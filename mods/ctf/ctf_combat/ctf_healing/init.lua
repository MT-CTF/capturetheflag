ctf_healing = {}

ctf_core.include_files("bandage.lua")

ctf_healing.registered_on_heal = {}
---@param func function
--- Passed params: player, patient, amount
function ctf_healing.register_on_heal(func, load_first)
	if load_first then
		table.insert(ctf_healing.registered_on_heal, 1, func)
	else
		table.insert(ctf_healing.registered_on_heal, func)
	end
end
