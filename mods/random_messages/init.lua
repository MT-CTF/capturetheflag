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

function table.count( t )
	local i = 0
	for k in pairs( t ) do i = i + 1 end
	return i
end

function table.random( t )
	local rk = math.random( 1, table.count( t ) )
	local i = 1
	for k, v in pairs( t ) do
		if ( i == rk ) then return v, k end
		i = i + 1
	end
end

function random_messages.initialize() --Set the interval in minetest.conf.
	minetest.setting_set("random_messages_interval",120)
	minetest.setting_save();
	return 120
end

function random_messages.set_interval() --Read the interval from minetest.conf(set it if it doesn'st exist)
	MESSAGE_INTERVAL = tonumber(minetest.setting_get("random_messages_interval")) or random_messages.initialize()
end

function random_messages.check_params(name,func,params)
	local stat,msg = func(params)
	if not stat then
		minetest.chat_send_player(name,msg)
		return false
	end
	return true
end

function random_messages.read_messages()
	random_messages.messages = {
		"To talk to only your team, start your messages with /t. For example, /t Hello team!",
		"If the map is ruined, use /vote to start a new vote to skip the current match.",
		"Eat apples to restore health quickly.",
		"You can steal items from the other team's chest."
	}
end

function random_messages.display_message(message_number)
	local msg = random_messages.messages[message_number] or message_number
	if msg then
		minetest.chat_send_all(msg)
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

local TIMER = 0
minetest.register_globalstep(function(dtime)
	TIMER = TIMER + dtime;
	if TIMER > MESSAGE_INTERVAL then
		random_messages.show_message()
		TIMER = 0
	end
end)

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
