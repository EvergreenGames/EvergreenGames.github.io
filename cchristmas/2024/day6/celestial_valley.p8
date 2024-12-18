pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- celestial valley v2.2
-- the fishing update!
-- by petthepetra

poke(0x5f37,1)

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

respawn_pos=vector(1139,56)
flash=0

inventory={14,15}

-- [entry point]

function _init()
	deaths,frames,seconds,minutes,music_timer,time_ticking,bg_col,cloud_col=0,0,0,0,0,true,0,1
	bag=bags[14]
	bag.id=14
	score=0
	fish_count=0
	intro_timer=0
	load_level()
end

function game_intro(t)
	-- note: don't do this!!
	-- using a coroutine and
	-- a proper action sequence
	-- is far safer and smarter
	
	-- i was just lazy and
	-- hardcoded everything tehe

	--move cam
	if t<84 then
		cam_x=890+easeinoutquad(0.2+t*0.01)*260
	end
	
	-- open door
	if t==60 then
		mset(14,23,44)
		sfx(28)
	end
	
	-- player exit
	if t==80 then
		init_object(player,respawn_pos.x,respawn_pos.y)
		sfx(29)
	end
	
	-- close door
	if t==105 then
		mset(14,23,126)
		sfx(30)
	end
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

-- [level functions]

function load_level()
	--remove existing objects
	objects={}

	--reset camera speed
	cam_x,cam_y=848,64
	cam_spdx,cam_spdy=0,0

	--set level globals
	lvl_w=384
	lvl_h=16
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8
	reload()

	-- entities
	for tx=0,383 do
		for ty=0,15 do
			local tile=tile_get(tx,ty)
			if tiles[tile] and tiles[tile].spawn then
				init_object(tiles[tile].spawn,tx*8,ty*8,tile)
			end
		end
	end
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
			-- delete old player object
			for obj in all(objects) do
				if obj.type==player then
					destroy_object(obj)
				end
			end
			
			local p=init_object(player,respawn_pos.x,respawn_pos.y)
			player.center(p)
			delay_restart=0
			
			local extralife=del(inventory,1)
			if bag.fruit>0 or extralife then
				local notif=init_object(lifeup,respawn_pos.x,respawn_pos.y)
				if extralife then
					-- lose life
					notif.icon=vector(116,16)
					notif.amount=-1
				else
					-- lose items
					notif.icon=bag.fruit_icon
					notif.amount=0-bag.fruit
					bag.fruit=0
				end
			end
		end
	end
	
	-- tick random tile
	tick_tile(flr(rnd(384)),flr(rnd(16)))
	
	-- update each object
	foreach(objects,function(obj)
		obj.move(obj.spd.x,obj.spd.y);
		(obj.type.update or stat)(obj)
	end)

	-- game intro
	if in_cutscene() then
		intro_timer+=1
		game_intro(intro_timer)
		return
	end
	
	--move camera to player
	foreach(objects,function(obj)
		if obj.type==player then
			move_camera(obj)
		end
	end)
	
	score=fix_counter(score)
	fish_count=fix_counter(fish_count)
	berry_bag.seeds=fix_counter(berry_bag.seeds)
	berry_bag.fruit=fix_counter(berry_bag.fruit)
	radish_bag.seeds=fix_counter(radish_bag.seeds)
	radish_bag.fruit=fix_counter(radish_bag.fruit)
end

-- stopgap overflow protection
function fix_counter(var)
	if var<0 then
		return 32767
	end
	return var
end

-- [drawing functions]

local fadetable={
 {0,128,130,133,5,5,5,134,134,134,134,6,6,6,7},
 {1,1,5,5,13,13,13,13,13,6,6,6,6,6,7},
 {2,141,141,134,134,134,134,134,6,6,6,6,6,7,7},
 {3,3,3,3,13,13,13,13,6,6,6,6,6,7,7},
 {4,4,4,134,134,134,143,143,143,15,15,15,15,7,7},
 {5,5,134,134,134,134,134,134,6,6,6,6,6,7,7},
 {6,6,6,6,6,6,6,6,7,7,7,7,7,7,7},
 {7,7,7,7,7,7,7,7,7,7,7,7,7,7,7},
 {8,8,8,142,142,14,14,14,14,14,15,15,15,7,7},
 {9,9,9,10,10,143,143,135,135,15,15,15,15,7,7},
 {10,10,10,135,135,135,135,135,135,15,15,15,7,7,7},
 {11,11,11,11,11,138,138,6,6,6,6,6,6,7,7},
 {12,12,12,12,12,12,6,6,6,6,6,6,7,7,7},
 {13,13,13,13,6,6,6,6,6,6,6,6,7,7,7},
 {14,14,14,14,14,15,15,15,15,15,15,7,7,7,7},
 {15,15,15,15,15,15,15,7,7,7,7,7,7,7,7}
}

function fade(i)
 for c=0,15 do
  if flr(i+1)>=16 then
   pal(c,7,1)
  else
   pal(c,fadetable[c+1][flr(i+1)],1)
  end
 end
end

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
	map(0,0,0,0,128,16,4)
	map(0,16,1024,0,128,16,4)
	map(0,32,2048,0,128,16,4)
	
	--set draw layering
	--0: background layer
	--1: default layer
	--2: player layer
	--3: foreground layer
	local layers={{},{},{}}
	foreach(objects,function(o)
		if o.layer==0 then
			draw_object(o) --draw below terrain
		elseif o.type~=water then
			add(layers[o.layer or 1],o) --add object to layer, default draw below player
		end
	end)

	-- draw deco
	map(0,0,0,0,128,16,2)
	map(0,16,1024,0,128,16,2)
	map(0,32,2048,0,128,16,2)
	
	-- draw water
	foreach(objects,function(o)
		if o.type==water then
			draw_object(o)
		end
	end)
	
	-- draw terrain
	map(0,0,0,0,128,16,0x20)
	map(0,16,1024,0,128,16,0x20)
	map(0,32,2048,0,128,16,0x20)
	
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
	
	-- draw fruit
	sspr_outline(0,bag.fruit_icon.x,bag.fruit_icon.y,4,5,2,2)
	print_outline(bag.fruit,8,2,bag.fruit>0 and 7 or 6,0)
	
	-- draw seeds
	sspr_outline(0,bag.seed_icon.x,bag.seed_icon.y,4,5,2,9)
	print_outline(bag.seeds,8,9,bag.seeds>0 and 7 or 6,0)
	
	-- draw fish
	if contains(inventory,45) then
		sspr_outline(0,116,24,4,5,2,16)
		print_outline(fish_count,8,16,fish_count>0 and 7 or 6,0)
	end
	
	local str=tostr(score)
	if #str<5 then
		for i=0,max(0,4-#str) do
			str="0"..str
		end
	end
	str=str.."0"
	print_outline(str,103,2,score>0 and 7 or 6,0)
	print_outline("$",99,2,score>0 and 11 or 3,0)
	
	-- inventory
	for i=1,#inventory do
		spr_outline(inventory[i],i*11-10,118,0)
	end

	if flash>0 then
		fade(flash)
		flash=flash-1
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
			if({[105]=y2%8>=6 and yspd>=0,
					[104]=y1%8<=2 and yspd<=0})[tile_get(i,j)] then
						return true
			end
		end
	end
end

-->8
-- player

-- much of this code was rushed
-- please ignore spaghetti

player={
	init=function(this)
		this.grace,this.jbuffer=0,0
		this.hitbox=rectangle(1,3,6,5)
		this.spr_off=0
		this.collides=true
		create_hair(this)
		
		this.frozen=false
		this.ui_shake=0
		this.spr=1
		this.layer=2
		
		this.djump=1
		this.max_djump=1
		
		this.bar_size=20
		this.animation=0
		
		-- debug player, skip cutscene
		if this.x~=respawn_pos.x and this.y~=respawn_pos.y then
			end_cutscene()
			this.type.center(this)
			
			add(inventory,45)
			bag.seeds=99
		end
	end,
	center=function(this)
		cam_x,cam_y=mid(this.x+4,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
	end,
	update=function(this)
		-- jump and dash input
		local jump,dash=btn(🅾️) and not this.p_jump,btn(❎) and not this.p_dash
		this.p_jump,this.p_dash=btn(🅾️),btn(❎)
		
		local h_input=0
		local v_input=0
		
		-- movement input
		if in_cutscene() then
			-- cutscene logic
			if intro_timer>90 then
				h_input=(intro_timer<95 or intro_timer>110) and 1 or intro_timer<100 and -1 or 0
			end
		elseif not this.fishing then
			h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0
			v_input=btn(⬇️) and 1 or btn(⬆️) and -1 or 0
		end
		
		-- fish catch animation
		if this.animation>0 then
			jump,dash=false,false
			this.animation=appr(this.animation,0,1)
			if this.animation==0 then
				-- collect fish
				local icon,amt=this.fish.catch(this)
				if icon and amt then
					local notif=init_object(lifeup,this.x-1,this.y)
					notif.icon=icon
					notif.amount=amt
				end
				
				player.stop_fishing(this)
			end
		end
		
		-- fishing minigame
		if this.catch then
			if dash then
				local target=this.bar_size
				local stopped=this.catch.pos
				if abs(stopped-target)<=this.fish.mercy then
					-- catch!!!
					this.catch=nil
					this.animation=20
					sfx(34)
					return
				else
					-- failed...
					player.stop_fishing(this)
					sfx(31)
					return
				end
			end
			
			-- wait at edge
			if this.catch.wait>0 then
				this.catch.wait-=1
			else
				-- move catch
				this.catch.time=appr(this.catch.time,this.catch.target,this.fish.speed*0.02)
				this.catch.pos=easeinoutquad(this.catch.time)*this.bar_size*2
				
				-- touch edge
				if this.catch.time==this.catch.target then
					-- heat mode
					if this.fish.heat==true then
						this.catch.wait=flr(rnd(60))
					else
						this.catch.wait=30-this.fish.speed*5
					end
					
					-- reverse direction
					if this.catch.target==0 then
						this.catch.target=1
					else
						this.catch.target=0
					end
				end
			end
		end
		
		-- spike collision / bottom death
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end
		
		-- freeze in water
		if this.frozen then
			local submerged=this.check(water,0,-4)
			this.spd.y=appr(this.spd.y,submerged and -1 or 1,0.15)
			return
		elseif this.check(water,0,0) then
			this.frozen=true
			delay_restart=120
			this.spd.x=0
			
			this.spr=252
			this.layer=0
			this.init_smoke(0,0)
			sfx(31)
			return
		end

		-- on ground checks
		local on_ground=this.is_solid(0,1)

		-- landing smoke
		if on_ground and not this.was_on_ground then
			this.init_smoke(0,4)
		end

		-- jump buffer
		if jump then
			this.jbuffer=4
		elseif this.jbuffer>0 then
			this.jbuffer-=1
		end

		-- grace frames and dash restoration
		if on_ground then
			this.grace=6
			this.djump=this.max_djump
		elseif this.grace>0 then
			this.grace-=1
		end
		
		-- x movement
		local maxrun=2.0
		local accel=this.is_ice(0,1) and 0.0775 or on_ground and 0.93 or 0.80
		local deccel=0.16

		-- set x speed
		this.spd.x=abs(this.spd.x)<=maxrun and
		appr(this.spd.x,h_input*maxrun,accel) or
		appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)
		
		-- facing direction
		if this.spd.x~=0 then
			this.flip.x=this.spd.x<0
		end
		
		-- crouch
		if not in_cutscene() and not this.fishing then
			this.crouch=on_ground and v_input==1
			this.look=on_ground and v_input==-1
			if this.crouch or this.look then
				this.spd.x=0
			end
		end

		-- y movement
		local gravity=v_input==1 and 0.5 or abs(this.spd.y)>0.124 and 0.334 or 0.167
		local maxfall=v_input==1 and 5.0 or 3.0

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
			this.spd.y=appr(this.spd.y,maxfall,gravity)
		end

		-- jump
		if this.jbuffer>0 then
			if this.fishing then
				player.stop_fishing(this)
			end
			
			if this.grace>0 then
				-- normal jump
				
				this.jbuffer=0
				this.grace=0
				if this.look then
					this.spd.y=-3.9
					sfx(26)
				elseif this.crouch then
					this.spd.y=-2.9
					this.spd.x=h_input*2.1
					sfx(27)
				else
					this.spd.y=-3.36
					sfx(1)
				end
				this.init_smoke(0,4)
			else
				-- wall jump
				local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
				if wall_dir~=0 then
					sfx(2)
					this.jbuffer=0
					this.spd=vector(-wall_dir*(maxrun+1.06),-3.36)
					if not this.is_ice(wall_dir*3,0) then
						-- wall jump smoke
						this.init_smoke(wall_dir*6)
					end
				elseif this.djump>0 and contains(inventory,0) then
					-- double jump
					this.djump-=1
					this.jbuffer=0
					this.spd.y=-3.36
					sfx(37)
				end
			end
		end
		
		-- get tile reference
		this.tile_pos=vector((this.x+4)\8,this.y\8)
		this.tile=tile_get(this.tile_pos.x,this.tile_pos.y)
		local ref=tiles[this.tile]
		
		if this.fishing then
		 --nothing!
		elseif this.look then
			local new_bag=bag.id==14 and 29 or 14
			
			if dash then
				if contains(inventory,new_bag) then
					-- swap seedbags
					bag=bags[new_bag]
					bag.id=new_bag
					sfx(25)
				else
					-- does not have bag :(
					this.ui_shake=10
					sfx(5)
				end
			end
		elseif this.crouch then
			if dash then
				if bag.seeds>0 and contains(inventory,45) then
					-- consume bait
					bag.seeds-=1
					
					local notif=init_object(lifeup,this.x-1,this.y)
					notif.icon=bag.seed_icon
					notif.amount=-1
					
					-- fish
					this.fishing=true
					
					local off=this.flip.x and -5 or 12
					this.bobber=init_object(bobber,this.x+off,this.y+5)
					this.bobber.player=this
					
					sfx(32)
				else
					if contains(inventory,45) then
						local notif=init_object(lifeup,this.x+2,this.y+1)
						notif.icon=bag.seed_icon
						notif.amount=0
					end
					this.ui_shake=10
					sfx(5)
				end
			end
		elseif dash and ref then
			-- check tile condition
			local condition=true
			if ref.condition then
				condition=ref.condition()
			end
			
			-- interact with tile
			if condition==false then
				this.ui_shake=10
				sfx(5)
			elseif ref.interact then
				ref.interact(this.tile_pos.x,this.tile_pos.y,this.tile_pos.x*8,this.tile_pos.y*8)
			end
		end
		
		-- animation
		this.spr_off+=0.25
		this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or v_input==1 and 8 or 3) or	-- wall slide or mid air
		this.crouch and 6 or -- crouch
		this.look and 7 or -- look up
		sgn(this.spd.x)==-h_input and 5 or
		this.spd.x~=0 and h_input~=0 and 1+this.spr_off%4 or 1 -- walk or stand
		
		-- was on the ground
		this.was_on_ground=on_ground
		this.ui_shake=appr(this.ui_shake,0,1)
	end,
	draw=function(this)
		-- clamp in screen
		local clamped=mid(this.x,-1,lvl_pw-7)
		if this.x~=clamped then
			this.x=clamped
			this.spd.x=0
		end
		
		-- fishing graphics
		if this.fishing then
			local off=this.flip.x and -5 or 5
			spr(45,this.x+off,this.y-1,1,1,this.flip.x)
			
			if this.bobber then
				local off=this.flip.x and -5 or 12
				line(this.x+off,this.y+5,this.bobber.x,this.bobber.y,7)
			end
		end
		
		-- wing graphics
		if contains(inventory,0) then
			local sprite=this.djump>0 and 42 or 43
			local x_off=this.flip.x and 4 or -4
			local y_off=flr(this.spr)==3 and -1 or 0
			spr(sprite,this.x+x_off,this.y+y_off,1,1,this.flip.x)
		end
		
		-- minigame graphics
		if this.catch then
		
			-- bar background
			local bar_length=this.bar_size
			local bar_height=3
			
			local bar_center=this.x+3
			local bar_left=bar_center-bar_length
			local bar_right=bar_center+bar_length
			local bar_top=this.y-4-bar_height
			local bar_bottom=this.y-4

			for _y=bar_top,bar_bottom do
				line(bar_left,_y,bar_right,_y,13)
				line(bar_left,_y+1,bar_right,_y+1,1)
			end
			
			-- bar middle
			for i=0,this.fish.mercy do
				line(bar_center-i,bar_top,bar_center-i,bar_bottom,11)
				pset(bar_center-i,bar_bottom+1,3)
				
				line(bar_center+i,bar_top,bar_center+i,bar_bottom,11)
				pset(bar_center+i,bar_bottom+1,3)
			end
			
			-- catch
			local linepos=bar_left+this.catch.pos
			line(linepos,bar_top,linepos,bar_bottom,7)
			pset(linepos,bar_bottom+1,6)
		end
		
		-- fish catch animation graphics
		if this.animation>0 then
			spr(this.fish.spr,this.x,this.y-8)
			this.spr=7
		end
		
		-- draw player hair and sprite
		set_hair_color(1)
		draw_hair(this)
		draw_obj_sprite(this)
		pal()

		if this.fishing then return end
		
		-- ui
		if	this.look and this.grace~=0 then
			spr_outline(bag.id,this.x,this.y-9,this.ui_shake>0 and 2 or 0)
		elseif this.crouch and this.grace~=0 then
			spr_outline(45,this.x,this.y-9,this.ui_shake>0 and 2 or 0)
		elseif this.tile then
			-- check for tile reference
			local ref=tiles[this.tile]
			if ref then
				-- check for custom tooltip
				if ref.draw_tooltip then
					ref.draw_tooltip(this.tile_pos.x*8,this.tile_pos.y*8,this.ui_shake>0)
				elseif ref.tooltip then
					spr_outline(ref.tooltip,this.tile_pos.x*8,this.tile_pos.y*8+sin(frames/30)-9,this.ui_shake>0 and 2 or 0)
				end
			end
		end
	end,
	start_minigame=function(this,secret)
		sfx(36)
		this.spd.y=-1
		this.crouch=false
		
		this.fish=get_fish(secret)
		this.catch={
			pos=0,
			time=0,
			target=1,
			wait=0,
		}
	end,
	stop_fishing=function(this)
		this.spr=1
		this.crouch=false
		this.fishing=false
		this.fish=nil
		this.catch=nil
		if this.bobber then
			destroy_object(this.bobber)
			this.bobber=nil
		end
	end
}

function create_hair(obj)
	obj.hair={}
	for i=1,5 do
		add(obj.hair,vector(obj.x,obj.y+i))
	end
end

function set_hair_color(djump)
	pal(8,djump==1 and 8 or djump==2 and 7+frames\3%2*4 or 12)
end

function draw_hair(obj)
	local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(obj.crouch and 4 or 3))
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x,h.y,mid(4-i,1,2),8)
		last=h
	end
end
-->8
-- objects

smoke={
	init=function(this)
		this.spd=vector(0.3+rnd"0.2",-0.1)
		this.x+=-1+rnd"2"
		this.y+=-1+rnd"2"
		this.flip=vector(rnd()<0.5,rnd()<0.5)
		this.spr=26
		this.layer=3
	end,
	update=function(this)
		this.spr+=0.2
		if this.spr>=29 then
			destroy_object(this)
		end
	end
}

lifeup={
	init=function(this)
		this.spd.y=0.25
		this.duration=30
	end,
	update=function(this)
		this.duration-=1
		if this.duration<=0 then
			destroy_object(this)
		end
	end,
	draw=function(this)
		sspr_outline(0,this.icon.x,this.icon.y,4,5,this.x-2,this.y+8)
		print_outline((this.amount>0 and "+" or "")..this.amount or "error",this.x+3,this.y+8,this.duration<4 and 1 or 7,0)
	end
}

key={
	update=function(this)
		if this.player_here() then
			sfx(23)
			add(inventory,10)
			destroy_object(this)
		end
	end,
	draw=function(this)
		draw_obj_sprite(this)
	end
}

chest={
	init=function(this)
		this.x-=1
		this.y+=1
	end,
	update=function(this)
		if this.player_here() and contains(inventory,10) then
			-- get fishing rod
			del(inventory,10)
			add(inventory,45)
			this.init_smoke(0,0)
			sfx(16)
			
			destroy_object(this)
		end
	end
}

fake_wall={
	init=function(this)
		this.solid_obj=true
		this.hitbox=rectangle(0,0,16,16)
	end,
	update=function(this)
		this.hitbox=rectangle(-1,-1,18,18)
		if false then
			hit.spd=vector(sign(hit.spd.x)*-1.5,-1.5)
			hit.dash_time=-1
			for ox=0,8,8 do
				for oy=0,8,8 do
					this.init_smoke(ox,oy)
				end
			end
	end
	this.hitbox=rectangle(0,0,16,16)
	end,
	draw=function(this)
		sspr(40,112,8,16,this.x,this.y)
		sspr(40,112,8,16,this.x+8,this.y,8,16,true,true)
	end
}

message={
	init=function(this)
		this.text="-- celestial valley --#this memorial to those#buried under the snow"
		this.hitbox.x+=4
		this.layer=3
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
		this.x+=3
	end,
	draw=function(this)
		spr(58+frames/5%3,this.x,this.y)
	end
}

meteor={
	init=function(this)
		this.spd.x=rnd(8)-4
		this.spd.y=4
		this.size=3+flr(rnd(10))
		sfx(20)
	end,
	update=function(this)
		if this.is_solid(0,0) then
			init_object(snowball,this.x,this.y+4)
			for i=0,this.size do
				init_object(snowball,this.x,this.y)
			end
			sfx(21)
			destroy_object(this)
		elseif this.y>128 then
			--oob
			destroy_object(this)
		else
			-- check to kill player
			local hit=this.player_here()
			if hit then
				-- lmao gottem
				kill_player(hit)
			end
		end
	end,
	draw=function(this)
		spr(24,this.x,this.y)
	end
}

snowball={
	init=function(this)
		this.hitbox=rectangle(2,2,4,4)
		this.spd=vector(rnd(3)-1.5,-1-rnd(3))
	end,
	update=function(this)
		this.spd.y+=0.2
		if this.is_solid(0,0) then
			local _x=this.x\8
			for _y=0,16 do
				if can_plant(_x,_y) then
					local t=tile_get(_x,_y)
					tile_set(_x,_y,t-16)
					tile_set(_x,_y-1,11)
					break
				end
			end
			sfx(22)
			this.init_smoke()
			destroy_object(this)
		elseif this.y>128 then
			--oob
			destroy_object(this)
		end
	end,
	draw=function(this)
		spr(25,this.x,this.y)
	end
}

water={
	init=function(this)
		this.tx=this.x\8
		this.ty=this.y\8
		
		-- search for water endcap
		-- 128 is search distance cap
		for i=1,128 do
			local t=tile_get(this.tx+i,this.ty)
			if t==74 then
				this.hitbox.w=8+(i*8)
				break
			end
		end
		
		this.hitbox.h=(lvl_h*8)-this.y
		layer=4
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
			local rx,ry=raw_pos(this.x,this.y+i)
			
			-- math hell
			tline(this.x+round(sin(i/16+time()*0.5)),this.y+i,w,this.y+i,
				rx/8,ry/8,0.125,0,2)
		end
		
		pal()
		line(this.x,this.y-1,this.x+this.hitbox.w-1,this.y-1,7)
		line(this.x,this.y,this.x+this.hitbox.w-1,this.y,0)
	end
}

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
				if fget(tile_get(i,j),flag) then
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
				for i=1,abs(amt) do
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
		init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),26)
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
-->8
-- tiles

tiles={
	[1]={
		spawn=player,
	},
	[9]={
		spawn=chest,
	},
	[10]={
		spawn=key,
	},
	[229]={
		spawn=fake_wall,
	},
	[122]={
		spawn=message,
	},
	[58]={
		spawn=flag,
	},
	[73]={
		spawn=water,
	},
	[54]={
		-- bush
		tick=function(tx,ty)
			tile_set(tx,ty,38)
		end,
	},
	[38]={
		-- berry bush
		tooltip=15,
		interact=function(tx,ty,x,y)
			-- get seeds
			local amt=ceil(rnd(3))
			local notif=init_object(lifeup,x,y)
			notif.icon=berry_bag.seed_icon
			notif.amount=amt
			berry_bag.seeds+=amt
			
			-- harvest plant
			sfx(17)
			tile_set(tx,ty,54)
			init_object(smoke,x,y)
		end
	},
	[39]={
		-- berry 1
		tick=function(tx,ty)
			tile_set(tx,ty,40)
		end,
	},
	[40]={
		-- berry 2
		tick=function(tx,ty)
			tile_set(tx,ty,41)
		end,
	},
	[41]={
		-- berry 3
		tooltip=15,
		interact=function(tx,ty,x,y)
			-- get berry
			local notif=init_object(lifeup,x,y)
			notif.icon=berry_bag.fruit_icon
			notif.amount=1
			berry_bag.fruit+=1
			
			-- harvest plant
			sfx(12)
			tile_set(tx,ty,13)
			init_object(smoke,x,y)
		end
	},
	[55]={
		-- radish 1
		tick=function(tx,ty)
			tile_set(tx,ty,56)
		end,
	},
	[56]={
		-- radish 2
		tick=function(tx,ty)
			tile_set(tx,ty,57)
		end,
	},
	[57]={
		-- radish 3
		tooltip=15,
		interact=function(tx,ty,x,y)
			-- get berry
			local notif=init_object(lifeup,x,y)
			notif.icon=radish_bag.fruit_icon
			notif.amount=1
			radish_bag.fruit+=1
			
			-- harvest plant
			sfx(12)
			tile_set(tx,ty,13)
			init_object(smoke,x,y)
		end
	},
	[11]={
		-- snow tile
		tooltip=13,
		condition=function()
			return contains(inventory,13)
		end,
		interact=function(tx,ty,x,y)
			-- clear snow
			local tile=tile_get(tx,ty+1)
			tile_set(tx,ty+1,tile+16)
			tile_set(tx,ty,13)
			
			sfx(10)
			init_object(smoke,x,y)
		end,
	},
	[13]={
		-- dirt tile
		condition=function()
			return bag.seeds>0
		end,
		interact=function(tx,ty,x,y)
			tile_set(tx,ty,bag.plant_tile)
			init_object(smoke,x,y)
			bag.seeds-=1
			sfx(11)
		end,
		draw_tooltip=function(x,y,failed)
			spr_outline(bag.id,x,y+sin(frames/30)-9,failed and 2 or 0)
		end,
	},
	[32]={
		-- car
		tooltip=30,
		condition=function() 
			return bag.fruit>0
		end,
		interact=function(tx,ty,x,y)
			-- sell fruit
			local value=bag.fruit*bag.value
			local notif=init_object(lifeup,x,y)
			notif.icon=vector(112,24)
			notif.amount=value*10
			score+=value
			bag.fruit=0
			sfx(18)
		end,
	},
	[120]={
		-- penguin
		tooltip=21,
		condition=function() 
			return fish_count>0
		end,
		interact=function(tx,ty,x,y)
			-- sell fruit
			local value=fish_count*2
			local notif=init_object(lifeup,x,y)
			notif.icon=vector(112,24)
			notif.amount=value*10
			score+=value
			fish_count=0
			sfx(39)
		end,
	},
	[34]={
		-- mill
		tooltip=31,
		condition=function() 
			return bag.fruit>0
		end,
		interact=function(tx,ty,x,y)
			local notif=init_object(lifeup,x,y)
			local modifier=bag.id==14 and ceil(rnd(2)) or 0
			local amt=2+modifier
			notif.icon=bag.seed_icon
			notif.amount=amt
			bag.seeds+=amt
			bag.fruit-=1
			sfx(19)
		end,
	},
	[36]={
		-- terminal
		condition=function() 
			return score>=100
		end,
		interact=function(tx,ty,x,y)
			-- buy map expansion
			local notif=init_object(lifeup,x,y)
			notif.icon=vector(112,24)
			notif.amount=-1000
			score-=100
			expand_map()
			flash=16
			sfx(24)
		end,
		draw_tooltip=function(x,y,failed)
			print_outline("$1000",x-2,y+sin(frames/30)-17,score>=100 and 11 or 8,failed and 2 or 0)
		end,
	},
	[239]={
		-- shovel
		interact=function(tx,ty,x,y)
			-- pickup shovel
			mset(26,9,0)
			add(inventory,13)
			sfx(13)
		end,
		draw_tooltip=function(x,y,failed)
			print_outline("❎",x,y+sin(frames/30)-6,7,0)
		end,
	},
	[47]={
		-- radish seedbag
		interact=function(tx,ty,x,y)
			-- pickup seedbag
			mset(22,27,118)
			add(inventory,29)
			sfx(13)
		end,
		draw_tooltip=function(x,y,failed)
			print_outline("❎",x,y+sin(frames/30)-6,7,0)
		end,
	},
}

function can_till(x,y)
	return fget(tile_get(x,y),6)
end

function can_plant(x,y)
	return fget(tile_get(x,y),7)
end

function tile_get(tx,ty)
	local x=tx%128
	local y=((tx\128)*16)+ty
	return mget(x,y)
end

function raw_pos(local_x,local_y)
	local x=local_x%1024
	local y=((local_x\1024)*128)+local_y
	return x,y
end

function tile_set(tx,ty,id)
	local x=tx%128
	local y=((tx\128)*16)+ty
	return mset(x,y,id)
end

function tick_tile(tx,ty)
	local num=tile_get(tx,ty)
	
	if tiles[num] and tiles[num].tick then
		tiles[num].tick(tx,ty)
	end
	
	-- meteor spawn
	if ty==0 and num==0 and flr(rnd(256))==0 and not in_cutscene() then
		init_object(meteor,tx*8,-32)
	end
end
-->8
-- seedbags

bags={
	[14]={
		name="berry",
		plant_tile=39,
		fruit=0,
		seeds=0,
		value=1,
		fruit_icon=vector(104,24),
		seed_icon=vector(108,24),
	},
	[29]={
		name="radish",
		plant_tile=55,
		fruit=0,
		seeds=0,
		value=4,
		fruit_icon=vector(120,24),
		seed_icon=vector(124,24),
	},
}

berry_bag=bags[14]
radish_bag=bags[29]
-->8
-- fishing

pools={
	common={
		"fish",
	},
	uncommon={
		"seed_box",
		"berry",
		"trash",
	},
	rare={
		"seed_barrel",
		"radish",
		"treasure",
	},
	epic={
		"orb",
		"goldfish",
		"diamond",
	},
	legendary={
		"adelie",
		"meteor",
	},
	mythic={
		"1-up"
	}
}

function get_fish(mythic)
	local pool=random_pool()
	if mythic then pool=pools.mythic end
	local index=pool[ceil(rnd(#pool))]
	return fish[index]
end

function random_pool()
	local rng=rnd(1)
	if rng<=1/512 then
		return pools.legendary
	elseif rng<=1/128 then
		return pools.epic
	elseif rng<=1/32 then
		return pools.rare
	elseif rng<=1/8 then
		return pools.uncommon
	else
		return pools.common
	end
end

fish={
	["fish"]={
		spr=21,
		mercy=6,
		speed=2,
		heat=true,
		catch=function(player)
			fish_count+=1
			-- return icon, amount
			return vector(116,24),1
		end,
	},
	["goldfish"]={
		spr=52,
		mercy=8,
		speed=4,
		heat=true,
		catch=function(player)
			fish_count+=10
			-- return icon, amount
			return vector(116,24),10
		end,
	},
	["seed_box"]={
		spr=100,
		mercy=5,
		speed=1,
		heat=false,
		catch=function(player)
			local amt=4+ceil(rnd(4))
			radish_bag.seeds+=amt
			-- return icon, amount
			return radish_bag.seed_icon,amt
		end,
	},
	["seed_barrel"]={
		spr=68,
		mercy=3,
		speed=1,
		heat=false,
		catch=function(player)
			local amt=16+ceil(rnd(16))
			radish_bag.seeds+=amt
			-- return icon, amount
			return radish_bag.seed_icon,amt
		end,
	},
	["berry"]={
		spr=22,
		mercy=12,
		speed=3,
		heat=false,
		catch=function(player)
			berry_bag.fruit+=1
			-- return icon, amount
			return berry_bag.fruit_icon,1
		end,
	},
	["radish"]={
		spr=23,
		mercy=6,
		speed=3,
		heat=false,
		catch=function(player)
			radish_bag.fruit+=1
			-- return icon, amount
			return radish_bag.fruit_icon,1
		end,
	},
	["treasure"]={
		spr=9,
		mercy=2,
		speed=2,
		heat=false,
		catch=function(player)
			local amt=flr(10+rnd(10))
			score+=amt
			
			-- return icon, amount
			return vector(112,24),amt*10
		end,
	},
	["diamond"]={
		spr=12,
		mercy=1,
		speed=1,
		heat=false,
		catch=function(player)
			local amt=flr(100+rnd(100))
			score+=amt
			
			-- return icon, amount
			return vector(112,24),amt*10
		end,
	},
	["orb"]={
		spr=0,
		mercy=0.5,
		speed=0.2,
		heat=true,
		catch=function(player)
			if contains(inventory,0) then
				local amt=100
				score+=amt
				
				-- return icon, amount
				return vector(112,24),amt*10
			else
				add(inventory,0)
				sfx(33)
			end
		end,
	},
	["trash"]={
		spr=26,
		mercy=16,
		speed=1,
		heat=false,
		catch=function(player)
			-- poof
			init_object(smoke,player.x,player.y-8)
		end,
	},
	["adelie"]={
		spr=120,
		mercy=8,
		speed=8,
		heat=false,
		catch=function(player)
			-- easter egg
			init_object(adelie,player.x,player.y-7)
		end
	},
	["meteor"]={
		spr=24,
		mercy=12,
		speed=4,
		heat=true,
		catch=function(player)
			-- lmfao gottem
			local reward=init_object(meteor,player.x,player.y-7)
			reward.spd.x=0
		end,
	},
	["1-up"]={
		spr=69,
		mercy=20,
		speed=1,
		heat=false,
		catch=function(player)
			add(inventory,1)
			-- return icon, amount
			return vector(116,16),1
		end
	}
}

bobber={
	init=function(this)
		this.layer=0
		this.hitbox.w=3
		this.hitbox.h=5
		this.touched_water=false
		this.caught=false
	end,
	update=function(this)
		-- bob
		if this.caught then
			return
		end
	
		-- count down fishing timer
		if this.wait_time then
			this.wait_time-=1
			if this.wait_time<=0 then
				player.start_minigame(this.player,this.y>30000)
				this.caught=true
				this.spd.y=0
				return
			end
		end
		
		-- bobber physics
		local submerged=this.check(water,0,0)
		if submerged then
			if not this.touched_water then
				this.spd.y=0.8
				this.touched_water=true
			end
			
			this.spd.y=appr(this.spd.y,-0.4,0.1)
		elseif this.touched_water then
			-- float on surface
			this.spd.y=0
			this.wait_time=ceil(rnd(120))
		else
			-- initial fall
			this.spd.y=appr(this.spd.y,5,0.1)
		end
		
		-- bobber collision
		if this.is_solid(0,0) then
			this.init_smoke()
			this.player.fishing=false
			destroy_object(this)
		end
		
		-- bobber oob
		if this.y>30000 then
			this.spd.y=0
			this.wait_time=1
		end
	end,
	draw=function(this)
		sspr(112,16,3,8,this.x-1,this.y+1)
	end
}

adelie={
	init=function(this)
		this.spd.x=-1
		this.spd.y=-2.6
	end,
	update=function(this)
		this.spd.y=appr(this.spd.y,4,0.2)
		if this.y>lvl_ph then
			destroy_object(this)
		end
	end,
	draw=function(this)
		spr(121,this.x,this.y)
	end
}
-->8
-- misc

function in_cutscene()
	return intro_timer<120
end

function end_cutscene()
	intro_timer=120
end

function expand_map()
	mset(91,22,119)
	mset(92,21,82)
	for obj in all(objects) do
		if obj.type==fake_wall then
			destroy_object(obj)
		end
	end
	map_expanded=true
	
	-- remove terminal functions
	tiles[36]=nil
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

function sspr_outline(l_col,sx,sy,sw,sh,dx,dy)
  -- draw sprite with outline
  pal_all(l_col)
  for _x=-1,1 do
    for _y=-1,1 do
      sspr(sx,sy,sw,sh,dx+_x,dy+_y)
    end
  end
  pal()
  sspr(sx,sy,sw,sh,dx,dy)
end

function contains(tbl,item)
	for v in all(tbl) do
		if v==item then 
			return true 
		end
	end
	
	return false
end

function pal_all(col)
	for i=0,15 do
		pal(i,col)
	end
end

-- cartid #easingcheatsheet
function easeinoutquad(t)
	if(t<.5) then
		return t*t*2
	else
		t-=1
		return 1-t*t*2
	end
end
__gfx__
00777700000000000000000008888880000000000000000000000000000000000888888000000000000000000000000000000000000004400000044000000700
0700007008888880088888808888888808888880088888000000000008888880888888880aaaaaa0000000000000000000000000000040040000444400007000
707700078888888888888888888ffff888888888888888800888888088f1ff18888ffff8a998888a000000000000000000777760005024040002220000006007
7077bb07888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff888fffff8a988888aaaa90000000000000c77777c055222400044440002226670
700bbb0788f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff808f1ff10aaaaaaaaa09a0000000000000ccc7c7665552000044ff44022202000
700bbb0708fffff008fffff00033330008fffff00fffff8088fffff80833338000333300a980088aa00aaaaa0000000000c7777065555500044ff44000022000
07000070003333000033330007000070073333000033337008f1ff100033330000070070a988888aa09a099a00000000000c770065555000044f444000022000
0077770000700700007000700000000000000700000070000773337000700700000000000aaaaaa0aaa9090a077777700000c000066600000044440000020000
000000000000000000ff0000000000000000b000000600000300b0b00b00b0b000777700000000000000000000000000700000000ff000000000000000024000
0000000000000000099ff0f0000000000000500000066000003b330000b333000777677000000000007700000770070007000007ffff00000000000007024070
007777000000000044444444000000000000500060ddd5d002888820008228007777777700077000007770700777000000000000004440000770544500677600
07777777777000000222222000777700000777006ddd5d5d0898888008222280777776770077770007777770077000000000000000ffff000000422444711722
77777777777700000005500007777770007777706ddd5ddd088889800222222077677777007777000777777000007000000000000ff22ff07704224022711744
e771e777e171000000a55111167117700777776660ddddd0088988800822228077777777000770000777777000000770000000000ff22ff00005445000677600
e7ccee7ce7cc000000055111166117700711176600060600028888200067760007776770000000000707770000070770070000700fff2ff00000000007042070
e1cceeccee77c00000a550000666777007111766000000000028820000066000007777000000000000000000700000000000000000ffff000000000000042000
e1cceeeceeccc7700005500000666700077777660000000000000000000000000000000000000000000000000000000021111422000004400500088022000000
eeeeeeeeeeee22220005500000011000066666660000055000b00000000000000000000000000000777770000000000021111422000040747770888822000000
8888888888889797044444444444444055555555500050500b30b0b00000000000000000000000000766770000000000211119220004060788808ff822000000
888888888888979700222222222222000111111100058282b223303b00000000000000000000000000777670000000002111142200406007777003302ff00000
eeeeeeeeeeee11110005500000b5500000ddddd0005066660082323000000000000000000300b0b00006677000777770211114220456000706007007fff4f000
20002220002222220005500000035b0000ddddd00050666608982b000000000000000000003b33000007777007677770211114224555000700600000f24ff200
016102016155510000055555338288300777777700578282008323000000b0000300b0b000288200000000007700000021111422465000086060000022ff22f0
011100011101110000055003822222807777777777778282bb3433b0000b0000003b33000298882000000000000000007771142247000000060000002fffffff
76666666666666666666666777777777000000007774777700000000000000000000000000000000004aaa00004a000000400aaa30030ff0bbb000d0300b0440
7555555555555555555555571177217700999000774c4c7700b00000000000000000000000000000004aaaaa004aa000004aaaaa0330ffffbb000ddd0b304444
c5555555555555555555555cc774477c00099900ccccc4cc0b30b0b000000000000000000000000004200aaa042aaaaa042aaa002882f9ff0bb01dd128824244
cc55555555555555555555cc77c477cc909aaaa0cccc4cccb223303b000000000000000000000000040000000400aaa00400000089889990bbb00ddd67762222
cccccccccccccccccccccccc1112211199aa9a9acccccccc0032323000000000000000000b00b0b0040000000400000004000000288209000b0010d006600220
cccccccccccccccccccccccc1112111199aa9aaacccccccc00032b00000000000000000000b33300420000004200000042000000000000000000000000000000
cccccccccccccccccccccccc11111111909aa9a0cccccccc00b323000000b0000b0000b000822800400000004000000040000000000000000000000000000000
cccccccccccccccccccccccc7777777700090900ccccccccbb3433b00003300000b3330008222280400000004000000040000000000000000000000000000000
42222222422222224222222200022000000ff0000777777007777770000000000000000088888880088888880000000000000000000000000000000000000000
0222222422222224222222200002200000555500bb7777bb77777777000000000000000088888880088888880000000000000000000000000000000000000000
00024000000000000002400000024000042424207bb77bb7777777770aa000a00008000088822200002228880000000000000000000000000000000000000000
000440000000000000044000000440070424242067bbbb767777337700a0baa0000e800088222000000222880082800000000000000000777000000000000000
0004400000000000000440000004477704242420663bb3667777337700ab0aa0000880008822000000002288082e800000000000000007777700000000000000
000440000000000000044000000477770424242063333336737733370003b0b00b00b000882000000000028888e8000000770000000777777770000000000000
0004400000000000000440000077777704242420041441407333bb370b03b0b00bb03b0b88000000000000888882000007777700007777777777700000077770
000420000000000000042000077777770055550000ffff000333bb3000bb30b0b30b3b0300000000000000008820000077777770777777777777770000777777
0002200042222222000220000002200000022000000000000333333000000000000000000000000000000000b000000000000000777777444944977706660000
00022000222222240002200000022000444444420000000003b333300000000000ee0ee0000000000000000b0000000000000007777774999944997775550000
000240000002400000024000000240004d4dd44200000000033333300000000000eeeee000000030008000b3000000000000077777774991194491777ddd0000
000440000004400000044000000440004ddd0d42000000000333b33000000000000e8e00000000b0008800bb0000000000007777799499111999917747550000
000440000004400000044000770440004d4dd44200000000003333000000b00000eeeee000000b3000080033b000000000007779994991122222222729490000
00044000000440000004400077777700444444420444444000044000000b000000ee3ee003000b00000b00033b00b00000079999949912222222222722149000
00044000000440000004400077777770000220000002200000044000030b00300000b00000b0b3000000b0033b0b300000797999499122277772222722219900
00042000000420000004000077777777000220000002200000999900030330300000b0000030330000003b0bb30b300009997994991222777777722222221190
55555555555555555555555555b35555000000000002200022000000000000006665666500000000000000000000000099999944111111117111111111111119
55555555555555500555555555b35555000000000002200022000000000000086765676500000000000000000000000004412949122222222222222222222214
555555555555550000555555555b35554444442044444420444444200000008e6770677000000000000000000000000009411949111111111111111111111114
5555555555555000000555555555b5554f2224204222f4204f222420800000e80700070000700070000000000000000009412949122222222222222222222294
5555555555550000000055555555b55542f22420422f242042f224208e000b8007000700007000700002eeeeeeee200009412949122222222222222222222294
5555555555500000000005555553b555422f242042f22420422f24208e000b000000000006770677002eeeeeeeeee20009412949122444422222222224444294
555555555500000000000055555b55554222f4204f2224204222f4200b00b300000000005676567600eeeeeeeeeeee0009412949129141122222222291411294
555555555000000000000005555555554444442044444420444444200b0b3b00000000005666566600e22222e2e22e0009412949129141122444422291411294
5555555550000000000000055555555500000000444444442200000000000000000000001011110100eeeeeeeeeeee0009412949129141122111142291411294
55555555550000000000005550555555000000004f2222f42200000000000000000000001171711100e22e2222e22e0009412949129141122122242291411294
550000555550000000000555555500550000000042f22f242200000050000000001111001199111100eeeeeeeeeeee0009412949129141122122292291411294
5500005555550000000055555555005504444444422ff2242200000000000000017171100177711000eee222e22eee0009412949129141122122242291411294
5500005555555000000555555555555504f222f4422ff2242200000000000000019911100177711000eeeeeeeeeeee0009412949129444422122242294444294
550000555555550000555555550555550422222442f22f242200000000000000117771110177711000eeeeeeeeeeee0009412949121111122122242211111294
5555555555555550055555555555555504f222f44f2222f4220000000077700019779111019dd91100ee77eee7777e0009412949122277772122242222222294
555555555555555555555555555555550444444444444444220000007777770009dd911000900900077777777777777009412949122777777772242227772294
00000000000000000000000000000026061700002706160000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000026061727270607160000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000002706060616161600000000000000000000f4d4e4000000000000000000f4d4e4f400000000000000000000000000000000
00000000000000000046000000000000000000170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000270616260616000000000000000000000000f46f7f8fe400000000000000d46f7f9cacacbc0000000000000000000000000000
000000f4c400f444475766c40000000000000006c400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002617271645c400000000000000000000f46f7f7fcfccdc1414ecec14fccf7f7f9eaeaebe000000f4c4000000000000000000
000000edececececececececed0000000000279cbc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
141424000000000000000000550055260617348fe400000000640000edfc9fafbf9cbcce000000000000009cbc1d2d3dcf860000f46f8fe4d4e4000000006400
f4d4e405000000000000000034e475000000cf9ebee4c40000000000000000000000000000000000000000000000000000000000000000270000000000000000
00000500000000000000000056f45766261d2d2d3d000075f465c400050000cf0c9ebe00000000000000009ebe1e2e3e860000f46f7f7f7f2d3d0000000065d4
6f7f8f35b0b0b0b0b0b0b0b01d2d3d0000001d2d2d3d7fe485000000000000000000000000000000000000001700000000a6b600000000060000000000000000
d4e4050000000000000000edececececfc1f4d2e3e00000c1d2d3d000500961d2d2d3d000000000000000000261f2f3f0000001d2d2d2d2d5d3fdcececfc1d2d
2d7f7f2d6c7c7c7c7c7c7c8c4c5d3f0000001f4d4e5c2d2d3d000000000000000000000000000000000000000600002700a7b78517000006a300000000000000
2d3d050000000000000000050000000000261e5d3f0000251e2e3e9405a41d4c2e2e3e960000000000000096270616160000001f2f4d4e2e3e16000000001f2f
4d2d2d4e6e7e7e7e7e7e7e8e5d3f0500c4f4051f4d4e2e5d3f000000000000d4e400000000000000000000f406000006d41d2d3d06f4c4064f00000000000000
2e3e4fb0b0b0b0b0b0b0b00500000000f4cf1e3e940000a41e2e5c3d56f41e5d2f4d5c3d00000000000000cf070617d4e4000000001f2f2f3f00000000000026
1f2f2f2f4d4e2e2e5d2f2f2f3f1415ececec15141e2e5d3f250000f400009cacbcc40000004455000000009cbce4d49cbc1f2f3f0c9cacbc4f960000a0000000
4e5c2d6c7c7c7c7c7c7c8c3d969696961d2d4c3ec400471d4c2e2e5c2d2d4c3e861e4e3e940000000000a41d2d2d7f7f8fc40000008686868600002131000000
260616161f2f2f2f3f07162616002500000005001e2e3e00000000cc00009dadbd9cbc009faf33bf0000279dbd9fbf9ebe9cacacbc9dadbd9cbc1700cc000000
2e2e2e6e7e7e7e7e7e7e8e3e4f4f4f4f1e4e2e5c2d2d2d4c5d2f4d2e2e2e2e3e001f4d3ec40000000000001e2e2e2d7f7f7fe485000000000000002232c40000
00060000000586862626000000000000000005f41e2e3e94000000ce00009eaebe9ebe009fafafbf0000269ebecf9cacbc9eaeaebe9dadbd9ebe1600ce0000a4
2e2e2e2e4e2e2e2e2e2e2e5c2d2d2d2d4c2e2e2e2e2e2e5d3f861e2e2e2e5d3f00861e5c3d0017000057661e2e4e2e7f7f7f7f3d0000000000f4d4ffff8fe455
00160095d435b0b0b0b0b0b0b0b0b0b0b0b0341d4c2e3e14240000000000cf9cacbc000000000000000000269fbf9dadbdcf169fbf9eaebecc16000025000000
2e2e2e2e2e5d2f2f4d2e4e2e2e2e2e2e2e2e2e2e2e2e4e3e00001f4d4e2e3e0500001e2e3e27060004ec1d4c2e2e2e2d7f7f2d3e00cf0000006f7f7f7f7f7f8f
0000001d2d2d6c7c7c7c7c7c7c7c7c7c7c8c2d4c2e2e5c3d151424000000009eaebe0000000000000000000026169eaebe1600269fbf9cbcce00000000000000
2e2e2e2e5d3f86271f2f2f4d2e2e2e4e2e2e2e2e2e2e2e3ee400251e4d2e3e2500851e2e5c3d2617051d4c4e2e2e2e2e2d2d2e3e9400000000269fbf9cbccf16
0000a41f4d2e6e7e7e7e7e7e7e7e7e7e7e8e4e2e2e2e2e5c2d2d3dc400000000000000000000000000000000000026cf2600000026269ebe1600000000000000
2e2e2e4e3e8600263616261e2e2e2e2e2e2e2e2e4e2e2e5c3d00001e2e2e3e00001d4c2e4e5c2d2d2d4c2e2e2e2e2e2e2e2e2e5c3d000000000000269ebe1600
00001d3d1e2e4e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e5c3d000000000000000000000000000000000000001600000000000026160000000000000000
5777777557777777777777777777777577cccccccccccc7777777777777777777777777777777777777777777777777777777777494949494949494949494949
777777777777777777777777777777777cccccccccccccc777777777777777777777777771111777111177711111777771117777222222222222222222222222
777c77777777ccc7777777777ccc7777cccccccccccccccccccc7772277777722777cccc71cc777cccc777ccccc7771771c77717000420000000000000024000
77cccc77777ccccc7c7777ccccccc777ccccccccccccccccccccc22222277222222cc7cc71c777cccc777ccccc777c1771777c17004200000000000000002400
77cccc77777ccccccc7777c7ccccc777cccccccccccccccccc77c22222222222222ccccc71777111177711111777111777771117042000000000000000000240
777cc7777777ccc7777777777ccc7777cccccccccccccccccc77c22222222222222ccccc77771111777111117771111777711117420000000000000000000024
77777777777777777777777777777777ccccccccccccccccccccc22222222222222ccccc7111111111111111111c111771111c17200000000000000000000002
57777775577777777777777777777775ccccccccccccccccccccc22222222222222ccccc71111111111111111111111771111117000000000000000000000000
57777775577777777777777777777775cccccccccccccccc77744444444444444444477771111111111111111111111771111117494949494949494949494949
77777777777777777777777777777777cccccccccccccccc7774444444444444444447777111111c111111111111111771cc1117022222222222222222222220
777777777777ccccc777777ccccc7777cccccccccccccccccccc4442244444422444cccc71111111111cc1111111111771cc1117000000000002400000000000
777cc777777cccccccc77cccccccc777ccccccccccccccccccccc22222244222222cc7cc71c11111111cc11111111c1771111c17000000000004400000000000
77cccc7777cccccccccccccccccccc77cccccccccccccccccc77c22222222222222ccccc71111111111111111111111771111117000000000004400000000000
77cccc7777cc77ccccccccccccc7cc77cccccccccccccccccc77c22222222222222ccccc71111111111111111111111771c11117000000000004400000000000
77c7cc7777cc77cccccccccccccccc777cccccccccccccc7ccccc22222222222222ccccc71111111c11111111111111771111117000000000004400000000000
77cccc7777cccccccccccccccccccc7777cccccccccccc77ccccc22222222222222ccccc7111111111111111111111177111c117000000000004200000000000
77cccc7777cccccccccccccccccccc77cccccccc57777557ccccc22222222222222ccccc71111111111111111111111771111117777777776000000000044000
777ccc77777cccccccccccccccccc777c77ccccc77777777ccccc22222222222222ccccc711111111111111111111117711c1117777777776600000000400400
777ccc77777cccccccccccccccccc777c77cc7cc7777cc77ccccc22222222222222ccccc711111111111c1111111111771111117777777775660000000444400
77ccc7777777cccccccccccccccc7777cccccccc777cccccccccc22222222222222ccccc7111111cc1111111111111177111cc17777117775566000000022000
77ccc7777777cccccccccccccccc7777cccccccc77ccccccccccc22222222222222ccccc7111111cc1111111111c11177111cc17771111775556600000022000
777cc777777cccccccccccccccccc777cc7ccccc57cc77ccccccc22222222222222ccccc71c11111111111111111111771c1111777111177c555660000022000
777cc777777cccccccccccccccccc777ccccc7cc577c77ccccccc22222222222222ccccc7111111111111111111111177111111771111117cc55566006555560
77cccc7777cccccccccccccccccccc77cccccccc777ccccccccccc222222222222cccccc7777777777777777777777777777777771111117ccc5556606555560
777ccc7777cccccccccccccccccccc7756666650777ccccc0777777777777777777777707777777777777777777777777777777771111117cccc555655555555
777cc77777cccccccccccccccccccc7766666661577ccccc7777777777777777777777777111777111117771111177777111777771111117ccccc55556111165
777cc77777cc7cccccccccccc77ccc776666666157cc7ccc77777777777777777777777771c777ccccc777ccccc7771771c7771771111117cccccc5551611615
77ccc77777ccccccccccccccc77ccc776666666177cccccc77777777777777777777777771777ccccc777ccccc777c1771777c1771111117ccccccc551166115
77cccc77777cccccccc77cccccccc77756666651777ccccc7777777777777777777777777777111117771111177711177777111771111117cccccccc77666677
77cccc777777ccccc777777ccccc7777555555517777cc7777777777777777777777777777711111777111117771111777711c1771111117cccccccc77777777
777cc77777777777777777777777777715555551777777777777777777777777777777777111111111111111111111177111111771111117cccccccc77777777
5777777557777777777777777777777501111110577775777777777777777777777777777777777777777777777777777777777771111117cccccccc77777777
__label__
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000
00000000001111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000
00000000001111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000
00000000001111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000
00000000001111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000
00000000001111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000001111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000001111111111111111111111111
16111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111
1111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000001111494949491111111111111
11111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000055550000001111222222221111111111111
11111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000424242000001111111241111111111111111
11111111111110000000000000000000000000007000000000000000000000000000000000000000000000000000424242000001111111441111111111111111
11111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000424242000001111111441111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000424242000001111111441111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000424242000001111111441111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055550000000000000420000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000494949494949494949494949494949490000000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222222222022222222222222220000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000240000000000000000000000240000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000440000000000000000000000440000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000440000000000000000000000440000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000440000000000000000000000440000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000440000000000000000000000440000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000420000000000000000000000420000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200000ff000000000000000220000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000099ff0f000000000000220000000000000000
11111111111111111111111111111111111000000000000000000000000000000000000000000000000000240004444444400000000000240000000000000000
11111111111111111111111111111111111000000000000000000000000000000000000000000000000000440000222222000777700000440000000000000000
11111111111111111111111111111111111000000000000000000000000000000000000000000000000000440000005500007777770000440000000000000000
111111111111111111111111111111111110000000000000000000000000000000000000000000000000004400000a5511116711770000440000000000000000
11111111111111111111111111111111111000000000000000000000000000000000000000000000000001441111115511116611771111441111111711110000
111111111111111111111111111111111110000000000000000000000000000000000000000000000000014111111a5511116667771111421111111111110000
11111111111111111111111111111111111000000000000000000000000000000000000000000000066001221111115511111666711111221111111111110000
11111111111111111111111111111111111000000080000000000000000000000000000000000000066001221111115511111111111111221111111111110000
000000000000000000000000000000000000000008e0000000000000000000000000000000000000000001241111444444444444441111241111111111110000
00000000000000000000000000000000000800000e80000000000000000000000000000000000000000001441111122222222222211111441111111111110000
000000000000000000000000000000000008e000b800000000000000000000000000000000000000000001441111115511111b55111111441111111111110000
000000000000000000000000000000000008e000b000000000000000000000000000000000000000000001441161115511111135b11111441111111111110000
000000000000000000000000000111111111b11b311111111111111b111111111111310b0b000000000001441111115555533828831111441111111111110000
000000000000000000000000000111111111b1b3b1117777771111b111117777771113b330007777770000420000005500382222280000400000000000000000
00050000000000000000000000011111115577777777777777744444444777777774444444477777777777777755555555555555555000220000000000000011
00055000000000000000000000011111155777777777777777744444444777777774444444477777777777777775611116556111165000220000000000000011
000555000000000000000000000111115557777cccccccc77722444444227777772244444422777cccccccc77775161161551611615000240000000000000011
00055550000000000000000000011115555777cccccccccc222222442222227722222244222222cc7ccccccc7775116611551166115000440000000000000011
0005555500000000000000000001115555577cccccccc77c222222222222222222222222222222ccccccccccc777766667777666677770440000000000000011
0005555550000000000000000001155555577cc77cccc77c222222222222222222222222222222cccccccc7cc777777777777777777777777000000000000011
0005555555000000000000000001555555577cc77ccccccc222222222222222222222222222222ccccccccccc777777777777777777777777700000000000000
0005555555500000000000000005555555577ccccccccccc222222222222222222222222222222ccccccccccc777777777777777777777777770000000000000
0055777777555555555555555555555555577ccccccccccc222222222222222222222222222222ccccccccccccc7777777777777777777777777777777549494
15577777777555555555555555555555555777cccccccccc222222222222222222222222222222cccccc77ccccc7777777777777777777777777777777722222
555777c7777555555555555555555111155777cccccccccc222222222222222222222222222222cccccc77cc7ccc777777cc777777cc777777ccccc777700042
55577cccc775555555555555555550000557777ccccccccc222222222222222222222222222222cccccccccccccccc77cccccc77cccccc77cccccccc77700420
55577cccc775555555555555555550000557777ccccccccc222222222222222222222222222222ccccccccccccccccccccccccccccccccccccccccccc7704200
555777cc777555555555555555555000055777cccccccccc222222222222222222222222222222ccccccc7cccccccccccccccccccccccccccccccc7cc7742000
55577777777555555555555555555555555777cccccccccc222222222222222222222222222222cccccccccc7cccccccccccccccccccccccccccccccc7720000
5555777777555555555555555555555555577cccccccccccc2222222222222222222222222222cccccccccccccccccccccccccccccccccccccccccccc7700000
7777767777555555555000000005555555577cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7750000
7777777777755555550000000000555555577ccccccccccccccccccccccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7755000
77ccccc777755555500000000000055555577cc7cccccccccccccccccccc77cc7ccccccccccccccccccccccccccccccccccccccccccccccccccc77ccc7755500
cccccccc77755555000000000000005555577ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccc7755550
ccccc6ccc77555500000000000000005555777ccc77ccc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77cccccccc77755555
cccccc7cc775550000000000000000005557777cc77c777777ccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccc777777ccccc777755555
ccccccccc7755111111111111111111115577777777777777777cccccccccccc7ccccccccccccccccccccccccccccccccccccccccc7777777777777777755555
ccccccccc77511111111111111111111115577777777777777777cccccccccccccccccccccccccccccccccccccc7ccccccccccccc77777777777777777555555
ccccccccc771111111111111111111111115555555555b3555577cccccccccccccccccccccccccccccccccccccccccccccccccccc7755b355555555555555555
cccccccc7771111111111111111111111111555555555b3555577cccccccccccccccccccccccccccccccccccccccccccccccccccc7755b355555555555115555
cccccccc77711111111111111111111111111555555555b355577cc7cccccccccccccccccccccccccccccccccccccccccccc77ccc77555b35555555551111555
ccccccc7777111111111111111111111111111555555555b55577ccccccccccccccccccccccccccccccccccccccccccccccc77ccc775555b5555555511111155
ccccccc7777000000000000000000000000000055555555b555777cccccccc77cccccc77cccccc77cccccc77cccccc77cccccccc7775555b5555555111111115
cccccccc777117711111111111111111111111115555553b5557777ccccc777777cc777777cc777777cc777777cc777777ccccc77775553b5555551111111111
cccccccc77717777711111111111111111111111155555b555577777777777777777777777777777777777777777777777777777777555b55555500000000000
ccccccccc77777777711111111111111111111111155555555557777777777777777777777777777777777777777777777777777775555555555000000000000
ccccccccc7777777775111111111111111111111111555555555555555555b355555555555500000000000000000000000055555555555555555000000000000
cccccccccc777777777111111111111111111111111555555500555555555b355555555555000000000000000000000000005555555055555555500000000000
ccccccccccccccc77771111111111111111111111115555550000555555555b35555555550000000000000000000000000000555555005555555550000000000
cccccccccccccccc77711111111111111111111111155555000000555555555b5555555500000000000000000000000000000055555000555555555000000005
ccccccccccccccccc7700000000000000000000000055550000000055555555b5555555000000000000000000000000000000005555000055555555500000055
cccccccccccccc7cc7700000000000000000000000055500000000005555553b5555550000000000000000000000000000000000555000005555555550000555
ccccccccccccccccc770000000000000000000000005500000000000055555b55555500000000000000000000000000000000000055000000555555555005555
ccccccccccccccccc770000000000000000000000005000000000000005555555555000000000000000000000000000000000000005000700055555555555555
ccccccccccccccccc770000000000000000000000000000000000000000555555550000000000000000000000000000000000000000000000005555555555555
cccccccccccccccc7770000000000000000000000000000000000000000055555550000000000000000000000000000000000000000000000000555555555555
cccccccccccccccc7770000000000080000000000000000000000000000005555550000000000000000000000000000000000000000000000000055555555555
ccccccccccccccc777770000000000e8000000000000000000000007000000555550000000000000000000000000000000000000000000000000005555555555
ccccccccccccccc77777700000000088000000000000000000000000000000055550000000000000000000000000000000000000000000000000000555555555
cccccccccccccccc777777000000b00b000000000000000000000000000000005550000000000000000000000000000000000000000000000000000055555555
cccccccccccccccc777777770000bb03b0b000000000000000000000000000000550000000000000000000000000000000000000000000000000000005555555
ccccccccccccccccc7777777700b30b3b03000000000000000000000000000000050004400000000000000000000000000000000000000000000000000555555
ccccccccccccccccc777777777777777775777777770000000000022000000000000040740000000000000000000000000000000000000000000000000555555
cccccccccccccccccc77777777777777777711177770000000044444442000000000406070000000000000000000000000000000000000000000000005550555
cccccccccccccccccccc777777ccccc777771c77717000000004d4dd442088888884060070000000000000000000000000000000000000000000000055555550
cccccccccccccccccccccc77cccccccc77771777c17000000004ddd0d42888888888600070000000000000000000000000000000000000000000000555555550
ccccccccccccccccccccccccccccccccc7777771117111111114d4dd4428888ffff8500070000000000000000000000000000000000000000000005555555555
cccccccccccccccccccccccccccccc7cc7777711c171111111144444442888fffff8000070000000000000000000000000000000000000000000055555555055
ccccccccccccccccccccccccccccccccc77711111171111111111122111188f1ff10000070000000000000000000000000000000000000000000555555555555
ccccccccccccccccccccccccccccccccc77777777771111111111122111117733370000070000000000000000000000000000000000000000005555555555555
ccccccccccccccccccccccccccccccccc77777777777777777777777777777777770000070000000000000000007777777777777777777777775777777777777
cccccccccccccccccccccccccccccccc777711177711111777111772177111177770000070000000000000000007111777111117771111177777777777777777
cccccccccccccccccccccccccccccccc77771c777ccccc777ccc774477cccc7771700000700000000000000000071c777ccccc777ccccc777177777ccccc7777
ccccccccccccccccccccccccccccccc777761777ccccc777ccc77c477cccc777c1700000700000000000000000071777ccccc777ccccc777c17777c77ccccc77
ccccccccccccccccccccccccccccccc77777777111117771111111221111777111700000500000000000000000077771111177711111777111777cc77ccccccc
cccccccccccccccccccccccccccccccc7777771161177711111111211117771111700007770000000000000000077711111777111117771111777cc77ccccccc
cccccccccccccccccccccccccccccccc7777111111111111111111111111111111700008880000000000000000071111111111111111111111777cc77ccccccc
ccccccccccccccccccccccccccccccccc777777777777777777777777777777777777777777777777777777777777777777777777777777777777ccccccccccc
ccccccccccccccccccccccccccccccccc775777777777777775000000000000000000000000000000000000000000000000000000005777777577ccccccccccc
cccccccccccccccccccc77cccccccccc77777777777777777771111111111110011111111111111111111111111111100111111111177777777777cccccc77cc
cccccccccccccccccccc77cc7ccccccc7777777cccccccc777711111111111100111111111111111111111111111111001111111111777c7777777cccccc77cc
ccccccccccccccccccccccccccccccc7777777cccccccccc7771111111111110011111111111111111111111111171100111111111177cccc777777ccccccccc
ccccccccccccccccccccccccccccccc777777cccccccccccc771111111111110011111111111111111111111111111100111111111177cccc777777ccccccccc
ccccccccccccccccccccc7cccccccccc77777cc77ccccc7cc7711111111111100111111111111111111111111111111001111111111777cc777777ccccccc7cc
cccccccccccccccccccccccc7ccccccc77777cc77cccccccc771111111111100111111111111111111111111111111001111111111177777777777cccccccccc
ccccccccccccccccccccccccccccccccc7777cccccccccccc77111111111110011111111111111111111111111111100111111111115777777577ccccccccccc
ccccccccccccccccccccc6ccccccccccc7777cccccccccccc77577777751110011111111111111111111110011111100111577777777777777777ccccccccccc
cccccccccccccccccccccccccccccccc77777cccccccccccc7777777777110011111111111111111111100001111100111177777777777777777cccccccccccc
cccccccccccccccccccccccccccccccc77777cc7cccc77ccc77777c777711001111111111111111111100000011110011117777ccccc777777cccccccccccccc
ccccccccccccccccccccccccccccccc777777ccccccc77ccc7777cccc771100111111111111111111110000001111001111777cccccccc77ccccccc77ccccccc
ccccccccccccccccccccccccccccccc7777777cccccccccc77777cccc77110011111111111111111111000000111100111177cccccc6ccccccccccc77ccccccc
cccccccccccccccccccccccccccccccc7777777cccccccc7777777cc777110011111001111111111111000000111100111177cc77ccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc777777777777777777777777777111001111000001111111111100000011110011177cc77ccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccc77577777777777777557777775111001110000000111111111110000111110011177ccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccc77777777777777777777777777777777777777777777777777777777777777777577ccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc77777777777777777777777777777777777777777777777777777777777777777777cccccc77cccccccccccccccccc
cccccccccccccccccccccccccccccccccccc777777cc777777cc777777cc777777cc777777cc777777cc777777ccccc7777777cccccc77cc7ccccccccccccccc
cccccccccccccccccccccccccccccccccccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccccc7777777ccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777ccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc77777ccccccc7cccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777cccccccccc7ccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777ccccccccccccccccccccccccccc

__gff__
0000000000000000000000020000000002020202020000000000000000000000020202020202020202020000020000022121211300210202020200000000000002020202020202020200000202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000212121212121616161131313130a0a0a212121212121a1a1a1131313130a0a0a2121212121202121211313131321210200212121212021212113131313212121
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006260706060f1d4e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e4e2e2e2e36100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004400de00000000000000006260616273e1e2e2e2e2e2e2e2e2e2e2e4e2e2e2e2e2e2e2e2d5f2f2f30000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dedfcede00000000000000000061000062e1e2e4d5f2f2f2f2d4e2e2d5f2f2f2f2f2f2d4e2e36360610000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005212135000000000000000000000000047e1e2e2e363617263f1f2f2f3607360616100f1f2f36160000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007100000000000000000000000072710000000000000000000000670b0b0b0b0b5022235200000000000000470d290d48d1c4e2d5f361006260636060606060610000005000500062000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000006000004b000057364d4e00727162610000000000460071000072d1c6c7c7c7c8d3ffff5300000000000072d1d6d7d8d2c4e2e2e30000000062607361627060610000005000500000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000467260715a5b7272d135d2d3726060710000000000475672c0606070e1e6e7e7e7e8e4d2d2d2d3cddf00727260f1e6e7e8e2e4e2e2e34e26573672606100726061000000005067500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000593656d1d2d2d2d36060e1e2e4c5d2d2d2d3cd000000cfd1d2d2d3610062f1f2d4e4e2e2e2e2d5f2f371717260606151f1f2d4e2e2e2e2c5d235d235d3612672736061004f4464d1d2d359000046004c0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000d135d2c4e2e2e2e36162f1f2d4e2e2e2d5f30000000000f1d4e2e34c00006263f1f2f2f2f2f2f36361626060607361500062f1d4e2e2e2e2e2e4e2e2c5d235d360610000d1d2d2c4e2e3c05557564dfc00004f4c00004d4e4c0000004f00004d4e
000000000000003a00000000000000000000000000000000004fef4c000000f1f2d4e2e2e2d5f300005062f1f2f2f2f300000000000062f1d4c5d30000006162636100000062627172606061610050000051e1d5f2f2f2f2f2f2f2f2f2f2f361000072e1e4e2e2e2c5d2d2d2d3fcfc4e00dececececececedececececececede
00000000007169c00000000000000000000000004b00000000f6f7f84c00005062f1f2f2f2f3500000500062610000500000000000000050e1e2e34e4800000062000000000000626061610000dddecedddef1f3005200005062636150005000007273f1f2d4e2e4e2e2e2e2c5d3fcfc00404141414141415141414141414142
000000727260d1d34e000000004600000000c05a5b0000004ff7f7f7f84e005000626263616150000050482657364c500000000000000043e1e2c5d2d3fc0054000000000000007273710000000051000052c0610051004b5100610051005200000062c060f1f2f2d4e2e2e2e4c5d3fc4e500d29290d0d0d500d0d270d280d50
000072606073e1c5d300000000564c000000d1d2d34e674df6f7f7f7f7f857434e267261000050004fd1d235d235d3530b0b0b0b0b0b0bd1c4e2e2e2e3f9fa33fb000000f9fafbd1d2d30000000052000050620000515a5b51000000500051000000006262736100f1d4e2e2e2e2c5d2d2d2d6d7d7d7d7d8d2d6d7d7d7d7d8d3
007273606162e1e2e3cdcececfd1d3000000e1e2c5d2d2d2f7f7f7f7f7d2d2d2d235d3713626504dd1c4e2e2e2e4c5d2c6c7c7c7c7c7c8c4e2e2e2e4e3d1d34950000000504ac0e1e4e30000000052000051000000d1d2d2d34e0000ddcedf00000000000062000062e1e2e2e2e2e2e2e4e2e6e7e7e7e7e8e2e6e7e7e7e7e8c5
007260610069e1e2c5d371004fe1e3cdcecfe1e4e2e2e2e2d2d2f7f7d2e2e2e2e2e2c5d23535d2d2c4e2e2e2e2e2e2e2e6e7e7e7e7e7e8e2e2e2e2e2e3f1f3c0504c004450d1d2c4e2e3690000dddddfdddfdf0069e1e2e4c5d3000000000000000000000000005878e1e2e2e2e2e4e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e4
7270607100d1c4e2e4e36060d1c4e3710000e1e2e2e2e2e2e2e2d2d2e2e2e2e2e2e2e2e2e2e2e2e2e2e4e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2c5d2d2d2d2d2d2d2d3e1e4e2e2c5d3000000000000000000d1c4e2e2e2e371000000000000000000000000d1d2c4e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e4e2e2e2e2e2
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000062e1e2e2e2e30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1e2d5f2f30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007576000000000000000000000000000000f1d4e373610000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444d4e74756600000000000000000000000000000062f1f360710000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000004d4e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000decedfceddcedfddde00000000000000000000000040414142c060607061000000000000000000000000000000000000000000000000000000000000
0000000000000000000000005c5d5e5f00000000000000000000000000000000000000000000000000000000000000000000000000000000404141514141420000004600404141414141414142000000000000000000000000521400e57260610000000000000000000000000000000000000000000000000000000000004041
0000000000000000000000006c6d6e6f00000000000000000000000000000000000000000000000000000000000000004c00000000000000404141514141420000005657500b0b0b0b0b0b0b524c4700000000000044000000502425726060610000000000000000000000000040414142000000000000000000000000005000
00000000000000004041424f7c7d7e7f4e404200000000000046000000000000000000000000000000000000000000d1d34f0b0b0b0b0b00500000500000434e674dd1d2d2c6c7c7c7c7c7c8d2d3c000000000004f7566444dd1d2d3d1d2d34e0000000000000000000000000052004d5357000000000000000000000058504c
0000000000000000434e43d1d2d2d2d2d2d2d3570000000000560b0b0b0b4840415141514151415141514151414259f1f3d1c6c7c7c7c8d35000dddedf00c1c2d2d2c4e2e2e6e7e7e7e7e7e8e2e361000000004cd1d3f9fbfcf1f2f3e1e2e3f84e4f4c0000000000de00004f4c43d1d2d2d34e0054000000000055444cc0d1d2
0000000000004f4df6f7f7e1e2e2e2e2d5f2f3c0cddecedecfd1c6c7c7c8d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d1d2d2c4e6e7e7e7e8e3c000005000006263f1f2f2f2d4e2e2e2e2e4e2d5f2f3000000004ffcf1f3d1d2d2d2d2d2e2e2e3c9cacacb4e00de0000500000d1d2d2c4e2d5f3f9fa33fb000000f933fafafbf1d4
0000dececedef6f7f7f7f7f1f2d4e2e4e3d1d2d30065005000e1e6e7e7e8e3f4f468f45068f4f4686850f468f4f4f1f2d4e4e2d5f2f2f2f3000000500000626070636168f1d4e2e2d5f2f2f3685000000000d1d2d2d2c4e2e2d5f2f2f2d4e3e9eaeaebfc4e404141514141f1d4e2e2e4e3496270610000000000000000004ae1
000050101150edf7f7f7ed0062f1f2f2f3e1e2e374752f5000f1d4e2d5f2f3f468000051006868000051000068f4c061f1f2f2f3636150000000dddedf0072606161000062e1e2d5f3610000005000000000f1d4e2e2e2d5f2f3000062e1e2d2d2d3f9fbf853580052000050e1e4e2e2e34e7261000000000000004041424fe1
4e4850202150fdf7d2f7fd0000526350c0e1e2c5d2d2d2d30062f1f2f3636100000000500000000000500000000000005262636162715036570000500000d1d34c00004726e1e2e36100000000500000004c50f1d4e2d5f36061000000f1f2d4e2c5d2d2d2d2d3c050000050e1e2e2e2c5d3fc4e40414142004f72756643d1c4
d2d23031313132d2e2d230ee0000615063e1e4e2e2e2e2e34e72610062606100000000510000000000de00000000004f43d1d3362662d135d30000500000e1c5d3264fd135c4e2e34e094c00005000004dfc5300e1e2e36060610000000062f1f2d4e2e2d5f2f34151414151e1e2e2e2e2c5d2d3c0744c654dd1d3d1d2d2c4e2
e2e2e2e2e2e2e2e2e2e2e2feee00005062f1d4e2e2e2e2e2d2d3716772706100000000500000000000500000000000d1d2c4c53535d2c4d5f300dddedf00f1e2c535d2c4e2e2e2c5d2d2d34e00ddcecececedf00e1d5f373610000000000006061f1d4d5f352000052004fd1c4e2e2e2e2e2e4e2d2d2d2d2d3f1f3e1e2e2e2e4
e2e2e2e2e2e2e2e2e2e2e2e2feee00500061e1e2e4e2e2e2e2e373d1d3610000000000de0000000000510000000072e1e2e2e2e2e2e4e2e300000052000062e1e2e2e2e2e2e2e4e2e2e2c5d30000000000000072e1e3626071000000000000700000e1e3607100000000d1c4e2e2e2e2e2e2e2e2e2e2e2e2c5d2d2c4e2e4e2e2
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
900300002e620206401e650126401a615016050060501705006050170507605236050060501705006050170501705017050060523605017050160500605017050060525605016052360525605017052360500000
000400000e560155751d0001d000180001800018000180001b0001b00022000220061f0051f00016000160001d0001d0001d002130011800018000180021f001240002200016000130001d0001b0021800018000
02040000260502605027050290302c03030020340150f0000a0000a0000a0000a0000a0000a0000500005000030000300003000030000c0000c0001100016000160000f001050000a00005000030010a0000a000
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
001000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000400002863427632226351e510275402c53018500185001850018500185001850000500165001650216502275042750427504275041f5001f5001f500135001b50135500305002450029500295002250022500
000400002b6501d640156302365014630076122d5422d5402d5403554235552355503555035555005003650036500375003750037500375000a5001350113500005000050013500135000f5000f5000050000500
12030000356472b64732647246472d647266471e6471a647226471b64714647086451e00012000120001200012000120001200012000120001200012000120001200523000240021f0021f0001d0011d0001d000
900a0000390143801137011350113301132011300112e0112d0112b0112901127011260112401122011200111e0111c0111a011170111501112011100110d0110a01107011040110201100011070010300101005
910500003f6433f6403f6403e6403e6303e6313d6313c6313a6313863134631316312f6312d6312963126621226211f6211c6211a6211862116621146211362111621106110f6110d6110a611086110661103615
900300000565003640006253360025600136001360012600106000f6000e6000e6000e6000f6001060011600106000f6000f6000e6000d6000c6000b6000b6000b6000b6000b6000b6000a600096000760005605
000600001877035770357703576035750357403573035720357103571500700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000400003f6703c670396703b670346702d6703667030670346702a67024670256601a6601f6601b6601c6601266015650186500b650086500e6500e640086401764013640106300b63005630026200162000615
0406000027653066351e65300625055000000005500075000a5000a5000a500000000a500000000a5000350005500055000550000000055000550005500000000a500075000c5000c5000f500000000a50007500
1102000011073130741a0762407624056240452403524025240152400024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480200001107009070040702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103000010624116401365015650176401f6232064421650246502565523500296002160531600276050f5000f5000f500005000a5000a5000a5000f50011500115000a5000a5000000000000000000000000000
0402000016650136501163306615256002f6032c604256001f6001a60523500296002160531600276050f5000f5000f500005000a5000a5000a5000f50011500115000a5000a5000000000000000000000000000
010300002c61428630236501e65018630246231f6441b640156301562523500296002160531600276050f5000f5000f500005000a5000a5000a5000f50011500115000a5000a5000000000000000000000000000
09050000356742d6621c6521b6520d6550c6560e65311653066530c6530e65303653046530065518700007001f7011f7001f7021f7021870000700187011b7002270122700227022270237002370023700237002
000c00003b6411c6350e7240b7210872104721007152770227702247020070000700007000070000700007002e0002e0002e0002e000350003500033001330002b0002b0002b0002b00030000300023000230002
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
00070000301532b1402e13035130241342b1242e11435115301032b1002e10035100241042b1042e1043510500603186030c601006050060324600186012460524300246033230131301303012b3010000000000
00040000336251a605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
00030000307532d7512d7413774137741377552970028700277000c30000000000000000000000000000000000000000000000000000000000000000000000000a3000a3000a3000a3000a3010a3000330103300
490400000a63415621216412165121651216253260032605336002660038605133001830013300163001d30022300223002230022300223002230013300133001830018300133001330016300163001d3001d300
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
000400002f45032450314502e4502f45030450000000000001400264002f45032450314502e4502f4503045030400304000000000000000000000000000000000000000000000000000000000000000000000000
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
