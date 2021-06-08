
local meta_set_object = spacetravelcore.meta_set_object;
local meta_get_object = spacetravelcore.meta_get_object;

local gravityPower = 500;

local node_box = {
	type = "fixed",
	fixed = {
        {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
        {0.125, -0.5, -0.5, 0.5,  0.5, -0.125},
        {0.125, -0.5, 0.125, 0.5, 0.5, 0.5},
        {-0.5, -0.5, 0.125, -0.125, 0.5, 0.5},
        {-0.5, -0.5, -0.5, -0.125, 0.5, -0.125}
    },
};

local function tryConsumeEnergy()
    return true;
end

local function gravity_generator_node_timer(position, elapsed)
    local meta = minetest.get_meta(position);
    local active = tryConsumeEnergy();
    local infotext = "Gravity Generator";
    if (active) then
        meta:set_int(spacetravelships.constants.meta_gravity_generator_power, gravityPower);
        infotext = infotext.." (Active)";
    else
        meta:set_int(spacetravelships.constants.meta_gravity_generator_power, 0);
        infotext = infotext.." (Inactive)";
    end

    meta:set_string("infotext", infotext);
    return true;
end

minetest.register_node("spacetravelships:gravity_generator", {
    description = "Gravity Generator",
    tiles = {
        "spacetraveltechnology_machine.png",
        "spacetraveltechnology_machine.png",
        "spacetravelships_gravity_generator.png",
        "spacetravelships_gravity_generator.png",
        "spacetravelships_gravity_generator.png",
        "spacetravelships_gravity_generator.png",
    },
    groups = {
        [spacetravelships.constants.group_gravity_generator] = 1,
        cracky = 2
    },
    drawtype = "nodebox",
    node_box = node_box,
    light_source = 3,
    is_ground_content = false,
    on_timer = gravity_generator_node_timer,
    on_construct = function(position)
        minetest.get_node_timer(position):start(0.5);
    end
});
