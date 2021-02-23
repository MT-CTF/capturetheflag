minetest.override_chatcommand("msg", {
	func = function(name, param)
		local sendto, message = param:match("^(%S+)%s(.+)$")
		if not sendto then
			return false, "Invalid usage, see /help msg."
		end
		if not minetest.get_player_by_name(sendto) then
			return false, "The player " .. sendto .. " is not online."
		end

		-- Message color
		local color = minetest.settings:get("ctf_chat.message_color") or "#E043FF"
		local pteam = ctf_teams.get(name)
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"

		-- Colorized sender name and message
		local str =  minetest.colorize(color, "PM from ")
		str = str .. minetest.colorize(tcolor, name)
		str = str .. minetest.colorize(color, ": " .. message)
		minetest.chat_send_player(sendto, str)

		minetest.log("action", "PM from " .. name .. " to " .. sendto .. ": " .. message)
		return true, "Message sent."
	end
})

local function me_func() end

if minetest.global_exists("irc") then
	function irc.playerMessage(name, message)
		local pteam = ctf_teams.get(name)

		local color = pteam and ctf_teams.team[pteam].irc_color or 16
		local clear = "\x0F"
		if color then
			color = "\x03" .. color
		else
			color = ""
			clear = ""
		end
		local abrace = color .. "<" .. clear
		local bbrace = color .. ">" .. clear
		return ("%s%s%s %s"):format(abrace, name, bbrace, message)
	end

	me_func = function(...)
		local message = irc.playerMessage(...)
		local start_escape = message:sub(1, message:find("<")-1)

		-- format is: \startescape < \endescape playername \startescape > \endescape
		message = message:gsub("\15(.-)"..start_escape, "* %1"):gsub("[<>]", "")

		irc.say(message)
	end
end

local handler
handler = function(name, message)
	local pteam = ctf_teams.get(name)
	if pteam then
		for i = 1, #minetest.registered_on_chat_messages do
			local func = minetest.registered_on_chat_messages[i]
			if func ~= handler and func(name, message) then
				return true
			end
		end

		if not minetest.check_player_privs(name, {shout = true}) then
			minetest.chat_send_player(name, "-!- You don't have permission to speak.")
			return true
		end
		local tcolor = ctf_teams.team[pteam].color
		minetest.chat_send_all(minetest.colorize(tcolor,
				"<" .. name .. "> ") .. message)
		return true
	else
		return
	end
end
table.insert(minetest.registered_on_chat_messages, 1, handler)

minetest.registered_chatcommands["me"].func = function(name, param)
	me_func(name, param)

	local pteam = ctf_teams.get(name)
	if pteam then
		local tcolor = ctf_teams.team[pteam].color
		name = minetest.colorize(tcolor, "* " .. name)
	else
		name = "* ".. name
	end

	minetest.log("action", "[CHAT] "..name.." "..param)

	minetest.chat_send_all(name .. " " .. param)
end

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
			local team = ctf_teams.get_team(tname)

			minetest.log("action", tname .. "<" .. name .. "> ** ".. param .. " **")
			if minetest.global_exists("chatplus") then
				chatplus.log("<" .. name .. "> ** ".. param .. " **")
			end

			local tcolor = ctf_teams.team[tname].color
			for _, username in pairs(team) do
				minetest.chat_send_player(username,
						minetest.colorize(tcolor, "<" .. name .. "> ** " .. param .. " **"))
			end
			if minetest.global_exists("irc") and irc.feature_mod_channel then
				irc:say(irc.config.channel, tname .. "<" .. name .. "> ** " .. param .. " **", true)
			end
		else
			minetest.chat_send_player(name,
					"You're not in a team, so you have no team to talk to.")
		end
	end
})
