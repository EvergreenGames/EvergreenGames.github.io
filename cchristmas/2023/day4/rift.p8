pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- rift
-- by ooooggll

-- made for 12 days of cc jam
-- 2023, organized by rubyred

--[[
	built off evercore+ V1.3
	
 a celeste classic mod base
 forked from evercore V2.2.0

 original game by:
 maddy thorson + noel berry

 major project contributions
 by taco360, meep, akliant,
 and gonengazit

 spacing, sprite sheet
 organization, and code
 improvements by ooooggll
--]]

-- [data structures]

function vector(x, y)
 return {x = x, y = y}
end

function rectangle(x, y, w, h)
 return {x = x, y = y, w = w, h = h}
end

-- token saver
function params(s)
	return unpack(split(s))
end

-- [globals]

-- tables
objects, got_fruit = {}, {}
-- timers
freeze, delay_restart, sfx_timer, music_timer, ui_timer = params"0, 0, 0, 0, -99"
-- camera values
draw_x, draw_y, cam_x, cam_y, cam_spdx, cam_spdy, cam_gain = params"0, 0, 0, 0, 0, 0, 0.25"

-- [entry point]

function _init()
 frames, start_game_flash = 0, 0
 music(params"40, 0, 7")
 lvl_id = 0
 
 past = false
 fade = 0
 
 poke(0x5f2e, 1)
end

function begin_game()
 max_djump, deaths, frames, 
 seconds, minutes, music_timer,
 fruit_count, bg_col, cloud_col = 
 params"1, 0, 0, 0, 0, 0, 0, 0, 1"
 
 time_ticking = true
 music(params"0, 0, 7")
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
 	w = 32 + rnd"32"
 })
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

-- [main update loop]

function _update()
 frames += 1
 if time_ticking then
  seconds += frames \ 30
  minutes += seconds \ 60
  seconds %= 60
 end
 frames %= 30
 
 --[[
 -- @debug - skip level
 if btnp(➡️, 1) then
 	if is_title() then
 		begin_game()
 	else
 		next_level()
 	end
 end
 -- @debug - switch timeline
 if btnp(⬆️, 1) then
 	past = not past
 end
 --]]
 
 --[[
 -- @debug - decorate
 if btnp(⬆️, 1) then
 	for x = lvl_x, lvl_x + 15 do
 		for y = lvl_y, lvl_y + 15 do
 			local tile = mget(x, y)
 			if tile == 33 or tile == 20 then
 				if rnd() > 0.95 then
 					mset(x, y, 20)
 				else
 					mset(x, y, 33)
 				end
				end
			end
		end
 end
 --]]

 if music_timer > 0 then
  music_timer -= 1
  if music_timer <= 0 then
   music(params"10, 0, 7")
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
  
  -- fade to present on death
  if delay_restart == 6 and past then
  	fade = 10
  end
 end

 -- update each object
 foreach(objects, function(obj)
  -- don't move during fade
  if fade > 0 then
  	return
  end
  
  obj.move(obj.spd.x, obj.spd.y, 0)
  
 	if (obj.update) obj:update()
 	
 	if obj.clamp then
 		-- clamp in screen
		 local clamped = mid(obj.x, -1, lvl_pw - 7)
		 if obj.x ~= clamped then
		  obj.x = clamped
		  obj.spd.x = 0
		 end
		end
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
  end
 else
	 local blocks_were_on = blocks_on
	 blocks_on = blocks_inverted()
	 for obj in all(objects) do
			if obj.type == button and obj.in_past == past then
				if (obj.check(crystal, 0, 0) or obj.check(player, 0, 0)) then
					-- if one button is powered, all blocks are powered
					blocks_on = not blocks_on
					break
				end
			end
	 end
	 
	 if blocks_on ~= blocks_were_on and blocks_were_on ~= nil then
		 swap_spikes()
		 
		 for obj in all(lookup.solid) do
		 	if obj.type == on_block or obj.type == off_block then
		 		obj:update()
				end
   end
		 
		 -- smoke
		 for obj in all(objects) do
		 	if obj.type == on_block or obj.type == off_block then
		 		--obj.init_smoke()
				end
   end
   
   sfx(63)
		end
	  
	 -- switch to past in the
	 -- middle of fade effect
	 if fade == 5 then
			past = not past
			for obj in all(objects) do
				if obj.type == player then
					obj.in_past = past
				end
			end
	 end
	end
end

-- [drawing functions]

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
  
  do_palette()
  
  return
 end

 -- draw bg color
 cls(flash_bg and frames / 5 or bg_col)

 -- bg clouds effect
 foreach(clouds, function(c)
  c.x += c.spd - cam_spdx
  rectfill(c.x, c.y, c.x + c.w, c.y + 16 - c.w * 0.1875, cloud_col)
  if c.x > 128 then
   c.x = - c.w
   c.y = rnd"120"
  end
 end)

 -- set cam draw position
 draw_x = round(cam_x) - 64
 draw_y = round(cam_y) - 64
 camera(draw_x, draw_y)

	-- background layer: -5
	-- foreground layer: 0
	-- default layer: 5
	
	-- actually draw objects
	for layer = min_layer, max_layer do
		if layer == -5 then
			-- draw bg terrain
 		map(lvl_x, lvl_y + (past and 16 or 0), 0, 0, lvl_w, lvl_h, 4)
		elseif layer == 0 then
			-- draw terrain
			if past then
  		pal(10, 13)
  		pal(3, 6)
  	end		
 		map(lvl_x, lvl_y + (past and 16 or 0), 0, 0, lvl_w, lvl_h, 2)
			pal()
		else
			foreach(objects, function(obj)
				if obj.layer == layer then
					draw_object(obj)
				end
			end)
		end
	end

 -- particles
 foreach(particles, draw_particle)

 -- dead particles
 foreach(dead_particles, function(p)
  p.x += p.dx
  p.y += p.dy
  p.t -= 0.2
  if p.t <= 0 then
   del(dead_particles, p)
  end
  rectfill(p.x - p.t, p.y - p.t, p.x + p.t, p.y + p.t, 14 + 5 * p.t % 2)
 end)

 -- draw level title
 camera()
 if ui_timer >= -30 then
  if ui_timer < 0 then
   draw_ui()
  end
  ui_timer -= 1
 end
 
 -- draw fade effect
	if fade > 7 then
		fillp(▒)
	elseif fade > 3 then
		fillp(█)
	elseif fade > 0 then
		fillp(▒)
	end
	if fade > 0 then
		fade -= 1
 	rectfill(params"0, 0, 127, 127, 0")
	end
	fillp()
 
	do_palette()
	
	-- @enddraw
end

function do_palette()
	pal(10, 131, 1)
	pal(9, 141, 1)
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
 rectfill(4, 11, 36, 18, 0)
 spr(37, 3, 11)
 ?":" .. fruit_count, 10, 13, 7
end

function two_digit_str(x)
 return sub("0" .. x, -2)
end

-- [helper functions]

function round(x)
 return flr(x + 0.5)
end

function appr(val, target, amount)
 return val > target and max(val - amount, target) or min(val + amount, target)
end

function sign(v)
 return v ~= 0 and sgn(v) or 0
end

function tile_at(x, y, in_past)
 return mget(lvl_x + x, lvl_y + y + (in_past and 16 or 0))
end

function spikes_at(x1, y1, x2, y2, xspd, yspd)
 for i = max(0, x1 \ 8), min(lvl_w - 1, x2 / 8) do
  for j = max(0, y1 \ 8), min(lvl_h - 1, y2 / 8) do
   if ({
   			[43] = x1 % 8 <= 2 and xspd <= 0,
	   		[44] = y1 % 8 <= 2 and yspd <= 0,
	     [59] = y2 % 8 >= 6 and yspd >= 0,
	     [60] = x2 % 8 >= 6 and xspd >= 0,
     	
     	-- background spikes
     	[100] = x1 % 8 <= 2 and xspd <= 0,
	   		[101] = y1 % 8 <= 2 and yspd <= 0,
	     [116] = y2 % 8 >= 6 and yspd >= 0,
	     [117] = x2 % 8 >= 6 and xspd >= 0,
     	
     	-- toggle spikes
     	[66] = x1 % 8 <= 2 and xspd <= 0,
	   		[67] = y1 % 8 <= 2 and yspd <= 0,
	     [82] = y2 % 8 >= 6 and yspd >= 0,
	     [83] = x2 % 8 >= 6 and xspd >= 0,
     })[tile_at(i, j, past)] then
      return true
   end
  end
 end
end

function swap_spikes()
	local swaps = {
		[66] = 68,
		[67] = 69,
		[82] = 84,
		[83] = 85,
		
		[68] = 66,
		[69] = 67,
		[84] = 82,
		[85] = 83,
	}
	
	for x = 0, 15 do
		for y = 0, 31 do
			local tile = tile_at(x, y)
			
			if swaps[tile] then
				mset(lvl_x + x, lvl_y + y, swaps[tile])
			end
		end
	end
end
-->8
-- [object definitions]

-- [player entity]

player = {layer = 6}
function player:init()
 self.grace, self.jbuffer = 0, 0
 self.djump = max_djump
 self.dash_time, self.dash_effect_time = 0, 0
 self.dash_target_x, self.dash_target_y = 0, 0
 self.dash_accel_x, self.dash_accel_y = 0, 0
 self.hitbox = rectangle(params"1, 3, 6, 5")
 self.spr_off = 0
 self.collides = true
 self.clamp = true
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
 if self.y < -4 and levels[lvl_id + 1] then
  next_level()
 end

 -- was on the ground
 self.was_on_ground = on_ground
end
function player:draw()
 -- draw player hair and sprite
 set_hair_color(self.djump)
 draw_hair(self)
 draw_obj_sprite(self)
 pal()
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

-- [other objects]

player_spawn = {layer = 6, draw = player.draw}
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
   
   -- create player
			local p = init_object(player, self.x, self.y)
			p.hair = self.hair
			p.in_past = false
  end
 end
end

spring = {}
function spring:init()
 self.hide_in = 0
 self.hide_for = 0
end
function spring:update()
 if self.hide_for > 0 then
  self.hide_for -= 1
  if self.hide_for <= 0 then
   self.spr = 21
   self.delay = 0
  end
 elseif self.spr == 21 then
  local hit = self.player_here()
  if hit and hit.spd.y >= 0 then
   self.spr = 22
   hit.y=self.y - 4
   hit.spd.x *= 0.2
   hit.spd.y = -3
   hit.djump = max_djump
   self.delay = 10
   self.init_smoke()
   -- crumble below spring
   break_fall_floor(self.check(fall_floor, 0, 1) or {})
   psfx"8"
  end
 elseif self.delay > 0 then
  self.delay -= 1
  if self.delay <= 0 then
   self.spr = 21
  end
 end
 -- begin hiding
 if self.hide_in > 0 then
  self.hide_in -= 1
  if self.hide_in <= 0 then
   self.hide_for = 60
   self.spr = 0
  end
 end
end

balloon = {}
function balloon:init()
 self.offset = rnd()
 self.start = self.y
 self.timer = 0
 self.hitbox = rectangle(params"-1, -1, 10, 10")
end
function balloon:update()
 if self.spr == 24 then
  self.offset += 0.01
  self.y = self.start + sin(self.offset) * 2
  local hit = self.player_here()
  if hit and hit.djump < max_djump then
   psfx"6"
   self.init_smoke()
   hit.djump = max_djump
   self.spr = 0
   self.timer = 60
  end
 elseif self.timer > 0 then
  self.timer -= 1
 else
  psfx"7"
  self.init_smoke()
  self.spr = 24
 end
end
function balloon:draw()
 if self.spr == 24 then
  for i = 7, 13 do
   pset(self.x + 4 + sin(self.offset * 2 + i / 10), self.y + i, 6)
  end
  draw_obj_sprite(self)
 end
end

fall_floor = {}
function fall_floor:init()
 self.solid_obj = true
 self.state = 0
end
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
   self.delay = 60-- how long it hides for
   self.collideable = false
  end
  -- invisible, waiting to reset
 elseif self.state == 2 then
  self.delay -= 1
  if self.delay <= 0 and not self.player_here() then
   psfx"7"
   self.state = 0
   self.collideable = true
   self.init_smoke()
  end
 end
end
function fall_floor:draw()
 spr(self.state == 1 and 28 - self.delay / 5 or self.state == 0 and 25, self.x, self.y) -- add an if statement if you use sprite 0 (other stuff also breaks if you do self i think)
end

function break_fall_floor(obj)
 if obj.state == 0 then
  psfx"15"
  obj.state = 1
  obj.delay = 15-- how long until it falls
  obj.init_smoke();
  (obj.check(spring, 0, -1) or {}).hide_in = 15
 end
end

smoke = {layer = 7}
function smoke:init()
 self.spd = vector(0.3 + rnd"0.2", -0.1)
 self.x += -1 + rnd"2"
 self.y += -1 + rnd"2"
 self.flip = vector(rnd() < 0.5, rnd() < 0.5)
end
function smoke:update()
 self.spr += 0.2
 if self.spr >= 16 then
  destroy_object(self)
 end
end

fruit = {check_fruit = true, link_partner = true}
function fruit:init()
 self.start = self.y
 self.off = 0
end
function fruit:update()
 check_fruit(self)
 self.off += 0.025
 self.y = self.start + sin(self.off) * 2.5
end

offset_fruit = {
	check_fruit = true,
	link_partner = true,
	update = fruit.update,
	layer = 1,
}
function offset_fruit:init()
	self.x -= 4
	self.y -= 4
	
	self.start = self.y
	self.off = 0
	
	self.spr = 28
end

fly_fruit = {check_fruit = true} 
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
  local text = init_object(lifeup, self.x, self.y)
  destroy_object(self)
  if self.in_past then
	  if self.partner then
	  	-- getting berry in the past gets the berry in the present
	  	destroy_object(self.partner)
	  else
	   -- if present berry was already obtained, subtract it from the total (cause its destiny was changed so you never actually collected it)
	   fruit_count -= 1
				text.points = " 1000\n-1000"
	  end
	 end
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
 self.points = "1000"
end
function lifeup:update()
 self.duration -= 1
 if self.duration <= 0 then
  destroy_object(self)
 end
end 
function lifeup:draw()
 self.flash += 0.5
 ?self.points, self.x - 4, self.y - 4, 7 + self.flash % 2
end

fake_wall = {layer = 2, link_partner = true}
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
  
  if self.partner and self.in_past then
  	destroy_object(self.partner)
  end
  destroy_object(self)
  --init_fruit(self, 4, 4)
 end
 self.hitbox = rectangle(params"0, 0, 16, 16")
end
function fake_wall:draw()
	if past then
		pal(10, 13)
		pal(3, 6)
	end		
  	
	spr(self.spr, self.x, self.y, 1, 2)
	spr(self.spr, self.x + 8, self.y, 1, 2, true, true)

	pal()
end

function init_fruit(self, ox, oy)
 sfx_timer = 20
 sfx"16"
 init_object(fruit, self.x + ox, self.y + oy, 28).fruit_id = self.fruit_id
 destroy_object(self)
end

flag = {}
function flag:init()
 self.x += 5
end
function flag:update()
 if not self.show and self.player_here() then
  sfx"55"
  sfx_timer, self.show, time_ticking = 30, true, false
 end
end
function flag:draw()
 spr(118 + frames / 5 % 3, self.x, self.y)
 
 if self.show then
  camera(-32, -88)
  rectfill(params"36, 2, 90, 31, 0")
  spr(28, 55, 6)
  ?"X" .. fruit_count, params"64, 9, 7"
  draw_time(49, 16)
  ?"deaths:" .. deaths, params"48, 24, 7"
  camera(draw_x, draw_y)
 end
end

teleporter = {}
function teleporter:init()
	self.start = self.y
	self.off = 0
end
function teleporter:update()
	local hit = self.player_here()
	if hit and hit.dash_effect_time > 1 and fade == 0 then
		hit.dash_effect_time = 0
		fade = 10
		self.init_smoke()
	end
	
	self.off += 0.025
 self.y = self.start + sin(self.off) * 2.5
end

refill_teleporter = {link_partner = true}
function refill_teleporter:init()
	self.timer = 0
	self.start = self.y
	self.off = 0
end
function refill_teleporter:update()
	local hit = self.player_here()
	if self.timer == 0 and hit and hit.dash_effect_time > 1 and fade == 0 then
		hit.dash_effect_time = 0
		fade = 10
		hit.djump = max_djump
		self.init_smoke()
		-- hide both past and present
		self.timer = 60
		self.partner.timer = 60
	end
	if self.timer > 0 then
		self.timer -= 1
		if self.timer == 0 then
			self.init_smoke()
			psfx"7"
		end
	end
	
	self.off += 0.025
 self.y = self.start + sin(self.off) * 2.5
end
function refill_teleporter:draw()
	if (self.timer == 0) draw_obj_sprite(self)
end

crystal = {link_partner = true, layer = 5}
function crystal:init()
	self.collides = true
	self.clamp = true
	self.semisolid_obj = true
end
function crystal:update()
	local hit = self.player_here()
	if hit then
		self.moved = true
		if hit.dash_time > 0 and not self.is_solid(sign(hit.spd.x), 0) then
			self.spd.x = sign(hit.spd.x) * 2
			self.spd.y = -2.4
			hit.spd.x = sign(hit.spd.x) * -2
			hit.spd.y = -1
			hit.dash_time = -1
		else
			self.move(hit.x > self.x and -1 or 1, 0, 0)
		end
	end
	self.spd.x = appr(self.spd.x, 0, 0.1)
	
	local on_ground = self.is_solid(0, 1)
	
	if not on_ground then
  self.spd.y = appr(self.spd.y, 2, abs(self.spd.y) > 0.15 and 0.21 or 0.105)
 	if past and self.in_past then
 		self.moved = true
 	end
 end
 
 -- update partner in future
 if past and self.in_past and self.moved then
		self.partner.x = self.x
		self.partner.y = self.y 	
 end
 if not past then
 	self.moved = false
 end
end

on_block = {layer = 1}
function on_block:init()
	self.potential_solid = true
end
function on_block:update()
	if past ~= self.in_past then
		return
	end
	
	if blocks_on then
		self.solid_obj = false
		self.spr = 65
	else
		self.solid_obj = true
		self.spr = 64
	end
end

off_block = {layer = 1}
function off_block:init()
	self.potential_solid = true
end
function off_block:update()
	if past ~= self.in_past then
		return
	end
	
	if blocks_on then
		self.solid_obj = true
		self.spr = 64
	else
		self.solid_obj = false
		self.spr = 65
	end
end

button = {}
function button:init()
	self.hitbox = rectangle(params"0, 5, 7, 2")
end
function button:draw()
	if self.check(crystal, 0, 0) or self.check(player, 0, 0) then
		pal(11, 3)
	end
	draw_obj_sprite(self)
	pal()
end

invert_switch = {layer = 1}
function invert_switch:init()
	self.solid_obj = true
end
function invert_switch:update()
	local bounce = vector(-1.5, -2)
	
	for x = -1, 1, 2 do
		local hit = self.check(player, x, 0)

		if hit and hit.dash_time > 0 and hit.spd.x ~= 0 then
			invert_blocks(hit)
			hit.spd.x = sign(hit.spd.x) * bounce.x
		end
	end
	
	for y = -1, 1, 2 do
		local hit = self.check(player, 0, y)

		if hit and hit.dash_time > 0 and hit.spd.y ~= 0 then
			invert_blocks(hit)
			hit.spd.y = sign(hit.spd.y) * bounce.y
		end
	end
end
function invert_switch:draw()
	if blocks_inverted() then
		pal(1, 9)
		pal(10, 2)
	end
	draw_obj_sprite(self)
	pal()
end

function invert_blocks(hit)
	hit.dash_time = -1
	if past then
		past_blocks_inverted = not past_blocks_inverted
		present_blocks_inverted = past_blocks_inverted
	else
		present_blocks_inverted = not present_blocks_inverted
	end		
end

function blocks_inverted()
	if past then
		return past_blocks_inverted
	end
	return present_blocks_inverted
end

funnel = {
	layer = 1, 
	solid_obj = true
}
function funnel:init()
	self.dir = 
		self.spr == 114 and vector(0, -1) or
		self.spr == 115 and vector(-1, 0) or
		vector(1, 0) 
		
	self.force = vector(0.3, 0.12)
	
	self.particles = {}
	
	self.cooldown = 1
end
function funnel:update()
	if (past ~= self.in_past) return
	
	-- keep track of where the funnel
	-- ends so particles can delete
	-- themselves there
	local cutoff
	local x, y = 0, 0
	
	for i = 0, 16 do
		if self.is_solid(x, y) then
			cutoff = vector(self.x + x, self.y + y)
			if (self.dir.x < 0) cutoff.x += 8
			if (self.dir.y < 0) cutoff.y += 8
			break
		end
		for other in all(lookup.collides) do
			if other.in_past == past and self.objcollide(other, x, y) then
				other.spd.x += self.dir.x * self.force.x
				if other.type == crystal then
				 other.spd.x = mid(-0.5, other.spd.x, 0.5)
					if (other.in_past) other.moved = true
				end
				
				other.spd.y += self.dir.y * self.force.y
				other.spd.y = max(other.spd.y, -2)
			end
		end
		x += self.dir.x * 8
		y += self.dir.y * 8
		
		-- end of stream
		if i == 16 then
			cutoff = vector(self.x + x, self.y + y)
		end
	end
	
	if self.in_past == past then
		self.cooldown -= 1
		
		-- particles
		if self.cooldown == 0 then
			self.cooldown = 6
			add(self.particles, {
				x = self.x + rnd(7),
				y = self.y + rnd(7),
				xv = self.dir.x,
				yv = self.dir.y,
				c = rnd({3, 11})
			})
		end
	end
	
	for p in all(self.particles) do
		p.x += p.xv
		p.y += p.yv
		
		if self.dir.x == 0 then
			if p.y < cutoff.y then
				del(self.particles, p)
			end
		elseif self.dir.x > 0 then
			if p.x > cutoff.x then
				del(self.particles, p)
			end
		else
			if p.x < cutoff.x then
				del(self.particles, p)
			end
		end
	end
end
function funnel:draw()
	for p in all(self.particles) do
		line(p.x, p.y, p.x - self.dir.x, p.y - self.dir.y, p.c)
	end
	draw_obj_sprite(self)
end

function psfx(num)
 if sfx_timer <= 0 then
  sfx(num)
 end
end

-- [tile dict]
tiles = {}
foreach(split([[
1,player_spawn
21,spring
24,balloon
25,fall_floor
28,fruit
29,fly_fruit
37,offset_fruit
45,crystal
46,refill_teleporter
61,teleporter
64,on_block
65,off_block
80,button
81,invert_switch
97,fake_wall
98,funnel
114,funnel
115,funnel
118,flag
]], "\n"), function(t)
 local tile, obj = unpack(split(t))
 tiles[tile] = _ENV[obj]
end)
-->8
-- [object functions]

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
  hitbox = rectangle(0, 0, 8, 8), 
  spd = vector(0, 0), 
  rem = vector(0, 0), 
  fruit_id = id,
  layer = 5,
  in_past = past,
 }
 
 -- copy type functions and other data
 for k, v in pairs(type) do
 	obj[k] = v
 end
 
 min_layer = min(obj.layer, min_layer)
	max_layer = max(obj.layer, max_layer)

 function obj.left() return obj.x + obj.hitbox.x end
 function obj.right() return obj.left() + obj.hitbox.w - 1 end
 function obj.top() return obj.y + obj.hitbox.y end
 function obj.bottom() return obj.top() + obj.hitbox.h - 1 end

 function obj.is_solid(ox, oy)
  for o in all(lookup.solid) do
   if o ~= obj and (o.solid_obj or o.semisolid_obj and not obj.objcollide(o, ox, 0) and oy > 0) and obj.objcollide(o, ox, oy) then
    return true
   end
  end
  return obj.is_flag(ox, oy, 0) -- solid terrain
 end

 function obj.is_ice(ox, oy)
  return obj.is_flag(ox, oy, 4)
 end

 function obj.is_flag(ox, oy, flag)
  for i = max(0, (obj.left() + ox) \ 8), min(lvl_w - 1, (obj.right() + ox) / 8) do
   for j = max(0, (obj.top() + oy) \ 8), min(lvl_h - 1, (obj.bottom() + oy) / 8) do
    if fget(tile_at(i, j, obj.in_past), flag) then
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
  other.top() <= obj.bottom() + oy and
 	other.in_past == obj.in_past
 end

 function obj.check(type, ox, oy)
  ox = ox or 0
  oy = oy or 0
  for other in all(objects) do
   if other and other.type == type and other ~= obj and obj.objcollide(other, ox, oy) then
    return other
   end
  end
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
     hit.move(
     	axis == "x" and (amt > 0 and obj.right() + 1 - hit.left() or amt < 0 and obj.left() - hit.right() - 1) or 0, 
      axis == "y" and (amt > 0 and obj.bottom() + 1 - hit.top() or amt < 0 and obj.top() - hit.bottom() - 1) or 0, 
      1
     )
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
  init_object(smoke, obj.x + (ox or 0), obj.y + (oy or 0), 13).in_past = obj.in_past
 end

 add(objects, obj)

 if (obj.init) obj:init()
 
 -- add to lookup table
 if obj.solid_obj 
 or obj.semisolid_obj 
 or obj.potential_solid then
  add(lookup.solid, obj)
 end
 if obj.collides then
 	add(lookup.collides, obj)
 end

 return obj
end

function destroy_object(obj)
	del(objects, obj)
	del(lookup.solid, obj)
	del(lookup.collides, obj)
	if (obj.partner) obj.partner.partner = nil
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
	if obj.in_past == past then
		if obj.draw then
			obj:draw()
		else
			draw_obj_sprite(obj)
		end	
	end
end

function draw_obj_sprite(obj)
 spr(obj.spr, obj.x, obj.y, 1, 1, obj.flip.x, obj.flip.y)
end
-->8
-- [level functions]

function next_level()
 local next_lvl = lvl_id + 1

 -- check for music trigger
 if music_switches[next_lvl] then
  music(music_switches[next_lvl], 500, 7)
 end

 load_level(next_lvl)
end

function load_level(id)
 has_dashed, has_key = false, false
	blocks_on, past_blocks_inverted, present_blocks_inverted = false, false, false

 -- remove existing objects
 foreach(objects, destroy_object)
	-- quick lookup table (for performance)
	lookup = {
		collides = {},
		solid = {},
	}
	
	min_layer, max_layer = -5, 0

 -- reset camera speed
 cam_spdx, cam_spdy = 0, 0

 local diff_level = lvl_id ~= id
	if (diff_level) past = false

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
 reload()
 
 -- check for mapdata strings
 if diff_level then
  if mapdata[lvl_id] then
   replace_mapdata(lvl_x, lvl_y, lvl_w, lvl_h, mapdata[lvl_id])
  end
 end
 
 -- levels with only a present
 -- timeline (so don't spawn
 -- objects in past)
 local no_past = {
 	[3] = true,
 	[12] = true,
 }

	-- make objects
 local obj_grid = {}
 for tx = 0, lvl_w - 1 do
		obj_grid[tx] = {}
  for ty = 0, lvl_h + (no_past[lvl_id] and 0 or 15) do
   local tile = tile_at(tx, ty)
   
   if tiles[tile] then
  		local obj = init_object(tiles[tile], tx * 8, (ty % 16) * 8, tile)
  		
  		if obj then
  			obj.in_past = ty > 15
	  		
	  		if ty > 15 and tiles[tile].link_partner then
	 				obj.partner = obj_grid[tx][ty - 16]
	 				if (obj.partner) obj.partner.partner = obj
	  		end
	  		obj_grid[tx][ty] = obj
	  	end
   end
  end
 end
end
-->8
-- [map metadata]

-- @begin
-- level table
-- "x,y,w,h,title"
levels = {
 "0,0,1,1",
 "1,0,1,1",
 "2,0,1,1",
 "3,0,1,1",
 "4,0,1,1",
 "5,0,1,1",
 "6,0,1,1",
 "7,0,1,1",
 "0,2,1,1",
 "1,2,1,1",
 "2,2,1,1",
 "2,1,1,1",
 "3,2,1,1",
 "4,2,1,1",
 "5,2,1,1",
 "6,2,1,1",
 "7,2,1,1,summit",
}

-- mapdata string table
-- assigned levels will load from here instead of the map
mapdata = {

}

-- list of music switch triggers
-- assigned levels will start the tracks set here
music_switches = {
	[9] = 20,
	[17] = 30,
}

-- @end

-- replace mapdata with hex
function replace_mapdata(x, y, w, h, data)
 for i = 1, #data, 2 do
  mset(x + i \ 2 % w, y + i \ 2 \ w, "0x" .. sub(data, i, i + 1))
 end
end

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
  reserve ..= num2hex(mget(i % w, i \ w))
 end
 printh(reserve, "@clip")
end

-- convert mapdata to memory data
function num2hex(v)
 return sub(tostr(v, true), 5, 6)
end
__gfx__
00000000000000000000000008888880000000000000000000000000000000000066666000066600000060000007707770077700000000000000000070000000
00000000088888800888888088888888088888800888880000000000088888800060006000060600000060000777777677777770007700000770070007000007
000000008888888888888888888ffff888888888888888800888888088f1ff18006d0d6000060600000060007766666667767777007770700777000000000000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff800d666d0000d6d00000060007677766676666677077777700770000000000000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000600000006000000060000000000000000000077777700000700000000000
0000000008fffff008fffff00033330008fffff00fffff8088fffff80833338000dd6000000d6000000060000000000000000000077777700000077000000000
00000000003333000033330007000070073333000033337008f1ff1000333300000d600000006000000060000000000000000000070777000007077007000070
000000000070070000700070000000000000070000007000077333700070070000666000000d6000000060000000000000000000000000007000000000000000
56666666666666666666666556666665aaaaaaaa00000000000000000000000000888800d666666dd666666dd666066d00303b00000000000000000000000000
66666666666666666666666666666666a33aaaaa00000000000000000000000008888880611111166111d116611d0616000b3000000777770000000000000000
6666aaaaa666666aaaaa666666666666a33aa3aa000000000000000006666660087888806111111661116116d6d00d1600299200007766700000000000000000
666aaaaaaaa66aaaaaaaa666666aa666aaaaaaaa0d6666d0000000006dd1111608888880611111166d6d0d16000000dd029f9920076777000000000000000000
66aaaaaaaaaaaaaaaaaaaa6666aaaa66aaaaaaaa00500500000000006d1111160888888061111116611d06d66d00000009999f90077660000777770000000000
66aa33aaaaaaaaaaaaa3aa6666aaaa66aa3aaaaa00055000000000006666666608888880611111166111611661d00d6609f99990077770000777767007700000
66aa33aaaaaaaaaaaaaaaa6666a3aa66aaaaa3aa00500500000000006d1001160088880061111116611d111661d0d11600999900070000000700007707777770
66aaaaaaaaaaaaaaaaaaaa6666aaaa66aaaaaaaa000550000d6666d06d11111600000000d666666dd666666ddd00d66d00022000000000000000000000077777
66aaaaaaaaaaaaaaaaaaaa6666aaaa66566666650000000000000000555555555555555555555555555555555500000066656665000770000077770000000000
666aaaaaaaaaaaaaaaaaa666666aaa6666666666003b0b0000000000555005555555555555555550055555556670000067656765007b37000788887000000000
666aaaaaaaaaaaaaaaaaa666666aaa66666a6666000330000000000055000055555555555555550000555555677770006770677007b7b3700782887000000000
6666aaaaaaaaaaaaaaaa666666aaa66666aaaa66002f9200000000005000000555555555555550000005555566600000070007007b733ba70078270000000000
6666aaaaaaaaaaaaaaaa666666aaa66666aaaa6600999f005555555550000005555555555555000000005555550000000700070073b33ba70072170000000000
666aaaaaaaaaaaaaaaaaa666666aa666666aa66600f999005555555555000055555555555550000000000555667000000000000007abba700721127000000000
666aaaaaaaaaaaaaaaaaa666666aa666666666660002200055555555555005555555555555000000000000556777700000000000073aa3700711117000000000
66aaaaaaaaaaaaaaaaaaaa6666aaaa66566666650000000055555555555555555555555550000000000000056660000000000000007777000077770000000000
66aaaaaaaaaaaaaaaaaaaa66666aaa66566666666666666666666665555555555555555550000000000000050000000000000666007777000000000000000000
66aaaaaaaaaaaaaaaaaaaa66666aa66666666666666666666666666655555555505555555500000000000055000000000007777607cccc700000000000000000
66aa3aaaaaaaaaaaa33aaa66666aa6666666aaa6a66aa66a6aaa666655000055555500555550000000000555000000000000076607cacc700000000000000000
66aaaaaaaaaaaaaaa33aaa6666aaa666666aaaaaaaaaaaaaaaaaa666550000555555005555550000000055550070007000000055007ca7000000000000000000
666aaaaaaaa66aaaaaaaa66666aaaa66666aaaaaaaaaaaaaaaaaa666550000555555555555555000000555550070007000000666007a17000000000000000000
6666aaaaa666666aaaaa666666aaaa666666aaa6a6666aaa6aaa666655000055550555555555550000555555067706770007777607a11a700000000000000000
666666666666666666666666666aa666666666666666666666666666555555555555555555555550055555555676567600000766071111700000000000000000
56666666666666666666666556666665566666666666666666666665555555555555555555555555555555555666566600000055007777000000000000000000
0333333000000000aa000000333a333a00000000aaa0aaa000000000000000000777777000000000000000000000000000000000000000000000000000000000
3bbbbbb30333333033b000003b3a3b3aaa000000a3a0a3a000000000000000007777777700000000000000000000000000000000000000000000000000000000
3b0000b3030000303bbbb0003bb03bb0a33300000300030000000000000000007777777700000000000000000000000000000000000000000000000000000000
3b0000b303000030333000000b000b00aa00000003000300000000000000b0007777337700000000000000000000000000006000000000000000000000000000
3b0000b303000030aa0000000b000b0000000000000000000000b000b00b00037777337700000000000000000000000000060600000000000000000000000000
3b0000b30300003033b0000000000000aa00000000000000000b0000300b000b7377333700000000000000000000000000b00060000000000000000000000000
3bbbbbb3033333303bbbb00000000000a333000000000000030b00300b0030b07333bb370000000000000000000000000b00000a000000000000000000000000
03333330000000003330000000000000aa0000000000000003033030030030300333bb30000000000000000000000000b000000a000000000000000000000000
0000000056666665000000000000033300000000000000aa00000000000000000333333000000000000000000000000a0000000a000600000000000000000000
000000006a11aa1600000000000bbbb3000000000000333a000000000000000003b333300000000000000000000000b000000000a060b0000000000000000000
000000006aa11aa60000000000000b3300000000000000aa000000000000003003333330000000000000000000000a00000000000b000b000000000000000000
0000000061aa11a600b000b0000000aa000000000000000000000000000000b00333b33000000000000000000000000000000000000000000000000000000000
00000000611aa11600b000b00000033300300030000000aa000000b000000b300033330000000000000000006666600666006666600666660000000000000000
000000006a11aa1603bb03bb000bbbb3003000300000333a00000b3003000b000004400000000000000000006666660666606666660666666000000000000000
0bbbbbb06aa11aa6a3b3a3b300000b330a3a0a3a000000aa0b00030000b0b3000004400000000000000000006600660066006600000006600000000000000000
d666666d56666665a333a333000000aa0aaa0aaa000000000030330000303300002222000000000000000000ddddd000dd00dddd00000dd00a00000000000000
0000000056666556566666650000000055555555666566650000000000000000007777000000000000000000dd00dd00dd00dd0000000dd000a0000000000000
00000000666666666611111b0000000066755555676567650000000000ee0ee0077777700000000000000000dd00dd0ddd00dd0000000dd000b0000000000000
000000006666aa666111a11b0000000067777555677567750000000000eeeee0073737700000000000000000dd00dd0dddd0dd0000000dd0000b000000000000
00000000666aaaaa61aaaa1b00000000666555555755575500000000000e2e0003bb373000000000000000a0000000000000000000000000000b000000000000
0000000066aaaaaa61aaaa1b000000005555555557555755000e0e0000eeeee0033333300000000000000a000000000000000000000000000000a00000000000
0000000056aa33aa6111a11b0000000066755555555555550000200000ee3ee00033b300000000000000a00000000000000000000000000000000a0000000000
00000000566a33aa6611111b0000bbb06777755555555555000ebe000000b000000440000000000000aa0000000000000000000000000000000000a000000000
00000000666aaaaa56666665442bb32366655555555555550000b0000000b00000222200000000000a000000000000000000000000000000000000a000000000
00000000666aaaaa5bbbbbb5566666655555555555555666004bbb00004b000000400bbb00000000a0000000000000000000000000000000000000a000000000
00000000566aaaaa61111116b11111665555555555577776004bbbbb004bb000004bbbbb0000000100000000000000000000000000000000000000a00a000000
0000000056aa3aaa611aa116b11a1116555555555555576604200bbb042bbbbb042bbb00000000a0000000000000000000000000000000000000001010a00000
0000000066aaaaaa61aaaa16b1aaaa165575557555555555040000000400bbb004000000000001000000000000000000000000000000000000000001000a0000
00000000666aaaaa611aa116b1aaaa16557555755555566604000000040000000400000000000100000000000000000000000000000000000000000000010000
000000006666aa66611aa116b11a1116567756775557777642000000420000004200000000000100000000000000000000000000000000000000000000001000
000000006666666666111166b1111166567656765555576640000000400000004000000000000000000000000000000000000000000000000000000000000000
00000000566665665666666556666665566656665555555540000000400000004000000000010000000000000000000000000000000000000000000000000010
12121212131313131313132346825702121212411212121212121212220000001212131241122200000002131313131212121212121212122200000212121212
828282920003131313131313131313121213131313132304040313131313131212121212411212121212220000021212000000a28200000000a3820000a28282
12121323565656c2c2c2c2c2a2825702131313131313131313131313231414141222c10313132304040432b200d3c30212411212121313132301210212124112
8200000000001400000000a28282820222c2c2c2c2c2c23434c2c256565656021212131312121212121222000002121200000000829300000082920000d38282
41221600a282828100000000008257020000144400350400a282828292000000122304a382829200000033b20000c30212131313238282824202220212121212
8293007500001400d3000000a27282022200000000000081000000a2828282021222b2e202121212411222000002121200000000a28200000082000000008282
12220052008283930000000000a2570200001444003504000000a282000000002246838292840000000014000000c30222828282828283820112220213131312
1111112100001400760000000005a20222008100b3b3b30000b3b3b3a27282021222b20003131313131323141403131382930000a38293a3829200000000a282
1213112100a28247b3b3b3b30000c3027610144400350400d200a3829300000022468282008500000000140000a3570222a282827382828203132332b2d3c302
12131313111111112100000001111112220000a3011121b2c3011121a38282021222b200c2c2c2c2568282000082920000a2930082a282828200000000000082
22d202220000820153535321b200c302111121b200c301112145011121b200002246829201111121000014a382825702220000a2920000a201111122b200c302
2282838203131312220000000212121222a38282021222b2c3021222838282021222b281000081a372829200a382000000008282920082829200000000000082
220402224200473215151532b200c302121222b200c302122214024122b2810022151515031313135311214682728202221414140121040402121222b200c302
228282920000a202220000000241121222468357024122b2c3021222829200021222b3b3b3b3b34747820000828305000000a2820000a272930000006536a382
2200022243630122b200c332b351b302121222b2e2c303122205021223b20000220000a2828282828202224682829203225454540222000002121222b2a35702
2292000000d20002230404040312121222b2a257021222b2c3021222000000021212111111111111111121a3820111110000a382000000828282930111111111
2214022200c30222b281c30211111112121222b20000150212111222b20000002200000082738292000222b2a2820000220000000222000002411222b2825702
1221436343535323820000000002121222b2e2c3021222b2c302412200000002121212121212121212122292000212410000a282930000820111111212121212
2200022200c30222b2a3570212411212411222b200a3150213131323b20081002200000047470000000322b2a382000022741000022200000212132346825702
122200000000a2828293000000021241224693c30212222525021222454545021212121313131312411223040403121200000082820000011212121212121212
2304032314140323b282570313131312121222b20057022215565656930000002214141401210000a35702111121b200121111111222141403230000a2728202
122200d30000000082830000000212122246825703132304040313231414140213132382828282031222820000000313000000a2839365021212411212121212
0000a282930000040082831400a25702121222b2a3570222158282828283930022b200c30222a382825703131323b200121313131322930000000000a3829202
1222000000000000a28293000002121222829200000400000082829200000002000000a292008282022382000000000000000000828201121212121212121212
00000082738293040082921400d357021212224747470222158272828282828222b200c302224782839200000004000022000000373282829300750082279302
1323829300000010004747b305021212228200000004000000a2730000c10002000000000000a28233829200000000d3000000a3828202121212121212121212
7410a39205a28204a382001475a357021212121111111212121111214747474722b200c302122182820000650004000023d20000011211111111111111111112
26048282828201634201111111121212229210007504000000748293004200020010000575000000a28200d20076000000107401111112121212121212411212
111111111111111111111111111111121212121212121212411212121111111122b210c302412273829301111121b3b326050505021241121212121212121212
11111111214323011112121241121212224353630111210404011111211501121111111121040400008301111111111111111112121241121212121212121212
12121212124112121212121212121212121241121212121212121212121212121211111112122282828202124112111111112127021212121212121212411212
1212124112111112121212121212121212111111121222272702124112111212121241122200000000a202121212121212121212121212121212121212121212
12121212131313131313132346825702121212411212121212121212220000001212131241122200000002131313131212121212121212122200000212121212
828282920003131313131313131313121213131313132304040313131313131212121212411212121212220000021212000000a28200000000a3820000a28282
12121323565656c2c2c2c2c2a2825702131313131313131313131313231414141222000313132304040432b200d3c30212411212121313132300000212124112
8200000000311400000000a28282820222c2c2c2c2c2c23434c2c256565656021212131312121212121222436302121200000000829300000082920000d38282
41221600a282828100000000008257020000144400350400a282318292000000122300a382829200000033b20000c30212131313238282828293000212121212
8293004201221400d3000000a27282022200000000000081000000a2828282021222b2e202121212411222000002121200000000a28200000082000000008282
12220052008283930000000000a25702000014440035040000003242000000002246838292000000000014000000c30222828282828283829282000213131312
1111112103231400660000000005a20222008100b3b3b30000b3b3b3a27282021222b20003131313131323141403131382930000a38293a3829200000000a282
1213112100a28247b3b3b3b30000c3026600144400350400d20003639300000022468282008600000000140000a3570222a282827382828200a29332b2d3c302
12131313111111112100000001111112220000a3011121b2c3011121a38282021222b200c2c2c2c2568282000082920000a2930082a282828200000000000082
22d202220000820153535321b200c302111121b200c301112145011121b200002246829201111121000014a382825702220000a2920000a201111122b200c302
2282838203131312220000000212121222a38282021222b2c3021222838282021222b281000081a372829200a382000000008282920082829200000000000082
220402220000473215151532b200c302121222b200c302122214024122b2810022151515031313135311214682728202221414140121040402121222b200c302
2282829200000002220000000241121222468357024122b2c3021222829200021222b3b3b3b3b34747820000828305000000a2820000a272930000006775a382
2200022200000122b200c332b351b302121222b2e2c303122205021223b20000220000a2828282828202224682829203225454540222000002121222b2a35702
2292000000d20002230404040312121222b2a257021222b2c3021222000000021212111111111111111121a3820111110000a382000000828282930111111111
2214022200c30222b281c30211111112121222b20000150212111222b20000002200000082738292000222b2a2820000220000000222000002411222b2825702
1221000043535323820000000002121222b2e2c3021222b2c302412200000002121212121212121212122292000212410000a282930000820111111212121212
2200022200c30222b2a3570212411212411222b200a3150213131323b20081002200000047470000000322b2a382000022640000022200000212132346825702
12220000000042318293000000021241224693c30212222525021222454545021212121313131313131323040403121200000082820000011212121212121212
2304032314140323b282570313131312121222b25157022215565656930000002214141401210000a35702111121b200121111111222141403230000a2728202
122200d30000012282830000000212122246825703132304040313231414140213132382828282574682820000000313000000a2839374021212411212121212
0000a282930000040082831400a25702121222b291570222158282828283930022b200c30222a382825703131323b200121313131322930000000000a3829202
1222000000000223a28293000002121222829200000400000082829200000002000000a292008257468282000000000000000000828201121212121212121212
00000082738293040082921400d357021212224747470222158272828282828222b200c302224782839200000004000022000000373282829300650082279302
1323829300003200004747b305021212228200000004000000a2730000000002000000000000a25746829200000000d3000000a3828202121212121212121212
6400a39205a28204a382001465a357021212121111111212121111214747474722b200c302122182820000750004000023d20000011211111111111111111112
260482828282320000011111111212122292000065040000006482930000000200000005650000c3468200d20066000000006401111112121212121212411212
111111111111111111111111111111121212121212121212411212121111111122b200c302412273829301111121b3b326050505021241121212121212121212
111111112142330111121212411212122243536301112100000111112115011211111111210404c3468301111111111111111112121241121212121212121212
12121212124112121212121212121212121241121212121212121212121212121211111112122282828202124112111111112127021212121212121212411212
121212411211111212121212121212121211111112121211111212411211121212124112220000c3b2a202121212121212121212121212121212121212121212
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000006000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000060000000000000060600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000b00060000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000b00000j000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000b070000j000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000j0000000j000600000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000b000000000j060b0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000j00000000000b000b000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000006666600666006666600666660000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000006666660666606666660666666000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000006600660066006600000006600000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000ddddd000dd00dddd00000dd00j00000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dd00dd00dd00dd0000000dd000j0000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dd00dd0ddd00dd0000000dd000b0000000000000000000070000000000000000000000000000
0000000000000000000000000000000000000000000000000000dd00dd0dddd0dd0000000dd0000b000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000j0000000000000000000000000000b000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000j000000000000000000000000000000j00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000j00000000000000000000000000000000j0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000jj0000000000000000000000000000000000j000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000j000000000000000000000000000000000000j000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000j0000000000000000000000000000000000000j000000000000000000000000000000000000000000000
0000000000000007000000000000000000000000000100000000000000000000000000000000000000j00j000000000000000000000000000000000000000000
000000000000000000000000000000000000000000j0000000000000000000000000000000000000001010j00000000000000000000000000000000000000000
000000000000000000000000000000000000000001000000000000000000000000000000000000000001000j0000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000
00000000000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000060000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000700000005505055005005550555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066600667660000006660606000000660066006600660066006606000600000000000000000000000000000000000
00000000000000000000000000000000000066606060606000006060606000006060606060606060600060006000600000000000000000000000000000000000
00000000000000000000000000000000000060606060606000006600666000006060606060606060600060006000600000000000000000000000000000000000
00000000000000000000000000000000000060606060606000006060006000006060606060606060606060606000600000000000000000000000000000000000
00000000000000000000000000000000000060606600666000006660666000006600660066006600666066606660666000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005577555055005500505000005550505005505550055005505500000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050505050505000000500505050505050500050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050555050505050555000000500555050505500555050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050505050005000000500505050505050005050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505055505550555000000500505055005050550055005050000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005500055055505000000055505550555055505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000003030303030000000000000000000000030303030300040404040402020000000303030303030304040404020200000000000404040404040400020202020202000004040404040404020202020202020000000202020404040202020202020200000000020200000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2121212131313200000000002a28282021212121211421212228283728283021211421313131313121222b00003c20212121142121213131312132000028202121212114212121212121212200000020212121212131313131320000000000002200002021211421212121212121212121212121213131313131313131320000
2121142200000000003436000038282021212121212121212224282828290020212132002838282830222b00003c2021212121313132003d003300003a28202121213131212121212114212200002420212114213228282900000000000000002200002021212121212121211421212121212121222c2c2c2c65282800400000
2121212200000024101112000028292021142121313131313111122947000020212200002a28283728232b40003c2014212132000040000000410000287420212122610030313131313131222410122021212122643828000000000000000000224141303131313131313131313121212121142122002e00182a382800400000
212121211200343531313224002a1021212131322829002a28303111123d00202122002d00572a2828232b00003c202121222b0000400047004100001011212121320025002a282828290033343132202121212264282800003d000000000000220000000000402a282839000000202121212121223b3b3b3b3b282900400057
212121212111360000003411111121212132282900000000283828302200002021211111353536002a232b00003c202121226400003435353535111121212121222b00000000002a2800000000003c20212121226428290000000000000000002200002e00004000002a38282839202121313131211111111112280055101111
21142121313200000000282021212121220000000000003a28282800233b0020212131322800000000332b00403c202121322800003a28000000302114212121222b000000003b3b2839003d00003c2021212122290000000000004141410000223b3b3b3b3b400000002a283728202122393a75203131313122290055202121
212121322a283900003a28303121142122390000003d00283728290023243b2021322828290000000000000000752021222838390028293d0000002021212121222b0000000010122828000000003c20211421220000003b3b3b3b3b3b3b747421111111111135361300003a282a202122282875236565656523000055201421
2131323900282828382828000020212122743b0000003a2874740000331324202264283800000000000000003a7520212228282828280000003a282021212121222b00003b3b202274743b0000003b20212131320000003435353535111111112121211421220000233a28282900202122283775336428387523545454202121
32002a2828282829002a2839003021212111123b0000287410122b002420122022642829000000480000000028742021211136282810111112642830212114213241414134353131353536404040342121222b40000000402a2839283031312121212121212200003328290000002021222829002d00002a7533414141202121
000000002837280000002828000030212131313600002a3421223b3b1031322022642800000000580050003a28102121212228372820212132642829302121210000000000282828282829000000002021222b4000000040002a2828290000202114212131322d00240000570050202122343536133b3b3b5000000000202121
0000003a2828290000002a38003d002032000000000000283021122433241021211136404040341111111111112121212132282875303132642900000020212100000000002a3828282800000000002021222b40002e00400000382800002d20313131322829193436414134353521142200003c203535353600000000202121
000100281012000000003a28390047200000000000003a38282021111111212121320000000000302121212121211421222829000000242828000000002021210000000000482828372900000000002021222b4000000040003a2829003435212a28756428000000400000000000202122002e3c330000000000000053202121
1111111121223b3b3b3b741011111121000100473b157428282021212121142122000000000000002021212121212121220000000000132829000050462021210001005000582a28280000002d00572021222b400000004000282800000000200028756429000000400000003d3a202122000053400000000000000053202114
21142121212111111111112121211421111111123435361011212121212121212200014650002d002021212121212121220001002d00332400571011112121211111111111123a28281011111111112121223b3b3b3b3b3b3a37280001475020502a7564000100474000003a2828202122000153405252525252521552202121
212121212121142121212121212121212121212111111121212114212121212121111111111111112121142121212121211111111111111111112121211421212114212121227474742021212121211421211111111111122828281011111121111111111111111112003a101111212121111111111111111111111111212121
2121212121212121212121212121212121142121212121212121212121212121212121212121212121212121212121212121211421212121212121212121212121212121212111111121211421212121212121211421212228282820212114212121212121212121222828202121142121212121211421212121212121212121
2121212131313131313200002a28282021212121211421212224202220323021212121212121212114212121220000002121142121213131312132000028202121212114212121212121212200000020212121212131313131320000000000002200002021211421212121212121212121212121213131313131313131320000
212114221012343600000000003828202121212121212121223431223324002021212121212121212121212122000000212121313132003d003300003a28202121213131212121212114212200000020212114213228282900000000000000002200002021212121212121211421212121212121222c2c2c2c65282800400000
212121223021120000000000002829202114212131313131311112332400002021211421313131313131313132404040212132000040000000410000287420212122610030313131313131224040402021212122643828000000000000000000224141303131313131313131313121212121142122002e00182a382800400000
212121211230320000000068002a1021212131322829002a28303111123d0020212121226565652c000000000000000021222b0000400046004100001011212121320025002a282828290033000000202121212264282800003d000000000000220000000000402a132839000000202121212121223b3b3b3b3b282900400056
21212121211136000000341111112121213228290000000028382830220000202121212264372900000000000000003a21226400003435353535111121212121222b00000000002a2800000000003c20212121226428290000000000000000002200002e00004000232a38282839202121313131211111111112280055101111
21142121313200000000282021212121220000000000003a2828280023001820212121226428003b3b000057003a282821322800003a28000000302114212121222b000000003b3b2839003d00003c2021212122290000000000004141410000223b3b3b3b3b402433002a283728202122343536203131313122290055202121
212121322a283900003a28303121142122390000003d002837282900230000202114212264293c101200001011111111222838390028293d0000002021212121222b0000000010122828000000003c20211421220000003b3b3b3b3b3b3b747421111111111135353600003a282a202122282875236565656523000055201421
2131323900282828382828000020212122743b0000003a287474000033000020313131322b003c2022000030313131312228282828280000003a282021212121222b00003b3b202274743b0000003b20212131320000003435353535111111112121211421220000003a28282900202122283775336428387523545454202121
32002a2828282829002a2839003021212111123b3b15747410122b00000000200000000000003c202200002c65652928211136282810111112642830212114213241414134353131353536404040342121222b40000000402a2839283031312121212121212200000028290000002021222829002d00002a7533414141202121
00000000283728000000282800003021213131363435363421223b0000003b2000000000003a75202200183a3828002a212228372820212132642829302121210000000000282828282800000000002021222b4000000040002a2828290000202114212131322d0000000056005020212200003c133b3b3b5000000000202121
0000003a2828290000002a38003d002032000000000000283021123b3b3b10210000000000287520223b3b74747400502132282875303132642900000020212100000000002a3828282800000000002021222b40002e00400000382800002d20313131322829193436414134353521142200003c203535353600000000202121
000000281012000000003a28390046200000000000003a382820211111112121000100560028752021111111111111112228290000002a2828000000002021210000000000002828372900000000002021222b4000000040003a2829000000202a28756428000000400000000000202122002e3c330000000000000053202121
1111111121223b3b3b3b74101111112100000046000028282820212121211421111111123a2875202131313131313131220000000000002829000050002021210046005000682a28280000002d00562021222b400000004000282800000000200028756429000000400000003d3a202122000053401300000000000053202114
2114212121211111111111212121142111111112003a2810112121212121212121212122282875202250002d00400073220000002d003a2800561011112121211111111111123a28281011111111112121223b3b3b3b3b3b3a37280046343620502a7564000000464000003a2828202122000053403324525252521552202121
212121212121142121212121212121212121212111111121212114212121212114212122727272202111111111111111211111111111111111112121211421212114212121227474742021212121211421211111111111122828281011111121111111111111111112003a101111212121111111111111111111111111212121
2121212121212121212121212121212121142121212121212121212121212121212121211111112121212121211421212121211421212121212121212121212121212121212111111121211421212121212121211421212228282820212114212121212121212121222828202121142121212121211421212121212121212121
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
00020500167701b7700f7700f7700f7700f7000f7000f7000f7000f70000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
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

