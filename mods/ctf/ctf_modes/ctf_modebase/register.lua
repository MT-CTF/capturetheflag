function ctf_modebase.register_mode(name, func)
	ctf_modebase.modes[name] = func
	table.insert(ctf_modebase.modelist, name)
end

ctf_modebase.registered_on_flag_take = {}
-- Flag take will be cancelled if you return a a string.
-- String will be used for the cancel reason sent to the player
---@param func function
---@param load_first bool
-- Passed params: `playername`, flagteam
function ctf_modebase.register_on_flag_take(func, load_first)
	if load_first then
		table.insert(ctf_modebase.registered_on_flag_take, 1, func)
	else
		table.insert(ctf_modebase.registered_on_flag_take, func)
	end
end

ctf_modebase.registered_on_flag_drop = {}
---@param func function
---@param load_first bool
-- Passed params: `playername`, `flagteam`
function ctf_modebase.register_on_flag_drop(func, load_first)
	if load_first then
		table.insert(ctf_modebase.registered_on_flag_drop, 1, func)
	else
		table.insert(ctf_modebase.registered_on_flag_drop, func)
	end
end

ctf_modebase.registered_on_flag_capture = {}
---@param func function
---@param load_first bool
-- Passed params: `playername`, `captured_flag`
function ctf_modebase.register_on_flag_capture(func, load_first)
	if load_first then
		table.insert(ctf_modebase.registered_on_flag_capture, 1, func)
	else
		table.insert(ctf_modebase.registered_on_flag_capture, func)
	end
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

ctf_modebase.registered_on_treasurefy_node = {}
---@param func function
--- Passed params: Same as node `on_rightclick`
function ctf_modebase.register_on_treasurefy_node(func, load_first)
	if load_first then
		table.insert(ctf_modebase.registered_on_treasurefy_node, 1, func)
	else
		table.insert(ctf_modebase.registered_on_treasurefy_node, func)
	end
end

ctf_modebase.registered_on_flag_rightclick = {}
function ctf_modebase.register_on_flag_rightclick(func, load_first)
	if load_first then
		table.insert(ctf_modebase.registered_on_flag_rightclick, 1, func)
	else
		table.insert(ctf_modebase.registered_on_flag_rightclick, func)
	end
end
