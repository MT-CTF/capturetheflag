-- License: WTFPL


rules = {}

local items = {
	"Welcome to Capture the Flag!",
	"",
	"Developed and hosted by rubenwardy.",
	"Moderators: Kpenguin, Thomas-S, Dragonop,",
	"            stormchaser3000, Calinou, sparky/ircSparky.",
	"By playing on this server you agree to these rules:",
	"1. Be nice. eg: No (excessive or bad) swearing",
	"2. No dating.",
	"3. Don't be a cheater. No hacked clients.",
	"4. Don't be a traitor. Don't:",
	"    a. Dig blocks in your base to make it less secure or",
	"       to trap team mates on purpose.",
	"    b. Help the other team win.",
	"5. Don't impersonate other community members",
	"Failure to follow these rules may result in a kick or ban",
	"     (temp or permanent) depending on severity.",
	"Use /report to send a message to a moderator.",
	"For example, /report bobgreen is destroying our base"}

for i = 1, #items do
	items[i] = minetest.formspec_escape(items[i])
end
rules.txt = table.concat(items, ",")

if minetest.global_exists("sfinv") then
	sfinv.register_page("rules:rules", {
		title = "Rules",
		get = function(player, context)
			return ([[
					size[8,8.6]
					bgcolor[#080808BB;true]
					background[5,5;1,1;gui_formbg.png;true]
					{{ nav }}
					textlist[0,0;7.85,8.5;help;]] .. rules.txt .. "]")
		end
	})
end

function rules.show(player)
	local fs = "size[8,8]textlist[0.1,0.1;7.8,6;msg;" .. rules.txt .. "]"
	if minetest.check_player_privs(player:get_player_name(), { interact = true }) then
		fs = fs .. "button_exit[0.5,6;7,2;yes;Okay]"
	else
		local yes = minetest.formspec_escape("Yes, let me play!")
		local no = minetest.formspec_escape("No, get me out of here!")

		fs = fs .. "button_exit[0.5,6;3.5,2;no;" .. no .. "]"
		fs = fs .. "button_exit[4,6;3.5,2;yes;" .. yes .. "]"
	end

	minetest.show_formspec(player:get_player_name(), "rules:rules", fs)
end

minetest.register_chatcommand("rules", {
	func = function(name, param)
		if param ~= "" and
				minetest.check_player_privs(name, { kick = true }) then
			name = param
		end

		local player = minetest.get_player_by_name(name)
		if player then
			rules.show(player)
			return true, "Rules shown."
		else
			return false, "Player " .. name .. " does not exist or is not online"
		end
	end
})

minetest.register_on_joinplayer(function(player)
	if not minetest.check_player_privs(player:get_player_name(), { interact = true }) then
		rules.show(player)
	end
end)

minetest.register_on_player_receive_fields(function(player, form, fields)
	if form ~= "rules:rules" then
		return
	end

	local name = player:get_player_name()
	if minetest.check_player_privs(name, { interact = true }) then
		return true
	end

	if fields.msg then
		return true
	elseif not fields.yes or fields.no then
		minetest.kick_player(name,
			"You need to agree to the rules to play on this server. " ..
			"Please rejoin and confirm another time.")
		return true
	end

	local privs = minetest.get_player_privs(name)
	privs.shout = true
	privs.interact = true
	minetest.set_player_privs(name, privs)

	minetest.chat_send_player(name, "Welcome "..name.."! You have now permission to play!")

	return true
end)
