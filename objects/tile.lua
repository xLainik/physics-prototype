local Tile = {}
Tile.__index = Tile

local function newTile(x, y, z, instance_index)
    local self = setmetatable({}, Tile)

    self.x = x
    self.y = y
    self.z = z
    self.index = instance_index

    return self
end

function Tile:update(dt)
    --pass
end

return newTile