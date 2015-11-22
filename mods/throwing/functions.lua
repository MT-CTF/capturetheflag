--~ 
--~ Shot and reload system
--~ 

local players = {}

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = {
		reloading=false,
	}
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)

function throwing_shoot_arrow (itemstack, player, stiffness, is_cross)
	if not player then
		return
	end
	local arrow = itemstack:get_metadata()
	itemstack:set_metadata("")
	player:set_wielded_item(itemstack)
	local playerpos = player:getpos()
	print(dump(minetest.luaentities))
	local obj = minetest.add_entity({x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, arrow)
	if not obj then
		minetest.chat_send_player(player:get_player_name(), "Error! Failed to create arrow.")
	end
	print(dump(minetest.luaentities))
	local dir = player:get_look_dir()
	obj:setvelocity({x=dir.x*stiffness, y=dir.y*stiffness, z=dir.z*stiffness})
	obj:setacceleration({x=dir.x*-3, y=-8.5, z=dir.z*-3})
	obj:setyaw(player:get_look_yaw()+math.pi)
	if is_cross then
		minetest.sound_play("throwing_crossbow_sound", {pos=playerpos})
	else
		minetest.sound_play("throwing_bow_sound", {pos=playerpos})
	end
	local le = obj:get_luaentity()
	if le then
		le.player = player
		le.inventory = player:get_inventory()
		le.stack = player:get_inventory():get_stack("main", player:get_wield_index()-1)
		print("le")
	else
		print("no le")
	end
	return true
end

function throwing_unload (itemstack, player, unloaded, wear)
	if itemstack:get_metadata() then
		for _,arrow in ipairs(throwing_arrows) do
			if itemstack:get_metadata() == arrow[2] then
				if not minetest.setting_getbool("creative_mode") then
					player:get_inventory():add_item("main", arrow[1])
				end
			end
		end
	end
	if wear >= 65535 then
		player:set_wielded_item({})
	else
		player:set_wielded_item({name=unloaded, wear=wear})
	end
end

function throwing_reload (itemstack, player, pos, is_cross, loaded)
	local playerName = player:get_player_name()
	players[playerName]['reloading'] = false
	if itemstack:get_name() == player:get_wielded_item():get_name() then
		if (pos.x == player:getpos().x and pos.y == player:getpos().y and pos.z == player:getpos().z) or not is_cross then
			local wear = itemstack:get_wear()
			for _,arrow in ipairs(throwing_arrows) do
				if player:get_inventory():get_stack("main", player:get_wield_index()+1):get_name() == arrow[1] then
					if not minetest.setting_getbool("creative_mode") then
						player:get_inventory():remove_item("main", arrow[1])
					end
					local meta = arrow[2]
					player:set_wielded_item({name=loaded, wear=wear, metadata=meta})
				end
			end
		end
	end
end

-- Bows and crossbows

function throwing_register_bow (name, desc, scale, stiffness, reload_time, toughness, is_cross, craft)
	minetest.register_tool("throwing:" .. name, {
		description = desc,
		inventory_image = "throwing_" .. name .. ".png",
		wield_scale = scale,
	    stack_max = 1,	
		on_use = function(itemstack, user, pointed_thing)
			local pos = user:getpos()
			local playerName = user:get_player_name()
			if not players[playerName]['reloading'] then
				players[playerName]['reloading'] = true
				minetest.after(reload_time, throwing_reload, itemstack, user, pos, is_cross, "throwing:" .. name .. "_loaded")
			end
			return itemstack
		end,
	})
	
	minetest.register_tool("throwing:" .. name .. "_loaded", {
		description = desc,
		inventory_image = "throwing_" .. name .. "_loaded.png",
		wield_scale = scale,
	    stack_max = 1,
		on_use = function(itemstack, user, pointed_thing)
			local wear = itemstack:get_wear()
			if not minetest.setting_getbool("creative_mode") then
				wear = wear + (65535/toughness)
			end
			local unloaded = "throwing:" .. name
			throwing_shoot_arrow(itemstack, user, stiffness, is_cross)
			minetest.after(0, throwing_unload, itemstack, user, unloaded, wear)				
			return itemstack
		end,
		on_drop = function(itemstack, dropper, pointed_thing)
			local wear = itemstack:get_wear()
			local unloaded = "throwing:" .. name
			minetest.after(0, throwing_unload, itemstack, dropper, unloaded, wear)
		end,
		groups = {not_in_creative_inventory=1},
	})
	
	minetest.register_craft({
		output = 'throwing:' .. name,
		recipe = craft
	})

	minetest.register_craft({
		output = 'throwing:' .. name,
		recipe = {
			{craft[1][3], craft[1][2], craft[1][1]},
			{craft[2][3], craft[2][2], craft[2][1]},
			{craft[3][3], craft[3][2], craft[3][1]},
		}
	})
end
