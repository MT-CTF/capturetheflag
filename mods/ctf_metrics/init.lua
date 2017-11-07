if not minetest.global_exists("prometheus") then
	return
end

local kill_counter = 0
ctf.register_on_killedplayer(function(victim, killer, type)
	kill_counter = kill_counter + 1
end)

local function step()
	prometheus.post("minetest_kills", kill_counter)
	kill_counter = 0

	local sum = 0
	local avg = 0
	if #minetest.get_connected_players() > 0 then
		for _, player in pairs(minetest.get_connected_players()) do
			local total, match = ctf_stats.player(player:get_player_name())
			sum = sum + total.score
		end
		avg = sum / #minetest.get_connected_players()
	end

	prometheus.post("minetest_ctf_score_total", sum)
	prometheus.post("minetest_ctf_score_avg", avg)

	minetest.after(15, step)
end
minetest.after(15, step)
