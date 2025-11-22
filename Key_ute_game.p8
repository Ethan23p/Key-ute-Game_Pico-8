pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 🔑ute Game (or :key:ute game)
-- idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
-- Code is incomplete, many parts still missing.
-- for Cassie ♥
-- ⬅️➡️⬆️⬇️

util = {}

init = {}
update = {}
draw = {}

-- When a run starts
function _init()
    --init flow / flow (game, menu, message) TODO

    init.config()

    --init.levels()

        -- Sets/validates parameters according to current level.
        -- init.run()
            -- if level == message then do message stuff

    player = proto_player:new()
    env = proto_env:new()

end

-- Process logic every frame
function _update()

        -- Establish player's new intent. Tell env intent.
        player:update()

    -- Place/validate environment hazards, starting position, success zone. Assess player's intent & tell result.
    env:update()

    -- Does player obj care about movement? Or does it just communicate and get told what to do?
    -- I suppose player object just does communications.
    -- I keep getting tripped up by this: which system manages position in world? Because an entity can intend to do whatever it wants, but it only moves according to the rules of the environment.
    player.receiveMovement()

    -- Check for success, death, validate movement.
    -- update.conditions()

end

-- Render every frame
function _draw()

    draw.clear_screen()
    env:draw()
    --game_door:draw()
    --game_key:draw()
    player:draw()
    --game_hazards:draw()
    --game_overlay:draw()
end

--- Init Functions ---

function init.config()
    config = {
        player = {
            initial_coords = { x = 64, y = 64 },
            speed = 8,
            initial_directionFacing = "➡️",
            sprite_id = 1
        },
        env = {
            tileSize = 8, -- Standard PICO-8 tile size
            boundary_flag_id = 1 -- Sprite flag ID used for collision (0-7)
        }
        --[[
        level parameters =
        level_title, seqOrder, coords_spawn,
        zone_success, coords_tileOrigin, coords_key, table_hazards, levelTimer
        ]]--

    }
end

--- Utility Functions ---

--- Player proto ---

proto_player = {}
proto_player.__index = proto_player

function proto_player:new()
    local instance = {
        coords = {
            x = config.player.initial_coords.x,
            y = config.player.initial_coords.y
        },
        vel = {
            x = 0,
            y = 0
        },
        speed = config.player.speed,
        directionFacing = config.player.initial_directionFacing

    }

    setmetatable(instance, self)
    return instance
end

function proto_player:update()

    local playerImpetus = self:getInput()

    -- env.checkMovement(playerImpetus)

end

function proto_player:draw()
    spr(config.player.sprite_id, self.coords.x, self.coords.y)
end


--Returns player's intended impetus as a table of left, right, up, down
--Values can be either true or nil, e.g. "if player.impetus.left then vel.x -= 8"
--Thus, other code can use this straightforward representation.
function proto_player:getInput()
    local impetus = {
        left = nil,
        right = nil,
        up = nil,
        down = nil
    }
    local input = {
        x = 0,
        y = 0
    }

    --Interpret input in a way that is flexible and robust to opposing buttons as well as both control schemes.
    if btn(0, 0) or btn(0, 1) then input.x -= 1 end
    if btn(1, 0) or btn(1, 1) then input.x += 1 end
    if btn(2, 0) or btn(2, 1) then input.y -= 1 end
    if btn(3, 0) or btn(3, 1) then input.y += 1 end

    --Formulate table in an easy to understand way so that
    --Other code can use this straightforward representation.
    if input.x == 0 then
        impetus.left, impetus.right = nil
    elseif input.x == -1 then
        impetus.left = true
    elseif input.x == 1 then
        impetus.right = true
    else
        impetus.left, impetus.right = nil
        assert(false, "Invalid input.x: " .. input.x)
    end

    if input.y == 0 then
        impetus.up, impetus.down = nil
    elseif input.y == -1 then
        impetus.up = true
    elseif input.y == 1 then
        impetus.down = true
    else
        impetus.up, impetus.down = nil
        assert(false, "Invalid input.y: " .. input.y)
    end

    return impetus
end

function proto_player.receiveMovement()

    -- if success then [change player coords]

    -- else [less]

end

--- env Functions ---

-- env object proto
proto_env = {}
proto_env.__index = proto_env

function proto_env:new()
    local instance = {
        -- env rendering properties
        tile_size = config.env.tileSize,
        screen_x = 0,
        screen_y = 0,
    }

    setmetatable(instance, self)
    return instance
end

function proto_env:update()



end

function proto_env:draw()
    -- Draw the env section using level-specific tile origin or fallback
    local tile_x = self.tile_origin.x or 0
    local tile_y = self.tile_origin.y or 0

    env(
        tile_x,
        tile_y,
        self.screen_x,
        self.screen_y,
        self.width,
        self.height
    )
end

function proto_env.checkMovement(intent)

    foo = (player.coords + (intent * player.speed))

end

--- Level Functions ---
        --[[
        level parameters =
        level_title, coords_spawn,
        zone_success, coords_tileOrigin, coords_key, table_hazards, levelTimer
        ]]--

proto_level = {}
proto_level.__index = proto_level

function proto_level:new(level_title, coords_spawn, zone_success, coords_tileOrigin, coords_key, table_hazards, levelTimer)
    local instance = {
        level_title = level_title,
        coords_spawn = coords_spawn,
        zone_success = zone_success,
        coords_tileOrigin = coords_tileOrigin,
        coords_key = coords_key,
        table_hazards = table_hazards,
        levelTimer = levelTimer
    }

    setmetatable(instance, self)
    return instance
end

function proto_level:update()

end

--- Draw Functions ---

function draw.clear_screen()
    cls()
end

--
--
--

__gfx__
00000000002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001cccccc01cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001cccccc01cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001c33bbbb1c33bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001c3bbbbb1c3bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001133bbbb1133bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
