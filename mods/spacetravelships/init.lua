local modPath = minetest.get_modpath("spacetravelships");

local S = minetest.get_translator("spacetravelships");

spacetravelships = {};

spacetravelships.get_translator = S;

dofile(modPath.."/constants.lua");

dofile(modPath.."/functions.lua");

dofile(modPath.."/register_space_objects.lua");

-- Ship parts
dofile(modPath.."/ship_core.lua");
dofile(modPath.."/station_core.lua");
dofile(modPath.."/navigation_computer.lua");
dofile(modPath.."/jump_engine.lua");
dofile(modPath.."/emergency_light.lua");
dofile(modPath.."/illuminator.lua");
dofile(modPath.."/gravity_generator.lua");
dofile(modPath.."/airlock.lua");

dofile(modPath.."/build_ship_token.lua");

minetest.register_node("spacetravelships:ship_hull_light", {
    description = "Light Ship Hull",
    tiles = {"spacetravelships_ship_hull_light.png"},
    groups = {cracky = 2},
    is_ground_content = false
});

minetest.register_craftitem("spacetravelships:gps", {
    description = "GPS",
    inventory_image = "spacetravelships_gps.png",
    stack_max = 1,
    on_place = function(itemstack, placer, pointed_thing)
        if (placer:is_player()) then
            local userPos = placer:get_pos();
            local x = math.floor(userPos.x);
            local y = math.floor(userPos.y);
            local z = math.floor(userPos.z);
            minetest.chat_send_player(placer:get_player_name(), "Coordinates: [X = "..x.."; Y = "..y.."; Z = "..z.."]");
        end

        return nil;
    end
});
