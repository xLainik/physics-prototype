-- Love2D v11.4

function love.load()
	-- Import utility library
	require("libs/utils")

    -- for name, i in pairs(love.graphics.getSupported()) do
    -- 	print(name, i)
    -- end

    -- Basic love config
    love.graphics.setDefaultFilter("nearest") --no atialiasing

    local Game = require("game")

    GAME = Game:new() 

    GAME:enterState("main_menu")

	FPS = 60
end

function love.update(dt)

	dt = dt*GAME.GAME_SPEED

	GAME:checkInputs()
	GAME.cursor:update(dt)
	GAME.current_state:update(dt)

	FPS = love.timer.getFPS()
end

function love.draw()
	GAME.current_state:draw()
	love.graphics.setCanvas()
	love.graphics.draw(GAME.main_canvas, -16, -16, 0, WINDOWSCALE, WINDOWSCALE, GAME.CANVAS_OFFSET[1], GAME.CANVAS_OFFSET[2])
	GAME.current_state:drawUI()
	GAME.cursor:screenDraw()
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


