local S = spacetraveltechnology.get_translator;

local powerRequiredToWork = 5;

function spacetraveltechnology.get_electric_furnace_active_formspec(item_percent)
	return "size[8,8.5]"..
		"list[context;src;2.75,1.5;1,1;]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..
		"list[context;dst;4.75,1.5;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

function spacetraveltechnology.get_electric_furnace_inactive_formspec()
	return "size[8,8.5]"..
		"list[context;src;2.75,1.5;1,1;]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"list[context;dst;4.75,1.5;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory();
	return inv:is_empty("src") and inv:is_empty("dst");
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

local function tryConsumeEnergy(pos)
    return spacetraveltechnology.energy_functions.try_consume_energy(pos, powerRequiredToWork, false) == powerRequiredToWork;
end

local function electric_furnace_node_timer(pos, elapsed)
    local meta = minetest.get_meta(pos)

	local src_time = meta:get_float("src_time") or 0;

	local inv = meta:get_inventory();
	local srclist = inv:get_list("src");
	local dst_full = false;

    local cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
    local cookable = cooked.time ~= 0;

    local active = false;

    if cookable then
        local energyConsumed = tryConsumeEnergy(pos);
        if (energyConsumed) then
            active = true;
            src_time = src_time + elapsed;
            if src_time >= cooked.time then
                -- Place result in dst list if possible
                if inv:room_for_item("dst", cooked.item) then
                    inv:add_item("dst", cooked.item)
                    inv:set_stack("src", 1, aftercooked.items[1])
                    src_time = src_time - cooked.time
                else
                    dst_full = true
                end
                -- Play cooling sound
                minetest.sound_play("default_cool_lava",
                    {pos = pos, max_hear_distance = 16, gain = 0.1}, true)
            end
        end
    end

    if srclist and srclist[1]:is_empty() then
		src_time = 0;
        minetest.get_node_timer(pos):stop();
	end

    local formspec
	local item_state
	local item_percent = 0
	if cookable then
		item_percent = math.floor(src_time / cooked.time * 100)
		if dst_full then
			item_state = S("100% (output full)")
		else
			item_state = S("@1%", item_percent)
		end
	else
		if srclist and not srclist[1]:is_empty() then
			item_state = S("Not cookable")
		else
			item_state = S("Empty")
		end
	end

    if (active) then
        formspec = spacetraveltechnology.get_electric_furnace_active_formspec(item_percent);
		swap_node(pos, "spacetraveltechnology:electric_furnace_active");
    else
        formspec = spacetraveltechnology.get_electric_furnace_inactive_formspec();
		swap_node(pos, "spacetraveltechnology:electric_furnace");
    end


	local infotext
	if active then
		infotext = S("Furnace active")
	else
		infotext = S("Furnace inactive")
	end
	infotext = infotext .. "\n" .. S("(Item: @1)", item_state)

	--
	-- Set meta values
	--
	meta:set_float("src_time", src_time)
	meta:set_string("formspec", formspec)
	meta:set_string("infotext", infotext)

	return true;
end

minetest.register_node("spacetraveltechnology:electric_furnace", {
    description = S("Electric Furnace"),
    tiles = {
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^electric_furnace_front.png"
	},
	paramtype2 = "facedir",
    groups = {cracky = 2, [spacetraveltechnology.energy_group] = 1},
	is_ground_content = false,
	
	on_timer = electric_furnace_node_timer,
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);

		local inv = meta:get_inventory();
		inv:set_size('src', 1);
        inv:set_size('dst', 1);
		
        minetest.get_node_timer(pos):start(0.5);

		spacetraveltechnology.energy_functions.update_cable_connections_on_construct(pos);

        electric_furnace_node_timer(pos, 0);
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
		drops[#drops+1] = "spacetraveltechnology:electric_furnace"
		minetest.remove_node(pos)
		return drops
	end,
	
	can_dig = can_dig,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take
})

minetest.register_node("spacetraveltechnology:electric_furnace_active", {
	description = S("Electric Furnace"),
	tiles = {
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^electric_furnace_front_active.png"
	},
	paramtype2 = "facedir",

	light_source = 8,
	drop = "spacetraveltechnology:electric_furnace",
	groups = {cracky=2, not_in_creative_inventory=1, [spacetraveltechnology.energy_group] = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,

	on_timer = electric_furnace_node_timer,

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})