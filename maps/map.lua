local Map = {}
Map.__index = Map

function Map:new(index)
    local self = setmetatable({}, Map)

    -- Index to know which map it is, and what to load on memory
    self.index = index

    --love:physics init
    self.WORLD = love.physics.newWorld(0, 0, true)
    self.WORLD:setCallbacks(beginContact, endContact, preSolve, postSolve)

    -- Fixture Category and Mask
    --1 -> Everything else
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
    --15 -> Unbreakable terrain (Floor 5)
    --16 -> Unbreakable terrain (Floor 6)

    -- Objects scripts ----------------------------------    
    local newBox = require(GAME.objects_directory.."/box")
    local newPolygon = require(GAME.objects_directory.."/polygon")
    local newDoor = require(GAME.maps_directory.."/door")

    local newPlayer = require(GAME.objects_directory.."/player")
    local newCircle = require(GAME.objects_directory.."/circle")

    local newEnemy_Slime = require(GAME.objects_directory.."/enemies/enemy_slime")
    local newProjectile_Simple = require(GAME.objects_directory.."/projectiles/projectile_simple")
    local newParticle_Damage = require(GAME.objects_directory.."/particles/particle_damage")
    local newParticle_Circle = require(GAME.objects_directory.."/particles/particle_circle")

    self.SPAWNFUNCTIONS = {}
    self.SPAWNFUNCTIONS["Player"] = newPlayer
    self.SPAWNFUNCTIONS["Circle"] = newCircle
    self.SPAWNFUNCTIONS["Box"] = newBox
    self.SPAWNFUNCTIONS["Door"] = newDoor
    self.SPAWNFUNCTIONS["Enemy_Slime"] = newEnemy_Slime
    self.SPAWNFUNCTIONS["Projectile_Simple"] = newProjectile_Simple
    self.SPAWNFUNCTIONS["Particle_Damage"] = newParticle_Damage
    self.SPAWNFUNCTIONS["Particle_Circle"] = newParticle_Circle

    self.SPAWNFUNCTIONS["enterSection"] = self.enterSection

    self.SPAWNQUEUE = {}
    self.DELETEQUEUE = {}

    -- Sections
    self.SECTIONS = {}

    -- All scenes that can be loaded
    local Scene_1 = require("maps/scenes/scene_1")

    self.SCENES = {}
    self.SCENES["Scene_1"] = Scene_1:new()

    return self
end


function Map:loadSections()
    -- Create all section objects that the map has and save them in memory
    local map_directory = GAME.maps_directory.."/"..tostring(self.index)
    local sections_directory = map_directory.."/sections"

    local files = love.filesystem.getDirectoryItems(sections_directory)
    for _, file_name in ipairs(files) do
        local scene_index = nil
        local section_index = tonumber(file_name)
        for line in love.filesystem.lines(sections_directory.."/"..file_name.."/data.dat") do
            local words = getTable(line)
            local object_name = words[1]
            table.remove(words, 1)
            if object_name == "Scene" then
                scene_index = tonumber(words[1])
            end
        end
        local Section = require("maps/section")
        local section_object = Section:new(self.index, section_index, scene_index)
        -- TODO: Section buffer for better use of memory, instead of having all map's sections loaded at ones
        section_object:loadSection()
        self.SECTIONS[section_index] = section_object
    end
end

function Map.enterSection(self, section_index, door_index)
    local previous_section = current_section
    if previous_section ~= nil then
        previous_section:exitSection()
    end
    current_section = self.SECTIONS[section_index]
    current_scene = self.SCENES["Scene_"..tostring(current_section.scene_index)]
    current_section:enterSection(door_index)
    player_1.body:setActive(true)
end

function Map:update(dt)
    -- Entities update
    self.WORLD:update(dt)

    local all_conts = self.WORLD:getContacts()
    for _, cont in pairs(all_conts) do
        if cont:isTouching() == true then
            local a, b = cont:getFixtures()
            if a:getCategory() == 6 and b:getCategory() == 6 then
                local user_a, user_b = a:getUserData(), b:getUserData()
                user_a:hitboxIsHit(user_b)
                user_b:hitboxIsHit(user_a)
            end
        end
    end    

    player_1:update(dt)
    GAME.cursor:update(dt)
    GAME.cursor:updateCoords(current_camera.target[1], current_camera.target[2], player_1.userData.position[3])
    circle_1:update(dt)

    current_section:update(dt)

    current_scene:update(dt)

    --Spawn the stuff from SPAWNQUEUE
    for i, spawn in pairs(self.SPAWNQUEUE) do
        obj = self.SPAWNFUNCTIONS[spawn["group"]](unpack(spawn["args"]))
        -- local words = {}
        -- for w in string.gmatch(spawn["group"], "([^_]+)") do
        --     table.insert(words, w)
        -- end
        -- local obj_type = words[1]
    end

    -- Projectiles update from current Scene
    for i = 1, current_section.projectile_imesh.instanced_count, 1 do
        current_section.projectiles[i]:update(dt)
    end

    -- Particles update from current Scene
    for i = 1, current_section.particle_imesh.instanced_count, 1 do
        current_section.particles[i]:update(dt)
    end

    --Delete the stuff from DELETEQUEUE
    for i, delete in pairs(self.DELETEQUEUE) do
        if delete["group"] == "Projectile" then
            current_section.projectiles[delete["index"]] = "empty"
        elseif delete["group"] == "Enemy" then
            table.remove(current_section.enemies, delete["index"])
        elseif delete["group"] == "Particle" then
            current_section.particles[delete["index"]] = "empty"
        end
    end

    self.SPAWNQUEUE = {}
    self.DELETEQUEUE = {}
end

function Map:draw()
    current_scene:draw()
end

function Map:drawUI()
    current_scene:drawUI()
end

function beginContact(a, b, contact)
    if a:getCategory() ~= 6 and b:getCategory() ~= 6 then
        local user_a, user_b = a:getUserData(), b:getUserData()
        user_a:gotHit(user_b)
        user_b:gotHit(user_a)
    end
    --print(a:getUserData().." colliding with "..b:getUserData().."\n")
end

function endContact(a, b, contact)
    if a:getCategory() ~= 6 and b:getCategory() ~= 6 then
        local user_a, user_b = a:getUserData(), b:getUserData()
        user_a:exitHit(user_b)
        user_b:exitHit(user_a)
    end
end

return Map