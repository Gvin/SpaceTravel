
minetest.clear_registered_biomes();
minetest.clear_registered_ores();
minetest.clear_registered_decorations();

local timeSet = false;

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({
        mgname='singlenode', 
        water_level=-32000
    });
end);

minetest.register_on_generated(function(minp, maxp, seed)
    if (not timeSet) then
        minetest.set_timeofday(0); -- Midnight
        minetest.settings:set("time_speed", 0);
        timeSet = true;
    end

	local position = {x = 0, y = 0, z = 0};
    if (
        position.x >= minp.x and position.x <= maxp.x and
        position.y >= minp.y and position.y <= maxp.y and
        position.z >= minp.z and position.z <= maxp.z) then
	        spacetravelmap.build_from_library(position, "stations/spawn_station.txt");
    end
end);

local function spawnPlayer(player)
    local playerSpawnPoint = {
        x = 4,
        y = 2,
        z = 16
    };

    minetest.emerge_area(
        {
            x = playerSpawnPoint.x - 2,
            y = playerSpawnPoint.y - 2,
            z = playerSpawnPoint.z - 2
        }, 
        {
            x = playerSpawnPoint.x + 2,
            y = playerSpawnPoint.y + 2,
            z = playerSpawnPoint.z + 2
        }, 
        function(blockpos, action, calls_remaining, param)
            if (calls_remaining == 0) then -- area fully loaded
                player:setpos(playerSpawnPoint);
            end
    end);
end

local function giveStartingItems(player)
    player:get_inventory():add_item("main", "spacetravelships:build_ship_token");
    player:get_inventory():add_item("main", "spacetravelships:navigation_computer");
    player:get_inventory():add_item("main", "spacetravelships:airlock_control 10");
    player:get_inventory():add_item("main", "spacetravelships:airlock_frame 20");
    player:get_inventory():add_item("main", "spacetravelships:shuttle");
end

minetest.register_on_newplayer(function(player)
    giveStartingItems(player);
	spawnPlayer(player);
end);

minetest.register_on_respawnplayer(function(player)
	spawnPlayer(player);
	return true;
end);

minetest.register_on_joinplayer(function(player, last_login)
    minetest.after(0, function()
        player:set_sky("#ffffff", "skybox", {
            "spacetravelmap_skybox_stars_top.png",
            "spacetravelmap_skybox_stars_bottom.png",
            "spacetravelmap_skybox_stars_left.png",
            "spacetravelmap_skybox_stars_right.png",
            "spacetravelmap_skybox_stars_back.png",
            "spacetravelmap_skybox_stars_front.png"
        }, false);
    end);
end);

minetest.register_globalstep(function(dtime)
    spacetravelmap.update_players_gravity();
end);
