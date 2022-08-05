local InstancedMesh = {}
InstancedMesh.__index = InstancedMesh

local ffi = require("ffi")

local function newInstancedMesh(max_instances, verts, texture, tile_width, tile_height, options)
    local self = setmetatable({}, InstancedMesh)

    self.tile_width = tile_width
    self.tile_height = tile_height

    self.max_instances = max_instances

    if type(texture) == "string" then
        self.texture = love.graphics.newImage(texture)
    else
        self.texture = texture
    end

    local uv_x_scale = self.tile_width/self.texture:getWidth()
    local uv_y_scale = self.tile_height/self.texture:getHeight()
    local uvs = {}

    if type(verts) == "string" then
        if verts == "plane" then
            uvs[1] = {x = 0*uv_x_scale, y = 0*uv_y_scale}
            uvs[2] = {x = 1*uv_x_scale, y = 0*uv_y_scale}
            uvs[3] = {x = 0*uv_x_scale, y = 1*uv_y_scale}
            uvs[4] = {x = 1*uv_x_scale, y = 1*uv_y_scale}

            self.verts = {
                {0.5, 0, -0.5, uvs[4].x, uvs[4].y, 0, -1, 0},
                {-0.5, -0, 0.5, uvs[1].x, uvs[1].y, 0, -1, 0},
                {-0.5, 0, -0.5, uvs[3].x, uvs[3].y, 0, -1, 0},
                {0.5, 0, -0.5, uvs[4].x, uvs[4].y, 0, -1, 0},
                {0.5, -0, 0.5, uvs[2].x, uvs[2].y, 0, -1, 0},
                {-0.5, -0, 0.5, uvs[1].x, uvs[1].y, 0, -1, 0}
            }
        elseif verts == "cube" then
            uvs[1] = {x = 0*uv_x_scale, y = 0*uv_y_scale}
            uvs[2] = {x = 1*uv_x_scale, y = 0*uv_y_scale}
            uvs[3] = {x = 0*uv_x_scale, y = 13/22*uv_y_scale}
            uvs[4] = {x = 1*uv_x_scale, y = 13/22*uv_y_scale}
            uvs[5] = {x = 0*uv_x_scale, y = 1*uv_y_scale}
            uvs[6] = {x = 1*uv_x_scale, y = 1*uv_y_scale}

            self.verts = {
                {0.5, -0.5, -0.5, uvs[6].x, uvs[6].y, 0, -1, 0},
                {0.5, -0.5, 0.5, uvs[4].x, uvs[4].y, 0, -1, 0},
                {-0.5, -0.5, 0.5, uvs[3].x, uvs[3].y, 0, -1, 0},
                {0.5, -0.5, 0.5, uvs[4].x, uvs[4].y, 0, 0, 1},
                {0.5, 0.5, 0.5, uvs[2].x, uvs[2].y, 0, 0, 1},
                {-0.5, 0.5, 0.5, uvs[1].x, uvs[1].y, 0, 0, 1},
                {0.5, -0.5, -0.5, uvs[6].x, uvs[6].y, 0, -1, 0},
                {-0.5, -0.5, 0.5, uvs[3].x, uvs[3].y, 0, -1, 0},
                {-0.5, -0.5, -0.5, uvs[5].x, uvs[5].y, 0, -1, 0},
                {0.5, -0.5, 0.5, uvs[4].x, uvs[4].y, 0, 0, 1},
                {-0.5, 0.5, 0.5, uvs[1].x, uvs[1].y, 0, 0, 1},
                {-0.5, -0.5, 0.5, uvs[3].x, uvs[3].y, 0, 0, 1},
            }
        end
    end

    local scale = nil
    local rotation = nil
    local pos_usage = nil
    local uvs_usage = nil

    if options ~= nil then
        scale = options["scale"]
        rotation = options["rotation"]
        pos_usage = options["pos usage"]
        uvs_usage = options["uvs usage"]
    end

    self.model = g3d.newModel(self.verts, self.texture, {0,0,0}, rotation or {0,0,0}, scale or {1,1,1})

    self.instanced_positions = {}
    self.instanced_uvs = {}

    self.instanced_count = 0

    self.pointer_last = 0

    for index = 1, max_instances, 1 do
        self.instanced_positions[index] = {-100, -100, -100}
        self.instanced_uvs[index] = {-1, -1}
    end

    self.instancemesh_pos = love.graphics.newMesh({{"InstancePosition", "float", 3}}, self.instanced_positions, nil, pos_usage or "dynamic")
    self.model.mesh:attachAttribute("InstancePosition", self.instancemesh_pos, "perinstance")

    self.instancemesh_uvs = love.graphics.newMesh({{"InstanceUVs", "float", 2}}, self.instanced_uvs, nil, uvs_usage or "dynamic")
    self.model.mesh:attachAttribute("InstanceUVs", self.instancemesh_uvs, "perinstance")

    return self
end

-- Adds a single instance (both position and UVs)
-- @param position = {x, y, z}
-- @param uvs = {u, v}
-- Returns its index
function InstancedMesh:addInstance(x,y,z, u,v)

    if self.instanced_count == self.max_instances then
        error(("Instance max count of %s exceeded."):format(self.max_instances))
    end

    self.instanced_count = self.instanced_count + 1

    local last = self.pointer_last + 1
    self.pointer_last = last

    self.instanced_positions[self.pointer_last] = {x,y,z}
    self.instanced_uvs[self.pointer_last] = {u,v}

    self.instancemesh_pos:setVertexAttribute(self.pointer_last, 1, x,y,z)
    self.instancemesh_uvs:setVertexAttribute(self.pointer_last, 1, u,v)

    return self.pointer_last
end

-- Removes a single instance (both position and UVs)
function InstancedMesh:removeInstance(index)
    self.instanced_count = self.instanced_count - 1

    local last = self.pointer_last - 1
    self.pointer_last = last

    local pos = self.instanced_positions[self.pointer_last+1]
    local uvs = self.instanced_uvs[self.pointer_last+1]

    if index ~= self.pointer_last+1 then
        -- We need to swap last instance with the empty slot
        --print("swapping: ", index, "with", self.pointer_last+1)
        self.instanced_positions[index] = pos
        self.instanced_uvs[index] = uvs
        self.instanced_positions[self.pointer_last+1] = {-100, -100, -100}
        self.instanced_uvs[self.pointer_last+1] = {-1, -1}
        self:updateInstance(index, pos[1], pos[2], pos[3], uvs[1], uvs[2])
    end
    self:updateInstance(self.pointer_last+1, -100,-100,-100, -1,-1)
    return self.pointer_last + 1
end

-- Updates the Position and UV coords of a single instance
function InstancedMesh:updateInstance(index, x,y,z, u,v)
    self.instancemesh_pos:setVertexAttribute( index, 1, x,y,z)
    self.instancemesh_uvs:setVertexAttribute( index, 1, u,v)
end

-- Updates the Position coords of a single instance
function InstancedMesh:updateInstancePosition(index, x,y,z)
    --print(self.instancemesh_pos:isAttributeEnabled("InstancePosition"))
    --local temp1, temp2, temp3 = self.instancemesh_pos:getVertexAttribute(index, 1)
    self.instancemesh_pos:setVertexAttribute( index, 1, x,y,z)
    --print(self.instancemesh_pos:getVertexAttribute(index, 1))
end

-- Updates the UV coords of a single instance
function InstancedMesh:updateInstanceUVs(index, u,v)
    --print(self.instancemesh_uvs:isAttributeEnabled("InstanceUVs"))
    local temp1, temp2 = self.instancemesh_uvs:getVertexAttribute(index, 1)
    self.instancemesh_uvs:setVertexAttribute( index, 1, u,v)
end

function InstancedMesh:draw(shader, camera, shadow_map)
    self.model:draw(shader, camera, shadow_map, self.instanced_count)
end

return newInstancedMesh