ctf_settings.register("ctf_kill_list:tp_size", {
	type = "list",
	description = "Your texturepack's texture size. Used to scale things like kill list images",
	list = {"8x", "16x", "32x", "64x", "128x"},
	image_scale_map = {2, 1, 0.5, 0.25, 0.125},
	default = "2",
})
