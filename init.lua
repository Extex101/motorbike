biker = {}
biker.signs = minetest.get_modpath("signs") and minetest.global_exists("generate_texture") and minetest.global_exists("create_line")
biker.turn_power = minetest.settings:get("motorbike.turn_power") or 0.07--Turning speed of bike 1 is instant. 0.07 is suggested
biker.max_speed = minetest.settings:get("motorbike.max_speed") or 17--Top speed the bike can go.
biker.max_reverse = minetest.settings:get("motorbike.reverse") or 5--Top speed in reverse
biker.acceleration = minetest.settings:get("motorbike.acceleration") or 1.5--Acceleration
biker.braking = minetest.settings:get("motorbike.braking") or 5--Braking power
biker.stepheight = minetest.settings:get("motorbike.stepheight") or 1.3--Bike stephight
biker.breakable = minetest.settings:get("motorbike.breakable") or true--If the bike is breakable (Citysim please change to false :)
biker.crumbly_spd = minetest.settings:get("motorbike.crumbly_spd") or 11--Same as max_speed but on nodes like dirt, sand, gravel ect
biker.kick = minetest.settings:get("motorbike.kick") or true--Ability to punch the motorbike to kick the rider off of the bike

biker.path = minetest.get_modpath("motorbike")
dofile(biker.path.."/functions.lua")

local bikelist = {"black", "blue", "brown", "cyan", 
"dark_green", "dark_grey", "green", "grey", "magenta", 
"orange", "pink", "red", "violet", "white", "yellow"}

for id, colour in pairs (bikelist) do
	minetest.register_entity("motorbike:bike_"..colour, {
		visual = "mesh",
		mesh = "motorbike_body.b3d",
		textures = {"motorbike_"..colour..".png","motorbike_"..colour..".png","motorbike_"..colour..".png","motorbike_"..colour..".png"},
		stepheight = biker.stepheight,
		physical = true,
		collisionbox = {0.5, 0.5, 0.5, -0.5, -0.83, -0.5},
		drop = "motorbike:"..colour,
		on_activate = function(self, staticdata)
			if staticdata then
				if biker.signs then
					self.platenumber = staticdata
				end
			end
			if not self.timer1 then self.timer1 = 0 end
			if not self.timer2 then self.timer2 = 0 end
			local pos = self.object:get_pos()
			self.object:set_armor_groups({fleshy=0, immortal=1})
			if biker.signs then
				minetest.after(0.1, function()
					if not self.platenumber then
						self.platenumber = biker.get_plate(self.placer)
					end
					if not self.plate then
						self.plate = minetest.add_entity(pos, "motorbike:licenseplate")
					end
					if self.plate then
						self.plate:set_attach(self.object, "", {x=-0.2, y=-1.9, z=-12.2}, {x=0, y=0, z=0})
					end
				end)
			end
			biker.wheelspeed(self)
		end,
		on_rightclick = function(self, clicker)
			local name = clicker:get_player_name()
			if not self.driver then
				biker.attach(self, clicker, false)
				return
			end
			if self.driver then
				biker.detach(clicker, {x=0.5, y=0, z=0.5})
				return
			end
		end,
		on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
			if biker.breakable then
				if puncher:is_player() and not self.driver then
					local pos = self.object:get_pos()
					local new_pos = {x=pos.x, y=pos.y+1, z=pos.z}
					local item = minetest.add_item(pos, ItemStack(self.drop))
					if item then
						self.object:remove()
						if self.plate then
							self.plate:remove()
						end
					end
				end
			end
			if biker.kick then
				if self.driver and puncher:get_player_name() ~= self.driver:get_player_name() then
					if (puncher:get_wielded_item():get_name() == "") and (time_from_last_punch >= tool_capabilities.full_punch_interval) and math.random(1,2) == 1 then
						biker.detach(self.driver)
					end
				end
			end
		end,
		on_step = function(self, dtime)
			local pos = self.object:get_pos()
			local node = minetest.get_node(pos)
			biker.drive(self, dtime)
		end,
		get_staticdata = function(self)
			if biker.signs then
				return self.platenumber
			end
		end,
	})
	minetest.register_craftitem("motorbike:"..colour, {
		description = colour:gsub("^%l", string.upper):gsub("_", " ").." bike",
		inventory_image = "motorbike_"..colour.."_inv.png",
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return
			end
			local pos = {x=pointed_thing.above.x, y=pointed_thing.above.y+1, z=pointed_thing.above.z}
			local bike = minetest.add_entity(pos, "motorbike:bike_"..colour, biker.get_plate(placer:get_player_name()))
			local ent = bike:get_luaentity()
			bike:set_yaw(placer:get_look_horizontal())
			itemstack:take_item()
			return itemstack
		end,
	})
	minetest.register_craft({
		output = "motorbike:"..colour,
		recipe = {
			{"","","default:stick"},
			{"default:steel_ingot","default:mese_crystal","default:steel_ingot"},
			{"motorbike:wheel","wool:"..colour, "motorbike:wheel"},
		}
	})
end
minetest.register_craftitem("motorbike:wheel", {
	description = "Motorbike Wheel",
	inventory_image = "motorbike_wheel_inv.png",
})
minetest.register_craft({
	output = "motorbike:wheel",
	recipe = {
		{"default:obsidian_shard","default:obsidian_shard","default:obsidian_shard"},
		{"default:obsidian_shard","default:steel_ingot","default:obsidian_shard"},
		{"default:obsidian_shard","default:obsidian_shard","default:obsidian_shard"}
	}
})
if biker.signs then
	minetest.register_entity("motorbike:licenseplate", {
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		visual = "upright_sprite",
		textures = {"blank.png"},
		visual_size = {x=0.7, y=0.7, z=0.7},
		physical = false,
		pointable = false,
		collide_with_objects = false,
		on_activate = function(self)
			minetest.after(0.2, function()
				if not self.object:get_attach() then
					self.object:remove()
				else
					self.object:set_armor_groups({immortal = 1})
					local text = self.object:get_attach():get_luaentity().platenumber
					if not text then return end
					self.object:set_properties({textures={generate_texture(create_lines(text))}})
				end
			end)
		end
	})
end
