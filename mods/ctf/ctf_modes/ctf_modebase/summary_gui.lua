local get_team = ctf_teams.get
local teams = ctf_teams.team
local format = string.format
local insert = table.insert
local sort = table.sort
local concat = table.concat

---@param name string Player name
---@param rankings table Recent rankings to show in the gui
---@param rank_values table Example: `{_sort = "score", "captures" "kills"}`
---@param formdef table table for customizing the formspec
function ctf_modebase.show_summary_gui(name, rankings, rank_values, formdef)
	rank_values = table.copy(rank_values)

	local rows = {}
	local sort_by = rank_values._sort or rank_values[1]
	local special_rows = {}

	if not formdef then formdef = {} end
	if not formdef.buttons then formdef.buttons = {} end

	for pname, ranks in pairs(rankings) do
		local color = "white"

		if not formdef.disable_nonuser_colors then
			if not ranks._row_color then
				local team = get_team(pname)

				if team then
					color = teams[team].color
				end
			else
				color = ranks._row_color
			end
		elseif name == pname then
			color = "gold"
		end

		local row = format("%s,%s", color, pname)

		for idx, rank in ipairs(rank_values) do
			row = format("%s,%s", row, ranks[rank] or 0)
		end

		insert(ranks._special_row and special_rows or rows, {row = row, sort = ranks[sort_by] or 0})
	end

	sort(rows, function(a, b) return a.sort > b.sort end)

	if #special_rows >= 1 then
		sort(special_rows, function(a, b) return a.sort > b.sort end)

		for i, c in pairs(special_rows) do
			special_rows[i] = format("%s,%s", i, c.row)
		end

		if formdef.special_row_title then
			insert(special_rows, 1, format(",white,%s,%s", formdef.special_row_title, HumanReadable(concat(rank_values, "  ,"))))
		end

		insert(special_rows, string.rep(",", #rank_values+3))
	end

	for i, c in pairs(rows) do
		rows[i] = format("%s,%s", i, c.row)
	end

	ctf_gui.show_formspec(name, "ctf_modebase:summary", {
		title = formdef.title or "Summary",
		elements = {
			rankings = {
				type = "table",
				pos = {"center", 0},
				size = {ctf_gui.FORM_SIZE.x-1, ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 3)},
				options = {
					highlight = "#00000000",
				},
				columns = {
					{type = "text", width = 1},
					{type = "color"}, -- Player team color
					{type = "text", width = 16}, -- Player name
					("text;"):rep(#rank_values):sub(1, -2),
				},
				rows = {
					#special_rows > 1 and concat(special_rows, ",") or "",
					"white", "Player Name", HumanReadable(concat(rank_values, "  ,")),
					concat(rows, ",")
				}
			},
			next = formdef.buttons.next and {
				type = "button",
				label = "See Current",
				pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
				func = function(playername, fields, field_name)
					local current_mode = ctf_modebase:get_current_mode()

					if not current_mode then return end

					local result, ranks, match_rank_values, newformdef = current_mode.summary_func(playername)

					if result then
						ctf_modebase.show_summary_gui(playername, ranks, match_rank_values, newformdef)
					end
				end,
			},
			previous = formdef.buttons.previous and {
				type = "button",
				label = "See Previous",
				pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
				func = function(playername, fields, field_name)
					local current_mode = ctf_modebase:get_current_mode()

					if not current_mode then return end

					local result, ranks, match_rank_values, newformdef = current_mode.summary_func(playername, "previous")

					if result then
						ctf_modebase.show_summary_gui(playername, ranks, match_rank_values, newformdef)
					end
				end,
			},
		}
	})
end

minetest.register_chatcommand("summary", {
	description = "Show a summary for the current match",
	func = function(name, param)
		local current_mode = ctf_modebase:get_current_mode()

		if not current_mode then
			return false, "No match has started yet!"
		end

		if current_mode.summary_func then
			local result, rankings, rank_values, formdef = current_mode.summary_func(name, param)

			if result then
				ctf_modebase.show_summary_gui(name, rankings, rank_values, formdef)
			else
				return result, rankings -- rankings holds an error message in this case
			end

			return true
		else
			return false, "This mode doesn't have a summary command!"
		end
	end
})

minetest.register_chatcommand("s", minetest.registered_chatcommands.summary)
