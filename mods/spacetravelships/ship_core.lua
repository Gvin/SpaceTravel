
local meta_get_object = spacetravelcore.meta_get_object;

local function meta_set_object(meta, name, value)
    meta:set_string(name, minetest.serialize(value));
end

local function convertDirection(dir)
    if (dir == 3) then -- X+
        return 180;
    elseif (dir == 1) then -- X-
        return 0;
    elseif (dir == 2) then -- Z+
        return 270;
    elseif (dir == 0) then -- Z-
        return 90;
    end
    error("Unable to convert direction: "..dir);
end

local function registerShipCore(position)
    local meta = minetest.get_meta(position);

    local id = meta:get_string(spacetravelships.constants.meta_ship_core_id);
    if (id == nil or string.len(id) == 0) then
        id = spacetravelships.generate_uuid();
    end

    local title = meta:get_string(spacetravelships.constants.meta_ship_core_title);
    if (title == nil or string.len(title) == 0) then
        title = "New Ship";
    end

    local size = meta_get_object(meta, spacetravelships.constants.meta_ship_core_size);
    if (size == nil) then
        size = {
            left = 1,
            right = 1,
            front = 1,
            back = 1,
            up = 1,
            down = 1
        };
    end

    local coreNode = minetest.get_node(position);
    local direction = convertDirection(coreNode.param2);

    if (not spacetravelships.get_is_registered(id)) then
        spacetravelships.register_space_object({
            type = spacetravelships.space_object_types.ship,
            id = id,
            title = title,
            core_position = position,
            core_direction = direction,
            size = size
        });

        meta:set_string(spacetravelships.constants.meta_ship_core_id, id);
        meta:set_string(spacetravelships.constants.meta_ship_core_title, title);
        meta_set_object(meta, spacetravelships.constants.meta_ship_core_size, size);
    end
end

local function ship_core_node_timer(position, elapsed)
    registerShipCore(position);
    return false;
end

minetest.register_node(spacetravelships.constants.ship_core_node, {
    description = "Space Ship Core",
    tiles = {
        "spacetraveltechnology_machine.png^spacetravelships_ship_core_top.png^[transformFY",
        "spacetraveltechnology_machine.png",
        "spacetraveltechnology_machine.png^spacetravelships_ship_core.png^spacetravelships_ship_core_side.png",
        "spacetraveltechnology_machine.png^spacetravelships_ship_core.png^spacetravelships_ship_core_side.png^[transformFX",
        "spacetraveltechnology_machine.png^spacetravelships_ship_core.png",
        "spacetraveltechnology_machine.png^spacetravelships_ship_core.png",
    },
    paramtype2 = "facedir",
    groups = {cracky = 2},
    is_ground_content = false,
    light_source = 10,

    on_timer = ship_core_node_timer,

    on_construct = function(position)
        minetest.get_node_timer(position):start(0.5);
    end,

    on_destruct = function(position)
        local meta = minetest.get_meta(position);
        local id = meta:get_string(spacetravelships.constants.meta_ship_core_id);

        if (id ~= nil and string.len(id) > 0 and spacetravelships.get_is_registered(id)) then
            spacetravelships.unregister_space_object(id);
        end
    end
});

minetest.register_lbm({
    name = "spacetravelships:register_ship_cores",
    nodenames = {spacetravelships.constants.ship_core_node},
    run_at_every_load = true,
    action = function(position, node)
        registerShipCore(position);
    end
});
