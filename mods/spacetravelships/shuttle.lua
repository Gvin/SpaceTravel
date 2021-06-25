
--
-- Helper functions
--

local function is_ground(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "cracky") ~= 0
end

local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i/math.abs(i)
	end
end

local function get_velocity(v, yaw, y)
	local x = math.cos(yaw)*v
	local z = math.sin(yaw)*v
	return {x=x, y=y, z=z}
end

local function get_v(v)
	return math.sqrt(v.x^2+v.z^2)
end

--
-- Cart entity
--

local boat = {
	physical = true,
	collisionbox = {-1.5, -0, -1.5, 1.5, 1, 1.5},
	visual = "mesh",
	stepheight = 2.1,
	visual_size = {x=8,y=8,z=8},
	mesh = "shuttle.obj",
	textures = {"spacetravelships_shuttle_texture.png"},
	
	driver = nil,
	vel = {
		horizontal = 0,
		vertical = 0
	}
}

function boat:on_rightclick(clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
	elseif not self.driver then
		self.driver = clicker
		clicker:set_attach(self.object, "", {x=0,y=2,z=0}, {x=180,y=0,z=0})
		self.object:setyaw(clicker:get_look_yaw())
	end
end

function boat:on_activate(staticdata, dtime_s)
	self.object:set_armor_groups({immortal=1})
	if staticdata then
		self.v = tonumber(staticdata)
	end
end

function boat:get_staticdata()
	return tostring(v)
end

function boat:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
	self.object:remove()
	if puncher and puncher:is_player() then
		puncher:get_inventory():add_item("main", "spacetravelships:shuttle_entity")
	end
end

function boat:on_step(dtime)
	self.vel.horizontal = get_v(self.object:getvelocity())*get_sign(self.vel.horizontal);
	self.vel.vertical = self.object:getvelocity().y;

	if self.driver then
		local ctrl = self.driver:get_player_control()
		
		if ctrl.up then
			self.vel.horizontal = self.vel.horizontal + 0.5;
		end
		if ctrl.down then
			self.vel.horizontal = self.vel.horizontal - 0.15;
		end
		if (ctrl.sneak) then
			self.vel.vertical = self.vel.vertical - 0.15;
		end
		if (ctrl.jump) then
			self.vel.vertical = self.vel.vertical + 0.15;
		end
		if ctrl.left then
			self.object:setyaw(self.object:getyaw()+math.pi/120+dtime*math.pi/120)
		end
		if ctrl.right then
			self.object:setyaw(self.object:getyaw()-math.pi/120-dtime*math.pi/120)
		end
	end

	-- Max velocity limit
	local maxVelocity = 4.5;
	self.vel.horizontal = math.min(maxVelocity, math.max(-maxVelocity, self.vel.horizontal));
	self.vel.vertical = math.min(maxVelocity, math.max(-maxVelocity, self.vel.vertical));

	-- Slow down when without input
	self.vel.horizontal = self.vel.horizontal - 0.02 * get_sign(self.vel.horizontal);
	self.vel.vertical = self.vel.vertical - 0.02 * get_sign(self.vel.vertical);

	-- Stop if low velocity
	local minVelocityToStop = 0.1;
	if (math.abs(self.vel.horizontal) <= minVelocityToStop) then
		self.vel.horizontal = 0;
	end
	if (math.abs(self.vel.vertical) <= minVelocityToStop) then
		self.vel.vertical = 0;
	end

	local newVelocity = get_velocity(self.vel.horizontal, self.object:getyaw(), self.vel.vertical);
	self.object:setvelocity(newVelocity);
end

minetest.register_entity("spacetravelships:shuttle_entity", boat)


minetest.register_craftitem("spacetravelships:shuttle", {
	description = "Shuttle",
	inventory_image = "spacetravelships_shuttle_item.png",
	wield_scale = {x=2, y=2, z=1},
	liquids_pointable = true,
	
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		if not is_ground(pointed_thing.under) then
			return
		end
		pointed_thing.under.y = pointed_thing.under.y+2
		minetest.add_entity(pointed_thing.under, "spacetravelships:shuttle_entity")
		itemstack:take_item()
		return itemstack
	end,
})
