local Game = {}
Game.__index = Game

function Game:new()
    local self = setmetatable({}, Game)

    self.state_stack = {}
    self.current_state = nil

    self:setup_directories()

    self.options = {}
    self.options["up"] = "w"
    self.options["down"] = "s"
    self.options["left"] = "a"
    self.options["right"] = "d"
    self.options["action_1"] = "space"
    self.options["action_2"] = "z"
    self.options["shift"] = "lshift"
    self.options["enter"] = "return"

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
        love.event.quit()
    end
end

function Game:enterState(state)
    if #self.state_stack > 0 then
        self.previous_state = self.state_stack[#self.state_stack]
    end

    table.insert(self.state_stack, state)
    self.current_state = state

    state:onEnter()
end

function Game:exitState()
    if #self.state_stack > 1 then
        self.current_state:onExit()

        table.remove(self.state_stack, self.current_state)
        self.current_state = self.state_stack[#self.state_stack]
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