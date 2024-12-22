pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- [initialization]
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
	max_djump=1
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,10
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
		sspr(unpack(split"72,32,56,32,36,23"))
		spr(70,64,57)
		spr(102,56,57)
    ?"🅾️/❎",54,72,10
    ?"levels by sheebeehs",27,85,2
    ?"maddy thorson",40,93,14
    ?"noel berry",46,101,7
		
		pal(10,130,1)

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
		rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14+5*p.t%2)
	end)

	pal(10,130,1)

	-- draw level title
	camera()
	if ui_timer>=-30 then
		if ui_timer<0 then
			draw_ui()
		end
		ui_timer-=1
	end
	
	pal(10,130,1)
	
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
        max_djump=1
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
    this.text="#-- mONT bLANC --#warning: sPEED#TECH REQUIRED#"
		this.hitbox.x+=1
		this.layer=4
	end,
	draw=function(this)
		if this.player_here() then
			rectfill(18,7,101,41,4)
			for i,s in ipairs(split(this.text,"#")) do
				camera()
				rectfill(26,7*i,101,7*i+6,9)
				rect(26,7,101,41,10)
				rectfill(59,40,68,57,9)
				rect(18,7,101,41,10)
				rect(59,41,68,57,10)
				rectfill(51,41,59,57,4)
				rect(51,41,59,57,10)
				line(60,41,67,41,9)
				?s,64-#s*2,7*i+1,10
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
 "0,0,2,1,cAVERN",
 "2,0,1,1,200M",
 "3,1,1,1,300M",
	"4,0,1,1,400M",
 "2,1,1,1,500M",
 "6,0,2,1,iCY gROTTO",
 "3,0,1,1,700M",
 "5,0,1,1,800M",
 "4,1,1,1,900M",
 "0,1,2,1,sUMMIT",
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
0000000000000000000000000888888000000000000000000000000000000000aee22eea5aaaaaa55aaaaaaa0007707770077700aaaaaaa50000444444440000
0000000008888880088888808888888808888880088888000000000008888880ae222eeaaaeeeeaaaaeeeeee0777777677777770eeeeeeaa0000499999940000
000000008888888888888888888ffff888888888888888800888888088f1ff18ae2222eaaeeeeeeaaeeee22e7766666667767777ee22eeea0004555559494000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8aee222eaaee22eeaaee22222767776667666667722222eea00049aaa99494000
0000000088f1ff1888f1ff1844fffff088f1ff1881ff1f80888ffff888fffff8aee22eeaae222eeaaee22222077666676666776022222eea0049aaa994999400
0000000044fffff044fffff06422220044fffff00fffff4488fffff844222280aeeeeeeaae2222eaaeee22ee0000000000000000e22eeeea0499aaa945555540
00000000642222006422220007000070672222000022227608f1ff1064222200aaeeeeaaaee222eaaaeeeeee0000000000000000eeeeeeaa049aaa9949aaa940
00000000007007000070007000000000000007000000700067722270007007005aaaaaa5aee22eea5aaaaaaa0000000000000000aaaaaaa54999999499aaa994
555555550000000000000000000000002222222266666666000770002eeeeee22eeeeee22eee0ee2000000006665666500077000000000000000000070000000
555555550000000000000000000d0000222222226666666600711700eaaaaaaeeaaa2aaeeaa20eae0003003067656765007aa700007700000770070007000007
55000055000000000000000000065050222222226666666607113170eaaaaaaeeaaaeaae2e2002ae00bb3b0067706770074a4a70007770700777000000000000
55000055007000700d6666d000060505222222226666666671313337eaaaaaaee2e202ae000000220223b3300700070000744700077777700770000000000000
5500005500700070005005000006050522222222666666667333b3b7eaaaaaaeeaa20e2ee2000000022883000700070007477970077777700000700000000000
55000055067706770005500000065050222222226666666607b3bb70eaaaaaaeeaaaeaaeea2002ee88d88b000000000000799700077777700000077000000000
555555555676567600500500000d00002222222266666666007bb700eaaaaaaeeaa2aaaeea202aae882200000000000000077000070777000007077007000070
555555555666566600055000000000002222222266666666000770002eeeeee22eeeeee222002ee2022000000000000000000000000000007000000000000000
aee222225aaaaaaaaaaaaaaaaaaaaaa5677666665666666666666666666666655555555555555555555555555500000000000000000000000000000000000000
aeee2222aaeeeeeeeeeeeeeeeeeeeeaa677766666677777777777777777777665555555555555550055555556670000000000000000777770000000000000000
aeee2222aeeeeeeeeeeeeeeeeeeeeeea67776666677777777777777777777776555555555555550000555555677770000000b000007766700000000000000000
aeeee222aeeeeee22eeeeee22eeeeeea67777666677777766777777667777776555555555555500000055555666000000000b00b076777000000000000000000
aeeee222aeeee222222ee222222eeeea6777766667777666666776666667777655555555555500000000555555000000b0003003077660000777770000000000
aeee2222aeee2222222222222222eeea6777666667776666666666666666777655555555555000000000055566700000030300b0077770000777767007700000
aeee2222aeee2222222222222222eeea6777666667776666666666666666777655555555550000000000005567777000030b0030070000000700007707777770
aee22222aee222222222222222222eea677666666776666666666666666667765555555550000000000000056660000003033030000000000000000000077777
22222eeaaee222222222222222222eea666667766776666666666666666667765555555550000000000000050000066600000000000000000088088000000000
2222eeeaaeee2222222222222222eeea666677766777666666666666666677765055555555000000000000550007777600300000000000000088888000000000
2222eeeaaeee2222222222222222eeea666677766777666666666666666677765555005555500000000005550000076600b00003000000000008980000000030
222eeeeaaeeee222222ee222222eeeea66677776677776666667766666677776555500555555000000005555000000550003000b0000000000888880000000b0
222eeeeaaeeeeee22eeeeee22eeeeeea6667777667777776677777766777777655555555555550000005555500000666000b00b30000b0000088388000000b30
2222eeeaaeeeeeeeeeeeeeeeeeeeeeea6666777667777777777777777777777655055555555555000055555500077776300b00b0000b00000000b00003000b00
2222eeeaaaeeeeeeeeeeeeeeeeeeeeaa66667776667777777777777777777766555555555555555005555555000007660b030b30030b0030000b000000b0b300
22222eea5aaaaaaaaaaaaaaaaaaaaaa566666776566666666666666666666665555555555555555555555555000000550303033003033030000b000000303300
22222222666666660777777777777777777777700777777001dddd00555555556665666500000000000000000000000000000000000000000000000000000000
2ee2222266666776771117771111777111117777771177771dddddd0555555556765676500000000000000000000000000000000000000000000000000000000
2ee22e226666677671cc777cccc777ccccc7771771c7771711111dd0555555556775677500000000000000000000111000000000000000000000000000000000
222222226666666671c777cccc777ccccc777c1771777c1700155510557555755755575500000000000000000011771110011000000000000000000000000000
22222222666766667177711117771111177711177777111701551100557555755755575500000000000000000177771dd1177100000000000000000000000000
22e2222266666676777711117771111177711117777111171555555056775677555555550000000000000000166771ddd7771d11000000000000000000000000
222222e2676666667111111111111111111c111771111c1715555550567656765555555500000000000000017776161d67771ddd110000000000000000000000
2222222266666666711111111111111111111117711111171111111056665666555555550000000001100017666aaa1a6671dddd711000011000000000000000
67766776566666657111111111111111111111177111111700000000555556660000000000000000171101eaaaaeee1aaa61ddd7166101171100000000000000
67666776667777667111111c111111111111111771cc11174999999955577776101111010000000171dd1eeeeeeee11aaea1aaaa666617771d10000000000000
676666766777777671111111111cc1111111111771cc111749aa9aa955555766117171110000001771ddd1e2e2e2e1aaeee11aaaaaa17771ddd1000001100000
677666766776677671c11111111cc11111111c1771111c17499999995555555511991111000001661ddaaa1e2e2e1aaa2eea1aaaaa116661dda1000017110000
67766776676667767111111111111111111111177111111749a9aaa9555556660177711000001eaaa1aaaaa1222111aae2e2a1aaa1a2aaa1aaaa1001771d1000
677777766766667671111111111111111111111771c1111749999999555777760177711000112e2e211aaaa12211a1aaae2e21aaaa2e2e1aaaaaa11771ddd100
667777666776667671111111c11111111111111771111117000490005555576601777110012222e21a11aaaa11a22a1aa2222a1aa222221aaaaaa16661ddaa10
56666665677667767111111111111111111111177111c1170004900055555555099d99111aa2a2211a21aaaa1222221aaa2222a2222221aaaaaa1eaaaa11aaa1
5666666666666665711111111111111111111117711111171dd01dd0555555555555555501aa2a21aa2a1aaaa122221aaa222222222211aaaaa1222aeae1aaa1
6677777777777766711111111111111111111117711c11171dd01dd055111155667555550011aa1aa2a21aaaa2a2a2a1a22222a2a2a21aaaaaa2a2a2a21aaa10
6777766777667776711111111111c11111111117711111171dd01dd05117171567777555000011aaaaaaa1aa2a2a2a2a2a2a2a2a2a21aaa11aaa2a2aa1a11100
67766666666667767111111cc1111111111111177111cc17155015505111991566655555000000111111111aaaaaa2a2a2a2a2aaaaaa11100111aaa111100000
67766666666667767111111cc1111111111c11177111cc17115555101117771155555555000000000000000111111aaaaaaaaa11111100000000111000000000
677766777667777671c11111111111111111111771c1111701555510111777116675555500000000000000000000011111111100000000000000000000000000
66777777777777667711111111111111111111777711117701155100511777156777755500000000000000000000000000000000000000000000000000000000
566666666666666507777777777777777777777007777770001110001199d9956665555500000000000000000000000000000000000000000000000000000000
aee22eeaaaaaaaaa07777777777777777777777007777770040000000400000004003bb0000000001eeeee001ee0000001eeee001ee01ee001eeee0000000000
aeee2eeaeeeeeeee7711777111117771111177777711777704bb300004b0000004bb3bb3000000001eeeeee01ee000001eeeeee01eee1ee01eeeeee000000000
aee22eeaeeeeeeee71c777ccccc777ccccc7771771c7771704bb3bb304bb000004bb3000000000001ee11ee01ee000001ee11ee01eeeeee01ee11ee000000000
aee2eeeae2eeee2271777ccccc777ccccc777c1771777c1704003bb004bb3bb30400000000000000122222101220000012222220122222201220111000000000
aee2eeea22eeee2e7777111117771111177711177777111742000000420b3b004200000000000000122112201220012012211220122122201220122000000000
aeeeeeeaeeeeeeee77711111777111117771111777711c1740000000400000004000000000000000122222201222222012201220122012201222222000000000
aeeeeeeaeeeeeeee7711111111111111111111777711117740000000400000004000000000000000122222101222222012201220122012201122221000000000
aee22eeaaaaaaaaa0777777777777777777777700777777040000000400000004000000000000000111111001111111011101110111011100111110000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077000000000000000000000000000000111000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000011771110011000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000177771dd1177100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000166771ddd7771d11000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000017776161d67771ddd110000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000001100017666iii1i6671dddd711000011000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000171101eiiiieee1iii61ddd7166101171100000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000171dd1eeeeeeee11iiei1iiii666617771d10000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001771ddd1e2e2e2e1iieee11iiiiii17771ddd1000001100000000000000000000000000000000000000000
000000000000000000000000000000000000000001661ddiii1e2e2e1iii2eei1iiiii116661ddi1000017110000000000000000000000000000000000000000
00000000000000000000000000000000000000001eiii1iiiii1222111iie2e2i1iii1i2iii1iiii1001771d1000000000000000000000000000000000000000
00000000000000000000000000000000000000112e2e211iiii12211i1iiie2e21iiii2e2e1iiiiii11771ddd100000000000000000000000000000000000000
000000000000000000000000000000000000012222e21i11iiii11i22i1ii2222i1ii222221iiiiii16661ddii10000000000000000000000000000000000000
0000000000000000000000000000000000001ii2i2211i21iiii1222221iii2222i2222221iiiiii1eiiii11iii1000000000000000000000000000000000000
00000000000000000000000000000000000001ii2i21ii2i1iiii122221iii222222222211iiiii1222ieie1iii1000000000000000000000000000000000000
0000000000000000000000000000000000000011ii1ii2i21iiii2i2i2i1i22222i2i2i21iiiiii2i2i2i21iii10000000000000000000000000000000000000
000000000000000000000000000000000000000011iiiiiii1ii2i2i2i2i2i2i2i2i2i21iii11iii2i2ii1i11100000000000000000000000000000000000000
000000000000000000000000000000000000000000111111111iiiiii2i2i2i2i2iiiiii11100111iii111100000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000111111iiiiiiiii11111100000000111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001eeeee001ee0000001eeee001ee01ee001eeee0000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001eeeeee01ee000001eeeeee01eee1ee01eeeeee000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001ee11ee01ee000001ee11ee01eeeeee01ee11ee000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000122222101220000012222220122222201220111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000122112201220012012211220122122201220122000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000122222201222222012201220122012201222222000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000122222101222222012201220122012201122221000000000000000000000000000000000000000000000
00000000000000000000000000000006600000000000111111001111111011101110111011100111110000000000000000000000000000000000000000000000
00000000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000060000000000000000001dd01dd001dddd0000000000000000000000000000000000000000000000000000000000
000000000000000070000000000000000000000000000000000000001dd01dd01dddddd000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000001dd01dd011111dd000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000155015500015551000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000115555100155110000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000015555101555555000000000000000000000000000000000000000000000000000000000
00000000000000000000007700000000000000000000000000000000011551001555555000000000000000000000000000000000000000000000000000000000
00000000000000000000007700000000000000000000000000000000001110001111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000070000000000000000
0000000000000000000000000000000000000000000000000000000iiiii0000i00iiiii00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000ii000ii00i00ii0i0ii0000000000000000000000000000000000000000000000000000000
000000660000000000000000000000000000000000000000000000ii0i0ii00i00iii0iii0000000000000000000000000000000000000000000000000000000
000000660006000000000000000000000000000000000000000000ii000ii00i00ii0i0ii0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000iiiii00i0000iiiii00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000020002220202022202000022000002220202000000220202022202220222022202220202002200000000000000000000000000
00000000000000000000000000020002000202020002000200000002020202000002000202020002000202020002000202020000000000000000000000000000
00000000000000000000000000020002200202022002000222000002200222000002220222022002200220022002200222022200000000000000000000000000
00000000000000000000000000020002000222020002000002000002020002000000020202020002000202020002000202000200000000000000000000000000
00000000000000000000000000022202220020022202220220000002220222000002200202022202220222022202220202022000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eee0eee0ee00ee00e0e00000eee0e0e00ee0eee00ee00ee0ee00000000000000000000000000000000000000
0000000000000000000000000000000000000000eee0e0e0e0e0e0e0e0e000000e00e0e0e0e0e0e0e000e0e0e0e0000000000000000000000000000000000000
0000000000000000000000000000000000000000e0e0eee0e0e0e0e0eee000000e00eee0e0e0ee00eee0e0e0e0e0000000000000000000000000000000000000
0000000000000000000000000000000000000000e0e0e0e0e0e0e0e000e000000e00e0e0e0e0e0e000e0e0e0e0e0000000000000000000000000000000000000
0000000000000000000000000000000000000000e0e0e0e0eee0eee0eee000000e00e0e0ee00e0e0ee00ee00e0e0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007700077077707000000077707770777077707070000000000000000000000000000000000000000000
00000000000000000000000000000000000600000000007070707070007000000070707000707070707070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007070707077007000000077007700770077007770000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007070707070007000000070707000707070700070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007070770077707770000077707770707070707770000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000070000000770000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000060000000000070000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000030303000003040404020000030300000000000200000000030303030303030304040402020000000303030303030303040404020202020203031313131302020200020202020202030313131313020204020202020202020303131313130004040202020202020203031313131300000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5353643114401433244115372014305253536364706828382857313214401432141433682828382828382835151541155353535420144014302441376828382840306253536364351541342014302828281028283862535363636424411515151541153752535354204014302441151515375254204014336810573536154136
5354212331323345351534211440306263644821332b2a2810284857313233254030481029002a281029002a353636156353536431141432333537682810282932320d6264684848241537313233381038282838293b6264212348353615413615363772535353542014323335363641344253543132331b2a28384848353721
63643114222223524435373132323348382857081b000029002a2828482526151430474700003a47471100003821233523626448483133484810282829002a002627484848282857353721231b2a28282829002a00001b1b2033103828353721372122235253536420334857724344353752535343441b000029002a28482114
22220d313232336264482122234848281029001b000000000000283857244115323342441111472122232b002a3114221423482900001b002a283828000000004137683829002a10482140302b00292a280000000000003b0848282828482114221440306263640908682810575264684862636363642b000000003a38573114
403342437448483828293114306838290000000000000000000029002a3536152627525343440a3232332b00001b204040302b1a000011000000002a000000003448292a00110028572014332b00000029000000000000001b2a2828293b31404014323348480a30683828293b652a2838484821220d2b00000000002a284820
334862544829002a10001b20332b2a00000000000000000000000000001b0935413462635354681b1b1b0000003b20321433091121222300000000000000000037680000000947285731331b00000000000000000000000000002828000000201433684828291b082b2a0000001b0029002a5731300000000000000000285720
382848552b00000029003b081b000000000000000000000000001100003b2022361527096264683911111100163b0821332140221432332b0000000000000000232900000020232838291b000000003a00000000000000003a282829001c0031334829002a00001b00000000000000000000001b082b0000000000003a384731
102829652b0000000000001b0000000000000000000000000000092b003b2014443537202310283821220d11111121142731323233452b00111111000000003a30000000002030102800111111001c280000000000003a103847471111001142442b0000000000000000000000000000000000001b0000000000000047574243
292a001b00000000000011000000000000000000000000390011702b1a3b311453441b3130292a28313342434344204015266148425411112122230000000028331112003b3133474711212223393a10000000000000002a57212222231142535400000000000000000000000000000000000000000000000000003b09475253
000000000000000000000911000000000000110000003a10570a30111111453153642b3b082b00291b3b62535354201441344857625343443114332b00003a38434344113a482122230a40143328382800000000000000003b314014320d5253540000000000000000000000000000000000390000000000391c0011200d5253
0000000000000039001120232b000000003a09113a2847424409310d42435343541b00001b00000000003b6263643114153768384852536374082b00000028285353637438283132320d3133282810283900000000110000003b31332b1b52536411000000003a000000000000000000113a10000000003a2800110a33096253
110e0f0100563a38572114306839003a3847202368474253642023425353535354390000000000000000001b252627313448282a5762642123103900003b25266364282828284848572527291a002a47280000000009110000001b1b003b526326272b0000001039001100000000001109682839000000103857424344202362
22222325262627474731403047474747280a143325275254211430626353536364380000001c0000000000113541152637382900291b21143328381111112415002a29002a3828104724340000111142383900001120232b00391a001c3b652515412700013a382811092b000000002130473847111111252627525354201422
4032332441153721222331332526272122230825153462642014332123626425222339013a00000000003b212335151522230000003b313048292a21232515410001000000292a5725413411114243532728013b214033393a3839111111251515153421234244470a30110000003a31320d4721222325154134525364314014
33424435153421401433424435413431144023244115262731332140302526151440220d68390000000011201423244140300001003a1008680000203035411522220d0000000047353637212362535341262661313345474747472122232441413637203062534344310d111111424343440a14403035411537626421233132
43535344243420143042535344241527201430241541153421224014302415414014304838281039003b211440302415144022236828382828393b204023241540302b0000003b424344211440235253154134424343534344212214403024153421224014235253542122222223525353534420141423243421222214402222
0000000000000000000000000000000000000000000000000000000000000000381057313240333515413420401433525354314030683828573132144030244128285735154134525354353636151536000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000002829002a57082b1b35363720143342535353442030682810282857313230241538281057351537626353444848353742000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000002a000000001b00001b1b3b3133425353536364203347472829160000000835362829002a575068485762642b1a1b4253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b3b626363542527084243444700000000112122232800003a28382916001b1b00003b5253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000111100000011001600000000001b252664354127626353442b00003b21401430290000002a28000000000000003b6253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000026271100000911000011113a003b244122233537212362642b00003b3114143300000000002900000000003900004862000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003641271111202339002123683900351540301b3b3114231b0000003a48313342000000000000000000003a2839005721000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000023353721223233474720303810291b2414332b1a1b20302b000000002a42435300000000000000003a28282828384720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000003a00760039000000000000000000000000000030485731334243434431332828393b35330000003b20332b0000000000626353000000000000002a283828002a282114000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000067394244475800003900000000000000000000336838285762635353444828382828212839000000081b00000000003a212362000000000011113a282900003a102040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003a424353642123113a1000000000000000000000482810290048486263642b2a2828282010282900001b000011002a285720142200000000112123681000000028473114000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000003a000011516263642140302527383900000000000000000028382839002a28281b1b0000292a4720473800000000000045113a384731401400000000214030472839000028252731000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000383911251526272114323335152728000000000000000000282900000000471039000000003b2114234739000000393a524468572527313200000011313214236847003a57241526000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003a4742443541153431334243443537212311110000003900002300010000000947283839111111311414232801003a2847625468472434212239013b42434431334751283847354115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
390000000000011042535344351541274253535344214014232527113a28000030602627113b202347474772434344311433252627105721236547254137204022237253535344252634474721232441000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
38103900003b4243535353534424153452535353542014403024412768383900402324152721403021222223525353433025154134212240142223243421141440142352535354244115272114302415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

