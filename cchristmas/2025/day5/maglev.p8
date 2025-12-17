pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- maglev
-- 

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

--global tables
objects,got_fruit={},{}
--global timers
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
--global camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

-- [magnet sprite]

magnet_spr_right=21
magnet_spr_up=28

-- [magnet unlock flags]

magnet_unlocked=false
magnet_flag=2

-- [entry point]

local demo = '-4,52,12,130,1,1|10,107,27,130,1,1|28,82,62,127,1,1|33,76,48,87,1,1|53,77,60,84,1,1|53,76,60,87,1,1|60,109,59,110,1,2|55,113,82,127,1,1|82,34,106,129,1,1|87,30,101,41,1,1|94,18,94,39,1,1|103,118,126,128,1,1|125,104,131,126,1,1|121,103,138,120,1,1'

function _init()
	frames,start_game_flash=0,0
	music(40,0,7)
	lvl_id=0
	stars_init(45)
	bg = parse_bg(demo)
end

function begin_game()
	max_djump=0
	deaths,frames,seconds,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,0
	music(0,0,7)
	load_level(1)
end

function is_title()
	return lvl_id==0
end

-- [effects]

clouds={}
for i=0,16 do
	add(clouds,{
		x=rnd"128",
		y=rnd"128",
		spd=1+rnd"4",
	w=32+rnd"32"})
end

particles={}
for i=0,24 do
	add(particles,{
		x=rnd"128",
		y=rnd"128",
		s=flr(rnd"1.25"),
		spd=0.25+rnd"5",
		off=rnd(),
		c=6+rnd"2",
	})
end

dead_particles={}

-- [function library]

function psfx(num)
	if sfx_timer<=0 then
		sfx(num)
	end
end

function round(x)
	return flr(x+0.5)
end

function appr(val,target,amount)
	return val>target and max(val-amount,target) or min(val+amount,target)
end

function sign(v)
	return v~=0 and sgn(v) or 0
end

function two_digit_str(x)
	return x<10 and "0"..x or x
end

function tile_at(x,y)
	return mget(lvl_x+x,lvl_y+y)
end

function spikes_at(x1,y1,x2,y2,xspd,yspd)
	for i=max(0,x1\8),min(lvl_w-1,x2/8) do
		for j=max(0,y1\8),min(lvl_h-1,y2/8) do
			if({[17]=y2%8>=6 and yspd>=0,
			[27]=y1%8<=2 and yspd<=0,
			[43]=x1%8<=2 and xspd<=0,
			[59]=x2%8>=6 and xspd>=0})[tile_at(i,j)] then
				return true
			end
		end
	end
end

function find_magnet_target(px,py,dx,dy)
    local max_range = 128 -- pixels ahead (3 tiles)

    for i=1,max_range do
        local tx = px + dx*i
        local ty = py + dy*i
        local mx = flr(tx/8)
        local my = flr(ty/8)

        -- stop searching if out of bounds
        if mx < 0 or mx >= lvl_w or my < 0 or my >= lvl_h then
            return nil
        end

        local tile = mget(lvl_x+mx, lvl_y+my)

        -- magnet tile found ヌ●★ return center
        if fget(tile, 2) then
            return mx*8 + 4, my*8 + 4
        end

        -- solid blocks stop the search (wall blocks vision)
        if fget(tile, 0) then
            return nil
        end
    end

    return nil
end

stars = {}
stars_inited = false

function stars_init(count)
	-- only build once
	if stars_inited then return end

	stars = {}
	for i=1,count do
		add(stars, {
			x = rnd(128),                -- screen coords
			y = rnd(128),
			phase = rnd(),               -- twinkle phase
			speed = 0.01 + rnd(0.02),    -- twinkle speed
			burst = 0,                   -- burst timer
		})
	end

	stars_inited = true
end

function stars_update()
	for s in all(stars) do
		-- natural twinkle
		s.phase += s.speed

		-- occasional burst
		if s.burst <= 0 and rnd() < 0.005 then
			s.burst = 0.6     -- lasts ~0.6s
		end

		-- decay burst
		if s.burst > 0 then
			s.burst -= 0.02
		end
	end
end

function stars_draw()
	-- no camera involved, just draw on the screen
	for s in all(stars) do
		local b = sin(s.phase)

		-- base flicker color
		local col =
  b > 0.4 and 10 or    -- bright color
  b < -0.4 and 1 or 5    -- dim color

		if s.burst > 0 then
			col = 7 or 10
			if s.burst > 0.3 then
				-- little bloom at peak of burst
				pset(s.x,   s.y,   col)
				pset(s.x+1, s.y,   col)
				pset(s.x-1, s.y,   col)
				pset(s.x,   s.y+1, col)
				pset(s.x,   s.y-1, col)
			else
				pset(s.x, s.y, col)
			end
		else
			pset(s.x, s.y, col)
		end
	end
end
  
-->8
-- [update loop]

function _update()
	frames+=1
	if time_ticking then
		seconds+=frames\30
		minutes+=seconds\60
		seconds%=60
	end
	frames%=30

	if music_timer>0 then
		music_timer-=1
		if music_timer<=0 then
			music(10,0,7)
		end
	end

	if sfx_timer>0 then
		sfx_timer-=1
	end

	-- cancel if freeze
	if freeze>0 then
		freeze-=1
		return
	end
	
	stars_update()

	-- restart (soon)
	if delay_restart>0 then
		cam_spdx,cam_spdy=0,0
		delay_restart-=1
		if delay_restart==0 then
			load_level(lvl_id)
		end
	end

	-- update each object
	foreach(objects,function(obj)
		obj.move(obj.spd.x,obj.spd.y,0);
		(obj.type.update or stat)(obj)
	end)

	--move camera to player
	foreach(objects,function(obj)
		if obj.type==player or obj.type==player_spawn then
			move_camera(obj)
		end
	end)

	-- start game
	if is_title() then
		if start_game then
			start_game_flash-=1
			if start_game_flash<=-30 then
				begin_game()
			end
		elseif btn(🅾️) or btn(❎) then
			music"-1"
			start_game_flash,start_game=50,true
			sfx"38"
		end
	end
end
-->8
-- [draw loop]

function _draw()
	if freeze>0 then
		return
	end

	-- reset all palette values
	pal()

	-- start game flash
	if is_title() then
		if start_game then
			for i=1,15 do
				pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
			end
		end

		cls()

		-- credits
		sspr(unpack(split"72,32,56,32,36,32"))
		?"🅾️/❎",55,80,5
		?"maddy thorson",40,96,5
		?"noel berry",46,102,5
		?"mod by merl_ + wisper",22,114,5

		-- particles
		foreach(particles,draw_particle)

		return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)

		-- bg clouds effect (these are behind stars)
	foreach(clouds,function(c)
		c.x+=c.spd-cam_spdx
		rectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col)
		if c.x>128 then
			c.x=-c.w
			c.y=rnd"120"
		end
	end)

  -- draw twinkling stars on top of the clouds, still in screen space
	stars_draw()
	
	draw_bg(bg)

	--set cam draw position
	draw_x=round(cam_x)-64
	draw_y=round(cam_y)-64
	camera(draw_x,draw_y)


	-- draw bg terrain
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4)
	
	--set draw layering
	--positive layers draw after player
	--layer 0 draws before player, after terrain
	--negative layers draw before terrain
	local pre_draw,post_draw={},{}
	foreach(objects,function(obj)
		local draw_grp=obj.layer<0 and pre_draw or post_draw
		for k,v in ipairs(draw_grp) do
			if obj.layer<=v.layer then
				add(draw_grp,obj,k)
				return
			end
		end
		add(draw_grp,obj)
	end)

	-- draw bg objects
	foreach(pre_draw,draw_object)
	
	-- draw terrain
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,2)
	
	-- draw fg objects
	foreach(post_draw,draw_object)

	-- draw jumpthroughs
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,8)

	-- particles
	foreach(particles,draw_particle)

	-- dead particles
	foreach(dead_particles,function(p)
		p.x+=p.dx
		p.y+=p.dy
		p.t-=0.2
		if p.t<=0 then
			del(dead_particles,p)
		end
		rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14+5*p.t%2)
	end)

	-- draw level title
	camera()
	if ui_timer>=-30 then
		if ui_timer<0 then
			draw_ui()
		end
		ui_timer-=1
	end
	pal(15,128,1)
end

function draw_particle(p)
	p.x+=p.spd-cam_spdx
	p.y+=sin(p.off)-cam_spdy
	p.off+=min(0.05,p.spd/32)
	rectfill(p.x+draw_x,p.y%128+draw_y,p.x+p.s+draw_x,p.y%128+p.s+draw_y,p.c)
	if p.x>132 then
		p.x=-4
		p.y=rnd"128"
	elseif p.x<-4 then
		p.x=128
		p.y=rnd"128"
	end
end

function draw_time(x,y)
	rectfill(x,y,x+32,y+6,0)
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds),x+1,y+1,7
end

function draw_ui()
	rectfill(24,58,104,70,0)
	local title=lvl_title or lvl_id.."00 m"
	?title,64-#title*2,62,7
	draw_time(4,4)
end

function parse_bg(s)
    local data,out = split(s,"|"),{}
   
    -- create table of shapes
    for i = 1,#data do
        out[i]=split(data[i])
    end
   
    return out
end

function draw_bg(bg)
    for i=1,#bg do
        local cur = bg[i]
       
        -- cache properties
        s1,s2,s3,s4,s5,s6=
        cur[1],cur[2],
        cur[3],cur[4],
        cur[5],cur[6]
       
        -- circle filled
        if not s5 then
            circfill(s1,s2,s3,s4)
           
     -- circle outlined
        elseif not s6 then
            circ(s1,s2,s3,s4)
           
        -- rectangle filled
        elseif s6==1then
            rectfill(s1,s2,s3,s4,s5)
           
        -- rectangle outlined
        elseif s6==2then
            rect(s1,s2,s3,s4,s5)
           
        end
    end
   
end

-->8
-- [player class]

player={
	init=function(this)
		this.grace,this.jbuffer=0,0
		this.djump=max_djump
		this.dash_time,this.dash_effect_time=0,0
		this.dash_target_x,this.dash_target_y=0,0
		this.dash_accel_x,this.dash_accel_y=0,0
		this.hitbox=rectangle(1,3,6,5)
		this.spr_off=0
		this.collides=true
		create_hair(this)
		
		this.magnet_active = false
  this.magnet_dirx = 0
  this.magnet_diry = 0
  this.magnet_target_x = 0
  this.magnet_target_y = 0
  this.magnet_speed = 0
  
  -- remember which level we were created in
		this.last_lvl_id = lvl_id
		
		this.layer=1
	end,
	update=function(this)
		if pause_player then
			return
		end
		
		if self_last_lvl_id ~= lvl_id then
 	self_last_lvl_id = lvl_id
 		this.magnet_active = false
 		this.magnet_speed = 0
		end

		if this.last_lvl_id ~= lvl_id then
			this.magnet_active = false
			this.magnet_dirx = 0
			this.magnet_diry = 0
			this.magnet_target_x = 0
			this.magnet_target_y = 0
			this.magnet_speed = 0
			this.last_lvl_id = lvl_id
		end

		-- horizontal input
		local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0

		-- spike collision / bottom death
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end

		-- on ground checks
		local on_ground=this.is_solid(0,1)

		-- landing smoke
		if on_ground and not this.was_on_ground then
			this.init_smoke(0,4)
		end

		-- jump and dash input (dash disabled)
local jump,dash = btn(🅾️) and not this.p_jump, false
this.p_jump,this.p_dash = btn(🅾️), btn(❎)

		
		-- jump buffer
		if jump then
			this.jbuffer=4
		elseif this.jbuffer>0 then
			this.jbuffer-=1
		end

		-- grace frames and dash restoration
		if on_ground then
			this.grace=6
			if this.djump<max_djump then
				psfx"54"
				this.djump=max_djump
			end
		elseif this.grace>0 then
			this.grace-=1
		end

		-- dash effect timer (for dash-triggered events, e.g., berry blocks)
		this.dash_effect_time-=1

		-- dash startup period, accel toward dash target speed
		if this.dash_time>0 then
			this.dash_time-=1
			this.spd=vector(appr(this.spd.x,this.dash_target_x,this.dash_accel_x),appr(this.spd.y,this.dash_target_y,this.dash_accel_y))
		else
		
			-- x movement
			local maxrun=1
			local accel=this.is_ice(0,1) and 0.05 or on_ground and 0.6 or 0.4
			local deccel=0.15

			-- set x speed
			this.spd.x=abs(this.spd.x)<=1 and
			appr(this.spd.x,h_input*maxrun,accel) or
			appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)

			-- facing direction
			if this.spd.x~=0 then
				this.flip.x=this.spd.x<0
			end

			-- y movement
			local maxfall=2

			-- wall slide
			if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) and not this.magnet_active then
				maxfall=0.4
				-- wall slide smoke
				if rnd"10"<2 then
					this.init_smoke(h_input*6)
				end
			end

			-- apply gravity
			if not on_ground then
				this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.15 and 0.21 or 0.105)
			end
			
			-- if magnet is active and input direction changes, cancel current pull
			if this.magnet_active and btn(❎) then
				-- compute current intended magnet direction (same priority as start)
				local cur_dx,cur_dy = 0,0
				if btn(⬆️) then
					cur_dy = -1
				elseif btn(⬇️) then
					cur_dy = 1
				elseif btn(➡️) then
					cur_dx = 1
				elseif btn(⬅️) then
					cur_dx = -1
				end

				-- if player is aiming a *different* direction than the active magnet, cancel it
				if (cur_dx ~= 0 or cur_dy ~= 0) and (cur_dx ~= this.magnet_dirx or cur_dy ~= this.magnet_diry) then
					this.magnet_active = false
					this.magnet_speed = 0
				end
			end
			
			-- start magnet movement on ❎
if magnet_unlocked and btn(❎) and not this.magnet_active then
    local dx,dy = 0,0

    -- vertical has priority over horizontal
    if btn(⬆️) then
        dy = -1
    elseif btn(⬇️) then
        dy = 1
    elseif btn(➡️) then
        dx = 1
    elseif btn(⬅️) then
        dx = -1
    end

    -- if no input, fall back to facing
    if dx == 0 and dy == 0 then
        dx = this.flip and this.flip.x and -1 or 1
    end

    local tx,ty = find_magnet_target(this.x+4,this.y+4,dx,dy)

    if tx then
        this.magnet_active = true
        this.magnet_dirx = dx
        this.magnet_diry = dy
        this.magnet_target_x = tx
        this.magnet_target_y = ty
        this.magnet_speed = 2.7
        maxfall = 10
    end
end

-- apply magnet movement override
if this.magnet_active then
    -- cancel magnet as soon as x is released
    if not btn(❎) then
        this.magnet_active = false
    else
    
        -- acceleration
        this.magnet_speed+=.2
        if this.magnet_speed>5 then
         this.magnet_speed=5
        end
        -- still pulling: override speed
        this.spd.x = this.magnet_dirx * this.magnet_speed
        this.spd.y = this.magnet_diry * this.magnet_speed

        local cx = this.x + 4
        local cy = this.y + 4
        local done = false

        if this.magnet_dirx == 1 and cx >= this.magnet_target_x then done = true end
        if this.magnet_dirx == -1 and cx <= this.magnet_target_x then done = true end
        if this.magnet_diry == 1 and cy >= this.magnet_target_y then done = true end
        if this.magnet_diry == -1 and cy <= this.magnet_target_y then done = true end

        if done then
            this.spd.x = 0
            this.spd.y = 0
            this.magnet_active = false
        else
        -- stat(49) gets the sfx playing on channel 3
        -- -1 means no sound playing
         if stat(49) == -1 then
          sfx(63, 3)
         end
        end
    end
end

			-- jump
			if this.jbuffer>0 then
				if this.grace>0 then
					-- normal jump
					psfx"1"
					this.jbuffer=0
					this.grace=0
					this.spd.y=-2
					this.init_smoke(0,4)
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
				 this.magnet_active=false
				 
					if wall_dir~=0 then
						psfx"2"
						this.jbuffer=0
						this.spd=vector(wall_dir*(-1-maxrun),-2)
						if not this.is_ice(wall_dir*3,0) then
							-- wall jump smoke
							this.init_smoke(wall_dir*6)
						end
					end
				end
			end

			-- dash
			local d_full=4
			local d_half=2.5355339059 -- 5 * sqrt(2)

			if this.djump>0 and dash then
				this.djump-=1
				this.dash_time=4
				has_dashed=true
				this.dash_effect_time=10
				-- vertical input
				local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0
				-- calculate dash speeds
				this.spd=vector(h_input~=0 and
					h_input*(v_input~=0 and d_half or d_full) or
					(v_input~=0 and 0 or this.flip.x and -1 or 1)
				,v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0)
				-- effects
				psfx"3"
				freeze=0
				-- dash target speeds and accels
				this.dash_target_x=2*sign(this.spd.x)
				this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
				this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
				this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
			elseif this.djump<=0 and dash then
				-- failed dash smoke
				psfx"9"
			end
		end

		-- animation
		this.spr_off+=0.25
		this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or	-- wall slide or mid air
		btn(⬇️) and 6 or -- crouch
		btn(⬆️) and 7 or -- look up
		this.spd.x~=0 and h_input~=0 and 1+this.spr_off%4 or 1 -- walk or stand

		-- exit level off the top (except summit)
		if this.y<-4 and levels[lvl_id+1] then
			next_level()
		end

		-- was on the ground
		this.was_on_ground=on_ground
	end,

	draw=function(this)
		-- clamp in screen
		local clamped=mid(this.x,-1,lvl_pw-7)
		if this.x~=clamped then
			this.x=clamped
			this.spd.x=0
		end
		-- draw player hair and sprite
		set_hair_color(this.djump)
		draw_hair(this)
		draw_obj_sprite(this)
		
		-- draw magnet when x is held
		if magnet_unlocked and btn(❎) then
    local mx,my = this.x,this.y
    local spr_id = magnet_spr_right
    local flip_x,flip_y = false,false

  if btn(⬆️) then
   -- up: use up-facing sprite
   my -= 8
   spr_id = magnet_spr_up
   flip_y = false

  elseif btn(⬇️) then
   -- down: flip the up-sprite vertically
   my += 8
   spr_id = magnet_spr_up
   flip_y = true

  else
   -- horizontal
   if this.flip and this.flip.x then
   	-- left: flip right-sprite horizontally
    mx -= 8
    flip_x = true
   else
    -- right
   	mx += 8
    flip_x = false
   end
    spr_id = magnet_spr_right
   end

    spr(spr_id, mx, my, 1, 1, flip_x, flip_y)
			end

		pal()
	end
}

function create_hair(obj)
--	obj.hair={}
--	for i=1,5 do
--		add(obj.hair,vector(obj.x,obj.y))
--	end
end

function set_hair_color(djump)
	pal(8,djump==1 and 8 or djump==2 and 7+frames\3%2*4 or 12)
end

function draw_hair(obj)
	local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x,h.y,mid(4-i,1,2),8)
		last=h
	end
end

function kill_player(obj)
	sfx_timer=12
	sfx"0"
	deaths+=1
	destroy_object(obj)
	--dead_particles={}
	for dir=0,0.875,0.125 do
		add(dead_particles,{
			x=obj.x+4,
			y=obj.y+4,
			t=2,
			dx=sin(dir)*3,
			dy=cos(dir)*3
		})
	end
	delay_restart=15
end

player_spawn={
	init=function(this)
		sfx"4"
		this.spr=3
		this.target=this.y
		this.y=min(this.y+48,lvl_ph)
		cam_x,cam_y=mid(this.x+4,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
		this.spd.y=-4
		this.state=0
		this.delay=0
		create_hair(this)
		this.djump=max_djump
		
		this.layer=1
	end,
	update=function(this)
		-- jumping up
		if this.state==0 and this.y<this.target+16 then
			this.state=1
			this.delay=3
			-- falling
		elseif this.state==1 then
			this.spd.y+=0.5
			if this.spd.y>0 then
				if this.delay>0 then
					-- stall at peak
					this.spd.y=0
					this.delay-=1
				elseif this.y>this.target then
					-- clamp at target y
					this.y=this.target
					this.spd=vector(0,0)
					this.state=2
					this.delay=5
					this.init_smoke(0,4)
					sfx"5"
				end
			end
			-- landing and spawning player object
		elseif this.state==2 then
			this.delay-=1
			this.spr=6
			if this.delay<0 then
				destroy_object(this)
				init_object(player,this.x,this.y)
			end
		end
	end,
	draw= player.draw
}
-->8
-- [objects]

spring={
	init=function(this)
		this.delta=0
		this.dir=this.spr==18 and 0 or this.is_solid(-1,0) and 1 or -1
		this.show=true
		this.layer=-1
	end,
	update=function(this)
		this.delta=this.delta*0.75
		local hit=this.player_here()
		
		if this.show and hit and this.delta<=1 then
			if this.dir==0 then
				hit.move(0,this.y-hit.y-4,1)
				hit.spd.x*=0.2
				hit.spd.y=-3
			else
				hit.move(this.x+this.dir*4-hit.x,0,1)
				hit.spd=vector(this.dir*3,-1.5)
			end
			hit.dash_time=0
			hit.dash_effect_time=0
			hit.djump=max_djump
			this.delta=8
			psfx"8"
			this.init_smoke()
			
			break_fall_floor(this.check(fall_floor,-this.dir,this.dir==0 and 1 or 0))
		end
	end,
	draw=function(this)
		if this.show then
			local delta=min(flr(this.delta),4)
			if this.dir==0 then
				sspr(16,8,8,8,this.x,this.y+delta)
			else
				spr(19,this.dir==-1 and this.x+delta or this.x,this.y,1-delta/8,1,this.dir==1)
			end
		end
end
}

fall_floor={
	init=function(this)
		this.solid_obj=true
		this.state=0
	end,
	update=function(this)
		-- idling
		if this.state==0 then
			for i=0,2 do
				if this.check(player,i-1,-(i%2)) then
					break_fall_floor(this)
				end
			end
		-- shaking
		elseif this.state==1 then
			this.delay-=1
			if this.delay<=0 then
				this.state=2
				this.delay=60--how long it hides for
				this.collideable=false
				set_springs(this,false)
			end
			-- invisible, waiting to reset
		elseif this.state==2 then
			this.delay-=1
			if this.delay<=0 and not this.player_here() then
				psfx"7"
				this.state=0
				this.collideable=true
				this.init_smoke()
				set_springs(this,true)
			end
		end
	end,
	draw=function(this)
		spr(this.state==1 and 26-this.delay/5 or this.state==0 and 23,this.x,this.y) --add an if statement if you use sprite 0 (other stuff also breaks if you do this i think)
	end,
}

function break_fall_floor(obj)
	if obj and obj.state==0 then
		psfx"15"
		obj.state=1
		obj.delay=15--how long until it falls
		obj.init_smoke()
	end
end

function set_springs(obj,state)
	obj.hitbox=rectangle(-2,-2,12,8)
	local springs=obj.check_all(spring,0,0)
	foreach(springs,function(s) s.show=state end)
	obj.hitbox=rectangle(0,0,8,8)
end

balloon={
	init=function(this)
		this.offset=rnd()
		this.start=this.y
		this.timer=0
		this.hitbox=rectangle(-1,-1,10,10)
	end,
	update=function(this)
		if this.spr==22 then
			this.offset+=0.01
			this.y=this.start+sin(this.offset)*2
			local hit=this.player_here()
			if hit and hit.djump<max_djump then
				psfx"6"
				this.init_smoke()
				hit.djump=max_djump
				this.spr=0
				this.timer=60
			end
		elseif this.timer>0 then
			this.timer-=1
		else
			psfx"7"
			this.init_smoke()
			this.spr=22
		end
	end,
	draw=function(this)
		if this.spr==22 then
			for i=7,13 do
				pset(this.x+4+sin(this.offset*2+i/10),this.y+i,6)
			end
			draw_obj_sprite(this)
		end
	end
}

smoke={
	init=function(this)
		this.spd=vector(0.3+rnd"0.2",-0.1)
		this.x+=-1+rnd"2"
		this.y+=-1+rnd"2"
		this.flip=vector(rnd()<0.5,rnd()<0.5)
		this.layer=3
	end,
	update=function(this)
		this.spr+=0.2
		if this.spr>=32 then
			destroy_object(this)
		end
	end
}

fruit={
  check_fruit=true,
  init=function(this)
    this.y_=this.y
    this.off=0
    this.follow=false
    this.tx=this.x
    this.ty=this.y
    this.ground_timer = 0
  end,

  update=function(this)
    if not this.follow and this.player_here() then
      -- picked up: start following
      this.follow = true
      psfx(23)
      prev_fruit = true

    elseif this.follow then
      local p = get_player()
      if p then
        if p.type == player then
          -- check if player is on the ground
          local on_ground = p.is_solid and p.is_solid(0,1)

          if on_ground then
            this.ground_timer += 1
          else
            this.ground_timer = 0
          end

          -- ヌう✽ cash-in after 5 grounded frames
          if this.ground_timer >= 5 then
            psfx"13"
            init_object(lifeup,this.x,this.y)

            -- ユか⬆️み mark this berry as permanently collected
            if this.fruit_id then
              got_fruit[this.fruit_id] = true
            end

            -- no more follower respawn on level reload
            prev_fruit = false

            if time_ticking then
              fruit_count += 1
            end

            destroy_object(this)
            return
          end
        end

        -- existing follow behaviour (you can keep or trim this):
        if p.type == player_spawn then
          if p.state == 2 and p.delay == 0 then
            init_object(lifeup,this.x,this.y)
            destroy_object(this)
            psfx"13"
            fruit_count+=1
            -- this one was originally using lvl_id-1; you can remove this if not needed:
            -- got_fruit[lvl_id-1] = true
            prev_fruit = false
          end
          this.x += 0.2*(p.x - this.x)
          this.y_ += 0.2*(p.y - 12 - this.y_)
        else
          this.tx += 0.2*(p.x - this.tx)
          this.ty += 0.2*(p.y - this.ty)
          local vx,vy = this.x - this.tx, this.y_ - this.ty
          local mag = sqrt(vx^2+vy^2)
          local k = mag>12 and 0.2 or 0.1
          this.x += k*(this.tx + 12*vx/mag - this.x)
          this.y_ += k*(this.ty + 12*vy/mag - this.y_)
        end
      end
    end

    -- bobbing
    this.off += 0.025
    this.y = this.y_ + sin(this.off)*2.5
  end
}


function get_player()
  for o in all(objects) do
    if o.type==player_spawn or o.type==player then
      return o
    end
  end
end


_load_level = load_level
function load_level(id)
  _load_level(id)
  if prev_fruit then
    local p=get_player()
    init_object(fruit,p.x,p.y,26).follow=true
  end
  prev_fruit=false
end

_kill_player = kill_player
function kill_player(o)
 _kill_player(o)
 prev_fruit=false
end

fly_fruit={
	check_fruit=true,
	init=function(this)
		this.start=this.y
		this.step=0.5
		this.sfx_delay=8
	end,
	update=function(this)
		--fly away
		if has_dashed then
			if this.sfx_delay>0 then
				this.sfx_delay-=1
				if this.sfx_delay<=0 then
					sfx_timer=20
					sfx"14"
				end
			end
			this.spd.y=appr(this.spd.y,-3.5,0.25)
			if this.y<-16 then
				destroy_object(this)
			end
			-- wait
		else
			this.step+=0.05
			this.spd.y=sin(this.step)*0.5
		end
		-- collect
		check_fruit(this)
	end,
	draw=function(this)
		spr(26,this.x,this.y)
		for ox=-6,6,12 do
			spr((has_dashed or sin(this.step)>=0) and 45 or this.y>this.start and 47 or 46,this.x+ox,this.y-2,1,1,ox==-6)
		end
	end
}

function check_fruit(this)
	local hit=this.player_here()
	if hit then
		hit.djump=max_djump
		sfx_timer=20
		sfx"13"
		got_fruit[this.fruit_id]=true
		init_object(lifeup,this.x,this.y)
		destroy_object(this)
		if time_ticking then
			fruit_count+=1
		end
	end
end

lifeup={
	init=function(this)
		this.spd.y=-0.25
		this.duration=30
		this.flash=0
	end,
	update=function(this)
		this.duration-=1
		if this.duration<=0 then
			destroy_object(this)
		end
	end,
	draw=function(this)
		this.flash+=0.5
		?"yum!",this.x-4,this.y-4,7+this.flash%2
	end
}

fake_wall={
	check_fruit=true,
	init=function(this)
		this.solid_obj=true
		this.hitbox=rectangle(0,0,16,16)
	end,
	update=function(this)
		this.hitbox=rectangle(-1,-1,18,18)
		local hit=this.player_here()
		if hit and hit.dash_effect_time>0 then
			hit.spd=vector(sign(hit.spd.x)*-1.5,-1.5)
			hit.dash_time=-1
			for ox=0,8,8 do
				for oy=0,8,8 do
					this.init_smoke(ox,oy)
				end
			end
			init_fruit(this,4,4)
		end
		this.hitbox=rectangle(0,0,16,16)
	end,
	draw=function(this)
		sspr(0,32,8,16,this.x,this.y)
		sspr(0,32,8,16,this.x+8,this.y,8,16,true,true)
	end
}

function init_fruit(this,ox,oy)
	sfx_timer=20
	sfx"16"
	init_object(fruit,this.x+ox,this.y+oy,26).fruit_id=this.fruit_id
	destroy_object(this)
end

key={
	update=function(this)
		this.spr=flr(9.5+sin(frames/30))
		if frames==18 then --if spr==10 and previous spr~=10
			this.flip.x=not this.flip.x
		end
		if this.player_here() then
			sfx"23"
			sfx_timer=10
			destroy_object(this)
			has_key=true
		end
	end
}

chest={
	check_fruit=true,
	init=function(this)
		this.x-=4
		this.start=this.x
		this.timer=20
	end,
	update=function(this)
		if has_key then
			this.timer-=1
			this.x=this.start-1+rnd"3"
			if this.timer<=0 then
				init_fruit(this,0,-4)
			end
		end
	end
}

platform={
	init=function(this)
		this.x-=4
		this.hitbox.w=16
		this.dir=this.spr==11 and -1 or 1
		this.semisolid_obj=true
		
		this.layer=2
	end,
	update=function(this)
		this.spd.x=this.dir*0.65
		--screenwrap
		if this.x<-16 then
			this.x=lvl_pw
		elseif this.x>lvl_pw then
			this.x=-16
		end
	end,
	draw=function(this)
		spr(11,this.x,this.y-1,2,1)
	end
}

message={
	init=function(this)
		this.text="we're going to shut you guys#down if you don't remove#all the fucking spikes.##are you *trying* to kill#people?? --osha"
		this.hitbox.x+=4
		this.layer=4
	end,
	draw=function(this)
		if this.player_here() then
			for i,s in ipairs(split(this.text,"#")) do
				camera()
				rectfill(7,7*i,120,7*i+6,7)
				?s,64-#s*2,7*i+1,0
				camera(draw_x,draw_y)
			end
		end
	end
}

big_chest={
	init=function(this)
		this.state=max_djump>0 and 2 or 0
		this.hitbox.w=16
	end,
	update=function(this)
		if this.state==0 then
			local hit=this.check(player,0,8)
			if hit and hit.is_solid(0,1) then
			--	music(-1,500,7)
				sfx"16"
			--	pause_player=true
				hit.spd=vector(0,0)
				this.state=1
				this.init_smoke()
				this.init_smoke(8)
				this.timer=0
				this.particles={}
			end
		elseif this.state==1 then
			this.timer-=1
		--	flash_bg=true
			if this.timer<=45 and #this.particles<50 then
				add(this.particles,{
					x=1+rnd"14",
					y=0,
					h=32+rnd"32",
				spd=8+rnd"8"})
			end
			if this.timer<0 then
				this.state=2
				this.particles={}
				flash_bg,bg_col,cloud_col=false,0,0
				init_object(orb,this.x+4,this.y+4,102)
				pause_player=false
			end
		end
	end,
	draw=function(this)
		if this.state==0 then
			draw_obj_sprite(this)
			spr(96,this.x+8,this.y,1,1,true)
		elseif this.state==1 then
			foreach(this.particles,function(p)
				p.y+=p.spd
				line(this.x+p.x,this.y+8-p.y,this.x+p.x,min(this.y+8-p.y+p.h,this.y+8),7)
			end)
		end
		spr(112,this.x,this.y+8)
		spr(112,this.x+8,this.y+8,1,1,true)
	end
}

orb={
	init=function(this)
		this.spd.y=-4
	end,
	update=function(this)
		this.spd.y=appr(this.spd.y,0,0.5)
		local hit=this.player_here()
		if this.spd.y==0 and hit then
		--	music_timer=45
			sfx"51"
			freeze=10
			destroy_object(this)
			max_djump=1
			hit.djump=1
			magnet_unlocked=true
		end
	end,
	draw=function(this)
		draw_obj_sprite(this)
		for i=0,0.875,0.125 do
			circfill(this.x+4+cos(frames/30+i)*8,this.y+4+sin(frames/30+i)*8,1,7)
		end
	end
}

flag={
	init=function(this)
		this.x+=5
	end,
	update=function(this)
		if not this.show and this.player_here() then
			sfx"55"
			sfx_timer,this.show,time_ticking=30,true,false
		end
	end,
	draw=function(this)
		spr(118+frames/5%3,this.x,this.y)
		if this.show then
			camera()
			rectfill(32,2,96,31,0)
			spr(26,55,6)
			?"x"..fruit_count,64,9,7
			draw_time(49,16)
			?"deaths:"..deaths,48,24,7
			camera(draw_x,draw_y)
		end
	end
}

-- [object class]

function init_object(type,x,y,tile)
	--generate and check berry id
	local id=x..","..y..","..lvl_id
	if type.check_fruit and got_fruit[id] then
		return
	end

	local obj={
		type=type,
		collideable=true,
		--collides=false,
		spr=tile,
		flip=vector(),--false,false
		x=x,
		y=y,
		hitbox=rectangle(0,0,8,8),
		spd=vector(0,0),
		rem=vector(0,0),
		layer=0,
		
		fruit_id=id,
	}

	function obj.left() return obj.x+obj.hitbox.x end
	function obj.right() return obj.left()+obj.hitbox.w-1 end
	function obj.top() return obj.y+obj.hitbox.y end
	function obj.bottom() return obj.top()+obj.hitbox.h-1 end

	function obj.is_solid(ox,oy)
		for o in all(objects) do
			if o!=obj and (o.solid_obj or o.semisolid_obj and not obj.objcollide(o,ox,0) and oy>0) and obj.objcollide(o,ox,oy) then
				return true
			end
		end
		return oy>0 and not obj.is_flag(ox,0,3) and obj.is_flag(ox,oy,3) or -- jumpthrough or
		obj.is_flag(ox,oy,0) -- solid terrain
	end

	function obj.is_ice(ox,oy)
		return obj.is_flag(ox,oy,4)
	end

	function obj.is_flag(ox,oy,flag)
		for i=max(0,(obj.left()+ox)\8),min(lvl_w-1,(obj.right()+ox)/8) do
			for j=max(0,(obj.top()+oy)\8),min(lvl_h-1,(obj.bottom()+oy)/8) do
				if fget(tile_at(i,j),flag) then
					return true
				end
			end
		end
	end

	function obj.objcollide(other,ox,oy)
		return other.collideable and
		other.right()>=obj.left()+ox and
		other.bottom()>=obj.top()+oy and
		other.left()<=obj.right()+ox and
		other.top()<=obj.bottom()+oy
	end

	--returns first object of type colliding with obj
	function obj.check(type,ox,oy)
		for other in all(objects) do
			if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
				return other
			end
		end
	end
	
	--returns all objects of type colliding with obj
	function obj.check_all(type,ox,oy)
		local tbl={}
		for other in all(objects) do
			if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
				add(tbl,other)
			end
		end
		
		if #tbl>0 then return tbl end
	end

	function obj.player_here()
		return obj.check(player,0,0)
	end

	function obj.move(ox,oy,start)
		for axis in all{"x","y"} do
			obj.rem[axis]+=axis=="x" and ox or oy
			local amt=round(obj.rem[axis])
			obj.rem[axis]-=amt
			local upmoving=axis=="y" and amt<0
			local riding=not obj.player_here() and obj.check(player,0,upmoving and amt or -1)
			local movamt
			if obj.collides then
				local step=sign(amt)
				local d=axis=="x" and step or 0
				local p=obj[axis]
				for i=start,abs(amt) do
					if not obj.is_solid(d,step-d) then
						obj[axis]+=step
					else
						obj.spd[axis],obj.rem[axis]=0,0
						break
					end
				end
				movamt=obj[axis]-p --save how many px moved to use later for solids
			else
				movamt=amt
				if (obj.solid_obj or obj.semisolid_obj) and upmoving and riding then
					movamt+=obj.top()-riding.bottom()-1
					local hamt=round(riding.spd.y+riding.rem.y)
					hamt+=sign(hamt)
					if movamt<hamt then
						riding.spd.y=max(riding.spd.y,0)
					else
						movamt=0
					end
				end
				obj[axis]+=amt
			end
			if (obj.solid_obj or obj.semisolid_obj) and obj.collideable then
				obj.collideable=false
				local hit=obj.player_here()
				if hit and obj.solid_obj then
					hit.move(axis=="x" and (amt>0 and obj.right()+1-hit.left() or amt<0 and obj.left()-hit.right()-1) or 0,
									axis=="y" and (amt>0 and obj.bottom()+1-hit.top() or amt<0 and obj.top()-hit.bottom()-1) or 0,
									1)
					if obj.player_here() then
						kill_player(hit)
					end
				elseif riding then
					riding.move(axis=="x" and movamt or 0, axis=="y" and movamt or 0,1)
				end
				obj.collideable=true
			end
		end
	end

	function obj.init_smoke(ox,oy)
		init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),29)
	end

	add(objects,obj);

	(obj.type.init or stat)(obj)

	return obj
end

function destroy_object(obj)
	del(objects,obj)
end

function move_camera(obj)
	cam_spdx=cam_gain*(4+obj.x-cam_x)
	cam_spdy=cam_gain*(4+obj.y-cam_y)

	cam_x+=cam_spdx
	cam_y+=cam_spdy

	--clamp camera to level boundaries
	local clamped=mid(cam_x,64,lvl_pw-64)
	if cam_x~=clamped then
		cam_spdx=0
		cam_x=clamped
	end
	clamped=mid(cam_y,64,lvl_ph-64)
	if cam_y~=clamped then
		cam_spdy=0
		cam_y=clamped
	end
end

function draw_object(obj)
	(obj.type.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj)
	spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
end
-->8
-- [level loading]

function next_level()
	local next_lvl=lvl_id+1

	--check for music trigger
	if music_switches[next_lvl] then
		music(music_switches[next_lvl],500,7)
	end

	load_level(next_lvl)
end

function load_level(id)
	has_dashed,has_key= false

	--remove existing objects
	local diff_level=lvl_id~=id
    --remove existing objects
     for o in all(objects) do
      if not (o.type==fruit and diff_level and o.follow) then
       destroy_object(o)
      end
     end
	--reset camera speed
	cam_spdx,cam_spdy=0,0

	local diff_level=lvl_id~=id

	--set level index
	lvl_id=id

	--set level globals
	local tbl=split(levels[lvl_id])
	for i=1,4 do
		_ENV[split"lvl_x,lvl_y,lvl_w,lvl_h"[i]]=tbl[i]*16
	end
	lvl_title=tbl[5]
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8

	--level title setup
	ui_timer=5

	--reload map
	if diff_level then
		reload()
		--check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
		end
	end

	-- entities
	for tx=0,lvl_w-1 do
		for ty=0,lvl_h-1 do
			local tile=tile_at(tx,ty)
			if tiles[tile] then
				init_object(tiles[tile],tx*8,ty*8,tile)
			end
		end
	end
end

--replace mapdata with hex
function replace_mapdata(x,y,w,h,data)
	for i=1,#data,2 do
		mset(x+i\2%w,y+i\2\w,"0x"..sub(data,i,i+1))
	end
end
-->8
-- [metadata]

--@begin
--level table
--"x,y,w,h,title"
levels={
	"0,0,1,1,ground floor",
	"4,1,1,1,2nd story",
	"1,0,1,1,3rd story",
	"3,0,1,1,4th story",
	"4,0,1,1,5th story",
	"2,0,1,1,6th story",
 "7,1,1,1,7th story",
	"6,0,1,1,8th story",
	"5,0,1,1,9th story",
	"0,2,1,1,10th story",
	"7,0,1,1,11th story",
	"3,1,1,1,12th story",
	"4,2,1,1,bad luck",
	"0,1,2,1,14th story",
 "2,1,1,2,15th story",
	"6,1,1,1,16th story",
	"1,2,1,1,17th story",
	"5,2,1,1,18th story",
	"3,2,1,1,19th story",
 "5,1,1,1,20th story",
	"7,2,1,2,birds eye",
	
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
 [13]=30,
 [14]=20,
 [21]=30
}

--@end

--tiles stack
--assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
1,player_spawn
8,key
11,platform
12,platform
18,spring
19,spring
20,chest
22,balloon
23,fall_floor
26,fruit
45,fly_fruit
64,fake_wall
86,message
96,big_chest
118,flag
]],"\n"),function(t)
 local tile,obj=unpack(split(t))
 tiles[tile]=_ENV[obj]
end)


__gfx__
00000000000000000000000000000000000000000000000000000000009aaa9000aaaaa0000aaa000000a0000007707770077700494949494949494949494949
00000000009aaa90009aaa90009aaa90009aaa9009aaa9000000000009aaaaaa00a000a0000a0a000000a0000777777677777770222222222222222222222222
0000000009aaaaaa09aaaaaa09aaaaaa09aaaaaaaaaaaa90009aaa900f41441000a909a0000a0a000000a0007766666667767777000420000000000000024000
000000000ff444400ff444400ff444400ff4444004444ff009aaaaaa04444440009aaa900009a9000000a0007677766676666677004200000000000000002400
000000000f4144100f4144100f4144100f414410014414f00ff44440044444400000a0000000a0000000a0000000000000000000042000000000000000000240
0000000004444440044444400444444004444440044444400f44444000cccc000099a0000009a0000000a0000000000000000000420000000000000000000024
0000000000cccc0000cccc0000cccc0006cccc0000cccc600441441000cccc000009a0000000a0000000a0000000000000000000200000000000000000000002
000000000060060000600060060000600000060000006000066ccc600060060000aaa0000009a0000000a0000000000000000000000000000000000000000000
5555555500000000000000000000000000000000000000000088880049999994499999944999099400555d006665666500000000000000000000000070000000
5555555500000000000000000004000000000000008888d008888880911111199111411991140919055555d0676567650dd50dd5007700000770070007000007
550000550000000000000000000950500aaaaaa0088888d008788880911111199111911949400419055555d06770677008820cc1007770700777000000000000
55000555007000700499994000090505a998888a0882225008888880911111199494041900000044000dd0000700070008820cc1077777700770000000000000
55000555007000700050050000090505a988888a0cc000000888888091111119911409499400000000655d000700070008820cc1077777700000700000000000
55000055067706770005500000095050aaaaaaaa0cccccd00888888091111119911191199140049900066000000000000888ccc1077777700000077000000000
55555555567656760050050000040000a980088a01ccccd00088880091111119911411199140411900d55600000000000088cc10070777000007077007000070
55555555566656660005500000000000a988888a0011115000000000499999944999999444004994000dd0000000000000000000000000007000000000000000
244444441aa11aa11aa11aa11aa11aa11ad6d5dddddddddddd5d6da1d000000d5555555500000000000000005500000007777770000000000000000000000000
2999999411aa11aa11aa11aa11aa11aa11d6d5dddd6dd6dddd5d6daadd0000dd555555550aaa0aaa0aaa0a0a6670000077777777000777770000000000000000
29499494a1dddddddddddddddddddd1aa1dddd5ddd5dd5ddd5dddd1add0000dd555555550aa00a0a0aa00aa06777700077777777007766700000000000000000
29944994aaddd66d66d66d66d66ddd11aad6dd5dddddddddd5dd6d11dd0000dd555555550a000aaa0a0a0a0a6660000077773377076777000000000000000000
299449941adddddddddddddddddddda11ad6dd5dddddddddd5dd6da1d0d00d0d5555555500000000000000005500000077773377077660000777770000000000
2949949411d6d55555dddd55555d6daa11dddd5ddd6dd6ddd5ddddaad0d00d0d5555555500000000000000006670000073773337077770000777767007700000
29999994a1d6d5dddd5555dddd5d6d1aa1d6d5dddd5dd5dddd5d6d1ad00dd00d555555550a000aaa0aaa0aaa677770007333bb37070000000700007707777770
22222222aaddd5dddddddddddd5ddd11aad6d5dddddddddddd5d6d11d0d00d0d555555550a0000a00aa000a0666000000333bb30000000000000000000077777
d0d00d0d1addd5dddddddddddd5ddda1ddddddddddddddddddddddddd0d00d0d555555550aaa0aaa0a0000a00000066609999999000000000000000000000000
d00dd00d11d6d5dddd5555dddd5d6daa0ddd0000000000000000ddd0d00dd00d505555550000000000000000000777760999c9990000000000ee0ee000000000
d00dd00da1d6d55555dddd55555d6d1a0000dd0dd00dd00dd0dd0000d0d00d0d55550055000000000000000000000766099ccc990000000000eeeee000000030
d0d00d0daadddddddddddddddddddd11000000d00dd00dd00d000000d0d00d0d555500550a0a0aaa0aaa0aaa0000005509ccccc900000000000e8e00000000b0
d0d00d0d1addd66d66d66d66d66ddda1000000d00dd00dd00d000000dd0000dd555555550aaa0aa00aa00aa0000006660999c9990000b00000eeeee000000b30
d00dd00d11ddddddddddddddddddddaa0000dd0dd00dd00dd0dd0000dd0000dd550555550a0a0aaa0a0a0aaa000777760999c999000b000000ee3ee003000b00
d00dd00da11aa11aa11aa11aa11aa11a0ddd0000000000000000ddd0dd0000dd5555555500000000000000000000076609999999030b00300000b00000b0b300
d0d00d0daa11aa11aa11aa11aa11aa11ddddddddddddddddddddddddd000000d5555555500000000000000000000005500004000030330300000b00000303300
5555555500000000077777777777777777777770000000000000000000000000d666666d00000000000000000000000000000000000000000000000000000000
55555666000000007000077700007770000077770000000004444444444444405dddddd500000000000000000000000000000000000000000000000000000000
555016660000000070cc777cccc777ccccc7770700000000049999999999994055dddd5500000000000000000000000000000000000000000000000000000000
550101660000000070c777cccc777ccccc777c0700000000049999998999994055dddd5500000000000000000000000000000000000000000000000000000000
5510106600000000707770000777000007770007000000000499899bbb99994055dddd5500000000000000000000000000000000000000000000000000000000
510101060000000077770000777000007770000700000000049aaa9bbb99994055dddd5500000000000000000000000000000000000000000000000000000000
50101016000000007000000000000000000c000700000000049aaa9bbb9999405dddddd500000000000000000000000000000000000000000000000000000000
5ddddddd0000000070000000000000000000000700000000049aaa9999989940d666666d00000000000000000000000000000000000000000000000000000000
5dddddd60000000000000011110000000000000770000007049aaa9999ccc9400000000000000ccccccccccccccccccccc888888888888888888888888880000
5dddd0160000000000ddddd11ddddd000000000770cc00070499999999ccc94000000000000000ccccccccccccccccccccc88888888888888888888888800000
5dd10106000000000d666661166666d00000000770cc00070499999999ccc9400000000000000000000000000000000000000000000000000000000000000000
55101016000000000d666661166666d000000c0770000c0704999999999999400000000000000000000000000000000000000000000000000000000000000000
55010106000000000d666661166666d0000000077000000704444444444444405555555500000770007700777770007777700770000007777770077000770000
55501016000000000d666dd11dd666d00000000770c0000702000000000000205555555500000777077707777777077777770770000007777777077000770000
55555106000000001d666d5115d666d1000000077000000702000000000000205555555500000777777707700077077000770770000007700000077000770000
55555555000000001111111111111111000000077000c00722200000000002225555555500000888888808800088088000000cc000000cccc0000ccc0ccc0000
00000000000000001111111111111111110000110666666000000000500000000000000500000880808808888888088008880cc0000c0cc0000000cc0cc00000
00aaaaaa000000001d666d5115d666d1155555511cccccc6008888d0550000000000005500000880008808800088088880880ccccccc0cccccc000ccccc00000
0a999999000000000d666dd11dd666d01dddddd11cccccc6088888d0555000000000055500000880008808800088008888880ccccccc0ccccccc000ccc000000
a99aaaaa000000000d666661166666d0166666611cccccc608822250555500000000555500000000000000000000000000000000000000000000000000000000
a9aaaaaa000000000d666661166666d0166666611cccccc60cc00000555555555555555500000000000000000000000000000000000000000000000000000000
a9999999000000000d666661166666d0166666611cccccc60cccccd05555555555555555000000ccccccccccccccccccccccc888888888888888888888800000
a99999990000000000ddddd11ddddd001dddddd11cccccc601ccccd0555555555555555500000ccccccccccccccccccccccccc88888888888888888888880000
a9999999000000000000001111000000110000110111111000111150555555555555555500000000000000000000000000000000000000000000000000000000
aaaaaaaa000000001100001111111111111111110eeeeee0004bbb00004b000000400bbb00000000000000000000000000000000000000000000000000000000
a49494a1000000001dddddd11d666d5115d666d12888888e004bbbbb004bb000004bbbbb00000000000000000000000000000000000000000000000000000000
a494a4a100000000166666610d666d5005d666d02888888e04200bbb042bbbbb042bbb0000000000000000000000000000000000000000000000000000000000
a49444aa00000000166666610d666d5005d666d02888888e040000000400bbb00400000000000000000000000000000000000000000000000000000000000000
a49999aa00000000166666610d666d5005d666d02888888e04000000040000000400000000000000000000000000000000000000000000000000000000000000
a4944499000000001dddddd10d666d5005d666d02888888e42000000420000004200000000000000000000000000000000000000000000000000000000000000
a494a44400000000155555511d666d5115d666d12888888e40000000400000004000000000000000000000000000000000000000000000000000000000000000
a4949999000000001100001111111111111111110222222040000000400000004000000000000000000000000000000000000000000000000000000000000000
2121722727272727352527272727278457575757575757570000b3575757575784374363030000b3848484840400724757b20000005784845757575757575757
00000037007200007200000026350000b357b200000000b384b20000000000000000000000000000000000000000000000000000000000000000000000000057
d0f00312222222322636b1b1b100100057374757575757570000b357b2b1b3578426273503000000b1b1b18405000347b10000000057b1b1b1b1b1b1b1b1b157
0000003700030000030000000026463500b1000000000000b1000000000000000000000000000000000000000000000000000000000000000000000000000000
0000031384848433848400001125273557374757b2b1b1b100000057b200b357123204000300000000000084020003470000000000570000000000000000b357
0000002646030000030000000000002657b200000000000000000000000000a10000000000000000000000000000000000000000000000000000000000000000
2121032727272727845700008484848457374757b200000000000057b280b357426205000300000000000084020273470000110011570000111111111100b357
00000000007300000300000000000000b10000000000002100000000000000000000000000000000000000000000000000670000000000000000000000000000
d0f003464646464684570000b346464657374757b200001111111157b200b3571333024703000000000000840202024700b384005757b2b35757575757b2b357
00000000000000000300000000000000000000000000b384b2000000000011000000000000000000000000000000000053535357000000000000000000000000
00000312848484328484b21100b3848457575757b200b35757575757b200b3574702020273000000001111122222324700b38410b1b10000b1b1b1b1b100b357
2100000072000000730000000043536311000011110000b100000011000084000000000000000000000000000000000084000057000000000000000000000000
21210313232323330000b302b2005784b2b1b1b10000b357b2b1b1b10000b3570202020202000000b35757132323334700b35784b200a100000000000000b357
0200000003000000000000000000000084b2b38484b200000000b3840000b1000000000000000000000000000000000057000084000000000000000000000000
d0f073000000000000000084b2005784b20000000000b357b20000000000b357040002848400000000b1b143632504000000b1b1111111000011111111111157
0200a100030000000000000000000200001100b1b1000000000000b1000000000000000000000000000000000000000057000000000000000000000000000000
00000000000011000000000000008484b20000111111b357b20000111111b35705000284471111110000008484370500000000b3848484b2b357575757575757
d0e0e0e0730000000000002100000202b357b2000000002100000000000000000000000000000000000000000000000000000000000000000000000000000000
2100000000b357b20000000011000047b200b35757575757b200b357575757572636028447848484b200008484370400000000b3575784b200b1b1b1b1b1b157
0000000000000064740000435353536300b10000000011f084b20000000011000000000000000000000000000000000000000000000000000000000000000000
d0f07257111103111157535357b20047b200b357b1b1b1b10000b357040025352535028447b1b1b10000008484370500000000000000b111111111110000b357
000000000000006575000000000000000000001100b357b2b1000000000084b20000000000000000000000000000000000000000000000000000000000000000
00000357535353535357b20000000057b200b357000000000000b3570500848437040084470000000000008484370400000000000000b35757575757b2000084
000000000000122222320000000000000000b384b200b100000000110000b1000000000000000000000000000000000000000000000000000000000000000000
21217357b200000000000000001100b1b20000b1000000111111b3570400263637050084470000000000008472370500000000110000b35757575757b2000084
00021000000042123262000000000000000000b1000000000000b357b20000000000000000000000000000000000000000000000000000000000000000000000
d0e0e0e00000001100001100b302b200b20000000000b3575757575705002535268425463600000000000084033704000000b357b20000b1b1b1b1b10000b357
000202000012524262620000000000000000000011000000000000b1000000000000000000000000000000000000000000000000000000000000000000000000
0000a1001100b302b2b302b200030000b21041000000b3574646464646463647728437123200000010000084033705001100b357b20000000000111111111157
02020200004212526252320000000000001000b384b2000011000000000000000000000000000000000000000000000000000000000000000000000000000000
848484b302b200030000030000030000575757b20000b35757575757575757577384371333122222222232847326464657b2b3571111111111b3575784848457
d0e0e0f0125242526252620000000000b357b200b10000b357b20000210000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043535353
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084840000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000057570000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084840000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000057570000000000000000000000000000
__label__
00000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000
00000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000070000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000ccccccccccccccccccccc888888888888888888888888880000000000000000000000000000000000000000
000000000000000000000000000000000000000000ccccccccccccccccccccc88888888888888888888888800000000000000000000000000000000000000000
00000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000770007700777770007777700770000007777770077000770000000000000000000000000000000000000000
00000000000000000000000000000000000000000777077707777777077777770770000007777777077000770000000000000000000000000000000000000000
00000000000000000000000000000000000000000777777707700077077000770770000007700000077000770000000000000000000000000000000000000000
70000000000000000000000000000000000000000888888808800088088000000cc000000cccc0000ccc0ccc0000000000000000000000000000000000000000
70000000000000000000000000000000000000000880808808888888088008880cc0000c0cc7700000cc0cc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000880008808800088088880880ccccccc0cc77cc000ccccc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000880008808800088008888880ccccccc0ccccccc000ccc000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000ccccccccccccccccccccccc888888888888888888888800000000000000000000000000000000000000000
00000000000000000000000000000000000000000ccccccccccccccccccccccccc88888888888888888888880000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000000000
00000000000000000000000000000000000000005550555055005500505000005550505005505550055005505500000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050505050505000000500505050505050500050505050000000000000000000000000000000000000
00007000000000000000000000000000000000005050555050505050555000000500555050505500555050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050505050005000000500505050505050005050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505055505550555000000500505055005050550055005050000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000070000000000000000005500055055505000000055505550555055505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000005550055055000000555050500000555055505550500000000000000000005050555005505550555055500000000000000000000000
00000000000000000000005550505050500000505050500000555050005050500000000000050000005050050050005050500050500000000000000000000000
00000000000000000000005050505050500000550055500000505055005500500000000000555000005050050055505550550055000000000000000000006000
00000000000000000000005050505050500000505000500000505050005050500000000000050000005550050000505000500050500000000000000000000000
00000000000000000000005050550055500000555055500000505055505050555055500000000000005550555055005000555050500000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000008080802020000000000000000000200000000030303030303030302020202020000000303030303030303020202020202020200000303030302020300020202020202000003030303020204020202020202020000030303070004040202020202020200000303030700000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
7575757575000000007575000075757527400052727272537500000000003125487575750012120000484848484848737400007400000000002020212222222375000000000000000000000000004848313232323232323375000000000000750000000000000075353535353535357575757500000000000000000000003b75
750000000000000000000000000000753050006264646463750000000000003148750d0e0e0e0e0f20482b001a00487374000074000000000020202425252526750000000000000000000000000075200000000000002123750000000000007500000000000000757575757575757575000000000000000075000000001a3b75
75000000000000000000000000000075304848484848484875000000000000204875000000000020202b000000003b73740000740000000020212223323232337500000000000000111111000000752000000001000031337500000000000048000000111100001b1b1b1b1b1b1b1b7500007575757575757575757575757575
757575000000000000000000120000753000000000000000000000000000002048750000002122231b00001111003b737400001b0000202020242533000000003000000000000000757548000000752034353536000075731b0000000000004800003b75752b00000000000000003b75000075751b1b1b1b1b1b1b1b1b1b1b1b
750000000000000075757575757575753000000000000000000000000075202048000000002430260000007575003b731b000000343535353631335253000000201111110014001275752500000075487500000000007573000000000000004800003b75750000111111111100003b7500001b1b000000000000000000000000
750000000000000075484848484840003000000000000000000000000075202073000000002430260000001b1b003b73000000001b1b1b484848646373000020343535353536525340004800000075487500001111117573000000000000004800003b7575121275757575752b003b7500000000000000000000000000000000
000000000000000075757572725350007500000000000000527248212222222373000000002430260011000000003b73121200000000001b1b1b202073002020757575484848487450004800000075277500001b1b1b7573000000000000004800003b7575757575212223752b003b7500001111000000111100000011110000
0000000000000000000075757562645375000000000000007321233132323233730000003b2430260020000000000020757512120000000000001b1b730020201b1b1b1b25001b1b1b1b1b00000075307500000000007573000000000000007500003b7535353575313233752b003b75003b40002b003b40002b003b40002b00
0000000000000000000000007575757430000000000000007524252300000000730000003b313233002000000000002021222375121212000000000075757575000000004800000000000000000075307511111100007548110000000000007500003b7575757575757575752b003b75003b50002b003b50002b003b50002b00
000000000000000000000000000075753000000000000000752425260000200062750000001b1b1b002011000011114831323322222375121212000000000000000000001b0000001111110000111137751b1b1b00007548480000000000001b0000001b1b1b1b1b1b1b1b1b00003b75003b73742b003b73742b003b73742b00
000000000000000000000000000000757500000000000000303132330020202052750000000000000048482b3b2525481b1b313232334848487512120000000000003b7575752b3b4848482b002122237500000000001b1b1b0000000000000000000000000000000000000000003b75003b73742b003b73742b003b73742b00
0001000000000000000000000000007575000000000000003000343535353536731b11111111000011111100001b1b4801001b1b1b1b1b1b1b1b75484875000000003b48212300001b371b00002425267500000000000000000000000000000000001111111100000011111100003b75003b73742b003b73742b003b73742b00
00757575752b00000000000060000000300000000000000075000000000020007300484848482b3b2122230000000048484848482b11110000001b1b4848000000003b48242600000008000000242526750000000000000000000000000000000100757575752b003b7575752b003b75003b73742b003b73742b003b73742b00
0e0f752b0000000000000000700000003000000000000000750000343535353673001b1b1b1b003b31323300000000757272725321222311110000001b1b000000003b25242648254827111111312526750000000000000011000000000000007575757575752b003b7575752b003b75003b73742b003b73742b003b73742b01
001a00000000000000003b48484821233001000000000000300020202000000062530000000000011b1b1b00000000754000487424252620481111000000000000013b483133111111300e0e0e2031337500000000000000752b0000000000002020751a00000000001b1b1b0000001b11117374111111737411111121222223
7575757500000000000000003b483133377500000000000037757575757575754874000000484848481111111111114850004863242526343535361152727253343535353535353648484848482020207575757575757575752b0000000034350d0f750000000000000000001111111175756362757575636275757531323233
00121200482b00000000005248484848487272533b252b0000003435353535350000202048343535353536000000000048757521222222232123752b00007575400040004848484848000000757575750000007575757575757575750000000000000000000000003b752b000000000000000000000000000000000000757575
0d0e0e0f752b00000000001b0000000000000074001b000000000000003435352020202048000000001b1b0000000000487575242525252631332b0000000000500050004848484848000000000000000000750000000000000000000f000000003b752b00000000526300000000000000000000000000000000000000000000
00000000752b0000000000000000000000143b7500000000000000000000000048646464480000000000000000000020480000313232252622232b00120000004872727272727248481212000000000000007500000000000000000000750000000000000000003b752b00000000000034353535353535353535353535353600
000000000000000000000000003b75353575757500000000000000000000000027646464480000000011110000122020480000750000313325262b00480000004864646464646448480d0e0e0e0e0e0f00656565656565650000000000750000752b000000000000000000000000000000277575757575757530757575750000
0800000000000000000000111111757575752b0000000000000000000000000037004000480000003b757548757575754800001b0000752425262b000000000048000000000000757400000000000000650000000000000065000000007575007300003b752b000000000000000000001a3000001b1b00001b3000001b1b0000
12121200000075752b00001b1b1b1b1b1b0000000000000000000000482122234848500048000000001b1b4875757575480000110000753132332b000000001148010000000000757400000000000000650000000000000065000000007500757300000074000000003b752b0000000000370000000000000030000000000000
2020200011525375753435350000003535353536000000001100000048313233527272725311111100000021234848484800007500001b0000752b0000000075212222230000007474000000000000006500000000000000650000000075007573000000743b752b000074000000000000000000000000000030000000000000
0000003b4863625375757253111111112000301b0000003b480000003b75400073212223744848482b000031335272724800007500001100007500003b757575242525260000001b1b0000000000212300656565656565650000000000750075730011006264630000526300750d0e0e00000000000000000030000000000000
000000001b0052630075752122222320200030000011003b480000003b75500073242526741b1b1b00000048486253484800007512127500007500003b75484824252526000000000000000000003133000075000000000000000000007500756264480000000000117400007400000000000100000000000030000000000000
00000000003b482b0000002425252625252530003b252b001b00000048736253732425267400000000000048400074484800007575757500001b000000754000212332330000001111000000000020000000750000000000000000000075007500001b000000003b486300007400000000007500000000003b30000000000000
0000000000001b00000000242525260e0e0e3700001b000000000000486253747331323374000000000000485000744848000000270075000011000000755000242600000000117474000000000020000000750000000075750000000075007500000000000000000000003b7500001200000000000000003b37000000000000
000000000000000000000031323233000000000000000000000000003b754000626464646300000000000052727263481b00000037007500007500003b75484824750000000048637400000000002020000075000000750000750000007575000000000000000000000000000000000f00000000000000000000000000000000
00000000000000000000003b757575000000000000000000000000003b7550004000484848111100000000730d0f21230000000020207512127500003b75757524750000000048646300000000002123000075000000750000750000007500000001000000000000000000000000000000000000000000000000000000000000
000001000000000000000000003b750000000000000020201111111111212223500048484875752b0000007340002426000000002020487575482b00001b1b752426000000001b1b1b00000000007526000075000000750000750000007500000075000000000000000000007500000000000000000000000000000000000000
0d0e200000000000000000000e0e0e000000000000007521222222222225252672532000481b1b000000007350003133000100202020484848482b0000001a7524260000000000000000000000007526000075000100750000750000007500000074000000000000000000007400000000000000000000000000000000000000
21222300000000000000003b2020202000000000000075313232323232323233487320202700000011111134353535367575343535353535360000000000007531330000000000000000000000003133000000757575000000007575750000000074000000000000000000007400000000000000000000000000000000000000
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
000100000b7600e7601176013770147601474011740117000e7000a70008700077000770008700097000b7000b700097000770006700057000670006700087000b7000d700107001370016700187001a7001a700
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

