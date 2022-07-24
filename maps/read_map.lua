return function (path, uFlip, vFlip)
    local positions, uvs, normals, faces = {}, {}, {}, {}
    local result = {}
    local name = false

    -- go line by line through the file
    for line in love.filesystem.lines(path) do
        local words = {}

        -- split the line into words
        for word in line:gmatch "([^%s]+)" do
            table.insert(words, word)
        end

        local firstWord = words[1]

        -- if the first word in this line is a "o", then this defines an object
        if firstWord == "o" then
            -- check if there was an object before
            if name then
                result[name] = faces
            end
            name = words[2]
            faces = {}
        end

        if firstWord == "v" then
            -- if the first word in this line is a "v", then this defines a vertex's position

            table.insert(positions, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
        elseif firstWord == "vt" then
            -- if the first word in this line is a "vt", then this defines a texture coordinate

            local u, v = tonumber(words[2]), tonumber(words[3])

            -- optionally flip these texture coordinates
            if uFlip then u = 1 - u end
            if vFlip then v = 1 - v end

            table.insert(uvs, {u, v})
        elseif firstWord == "vn" then
            -- if the first word in this line is a "vn", then this defines a vertex normal

            table.insert(normals, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
        elseif firstWord == "f" then
            -- if the first word in this line is a "f", then this is a face
            -- a face takes three point definitions
            -- the arguments a point definition takes are vertex, vertex texture, vertex normal in that order

            assert(#words == 4, ("Faces in level %s must be triangulated before they can be loaded!"):format(path))

            for i=2, #words do
                local v, vt, vn = words[i]:match "(%d+)/(%d+)/(%d+)"
                v, vt, vn = tonumber(v), tonumber(vt), tonumber(vn)
                local vert = {
                    positions[v][1],
                    positions[v][2],
                    positions[v][3],
                    uvs[vt][1],
                    uvs[vt][2],
                    normals[vn][1],
                    normals[vn][2],
                    normals[vn][3],
                }
                table.insert(faces, vert)
            end
        end
    end
    -- insert last object
    result[name] = faces

    return result
end