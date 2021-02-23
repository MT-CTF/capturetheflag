local backend = minetest.settings:get("ctf_rankings_backend") or "default"

local rankings
local env

if backend == "redis" then
	env = minetest.request_insecure_environment()
	assert(env, "Please add 'ctf_rankings' to secure.trusted_mods if you want to use the redis backend")

	rankings = env.dofile(env.core.get_modpath(env.core.get_current_modname()).."/redis.lua")
else
	rankings = ctf_core.include_files(backend..".lua")
end

ctf_rankings = {
	init = function()
		if backend == "redis" then
			local old_require = require
			env.rawset(_G, "require", env.require)

			local new = rankings:init_new()

			env.rawset(_G, "require", old_require)

			return new
		else
			return rankings:init_new()
		end
	end,
}
