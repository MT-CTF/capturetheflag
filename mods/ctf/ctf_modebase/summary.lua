local previous = nil
local start_time = nil
local game_stat = nil
local winner = nil

local function team_rankings(total)
	local ranks = {}

	for team, rank_values in pairs(total) do
		rank_values._row_color = ctf_teams.team[team].color

		ranks[HumanReadable("team " .. team)] = rank_values
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

ctf_modebase.summary = {}

function ctf_modebase.summary.get(prev)
	if not prev then
		local current_mode = ctf_modebase:get_current_mode()
		if not current_mode then return end
		local rankings = current_mode.recent_rankings

		return
			rankings.players(), team_rankings(rankings.teams()), current_mode.summary_ranks, {
				title = "Match Summary",
				special_row_title = "Total Team Stats",
				game_stat = game_stat,
				winner = winner,
				duration = get_duration(),
				buttons = {previous = previous ~= nil},
			}
	elseif previous ~= nil then
		return
			previous.players, team_rankings(previous.teams), previous.summary_ranks, {
				title = "Previous Match Summary",
				special_row_title = "Total Team Stats",
				game_stat = previous.game_stat,
				winner = previous.winner,
				duration = previous.duration,
				buttons = {next = true},
			}
	end
end

ctf_api.register_on_new_match(function()
	game_stat = string.format("%s mode: Round %d of %d",
		HumanReadable(ctf_modebase.current_mode),
		ctf_modebase.current_mode_matches_played + 1,
		ctf_modebase.current_mode_matches
	)
end)

ctf_api.register_on_match_start(function()
	start_time = os.time()
end)

ctf_api.register_on_match_end(function()
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	local rankings = current_mode.recent_rankings

	previous = {
		players = rankings.players(),
		teams = rankings.teams(),
		game_stat = game_stat,
		winner = winner or "NO WINNER",
		duration = get_duration(),
		summary_ranks = current_mode.summary_ranks,
	}

	start_time = nil
	winner = nil
end)

function ctf_modebase.summary.set_winner(i)
	winner = i
end

---@param name string Player name
---@param rankings table Recent rankings to show in the gui
---@param rank_values table Example: `{_sort = "score", "captures" "kills"}`
---@param formdef table table for customizing the formspec
function ctf_modebase.summary.show_gui(name, rankings, special_rankings, rank_values, formdef)
	local sort_by = rank_values._sort or rank_values[1]

	local sort = function(unsorted)
		local sorted = {}

		for pname, ranks in pairs(unsorted) do
			local t = table.copy(ranks)
			t.pname = pname
			t.sort = ranks[sort_by] or 0
			table.insert(sorted, t)
		end

		table.sort(sorted, function(a, b) return a.sort > b.sort end)

		return sorted
	end

	ctf_modebase.summary.show_gui_sorted(name, sort(rankings), sort(special_rankings), rank_values, formdef)
end

local function show_for_player(name, prev)
	local match_rankings, special_rankings, rank_values, formdef = ctf_modebase.summary.get(prev)
	if not match_rankings then
		return false
	end

	ctf_modebase.summary.show_gui(name, match_rankings, special_rankings, rank_values, formdef)
	return true
end

---@param name string Player name
---@param rankings table Sorted recent rankings Example: `{{pname=a, score=2}, {pname=b, score=1}}`
---@param rank_values table Example: `{_sort = "score", "captures" "kills"}`
---@param formdef table table for customizing the formspec
function ctf_modebase.summary.show_gui_sorted(name, rankings, special_rankings, rank_values, formdef)
	if not formdef then formdef = {} end
	if not formdef.buttons then formdef.buttons = {} end

	minetest.handle_async(
	function(
		name_a, rankings_a, special_rankings_a, rank_values_a,
		formdef_a, form_size_a, elem_size_a,
		human_readable
	)
		local render = function(sorted)
			for i, ranks in ipairs(sorted) do
				local color = "white"

				if not formdef_a.disable_nonuser_colors then
					if not ranks._row_color then
						local team = ctf_teams.get(ranks.pname)

						if team then
							color = ctf_teams.team[team].color
						end
					else
						color = ranks._row_color
					end
				elseif name_a == ranks.pname then
					color = "gold"
				end

				local row = string.format("%d,%s,%s", ranks.number or i, color, ranks.pname)

				for idx, rank in ipairs(rank_values_a) do
					row = string.format("%s,%s", row, math.round(ranks[rank] or 0))
				end

				sorted[i] = row
			end
		end

		render(rankings_a)
		render(special_rankings_a)

		if #special_rankings_a >= 1 then
			if formdef_a.special_row_title then
				table.insert(special_rankings_a, 1, string.format(
					",white,%s,%s", formdef_a.special_row_title, human_readable(table.concat(rank_values_a, "  ,"))
				))
			end

			table.insert(special_rankings_a, string.rep(",", #rank_values_a+3))
		end

		local formspec = {
			title = formdef_a.title or "Summary",
			elements = {
				rankings = {
					type = "table",
					pos = {0.1, 1},
					size = {
						math.max(form_size_a.x - 0.2, ((1 + 8 + 16 + table.concat(rank_values_a, "  ,"):len())) * 0.3),
						form_size_a.y - 1 - (elem_size_a.y + 3)
					},
					options = {
						highlight = "#00000000",
					},
					columns = {
						{type = "text",  width = 1 },
						{type = "color", width = 8 }, -- Player team color
						{type = "text",  width = 16}, -- Player name_a
						("text;"):rep(#rank_values_a):sub(1, -2),
					},
					rows = {
						#special_rankings_a > 1 and table.concat(special_rankings_a, ",") or "",
						"white", "Player Name", human_readable(table.concat(rank_values_a, "  ,")),
						table.concat(rankings_a, ",")
					}
				}
			}
		}

		if formdef_a.game_stat then
			formspec.elements.game_stat = {
				type = "label",
				pos = {11, 0.5},
				label = formdef_a.game_stat,
			}
		end

		if formdef_a.winner then
			formspec.elements.winner = {
				type = "label",
				pos = {4, 0.5},
				label = formdef_a.winner,
			}
		end

		if formdef_a.duration then
			formspec.elements.duration = {
				type = "label",
				pos = {1, 0.5},
				label = "Duration: " .. formdef_a.duration,
			}
		end

		return formspec
	end, function(form_return)
		if formdef.buttons.next then
			form_return.elements.next = {
				type = "button",
				label = "See Current",
				pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
				func = function()
					show_for_player(name, false)
				end,
			}
		end

		if formdef.buttons.previous then
			form_return.elements.previous = {
				type = "button",
				label = "See Previous",
				pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
				func = function()
					show_for_player(name, true)
				end,
			}
		end

		ctf_gui.old_show_formspec(name, "ctf_modebase:summary", form_return)
	end,
	name, rankings, special_rankings, rank_values,
	formdef, ctf_gui.FORM_SIZE, ctf_gui.ELEM_SIZE,
	HumanReadable)
end

ctf_core.register_chatcommand_alias("summary", "s", {
	description = "Show a summary for the current match",
	func = function(name, param)
		local prev
		if not param or param == "" then
			prev = false
		elseif param:match("p") then
			prev = true
		else
			return false, "Can't understand param " .. dump(param)
		end

		if not show_for_player(name, prev) then
			return false, "No match summary!"
		end

		return true
	end
})
