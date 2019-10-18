local nametags = {}
local tag_settings = {}
local ATTACH_POSITION = minetest.rgba and {x=0,y=20,z=0} or {x=0,y=10,z=0}

local TYPE_BUILTIN = 0
local TYPE_ENTITY = 1

ctf_playertag = {
	TYPE_BUILTIN = TYPE_BUILTIN,
	TYPE_ENTITY  = TYPE_ENTITY,
}

local function add_entity_tag(player)
	local ent = minetest.add_entity(player:get_pos(), "ctf_playertag:tag")

	-- Build name from font texture
	local color = "W"
	local texture = "npcf_tag_bg.png"
	local x = math.floor(134 - ((player:get_player_name():len() * 11) / 2))
	local i = 0
	player:get_player_name():gsub(".", function(char)
		if char:byte() > 64 and char:byte() < 91 then
			char = "U"..char
		end
		texture = texture.."^[combine:84x14:"..(x+i)..",0="..color.."_"..char..".png"
		i = i + 11
	end)
	ent:set_properties({ textures={texture} })

	-- Attach to player
	ent:set_attach(player, "", ATTACH_POSITION, {x=0,y=0,z=0})
	ent:get_luaentity().wielder = player:get_player_name()

	-- Store
	nametags[player:get_player_name()] = ent

	-- Hide fixed nametag
	player:set_nametag_attributes({
		color = {a = 0, r = 0, g = 0, b = 0}
	})
end

local function remove_entity_tag(player)
	tag_settings[player:get_player_name()] = nil
	local tag = nametags[player:get_player_name()]
	if tag then
		tag:remove()
		nametags[player:get_player_name()] = nil
	end
end

local function update(player, settings)
	tag_settings[player:get_player_name()] = settings

	if settings.type == TYPE_BUILTIN then
		remove_entity_tag(player)
		player:set_nametag_attributes({
			color = settings.color
		})
	elseif settings.type == TYPE_ENTITY then
		add_entity_tag(player)
	end
end

function ctf_playertag.set(player, type, color)
	local oldset = tag_settings[player:get_player_name()]
	color = color or { a=255, r=255, g=255, b=255 }
	if not oldset or oldset.type ~= type or oldset.color ~= color then
		update(player, { type = type, color = color })
	end
end

function ctf_playertag.get(player)
	return tag_settings[player:get_player_by_name()]
end

function ctf_playertag.get_all()
	return tag_settings
end

local nametag = {
	npcf_id = "nametag",
	physical = false,
	collisionbox = {x=0, y=0, z=0},
	visual = "sprite",
	textures = {"default_dirt.png"},--{"npcf_tag_bg.png"},
	visual_size = {x=2.16, y=0.18, z=2.16},--{x=1.44, y=0.12, z=1.44},
}

function nametag:on_activate(staticdata, dtime_s)
	if staticdata == "expired" then
		local name = self.wielder and self.wielder:get_player_name()
		if name and nametags[name] == self.object then
			nametags[name] = nil
		end

		self.object:remove()
	end
end

function nametag:get_staticdata()
	return "expired"
end

function nametag:on_step(dtime)
	local name = self.wielder
	local wielder = name and minetest.get_player_by_name(name)
	if not wielder then
		self.object:remove()
	elseif not tag_settings[name] or tag_settings[name].type ~= TYPE_ENTITY then
		if name and nametags[name] == self.object then
			nametags[name] = nil
		end

		self.object:remove()
	end
end

minetest.register_entity("ctf_playertag:tag", nametag)

local function step()
	for _, player in pairs(minetest.get_connected_players()) do
		local settings = tag_settings[player:get_player_name()]
		if settings and settings.type == TYPE_ENTITY then
			local ent = nametags[player:get_player_name()]
			if not ent or ent:get_luaentity() == nil then
				add_entity_tag(player)
			else
				ent:set_attach(player, "", ATTACH_POSITION, {x=0,y=0,z=0})
			end
		end
	end

	minetest.after(10, step)
end
minetest.after(10, step)

minetest.register_on_joinplayer(function(player)
	ctf_playertag.set(player, TYPE_BUILTIN, {a = 0, r = 255, g = 255, b = 255})
	minetest.after(2, function(name)
		player = minetest.get_player_by_name(name)
		if player then
			ctf_playertag.set(player, TYPE_ENTITY)
		end
	end, player:get_player_name())
end)

minetest.register_on_leaveplayer(function(player)
	remove_entity_tag(player)
end)
