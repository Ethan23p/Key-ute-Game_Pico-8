pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--🔑ute Game (or :key:ute game)
--idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
--Code is incomplete, many parts still missing.
--Going for a 'table of contents' style of organization
--The concept is (spoiler alert) the player navigates (2d, birds eye view) through 3 levels while avoiding hazards and pressured by a timer;
--when they complete the third level they're presented with a compressed view of all 3 maps;
--then a 'ghost' recording of their character loops speedily through the actually path they took through the levels, leaving particles behind as it goes. Then a twist takes form - the maps were designed to make the player navigate such that it forms the message: 'I' '♥' 'U'. Concept by Nicky Case, it made for the perfect tiny project to learn the Pico-8.
--for Cassie ♥
--⬅️➡️⬆️⬇️

util = {}

init = {}
update = {}
draw = {}

--
function _init()
    --init config
    --init flow (game, menu, message)
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
    }
    -- Initialize player direction from config
    config.player.directionFacing = config.player.initial_directionFacing -- Let's eliminate this function with a more elegant solution; the config can be primarily initial values.

    player = player_controller:new()
end

--
function _update()
    player:update()
end

--
function _draw()
    draw.clear_screen()
    --draw map
    draw.background()
    player:draw()
    --draw overlay (timer, particles)
end
--- Utility Functions ---

-- Checks if the given screen coordinates (coords.x, coords.y)
-- fall on a map tile that is considered a boundary.
-- A boundary is defined as a tile with the predefined sprite flag set.
function util.query_boundary(coords)
    -- Ensure necessary config values are available; otherwise, it's safer to assume a boundary
    -- or handle the error as appropriate for your game's logic.
    if not config or not config.map or not config.map.tileSize or not config.map.boundary_flag_id then
        printh("Error: Missing map config in util.query_boundary. Assuming boundary.")
        return true
    end

    local tile_size = config.map.tileSize
    local map_x = flr(coords.x / tile_size)
    local map_y = flr(coords.y / tile_size)

    local sprite_id = mget(map_x, map_y)
    local sprite_flags = fget(sprite_id)

    -- Calculate the bitmask for the configured boundary flag
    local boundary_flag_bitmask = 2^config.map.boundary_flag_id
    return band(sprite_flags, boundary_flag_bitmask) > 0
end

--- Player Controller ---

player_controller = {}
player_controller.__index = player_controller

function player_controller:new()
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

function player_controller:update()
    local playerImpetus = self:getInput()

    local coords_intended = self:query_intendedCoords(playerImpetus)

    if not util.query_boundary(coords_intended) then
        self.coords = coords_intended
    end
end

function player_controller:draw()
    spr(config.player.sprite_id, self.coords.x, self.coords.y)
end

function player_controller:query_intendedCoords(impetus)
    local intended_coords = {
        x = self.coords.x,
        y = self.coords.y
    }
    local current_speed = self.speed

    if impetus.left then
        intended_coords.x -= current_speed
        self.directionFacing = "⬅️"
    elseif impetus.right then
        intended_coords.x += current_speed
        self.directionFacing = "➡️"
    end

    if impetus.up then
        intended_coords.y -= current_speed
    elseif impetus.down then
        intended_coords.y += current_speed
    end

    return intended_coords
end

--Returns player's intended impetus as a table of left, right, up, down
--Values can be either true or nil, e.g. "if player.impetus.left then vel.x -= 8"
--Thus, other code can use this straightforward representation.
function player_controller:getInput()
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

--- Draw Functions ---

function draw.clear_screen()
    cls()
end

function draw.background()
    circfill(60, 60, 20, 1)
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
