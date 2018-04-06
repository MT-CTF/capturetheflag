local storage = minetest.get_mod_storage()

local function get_irc_mods()
	return storage:get_string("irc_mods"):split(",")
end

local function add_irc_mod(name)
	local mods = get_irc_mods()
	if table.indexof(mods, name) > 0 then
		return false
	end
	mods[#mods + 1] = name
	storage:set_string("irc_mods", table.concat(mods, ","))
	return true
end

local function remove_irc_mod(name)
	local mods = get_irc_mods()
	local idx = table.indexof(mods, name)
	if idx > 0 then
		table.remove(mods, idx)
		storage:set_string("irc_mods", table.concat(mods, ","))
		return true
	end
	return false
end

minetest.register_chatcommand("report_sub", {
	privs = { kick = true },
	func = function(name, param)
		if param:lower():trim() == "remove" then
			if remove_irc_mod(name) then
				return true, "Successfully removed!"
			else
				return false, "Unable to remove, are you even subscribed?"
			end
		else
			if add_irc_mod(name) then
				return true, "Successfully added!"
			else
				return false, "Unable to add, are you already subscribed?"
			end
		end
	end
})

minetest.register_chatcommand("report", {
	func = function(name, param)
		param = param:trim()
		if param == "" then
			return false, "Please add a message to your report. " ..
				"If it's about (a) particular player(s), please also include their name(s)."
		end
		local _, count = string.gsub(param, " ", "")
		if count == 0 then
			minetest.chat_send_player(name, "If you're reporting a player, " ..
				"you should also include a reason why. (Eg: swearing, sabotage)")
		end

		-- Send to online moderators / admins
		-- Get comma separated list of online moderators and admins
		local mods = {}
		for _, player in pairs(minetest.get_connected_players()) do
			local toname = player:get_player_name()
			if minetest.check_player_privs(toname, {kick = true, ban = true}) then
				table.insert(mods, toname)
				minetest.chat_send_player(toname, minetest.colorize(#FFFF00,"-!- " .. name .. " reported: " .. param))
			end
		end

		-- Build message for offline listeners
		local msg
		if #mods == 0 then
			msg = "Report from " ..name .. ": " .. param .. " (no mods online)"
		else
			msg = "Report from " ..name .. ": " .. param .. " (mods online: " ..
					table.concat(mods, ", ") .. ")"
		end

		-- Send to IRC moderators
		for _, toname in pairs(get_irc_mods()) do
			if not minetest.get_player_by_name(toname) then
				minetest.chat_send_player(toname, msg)
			end
		end

		-- Email to admin
		email.send_mail(name, minetest.setting_get("name"), msg)

		return true, "Reported. We'll get back to you."
	end
})
