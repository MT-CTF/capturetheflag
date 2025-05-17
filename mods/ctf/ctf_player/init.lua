-- Override player_api model
player_api.registered_models["character.b3d"] = nil

player_api.register_model("character.b3d", {
	animation_speed = 30,
	--textures={"character.png", "flagtexture",},
	textures = {"character.png", "blank.png"  ,},
	animations = {
		-- Standard animations.
		stand     = {x = 0,   y = 79},
		lay       = {x = 162, y = 166, eye_height = 0.3,
			collisionbox = {-0.6, 0.0, -0.6, 0.6, 0.3, 0.6}},
		walk      = {x = 168, y = 187},
		mine      = {x = 189, y = 198},
		walk_mine = {x = 200, y = 219},
		sit       = {x = 81,  y = 160, eye_height = 0.8,
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.0, 0.3}},
		stab      = {x = 221, y = 241, frame_loop = false},
		slash     = {x = 242, y = 262, frame_loop = false},
	},
	collisionbox = {-0.3, 0.01, -0.3, 0.3, 1.71, 0.3},
	stepheight = 0.6,
	eye_height = 1.47,
})

minetest.register_on_joinplayer(function(player)
	player:set_local_animation(nil, nil, nil, nil, 0)
end)