pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- the eyes watch
-- a trembling palace

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

--global tables
objects,got_fruit={},{}
destroyed=0
destm=0
exist=0

collected=false
--global timers
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
--global camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

truth_found=false
-- [entry point]

function _init()
	frames,start_game_flash=0,0
	music(30,0,7)
	lvl_id=0
end

function begin_game()
	max_djump=1
	max_pull=1
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,2,13	music(0,0,7)
	load_level(1)
end

function is_title()
	return lvl_id==0
end

-- [effects]

clouds={}
for i=0,5 do
	add(clouds,{
		x=rnd"128",
		y=rnd"128",
		spd=1+rnd"4",
	w=50+rnd"32"})
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


nx=64
ny=64
sides=5
ao=0
function ngon(x, y, r, n, col,aoff)
  line(col)         
  for i=0,n do
    local angle = i/n+aoff
    line(x + r*cos(angle), y + r*sin(angle))
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
	
	ao+=1
	if ao>360 then ao=0 end
	
	if destm>0 then destm-=1 end
	
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
	
	if lvl_id==19 then bg_col=0 end


	--move camera to 
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
		?"🅾️/❎",55,80,13
		?"veitamura",47,88,13
		?"original game by:",32,98,13
		?"maddy thorson",39,104,13
		?"noel berry",45,110,13

		-- particles
		foreach(particles,draw_particle)

		return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)

	-- bg clouds effect

	foreach(clouds,function(c)
		c.x+=0.8-cam_spdx
		ovalfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col)
		if c.x>128 then
			c.x=-c.w
			c.y=rnd"120"
		end
		
	end)
	

	-- draw ngon
	fillp(✽)
	ngon(nx,ny,40,sides,0,ao/360)
	ngon(nx,ny,35,sides,0,1-(ao/360))
	if destm>0 then
		circfill(nx,ny,1+destm,0)
	end
	fillp()
	
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
	p.x+=0.5*p.spd-cam_spdx
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
		this.immune=true
		this.djump=max_djump
		this.pull=max_pull
		this.dash_time,this.dash_effect_time=0,0
		this.dash_target_x,this.dash_target_y=0,0
		this.dash_accel_x,this.dash_accel_y=0,0
		this.hitbox=rectangle(1,3,6,5)
		this.spr_off=0
		this.collides=true
		create_hair(this)
		this.pulling=false
		this.tick=0
		exist=0
	 
		--this.ix = this.x
		--this.iy = this.y
		
		this.layer=1
	end,
	update=function(this)
		if pause_player then
			return
		end
		
		this.xs = (this.x\8)*8
		this.ys = (this.y\8)*8
		
		if exist then
			if exist>0 then
				exist-=1
			end
		end
		
	 if this.check(diamond,this.x,this.y) then
	 	cur_dia =	this.check(diamond,this.x,this.y)
			salt_mid = this.check(block,72,80)	 
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
		end
		if this.grace>0 then
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
			this.spd.x=abs(this.spd.
			x)<=1 and
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
			
				if lvl_id==17 and destroyed>=4 then
					if is_block(64,72) then
						load_level(19)
					end
				end

			-- dash
			local d_full=5
			local d_half=3.5355339059 -- 5 * sqrt(2)

			if this.pull>0 and this.pulling and dash then
					this.pull-=1		
					psfx"3"
					freeze=2
					this.pulling=false
					cur_dia.attached=false
					exist=200
					over_level(lvl_id,this.xs-this.ix,this.ys-this.iy)
			elseif this.djump>0 and dash and not this.pulling then
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
				--load_level(lvl_id)

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
		spr(65,this.x,this.y-5)
		draw_hair(this)
		draw_obj_sprite(this)

		if exist then
			if exist>0 then
				circ(this.x+4,this.y+4,exist/15,12)
		 end
		end
		if this.pulling then
			line(this.ix+4,this.iy+4,(this.x\8)*8+4,(this.y\8)*8+4,9)
			for tx=0,lvl_w-1 do
				for ty=0,lvl_h-1 do
					local tile=tile_at(tx,ty)
					if tiles[tile] and (tile==28 or tile==21) then
						xoff = this.xs-this.ix
						yoff = this.ys-this.iy
						line(tx*8+4,ty*8+4,tx*8+xoff+4,ty*8+yoff+4,14)
					end
				end
			end	
		end
		pal()
	--print(this.x,this.x,this.y)
	end
}

function create_hair(obj)
	obj.hair={}
	for i=1,7 do
		add(obj.hair,vector(obj.x,obj.y))
	end
end

function set_hair_color(djump)
	pal(8,djump==1 and 11 or djump==2 and 7+frames\3%2*4 or 12)
end

function draw_hair(obj)
	local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x+2,h.y,mid(1,2),8)
		circfill(h.x-2,h.y,mid(1,2),8)
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

function get_player()
	for o in all(objects) do
		if o.type==player_spawn then
			return o
		end
	end
end
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
		this.xw = 5
		this.yw = 10
		this.hitbox=rectangle(-1,-1,10,10)
	end,
	update=function(this)
		if this.spr==22 then
			this.offset+=0.01
			this.y=this.start+sin(this.offset)*2
			local hit=this.player_here()
			if hit and hit.djump<max_djump and not hit.pulling then
				psfx"6"
				this.init_smoke()
				hit.djump=max_djump
				this.spr=0
				this.timer=60
			end
		this.xw-=1
		this.yw-=1
		if this.xw <-5 then
			this.xw=5
		end
		if this.yw <-10 then 
			this.yw=10
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
		oval(this.x-this.xw+4,this.y-this.yw+3,this.x+this.xw+4,this.y+this.yw+3,15)
		oval(this.x-this.yw+4,this.y-this.xw+3,this.x+this.yw+4,this.y+this.xw+3,15)
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
		this.fruit=true
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
		key_tali_collected=true
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
			collected=true
		end
		if has_key or key_tali_collected then
			destroy_object(this)
		end
	end
}

chest={
	check_fruit=true,
	init=function(this)
		--this.x-=4
		this.start=this.x
		this.timer=20
	end,
	update=function(this)
		if has_key then
			this.timer-=1
			this.x=this.start-1+rnd"3"
			if this.timer<=0 and not key_tali_collected then
				init_fruit(this,0,-4)
			end
		end
		if key_tali_collected then
			destroy_object(this)
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
		this.text1="- $✽░★♪mantra -#immortal cultivation is#repentant englightenment#like tiny grains of salt#gathering to form the sea#build mountains through#repentant enlightenment#building a mountain of#salt is perhaps the fastest#way to reach the heavens#each to one another#holding hands with#everyone at the sea#drink salt#and with the wind, soar#for that is how one reaches#the peak of the mountain."
		this.text2="- like combining all intents#turns them colorless,#embrace all connections#and become impermanence.#"
		this.text3="-- ☉☉☉☉ noble truths --#should be erased."
		this.hitbox.x+=4
		this.layer=4
	end,
	draw=function(this)
		local hit=this.player_here()
		if exist>0 then 
			this.text=this.text3
		elseif hit then
			if not hit.pulling then
				this.text=this.text1
			elseif hit.pulling then
				this.text=this.text2
			end
		else
			this.text=this.text1
		end
		if hit then
			cls()
			for i,s in ipairs(split(this.text,"#")) do
				camera()
				--rectfill(7,7*i,123,7*i+6,7)
				?s,64-#s*2,7*i-1,8
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
		if lvl_id==18 then
			spr(118+frames/5%3,this.x,this.y)
		end
		if this.show and lvl_id==18 then
			camera()
			rectfill(32,2,96,50,0)
			spr(26,55,6)
			?"x"..two_digit_str(fruit_count),64,9,7
			draw_time(43,16)
			?"deaths:"..two_digit_str(deaths),48,24,7
			?"iris?",56,36,7
			?"where are you?",36,42,7
			camera(draw_x,draw_y)
		end
		if this.show and lvl_id==19 then
			camera()
			rectfill(0,0,128,128,0)
			draw_time(43,16)
			?"deaths:"..two_digit_str(deaths),48,24,7
			?"thank you, iris,",36,40,7
			?"for your collapse",32,46,7
			?"of phenomena.",40,52,7
			?"you are loved",38,90,7
			?"at the world's end",30,96,7

			camera(draw_x,draw_y)
		end
	end
}

block={
	init=function(this)
		this.solid_obj=true
		this.layer=1
		if new_load then
			this.lifespan=false
		else
			this.lifespan=200
		end
	end,
	
	update=function(this)
		if this.lifespan then
				this.lifespan-=1
				if this.lifespan<1 then 
					destroy_object(this)
				end
			end
	end,
		
	draw=function(this)
		spr(28,this.x,this.y)
	end
}

unblock={
	init=function(this)
		this.solid_obj=false
		this.immune=true
		this.layer=1
		local celx=this.x/8
		local cely=this.y/8
		if new_load then
			this.lifespan=false
		else
			this.lifespan=200
		end
		
		
		for k,o in pairs(objects) do
			if o ~=this then
				if (o.x>=this.x-2.5 and o.x<=this.x+2.5) and (o.y>=this.y-4 and o.y<=this.y+4) then
					if o.fruit then
						destroyed+=1
						key_tali_collected=true
						destroy_object(o)
						sides-=1
						destm=120
						sfx"13"
					end
					if not o.immune then
						destroy_object(o)
					end
				end
			end
		end
	end,
	
	update=function(this)
		if this.lifespan then
			this.lifespan-=1
			if this.lifespan<1 then 
				destroy_object(this)
			end
		end

		local celx=this.x/8
		local cely=this.y/8
		local tile=tile_at(celx,cely)
		if (tile>=26 and tile<=28) or tile==43 or tile==59 or tile==17 then
			mset(celx,cely,73)
		end
	end,
	
	draw=function(this)
		spr(21,this.x,this.y)
	end
}

diamond={
	init=function(this)
		this.offset=rnd()
		this.attached=false
		this.start=this.y
		this.immune=true
		this.timer=0
		this.hitbox=rectangle(-1,-1,10,10)
	end,
	update=function(this)
		if this.spr==56 then
			this.offset+=0.01
			this.y=this.start
			local hit=this.player_here()
			if hit and not hit.pulling then
				cur_dia=this
				psfx"6"
				this.init_smoke()
				hit.pull=max_pull
				this.spr=0
				this.timer=200
				hit.ix = this.x
				hit.iy = this.y
				hit.pulling=true
				this.attached=true

			end
		elseif this.timer>0 and (not this.attached) then
			this.timer-=1
		elseif this.timer>0 and this.attached then
			dummy=0	
		else
			psfx"7"
			this.init_smoke()
			this.spr=56
		end
	end,
	draw=function(this)
		if this.spr==56 then
			for i=0,0.875,0.125 do
				circfill(this.x+4+cos(frames/30+i)*3+sin(9*this.offset),this.y+4+sin(frames/30+i)*3+sin(7*this.offset)*0.5,1,10)
			end
			draw_obj_sprite(this)
		end
		if this.timer then
			if this.timer>0 then
				circ(this.x+3,this.y+3,this.timer/15,12)
		 end
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

function is_block(x,y)
	for o in all(objects) do
		if o.type==block and o.x==x and o.y==y then
			return true
		end
	end
	return false
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

function unb_overlap(o)
	if o.x == ux and o.y == uy then
		destroy_object(o)
	end
end

-- testing load without reset
function over_level(id,pxo,pyo)
	--reset camera speed
	new_load=false
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
	

		--check for mapdata strings
	if mapdata[lvl_id] then
		overlap_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
	end
	
		-- entities
	for tx=0,lvl_w-1 do
		for ty=0,lvl_h-1 do
			local tile=tile_at(tx,ty)
					if tiles[tile] and (tile==28 or tile==21) then
				init_object(tiles[tile],tx*8+pxo,ty*8+pyo,tile,true)
			
			end
		end
	end
	
end

function load_level(id)
	has_dashed = false

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
	has_key=false
	if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
	end
	--reload map
	if diff_level then
		reload()
		has_key=false
		key_tali_collected=false
		--check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
		end
	end
	
	new_load=true


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

function overlap_mapdata(x,y,w,h,data)
	for i=1,#data,2 do
		if sub(data,i,i+1) == "00" then
			mset(x+i\2%w,y+i\2\w,"0x"..sub(data,i,i+1))
			end
	end
end
-->8
-- [metadata]

--@begin
--level table
--"x,y,w,h,title"
levels={
  "0,0,1,1.4375,pLATEAU bASE",
  "1,0,1.5,1,pALACE gATE",
  "0,1,1,1,mENTAL fACTOR",
  "1,1,1,1,iMPERMANENCE",
  "0,2,1.625,1.4375,sAMSARA",
  "0,0,1,1,sHUNYATA",
  "0,0,1.3125,1.125,vIRIYA",
  "0,0,1.375,1.125,dEPTH pERCEPTION",
  "0,0,1.4375,1,lITERARY gLORY",
  "0,0,1,1.375,dOUBLE s dOUBLE s",
  "0,0,1,1.3125,tHE oBSERVER",
  "0,0,1,2,wITH THE wIND",
  "0,0,1.8125,1,rIGHT aCTION",
  "0,0,1.1875,1.625,rESOLVE",
  "0,0,1,1,sAMADHI",
  "0,0,1.5625,1.9375,fOOT OF THE tHRONE",
  "0,0,1,1,rECITATION cHAMBER",
  "0,0,1,1,pURE lAND",
  "0,0,1,1,qUEEN oF nOTHING",
  "0,0,1,1,",
  "0,0,1,1,rESPITE",
  "0,2,2,1,",
  "0,0,1,1,summit"
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
  "25254848323300000000000000000000254848330000000000000000000000002548260000000000000000000000000048483300000000005858585858003f214826001c3d000000424343434422224832482222222300000034352248484825003132324848230000000031324848253e000000314833000000000000314848222300000037000000000000000031324826000000000000000000000000000048330000000000000000000000000000260000003422234243434344000000003300000000313222222223291c00003d00000000000000313248482223000021000000000000000000244848330000240000000000000000003148260000002400000000000000000000243300000024000000000000000000003700000021483d000000000000000000000000002448230158585858585858003e00000024484822234343434343442123000000244825483329000000002a2448230000314848260000000000002148482600000024",
  "2525254848323300000000000000000000000000000000004825254826000000000062636363636363636363636364003248484848230000000000727373740000007273737400000031324848260000000000002a280000000000552900000000000031324823003f0000000028003a28390055000000000000000000313222222300000028282810282855000000000000000000000031323300000028002a2829005500000000000000000000000000000000002867585858685500000000006263640000000000000000002829002c002a5500000000007255740000000000000000002800003c00005500000000002a5529000000000000000000550d0e0e0e0f6500000000000055000000585858585858585500000000004243434343000065000100424343434343434400000000003435222222001c42434344212222223629000000000000000000314848424421222222484848330000000000000000000000003148222248484848252526000000000000000000000000000024",
  "0000000000003b314848252548483232000000000000003b3132484848330000003e0000000000000000313233000000223523000000000000001b000000000033000000000000000000000000000000290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d21000000000000000000000000000034320000000000000000000000000000000000000000000000000000006263636363000000000000003f0000000073737373000001000000002700000000002a2800001c1c000000002423000038000028004243434344000024260000000000280022222223000000242600424343434343",
  "001c1c1c1b1b3148252548332b0000001c1b1b1b00003b244848332b000000001b3d000000003b2448262b00000000002223000000003b3148262b000000003d482638000000001b31262b000000342248260000000000001b372b00000000314833000000000000001b0000000000003300000000000000000000000000000000000000000000000000000000001111111111000000000000000000001121226363636364000000000000003b3432327373737373740000000000000000000000002a2829000000000000000000003e0001002800000000000000000000002122230028003f000000000000000021484848222222222222230d0e0e0e0f2448",
  "4848323232324848324848484848262b0000000000000000000032261c1c1c1c4832003132324848262b000000000000000000000031353535353300000000003148262b000000000000000000001100000000000000000000000031332b00000000000000000000230000000000000000000000000000000000000000000000000026110000380000000011000000000000000000000000000000004823000000000011112123003e000000000000000000000000004826000000003b2122484835353522230000000000000000000048261100000011244862636363643148222300000000000000004848232b003b21487273737373737331324823000000000000002548262b003b244826282a1029280000003148230000000000002548262b003b2448262867586828000000003126000000003f002548262b003b2448262800000028111100003b242300003b21222548262b003b2448332800000028213600003b242600000031482548262b003b2426672800002122260000003b242600000000242548262b003b3133682900112448330000001124332b00000024484833000000000000000021482600000011212600000000003148260d0e0e0f34362b0011244833000011213233000000000000482600000000000000002148260000003433000000000000000042434400000000001111244833000000000000000000000000002222230001003d0021224833000000000000000000000034222248484842434343442448260000001717170000171717000031482525484848484848484826000000000000000000000000000024",
  "1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0000000000000000000000000000000000000000000000000000000000003d0022230000000000000000000000002122323236000000000000000000002132320000000000000000000000000037000000002122222300150000000000000000222232323232360000000000000000003233626363640000004243440000003f007273737373740000003133000000212300280000280000000000000000002426002800002800000000380000000031482328010028003e00000000000000004842434343434421230d0e0e0e0e0e0f4823652123652148482223000000002148482248482248484848260000002148",
  "252548484848323232323232323232323233000000484848323233000000000000000000000000000000323233000000000000000000000000000000000000000000000000000000212300000000000000002122000000000000000000244823424343434421224848000000000000000000244848230d0e0f21484848480000000000000000214848484822222248484848483d0000000000000024484848484848484848483232232b000000003e0024483232324848484848336263262b00000000212248260015003132323233727373262b00001121484832330015000000006263636363262b003b3432323300000015000000000072737373262b00000000000000000015000000000000000055262b00000000000000000015000000000000000055262b00000000000000000015000000000000380055262b0000000000003d000115000000000000000055261111000000000034222223003f00000000000055482223000000000000244848222223000000000055",
  "4826000000003d2448484848323232323232324848484833000000343532323232331b1b1b1b1b1b1b3132323300000000000000000000000000000000000000000000000000000000000000000000001111111111001a000000003d00003800000000000000274343434400003e00002122222300000000000000003122353522223535222248261c1c230000000000000000370000313300004848484848484822230000000000000000000000000048484848481548482600003f2123000000000000003448484832322248484822222248424343434344000000323233000031484848484832331b1b1b1b1b1b0000000000000000003148484826000000000000000000000000000000003800244848260000000000000000000021000000000100001c1c1c1c0d0e0f2700000000110024636400002700000031322600003b370000000027112473737421330000001b1b1b00000000001111112422485522222600000000000000000000001121222248484855484848230000000000000000002122484848482525",
  "0000000000000000000000000038000000000000000000636364000000000062636363636400000000000000000073737363636363637373737373736363636364000000002829727373737373742928002a727373737373740000002800002a282900000000283900000000002800000000002839003a28390000003a28286758585868280000000000282a2829282a675868292829000000002a2800000000004568106728000028000028393a393a393a2800000000455529002a280067286800282a292a292a292800000000555500000028002a00290045000046470000450000000055550d0e0f45000000000055000056570000550000002065650000005500000000005500424343440055003e424343233d00005500002c000065006500006500550021222222483601005500003c00424343434343434465214848484826424343434343434321222222222222222248252525254822222222222222224848484848484848482525252525",
  "25252525252525484848484833000000252525252548484832323233000008004848484848483233001111113e000038323232323226110000343535352222221b1b1b1b003123110000001515313232000000000000312300000000001515150000000000003b30000000000000001500003e0000003b301c1c0000000000000000272b00003b31231c000000002122000031232b00003b302b000000002448000000302b00003b31232b00380031483d0000302b0000003b302b000000003123000030111100003b302b000000000026000024223600003b302b000042434326000024262b00003b372b0000002a393300003133585800000000000000002a0000006862636467000000000000000000000072735573740000000000000000000000002a55295858580068626363630001000000550d0e0e0e0f72737373732223001400550000000000002a28290048424343446500000000000000280000",
  "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000390000000000000000000000000000002a393a67580000000000000000000000002829000000000000000000000000000028000000000000000000000000000067280000000000000000000000000000002800000000000000000000000000003a2900000000001c1c1c1c00000000002800000000001c28292a281c0000000029000000001c29380015382a1c00000000000000001c39000000153a1c0000003d00000000001c28013a281c00000000230000000000001c1c1c1c00000000002600002c0000000000000000000000003236003c0038000000000000000000004243434400000000000000000000000022230000000000000000000000000000",
  "483232323232330000000000000000003300000000000000000000003e00003f00000000000000003d000021222222220000160000001121222222484848484800000000003b343232323232484825250000000000000000000000003148484800000000000000000000000000313232000000000000000000000000000000000000000000000000000062636363636300000000000000000000007373737373000000000000000000000000002c28000b00000000000000000b0000003c28001c0000000000000000000000424343431c000000000000000000000028292a281c3800000000000000000000286768281c00000000000000000000002a3900281c0000000000000000000000002a392a000000000000000000000000000000390000000000000000111111000000002a110000000000003b1c1c1c2b0000000023000000000000001b1b1b0000000000261111000000000000000000000000004822360000000000000000003800000032332b00000000000000000000000000000000000000000000000000000000000b00000000000000000b0000000000000000000000000000000000000000000000000000000000000000000000626363003e0000000000000000006272737373222223000000000000007273737455294848482300013f000000002a5529650025254848222223000000000065424343",
  "48484848484832323232323232323232324832324848262b000000000048484832323300000000003800000000003015152432332b0000003d004848330000000000000000000000000000313535260000000000002122482600000000000000000000000000000000003b300000000008002448323300000000000000000000000000000000003b370d0000001111244800000000000000000000000000000000000000001b000000003422484811000000000000000000000000000000000000000000000000003132321c2b0000000000000000000000000000000000000000000000000000111c0000000000000000000000000000000000000021230000000000001c1c0000000000000000000000000000000000000031330000000000001c1c0000000011111111111111110000000000000000000000000000001c1c3800001162636363636363641111111100000000000000000038001c1c0000007273737373737373626363636400000000000000000000001c1c0001212236280000002872737373740000000000000000000000001c0000212526002800140028002800000000000000000000000000000000002125252600450d0e0f45002800004243434400000000000000000000",
  "25484848483232330000000062636363636363483232323300000000000072737373737373733300000000000000000000002a55292c002a550000000000000000000000003a55393c00212200000000000011112122222222222242434343111111000011212248323232323248484848482222230000343232330000000000313232323248261c1c1c1c0000000000000000000000000048331c1c1c1c0000000000000000000000000033000000000000151500003800000000003f00000000000000001515000000003e002122222200000000000000000000000000212248484848636364000000000000001c1c1c2448482525257374000000000000002122222248484848484855290000000000212248483232323232323232550000003b2122484832330000000000000000550000003b314848330000000000000000000055000000003b31330000000000000000000000550000000000000000000000000000000000005500000000000000000000000000000001000055000000000000000000000000000021230000290000000000000000380000000000314822220000000000000000000013450d0e0e0f31484800000000000000111111005567585858682448000000000000001c1c1c0055290000002a314800000000000000000000005500000000000024",
  "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000380000000000000000000000000000000000000038000000000000000000000000000000010000000000000000000000000000001c0000000000000000000000000000001c000038000000000000000000000000000000000000000000",
  "25254848424343434343434343434343434343440000000000254848265500000015152828002828002828290000000000004848323355003800151528280028280028280000000000000032332a39556758683911292a11292a11292a110000000014000000002a650028002a45111145111145111145002c0000212200000000000028001165424465424465424465003c00002448000000000000281121223535353535222222230d0e0e0f314800000000160028344826290000001c313232260000000000311100000000002a002448230038001c0000002423000000000023110000000000002448260000001c0000003126000000000048231100000000003148482300001c0000000031232b00002148482311000000003b2448260000000000000000302b00002425484823000000003b2448263d003e003f000000302b00002425254826000000003b2448482222223536000000302b0000242525482600001600112448484848330000000000302b0000242525482600000000214848483233000000000000302b0000312525482600000000244848330000000000000000302b0000004848483300000011244826000000000000000000372b000000483233000000002148482600000000000000000000000000003300000000001124484833000062636363636400000000000000000000001121484833000072737373737373740000004243000016000021484833000000002a28292a282900000000002a000000000024482600000000000028000028000000003f000000000000002448260000000000002867682800000021230000000000003b24483300000000003a2800002839212248330d0f000000003b2426000000003d00424343434344244833000000000000003b24330000000021231c1c1c1c1c1c3233000016003d0000003b37000000343532333a2800002a393a29000000002300011c1c00000000000000002828000000282900000000004822231c1c000000000000000028290008002800000000000048484822230000000000000000280000000028000000000000",
  "000000000000000000000000000000000000000000000000000000000000000063636363640000000000000000000000737373737374000038000000000000002a55293a29000038283800000000626339553a290000382810283800007273732a552900003828282828283800002a550055000038282810011028283800005500550038281028281c28281028380055005538282828281c001c2828282838550055282810281c1c1c1c1c281028285542434343434344424343434343441c6536424343434343444243434243434343424343434343444243434343434434354343434443434343434442434343434343434343434442434343434344424343",
  "00000000000000000000000000000000000000000000000000000000000000000000000000000000006263636400000000000000000062636373737373740000636363636363737373737373626363637273737373742a2829002a72737373732829002a2829002800000028002a2829280000002800002868106728390028002800000028003a2829002a282a39280028585858283a292800000028002a28002829002a282900280076002800002800280000002800450d0e0e0f450000283f280001002800550000000055003e282143434343434455675858685500212248353522222300552900002a552148484800002448482355000000005524484848",
  "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000535353000000000000000000000000005301530000000000000000000000000053765300000000000000000000000000535353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  [21] = "00000000002448484848482525252525000000000031323232484848484848480000000000000000003132323232323200000000000000000000000000000000000000000000000000000000464700002222223600000000000000005657000048483300000000000000002122222222323300000000000000000031484848480000000000000000000000003132324800000000002a62636429000000000031000000006872737373746700000000000000000000286758682800000000000000010000002800280028000000000000222223000042434343440000000000004848482300212222222223000000000025484848224848484848482222230000",
  [23] = "00000000000000000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000010000039000000000000000000003a00280000380000000000000000000028672800001000390000000000000000283828760028672800000000000000002a28282123283829000000000000006838282125252328393a0000000000002a28212548252523283868000058586828292425252525261028286800281028380031322525482629002a2800002a28393f2123242532332000002800000021222225263133212223283928670100312525482522222525252310382821222324252525252525482525222223"
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
	[9]=30,
	[10]=3,
	[17]=30
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
21,unblock
22,balloon
23,fall_floor
26,fruit
28,block
45,fly_fruit
56,diamond
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
00000000000000000000000008e88880000000000000000000000000000000000111111100111110000111000007707770077700111111111111111111111111
0000000008e8888008e88880ee88888808e888800888e8000000000008e8888001a1a1a1001aaa100001a1000777777677777770194949494949494949494941
00000000ee888888ee8888888e8ffff8ee88888888888ee008e88880eef1ff1801a919a1001a1a100001a1007766666667767777122222222222222222222221
000000008e8ffff88e8ffff888f1ff188e8ffff88ffff8e0ee88888888fffff8019aaa910019a9100001a1007677766676666677014211111111111111112410
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f808e8ffff888fffff80011a1110001a1000001a1000000000000000000142100000000000000001241
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800199a1000019a1000001a1000000000000000000421000000000000000000124
00000000003333000033330007000070073333000033337008f1ff10003333000019a1000001a1000001a1000000000000000000210000000000000000000012
00000000007007000070007000000000000007000000700007733370007007000111110000111100000111000000000000000000000000000000000000000001
11111111000000000000000000010000000000000e0cc0e000111100499999944999999449009094001111116665666506666660000000000000000070000000
1155551100000000000000000014101000000000ee0000ee01a1a910941111499411114994041099016777616765676566777766007700000770070007000007
150000510000000001111110001951510aaaaaa00000000019a1a9f1914114199101141940100014016556106770677067767776007770700777000000000000
15000051007000701499994100191515a998888ac000000c19a189f1441441444400014400000094016756100700070067677776077777700770000000000000
15000051007000700150051000191515a988888ac000000c19a189f1004994000440040040000040016776100700070067777676077777700000700000000000
15000051067706770015510000195151aaaaaaaa0000000019a1a9f1000000000090009000000000016556100000000067776776077777700000077000000000
11555511567656760150051000141000a980088aee0000ee01a1a910000000000000000000000000167776100000000066777766070777000007077007000070
11111111566656660015510000010000a988888a0e0cc0e000111100000000000000000000000000111111000000000006666660000000007000000000000000
511111155111111111111111111111151d666576dddddddddddddd51511111151155551111515551155515115500000000111100000000000000000000000000
1ddd55d111ddd567dddd5dddddd55d1116755d76dddddddd676665d11dddddd15155551515551510015155516670000001bb4210000777770000000000000000
16765d711d776566766556677655d6d1155dd666dddddddd7555556116776651511111155555510000155555677770001b341141007766700000000000000000
1555d761165555666655d555555d676115d66766dddddddd5ddd5d61155555d1515555151555100000015551666000001b0213b1076777000000000000000000
1dd55661155ddd55555d7ddddd5566611d667765ddddddddd66657611dddd5615155551551510000000015155500000013421331077660000777770000000000
167655611ddd6665ddd5576666d5566116776655dddddddd67765571167665615111111555100000000001556670000001343bb1077770000777767007700000
15666551166677656776556666555551167655dddddddddd6766656117655d615155551551000000000000156777700001b343b1070000000700007707777770
511111151666665566666555555dddd11665dd76dddddddd66655d611665d66111555511100000000000000166600000134434b1000000000000000000077777
1676ddd1155555d555555dddddd66661511111111111111111111115165d6761000000001000000000000001000006661bbb3b41000000000001010000000000
155567611ddddd6dd5ddd556667766511ddddddd5dddd55dddddddd116567761001111005100000000000015000777761b31b14100000000001c1c1000000010
1dd55561166666555d677d55666665d116776555556765d66755555115d567610128821055100000000001550000076613b104210000000001cdcdc100000131
177ddd511677655dd66666d55555557115555ddddd55555555ddddd1156556611280082151510000000015150000005501b1141000001000001cac10000001b1
16665551165555d5566666655ddddd711ddd567776ddddd5dd5556711d6d555112800821155510000001555100000666001142100001b10001cdcdc101001b31
1655ddd1155ddd6dd555555d555666611676d566655556755dddd5611676ddd10128821055555100001555550007777601014110011b1010001cbc1013101b10
165d776111d67766dddddddddd55551116676d5655dd555d56776d51167766610011110015551510015155510000076619112191131b11310001b10001b1b310
15d65551511111111111111111111115511111111111111111111115511111150000000011515551155515110000005501999910131331310001b10001313310
5777755700000000011111111111111111111110111111110011111111111100dddd66dd00000000000000000000000000000000000000000000000000000000
77777777000000001444444444444444444444411888888101922222222229106dd66d6d06660000000000003300000000000000000000033000000000000000
7777cc77000000001422224222222244224224411889a8811944444444444491d66dd66606000000000000032233333333333333333333322300000000000000
777ccccc0000000012244444444444444444422118a9a98114411b114fe2844166dd66dd06660000000000032223666666666666666663222300000000000000
77cccccc00a00a0014442422222422224222444118a9a9810142b22243e28410d6dd6ddd00060000000000003336777777777777777776333000000000000000
57cc77cc009aa90014224444444444444444222118a9a9810149ee9943e82410ddd6d66d06660000000000003667777777777770777777663000000000000000
577c77cc0009900014444444444442242224444112a9a9210144444443e82410d66d66dd00000000000000003677777777777706777777763000000000000000
777ccccc00000000122222442222444444424221122a9221014994a844444410d6dddddd06660000000000003677070000077000000007763000000000000000
777ccccc0000000070000000000000000000000712888821014994a8113b34100000000006060000000000003677000606670666666667763000000000000000
577ccccc000000007000000c000000000000000712888821014664a8239314b10000000006660000000000003677066706776770777777763dd0000000dddd00
57cc7ccc0000000070000000000000000000000712888821014994444444443100000000060600000000000d36770677067777700007777637ddd00dddd77d00
77cccccc0000000070c000000000000000000c0712888821014444114de5b4100000000006060000000000d73677000000007770666777763777dddd77777d00
777ccccc0000000070000000000000000000000712888821014111114de53410111111110000000000000d763677066666060000000007763777777777776d00
7777cc770000000070000000000000000000000712888821014222224d5e1410515555150600000000000d763677077777060666060607763677777677776d00
7777777700000000700000000000000000000007128888211544444444444451515555150600000000000d763677000000670707670707763667766677226d00
577775770000000070000000000000000000000712888821151999999999915151555515060000000000d7663677066606770760070707763666622222226d00
000000000000000001101101101111011011011012888821007777001000000000000001060000000000d7663677077707770076606007763666228882226d00
00aaaaaa0000000019414414414444144144149112888821070000705100000000000015066600000000d7663677000000070600060607763666228282226d00
0a99999900000000199a44a444a44a444a44a99112888821707700075510000000000155000000000000d7263677066666670766606707763662228882266d00
a99aaaaa0000000014a4aa4aaa4aa4aaa4aa4a41128888217077bb07111100000000111106660000000d76263677677777770000000007763662222222666d00
a9aaaaaa0000000014949949994994999499494118888881700bbb07555511111111555500600000000d76263677777777776666666607763266666666666d00
a99999990000000014949949994994999499494118888881700bbb0755515555555515550060000000d762223677770000000000000767763222666662666d00
a99999990000000014499949994994999499944118888881070000705515555555555155006000000d7662223677770660666660660777763288226622266d00
a9999999000000001499949994999949994999411111111100777700515555555555551500600000d76222223677770070077700700777763288226222266d00
aaaaaaaa00000000011111114444444411111110077777700111111000111000011111110000000d722288223677776076077706706777763282826288826d00
a49494a10000000014499994449999444999944170007777014bbb11014bb111014bbbb1000000d7228888223677000000000000000007763282826282826d00
a494a4a10000000014999999499999949999994170c77707142bbbb1142bbbb1142bbbb100000d76288288263677666666666666666667763628826288826d00
a49444aa0000000014999999999999999999994170777c0714111bb11411bbb1141bb1100000d7662888822633b7777777777777777777b33622226622226d00
a49999aa00000000149444999999999999444941777700071410011114101110141110000000d76222822263223bbbbbbbbbbbbbbbbbbb322322822622266d00
a494449900000000144fff444944449444fff44177700c074210000042100000421000000000d76222222663223333333333333333333332232828266266dd00
a494a4440000000014fffff444ffff444fffff4170000007410000004100000041000000000d766222266666336666666666666666666663362888226666d000
a494999900000000111111111111111111111111077777704100000041000000410000000007666222666666666666666666666666666666662222222666d000
5252848433b20000000000000000000000000000000000000000a282824284520000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52848462920000000000000000000000000000000000000000000000a24284840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8484233300a100000000000000000000000000000000000000000000001384840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
846202b1000000000000000000000000000000000000000000000000000013230000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8462b1000000000000000000000000000000000000000000000000000000b1b10000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
84620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
84330000000000000000000000000000000000000000000000060000000000930000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33b20000000000000000000000000000007171713100a3a393000000e300a3820000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
839300000000000000000000000000000000000000a38283122222320293a3830000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8293000000000000000031717171000000000000000082a213238462838282820000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
82829200c20000000000000000000000000000a30000a2008292133392a201820000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
828293f3c3d310e300000000000000000000008200000000a20000a2000021a20000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a201122232123200000000610000a3000000820000930000000000000071000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a2428462133393a3760000a3008300e3a3839300830000000000001111110000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001142528432a282920000008293829312223201a38293a3939311111222220000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a31284528462a392000000a382a282824284628282828283828212228484840000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000770000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000000000000
00060000006000000000000000000000000006660000000000003300000000000000000000033000000066000000000000000000000000000000000000000000
00000000000000000000000000000000000006000000000000032233333333333333333333322300000000770000000000007000000000000000000000000000
00000000000000000000000000000000000006660000000000032223666666666666666663222300000000770000000000000000000000000000000000000000
00000000000000000000000000000000000000060000000000003336777777777777777776333000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006660000000000003667777777777770777777663000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000003677777777777706777777763000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006660000000000003677060000077000000007763000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006060000000000003677000606670666666667763000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006660000000000003677066706776770777777763dd0000000dddd00000000000000000000000000000000000000
000000000000000000000000000000000000060600000000000d36770677067777700007777637ddd00dddd77d00000000000000000000000000000000000000
00000000000000000000000000000000000006060000000000d73677000000007770666777763777dddd77777d00000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000d763677066666060000000007763777777777776d00000000000000000000000000000000000000
0000000000000000000000000000000000000600000000000d763677077777060666060607763677777677776d00000000000000000000000000000000000000
0000000000000000000000000000000000000600000000000d763677000000670707670707763667766677226d00000000000000000000000000000000000000
000000000000000000000000000000000000060000000000d7663677066606770760070707763666622222226d00000000000000000000000000000000000000
000000000000000000000000000000000000060000000000d7663677077707770076606007763666228882226d00000000000000000000000000000000000000
000000000000000000000000000000000000066600000000d7663677000000070600060607763666228282226d00000000000000000000000000000000000000
000000000000000000000000000000000000000000000000d7263677066666670766606707763662228882266d00000000000000000000000000000000000000
00000000000000000000000000000000000006660000000d76263677677777770000000007763662222222666d00000000000000000000000000000000000000
00000000000000000000000000000000000000600000000d76263677777777776666666607763266666666666d00000000000000000000000000000000000000
0000000000000000000000000000000000000060000000d762223677770000000000000767763222666662666d00000000000000000000000000000000000000
000000000000000000000000000000000000006000000d7662223677770660666660660777763288226622266d00000000000000000000000000000000000000
00000000000000000000000000000000000000600000d76222223677770070077700700777763288226222266d00000000000000000000000000000000000000
0000000000000000000000000000000000000000000d722288223677776076077706706777763282826288826d00000000000000006600000000000000000000
000000000000000000000000000000000000000000d7228888223677000000000000000007763282826282826d00000000000000006600000000000000000000
00000000000000000000000000000000000000000d76288288263677666666666666666667763628826288826d00000000000000000000000000000000000000
0000000000007700000000000000000000000000d7662888822633b7777777777777777777b33622226622226d00000000000000000000000000000000000000
0000000000007700000000000000000000000000d76222822263223bbbbbbbbbbbbbbbbbbb322322822622266d00000000000000000000000000000000000000
0000000000000000000000000000000000000000d76222222663223333333333333333333332232828266266dd00000000000000000000000000000000000000
000000000000000000000000000000000000000d766222266666336666666666666666666663362888226666d000000000000000000000000000000000000000
0000000000000000000000000000000000000007666222666666666666666666666666666666662222222666d000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000ddddd0000d00ddddd0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000dd000dd00d00dd0d0dd000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000dd0d0dd00d00ddd0ddd000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000dd000dd00d00dd0d0dd000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000ddddd00d0000ddddd0000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000d0d0ddd0ddd0ddd0ddd0ddd0d0d0ddd0ddd0000000000000000000700000000000000000000000000
00000000000000000000000000000000000000000000000d0d0d0000d000d00d0d0ddd0d0d0d0d0d0d0000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000d0d0dd600d000d00ddd0d0d0d0d0dd00ddd0000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000ddd0d0000d000d00d0d0d0d0d0d0d0d0d0d0000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000d00ddd0ddd00d00d0d0d0d00dd0d0d0d0d0000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000dd0ddd0ddd00dd0ddd0dd00ddd0d00000000dd0ddd0ddd0ddd00000ddd0d0d000000000000000000000000000000000
00000000000000000000000000000000d0d0d0d00d00d0000d00d0d0d0d0d0000000d000d0d0ddd0d0000000d0d0d0d00d000000000000000000000000000000
00000000000000000000000000000000d0d0dd000d00d0000d00d0d0ddd0d0000000d000ddd0d0d0dd000000dd00ddd000000000000000000000000000000000
00000000000000000000000000000000d0d0d0d00d00d0d00d00d0d0d0d0d0000000d0d0d0d0d0d0d0000000d0d000d00d000000000000000000000000000000
00000000000000000000000000000000dd00d0d0ddd0ddd0ddd0d0d0d0d0ddd00000ddd0d0d0d0d0ddd00000ddd0ddd000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000ddd0ddd0dd00dd00d0d00000ddd0d0d00dd0ddd00dd00dd0dd000000000000000000000000000000000000000
000000000000000000000000000000000000000ddd0d0d0d0d0d0d0d0d000000d00d0d0d0d0d0d0d000d0d0d0d00000000000000000000070000000000000000
000000000000000000000000000000000000000d0d0ddd0d0d0d7d0ddd000000d00ddd0d0d0dd00ddd0d0d0d0d00000000000000000000000000000000700000
000000000000000000070000000000000000000d0d0d0d0d0d0d0d000d000000d00d0d0d0d0d0d000d0d0d0d0d00000000000060000000000000000000000000
000000000000000000000000000000000000000d0d0d0d0ddd0ddd0ddd000000d00d0d0dd00d0d0dd00dd00d0d00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000dd000dd0ddd0d0000000ddd0ddd0ddd0ddd0d0d00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000d0d0d0d0d000d0000000d0d0d000d0d0d0d0d0d00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000d0d0d0d0dd00d0000000dd00dd00dd00dd00ddd00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000d0d0d0d0d000d0000000d0d0d000d0d0d0d000d00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000d0d0dd00ddd0ddd00000ddd0ddd0d0d0d0d0ddd00000000000000000000000000000000000000000000
60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

__gff__
0000000000000000000000000008080804020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202020200000303030302020300020202020202000003030303020204000202020202020000030303030004040002020202020200000303030300000000020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2525484832323232323300000024252500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2548483300000000000000000031484800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848330000000000000000000000314800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4833000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
260000000000000000001c1c1c00003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26000000003f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000015243b00000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26000015001b0000003800001514000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600151c00000062636363636363640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600001a00007273737373737373737400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
260038002c00002a102900002a10292100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
260000003c000000280000000028002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26013a2123000000286758586828002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4822224826000000280000000028002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848484826003f002800003e0028344800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2225254848222342434343434343442400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
011100200177500605017750170523655017750160500605017750060501705076052365500605017750060501775017050177500605236550177501605006050177500605256050160523655256050177523655
012200001a0541a0401a0301a0201a044180401c0301d02018050180201804218040150341503015042150401a0441a0401a0521a0621a034180301c0501d0601805018020180401f0001804413020180400c500
012200001a0541a0401a0301a0201a042180401c0301d020180541802018042180401503415030150421504018064180501804018030130641305013040130301806418050180501804018040180301802018020
410400000c4501c4601047023470194702c4702147037470284703b4702c4703e460314503e440314303e430314203f420314203f420314103f410314103f410314103f410314103f40000400004000040000400
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
012200001a0541a0401a0401a0301a024180501c0501d05018054180501805018050150541505015050150501a0541a0401a0401a0301f000180641c0501d0201c0521d032180602400018074180601807018060
012200001c1701c1501c1701a165161500a1001f1721d1521a1501a1401a12016165131501310016172161521815018140181201316510150161001317213152161501614016120111650e1500f1001117211152
012200001617016150161701316516150241001f1721f1521a1501a1401a12016165131502910016172161521815018140181201316510150101001317213152101501014010130101250c1500c1400c1400c135
012200201a1701a1501a17016165131503b1001d172211521c1501c1401c1201a16516150001001c1721f1521a1501a1401a12016165131500010016172161521815018140181201316510150001001317213152
0122002015150151301512511170161601015013140161501514215142211621d1521a1401a14016130161251a1601a1501a1421d1621a15216140111301612015160151450e1600e14515160151401513000100
c5220020167501375016730137301672013720167101371016750137501673013730117500c750117300c730137500f750137300f730137200f720117500c750117300c730117200c720117100c710117100c710
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001800202945035710294403571029430377102942037710224503571022440274503c710274403c710274202e450357102e440357102e430377102e420377102e410244402b45035710294503c710294403c710
0118002005570055700557005570055700000005570075700a5700a5700a570000000a570000000a5700357005570055700557000000055700557005570000000a570075700c5700c5700f570000000a57007570
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
01 0b165644
00 11164c44
02 0c164c44
01 0c4a1644
01 120a1644
00 130a1644
00 140a1644
02 150a1644
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

