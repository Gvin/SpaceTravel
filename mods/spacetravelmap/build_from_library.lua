local meta_get_object = spacetravelcore.meta_get_object;
local meta_set_object = spacetravelcore.meta_set_object;

local function translateSize(mapPosition, building, direction)
    if (direction == 1) then -- North
        return {
            front = mapPosition.x - 1,
            back = building.size.x - mapPosition.x,
            left = mapPosition.z - 1,
            right = building.size.z - mapPosition.z,
            up = building.size.y - mapPosition.y,
            down = mapPosition.y - 1
        };
    elseif (direction == 3) then -- South
        return {
            front = building.size.x - mapPosition.x,
            back = mapPosition.x - 1,
            left = building.size.z - mapPosition.z,
            right = mapPosition.z - 1,
            up = building.size.y - mapPosition.y,
            down = mapPosition.y - 1
        };
    elseif (direction == 0) then -- East
        return {
            front = building.size.z - mapPosition.z,
            back = mapPosition.z - 1,
            left = mapPosition.x - 1,
            right = building.size.z - mapPosition.z,
            up = building.size.y - mapPosition.y,
            down = mapPosition.y - 1
        };
    elseif (direction == 2) then -- West
        return {
            front = mapPosition.z - 1,
            back = building.size.z - mapPosition.z,
            left = building.size.z - mapPosition.z,
            right = mapPosition.x - 1,
            up = building.size.y - mapPosition.y,
            down = mapPosition.y - 1
        };
    else
        error("Unknown direction: "..direction, 2);
    end
end

local function placeCore(name, position, mapPosition, direction, building)
    minetest.set_node(position, {name = name, param2 = direction});

    local size = translateSize(mapPosition, building, direction);
    local meta = minetest.get_meta(position);
    local id = spacetravelships.generate_uuid();
    meta_set_object(meta, spacetravelships.constants.meta_ship_core_size, size);
    meta:set_string(spacetravelships.constants.meta_ship_core_id, id);
    return id;
end

local function placeStationCore(position, mapPosition, direction, building)
    return placeCore(spacetravelships.constants.station_core_node, position, mapPosition, direction, building);
end

local function placeShipCore(position, mapPosition, direction, building)
    return placeCore(spacetravelships.constants.ship_core_node, position, mapPosition, direction, building);
end

local blockAliases = {};
blockAliases["."] = "air";
blockAliases["1"] = "spacetravelships:ship_hull_light";
blockAliases["o"] = "spacetravelships:emergency_light";
blockAliases["g"] = "spacetravelships:illuminator";
blockAliases["F"] = "spacetravelmap:ship_found_computer";
blockAliases["^"] = "spacetravelships:jump_engine";
blockAliases["c"] = "spacetravelships:navigation_computer";
blockAliases["%"] = "spacetravelships:gravity_generator";

-- Station Core
blockAliases["S"] = function(position, mapPosition, building) -- Direction South (+X)
    return placeStationCore(position, mapPosition, 3, building);
end
blockAliases["N"] = function(position, mapPosition, building) -- Direction North (-X)
    return placeStationCore(position, mapPosition, 1, building);
end
blockAliases["E"] = function(position, mapPosition, building) -- Direction East (-Z)
    return placeStationCore(position, mapPosition, 0, building);
end
blockAliases["W"] = function(position, mapPosition, building) -- Direction West (+Z)
    return placeStationCore(position, mapPosition, 2, building);
end

-- Ship Core
blockAliases["s"] = function(position, mapPosition, building) -- Direction South (+X)
    return placeShipCore(position, mapPosition, 3, building);
end
blockAliases["n"] = function(position, mapPosition, building) -- Direction North (-X)
    return placeShipCore(position, mapPosition, 1, building);
end
blockAliases["e"] = function(position, mapPosition, building) -- Direction East (-Z)
    return placeShipCore(position, mapPosition, 0, building);
end
blockAliases["w"] = function(position, mapPosition, building) -- Direction West (+Z)
    return placeShipCore(position, mapPosition, 2, building);
end

local modPath = minetest.get_modpath("spacetravelmap");

local function placeNode(position, mapPosition, alias, building)
    local nodeData = blockAliases[""..alias];
    if (nodeData == nil) then
        error("Unknown block alias: "..alias, 2);
    end
    local dataType = type(nodeData);
    if (dataType == "string") then
        minetest.set_node(position, {name = nodeData});
    elseif (dataType == "function") then
        return nodeData(position, mapPosition, building);
    else
        error("Unknown block data type. Alias = \""..alias.."\"; Data Type = \""..dataType.."\"", 2);
    end
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

spacetravelmap.get_building_size = function(libraryPath)
    local building = loadBuilding(modPath.."/library/"..libraryPath);
    if (building == nil) then
        error("Building not found in library: "..libraryPath, 2);
    end

    return building.size;
end

spacetravelmap.build_from_library = function(position, libraryPath)
    local building = loadBuilding(modPath.."/library/"..libraryPath);
    if (building == nil) then
        error("Building not found in library: "..libraryPath, 2);
    end
    minetest.log("Building from library \""..libraryPath.."\". Size: "..building.size.x..";"..building.size.z..";"..building.size.y);

    local returnValue = nil;
    writeMap(building);
    for y = 1, building.size.y do
        local slice = building.map[y];
        for x = 1, building.size.x do
            for z = 1, building.size.z do
                local alias = slice[x][z];
                local mapPosition = {
                    x = x,
                    y = y,
                    z = z
                };
                local result = placeNode({
                    x = x + position.x,
                    y = y + position.y,
                    z = z + position.z
                }, mapPosition, alias, building);
                if (result ~= nil) then
                    returnValue = result;
                end
            end 
        end
    end

    return returnValue;
end
