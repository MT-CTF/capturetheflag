ctf_chat = {}

minetest.override_chatcommand("msg", {
	func = function(name, param)
		local sendto, message = param:match("^(%S+)%s(.+)$")
		if not sendto then
			return false, "Invalid usage, see /help msg."
		end
		if not minetest.get_player_by_name(sendto) then
			return false, "The player " .. sendto .. " is not online."
		end

		-- Run the message through filter if it exists
		if filter and not filter.check_message(name, message) then
			filter.on_violation(name, message)
			return false
		end

		-- Message color
		local color = minetest.settings:get("ctf_chat.message_color") or "#E043FF"
		local pteam = ctf_teams.get(name)
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"

		-- Colorize the recepient-side message and send it to the recepient
		local str =  minetest.colorize(color, "PM from ")
		str = str .. minetest.colorize(tcolor, name)
		str = str .. minetest.colorize(color, ": " .. message)
		minetest.chat_send_player(sendto, str)

		-- Make the sender-side message
		str = "Message sent to " .. sendto .. ": " .. message

		minetest.log("action", string.format("[CHAT] PM from %s to %s: %s", name, sendto, message))

		-- Send the sender-side message
		return true, str
	end
})

---@return boolean
-- Return true to cancel the normal chat message
function ctf_chat.send_me(name, param)

end

minetest.override_chatcommand("me", {
	func = function(name, param)
		minetest.log("action", string.format("[CHAT] ME from %s: %s", name, param))

		if ctf_chat.send_me(name, param) then
			return
		end

		local pteam = ctf_teams.get(name)

		if pteam then
			local tcolor = ctf_teams.team[pteam].color
			name = minetest.colorize(tcolor, "* " .. name)
		else
			name = "* ".. name
		end

		minetest.chat_send_all(name .. " " .. param)
	end
})

minetest.register_chatcommand("t", {
	params = "msg",
	description = "Send a message on the team channel",
	privs = { interact = true, shout = true },
	func = function(name, param)
		if param == "" then
			return false, "-!- Empty team message, see /help t"
		end

		local tname = ctf_teams.get(name)
		if tname then
			minetest.log("action", string.format("[CHAT] team message from %s (team %s): %s", name, tname, param))

			local tcolor = ctf_teams.team[tname].color
			for username in pairs(ctf_teams.online_players[tname].players) do
				minetest.chat_send_player(username,
						minetest.colorize(tcolor, "<" .. name .. "> ** " .. param .. " **"))
			end
		else
			minetest.chat_send_player(name,
					"You're not in a team, so you have no team to talk to.")
		end
	end
})

minetest.register_on_mods_loaded(function()
	local old_handlers = minetest.registered_on_chat_messages
	minetest.registered_on_chat_messages = {
	function(name, message)
		local chat = message:sub(1,1) ~= "/"

		if chat and not minetest.check_player_privs(name, {shout = true}) then
			minetest.chat_send_player(name, "-!- You don't have permission to speak.")
			return true
		end

		for _, handler in ipairs(old_handlers) do
			if handler(name, message) then
				return true
			end
		end

		if chat then
			local pteam = ctf_teams.get(name)
			if pteam then
				minetest.chat_send_all(minetest.colorize(ctf_teams.team[pteam].color, "<" .. name .. "> ") .. message)
			else
				minetest.chat_send_all("<" .. name .. "> " .. message)
			end
		end

		return true
	end}
end)
