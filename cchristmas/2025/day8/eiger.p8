pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- eIGER
-- bY sHEEBEEHS
-- evercore v2.3.1

poke(0x5f2e,1)

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
end

function begin_game()
	max_djump=0
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,1
	music(30,0,7)
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
          [59]=x2%8>=6 and xspd>=0,
          [71]=y2%8>=6 and yspd>=0,
          [72]=y1%8<=2 and yspd<=0,
          [87]=x2%8>=6 and xspd>=0,
          [104]=x1%8<=2 and xspd<=0,})[tile_at(i,j)] then
            return true
      end
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
		sspr(unpack(split"72,32,56,32,36,33"))
		--spr(70,64,57)
		--spr(102,56,57)
    ?"🅾️/❎",54,72,1
    ?"lEVEL BY sHEEBEEHS",27,85,10
    ?"mADDY tHORSON",40,93,3
    ?"nOEL bERRY",46,101,14
		
		pal(10,131,1)
		pal(14,139,1)
		
		pal(11,141,1)
		
		-- particles
		foreach(particles,draw_particle)

		return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)

	-- bg clouds effect
	foreach(clouds,function(c)
		c.x+=c.spd-cam_spdx
  fillp(▒)
  --ovalfill for round clouds
		rectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col)
		fillp()
		if c.x>128 then
			c.x=-c.w
			c.y=rnd"120"
		end
	end)

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
		rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,6+5*p.t%2)
	end)
	
	pal(10,131,1)
	pal(14,139,1)
	
	pal(11,141,1)

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
			local maxfall=2

			-- wall slide
			if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) then
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
				,v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0)
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
	pal(8,djump==1 and 8 or djump==2 and 9+frames\3%2*-2 or 12)
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
				--pset(this.x+4+sin(this.offset*2+i/10),this.y+i,6)
			end
			draw_obj_sprite(this)
		end
	end
}

dballoon={
  init=function(this) 
    this.offset=rnd(1)
    this.start=this.y
    this.timer=0
    this.hitbox=rectangle(-1,-1,10,10)
  end,
  update=function(this) 
    if this.spr==28 then
      this.offset+=0.01
      this.y=this.start+sin(this.offset)*2
      local hit=this.player_here()
      if hit and hit.djump<2 then
        max_djump=2
        psfx(6)
        this.init_smoke()
        hit.djump=max_djump
        this.spr=0
        this.timer=60
        max_djump=0
      end
    elseif this.timer>0 then
      this.timer-=1
    else 
      psfx(7)
      this.init_smoke()
      this.spr=28
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
		--hit.djump=max_djump
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

function init_fruit(this,ox,oy)
	sfx_timer=20
	sfx"16"
	init_object(fruit,this.x+ox,this.y+oy,26).fruit_id=this.fruit_id
	destroy_object(this)
end

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
    this.text="#-- tHE eIGER --#caution: wATCH#YOUR FOOTING!#"
		this.hitbox.x+=1
		this.layer=4
	end,
	draw=function(this)
		if this.player_here() then
			rectfill(18,7,101,41,4)
			for i,s in ipairs(split(this.text,"#")) do
				camera()
				rectfill(26,7*i,101,7*i+6,9)
				rect(26,7,101,41,1)
				rectfill(59,40,68,57,9)
				rect(18,7,101,41,1)
				rect(59,41,68,57,1)
				rectfill(51,41,59,57,4)
				rect(51,41,59,57,1)
				line(60,41,67,41,9)
				?s,64-#s*2,7*i+1,1
				camera(draw_x,draw_y)
			end
		end
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
			rectfill(34,2,96,35,0)
			spr(26,55,6)
			?"x"..two_digit_str(fruit_count),64,9,14
			draw_time(43,16)
			?"deaths:"..two_digit_str(deaths),48,24,14
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
 "0,0,8,4,tHE eIGER",
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={}

--@end

--tiles stack
--assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
1,player_spawn
11,platform
12,platform
18,spring
19,spring
22,balloon
23,fall_floor
26,fruit
28,dballoon
45,fly_fruit
86,message
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
0000000000000000000000000888888000000000000000000000000000000000e33aa33e5eeeeee55eeeeeee0007707770077700eeeeeee55000222222220000
0000000008888880088888808888888808888880088888000000000008888880e3aaa33eee3333eeee3333330777777677777770333333ee5500288888820000
000000008888888888888888888ffff888888888888888800888888088f1ff18e3aaaa3ee333333ee3333aa3776666666776777733aa333e5552bbbbb8282000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8e33aaa3ee33aa33ee33aaaaa7677766676666677aaaaa33e5552822288282000
0000000088f1ff1888f1ff1844fffff088f1ff1881ff1f80888ffff888fffff8e33aa33ee3aaa33ee33aaaaa0776666766667760aaaaa33e5528222882888200
0000000044fffff044fffff06422220044fffff00fffff4488fffff844222280e333333ee3aaaa3ee333aa3300000000000000003aa3333e528822282bbbbb20
00000000642222006422220007000070672222000022227608f1ff1064222200ee3333eee33aaa3eee3333330000000000000000333333ee5282228828222820
00000000007007000070007000000000000007000000700067722270007007005eeeeee5e33aa33e5eeeeeee0000000000000000eeeeeee52888888288222882
55555555000000000000000000000000aaaaaaaa11111111000770005999999559999995599909950004003e6665666500077000000000000000000070000000
555555550000000000000000000d0000aaaaaaaa11111111007ee700911111199111511991150919000043ee6765676500799700007700000770070007000007
55000055000000000000000000065050aaaaaaaa1111111107ee3e7091111119911191195950051900994ee06770677007898970007770700777000000000000
55000055007000700d6666d000060505aaaaaaaa111111117e3e3337911111199595051900000055048242900700070000788700077777700770000000000000
55000055007000700050050000060505aaaaaaaa111111117333a3a7911111199115095995000000088828900700070007877270077777700000700000000000
55000055067706770005500000065050aaaaaaaa1111111107a3aa70911111199111911991500599048888800000000000722700077777700000077000000000
555555555676567600500500000d0000aaaaaaaa11111111007aa700911111199115111991505119048888400000000000077000070777000007077007000070
55555555566656660005500000000000aaaaaaaa1111111100077000599999955999999555005995004484000000000000000000000000007000000000000000
e33aaaaa5eeeeeeeeeeeeeeeeeeeeee53aa111115333333333333333333333355555555555555555555555555500000000000000000000000000000000000000
e333aaaaee33333333333333333333ee3aaa111133aaaaaaaaaaaaaaaaaaaa335555555555555550055555556670000000000000000777770000000000000000
e333aaaae3333333333333333333333e3aaa11113aaaaaaaaaaaaaaaaaaaaaa3555555555555550000555555677770000000e000007766700000000000000000
e3333aaae333333aa333333aa333333e3aaaa1113aaaaaa11aaaaaa11aaaaaa3555555555555500000055555666000000000e00e076777000000000000000000
e3333aaae3333aaaaaa33aaaaaa3333e3aaaa1113aaaa111111aa111111aaaa355555555555500000000555555000000e0003003077660000777770000000000
e333aaaae333aaaaaaaaaaaaaaaa333e3aaa11113aaa1111111111111111aaa355555555555000000000055566700000030300e0077770000777767007700000
e333aaaae333aaaaaaaaaaaaaaaa333e3aaa11113aaa1111111111111111aaa355555555550000000000005567777000030e0030070000000700007707777770
e33aaaaae33aaaaaaaaaaaaaaaaaa33e3aa111113aa111111111111111111aa35555555550000000000000056660000003033030000000000000000000077777
aaaaa33ee33aaaaaaaaaaaaaaaaaa33e11111aa33aa111111111111111111aa35555555550000000000000050000066600000000000000000088088000000000
aaaa333ee333aaaaaaaaaaaaaaaa333e1111aaa33aaa1111111111111111aaa35055555555000000000000550007777600300000000000000088888000000000
aaaa333ee333aaaaaaaaaaaaaaaa333e1111aaa33aaa1111111111111111aaa35555005555500000000005550000076600e00003000000000008980000000030
aaa3333ee3333aaaaaa33aaaaaa3333e111aaaa33aaaa111111aa111111aaaa3555500555555000000005555000000550003000e0000000000888880000000e0
aaa3333ee333333aa333333aa333333e111aaaa33aaaaaa11aaaaaa11aaaaaa355555555555550000005555500000666000e00e30000e0000088388000000e30
aaaa333ee3333333333333333333333e1111aaa33aaaaaaaaaaaaaaaaaaaaaa355055555555555000055555500077776300e00e0000e00000000e00003000e00
aaaa333eee33333333333333333333ee1111aaa333aaaaaaaaaaaaaaaaaaaa33555555555555555005555555000007660e030e30030e0030000e000000e0e300
aaaaa33e5eeeeeeeeeeeeeeeeeeeeee511111aa3533333333333333333333335555555555555555555555555000000550303033003033030000e000000303300
aaaaaaaa111111110777777777777777777777700777777000000000555555556665666500000000000000000000000000000000000000000000000000000000
aaaaa33a1aa111117711177711117771111177777711777700111100555555556765676500000000000000000000000000000000000000000000000000000000
aaaaa33a1aa11a1171cc777cccc777ccccc7771771c7771701717110555555556775677500000000000000000000000000000000000000000000000000000000
aaaaaaaa1111111171c777cccc777ccccc777c1771777c1701991110557555755755575500000000000000000000000000011000000000000000000000000000
aaa3aaaa111111117177711117771111177711177777111711777111557555755755575500000000000000000000000000171100000000000000000000000000
aaaaaa3a11a111117777111177711111777111177771111711777111567756775555555500000000000000000000000001771d10000000000000000000000000
a3aaaaaa111111a17111111111111111111c111771111c170177711056765676555555550000000000000000000000011771ddd1101100000000000000000000
aaaaaaaa1111111171111111111111111111111771111117099d99115666566655555555000000000000000000000011d661ddd6617710000000000000000000
3aa11aa35333333571111111111111111111111771111117000000005555566600000000000000000000000000000171da1ddd666771d1000000000000000000
3a111aa333aaaa337111111c111111111111111771cc11174999999955577776101111010000000000000001100117761ae1dda6771ddd100000000000000000
3a1111a33aaaaaa371111111111cc1111111111771cc111749119119555557661171711100000000000000171116666aaeee1aaa661add611000000000000000
3aa111a33aa11aa371c11111111cc11111111c1771111c1749999999555555551199111100000000000001771d1aaaaeeee31aa3a1aaa6667110000000000000
3aa11aa33a111aa3711111111111111111111117711111174919111955555666017771100000000000011661daa13e3e3e11a1ae1e1aaa6771d1100000000000
3aaaaaa33a1111a371111111111111111111111771c111174999999955577776017771100000000000131aa1aaa1e3e3e1aaa1aa331aaaa61daaa10000000000
33aaaa333aa111a371111111c1111111111111177111111700049000555557660177711000000000013a31aa1aaa13331aa331aa3331aaaa1aaaaa1000000000
533333353aa11aa37111111111111111111111177111c1170004900055555555099d99110000000001a3a3a31aaaa13333331a1aa3333aa3a3aaa10000000000
53333333333333357111111111111111111111177111111700000000000000005555555500000000001aaa3a3aaaaa333331aa1aaa3a3a3a3aa1100000000000
33aaaaaaaaaaaa33711111111111111111111117711c11170011110010111101667555550000000000011aaaa3aaa3a3a3a1a3a1aaa3a3aaa110000000000000
3aaaa11aaa11aaa3711111111111c11111111117711111170117171011171711677775550000000000000111aaaa3a3a3a1a3a3a1aaaaa111000000000000000
3aa1111111111aa37111111cc1111111111111177111cc1701119910111199116665555500000000000000001111aaaaa1aaaaaaa11111000000000000000000
3aa1111111111aa37111111cc1111111111c11177111cc1711177711011777105555555500000000000000000000111111111111100000000000000000000000
3aaa11aaa11aaaa371c11111111111111111111771c1111711177711011777106675555500000000000000000000000000000000000000000000000000000000
33aaaaaaaaaaaa337711111111111111111111777711117701177710011777106777755500000000000000000000000000000000000000000000000000000000
5333333333333335077777777777777777777770077777701199d9901199d9906665555500000000000000000000000000000000000000000000000000000000
e33aa33eeeeeeeee07777777777777777777777007777770040000000400000004003ee0000000001eeeee001eeeee0001eeee001eeeee001eeeee0000000000
e333a33e333333337711777111117771111177777711777704ee300004e0000004ee3ee3000000001eeeeee01eeeeee01eeeeee01eeeeee01eeeeee000000000
e33aa33e3333333371c777ccccc777ccccc7771771c7771704ee3ee304ee000004ee3000000000001ee11110111ee1101ee11ee01ee111101ee01ee000000000
e33a333e3a3333aa71777ccccc777ccccc777c1771777c1704003ee004ee3ee30400000000000000133330000013300013301110133330001333330000000000
e33a333eaa3333a37777111117771111177711177777111742000000420e3e004200000000000000133110000013300013313330133110001330133000000000
e333333e3333333377711111777111117771111777711c1740000000400000004000000000000000133333001333330013333330133333001330133000000000
e333333e333333337711111111111111111111777711117740000000400000004000000000000000133333301333333011333310133333301330133000000000
e33aa33eeeeeeeee0777777777777777777777700777777040000000400000004000000000000000111111101111111001111100111111101110111000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
831222325351515151515151145151515151515151145151515151515151515151515151515151432434354693000000000000828392b1000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000a100000000000000000000000000a300f3e3c20000000000a3
8213410432425151515151515151515151515151145151515151515151515151515151515151514326354586839200000000a301829300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008293122232b2000000d3e3
a2841323334251515151515151515151515151515151515151515151515151515151515151515151722545920000000000a28282920000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000930000e3a38374020433110000001222
22223252625151145151515151515114515151515151515151515151511451515151515151515151432646d300000076e3a3838200000064c200f3e3d3000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a301821232747412410324440000001323
2341034251515151515151515151515151515151515151511451515151515151515151515151515151721232c266f312322444829385d3122232122232000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000243434441341223213233325459300a38212
3213334214515151515151145151515151515151515151515151515151515151515151145151515151431341321222040325353434441241043313040311a300
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c2263635354413233352722435457482828302
04325251515151515151515151515151515151515151515151515151515151515151515151515151515172133302412333263535354613233352721323d07400
0000000000000000000000000000000000000000000000000000000000000000000000000000d3e300000000f312223226364652626251432635354401828202
41334251515151511451515151515151515151515151515151515151515151515151515151515151515151627213335262722636465262626251516272244493
0000000000000000000000000000000000000000000000000000000000000000000000000000122232c30000a023414132526251515114517226364682920013
33525151515151515151515151515151515114515151515151515151515151515151515151145151511451515162625151516262625151515151515143254574
0000000000d300e3f300000000000000000000000000000000000000000000000000000000b31304413200a3123213233342515151515151431232b1a2c10024
44535151515151515151515151515151515151515151515114515151515151515151515151515151515151515151515151145151515114515151515143263534
e0f010c2f3122222320000000000000000000000000000000000000000000000000000000000b113233383820204223252515114515151514302031100001126
35444251511451515151515151145151515151515151515151515151515151515151515151515151515151515151515151515151511451515114515151722636
222232122241044103000000000000000000000000000000000000000000000000000000000000a0223286751341413342511451515151514313413200001232
26464251515151515151515151515151515151515151515151515151515151515151515151515151515151515151145151515151515151515151515151516262
042333132323414133000000000000000000000000000000000000000000000000000000000000a2020386838413335251515151515151515172133393110241
32525151515151515151515151515151515151515151515151515151511451515151515114515151515151515151515151515151515151515151515151515151
3352627224441333b200000000000000000000000000000000000000000000000000000000000000023386017524445351515151515151145173123275a02323
33425151515151515114515151515151515151515151515151515151515151515151515151515114515151515151515151515151515151515151515151515151
62511473263544b1000000000000000000000000000000000000000000000000000000000000000080849200a225354442515151515151514312040374123252
62515114515151515151515151515151515151511451515151515151515151515151515151515151515151515151145151515151511451515151515114515151
51514312322646b200000000000000000093f3e300d3000000000000000000000000000000000000b1a20000f326354542145151515151514313410312410342
51511451515151515151515151145151515151515151515151515151515151515114515151515151515151515151515151515151515151515151515151515151
51514313043284930000c300d3e30000a37412222232000000000000000000000000000000000000000000001232264642515151515151515172133302043342
51515151515151515151515151515151515151515151515151515114515151515151515151515151515151145151515151515151515151515151515151515114
51145172133374829200122222321111741241044133000000111100000000000000000000000000000000c30241325251515151515151515151627213335251
51515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151511451
145151511612328393a313044133122232132323338693a3001232000000000000000000000000e3000000120441334251515151515114515151515162625151
51515151515151515151515151515151515151145151515151515151515151145151515151511451515151515151511451515114515151515151145151515151
51516373120403820182751333120441335272244474748393024132000000000000000093001112321111132333525151515151515151515151515151515151
51515151515151515151515151515151515114515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151
5173244413233392a28283847502410352514326353444747402040393000000d3f3c3a301751204031222223206515151145151515151515151515114515151
51515151515151511451515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151
43243535441232110092a20182132333425151722636461222412333869200111222327474740241331323234132425151515151515151515151511451515151
51145151515151515151515151515151515151515151145151515151515151515151515151515151515151145151515151515151515151515151515151515151
7325353646134132b20000a2741232525114515162627213233312327493b3120441332434441333526262721333425151515151515151515151515151515151
51515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515114
322646b2a2751303000000b312410342515151515151516262721341327474024133243535465262515151516262515151515151515151515151515151515151
51515151515151515151515151145151515151515151515151515151515151515151511451515151515151515151515114515151515151515114515151515151
4132b100c192b180000000b302413353515151515151515151517202412232133315263646525114515151515151515151515114515151515151515151515151
51515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151
233311c300000000000000b313332444425151145151511451514313232333526251626262515151515114515151145151515151515151515114515151515151
51515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151
72122232e300c20000000000b1b12545535151515151145151515162626262515151511451515151515151515151515151515151515151515151515151515151
51515151515151515151515151515151515151515151515151511451515151515151515151515151515151515151515151515151515151515151515151515151
4313230432122232b200000000112635444251515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151
51515114515151515151515151515151515151515151511451515151515151515151515151515151515151515151515151515151515114515151515151515151
516272133302413311000000b3123226464251515151515151515151511451515151515151515151511451515151515151145151515151515151515151145151
51515151515151515151515151511451515151515151515151515151515151515151515151145151515151145151515114515151515151515151515151145151
511451627213331232b2a193a3024132525151515151515151515151515151515151515151515151145151515151515151515151515151515151515151515151
51515151515151515151515114515151515151145151515151515151515151515114515151515151515151515151515151515151515151515151515151515151
51515151517212040393a38274020433425114515151515114515151515151515151145151515151515151515151515151515151515151515114515151515151
51515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151
51515114514302410301837512410352515151515151515151515114515151515151515151515151515151515151515151511451515151515151515151515151
51515151515151145151515151515151515151515151515151515151145151515151515151515151515151515151515151515151145151515151515151515151
__label__
00000000000000000007000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060060000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000
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
00000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000171100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001771d10000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000011771ddd1101100000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000011d661ddd6617710000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000171dj1ddd666771d1000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000001100117761jr1ddj6771ddd100000000000000000000060000000000000000000000000000000
00000000000000000000000000000000000000000000000000171116666jjrrr1jjj661jdd611000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001771d1jjjjrrrr31jj3j1jjj6667110000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000011661djj13r3r3r11j1jr1r1jjj6771d1100000000000000000000000000000000000060000000000
0000000000000000000000000000000000000000000000131jj1jjj1r3r3r1jjj1jj331jjjj61djjj10000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000013j31jj1jjj13331jj331jj3331jjjj1jjjjj1000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000001j3j3j31jjjj13333331j1jj3333jj3j3jjj10000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000001jjj3j3jjjjj333331jj1jjj3j3j3j3jj1100000000000000000006000000000000000000000000000
0000000000000000000000000000000000000000000000011jjjj3jjj3j3j3j1j3j1jjj3j3jjj110000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000111jjjj3j3j3j1j3j3j1jjjjj111000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000001111jjjjj1jjjjjjj11111000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111111111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001rrrrr001rrrrr0001rrrr001rrrrr001rrrrr0000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001rrrrrr01rrrrrr01rrrrrr01rrrrrr01rrrrrr000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001rr11110111rr1101rr11rr01rr111771rr01rr000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000133330000013300013301110133330771333330000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000133110000013300013313330133110001330133000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000133333001333330013333330133333001330133000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000133333301333333011333310133333301330133000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000111111101111111001111100111111101110111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001111100001001111100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000011000110010011010110000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000011010110010011101110000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000011000110010011010110000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001111100100001111100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000000000
00000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000j000000000000000000000000000000000000jj00000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000j000jjj0j0j0jjj0j0000000jj00j0j00000j000j0j0jjj0jjj0jj00jjj0jjj0j0j00jj000000000000000000000000000000
000000006000000000000000000j000jj00j0j0jj00j0000000jj00jjj00000jjj0j0j0jj00jj00jj00jj00jj00j0j0j00000000000000000000000000000000
000000000000000000000000070j000j000jjj0j000j0000000j0j000j0000000j0jjj0j000j000j0j0j000j000jjj000j000000000000000000000000000000
000000000000000000000000000jjj00jj00j000jj00jj00000jjj0jj000000jj00j0j00jj00jj0jjj00jj00jj0j0j0jj0000000000000000000000000000000
00000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000003330000000000000000000003330000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000003330033033003300303000000307303003303300033003303300000000000000000000000000000000000000
00000000000000000000000000000000000000003030303030303030333000000300303030303030300030303030000000000000000000000000000000000000
00000000000000000000000000000000000000003030333030303030003000000300333030303300003030303030000000000000000000000000000000000000
00000000000000000000000000000000000000003030303033003300330000000300303033003030330033003030000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000rr000000000000000000rrr00000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000r0r00rr0rrr0r0000000r0r0rrr0rr00rr00r0r0600000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000r0r0r0r0rr00r0000000rr00rr00r0r0r0r0rrr0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000r0r0r0r0r000r0000000r0r0r000rr00rr0000r0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000r0r0rr000rr00rr00000rrr00rr0r0r0r0r0rr00000000000000000000000000000000000000000000
00000000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000030303000003040404020000030300000000000200000000030303030303030304040402020000000303030303030303040404020202020203031313131304020200000000000000030313131313020204000000000000000303131313130404040000000000000003031313131300000000020000020200
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003900000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a28003c3f3e763d00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000283839212222222300000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003f003e2c3a424344201440143039000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003f3e3c003d2122222342535364313214403338000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000212222230a1440143362535425266131336828390000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a31323214233132332527626424342123482810290000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a42443133252626151526261537203029002a000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006253434424151515411515342114332b0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d003f3e2c000000000000000000000000002a525364241541151515153731331b000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110000212222222339003a0000000000000000003f3d6264251541151515153442434400000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a0000212223003a311440143328382839000000000000002c21222223241515151515153452535439000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003140302838573132331b2a2810281111000000003b2114141430241515151515413462535447282900000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b313310282921222311001c2a38212311000000113114401433241515151515151527525344380000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a2838292a003114142300003a47201423111111212331323325151515151515151534626364290000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a283f00000031323311114721144030212222143025262615411515154115151515612123000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d3e3f00003a212300003a21234243434420143233311440143324151515151515151515151534211430000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000112122231111472030111121403062635354313325262731323325154115151515151515151541342040332b0000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a32323342434431142223313233252762642526151515262626151515151515151515151515153731331b000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003900111100003921222351625353442014332526261515262615151515411515151515151515151541151515153421222300000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e3d003e2c3a102821232b3a4731403024276263643133251515151515151515151515151515151515151515154115151515153420143047390000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003f3c3a2123212222233847313047474244313324152626262626151515151515154115151515151515151515151515151515363615413431401423102839000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002122221433314014334721232023425353442515151515151515151515151515151515151515151515154115153636363637424435151527313233472900000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003114403042443133212240333133525353642415154115151515151541151515151515151515151515411515372122222342535344353637424343440000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b31323352542527313233252627626364251515151515151515151515151515151515151515151515151534211440323362636364212223626353540000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b4842536424152626261515152626261515151515151515151515151515154115151515151515151515373132332b002a10570a323214222362640000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a476264251515411515151515151515151515151515151515151515151541151515151515411515363742441b1b000000002a48285731323329000000000000
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

