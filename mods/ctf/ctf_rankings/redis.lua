local redis = require("redis")
local client = redis.connect("127.0.0.1", tonumber(minetest.settings:get("ctf_rankings_redis_server_port")) or 6379)
assert(client:ping(), "Redis server not found!")

return function(prefix, top, sorting_finished)

-- If callback isn't passed then coroutine will never yield
local function op_all(operation, callback)
	if not callback then
		minetest.log("warning", "op_all() called without callback, it will block the server step until it finishes")
	end

	local interval = 0.2
	local time = minetest.get_us_time()
	local times = 0
	local keys = client:keys(prefix .. '*')
	local c = coroutine.wrap(function()
		for _, key in ipairs(keys) do
			times = times + 1
			operation(string.sub(key, #prefix + 1), client:get(key))

			if callback and ((minetest.get_us_time()-time) / 1e6) >= interval then
				coroutine.yield()
			end
		end

		return "done"
	end)

	local function rep()
		time = minetest.get_us_time()

		if c() ~= "done" then
			minetest.after(0, function() minetest.after(0, rep) end)
		elseif callback then
			assert(times == #keys, dump(#keys - times).." | "..dump(times).." | "..dump(#keys))
			callback()
		end
	end

	rep()
end

local timer = minetest.get_us_time()
op_all(function(noprefix_key, value)
	local rank = minetest.parse_json(value)

	if rank ~= nil and rank.score then
		top:set(noprefix_key, rank.score)
	end
end,
function()
	minetest.log(
		"action",
		"Sorted rankings by score '"..prefix:sub(1, -2).."'. Took "..((minetest.get_us_time()-timer) / 1e6)
	)
	sorting_finished()
end)

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
