
local metaMenuTab = "spacetravelinit:menu_tab";
local metaAreaGrid = "spacetravelinit:area_grid";
local metaSelectedZone = "spacetravelinit:selected_zone";
local metaZoomStep = "spacetravelinit:zoom_step";
local metaMapShift = "spacetravelinit:map_shift";

local tabNameControl = "control";
local tabNameConfig = "config";

local tabButtonControl = "controlBtn";
local tabButtonConfig = "configBtn";

local configurationSaveButton = "config_saveBtn";
local configurationSizeXField = "config_sizeXField";
local configurationSizeYField = "config_sizeYField";
local configurationSizeZField = "config_sizeZField";
local configurationTitleField = "config_TitleField";

local controlZoomInBtn = "controlZoomIn";
local controlZoomOutBtn = "controlZoomOut";

local controlMapShiftLeftBtn = "controlMapShiftLeftBtn";
local controlMapShiftRightBtn = "controlMapShiftRightBtn";
local controlMapShiftUpBtn = "controlMapShiftUpBtn";
local controlMapShiftDownBtn = "controlMapShiftDownBtn";

local gridButtonPrefix = "gridBtn_";

local zoomSteps = {
    1,
    3,
    5
};

local mapDisplaySize = 21;
local gridRadius = 20;
local defaultMapShift = math.floor(gridRadius - mapDisplaySize / 2);

local function get_navigation_computer_inactive_formspec()
    return "size[15,10]"..
            "label[6,4;Ship Core Not Connected]";
end

local function getTabsButtons()
    return 
        "button[0.2,0.2;2,1;"..tabButtonControl..";Control]"..
        "button[2,0.2;3,1;"..tabButtonConfig..";Configuration]";
end

local function get_navigation_computer_configuration_formspec(shipId, shipTitle, size)
    return 
        "size[15,10]"..
        getTabsButtons()..

        "label[0.2,1.2;Configuration]"..

        "label[4,1.2;Ship ID: "..shipId.."]"..

        "field[0.5,3;1.5,1;"..configurationSizeXField..";Size X;"..size.x.."]"..
        "field[0.5,4.5;1.5,1;"..configurationSizeYField..";Size Y;"..size.y.."]"..
        "field[0.5,6;1.5,1;"..configurationSizeZField..";Size Z;"..size.z.."]"..
        
        "field[4,3;3,1;"..configurationTitleField..";Title;"..shipTitle.."]"..
        
        "button[0.2,9;2,1;"..configurationSaveButton..";Save]";
end

local function cellsContainObject(cells, objectType)
    for _, cell in pairs(cells) do
        if (cell.type == "object" and cell.object ~= nil and cell.object.type == objectType) then
            return true;
        end
    end
    return false;
end

local function cellsContainMultipleObjects(cells)
    local objectFound = false;
    for _, cell in pairs(cells) do
        if (cell.type == "object" and cell.object ~= nil) then
            if (objectFound) then
                return true;
            else
                objectFound = true;
            end
        end
    end
    return false;
end

local function cellsContainSelf(cells)
    for _, cell in pairs(cells) do
        if (cell.type == "object" and cell.object ~= nil and cell.object.id == "self") then
            return true;
        end
    end
    return false;
end

local function cellsContainBorders(cells)
    local bordersCount = 0;
    for _, cell in pairs(cells) do
        if (cell.type == "borders") then
            bordersCount = bordersCount + 1;
        end
    end
    return bordersCount / #cells >= 0.5;
end

local function getMapGridImageMulticells(cells)
    local resultImage = "spacemap_empty.png";

    if (cellsContainSelf(cells)) then -- If cells contain current ship
        resultImage = resultImage.."^spacemap_borders.png^spacemap_self.png";
    elseif (cellsContainObject(cells, spacetravelcore.space_object_types.ship)) then -- If cells contain ship
        resultImage = resultImage.."^spacemap_borders.png^spacemap_ship.png";
    elseif (cellsContainObject(cells, spacetravelcore.space_object_types.station)) then -- If cells contain station
        resultImage = resultImage.."^spacemap_borders.png^spacemap_station.png";
    elseif (cellsContainBorders(cells)) then -- No objects, just borders
        resultImage = resultImage.."^spacemap_borders.png";
    end

    if (cellsContainMultipleObjects(cells)) then -- More than 1 object
        resultImage = resultImage.."^spacemap_multi.png";
    end

    return resultImage;
end

local function getMapGridImageSingleCell(data, currentDirection)
    if (data.type == "empty") then
        return "spacemap_empty.png";
    elseif (data.type == "borders") then
        return "spacemap_empty.png^spacemap_borders.png";
    elseif (data.type == "object" and data.object ~= nil) then
        if (data.object.type == spacetravelcore.space_object_types.ship) then
            local shipImage = "spacemap_ship.png";
            if (data.object.id == "self") then
                shipImage = "spacemap_self.png";
            end
            local transformation = "";
            local directionDiff = currentDirection - data.object.core_direction;
            if (directionDiff > 0) then
                directionDiff = directionDiff - 360;
            end
            if (directionDiff == -180) then -- ^v
                transformation = "^[transformR180";
            elseif (directionDiff == -90) then -- ^>
                transformation = "^[transformR90";
            elseif (directionDiff == -270) then -- <v
                transformation = "^[transformR270";
            end
            return "spacemap_empty.png^spacemap_borders.png^"..shipImage..transformation;
        elseif (data.object.type == spacetravelcore.space_object_types.station) then
            return "spacemap_empty.png^spacemap_borders.png^spacemap_station.png";
        end
    end

    return "spacemap_empty.png^spacemap_unknown.png";
end

local function getMapGridImage(cells, currentDirection, zoomLevel)
    if (zoomLevel == 1) then -- No zoom
        return getMapGridImageSingleCell(cells[1], currentDirection);
    else
        return getMapGridImageMulticells(cells);
    end
end

local function get_map_grid_formspec(areaGrid, currentDirection, selectedZone, zoomLevel, mapShift)
    local leftShift = 1;
    local topShift = 2;
    local imageSize = 0.5;
    local sizeMultiplierY = 0.33;
    local sizeMultiplierX = 0.28;
    local result = "";

    for indexX = 1, mapDisplaySize do
        for indexY = 1, mapDisplaySize do
            local x = indexX + mapShift.x;
            local y = indexY + mapShift.y;
            if (x <= #areaGrid and y <= #areaGrid[x]) then
                local btnX = leftShift + indexX  * sizeMultiplierX;
                local btnY = topShift + indexY * sizeMultiplierY;
                
                local image = getMapGridImage(areaGrid[x][y], currentDirection, zoomLevel);

                local selected = selectedZone ~= nil and selectedZone.x == x and selectedZone.y == y;
                if (selected) then
                    image = image.."^spacemap_selected.png";
                end

                local name = gridButtonPrefix..x.."_"..y;
                result = result.."image_button["..btnX..","..btnY..";"..imageSize..","..imageSize..";"..image..";"..name..";]";
            end
        end
    end

    return result;
end

local function countObjects(zone)
    local result = 0;
    for _, cell in pairs(zone) do
        if (cell.type == "object") then
            result = result + 1;
        end
    end
    return result;
end

local function calculateZoneSize(zone)
    local minX = zone[1].position.x;
    local maxX = minX;
    local minZ = zone[1].position.z;
    local maxZ = minZ;
    for _, cell in pairs(zone) do
        if (cell.position.x < minX) then
            minX = cell.position.x;
        end
        if (cell.position.x > maxX) then
            maxX = cell.position.x;
        end
        if (cell.position.z < minZ) then
            minZ = cell.position.z;
        end
        if (cell.position.z > maxZ) then
            maxZ = cell.position.z;
        end
    end

    return minX, maxX, minZ, maxZ;
end

local function get_selected_zone_formspec(areaGrid, selectedZone)
    if (selectedZone == nil) then
        return "";
    end

    local zone = areaGrid[selectedZone.x][selectedZone.y];
    local minX, maxX, minZ, maxZ = calculateZoneSize(zone);

    local sizeTextX = "";
    if (minX == maxX) then
        sizeTextX = sizeTextX.."X="..minX;
    else
        sizeTextX = sizeTextX.."X=["..minX..";"..maxX.."]";
    end

    local sizeTextZ = "";
    if (minZ == maxZ) then
        sizeTextZ = sizeTextZ.."Z="..minZ;
    else
        sizeTextZ = sizeTextZ.."Z=["..minZ..";"..maxZ.."]";
    end

    sizeTextX = minetest.formspec_escape(sizeTextX);
    sizeTextZ = minetest.formspec_escape(sizeTextZ);

    return
        "label[8, 1.2;Selection:]"..
        "label[8, 1.7;Objects: "..countObjects(zone).."]"..
        "label[8, 2.3;"..sizeTextX.."]"..
        "label[8, 2.8;"..sizeTextZ.."]";
end

local function get_navigation_computer_control_formspec(areaGrid, currentDirection, selectedZone, zoomLevel, mapShift)
    return 
        "size[15,10]"..
        getTabsButtons()..

        "label[0.2,1.2;Control]"..
        "label[0.2,1.7;Rotation: "..currentDirection.."]"..

        "button[0.2, 2.2; 0.5, 6;"..controlMapShiftLeftBtn..";<]"..
        "button[7.5, 2.2; 0.5, 6;"..controlMapShiftRightBtn..";>]"..
        "button[3.5, 1.7; 2, 1;"..controlMapShiftUpBtn..";^]"..
        "button[3.5, 9; 2, 1;"..controlMapShiftDownBtn..";V]"..
        
        get_map_grid_formspec(areaGrid, currentDirection, selectedZone, zoomLevel, mapShift)..

        "button[0.5,9.5;1.5,1;"..controlZoomInBtn..";Zoom +]"..
        "button[1.8,9.5;1.5,1;"..controlZoomOutBtn..";Zoom -]"..
        "label[3.5,9.7;1X"..zoomLevel.."]"..
        
        get_selected_zone_formspec(areaGrid, selectedZone);
end

local function meta_get_object(meta, name)
    local str = meta:get_string(name);
    if (not str) then
        return nil;
    end
    return minetest.deserialize(str);
end

local function fieldsContainButton(fields, buttonName)
    for name, _ in pairs(fields) do
        if (name == buttonName) then
            return true;
        end
    end
    return false;
end

local function processConfigTabEvents(coreMeta, fields)
    if (fieldsContainButton(fields, configurationSaveButton)) then -- Save button
        local size = {};
        size.x = fields[configurationSizeXField];
        size.y = fields[configurationSizeXField];
        size.z = fields[configurationSizeXField];

        local title = fields[configurationTitleField];

        coreMeta:set_string("spacetravelinit:ship_core_size", minetest.serialize(size));
        coreMeta:set_string("spacetravelinit:ship_core_title", title);
    end
end

local function findGridButtonEvent(fields)
    for name, _ in pairs(fields) do
        if (string.sub(name, 1, string.len(gridButtonPrefix)) == gridButtonPrefix) then
            return name;
        end
    end
    return nil;
end

local function processControlTabEvents(meta, fields)
    if (fieldsContainButton(fields, controlZoomOutBtn)) then -- Zoom -
        local zoomStep = meta:get_int(metaZoomStep);
        zoomStep = math.max(1, zoomStep);
        meta:set_int(metaZoomStep, math.min(#zoomSteps, zoomStep + 1));
    elseif (fieldsContainButton(fields, controlZoomInBtn)) then -- Zoom +
        local zoomStep = meta:get_int(metaZoomStep);
        zoomStep = math.max(1, zoomStep);
        meta:set_int(metaZoomStep, math.max(1, zoomStep - 1));
    elseif (fieldsContainButton(fields, controlMapShiftLeftBtn)) then -- Map Shift Left
        local mapShift = meta_get_object(meta, metaMapShift);
        if (mapShift == nil) then
            mapShift = {
                x = 0,
                y = 0
            };
        end
        mapShift.x = math.max(0, mapShift.x - 1);
        meta:set_string(metaMapShift, minetest.serialize(mapShift));
        minetest.log(minetest.serialize(mapShift))
    elseif (fieldsContainButton(fields, controlMapShiftRightBtn)) then -- Map Shift Right
        local mapShift = meta_get_object(meta, metaMapShift);
        if (mapShift == nil) then
            mapShift = {
                x = 0,
                y = 0
            };
        end
        mapShift.x = mapShift.x + 1;
        meta:set_string(metaMapShift, minetest.serialize(mapShift));
        minetest.log(minetest.serialize(mapShift))
    elseif (fieldsContainButton(fields, controlMapShiftUpBtn)) then -- Map Shift Up
        local mapShift = meta_get_object(meta, metaMapShift);
        if (mapShift == nil) then
            mapShift = {
                x = 0,
                y = 0
            };
        end
        mapShift.y = math.max(0, mapShift.y - 1);
        meta:set_string(metaMapShift, minetest.serialize(mapShift));
        minetest.log(minetest.serialize(mapShift))
    elseif (fieldsContainButton(fields, controlMapShiftDownBtn)) then -- Map Shift Down
        local mapShift = meta_get_object(meta, metaMapShift);
        if (mapShift == nil) then
            mapShift = {
                x = 0,
                y = 0
            };
        end
        mapShift.y = mapShift.y + 1;
        meta:set_string(metaMapShift, minetest.serialize(mapShift));
        minetest.log(minetest.serialize(mapShift))
    else -- Grid click
        local gridButtonEvent = findGridButtonEvent(fields);
        if (gridButtonEvent == nil) then
            return;
        end

        local areaGrid = meta_get_object(meta, metaAreaGrid);
        if (areaGrid == nil) then
            return;
        end

        local indexesPart = string.sub(gridButtonEvent, string.len(gridButtonPrefix) + 1, string.len(gridButtonEvent));

        local separatorIndex = string.find(indexesPart, "%_");
        local x = string.sub(indexesPart, 1, separatorIndex - 1);
        local y = string.sub(indexesPart, separatorIndex + 1, string.len(indexesPart));

        meta:set_string(metaSelectedZone, minetest.serialize({x = tonumber(x), y = tonumber(y)}));
    end
end

local function navigation_computer_receive_fields(position, formname, fields, sender)
    local meta = minetest.get_meta(position);
    local corePosition = meta_get_object(meta, "spacetravelinit:controllable_position");
    if (corePosition == nil) then
        return;
    end

    local currentTab = meta:get_string(metaMenuTab);

    if (fieldsContainButton(fields, tabButtonControl)) then -- Tab Control
        meta:set_string(metaMenuTab, tabNameControl);
    elseif (fieldsContainButton(fields, tabButtonConfig)) then -- Tab Configuration
        meta:set_string(metaMenuTab, tabNameConfig);
    end

    local coreMeta = minetest.get_meta(corePosition);
    if (currentTab == tabNameControl) then
        processControlTabEvents(meta, fields);
    elseif (currentTab == tabNameConfig) then -- Configuration tab events
        processConfigTabEvents(coreMeta, fields);
    end

    minetest.log("formname="..formname.."; fields="..minetest.serialize(fields));
end

local function isPointInBorders(position, obj)
    local minX = obj.core_position.x - obj.size.x;
    local maxX = obj.core_position.x + obj.size.x;
    local minZ = obj.core_position.z - obj.size.z;
    local maxZ = obj.core_position.z + obj.size.z;
    return
        position.x >= minX and position.x <= maxX and
        position.z >= minZ and position.z <= maxZ;
end

local function getGridRecord(position, objects, corePosition)
    local result = {
        type = "empty",
        position = position
    };
    for _, obj in pairs(objects) do
        if (obj.core_position.x == position.x and obj.core_position.z == position.z) then
            result.type = "object";
            result.object = obj;
            if (position.x == corePosition.x and position.z == corePosition.z) then
                result.object.id = "self";
            end
        elseif (isPointInBorders(position, obj)) then
            result.type = "borders";
        end
    end

    return result;
end

local function rotateGrid90(grid)
    local out = {};
    for x = 1, #grid do
        table.insert(out, {});
    end
        
    for yIndex, x in pairs(grid) do
        for y = 1, #grid do
            out[y][#grid + 1 - yIndex] = x[y];
        end
    end
    
    return out;
end

local function rotateGrid(grid, coreDirection)
    local data = grid;
    local rotationsCount =(360 - coreDirection) / 90;

    for i = 1, rotationsCount do
        data = rotateGrid90(data);
    end
    return data;
end

local function fetchAreaGrid(meta, corePosition, coreDirection, coreMeta, scanRadius)
    local left = corePosition.x - scanRadius;
    local right = corePosition.x + scanRadius;
    local top = corePosition.z - scanRadius;
    local bottom = corePosition.z + scanRadius;
    local objects = spacetravelcore.scan_for_objects(corePosition, scanRadius);

    local grid = {};

    for x =  1, scanRadius * 2 + 1  do
        table.insert(grid, {});
        local zPos = top;
        for z = 1, scanRadius * 2 + 1 do
            local cellPos = {
                x = left + z - 1,
                z = top + x - 1
            };
            local record = getGridRecord(cellPos, objects, corePosition);
            table.insert(grid[x], record);
        end
    end

    return rotateGrid(grid, coreDirection);
end

local function buildAreaGrid(meta, corePosition, coreDirection, coreMeta, zoomLevel)
    local scanSize = gridRadius * zoomLevel;
    local dataGrid = fetchAreaGrid(meta, corePosition, coreDirection, coreMeta, scanSize);
    -- In blocs zoomLevel X zoomLevel
    local grid = {};

    for gridX = 1, gridRadius * 2 + 1 do
        table.insert(grid, {});
        local dataGridX = 1 + (gridX - 1) * zoomLevel;
        for gridY = 1, gridRadius * 2 + 1 do
            table.insert(grid[gridX], {});
            local dataGridY = 1 + (gridY - 1) * zoomLevel;

            for x = dataGridX, dataGridX + zoomLevel - 1 do
                for y = dataGridY, dataGridY + zoomLevel - 1 do
                    if (x <= #dataGrid and y <= #dataGrid[x]) then
                        local cell = dataGrid[x][y];
                        table.insert(grid[gridX][gridY], cell);
                    end
                end
            end
        end
    end

    -- local file = io.open(minetest.get_worldpath().."/grid.txt", "w")
    -- if file then
    --     file:write(minetest.serialize(grid))
    --     file:close()
    -- end

    return grid;
end

local function convertDirection(dir)
    if (dir == 3) then -- X+
        return 180;
    elseif (dir == 1) then -- X-
        return 0;
    elseif (dir == 2) then -- Z+
        return 270;
    elseif (dir == 0) then -- Z-
        return 90;
    end
    error("Unable to convert direction: "..dir);
end

local function getFormspecForActiveComputer(meta, corePosition, coreMeta)
    local menuTabName = meta:get_string(metaMenuTab);

    if (menuTabName == nil or menuTabName == tabNameControl) then
        local coreNode = minetest.get_node(corePosition);
        local coreDirection = convertDirection(coreNode.param2);

        local zoomStep = meta:get_int(metaZoomStep);
        zoomStep = math.max(1, zoomStep);
        local zoomLevel = zoomSteps[zoomStep];

        local areaGrid = buildAreaGrid(meta, corePosition, coreDirection, coreMeta, zoomLevel);
        meta:set_string(metaAreaGrid, minetest.serialize(areaGrid));
        local selectedZone = meta_get_object(meta, metaSelectedZone);

        local mapShift = meta_get_object(meta, metaMapShift);
        if (mapShift == nil) then
            mapShift = {
                x = defaultMapShift,
                y = defaultMapShift
            };
            meta:set_string(metaMapShift, minetest.serialize(mapShift));
        end
        if (areaGrid ~= nil and mapShift.x > #areaGrid - mapDisplaySize) then
            mapShift.x = #areaGrid - mapDisplaySize;
            meta:set_string(metaMapShift, minetest.serialize(mapShift));
        end
        if (areaGrid ~= nil and mapShift.y > #areaGrid - mapDisplaySize) then
            mapShift.y = #areaGrid - mapDisplaySize;
            meta:set_string(metaMapShift, minetest.serialize(mapShift));
        end  
        
        return get_navigation_computer_control_formspec(areaGrid, coreDirection, selectedZone, zoomLevel, mapShift);

    elseif (menuTabName == tabNameConfig) then
        local shipId = coreMeta:get_string("spacetravelinit:ship_core_id");
        local shipTitle = coreMeta:get_string("spacetravelinit:ship_core_title");
        local shipSize = meta_get_object(coreMeta, "spacetravelinit:ship_core_size");
        return get_navigation_computer_configuration_formspec(shipId, shipTitle, shipSize);
    end

    minetest.log("Unknown menu tab name: "..menuTabName);
    return get_navigation_computer_inactive_formspec();
end

local function navigation_computer_node_timer(position, elapsed)
    local meta = minetest.get_meta(position);
    local connectedPosition = meta_get_object(meta, "spacetravelinit:controllable_position");

    local formspec = get_navigation_computer_inactive_formspec();

    if (connectedPosition ~= nil) then
        local connectedNode = minetest.get_node(connectedPosition);
        if (connectedNode.name == "spacetravelinit:ship_core") then
            local coreMeta = minetest.get_meta(connectedPosition);
            formspec = getFormspecForActiveComputer(meta, connectedPosition, coreMeta);
        end
    end

    meta:set_string("formspec", formspec);

    return true;
end

minetest.register_node("spacetravelinit:navigation_computer", {
    description = "Navigation Computer",
    tiles = {
        "machine.png",
        "machine.png",
        "machine.png",
        "machine.png",
        "machine.png",
        "machine.png^navigation_computer_front.png"
    },
    paramtype2 = "facedir",
    groups = {cracky = 2, ["tunable_controller"] = 1},
    is_ground_content = false,
    light_source = 2,
    on_timer = navigation_computer_node_timer,
    on_construct = function(position)
        local meta = minetest.get_meta(position);
        meta:set_string(metaMenuTab, tabNameControl);

        minetest.get_node_timer(position):start(0.5);
    end,
    on_receive_fields = navigation_computer_receive_fields
});
