pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- vector
-- by ooooggll
-- made for ccmas 2025

-- based on evercore+ V2.0.1

devmode = false

function vector(x, y)
	return {x = x, y = y}
end

function rectangle(x, y, w, h)
	return {x = x, y = y, w = w, h = h}
end

function params(n)
	return unpack(split(n))
end

-- global tables
objects, got_fruit = {}, {}
-- global timers
freeze, delay_restart, sfx_timer, music_timer, ui_timer = 0, 0, 0, 0,  - 99
-- global camera values
draw_x, draw_y, cam_x, cam_y, cam_spdx, cam_spdy, cam_gain = 0, 0, 0, 0, 0, 0, 0.25

-- [entry point]

function _init()
	frames, start_game_flash = 0, 0
	music(40, 0, 7)
	lvl_id = 0
end

function begin_game()
	max_djump = 1
	deaths, frames, seconds, minutes, music_timer, time_ticking, fruit_count, bg_col, cloud_col = 0, 0, 0, 0, 0, true, 0, 0, 1
	music(0, 0, 7)
	load_level(1)
end

function is_title()
	return lvl_id == 0
end

-- [effects]

clouds = {}
for i = 0, 16 do
	add(clouds, {
		x = rnd"128", 
		y = rnd"128", 
		spd = 1 + rnd"4", 
		w = 32 + rnd"32"})
end

particles = {}
for i = 0, 24 do
	add(particles, {
		x = rnd"128", 
		y = rnd"128", 
		s = flr(rnd"1.25"), 
		spd = 0.25 + rnd"5", 
		off = rnd(), 
		c = 6 + rnd"2", 
	})
end

dead_particles = {}

-- [function library]

function psfx(num)
	if sfx_timer <= 0 then
		sfx(num)
	end
end

function round(x)
	return flr(x + 0.5)
end

function appr(val, target, amount)
	return val > target and max(val - amount, target) or min(val + amount, target)
end

function sign(v)
	return v ~= 0 and sgn(v) or 0
end

function two_digit_str(x)
	return x < 10 and "0"..x or x
end

function tile_at(x, y)
	return mget(lvl_x + x, lvl_y + y)
end

function spikes_at(x1, y1, x2, y2, xspd, yspd)
 for i = max(0, x1 \ 8), min(lvl_w - 1, x2 / 8) do
  for j = max(0, y1 \ 8), min(lvl_h - 1, y2 / 8) do
   if({[59] = y2 % 8 >= 6 and yspd >= 0, 
     [44] = y1 % 8 <= 2 and yspd <= 0, 
     [43] = x1 % 8 <= 2 and xspd <= 0, 
     [60] = x2 % 8 >= 6 and xspd >= 0})[tile_at(i, j)] then
      return true
   end
  end
 end
end
-->8
-- [update loop]

function _update()
	frames += 1
	if time_ticking then
		seconds += frames \ 30
		minutes += seconds \ 60
		seconds %= 60
	end
	frames %= 30

	if music_timer > 0 then
		music_timer -= 1
		if music_timer <= 0 then
			music(10, 0, 7)
		end
	end

	if sfx_timer > 0 then
		sfx_timer -= 1
	end

	-- cancel if freeze
	if freeze > 0 then
		freeze -= 1
		return
	end

	-- restart (soon)
	if delay_restart > 0 then
		cam_spdx, cam_spdy = 0, 0
		delay_restart -= 1
		if delay_restart == 0 then
			load_level(lvl_id)
		end
	end

	-- update each object
	foreach(objects, function(obj)
		obj.move(obj.spd.x, obj.spd.y, 0);
		obj:update()
	end)

	-- move camera to player
	foreach(objects, function(obj)
		if obj.type == player or obj.type == player_spawn then
			move_camera(obj)
		end
	end)

	-- start game
	if is_title() then
		if start_game then
			start_game_flash -= 1
			if start_game_flash <= -30 then
				begin_game()
			end
		elseif btn(🅾️) or btn(❎) then
			music"-1"
			start_game_flash, start_game = 50, true
			sfx"38"
		elseif btnp(⬆️, 1) and devmode then
			begin_game()
		end
	else
		if btnp(⬆️, 1) and devmode then
			next_level()
		end
	end
end
-->8
-- [draw loop]

function _draw()
	if freeze > 0 then
		return
	end

	-- reset all palette values
	pal()

	-- start game flash
	if is_title() then
		if start_game then
			for i = 1, 15 do
				pal(i, start_game_flash <= 10 and ceil(max(start_game_flash) / 5) or frames % 10 < 5 and 7 or i)
			end
		end

		cls()

		-- credits
		spr(params"73, 36, 32, 7, 4")
		?params"🅾️/❎, 55, 80, 5"
		?params"mod by ooooggll, 36, 94, 6"
  ?params"maddy thorson, 40, 104, 5"
  ?params"noel berry, 46, 110, 5"
		
		-- particles
		foreach(particles, draw_particle)

		return
	end

	-- draw bg color
	cls(flash_bg and frames / 5 or bg_col)

	-- bg clouds effect
	foreach(clouds, function(c)
		c.x += c.spd - cam_spdx
		rectfill(c.x, c.y, c.x + c.w, c.y + 16 - c.w * 0.1875, cloud_col)
		if c.x > 128 then
			c.x = -c.w
			c.y = rnd"120"
		end
	end)

	-- set cam draw position
	draw_x = round(cam_x) - 64
	draw_y = round(cam_y) - 64
	camera(draw_x, draw_y)

	-- draw bg terrain
	map(lvl_x, lvl_y, 0, 0, lvl_w, lvl_h, 4)
	
	-- set draw layering
	-- positive layers draw after player
	-- layer 0 draws before player, after terrain
	-- negative layers draw before terrain
	local pre_draw, post_draw = {}, {}
	foreach(objects, function(obj)
		local draw_grp = obj.layer < 0 and pre_draw or post_draw
		for k, v in ipairs(draw_grp) do
			if obj.layer <= v.layer then
				add(draw_grp, obj, k)
				return
			end
		end
		add(draw_grp, obj)
	end)

	-- draw bg objects
	foreach(pre_draw, draw_object)
	
	-- draw terrain
	map(lvl_x, lvl_y, 0, 0, lvl_w, lvl_h, 2)
	
	-- draw fg objects
	foreach(post_draw, draw_object)

	-- draw jumpthroughs
	map(lvl_x, lvl_y, 0, 0, lvl_w, lvl_h, 8)

	-- particles
	foreach(particles, draw_particle)

	-- dead particles
	foreach(dead_particles, function(p)
   p.x += p.dx / 2
   p.y += p.dy / 2
   p.t -= 0.1
   if p.t <= 1 then
     del(dead_particles, p)
   end
   circfill(p.x - p.t, p.y - p.t, p.t + 1, p.t > 1.5 and 8 or 14)
 end)

	-- draw level title
	camera()
	if ui_timer >= -30 then
		if ui_timer < 0 then
			draw_ui()
		end
		ui_timer -= 1
	end
	
	-- dash puzzle arrows
	for i, dir in pairs(puzzle) do
		for x = -1, 1 do
			for y = -1, 1 do
				if x != 0 or y != 0 then
					draw_arrow(dir, i * 10 - 8 + x, 120 + y, 1)
				end
			end
		end
		local c = i <= puzzle_index and 12 or 7
		if (puzzle_incorrect and i == puzzle_index) c = 8
		if (puzzle_solved) c = 11
		draw_arrow(dir, i * 10 - 8, 120, c)
	end
end

function draw_particle(p)
	p.x += p.spd - cam_spdx
	p.y += sin(p.off) - cam_spdy
	p.off += min(0.05, p.spd / 32)
	rectfill(p.x + draw_x, p.y % 128 + draw_y, p.x + p.s + draw_x, p.y % 128 + p.s + draw_y, p.c)
	if p.x > 132 then
		p.x = -4
		p.y = rnd"128"
	elseif p.x < -4 then
		p.x = 128
		p.y = rnd"128"
	end
end

function draw_time(x, y)
	rectfill(x, y, x + 32, y + 6, 0)
	?two_digit_str(minutes \ 60) .. ":" .. two_digit_str(minutes % 60) .. ":" .. two_digit_str(seconds), x + 1, y + 1, 7
end

function draw_ui()
	rectfill(params"24, 58, 104, 70, 0")
	local title = lvl_title or lvl_id .. "00 m"
	?title, 64 - #title * 2, 62, 7
	draw_time(4, 4)
end

function draw_arrow(dir, x, y, c)
	local hflip, vflip, sprite = false, false, 37
	
	if dir == "l" then
		-- default settings
	elseif dir == "r" then
		hflip = true
	elseif dir == "u" then
		sprite = 38
		vflip = true
	elseif dir == "d" then
		sprite = 38
	else
		sprite = 39
		local char1 = sub(dir, 1, 1)
		local char2 = sub(dir, 2, 2)
	
		if (char2 == "r") hflip = true
		if (char1 == "d") vflip = true
	end
	
	pal(12, c or 12)
	
	spr(sprite, x, y, 1, 1, hflip, vflip)

	pal(12, 12)
end
-->8
-- [player class]

player = {
	layer = 1,
	collides = true
}
function player:init()
 self.grace, self.jbuffer = 0, 0
 self.djump = max_djump
 self.dash_time, self.dash_effect_time = 0, 0
 self.dash_target_x, self.dash_target_y = 0, 0
 self.dash_accel_x, self.dash_accel_y = 0, 0
 self.hitbox = rectangle(params"1, 3, 6, 5")
 self.spr_off = 0
end
function player:update()
 if pause_player then
  return
 end

 -- horizontal input
 local h_input = btn(➡️) and 1 or btn(⬅️) and -1 or 0

 -- spike collision / bottom death
 if spikes_at(self.left(), self.top(), self.right(), self.bottom(), self.spd.x, self.spd.y) or self.y > lvl_ph then
  kill_player(self)
 end

 -- on ground checks
 local on_ground = self.is_solid(0, 1)

 -- landing smoke
 if on_ground and not self.was_on_ground then
  self.init_smoke(0, 4)
 end

 -- jump and dash input
 local jump, dash = btn(🅾️) and not self.p_jump, btn(❎) and not self.p_dash
 self.p_jump, self.p_dash = btn(🅾️), btn(❎)

 -- jump buffer
 if jump then
  self.jbuffer = 4
 elseif self.jbuffer > 0 then
  self.jbuffer -= 1
 end

 -- grace frames and dash restoration
 if on_ground then
  self.grace = 6
  if self.djump < max_djump then
   psfx"54"
   self.djump = max_djump
  end
 elseif self.grace > 0 then
  self.grace -= 1
 end

 -- dash effect timer (for dash-triggered events, e.g., berry blocks)
 self.dash_effect_time -= 1

 -- dash startup period, accel toward dash target speed
 if self.dash_time > 0 then
  self.init_smoke()
  self.dash_time -= 1
  self.spd = vector(appr(self.spd.x, self.dash_target_x, self.dash_accel_x), appr(self.spd.y, self.dash_target_y, self.dash_accel_y))
 else
  -- x movement
  local maxrun = 1
  local accel = self.is_ice(0, 1) and 0.05 or on_ground and 0.6 or 0.4
  local deccel = 0.15

  -- set x speed
  self.spd.x = abs(self.spd.x) <= 1 and
  appr(self.spd.x, h_input * maxrun, accel) or
  appr(self.spd.x, sign(self.spd.x) * maxrun, deccel)

  -- facing direction
  if self.spd.x ~= 0 then
   self.flip.x = self.spd.x < 0
  end

  -- y movement
  local maxfall = 2

  -- wall slide
  if h_input ~= 0 and self.is_solid(h_input, 0) and not self.is_ice(h_input, 0) then
   maxfall = 0.4
   -- wall slide smoke
   if rnd"10" < 2 then
    self.init_smoke(h_input * 6)
   end
  end

  -- apply gravity
  if not on_ground then
   self.spd.y = appr(self.spd.y, maxfall, abs(self.spd.y) > 0.15 and 0.21 or 0.105)
  end

  -- jump
  if self.jbuffer > 0 then
   if self.grace > 0 then
    -- normal jump
    psfx"1"
    self.jbuffer = 0
    self.grace = 0
    self.spd.y = -2
    self.init_smoke(0, 4)
   else
    -- wall jump
    local wall_dir = (self.is_solid(-3, 0) and -1 or self.is_solid(3, 0) and 1 or 0)
    if wall_dir ~= 0 then
     psfx"2"
     self.jbuffer = 0
     self.spd = vector(wall_dir * (-1 - maxrun), -2)
     if not self.is_ice(wall_dir * 3, 0) then
      -- wall jump smoke
      self.init_smoke(wall_dir * 6)
     end
    end
   end
  end

  -- dash
  local d_full = 5
  -- 5 * sqrt(2) = 3.5355339059 then rounded to 4 decimal places because pico 8 forgets the rest anyways
  local d_half = 3.5355

  if self.djump > 0 and dash then
   self.init_smoke()
   self.djump -= 1
   self.dash_time = 4
   has_dashed = true
   self.dash_effect_time = 10
   -- vertical input
   local v_input = btn(⬆️) and -1 or btn(⬇️) and 1 or 0
   -- calculate dash speeds
   self.spd = vector(
   	h_input ~= 0 and
    h_input * (v_input ~= 0 and d_half or d_full) or
    (v_input ~= 0 and 0 or self.flip.x and -1 or 1), 
    v_input ~= 0 and v_input * (h_input ~= 0 and d_half or d_full) or 0
   )
   
   -- dash puzzle thing
   if puzzle_solved then
   	-- no more dashes after it's solved
   	kill_player(self)
   	--puzzle_incorrect = true
   else
	   local dir_x = sign(self.spd.x)
	   local dir_y = sign(self.spd.y)
	   local dir = ""
	   if (dir_y == -1) dir ..= "u"
	   if (dir_y == 1) dir ..= "d"
	   if (dir_x == -1) dir ..= "l"
	   if (dir_x == 1) dir ..= "r"
	   add(dash_dirs, dir)
	   puzzle_index += 1
	   
	   -- check against puzzle
	   if dir != puzzle[puzzle_index] then
	   	--puzzle_index = 0
	   	kill_player(self)
	   	puzzle_incorrect = true
	   elseif puzzle_index == #puzzle then
	   	puzzle_solved = true
	   	--stop()
	   end
	  end
   
   -- effects
   psfx"3"
   freeze = 2
   -- dash target speeds and accels
   self.dash_target_x = 2 * sign(self.spd.x)
   self.dash_target_y = (self.spd.y >= 0 and 2 or 1.5) * sign(self.spd.y)
   self.dash_accel_x = self.spd.y == 0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
   self.dash_accel_y = self.spd.x == 0 and 1.5 or 1.06066017177
  elseif self.djump <= 0 and dash then
   -- failed dash smoke
   psfx"9"
   self.init_smoke()
  end
 end

 -- animation
 self.spr_off += 0.25
 self.spr = not on_ground and (self.is_solid(h_input, 0) and 5 or 3) or -- wall slide or mid air
 btn(⬇️) and 6 or -- crouch
 btn(⬆️) and 7 or -- look up
 self.spd.x ~= 0 and h_input ~= 0 and 1 + self.spr_off % 4 or 1 -- walk or stand

 -- exit level off the top (except summit)
 if self.y < -4 and levels[lvl_id + 1] and puzzle_solved then
  next_level()
 end

 -- was on the ground
 self.was_on_ground = on_ground
end
function player:draw()
 -- clamp in screen
 local clamped = mid(self.x, -1, lvl_pw - 7)
 if self.x ~= clamped then
  self.x = clamped
  self.spd.x = 0
 end
 if not puzzle_solved and self.y < 0 then
 	self.y = 0
 	self.spd.y = 0
 end
 -- draw player hair and sprite
 set_hair_color(self.djump)
 draw_hair(self)
	self:draw_sprite()
 pal()
 
 -- next dash dir indicator
 local ix = self.x + 2
 local iy = self.y + 3
 local dir = letter_dirs[puzzle[puzzle_index + 1]]
 if dir then
	 local dx = split(dir)[1]
	 local dy = split(dir)[2]
	 ix += dx * 16
	 iy += dy * 16
	 local s = frames % 4 >= 2 and 92 or 88
	 sspr(s, 0, 4, 4, ix, iy)
	end
end

function create_hair(obj)
	obj.hair = {}
	for i = 1, 5 do
		add(obj.hair, vector(obj.x, obj.y))
	end
end

function set_hair_color(djump)
	pal(8, djump == 1 and 8 or djump == 2 and 7 + frames \ 3 % 2 * 4 or 12)
end

function draw_hair(obj)
	local last = vector(obj.x + (obj.flip.x and 6 or 2), obj.y + (btn(⬇️) and 4 or 3))
	for i, h in ipairs(obj.hair) do
		h.x += (last.x - h.x) / 1.5
		h.y += (last.y + 0.5 - h.y) / 1.5
		circfill(h.x, h.y, mid(4 - i, 1, 2), 8)
		last = h
	end
end

function kill_player(obj)
	sfx_timer = 12
	sfx"0"
	deaths += 1
	destroy_object(obj)
	
	for dir = 0, 0.875, 0.125 do
		add(dead_particles, {
			x = obj.x + 4,
			y = obj.y + 4,
			t = 2,
			dx = sin(dir) * 3,
			dy = cos(dir) * 3
		})
	end
	delay_restart = 15
end

player_spawn = {
	layer = 6, 
	draw = player.draw
}
function player_spawn:init()
 sfx"4"
 self.spr = 3
 self.target = self.y
 self.y = min(self.y + 48, lvl_ph)
 cam_x, cam_y = mid(self.x + 4, 64, lvl_pw - 64), mid(self.y, 64, lvl_ph - 64)
 self.spd.y = -4
 self.state = 0
 self.delay = 0
 create_hair(self)
 self.djump = max_djump
end 
function player_spawn:update()
 if self.state == 0 and self.y < self.target + 16 then
 	-- jumping up
  self.state = 1
  self.delay = 3
 elseif self.state == 1 then
		-- falling
  self.spd.y += 0.5
  if self.spd.y > 0 then
   if self.delay > 0 then
    -- stall at peak
    self.spd.y = 0
    self.delay -= 1
   elseif self.y > self.target then
    -- clamp at target y
    self.y = self.target
    self.spd = vector(0, 0)
    self.state = 2
    self.delay = 5
    self.init_smoke(0, 4)
    sfx"5"
   end
  end
 elseif self.state == 2 then
 	-- landing and spawning player object
  self.delay -= 1
  self.spr = 6
  if self.delay < 0 then
   destroy_object(self)
			init_object(player, self.x, self.y).hair = self.hair
  end
 end
end
-->8
-- [objects]

spring = {
	layer = -1,
}
function spring:init()
	self.delta = 0
	self.dir = self.spr == 21 and 0 or self.is_solid(-1, 0) and 1 or -1
	self.show = true
end
function spring:update()
	self.delta = self.delta * 0.75
	local hit = self.player_here()
	
	if self.show and hit and self.delta <= 1 then
		if self.dir == 0 then
			hit.move(0, self.y - hit.y - 4, 1)
			hit.spd.x *= 0.2
			hit.spd.y = -3
		else
			hit.move(self.x + self.dir * 4 - hit.x, 0, 1)
			hit.spd = vector(self.dir * 3, -1.5)
		end
		hit.dash_time = 0
		hit.dash_effect_time = 0
		hit.djump = max_djump
		self.delta = 8
		psfx"8"
		self.init_smoke()
		
		break_fall_floor(self.check(fall_floor, -self.dir, self.dir == 0 and 1 or 0))
	end
end
function spring:draw()
	if self.show then
		local delta = min(flr(self.delta), 4)
		if self.dir == 0 then
			spr(21, self.x, self.y + delta)
		else
			spr(22, self.dir == -1 and self.x + delta or self.x, self.y, 1 - delta / 8, 1, self.dir == 1)
		end
	end
end

fall_floor = {
	solid_obj = true,
	state = 0,
}
function fall_floor:update()
	-- idling
	if self.state == 0 then
		for i = 0, 2 do
			if self.check(player, i - 1, -(i % 2)) then
				break_fall_floor(self)
			end
		end
	-- shaking
	elseif self.state == 1 then
		self.delay -= 1
		if self.delay <= 0 then
			self.state = 2
			self.delay = 60 -- how long it hides for
			self.collideable = false
			set_springs(self, false)
		end
	-- invisible, waiting to reset
	elseif self.state == 2 then
		self.delay -= 1
		if self.delay <= 0 and not self.player_here() then
			psfx"7"
			self.state = 0
			self.collideable = true
			self.init_smoke()
			set_springs(self, true)
		end
	end
end
function fall_floor:draw()
	spr(self.state == 1 and 28 - self.delay / 5 or self.state == 0 and 25, self.x, self.y) -- add an if statement if you use sprite 0 (other stuff also breaks if you do this i think)
end

function break_fall_floor(obj)
	if obj and obj.state == 0 then
		psfx"15"
		obj.state = 1
		obj.delay = 15 -- how long until it falls
		obj.init_smoke()
	end
end

function set_springs(obj, state)
	obj.hitbox = rectangle(-2, -2, 12, 8)
	local springs = obj.check_all(spring, 0, 0)
	foreach(springs, function(s) s.show = state end)
	obj.hitbox = rectangle(params"0, 0, 8, 8")
end

balloon = {}
function balloon:init()
	self.offset = rnd()
	self.start = self.y
	self.timer = 0
	self.hitbox = rectangle(params"-1, -1, 10, 10")
	self.show = true
end
function balloon:update()
	if self.show then
		self.offset += 0.01
		self.y = self.start + sin(self.offset) * 2
		local hit = self.player_here()
		if hit and hit.djump < max_djump then
			psfx"6"
			self.init_smoke()
			hit.djump = max_djump
			self.show = false
			self.timer = 60
		end
	elseif self.timer > 0 then
		self.timer -= 1
	else
		psfx"7"
		self.init_smoke()
		self.show = true
	end
end
function balloon:draw()
	if self.show then
		for i = 7, 13 do
			pset(self.x + 4 + sin(self.offset * 2 + i / 10), self.y + i, 6)
		end
		self:draw_sprite()
	end
end

smoke = {
	layer = 3
}
function smoke:init()
	self.spd = vector(0.3 + rnd"0.2", -0.1)
	self.x += -1 + rnd"2"
	self.y += -1 + rnd"2"
	self.flip = vector(rnd() < 0.5, rnd() < 0.5)
end
function smoke:update()
	self.spr += 0.2
	if self.spr >= 105 then
		destroy_object(self)
	end
end

fruit = {
	check_fruit = true
}
function fruit:init()
	self.start = self.y
	self.off = 0
end
function fruit:update()
	check_fruit(self)
	self.off += 0.025
	self.y = self.start + sin(self.off) * 2.5
end

fly_fruit = {
	check_fruit = true
}
function fly_fruit:init()
	self.start = self.y
	self.step = 0.5
	self.sfx_delay = 8
end
function fly_fruit:update()
	-- fly away
	if has_dashed then
		if self.sfx_delay > 0 then
			self.sfx_delay -= 1
			if self.sfx_delay <= 0 then
				sfx_timer = 20
				sfx"14"
			end
		end
		self.spd.y = appr(self.spd.y, -3.5, 0.25)
		if self.y < -16 then
			destroy_object(self)
		end
	-- wait
	else
		self.step += 0.05
		self.spd.y = sin(self.step) * 0.5
	end
	-- collect
	check_fruit(self)
end
function fly_fruit:draw()
	spr(28, self.x, self.y)
	for ox = -6, 6, 12 do
		spr((has_dashed or sin(self.step) >= 0) and 29 or self.y > self.start and 31 or 30, self.x + ox, self.y - 2, 1, 1, ox == -6)
	end
end

function check_fruit(self)
	local hit = self.player_here()
	if hit then
		hit.djump = max_djump
		sfx_timer = 20
		sfx"13"
		got_fruit[self.fruit_id] = true
		init_object(lifeup, self.x, self.y)
		destroy_object(self)
		if time_ticking then
			fruit_count += 1
		end
	end
end

lifeup = {}
function lifeup:init()
	self.spd.y = -0.25
	self.duration = 30
	self.flash = 0
end
function lifeup:update()
	self.duration -= 1
	if self.duration <= 0 then
		destroy_object(self)
	end
end
function lifeup:draw()
	self.flash += 0.5
	?"1000", self.x - 4, self.y - 4, 7 + self.flash % 2
end

fake_wall = {
	check_fruit = true,
	solid_obj = true
}
function fake_wall:init()
	self.solid_obj = true
	self.hitbox = rectangle(params"0, 0, 16, 16")
end
function fake_wall:update()
	self.hitbox = rectangle(params"-1, -1, 18, 18")
	local hit = self.player_here()
	if hit and hit.dash_effect_time > 0 then
		hit.spd = vector(sign(hit.spd.x) * -1.5, -1.5)
		hit.dash_time = -1
		for ox = 0, 8, 8 do
			for oy = 0, 8, 8 do
				self.init_smoke(ox, oy)
			end
		end
		init_fruit(self, 4, 4)
	end
	self.hitbox = rectangle(params"0, 0, 16, 16")
end
function fake_wall:draw()
	spr(97, self.x, self.y, 1, 2)
	spr(97, self.x + 8, self.y, 1, 2, true, true)
end

function init_fruit(self, ox, oy)
	sfx_timer = 20
	sfx"16"
	init_object(fruit, self.x + ox, self.y + oy, 28).fruit_id = self.fruit_id
	destroy_object(self)
end

key = {}
function key:update()
	self.spr = flr(9.5 + sin(frames / 30))
	if frames == 18 then
		self.flip.x = not self.flip.x
	end
	if self.player_here() then
		sfx"23"
		sfx_timer = 10
		destroy_object(self)
		has_key = true
	end
end

chest = {
	check_fruit = true
}
function chest:init()
	self.x -= 4
	self.start = self.x
	self.timer = 20
end
function chest:update()
	if has_key then
		self.timer -= 1
		self.x = self.start - 1 + rnd"3"
		if self.timer <= 0 then
			init_fruit(self, 0, -4)
		end
	end
end

message = {
	layer = 4
}
function message:init()
	self.text = "-- celeste mountain --#this memorial to those#perished on the climb"
	self.hitbox.x += 4
end
function message:draw()
	if self.player_here() then
		for i, s in ipairs(split(self.text, "#")) do
			camera()
			rectfill(7, 7 * i, 120, 7 * i + 6, 7)
			?s, 64 - #s * 2, 7 * i + 1, 0
			camera(draw_x, draw_y)
		end
	end
end

big_chest = {}
function big_chest:init()
	self.state = max_djump > 1 and 2 or 0
	self.hitbox.w = 16
end
function big_chest:update()
	if self.state == 0 then
		local hit = self.check(player, 0, 8)
		if hit and hit.is_solid(0, 1) then
			music(-1, 500, 7)
			sfx"37"
			pause_player = true
			hit.spd = vector(0, 0)
			self.state = 1
			self.init_smoke()
			self.init_smoke(8)
			self.timer = 60
			self.particles = {}
		end
	elseif self.state == 1 then
		self.timer -= 1
		flash_bg = true
		if self.timer <= 45 and #self.particles < 50 then
			add(self.particles, {
				x = 1 + rnd"14",
				y = 0,
				h = 32 + rnd"32",
				spd = 8 + rnd"8"
			})
		end
		if self.timer < 0 then
			self.state = 2
			self.particles = {}
			flash_bg, bg_col, cloud_col = false, 2, 14
			init_object(orb, self.x + 4, self.y + 4, 46)
			pause_player = false
		end
	end
end
function big_chest:draw()
	if self.state == 0 then
		self:draw_sprite()
		spr(96, self.x + 8, self.y, 1, 1, true)
	elseif self.state == 1 then
		foreach(self.particles, function(p)
			p.y += p.spd
			line(self.x + p.x, self.y + 8 - p.y, self.x + p.x, min(self.y + 8 - p.y + p.h, self.y + 8), 7)
		end)
	end
	spr(112, self.x, self.y + 8)
	spr(112, self.x + 8, self.y + 8, 1, 1, true)
end

orb = {}
function orb:init()
	self.spd.y = -4
end
function orb:update()
	self.spd.y = appr(self.spd.y, 0, 0.5)
	local hit = self.player_here()
	if self.spd.y == 0 and hit then
		music_timer = 45
		sfx"51"
		freeze = 10
		destroy_object(self)
		max_djump = 2
		hit.djump = 2
	end
end
function orb:draw()
	self:draw_sprite()
	for i=0, 0.875, 0.125 do
		circfill(self.x + 4 + cos(frames / 30 + i) * 8, self.y + 4 + sin(frames / 30 + i) * 8, 1, 7)
	end
end

flag = {}
function flag:init()
	self.x += 5
end
function flag:update()
	if not self.show and self.player_here() and puzzle_solved then
		sfx"55"
		sfx_timer, self.show, time_ticking = 30, true, false
	end
end
function flag:draw()
	if puzzle_solved then
		spr(118 + frames / 5 % 3, self.x, self.y)
		if self.show then
			camera()
			rectfill(params"32, 2, 96, 31, 0")
			spr(28, 55, 6)
			?"x" .. fruit_count, 64, 9, 7
			draw_time(49, 16)
			?"deaths:" .. deaths, 48, 24, 7
			camera(draw_x, draw_y)
		end
	else
		spr(88, self.x, self.y)
	end
end

-- [object class]

function init_object(type, x, y, tile)
	-- generate and check berry id
	local id = x .. "," .. y .. "," .. lvl_id
	if type.check_fruit and got_fruit[id] then
		return
	end

	local obj = {
		type = type,
		collideable = true,
		spr = tile,
		flip = vector(), -- false, false
		x = x,
		y = y,
		hitbox = rectangle(params"0, 0, 8, 8"),
		spd = vector(0, 0),
		rem = vector(0, 0),
		layer = 0,
		
		fruit_id = id,
	}

	function obj.left() return obj.x + obj.hitbox.x end
	function obj.right() return obj.left() + obj.hitbox.w - 1 end
	function obj.top() return obj.y + obj.hitbox.y end
	function obj.bottom() return obj.top() + obj.hitbox.h - 1 end

	function obj.is_solid(ox, oy)
		for o in all(objects) do
			if o != obj and (o.solid_obj or o.semisolid_obj and not obj.objcollide(o, ox, 0) and oy > 0) and obj.objcollide(o, ox, oy) then
				return true
			end
		end
		return oy > 0 and not obj.is_flag(ox, 0, 3) and obj.is_flag(ox, oy, 3) or -- jumpthrough or
		obj.is_flag(ox, oy, 0) -- solid terrain
	end

	function obj.is_ice(ox, oy)
		return obj.is_flag(ox, oy, 4)
	end

	function obj.is_flag(ox, oy, flag)
		for i = max(0, (obj.left() + ox) \ 8), min(lvl_w - 1, (obj.right() + ox) / 8) do
			for j = max(0, (obj.top() + oy) \ 8), min(lvl_h - 1, (obj.bottom() + oy) / 8) do
				if fget(tile_at(i, j), flag) then
					return true
				end
			end
		end
	end

	function obj.objcollide(other, ox, oy)
		return other.collideable and
		other.right() >= obj.left() + ox and
		other.bottom() >= obj.top() + oy and
		other.left() <= obj.right() + ox and
		other.top() <= obj.bottom() + oy
	end

	-- returns first object of type colliding with obj
	function obj.check(type, ox, oy)
		for other in all(objects) do
			if other and other.type == type and other ~= obj and obj.objcollide(other, ox, oy) then
				return other
			end
		end
	end
	
	-- returns all objects of type colliding with obj
	function obj.check_all(type, ox, oy)
		local tbl = {}
		for other in all(objects) do
			if other and other.type == type and other ~= obj and obj.objcollide(other, ox, oy) then
				add(tbl, other)
			end
		end
		
		if #tbl > 0 then return tbl end
	end

	function obj.player_here()
		return obj.check(player, 0, 0)
	end

	function obj.move(ox, oy, start)
		for axis in all{"x", "y"} do
			obj.rem[axis] += axis == "x" and ox or oy
			local amt = round(obj.rem[axis])
			obj.rem[axis] -= amt
			local upmoving = axis == "y" and amt < 0
			local riding = not obj.player_here() and obj.check(player, 0, upmoving and amt or -1)
			local movamt
			if obj.collides then
				local step = sign(amt)
				local d = axis == "x" and step or 0
				local p = obj[axis]
				for i = start, abs(amt) do
					if not obj.is_solid(d, step - d) then
						obj[axis] += step
					else
						obj.spd[axis], obj.rem[axis] = 0, 0
						break
					end
				end
				movamt = obj[axis] - p -- save how many px moved to use later for solids
			else
				movamt = amt
				if (obj.solid_obj or obj.semisolid_obj) and upmoving and riding then
					movamt += obj.top() - riding.bottom() - 1
					local hamt = round(riding.spd.y + riding.rem.y)
					hamt += sign(hamt)
					if movamt < hamt then
						riding.spd.y = max(riding.spd.y, 0)
					else
						movamt = 0
					end
				end
				obj[axis] += amt
			end
			if (obj.solid_obj or obj.semisolid_obj) and obj.collideable then
				obj.collideable = false
				local hit = obj.player_here()
				if hit and obj.solid_obj then
					hit.move(axis == "x" and (amt > 0 and obj.right() + 1 - hit.left() or amt < 0 and obj.left() - hit.right() - 1) or 0,
							axis == "y" and (amt > 0 and obj.bottom() + 1 - hit.top() or amt < 0 and obj.top() - hit.bottom() - 1) or 0,
							1)
					if obj.player_here() then
						kill_player(hit)
					end
				elseif riding then
					riding.move(axis == "x" and movamt or 0, axis == "y" and movamt or 0, 1)
				end
				obj.collideable = true
			end
		end
	end

	function obj.init_smoke(ox, oy)
		init_object(smoke, obj.x + (ox or 0), obj.y + (oy or 0), 102)
	end
	
	function obj:init() end
	
	function obj:update() end
	
	function obj:draw()
		spr(obj.spr, obj.x, obj.y, 1, 1, obj.flip.x, obj.flip.y)
	end
	
	-- this is the replacement for draw_obj_sprite
	-- useful if you override obj.draw but still use the default draw function
	obj.draw_sprite = obj.draw
	
	-- copy functions and other variables from type
	-- these functions can also override functions from the obj class
	-- for instance, obj.is_solid can be redefined per object
	for k, v in pairs(type) do
		obj[k] = v
	end

	add(objects, obj)

	obj:init()

	return obj
end

function destroy_object(obj)
	del(objects, obj)
end

function move_camera(obj)
	cam_spdx = cam_gain * (4 + obj.x - cam_x)
	cam_spdy = cam_gain * (4 + obj.y - cam_y)

	cam_x += cam_spdx
	cam_y += cam_spdy

	-- clamp camera to level boundaries
	local clamped = mid(cam_x, 64, lvl_pw - 64)
	if cam_x ~= clamped then
		cam_spdx = 0
		cam_x = clamped
	end
	clamped = mid(cam_y, 64, lvl_ph - 64)
	if cam_y ~= clamped then
		cam_spdy = 0
		cam_y = clamped
	end
end

function draw_object(obj)
	obj:draw()
end
-->8
-- [level loading]

function next_level()
	local next_lvl = lvl_id + 1

	-- check for music trigger
	if music_switches[next_lvl] then
		music(music_switches[next_lvl], 500, 7)
	end

	load_level(next_lvl)
end

function load_level(id)
	has_dashed, has_key = false

	-- remove existing objects
	foreach(objects, destroy_object)
	
	dash_dirs = {}
	puzzle = split(puzzles[id])
	puzzle_index = 0
	puzzle_solved = false
	puzzle_incorrect = false

	-- reset camera speed
	cam_spdx, cam_spdy = 0, 0

	local diff_level = lvl_id ~= id

	-- set level index
	lvl_id = id

	-- set level globals
	local tbl = split(levels[lvl_id])
	for i = 1, 4 do
		_ENV[split"lvl_x,lvl_y,lvl_w,lvl_h"[i]] = tbl[i] * 16
	end
	lvl_title = tbl[5]
	lvl_pw, lvl_ph = lvl_w * 8, lvl_h * 8

	-- level title setup
	ui_timer = 5

	-- reload map
	if diff_level then
		reload()
		--	check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x, lvl_y, lvl_w, lvl_h, mapdata[lvl_id])
		end
	end

	-- entities
	for tx = 0, lvl_w - 1 do
		for ty = 0, lvl_h - 1 do
			local tile = tile_at(tx, ty)
			if tiles[tile] then
				init_object(tiles[tile], tx * 8, ty * 8, tile)
			end
		end
	end
end

-- replace mapdata with hex
function replace_mapdata(x, y, w, h, data)
	for i = 1, #data, 2 do
		mset(x + i \ 2 % w, y + i \ 2 \ w, "0x" .. sub(data, i, i + 1))
	end
end
-->8
-- [metadata]

-- @begin
-- level table
-- "x, y, w, h, title"
levels = {
	"0,0,1,1",
	"1,0,1,1",
	"2,0,1,1",
	"3,0,1,1",
	"4,0,1,1",
	"5,0,1,1",
	"6,0,1,1,summit",
}

puzzles = {
	"u,ul",
	"r,l,r,u,u,u",
	"d",
	"r,u,ur,l,r,l,u,u,u,u",
	"u,l,d,d,u,u,r,r,u",
	"r,r,l,l,u,u,d,d,ul,ul",
	"u,u,d,d,l,r,l,r"
}

dir_letters = {
	["-1,0"] = "l",
	["1,0"] = "r",
	["0,-1"] = "u",
	["0,1"] = "d",
	["-1,-1"] = "ul",
	["1,-1"] = "ur",
	["-1,1"] = "dl",
	["1,1"] = "dr",
}

letter_dirs = {}

for k, v in pairs(dir_letters) do
	letter_dirs[v] = k
end

-- mapdata string table
-- assigned levels will load from here instead of the map
mapdata = {

}

-- list of music switch triggers
-- assigned levels will start the tracks set here
music_switches = {
	[7] = 30
}

-- @end

-- tiles stack
-- assigned objects will spawn from tiles set here
tiles = {}
foreach(split([[
1,player_spawn
8,key
21,spring
22,spring
23,chest
24,balloon
25,fall_floor
28,fruit
29,fly_fruit
86,message
96,big_chest
97,fake_wall
118,flag
]],"\n"),function(t)
 local tile, obj = unpack(split(t))
 tiles[tile] = _ENV[obj]
end)

--[[

short on tokens?
everything below this comment
is just for grabbing data
rather than loading it
and can be safely removed!

--]]

-- copy mapdata string to clipboard
function get_mapdata(x, y, w, h)
	local reserve = ""
	for i = 0, w * h - 1 do
		reserve ..= num2hex(mget(x + i % w, y + i \ w))
	end
	printh(reserve, "@clip")
end

-- convert mapdata to memory data
function num2hex(v)
	return sub(tostr(v, true), 5, 6)
end
__gfx__
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a000c0c0000000000000494949494949494949494949
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000c00ccc000000000222222222222222222222222
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a0000000000000000000000420000000000000024000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0000000000000000000004200000000000000002400
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000000000000000000042000000000000000000240
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000000000000000000420000000000000000000024
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a0000000000000000000200000000000000000000002
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0000000000000000000000000000000000000000000
57777777777777777777777557777775dddddddd000000000000000000000000008888004999999449999994499909940300b0b0000000000000000000000000
77777777777777777777777777777777d77ddddd00000000000400000000000008888880911111199111411991140919003b3300000777770000000000000000
7777ddddd777777ddddd777777777777d77dd7dd00000000000950500aaaaaa00878888091111119911191194940041902888820007766700000000000000000
777dddddddd77dddddddd777777dd777dddddddd0499994000090505a998888a0888888091111119949404190000004408988880076777000000000000000000
77dddddddddddddddddddd7777dddd77dddddddd0050050000090505a988888a0888888091111119911409499400000008888980077660000777770000000000
77dd77ddddddddddddd7dd7777dddd77dd7ddddd0005500000095050aaaaaaaa0888888091111119911191199140049908898880077770000777767007700000
77dd77dddddddddddddddd7777d7dd77ddddd7dd0050050000040000a980088a0088880091111119911411199140411902888820070000000700007707777770
77dddddddddddddddddddd7777dddd77dddddddd0005500000000000a988888a0000000049999994499999944400499400288200000000000000000000077777
77dddddddddddddddddddd7777dddd77577777750000000000000000000000005555555555555555555555555500000066656665077777700077770000000000
777dddddddddddddddddd777777ddd7777777777000c0000000cc0000cccc0005555555555555550055555556670000067656765777777770700007000000000
777dddddddddddddddddd777777ddd77777d777700cc0000000cc0000ccc00005555555555555500005555556777700067706770777777777077000700000000
7777dddddddddddddddd777777ddd77777dddd770cccccc0000cc0000cccc0005555555555555000000555556660000007000700777733777077bb0700000000
7777dddddddddddddddd777777ddd77777dddd770cccccc00cccccc00c0ccc00555555555555000000005555550000000700070077773377700bbb070000b000
777dddddddddddddddddd777777dd777777dd77700cc000000cccc000000ccc0555555555550000000000555667000000000000073773337700bbb07000b0000
777dddddddddddddddddd777777dd77777777777000c0000000cc00000000c0055555555550000000000005567777000000000007333bb3707000070030b0030
77dddddddddddddddddddd7777dddd775777777500000000000000000000000055555555500000000000000566600000000000000333bb300077770003033030
77dddddddddddddddddddd77777ddd77577777777777777777777775555555555555555550000000000000050000000000000666033333300000000000000000
77dddddddddddddddddddd77777dd77777777777777777777777777755555555505555555500000000000055000000000007777603b3333000ee0ee000000000
77dd7dddddddddddd77ddd77777dd7777777ddd7777777777ddd77775500005555550055555000000000055500000000000007660333333000eeeee000000030
77ddddddddddddddd77ddd7777ddd777777ddddd7d7777ddddddd7775500005555550055555500000000555500700070000000550333b330000e8e00000000b0
777dddddddd77dddddddd77777dddd77777ddddddd7777d7ddddd7775500005555555555555550000005555500700070000006660033330000eeeee000000b30
7777ddddd777777ddddd777777dddd777777ddd7777777777ddd77775500005555055555555555000055555506770677000777760004400000ee3ee003000b00
777777777777777777777777777dd777777777777777777777777777555555555555555555555550055555555676567600000766000440000000b00000b0b300
57777777777777777777777557777775577777777777777777777775555555555555555555555555555555555666566600000055009999000000b00000303300
000b300077707777000c000000cccc00ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000330000700077000cc000000cccc00cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033000000007000ccccccc00cccc00ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b30000000000cccccccc00cccc00cccccc000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000
0000b30000000000ccccccccccccccccc0ccccc0000000000002eeeeeeee20000000000000000000000000000000000000060600000000000000000000000000
00003300000000000ccccccc0cccccc0000ccccc00000000002eeeeeeeeee2000000000000000000000000000000000000500060000000000000000000000000
000b30000000000000cc000000cccc000000ccc00000000000eeeeeeeeeeee00000000000000000000000000000000000500000d000000000000000000000000
0003300000000000000c0000000cc00000000c000000000000e22222e2e22e00000000000000000000000000000000005000000d000000000000000000000000
00033000000000000000000000000000000000000000000000eeeeeeeeeeee000043000000000000000000000000000d0000000d000600000000000000000000
000b0000000000000000000000000000000000000000000000e22e2222e22e000043300000000000000000000000005000000000d06050000000000000000000
00030000000000000000000000000000000000000000000000eeeeeeeeeeee0004233000000000000000000000000d0000000000050005000000000000000000
00000000000000000000000000000000000000000000000000eee222e22eee000400330000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000eeeeeeeeeeee000400330000066000660666666000666660066666600066666006666660000000
00000000000000000000000000000000000000000000000000eeeeeeeeeeee004200000000066000660666666606666666066666660666666606666666000000
00000000000000000000000000000000000000000000000000ee77eee7777e004000000000066000660660000006600066000660000660006606600066000000
000000000000000000000000000000000000000000000000077777777777777040000000000ddd0ddd0dddd0000dd00000000dd0000dd000dd0dddddd0000000
0000000057777557000000000000000000000000000000000000000000000000700000000000dd0dd00dd000000dd000dd000dd0000dd000dd0dd000dd000000
00aaaaaa77777777000000000000000000000000000000000077000007700700070000070000ddddd00dddddd00ddddddd000dd0000ddddddd0dd000dd000000
0a9999997777dd770000000000000000000000000000000000777070077700000000000000000ddd000ddddddd00ddddd0000dd00000ddddd00dd000dd000000
a99aaaaa777ddddd0000000000000000000000000000000007777770077000000000000000000000000000000000000000000000000000000000000000000000
a9aaaaaa77dddddd000000000000000000000000000000000777777000007000000000000000000000000d000000000000000000000000000000d00000000000
a999999957dd77dd00000000000000000000000000000000077777700000077000000000000000000000d00000000000000000000000000000000d0000000000
a9999999577d77dd000000000000000000000000000000000707770000070770070000700000000000dd0000000000000000000000000000000000d000000000
a9999999777ddddd00000000000000000000000000000000000000007000000000000000000000000d000000000000000000000000000000000000d000000000
aaaaaaaa777ddddd00000000000000000000000000000000004bbb00004b000000400bbb00000000d0000000000000000000000000000000000000d000000000
a49494a1577ddddd00000000000000000000000000000000004bbbbb004bb000004bbbbb0000000100000000000000000000000000000000000000d00d000000
a494a4a157dd7ddd0000000000000000000000000000000004200bbb042bbbbb042bbb00000000d0000000000000000000000000000000000000001010d00000
a49444aa77dddddd00000000000000000000000000000000040000000400bbb004000000000001000000000000000000000000000000000000000001000d0000
a49999aa777ddddd0000000000000000000000000000000004000000040000000400000000000100000000000000000000000000000000000000000000010000
a49444997777dd770000000000000000000000000000000042000000420000004200000000000100000000000000000000000000000000000000000000001000
a494a444777777770000000000000000000000000000000040000000400000004000000000000000000000000000000000000000000000000000000000000000
a4949999577775770000000000000000000000000000000040000000400000004000000000010000000000000000000000000000000000000000000000000010
__label__
00000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000600000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000500060000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000500000d000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000005000000d000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000d0000000d000600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005000000000d06050000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000007700000000000d0000000000050005000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000066000660666666000666660066666600066666006666660000000000000000000000000000000000000000000
00000000000000000000000000000000000000066000660666666606666666066666660666666606666666000000000000000000000000000000000000006000
00000000000000000000000000000000000000066000660660000006600066000660000660006606600066000000000000000000000000000000000000000000
000000000000000000000000000000000000000ddd0ddd0dddd0000dd00000000dd0000dd000dd7dddddd0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000dd0dd00dd000000dd000dd000dd0000dd000dd0dd000dd000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ddddd00dddddd00ddddddd000dd0000ddddddd0dd000dd000000000000000000000000000000070000000000
00000000000000000000000000000000000000000ddd000ddddddd00ddddd0000dd00000ddddd00dd000dd000000000000000000000000000000000000000000
00000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000d000000000000000000000000000000d00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000d00000000000000000000000000000000d0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000dd0000000000000000000000000000000000d000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000d000000000000000000000000000000000000d000000000000000000000000000000000060000000000
00000000000000000000000000000000000000000000d0000000000000000000000000000000000000d000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000100000000000000000000000000000000000000d00d000000000000000000000000000000000000000000
000000000000000000000000000000000006000000d0000000000000000000000000000000000000001010d00000000000000000000000000000000000000000
000000000000000000000000000000000000000001000000000000000000000000000000000000000001000d0000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000000000000000000000000000000000
00070000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066600660660000006660606000000660066006600660066006606000600000000000000000000000000000000000
00000000000000000000000000000000000066606060606000006060606000006060606060606060600060006000600000000000000000000000000000000000
00000000000000000000000000000000000060606060606000006600666000006060606060606060600060006000600000000000000000000000000000000000
00000000000000000000000000000000000060606060606000006060006000006060606060606060606060606000600000000000000000000000660000000000
00000000000000000000000000000000000060606600666000006660666000006600660066006600666066606660666000000000000000000000660000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005550555055005500505000005550505005505550055005505500000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050505050505000000500505050505050500050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050555050505050555000000500555050505500555050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050505050077000000500505050505050005050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505055505550577000000500505055005050550055005050000000000000000000000000007000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000
00000000000000000000000000000000000000000000005500055055505000000055505550555055505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000006600000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000006600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000008080803030303030000000000000000000000030303030300000004040402020200020303030303030304040404020202020204000000000002020000000000000000040000000000020200000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2122282828203131313230313131212138282031313131313131313131312121000000000000000000002a282828283800003c2014213131313131313131212121212121212230212114212228282820211421222828293c20313131312121210000000000000000000000000000000000000000000000000000000000000000
14222838282328282828294040412021282923412837282828282829410020310008000000000000190000283728282800003c2021322b414000002a2841302131211421212112202121212228283820212121222900003c332b00413c3031310000000000000000000000000000000000000000000000000000000000000000
21322828283337290000004040002021280023002a28282838290000000033100000000000000000190000282828282800003c20322b000050003b002839133012303131312132202121212228282820212121323b00000000000000000000410000000000000000000000000000000000000000000000000000000000000000
222b2a28282829000000005040162021290023002f002a282800170000001021000000001900000000003a282828282800183c232b000000003b243a2838201114122c2c2c3334313131142228002a2021313210123b3b0018003b3b000000000000000000000000000039000000000000000000000000000000000000000000
222b0028000000000000000040002021003c23001012282828101112000020210000000019000000002828283828282800003c230000003b3b1012282828202121222b00002c2c41183c202228000020321011212111363b3b3b10123b00180000000000003a0000000028000000000000000000000000000000000000000000
222b0029000000000000000050002014003c3300203229002a302122000020140000000000000000002a28282828282800003c3328393c101114222a2828202121222b18003b3b00003c202229000020112114212132101111111421123b00000000000000280000000037000000000000000000000000000000000000000000
322b0000000000003a2839000000303100004000232c0000002c30320000302100000000000000000000002a2828290000183c2437283c30313122002900201421222b003c10122b003c303200000020213131313234313131313131313600000000003a00380076000028000000000000000000000000000000000000000000
410000000000003a283728000000101100005000332b0018003c13003a2828203900000015000000000000000000000000003c1329000000403c23000000202121222b003c30322b00002c2c00000020320040000041002838282828284000000000002800280010122f28003900000000000000000000000000000000000000
0000003a283900282828283900002021003c3411123b0000003b2328283828302800000019000000000019000000190000003c2300000000403c33003a282021142200180010122b00003b3b00180020280040000000002a282900002950000000000028392810212111123a3800000000000000000000000000000000000000
0000002a28283a28282828282839202128393c2021122b003c102228280000402839000000000000390019000000000039183c233b153b00503c132838293031212200000020222b013c10122b000030283950003f003b3b003b3b3b002f00150000002828133021211421122800000000000000000000000000000000000000
0000002d00282838101111122837202138283c3031322b003c203228290000502838282829000000280000000000190028003c303535362b003c2300000010112122000000202135353630322b0000103828000034111111121011111111113500003a2828201230212121211200390000000000000000000000000000000000
002f013d3a28282820142122002a20212829002c2c2c00003a33130000003b3b282829000000000037390000000000003728002c2c2c2c00003c233b153b202121220018003022282828284000000020282839003c30313132303131313132100000283810142112202121212239280000000000000000000000000000000000
001011122829002a202131323b3b20212800003b3b3b0000371022000000101128290000000000002a2800000000000028290000000000002d3c201111112121313200003a1333291c2a3750000000202837282839004041002829004128282000002a2830212122303131313213370000000000000000000000000000000000
3b2021223b3b3b3b303210111111211428013c1011122b3f28202200080020140000000000000000002839001900000028013f3b3b3b3b2f3d3c3021211421211112000028201216000029000000162028002a2828005018002800180028382000012f1012302121111111121021123f00000000000000000000000000000000
1121142111111111111230212121212111111220212111111121223b3b3b202100012f17000000193a283800000000001111123411111111111112302121212121223a282820223b3b3b3b3b3b3b3b2029000128283900003a3700003a2828201111112121122021212114222021211100000000000000000000000000000000
2121212121212114212112202121212114212220212121142121211111112121001011120000003a28282828283900001421211220212114212121122021212121222838282021111111111111111121000013282838282828282828282828202121142121222021212121222021142100000000000000000000000000000000
__sfx__
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000200177500605017750170523655017750160500605017750060501705076052365500605017750060501775017050177500605236550177501605006050177500605256050160523655256050177523655
002000001d0401d0401d0301d020180401804018030180201b0301b02022040220461f0351f03016040160401d0401d0401d002130611803018030180021f061240502202016040130201d0401b0221804018040
00100000070700706007050110000707007060030510f0700a0700a0600a0500a0000a0700a0600505005040030700306003000030500c0700c0601105016070160600f071050500a07005050030510a0700a060
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000002953429554295741d540225702256018570185701856018500185701856000500165701657216562275142753427554275741f5701f5601f500135201b55135530305602454029570295602257022560
011000200a0700a0500f0710f0500a0600a040110701105007000070001107011050070600704000000000000a0700a0500f0700f0500a0600a0401307113050000000000013070130500f0700f0500000000000
002000002204022030220201b0112404024030270501f0202b0402202027050220202904029030290201601022040220302b0401b030240422403227040180301d0401d0301f0521f0421f0301d0211d0401d030
0108002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
002000200a1400a1300a1201113011120111101b1401b13018152181421813213140131401313013120131100f1400f1300f12011130111201111016142161321315013140131301312013110131101311013100
001000202e750377502e730377302e720377202e71037710227502b750227302b7301d750247501d730247301f750277501f730277301f7202772029750307502973030730297203072029710307102971030710
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001800202945035710294403571029430377102942037710224503571022440274503c710274403c710274202e450357102e440357102e430377102e420377102e410244402b45035710294503c710294403c710
0018002005570055700557005570055700000005570075700a5700a5700a570000000a570000000a5700357005570055700557000000055700557005570000000a570075700c5700c5700f570000000a57007570
010c00103b6352e6003b625000003b61500000000003360033640336303362033610336103f6003f6150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c002024450307102b4503071024440307002b44037700244203a7102b4203a71024410357102b410357101d45033710244503c7101d4403771024440337001d42035700244202e7101d4102e7102441037700
011800200c5700c5600c550000001157011560115500c5000c5700c5600f5710f56013570135600a5700a5600c5700c5600c550000000f5700f5600f550000000a5700a5600a5500f50011570115600a5700a560
001800200c5700c5600c55000000115701156011550000000c5700c5600f5710f56013570135600f5700f5600c5700c5700c5600c5600c5500c5300c5000c5000c5000a5000a5000a50011500115000a5000a500
000c0020247712477024762247523a0103a010187523a0103501035010187523501018750370003700037000227712277222762227001f7711f7721f762247002277122772227620070027771277722776200700
000c0020247712477024762247523a0103a010187503a01035010350101875035010187501870018700007001f7711f7701f7621f7521870000700187511b7002277122770227622275237012370123701237002
000c0000247712477024772247722476224752247422473224722247120070000700007000070000700007002e0002e0002e0102e010350103501033011330102b0102b0102b0102b00030010300123001230012
000c00200c3320c3320c3220c3220c3120c3120c3120c3020c3320c3320c3220c3220c3120c3120c3120c30207332073320732207322073120731207312073020a3320a3320a3220a3220a3120a3120a3120a302
000c00000c3300c3300c3200c3200c3100c3100c3103a0000c3300c3300c3200c3200c3100c3100c3103f0000a3300a3201333013320073300732007310113000a3300a3200a3103c0000f3300f3200f3103a000
00040000336251a605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000c00000c3300c3300c3300c3200c3200c3200c3100c3100c3100c31000000000000000000000000000000000000000000000000000000000000000000000000a3000a3000a3000a3000a3310a3300332103320
001000000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163401d36022370223702236022350223402232013300133001830018300133001330016300163001d3001d300
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
001000102f65501075010753f615010753f6152f65501075010753f615010753f6152f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
0010000016270162701f2711f2701f2701f270182711827013271132701d2711d270162711627016270162701b2711b2701b2701b270000001b200000001b2000000000000000000000000000000000000000000
00080020245753057524545305451b565275651f5752b5751f5452b5451f5352b5351f5252b5251f5152b5151b575275751b545275451b535275351d575295751d545295451d535295351f5752b5751f5452b545
002000200c2650c2650c2550c2550c2450c2450c2350a2310f2650f2650f2550f2550f2450f2450f2351623113265132651325513255132451324513235132351322507240162701326113250132420f2600f250
00100000072750726507255072450f2650f2550c2750c2650c2550c2450c2350c22507275072650725507245072750726507255072450c2650c25511275112651125511245132651325516275162651625516245
000800201f5702b5701f5402b54018550245501b570275701b540275401857024570185402454018530245301b570275701b540275401d530295301d520295201f5702b5701f5402b5401f5302b5301b55027550
00100020112751126511255112451326513255182751826518255182451d2651d2550f2651824513275162550f2750f2650f2550f2451126511255162751626516255162451b2651b255222751f2451826513235
00100010010752f655010753f6152f6553f615010753f615010753f6152f655010752f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000100107501075010753f6152f6553f6153f61501075010753f615010753f6152f6553f6152f6553f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
002000002904029040290302b031290242b021290142b01133044300412e0442e03030044300302b0412b0302e0442e0402e030300312e024300212e024300212b0442e0412b0342e0212b0442b0402903129022
000800202451524515245252452524535245352454524545245552455524565245652457500505245750050524565005052456500505245550050524555005052454500505245350050524525005052451500505
000800201f5151f5151f5251f5251f5351f5351f5451f5451f5551f5551f5651f5651f575000051f575000051f565000051f565000051f555000051f555000051f545000051f535000051f525000051f51500005
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
002000200c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f2350c2650c2550c2450c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f235112651125511245
002000001327513265132551324513235112651125511245162751626516255162451623513265132551324513275132651325513245132350f2650f2550f2450c25011231162650f24516272162520c2700c255
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
001000003c5753c5453c5353c5253c5153c51537555375453a5753a5553a5453a5353a5253a5253a5153a51535575355553554535545355353553535525355253551535515335753355533545335353352533515
00100000355753555535545355353552535525355153551537555375353357533555335453353533525335253a5753a5453a5353a5253a5153a51533575335553354533545335353353533525335253351533515
001000200c0600c0300c0500c0300c0500c0300c0100c0000c0600c0300c0500c0300c0500c0300c0100f0001106011030110501103011010110000a0600a0300a0500a0300a0500a0300a0500a0300a01000000
001000000506005030050500503005010050000706007030070500703007010000000f0600f0300f010000000c0600c0300c0500c0300c0500c0300c0500c0300c0500c0300c010000000c0600c0300c0100c000
0010000003625246150060503615246251b61522625036150060503615116253361522625006051d6250a61537625186152e6251d615006053761537625186152e6251d61511625036150060503615246251d615
00100020326103261032610326103161031610306102e6102a610256101b610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
00400000302453020530235332252b23530205302253020530205302253020530205302153020530205302152b2452b2052b23527225292352b2052b2252b2052b2052b2252b2052b2052b2152b2052b2052b215
__music__
01 150a5644
00 0a160c44
00 0a160c44
00 0a0b0c44
00 14131244
00 0a160c44
00 0a160c44
02 0a111244
00 41424344
00 41424344
01 18191a44
00 18191a44
00 1c1b1a44
00 1d1b1a44
00 1f211a44
00 1f1a2144
00 1e1a2244
02 201a2444
00 41424344
00 41424344
01 2a272944
00 2a272944
00 2f2b2944
00 2f2b2c44
00 2f2b2944
00 2f2b2c44
00 2e2d3044
00 34312744
02 35322744
00 41424344
01 3d7e4344
00 3d7e4344
00 3d4a4344
02 3d3e4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 383a3c44
02 393b3c44

