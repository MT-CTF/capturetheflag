give_initial_stuff = {}

setmetatable(give_initial_stuff, {
	__call = function(self, player)
		minetest.log("action", "Giving initial stuff to player "..player:get_player_name())
		local inv = player:get_inventory()
		inv:set_list("main",  {})
		inv:set_list("craft", {})
		inv:set_list("craftresult", {})
		inv:set_list("hand", {})

		local items = give_initial_stuff.get_stuff()

		for _, item in pairs(items) do
			inv:add_item("main", item)
		end
	end
})

function give_initial_stuff.get_stuff()
	return ctf_map.map and ctf_map.map.initial_stuff or {
		"default:pick_wood",
		"default:sword_wood",
		"default:torch 3",
	}
end

minetest.register_on_joinplayer(function(player)
	player:set_hp(20)
	give_initial_stuff(player)
end)
minetest.register_on_respawnplayer(give_initial_stuff)
