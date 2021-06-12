--Inspired from Andrey's bandages mod

ctf_bandages = {}
ctf_bandages.heal_percent = 0.75 -- Percentage of total HP to be healed

minetest.register_craftitem("ctf_bandages:bandage", {
	description = "Bandage\n\n" ..
		"Heals teammates for 3-4 HP until target's HP is equal to " ..
		ctf_bandages.heal_percent * 100 .. "% of their maximum HP",
	inventory_image = "ctf_bandages_bandage.png",
	stack_max = 1,
	on_use = function(itemstack, player, pointed_thing)
		if pointed_thing.type ~= "object" then return end

		local object = pointed_thing.ref
		if not object:is_player() then return end

		local pname = object:get_player_name()
		local name = player:get_player_name()

		if ctf.player(pname).team == ctf.player(name).team then
			local hp = object:get_hp()
			local limit = ctf_bandages.heal_percent * object:get_properties().hp_max

			if hp <= 0 then
				hud_event.new(name, {
					name  = "ctf_bandages:dead",
					color = "warning",
					value = pname .. " is dead!",
				})
			elseif hp >= limit then
				hud_event.new(name, {
					name  = "ctf_bandages:limit",
					color = "warning",
					value = pname .. " already has " .. limit .. " HP!",
				})
			else
				local hp_add = math.random(3,4)

				kill_assist.add_heal_assist(pname, hp_add)
				hp = hp + hp_add

				if hp > limit then
					hp = limit
				end

				object:set_hp(hp)
				hud_event.new(pname, {
					name  = "ctf_bandages:heal",
					color = 0xC1FF44,
					value = name .. " healed you!\nYour HP:"..object:get_hp(),
				})
			end
		else
			hud_event.new(name, {
				name  = "ctf_bandages:team",
				color = "warning",
				value = pname .. " isn't in your team!",
			})
		end
	end,
})
