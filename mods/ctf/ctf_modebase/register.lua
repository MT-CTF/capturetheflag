function ctf_modebase.register_mode(name, func)
	ctf_modebase.modes[name] = func
	table.insert(ctf_modebase.modelist, name)
end

ctf_modebase.registered_on_new_match = {}
---@param func function
--- Passed params: `mapdef`, `old_map` (`old_map` may be nil)
function ctf_modebase.register_on_new_match(func, load_first)
	if load_first then
		table.insert(ctf_modebase.registered_on_new_match, 1, func)
	else
		table.insert(ctf_modebase.registered_on_new_match, func)
	end
end

ctf_modebase.registered_on_new_mode = {}
---@param func function
--- Passed params: `new_mode`, `old_mode` (`old_mode` may be false)
function ctf_modebase.register_on_new_mode(func, load_first)
	if load_first then
		table.insert(ctf_modebase.registered_on_new_mode, 1, func)
	else
		table.insert(ctf_modebase.registered_on_new_mode, func)
	end
end
