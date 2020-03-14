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
			"Your class can't use that weapon! Change your class at spawn")
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
					"Your class can't use that weapon! Change your class at spawn")

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

check_grapple("shooter_hook:grapple_gun_loaded")
check_grapple("shooter_hook:grapple_gun")
check_grapple("shooter_hook:grapple_hook")
