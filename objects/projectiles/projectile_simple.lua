local Projectile = {}
Projectile.__index = Projectile

local function newProjectile(x, y, z, entity_dx, entity_dy, ini_angle, options)
    local self = setmetatable({}, Projectile)

    self.type = "simple"
    self.index = nil

    self.target = target

    self.angle = ini_angle

    self.depth = 4

    self.top_floor = 1000
    self.bottom_floor = -1000

    self.userData = {
        id = "projectile",
        position = {x, y, z},
        player_damage = options["player_damage"] or 0,
        enemy_damage = options["enemy_damage"] or 0,
        hp = -1
        }

    self.top = self.userData.position[3] + self.depth/2
    self.bottom = self.userData.position[3] - self.depth/2

    self.top_function = function(x, y)
        return self.top, true
    end

    self.bottom_function = function(x, y)
        return self.bottom
    end

    -- Set projectile type
    self.radius = 4
    self.speed = 100
    self.z_offset = 6 + self.depth/2

    self.timer = 0
    self.max_timer = 16 - 0.0002*self.speed*self.speed --120 speed = 13 (MAX = 280)


    self.active = true

    local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    self.model = g3d.newModel(GAME.models_directory.."/unit_cylinder.obj", GAME.models_directory.."/no_texture.png", {0,0,0}, {0,0,0}, scale)

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

    self:setHeight()

    self.fixture:setMask(1,2,3,4,5,6,7,8,9)
    self.fixture:setUserData(self)

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

    self:setHeight()

    if self.bottom <= self.bottom_floor then
        --self.userData.position[3] = self.bottom_floor + self.depth/2 + 0.01
        self.active = false
    end
    if self.top >= self.top_floor then
        --self.userData.position[3] = self.top_floor - self.depth/2 - 0.01
        self.active = false
    end

    local x_speed, y_speed = self.body:getLinearVelocity()

    if closeNumber(x_speed, 0, 0.1) or closeNumber(y_speed, 0, 0.1) then
        self.active = false
    end

    self:setHeight()

    -- Instanced Mesh update
    self.position = {self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z}
    self.matrix:setTransformationMatrix(self.position, self.rotation, self.scale)

    current_section.projectile_imesh:updateInstanceMAT(self.index, self.matrix:getMatrixRows())

    --Shadow
    self.shadow:updatePosition(self.userData.position[1], self.userData.position[2], self.userData.position[3])
    self:updateShadow()

    self.model:setTranslation(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z)

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
        self.shadow:draw(shader, camera, shadow_map)
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

function Projectile:setHeight()
    self.top = self.userData.position[3] + self.depth/2
    self.bottom = self.userData.position[3] - self.depth/2
end

function Projectile:gotHit(entity, xn, yn)
    --print("Projectile got hit: ", entity.fixture:getCategory())
    
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

function Projectile:updateShadow()
    local bottom_buffer = {}
    for i=#self.shadow.floor_buffer,1,-1 do
        -- read the buffer from top to bottom
        local coll_top, coll_center = self.shadow.floor_buffer[i][2](self.userData.position[1], self.userData.position[2])
        local coll_bottom = self.shadow.floor_buffer[i][3](self.userData.position[1], self.userData.position[2])
        if coll_center == true then
            if coll_bottom > self.top then
                table.insert(bottom_buffer, coll_bottom)
            else
                self.bottom_floor = coll_top
                --print(self.bottom_floor)
                self.top_floor = bottom_buffer[#bottom_buffer] or 1000
                break
            end
        end
    end
end

return newProjectile