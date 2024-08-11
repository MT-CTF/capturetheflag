local players = {}
local ATTACH_POSITION = minetest.rgba and {x=0, y=20, z=0} or {x=0, y=10, z=0}

local TYPE_BUILTIN = 0
local TYPE_ENTITY = 1

playertag = {
	TYPE_BUILTIN = TYPE_BUILTIN,
	TYPE_ENTITY  = TYPE_ENTITY,
}

local function remove_entity_tag(player)
	local tag = players[player:get_player_name()]
	if tag then
		if tag.entity then
			tag.entity.object:remove()
			tag.entity = nil
		end

		if tag.nametag_entity then
			tag.nametag_entity.object:remove()
			tag.nametag_entity = nil
		end

		if tag.symbol_entity then
			tag.symbol_entity.object:remove()
			tag.symbol_entity = nil
		end
	end
end

local function add_entity_tag(player, old_observers)
	local pname = player:get_player_name()
	local ppos = player:get_pos()

	-- Hide fixed nametag
	player:set_nametag_attributes({
		color = {a = 0, r = 0, g = 0, b = 0}
	})

	remove_entity_tag(player)

	if not ppos then return end

	local ent = minetest.add_entity(ppos, "playertag:tag")
	local ent2 = false
	local ent3 = false

	if not ent then
		minetest.after(1, add_entity_tag, player, old_observers)
		return
	end

	if ent.set_observers then
		ent2 = minetest.add_entity(ppos, "playertag:tag")
		ent2:set_observers(old_observers.nametag_entity or {})
		ent2:set_properties({
			nametag = pname,
			nametag_color = "#EEFFFFDD",
			nametag_bgcolor = "#0000002D"
		})

		ent3 = minetest.add_entity(ppos, "playertag:tag")
		ent3:set_observers(old_observers.symbol_entity or {})
		ent3:set_properties({
			collisionbox = { 0, 0, 0, 0, 0, 0 },
			nametag = "V",
			nametag_color = "#EEFFFFDD",
			nametag_bgcolor = "#0000002D"
		})
	end

	-- Build name from font texture
	local texture = "npcf_tag_bg.png"
	local x = math.floor(134 - ((pname:len() * 11) / 2))
	local i = 0
	pname:gsub(".", function(char)
		local n = "_"
		if char:byte() > 96 and char:byte() < 123 or char:byte() > 47 and char:byte() < 58 or char == "-" then
			n = char
		elseif char:byte() > 64 and char:byte() < 91 then
			n = "U" .. char
		end
		texture = texture.."^[combine:84x14:"..(x+i+1)..",1=(W_".. n ..".png\\^[multiply\\:#000):"..
				(x+i)..",0=W_".. n ..".png"
		i = i + 11
	end)
	ent:set_properties({ textures={texture} })

	-- Attach to player
	ent:set_attach(player, "", ATTACH_POSITION, {x=0, y=0, z=0})

	if ent2 and ent3 then
		ent2:set_attach(player, "", ATTACH_POSITION, {x=0, y=0, z=0})
		ent3:set_attach(player, "", ATTACH_POSITION, {x=0, y=0, z=0})
	end

	-- Store
	players[pname].entity = ent:get_luaentity()
	players[pname].nametag_entity = ent2 and ent2:get_luaentity()
	players[pname].symbol_entity = ent3 and ent3:get_luaentity()
end

local function update(player, settings)
	local pname = player:get_player_name()
	local old_observers = {}

	if player.get_observers and players[pname] then
		if players[pname].nametag_entity and players[pname].nametag_entity.object:get_pos() then
			old_observers.nametag_entity = players[pname].nametag_entity.object:get_observers()
		end

		if players[pname].symbol_entity and players[pname].nametag_entity.object:get_pos() then
			old_observers.symbol_entity = players[pname].symbol_entity.object:get_observers()
		end
	end

	if settings.nametag_entity_observers then
		old_observers.nametag_entity = table.copy(settings.nametag_entity_observers)
		settings.nametag_entity_observers = nil
	end

	if settings.symbol_entity_observers then
		old_observers.symbol_entity = table.copy(settings.symbol_entity_observers)
		settings.symbol_entity_observers = nil
	end

	remove_entity_tag(player)
	players[pname] = settings

	if settings.type == TYPE_BUILTIN then
		player:set_nametag_attributes({
			color = settings.color or {a=255, r=255, g=255, b=255},
			bgcolor = {a=0, r=0, g=0, b=0},
		})
	elseif settings.type == TYPE_ENTITY then
		add_entity_tag(player, old_observers)
	end
end

function playertag.set(player, type, color, extra)
	local oldset = players[player:get_player_name()]
	if not oldset then return end

	if oldset.type ~= type or oldset.color ~= color then
		extra = extra or {}
		extra.type = type
		extra.color = color

		update(player, extra)
	end

	return players[player:get_player_name()]
end

function playertag.get(player)
	return players[player:get_player_name()]
end

function playertag.get_all()
	return players
end

minetest.register_entity("playertag:tag", {
	visual = "sprite",
	visual_size = {x=2.16, y=0.18, z=2.16}, --{x=1.44, y=0.12, z=1.44},
	textures = {"blank.png"},
	collisionbox = { 0, -0.2, 0, 0, -0.2, 0 },
	physical = false,
	makes_footstep_sound = false,
	backface_culling = false,
	static_save = false,
	pointable = false,
	on_punch = function() return true end,
	on_deactivate = function(self, removal)
		if not removal then
			local attachmentInfo = self.object:get_attach()
			local player = nil
			if attachmentInfo then
				player = attachmentInfo.parent
			end

			if player and player:is_player() then
				minetest.log("action", "Playertag for player "..player:get_player_name().." unloaded. Re-adding...")
				update(player, players[player:get_player_name()])
			end
		end
	end
})

minetest.register_on_joinplayer(function(player)
	players[player:get_player_name()] = {type = TYPE_BUILTIN, color = {a=255, r=255, g=255, b=255}}
end)

minetest.register_on_leaveplayer(function(player)
	remove_entity_tag(player)
	players[player:get_player_name()] = nil
end)
