
local charset = {}  do -- [A-Z]
    for c = 65, 90 do table.insert(charset, string.char(c)) end
end
local numset = {}  do -- [0-9]
    for c = 48, 57  do table.insert(numset, string.char(c)) end
end

local function randomString(length)
	local text = ""
	local i = 0
    if not length or length <= 0 then return text end
	while i < length do
		text = text..charset[math.random(1, #charset)]
		i = i + 1
	end
	return text
end

local function randomNumber(length)
	local text = ""
	local i = 0
    if not length or length <= 0 then return text end
	while i < length do
		text = text..numset[math.random(1, #numset)]
		i = i + 1
	end
	return text
end
local function def_plate() return randomString(3).."-"..randomNumber(3) end

function biker.get_plate(name)
	local custom_plates = {
		Jely = {"Jely-"..randomNumber(2), def_plate()},
		Elkien = {"Elk-"..randomNumber(3), def_plate(), "Sparks-"..randomNumber(3)},
		Bob12 = {"Bob-"..randomNumber(3), "Boi-"..randomNumber(3), "MB-"..randomNumber(4), "N1nja-"..randomNumber(3), def_plate()},
		Extex = {"Ex-"..randomNumber(4), "Bullet-"..randomNumber(2), def_plate(), "3xt3x-"..randomNumber(2)},
		Merlok = {"Mer-"..randomNumber(3), "Nipe-"..randomNumber(2), "M3RL0k-"..randomNumber(2), "N1P3-"..randomNumber(2), def_plate(), "Snoopy-"..randomNumber(3)},
		Nipe = {"Nipe-"..randomNumber(2), "Snoopy-"..randomNumber(3), def_plate()},
		--"The-Black-Knight" = {"TBK-"..randomNumber(3), "Vike-"randomNumber(2), "Rock-"..randomNumber(2), def_plate()},
		Queen_Vibe = {"QV-"..randomNumber(3), "Vibe-"..randomNumber(2), def_plate()},
		Melkor = {"Creator", "ModelKing", "Melkor", def_plate()},
		Hype = {"Hobo-"..randomNumber(2), "Hyper-"..randomNumber(1), def_plate()},
		AidanLCB = {"LCB-"..randomNumber(3), def_plate(), "Gold-"..randomNumber(3)},
		irondude = {"Iron-"..randomNumber(3), def_plate(), "Fox-"..randomNumber(3), "cndl-"..randomNumber(3)},
	}
	if custom_plates[name] then
		return custom_plates[name][math.random(#custom_plates[name])]
	end
	return def_plate()
end
player_api.register_model("motorbike_biker.b3d", {
	animation_speed = 30,
	textures = {"character.png", "blank.png"},
	animations = {
		-- Standard animations.
		stand     = {x = 0,   y = 79},
		lay       = {x = 162, y = 166},
		walk      = {x = 168, y = 187},
		mine      = {x = 189, y = 198},
		walk_mine = {x = 200, y = 219},
		sit       = {x = 81,  y = 160},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.47,
})



local function repair(num, p)
	p = p or 3
	return math.floor(num*math.pow(10,p)+0.5) / math.pow(10,p)
end
local function node_is(pos)
	local node = minetest.get_node(pos)
	if node.name == "air" then
		return "air"
	end
	if minetest.get_item_group(node.name, "liquid") ~= 0 then
		return "liquid"
	end
	if minetest.get_item_group(node.name, "walkable") ~= 0 then
		return "walkable"
	end
	if minetest.get_item_group(node.name, "crumbly") ~= 0 then
		return "crumbly"
	end
	return "other"
end
local function shortAngleDist(a0,a1)
    local max = math.pi*2
    local da = (a1 - a0) % max
    return 2*da % max - da
end
local function lerp(a, b, t)
	return a + (a - b) * t
end

local function angleLerp(a0,a1,t)
	local result = repair(a0 + shortAngleDist(a0,a1)*t)
    if math.floor(result) == a1 then
	    return a1
    end
    return result
end
local function get_sign(i)
	i = i or 0
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end

local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end
function biker.turn_check(lerp, dest, range)
	if math.floor(lerp) <= (dest-(math.rad(90)))-range then return true end
	if math.floor(lerp) >= (dest-(math.rad(90)))+range then return true end
	return false
end
function biker.clamp(value, min, max) 
    return math.min(math.max(value, min), max)
   end
function biker.dist(v1, v2)
	--if v1 - v2 > -math.rad(45) and v1 - v2 < math.rad(45) then return v1 - v2 end
	return biker.clamp(-shortAngleDist(v1, v2), math.rad(-55), math.rad(55))
end
local function force_detach(player)
	local attached_to = player:get_attach()
	if not player:is_player() then return end
	if attached_to then
		local entity = attached_to:get_luaentity()
		if entity.driver and entity.driver == player then
			entity.driver = nil
		end
		local name = player:get_player_name()
		player:set_detach()
		player:set_eye_offset({x=0, y=0, z=0}, {x=0, y=0, z=0})
		if entity.info then
			player_api.set_model(player, entity.info.model)
		end
	end
end

function biker.detach(player, crash)
	force_detach(player)
	player_api.player_attached[player:get_player_name()] = false
	player_api.set_animation(player, "stand" , 30)
	if crash then
		
	end
end

function biker.wheelspeed(bike)
	--if true then return end
	if not bike then return end
	if not bike.wheels then return end
	if not bike.object then return end
	if not bike.object:getvelocity() then return end
	local direction = 1
	if bike.v then
		direction = get_sign(bike.v)
	end
	local v = get_v(bike.object:get_velocity())
	local fps = v*4
	
	bike.object:set_animation({x=1, y=20}, fps*direction, 0, true)
	if v ~= 0 then
		local i = 16
		while true do
			if i/fps > 1 then i = i/2 else break end
		end
		minetest.after(i/fps, biker.wheelspeed, bike)
	end
end

function biker.attach(entity, player, is_passenger)
	local attach_at, eye_offset = {}, {}
	if not entity then
		return
	end
	if entity.driver then return end
	if not player:is_player() then
		return
	end
	local name = player:get_player_name()
	if not entity.driver_attach_at then
		entity.driver_attach_at = {x=0, y=1.1, z=0.9}
	end
	if not entity.driver_eye_offset then
		entity.driver_eye_offset = {x=0, y=-2.2, z=0.3}
	end 
	attach_at = entity.driver_attach_at
	eye_offset = entity.driver_eye_offset
	entity.driver = player
	local props = player:get_properties()
	entity.info = {}
	entity.info.model = player_api.get_animation(player).model
	if props.textures[2] == nil then
		props.textures[2] = "blank.png"
	end
	
	force_detach(player)

	player:set_attach(entity.object, "", attach_at, entity.player_rotation)
	player_api.player_attached[player:get_player_name()] = true
	player:set_eye_offset(eye_offset, {x=0, y=0, z=0})
	minetest.after(0.2, function()
		player_api.set_model(player, "motorbike_biker.b3d")
	end)
	player:set_look_yaw(entity.object:getyaw())
end

local timer = 0
function biker.drive(entity, dtime)
	timer = timer + dtime

	local rot_steer, rot_view = math.pi/2, 0

	local acce_y = 2

	local velo = entity.object:getvelocity()
	entity.v = get_v(velo) * get_sign(entity.v)
	-- process controls
	if entity.driver then
		if entity.v then
			local newv = entity.object:getvelocity()
			if not entity.crash then entity.crash = false end
			local crash = false
			if math.abs(entity.lastv.x) > 5 and newv.x == 0 then crash = true end
			if math.abs(entity.lastv.y) > 10 and newv.y == 0 then crash = true end
			if math.abs(entity.lastv.z) > 5 and newv.z == 0 then crash = true end
			if crash and not entity.crash then
				entity.crash = true
				minetest.after(.5, function()
					entity.crash = false
				end)
				
				return
			end
		end
		if not entity.wheelie then
			entity.wheelie = 0
		end
		if not entity.lastv then
			entity.lastv = {x=0,y=0,z=0}
		end
		local rots = entity.object:get_rotation()
		local j = rots.y
		local k = rots.x
		local newrot = j
		local rrot = entity.driver:get_look_yaw() - rot_steer
		local ctrl = entity.driver:get_player_control()
		if ctrl.up and not ctrl.sneak then
			if get_sign(entity.v) >= 0 then
				entity.v = entity.v + biker.acceleration/10
			else
				entity.v = entity.v + biker.acceleration/10
			end
		elseif ctrl.down then
			if biker.max_reverse == 0 and entity.v == 0 then return end
			if get_sign(entity.v) < 0 then
				entity.v = entity.v - biker.acceleration/10
			else
				entity.v = entity.v - biker.braking/10
			end
		end
		if ctrl.down and ctrl.sneak and not ctrl.jump and biker.turn_check(angleLerp(newrot, rrot, biker.turn_power)%math.rad(360), rrot, 3.2) then
			if get_sign(entity.v) < 0 then
				entity.v = entity.v - biker.acceleration/10
			elseif get_sign(entity.v) > 0 and entity.v > (biker.max_speed/10)-1 then
				entity.v = entity.v - biker.braking/10
				local num = 1
				local pos = entity.object:getpos()
				local d = 0.2
				for i = 0, 20, 1 do
					local time = math.random(1, 2)
					minetest.add_particle({
						pos = {x=pos.x+math.random(-d, d),y = pos.y+math.random(0, d), z= pos.z+math.random(-d, d)},
						velocity = {x=math.random(-num, num), y=math.random(0, num), z=math.random(-num, num)},
						acceleration = {x=math.random(-num, num), y=math.random(0, num), z=math.random(-num, num)},
						expirationtime = time,
						glow = 20,
						size = math.random(10, 20),
						collisiondetection = false,
						vertical = false,
						texture = "motorbike_burnout.png",
						animation = {
							type = "vertical_frames",
							aspect_w = 64,
							aspect_h = 64,
							length = time,
						},
					})
				end
			end
			
		end
		local l = rots.z
		
		if ctrl.jump and entity.v > (biker.max_speed)/3 then
			entity.driver:set_eye_offset({x=0, y=-6.0, z=0}, {x=0, y=0, z=0})
			entity.wheelie = repair(angleLerp(k, 45, 0.1))
			l = angleLerp(l, 0, 0.07)
			entity.object:set_rotation({x=repair(entity.wheelie),y=repair(j),z=repair(l,3)})
		elseif not ctrl.jump or entity.v < (biker.max_speed)/3 then
			
			entity.driver:set_eye_offset({x=0, y=-7, z=0}, {x=0, y=0, z=0})
			if entity.v > 1.2 and entity.wheelie == 0 then
				newrot = angleLerp(newrot, rrot, biker.turn_power)%math.rad(360)
				l = biker.dist(newrot+math.rad(360), rrot+math.rad(360))
			elseif entity.v < 1.2 then
				l = angleLerp(rots.z, 0, 0.2)
			end
			
			entity.wheelie = repair(angleLerp(k, 0 ,0.1))
			entity.object:set_rotation({x=entity.wheelie, y=newrot, z=repair(l,3)})
		end
		if math.abs(entity.v) < .05 and math.abs(entity.v) > 0 then
			biker.wheelspeed(entity)
		end
		if entity.lastv and vector.length(entity.lastv) == 0 and math.abs(entity.v) > 0 then
			biker.wheelspeed(entity)
		end
		if not ctrl.sneak then
			local s = get_sign(entity.v)
			entity.v = entity.v - 0.04 * s
			if s ~= get_sign(entity.v) then
				entity.object:setvelocity({x=0, y=0, z=0})
				entity.v = 0
				return
			end
		end
	elseif not entity.driver then
		entity.object:set_rotation({x=entity.object:get_rotation().x, y=entity.object:get_rotation().y, z=0})
	end
	
	-- Stop!
	if not entity.driver then
		local s = get_sign(entity.v)
		entity.v = entity.v - 0.04 * s
		if s ~= get_sign(entity.v) then
			entity.object:setvelocity({x=0, y=0, z=0})
			entity.v = 0
			return
		end
	end

	-- enforce speed limit forward and reverse
	local p = entity.object:getpos()
	local ni = node_is(p)
	local uni = node_is(vector.add(p, {x=0, y=-1, z=0}))
	--minetest.chat_send_all(node_is)
	local max_spd = biker.max_reverse
	if get_sign(entity.v) >= 0 and ni ~= "liquid" then
		if uni == "crumbly" and uni ~= "other" then
			max_spd = biker.crumbly_spd
		else
			max_spd = biker.max_speed
		end
	elseif ni == "liquid" then
		max_spd = 2
	end
	if uni == "crumbly" and uni ~= "other" then
		max_spd = biker.crumbly_spd
	end
	if math.abs(entity.v) > max_spd then
		entity.v = entity.v - get_sign(entity.v)
	end

	--Set position, velocity and acceleration	
	
	local new_velo = {x=0, y=0, z=0}
	local new_acce = {x=0, y=-9.8, z=0}

	p.y = p.y - 0.5
	
	
	new_velo = get_velocity(entity.v, entity.object:getyaw() - rot_view, velo.y)
	new_acce.y = new_acce.y + acce_y

	entity.object:setvelocity(new_velo)
	entity.object:setacceleration(new_acce)
	entity.lastv = entity.object:getvelocity()
end

minetest.register_on_leaveplayer(function(player)
	biker.detach(player)
end)
minetest.register_on_dieplayer(function(player)
	biker.detach(player)
end)
