function hudkit()
	return {
		players = {},

		add = function(self, player, id, def)
			local name     = player:get_player_name()
			local elements = self.players[name]

			if not elements then
				self.players[name] = {}
				elements = self.players[name]
			end

			elements[id] = {
				id = player:hud_add(def),
				def = def
			}
			return true
		end,

		exists = function(self, player, id)
			if not player then
				return false
			end

			local name     = player:get_player_name()
			local elements = self.players[name]

			if not elements or not elements[id] then
				return false
			end
			return true
		end,

		change = function(self, player, id, stat, value)
			if not player then
				return false
			end

			local name     = player:get_player_name()
			local elements = self.players[name]

			if not elements or not elements[id] or not elements[id].id then
				return false
			end

			if elements[id].def[stat] ~= value then
				elements[id].def[stat] = value
				player:hud_change(elements[id].id, stat, value)
			end
			return true
		end,

		remove = function(self, player, id)
			local name     = player:get_player_name()
			local elements = self.players[name]

			if not elements or not elements[id] or not elements[id].id then
				return false
			end

			player:hud_remove(elements[id].id)
			elements[id] = nil
			return true
		end
	}
end
