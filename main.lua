-- Love2D v11.4

function love.load()
	--love:physics init
	WORLD = love.physics.newWorld(0, 0, true)
	WORLD:setCallbacks(beginContact, endContact, preSolve, postSolve)

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
	local newTile = require("objects/tile")
	local newCircle = require("objects/circle")
	local newProjectile = require("objects/projectile")

	require("libs/utils") --utility functions

	SPAWNFUNCTIONS = {}
	SPAWNFUNCTIONS["Enemy"] = newEnemy
	SPAWNFUNCTIONS["Projectile"] = newProjectile
	SPAWNFUNCTIONS["Tile"] = newTile

	SPAWNQUEUE = {}
	DELETEQUEUE = {}

	cursor_1 = newCursor()
	player_1 = newPlayer(400, 100, cursor_1)


	enemy_1 = newEnemy(900, 300)
	--enemy_2 = newEnemy(900, 400)

	circle_1 = newCircle(30, 30)

	gameMap = require("maps/test_map")

	tiles = {}

	for i, obj in pairs(gameMap.layers[2].objects) do
		local tile = newTile(obj.x, obj.y, obj.width, obj.height)
		table.insert(tiles, tile)
	end

	projectiles = {}

	fps = 60
end

function love.update(dt)
	-- Entities update
	WORLD:update(dt)
	player_1:update(dt)
	cursor_1:update(dt)
	enemy_1:update(dt)
	--enemy_2:update(dt)
	circle_1:update(dt)

	-- Projectiles update
	for index, projectile in ipairs(projectiles) do
		projectile:update(dt)
		if not projectile.active then
			table.insert(DELETEQUEUE, {group = "Projectile", index = index})
		end
	end

	if love.keyboard.isDown("r") then
		love.event.quit("restart")
	end

	if love.keyboard.isDown("escape") then
		love.event.quit()
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

	fps = love.timer.getFPS()
end

function love.draw(dt)

	love.graphics.clear(0.05, 0.0, 0.05)

	-- Terrain draw
	for i, tile in pairs(tiles) do
		tile:debugDraw()
	end

	-- Entities draw
	enemy_1:debugDraw()
	--enemy_2:debugDraw()
	player_1:debugDraw()

	-- Projectiles draw
	for index, projectile in pairs(projectiles) do
		projectile:debugDraw()
	end
	
	-- GUI draw
	circle_1:debugDraw()
	cursor_1:debugDraw()

	love.graphics.setColor(0.9, 0.8, 0.9)
	love.graphics.print("FPS: "..tostring(fps), 10, 10)
end

function love.mousemoved(x,y, dx,dy)
	--pass
end

function love.wheelmoved(x, y)
    --pass
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