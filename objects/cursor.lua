local Cursor = {}
Cursor.__index = Cursor

local function newCursor(x, y)
	local self = setmetatable({}, Cursor)

	self.x = x or 0
	self.y = y or 0
	self.z = z or 0

	self.model = g3d.newModel("assets/3d/unit_cylinder.obj", "assets/3d/no_texture.png", {0,0,0}, {0,0,0})

	self.screen_x, self.screen_y = 0, 0

	self.state = "idle"

	-- List of states
	--"idle"
	--"click"
	--"magic"

	self.click_timer = 0.1
	self.click_interval = 0.1 --if click is held, self:click() returns true every 0.1 second

	return self
end

function Cursor:update(dt)
	
	if love.mouse.isDown(1) then
		self.state = "click"

		self.click_timer = self.click_timer + dt

	elseif love.mouse.isDown(2) then
		self.state = "magic"
	else 
		self.state = "idle"

		self.click_timer = 0.1
	end
end

function Cursor:updateCoords(cam_target_x, cam_target_y, player_z)
	self.screen_x, self.screen_y = love.mouse.getPosition()
	self.x = cam_target_x + (self.screen_x/WINDOWSCALE-SCREENWIDTH/2)/SCALE3D.x
	self.y = cam_target_y + (self.screen_y/WINDOWSCALE-SCREENHEIGHT/2)/SCALE3D.y*(16/13) - 1
	self.z = player_z/SCALE3D.z

	self.model:setTranslation(self.x, self.y, self.z)
end

function Cursor:draw()
	self.model:draw(nil, current_camera, false)
end


function Cursor:screenDraw()
	if self.state == "idle" then
		love.graphics.setColor(0.9, 0.8, 0.9)
		love.graphics.setPointSize(4)
	elseif self.state == "click" then
		love.graphics.setColor(0.95, 0.2, 0.35)
		love.graphics.setPointSize(10)
	elseif self.state == "magic" then
		love.graphics.setColor(0.3, 0.2, 0.8)
		love.graphics.setPointSize(10)
	end
	love.graphics.points({self.screen_x, self.screen_y})
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