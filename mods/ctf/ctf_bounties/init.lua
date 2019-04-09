local bountied_player = nil
local bounty_score = 0

local function announce(name)
	local tcolor = ctf_colors.get_color(ctf.player(bountied_player))
	minetest.chat_send_player(name,
			minetest.colorize("#fff326", "The next person to kill ") ..
			minetest.colorize(tcolor.css, bountied_player) ..
			minetest.colorize("#fff326", " will receive " .. bounty_score .. " points!"))
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
	local prev = bountied_player
	bountied_player = target

	--                Score * K/D
	-- bounty_score = -----------, or 500 (whichever is lesser)
	--                   5000

	local pstat, _ = ctf_stats.player(target)
	if pstat.deaths == 0 then
		pstat.deaths = 1
	end
	bounty_score = (pstat.score * (pstat.kills / pstat.deaths)) / 10000
	if bounty_score > 500 then
		bounty_score = 500
	end
	if bounty_score < 50 then
		bounty_score = 50
	end
	bounty_score = math.floor(bounty_score)

	if prev then
		for _, player in pairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			if bountied_player ~= name then
				local _, prev_color = ctf_colors.get_color(prev, ctf.player(prev))
				minetest.chat_send_player(player:get_player_name(),
					minetest.colorize("#fff326", "Player ") ..
					minetest.colorize(prev_color:gsub("0x", "#"), prev) ..
					minetest.colorize("#fff326", " no longer has a bounty on their head!"))
			end
		end
	end

	minetest.after(0.1, announce_all)
end

local function bounty_find_new_target()
	local players = {}
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pstat, _ = ctf_stats.player(name)
		pstat.name = name
		pstat.color = nil
		if pstat.score > 1000 and pstat.kills > pstat.deaths * 1.5 then
			table.insert(players, pstat)
		end
	end

	if #players > 0 then
		bounty_player(players[math.random(1, #players)].name)
	end

	minetest.after(math.random(500, 1000), bounty_find_new_target)
end
minetest.after(math.random(500, 1000), bounty_find_new_target)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if bountied_player and
			bountied_player ~= name then
		announce(name)
	end
end)

ctf.register_on_killedplayer(function(victim, killer)
	if victim ~= bountied_player or victim == killer then
		return
	end

	local main, match = ctf_stats.player(killer)
	if main and match then
		main.score  = main.score  + bounty_score
		match.score = match.score + bounty_score
		main.bounty_kills = main.bounty_kills + 1
		match.bounty_kills = match.bounty_kills + 1
		ctf.needs_save = true
	end
	bountied_player = nil

	local msg = killer .. " has killed " .. victim .. " and received the prize!"
	minetest.chat_send_all(msg)
	hud_score.new(killer, {
		name = "ctf_bounty:prize",
		color = 0x4444FF,
		value = bounty_score
	})
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
