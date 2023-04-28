local Ramp = {}
Ramp.__index = Ramp

local function newRamp(ramp_type, x, y, z, width, height, depth, model)
    local self = setmetatable({}, Ramp)

    local z_rotation = model.rotation[3]

    -- Position of the xyz center in 3D
    self.x, self.y  = rotatePoint(x,y, x+width/2,y+height/2, z_rotation)
    self.z = z + depth/2 or 0
    
    self.width = width or 60
    self.height = height or 60
    self.depth = depth or 60

    if ramp_type == "Diagonal_Ramp" or ramp_type == "Diagonal_Ramp_Inner" then
        self.normal = {normalizeVector_3D(crossProduct_3D(width,0,depth, -width,height,0))}
    end

    self.origin_x = x*SCALE3D.x
    self.origin_y = y*SCALE3D.y
    self.origin_z = z*SCALE3D.z

    self.top = (self.z + self.depth/2)*SCALE3D.z
    self.bottom = (self.z - self.depth/2)*SCALE3D.z

    -- Top Functions -----------------------------------------------------------------------

    if ramp_type == "Regular_Ramp" then
        self.top_function = function(x, y)
            local loc_x = self.body:getLocalPoint(x, y)
            local rel_x = loc_x+self.width/2*SCALE3D.x
            local intersect = rel_x*self.depth/self.width
            return clamp(self.origin_z + intersect, self.bottom, self.top), true
        end
    end

    if ramp_type == "Diagonal_Ramp" then
        self.top_function = function(x, y)
            local loc_x, loc_y = self.body:getLocalPoint(x, y)
            local rel_x, rel_y = loc_x+self.width/2*SCALE3D.x, -1*(loc_y+self.height/2*SCALE3D.y)
            local intersect = (self.normal[1]*self.width*SCALE3D.x - self.normal[1]*rel_x - self.normal[2]*rel_y)/self.normal[3]
            return clamp(self.origin_z + intersect, self.bottom, self.top), self.fixture:testPoint(x, y)
        end
    elseif ramp_type == "Diagonal_Ramp_Inner" then
        self.top_function = function(x, y)
            local loc_x, loc_y = self.body:getLocalPoint(x, y)
            local rel_x, rel_y = loc_x+self.width/2*SCALE3D.x, -1*(loc_y+self.height/2*SCALE3D.y)
            local intersect = (self.normal[1]*self.width*SCALE3D.x - self.normal[1]*rel_x - self.normal[2]*rel_y)/self.normal[3]
            return clamp(self.origin_z + intersect + self.depth*SCALE3D.x, self.bottom, self.top), self.fixture:testPoint(x, y)
        end
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
    self.body:setAngle(-1*z_rotation)

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