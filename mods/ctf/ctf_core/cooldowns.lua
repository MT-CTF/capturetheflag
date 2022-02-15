function ctf_core.init_cooldowns()
	return {
		players = {},
		set = function(self, player, time)
			local pname = PlayerName(player)

			if self.players[pname] then
				self.players[pname]:cancel()

				if not time then
					self.players[pname] = nil
					return
				end
			end

			self.players[pname] = minetest.after(time, function() self.players[pname] = nil end)
		end,
		get = function(self, player)
			return self.players[PlayerName(player)]
		end
	}
end
