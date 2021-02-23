give_initial_stuff = {}

-- Add item to inv. Split item if count > stack_max using recursion
function give_initial_stuff.give_item(inv, item)
	-- Remove any lower tier tools of the same type as the item

	-- Get the 'tier' of the new item
	local newdef = item:get_definition()

	-- Only do tier checks if the new item has a category
	if newdef._g_category then
		for idx, i in ipairs(inv:get_list("main")) do
			local idef = i:get_definition()

			-- Only compare items in the same category
			if idef._g_category == newdef._g_category then
				local tier = idef.groups.tier or 1

				if tier < (newdef.groups.tier or 1) then
					inv:remove_item("main", i) -- Will do nothing if item doesn't exist
				elseif tier >= (newdef.groups.tier or 1) then
					return -- A higher tier item is already in inventory
				end
			end
		end
	end

	-- Don't duplicate stacks
	if inv:contains_item("main", item:get_name()) then
		local safeguard = 0
		local itemcount = item:get_count()-5
		if itemcount < 0 then itemcount = 0 end

		-- Replace stack if it's smaller than what we want to add
		while not inv:contains_item("main", ("%s %d"):format(item:get_name(), itemcount)) do
			safeguard = safeguard + 1

			inv:add_item("main", item:get_name() .. " 5")

			if safeguard >= 500 then
				minetest.log("error", "[give_initial_stuff] Something went wrong when filling stack "..dump(item:get_name()))
				break
			end
		end

		return
	end

	inv:add_item("main", item:take_item(item:get_stack_max()))

	-- If item isn't empty, add the leftovers again
	if not item:is_empty() then
		give_initial_stuff.give_item(inv, item)
	end
end

setmetatable(give_initial_stuff, {
	__call = function(self, player, replace)
		if ctf_core.settings.server_mode == "mapedit" then
			return
		end

		minetest.log("action", "Giving initial stuff to player "
				.. player:get_player_name())
		local inv = player:get_inventory()

		if not replace then
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
