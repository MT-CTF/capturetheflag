--Inspired from Andrey's bandages mod

local HEAL_PERCENT = 0.75 -- Percentage of total HP to be healed

minetest.register_craftitem("ctf_healing:bandage", {
	description = "Bandage\n\n" ..
		"Heals teammates for 3-4 HP until target's HP is equal to " ..
		HEAL_PERCENT * 100 .. "% of their maximum HP",
	inventory_image = "ctf_healing_bandage.png",
	stack_max = 1,
	on_use = function(itemstack, player, pointed_thing)
		if pointed_thing.type ~= "object" then return end

		local object = pointed_thing.ref
		if not object:is_player() then return end

		local pname = object:get_player_name()
		local name = player:get_player_name()

		if ctf_teams.get(pname) == ctf_teams.get(name) then
			local hp = object:get_hp()
			local limit = HEAL_PERCENT * object:get_properties().hp_max

			if hp <= 0 then
				hud_events.new(name, {
					quick = true,
					text = pname .. " is dead!",
					color = "warning",
				})
			elseif hp >= limit then
				hud_events.new(name, {
					quick = true,
					text = pname .. " already has " .. limit .. " HP!",
					color = "warning",
				})
			else
				local hp_add = math.random(3,4)

				if hp + hp_add > limit then
					hp_add = limit - hp
					hp = limit
				else
					hp = hp + hp_add
				end

				local result = RunCallbacks(ctf_healing.registered_on_heal, player, object, hp_add)

				if not result then
					object:set_hp(hp)
					hud_events.new(pname, {
						quick = true,
						text = name .. " healed you!",
						color = 0xC1FF44,
					})
				elseif type(result) == "string" then
					hud_events.new(name, {
						quick = true,
						text = result,
						color = "warning",
					})
				end
			end
		else
			hud_events.new(name, {
				quick = true,
				text = pname .. " isn't in your team!",
				color = "warning",
			})
		end
	end,
})
