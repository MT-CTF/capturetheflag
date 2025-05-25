core.register_on_joinplayer(function(player)
	player:set_properties({glow = 3})
end)

local MIN_GLOW = 8

core.register_on_mods_loaded(function()
	local itemdef = core.registered_entities["__builtin:item"]
	local old_set_item = itemdef.set_item

	itemdef.set_item = function(self, itemstring)
		old_set_item(self, itemstring)
		local iname = itemstring or self.itemstring
		iname = ItemStack(iname):get_name()

		if not core.registered_items[iname] or (core.registered_items[iname].light_source or 0) < MIN_GLOW then
			self.object:set_properties({glow = MIN_GLOW})
		else
			self.object:set_properties({glow = core.registered_items[iname].light_source})
		end
	end

	core.register_entity(":__builtin:item", itemdef)
end)
