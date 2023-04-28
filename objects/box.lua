local Box = {}
Box.__index = Box

local function newBox(x, y, z, width, height, depth, rot_x, rot_y, rot_z, model)
    local self = setmetatable({}, Box)

    -- Position/Scale and rotation of the xyz center in 3D
    self.x, self.y  = rotatePoint(x,y, x+width/2,y+height/2, rot_z)
    self.z = z + depth/2
    self.width = width or 60
    self.height = height or 60
    self.depth = depth or 60

    self.top = (self.z + self.depth/2)*SCALE3D.z
    self.bottom = (self.z - self.depth/2)*SCALE3D.z

    self.top_function = function(x, y)
        return self.top, true
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
    self.body:setAngle(-1*rot_z)

    -- Fixture Category and Mask
    self.fixture:setCategory(10)
    self.fixture:setUserData(self)

    -- 3D model
    self.model = model
    self.model:setTranslation(self.x, self.y, self.z)

    return self
end

function Box:update(dt)
    --pass
end

function Box:draw(shader, camera, shadow_map)
    self.model:draw(shader, camera, shadow_map)
end

function Box:getTopFunction()
    return self.top_function
end

function Box:getBottomFunction()
    return self.bottom_function
end

function Box:gotHit(entity)
    --print("Box got hit")
end
function Box:exitHit(entity)
    --print("Box exited a collision")
end

function Box:hitboxGotHit(entity)
    --print("Box Hitbox got hit: ", entity.fixture:getCategory())
end
function Box:hitboxExitHit(entity)
    --print("Box Hitbox exited a collision")
end

return newBox