local Box = {}
Box.__index = Box

local function newBox(x, y, z, width, height, model)
    local self = setmetatable({}, Box)

    self.model = model

    --Position of the rectangle center
    self.x = x + width/2 or 50
    self.y = y + height/2 or 50
    self.z = z or 0
    self.width = width or 50
    self.height = height or 50

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "static")
    self.shape = love.physics.newRectangleShape(self.width, self.height)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(10)
    self.fixture:setUserData(self)

    return self
end

function Box:update(dt)
    --pass
end

function Box:debugDraw()
    love.graphics.setColor(0.85, 0.85, 0.9)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
end

function Box:draw(shader, camera, shadow_map)
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
    self.model:draw(nil, camera, false)
end

function Box:gotHit(entity, xn, yn)
    --print("Box got hit")
end

return newBox