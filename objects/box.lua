local Box = {}
Box.__index = Box

local function newBox(x, y, z, width, height, depth, model, coll_category)
    local self = setmetatable({}, Box)

    self.model = model

    -- Position of the xyz center in 3D
    self.x = x + width/2 or 0
    self.y = y + height/2 or 0
    self.z = z + depth/2 or 0
    self.width = width or 60
    self.height = height or 60
    self.depth = depth or 60

    self.top = self.z + self.depth/2
    self.bottom = self.z - self.depth/2
    
    --print(coll_category, self.z)
    if z < 0 then
        -- barrier is colored black
        self.color = 0.0
    else
        -- floor level above 0
        self.color = (150 - z/2)/250
    end

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "static")
    self.shape = love.physics.newRectangleShape(self.width, self.height)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(coll_category)
    self.fixture:setUserData(self)

    return self
end

function Box:update(dt)
    --pass
end

function Box:draw(shader, camera, shadow_map)
    self.model:setTranslation(self.x/SCALE3D.x, self.y/SCALE3D.y, self.z/SCALE3D.z)
    self.model:draw(shader, camera, shadow_map)
end

function Box:gotHit(entity)
    --print("Box got hit")
end
function Box:exitHit(entity)
    --print("Box exited a collision")
end

return newBox