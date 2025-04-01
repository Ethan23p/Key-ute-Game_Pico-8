pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--🔑ute Game (or :key:ute game)
--idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
--for Cassie ♥ fr
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

    player = init.create_player()

end
init.game = initialize_game

--Each cycle, check game conditions and execute ongoing logic.
function update_game()

end
update.game = update_game

--Each cycle, draw the screen as the player will see it in progressive layers; earliest is bottom-most layers, latest is top-most.
function draw_game()

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



--[[ #endregion Update-Functions ]]

--[[ #region Draw-Functions ]]

function draw.clearScreen()

    cls()

end

function draw.map()

    map(0, 0, 0, 0, 0, 0)

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
