--
--- PLAYERS
--

do
	local get_player_by_name = minetest.get_player_by_name
	function PlayerObj(player)
		local type = type(player)

		if type == "string" then
			return get_player_by_name(player)
		elseif type == "userdata" and player:is_player() then
			return player
		end
	end

	function PlayerName(player)
		local type = type(player)

		if type == "string" then
			return player
		elseif type == "userdata" and player:is_player() then
			return player:get_player_name()
		end
	end
end

--
--- FORMSPECS
--

do
	local registered_on_formspec_input = {}
	function ctf_core.register_on_formspec_input(formname, func)
		table.insert(registered_on_formspec_input, {formname = formname, call = func})
	end

	minetest.register_on_player_receive_fields(function(player, formname, fields, ...)
		for _, func in ipairs(registered_on_formspec_input) do
			if formname:match(func.formname) then
				if func.call(PlayerName(player), formname, fields, ...) then
					return
				end
			end
		end
	end)
end

--
--- STRINGS
--

do
	local format = string.format
	local gsub   = string.gsub
	local upper  = string.upper
	local lower  = string.lower
	local remove = table.remove
	local sort   = table.sort

	function HumanReadable(input)
		if not input then return input end

		local out
		local t = type(input)

		if t == "string" then
			out = gsub(input, "(%a)([%w'-]*)", function(a,b) return format("%s%s", upper(a), lower(b)) end)

			out = gsub(out, "_", " ")
		elseif t == "table" then -- Only accepts lists
			input = table.copy(input)
			sort(input)

			if #input >= 2 then
				local last = remove(input)

				for _, i in ipairs(input) do
					out = format("%s%s, ", out or "", HumanReadable(i))
				end

				out = format("%sand %s", out, HumanReadable(last))
			else
				out = HumanReadable(input[1]) or "[ERROR]"
			end
		end

		return out
	end
end

--
--- TABLES
--

-- Borrowed from random_messages mod
function table.count( t ) -- luacheck: ignore
	local i = 0
	for k in pairs( t ) do i = i + 1 end
	return i
end

---@param funclist table
function RunCallbacks(funclist, ...)
	for _, func in ipairs(funclist) do
		local temp = func(...)

		if temp then
			return temp
		end
	end
end

--
--- VECTORS/POSITIONS
--

do
	function vector.sign(a)
		return vector.new(math.sign(a.x), math.sign(a.y), math.sign(a.z))
	end

	local vsort = vector.sort
	function ctf_core.pos_inside(pos, pos1, pos2)
		pos1, pos2 = vsort(pos1, pos2)

		return pos.x >= pos1.x and pos.x <= pos2.x
		and pos.y >= pos1.y and pos.y <= pos2.y
		and pos.z >= pos1.z and pos.z <= pos2.z
	end

	if not math.round then
		local m_floor = math.floor

		function math.round(x)
			return m_floor(x + 0.5)
		end
	end
end
--
--- MISC
--

function ctf_core.register_chatcommand_alias(name, alias, def)
	minetest.register_chatcommand(name, def)
	if alias then
		minetest.register_chatcommand(alias, {
			description = "An alias for /" .. name,
			func = def.func,
		})
	end
end

function ctf_core.file_exists(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	end

	return false
end

--
---Debug helpers
--

function ctf_core.error(area, msg)
	minetest.log("error", "[CTF | " .. area .. "] " .. msg)
end

function ctf_core.log(area, msg)
	if area and area ~= "" then
		minetest.log("info", "[CTF | " .. area .. "] " .. msg)
	else
		minetest.log("info", "[CTF]" .. msg)
	end
end

function ctf_core.action(area, msg)
	if area and area ~= "" then
		minetest.log("action", "[CaptureTheFlag] (" .. area .. ") " .. msg)
	else
		minetest.log("action", "[CaptureTheFlag] " .. msg)
	end
end

function ctf_core.warning(area, msg)
	minetest.log("warning", "[CTF | " .. area .. "] " .. msg)
end
