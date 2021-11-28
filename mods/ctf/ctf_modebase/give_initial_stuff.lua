give_initial_stuff = {}

-- Add item to inv.
function give_initial_stuff.give_item(inv, new_item)
	local list = inv:get_list("main")
	local new_count = new_item:get_count()
	local new_def = new_item:get_definition()

	for idx, item in ipairs(list) do
		local item_def = item:get_definition()

		if item:get_name() == new_item:get_name() then
			local item_count = item:get_count()
			local space = item:get_free_space()

			new_count = new_count - item_count -- <item_count> of the new item was already added

			if space >= new_count then -- We can fully add the item
				item:set_count(item_count + new_count)

				inv:set_stack("main", idx, item)
				return
			else -- We can't fully add to it, but we can fill this stack up to max and move on
				item:set_count(item:get_stack_max())
				new_item:set_count(new_count - space)
				new_count = new_count - space

				inv:set_stack("main", idx, item)
			end
		elseif new_def._g_category and new_def._g_category == item_def._g_category then
			if (new_def.groups.tier or 0) >= (item_def.groups.tier or 0) then -- Replace the lower tier item
				inv:set_stack("main", idx, new_item)
				return
			else -- A higher tier item already exists
				return
			end
		end
	end

	inv:add_item("main", new_item:take_item(new_item:get_stack_max()))
end

setmetatable(give_initial_stuff, {
	__call = function(self, player, dont_replace)
		if ctf_core.settings.server_mode == "mapedit" then
			return
		end

		minetest.log("action", "Giving initial stuff to player "
				.. player:get_player_name())
		local inv = player:get_inventory()

		if not dont_replace then
			inv:set_list("main",  {})
			inv:set_list("craft", {})

			inv:set_size("craft", 1)
			inv:set_size("craftresult", 0)
			inv:set_size("hand", 0)
		end

		local items = give_initial_stuff.get_stuff(player)

		for _, item in pairs(items) do
			give_initial_stuff.give_item(inv, ItemStack(item))
		end
	end
})

local registered_stuff_providers = {}
function give_initial_stuff.register_stuff_provider(func, priority)
	table.insert(registered_stuff_providers,
		priority or (#registered_stuff_providers + 1),
		func)
end

function give_initial_stuff.reset_stuff_providers()
	registered_stuff_providers = {}
end

function give_initial_stuff.get_stuff(player)
	local seen_stuff = {}

	local stuff = {}
	for i=1, #registered_stuff_providers do
		local new_stuff = registered_stuff_providers[i](player)
		assert(new_stuff)

		for j=1, #new_stuff do
			local name = ItemStack(new_stuff[j]):get_name()
			if not seen_stuff[name] then
				seen_stuff[name] = true
				stuff[#stuff + 1] = new_stuff[j]
			end
		end
	end
	return stuff
end
