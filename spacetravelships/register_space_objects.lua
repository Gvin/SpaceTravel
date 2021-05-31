spacetravelships.space_objects = {};
spacetravelships.space_objects_cubes = {};

spacetravelships.space_object_types = {};
spacetravelships.space_object_types.ship = "spacetravelships:space_object_types.ship";
spacetravelships.space_object_types.station = "spacetravelships:space_object_types.station";
spacetravelships.space_object_types.asteroid = "spacetravelships:space_object_types.asteroid";

local function findSpaceObject(id)
    for _, obj in pairs(spacetravelships.space_objects) do
        if (obj.id == id) then
            return obj;
        end
    end
    return nil;
end

local function calculateObjectCube(position, size)
    local node = minetest.get_node(position);
    local dir = node.param2;

    local cube = {};
    cube.min_y = position.y - size.down;
    cube.max_y = position.y + size.up;

    if (dir == 3) then -- X+
        cube.min_z = position.z - size.right;
        cube.max_z = position.z + size.left;

        cube.min_x = position.x - size.back;
        cube.max_x = position.x + size.front;
    elseif (dir == 1) then -- X-
        cube.min_z = position.z - size.left;
        cube.max_z = position.z + size.right;

        cube.min_x = position.x - size.front;
        cube.max_x = position.x + size.back;
    elseif (dir == 2) then -- Z+
        cube.min_z = position.z - size.back;
        cube.max_z = position.z + size.front;

        cube.min_x = position.x - size.left;
        cube.max_x = position.x + size.right;
    elseif (dir == 0) then -- Z-
        cube.min_z = position.z - size.front;
        cube.max_z = position.z + size.back;

        cube.min_x = position.x - size.right;
        cube.max_x = position.x + size.left;
    else
        error("Unknown core direction: "..dir);
    end

    return cube;
end

-- objectData: {type, id, title, core_position, core_direction, size}
spacetravelships.register_space_object = function(objectData)
    if (objectData == nil) then
        error("Object data is nil.", 2);
    end
    if (objectData.id == nil or string.len(objectData.id) == 0) then
        error("Object id is nil or empty.", 2);
    end
    local existingObject = findSpaceObject(objectData.id);
    if (existingObject ~= nil) then
        error("Object with the same id is already registered. ID="..objectData.id, 2);
    end

    table.insert(spacetravelships.space_objects, objectData);
    local cube = calculateObjectCube(objectData.core_position, objectData.size);
    spacetravelships.space_objects_cubes[objectData.id] = cube;

    minetest.log("Space object registered: "..objectData.id);
end

spacetravelships.update_space_object = function(id, title, core_position, size)
    local obj = findSpaceObject(id);
    if (obj == nil) then
        error("Object with such id is not registered. ID="..id, 2);
    end

    obj.title = title;
    obj.size = minetest.deserialize(minetest.serialize(size));

    local cube = calculateObjectCube(core_position, size);
    spacetravelships.space_objects_cubes[id] = cube;
end

spacetravelships.scan_for_objects = function(position, radius)
    local result = {};
    for _, obj in pairs(spacetravelships.space_objects) do
        local corePos = obj.core_position;
        if (corePos.x >= position.x - radius and
            corePos.x <= position.x + radius and
            corePos.y >= position.y - radius and
            corePos.y <= position.y + radius and
            corePos.z >= position.z - radius and
            corePos.z <= position.z + radius) then
                local objCopy = minetest.deserialize(minetest.serialize(obj));
                objCopy.cube = spacetravelships.space_objects_cubes[obj.id];
                table.insert(result, objCopy);
        end
    end

    return result;
end

local function findIndex(list, checkFnc)
    for index, item in pairs(list) do
        if (checkFnc(item)) then
            return index;
        end
    end
    return nil;
end

spacetravelships.unregister_space_object = function(objectId)
    minetest.log("Unregistering object: "..objectId);

    local objectIdComparer = function(obj)
        return obj.id == objectId;
    end

    local objIndex = findIndex(spacetravelships.space_objects, objectIdComparer);
    if (objIndex == nil) then
        error("Object with such id is not registered. ID="..objectId, 2);
    end

    table.remove(spacetravelships.space_objects, objIndex);
    spacetravelships.space_objects_cubes[objectId] = nil;
end

local function createCube(position, size)
    local cube = {};
    cube.min_x = position.x - size.x;
    cube.max_x = position.x + size.x;
    cube.min_y = position.y - size.y;
    cube.max_y = position.y + size.y;
    cube.min_z = position.z - size.z;
    cube.max_z = position.z + size.z;
    return cube;
end

local function checkOverlaps(position1, size1, position2, size2)
    local cube1 = calculateObjectCube(position1, size1);
    local cube2 = calculateObjectCube(position2, size2);

    return 
        cube1.max_x >= cube1.min_x and
        cube1.min_x <= cube2.max_x and
        cube1.max_y >= cube1.min_y and
        cube1.min_y <= cube2.max_y and
        cube1.max_z >= cube1.min_z and
        cube1.min_z <= cube2.max_z;
end

local function checkContains(position, size, point)
    local cube = calculateObjectCube(position, size);

    return
        point.x >= cube.min_x and
        point.x <= cube.max_x and
        point.y >= cube.min_y and
        point.y <= cube.max_y and
        point.z >= cube.min_z and
        point.z <= cube.max_z;
end

spacetravelships.can_move_to_position = function(targetPosition, size)
    for _, obj in pairs(spacetravelships.space_objects) do -- for each object
        if (checkOverlaps(targetPosition, size, obj.core_position, obj.size)) then
            return false;
        end
    end
    return true;
end

local function move_node_and_meta(oldpos, newpos)
	local node = minetest.get_node(oldpos);
	local meta = minetest.get_meta(oldpos):to_table();
	minetest.set_node(oldpos, { name = "air" });
	minetest.set_node(newpos, node);
	minetest.get_meta(newpos):from_table(meta);
end

local function move_objects(oldPos, newPos)
    local objects = minetest.get_objects_inside_radius(oldPos, 1);
    for _, obj in pairs(objects) do
        obj:set_pos(newPos);
    end
end

spacetravelships.move_to_position = function(type, id, core_position, size, targetPosition)
    if (not spacetravelships.can_move_to_position(targetPosition, size)) then
        return false;
    end

    local obj = findSpaceObject(type, id);
    obj.core_position = targetPosition;

    local delta_x = targetPosition.x - core_position.x;
    local delta_y = targetPosition.y - core_position.y;
    local delta_z = targetPosition.z - core_position.z;

    local cube = createCube(core_position, size);
    for x = cube.min_x, cube.max_x do
    for y = cube.min_y, cube.max_y do
    for z = cube.min_z, cube.max_z do
        local oldPos = {};
        oldPos.x = x;
        oldPos.y = y;
        oldPos.z = z;

        local newPos = {};
        newPos.x = x + delta_x;
        newPos.y = y + delta_y;
        newPos.z = z + delta_z;

        move_node_and_meta(oldPos, newPos);
        move_objects(oldPos, newPos);
    end end end

    return true;
end