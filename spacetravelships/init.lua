local modPath = minetest.get_modpath("spacetravelships");

local S = minetest.get_translator("spacetravelships");

spacetravelships = {};

spacetravelships.get_translator = S;

dofile(modPath.."/register_space_objects.lua");

dofile(modPath.."/ship_core.lua");
dofile(modPath.."/navigation_computer.lua");
dofile(modPath.."/connection_tuner.lua");

minetest.register_node("spacetravelships:ship_hull_light", {
    description = "Light Ship Hull",
    tiles = {"ship_hull_light.png"},
    groups = {cracky = 2},
    is_ground_content = false
});
