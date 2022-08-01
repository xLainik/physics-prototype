local Sprite = {}
Sprite.__index = Sprite

local function newSprite(x,y,z, spritesheet_path, frame_width, frame_height, border)
    local self = setmetatable({}, Sprite)

    self.frame_width = frame_width
    self.frame_height = frame_height

    self.sheet = love.graphics.newImage(spritesheet_path)
    self.grid = anim8.newGrid(frame_width, frame_height, self.sheet:getWidth(), self.sheet:getHeight(), 0, 0, border or 0)
    
    self.total_frames = self.sheet:getWidth()/self.frame_width
    self.total_angles = self.sheet:getHeight()/self.frame_height

    local uv_x_scale = self.frame_width/self.sheet:getWidth()
    local uv_y_scale = self.frame_height/self.sheet:getHeight()

    local uvs = {}
    uvs[1] = {x = 0*uv_x_scale, y = 0*uv_y_scale}
    uvs[2] = {x = 1*uv_x_scale, y = 0*uv_y_scale}
    uvs[3] = {x = 0*uv_x_scale, y = 1*uv_y_scale}
    uvs[4] = {x = 1*uv_x_scale, y = 1*uv_y_scale}

    local plane = {
        {0.5, 0, -0.5, uvs[4].x, uvs[4].y, 0, -1, 0},
        {-0.5, -0, 0.5, uvs[1].x, uvs[1].y, 0, -1, 0},
        {-0.5, 0, -0.5, uvs[3].x, uvs[3].y, 0, -1, -0},
        {0.5, 0, -0.5, uvs[4].x, uvs[4].y, 0, -1, -0},
        {0.5, -0, 0.5, uvs[2].x, uvs[2].y, 0, -1, 0},
        {-0.5, -0, 0.5, uvs[1].x, uvs[1].y, 0, -1, 0}
    }

    local scale = {self.frame_width/16, 0, self.frame_height/16}
    self.x_offset = 0
    self.z_offset = 0
    self.model = g3d.newModel(plane, self.sheet, {x,y,z}, {-0.927295218,0,0}, scale)

    self.animations = {}
    for row = 1, self.total_angles, 1 do
        self.animations[row] = anim8.newAnimation(self.grid("1-"..tostring(self.sheet:getWidth()/self.frame_width), row), 0.2)
    end

    self.current_anim = 1

    return self
end

function Sprite:changeAnimation(new_anim)
    self.current_anim = new_anim
end

function Sprite:update(dt)
    self.animations[self.current_anim]:update(dt)
    self.current_uvs = {(self.animations[self.current_anim].position-1)/self.total_frames, (self.current_anim-1)/self.total_angles}
    --print(unpack(self.current_uvs))
end

function Sprite:draw(shader, camera, shadow_map)
    self.model:draw(shader, camera, shadow_map, nil, self.current_uvs)
end

return newSprite