local theme = [[size[8,8.6]
	bgcolor[#080808BB;true]
	background[5,5;1,1;gui_formbg.png;true]
	{{ nav }}
	listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]
	list[current_player;main;0,4.25;8,1;]
	list[current_player;main;0,5.5;8,3;8] ]]

sfinv = {
	pages = {},
	pages_unordered = {},
	homepage_name = "sfinv:crafting",
	contexts = {}
}

function sfinv.register_page(name, def)
	if not name or not def or not def.get then
		error("Invalid sfinv page. Requires a name & def, and a get function in def")
	end
	sfinv.pages[name] = def
	def.name = name
	table.insert(sfinv.pages_unordered, def)
end

function sfinv.parse_variables(fs, vars)
	local ret = fs
	for key, value in pairs(vars) do
		print("Running " .. key .. "=" .. value .. " on string")
		ret = string.gsub(ret, "{{([ ]+)" .. key .. "([ ]+)}}", value)
	end
	return ret
end

function sfinv.get(player, context)
	local page = sfinv.pages[context.page]
	if not page then
		page = sfinv.pages["404"]
	end
	print(dump(page))

	local fs = page:get(player, context)
	local nav = {}
	local nav_ids = {}
	local current_idx = 1
	for i, pdef in pairs(sfinv.pages_unordered) do
		if not pdef.is_in_nav or pdef.is_in_nav(player, context) then
			nav[#nav + 1] = pdef.title
			nav_ids[#nav_ids + 1] = pdef.name
			if pdef.name == context.page then
				current_idx = i
			end
		end
	end
	context.nav = nav_ids

	print(dump(context))
	print(current_idx)

	local vars = {
		layout = theme,
		name = player:get_player_name(),
		nav = "tabheader[0,0;tabs;" .. table.concat(nav, ",") .. ";" .. current_idx .."]"
	}
	fs = sfinv.parse_variables(fs, vars)
	fs = sfinv.parse_variables(fs, vars)
	return fs
end

function sfinv.set(player, context)
	if not context then
		local name = player:get_player_name()
		context = sfinv.contexts[name]
		if not context then
			context = {
				page = sfinv.homepage_name
			}
			sfinv.contexts[name] = context
		end
	end
	print("Setting " .. context.page)
	local fs = sfinv.get(player, context)
	print(fs)
	player:set_inventory_formspec(fs)

	--[[local tmp = [ [
		size[8,8.6]
		image[4.06,3.4;0.8,0.8;creative_trash_icon.png]
		list[current_player;main;0,4.7;8,1;]
		list[current_player;main;0,5.85;8,3;8]
		list[detached:creative_trash;main;4,3.3;1,1;]
		tablecolumns[color;text;color;text]
		tableoptions[background=#00000000;highlight=#00000000;border=false]
		button[5.4,3.2;0.8,0.9;creative_prev;<]
		button[7.25,3.2;0.8,0.9;creative_next;>]
		button[2.1,3.4;0.8,0.5;search;?]
		button[2.75,3.4;0.8,0.5;clear;X]
		tooltip[search;Search]
		tooltip[clear;Reset]
		listring[current_player;main]
		] ] ..
		"field[0.3,3.5;2.2,1;filter;;".. filter .."]"..
		"listring[detached:creative_".. player_name ..";main]"..
		"tabheader[0,0;tabs;Crafting,All,Nodes,Tools,Items;".. tostring(tab_id) ..";true;false]"..
		"list[detached:creative_".. player_name ..";main;0,0;8,3;".. tostring(start_i) .."]"..
		"table[6.05,3.35;1.15,0.5;pagenum;#FFFF00,".. tostring(pagenum) ..",#FFFFFF,/ ".. tostring(pagemax) .."]"..
		default.get_hotbar_bg(0,4.7)..
		default.gui_bg .. default.gui_bg_img .. default.gui_slots
		]]--
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0.5, function()
		minetest.chat_send_player(player:get_player_name(), "Hello!")
		sfinv.set(player)
	end)
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then
		return false
	end
	print("Received fields! " .. dump(fields))

	-- Get Context
	local name = player:get_player_name()
	local context = sfinv.contexts[name]
	if not context then
		sfinv.set(player)
		return false
	end

	-- Handle Events
	if fields.tabs and context.nav then
		local tid = tonumber(fields.tabs)
		if tid and tid > 0 then
			local id = context.nav[tid]
			if id and sfinv.pages[id] then
				print(name .. " views sfinv/" .. id)

				-- TODO: on_leave
				context.page = id
				sfinv.set(player, context)
			end
		end
		return
	end

	-- Pass to page
	local page = sfinv.pages[context.page]
	if page and page.on_player_receive_fields then
		return page.on_player_receive_fields(player, context, fields)
	end
end)
