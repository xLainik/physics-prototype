local Game = {}
Game.__index = Game

function Game:new()
    local self = setmetatable({}, Game)

    -- Game states
    self.state_stack = {}
    self.current_state = nil

    -- Directories
    self:setup_directories()

    -- Screen shake and game speed variables
    self.SCREEN_SHAKING = 0
    self.GAME_SPEED = 1

    -- Cursor
    local newCursor = require("objects/cursor")
    love.mouse.setVisible(false)
    self.cursor = newCursor()

    -- Screen Canvas
    self.main_canvas = love.graphics.newCanvas(SCREENWIDTH, SCREENHEIGHT)
    self.main_canvas:setFilter("nearest","nearest") --no atialiasing
    self.CANVAS_OFFSET = {0, 0}

    -- Fonts and sounds (Better placed elsewhere)
    self.FONT_SMALL = love.graphics.newFont(self.fonts_directory.."/RobotoCondensed-Bold.ttf", 8*WINDOWSCALE)
    self.FONT_SMALL:setFilter("linear")
    love.graphics.setFont(self.FONT_SMALL)

    self.FONT_LARGE = love.graphics.newFont(self.fonts_directory.."/RobotoCondensed-Bold.ttf", 16*WINDOWSCALE)
    self.FONT_LARGE:setFilter("linear")

    -- Options
    self.options = {}
    self.options["up"] = "w"
    self.options["down"] = "s"
    self.options["left"] = "a"
    self.options["right"] = "d"
    self.options["action_1"] = "space"
    self.options["action_2"] = "z"
    self.options["shift"] = "lshift"
    self.options["enter"] = "return"

    -- Inputs -> Actions
    self.actions = {}
    for action, binding in pairs(self.options) do
        self.actions[action] = false
    end

    local joysticks = love.joystick.getJoysticks()
    self.active_joystick = joysticks[1]

    --self.active_joystick:getName()

    return self
end

function Game:checkInputs()
    --General/Debug Inputs
    if love.keyboard.isDown("r") then
        love.event.quit("restart")
    end

    if love.keyboard.isDown("escape") then
        self:exitState()
    end
end

function Game:enterState(state_name)

    local state = require(self.states_directory.."/"..state_name)
    local state_instance = state:new()


    if #self.state_stack > 0 then
        self.previous_state = self.state_stack[#self.state_stack]
    end

    table.insert(self.state_stack, state_instance)
    self.current_state = state_instance

    state_instance:onEnter()
end

function Game:exitState()
    if #self.state_stack > 1 then
        self.current_state:onExit()

        table.remove(self.state_stack)
        self.current_state = self.state_stack[#self.state_stack]
        self.current_state:onEnter()
    end
end

function Game:setup_directories()
    self.game_directory = love.filesystem.getSource()

    self.assets_directory = "assets"
    self.libs_directory = "libs"
    self.maps_directory = "maps"
    self.objects_directory = "objects"
    self.states_directory = "states"

    self.audio_directory = self.assets_directory .. "/audio"
    self.fonts_directory = self.assets_directory .. "/fonts"
    self.models_directory = self.assets_directory .. "/models"
    self.shaders_directory = self.assets_directory .. "/shaders"
    self.sprites_directory = self.assets_directory .. "/sprites"
end

return Game