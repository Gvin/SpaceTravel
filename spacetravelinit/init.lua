
local modPath = minetest.get_modpath("spacetravelinit");

local S = minetest.get_translator("spacetravelinit");

spacetravelinit = {};

spacetravelinit.get_translator = S;

dofile(modPath.."/register_ores.lua");
dofile(modPath.."/ship_core.lua");
dofile(modPath.."/navigation_computer.lua");
dofile(modPath.."/connection_tuner.lua");
dofile(modPath.."/ship_core_placer.lua");

minetest.register_node("spacetravelinit:ship_hull_light", {
    description = "Light Ship Hull",
    tiles = {"ship_hull_light.png"},
    groups = {cracky = 2},
    is_ground_content = false
});
