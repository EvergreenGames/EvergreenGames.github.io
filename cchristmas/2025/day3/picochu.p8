pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--picochu
--by moderator dev

-- [initialization]
-- evercore v2.3.1

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

-- global tables
objects,collected={},{}
-- global timers
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
-- global camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

-- [entry point]

function _init()
	frames,start_game_flash=0,0
	music(40,0,7)
	lvl_id=0
	-- begin_game()
end

function begin_game()
	max_djump=2
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,2,0
	music(0,0,7)
	load_level(1)
end

function is_title()
	return lvl_id==0
end

-- [effects]


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

function tile_at(x,y,oob)
 if x>=0 and x<lvl_w and y>=0 and y<lvl_h then
	 return mget(lvl_x+x,lvl_y+y)
	else
	 return oob or 0
	end
end

function tile_set(x,y,t)
 if x>=0 and x<lvl_w and y>=0 and y<lvl_h then
	 mset(lvl_x+x,lvl_y+y,t)
	end
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
		--return
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
		if obj.type==player and freeze > 0 then return end
		obj.move(obj.spd.x,obj.spd.y,0);
		(obj.type.update or stat)(obj)
	end)

	-- move camera to player
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
			sfx"37"
		end
	end
end
-->8
-- [draw loop]

function _draw()
	if freeze>0 then
		--return
	end

	-- reset all palette values
	pal()
	pal({[0]=0,1,130,3,4,5,6,7,8,9,10,11,12,13,14,15},1)

	-- start game flash
	if is_title() then
		if start_game then
			for i=1,15 do
				pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
			end
		end

		cls()

		-- credits
    sspr(64,64,64,64,36,10)

    ?"🅾️+❎",54,72,13
    ?"maddy thorson",38,84,13
    ?"noel berry",44,90,13
    ?"meep | petthepetra",28,104,13
    ?"rubyred | gonengazit",24,110,13
	?"v1.1",0,0,1

		-- particles
		foreach(particles,draw_particle)

		return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)

	-- bg clouds effect
	foreach(clouds,function(c)
		c.x+=c.spd-cam_spdx
		rectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col)
		if c.x>128 then
			c.x=-c.w
			c.y=rnd"120"
		end
	end)

	-- set cam draw position
	draw_x=round(cam_x)-64
	draw_y=round(cam_y)-64
	camera(draw_x,draw_y)

	-- draw bg terrain
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4)
	
	-- set draw layering
	-- positive layers draw after player
	-- layer 0 draws before player, after terrain
	-- negative layers draw before terrain
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
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,7
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
		local h_input,v_input=
		 tonum(btn(➡️))-tonum(btn(⬅️)),
		 tonum(btn(⬇️))-tonum(btn(⬆️))
		-- spike collision / bottom death
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end

		-- on ground checks
		local on_ground=this.djump~=1 and this.dash_time==0 and this.is_solid(0,1)

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
		
		if this.djump==0 and this.to_refill then
		 this.djump=max_djump
		 this.prev_dash_dir=nil
		 this.to_refill=false
		end

		-- grace frames and dash restoration
		if on_ground then
			this.grace=6
			if this.djump<max_djump then
				psfx"54"
				this.djump=max_djump
				this.prev_dash_dir=nil
			end
		elseif this.grace>0 then
			this.grace-=1
		end

		-- dash effect timer (for dash-triggered events, e.g., berry blocks)
		this.dash_effect_time-=1

		-- dash startup period, accel toward dash target speed
		if this.dash_time>0 then
			if this.dash_time %2 == 0 then 
				local sm = this.init_smoke(-this.spd.x*2, -this.spd.y*2)
				sm.spd.x -= this.spd.x/4
				sm.spd.y -= this.spd.y/4
			end
			this.dash_time-=1
			this.spd=vector(appr(this.spd.x,this.dash_target_x,this.dash_accel_x),appr(this.spd.y,this.dash_target_y,this.dash_accel_y))
		else
			-- x movement
			local maxrun=2
			local accel=on_ground and 0.93 or 0.80
			local deccel=0.16

			-- set x speed
			this.spd.x=abs(this.spd.x)<=maxrun and
			appr(this.spd.x,h_input*maxrun,accel) or
			appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)

			-- facing direction
			if this.spd.x~=0 then
				this.flip.x=this.spd.x<0
			end

			-- y movement
			local maxfall=3

			-- wall slide
			if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) then
				maxfall=0.8
				-- wall slide smoke
				if rnd"10"<2 then
					this.init_smoke(h_input*6)
				end
			end

			-- apply gravity
			if not on_ground then
				this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.124 and 0.334 or 0.167)
			end

			-- jump
			if this.jbuffer>0 then
				if this.grace>0 then
					-- normal jump
					psfx"1"
					this.jbuffer=0
					this.grace=0
					this.spd.y=-3.36
					this.init_smoke(0,4)
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
					if wall_dir~=0 then
						psfx"2"
						this.jbuffer=0
						this.spd=vector(-wall_dir*(maxrun+1.06),-3.36)
						if not this.is_ice(wall_dir*3,0) then
							-- wall jump smoke
							this.init_smoke(wall_dir*6)
						end
					end
				end
			end

			-- dash
			local d_full=1.4*6.58
			local d_half=1.4*4.6528

			if this.djump==2 and dash or this.djump==1 then
				--this.init_smoke()
				this.djump-=1
				if this.djump~=0 or h_input|v_input~=0 and not (this.prev_dash_dir and h_input==this.prev_dash_dir.x and v_input==this.prev_dash_dir.y) then
				 this.dash_time=4
				 this.dash_effect_time=10
				 has_dashed=true
				 -- calculate dash speeds
				 this.spd=vector(h_input~=0 and h_input*(v_input~=0 and d_half or d_full) or
				  (v_input~=0 and 0 or this.flip.x and -d_full or d_full),
				  v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0)
				 -- effects
				 psfx"3"
				 freeze=6
				 -- dash target speeds and accels
				 this.dash_target_x=2*sign(this.spd.x)
				 this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
				 this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177
				 this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
			  this.prev_dash_dir=vector(h_input,v_input)
			 end
			elseif this.djump<=0 and dash then
				-- failed dash smoke
				psfx"9"
				this.init_smoke()
			end
		end

		-- animation
		this.spr_off+=0.25
		this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or (this.djump>0 or this.dash_time>2) and 3 or abs(this.spd.y)<0.5 and 9 or this.spd.y<0 and 8 or 10) or	-- wall slide or mid air
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
		if freeze == 5 or freeze == 3 then
			circfill(this.x+3, this.y+3, freeze+1, 10)
		end
		local clamped=mid(this.x,-1,lvl_pw-7)
		if this.x~=clamped then
			this.x=clamped
			this.spd.x=0
		end
		
		if this.dash_effect_time and this.dash_effect_time > 3  and this.dash_effect_time < 10 then
			local cx,cy = this.x+4, this.y+4
			--for _x=this.spd.y/2,-this.spd.y/2 do
				--for _y=-this.spd.x/2,this.spd.x/2 do
					line(
						cx - this.spd.x*4,
						cy - this.spd.y*4,
						cx + this.spd.x*2,
						cy + this.spd.y*2,
						10
					)
				--end
			--end
		end
		-- draw player hair and sprite
		--set_hair_color(this.djump)
		--draw_hair(this)
		draw_obj_sprite(this)
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

		if lvl_id==1 then
			this.y = this.target+24
			this.x+=4
			this.state = 2
			this.delay = 3
		end
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
				hit.spd=vector(this.dir*4.3,-2.25)
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
				this.delay=60 -- how long it hides for
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
		if this.state~=2 then
			spr(this.state==1 and 26-this.delay/5 or 23,this.x,this.y)
		end
	end,
}

function break_fall_floor(obj)
	if obj and obj.state==0 then
		psfx"15"
		obj.state=1
		obj.delay=15 -- time until it falls
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
				hit.to_refill=true
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
		this.spd=vector(rnd"0.5",rnd"0.5")
		this.x+=-1+rnd"2"
		this.y+=-1+rnd"2"
		this.flip=vector(rnd()<0.5,rnd()<0.5)
		this.layer=3
	end,
	update=function(this)
		this.spr+=0.5
		if this.spr>=32 then
			destroy_object(this)
		end
	end
}

fruit={
	is_fruit=true,
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
	is_fruit=true,
	init=function(this)
		this.start=this.y
		this.step=0.5
		this.sfx_delay=8
	end,
	update=function(this)
		-- fly away
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
		collected[this.id]=true
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
	is_fruit=true,
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
	init_object(fruit,this.x+ox,this.y+oy,26).id=this.id
	destroy_object(this)
end

key={
	update=function(this)
		this.spr=flr(9.5+sin(frames/30))
		if frames==18 then -- if spr==10 and previous spr~=10
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
	is_fruit=true,
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
		-- screenwrap
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
		this.text="-- celeste mountain --#this memorial to those#perished on the climb"
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
		this.hitbox=rectangle(0,0,16,16)
	end,
	update=function(this)
		if not this.show and this.player_here() then
			sfx"38"
			sfx_timer,this.show,time_ticking=30,true,false
		end
	end,
	draw=function(this)
		-- spr(118+frames/5%3,this.x,this.y)
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
	-- generate and check berry id
	local id=x..":"..y..":"..lvl_id
	if type.is_fruit and collected[id] then
		return
	end

	local obj={
		type=type,
		collideable=true,
		-- collides=false,
		spr=tile,
		flip=vector(),
		x=x,
		y=y,
		hitbox=rectangle(0,0,8,8),
		spd=vector(0,0),
		rem=vector(0,0),
		layer=0,
		id=id,
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

	-- returns first object of type colliding with obj
	function obj.check(type,ox,oy)
		for other in all(objects) do
			if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
				return other
			end
		end
	end
	
	-- returns all objects of type colliding with obj
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

	function obj.move(ox,oy)
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
				for i=1,abs(amt) do
					if not obj.is_solid(d,step-d) then
						obj[axis]+=step
					else
						obj.spd[axis],obj.rem[axis]=0,0
						break
					end
				end
				movamt=obj[axis]-p -- save how many px moved to use later for solids
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
		return init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),29)
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

	-- clamp camera to level boundaries
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

	-- check for music trigger
	if music_switches[next_lvl] then
		music(music_switches[next_lvl],500,7)
	end

	load_level(next_lvl)
end

function load_level(id)
	has_dashed,has_key= false

	-- remove existing objects
	foreach(objects,destroy_object)

	-- reset camera speed
	cam_spdx,cam_spdy=0,0

	local diff_level=lvl_id~=id

	-- set level index
	lvl_id=id

	-- set level globals
	local tbl=split(levels[lvl_id])
	for i=1,4 do
		_ENV[split"lvl_x,lvl_y,lvl_w,lvl_h"[i]]=tbl[i]*16
	end
	lvl_title=tbl[5]
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8

	-- level title setup
	ui_timer=5

	-- reload map
	if diff_level then
		--reload()
		-- check for mapdata strings
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

-- replace mapdata with hex
function replace_mapdata(x,y,w,h,data)
	for i=1,#data,2 do
		mset(x+i\2%w,y+i\2\w,"0x"..sub(data,i,i+1))
	end
end
-->8
-- [metadata]

--@begin
-- level table
-- "x,y,w,h,title"
levels={
  "0,0,1,1,awakened",
  "4,1,3,1,dark chasm",
  "1,0,2,1,winding caverns",
  "4,0,2,1,looming stalagmites",
  "1,1,1,1,falling thorns",
  "4,2,2,1,wall of doom",
  "0,1,1,1,hellish overhang",
  "2,1,2,1,grid of ancient evil",
  "6,0,1,1,looming storm",
  "4,3,2,1,pillar of eternity",
  "3,0,1,1,cursed cube",
  "0,2,2,1.8125,rest"
}

-- mapdata string table
-- assigned levels will load from here instead of the map
mapdata={}

-- list of music switch triggers
-- assigned levels will start the tracks set here
music_switches={
}

--@end

-- tiles stack
-- assigned objects will spawn from tiles set here
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
76,flag
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

-- copy mapdata string to clipboard
function get_mapdata(x,y,w,h)
	local reserve=""
	for i=0,w*h-1 do
		reserve..=num2hex(mget(x+i%w,y+i\w))
	end
	printh(reserve,"@clip")
end

-- convert mapdata to memory data
function num2hex(v)
	return sub(tostr(v,true),5,6)
end
-->8
function perlin_init(res,seed)
 seed=seed or rnd()
 res/=0x0000.b505
 local function sig(t) return t^3*(t*(t*6-15)+10) end
 local function lerp(p0,p1,k) return (1-k)*p0+k*p1 end
 local function grad(x,y)
  x*=0xdead.beef y*=0xfeed.baba
  y^^=x<<16|y>>>16 x^^=y<<16|x>>>16
  return x*(seed^^0xdeaf.face)%1
 end
 local function perlin(x,y)
  x,y=(x-y)/res,(y+x)/res
  local x0,y0=x\1,y\1
  local function gdot(x_,y_)
   local a=grad(x_,y_)
   return cos(a)*(x-x_)+sin(a)*(y-y_)
  end
  local function xlerp(y_) return lerp(gdot(x0,y_),gdot(x0+1,y_),sig(x-x0)) end
  return lerp(xlerp(y0),xlerp(y0+1),sig(y-y0))
 end
 return perlin,grad
end

_tdict={}
foreach(split([[0b00000000,115
0b00000001,99
0b00000010,67
0b00000011,83
0b00000100,114
0b00000101,102
0b00000110,70
0b00000111,86
0b00001000,112
0b00001001,100
0b00001010,68
0b00001011,84
0b00001100,113
0b00001101,101
0b00001110,69
0b00001111,85
0b00010101,98
0b00010111,75
0b00011101,122
0b00011111,105
0b00101001,96
0b00101011,74
0b00101101,123
0b00101111,103
0b00111101,97
0b00111111,104
0b01000110,66
0b01000111,91
0b01001110,106
0b01001111,73
0b01010111,82
0b01011111,89
0b01101111,120
0b01111111,116
0b10001010,64
0b10001011,90
0b10001110,107
0b10001111,71
0b10011111,121
0b10101011,80
0b10101111,87
0b10111111,117
0b11001110,65
0b11001111,72
0b11011111,118
0b11101111,119
0b11111111,81]],"\n"),function(ln)
 local k,v=unpack(split(ln))
 _tdict[k]=v
end)

perlin,rnd2d=perlin_init(16,69)
function compute_tile(tx,ty,f)
 local nbs,tp=0,perlin(tx,ty)>0.5
 foreach(split([[1|0,-1
2|0,1
4|-1,0
8|1,0
16|0,-1+-1,0+-1,-1
32|0,-1+1,0+1,-1
64|0,1+-1,0+-1,1
128|0,1+1,0+1,1]],"\n"),function(ln)
  local v,checks=unpack(split(ln,"|"))
  for d in all(split(checks,"+")) do
   local dx,dy=unpack(split(d))
   if not fget(tile_at(tx+dx,ty+dy,81),f) or (perlin(tx+dx,ty+dy)>0.5)~=tp then
    return
   end
  end
  nbs+=v
 end)
 return _tdict[nbs]
end

function autotile(tx,ty)
 local t=tile_at(tx,ty)
 if fget(t,0) then
  t=compute_tile(tx,ty,0)
  -- deco
  if t==81 and rnd2d(tx,ty)<0.1 then
   t=88
  end
  tile_set(tx,ty,t)
 end
end

foreach(levels,function(lvl)
 lvl_x,lvl_y,lvl_w,lvl_h,_=unpack(split(lvl))
 lvl_x*=16
 lvl_y*=16
 lvl_w*=16
 lvl_h*=16
 for tx=0,lvl_w-1 do
  for ty=0,lvl_h-1 do
   autotile(tx,ty)
  end
 end
end)
__gfx__
00000000000000000000000001000100000000000000000000000000010001000010001000000000000000000007707770077700494949494949494949494949
0000000001000100010001000a000a000100010000000000000000000a000a0000a000a000100010000000000777777677777770222222222222222222222222
000000000a000a000a000a000aaaaaa00a000a0000a000a0010001000aa1aa1000aaaaaa00a000a0901090107766666667767777000420000000000000024000
000000000aaaaaa00aaaaaa00aa1aa100aaaaaa00aaaaaa00a000a000aaa11a000aa1aa100aaaaaa09a990a07677766676666677004200000000000000002400
000000000aa1aa100aa1aa10098a11900aa1aa1001aa1aa00aaaaaa0098a11900998a11909aa1aa109aaaaaa0000000000000000042000000000000000000240
00000000098a1190098a119000991100098a11900911a8900aaaaaa000999900099991100998a11909aa1aa10000000000000000420000000000000000000024
0000000000991100009911000900009009991100001199400981aa100099990090090000900991100098a1190000000000000000200000000000000000000002
00000000009009000090009000000000000009000000900004491140009009000000000000000000000991100000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000008888004999999449999994499909940300b0b067656765000000000000000000aaac00a00000ca
00000000000000000000000000040000000000000011110008888880911111199111411991140919003b33006770677000000000007777000a00c0a0c0000000
901090100000000000000000000950500aaaaaa0017171100878888091111119911191194940041902888820070007000000000007777770c00cc00a00000000
09a990a0000000000499994000090505a998888a019911100888888091111119949404190000004408988880070007000000000007777770acc77c0a00000000
09aaaaaa007000700050050000090505a988888a117771110888888091111119911409499400000008888980000000000000000007777770a0c77cca00000000
09aa1aa1007000700005500000095050aaaaaaaa117771110888888091111119911191199140049908898880000000000000000007777770a00cc00c00000000
0098a119067706770050050000040000a980088a0177711000888800911111199114111991404119028888200000000000000000007777000a0c00a00000000c
00099110567656760005500000000000a988888a099d9911000000004999999449999994440049940028820000000000000000000000000000caaa00ac00000a
077777700777777777777777777777705dddddddddddddddddddddd5077777700000000065555555000000005000000007777770000000000000000000000000
777777777777777777577777777777775dddddddddddddddddddddd5777777770000000067755500000000006700000077777777000777770000000000000000
775777777757577775d77557755757775dddddddddddddddddddddd5777775770000000006675000000000007777000077777777007766700000000000000000
75d5755775d5d7755dd57dd55dd5d5775dddddddddddddddddddddd575575d570000000000677000000770006600000077773377076777000000000000000000
5ddd5dd55dddd75ddddd5ddddddddd555dddddddddddddddddddddd55dd5ddd50000000000760000007777705000000077773377077660000777770000000000
55dddd555dddd5ddddddddddddddddd55dddddddddddddddddddddd55dddddd57000000000060000007666776700000073773337077770000777767007700000
5555d5555dddddddddddddddddddddd55dddddddddddddddddddddd55dddddd5777070000000000007766557777700007333bb37070000000700007707777770
055555505dddddddddddddddddddddd55dddddddddddddddddddddd55dddddd5777777700000000077665555660000000333bb30000000000000000000077777
5dddddd55dddddddddddddddddddddd50777777777777777777777705dddddd50000000000000000000000000000006603333330000000000000000000000000
5dddddd555dddddddddddddddddddd557757777775777557757777775dddddd50000000000000000000000000000777703b333300000000000ee0ee000000000
5dddddd555dddddddddddddddddd555575d577555d575dd55d7755775dddddd500000000000000000000000000000076033333300000000000eeeee000000000
5dddddd5555dddddddddddddddddd5555ddd55ddddd5dddddd57dd755dddddd5000000000000000000000000000000050333b33000000000000e8e0000000000
5dddddd555ddd5dd55ddd5dddd5dd5555dddddddddddddddddd5dd555dd5dd5500000000000000000000000000000066003333000000000000eeeee000000000
5dddddd5555d55d555dd5555d55d555555dddd555dddd55ddd55d55555d5d55500000000000000000000000000007777000440000000000000ee3ee000000000
5dddddd555555555555d555555555555555d555555d5555555555555555555550000000000000000000000000000007600044000000000000000b00000000000
5dddddd5055555555555555555555550055555555555555555555550055555500000000000000000000000000000000500999900000000000000b00000000000
d7777777777777777777777dd777777dd7777777777777777777777d766ddd67766ddd67766ddd67666ddddddddddd6600000000000000000000000000000000
777777777777777777777777777777777777777777777777777777777766d6677766d6677766d66766ddddd11d1dd66700aaaaaaaaaaaa000000000000000000
777766777777667777776677777766777777667777776677777766776666d6666666d6666666d66666ddd11111ddd6660a999999999999a00000000000000000
667666766676667666766676667666766676667666766676667666766661d1666661d1666661d166766dd1111ddddd66a99aaaaaaaaaa99a0000000000000000
66667666766676667666766666667666666676667666766676667666666ddd66666ddd66666ddd66666dddd1111ddd66a9aaaaaaaaaaaa9a0000000000000000
66116611661166116611666666666667661166116611661166116666661ddd16661ddd16661ddd1666dddd11111dd667a99999999999999a0000000000000000
66dddddddddddddddddd66666661166666dddddddddddddddddd6666dddddddddddddddddddddddd66ddd1ddddddd666a99999999999999a0000000000000000
766ddd1ddd11d1ddd1dd1166766dd166766dddd666ddddd666dd116666dddd1ddd11d1ddd1ddddd6766dddd666dddd66a99999999999999a0000000000000000
666ddddd11111111dddddd66666ddd66666ddd67766ddd67766ddd66766ddddd11111111dddddd67666ddd67766ddd66aaaaaaaaaaaaaaaa0000000000000000
66ddddd1111111111d1dd66766ddd66766ddd6677766d6677766d6677766ddd1111111111d1dd66766ddd6677766d667a49494a11a49494a0000000000000000
66ddd1111111111111ddd66666ddd66666ddd6666666d6666666d6666666d11111dd111111ddd66666ddd6666666d666a494a4a11a4a494a0000000000000000
766dd111111111111ddddd66766ddd66766dd1666661d1666661dd666661d11111dd11d11dddd166766dd1666661dd66a49444aaaa44494a0000000000000000
666dddd111111111111ddd66666ddd66666ddd66666ddd66666ddd66666dddd111111111111ddd66666ddd66666ddd66a49999aaaa99994a0000000000000000
66dddd1111111111111dd66766ddd66766dddd16661ddd16661dd667661ddd111111d111111ddd1666dddd16661dd667a49444999944494a0000000000000000
66ddd1d1111111111dddd66666ddd66666ddddddddddddddddddd666ddddd1d1111111111ddddddd66ddddddddddd666a494a444444a494a0000000000000000
766ddddd11111111dddddd66766ddd66766dddd666ddddd666dddd6666dddddd11111111ddddddd6766ddd1dd1dddd66a49499999999494a0000000000000000
666ddddd111111111dd1dd66666ddd66666ddd67766ddd67766ddd66766ddddd111111111dd1dd67777777777777777700000000000000000000000000000000
66dddd111111111111ddd66766ddd66766ddd6677766d6677766d6677766dd111111111111ddd667777777777777777700000000000000000000000000000000
66ddddd1111111111dddd66666ddd66666ddd6666666d6666666d6666666ddd1111111111dddd666777766777777667700000000000000000000000000000000
766dd1d111111111dd1ddd66766ddd66766dd1666661d1666661dd666661d1d111111111dd1dd166667666766676667600000000000000000000000000000000
666ddddd111111111ddddd66666ddd66666ddd66666ddd66666ddd66666ddddd111111111ddddd66766676667666766600000000000000000000000000000000
66ddddd11d1dd1d11ddddd67666dd66766dddd16661ddd16661ddd67661dddd11d1dd1d11ddddd16661166116611661100000000000000000000000000000000
6666ddddddddddddddddd666666666666666ddddddddddddddddd666dddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000
d6666666666666666666666dd666666dd6666666666666666666666d66ddddd666ddddd666ddddd6ddd1ddd666ddd1dd00000000000000000000000000000000
d7777777777777777777777dd777777d11111111111111111ddddd67766dddd1766ddddd1dd1dd671ddddd67766dddd100000000000000000000000000000000
7777777777777777777777777777777711111111111111111dddd6677766dd117766dd1111ddd66711ddd6677766dd1100000000000000000000000000000000
77776677777766777777667777776677111111111111111111ddd6666666dddd6666ddd11dddd6661dddd6666666ddd100000000000000000000000000000000
6676667666766676667666767676667611111111111111111dddd1666661dddd6661d1d1dd1dd16611ddd1666661dd1d00000000000000000000000000000000
6666766676667666766676666661166611111d1111d11d111ddddd66666dddd1666ddddd1ddddd661d1ddd66666dddd100000000000000000000000000000000
66116611661166116611666666dddd661111d1d11d1d111111dddd16661ddd11661dddd11ddddd161ddddd16661ddddd00000000000000000000000000000000
66dddddddddddddddddd6666666dd6661d1ddddddddddd11111d1dddddddd1d1dddddddddddddddddddddddddddddddd00000000000000000000000000000000
d6666666666666666666666dd666666d11ddddd666ddd11111d1ddd1dd11d111d1ddddd666dddd1d666666666666666600000000000000000000000000000000
52522323232323232352525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
02020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000
52330000000000000013235252525252525252525252525252525252525252520000770000000000000000000000000000000000000000000000000000000000
02020292000000000002020202020202020202020202020202000000000000000000777700000000000000000000000000000000000000000000000000000000
62b20000000000000000001352525252525252525252525252525252525252520000777777000000000000000000000000000000000000000000000000000000
020200000000000000920002020202b1000000020202020202d00000000000000000777777770000000000000000000000000000000000000000000000000000
33b20000000000000000000042525252525252525252525252525252525252520000077777007000000000000000000000000000000000000000000000000000
0200000000000000000000b30202b200000000000202020202000000000000000000077770000770000000000000000000000000000000000000000000000000
00000000001111000000000042525252525252525252525252525252525252520000007770000007000000000000000000000000000000000000777777700000
0200000000001111000000b30202b200000000000202020202000000000000000000007770000000700000000000000000000000000000000077007777700000
00000000001232000000000042525252525252525252525252525252525252520000000770000000070000000000000000000000000000007700007777700000
0000000000b30202b20000b30202b200000061000202020202000000000000000000000770000000007000000000000000000000000000770000007777700000
00000000004262000000001142525252525252525252525252525252525252520000000070000000000700000000000000000000000077000000007777000000
0000000000b30202b20000b30202b200001100000202020202000000000000000000000070000000000077777777777000000000007700000000007777000000
00100000004262000000001252525252525252525252525252525252525252520000000007000000000000000000000777770000770000000000007770000000
0000000000b302b2000000b30202b200000211110202020202000000000000000000000007000000000000000000000000007777000000000000007700000000
22223200a24262000000004252525252525252525252525252525252525252520000000000700000000000000000000000000000000000000000007000000000
0000000000b302b2000000110202b2000002020202020202b1000000000000000000000000700000000000000000000000000000000000000000070000000000
52525222225262000000004252525252525252525252525252525252525252520000000000077000000000000000000000000000000000000000700000000000
00000000001102b20000b3020202b20000b1b1b1b102020200000000000000000000000000070000000000000000000000000000000000000007000000000000
52525252525233000000004252525252525252525252525252525252525252520000000000700000000000000000000000000000000000000070000000000000
00000000000202b20000b3020202b20000000000000000b100000000000000000000000000700000000000000000000000000000000000007700000000000000
525252525262b1000000004252525252525252525252525252525252525252520000000007000000077000000000000000000000000000070000000000000000
00000000000202000000b30202920000000000000000000000000000000000000000000007000000707700000000000077000000000000700000000000000000
52525252526200000000114252525252525252525252525252525252525252520000000070000000777700000000000707700000000000700000000000000000
00000000000202000000000000000000000000000000000000000000000000000000000070000000777700000000000777700000000000700000000000000000
52525252526200000000125252525252525252525252525252525252522323230000000700000000077000000000000777700000000000700000000000000000
00000000000202000000000000000000000000006100000000000000000000000000000700000000000000000000000077000000000000070000000000000000
52525252526200000000425252232352525252525252525252525223330000000000007000000000000000000000000000000000000000070000000000000000
10000000000202000000001100000011000000000000000000000000000000000000007000000000000000777000000000000000000000070000000000000000
52525252526200000000425262000013232323232323232323233300000000000000007000000000000000077000000000000000000000070000000000000000
02000000000202000000000200000002000000000000000000000000000000000000007000000000000000000000000000000000000000007000000000000000
52525252523300000000425262820000000000000000000000000000000000000000007000000000000000000000000000000000000000007000000000000000
02020202020202020202020202020202000000000000000002020202000000000000007000000000000000000000000000000000000000007000000000000000
52525252330000000011425252222222222222222222222222222222222222220000007000000000000000777770000000000000000000007000000000000000
b1b1b1b1b1b102020202020202029200000000000000000000020202000000000000007000000000000007777777000000000000000000000700000000000000
52525262920000001112525252525252525252525252525252525252525252520000000700000000000007777777000000000000000000000700000000000000
1000000000b302020202020202000000000000000000000000020202000000000000000700000000000007777777000000000000000000000700000000000000
52525233000000001252525252525252525252525252525252525252525252520000000700000000000007777777000000000000000000000700000000000000
0211111100b302020202020202000000000000000000000000020202000000000000000070000000000000777770000000000000000000000070000000000000
52526292000000004252525252525252525252525252525252525252525252520000000007000000000000000000000000000000000000000070000000000000
0202020200b302020202020200000000000000000000000000020202000000000000000007000000000000000000000000000000000000000070000000000000
52526200000000004252525252525252525252522323232323525252525252520000000070000000000000000000000000000000000000000070000000000000
02029200000002020202020200000000000000001100000000020202000000000000000070000000000000000000000000000000000000000070000000000000
5252620000000000425252525252525252525233000000009213525252525252000000070000000aa00000000000000000000000000000000007000000000000
02000000000002020202020200000000000000b302b2000000b1b1b10000000000000007000000aaa00000000000000000000000000000000007000000000000
52526200000000001352525252525252525262920000000000001352525252520000000000000aaaa00000000000000000000000000000000000000000000000
02000000000002020202020200000000000000b302b200000000000000000000000077777700aaaaa07777700077777000777770077000770770007700000000
5252620000000000004252525252525252523300000000000000004252525252000077777770aaaa077777770777777707777777077000770770007700000000
020000000000020202020202b2000000000000b30200000000111111000000000000770007700aa0077000770770007707700077077000770770007700000000
52523300000000000013232323232323233300000000c4d400000013525252520000aaaaaaa00aaa0aa000000aa000aa0aa000000aaaaaaa0aa000aa00000000
020011111111020200000002b2000000000000b302000000b3020202a20000000000aaaaaa0000aa0aa000aa0aa000aa0aa000aa0aa000aa0aa000aa00000000
52330000000000000000000000000000000000000000c5d5000000a2425252520000aa00000044400aaaaaaa0aaaaaaa0aaaaaaa0aa000aa0aaaaaaa00000000
020002020202020200610002b2000000000000b302000000b3020202020202020000aa000000440000aaaaa000aaaaa000aaaaa00aa000aa00aaaaa000000000
62000000122232000000001222222222222222222222222222222222525252520000000000000000000000000000000000000000000000000000000000000000
020000020202000000000000000000000000000002000000b3020202020202020000000000000000000000000000000000000000000000000000000000000000
23535353232323535353535252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
020000000000000000000000000000000000000002310000b3020202020202020000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020000000000000000000000000000000000000002b20000b3020202020202020000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
023100000000111111111100000000000000000002b20000b3020202020202020000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0231000000b3020202020200000000000000000002b20000b3020202020202020000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000777770070000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000777700007700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000077700000070000000000000000000000000000000000007777777000000000000000000000000000000000
00000000000000000000000000000000000000000077700000007000000000000000000000000000000000770077777000000000000000000000000000000000
00000000000000000000000000000000000000000007700000000700000000000000000000000000000077000077777000000000000000000000000000000000
00000000000000000000000000000000000000000007700000000070000000000000000000000000007700000077777000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000007000000000000000000000000770000000077770000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000000777777777770000000000077000000000077770000000000000000000000000000000000
00000000000000000000000000000000000000000000070000000000000000000007777700007700000000000077700000000000000000000000000000000000
00000000000000000000000000000000000000000000070000000000000000000000000077770000000000000077000000000000000000000000000000000000
00000000000000000000000000000000000000000000007000000000000000000000000000000000000000000070000000000000000000000000000000000000
00000000000000000000000000000000000000000000007000000000000000000000000000000000000000000700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000770000000000000000000000000000000000000007000000000000000000000006600000000000000
00000000000000000000000000000000000000000000000700000000000000000000000000000000000000070000000000000000000000006600000000000000
00000000000000000000000000000000007000000000007000000000000000000000000000000000006600700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007000000000000000000000000000000000006677000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000070000000770000000000000000000000000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000070000007077000000000000770000000000007000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000007777000000000007077000000000007000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000007777000000000007777000000000007000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000000770000000000007777000000000007000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000000000000000000000770000000000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000000000000000000000000000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000007770000000000000000000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000000770000000000000000000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000000000000000000000000000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000000000000000077000000000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000000000000000077000000000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000007777700000000000000000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000077777770000000000000000000007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000000000077777770000000000000000000007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000000000077777770000000000000000000007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000000000077777770000000000000000000007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000000007777700000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000070000000000000000000000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000070000000000000000000000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000000000000000000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000000000000000000000000000000000000700000000000000000000000000000000000000000
000000000000000000000000000000000000000000070000000aa000000000000000000000000000000000070000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000aaa000000000000000000000000000000000070000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000077777700aaaaa077777000777770007777700770007707700077000000000000000000006000000000000000
000000000000000000000000060000000000000077777770aaaa0777777707777777077777770770007707700077000000000000000000000000000000000000
0000000000000000000000000000000000000000770007700aa00770007707700077077000770770007707700077000000000000000000000000000000000000
0000000000000000000000000000000000000000aaaaaaa00aaa0aa000000aa000aa0aa000000aaaaaaa0aa000aa000000000000000000000000000000000000
0000000000000000000000000000000000000000aaaaaa0000aa0aa000aa0aa000aa0aa000aa0aa000aa0aa000aa000000000000000000000000000000000000
0000000000000000000000000000000000000000aa00000044400aaaaaaa0aaaaaaa0aaaaaaa0aa000aa0aaaaaaa000000000000000000000000000000000000
0000000000000000000000000000000000000000aa000000440000aaaaa000aaaaa000aaaaa00aa000aa00aaaaa0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077000000000000000000000000060000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000ddddd7000000ddddd00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000dd000dd00d00dd0d0dd0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000dd0d0dd0ddd0ddd0ddd0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000dd000dd00d60dd0d0dd0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000ddddd0000000ddddd00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000ddd0ddd0dd00dd00d0d00000ddd0d0d00dd0ddd00dd00dd0dd0000000000000000000000000000000000000000
00000000000000000000000000000000000000ddd0d0d0d0d0d0d0d0d000000d00d0d0d0d0d0d0d000d0d0d0d000000000000000000000000000000000000000
00000000000000000000000000000000000000d0d0ddd0d0d0d0d0ddd000000d00ddd0d0d0dd00ddd0d0d0d0d000000000000000000000000000000000000000
00000000000000000000000000000000000000d0d0d0d0d0d0d0d000d000000d00d0d0d0d0d0d000d0d0d0d0d000000000000000000000000000000000000000
00000000000000000000000000000000000000d0d0d0d0ddd0ddd0ddd000000d00d0d0dd00d0d0dd00dd00d0d000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000dd000dd0ddd0d0000000ddd0ddd0ddd0ddd0d0d000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000d0d0d0d0d000d0000000d0d0d000d0d0d0d0d6d000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000d0d0d0d0dd00d0000000dd00dd00dd00dd00ddd000000000000000000000000000000000000000000000
00000000000000000000000007000000000000000000d0d0d0d0d000d0000000d0d0d000d0d0d0d000d000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000d0d0dd00ddd0ddd00000ddd0ddd0d0d0d0d0ddd000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000ddd0ddd0ddd0ddd000000d000000ddd0ddd0ddd0ddd0d0d0ddd0ddd0ddd0ddd0ddd0ddd00000000000000000000000000000
0000000000000000000000000000ddd0d000d000d0d000000d000000d0d0d0000d000d00d0d0d000d0d0d0000d00d0d0d0d00000000000000000000000000000
0000000000000000000000000000d0d0dd00dd00ddd000000d000000ddd0dd000d000d00ddd0dd00ddd0dd000d00dd00ddd00000000000000000000000000000
0000000000000000000000000000d0d0d000d000d00000000d000000d000d0000d000d00d0d0d000d000d0000d00d0d0d0d00000000000000000000000000000
0000000000000000000000000000d0d0ddd0ddd0d00000000d000000d000ddd00d000d00d0d0ddd0d000ddd00d00d0d0d0d00000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000ddd0d0d0ddd0d0d0ddd0ddd0dd0000000d0000000dd00dd0dd00ddd0dd000dd0ddd0ddd0ddd0ddd0000000000000000000000000
000000000000000000000000d0d0d0d0d0d0d0d0d0d0d000d0d000000d000000d000d0d0d0d0d000d0d0d000d0d000d007000d00000000000000000000000000
000000000000000000000000dd00d0d0dd00ddd0dd00dd00d0d000000d000000d000d0d0d0d0dd00d0d0d000ddd00d000d000d00600000000000000000000000
000000000000000000000000d0d0d0d0d0d000d0d0d0d000d0d000000d000000d0d0d0d0d0d0d000d0d0d0d0d0d0d0000d000d00000000000000000000000000
000000000000000000000000d0d00dd0ddd0ddd0d0d0ddd0ddd000000d000000ddd0dd00d0d0ddd0d0d0ddd0d0d0ddd0ddd00d00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600
00007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000008080800020000000200000000000200000000030303030303030304040402020000000303030303030303040404020202020203030303030303030303030302020000030303030303030307030303020200000303030303030307070303030000000003030303030303030303030300000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
25253232323300000000313232322525252525252532323232323232323232322525252525252525253300003b24252525260000000000313232323232322525323232322525253232323225253232323232323232252525253300000031322500003b2525252525252525252525252500000000000000000000000000000000
25330000000000000000000000293132252525253300000000000000000000002425252532323232332900003b31252525262800000000000000000000293125000000003125262900000024260000000000000000242525332900000000003100003b252b00002500003b252b00000000000000000000000000000000000000
2629000000000000000000000000000025323233290000000000000000000000242525260029000000000000003b312525252223280000000000000000001b240001000000242600000000243300000000110016002425261b000000000000290000001b000000250000001b0000000000000000000000000000000000000000
33000000000000000000000016000000262800000000000000000000212300002425323300000011111111000000002425323232353535230000000000000031222300000024260000000f371b000000112700000031252600000000110000000000001100000025000000110000000000000000000000000000000000000000
000000000000000000000000000000002523280000000000000000002426000031330000000000212222231100000024262b000000002930000000111100001b25330000002433000000001b0000000021260000001b3133000000112700000000003b252b00002500003b252b00000000000000000000000000000000000000
000000000000000000000000000000002525222223000000000000112426000000000000000000313225252300000024262b00111100003000000021230000002600000000371b0000000000000000002426000000001b1b00000021260000000b00001100000b1b000000110b00000000000000000000000000000000000000
000000160000000000000000000000002525253233000000000000212526000000000000000000002924252600000024262b0021230000302b0000242600000026000000001b00000000000000000000313300000000000000000024260016000000002511111111111111250000001100000000000000000000000000000000
000000000000000000000000000000002532330000000000000000242526000000000000000000000024252600000024262b0024262801302b00002433000000260000000000000000000000000000000000000000000000000000242600000000000025252525252525252500003b2500000000000000000000000000000000
000000000000000000000000000000002600000000000000000011242526280000000021222300000024252600002a2426000024323535332b003b302b0000002611111100000000111111000000000000001111111111000000002426110000111111251b1b1b1b1b1b1b250000001b00000000000000000000000000000000
000000000000000100000000000000003300000000000000003b2125252522222300002425260000003132330d0e0f24260000300000000000003b302b00000025222223111111112122231100000000111121222222231111000024252311112525252500000000000000250000000000000000000000000000000000000000
000000000000005c5d000000000000000000000000000000003b2425252525252600002425260000001b1b1b0000002426003b300000111100003b302b00000025252525222222222525252300001111212225252525252223111124252522221b1b1b2500001111110000251111000000000000000000000000000000000000
000000000000212222230000000000000000000000000000003b2425252525252600002425260000000000000000002426163b302b0021232b0000302b000000252525252525252525252526111121222525252525252525252222252525252500010025000025252500002525252b0000000000000000000000000000000000
000000002122252525252223000000000000000000000000003b2425252525252600002425260000001111110000002426003b372b0024262b0000300016000025252525252525252525252522222525252525252525252525252525252525250017002500000025000000251b1b000000000000000000000000000000000000
2223002a2425252525252526000000210000010000000000003b2425252525252600002425261111112122230000112426000000000024332b1600370000000025252525252525252525252525252525252525252525252525252525252525250000001b000000250000001b0000000000000000000000000000000000000000
25252222252525252525252522222225230d0e0f21230000002125252525252526111124252522222225252611112125260000000000302b000000000000000025252525252525252525252525252525252525252525252525252525252525250000000000000025000000000000000000000000000000000000000000000000
252525252525252525252525252525252600000024252300002425252525252525222225252525252525252522222525260000000000302b0000000000000000252525252525252525252525252525252525252525252525252525252525252500000c000000001b0c00000000000c0000000000000000000000000000000000
25252525252525252525252500002525252525252525000000000011003b2525252532323225252525262425252525252525252525252525252525262b003b2425252525252525252525252525252525252525252525252525252525252525252525252525252525000000252525252500000000000000000000000000000000
25002900000000000025252500001b25252525251b1b000000003b252b003b25252600000031323232332432323232323232322525252525252525262b003b242525252525251b00000000000000000000000000001b252525251b0000292525252525252525251b000000252525252500000000000000000000000000000000
000000000000000013252525000000252525251b000000000000001b00003b252533000000000000002930000000000000003b2425253232323232332b003b311b2525250000000000000000000000000000000000001b2525250000000000252525252525252500000000252525252500000000000000000000000000000000
00000011000000111125251b0000001b25252500001600000011000000003b252600000000000000000030001600000000003b24252600290000000000000000000025250000000000000000000000000000000000000025251b00000000002525252525252525000000001b2900252500000000000000000000000000000000
00003b252b003b25252525000000000025252500000000003b252b00000000002613000000000000000030000000111100003b312526000000000000000000000000001b000000000000000000000000000000000000002525000000000e0f252525252525251b000000000000001b2500000000000000000000000000000000
00003b252b003b252529000000002c002525251111000000001b00000000000033130000000011000000302b003b21362b00003b2426110000001111111111110000000000000000000000000000002a283e000000000025250000000000002525252525290000000000002c2c2c002500000000000000000000000000000000
00003b252b003b252b00000000003c2a2525252525110000000000001600000000000000000027000000372b003b30290000003b2426202b163b343536343535000000000000000000000000000025252525250000000025250d0e0000000000252525000000000000003e3c3c3c3e2500000000000000000000000000000000
00003b252b013b252b0000002a2825252525252525252b000000000000001100000000000000300000001b00003b37000000003b242600000000000000000000000000000000000000000000000025252525250000000025250000000000000000252500000000000e0f25252525252500000000000000000000000000000000
00003b25252525252b003b252525252525251b1b1b1b000000001100003b252b00000000002a300000000000000000000000003b24260000000000000000000000000000000000000000000000002525252525000000000000000000000000000025250000000000000025252525252500000000000000000000000000000000
00003b25252525252b003b25252525252525000000000000003b252b00001b00000000000021261111111111110000000000003b242611111111111100000011002c0000000000000000000000000025252525000000000000000000000000000025250000000000000025252525252500000000000000000000000000000000
00003b252b003b252b000000000025251b1b00000011000000001b0000000000000000000024252235353535360000000000003b24323535353535362b163b34283c000000002c000000000000000025252500000000000000000000000000000000250000000000000025252525252500000000000000000000000000000000
00003b252b163b252b00000000002525000000003b252b000000000000000000000000000024252628000000000000000000003b30000000002900000000000025250001003e3c2a2800000000000025252500000000000000000000000000000000000000000000000025252525252500000000000000000000000000000000
00003b252b003b252b0000000013252500000000001b00000016000000110000280100000031252523130000000000000000003b37000000000000000000000025250d0e0f252525250000000000002525250000000000000000000000000000000000000000000000001b1b2525252500000000000000000000000000000000
00003b252b003b252b000000000025250001000000000011000000003b252b0022230d00000024253313000000000000000000001b000000000000000000000025250000002525252500000000000025252500000000000000000000000000000000000000000000000000002525250000000000000000000000000000000000
0000001b0000001b00000000001125252525250000003b252b000000001b0000252600000000242629000000000000000000000000000000000000000016000025250000000025252500000000000025252500000000000000000000000000000000000000000000000000002525000000000000000000000000000000000000
00000000000000000000000000252525252525000000001b0000000000000000252600000000242600000000000000000000000000000000000000000000000025000000000025250000000000000025252500000000000000000000000000000000000000000000000000002525000000000000000000000000000000000000
__sfx__
0102000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000236502b650256503525029250212501c25018240152401323012220322002d2002820024200212001d2001a20016200112000e2000b20007200052000320010200102000020000200002000020000200
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0b0c00200c0530000024625010000c0530c60024625000000c0530000024625070000c0530000024625000000c0530000024625010000c0530c60024625000000c0530000024625070000c053000002462500000
010c00000015000100001501d00024645180000c1500c150001501b0000015022000246451f00002150021550315003100031501300024645180000f1500f15003150220002464413000306351b0000a1550c155
110c0000243502435024322243120730007300033000f300273502735029350293502b3502b3502735027350293502935029322293120c3000c3002635026350163000f300273502735005300033002935029350
110c0000243502635126322263122735027350263502635026320263101f3501f3501f3221f3121f3002730030555293002930029300305550c30026300263002e5552b55526555275552e5552b5552655527555
110c0000293502b3512b3222b3120730007300033000f300273002730029300293002b3002b300273002730030555293002930029300305550c30026300263002e5552b55529555275552e5552b5552955527555
01030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
350c00000003300033000330003300033000330004300043000430004300043000430005300053000530005300053000630006300063000730007300073000630006300063000630005300053000430004300043
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
051400000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163401d36022370233712336023350233422332213300133001830018300133001330016300163001d3001d300
051400000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163402236024370243712436024350243422432213300133001830018300133001330016300163001d3001d300
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
__music__
01 0a0b4344
00 0a0b4344
00 0a0b4344
00 0a0b4344
00 0a0b0c44
00 0a0b0e44
00 0a0b0c44
02 0a0b0d44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 11424344

