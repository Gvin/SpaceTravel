local metaTunerStoredPoint = "spacetravelinit:tuner_stored_point";

local function meta_get_object(meta, name)
    local str = meta:get_string(name);
    if (not str) then
        return nil;
    end
    return minetest.deserialize(str);
end

minetest.register_craftitem("spacetravelinit:connection_tuner", {
    description = "Connection Tuner",
    inventory_image = "connection_tuner.png",
    wield_image = "connection_tuner.png",
    stack_max = 1,
    on_place = function(stack, user, pointed_thing)
        if (pointed_thing.type ~= "node") then
            return stack;
        end

        local position = {}; -- target node position
        position.x = pointed_thing.above.x;
        position.z = pointed_thing.above.z;
        position.y = pointed_thing.above.y - 1;

        local meta = stack:get_meta();

        local nodeName = minetest.get_node(position).name;
        local tunableControllableGroup = minetest.get_item_group(nodeName, "tunable_controllable");
        local tunableControllerGroup = minetest.get_item_group(nodeName, "tunable_controller");

        if (tunableControllableGroup == 1) then
            minetest.log("Grabbing controllable");
            meta:set_string(metaTunerStoredPoint, minetest.serialize(position));
        elseif (tunableControllerGroup == 1) then
            local storedPoint = meta_get_object(meta, metaTunerStoredPoint);
            if (storedPoint ~= nil) then
                minetest.log("Configuring controller");
                local controllerMeta = minetest.get_meta(position);
                controllerMeta:set_string("spacetravelinit:controllable_position", minetest.serialize(storedPoint));
            end
        end

        return stack;
    end
});
