ctf_modebase = {
	-- Time until voting ends
	VOTING_TIME          = 20,    ---@type integer

	-- Amount of maps that need to be played before a mode vote starts
	MAPS_PER_MODE        = 5,     ---@type integer

	-- Table containing all registered modes and their definitions
	modes                = {},    ---@type table

	-- Same as ctf_modebase.modes but in list form
	modelist             = {},    ---@type list

	-- Name of the mode currently being played. On server start this will be false
	current_mode         = false, ---@type string

	-- Get the mode def of the current mode. On server start this will return false
	get_current_mode = function(self)
		return self.current_mode and self.modes[self.current_mode]
	end,

	-- Amount of matches played since this mode won the last vote
	current_mode_matches = 0,     ---@type integer

	-- taken_flags[Player Name] = list of team names
	taken_flags          = {},

	-- flag_taken[Team Name] = Name of thief
	flag_taken           = {},

	--flag_captured[Team name] = true if captured, otherwise nil
	flag_captured        = {},
}

ctf_gui.init()

ctf_core.include_files(
	"summary_gui.lua",
	"give_initial_stuff.lua",
	"treasure.lua",
	"register.lua",
	"commands.lua",
	"flags/nodes.lua",
	"flags/taking.lua",
	"match.lua",
	"mode_functions.lua",
	"crafting.lua",
	"hpregen.lua",
	"respawn_delay.lua",
	"markers.lua"
)

ctf_modebase.bounties = ctf_core.include_files("bounties.lua")

if ctf_core.settings.server_mode == "play" then
	local match_started = false

	minetest.register_on_joinplayer(function(player)
		if not match_started then
			ctf_modebase.current_mode_matches = ctf_modebase.MAPS_PER_MODE
			ctf_modebase.start_new_match(true)
			match_started = true
		end

		player:set_hp(player:get_properties().hp_max)
	end)
end
