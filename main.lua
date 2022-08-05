-- Love2D v11.4

function love.load()
	--love:physics init
	WORLD = love.physics.newWorld(0, 0, true)
	WORLD:setCallbacks(beginContact, endContact, preSolve, postSolve)

	-- Utility functions
	require("libs/utils")

	--3D renderer library
    g3d = require("libs/g3d")

    --2D animation library
    anim8 = require("libs/anim8")

    -- for name, i in pairs(love.graphics.getSupported()) do
    -- 	print(name, i)
    -- end

    SCALE3D = {x = 16, y = -16, z = 16} -- 16 love:physics unit (Tiled map) = 1 g3d unit

    love.graphics.setDefaultFilter("nearest") --no atialiasing
	debug_canvas = love.graphics.newCanvas(1278, 720)
	main_canvas = love.graphics.newCanvas(SCREENWIDTH, SCREENHEIGHT)
	main_canvas:setFilter("nearest","nearest") --no atialiasing

	shadow_buffer_canvas = love.graphics.newCanvas(SCREENWIDTH*1.5, SCREENWIDTH, {format="depth24", readable=true})
    shadow_buffer_canvas:setFilter("nearest","nearest")
    variance_shadow_canvas = love.graphics.newCanvas(SCREENWIDTH, SCREENWIDTH, {format="depth24", readable=true})
    variance_shadow_canvas:setFilter("linear","linear")

    DISTLIGHTCAM = 20
    DISTMAINCAM = 10
    CAMVECTOR_MAIN = { 0 * DISTMAINCAM, -3 * DISTMAINCAM, 4 * DISTMAINCAM}
    LIGHTVECTOR_TOP = { 0, -0.00001, 1 * DISTLIGHTCAM} -- in g3d units
    LIGHTVECTOR_LF = {0.404508497 * DISTLIGHTCAM, 0.700629269 * DISTLIGHTCAM, -0.587785252 * DISTLIGHTCAM} -- in g3d units
    CURRENTLIGHT_VECTOR = LIGHTVECTOR_TOP

    LIGHTRAMP_TEXTURE = love.graphics.newImage("shaders/light_ramp.png")

    main_camera = g3d.newCamera(SCREENWIDTH/SCREENHEIGHT)
    main_camera:lookAt(CAMVECTOR_MAIN[1], CAMVECTOR_MAIN[2], CAMVECTOR_MAIN[3], 0,0,0)
    main_camera:updateOrthographicMatrix((SCREENHEIGHT/2)/SCALE3D.x)

    light_camera = g3d.newCamera(shadow_buffer_canvas:getWidth()/shadow_buffer_canvas:getHeight())
    light_camera:lookAt(CURRENTLIGHT_VECTOR[1], CURRENTLIGHT_VECTOR[2], CURRENTLIGHT_VECTOR[3], 0, 0, 0)
    --light_camera:lookInDirection(nil,nil,nil, math.pi/3, -math.pi/5, 0)
    light_camera:updateOrthographicMatrix((SCREENWIDTH/2)/SCALE3D.x)

    current_camera = main_camera

	current_camera:moveCamera(0.625*16, -0.3125*16, 0)


    myShader_code = love.filesystem.read("shaders/test_shader_7.glsl")
    myShader = love.graphics.newShader(myShader_code)

    myShader:sendColor("light_color", {142/255, 79/255, 28/255})
    myShader:sendColor("shadow_color", {94/255, 75/255, 194/255})
    myShader:send("light_direction", CURRENTLIGHT_VECTOR)
	myShader:send("light_ramp_tex", LIGHTRAMP_TEXTURE)

    depthMapShader_code = love.filesystem.read("shaders/depth_map.glsl")
    depthMapShader = love.graphics.newShader(depthMapShader_code)

    billboardShader_code = love.filesystem.read("shaders/billboard.glsl")
    billboardShader = love.graphics.newShader(billboardShader_code)

    -- Random seed
	local seed = os.time()
	print('Seeding RNG with: ' .. seed)
	math.randomseed(seed)

	-- Fixture Category and Mask
	--1 -> Everything else (Shadows for now)
	--2 -> Player
    --3 -> Enemies 1
    --4 -> Enemies 2
    --5 -> Enemies 3
    --6 -> Player attacks 1
    --7 -> Player attacks 2
    --8 -> Enemy attacks 1
    --9 -> Enemy attacks 2
    --10 -> Unbreakable terrain (Floor 0 - Barriers)
    --11 -> Unbreakable terrain (Floor 1)
    --12 -> Unbreakable terrain (Floor 2)
    --13 -> Unbreakable terrain (Floor 3)
    --14 -> Unbreakable terrain (Floor 4)

	local newPlayer = require("objects/player")
	local newCursor = require("objects/cursor")
	local newEnemy = require("objects/enemy")
	local newBox = require("objects/box")
	local newPolygon = require("objects/polygon")
	local newCircle = require("objects/circle")
	local newProjectile = require("objects/projectile")

	newInstancedMesh = require("objects/instanced_mesh")
	newShadow = require("objects/shadow")
	newSprite = require("objects/sprite")

	require("libs/utils") --utility functions

	SPAWNFUNCTIONS = {}
	SPAWNFUNCTIONS["Enemy"] = newEnemy
	SPAWNFUNCTIONS["Projectile"] = newProjectile
	SPAWNFUNCTIONS["Box"] = newBox

	SPAWNQUEUE = {}
	DELETEQUEUE = {}

	cursor_1 = newCursor()
	love.mouse.setVisible(false)
	player_1 = newPlayer(64, 64, 200, cursor_1)

	view = {"final_view", "3d_debug"}
	view_index = 1
	view_timer = 0.1

	--enemy_1 = newEnemy(900, 300)
	--enemy_2 = newEnemy(900, 400)

	circle_1 = newCircle(30, 30, 8, 20)

	--Level loader
	gameMap = require("maps/test_map")

	--shadow_imesh = newInstancedMesh(300, "plane", "assets/2d/projectiles/test.png", 16, 16, {rotation = {-0.927295218,0,0}})

	projectile_imesh = newInstancedMesh(300, "plane", "assets/2d/projectiles/test.png", 16, 16, {rotation = {-0.927295218,0,0}})
	projectiles = {}

	collisions = {}
	tilesets = {}
	tiles = {}
	local layer_height = -SCALE3D.z
	local depth = SCALE3D.z

	-- Load tileset's images
	for i, tileset in pairs(gameMap.tilesets) do
		local path = string.sub(tileset.image, 3)
		local tileset_image = love.graphics.newImage(path)
		tilesets[i] = {image = tileset_image, mapwidth = gameMap.width, mapheight = gameMap.height, tilewidth = tileset.tilewidth,  tileheight = tileset.tileheight}
	end

	tile_imesh = newInstancedMesh(200, "cube", tilesets[1].image, 16, 22)

	tile_instance_positions = {}
	tile_instance_uvs = {}

	local newTile = require("objects/tile")

	-- Read tiled layers for hitboxes and tile placement
	for i, group in pairs(gameMap.layers) do
		if group.type == "group" then -- Groups (Floors)
			local floor_tiles = {}
			local words = {}
			for w in string.gmatch(group.name, "([^%s]+)") do
				table.insert(words, w)
			end
			local floor_number = tonumber(words[2])
			for i, sublayer in pairs(group.layers) do
				if sublayer.type == "objectgroup" then -- Hitboxes
					coll_category = 10 + floor_number
					floor_table = {}
					for i, obj in pairs(sublayer.objects) do
						if obj.shape == "rectangle" then
							local model = g3d.newModel(g3d.loadObj("assets/3d/unit_cube_front_top_3.obj", false, true), "assets/3d/front_top_texture_2.png", {obj.x/SCALE3D.x, obj.y/SCALE3D.y, layer_height}, {0,0,0}, {obj.width/SCALE3D.x, obj.height/SCALE3D.y, depth/SCALE3D.z})
							shape = newBox(obj.x, obj.y, layer_height, obj.width, obj.height, depth, model, coll_category)
						elseif 	obj.shape == "polygon" then
							local model = g3d.newModel(g3d.loadObj("assets/3d/unit_cube_front_top.obj", false, true), "assets/3d/white_texture.png", {obj.x/SCALE3D.x, obj.y/SCALE3D.y, layer_height}, {0,0,0}, {20/SCALE3D.x, 20/SCALE3D.y, 20/SCALE3D.z})
							shape = newPolygon(obj.x, obj.y, layer_height, obj.polygon, model, coll_category)
						end
						table.insert(floor_table, shape)
					end
					layer_height = layer_height + SCALE3D.z
					collisions[2+floor_number] = floor_table
				end
				if sublayer.type == "tilelayer" and sublayer.visible == true then -- Tiles
					--print("FLOOR NUMBER: ", floor_number)
					for y_tile = 1, tilesets[1].mapheight, 1 do
			            for x_tile = 1, tilesets[1].mapwidth, 1 do
			            	local tile_id = sublayer.data[tilesets[1].mapwidth*(y_tile-1)+x_tile]
			            	if tile_id ~= 0 then
			            		local tileset_y = math.ceil(tile_id/(tilesets[1].image:getWidth()/tilesets[1].tilewidth)) - 1
								local tileset_x = (tile_id - (tileset_y*(tilesets[1].image:getWidth()/tilesets[1].tilewidth))) - 1
			            		local x_trans = tileset_x*tilesets[1].tilewidth
			            		local y_trans = tileset_y*tilesets[1].tileheight

								local quad = love.graphics.newQuad(x_trans, y_trans, tilesets[1].tilewidth, tilesets[1].tileheight, tilesets[1].image:getDimensions())
								-- Add tile to the instance table (in g3d units)
								local x, y, z = x_tile-0.5, -(y_tile-0.5), (floor_number-1)+0.5
								local u, v = x_trans/tilesets[1].image:getWidth(), y_trans/tilesets[1].image:getHeight()
								local instance_index = tile_imesh:addInstance(x,y,z, 1,1,1, u,v)
								local tile = newTile((x_tile-1)*tilesets[1].tilewidth, (y_tile-1)*tilesets[1].tileheight, layer_height, instance_index)
								table.insert(floor_tiles, tile)
							end
						end
					end
					tiles[floor_number] = floor_tiles
				end
			end
		end
	end

	fps = 60
end

function love.update(dt)
	--General Inputs
	if love.keyboard.isDown("r") then
		love.event.quit("restart")
	end

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	--Switch views
	if view_timer < 0.1 then
		view_timer = view_timer + dt
	else
		if love.keyboard.isDown("k") then
			view_timer = 0
			if view_index < 2 then
				view_index = view_index + 1
			else
				view_index = 1
			end
		elseif love.keyboard.isDown("p") then
    		view_timer = 0
    	elseif love.keyboard.isDown("t") then
    		view_timer = 0
    		--print(#tile_imesh.instanced_positions)
    		--tile_imesh:addInstance({math.random(1, 10),math.random(-10, -1),1}, {0,0})
    		local remove_index = math.random(1, projectile_imesh.instanced_count)
    		--print("remove index: ", remove_index)
    		table.insert(DELETEQUEUE, {group = "Projectile", index = remove_index})
    	elseif love.keyboard.isDown("f11") then
    		view_timer = 0
    		main_canvas:newImageData():encode("png", "screen"..tostring(os.time())..".png")
    		love.graphics.captureScreenshot("screen"..tostring(os.time()).."_scaled"..".png")
		end
	end

	if view[view_index] == "3d_debug" then
		love.mouse.setRelativeMode(true)
	else
		love.mouse.setRelativeMode(false)
	end

	-- Entities update
	WORLD:update(dt)
	player_1:update(dt)

	cursor_1:update(dt)
	
	--enemy_1:update(dt)
	--enemy_2:update(dt)
	circle_1:update(dt)

	--Spawn the stuff from SPAWNQUEUE
	for i, spawn in pairs(SPAWNQUEUE) do
		obj = SPAWNFUNCTIONS[spawn["group"]](unpack(spawn["args"]))
		if spawn["group"] == "Projectile" then
			local instance_index = projectile_imesh:addInstance(obj.x/SCALE3D.x, obj.y/SCALE3D.y, obj.z/SCALE3D.z, 1,1,1, obj.uvs[1], obj.uvs[2])
			--print("adding from SPAWNQUEUE: ", instance_index, obj.x/SCALE3D.x, obj.y/SCALE3D.y, obj.z/SCALE3D.z, player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)
			obj.index = instance_index
			table.insert(projectiles, obj)
		end
	end

	-- Projectiles update
	for i, projectile in ipairs(projectiles) do
		projectile:update(dt)
		projectile_imesh:updateInstancePosition(projectile.index, projectile.x/SCALE3D.x, projectile.y/SCALE3D.y, projectile.z/SCALE3D.z)
		--print(projectile.index, projectile.x/SCALE3D.x, projectile.y/SCALE3D.y, projectile.z/SCALE3D.z, player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)
		if not projectile.active then
			table.insert(DELETEQUEUE, {group = "Projectile", index = i})
			local swap_index = projectile_imesh:removeInstance(projectiles[i].index)
			local swap_obj = projectiles[swap_index]
			projectiles[i] = swap_obj
			projectiles[i].index = i
		end
	end

	--print(#projectiles)

	--Delete the stuff from DELETEQUEUE
	for i, delete in pairs(DELETEQUEUE) do
		if delete["group"] == "Projectile" then
			table.remove(projectiles, swap_index)
		end
	end

	SPAWNQUEUE = {}
	DELETEQUEUE = {}

	--3D Cam update

	local l_cam_dx, l_cam_dy = 0, 0

	if love.keyboard.isDown("h") then
		l_cam_dy = 0.0625
	elseif love.keyboard.isDown("n") then
		l_cam_dy = -0.0625
	end
	if love.keyboard.isDown("b") then
		l_cam_dx = 0.0625
	elseif love.keyboard.isDown("m") then
		l_cam_dx = -0.0625
	end

	light_camera:moveCamera(l_cam_dx, l_cam_dy, 0)

	--light grid = { 1/16 } in g3d units

	--camera grid = { 0.0625 = 1/16, 0.3125 = 5/16, 0.3125 = 5/16 } in g3d units
	cam_grid_pos = { math.floor((player_1.x/SCALE3D.x) / 0.0625)*0.0625, math.floor((player_1.y/SCALE3D.y) / 0.3125)*0.3125, math.floor((player_1.z/SCALE3D.z) / 0.3125)*0.3125 }

	local cam_dx, cam_dy = 0, 0

	if love.keyboard.isDown("up") then
		cam_dy = 0.3125
	elseif love.keyboard.isDown("down") then
		cam_dy = -0.3125
	end
	if love.keyboard.isDown("right") then
		cam_dx = 0.625
	elseif love.keyboard.isDown("left") then
		cam_dx = -0.625
	end

	main_camera:moveCamera(cam_dx, cam_dy, 0)

	fps = love.timer.getFPS()
end

function love.draw(dt)

	love.graphics.clear(0.05, 0.0, 0.05)
	love.graphics.setColor(1,1,1)

	-- Shadowmap render
    love.graphics.setMeshCullMode("front")
    love.graphics.setCanvas({depthstencil=shadow_buffer_canvas})
    love.graphics.clear(1,0,0)
    love.graphics.setDepthMode("lequal", true)

    -- Terrain draw
    tile_imesh:draw(depthMapShader, light_camera, true)

    love.graphics.setMeshCullMode("back")
    
    -- Entities draw
    player_1:draw(depthMapShader, light_camera, true)

    for i, projectile in pairs(projectiles) do
		projectile:draw(depthMapShader, light_camera, true)
	end

    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    -- if true then
    --     love.graphics.setCanvas{canvas, depth=24}
    --     love.graphics.clear(1,1,1)
    -- end

    if love.keyboard.isDown("l") then
        current_camera = light_camera
    else
    	current_camera = main_camera
	end

    --Object render

    if myShader:hasUniform("shadowProjectionMatrix") then
        myShader:send("shadowProjectionMatrix", light_camera.projectionMatrix)
    end
    if myShader:hasUniform("shadowViewMatrix") then
        myShader:send("shadowViewMatrix", light_camera.viewMatrix)
    end
    if myShader:hasUniform("shadowMapImage") then
        myShader:send("shadowMapImage", shadow_buffer_canvas)
    end

	--3D draw
	love.graphics.setCanvas({main_canvas, depth=true})
    love.graphics.setDepthMode("lequal", true)

    love.graphics.clear(0.05, 0.0, 0.05)

    love.graphics.setMeshCullMode("none")

    if view[view_index] == "3d_debug" then
	    -- Draw the collision boxes
	    for i, floor in pairs(collisions) do
			for i, box in pairs(floor) do
				box:draw(myShader, current_camera, false)
			end
		end
	else
		-- Draw tiles
		tile_imesh:draw(myShader, current_camera, false)
	end

	projectile_imesh:draw(billboardShader, current_camera, false)

    player_1:draw(billboardShader, current_camera, false)

    -- Draw UI elements (Original Resolution)
    love.graphics.setDepthMode()
	love.graphics.setCanvas(main_canvas)

	love.graphics.setColor(0.9, 0.8, 0.9)
	love.graphics.print("FPS: "..tostring(fps), 10, 10)

	love.graphics.setCanvas()
	love.graphics.draw(main_canvas, 0, 0, 0, WINDOWSCALE, WINDOWSCALE)

	-- Draw UI elements (Window size Resolution)
	circle_1:screenDraw()
	cursor_1:screenDraw()
	
    
end

function love.mousemoved(x,y, dx,dy)
	cursor_1:updateCoords(current_camera.target[1], current_camera.target[2], player_1.z)

	if dx ~= 0 and dy ~= 0 and view[view_index] == "3d_debug" then
    	current_camera:thirdPersonLook(dx,dy,player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        current_camera:updateOrthographicMatrix(current_camera.size - 0.1)
    elseif y < 0 then
        current_camera:updateOrthographicMatrix(current_camera.size + 0.1)
    end
end

function love.mousepressed( x, y, button, istouch, presses )
	cursor_1:updateCoords(current_camera.target[1], current_camera.target[2], player_1.z)
end

function beginContact(a, b, contact)
	user_a = a:getUserData()
	user_b = b:getUserData()
	user_a:gotHit(user_b)
	user_b:gotHit(user_a)
    --print(a:getUserData().." colliding with "..b:getUserData().."\n")
end

function endContact(a, b, contact)
	user_a = a:getUserData()
	user_b = b:getUserData()
	user_a:exitHit(user_b)
	user_b:exitHit(user_a)
end

function preSolve(a, b, contact)
	--pass
end

function postSolve(a, b, contact, normalimpulse, tangentimpulse)
	--pass
end