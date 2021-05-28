
local random = math.random;

local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end);
end

minetest.register_craftitem("spacetravelinit:ship_core_placer", {
    description = "Ship Core Placer",
    inventory_image = "connection_tuner.png",
    wield_image = "connection_tuner.png",
    stack_max = 1,
    on_place = function(stack, user, pointed_thing)
        if (pointed_thing.type ~= "node") then
            return stack;
        end

        local position = pointed_thing.above; -- target node position
        minetest.log("Position: "..minetest.serialize(position));
        -- minetest.place_node(position, {name="spacetravelinit:ship_core"});
        -- local meta = minetest.get_meta(position);

        -- local id = uuid();
        -- local title = "New Ship";
        -- local size = {};
        -- size.x = 1;
        -- size.y = 1;
        -- size.z = 1;

        -- meta:set_string("spacetravelinit:ship_core_id", id);
        -- meta:set_string("spacetravelinit:ship_core_title", title);
        -- meta:set_string("spacetravelinit:ship_core_size", minetest.serialize(size));

        -- spacetravelcore.register_space_object(spacetravelcore.space_object_types.ship, {
        --     id = id,
        --     title = title,
        --     core_position = position,
        --     size = size
        -- });

        return stack;
    end
});
