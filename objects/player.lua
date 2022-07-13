local Player = {}
Player.__index = Player

local function newPlayer(x, y)
    local self = setmetatable({}, Player)

    --Position of the circle center
    self.x = x or 50
    self.y = y or 50
    self.radius = 20

    self.angle = 0

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
    self.body:setMass(4)
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5)

    self.body:setLinearDamping(5)
    --self.body:setInertia(0)
    self.fixture:setFriction(1.0)

    return self
end

function Player:update(dt)

    local force = 1200

    -- Input handling
    if love.keyboard.isDown("a") and love.keyboard.isDown("w") then
      self.angle = math.pi*1.25
    elseif love.keyboard.isDown("d") and love.keyboard.isDown("w")then
      self.angle = math.pi*1.75 
    elseif love.keyboard.isDown("a") and love.keyboard.isDown("s") then
      self.angle = math.pi*0.75
    elseif love.keyboard.isDown("d") and love.keyboard.isDown("s") then
      self.angle = math.pi*0.25
    elseif love.keyboard.isDown("d") then
        self.angle = 0
    elseif love.keyboard.isDown("a") then
        self.angle = math.pi
    elseif love.keyboard.isDown("w") then
        self.angle = math.pi*1.50
    elseif love.keyboard.isDown("s") then
        self.angle = math.pi*0.50
    else
        force = 0
        --when the key is released, the body sets still instanly
        self.body:setLinearVelocity(0 , 0)
    end

    self.body:applyForce(math.cos(self.angle) * force, math.sin(self.angle) * force)

    self.x, self.y = self.body:getX(), self.body:getY()

end

function Player:debugDraw()
    love.graphics.setColor(0.9, 0.8, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius, 6)
end

function Player:setPosition(x, y)
    self.body:setPosition(x, y)
end

return newPlayer