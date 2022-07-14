local Cursor = {}
Cursor.__index = Cursor

local function newCursor(x, y)
	local self = setmetatable({}, Cursor)

	self.x = x or 0
	self.y = y or 0

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

	self.x, self.y = love.mouse.getPosition()

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

function Cursor:debugDraw()
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
	love.graphics.points({self.x, self.y})
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