local specs_cache = {}

local function get_shooter_specs(weapon_name, multiplier)
	local spec = shooter.registered_weapons[weapon_name]
	if not spec then
		return nil
	end
	spec = spec.spec

	-- this will convert the multipler to a table pointer
	local idx = ("%s:%s"):format(multiplier or "nil", weapon_name)

	if specs_cache[idx] then
		return specs_cache[idx]
	end

	spec = table.copy(spec)
	specs_cache[idx] = spec

	spec.range = spec.range * 1.5
	spec.tool_caps.full_punch_interval = spec.tool_caps.full_punch_interval * 0.8
	return spec
end

shooter.get_weapon_spec = function(_, user, weapon_name)
	local class = ctf_classes.get(user)

	if table.indexof(class.properties.allowed_guns or {}, weapon_name) == -1 then
		minetest.chat_send_player(user:get_player_name(),
			"Your class can't use that weapon! Change your class at spawn")
		return nil
	end

	local spec = get_shooter_specs(weapon_name, class.properties.shooter_multipliers)
	spec.name = user and user:get_player_name()

	return spec
end


local function check_grapple(itemname)
	local def = minetest.registered_items[itemname]
	local old_func = def.on_use
	minetest.override_item(itemname, {
		on_use = function(itemstack, user, ...)
			if ctf_classes.get(user).name ~= "shooter" then
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

check_grapple("shooter:grapple_gun_loaded")
check_grapple("shooter:grapple_gun")
