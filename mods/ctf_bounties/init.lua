local bountied_player = nil
local bounty_score = 0

local function announce(name)
	minetest.chat_send_player(name,
			minetest.colorize("#fff326", "The next person to kill " .. bountied_player ..
			" will receive " .. bounty_score .. " points!"))
end

local function announce_all()
	if bountied_player then
		for _, player in pairs(minetest.get_connected_players()) do
			if bountied_player ~= player:get_player_name() then
				announce(player:get_player_name())
			end
		end
	end
end

local function bounty_player(target)
	if bountied_player then
		minetest.chat_send_all("Player " .. bountied_player .. " no longer has a bounty on their head!")
	end

	bountied_player = target

	-- if minetest.global_exists("irc") then
		-- irc:say("Player " .. bountied_player .. " has a bounty on their head!")
	-- end
	minetest.after(0.1, announce_all)
end

local function bounty_find_new_target()
	local players = {}
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pstat, mstat = ctf_stats.player(name)
		pstat.name = name
		pstat.color = nil
		if pstat.score > 1000 and pstat.kills > pstat.deaths * 1.5 then
			table.insert(players, pstat)
		end
	end

	if #players > 0 then
		bounty_player(players[math.random(1, #players)].name)
		
		-- 				  Score * K/D
		-- bounty_score = -----------, or 1000 (whichever is lesser)
		--                   10000
		bounty_score = (pstat.score * (pstat.kills / pstat.deaths)) / 10000
		if bounty_score > 1000
			bounty_score = 1000
		end
	end

	minetest.after(math.random(500, 1000), bounty_find_new_target)
end
minetest.after(math.random(500, 1000), bounty_find_new_target)

minetest.register_on_leaveplayer(function(player)
	if bountied_player == player:get_player_name() then
		bountied_player = nil
	end
end)

minetest.register_on_joinplayer(function(player)
	if bountied_player then
		announce(player:get_player_name())
	end
end)

ctf.register_on_killedplayer(function(victim, killer)
	if victim == bountied_player then
		local main, match = ctf_stats.player(killer)
		if main and match then
			main.score  = main.score  + bounty_score
			match.score = match.score + bounty_score
			ctf.needs_save = true
		end
		bountied_player = nil

		local msg = killer .. " has killed " .. victim .. " and received the prize!"
		-- if minetest.global_exists("irc") then
			-- irc:say(msg)
		-- end
		minetest.chat_send_all(msg)
	end
end)

minetest.register_privilege("bounty_admin")

minetest.register_chatcommand("place_bounty", {
	privs = { bounty_admin = true },
	func = function(name, target)
		target = target:trim()
		if not minetest.get_player_by_name(target) then
			return false, target .. " is not online"
		end

		bounty_player(target)
		return true, "Put bounty on " .. target
	end
})
