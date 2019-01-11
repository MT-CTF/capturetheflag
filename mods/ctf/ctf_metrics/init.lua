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
	local bins = { r050=0, r200=0, r5000=0, rest=0 }
	if #minetest.get_connected_players() > 0 then
		for _, player in pairs(minetest.get_connected_players()) do
			local total, _ = ctf_stats.player(player:get_player_name())
			sum = sum + total.score

			if total.score > 174000 then
				bins.r050 = bins.r050 + 1
			elseif total.score > 10000 then
				bins.r200 = bins.r200 + 1
			elseif total.score > 1000 then
				bins.r5000 = bins.r5000 + 1
			else
				bins.rest = bins.rest + 1
			end
		end
		avg = sum / #minetest.get_connected_players()
	end

	for key, value in pairs(bins) do
		prometheus.post("minetest_ctf_score_bins{rank=\"" .. key .. "\"}", value)
	end

	prometheus.post("minetest_ctf_score_total", sum)
	prometheus.post("minetest_ctf_score_avg", avg)

	minetest.after(15, step)
end
minetest.after(15, step)
