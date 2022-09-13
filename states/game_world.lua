
local State = require("states/state")

local GameWorld = State:new()

function GameWorld:new()
   local o = State:new()
   setmetatable(o, self)
   self.__index = self
   return o
end

function GameWorld:onEnter()

    love.graphics.setFont(FONT_SMALL)

    --love:physics init
    WORLD = love.physics.newWorld(0, 0, true)
    WORLD:setCallbacks(beginContact, endContact, preSolve, postSolve)

    SCALE3D = {x = 16, y = -16, z = 16} -- 16 love:physics unit = 1 g3d unit

    SCREENSCALE = 16 -- 16 is 1 pixel of texture = 1 screen pixel

    love.graphics.setDefaultFilter("nearest") --no atialiasing
    debug_canvas = love.graphics.newCanvas(SCREENWIDTH, SCREENHEIGHT)
    debug_canvas:setFilter("nearest","nearest") --no atialiasing
    main_canvas = love.graphics.newCanvas(SCREENWIDTH, SCREENHEIGHT)
    main_canvas:setFilter("nearest","nearest") --no atialiasing

    DEBUG_OFFSET = {0, 0}

    shadow_buffer_canvas = love.graphics.newCanvas(SCREENWIDTH*1.50, SCREENWIDTH*1.50, {format="depth24", readable=true})
    shadow_buffer_canvas:setFilter("nearest","nearest")
    --variance_shadow_canvas = love.graphics.newCanvas(SCREENWIDTH, SCREENWIDTH, {format="depth24", readable=true})
    --variance_shadow_canvas:setFilter("linear","linear")

    CAM_OFFSET = {0, 0}

    DISTLIGHTCAM = 20
    DISTMAINCAM = 10
    CAMVECTOR_MAIN = { 0 * DISTMAINCAM, -3 * DISTMAINCAM, 4 * DISTMAINCAM}
    LIGHTVECTOR_TOP = { 0, -0.00001, 1 * DISTLIGHTCAM} -- in g3d units
    LIGHTVECTOR_LF = {-0.404508497 * DISTLIGHTCAM, -0.700629269 * DISTLIGHTCAM, 0.587785252 * DISTLIGHTCAM} -- in g3d units
    LIGHTVECTOR_ANGLE = { 0 * DISTMAINCAM, -1 * DISTMAINCAM, 1 * DISTMAINCAM}
    CURRENTLIGHT_VECTOR = LIGHTVECTOR_LF

    LIGHTRAMP_TEXTURE = love.graphics.newImage("assets/shaders/light_ramp.png")

    main_camera = g3d.newCamera(SCREENWIDTH/SCREENHEIGHT)
    main_camera:lookAt(CAMVECTOR_MAIN[1], CAMVECTOR_MAIN[2], CAMVECTOR_MAIN[3], 0,0,0)
    main_camera:updateOrthographicMatrix((SCREENHEIGHT/2)/SCREENSCALE)

    light_camera = g3d.newCamera(shadow_buffer_canvas:getWidth()/shadow_buffer_canvas:getHeight())
    light_camera:lookAt(CURRENTLIGHT_VECTOR[1], CURRENTLIGHT_VECTOR[2], CURRENTLIGHT_VECTOR[3], 0, 0, 0)
    light_camera:updateOrthographicMatrix((SCREENWIDTH/2)/SCALE3D.x)

    current_camera = main_camera

    current_camera:moveCamera(0.625*16, -0.3125*16, 0)

    myShader_code = love.filesystem.read("assets/shaders/test_shader_8.glsl")
    myShader = love.graphics.newShader(myShader_code)

    myShader:sendColor("light_color", {239/255, 118/255, 98/255, 100/255})
    myShader:sendColor("shadow_color", {91/255, 152/255, 230/255, 168/255})
    myShader:send("light_direction", CURRENTLIGHT_VECTOR)
    myShader:send("light_ramp_tex", LIGHTRAMP_TEXTURE)

    depthMapShader_code = love.filesystem.read("assets/shaders/depth_map.glsl")
    depthMapShader = love.graphics.newShader(depthMapShader_code)

    billboardShader_code = love.filesystem.read("assets/shaders/billboard.glsl")
    billboardShader = love.graphics.newShader(billboardShader_code)

    -- Random seed
    local RNG_SEED = os.time()
    print('Seeding RNG with: ' .. RNG_SEED)
    math.randomseed(RNG_SEED)

    -- Fixture Category and Mask
    --1 -> Everything else (Shadows and projectiles for now)
    --2 -> Player 
    --3 -> Enemies 1
    --4 -> Enemies 2
    --5 -> NPCs
    --6 -> Entities Hitboxes 1
    --7 -> Entities Hitboxes 2
    --8 -> 
    --9 -> 
    --10 -> Unbreakable terrain (Floor 0 - Barriers)
    --11 -> Unbreakable terrain (Floor 1)
    --12 -> Unbreakable terrain (Floor 2)
    --13 -> Unbreakable terrain (Floor 3)
    --14 -> Unbreakable terrain (Floor 4)

    local newPlayer = require("objects/player")
    local newCursor = require("objects/cursor")
    local newEnemy_Slime = require("objects/enemies/enemy_Slime")
    local newBox = require("objects/box")
    local newPolygon = require("objects/polygon")
    local newCircle = require("objects/circle")
    local newProjectile_Simple = require("objects/projectiles/projectile_simple")
    local newParticle_Damage = require("objects/particles/particle_damage")
    local newParticle_Circle = require("objects/particles/particle_circle")

    newInstancedMesh = require("objects/instanced_mesh")
    newShadow = require("objects/shadow")
    newSprite = require("objects/sprite")

    SPAWNFUNCTIONS = {}
    SPAWNFUNCTIONS["Enemy_Slime"] = newEnemy_Slime
    SPAWNFUNCTIONS["Projectile_Simple"] = newProjectile_Simple
    SPAWNFUNCTIONS["Particle_Damage"] = newParticle_Damage
    SPAWNFUNCTIONS["Particle_Circle"] = newParticle_Circle
    SPAWNFUNCTIONS["Box"] = newBox

    SPAWNQUEUE = {}
    DELETEQUEUE = {}

    --shadow_imesh = newInstancedMesh(200, g3d.loadObj("assets/3d/unit_disc_2.obj", false, true), "assets/3d/no_texture.png", 16, 16)

    cursor_1 = newCursor()
    love.mouse.setVisible(false)
    player_1 = newPlayer(70, 95, 100, cursor_1)

    view = {"final_view", "hitbox_debug", "3d_debug"}
    view_index = 1
    view_timer = 0.1

    enemies = {}
    table.insert(enemies, newEnemy_Slime(120, 120, 100))
    table.insert(enemies, newEnemy_Slime(220, 160, 100))

    circle_1 = newCircle(30, 30, 8, 20)

    projectile_imesh = newInstancedMesh(600, "plane", "assets/2d/projectiles/projectiles.png", 16, 16)
    projectiles = {}
    for index = 1, projectile_imesh.max_instances, 1 do
        projectiles[index] = "empty"
    end

    particle_imesh = newInstancedMesh(400, "plane", "assets/2d/particles/particles.png", 16, 16)
    particles = {}
    for index = 1, particle_imesh.max_instances, 1 do
        particles[index] = "empty"
    end

    --Level loader
    collisions = {}

    for line in love.filesystem.lines("maps/Test/test_map.txt") do
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
            local model = g3d.newModel(g3d.loadObj("assets/3d/unit_cube.obj", false, true), "assets/3d/no_texture.png", {pos[1], pos[2], pos[3]}, {0,0,0}, {dim[1], dim[2], dim[3]})
            local coll_category = 11 + pos[3]
            shape = newBox(pos[1], pos[2], pos[3], dim[1], dim[2], dim[3], model, coll_category)
        end

        table.insert(collisions, shape)

    end

    -- Tiles
    tiles = g3d.newModel(g3d.loadObj("maps/Test/Test map.obj", false, true), "maps/Test/tileset.png", {0,0,0}, {0,0,math.pi/2})

    -- local newTile = require("objects/tile")

    -- -- Read tiled layers for hitboxes and tile placement
    -- for i, group in pairs(gameMap.layers) do
    --  if group.type == "group" then -- Groups (Floors)
    --      local floor_tiles = {}
    --      local words = {}
    --      for w in string.gmatch(group.name, "([^%s]+)") do
    --          table.insert(words, w)
    --      end
    --      local floor_number = tonumber(words[2])
    --      for i, sublayer in pairs(group.layers) do
    --          if sublayer.type == "objectgroup" then -- Hitboxes
    --              coll_category = 10 + floor_number
    --              floor_table = {}
    --              for i, obj in pairs(sublayer.objects) do
    --                  if obj.shape == "rectangle" then
    --                      local model = g3d.newModel(g3d.loadObj("assets/3d/unit_cube_front_top_3.obj", false, true), "assets/3d/front_top_texture_2.png", {obj.x/SCALE3D.x, obj.y/SCALE3D.y, layer_height}, {0,0,0}, {obj.width/SCALE3D.x, obj.height/SCALE3D.y, depth/SCALE3D.z})
    --                      shape = newBox(obj.x, obj.y, layer_height, obj.width, obj.height, depth, model, coll_category)
    --                  elseif  obj.shape == "polygon" then
    --                      local model = g3d.newModel(g3d.loadObj("assets/3d/unit_cube_front_top.obj", false, true), "assets/3d/white_texture.png", {obj.x/SCALE3D.x, obj.y/SCALE3D.y, layer_height}, {0,0,0}, {20/SCALE3D.x, 20/SCALE3D.y, 20/SCALE3D.z})
    --                      shape = newPolygon(obj.x, obj.y, layer_height, obj.polygon, model, coll_category)
    --                  end
    --                  table.insert(floor_table, shape)
    --              end
    --              layer_height = layer_height + SCALE3D.z
    --              collisions[2+floor_number] = floor_table
    --          end
    --          if sublayer.type == "tilelayer" and sublayer.visible == true then -- Tiles
    --              --print("FLOOR NUMBER: ", floor_number)
    --              for y_tile = 1, tilesets[1].mapheight, 1 do
    --                  for x_tile = 1, tilesets[1].mapwidth, 1 do
    --                      local tile_id = sublayer.data[tilesets[1].mapwidth*(y_tile-1)+x_tile]
    --                      if tile_id ~= 0 then
    --                          local tileset_y = math.ceil(tile_id/(tilesets[1].image:getWidth()/tilesets[1].tilewidth)) - 1
    --                          local tileset_x = (tile_id - (tileset_y*(tilesets[1].image:getWidth()/tilesets[1].tilewidth))) - 1
    --                          local x_trans = tileset_x*tilesets[1].tilewidth
    --                          local y_trans = tileset_y*tilesets[1].tileheight

    --                          local quad = love.graphics.newQuad(x_trans, y_trans, tilesets[1].tilewidth, tilesets[1].tileheight, tilesets[1].image:getDimensions())
    --                          -- Add tile to the instance table (in g3d units)
    --                          local x, y, z = x_tile-0.5, -(y_tile-0.5), (floor_number-1)+0.5
    --                          local u, v = x_trans/tilesets[1].image:getWidth(), y_trans/tilesets[1].image:getHeight()
    --                          local instance_index = tile_imesh:addInstance(x,y,z, 1,1,1, u,v)
    --                          local tile = newTile((x_tile-1)*tilesets[1].tilewidth, (y_tile-1)*tilesets[1].tileheight, layer_height, instance_index)
    --                          table.insert(floor_tiles, tile)
    --                      end
    --                  end
    --              end
    --              tiles[floor_number] = floor_tiles
    --          end
    --      end
    --  end
    -- end
end

function GameWorld:onExit()
    --pass
end

function GameWorld:update(dt)

    --Switch views
    if view_timer < 0.1 then
        view_timer = view_timer + dt
    else
        if love.keyboard.isDown("k") then
            view_timer = 0
            if view_index < 3 then
                view_index = view_index + 1
            else
                view_index = 1
            end
        elseif love.keyboard.isDown("p") then
            view_timer = 0
        elseif love.keyboard.isDown("t") then
            view_timer = 0
            --print(#tile_imesh.instanced_positions)
            --tile_imesh:addInstance({math.random(1, 10),math.random(-10, -1),1}, {0,0})
            local remove_index = math.random(1, projectile_imesh.instanced_count)
            --print("remove index: ", remove_index)
            table.insert(DELETEQUEUE, {group = "Projectile", index = remove_index})
        elseif love.keyboard.isDown("f11") then
            view_timer = 0
            main_canvas:newImageData():encode("png", "screen"..tostring(os.time())..".png")
            love.graphics.captureScreenshot("screen"..tostring(os.time()).."_scaled"..".png")
        end
    end

    if view[view_index] == "3d_debug" then
        love.mouse.setRelativeMode(true)
    else
        love.mouse.setRelativeMode(false)
    end

    -- Entities update
    WORLD:update(dt)

    local all_conts = WORLD:getContacts()
    for _, cont in pairs(all_conts) do
        if cont:isTouching() == true then
            local a, b = cont:getFixtures()
            local user_a, user_b = a:getUserData(), b:getUserData()
            if a:getCategory() == 6 then
                user_a:hitboxIsHit(user_b)
            end
            if b:getCategory() == 6 then
                user_b:hitboxIsHit(user_a)
            end
        end
    end

    player_1:update(dt)
    cursor_1:update(dt)
    cursor_1:updateCoords(current_camera.target[1], current_camera.target[2], player_1.z)
    circle_1:update(dt)

    for i, enemy in ipairs(enemies) do
        enemy:update(dt)
    end
    
    --Spawn the stuff from SPAWNQUEUE
    for i, spawn in pairs(SPAWNQUEUE) do
        obj = SPAWNFUNCTIONS[spawn["group"]](unpack(spawn["args"]))
        local words = {}
        for w in string.gmatch(spawn["group"], "([^_]+)") do
            table.insert(words, w)
        end
        local obj_type = words[1]
    end

    -- Projectiles update
    for i = 1, projectile_imesh.instanced_count, 1 do
        projectiles[i]:update(dt)
    end

    -- Particles update
    for i = 1, particle_imesh.instanced_count, 1 do
        particles[i]:update(dt)
    end

    --Delete the stuff from DELETEQUEUE
    for i, delete in pairs(DELETEQUEUE) do
        if delete["group"] == "Projectile" then
            projectiles[delete["index"]] = "empty"
        elseif delete["group"] == "Enemy" then
            table.remove(enemies, delete["index"])
        elseif delete["group"] == "Particle" then
            particles[delete["index"]] = "empty"
        end
    end

    --print(#enemies)

    SPAWNQUEUE = {}
    DELETEQUEUE = {}

    --3D Cam update

    -- local l_cam_dx, l_cam_dy = 0, 0

    -- if love.keyboard.isDown("h") then
    --  l_cam_dy = 0.0625
    -- elseif love.keyboard.isDown("n") then
    --  l_cam_dy = -0.0625
    -- end
    -- if love.keyboard.isDown("b") then
    --  l_cam_dx = 0.0625
    -- elseif love.keyboard.isDown("m") then
    --  l_cam_dx = -0.0625
    -- end

    -- --light grid = { 1/16 } in g3d units

    -- --camera grid = { 0.0625 = 1/16, 0.3125 = 5/16, 0.3125 = 5/16 } in g3d units
    -- cam_grid_pos = { math.floor((player_1.x/SCALE3D.x) / 0.0625)*0.0625, math.floor((player_1.y/SCALE3D.y) / 0.3125)*0.3125, math.floor((player_1.z/SCALE3D.z) / 0.3125)*0.3125 }

    -- local cam_dx, cam_dy = 0, 0

    -- if love.keyboard.isDown("up") then
    --  cam_dy = 0.3125
    --  cam_dy = 0.05
    -- elseif love.keyboard.isDown("down") then
    --  cam_dy = -0.3125
    --  cam_dy = -0.05
    -- end
    -- if love.keyboard.isDown("right") then
    --  cam_dx = 0.625
    --  cam_dx = 0.05
    -- elseif love.keyboard.isDown("left") then
    --  cam_dx = -0.625
    --  cam_dx = -0.05
    -- end

    --main_camera:followPoint(player_1.x/SCALE3D.x, player_1.y/SCALE3D.y)
    CAM_OFFSET = main_camera:followPointOffset(player_1.x/SCALE3D.x, player_1.y/SCALE3D.y)

    light_camera:followPointOffset(player_1.x/SCALE3D.x, player_1.y/SCALE3D.y)

    --main_camera:moveCamera(cam_dx, cam_dy, 0)
    --light_camera:moveCamera(l_cam_dx, l_cam_dy, 0)

    if SCREEN_SHAKING > 0 then
        local random_x = math.random(2*SCREEN_SHAKING)
        local random_y = math.random(2*SCREEN_SHAKING)
        CAM_OFFSET[1] = CAM_OFFSET[1] + random_x
        CAM_OFFSET[2] = CAM_OFFSET[2] + random_y
    end
end

function GameWorld:draw()
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
        for i, box in pairs(collisions) do
            box:draw(depthMapShader, light_camera, true)
        end
    else
        -- Draw tiles
        --tile_imesh:draw(depthMapShader, light_camera, true)
    end

    tiles:draw(depthMapShader, light_camera, true)

    --shadow_imesh:draw(depthMapShader, light_camera, true)

    love.graphics.setMeshCullMode("none")
    
    -- Entities draw
    player_1:draw(billboardShader, light_camera, true)
    --cursor_1:draw(depthMapShader, light_camera, true)

    for i, enemy in pairs(enemies) do
        enemy:draw(billboardShader, light_camera, true)
    end

    love.graphics.setMeshCullMode("back")

 --    for i, projectile in pairs(projectiles) do
    --  projectile:draw(depthMapShader, light_camera, true)
    -- end

    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    -- if true then
    --     love.graphics.setCanvas{canvas, depth=24}
    --     love.graphics.clear(1,1,1)
    -- end

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
    love.graphics.setCanvas({main_canvas, depth=true})
    love.graphics.setDepthMode("lequal", true)

    love.graphics.clear(0.05, 0.0, 0.05)

    love.graphics.setMeshCullMode("none")

    if view[view_index] == "3d_debug" then
        -- Draw terrain collision boxes
        for i, box in pairs(collisions) do
            box:draw(myShader, current_camera, false)
        end
    else
        -- Draw tiles
        --tile_imesh:draw(myShader, current_camera, false)
        tiles:draw(myShader, current_camera, false)
    end

    projectile_imesh:draw(billboardShader, current_camera, false)

    particle_imesh:draw(billboardShader, current_camera, false)
    --particle_L_imesh:draw(billboardShader, current_camera, false)

    --shadow_imesh:draw(billboardShader, current_camera, false)

    player_1:draw(billboardShader, current_camera, false)

    for i, enemy in pairs(enemies) do
        enemy:draw(billboardShader, current_camera, false)
    end

    --cursor_1:draw(myShader, current_camera, false)

    if view[view_index] == "hitbox_debug" then
        -- Draw Flat hitboxes (projectiles and attack hitboxes)
        love.graphics.setDepthMode()
        love.graphics.setCanvas(debug_canvas)

        love.graphics.clear(0.0, 0.0, 0.0, 0.4)

        DEBUG_OFFSET = {-current_camera.target[1]*16 + 229, current_camera.target[2]*13 + 136}
        love.graphics.push()
        love.graphics.translate( unpack(DEBUG_OFFSET) )

        -- player_1:debugDraw()
        -- enemy_1:debugDraw()

        -- for _, projectile in pairs(projectiles) do
     --     projectile:debugDraw()
     --    end

     --    for i, box in pairs(collisions) do
     --     if box.fixture:getCategory() == 10 then
        --      box:debugDraw()
        --  end
        -- end

        for _, body in pairs(WORLD:getBodies()) do
            for _, fixture in pairs(body:getFixtures()) do
                if true then
                    local shape = fixture:getShape()
                    love.graphics.setLineWidth(1)
                    if shape:typeOf("CircleShape") then
                        local cx, cy = body:getWorldPoints(shape:getPoint())
                        love.graphics.circle("line", cx, cy, shape:getRadius())
                    elseif shape:typeOf("PolygonShape") then
                        love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
                    else
                        love.graphics.line(body:getWorldPoints(shape:getPoints()))
                    end
                end
            end
        end

        love.graphics.pop()
    end

    -- Draw UI elements (Original Resolution)
    love.graphics.setDepthMode()
    love.graphics.setCanvas(main_canvas)

    love.graphics.setCanvas()
    --print(unpack(CAM_OFFSET))
    
    love.graphics.draw(main_canvas, -16, -16, 0, WINDOWSCALE, WINDOWSCALE, CAM_OFFSET[1], CAM_OFFSET[2])
    
    if view[view_index] == "hitbox_debug" then
        love.graphics.draw(debug_canvas, -16, -16, 0, WINDOWSCALE, WINDOWSCALE*0.8125, CAM_OFFSET[1], CAM_OFFSET[2])
    end

    -- Draw UI elements (Window size Resolution)
    love.graphics.setColor(244/255, 248/255, 255/255)
    love.graphics.print("FPS: "..tostring(FPS), 4*WINDOWSCALE, 4*WINDOWSCALE)

    --player_1:debugDraw()

    player_1:screenDrawUI()

    for _, enemy in pairs(enemies) do
        enemy:screenDrawUI()
    end

    circle_1:screenDraw()
    cursor_1:screenDraw()
end

function beginContact(a, b, contact)
    local user_a = a:getUserData()
    local user_b = b:getUserData()
    if a:getCategory() == 6 then
        user_a:hitboxGotHit(user_b)
    else
        user_a:gotHit(user_b)
    end
    if b:getCategory() == 6 then
        user_b:hitboxGotHit(user_a)
    else
        user_b:gotHit(user_a)
    end
    --print(a:getUserData().." colliding with "..b:getUserData().."\n")
end

function endContact(a, b, contact)
    local user_a = a:getUserData()
    local user_b = b:getUserData()
    if a:getCategory() == 6 then
        user_a:hitboxExitHit(user_b)
    else
        user_a:exitHit(user_b)
    end
    if b:getCategory() == 6 then
        user_b:hitboxExitHit(user_a)
    else
        user_b:exitHit(user_a)
    end
end

-- function love.mousemoved(x,y, dx,dy)

--     if dx ~= 0 and dy ~= 0 and view[view_index] == "3d_debug" then
--         current_camera:thirdPersonLook(dx,dy,player_1.x/SCALE3D.x, player_1.y/SCALE3D.y, player_1.z/SCALE3D.z)
--     end
-- end

-- function love.wheelmoved(x, y)
--     if y > 0 then
--         current_camera:updateOrthographicMatrix(current_camera.size - 0.1)
--     elseif y < 0 then
--         current_camera:updateOrthographicMatrix(current_camera.size + 0.1)
--     end
-- end

-- function love.mousepressed( x, y, button, istouch, presses )
--     --
-- end

return GameWorld