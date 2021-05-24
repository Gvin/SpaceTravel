
spacetraveltechnology.block_functions = {};

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
spacetraveltechnology.block_functions.update_cable_connections_on_construct = function(pos)
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
spacetraveltechnology.block_functions.update_cable_connections_on_destruct = function(pos)
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
