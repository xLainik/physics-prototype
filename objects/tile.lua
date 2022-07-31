local Tile = {}
Tile.__index = Tile

local function newTile(x, y, z, quad)
    local self = setmetatable({}, Tile)

    self.x = x
    self.y = y
    self.z = z
    self.quad = quad

    return self
end

function Tile:update(dt)
    --pass
end

return newTile