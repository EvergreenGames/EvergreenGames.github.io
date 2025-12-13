pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- [initialization]
-- maddy on the moon by wisper

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

-- [entry point]

function _init()
	frames,start_game_flash=0,0
	music(40,0,7)
	lvl_id=0
	stars_init(60)
end

function begin_game()
	max_djump=1
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,0
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

-- simple screen-space twinkling stars

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
		local col = 6
		if b > 0.4 then
			col = 7       -- bright
		elseif b < -0.4 then
			col = 5       -- dim
		end

		if s.burst > 0 then
			col = 7
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
		seconds_f+=1
		minutes+=seconds_f\1800
		seconds_f%=1800
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
		?"mod by wisper",40,112,5

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
	rectfill(x,y,x+44,y+6,0)
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30)..":"..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,7
end

function draw_ui()
	rectfill(24,58,104,70,0)
	local title=lvl_title or lvl_id.."00 m"
	?title,64-#title*2,62,7
	draw_time(4,4)
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
		
		this.layer=1
	end,
	update=function(this)
		if pause_player then
			return
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

		-- jump and dash input
		local jump,dash=btn(🅾️) and not this.p_jump,btn(❎) and not this.p_dash
		this.p_jump,this.p_dash=btn(🅾️),btn(❎)

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
			this.init_smoke()
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
			local maxfall=1.2

			-- wall slide
			if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) then
				maxfall=0.3
				-- wall slide smoke
				if rnd"10"<2 then
					this.init_smoke(h_input*6)
				end
			end

			-- apply gravity
			if not on_ground then
				this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.15 and 0.12 or 0.06)
			end

			-- jump
			if this.jbuffer>0 then
				if this.grace>0 then
					-- normal jump
					psfx"1"
					this.jbuffer=0
					this.grace=0
					this.spd.y=-2.0
					this.init_smoke(0,4)
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
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
			local d_full=5
			local d_half=3.5355339059 -- 5 * sqrt(2)

			if this.djump>0 and dash then
				this.init_smoke()
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
				,v_input~=0 and v_input*(h_input~=0 and d_half or d_full*1.2) or 0)
				-- effects
				psfx"3"
				freeze=2
				-- dash target speeds and accels
				this.dash_target_x=2*sign(this.spd.x)
				this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
				this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
				this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
			elseif this.djump<=0 and dash then
				-- failed dash smoke
				psfx"9"
				this.init_smoke()
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
		pal()
	end
}

function create_hair(obj)
	obj.hair={}
	for i=1,5 do
		add(obj.hair,vector(obj.x,obj.y))
	end
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
			this.spd.y+=0.25
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
				hit.spd.y=-2.5
			else
				hit.move(this.x+this.dir*4-hit.x,0,1)
				hit.spd=vector(this.dir*3,-1.2)
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
		this.start=this.y
		this.off=0
	end,
	update=function(this)
		check_fruit(this)
		this.off+=0.025
		this.y=this.start+sin(this.off)*2.5
	end
}

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
		?"1000",this.x-4,this.y-4,7+this.flash%2
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
		this.text="coming soon..." 
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
		this.state=max_djump>1 and 2 or 0
		this.hitbox.w=16
	end,
	update=function(this)
		if this.state==0 then
			local hit=this.check(player,0,8)
			if hit and hit.is_solid(0,1) then
				music(-1,500,7)
				sfx"37"
				pause_player=true
				hit.spd=vector(0,0)
				this.state=1
				this.init_smoke()
				this.init_smoke(8)
				this.timer=60
				this.particles={}
			end
		elseif this.state==1 then
			this.timer-=1
			flash_bg=true
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
				flash_bg,bg_col,cloud_col=false,2,14
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
			music_timer=45
			sfx"51"
			freeze=10
			destroy_object(this)
			max_djump=2
			hit.djump=2
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
			?"x"..two_digit_str(fruit_count),64,9,7
			draw_time(43,16)
			?"deaths:"..two_digit_str(deaths),48,24,7
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
	foreach(objects,destroy_object)

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
  "0,0,1,1,light ascent",
  "1,0,1,1,long drift",
  "2,0,1,1,first springs",
  "3,0,1,2,bounce tower",
  "4,0,1,1,side spring highway",
  "5,0,1,1,spring gauntlet",
  "6,0,1,1,momentum",
  "0,1,2,1,the arc lab",
  "7,0,1,1,crossfire springs",
  "4,1,2,2,large towers",
  "2,1,1,1,circular motions",
  "6,1,1,1,low-g timing",
  "7,1,1,1,zipline",
  "3,2,1,1,sub zero",
  "0,2,1,1,orbital platforms",
  "6,2,1,2,constellation trial",
  "7,2,1,2,moon gauntlet",
  "1,2,2,2,moon summit",
  "3,3,3,1,???",
  "0,0,7,3,thanks for playing"
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
  "32324848262b002a6700002a6758682422233132262b0000103900000028343248482223372b00002a3839006738212232483232362b000000002a682821482523374000202b000000000038292448324823000000000000005868290024262148330000000000003a38000000242624333839000000003a2810390e0f243324002a383900000000682828583930214800002a28390000002867002a3837242500002a3839001111382839002a2148250000002a2868212328002a390024252500000000212248332900002827313248000100002448262123000034332123312222222331323324482223342248482248252548232122482525482324252548",
  "23343536244825332448260000000000323637343232333448254823390000002a28390000000000314848333828383900002a2839000000383133212300002a28283900286829002a3821483300000000002a396828382828293133200000002301002a28102838286700000000000048231111111100002a2810383900160048330d0e0e0e003a38292a281039580033270000003a38290000002a67683867222600003a29000000171700002a100048263a38290000000000000000002a67322629001a000011111111000000002a233711000011113536212311000027214823201111212223214848231127372425482320214848262448254822262148",
  "2024262a3900001029000000000000002248262b2a38392800000000000000003248262b00002a28000000000000003a2731332b0000002a3900585868673a383123202b00000000382828382828293a23371b1111000000683800113422232a260d0e0e0e00003a68293b342331332b262b00000000002a2800001b31361b00262b00000000003a106700003a2900002611000058685868283900002a390000332000682900002a39000000002a3900222368291200586810683900002828382548222236203a38002a38393a290000482548332122223634353536290100002548332148483321222236212223202148262148252621484826214825482248",
  "4826000000003800000000000000000048330000586828580000000000000000261b0000003a29000000000000000000330000586828000000000000000000002300003a28380000000000000000003a2638283810286700000000000058583826000028292a383900001111003a290048233a290000002a28382123382900003126380000000000000024260000000023312223000000000013313300000000482331323639000000002122230000003148232123385868676831323300000023312631332a39003a282136212300004823331b1b002868290037214832360048331b0000001029003b2125332123003327000000002a39003b313334483300342613000000003800001b4000371b002337000000003a2800000000001b000048230000006828103900000000000000482600003a292a2828390000000000003226113a290000682900000000000000233136293a6839286768390000003a284823202829002a38002a1067586868384833272a6700002800002a2838282900333433002a3900286700003a2900000034231b00002a281028382829000000002730000000002a2800000000586858683037110000586838395868673a28382831362000003a292a2828292a2839002a232122233a2900002a380000002a390026313233276758583a28390001002a392523212226212321222222222300002a",
  "2548330011003148482548330000000032331b3b202b1b313232331b0000003a1b1b00001b00001b1b1b1b0000003a3811000000000000000000003a28382900231100001a000000000000381029000032232b000000212300003a292136000023372b003b343233000028123721232b48232b003b343600003a29203432332b25262b003b20386768293b273435362b48330000003a290028003b3021361b00331713003a28676829003a37371b000022235868290068105858381b1b0000004848230001002a2839002a3839000000254833212320273436273a292a2839004833214848233123213321222222230033214825254823373721484825254822",
  "483339000000314826372b3b3132332b331b2a3839001b3133202b001b1b1b001b0000002a39001b1b1b003a3900001100111100002a3900003a3829290011213b34231100002a2838102900001121333b273123111200002a380000133433213b2423312223000000280000002122483b31482324333900002a390000244825001b3133371b3800000028003a31324800001b1b1b001039000038282934233100000000003a292a393a2810001b313500000000682868283829002a39001b1b2839003a281029682900000038000000002a382901003a280000120028001a000021222222233829000017002a39000021484848254823000000000000383900",
  "26203132323300003a29313232330000482327400028393a292021222327202b3233305868283810393b313233372b00232148232700002a38391b1b1b1b00002631323331231200282900000000000033203422232423002a390000001317002222232426313311002a39000000000025483331332122232b002a3839003a2832332122232448332b00000028282900222324483331331b00003a3828106768482631331b1b1b00003a29002a38290032331b1b0000003a38290012586758686829000000003a10675858212311002a29000001682829000011214848232b0034222223276768393b34323232332b002324252630292a29001b1b1b1b1b0000",
  "000000280000006829000000000030314826000000000000313232332426302400003a2900000028000000000034252331330000000000001b1b1b34323330240020380000000028000000000027314823390000000000000000001b1b3433245868280020003a290000001400312331332a39000000000008000000001b343238281039003a290000002123342331362b003839000000003a28382839001b21002a282810286758586831482331362b00002a28003a28282900002a3828283100200028292a39000000683132362b000000002838282900000000000000001b00003a2900202a390000281b1b1b000000000028000000000000001317000000003a29000000002a67683867586839000000002a39000000000000000000000038290000000000002a671039002a29001600000028000000000000000000000000000000000000003a28382839000000000000003800000000000000000000000000001200000058682900002a2828390000003a290000000000000000000000000021222222362029000000003810282839002800000000000000000000000000212548323321232758585868290000003828280000000000000000000000002248323321224826302a39002858585868281038390000212222360001000000252621224825252630002a5829000000280000002a3927244826212222230000",
  "000000314848253321262425482631480000001b313233343233314832323631000000001b1b1b2a67582024212222222300000000003a38290000373132323248233a28381029000000004000212222482522360038000013170000003132482548332b3a290000111111112122233125262b0038001111212223214825483548332b0028112123244826314848331b332b0000102148263132323631331b00232b00002a3132331b1b1b1b1b1b0000262b0000001b1b1b0000000000003a3826000000000000000000003a381029002612000000000000003a38290000000048232b00000000003a2900000001212248262b000000003a3868390021222525",
  "00000000000000000000000031323232323300000000000000313232323232320000000000000000000000003422362123202a390000003a29342222363423200000000000000000000000001b302148331b003800000038001b3133212331230000000000000000000000003b3031261b00142800003a2900001b21484823310000110000000000000000003b3136370034362a393a38000000003148483327003b203900000000000000003b21232000000000283829000e0e0f203133273700001b2a39000000000000003b244823000000001028000000003b21233433210000586829000000110000003b313233110000202838000000003b2426202148005868385800003b202b0000001b3435361100002a10390000003b313327314858683828390000001b000000003b212320270000000028675800001b273123312829002a1039000000000000003b244823301300586828390000003b242331232900113a2838670000000000003b313233370000000028106700003b24332731003b202867386758000000000011272021230000003a28283900003b3721482300001b003a2900000000000000214823242600000028676838390011273148330000003a100800001100000011242526313338393a28585868293b2148233720003a38282839003b202b003b343232323536002a1067586829003b2448332122382900002a2839001b00003b20212320212300002858681039003b313327314829000011001029000000003b2125332125260000280000002800001b3435233100003b20683867000000003b31333425483300002a39000028390013343637270000001b2a280000000000001b212331331b0000002a6758682900003422223300000000002867580000000011244823202b000000003867290000002731332000000058681029000000003b21482548232b000058582810675800002436212300585868382900000000003b31323232332b0000003a29002800001137214833585868290000003b202b003b212222231b00000000280000283900272731332110382900000000001b00003b314848332b0000003a29000028103830242334482900000000000000000000001b31331b0000003a2800003a2900003024332731000000000000000000000000001b1b0000003a2810000028000000303734482300000000000000000000000000000000003a29002a2838290000123721233148000000000001000000000000000000003a29000000002a39000021363148233100000000212321222300000000000000380000000000002a39003721233133210000212248332425482300000021222334222300000000002a39214833273448222248252621252525260000214825482324482300000000002a242621482324",
  "3324330000000000000000313324483322331b00000000000000001b34323321261b000000000000000000001b1b2148330000000000000000000000003b31321b000000000000000000000000001b343900001121230012000011110000001b2a28392148330d0e0e0f2123282839000068283133390000003a3132232b2a3968102900002a286768383423332b0038290000000000002a29001b371b003a280000000000002122232b001b003a292a000000003b343232332b00000038000000080000001b1b1b1b0000003a2900000000000000000000000000002801140036212311000000000000000038212300202448232b0000000000003a34323300",
  "4832332448332448253300000000000026403a243321482526390000000000002600383734323232332a10383900003a263a291b1b0000001b0000002a102838333800000000000000000000000000002310000000000000000012000000132026290000000012111111171111003a21261112111111172734222222360038242620172734362125363132330000383125362125233432331b1b1b000000280033343232331b1b000000000000002a39392a292a39000000000000120000002a38686768290000120000001700000000290129120000001700001111111111112222222311111111111134222222222248482548232122222222232448254848",
  "4826313232335858585868290000000048332a391b1b003a283829000000000026390028102828382900000000000000332a682829122a290000000012000000232b10391317130000001121222311002600002a39000000003b34324848232b26130000283a390000001b1b3132332b260000002a102828390000001b1b1b00330000003a2900002a383900000000001b00003a29000000002a383900000000003a3829000000131713002a283828382829000000000000000000000012002a0000000000000000000000001317133b111111111111111111111100000000002223212334352222362123000100000048262425222324262125482222230000",
  "3233552829001127244833244833212523425438003b2126313334323321483226526438003b2433361b1b1b1b31332133551b28003b37201b000000001b1b2423556828003b2122232b0000000000312655002a393b2432331100000000400026550000283b372021232b000027000026551300383b2122482600000024233426550000283b2448483300002148332133550000283b313233270034323321482355586810001b1b3433001b1b1b31322655002a280000001b1b000000001b1b265511002a39000000000000000100003352440000102838283900427373737323625411002a67582a2a4264212222224823524400003867392a552148254848",
  "2525330000000000000000110031252532333800000000000000002000103132003a2900000e0f2000000000002a390010290000000000000000007500002a382900752b00000000202b00000000752a00000000110000000000202b0000000000000075343600000000007500202b0000110020000000002000001b400000003b200000000000001b2000000000752b00000000000034362b000000007500000000000000000000000000752b0000000000727400000000000000000020000000000000202b750000000000000000000011000000001b72740000000000010000200011000000000000000000424343000000452b0000000000000042535353",
  "0000000000000000000000000000000000002123000000000000000000000000000024483600000000000021222300000021482621360d0e0e0e0e313233272b00313233371b00000000001b1b343300001b1b1b1b00000000000000001b1b00000000000000000000000000003a28670000000000000000000000003a2810382867000000000000000034222223002a1028000000000000342223314848362b28286700003b34222331482331331b00002a383900003b31323631331b1b000000002a380000001b1b1b1b1b000000000000002800000000000000000000000000000028390000000000001200000000001121223611000000001317130000003b21483321232b0000000000000000003b31332148332b000000000000000000001b2731331b00000000000000000000003b24231b0000000000110000000000003b313313000000003b202b0011000039001b1b0000000011001b0011272b00280000000000003b202b001121262b0010000000000000001b003b3432330000283900000000000000003b21234000002a3800000000110000003b312600000000280000003b202b0000001b31362b000038390000001b00000000001b1b00003a282800000000000000000000000000222329010000000012000000000000004825362123000000170000000000000048262148482300000000000000000000",
  "0000002a102829000038000031333148000000002a28003a382900001b21233100000000002838290000000000244823000000003a2900000000000000314848000000003800000000000000002731480000003a290000000000000000242331003a38290000000000000000003133211029000000000000000000001121224829000000000000000000000021483232000000000000000000000000313321220000000000000011000000001b1b314800000000000000200000000000001b31000000000000001b000000000000001b000011000000000000000000000000000000200000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000001127000000000000001111000000000021260000000000003b34362b0000001331330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000011000000271100000000000000000000270000002423110000000000000000003000000024332700000000000000001137000000372126000000010000001121230000002125260d0e0e0e0e0e0f2148260000",
  "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000000000000000000000000000000000000343523000000000000000000000000000000000000002034222300000000000021233720000000000000000000000000000000000000212331260000000000003148232000000000000000000000000000000000000031482337000000000000003133000000000000000000212376000000000000000031330000000000000000000000000000000000002125332123000000000000000000000000000000000000000000000000000000313334322600000000000000000000000000000000000000000000000000000034222223370000000000000000000000000000000000000000000000000000212331483321230000000000000000000000000000000000000000000000000031482337272433000000000000000000000000000000000000000000000000000024333426372123000000000000000000000000000000000000000000000000003721233727313300000000000000002123000000000000000000000000000000003126343236000000000000000034482600000000000000000000000000000000003135360000000000000000000031330000000000002122360000000000000000000000000000000000000000000000000000000000313321230000000000000000000000000000000000000000000000000000000000003133000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002123000000000000212236270000000000000000000000000000000000000027313321360d0e0e0f313321482300000000000000000000000000000000000031353533000000000000343232330000000021230000000000000000000000000000000000000000000000000000000000214826000000002300000000000000000000000000000000000000000000343631483300000000483600010000000000000000000000000000000000000000212333000000000033212222230000000000000000000000000000000000000031330000000000002148254848230000000000000000000000000000000000000000000000000000",
  "0000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100003b202b00000000000000000000000000000000000000000000000000000000000000000000000000000000003b202b00001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000111b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b202b000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b00003b202b000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000001b001100000000000000000000000000000000000000000000000000000000000000000000000000003b202b11000000003b200000000000000000000000000000000000000000000000000000000000000000000000000000001b3b202b110000111b00000000000000000000000000000000000000110000000000000000000000000000000000000000001b3b202b3b2000000000000000000000000000000000000000002700000000000000000000000000000000000000000000001b00001b00000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000056000000000000000000000000003000000000000000000000000000000000000000000011000000000000212334222236212300000000000001000000003000000000000000000000000000000000000011003b202b1100000000312523313321253300000000002122222300003000000000000000000000000000000000003b202b001b3b200000000000313236343233000000000000242525260000300000000000000000000000000000000000001b000000001b00000000000000000000000000000000"
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
	[18]=30
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

--[[

short on tokens?
everything below this comment
is just for grabbing data
rather than loading it
and can be safely removed!

--]]

--copy mapdata string to clipboard
function get_mapdata(x,y,w,h)
	local reserve=""
	for i=0,w*h-1 do
		reserve..=num2hex(mget(x+i%w,y+i\w))
	end
	printh(reserve,"@clip")
end

--convert mapdata to memory data
function num2hex(v)
	return sub(tostr(v,true),5,6)
end
__gfx__
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700494949494949494949494949
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000777777677777770222222222222222222222222
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a0007766666667767777000420000000000000024000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0007677766676666677004200000000000000002400
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000000000000000000042000000000000000000240
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000000000000000000420000000000000000000024
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a0000000000000000000200000000000000000000002
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0000000000000000000000000000000000000000000
555555550000000000000000000000000000000000000000008888005666666556666665566606650c0cc0c06665666500000000000000000000000070000000
55555555000000000000000000040000000000000000000008888880666dd666666d76666dd706d60cccccc06765676500000000007700000770070007000007
550000550000000000000000000950500aaaaaa000000000087888806677dd6666dd6d66767007d6003333006770677010111101007770700777000000000000
55000055007000700499994000090505a998888a00000000088888806d77d7d6676707d60000007703abbb300700070011171711077777700770000000000000
55000055007000700050050000090505a988888a00000000088888806dddddd66dd70676670000000bbbbab00700070011119911077777700000700000000000
55000055067706770005500000095050aaaaaaaa000000000888888066d7dd6666dd6d666d70076603babb300000000001177710077777700000077000000000
55555555567656760050050000040000a980088a0000000000888800666dd6666667d6666d707dd6003bb3000000000001197790070777000007077007000070
55555555566656660005500000000000a988888a0000000000000000566666655666666557007665000330000000000001196690000000007000000000000000
5dddddd55dddddddddddddddddddddd5dd66666666666666666666dd5dddddd55555555555555555555555555500000007777770000000000000000000000000
ddddddddddddddddddddddddddddddddddd666666666666666666ddddddddddd5555555555555550055555556670000077777777000777770000000000000000
ddd6dddddddd66666dddddd66666ddddddd666666666666666666ddddddddddd5555555555555500005555556777700077777777007766700000000000000000
dd6666ddddd66666666dd66666666ddddddd6666666666666666ddddddd66ddd5555555555555000000555556660000077773377076777000000000000000000
dd6666dddd66666666666666666666dddddd6666666666666666dddddd6666dd5555555555550000000055555500000077773377077660000777770000000000
ddd66ddddd66776666666666666766ddddd666666666666666666ddddd6666dd5555555555500000000005556670000073773337077770000777767007700000
dddddddddd66776666666666666666ddddd666666666666666666ddddd6766dd555555555500000000000055677770007333bb37070000000700007707777770
5dddddd5dd66666666666666666666dddd66666666666666666666dddd6666dd555555555000000000000005666000000333bb30000000000000000000077777
dd6666dddd66666666666666666666dd5dddddddddddddddddddddd5ddd666dd5555555550000000000000050000066603333330000000000000000000000000
ddd666dddd66666666666666666666ddddddddddddddddddddddddddddd66ddd5055555555000000000000550007777603b333300000000000ee0ee000000000
ddd666dddd66766666666666677666dddddd666dddddddddd666ddddddd66ddd55550055555000000000055500000766033333300000000000eeeee000000030
dd666ddddd66666666666666677666ddddd66666d6dddd6666666ddddd666ddd555500555555000000005555000000550333b33000000000000e8e00000000b0
dd666dddddd66666666dd66666666dddddd6666666dddd6d66666ddddd6666dd55555555555550000005555500000666003333000000b00000eeeee000000b30
ddd66ddddddd66666dddddd66666dddddddd666dddddddddd666dddddd6666dd5505555555555500005555550007777600044000000b000000ee3ee003000b00
ddd66dddddddddddddddddddddddddddddddddddddddddddddddddddddd66ddd5555555555555550055555550000076600044000030b00300000b00000b0b300
dd6666dd5dddddddddddddddddddddd55dddddddddddddddddddddd55dddddd55555555555555555555555550000005500999900030330300000b00000303300
5dddd55d000000000777777777777777777777700777777000000000000000006666666600000000000000000000000006660666066006600606000666066000
dddddddd000000007000077700007770000077777000777700000000000000006776666600000000000000000000000006660606060606060606000606060600
dddd66dd0000000070cc777cccc777ccccc7770770c7770700000000000000006776676600000000000000000000000006060666060606060666000606060600
ddd666660000000070c777cccc777ccccc777c0770777c0700000000000000006666666600000000000006666666000006060606060606060006000606060600
dd666666000000007077700007770000077700077777000700000000000000006666666600000000000666666666660006060606066606660666000666060600
5d667766000000007777000077700000777000077770000700000000000000006676666600000000066666666666666600000000000000000000000000000000
5dd67766000000007000000000000000000c000770000c0700000000000000006666676600000000666666666666666660000000000000666060606660000000
ddd66666000000007000000000000000000000077000000700000000000000006666666600000006666666666555666666000000000000060060606000000000
ddd66666000000007000000000000000000000077000000707777770000000000000000000000066666666665666566666600000000600060066606600000000
5dd66666000000007000000c000000000000000770cc000777776777000000000000000000000066666666656666566666600000c060d0060060606000000000
5d6676660000000070000000000cc0000000000770cc0007716716770000000000000000000005666666666566656666666600000d000d060060606660000000
dd6666660000000070c00000000cc00000000c0770000c077ef6eff7000000000000000000000566656666665556660006660000000000000000000000000000
ddd66666000000007000000000000000000000077000000767ffff76000000005555555500005566565666666666660660606600666660006666600660006600
dddd66dd0000000070000000000000000000000770c0000706333360000000005555555500005566565666666666660666066606666666066666660666006600
dddddddd0000000070000000c0000000000000077000000700494400000000005555555500005556656666666666660666666606600066066000660666606600
5dddd5dd000000007000000000000000000000077000c00700100100000000005555555500005556666666666666660ddddddd0dd000dd0dd000dd0ddddddd00
00000000000000007000000000000000000000077000000700777700500000000000000500005556666655666666660dd0d0dd0dd000dd0dd000dd0dd0dddd00
00aaaaaa00000000700000000000000000000007700c000707000070550000000000005500005555666566566666660dd000dd0ddddddd0ddddddd0dd00ddd00
0a99999900000000700000000000c000000000077000000770770007555000000000055500005555666566656666660dd060dd00ddddd000ddddd00dd000dd00
a99aaaaa000000007000000cc0000000000000077000cc077077bb07555500000000555500000555566656656666660000600000000000000000000000000000
a9aaaaaa000000007000000cc0000000000c00077000cc07700bbb07555555555555555500000555566665566666566666660000000000000000c00000000000
a99999990000000070c00000000000000000000770c00007700bbb075555555555555555000000555566666666556566666000000000000000000c0000000000
a999999900000000700000000000000000000007700000070700007055555555555555550000005555566666656665666660000000000000000000c000000000
a999999900000000077777777777777777777770077777700077770055555555555555550000000555556666656656666600000000000000000000c000000000
aaaaaaaa0000000007777777777777777777777007777770004bbb00004b000000400bbb0000000055555566665566666000000000000000000000c000000000
a49494a10000000070007770000077700000777770007777004bbbbb004bb000004bbbbb0000000005555555566666660000000000000000000000c00c000000
a494a4a10000000070c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb0000000000000555555555555000000000000000000000001010c00000
a49444aa0000000070777ccccc777ccccc777c0770777c07040000000400bbb004000000000000000000055555550000000000000000000000000001000c0000
a49999aa000000007777000007770000077700077777000704000000040000000400000000000000000000000000000000000000000000000000000000010000
a49444990000000077700000777000007770000777700c0742000000420000004200000000000000000000000000000000000000000000000000000000001000
a494a444000000007000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
a4949999000000000777777777777777777777700777777040000000400000004000000000000000000000000000000000000000000000000000000000000010
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000007000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000006660666066006600606000666066000000000000000000000000000000000000000
00000660000000000000000000000000000000000000000000000000000006660606060606060606000606060600000000000000000000000000000000000000
00000660000000000000000000000000000000000000000000000000000006060666060606060666000606060600000000000000000000000000000000000000
00000000000000000000000000000000000000000000000006666666000006060606060606060006000606060600000000000000000000000000000000000000
00000000000000000000000000000000000000000000000666666666660006060606066606660666000666060600000000000000000000000000000000000000
00000000000000000000000000000000000000000000066666666666666600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000666666666666666660000000000000666060606660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000006666666666555666666000000000000060060606000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066666666665666566666600000000600060066606600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066666666656666566666600000c060d0060060606000000000000000000000000000000006000000000000
000000000000000000000000000000000000000005666666666566656666666600000d000d060060606660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000566656666665556660006660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005566565666666666660660606600666660006666600660006600000000000000000000000000000000000000
00000000000000000000000000000000000000005566565666666666660666066606666666066666660666006600000000000000000000000000000000000000
00000000000000000000000000000000000000005556656666666666660666666606600066066000660666606600000000000000000000000000000000000000
00000000000000000000000000000000000000005556666666666666660ddddddd0dd000dd0dd000dd0ddddddd00000000000000000000000000000000000000
00000000000000000000000000000000000000005556666655666666660dd0d0dd0dd000dd0dd000dd0dd0dddd00000000000000000000000000000000000000
00000000000000000000000000000000000000005555666566566666660dd000dd0ddddddd0ddddddd0dd00ddd00000000000000000000000000000000000000
00000000000000000000700000000000000000005555666566656666660dd060dd00ddddd000ddddd00dd000dd00000000000000000000000000000000000000
00000000000000000000000000000000000000000555566656656666660000600000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000555566665566666566666660000000000000000c00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000555566666666556566666000000000000000000c0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000005555566666656665666660000000000000000000c000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000555556666656656666600000000000000000000c000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000055555566665566666000000000000000000000c000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000005555555566666660000000000000000000000c00c000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000555555555555000000000000000000000001010c00000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000055555550000000000000000000000000001000c0000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000070000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000070000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000000000
00000000000000000000000006000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005550555055005500505000005550505005505550055005505500000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050505050505000000500505050505050500050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050555050705050555000000500555050505500555050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050505050005000000500505050505050005050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505055505550555000000500505055065050550055005050000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005500055055505000000055505550555055505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050505050000000000000000000000000000000000000000000
00000660000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
00000660000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005550055055000000555050500000505055500550555055505550000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050500000505050500000505005005000505050005050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050500000550055500000505005005550555055005500000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050500000505000500000555005000050500050005650000000000000000000000000000000000000
00000000000000000000000000000000000000005050550055500000555055500000555055505500500055505050000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000008080804020000000000000000000202000000030303030303030304040402020000000303030303030303040404020202020200001313131300000300000000020202000013131313020004000000000200000000131313130004040000000002000000001313131300000000000000020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000001c3d3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000272034360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000313536000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0102000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0103000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000200177500605017750170523655017750160500605017750060501705076052365500605017750060501775017050177500605236550177501605006050177500605256050160523655256050177523655
011a00201604013040160401b0401d0401d0301b0401a0401b0401b0301b0101a040180401604013040110401304013020130401604011040110200f0400e0400c0400c0400c0300c0300c0200c0200c0100c010
01340000070400704003030030300302003020030100301000040000400703007030070200702007010070100a0400a04000030000300002000020000100001003040030400a0300a0300a0200a0200a0100a010
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000002953429554295741d540225702256018570185701856018500185701856000500165701657216562275142753427554275741f5701f5601f500135201b55135530305602454029570295602257022560
011000200a0700a0500f0710f0500a0600a040110701105007000070001107011050070600704000000000000a0700a0500f0700f0500a0600a0401307113050000000000013070130500f0700f0500000000000
002000002204022030220201b0112404024030270501f0202b0402202027050220202904029030290201601022040220302b0401b030240422403227040180301d0401d0301f0521f0421f0301d0211d0401d030
0108002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
013400201b0571f05722037260371b0271f0272201726017130571f057270372e037130271f027270172e017180571b0571d0371f037180271b0271d0171f0172205726057270372903722027260272701729017
011a0020277502e7501b7302b73032720277202e73027730277502e7501b7302b73032720277202e730277303275035750277302e7302b7202772032730357303275035750277302e7302b720277203273035730
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
011a0020297502e75018730247302b72027720297302e73018750247502b73027730297202e7201873024730337502e75022730357303272033720337402e73022750357503273033740337202e7202273035730
0018002005570055700557005570055700000005570075700a5700a5700a570000000a570000000a5700357005570055700557000000055700557005570000000a570075700c5700c5700f570000000a57007570
010d00103b6352e6003b625000003b61500000000003360033640336303362033610336103f6003f6150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
01 150c1644
00 1a150c44
00 1a160c44
00 1a160c44
00 1a0c0b44
00 1a160c44
00 1a160c44
02 1a0b1544
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

