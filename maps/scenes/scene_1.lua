local Scene = require("maps/scene")
local Scene_1 = Scene:new()

function Scene_1:new()
    local o = Scene:new()
    setmetatable(o, self)
    self.__index = self

    -- Light camera for shadow mapping
    local DISTLIGHTCAM = 20

    local LIGHTVECTOR_TOP = { 0, -0.00001, 1 * DISTLIGHTCAM} -- in g3d units
    local LIGHTVECTOR_LF = {-0.404508497 * DISTLIGHTCAM, -0.700629269 * DISTLIGHTCAM, 0.587785252 * DISTLIGHTCAM} -- in g3d units
    local LIGHTVECTOR_FRONT = { 0 * DISTMAINCAM, -2 * DISTMAINCAM, 1 * DISTMAINCAM}
    self.CURRENTLIGHT_VECTOR = LIGHTVECTOR_LF

    -- Shader uniforms 
    self.LIGHTRAMP_TEXTURE = love.graphics.newImage("maps/scenes/light_ramp_1.png")
    self.LIGHT_COLOR = {239/255, 118/255, 98/255, 100/255}
    self.SHADOW_COLOR = {91/255, 152/255, 230/255, 168/255}

    light_camera:lookAt(self.CURRENTLIGHT_VECTOR[1], self.CURRENTLIGHT_VECTOR[2], self.CURRENTLIGHT_VECTOR[3], 0, 0, 0)
    light_camera:updateOrthographicMatrix((SCREENWIDTH/2)/SCALE3D.x)

    -- TODO: color grading

    self:updateShader()

    return o
end

function Scene_1:updateShader()
    dirLightShader:sendColor("light_color", self.LIGHT_COLOR)
    dirLightShader:sendColor("shadow_color", self.SHADOW_COLOR)
    dirLightShader:send("light_direction", self.CURRENTLIGHT_VECTOR)
    dirLightShader:send("light_ramp_tex", self.LIGHTRAMP_TEXTURE)
end

function Scene_1:update(dt)
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
        for i, box in pairs(current_section.collisions) do
            box:draw(depthMapShader, light_camera, true)
        end
    else
        -- Draw tiles
        --tile_imesh:draw(depthMapShader, light_camera, true)
    end

    current_section.tiles:draw(depthMapShader, light_camera, true)

    --shadow_imesh:draw(depthMapShader, light_camera, true)

    love.graphics.setMeshCullMode("none")
    
    -- Entities draw
    player_1:draw(billboardShader, light_camera, true)
    --cursor_1:draw(depthMapShader, light_camera, true)

    for i, enemy in pairs(current_section.enemies) do
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
        for i, box in pairs(current_section.collisions) do
            box:draw(dirLightShader, current_camera, false)
        end
    else
        -- Draw tiles
        current_section.tiles:draw(dirLightShader, current_camera, false)
    end

    current_section.projectile_imesh:draw(billboardShader, current_camera, false)

    current_section.particle_imesh:draw(billboardShader, current_camera, false)

    --shadow_imesh:draw(billboardShader, current_camera, false)

    player_1:draw(billboardShader, current_camera, false)

    for i, enemy in pairs(current_section.enemies) do
        enemy:draw(billboardShader, current_camera, false)
    end

    --cursor_1:draw(dirLightShader, current_camera, false)
end

function Scene_1:drawUI()
    player_1:screenDrawUI()

    for _, enemy in pairs(current_section.enemies) do
        enemy:screenDrawUI()
    end

    circle_1:screenDraw()
end

return Scene_1