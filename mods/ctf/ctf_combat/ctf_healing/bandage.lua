--Inspired from Andrey's bandages mod

ctf_healing = {}

function ctf_healing.register_bandage(name, def)
	local tooldef = {
		description = def.description,
		inventory_image = def.inventory_image,
		on_use = function(itemstack, player, pointed_thing)
			if pointed_thing.type ~= "object" then return end

			local object = pointed_thing.ref
			if not object:is_player() then return end

			local pname = object:get_player_name()
			local uname = player:get_player_name()

			if ctf_teams.get(pname) == ctf_teams.get(uname) then
				local hp = object:get_hp()
				local limit = def.heal_percent * object:get_properties().hp_max

				if hp <= 0 then
					hud_events.new(uname, {
						quick = true,
						text = pname .. " is dead!",
						color = "warning",
					})
				elseif hp >= limit then
					hud_events.new(uname, {
						quick = true,
						text = pname .. " already has " .. limit .. " HP!",
						color = "warning",
					})
				else
					local hp_add = math.random(def.heal_min or 3, def.heal_max or 4)

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
							text = uname .. " healed you!",
							color = 0xC1FF44,
						})
					elseif type(result) == "string" then
						hud_events.new(uname, {
							quick = true,
							text = result,
							color = "warning",
						})
					end
				end
			else
				hud_events.new(uname, {
					quick = true,
					text = pname .. " isn't in your team!",
					color = "warning",
				})
			end
		end,
	}

	if def.rightclick_func then
		tooldef.on_place = def.rightclick_func

		tooldef.on_secondary_use = function(itemstack, user, pointed_thing, ...)
			if pointed_thing then
				def.rightclick_func(itemstack, user, pointed_thing, ...)
			end
		end
	end

	minetest.register_tool(name, tooldef)
end

local HEAL_PERCENT = 0.75
ctf_healing.register_bandage("ctf_healing:bandage", {
	description = "Bandage\nHeals teammates for 3-4 HP until target's HP is equal to " ..
			HEAL_PERCENT * 100 .. "% of their maximum HP",
	inventory_image = "ctf_healing_bandage.png",
	heal_percent = HEAL_PERCENT,
})
