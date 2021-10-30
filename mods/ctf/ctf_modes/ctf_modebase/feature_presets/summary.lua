local previous = nil

return function(mode_data, rankings)

local start_time = nil
local winner = nil

local function team_rankings(total)
	local ranks = {}

	for team, rank_values in pairs(total) do
		rank_values._row_color = ctf_teams.team[team].color

		ranks[HumanReadable("team "..team)] = rank_values
	end

	return ranks
end

local function get_duration()
	if not start_time then
		return "-"
	end

	local time = os.time() - start_time
	return string.format("%02d:%02d:%02d",
        math.floor(time / 3600),        -- hours
        math.floor((time % 3600) / 60), -- minutes
        math.floor(time % 60))          -- seconds
end

return {
	summary_func = function(prev)
		if not prev then
			return
				rankings.recent(), team_rankings(rankings.teams()), mode_data.SUMMARY_RANKS, {
					title = "Match Summary",
					special_row_title = "Total Team Stats",
					gamemode = ctf_modebase.current_mode,
					winner = winner,
					duration = get_duration(),
					buttons = {previous = previous ~= nil},
				}
		elseif previous ~= nil then
			return
				previous.players, team_rankings(previous.teams), previous.mode_data.SUMMARY_RANKS, {
					title = "Previous Match Summary",
					special_row_title = "Total Team Stats",
					gamemode = previous.gamemode,
					winner = previous.winner,
					duration = previous.duration,
					buttons = {next = true},
				}
		end
	end,
	on_match_end = function()
		previous = {
			players = rankings.recent(),
			teams = rankings.teams(),
			gamemode = ctf_modebase.current_mode,
			winner = winner or "NO WINNER",
			duration = get_duration(),
			mode_data = mode_data,
		}
		start_time = nil
		winner = nil
	end,
	set_winner = function(i)
		winner = i
	end,
	on_match_start = function()
		start_time = os.time()
	end,
}

end
