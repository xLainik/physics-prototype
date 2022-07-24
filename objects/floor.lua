local Floor = {}
Floor.__index = Floor

local function newFloor(model)
    local self = setmetatable({}, Floor)

    self.model = model

    self.shapes = {}

    --Physics
    self.body = love.physics.newBody(WORLD, 0, 0, "static")
    local shape = love.physics.newPolygonShape(self.model, self.model)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(10)
    self.fixture:setUserData(self)

    table.insert(self.shapes, shape)

    return self
end

function Floor:update(dt)
    --pass
end

function Floor:debugDraw()
    love.graphics.setColor(0.85, 0.85, 0.9)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
end

function Floor:draw(shader, camera, shadow_map)
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
    self.model:draw(nil, camera, false)
end

function Floor:gotHit(entity, xn, yn)
    --print("Floor got hit")
end

return newFloor