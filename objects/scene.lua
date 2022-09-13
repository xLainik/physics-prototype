local Scene = {}
Scene.__index = Scene

local function newScene(index)
    local self = setmetatable({}, Scene)

    self.index = index

    return self
end

function Scene:update(dt)
    --pass
end

function Scene:draw()
    --pass
end

return newScene