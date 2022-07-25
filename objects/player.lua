local Player = {}
Player.__index = Player

local newShadow = require("objects/shadow")

local function newPlayer(x, y, z, cursor)
    local self = setmetatable({}, Player)

    self.cursor = cursor

    -- Position of the xyz center in 3D
    self.x = x or 50
    self.y = y or 50
    self.z = z or 0
    self.radius = 7

    self.depth = 24
    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2

    self.angle = 0

    local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    self.model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, scale)

    -- Variables for jumping
    self.top_floor = 1000
    self.bottom_floor = -1000
    self.on_ground = false
    self.jump_max_speed = 150

    self.dz = -8
    self.z_gravity = -8
    self.max_falling = -200
    self.space_is_down = 0

    -- Coyote jump and jump buffering
    self.coyote_time = 0.1
    self.coyote_time_counter = 0
    self.jump_buffer_time = 0.1
    self.jump_buffer_time_counter = 0

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
    self:setHeight()

    -- Shadow
    self.shadow = newShadow(self)

    return self
end

function Player:update(dt)

    local force = 60
    local speed = 400*dt

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

    -- Flying mode
    -- if love.keyboard.isDown("space") then
    --     self.z = self.z + 50*dt
    --     self:setHeight()
    -- elseif love.keyboard.isDown("lshift") then
    --     self.z = self.z - 50*dt
    --     self:setHeight()
    -- end

    -- Mouse Input
    if self.cursor:click() then
        table.insert(SPAWNQUEUE, {group = "Projectile", args = {self.x, self.y, 10, 750, getAngle(self.x,self.y, self.cursor.x, self.cursor.y)}})
    end

    self.body:applyForce(math.cos(self.angle) * force, math.sin(self.angle) * force)

    self.x, self.y = self.body:getX(), self.body:getY()

    --Shadow
    self.shadow:update()
    self:updateShadow()
    
    --print(unpack(self.shadow.floor_buffer))
    --print(self.on_ground, self.dz)

    -- Jump (coyote time + jump buffer)
    if self.on_ground then
        self.coyote_time_counter = self.coyote_time
    else
        self.coyote_time_counter = self.coyote_time_counter - dt
    end

    if love.keyboard.isDown("space") then
        self.jump_buffer_time_counter = self.jump_buffer_time
    else
        self.jump_buffer_time_counter = self.jump_buffer_time_counter - dt
    end

    if self.coyote_time_counter > 0 and self.jump_buffer_time_counter > 0 then
        self.on_ground = false
        self.dz = self.jump_max_speed
        self.jump_buffer_time_counter = 0
    end
    if not(self.on_ground) and not(love.keyboard.isDown("space")) and self.dz > 0 then
        --short jump
        self.dz = self.dz * 0.75
        self.coyote_time_counter = 0
    end

    if love.keyboard.isDown("space") then
        self.space_is_down = 1
    else
        self.space_is_down = 0
    end

    -- Apply gravity
    if not(self.on_ground) and self.dz > self.max_falling then
        self.dz = self.dz + self.z_gravity - 10*(1 - self.space_is_down)
    end

    -- Check top and bottom floor, and then apply z velocity
    local new_z = self.z + self.dz*dt
    if self.dz > 0 and new_z + self.depth/2 < self.top_floor then
        self.z = new_z
    elseif self.dz < 0 then
        if new_z - self.depth/2 > self.bottom_floor then
            self.z = new_z
        else
            self.on_ground = true
            self.z = self.bottom_floor + self.depth/2 + 0.01
            self.dz = 0
        end
    end

    self:setHeight()
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
end

function Player:debugDraw()
    self.shadow:debugDraw()
    love.graphics.setColor(0.1, 0.05, 0.1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius, 6)
    love.graphics.setColor(0.8, 0.1, 0.4)
    love.graphics.print("bot_floor: "..tostring(self.bottom_floor), 10, 40)
    love.graphics.print("top_floor: "..tostring(self.top_floor), 10, 60)
end

function Player:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(shader, camera, shadow_map)
    end
    --self.model:draw(shader, camera, shadow_map)
end

function Player:setPosition(x, y)
    self.body:setPosition(x, y)
end

function Player:setHeight()
    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2
    self.mask = {11,12,13,14}

    for i, coll_cat in ipairs(self.mask) do
        local overlap = math.min(self.top, (i)*SCALE3D.z) - math.max(self.bottom, (i-1)*SCALE3D.z)
        if overlap >= 0 then
            -- the player overlaps the floor range, either from the bottom (or top)
            table.remove(self.mask, i)
            if overlap == self.depth then
                -- the overlap is the whole player's depth
                break
            else
                -- remove the next floor on top (which now is at index i, not i+1)
                table.remove(self.mask, i)
                break
            end
        end
    end

    self.fixture:setMask(unpack(self.mask))
    self.fixture:setUserData(self)
end

function Player:gotHit(entity)
    --print("Player got hit")
end
function Player:exitHit(entity)
    --print("Player exited a collision")
end
function Player:updateShadow()
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

return newPlayer