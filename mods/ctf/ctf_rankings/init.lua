local backend = minetest.settings:get("ctf_rankings_backend") or "default"

local rankings
local top = ctf_core.include_files("top.lua")

if backend == "redis" then
	local env = minetest.request_insecure_environment()
	assert(env, "Please add 'ctf_rankings' to secure.trusted_mods if you want to use the redis backend")

	local old_require = require

	env.rawset(_G, "require", env.require)
	rankings = env.dofile(env.core.get_modpath(env.core.get_current_modname()).."/redis.lua")
	env.rawset(_G, "require", old_require)
else
	rankings = ctf_core.include_files(backend..".lua")
end

ctf_rankings = {
	init = function()
		return rankings(top:new())
	end,
}
