local metaFrame = "spacetravelships:airlock_frame";
local metaDoorNodes = "spacetravelships:airlock_door_nodes";
local metaLeftOpen = "spacetravelships:airlock_left_open";
local metaControlNode = "spacetravelships:airlock_control_node";

local groupAirlock = "spacetravelships_airlock_group";

local meta_set_object = spacetravelcore.meta_set_object;
local meta_get_object = spacetravelcore.meta_get_object;

local airlockOpenTime = 3.0;

local function getScanDirection(position)
    local node = minetest.get_node(position);
    local dir = node.param2;
    if (dir == 3) then -- X+
        return {x = 0, z = -1};
    elseif (dir == 1) then -- X-
        return {x = 0, z = 1};
    elseif (dir == 2) then -- Z+
        return {x = 1, z = 0};
    elseif (dir == 0) then -- Z-
        return {x = -1, z = 0};
    end
    error("Unable to convert direction: "..dir);
end

local function getConnectedNodesColumn(position)
    local results = {position};
    -- Going up
    local scanPos = {x = position.x, y = position.y + 1, z = position.z};
    local node = minetest.get_node(scanPos);
    while (minetest.get_item_group(node.name, groupAirlock) == 1) do
        table.insert(results, scanPos);
        scanPos = {x = scanPos.x, y = scanPos.y + 1, z = scanPos.z};
        node = minetest.get_node(scanPos);
    end
    -- Going down
    scanPos = {x = position.x, y = position.y - 1, z = position.z};
    node = minetest.get_node(scanPos);
    while (minetest.get_item_group(node.name, groupAirlock) == 1) do
        table.insert(results, scanPos);
        scanPos = {x = scanPos.x, y = scanPos.y - 1, z = scanPos.z};
        node = minetest.get_node(scanPos);
    end

    return results;
end

local function findTargetNode(initialNode, scanDirection)
    local maxScanDistance = 3;
    for counter = 1, maxScanDistance do
        local targetPos = {x = initialNode.x + scanDirection.x * counter, z = initialNode.z + scanDirection.z * counter, y = initialNode.y};
        local targetNode = minetest.get_node(targetPos);
        if (minetest.get_item_group(targetNode.name, groupAirlock) == 1) then
            return targetPos;
        elseif (targetNode.name ~= "air") then -- Something blocks airlock
            return nil;
        end
    end
    return nil;
end

local function getNodeKey(position)
    return ""..position.x.."_"..position.y.."_"..position.z;
end

local function getTargetNodes(initialNodes, scanDirection)
    
    local result = {};
    for _, initialNode in pairs(initialNodes) do
        local targetNode = findTargetNode(initialNode, scanDirection);
        if (targetNode == nil) then -- Failed to find target node
            return nil;
        else
            result[getNodeKey(initialNode)] = targetNode;
        end
    end

    return result;
end

local function getFrame(position)
    local scanDirection = getScanDirection(position);
    local initialNodes = getConnectedNodesColumn(position);
    local targetNodes = getTargetNodes(initialNodes, scanDirection);
    if (targetNodes == nil) then
        return nil;
    else
        return {
            initial = initialNodes,
            target = targetNodes
        };
    end
end

local function getDoorNodesPosition(frame)
    local results = {};
    for _, initialNode in pairs(frame.initial) do
        local targetNode = frame.target[getNodeKey(initialNode)];
        local startX = math.min(initialNode.x, targetNode.x);
        local endX = math.max(initialNode.x, targetNode.x);
        local startZ = math.min(initialNode.z, targetNode.z);
        local endZ = math.max(initialNode.z, targetNode.z);
        for x = startX, endX do
            for z = startZ, endZ do
                if ((not (x == targetNode.x and z == targetNode.z)) and (not(x == initialNode.x and z == initialNode.z))) then
                    table.insert(results, {x = x, z = z, y = initialNode.y});
                end
            end
        end
    end
    return results;
end

local function placeDoorNode(position, controlNodePosition, direction)
    minetest.set_node(position, {name = "spacetravelships:airlock_door", param2 = direction});
    local meta = minetest.get_meta(position);
    meta_set_object(meta, metaControlNode, controlNodePosition);
end

local function closeAirlock(position)
    local controlNode = minetest.get_node(position);
    local meta = minetest.get_meta(position);
    local doorNodes = meta_get_object(meta, metaDoorNodes);
    if (doorNodes ~= nil) then
        for _, pos in pairs(doorNodes) do
            if (minetest.get_node(pos).name ~= "air") then
                return;
            end
        end

        for _, pos in pairs(doorNodes) do
            placeDoorNode(pos, position, controlNode.param2);
        end
    end
end

local function openAirlock(position)
    local meta = minetest.get_meta(position);
    local doorNodes = meta_get_object(meta, metaDoorNodes);
    if (doorNodes ~= nil) then
        for _, pos in pairs(doorNodes) do
            if (minetest.get_node(pos).name == "spacetravelships:airlock_door") then
                minetest.set_node(pos, {name="air"});
            end
        end
    end
end

local function setControlNode(frame, controlNodePosition)
    for _, pos in pairs(frame.initial) do
        local meta = minetest.get_meta(pos);
        meta_set_object(meta, metaControlNode, controlNodePosition);
    end
    for _, pos in pairs(frame.target) do
        local meta = minetest.get_meta(pos);
        meta_set_object(meta, metaControlNode, controlNodePosition);
    end
end

local function refreshFrame(controlNodePosition)
    local meta = minetest.get_meta(controlNodePosition);

    openAirlock(controlNodePosition);
    
    local oldFrame = meta_get_object(meta, metaFrame);
    if (oldFrame ~= nil) then
        setControlNode(oldFrame, nil);
    end

    local frame = getFrame(controlNodePosition);
    meta_set_object(meta, metaFrame, frame);
    local doorNodes = nil;
    if (frame ~= nil) then
        setControlNode(frame, controlNodePosition);
        doorNodes = getDoorNodesPosition(frame);
    end
    meta_set_object(meta, metaDoorNodes, doorNodes);

    closeAirlock(controlNodePosition);
end

local function airlock_control_construct(position)
    refreshFrame(position);
end

local function airlock_control_on_timer(position, elapsed)
    local meta = minetest.get_meta(position);
    local leftOpen =meta:get_float(metaLeftOpen);
    leftOpen = leftOpen - elapsed;
    meta:set_float(metaLeftOpen, math.max(0, leftOpen));

    if (leftOpen < 0) then
        closeAirlock(position);
        meta:set_float(metaLeftOpen, 0);
        return false;
    end

    return true;
end

local function airlock_control_on_destruct(position)
    local meta = minetest.get_meta(position);
    
    local oldFrame = meta_get_object(meta, metaFrame);
    if (oldFrame ~= nil) then
        setControlNode(oldFrame, nil);
    end
end

local function airlock_frame_on_destruct(position)
    local meta = minetest.get_meta(position);
    local controlNodePosition = meta_get_object(meta, metaControlNode);
    if (controlNodePosition ~= nil) then
        refreshFrame(controlNodePosition);
    end
end

local function airlock_door_on_rightclick(position, node, player, itemstack, pointed_thing)
    local meta = minetest.get_meta(position);
    local controlNode = meta_get_object(meta, metaControlNode);
    if (controlNode == nil) then
        error("Airlock door not linked to control node.");
    end

    -- TODO: Add security checks
    local controlMeta = minetest.get_meta(controlNode)
    local doorNodes = meta_get_object(controlMeta, metaDoorNodes);
    if (doorNodes ~= nil) then
        openAirlock(position);
        controlMeta:set_float(metaLeftOpen, airlockOpenTime);
        minetest.get_node_timer(controlNode):start(0.5);
    end
    openAirlock(controlNode);
end

minetest.register_node("spacetravelships:airlock_control", {
    description = "Airlock Control",
    tiles = {
        "spacetravelships_airlock_frame.png",
        "spacetravelships_airlock_frame.png",
        "spacetravelships_airlock_frame.png",
        "spacetravelships_airlock_frame.png",
        "spacetravelships_airlock_frame.png^spacetravelships_airlock_control.png^spacetravelships_airlock_control_direction.png^[transformFX",
        "spacetravelships_airlock_frame.png^spacetravelships_airlock_control.png^spacetravelships_airlock_control_direction.png"
    },
    paramtype2 = "facedir",
    groups = {cracky = 2, [groupAirlock] = 1},
    is_ground_content = false,
    on_construct = airlock_control_construct,
    on_destruct = airlock_control_on_destruct,
    on_timer = airlock_control_on_timer
});

minetest.register_node("spacetravelships:airlock_frame", {
    description = "Airlock Frame",
    tiles = {"spacetravelships_airlock_frame.png"},
    groups = {cracky = 2, [groupAirlock] = 1},
    is_ground_content = false,
    on_destruct = airlock_frame_on_destruct
});

local doorNodebox = {
    type = "fixed",
	fixed = {
        {-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875}
    }
}

minetest.register_node("spacetravelships:airlock_door", {
    description = "Airlock Door",
    tiles = {"spacetravelships_airlock_door.png"},
    paramtype2 = "facedir",
    groups = {cracky = 2, not_in_creative_inventory=1},
    is_ground_content = false,
    drawtype = "nodebox",
    node_box = doorNodebox,
    on_rightclick = airlock_door_on_rightclick
});
