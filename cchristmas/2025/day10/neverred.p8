pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- neverred V0.2 BY PETTHEPETRA
-- THANK YOU FOR PLAYING♥

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

-- global tables
objects,collected={},{}
-- global timers
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,0

-- metroidvania
spawn_pos=vector(60,-8)
spawn_spd=vector(0,4)
spawn_diving=true

abilities={
	jump=false,
	walljump=false,
	dash=false,
	dive=false,
	grapple=false,
}

pickups={
	[123]="jump",
	[124]="walljump",
	[125]="dash",
	[126]="dive",
	[127]="grapple",
}

-- [entry point]

function _init()
	frames,start_game_flash=0,0
	begin_game()
end

function begin_game()
	max_djump=1
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,1
	load_room(3,1)
	region=0
	ui_timer=0
	music(30,0,7)
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
	return mget(room.x*16+x,room.y*16+y)
end

function spikes_at(x1,y1,x2,y2,xspd,yspd)
	for i=max(0,x1\8),min(127,x2/8) do
		for j=max(0,y1\8),min(127,y2/8) do
			if({[17]=y2%8>=6 and yspd>=0,
			[27]=y1%8<=2 and yspd<=0,
			[43]=x1%8<=2 and xspd<=0,
			[59]=x2%8>=6 and xspd>=0})[tile_at(i,j)] then
				return true
			end
		end
	end
end

function pal_all(col)
	for i=0,15 do
		pal(i,col)
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
			music(regions[region].music,4000,7)
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
		delay_restart-=1
		if delay_restart==0 then
			load_room(room.x,room.y)
		end
	end

	-- update each object
	foreach(objects,function(obj)
		obj.move(obj.spd.x,obj.spd.y,0);
		(obj.type.update or stat)(obj)
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

		-- particles
		foreach(particles,draw_particle)

		return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)

	if room.y==0 and room.x>2 then
		-- bg clouds effect
		foreach(clouds, function(c)
			c.x += c.spd
			rectfill(c.x,c.y,c.x+c.w,c.y+4+(1-c.w/64)*12,13)
			if c.x > 128 then
				c.x = -c.w
				c.y=rnd(128-8)
			end
		end)
	else
		camera(room.x*32,0)
		-- columns
		fillp(0b0000100000000010.1)
		local x=0
		while x < 1024 do
			local tx = x * 8
			rectfill(tx-2, 0, tx + (x % 2) * 8 + 6, 128, 13)
			x += 1 + x % 7
		end
		fillp()
		camera(0,0)
	end
	
	-- death plane
	if room.y>2 then
		rectfill(0,126,127,127,0)
		local px=-1
		repeat
			line(px,125,px+2,125,0)
			pset(px+1,124,0)
			px+=4
		until px>=128
	end

	-- draw bg terrain
	--map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4)
	
	-- set draw layering
	local pre_draw,mid_draw,post_draw={},{},{}
	foreach(objects,function(obj)
		local draw_grp=obj.layer<0 and pre_draw or obj.layer==0 and mid_draw or post_draw
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

	-- draw deco
	map(room.x*16,room.y*16,0,0,16,16,0x2)

	-- draw mg objects
	foreach(mid_draw,draw_object)
	
	-- draw terrain
	map(room.x*16,room.y*16,0,0,16,16,0x4)
	
	-- draw fg objects
	foreach(post_draw,draw_object)
	
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
	
	if ui_timer>0 then
		local rg=regions[region]
		print_outline(rg.title,2,113,7,13)
		print_outline(rg.name,2,121,7,13)
		ui_timer-=1
	end
	
	if region==0 then
		pal(13,1,1)
	else
		pal(13,regions[region].color,1)
	end
	--pal(0,129,1)
end

function print_outline(text,x,y,col,l_col)
  -- print text with outline
  for _x=-1,1 do
    for _y=-1,1 do
      print(text,x+_x,y+_y,l_col)
    end
  end
  print(text,x,y,col)
end

function spr_outline(s,x,y,l_col)
  -- draw sprite with outline
  pal_all(l_col)
  for _x=-1,1 do
    for _y=-1,1 do
      spr(s,x+_x,y+_y)
    end
  end
  pal()
  spr(s,x,y)
end

function draw_particle(p)
	p.x += p.spd
	p.y += sin(p.off)
	p.off+= min(0.05,p.spd/32)
	rectfill(p.x,p.y,p.x+p.s,p.y+p.s,p.c)
	if p.x>128+4 then 
		p.x=-4
		p.y=rnd(128)
	end
end

function draw_time(x,y)
	rectfill(x,y,x+44,y+6,0)
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,7
end

function draw_ui()
	--rectfill(24,58,104,70,0)
	--?room.x.." "..room.y,48,62,7
	--local title=lvl_title or lvl_id.."00 m"
	--?title,64-#title*2,62,7
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
		this.spr=9
		this.spr_off=0
		this.collides=true
		create_hair(this)
		
		-- intro check
		if seconds_f+minutes~=0 then
			this.init_smoke()
		end
		
		-- accidental buffer check
		if btn(🅾️) then this.p_jump=true end
		if btn(❎) then this.p_dash=true end
		
		this.spd=vector(spawn_spd.x,spawn_spd.y)
		
		if spawn_diving then
			this.diving=true
			-- to avoid softlock
			spawn_diving=false
			if spawn_spd.y>2 then
				spawn_spd.y=2
			end
		end
		
		this.layer=-1
	end,
	update=function(this)
		if pause_player then
			return
		end

		-- horizontal input
		local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0
		
		-- vertical input
		local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0
				
		-- spike collision / bottom death
		if (spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) and not this.diving) or this.check(icicle,0,0) or (this.y>128 and room.y>=3) then
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
			this.tumble=false
			
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
			this.spd=vector(appr(this.spd.x,this.dash_target,this.dash_accel),0)
		elseif this.diving then
			this.spd.y=appr(this.spd.y,8,0.2)
			if on_ground then
				this.diving=false
				psfx"5"
			end
		elseif this.hook then
			this.spd.x=0
			
			-- touch hook or hook oob
			if this.y<=this.hook.y or (this.hook.y<-128 or this.hook.y>256) then
				release_hook(this)
				
				if this.spd.y<-3 and not this.is_solid(0,-1) then
					-- cap jumpthrough launch
					this.spd.y=-3
				else
					-- hit head
					psfx"5"
				end
			elseif this.hook.hooked then
				this.spd.y=appr(this.spd.y,-4,1)
				if this.jbuffer>0 then
					-- jump out of hook
					psfx"63"
					this.jbuffer=0
					this.grace=0
					this.spd.y=-2
					this.spd.x=h_input*2
					this.init_smoke(0,4)
					
					release_hook(this)
				end
			end
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
				if abilities.jump and this.grace>0 then
					-- normal jump
					psfx"1"
					this.jbuffer=0
					this.grace=0
					this.spd.y=-2
					this.init_smoke(0,4)
				elseif abilities.walljump then
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
					if wall_dir~=0 and this.y>-8 then
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

			-- action key pressed
			if dash and not this.tumble then
				if h_input~=0 then
					-- dash
					if this.djump>0 and abilities.dash then
						this.init_smoke()
						this.djump-=1
						this.dash_time=4
						has_dashed=true
						this.dash_effect_time=10
						-- calculate dash speeds
						this.spd=vector(h_input*5,0)
						-- effects
						psfx"3"
						freeze=2
						-- dash target speeds and accels
						this.dash_target=2*sign(this.spd.x)
						this.dash_accel=1.5
					elseif this.djump<=0 then
						-- failed dash smoke
						psfx"9"
						this.init_smoke()
					end
				elseif v_input==1 and abilities.dive then
					freeze=2
					psfx"35"
					this.spd.x=0
					this.spd.y=4
					this.diving=true
					this.init_smoke()
				elseif v_input==-1 and abilities.grapple then
					this.hook=init_object(hook,this.x,this.y)
					psfx(58)
					this.spd.x=0
					this.spd.y=0
				end
			end
		end
		
		--room borders and transitions
 	local x,y=get_room(this)
  if (x~=room.x or y~=room.y) and (x>=0 and x<=7) and (y>=0 and y<=3) then
   -- set spawn position
   pos_x,pos_y=raw_pos(this)
   spawn_pos=vector((pos_x+4)%128-4,(pos_y+4)%128-4)
   
   if y<room.y then
   	spawn_spd=vector(this.spd.x,-2)
   	sfx_timer=12
   	sfx(4)
   else
   	spawn_spd=vector(this.spd.x,this.spd.y)
   end
   
   if this.diving then
   	spawn_diving=true
   else
   	spawn_diving=false
   end
   
   load_room(x,y)
  end
		
		-- animation
		this.spr_off+=0.25
		this.spr = this.tumble and 107+(this.spr_off%2)*2 or
		this.hook and (on_ground and 7 or this.hook.hooked and 12 or 8) or
		not on_ground and (this.is_solid(h_input,0) and 5 or this.spd.y<0 and 8 or 9) or	-- wall slide or mid air
		btn(⬇️) and 6 or -- crouch
		btn(⬆️) and 7 or -- look up
		this.spd.x~=0 and h_input~=0 and 1+this.spr_off%4 or
		btn(❎) and 10+this.spr_off%2 or 1 -- walk or stand
		
		-- was on the ground
		this.was_on_ground=on_ground
	end,

	draw=function(this)
		-- draw player hair and sprite
		set_hair_color(this.djump)
		
		if this.hook then
			line(this.x+3,this.y,this.hook.x+3,this.hook.y,7)
		end
		
		if this.diving then
			pal_all(7)
		end
		
		draw_hair(this)
		draw_obj_sprite(this)
		if this.spr>=10 then
			pset(this.x+(this.flip.x and 8 or -1),this.y+2,8)
		end
		pal()
	end
}

function release_hook(obj)
	if obj.hook then
		destroy_object(obj.hook)
		obj.hook=nil
		obj.tumble=true
	end
end

function create_hair(obj)
	obj.hair={}
	for i=1,5 do
		add(obj.hair,vector(obj.x,obj.y))
	end
end

function set_hair_color(djump)
	pal(14,djump==1 and 14 or 12)
	pal(2,djump==1 and 2 or 1)
end

function draw_hair(obj)
	local last=vector(obj.x+(obj.flip.x and 5 or 3),obj.y+(btn(⬇️) and 4 or 3))
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x,h.y+0.5,mid(4-i,1,2),2)
		circfill(h.x,h.y,mid(4-i,1,2),14)
		
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
-->8
-- [objects]

spring={
	init=function(this)
		this.delta=0
		this.dir=this.spr==18 and 0 or this.is_solid(-1,0) and 1 or -1
		this.show=true
		this.layer=-2
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
			hit.diving=false
			release_hook(hit)
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
					psfx"15"
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

function check_fruit(this)
	local hit=this.player_here()
	if hit then
		hit.djump=max_djump
		sfx_timer=20
		sfx"13"
		collected[this.id]=true
		init_object(lifeup,this.x,this.y)
		destroy_object(this)
		fruit_count+=1
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
	is_fruit=true,
	update=function(this)
		this.spr=flr(53.5+sin(frames/30))
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
		this.layer=-2
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

message={
	init=function(this)
		this.text="-- everblue ridge --#a memorial in rememberance#of those we lost in the snow"
		this.hitbox.x+=4
		this.layer=4
	end,
	draw=function(this)
		sspr(48,32,16,16,this.x,this.y-8)
		if this.player_here() then
			for i,s in ipairs(split(this.text,"#")) do
				rectfill(5,7*i-1,122,7*i+7,7)
				?s,64-#s*2,7*i+1,0
			end
		end
	end
}

big_chest={
	init=function(this)
		this.state=abilities[pickups[this.spr]] and 2 or 0
		this.hitbox.w=16
		this.layer=-2
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
				flash_bg=false
				init_object(pickup,this.x+4,this.y+4,this.spr)
				pause_player=false
			end
		end
	end,
	draw=function(this)
		if this.state==0 then
			spr(96,this.x,this.y)
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

pickup={
	init=function(this)
		this.spd.y=-2
		this.collides=true
		this.bounces=true
		this.spd.x=this.spr<125 and -0.8 or this.spr==126 and -0.5 or 1
		this.pickup_delay=4
		this.layer=6
	end,
	update=function(this)
		if not this.is_solid(0,1) then
			-- gravity
			this.spd.y=appr(this.spd.y,3,0.2)
		end
		
		-- friction
		this.spd.x=appr(this.spd.x,0,0.02)
		
		this.pickup_delay-=1
		
		local hit=this.player_here()
		if hit and this.pickup_delay<=0 then
			music_timer=45
			sfx"51"
			freeze=6
			destroy_object(this)
			abilities[pickups[this.spr]]=true
		end
	end,
	draw=function(this)
		spr_outline(this.spr,this.x,this.y,13)
		for i=0,0.875,0.125 do
			circfill(this.x+4+cos(frames/30+i)*8,this.y+4+sin(frames/30+i)*8,1,7)
		end
	end
}

flag={
	init=function(this)
		this.x+=3
		this.layer=4
	end,
	update=function(this)
		if not this.show and this.player_here() then
			sfx"55"
			sfx_timer,this.show,time_ticking=20,true,false
		end
	end,
	draw=function(this)
		spr(118+frames/5%3,this.x,this.y)
		if this.show then
			rectfill(32,2,96,31,0)
			spr(26,48,6)
			?"x"..two_digit_str(fruit_count).."/12",58,9,7
			draw_time(43,16)
			?"deaths:"..two_digit_str(deaths),48,24,7
		end
	end
}

water={
	init=function(this)
		local tx=room.x*16+this.x\8
		local ty=room.y*16+this.y\8
		
		-- search for water endcap
		-- 16 is search distance cap
		for i=1,16 do
			local t=mget(tx+i,ty)
			if t==104 then
				this.hitbox.w=8+(i*8)
				break
			end
		end
		
		this.hitbox.h=128-this.y
		this.layer=0
	end,
	draw=function(this)
		pal()
		rectfill(this.x,this.y,this.x+this.hitbox.w-1,this.y+this.hitbox.h-1,1)
		
		-- shadows
		for i=0,15 do
			pal(i,0)
		end
		
		-- draw deco
		local w=this.x+this.hitbox.w-1
		for i=0,this.hitbox.h do
			-- get raw pos for tline operation
			local rx,ry=this.x,this.y+i
			
			-- math hell
			tline(this.x+round(sin(i/16+time()*0.5)),this.y+i,w,this.y+i,
				(room.x*16+this.x/8),room.y*16+(this.y+i)/8,0.125,0,2)
		end
		
		pal()
		line(this.x,this.y-1,this.x+this.hitbox.w-1,this.y-1,7)
		line(this.x,this.y,this.x+this.hitbox.w-1,this.y,0)
	end
}

icicle={
	init=function(this)
		this.start_x=this.x
		this.start_y=this.y
		this.wait=10
		this.state=0
	end,
	update=function(this)
		if this.state==0 then
			-- search for player
			-- 16 is search distance cap
			for _y=1,16 do
				this.y=this.start_y+_y*8
				if this.player_here() then
					this.state=1
					--psfx(15)
					break
				elseif this.is_solid(0,0) then
					break
				end
			end
			
			this.y=this.start_y
		elseif this.state==1 then
			this.x=this.start_x+frames%2
			this.wait-=1
			if this.wait<=0 then
				this.state=2
				this.x=this.start_x
			end
		else
			this.spd.y+=0.1
			if this.y>128 or this.is_solid(0,0) then
				this.init_smoke()
				destroy_object(this)
				psfx"40"
			end
		end
	end,
}

hook={
	init=function(this)
		this.hooked=false
		this.spd.y=-10
		this.collides=true
		this.hitbox=rectangle(1,3,6,5)
		this.layer=-5
		
		-- collide with jumpthroughs
		this.hit_through=true
	end,
	update=function(this)
		if not this.hooked then
			this.spd.y=appr(this.spd.y,10,0.5)
		end
		if this.is_solid(0,-1) or (this.y<-8 and room.y~=0) then
			if this.is_ice(0,-1) then
				this.spd.y=1
				psfx"40"
			elseif not this.hooked then
				this.hooked=true
				this.spd.y=0
				psfx"14"
			end
		end 
	end,
	draw=function(this)
		if this.hooked then
			pal(8,11)
		end
		local off=this.is_flag(0,-1,3) and -5 or 0
		spr(111,this.x,this.y+off+(this.hooked and 1 or 0))
		pal()
	end,
}

adelie={
	init=function(this)
		this.collides=true
	end,
	update=function(this)
		if this.is_solid(0,1) then
			if this.player_here() then
				this.spd.y=-1
				psfx"59"
			end
		else
			this.spd.y=appr(this.spd.y,4,0.2)
		end
		
		-- look at player
		for obj in all(objects) do
				if obj.type==player then
					this.flip.x=obj.x<this.x
				end
			end
	end,
	draw=function(this)
		spr(this.is_solid(0,1) and 65 or 81,this.x,this.y,1,1,this.flip.x)
	end
}

-- [object class]

function init_object(type,x,y,tile)
	-- generate and check berry id
	local id=room.x..":"..room.y
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
		return ((oy>0 or obj.hit_through) and not obj.is_flag(ox,0,3) and obj.is_flag(ox,oy,3) and not obj.diving) or -- jumpthrough or
		obj.is_flag(ox,oy,0) -- solid terrain
	end

	function obj.is_ice(ox,oy)
		return obj.is_flag(ox,oy,4)
	end

	function obj.is_flag(ox,oy,flag)
		for i=mid(0,(obj.left()+ox)\8,127),mid(0,(obj.right()+ox)/8,127) do
			for j=mid(0,(obj.top()+oy)\8,127),mid(0,(obj.bottom()+oy)/8,127) do
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
						if obj.bounces then
							if abs(obj.spd.x)<0.2 then
								obj.spd.x=0
							else
								obj.spd.x=-obj.spd.x*0.5
							end
							
							if abs(obj.spd.y)<0.2 then
								obj.spd.y=0
							else
								obj.spd.y=-obj.spd.y*0.5
							end
							
						else
							obj.spd[axis],obj.rem[axis]=0,0
						end
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
		init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),29)
	end

	add(objects,obj);

	(obj.type.init or stat)(obj)

	return obj
end

function destroy_object(obj)
	del(objects,obj)
end

function draw_object(obj)
	(obj.type.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj)
	spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
end
-->8
-- [level loading]

function load_room(x,y)
	time_ticking=true
	has_key=false
	room=vector(x,y)
	
	-- remove existing objects
	foreach(objects,destroy_object)
	
	-- check region
	for id,rg in pairs(regions) do
		if rg.bounds(x,y) then
			if region~=id then
				-- changed region
				region=id
				ui_timer=90
				music(-1)
				music(regions[id].music,4000,7)
			end
			
			break
		end
	end

	-- entities
	for tx=0,15 do
		for ty=0,15 do
			local tile=tile_at(tx,ty)
			if tiles[tile] then
				init_object(tiles[tile],tx*8,ty*8,tile)
			end
		end
	end
	
	local p=init_object(player,spawn_pos.x,spawn_pos.y)
end

function raw_pos(obj)
  return (room.x*128)+obj.x,(room.y*128)+obj.y
end

function get_room(obj)
  local x,y=raw_pos(obj)
  return flr((x+4)/128),flr((y+4)/128)
end
-->8
-- [metadata]

regions={
	{
		title="EVERBLUE RIDGE'S",
		name="windswept wonders",
		color=130,
		music=30,
		bounds=function(x,y)
			return x>2 and y==0
		end
	},
	{
		title="SUB-SURFACE",
		name="snowy steps",
		color=1,
		music=0,
		bounds=function(x,y)
			return (x==3 and y>0) or (y==3 and x<5) or (x==2 and y==2)
		end
	},
	{
		title="THE GREAT",
		name="frozen footing",
		color=129,
		music=18,
		bounds=function(x,y)
			return x>3 and y>0 and y<3
		end
	},
	{
		title="LONG-FORGOTTEN",
		name="arctic arboretum",
		color=128,
		music=10,
		bounds=function(x,y)
			return x<3 and y<3 and not (x==2 and y==2)
		end
	},
	{
		title="SUBTERRANEAN LAKE",
		name="penguin paradise",
		color=140,
		music=40,
		bounds=function(x,y)
			return x>4 and y==3
		end
	},
}

--@end

-- tiles stack
-- assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
52,key
103,water
18,spring
19,spring
20,chest
22,balloon
23,fall_floor
26,fruit
28,icicle
45,fly_fruit
64,fake_wall
86,message
123,big_chest
124,big_chest
125,big_chest
126,big_chest
127,big_chest
118,flag
65,adelie
]],"\n"),function(t)
 local tile,obj=unpack(split(t))
 tiles[tile]=_ENV[obj]
end)
__gfx__
0000000000800000008000000e8eeee0008000000000080000000000008800000080000000800000080000000800000000880000494949494949494949494949
000000000e88eee00e88eee0ee88eeee0e88eee00eee88000080000088eeeee00e88eee00e88eee0088eeee0088eeee088eeeee0222222222222222222222222
0000000088eeeeee88eeeeee88eeeeee88eeeeeeeeeeee800e88eee0e8e1ff1e88eeeeee88eeeeee8eeeeeee8eeeeeeee8e1ff1e000420000000000000024000
00000000e8eeeeeee8eeeeeee8e1ff1ee8eeeeeeeeeeee8088eeeeeeeefffffee8eeeeeee8eeeeee8eeeeeee8eeeeeeeeefffffe004200000000000000002400
00000000eee1ff1eeee1ff1e2efffff2eee1ff1ee1ff1ee0e8eeeeeeeefffffeeee1ff1eeeeffffeee1ff1eeee1ff1eeeefffffe042000000000000000000240
000000002efffff22efffff2028888202efffff22fffffe0eeeffffe2e8888e22efffff22ef1ff122effffe227ffff722e8888e2420000000000000000000024
0000000002888820028888200700007007888820028888702ef1ff12028888200288882002888820078888700288882002888820200000000000000000000002
00000000007007000070007000000000000007000000700007788870000770000700700000070070007007000070070000770000000000000000000000000000
55555555000000000000000000000000000000000000000000888800499999944999999449990994033b00007ccccc7007ccc700000000000000000070000000
555555550000000000000000000400000000000000000000088788809111111991114119911409193bb3b00007cc71707117cc70007700000770070007000007
550000550000000000000000000950500aaaaaa00000000008788880911111199111911949400419b0bb44000717170071117170007770700777000000000000
55000055007000700499994000090505a998888a0000000008888880911111199494041900000044000402200071170007111700077777700770000000000000
55000055007000700050050000090505a988888a0000000008888880911111199114094994000000008826220071170007111700077777700000700000000000
55000055067706770005500000095050aaaaaaaa0000000002888820911111199111911991400499087882220071700000711700077777700000077000000000
55555555567656760050050000040000a980088a0000000000222200911111199114111991404119088882200007000000717000070777000007077007000070
55555555566656660005500000000000a988888a0000000000000000499999944999999444004994008800000000000000070000000000007000000000000000
7777777777777777777777777777777777cccccccccccccccccccc7700b000000000000000000000000000005500000000077000000000000000000000000000
77777777777777777777777777777777777cccccccccccccccccc777003700000000000000000000000000006670000000777700000777770000000000000000
777c77777777ccccc777777ccccc7777777cccccccccccccccccc7770003700000080000000000000aa000a06777700000777700007766700000000000000000
77cccc77777cccccccc77cccccccc7777777cccccccccccccccc77770003b000000e80000082800000a0baa06660000007737770076777000000000000000000
77cccc7777cccccccccccccccccccc777777cccccccccccccccc77770000b00000088000082e800000ab0aa05500000007737770077660000777770000000000
777cc77777cc77ccccccccccccc7cc77777cccccccccccccccccc777000730000b00b00088e800000003b0b06670000007733770077770000777767007700000
7777777777cc77cccccccccccccccc77777cccccccccccccccccc777000b30000bb03b0b888200000b03b0b0677770000773b770070000000700007707777770
7777777777cccccccccccccccccccc7777cccccccccccccccccccc7700730000b77377738820000007bb77b0666000000733bb77000000000000000000077777
cccccccc77cccccccccccccccccccc7700000000000000000000000000b3000000000000b0000000000000000000066677333377000000000000000000000000
cccccccc77cccccccccccccccccccc77aaa900000aaa0000000aa00000b700000000000700000000000000080007777673b333370000000000ee0ee000000000
cccc77cc77cc7cccccccccccc77ccc77a09a00000a9a0000000aa000000b700000800073000000000000008e00000766733333370000000000eeeee000000030
cccc77cc77ccccccccccccccc77ccc77a00aaaaa0a0aaaa0000aa0000000b000008800bb00000000800000e8000000553333b33300000000000e8e00000000b0
c7cccccc777cccccccc77cccccccc777a09a099a0a9a99a0000aa0000000b00000080033700000008e00078000000666033333300000b00000eeeee000000730
cccccccc7777ccccc777777ccccc7777aaa9090a0aaa90a0000aa0000007b000000b00033700b0008e000b000007777600044000000b000000ee3ee007000b00
cccc7ccc777777777777777777777777000000000000000000000000000b00000000b0033b0b30000b0073000000076600777700030b00300000b00000b0b700
cccccccc7777777777777777777777770000000000000000000000000000000000073b7bb37b37000b0b3b700000005507777770037737300000b00000377770
57777557000000007777777777777777777777777777777700000000000000000000000077777777000000000777777042222222422222224222222200022000
77777777001111007111177711117771111177777111777700000000000000000000000077777777000000000077770002222224222222242222222000022000
7777cc770117171071cc777cccc777ccccc7771771c7771700000000000000000000000077777777000000000002400000024000000000000002400000024000
777ccccc0111991071c777cccc777ccccc777c1771777c170000077777700000000ff00077777777000000000004400000044000000000000004400000044007
77cccccc1117771171777111177711111777111777771117000775555557700000ff7f0077777777000000000004400000044000000000000004400000044777
57cc77cc1117771177771111777111117771111777711117007555555555570000ffff0077777777000000000004400000044000000000000004400000047777
577c77cc011777107111111111111111111c111771111c17005566666566550000ffff0077777777000000000004400000044000000000000004400000777777
777ccccc1199d990711111111111111111111117711111170755555555555570000ff00077777777000000000004200000042000000000000004200007777777
777ccccc101111017111111111111111111111177111111705555555555555505555555577777777707777774949494900022000422222220002200000022000
577ccccc111717117111111c111111111111111771cc111705665500005566505555555577770770000777772222222200022000222222240002200000022000
57cc7ccc1111991171111111111cc1111111111771cc111705555000000555505555555577700070000777770002400000024000000240000002400070024000
77cccccc0117771071c11111111cc11111111c1771111c1705665000000566505555555577000070000077070004400000044000000440000004400077044000
777ccccc011777107111111111111111111111177111111705555000000555500000000077000000000070070004400000044000000440000004400077744000
7777cc770117771071111111111111111111111771c1111700555700007555000000000070000000000000070004400000044000000440000004400077777700
77777777119dd91071111111c1111111111111177111111700557777777755000000000000000000000000000004400000044000000440000004400077777770
57777577009009007111111111111111111111177111c11707777777777777700000000000000000000000000004200000042000000420000004000077777777
000000000000000071111111111111111111111771111117007777008888888008888888000000000000000000800000002ee8000007700000eee20007070700
00aaaaaa00000000711111111111111111111117711c111707000070888888800888888800000000000000000e88eee002ee88e0028888200eeef12070070070
0a99999900000000711111111111c1111111111771111117707700078882220000222888000000077000000088eeeeee08feee8821ff1fe20eeeff8060070060
a99aaaaa000000007111111cc1111111111111177111cc177077bb0788222000000222880000007777000000e8eeeeee781fee80effffeee0eeeff8706070600
a9aaaaaa007777007111111cc1111111111c11177111cc17700bbb0788220000000022880000077777770000eeeffffe78ffeee0eeeeee8e08eef18700686000
a99999990711117071c11111111111111111111771c11117700bbb07882000000000028800007777777770002ef1ff1208ffeee0eeeeee8888eeef8000070000
a99999997111111771111111111111111111111771111117070000700000000000000088007777777777770002888820021feee00eee88e00e88ee2000070000
a99999997111111777777777777777777777777777777777007777000000000000000000077777777777777000077000002eee0000000800008ee20000070000
aaaaaaaa7111111777777777777777777777777777777777004ccc00004c000000400ccc00000000000000000008808008888066000000000708070006700000
a49494a17111111771117771111177711111777771117777004ccccc004cc000004ccccc00000000000000000008808008800077000128000708070060000500
a494a4a17111111771c777ccccc777ccccc7771771c7771704200ccc042ccccc042ccc000000000000000000008888200808007700012880777877706000a5a9
a49444aa7111111771777ccccc777ccccc777c1771777c17040000000400ccc004000000000000000000000008282200080080771288888877787770066aaba5
a49999aa71111117777711111777111117771117777711170400000004000000040000000000000000000000080888000000087700012880088888006000a4a9
a49444997111111777711111777111117771111777711c1742000000420000004200000000077700007700000208280000008077000128000288820060000404
a494a444711111177111111111111111111111177111111740000000400000004000000000777770077777000008020000080077000000000028200006700404
a4949999711111177777777777777777777777777777777740000000400000004000000007777777777777700002000000200066000000000002000000000040
52035252525252526200001323520352525262000000425203525252525252525223232323232352525252525252525252526200000042525252525252035252
52036200002545253545263636462535354526364625354526460097a7425252525223330097254500000056d4d4d44252522323233325354513232333000042
525252035223232333000072a542525252036200000042525223232323235252629572a59572a513525252525252525203523300000042525223232323232323
2323330000254525354595c5c1a526363646b100a526364695009602024252035262244400572545004300b1000000425262950000a52636469500a595000042
52525252629572a5950000720042525252233300000042523395720072a5132333007200007300a513232323235252525262b10000001323339500000000a512
3294950000264625354500c50000b100a595000000c500c5000012222252525203622545a6c125450000000000000013233300000000a5950000000000009742
52522323330073000000117200425252629573000000133395007200730000b4000072000000000054029500a5135252526200000000b4a595000097a7000042
6295000000c1a525354500c5000000000000000000c500c50000425252525252526225455700254500000000000000b4a5950011000000110000000041960242
52620272730000920000547300425252620000000000b47200007300000000c500007397a700000055b1000000a54252526200000000e5000000001232000042
6200a10000000026364600c5002434343444d0e0d4d5d4d5d4f042035252525252332646c196254500000000000000f4a7009657000000540000001222222252
0362957200a78393000055d4d442525262a70097a700c573000000000000a2f4a6a3969494a6000055000011000042525262a60097a700000000001333000042
62a6000000c4d457b1c500c5002636363646111100c500c500001323235203526295c1b100572646000000000000572434343444000000551111114252525252
5262007200122232000056d4d44252035232969494a6c5000000000000f012222222222222320000560000540000425252522222223200000000001232d4d442
5222223200c500c500c5005700a524343434344400b500c50000b1b4b11323233300009700b1a595000000000000a52535353545d4d4d4552737471323235252
03620072004252620000000000425252035222329494f50000000000000042525252525252620000000000550000135252525203526200002100004262000042
5252523300c500c500c500c5000025353535354500c500c5000000c500a59500b4000094a6a7000096a6a721000000253535354500000055950000a595a51352
52620073004252620000000000132352525252522222321111111111111142035252232323330000000000550000b14252522323526200007100004262000042
03523395005700c5005700c5000025353535354500c500b5000000c500009796f5e396942434442434343444000000253535354500000056000011000000a542
526200000013233300000000b32444425252232323233327373737373747425252629500730000000000005500000042523395b1426211111111114262000042
5262950000b100c500c100c5000025353535354500c500c5000000b5000012222232244425354526363636460000002636363646000000b10000570000000042
526200000002957200000000b3254513233394957273b4000000000000a5132323330000000000000000005600000042629500001333d0e0e0e0f01333d4d442
52620000000000c500000057001126363636364600b500c5000000e50000425252622646253545b1000000b1000000244457b157000000000000540000e39642
5262000000b1007300000000b326469500a595007300c50011111111000000b40073008296a6000092000000000000133300a10002b40000000000a595009742
5262a600000000c5000000b1001222223200000000e500c500001111111142525252325426364600000000000000002545b100b4000000110000550000122252
52629700000000000000000000a595000000009796a6c50012222232000000f4a697a7122232a68393a70000000000b4b4000000b4c500000000000000001252
526294a697000057000000000042035262004300000000b5000024343444425252526256b10000000000210000540025450043c5110000540000550011425252
525232a6d3a38297a700000000000000a7a396949494f5a24252036200009694949494425252222222320000009700f4f50000a7f4f500717171717171004252
5252222232000000000011111142525262000000000097c5004125353545425252526295000000000011571111561126460000c5571111560000550012525252
525252222222222232000097a2961222222222222222222252525262d0f012222222225252525252526200000012222222321222223211111111111111114252
5252035262000000000024344442525262111111111112222232253535454252525262000097004196243434343434343434343434441232111155d442525252
525252520352525262d0f01222225252525203525252525252525262000042525252525252525252526200000042525252624252525222222222222222225203
5252525262d0e0e0e0f025354542520362243434344442525262253535454252525262000012222232253535353535353535353535454252223255d442525252
52525252525252526200004203525203525223232323232352035233000042525252520352232323233300000013235252624252232323232323525252525252
52520352620000000000253545132323332535353545132323332636364613525252620000425252622535353535353535353535354542525262560042525252
525252520352525262d4d4425252525252629500000000b1135262b100001352522323233395b4b1a595000000b1a5132333133395c1c1c1a594420352030352
5252522333d0e0d4d4f02535455795b4a526363636469596a6a7b4b1273747425252330000425252622636363636363636363636364642525262950013235252
525252525252525233000042035252525262000000000000a54262000000b11333b1b1a59500c51111110000000000b4b400a5020000000000a5132323232352
03526295000000000000263646b100f4a600c1b100a796949494f500b497a5132333000096425252522232579500000000a595b100a513235262000000a54252
52035223232352629500004252520352526211000011000000426200000000a5950000000000f4273747a600970000c5c50000b1000000000000b400c100b413
232333d0d4d4e0f0243444244400001232a697a796949412223294a6f494a696a6000096944252035252629500009796a6000011000000b34262a74100001352
525233b100a5426200000042522323232333d0d4d454d4d4f01333000000000000a70000009694122222223202a600f4f5000000000000000000c5000000c500
00a59500000000002535452545001142522222222222225252522222222222222222222222525252525262000000243444a70054a70000b342522232a600b142
5233950000004262d4d4d413339500b4000000000056a70000a59500000012222232000000122203525252621222222232023100000000000096f5000000f4a6
970000000000e0f02636462545d4f042520352522323232323232323525252525203522323235252525262d0e0f026364657115694a600b34252233302000042
6295000000001333000000b1000000c5000000000012320000000000000042525262d0e0f01323235252036242525252629500a7000000000024440000001222
32a6000000000000b1a5572545000042525223339500a595000000a51352525252233395b1a51323235262b200b31222222222222232b2b342620295b1000042
620000000000a50200000000000000f4a697a7000042620000004100000042525233000000b1c5a5425223331352520362111157111111111126460000004252
5232d0e0d4d4d4d4d4d4f02545110042523395b10000000000000000a51323233395b1000000b1b1a54262b200b34203525252525262b2b31333b10000000042
6200c700000000b100000000000012222222321111426211111232111111425262b100000000c500133395c5b142525252222222222222222222320000004252
52620000000000000000002545d0d44262950000000000000000000000b100a59500000000000000001333b200b34252525252520362b200a595000000001142
62a60000970000000000000000004252525262d0f01333d0f01333d0e0f04203620000110000b500000000c50042035252525223232323235203620021004252
5262d0e0000000b7000096264600004262000000008484140067000000000000000000000000000000a5950000b34252035252232333b2000000000097215742
62949494940000000000000000001352525233000000b1000002950000001323330000570000c500000000b50013232323233395a55495a51352620071004252
5233a6e397a70000000012223200114262000000142434344457001400009796a6a70000000000000000000000b31352525233c1000000000000000012222252
5222222232000000002100000000b142526295000000000000b100002100b400b40011540000b500000000c500b100b4b400b10000560000a542621111114252
62122222222222222232425233d4f042620000244425353545243444000012222232000014840000000000000000a54252629500000000000000000042525252
5252525233d4d4f0243444570000004203620043000000000097a7965497c500c59754561100e500000000b5000097f4f5a7000000b10000001333d0e0f01323
331323232323232323331333b40000426276002646253535452636460086425252330084244400000000000096a6004252620043007171717100000013525252
525203627600000026364685000086420362005400005700001222325502f500f494561232000000000000c50000122222320000000097a70000b4000000b400
b4b1b1c1b1c1c1c1b1c1c1b1c5979642620000000026363646858585000042036200005425450057000000243444004252620000000000000000000000425252
52525262000000000085850000000042526276560000850086425262551222222222324262000000000000b50000425203620000003112320000e5000096f5a7
f4a60097000000a7a7000097f494125262a600000085858585000000009642526276005626460085000000263646864252627600000000000000000086425252
52525262000000000000000000000042526200000000000000425262554252520352624262000000000000e50000425252620000000042620000000031122222
22222222222222222222222222225252523200000000000000000000001252526200000085850000000000858585004252620000000000000000000000425252
__label__
cccccccccccccc7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc77777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc77777777ccccccccccccccc77cccccc77cccccc77cccccc77cccccc77cccccc77ccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc777777cccccccccccccc777777cc777777cc777777cc777777cc777777cc777777ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc777777ccccccccccccc777777777777777777777777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc7777cccccccccccccc777777777777777777777777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc7777cccccccccccc777777777717ccc71117ccc71007ccc700707777777777777777cccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc7777cccccccccccc77777707717117cc717117cc707117cc700007777777777777777ccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc77ccc7777cc7cccc77ccc77777111717111717171117170711171700007777777777777777ccccccccc77cccccccccccccc77cccccc77cccccccccc
ccccccccc77ccc7777ccccccc77ccc777701117117111701171117000711170000007707777777777777cccccccc77cccccccccccccc77cccccc77cccccccccc
ccc77cccccccc777777cccccccccc7777711117117111711171117100711170000007017777777777777ccccc7ccccccccccccccc7ccccccc7cccccccccccccc
c777777ccccc77777777cccccccc7777711101110171171101711710007117000000001777777777777ccccccccccccccccccccccccccccccccccccccccccccc
77777777777777777777777777777777111111111171711111717110007170000000001177777777777ccccccccc7ccccccccccccccc7ccccccc7ccccccccccc
7777777777777777777777777777777711011101110711011107110000070000000000017777777777cccccccccccccccccccccccccccccccccccccccccccccc
0777777000000011717777777777777711111111111111111111111000000000000000117177777777cccccccccccccccccccccccccccccccccccccccccccccc
0077770000007711011777777777777701110111011101110111011000000000000000110117777777cccccccccccccccccccccccccccccccccccccccccccccc
000240000000771111177777777c777711161111111111111111111000000000000000111117777777cc7ccccccccccccccccccccccccccccccccccccccccccc
00044000000000011101770777cccc7711011101110111011101110000000000000000011101770777cccccccccccccccccccccccccccccccccccccccccccccc
00044000000000111111711777cccc77111111111111111111111110000000000000001111117117777cccccccc77cccccc77cccccc77cccccc77ccccccccccc
000440000000001101110117777cc7770111011101110111011101100000000000000011011101177777ccccc777777cc777777cc777777cc777777ccccccccc
000440000000001111111111777777771111111111111111111111100000000000000011111111117777777777777777777777777777777777777777cccccccc
000420000000000111011101777777771101110111011101110111000000000000000001110111017777777777777777777777777777777777777777cccccccc
0002200000000011111111117ccccc71111111111111111111111110000000000000001111111111177777700000001117ccc710000000000777777077cccccc
00022000000000110111011107cc717101110111011101110111011000000000000000110111011101777710000000117117cc70000000000077770077cccccc
00024000000000111111111117171711111111111111111111111110000000000000001111111111111241100000001171117170000000000002400077cc7ccc
00044000000000011101110111711701110111011101110111011100000000000000000111011101110441000000000117111700000000000004400077cccccc
000440000000001111111111117117111111111111111111111111100000000000000011111111111114411000000011171117100000000000044000777ccccc
0004400000000011011101110171711101110111011101110111011000000000000000110111011101144110000000110171171000000000000440007777cccc
00044000000000111111111111171111111111111111111111111110000000000000001111111111111441100000001111717110000000000004400077777777
00042060000000011101110111011101110111011101110111011100000000000000000111011101110421000000000111071100000000000004200077777777
00022000008000111111111111111111111111111111111111111110000000000000001111111111111221100000001111111110000000000002200000000011
000220000e88eee10111011101110111011101110111011101110110000000000000001101110111011221100000001101110110000000000002200000000011
7002400088eeeeee1111111111111111111111111111111111111110000000000000001111111111111241100000001111111110000000000002400000000011
77044000e8eeeeee1101110111011101110111011101110111011100000000000000000111011101110441000000000111011100000000000004400000000001
77744000eee1ff1e1111111111111111111111111111111111111110000000000000001111111111111441100000001111111110000000000004400000000011
777777002efffff20111011101110111011101110111011101110110000000000000001101110111011441100000001101110110000000000004400000000011
77777770028888211111111111111111111111111111111111111110000000000000001111111111111441100000001111111110000000000004400000000011
77777777007007011101110111011101110111011101110111011100000000000000000111011101110421000000000111011100000000000004200000000001
77777777777777771111111111111111111111111111111111111110000000000000001111111111111221100000001111111110000000000002200000000011
77777777777777770111411101110111011101110111011101110110000000000000001101110111011221100000001101110110000000000002200000000011
cccc7777777c77771515911111111111111111111111111111111110000000000000001111111117711241100000001111111110000000000002400070000011
ccccc77777cccc775151910111011101110111011101110111011100000000000000077111011177770441000000000111011100000000000004400777000001
cccccc7777cccc775151911111111111111111111111111111111110000000000000077111111777777441100000001111111110000000000004477777770011
ccc7cc77777cc7770515911101110111011101110111011101110110000000000000001101117777777777100000001101110110000000000004777777777011
cccccc77777777771111411111111111111111111111111111111110000000000000001111777777777777700000001111111110000000000077777777777711
cccccc77777777771101110111011101110111011101110111011100000000000000000117777777777777770000000111011100000000000777777777777771
cccccc77777777771111111111111111111111111111111111111110000000070000001177777777777777770000001111111110000000007777777777777777
ccccc777777707710111011101110111011101110111011101110110000000000000001171111777111177770000001101110110006000007777777777777777
ccccc777777000711111111111111111111111111111111111111110000000000000001171cc777cccc777170000001111111110000000007777ccccc777777c
cccc7777770000711101110111011101110111011101110111011100000000000000000171c777cccc777c17000000011101110000000000777cccccccc77ccc
cccc77777700001111611111111111111111111111111111111111100000000000000011717771111777111700000011111111100000000077cccccccccccccc
ccccc7777000001101110111017701110111011101110111011101100000000000000011777711117771111700000011011101100000066077cc77cccccccccc
ccccc777000000111111111117777711111111111111111111111110000000000000001171111111111c111700000011111111100000066077cc77cccccccccc
cccccc770000000111011101777777711101110111011101110111000000000000000001711111111111111700000001110111000000000077cccccccccccccc
cccccc770000001111111111777777771111111111111111111111100000000000000011711111111111111700000011111111100000000077cccccccccccccc
ccccc77700000011011101117111777701110111011101110111011000000000000000117111111111111117000000110111011000000000777ccccccccccccc
ccccc777000000111111111171c7771711111111111111111111111000000000000000117111111111111117000000111111111000000000777ccccccccccccc
cccc7777007000711171117171777c1711711171117111711171117000700070007000717111111c111111170000000111011100000000007777cccccccccccc
cccc777700700071117111717777111711711171117111711171117000700070007000717111111c111c11170000001111111110000000007777cccccccccccc
ccccc777067706770677067777711c17067706770677067706770677067706770677067771c1111111111117000000110111011000000000777ccccccccccccc
ccccc77756765676567656767111111756765676567656765676567656765676567656767111111111111117000000111111111000000000777ccccccccccccc
cccccc775666566656665666777777775666566656665666566656665666566656665666777777777777777700000001110111000000000077cccccccccccccc
cccccccc7777777777777777777777777777777777777777777777777777777777777777777777777777777700000011111111100000000077cccccccccccccc
cccccccc77777777777777777777777777777777777777777777777777777777777777777777777777777777000000110111011000000000777ccccccccccccc
ccccccccc777777cc777777cc777777cc777777cc777777cc777777cc777777cc777777cc777777ccccc7777000000111111111000000000777ccccccccccccc
ccccccccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccccc7770000000111011100000000007777cccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc770000001111111110000000007777cccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc77000000110111011000000000777ccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77000000111111111000000000777ccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7700000001110111000000000077cccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6cccccccccccccccccccccc7700000011111111100000000077cccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777000000110111011000000000777ccccccccccccc
ccccccccccccccccc6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccccccc777000000111111111000000000777ccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77cccccc77770000000114999940000000007777cccccccccccc
ccccccccccccccccccccccccccc77cccccc77cccccc77cccccc77cccccc77cccccccccccc7cccccccccc77770000001111511510000000007777cccccccccccc
ccccccccccccccccccccccccc777777cc777777cc777777cc777777cc777777cccccccccccccccccccccc777000000110115511000000000777ccccccccccccc
cccccccccccccccccccccccc7777777777777777777777777777777777777777ccccccccc6cc7cccccccc777000000111151151000000000777ccccccccccccc
cccccccccccccccccccccccc7777777777777777777777777777777777777777cccccccc7ccccccccccccc7700000001110551000000000077cccccccccccccc
cccccccccccccccccccccc77777777777177777777777777777777777077777777cccccccccccccccccccc7700000011499999940000000077cccccccccccccc
cccccccccccccccccccccc77777707710117777771117777777707700007777777ccccccccccccccccccc777000000119111111900000000777ccccccccccccc
ccccccccccccccccc77ccc77777111711117777771c77717777111700007777777cc7cccccccccccccccc777000000119111111900000000777ccccccccccccc
ccccccccccccccccc77ccc77770111711101770771777c17770111700000770777cccccccccccccccccc77770000000191111119000000007777cccccccccccc
ccc77cccccc77cccccccc7777711111111117117777711177711111000007007777ccccccccccccccccc77770000001191111119000000007777cccccccccccc
c777777cc777777ccccc777771110111011101177771111771110110000000077777ccccccccccccccccc777000000119111111900000000777ccccccccccccc
777777777777777777777777111111111111111171111c17111111100000000077777777ccccccccccccc777000000119111111900000000777ccccccccccccc
777777777777777777777777110111011101110171111117110111000000000077777777cccccccccccccc7700000001499999940000000077cccccccccccccc
07777770000000117ccccc7111111111111111117111111711111110000000007077777777cccccccccccc7700000011111111100000000077cccccccccccccc
007777000000001107cc71710111011101110111711c1117011101100000000000077777777cccccccccc777000000110111011000000000777ccccccccccccc
000240000000001117171711111111111111111171111117111111100000000000077777777cccccccccc777000000111111111000000000777ccccccccccccc
00044000000000011171170111011101110111017111cc171101110000000000000077077777cccccccc77770070007111711170007000707777cccccccccccc
00044000000000111171171111111111111111117111cc171111111000000000000070177777cccccccc77770070007111711170007000707777ccccccccccc6
000440000000001101717111011101110111011171c11117011101100000000000000017777cccccccccc777067706770677067706770677777ccccccccccccc
000440000000001111171111111111111111111171111117111111100000000000000011777cccccccccc777567656765676567656765676777ccccccccccccc
00042000000000011101110111011101110111017777777711011100000000000000000177cccccccccccc7756665666566656665666566677cccccccccccccc
00022000000000111111111111111111111111117ccccc7111117110000000000000001177cccccccccccc7749494949494949494949494977cccccccccccccc
066220000000001101110111011101110111011107cc717101110110000000000000001177cccccccccccc7722222222222222222222222277cccccccccccccc
76624000000000111111111111111111111111111717171111111110000000000000001177cc7cccc77ccc7700042011111111100002400077cc7ccccccccccc
77044000000000011101110111011101110111011171170111011100000000000000000177ccccccc77ccc7700420001110111000000240077cccccccccccccc
777440000000001111111111111111111111111111711711111111100000000000000011777cccccccccc777042000111111111000000240777cccccccc77ccc
7777770000770011011101110111011101110111017171110111011000000000000000117777cccccccc77774200001101110110000000247777ccccc777777c
77777770077777111111111111111111111111111117111111111610000000000000001177777777777777772000001111111110000000027777777777777777
77777777777777711101110111011101110111011101110111011100000000000000000177777777777777770000000111011100000000007777777777777777
77777777777777771111111111111111111111111111111111111110000000000000001111111111177777700000001111111110000000000777777000000011
77777777777777770111011101110111011101110111011101110110000000000000001101110111017777100000001101110110000000000077770000000011
c777777ccccc77771111111111111111111111111111111111111110000000000000001111111111111241100000001111111110000000000002400000000011
ccc77cccccccc7771101110111011101110111011101110111011100000000000000000111011101110441000000000111011100000000000004400000000001
cccccccccccccc771111111111111111111111111111111111111110000000000000001111111111111441100000001111111110000000000004400000000011
ccccccccccc7cc770111011101110111011101110111011101177710007700000000001101110111011441100000001101110110000000000004400000000011
cccccccccccccc771111111111111111111111111111111111777770077777000000001111111111111441100000001111111110000000000004400000000011
cccccccccccccc771101110111011101110111011101110117777777777777700000000111011101110421000000000111611100000000000004200000000001
cccccccccccccc771111111111111111111111111111111177777777777777770000001111111111111221100000001111111110000000000002200000000011
ccccccccccccc7770111011101110111011101110114011177777777777777770000001101110111011221100000001101110110000000000002200000000011
cccc77ccccccc777111111111111111111111111111951517777cccccccc77770000001111111111111241100000001111111110000000077002400000000011
cccc77cccccc777711011101110111011101110117091505777cccccccccc7770000000111011101110441000000000111011100000000777704400000000001
c7cccccccccc77771111111111111111111111111119151577cccccccccccc770000001111111111111441100000001111111110000007777774400000000011
ccccccccccccc7770111011101110111011101110119515177cc77ccccc7cc770000001101110111011441100000001101110110000077777777770000770011
cccc7cccccccc7771111111111111111111111111114111177cc77cccccccc770000001111111111111441100000001111111110007777777777777007777711
cccccccccccccc771101110111011101110111011101110177cccccccccccc770000000111011101110411000000000111011100077777777777777777777771
cccccccccccccc771111111111111111111111111111111177cccccccccccc770000001111111111111111100000001111111110777777777777777777777777
ccccccccccccc77701110111011101110111011101110111777cccccccccc7770000001101110111011101100000001101140110777777777777777777777777
ccccccccccccc77711111111111111111111111111111111777cccccccccc77700000011111111111111111000000011111951507777ccccc777777cc777777c
cccccccccccc7777110111011101110111011101110111017777cccccccc77770000000111011101110111000000000111091505777cccccccc77cccccc77ccc
cccccccccc7c7777111111111111111111111111111111117777cccccccc7777000000111111111111111110000000111119151577cccccccccccccccccccccc
ccccccccccccc77701110111011101110111011101110111777cccccccccc777000000110111011101110110000000110119515077cc77cccccccccccccccccc
ccccccccccccc77711111111111111111111111111111111777cccccccccc777000000111111111111111110000000111114111077cc77cccccccccccccccccc
cccccccccccccc771101110111011101110111011101110177cccccccccccc77000000011101110111011100000000011101110077cccccccccccccccccccccc

__gff__
000000000000000000000000000a0a0a0402000000000000000000020000000005050505050505020202020202000000050505050000000202020202020202020000131313130000020300020202020200001313131300000202020a020202020000131313130000000202000000000000001313131300000002020000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
25252525302525252525302525252525252525252525302525252526626364242525302525253232323232323025252525330000000000005a24252532330000000000000000000000005a31322525252525323232323232252530252530302525252526590000005c005a313232323233590000003125253233626363645253
3025252525252525252525252525253025252525253232323225252659005a24252525253026591b27270027312525302659000000000000003132335900000000000000000000000000001b5a242525252659001b1b004b242532323232323232323233000000005c00004b5a594b5a59000000005a313359000000005a6263
2525252525252525253025252525252525253025335927275a242526001a00242530253232330000372700275a24253233001a0000000000005a595c0000000000000000000000000000000000312525302600001111005c313359000000004b004b004b000000005c00005c00794f6a797a00000000452b0000000000003b21
252525252525252525252525252525252525252659002727002430260000002425253337271b00000027003700313349496a7a00000000000000005c00000000000000000000000000110000005a3132323300004244005c5a5900000011005c005c005c000000005c00005c0020212222230d000000552b0000111100003b24
2530252525323232323225252530252525323233000027370031323300003b24252659003700001100270000004949494949496a000000000000005c0000000000000000000000000045000000004b00004b000052544d5d4d4d4d5d4d454d4d4d5d4d5d4d4d4d4d5d4d4d4e005a2425252600000000652b003b21232b003b24
2525252533273700375a31323232323233275a5900002700005a4945000000242526000000696a20003700000049492122234920000000000000007500000000000000000000004c4d554d4d4d4d4e00005c00006264135e0000005c00650000005c005c000000005c00005c000024252526110000000000003b24262b343b24
252525263727000000005a5937273700373700000000370000005a552b00003132330000002122235d4d4d4d5d21222525252359000000000000001b0000000000000000696a005c0065000000007500007500001b1b00000000005c001b0000005b0e5b000000005c00005c000024252525231111111100003b24262b003b24
2525252600370000000000007937797a2a797a0000000000000000650000004949490000003132335c0000005c31252525253300000000000000000000000000000000002123005c001b000000001b00001b0000000000000000005c00000000005e005c000000005c7f005c00002425252525222222232b003b24262b003b24
252525337900006100007a692122222222232000000000000000004500003b2122235b0e5b2122235c0000005c1b313232335900000000000000000000002c00002c00002426005c000000000000000000000000000000000000005e000000000000005e000000004f6a794f6a7a2425252525253232332b003b31332b003b24
25252649496a79717a694949242525253026590000000000000000550000002425265c005c2425265c0000005c001b004b270000000000000000000000003c7a7a3c000024267a5c0000000000000000000000000000000000000000000000000000000000000011212222230d0f31252532323359004b000000004b00000024
302526494949494949494949242530252526000000001100000000652b00002425335c005c2425265f0000295c0000005c37000000000000000000002c00494949496a692425235c007a002c000000000000000000000046470000000000000000000000000000212525252600004b31334b5a5900005c000000005c00000024
2525252349494949494949212525252525261111111175000000004b0000003133595c005c243026496a38394f6a7a004f6a000000000000000000793c694949494949212525265f69496a3c7a002c000000000000007956577a0000000000000000000000000024252530266a7a5c5a594c4d4d4d4d4d4d4d5d4d4d4d4d4d24
2525252522222222222222252525252525252222222223000000005c0000004b00005c794f242525222222222222222223497900000000000000004949494949494920242525252349494949496a3c797a00000000002122222300000000002c00000000000000242525252523495f7a695f140000000011005e001100000024
25252525252525253025252525252525252525252525260000793a4f6a7a3f4f6a3d4f494924252525253025252525252649496a7a000000000000204949212222222225252525252223494949494949496a002c0000242525266a000000003c797a000011000024252525252522222222222311000000450000004511111124
252525252525252525252525252525252525252530252600002122222349212222222222222525252525252525252530252349494979000079007a21222225252525252525252525252522222349494949496a3c7a6924252525236a696a694949490d0f206a6924302525252525252525252523111111651111115549494931
25253025252525252525252525252525252525252525260000242525264924252525252525252525302525252525252530252222230d4d4d0e4d0f242525252525252525252525252525252525222222234949494921252525252649494949212223000049494924252525252525252525252525222349494949496549494949
2525323232323232322525253232252525252525252526000024302526492425252525253025252532323232323225252525252526000000000000242530252525253232323232323232253025252525264949494924253232252649494949243026000049494931252525252530252525252525252525252526494949494949
25265900275a590027313233595a31252525252532323300002425323349243025323232323225264959007a5a492425253032323300000000000024252525252533591b0000001b5c5a313232322530252222222225331c5a24252222222225252679004949595a312530252525252525252525252525323225222349494949
25330000370016002700273700005a24253025335937270000242627275a31252659696a5a49313349006949005a3132323359371b000000000000313225252526590000000000005c00005c001b31252525252525261c0000313232322525252525237a5a597a00492425252525252525253025252533595a31252522222222
265900000000000027002700001a00242525261b0000370000313327370027242600212300492049590049496a79005a5927000000000000000000755924253026000000000000005c00005c00001b242525323232330000001c5a595a24252525252522222320005a313232322530252532322525265900005a242532322525
26000000000000002700370079696a24252526793a7a00000020592700002724264d24267a5a49490069494949496a3e7a370000000000000000001b0031323233007a00000000007500005c000000242533591c001b000000000000693132323232253025335900002059001b31323233591b312526000000002426591b3125
260d0f45000000002700000021222225252525222223000000270027000037242600242649005a590049494949212222236a7a000000000000000000005a59004b692011111100001c00007500000024265900000000000000000000424343434344242526590000001c0000001b005a5900005a2426007e0000242600001b24
260000550000000037000000312525252525253025330000002700270000002426002426496a797a6949212222253025252223000000000000000000000000794f494921222300000000001c00000024260000000000000000000000626363636364242526001a00000000000000797a3e790000242600000000242600000024
260d4d5500000000000000005a31323232323232334b000000273d2700000024264d31337273737373743132323225252525260000007900007a0000000000727373743132334d4d4d4d4d4d4d4d0f313300000000000000000000005c1c42434421252526000000000000110000212222230d0f24260d0e0e0f313300000024
260000550000000000160000005a5900005a594b375c0000002122230000002426005a4959005c005a755927375a31252532330d0e0f212222230d4d4d4d0f212222222222230000000000000000795a5900000000114244000000005c00525354243025267500000000004500002425252600003133000000004b5900000024
264d0f5500000000000000000000007a7a00004c4d5d4d4d4d2430260d0e0f313300004b00005c00005c003700002724264959000000313232330000007a69242525253032334d4d4d4d4d4d0e0f4243434400000045525400000000750062636424253233424344000000554d4d3125252600001b1b000000005c0079000024
260000650000111100000000797a6949496a005c005c0000002425267a79005a5900005c00005e00005c0000000037242649000000004b00004b000069494924252525331b0000000000000000005253535400000065626400000000007900005a3133595a6263644d4d4d6500005a24253300001111000012005c6920000024
260d4d4d4d4d424400000000494949494949004c4d4d4d4d4d24252649496a7a28007a5b00000000005c00007d0000242659000000005c00005c0069494949243025265900000000000000000000525353541111114243440000000000207a696a5a5900001b1b1c0000001b000000313359007a21234d4d454d4d21230d0f24
267a000000005254000000694949494949496a5e0000000000313233494921222222222300000000005c002a00007924267a000000005c00695f694921222225252526000000004243440000000052535354424344525354797a00000021222222230d0e00000000000000000000005a5900694924267a00556a692426000024
262011111111525400000f21222222222222230000001200001b6949494924252530252611111111005e00212222222526496a0000005c694949494924252525252526000011115253540000000052535354525354525354424400000024252525266a790000000000000011000000797a7921222526206a6521222526000024
252222222223626411000024252525253025260d0e0f206a2869494949492425252525252222222311111124252525252522230000004f4921222222252525252525260000424452535411111111525353545253545253545254000000242525252522230000797a000000450000002122222525252642434424252526000024
2525252525252222230000242525252525252600000021222222222222223025252525252530252522222225252525252525260000002122253025252525252525252600005254525354424343445253535452535452535452540d0e4d242525253025260d0f4244000000554d4d4d2425252525252652535424252526000024
__sfx__
000200002f6502b6402963026620226301f6452f1501d0652a17017075271701307523170110751e1700e0751a1600c065161500804512130050253f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0502000011051130501a0502405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050300000d05110050160502205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020200000642008420094200b420224402a4703c6703b6703b6703967036670326702d6702866024660216501d6501a64016640116300e6300b62007620056100361010600106000060000600006000060000600
000400000f1701e170121702217017170261701b1602c160211503115027140361402b1303a130301203e12035110001000010000100001000010000100001000010000100001000010000100001000010000100
000300002e67309670096600965008640076300662005615356003460034600346003460034600346003560035600356003560035600346003460034600336003360033600336000060000600006000060000600
00030000245700e5702d5701657034570205603b560285503f5402f520285101d5101051003510005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00020000102101221014210162101a220202202623032240322403420000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
00030000071610a1610e1611016116161221612f1602f1502c1402c1402f1302f1302c1202c1202f1102f1152c100001000010000100001000010000100001000010000100001000010000100001000010000100
0303000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
02100020017750060501775017053b655017750160500605017750060501705076053b655006050177500605017750170501775006053b655017750160500605017750060525605016053b655256050177523655
052000001d5401d5401d5301d520185401854018530185201b5301b52022540225461f5351f53016540165401d5401d5401d502135611853018530185021f561245502252016540135201d5401b5221854018540
11100000077700776007750117000777007760037510f7700a7700a7600a7500a7000a7700a7600575005740037700376003700037500c7700c7601175016770167600f771057500a77005750037510a7700a760
0e0400000c4511c0611047123071194712c0712147137071284723b0722c4723e062314523f042314323f032314223f022314223f022314123f012314123f012314123f012314123f01500400007000040000400
00040000306532405330653306103061018615376003760000654000003065424800248002480000000000003c6040c6012460113005260041a0010e0010200425001190010d00424001180010c004180010c001
02030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
051000001f47518475274752740027400244001d400264002a4001c40019400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
051000002953429554295741d540225702256018570185701856018500185701856000500165701657216562275142753427554275741f5701f5601f500135201b55135530305602454029570295602257022560
011000200a0700a0500f0710f0500a0600a040110701105007000070001107011050070600704000000000000a0700a0500f0700f0500a0600a0401307113050000000000013070130500f0700f0500000000000
052000002254022530225201b5112454024530275501f5202b5402252027550225202954029530295201651022540225302b5401b530245422453227540185301d5401d5301f5521f5421f5301d5211d5401d530
0308002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
052000200a5400a5300a5201153011520115101b5401b53018552185421853213540135401353013520135100f5400f5300f52011530115201151016542165321355013540135301352013510135101351013500
051000202e550375502e530375302e520375202e51037510225502b550225302b5301d550245501d530245301f550275501f530275301f5202752029550305502953030530295203052029510305102951030510
010600001857035572355723556235552355423553235522355153550000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
18180020297502e710297402e710297302b710297202b7102e750297102e74027750247102774024710277202e750297102e740297102e7302b7102e7202b7102e710247302b7402973029730247102974024710
5118002005570055700557005570055700000005570075700a5700a5700a570000000a570000000a5700357005570055700557000000055700557005570000000a570075700c5700c5700f570000000a57007570
030c00103b6352e6003b625000003b61500000000003360033640336303362033610336103f6003f6150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d0c002024752307132b7523071024742307002b74237700247223a7102b7223a71024712357102b712357101d75233710247523c7101d7423771024742337001d72235700247222e7101d7122e7102471237700
691800200c5700c5600c550005001157011560115500c5000c5700c5600f5710f56013570135600a5700a5600c5700c5600c550005000f5700f5600f550005000a5700a5600a5500f50011570115600a5700a560
691800200c5700c5600c55000500115701156011550005000c5700c5600f5710f56013570135600f5700f5600c5700c5700c5600c5600c5500c5300c5000c5000c5000a5000a5000a50011500115000a5000a500
1d0c002024770247702e760247502e7102e710247502e7102971029710247502971024750377003770037700227722277222765227001f7721f7721f765247002277222772227650070027772277722776500700
1d0c002024770247702e760247502e7102e710247502e71029710297102475029710247502470024700247002b7722b7722b7622b755247002470024750277002e7722e7722e7622e7522b7102b7102b7102b700
1d0c0000247702477024772247722476224752247422473224722247120070000700007000070000700007002e7002e7002e7102e710357103571033711337102b7102b7102b7102b70030710307123071230712
010c00200c7320c7320c7220c7220c7120c7120c7120c7020c7320c7320c7220c7220c7120c7120c7120c70207732077320772207722077120771207712077020a7320a7320a7220a7220a7120a7120a7120a702
000c00000c7300c7300c7200c7200c7100c7100c7103a7000c7300c7300c7200c7200c7100c7100c7103f7000a7300a7201373013720077300772007710117000a7300a7200a7103c7000f7300f7200f7103a700
120200000642008420094200b420224402a4703c6713e370396713f370366713b3702f67135360246612d3501d65123340166411f3300e63114320076210d3100361109310107000060000600006000060000600
000c00000c7300c7300c7300c7200c7200c7200c7100c7100c7100c71000700007000070000700007000070000700007000070000700007000070000700007000a7000a7000a7000a7000a7310a7300372103720
041000000c4400c4300c4200c4100f4400f4300f4200f410184401843013440134301844013440164301d45022450224502245022440224302242022410224051840018400134001340016400164001d4001d400
010c0000244752b47530475244652b46530465244552b45530455244452b44530445244352b43530435244252b42530425244152b41530415244052b40530405244052b405304053a4052e405004050040500405
031000102f65501075010753f615010753f6152f65501075010753f615010753f6152f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
010300000511007130146403f5403f5303f5203f5103f5153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
05080020247753077524745307451b765277651f7752b7751f7452b7451f7352b7351f7252b7251f7152b7151b775277751b745277451b735277351d775297751d745297451d735297351f7752b7751f7452b745
002000200c5650c5650c5550c5550c5450c5450c5350a5310f5650f5650f5550f5550f5450f5450f5351653113565135651355513555135451354513535135351352507540165701356113550135420f5600f550
00100000075750756507555075450f5650f5550c5750c5650c5550c5450c5350c52507575075650755507545075750756507555075450c5650c55511575115651155511545135651355516575165651655516545
040800201f7752b7751f7452b74518755247551b775277751b745277451877524775187452474518735247351b775277751b745277451d735297351d725297251f7752b7751f7452b7451f7352b7351b75527755
00100020115751156511555115451356513555185751856518555185451d5651d5550f5651854513575165550f5750f5650f5550f5451156511555165751656516555165451b5651b555225751f5451856513535
03100010010752f655010753f6152f6553f615010753f615010753f6152f655010752f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
031000100107501075010753f6152f6553f6153f61501075010753f615010753f6152f6553f6152f6553f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
052000002974029740297302b731297242b721297142b71133744307412e7442e73030744307302b7412b7302e7442e7402e730307312e724307212e724307212b7442e7412b7342e7212b7442b7402973129722
000800202471524715247252472524735247352474524745247552475524765247652477500705247750070524765007052476500705247550070524755007052474500705247350070524725007052471500705
000800201f7151f7151f7251f7251f7351f7351f7451f7451f7551f7551f7651f7651f775007051f775007051f765007051f765007051f755007051f755007051f745007051f735007051f725007051f71500705
040500000373005731077410c741137511b7612447030471275702e5712447030471275702e5712446030461275602e5612445030451275502e5512444030441275402e5412443030431275202e5212441030411
002000200c5750c5650c5550c5450c5350a5650a5550a5450f5750f5650f5550f5450f5350c5650c5550c5450c5750c5650c5550c5450c5350a5650a5550a5450f5750f5650f5550f5450f535115651155511545
002000001357513565135551354513535115651155511545165751656516555165451653513565135551354513575135651355513545135350f5650f5550f5450c55011531165650f54516572165520c5700c555
4d0300001f4302b43022430294301f4202b42022420294201f4102b41022410294101f4002b400224002940000400004000040000400004000040000400004000040000400004000040000400004000040000400
040b00002955500500295453057030560305551350524500245050050013505245002450500500005002450024505005000050000500005000050000500005000050000500005000050000500005000050000500
4c1000003c5753c5453c5353c5253c5153c5153c5153c5153a5753a5553a5453a5353a5253a5253a5153a51537575375553754537545375353753537525375253751537515335753355533545335353352533515
4c1000003557535555355453553535525355253057530565375553753533575335553354533535335253352529575295452953529525295152951524575245552454524545245352453524525245252451524515
000700000c05318653246440061200612000000000000000301032b1002e10035100241042b1042e1043510500603186030c601006050060324600186012460524300246033230131301303012b3010000000000
050400002f45032450314502e4502f45030450004000040001400264002f40032400314002e4002f4003040030400304000040000400004000040000400004000040000400004000040000400004000040000400
0310000003625246150060503615246251b61522625036150060503615116253361522625006051d6250a61537625186152e6251d615006053761537625186152e6251d61511625036150060503615246251d615
481000201a6101a6101a6101a61019610196101861016610126100f6100d610076100361001610006100061000610006100061003610086100c61011610126101661018610196101b6101b6101c6101c6101c610
49500000180351b0051b0251b0052403524005240051b0001803413020160101d02022035270002700027000180351b0051b0251b005240351600022000220001803413020160102202029035100001000010000
010c00001f033210313c021276003c00100604070040c0013e0043d0013c0013a0013b0013a0013900138001370013600135001340013300132001300011f00100604006010c60118601246010c6010060100605
__music__
01 554a1644
00 0a160c44
00 0a155644
00 0a0b0c44
00 14131244
00 0a160c44
00 0a160c44
02 4a111244
00 41424344
00 41424344
01 18595a44
00 18191a44
00 1c1b1a44
00 1d1b5a44
00 1f211a44
00 1f1a2144
00 1e1a2244
02 205a2444
01 41422944
00 41422944
00 6a672c44
00 6a672c44
00 6f2b2944
00 6f2b2c44
00 2f2b2944
00 2f2b2c44
00 2e2d3044
00 6e2d3044
00 34312744
02 35326744
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
01 387a7c44
00 397b7c44
01 387a3c44
02 397b3c44

