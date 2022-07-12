local Circle = {}
Circle.__index = Circle

local function newCircle(x, y, num_vertices, radius)
	local self = setmetatable({}, Circle)

	self.num_vertices = n_vertex or 8
	self.radius = radius or 40
	self.polygon_size = self.num_vertices
	
	self.origin_vertices = {}
	local angle = 2 * math.pi / self.num_vertices
	for i = 0, self.num_vertices, 1 do
		x = self.radius * math.sin(i * angle + math.pi/2)
	    y = self.radius * math.cos(i * angle + math.pi/2)
	    self.origin_vertices[i] = {x, y}
	end

	self.active = false

	self.node_buffer = {}
	self.node_buffer_draw = {}

	self.spells = {}

	self.spells[1] = {8, 4} --right-left flick
	self.spells[2] = {6, 2} --down-up flick
	self.spells[3] = {8,7,6,5,4} --sonrisa baja

	return self
end

function Circle:spawn(x, y)
	self.active = true
	--set the cursor on circle center
	self.center_x, self.center_y = love.mouse.getPosition()
	self.cursor_x, self.cursor_y = self.center_x, self.center_y
	self.cursor_angle = 0
	--translation from the origin to he circle center of all the polygon points
	self.vertices = {}
	self.vertices_draw = {}
	for i, point in ipairs(self.origin_vertices) do
		local x = point[1] + self.center_x
		local y = point[2] + self.center_y
		self.vertices[i] = {x, y}
		self.vertices_draw[i] = {x, y}
	end
end

function Circle:pointOnCircle(x,y, circle_x, circle_y, radius)
	return math.abs(x-circle_x) <= radius and math.abs(y-circle_y) <= radius
end

function Circle:getAngle(x1,y1, x2,y2)
	return math.atan2(y2-y1, x2-x1)
end

function Circle:getDistance(x1,y1, x2,y2)
	return math.sqrt((y2-y1)^2 + (x2-x1)^2)
end

function Circle:checkSpells()
	for i, spell in ipairs(self.spells) do
		local match_value = 0
		--compare step by step, if the number of steps are equal
		if #spell == #self.node_buffer then
			match_value = 20 --just for having the same lenght
			for j, node in ipairs(spell) do
				local node_dist = math.abs(node - self.node_buffer[j])
				if node_dist > 4 then --max distance possible is 4
					node_dist = 8 - node_dist
				end	
				match_value = match_value + (80/#self.node_buffer) * (1 - node_dist / 4)
			end
		end
		print(tostring(match_value).."% => Spell "..tostring(i))	
	end
end

function Circle:addNode(add_index)
	table.insert(self.node_buffer, add_index)
	table.insert(self.node_buffer_draw, self.vertices_draw[add_index])
	--table.remove(self.vertices, index + (#self.node_buffer - 1))
end

function Circle:update(dt)

	if love.mouse.isDown(1) and self.active == false then
		self:spawn()
		--love.mouse.setRelativeMode(true)
	end

	if self.active then
			local real_cursor_x, real_cursor_y = love.mouse.getPosition()
		if self:pointOnCircle(real_cursor_x, real_cursor_y, self.center_x, self.center_y, self.radius-2) then
			self.cursor_x, self.cursor_y = real_cursor_x, real_cursor_y
		else
			self.cursor_angle = self:getAngle(self.center_x,self.center_y, real_cursor_x, real_cursor_y)
			--local ratio = 
			self.cursor_x = self.center_x + self.radius * math.cos(self.cursor_angle)
			self.cursor_y = self.center_y + self.radius * math.sin(self.cursor_angle)
		end

		--print(tostring(#self.node_buffer).." / "..tostring(#self.vertices))

		local add_buffer_index = nil

		for i, point in ipairs(self.vertices_draw) do
			local radius = 11
			if self:pointOnCircle(self.cursor_x, self.cursor_y, point[1], point[2], radius) then
				add_buffer_index = i
				break
			end
		end


        --print(add_buffer_index)

        if add_buffer_index then
	        --check if last input was different
	        if #self.node_buffer > 0 then
	        	--print(#self.node_buffer)
	        	--print(table.concat(self.node_buffer[#self.node_buffer], ","))
				if self.node_buffer[#self.node_buffer] ~= add_buffer_index then
					self:addNode(add_buffer_index)
				end
			else
				self:addNode(add_buffer_index)
			end
		end
    end

    if self.active and love.mouse.isDown(1) == false then
		--if spell is correct, spawn said spell
		print("Input: "..table.concat(self.node_buffer, ","))
		self:checkSpells()

		self.active = false
		self.node_buffer = {}
		self.node_buffer_draw = {}
		self.vertices = self.vertices_draw

		--love.mouse.setRelativeMode(false)
	end
end

function Circle:debugDraw()
	if self.active then
		love.graphics.circle("line", self.center_x, self.center_y, self.radius, self.polygon_size)
		love.graphics.setLineWidth(2)
		love.graphics.line(self.center_x,self.center_y, self.cursor_x,self.cursor_y)
		love.graphics.setPointSize(10)
		love.graphics.points(self.vertices_draw)
		love.graphics.setColor(0.3, 0.2, 0.8)
		if #self.node_buffer_draw > 1 then --draw lines
			for i = 1, #self.node_buffer_draw-1, 1 do
				love.graphics.line(self.node_buffer_draw[i][1], self.node_buffer_draw[i][2], self.node_buffer_draw[i+1][1], self.node_buffer_draw[i+1][2])
			end
			-- for i = 1, #self.node_buffer_draw-2, 3 do
			-- 	love.graphics.polygon("fill", self.node_buffer_draw[i][1], self.node_buffer_draw[i][2], self.node_buffer_draw[i+1][1], self.node_buffer_draw[i+1][2], self.node_buffer_draw[i+2][1], self.node_buffer_draw[i+2][2])
			-- end
		end
		love.graphics.points(self.node_buffer_draw)
		love.graphics.setColor(0.9, 0.2, 0.4)
		love.graphics.points({{self.cursor_x, self.cursor_y}})
    end
end

return newCircle