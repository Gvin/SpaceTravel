local maxFieldHeight = 5;

local function tryConsumeEnergy(position)
    return true;
end

local function getFieldNodes(position, name)
    local result = {};
    for y = 1, maxFieldHeight do
        local pos = {x = position.x, z = position.z, y = position.y + y};
        if (minetest.get_node(pos).name == name) then
            table.insert(result, pos);
        else
            return result;
        end
    end
    return result;
end

local function placeFieldNodes(generatorPosition)
    local positions = getFieldNodes(generatorPosition, "air");
    for _, pos in pairs(positions) do
        minetest.set_node(pos, {name = "spacetravelships:air_blocker_field"});
    end
end

local function removeFieldNodes(generatorPosition)
    local positions = getFieldNodes(generatorPosition, "spacetravelships:air_blocker_field");
    for _, pos in pairs(positions) do
        minetest.set_node(pos, {name = "air"});
    end
end

local function air_blocker_field_generator_on_timer(position, elapsed)
    local active = tryConsumeEnergy(position);

    local infotext = "Air Blocker Field Generator";
    if (active) then
        placeFieldNodes(position);
        infotext = infotext.." (Active)";
    else
        removeFieldNodes(position);
        infotext = infotext.." (Inactive)";
    end

    local meta = minetest.get_meta(position);
    meta:set_string("infotext", infotext);
end

local function air_blocker_field_generator_on_descruct(position)
    removeFieldNodes(position);
end

minetest.register_node("spacetravelships:air_blocker_field_generator", {
    description = "Air Blocker Field Generator",
    tiles = {
        "spacetravelships_ship_hull_light.png^spacetravelships_air_blocker_field_generator.png",
        "spacetravelships_ship_hull_light.png",
        "spacetravelships_ship_hull_light.png",
        "spacetravelships_ship_hull_light.png",
        "spacetravelships_ship_hull_light.png",
        "spacetravelships_ship_hull_light.png"
    },
    is_ground_content = false,
    groups = {cracky = 2},
    on_timer = air_blocker_field_generator_on_timer,
    on_construct = function(position)
        minetest.get_node_timer(position):start(0.5);
    end
});

minetest.register_node("spacetravelships:air_blocker_field", {
    description = "Air Blocker Field",
    tiles = {"spacetravelships_air_blocker_field.png"},
    drawtype = "glasslike_framed",
    is_ground_content = false,
    walkable = false,
    sunlight_propagates = true,
    diggable = false
});
