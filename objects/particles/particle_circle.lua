local Particle = {}
Particle.__index = Particle

local function newParticle(x, y, z, entity_dx, entity_dy, ini_angle, options)
    local self = setmetatable({}, Particle)

    self.type = "damage"
    self.index = nil

    --Position of the 3D cylinder center
    self.x = x
    self.y = y
    self.z = z

    self.angle = ini_angle

    self.userData = {}

    -- More user data
    self.speed = 0
    self.radius = 1
    self.inactive_timer = 0
    self.max_timer = 0.1

    self.timer = 0

    self.active = true

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "dynamic")
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

    local instance_index = particle_imesh:addInstance(self.matrix, self.uvs[1], self.uvs[2], self.uvs[3])
    self.index = instance_index
    particles[instance_index] = self

    local color = options["color"] or {1,1,1,0}
    particle_imesh:updateInstanceColor(self.index, color[1], color[2], color[3], color[4])

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
    self.x, self.y = self.body:getX(), self.body:getY()

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
    self.position = {self.x/SCALE3D.x, self.y/SCALE3D.y + self.y_sprite_offset, self.z/SCALE3D.z + self.z_sprite_offset}
    self.matrix:setTransformationMatrix(self.position, self.rotation, self.scale)

    particle_imesh:updateInstanceMAT(self.index, self.matrix:getMatrixRows())

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
    local last_index = particle_imesh:removeInstance(self.index)
    local last_obj = particles[last_index]
    particles[self.index] = last_obj
    last_obj.index = self.index

    table.insert(DELETEQUEUE, {group = "Particle", index = last_index})

    self.body:destroy()
end

function Particle:gotHit(entity, xn, yn)
    --print("Particle got hit: ", entity.fixture:getCategory())
end
function Particle:exitHit(entity, xn, yn)
    --print("Particle exited a collision")
end


return newParticle