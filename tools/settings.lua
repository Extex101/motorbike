local settings = {
	-- Turning speed of bike, 1 is instant
	turn_power = 0.07,
	-- Top speed the bike can go
	max_speed = 17,
	-- Top speed in reverse
	max_reverse = 5,
	acceleration = 1.5,
	-- Braking power
	braking = 5,
	stepheight = 1.3,
	-- Whether the bike is breakable
	breakable = true,
	-- Same as max_speed but on nodes like dirt, sand, gravel ect
	crumbly_speed = 7,
	-- Speed the bike can move while underwater
	underwater_speed = 3,
	-- Ability to remove the rider by punching the bike
	kick = true,
	-- Enable custom plates, requires "signs" mod
	custom_plates = true,
}



for setting, default in pairs(settings) do
	local settype = type(default)
	local value
	if settype == "boolean" then
		value = minetest.settings:get_bool("motorbike." .. setting, default)
	elseif settype == "number" then
		value = tonumber(minetest.settings:get("motorbike." .. setting)) or default
	else
		value = minetest.setting:get("motorbike." .. setting)
	end
	assert(type(value) == settype)
	biker[setting] = value
end
