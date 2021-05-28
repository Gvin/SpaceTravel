
local modPath = minetest.get_modpath("spacetravelcore");

local S = minetest.get_translator("spacetravelcore");

spacetravelcore = {};

spacetravelcore.get_translator = S;

dofile(modPath.."/register_recipes.lua");
dofile(modPath.."/register_space_objects.lua");
