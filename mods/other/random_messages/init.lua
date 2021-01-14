--[[
RandomMessages mod by arsdragonfly.
arsdragonfly@gmail.com
6/19/2013
--]]
--Time between two subsequent messages.
local MESSAGE_INTERVAL = 0

math.randomseed(os.time())

random_messages = {}
random_messages.messages = {} --This table contains all messages.

function table.count( t ) -- luacheck: ignore
	local i = 0
	for k in pairs( t ) do i = i + 1 end
	return i
end

function table.random( t ) -- luacheck: ignore
	local rk = math.random( 1, table.count( t ) )
	local i = 1
	for k, v in pairs( t ) do
		if ( i == rk ) then return v, k end
		i = i + 1
	end
end

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
		"To talk to only your team, start your messages with /t. For example, /t Hello team!",
		"Use medkits to gradually restore your health.",
		"Moving or fighting while using medkits will interrupt the healing process.",
		"Knights have a slight damage bonus (up to 1.5 hp) when attacking with swords.",
		"Gain more score by killing more than you die, by healing teammates as a medic, or by capturing the flag.",
		"You gain more score the better the opponent you defeat.",
		"Find weapons in chests or mine and use furnaces to make stronger swords.",
		"Players are immune to attack for 5 seconds after they respawn.",
		"Access the pro section of the chest by achieving a 10k+ score and killing 3 people for every 2 deaths.",
		"Use team doors (steel) to stop the enemy walking into your base.",
		"Craft 6 cobbles and 1 steel ingot together to make reinforced cobble.",
		"Sprint by pressing the fast key (E) when you have stamina.",
		"Like CTF? Give feedback using /report, and consider donating at rubenwardy.com/donate",
		"Want to submit your own map? Visit ctf.rubenwardy.com to get involved.",
		"Using limited resources for building structures that don't strengthen your base's defences is discouraged.",
		"To report misbehaving players to moderators, please use /report <name> <action>",
		"Swearing, trolling and being rude will not be tolerated and strict action will be taken.",
		"Trapping team mates on purpose is strictly against the rules and you will be kicked immediately.",
		"Help your team claim victory by storing extra weapons in the team chest, and never taking more than you need.",
		"Excessive spawn-killing is a direct violation of the rules - appropriate punishments will be given.",
		"Use /r to check your score and rank, and /rankings to see the league tables.",
		"Use /r <number> or /rn <number> to check the rankings of the player in the given rank.",
		"Use bandages on team-mates to heal them by 3-4 HP if their health is below 15 HP.",
		"Use /m to add a team marker at pointed location, that's visible only to team-mates.",
		"Use /summary to check scores of the current match and the previous match.",
		"Use /maps to view the maps catalog. It also contains license info and attribution details.",
		"Change your class in your base by right clicking the home flag or typing /class.",
		"Medics cause troops within 10 metres to regenerate health faster.",
		"Hitting your enemy does more damage than not hitting them.",
		"Press right mouse button or double-tap the screen to activate scope while wielding a sniper rifle.",
		"The 'Updates' tab in your inventory will show some of the latest updates to CTF",
	}
end

function random_messages.display_message(message_number)
	local msg = random_messages.messages[message_number] or message_number
	if msg then
		minetest.chat_send_all(minetest.colorize("#808080", msg))
	end
end

function random_messages.show_message()
	random_messages.display_message(table.random(random_messages.messages))
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
