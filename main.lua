-- Love2D v11.4

function love.load()
	--Love2d load
	WORLD = love.physics.newWorld(0, 0, true)

	newPlayer = require("objects/player")
	newTile = require("objects/tile")

	player_1 = newPlayer(400, 100)

	gameMap = require("maps/test_map")

	tiles = {}

	for i, obj in pairs(gameMap.layers[2].objects) do
		local tile = newTile(obj.x, obj.y, obj.width, obj.height)
		table.insert(tiles, tile)
	end

	fps = 60
end

function love.update(dt)
	--Love2d update
	WORLD:update(dt)
	player_1:update(dt)

	if love.keyboard.isDown("r") then
		love.event.quit("restart")
	end

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	fps = love.timer.getFPS()
end

function love.draw(dt)
	--Love2d draw
	love.graphics.clear(0.05, 0.0, 0.05)
	player_1:debugDraw()

	for i, tile in pairs(tiles) do
		tile:debugDraw()
	end

	love.graphics.print("FPS: "..tostring(fps), 10, 10)
end