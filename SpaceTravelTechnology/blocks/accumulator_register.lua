
local metaEnergyMaxStorage = "spacetraveltechnology:energy_max_storage";
local metaEnergyStorage = "spacetraveltechnology:energy_storage";
local metaMaxChargeRate = "spacetraveltechnology:max_charge_rate";
local metaMaxProduction = "spacetraveltechnology:max_production";

local S = spacetraveltechnology.get_translator;

local function readConnections(meta)
	local connections = spacetraveltechnology.meta_get_object(meta, spacetraveltechnology.energy_connections_meta);
	if (connections == nil) then
		return {};
	else
		return connections;
	end
end

local function connectionsContains(connections, position)
	for _, connection in pairs(connections) do
		if (connection.x == position.x and connection.y == position.y and connection.z == position.z) then
			return true;
		end
	end
	return false;
end

local function findEnergySources(pos, blacklist)
	table.insert(blacklist, pos); -- Exclude double checking
	local results = {};
	
	local meta = minetest.get_meta(pos);

	local isEnergyProducer = meta:get_int(spacetraveltechnology.is_energy_producer_meta) == 1;
	if (isEnergyProducer) then -- Power sources is result
		table.insert(results, pos);
	end

	local conductsEnergy = meta:get_int(spacetraveltechnology.conducts_energy_meta) == 1;
	if (conductsEnergy) then -- check extra connections only if block conducts energy
		local connections = readConnections(meta);
		local uncheckedConnections = {};
		for _, connection in pairs(connections) do
			if (not connectionsContains(blacklist, connection)) then
				local connectionMeta = minetest.get_meta(connection);
				local productionBlacklist = spacetraveltechnology.meta_get_object(connectionMeta, spacetraveltechnology.energy_production_blacklist_meta);
				
				if (productionBlacklist == nil or not connectionsContains(productionBlacklist, pos)) then
					table.insert(uncheckedConnections, connection);
				end
			end
		end
		
		if (#uncheckedConnections == 0) then
			return results;
		end
		
		for _, uncheckedConn in pairs(uncheckedConnections) do
			local subcheckResults = findEnergySources(uncheckedConn, blacklist);
			for _, subRes in pairs(subcheckResults) do
				if (not connectionsContains(results, subRes)) then
					table.insert(results, subRes);
				end
			end
		end
	end
	
	return results;
end

local function getEnergySources(meta, pos)
	local node = minetest.get_node(pos);
	local dir = minetest.facedir_to_dir(node.param2 % 4)
	local inputPos = vector.new(pos.x + dir.x * -1, pos.y + dir.y * -1, pos.z + dir.z * -1);

	local connections = readConnections(meta);

	local positionsEqual = function(pos1, pos2)
		return pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z;
	end

	if (connectionsContains(connections, inputPos)) then
		local blacklist = {};
		table.insert(blacklist, pos);
		return findEnergySources(inputPos, blacklist);
	else
		return {};
	end
end

local function accumulator_node_timer(pos, elapsed)
	local meta = minetest.get_meta(pos);
	local maxStorage = meta:get_int(metaEnergyMaxStorage);
	local storage = meta:get_int(metaEnergyStorage);

	if (storage < maxStorage) then -- If charging needed
		local energySources = spacetraveltechnology.meta_get_object(meta, spacetraveltechnology.energy_sources_cache_meta);

		if (energySources == nil) then -- If energy sources cache not initialized
			energySources = getEnergySources(meta, pos);
			spacetraveltechnology.meta_set_object(meta, spacetraveltechnology.energy_sources_cache_meta, energySources);
		end

		local storageLeft = maxStorage - storage;
		local maxChargeRate = math.min(meta:get_int(metaMaxChargeRate), storageLeft);
		local availablePower = 0;
		local index = 1;
		
		while (index <= #energySources and availablePower < maxChargeRate) do
			local powerSourcePosition = energySources[index];
			local powerSourceMeta = minetest.get_meta(powerSourcePosition);
			local powerFromSource = powerSourceMeta:get_int(spacetraveltechnology.energy_production_left_meta);
			local collectedPower = math.min(powerFromSource, maxChargeRate - availablePower);
			local leftPower = powerFromSource - collectedPower;
			
			availablePower = availablePower + collectedPower;
			powerSourceMeta:set_int(spacetraveltechnology.energy_production_left_meta, leftPower);
			
			index = index + 1;
		end

		storage = math.min(maxStorage, storage + availablePower);
	end
	
	local maxProduction = meta:get_int(metaMaxProduction);
	
	local currentLeftProduction = meta:get_int(spacetraveltechnology.energy_production_left_meta);
	local currentInitialProduction = meta:get_int(spacetraveltechnology.energy_production_initial_meta);
	local currentProductionDrop = currentInitialProduction - currentLeftProduction;
	if (currentProductionDrop > 0) then
		storage = math.max(0, storage - currentProductionDrop);
	end
	
	meta:set_int(metaEnergyStorage, storage);

	local maxPowerProduction = math.min(storage, maxProduction);
	meta:set_int(spacetraveltechnology.energy_production_left_meta, maxPowerProduction);
	meta:set_int(spacetraveltechnology.energy_production_initial_meta, maxPowerProduction);
	
	local percent = math.floor(storage*100/maxStorage);
	meta:set_string("infotext", S("Energy Storage: @1 / @2 (@3%)", storage, maxStorage, percent));
	
	return true;
end

-- Registration

spacetraveltechnology.blocks.register_accumulator = function(name, description, maxStorage, maxChargeRate, maxProduction, tiles)
    minetest.register_node(name, {
        description = "Small Accumulator",
        tiles = {
            "machine.png^accumulator_small_output.png",
            "machine.png^accumulator_small_output.png",
            "machine.png^accumulator_small_output.png",
            "machine.png^accumulator_small_output.png",
            "machine.png^accumulator_small_output.png",
            "machine.png^accumulator_small_input.png"
        },
        paramtype2 = "facedir",
        groups = {cracky = 2, [spacetraveltechnology.energy_group] = 1},
        is_ground_content = false,
        
        drop = "spacetraveltechnology:accumulator_small",
        
        drawtype = "nodebox",
        is_ground_content = false,
        
        on_timer = accumulator_node_timer,
        
        on_construct = function(pos)
            local meta = minetest.get_meta(pos);
            meta:set_int(metaEnergyMaxStorage, maxStorage);
            meta:set_int(metaEnergyStorage, 0);
            meta:set_int(metaMaxChargeRate, maxChargeRate);
            meta:set_int(metaMaxProduction, maxProduction);
            meta:set_int(spacetraveltechnology.energy_production_left_meta, 0);
            meta:set_int(spacetraveltechnology.energy_production_initial_meta, 0);
            meta:set_int(spacetraveltechnology.is_energy_producer_meta, 1);
            
            local node = minetest.get_node(pos);
            local dir = minetest.facedir_to_dir(node.param2 % 4)
            local inputPos = vector.new(pos.x + dir.x * -1, pos.y + dir.y * -1, pos.z + dir.z * -1);
            local productionBlacklist = {};
            table.insert(productionBlacklist, inputPos);
            spacetraveltechnology.meta_set_object(meta, spacetraveltechnology.energy_production_blacklist_meta, productionBlacklist);
            
            minetest.get_node_timer(pos):start(0.5);
            
            spacetraveltechnology.energy_functions.update_cable_connections_on_construct(pos);
            accumulator_node_timer(pos, 0);
        end,
        on_destruct = spacetraveltechnology.energy_functions.update_cable_connections_on_destruct
    });
end
