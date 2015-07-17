minetest.register_chatcommand("ctf_next", {
	description = "Skip to the next match",
	privs = {
		ctf_admin = true
	},
	func = function(name, param)
		ctf_match.next()
	end
})
