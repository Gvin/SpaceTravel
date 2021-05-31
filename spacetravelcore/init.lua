
local modPath = minetest.get_modpath("spacetravelcore");

local S = minetest.get_translator("spacetravelcore");

spacetravelcore = {};

spacetravelcore.get_translator = S;

dofile(modPath.."/register_recipes.lua");

spacetravelcore.save_to_file = function(fileName, data)
    local file = io.open(minetest.get_worldpath().."/"..fileName, "w")
    if file then
        file:write(data)
        file:close()
    end
end
