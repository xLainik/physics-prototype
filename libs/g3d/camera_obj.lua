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
    self.radius = 3
    self.angle_x = math.pi*1.5
    self.angle_z = math.pi*0.25
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
    self.projectionMatrix:setOrthographicMatrix(self.fov, size or 5, self.nearClip, self.farClip, self.aspectRatio)
end

function camera:thirdPersonLook(dx, dy, player_x, player_y, player_z)

    local sensitivity = 1/400

    self.angle_x = self.angle_x + dx*sensitivity
    self.angle_z = math.max(math.min(self.angle_z + dy*sensitivity, math.pi*0.5), math.pi*-0.5)

    if love.keyboard.isDown("t") then
        print(self.angle_z/math.pi*180)
    end

    self.position[1] = player_x + math.cos(self.angle_x)*math.cos(self.angle_z)*self.radius
    self.position[2] = player_y + math.sin(self.angle_x)*math.cos(self.angle_z)*self.radius
    self.position[3] = player_z + math.sin(self.angle_z)*self.radius

    --Equivalent code might be:
    --camera.lookAt(camera.position[1],camera.position[2],camera.position[3], player_x, player_y, player_z)

    self.target[1] = player_x
    self.target[2] = player_y
    self.target[3] = player_z

    self.direction = math.pi/2 - self.angle_x
    self.pitch = self.angle_z

    self:updateViewMatrix()

    --But changing the parameters directly is faster
end

function camera:thirdPersonMovement(dt, player_x, player_y, player_z)

    --print("camera"..camera.position[1]..", "..camera.position[2])

    if love.keyboard.isDown("left") then
        self.angle_x = self.angle_x - math.pi/2*dt
    elseif love.keyboard.isDown("right") then
        self.angle_x = self.angle_x + math.pi/2*dt
    end

    if love.keyboard.isDown("down") then
        self.angle_z = math.max(math.min(self.angle_z - math.pi/2*dt, math.pi*0.5), math.pi*-0.5)
    elseif love.keyboard.isDown("up") then
        self.angle_z = math.max(math.min(self.angle_z + math.pi/2*dt, math.pi*0.5), math.pi*-0.5)
    end

    self.position[1] = player_x + math.cos(self.angle_x)*math.cos(self.angle_z)*self.radius
    self.position[2] = player_y + math.sin(self.angle_x)*math.cos(self.angle_z)*self.radius
    self.position[3] = player_z + math.sin(self.angle_z)*self.radius

    --Equivalent code might be:
    --camera.lookAt(camera.position[1],camera.position[2],camera.position[3], player_x, player_y, player_z)

    self.target[1] = player_x + 0.3 --add the player.w/2
    self.target[2] = player_y + 0.3 --add the player.h/2
    self.target[3] = player_z + 0.25 --add the player.d/2

    self.direction = math.pi/2 - self.angle_x
    self.pitch = self.angle_z

    self:updateViewMatrix()

    --But changing the parameters directly seems faster
end

return newCamera
