function love.conf(t)
	--https://love2d.org/wiki/Config_Files
	WINDOWSCALE = 2

	t.version = "11.4"
	t.identity = "Physics Prototype" --AppData/LOVE folder's name
	t.console = true
	

	t.window.title = "AAAAAAAAA"
	t.window.icon = nil
	t.window.width = 1278/WINDOWSCALE
	t.window.height = 720/WINDOWSCALE
	t.window.vsync = true
	t.window.resizable = false
    --t.window.minwidth = 426
    --t.window.minheight = 240
	t.window.display = 1 
    t.window.x = 500                    
    t.window.y = 300

    t.modules.touch = false
    t.modules.video = false
end
