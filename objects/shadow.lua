local Shadow = {}
Shadow.__index = Shadow

local function newShadow(entity)
    local self = setmetatable({}, Shadow)

    -- Position of the xy center in 2D
    self.entity = entity
    self.x, self.y = self.entity.x, self.entity.y
    self.radius = self.entity.radius

    --Physics
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.entity.body, self.shape, 0.1)

    local scale = self.radius*2/SCALE3D.x
    self.model = g3d.newModel(g3d.loadObj("assets/3d/unit_disc_2.obj", false, true), "assets/3d/no_texture.png", {x,y,z}, {0,0,0}, scale)

    self.fixture:setSensor(true)
    self.fixture:setCategory(1)
    self.fixture:setMask(10)

    self.fixture:setUserData(self)

    -- Shadow floor buffer
    --optional: including a permanent floor (in this case z=0)
    self.floor_buffer = {0}

    return self
end

function Shadow:update()
    self.x, self.y = self.entity.x, self.entity.y
end

function Shadow:debugDraw()
    love.graphics.setColor(0.2, 0.1, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.circle("fill", self.x, self.y, self.radius, 6)
end

function Shadow:draw(shader, camera, shadow_map)
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.entity.z/SCALE3D.z)
    self.model:draw(shader, camera, shadow_map)
end

function Shadow:gotHit(entity)
    --print("Shadow got hit")
    table.insert(self.floor_buffer, entity.top)
    table.sort(self.floor_buffer)
end
function Shadow:exitHit(entity)
    --print("Shadow exited a collision")
    for i, floor in ipairs(self.floor_buffer) do
        if floor == entity.top then
            table.remove(self.floor_buffer, i)
            break
        end
    end
end

return newShadow