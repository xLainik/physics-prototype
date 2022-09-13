
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

    -- Import libraries
    g3d = require("libs/g3d")
    anim8 = require("libs/anim8")
    tree = require("libs/decision_tree")

    -- Random seed
    local RNG_SEED = os.time()
    print('Seeding RNG with: ' .. RNG_SEED)
    math.randomseed(RNG_SEED)

    SCALE3D = {x = 16, y = -16, z = 16} -- 16 love:physics unit = 16 pixeles = 1 g3d unit

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
    main_camera:updateOrthographicMatrix((SCREENHEIGHT/2)/SCALE3D.x)

    light_camera = g3d.newCamera(shadow_buffer_canvas:getWidth()/shadow_buffer_canvas:getHeight())
    light_camera:lookAt(CURRENTLIGHT_VECTOR[1], CURRENTLIGHT_VECTOR[2], CURRENTLIGHT_VECTOR[3], 0, 0, 0)
    light_camera:updateOrthographicMatrix((SCREENWIDTH/2)/SCALE3D.x)

    current_camera = main_camera

    -- Load basic objects
    newInstancedMesh = require("libs/instanced_mesh")   
    newShadow = require("objects/shadow")
    newSprite = require("objects/sprite")

    TOTAL_MAPS = 1
    Map = require("maps/map")
    Scene = require("maps/scene")

    -- Load Map
    current_map = Map:new(1)

    -- Load First Scene
    current_scene = Scene:new(1)

    -- Load Player, Cursor and Circle
    local newPlayer = require("objects/player")
    local newCursor = require("objects/cursor")
    local newCircle = require("objects/circle")

    love.mouse.setVisible(false)

    cursor_1 = newCursor()
    player_1 = newPlayer(70, 95, 100, cursor_1)
    circle_1 = newCircle(30, 30, 8, 20)

    view = {"final_view", "hitbox_debug", "3d_debug"}
    view_index = 1
    view_timer = 0.1

end

function GameWorld:onExit()
    --pass
end

function GameWorld:update(dt)

    -- Update current Map 
    current_map:update(dt)

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

    --3D Cam update
    CAM_OFFSET = main_camera:followPointOffset(player_1.x/SCALE3D.x, player_1.y/SCALE3D.y)

    light_camera:followPointOffset(player_1.x/SCALE3D.x, player_1.y/SCALE3D.y)

    if SCREEN_SHAKING > 0 then
        local random_x = math.random(2*SCREEN_SHAKING)
        local random_y = math.random(2*SCREEN_SHAKING)
        CAM_OFFSET[1] = CAM_OFFSET[1] + random_x
        CAM_OFFSET[2] = CAM_OFFSET[2] + random_y
    end
end

function GameWorld:draw()
    -- Draw current map
    current_map:draw()

    if view[view_index] == "hitbox_debug" then
        -- Draw Flat hitboxes (projectiles and attack hitboxes)
        love.graphics.setDepthMode()
        love.graphics.setCanvas(debug_canvas)

        love.graphics.clear(0.0, 0.0, 0.0, 0.4)

        DEBUG_OFFSET = {-current_camera.target[1]*16 + 229, current_camera.target[2]*13 + 136}
        love.graphics.push()
        love.graphics.translate( unpack(DEBUG_OFFSET) )


        for _, body in pairs(WORLD:getBodies()) do
            if body:isActive() == true then
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

    -- Draw Entities/projectiles/particles UI from current Scene
    current_scene:drawUI()

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