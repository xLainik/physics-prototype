local Map = {}
Map.__index = Map

function Map:new(index)
    local self = setmetatable({}, Map)

    self.index = index

    --love:physics init
    self.WORLD = love.physics.newWorld(0, 0, true)
    self.WORLD:setCallbacks(beginContact, endContact, preSolve, postSolve)

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

    -- Objects scripts ----------------------------------    
    local newBox = require("objects/box")
    local newPolygon = require("objects/polygon")
    local newEnemy_Slime = require("objects/enemies/enemy_Slime")
    local newProjectile_Simple = require("objects/projectiles/projectile_simple")
    local newParticle_Damage = require("objects/particles/particle_damage")
    local newParticle_Circle = require("objects/particles/particle_circle")

    self.SPAWNFUNCTIONS = {}
    self.SPAWNFUNCTIONS["Box"] = newBox
    self.SPAWNFUNCTIONS["Enemy_Slime"] = newEnemy_Slime
    self.SPAWNFUNCTIONS["Projectile_Simple"] = newProjectile_Simple
    self.SPAWNFUNCTIONS["Particle_Damage"] = newParticle_Damage
    self.SPAWNFUNCTIONS["Particle_Circle"] = newParticle_Circle

    self.SPAWNQUEUE = {}
    self.DELETEQUEUE = {}

    return self
end

function Map:update(dt)
    -- Entities update
    self.WORLD:update(dt)

    local all_conts = self.WORLD:getContacts()
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

    current_scene:update(dt)

    --Spawn the stuff from SPAWNQUEUE
    for i, spawn in pairs(self.SPAWNQUEUE) do
        obj = self.SPAWNFUNCTIONS[spawn["group"]](unpack(spawn["args"]))
        local words = {}
        for w in string.gmatch(spawn["group"], "([^_]+)") do
            table.insert(words, w)
        end
        local obj_type = words[1]
    end

    -- Projectiles update from current Scene
    for i = 1, current_scene.projectile_imesh.instanced_count, 1 do
        current_scene.projectiles[i]:update(dt)
    end

    -- Particles update from current Scene
    for i = 1, current_scene.particle_imesh.instanced_count, 1 do
        current_scene.particles[i]:update(dt)
    end

    --Delete the stuff from DELETEQUEUE
    for i, delete in pairs(self.DELETEQUEUE) do
        if delete["group"] == "Projectile" then
            current_scene.projectiles[delete["index"]] = "empty"
        elseif delete["group"] == "Enemy" then
            table.remove(current_scene.enemies, delete["index"])
        elseif delete["group"] == "Particle" then
            current_scene.particles[delete["index"]] = "empty"
        end
    end

    self.SPAWNQUEUE = {}
    self.DELETEQUEUE = {}
end

function Map:draw()
    current_scene:draw()
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

return Map