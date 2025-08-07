local redis = require("redis")
local client = redis.connect("127.0.0.1", tonumber(minetest.settings:get("ctf_rankings_redis_server_port")) or 6379)
assert(client:ping(), "Redis server not found!")

local CHUNKING_TIMER = 30

return function(prefix, ranklist)
	local DB_VERSION = client:get(prefix .. ":db_version") or 1

	if DB_VERSION == 1 then
		local tmp = {}
		local keys = client:keys(prefix .. "*")
		for _, key in pairs(keys) do
			if not key:find(prefix..":") then
				tmp[key] = client:get(key)
				client:del(key)
			end
		end

		for key, val in pairs(tmp) do
			local pname = string.sub(key, #prefix + 1)
			local rankings = minetest.parse_json(val)

			if rankings then
				for k, v in pairs(rankings) do
					client:zadd(prefix..k, v, pname)
				end
			end
		end

		client:set(prefix .. ":db_version", DB_VERSION+1)
	end

local function op_all(operation, callback)
	assert(false, "op_all is not yet reworked")
end

return {
	backend = "redis",
	prefix = prefix,

	op_all = op_all,

	gtcache = nil,
	get_top = function(self, rend, sortby, rstart, bypass_cache)
		assert(not bypass_cache, "bypass_cache does not account for the :add() cache, please ask for this to be implemented")

		if type(rstart) == "number" then
			rstart = rstart - 1
		end

		if not self.gtcache or bypass_cache then
			self.gtcache = client:zrevrange(self.prefix..sortby, rstart or 0, rend-1, {withscores = true})

			if self.gtcache then
				minetest.after(CHUNKING_TIMER, function()
					self.gtcache = nil
				end)
			end
		end

		return table.copy(self.gtcache)
	end,

	gpcache = {},
	get_place = function(self, pname, sortby, bypass_cache)
		pname = PlayerName(pname)

		assert(not bypass_cache, "bypass_cache does not account for the :add() cache, please ask for this to be implemented")

		local out
		if not self.gpcache[pname] or bypass_cache then
			out = client:zrevrank(self.prefix..sortby, pname)

			if out then
				out = out + 1 -- first place is index 0, correct that
				self.gpcache[pname] = out

				minetest.after(CHUNKING_TIMER, function()
					self.gpcache[pname] = nil
				end)
			end
		else
			out = self.gpcache[pname]
		end

		return out
	end,

	gcache = {},
	get = function(self, pname, bypass_cache)
		pname = PlayerName(pname)

		assert(not bypass_cache, "bypass_cache does not account for the :add() cache, please ask for this to be implemented")

		local rank = {}
		local has_nonzero = false

		if self.gcache[pname] == nil or bypass_cache then
			for _, rankkey in ipairs(ranklist) do
				local val = client:zscore(self.prefix..rankkey, pname)

				if val ~= nil then
					has_nonzero = true
				end

				rank[rankkey] = tonumber(val or 0)
			end

			if has_nonzero then
				self.gcache[pname] = rank
			else
				self.gcache[pname] = false
				rank = false
			end

			minetest.after(CHUNKING_TIMER, function()
				self.gcache[pname] = nil
			end)
		else
			rank = (type(self.gcache[pname]) == "table") and table.copy(self.gcache[pname]) or self.gcache[pname]
		end

		return rank
	end,
	set = function(self, pname, newrankings, erase_unset)
		pname = PlayerName(pname)

		if erase_unset then
			for _, rankkey in ipairs(ranklist) do
				client:zrem(self.prefix..rankkey, pname)
			end
		end

		for rank, val in pairs(newrankings) do
			val = tonumber(val)

			if type(val) == "number" and val == val then
				client:zadd(self.prefix..rank, val, pname)
			end
		end
	end,

	acache = {},
	add = function(self, pname, amounts)
		pname = PlayerName(pname)

		if not self.acache[pname] then
			self.acache[pname] = {}

			minetest.after(CHUNKING_TIMER, function()
				for rank, val in pairs(self.acache[pname]) do
					if type(val) == "number" and val == val then
						client:zincrby(self.prefix..rank, val, pname)
					end
				end

				self.acache[pname] = nil
			end)
		end

		for r, v in pairs(amounts) do
			self.acache[pname][r] = (self.acache[pname][r] or 0) + tonumber(v)
		end
	end,
	del = function(self, pname)
		pname = PlayerName(pname)

		for _, rankkey in ipairs(ranklist) do
			client:zrem(self.prefix..rankkey, pname)
		end
	end,
	__flushdb = function()
		client:flushdb()
	end
}

end
