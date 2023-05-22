local tools = {}

function tools.random_string(length, charcode_start, charcode_end)
	local text = ""
	if length <= 0 then return text end
	for _ = 1, length do
		text = text .. string.char(math.random(charcode_start, charcode_end))
	end
	return text
end

function tools.random_letters(length)
	-- 65 - 90 is the ASCII range for A-Z
	return tools.random_string(length, 65, 90)
end

function tools.random_digits(length)
	-- 48 - 57 is the ASCII range for 0-9
	return tools.random_string(length, 48, 57)
end

function tools.license_plate() return tools.random_letters(3) .. "-" .. tools.random_digits(3) end

function tools.get_plate(name)
	-- TODO make configurable
	local custom_plates = {
		Jely = { "Jely-" .. tools.random_digits(2), tools.license_plate() },
		Elkien = { "Elk-" .. tools.random_digits(3), tools.license_plate(), "Sparks-" .. tools.random_digits(3) },
		Bob12 = {
			"Bob-" .. tools.random_digits(3),
			"Boi-" .. tools.random_digits(3),
			"MB-" .. tools.random_digits(4),
			"N1nja-" .. tools.random_digits(3),
			tools.license_plate()
		},
		Extex = {
			"Ex-" .. tools.random_digits(4),
			"Bullet-" .. tools.random_digits(2),
			tools.license_plate(),
			"3xt3x-" .. tools.random_digits(2)
		},
		Merlok = {
			"Mer-" .. tools.random_digits(3),
			"Nipe-" .. tools.random_digits(2),
			"M3RL0k-" .. tools.random_digits(2),
			"N1P3-" .. tools.random_digits(2),
			tools.license_plate(),
			"Snoopy-" .. tools.random_digits(3)
		},
		Nipe = { "Nipe-" .. tools.random_digits(2), "Snoopy-" .. tools.random_digits(3), tools.license_plate() },
		Queen_Vibe = { "QV-" .. tools.random_digits(3), "Vibe-" .. tools.random_digits(2), tools.license_plate() },
		Melkor = {
			"Creator",
			"ModelKing",
			"Melkor",
			tools.license_plate()
		},
		Hype = { "Hobo-" .. tools.random_digits(2), "Hyper-" .. tools.random_digits(1), tools.license_plate() },
		AidanLCB = { "LCB-" .. tools.random_digits(3), tools.license_plate(), "Gold-" .. tools.random_digits(3) },
		irondude = {
			"Iron-" .. tools.random_digits(3),
			tools.license_plate(),
			"Fox-" .. tools.random_digits(3),
			"cndl-" .. tools.random_digits(3)
		}
	}
	if custom_plates[name] and biker.custom_plates then
		return custom_plates[name][math.random(#custom_plates[name])]
	end
	return tools.license_plate()
end

function tools.node_is(pos)
	local nodename = minetest.get_node(pos).name
	local def = minetest.registered_nodes[nodename]
	if def then
		if not def.walkable then
			if minetest.get_item_group(nodename, "liquid") ~= 0 then
				return "liquid"
			end
			return "air"
		end
		if minetest.get_item_group(nodename, "crumbly") ~= 0 then
			return "crumbly"
		end
	end

	return "other"
end

function tools.under(pos)
	return tools.node_is(vector.floor( vector.add( {x=pos.x, y=pos.y-1, z=pos.z}, 0.5) ))
end

function tools.shortAngleDist(a0, a1)
	local max = math.pi * 2
	local da = (a1 - a0) % max
	return 2 * da % max - da
end

local function repair(num, p)
	p = p or 3
	return math.floor(num * math.pow(10, p) + 0.5) / math.pow(10, p)
end

function tools.angleLerp(a0, a1, t)
	local result = repair(a0 + tools.shortAngleDist(a0, a1) * t)
	if math.floor(result) == a1 then return a1 end
	return result
end

function tools.get_sign(x)
	return x>0 and 1 or x<0 and -1 or 0
end

function tools.get_speed(velocity)
	return math.sqrt(velocity.x ^ 2 + velocity.z ^ 2)
end

function tools.turn_check(lerp, dest, range)
	if math.floor(lerp) <= dest - math.rad(90) - range then return true end
	if math.floor(lerp) >= dest - math.rad(90) + range then return true end
	return false
end

function tools.clamp(value, min, max) return math.min(math.max(value, min), max) end

function tools.dist(v1, v2)
	-- if v1 - v2 > -math.rad(45) and v1 - v2 < math.rad(45) then return v1 - v2 end
	return tools.clamp(-tools.shortAngleDist(v1, v2), math.rad(-55), math.rad(55))
end

function tools.force_detach(player, leave)
	local attached_to = player:get_attach()
	if not player:is_player() then return end
	if attached_to then
		local entity = attached_to:get_luaentity()
		assert(entity.driver == player)
		entity.driver = nil
		player:set_detach()
		player:set_eye_offset({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
		if entity.info and not leave then player_api.set_model(player, entity.info.model) end
	end
end

function tools.rotator(origin_y, floor_y, length, angle)--Maybe a future feature
	-- Beautifully small and compact!
	local floorY = floor_y - origin_y
	-- To the mathematician who invented Arcsine. I am eternally grateful.
	local result = math.asin(floorY / length)
	return result
end

function tools.point(pos, angle, vec)
	local edge = vector.rotate(vec, angle)
	return vector.add(pos, edge)
end

local function get_above(pos)
	local next = vector.round(pos)
	local above = tools.node_is(next)
	local n = 0
	while above ~= "air" and above ~= "other" do
		next.y = next.y + 1
		above = tools.node_is(next)
		n = n + 1
		if n > 4 then
			return n
		end
	end
	return n
end

function tools.tip(self, offset)
	local pos = self.object:get_pos()
  local corner = tools.point(pos, self.angle, offset)
  minetest.add_particle({
    pos = corner,
    texture = "dev_part.png",
    time = 2,
    glow = 10,
  })

	if get_above(corner) > 1 then return end

  local node = minetest.get_node_or_nil(corner)
  if node then
    local def = minetest.registered_nodes[node.name]
    if def and def.walkable and node.name ~= "air" then
      return tools.rotator(pos.y+offset.y, math.floor(corner.y+0.5)+0.5, offset.z)
    end
  end
	return false
end

local function map(num, in_min, in_max, out_min, out_max)
	return (num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function tools.mapTurn(vel, sub, min, max, max_power)
	local num = math.min(math.max(vel-sub-max, min-max), max-max)+max
	return map(num, min, max, 0, max_power)
end

function tools.deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[tools.deepcopy(orig_key, copies)] = tools.deepcopy(orig_value, copies)
            end
            setmetatable(copy, tools.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return tools
