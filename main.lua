-- Love2D v11.4

function love.load()
	-- Import utility library
	require("libs/utils")

    -- for name, i in pairs(love.graphics.getSupported()) do
    -- 	print(name, i)
    -- end

    -- Fonts and sounds
    FONT_SMALL = love.graphics.newFont("assets/fonts/RobotoCondensed-Bold.ttf", 8*WINDOWSCALE)
    FONT_SMALL:setFilter("linear")
    love.graphics.setFont(FONT_SMALL)

    -- Fonts and sounds
    FONT_LARGE = love.graphics.newFont("assets/fonts/RobotoCondensed-Bold.ttf", 16*WINDOWSCALE)
    FONT_LARGE:setFilter("linear")

    local Game = require("game")
    GameWorldState = require("states/game_world")
    MainMenuState = require("states/main_menu")

    GAME = Game:new()

    game_world_state = GameWorldState:new()
    GAME:enterState(game_world_state)

    SCREEN_SHAKING = 0
    GAME_SPEED = 1

	FPS = 60
end

function love.update(dt)

	dt = dt*GAME_SPEED

	GAME:checkInputs()
	GAME.current_state:update(dt)

	FPS = love.timer.getFPS()
end

function love.draw()
	GAME.current_state:draw()
end

function love.keypressed(key, scancode, isrepeat)
    for action, bind in pairs(GAME.options) do
        if bind == key then
            GAME.actions[action] = true
            break
        end
    end
end

function love.keyreleased(key, scancode)
     for action, bind in pairs(GAME.options) do
        if bind == key then
            GAME.actions[action] = false
            break
        end
    end
end

function love.textinput(text)
    --pass
end

function love.gamepadpressed(joystick, button)
    local name = joystick:getName()
    local index = joystick:getConnectedIndex()
    print(string.format("Changing active gamepad to #%d '%s'.", index, name))
end

function love.joystickadded(joystick)
	GAME.active_joystick = joystick
end


