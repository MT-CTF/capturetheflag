local function get_item_description(name)
	if name:sub(1, 6) == "group:" then
		local group = name:sub(7, #name):gsub("%_", " ")
		return "Any " .. group
	else
		local def = minetest.registered_items[name] or {}
		return def.description or name
	end
end

function crafting.make_result_selector(player, size, context)
	local table_insert = table.insert

	local page = context.crafting_page or 1

	local full_recipes = crafting.get_all_for_player(player)
	local recipes
	if context.crafting_query then
		recipes = {}

		for i = 1, #full_recipes do
			local output = full_recipes[i].recipe.output
			local desc   = get_item_description(output):lower()
			if string.find(output, context.crafting_query, 1, true)
				or string.find(desc, context.crafting_query, 1, true) then
				table_insert(recipes, full_recipes[i])
			end
		end
	else
		recipes = full_recipes
	end

	local num_per_page = size.x * size.y

	local max_pages = 1
	if #recipes > 0 then
		max_pages = math.floor((#recipes + num_per_page - 1) / num_per_page)
	end

	if page > max_pages or page < 1 then
		page = ((page - 1) % max_pages) + 1
		context.crafting_page = page
	end

	local start_i  = (page - 1) * num_per_page + 1

	local formspec = {}

	table_insert(formspec, "container[")
	table_insert(formspec, tostring(size.x))
	table_insert(formspec, ",")
	table_insert(formspec, tostring(size.y))
	table_insert(formspec, "]")

	table_insert(formspec, "style_type[item_image_button;border=false]")

	table_insert(formspec, "field_close_on_enter[query;false]")
	table_insert(formspec, "field[-4.75,0.81;3,0.8;query;;")
	table_insert(formspec, context.crafting_query)
	table_insert(formspec, "]button[-2.2,0.5;0.8,0.8;search;?]")
	table_insert(formspec, "button[-1.4,0.5;0.8,0.8;prev;<]")
	table_insert(formspec, "button[-0.8,0.5;0.8,0.8;next;>]")

	table_insert(formspec, "container_end[]")

	table_insert(formspec, "label[0,-0.25;")
	table_insert(formspec, minetest.formspec_escape(
		"Page: " .. page .. "/" .. max_pages)
	)
	table_insert(formspec, "]")

	local x = 0
	local y = 0
	local y_offset = 0.2
	for i = start_i, math.min(#recipes, start_i * num_per_page)  do
		local result = recipes[i]
		local recipe = result.recipe

		local itemname = ItemStack(recipe.output):get_name()
		local item_description = get_item_description(itemname)

		table_insert(formspec, "item_image_button[")
		table_insert(formspec, x)
		table_insert(formspec, ",")
		table_insert(formspec, y + y_offset)
		table_insert(formspec, ";1,1;")
		table_insert(formspec, recipe.output)
		table_insert(formspec, ";result_")
		table_insert(formspec, tostring(recipe.id))
		table_insert(formspec, ";]")

		table_insert(formspec, "tooltip[result_")
		table_insert(formspec, tostring(recipe.id))
		table_insert(formspec, ";")
		table_insert(formspec, minetest.formspec_escape(item_description .. "\n"))
		for _, item in ipairs(result.items) do
			local color = item.have >= item.need and "#6f6" or "#f66"
			local itemtab = {
				"\n",
				minetest.get_color_escape_sequence(color),
				get_item_description(item.name), ": ",
				item.have, "/", item.need
			}
			table_insert(formspec, minetest.formspec_escape(table.concat(itemtab, "")))
		end
		table_insert(formspec, minetest.get_color_escape_sequence("#ffffff"))
		table_insert(formspec, "]")

		table_insert(formspec, "image[")
		table_insert(formspec, x)
		table_insert(formspec, ",")
		table_insert(formspec, y + y_offset)
		if result.craftable then
			table_insert(formspec, ";1,1;crafting_slot_craftable.png]")
		else
			table_insert(formspec, ";1,1;crafting_slot_uncraftable.png]")
		end

		x = x + 1
		if x == size.x then
			x = 0
			y = y + 1
		end
		if y == size.y then
			break
		end
	end

	while y < size.y do
		while x < size.x do
			table_insert(formspec, "image[")
			table_insert(formspec, tostring(x))
			table_insert(formspec, ",")
			table_insert(formspec, tostring(y + y_offset))
			table_insert(formspec, ";1,1;crafting_slot_empty.png]")

			x = x + 1
		end
		x = 0
		y = y + 1
	end

	return table.concat(formspec, "")
end

function crafting.result_select_on_receive_results(player, context, fields)
	if fields.prev then
		context.crafting_page = (context.crafting_page or 1) - 1
		return true
	elseif fields.next then
		context.crafting_page = (context.crafting_page or 1) + 1
		return true
	elseif fields.search or fields.key_enter_field == "query" then
		context.crafting_query = fields.query:trim():lower()
		context.crafting_page  = 1
		if context.crafting_query == "" then
			context.crafting_query = nil
		end
		return true
	end

	for key, value in pairs(fields) do
		if key:sub(1, 7) == "result_" then
			local num = string.match(key, "result_([0-9]+)")
			if num then
				local recipe = crafting.get_recipe(tonumber(num))
				local name   = player:get_player_name()
				if not crafting.can_craft(name, recipe) then
					minetest.log("error", "[crafting] Player clicked a button they shouldn't have been able to")
					return true
				elseif crafting.perform_craft(player, "main", "main", recipe) then
					return true -- crafted
				else
					minetest.chat_send_player(name, "Missing required items!")
					return false
				end
			end
		end
	end
end

if minetest.global_exists("sfinv") then
	local player_inv_hashes = {}

	local trash = minetest.create_detached_inventory("crafting_trash", {
		-- Allow the stack to be placed and remove it in on_put()
		-- This allows the creative inventory to restore the stack
		allow_put = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,
		on_put = function(inv, listname)
			inv:set_list(listname, {})
		end,
	})
	trash:set_size("main", 1)

	sfinv.override_page("sfinv:crafting", {
		get = function(self, player, context)
			player_inv_hashes[player:get_player_name()] =
				crafting.calc_inventory_list_hash(player:get_inventory(), "main")

			local formspec = crafting.make_result_selector(player, { x = 8, y = 3 }, context)
			formspec = formspec .. "list[detached:crafting_trash;main;0,3.4;1,1;]" ..
				"image[0.05,3.5;0.8,0.8;crafting_trash_icon.png]" ..
				"image_button[1,3.4;1,1;crafting_save_icon.png;save_inv_order;]" ..
				"tooltip[save_inv_order;Saves the order of the items in your inventory" ..
					"\n(Your saved order is used when you respawn, and is per-mode)]"

			return sfinv.make_formspec(player, context, formspec, true)
		end,
		on_player_receive_fields = function(self, player, context, fields)
			if crafting.result_select_on_receive_results(player, context, fields) then
				sfinv.set_player_inventory_formspec(player)
			end

			if fields.save_inv_order then
				ctf_modebase.player.save_initial_stuff_positions(player)

				minetest.sound_play("crafting_save_sound", {
					to_player = player:get_player_name(),
				}, true)
			end

			return true
		end
	})

	local globalstep_timer = 0
	minetest.register_globalstep(function(dtime)
		globalstep_timer = globalstep_timer + dtime
		if globalstep_timer < 1 then return end

		globalstep_timer = 0

		for _, player in pairs(minetest.get_connected_players() or {}) do
			if sfinv.get_or_create_context(player).page == "sfinv:crafting" then
				local hash = crafting.calc_inventory_list_hash(player:get_inventory(), "main")
				local old_hash = player_inv_hashes[player:get_player_name()]
				if hash ~= old_hash then
					sfinv.set_page(player, "sfinv:crafting")
				end
			end
		end
	end)
end
