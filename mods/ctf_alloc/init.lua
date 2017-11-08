local storage = minetest.get_mod_storage()
local data = minetest.parse_json(storage:get_string("locktoteam")) or {}

local ctf_autoalloc = ctf.autoalloc
function ctf.autoalloc(name, alloc_mode)
	if data[name] then
		return data[name]
	end

	return ctf_autoalloc(name, alloc_mode)
end

ChatCmdBuilder.new("ctf_lockpt", function(cmd)
	cmd:sub(":name :team", function(name, pname, team)
		if team == "!" then
			data[pname] = nil
			storage:set_string("locktoteam", minetest.write_json(data))
			return true, "Unlocked " .. pname
		else
			data[pname] = team
			storage:set_string("locktoteam", minetest.write_json(data))
			return true, "Locked " .. pname .. " to " .. team
		end
	end)
end, {
	description = "Lock a player to a team",
	privs = {
		ctf_admin = true,
	}
})
