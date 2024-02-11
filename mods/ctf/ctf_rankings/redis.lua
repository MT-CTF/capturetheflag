local redis = require("redis")
local client = redis.connect("127.0.0.1", tonumber(minetest.settings:get("ctf_rankings_redis_server_port")) or 6379)
assert(client:ping(), "Redis server not found!")

return function(prefix, top)

local function op_all(operation)
	for _, key in ipairs(client:keys(prefix .. '*')) do
		operation(string.sub(key, #prefix + 1), client:get(key))
	end
end

local timer = minetest.get_us_time()
op_all(function(noprefix_key, value)
	local rank = minetest.parse_json(value)

	if rank ~= nil and rank.score then
		top:set(noprefix_key, rank.score)
	end
end)
minetest.log("action", "Sorted rankings database. Took "..((minetest.get_us_time()-timer) / 1e6))

return {
	backend = "redis",
	top = top,
	prefix = prefix,

	op_all = op_all,

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
	end,
	del = function(self, pname)
		pname = PlayerName(pname)

		self.top:set(pname, 0)
		client:del(self.prefix..pname)
	end
}

end
