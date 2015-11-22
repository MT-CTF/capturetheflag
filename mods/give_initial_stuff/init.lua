function give_initial_stuff(player)
	if minetest.setting_getbool("give_initial_stuff") then
		minetest.log("action", "Giving initial stuff to player "..player:get_player_name())
		local inv = player:get_inventory()
		inv:set_list("main", {})
		inv:set_list("craft", {})
		inv:add_item('main', 'default:pick_wood')
		inv:add_item('main', 'default:sword_wood')
		inv:add_item('main', 'default:torch 3')
	end
end

minetest.register_on_newplayer(give_initial_stuff)
minetest.register_on_respawnplayer(give_initial_stuff)
