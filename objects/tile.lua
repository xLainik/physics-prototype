local Tile = {}
Tile.__index = Tile

local function newTile(x, y, width, height)
    local self = setmetatable({}, Tile)

    --Position of the rectangle center
    self.x = x + width/2 or 50
    self.y = y + height/2 or 50
    self.width = width or 50
    self.height = height or 50

    --Physics
    self.body = love.physics.newBody(WORLD, self.x, self.y, "static")
    self.shape = love.physics.newRectangleShape(self.width, self.height)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setCategory(10)
    self.fixture:setUserData(self)

    return self
end

function Tile:update(dt)
    --pass
end

function Tile:debugDraw()
    love.graphics.setColor(0.85, 0.85, 0.9)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
end

function Tile:gotHit(entity, xn, yn)
    --print("Tile got hit")
end

return newTile