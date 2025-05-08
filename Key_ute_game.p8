pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--🔑ute Game (or :key:ute game)
--idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
--for Cassie ♥
--⬅️➡️⬆️⬇️
--Technical note: In the comments I use commands like "region", "endregion", "tag" which shouldn't have any effect in-engine; they are due to my using the plug-in 'Outline Map' to organize my code.

--[[ #region Initialization ]]

util = {}

init = {}
update = {}
draw = {}
--Decided to make these tables global, may change my mind later.

function _init()

    init.config()

    init[gameState]()

end

--[[ #endregion Initialization ]]

--[[ #region Game-Flow ]]

--When the player's latest lifecycle is starting, set starting conditions.
function init.game()

    _update = update.game
    _draw = draw.game

    player = class_player:new()

end

--Each cycle, check game conditions and execute ongoing logic.
function update.game()

    table_playerIntent = update.input()
    player.update()

end

--Each cycle, draw the screen as the player will see it in progressive layers; earliest is bottom-most layers, latest is top-most.
function draw.game()

    draw.clearScreen()

    draw.map()

    player.draw()

end

--[[ #endregion Game-Flow ]]

--Menu flow won't be implemented for a while. TODO
--[[ #region Menu-Flow ]]

function init_menu()

end

function update_menu()

end

function draw_menu()

end

--[[ #endregion Menu-Flow ]]

--[[ #region Utility-Functions ]]

function util.troubleshooting(uniqueID, errorMessage)

    if not queue_troubleshooting then
        queue_troubleshooting = {}
    end

    add(queue_troubleshooting, errorMessage, uniqueID)

end

--[[ #endregion Utility-Functions ]]

--[[ #region initialize-Functions ]]

function init.config()

    local config = {

        skipIntoGame = true,
        level_initial = 1,
        init.levels()
    }

    if config.skipIntoGame then
        gameState = "game"
    else
        gameState = "menu"
    end

end

-- TODO I got carried away making this, I'll return to it.
function init.levels()

    levels = {}

    level_title = {
        "level_I",
        "level_heart",
        "level_u"
    }
    coords_spawn = {
        {x = 1, y = 2},
        {},
        {}
    }
    zone_success = {
        {zone.x1 = 1, zone.y1 = 1, zone.x2 = 2, zone.y2 = 2},
        {},
        {}
    }
    coords_tileOrigin = {
        {x = 1, y = 1},
        {},
        {}
    }
    coords_key =
    table_hazards =
    levelTimer =

    function levels.new(level_index)

        level_title[level_index]

    end

end

--[[ #endregion initialize-Functions ]]

--[[ #region Update-Functions ]]

--Returns player's intended impetus as a table of left, right, up, down
--Values can be either true or nil, e.g. "if player.impetus.left then vel.x -= 8"
--Thus, other code can use this straightforward representation.
function update.input()

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
        util.troubleshooting("input_x", "Invalid input.x: " .. input.x)
    end

    if input.y == 0 then
        impetus.up, impetus.down = nil
    elseif input.y == -1 then
        impetus.up = true
    elseif input.y == 1 then
        impetus.down = true
    else
        impetus.up, impetus.down = nil
        util.troubleshooting("input_y", "Invalid input.y: " .. input.y)
    end

    return impetus
end

local class_player = {}
class_player.__index = class_player

function class_player:new()

    local new_player = {}
    setmetatable(new_player, class_player)



    return new_player

end

--[[ #endregion Update-Functions ]]

--[[ #region Draw-Functions ]]

function draw.clearScreen()

    cls()

end

function draw.map()

    circfill(60, 60, 20, 1)

end

function draw.object(object)

    sprite = object.sprite
    spr(sprite.initial, object.coords.x, object.coords.y)

end

--[[ #endregion Draw-Functions ]]









__gfx__
00000000002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001cccccc01cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001cccccc01cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001c33bbbb1c33bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001c3bbbbb1c3bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001133bbbb1133bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
