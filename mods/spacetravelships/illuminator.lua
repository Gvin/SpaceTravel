minetest.register_node("spacetravelships:illuminator", {
	details = "Illuminator",
	drawtype = "glasslike_framed_optional",
	tiles = {"spacetravelships_illuminator_base.png^spacetravelships_illuminator_full.png", "spacetravelships_illuminator_base.png"},
	use_texture_alpha = "clip", -- only needed for stairs API
	paramtype = "light",
	paramtype2 = "glasslikeliquidlevel",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3}
});
