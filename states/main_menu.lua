local State = require("states/state")

local MainMenu = State:new()

function MainMenu:new()
   local o = State:new()
   setmetatable(o, self)
   self.__index = self
   return o
end

function MainMenu:onEnter()
    love.graphics.setFont(GAME.FONT_LARGE)
end

function MainMenu:onExit()
    --pass
end

function MainMenu:update(dt)
    if GAME.actions["enter"] then
        GAME:enterState("game_world")
    end
end

function MainMenu:draw()
    -- pass
end

function MainMenu:drawUI()
    love.graphics.setColor(244/255, 248/255, 255/255)
    love.graphics.clear()
    local width = GAME.FONT_LARGE:getWidth("Press Enter")
    local height = GAME.FONT_LARGE:getHeight()
    love.graphics.printf("Press Enter", ((SCREENWIDTH-32)/2)*WINDOWSCALE - width/2, ((SCREENHEIGHT-32)/2)*WINDOWSCALE - height/2, 200)
end

return MainMenu