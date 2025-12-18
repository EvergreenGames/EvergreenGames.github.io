pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- [initialization]
-- evercore v2.3.1

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

--global tables
objects,got_fruit={},{}
--global timers
--i was going to delete this cheatsheet when i finished the mod but lowkey i forgot to make the table at all
--progress: 1 = truck has been initialized
-- 2 = 
freeze,delay_restart,sfx_timer,music_timer,ui_timer,progress,keytracker,keytracker2=0,0,0,0,-99,0,0,0
--global camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25
dancedancerevolution="0000000000000000000000"
-- [entry point]

function _init()
 cartdata("maude2")
 if dget(0)==2 then
  dset(0,0)
 end
	frames,start_game_flash=0,0
	music(40,0,7)
	lvl_id=0
end

function begin_game()
	max_djump=1
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
		spd=0.575*(flr(rnd"10")+1),
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


function mul32(a,b)
  local a_lo = a & 0xffff
  local a_hi = (a >> 16) & 0xffff
  local b_lo = b & 0xffff
  local b_hi = (b >> 16) & 0xffff

  local lo = a_lo*b_lo
  local carry = (lo >> 16) & 0xffff
  lo = lo & 0xffff

  local mid = a_lo*b_hi + a_hi*b_lo + carry

  return (lo) | ((mid & 0xffff) << 16)
end

function fnv1a32(str)
  
  local h = (0x811c << 16) | 0x9dc5
  local prime = 0x01000193

  for i=1,#str do
    h = h ^^ ord(str,i)
    h = mul32(h, prime)
  end

  return h 
end

function fnv1a32_seeded(str, seed_hi, seed_lo, prime)
  local h = (seed_hi << 16) | seed_lo
  for i=1,#str do
    h = h ^^ ord(str,i)
    h = mul32(h, prime)
  end
  return h
end

function fnv1a64(str)
  local prime = 0x01000193
  local h1 = fnv1a32_seeded(str, 0x811c, 0x9dc5, prime)
  local h2 = fnv1a32_seeded(str, 0x1234, 0x5678, prime)
  return h1,h2 
end
-->8

-- [update loop]

function _update()
 if lvl_id>1 then
  if btn(6) then
   dset(0,0)
  else
   dset(0,1)
  end
 end
 levels[0]="7,3,1,1,\"\""
 if lvl_id<1 then
  load_level(0)
 end
 if lvl_id==9 and progress<9000 and progress>-1 then
  progress+=1
 end
 if progress==8998 then
  levels[10]="5,3,1,1,true summit"
 end
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
		end
	end

	if sfx_timer>0 then
		sfx_timer-=1
	end

	-- cancel if freeze
	if freeze>0 then
		freeze-=1
	 if freeze>2 then
	  rectfill(0,11,128,58,0)
	  rectfill(0,58,12,64,0)
	  print("runtime error line 31 tab 4",0,11,14)
	  print("   if player.spd.x<0.13 then",0,17,7)
	  print("attempt to compare number with n",0,23,6)
	  print("il",0,29,6)
	  print("in _f line 29 (tab 4)",0,35,13)
	  print("in foreach line 0 (tab 0)",0,41,13)
	  print("in _update line 27 (tab 4)",0,47,13)
	  print("at line 0 (tab 0)",0,53,13)
	  print(">",0,59,7)
	 end
	 if frames%15>7 and freeze>2 then
	   rectfill(8,59,11,63,8)
	  end
		return
	end

	-- restart (soon)
	if delay_restart>0 then
		cam_spdx,cam_spdy=0,0
		delay_restart-=1
		if delay_restart==0 then
		 if lvl_id==1 then
		  levels[2]="7,3,1,1"
		  lvl_id+=1
		  progress=2
		  music(40,0,7)
		 end
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
			if progress!=1 then
			 move_camera(obj)
			end
		end
	end)

	-- start game
	if lvl_x==112 and lvl_y==48 then
		if start_game then
			start_game_flash-=1
			if start_game_flash<=-30 then
				levels[2]="5.5,0,1,1,the climb",
			 load_level(2)
			 music(0,0,7)
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
 if is_title() then
  begin_game()
 end
 if freeze==3 then
  music(0,0,7)
 end
	if freeze>0 then
	 if freeze>60 then
	  music"-1"
	  rectfill(0,11,128,58,0)
	  rectfill(0,58,12,64,0)
	  print("runtime error line 31 tab 4",0,11,14)
	  print("   if player.spd.x<0.13 then",0,17,7)
	  print("attempt to compare number with n",0,23,6)
	  print("il",0,29,6)
	  print("in _f line 29 (tab 4)",0,35,13)
	  print("in foreach line 0 (tab 0)",0,41,13)
	  print("in _update line 27 (tab 4)",0,47,13)
	  print("at line 0 (tab 0)",0,53,13)
	  print(">",0,59,7)
	 end
	 if frames%15>7 and freeze>2 then
	   rectfill(8,59,11,63,8)
	  end
		return
	end

	-- reset all palette values
	pal()
	if lvl_id==6 then
	 pal(12,8)
	end

	-- start game flash
	if lvl_x==112 and lvl_y==48 then
		if start_game then
			for i=1,15 do
				pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
			end
		end

		--cls()

		-- credits
		sspr(unpack(split"72,32,56,32,40,32"))
		?"🅾️/❎",55,80,5
		?"it's even funnier the second",11,96,5
		?"no",45,102,5
		?"el berry",54,102,5

		-- particles
		foreach(particles,draw_particle)
  
		--return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)

	-- bg clouds effect
	if lvl_id!=2 or lvl_y!=48 then
	 foreach(clouds,function(c)
		c.x+=c.spd-cam_spdx
		rectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col)
		if c.x>128 then
			c.x=-c.w
			c.y=rnd"120"
		end
	end)
	end

	--set cam draw position
	draw_x=round(cam_x)-64
	draw_y=round(cam_y)-64
	--if progress!=1 then
	 camera(-1+draw_x,-2+draw_y)
 --end
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
	-- todo: make error message hella cursed
	if progress!=1 or lvl_id!=1 then
	 camera()
	end
	
	if ui_timer>=-30 then
		if ui_timer<0 then
			draw_ui()
		elseif ui_timer>6 and ui_timer<85 then
		 draw_ui()
		elseif ui_timer>90 then
		 draw_ui()
		end
		if ui_timer==6 or ui_timer==90 then
	  ui_timer=-32
	 end
		ui_timer-=1
	end
	if lvl_x==112 and lvl_y==48 then
		if start_game then
			for i=1,15 do
				pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
			end
		end

		--cls()

		-- credits
		sspr(unpack(split"72,32,56,32,40,32"))
		?"🅾️/❎",55,80,5
		?"it's even funnier the second",11,96,5
		if fruit_count==0 then
		 ?"no",45,102,5
		else  
		 ?"si,",42,102,5
		end
		?"el berry",54,102,5

		-- particles
	end
end

function draw_particle(p)
	p.x+=p.spd-cam_spdx
	p.y+=sin(p.off)-cam_spdy
	p.off+=min(0.05,p.spd/32)
	rectfill(p.x+draw_x,p.y%128+draw_y,p.x+p.s+draw_x,p.y%128+p.s+draw_y,p.c)
	if p.x>132 then
		p.x-=138
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
	local title=lvl_title or lvl_id.."00 m"
	if lvl_id==8 then
	 if ui_timer>5 then
	  title="postscript: baited"
	 end
	elseif progress>2 and lvl_id==3 then
	 if ui_timer<90 then
	  title="it's you, madeline"
	 else
	  title="you're the key to my heart"
  end
 end
 if lvl_x!=112 or lvl_y!=48 then
  rectfill(min(24,60-#title*2),58,max(104,68+#title*2),70,0)
	 ?title,64-#title*2,62,7
  if ui_timer<0 then
	  draw_time(4,4)
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
		this.gravity=true
		if lvl_id==3 and keytracker==9 then
		 this.spr=8
		else
		 create_hair(this)
		end
		this.layer=1
	end,
	update=function(this)
	 if progress>60 and progress<90 and this.check(adelie,1,0) then
		 sfx"5"
		 this.spr=28
		 this.spd.x=-.5
		 this.spd.y=1
		end
		if pause_player or ((this.spr==28 or (progress>50 and progress<100 and lvl_id==8)) and progress<120) then
			this.spd.x*=.8
			if lvl_id==8 then
			 this.spd.y=0
			end
			if lvl_id==3 then
			 this.spr=0
			end
			return
		end
		if progress==3 then
		 this.x=8
		 this.y-=48
		 progress=4
		end
		if progress==5 then
		 this.x=72
		 progress=6
		end
		if progress==7 then
		 this.x=72
		 this.y+=48
		 progress=8
		end
		if progress==20 then
		 next_level()
		 progress+=1
		end
		--todo: hair?
	 if lvl_id==1 and this.x>264 and progress<1 then
	  if dget(0)==0 then
	   sfx"60"
	   init_object(truck,this.x+30,144)
	   progress=1
	  else
	   --dset(0,2)
	  end
	 end
		-- horizontal input
		local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0
  
		-- spike collision / bottom death
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end

		-- on ground checks
		this.on_ground=this.is_solid(0,1) and this.gravity

		-- landing smoke
		if this.on_ground and not this.was_on_ground then
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
		if this.on_ground and not this.check(truck,0,0) then
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
			local accel=this.is_ice(0,1) and 0.05 or this.on_ground and 0.6 or 0.4
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
			if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) and (not (this.check(adelie,h_input,0) or this.check(penguin,h_input,0))) then
				maxfall=0.4
				-- wall slide smoke
				if rnd"10"<2 then
					this.init_smoke(h_input*6)
				end
			end

			-- apply gravity
			if this.gravity and (not this.on_ground) then
				this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.15 and 0.21 or 0.105)
			elseif not this.gravity then
			 this.spd.y=appr(this.spd.y,-1*maxfall,abs(this.spd.y)>0.15 and 0.21 or 0.105)
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
			local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0
			if this.y==88 and this.x>80 then
			 if h_input!=this.h_input and lvl_id==10 then 
				 progress=(h_input+1)*.5+189
			 end
			 if v_input!=this.v_input and lvl_id==10 then
				 progress=(v_input+1)*.5+173
			 end
			end
			this.h_input,this.v_input=h_input,v_input
			if this.djump>0 and dash then
				this.init_smoke()
				this.djump-=1
				this.dash_time=4
				has_dashed=true
				this.dash_effect_time=10
				-- vertical input
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
		this.spr = not this.on_ground and (this.is_solid(h_input,0) and 5 or 3) or	-- wall slide or mid air
		btn(⬇️) and 6 or -- crouch
		btn(⬆️) and 7 or -- look up
		this.spd.x~=0 and h_input~=0 and 1+this.spr_off%4 or 1 -- walk or stand

		-- exit level off the top (except summit)
		if this.y<-4 and levels[lvl_id+1] and progress*lvl_id!=-9 and lvl_id!=1 and lvl_id!=10 then
			next_level()
		end

		-- was on the ground
		this.was_on_ground=this.on_ground
	 if lvl_id==3 and keytracker==9 then
	  this.spr=8
	 end
	end,

	draw=function(this)
		-- clamp in screen
		local clamped=mid(this.x,-1,lvl_pw-7)
		local clampedy=mid(this.y,-1,lvl_ph+1000)
		if this.x~=clamped then
			this.x=clamped
			this.spd.x=0
		end
		if this.y~=clampedy and (lvl_id*progress==-9 or dget(0)==2) then
		 this.y=clampedy
		 this.spd.y=0
		end
		-- draw player hair and sprite
		if lvl_id!=2 or lvl_y!=48  then
		 set_hair_color(this.djump)
		end
		draw_hair(this)
		draw_obj_sprite(this)
		pal()
		if this.gravity==false then
		 spr(172,this.x,this.y-7)
		 spr(156,this.x,this.y-14)
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
	local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and obj.grace and 4 or 3))
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
		this.spr=3
		this.target=this.y
		this.y=min(this.y+48,lvl_ph)
		cam_x,cam_y=mid(this.x+4,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
		if lvl_x==112 and lvl_y==48 then 
		 this.spr=132
		 this.y=this.target
		else
		 this.spd.y=-4
		 this.state=0
		 this.delay=0
		 sfx"4"
		end
		if lvl_id==3 and keytracker==8 then
		 this.spr=8
	 else
		 create_hair(this)
		end
		this.djump=max_djump
		
		this.layer=1
	end,
	update=function(this)
	 if start_game and this.spr==132 then
		 set_hair_color(0)
		end
	 if this.spr==132 then
	  return
	 end
		-- jumping up
		if this.y<-4 and progress>-1 then
		 next_level()
		end
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
			if keytracker<8 or lvl_id!=3 then
			 this.spr=6
			else
			 keytracker=9
			end
			if this.delay<0 then
			 init_object(player,this.x,this.y)
				destroy_object(this)
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
		
		 if this.show and hit and hit.spd.y>=0 and this.delta<=1 then
			 if this.dir==0 then
				 hit.move(0,this.y-hit.y-4,1)
				 hit.spd.x*=0.2
				 hit.spd.y=-.2
				 if not pause_player then
				  hit.spd.y=-3
				 end
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
		this.solid_obj,this.state=true,0
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
				this.state,this.collideable=0,true
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
		obj.state,obj.delay=1,15
  --how long until it falls
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
		this.start,this.timer=this.y,0
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
				hit.gravity=false
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
			this.spd.y=sin(this.step)*0.5+.01
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
	 if lvl_id==4 then
	  max_djump=0
	 end
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
	 if lvl_id!=2 then
	  keytracker+=1
	  if keytracker==3 then
	   keytracker+=4
	  end
	  if keytracker==8 then
	   levels[3]="3,1,1.5,1,heart-shaped box"
	  end
	 end
		 this.spd.y,this.duration=-0.25,30
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

key={
 init=function(this)
  if keytracker>7 then
   destroy_object(this)
  end
 end,
	update=function(this)
		this.spr=flr(9.5+sin(frames/30))
		if frames==18 then --if spr==10 and previous spr~=10
			this.flip.x=not this.flip.x
		end
		if this.player_here() then
			sfx"23"
			sfx_timer=10
			destroy_object(this)
			if keytracker2==0 then
			 has_key=true
			else
			 keytracker2-=1
			end
		end
	end
}

chest={
	check_fruit=true,
	init=function(this)
		this.x-=8
		this.start=this.x
		this.timer=20
		if keytracker>7 then
		 mset(61,24,0)
		 init_object(heart,this.x+10,this.y-8)
		 destroy_object(this)
		end
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

heart={
 update=function(this)
  this.player=this.check(player,0,8)
  if this.player and this.player.on_ground and not pause_player then
   init_object(cutscenekey,this.player.x,this.player.y)
   pause_player=true
   this.player.spd.x=0
   this.player.spd.y=0
  end
 end,
 draw=function(this)
  if progress<80 then
   spr(165,this.x,this.y,2,2)
  else
   spr(167,this.x,this.y,2,2)
  end
 end
} 

cutscenekey={
 init=function(this)
  this.spr=8
  this.layer=1
  this.startpos=this.x
 end,
 update=function(this)
  if progress==2 then
   this.x=appr(this.x,116,.25)
   this.y=appr(this.y,60,.25)
  end
  if this.x==116 and this.y==60 and progress<10 then
   progress+=1
   sfx"21"
  elseif progress>9 and progress<100 then
   this.spr=131
   progress+=1
   this.x=appr(this.x,118,.1)
  elseif progress>99 and progress<200 then
   this.spr=176
   lvl_w=24
   lvl_pw=24*8
   progress+=1
  elseif progress>199 and progress<300 and ui_timer then
    ui_timer=80
    progress+=1
  elseif progress>299 and progress<400 then
    ui_timer=91
    progress+=1
  elseif progress==400 then
    init_object(flag,this.startpos,64)
    progress+=1
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
	last=0,
	draw=function(this)
	 if lvl_id==5 then
	  if this.x<50 and this.y>60 then
		  this.text="kawazaki."
		 elseif this.x<50 then
		  this.text="cago."
		 elseif this.y>60 then
		  this.text="y estriper."
		 else
		  this.text="krico."
		  spr(81+frames\10*16,this.x-12,this.y-2)
		 end
		elseif lvl_id==2 then
		  this.text="--spiritual mountain--# billions must climb. "
  elseif lvl_id==7 then
    this.text="   wordle 2378 6/6   "
   elseif lvl_id==9 then
    this.text="maude isn't a free game#game so please pay what#you think is fair. time#is money so you need to#stand here until you've#paid the correct amount#do not enjoy yourself. "
   elseif lvl_id==11 then
    this.text="congratulations! your#spiritual journey has#culminated! hopefully#this has been a great#mod to"
   elseif levels[10]=="5,3,1,1,true summit" then
    this.text="why make a new summit?#you've already paid me"
   elseif lvl_id==10 then
    this.text="summit"
   else
    this.text="welcome 2 west virginia"
   end
		if this.check(player,4,lvl_id>1 and 0 or -8) then
			if this.index<#this.text then
			 this.index+=0.5
				if this.index>=this.last+1 then
				 this.last+=1
				 sfx(35)
				end
			else
			 if lvl_id==5 then
			  progress+=1
			 end
			end
			camera()
			this.off={x=8,y=80}
			if lvl_id>9 then
			 this.off.y=10
			end
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(this.off.x-2,this.off.y-2,this.off.x+7,this.off.y+6 ,7)
					print(sub(this.text,i,i),this.off.x,this.off.y,0)
					this.off.x+=5
				else
					this.off.x=8
					this.off.y+=7
				end
			end
		else
			this.index=0
			this.last=0
		end
		camera(draw_x-1,draw_y-2)
	end
}

penguin={
	last=0,
	init=function(this)
	 this.y+=1
	 this.solid_obj=true
	end,
	draw=function(this)
	 if this.y>20 then 
	   this.text="when you died you went#to maude 2? you mustve#been a terrible person"
  else
    this.text="a note from the creator:#play my hideogames     "
  end 
  if lvl_id==10 then
    this.text="since you did so well#all the adelie pooled#some money and bought#you one copy of dance#  dance revolution!  #have fun reliving the#levels you've played!"
  end
		if this.check(player,(lvl_id==10 and -1 or 1)*4,0) then
			if this.index<#this.text then
			 this.index+=0.5
				if this.index>=this.last+1 then
				 this.last+=1
				 sfx(35)
				end
			end
			camera()
			this.off={x=8,y=10}
			if lvl_id==2 then
			 this.off.y=80
			end
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(this.off.x-2,this.off.y-2,this.off.x+7,this.off.y+6 ,7)
					print(sub(this.text,i,i),this.off.x,this.off.y,(this.y<20 and i>33 and i<44) and 10 or (levels[10]=="5,3,1,1,true summit" and i==102) and 11 or 0)
					this.off.x+=5
				else
					this.off.x=8
					this.off.y+=7
				end
			end
		else
			this.index=0
			this.last=0
		end
		camera(draw_x-1,draw_y-2)
		spr(170,this.x,this.y,1,1,lvl_id==10)
	end
}

button={
 update=function(this)
  this.player=this.check(player,-1,0)
  if this.player and this.player.dash_effect_time>0 and progress>0 then
   ui_timer=45
  end
 end,
}

invis={
 update=function(this)
  this.player=this.check(player,0,1)
  if this.player and this.player.spd.y<0 and this.spr==21 then
   this.solid_obj=true
   this.spr=158
   sfx"5"
   this.player.y=this.y+8
   this.player.spd.y=0
  end
 end,
}

adelie={
 last=0,
	init=function(this)
	 last=0
	 this.last=0
  if progress>50 or progress<20 then
   destroy_object(this)
  end
 end,
	draw=function(this)
	 if progress<20 then
	  this.spd.y+=.105
	  this.collides=true
	 end
	 if this.is_solid(0,1) and progress<1 then
	  progress=-1
	  this.spd.x=0
	  this.spr=141
	  levels[9]="4,3,1,1,jail"
	 end
	 if progress>80 then
	  this.spd.y-=.051
	  this.spd.x=-.45*sin(progress/30)
	 end
	 this.solid_obj=true
	 if progress>51 then
	  this.player=this.check(player,0,-14)
	  if this.player and this.player.djump==0 then
	   this.spd.y=-1
	   progress=0
	   this.player.djump=max_djump
	   psfx"6"
	  end
	 end
	 if not this.text then
   this.text="it says \"do not push\"#i wonder what it does#.....................#i'm going to press it"
		end
		this.playerclose=this.check(player,-8,0)
		if this.playerclose and (not this.playerclose.flip.x) and progress>20 then
			if this.index<#this.text then
			 this.flip.x=true
			 this.index+=0.5
				if this.index>=this.last+1 then
				 this.last+=1
				 sfx(35)
				end
			else
			 if progress<51 then
			  progress+=1
			 end
			 this.flip.x=false
			 if progress==50 then
			  freeze=120
			  this.text="i totally got you lmao!#pranked!!! i can't even#push the button. adelie#can't dash hard enough!"
			  this.index=0
			  this.last=0
			 end
			end
			camera()
			this.off={x=8,y=10}
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(this.off.x-2,this.off.y-2,this.off.x+7,this.off.y+6 ,7)
					print(sub(this.text,i,i),this.off.x,this.off.y,lvl_id==8 and progress>49 and i>77 and i<83 and 8 or 0)
					this.off.x+=5
				else
					this.off.x=8
					this.off.y+=7
				end
			end
		else
			this.index=0
			this.last=0
			this.flip.x=false
		end
		camera(draw_x-1,draw_y-2)
	 if progress<51 then
	  spr(this.spr,this.x,this.y,1,1,this.flip.x)
	 else
	  if progress<200 then
	   progress+=1
	  end
	  spr(155,this.x,this.y,1,1,true)
	  spr(172,this.x-3,this.y-7,1,1)
	  spr(156,this.x-3,this.y-14,1,1)
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
		this.spd.y=lvl_id==11 and -4 or -11
	end,
	update=function(this)
		this.spd.y=appr(this.spd.y,0,0.5)
		local hit=this.player_here()
		if this.spd.y==0 and hit then
			music_timer=45
			sfx"51"
			freeze=2
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
	end,
	update=function(this)
	 if this.player_here() then
		 if not this.show then
			 sfx"55"
			 sfx_timer,this.show,time_ticking=30,true,false
		 end
		else
		 this.show=false
		end
	end,
	draw=function(this)
		if lvl_id!=3 then
		 spr(118+frames/5%3,this.x,this.y)
		end
		local yoff=lvl_id>1 and 0 or 36
		if this.show then
			camera()
			rectfill(32,2+yoff,96,31+yoff,0)
			if lvl_id==3 then
			 spr(138,63,6)
			elseif lvl_id==1 then
			 spr(137,63,42)
			else
			 spr(118,63,6)
			end
			draw_time(43,16+yoff)
			?"deaths:"..two_digit_str(deaths),48,24+yoff,7
			camera(draw_x-1,draw_y-2)
		end
	end
}

arrow={
  init=function(this)
   this.timer=-1
  end,
  update=function(this)
   if progress==this.spr then
    progress=0
    if this.spr<189 then
     sfx(this.spr-126)
    else
     sfx(this.spr-140)
    end
    if this.timer==-1 then
     dancedancerevolution=sub(dancedancerevolution,3)..tostr(this.spr-100)
     h1,h2 = fnv1a64(dancedancerevolution)
     if the400==1 then
      if h1==-14135 and h2==5324 then
        next_level()
       end
     elseif the400==2  then
      if h1==20958 and h2==-25493 then
       next_level()
      end
     elseif the400==3 then
       if h1==-24785 and h2==29894 then
        next_level()
       end
     else
      if h1==-24557 and h2==13654 then
       next_level()
      end
     end
    end
    this.spr-=36
    this.timer=10
   end
   if this.timer>0 then
    this.timer-=1
   elseif this.timer==0 then
    this.spr+=36
    this.timer-=1
   end
  end
}
   

prekey={
  init=function(this)
   if keytracker>keytracker2 and keytracker<8 then
    keytracker2+=1
    init_object(key,this.x,this.y)
    destroy_object(this)
   end
  end,
  draw=function(this)
   local p=true
  end
}

truck={
  init=function(this)
   this.spd.x=-15
   this.solid_obj=true
   this.collideable=true
   this.hitbox=rectangle(-24,-24,40,40)
  end,
  draw=function(this)
    spr(144,this.x,this.y,4,2)
  end
}

sillyblock={
 init=function(this)
  this.solid_obj,this.collides,this.collidable=true,true,true
  this.hitbox=rectangle(0,0,16,16)
 end,
 update=function(this)
  for i=1,3 do
   if this.check(player,-1,i*8) and dget(0)==1 then
    this.spd.y=3
   end
  end
  local hit=this.check(player,0,-1)
  if hit then
   mset(32,17,17)
   mset(33,17,17)
   kill_player(hit)
  end
 end,
 draw=function(this)
  spr(143,this.x,this.y)
  spr(159,this.x+8,this.y)
  spr(175,this.x,this.y+8)
  spr(191,this.x+8,this.y+8)
 end
}
--something is wrong with me
movingarrow={
  init=function(this)
   this.x-=6
  end
}

-- [object class]

function init_object(type,x,y,tile)
	--generate and check berry id
	local id=x..","..y..","..lvl_id
	if type.check_fruit and got_fruit[id] then
		got_fruit[id]=false
	end

	local obj={
		type=type,
		collideable=true,
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
	 if obj.x+ox>lvl_pw-7 or obj.x+ox<-1 then
	  return true
	 end
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
	 if lvl_x==112 and lvl_y==48 then
	  return obj.check(player_spawn,0,0)
	 end
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
	cam_spdx=min(cam_gain*(4+obj.x-cam_x),5)
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
	if music_switches[next_lvl] and cloud_col==14 then
		music(music_switches[next_lvl],500,7)
	end

	load_level(next_lvl)
end

function load_level(id)
 if keytracker>7 and lvl_id==3 then
  if id==3 then
   music"-1"
  else
   music(0,0,7)
  end
 end
 if id==5 then
  max_djump=1
 end
 if id==9 and progress>=0 then
  printh("right","@clip")
 elseif id>1 then
  printh("maude 2 is easily the best mod i've ever played. the graphics are incredible, the gameplay is invigorating, and the puzzles are the most unique and creative i've seen! mod of the year for sure!","@clip")
 end
 if id==8 and progress<60 and progress>20 then
  progress=21
 end
 if keytracker2!=0 then
  keytracker1,keytracker2=0,0
 end
 if id==3 and keytracker==9 then
  keytracker=8
 end
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
	if lvl_id==3 then
  lvl_w=16
 end
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8

	--level title setup
	ui_timer=5

	--reload map
	if diff_level or lvl_id==2 then
		reload()
		--check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
		end
	end

	-- entities
	for ty=0,lvl_h-1 do
		for tx=0,lvl_w-1 do
			local tile=tile_at(tx,ty)
			if tiles[tile] then
				init_object(tiles[tile],tx*8,ty*8,tile)
			end
		end
	end
	if lvl_id==9 and progress>-1 then
	 progress=0
	end
	if lvl_id==10 then
	 progress=0
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
the400=flr(rnd(4))
levels={
	"0,0,3,2,stairway to heaven",
	"5.5,0,1,1,the climb",
	"3,1,1.5,1,outside of the box",
	the400..",3,1,1,400 remade from memory",
		"4,0,1.5,1,los pinguinos me la van a mascar",
	"6.5,0,1,1,never mind",
	"5,1,1,1,did you see that???",
	"6,1,1,1,big red button",
	"7,1,1,1,n minute timeout",
	"5,3,1,1,wow congratulations on beating maude 2! credits: lord snek",
 "6,3,1,1,truest summit"
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
	[8]=0,
}

--@end

--tiles stack
--assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
1,player_spawn
8,key
9,prekey
11,platform
12,platform
18,spring
19,spring
20,chest
21,invis
22,balloon
23,fall_floor
26,fruit
45,fly_fruit
86,message
96,big_chest
118,flag
139,adelie
140,button
143,sillyblock
144,truck
153,movingarrow
165,heart
170,penguin
173,arrow
174,arrow
189,arrow
190,arrow
]],"\n"),function(t)
 local tile,obj=unpack(split(t))
 tiles[tile]=_ENV[obj]
end)

--[[

short on tokens?
everything below this comment

--]]
__gfx__
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700494949494949494949494949
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000777777677777770222222222222222222222222
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a0007766666667767777000420000000000000024000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0007677766676666677004200000000000000002400
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000000000000000000042000000000000000000240
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000000000000000000420000000000000000000024
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a0000000000000000000200000000000000000000002
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0000000000000000000000000000000000000000000
555555550000000000000000000000000000000000000000008888004999999449999994499909940300b0b06665666500000000000000000000000070000000
55555555000000000000000000040000000000000000000008888880911111199111411991140919003b33006765676500000000007700000770070007000007
550000550000000000000000000950500aaaaaa00000000008788880911111199111911949400419028888206770677008888880007770700777000000000000
55000055007000700499994000090505a998888a0000000008888880911111199494041900000044089888800700070088888888077777700770000000000000
55000055007000700050050000090505a988888a00000000088888809111111991140949940000000888898007000700888ffff8077777700000700000000000
55000055067706770005500000095050aaaaaaaa0000000008888880911111199111911991400499088988800000000088f1ff18077777700000077000000000
55555555567656760050050000040000a980088a0000000000888800911111199114111991404119028888200000000008fffff7070777000007077007000070
55555555566656660005500000000000a988888a0000000000000000499999944999999444004994002882000000000000033700000000007000000000000000
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
7776667757777775000000000007707770077700000000000000000000000000cccccccc00000000000000000000000000000000000000000000000000000000
7776677777777777000000000777777677777770077000000000000000000000c77ccccc00000000000000000000000000000000000000000000000000000000
7776677777777777000000007766666667767777777700000000000000000000c77cc7cc00000000000000000000000000000000000000000000000000000000
7766677777766777000000777677766676666677776700000000000000000000cccccccc00000000000000000000000000000000000000000000000000000000
7766667777666677000007776666666666666666666770000002eeeeeeee2000cccccccc00000000000000000000000000000000000000000000000000000000
776666777766667700007777666666666666666666667700002eeeeeeeeee200cc7ccccc00000000000000000000000000000000000000000000000000000000
77766777776766770000776666666666666666666666677000eeeeeeeeeeee00ccccc7cc00000000000000000000000000000000000000000000000000000000
57777775776666770007676666666666666666666667677000e22222e2e22e00cccccccc00000000000000000000000000000000000000000000000000000000
00000000000000000076766666666666666666666667677000eeeeeeeeeeee000000000000006600066000666660006600066006666660006666660000000000
00000000000000600077766666666666666666666676670000e22e2222e22e000000000000006660666006600066006600066006666666006666666000000000
00000000000000000007676666666666666666666666700000eeeeeeeeeeee000000000000006666666006600066006600066006600066006600000000000000
00000000000000060007666666666666666666666667700000eee222e22eee00000000000000ddddddd00ddddddd00dd000dd00dd000dd00dddd000000000000
00000000000066600000767777666667666777677677000000eeeeeeeeeeee00555555550000dd0d0dd00dd000dd00dd000dd00dd000dd00dd00000000000000
00000000000080000000776677776776666666777770000000eeeeeeeeeeee00555555550000dd000dd00dd000dd00ddddddd00ddddddd00dddddd0000000000
00000000000000000000077707777777677777707000000000ee77eee7777e00555555550000dd000dd00dd000dd000ddddd000dddddd000ddddddd000000000
00000000000000000000000700777007770770000000000007777777777777705555555500000000000000000000000000000000000000000000000000000000
00000000000000066666666657777777777777777777777500777700500000000000000500000000000000000000000000000000000000000000000000000000
00aaaaaa000000006666666677777777777777777777777707000070550000000000005500000000000000000000000000000000000000000000000000000000
0a999999000000606666666677776666677777766666777770770007555000000000055500000000000000000000000000000000000000000000000000000000
a99aaaaa00000600666666667776666666677666666667777077bb07555500000000555500000000000000000000000000000000000000000000000000000000
a9aaaaaa0000660066666666776666666666666666666677700bbb07555555555555555500000000000000000000000000000000000000000000000000000000
a99999990000800066666666776677666666666666676677700bbb07555555555555555500000000000000000000000666660000000000000000000000000000
a9999999000000006666666677667766666666666666667707000070555555555555555500000000000000000000006666666000000000000000000000000000
a9999999000000006666666677666666666666666666667700777700555555555555555500000000000000000000006600066000000000000000000000000000
aaaaaaaa0000000677cccc77776666666666666666666677004bbb00004b000000400bbb00000000000000000000000000666000000000000000000000000000
a49494a100000006777ccc77776666666666666666666677004bbbbb004bb000004bbbbb00000000000000000000000006660000000000000000000000000000
a494a4a100000000777ccc7777667666666666666776667704200bbb042bbbbb042bbb00000000000000000000000000ddd00000000000000000000000000000
a49444aa0000006077ccc777776666666666666667766677040000000400bbb00400000000000000000000000000000ddd000000000000000000000000000000
a49999aa0000660077ccc7777776666666677666666667770400000004000000040000000000000000000000000000ddddddd000000000000000000000000000
a494449900008000777cc7777777666667777776666677774200000042000000420000000000000000000000000000ddddddd000000000000000000000000000
a494a44400000000777cc77777777777777777777777777740000000400000004000000000000000000000000000000000000000000000000000000000000000
a49499990000000077cccc7757777777777777777777777540000000400000004000000000000000000000000000000000000000000000000000000000000000
55555555bbbbbbbbaaaaaaaa000aa0000000000077666666777777776666667700000000000bb000000880000000000077cccccc101100000011110057777777
55555555bbbbbbbbaaaaaaaa00aaaa00088888807776666677777777666667770000000000bbbb000008800000111100777ccccc111111000111111077777777
55555555bbbbbbbbaaaaaaaa00aaaa0088888888777666667777777766666777000000000bbbbbb00008800001171710d77ccccc911111101171171177776666
55555555bbbbbbbbaaaaaaaa00aaaa00888ffff877776666767777666666777700000000bbbbbbbb00088000011199108877cccc977717101119911177766666
55555555bbbbbbbbaaaaaaaa000aa00088f1ff1877776666667777676666777700000000000bb00088888888111777118877ccccd77791101111111177666666
55555555bbbbbbbbaaaaaaaa000aa00008fffff077766666777777776666677700000000000bb0000888888011177711d77ccccc977797101177771177667766
55555555bbbbbbbbaaaaaaaa00aaaa000033330077766666777777776666677700000000000bb0000088880001177710777ccccc911111000677776077667766
55555555bbbbbbbbaaaaaaaa00aaaa000070070077666666777777776666667700000000000bb000000880001199d99077cccccc001100000066660077666666
000000000000000000000000000000000000000057777777777777777777777500000000000a00000000c0000000000000888800000000000222222077777775
00000077777700000000000000000000088888807777777777777777777777770000000000aa00000000cc000011110108888880101111012444444277777777
000077c6cc7702eee2eee2eee2eee2e088888888777766677777777776667777000000000aaa00000000ccc00117171108788880111717112444444266667777
00076ccc6c7708288828882888288828888ffff877766666767777666666677700000000aaaaaaaacccccccc0111991108888880111199112444444266666777
0007c6ccc6770828882888288828882888f1ff1877766666667777676666677700000000aaaaaaaacccccccc1117771008888880011777102444444266666677
0007cc6ccc770828882888288828882808fffff0777766677777777776667777000000000aaa00000000ccc01117771008888880011777102444444266676677
0777ccc6cc7708288828882888288828003333007777777777777777777777770000000000aa00000000cc000117771000888800011777102444444266666677
777777777777082888288828882888280070070057777777777777777777777500000000000a00000000c0001199d990000000001199d9900222222066666677
76677777777708288828882888288828000000000088880000088800008888000008880000000000001111000000000000006000000660000006600077666666
77777777657708288828882888288828088888800888888000888880088888800088888000000000011717101011110000006000006666000006600077666666
76677777777708288828882888288828888888888888888888888888888888888888888808800880011199101171711000006000066666600006600077667666
77777777777755222222222222222222888ffff88888888888888888888888888888888888888888111777111199111000006000666666660006600077666666
5554444555555555555555555444455588f1ff188888888008888888888888888888888888888888111777110177711100060000000660006666666677766666
0044d0440000000000000000440d440008fffff08888880000888888888888888888888888888888011777100177711100060000000660000666666077776666
00440d44000000000000000044d044000033330088888800008888888888888888888888088888801199d9900177711000060000000660000066660077777777
0004444000000000000000000444400000700700888888000088888888888888888888880088880000000000099d991100060000000660000006600057777777
00000000000000000000000000000000000000008888888008888888888888888888888800088000000000000000000000000000000600000000600066666677
00000000000000770000000000000000001111010888888008888880088888888888888000000000001111000000000000111100006600000000660066666677
0aaa00aa000077c60000000000000000111717110088880000888800008888888888880010111101055555500011110001171710066600000000666067766677
aaaaaaaa00076ccc0000000000000000111199110008880000888000000888888888800011717111015595500117171001119955666666666666666667766677
aaaaaaaa0007c6cc0007707770077700101777100000888888880000000088888888000011991111111777111111991111177711666666666666666666666777
0aaa00aa0007cc6c0777777677777770001777100000088888800000000008888880000001777110111777111117771111177711066600000000666066667777
000000000777ccc67766666667767777011777100000008888000000000000888800000009779110011777100119779001177710006600000000660077777777
000000007777777776777666766666771199e99000000008800000000000000880000000096691001199d990011966901199d990000600000000600077777775
232323232323232323232352620000000000000000a293000202020202a392000000000000000000000000000000000023232323232323232323236282828282
1062d9d9d9d9d9d9d9d9d9d9d9d9d9d9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2018201920000008282001362000000000000000000a293020202020292000000000000000000000000000000000000b1b1b1b1b1b1b1b1b1b1b103920101a2
2333d9d9d9d9d9d9d9d9d9d9d9d9d9d9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a283920000000082820000030000a30000a1001100008202020202020000a300000000000000000000000000a3930000000000000000000000000300000000
d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001222320000a3828293000300a392000000b302b200a2020202020200a382000000000000000000000000a382829300000000000000000000a30300000000
d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000042526200a2828282829203a3920000000000b10000000202020202a392a211111111111111111111111111828200000000000000000000a3820300000000
d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d900000000000000000000000000000000000000002b3b2b3b2b3b2b3b00000000000000d2000000000000000000000000
00004252620000a28282920003a2930000000000000000000093000002920000222222222222222222222222328282000000000000a39300a392a20300000000
d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9000000000000000000000000000000000000243426262626262626264454000000000000000000000000000000005a6a
00a3425262000000a29200000300a2930000000000a3828282829300000000002323232323232323232323526282820000001222222232829200000300000000
d9d96474d9d9d9d9d9d96474d9d9d9d9000000000000000000000000000000005151253545354535453545354555515100000000000000000000000000005b6b
a392132333000000000000000300a39200000000a38282828282920000000000000000000000000000a293426282920000004252525262a29300000393000000
d9d96575d9d9d9d9d9d96575d9d9d9d9000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000122222
8293b1b1b11222320000000003a39200001000a392000000009200001100000093001000000000000000a2133392000000001323232352223200001363000000
53535353535353535353535363d9d9d900000000000000000000000000da00000000000000000000000000000000000022222232000000000000000000425252
92a2930000425262000000007392000000028202020293000000000002000000829312222232930000000012223200000000b1b1b1b1135262930000000000a3
d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9000000000000000000000000db00eb000000000000000000000000000000000023525262000000000000000000132323
0000a2930042526200000000b10000000000000000a20202020000000200000082821323232322223200001323620000000000a30000a34262a293000000a392
d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d900000000000064740000000000ea000000000000000000000000000000000000e8132333000000000000000000000000
000000a2934252620000000000000000000000000000a293029300a30200000092a282000082132362000000a27300000000a382828282426293a276858692a3
d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d967001000000065750000aa00000000000000647400c200c2000600000000000098000000000000000000000000000000
00000000a2425262930000000000000000000000000000a202820182020000000000a2768692000003000000000000009300a282828282426282828282828282
d96474d9d9d96474d9d9d96474d9d9d9222222222232122222222222222222220000657500c300c3000700006700100000000000000000000000000000000000
00000000a3425262a27686931100000000000000000000000282018202000000000000a2920000000300000000000000829300a20010a2426276858585858586
d96575d9aad96575d9d9d96575d9d9d923525252526242525252525252525252001222223212223212222232122232120000000000000000000000001b192939
001000a39242526200a38282720000000000000000000000029200a20200000000000000000000a3030000000000000022222222222232426282829200a28282
222222222222222222222222222222222213525252621323525252525252525200135252621323334252526213233342000000000000000000ba00000a1a2a3a
2232a39200425262a392a2760300000000000000000000000200000002000000000000a31222222262000000000000005252525252526242628292000000a282
52525252525252525252525252525252523242525252223242525252525252520000425252222222525252522222225222222222222222222222222222222222
__label__
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666667666666666666666
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
06667766666677666666776666667766666677666666776666667766666677666666776666667766666677666666776666667766666677666666776666667766
06777777667777776677777766777777667777776677777766677777667777776677777766777777667777776677776666777777667777776677777766777777
07777777777777777777777777777777667777777777777777777777777777777777777777777777777777777777776677777777777777777777777777777777
07777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
05555555555555555555555555555555555555555555555555555555511111111111111111111111111111111111111111111100000000000000000000000000
05555555555555555555555555555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000700000
05555555555555555555555555555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555655555555555555555000000000000000000000000000000000000000000000000000000000000000000000600000
05555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000700
05555555555555555555555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555505555550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555500550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555500550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555550555550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000
05555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000001111111
05555555555555555555555555555555555555555555555555555555111111111111111100000000000000000000000000000000000000000000000001111111
05555555555555555555555555555555555555555555555555555555511111111111111100000000000000000000000000000000000000000000000001111111
07777777777777777777777777777777777777777777777777777777549494949494949494949494949494949494949494949494949494949494949494649494
07777777777777777777777777777777777777777777777777777777722222222222222222222222222222222222222222222222222222222222222222222222
06777777667777776677777766777777667777776677777766666777711111111111111100000000000000000000000000000000000000000000000001111111
06667766666677666666776666667766666677666666776666666677711111111111111100000000000000000000000000000000000000000000000000000000
06666666666666666666666666666666666666666666666666666667711111111111111100000000000000000000000000000000000000000000000000000000
06666666666666666666666666666666666666666666666666667667711111111111111100000000000000000000000000000000000000000000000000000000
06666666666666666666666666666666666666666666666666666667711111111111111100000000000000000000000000000000000000000000000000000000
06666666666666666666666666666666666666666666666666666667711111100000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666667750000000000000000000000000000000000000000000000000000000000700000000000
16666666666666666666666666666666666666666666666666666677755000000000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666677755500000000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666777755550000000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666777755555000000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666677755555500000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666677755555550000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666667755555555000000000000000000000000000000000000000000000000000000000000000
16666666666666666666666666666666666666666666666666666667755555555000000000000000000000000000000000000000000000000000000000000000
06666666666666666666666666666666666666666666666666666667755555550000000000000000000000000000000000000000000000000000000000000000
06666666666666666666666666666666666666666666666666776667755555500000000000000000000000000000000000000000000000000000000000000000
06666666666666666666666666666666666666666666666666776667755555000000000000000000000000000000000000000000000000000000000000000000
06667766666666666666666666666666666666666666666666666677755550000000000000000000000000000000000000000000000000000000000000000000
06777777666666666666666666666666666666666666666666666777755500000000000000000000000000000000000000000000000000000000000000000000
07777777766666666666666666666666666666666666666667777777755000000000000000000000000000000000000000000000000000000000000000000000
07777777766666666666666666666666666666666666666667777777550000000000000000000000000000000000000000000000000000000000000000000000
07777777577666666666666666666666666666666666666775555555500000000000000000000000000000000000000000000000000000000000000000000000
07777777777766666666666666666666666666666666666775555555000000000000000000000000000000000000000000000000000000000000000000000000
06666777777766666666666666666666666666666677666775555550000000000000000000000000000000000000000000000000000000000000000000000000
06666677777776666666666666666666666666666677666775555500000000000000000000000070000000000000000000000000000000000000000000000000
06666667777776666666776666667766666677666666667775555000000000000000000000000000000000000000000000000000000000000000000000000000
06667667777766666677777766777777667777776666677775550000000000000000000000000000000000000000000000000000000000000000000000000000
06666667777766666777777777777777777777777777777775500000000000000000000000000000000000000000000000000000000000000000000000000000
06666667777666666777777777777777777777777777777755000000000000000000000000000000000000000000000000000000000000000000000000000000
16666667777766677555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000055000000
16666677777766777555555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000555500000
16666677777766777555555555555555555555555555555111111111111111111111111111111111111111111111111110000000000000000000005555550000
16666777777666777555555555555555555555555555551111111111111111111111111111111111111111111111111110000000000000000000055555555000
16666777777666677555555555555555555555555555511111111111111111111111111111111111111111111111111110000000000000000000555555555500
16666677777666677555555555555555555555555555111111111111111111111111111111111111111111111111111110000000000000000005555555555550
16666677777766777555555555555555555555555551111111111111111111111111111111111111111111111111111110000000000000000055555555555555
16666667757777775555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000555555555555555
16666667755555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000005555555555555555
06666677755555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000055555555555555555
06666677755555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000555555555555555551
06666777755555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000005555555556555555511
06666777755555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000055555555555555555111
06666677755555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000555555555555555551111
06666677755555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000005555555555555555511111
06666667755555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000055555555555555555000000
06666667755555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000555555555577777777777777
06666677755555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000005555555555777777777777777
06666677755555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000055555555555777766666777777
06666777755555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000555555555555777666666667766
06666777755555555555555555555000000000000000000000000000000000000000000000000000000000000000000000005555555555555776666666666666
06666677755555555555555555550000000000000000000000000000000000000000000000000000000000000000000000055555555555555776677666666666
06666677755555555555555555500000000000000000000000000000000000000000000000000000000000000000000000555555555755555776677666666666
06666667755555555555555555000000000000000000000000000000000000000000000000000000000000000000000005555555555555555776666666666666
06666667755555555000000000000000000000000000000000000000000000005500000000000000000000000000000055777777777777775776666666666666
06666677755555550000000000000000000011111111111111111111111111155551111111111111111111111111110557777777777777777776666666666666
06666677755555500000000000000000000011111111111111111111111111555555111111111111111111111111115557777666666667777776676666666666
06666777755555000000000000000000000011111111111111111111111115555555511111111111111111111111155557776666666666777776666666666666
06666777755550000060000000000000000011111111111111111111111155555555551111111111111111111111555557766666666666677777666666666666
06666677755500000000000000000000000011111111111111111111111555555555555111111111111111111115555557766776666676677777766666666666
06666677755111111111111111111111111111111111111111111111115555555555555511111111111111111155555557766776666666677777777776666666
06666667751111111111111111111111111111111111111111111111155555555555555551111111111111111555555557766666666666677577777776666666
06666667711111111111111111111111111111111111111111111111555555555555555555777777777777777777777776666666666666677577777757766666
06666677711111111111111111111111111111111111111111111115555555555555555557777777777777777777777776666666666666777777777777766666
06666677711111111111111111111111111111111111111111111155555555555555555557777666667777776677777766666666666666777777777777766766
06666777711111111111111111111111111111111111111111111555555555555555555557776666666677666666776666666666666667777777667777766666
06666777711111111111111111111111111111111111111111115555555555555555555557766666666666666666666666666666666667777776666777776666
06666677711111111111111111111111111111111111111111155555555555555555555557766776666666666666666666666666666666777776666777777666
06666677700000000000000000000000011111111111111111555555555555555555555557766776666666666666666666666666666666777776766777777777
06666667700000000000000000000000011111111111111115555555555555555555555557766666666666666666666666666666666666677776666775777777
16666667711111111111111111111111111100000000000055555555557777777767777776666666666666666666666666666666666666677776666667777777
16666677711111111111111111111111111100006000000555555555577777777777777776666666666666666666666666666666666666777777666667777777
16666677711111111111111111111111111100000000005555555555577776666677777766666666666666666666666666666666666666777777666666777777
16666777711111111111111111111111111100000000055555555555577766666666776666666666666666666666666666666666666667777777766666667766
16666777711111111111111111111111111100000000555555555555577666666666666666666666666666666666666666666666666667777777766666666666
16666677711111111111111111111111111100000005555555555555577667766666666666666666666666666666666666666666666666777777666666666666
16666677711111111111111111111111111100000055555555555555577667766666666666666666666666666666666666666666666666777777666666666666
16666667711111111111111111111111111100000555555555555555577666666666666666666666666666666666666666666666666666677776666666666666
06666667700000000000000000000000000000005577777777777777766666666666666666666666666666666666666666666666666666677776666666666666
06666667700000000888888800000000000000055777777777777777766666666666666666666666666666666666666666666666666666777777666666666666
06776667700000008888888880000000000000555777766666777777666666666666666666666666666666666666666666666666666666777777666666666666
06776667700000008888ffff80000000000005555777666666667766666666666666666666666666666666666666666666666666666667777777766666666666
0666667770000000888f1ff180000000000055555776666666666666666666666666666666666666666666666666666666666666666667777777766666666666
0666677770000000088fffff00000000000555555776677666666666666666666666666666666666666666666666666666666666666666777777666666666666
07777777700000000083333000000000005555555776677666666666666666666666666666666666666666666666666666666666666666777777666666666666
07777777500000000007007000000000055555555776666666666666666666666666666666666666666666666666666666666666666666677776666666666666
07777777777777777777777777777777777777777666666666666666666666666666666666666666666666666666666666666666666666677776666666666666
07777777777777777777777777777777777777777666666666666666666666666666666666666666666666666666666666666666666666777777666666666666
06777777667777776677777766777777667777776666666666666666666666666666666666666666666666666666666666666666666666777777666666666666
06667766666677666666776666667766666677666666666666666666666666666666666666666666666666666666666666666666666667777777766666666666
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666667777777766666666666
06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666777777666666666666

__gff__
0000000000000000000000000008080804020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202020203030505050502020300020202020202000009090909020204020202020202020000070303030004040202020202020200000303030300000002020202020202
0303030002030303000202000300020000020202000303030002020000020000020202020000000000020002000000000002030302000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
62626262626262626262626262626262626262626262626287856262871585626262626262626262626262626262626200000000000000000000000000000000252525252525252624252525252525252624252525260000260000000000002829002a28002a392401003b242525252525262b0000003b240000000000000000
62626262626262626262626262626262626262626262626287856262870085747474747474747474747474747474747400000000000000000000000000000000252525252525252624252525252525252624252525262b0026aa3a39000000280000002800002a24232b3b242525252525262b0058003b240000000000000000
62626262626262626262626262626262626262626262626287856262870040000000007600464700000000000000000000000000000000000000000000000000253232323232252631323232323232252624252525262b0025353629000000280010002800000024262b3b242525252525262b3a10393b310000000000000000
6262626262626262626262626262626262626262626262628785626287000000636464646556576364646500000000000000000000000000000000000000000026280000000031252328000000000024262425252526009926000000000000280000002800000024332b3b24252525252525361b1b1b1b1b0000000000000000
626262626262626262626262626262626262626262626262878562628700002c8562627474868674746262653900000000000000000000000000000000000000262800000000002426280000000000242631252525262b00260000000000002839003a2800003a241b0011242532323225261b00000000000000000000000000
626262626262626262626262626262626262626262626262878562628700003c8562871b1b1b1b1b1b8562872839000000000000000000000000000000000000262900000046472426290000004647242628242525262b00260000000000002a28282829003a2824003b21252634353624263a67585868390000000000000000
62626262626262626262626262626262626262626262626287856262870000636262870000000000008562872a28390000000000000000000000000000000000260000bb00565731260000bc005657372728313232332b0026aa3a390000003a67586839002a2824003b3132331b1b1b31332838283828280000000000000000
62626262626262626262626262626262626262626262626287856262870000856262876758585858688562873a282810000000000000000000000000000000002522222222222223373422222222222126291b1b1b1b0000253536290000002a28292a29003a282439001b1b1b1111111b1b2867585868280000000000000000
62626262626262626262626262626262626262626262626287856262871515856262872828282828288562872a28281000000000000000000000000000000000253232323232252523203132323232242600000000001212262829000000000000000000002a2824290000003b21222311111111110000160000000000000000
626262626262626262626262626262626262626262626262878562628739007374747529000000002a8562873a2829000000000000000000000000000000000026280000000031252628000000000024261111111111212226290000000000001111116867682824000000003b24252522222222232b00000000000000000000
62626262626262626262626262626262626262626262626287856262872a391b1b1b1b0000000000008562872829000000000000000000000000000000000000262800000000002426280000000000242634222222232425260000000000003a212223292a292a24110000003b24252532323225332b00000000000000000000
62626262626262626262626262626262626262626262626287856262873a2828393a3900001600000073747529000000000000000000000000000000000000002629000000464724262900004647002425362425252624252600000100003a2924252600000000242311111111242526202123372b0000000000000000000000
62626262626262626262626262626262626262626262626287856262626464646465290000000000001b1b1b0000000000000000000000000000000000000000260100ba005657242600b40056570024263425252526242525222223003a292824252600464700242522222222252526212525232b0000000000000000000000
62626262626262626262626262626262626262626262626287856262626262626287000000000000000000000000000000000000000000000000000000000000252222232122233133212222222223313236242525263125252525263a29283a24252600565700242525252525252526242525262b0000000000000000000000
626262626262626262626262626262626262626262626262877374626262626274750000000000000000000000000000000000000000000000000000000000002525252624252523212525252525252321222525252600312525253329283a2924252522222222252525252525252526242525262b0000000000000000000000
62626262626262626262626262626262626262626262626287636585626262878f9f00000000000000000000000000000000000000000000000000000000000025252526242525262425252525252526242525252526000025252629283a290024252525252525252525252525252526242525262b0000000000000000000000
7474747474747474747474747474747474747474747474747573757374747475afbf00000000000000000000003a2828000000005800000000000000002a2432323232322525252500000000000000002a8182808281290000000024252525252525262425252525252628282828282800000000000000000000000000000000
282828282828290000000000000000000000000000000000002a2828282828290000000000000000000000000028102867586828103900000000000000003000002a282824252525000000000000000000828182808100003a3a3a242525252525252624252525252526282900002a2800000000000000000000000000000000
28282828283800000000000000000000000000000000000000002a382838290000000000000000000000000000282828283828282122230008000000093a300900002a2824252525000000000000000000808282818200002a282824252525252525263132323232323329000000002a00000000000000000000000000000000
28282828282839000000000000000000000000000000000000000000000000003a39000000000000000000003a282828282838282425252222231515343533390000002a2425252500000000000000000080828182810000002a2a24252525252525252235353535222300000000000000000000000000000000000000000000
646464646464650e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0f636464646464646563646464646464646464646428282828312525252526000000002a2900000000242525250000000000000000008280818181000000000024252525252525252621222222252600000000000000000000000000000000000000000000
6262626262628739000000000000000000000000000000000000003a85626262626262878562626262626262626262622929002a2a312525252600000000000000000000242525250000000000000000008181818181000000000024252525252525252624252525252600000000000000000000000000464700000000000000
7462626262627529000000000000000000000000000000003a101028856262626262628785626262626262626262626200000900003b2448252600000000000900000000313225320000000000000000000000000000000000000024252525253232323324252525252600000000000000000001000000565700000000000000
6585747474752900000000000000000000000000003a676828282828856262626262627585626262626262626262626200000000003b242525266768000000000000a90021233721000000000000000000003a39000000000000002425252525293a282831323232323300000000003a22222222222222222222222222222222
87402828282900000000000000003a39000000003a63646464646465737474747474756362626262626262626262626200000000003b242548261010391114000000b900242522250000000000000000003a28282900000000000024252525253a2828291b1b1b1b1b1b00000000002125252525252525252525252525252525
872828282900000000000000003a2829636464646585626262626287636464646464646262626262626262626262626200000000003b313232332a28282122222222222331322525000000000000000028282810390000003a3a3a24252525252828290000000000000000000000002432252525252525252525252525252532
8728282900000000000000003a28636462626262878562626262628785626262626262626262626262626262626262623939393900001b1b1b1b00292a2425482525252522232425000000000000000029002a282839003a1028282425252525282900000000000000000000000000248e31323232323232323232323232338e
872900000000003a3900003a6365736262626262878562626262628785626262626262626262626262626262626262622828281039000000000009676831323225482525252631320000000000000000000000292a29002a292a2a24252525252900000011111111110000000000002400000000000000000000000000000000
8700000000003a282863646462874173747462628785626262626275856262626262626262626262626262626262626228282900000000090000002a1029002a242525252525222200000000000000000000000000000000000000242525252500000000212222222339000000008b8c00000000000000000000000000000000
87000000003a2863646262626287856464657362877362626262876362626262626262626262626262626262626262622a28010000001111111111110000090024252525252525250000000000000000004647000000000060000024252525253900000124252525252222222222222500000000000000000000000000000000
750001003a636462626262626287856262626573626585626262878562626262626262626262626262626262626262622222231111112122222222233900003a242548252525252500000000000000003956570001003a3970001224252525252222222324252525252525252525252500000000000000000000000000000000
64646464646262626262626262878562626262658587856262628785626262626262626262626262626262626262626225252621222225482525252628393a2824252525252525250000000000000000222222222222222222222225252525252525252624252525252525252525252500000000000000000000000000000000
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
010e00000b620000000b6200500000000000000b620000000b6200000000000000000b62000000000000000032010320153102031025320203202531020310253203032035310303103532030320353103031035
a10e000017030170301703017035170301703017030170351703017030170301703017030170301703017030170201701500000000000000000000320153b0253605500000000000000000000000000000000000
a10e00001a0301a0301a0311a03112030120310e0310e0310e0320e0320e0320e0320e0320e0320e0320e0320e0220e0220e0220e01200000000001202212022120221201500000000000e0220e0320e0420e042
010400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
a10e00000e0400e0400e0400e0450e0400e0400e0400e0450e0400e0400e0400e0400e0400e0400e0400e0300e0200e0150000000000000000000032015360253b01000000000000000000000000000000000000
b90e00200b0440e0410e0410e0420e0420e0420e0310b01100000000000000013032140321703217032170321701217012170100000000000000001202212022000000000012022120220e021000000e0420e055
a10e00000b0400b0400b0400b0450b0400b0400b0400b0450b0400b0400b0400b0400b0400b0400b0400b0300b0200b01500000000000000000000320153b0253601000000000000000000000000000000000000
0108002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
170d0000173101731017320173201733017330173401734017350173501736017360173701737017370173701737017370173701737017370173701736017360000060000000000000003b6752f6752367517675
001000202e750377502e730377302e720377202e71037710227502b750227302b7301d750247501d730247301f750277501f730277301f7202772029750307502973030730297203072029710307102971030710
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001800202945035710294403571029430377102942037710224503571022440274503c710274403c710274202e450357102e440357102e430377102e420377102e410244402b45035710294503c710294403c710
011800202f520000002d520000002a530000002952000000295302a5302b5302c5302f53000000295400000023530215301f5301800023530215301f530000002654226542265422654226542000001e55000000
011800001a54000000235500000026550265502655026550265402653000000000002353023530235302353500000000002653000000235301e5301a530000001e530000001a530000001e530000001a53000000
010c00201e550187001a550187001e550187001a5501f7001e550227001a550227001e5501d70023550357001e550187001a550187001e550187001a5501f7001e550227001a550227001e550235502655035700
01180020265552655526555000002355500000265552655526555000002a55500000265552655526555000002355500000265552655526555000002a55500000265552a555265552a55526555265552655500000
010c00201e5500000000000000001a55000000000000000017550000000000000000125500000000000000000e5550e5550e5550e5550e555000000b555000001a5501a5501a5501a5501a5501a5501a5501a550
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
011000002f35000005000050000500005000050000500005000050000500005000050000500005000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002335000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002635000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002a35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
012000002f35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001327513265132551324513235112651125511245162751626516255162451623513265132551324513275132651325513245132350f2650f2550f2450c25011231162650f24516272162520c2700c255
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
001000003c5753c5453c5353c5253c5153c51537555375453a5753a5553a5453a5353a5253a5253a5153a51535575355553554535545355353553535525355253551535515335753355533545335353352533515
00100000355753555535545355353552535525355153551537555375353357533555335453353533525335253a5753a5453a5353a5253a5153a51533575335553354533545335353353533525335253351533515
001000200c0600c0300c0500c0300c0500c0300c0100c0000c0600c0300c0500c0300c0500c0300c0100f0001106011030110501103011010110000a0600a0300a0500a0300a0500a0300a0500a0300a01000000
001000000506005030050500503005010050000706007030070500703007010000000f0600f0300f010000000c0600c0300c0500c0300c0500c0300c0500c0300c0500c0300c010000000c0600c0300c0100c000
010400001537015370153701537015370153701537015370153701537015370153701536015360153601536015350153501534000000000000000000000000000000000000000000000000000000000000000000
00100020326103261032610326103161031610306102e6102a610256101b610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
00400000302453020530235332252b23530205302253020530205302253020530205302153020530205302152b2452b2052b23527225292352b2052b2252b2052b2052b2252b2052b2052b2152b2052b2052b215
__music__
01 0a4b5644
01 114b4c44
00 0b4c4c44
00 114c4c44
00 13535244
00 0c564c44
00 11564c44
00 114b5244
02 134b4344
02 11424344
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
01 197a7c44
00 1a7b7c44
00 1b424344
00 1b424344
00 1d424344
02 1c424344

