local Enemy = {}
Enemy.__index = Enemy

local machine = require('libs/state_machine')

local function newEnemy(x, y, z)
    local self = setmetatable({}, Enemy)

    --Position of the circle center
    self.x = x or 50
    self.y = y or 50
    self.z = z or 50
    
    self.radius = 7.5

    self.angle = 0
    self.speed = 0

    self.dz = -8
    self.z_gravity = -8
    self.max_falling = -200

    -- Variables for jumping
    self.top_floor = 1000
    self.bottom_floor = -1000

    self.idle_timer = 0
    self.wander_timer = 0

    self.depth = 24
    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2

    self.z_offset = 20

    local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    self.model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, scale)

    -- -- State machine
    -- self.state_machine = machine.create({
    --     initial = "idle",
    --     events = {
    --         { name = "wander", from = {"idle", "chasing"}, to = "wandering"},
    --         { name = "chase",  from = "idle",  to = "chasing" },
    --         { name = "calmdown", from = {"wandering", "chasing"}, to = "idle"}},
    --     callbacks = {
    --         onenterwandering = function() self:onenterwandering() end,
    --         onenteridle = function() self:onenteridle() end
    --         }
    --     })

    self.userData = {
        position = {self.x, self.y},
        stamina = 1,
        alive = true
        }

    self.tree = tree.newTree()

    self.idle_action = self.tree.createAction("idle", self.idle_inizializeFunction, self.idle_updateFunction, nil, self)
    self.wander_action = self.tree.createAction("wander", self.wander_inizializeFunction, self.wander_updateFunction, self.wander_cleanUpFunction, self)
    self.die_action = self.tree.createAction("die", self.die_inizializeFunction, nil, nil, self)
    self.hasStamina_evaluator = self.tree.createEvaluator("hasStamina", self.hasStamina_evalFunction, self)
    self.isAlive_evaluator = self.tree.createEvaluator("isAlive", self.isAlive_evalFunction, self)

    self.isAlive_branch = self.tree.createBranch("isAlive")
    self.hasStamina_branch = self.tree.createBranch("hasStamina")

    self.isAlive_branch:setEvaluator(self.isAlive_evaluator)
    self.isAlive_branch:addChild(self.die_action, 1)
    self.isAlive_branch:addChild(self.hasStamina_branch, 2)

    self.hasStamina_branch:setEvaluator(self.hasStamina_evaluator)
    self.hasStamina_branch:addChild(self.idle_action, 1)
    self.hasStamina_branch:addChild(self.wander_action, 2)

    self.tree:setBranch(self.isAlive_branch)

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
    self.body:setFixedRotation(true)
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5)

    -- Fixture Category and Mask
    self.fixture:setCategory(3)

    -- Flat hitbox
    self.width_flat, self.height_flat = 16, 16
    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, self.body:getY()*(0.8125) - self.height_flat/2 - self.z_offset
    self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_offset

    --self.shape_flat = love.physics.newCircleShape(self.radius)
    --self.shape_flat:setPoint(0, -self.z_offset)
    local x, y = self.width_flat/2, self.height_flat/2 
    self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_offset, x, -y -self.z_offset, -x, y -self.z_offset, x, y -self.z_offset)
    self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat, 0.5)

    self.fixture_flat:setSensor(true)

    self.fixture_flat:setCategory(6)

    -- Shadow
    self.shadow = newShadow(self)
    self:setHeight()

    -- self.Ray = {
    --     x1 = 0,
    --     y1 = 0,
    --     x2 = 0,
    --     y2 = 0,
    --     hitList = {}
    -- }

    return self
end

--[[function Enemy:worldRayCastCallback(fixture, x, y, xn, yn, fraction)
    local hit = {}
    hit.fixture = fixture
    hit.x, hit.y = x, y
    hit.xn, hit.yn = xn, yn
    hit.fraction = fraction

    table.insert(self.Ray.hitList, hit)

end--]]

-- AI Evaluation Functions -------------------------------------

function Enemy:isAlive_evalFunction()
    print("Evaluating alive", self.userData.alive)
    return self.userData.alive ~= nil and self.userData.alive == true
end

function Enemy:hasStamina_evalFunction()
    print("Evaluating stamina", self.userData.stamina)
    return self.userData.stamina ~= nil and self.userData.stamina > 0
end

-- AI Actions -------------------------------------

function Enemy:die_inizializeFunction()
    print("Inizialize Die Action")
    self.body:setLinearVelocity(0, 0)
end

function Enemy:idle_inizializeFunction()
    print("Inizialize Idle Action")
    self.body:setLinearVelocity(0, 0)
    self.idle_timer = 0
end

function Enemy:idle_updateFunction(dt)
    self.idle_timer = self.idle_timer + dt
    --print("Update Idle Action", self.idle_timer)
    return "RUNNING"
end

function Enemy:wander_inizializeFunction()
    print("Inizialize Wander Action")
    self.speed = 8
    self.angle = math.random(0, 2*math.pi)
    self.wander_timer = 0
end

function Enemy:wander_updateFunction(dt)
    self.wander_timer = self.wander_timer + dt
    --print("Update Wander Action", self.wander_timer)
    if self.wander_timer > 2 then
        return "TERMINATED"
    else
        return "RUNNING"
    end
end

function Enemy:wander_cleanUpFunction()
    print("CleanUp Wander Action")
    self.speed = 0
    self.wander_timer = 0
end

function Enemy:update(dt)

    -- Behavior tree update
    self.tree:update(dt)

    if self.speed > 0 then
        self.body:setLinearVelocity(math.cos(self.angle) * self.speed, math.sin(self.angle) * self.speed)
    end

    -- Apply gravity
    if self.dz > self.max_falling then
        self.dz = self.dz + self.z_gravity
    end

    -- Check top and bottom floor, and then apply z velocity
    local new_z = self.z + self.dz*dt
    if self.dz > 0 and new_z + self.depth/2 < self.top_floor then
        self.z = new_z
    elseif self.dz < 0 then
        if new_z - self.depth/2 > self.bottom_floor then
            self.z = new_z
        else
            self.z = self.bottom_floor + self.depth/2 + 0.01
        end
    end

    self.x, self.y = self.body:getX(), self.body:getY()

    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.height_flat/2 - self.z_offset)*(0.8125)
    self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_offset

    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)

    --Shadow
    self.shadow:updatePosition(self.x, self.y, self.z)
    self:updateShadow()

    -- Raycast
    --self.Ray.hitList = {}
    --self.Ray.x1, self.Ray.y1 = self.x, self.y
    --self.Ray.x2, self.Ray.y2 = self.x - 400, self.y
    
    -- Cast the ray and populate the hitList table.
    --WORLD:rayCast(self.Ray.x1, self.Ray.y1, self.Ray.x2, self.Ray.y2, function(fixture, x, y, xn, yn, fraction) self:worldRayCastCallback(fixture, x, y, xn, yn, fraction) return 1 end)

    -- for i, hit in ipairs(self.Ray.hitList) do
    --     print(i, hit.x, hit.y, hit.xn, hit.xy, hit.fraction)
    -- end
    
end

function Enemy:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(shader, camera, shadow_map)
        self.model:draw(shader, camera, shadow_map)
    else
        self.model:draw(shader, camera, shadow_map)
    end
end

function Enemy:debugDraw()
    --love.graphics.setColor(0.95, 0.2, 0.35)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.flat_x, self.flat_y, self.radius)
    --love.graphics.rectangle("line", self.flat_x, self.flat_y, self.width_flat, self.height_flat*(0.8125))

    -- raycast
    --love.graphics.setLineWidth(3)
    --love.graphics.setColor(255, 255, 255, 100)
    --love.graphics.line(self.Ray.x1, self.Ray.y1, self.Ray.x2, self.Ray.y2)
    --love.graphics.setLineWidth(1)

    -- Drawing the intersection points and normal vectors if there were any.
    for i, hit in ipairs(self.Ray.hitList) do
        --love.graphics.setColor(255, 0, 0)
        --love.graphics.print(i, hit.x, hit.y) -- Prints the hit order besides the point.
        --love.graphics.circle("line", hit.x, hit.y, 3)
        --love.graphics.setColor(0, 255, 0)
        --love.graphics.line(hit.x, hit.y, hit.x + hit.xn * 25, hit.y + hit.yn * 25)
    end
end

function Enemy:setPosition(x, y)
    self.body:setPosition(x, y)
end

function Enemy:setHeight()
    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2
    local mask = {11,12,13,14}

    for i, coll_cat in ipairs(mask) do
        local overlap = math.min(self.top, (i)*SCALE3D.z) - math.max(self.bottom, (i-1)*SCALE3D.z)
        if overlap >= 0 then
            -- the player overlaps the floor range, either from the bottom (or top)
            table.remove(mask, i)
            if overlap == self.depth then
                -- the overlap is the whole player's depth
                break
            else
                -- remove the next floor on top (which now is at index i, not i+1)
                table.remove(mask, i)
                break
            end
        end
    end
    -- category 1 are shadows
    self.fixture:setMask(1,2,3,4,5,6,7,8,9, unpack(mask))
    self.fixture:setUserData(self)

    self.fixture_flat:setMask(1,2,3,4,5,8,9, unpack(mask))
    self.fixture_flat:setUserData(self)
end

function Enemy:gotHit(entity)
    --print("Enemy got hit: ", entity.fixture:getCategory())
end
function Enemy:exitHit(entity)
    --print("Enemy exited a collision")
end

function Enemy:hitboxGotHit(entity)
    --print("Enemy Hitbox got hit: ", entity.fixture:getCategory())
end
function Enemy:hitboxExitHit(entity)
    --print("Enemy Hitbox exited a collision")
end

function Enemy:updateShadow()
    local bottom_buffer = {}
    for i=#self.shadow.floor_buffer,1,-1 do
        -- read the buffer from top to bottom
        local floor = self.shadow.floor_buffer[i]
        local bottom = floor - SCALE3D.z
        if floor <= self.bottom then
            self.bottom_floor = floor
            self.top_floor = bottom_buffer[#bottom_buffer] or 1000
            break
        elseif bottom >= self.top then
            table.insert(bottom_buffer, bottom)
        end
    end
end

return newEnemy