
local metaMenuTab = "spacetravelships:menu_tab";
local metaAreaGrid = "spacetravelships:area_grid";
local metaSelectedZone = "spacetravelships:selected_zone";
local metaZoomStep = "spacetravelships:zoom_step";
local metaMapShift = "spacetravelships:map_shift";
local metaTargetY = "spacetravelships:target_y";

local tabNameControl = "control";
local tabNameConfig = "config";

local tabButtonControl = "controlBtn";
local tabButtonConfig = "configBtn";

local configurationSaveButton = "config_saveBtn";
local configurationSizeLeftField = "config_sizeLeftField";
local configurationSizeRightField = "config_sizeRightField";
local configurationSizeFrontField = "config_sizeFrontField";
local configurationSizeBackField = "config_sizeBackField";
local configurationSizeUpField = "config_sizeUpField";
local configurationSizeDownField = "config_sizeDownField";

local configurationTitleField = "config_TitleField";

local controlZoomInBtn = "control_ZoomIn";
local controlZoomOutBtn = "control_ZoomOut";

local controlMapShiftLeftBtn = "control_MapShiftLeftBtn";
local controlMapShiftRightBtn = "control_MapShiftRightBtn";
local controlMapShiftUpBtn = "control_MapShiftUpBtn";
local controlMapShiftDownBtn = "control_MapShiftDownBtn";
local controlJumpBtn = "control_JumpBtn";
local controlTargetYPlus1Btn = "control_TargetYPlus1Btn";
local controlTargetYMinus1Btn = "control_TargetYMinus1Btn";
local controlTargetYPlus10Btn = "control_TargetYPlus10Btn";
local controlTargetYMinus10Btn = "control_TargetYMinus10Btn";

local gridButtonPrefix = "gridBtn_";

local zoomSteps = {
    1,
    3,
    5
};

local mapDisplaySize = 21;
local gridRadius = 20;
local defaultMapShift = math.floor(gridRadius - mapDisplaySize / 2);
local maxTargetY = 200;
local minTargetY = 1;

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

        "field[0.5,3;1.5,1;"..configurationSizeLeftField..";Left;"..size.left.."]"..
        "field[3.5,3;1.5,1;"..configurationSizeRightField..";Right;"..size.right.."]"..

        "field[0.5,5;1.5,1;"..configurationSizeFrontField..";Front;"..size.front.."]"..
        "field[3.5,5;1.5,1;"..configurationSizeBackField..";Back;"..size.back.."]"..

        "field[0.5,7;1.5,1;"..configurationSizeUpField..";Up;"..size.up.."]"..
        "field[3.5,7;1.5,1;"..configurationSizeDownField..";Down;"..size.down.."]"..
        
        "field[6,3;3,1;"..configurationTitleField..";Title;"..shipTitle.."]"..
        
        "button[0.2,9;2,1;"..configurationSaveButton..";Save]";
end

local function cellContainObject(cell, objectType)
    for _, obj in pairs(cell.objects) do
        if (obj.type == objectType) then
            return true;
        end
    end
    return false;
end

local function cellContainSelf(cell)
    for _, obj in pairs(cell.objects) do
        if (obj.id == "self") then
            return true;
        end
    end
    return false;
end

local function cellContainBorders(cell)
    return cell.borders >= 0.5;
end

local function getMapGridImageMulticells(cellData)
    local resultImage = "spacemap_empty.png";

    if (cellContainSelf(cellData)) then -- If cells contain current ship
        resultImage = resultImage.."^spacemap_borders.png^spacemap_self.png";
    elseif (cellContainObject(cellData, spacetravelships.space_object_types.ship)) then -- If cells contain ship
        resultImage = resultImage.."^spacemap_borders.png^spacemap_ship.png";
    elseif (cellContainObject(cellData, spacetravelships.space_object_types.station)) then -- If cells contain station
        resultImage = resultImage.."^spacemap_borders.png^spacemap_station.png";
    elseif (cellContainBorders(cellData)) then -- No objects, just borders
        resultImage = resultImage.."^spacemap_borders.png";
    end

    if (#cellData.objects > 1) then -- More than 1 object
        resultImage = resultImage.."^spacemap_multi.png";
    end

    return resultImage;
end

local function getMapGridImageSingleCell(cellData, currentDirection)
    local resultImage = "spacemap_empty.png";

    if (cellContainSelf(cellData)) then -- If cells contain current ship
        resultImage = resultImage.."^spacemap_borders.png^spacemap_self.png";
    elseif (cellContainObject(cellData, spacetravelships.space_object_types.ship)) then -- If cells contain ship
        local directionDiff = currentDirection - cellData.objects[1].core_direction;
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
        return "spacemap_empty.png^spacemap_borders.png^spacemap_ship.png"..transformation;
    elseif (cellContainObject(cellData, spacetravelships.space_object_types.station)) then -- If cells contain station
        resultImage = resultImage.."^spacemap_borders.png^spacemap_station.png";
    elseif (cellContainBorders(cellData)) then -- No objects, just borders
        resultImage = resultImage.."^spacemap_borders.png";
    end

    return resultImage;
end

local function getMapGridImage(cellData, currentDirection, zoomLevel)
    if (zoomLevel == 1) then -- No zoom
        return getMapGridImageSingleCell(cellData, currentDirection);
    else
        return getMapGridImageMulticells(cellData);
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

local function get_selected_zone_formspec(areaGrid, selectedZone)
    if (selectedZone == nil) then
        return "";
    end

    local zone = areaGrid[selectedZone.x][selectedZone.y];

    local sizeTextX = "";
    if (zone.size.min_x == zone.size.max_x) then
        sizeTextX = sizeTextX.."X="..zone.size.min_x;
    else
        sizeTextX = sizeTextX.."X=["..zone.size.min_x..";"..zone.size.max_x.."]";
    end

    local sizeTextZ = "";
    if (zone.size.min_z == zone.size.max_z) then
        sizeTextZ = sizeTextZ.."Z="..zone.size.min_z;
    else
        sizeTextZ = sizeTextZ.."Z=["..zone.size.min_z..";"..zone.size.max_z.."]";
    end

    sizeTextX = minetest.formspec_escape(sizeTextX);
    sizeTextZ = minetest.formspec_escape(sizeTextZ);

    return
        "label[8, 1.2;Selection:]"..
        "label[8, 1.7;Objects: "..#zone.objects.."]"..
        "label[8, 2.3;"..sizeTextX.."]"..
        "label[8, 2.8;"..sizeTextZ.."]";
end

local function get_jump_controls(canJump, targetY)
    local targetYText = minetest.formspec_escape("Target Y: "..targetY);
    local result = 
        "label[7.5, 3.5;"..targetYText.."]"..
        "button[9.5, 3.3; 1, 1;"..controlTargetYPlus1Btn..";+1]"..
        "button[10.5, 3.3; 1, 1;"..controlTargetYMinus1Btn..";-1]"..
        "button[11.5, 3.3; 1, 1;"..controlTargetYPlus10Btn..";+10]"..
        "button[12.5, 3.3; 1, 1;"..controlTargetYMinus10Btn..";-10]";

    
    if (not canJump) then
        return result;
    else
        return 
            result..
            "button[8, 5; 2, 1;"..controlJumpBtn..";Jump]";
    end
end

local function get_navigation_computer_control_formspec(areaGrid, currentDirection, selectedZone, zoomLevel, mapShift, canJump, targetY)
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
        
        get_selected_zone_formspec(areaGrid, selectedZone)..
        
        get_jump_controls(canJump, targetY);
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

local function processConfigTabEvents(corePosition, coreMeta, fields)
    if (fieldsContainButton(fields, configurationSaveButton)) then -- Save button
        local size = {
            left = fields[configurationSizeLeftField],
            right = fields[configurationSizeRightField],
            front = fields[configurationSizeFrontField],
            back = fields[configurationSizeBackField],
            up = fields[configurationSizeUpField],
            down = fields[configurationSizeDownField]
        };

        local title = fields[configurationTitleField];

        coreMeta:set_string(spacetravelships.constants.meta_ship_core_size, minetest.serialize(size));
        coreMeta:set_string(spacetravelships.constants.meta_ship_core_title, title);

        local id = coreMeta:get_string(spacetravelships.constants.meta_ship_core_id);
        spacetravelships.update_space_object(id, title, corePosition, size);
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

local function processControlTabEvents(meta, coreMeta, corePosition, fields, spaceObject)
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
    elseif (fieldsContainButton(fields, controlTargetYPlus1Btn)) then
        local targetY = meta:get_int(metaTargetY);
        meta:set_int(metaTargetY, math.min(maxTargetY - spaceObject.size.up, targetY + 1));
    elseif (fieldsContainButton(fields, controlTargetYPlus10Btn)) then
        local targetY = meta:get_int(metaTargetY);
        meta:set_int(metaTargetY, math.min(maxTargetY - spaceObject.size.up, targetY + 10));
    elseif (fieldsContainButton(fields, controlTargetYMinus1Btn)) then
        minetest.log("-1")
        local targetY = meta:get_int(metaTargetY);
        meta:set_int(metaTargetY, math.max(minTargetY + spaceObject.size.down, targetY - 1));
    elseif (fieldsContainButton(fields, controlTargetYMinus10Btn)) then
        local targetY = meta:get_int(metaTargetY);
        meta:set_int(metaTargetY, math.max(minTargetY + spaceObject.size.down, targetY - 10));
    elseif (fieldsContainButton(fields, controlJumpBtn)) then -- Jump
        minetest.log("Jump initiated");
        local areaGrid = meta_get_object(meta, metaAreaGrid);
        local selectedZone = meta_get_object(meta, metaSelectedZone);
        if (areaGrid ~= nil and selectedZone ~= nil) then
            local targetMapZone = areaGrid[selectedZone.x][selectedZone.y];
            local shipId = coreMeta:get_string(spacetravelships.constants.meta_ship_core_id);
            local targetY = meta:get_int(metaTargetY);
            local targetPosition = {
                x = targetMapZone.size.min_x,
                z = targetMapZone.size.min_z,
                y = targetY
            };
            spacetravelships.move_to_position(shipId, targetPosition);
        end
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
    local spaceObject = spacetravelships.get_owning_object(position);
    if (spaceObject == nil) then
        return;
    end

    local currentTab = meta:get_string(metaMenuTab);

    if (fieldsContainButton(fields, tabButtonControl)) then -- Tab Control
        meta:set_string(metaMenuTab, tabNameControl);
    elseif (fieldsContainButton(fields, tabButtonConfig)) then -- Tab Configuration
        meta:set_string(metaMenuTab, tabNameConfig);
    end

    local coreMeta = minetest.get_meta(spaceObject.core_position);
    if (currentTab == tabNameControl) then -- Control tab events
        processControlTabEvents(meta, coreMeta, spaceObject.core_position, fields, spaceObject);
    elseif (currentTab == tabNameConfig) then -- Configuration tab events
        processConfigTabEvents(spaceObject.core_position, coreMeta, fields);
    end

    minetest.log("formname="..formname.."; fields="..minetest.serialize(fields));
end

local function isPointInBorders(position, obj)
    return
        position.x >= obj.cube.min_x and position.x <= obj.cube.max_x and
        position.z >= obj.cube.min_z and position.z <= obj.cube.max_z;
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
    local objects = spacetravelships.scan_for_objects(corePosition, scanRadius);

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

            local cellObjects = {};
            local cellSize = {
                min_x = dataGrid[dataGridX][dataGridY].position.x,
                max_x = dataGrid[dataGridX][dataGridY].position.x,
                min_z = dataGrid[dataGridX][dataGridY].position.z,
                max_z = dataGrid[dataGridX][dataGridY].position.z
            };
            local bordersCount = 0;
            for x = dataGridX, dataGridX + zoomLevel - 1 do
                for y = dataGridY, dataGridY + zoomLevel - 1 do
                    if (x <= #dataGrid and y <= #dataGrid[x]) then
                        local cell = dataGrid[x][y];
                        if (cell.type == "object" and cell.object ~= nil) then
                            table.insert(cellObjects, cell.object);
                        end
                        if (cell.type == "borders") then
                            bordersCount = bordersCount + 1;
                        end
                        cellSize.min_x = math.min(cellSize.min_x, cell.position.x);
                        cellSize.max_x = math.max(cellSize.max_x, cell.position.x);
                        cellSize.min_z = math.min(cellSize.min_z, cell.position.z);
                        cellSize.max_z = math.max(cellSize.max_z, cell.position.z);
                    end
                end
            end
            grid[gridX][gridY] = {
                objects = cellObjects,
                size = cellSize,
                borders = bordersCount / (zoomLevel * zoomLevel);
            };
        end
    end

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

        local targetY = meta:get_int(metaTargetY);
        if (targetY == nil or targetY == 0) then
            targetY = corePosition.y;
            meta:set_int(metaTargetY, targetY);
        end

        local canJump = false;
        if (selectedZone ~= nil) then
            local targetMapZone = areaGrid[selectedZone.x][selectedZone.y];
            local shipId = coreMeta:get_string(spacetravelships.constants.meta_ship_core_id);
            local targetPosition = {
                x = targetMapZone.size.min_x,
                z = targetMapZone.size.min_z,
                y = targetY
            }
            canJump = spacetravelships.can_move_to_position(shipId, targetPosition);
        end
        
        return get_navigation_computer_control_formspec(areaGrid, coreDirection, selectedZone, zoomLevel, mapShift, canJump, targetY);

    elseif (menuTabName == tabNameConfig) then
        local shipId = coreMeta:get_string(spacetravelships.constants.meta_ship_core_id);
        local shipTitle = coreMeta:get_string(spacetravelships.constants.meta_ship_core_title);
        local shipSize = meta_get_object(coreMeta, spacetravelships.constants.meta_ship_core_size);
        return get_navigation_computer_configuration_formspec(shipId, shipTitle, shipSize);
    end

    minetest.log("Unknown menu tab name: "..menuTabName);
    return get_navigation_computer_inactive_formspec();
end

local function navigation_computer_node_timer(position, elapsed)
    local meta = minetest.get_meta(position);
    local spaceObject = spacetravelships.get_owning_object(position);

    local formspec = get_navigation_computer_inactive_formspec();

    if (spaceObject ~= nil) then
        local coreMeta = minetest.get_meta(spaceObject.core_position);
        formspec = getFormspecForActiveComputer(meta, spaceObject.core_position, coreMeta);
    end

    meta:set_string("formspec", formspec);

    return true;
end

minetest.register_node("spacetravelships:navigation_computer", {
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
    groups = {cracky = 2},
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
