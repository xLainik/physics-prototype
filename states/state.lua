local State = {}
State.__index = State

function State:new()
   local self = setmetatable({}, Game)

   self.previous_state = nil

   return self
end

function State:onEnter()
    --pass
end

function State:onExit()
    --pass
end

function State:update(dt)
    --pass
end

function State:draw()
    --pass
end

return State