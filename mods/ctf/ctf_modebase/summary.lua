local previous = nil
local game_stat = nil
local winner = nil

local player_sort_by = {}

minetest.register_on_leaveplayer(function(player) player_sort_by[player:get_player_name()] = nil end)

local function team_rankings(total)
	local ranks = {}

	for team, rank_values in pairs(total) do
		rank_values._row_color = ctf_teams.team[team].color

		ranks[HumanReadable("team " .. team)] = rank_values
	end

	return ranks
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
				duration = ctf_map.get_duration(),
				buttons = {previous = previous ~= nil},
				allow_sort = true,
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
				allow_sort = true,
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

ctf_api.register_on_match_end(function()
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return end
	local rankings = current_mode.recent_rankings

	previous = {
		players = rankings.players(),
		teams = rankings.teams(),
		game_stat = game_stat,
		winner = winner or "NO WINNER",
		duration = ctf_map.get_duration(),
		summary_ranks = current_mode.summary_ranks,
	}

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

	if formdef.allow_sort and player_sort_by[name] then
		rank_values._sort = player_sort_by[name]
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

	local sort_by_idx = table.indexof(rank_values, rank_values._sort)

	if sort_by_idx == -1 then
		sort_by_idx = 1
	end

	local modified_ranks = table.copy(rank_values)
	local sortby = table.remove(modified_ranks, sort_by_idx)

	local render = function(sorted)
		for i, ranks in ipairs(sorted) do
			local color = "white"

			if not formdef.disable_nonuser_colors then
				if not ranks._row_color then
					local team = ctf_teams.get(ranks.pname)

					if team then
						color = ctf_teams.team[team].color
					end
				else
					color = ranks._row_color
				end
			elseif name == ranks.pname then
				color = "gold"
			end

			local row = string.format(
				"%d,%s,%s,%s"..",%s,%s",
				ranks.number or i, color, ranks.pname, color, math.round(ranks[rank_values[sort_by_idx]] or 0), color
			)
			local rv = table.copy(rank_values)
			table.remove(rv, sort_by_idx)

			for idx, rank in ipairs(rv) do
				row = string.format("%s,%d", row, math.round(ranks[rank] or 0))
			end

			sorted[i] = row
		end
	end

	render(rankings)
	render(special_rankings)

	if #special_rankings >= 1 then
		if formdef.special_row_title then
			table.insert(special_rankings, 1, string.format(
				",white,%s,cyan,%s,white,%s",
				formdef.special_row_title, HumanReadable(sortby), HumanReadable(table.concat(modified_ranks, "  ,"))
			))
		end

		table.insert(special_rankings, string.rep(",", #modified_ranks+6))
	end

	local formspec = {
		title = formdef.title or "Summary",
		elements = {
			rankings = {
				type = "table",
				pos = {0.1, 1 + (formdef.allow_sort and 1 or 0)},
				size = {
					math.max(
						ctf_gui.FORM_SIZE.x - 0.2,
						((1 + 8 + 16 + table.concat(rank_values, "  ,"):len())) * 0.3
					),
					(ctf_gui.FORM_SIZE.y - (formdef.allow_sort and 2 or 1)) - (ctf_gui.ELEM_SIZE.y + 3)
				},
				options = {
					highlight = "#00000000",
				},
				columns = {
					{type = "text", width = 1},
					{type = "color"}, -- Player team color
					{type = "text", width = 16}, -- Player name
					"color", -- sortby text color
					"text", -- sortby text
					"color", -- Reset color
					("text;"):rep(#modified_ranks):sub(1, -2),
				},
				rows = {
					#special_rankings > 1 and table.concat(special_rankings, ",") or "",
					"white", "Player Name",
					"cyan", HumanReadable(sortby).."  ", "white",
					HumanReadable(table.concat(modified_ranks, "  ,")),
					table.concat(rankings, ",")
				}
			}
		}
	}

	if formdef.allow_sort then
		formspec.elements.sorting = {
			type = "dropdown",
			items = rank_values,
			default_idx = sort_by_idx,
			give_idx = false,
			pos = {x = 13, y = 1},
			size = {x = ctf_gui.ELEM_SIZE.x + 1, y = ctf_gui.ELEM_SIZE.y},
			func = function(playername, fields, field_name)
				if fields.sorting and sortby ~= fields.sorting and table.indexof(rank_values, fields.sorting) ~= -1 then
					player_sort_by[playername] = fields.sorting
					show_for_player(playername, formdef.buttons.next and true or false)
				end
			end,
		}
		formspec.elements.label = {
			type = "label",
			pos = {13, 0.5},
			label = "Sort players by: "
		}
	end

	if formdef.buttons.next then
		formspec.elements.next = {
			type = "button",
			label = "See Current",
			pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
			func = function()
				show_for_player(name, false)
			end,
		}
	end

	if formdef.buttons.previous then
		formspec.elements.previous = {
			type = "button",
			label = "See Previous",
			pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
			func = function()
				show_for_player(name, true)
			end,
		}
	end

	if formdef.game_stat then
		formspec.elements.game_stat = {
			type = "label",
			pos = {1, 0.5},
			label = formdef.game_stat,
		}
	end

	if formdef.winner then
		formspec.elements.winner = {
			type = "label",
			pos = {5, 1.3},
			label = formdef.winner,
		}
	end

	if formdef.duration then
		formspec.elements.duration = {
			type = "label",
			pos = {1, 1.3},
			label = "Duration: " .. formdef.duration,
		}
	end

	ctf_gui.old_show_formspec(name, "ctf_modebase:summary", formspec)
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
