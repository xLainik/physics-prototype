local Ramp = {}
Ramp.__index = Ramp

local function newRamp(x, y, z, width, height, depth, model)
    local self = setmetatable({}, Ramp)

    -- Position of the xyz center in 3D
    self.x = x + width/2 or 0
    self.y = y + height/2 or 0
    self.z = z + depth/2 or 0
    self.width = width or 60
    self.height = height or 60
    self.depth = depth or 60

    self.origin_x = x*SCALE3D.x
    self.origin_y = y*SCALE3D.y
    self.origin_z = z*SCALE3D.z

    self.top = (self.z + self.depth/2)*SCALE3D.z
    self.bottom = (self.z - self.depth/2)*SCALE3D.z

    self.top_function = function(x, y)
        local rel_x = x - self.origin_x
        local rel_y = self.origin_y - y
        if rel_x >= 0 and rel_x < self.width*SCALE3D.x then
            return clamp(self.origin_z + rel_x*self.depth/self.width, self.bottom, self.top)
        end
        if rel_x < 0 then
            return self.bottom
        elseif rel_x >= self.width*SCALE3D.x then
            return self.top
        end
        --return rel_x * self.depth/self.width + self.bottom + 1
    end

    self.bottom_function = function(x, y)
        return self.bottom
    end

    self.userData = {
        collision = true
        }

    --Physics
    self.body = love.physics.newBody(current_map.WORLD, self.x*SCALE3D.x, self.y*SCALE3D.y, "static")
    self.shape = love.physics.newRectangleShape(self.width*SCALE3D.x, self.height*SCALE3D.x)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    --self.fixture:setSensor(true)

    -- Fixture Category and Mask
    self.fixture:setCategory(11)
    self.fixture:setUserData(self)

    -- 3D model
    self.model = model
    self.model:setTranslation(self.x, self.y, self.z)

    return self
end

function Ramp:update(dt)
    --pass
end

function Ramp:draw(shader, camera, shadow_map)
    self.model:draw(shader, camera, shadow_map)
end

function Ramp:getTopFunction()
    return self.top_function
end

function Ramp:getBottomFunction()
    return self.bottom_function
end

function Ramp:gotHit(entity)
    --print("Ramp got hit")
end
function Ramp:exitHit(entity)
    --print("Ramp exited a collision")
end

function Ramp:hitRampGotHit(entity)
    --print("Ramp HitRamp got hit: ", entity.fixture:getCategory())
end
function Ramp:hitRampExitHit(entity)
    --print("Ramp HitRamp exited a collision")
end

return newRamp