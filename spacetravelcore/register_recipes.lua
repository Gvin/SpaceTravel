
spacetravelcore.recipes = {};

spacetravelcore.recipe_types = {};
spacetravelcore.recipe_types.cooking = "spacetravelcore:cooking";
spacetravelcore.recipe_types.grinding = "spacetravelcore:grinding";
spacetravelcore.recipe_types.compressing = "spacetravelcore:compressing";

local function createRecipeRecord(recipeData)
    if (recipeData == nil) then
        error("Argument nil: recipeData is empty.", 3);
    elseif (not recipeData.input_name) then
        error("Invalid argument: input_name is empty.", 3);
    elseif (not recipeData.output_name) then
        error("Invalid argument: output_name is empty.", 3);
    elseif (not recipeData.time) then
        error("Invalid argument: time is empty.", 3);
    end

    local record = {};
    record["input_name"] = recipeData.input_name;
    record["input_count"] = recipeData.input_count;
    if (not record.input_count) then
        record.input_count = 1;
    end
    record["output_name"] = recipeData.output_name;
    record["output_count"] = recipeData.output_count;
    if (not record.output_count) then
        record.output_count = 1;
    end
    record["time"] = recipeData.time;

    return record;
end

spacetravelcore.register_grinding_recipe = function(inputName, inputCount, outputName, outputCount, time)
    spacetravelcore.register_process_recipe(spacetravelcore.recipe_types.grinding, {
        input_name = inputName,
        input_count = inputCount,
        output_name = outputName,
        output_count = outputCount,
        time = time
    });
end

spacetravelcore.register_cooking_recipe = function(inputName, inputCount, outputName, outputCount, time)
    spacetravelcore.register_process_recipe(spacetravelcore.recipe_types.cooking, {
        input_name = inputName,
        input_count = inputCount,
        output_name = outputName,
        output_count = outputCount,
        time = time
    });
end

spacetravelcore.register_compressing_recipe = function(inputName, inputCount, outputName, outputCount, time)
    spacetravelcore.register_process_recipe(spacetravelcore.recipe_types.compressing, {
        input_name = inputName,
        input_count = inputCount,
        output_name = outputName,
        output_count = outputCount,
        time = time
    });
end

-- recipeData: {input_name, input_count, output_name, output_count, time}
spacetravelcore.register_process_recipe = function(type, recipeData)
    if (spacetravelcore.recipes[type] == nil) then
        spacetravelcore.recipes[type] = {};
    end

    local section = spacetravelcore.recipes[type];
    local record = createRecipeRecord(recipeData);
    table.insert(section, record);
end

local function tryFindCookingRecipe(inputName)
    local inputStartCount = 99;
    local inputStack = ItemStack(inputName.." "..inputStartCount);

    local cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = {inputStack}});
    if (cooked.time == 0) then -- not cookable
        return nil;
    end

    local remainingCount = aftercooked.items[1]:get_count();

    local recipe = {};
    recipe["input_name"] = inputName;
    recipe["input_count"] = inputStartCount - remainingCount;
    recipe["output_name"] = cooked.item:get_name();
    recipe["output_count"] = cooked.item:get_count();
    recipe["time"] = cooked.time;
    return recipe;
end

spacetravelcore.get_process_recipe = function(type, inputName)
    if (type == spacetravelcore.recipe_types.cooking) then
        local cookingRecipe = tryFindCookingRecipe(inputName);
        if (cookingRecipe ~= nil) then
            return cookingRecipe;
        end
    end

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
