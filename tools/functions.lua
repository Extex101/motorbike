local tools = dofile(biker.path .. "/tools/helpers.lua")
function biker.detach(player)
	tools.force_detach(player)
	player_api.player_attached[player:get_player_name()] = false
	player_api.set_animation(player, "stand", 30)
end

function biker.attach(entity, player)--Clean this up
	local attach_at, eye_offset = {}, {}
	if not entity then return end
	if entity.driver then return end
	if not player:is_player() then return end
	if not entity.driver_attach_at then entity.driver_attach_at = { x = 0, y = 0.0, z = 0 } end
	if not entity.driver_eye_offset then entity.driver_eye_offset = { x = 0, y = -5.9, z = 0 } end--6.7
	attach_at = entity.driver_attach_at
	eye_offset = entity.driver_eye_offset
	entity.driver = player
	local props = player:get_properties()
	entity.info = {}
	entity.info.model = player_api.get_animation(player).model
	if props.textures[2] == nil then props.textures[2] = "blank.png" end
	tools.force_detach(player)
	player:set_attach(entity.object, "", attach_at, entity.player_rotation)
	player_api.player_attached[player:get_player_name()] = true
	player_api.set_model(player, "motorbike_biker.b3d")
	player:set_eye_offset(eye_offset, { x = 0, y = -10, z = 0 })
	player:set_look_horizontal(entity.object:get_yaw())
end
