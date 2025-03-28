pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Key-ute Game
-- idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
-- for Cassie ♥ 

-->8
--Flow Functions - init, update, draw

--Initial function that is called when the program starts
function _init()

    init_variables()

    init_game()

end

--Sets or updates foundational and level-specific states and variables
function init_game()

    init_game_construction()

    init_game_runStart()

end

--Every frame, update the state of the program
function update_game()

    update_game_systems()
    
    update_game_validation()
    
    update_game_move()
    
    update_game_conditions()
    
end

--Every frame, after the logic is processed, render to the screen
--The current pipeline is: map, objects, animated objects, then player but 
--a more complex pipeline would allow for objects in the foreground / allow objects & player to be placed at various depths 
function draw_game()

    clear_screen()

    draw_map()

    draw_objects()

    draw_animation()

    draw_player()

    draw_troubleshooting()

    draw_screenOverlay()

end

--Sets or updates foundational states and variables
function init_game_construction()

    --Set the update and draw functions to their game-play counterparts
    _update = update_game
    _draw = draw_game

    --Start creating levels

    --initialize level_current
    if not level_current then 
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
end

--Sets or resets variables for the current run, based on the current level
function init_game_runStart()

    --Clear table toAnimate
    table_toAnimate = {}

    --Clear temporary tape
    tempTape_clear(char_player)

    --Reset key progress
    char_player.hasKey = false

    key_current = 
    {
        coords = coords_key,
        spr = 
        {
            current = 25,
            size = 1,
            hoverCycle = {range = 3},
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

-->8
--Init Functions

--A simple function for creating variables that must exist on program 
--start or are useful to be able to quickly tweak when developing. 
function init_variables()
    foo = "bar"

    --This will only be the initial stats - if there's anything I want to preserve I should copy it when the program starts.
    char_player =
    {
        coords = {x = 16, y = 16},
        direction = "➡️", --For reference: ⬅️➡️⬆️⬇️
        moveSpeed = 16, --base moveSpeed, everything else will be based on this
        vel = {x = 0, y = 0},
        intended = {x = 16, y = 16},
        width = 7, --remember that pixel counting effectively starts at 0
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
    tileSize = 8
    originOffset = 16

    global_framesPerSprite = 5
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
    levelsSeq = {}
    create_levels()

    table_toAnimate = {}
end

--Like a factory, create the levels using the parameters set here. 
--This function creates objects in the levels table using the next function, a pseudo-class.
--This approach involves some boilerplate for readability, to account for the lack of classes in Lua. 
function create_levels()
    --[[level_title, seqOrder, coords_spawn, 
    zone_success, coords_tileOrigin, coords_key, table_hazards, timer]]
    --[[
        I want to use the coords from the Pico-8 map editor so I have to: 
        convert each value from map editor coords to screen space and then
        account for offset.
    --]]

    --Returns input value from map editor coords "to Screen with Offset"
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
        },
        {max = 300} --levelTimer
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
        },
        {max = 300} --levelTimer
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
        },
        {max = 300} --levelTimer
    )

    --Add a reference to a given level to the levelsSeq table with an index of its sequence order.
    --Though this is very over-engineered, the purpose is to enable me to call levels based on the sequential order rather than the title (I particularly wanted this so levels could have appropriate names, instead of just hardcoded numbers).
    local function sequence_level(level)
        levelsSeq[level.seqOrder] = level
    end
    --For each level, add a reference to it based on its sequence order.
    for i, level in pairs(levels) do
        sequence_level(level)
    end

end

--Custom pseudo class to create entries into the levels table.
--Not confident this is the best approach, but it seems like a 
--slightly elegant workaround for the lack of classes in Lua.
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

-->8
--Update Functions

--Update core game systems, like the game-play tick and timer
function update_game_systems()

    --Iterate global tick
    tick_update()

    levelTimer_update()

end

--Validate any variables/objects
function update_game_validation()

        --Validate player
        if not char_player then
            troubleshooting("noChar", "Um, you lost your character! \n")
        end

end

--Update movement logic
function update_game_move()

        --Early in frame, move player
        --then record
        move_player(char_player)
        tempTape_write(char_player, char_player.coords.x)

end

--Check for success/fail conditions, like completing the level or dying by hazards
function update_game_conditions()

    --If player is in success zone, advance level
    if query_doesCollide_zone(char_player, zone_success) and char_player.hasKey then

        advance_level()

    end

    --If player picks up key, set "player has key" and stop rendering the sprite
    if query_doesCollide_range(char_player.coords, coords_key, range_key) then
        char_player.hasKey = true
        del(table_toAnimate, key_current)
    end

    --For each hazard in hazard table: if colliding with hazard, die
    for index, hazard in pairs(table_hazards) do
        if query_doesCollide_range(char_player.coords, hazard.coords, range_hazard) then
            die()
        end
    end

    --Need to add logic and rendering for "message" level. TODO
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

    --Impose limits of drag and maximum move-speed 
    --(side note, I suppose move-speed max could be derived from gravity/drag affecting base move-speed)
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
    --Check collision on each axis.
    --If there is collision on an axis, reverse movement and greatly reduce velocity on that axis. 
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

    --Compare player's intended x to their current x, if negative they are facing left, else right.
    --For reference: ⬅️➡️⬆️⬇️
    if (player.intended.x - player.coords.x) < 0 then
        player.direction = "⬅️"
    else
        player.direction = "➡️"
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

--Level timer ticks down, ends run on depletion, and provides framework for the timer visual.
--Need to implement a timer visual, TODO
function levelTimer_update()

    --Intentionally uses reference of current level's timer so that then
    --timer can be preserved per level; only timer max is constant.
    local timer = level_current.levelTimer

    --Validate timer_current.
    if not timer.current then
        timer.current = timer.max
    end

    --Decrement timer.
    timer.current -= 1

    --When timer reaches 0, end the run.
    if timer.current < 0 then
        troubleshooting("levelTimer", "Too slow") --TS, will remove later.
        die()
    end

end

function levelTimer_reset()

    --Reset the current level timer.
    level_current.levelTimer.current = level_current.levelTimer.max

end

--Advance by finding the next level, according to seqOrder, setting that as the current level, and ending the current run.  
function advance_level()

    local seqOrder_next = level_current.seqOrder + 1

    if levelsSeq[seqOrder_next] then
        level_current = levelsSeq[seqOrder_next]
    elseif seqOrder_next > (#levelsSeq - 1) then
        troubleshooting("weiner", "You r the weiner!")
        --init_game_levelMessage() --TODO
    else
        troubleshooting("advanceLevel", "Incompatible next level")
    end

    tape_record(char_player)

    die()

end

--End current run, agnostic of whether it was a success or failure.
function die()

    levelTimer_reset()

    --Because init_game references live variables, calling it will always reset the game-state according to the set current level.
    init_game()

end

--Checks if an object's bounds touch a map tile with a given sprite flag
--limited to only "is solid?" but I could modify
function query_canMove(x, y, obj_width, obj_height)

    --I'm collision checking the outer points of a cross centered in the sprite, 
    --rather than the center or corners
    offset_width = (((obj_width + 1) - .5) / 2) --Add 1 because pixel counts are 0 indexed, subtract a bit for game-feel, divide by two for centering
    offset_height = (((obj_height + 1) - .5) / 2)

    --Add the outer points of  a cross to an array
    local edges = {}
    add(edges, {x - offset_width, y})
    add(edges, {x + offset_width, y})
    add(edges, {x, y - offset_height})
    add(edges, {x, y + offset_height})

    --If any point returns solid, return false immediately
    --Note to self, I could use the Pico-8 foreach function here --From future self; not sure if I could, I like that it immediately exits upon failure.
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

--Clear tempTape simply (I just want to be explicit for clarity).
function tempTape_clear(obj)

    --Initialize tempTape
    if not tempTape then
        tempTape = {}
    end

    --Clear tempTape
    tempTape[obj] = {}

end

--Add a single frame of player data to tempTape.
function tempTape_write(obj)

    local working_tempTape = tempTape[obj]

    local player_data = 
    {
        x = obj.coords.x, 
        y = obj.coords.y, 
        direction = obj.direction, 
    }

    add(working_tempTape, player_data)

end

--Given that the tempTape for the given level is finalized, copy it to the final tape
function tape_record(obj)

    if not tempTape[obj] then
        troubleshooting("recordNil", "No tempTape to record for "..obj)
        return
    end

    if not finalTape then
        finalTape = {}
    end

    local working_level = level_current.seqOrder

    if not finalTape[working_level] then
        finalTape[working_level] = {}
    end

    local working_tempTape = tempTape[obj]
    local working_finalTape = finalTape[working_level]

    for index, entry in ipairs(working_tempTape) do

        local player_data = 
        {
            x = entry.x, 
            y = entry.y, 
            direction = entry.direction, 
        }

        add(working_finalTape, player_data)

    end
end

--TODO
function tape_play(obj)

end

--Initiate variables and functions for the message portion of the game. 
function init_game_levelMessage()

    _update = update_message
    _draw = draw_message

    messageLevel_goTime = 30
    messageLevel_delay = 0
    
    playhead_level = 1 
    playhead_frame = 0

    message_particles = {}

end

--Manage the message sequencing, set the current player movement data, track the particles.
function update_message()

    --If the delay tracker is less than the goTime, increment it and return.
    if messageLevel_delay < messageLevel_goTime then
        messageLevel_delay += 1
        return
    end

    --Increment current frame, set end of frames for current level.
    playhead_frame += 1
    playhead_stop = #finalTape[playhead_level]

    
    --If the playhead has reached the end of the current level's sequence, reset it and increment the level.
    if playhead_frame >= playhead_stop then
        
        playhead_frame = 0
        playhead_level += 1
        
        
    end

    --If the playhead has reached the end of the finalTape, reset it to the first level.
    if playhead_level > #finalTape then
        playhead_level = 1
    end

    --Set the current player movement data; global so that it can be used in the draw function.
    --Defined above, this can be used simply like: message_playerData_current.y
    local level_ofFinalTape = finalTape.char_player[playhead_level]
    local frame_ofLevel= level_ofFinalTape[playhead_frame]
    
    message_playerData_current = frame_ofLevel

    --Build a massive table of particle positions.
    add(message_particles, message_playerData_current)

end

--Clear the screen, draw the map, draw every particle so far, draw the player sprite.
function draw_message()

    clear_screen()

    draw_map_message()

    for index, particle in ipairs(message_particles) do
        --insert draw sprite function
        spr(particle.x, particle.y, 1, 1, (query_isFacingLeft(particle)))
    end

    --Generate lazy walking sprite by adding the modulo of global_tick to the start of the walk cycle
    local message_walkingSprite = 
    (char_player.spr.walkCycle_start + ((global_tick % char_player.spr.walkCycle_length)))
    --Draw player character puppet.
    spr(message_walkingSprite, message_playerData_current.x, message_playerData_current.y, 1, 1, (query_isFacingLeft(message_playerData_current)))
end

--TODO
--Draw map 3 times for the 3 levels, each with their corresponding originTile, offset, and width.
function draw_map_message()



end

-->8
--Draw Functions

--You wouldn't believe it, this function clears the screen.
function clear_screen()

    cls(2)

end

--Render the game world, presumably before (under) other objects
function draw_map()

    map(coords_tileOrigin.x, coords_tileOrigin.y, 0, 0, 16, 16)

end

--Render objects which are imposed on the map
function draw_objects()

    draw_door()

end

--Render animated objects
function draw_animation()

    --If there is no entries in table_toAnimate, send error. (Assumes that there is always at least one object to animate)
    if next(table_toAnimate) == nil then
        troubleshooting("animateNil", "No objects to animate")
    end

    --Iterate through and animate each object which has an element of animation
    for index, anim_obj in pairs(table_toAnimate) do
        obj_animate(anim_obj)
    end

end

--Render the player
function draw_player()

    obj_animate(char_player)

end

--Animate object depending on what type of animation it requires, then render the current animation frame.
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
    elseif obj.spr.loopCycle then --If object is a simple sprite with a loop cycle, like the hazards
        if not obj.spr.current then
            obj.spr.current = obj.spr.loopCycle[1]
        end

        if global_tick % global_framesPerSprite == 0 then
            --a per-object anim tick cycles from 1 to the length of loopCycle.
            obj.spr.animTick = (obj.spr.animTick % #obj.spr.loopCycle) + 1
            obj.spr.current = obj.spr.loopCycle[obj.spr.animTick]
        end
    elseif obj.spr.hoverCycle then --If object is a simple sprite with a hover cycle, like the key
        if global_tick % global_framesPerSprite == 0 then
            if not obj.spr.hoverCycle.high then
                obj.spr.hoverCycle.high = obj.coords.y + obj.spr.hoverCycle.range
                obj.spr.hoverCycle.low = obj.coords.y - obj.spr.hoverCycle.range
                obj.spr.hoverCycle.pole = 1
            end

            --Move object by one pixel per frame, respective of a maximum and minimum height relative to origin
            obj.coords.y += obj.spr.hoverCycle.pole
            if obj.coords.y >= obj.spr.hoverCycle.high then
                obj.spr.hoverCycle.pole = -1
            elseif obj.coords.y <= obj.spr.hoverCycle.low then
                obj.spr.hoverCycle.pole = 1
            end

        end

    --If invalid object is put in table, send error.
    else 
        troubleshooting("objAnimateNil", "obj_animate called with incompatible obj")
        --return
    end

    spr(obj.spr.current, (obj.coords.x - (obj.spr.size * 4)), (obj.coords.y - (obj.spr.size * 4)), obj.spr.size, obj.spr.size, query_isFacingLeft(obj), false)

end

--Render door according to success zone, allowing for rendering not aligned to the sprite grid.
function draw_door()

    local door_x = ((level_current.zone_success.corner_1.x + level_current.zone_success.corner_2.x) / 2) - (tileSize / 2)
    local door_y = ((level_current.zone_success.corner_1.y + level_current.zone_success.corner_2.y) / 2) - (tileSize / 2)

    spr(26, door_x, door_y)

end

function draw_screenOverlay()

    draw_timer()

end

function draw_timer()

    local timerProgress = level_current.levelTimer.current / level_current.levelTimer.max 

    --Unfinished

end

-->8
--Utility Functions

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

--Simple function for checking, direction facing is determined in movement code.
function query_isFacingLeft(obj)
    if obj.direction == "⬅️" then 
        return true
    else
        return false
    end
end

__gfx__
0000000077f7567f567f77f7756f756f555555555d666666ddddddddbbc3333cdddd65dd55555555777777770000000000000000000000000000000000000000
000000007777567f567f77f775677567500000555d666666dccccccdbc333bbcdddd65ddd66666657f7777770000000000000000000000000000000000000000
0070070077775677567f77f775677567050005055d666666dccccccdc333bbbbdddd65ddd66666657f7777f70000000000000000000000000000000000000000
0007700066665666567f77f765666566000050055d666666dccccccd3333bbbb55556555d66666657f7777f70000000000000000000000000000000000000000
0007700055555555567f777755555555000050055d666666dccccccd33333bbb66666666d66666657f7777f70000000000000000000000000000000000000000
007007007f7567f756777777756f756f000500055d666666dccccccdbbbc33cbddd65dddd66666657f7777f70000000000000000000000000000000000000000
000000007f7567f756666666756f756f005000055ddddddddccccccdbbbbc33cddd65dddd66666657f7777770000000000000000000000000000000000000000
000000007f7567f755555555756f756f0500050555555555ddddddddbbbbbc33ddd65dddddddddd5777777770000000000000000000000000000000000000000
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
0503010101010101010101010101010505020202020202070707020205020202050507070503030303030305070705050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503030404030303030404040303030505020202020202020702020205050505050307070303030303030303070703050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503030303040403030404040403030505020202020207070407070205020202050303030303030707030303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505070707030707040403030505020202020207070407070202020202050303030303030707030303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503030404070703070707050505050505020202020203030404030205020202050505050303030707030303050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503030303040403030404040403030505020202020202030404020205050505051b0305030303070703030305031b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503030403030403030404040303030505020202020202020402020202020205050303030303030303030303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010101010303030304040505050205050505040202020202020205050505050303030303030303050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010101040404040404040505020202020205040405050205050205050303030303030303030303030303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010104040404040404040505020202020205040405020205020205050303050303030303030303050303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503010101010104040404040404040505020202020205040405020205020205050303050303030303030303050303050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050505050505050505020202020205050505020205020205050305050505050505050505050305050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
