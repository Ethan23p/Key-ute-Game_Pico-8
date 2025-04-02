pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--🔑ute Game (or :key:ute game)
--idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
--for Cassie ♥
--⬅️➡️⬆️⬇️
--Technical note: In the comments I use commands like "region", "endregion", "tag" which shouldn't have any effect in-engine; they are due to my using the plug-in 'Outline Map' to organize my code.

--[[ #region Initialization ]]

utilities = {}

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
local function initialize_game()

    _update = update.game
    _draw = draw.game

    player = init.create_player()

end
init.game = initialize_game

--Each cycle, check game conditions and execute ongoing logic.
local function update_game()



end
update.game = update_game

--Each cycle, draw the screen as the player will see it in progressive layers; earliest is bottom-most layers, latest is top-most.
local function draw_game()

    draw.clearScreen()

    draw.map()

    draw.object(player)

end
draw.game = draw_game

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

function return_foo()

    return "foo"

end

--[[ #endregion Utility-Functions ]]

--[[ #region initialize-Functions ]]

function init.config()

    config = {

        skipIntoGame = true

    }

    if config.skipIntoGame then
        gameState = "game"
    else
        gameState = "menu"
    end

end

--player = init.create-player()
function init.create_player()

    player_character = {
        coords = {
            x = 60,
            y = 60
        },
        velocity = {
            x = 0,
            y = 0
        },
        direction = "⬅️",
        sprite = {
            initial = 1
        }
    }

    return player_character

end

--[[ #endregion initialize-Functions ]]

--[[ #region Update-Functions ]]

--Returns player's intended impetus as a table of left, right, up, down
--Values can be either true or nil, e.g. "if player.impetus.left then vel.x -= 8"
--Thus, other code can use this straightforward representation.

local function player_input()

    impetus = {
        x = nil,
        y = nil
    }
    impetus = {
        left = nil,
        right = nil,
        up = nil,
        down = nil
    }
    input = {
        x = 0,
        y = 0
    }

    --if left, -1 to x velocity
    --if right, +1 to x velocity
    --if up, -1 to y velocity
    --if down, +1 to y velocity

    if btn(0, 0) or btn(0, 1) then input.x -= 1 end
    if btn(1, 0) or btn(1, 1)  then input.x += 1 end
    if btn(2, 0) or btn(2, 1) then input.y -= 1 end
    if btn(3, 0) or btn(3, 1) then input.y += 1 end

    if input.x == -1 then
        impetus.x = "left"
    elseif input.x == 1 then
        impetus.x = "right"
    else
        impetus.x = nil
    end

    if input.y == -1 then
        impetus.y = "up"
    elseif input.y == 1 then
        impetus.y = "down"
    else
        impetus.y = nil
    end

    return impetus

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
