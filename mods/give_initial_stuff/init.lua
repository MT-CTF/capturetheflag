function give_initial_stuff(player)
	if minetest.setting_getbool("give_initial_stuff") then
		minetest.log("action", "Giving initial stuff to player "..player:get_player_name())
		player:get_inventory():add_item('main', 'default:pick_wood')
		player:get_inventory():add_item('main', 'default:sword_wood')
		player:get_inventory():add_item('main', 'default:torch 3')
	end
end

minetest.register_on_newplayer(give_initial_stuff)
