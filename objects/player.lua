local Player = {}
Player.__index = Player

local function newPlayer(cursor)
    local self = setmetatable({}, Player)

    self.cursor = cursor

    self.radius = 4.5

    self.depth = 24
    self.top = self.depth/2
    self.bottom = -self.depth/2

    self.z_flat_offset = self.depth/2

    self.angle = 0
    self.speed = 0

    local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    self.model = g3d.newModel(GAME.models_directory.."/unit_cylinder.obj", GAME.models_directory.."/no_texture.png", {0,0,0}, {0,0,0}, scale)

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
        id = "player",
        position = {0,0,0},
        stamina = 10,
        hp = 100,
        max_hp = 100,
        control = true,
        vulnerable = true
        }

    self.invulnerable_timer = 0
    self.die_timer = 0

    self.tree = tree.newTree(self)

    self.control_action = self.tree.createAction("control", self.control_inizializeFunction, self.control_updateFunction, self.control_cleanUpFunction, self)
    self.not_control_action = self.tree.createAction("not_control", self.not_control_inizializeFunction, self.not_control_updateFunction, self.not_control_cleanUpFunction, self)
    self.die_action = self.tree.createAction("die", self.die_inizializeFunction, self.die_updateFunction, self.die_cleanUpFunction, self)
 
    self.isAlive_evaluator = self.tree.createEvaluator("isAlive", self.isAlive_evalFunction, self)
    self.isControl_evaluator = self.tree.createEvaluator("isControl", self.isControl_evalFunction, self)

    self.isAlive_branch = self.tree.createBranch("isAlive")
    self.isControl_branch = self.tree.createBranch("isControl")

    self.isAlive_branch:setEvaluator(self.isAlive_evaluator)
    self.isAlive_branch:addChild(self.die_action, 1)
    self.isAlive_branch:addChild(self.isControl_branch, 2)

    self.isControl_branch:setEvaluator(self.isControl_evaluator)
    self.isControl_branch:addChild(self.not_control_action, 1)
    self.isControl_branch:addChild(self.control_action, 2)

    self.tree:setBranch(self.isAlive_branch)

    --Physics
    self.body = love.physics.newBody(current_map.WORLD, self.userData.position[1], self.userData.position[2], "dynamic")
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
    self.width_flat, self.height_flat = 6, 10/0.8125
    --self.flat_x, self.flat_y = self.body:getX(), (self.body:getY())*0.8125 - self.z_flat_offset
    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.z_flat_offset - self.depth/2)*(0.8125)

    --self.shape_flat = love.physics.newCircleShape(self.radius)
    --self.shape_flat:setPoint(0, -self.z_flat_offset)
    local x, y = self.width_flat/2, self.height_flat/2 
    self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_flat_offset, x, -y -self.z_flat_offset, -x, y -self.z_flat_offset, x, y -self.z_flat_offset)
    self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat)

    self.fixture_flat:setSensor(true)

    self.fixture_flat:setCategory(6)

    -- Shadow
    self.shadow = newShadow(self)

    -- Animations
    local sheet = love.graphics.newImage(GAME.sprites_directory.."/sprites/player/player.png")
    self.sprite_1 = newSprite(0,0,0, sheet, 40, 40)
    self.sprite_2 = newSprite(0,0,0, sheet, 40, 40)
    self.z_sprite_offset = (20/16)*math.cos(0.927295218)

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

    self:setAnimation("idle", 3, 1, 1)
    self.last_angles_index = 3


    self.stats = {}
    self.stats["accuracy"] = 40 --  100 ->  0
    self.stats["atk speed"] = 0.2 -- 0.6 -> 0.05
    self.cursor.click_interval = self.stats["atk speed"]

    return self
end

-- Player Evaluation Functions -------------------------------------------------------------------------------------

function Player:isAlive_evalFunction()
    --print("Evaluating isAlive", self.userData.hp)
    return self.userData.hp ~= nil and self.userData.hp > 0
end

function Player:isControl_evalFunction()
    --print("Evaluating isControl", self.userData.stun)
    return self.userData.control ~= nil and self.userData.control == true
end

-- Player Actions -------------------------------------------------------------------------------------------------------

function Player:die_inizializeFunction()
    --print("Inizialize Die Action")
    self.body:setLinearVelocity(0, 0)
end

function Player:die_updateFunction(dt)
    self.die_timer = self.die_timer + dt
    --print(self.die_timer)        
    if self.die_timer > 20 then
        return "TERMINATED"
    end    
    return "RUNNING"
end

function Player:die_cleanUpFunction()
    --print("CleanUp Die Action")
end

function Player:control_inizializeFunction()
    --print("Inizialize Control Action")
end

function Player:control_updateFunction(dt)

    self.speed = 64

    -- Input handling
    -- Keyboard Input
    if GAME.actions["left"] and GAME.actions["up"] then
        self.angle = math.pi*1.25
    elseif GAME.actions["right"] and GAME.actions["up"]then
        self.angle = math.pi*1.75
    elseif love.keyboard.isDown("a") and GAME.actions["down"] then
        self.angle = math.pi*0.75
    elseif GAME.actions["right"] and GAME.actions["down"] then
        self.angle = math.pi*0.25
    elseif GAME.actions["right"] then
        self.angle = 0
    elseif GAME.actions["left"] then
        self.angle = math.pi
    elseif GAME.actions["up"] then
        self.angle = math.pi*1.50
    elseif GAME.actions["down"] then
        self.angle = math.pi*0.50
    else
        self.speed = 0
        --when the key is released, the body stops instanly
        self.body:setLinearVelocity(0 , 0)
    end

    -- -- Flying mode
    -- if GAME.actions["action_1"] then
    --     self.userData.position[3] = self.userData.position[3] + 200*dt
    --     self:setHeight()
    -- elseif GAME.actions["shift"] then
    --     self.userData.position[3] = self.userData.position[3] - 50*dt
    --     self:setHeight()
    -- end

    -- Jump Input
    if GAME.actions["action_1"] then
        self.space_is_down = 1
    else
        self.space_is_down = 0
    end

    -- Mouse Input
    if self.cursor:click() then
        if self.on_ground == true then
            -- Shoot simple projectile ONLY when on the ground
            local angle = -1*(getAngle(self.userData.position[1]/SCALE3D.x, (self.userData.position[2]-self.z_flat_offset)/SCALE3D.y, self.cursor.x, self.cursor.y - self.cursor.z_offset/16) + math.random(-self.stats["accuracy"], self.stats["accuracy"])/1000)        
            --print("ANGLE: ", tostring(getAngle(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.cursor.model.translation[1], self.cursor.model.translation[2])*180/math.pi))
            local spawn_point = {self.userData.position[1] + math.cos(angle)*(16), (self.userData.position[2] - self.z_flat_offset) + math.sin(angle)*(20)}
            table.insert(current_map.SPAWNQUEUE, {group = "Projectile_Simple", args = {spawn_point[1], spawn_point[2], self.userData.position[3], dx, dy, angle, {player_damage = 2}} })
            table.insert(current_map.SPAWNQUEUE, {group = "Particle_Circle", args = {spawn_point[1], spawn_point[2], self.userData.position[3], 0, 0, 0, {style = "line", color = {255/255,121/255,23/255,1}}}})
        end
    end

    if self.userData.control == true then
        return "RUNNING"
    end    
    return "TERMINATED"
end

function Player:control_cleanUpFunction()
    --print("CleanUp Control Action")
end

function Player:not_control_inizializeFunction()
    --print("Inizialize Not Control Action")
end

function Player:not_control_updateFunction(dt)
    return "RUNNING"
end

function Player:not_control_cleanUpFunction()
    --print("CleanUp Not Control Action")
end

function Player:loadData(user_data)
    for name, element in pairs(user_data) do
        self.userData[name] = element
    end
    self:setHeight()
    self.body:setPosition(self.userData.position[1], self.userData.position[2])
end

function Player:update(dt)

    self.tree:update(dt)

    if self.userData.vulnerable == false then
        self.invulnerable_timer = self.invulnerable_timer + dt
        self.sprite_1:setColor(252/255, 55/255, 134/255, 0.25*(math.cos(self.invulnerable_timer*12)+1) )
        self.sprite_2:setColor(252/255, 55/255, 134/255, 0.25*(math.cos(self.invulnerable_timer*12)+1))
        if self.invulnerable_timer > 1.8 then
            self.invulnerable_timer = 0
            self.userData.vulnerable = true
            self.sprite_1:setColor(1, 1, 1, 0)
        self.sprite_2:setColor(1, 1, 1, 0)
        end
    end

    self:getAnimationAngle()
    if self.speed > 0 then
        self:setAnimation("run", self.anim_angle, self.anim_flip_x, 1)
    else
        self:setAnimation("idle", self.last_angles_index, nil)
    end

    self.body:setLinearVelocity(math.cos(self.angle) * self.speed, math.sin(self.angle) * self.speed)

    --self.userData.position[1], self.userData.position[2] = self.body:getX(), self.body:getY()

    self.userData.position[1], self.userData.position[2] = math.floor(self.body:getX()), math.floor(self.body:getY())

    --self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_flat_offset
    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.z_flat_offset - self.height_flat/2)*(0.8125)

    --Shadow
    self.shadow:updatePosition(self.userData.position[1], self.userData.position[2], self.userData.position[3])
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

    -- Apply gravity
    if not(self.on_ground) and self.dz > self.max_falling then
        self.dz = self.dz + self.z_gravity - self.space_up_factor*(1 - self.space_is_down)
    end

    -- Check top and bottom floor, and then apply z velocity
    local new_z = self.userData.position[3] + self.dz*dt
    if self.dz > 0 and new_z + self.depth/2 < self.top_floor then
        self.userData.position[3] = new_z
    elseif self.dz < 0 then
        if new_z - self.depth/2 > self.bottom_floor then
            self.userData.position[3] = new_z
        else
            self.on_ground = true
            self.userData.position[3] = self.bottom_floor + self.depth/2 + 0.01
        end
    end

    -- Animation Handleling
    self.sprite_1:update(dt)
    self.sprite_2:update(dt)

    self:setHeight()
    self.model:setTranslation(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z)
    self.sprite_1:setTranslation(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y - 0.2, self.userData.position[3]/SCALE3D.z + self.z_sprite_offset)
    self.sprite_2:setTranslation(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y - 0.15, self.userData.position[3]/SCALE3D.z + self.z_sprite_offset)

end

function Player:resetTree()
    --print("reset tree")
    self.tree.currentAction = nil
    self.userData.control = true
    self.userData.vulnerable = true
    self.die_timer = 0
end

function Player:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(shader, camera, shadow_map)
        self.sprite_1:draw(shader, camera, shadow_map)
        self.sprite_2:draw(shader, camera, shadow_map)
    else
        self.sprite_1:draw(shader, camera, shadow_map)
        self.sprite_2:draw(shader, camera, shadow_map)
        --self.model:draw(shader, camera, shadow_map)
    end
    
end

function Player:debugDraw()
    local x, y = main_camera:pointOnScreen(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z)
    local x2, y2 = x - self.width_flat/2*WINDOWSCALE, y - self.height_flat*WINDOWSCALE
    love.graphics.setColor(0.9, 0.8, 0.9, 1)
    love.graphics.setLineWidth(1*WINDOWSCALE)
    --print(current_camera.target[1], current_camera.target[2])
    --love.graphics.circle("line", self.flat_x, self.flat_y, self.radius)
    love.graphics.rectangle("line", x2, y2, self.width_flat*WINDOWSCALE, self.height_flat*WINDOWSCALE)
end

function Player:screenDrawUI()
    local size = 1.5*self.userData.max_hp
    love.graphics.setLineWidth(4*WINDOWSCALE)
    love.graphics.setColor(244/255, 248/255, 255/255)
    love.graphics.rectangle("line", 8*WINDOWSCALE, (SCREENHEIGHT-60)*WINDOWSCALE, (size)*WINDOWSCALE, 12*WINDOWSCALE)
    love.graphics.setColor(47/255, 18/255, 25/255)
    love.graphics.rectangle("fill", 8*WINDOWSCALE, (SCREENHEIGHT-60)*WINDOWSCALE, (size)*WINDOWSCALE, 12*WINDOWSCALE)
    love.graphics.setColor(252/255, 55/255, 134/255)
    local scale = self.userData.hp/self.userData.max_hp
    love.graphics.rectangle("fill", 8*WINDOWSCALE, (SCREENHEIGHT-60)*WINDOWSCALE, (size*scale)*WINDOWSCALE, 12*WINDOWSCALE)
    love.graphics.setColor(244/255, 248/255, 255/255)
    love.graphics.print("HP: "..tostring(self.userData.hp).."/100", (8+54)*WINDOWSCALE, (SCREENHEIGHT-58)*WINDOWSCALE)
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
    self.top = self.userData.position[3] + self.depth/2
    self.bottom = self.userData.position[3] - self.depth/2
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
    self.fixture:setMask(1,2,3,4,5,6,7,8,9, unpack(mask))
    self.fixture:setUserData(self)

    -- self.z_flat_offset = self.userData.position[3] - self.depth
    -- local x, y = self.width_flat/2, self.height_flat/2 
    -- self.fixture_flat:destroy()
    -- self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_flat_offset, x, -y -self.z_flat_offset, -x, y -self.z_flat_offset, x, y -self.z_flat_offset)
    -- self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat)

    -- self.fixture_flat:setSensor(true)
    -- self.fixture_flat:setCategory(6)

    self.fixture_flat:setMask(1,2,3,4,5,8,9, unpack(mask))
    self.fixture_flat:setUserData(self)
end

function Player:gotHit(entity)
    --print("Player got hit: ", entity.fixture:getCategory())
end
function Player:exitHit(entity)
    --print("Player exited a collision")
end

function Player:hitboxIsHit(entity)
    --print("Player Hitbox is hit: ", entity.fixture:getCategory())
    if self.userData.vulnerable == true then
        if entity.userData ~= nil then
            if entity.userData.enemy_damage ~= nil and entity.userData.enemy_damage > 0 then
                self.userData.hp = self.userData.hp - entity.userData.enemy_damage
                self.userData.vulnerable = false
                if self.userData.hp <= 0 then
                    self:resetTree()
                end
            end
        end
    end
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