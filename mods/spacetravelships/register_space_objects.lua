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

local function checkOverlaps(cube1, cube2)
    return 
        cube1.max_x >= cube2.min_x and
        cube1.min_x <= cube2.max_x and
        cube1.max_y >= cube2.min_y and
        cube1.min_y <= cube2.max_y and
        cube1.max_z >= cube2.min_z and
        cube1.min_z <= cube2.max_z;
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

local function checkContains(cube, point)
    return
        point.x >= cube.min_x and
        point.x <= cube.max_x and
        point.y >= cube.min_y and
        point.y <= cube.max_y and
        point.z >= cube.min_z and
        point.z <= cube.max_z;
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

spacetravelships.get_engine_power = function(id)
    local cube = spacetravelships.space_objects_cubes[id];
    if (cube == nil) then
        error("Object with such id is not registered. ID="..id, 2);
    end

    local totalPower = 0;
    for x = cube.min_x, cube.max_x do
        for z = cube.min_z, cube.max_z do
            for y = cube.min_y, cube.max_y do
                local position = {
                    x = x,
                    z = z,
                    y = y
                };
                local node = minetest.get_node(position);
                if (minetest.get_item_group(node.name, spacetravelships.constants.group_engine) == 1) then
                    local meta = minetest.get_meta(position);
                    local power = meta:get_int(spacetravelships.constants.meta_engine_power);
                    totalPower = totalPower + power;
                end
            end
        end
    end
    
    return totalPower;
end

spacetravelships.get_space_object = function(id)
    return findSpaceObject(id);
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

local function hasSpaceForPlayer(position)
    return 
        minetest.get_node(position).name == "air" and
        minetest.get_node({
            x = position.x,
            z = position.z,
            y = position.y + 1
        }).name == "air";
end

local function findFreeSpaceNear(position, cube)
    for length = 1, 10 do

        local posPlusX = {
            x = position.x + length,
            z = position.z,
            y = position.y
        };
        if (hasSpaceForPlayer(posPlusX) and  checkContains(cube, posPlusX)) then
            return posPlusX;
        end

        local posMinusX = {
            x = position.x - length,
            z = position.z,
            y = position.y
        };
        if (hasSpaceForPlayer(posMinusX) and checkContains(cube, posMinusX)) then
            return posMinusX;
        end

        local posPlusZ = {
            z = position.z + length,
            x = position.x,
            y = position.y
        };
        if (hasSpaceForPlayer(posPlusZ) and checkContains(cube, posPlusZ)) then
            return posPlusZ;
        end

        local posMinusZ = {
            z = position.z - length,
            x = position.x,
            y = position.y
        };
        if (hasSpaceForPlayer(posMinusZ) and checkContains(cube, posPlusZ)) then
            return posPlusZ;
        end
    end

    error("Position for player not found.", 2);
end

spacetravelships.teleport_player_to_core = function(id, player)
    local obj = findSpaceObject(id);
    if (obj == nil) then
        error("Object with such id is not registered. ID="..id, 2);
    end

    local cube = spacetravelships.space_objects_cubes[id];
    local targetPosition = findFreeSpaceNear(obj.core_position, cube);
    player:set_pos(targetPosition);
end

spacetravelships.scan_for_objects = function(position, radius)
    local scanCube = {
        min_x = position.x - radius,
        max_x = position.x + radius,
        min_y = position.y - radius,
        max_y = position.y + radius,
        min_z = position.z - radius,
        max_z = position.z + radius
    };

    local result = {};
    for _, obj in pairs(spacetravelships.space_objects) do
        local objCube = spacetravelships.space_objects_cubes[obj.id];
        if (checkOverlaps(scanCube, objCube)) then
            local objCopy = minetest.deserialize(minetest.serialize(obj));
            objCopy.cube = objCube;
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

local function shiftCube(cube, delta)
    return {
        min_x = cube.min_x + delta.x,
        max_x = cube.max_x + delta.x,
        min_y = cube.min_y + delta.y,
        max_y = cube.max_y + delta.y,
        min_z = cube.min_z + delta.z,
        max_z = cube.max_z + delta.z
    }
end


spacetravelships.can_move = function(id)
    local cube = spacetravelships.space_objects_cubes[id];
    if (cube == nil) then
        error("Object with such id is not registered. ID="..id, 2);
    end

    local volume = (cube.max_x - cube.min_x) * (cube.max_y - cube.min_y) * (cube.max_z - cube.min_z);
    local power = spacetravelships.get_engine_power(id);
    return power >= volume;
end

spacetravelships.can_move_to_position = function(id, targetPosition)
    local movingObject = findSpaceObject(id);
    if (movingObject == nil) then
        error("Space object with such id not found. ID="..id, 2);
    end

    local cube = spacetravelships.space_objects_cubes[id];
    local targetCube = shiftCube(cube, {
        x = targetPosition.x - movingObject.core_position.x,
        y = targetPosition.y - movingObject.core_position.y,
        z = targetPosition.z - movingObject.core_position.z
    });

    for _, obj in pairs(spacetravelships.space_objects) do -- for each object
        local objCube = spacetravelships.space_objects_cubes[obj.id];
        if (checkOverlaps(objCube, targetCube)) then
            return false;
        end
    end
    return true;
end

spacetravelships.get_is_registered = function(id)
    return findSpaceObject(id) ~= nil;
end

local function getGravityGeneratorsPower(cube)
    local totalPower = 0;
    for x = cube.min_x, cube.max_x do
        for y = cube.min_y, cube.max_y do
            for z = cube.min_z, cube.max_z do
                local position = {x = x, y = y, z = z};
                local node = minetest.get_node(position);
                if (minetest.get_item_group(node.name, spacetravelships.constants.group_gravity_generator) == 1) then
                    local meta = minetest.get_meta(position);
                    local power = meta:get_int(spacetravelships.constants.meta_gravity_generator_power);
                    totalPower = totalPower + power;
                end
            end
        end
    end
    return totalPower;
end

spacetravelships.get_has_gravity = function(id)
    local cube = spacetravelships.space_objects_cubes[id];
    if (cube == nil) then
        error("Space object with such id not found. ID="..id, 2);
    end

    local gravityGeneratorsPower = getGravityGeneratorsPower(cube);
    local volume = (cube.max_x - cube.min_x) * (cube.max_y - cube.min_y) * (cube.max_z - cube.min_z);

    return gravityGeneratorsPower >= volume;
end

-- Gets ship that owns specific node position
spacetravelships.get_owning_object = function(position)
    for _, obj in pairs(spacetravelships.space_objects) do -- for each object
        local objCube = spacetravelships.space_objects_cubes[obj.id];
        if (checkContains(objCube, position)) then
            return obj;
        end
    end
    return nil;
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
        local newObjectPos = {
            x = newPos.x,
            z = newPos.z,
            y = newPos.y
        };
        if (obj:is_player()) then -- to fix player in block teleport
            newObjectPos.y = newObjectPos.y + 1;
        end
        obj:set_pos(newObjectPos);
    end
end

spacetravelships.move_to_position = function(id, targetPosition)
    if (not spacetravelships.can_move(id)) then
        return false;
    end
    if (not spacetravelships.can_move_to_position(id, targetPosition)) then
        return false;
    end

    local obj = findSpaceObject(id);
    if (obj == nil) then
        error("Space object with such id not found. ID="..id, 2);
    end

    local cube = spacetravelships.space_objects_cubes[id];
    local delta = {
        x = targetPosition.x - obj.core_position.x,
        y = targetPosition.y - obj.core_position.y,
        z = targetPosition.z - obj.core_position.z
    };

    local targetAreaPos1 = {
        x = cube.min_x + delta.x,
        y = cube.min_y + delta.y,
        z = cube.min_z + delta.z
    };
    local targetAreaPos2 = {
        x = cube.max_x + delta.x,
        y = cube.max_y + delta.y,
        z = cube.max_z + delta.z
    };

    minetest.emerge_area(targetAreaPos1, targetAreaPos2, function(blockpos, action, calls_remaining, param)
        if (calls_remaining == 0) then -- area fully loaded
            for x = cube.min_x, cube.max_x do
            for y = cube.min_y, cube.max_y do
            for z = cube.min_z, cube.max_z do
                local oldPos = {
                    x = x,
                    y = y,
                    z = z
                };
        
                local newPos = {
                    x = x + delta.x,
                    y = y + delta.y,
                    z = z + delta.z
                };
        
                move_node_and_meta(oldPos, newPos);
                move_objects(oldPos, newPos);
            end end end
        end
    end);

    return true;
end
