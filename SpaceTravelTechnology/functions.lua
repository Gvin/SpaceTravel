
function spacetraveltechnology.get_hotbar_bg(x,y)
	local out = ""
	for i=0,7,1 do
		out = out .."image["..x+i..","..y..";1,1;gui_hb_bg.png]"
	end
	return out
end

function spacetraveltechnology.get_inventory_drops(pos, inventory, drops)
	local inv = minetest.get_meta(pos):get_inventory()
	local n = #drops
	for i = 1, inv:get_size(inventory) do
		local stack = inv:get_stack(inventory, i)
		if stack:get_count() > 0 then
			drops[n+1] = stack:to_table()
			n = n + 1
		end
	end
end

function spacetraveltechnology.meta_set_object(meta, name, obj)
	local objString = minetest.serialize(obj);
	meta:set_string(name, objString);
end

function spacetraveltechnology.meta_get_object(meta, name)
	local objString = meta:get_string(name);
	if (objString == nil or string.len(objString) == 0) then
		return nil;
	else
		return minetest.deserialize(objString);
	end
end

spacetraveltechnology.table = {};

spacetraveltechnology.table.any = function(tbl, checkFnc)
	for _, element in pairs(tbl) do
		if (checkFnc(element)) then
			return true;
		else
			return false;
		end
	end
end
