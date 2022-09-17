local Particle = {}
Particle.__index = Particle

local function newParticle(x, y, z, entity_dx, entity_dy, ini_angle, options)
    local self = setmetatable({}, Particle)

    self.type = "damage"
    self.index = nil

    self.angle = ini_angle

    self.userData = {
        position = {x,y,z},
        spawn_position = {x,y,z}
        }

    -- More user data
    self.speed = 0
    self.radius = 1
    self.inactive_timer = 0
    self.max_timer = 0.1

    self.timer = 0

    self.active = true

    --Physics
    self.body = love.physics.newBody(current_map.WORLD, self.userData.position[1], self.userData.position[2], "dynamic")
    self.body:setFixedRotation(true)
    self.body:setMass(1)

    self.body:setActive(false)

    self.body:applyLinearImpulse(math.cos(self.angle)*self.speed, math.sin(self.angle)*self.speed)

    -- Instance mesh
    local style = options["style"] or "line"
    if style == "fill" then
        self.uvs = {0/16, 8/16, 2}
    else
        self.uvs = {2/16, 8/16, 2}
    end
    self.matrix = g3d.newMatrix()
    self.position = {x,y,z}
    self.rotation = {-0.927295218, 0, 0}
    self.scale = {8/16, 0, 8/16}
    self.matrix:setTransformationMatrix(self.position, self.rotation, self.scale)

    local instance_index = current_section.particle_imesh:addInstance(self.matrix, self.uvs[1], self.uvs[2], self.uvs[3])
    self.index = instance_index
    current_section.particles[instance_index] = self

    local color = options["color"] or {1,1,1,0}
    current_section.particle_imesh:updateInstanceColor(self.index, color[1], color[2], color[3], color[4])

    -- Drawing offsets
    self.y_sprite_offset = -0.3
    self.z_sprite_offset = (12/16)*math.cos(0.927295218)

    return self
end

function Particle:setVelocity(speed, angle)
    self.speed = speed
    self.angle = angle
    self.body:setLinearVelocity(math.cos(self.angle)*self.speed, math.sin(self.angle)*self.speed)
end

function Particle:update(dt)
    self.userData.position[1], self.userData.position[2] = self.body:getX(), self.body:getY()

    self.timer = self.timer + dt

    if self.timer > self.inactive_timer then
        self.body:setActive(true)
    end
    if self.timer > self.max_timer then
        self.active = false
    end

    self.scale[1] = self.scale[1] + 2*dt
    self.scale[3] = self.scale[3] + 2*dt

    -- Instanced Mesh update
    self.position = {self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y + self.y_sprite_offset, self.userData.position[3]/SCALE3D.z + self.z_sprite_offset}
    self.matrix:setTransformationMatrix(self.position, self.rotation, self.scale)

    current_section.particle_imesh:updateInstanceMAT(self.index, self.matrix:getMatrixRows())

    if self.active == false then
        self:destroyMe()
    end

end

function Particle:debugDraw()
    --print("hello")
    --love.graphics.setColor(0.9, 0.8, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.flat_x, self.flat_y, self.radius, 6)
    --love.graphics.rectangle("line", self.flat_x, self.flat_y, self.width_flat, self.height_flat)
end

function Particle:draw(shader, camera, shadow_map)
    if shadow_map == true then
        --self.shadow:draw(shader, camera, shadow_map)
    else
        --self.model:draw(shader, camera, shadow_map)
    end
end

function Particle:destroyMe()
    local last_index = current_section.particle_imesh:removeInstance(self.index)
    local last_obj = current_section.particles[last_index]
    current_section.particles[self.index] = last_obj
    last_obj.index = self.index

    table.insert(current_map.DELETEQUEUE, {group = "Particle", index = last_index})

    self.body:destroy()
end

function Particle:gotHit(entity, xn, yn)
    --print("Particle got hit: ", entity.fixture:getCategory())
end
function Particle:exitHit(entity, xn, yn)
    --print("Particle exited a collision")
end


return newParticle