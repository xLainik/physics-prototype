local Shadow = {}
Shadow.__index = Shadow

local function newShadow(entity)
    local self = setmetatable({}, Shadow)

    -- Position of the xy center in 2D
    self.x, self.y, self.z = 0, 0, 0
    self.radius = entity.radius - 1


    --Physic object and floor buffer
    self.shape = love.physics.newCircleShape(self.radius)
    
    self.fixture_flat = love.physics.newFixture(entity.body, self.shape, 0.1)
    self.fixture_flat:setSensor(true)
    self.fixture_flat:setUserData(self)

    -- Shadow floor buffer
    --optional: including a permanent floor (in this case z=0)
    self.floor_buffer = {0}


    -- 3D Model for shadow casting
    local scale = (self.radius+1)*2/SCALE3D.x
    self.model = g3d.newModel(g3d.loadObj(GAME.models_directory.."/unit_disc_2.obj", false, true), GAME.models_directory.."/no_texture.png", {self.x, self.y, self.z}, {0,0,0}, scale)

    -- TODO: Instance meshing
    --self.index = shadow_imesh:addInstance(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z, scale,scale,scale, 0,0)
    --print("shadow index: ", self.index, self.radius)

    return self
end

function Shadow:updatePosition(x, y, z)
    self.x, self.y, self.z = x, y, z
    --shadow_imesh:updateInstancePosition(self.index, self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
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
    --shadow_imesh:removeInstance(self.index)
end

function Shadow:hitboxIsHit(entity)
    --print("Door Hitbox is hit: ", entity.fixture:getCategory())
end

function Shadow:gotHit(entity)
    --print("Shadow got hit")
    if entity.userData ~= nil and entity.userData.collision == true then
        table.insert(self.floor_buffer, entity.top)
        table.sort(self.floor_buffer)
    end
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