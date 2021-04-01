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

local report_reasons = {
	"abusing chat",
	"swearing",
	"asking for personal info",
	"spawn killing",
	"hacking",
	"cross teaming",
	"base griefing",
	"being inappropriate"
}

minetest.register_chatcommand("report", {
	func = function(name, param)
		local connected_players = {}
		for index, player in ipairs(minetest.get_connected_players()) do
			table.insert(connected_players,player:get_player_name())
		end
		local report_formspec =
		"formspec_version[4]"..
		"size[6,2,false]"..
		"label[0.1,0.15;Username]"..
		"dropdown[0.1,0.3;2.1,0.5;username_dropdown;"..table.concat(connected_players,",")..";0]"..
		"label[2.2,0.15;Reason]"..
		"dropdown[2.2,0.3;2.1,0.5;reason_dropdown;"..table.concat(report_reasons,",")..";0]"..
		"button_exit[4.4,0.3;1.5,0.5;report_btn;Report]"..
		"button_exit[4.4,1;1.5,0.5;close_btn;Cancel]"..
		"field[0.1,1.2;4,0.5;info_field;Message;]"
		minetest.show_formspec(name, "ctf_report", report_formspec)
		return true
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "ctf_report" and fields.quit then
		if not fields.report_btn then
			return
		end
		if fields.username_dropdown and fields.reason_dropdown then
			if string.gsub(fields.info_field, "%s+", "") == "" then
				ctf_reports.send_report(player:get_player_name().." reports "..fields.username_dropdown .." for "..fields.reason_dropdown..".")
			else
				ctf_reports.send_report(player:get_player_name().." reports "..
				fields.username_dropdown .." for "..fields.reason_dropdown..". Message: "..fields.info_field)
			end
			minetest.chat_send_player(player:get_player_name(),"Report has been sent." )
		elseif string.gsub(fields.info_field, "%s+", "") ~= "" then
			if fields.username_dropdown then
				ctf_reports.send_report(player:get_player_name().." reports "..fields.username_dropdown .." Message: "..fields.info_field)
			else
				ctf_reports.send_report(player:get_player_name().." reports: "..fields.info_field)
			end
		else
			minetest.chat_send_player(player:get_player_name(),"Missing argument(s)!" )
		end
	end
end)

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
