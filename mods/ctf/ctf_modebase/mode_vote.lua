local VOTING_TIME = 30

local timer = nil
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

	minetest.chat_send_all(string.format("%s voted for the mode '%s'", name, HumanReadable(modename)))

	if voters_count == 0 then
		ctf_modebase.mode_vote.end_vote()
	end
end

local function show_modechoose_form(player)
	local modenames = {}

	for modename in pairs(ctf_modebase.modes) do
		table.insert(modenames, modename)
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
				if votes then
					if ctf_modebase.modes[modename] then
						player_vote(player, modename)
					else
						show_modechoose_form(player)
					end
				end
			end,
		}

		idx = idx + 1
	end

	ctf_gui.show_formspec(player, "ctf_modebase:mode_select", {
		size = {x = 8, y = 8},
		title = "Mode Selection",
		description = "Please vote on what gamemode you would like to play",
		on_quit = function()
			if votes and not voted[player] then
				show_modechoose_form(player)
			end
		end,
		elements = elements,
	})
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
end

function ctf_modebase.mode_vote.end_vote()
	if timer then
		timer:cancel()
		timer = nil
	end

	for _, player in ipairs(minetest.get_connected_players()) do
		minetest.close_formspec(player:get_player_name(), "ctf_modebase:mode_select")
	end

	local modes = {}
	for _, mode in ipairs(ctf_modebase.modelist) do
		modes[mode] = 0
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

	local best_modes = {}
	for mode, count in pairs(modes) do
		if count == max_votes then
			table.insert(best_modes, mode)
		end
	end

	local new_mode = best_modes[math.random(1, #best_modes)]

	minetest.chat_send_all(string.format("Voting is over, '%s' won with %d votes!",
		HumanReadable(new_mode),
		max_votes
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
