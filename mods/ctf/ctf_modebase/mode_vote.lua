local VOTING_TIME = 30
local MAX_ROUNDS = 5

local timer = nil
local formspec_send_timer = nil
local votes = nil
local voted = nil
local voters_count = nil
local new_mode

ctf_modebase.mode_vote = {}

local function player_vote(name, length)
	if not voted[name] then
		voters_count = voters_count - 1
	end

	voted[name] = true
	votes[minetest.get_player_information(name).address] = length

	if voters_count == 0 then
		ctf_modebase.mode_vote.end_vote()
	end
end

local function show_modechoose_form(player)
	local elements = {}

	for i = 0, MAX_ROUNDS do
		elements[string.format("vote_%d", i)] = {
			type = "button",
			label = i,
			exit = true,
			pos = {"center", i},
			func = function()
				if votes then
					player_vote(player, i)
				end
			end,
		}
	end

	ctf_gui.show_formspec(player, "ctf_modebase:mode_select", {
		size = {x = 8, y = 8},
		title = "Mode: "..HumanReadable(new_mode),
		description = "Please vote on how many matches you would like to play",
		elements = elements,
	})
end

local function send_formspec()
	for _, player in pairs(minetest.get_connected_players()) do
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

	local mode_index = new_mode and table.indexof(ctf_modebase.modelist, new_mode) or -1
	if mode_index == -1 or mode_index+1 > #ctf_modebase.modelist then
		new_mode = ctf_modebase.modelist[1]
	else
		new_mode = ctf_modebase.modelist[mode_index + 1]
	end

	for _, player in pairs(minetest.get_connected_players()) do
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

	for _, player in pairs(minetest.get_connected_players()) do
		minetest.close_formspec(player:get_player_name(), "ctf_modebase:mode_select")
	end

	local length_votes = {}
	for _, length in pairs(votes) do
		length_votes[length] = (length_votes[length] or 0) + 1
	end

	votes = nil
	voted = nil

	local votes_result = ""
	local average_vote = 0
	local entry_count = 0
	for length, vote_count in pairs(length_votes) do
		votes_result = votes_result .. string.format(
			"    %d vote%s for %d match%s\n",
			vote_count,
			vote_count == 1 and "" or "s",
			length,
			length == 1 and "" or "es"
		)

		entry_count = entry_count + vote_count
		average_vote = average_vote + (length * vote_count)
	end

	if entry_count > 0 then
		average_vote = math.round(average_vote / entry_count)
	else
		average_vote = MAX_ROUNDS -- no votes, default to max rounds
	end

	votes_result = string.format(
		"Voting is over. The mode %s will be played for %d match%s\n%s",
		HumanReadable(new_mode),
		average_vote,
		average_vote == 1 and "" or "es",
		votes_result:sub(1, -2)
	)

	minetest.chat_send_all(votes_result)
	ctf_modebase.announce(votes_result)

	ctf_modebase.current_mode_matches = average_vote
	if average_vote <= 0 then
		ctf_modebase.mode_vote.start_vote()
	else
		ctf_modebase.mode_on_next_match = new_mode
		ctf_modebase.start_match_after_vote()
	end
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
