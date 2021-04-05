ctf_reports = {}

local storage = minetest.get_mod_storage()
local http = minetest.request_http_api()

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
	minetest.log("action", name .. " subscribed to IRC reports")
	return true
end

local function remove_irc_mod(name)
	local mods = get_irc_mods()
	local idx = table.indexof(mods, name)
	if idx > 0 then
		table.remove(mods, idx)
		storage:set_string("irc_mods", table.concat(mods, ","))
		minetest.log("action", name .. " unsubscribed from IRC reports")
		return true
	end
	return false
end

-- If word corresponds to a player name, this method returns the
-- word enclosed by color escape codes of the player's team and
-- also the name followed by team name in parenthesis for IRC
local function colorize_word(word)
	if not minetest.get_player_by_name(word) then
		return minetest.colorize("#FFFF00", word), word
	end

	local tplayer = ctf.player(word)
	if not tplayer then
		return minetest.colorize("#FFFF00", word), word
	end

	return minetest.colorize(ctf_colors.get_color(tplayer).css, word),
			word .. " (team " .. (tplayer.team or "none") .. ")"
end

function ctf_reports.send_report(report)
	local ingame_report = ""
	local irc_report    = ""

	-- Colorize report word-by-word
	local parts = report:split(" ")
	for _, part in pairs(parts) do
		local ingame_part, irc_part = colorize_word(part)
		ingame_report = ingame_report .. " " .. ingame_part
		irc_report    = irc_report    .. " " .. irc_part
	end

	ingame_report = ingame_report:trim()
	irc_report    = irc_report:trim()

	-- Send to online moderators / admins
	-- Get comma separated list of online moderators and admins
	local mods = {}

	for _, player in pairs(minetest.get_connected_players()) do
		local toname = player:get_player_name()
		if minetest.check_player_privs(toname, { kick = true}) then
			table.insert(mods, toname)
			minetest.chat_send_player(toname, ingame_report)
		end
	end

	if not minetest.global_exists("irc") and not http then
		return
	end

	-- Append list of moderators in-game
	local msg
	if #mods == 0 then
		msg = irc_report .. " (no moderators online)"
	else
		msg = irc_report .. " (moderators online: " .. table.concat(mods, ", ") .. ")"
	end

	-- Send to IRC moderators
	if minetest.global_exists("irc") then
		for _, toname in pairs(get_irc_mods()) do
			if not minetest.get_player_by_name(toname) then
				minetest.chat_send_player(toname, msg)
			end
		end
	end

	-- Send to discord
	if http and minetest.settings:get("reports_webhook") then
		http.fetch({
			method = "POST",
			url = minetest.settings:get("reports_webhook"),
			extra_headers = {"Content-Type: application/json"},
			timeout = 5,
			data = minetest.write_json({
				username = "Ingame Report",
				avatar_url = "https://cdn.discordapp.com/avatars/447857790589992966/7ab615bae6196346bac795e66ba873dd.png",
				content = msg,
			}),
		}, function() end)
	end
end

minetest.register_chatcommand("report", {
	func = function(name, param)
		param = param:trim()
		if param == "" then
			return false, "Please add a message to your report. " ..
				"If it's about (a) particular player(s), please also include their name(s)."
		end

		-- Count the number of words, by counting for replaced spaces
		-- Number of spaces = Number of words - 1
		local _, count = string.gsub(param, " ", "")
		if count == 0 then
			return false, "If you're reporting a player, you should" ..
				" also include a reason why (e.g. swearing, griefing, spawnkilling, etc.)."
		end

		param = name .. " reported: " .. param

		ctf_reports.send_report(param)

		return true, "Report has been sent."
	end
})

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
