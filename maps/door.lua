local Door = {}
Door.__index = Door

local function newDoor(x, y, z, width, height, depth, model, index, connected_to, direction)
    local self = setmetatable({}, Door)
    -- An object that connects different sections of the current map

    self.index = index

    -- Format: {section_index, door_index}
    self.connected_to = connected_to

    self.direction = direction

    -- Scale
    self.width = width*SCALE3D.x
    self.height = height*SCALE3D.x
    self.depth = depth*SCALE3D.z

    self.userData = {
        position = {(x + width/2)*SCALE3D.x, (y + height/2)*SCALE3D.y, (z + depth/2)*SCALE3D.z},
        spawn_position = {(x + width/2)*SCALE3D.x, (y + height/2)*SCALE3D.y, (z + depth/2)*SCALE3D.z}
        }

    self.top = self.userData.position[3] + self.depth/2
    self.bottom = self.userData.position[3] - self.depth/2

    --Physics
    self.body = love.physics.newBody(current_map.WORLD, self.userData.position[1], self.userData.position[2], "dynamic")
    self.shape = love.physics.newRectangleShape(self.width, self.height)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    -- Fixture Category and Mask
    self.fixture:setSensor(true)
    self.fixture:setCategory(z + 12)
    self.fixture:setMask(6)
    self.fixture:setUserData(self)

    -- 3D model
    self.model = model
    self.model:setTranslation(self.userData.position[1]/SCALE3D.x, self.userData.position[2]/SCALE3D.y, self.userData.position[3]/SCALE3D.z)

    return self
end

function Door:update(dt)
    --pass
end

function Door:draw(shader, camera, shadow_map)
    self.model:draw(shader, camera, shadow_map)
end


function Door:screenDrawUI()
    --pass
end

function Door:gotHit(entity)
    --print("Door got hit: ", entity.fixture:getCategory())
    if entity.userData ~= nil then
        local id = entity.userData.id
        if id == "player" then
            print("Transition to section", self.connected_to[1])
            -- Load Scetion
            table.insert(current_map.SPAWNQUEUE, {group = "enterSection", args = {current_map, self.connected_to[1], self.connected_to[2]}} )
        end
    end
end
function Door:exitHit(entity)
    --print("Door exited a collision")
end

function Door:takeDamage(amount)
    --pass
end

function Door:hitboxIsHit(entity)
    --print("Door Hitbox is hit: ", entity.fixture:getCategory())
end
function Door:hitboxGotHit(entity)
    --print("Door Hitbox got hit: ", entity.fixture:getCategory())
end
function Door:hitboxExitHit(entity)
    --print("Door Hitbox exited a collision")
end

return newDoor