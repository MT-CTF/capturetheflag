ChatCmdBuilder = {}

function ChatCmdBuilder.new(name, func, def)
	def = def or {}
	local cmd = ChatCmdBuilder.build(func)
	cmd.def = def
	def.func = cmd.run
	minetest.register_chatcommand(name, def)
	return cmd
end

local STATE_READY = 1
local STATE_PARAM = 2
local STATE_PARAM_TYPE = 3
local bad_chars = {}
bad_chars["("] = true
bad_chars[")"] = true
bad_chars["."] = true
bad_chars["%"] = true
bad_chars["+"] = true
bad_chars["-"] = true
bad_chars["*"] = true
bad_chars["?"] = true
bad_chars["["] = true
bad_chars["^"] = true
bad_chars["$"] = true
local function escape(char)
	if bad_chars[char] then
		return "%" .. char
	else
		return char
	end
end

local dprint = function() end

ChatCmdBuilder.types = {
	pos    = "%(? *(%-?[%d.]+) *, *(%-?[%d.]+) *, *(%-?[%d.]+) *%)?",
	text   = "(.+)",
	number = "(%-?[%d.]+)",
	int    = "(%-?[%d]+)",
	word   = "([^ ]+)",
	alpha  = "([A-Za-z]+)",
	modname      = "([a-z0-9_]+)",
	alphascore   = "([A-Za-z_]+)",
	alphanumeric = "([A-Za-z0-9]+)",
	username     = "([A-Za-z0-9-_]+)",
}

function ChatCmdBuilder.build(rfunc)
	local cmd = {
		_subs = {}
	}
	function cmd:sub(route, func, _)
		dprint("Parsing " .. route)

		if string.trim then
			route = string.trim(route)
		end

		local sub = {
			pattern = "^",
			params = {},
			func = func
		}

		-- End of param reached: add it to the pattern
		local param = ""
		local param_type = ""
		local should_be_eos = false
		local function finishParam()
			if param ~= "" and param_type ~= "" then
				dprint("   - Found param " .. param .. " type " .. param_type)

				local pattern = ChatCmdBuilder.types[param_type]
				if not pattern then
					error("Unrecognised param_type=" .. param_type)
				end

				sub.pattern = sub.pattern .. pattern

				table.insert(sub.params, param_type)

				param = ""
				param_type = ""
			end
		end

		-- Iterate through the route to find params
		local state = STATE_READY
		local catching_space = false
		local match_space = " " -- change to "%s" to also catch tabs and newlines
		local catch_space = match_space.."+"
		for i = 1, #route do
			local c = route:sub(i, i)
			if should_be_eos then
				error("Should be end of string. Nothing is allowed after a param of type text.")
			end

			if state == STATE_READY then
				if c == ":" then
					dprint(" - Found :, entering param")
					state = STATE_PARAM
					param_type = "word"
					catching_space = false
				elseif c:match(match_space) then
					print(" - Found space")
					if not catching_space then
						catching_space = true
						sub.pattern = sub.pattern .. catch_space
					end
				else
					catching_space = false
					sub.pattern = sub.pattern .. escape(c)
				end
			elseif state == STATE_PARAM then
				if c == ":" then
					dprint(" - Found :, entering param type")
					state = STATE_PARAM_TYPE
					param_type = ""
				elseif c:match(match_space) then
					print(" - Found whitespace, leaving param")
					state = STATE_READY
					finishParam()
					catching_space = true
					sub.pattern = sub.pattern .. catch_space
				elseif c:match("%W") then
					dprint(" - Found nonalphanum, leaving param")
					state = STATE_READY
					finishParam()
					sub.pattern = sub.pattern .. escape(c)
				else
					param = param .. c
				end
			elseif state == STATE_PARAM_TYPE then
				if c:match(match_space) then
					print(" - Found space, leaving param type")
					state = STATE_READY
					finishParam()
					catching_space = true
					sub.pattern = sub.pattern .. catch_space
				elseif c:match("%W") then
					dprint(" - Found nonalphanum, leaving param type")
					state = STATE_READY
					finishParam()
					sub.pattern = sub.pattern .. escape(c)
				else
					param_type = param_type .. c
				end
			end
		end
		dprint(" - End of route")
		finishParam()
		sub.pattern = sub.pattern .. "$"
		dprint("Pattern: " .. sub.pattern)

		table.insert(self._subs, sub)
	end

	if rfunc then
		rfunc(cmd)
	end

	cmd.run = function(name, message)
		for i = 1, #cmd._subs do
			local sub = cmd._subs[i]
			local res = { string.match(message, sub.pattern) }
			if #res > 0 then
				local pointer = 1
				local params = { name }
				for j = 1, #sub.params do
					local param = sub.params[j]
					if param == "pos" then
						local pos = {
							x = tonumber(res[pointer]),
							y = tonumber(res[pointer + 1]),
							z = tonumber(res[pointer + 2])
						}
						table.insert(params, pos)
						pointer = pointer + 3
					elseif param == "number" or param == "int" then
						table.insert(params, tonumber(res[pointer]))
						pointer = pointer + 1
					else
						table.insert(params, res[pointer])
						pointer = pointer + 1
					end
				end
				if table.unpack then
					-- lua 5.2 or later
					return sub.func(table.unpack(params))
				else
					-- lua 5.1 or earlier
					return sub.func(unpack(params))
				end
			end
		end
		return false, "Invalid command"
	end

	return cmd
end

local function run_tests()
	if not (ChatCmdBuilder.build(function(cmd)
		cmd:sub("bar :one and :two:word", function(name, one, two)
			if name == "singleplayer" and one == "abc" and two == "def" then
				return true
			end
		end)
	end)).run("singleplayer", "bar abc and def") then
		error("Test 1 failed")
	end

	local move = ChatCmdBuilder.build(function(cmd)
		cmd:sub("move :target to :pos:pos", function(name, target, pos)
			if name == "singleplayer" and target == "player1" and
					pos.x == 0 and pos.y == 1 and pos.z == 2 then
				return true
			end
		end)
	end).run
	if not move("singleplayer", "move player1 to 0,1,2") then
		error("Test 2 failed")
	end
	if not move("singleplayer", "move player1 to (0,1,2)") then
		error("Test 3 failed")
	end
	if not move("singleplayer", "move player1 to 0, 1,2") then
		error("Test 4 failed")
	end
	if not move("singleplayer", "move player1 to 0 ,1, 2") then
		error("Test 5 failed")
	end
	if not move("singleplayer", "move player1 to 0, 1, 2") then
		error("Test 6 failed")
	end
	if not move("singleplayer", "move player1 to 0 ,1 ,2") then
		error("Test 7 failed")
	end
	if not move("singleplayer", "move player1 to ( 0 ,1 ,2)") then
		error("Test 8 failed")
	end
	if move("singleplayer", "move player1 to abc,def,sdosd") then
		error("Test 9 failed")
	end
	if move("singleplayer", "move player1 to abc def sdosd") then
		error("Test 10 failed")
	end

	if not (ChatCmdBuilder.build(function(cmd)
		cmd:sub("does :one:int plus :two:int equal :three:int", function(name, one, two, three)
			if name == "singleplayer" and one + two == three then
				return true
			end
		end)
	end)).run("singleplayer", "does 1 plus 2 equal 3") then
		error("Test 11 failed")
	end

	local checknegint = ChatCmdBuilder.build(function(cmd)
		cmd:sub("checknegint :x:int", function(name, x)
			return x
		end)
	end).run
	if checknegint("checker","checknegint -2") ~= -2 then
		error("Test 12 failed")
	end

	local checknegnumber = ChatCmdBuilder.build(function(cmd)
		cmd:sub("checknegnumber :x:number", function(name, x)
			return x
		end)
	end).run
	if checknegnumber("checker","checknegnumber -3.3") ~= -3.3 then
		error("Test 13 failed")
	end

	local checknegpos = ChatCmdBuilder.build(function(cmd)
		cmd:sub("checknegpos :pos:pos", function(name, pos)
			return pos
		end)
	end).run
	local negpos = checknegpos("checker","checknegpos (-13.3,-4.6,-1234.5)")
	if negpos.x ~= -13.3 or negpos.y ~= -4.6 or negpos.z ~= -1234.5 then
		error("Test 14 failed")
	end

	local checktypes = ChatCmdBuilder.build(function(cmd)
		cmd:sub("checktypes :int:int :number:number  :pos:pos :word:word  :text:text", function(name, int, number, pos, word, text)
			return int, number, pos.x, pos.y, pos.z, word, text
		end)
	end).run
	local int, number, posx, posy, posz, word, text
	int, number, posx, posy, posz, word, text = checktypes("checker","checktypes -1 -2.4 (-3,-5.3,6.12)  some text  to finish off with")
	--dprint(int, number, posx, posy, posz, word, text)
	if int ~= -1 or number ~= -2.4 or posx ~= -3 or posy ~= -5.3 or posz ~= 6.12 or word ~= "some" or text ~= "text  to finish off with" then
		error("Test 15 failed")
	end
	dprint("All tests passed")

end
if not minetest then
	run_tests()
end
