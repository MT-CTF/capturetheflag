local redis = require("redis")
local client = redis.connect("127.0.0.1", tonumber(minetest.settings:get("ctf_rankings_redis_server_port")) or 6379)
assert(client:ping(), "Redis server not found!")

return function(top)

local prefix = minetest.get_current_modname() .. '|'

for _, key in ipairs(client:keys(prefix .. '*')) do
	local value = client:get(key)
	local pname = string.sub(key, #prefix + 1)
	local rank = minetest.parse_json(value)
	if rank.score then
		top:set(pname, rank.score)
	end
end

return {
	backend = "redis",
	top = top,
	prefix = prefix,

	get = function(self, pname)
		pname = PlayerName(pname)

		local rank_str = client:get(self.prefix .. pname)

		if not rank_str or rank_str == "" then
			return false
		end

		return minetest.parse_json(rank_str)
	end,
	set = function(self, pname, newrankings, erase_unset)
		pname = PlayerName(pname)

		if not erase_unset then
			local rank = self:get(pname)
			if rank then
				for k, v in pairs(newrankings) do
					rank[k] = v
				end

				newrankings = rank
			end
		end

		self.top:set(pname, newrankings.score or 0)
		client:set(self.prefix .. pname, minetest.write_json(newrankings))
	end,
	add = function(self, pname, amounts)
		pname = PlayerName(pname)

		local newrankings = self:get(pname) or {}

		for k, v in pairs(amounts) do
			newrankings[k] = (newrankings[k] or 0) + v
		end

		self.top:set(pname, newrankings.score or 0)
		client:set(self.prefix .. pname, minetest.write_json(newrankings))
	end
}

end
