local function getShipSpawnComputerFormspec()
    return 
        "size[5,5]"..
        "label[1, 1;New Ship Founding]"..
        "button_exit[1, 3; 3, 1;foundShipBtn;Found New Ship]";
end

local function tryRemoveNewShipToken(player)
    local inventory = player:get_inventory();
    local token = ItemStack("spacetravelships:build_ship_token 1");
    if (inventory:contains_item("main", token)) then
        inventory:remove_item("main", token);
        return true;
    else
        return false;
    end
end

local function findFreePosition(computerPosition, libraryPath)
    local size = spacetravelmap.get_building_size(libraryPath);
    local searchRadius = 10;
    local attemptsCount = 0;
    local shipSizeMax = math.max(size.x, math.max(size.z, size.y));
    while attemptsCount < 100 do
        attemptsCount = attemptsCount + 1;
        local checkPosition = {
            x = computerPosition.x + math.floor((math.random(-1, 1) * searchRadius)),
            y = computerPosition.y + math.floor((math.random(-1, 1) * searchRadius)),
            z = computerPosition.z + math.floor((math.random(-1, 1) * searchRadius))
        };
        local objects = spacetravelships.scan_for_objects(checkPosition, shipSizeMax);
        if (#objects == 0) then
            return checkPosition;
        end

        searchRadius = searchRadius + 10;
    end

    error("Failed to find free position.", 2);
end

local function foundNewShip(computerPosition, player)
    local startingShipLibraryPath = "ships/starting_ship.txt";
    local freePosition = findFreePosition(computerPosition, startingShipLibraryPath);
    local shipId = spacetravelmap.build_from_library(freePosition, startingShipLibraryPath);
    if (shipId == nil) then
        error("Ship Id not generated on ship building.");
    end
    minetest.after(3, function()
        minetest.chat_send_player(player:get_player_name(), "Teleporting to ship core.");
        spacetravelships.teleport_player_to_core(shipId, player)
    end);
end

local function receive_fields(position, formname, fields, sender)
    if (fields.foundShipBtn and sender:is_player()) then
        if (tryRemoveNewShipToken(sender)) then
            foundNewShip(position, sender);
            minetest.chat_send_player(sender:get_player_name(), "Ship founded. Preparing to teleport.");
        else
            minetest.chat_send_player(sender:get_player_name(), "New Ship Token required.");
        end
    end
end

minetest.register_node("spacetravelmap:ship_found_computer", {
    description = "Ship Found Computer",
    tiles = {
        "spacetraveltechnology_machine.png",
        "spacetraveltechnology_machine.png",
        "spacetraveltechnology_machine.png^spacetravelmap_ship_found_computer.png",
        "spacetraveltechnology_machine.png^spacetravelmap_ship_found_computer.png",
        "spacetraveltechnology_machine.png^spacetravelmap_ship_found_computer.png",
        "spacetraveltechnology_machine.png^spacetravelmap_ship_found_computer.png"
    },
    on_timer = ship_spawn_computer_timer,
    on_construct = function(position)
        local meta = minetest.get_meta(position);
        meta:set_string("infotext", "Ship Found Computer");
        meta:set_string("formspec", getShipSpawnComputerFormspec());
    end,
    on_receive_fields = receive_fields
})