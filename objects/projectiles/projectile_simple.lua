local Projectile = {}
Projectile.__index = Projectile

local function newProjectile(x, y, z, entity_dx, entity_dy, ini_angle, options)
    local self = setmetatable({}, Projectile)

    self.type = "simple"
    self.index = nil

    self.target = target

    --Position of the 3D cylinder center
    

    self.angle = ini_angle

    self.depth = 10

    self.userData = {
        id = "projectile",
        position = {x, y, z},
        player_damage = options["player_damage"] or 0,
        enemy_damage = options["enemy_damage"] or 0,
        hp = -1
        }

    self.top = self.userData.position[3] + self.depth/2
    self.bottom = self.userData.position[3] - self.depth/2

    -- Set projectile type
    self.radius = 4
    self.speed = 100
    self.z_offset = 3 + self.depth/2

    self.timer = 0
    self.max_timer = 16 - 0.0002*self.speed*self.speed --120 speed = 13 (MAX = 280)


    self.active = true

    --local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    --self.model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, scale)

    --Physics
    self.body = love.physics.newBody(current_map.WORLD,  self.userData.position[1], self.userData.position[2], "dynamic")
    self.body:setFixedRotation(true)
    self.body:setBullet(true) --slow processing
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.body:setMass(0)

    -- Fixture Category and Mask

    -- Flat hitbox
    --self.flat_x, self.flat_y = self.body:getX(), (self.body:getY()) - self.z_offset

    --self.shape_flat = love.physics.newRectangleShape(self.width_flat, self.height_flat*(0.8125))

    -- More type options adjustments
    --self.shape_flat = love.physics.newCircleShape(self.radius)
    self.width_flat, self.height_flat = 6, 6/0.8125
    local x, y = self.width_flat/2, self.height_flat/2 
    self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_offset, x, -y -self.z_offset, -x, y -self.z_offset, x, y -self.z_offset)

    self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat, 0.5)
    self.fixture:setCategory(4)
    self.fixture_flat:setCategory(6)
    self.hit_set = {nil, nil, true, true}


    self.fixture_flat:setSensor(true)

    self:setHeight2()

    self.fixture:setMask(1,2,3,4,5,6,7,8,9)
    self.fixture:setUserData(self)

    self.fixture_flat:setMask(1,2,3,4,5,7,8,9)
    self.fixture_flat:setUserData(self)

    --self:setVelocity(self.speed, self.angle)
    --print(entity_dx, entity_dy)
    self.body:setLinearVelocity(math.cos(self.angle) * self.speed, math.sin(self.angle) * self.speed)

    -- Instance mesh
    self.uvs = {0/16, 0/16, 1}
    self.matrix = g3d.newMatrix()
    self.position = {x,y,z}
    self.rotation = {0,0,0}
    self.scale = {16/16, 0, (16/16)/math.cos(0.927295218)}
    self.matrix:setTransformationMatrix(self.position, self.rotation, self.scale)

    local instance_index = current_section.projectile_imesh:addInstance(self.matrix, self.uvs[1], self.uvs[2], self.uvs[3])
    self.index = instance_index
    current_section.projectiles[instance_index] = self

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
    self.userData.position[1], self.userData.position[2] = self.body:getX(), self.body:getY()

    self.timer = self.timer + dt

    if self.timer > self.max_timer then
        self.active = false
    end

    self:setHeight2()

    -- Instanced Mesh update
    self.position = {self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z}
    self.matrix:setTransformationMatrix(self.position, self.rotation, self.scale)

    current_section.projectile_imesh:updateInstanceMAT(self.index, self.matrix:getMatrixRows())

    --Shadow
    self.shadow:updatePosition(self.userData.position[1], self.userData.position[2], self.userData.position[3])
    --self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)

    if self.active == false then
        self:destroyMe()
    end

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
        --self.shadow:draw(shader, camera, shadow_map)
    else
        --self.model:draw(shader, camera, shadow_map)
    end
end

function Projectile:destroyMe()
    local last_index = current_section.projectile_imesh:removeInstance(self.index)
    local last_obj = current_section.projectiles[last_index]
    current_section.projectiles[self.index] = last_obj
    last_obj.index = self.index

    table.insert(current_map.DELETEQUEUE, {group = "Projectile", index = last_index})

    self.body:destroy()
end

function Projectile:setHeight2()
    self.top = self.userData.position[3] + self.depth/2
    self.bottom = self.userData.position[3] - self.depth/2
end

function Projectile:setHeight()
    local mask = {11,12,13,14,15,16}

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
    local overlap = math.min(self.top, entity.top) - math.max(self.bottom, entity.bottom)
    if overlap >= 0 then
        self.active = false
    end
end
function Projectile:exitHit(entity, xn, yn)
    --print("Projectile exited a collision")
end

function Projectile:hitboxIsHit(entity)
    local category = entity.fixture:getCategory()
    --print("Projectile Hitbox is hit: ", category)
    if self.hit_set[category] ~= nil then
        if entity.userData ~= nil and entity.userData.hp > 0 then
            self.active = false
        end
    end
end
function Projectile:hitboxGotHit(entity)
    --print("Projectile Hitbox got hit: ", category)
end
function Projectile:hitboxExitHit(entity)
    --print("Projectile Hitbox exited a collision")
end

return newProjectile