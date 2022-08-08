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
    self.position = {-1,0,0}
    self.target = {0,0,0}
    self.up = {0,0,1}
    self.size = 5
    self.radius = 12
    self.viewMatrix = newMatrix()
    self.projectionMatrix = newMatrix()
    
    self.direction = 0
    self.pitch = 0

    self.desired_position = self.position
    self.speed = 0

    self.pixel_dist_x = 1/(16*WINDOWSCALE)
    self.pixel_dist_y = 1/(13*WINDOWSCALE)

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

function camera:followPoint(x, y)
    local dif_x = x - self.target[1]
    local dif_y = y - self.target[2]
    --print(dif_x, dif_y)
    local dx, dy = 0, 0
    local offset_x, offset_y = 0, 0
    if math.abs(dif_x) >= 0.625 then
        dx = getSign(dif_x) * 0.625
    else
        offset_x = math.floor(dif_x/self.pixel_dist_x) * self.pixel_dist_x * SCALE3D.x
        
    end
    if math.abs(dif_y) >= 0.3125 then
        dy = getSign(dif_y) * 0.3125
    else
        offset_y = math.floor(dif_y/self.pixel_dist_y) * self.pixel_dist_y * (-13)
    end
    self:moveCamera(dx, dy, 0)
    

    return {offset_x, offset_y}
end

return newCamera
