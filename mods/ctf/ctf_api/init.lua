ctf_api = {}

ctf_api.registered_on_mode_start = {}
ctf_api.registered_on_new_match = {}
ctf_api.registered_on_match_start = {}
ctf_api.registered_on_match_end = {}
ctf_api.registered_on_respawnplayer = {}

---@param func function
function ctf_api.register_on_mode_start(func)
	table.insert(ctf_api.registered_on_mode_start, func)
end

---@param func function
function ctf_api.register_on_new_match(func)
	table.insert(ctf_api.registered_on_new_match, func)
end

---@param func function
function ctf_api.register_on_match_start(func)
	table.insert(ctf_api.registered_on_match_start, func)
end

---@param func function
function ctf_api.register_on_match_end(func)
	table.insert(ctf_api.registered_on_match_end, func)
end

---@param func function
function ctf_api.register_on_respawnplayer(func)
	table.insert(ctf_api.registered_on_respawnplayer, func)
end

