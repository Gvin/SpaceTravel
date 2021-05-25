
spacetravelores.register_crushed = function(name, description, inventoryImage, wieldImage, ingotName)
    minetest.register_craftitem(name, {
        description = description,
        inventory_image = inventoryImage,
        wield_image = wieldImage,
        stack_max = 99
    });

    if (ingotName ~= nil) then
        minetest.register_craft({
            type = "cooking",
            output = ingotName,
            cooktime = 5,
            recipe = name
        });
    end
end

spacetravelores.register_ore = function(name, description, tiles, pickaxeTier, crushedName, ingotName)
    minetest.register_node(name, {
        description = description,
        tiles = tiles,
        groups = {cracky = 2},
        is_ground_content = true,
        can_dig = true,
        on_construct = function(pos)
            local meta = minetest.get_meta(pos);

            if (crushedName ~= nil) then
                meta:set_string(spacetravelores.ore_crushed_name_meta, crushedName);
            end
        end
    });

    if (ingotName ~= nil) then
        minetest.register_craft({
            type = "cooking",
            output = ingotName,
            cooktime = 5,
            recipe = name
        });
    end
end
