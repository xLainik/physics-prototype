local Projectile = {}
Projectile.__index = Projectile

local function newProjectile(x, y, radius, ini_speed, ini_angle)
    local self = setmetatable({}, Projectile)

    --Position of the rectangle center
    self.x = x + radius/2 or 50
    self.y = y + radius/2 or 50
    self.radius = radius or 50

    self.active = true

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
    --self.body:setMass(0)
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(6)
    self.fixture:setMask(2)
    self.fixture:setUserData(self)
    self.fixture:setSensor(true)
    self.body:setBullet(true) --slower processing

    if ini_speed then
        self:setVelocity(ini_speed, ini_angle)
    else
        self.speed = 0
        self.angle = 0
    end

    return self
end

function Projectile:setVelocity(speed, angle)
    self.speed = speed
    self.angle = angle
    self.body:setLinearVelocity(math.cos(self.angle)*self.speed, math.sin(self.angle)*self.speed)
end

function Projectile:update(dt)
    self.x, self.y = self.body:getX(), self.body:getY()
end

function Projectile:debugDraw()
    love.graphics.setColor(0.9, 0.8, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius, 6)
end

function Projectile:gotHit(entity, xn, yn)
    --print("Projectile got hit")
    self.active = false
end
function Projectile:exitHit(entity, xn, yn)
    --print("Projectile exited a collision")
end

return newProjectile