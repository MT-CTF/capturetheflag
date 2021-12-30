local VOTING_TIME = 30

local timer = nil
local formspec_send_timer = nil
local votes = nil
local voted = nil
local voters_count = nil

ctf_modebase.mode_vote = {}

local function player_vote(name, modename)
	if not voted[name] then
		voters_count = voters_count - 1
	end

	voted[name] = true
	votes[minetest.get_player_information(name).address] = modename

	if voters_count == 0 then
		ctf_modebase.mode_vote.end_vote()
	end
end

local function show_modechoose_form(player)
	local modenames = {}

	for modename in pairs(ctf_modebase.modes) do
		if modename ~= ctf_modebase.current_mode then
			table.insert(modenames, modename)
		end
	end
	table.sort(modenames)

	local elements = {}
	local idx = 0
	for _, modename in ipairs(modenames) do
		elements[modename] = {
			type = "button",
			label = HumanReadable(modename),
			exit = true,
			pos = {"center", idx + 0.5},
			func = function()
				if votes and ctf_modebase.modes[modename] then
					player_vote(player, modename)
				end
			end,
		}

		idx = idx + 1
	end

	ctf_gui.show_formspec(player, "ctf_modebase:mode_select", {
		size = {x = 8, y = 8},
		title = "Mode Selection",
		description = "Please vote on what gamemode you would like to play",
		elements = elements,
	})
end

local function send_formspec()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if not voted[pname] then
			show_modechoose_form(pname)
		end
	end
	formspec_send_timer = minetest.after(1, send_formspec)
end

function ctf_modebase.mode_vote.start_vote()
	votes = {}
	voted = {}
	voters_count = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		show_modechoose_form(player:get_player_name())
		voters_count = voters_count + 1
	end

	timer = minetest.after(VOTING_TIME, ctf_modebase.mode_vote.end_vote)
	formspec_send_timer = minetest.after(1, send_formspec)
end

function ctf_modebase.mode_vote.end_vote()
	if timer then
		timer:cancel()
		timer = nil
	end

	if formspec_send_timer then
		formspec_send_timer:cancel()
		formspec_send_timer = nil
	end

	for _, player in ipairs(minetest.get_connected_players()) do
		minetest.close_formspec(player:get_player_name(), "ctf_modebase:mode_select")
	end

	local modes = {}
	for _, mode in ipairs(ctf_modebase.modelist) do
		if ctf_modebase.current_mode ~= mode then
			modes[mode] = 0
		end
	end

	for _, mode in pairs(votes) do
		modes[mode] = modes[mode] + 1
	end

	votes = nil
	voted = nil

	local max_votes = 0
	for _, count in pairs(modes) do
		max_votes = math.max(max_votes, count)
	end

	local votes_result = ""
	local best_modes = {}
	for mode, count in pairs(modes) do
		votes_result = votes_result .. string.format("%s got %d votes, ", HumanReadable(mode), count)
		if count == max_votes then
			table.insert(best_modes, mode)
		end
	end

	local new_mode = best_modes[math.random(1, #best_modes)]

	minetest.chat_send_all(string.format("Voting is over, %s won with %d votes!\n%s",
		HumanReadable(new_mode), max_votes, votes_result:sub(1, -3)
	))

	ctf_modebase.mode_on_next_match = new_mode
	ctf_modebase.start_match_after_vote()
end

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()

	if votes and not voted[pname] then
		show_modechoose_form(pname)
		voters_count = voters_count + 1
	end
end)

minetest.register_on_leaveplayer(function(player)
	if votes and not voted[player:get_player_name()] then
		voters_count = voters_count - 1

		if voters_count == 0 then
			ctf_modebase.mode_vote.end_vote()
		end
	end
end)
