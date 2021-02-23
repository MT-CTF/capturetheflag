function ctf_core.init_cooldowns()
	return {
		players = {},
		start = function(self, player, time)
			local pname = PlayerName(player)

			self.players[pname] = true
			minetest.after(time, function() self.players[pname] = nil end)
		end,
		get = function(self, player)
			return self.players[PlayerName(player)]
		end
	}
end
