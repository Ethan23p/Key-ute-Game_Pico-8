pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--🔑ute Game (or :key:ute game)
--idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
--Code is incomplete, many parts still missing.
--The concept is (spoiler alert) the player navigates (2d, birds eye view) through 3 levels while avoiding hazards and pressured by a timer;
--when they complete the third level they're presented with a compressed view of all 3 maps;
--then a 'ghost' recording of their character loops speedily through the actually path they took through the levels, leaving particles behind as it goes. Then a twist takes form - the maps were designed to make the player navigate such that it forms the message: 'I' '♥' 'U'. Concept by Nicky Case, it made for the perfect tiny project to learn the Pico-8.
--Principles I'm grappling with:
--Tell, don't ask
--encapsulation
--Going for a 'table of contents' style of organization
--for Cassie ♥
--⬅️➡️⬆️⬇️

util = {}

init = {}
update = {}
draw = {}

--
function _init()
    --init flow / flow (game, menu, message) TODO

    init.config()

    player = blueprint_player:new()
    map = blueprint_map:new()
end

--
function _update()
    map:update()
    player:update()
    --update.conditions()
end

--
function _draw()
    draw.clear_screen()
    map:draw()
    --game_door:draw()
    --game_key:draw()
    player:draw()
    --game_hazards:draw()
    --game_overlay:draw()
end

--- Init Functions ---

function init.config()
    --The config definitions will stay here, easy to access.
    config = {
        player = {
            initial_coords = { x = 64, y = 64 },
            speed = 8,
            initial_directionFacing = "➡️",
            sprite_id = 1
        },
        map = {
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

--- Player Blueprint ---

blueprint_player = {}
blueprint_player.__index = blueprint_player

function blueprint_player:new()
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

function blueprint_player:update()

    local playerImpetus = self:getInput()

end

function blueprint_player:draw()
    spr(config.player.sprite_id, self.coords.x, self.coords.y)
end


--Returns player's intended impetus as a table of left, right, up, down
--Values can be either true or nil, e.g. "if player.impetus.left then vel.x -= 8"
--Thus, other code can use this straightforward representation.
function blueprint_player:getInput()
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

--- Map Functions ---

-- Map object blueprint
blueprint_map = {}
blueprint_map.__index = blueprint_map

function blueprint_map:new()
    local instance = {
        -- Map rendering properties
        tile_size = config.map.tileSize,
        screen_x = 0,
        screen_y = 0,
        -- Map data properties
        width = 16,  -- tiles
        height = 16, -- tiles
    }
    
    setmetatable(instance, self)
    return instance
end

function blueprint_map:update()

end

function blueprint_map:draw()
    -- Draw the map section
    map(
        self.tile_origin.x, 
        self.tile_origin.y, 
        self.screen_x,
        self.screen_y,
        self.width, 
        self.height
    )
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
