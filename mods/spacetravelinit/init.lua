
local modPath = minetest.get_modpath("spacetravelinit");

local S = minetest.get_translator("spacetravelinit");

spacetravelinit = {};

spacetravelinit.get_translator = S;

dofile(modPath.."/register_ores.lua");
