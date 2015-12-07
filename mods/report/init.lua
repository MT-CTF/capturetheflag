minetest.register_chatcommand("report", {
	func = function(name, param)
		local mods = ""
		for _, player in pairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			if minetest.check_player_privs(name, {kick=true,ban=true}) then
				if mods ~= "" then
					mods = mods .. ", "
				end
				mods = mods .. name
				minetest.chat_send_player(name, "-!- " .. name .. " reported: " .. param)
			end
		end
		if mods == "" then
			mods = "none"
		end
		chatplus.send_mail(name, minetest.setting_get("name"),
			"Report: " .. param .. " (mods online: " .. mods .. ")")
	end
})
