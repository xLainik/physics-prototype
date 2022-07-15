local Player = {}
Player.__index = Player

local function newPlayer(x, y, z, model, cursor)
    local self = setmetatable({}, Player)

    self.cursor = cursor
    self.model = model

    --Position of the circle center
    self.x = x or 50
    self.y = y or 50
    self.z = z or 0
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

    -- Fixture Category and Mask
    self.fixture:setCategory(2)
    self.fixture:setMask()
    self.fixture:setUserData(self)

    --2 -> Player
    --3 -> Enemies 1
    --4 -> Enemies 2
    --5 -> Enemies 3
    --6 -> Player attacks 1
    --7 -> Player attacks 2
    --8 -> Enemy attacks 1
    --9 -> Enemy attacks 2
    --10 -> Unbreakable terrain
    --11 -> Breakable terrain

    return self
end

function Player:update(dt)

    local force = 1200

    -- Input handling
    -- Keyboard Input
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
        --when the key is released, the body stops instanly
        self.body:setLinearVelocity(0 , 0)
    end

    if love.keyboard.isDown("space") then
        self.z = self.z + 500*dt
    elseif love.keyboard.isDown("lshift") then
        self.z = self.z - 500*dt
    end

    -- Mouse Input
    if self.cursor:click() then
        table.insert(SPAWNQUEUE, {group = "Projectile", args = {self.x, self.y, 10, 750, getAngle(self.x,self.y, self.cursor.x, self.cursor.y)}})
    end

    self.body:applyForce(math.cos(self.angle) * force, math.sin(self.angle) * force)

    self.x, self.y = self.body:getX(), self.body:getY()

end

function Player:debugDraw()
    love.graphics.setColor(0.9, 0.8, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius, 6)
end

function Player:draw(shader, camera, shadow_map)
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
    self.model:draw(nil, camera, false)
end

function Player:setPosition(x, y)
    self.body:setPosition(x, y)
end

function Player:gotHit(entity, xn, yn)
    --print("Player got hit")
end

return newPlayer