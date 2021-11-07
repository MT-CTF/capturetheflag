minetest.register_tool("ctf_mode_nade_fight:grenade", {
	description = "Frag grenade (Kills anyone near blast)",
	inventory_image = "grenades_frag.png",
	on_use = function(itemstack, user, pointed_thing)
		if itemstack:get_wear() < 65534 then
			grenades.throw_grenade("grenades:frag_small", 17, user)
		end

		if itemstack:get_wear() == 0 then
			ctf_modebase.update_wear.start_update(user:get_player_name(), "ctf_mode_nade_fight:grenade", 2000, true)
		end

		itemstack:set_wear(math.min(itemstack:get_wear() + 3000, 65534))

		return itemstack
	end,
})
