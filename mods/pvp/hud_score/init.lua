hud_score = {}
local hud = hudkit()

local players = {}
local duration = 5
local max = 6
local next_check = 10000000

local function update(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	-- Handle all elements marked for deletion
	-- and rebuild table
	local temp = {}
	for _, def in ipairs(players[name]) do
		if def.delete then
			if hud:exists(player, def.name) then
				hud:remove(player, def.name)
			end
		else
			table.insert(temp, def)
		end
	end

	for i, def in ipairs(temp) do
		-- If not the top-most element, prefix with "+ "
		local text = def.value
		if i > 1 then
			text = "+ " .. text
		end

		text = tostring(text)

		if hud:exists(player, def.name) then
			hud:change(player, def.name, "text", text)
			hud:change(player, def.name, "offset", {x = 0, y = i * 20})
		else
			hud:add(player, def.name, {
				hud_elem_type = "text",
				alignment = {x = 0, y = 0},
				position = {x = 0.5, y = 0.6},
				offset = {x = 0, y = i * 20},
				number = tonumber(def.color),
				text = text
			})
		end
	end
	players[name] = temp
end

function hud_score.new(name, def)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	-- Verify HUD score element def
	if not name or not def or type(def) ~= "table" or
			not def.name or not def.value or not def.color then
		error("hud_score: Invalid HUD score element definition", 2)
	end

	-- Store element expiration time in def.time
	-- and append score element def to players[name]
	def.time = os.time() + duration
	if next_check > duration then
		next_check = duration
	end
	table.insert(players[name], def)

	-- If more than `max` active elements, mark oldest element for deletion
	if #players[name] > max then
		players[name][1].delete = true
	end

	update(name)
end

minetest.register_globalstep(function(dtime)
	next_check = next_check - dtime
	if next_check > 0 then
		return
	end

	next_check = 10000000

	-- Loop through HUD score elements of all players
	-- and remove them if they've expired
	for name, hudset in pairs(players) do
		local modified = false
		for i, def in pairs(hudset) do
			local rem = def.time - os.time()
			if rem <= 0 then
				def.delete = true
				modified = true
			elseif rem < next_check then
				next_check = rem
			end
		end

		-- If a player's hudset was modified, update player's HUD
		if modified then
			update(name)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	players[player:get_player_name()] = {}
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)
