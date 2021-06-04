local blockAliases = {};
blockAliases["."] = "air";
blockAliases["@"] = "spacetravelships:ship_core";
blockAliases["1"] = "spacetravelships:ship_hull_light";
blockAliases["e"] = "spacetravelships:emergency_light";
blockAliases["g"] = "spacetravelships:illuminator";

local modPath = minetest.get_modpath("spacetravelmap");

local function placeNode(position, alias)
    local nodeName = blockAliases[""..alias];
    if (nodeName == nil) then
        error("Unknown block alias: "..alias, 2);
    end
    minetest.set_node(position, {name = nodeName});
end

local function fileExists(file)
    local f = io.open(file, "rb");
    if f then f:close() end
    return f ~= nil;
end

local function readFile(path)
    if (not fileExists(path)) then 
        return nil;
    end
    local lines = {};
    for line in io.lines(path) do
        lines[#lines + 1] = line;
    end
    return lines;
end

local function loadBuilding(path)
    local lines = readFile(path);
    if (lines == nil) then
        return nil;
    end

    local size = {
        x = tonumber(lines[1]),
        y = tonumber(lines[2]),
        z = tonumber(lines[3]),
    };

    local lineIndex = 4;
    local map = {};
    for y = 1, size.y do
        map[y] = {};
        for x = 1, size.x do
            map[y][x] = {};
            local line = lines[lineIndex];
            for z = 1, size.z do
                local symbol = line:sub(z, z);
                map[y][x][z] = symbol;
            end
            lineIndex = lineIndex + 1;
        end
        lineIndex = lineIndex + 1; -- Skipping extra line between layers
    end

    return {
        size = size,
        map = map
    };
end

local function writeMap(map)
    local file = io.open(minetest.get_worldpath().."/map.txt", "w")
	if file then
		file:write(minetest.serialize(map))
		file:close()
	end
end

spacetravelmap.build_from_library = function(position, libraryPath)
    --local building = dofile(modPath.."/library/"..libraryPath);
    local building = loadBuilding(modPath.."/library/"..libraryPath);
    if (building == nil) then
        error("Building not found in library: "..libraryPath, 2);
    end
    minetest.log("Building from library \""..libraryPath.."\". Size: "..building.size.x..";"..building.size.z..";"..building.size.y);

    writeMap(building);
    for y = 1, building.size.y do
        local slice = building.map[y];
        for x = 1, building.size.x do
            for z = 1, building.size.z do
                local alias = slice[x][z];
                placeNode({
                    x = x + position.x,
                    y = y + position.y,
                    z = z + position.z
                }, alias);
            end 
        end
    end

end
