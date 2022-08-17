local Box = {}
Box.__index = Box

local function newBox(x, y, z, width, height, depth, model, coll_category)
    local self = setmetatable({}, Box)

    -- Position of the xyz center in 3D
    self.x = x + width/2 or 0
    self.y = y + height/2 or 0
    self.z = z + depth/2 or 0
    self.width = width or 60
    self.height = height or 60
    self.depth = depth or 60

    self.top = (self.z + self.depth/2)*SCALE3D.z
    self.bottom = (self.z - self.depth/2)*SCALE3D.z

    --Physics
    self.body = love.physics.newBody(WORLD, self.x*SCALE3D.x, self.y*SCALE3D.y, "static")
    self.shape = love.physics.newRectangleShape(self.width*SCALE3D.x, self.height*SCALE3D.x)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(coll_category)
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

function Box:gotHit(entity)
    --print("Box got hit")
end
function Box:exitHit(entity)
    --print("Box exited a collision")
end

return newBox