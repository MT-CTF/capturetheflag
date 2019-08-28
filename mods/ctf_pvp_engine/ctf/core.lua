-- Awaiting core support.
local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    if state == nil then
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end



-- Registered
ctf.registered_on_load = {}
function ctf.register_on_load(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_load, func)
	if ctf._loaddata then
		func(ctf._loaddata)
	end
end
ctf.registered_on_save = {}
function ctf.register_on_save(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_save, func)
end
ctf.registered_on_init = {}
function ctf.register_on_init(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_init, func)
	if ctf._inited then
		func()
	end
end
ctf.registered_on_new_team = {}
function ctf.register_on_new_team(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_new_team, func)
end
ctf.registered_on_territory_query = {}
function ctf.register_on_territory_query(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_territory_query, func)
end
ctf.registered_on_new_game = {}
function ctf.register_on_new_game(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_new_game, func)
	if ctf._new_game then
		func()
	end
end

function vector.distanceSQ(p1, p2)
	local x = p1.x - p2.x
	local y = p1.y - p2.y
	local z = p1.z - p2.z
	return x*x + y*y + z*z
end



-- Debug helpers
function ctf.error(area, msg)
	minetest.log("error", "CTF::" .. area .. " - " ..msg)
end
function ctf.log(area, msg)
	if area and area ~= "" then
		print("[CaptureTheFlag] (" .. area .. ") " .. msg)
	else
		print("[CaptureTheFlag] " .. msg)
	end
end
function ctf.action(area, msg)
	if area and area ~= "" then
		minetest.log("action", "[CaptureTheFlag] (" .. area .. ") " .. msg)
	else
		minetest.log("action", "[CaptureTheFlag] " .. msg)
	end
end
function ctf.warning(area, msg)
	print("WARNING: [CaptureTheFlag] (" .. area .. ") " .. msg)
end

function ctf.init()
	ctf._inited = true
	ctf.log("init", "Initialising!")

	-- Set up structures
	ctf._defsettings = {}
	ctf.teams = {}
	ctf.players = {}

	-- See minetest.conf.example in the root of this subgame

	ctf.log("init", "Creating Default Settings")
	ctf._set("diplomacy",                  true)
	ctf._set("players_can_change_team",    true)
	ctf._set("allocate_mode",              0)
	ctf._set("maximum_in_team",            -1)
	ctf._set("default_diplo_state",        "war")
	ctf._set("hud",                        true)
	ctf._set("autoalloc_on_joinplayer",    true)
	ctf._set("friendly_fire",              true)
	ctf._set("spawn_offset",               "0,0,0")


	for i = 1, #ctf.registered_on_init do
		ctf.registered_on_init[i]()
	end

	ctf.load()
end

function ctf.reset()
	ctf.log("io", "Deleting CTF save data...")
	os.remove(minetest.get_worldpath().."/ctf.txt")
	ctf.player_last_team = {}
	ctf.init()
end

-- Set default setting value
function ctf._set(setting, default)
	if ctf._defsettings[setting] then
		ctf.warning("settings", "Setting " .. dump(setting) .. " redeclared!")
		ctf.warning("settings", debug.traceback())
	end
	ctf._defsettings[setting] = default

	if minetest.settings:get("ctf."..setting) then
		ctf.log("settings", "- " .. setting .. ": " .. minetest.settings:get("ctf."..setting))
	elseif minetest.settings:get("ctf_"..setting) then
		ctf.log("settings", "- " .. setting .. ": " .. minetest.settings:get("ctf_"..setting))
		ctf.warning("settings", "deprecated setting ctf_"..setting..
				" used, use ctf."..setting.." instead.")
	end
end

function ctf.setting(name)
	local set = minetest.settings:get("ctf."..name) or
			minetest.settings:get("ctf_"..name)
	local dset = ctf._defsettings[name]
	if dset == nil then
		ctf.error("setting", "No such setting - " .. name)
		return nil
	end

	if set ~= nil then
		if type(dset) == "number" then
			return tonumber(set)
		elseif type(dset) == "boolean" then
			return minetest.is_yes(set)
		else
			return set
		end
	else
		return dset
	end
end

function ctf.load()
	ctf.log("io", "Loading CTF state")
	local file = io.open(minetest.get_worldpath().."/ctf.txt", "r")
	if file then
		local table = minetest.deserialize(file:read("*all"))
		if type(table) == "table" then
			ctf.teams = table.teams
			ctf.players = table.players

			for i = 1, #ctf.registered_on_load do
				ctf.registered_on_load[i](table)
			end
			return
		end
		ctf._loaddata = table
	else
		ctf.log("io", "ctf.txt is not present in the world folder")
		ctf._new_game = true
		for i = 1, #ctf.registered_on_new_game do
			ctf.registered_on_new_game[i]()
		end
	end
end

minetest.after(0, function()
	ctf._loaddata = nil
	ctf._mt_loaded = true
end)

function ctf.check_save()
	if ctf_flag and ctf_flag.assert_flags then
		ctf_flag.assert_flags()
	end
	if ctf.needs_save then
		ctf.save()
	end
	minetest.after(10, ctf.check_save)
end
minetest.after(10, ctf.check_save)

function ctf.save()
	local file = io.open(minetest.get_worldpath().."/ctf.txt", "w")
	if file then
		local out = {
			teams = ctf.teams,
			players = ctf.players
		}

		for i = 1, #ctf.registered_on_save do
			local res = ctf.registered_on_save[i]()

			if res then
				for key, value in pairs(res) do
					out[key] = value
				end
			end
		end

		file:write(minetest.serialize(out))
		file:close()
    	ctf.needs_save = false
	else
		ctf.error("io", "CTF file failed to save!")
	end
end
