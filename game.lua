local Game = {}
Game.__index = Game

local function newGame()
    local self = setmetatable({}, Game)

    self.state_stack = {}
    self.current_state = nil

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

return newGame