local Cursor = {}
Cursor.__index = Cursor

local function newCursor(x, y)
	local self = setmetatable({}, Cursor)

	self.x = x or 0
	self.y = y or 0
	self.z = z or 0

	self.screen_x, self.screen_y = 0, 0

	self.image = love.graphics.newImage("assets/sprites/cursor_1.png")

	self.z_offset = 4/0.8125

	self.state = "idle"

	-- List of states
	--"idle"
	--"click"
	--"magic"

	self.click_timer = 0
	self.click_interval = 0.05 --if click is held, self:click() returns true every 0.2 second

	self.unhold_timer = 0

	return self
end

function Cursor:changeImage(image_name)
	self.image = love.graphics.newImage(GAME.sprites_directory.."/"..image_name..".png")
end

function Cursor:gameWorldEnter()
	self.model = g3d.newModel(GAME.models_directory.."/unit_cylinder.obj", GAME.models_directory.."/no_texture.png", {0,0,0}, {0,0,0})
end

function Cursor:changeInterval(interval)
	self.click_interval = interval
end

function Cursor:update(dt)

	self:updateScreenPosition()
	
	if love.mouse.isDown(1) then
		self.state = "click"

		if self.click_timer >= self.click_interval then
			self.click_timer = self.click_interval
		else
			self.click_timer = self.click_timer + dt
		end
		
		self.unhold_timer = 0

	elseif love.mouse.isDown(2) then
		self.state = "magic"
	else 
		self.state = "idle"

		if self.unhold_timer >= self.click_interval then
			-- recharge timer only if the mouse has been release click_interval second ago or more
			self.click_timer = self.click_interval
		else
			self.unhold_timer = self.unhold_timer + dt
		end
	end
end

function Cursor:updateScreenPosition()
	self.screen_x, self.screen_y = love.mouse.getPosition()
end

function Cursor:updateCoords(cam_target_x, cam_target_y, player_z)
	self.x = cam_target_x + (self.screen_x/WINDOWSCALE-(SCREENWIDTH-16)/2)/SCALE3D.x + GAME.CANVAS_OFFSET[1]/16
	self.y = cam_target_y + (self.screen_y/WINDOWSCALE-(SCREENHEIGHT-16)/2)/(-SCALE3D.x)*(16/13) - 1 + GAME.CANVAS_OFFSET[2]/-16
	self.z = player_z/SCALE3D.z

	self.model:setTranslation(self.x, self.y, self.z)
end

function Cursor:draw(shader, camera, shadowmap)
	self.model:draw(shader, camera, shadowmap)
end


function Cursor:screenDraw()
	love.graphics.setColor(1,1,1)
	love.graphics.draw(self.image, self.screen_x-3.5*WINDOWSCALE, self.screen_y-3.5*WINDOWSCALE, 0, WINDOWSCALE)
	if self.state == "idle" then
		--love.graphics.setColor(0.9, 0.8, 0.9)
		--love.graphics.setPointSize(4)
	elseif self.state == "click" then
		love.graphics.setColor(0.95, 0.2, 0.35)
		love.graphics.setPointSize(2*WINDOWSCALE)
		love.graphics.points({self.screen_x, self.screen_y})
	elseif self.state == "magic" then
		love.graphics.setColor(0.3, 0.2, 0.8)
		love.graphics.setPointSize(2*WINDOWSCALE)
		love.graphics.points({self.screen_x, self.screen_y})
	end
	
end

function Cursor:changeState(new_state)
	self.state = new_state
end

function Cursor:click()
	if self.state == "click" and self.click_timer >= self.click_interval then
		self.click_timer = self.click_timer - self.click_interval
		return true
	end

	return false
end

return newCursor