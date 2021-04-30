local function recursive_multiply(source, multiplier)
	for key, value in pairs(multiplier) do
		assert(type(source[key]) == type(value))
		if type(value) == "table" then
			recursive_multiply(source[key], value)
		else
			source[key] = source[key] * value
		end
	end
end

local function get_shooter_specs(weapon_name, multiplier)
	local spec = shooter.registered_weapons[weapon_name]
	if not spec then
		return nil
	end

	spec = table.copy(spec.spec)

	if multiplier then
		recursive_multiply(spec, multiplier)
	end

	return spec
end

shooter.get_weapon_spec = function(user, weapon_name)
	local class = ctf_classes.get(user)

	if table.indexof(class.properties.allowed_guns or {}, weapon_name) == -1 then
		minetest.chat_send_player(user:get_player_name(),
			"Your class can't use that weapon! Change your class at base")
		return nil
	end

	local spec = get_shooter_specs(weapon_name, class.properties.shooter_multipliers)
	if not spec then
		return nil
	end

	return spec
end


local function check_grapple(itemname)
	local def = minetest.registered_items[itemname]
	local old_func = def.on_use
	minetest.override_item(itemname, {
		on_use = function(itemstack, user, ...)
			if not ctf_classes.get(user).properties.allow_grapples then
				minetest.chat_send_player(user:get_player_name(),
					"Your class can't use that weapon! Change your class at base")

				return itemstack
			end

			if ctf_flag.has_flag(user:get_player_name()) then
				minetest.chat_send_player(user:get_player_name(),
					"You can't use grapples whilst carrying the flag")

				return itemstack
			end

			return old_func(itemstack, user, ...)
		end,
	})
end

local function check_rocket(itemname)
	local def = minetest.registered_items[itemname]
	local old_func = def.on_use
	minetest.override_item(itemname, {
		on_use = function(itemstack, user, ...)
			if not ctf_classes.get(user).properties.allow_rockets then
				minetest.chat_send_player(user:get_player_name(),
					"You can't use that weapon! Change your class at base.")
				return itemstack
			end

			return old_func(itemstack, user, ...)
		end,

	})
end

check_grapple("shooter_hook:grapple_gun_loaded")
check_grapple("shooter_hook:grapple_gun")
check_grapple("shooter_hook:grapple_hook")

check_rocket("shooter_rocket:rocket_gun_loaded")
check_rocket("shooter_rocket:rocket_gun")

-- Override grappling hook entity to check if player has flag before teleporting
local old_grapple_step = minetest.registered_entities["shooter_hook:hook"].on_step
minetest.registered_entities["shooter_hook:hook"].on_step = function(self, dtime, ...)
	-- User left the game. Life is no longer worth living for this poor hook
	if not self.user or not minetest.get_player_by_name(self.user) then
		self.object:remove()
		return
	end

	-- Remove entity if player has flag
	-- This is to prevent players from firing the hook, and then punching the flag
	if ctf_flag.has_flag(self.user) then
		local player = minetest.get_player_by_name(self.user)
		if player then
			player:get_inventory():add_item("main", "shooter_hook:grapple_hook")
		end
		minetest.chat_send_player(self.user,
			"You can't use grapples whilst carrying the flag")
		self.object:remove()
		return
	end

	-- Remove hook if player changes class after throwing it
	if not ctf_classes.get(self.user).properties.allow_grapples then
		minetest.chat_send_player(self.user,
			"Grapples don't work if you change class!")
		self.object:remove()
		return
	end

	return old_grapple_step(self, dtime, ...)
end
