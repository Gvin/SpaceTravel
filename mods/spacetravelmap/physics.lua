local gravityInSpace = 0;
local gravityWithGenerator = 0.5;

local function setPlayerGravity(player, gravity)
    local speed = 1;
    if (gravity == 0) then -- Limiting speed in vacuum
        speed = 0.1;
    end
    player:set_physics_override({ gravity=gravity, speed = speed });
end

local function getPlayerExpectedGravity(player)
    local position = player:get_pos();
    local owningSpaceObject = spacetravelships.get_owning_object(position);
    if (owningSpaceObject == nil) then -- In open space
        return gravityInSpace;
    end

    if (spacetravelships.get_has_gravity(owningSpaceObject.id)) then
        return gravityWithGenerator;
    else
        return gravityInSpace;
    end
end

spacetravelmap.update_players_gravity = function()
    for _,player in ipairs(minetest.get_connected_players()) do
        local expectedGravity = getPlayerExpectedGravity(player);
        setPlayerGravity(player, expectedGravity);
    end
end
