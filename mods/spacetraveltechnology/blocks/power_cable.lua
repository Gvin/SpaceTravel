
local size = 2/16;

local node_box = {
	type = "connected",
	fixed          = {-size, -size, -size, size,  size, size},
	connect_top    = {-size, -size, -size, size,  0.5,  size}, -- y+
	connect_bottom = {-size, -0.5,  -size, size,  size, size}, -- y-
	connect_front  = {-size, -size, -0.5,  size,  size, size}, -- z-
	connect_back   = {-size, -size,  size, size,  size, 0.5 }, -- z+
	connect_left   = {-0.5,  -size, -size, size,  size, size}, -- x-
	connect_right  = {-size, -size, -size, 0.5,   size, size}, -- x+
};

minetest.register_node("spacetraveltechnology:power_cable", {
    description = "Power Cable",
    tiles = {
		"power_cable.png",
		"power_cable.png",
		"power_cable.png",
		"power_cable.png",
		"power_cable.png",
		"power_cable.png"
	},
	wield_image = "power_cable_wield.png",
	inventory_image = "power_cable_wield.png",
    groups = {cracky = 2, [spacetraveltechnology.energy_group] = 1},
	is_ground_content = false,
	
	drop = "spacetraveltechnology:power_cable",
	
	sunlight_propagates = true,
	
	paramtype = "light",
	
	drawtype = "nodebox",
	node_box = node_box,
	
	connects_to = {"group:"..spacetraveltechnology.energy_group},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		meta:set_int(spacetraveltechnology.conducts_energy_meta, 1);

		spacetraveltechnology.energy_functions.update_cable_connections_on_construct(pos);
	end,
	on_destruct = spacetraveltechnology.energy_functions.update_cable_connections_on_destruct
})
