
local modPath = minetest.get_modpath("spacetravelores");

local S = minetest.get_translator("spacetravelores");

spacetravelores = {};

spacetravelores.get_translator = S;

dofile(modPath.."/constants.lua");
dofile(modPath.."/ores_registration.lua");
