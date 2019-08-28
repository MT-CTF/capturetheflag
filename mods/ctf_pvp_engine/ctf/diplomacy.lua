-- diplo states: war, peace, alliance
ctf.diplo = {
	diplo = {}
}

ctf.register_on_load(function(table)
	ctf.diplo.diplo = table.diplo
end)

function ctf.diplo.get(one,two)
	return "war"
end
