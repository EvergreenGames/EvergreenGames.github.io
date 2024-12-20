pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--[filament - by anti]
--[evercore - v 2.3.1]

-- [initialization]
function vector(x,y)
	return {x=x,y=y}
end

function v0() return vector(0,0) end

function rectangle(str)
local tbl={}
for i=1,4do tbl[split"x,y,w,h"[i]]=split(str)[i]end
return tbl
end

function u(s) 
return unpack(split(s)) 
end

poke(24366,1)

--global tables
objects,got_fruit={},{}
--global timers
delay_restart,sfx_timer,ui_timer=0,0,-99
--global camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25
--level sht for title screen
lvl_x,lvl_y,extinguished=-128,-128,false

-- [entry point]
function _init()
	frames,start_game_flash,lvl_id=0,0,0
	for x=0,128,42 do
		init_object(spotlight,x,rnd'16'-16)
	end
end

function begin_game()
	max_djump=1
	deaths,frames,seconds_f,minutes,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,true,0,0,1

--	load_level(#levels)
load_level(1)
end
--extinguished=true

function is_title()
	return lvl_id==0
end

-- [effects]
embers={}
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

function spikes_at(x1,y1,x2,y2,xspd,yspd,tile)
	for i=max(0,x1\8),min(lvl_w-1,x2/8) do
		for j=max(0,y1\8),min(lvl_h-1,y2/8) do
			if({[17]=y2%8>=6 and yspd>=0,
			[27]=y1%8<=2 and yspd<=0,
			[43]=x1%8<=2 and xspd<=0,
			[59]=x2%8>=6 and xspd>=0})[tile or tile_at(i,j)] then
				return true
			end
		end
	end
end

function spr_r(n,x,y,a)
  local sx,sy,ca,sa=n%16*8,n\16*8,cos(a),sin(a)
  local dx,dy,x0,y0=ca,sa,4+3.5*(sa-ca),4-3.5*(sa+ca)
  for _x=0,7 do
    local srcx,srcy=x0,y0
    for _y=0,7 do
      if (srcx|srcy)&-8==0 then
        local c=sget(sx+srcx,sy+srcy)
        if c~=0 then pset(x+_x,y+_y,c) end
      end
      srcx,srcy=srcx-dy,srcy+dx
    end
    x0,y0=x0+dx,y0+dy
  end
end

function get_player(spawn) --get player or spawn
	local found=nil
	foreach(objects,function(q)
		if q.type==player or spawn and q.type==player_spawn then
			found=q
		end
	end)
	return found
end

function get_sun() --get lightbulb
	local found=nil
	foreach(objects,function(s)
		if s.type==sun and not s.held then
			found=s
		end
	end)
	return found
end

ec=split'1,5,5,2,2,8,13,13,13,9,9,9,9,10,10,10,4,4,7,7'
function new_ember(x,y,yay,kapow)
	local q={
		x=x,
		y=y,
		dir=vector(rnd"1"-.5,rnd"1"-.5),
		life=20,
		size=rnd"2">1 and 2 or 1,
		nyoom=yay, --professional programming right here
	}
	if kapow then
		q.dir.x*=kapow
		q.dir.y*=kapow
	end
	add(embers,q)
end

function get_dist(x1,y1,x2,y2)
	return sqrt((x2-x1)^2+(y1-y2)^2)
end

dp=split'0,0,0,0,0,0,0,0,0,0,0,0,0,0,0'


-->8
-- [update loop]

function _update()
 if not gogogo then --tick all objects once before anything else happens, after all objs are loaded
  gogogo=true
  foreach(objects,function(o)
   (o.type.update or stat)(o);
  end)
 end
	if not is_title() and ui_timer!=-1 then return end
	frames+=1
	bg_col=0
	if time_ticking then
		seconds_f+=1
		minutes+=seconds_f\1800
		seconds_f%=1800
	end
	frames%=30
	
	if sfx_timer>0 then
		sfx_timer-=1
	end



	-- restart (soon)
	if delay_restart>0 then
		cam_spdx,cam_spdy=0,0
		delay_restart-=1
		if delay_restart==0 then
			load_level(lvl_id)
		end
	end

	menuitem(1)
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
	
	foreach(embers,function(e)
	 	e.x+=e.dir.x
  	e.y+=e.dir.y
  	e.life-=e.nyoom and .5 or .8
  	if e.life<=0 then
  		del(embers,e)
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

			start_game_flash,start_game=50,true
		 sfx"11"
			
		end
	end
end
-->8
-- [draw loop]
_pal=pal

function _draw()


	if stop_draw then 
	cls'0'
	foreach(objects,function(b)
	if b.type==flag or b.type==player then b.type.draw(b) end
	b.spd=vector(0,0)
	if b.type==player then
		b.spr=1
	end
	end)
	
	return end
	-- reset all palette values
	pal()

	-- start game flash
	if is_title() then

		cls'3'
		-- credits
		?"🅾️/❎",37,80,0
		?"m\na\nd\nd\ny\n\nt\nh\no\nr\ns\no\nn",87,6,0
		?"n\no\ne\nl\n \nb\ne\nr\nr\ny",45,6,0
		?"m\no\nd\n \nb\ny\n \na\nn\nt\ni",4,6,0
  if not start_game then
  do_lighting(false,true)
  		sspr(unpack(split"72,32,56,16,0,109,128,16"))

  else
   cls'0'
   if not pl_s then
   	pl_s=true
   	--sfx''
   end
  end

		return
	end

	-- draw bg color
	cls'3'
	
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
	palt'0'
	-- draw terrain
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,2)
	palt()
	-- draw fg objects
	foreach(post_draw,draw_object)

	-- draw jumpthroughs
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,8)

	-- dead particles
	foreach(dead_particles,function(p)
		p.x+=p.dx
		p.y+=p.dy
		p.t-=0.2
		if p.t<=0 then
			del(dead_particles,p)
		end
		rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14)
	end)

	-- draw level title
	camera()
	
	do_lighting(ui_timer<=0,ui_timer<=0)
  
 if ui_timer>=0 then
 	ui_timer-=1
 	draw_time(40,52)
 end
end

function draw_time(x,y)
	rectfill(x,y,x+44,y+16,0)
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30)..":"..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,7
	spr(45,x+14,y+5) ?"X"..two_digit_str(deaths),x+21,y+7
	spr(58,x+14,y+13) ?"X"..two_digit_str(fruit_count),x+21,y+13
end

function do_lighting(qqq,jjj)

if qqq then
  	foreach(embers,function(e)
  		circfill(e.x-draw_x,e.y-draw_y,e.size-1,ec[flr(e.life)])
  	end) end
  			  
 	 	--copy screen
  
  	memcpy(u'0,0x6000,0x2000')
  
  	poke(0x5f55,0)
    	
    if jjj then
  	foreach(objects,function(b) 
  		--if onscreen
  		if b.light then--and (b.middle().x+b.brightness>draw_x and b.middle().x-b.brightness<draw_x+128 and b.middle().y+b.brightness>draw_y and b.middle().y-b.brightness<draw_y+128) then --causes issues with searchlight/spotlight
  		
  			--fallback
  			b.l_off=b.l_off or v0()
  			b.emit_d=b.emit_d or v0()
  			
  			if b.light_type==nil or b.light_type=='circle' then --normal light source
  	    	circfill(b.middle().x-draw_x+b.l_off.x or 0,b.middle().y-draw_y+b.l_off.y or 0,b.brightness+rnd(b.brightness/4),14) --circular light  	    
  	  	elseif b.light_type=='field' then --fieldtype lightsource
  	   		for xx=b.left(),b.right(),b.brightness/6 do	--fill hitbox with circular light
  	  				for yy=b.top(),b.bottom(),b.brightness/6 do
  	    			circfill(xx-draw_x,yy-draw_y,b.brightness+rnd(b.brightness/4),14)
  	   		 	end
  	   		end
  	    	for xx=b.left(),b.right(),b.brightness/12 do --larger fillsize / should remove dips
  	    		circfill(xx-draw_x,b.middle().y-draw_y,(b.brightness)+rnd(b.brightness/4),14)
  	    	for yy=b.top(),b.bottom(),b.brightness/12 do
  	    		circfill(b.middle().x-draw_x,yy-draw_y,(b.brightness)+rnd(b.brightness/4),14)
  	    	end	end
  	  	elseif b.light_type=='cone' then --cone lightsource (hanging lamps)
  	    	local _w
  	    	for yy=0,b.hitbox.h-b.brightness*2,b.brightness/6 do --increasing diameter circular light, fill hitbox vertically
  	    		_w=sqrt(yy/b.hitbox.h*yy)
  	 				circfill(b.middle().x-draw_x+b.l_off.x,yy+b.y-draw_y+b.brightness+b.l_off.y,b.brightness+rnd(b.brightness/4)+_w,14)
  	    	end
  	   elseif b.light_type=='search' then
  	   	local _w
  	   	b.search_dist=b.search_dist or 64
  	   	for i=1,b.search_dist,1/1.5 do
  	   		local s_dir=vector(i*cos(b.search_angle/360),i*sin(b.search_angle/360))
  	   		_w=sqrt(i/b.search_dist*i)
  	   		circfill(b.middle().x-draw_x+b.brightness+b.l_off.x+s_dir.x,b.middle().y-draw_y+b.brightness+b.l_off.y+s_dir.y,b.brightness+rnd(b.brightness/4)+_w,14)
  	   	end
  	   	
  	  	end
  	  	if frames%(b.ember_time or 15)==0 and b.emit then --create ember particles
  	  		new_ember(b.middle().x+b.emit_d.x,b.middle().y+b.emit_d.y)
  	  	end
  		end
  	end)
  	foreach(embers,function(e)
  		circfill(e.x-draw_x,e.y-draw_y,e.size,14)
  	end)end
	  
	  poke(0x5f55,0x60)
  
  	palt(14,true)
  
  	pal(dp)
  
  	sspr(u'0,0,128,128,0,0')

  	reload(u'0,0,0x2000')
  	palt()pal()camera()
  	pal(u'3,128,1')
  	pal(u'13,137,1')
  	pal(u'4,135,1')
  	pal(u'8,136,1')
  	pal(u'12,140,1')
end
-->8
-- [player class]

player={
	init=function(this)
	died_already=false
		foreach(split'sun_wait,grace,jbuffer,berry_timer,berry_count,dash_time,dash_effect_time,dash_target_x,dash_target_y,dash_accel_x,dash_accel_y,spr_off',function(v)
			this[v]=0
		end)
		
		this.layer,this.djump,this.hitbox,this.outline,this.collides=1,max_djump
		,rectangle'1,3,6,5'
		,true
		,true
		create_hair(this)
		if lvl_id!=1 and not extinguished then
			this.sun=init_object(sun,this.x,this.y)
			this.sun.held=true
		end
	end,
	update=function(this)
		if stop_player then return end
		menuitem(1,'retry level',function() kill_player(this) end)

		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end
		if this.sun then
					
			if btn'5' and this.sun_wait<0 then --throw sun
					
				this.sun_wait=5
				
				this.sun.held=false
					this.sun.solid_obj=false
				if this.sun.is_solid(1,0) then
					this.sun.x-=1
				end if this.sun.is_solid(0,0) then
					
				
					this.sun.y=this.y+4
				end
				
					
					this.sun.spd=vector(
						this.sun.flip.x and -1 or 1,
						btn'2' and -1.75 or -1
					)
					if not this.flip.x and this.is_solid(1,0) then
						this.sun.move(-1,0,0)
					end
					this.sun.spd.x/=(btn'3' and 3 or btn'2' and 1.333 or .95)
								
				
				this.sun=nil
			end
	
				
		end
		
				this.sun_wait-=1
		if this.sun then
		
			this.sun.flip=this.flip

			this.sun.x=this.x+(this.spr==5 and(this.flip.x and 1 or -1)or 0)
			this.sun.y=this.y+(this.spr==6 and 2 or this.spr==7 and 0 or 1)-6
		
		end
		-- horizontal input
		local h_input=btn'1' and 1 or btn'0' and -1 or 0

		-- on ground checks
		local on_ground=this.is_solid(0,1)

        -- <fruitrain> --
    if this.is_solid(0,1,true) then
      this.berry_timer+=1
    else
      this.berry_timer,this.berry_count=0, 0
    end
    

    for i,f in inext,fruitrain do
      local function kapow(f)
        del(fruitrain, f)
        destroy_object(f);
        this.berry_timer=-5
        (fruitrain[i] or {}).target=f.target
      end
      if i==1 then
        f.target=vector(this.x,this.y)
        f.r=fruitrain[1] and 8 or 12
      end      
      if f.iskey then
      		f.ischest=this.check(chest,0,0) or f.ischest
        if f.ischest and not f.ischest.open then
          f.target,f.r,f.opening=vector(f.ischest.x,f.ischest.y)
          ,1.25
          ,true
  
          
          if f.objcollide(f.ischest,0,0) then
          	f.ischest.open=true
          	f.ischest.altid=f.fruit_id
          	kapow(f)
          end
                    
        end
      end
      

      
     
      
      if f.type==fruit and this.berry_timer>5 and not f.iskey then
        this.berry_count+=1
        fruit_count+=1
        this.berry_timer,got_fruit[f.fruit_id]=-5, true
        if f.altid then
        	got_fruit[f.altid]=true
        end
        init_object(lifeup, f.x, f.y,this.berry_count)
        kapow(f)
      end
    end
    -- </fruitrain> --

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
					
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
					if wall_dir~=0 then
						psfx"2"
						this.jbuffer=0
						this.spd=vector(wall_dir*(-1-maxrun),-2)

					end
				end
			end

			-- dash
			local d_full=5
			local d_half=3.5355339059 -- 5 * sqrt(2)

			if this.djump>0 and dash and not this.sun and this.sun_wait<0 then
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
				-- dash target speeds and accels
				this.dash_target_x=2*sign(this.spd.x)
				this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
				this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
				this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
			elseif this.djump<=0 and dash then
				-- failed dash
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
		local sun_check=this.sun or extinguished
		if this.x>lvl_pw-4 and levels[lvl_id+1] and sun_check and can_exit then
			next_level()
		end

		-- was on the ground
		this.was_on_ground=on_ground
	end,

	draw=function(this,spawn)
		-- clamp in screen
		if not spawn then
		local clamped=mid(this.x,-1,lvl_pw-2-(extinguished and 0 or not this.sun and 4 or 0))
		if this.x~=clamped then
			this.x=clamped
			this.spd.x=0
		end
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
	if not died_already then
	deaths+=1
	died_already=true
	end
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
	fruitrain={}
	
	delay_restart=15
	 		foreach(objects,function(b)
	 			if b.type==sun then
	 				b.held=nil
	 				if obj.sun then
	 				 b.spd=obj.spd
	 				 obj.sun=nil
	 				end
	 			end
	 		end)	
end

player_spawn={
	init=function(this)
		sfx"4"
		if lvl_id!=1 and not extinguished then
			this.light,this.brightness=true,12
		end
		this.outline,this.l_off=true,v0()
		this.spr,this.target,this.x,this.spd.x=3
		,this.x
		,-8
		,1.4
		cam_x,cam_y=mid(this.x+4,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
		create_hair(this)
		this.djump=max_djump
		this.soff=0
		this.layer=1
    --- <fruitrain> ---
    foreach(fruitrain, function(f)
      --this gets called many times but saves tokens for checking if fruitrain is empty
      fruitrain[1].target=this

      add(objects,f)
      f.x,f.y=this.x,this.y
      fruit.init(f)
    end) end,
    --- </fruitrain> ---
	update=function(this)
		this.soff+=.25
		this.spr=1+this.soff%4
		if this.x>this.target then
			this.x=this.target
			destroy_object(this)
			local p=init_object(player,this.x,this.y)
        --- <fruitrain> ---
   ;(fruitrain[1] or {}).target=p
        --- </fruitrain> ---		
		end 
	end,
	draw=function(this)
		player.draw(this,true)
		if lvl_id!=1 and not extinguished then
			spr(113,this.x,this.y-6+(this.spr==6 and 1 or 0),1,1,this.flip.x)
		end
	end,
}
-->8
-- [objects]
retract={
	init=function(this)
	this.layer,this.xoff,this.yoff=-1,0,0
--	this.unsafe=true
	this.rev=this.spr==12
			this.s_rot=this.is_solid(0,1) and 0 or this.is_solid(0,-1) and .5 or this.is_solid(-1,0) and .25 or .75
   this.b=({[0]=17,43,27,59})[this.s_rot*4]
	end,
	
	update=function(this)
		this.active=this.rev and not outlet_power or not this.rev and outlet_power or false

	 local q=this.player_here() or this.check(sun,0,0)
	 if this.active and q and not q.held then
	 local _spd=q.spd
	 	if spikes_at(q.left(),q.top(),q.right(),q.bottom(),q.spd.x,q.spd.y,this.b) then
	 		kill_player(q)
	 	end
	 end
	 this.yoff=appr(this.yoff,(this.active and 0 or (this.b==17 and 5 or this.b==27 and -5 or 0)),.35)
	 this.xoff=appr(this.xoff,(this.active and 0 or (this.b==43 and -5 or this.b==59 and 5 or 0)),.35)
	end,
	
	draw=function(this)
		spr_r(this.spr,this.x+this.xoff,this.y+this.yoff,this.s_rot)
	end,	
}
searchlight={
	init=function(this)
		this.light,this.light_type,this.search_angle,this.brightness=true
		,'search'
		,-90
		,3
		this.l_off=vector(-13,2)
		this.pt=0
		this.return_time=30
		this.hitbox=rectangle'-20,0,48,0'

		while not fget(tile_at(this.middle().x/8,(this.bottom()+1)/8),0) do this.hitbox.h+=8 if this.hitbox.h>=138 then break end end
		this.search_dist=this.hitbox.h-8
		if this.spr==57 then
			this.hitbox=rectangle'-128,-128,256,256'
			this.l_off=vector(-63,128)
			this.spr=41
		end	
		 
	end,
	update=function(this)
	
		local p=this.check(sun,0,0)
		local q=this.player_here()
		
		
		if p and not p.semisolid_obj then
			this.pt=30
		end
				
		if p and this.pt>0 then
			if q then
				this.pt-=1
			end
			this.search_angle=appr(this.search_angle,atan2(p.x-this.x,this.y-p.y)*-360,4)
			this.search_dist=appr(this.search_dist,get_dist(this.x,this.y,p.x,p.y),4)
			this.return_time=30
		elseif q then	
			this.search_angle=appr(this.search_angle,atan2(q.x-this.x,this.y-q.y)*-360,4)
			this.search_dist=appr(this.search_dist,get_dist(this.x,this.y,q.x,q.y),4)
			this.return_time=30
		elseif this.return_time<=0 then
			if p then
				this.pt=30
				return
			end
			this.search_angle=appr(this.search_angle,-90,4)
			this.search_dist=appr(this.search_dist,this.hitbox.h-8,4)
		else
			this.return_time-=1
		end
	end,
	draw=function(this)
		spr_r(this.spr,this.x,this.y,2*(mid(105,-this.search_angle,75)/180))
	end
}
wall={
	init=function(this)
		this.dirx,this.diry=this.is_solid(-1,0) and -1 or this.is_solid(1,0) and 1 or 0
		,this.is_solid(0,-1) and -1 or this.is_solid(0,1) and 1 or 0
				this.hitbox=rectangle'0,0,0,0'
		this.light,this.p=true,{}
		this.unsafe,this.light_type,this.brightness=true
		,'field'
		,4.5
		this.rev=this.spr==103
		if this.dirx!=0 then
			this.diry=0
				this.hitbox.y+=3
				this.hitbox.h+=1
				while not fget(tile_at((this.right()+1)/8,this.y/8),0) do this.hitbox.w+=8 if this.right()>lvl_pw then break end end
		end
		if this.diry!=0 then
			this.hitbox.x+=4
			this.hitbox.w+=1
			while not fget(tile_at(this.x/8,(this.bottom()+1)/8),0) do this.hitbox.h+=8 if this.bottom()>lvl_ph then break end end

		end
		
		this._hitbox=this.hitbox
		this.hitbox=rectangle(this._hitbox.x..','..this._hitbox.y..',0,0')
				this.activated=false
	end,
	update=function(this)
		this.active=this.rev and not outlet_power or not this.rev and outlet_power or false
		if this.active then
			this.solid_obj=true
			this.hitbox.x,this.hitbox.y=this._hitbox.x,this._hitbox.y
				this.hitbox.w=appr(this.hitbox.w,this._hitbox.w,8)
				this.hitbox.h=appr(this.hitbox.h,this._hitbox.h,8)
				if this.hitbox.w==this._hitbox.w and this.hitbox.h==this._hitbox.h then
					this.deployed=true
				end
			else
			this.hitbox=rectangle'0,0,0,0'
		end
	end,
	draw=function(this)
		local a=this.dirx==-1 and 0 or this.dirx==1 and .5 or this.diry==1 and .75 or this.diry==-1 and .25
		if this.active then
			line(this.left(),this.top(),this.right(),this.bottom(),12)
			line(this.left()-(this.dirx==0 and 1 or 0),this.top()+1,this.right()-(this.dirx==0 and 1 or 0),this.bottom()+(this.dirx==0 and 0 or 1),1)
		end
		if frames%3==0 and this.active then
			if this.dirx!=0 then
				local pos=rnd(this.hitbox.w)+this.x
				add(this.p,{x=pos,y=this.y+this.hitbox.y,l=5+rnd"15",s=vector(rnd"1"-.5,rnd"1"-.5)})
			else
				local pos=rnd(this.hitbox.h)+this.y
				add(this.p,{x=this.x+this.hitbox.x,y=pos,l=5+rnd"15",s=vector(rnd"1"-.5,rnd"1"-.5)})
			end
		end
		foreach(this.p,function(p)
			p.l-=1
			if p.l<=0 then del(this.p,p) end
			p.x+=p.s.x
			p.y+=p.s.y
			pset(p.x,p.y,12)
		end)
		spr_r(this.spr,this.x,this.y,a)
--		?"["..this.dirx..","..this.diry.."]",this.x,this.y,13
	end,

}

off={ --good rpg
	init=function(this)
		spotlight.init(this) --im so smart
		this.active=this.spr==42 or this.spr==104
		this.active_wait=flr(rnd"15"+30)
		this.light=this.active
		this.emit=this.active
		this.rev=this.rev or this.spr==42 or this.spr==104
			this.q={}
			for i=1,45,3 do --optimise later
				this.q[i]=rnd"1">.5 and true or false
				this.q[i+1]=this.q[i]
				this.q[i+2]=this.q[i]
				if i>20 then this.q[i],this.q[i+1],this.q[i+2]=false,false,false end
			end		
			this.spr=65
	end,
	update=function(this)
		if this.rev and not outlet_power or not this.rev and outlet_power or false then
			this.active_wait=max(-1,this.active_wait-1)

			
			if this.active_wait<0 then
				this.light=true
				this.emit=true
			else
				this.light=this.q[this.active_wait]
			end
			this.done=false
		elseif not this.done then
			this.done=true
			this.type.init(this)
		end
		
	
		
		
	end,
}
off2={
	init=function(this)
		off.init(this)
		this.light_type='circle'
		this.l_off=vector(-1,0)
		this.brightness=12
		this.spr=81
	end,
	update=off.update
}
decay={
	init=function(this)
			can_exit=false
			this.x+=4
	end,
	update=function(this)
		this.hitbox=rectangle'0,5,4,2'
		if not this.powered then
			this.powered=this.check(sun,0,0)
		end
		local s=this.powered
		local function g(s)
				(s and destroy_object or stat)(s);
				this.powered,extinguished,can_exit,outlet_power=nil
			,true
				,true
				,true
				destroy_object(this)
		end
		if s then 
				s.y_off,s.spd.x,s.x,s.y,s.rot,s.drain=-1
				,0
				,this.x-1,this.y
				,.75
				,true
--			if not s.drain then
--				this.light,this.brightness=false,0
--			end
			s.reached=s.reached or 0
			if s.reached==0 then
				s.brightness=appr(s.brightness,42,0.25)
				s.reached=s.brightness==42 and 1 or 0
			elseif s.reached==1 then
				s.brightness=appr(s.brightness,0,1)
				s.reached=s.brightness==0 and 2 or 1
			elseif s.reached==2 then
				for i=1,40 do
					new_ember(s.middle().x,s.middle().y+4,false,5)
				end
				g(s)
			end
			
		
		end
		if extinguished then g(s) end
	end,
	
	draw=function(this)
		sspr(48,32,16,16,this.x-4,this.y-8)
	end
}
outlet={
	init=function(this)
		this.hitbox=rectangle'0,5,4,2'
		this.x+=2
		if this.spr==40 then
			this.powered=init_object(sun,this.x,this.y)
		end
		if this.spr==56 then
			this.powered=init_object(sun,this.x,this.y)
			this.shatter=true
			this.powered.solid_obj=true
			this.powered.shatter=true
		end
		this.spr=21
	end,
	update=function(this)
		this.powered=this.check(sun,0,0)

		if not this.powered and this.shatter then
		 destroy_object(this)
		end
		if this.powered then
			this.powered.spd.x=0
			this.powered.x=this.x-2
			this.powered.y_off=-2
			this.powered.y=this.y
			this.powered.rot=.75
			this.light,this.brightness=false,0
		
			outlet_power=true
		else
			outlet_power=false
			this.light,this.brightness=true,4
		end
		foreach(objects,function(b)
			if b.type==outlet and b.powered then
				outlet_power=true
			end
		end)
	end,
	draw=function(this)
		local kx=this.x
		if not this.powered then
			line(this.x+1+rnd"2",this.y+6,this.x+(rnd"5"),this.y-rnd"6"+6,10)
		end
		draw_obj_sprite(this)
	end,
}

sun={ --i just 100% oneshot so i kinda had to call the lightbulb the sun lol
	init=function(this)
		this.light,this.brightness=true,12
		this.emit=true
		this.search_dist=0
		this.outline=true
		this.ember_time=10
		this.unsafe=true
		this.spr=113
		this.layer=2

		this.rot=0
		this.hitbox=rectangle'1,1,7,7'
		this.semisolid_obj,this.collides=true,true
		this._hitbox=this.hitbox
		this.l_off=vector(0,4)
		this.online=true --for shattered version
	end,
	update=function(this)
		if not this.drain then
--		this.search_angle=(this.rot)*-360
		
		if not this.held then
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end
		end
		
		--prevent bugged hold
		if get_player() and get_player().sun==nil and this.held then
			this.held=false
			this.spd=vector(this.flip.x and -.3333 or .3333,-1)
		end
		
		--dislodge if other sun held
		foreach(objects,function(b)
			if b.type==sun and this!=b and b.held and this.held then
				this.held=false
				this.spd=vector(this.flip.x and -1 or 1,-1)
			 this.spd=vector(this.flip.x and -.3333 or .3333,-1)
				
			end
		end)
		
		if this.held then
			this.semisolid_obj=false
		else
							-- spike collision / bottom death

			local on_ground=this.is_solid(0,1)			
			if on_ground and this.spd.x==0 then
				this.semisolid_obj=true
				this.hitbox=rectangle'1,0,7,8'
				if not this.shatter then
				local above=this.player_here(0,0)
				if above then
					if btn(⬇️) and btn(❎) then
						above.sun=this
						this.held=true
						above.sun_wait=5
					end
				end
				else
					this.hitbox=rectangle'-2,-2,12,12'
					local hit=this.player_here()
					
					if hit and this.online then
						if hit.dash_time>0 then
							for i=1,45 do
							 new_ember(this.middle().x,this.middle().y+4,false,5)
							end
								destroy_object(this)
								hit.dash_time=0
								sfx(12)
								hit.djump=max_djump
								hit.dash_effect_time=0
				   	hit.spd=vector(hit.spd.x,-hit.spd.y/3)
								this.online=false
								return
						end
					end
					
					this.hitbox=rectangle'0,0,8,8'
				end
	
				this.hitbox=this._hitbox
									
			else

				this.rot=this.x/32
				if frames%2==0 then --burn
					new_ember(this.middle().x,this.middle().y+4,true)
				end
			end


			-- apply gravity
			if not on_ground then
				this.spd.y=appr(this.spd.y,2,abs(this.spd.y)>0.15 and 0.21 or 0.105)
			else
				this.spd.x=appr(this.spd.x,0,0.075)
			end

			
		end
		end
	end,
	draw=function(this)
				-- clamp in screen
		local clamped=mid(this.x,-1,lvl_pw-2)
		if this.x~=clamped then
			this.x=clamped
			this.spd.x=0
		end
		if this.held then
			spr(this.spr,this.x,this.y,1,1,this.flip.x)
		else
			spr_r(this.spr,this.x,this.y+1+(this.y_off or 0),this.rot)
			this.y_off=0
		end
	end
}
spotlight={
	init=function(this)
		this.light=true
		this.emit=true
		this.emit_d=vector(1,7)
		this.light_type='cone'
		this.brightness=6
		this.l_off=vector(0,3)
--		this.emit=true
--		this.emit_d=vector(0,6)
		while not fget(tile_at(this.middle().x/8,(this.bottom()+1)/8),0) do this.hitbox.h+=8 if this.hitbox.h>=92 then break end end
	end,
}
bulb={
	init=function(this)
		this.emit=true
		this.light,this.brightness=true,12
		this.l_off=vector(-1,0)
--		this.emit=true
	end,
}
spring={
	init=function(this)
		this.delta=0
		this.dir=this.spr==18 and 0 or this.is_solid(-1,0) and 1 or -1
		this.show=true
		this.layer=-1
	end,
	update=function(this)
		this.delta=this.delta*0.95
		local hit=this.player_here() or this.check(sun,0,0)
		
		if this.show and hit and this.delta<=1 and not hit.held then
		
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

balloon={
	init=function(this)
--		this.light,this.brightness=true,6
		this.offset=rnd'1'
		this.start=this.y
		this.timer=0
		this.l_off=vector(0,3)
		this.hitbox=rectangle'-1,-1,10,10'
	end,
	update=function(this)
--		this.light=this.spr==22
		if this.spr==22 then
			this.offset+=0.01
			this.y=this.start+sin(this.offset)*2
			local hit=this.player_here()
			if hit and hit.djump<max_djump then
				psfx"6"
				
				hit.djump=max_djump
				this.spr=0
				this.timer=60
			end
		elseif this.timer>0 then
			this.timer-=1
		else
			psfx"7"
		
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

--- <fruitrain> ---
fruitrain={}
fruit={
  check_fruit=true,
  init=function(this)
  this.brightness=5
  this.l_off=vector(0,3)
    this.y_,this.off,this.tx,this.ty=this.y,0,this.x,this.y
  end,
  update=function(this)
    if this.target then
    this.light=true
  		this.l_off=vector(-rnd'1',3)
    
      this.tx+=0.2*(this.target.x-this.tx)
      this.ty+=0.2*(this.target.y-this.ty)
      local dtx,dty=this.x-this.tx,this.y_-this.ty
      local a,k=atan2(dtx,dty),dtx^2+dty^2 > this.r^2 and 0.2 or 0.1
      this.x+=k*(this.r*cos(a)-dtx)
      this.y_+=k*(this.r*sin(a)-dty)
    else
      local hit=this.player_here()
      if hit then
        hit.berry_timer,this.target,this.r=
        0,fruitrain[#fruitrain] or hit,fruitrain[1] and 8 or 12
        add(fruitrain,this)
      end
    end
    this.off+=0.025
    this.y=this.y_+sin(this.off)*2.5
    if this.iskey then
		this.spr=flr(9.5+sin(frames/30))
		if frames==18 then --if spr==10 and previous spr~=10
			this.flip.x=not this.flip.x
		end    
    end
  end
}
--- </fruitrain> ---

lifeup={
	init=function(this)
		this.spd.y=-0.25
		this.light=true
		this.brightness=8
		this.duration=30
		this.flash=0
	end,
	update=function(this)
		this.duration-=1
		this.l_off=vector(-1,-2+rnd'1')
		
		if this.duration<=0 then
			destroy_object(this)
		end
		this.flash+=0.5
	end,
	draw=function(this)
    --<fruitrain>--
        color((this.spr>=6 and {7,11} or {7,8})[((flr(this.flash))%2)+1])

    ?split"1000,2000,3000,4000,5000,1up"[min(this.spr,6)],this.x-4,this.y-4
    --<fruitrain>--
	end
}

function init_fruit(this,ox,oy)
	sfx_timer=20
	sfx"16"
	local qx,qy=this.x,this.y
	destroy_object(this)
	local f=init_object(fruit,qx+ox,qy+oy,26)
	f.fruit_id=this.fruit_id
	f.altid=this.altid
end

key={
check_fruit=true,
	update=function(this)
		this.spr=flr(9.5+sin(frames/30))
		if frames==18 then --if spr==10 and previous spr~=10
			this.flip.x=not this.flip.x
		end
		local hit=this.player_here()
		if hit and not this.obtained then
			sfx"23"
			sfx_timer=10
			destroy_object(this)
			local b=init_object(fruit,this.x,this.y)
   b.target,b.r,b.fruit_id=
   fruitrain[#fruitrain] or hit,fruitrain[1] and 8 or 12,this.fruit_id
   b.iskey=true
   b.spr=8
   add(fruitrain,b)
   
		end
	end
}

chest={
	check_fruit=true,
	init=function(this)
		this.x-=4
		this.l_off=vector(0,3)
		this.start=this.x
--		this.light,this.brightness=true,6
		this.timer=20
	end,
	update=function(this)
		if this.open then
			this.timer-=1
			this.x=this.start-1+rnd"3"
			if this.timer<=0 then
				init_fruit(this,0,-4)
			end
		end
	end
}

big_chest={
	init=function(this)
		this.state=max_djump>1 and 2 or 0
		this.hitbox.w=16
		this.light,this.light_type,this.brightness=true,'field',10
	end,
	update=function(this)
		if this.state==0 then
			local hit=this.check(player,0,8)
			if hit and hit.is_solid(0,1) then
				sfx"37"
				
				this.state=1
				
				this.timer=60
				this.particles={}
			end
		elseif this.state==1 then
			this.timer-=1
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
				s=init_object(sun,this.x+4,this.y-4,102)
				s.spd=vector(0,-3)
				this.light=false
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

flag={
	init=function(this)
--		this.light,this.brightness=true,12
		this.x+=5
		this.layer=200
	end,
	update=function(this)
		if not this.show and this.player_here() then
			sfx"55"
			sfx_timer,this.show,time_ticking=30,true,false
		end
	end,
	draw=function(this)
		spr(118,this.x,this.y)
		if this.show then
			camera()
--			cls()
--			rectfill(u'32,2,96,31,0')
--			spr(26,55,6)
--			?"x"..two_digit_str(fruit_count),64,9,7
			draw_time(40,52)
--			?"deaths:"..two_digit_str(deaths),48,24,7
--   ?"yadlie",36,1
   stop_player=true
   stop_draw=true
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
		hitbox=rectangle'0,0,8,8',
		spd=v0(),
		rem=v0(),
		layer=0,
		
		fruit_id=id,
	}

	function obj.left() return obj.x+obj.hitbox.x end
	function obj.right() return obj.left()+obj.hitbox.w-1 end
	function obj.top() return obj.y+obj.hitbox.y end
	function obj.bottom() return obj.top()+obj.hitbox.h-1 end
	function obj.middle() return
	  vector((obj.hitbox.x/2)+(obj.hitbox.w/2)+obj.x,
	  (obj.hitbox.y/2)+(obj.hitbox.y/2)+obj.y)
	end
	
	function obj.is_solid(ox,oy,req_safe)
		for o in all(objects) do
			if o!=obj and (o.solid_obj or o.semisolid_obj and not obj.objcollide(o,ox,0) and oy>0) and obj.objcollide(o,ox,oy) and not (req_safe and o.unsafe) then
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
	if obj.rot then
		spr_r(obj.spr,obj.x,obj.y,obj.rot)
	else
		spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
	end
end
-->8
-- [level loading]

function next_level()
	local next_lvl=lvl_id+1

	

	load_level(next_lvl)
end

function load_level(id)
	has_dashed,has_key=false
	can_exit,gogogo=true

	--remove existing objects
	foreach(objects,destroy_object)
	embers={}
	
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
	ui_timer=30

	--reload map
	if diff_level then
		reload()
		--check for mapdata strings
		if mapdata[lvl_id] then
	for i=1,#mapdata[lvl_id],2 do
		mset(lvl_x+i\2%lvl_w,lvl_y+i\2\lvl_w,"0x"..sub(mapdata[lvl_id],i,i+1))
	end		
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
-->8
-- [metadata]

--length=length/16
--1.5625=25/16

--@begin
--level table
--"x,y,w,h,title"
levels={}
foreach(split([[
0,0,2,1
2,0,1,1
1.0625,0,1.9375,1
3,0,1,2
4,0,1,1
0,1,1,2
0,0,1.0625,1
5,0,1,1
6,0,1,1
7,0,1,1
1,1,1,1
2,1,1,2
1,2,1,1
4,1,1,1
5,1,1,1
6,1,2,1
3,2,1,1
0,3,2,1
6,2,2,2
]],'\n'),function(l)
if(l!='')add(levels,l)
end)

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
"2525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252532323232323232323232323232323232323232323232323232323232323232320041000000000000000000000029000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000001000000000000000000000000000000000000000000700000000000000000222222222222222222222222222222222222222222222222222222222222222225252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525",
"0000000000000000000000000000000000000000000000000000000000000000000000212222222222222222222222220000002425252525252525252525252500000031323232323232323232323d25000000000000000000000000000024250012000051000000000000000000242522222222222222230000000000002425252525252525252600000000000024253232323232323233000000005100242500000000000000000000002122223c250000000000000000000000242525252500010000000000000000003132323d25222223000000212223000000000024252525260000002425260000000000242525252600000024252600000000002425",
}

--@end

--tiles stack
--assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
1,player_spawn
8,key
18,spring
19,spring
20,chest
22,balloon
23,fall_floor
26,fruit
45,fly_fruit
64,fake_wall
96,big_chest
118,flag
65,spotlight
81,bulb
113,sun
21,outlet
28,off
42,off
97,wall
104,off2
40,outlet
11,retract
12,retract
103,wall
88,off2
41,searchlight
86,decay
57,searchlight
56,outlet
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
--function get_mapdata(x,y,w,h)
--	local reserve=""
--	for i=0,w*h-1 do
--		reserve..=num2hex(mget(x+i%w,y+i\w))
--	end
--	printh(reserve,"@clip")
--end
--
----convert mapdata to memory data
--function num2hex(v)
--	return sub(tostr(v,true),5,6)
--end
__gfx__
00000000000000000000000008888880000000000000000000000000000000000099999000099900000090000000000000000000111111111111111111111111
00000000088888800888888088288888088888800888880000000000082888800090009000090900000090000000000000000000111111111111111111111111
000000008828888888288888822ffff888288888888882800888888082f1ff18009d0d9000090900000090000000000000000000000110000000000000011000
00000000822ffff8822ffff882f1ff18822ffff88ffff2208828888882fffff800d999d0000d9d00000090000070007000700070001100000000000000001100
0000000082f1ff1882f1ff1808fffff082f1ff1881ff1f20822ffff888fffff80000900000009000000090000070007000700070011000000000000000000110
0000000008fffff008fffff00055550008fffff00fffff8082fffff80855558000dd9000000d9000000090000677067706770677110000000000000000000011
00000000005555000055550006000060065555000055556008f1ff1000555500000d900000009000000090005626562656165616100000000000000000000001
000000000060060000600060000000000000060000006000066555600060060000999000000d9000000090005686568656c656c6000000000000000000000000
000000003333333300000000000000000000000000000000008888000000000000000000000000000b00b0b06665666500805000000000000000000070000000
000000003333333300000000000d000000000000000000000888888000000000000000000000000000bbbb006765676508a82000007700000770070007000007
00000000333333330000000000095050099999900000000008788880000000000000000000000000028888206773677308a85500007770700777000000000000
00000000337333730d9999d00009050592288889000000000888888000000000000000000000000008988880373337338aaa8600077777700770000000000000
55550000337333730050050000090505928888890000000008888880000000000000000000000000088889803733373388888a60077777700000700000000000
5555000036773677000550000009505099999999070700000888888000000000000000000000000008898880333333330069a960077777700000077000000000
555500005676567600500500000d00009281188957075000008888000000000000000000000000000288882033333333006a8a60070777000007077007000070
55550000566656660005500000000000928888896666600000000000000000000000000000000000002882003333333300066600000000007000000000000000
11111111111111111111111111111111110100000000000000001011111111110000828200005000001050005533333300001011000000000000555555550000
1111111111111111111111111111111111010000000000000000101111111111000082820001200001c120006673333300001011000000000000555555550000
1100001111000000000000000000001111010000000000000000101111000011000082820015550001c155006777733300001000077770000000555555550000
110110111101111111111111111110111101000000000000000010111101101100000000001666001ccc16006663333300001111117117000000555555550000
110110111101000000000000000010111101000000000000000010111101101100008282016d8d6011111d605533333300000000117117000000000000000000
1100001111010000000000000000101111010000000000000000101111011011070700000c699d60006d9a606673333300000000077770000000000000000000
111111111101000000000000000010111101000000000000000010111101101157075000cc64a960006aaa606777733300000000070700000000000000000000
11111111110100000000000000001011110100000000000000001011110110116666600000066600000666006663333300000000000000000000000000000000
110110111101000000000000000010111111111111111111111111111101101100820082008250000b0b0b003333366611010000000000000000000000000000
1101101111010000000000000000101111111111111111111111111111011011000828200082200000bbb0003337777611010000000000000000000000000000
11011011110100000000000000001011110000000000000000000011110110110000820088888200028882003333376600010000000000000000000000000000
110110111101000000000000000010111101111111111111111110111101101100082820008266000898880033333355111100000000000000000000000000b0
11011011110111111111111111111011110111111111111111111011110110110082008201828d60028892003333366600000000111100000000111100000b00
1101101111000000000000000000001111000000000000000000001111000011070700000c699d60002820003337777600000000000100000000100000000b00
110110111111111111111111111111111111111111111111111111111111111157075000cc64a960000000003333376600000000110100000000101100b0b000
11011011111111111111111111111111111111111111111111111111111111116666600000066600000000003333335500000000110100000000101100000000
00005555000050000000000550000000555555550000000000000000000000000000000000030000000000000000000000000000000000000000000000000000
00005555000020000000005555000000555555550000000000000000000000000000000000303000000000000000000000000000000000000000000000000000
00005555000555000000055555500000555555550000000000000000000000000000000000303000000000000000000000000000000000000000000030000300
00005555000666000000555555550000555555550000000000000000000000000000000000303003003300000000000000000000000000000000000003303300
00005555006d8d600005555555555000555555550000555500000000000000000000000033303000003330000000000000000000000000000000000000033000
0000555500699d600055555555555500555555550000555500000000000000000000000030330030033030000033300000000000000000000000000000003300
000055550064a9600555555555555550555555550000555500000000000000000000000033300030030030000330300033033303300000000000000000003033
0000555500066600555555555555555555555555000055550c00000000000c000000000003330030030030000300300003330333030000333300030000003000
5555000000666000555555555555555500000000555555551c00000000000c100066680003033030030030003000030003300033030000300300033003003000
5555000006aa460005555555555555500000000055555555570000000000075006998a8003033300030330033000030000300033033000300300003033003000
5555000006d9a600005555555555550000000000555555555708000000080750069a8a8030030300030300030000030000300030003000300300033030303000
555500000698d60000055555555550000000000055555555572800000008275006a8aaa830030330003300330000030000300000003000303300303330303000
55550000016660000000555555550000555555550000000057570000000757500168888830300033333333330000033003300000003000333003003300300303
55550000001150000000055555500000555555550000000057570070700757500011500003000000000000033330333303000000003033333033033000300333
55550000000210000000005555000000555555550000000057570570750757500002100000000000000000000033300333000000003300003330030000330000
5555000000050cc000000005500000005555555500000000656566555665656000050dd000000000000000000000000000000000000000000000000000000000
00000000770000000000000550000000000055555555000000000000770000000066610000000000000000005555555555555555050505055555555555555555
000000006667700000000055550000000000555555550000000000006667700006991c1000000000000000005555555055555555505050505555555555555555
0000000065200000000005555550000000005555555500000000000065200000069a1c1000000000000000005555550505555555050505055555555555555555
111111117cc0000000005555555500000000555555550000000000007cc0000006a1ccc100000000000000005555505050555555505050505555555555555555
11111111711000005555555555555555000555555555500000000000711000000161111100000005500000005555050505055555050505055555555555555555
11555555652000005555555555555555005555555555550000000000652000000011500000000055550000005550505050505555505050505555555055555555
11555555666770005555555555555555055555555555555000000000666770000002100000000555555000005505050505050555050505055555550505555555
115555557700000055555555555555555555555555555555000000007700000000050dd000005555555500005050505050505055505050505555505050555555
11111111000000005555555555555555555555555555555500599900005900000050099900005555555500005505050505050505000000005555550505055555
1111111a000666005555555555555555055555555555555000599999005990000059999900000555555000005550505050505055000000005555555050555555
11555519006aa4605555555555555555005555555555550005100999051999990519990000000055550000005555050505050555000000005555555505555555
1155551156a17aa65555555555555555000555555555500005000000050099900500000000000005500000005555505050505555000000005555555555555555
1155555556da7a960000555555550000000055555555000005000000050000000500000000000000000000005555550505055555000000005555555555555555
1155555556d179960000055555500000000055555555000051000000510000005100000000000000000000005555555050555555000000005555555555555555
11111111006dd9600000005555000000000055555555000050000000500000005000000000000000000000005555555505555555000000005555555555555555
11111111000666000000000550000000000055555555000050000000500000005000000000000000000000005555555555555555000000005555555555555555
525252525262444444444252525252525252e323d3e32323232323232323d35223232323232323d3624434004252525200000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d6d6d6425262d6d6d6d6d6d6425262d6d6d6d6d6d6d6d6133344444434142444
e32323232333274437a71323232323d3e3233344133344358024440244444252c6444444444444426244440042525252232323232323d300e323232323232323
0000000000000000000000000000000000000000000000000000000000000000d6d6c7425262d6d6d6d6d6d6425262d6d6d6d6d6d6d6c7141444444444444444
6244444437a70025000097274437a742624444444444444353632502024413d3d6444444572544426244443642525252444436a6140042006200149626444444
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6d6d6d6d6d6425262d6d6d6d6d6d6d635000025444444444444
62444436a6000000009626443541004262444353634443633514244444444442d6c61232a7004742622744444252525244444444a60042006236264444444444
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6d6d6d6d6d6425262d6d6d6d6d6c7d600000000002544444444
c22222222232000000971222222222c362444444444435000000447235724413d6d6426200829742620044444252525244444444443642006244444444374444
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6d6d6d6d6d6425262d6d6d6d6d644d600000000000000254444
232323232333310000311323232323d362441232435353637624447324734353d6d642c2222222c3622444354252525244444444444442006244444435864644
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6d6d6d6d6d6425262d6d6d6d6d644d600000000000000672544
4444444444350000002444444444444233441333561400464444444444444444d6d6132323232323334435001323d35244354644443542006244445712222222
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6d6d6d6d6d6425262c7d6d6d6d644d600000000001222222222
44444444370000000025444444444442444444444436a6444444444444444444d6d64437a70000009735000000b342523510972744004200624444a742000000
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6d6d6d6d6d642526244d6c7b7d644b700000000004252525252
444444a700000000000097444444444244274444444444444444444444444444d6c74444340000111100000000b3425222223200440042006225443442000000
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6d6b7d6d6b742526244d64444c7443500006100004252525252
444435000000000000000047444444425700972744444444444444444444443522222222320024123216000000b3425200006276250013233316444442000000
0000000000000000000000000000000000000000000000000000000000000000d6d644425262d6c744d6d64413233344d6444444440000000000004252525252
44440000000012222232009744444442a700000000512544122232444444350023232323332644426234000000b34252000062b2000000000000254442000000
0000000000000000000000000000000000000000000000000000000000000000d6d644425262c74444b7d64434142544b7444425440000002400004252525252
4435000000004252526200002544444200000024122232b6425262443515004197274444444444426244008000b34252000062b2000000000000004442000000
0000000000000000000000000000000000000000000000000000000000000000d6d64442526244444444d6444400004444354400350000004400004252525252
57000000e0f042525262d0e000002542101524b6425262d6425262441222222200004744444444426244340000b34252000062b2000000000000002542000000
0000000000000000000000000000000000000000000000000000000000000000d6d64442526244444444d6254400003544004400000000004400004252525252
a7100000243442525262340000005142222232d6425262d6425262b64252525200109727444444426244444434b34252000062b2000000000000000042000000
0000000000000000000000000000000000000000000000000000000000000000d6d64442526244444444c7004400000025004400000061004400004252525252
222232b6f6e642525262c634001222c3525262d6425262d6425262d64252525222222222222222c3c22222222222c35200006216000000830000002442000000
0000000000000000000000000000000000000000000000000000000000000000d6d6444252622544354444342524000000002500003400004400244252525252
525262d6d6d642525262d6c634425252525262d6425262d6425262d64252525252525252525252525252525252525252000062b20096264436a624b642000000
0000000000000000000000000000000000000000000000000000000000000000d6c7444252620025244444443444000000000000244400244400444252525252
5252525252525252e3232323d3525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d644441323330034444444444444000000000024444434444434444252525252
5252e3232323d3526200c1004252e323232323232323232323232323232323230000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d6443500140000444444444444350000244444444444444444c6444252525252
52526200c10042526200000042526200a20000000000962644444437a71600000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d6440000000024444444442544003400122222223244b64444d6444252525252
2323330000004252620000004252620000000000862444444444444436a600000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000c7440000000044444444443444004400425252526244d6c644d6444252525252
00140000000042526200000013233300000012222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000444400340024444444444444446144004252525262b6d6c7b6d6c64252525252
00000000000013233300000000960000000042525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000443524442444444444444444440044244252525262d6d644b7d6d64252525252
0000000000000000960000962644360000004252525252525252e3232323d3520000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000444444444444444444444444442444444252525262b7d6c644d6d64252525252
100041000000000046000044444444a600964252e3232323d3526200a20042520000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000044444444444444444444444444444444425252526244d6d6c6b7d64252525252
222232340000009644a6244444444405244442526200c10042526200000042520000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000444444444444444444442544444444444252525262c6b7d6d6c6d64252525252
52526244009626444456444412223256444442526200962642526200800042520000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000004444444444444444444434444444b6444252525262d644d6d6d6d64252525252
5252624400464444444444b642526244444413233326444413233376000042520000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000002544444444b61222222232c64444d6444252525262d6c6d6d6d6d64252525252
52526244004444444444e6d6425262c6444444444444b64444445600000042520000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000444444b6d64252525262d64444d6c64252525262d6d6d6d6d6d64252525252
525262c63444122232b6d6d6425262d6c64444444444d6c6444444a6000042520000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000354444d6d64252525262d6c644d6d64252525262d6d6d6d6d6d64252525252
525262d6f644425262d6d6d6425262d6d6f6444444b6d6d6f6444456830042520000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000102544d6d64252525262d6d6b6d6d64252525262d6d6d6d6d6d64252525252
525262d6d6f6425262d6d6d6425262d6d6d6122232d6d6d6122222222222c3520000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000222232b6d6d64252525262d6d6d6d6d64252525262d6d6d6d6d6d64252525252
525262d6d6d6425262d6d6d6425262d6d6d6425262d6d6d642525252525252520000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000525262d6d6d64252525262d6d6d6d6d64252525262d6d6d6d6d6d64252525252
__label__
ggggggggggggg0000000000000000000000000000000ggggg0000000000000000000000000000000ggggggggggggggggg00000000000000000000000000000gg
gggggggggggggg0000000000000000000000000000ggggggggg00000000000000000000000000000ggggggggggggggggg0000000000000000000000000000ggg
gggggggggggggg000000000000000000000000000ggggggggggg0000000000000000000000000000ggggggggggggggggg000000000000000000000000000gggg
gggggggggggggg00000000000000000000000000ggggggggggggg000000000000000000000000000ggggggggggggggggg000000000000000000000000000gggg
ggggggggggggg000000000000000000000000000ggggggggggggg000000000000000000000000000ggggggggggggggggg00000000000000000000000000ggggg
ggggggggggggg00000000000000000000000000ggggggggggggggg0ggg0000000000000000000000ggggggggggggggggg00000000000000000000000000ggggg
gggg000gggggg00000000000000000000000000gggggg00gggggggggggg000000000000000000000ggggggg000ggggggg00000000000000000000000000ggggg
gggg000gggggg00000000000000000000000000gggggg0g0ggggggggggg000000000000000000000ggggggg000ggggggg00000000000000000000000000ggggg
gggg0g0gggggg00000000000000000000000000gggggg0g0ggggggggggg000000000000000000000ggggggg0g0ggggggg00000000000000000000000000ggggg
gggg0g0gggggg00000000000000000000000000gggggg0g0gggggg0ggg000000000000000000000gggggggg0g0gggggggg0000000000000000000000000ggggg
gggg0g0gggggg00000000000000000000000000gggggg0g0gggggg0000000000000000000000000gggggggg0g0gggggggg0000000000000000000000000ggggg
ggggggggggggg00000000000000000000000000ggggggggggggggg0000000000000000000000000ggggggggggggggggggg0000000000000000000000000ggggg
ggggg00gggggg00000000000000000000000000ggggggg00gggggg0000000000000000000000000gggggggg000gggggggg0000000000000000000000000ggggg
gggg0g0gggggg0000000000000000000000000ggggggg0g0ggggggg000000000000000000000000gggggggg0g0gggggggg0000000000000000000000000ggggg
gggg0g0gggggg0000000000000000000000000ggggggg0g0ggggggg0000000000000000000000000ggggggg000ggggggg00000000000000000000000000ggggg
gggg0g0gggggg0000000000000000000000000ggggggg0g0ggggggg0000000000000000000000000ggggggg0g0ggggggg0000000000000000000000000gggggg
gggg00ggggggg0000000000000000000000000ggggggg00gggggggg000000000000000000000000gggggggg0g0gggggggg000000000000000000000000gggggg
ggggggggggggg0000000000000000000000000ggggggggggggggggg000000000000000000000000ggggggggggggggggggg000000000000000000000000gggggg
gggg00gggggggg000000000000000000000000ggggggg000ggggggg000000000000000000000000gggggggg00ggggggggg000000000000000000000000gggggg
gggg0g0ggggggg000000000000000000000000ggggggg0ggggggggg000000000000000000000000gggggggg0g0gggggggg000000000000000000000000gggggg
gggg0g0ggggggg000000000000000000000000ggggggg00gggggggg000000000000000000000000gggggggg0g0gggggggg000000000000000000000000gggggg
gggg0g0ggggggg000000000000000000000000ggggggg0ggggggggg00000000000000000000000ggggggggg0g0ggggggggg00000000000000000000000gggggg
gggg000ggggggg000000000000000000000000ggggggg000ggggggg00000000000000000000000ggggggggg000ggggggggg0000000000000000000000ggggggg
gggggggggggggg00000000000000000000000ggggggggggggggggggg0000000000000000000000ggggggggggggggggggggg0000000000000000000000ggggggg
gggggggggggggg00000000000000000000000gggggggg0gggggggggg0000000000000000000000ggggggggg00gggggggggg0000000000000000000000ggggggg
gggggggggggggg00000000000000000000000gggggggg0gggggggggg0000000000000000000000ggggggggg0g0ggggggggg0000000000000000000000ggggggg
ggggggggggggggg0000000000000000000000gggggggg0gggggggggg0000000000000000000000ggggggggg0g0ggggggggg0000000000000000000000ggggggg
ggggggggggggggg0000000000000000000000gggggggg0gggggggggg0000000000000000000000ggggggggg0g0ggggggggg0000000000000000000000ggggggg
ggggggggggggggg0000000000000000000000gggggggg000gggggggg0000000000000000000000ggggggggg000ggggggggg0000000000000000000000ggggggg
ggggggggggggggg0000000000000000000000ggggggggggggggggggg0000000000000000000000ggggggggggggggggggggg0000000000000000000000ggggggg
gggg000gggggggg0000000000000000000000ggggggggggggggggggg000000000000000000000gggggggggg0g0gggggggggg000000000000000000000ggggggg
gggg0g0gggggggg000000000000000000000ggggggggggggggggggggg00000000000000000000gggggggggg0g0gggggggggg000000000000000000000ggggggg
gggg00ggggggggg000000000000000000000ggggggggggggggggggggg00000000000000000000gggggggggg000gggggggggg00000000000000000000gggggggg
gggg0g0gggggggg000000000000000000000ggggggggggggggggggggg00000000000000000000gggggggggggg0gggggggggg00000000000000000000gggggggg
gggg000ggggggggg00000000000000000000ggggggggggggggggggggg00000000000000000000gggggggggg000gggggggggg00000000000000000000gggggggg
gggggggggggggggg00000000000000000000ggggggggggggggggggggg00000000000000000000ggggggggggggggggggggggg00000000000000000000gggggggg
gggg0g0ggggggggg00000000000000000000ggggggggg000ggggggggg00000000000000000000ggggggggggggggggggggggg00000000000000000000gggggggg
gggg0g0ggggggggg00000000000000000000ggggggggg0g0ggggggggg00000000000000000000ggggggggggggggggggggggg00000000000000000000gggggggg
gggg000ggggggggg00000000000000000000ggggggggg00gggggggggg00000000000000000000ggggggggggggggggggggggg00000000000000000000gggggggg
gggggg0ggggggggg0000000000000000000gggggggggg0g0gggggggggg0000000000000000000ggggggggggggggggggggggg00000000000000000000gggggggg
gggg000ggggggggg0000000000000000000gggggggggg000gggggggggg000000000000000000ggggggggggggggggggggggggg0000000000000000000gggggggg
gggggggggggggggg0000000000000000000ggggggggggggggggggggggg000000000000000000ggggggggggggggggggggggggg0000000000000000000gggggggg
gggggggggggggggg0000000000000000000gggggggggg000gggggggggg000000000000000000ggggggggggg000ggggggggggg0000000000000000000gggggggg
gggggggggggggggg0000000000000000000gggggggggg0gggggggggggg000000000000000000gggggggggggg0gggggggggggg0000000000000000000gggggggg
gggggggggggggggg0000000000000000000gggggggggg00ggggggggggg000000000000000000gggggggggggg0gggggggggggg0000000000000000000gggggggg
gggggggggggggggg0000000000000000000gggggggggg0gggggggggggg000000000000000000gggggggggggg0gggggggggggg000000000000000000ggggggggg
gggggggggggggggg0000000000000000000gggggggggg000gggggggggg000000000000000000gggggggggggg0gggggggggggg000000000000000000ggggggggg
gggggggggggggggg0000000000000000000ggggggggggggggggggggggg00000000000000000ggggggggggggggggggggggggggg00000000000000000ggggggggg
gggg000ggggggggg0000000000000000000gggggggggg000gggggggggg00000000000000000gggggggggggg0g0gggggggggggg00000000000000000ggggggggg
gggg0g0ggggggggg0000000000000000000gggggggggg0g0gggggggggg00000000000000000gggggggggggg0g0gggggggggggg00000000000000000ggggggggg
gggg000ggggggggg0000000000000000000gggggggggg00ggggggggggg00000000000000000gggggggggggg000gggggggggggg00000000000000000ggggggggg
gggg0g0ggggggggg000000000000000000ggggggggggg0g0ggggggggggg0000000000000000gggggggggggg0g0gggggggggggg00000000000000000ggggggggg
gggg0g0ggggggggg000000000000000000ggggggggggg0g0ggggggggggg0000000000000000gggggggggggg0g0gggggggggggg0000000000000000gggggggggg
ggggggggggggggggg00000000000000000ggggggggggggggggggggggggg0000000000000000ggggggggggggggggggggggggggg0000000000000000gggggggggg
gggg00ggggggggggg00000000000000000ggggggggggg000ggggggggggg0000000000000000ggggggggggggg00gggggggggggg0000000000000000gggggggggg
gggg0g0gggggggggg00000000000000000ggggggggggg0g0ggggggggggg0000000000000000gggggggggggg0g0gggggggggggg0000000000000000gggggggggg
gggg0g0gggggggggg00000000000000000ggggggggggg00gggggggggggg0000000000000000gggggggggggg0g0gggggggggggg0000000000000000gggggggggg
gggg0g0ggggggggggg0000000000000000ggggggggggg0g0ggggggggggg0000000000000000gggggggggggg0g0gggggggggggg0000000000000000gggggggggg
gggg0g0ggggggggggg0000000000000000ggggggggggg0g0ggggggggggg000000000000000ggggggggggggg00gggggggggggggg000000000000000gggggggggg
gggggggggggggggggg0000000000000000ggggggggggggggggggggggggg000000000000000ggggggggggggggggggggggggggggg000000000000000gggggggggg
gggg000ggggggggggg0000000000000000ggggggggggg0g0ggggggggggg000000000000000ggggggggggggg000ggggggggggggg00000000000000ggggggggggg
ggggg0gggggggggggg0000000000000000ggggggggggg0g0ggggggggggg000000000000000ggggggggggggg0g0ggggggggggggg00000000000000ggggggggggg
ggggg0ggggggggggggg00000000000000gggggggggggg000gggggggggggg00000000000000ggggggggggggg00gggggggggggggg00000000000000ggggggggggg
ggggg0ggggggggggggg00000000000000gggggggggggggg0gggggggggggg00000000000000ggggggggggggg0g0ggggggggggggg00000000000000ggggggggggg
ggggg0ggggggggggggg00000000000000gggggggggggg000gggggggggggg00000000000000ggggggggggggg0g0ggggggggggggg00000000000000ggggggggggg
ggggggggggggggggggg00000000000000ggggggggggggggggggggggggggg00000000000000ggggggggggggggggggggggggggggg00000000000000ggggggggggg
gggg000gggggggggggg00000000000000ggggggggggggggggggggggggggg00000000000000gggggggggggggg00ggggggggggggg00000000000000ggggggggggg
ggggg0ggggggggggggg00000000000000ggggggggggggggggggggggggggg0000000000000gggggggggggggg0gggggggggggggggg0000000000000ggggggggggg
ggggg0ggggggggggggg00000000000000ggggggggggggggggggggggggggg0000000000000gggggggggggggg000gggggggggggggg0000000000000ggggggggggg
ggggg0ggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggggg0gggggggggggggg0000000000000ggggggggggg
gggg000gggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggg00ggggggggggggggg0000000000000ggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000ggggggggggggggggggggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000ggggggggggggggg00gggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggg0g0gggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggg0g0gggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggg0g0gggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggg00ggggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000ggggggggggggggggggggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggg00ggggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000ggggggggggggggggggggggggggggg000000000000gggggggggggggg0g0gggggggggggggg000000000000gggggggggggg
ggggggggggggggggggg0000000000000gggggg00000gggg0gg00000gggggg000000000000gggggggggggggg0g0gggggggggggggg00000000000ggggggggggggg
gggggggggggggggggggg000000000000ggggg00ggg00gg0gg00g0g00ggggg000000000000gggggggggggggg0g0gggggggggggggg00000000000ggggggggggggg
gggggggggggggggggggg00000000000gggggg00g0g00gg0gg000g000gggggg000000000000ggggggggggggg0g0ggggggggggggg000000000000ggggggggggggg
gggggggggggggggggggg00000000000gggggg00ggg00gg0gg00g0g00gggggg000000000000ggggggggggggggggggggggggggggg000000000000ggggggggggggg
gggggggggggggggggggg00000000000ggggggg00000gg0gggg00000ggggggg000000000000ggggggggggggggggggggggggggggg000000000000ggggggggggggg
gggggggggggggggggggg00000000000ggggggggggggggggggggggggggggggg0000000000000ggggggggggggggggggggggggggg0000000000000ggggggggggggg
gggggggggggggggggggg00000000000ggggggggggggggggggggggggggggggg0000000000000ggggggggggggggggggggggggggg0000000000000ggggggggggggg
gggggggggggggggggggg00000000000ggggggggggggggggggggggggggggggg00000000000000ggggggggggggggggggggggggg00000000000000ggggggggggggg
ggggggggggggggggggg000000000000ggggggggggggggggggggggggggggggg000000000000000ggggggggggggggggggggggg000000000000000ggggggggggggg
ggggggggggggggggggg000000000000ggggggggggggggggggggggggggggggg0000000000000000ggggggggggggggggggggg0000000000000000ggggggggggggg
ggggggggggggggggggg000000000000ggggggggggggggggggggggggggggggg00000000000000000ggggggggggggggggggg00000000000000000ggggggggggggg
gggggggggggggggggg0000000000000ggggggggggggggggggggggggggggggg000000000000000000ggggggggggggggggg000000000000000000ggggggggggggg
gggggggggggggggggg0000000000000ggggggggggggggggggggggggggggggg00000000000000000000ggggggggggggg00000000000000000000ggggggggggggg
ggggggggggggggggg00000000000000ggggggggggggggggggggggggggggggg00000000000000000000000ggggggg000000000000000000000000gggggggggggg
gggggggggggggggg0000000000000000ggggggggggggggggggggggggggggg0000000000000000000000000000000000000000000000000000000gggggggggggg
ggggggggggggggg00000000000000000ggggggggggggggggggggggggggggg0000000000000000000000000000000000000000000000000000000gggggggggggg
gggggggggggggg000000000000000000ggggggggggggggggggggggggggggg00000000000000000000000000000000000000000000000000000000ggggggggggg
ggggggggggggg00000000000000000000ggggggggggggggggggggggggggg000000000000000000000000000000000000000000000000000000000ggggggggggg
ggggggggggg0000000000000000000000ggggggggggggggggggggggggggg0000000000000000000000000000000000000000000000000000000000gggggggggg
0ggggggg00000000000000000000000000ggggggggggggggggggggggggg000000000000000000000000000000000000000000000000000000000000ggggggggg
00000000000000000000000000000000000ggggggggggggggggggggggg00000000000000000000000000000000000000000000000000000000000000gggggggg
000000000000000000000000000000000000ggggggggggggggggggggg0000000000000000000000000000000000000000000000000000000000000000ggggggg
0000000000000000000000000000000000000ggggggggggggggggggg000000000000000000000000000000000000000000000000000000000000000000gggggg
00000000000000000000000000000000000000ggggggggggggggggg000000000000000000000000000000000000000000000000000000000000000000000gggg
0000000000000000000000000000000000000000ggggggggggggg00000000000000000000000000000000000000000000000000000000000000000000000000g
0000000000000000000000000000000000000000000ggggggg000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000gg00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000gg00gg000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000gg00gg000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000gg000000000gg00000
00000gg00gg00000gg00000gggg0000000000000000000000000000000000000000000000000000000000000000000000000000000000000ggggg00gggg00000
ggggggg00gg000000000000ggggggg000000000000000000000000000000000000000000000000000000000000000000000000000000000000000gggg0000000
gg000gggg00000gg00000gggg00ggg00000000000ggggggg00000000000000000000000000000000000000000000000000000000000000000000000gggg00000
ggggggg0000000gg00000gg0000ggg000000000gggg000gg0000000gggg000ggggggg00gggg00000000000000000000000000000000000000000000gg00ggggg
00ggggggg00000gg00000gg0000ggg000000000gg00000gg000000000ggggggg00ggggggg00ggg000000000ggggggggg0000000gg00000000000000gg0000000
00ggg00gggg000gg00000gg0000ggg0000000gg000000000gg0000000ggggg0000000gggg00ggg000000000gg00000gg0000000gggg00000gg00000gg0000000
00ggg00ggggggg0000000gg00ggggg0000ggggg000000000gg000000000ggg0000000gggg00ggggg0000000gg00000gg000000000gg000gggg00000gg0000000
gg00000gg00ggg0000000gg00gg0000000ggg00000000000gg000000000ggg0000000gg0000000gg0000000gg00000gg0000000gggg000gg00ggg00gg0000000
gg00000gg00ggggg0000000gggg00000ggggg00000000000gg000000000ggg0000000000000000gg0000000gg00ggggg00000gg00ggggggg00ggg00gg0000000
gg000gg0000000ggggggggggggggggggggggg00000000000ggggg0000ggggg0000000000000000gg0000000ggggggg0000ggg0000ggggg0000ggg0000gg000gg
00ggg00000000000000000000000000000ggggggggg000ggggggggg00gg0000000000000000000gg00gggggggggggg00ggggg00gggg0000000ggg0000ggggggg
00000000000000000000000000000000000000000ggggggg00000gggggg0000000000000000000gggg000000000ggggggg00000gg000000000ggggg000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000008080804020000000000000000000200000000030303030303030300000002030004040303030303030303000000020303030204000404040400000400000000000000040004040404000000000000000000000000040404040000000404040404040400000404040400000004040404040404
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2500000000000000395244737a000000000000000000410000000074242525253e32323232323232323232323232323d2525252525253e32323232323232323225252525252525252525252525252525323232323232323232323232323d2525253e3232326d25252525252525252525253e3232323232326d326d3232323d25
0000000000000000000000000000000000000000000000000000004024252525260041000074750074750074751b1b24252525252525264444444473557a000032323232323232323232323232323d256d6d7c533900424444530b0b0b2425252526000000242525252525252525252525260000000000000000000000002425
000034353535353535353535353535362000000000000000000000402425252526000000006465006465006465111124323232323232334444737a0000000000002a74444444444444444444444424256d7c44000042444453000000422425252526000800243e32323232323232323d25260000000000000000000000002425
00000000000000000000000000000000210000000000000000000040242525252600006921222222222223747521223c1b1b1b1b1b1b1b724444636a14000000000079444444444444444444737a24256d445300424434360b0b0b424424252532330000002426001c000000001b1b2425260000000000000000000000002425
000000000000000000000000000000002400000000000000000000402425252526000040243e3232323d26646524252511110069111111007421222222222222000000524444444444445300000024256d4421233435353536212344442425250c0c000000242600000000000000002425260000212222222222222300002425
00000000000000000000000000000000240000000000000000000064313232323300006424267500742426747524252522236a6421222300793132323232323d0000004244444444737a0015000024256d4424261a000c0c0c2426444424252500000c580c2426000000201111110024252600003132323d3e32323300002425
12001111000015000011110000000000240000000000000000696244444473557a6962442426651a643133646524252525266544242526000000000000003b2400000021222222222222222222223c256d44242600000c000c24264453313d25000c2122223c26000000212222230b2425260000000000242600000000002425
22222222222222222222222222230b0b24000000000000004244444444446a510064444424267500747500747524252525264444242526000000000000003b24000000242525252525252525252525256d6f31333435360c0c242653003b2425000c313232323300000024252526002425260000000000242600000000002425
3232323232323232323232323d260b0b24000000000000694444444444442122234444442426650064655164652425252526444424252c222222222223003b240d0e00242525252525253e32323232326d7c5300000000000024262b003b242500000000001c0000000024252526002425260000000000242600000000002425
00000000000000000c0c000031330b0b2400000000000064444444444444242526444444242c222222222222223c252525264444313232323232323233636a24000000242525252525252644444444447c53580b0b0b58006924262b003b242500580000000000000000242525260024252c2222230000242600002122223c25
000000000000000000000000000000002400010000004244444444444444242526444444242525252525252525252525252644731b1b1b696244444444444424000e0f31323232323232334444737a7422222222222223436424262b003b2425222222230000002122223c252526002432323232330000242600003132323232
00000000000000000c0c000000000000312222230000444444212223446b242526444444313232323232323232323232252653696244444444444444444444240000007444444444444444447500004032323232323233444424262b003b313232323233000000313232323232330b3100000000000000242600000000000000
000000000000000021230b0000002122222525266362444444242526446d24252644444444444444444444447b6d6d6d252c222222222223524421222222223c0000007972445374447944737a0058790079724444444444442426000000426b0000000000000000000c0c0c0c00000000000000000000242600000000000000
000100000000000024260b0000152425002525266f4444446e2425266e6d2425266f4444444444444444446b6d6d6d6d32323232323232330074313232323d250001000000520079530053003b21222200016962444444444424260015426b6d0001000000000000580c0c0c0c00150000010014000000242600000000000000
2222230b000b21223c260b0021223c25002525266d6c446b6d2425266d6d2425266d6c6e2122222222222222222222221b1b1b1b1b00000000791b1b1b3b242522232b0000000000580000003b2425252222222222222222223c2c222222222222222223000000212222222222222222222222222222223c2c22222222222222
2525260b000b242525260b0024252525002525266d6d6d6d6d2425266d6d2425266d6d6d2425252525252525252525256a0011111100000000001100003b242525262b0000003b2122232b003b242525252525252525252525252525252525252525252600000024252525252525252525252525252525252525252525252525
00000000000000000000000000426b6d3e3232323232323d3e3232323232323d2525252525252525252525252525252565692122234300212222232b003b242525252525252525252525252525252525252525253e323232323232323d2525252525252525252525252525252525252525252525252525252525252525252525
000000000000000000000068426b6d6d2644445300410024260c2a0052444424253e323232323232323232323232323244442425264463242525262b003b24252525253e32323232323232323d252525252525252644444444651c0024252525253e3232323d25252525252525253e3232323232323232323232323232323d25
000000000000005800692122222222222644444443000024260c00000052442425267444444444737a6100000061426b44443132334444313232332b003b24252525252644431c00001c424424252525252525252675797244444300242525252526001c692425252525252525252644444444444444737a424444737a002425
00000000006921222344243e3232323d2644444444444324260c00000028522425262e7244447a000000000000426b6d444444444444444444737a00003b24252525252644444300004244442425252525252525267a380044444463242525253233430064313232323232323232334444444444737a38424444636a08002425
0000000000403132334424262b1c3b242c22222344444424260c000c2122223c2526002852444463546a0014426b6d6d44444444444444444444636a113b242525252526444453000052444424252525252525252c22222223444444242525256d6d6c6a4444444444737a79444444737a212334353535364444212343002425
4300005800797244444424262b003b242525252644444431330c000c24252525252c222223444421222222222222222244442122222222222344442122223c2525253e334453000000005244313d25252525253e3232323233444444242525256d7c446544444453005869624444533800242644444444534444242644422425
44632122236a0052444424262b083b24252525264444731b1b00000c242525252525252526444424253e3232323d25254444313232323d25264444243232323d2525264444430046470042444424252525252526001c7944444444442425252522234444442122222222222344442122223c2644445338004444242644442425
6c44313233500000794424262b00002425252526444400000000000c2425252532323232334444313233444444313d254444444444442425264444302b003b2425252644430000565700004244242525252525260000424444444444242525253233444453243e32323232337444313232323344442122234444313344442425
6d444444447a0000004424262b000024252525264444631111110c0c2425252500000079557a797244444444445324254444444444442425264444302b003b24252526444434222222223644442425252525252600424421222222223c2525256d6c44444324260000000042794444447a004244442425264444737a42442425
6d44444444636a154244242600003b242525252674444421222222223c252525000011111111000074445328000024252222222374442425264444302b083b243e32334444443132323344444431323d323232336244443132323232323232326d6d7c44442426000058424463447a00384244444424252644636a3800742425
6d6c21222222222222223c2600000024252525262e7244243e32323232323232003b2122222300692122222222223c252525252679442425264444302b003b2433000052444444444444444453670031444444444444444444445361000000612223444444242c22222222222222222222222222223c252c2222222222223c25
6d6d24253e323232323232332b00002432323233000052313344445300006142003b313232330064313232323d252525323232330052243e334444372b003b2400000000535852444453585200000000524444444444444444530000000000003233444444313232323232323232323232323232323232323232323232323232
6d6d31323343001c1c000000000000240000000000437972444444000000426b00001b1b1b1b6944444444442425252500000000000024262b52444444636a24000000003422236b6c21223600000000000052444444444444000000000000000000524444444453006100006100005244444444445300000000000000000000
6d6d7c4444446300000000000000002400010069626c0069624444636a426b6d0069624444444444444444442425252500010000003b24262b00524444444424015800424324266d6d242642430058000001585244444444530000000068000000014244530b0b00000000000000006842444453680000001468000000006800
6d7c444444444443696221222222223c222222236b6d6321236b6d6c2122222222222222222222222344537924252525222222232b3b24262b3b21222222223c2223426b6c24266d6d24266b6c432122222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222344444444242525252525252525266d6d6c24266d6d6d2425252525252525252525252644000024252525252525262b3b24262b3b242525252525252c236d213c266d6d242c236d213c25252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525
__sfx__
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
901000200060500605006050060500605006050060500000256750060519655006050d6350060501615006050060500605006050060500605006050060500605256750060519655006050d635006050161500605
0103000030674296601d6501a6400f6300a6250060000601006010060100601016010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100000
900200003f6023d6623f6723a6623c6623765239662346523665232642346522f642316422c6322e642296322b6322662228632236222562221612226221e6122061212602016020360212602046021360210602
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000002953429554295741d540225702256018570185701856018500185701856000500165701657216562275142753427554275741f5701f5601f500135201b55135530305602454029570295602257022560
011000200a0700a0500f0710f0500a0600a040110701105007000070001107011050070600704000000000000a0700a0500f0700f0500a0600a0401307113050000000000013070130500f0700f0500000000000
002000002204022030220201b0112404024030270501f0202b0402202027050220202904029030290201601022040220302b0401b030240422403227040180301d0401d0301f0521f0421f0301d0211d0401d030
010800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000201312013110131101311013100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 0a424344
00 0a424344
00 0a0b4344
02 0a424344

