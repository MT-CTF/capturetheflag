weapon_data = {{"frag",{"blown up", "bombed", "exploded"}}, {"knockback_grenade",{"sent flying", "doomed to fall"}}, {"black_hole_grenade",{"sucked into the void"}}, {"sword",{"killed", "slashed", "stabbed", "murdered"}}, {"axe",{"killed", "slashed", "murdered", "axed a question"}}, {"shovel",{"killed by a gardening mere tool"}}, {"pick",{"pickaxed to death"}}, {"ctf_ranged",{"shot", "sniped"}}, {"default_water", {"suffocated"}}}

ctf_death_message = {}

function ctf_death_message.death_message(player, killer, weapon_image)
    local death_message_setting = ctf_settings.get(minetest.get_player_by_name(player), "ctf_death_message:send_death_message")
    local image_index = nil
    local death_message = ""
    local assist_message = ""
    local hitters = ctf_combat_mode.get_other_hitters(player, killer)

    local k_teamcolor = ctf_teams.get(killer)
    if k_teamcolor then
		local k_teamcolor = ctf_teams.team[k_teamcolor].color
	end
    for index, data in ipairs(weapon_data) do
        if weapon_image:find(data[1]) then
            image_index = index
        end
    end

    if #hitters > 0 then
        assist_message = ", assisted by "
        for index, pname in ipairs(hitters) do
            local a_teamcolor = ctf_teams.get(pname)
            if a_teamcolor then
		        a_teamcolor = ctf_teams.team[a_teamcolor].color
	        end
            if index == 1 then
                assist_message = assist_message .. minetest.colorize(a_teamcolor, pname)
            elseif index == #hitters then
                assist_message = assist_message .. ", and " .. minetest.colorize(a_teamcolor, pname)
            
			else
                assist_message = assist_message .. ", " .. minetest.colorize(a_teamcolor, pname)
            end
		end
    end

    if (death_message_setting == "true") then
        if image_index and player ~= killer then
            death_message = "You were " .. weapon_data[image_index][2][math.random(1,#weapon_data[image_index][2])] .. " by " .. minetest.colorize(k_teamcolor, killer) .. assist_message .. "."
            minetest.chat_send_player(player, death_message)
        elseif player ~= killer then
            death_message = "You were killed by " .. minetest.colorize(k_teamcolor, killer) .. assist_message .. "."
            minetest.chat_send_player(player, death_message)
        end
        if player == killer and #hitters == 0 then
            local suicide_message = nil
            if image_index then 
                suicide_message = weapon_data[image_index][2][math.random(1,#weapon_data[image_index][2])] 
            end
            if suicide_message == nil then 
                suicide_message = "suicided"
            end
            death_message = "You " .. suicide_message .. assist_message .. "."
            minetest.chat_send_player(player, death_message)
        end
    end
end

minetest.register_on_mods_loaded(function()
    ctf_settings.register("ctf_death_message:send_death_message", {
	    type = "bool",
	    label = "Recieve death message.",
	    description = "When enabled, you will recieve a death message whenever you die stating who killed you.",
	    default = "false",
    })
end)
