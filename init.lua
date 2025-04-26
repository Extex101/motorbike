biker = {}
biker.path = minetest.get_modpath("motorbike")
biker.signs = (minetest.get_modpath("signs") and minetest.global_exists("generate_texture") and minetest.global_exists("create_lines"))
local tools = dofile(biker.path .. "/tools/init.lua")

local def = {
    initial_properties = {
        visual = "mesh",
        mesh = "motorbike_body.b3d",
        textures = {"motorbike_blue.png"},
        stepheight = biker.stepheight,
        physical = true,
        backface_culling = false,
        collisionbox = {
            0.2,
            0.2,
            0.2,
            -0.2,
            -0.83,
            -0.2
        },
        selectionbox = {
            0.4,
            0.4,
            0.4,
            -0.4,
            -0.83,
            -0.4
        },
    },
}

function def.on_activate (self, staticdata)
    if staticdata and biker.signs then
        self.platenumber = staticdata
        local pos = self.object:get_pos()
        self.plate = minetest.add_entity(pos, "motorbike:licenseplate")
        if self.plate then
            self.plate:set_attach(self.object, "", { x = -0.1, y = -2.15, z = -10.7 }, { x = 0, y = 0, z = 0 })
        end
    end
    self.timer = 0
    self.gravity = 0
    self.vel = 0
    self.preVel = 0
    self.wheelie = 0
    self.angle = self.object:get_rotation()
    self.object:set_armor_groups{ immortal = 1 }
	self.object:set_animation({ x = 1, y = 19 }, 0, 0, true)
    self:wheelspeed(self)
end

function def.on_rightclick (self, clicker)
    if not self.driver then
        if clicker:get_attach() then
            return
        end
        biker.attach(self, clicker, false)
        minetest.sound_play("motorbike_start", {
            max_hear_distance = 24,
            gain = 1,
            object = self.object,
        })
        return
    end
    if self.driver and self.driver:get_player_name() == clicker:get_player_name() then
        biker.detach(clicker)
    end
end

function def.on_punch (self, puncher, time_from_last_punch, tool_capabilities, _dir)
    if not puncher:is_player() then
        return
    end
    if not self.driver then
        if biker.breakable then
            local stack = ItemStack(self.drop)
            local pinv = puncher:get_inventory()
            if not pinv:room_for_item("main", stack) then
                minetest.add_item(self.object:get_pos(), self.drop)
            else
                pinv:add_item("main", stack)
            end
            self.object:remove()
            if self.plate then self.plate:remove() end
        end
        return
    end
    if biker.kick and puncher:get_player_name() ~= self.driver:get_player_name() and puncher:get_wielded_item():get_name() == "" and time_from_last_punch >= tool_capabilities.full_punch_interval and math.random(1, 2) == 1 then
        biker.detach(self.driver)
    end
end

if biker.signs then
    function def.get_staticdata (self)
        return self.platenumber
    end

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

function def.wheelspeed (self)
    local fps = self.vel * 4
    self.object:set_animation_frame_speed(fps)
end

function def.controls(self)
    local driver = self.driver
    local controls = driver:get_player_control()
    local look = self.driver:get_look_horizontal()

    local max_speed = biker.max_speed

    local pos = vector.floor( vector.add( self.object:get_pos(), 0.5) )

    if tools.under(pos) == "crumbly" then
        max_speed = biker.crumbly_speed
    end

    if tools.node_is(pos) == "liquid" then
        max_speed = biker.underwater_speed
    end

    --Tilt Controls--------------------------------------------

    --up
    if controls.sneak then
        --When not sneaking: Sustain
    else--
        self.vel = math.min(self.vel, max_speed) -- Limit velocity to max speed

        if controls.up and self.vel <= max_speed then -- While pressing forward and while less than max

            self.preVel = self.vel -- update cached velocity
            self.vel = self.vel + biker.acceleration / 10 -- increase speed

        elseif controls.down and self.vel > -biker.max_reverse then
            -- When pressing back:
            self.preVel = self.vel
            if self.vel >= 0 then
                -- Apply brakes
                self.vel = self.vel - biker.braking / 10
            elseif self.vel < 0 then
                -- Apply reverse acceleration
                self.vel = self.vel - biker.acceleration / 10
            end
        end
    end

    --When not doing a wheelie, rotate the bike towards the look direction
    local turn_power = tools.mapTurn(self.vel, 1, -1, 4, biker.turn_power)

    local newLook = tools.angleLerp(self.angle.y, look, turn_power) % math.rad(360)

    if controls.jump and self.vel > 3 then
        self.wheelie = tools.angleLerp(self.wheelie, math.rad(65), 0.07)
        self.angle.z = tools.angleLerp(self.angle.z, 0, 0.1)
    else
        if self.wheelie > math.rad(1) then
            self.wheelie = tools.angleLerp(self.wheelie, 0, 0.09)
        else
            self.wheelie = 0
        end


        self.angle.z = tools.dist(self.angle.y + math.rad(360), newLook + math.rad(360)) * self.vel

        self.angle.y = newLook


        if self.vel <= 1 then
            self.angle.z = tools.angleLerp(self.angle.z, 0, 0.2)
        end
    end
    if not controls.up and not controls.down and not controls.shift then
        if self.vel ~= 0 then
            self.vel = self.vel - 0.01 * tools.get_sign(self.vel)
        end
    end


    if controls.sneak and controls.down and
    not controls.jump and tools.turn_check(newLook, look, 3.2) and
    tools.get_sign(self.vel) > 0 and self.vel > (biker.max_speed/10)-1 then

        self.vel = self.vel - biker.braking / 3 --Slow down
        if not self.playSound then
            minetest.sound_play("motorbike_screech", {--Play the sound
                max_hear_distance = 48,
                gain = 0.3,
                object = self.object,
            })
            self.playSound = true
        end

        for i = 0, 20 do
            local time = math.random(1, 2)
            minetest.add_particle({
                pos = {x=pos.x+math.random(-0.2, 0.2),y = pos.y+math.random(0, 0.2), z= pos.z+math.random(-0.2, 0.2)},
                velocity = {x=math.random(-1, 1), y=math.random(0, 1), z=math.random(-1, 1)},
                acceleration = {x=math.random(-1, 1), y=math.random(0, 1), z=math.random(-1, 1)},
                expirationtime = time,
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
    else
        self.playSound = false
    end

    self.angle = {
        x = self.wheelie,
        y = self.angle.y,
        z = tools.clamp(self.angle.z, math.rad(-45), math.rad(45))
    }
end

function def.play_sounds(self, dtime)
	-- sound
    if self.driver and math.floor(self.vel*2) ~= 0 then
		self.timer = self.timer + dtime
		if self.timer > 0.1 then
            local s = biker.max_speed / 2
			local rpm = math.abs(self.vel/s)

			minetest.sound_play("motoengine", {
                max_hear_distance = 48,
                pitch = rpm + 0.1,
                gain = 0.3,
                object = self.object
            })
			self.timer = 0
		end
	end
end

function def.on_step (self, dtime)

    local velocity = self.object:get_velocity()
    local pos = self.object:get_pos()
    local under = tools.under(pos)

    self:play_sounds(dtime)
    if under == "air" then
        self.gravity = self.gravity + (9.8 * dtime)
    elseif velocity.y == 0 then
        self.gravity = 0
    end
    -- process controls
    if self.driver and self.driver:is_player() then

        --Check if driver dismounted by unexpected means
        local foundDriver = false
        for _, child in ipairs(self.object:get_children()) do
            if self.driver and child:is_player() and child:get_player_name() == self.driver:get_player_name() then
                foundDriver = true
            end
        end

        --If driver is no longer attached then remove it from bike memory
        if not foundDriver then
            self.driver = nil
            return
        end
        if not under ~= "liquid" then--Disable controls while sinking in water
            self:controls(self)
        end
    else
        if self.angle.z ~= 0 or self.angle.x ~= 0 then
            self.angle.z = 0
            self.angle.x = 0
        end
        -- Gradually slow it down
        if self.vel ~= 0 then
            self.vel = self.vel - 0.02 * tools.get_sign(self.vel)
        end
    end

    if self.nvel then--Crash
        if tools.get_speed(velocity) < tools.get_speed(self.nvel)/2 then
            self.preVel = self.vel
            self.vel = 0
        end
    end
    self.nvel = velocity



    local rotvel = vector.rotate({x = 0, y = 0, z = self.vel}, {x=0, y=self.angle.y, z=0})
    rotvel.y = rotvel.y - self.gravity
    if under == "liquid" then
        rotvel.y = -2
    end

    local angle = vector.dir_to_rotation(rotvel)
    self:wheelspeed(self)
    self.object:set_rotation(self.angle)
    self.object:set_velocity(rotvel)
end

local bikeColors = {
    "black",
    "blue",
    "brown",
    "cyan",
    "dark_green",
    "dark_grey",
    "green",
    "grey",
    "magenta",
    "orange",
    "pink",
    "red",
    "violet",
    "white",
    "yellow"
}

for index, col in ipairs(bikeColors) do
    local newDef = tools.deepcopy(def)
    newDef.initial_properties.textures = {"motorbike_"..col..".png", "motorbike_"..col..".png", "motorbike_"..col..".png"}
    newDef.drop = "motorbike:"..col
    minetest.register_entity("motorbike:"..col, newDef)

    minetest.register_craftitem("motorbike:"..col, {
        description = "Motorbike\n"..minetest.colorize(col:gsub("_", ""), col:gsub("^%l", string.upper):gsub("_", " ")),
        inventory_image = "motorbike_"..col.."_inv.png",
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then return end
            local pos = { x = pointed_thing.above.x, y = pointed_thing.above.y + 1, z = pointed_thing.above.z }
            local bike = minetest.add_entity(pos, "motorbike:"..col, tools.get_plate(placer:get_player_name()))
            bike:get_luaentity().angle.y = placer:get_look_horizontal()
            itemstack:take_item(1)
            return itemstack
        end
    })
    minetest.register_craft{
    	output = "motorbike:"..col,
    	recipe = {
    		{ "", "", "default:stick" },
    		{ "default:steel_ingot", "wool:"..col, "default:steel_ingot" },
    		{ "motorbike:wheel", "default:mese_crystal", "motorbike:wheel" }
    	}
    }
end
minetest.register_craftitem("motorbike:wheel", { description = "Motorbike Wheel", inventory_image = "motorbike_wheel_inv.png" })
minetest.register_craft{
	output = "motorbike:wheel",
	recipe = {
		{ "default:obsidian_shard", "default:obsidian_shard", "default:obsidian_shard" },
		{ "default:obsidian_shard", "default:steel_ingot", "default:obsidian_shard" },
		{ "default:obsidian_shard", "default:obsidian_shard", "default:obsidian_shard" }
	}
}



minetest.register_on_leaveplayer(function(player) tools.force_detach(player, true) end)
minetest.register_on_dieplayer(biker.detach)
