pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--🔑ute Game (or :key:ute game)
--idea 100% taken from Nicky Case, code 100% written by me, Ethan Porter
--for Cassie ♥
--⬅️➡️⬆️⬇️

utilities = {}

init = {}
update = {}
draw = {}
--Decided to make these tables global, may change my mind later.

function _init()

    init.config()

    init[gameState]()

end

--Game flow

--When the player's latest lifecycle is starting, set starting conditions.
local function initialize_game()

end
init.game = initialize_game

--Each cycle, check game conditions and execute ongoing logic.
function update_game()

end

--Each cycle, draw the screen as the player will see it in progressive layers; earliest is bottom-most layers, latest is top-most.
function draw_game()

    clearScreen()

    draw_map()

end

--Menu flow won't be implemented for a while. TODO
    function init_menu()

    end

    function update_menu()

    end

    function draw_menu()

    end
--end

--Utility functions

--Initialize functions

function init.config()

    config = {

        skipIntoGame = true,
        gameState = "menu"

    }

    if config.skipIntoGame then
        gameState = "game"
    end

end

function create_player()

    player = {
        coords = {
            x = 60,
            y = 60
        }
    }

end

--Update functions

--Draw functions









__gfx__
00000000002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700002888000028880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001cccccc01cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001cccccc01cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001c33bbbb1c33bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001c3bbbbb1c3bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001133bbbb1133bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
