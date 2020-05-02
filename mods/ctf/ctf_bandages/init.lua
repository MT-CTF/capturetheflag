--Inspired from Andrey's bandages mod

minetest.register_craftitem("ctf_bandages:bandage", {
	description = "Bandage\n\nHeals teammates for 3-4 HP until HP is equal to 75% of the total HP",
	inventory_image = "ctf_bandages_bandage.png",
	on_use = function(itemstack, player, pointed_thing)
		if pointed_thing.type ~= "object" then
			return
		end
		local object = pointed_thing.ref
		if not object:is_player() then
			return
		end
		local pname = object:get_player_name()
		local name = player:get_player_name()
		if ctf.player(pname).team == ctf.player(name).team then
			local hp = object:get_hp()
			local percentage = 0.75 --Percentage of total HP to be healed
			local limit = percentage * object:get_properties().hp_max
			if hp > 0 and hp < limit then
				hp = hp + math.random(3,4)
				if hp > limit then
					hp = limit
				end
				object:set_hp(hp)
				itemstack:take_item()
				minetest.chat_send_player(pname, minetest.colorize("#C1FF44", name .. " has healed you!"))
				return itemstack
			else
				minetest.chat_send_player(name, pname .. " has " .. hp .. " HP. You can't heal them.")
			end
		else
			minetest.chat_send_player(name, pname.." isn't in your team!")
		end
	end,
})
