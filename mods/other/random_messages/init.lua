--[[
RandomMessages mod by arsdragonfly.
arsdragonfly@gmail.com
6/19/2013
--]]
--Time between two subsequent messages.
local MESSAGE_INTERVAL = 0
local S = minetest.get_translator(minetest.get_current_modname())

math.randomseed(os.time())

random_messages = {}
random_messages.messages = {} --This table contains all messages.

function random_messages.initialize() --Set the interval in minetest.conf.
	minetest.settings:set("random_messages_interval", 60)
	minetest.settings:write();
	return 60
end

function random_messages.set_interval() --Read the interval from minetest.conf and set it if it doesn't exist
	MESSAGE_INTERVAL = tonumber(minetest.settings:get("random_messages_interval"))
							or random_messages.initialize()
end

function random_messages.check_params(name,func,params)
	local stat, msg = func(params)
	if not stat then
		minetest.chat_send_player(name,msg)
		return false
	end
	return true
end

function random_messages.read_messages()
	random_messages.messages = {
		S("To talk to only your team, start your messages with /t. For example, /t Hello team!"),
		S("Use apples to quickly restore your health."),
		S("Moving or fighting can avoid an inactivity kick."),
		S("Gain more score by killing more than you die, by healing teammates with bandages, or by capturing the flag."),
		S("You gain more score the better the opponent you defeat."),
		S("Find weapons in chests or mine and use furnaces to make stronger swords."),
		S("Use team doors (steel) to stop the enemy walking into your base."),
		S("Sprint by pressing the fast key (E) when you have stamina."),
		S("Like CTF? Give feedback using /report, and consider donating at rubenwardy.com/donate"),
		S("Want to submit your own map? Visit ctf.rubenwardy.com to get involved."),
		S("Using limited resources for building structures that don't strengthen your base's defences is discouraged."),
		S("To report misbehaving players to moderators, please use /report <name> <action>"),
		S("Swearing, trolling and being rude will not be tolerated and strict action will be taken."),
		S("Trapping team mates on purpose is strictly against the rules and you will be kicked immediately."),
		S("Help your team claim victory by storing extra weapons in the team chest, and never taking more than you need."),
		S("Excessive spawn-killing is a direct violation of the rules - appropriate punishments will be given."),
		S("Use /r to check your rank and other statistics."),
		S("Use /r <playername> to check the rankings of another player."),
		S("Use bandages on team-mates to heal them by 3-4 HP if their health is below 15 HP."),
		S("Use /m to add a team marker at pointed location, that's visible only to team-mates."),
		S("Use /summary (or /s) to check scores of the current match and the previous match."),
		S("Strengthen your team by capturing enemy flags."),
		S("Hitting your enemy does more damage than not hitting them."),
		S("Use /top50 command to see the leaderboard."),
		S("Use /top50 <mode:technical modename> to see the leaderboard on another mode.")
		.. S("For example: /top50 mode:nade_fight."),
		S("To check someone's rank on another mode use /r <mode:technical modename> <playername>.")
		.. S(" For example: /r mode:nade_fight randomplayer."),
		S("To check someone's team use /team player <player_name>."),
		S("To check all team members use /team."),
		S("You can capture multiple enemy flags at once!"),
		S("Consider joining our Discord server at https://discord.gg/vcZTRPX"),
		S("You can press sneak while jumping, to jump up two blocks."),
		S("Use /donate <playername> <amount> to reward a team-mate for their work.")
	}
end

function random_messages.display_message(message_number)
	local msg = random_messages.messages[message_number] or message_number
	if msg then
		minetest.chat_send_all(minetest.colorize("#808080", msg))
	end
end

function random_messages.show_message()
	local message = random_messages.messages[math.random(1, #random_messages.messages)]
	random_messages.display_message(message)
end

function random_messages.list_messages()
	local str = ""
	for k,v in pairs(random_messages.messages) do
		str = str .. k .. " | " .. v .. "\n"
	end
	return str
end

function random_messages.remove_message(k)
	table.remove(random_messages.messages,k)
	random_messages.save_messages()
end

function random_messages.add_message(t)
	table.insert(random_messages.messages,table.concat(t," ",2))
	random_messages.save_messages()
end

function random_messages.save_messages()
	local output = io.open(minetest.get_worldpath().."/random_messages","w")
	for k,v in pairs(random_messages.messages) do
		output:write(v .. "\n")
	end
	io.close(output)
end

--When server starts:
random_messages.set_interval()
random_messages.read_messages()

local function step(dtime)
	random_messages.show_message()
	minetest.after(MESSAGE_INTERVAL, step)
end
minetest.after(MESSAGE_INTERVAL, step)

local register_chatcommand_table = {
	params = "viewmessages | removemessage <number> | addmessage <number>",
	privs = {server = true},
	description = "View and/or alter the server's random messages",
	func = function(name,param)
		local t = string.split(param, " ")
		if t[1] == "viewmessages" then
			minetest.chat_send_player(name,random_messages.list_messages())
		elseif t[1] == "removemessage" then
			if not random_messages.check_params(
			name,
			function (params)
				if not tonumber(params[2]) or
				random_messages.messages[tonumber(params[2])] == nil then
					return false,"ERROR: No such message."
				end
				return true
			end,
			t) then return end
			random_messages.remove_message(t[2])
		elseif t[1] == "addmessage" then
			if not t[2] then
				minetest.chat_send_player(name,"ERROR: No message.")
			else
				random_messages.add_message(t)
			end
		else
				minetest.chat_send_player(name,"ERROR: Invalid command.")
		end
	end
}

minetest.register_chatcommand("random_messages", register_chatcommand_table)
minetest.register_chatcommand("rmessages", register_chatcommand_table)
