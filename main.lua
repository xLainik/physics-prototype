-- Love2D v11.4

function love.load()
	--love:physics init
	WORLD = love.physics.newWorld(0, 0, true)
	WORLD:setCallbacks(beginContact, endContact, preSolve, postSolve)
	WORLDZ = love.physics.newWorld(0, 0, true)

	-- Utility functions
	require("libs/utils")

	--3D stuff load
    g3d = require("libs/g3d")

    SCALE3D = {x = 16, y = -16, z = 16} -- 16 love:physics unit (Tiled map) = 1 g3d unit
    SCREENSCALE=2

    love.graphics.setDefaultFilter("nearest") --no atialiasing
	debug_canvas = love.graphics.newCanvas(1278, 720)
	main_canvas = love.graphics.newCanvas(1278/SCREENSCALE, 720/SCREENSCALE)
	main_canvas:setFilter("linear","linear") --no atialiasing

	shadow_buffer_canvas = love.graphics.newCanvas(1278/SCREENSCALE, 720/SCREENSCALE, {format="depth24", readable=true})
    shadow_buffer_canvas:setFilter("nearest","nearest")
    variance_shadow_canvas = love.graphics.newCanvas(1278/SCREENSCALE, 1278/SCREENSCALE, {format="depth24", readable=true})
    variance_shadow_canvas:setFilter("linear","linear")

	main_camera = g3d.newCamera()
    main_camera:updateOrthographicMatrix(7.5)

    DISTLIGHTCAM = 20
    LIGHTVECTOR = {x = 0.00001, y = 0.00001, z = 1.0} -- in g3d units

    light_camera = g3d.newCamera(shadow_buffer_canvas:getWidth()/shadow_buffer_canvas:getHeight())
    --light_camera:lookAt(0.0 * DISTLIGHTCAM, 0.0 * DISTLIGHTCAM, 1.0 * DISTLIGHTCAM, 0,0,0)
    light_camera:updateOrthographicMatrix(20)

    current_camera = main_camera

    --3d models
    player_model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, {7/8,7/8,1.5})

    myShader_code = love.filesystem.read("shaders/test_shader_7.glsl")
    myShader = love.graphics.newShader(myShader_code)

    depthMapShader_code = love.filesystem.read("shaders/depth_map.glsl")
    depthMapShader = love.graphics.newShader(depthMapShader_code)

    varianceShader_code = love.filesystem.read("shaders/variance_shadow_map.glsl")
    varianceShader = love.graphics.newShader(varianceShader_code)

    -- Random seed
	local seed = os.time()
	print('Seeding RNG with: ' .. seed)
	math.randomseed(seed)

	-- Fixture Category and Mask
	--1 -> Everything else
	--2 -> Player
    --3 -> Enemies 1
    --4 -> Enemies 2
    --5 -> Enemies 3
    --6 -> Player attacks 1
    --7 -> Player attacks 2
    --8 -> Enemy attacks 1
    --9 -> Enemy attacks 2
    --10 -> Unbreakable terrain (Floor -1 - Barriers)
    --11 -> Unbreakable terrain (Floor 0)
    --12 -> Unbreakable terrain (Floor 1)
    --13 -> Unbreakable terrain (Floor 2)
    --14 -> Unbreakable terrain (Floor 3)

	local newPlayer = require("objects/player")
	local newCursor = require("objects/cursor")
	local newEnemy = require("objects/enemy")
	local newBox = require("objects/box")
	local newPolygon = require("objects/polygon")
	local newCircle = require("objects/circle")
	local newProjectile = require("objects/projectile")

	require("libs/utils") --utility functions

	SPAWNFUNCTIONS = {}
	SPAWNFUNCTIONS["Enemy"] = newEnemy
	SPAWNFUNCTIONS["Projectile"] = newProjectile
	SPAWNFUNCTIONS["Box"] = newBox

	SPAWNQUEUE = {}
	DELETEQUEUE = {}

	cursor_1 = newCursor()
	player_1 = newPlayer(64, 64, 200, player_model, cursor_1)

	view = {"debug", "3d_view"}
	view_index = 2
	view_timer = 0.1

	--enemy_1 = newEnemy(900, 300)
	--enemy_2 = newEnemy(900, 400)

	--circle_1 = newCircle(30, 30)

	--Level loader
	-- mapLoader = require("maps/read_map")
	-- map_3d_test = mapLoader("maps/test_3d_2.obj")

	-- floors = {}

	-- for index, object in pairs(map_3d_test) do
	-- 	print(index)
	-- 	local model = g3d.newModel(object, "assets/3d/white_texture.png")
	-- 	local floor = newFloor(model)
	-- 	table.insert(floors, floor)
	-- end

	gameMap = require("maps/test_map")

	collisions = {}
	layer_height = -SCALE3D.z
	depth = SCALE3D.z

	for i, layer in pairs(gameMap.layers) do
		if layer.type == "objectgroup" then
			words = {}
			for w in string.gmatch(layer.name, "([^%s]+)") do
		       table.insert(words, w)
		    end
			coll_category = 11 + tonumber(words[2])
			floor_table = {}
			for i, obj in pairs(layer.objects) do
				if obj.shape == "rectangle" then
					local model = g3d.newModel(g3d.loadObj("assets/3d/unit_cube_front_top_2.obj", false, true), "assets/3d/front_top_texture.png", {obj.x/SCALE3D.x, obj.y/SCALE3D.y, layer_height}, {0,0,0}, {obj.width/SCALE3D.x, obj.height/SCALE3D.y, depth/SCALE3D.z})
					shape = newBox(obj.x, obj.y, layer_height, obj.width, obj.height, depth, model, coll_category)
				elseif 	obj.shape == "polygon" then
					local model = g3d.newModel(g3d.loadObj("assets/3d/unit_cube_front_top.obj", false, true), "assets/3d/white_texture.png", {obj.x/SCALE3D.x, obj.y/SCALE3D.y, layer_height}, {0,0,0}, {20/SCALE3D.x, 20/SCALE3D.y, 20/SCALE3D.z})
					shape = newPolygon(obj.x, obj.y, layer_height, obj.polygon, model, coll_category)
				end
				table.insert(floor_table, shape)
			end
			layer_height = layer_height + SCALE3D.z
			collisions[2+tonumber(words[2])] = floor_table
		end
	end

	projectiles = {}

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
    	elseif love.keyboard.isDown("f11") then
    		view_timer = 0
    		main_canvas:newImageData():encode("png", "screen"..tostring(os.time())..".png")
    		love.graphics.captureScreenshot("screen"..tostring(os.time()).."_scaled"..".png")
		end
	end

	if view[view_index] == "3d_view" then
		love.mouse.setRelativeMode(true)
	else
		love.mouse.setRelativeMode(false)
	end

	-- Entities update
	WORLD:update(dt)
	player_1:update(dt)
	--cursor_1:update(dt)
	--enemy_1:update(dt)
	--enemy_2:update(dt)
	--circle_1:update(dt)

	-- Projectiles update
	for index, projectile in ipairs(projectiles) do
		projectile:update(dt)
		if not projectile.active then
			table.insert(DELETEQUEUE, {group = "Projectile", index = index})
		end
	end

	--Spawn the stuff from SPAWNQUEUE
	for i, spawn in pairs(SPAWNQUEUE) do
		object = SPAWNFUNCTIONS[spawn["group"]](unpack(spawn["args"]))
		if spawn["group"] == "Projectile" then
			table.insert(projectiles, object)
		end
	end

	--Delete the stuff from DELETEQUEUE
	for i, delete in pairs(DELETEQUEUE) do
		if delete["group"] == "Projectile" then
			table.remove(projectiles, delete["index"])
		end
	end

	SPAWNQUEUE = {}
	DELETEQUEUE = {}

	--3D Cam update

	light_camera:lookAt(math.floor(player_1.x/SCALE3D.x+LIGHTVECTOR.x*DISTLIGHTCAM)+0.00001, math.floor(player_1.y/SCALE3D.y+LIGHTVECTOR.y*DISTLIGHTCAM), math.floor(player_1.z/SCALE3D.z+LIGHTVECTOR.z*DISTLIGHTCAM), math.floor(player_1.x/SCALE3D.x), math.floor(player_1.y/SCALE3D.y), math.floor(player_1.z/SCALE3D.z))

    current_camera:thirdPersonMovement(dt, player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)

    --light_camera.position = {main_camera.position[1]+2, main_camera.position[2], main_camera.position[3]}
    --light_camera.target = main_camera.target


    -- print("camera position", unpack(main_camera.position))
    -- print("light position", unpack(light_camera.position))
    -- print("player position", player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)
    -- print("camera target", unpack(main_camera.target))
    -- print("light target", unpack(light_camera.target))

	fps = love.timer.getFPS()
end

function love.draw(dt)

	love.graphics.clear(0.05, 0.0, 0.05)

	if view[view_index] == "debug" then
		-- Terrain draw
		for i, floor in pairs(collisions) do
			for i, box in pairs(floor) do
				box:debugDraw()
			end
		end

		-- Entities draw
		--enemy_1:debugDraw()
		--enemy_2:debugDraw()
		player_1:debugDraw()

		-- Projectiles draw
		for index, projectile in pairs(projectiles) do
			projectile:debugDraw()
		end

		-- GUI draw
		--circle_1:debugDraw()
		--cursor_1:debugDraw()

		love.graphics.setColor(0.9, 0.8, 0.9)
		love.graphics.print("FPS: "..tostring(fps), 10, 10)

	elseif view[view_index] == "3d_view" then

		love.graphics.setColor(1,1,1)

		-- Shadowmap render
	    love.graphics.setMeshCullMode("back")
	    love.graphics.setCanvas({depthstencil=shadow_buffer_canvas})
	    love.graphics.clear(1,0,0)
	    love.graphics.setDepthMode("lequal", true)

	    -- Terrain draw
	    for i, floor in pairs(collisions) do
			for i, box in pairs(floor) do
				box:draw(depthMapShader, light_camera, true)
			end
		end
	    
	    -- Entities draw
	    player_1:draw(depthMapShader, light_camera, true)


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
	    myShader:sendColor("light_color", {142/255, 79/255, 28/255})
	    myShader:sendColor("shadow_color", {94/255, 75/255, 194/255})
	    myShader:send("light_direction", {LIGHTVECTOR.x, LIGHTVECTOR.y, LIGHTVECTOR.z})

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

	    -- Terrain draw
	    for i, floor in pairs(collisions) do
			for i, box in pairs(floor) do
				box:draw(myShader, current_camera, false)
			end
		end

	    player_1:draw(myShader, current_camera, false)

	    love.graphics.setDepthMode()

	    love.graphics.setCanvas(main_canvas)
		love.graphics.setColor(0.9, 0.8, 0.9)
		love.graphics.print("FPS: "..tostring(fps), 10, 10)

		love.graphics.setCanvas()
	    love.graphics.draw(main_canvas, 0, 0, 0, SCREENSCALE/WINDOWSCALE)
	end
end

function love.mousemoved(x,y, dx,dy)
    current_camera:thirdPersonLook(dx,dy,player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)
end

function love.wheelmoved(x, y)
    if y > 0 then
        current_camera.radius = current_camera.radius - 0.1
    elseif y < 0 then
        current_camera.radius = current_camera.radius + 0.1
    end
end

function love.mousepressed( x, y, button, istouch, presses )
	--pass
end

function beginContact(a, b, coll)
	user_a = a:getUserData()
	user_b = b:getUserData()
	user_a:gotHit(user_b)
	user_b:gotHit(user_a)
    --print(a:getUserData().." colliding with "..b:getUserData().."\n")
end

function endContact(a, b, coll)
	user_a = a:getUserData()
	user_b = b:getUserData()
	user_a:exitHit(user_b)
	user_b:exitHit(user_a)
end

function preSolve(a, b, coll)
	--pass
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
	--pass
end