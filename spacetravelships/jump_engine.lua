
local metaNozzlePosition = "spacetravelships:nozzle_position";

local meta_set_object = spacetravelcore.meta_set_object;
local meta_get_object = spacetravelcore.meta_get_object;

local function getNozzleExpectedPosition(position, shipDirection)
    if (shipDirection == 3) then -- X+
        return {
            x = position.x - 1,
            y = position.y,
            z = position.z
        };
    elseif (shipDirection == 1) then -- X-
        return {
            x = position.x + 1,
            y = position.y,
            z = position.z
        };
    elseif (shipDirection == 2) then -- Z+
        return {
            x = position.x,
            y = position.y,
            z = position.z - 1
        };
    elseif (shipDirection == 0) then -- Z-
        return {
            x = position.x,
            y = position.y,
            z = position.z + 1
        };
    end
    error("Unable to process direction: "..shipDirection);
end

local nozzle_node_box = {
	type = "fixed",
	fixed = {
        {-0.5, -0.5, 0, 0.5, 0.5, 0.5},
        {-0.25, -0.25, -0.5, 0.25,  0.25, 0}
    },
};

local function positionEquals(pos1, pos2)
    return pos1.x == pos2.x and
        pos1.y == pos2.y and
        pos1.z == pos2.z;
end

local function correctNozzle(position)
    local owningObject = spacetravelships.get_owning_object(position);
    if (owningObject ~= nil) then
        local shipDirection = minetest.get_node(owningObject.core_position).param2;
        local meta = minetest.get_meta(position);
        local nozzlePosition = meta_get_object(meta, metaNozzlePosition);
        local expectedNozzlePosition = getNozzleExpectedPosition(position, shipDirection);

        if (minetest.get_node(expectedNozzlePosition).name == "air") then -- Has space for nozzle
            if (nozzlePosition == nil) then -- Nozzle not existed before
                minetest.set_node(expectedNozzlePosition, {name="spacetravelships:jump_engine_nozzle", param2=shipDirection});
                meta_set_object(meta, metaNozzlePosition, expectedNozzlePosition);
            elseif (not positionEquals(expectedNozzlePosition, nozzlePosition)) then -- Nozzle existed and position mismatch
                minetest.set_node(nozzlePosition, {name="air"});
                minetest.set_node(expectedNozzlePosition, {name="spacetravelships:jump_engine_nozzle", param2=shipDirection});
                meta_set_object(meta, metaNozzlePosition, expectedNozzlePosition);
            end
        end
    end
end

local function jump_engine_node_timer(position, elapsed)
    correctNozzle(position);
end

minetest.register_node("spacetravelships:jump_engine", {
    description = "Jump Engine",
    tiles = {
        "machine.png^spacetravelships_engine.png",
        "machine.png^spacetravelships_engine.png",
        "machine.png^spacetravelships_engine.png",
        "machine.png^spacetravelships_engine.png",
        "machine.png^spacetravelships_engine.png",
        "machine.png^spacetravelships_engine.png"
    },
    groups = {
        [spacetravelships.constants.group_engine] = 1,
        cracky = 2
    },
    light_source = 3,
    is_ground_content = false,
    on_timer = jump_engine_node_timer,
    on_construct = function(position)
        minetest.get_node_timer(position):start(0.5);
    end,
    on_destruct = function(position)
        local meta = minetest.get_meta(position);
        local nozzlePosition = meta_get_object(meta, metaNozzlePosition);
        if (nozzlePosition ~= nil) then
            minetest.set_node(nozzlePosition, {name="air"});
        end
    end
});

minetest.register_node("spacetravelships:jump_engine_nozzle", {
    description = "Jump Engine",
    tiles = {
        "spacetravelships_engine_nozzle.png",
        "spacetravelships_engine_nozzle.png",
        "spacetravelships_engine_nozzle.png",
        "spacetravelships_engine_nozzle.png",
        "spacetravelships_engine_nozzle.png^spacetravelships_engine_nozzle_fire.png",
        "spacetravelships_engine_nozzle.png"
    },
    paramtype2 = "facedir",
    drawtype = "nodebox",
    node_box = nozzle_node_box,
    groups = {not_in_creative_inventory=1},
    can_dig = function() 
        return false; 
    end,
    light_source = 12,
    is_ground_content = false
});
