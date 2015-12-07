minetest.register_privilege("ctf_match", {
	description = "can skip matches"
})

minetest.register_chatcommand("ctf_next", {
	description = "Skip to the next match",
	privs = {
		ctf_match = true
	},
	func = function(name, param)
		ctf_match.next()
	end
})
