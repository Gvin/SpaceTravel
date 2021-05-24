
local modPath = minetest.get_modpath("spacetraveltechnology");

local S = minetest.get_translator("spacetraveltechnology");

spacetraveltechnology = {};

spacetraveltechnology.get_translator = S;


dofile(modPath.."/constants.lua");

dofile(modPath.."/functions.lua");

dofile(modPath.."/blocks/init_blocks.lua");
