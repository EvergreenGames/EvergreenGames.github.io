pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- [initialization]
-- evercore v2.3.1
-- bump jump mania v1.0 by cominixo
-- wow i actually finished this?

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

cartdata("bumpjumpmania")

function back_to_menu()
	_init()
end

menuitem(1, "back to menu", back_to_menu)

characters = {
	{spr=1, cost=0, name="madeline", color=8, animated=true}, 
	{spr=8, cost=10, name="badeline", color=2, animated=true},
	{spr=96, cost=20, name="periline", color=8, animated=true},
	{spr=23, cost=25, name="adeline", color=8, animated=true},
	{spr=80, cost=30, name="caroline", color=1, animated=true},
	{spr=160, cost=35, name="solanum", color=2, animated=true},
	{spr=112, cost=40, name="funkeline", color=4, animated=true},
	{spr=144, cost=45, name="wuffeline", color=8, animated=true},
	{spr=64, cost=50, name="pikashock", color=0, animated=true},
	{spr=18, cost=60, name="adelie", color=0, animated=true},
	{spr=69, cost=100, name="roundelie", color=0, animated=false},
	{spr=70, cost=200, name="gold roundelie", color=0, animated=false},
	{spr=128, cost=300, name="snekeline", color=8, animated=true},
}

selected_char = dget(0) != 0 and dget(0) or 1
changing_chars = false

-- [entry point]

function _init()
	highscores = {}
	best_highscore = 0
	global_x = 0
	-- global tables
	objects,collected={},{}
	-- global timers
	freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
	-- global camera values
	draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25
	
	start_game = false

	frames,start_game_flash=0,0
	music(40,0,7)
	lvl_id=0
	bump_mode=3
	for i=3,6 do
		highscores[i] = dget(i)
		if highscores[i] > best_highscore then
			best_highscore = highscores[i]
		end
	end
end

function begin_game()
	last_score = 0
	max_djump=0
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,1
	pause_player=true
	just_died=false
	--music(0,0,7)
	load_level(1)
	if best_highscore < characters[selected_char].cost then
		selected_char = 1
	end

	dset(0, selected_char)

	init_object(player, 8+(bump_mode*16), 90, characters[selected_char].spr)
end

function is_title()
	return lvl_id==0
end

-- [effects]

-- clouds={}
-- for i=0,16 do
-- 	add(clouds,{
-- 		x=rnd"128",
-- 		y=rnd"128",
-- 		spd=1+rnd"4",
-- 	w=32+rnd"32"})
-- end

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
			global_x = 0
			load_level(lvl_id)
			init_object(player, 8+(bump_mode*16), 90, characters[selected_char].spr)
		end
	end

	local player_x_mov = 0

	-- update each object
	foreach(objects,function(obj)
		if (obj.type != bump) then
			if (obj.type == player) then
				player_x_mov = obj.move(obj.spd.x,obj.spd.y,0)
			else
				obj.move(obj.spd.x,obj.spd.y,0)
			end
			(obj.type.update or stat)(obj)
		end
	end)

	global_x -= player_x_mov

	-- update bumps
	foreach(objects,function(obj)
		if (obj.type == bump) then
			obj.x -= player_x_mov
			obj.move(0,0,0)
			obj.type.update(obj)
		end
	end)

	

	-- move camera to player and update hair x
	foreach(objects,function(obj)
		if obj.type == player then
			move_camera(obj)
			obj.fake_x += player_x_mov
			obj.x_amt = player_x_mov
		end
	end)

	-- start game
	if is_title() then
		local h_input= btn(➡️) and 1 or btn(⬅️) and -1 or 0
		local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0

		if start_game then
			start_game_flash-=1
			if start_game_flash<=-30 then
				begin_game()
			end
		elseif (prev_v_input != v_input and v_input != 0) then
			changing_chars = not changing_chars
		elseif (prev_h_input != h_input) then
			if not changing_chars then
				bump_mode += h_input
				bump_mode = mid(bump_mode,3,6)
			else
				selected_char += h_input
				selected_char = mid(selected_char, 1, #characters)
			end
		elseif btn(🅾️) or btn(❎) then
			music"-1"
			start_game_flash,start_game=50,true
			sfx"38"
		end

		prev_h_input = h_input
		prev_v_input = v_input
	end
end
-->8
-- [draw loop]

function smap(mx,my,x,y,mxs,mys,xs,ys)
	-- mx = section of map to draw top left corner x in tiles
	-- my = section of map to draw top left corner y in tiles
	-- mxs = width of map section to draw in tiles
	-- mys = height of map section to draw in tiles
	-- x = screen position top left corner x in pixels
	-- y = screen position top left corner y in pixels
	-- xs = how wide to draw section in pixels
	-- ys = how tall to draw section in pixels
	
	local yo=((mys*8-1)/ys)/8
	for i=1,ys+1 do
		tline(x,y-1+i,x+xs,y-1+i,mx,my-yo+i*yo,((mxs*8-1)/xs)/8)
	end
end

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
		sspr(unpack(split"72,32,56,32,36,32,56,32"))
		?"🅾️/❎",55,68,5
		if changing_chars then
			if bump_mode == 6 then
				?"mode: <\f3 random \f5> best: "..highscores[bump_mode],0,90,5
			else
				?"mode: <\f3 "..(bump_mode-1).."-wide \f5> best: "..highscores[bump_mode],0,90,5
			end
			?"> character: <\f3 "..(characters[selected_char].name).." \f7>",0,98,7
		else
			if bump_mode == 6 then
				?"> mode: <\f3 random \f7> best: "..highscores[bump_mode],0,90,7
			else
				?"> mode: <\f3 "..(bump_mode-1).."-wide \f7> best: "..highscores[bump_mode],0,90,7
			end
			?"character: <\f3 "..(characters[selected_char].name).." \f5>",0,98,5
		end

		spr(characters[selected_char].spr, 0, 106)
		if (selected_char != 1) then
			?"get a score of "..characters[selected_char].cost.." or more",0,118,5
			if best_highscore >= characters[selected_char].cost then
				?"unlocked",10,108,11
			else
				?"locked",10,108,8
			end

		end

		?"maddy thorson",0,0,5
		?"noel berry",0,6,5
		?"mod by cominixo",68,0,5

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
	map(lvl_x,lvl_y,(global_x%256)-256,0,lvl_w,lvl_h,4)
	map(lvl_x,lvl_y,global_x%256,0,lvl_w,lvl_h,4)
	map(lvl_x,lvl_y,(global_x%256)+256,0,lvl_w,lvl_h,4)
	
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

	map(lvl_x,lvl_y,(global_x%256)-256,0,lvl_w,lvl_h,2)
	map(lvl_x,lvl_y,global_x%256,0,lvl_w,lvl_h,2)
	map(lvl_x,lvl_y,(global_x%256)+256,0,lvl_w,lvl_h,2)

	
	-- draw fg objects
	foreach(post_draw,draw_object)

	-- draw jumpthroughs
	map(lvl_x,lvl_y,(global_x%256)-256,0,lvl_w,lvl_h,8)
	map(lvl_x,lvl_y,global_x%256,0,lvl_w,lvl_h,8)
	map(lvl_x,lvl_y,(global_x%256)+256,0,lvl_w,lvl_h,8)

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
	rectfill(0,0,32+(#tostr(score))*4,6,0)
	print("score: "..score, 0,0,7)

	rectfill(0,5,48+(#tostr(highscores[bump_mode]))*4,6+6,0)
	print("high score: "..highscores[bump_mode], 0, 6, 7)

	if pause_player and not is_title() then
		if just_died then
			rect(30-1,128/4-2-1, 32+15*4+8+1,128/4+6+16+1,7)
			rectfill(30,128/4-2, 32+15*4+8,128/4+6+16,0)

			print("score: "..last_score, 32, 128/4+8, 7)
			print("high score: "..highscores[bump_mode], 32, 128/4+16, 7)
		else 
			rect(30-1,128/4-2-1, 32+15*4+8+1,128/4+6+1,7)
			rectfill(30,128/4-2, 32+15*4+8,128/4+6,0)
		end

		print("press 🅾️ to jump!", 32, 128/4, 7)
	end
	-- if ui_timer>=-30 then
	-- 	if ui_timer<0 then
	-- 		draw_ui()
	-- 	end
	-- 	ui_timer-=1
	-- end
end

function draw_particle(p)
	p.x+=p.spd-cam_spdx
	p.y+=sin(p.off)-cam_spdy
	p.off+=min(0.05,p.spd/32)
	circ(p.x+draw_x,p.y%128+draw_y,p.s,p.c)
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
		this.collideable=true
		this.solid_obj=true
		this.x_amt=0
		this.base_spr=this.spr

		this.fake_x=this.x
		create_hair(this)
		
		this.layer=1
	end,
	update=function(this)
		-- jump and dash input
		local jump,dash=btn(🅾️) and not this.p_jump,btn(❎) and not this.p_dash
		this.p_jump,this.p_dash=btn(🅾️),btn(❎)

		if pause_player then
			if jump then 
				pause_player = false 
			else
				return
			end
		end

		-- horizontal input
		local h_input= btn(➡️) and 1 or btn(⬅️) and -1 or 0

		-- spike collision / bottom death
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end

		if (this.is_solid(0,1)) then
			kill_player(this)
			return
		end

		-- on ground checks
		local on_ground=false --this.is_solid(0,1)

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
					--this.init_smoke(h_input*6)
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

						foreach(objects,function(obj)
							if (obj.type == bump) then
								if (obj.objcollide(this,3,0) and not obj.walljumped) then
									score += 1
									obj.walljumped = true
								end
							end
						end)
						

						psfx"2"
						this.jbuffer=0
						this.spd=vector(wall_dir*(-1-maxrun),-2)
						if not this.is_ice(wall_dir*3,0) then
							-- wall jump smoke
							--this.init_smoke(wall_dir*6)
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
		if characters[selected_char].animated then
			this.spr_off+=0.25
			this.spr = not on_ground and (this.is_solid(h_input,0) and this.base_spr+4 or this.base_spr+2) or	-- wall slide or mid air
			btn(⬇️) and 6 or -- crouch
			btn(⬆️) and 7 or -- look up
			this.spd.x~=0 and h_input~=0 and this.base_spr+this.spr_off%4 or this.base_spr -- walk or stand
		end
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
		--set_hair_color(this.djump)
		local haircolor = characters[selected_char].color
		if haircolor != 0 then
			pal(8,haircolor)
			draw_hair(this)
		end
		draw_obj_sprite(this)
		pal()
	end
}

bump={
	init=function(this)
		this.collideable=true
		this.solid_obj=true
		this.walljumped=false
		
		this.layer=1
	end,
	update=function(this)
		local bump_gap = bump_mode
		local rand_offset = 0
		if (bump_mode == 6) then
			bump_gap = 3
			rand_offset = flr(rnd(5))+5
		end

		local bump_threshold = bump_mode == 5 and -8 or -16
		local bump_respawn_offset = bump_mode == 5 and 0 or 8

		if this.x <= bump_threshold then 
			
			this.x = 128+((15%bump_gap)*8) - bump_respawn_offset
			if (bump_gap%2 != 0) then
				this.x += 8*(bump_gap-2)
			end
			this.x += rand_offset
			this.walljumped=false
		end
	end,
	draw=function(this)
		spr(17,this.x,this.y-8)
		spr(this.spr,this.x,this.y)

		local bump_gap = bump_mode-1

		if (bump_mode == 6) then
			bump_gap = 3
		end

		if (this.x > 128+8*(bump_gap-1)) then
			local offset = 8*bump_gap
			if (bump_gap+1 % 2 == 0) then
				offset = 8*(bump_gap+1)
			end
			spr(this.spr,this.x-128-offset,this.y)
			spr(17,this.x-128-offset,this.y-8)
			this.random_bump_gap=flr(rnd(7))+2
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
	pal(8,8)
end

function draw_hair(obj)
	local obj_x = obj.type == player and obj.fake_x or obj.x
	
	local last=vector(obj_x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
	
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		if (obj.type == player) then
			circfill(h.x-obj.fake_x+obj.x,h.y,mid(4-i,1,2),8)
		else
			circfill(h.x,h.y,mid(4-i,1,2),8)
		end
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
	delay_restart=10
	pause_player = true
	just_died = true


	-- update highscore
	last_score = score
	if score > highscores[bump_mode] then
		dset(bump_mode, score)
		highscores[bump_mode] = score
		if score > best_highscore then
			best_highscore = score
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

	function obj.move(ox,oy,start)
		local movamt_x = 0
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

				movamt=obj[axis]-p -- save how many px moved to use later for solids
				if axis == "x" then
					if obj.type == player then
						obj[axis] = p
					end
					movamt_x = movamt
				end
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
				end
				--elseif riding then
				--	riding.move(axis=="x" and movamt or 0, axis=="y" and movamt or 0,1)
				--end
				obj.collideable=true
			end
		end
		return movamt_x
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
	if obj.type == player then
		cam_spdx= cam_gain*(4+obj.x-obj.x_amt-cam_x)
	else
		cam_spdx=cam_gain*(4+obj.x-cam_x)
	end
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
	score = 0

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
		reload()
		-- check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
		end
	end

	-- bumps

	local bump_gap = bump_mode;

	if bump_mode == 6 then
		bump_gap = 4
	end
	
	for bx=0,ceil(15/bump_gap) do
		init_object(bump, bx*8*(bump_gap), 94, 117);
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
  "0,0,2,1,"
}

-- mapdata string table
-- assigned levels will load from here instead of the map
mapdata={}

-- list of music switch triggers
-- assigned levels will start the tracks set here
music_switches={
	[2]=20,
	[3]=30
}

--@end

-- tiles stack
-- assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
1,player
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
__gfx__
00000000000000000000000008888880000000000000000000000000000000000000000000000000022222200000000000000000000000000000000049494949
00000000088888800888888088888888088888800888880000000000088888800222222002222220222222220222222002222200000000000222222022222222
000000008888888888888888888ffff888888888888888800888888088f1ff182222222222222222222666622222222222222220022222202268668200024000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff82226666222266662226866822226666226666220222222222266666200002400
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff82268668222686682026666602268668228668620222666622266666200000240
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800266666002666660001111000266666006666620226666620211112000000024
00000000003333000033330007000070073333000033337008f1ff10003333000011110000111100050000500511110000111150026866800011110000000002
00000000007007000070007000000000000007000000700007733370007007000050050000500050000000000000050000005000055111500050050000000000
00000000000000000000000000000000101111010000000000000000000000000000000005888880000000000000000000000000000000000000000070000000
00000000000000000011110000111100111717110011110000111101058888800288888059888888058888800588880000000000007700000770070007000007
00000000000000000117171001171710111199110117171001717111598888882988888858888ff8598888889888888000000000007770700777000000000000
0000000000700070011199100111991001177710011199100199111158888ff828888ff888f1ff1858888ff8888ff88000000000077777700770000000000000
0000000000700070111777110111771101177710111771101177711088f1ff1888f1ff1808fffff088f1ff1881ff1f8000000000077777700000700000000000
0000000006770677111777110111771101177710111771101177711008fffff008fffff0002ee20008fffff00fffff8000000000077777700000077000000000
00000000567656760117771001177710119559100117771001777110002ee200002ee20007000070072ee200002ee27000000000070777000007077007000070
00000000566656661199599019955990009009001199559900995599007007000070007000000000000007000000700000000000000000007000000000000000
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
0000000000000000010001000000000000000000001111000099990000000000cccccccc00000000000000000000000000000000000000000000000000000000
01000100010001000a000a0001000100001000100111111009aaaa9000000000c77ccccc00000000000000000000000000000000000000000000000000000000
0a000a000a000a000aaaaaa00a000a0000a000a0117117119a9aa9a900000000c77cc7cc00000000000000000000000000000000000000000000000000000000
0aaaaaa00aaaaaa00aa1aa100aaaaaa00aaaaaa0111991119aa99aa900000000cccccccc00000000000000000000000000000000000000000000000000000000
0aa1aa100aa1aa10098a11900aa1aa1001aa1aa0111111119aaaaaa9eeee2000cccccccc00000000000000066666000066000660066000660066666600000000
098a1190098a119000991100098a11900911a890117777119a7777a9eeeee200cc7ccccc00000000000000066666600666006660066606660066666660000000
00991100009911000900009000991100001199000677776006777760eeeeee00ccccc7cc00000000000000060006600660006600666666600660006660000000
00900900009000900000000009000900000900900066660000666600e2e22e00cccccccc00000000000000cccccc00cc000cc000ccccccc00ccccccc00000000
00000000000000000111111000000000000000000000000000000000eeeeee00000000000000000000000cc000cc00cc000cc00cc0c0cc00cccccc0000000000
0111111001111110111b11110111111001111110000000000000000022e22e00000000000000000000000eeeeeee0eeeeeee000ee000ee00ee00000000000000
111b1111111b111111bfff11111b11111111b1110000000000000000eeeeee0000000000000000000000eeeeee000eeeee0000ee000ee00ee000000000000000
11bfff1111bfff111bfdffd111bfff1111fffb110000000000000000e22eee000000000000000000000000000000000000000000000000000000000000000000
1bfdffd11bfdffd111fffff01bfdffd11dffdfb10000000000000000eeeeee005555555500000000000066600066000660066000660066666600000000000000
11fffff011fffff001bbbb0011fffff00fffff110000000000000000eeeeee005555555500000000000066600666006660066606660066666660000000000000
01bbbb0001bbbb000700007007bbbb0000bbbb700000000000000000e7777e005555555500000000000006600660006600666666600660006660000000000000
007007000070007000000000000007000000700000000000000000007777777055555555000000000000cc00cc000cc000ccccccc00ccccccc00000000000000
00000000000000000288888000088880000000007000000700777700500000000000000500000000cc00cc00cc000cc00cc0c0cc00cccccc0000000000000000
028888800288888028f888880288888808888200700c000707000070550000000000005500000000eeeeee0eeeeeee000ee000ee00ee00000000000000000000
28f8888828f8888828ff888828ff88888888f8207000000770770007555000000000055500000000eeee000eeeee0000ee000ee00ee000000000000000000000
28ffff8828ffff888ff1ff1828fffff888fff8207000cc077077bb07555500000000555500000000000000000000000000000000000000000000000000000000
8ff1ff188ff1ff1808fffff08ff1ff1081ff1f807000cc07700bbb075555555555555555000000000000000660006600eeeee00cc000cc0666000eeeee000000
08fffff008fffff000dddd0008fffff00ffff80070c00007700bbb07555555555555555500000000000000066606660eeeeeee0ccc00cc066660eeeeeee00000
00dddd0000dddd000700007007dddd0000dddd707000000707000070555555555555555500000000000000066666660ee000ee0cccc0cc006600ee000ee00000
00700700007000700000000000000700000070000777777000777700555555555555555500000000000000066666660eeeeeee0ccccccc006600eeeeeee00000
000000000000000008874440000000000000000007777770004bbb00004b000000400bbb00000000000000066060660ee000ee0cc0cccc006600ee000ee00000
088744400887444087884444088744400444788070007777004bbbbb004bb000004bbbbb00000000000000066000660ee000ee0cc00ccc066600ee000ee00000
878844448788444448111114878844444444887070c7770704200bbb042bbbbb042bbb0000000000000000066000660ee000ee0cc000cc066660ee000ee00000
481111144811111444f11f14481111144111148070777c07040000000400bbb00400000000000000000000000000000000000000000000000000000000000000
44f11f1444f11f1404ff77f044f11f1441f11f407777000704000000040000000400000000000000000000000000000000000000000000000000000000000000
04ff77f004ff77f000cccc0004ff77f00f77ff4077700c0742000000420000004200000000000000000000000000000000000000000000000000000000000000
00cccc0000cccc000700007007cccc0000cccc707000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
00700700007000700000000000000700000070000777777040000000400000004000000000000000000000000000000000000000000000000000000000000000
04444440044444400444444004444440044444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888888888888888ffff888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888ffff8888ffff888f1ff18888ffff88ffff8800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88f1ff1888f1ff1808fffff088f1ff1881ff1f800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08fffff008fffff00033330008fffff00fffff800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333300003333000700007007333300003333700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007000700000000000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880088888800888888008888880088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888ffff8888ffff8888ffff8888ffff88ffff8880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88f1ff1888f1ff1888f1ff1888f1ff1881ff1f880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08fffff008fffff008fffff008fffff00fffff800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04c4cc0004c4cc0004c4cc0004c4cc0000cc4c400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d4222200d4222200d4222200d72222000022227d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007000700700007000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000a22222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a2222200a222220922222220a22222002222a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9222222292222222222ffff292222222222222900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222ffff2222ffff222f1ff12222ffff22ffff2200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22f1ff1222f1ff1202fffff022f1ff1221ff1f200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02fffff002fffff000dddd0002fffff00fffff200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd000700007007dddd0000dddd700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007000700000000000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
55505550550055005050000055505050055055500550055055000000000000000000555005505500000055505050000005500550555055505500555050500550
55505050505050505050000005005050505050505000505050500000000000000000555050505050000050505050000050005050555005005050050050505050
50505550505050505550000005005550505055005550505050500000000000000000505050505050000055005550000050005050505005005050050005005050
50505050505050500050000005005050505050500057505050500000000000000000505050505050000050500050000050005050505005005050050050505050
50505050555055505550000005075050550050505500550050500000000000000000505055005550000055505550000005505500505055505050555050505500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55000550555050000000555055505550555050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050500050000000505050005050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050550050000000550055005500550055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050500050000000505050005050505000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505500555055500000555055505050505055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066666000066000660066000660066666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066666600666006660066606660066666660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000060006600660006600666666600660006660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccccc00cc000cc000ccccccc00ccccccc00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000cc000cc00cc000cc00cc0c0cc00cccccc0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000eeeeeee0eeeeeee000ee000ee00ee00000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000eeeeee000eeeee0000ee000ee00ee000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000066600066000660066000660066666600000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000066600666006660066606660066666660000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000006600660006600666666600660006660000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000cc00cc000cc000ccccccc00ccccccc00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000cc00cc00cc000cc00cc0c0cc00cccccc0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000eeeeee0eeeeeee000ee000ee00ee00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000eeee000eeeee0000ee000ee00ee000000000000000000000000000000000000000000000000000000000
00000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000660006600eeeee00cc000cc0666000eee7e000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066606660eeeeeee0ccc00cc066660eeeeeee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066666660ee000ee0cccc0cc006600ee000ee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066666660eeeeeee0ccccccc006600eeeeeee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066060660ee000ee0cc0cccc006600ee000ee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066000660ee000ee0cc00ccc066600ee000ee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000066000660ee000ee0cc000cc066660ee000ee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000060000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000070000
00000000000000000000000000000000000060000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000600000000000000000000006000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777007707700777000000000007000003330000030303330330033300000700000007770777007707770000000007770777000000000000000000000
07000000777070707070700007000000070000000030000030300300303030000000070000007070700070000700070000000070007000000000000000000000
00700000707070707070770000000000700000003330333030300300303033000000007000007700770077700700000000000770777000000000000000060000
07000000707070707070700007000000070000003000000033300300303030000000070000007070700000700700070000000070700000000000000000000000
70000000707077007770777000000000007000003330000033303330333033300000700000007770777077000700000000007770777000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05505050555055505550055055505550555000000000005000000330333033300330300033303300333000005000000000000000000000000000000000000000
50005050505050505050500005005000505005000000050000003000303030303030300003003030300000000500000000000000000000000000000000000000
50005550555055005550500005005500550000000000500000003000333033003030300003003030330000000050000000000000000000000000000000000000
50005050505050505050500005005000505005000000050000003000303030303030300003003030300000000500000000000000000000000000000000000000
05505050505050505050055005005550505000000000005000000330303030303300333033303030333000005000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111b111100b0b0bb00b0000bb00bb0b0b0bbb0bb0000000000000000600000000000000000000000000000000000000000000000000000000000000000000000
11bfff1100b0b0b0b0b000b0b0b000b0b0b000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1bfdffd100b0b0b0b0b000b0b0b000bb00bb00b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11f6fff000b0b0b0b0b000b0b0b000b0b0b000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
016b6b00000bb0b0b0bbb0bb000bb0b0b0bb60bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00760700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05505550555000005550000005500550055055505550000005505550000055505550000005505550000055500550555055500000000000000000000000000000
50005000050000005050000050005000505050505000000050505000000000505050000050505050000055505050505050000000000000000000000000000000
50005500050000005550000055505000505055005500000050505500000005505050000050505500000050505050550055000000000000000000000000000000
50505000050000005050000000505000505050505000000050505000000000505050000050505050000050505050505050000000000000000000000000000000
55505550050000005050000055000550550050505550000055005000000055505550000055005050000050505500505055500000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000800020000000000000000000000000000000303030303030304040402020000000303030303030303040404020202020200000000000000020300000000000000000000000000000204000000000000000000000000000000000000000000000000000000001300000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002700002c000000000000000000000000002c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003700003c000000003f0000203d000000003c0000000000212300003d3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222525222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3232254825252525253232322525323232323232323225322525252548323232000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000031322525482526000000313328000021233e002830003132252526002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002831323232332000003a2829000f313327003837000000313233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3900002a283828390000000028290000000000370028390000002a280000003a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2800000000000028390000003800000000000000002a28390000003800003a38000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
383900000000002a290000002a2900000000000000002a2900000028003a2828000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002a382900000000000000000000000000000000000000000000002a28282900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000003a390000000000000000002a390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003a39000000000000003a38290000003a390000000000280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000003a28382828283900003a38290000003a38290000000000383900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000000000000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f60000000
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
010d0000280752f07533075280652f06533065280552f05533055280452f04533045280352f03533035280252f02533025280152f01533015242052b20530205242052b205302053a2052e205002050020500205
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
00100000285752854528535285252851528515285152851520575205552054520535205252052520515205152357523555235452354525535255352552525525235152351523575235551c5451c5351c5251c515
00100000205752057520575205752057520575205752057519555195351957519555195451953519525195251c5751c5751c5751c575235152351523575235551c5451c5451c5351c5351c5251c5251c5151c515
00100020100601003010050100301005010030100100c000140601403014050140301405014030140100f0000d0600d0300d0500d0300d0101100000000000001006010030100501003010050100301005010030
0010000014575145751457514575145750500000000000000d0600d0300d0500d0300d01000000000000f0000f0000f0000000010060100301005010030100501003010050100301005010030100100c00010000
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

