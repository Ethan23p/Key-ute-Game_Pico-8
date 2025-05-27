pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--🔑ute Game (or :key:ute game)
--idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
--Code is incomplete, many parts still missing
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
            speed = 8,
            facing = "➡️"
        }
    }

    player = player_controller.new()

end

--
function _update()

    --game systems
    --game conditions

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

-- Not implemented yet TODO
function util.query_boundary(coords)
    return false
end

player_controller = {
    speed = config.player.speed,
    facing = config.player.facing
}
player_controller.__index = player_controller

function player_controller:new()

    local instance = {
        coords = {
            x = 32,
            y = 32
        },
        vel = {
            x = 0,
            y = 0
        }
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

    spr(1, self.coords.x, self.coords.y)

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
    if btn(1, 0) or btn(1, 1)  then input.x += 1 end
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
