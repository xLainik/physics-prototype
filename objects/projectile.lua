local Projectile = {}
Projectile.__index = Projectile

local function newProjectile(x, y, z, entity_dx, entity_dy, ini_angle, projectile_type)
    local self = setmetatable({}, Projectile)

    self.type = projectile_type or "simple player"
    self.index = nil

    --Position of the 3D cylinder center
    self.x = x
    self.y = y
    self.z = z
    
    self.angle = ini_angle

    self.depth = 10

    -- Set projectile type
    if self.type == "simple player" then
        self.uvs = {0/4, 0}
        self.radius = 4
        self.speed = 120
        self.y = self.y
        self.z = self.z
        self.z_offset = 3 + self.depth/2
        self.inactive_timer = 0
    end

    self.timer = 0
    --self.max_timer = 16 - self.speed*(1/20) --120 speed = 10 seconds (MAX = 320)
    self.max_timer = 16 - 0.0002*self.speed*self.speed --120 speed = 13 (MAX = 280)
    
    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2

    self.active = true

    --local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    --self.model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, scale)

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
    self.body:setFixedRotation(true)
    self.body:setBullet(true) --slow processing
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.body:setMass(0)

    self.body:setActive(false)

    -- Fixture Category and Mask

    -- Flat hitbox
    --self.flat_x, self.flat_y = self.body:getX(), (self.body:getY()) - self.z_offset

    --self.shape_flat = love.physics.newRectangleShape(self.width_flat, self.height_flat*(0.8125))

    -- More type options adjustments
    if self.type == "simple player" then
        --self.shape_flat = love.physics.newCircleShape(self.radius)
        self.width_flat, self.height_flat = 6, 6/0.8125
        local x, y = self.width_flat/2, self.height_flat/2 
        self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_offset, x, -y -self.z_offset, -x, y -self.z_offset, x, y -self.z_offset)

        self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat, 0.5)
        self.fixture:setCategory(1)
        self.fixture_flat:setCategory(6)
        self.hit_set = {nil, nil, true, true}
    end

    self.fixture_flat:setSensor(true)

    self:setHeight()

    --self:setVelocity(self.speed, self.angle)
    --print(entity_dx, entity_dy)
    self.body:setLinearVelocity(math.cos(self.angle) * self.speed, math.sin(self.angle) * self.speed)

    -- Shadow
    self.shadow = newShadow(self)

    return self
end

function Projectile:setVelocity(speed, angle)
    self.speed = speed
    self.angle = angle
    self.body:setLinearVelocity(math.cos(self.angle)*self.speed, math.sin(self.angle)*self.speed)
end

function Projectile:update(dt)
    self.x, self.y = self.body:getX(), self.body:getY()

    self.timer = self.timer + dt

    if self.timer > self.inactive_timer then
        self.body:setActive(true)
    end

    if self.timer > self.max_timer then
        self.active = false
    end

    --Shadow
    self.shadow:updatePosition(self.x, self.y, self.z)
    --self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)

end

function Projectile:debugDraw()
    --print("hello")
    --love.graphics.setColor(0.9, 0.8, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.flat_x, self.flat_y, self.radius, 6)
    --love.graphics.rectangle("line", self.flat_x, self.flat_y, self.width_flat, self.height_flat)
end

function Projectile:draw(shader, camera, shadow_map)
    if shadow_map == true then
        self.shadow:draw(shader, camera, shadow_map)
    else
        --self.model:draw(shader, camera, shadow_map)
    end
end

function Projectile:destroyMe(external_index)
    table.insert(DELETEQUEUE, {group = "Projectile", index = external_index})
    local swap_index = projectile_imesh:removeInstance(self.index)
    local swap_obj = projectiles[swap_index]
    projectiles[external_index] = swap_obj
    projectiles[external_index].index = external_index
    projectiles[external_index].shadow.index = self.shadow.index

    self.body:destroy()
end

function Projectile:setHeight()
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
    self.fixture:setMask(1,3,4,5,6,7,8,9, unpack(mask))
    self.fixture:setUserData(self)

    self.fixture_flat:setMask(1,2,3,4,5,7,8,9, unpack(mask))
    self.fixture_flat:setUserData(self)
end

function Projectile:gotHit(entity, xn, yn)
    --print("Projectile got hit: ", entity.fixture:getCategory())
    self.active = false
end
function Projectile:exitHit(entity, xn, yn)
    --print("Projectile exited a collision")
end

function Projectile:hitboxGotHit(entity)
    local category = entity.fixture:getCategory()
    --print("Projectile Hitbox got hit: ", category)
    if self.hit_set[category] ~= nil then
        self.active = false
    end
end
function Projectile:hitboxExitHit(entity)
    --print("Projectile Hitbox exited a collision")
end

return newProjectile