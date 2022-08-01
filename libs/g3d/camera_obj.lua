-- written by groverbuger for g3d
-- september 2021
-- MIT license

local newMatrix = require("libs/g3d/matrices")

----------------------------------------------------------------------------------------------------
-- define the camera singleton
----------------------------------------------------------------------------------------------------

local camera = {}
camera.__index = camera

local function newCamera(aspectRatio)
    local self = setmetatable({}, camera)

    self.fov = math.pi/2
    self.nearClip = 0.01
    self.farClip = 1000
    self.aspectRatio = aspectRatio or love.graphics.getWidth()/love.graphics.getHeight()
    self.position = {0,0,0}
    self.target = {1,0,0}
    self.up = {0,0,1}
    self.size = 5
    self.radius = 12
    self.viewMatrix = newMatrix()
    self.projectionMatrix = newMatrix()
    
    self.direction = 0
    self.pitch = 0

    return self
end

function camera:getLookVector()
    local vx = self.target[1] - self.position[1]
    local vy = self.target[2] - self.position[2]
    local vz = self.target[3] - self.position[3]
    local length = math.sqrt(vx^2 + vy^2 + vz^2)

    -- make sure not to divide by 0
    if length > 0 then
        return vx/length, vy/length, vz/length
    end
    return vx,vy,vz
end
function camera:lookAt(x,y,z, xAt,yAt,zAt)
    self.position[1] = x
    self.position[2] = y
    self.position[3] = z
    self.target[1] = xAt
    self.target[2] = yAt
    self.target[3] = zAt

    -- update the fpsController's direction and pitch based on lookAt
    local dx,dy,dz = self:getLookVector()
    self.direction = math.pi/2 - math.atan2(dz, dx)
    self.pitch = math.atan2(dy, math.sqrt(dx^2 + dz^2))

    -- update the camera in the shader
    self:updateViewMatrix()
end

function camera:lookInDirection(x,y,z, directionTowards,pitchTowards)
    self.position[1] = x or self.position[1]
    self.position[2] = y or self.position[2]
    self.position[3] = z or self.position[3]

    self.direction = directionTowards or self.direction
    self.pitch = pitchTowards or self.pitch

    -- turn the cos of the pitch into a sign value, either 1, -1, or 0
    local sign = math.cos(self.pitch)
    sign = (sign > 0 and 1) or (sign < 0 and -1) or 0

    -- don't let cosPitch ever hit 0, because weird camera glitches will happen
    local cosPitch = sign*math.max(math.abs(math.cos(self.pitch)), 0.00001)

    -- convert the direction and pitch into a target point
    self.target[1] = self.position[1]+math.cos(self.direction)*cosPitch
    self.target[2] = self.position[2]+math.sin(self.direction)*cosPitch
    self.target[3] = self.position[3]+math.sin(self.pitch)

    -- update the camera in the shader
    self:updateViewMatrix()
end

-- recreate the camera's view matrix from its current values
function camera:updateViewMatrix()
    self.viewMatrix:setViewMatrix(self.position, self.target, self.up)
end

-- recreate the camera's projection matrix from its current values
function camera:updateProjectionMatrix()
    self.projectionMatrix:setProjectionMatrix(self.fov, self.nearClip, self.farClip, self.aspectRatio)
end

-- recreate the camera's orthographic projection matrix from its current values
function camera:updateOrthographicMatrix(size)
    self.size = size
    self.projectionMatrix:setOrthographicMatrix(self.fov, self.size, self.nearClip, self.farClip, self.aspectRatio)
end

function camera:thirdPersonLook(dx, dy, player_x, player_y, player_z)

    local sensitivity = 1/400

    self.direction = self.direction + dx*sensitivity
    self.pitch = math.max(math.min(self.pitch - dy*sensitivity, math.pi*0.5), math.pi*-0.5)

    self.position[1] = player_x + math.cos(self.direction)*math.cos(self.pitch)*self.radius
    self.position[2] = player_y + math.sin(self.direction)*math.cos(self.pitch)*self.radius
    self.position[3] = player_z + math.sin(self.pitch)*self.radius

    --Equivalent code might be:
    --camera.lookAt(camera.position[1],camera.position[2],camera.position[3], player_x, player_y, player_z)

    self.target[1] = player_x
    self.target[2] = player_y
    self.target[3] = player_z

    self:updateViewMatrix()

    --But changing the parameters directly is faster
end

function camera:thirdPersonMovement(dt, player_x, player_y, player_z)

    if love.keyboard.isDown("left") then
        self.direction = self.direction - math.pi/2*dt
    elseif love.keyboard.isDown("right") then
        self.direction = self.direction + math.pi/2*dt
    end

    if love.keyboard.isDown("down") then
        self.pitch = math.max(math.min(self.pitch - math.pi/2*dt, math.pi*0.5), math.pi*-0.5)
    elseif love.keyboard.isDown("up") then
        self.pitch = math.max(math.min(self.pitch + math.pi/2*dt, math.pi*0.5), math.pi*-0.5)
    end

    self.position[1] = player_x + math.cos(self.direction)*math.cos(self.pitch)*self.radius
    self.position[2] = player_y + math.sin(self.direction)*math.cos(self.pitch)*self.radius
    self.position[3] = player_z + math.sin(self.pitch)*self.radius

    --Equivalent code might be:
    --camera.lookAt(camera.position[1],camera.position[2],camera.position[3], player_x, player_y, player_z)

    self.target[1] = player_x
    self.target[2] = player_y
    self.target[3] = player_z

    self:updateViewMatrix()

    --But changing the parameters directly seems faster
end

function camera:moveCamera(dx, dy, dz)

    self.position[1] = self.position[1] + dx
    self.position[2] = self.position[2] + dy
    self.position[3] = self.position[3] + dz

    self.target[1] = self.target[1] + dx
    self.target[2] = self.target[2] + dy
    self.target[3] = self.target[3] + dz
    
    self:updateViewMatrix()

end

function camera:followPoint()
    -- angle1 = center_angle(player1.rect, cursor1.rect)
    -- #angle1 = math.atan2(cursor1.rect.y - player1.y, cursor1.rect.x - player1.x)
    -- dist1 = center_distance(player1.rect, cursor1.rect)
    -- if dist1 > 30: dist1 = 30
    -- self.desired_pos = [player1.rect.centerx + round(math.cos(angle1)*dist1*0.5), player1.rect.centery + round(math.sin(angle1)*dist1*0.5)] # mid point                

    -- angle2 = math.atan2(self.desired_pos[1] - self.rect.centery, self.desired_pos[0] - self.rect.centerx)
    -- dist2 = math.sqrt((self.rect.centerx - self.desired_pos[0])**2 + (self.rect.centery - self.desired_pos[1])**2)
    -- self.speed = easeOutExpo(dist2, 1, 2, dist1)
    -- #print(self.speed)
    -- self.speed_x, self.speed_y = math.cos(angle2)*self.speed, math.sin(angle2)*self.speed
    -- if self.rect.centerx in range(self.desired_pos[0]-3, self.desired_pos[0]+4) and self.rect.centery in range(self.desired_pos[1]-3, self.desired_pos[1]+4):
    --     self.speed_x, self.speed_y = 0, 0
    --     self.x, self.y = self.desired_pos[0] - SCREEN_WIDTH/2, self.desired_pos[1] - SCREEN_HEIGHT/2
    -- else:
    --     self.x += player1.speed_x + self.speed_x
    --     self.y += player1.speed_y + self.speed_y

    -- self.rect.x = int(self.x)
    -- self.rect.y = int(self.y)
end

return newCamera
