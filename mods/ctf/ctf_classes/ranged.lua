local shooter_specs = {}


shooter.get_weapon_spec = function(_, user, name)
	local spec = shooter.registered_weapons[name]
	if not spec then
		return nil
	end
	spec = spec.spec
	spec.name = user:get_player_name()

	if not user then
		return spec
	end

	local class = ctf_classes.get(user)
	if class.name ~= "shooter" then
		if name == "shooter:rifle" then
			minetest.chat_send_player(user:get_player_name(),
				"Only Shooters are skilled enough for rifles! Change your class at spawn")
			return nil
		end
		return spec
	end

	if shooter_specs[name] then
		return shooter_specs[name]
	end

	spec = table.copy(spec)
	shooter_specs[name] = spec

	spec.range = spec.range * 1.5
	spec.tool_caps.full_punch_interval = spec.tool_caps.full_punch_interval * 0.8
	return spec
end


local function check_grapple(itemname)
	local def = minetest.registered_items[itemname]
	local old_func = def.on_use
	minetest.override_item(itemname, {
		description = def.description .. "\n\nCan only be used by Shooters",
		on_use = function(itemstack, user, ...)
			if ctf_classes.get(user).name ~= "shooter" then
				minetest.chat_send_player(user:get_player_name(),
					"Only Shooters are skilled enough for grapples! Change your class at spawn")

				return itemstack
			end

			return old_func(itemstack, user, ...)
		end,
	})
end

check_grapple("shooter:grapple_gun_loaded")
check_grapple("shooter:grapple_gun")

minetest.override_item("shooter:rifle", {
	description = "Rifle\n\nCan only be used by Shooters",
})
