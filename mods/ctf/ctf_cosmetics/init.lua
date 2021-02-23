ctf_cosmetics = {}

function ctf_cosmetics.get_colored_skin(player, color)
	local extras = ""

	for clothing, clothcolor in pairs(ctf_cosmetics.get_extra_clothing(player)) do
		extras = string.format(
			"%s^(%s^[multiply:%s)", extras,
			ctf_cosmetics.get_clothing_texture(player, clothing),
			clothcolor
		)
	end

	return string.format(
		"character.png^(%s^[multiply:%s)^(%s^[multiply:%s)%s",
		ctf_cosmetics.get_clothing_texture(player, "shirt"),
		color,
		ctf_cosmetics.get_clothing_texture(player, "pants"),
		color,
		extras
	)
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
	return minetest.deserialize(PlayerObj(player):get_meta():get_string("ctf_cosmetics:extra_clothing")) or {}
end
