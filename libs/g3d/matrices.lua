-- written by groverbuger for g3d
-- september 2021
-- MIT license

local vectors = require(g3d.path .. "/vectors")
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize

----------------------------------------------------------------------------------------------------
-- matrix class
----------------------------------------------------------------------------------------------------
-- matrices are 16 numbers in table, representing a 4x4 matrix like so:
--
-- |  1   2   3   4  |
-- |                 |
-- |  5   6   7   8  |
-- |                 |
-- |  9   10  11  12 |
-- |                 |
-- |  13  14  15  16 |

local matrix = {}
matrix.__index = matrix

local function newMatrix()
    local self = setmetatable({}, matrix)

    -- initialize a matrix as the identity matrix
    self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
    self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
    self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1

    return self
end

-- automatically converts a matrix to a string
-- for printing to console and debugging
function matrix:__tostring()
    return ("%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f"):format(unpack(self))
end

----------------------------------------------------------------------------------------------------
-- transformation, projection, and rotation matrices
----------------------------------------------------------------------------------------------------
-- the three most important matrices for 3d graphics
-- these three matrices are all you need to write a simple 3d shader

-- returns a transformation matrix
-- translation, rotation, and scale are all 3d vectors
function matrix:setTransformationMatrix(translation, rotation, scale)
    -- translations
    self[4]  = translation[1]
    self[8]  = translation[2]
    self[12] = translation[3]

    -- rotations
    if #rotation == 3 then
        -- use 3D rotation vector as euler angles
        -- source: https://en.wikipedia.org/wiki/Rotation_matrix
        local ca, cb, cc = math.cos(rotation[3]), math.cos(rotation[2]), math.cos(rotation[1])
        local sa, sb, sc = math.sin(rotation[3]), math.sin(rotation[2]), math.sin(rotation[1])
        self[1], self[2],  self[3]  = ca*cb, ca*sb*sc - sa*cc, ca*sb*cc + sa*sc
        self[5], self[6],  self[7]  = sa*cb, sa*sb*sc + ca*cc, sa*sb*cc - ca*sc
        self[9], self[10], self[11] = -sb, cb*sc, cb*cc
    else
        -- use 4D rotation vector as a quaternion
        local qx, qy, qz, qw = rotation[1], rotation[2], rotation[3], rotation[4]
        self[1], self[2],  self[3]  = 1 - 2*qy^2 - 2*qz^2, 2*qx*qy - 2*qz*qw,   2*qx*qz + 2*qy*qw
        self[5], self[6],  self[7]  = 2*qx*qy + 2*qz*qw,   1 - 2*qx^2 - 2*qz^2, 2*qy*qz - 2*qx*qw
        self[9], self[10], self[11] = 2*qx*qz - 2*qy*qw,   2*qy*qz + 2*qx*qw,   1 - 2*qx^2 - 2*qy^2
    end

    -- scale
    local sx, sy, sz = scale[1], scale[2], scale[3]
    self[1], self[2],  self[3]  = self[1] * sx, self[2]  * sy, self[3]  * sz
    self[5], self[6],  self[7]  = self[5] * sx, self[6]  * sy, self[7]  * sz
    self[9], self[10], self[11] = self[9] * sx, self[10] * sy, self[11] * sz

    -- fourth row is not used, just set it to the fourth row of the identity matrix
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

-- returns a perspective projection matrix
-- (things farther away appear smaller)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrix:setProjectionMatrix(fov, near, far, aspectRatio)
    local top = near * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    self[1],  self[2],  self[3],  self[4]  = 2*near/(right-left), 0, (right+left)/(right-left), 0
    self[5],  self[6],  self[7],  self[8]  = 0, 2*near/(top-bottom), (top+bottom)/(top-bottom), 0
    self[9],  self[10], self[11], self[12] = 0, 0, -1*(far+near)/(far-near), -2*far*near/(far-near)
    self[13], self[14], self[15], self[16] = 0, 0, -1, 0
end

-- returns an orthographic projection matrix
-- (things farther away are the same size as things closer)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrix:setOrthographicMatrix(fov, size, near, far, aspectRatio)
    local top = size * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    self[1],  self[2],  self[3],  self[4]  = 2/(right-left), 0, 0, -1*(right+left)/(right-left)
    self[5],  self[6],  self[7],  self[8]  = 0, 2/(top-bottom), 0, -1*(top+bottom)/(top-bottom)
    self[9],  self[10], self[11], self[12] = 0, 0, -2/(far-near), -(far+near)/(far-near)
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

-- returns a view matrix
-- eye, target, and up are all 3d vectors
function matrix:setViewMatrix(eye, target, up)
    local z1, z2, z3 = vectorNormalize(eye[1] - target[1], eye[2] - target[2], eye[3] - target[3])
    local x1, x2, x3 = vectorNormalize(vectorCrossProduct(up[1], up[2], up[3], z1, z2, z3))
    local y1, y2, y3 = vectorCrossProduct(z1, z2, z3, x1, x2, x3)

    self[1],  self[2],  self[3],  self[4]  = x1, x2, x3, -1*vectorDotProduct(x1, x2, x3, eye[1], eye[2], eye[3])
    self[5],  self[6],  self[7],  self[8]  = y1, y2, y3, -1*vectorDotProduct(y1, y2, y3, eye[1], eye[2], eye[3])
    self[9],  self[10], self[11], self[12] = z1, z2, z3, -1*vectorDotProduct(z1, z2, z3, eye[1], eye[2], eye[3])
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end


--- Cirno's perfect math library: Invert a matrix.
-- @tparam mat4 outmat Matrix to store the result
-- @tparam mat4 mat Matrix to invert
-- @treturn mat4 out
function invertMatrix(mat,outmat)
    local out
    if outmat then
        out = outmat
    else
        out = newMatrix()
    end
    out[1]  =  mat[6] * mat[11] * mat[16] - mat[6] * mat[12] * mat[15] - mat[10] * mat[7] * mat[16] + mat[10] * mat[8] * mat[15] + mat[14] * mat[7] * mat[12] - mat[14] * mat[8] * mat[11]
    out[2]  = -mat[2] * mat[11] * mat[16] + mat[2] * mat[12] * mat[15] + mat[10] * mat[3] * mat[16] - mat[10] * mat[4] * mat[15] - mat[14] * mat[3] * mat[12] + mat[14] * mat[4] * mat[11]
    out[3]  =  mat[2] * mat[7]  * mat[16] - mat[2] * mat[8]  * mat[15] - mat[6]  * mat[3] * mat[16] + mat[6]  * mat[4] * mat[15] + mat[14] * mat[3] * mat[8]  - mat[14] * mat[4] * mat[7]
    out[4]  = -mat[2] * mat[7]  * mat[12] + mat[2] * mat[8]  * mat[11] + mat[6]  * mat[3] * mat[12] - mat[6]  * mat[4] * mat[11] - mat[10] * mat[3] * mat[8]  + mat[10] * mat[4] * mat[7]
    out[5]  = -mat[5] * mat[11] * mat[16] + mat[5] * mat[12] * mat[15] + mat[9]  * mat[7] * mat[16] - mat[9]  * mat[8] * mat[15] - mat[13] * mat[7] * mat[12] + mat[13] * mat[8] * mat[11]
    out[6]  =  mat[1] * mat[11] * mat[16] - mat[1] * mat[12] * mat[15] - mat[9]  * mat[3] * mat[16] + mat[9]  * mat[4] * mat[15] + mat[13] * mat[3] * mat[12] - mat[13] * mat[4] * mat[11]
    out[7]  = -mat[1] * mat[7]  * mat[16] + mat[1] * mat[8]  * mat[15] + mat[5]  * mat[3] * mat[16] - mat[5]  * mat[4] * mat[15] - mat[13] * mat[3] * mat[8]  + mat[13] * mat[4] * mat[7]
    out[8]  =  mat[1] * mat[7]  * mat[12] - mat[1] * mat[8]  * mat[11] - mat[5]  * mat[3] * mat[12] + mat[5]  * mat[4] * mat[11] + mat[9]  * mat[3] * mat[8]  - mat[9]  * mat[4] * mat[7]
    out[9]  =  mat[5] * mat[10] * mat[16] - mat[5] * mat[12] * mat[14] - mat[9]  * mat[6] * mat[16] + mat[9]  * mat[8] * mat[14] + mat[13] * mat[6] * mat[12] - mat[13] * mat[8] * mat[10]
    out[10] = -mat[1] * mat[10] * mat[16] + mat[1] * mat[12] * mat[14] + mat[9]  * mat[2] * mat[16] - mat[9]  * mat[4] * mat[14] - mat[13] * mat[2] * mat[12] + mat[13] * mat[4] * mat[10]
    out[11] =  mat[1] * mat[6]  * mat[16] - mat[1] * mat[8]  * mat[14] - mat[5]  * mat[2] * mat[16] + mat[5]  * mat[4] * mat[14] + mat[13] * mat[2] * mat[8]  - mat[13] * mat[4] * mat[6]
    out[12] = -mat[1] * mat[6]  * mat[12] + mat[1] * mat[8]  * mat[10] + mat[5]  * mat[2] * mat[12] - mat[5]  * mat[4] * mat[10] - mat[9]  * mat[2] * mat[8]  + mat[9]  * mat[4] * mat[6]
    out[13] = -mat[5] * mat[10] * mat[15] + mat[5] * mat[11] * mat[14] + mat[9]  * mat[6] * mat[15] - mat[9]  * mat[7] * mat[14] - mat[13] * mat[6] * mat[11] + mat[13] * mat[7] * mat[10]
    out[14] =  mat[1] * mat[10] * mat[15] - mat[1] * mat[11] * mat[14] - mat[9]  * mat[2] * mat[15] + mat[9]  * mat[3] * mat[14] + mat[13] * mat[2] * mat[11] - mat[13] * mat[3] * mat[10]
    out[15] = -mat[1] * mat[6]  * mat[15] + mat[1] * mat[7]  * mat[14] + mat[5]  * mat[2] * mat[15] - mat[5]  * mat[3] * mat[14] - mat[13] * mat[2] * mat[7]  + mat[13] * mat[3] * mat[6]
    out[16] =  mat[1] * mat[6]  * mat[11] - mat[1] * mat[7]  * mat[10] - mat[5]  * mat[2] * mat[11] + mat[5]  * mat[3] * mat[10] + mat[9]  * mat[2] * mat[7]  - mat[9]  * mat[3] * mat[6]

    local det = mat[1] * out[1] + mat[2] * out[5] + mat[3] * out[9] + mat[4] * out[13]

    if det == 0 then return mat end

    det = 1 / det

    for i = 1, 16 do
        out[i] = out[i] * det
    end

    return out
end

--- Cirno's perfect math library: Transpose a matrix.
-- @tparam mat4 outmat Matrix to store the result
-- @tparam mat4 mat Matrix to transpose
-- @treturn mat4 out
function transposeMatrix(mat,outmat)
    local out
    if outmat then
        out = outmat
    else
        out = newMatrix()
    end
   out[1]  = mat[1]
   out[2]  = mat[5]
   out[3]  = mat[9]
   out[4]  = mat[13]
   out[5]  = mat[2]
   out[6]  = mat[6]
   out[7]  = mat[10]
   out[8]  = mat[14]
   out[9]  = mat[3]
   out[10] = mat[7]
   out[11] = mat[11]
   out[12] = mat[15]
   out[13] = mat[4]
   out[14] = mat[8]
   out[15] = mat[12]
   out[16] = mat[16]

    return out
end

--- Cirno's perfect math library: Multiply N matrices.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 or {mat4, ...} left hand operand(s)
-- @tparam mat4 right hand operand if a is not table
-- @treturn mat4 out multiplied matrix result
function multiplyMatrices(b, a, outmat)
    local out
    if outmat then
        out = outmat
    else
        out = newMatrix()
    end

    --mat4 out = mat4 b * mat4 a
    
    out[1]  = b[1]  * a[1] + b[2]  * a[5] + b[3]  * a[9]  + b[4]  * a[13]
    out[2]  = b[1]  * a[2] + b[2]  * a[6] + b[3]  * a[10] + b[4]  * a[14]
    out[3]  = b[1]  * a[3] + b[2]  * a[7] + b[3]  * a[11] + b[4]  * a[15]
    out[4]  = b[1]  * a[4] + b[2]  * a[8] + b[3]  * a[12] + b[4]  * a[16]
    out[5]  = b[5]  * a[1] + b[6]  * a[5] + b[7]  * a[9]  + b[8]  * a[13]
    out[6]  = b[5]  * a[2] + b[6]  * a[6] + b[7]  * a[10] + b[8]  * a[14]
    out[7]  = b[5]  * a[3] + b[6]  * a[7] + b[7]  * a[11] + b[8]  * a[15]
    out[8]  = b[5]  * a[4] + b[6]  * a[8] + b[7]  * a[12] + b[8]  * a[16]
    out[9]  = b[9]  * a[1] + b[10] * a[5] + b[11] * a[9]  + b[12] * a[13]
    out[10] = b[9]  * a[2] + b[10] * a[6] + b[11] * a[10] + b[12] * a[14]
    out[11] = b[9]  * a[3] + b[10] * a[7] + b[11] * a[11] + b[12] * a[15]
    out[12] = b[9]  * a[4] + b[10] * a[8] + b[11] * a[12] + b[12] * a[16]
    out[13] = b[13] * a[1] + b[14] * a[5] + b[15] * a[9]  + b[16] * a[13]
    out[14] = b[13] * a[2] + b[14] * a[6] + b[15] * a[10] + b[16] * a[14]
    out[15] = b[13] * a[3] + b[14] * a[7] + b[15] * a[11] + b[16] * a[15]
    out[16] = b[13] * a[4] + b[14] * a[8] + b[15] * a[12] + b[16] * a[16]

    for i = 1, 16 do
        out[i] = out[i] * 1.0
    end

    return out
end

return newMatrix
