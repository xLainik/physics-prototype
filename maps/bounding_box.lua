local BoundingBox = {}
BoundingBox.__index = BoundingBox

local function newBoundingBox(x1, y1, x2, y2)
    local self = setmetatable({}, BoundingBox)

    self.queryBodies = {}

    -- callback function for queryBoundingBox() that is called when pressed left mouse while in idle state
    self.queryCallback = function(fixture)
        table.insert(self.queryBodies, fixture:getBody())
        return true
    end

    self.x1, self.y1, self.x2, self.y2 = x1, y1, x2, y2

    return self
end

function BoundingBox:activateBodies()
    current_map.WORLD:queryBoundingBox( self.x1, self.y1, self.x2, self.y2, self.queryCallback)
    for _, body in pairs(self.queryBodies) do
        if body:isDestroyed() == false then
            if body:getType() == "static" then
                body:setActive(true)
            end
        end
    end
    self.queryResult = {}
end

function BoundingBox:deactivateBodies()
    current_map.WORLD:queryBoundingBox( self.x1, self.y1, self.x2, self.y2, self.queryCallback)
    for _, body in pairs(self.queryBodies) do
        if body:isDestroyed() == false then
            body:setActive(false)
        end
    end
end



return newBoundingBox