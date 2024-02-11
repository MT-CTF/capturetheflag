ctf_cosmetics = {}

function ctf_cosmetics.get_colored_skin(player, color)
	color = color or "white"
	local extras = {}

	for clothing, clothcolor in pairs(ctf_cosmetics.get_extra_clothing(player)) do
		local append = false

		if type(clothcolor) == "table" then
			append = clothcolor.append
			clothcolor = clothcolor.color
		end

		if clothing:sub(1, 1) ~= "_" then
			local texture = ctf_cosmetics.get_clothing_texture(player, clothing)

			if texture then
				table.insert(extras, append and (#extras + 1) or 1, string.format(
					"^(%s^[multiply:%s)",
					texture,
					clothcolor
				))
			end
		end
	end

	return string.format(
		"character.png^(%s^[multiply:%s)^(%s^[multiply:%s)%s",
		ctf_cosmetics.get_clothing_texture(player, "shirt"), color,
		ctf_cosmetics.get_clothing_texture(player, "pants"), color,
		table.concat(extras)
	)
end

function ctf_cosmetics.get_skin(player)
	local pteam = ctf_teams.get(player)

	return ctf_cosmetics.get_colored_skin(player, pteam and ctf_teams.team[pteam].color)
end

function ctf_cosmetics.get_clothing_texture(player, clothing)
	local texture = PlayerObj(player):get_meta():get_string("ctf_cosmetics_"..clothing)

	if not texture or texture == "" then
		return "ctf_cosmetics_"..clothing..".png"
	else
		return texture
	end

end

function ctf_cosmetics.set_extra_clothing(player, extra_clothing)
	local current = ctf_cosmetics.get_extra_clothing(player)

	current._unset = nil

	if extra_clothing._remove then
		for _, clothing in pairs(extra_clothing._remove) do
			current[clothing] = nil
		end

		extra_clothing._remove = nil
	end

	for clothing, clothingcolor in pairs(extra_clothing) do
		current[clothing] = clothingcolor
	end

	return PlayerObj(player):get_meta():set_string("ctf_cosmetics:extra_clothing", minetest.serialize(current))
end

function ctf_cosmetics.get_extra_clothing(player)
	local meta = PlayerObj(player):get_meta():get_string("ctf_cosmetics:extra_clothing")

	if meta == "" then
		return {_unset = true}
	else
		return minetest.deserialize(meta) or {_unset = true}
	end
end
