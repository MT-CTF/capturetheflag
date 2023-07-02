return function(top)
local modstorage = assert(minetest.get_mod_storage(), "Can only init rankings at runtime!")

for k, v in pairs(modstorage:to_table()["fields"]) do
	local rank = minetest.parse_json(v)
	if rank ~= nil and rank.score then
		top:set(k, rank.score)
	end
end

return {
	backend = "default",
	top = top,
	modstorage = modstorage,

	get = function(self, pname)
		pname = PlayerName(pname)

		local rank_str = self.modstorage:get_string(pname)

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
	end
}
end
