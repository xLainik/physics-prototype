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
    self.body = love.physics.newBody(current_map.WORLD, self.x*SCALE3D.x, self.y*SCALE3D.y, "static")
    self.shape = love.physics.newRectangleShape(self.width*SCALE3D.x, self.height*SCALE3D.x)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(coll_category)
    self.fixture:setUserData(self)

    -- Flat hitbox
    self.width_flat, self.height_flat = self.width*SCALE3D.x, self.height*SCALE3D.x*0.8125
    self.flat_x, self.flat_y = self.body:getX() - self.width_flat/2, (self.body:getY() - self.height_flat/2 - self.depth/2)*(0.8125)

    self.shape_flat = love.physics.newRectangleShape(self.width_flat, self.height_flat*(0.8125))
    self.fixture_flat = love.physics.newFixture(self.body, self.shape_flat)

    self.fixture_flat:setSensor(true)
    self.fixture_flat:setCategory(coll_category)
    self.fixture_flat:setUserData(self)

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

function Box:debugDraw()
    love.graphics.rectangle("line", self.flat_x, self.flat_y, self.width_flat, self.height_flat)
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