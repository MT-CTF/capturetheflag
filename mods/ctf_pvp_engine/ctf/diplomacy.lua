-- diplo states: war, peace, alliance
ctf.diplo = {
	diplo = {}
}

ctf.register_on_load(function(table)
	ctf.diplo.diplo = table.diplo
end)

ctf.register_on_save(function()
	return { diplo = ctf.diplo.diplo }
end)

function ctf.diplo.get(one,two)
	if not ctf.diplo.diplo then
		return ctf.setting("default_diplo_state")
	end

	for i = 1, #ctf.diplo.diplo do
		local dip = ctf.diplo.diplo[i]
		if (dip.one == one and dip.two == two) or
				(dip.one == two and dip.two == one) then
			return dip.state
		end
	end

	return ctf.setting("default_diplo_state")
end

function ctf.diplo.set(one, two, state)
	if ctf.diplo.diplo then
		-- Check the table for an existing diplo state
		for i = 1, #ctf.diplo.diplo do
			local dip = ctf.diplo.diplo[i]
			if (dip.one == one and dip.two == two) or
					(dip.one == two and dip.two == one) then
				dip.state = state
				return
			end
		end
	else
		ctf.diplo.diplo = {}
	end

	table.insert(ctf.diplo.diplo,{one=one,two=two,state=state})
end

function ctf.diplo.check_requests(one, two)
	local team = ctf.team(two)

	if not team.log then
		return nil
	end

	for i=1,#team.log do
		if team.log[i].team == one and
				team.log[i].type == "request" and
				team.log[i].mode == "diplo" then
			return team.log[i].msg
		end
	end

	return nil
end

function ctf.diplo.cancel_requests(one, two)
	local team = ctf.team(two)

	if not team.log then
		return
	end

	for i=1,#team.log do
		if team.log[i].team == one and
				team.log[i].type == "request" and
				team.log[i].mode == "diplo" then
			table.remove(team.log,i)
			return
		end
	end

	return
end
