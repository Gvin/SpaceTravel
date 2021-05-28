local size = {};
size.x = 2;
size.y = 2;
size.z = 2;

local random = math.random;

local function meta_get_object(meta, name)
    local str = meta:get_string(name);
    if (not str) then
        return nil;
    end
    return minetest.deserialize(str);
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

    local id = meta:get_string("spacetravelinit:ship_core_id");
    if (id == nil or string.len(id) == 0) then
        id = uuid();
    end

    local title = meta:get_string("spacetravelinit:ship_core_title");
    if (title == nil or string.len(title) == 0) then
        title = "New Ship";
    end

    local size = meta_get_object(meta, "spacetravelinit:ship_core_size");
    if (size == nil) then
        size = {
            x = 1,
            y = 1,
            z = 1
        };
    end

    local coreNode = minetest.get_node(position);
    local direction = convertDirection(coreNode.param2);

    spacetravelcore.register_space_object({
        type = spacetravelcore.space_object_types.ship,
        id = id,
        title = title,
        core_position = position,
        core_direction = direction,
        size = size
    });
end

local function ship_core_node_timer(position, elapsed)
    -- minetest.log("Moving ship core")
    -- local targetPosition = {};
    -- targetPosition.x = position.x;
    -- targetPosition.z = position.z;
    -- targetPosition.y = position.y + 20;

    -- if (not registered) then
    --     minetest.log("Registering space object");
    --     spacetravelcore.register_space_object(spacetravelcore.space_object_types.ship, {
    --         id = "test_id1",
    --         title = "Test Ship",
    --         core_position = position,
    --         size = size
    --     });
    --     registered = true;
    -- end

    --local moved = spacetravelcore.move_to_position(spacetravelcore.space_object_types.ship, "test_id1", position, size, targetPosition);

    
    registerShipCore(position);
    return false;
end

minetest.register_node("spacetravelinit:ship_core", {
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
    groups = {cracky = 2, ["tunable_controllable"] = 1},
    is_ground_content = false,
    light_source = 10,

    on_timer = ship_core_node_timer,

    on_construct = function(position)
        minetest.get_node_timer(position):start(0.5);
    end,

    on_desctuct = function(position)
        local meta = minetest.get_meta(position);
        local id = meta:get_string("spacetravelinit:ship_core_id");

        if (id ~= nil and string.len(id) > 0) then
            spacetravelcore.unregister_space_object(id);
        end
    end
});

minetest.register_lbm({
    name = "spacetravelinit:register_ship_cores",
    nodenames = {"spacetravelinit:ship_core"},
    run_at_every_load = true,
    action = function(position, node)
        registerShipCore(position);
    end
});
