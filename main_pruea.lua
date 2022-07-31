-- A simple small triangle with the default position, texture coordinate, and color vertex attributes.
local vertices_ori = {
	{0, 0,  0,0, 1.0,0.2,0.2,1.0},
	{16,0,  0,0, 0.2,1.0,0.2,1.0},
	{16,16, 0,0, 0.2,0.2,1.0,1.0},
}

local vertices = {
	{0,0,0,  0,0, 0,1,0},
	{1,0,0,  0,0, 0,1,0},
	{1,1,0, 0,0, 0,1,0},
}

local uvs = {}
uvs[1] = {x = 0, y = 0}
uvs[2] = {x = 1, y = 0}
uvs[3] = {x = 0, y = 13/22}
uvs[4] = {x = 1, y = 13/22}
uvs[5] = {x = 0, y = 1}
uvs[6] = {x = 1, y = 1}

local top_down_cube = {
	{0.5, -0.5, -0.5, uvs[6].x, uvs[6].y, 0, -1, 0},
	{0.5, -0.5, 0.5, uvs[4].x, uvs[4].y, 0, -1, 0},
	{-0.5, -0.5, 0.5, uvs[3].x, uvs[3].y, 0, -1, 0},
	{0.5, -0.5, 0.5, uvs[4].x, uvs[4].y, -0, 0, 1},
	{0.5, 0.5, 0.5, uvs[2].x, uvs[2].y, -0, 0, 1},
	{-0.5, 0.5, 0.5, uvs[1].x, uvs[1].y, -0, 0, 1},
	{0.5, -0.5, -0.5, uvs[6].x, uvs[6].y, 0, -1, 0},
	{-0.5, -0.5, 0.5, uvs[3].x, uvs[3].y, 0, -1, 0},
	{-0.5, -0.5, -0.5, uvs[5].x, uvs[5].y, 0, -1, 0},
	{0.5, -0.5, 0.5, uvs[4].x, uvs[4].y, -0, 0, 1},
	{-0.5, 0.5, 0.5, uvs[1].x, uvs[1].y, -0, 0, 1},
	{-0.5, -0.5, 0.5, uvs[3].x, uvs[3].y, -0, 0, 1},
}


local floor_1 = {
	1, 1, 1, 1,
	1, 1, 1, 1,
	1, 1, 1, 1,
	
}

local map = {floor_1, floor_2}

local mapW, mapH = 4, 3

local tileW, tileH = 1, 1

--local mesh = love.graphics.newMesh(vertices, "triangles", "static")

g3d = require("libs/g3d")

DISTMAINCAM = 6
main_camera = g3d.newCamera(love.graphics.getWidth()/love.graphics.getHeight())
main_camera:lookAt( 0 * DISTMAINCAM, -3 * DISTMAINCAM, 4 * DISTMAINCAM, 0,0,0)
main_camera:updateOrthographicMatrix(6.5)

current_camera = main_camera

local object = g3d.loadObj("assets/3d/unit_cube_front_top.obj", false, true)

for i, n in ipairs(object) do
	local vert = {} 
	for j, m in ipairs(n) do
		table.insert(vert, m)
	end
	print("{"..table.concat(vert, ", ").."},")
end

object = top_down_cube

local model = g3d.newModel(object, "assets/3d/front_top_texture_2.png", {0,0,0})


-- Unique positions for each instance that will be rendered.
local instancepositions = {}
for i, floor in ipairs(map) do
	for y=0, mapH, 1 do
		for x = 0, mapW, 1 do
			local value = floor[y * 4 + (x + 1)]
			if value ~= 0 then
				local pos = {x * tileW, y * tileH, i}
				table.insert(instancepositions, pos)
			end
		end
	end
end

-- Create a mesh containing the per-instance position data.
-- It won't be drawn directly, but it will be referenced by the triangle's mesh.
local instancemesh = love.graphics.newMesh({{"InstancePosition", "float", 3}}, instancepositions, nil, "static")

-- When the triangle's mesh is rendered, the vertex shader will pull in a different
-- value of the InstancePosition attribute for each instance, instead of for each vertex.
model.mesh:attachAttribute("InstancePosition", instancemesh, "perinstance")



local shader = love.graphics.newShader[[

// written by groverbuger for g3d
// september 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute vec3 VertexNormal;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;

attribute vec3 InstancePosition;

#ifdef VERTEX
	vec4 position(mat4 transformProjection, vec4 vertexPosition) {
	    
	    vertexPosition.xyz += InstancePosition;
	    worldPosition = modelMatrix * vertexPosition;
	    viewPosition = viewMatrix * worldPosition;
	    screenPosition = projectionMatrix * viewPosition;

	    vertexNormal = VertexNormal;
	    vertexColor = VertexColor;

	    if (isCanvasEnabled) {
	        screenPosition.y *= -1.0;
	    }

	    return screenPosition;
}
#endif


]]

function love.update(dt)
	local dx, dy = 0, 0

	if love.keyboard.isDown("w") then
		dy = 500
	elseif love.keyboard.isDown("s") then
		dy = -500
	end
	if love.keyboard.isDown("d") then
		dx = 500
	elseif love.keyboard.isDown("a") then
		dx = -500
	end

	current_camera:thirdPersonLook(dx*dt,dy*dt,mapW/2, mapH/2,0)
end





function love.draw()

	love.graphics.setDepthMode("lequal", true)
	love.graphics.clear(0.05, 0.0, 0.05)
	love.graphics.setMeshCullMode("none")

	model:draw(shader, main_camera, false, #instancepositions)

	love.graphics.setColor(0.9, 0.8, 0.9)
	love.graphics.print("FPS: "..tostring(love.timer.getFPS()), 10, 10)
end






function love.wheelmoved(x, y)
    if y > 0 then
        current_camera:updateOrthographicMatrix(current_camera.size - 0.1)
        current_camera.radius = current_camera.radius - 0.1
    elseif y < 0 then
        current_camera:updateOrthographicMatrix(current_camera.size + 0.1)
        current_camera.radius = current_camera.radius + 0.1
    end
end