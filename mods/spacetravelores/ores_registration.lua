
-- Ore node data: {name, description, tiles, pickaxe_tier}
-- Ore item data: {name, inventory_image, wield_image}
-- Crushed ore item data: {name, description, inventory_image, wield_image}
-- Ingot data: {name, description, inventory_image, wield_image}
spacetravelores.register_ore = function(oreNodeData, oreItemData, crushedOreData, ingotData)
    -- Ore node
    minetest.register_node(oreNodeData.name, {
        description = oreNodeData.description,
        tiles = oreNodeData.tiles,
        groups = {cracky = 2},
        is_ground_content = true,
        drop = oreItemData.oreItemName
    });
    -- Ore item (dropped fron node)
    minetest.register_craftitem(oreItemData.name, {
        description = oreNodeData.description,
        inventory_image = oreItemData.inventory_image,
        wield_image = oreItemData.wield_image,
        stack_max = 99
    });
    spacetravelcore.register_process_recipe(spacetravelcore.recipe_types.cooking, {
        input_name = oreItemData.name,
        output_name = ingotData.name, 
        output_count = 1, 
        time = 20
    });
    spacetravelcore.register_process_recipe(spacetravelcore.recipe_types.grinding, {
        input_name = oreItemData.name,
        output_name = crushedOreData.name, 
        output_count = 2, 
        time = 20
    });
    -- Crushed ore item
    minetest.register_craftitem(crushedOreData.name, {
        description = crushedOreData.description,
        inventory_image = crushedOreData.inventory_image,
        wield_image = crushedOreData.wield_image,
        stack_max = 99
    });
    spacetravelcore.register_process_recipe(spacetravelcore.recipe_types.cooking, {
        input_name = crushedOreData.name,
        output_name = ingotData.name, 
        output_count = 1, 
        time = 20
    });
    -- Ingot
    minetest.register_craftitem(ingotData.name, {
        description = ingotData.description,
        inventory_image = ingotData.inventory_image,
        wield_image = ingotData.wield_image,
        stack_max = 99
    });
end
