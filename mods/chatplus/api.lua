-- Chat Plus
--    by rubenwardy
---------------------
-- api.lua
-- Core functionality
---------------------


chatplus = {
	version = 2.2,
	_logpath = minetest.get_worldpath().."/chatplus-log.txt",
	_defsettings = {
		log = true,
		use_gui = true,
		distance = 0,
		badwords = ""
	}
}

function chatplus.init()
	chatplus.load()
	chatplus.clean_players()

	if not chatplus.players then
		chatplus.players = {}
	end
	chatplus.count = 0
	chatplus.loggedin = {}
	chatplus._handlers = {}
end

function chatplus.setting(name)
	local get = minetest.setting_get("chatplus_" .. name)
	if get then
		return get
	elseif chatplus._defsettings[name]~= nil then
		return chatplus._defsettings[name]
	else
		minetest.log("[Chatplus] Setting chatplus_" .. name .. " not found!")
		return nil
	end
end

function chatplus.log(msg)
	if chatplus._log then
		chatplus._log:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\r\n")
		chatplus._log:flush()
	end
end

function chatplus.load()
	-- Initialize the log
	if chatplus.setting("log") then
		chatplus._log = io.open(chatplus._logpath, "a+")
		if not chatplus._log then
			minetest.log("error", "Unable to open the chatplus log file: " .. chatplus._logpath)
		else
			minetest.log("action", "Logging chat plus to: " .. chatplus._logpath)
		end
		chatplus.log("*** SERVER STARTED ***")
	end

	-- Load player data
	minetest.log("[Chatplus] Loading data")
	local file = io.open(minetest.get_worldpath() .. "/chatplus.txt", "r")
	if file then
		local from_file = minetest.deserialize(file:read("*all"))
		file:close()
		if type(from_file) == "table" then
			if from_file.players and from_file.version >= 2 then
				chatplus.players = from_file.players
			else
				chatplus.players = {}
				for name, data in pairs(from_file) do
					chatplus.players[name] = data
					local inbox = data.inbox
					data.inbox = {}
					for _, msg in pairs(inbox) do
						table.insert(data.inbox, {
							date = "?",
							from = "?",
							msg = msg
						})
					end
				end
			end
			return
		end
	end
end

function chatplus.save()
	minetest.log("[Chatplus] Saving data")

	local file = io.open(minetest.get_worldpath().."/chatplus.txt", "w")
	if file then
		file:write(minetest.serialize({	version = 2, players = chatplus.players}))
		file:close()
	end
end

function chatplus.clean_players()
	if not chatplus.players then
		chatplus.players = {}
		return
	end

	minetest.log("[Chatplus] Cleaning player lists")
	for key,value in pairs(chatplus.players) do
		if value.messages then
			value.inbox = value.messages
			value.messages = nil
		end

		if (
			(not value.inbox or #value.inbox==0) and
			(not value.ignore or #value.ignore==0)
		) then
			value[key] = nil
		end
	end
	chatplus.save()
end

local function cp_tick()
	chatplus.clean_players()
	minetest.after(30*60, cp_tick)
end
minetest.after(30*60, cp_tick)

function chatplus.poke(name,player)
	local function check(name,value)
		if not chatplus.players[name][value] then
			chatplus.players[name][value] = {}
		end
	end
	if not chatplus.players[name] then
		chatplus.players[name] = {}
	end
	check(name, "ignore")
	check(name, "inbox")

	chatplus.players[name].enabled = true

	if player then
		if player=="end" then
			chatplus.players[name].enabled = false
			chatplus.loggedin[name] = nil
		else
			if not chatplus.loggedin[name] then
				chatplus.loggedin[name] = {}
			end
			chatplus.loggedin[name].player = player
		end
	end

	chatplus.save()

	return chatplus.players[name]
end

function chatplus.register_handler(func,place)
	if not place then
		table.insert(chatplus._handlers, func)
	else
		table.insert(chatplus._handlers, place, func)
	end
end

-- Allows overriding
function chatplus.log_message(from, msg)
	chatplus.log("<" .. from .. "> " .. msg)
end

function chatplus.send(from, msg)
	if msg:sub(1, 1) == "/" then
		return false
	end

	chatplus.log_message(from, msg)

	if #chatplus._handlers == 0 then
		return nil
	end

	-- Loop through possible receivers
	for to, value in pairs(chatplus.loggedin) do
		if to ~= from then
			-- Run handlers
			local res = nil
			for i = 1, #chatplus._handlers do
				if chatplus._handlers[i] then
					res = chatplus._handlers[i](from, to, msg)

					if res ~= nil then
						break
					end
				end
			end

			-- Send message
			if res == nil or res == true then
				minetest.chat_send_player(to, "<" .. from .. "> " .. msg)
			end
		end
	end
	return true
end


-- Minetest callbacks
minetest.register_on_chat_message(function(...)
	local ret = chatplus.send(...)
	if ret and minetest.global_exists("irc") then
		irc.on_chatmessage(...)
	end
	return ret
end)
minetest.register_on_joinplayer(function(player)
	chatplus.log(player:get_player_name() .. " joined")
end)
minetest.register_on_leaveplayer(function(player)
	chatplus.poke(player:get_player_name(), "end")
	chatplus.log(player:get_player_name() .. " disconnected")
end)
chatplus.init()
