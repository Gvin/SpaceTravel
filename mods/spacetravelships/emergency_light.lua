local size = 2/16;

minetest.register_node("spacetravelships:emergency_light", {
    description = "Energency Light",
    tiles = {"spacetravelships_emergency_light.png"},
    groups = {cracky = 2},
    is_ground_content = false,
    drop = "spacetravelships:emergency_light",
    sunlight_propagates = true,
    paramtype = "light",
    drawtype = "nodebox",
    node_box = {
        type = "connected",
        fixed          = {-size, -size, -size, size,  size, size},
        connect_top    = {-size, -size, -size, size,  0.5,  size}, -- y+
        connect_bottom = {-size, -0.5,  -size, size,  size, size}, -- y-
        connect_front  = {-size, -size, -0.5,  size,  size, size}, -- z-
        connect_back   = {-size, -size,  size, size,  size, 0.5 }, -- z+
        connect_left   = {-0.5,  -size, -size, size,  size, size}, -- x-
        connect_right  = {-size, -size, -size, 0.5,   size, size}, -- x+
    },
    light_source = 20 -- TODO: reduce emergency light level
});
