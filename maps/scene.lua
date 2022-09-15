local Scene = {}
Scene.__index = Scene

function Scene:new()
    local self = setmetatable({}, Scene)

    return self
end

function Scene:update(dt)
    --pass
end

function Scene:draw()
    --pass
end

function Scene:drawUI()
    --pass
end

return Scene