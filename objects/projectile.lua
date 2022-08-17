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
        self.uvs = {0, 0}
        self.radius = 4
        self.speed = 100
        self.y = self.y -4
        self.z = self.z
    end 

    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2

    self.active = true

    --local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    --self.model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, scale)

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
    self.body:setBullet(true) --slow processing
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.body:setMass(0)

    -- Fixture Category and Mask

    -- More type options adjustments
    if self.type == "simple player" then
        self.fixture:setCategory(6)
    end

    self:setHeight()

    --self:setVelocity(self.speed, self.angle)
    print(entity_dx, entity_dy)
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
    
    --Shadow
    self.shadow:updatePosition(self.x, self.y, self.z)
    --self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)

end

function Projectile:debugDraw()
    love.graphics.setColor(0.9, 0.8, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius, 6)
end

function Projectile:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(shader, camera, shadow_map)
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

    if self.type == "simple player" then
        table.insert(mask, 2)
        table.insert(mask, 6)
    end
    -- category 1 are shadows
    self.fixture:setMask(1, unpack(mask))
    self.fixture:setUserData(self)
end

function Projectile:gotHit(entity, xn, yn)
    --print("Projectile got hit: ", entity.fixture:getCategory())
    self.active = false
end
function Projectile:exitHit(entity, xn, yn)
    --print("Projectile exited a collision")
end

return newProjectile