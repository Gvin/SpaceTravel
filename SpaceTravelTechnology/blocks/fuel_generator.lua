
-- support for MT game translation.
local S = spacetraveltechnology.get_translator

local metaProducingPowerRate = "spacetraveltechnology:producing_power_rate";
local defaultProducingPowerRate = 5;

function spacetraveltechnology.get_fuel_generator_active_formspec(fuel_percent)
	return "size[8,8.5]"..
		"list[context;fuel;3.5,2.5;1,1;]"..
		"image[3.5,1.5;1,1;fuel_generator_fire_bg.png^[lowpart:"..
		(fuel_percent)..":fuel_generator_fire_fg.png]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[current_player;main]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		spacetraveltechnology.get_hotbar_bg(0, 4.25)
end

function spacetraveltechnology.get_fuel_generator_inactive_formspec()
	return "size[8,8.5]"..
		"list[context;fuel;3.5,2.5;1,1;]"..
		"image[3.5,1.5;1,1;fuel_generator_fire_bg.png]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[current_player;main]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		spacetraveltechnology.get_hotbar_bg(0, 4.25)
end

--
-- Node callback functions that are the same for active and inactive furnace
--

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory();
	return inv:is_empty("fuel");
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "fuel" then
		if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
			if inv:is_empty("src") then
				meta:set_string("infotext", S("Fuel Generator is empty"))
			end
			return stack:get_count();
		else
			return 0;
		end
	else
		return 0;
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function fuel_generator_node_timer(pos, elapsed)
	--
	-- Initialize metadata
	--
	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local fuel_totaltime = meta:get_float("fuel_totaltime") or 0

	local inv = meta:get_inventory()
	local fuellist

	local timer_elapsed = meta:get_int("timer_elapsed") or 0
	meta:set_int("timer_elapsed", timer_elapsed + 1)

	local fuel

	local update = true

	while elapsed > 0 and update do
		update = false
		
		local el = math.min(elapsed, fuel_totaltime - fuel_time);
		
		fuellist = inv:get_list("fuel")

		-- Check if we have enough fuel to burn
		if fuel_time < fuel_totaltime then
			-- The furnace is currently active and has enough fuel
			fuel_time = fuel_time + el
			-- If there is a cookable item then check if it is ready yet
		else
			-- Furnace ran out of fuel
			local afterfuel
			fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})
			
			if fuel.time == 0 then
				-- No valid fuel in fuel list
				fuel_totaltime = 0
			else
				-- Take fuel from fuel list
				inv:set_stack("fuel", 1, afterfuel.items[1])
				update = true
				fuel_totaltime = fuel.time + (fuel_totaltime - fuel_time)
			end
			
			fuel_time = 0
		end

		elapsed = elapsed - el
	end

	if fuel and fuel_totaltime > fuel.time then
		fuel_totaltime = fuel.time
	end

	--
	-- Update formspec, infotext and node
	--
	local formspec

	local fuel_state = S("Empty")
	local active = false
	local result = false

	if fuel_totaltime ~= 0 then
		active = true
		local fuel_percent = 100 - math.floor(fuel_time / fuel_totaltime * 100)
		fuel_state = S("@1%", fuel_percent)
		formspec = spacetraveltechnology.get_fuel_generator_active_formspec(fuel_percent)
		swap_node(pos, "spacetraveltechnology:fuel_generator_active")
		-- make sure timer restarts automatically
		result = true

		-- Play sound every 5 seconds while the generator is active
		if timer_elapsed == 0 or (timer_elapsed+1) % 5 == 0 then
			--minetest.sound_play("default_furnace_active",
				--{pos = pos, max_hear_distance = 16, gain = 0.5}, true)
		end
	else
		if fuellist and not fuellist[1]:is_empty() then
			fuel_state = S("@1%", 0)
		end
		formspec = spacetraveltechnology.get_fuel_generator_inactive_formspec()
		swap_node(pos, "spacetraveltechnology:fuel_generator")
		-- stop timer on the inactive generator
		minetest.get_node_timer(pos):stop()
		meta:set_int("timer_elapsed", 0)
	end

	-- Mark producing power if active
	if (active) then
		local producingPower = meta:get_int(metaProducingPowerRate);
		meta:set_int(spacetraveltechnology.energy_production_left_meta, producingPower);
		meta:set_int(spacetraveltechnology.energy_production_initial_meta, producingPower);
	else
		meta:set_int(spacetraveltechnology.energy_production_left_meta, 0);
		meta:set_int(spacetraveltechnology.energy_production_initial_meta, 0);
	end

	local infotext
	if active then
		infotext = S("Fuel Generator active")
	else
		infotext = S("Fuel Generator inactive")
	end
	infotext = infotext .. "\n" .. S("(Fuel: @1)", fuel_state)

	--
	-- Set meta values
	--
	meta:set_float("fuel_totaltime", fuel_totaltime)
	meta:set_float("fuel_time", fuel_time)
	meta:set_string("formspec", formspec)
	meta:set_string("infotext", infotext)

	return result
end

minetest.register_node("spacetraveltechnology:fuel_generator", {
    description = "Fuel Generator",
    tiles = {
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^fuel_generator_front.png"
	},
	paramtype2 = "facedir",
    groups = {cracky = 2, [spacetraveltechnology.energy_group] = 1},
	is_ground_content = false,
	
	on_timer = fuel_generator_node_timer,
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		
		meta:set_int(metaProducingPowerRate, defaultProducingPowerRate);
		meta:set_int(spacetraveltechnology.energy_production_left_meta, 0);
		meta:set_int(spacetraveltechnology.energy_production_initial_meta, 0);
		meta:set_int(spacetraveltechnology.is_energy_producer_meta, 1);

		local inv = meta:get_inventory();
		inv:set_size('fuel', 1);
		
		fuel_generator_node_timer(pos, 0);
		spacetraveltechnology.energy_functions.update_cable_connections_on_construct(pos);
	end,

	on_destruct = spacetraveltechnology.energy_functions.update_cable_connections_on_destruct,
	
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_take = function(pos)
		-- check whether the furnace is empty or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	
	on_blast = function(pos)
		local drops = {}
		spacetraveltechnology.get_inventory_drops(pos, "fuel", drops);
		drops[#drops+1] = "spacetraveltechnology:fuel_generator"
		minetest.remove_node(pos)
		return drops
	end,
	
	can_dig = can_dig,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take
})

minetest.register_node("spacetraveltechnology:fuel_generator_active", {
	description = "Fuel Generator",
	tiles = {
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		{
			image = "machine.png^fuel_generator_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	paramtype2 = "facedir",

	light_source = 8,
	drop = "spacetraveltechnology:fuel_generator",
	groups = {cracky=2, not_in_creative_inventory=1, [spacetraveltechnology.energy_group] = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,

	on_timer = fuel_generator_node_timer,

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})