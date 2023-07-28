return function(prefix, top)

local modstorage = assert(minetest.get_mod_storage(), "Can only init rankings at runtime!")

local function op_all(operation)
	minetest.log(dump(modstorage:to_table()))
	for k, v in pairs(modstorage:to_table()["fields"]) do
		operation(k, v)
	end
end

local timer = minetest.get_us_time()
op_all(function(key, value)
	local rank = minetest.parse_json(value)

	if rank ~= nil and rank.score then
		top:set(key, rank.score)
	end
end)
minetest.log("action", "Sorted rankings database. Took "..((minetest.get_us_time()-timer) / 1e6))

return {
	backend = "default",
	top = top,
	modstorage = modstorage,

	prefix = "",

	op_all = op_all,

	get = function(self, pname)
		pname = PlayerName(pname)

		local rank_str = self.modstorage:get_string(pname)

		if not rank_str or rank_str == "" then
			return false
		end

		minetest.log(dump(pname))

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
		self.modstorage:set_string(pname, minetest.write_json(newrankings))
	end,
	add = function(self, pname, amounts)
		pname = PlayerName(pname)

		local newrankings = self:get(pname) or {}

		for k, v in pairs(amounts) do
			newrankings[k] = (newrankings[k] or 0) + v
		end

		self.top:set(pname, newrankings.score or 0)
		self.modstorage:set_string(pname, minetest.write_json(newrankings))
	end,
	del = function(self, pname)
		pname = PlayerName(pname)

		self.top:set(pname, 0)
		self.modstorage:set_string(pname)
	end,
}

end
