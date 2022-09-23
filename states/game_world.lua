
local State = require("states/state")
local GameWorld = State:new()

function GameWorld:new()
   local o = State:new()
   setmetatable(o, self)
   self.__index = self
   return o
end

function GameWorld:onEnter()

    love.graphics.setFont(GAME.FONT_SMALL)

    -- Import libraries
    g3d = require("libs/g3d")
    anim8 = require("libs/anim8")
    tree = require("libs/decision_tree")

    -- Random seed
    local RNG_SEED = os.time()
    print('Seeding RNG with: ' .. RNG_SEED)
    math.randomseed(RNG_SEED)

    SCALE3D = {x = 16, y = -16, z = 16} -- 16 love:physics unit = 16 pixeles = 1 g3d unit

    -- Debug canvas for drawing all active physics bodies
    debug_canvas = love.graphics.newCanvas(SCREENWIDTH, SCREENHEIGHT)
    debug_canvas:setFilter("nearest","nearest") --no atialiasing

    DEBUG_OFFSET = {0, 0}

    -- Main camera that follows the player around
    DISTMAINCAM = 10
    CAMVECTOR_MAIN = { 0 * DISTMAINCAM, -3 * DISTMAINCAM, 4 * DISTMAINCAM}

    main_camera = g3d.newCamera(SCREENWIDTH/SCREENHEIGHT)
    main_camera:lookAt(CAMVECTOR_MAIN[1], CAMVECTOR_MAIN[2], CAMVECTOR_MAIN[3], 0,0,0)
    main_camera:updateOrthographicMatrix((SCREENHEIGHT/2)/SCALE3D.x)

    current_camera = main_camera

    -- Light camera for shadow mapping
    shadow_buffer_canvas = love.graphics.newCanvas(SCREENWIDTH*1.50, SCREENWIDTH*1.50, {format="depth24", readable=true})
    shadow_buffer_canvas:setFilter("nearest","nearest")

    light_camera = g3d.newCamera(shadow_buffer_canvas:getWidth()/shadow_buffer_canvas:getHeight())

    -- All shaders
    local dirLightShader_code = love.filesystem.read(GAME.shaders_directory.."/dir_light.glsl")
    dirLightShader = love.graphics.newShader(dirLightShader_code)

    local depthMapShader_code = love.filesystem.read("assets/shaders/depth_map.glsl")
    depthMapShader = love.graphics.newShader(depthMapShader_code)

    local billboardShader_code = love.filesystem.read("assets/shaders/billboard.glsl")
    billboardShader = love.graphics.newShader(billboardShader_code)

    -- Load basic objects
    newInstancedMesh = require("libs/instanced_mesh")   
    newShadow = require("objects/shadow")
    newSprite = require("objects/sprite")

    -- Load data saved at source
    self.data = {}
    self:loadData()

    local Map = require("maps/map")

    -- Load Map
    current_map = Map:new(self.data["current_map"])
    current_map:loadSections()

    -- Deactivate all bodies in the whole map
    for _, section in pairs(current_map.SECTIONS) do
        for _, AABB in pairs(section.bounding_boxes) do
            AABB:deactivateBodies()
        end
    end

    -- Load Player and Circle (Entities that are always loaded)
    local newPlayer = require("objects/player")
    local newCircle = require("objects/circle")

    GAME.cursor:gameWorldEnter()
    player_1 = newPlayer(GAME.cursor)
    circle_1 = newCircle()

    player_1:loadData({hp = 100, position = {40, 100, 100}})

    -- Load Section
    --current_map:enterSection(1)

    --self:saveData()

    -- Debug collisions and 3d orbiting
    view = {"final_view", "hitbox_debug", "3d_debug"}
    view_index = 3
    view_timer = 0.1

    current_map.enterSection(current_map, 1, nil)

end

function GameWorld:onExit()
    --pass
end

function GameWorld:saveData()
    local table_ = {}
    for name, element in pairs(self.data) do
        local union = element
        if type(union) == "table" then
            union = table.concat(element, " ")
        end
        table.insert(table_, name.." "..union) 
    end
    local file = io.open(GAME.game_directory.."/data/save_2.dat", "w+")
    file:write(table.concat(table_, "\n"))
    file:close()
end

function GameWorld:loadData()
    local read_lines = {}
    for line in love.filesystem.lines("data/save_1.dat") do
        table.insert(read_lines, getTable(line))
    end
    for index, line in ipairs(read_lines) do
        local data_name = line[1]
        table.remove(line, 1)
        self.data[data_name] = getFormatedTable(line)
    end
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
        elseif love.keyboard.isDown("f11") then
            view_timer = 0
            GAME.main_canvas:newImageData():encode("png", "screen"..tostring(os.time())..".png")
            love.graphics.captureScreenshot("screen"..tostring(os.time()).."_scaled"..".png")
        end
    end

    if view[view_index] == "3d_debug" then
        love.mouse.setRelativeMode(true)
    else
        love.mouse.setRelativeMode(false)
    end

    if GAME.SCREEN_SHAKING > 0 then
        local random_x = math.random(2*GAME.SCREEN_SHAKING)
        local random_y = math.random(2*GAME.SCREEN_SHAKING)
        GAME.CANVAS_OFFSET[1] = GAME.CANVAS_OFFSET[1] + random_x
        GAME.CANVAS_OFFSET[2] = GAME.CANVAS_OFFSET[2] + random_y
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
        love.graphics.translate(unpack(DEBUG_OFFSET))

        for _, body in pairs(current_map.WORLD:getBodies()) do
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

end

function GameWorld:drawUI()
    -- Draw Entities/projectiles/particles UI from current Scene
    current_map:drawUI()

    -- Drawing debug stuff
    if view[view_index] == "hitbox_debug" then
        love.graphics.setColor(0.2,0.1,0.9,0.8)
        love.graphics.draw(debug_canvas, -16, -16, 0, WINDOWSCALE, WINDOWSCALE*0.8125, GAME.CANVAS_OFFSET[1], GAME.CANVAS_OFFSET[2])
    end

    -- Draw UI elements (Window size Resolution)
    love.graphics.setColor(244/255, 248/255, 255/255)
    love.graphics.print("FPS: "..tostring(FPS), 4*WINDOWSCALE, 4*WINDOWSCALE)
end

function love.mousemoved(x,y, dx,dy)

    if dx ~= 0 and dy ~= 0 and view[view_index] == "3d_debug" then
        current_camera:thirdPersonLook(dx,dy,  player_1.userData.position[1]/SCALE3D.x,  player_1.userData.position[2]/SCALE3D.y,  player_1.userData.position[3]/SCALE3D.z)
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        current_camera:updateOrthographicMatrix(current_camera.size - 0.1)
    elseif y < 0 then
        current_camera:updateOrthographicMatrix(current_camera.size + 0.1)
    end
end

function love.mousepressed( x, y, button, istouch, presses )
    --
end

return GameWorld