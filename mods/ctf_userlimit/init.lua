if minetest.register_can_bypass_userlimit then
	minetest.register_can_bypass_userlimit(function(name, ip)
		local pstat, _ = ctf_stats.player_or_nil(name)
		local actual_max_users = tonumber(minetest.settings:get("max_users")) +
			tonumber(minetest.settings:get("max_extra_users") or "10")
		local req_score = tonumber(minetest.settings:get("userlimit_bypass_required_score") or "10000")
		return pstat and pstat.score > req_score and #minetest.get_connected_players() < actual_max_users
	end)
end
