
local metaEnergyMaxStorage = "spacetraveltechnology:energy_max_storage";
local metaEnergyStorage = "spacetraveltechnology:energy_storage";
local metaMaxChargeRate = "spacetraveltechnology:max_charge_rate";
local metaMaxProduction = "spacetraveltechnology:max_production";

local S = spacetraveltechnology.get_translator;

local function tryConsumeEnergy(meta, position, requiredEnergy)
	local node = minetest.get_node(position);
	local dir = minetest.facedir_to_dir(node.param2 % 4)
	local inputPos = vector.new(position.x + dir.x * -1, position.y + dir.y * -1, position.z + dir.z * -1);

	return spacetraveltechnology.energy_functions.try_consume_energy(position, requiredEnergy, true, {inputPos});
end

local function accumulator_node_timer(pos, elapsed)
	local meta = minetest.get_meta(pos);
	local maxStorage = meta:get_int(metaEnergyMaxStorage);
	local storage = meta:get_int(metaEnergyStorage);

	-- Charging
	if (storage < maxStorage) then
		local maxChargeRate = meta:get_int(metaMaxChargeRate);
		local requiredEnergy = math.min(maxChargeRate, maxStorage - storage);
		local availableEnergy = tryConsumeEnergy(meta, pos, requiredEnergy);

		storage = math.min(maxStorage, storage + availableEnergy);
	end
	
	-- Production
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
	
	-- Info
	local percent = math.floor(storage*100/maxStorage);
	meta:set_string("infotext", S("Energy Storage: @1 / @2 (@3%)", storage, maxStorage, percent));
	
	return true;
end

-- Registration

spacetraveltechnology.blocks.register_accumulator = function(name, description, maxStorage, maxChargeRate, maxProduction, tiles)
    minetest.register_node(name, {
        description = "Small Accumulator",
        tiles = tiles,
        paramtype2 = "facedir",
        groups = {cracky = 2, [spacetraveltechnology.energy_group] = 1},
        is_ground_content = false,
        
        drop = name,
        
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
