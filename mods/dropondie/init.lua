local drop = function(pos, itemstack)

	local it = itemstack:take_item(itemstack:get_count())
	local obj = core.add_item(pos, it)

	if obj then

	obj:setvelocity({x=math.random(-1,1), y=5, z=math.random(-1,1)})

	local remi = minetest.setting_get("remove_items")

	if remi and remi == "true" then
		obj:remove()
	end

	end
	return itemstack
end

minetest.register_on_dieplayer(function(player)

	if minetest.setting_getbool("creative_mode") then
		return
	end

	local pos = player:getpos()
	pos.y = math.floor(pos.y + 0.5)

	minetest.chat_send_player(player:get_player_name(), 'at '..math.floor(pos.x)..','..math.floor(pos.y)..','..math.floor(pos.z))

	local player_inv = player:get_inventory()

	for i=1,player_inv:get_size("main") do
		drop(pos, player_inv:get_stack("main", i))
		player_inv:set_stack("main", i, nil)
	end

	for i=1,player_inv:get_size("craft") do
		drop(pos, player_inv:get_stack("craft", i))
		player_inv:set_stack("craft", i, nil)
	end

end)
