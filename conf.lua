function love.conf(t)
	--https://love2d.org/wiki/Config_Files
	
	t.version = "11.4"
	t.identity = "Physics Prototype" --AppData/LOVE folder's name
	t.console = true
	
	-- source resolution (pixelart)
	SCREENWIDTH = 426
    SCREENHEIGHT = 240

    WINDOWSCALE = 2

	t.window.title = "AAAAAAAAA"
	t.window.icon = nil
	t.window.width = SCREENWIDTH*WINDOWSCALE
	t.window.height = SCREENHEIGHT*WINDOWSCALE
	t.window.vsync = true
	t.window.resizable = false
    --t.window.minwidth = 426
    --t.window.minheight = 240
	t.window.display = 1 
    t.window.x = 300                    
    t.window.y = 220

    t.modules.touch = false
    t.modules.video = false
end
