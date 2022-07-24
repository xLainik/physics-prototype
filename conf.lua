function love.conf(t)
	--https://love2d.org/wiki/Config_Files
	t.window.depth = 16

	WINDOWSCALE = 2

	t.identity = "Physics Prototype" --AppData/LOVE folder's name
	t.title = "Physics Prototype"
	t.console = true
	t.window.msaa = 0
	t.window.vsync = tr
	t.window.height = 720/WINDOWSCALE
	t.window.width = 1278/WINDOWSCALE

	t.window.display = 1 
    t.window.x = 500                    
    t.window.y = 300  
end
