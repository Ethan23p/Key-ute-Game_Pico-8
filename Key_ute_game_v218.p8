pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- Flirt game 
-- idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
-- for Cassie ♥

-->8
--Construction Functions

function _init()

    initialize_variables()

    init_gameplay()

end

--A simple function for creating variables that must exist on program 
--start or are useful to be able to quickly tweak when developing. 
function initialize_variables()
    foo = "bar"

    --This will only be the initial stats - if there's anything I want to preserve I should copy it when the program starts.
    char_player =
    {
        coords = {x = 16, y = 16},
        facingRight = true,
        moveSpeed = 16, --base moveSpeed, everything else will be based on this
        vel = {x = 0, y = 0},
        intended = {x = 16, y = 16},
        width = 7, --remeber that pixel counting effectively starts at 0
        height = 7,
        spr = 
        {
            idle = 56,
            walkCycle_start = 57,
            walkCycle_length = 4,
            walkCycle = {},
            animTick = 1,
            current = 16,
            size = 1
        },
        hasKey = false,
    }
    --Construct a list of the sprites that make-up the walk cycle
    --It would be wise to make this a more general function and more robust, but this will do for now
    for i = 1, char_player.spr.walkCycle_length do
        add(char_player.spr.walkCycle, char_player.spr.walkCycle_start + i - 1)
    end

    global_physicsDrag = .92 -- generally, movement should be multiplied by this to gradually reduce velocity each frame
    global_moveSpeedMax = 8 --Multiply obj moveSpeed by this number
    global_dampen = .02 --Multiply anything related to movement to convert my working numbers into numbers appropriate for pixels
    global_tick = 0
    global_framesPerSprite = 5
    tileSize = 8
    originOffset = 16

    spriteFlag_solid = 0
    spriteFlag_loseCondition = 2 --Prob unused, might remove
    range_hazard = (8 + char_player.width/2) --in pixels
    range_key = (8 + char_player.width/2)

    --Animation iterates through these sprites 
    --It would be more elegant to set states and timing and construct the cycle on the fly
    sprite_hazardCycle = 
    {
        66, 64, 64, 64, 64, 64, 64, 64,--Rest state 1, settles for 1 frame then rests
        68, 70, 72, 68, 70, 72, --Spinning state 1
        64, 66, 66, 66, 66, 66, 66, 66, --Rest State 2, settles then rests
        68, 70, 72, 68, 70, 72, --Spinning State 2, identical to first
    }
    
    level_initial = "level_I"--"level_heart"--
    levels = {}
    create_levels()

    table_toAnimate = {}

end

function init_gameplay()

    --Construction events
    --
    _update = update_gameplay
    _draw = draw_gameplay

    --Start creating levels
    if not level_current then --initialize level_current
        level_current = levels[level_initial]
    end

    --Set current conditions based on the current level's parameters
    coords_spawn = level_current.coords_spawn
    zone_success = level_current.zone_success
    coords_tileOrigin = level_current.coords_tileOrigin
    coords_key = level_current.coords_key
    table_hazards = level_current.table_hazards
    
    --Validate level parameters
    if coords_spawn == nil 
    or zone_success == nil 
    or coords_tileOrigin == nil 
    or coords_key == nil 
    or table_hazards == nil
    then
        troubleshooting("levelParams","Hey, setting the level params doesn't work! \n")
        return
    end

    --Game Cycle Start Events
    --

    --Clear table toAnimate
    table_toAnimate = {}

    --Reset key progress
    char_player.hasKey = false

    --Add the player to the ToAnimate table
    add(table_toAnimate, char_player)
    
    --Define the key
    key_current = 
    {
        coords = coords_key,
        spr = 
        {
            current = 25,
            size = 1,
            hoverCycle = 
            {
                distance = range_key / 4, --Aiming for 3 pixels, want it to be dynamic
            }
        }
    }
    --Add the key to the ToAnimate table
    add(table_toAnimate, key_current)
    --Give each entry in the hazards table a loop cycle variable (indicates this is an object with a simple anim, rather than a walk cycle) 
    --then add each entry in the table to the ToAnimate table
        for index, hazard in ipairs(table_hazards) do
        hazard.spr = {}
        hazard.spr.size = 2
        hazard.spr.loopCycle = sprite_hazardCycle
        add(table_toAnimate, hazard)
    end

    --Slow player dramatically on level advance
    char_player.vel.x = impose_global_dampen(char_player.vel.x)
    char_player.vel.y = impose_global_dampen(char_player.vel.y)

    --TP player to spawn coords
    char_player.coords = {x = coords_spawn.x, y = coords_spawn.y}

end

function create_level(level_title, seqOrder, coords_spawn, 
    zone_success, coords_tileOrigin, coords_key, table_hazards, levelTimer)

    if levels[level_title] then 
        troubleshooting("levelExists", "Hey, that level, "..level_title..",\n already exists! \n") 
        return
    end

    levels[level_title] =
    {
        seqOrder = seqOrder or 0,
        coords_spawn = coords_spawn or {x = 64, y = 64},
        zone_success = zone_success or {corner_1 = {x = (0 * tileSize), y = (0 * tileSize)}, corner_2 = {x = (2 * tileSize), y = (2 * tileSize)}},
        coords_tileOrigin = coords_tileOrigin or {x = 0, y = 0},
        coords_key = coords_key or {x = 64, y = 64},
        table_hazards = table_hazards or {{coords = {x = 5, y = 5},}},
        levelTimer = levelTimer or {max = 300}
    }
end

function create_levels()
    --[[level_title, seqOrder, coords_spawn, 
    zone_success, coords_tileOrigin, coords_key, table_hazards, timer]]
    --[[
        I want to use the coords from the map editor so I have to 
        convert each value here to screen space and account for offset.
    --]]

    --Val "to Screen with Offset"
    local function toScr_wOff(val, offset) --I've given everything clearer names for readability, but I just couldn't bear this function being so long
        if offset == nil then 
            offset = 0 
        end
        return ((val - (originOffset * offset)) * tileSize)
    end
    create_level
    (
        "level_I", --level_title
        1, --seqOrder
        {x = toScr_wOff(8), y = toScr_wOff(8)}, --coords_spawn
        {corner_1 = {x = toScr_wOff(7), y = toScr_wOff(4)}, corner_2 = {x = toScr_wOff(9), y = toScr_wOff(5)}}, --zone_success
        {x = (originOffset * 0), y = 0}, --coords_tileOrigin
        {x = toScr_wOff(8), y = toScr_wOff(11.5)}, --coords_key
        { --table_hazards
            {coords = {x = toScr_wOff(6.5), y = toScr_wOff(8)}},
            {coords = {x = toScr_wOff(9.5), y = toScr_wOff(8)}},
        }, --levelTimer
        {max = 300}
    )

    create_level
    (
        "level_heart", --level_title
        2, --seqOrder
        {x = toScr_wOff(23.5, 1), y = toScr_wOff(10.5)}, --coords_spawn
        {corner_1 = {x = toScr_wOff(24, 1), y = toScr_wOff(11)}, corner_2 = {x = toScr_wOff(26, 1), y = toScr_wOff(12)}}, --zone_success
        {x = (originOffset * 1), y = 0}, --coords_tileOrigin
        {x = toScr_wOff(26.5, 1), y = toScr_wOff(4.5)}, --coords_key
        { --table_hazards
            {coords = {x = toScr_wOff(24.5, 1), y = toScr_wOff(5)}},
            {coords = {x = toScr_wOff(23, 1), y = toScr_wOff(7)}},
            {coords = {x = toScr_wOff(26, 1), y = toScr_wOff(7)}},
        }, --levelTimer
        {max = 300}
    )

    create_level
    (
        "level_u", --level_title
        3, --seqOrder
        {x = toScr_wOff(41, 2), y = toScr_wOff(5)}, --coords_spawn
        {corner_1 = {x = toScr_wOff(38, 2), y = toScr_wOff(5)}, corner_2 = {x = toScr_wOff(39, 2), y = toScr_wOff(6)}}, --zone_success
        {x = (originOffset * 2), y = 0}, --coords_tileOrigin
        {x = toScr_wOff(39, 2), y = toScr_wOff(11)}, --coords_key
        { --table_hazards
            {coords = {x = toScr_wOff(40, 2), y = toScr_wOff(9)}},
            {coords = {x = toScr_wOff(40, 2), y = toScr_wOff(7)}},
            {coords = {x = toScr_wOff(35, 2), y = toScr_wOff(5)}},
            {coords = {x = toScr_wOff(35, 2), y = toScr_wOff(3)}},
            {coords = {x = toScr_wOff(45, 2), y = toScr_wOff(5)}},
            {coords = {x = toScr_wOff(45, 2), y = toScr_wOff(3)}},
        }, --levelTimer
        {max = 300}
    )

end

--Often my working numbers are higher values for more precision, so I need to 
--convert them to a value more appropriate for pixels/every frame calculation
function impose_global_dampen(val)
    if type(val) == "number" then 
        return val * global_dampen
    else
        troubleshooting("notNumberInGlob", "Hey, that's not a number \nin impose_global_dampen! \n")
        return
    end
end

-->8
--Utility Functions

--Troubleshooting function which is as simple as possible; 
--Each message gets an ID so it doesn't get duplicated, then all messages from start of runtime
--are stored in a table so they can be drawn at the end of the frame.
--Troubleshooting messages can be added from anywhere in the stack, overwrite their previous messages, and don't expire.
function troubleshooting(id, msg)

    if not ts_messages then 
        ts_messages = {} 
    end

    ts_messages[id] = msg

end

--Draw all messages accumulated since runtime began,
--all reasonably spaced and function is placed at the very end
--of the draw so that it overrides all other drawing
function draw_troubleshooting()

    local ts_messageOffset = 0

    if ts_messages == nil then
        return
    end

    for key, message in pairs(ts_messages) do
        print(message, 4, 4 + ts_messageOffset, tileSize)
        ts_messageOffset += tileSize
    end

end

--If velocity is a given fraction of the moveSpeed, halt
function query_shouldHalt(vel, moveSpeed)
    if ((abs(vel)) < (moveSpeed / 16)) then
        return true
    else
        return false
    end
end

-- Checks if object coordinates are within a specified range of a given point
function query_doesCollide_range(obj_coords, point_coords, range)
    local differenceInX = obj_coords.x - point_coords.x
    local differenceInY = obj_coords.y - point_coords.y
    local euclideanDistance = sqrt(differenceInX^2 + differenceInY^2)

    if euclideanDistance < range then
        return true
    else
        return false
    end
end

--If player coords are within bounds of zone, return true
function query_doesCollide_zone(obj, zone)

    local x = obj.coords.x
    local y = obj.coords.y

    if (zone.corner_1.x < x) 
    and (x < zone.corner_2.x) 
    and (zone.corner_1.y < y) 
    and (y < zone.corner_2.y) 
    then
        return true
    else
        return false
    end
end

-->8
--Update Functions

function update_gameplay()
    
    --Iterate global tick
    tick_update()

    levelTimer.update()

    --Validate player
    if not char_player then
        troubleshooting("noChar", "Um, you lost your character! \n")
    end

    --Early in frame, move player
    --then record TODO
    move_player(char_player)

    --If player is in success zone, 
    --advance level
    if query_doesCollide_zone(char_player, zone_success) and char_player.hasKey then

        advance_level()

    end

    --If player picks up key, stop rendering the sprite
    if query_doesCollide_range(char_player.coords, coords_key, range_key) then
        char_player.hasKey = true
        del(table_toAnimate, key_current)
    end

    --For each hazard in table: if colliding with hazard, die
    for index, hazard in pairs(table_hazards) do
        if query_doesCollide_range(char_player.coords, hazard.coords, range_hazard) then
            die()
        end
    end

end

--Find players new x, y coords by maintaining velocity
function move_player(player)

    --(btn(x,y)) 
    --x=0, 1 means left, right 
    --x=2,3 means up, down
    --y=0 means player control scheme 1, y=1 means player control scheme 2 (I have both set up to control main character so user can choose)
    --
    --While player presses any button, continuously add velocity to relevant direction
    --(This is a tidy little module to reduce code repetition)
    local function impetus(vel, pole)
        return vel + (player.moveSpeed * pole)
    end
    if (btn(0,0) or btn(0,1)) player.vel.x = impetus(player.vel.x, -1)
    if (btn(1,0) or btn(1,1)) player.vel.x = impetus(player.vel.x, 1)
    if (btn(2,0) or btn(2,1)) player.vel.y = impetus(player.vel.y, -1)
    if (btn(3,0) or btn(3,1)) player.vel.y = impetus(player.vel.y, 1)

    --Impose limits of drag and maximum movespeed 
    --(sidenote, I suppose movespeed max could be derived from gravity/drag affecting base movespeed)
    local function player_imposeLimits(vel, moveSpeed)
        local moveSpeedMax = moveSpeed * global_moveSpeedMax
        return mid(-moveSpeedMax, (vel * global_physicsDrag), moveSpeedMax)
    end
    player.vel.x = player_imposeLimits(player.vel.x, player.moveSpeed)
    player.vel.y = player_imposeLimits(player.vel.y, player.moveSpeed)

    if query_shouldHalt(player.vel.x, player.moveSpeed) then
        player.vel.x = 0
    end
    if query_shouldHalt(player.vel.y, player.moveSpeed) then
        player.vel.y = 0
    end

    --Find intended x,y coords
    player.intended.x = player.coords.x + (impose_global_dampen(player.vel.x))
    player.intended.y = player.coords.y + (impose_global_dampen(player.vel.y))
    --Check collision on each axis
    --If there is collision on an axis, set the intended location back to the current one
    if not query_canMove(player.intended.x, player.coords.y, player.width, player.height) then
        --troubleshooting("Xsolid", "Solid X: "..player.intended.x..", "..player.coords.y)
        player.vel.x *= -.5
        player.intended.x = player.coords.x + (impose_global_dampen(player.vel.x))
    end
    if not query_canMove(player.coords.x, player.intended.y, player.width, player.height) then
        --troubleshooting("Ysolid", "Solid Y: "..player.coords.x..", "..player.intended.y)
        player.vel.y *= -.5
        player.intended.y = player.coords.y + (impose_global_dampen(player.vel.y))
    end
    
    --Simply set player coords to the intended coords
    player.coords.x = player.intended.x
    player.coords.y = player.intended.y

end

function tick_update()

        --Once each cycle, increment global_tick until it is reset after 64
        if global_tick > 64 then
            global_tick = 0
        end
        global_tick += 1

end

levelTimer = {} --Initialize level timer
--Function intentially uses reference of current level's timer
--Level timer ticks down and provides framework for the timer visual.
--TODO Need to implement a timer visual
function levelTimer.update()

    local timer = level_current.levelTimer

    if not timer.current then
        timer.current = timer.max
    end

    timer.current -= 1

    if timer.current < 0 then
        troubleshooting("levelTimer", "Too slow")
        die()
    end

end

function levelTimer.reset()

    level_current.levelTimer.current = level_current.levelTimer.max

end

function advance_level()

    local wasFound_bool = false --Local variable tracking if the following function somehow ends up invalid
    local levelNext_seqOrder = level_current.seqOrder + 1 --Local variable setting the target for the function

        --If target is greater than the number of levels there are, set current level to initial level
        --Probably temporary for development
    if levelNext_seqOrder > 3 then
        troubleshooting("levelLoop","No more levels, looping")
        level_current = levels[level_initial]
    else
        for key, level in pairs(levels) do
            if level.seqOrder == levelNext_seqOrder then
                wasFound_bool = true

                level_current = levels[key]
            end
        end
        die()
        if not wasFound_bool then
            troubleshooting("levelNext", "No next level found!")
        end
    end
end

function die()
    levelTimer.reset()
    init_gameplay()

end

--Checks if an objects bounds touch a map tile with a given sprite flag
--limited to only "is solid?" but I could modify
function query_canMove(x, y, obj_width, obj_height)

    --I'm collision checking the outer points of a cross centered in the sprite, 
    --rather than the center or corners
    offset_width = (((obj_width + 1) - .5) / 2) --Add 1 because pixel counts are 0 indexed, subtract a bit for gamefeel, divide by two for centering
    offset_height = (((obj_height + 1) - .5) / 2)

    local edges = {}

    --Add the outer points of  a cross to an array
    add(edges, {x - offset_width, y})
    add(edges, {x + offset_width, y})
    add(edges, {x, y - offset_height})
    add(edges, {x, y + offset_height})

    --If any point returns solid, return false immediately
    --Note to self, I could use the Pico-8 foreach function here
    for i=1, #edges do
        if query_flagType(edges[i], spriteFlag_solid) then
            --troubleshooting("solid", "Solid...SOLID "..x..", "..y)
            return false
        end
    end
    --troubleshooting("solid", "Clear "..x..", "..y)
    return true

end

--Checks a given x,y coords for a specific flag
function query_flagType(coords_input, flagType)

    --Had a more complicated use-case in mind, so this function can handle multiple flags of interest
    spriteFlags_ofInterest = {flagType}

    --Convert from screen coords to map coords, taking into consideration tile offset
    map_x = flr((coords_input[1] / tileSize) + level_current.coords_tileOrigin.x)
    map_y = flr((coords_input[2] / tileSize) + level_current.coords_tileOrigin.y)

    --Get sprite address
    local sprite_address = mget(map_x, map_y)
    -- Get the flag(s) associated with the sprite
    local spriteFlags = fget(sprite_address)
    
    -- Check for flag type of interest based on spriteFlags
    for key, flag in ipairs(spriteFlags_ofInterest) do
        if (spriteFlags & 2^flag) > 0 then
            return true
        end
    end

    -- Return false if spriteAddress is not of given flag type
    return false
end

tempTape = {}

function tempTape.clear(obj)

    tempTape[obj] = {}

end

function tempTape.write(obj, coords, direction, level)

    add(
        tempTape[obj], 
        {
            coords.x, 
            coords.y, 
            direction, 
            level
        }
    )

end

tape = {}

function tape.record(obj)

    for index, entry in ipairs(tempTape[obj]) do

        add
        (
            finalTape, 
            {
                entry.x,
                entry.y,
                entry.direction,
                entry.level
            }
        )

    end
end

function tape.play(obj)



end

-->8
--Draw Functions

function draw_gameplay()

    cls(2)

    draw_map()

    if next(table_toAnimate) == nil then
        troubleshooting("animateNil", "No objects to animate")
    end

    for index, anim_obj in pairs(table_toAnimate) do
        obj_animate(anim_obj)
    end

    draw_troubleshooting()

end

function draw_map()

    map(coords_tileOrigin.x, coords_tileOrigin.y, 0, 0, 16, 16)

end

function obj_animate(obj)

    if not obj.spr.animTick then
        obj.spr.animTick = 1
    end

    if obj.spr.walkCycle then --If object has a walk cycle
        --If object is not moving, set spr.current to idle
        if query_shouldHalt(obj.vel.x, obj.moveSpeed) and query_shouldHalt(obj.vel.y, obj.moveSpeed) then
            obj.spr.current = obj.spr.idle
            --troubleshooting("halted", "halted anim "..global_tick)
        --iterate walk cycle by cycling through the indices of walkCycle according to
        --the modulo of global_tick; I do it this way for elegance
        elseif global_tick % global_framesPerSprite == 0 then
            --a per-object anim tick cycles from 1 to the length of walkCycle. It could just increment, but this prevents infinite growth if I understand it correctly
            obj.spr.animTick = (obj.spr.animTick % #obj.spr.walkCycle) + 1
            obj.spr.current = obj.spr.walkCycle[obj.spr.animTick]
        else

    end

    elseif obj.spr.loopCycle then --If object is a simple sprite with a loop cycle
        if not obj.spr.current then
            obj.spr.current = obj.spr.loopCycle[1]
        end
        if global_tick % global_framesPerSprite == 0 then
            --a per-object anim tick cycles from 1 to the length of loopCycle.
            obj.spr.animTick = (obj.spr.animTick % #obj.spr.loopCycle) + 1
            obj.spr.current = obj.spr.loopCycle[obj.spr.animTick]
        end

    elseif obj.spr.hoverCycle then --If object is a simple sprite with a hover cycle
        if not obj.spr.hoverCycle.origin_y then
            obj.spr.hoverCycle.origin_y = obj.coords.y --Initialize origin y coord for reference in hover distance
            obj.spr.hoverCycle.pole = 1
        end

        if global_tick % global_framesPerSprite == 0 then
            --Add 1 or -1 to objects y coord depending on if it is above or below the distance from the origin
            if obj.coords.y <= (obj.spr.hoverCycle.origin_y - obj.spr.hoverCycle.distance) then
                obj.spr.hoverCycle.pole = 1
            elseif obj.coords.y >= (obj.spr.hoverCycle.origin_y + obj.spr.hoverCycle.distance) then
                obj.spr.hoverCycle.pole = -1
            end
            obj.coords.y += 1 * obj.spr.hoverCycle.pole

        end

    else
        troubleshooting("objAnimateNil", "obj_animate called with incompat obj")
        --return
    end

    spr(obj.spr.current, (obj.coords.x - (obj.spr.size * 4)), (obj.coords.y - (obj.spr.size * 4)), obj.spr.size, obj.spr.size)

end

function draw_player()

    spr(52, char_player.coords.x, char_player.coords.y)

end

__gfx__
00000000777756775677777775677567555555555d666666ddddddddbbc3333cdddd65dd55555555777777770000000000000000000000000000000000000000
00000000777756775677777775677567500000555d666666dccccccdbc333bbcdddd65ddd66666657f7777770000000000000000000000000000000000000000
00700700777756775677777775677567050005055d666666dccccccdc333bbbbdddd65ddd66666657f7777f70000000000000000000000000000000000000000
00077000666656665677777765666566000050055d666666dccccccd3333bbbb55556555d66666657f7777f70000000000000000000000000000000000000000
00077000555555555677777755555555000050055d666666dccccccd33333bbb66666666d66666657f7777f70000000000000000000000000000000000000000
00700700777567775677777775677567000500055d666666dccccccdbbbc33cbddd65dddd66666657f7777f70000000000000000000000000000000000000000
00000000777567775666666675677567005000055ddddddddccccccdbbbbc33cddd65dddd66666657f7777770000000000000000000000000000000000000000
000000007775677755555555756775670500050555555555ddddddddbbbbbc33ddd65dddddddddd5777777770000000000000000000000000000000000000000
00077600000000000000000000000000000000000000000000000000000000000000000000000aa0000ddd006ddddd6600000000000000000000000000000000
007d11600007766000007766000077660000776600007766007766000000000000066bb00000aaff00dd41106ddddd6600000000000000000000000000000000
77dbd360007dd1600007dd160007dd160007dd160007dd1607dd160000000000006cc3b0000aa00f00d942106577756600000000000000000000000000000000
007dd160007bd3600007bd360007bd360007bd360007bd3607bd3600000000000067cab0000af09900d949106770776600000000000000000000000000000000
007776000077760000077760000777600007776000077760077760000000000000666b0000aff9900dd942106700076600000000000000000000000000000000
0017100000071000071710000071700000071000000710000171000000000000000630000af900000dd942106770776600000000000000000000000000000000
055dd100017dd110057dd100011d7500017dd1000017d10057dd100000000000036cc330af9000000dd940006677766600000000000000000000000000000000
000002200550022000502200022550000550220000052200050022000000000009900440a90000000dd900006666666600000000000000000000000000000000
00111500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01171600001115000001115000011150000111500001115001115000000000000000000007766600077666000776660007766600000000000000000000000000
71787260011716000011716000117160001171600011716001716000000000000776660007e8684007e8684007e8684007e86800000000000000000000000000
061775000178725000178720001787200017872000178720078725000000000055e8681057766644577666445776664457766640000000000000000000000000
00666000001776000001776000017760000177600001776001776000000000005556664455555444555554445555544455566440000000000000000000000000
00995000006660000766660007666600076666000766660007660000000000000555444405555544055555440555554405554444000000000000000000000000
0005500007555600095550000059900000555000005550009955000000000000c7555440cc7744400cc74440d77cc44007c55440000000000000000000000000
0000440009904400009044000044000009904400004400000440000000000000ccc44400cc0dd00000cd00000d0cc0000dcc4400000000000000000000000000
00000000000ee000000ee000000ee000000eee00000ee000000000ee00000e000000000000000000000000000000000000000000000000000000000000000000
00aa0000000ee00000eeee00000ee000000eee00000ee00000e0ee000000e00e00000000066ddd00066ddd00066ddd00066ddd00000000000000000000000000
00aaa00008aee20000aeee00008ee200088aee20008aa200000ee0000000e0e0066ddd0006e8d84006e8d84006e8d84006e8d800000000000000000000000000
0aaaaa00088aa20000aaa200088aaa20088aaa20088aaa20000e0e00000e0e0011e8d810166ddd44166ddd44166ddd44166ddd40000000000000000000000000
0aaaa000088aa2000aaaa20008aaa20008aaaa0008aaa2000ee0e0e000eee000111ddd44111112441111124411111244111dd440000000000000000000000000
0aaa000008aa32000aaa020008b0320008baa20008b032000e0e00000ee000000111244401111124011111240111112401112444000000000000000000000000
00a000000ba030000aa0000000b0300000b0300000b03000ee0000000e000000c6111240cc6622200cc62220366cc22006c11240000000000000000000000000
000000000bb033000000000000bb330000bb330000bb330000e00000e0000000ccc22200cc03300000c30000030cc00003c22200000000000000000000000000
00000000044400000000004200000000000009944440000000000444440000000000044444400000000000000000000000000000000000000000000000000000
00000000422200000000004200000000000009944422000000002244442000000000244444220000000000000000000000000000000000000000000000000000
00000002222200000000042200000000000022994222200000022224422220000000224442220000000000000000000000000000000000000000000000000000
00000001122000000000042110000000002222911422200000222241122222000002224114222000000000000000000000000000000000000000000000000000
42200111111000000000411e8114000002222118e112220000222118811222200222211ee1122220000000000000000000000000000000000000000000000000
42221e8111e100000000111111114400222218811ee1222202221ee11881222222221ee118812222000000000000000000000000000000000000000000000000
42221111118100000000111111112244222218111181222222221e11118122222222181111812222000000000000000000000000000000000000000000000000
0421111d111112000001811d111e12222221811dd11812222221811d111812222221811d11181222000000000000000000000000000000000000000000000000
00211111d11112402221e11d111810002221811dd11812222221811dd11812222221811dd1181222000000000000000000000000000000000000000000000000
0000181111112224442211111111000022221811118122222222181111e122222222181111812222000000000000000000000000000000000000000000000000
00001e1118e12224004411111111000022221ee118812222222218811ee12220222218811ee19222000000000000000000000000000000000000000000000000
000001111110022400004118e11400000022211e8112222002299118811222000222211ee1199990000000000000000000000000000000000000000000000000
00000221100000000000000112400000000222411422220000999921142222000002224114229900000000000000000000000000000000000000000000000000
00002222200000000000000022400000000222244422000000099224422220000000222444220000000000000000000000000000000000000000000000000000
00002224000000000000000024000000000022444440000000000244442200000000224444420000000000000000000000000000000000000000000000000000
00004440000000000000000024000000000004444440000000000044444000000000044444400000000000000000000000000000000000000000000000000000
__gff__
0000000000010008000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010101010101010101010505020202020202020202020205050505050303030303030303030303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010101010101010101010505020202020202020202020205020202050307070303030303030303070703050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010101010101010101010505020202020202020702020202020202050507070503030303030305070705050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010106060101010101010505020202020202070707060205020202050507070503030303030305070705050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050303040403030a0a040404030303050502020202020a0a070a0a0205050505050307070303060303060303070703050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050303030304040a0a0404040403030505020202020a07070407070a050202020503030303030a07070a0303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050505050606060a0606040403030505020202020a07070407070a020202020503030303030a07070a0303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050303040406060a060606050505050505020202020a03030404030a050202020505050503030a07070a0303050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050303030304040a0a040404040303050502020202020a0304040a0205050505051b030503030a07070a030305031b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050303040303040a0a040404030303050502020202020206040a020202020205050303030303030a0a030303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010106060303030304040505050205050505040602020202020205050505050303030603030303050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010101040404040404040505020202020205040405050205050205050303030303030303030303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010104040404040404040505020202020205040405020205020205050303050303030303030303050303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010104040404040404040505020202020205040405020205020205050303050303030303030303050303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050505050505050505020202020205050505020205020205050305050505050505050505050305050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
