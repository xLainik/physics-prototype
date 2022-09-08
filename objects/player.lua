local Player = {}
Player.__index = Player

local function newPlayer(x, y, z, cursor)
    local self = setmetatable({}, Player)

    self.cursor = cursor

    -- Position of the xyz center in 3D
    self.x = x or 50
    self.y = y or 50
    self.z = z or 40

    self.radius = 4.5

    self.depth = 24
    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2

    self.z_offset = self.depth/2 - 2

    self.angle = 0

    local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    self.model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, scale)

    -- Variables for jumping
    self.top_floor = 1000
    self.bottom_floor = -1000
    self.on_ground = false
    self.jump_max_speed = 280

    self.dz = -8
    self.z_gravity = -8
    self.max_falling = -120
    self.space_is_down = 0
    self.space_up_factor = 20

    -- Coyote jump and jump buffering
    self.coyote_time = 0.1
    self.coyote_time_counter = 0
    self.jump_buffer_time = 0.1
    self.jump_buffer_time_counter = 0

    -- UserData
    self.userData = {
        position = {self.x, self.y},
        spawn_position = {x, y},
        stamina = 10,
        hp = 100
        }

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
    self.body:setFixedRotation(true)
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5)
    self.body:setMass(2)

    self.body:setLinearDamping(5)
    --self.body:setInertia(0)
    self.fixture:setFriction(1.0)

    -- Fixture Category and Mask
    self.fixture:setCategory(2)

    -- Flat hitbox
    self.width_flat, self.height_flat = 6, 16/0.8125
    --self.flat_x, self.flat_y = self.body:getX(), (self.body:getY())*0.8125 - self.z_offset
    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.z_offset - self.depth/2)*(0.8125)

    --self.shape_flat = love.physics.newCircleShape(self.radius)
    --self.shape_flat:setPoint(0, -self.z_offset)
    local x, y = self.width_flat/2, self.height_flat/2 
    self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_offset, x, -y -self.z_offset, -x, y -self.z_offset, x, y -self.z_offset)
    self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat)

    self.fixture_flat:setSensor(true)

    self.fixture_flat:setCategory(6)

    -- Shadow
    self.shadow = newShadow(self)
    self:setHeight()

    -- Animations
    local sheet = love.graphics.newImage("assets/2d/sprites/player/player.png")
    self.sprite_1 = newSprite(0,0,0, sheet, 40, 40)
    self.sprite_2 = newSprite(0,0,0, sheet, 40, 40)

    self.anim_angle = 3
    self.anim_flip_x = 1

    local animations_init = {}
    -- ["name"] = {"torso" = {first_1, last_1, row, time, angles}, "legs" = {first_1, last_1, row, time, angles}}
    animations_init["idle"] = {torso = {1, 2, 1, 0.8, 5}, legs = {9, 9, 1, 0.8, 5}}
    animations_init["run"] = {torso = {1, 4, 6, 0.2, 5}, legs = {9, 12, 6, 0.2, 5}}

    self.animations = {}
    for anim_name, anim in pairs(animations_init) do
        -- ["name"] = {torso = {{angle = index}, ... }, legs = {{angle = index}, ... ]}
        self.animations[anim_name] = {}
        for body_part, frame_info in pairs(anim) do
            if body_part == "torso" then
                self.animations[anim_name]["torso"] = {}
                for angle = 1, frame_info[5], 1 do
                    local index = self.sprite_1:newAnimation(frame_info[1], frame_info[2], frame_info[3] + (angle - 1), frame_info[4])
                    self.animations[anim_name]["torso"][angle] = index
                end
            elseif body_part == "legs" then
                self.animations[anim_name]["legs"] = {}
                for angle = 1, frame_info[5], 1 do
                    local index = self.sprite_2:newAnimation(frame_info[1], frame_info[2], frame_info[3] + (angle - 1), frame_info[4])
                    self.animations[anim_name]["legs"][angle] = index
                end
            end
        end
    end

    -- for name, anim in pairs(self.animations) do
    --     print(name)
    --     for part, angle_index_pairs in pairs(anim) do
    --         print(part)
    --         for angle, index in pairs(angle_index_pairs) do
    --             print(angle, index)
    --         end
    --     end
    -- end

    self:setAnimation("idle", 3, 1, 1)
    self.last_angles_index = 3


    self.stats = {}
    self.stats["accuracy"] = 40 --  100 ->  0
    self.stats["atk speed"] = 0.2 -- 0.6 -> 0.05
    self.cursor.click_interval = self.stats["atk speed"]

    return self
end

function Player:update(dt)

    local speed = 16*4

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
        speed = 0
        --when the key is released, the body stops instanly
        self.body:setLinearVelocity(0 , 0)
        self:setAnimation("idle", self.last_angles_index, nil)
    end

    self:getAnimationAngle()
    if speed > 0 then
        self:setAnimation("run", self.anim_angle, self.anim_flip_x, 1)
    end

    -- Flying mode
    -- if love.keyboard.isDown("space") then
    --     self.z = self.z + 50*dt
    --     self:setHeight()
    -- elseif love.keyboard.isDown("lshift") then
    --     self.z = self.z - 50*dt
    --     self:setHeight()
    -- end

    self:updateUserData()

    self.body:setLinearVelocity(math.cos(self.angle) * speed, math.sin(self.angle) * speed)

    --self.x, self.y = self.body:getX(), self.body:getY()

    self.x, self.y = math.floor(self.body:getX()), math.floor(self.body:getY())

    --self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_offset
    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.z_offset - self.height_flat/2)*(0.8125)

    --Shadow
    self.shadow:updatePosition(self.x, self.y, self.z)
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
        self.dz = self.dz * 0.5
        self.coyote_time_counter = 0
    end

    if love.keyboard.isDown("space") then
        self.space_is_down = 1
    else
        self.space_is_down = 0
    end

    -- Apply gravity
    if not(self.on_ground) and self.dz > self.max_falling then
        self.dz = self.dz + self.z_gravity - self.space_up_factor*(1 - self.space_is_down)
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
        end
    end

    -- Mouse Input
    if self.cursor:click() then
        --print("PLAYER POS: ", self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
        --print("SPRITE POS: ", self.sprite.imesh.translation[1], self.sprite.imesh.translation[2], self.sprite.imesh.translation[3])
        --print("CURSOR POS: ", self.cursor.x, self.cursor.y, self.cursor.z)
        -- dx, dy = 0, 0
        -- if speed ~= 0 then
        --     dx, dy = self.body:getLinearVelocity()
        --     dx, dy = dx, dy
        -- end
        local angle = -1*(getAngle(self.x/SCALE3D.x, (self.y-self.z_offset)/SCALE3D.y, self.cursor.x, self.cursor.y - self.cursor.z_offset/16) + math.random(-self.stats["accuracy"], self.stats["accuracy"])/1000)        
        --print("ANGLE: ", tostring(getAngle(self.x/SCALE3D.x, self.y/SCALE3D.y, self.cursor.model.translation[1], self.cursor.model.translation[2])*180/math.pi))
        local spawn_point = {self.x + math.cos(angle)*(16 + 16*math.abs(math.sin(angle))), (self.y - self.z_offset) + math.sin(angle)*(16 + 16*math.abs(math.sin(angle)))}
        table.insert(SPAWNQUEUE, {group = "Projectile", args = {spawn_point[1], spawn_point[2], self.z, dx, dy, angle, "simple player"}})
    end

    -- Animation Handleling
    self.sprite_1:update(dt)
    self.sprite_2:update(dt)


    self:setHeight()
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
    self.sprite_1:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y - 0.2, self.z/SCALE3D.z - 0.6)
    self.sprite_2:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y - 0.15, self.z/SCALE3D.z - 0.6)
end

function Player:updateUserData()
    self.userData.position = {self.x, self.y}
end

function Player:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(myShader, camera, shadow_map)
        self.sprite_1:draw(shader, camera, shadow_map)
        self.sprite_2:draw(shader, camera, shadow_map)
    else
        self.sprite_1:draw(shader, camera, shadow_map)
        self.sprite_2:draw(shader, camera, shadow_map)
        --self.model:draw(myShader, camera, shadow_map)
    end
    
end

function Player:debugDraw()
    --love.graphics.setColor(0.9, 0.8, 0.9)
    love.graphics.setLineWidth(1)
    --print(current_camera.target[1], current_camera.target[2])
    love.graphics.circle("line", self.flat_x, self.flat_y, self.radius)
    --love.graphics.rectangle("line", self.flat_x, self.flat_y, self.width_flat, self.height_flat)
end

function Player:setPosition(x, y)
    self.body:setPosition(x, y)
end

function Player:setAnimation(name, angle, flip_x, flip_y)
    local anim = self.animations[name]
    self.sprite_1:changeAnimation(anim["torso"][angle], flip_x, flip_y)
    self.sprite_2:changeAnimation(anim["legs"][angle], flip_x, flip_y)
    self.last_angles_index = angle
end

function Player:flipAnimation(x, y)
    self.sprite_1:flipAnimation(x, y)
    self.sprite_2:flipAnimation(x, y)
end

function Player:getAnimationAngle()
    local index = math.floor(((self.angle)/(2*3.14)) * 8 + 3)
    local sign = 1
    if index > 8 then index = index - 8 end
    if index > 5 then
        index = 5 - (index - 5)
        sign = -1
    end
    self.anim_angle = index
    self.anim_flip_x = sign
end

function Player:setHeight()
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

function Player:gotHit(entity)
    --print("Player got hit: ", entity.fixture:getCategory())
end
function Player:exitHit(entity)
    --print("Player exited a collision")
end

function Player:hitboxGotHit(entity)
    --print("Player Hitbox got hit: ", entity.fixture:getCategory())
end
function Player:hitboxExitHit(entity)
    --print("Player Hitbox exited a collision")
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