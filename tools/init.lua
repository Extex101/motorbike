dofile(biker.path .. "/tools/settings.lua")
local tools = dofile(biker.path .. "/tools/helpers.lua")
dofile(biker.path .. "/tools/functions.lua")


player_api.register_model("motorbike_biker.b3d", {
	textures = { "character.png", "blank.png" },
	animations = {},
	collisionbox = {
		-0.3,
		0,
		-0.3,
		0.3,
		1.7,
		0.3
	},
	stepheight = 0.6,
	eye_height = 1.4699999999
})

return tools
