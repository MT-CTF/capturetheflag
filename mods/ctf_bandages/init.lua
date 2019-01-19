--Inspired from Andrey's bandages mod

minetest.register_craftitem("ctf_bandages:bandage", {
	description = "Bandage, heals teammates for 15HP",
	inventory_image = "ctf_bandages_bandage.png",
	range = 4,
	on_use = function(itemstack, player, pointed_thing)
	if pointed_thing.type == "object" then
		local name = player:get_player_name()
		local object = pointed_thing.ref
		local team = ctf.player(name).team
			if not object:is_player() then
				return
			end

			if ctf.player(object:get_player_name()).team == team then
				local hp = object:get_hp()
				if hp > 0 and hp <= 15 then
					object:set_hp(hp + math.random(3,4))
					itemstack:take_item()
				else
					minetest.chat_send_player(object:get_player_name(), "Your HP is above 15!")
					minetest.chat_send_player(player:get_player_name(), object:get_player_name().."'s".." HP is above 15!")
				end
				return itemstack
			else
				minetest.chat_send_player(player:get_player_name(), object:get_player_name().." isn't in your team!")
			end
	end
end,
})
