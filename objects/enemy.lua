local Enemy = {}
Enemy.__index = Enemy

local machine = require('libs/state_machine')

local function newEnemy(x, y)
    local self = setmetatable({}, Enemy)

    

    --Position of the circle center
    self.x = x or 50
    self.y = y or 50
    self.radius = 20

    self.angle = 0
    self.speed = 0

    self.idle_timer = 0
    self.wander_timer = 0

    -- State machine
    self.state_machine = machine.create({
        initial = "idle",
        events = {
            { name = "wander", from = {"idle", "chasing"}, to = "wandering"},
            { name = "chase",  from = "idle",  to = "chasing" },
            { name = "calmdown", from = {"wandering", "chasing"}, to = "idle"}},
        callbacks = {
            onenterwandering = function() self:onenterwandering() end,
            onenteridle = function() self:onenteridle() end
            }
        })

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
    --self.body:setMass(5)
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5)

    self.Ray = {
        x1 = 0,
        y1 = 0,
        x2 = 0,
        y2 = 0,
        hitList = {}
    }

    -- Fixture Category and Mask
    self.fixture:setCategory(3)
    self.fixture:setMask(2)
    self.fixture:setUserData(self)

    return self
end

function Enemy:worldRayCastCallback(fixture, x, y, xn, yn, fraction)
    local hit = {}
    hit.fixture = fixture
    hit.x, hit.y = x, y
    hit.xn, hit.yn = xn, yn
    hit.fraction = fraction

    table.insert(self.Ray.hitList, hit)

end

function Enemy:onenteridle()
    --print("onenteridle")
    self.body:setLinearVelocity(0, 0)
    self.idle_timer = 0
end

function Enemy:onenterwandering()
    --print("onenterwandering")
    self.speed = 16
    self.angle = math.random(0, 2*math.pi)
    self.body:setLinearVelocity(math.cos(self.angle)*self.speed, math.sin(self.angle)*self.speed)
    self.wander_timer = 0
end

function Enemy:update(dt)

    -- State handling
    if self.state_machine:is("idle") then
        --print("new state: idle", tostring(self.idle_timer))
        self.idle_timer = self.idle_timer + dt
        if self.idle_timer > 4 then
            self.state_machine:wander()
            --print("transition: wander")

        end
    elseif self.state_machine:is("wandering") then
        --print("new state: wandering", tostring(self.wander_timer))
        self.wander_timer = self.wander_timer + dt

        

        if self.wander_timer > 12 then
            self.state_machine:calmdown()
            --print("transition: calmdown")
        end
    end

    self.x, self.y = self.body:getX(), self.body:getY()

    -- Raycast
    self.Ray.hitList = {}
    self.Ray.x1, self.Ray.y1 = self.x, self.y
    self.Ray.x2, self.Ray.y2 = self.x - 400, self.y
    
    -- Cast the ray and populate the hitList table.
    WORLD:rayCast(self.Ray.x1, self.Ray.y1, self.Ray.x2, self.Ray.y2, function(fixture, x, y, xn, yn, fraction) self:worldRayCastCallback(fixture, x, y, xn, yn, fraction) return 1 end)

    -- for i, hit in ipairs(self.Ray.hitList) do
    --     print(i, hit.x, hit.y, hit.xn, hit.xy, hit.fraction)
    -- end
    
end

function Enemy:debugDraw()
    love.graphics.setColor(0.95, 0.2, 0.35)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius, 6)

    -- raycast
    love.graphics.setLineWidth(3)
    love.graphics.setColor(255, 255, 255, 100)
    love.graphics.line(self.Ray.x1, self.Ray.y1, self.Ray.x2, self.Ray.y2)
    love.graphics.setLineWidth(1)

    -- Drawing the intersection points and normal vectors if there were any.
    for i, hit in ipairs(self.Ray.hitList) do
        love.graphics.setColor(255, 0, 0)
        love.graphics.print(i, hit.x, hit.y) -- Prints the hit order besides the point.
        love.graphics.circle("line", hit.x, hit.y, 3)
        love.graphics.setColor(0, 255, 0)
        love.graphics.line(hit.x, hit.y, hit.x + hit.xn * 25, hit.y + hit.yn * 25)
    end
end

function Enemy:setPosition(x, y)
    self.body:setPosition(x, y)
end

function Enemy:gotHit(entity, xn, yn)
    print("Enemy got hit")
end

return newEnemy