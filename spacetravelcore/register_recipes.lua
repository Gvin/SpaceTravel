
spacetravelcore.recipes = {};

spacetravelcore.recipe_types = {};
spacetravelcore.recipe_types.cooking = "spacetravelcore:cooking";
spacetravelcore.recipe_types.grinding = "spacetravelcore:grinding";
spacetravelcore.recipe_types.compressing = "spacetravelcore:compressing";

-- recipeData: {input_name, output_name, output_count, time}
spacetravelcore.register_process_recipe = function(type, recipeData)
    if (spacetravelcore.recipes[type] == nil) then
        spacetravelcore.recipes[type] = {};
    end

    local section = spacetravelcore.recipes[type];
    table.insert(section, recipeData);
end

spacetravelcore.get_process_recipe = function(type, inputName)
    if (spacetravelcore.recipes[type] == nil) then
        return nil;
    end

    local section = spacetravelcore.recipes[type];
    for _, record in pairs(section) do
        if (record.input_name == inputName) then
            return record;
        end
    end
    return nil;
end
