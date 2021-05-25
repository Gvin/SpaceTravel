
spacetraveltechnology.energy_functions = {};

local tableExt = spacetraveltechnology.table;

local function check_connections(pos)
	local connections = {}
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}
	for _,connected_pos in pairs(positions) do
		local nodeName = minetest.get_node(connected_pos).name;
		local energyGroup = minetest.get_item_group(nodeName, spacetraveltechnology.energy_group);
		if (energyGroup == 1) then
			table.insert(connections,connected_pos);
		end
	end
	return connections
end

local function readConnections(meta)
	local connections = spacetraveltechnology.meta_get_object(meta, spacetraveltechnology.energy_connections_meta);
	if (connections == nil) then
		return {};
	else
		return connections;
	end
end

local function saveConnections(meta, connections)
	spacetraveltechnology.meta_set_object(meta, spacetraveltechnology.energy_connections_meta, connections);
end

local function connectionsContains(connections, position)
	for _, connection in pairs(connections) do
		if (connection.x == position.x and connection.y == position.y and connection.z == position.z) then
			return true;
		end
	end
	return false;
end

local function getConnectionIndex(connections, position)
	for index, connection in pairs(connections) do
		if (connection.x == position.x and connection.y == position.y and connection.z == position.z) then
			return index;
		end
	end
	return nil;
end

local function removeConnection(connections, position)
	local index = getConnectionIndex(connections, position);
	if (index ~= nil) then
		table.remove(connections, index);
	end
end

local function clearPowerSourcesCache(position, blacklist)
	table.insert(blacklist, position);
	local meta = minetest.get_meta(position);
	meta:set_string(spacetraveltechnology.energy_sources_cache_meta, nil);
	local connections = readConnections(meta);
	for _, connection in pairs(connections) do
		if (not connectionsContains(blacklist, connection)) then
			clearPowerSourcesCache(connection, blacklist);
		end
	end
end

-- Add this position to all connected nodes. Add all connected nodes to this node's connections.
spacetraveltechnology.energy_functions.update_cable_connections_on_construct = function(pos)
	local meta = minetest.get_meta(pos);
	local localConnections = {};
	local positions = check_connections(pos);
	
	if #positions < 1 then return; end -- No connections
	
	for _, connectedPos in pairs(positions) do
		if (not connectionsContains(localConnections, connectedPos)) then
			table.insert(localConnections, connectedPos);
		end
	
		local targetMeta = minetest.get_meta(connectedPos);
		local connectionsOnTarget = readConnections(targetMeta);
		if (not connectionsContains(connectionsOnTarget, pos)) then
			table.insert(connectionsOnTarget, pos);
		end
		saveConnections(targetMeta, connectionsOnTarget);
	end
	
	saveConnections(meta, localConnections);
	clearPowerSourcesCache(pos, {});
end

-- Remove this position from all connected nodes.
spacetraveltechnology.energy_functions.update_cable_connections_on_destruct = function(pos)
	local positions = check_connections(pos);
	
	if #positions < 1 then return; end -- No connections
	
	for _, connectedPos in pairs(positions) do
		local targetMeta = minetest.get_meta(connectedPos);
		local connectionsOnTarget = readConnections(targetMeta);
		removeConnection(connectionsOnTarget, pos);
		saveConnections(targetMeta, connectionsOnTarget);
	end

	clearPowerSourcesCache(pos, {});
end

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

local function collectEnergySources(position, blacklist)
	table.insert(blacklist, position); -- Exclude double checking
	local results = {};

	local meta = minetest.get_meta(position);

	local isEnergyProducer = meta:get_int(spacetraveltechnology.is_energy_producer_meta) == 1;
	if (isEnergyProducer) then -- Power sources is result
		table.insert(results, position);
	end

	local conductsEnergy = meta:get_int(spacetraveltechnology.conducts_energy_meta) == 1;
	if (conductsEnergy) then -- check extra connections only if block conducts energy
		local connections = readConnections(meta);
		local uncheckedConnections = {};
		for _, connection in pairs(connections) do
			if (not connectionsContains(blacklist, connection)) then
				local connectionMeta = minetest.get_meta(connection);
				local productionBlacklist = spacetraveltechnology.meta_get_object(connectionMeta, spacetraveltechnology.energy_production_blacklist_meta);
				
				if (productionBlacklist == nil or not connectionsContains(productionBlacklist, position)) then
					table.insert(uncheckedConnections, connection);
				end
			end
		end
		
		for _, uncheckedConn in pairs(uncheckedConnections) do
			local subcheckResults = collectEnergySources(uncheckedConn, blacklist);
			for _, subRes in pairs(subcheckResults) do
				if (not connectionsContains(results, subRes)) then
					table.insert(results, subRes);
				end
			end
		end
	end
	
	return results;
end

local function getEnergySources(position, meta, inputPositions)
	local searchStartPositions = {};
	if (inputPositions ~= nil) then
		searchStartPositions = inputPositions;
	else
		searchStartPositions = spacetraveltechnology.meta_get_object(meta, spacetraveltechnology.energy_connections_meta);
		if (searchStartPositions == nil) then
			return {};
		end
	end

	local result = {};
	local blacklist = {position};
	for _, searchStart in pairs(searchStartPositions) do
		local subResults = collectEnergySources(searchStart, blacklist);
		for _, source in pairs(subResults) do
			table.insert(result, source);
		end
	end

	return result;
end

local function getEnergyProduction(position)
	local meta = minetest.get_meta(position);
	local productionLeft = meta:get_int(spacetraveltechnology.energy_production_left_meta);
	if (productionLeft == nil) then
		return 0;
	else
		return productionLeft;
	end
end

spacetraveltechnology.energy_functions.try_consume_energy = function(position, requiredEnergy, allowPartial, inputPositions)
	local meta = minetest.get_meta(position);
	local energySources = spacetraveltechnology.meta_get_object(meta, spacetraveltechnology.energy_sources_cache_meta);
	if (energySources == nil) then
		energySources = getEnergySources(position, meta, inputPositions);
		spacetraveltechnology.meta_set_object(meta, spacetraveltechnology.energy_sources_cache_meta, energySources);
	end

	local totalEnergyAvailable = tableExt.reduce(energySources, function (sum, value) return sum + getEnergyProduction(value); end, 0);

	if (totalEnergyAvailable < requiredEnergy and not allowPartial) then
		return 0;
	else
		local index = 1;
		local collectedEnergy = 0;

		while (index <= #energySources and collectedEnergy < requiredEnergy) do
			local energySource = energySources[index];
			local energySourceMeta = minetest.get_meta(energySource);
			local energyLeft = energySourceMeta:get_int(spacetraveltechnology.energy_production_left_meta);
			local energyConsumed = math.min(energyLeft, requiredEnergy - collectedEnergy);
			energySourceMeta:set_int(spacetraveltechnology.energy_production_left_meta, energyLeft - energyConsumed);
			collectedEnergy = collectedEnergy + energyConsumed;

			index = index + 1;
		end

		return collectedEnergy;
	end
end
