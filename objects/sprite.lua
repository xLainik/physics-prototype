local Sprite = {}
Sprite.__index = Sprite

local function newSprite(x,y,z, spritesheet_path, frame_width, frame_height, border)
    local self = setmetatable({}, Sprite)

    self.frame_width = frame_width
    self.frame_height = frame_height

    if type(spritesheet_path) == "string" then
        self.sheet = love.graphics.newImage(spritesheet_path)
    else
        self.sheet =  spritesheet_path
    end
    self.grid = anim8.newGrid(frame_width, frame_height, self.sheet:getWidth(), self.sheet:getHeight(), 0, 0, border or 0)
    
    self.total_frames = self.sheet:getWidth()/self.frame_width
    self.total_angles = self.sheet:getHeight()/self.frame_height

    local scale = {self.frame_width/16, 0, (self.frame_height/16)/math.cos(0.927295218)}
    
    self.z_offset = (self.frame_height/16)/2

    self.imesh = newInstancedMesh(1, "plane", self.sheet, frame_width, frame_height, {scale = scale})
    self.imesh:addInstance(x,y,z, 1,1,1, 0,0)

    self.animations = {}
    self.uvs = {}

    self.flipVertex = {1, 1}
    self.speedMultiplier = 1

    self.current_anim = 0

    return self
end

function Sprite:newAnimation(frame_1, frame_2, row, intervals)
    local index = #self.animations + 1
    self.animations[index] = anim8.newAnimation(self.grid(tostring(frame_1).."-"..tostring(frame_2), row), intervals)
    local lenght = frame_2-frame_1
    self.uvs[index] = {}
    for i = 0, lenght, 1 do
        local u, v = (frame_1-1 + i)/self.total_frames, (row-1)/self.total_angles
        self.uvs[index][i+1] = {u, v}
    end
    return index
end

function Sprite:changeAnimation(index, flip_x, flip_y)
    self:flipAnimation(flip_x, flip_y)
    self:setSpeed(1)
    self.current_anim = index
end

function Sprite:pauseAtStart(index)
    -- Jump to first frame and pause
    self.animations[index]:pauseAtStart()
end

function Sprite:pauseAtEnd(index)
    -- Jump to last frame and pause
    self.animations[index]:pauseAtEnd()
end

function Sprite:flipAnimation(flipH, flipV)
    if flipH ~= nil then
        self.flipVertex = {flipH, flipV}
    end
end

function Sprite:setSpeed(speed)
    -- Negative values reverse the animation
    self.speedMultiplier = speed
end

function Sprite:setTranslation(x, y, z)
    self.imesh:updateInstancePosition(1, x, y, z + self.z_offset)
end

function Sprite:update(dt)
    self.animations[self.current_anim]:update(dt * self.speedMultiplier)
    --local u, v = (self.animations[self.current_anim].position-1)/self.total_frames, (self.current_anim-1)/self.total_angles
    local u, v = unpack(self.uvs[self.current_anim][self.animations[self.current_anim].position])
    --print(self.uvs[self.animations[self.current_anim].position][self.current_anim])
    self.imesh:updateInstanceUVs(1, u,v)
    --print(unpack(self.current_uvs))
end

function Sprite:draw(shader, camera, shadow_map)
    self.imesh:draw(shader, camera, shadow_map, self.flipVertex)
end

return newSprite