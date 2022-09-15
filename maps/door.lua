local Door = {}
Door.__index = Door

function Door:new(x, y, z, index, connected_to)
    local self = setmetatable({}, Door)

    --Position of the circle center
    self.x = x or 50
    self.y = y or 50
    self.z = z or 50

    self.index = index or 1

    self.radius = 2

    self.userData = {
        position = {self.x, self.y},
        spawn_position = {x, y},
        connected_to = connected_to or 1
        }

    --Physics
    self.body = love.physics.newBody(current_map.WORLD, self.x, self.y, "dynamic")
    self.body:setFixedRotation(true)

    self.dz = -8
    self.z_gravity = -8
    self.max_falling = -200

    -- Variables for jumping
    self.top_floor = 1000
    self.bottom_floor = -1000

    self.depth = 64
    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2

    self.z_flat_offset = 8

    -- Flat hitbox
    self.width_flat, self.height_flat = 16, 16
    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, self.body:getY()*(0.8125) - self.height_flat/2 - self.z_flat_offset
    self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_flat_offset

    --self.shape_flat = love.physics.newCircleShape(self.radius)
    --self.shape_flat:setPoint(0, -self.z_flat_offset)
    local x, y = self.width_flat/2, self.height_flat/2 
    self.shape_flat = love.physics.newPolygonShape(-x, -y -self.z_flat_offset, x, -y -self.z_flat_offset, -x, y -self.z_flat_offset, x, y -self.z_flat_offset)
    self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat, 0.5)

    self.fixture_flat:setSensor(true)

    self.fixture_flat:setCategory(6)

    -- Shadow
    self.shadow = newShadow(self)
    self:setHeight()

    local scale = {self.width_flat/SCALE3D.x, self.height_flat/SCALE3D.x, self.depth/SCALE3D.z}
    self.model = g3d.newModel(g3d.loadObj(GAME.models_directory.."/unit_cube.obj", false, true), GAME.models_directory.."/no_texture.png", {1,1,1}, {0,0,0}, scale)

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

    return self
end

function Door:update(dt)
    
    self.x, self.y = self.body:getX(), self.body:getY()

    --self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.height_flat/2 - self.z_flat_offset)*(0.8125)
    self.flat_x, self.flat_y = self.body:getX(), self.body:getY()*(0.8125) - self.z_flat_offset

    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)

    --Shadow
    self.shadow:updatePosition(self.x, self.y, self.z)
    self:updateShadow()

    -- Animation Handleling
    self.sprite:update(dt)

    self.sprite:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y + self.y_sprite_offset, self.z/SCALE3D.z + self.z_sprite_offset)
    
end

function Door:updateUserData()
    self.userData.position = {self.x, self.y}
end


function Door:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(myShader, camera, shadow_map)
        --self.sprite:draw(shader, camera, shadow_map)
        self.model:draw(shader, camera, shadow_map)
    else
        --self.sprite:draw(shader, camera, shadow_map)
        self.model:draw(shader, camera, shadow_map)
    end
end

function Door:debugDraw()
    --love.graphics.setColor(0.95, 0.2, 0.35)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.flat_x, self.flat_y, self.radius)
    --love.graphics.rectangle("line", self.flat_x, self.flat_y, self.width_flat, self.height_flat*(0.8125))

end

function Door:screenDrawUI()
    --pass
end

function Door:destroyMe()
    table.insert(current_map.DELETEQUEUE, {group = "Door", index = getIndex(current_scene.enemies, self)})
    self.body:destroy()
end

function Door:setPosition(x, y)
    self.body:setPosition(x, y)
end

function Door:setAnimation(name, angle, flip_x, flip_y)
    local anim = self.animations[name]
    self.sprite:changeAnimation(anim[angle], flip_x, flip_y)
    self.last_angles_index = angle
end

function Door:goToFrameAnimation(name, frame)
    local anim = self.animations[name]
    for _, index in pairs(anim) do
        self.sprite:goToFrame(index, frame)
    end
end

function Door:getAnimationAngle()
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

function Door:setHeight()
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

    self.fixture_flat:setMask(1,2,3,4,5,8,9, unpack(mask))
    self.fixture_flat:setUserData(self)
end

function Door:gotHit(entity)
    --print("Door got hit: ", entity.fixture:getCategory())
end
function Door:exitHit(entity)
    --print("Door exited a collision")
end

function Door:takeDamage(amount)
    --pass
end

function Door:hitboxIsHit(entity)
    --print("Door Hitbox is hit: ", entity.fixture:getCategory())
    if entity.userData ~= nil then
        local id = entity.userData.id
        if id == "player" then
            print("hello player")
        end
    end
end
function Door:hitboxGotHit(entity)
    --print("Door Hitbox got hit: ", entity.fixture:getCategory())
end
function Door:hitboxExitHit(entity)
    --print("Door Hitbox exited a collision")
end

function Door:updateShadow()
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

return Door