local Polygon = {}
Polygon.__index = Polygon

local function newPolygon(x, y, z, verts, model)
    local self = setmetatable({}, Polygon)

    self.model = model

    --Position of the rectangle center
    self.x = x or 50
    self.y = y or 50
    self.z = z or 0

    self.verts = {}
    for i, vert in pairs(verts) do
        table.insert(self.verts, vert.x)
        table.insert(self.verts, vert.y)
    end

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "static")
    self.shape = love.physics.newPolygonShape(self.verts)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(10)
    self.fixture:setUserData(self)

    return self
end

function Polygon:update(dt)
    --pass
end

function Polygon:debugDraw()
    love.graphics.setColor(0.85, 0.85, 0.9)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
end

function Polygon:draw(shader, camera, shadow_map)
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
    self.model:draw(nil, camera, false)
end

function Polygon:gotHit(entity, xn, yn)
    --print("Polygon got hit")
end

return newPolygon