function ctf_core.init_cooldowns()
	return {
		players = {},
		set = function(self, player, time)
			local pname = PlayerName(player)

			if self.players[pname] then
				self.players[pname]._timer:cancel()

				if not time then
					self.players[pname] = nil
					return
				end
			end

			if type(time) ~= "table" then
				time = {_time = time}
			end

			time._timer = minetest.after(time._time, function()
				if time._on_end then
					local copy = table.copy(self.players[pname])

					self.players[pname] = nil
					time._on_end(copy)
				else
					self.players[pname] = nil
				end
			end)

			time.start_time = os.clock()

			self.players[pname] = time
		end,
		get = function(self, player)
			return self.players[PlayerName(player)]
		end
	}
end
