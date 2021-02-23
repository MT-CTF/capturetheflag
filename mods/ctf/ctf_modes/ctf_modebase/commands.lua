local mode_chatcommands = {}
function ctf_modebase.register_chatcommand(modename, name, def)
	if not mode_chatcommands[modename] then
		mode_chatcommands[modename] = {}
	end

	mode_chatcommands[modename][name] = def.func

	def.func = function(...)
		local current_mode = ctf_modebase.current_mode

		if current_mode then
			local cmd_func = mode_chatcommands[current_mode][name]

			if cmd_func then
				return cmd_func(...)
			else
				return false, "The current mode hasn't implemented that command!"
			end
		else
			return false, "Can't run mode-specific commands when no mode is running!"
		end
	end

	minetest.register_chatcommand(name, def)
end

minetest.register_chatcommand("ctf_next", {
	description = "Skip to a new match.",
	privs = {ctf_admin = true},
	params = "[<technical modename> | <technical mapname>]",
	func = function(name, param)
		if param then
			if ctf_modebase.modes[param] then
				ctf_modebase.start_new_match(nil, param)
				return true
			elseif table.indexof(minetest.get_dir_list(ctf_map.maps_dir, true), param) ~= -1 then
				ctf_modebase.start_new_match(nil, nil, param)
				return true
			end
		end

		if ctf_modebase.current_mode then
			ctf_modebase.start_new_match()
			return true
		else
			return false, "You need to provide a mode to go to when running this command at server start"
		end
	end,
})

minetest.register_chatcommand("list_bounties", {
	description = "List current bounties",
	func = function(name)
		local pteam = ctf_teams.get(name)
		local output = {}

		for tname, bounty in pairs(ctf_modebase.bounties.bounties) do
			if pteam ~= tname then
				table.insert(output, bounty.msg)
			end
		end

		if #output <= 0 then
			return false, "There are no bounties you can claim"
		end

		return true, table.concat(output, "\n")
	end
})
