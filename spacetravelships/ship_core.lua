
local random = math.random;

local function meta_get_object(meta, name)
    local str = meta:get_string(name);
    if (not str) then
        return nil;
    end
    return minetest.deserialize(str);
end

local function meta_set_object(meta, name, value)
    meta:set_string(name, minetest.serialize(value));
end

local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end);
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
        id = uuid();
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

local function ship_core_node_timer(position, elapsed)
    registerShipCore(position);
    return false;
end

minetest.register_node(spacetravelships.constants.ship_core_node, {
    description = "Space Ship Core",
    tiles = {
        "machine.png^ship_core_top.png^[transformFY",
        "machine.png",
        "machine.png^ship_core.png^ship_core_side.png",
        "machine.png^ship_core.png^ship_core_side.png^[transformFX",
        "machine.png^ship_core.png",
        "machine.png^ship_core.png",
    },
    paramtype2 = "facedir",
    groups = {cracky = 2},
    is_ground_content = false,
    light_source = 10,

    on_timer = ship_core_node_timer,

    on_construct = function(position)
        minetest.get_node_timer(position):start(0.5);
    end,

    on_desctuct = function(position)
        local meta = minetest.get_meta(position);
        local id = meta:get_string(spacetravelships.constants.meta_ship_core_id);

        if (id ~= nil and string.len(id) > 0) then
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
