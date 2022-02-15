ctf_core = {
	settings = {
		-- server_mode = minetest.settings:get("ctf_server_mode") or "play",
		server_mode = minetest.settings:get_bool("creative_mode", false) and "mapedit" or "play",
	}
}

---@param files table
-- Returns dofile() return values in order that files are given
--
-- Example: local f1, f2 = ctf_core.include_files("file1", "file2")
function ctf_core.include_files(...)
	local PATH = minetest.get_modpath(minetest.get_current_modname()) .. "/"
	local returns = {}

	for _, file in pairs({...}) do
		for _, value in pairs{dofile(PATH .. file)} do
			table.insert(returns, value)
		end
	end

	return unpack(returns)
end

ctf_core.include_files(
	"helpers.lua",
	"privileges.lua",
	"cooldowns.lua"
)
