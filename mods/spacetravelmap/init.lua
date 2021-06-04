spacetravelmap = {};

local modPath = minetest.get_modpath("spacetravelmap");

dofile(modPath.."/build_from_library.lua");

minetest.clear_registered_biomes();
minetest.clear_registered_ores();
minetest.clear_registered_decorations();

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({
        mgname='singlenode', 
        water_level=-32000, 
        flags = "nolight"
    });
end);

minetest.register_on_generated(function(minp, maxp, seed)
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
end

minetest.register_on_newplayer(function(player)
    giveStartingItems(player);
	spawnPlayer(player);
end);

minetest.register_on_respawnplayer(function(player)
	spawnPlayer(player);
	return true
end);
