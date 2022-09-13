local State = require("states/state")

local MainManu = State:new()

function MainManu:new()
   local o = State:new()
   setmetatable(o, self)
   self.__index = self
   return o
end

function MainManu:onEnter()
    love.graphics.setFont(FONT_LARGE)
end

function MainManu:onExit()
    --pass
end

function MainManu:update(dt)
    if GAME.actions["enter"] then
        game_world_state = GameWorldState:new()
        GAME:enterState(game_world_state)
    end
end

function MainManu:draw()
    love.graphics.setColor(244/255, 248/255, 255/255)
    local width = FONT_LARGE:getWidth("Press Enter")
    local height = FONT_LARGE:getHeight()
    love.graphics.printf("Press Enter", ((SCREENWIDTH-32)/2)*WINDOWSCALE - width/2, ((SCREENHEIGHT-32)/2)*WINDOWSCALE - height/2, 200)
end

return MainManu