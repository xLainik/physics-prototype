local Scene = require("maps/scene")
local Scene_1 = Scene:new()

function Scene_1:new()
    local o = Scene:new()
    setmetatable(o, self)
    self.__index = self

    -- Move the camera to where the player is suppose to be
    current_camera:moveCamera(0.625*16, -0.3125*16, 0)

    -- Light camera for shadow mapping
    DISTLIGHTCAM = 20

    LIGHTVECTOR_TOP = { 0, -0.00001, 1 * DISTLIGHTCAM} -- in g3d units
    LIGHTVECTOR_LF = {-0.404508497 * DISTLIGHTCAM, -0.700629269 * DISTLIGHTCAM, 0.587785252 * DISTLIGHTCAM} -- in g3d units
    LIGHTVECTOR_FRONT = { 0 * DISTMAINCAM, -2 * DISTMAINCAM, 1 * DISTMAINCAM}
    CURRENTLIGHT_VECTOR = LIGHTVECTOR_LF

    shadow_buffer_canvas = love.graphics.newCanvas(SCREENWIDTH*1.50, SCREENWIDTH*1.50, {format="depth24", readable=true})
    shadow_buffer_canvas:setFilter("nearest","nearest")

    light_camera = g3d.newCamera(shadow_buffer_canvas:getWidth()/shadow_buffer_canvas:getHeight())
    light_camera:lookAt(CURRENTLIGHT_VECTOR[1], CURRENTLIGHT_VECTOR[2], CURRENTLIGHT_VECTOR[3], 0, 0, 0)
    light_camera:updateOrthographicMatrix((SCREENWIDTH/2)/SCALE3D.x)

    -- All shaders
    dirLightShader_code = love.filesystem.read(GAME.shaders_directory.."/dir_light.glsl")
    dirLightShader = love.graphics.newShader(dirLightShader_code)

    depthMapShader_code = love.filesystem.read("assets/shaders/depth_map.glsl")
    depthMapShader = love.graphics.newShader(depthMapShader_code)

    billboardShader_code = love.filesystem.read("assets/shaders/billboard.glsl")
    billboardShader = love.graphics.newShader(billboardShader_code)

    -- Shader uniforms 
    LIGHTRAMP_TEXTURE = love.graphics.newImage("maps/scenes/light_ramp_1.png")

    -- TODO: color grading

    dirLightShader:sendColor("light_color", {239/255, 118/255, 98/255, 100/255})
    dirLightShader:sendColor("shadow_color", {91/255, 152/255, 230/255, 168/255})
    dirLightShader:send("light_direction", CURRENTLIGHT_VECTOR)
    dirLightShader:send("light_ramp_tex", LIGHTRAMP_TEXTURE)

    -- Entities/projectiles/particles tables ----------------------------------------------
    self.enemies = {}

    self.projectile_imesh = newInstancedMesh(600, "plane", "assets/sprites/projectiles/projectiles.png", 16, 16)
    self.projectiles = {}
    for index = 1, self.projectile_imesh.max_instances, 1 do
        self.projectiles[index] = "empty"
    end

    self.particle_imesh = newInstancedMesh(400, "plane", "assets/sprites/particles/particles.png", 16, 16)
    self.particles = {}
    for index = 1, self.particle_imesh.max_instances, 1 do
        self.particles[index] = "empty"
    end

    -- Collision meshes and tiles
    self.collisions = {}
    self.tiles = nil

    return o
end

function Scene_1:onEnter(map_index, section_index, door_index)

    local map_directory = GAME.maps_directory.."/"..tostring(map_index)
    local scene_directory = map_directory.."/sections/"..tostring(section_index)

    -- Tiles object
    self.tiles = g3d.newModel(g3d.loadObj(scene_directory.."/tiles.obj", false, true), map_directory.."/tileatlas.png", {0,0,0}, {0,0,math.pi/2})

    -- Collision meshes

    for line in love.filesystem.lines(scene_directory.."/data.dat") do
        local words = getTable(line)
        local object_name = words[1]
        table.remove(words, 1)
        if object_name == "Box" then
            -- Read position and dimension (scale)
            local pos = getFormatedTable(getTable(words[1], "([^,]+)"))
            local dim = getFormatedTable(getTable(words[2], "([^,]+)"))
            -- Spawn a Box collision shape
            local model = g3d.newModel(g3d.loadObj(GAME.models_directory.."/unit_cube.obj", false, true), GAME.models_directory.."/no_texture.png", pos, {0,0,0}, dim)
            local coll_category = 11 + pos[3]
            local shape = current_map.SPAWNFUNCTIONS["Box"](pos[1], pos[2], pos[3], dim[1], dim[2], dim[3], model, coll_category)

            table.insert(self.collisions, shape)
        elseif object_name == "Door" then
            -- Read position, rotation and dimension (scale)
            local pos = getFormatedTable(getTable(words[1], "([^,]+)"))
            local dim = getFormatedTable(getTable(words[2], "([^,]+)"))
            local index = tonumber(words[3])
            local connected_to = getFormatedTable(getTable(words[4], "([^,]+)"))
            local direction = getFormatedTable(getTable(words[5], "([^,]+)"))
            local model = g3d.newModel(g3d.loadObj(GAME.models_directory.."/unit_cube.obj", false, true), GAME.models_directory.."/no_texture.png", pos, {0,0,0}, dim)
            local door = current_map.SPAWNFUNCTIONS["Door"](pos[1], pos[2], pos[3], dim[1], dim[2], dim[3], model, index, connected_to, direction)

            if index == door_index then
                player_1.body:setPosition((pos[1]+direction[1])*SCALE3D.x, (pos[2]+direction[2])*SCALE3D.y)
            end

            table.insert(self.collisions, door)          
        end
    end

    -- Load entities with their respective data
    --table.insert(self.enemies, current_map.SPAWNFUNCTIONS["Enemy_Slime"](120, 120, 100))
    -- Projectiles
    --Particles
end

function Scene_1:update(dt)

    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end

    --3D Cam update
    GAME.CANVAS_OFFSET = main_camera:followPointOffset(player_1.userData.position[1]/SCALE3D.x, player_1.userData.position[2]/SCALE3D.y)
    light_camera:followPointOffset( player_1.userData.position[1]/SCALE3D.x,  player_1.userData.position[2]/SCALE3D.y)

end

function Scene_1:draw()
    love.graphics.clear(0.05, 0.0, 0.05)
    love.graphics.setColor(1,1,1)

    -- Shadowmap render
    love.graphics.setCanvas({depthstencil=shadow_buffer_canvas})
    love.graphics.clear(1,0,0)
    love.graphics.setDepthMode("lequal", true)

    love.graphics.setMeshCullMode("front")

    -- Terrain draw
    if view[view_index] == "3d_debug" then
        -- Draw terrain collision boxes
        for i, box in pairs(self.collisions) do
            box:draw(depthMapShader, light_camera, true)
        end
    else
        -- Draw tiles
        --tile_imesh:draw(depthMapShader, light_camera, true)
    end

    self.tiles:draw(depthMapShader, light_camera, true)

    --shadow_imesh:draw(depthMapShader, light_camera, true)

    love.graphics.setMeshCullMode("none")
    
    -- Entities draw
    player_1:draw(billboardShader, light_camera, true)
    --cursor_1:draw(depthMapShader, light_camera, true)

    for i, enemy in pairs(self.enemies) do
        enemy:draw(billboardShader, light_camera, true)
    end

    love.graphics.setMeshCullMode("back")

    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    if love.keyboard.isDown("l") then
        current_camera = light_camera
    else
        current_camera = main_camera
    end

    --Object render

    if dirLightShader:hasUniform("shadowProjectionMatrix") then
        dirLightShader:send("shadowProjectionMatrix", light_camera.projectionMatrix)
    end
    if dirLightShader:hasUniform("shadowViewMatrix") then
        dirLightShader:send("shadowViewMatrix", light_camera.viewMatrix)
    end
    if dirLightShader:hasUniform("shadowMapImage") then
        dirLightShader:send("shadowMapImage", shadow_buffer_canvas)
    end

    --3D draw
    love.graphics.setCanvas({GAME.main_canvas, depth=true})
    love.graphics.setDepthMode("lequal", true)

    love.graphics.clear(0.05, 0.0, 0.05)

    love.graphics.setMeshCullMode("none")

    if view[view_index] == "3d_debug" then
        -- Draw terrain collision boxes
        for i, box in pairs(self.collisions) do
            box:draw(dirLightShader, current_camera, false)
        end
    else
        -- Draw tiles
        self.tiles:draw(dirLightShader, current_camera, false)
    end

    self.projectile_imesh:draw(billboardShader, current_camera, false)

    self.particle_imesh:draw(billboardShader, current_camera, false)

    --shadow_imesh:draw(billboardShader, current_camera, false)

    player_1:draw(billboardShader, current_camera, false)

    for i, enemy in pairs(self.enemies) do
        enemy:draw(billboardShader, current_camera, false)
    end

    --cursor_1:draw(dirLightShader, current_camera, false)
end

function Scene_1:drawUI()
    player_1:screenDrawUI()

    for _, enemy in pairs(self.enemies) do
        enemy:screenDrawUI()
    end

    circle_1:screenDraw()
end

return Scene_1