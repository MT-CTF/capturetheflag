local previous = nil
local game_stat = nil
local winner = nil

local player_sort_by = {}

local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_on_leaveplayer(function(player) player_sort_by[player:get_player_name()] = nil end)

local function team_rankings(total)
	local ranks = {}

	for team, rank_values in pairs(total) do
		rank_values._row_color = ctf_teams.team[team].color

		ranks[HumanReadable(S("team") .." ".. team)] = rank_values
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
				title = S("Match Summary"),
				special_row_title = S("Total Team Stats"),
				game_stat = game_stat,
				winner = winner,
				duration = ctf_map.get_duration(),
				map = ctf_map.current_map.name,
				buttons = {previous = previous ~= nil},
				allow_sort = true,
			}
	elseif previous ~= nil then
		return
			previous.players, team_rankings(previous.teams), previous.summary_ranks, {
				title = S("Previous Match Summary"),
				special_row_title = S("Total Team Stats"),
				game_stat = previous.game_stat,
				winner = previous.winner,
				duration = previous.duration,
				map = previous.map,
				buttons = {next = true},
				allow_sort = true,
			}
	end
end

ctf_api.register_on_new_match(function()
	game_stat = S("@1 mode: Round @2 of @3",
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
		winner = winner or S("NO WINNER"),
		duration = ctf_map.get_duration(),
		map = ctf_map.current_map.name,
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

	ctf_gui.show_formspec(name, "ctf_modebase:summary", function(ctx)
		local winfo = core.get_player_window_information(ctx.pname)

		-- EDITOR: Fix crash
		-- local S = function(x) return x end

		-- EDITOR: Edit COUNT to control rank entries
		-- local COUNT = 11
		-- for i=1, COUNT - #ctx.rankings, 1 do
		-- 	table.insert(ctx.rankings, 1, ctx.rankings[1])
		-- end
		-- for i=1, #ctx.rankings - COUNT, 1 do
		-- 	table.remove(ctx.rankings, 1)
		-- end

		local TWO_START_COLS_LEN = 28
		local tlen = ctx.sortby:len() + TWO_START_COLS_LEN

		for _, str in pairs(ctx.modified_ranks) do
			tlen = tlen + math.max(6, str:len()) + 0.333
		end

		-- target: 0.6555
		local FORM_X = 18.7
		local FORM_Y = 13.7

		if winfo then
			FORM_X = (FORM_X > winfo.max_formspec_size.x) and winfo.max_formspec_size.x or FORM_X
			FORM_Y = (FORM_Y > winfo.max_formspec_size.y) and winfo.max_formspec_size.y or FORM_Y
		end

		local EDITOR_X = 1920
		local EDITOR_Y = 1080

		if not winfo then
			winfo = {size = {x = EDITOR_X, y = EDITOR_Y}, max_formspec_size = {x = 28, y = 15}}
		end

		local SCALE_SIZE_X = 0.14 * (EDITOR_X / winfo.size.x) * (winfo.max_formspec_size.x / FORM_X)
		local SCALE_SIZE_Y = 0.39 * (EDITOR_Y / winfo.size.y) * (winfo.max_formspec_size.y / FORM_Y)

		local EXTRA_HEIGHT = (ctx.formdef.winner and 1 or 0) +
				(ctx.formdef.game_stat and 1 or 0) +
				(ctx.formdef.duration and 1 or 0)
		local EXTRA_HEIGHT_INVERSE = 3 - EXTRA_HEIGHT
		local EXTRA_HEADER = #ctx.rankings >= 20

		local BOTH_BUTTONS = ctx.formdef.buttons.next and ctx.formdef.buttons.previous
		local NEITHER_BUTTONS = not ctx.formdef.buttons.next and not ctx.formdef.buttons.previous
		local FILL_FORM = 0

		if NEITHER_BUTTONS then
			FILL_FORM = 1.5
		end

		local out = {
			"formspec_version[8]",
			{"size[%.1f,%.1f;true]", FORM_X, FORM_Y},
			"padding[0,0]",
			{
				"label[0.5,2;%s%s%s]",
				(ctx.formdef.winner and (ctx.formdef.winner .. "\n") or ""),
				(ctx.formdef.game_stat and (ctx.formdef.game_stat .. "\n") or ""),
				(ctx.formdef.duration and (S("Duration") ..": ".. ctx.formdef.duration) or ""),
			},
			{"hypertext[0,0.2;%.1f,1.6;title;<center><big>", FORM_X},
				core.formspec_escape((ctx.formdef.title or S("Summary")) .. (ctx.formdef.map and " - "..ctx.formdef.map or "")),
			"</big></center>]",
			{
				"scroll_container[0.2,%.1f;%.1f,%.1f;formcontenty;vertical;0.1;0]",
				1 + EXTRA_HEIGHT,
				FORM_X - 0.8,
				(FORM_Y - 6.3) + EXTRA_HEIGHT_INVERSE + FILL_FORM
			},
			{
				"scroll_container[0,0;%.1f,%.1f;formcontentx;horizontal;0.1;0]",
				FORM_X - 0.8,
				math.max( -- SCROLL HEIGHT
					(FORM_Y - 6.3) + EXTRA_HEIGHT_INVERSE,
					(#ctx.rankings + #ctx.special_rankings) * SCALE_SIZE_Y
				) + FILL_FORM,
			},
			"tableoptions[highlight=#00000000;border=false]",
			string.format(
				"tablecolumns[text,width=4;color;text,width=18;color;text,width=6;color;%s]",
				("text,width=6;"):rep(#ctx.modified_ranks):sub(1, -2)
			),
			"style[rankings;font_size=14;font=mono]",
			string.format(
				"table[0,0;%.1f,%.1f;rankings;%s,%s%s;1]",
				math.max(
					FORM_X - 0.2,
					tlen * SCALE_SIZE_X -- SCROLL WIDTH
				),
				--
				-- Height of table, should always be big enough to fit all entries,
				-- will get cut to size by scroll container
				math.max(#ctx.rankings, FORM_Y),
				#ctx.special_rankings > 1 and table.concat(ctx.special_rankings, ",") or "",
				table.concat({
					"white",
					S("Player Name"),
					"cyan", HumanReadable(ctx.sortby).."  ", "white",
					HumanReadable(table.concat(ctx.modified_ranks, "  ,")),
					table.concat(ctx.rankings, ","),
				}, ","),
				EXTRA_HEADER and table.concat({
					",,white",
					S("Player Name"),
					"cyan", HumanReadable(ctx.sortby).."  ", "white",
					HumanReadable(table.concat(ctx.modified_ranks, "  ,")),
				}, ",") or ""
				-- EDITOR: Measuring, remember to add 1 row to table's width calc, and a %s to format str
				-- ,",++++,green,+++++1+++++++++2++,red,+++++++,green,3+++++++++4++++,+++++5+++++++++,6++++++,+++7+++++++++8,
				--+++++++++9++++,++++10++,++++++11+++,+++++12++++++++13++++++++14++++++++15"
			),
			"scroll_container_end[]",
			"scroll_container_end[]",
			{
				"scrollbar[%.1f,%.1f;0.4,%.1f;vertical;formcontenty;0]",
				FORM_X - 0.5,
				EXTRA_HEIGHT + 1,
				(FORM_Y - 6.3) + EXTRA_HEIGHT_INVERSE + FILL_FORM
			},
			{
				"scrollbar[0.2,%.1f;%.1f,0.4;horizontal;formcontentx;0]",
				FORM_Y - 2.2 + FILL_FORM,
				FORM_X - 0.7,
			},
		}

		if ctx.formdef.allow_sort then
			local x = FORM_X - (ctf_gui.ELEM_SIZE.x + 1.5)
			local y = 1.8
			table.insert(out, string.format(
				"dropdown[%.1f,%.1f;%.1f,%.1f;sorting;%s;1;false]",
				x, y + 0.2,
				ctf_gui.ELEM_SIZE.x + 1,
				ctf_gui.ELEM_SIZE.y,
				table.concat(ctx.rank_values, ",")
			))

			table.insert(out, string.format(
				"label[%.1f,%.1f;%s: ]",
				x, y,
				S("Sort players by")
			))
		end

		local x_pos = FORM_X / 2 - 2.5

		if BOTH_BUTTONS then x_pos = (FORM_X / 2 - 2.5) + 3 end

		if ctx.formdef.buttons.next then
			table.insert(out,  string.format(
				"button[%.1f,%.1f;5,1;next;%s]",
				x_pos,
				FORM_Y - 1.3,
				BOTH_BUTTONS and S("See Next") or S("See Current")
			))
		end

		if BOTH_BUTTONS then x_pos = (FORM_X / 2 - 2.5) - 3 end

		if ctx.formdef.buttons.previous then
			table.insert(out, string.format(
				"button[%.1f,%.1f;5,1;previous;%s]",
				x_pos,
				FORM_Y - 1.3,
				S("See Previous")
			))
		end

		return ctf_gui.list_to_formspec_str(out)
	end,
	{
		formdef = formdef,
		rank_values = rank_values,
		rankings = rankings,
		special_rankings = special_rankings,
		modified_ranks = modified_ranks,
		sortby = sortby,
		pname = name,
		_on_formspec_input = function(pname, context, fields)
			if context.formdef.buttons.previous and fields.previous then
				show_for_player(pname, true)
			end

			if context.formdef.buttons.next and fields.next then
				show_for_player(pname, false)
			end

			if context.formdef.allow_sort then
				if fields.sorting and sortby ~= fields.sorting and table.indexof(rank_values, fields.sorting) ~= -1 then
					player_sort_by[pname] = fields.sorting
					show_for_player(pname, context.formdef.buttons.next and true or false)
				end
			end
		end,
	})

	minetest.log("action", "[ctf_modebase.summary] Showed gui to "..dump(name))
end

ctf_core.register_chatcommand_alias("summary", "s", {
	description = S("Show a summary for the current match"),
	func = function(name, param)
		local prev
		if not param or param == "" then
			prev = false
		elseif param:match("p") then
			prev = true
		else
			return false, S("Can't understand param") .." ".. dump(param)
		end

		if not show_for_player(name, prev) then
			return false, S("No match summary!")
		end

		return true
	end
})
