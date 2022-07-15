-- Love2D v11.4

function love.load()
	--love:physics init
	WORLD = love.physics.newWorld(0, 0, true)
	WORLD:setCallbacks(beginContact, endContact, preSolve, postSolve)

	--3D stuff load
    g3d = require("libs/g3d")

    SCALE3D = {x = 100, y = -100, z = 100} -- 100 love:physics unit = 1 g3d unit

    love.graphics.setDefaultFilter("linear")
    SCREENSCALE=1
	debug_canvas = love.graphics.newCanvas(1280, 720)
	main_canvas = love.graphics.newCanvas(1280/SCREENSCALE, 720/SCREENSCALE)

	main_camera = g3d.newCamera()
    main_camera:updateProjectionMatrix()

    --3d models
    player_model = g3d.newModel("assets/3d/cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0}, 1)

	math.randomseed( os.time() )

	-- Fixture Category and Mask
	--2 -> Player
    --3 -> Enemies 1
    --4 -> Enemies 2
    --5 -> Enemies 3
    --6 -> Player attacks 1
    --7 -> Player attacks 2
    --8 -> Enemy attacks 1
    --9 -> Enemy attacks 2
    --10 -> Unbreakable terrain
    --11 -> Breakable terrain

	local newPlayer = require("objects/player")
	local newCursor = require("objects/cursor")
	local newEnemy = require("objects/enemy")
	local newBox = require("objects/box")
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
	player_1 = newPlayer(400, 100, 0, player_model, cursor_1)

	view = {"debug", "3d_view"}
	view_index = 1
	view_timer = 0.1

	--enemy_1 = newEnemy(900, 300)
	--enemy_2 = newEnemy(900, 400)

	--circle_1 = newCircle(30, 30)

	gameMap = require("maps/test_map")

	boxes = {}

	for i, obj in pairs(gameMap.layers[2].objects) do
		local model = g3d.newModel("assets/3d/unit_cube.obj", "assets/3d/no_texture.png", {obj.x/SCALE3D.x, obj.y/SCALE3D.y, 0}, {0,0,0}, {obj.width/SCALE3D.x, obj.height/SCALE3D.y, 1})
		local box = newBox(obj.x, obj.y, 0, obj.width, obj.height, model)
		table.insert(boxes, box)
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
			if view[view_index] == "3d_view" then
    			love.mouse.setRelativeMode(true)
    		else
    			love.mouse.setRelativeMode(false)
    		end
		end
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
    main_camera:thirdPersonMovement(dt, player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)

	fps = love.timer.getFPS()
end

function love.draw(dt)

	love.graphics.clear(0.05, 0.0, 0.05)

	if view[view_index] == "debug" then
		-- Terrain draw
		for i, box in pairs(boxes) do
			box:debugDraw()
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
		--3D draw
		love.graphics.setCanvas({main_canvas, depth=true})
	    love.graphics.setDepthMode("lequal", true)

	    love.graphics.clear(0.05, 0.0, 0.05)

	    love.graphics.setMeshCullMode("back")

	    -- Terrain draw
		for i, box in pairs(boxes) do
			box:draw(nil, main_camera, nil)
		end

	    player_1:draw(nil, main_camera, nil)

	    love.graphics.setDepthMode()

		love.graphics.setColor(0.9, 0.8, 0.9)
		love.graphics.print("FPS: "..tostring(fps), 10, 10)

		love.graphics.setCanvas()
	    love.graphics.draw(main_canvas, 0, 0, 0, SCREENSCALE)
	end
end

function love.mousemoved(x,y, dx,dy)
    main_camera:thirdPersonLook(dx,dy,player_1.x, player_1.y, player_1.z)
end

function love.wheelmoved(x, y)
    if y > 0 then
        main_camera.radius = main_camera.radius - 0.1
    elseif y < 0 then
        main_camera.radius = main_camera.radius + 0.1
    end
end

function love.mousepressed( x, y, button, istouch, presses )
	--pass
end

function beginContact(a, b, coll)
	xn,yn = coll:getNormal()
	user_a = a:getUserData()
	user_b = b:getUserData()
	user_a:gotHit(user_b, xn,yn)
	user_b:gotHit(user_a, xn,yn)
    --print(a:getUserData().." colliding with "..b:getUserData().." with a vector normal of: "..x..", "..y.."\n")
end

function endContact(a, b, coll)
	--pass
end

function preSolve(a, b, coll)
	--pass
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
	--pass
end