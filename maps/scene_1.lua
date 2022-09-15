local Scene = require("maps/scene")
local Scene_1 = Scene:new()

function Scene_1:new()
    local o = Scene:new()
    setmetatable(o, self)
    self.__index = self

    current_camera:moveCamera(0.625*16, -0.3125*16, 0)

    myShader_code = love.filesystem.read(GAME.shaders_directory.."/dir_light.glsl")
    myShader = love.graphics.newShader(myShader_code)

    myShader:sendColor("light_color", {239/255, 118/255, 98/255, 100/255})
    myShader:sendColor("shadow_color", {91/255, 152/255, 230/255, 168/255})
    myShader:send("light_direction", CURRENTLIGHT_VECTOR)
    myShader:send("light_ramp_tex", LIGHTRAMP_TEXTURE)

    depthMapShader_code = love.filesystem.read("assets/shaders/depth_map.glsl")
    depthMapShader = love.graphics.newShader(depthMapShader_code)

    billboardShader_code = love.filesystem.read("assets/shaders/billboard.glsl")
    billboardShader = love.graphics.newShader(billboardShader_code)

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

function Scene_1:onEnter(map_index, scene_index)

    local map_directory = GAME.maps_directory.."/"..tostring(map_index)
    local scene_directory = map_directory.."/sections/"..tostring(scene_index)

    -- Tiles object
    self.tiles = g3d.newModel(g3d.loadObj(scene_directory.."/tiles.obj", false, true), map_directory.."/tileatlas.png", {0,0,0}, {0,0,math.pi/2})

    -- Collision meshes

    for line in love.filesystem.lines(scene_directory.."/collisions.txt") do
        local words = {}
        for word in string.gmatch(line, "([^%s]+)") do
            table.insert(words, word)
        end
        if words[1] == "Box" then
            -- Read position and dimension (scale)
            local pos = {}
            for coord in string.gmatch(words[2], "([^,]+)") do
                table.insert(pos, coord)
            end
            local dim = {}
            for coord in string.gmatch(words[3], "([^,]+)") do
                table.insert(dim, coord)
            end
            -- Spawn a Box collision shape
            local model = g3d.newModel(g3d.loadObj(GAME.models_directory.."/unit_cube.obj", false, true), GAME.models_directory.."/no_texture.png", {pos[1], pos[2], pos[3]}, {0,0,0}, {dim[1], dim[2], dim[3]})
            local coll_category = 11 + pos[3]
            shape = current_map.SPAWNFUNCTIONS["Box"](pos[1], pos[2], pos[3], dim[1], dim[2], dim[3], model, coll_category)
        end

        table.insert(self.collisions, shape)

    end

    -- Entities with their respective data
    player_1:loadData({hp = 30, position = {80, 70, 100}})
    table.insert(self.enemies, current_map.SPAWNFUNCTIONS["Enemy_Slime"](120, 120, 100))
    local Door = require("maps/door")
    test_door = Door:new(24*10,16*0,16*1)
    -- Projectiles
    --Particles
end

function Scene_1:update(dt)

    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end

    test_door:update(dt)

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

    test_door:draw(billboardShader, light_camera, true)

    love.graphics.setMeshCullMode("back")

    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    if love.keyboard.isDown("l") then
        current_camera = light_camera
    else
        current_camera = main_camera
    end

    --Object render

    if myShader:hasUniform("shadowProjectionMatrix") then
        myShader:send("shadowProjectionMatrix", light_camera.projectionMatrix)
    end
    if myShader:hasUniform("shadowViewMatrix") then
        myShader:send("shadowViewMatrix", light_camera.viewMatrix)
    end
    if myShader:hasUniform("shadowMapImage") then
        myShader:send("shadowMapImage", shadow_buffer_canvas)
    end

    --3D draw
    love.graphics.setCanvas({GAME.main_canvas, depth=true})
    love.graphics.setDepthMode("lequal", true)

    love.graphics.clear(0.05, 0.0, 0.05)

    love.graphics.setMeshCullMode("none")

    if view[view_index] == "3d_debug" then
        -- Draw terrain collision boxes
        for i, box in pairs(self.collisions) do
            box:draw(myShader, current_camera, false)
        end
    else
        -- Draw tiles
        self.tiles:draw(myShader, current_camera, false)
    end

    self.projectile_imesh:draw(billboardShader, current_camera, false)

    self.particle_imesh:draw(billboardShader, current_camera, false)

    --shadow_imesh:draw(billboardShader, current_camera, false)

    player_1:draw(billboardShader, current_camera, false)

    test_door:draw(myShader, current_camera, false)

    for i, enemy in pairs(self.enemies) do
        enemy:draw(billboardShader, current_camera, false)
    end

    --cursor_1:draw(myShader, current_camera, false)
end

function Scene_1:drawUI()
    player_1:screenDrawUI()

    for _, enemy in pairs(self.enemies) do
        enemy:screenDrawUI()
    end

    circle_1:screenDraw()
end

return Scene_1