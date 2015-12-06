join_fs = {
	slides = {},
	players = {}
}

function join_fs.load()
	local filepath = minetest.get_worldpath() .. "/join_fs.txt"
	local file = io.open(filepath, "r")
	if file then
		local table = minetest.deserialize(file:read("*all"))
		if type(table) == "table" then
			join_fs.players = table.players
			return
		end
	end
end

function join_fs.save()
	local filepath = minetest.get_worldpath() .. "/join_fs.txt"
	local file = io.open(filepath, "w")
	if file then
		file:write(minetest.serialize({
			players = join_fs.players
		}))
		file:close()
	else
		minetest.log("warning", "Failed to save join_fs player config!")
	end
end

minetest.register_on_shutdown(function()
	join_fs.save()
end)

function join_fs.confirm(name, sname)
	local player = join_fs.players[name]
	if not player then
		player = {}
		join_fs.players[name] = player
	end
	player[sname] = true
	join_fs.save()
end

function join_fs.register_slide(def)
	table.insert(join_fs.slides, def)
	return def.name
end

function join_fs.show_next_slide(player)
	for _, def in pairs(join_fs.slides) do
		local pids = join_fs.players[player:get_player_name()] or {}
		if def.should_show(player, pids[def.name]) then
			def.show(player)
			break
		end
	end
end

join_fs.load()
minetest.register_on_joinplayer(function (player)
	local name = player:get_player_name()
	minetest.after(0.5, function()
		local player = minetest.get_player_by_name(name)
		if player then
			join_fs.show_next_slide(player)
		end
	end)
end)
