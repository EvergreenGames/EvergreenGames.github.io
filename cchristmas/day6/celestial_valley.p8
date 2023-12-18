pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--~evercore~
--a celeste classic mod base
--v2.2.0

--original game by:
--maddy thorson + noel berry

--major project contributions by
--taco360, meep, gonengazit, and akliant

--persistent palette

-- [data structures]

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

-- [globals]
	
--tables
objects={}
--timers
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
--camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

-- [entry point]

function _init()
	deaths,frames,seconds,minutes,music_timer,time_ticking,bg_col,cloud_col=0,0,0,0,0,true,0,1
	berries=0
	seeds=4
	score=0
	load_level()
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

-- [player entity]

player={
	layer=2,
	init=function(this)
		this.grace,this.jbuffer=0,0
		this.hitbox=rectangle(1,3,6,5)
		this.spr_off=0
		this.collides=true
		create_hair(this)
		
		this.work_tile=vector(0,0)
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
		elseif this.grace>0 then
			this.grace-=1
		end
		
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
		this.work_tile=vector((this.x+4)\8,this.y\8+1)
		
		if dash then
			if can_till(this.work_tile) then
				tile_set(this.work_tile,tile_at(this.work_tile)+16)
				this.init_smoke(0,4)
				sfx(10)
			elseif can_plant(this.work_tile) then
				local plant=vector(this.work_tile.x,this.work_tile.y-1)
				local plant_tile=tile_at(plant)
				if can_harvest(plant) then
					if plant_tile==194 then
						local notif=init_object(lifeup,this.x,this.y)
						notif.icon=197
						notif.amount=1
						berries+=1
						tile_set(plant,0)
						sfx(12)
					elseif plant_tile==91 then
						local amt=ceil(rnd(3))
						local notif=init_object(lifeup,this.x,this.y)
						notif.icon=198
						notif.amount=amt
						seeds+=amt
						tile_set(plant,75)
						sfx(17)
					end
					this.init_smoke(0,0)
				elseif plant_tile==0 then
					if seeds>0 then
						tile_set(plant,192)
						this.init_smoke(0,0)
						seeds-=1
						sfx(11)
					end
				end
			elseif can_sell(this.work_tile) and berries>0 then
				local notif=init_object(lifeup,this.x,this.y)
				notif.icon=199
				notif.amount=berries*10
				score+=berries
				berries=0
				sfx(18)
			elseif can_mill(this.work_tile) and berries>0 then
				local notif=init_object(lifeup,this.x,this.y)
				notif.icon=198
				notif.amount=4
				seeds+=4
				berries-=1
				sfx(19)
			end
		end
		
		-- animation
		this.spr_off+=0.25
		this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or	-- wall slide or mid air
		btn(⬇️) and 6 or -- crouch
		btn(⬆️) and 7 or -- look up
		this.spd.x~=0 and h_input~=0 and 1+this.spr_off%4 or 1 -- walk or stand

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
		set_hair_color(1)
		draw_hair(this)
		draw_obj_sprite(this)
		pal()
		
		--ui
		if this.work_tile then
			local s=0
			local plant=vector(this.work_tile.x,this.work_tile.y-1)
			
			if can_harvest(plant) then
				s=159
			elseif can_plant(this.work_tile) and tile_at(plant)==0 and seeds>0 then
			 s=143
			elseif can_till(this.work_tile) then
				s=142
			elseif can_sell(this.work_tile) and berries>0 then
				s=174
			elseif can_mill(this.work_tile) and berries>0 then
				s=175
			end
			
			--draw icon
			if s~=0 then
				spr_outline(s,this.work_tile.x*8,this.work_tile.y*8+sin(frames/30)-17,0)
			end
		end
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

-- [other objects]

player_spawn={
	layer=2,
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

spring={
	init=function(this)
		this.hide_in=0
		this.hide_for=0
	end,
	update=function(this)
		if this.hide_for>0 then
			this.hide_for-=1
			if this.hide_for<=0 then
				this.spr=18
				this.delay=0
			end
		elseif this.spr==18 then
			local hit=this.player_here()
			if hit and hit.spd.y>=0 then
				this.spr=19
				hit.y=this.y-4
				hit.spd.x*=0.2
				hit.spd.y=-3
				this.delay=10
				this.init_smoke()
				-- crumble below spring
				break_fall_floor(this.check(fall_floor,0,1) or {})
				psfx"8"
			end
		elseif this.delay>0 then
			this.delay-=1
			if this.delay<=0 then
				this.spr=18
			end
		end
		-- begin hiding
		if this.hide_in>0 then
			this.hide_in-=1
			if this.hide_in<=0 then
				this.hide_for=60
				this.spr=0
			end
		end
	end
}

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
			if hit then
				psfx"6"
				this.init_smoke()
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
			end
			-- invisible, waiting to reset
		elseif this.state==2 then
			this.delay-=1
			if this.delay<=0 and not this.player_here() then
				psfx"7"
				this.state=0
				this.collideable=true
				this.init_smoke()
			end
		end
	end,
	draw=function(this)
		spr(this.state==1 and 26-this.delay/5 or this.state==0 and 23,this.x,this.y) --add an if statement if you use sprite 0 (other stuff also breaks if you do this i think)
	end
}

function break_fall_floor(obj)
	if obj.state==0 then
		psfx"15"
		obj.state=1
		obj.delay=15--how long until it falls
		obj.init_smoke();
		(obj.check(spring,0,-1) or {}).hide_in=15
	end
end

smoke={
	layer=3,
	init=function(this)
		this.spd=vector(0.3+rnd"0.2",-0.1)
		this.x+=-1+rnd"2"
		this.y+=-1+rnd"2"
		this.flip=vector(rnd()<0.5,rnd()<0.5)
	end,
	update=function(this)
		this.spr+=0.2
		if this.spr>=32 then
			destroy_object(this)
		end
	end
}

lifeup={
	init=function(this)
		this.spd.y=-0.25
		this.duration=30
	end,
	update=function(this)
		this.duration-=1
		if this.duration<=0 then
			destroy_object(this)
		end
	end,
	draw=function(this)
		spr_outline(this.icon or 196,this.x-2,this.y-4,0)
		print_outline((this.amount>0 and "+" or "")..this.amount or "error",this.x+3,this.y-4,this.duration<4 and 1 or 7,0)
	end
}

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

message={
	layer=3,
	init=function(this)
		this.text="-- celeste mountain --#this memorial to those#perished on the climb"
		this.hitbox.x+=4
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

function psfx(num)
	if sfx_timer<=0 then
		sfx(num)
	end
end

-- [tile dict]
tiles={}
foreach(split([[
1,player_spawn
8,key
11,platform
12,platform
18,spring
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


-- [object functions]

function init_object(type,x,y,tile)
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
		return (oy>0 and not obj.is_platform(ox,0) and obj.is_platform(ox,oy)) or obj.is_flag(ox,oy,0) -- solid terrain
	end

	function obj.is_ice(ox,oy)
		return obj.is_flag(ox,oy,4)
	end
	
	function obj.is_platform(ox,oy)
		return obj.is_flag(ox,oy,3)
	end

	function obj.is_flag(ox,oy,flag)
		for i=max(0,(obj.left()+ox)\8),min(lvl_w-1,(obj.right()+ox)/8) do
			for j=max(0,(obj.top()+oy)\8),min(lvl_h-1,(obj.bottom()+oy)/8) do
				if fget(tile_at(vector(i,j)),flag) then
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

	function obj.check(type,ox,oy)
		for other in all(objects) do
			if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
				return other
			end
		end
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

-- [level functions]

function load_level()
	--remove existing objects
	objects={}

	--reset camera speed
	cam_spdx,cam_spdy=0,0

	--set level globals
	lvl_w=256
	lvl_h=16
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8
	reload()

	-- entities
	for tx=0,255 do
		for ty=0,15 do
			local tile=tile_at(vector(tx,ty))
			if tiles[tile] then
				init_object(tiles[tile],tx*8,ty*8,tile)
			end
		end
	end
	
	local respawn_pos=vector(880,56)
	init_object(player_spawn,respawn_pos.x,respawn_pos.y)
end

-- [main update loop]

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

	-- restart (soon)
	if delay_restart>0 then
		cam_spdx,cam_spdy=0,0
		delay_restart-=1
		if delay_restart==0 then
			local respawn_pos=vector(880,56)
			init_object(player_spawn,respawn_pos.x,respawn_pos.y)
			delay_restart=0
			
			if berries>0 then
				lose_items(respawn_pos)
			end
		end
	end
	
	--tick random tile
	local rand=vector(flr(rnd(256)),flr(rnd(16)))
	tick_tile(rand)
	
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
end

function lose_items(respawn_pos)
	local notif=init_object(lifeup,respawn_pos.x,respawn_pos.y)
	notif.icon=197
	notif.amount=0-berries
	berries=0
end

-- [drawing functions]

function _draw()
	if freeze>0 then
		return
	end

	-- reset all palette values
	pal()

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

	--set cam draw position
	draw_x=round(cam_x)-64
	draw_y=round(cam_y)-64
	camera(draw_x,draw_y)

	-- draw bg terrain
	map(0,0,0,0,lvl_w,lvl_h,4)
	map(0,16,1024,0,lvl_w,lvl_h,4)
	
	--set draw layering
	--0: background layer
	--1: default layer
	--2: player layer
	--3: foreground layer
	local layers={{},{},{}}
	foreach(objects,function(o)
		if o.type.layer==0 then
			draw_object(o) --draw below terrain
		else
			add(layers[o.type.layer or 1],o) --add object to layer, default draw below player
		end
	end)

	-- draw terrain
	map(0,0,0,0,lvl_w,lvl_h,2)
	map(0,16,1024,0,lvl_w,lvl_h,2)
	
	-- draw objects
	foreach(layers,function(l)
		foreach(l,draw_object)
	end)

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

	-- draw ui
	camera()
	spr_outline(197,2,2,0)
	print_outline(berries,8,2,berries>0 and 7 or 6,0)
	spr_outline(198,2,9,0)
	print_outline(seeds,8,9,seeds>0 and 7 or 6,0)
	local str=tostr(score)
	for i=0,max(0,4-#str) do
		str="0"..str
	end
	str=str.."0"
	print_outline(str,103,2,score>0 and 7 or 6,0)
	print_outline("$",99,2,score>0 and 11 or 3,0)
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

function draw_object(obj)
	(obj.type.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj)
	spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
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

function two_digit_str(x)
	return x<10 and "0"..x or x
end

-- [helper functions]

function round(x)
	return flr(x+0.5)
end

function appr(val,target,amount)
	return val>target and max(val-amount,target) or min(val+amount,target)
end

function sign(v)
	return v~=0 and sgn(v) or 0
end

function spikes_at(x1,y1,x2,y2,xspd,yspd)
	for i=max(0,x1\8),min(lvl_w-1,x2/8) do
		for j=max(0,y1\8),min(lvl_h-1,y2/8) do
			if({[17]=y2%8>=6 and yspd>=0,
					[27]=y1%8<=2 and yspd<=0,
					[43]=x1%8<=2 and xspd<=0,
					[59]=x2%8>=6 and xspd>=0})[tile_at(vector(i,j))] then
						return true
			end
		end
	end
end

-->8
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

function pal_all(col)
	for i=0,15 do
		pal(i,col)
	end
end
-->8
--new tile code

function can_harvest(pos)
	return fget(tile_at(pos),5)
end

function can_till(pos)
	return fget(tile_at(pos),6)
end

function can_plant(pos)
	return fget(tile_at(pos),7)
end

function can_sell(pos)
	local num=tile_at(pos)
	return num==105 or num==106
end

function can_mill(pos)
	local num=tile_at(pos)
	return num==177
end

function tile_at(pos)
	local x=pos.x%128
	local y=((pos.x\128)*16)+pos.y
	return mget(x,y)
end

function tile_set(pos,id)
	local x=pos.x%128
	local y=((pos.x\128)*16)+pos.y
	return mset(x,y,id)
end

function tick_tile(pos)
	local num=tile_at(pos)
	if num==192 then
		-- 1 (sprout) -> 2
		tile_set(pos,193)
	elseif num==193 then
		-- 2 -> 3 (grown)
		tile_set(pos,194)
	elseif num==75 then
		--berry bush
		tile_set(pos,91)
	end
end
__gfx__
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0004949494949494949494949494949494949494949
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000222222222222220222222222222222222222222
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a0000000000000000000000420000000000000024000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0000000000000000000004200000000000000002400
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000000000000000000042000000000000000000240
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000000000000000000420000000000000000000024
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a0000000000000000000200000000000000000000002
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0000000000000000000000000000000000000000000
555555550000000000000000000000000000000000000000008888004999999449999994499909940300b0b06665666549494949000000000000000070000000
55555555000000000000000000000000000000000000000008888880911111199111411991140919003b33006765676522222222007700000770070007000007
550000550000000000000000000000000aaaaaa00011110008788880911111199111911949400419028888206770677000024000007770700777000000000000
55000055007000700499994000000000a998888a0171711008888880911111199494041900000044089888800700070000044000077777700770000000000000
55000055007000700050050000000000a988888a0199111008888880911111199114094994000000088889800700070000044000077777700000700000000000
55000055067706770005500000000000aaaaaaaa1177711108888880911111199111911991400499088988800000000000044000077777700000077000000000
55555555567656760050050000000000a980088a1977911100888800911111199114111991404119028888200000000000044000070777000007077007000070
55555555566656660005500004999940a988888a09dd911000000000499999944999999444004994002882000000000000042000000000007000000000000000
5777777557777777777777777777777577cccccccccccccccccccc77577777755555555555555555555555555500000007777770000000000000000000000000
77777777777777777777777777777777777cccccccccccccccccc777777777775555555555555550055555556670000077777777000777770000000000000000
777c77777777ccccc777777ccccc7777777cccccccccccccccccc777777777775555555555555500005555556777700077777777007766700000000000000000
77cccc77777cccccccc77cccccccc7777777cccccccccccccccc7777777cc7775555555555555000000555556660000077773377076777000000000000000000
77cccc7777cccccccccccccccccccc777777cccccccccccccccc777777cccc775555555555550000000055555500000077773377077660000777770000000000
777cc77777cc77ccccccccccccc7cc77777cccccccccccccccccc77777cccc775555555555500000000005556670000073773337077770000777767007700000
7777777777cc77cccccccccccccccc77777cccccccccccccccccc77777c7cc77555555555500000000000055677770007333bb37070000000700007707777770
5777777577cccccccccccccccccccc7777cccccccccccccccccccc7777cccc77555555555000000000000005666000000333bb30000000000000000000077777
77cccc7777cccccccccccccccccccc77577777777777777777777775777ccc775555555550000000000000050000066603333330000000000000000000000000
777ccc7777cccccccccccccccccccc77777777777777777777777777777cc7775055555555000000000000550007777603b333300000000000ee0ee000000000
777ccc7777cc7cccccccccccc77ccc777777ccc7777777777ccc7777777cc77755550055555000000000055500000766033333300000000000eeeee000000030
77ccc77777ccccccccccccccc77ccc77777ccccc7c7777ccccccc77777ccc777555500555555000000005555000000550333b33000000000000e8e00000000b0
77ccc777777cccccccc77cccccccc777777ccccccc7777c7ccccc77777cccc7755555555555550000005555500000666003333000000b00000eeeee000000b30
777cc7777777ccccc777777ccccc77777777ccc7777777777ccc777777cccc775505555555555500005555550007777600044000000b000000ee3ee003000b00
777cc777777777777777777777777777777777777777777777777777777cc7775555555555555550055555550000076600044000030b00300000b00000b0b300
77cccc77577777777777777777777775577777777777777777777775577777755555555555555555555555550000005500999900030330300000b00000303300
5777755700000000077777777777777777777770077777700000000000000000cccccccc00000000000000000000000077777777777777777777777700000000
7777777700000000711117771111777111117777711177770000000000000000c77ccccc000000000000000000b0000077777777777777777777777700000000
7777cc770000000071cc777cccc777ccccc7771771c777170000000000000000c77cc7cc00777700000000000b30b0b0cccc7772277777722777cccc00000000
777ccccc0000000071c777cccc777ccccc777c1771777c170000000000000000cccccccc0777777777700000b223303bccccc22222277222222cc7cc00000000
77cccccc00000000717771111777111117771117777711170002eeeeeeee2000cccccccc777777777777000000323230cc77c22222222222222ccccc00000000
57cc77cc0000000077771111777111117771111777711117002eeeeeeeeee200cc7ccccce771e777e171000000032b00cc77c22222222222222ccccc00000000
577c77cc000000007111111111111111111c111771111c1700eeeeeeeeeeee00ccccc7cce7ccee7ce7cc000000b32300ccccc22222222222222ccccc00000000
777ccccc000000007111111111111111111111177111111700e22222e2e22e00cccccccce1cceeccee77c000bb3433b0ccccc22222222222222ccccc00000000
777ccccc000000007111111111111111111111177111111700eeeeeeeeeeee0000000000e1cceeeceeccc7700000000077744444444444444444477700000000
577ccccc000000007111111c111111111111111771cc111700e22e2222e22e0000000000eeeeeeeeeeee222200b0000077744444444444444444477700000000
57cc7ccc0000000071111111111cc1111111111771cc111700eeeeeeeeeeee000000000088888888888897970b30b0b0cccc4442244444422444cccc00000000
77cccccc0000000071c11111111cc11111111c1771111c1700eee222e22eee00000000008888888888889797b223303bccccc22222244222222cc7cc00000000
777ccccc000000007111111111111111111111177111111700eeeeeeeeeeee0055555555eeeeeeeeeeee111100823230cc77c22222222222222ccccc00000000
7777cc770000000071111111111111111111111771c1111700eeeeeeeeeeee0055555555200022200022222208982b00cc77c22222222222222ccccc00000000
777777770000000071111111c1111111111111177111111700ee77eee7777e0055555555016102016155510000832300ccccc22222222222222ccccc00000000
57777577000000007111111111111111111111177111c1170777777777777770555555550111000111011100bb3433b0ccccc22222222222222ccccc00000000
77cccccccccccc77711111111111111111111117711111170077770050000000000000057777cccccccc777777747777ccccc22222222222222ccccc00000000
7cccccccccccccc7711111111111111111111117711c111707000070550000000000005577cccccccccccc77774c4c77ccccc22222222222222ccccc00000000
cccccccccccccccc711111111111c1111111111771111117707700075550000000000555ccccccccccccccccccccc4ccccccc22222222222222ccccc00000000
cccccccccccccccc7111111cc1111111111111177111cc177077bb075555000000005555cccccccccccccccccccc4cccccccc22222222222222ccccc00000000
cccccccccccccccc7111111cc1111111111c11177111cc17700bbb075555555555555555ccccccccccccccccccccccccccccc22222222222222ccccc00000000
cccccccccccccccc71c11111111111111111111771c11117700bbb075555555555555555ccccccccccccccccccccccccccccc22222222222222ccccc00000000
cccccccccccccccc71111111111111111111111771111117070000705555555555555555ccccccccccccccccccccccccccccc22222222222222ccccc00000000
cccccccccccccccc07777777777777777777777007777770007777005555555555555555cccccccccccccccccccccccccccccc222222222222cccccc00000000
cccccccccccccccc07777777777777777777777007777770004bbb00004b000000400bbb00000000000000000000000000000000000000000000000000000000
cccccccccccccccc71117771111177711111777771117777004bbbbb004bb000004bbbbb00000000000000000000000000000000000000000000000000000000
cccccccccccccccc71c777ccccc777ccccc7771771c7771704200bbb042bbbbb042bbb0000000000000000000000000000000000000000000000000000000000
cccccccccccccccc71777ccccc777ccccc777c1771777c17040000000400bbb00400000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc7777111117771111177711177777111704000000040000000400000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc77711111777111117771111777711c1742000000420000004200000000000000000000000000000000000000000000000000000000000000
7cccccccccccccc77111111111111111111111177111111740000000400000004000000000000000000000000000000000000000000000000000000000000000
77cccccccccccc770777777777777777777777700777777040000000400000004000000000000000000000000000000000000000000000000000000000000000
000000007777774449449777066600004444444422000000000ff000042222400002200000ff0000000000000000000000000000000004400000044000000440
000000077777749999449977755500004f2222f422000000005555000400004000022000099ff0f0000000000000000000000000000040740000400400004444
0000077777774991194491777ddd000042f22f242200000004242420042222400002400044444444000000000000000000000000000406070050240400022200
00007777799499111999917747550000422ff2242200000004242420040000400004400002222220007777000000000000000000004060070552224000444400
00007779994991122222222729490000422ff22422000000042424200422224077044000000550000777777000000000000000000456000765552000044ff440
0007999994991222222222272214900042f22f242200000004242420040000407777770000a551111671177000000000000000004555000765555500044ff440
007979994991222777722227222199004f2222f422000000042424200422224077777770000551111661177000000000000000004650000865555000044f4440
09997994991222777777722222221190444444442200000000555500040000407777777700a55000066677700000000000000000470000000666000000444400
99999944111111117111111111111119000000000002200022000000000000000000000000055000006667000000000000000000000880000000000000000700
04412949122222222222222222222214000000000002200022000000000000000000000000055000000110000000000000000000008888000000000000007000
09411949111111111111111111111114444444204444442044444420000000000000000004444444444444400000000000000000008888003033330000006007
094129491222222222222222222222944f2224204222f4204f222420044444440000000000222222222222000000000000000000008888003333337002226670
0941294912222222222222222222229442f22420422f242042f2242004f222f4000000000005500000b550000000000000000000000880000333330722202000
09412949122444422222222224444294422f242042f22420422f242004222224000000000005500000035b000000000000000000000000000099996000022000
094129491291411222222222914112944222f4204f2224204222f42004f222f40000000000055555338288300000000000000000000880000033330000022000
09412949129141122444422291411294444444204444442044444420044444440000000000055003822222800000000000000000000880000000000000020000
09412949129141122111142291411294000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000024000
09412949129141122122242291411294000000000000000000000000000000000000000000000000000000000000000000000000000777000000000007024070
09412949129141122122292291411294000000000000000000000000000000000000000000000000000000000000000000000000000888000770544500677600
09412949129141122122242291411294000000000000007700000000000000000000000008280000000000000000000000000000000777000000422444711722
09412949129444422122242294444294000000000000077707700000000000000000000082e80000000000000000000000000000000060007704224022711744
0941294912111112212224221111129400770000000777777777000000000000000000088e800000000000000000000000000000000006000005445000677600
09412949122277772122242222222294077777000077777777777700000777700000000888200000000000000000000000000000000606000000000007042070
09412949122777777772242227772294777777707777777777777770007777770000000882000000000000000000000000000000000060000000000000042000
56666650555555554222222242222222000220004222222242222222000220000000000b0000000055b355550000000000000000000000000000000000000000
6666666156111165222222242222222400022000022222242222222000022000000000b00000000055b355550000000000000000000000080000000000000000
666666615161161500024000000000000002400000024000000240000002400008000b3000000000555b35550aa000a0000800000000008e0000000000000000
666666615116611500044000000000000004400000044000000440000004400008800bb0000000005555b55500a0baa0000e8000800000e80000000000000000
56666651776666770004400000000000000440000004400000044000000440000080033b000000005555b55500ab0aa0000880008e000b800000000000000000
555555517777777700044000000000000004400000044000000440000004400000b00033b00b00005553b5550003b0b00b00b0008e000b000000000000000000
1555555177777777000440000000000000044000000440000004400000044000000b0033b0b30000555b55550b03b0b00bb03b0b0b00b3000000000000000000
01111110777777770004200000000000000420000004200000042000000400000003b0bb30b300005555555500bb30b0b30b3b030b0b3b000000000000000000
0000000000000000000000000300b0b008000000300300000ff00000bbb000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000003b33000800000003300000ffff0000bb0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000028888200800000028820000f9ff00000bb000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000008988880000000008988000099900000bbb000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000300b0b0088889800800000028820000090000000b0000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000003b330008898880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b0000300b0b00028820002888820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b0000003b33000298882000288200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000b00b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000b33300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000822800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000008222280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000b00b0b002222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b3330008222280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b0000b00b0b00082280000677600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003300000b333000822228000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000070700000000000000000000000000000000000000000000000000000000000
10300300666011111111111111111111111111111111111111000000000000000000000000000000000000000000000000033306660666066606660666066600
10033000606011111111111111111111111111111111111111000000000000000000000000000000006000000000000000033006060606060606060606060600
10288200606011111111111111111111111111111111111111000000000000000000000000000000000000000000000000003306060606060606060606060600
10898800606011111111111111111111111111111111111111000000000000000000000000000000000000000000000000033306060606060606060606060600
10288200666011111111111111111111111111111111111111000000000000000000000000000000000000000000000000003006660666066606660666066600
10000000000011111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000
11000010000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ff000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffff00606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f9ff00606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090010666011111111111111111111111111100000000000000000000000000000600000000000000000000000000000000000000000000000000000000000
00000110000011111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
00011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
00011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
00011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
00011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
00011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
11111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
11111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000111111111111111111111111
11111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000
11111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000
11111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111100000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007700000000000000000000000000000006600000000000000000000000000000000007000000000000000000000000000000
00000000000000000000000000077707700000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007777774449449777066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000077777749999449977755500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000077777774991194491777ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077777994991119999177475500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077799949911222222227294900000000000000000000000000000000111111111111111111111111111111111111111111111111111000
00000000000000000799999499122222222227221490000000000000000000000000000000111111111111111111111111111111111111111111111111111000
00000000000000007979994991222777722227222199000000000000000000000000000000111111111111111111111611111111111111111111111111111000
00000000000000099979949912227777777222222211900000000000000000000000000000111111111111111111111111111111111111111111111111111000
00000000000000999999441111111171111111111111190000000000000000000000000000111111111111111111111111111111111111111111111111111000
00000000000000044129491222222222222222222222140000000000000000000000000000111111111111111111111111111111111111111111111111111000
00000000000000094119491111111111111111111111140000000000000000000000000000111111111111111111111111111111111111111111111111111000
00000000000000094129491222222222222222222222940000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000094129491222222222222222222222940000000000000000000000000000000000000000000000001111111111111111111111111111111111
00000000000000094129491224444222222222244442940000000000000000000000000000000000000000000000001111111111111111111111111111111111
00000000000000094129491291411222222222914112940000000000000000000000000000000000000000000000001111111111111111111111111111111111
00000000000000094129491291411224444222914112940000000000000000000000000000000000000000000000001111111111111111111111111111111111
00000000000000094129491291411221111422914112940000000042222222422222220000000000000000000000001111111111111111111111111111111117
00000000000000094129491291411221222422914112940000000002222288888882200000000000000000000000001111111111111111111111111111111177
00000000000000094129491291411221222922914112940000000000024888888888000000000000000000000000001111111111111111111111111111111177
000077000000000941294912914112212224229141129400000000000448888ffff8000000000000000000000000001111111111111111111111111111111177
00077707700000094129491294444221222422944442940770000000044888f1ff18000000b00111111111111111111111111111111111111111111111111177
07777777770000094129491211111221222422111112947777000000044888fffff000000b000111111111111111111111111111111111111000000000000073
7777777777770009412949122277772122242222222294777777000004408833334000030b003111111111111111111111111111111111111000000000000073
77777777777770094129491227777777722422277722947777777000042000700720000303303111111111111111111111111111111111111000000000000003
77777777777777777777777777777777777777777777777777777777777777777777777777777511111111111111111111111111111111111000000000000003
77777777777777777777777777777777777777777777777777777777777777777777777777777711111111111111111111111111111111111000000000000003
77777cc777777cc777777cc777777cc777777cc777777cc777777cc777777cc777777ccccc777711111111111111111111111111111111111000000000000003
c77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccccc77711111111111111111111111111111111111000000000000003
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7711111111111111111111111111111111111000000000000000
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc7711111111111111111111111111111111111000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7700000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7700000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7757777775494949494949494949494949494949494949494957
cccccccccccccccccccc77ccccccccccccccccccccccccccccccccccccccccc77cccccccccc77777777777222222222222222222222222222222222222222277
cccccccccccccccccccc77ccccccccccccccccccccccccccccccccccccccccc77cc7ccccccc777777c7777000420000002400111111111111241111112411177
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777cccc77004200000004400111111111111441111111241177
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777cccc77042000000004400111111111111441111111124177
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccc777777cc777420000000004400111111111111441111111112477
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccc77777777777200000000004400111111111111441111111111277
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7757777775000000000004200000000000000420000000000077
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6cccc777777777500000000000220000000000000022000000ff00077
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777000000000002200000000000000220000055550077
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777000000004444442000000000000240000424242077
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777111111114222f42111111111111441111424242077
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7711111111422f242111111111111441111424242077
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc771111111146f2242111111111111441111424242077
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77111111114f22242111111111111441111424242077
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77111111114444442111111111111421111055550077
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77111111114444444422111111111221115777777577
7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777111111114f2222f422111111111221117777777777
7cc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7770000000042f22f244444442000024000777c777777
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777704444444422ff2244f2224200004400077cccc7777
ccccccccccccccccc77cccccc77cccccc77cccccc77ccccccccccccccccccccccccccccccccccccccc777704f222f4422ff22442f224200004400077cccc7777
7cccccccccccccc777777cc777777cc777777cc777777cccccccccccccccccccccccccccccccccccccc7770422222442f22f24422f242000044111777cc77777
ccc7ccccccccc7777777777777777777777777777777777cccccccccccccccccccccccccccccccccccc77714f222f44f2222f44222f421111441117777777777
cccccccccccc777777777777777777777777777777777777cccccccccccccccccccccccccccccccccccc77144444444444444744444421111421115777777577
cccccccccccc77000220005555555555b355550002200077cccccccccccccccccccccccccccccccccccc77777777777777777777777777777777777777777777
cccccccccccc77000220000555555555b355550002200077ccccccccccccccccccccccccccccccccccccc777777777777777777777777777777777777777777c
ccccccc77ccc770066411111555555555b35551112411177cc7cccccccccccccccccccccccccccccccccccc777777cc777777cc777777cc777777cc777777ccc
ccccccc77ccc7700664111111555555555b5551114411177ccccccccccccccccccccccc6ccccccccccccccccc77cccccc77cccccc77cccccc77cccccc77ccccc
ccccccccccc77700044111111155555555b55511144111777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc777700044111111115555553b555111441117777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66ccccccc
ccccc7777777770004411111888855555b555511144111777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66ccccccc
cccc7777777775000421111888888555555555111421115777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc77555555550002211118788881555555551112211155b3555577cccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccc
ccc777555555500002211118888881555555511112211155b35555777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7
ccc7775555550000024000088888805555550000024000555b3555777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7
cc777755555000000440000888888055555000000440005555b5557777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc777755550000000440000088880055550000000440005555b5557777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc77755500000000440000006000055500000000440005553b555777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc7775500000000044000000600005500000000044000555b5555777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7750000000000420000006000050000000000420005555555577cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7700000000000220000006000000000000000220005555555577cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc777000000000002200000006000111111111112211115555555777cccccccccccccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc777000000000002400000006000111111111112411111555555777cccccccccccccc77cc7cccccccccccccccccccccccccccccccccccccccccccccccccccc
cc77770000000000044000000060001171711111144111111555557777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc77770000000000044000000000001199111111144111111155557777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc777000000000004400000000000117771111114411111111555777ccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc777000000000004400000000000197791111114411111111155777cccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7700000000000420000000000019dd9111111421111111111577ccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7749494949494949494949494949494949494949494949494977cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
66c777222222222222222222222222222222222222222222222222777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
66c777000000000002400000000000111111111112411111111111777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc77770000007000044000000000000000000000044000000000007777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc77770000000000044000000000000000000000044000000000007777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc777000000000004400000000000000000000004400000000000777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc777000000000004400000000000000000000004400000000000777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7700000000000420000000000000000000000420000000000077cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
00000000000000000000000a0a0a0a0a0402000000020000000000020a000000030303030303030304040402020000000303030303030303040404020202020200001313131302020302020243434302000013131313020204020222838383020303131313130004040303830303030203031313131300000000000000000000
0202020202020200020202000000000002020202020202020002020000000000020202020202020202020000000000000303020202020202020204020202000002022200000000000000000000000000020222000000800000000000000000000201010100000000000000000000000000000101020002000000000000000000
__map__
000000000000000000000000000000000000000000000000000000000000000000000000247133000000002a281028283170252525252525252525252525252525252525254825252526000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000024262900000000002a28292a3824254825252525252525252548252525252525252571323233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000008485000000000000000000002426000000000000002900002a24252525713232323270252571323232323232702526000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000008686a5a69794849600000000000000000000312600000000000000000000bb2425252526ba293aba31323233283828292900313233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000b50e0e0e0e0e0e0e0eb60000000000000000002a300000000000bb00c200bc21602525713329002a28ba282828282838000000b400b40000000000000000000000000000000000000000000000000000000000000000000000000000a5a60000000000000000000000000000000000
000000000000000000000000000000002cb40000000000000000b400000000003a39000000370000000000215c5d5e226025252526000000002a2838292a102829000000b400b4000000000000a40000000000000000a7a4a5a60000000000000000000000000000000000008081828300000000000000000000000000000000
000000000000000000000000000000bd3cb40000000000000000b4a400003a392a29000000200d0c000000246c6d6e254825252526a65b3d5b3a2829003a281000000094b4bdb40000000000a52000000000000000001c0e0e1c0000000000000000000000000000494a00009091929300000000000000000000000000000000
0000000000000000000000000000002021224c4d4d4d4d4d4d4e2223bc3a2828390000000000000000000031323270252525252561226b226b23295b3a38282900a7862122222300c2c200a52020a600000000000000b5b3b3b600000000000000000000000000a7595aa5a6a0a1a2a3a6b5b63d0000000000002c0000000000
0000000000000000000000000000002a31706c6d6d6d6d6d6d6e4861222320282900000000000000000000b40000317025252525252548252561226b23282900002122602525615c5d5d5e2223202000000000000000b4898ab400000000000000000000000b0f21696a222222222222222222230000000000003c000000003e
000000000000000000000000000000003a3132702525252571323232706123290000000000000000000000b20000b224713232323232323232323232332900003a2425252525256c6d6d6e25612320a6000000000000b4999ab4000000000000000000000000bb24482525252525252525254826200d1c0e1c0f214c4d4d4e23
00000000000000000000393ea8a900002aba283132323232331029003132330d0c00000011110000000b0e1c0e0e1c313300b4000000b4000000b400b400003a383132704825252525252525256122224c4d4d4d4d4e23b1b1880000000000000000000000bc202425252525252525252525256123009500b486246c6d6d6e26
00000000000000003a3a2820b8b90000002a2a2828ba29002a280000002a28390000000021230000000000b20000b2000000b2b3b3b3b2000000b200b20000002a2028317025252525252525252525256c6d6d6d6d6e252222224c4d4d4d4d4d4d4d4d4d4e22226025254871323232327025252526978496b420242525252526
000000000000003a282838212223000000000028290000002a28000000002a390000000024260000000000b40000b4000000b2000000b2000000b200b2000000002a2a38242525252525252525254825252525252525252525256c6d6d6d6d6d6d6d6d6d6e25252525257133b42abab431702525612222222222602525713233
0000000000003a3828292a2425260000003d5b283d0000000028395b5b3d3a283900001124260000000000b20000b20000000b0e0e0e0c0000000b0e0c0000000000002a24252525252525252525252525252525252525482525252525252525252525252525252525252629b41629b4ba242525252525252525482525262829
0000000000003a28290011244826000000216b22233f5b5b3a21226b6b232029000000216026110000000b0e0e0e0e0c000000000000000000000000000000000000000024252525252525252525252525252525252525252525252525252525252525252525252525252600b40015b42a242548252525252525252525262829
000000003a10282839002160252600000024254861226b6b22602525252629000000002448612300000000000000000000000000000000000000000000000000000000002425252548252525252525252525252525252525252525252525252525252525252548252525260e1c0e0e1c0e242525252525252525252548261000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000b5b3b3b2b3b3b600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000b5b3b3b2b3b3b6000000002c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000a8a900bd8694a75bb40000b40000b40000003d3ca5a60000000000000000b5b60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000002c0000b8b9b020b0b0216b23000b1c0c00b43d3ea5212222224c4d4d4d4d4d4d4e23200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b5b3b2b3b2b3b2b3b2b3b2b3b2b3b63f3ca4b02122222222226025260000b4000034352222602548256c6d6d6d6d6d6d6e26290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0212222226025252525482571330000b400002a28313232327025252525254825713233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0b000b0b400b0b000b0b4b000b0b024252525252571323232323300000b1c0c002a282828292a3132702525713232330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0000000b40000b00000b4000000b0242548257132332828290000000000b400003a282900003a2820242571332900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b40000000000b4000000003170252526bc002a28395b3d000000b400002123bb00002a2829242526290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b40000000000b4000000002a31702561235b5b28216b2300000b1c0c003161233f00002abb242526000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b40000000000b400000000002a242525616b6b22607133000000b700002a2426205b5b5b21602526110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b40000000000b400000000003a24252548252525252600000000000000002461226b6b6b60254861230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
910300002e620206401e650126401a615016050060501705006050170507605236050060501705006050170501705017050060523605017050160500605017050060525605016052360525605017052360500000
000400000e560155751d0001d000180001800018000180001b0001b00022000220061f0051f00016000160001d0001d0001d002130011800018000180021f001240002200016000130001d0001b0021800018000
02040000260502605027050290302c03030020340150f0000a0000a0000a0000a0000a0000a0000500005000030000300003000030000c0000c0001100016000160000f001050000a00005000030010a0000a000
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000400002863427632226351e510275402c53018500185001850018500185001850000500165001650216502275042750427504275041f5001f5001f500135001b50135500305002450029500295002250022500
11040000125511255126551265412653126521265151150007500075001150011500075000750000500005000a5000a5000f5000f5000a5000a5001350113500005000050013500135000f5000f5000050000500
13030000356472b64732647246472d647266471e6471a647226471b64714647086451e00012000120001200012000120001200012000120001200012000120001200523000240021f0021f0001d0011d0001d000
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
001000003f7703f7703f7713f7703f7703f7703f7713f7703f7713f7703f7713f7703f7713f7703f7703f7703f7713f7703f7703f7703f7503f7503f7503f7500000000000000000000000000000000000000000
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
