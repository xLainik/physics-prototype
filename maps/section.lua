local Section = {}
Section.__index = Section

function Section:new(map_index, section_index, scene_index)
    local self = setmetatable({}, Section)

    -- Index to know which Section it is, and to what map it belongs
    self.map_index = map_index
    self.index = section_index
    self.scene_index = scene_index

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

    self.doors = {}
    self.bounding_boxes = {}

   
    return self
end

function Section:loadSection()
    -- Load in memory all objects that the section has
    local map_directory = GAME.maps_directory.."/"..tostring(self.map_index)
    local section_directory = map_directory.."/sections/"..tostring(self.index)

    -- Tiles object
    self.tiles = g3d.newModel(g3d.loadObj(section_directory.."/tiles.obj", false, true), map_directory.."/tileatlas.png", {0,0,0}, {0,0,math.pi/2})

    -- Collision meshes

    for line in love.filesystem.lines(section_directory.."/collisions.dat") do
        local words = getTable(line)
        local object_name = words[1]
        table.remove(words, 1)
        if object_name == "SectionBoundingBox" then
            -- Read position and dimension (scale)
            local pos = getFormatedTable(getTable(words[1], "([^,]+)"))
            local dim = getFormatedTable(getTable(words[2], "([^,]+)"))
            local newBoundingBox = require(GAME.maps_directory.."/bounding_box")
            local x1, y1, x2, y2 = pos[1]*SCALE3D.x, (pos[2]+dim[2])*SCALE3D.y, (pos[1]+dim[1])*SCALE3D.x, pos[2]*SCALE3D.y
            local bounding_box = newBoundingBox(x1, y1, x2, y2)
            table.insert(self.bounding_boxes, bounding_box)
        elseif object_name == "Box" then
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

            table.insert(self.collisions, door)
            table.insert(self.doors, door)
        end
    end

    -- Load entities with their respective data
    --table.insert(self.enemies, current_map.SPAWNFUNCTIONS["Enemy_Slime"](120, 120, 100))
    -- Projectiles
    --Particles
end

function Section:enterSection(in_door_index)
    if in_door_index ~= nil then
        for _, door in pairs(self.doors) do
            if door.index == in_door_index then
                player_1.body:setPosition(door.userData.position[1]+door.direction[1]*SCALE3D.x, door.userData.position[2]+door.direction[2]*SCALE3D.y)
                player_1.userData.position = {player_1.body:getX(), player_1.body:getY(), door.userData.position[3] + 10}
            end
        end
    end
    -- Activate all bodies in the section
    for _, AABB in pairs(self.bounding_boxes) do
        AABB:activateBodies()
    end
    -- (DON't) Move the camera to where the player is suppose to be
    --current_camera:moveCamera(door.userData.position[1]/SCALE3D.x, door.userData.position[2]/SCALE3D.y, 0)
end

function Section:exitSection()
    -- DEactivate all bodies in the section
    for _, AABB in pairs(self.bounding_boxes) do
        AABB:deactivateBodies()
    end
end

function Section:update(dt)
    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
end

return Section