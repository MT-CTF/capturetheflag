--[==[	
	Treasurer
	- A mod for Minetest
	version 0.2.0
]==]

--[=[
 	TABLE OF CONTENTS 
	part 1: Initialization
	part 2: Treasure API
	part 3: Treasure spawning mod handling
	part 4: Internal functions
]=]

--[=[
	part 1: Initialization
]=]

-- This creates the main table; all functions of this mod are stored in this table
treasurer = {}

-- Table which stores all the treasures
treasurer.treasures = {}

-- This table stores the treasures again, but this time sorted by groups
treasurer.groups = {}

-- Groups defined by the Treasurer API
treasurer.groups.treasurer = {}
treasurer.groups.treasurer.default = {}

-- Groups defined by the Minetest API
treasurer.groups.minetest = {}

--[[
format of treasure table:
	treasure = {
		name,		-- treasure name, e.g. mymod:item
		rarity,		-- relative rarity on a scale from 0 to 1 (inclusive).
				-- a rare treasure must not neccessarily be a precious treasure
		count,		-- count (see below)
		preciousness,	-- preciousness or “worth” of the treasure.
				-- ranges from 0 (“scorched stuff”) to 10 (“diamond block”)
		wear,		-- wear (see below)
		metadata,	-- unused at the moment

	}
	treasures can be nodes or items

format of count type:
	count = number			-- it’s always number times
	count = {min, max}		-- it’s pseudorandomly between min and max times, math.random() will be used to chose the value
	count = {min, max, prob_func}	-- it’s between min and max times, and the value is given by prob_func (which is not neccessarily random [in the strictly mathematical sense])

format of wear type:
	completely analogous to count type

format of prob_func function:
	prob_func = function()
	--> returns a random or pseudorandom number between 0 (inclusive) and 1 (exclusive)
	prob_func is entirely optional, if it’s not used, treasurer will default to math.random.
	You can use prob_func to define your own random function, in case you don’t like an even
	distribution 

format of treasurer_groups:
	This is just a table of strings, each string stands for a group name.
]]


--[=[
	part 2: Treasurer API
]=]

--[[
 treasurer.register_treasure - registers a new treasure
 (this means the treasure will be ready to be spawned by treasure spawning mods.

 name: name of resulting ItemStack, e.g. “mymod:item”
 rarity: rarity of treasure on a scale from 0 to 1 (inclusive). lower = rarer
 preciousness: preciousness of treasure on a scale from 0 (“scorched stuff”) to 10 (“diamond block”).
 count: optional value which specifies the multiplicity of the item. Default is 1. See count syntax help in this file.
 wear: optional value which specifies the wear of the item. Default is 0, which disables the wear. See wear syntax help in this file.
 treasurer_groups: (optional) a table of group names to assign this treasure to. If omitted, the treasure is added to the default group.
 This function does some basic parameter checking to catch the most obvious mistakes. If invalid parameters have been passed, the input is rejected and the function returns false. However, it does not cover every possible mistake, so some invalid treasures may slip through.

 returns: true on success, false on failure
]]
function treasurer.register_treasure(name, rarity, preciousness, count, wear, treasurer_groups )
	--[[ We don’t trust our input, so we first check if the parameters
	have the correct types and refuse to add the treasure if a
	parameter is malformed.
	What follows is a bunch of parameter checks.
	]]

	-- check wheather name is a string
	if type(name) ~= "string" then
		minetest.log("error","[treasure] I rejected a treasure because the name was of type \""..type(name).."\" instead of \"string\".")
		return false
	end
	-- first check if rarity is even a number
	if type(rarity) == "number" then
		-- then check wheather the rarity lies in the allowed range
		if rarity < 0 or rarity > 1 then
			minetest.log("error", "[treasurer] I rejected the treasure \""..tostring(name).."\" because it’s rarity value is out of bounds. (it was "..tostring(rarity)..".)")
			return false
		end
	else
		minetest.log("error","[treasurer] I rejected the treasure \""..tostring(name).."\" because it had an illegal type of rarity. Given type was \""..type(rarity).."\".") 
		return false
	end

	-- check if preciousness is even a number
	if type(preciousness) == "number" then
		-- then check wheather the preciousness lies in the allowed range
		if preciousness < 0 or preciousness > 10 then
			minetest.log("error", "[treasurer] I rejected the treasure \""..tostring(name).."\" because it’s preciousness value is out of bounds. (it was "..tostring(preciousness)..".)")
			return false
		end
	else
		minetest.log("error","[treasurer] I rejected the treasure \""..tostring(name).."\" because it had an illegal type of preciousness. Given type was \""..type(preciousness).."\".") 
		return false
	end


	-- first check if count is of a correct type
	if type(count) ~= "number" and type(count) ~= "nil" and type(count) ~= "table" then
		minetest.log("error", "[treasurer] I rejected the treasure \""..tostring(name).."\" because it had an illegal type of “count”. Given type was \""..type(count).."\".")
		return false
	end
	-- if count’s a table, check if it’s format is correct
	if type(count) == "table" then
		if(not (type(count[1]) == "number" and type(count[2]) == "number" and (type(count[3]) == "function" or type(count[3]) == "nil"))) then
			minetest.log("error","[treasurer] I rejected the treasure \""..tostring(name).."\" because it had a malformed table for the count parameter.")
			return false
		end
	end

	-- now do the same for wear:
	-- first check if wear is of a correct type
	if type(wear) ~= "number" and type(wear) ~= "nil" and type(wear) ~= "table" then
		minetest.log("error","[treasurer] I rejected the treasure \""..tostring(name).."\" because it had an illegal type of “wear”. Given type was \""..type(wear).."\".")
		return false
	end
	-- if wear’s a table, check if it’s format is correct
	if type(wear) == "table" then
		if(not (type(wear[1]) == "number" and type(wear[2]) == "number" and (type(wear[3]) == "function" or type(wear[3]) == "nil"))) then
			minetest.log("error","[treasurer] I rejected the treasure \""..tostring(name).."\" because it had a malformed table for the wear parameter.")
			return false
		end
	end

	-- check type of treasurer_group
	if type(treasurer_groups) ~= "table" and type(treasurer_groups) ~= "nil" and type(treasurer_groups) ~= "string" then
		minetest.log("error","[treasurer] I rejected the treasure \""..tostring(name).."\" because the treasure_group parameter is of type "..tosting(type(treasurer_groups)).." (expected: nil, string or table).")
		return false
	end




	--[[ End of checks. If we reached this point of the code, all checks have been passed
	and we finally register the treasure.]]

	-- default count is 1
	if count == nil then count = 1 end
	-- default wear is 0
	if wear == nil then wear = 0 end
	local treasure = {
		name = name,
		rarity = rarity,
		count = count,
		wear = wear,
		preciousness = preciousness,
		metadata = "",
	}
	table.insert(treasurer.treasures, treasure)

	--[[ Assign treasure to Treasurer group(s) or default if not provided ]]
	-- default Treasurer group is default
	if treasurer_groups == nil then treasurer_groups = "default" end

	if(type(treasurer_groups) == "string") then
		if(treasurer.groups.treasurer[treasurer_groups] == nil) then
			treasurer.groups.treasurer[treasurer_groups] = {}
		end
		table.insert(treasurer.groups.treasurer[treasurer_groups], treasure)
	elseif(type(treasurer_groups) == "table") then 
		for i=1,#treasurer_groups do
			-- assign to Treasurer group (create table if it does not exist yet)
			if(treasurer.groups.treasurer[treasurer_groups[i]] == nil) then
				treasurer.groups.treasurer[treasurer_groups[i]] = {}
			end
			table.insert(treasurer.groups.treasurer[treasurer_groups[i]], treasure)
		end

	end

	minetest.log("info","[treasurer] Treasure successfully registered: "..name)
	return true
end


--[=[
	part 3: Treasure spawning mod (TSM) handling
]=]

--[[
  treasurer.select_random_treasures - request some treasures from treasurer
  parameters:
    count: (optional) amount of items in the treasure. If this value is nil, treasurer assumes a default of 1.
    min_preciousness: (optional) don’t consider treasures with a lower preciousness. nil = no lower limit
    max_preciousness: (optional) don’t consider treasures with a higher preciousness. nil = no lower limit
    treasurer_groups: (optional): Only consider treasures which are members of at least one of the members of the provided Treasurer group table. nil = consider all groups
  returns: 
    a table of ItemStacks (the requested treasures) - may be empty
    on error, it returns false
]]
function treasurer.select_random_treasures(count, min_preciousness, max_preciousness, treasurer_groups)
	if #treasurer.treasures == 0 and count >= 1 then
		minetest.log("info","[treasurer] I was asked to return "..count.." treasure(s) but I can’t return any because no treasure was registered to me.")
		return {}
	end
	if count == nil then count = 1 end
	local sum = 0
	local cumulate = {}
	local randoms = {}

	-- copy treasures into helper table
	local p_treasures = {}
	if(treasurer_groups == nil) then
		-- if the group filter is not used (defaul behaviour), copy all treasures
		for i=1,#treasurer.treasures do
			table.insert(p_treasures, treasurer.treasures[i])
		end
	
	-- if the group filter IS used, copy only the treasures from the said groups
	elseif(type(treasurer_groups) == "string") then
		if(treasurer.groups.treasurer[treasurer_groups] ~= nil) then
			for i=1,#treasurer.groups.treasurer[treasurer_groups] do
				table.insert(p_treasures, treasurer.groups.treasurer[treasurer_groups][i])
			end
		else
			minetest.log("info","[treasurer] I was asked to return "..count.." treasure(s) but I can’t return any because no treasure which fits to the given Treasurer group “"..treasurer_groups.."”.")
			return {}
		end
	elseif(type(treasurer_groups) == "table") then
		for t=1,#treasurer_groups do
			if(treasurer.groups.treasurer[treasurer_groups[t]] ~= nil) then
				for i=1,#treasurer.groups.treasurer[treasurer_groups[t]] do
					table.insert(p_treasures, treasurer.groups.treasurer[treasurer_groups[t]][i])
				end
			end
		end
	else
		minetest.log("error","[treasurer] treasurer.select_random_treasures was called with a malformed treasurer_groups parameter!")
		return false
	end

	if(min_preciousness ~= nil) then
		-- filter out too unprecious treasures
		for t=#p_treasures,1,-1 do
			if((p_treasures[t].preciousness) < min_preciousness) then
				table.remove(p_treasures,t)
			end
		end
	end

	if(max_preciousness ~= nil) then
		-- filter out too precious treasures
		for t=#p_treasures,1,-1 do
			if(p_treasures[t].preciousness > max_preciousness) then
				table.remove(p_treasures,t)
			end
		end
	end

	for t=1,#p_treasures do
		sum = sum + p_treasures[t].rarity
		cumulate[t] = sum
	end
	for c=1,count do
		randoms[c] = math.random() * sum
	end

	local treasures = {}
	for c=1,count do
		for t=1,#p_treasures do
			if randoms[c] < cumulate[t] then
				table.insert(treasures, p_treasures[t])
				break
			end
		end
	end

	local itemstacks = {}
	for i=1,#treasures do
		itemstacks[i] = treasurer.treasure_to_itemstack(treasures[i])
	end
	if #itemstacks < count then
		minetest.log("info","[treasurer] I was asked to return "..count.." treasure(s) but I could only return "..(#itemstacks)..".")
	end
	return itemstacks
end

--[=[
	Part 4: internal functions
]=]

--[[ treasurer.treasure_to_itemstack - converts a treasure table to an
     ItemStack
  parameter:
    treasure: a treasure (see format in the head of this file)
  returns:
    an ItemStack
]]
function treasurer.treasure_to_itemstack(treasure)
	local itemstack = {}
	itemstack.name = treasure.name
	itemstack.count = treasurer.determine_count(treasure)
	itemstack.wear = treasurer.determine_wear(treasure)
	itemstack.metadata = treasure.metadata

	return ItemStack(itemstack)
end

--[[
  This determines the count of a treasure by taking the various different
  possible types of the count value into account
  This function assumes that the treasure table is valid.
  returns: the count
]]
function treasurer.determine_count(treasure)
	if(type(treasure.count)=="number") then
		return treasure.count
	else
		local min,max,prob = treasure.count[1], treasure.count[2], treasure.count[3]
		if(prob == nil) then
			return(math.floor(min + math.random() * (max-min)))
		else
			return(math.floor(min + prob() * (max-min)))
		end
	end
end

--[[
  This determines the wear of a treasure by taking the various different
  possible types of the wear value into account.
  This function assumes that the treasure table is valid.
  returns: the count
]]
function treasurer.determine_wear(treasure)
	if(type(treasure.wear)=="number") then
		return treasure.wear
	else
		local min,max,prob = treasure.wear[1], treasure.wear[2], treasure.wear[3]
		if(prob == nil) then
			return(math.floor(min + math.random() * (max-min)))
		else
			return(math.floor(min + prob() * (max-min)))
		end
	end
end

