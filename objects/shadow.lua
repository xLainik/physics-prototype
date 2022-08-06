local Shadow = {}
Shadow.__index = Shadow

local function newShadow(entity, options)
    local self = setmetatable({}, Shadow)

    -- Position of the xy center in 2D
    self.x, self.y, self.z = entity.x, entity.y, entity.z
    self.radius = entity.radius - 1

    local physics = true

    if options ~= nil then
        physics = options["physics"]
    end

    if physics == true then
        --Physic object and floor buffer
        self.shape = love.physics.newCircleShape(self.radius)
        self.fixture = love.physics.newFixture(entity.body, self.shape, 0.1)

        self.fixture:setSensor(true)
        self.fixture:setCategory(1)
        self.fixture:setMask(1, 10)

        self.fixture:setUserData(self)

        -- Shadow floor buffer
        --optional: including a permanent floor (in this case z=0)
        self.floor_buffer = {0}
    end

    --Instance
    local scale = (self.radius+1)*2/SCALE3D.x
    --self.model = g3d.newModel(g3d.loadObj("assets/3d/unit_disc_2.obj", false, true), "assets/3d/no_texture.png", {self.x, self.y, self.z}, {0,0,0}, scale)

    self.index = shadow_imesh:addInstance(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z, scale,scale,scale, 0,0)
    --print("shadow index: ", self.index, self.radius)

    return self
end

function Shadow:updatePosition(x, y, z)
    self.x, self.y, self.z = x, y, z
    shadow_imesh:updateInstancePosition(self.index, self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
end

function Shadow:debugDraw()
    love.graphics.setColor(0.2, 0.1, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.circle("fill", self.x, self.y, self.radius, 6)
end

function Shadow:draw(shader, camera, shadow_map)
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
    self.model:draw(shader, camera, shadow_map)
end

function Shadow:destroyMe()
    shadow_imesh:removeInstance(self.index)
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