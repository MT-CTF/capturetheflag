ctf.register_on_init(function()
	ctf.log("chat", "Initialising...")

	-- Settings: Chat
	ctf._set("chat.team_channel",          true)
	ctf._set("chat.global_channel",        true)
	ctf._set("chat.default",               "global")
end)

function minetest.is_player_name_valid(name)
	return name:match("^[%a%d_-]+$")
end

-- Implement coloured PMs by overriding /msg
-- The following code has been adapted from the chat-command of the same name in
-- builtin/game/chat.lua of Minetest <https://github.com/minetest/minetest> licensed
-- under the GNU LGPLv2.1+ license
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

		-- Colorized sender name and message
		local str =  minetest.colorize(color, "PM from ")
		str = str .. minetest.colorize(ctf_colors.get_color(ctf.player(name)).css, name)
		str = str .. minetest.colorize(color, ": " .. message)
		minetest.chat_send_player(sendto, str)

		minetest.log("action", "PM from " .. name .. " to " .. sendto .. ": " .. message)
		return true, "Message sent."
	end
})

local function team_console_help(name)
	minetest.chat_send_player(name, "Try:")
	minetest.chat_send_player(name, "/team - show team panel")
	minetest.chat_send_player(name, "/team all - list all teams")
	minetest.chat_send_player(name, "/team <team> - show details about team 'name'")
	minetest.chat_send_player(name, "/team <name> - get which team 'player' is in")
	minetest.chat_send_player(name, "/team player <name> - get which team 'player' is in")

	local privs = minetest.get_player_privs(name)
	if privs and privs.ctf_admin == true then
		minetest.chat_send_player(name, "/team add <team> - add a team called name (ctf_admin only)")
		minetest.chat_send_player(name, "/team remove <team> - remove a team called name (ctf_admin only)")
	end
	if privs and privs.ctf_team_mgr == true then
		minetest.chat_send_player(name, "/team bjoin <team> <commands> - Command is * for all players, playername for one, !playername to remove (ctf_team_mgr only)")
		minetest.chat_send_player(name, "/team join <name> <team> - add 'player' to team 'team' (ctf_team_mgr only)")
		minetest.chat_send_player(name, "/team removeplayer <name> - remove 'player' from 'team' (ctf_team_mgr only)")
	end
end

minetest.register_chatcommand("team", {
	description = "Open the team console, or run team command (see /team help)",
	func = function(name, param)
		local test   = string.match(param, "^player ([%a%d_-]+)")
		local create = string.match(param, "^add ([%a%d_-]+)")
		local remove = string.match(param, "^remove ([%a%d_-]+)")
		local j_name, j_tname = string.match(param, "^join ([%a%d_-]+) ([%a%d_]+)")
		local b_tname, b_pattern = string.match(param, "^bjoin ([%a%d_-]+) ([%a%d_-%*%! ]+)")
		local l_name = string.match(param, "^removeplayer ([%a%d_-]+)")
		if create then
			local privs = minetest.get_player_privs(name)
			if privs and privs.ctf_admin then
				if (
					string.match(create, "([%a%b_]-)")
					and create ~= ""
					and create ~= nil
					and ctf.team({name=create, add_team=true, color=create, allow_joins=false})
				) then
					return true, "Added team '"..create.."'"
				else
					return false, "Error adding team '"..create.."'"
				end
			else
				return false, "You are not a ctf_admin!"
			end
		elseif remove then
			local privs = minetest.get_player_privs(name)
			if privs and privs.ctf_admin then
				if ctf.remove_team(remove) then
					return true, "Removed team '" .. remove .. "'"
				else
					return false, "Error removing team '" .. remove .. "'"
				end
			else
				return false, "You are not a ctf_admin!"
			end
		elseif param == "all" then
			ctf.list_teams(name)
		elseif ctf.team(param) then
			local i = 0
			local str = ""
			local team = ctf.team(param)
			local tcolor = "#" .. ctf.flag_colors[team.data.color]:sub(3, 8)
			for pname, tplayer in pairs(team.players) do
				i = i + 1
				str = str .. "  " .. i .. ") " .. minetest.colorize(tcolor, pname) .. "\n"
			end
			str = "Team " .. minetest.colorize(tcolor, param) .. " (" .. i .. ") :\n" .. str
			minetest.chat_send_player(name, str)
		elseif ctf.player_or_nil(param) or test then
			if not test then
				test = param
			end
			if ctf.player(test).team then
				return true, test ..
						" is in team " .. ctf.player(test).team
			else
				return true, test.." is not in a team"
			end
		elseif j_name and j_tname then
			local privs = minetest.get_player_privs(name)
			if privs and privs.ctf_team_mgr then
				if ctf.join(j_name, j_tname, true, name) then
					return true, "Successfully added " .. j_name .. " to " .. j_tname
				else
					return false, "Failed to add " .. j_name .. " to " .. j_tname
				end
			else
				return true, "You are not a ctf_team_mgr!"
			end
		elseif b_pattern and b_tname then
			local privs = minetest.get_player_privs(name)
			if privs and privs.ctf_team_mgr then
				local tokens = string.split(b_pattern, " ")
				local players = {}

				for _, token in pairs(tokens) do
					print(token)
					if token == "*" then
						for _, player in pairs(minetest.get_connected_players()) do
							players[player:get_player_name()] = true
						end
					elseif token:sub(1, 1) == "!" then
						players[token:sub(2, #token)] = nil
					elseif minetest.is_player_name_valid(token) then
						players[token] = true
					else
						return false, "Invalid token: " .. token .. "\nExpecting *, playername, or !playername."
					end
				end

				for pname, _ in pairs(players) do
					ctf.join(pname, b_tname, true, name)
				end
				return true, "Success!"
			else
				return false, "You are not a ctf_team_mgr!"
			end
		elseif l_name then
			local privs = minetest.get_player_privs(name)
			if privs and privs.ctf_team_mgr then
				if ctf.remove_player(l_name) then
					return true, "Removed player " .. l_name
				else
					return false, "Failed to remove player."
				end
			else
				return false, "You are not a ctf_team_mgr!"
			end
		elseif param=="help" then
			team_console_help(name)
		else
			if param ~= "" and param ~= nil then
				minetest.chat_send_player(name, "'"..param.."' is an invalid parameter to /team")
				team_console_help(name)
			end
		end
		return false, "Nothing could be done"
	end
})

minetest.register_chatcommand("join", {
	params = "team name",
	description = "Add to team",
	func = function(name, param)
		if ctf.join(name, param, false, name) then
			return true, "Joined team " .. param .. "!"
		else
			return false, "Failed to join team!"
		end
	end
})

minetest.register_chatcommand("ctf_clean", {
	description = "Do admin cleaning stuff",
	privs = {ctf_admin=true},
	func = function(name, param)
		ctf.log("chat", "Cleaning CTF...")
		ctf.clean_player_lists()
		if ctf_flag and ctf_flag.assert_flags then
			ctf_flag.assert_flags()
		end
		return true, "CTF cleaned!"
	end
})

minetest.register_chatcommand("ctf_reset", {
	description = "Delete all CTF saved states and start again.",
	privs = {ctf_admin=true},
	func = function(name, param)
		minetest.chat_send_all("The CTF core was reset by the admin. All team memberships," ..
				"flags, land ownerships etc have been deleted.")
		ctf.reset()
		return true, "Reset CTF core."
	end,
})

minetest.register_chatcommand("ctf_reload", {
	description = "reload the ctf main frame and get settings",
	privs = {ctf_admin=true},
	func = function(name, param)
		ctf.init()
		return true, "CTF core reloaded!"
	end
})

minetest.register_chatcommand("ctf_ls", {
	description = "ctf: list settings",
	privs = {ctf_admin=true},
	func = function(name, param)
		minetest.chat_send_player(name, "Settings:")
		for set, def in orderedPairs(ctf._defsettings) do
			minetest.chat_send_player(name, " - " .. set .. ": " .. dump(ctf.setting(set)))
			print("\"" .. set .. "\"   " .. dump(ctf.setting(set)))
		end
		return true
	end
})

minetest.register_chatcommand("t", {
	params = "msg",
	description = "Send a message on the team channel",
	privs = { interact = true, shout = true },
	func = function(name, param)
		if not ctf.setting("chat.team_channel") then
			minetest.chat_send_player(name, "The team channel is disabled.")
			return
		end

		local tname = ctf.player(name).team
		local team = ctf.team(tname)
		if team then
			minetest.log("action", tname .. "<" .. name .. "> ** ".. param .. " **")
			if minetest.global_exists("chatplus") then
				chatplus.log("<" .. name .. "> ** ".. param .. " **")
			end

			if param == "" then
			minetest.chat_send_player(name, "You did not write anything, see /help t")
			end

			local tcolor = ctf_colors.get_color(ctf.player(name))
			for username, to in pairs(team.players) do
				minetest.chat_send_player(username,
						minetest.colorize(tcolor.css, "<" .. name .. "> ** " .. param .. " **"))
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

if minetest.global_exists("irc") then
	function irc.playerMessage(name, message)
		local color = ctf_colors.get_irc_color(ctf.player(name))
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
end

local handler
handler = function(name, message)
	if ctf.player(name).team then
		for i = 1, #minetest.registered_on_chat_messages do
			local func = minetest.registered_on_chat_messages[i]
			if func ~= handler and func(name, message) then
				return true
			end
		end

		if not minetest.check_player_privs(name, {shout = true}) then
			minetest.chat_send_player(name, "-!- You don't have permission to shout.")
			return true
		end
		local tcolor = ctf_colors.get_color(ctf.player(name))
		minetest.chat_send_all(minetest.colorize(tcolor.css,
				"<" .. name .. "> ") .. message)
		return true
	else
		return nil
	end
end
table.insert(minetest.registered_on_chat_messages, 1, handler)

minetest.registered_chatcommands["me"].func = function(name, param)
	if ctf.player(name).team then
		local tcolor = ctf_colors.get_color(ctf.player(name))
		name = minetest.colorize(tcolor.css, "* " .. name)
	else
		name = "* ".. name
	end

	minetest.chat_send_all(name .. " " .. param)
end
