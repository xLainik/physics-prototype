local InstancedMesh = {}
InstancedMesh.__index = InstancedMesh

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
    else
        self.verts = verts
    end

    local mat_usage = "dynamic"
    local uvs_usage = "dynamic"

    if options ~= nil then
        mat_usage = options["mat usage"]
        uvs_usage = options["uvs usage"]
    end

    self.model = g3d.newModel(self.verts, self.texture, {0,0,0}, {0,0,0}, {1,1,1})

    self.instanced_uvs = {}
    self.instanced_mat1 = {}
    self.instanced_mat2 = {}
    self.instanced_mat3 = {}
    self.instanced_mat4 = {}
    self.instanced_color = {}

    self.instanced_count = 0

    self.pointer_last = 0

    for index = 1, max_instances, 1 do
        self.instanced_uvs[index] = {-1, -1}
        self.instanced_mat1[index] = {1, 0, 0, 0}
        self.instanced_mat2[index] = {0, 1, 0, 0}
        self.instanced_mat3[index] = {0, 0, 1, 0}
        self.instanced_mat4[index] = {0, 0, 0, 1}
        self.instanced_color[index] = {1, 1, 1, 0}
    end

    self.instancemesh_uvs = love.graphics.newMesh({{"InstanceUVs", "float", 2}}, self.instanced_uvs, nil, uvs_usage or "dynamic")
    self.model.mesh:attachAttribute("InstanceUVs", self.instancemesh_uvs, "perinstance")

    self.instancemesh_mat1 = love.graphics.newMesh({{"ModelMat1", "float", 4}}, self.instanced_mat1, nil, mat_usage or "dynamic")
    self.model.mesh:attachAttribute("ModelMat1", self.instancemesh_mat1, "perinstance")

    self.instancemesh_mat2 = love.graphics.newMesh({{"ModelMat2", "float", 4}}, self.instanced_mat2, nil, mat_usage or "dynamic")
    self.model.mesh:attachAttribute("ModelMat2", self.instancemesh_mat2, "perinstance")

    self.instancemesh_mat3 = love.graphics.newMesh({{"ModelMat3", "float", 4}}, self.instanced_mat3, nil, mat_usage or "dynamic")
    self.model.mesh:attachAttribute("ModelMat3", self.instancemesh_mat3, "perinstance")

    self.instancemesh_mat4 = love.graphics.newMesh({{"ModelMat4", "float", 4}}, self.instanced_mat4, nil, mat_usage or "dynamic")
    self.model.mesh:attachAttribute("ModelMat4", self.instancemesh_mat4, "perinstance")

    self.instancemesh_color = love.graphics.newMesh({{"OverlayColor", "float", 4}}, self.instanced_color, nil, "dynamic")
    self.model.mesh:attachAttribute("OverlayColor", self.instancemesh_color, "perinstance")

    return self
end

-- Adds a single instance (both model matrix and UVs)
-- @param matrix = g3d.Matrix
-- @param uvs = {u, v}
-- @param colorOverlay = {r, g, b, a}
-- Returns its index
function InstancedMesh:addInstance(matrix, u,v, r,g,b,a)

    if self.instanced_count == self.max_instances then
        error(("Instance max count of %s exceeded."):format(self.max_instances))
    end

    self.instanced_count = self.instanced_count + 1

    local last = self.pointer_last + 1
    self.pointer_last = last

    self.instanced_uvs[self.pointer_last] = {u,v}

    local row1, row2, row3, row4 = matrix:getMatrixRows()
    self.instanced_mat1[self.pointer_last] = row1
    self.instanced_mat2[self.pointer_last] = row2
    self.instanced_mat3[self.pointer_last] = row3
    self.instanced_mat4[self.pointer_last] = row4

    self.instancemesh_uvs:setVertexAttribute(self.pointer_last, 1, u,v)
    self.instancemesh_mat1:setVertexAttribute(self.pointer_last, 1, row1[1], row1[2], row1[3], row1[4])
    self.instancemesh_mat2:setVertexAttribute(self.pointer_last, 1, row2[1], row2[2], row2[3], row2[4])
    self.instancemesh_mat3:setVertexAttribute(self.pointer_last, 1, row3[1], row3[2], row3[3], row3[4])
    self.instancemesh_mat4:setVertexAttribute(self.pointer_last, 1, row4[1], row4[2], row4[3], row4[4])

    self.instancemesh_color:setVertexAttribute(self.pointer_last, 1, r,g,b,a)

    return self.pointer_last
end

-- Removes a single instance (both position and UVs)
function InstancedMesh:removeInstance(index)
    self.instanced_count = self.instanced_count - 1

    local last = self.pointer_last - 1
    self.pointer_last = last

    local uvs = self.instanced_uvs[self.pointer_last+1]
    local row1 = self.instanced_mat1[self.pointer_last+1]
    local row2 = self.instanced_mat2[self.pointer_last+1]
    local row3 = self.instanced_mat3[self.pointer_last+1]
    local row4 = self.instanced_mat4[self.pointer_last+1]
    local color = self.instanced_color[self.pointer_last+1]

    if index ~= self.pointer_last+1 then
        -- We need to swap last instance with the empty slot
        --print("swapping: ", index, "with", self.pointer_last+1)

        self.instanced_uvs[index] = uvs
        self.instanced_mat1[index] = row1
        self.instanced_mat2[index] = row2
        self.instanced_mat3[index] = row3
        self.instanced_mat4[index] = row4

        self.instanced_uvs[self.pointer_last+1] = {-1, -1}
        self.instanced_mat1[self.pointer_last+1] = {1, 0, 0, 0}
        self.instanced_mat2[self.pointer_last+1] = {0, 1, 0, 0}
        self.instanced_mat3[self.pointer_last+1] = {0, 0, 1, 0}
        self.instanced_mat4[self.pointer_last+1] = {0, 0, 0, 1}

        self.instanced_color[self.pointer_last+1] = {1, 1, 1, 0}

        self:updateInstance(index, row1, row2, row3, row4, uvs[1], uvs[2], color[1], color[2], color[3], color[4])
    end
    self:updateInstance(self.pointer_last+1, row1, row2, row3, row4, -1,-1, color[1], color[2], color[3], color[4])
    return self.pointer_last + 1
end

-- Updates the both model Matrix and UVs of a single instance
function InstancedMesh:updateInstance(index, row1, row2, row3, row4, u,v, r, g, b, a)
    self.instanced_uvs[index] = {u,v}
    self.instancemesh_uvs:setVertexAttribute( index, 1, u,v)

    self.instanced_mat1[index] = row1
    self.instanced_mat2[index] = row2
    self.instanced_mat3[index] = row3
    self.instanced_mat4[index] = row4
    self.instancemesh_mat1:setVertexAttribute(index, 1, row1[1], row1[2], row1[3], row1[4])
    self.instancemesh_mat2:setVertexAttribute(index, 1, row2[1], row2[2], row2[3], row2[4])
    self.instancemesh_mat3:setVertexAttribute(index, 1, row3[1], row3[2], row3[3], row3[4])
    self.instancemesh_mat4:setVertexAttribute(index, 1, row4[1], row4[2], row4[3], row4[4])

    self.instanced_color[index] = {r, g, b, a}
    self.instancemesh_color:setVertexAttribute(index, 1, r, g, b, a)
end

-- Updates the model Matrix of a single instance
function InstancedMesh:updateInstanceMAT(index, row1, row2, row3, row4)
    self.instanced_mat1[index] = row1
    self.instanced_mat2[index] = row2
    self.instanced_mat3[index] = row3
    self.instanced_mat4[index] = row4
    self.instancemesh_mat1:setVertexAttribute(index, 1, row1[1], row1[2], row1[3], row1[4])
    self.instancemesh_mat2:setVertexAttribute(index, 1, row2[1], row2[2], row2[3], row2[4])
    self.instancemesh_mat3:setVertexAttribute(index, 1, row3[1], row3[2], row3[3], row3[4])
    self.instancemesh_mat4:setVertexAttribute(index, 1, row4[1], row4[2], row4[3], row4[4])
end

-- Updates the UV coords of a single instance
function InstancedMesh:updateInstanceUVs(index, u,v)
    --local temp1, temp2 = self.instancemesh_uvs:getVertexAttribute(index, 1)
    self.instanced_uvs[index] = {u,v}
    self.instancemesh_uvs:setVertexAttribute(index, 1, u,v)
end

-- Updates the Color Overlay of a single instance
function InstancedMesh:updateInstanceColor(index, r, g, b, a)
    --local temp1, temp2 = self.instancemesh_color:getVertexAttribute(index, 1)
    self.instanced_color[index] = {r, g, b, a}
    self.instancemesh_color:setVertexAttribute(index, 1, r, g, b, a)
end

function InstancedMesh:draw(shader, camera, shadow_map, flip)
    self.model:draw(shader, camera, shadow_map, self.instanced_count, flip)
end

return newInstancedMesh