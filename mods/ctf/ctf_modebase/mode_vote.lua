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
	if not voted then return end

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
	local vote_setting = "ask"

	if ctf_settings.settings["ctf_modebase:default_vote_"..new_mode] then
		vote_setting = ctf_settings.get(minetest.get_player_by_name(player), "ctf_modebase:default_vote_"..new_mode)

		vote_setting = ctf_settings.settings["ctf_modebase:default_vote_"..new_mode]._list_map[tonumber(vote_setting)]
	end

	if vote_setting ~= "ask" then
		minetest.after(0, function()
			if not minetest.get_player_by_name(player) then return end

			minetest.chat_send_player(player,
				string.format("Voting for " .. new_mode .. ". Automatic vote: " .. vote_setting .. "\n" ..
				"To change the automatic vote settings, go to the \"Settings\" tab of your inventory."))
			player_vote(player, vote_setting)
		end)

		return
	end

	local elements = {}

	local i = 0.2
	local vote = 0
	while vote <= MAX_ROUNDS do
		local vote_num = vote
		elements[string.format("vote_%d", vote_num)] = {
			type = "button",
			label = vote_num,
			exit = true,
			pos = {"center", i},
			size = {1.4, 0.7},
			func = function()
				if votes then
					player_vote(player, vote_num)
				end
			end,
		}

		vote = vote + 1
		i = i + 1
	end

	i = i + 1.2
	elements["quit_button"] = {
		type = "button",
		exit = true,
		label = "Exit Game",
		pos = {x = "center", y = i},
		func = function(playername, fields, field_name)
			minetest.kick_player(playername, "You clicked 'Exit Game' in the mode vote formspec")
		end,
	}
	i = i + (ctf_gui.ELEM_SIZE.y - 0.2)

	ctf_gui.old_show_formspec(player, "ctf_modebase:mode_select", {
		size = {x = 8, y = i + 3.5},
		title = "Mode: "..HumanReadable(new_mode),
		description = "Please vote on how many matches you would like to play.\n" ..
			"You can change your default vote for this mode via the Settings tab (in your inventory)",
		header_height = 2.4,
		elements = elements,
	})
end

local function send_formspec()
	for pname in pairs(voted) do
		if not voted[pname] then
			show_modechoose_form(pname)
		end
	end
	formspec_send_timer = minetest.after(2, send_formspec)
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

	local mode_defined_rounds = ctf_modebase.modes[new_mode].rounds
	if not mode_defined_rounds then
		for _, player in pairs(minetest.get_connected_players()) do
			if ctf_teams.get(player) ~= nil or not ctf_modebase.current_mode then
				local pname = player:get_player_name()

				show_modechoose_form(pname)

				voted[pname] = false
				voters_count = voters_count + 1
			end
		end

		timer = minetest.after(VOTING_TIME, ctf_modebase.mode_vote.end_vote)
		formspec_send_timer = minetest.after(2, send_formspec)
	else
		ctf_modebase.current_mode_matches = mode_defined_rounds
		ctf_modebase.mode_on_next_match = new_mode
		ctf_modebase.start_match_after_vote()
	end
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
	for length = 0, MAX_ROUNDS do
		local vote_count = length_votes[length]
		if vote_count then
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
		voted[pname] = false
		voters_count = voters_count + 1
	end
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if votes and not voted[pname] then
		voters_count = voters_count - 1

		if voters_count == 0 then
			ctf_modebase.mode_vote.end_vote()
		end
	end

	if voted then
		voted[pname] = nil
	end
end)
