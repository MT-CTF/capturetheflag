local players = {}
local ATTACH_POSITION = minetest.rgba and {x=0, y=20, z=0} or {x=0, y=10, z=0}

local TYPE_BUILTIN = 0
local TYPE_ENTITY = 1

ctf_playertag = {
	TYPE_BUILTIN = TYPE_BUILTIN,
	TYPE_ENTITY  = TYPE_ENTITY,
}

local function add_entity_tag(player)
	-- Hide fixed nametag
	player:set_nametag_attributes({
		color = {a = 0, r = 0, g = 0, b = 0}
	})

	local ent = minetest.add_entity(player:get_pos(), "ctf_playertag:tag")

	-- Build name from font texture
	local texture = "npcf_tag_bg.png"
	local x = math.floor(134 - ((player:get_player_name():len() * 11) / 2))
	local i = 0
	player:get_player_name():gsub(".", function(char)
		local n = "_"
		if char:byte() > 96 and char:byte() < 123 or char:byte() > 47 and char:byte() < 58 or char == "-" then
			n = char
		elseif char:byte() > 64 and char:byte() < 91 then
			n = "U" .. char
		end
		texture = texture.."^[combine:84x14:"..(x+i)..",0=W_".. n ..".png"
		i = i + 11
	end)
	ent:set_properties({ textures={texture} })

	-- Attach to player
	ent:set_attach(player, "", ATTACH_POSITION, {x=0, y=0, z=0})

	-- Store
	players[player:get_player_name()].entity = ent
end

local function remove_entity_tag(player)
	local tag = players[player:get_player_name()]
	if tag and tag.entity then
		tag.entity:remove()
	end
end

local function update(player, settings)
	remove_entity_tag(player)
	players[player:get_player_name()] = settings

	if settings.type == TYPE_BUILTIN then
		player:set_nametag_attributes({
			color = settings.color or {a=255, r=255, g=255, b=255},
			bgcolor = {a=0, r=0, g=0, b=0},
		})
	elseif settings.type == TYPE_ENTITY then
		add_entity_tag(player)
	end
end

function ctf_playertag.set(player, type, color)
	local oldset = players[player:get_player_name()]
	if not oldset or oldset.type ~= type or oldset.color ~= color then
		update(player, {type = type, color = color})
	end
end

function ctf_playertag.get(player)
	return players[player:get_player_by_name()]
end

function ctf_playertag.get_all()
	return players
end

minetest.register_entity("ctf_playertag:tag", {
	visual = "sprite",
	visual_size = {x=2.16, y=0.18, z=2.16}, --{x=1.44, y=0.12, z=1.44},
	textures = {"blank.png"},
	collisionbox = {0},
	physical = false,
	static_save = false,
})

minetest.register_on_joinplayer(function(player)
	ctf_playertag.set(player, TYPE_ENTITY)
end)

minetest.register_on_leaveplayer(function(player)
	remove_entity_tag(player)
	players[player:get_player_name()] = nil
end)
