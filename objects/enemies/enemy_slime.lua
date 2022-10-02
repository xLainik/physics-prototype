local Enemy = {}
Enemy.__index = Enemy

local function newEnemy(x, y, z)
    local self = setmetatable({}, Enemy)
    
    self.radius = 7.5

    self.angle = 0
    self.speed = 0

    self.steering = {0, 0}

    -- Variables for jumping
    self.top_floor = 1000
    self.bottom_floor = -1000
    self.on_ground = false

    self.dz = -8
    self.z_gravity = -8
    self.max_falling = -120

    self.depth = 24
    
    self.top = self.depth/2
    self.bottom = -self.depth/2

    self.z_flat_offset = 8

    local scale = {self.radius*2/SCALE3D.x, self.radius*2/SCALE3D.x, self.depth/SCALE3D.z}
    self.model = g3d.newModel(GAME.models_directory.."/unit_cylinder.obj", GAME.models_directory.."/no_texture.png", {0,0,0}, {0,0,0}, scale)

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
        id = "enemy",
        position = {x,y,z},
        spawn_position = {x,y,z},
        stamina = 0,
        hp = 10,
        max_hp = 10,
        stun = false,
        enemy_damage = 0
        }

    self:setHeight()

    self.idle_timer = 0
    self.wander_timer = 0
    self.chargeAttack_timer = 0
    self.die_timer = 0
    self.stun_timer = 0
    
    self.tree = tree.newTree(self)

    self.idle_action = self.tree.createAction("idle", self.idle_inizializeFunction, self.idle_updateFunction, nil, self)
    self.stun_action = self.tree.createAction("stun", self.stun_inizializeFunction, self.stun_updateFunction, self.stun_cleanUpFunction, self)
    self.wander_action = self.tree.createAction("wander", self.wander_inizializeFunction, self.wander_updateFunction, self.wander_cleanUpFunction, self)
    self.die_action = self.tree.createAction("die", self.die_inizializeFunction, self.die_updateFunction, self.die_cleanUpFunction, self)
    self.seek_action = self.tree.createAction("seek", self.seekVel_inizializeFunction, self.seekVel_updateFunction, self.seekVel_cleanUpFunction, self)
    self.chargeAttack_action = self.tree.createAction("chargeAttack", self.chargeAttack_inizializeFunction, self.chargeAttack_updateFunction, self.chargeAttack_cleanUpFunction, self)

    self.hasStamina_evaluator = self.tree.createEvaluator("hasStamina", self.hasStamina_evalFunction, self)
    self.isStun_evaluator = self.tree.createEvaluator("isStun", self.isStun_evalFunction, self)
    self.isAlive_evaluator = self.tree.createEvaluator("isAlive", self.isAlive_evalFunction, self)
    self.checkPlayer_evaluator = self.tree.createEvaluator("checkPlayer", self.checkPlayer_evalFunction, self)

    self.isAlive_branch = self.tree.createBranch("isAlive")
    self.isStun_branch = self.tree.createBranch("isStun")
    self.hasStamina_branch = self.tree.createBranch("hasStamina")
    self.checkPlayer_branch = self.tree.createBranch("checkPlayer")
    self.attackPlayer_branch = self.tree.createBranch("attackPlayer")

    self.isAlive_branch:setEvaluator(self.isAlive_evaluator)
    self.isAlive_branch:addChild(self.die_action, 1)
    self.isAlive_branch:addChild(self.hasStamina_branch, 2)

    self.isStun_branch:setEvaluator(self.isStun_evaluator)
    self.isStun_branch:addChild(self.hasStamina_branch, 1)
    self.isStun_branch:addChild(self.stun_action, 2)

    self.hasStamina_branch:setEvaluator(self.hasStamina_evaluator)
    self.hasStamina_branch:addChild(self.idle_action, 1)
    self.hasStamina_branch:addChild(self.checkPlayer_branch, 2)

    self.checkPlayer_branch:setEvaluator(self.checkPlayer_evaluator)
    self.checkPlayer_branch:addChild(self.wander_action, 1)
    self.checkPlayer_branch:addChild(self.seek_action, 2)
    self.checkPlayer_branch:addChild(self.chargeAttack_action, 3)

    self.tree:setBranch(self.isAlive_branch)

    --Physics
    self.body = love.physics.newBody(current_map.WORLD, self.userData.position[1], self.userData.position[2], "dynamic")
    self.body:setFixedRotation(true)
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0.5)

    -- Fixture Category and Mask
    self.fixture:setCategory(3)

    self.fixture:setMask(1,2,3,4,5,6,7,8,9)
    self.fixture:setUserData(self)

    -- Flat hitbox
    self.width_flat, self.height_flat = 16, 18
    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, self.body:getY()*(0.8125) - self.height_flat/2 - self.z_flat_offset
    self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_flat_offset

    --self.shape_flat = love.physics.newCircleShape(self.radius)
    --self.shape_flat:setPoint(0, -self.z_flat_offset)
    local x, y = self.width_flat/2, self.height_flat/2 
    self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_flat_offset, x, -y -self.z_flat_offset, -x, y -self.z_flat_offset, x, y -self.z_flat_offset)
    self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat, 0.5)

    self.fixture_flat:setSensor(true)

    self.fixture_flat:setCategory(6)

    self.fixture_flat:setMask(1,2,3,4,5,8,9)
    self.fixture_flat:setUserData(self)

    -- Shadow
    self.shadow = newShadow(self)
    self:updateShadow()
    

    -- Animations
    local sheet = love.graphics.newImage(GAME.sprites_directory.."/sprites/enemy_slime/slime.png")
    self.sprite = newSprite(0,0,0, sheet, 24, 24)
    self.y_sprite_offset = -0.3
    self.z_sprite_offset = (12/16)*math.cos(0.927295218)

    self.anim_angle = 2
    self.anim_flip_x = 1

    local animations_init = {}
    -- ["name"] = {first_1, last_1, row, time, angles}
    animations_init["idle"] = {1, 2, 1, 0.8, 2, nil}
    animations_init["attack_telegraph"] = {1, 3, 3, 0.2, 2, "pauseAtEnd"}
    animations_init["attack_process"] = {1, 2, 5, 0.2, 2, nil}
    animations_init["run"] = {1, 2, 7, 0.4, 2, nil}
    animations_init["die"] = {1, 1, 9, 0.2, 2, "pauseAtEnd"}

    self.animations = {}
    for anim_name, anim in pairs(animations_init) do
        -- ["name"] = {torso = {{angle = index}, ... }, legs = {{angle = index}, ... ]}
        self.animations[anim_name] = {}
        for angle = 1, anim[5], 1 do
            local index = self.sprite:newAnimation(anim[1], anim[2], anim[3] + (angle - 1), anim[4], anim[6])
            self.animations[anim_name][angle] = index
        end
    end

    self:setAnimation("idle", 1, 1, 1)
    self.last_angles_index = 1

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

-- AI Evaluation Functions -------------------------------------------------------------------------------------

function Enemy:isAlive_evalFunction()
    --print("Evaluating isAlive", self.userData.hp)
    return self.userData.hp ~= nil and self.userData.hp > 0
end

function Enemy:isStun_evalFunction()
    --print("Evaluating isStun", self.userData.stun)
    return self.userData.stun ~= nil and self.userData.stun == true
end

function Enemy:hasStamina_evalFunction()
    --print("Evaluating hasStamina", self.userData.stamina)
    return self.userData.stamina ~= nil and self.userData.stamina > 0
end

function Enemy:checkPlayer_evalFunction()
    local dist = getDistance(self.userData.position[1], self.userData.position[2], player_1.userData.position[1], player_1.userData.position[2])
    --print("Evaluating checkPlayer", dist)
    if dist > 100 then
        return 1
    else
        if dist < 50 then
            -- Attack action
            return 3
        else
            -- Seek action
            return 2
        end
    end
end

-- AI Actions -------------------------------------------------------------------------------------------------------

function Enemy:die_inizializeFunction()
    --print("Inizialize Die Action")
    self.body:setLinearDamping(2)
    --self.sprite:setRotation(-math.pi/2,0,0)
    --self.sprite:setScale(nil,nil,self.sprite.frame_height/16)
    --self.z_sprite_offset = -self.depth/16 + 1
    self:setAnimation("die", self.anim_angle, self.anim_flip_x, 1)
    self.userData.enemy_damage = 0
end

function Enemy:die_updateFunction(dt)
    self.die_timer = self.die_timer + dt
    --print(self.die_timer)        
    if self.die_timer > 1 then
        return "TERMINATED"
    end    
    return "RUNNING"
end

function Enemy:die_cleanUpFunction()
    --print("CleanUp Die Action")
    self:destroyMe()
end

function Enemy:stun_inizializeFunction()
    --print("Inizialize Stun Action")
    self.stun_timer = 0
    self.userData.stamina = self.userData.stamina - 1
    self.body:setLinearDamping(10)
    self.body:applyLinearImpulse(scaleVector(self.steering[1], self.steering[2], 10))

    table.insert(SPAWNQUEUE, {group = "Particle_Damage", args = {self.userData.position[1], self.userData.position[2], self.userData.position[3], 0, 0, getAngle(0, 0, self.steering[1], self.steering[2])}})
    table.insert(SPAWNQUEUE, {group = "Particle_Damage", args = {self.userData.position[1], self.userData.position[2], self.userData.position[3], 0, 0, getAngle(0, 0, self.steering[1], self.steering[2])+0.4}})
    table.insert(SPAWNQUEUE, {group = "Particle_Damage", args = {self.userData.position[1], self.userData.position[2], self.userData.position[3], 0, 0, getAngle(0, 0, self.steering[1], self.steering[2])-0.4}})
end

function Enemy:stun_updateFunction(dt)
    self.stun_timer = self.stun_timer + dt
    --print(self.stun_timer)
    if self.stun_timer > 0.15 then
        return "TERMINATED"
    end    
    return "RUNNING"
end

function Enemy:stun_cleanUpFunction()
    --print("CleanUp Stun Action")
    self.steering = {0, 0}
    self.userData.stun = false
end

function Enemy:idle_inizializeFunction()
    --print("Inizialize Idle Action")
    --self.body:setLinearVelocity(0, 0)
    self.idle_timer = 0
    self:setAnimation("idle", self.anim_angle, self.anim_flip_x, 1)
end

function Enemy:idle_updateFunction(dt)
    self.idle_timer = self.idle_timer + dt
    --print("Update Idle Action", self.idle_timer)
    if self.idle_timer > 3 then
        self.userData.stamina = self.userData.stamina + 1
        return "TERMINATED"
    else
        return "RUNNING"
    end
end

function Enemy:seek_inizializeFunction()
    --print("Inizialize Seek Action")
    self.body:setLinearVelocity(0, 0)
    self.body:setLinearDamping(10)
end

function Enemy:seek_updateFunction(dt)
    local dif_x, dif_y = difVector(self.userData.position[1], self.userData.position[2], player_1.userData.position[1], player_1.userData.position[2])
    local norm_x, norm_y = normalizeVector(dif_x, dif_y)
    local desired_vel_x, desired_vel_y = scaleVector(norm_x, norm_y, 80)
    local vel_x, vel_y = self.body:getLinearVelocity()

    self.steering = {difVector( vel_x, vel_y, desired_vel_x, desired_vel_y)}

    local dist = getLenght(dif_x, dif_y)
    --print("Update Seek Action")
    if dist < 50 then
        return "TERMINATED"
    else
        return "RUNNING"
    end
end

function Enemy:seek_cleanUpFunction()
    --print("CleanUp Seek Action")
    self.steering = {0, 0}
end

function Enemy:seekVel_inizializeFunction()
    --print("Inizialize SeekVel Action")
    self.body:setLinearVelocity(0, 0)
end

function Enemy:seekVel_updateFunction(dt)
    local dif_x, dif_y = difVector(self.userData.position[1], self.userData.position[2], player_1.userData.position[1], player_1.userData.position[2])
    self.angle = getAngle(dif_x,dif_y, 0,0)
    self.speed = 40
    self.body:setLinearVelocity(math.cos(self.angle) * self.speed, math.sin(self.angle) * self.speed)

    self:setAnimation("run", self.anim_angle, self.anim_flip_x, 1)

    local dist = getLenght(dif_x, dif_y)
    --print("Update Seek Action")
    if dist < 50 then
        return "TERMINATED"
    else
        return "RUNNING"
    end
end

function Enemy:seekVel_cleanUpFunction()
    --print("CleanUp Seek Action")
    self.steering = {0, 0}
    self.speed = 0
    self.body:setLinearVelocity(0, 0)
end

function Enemy:wander_inizializeFunction()
    --print("Inizialize Wander Action")
    local x, y = difVector(self.userData.position[1], self.userData.position[2], self.userData.spawn_position[1], self.userData.spawn_position[2])
    local lenght = getLenght(x, y)
    self.speed = 8
    self.wander_timer = 0
    if lenght < 20 then
        self.angle = math.random(0, 2*math.pi)
    else
        self.angle = getAngle(x,y, 0,0)
    end
end

function Enemy:wander_updateFunction(dt)
    self.wander_timer = self.wander_timer + dt
    --print("Update Wander Action", self.wander_timer)
    self.body:setLinearVelocity(math.cos(self.angle) * self.speed, math.sin(self.angle) * self.speed)
    self:setAnimation("run", self.anim_angle, self.anim_flip_x, 1)
    self.sprite:setSpeed(0.5)
    if self.wander_timer > 3 then
        return "TERMINATED"
    end
    return "RUNNING"
end

function Enemy:wander_cleanUpFunction()
    --print("CleanUp Wander Action")
    self.speed = 0
    self.wander_timer = 0
end

function Enemy:chargeAttack_inizializeFunction()
    --print("Inizialize chargeAttack Action")
    self.chargeAttack_timer = 0
    self.speed = 0
    self:goToFrameAnimation("attack_telegraph", 1)
end

function Enemy:chargeAttack_updateFunction(dt)
    self.chargeAttack_timer = self.chargeAttack_timer + dt
    if self.chargeAttack_timer < 0.6 then
        -- Telegraph attack
        --print("Telegraph Attack")
        self:setAnimation("attack_telegraph", 2, self.anim_flip_x, 1)
        self.angle = getAngle(self.userData.position[1], self.userData.position[2], player_1.userData.position[1], player_1.userData.position[2])
    else
        -- Perform the attack
        --print("Perfom Attack")
        self:setAnimation("attack_process", 2, self.anim_flip_x, 1)
        self.userData.enemy_damage = 10
        if self.chargeAttack_timer > 0.7 then
            if self.chargeAttack_timer > 2.2 then
                self.userData.stamina = self.userData.stamina - 1
                return "TERMINATED"
            end
        else
            self.body:setLinearDamping(2)
            self.body:applyLinearImpulse(math.cos(self.angle) * 2.4, math.sin(self.angle) * 2.4)
        end
    end
    return "RUNNING"
end

function Enemy:chargeAttack_cleanUpFunction()
    --print("CleanUp chargeAttack Action")
    self.userData.enemy_damage = 0
end

function Enemy:update(dt)

    self.tree:update(dt)

    self.userData.position[1], self.userData.position[2] = self.body:getX(), self.body:getY()

    --- Apply gravity
    if self.dz > self.max_falling then
        self.dz = self.dz + self.z_gravity
    end

    -- Check top and bottom floor, and then apply z velocity
    self.userData.position[3] = self.userData.position[3] + self.dz*dt

    self:setHeight()

    if self.bottom <= self.bottom_floor then
        self.on_ground = true
        self.userData.position[3] = self.bottom_floor + self.depth/2 + 0.01
    else
        self.on_ground = false
    end
    if self.top >= self.top_floor then        
        self.userData.position[3] = self.top_floor - self.depth/2 - 0.01
    end

    self:setHeight()

    --Shadow
    self.shadow:updatePosition(self.userData.position[1], self.userData.position[2], self.userData.position[3])
    self:updateShadow()

    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.height_flat/2 - self.z_flat_offset)*(0.8125)
    self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_flat_offset

    self.model:setTranslation(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z)

    -- Raycast
    --self.Ray.hitList = {}
    --self.Ray.x1, self.Ray.y1 = self.userData.position[1], self.userData.position[2]
    --self.Ray.x2, self.Ray.y2 = self.x - 400, self.userData.position[2]
    
    -- Cast the ray and populate the hitList table.
    --WORLD:rayCast(self.Ray.x1, self.Ray.y1, self.Ray.x2, self.Ray.y2, function(fixture, x, y, xn, yn, fraction) self:worldRayCastCallback(fixture, x, y, xn, yn, fraction) return 1 end)

    -- for i, hit in ipairs(self.Ray.hitList) do
    --     print(i, hit.x, hit.y, hit.xn, hit.xy, hit.fraction)
    -- end

    if self.userData.stun == true then
        self.stun_timer = self.stun_timer + dt
        self.sprite:setColor(1,1,1,0.5)
        if self.stun_timer > 0.2 then
            self.userData.stun = false
            self.stun_timer = 0
        end
    else
        self.sprite:setColor(1,1,1,0)
    end

    if self.userData.hp <= 0 then
        self.sprite:setColor(0,0,0,0.5)
        self:resetTree()
    end
    -- Animation Handleling
    self.sprite:update(dt)

    self:getAnimationAngle()

    self.sprite:setTranslation(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y + self.y_sprite_offset, self.userData.position[3]/SCALE3D.z + self.z_sprite_offset)
    
end

function Enemy:resetTree()
    --print("reset tree")
    if self.tree.currentAction ~= nil then
        self.tree.currentAction.status = "TERMINATED"
        self.tree.currentAction = nil
    end
    -- Also reset no-loop animations
    self:goToFrameAnimation("attack_telegraph", 1)
end

function Enemy:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(myShader, camera, shadow_map)
        --self.model:draw(myShader, camera, shadow_map)
        self.sprite:draw(shader, camera, shadow_map)
    else
        self.sprite:draw(shader, camera, shadow_map)
        --self.model:draw(myShader, camera, shadow_map)
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

function Enemy:screenDrawUI()
    local x, y = main_camera:pointOnScreen(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z)
    local size = 1.2*self.userData.max_hp
    local x2, y2 = x - size/2*WINDOWSCALE, y - (20)*WINDOWSCALE
    love.graphics.setLineWidth(1*WINDOWSCALE)
    love.graphics.setColor(244/255, 248/255, 255/255)
    love.graphics.rectangle("line", x2, y2, (size)*WINDOWSCALE, 2*WINDOWSCALE)
    love.graphics.setColor(47/255, 18/255, 25/255)
    love.graphics.rectangle("fill", x2, y2, (size)*WINDOWSCALE, 2*WINDOWSCALE)
    love.graphics.setColor(252/255, 55/255, 134/255)
    if self.userData.hp > 0 then
        local scale = self.userData.hp/self.userData.max_hp
        love.graphics.rectangle("fill", x2, y2, (size*scale)*WINDOWSCALE, 2*WINDOWSCALE)
    end
end

function Enemy:destroyMe()
    table.insert(current_map.DELETEQUEUE, {group = "Enemy", index = getIndex(current_section.enemies, self)})
end

function Enemy:setAnimation(name, angle, flip_x, flip_y)
    local anim = self.animations[name]
    self.sprite:changeAnimation(anim[angle], flip_x, flip_y)
    self.last_angles_index = angle
end

function Enemy:goToFrameAnimation(name, frame)
    local anim = self.animations[name]
    for _, index in pairs(anim) do
        self.sprite:goToFrame(index, frame)
    end
end

function Enemy:getAnimationAngle()
    --print(self.angle)
    local angle = self.angle
    if angle < 0 then angle = 3.14*2 + angle end
    local index = math.floor((angle/(2*3.14)) * 4 + 1.5)
    local sign = 1
    if index > 4 then index = index - 4 end
    if index > 2 then
        index = 3 - (index - 2)
        sign = -1
    end
    --print(angle*180/3.14, index, sign)
    self.anim_angle = index
    self.anim_flip_x = sign
end

function Enemy:setHeight()
    self.top = self.userData.position[3] + self.depth/2
    self.bottom = self.userData.position[3] - self.depth/2
end

function Enemy:gotHit(entity)
    --print("Enemy got hit: ", entity.fixture:getCategory())
end
function Enemy:exitHit(entity)
    --print("Enemy exited a collision")
end

function Enemy:takeDamage(amount)

    self.userData.hp = self.userData.hp - amount

    self.userData.stun = true

    if self.tree.currentAction ~= nil and self.tree.currentAction.name ~= "chargeAttack" then
        self.body:setLinearDamping(10)
        self.body:applyLinearImpulse(scaleVector(self.steering[1], self.steering[2], 10))
    end

    table.insert(current_map.SPAWNQUEUE, {group = "Particle_Damage", args = {self.userData.position[1], self.userData.position[2], self.userData.position[3], 0, 0, getAngle(0, 0, self.steering[1], self.steering[2])}})
    table.insert(current_map.SPAWNQUEUE, {group = "Particle_Damage", args = {self.userData.position[1], self.userData.position[2], self.userData.position[3], 0, 0, getAngle(0, 0, self.steering[1], self.steering[2])+0.4}})
    table.insert(current_map.SPAWNQUEUE, {group = "Particle_Damage", args = {self.userData.position[1], self.userData.position[2], self.userData.position[3], 0, 0, getAngle(0, 0, self.steering[1], self.steering[2])-0.4}})
end

function Enemy:hitboxIsHit(entity)
    --print("Enemy Hitbox is hit: ", entity.fixture:getCategory())
    if entity.userData ~= nil then
        if entity.userData.player_damage ~= nil and entity.userData.player_damage > 0 then
            self.steering = {normalizeVector(entity.body:getLinearVelocity())}
            if self.userData.hp > 0 and self.userData.stun == false then
                self:takeDamage(entity.userData.player_damage)
            end
        end
    end
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

return newEnemy