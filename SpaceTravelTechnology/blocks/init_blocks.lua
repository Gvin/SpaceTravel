local path = minetest.get_modpath("spacetraveltechnology").."/blocks";

spacetraveltechnology.blocks = {};

dofile(path.."/energy_functions.lua");
dofile(path.."/accumulator_register.lua");

-- Blocks
dofile(path.."/fuel_generator.lua");
dofile(path.."/power_cable.lua");
dofile(path.."/accumulators.lua");
dofile(path.."/electric_furnace.lua");
dofile(path.."/macerator.lua");
