select_item = {}

local S = core.get_translator("select_item")

-- Cache for result of item filters
local player_filters = {}
local player_filter_results = {}
local player_compares = {}
local player_maxpage = {}

local reset_player_info = function(playername)
	player_filters[playername] = nil
	player_filter_results[playername] = nil
	player_compares[playername] = nil
	player_maxpage[playername] = nil
end

-- Predefined filters
select_item.filters = {}

-- Filters out all items not for the Creative Inventory.
-- This elimininates all items reserved for internal use.
select_item.filters.creative = function(itemstring)
	local itemdef = core.registered_items[itemstring]
	if itemstring == "air" then
		return false
	end
	if itemdef.description == nil or itemdef.description == "" then
		return false
	end
	if core.get_item_group(itemstring, "not_in_creative_inventory") == 1 then
		return false
	end
	return true
end

-- No filtering
select_item.filters.all = function()
	return true
end

local check_item = function(itemstring, filter)
	local itemdef = core.registered_items[itemstring]
	if itemstring == "" or itemstring == "unknown" or itemstring == "ignore" or itemdef == nil then
		return
	end
	if type(filter) == "function" then
		if filter(itemstring) ~= true then
			return false
		end
	end

	return true
end

local get_items = function(filter, compare)
	local it = {}
	for itemstring, itemdef in pairs(core.registered_items) do
		if check_item(itemstring, filter) then
			table.insert(it, {itemstring=itemstring, itemdef=itemdef})
		end
	end
	local internal_compare
	if not compare then
		-- Default sorting: Move description-less items and
		-- items not_in_creative_inventory=1 to the end, then sort by itemstring.
		internal_compare = function(t1, t2)
			local t1d = core.registered_items[t1.itemstring].description
			local t2d = core.registered_items[t2.itemstring].description
			local t1g = core.get_item_group(t1.itemstring, "not_in_creative_inventory")
			local t2g = core.get_item_group(t2.itemstring, "not_in_creative_inventory")
			if (t1d == "" and t2d ~= "") then
				return false
			elseif (t1d ~= "" and t2d == "") then
				return true
			end
			if (t1g == 1 and t2g == 0) then
				return false
			elseif (t1g == 0 and t2g == 1) then
				return true
			end
			return t1.itemstring < t2.itemstring
		end
	else
		internal_compare = function(t1, t2)
			return compare(t1.itemstring, t2.itemstring)
		end
	end
	table.sort(it, internal_compare)
	return it
end

local xsize_norm = 12
local ysize_norm = 9

-- Opens the item selection dialog for player with the given filter function at page.
-- The dialog has unique identifier dialogname.
-- Returns: Number of items it displays.
local show_dialog_page = function(playername, dialogname, filter, compare, page)
	local items
	if player_filters[playername] == nil then
		player_filters[playername] = filter
		player_compares[playername] = compare
		items = get_items(filter, compare)
		player_filter_results[playername] = items
	end
	items = player_filter_results[playername]
	local xsize, ysize, total_pages
	if #items < xsize_norm * ysize_norm then
		xsize = xsize_norm
		ysize = math.ceil(#items / xsize)
		total_pages = 1
	else
		xsize = xsize_norm
		ysize = ysize_norm
		total_pages = math.ceil(#items / (xsize * ysize))
	end
	local bg = ""
	-- Legacy default formspec background (MT<=0.4.17)
	if core.get_modpath("default") and default.gui_bg then
		bg = default.gui_bg .. default.gui_bg_img .. default.gui_slots
	end
	if #items == 0 then
		local form = "size[6,2]"..
				bg ..
				"label[0,0;"..core.formspec_escape(S("There are no items to choose from.")).."]"..
				"button_exit[0,1;2,1;cancel;"..core.formspec_escape(S("There are no items to choose from.")).."]"
		core.show_formspec(playername, "select_item:page1", form)
		return #items
	end
	local form = "size["..xsize..","..(ysize+1).."]" .. bg
	local x = 0
	local y = 0.5
	if page == nil then page = 1 end
	local start = 1 + (page-1) * xsize * ysize
	player_maxpage[playername] = total_pages
	form = form .. "label[0,0;"..core.formspec_escape(S("Select an item:")).."]"
	for i=start, #items do
		local itemstring = items[i].itemstring
		local itemdef = items[i].itemdef
		local name = "item_"..itemstring
		form = form .. "item_image_button["..x..","..y..";1,1;"..itemstring..";"..name..";]"
		if itemdef.description == nil or itemdef.description == "" then
			form = form .. "tooltip["..name..";"..itemstring.."]"
		end

		x = x + 1
		if x >= xsize then
			x = 0
			y = y + 1
			if y >= ysize then
				break
			end
		end
	end
	local ynav = (ysize + 0.5)
	if total_pages > 1 then
		form = form .. "button[0,"..ynav..";1,1;previous;<]"
		form = form .. "button[1,"..ynav..";1,1;next;>]"
		form = form .. "label[2,"..ynav..";"..core.formspec_escape(S("Page @1/@2", page, total_pages)).."]"
	end
	form = form .. "button_exit["..(xsize-2)..","..ynav..";2,1;cancel;"..core.formspec_escape(S("Cancel")).."]"
	core.show_formspec(playername, "select_item:page"..page.."%%"..dialogname, form)
	return #items
end

select_item.show_dialog = function(playername, dialogname, filter, compare)
	show_dialog_page(playername, dialogname, filter, compare, 1)
end

local callbacks = {}
select_item.register_on_select_item = function(callback)
	table.insert(callbacks, callback)
end

core.register_on_player_receive_fields(function(player, formname, fields)
	local playername = player:get_player_name()
	if string.sub(formname, 1, 16) == "select_item:page" then
		-- Parse formname
		local rest = string.sub(formname, 17, string.len(formname))
		local split = string.split(rest, "%%", true, 2)
		local page = tonumber(split[1])
		local dialogname = split[2]

		local item
		for field,_ in pairs(fields) do
			if string.sub(field, 1, 5) == "item_" then
				item = string.sub(field, 6, string.len(field))
				break
			end
		end
		if item or fields.quit then
			local close = true
			for i=1,#callbacks do
				local ret = callbacks[i](playername, dialogname, item)
				if ret == false then
					close = false
				end
			end
			if close then
				core.close_formspec(playername, formname)
			end
			reset_player_info(playername)
		end
		if fields.quit or fields.cancel then
			reset_player_info(playername)
		end
		if page ~= nil then
			if fields.previous and page > 1 then
				show_dialog_page(player:get_player_name(), dialogname, player_filters[playername], player_compares[playername], page - 1)
			elseif fields.next then
				local maxpage = player_maxpage[playername]
				if maxpage and (page + 1 <= maxpage) then
					show_dialog_page(playername, dialogname, player_filters[playername], player_compares[playername], page + 1)
				end
				if not maxpage then
					core.log("warning", "[select_item] Player "..playername.." managed to navigate select_item menu without maxpage set!")
				end
			end
		end
	end
end)

core.register_on_leaveplayer(function(player)
	reset_player_info(player:get_player_name())
end)
