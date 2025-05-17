local S = minetest.get_translator(minetest.get_current_modname())

ctf_settings.register("ctf_kill_list:tp_size", {
	type = "list",
	description = S("Your texturepack's texture size.") .. "\n" .. S("Used to scale things like kill feed images."),
	list = {"8px", "16px", "32px", "64px", "128px", "256px"},
	image_scale_map = {2, 1, 0.5, 0.25, 0.125, 0.0625},
	default = "2",
})

ctf_settings.register("use_hudbars", {
	label = "Use hudbars instead of icon hud",
	type = "bool",
	default = "false",
	description = "Use a bar with a label instead of icons for quantites like\n" ..
		"health, stamina, and breath.\n" ..
		"Disconnect and reconnect to see effects.",
	on_change = function(player, new_value)
		minetest.chat_send_player(player:get_player_name(), minetest.colorize("cyan",
			"[Notice]: You need to rejoin for your HUD to change"
		))
	end,
})
