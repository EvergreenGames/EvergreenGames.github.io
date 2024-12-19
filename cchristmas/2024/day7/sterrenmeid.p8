pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- sterrenmeid 1.0
-- celeste mod by faith

-- [initialization]
-- evercore v2.3.1

-- easter egg

-- big thanks to
-- JUNO VELKAROT FOR THE TILE ART
-- NIKO HXGONIC FOR THE MUSIC (https://hxgonic.carrd.co)
-- PETTHEPETRA FOR TEACHING ME LUA AND MAKING EVERCORE
-- SNOO23 FOR SHORTCUT
-- ANTIBRAIN FOR ANTIMATTER ANOMOLY
-- DEHOISTED FOR ASTRAL ABYSS
-- HXGONIC FOR CELESTIAL CAVES
-- THERAT69 FOR RATHOLE

--smaller thanks to
-- LORD SNEK FOR TESTING
-- BACON_GOOD FOR "TESTING"
-- SNOO23 FOR COMPLAINING ABOUT DASHLESS LEVELS
-- MADDY THORSON FOR MAKING ME TRANSGENDER

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
	music(32,0,7)
	lvl_id=0
end

function begin_game()
	max_djump=0
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,1,1
	music(4,0,7)
	load_level(1)
	music_changed=false
end



function is_title()
	return lvl_id==0
end

-- [effects]

clouds={}
for i=0,32 do
	add(clouds,{
		x=rnd"128",
		y=rnd"128",
		spd=0.3+rnd"0.5",
	w=0.5})
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


function grav_func()
    grav_check=lvl_id~=10
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

	grav_func()

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
			music(12,0,7)
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
			sfx"46"
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
		sspr(unpack(split"72,32,127,32,36,32"))
		?"🅾️/❎",55,80,5
		?"maddy thorson",40,96,5
		?"noel berry",46,102,5
		?"faith sterrenmaid",34,108,5

		-- particles


		return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)
	

		-- bg clouds effect
	foreach(clouds,function(c)
		c.x+=c.spd-cam_spdx
		rectfill(c.x,c.y,c.x+c.w,c.y+0-c.w*1,cloud_col)
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
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30)..":"..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,7
end

function draw_ui()
	rectfill(24,58,104,70,0)
	local title=lvl_title or lvl_id.."00 m"
	?title,64-#title*2,62,7
	draw_time(4,4)

function draw_berry()
		if check_adelie==true then
			rectfill(44,6,55,7,0)
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
		create_hair(this)
		
		this.layer=1
	end,
	update=function(this)
		if pause_player then
			return
		end

		-- horizontal input
		local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0

		-- spike collision
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) then
			kill_player(this)
		end



	if lvl_id==20 and this.y>275 and music_changed==false then
		music(2,1,7)
		music_changed=true
	end


-- bottom death (rip bottoms)
		if this.y>lvl_ph then
			if lvl_id==1 then
				load_level(3)
			elseif lvl_id==20 then
				load_level(21)
			else
				kill_player(this)
			end
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
				psfx"48"
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
if not on_ground and grav_check==true then
	this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.105 and 0.21 or 0.1005)
elseif not on_ground and grav_check==false then
	this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.15 and 0.11 or 0.105)
end




			-- jump
			if this.jbuffer>0 then
				if this.grace>0 then
					-- normal jump
					psfx"31"
					this.jbuffer=0
					this.grace=0
					this.spd.y=-2
					this.init_smoke(0,4)
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
					if wall_dir~=0 then
						psfx"32"
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
				psfx"33"
				freeze=2
				-- dash target speeds and accels
				this.dash_target_x=2*sign(this.spd.x)
				this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
				this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
				this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
			elseif this.djump<=0 and dash then
				-- failed dash smoke
				psfx"39"
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
		if this.y<-4 then
			if lvl_id==1 then
				load_level(2)
			elseif lvl_id==2 then
				load_level(4)
			else
				next_level()
			end
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
	pal(14,djump==1 and 14 or djump==2 and 7+frames\3%2*4 or lvl_id==3 and 1 or lvl_id==9 and 1 or lvl_id==10 and 1 or lvl_id==11 and 1 or lvl_id==12 and 1 or lvl_id==13  and 1 or lvl_id==14 and 1 or lvl_id==15 and 1 or lvl_id==16 and 1 or lvl_id==17 and 1 or lvl_id==18 and 1 or lvl_id==19 and 1 or lvl_id==20 and 1 or lvl_id==21 and 1 or 0)
end

function draw_hair(obj)
	local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x,h.y,mid(4-i,1,2),14)
		last=h
	end
end

function kill_player(obj)
	sfx_timer=12
	sfx"30"
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
		sfx"34"
		this.spr=3
		this.target=this.y
		this.y=min(this.y+48,lvl_ph)
		cam_x,cam_y=mid(this.x+4,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
		this.spd.y=-4
		this.state=0
		this.delay=0
		create_hair(this)
		this.djump=max_djump
		if lvl_id~=3 and lvl_id~=1 and lvl_id~=2 then
			max_djump=1
		end
		
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
					sfx"35"
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

flippot={
	check_pot=true,
	init=function(this)
		this.start=this.y
		this.off=0
	end,
	update=function(this)
		check_pot(this)
		this.off+=0.025
		this.y=this.start+sin(this.off)*1.1
	end
}

function check_pot(this)
	local hit=this.player_here()
	if hit then
		sfx_timer=20
		sfx"30"
		max_djump=0
		hit.djump=0
		destroy_object(this)
		if peek(0x5f2c)==0 then
			poke(0x5f2c, 129)
		elseif peek(0x5f2c)==129 then
			kill_player(hit)
		end
	end
end

flipcure={
	check_cure=true,
	init=function(this)
		this.start=this.y
		this.off=0
	end,
	update=function(this)
		check_cure(this)
		this.off+=0.025
		this.y=this.start+sin(this.off)*1.1
	end
}



function check_cure(this)
	local hit=this.player_here()
	if hit then
		sfx_timer=20
		sfx"40"

		destroy_object(this)
		if peek(0x5f2c)==129 then
			poke(0x5f2c, 0)
			max_djump=1
			hit.djump=1
		elseif peek(0x5f2c)==0 then
			kill_player(hit)
		end
	end
end


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
			psfx"38"
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
				psfx"37"
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
		psfx"42"
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
            local target_djump=max_djump==0 and 1 or max_djump
            if hit and hit.djump<target_djump then
                psfx"36"
                this.init_smoke()
                this.spr=0
                this.timer=60
                hit.djump=target_djump
            end
        elseif this.timer>0 then
            this.timer-=1
        else
            psfx"37"
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


balloon2={
    init=function(this)
        this.offset=rnd()
        this.start=this.y
        this.timer=0
        this.hitbox=rectangle(-1,-1,10,10)
    end,
    update=function(this)
        if this.spr==21 then
            this.offset+=0.01
            this.y=this.start+sin(this.offset)*2
            local hit=this.player_here()
            local target_djump=max_djump==0 and 1 or max_djump
            if hit and hit.djump<target_djump then
                psfx"36"
                this.init_smoke()
                this.spr=0
                this.timer=5
                hit.djump=target_djump
            end
        elseif this.timer>0 then
            this.timer-=1
        else
            psfx"37"
            this.init_smoke()
            this.spr=21
        end
    end,
    draw=function(this)
        if this.spr==21 then
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


gem={
	check_gem=true,
	init=function(this)
		this.start=this.y
		this.off=0
	end,
	update=function(this)
		check_gem(this)
		this.off+=0.025
		this.y=this.start+sin(this.off)*1.1
	end
}

function check_gem(this)
	local hit=this.player_here()
	if hit then
		sfx_timer=20
		sfx"45"

		destroy_object(this)
		if max_djump==0 then
			max_djump=1
			hit.djump=1
		elseif max_djump~=0 then
			max_djump=1
		end
	end
end

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
					sfx"41"
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
		local target_djump=max_djump==0 and 1 or max_djump
            if hit then
				sfx_timer=20
				sfx"40"
				got_fruit[this.fruit_id]=true
				init_object(lifeup,this.x,this.y)
				destroy_object(this)
				hit.djump=target_djump
				if __key_id then
					got_fruit[__key_id]=true
					__key_id=nil
				end
			end
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
		?fruit_count,this.x-7.5,this.y-4,7+this.flash%2
		?"000",this.x-4,this.y-4,7+this.flash%2

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

fake_wall2={
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
		sspr(56,48,8,16,this.x,this.y)
		sspr(56,48,8,16,this.x+8,this.y,8,16,true,true)
	end
}

function init_fruit(this,ox,oy)
	sfx_timer=20
	sfx"43"
	init_object(fruit,this.x+ox,this.y+oy,26).fruit_id=this.fruit_id
	destroy_object(this)
end

key={
	check_fruit=true,
	update=function(this)
		this.spr=flr(9.5+sin(frames/30))
		if frames==18 then --if spr==10 and previous spr~=10
			this.flip.x=not this.flip.x
		end
		if this.player_here() then
			sfx"44"
			sfx_timer=10
			destroy_object(this)
			has_key=true
			__key_id=this.fruit_id
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
		if lvl_id==1 then
			this.text="-- adelie skip is real --#are you worthy?"
		elseif lvl_id==2 then
			this.text="adelie skip will be updated#in the dlc for $20! sorry"
		else
			this.text=" !!DANGER!! DEATH BELOW! # TAKE THIS FOR YOUR SAFETY"
		end
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
				this.state=1
				this.init_smoke()
				this.init_smoke(8)
				this.timer=10
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
				init_object(orb,this.x+4,this.y-60,114)
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
			sfx"47"
			freeze=10
			destroy_object(this)
			max_djump+=1
			hit.djump+=1
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
			sfx"49"
			sfx_timer,this.show,time_ticking=30,true,false
		end
	end,
	draw=function(this)
		spr(97+frames/5%3,this.x,this.y)
		if this.show then
			camera()
			rectfill(32,2,96,31,0)
			spr(26,55,6)
			?two_digit_str(fruit_count),64,9,7
			print("/08",72,9,7)
			draw_time(43,16)
			?"deaths:"..two_digit_str(deaths),48,24,7
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
		return oy<0 and not obj.is_flag(ox,0,3) and obj.is_flag(ox,oy,3) or -- jumpthrough or
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

	if peek(0x5f2c)==129 then
		poke(0x5f2c, 0)
	end

	load_level(next_lvl)
end

function load_level(id)
	has_dashed,has_key= false
	_key_id=nil

	--remove existing objects
	foreach(objects,destroy_object)

	--reset camera speed
	cam_spdx,cam_spdy=0,0

	local diff_level=lvl_id~=id

	--set level index
	lvl_id=id

	--set level globals
	local tbl=split(levels[lvl_id])
	for i=1,6 do
		_ENV[split"lvl_x,lvl_y,lvl_w,lvl_h,bg_col,cloud_col"[i]]=tbl[i]*16
	end
	lvl_title=tbl[7]
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8
	--level title setup
	ui_timer=5

	--reload map
	if diff_level then
		reload()
		--check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,bg_col,cloud_col,mapdata[lvl_id])
		end
	end

	if peek(0x5f2c)==129 then
		poke(0x5f2c, 0)
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
--"x,y,w,h,bg_col/16,cloud_col/16,title"
levels={
  "0,0,2,1,0.0625,0.4375,crash land",
  "2,0,1,1,0.0625,0.4375,shortcut",
  "6,0,2,2,0,0.437,so close!",
  "3,0,1,1,0.0625,0.0625,lab..?",
  "4,0,1,1,0.0625,0.0625,lab 2",
  "5,0,1,1,0.0625,0.0625,lab 3",
  "0,1,1,1,0.0625,0.0625,cloning facility",
  "1,1,1,1,0.0625,0.0625,clone 2",
     "2,1,2,1,0,0.437,lab exit",
     "4,1,1,1,0,0.437,low gravity zone",
     "0,2,1,1,0,0.437,solar storm",
     "1,2,1,1,0,0.437,antimatter anomaly",
     "2,2,1,1,0,0.437,cosmic cradle",
     "3,2,1,1,0,0.437,astral abyss",
     "4,2,1,1,0,0.337,celestial caves",
     "0,3,1,1,0,0.337,starfall straits",
     "1,3,2,1,0,0.337,black hole basin",
     "3,3,1,1,0,0.337,pulsar peaks",
     "6,2,2,2,0,0.337,rathole",
     "5,1,1,3,0,0.337,core",
     "4,3,1,1,0,0.337,easter egg"
}


--mapdata string table
--assigned levels will load from here instead of the map
mapdata={}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
	[11]=12,
	[16]=20
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
22,balloon
21,balloon2
23,fall_floor
26,fruit
120,adelieberry
41,flippot
45,fly_fruit
57,flipcure
114,gem
64,fake_wall
103,fake_wall2
113,message
96,big_chest
97,flag
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
0000000000000000000000000eeeeee00000000000000000000000000000000000aaaaa0000aaa000000a0000c6066d055d5d0d000000000cccccc6666cccccc
000000000eeeeee00eeeeee0eeceeeee0eeeeee00eeeee00000000000eceeee000a000a0000a0a000000a000c656dddddd55dd5d00000000cccccc6666cccccc
00000000eeceeeeeeeceeeeeeceefffeeeceeeeeeeeeece00eeeeee0ece1ff1e00a909a0000a0a000000a000d5dd5dddd6d5dd6c00000000cdccdc6666ccdcdc
00000000eceefffeeceefffeeee1ff1eeceefffeefffeec0eeceeeeeeeeffffe009aaa900009a9000000a0000ddd0055dd660dc000000000dddcdc6666dcdcdc
00000000eee1ff1eeee1ff1e0efffff0eee1ff1ee1ff1ee0eceefffeeefffffe0000a0000000a0000000a000000000000000000000000000dddddc6666dddcdd
000000000efffff00efffff0005775000efffff00fffffe0eeeffffe0e7ff7e00099a0000009a0000000a00000000000000000007d7d7d7ddddddd6666dddddd
0000000000577500005775000700007007577500005775700ef1ff10005775000009a0000000a0000000a000000000000000000056565656dddddd6666dddddd
000000000070070000700070000000000000070000007000077575700070070000aaa0000009a0000000a000000000000000000000000000dddddd6666dddddd
cccccccc00000000000000000000000000000000008ee80000eeee0049999994499999944999099400bb000066656665cccccccc000000000000000070000000
cccccccc0000000000000000000d00000000000008e7ee800eeeeee0911111199111411991140919000bbb0067656765cccccccc077777700770070007000007
cdccdcdc000000000000000000065050066666600e7eeee00e7eeee0911111199111911949400419008b800067706770cdccdcdc777777770777000000000000
dddcdcdc007000700d6666d000060505655333360eeeeee00eeeeee09111111994940419000000440888800007000700dddcdcdc777777770770000000000000
dddddcdd007000700050050000060505653333360eeeeee00eeeeee09111111991140949940000000988880007000700dddddcdd077777770000700000000000
dddddddd0677067700055000000650506666666608eeee800eeeeee09111111991119119914004990889800000000000dddddddd077777770000077000000000
dddddddd5676567600500500000d000065300336008ee80000eeee00911111199114111991404119008880000000000066666666077007700007077007000070
dddddddd566656660005500000000000653333360000000000000000499999944999999444004994000000000000000066666666000000007000000000000000
56666665566666666666666666666665655ddddddddddddddd55dd6656666665dddddddd00000000000000005500000007777770000000000000000000000000
66656666666666666666556666556666665dddddddddddddd6d5d66666666566ddddd55d00444400000000006670000077777777000777770000000000000000
66d6dd66655dddddddd6d5ddd6d5dd66666dddd5dddddddddd66d666666dd666dddd6d5d00777700000000006777700077777777007766700000000000000000
66dddd666d5ddddddddd66dddd66dd6666ddddd6dddddddddddddd66666ddd665dddd66d00700700066666606660000077773377076777000000000000000000
66ddd556666dddddd55ddddddddddd6666dddddddddddddddddd556666dddd666ddddddd07788770055555505500000077773377077660000777770000000000
66dd6d5666ddd55d6d5ddddddddd556666ddd55dddddddddddd6d56665dd5566dddddddd07828870005656006670000073773337077770000777767007700000
6666666666dd6d5dd66ddddd5dd6d56666dd6d5ddddddddd5ddd666666d6d566ddd5dddd0788827000565600677770007333bb37070000000700007707777770
5666666566ddd66ddddddddd6ddd666666ddd66ddddddddd6ddddd6666ddd666ddd6dddd007777000dddddd0666000000333bb30000000000000000000077777
66d5dd6666dddd55dddddd55dd5ddd6656666666666666666666666566ddd556ddd55ddd00000000000000000000066603333330566666666666666666666665
66d6dd6666ddd6d5ddddd6d5dd6ddd6666656655665666666656666666dd6d56dd6d5ddd07700770000000000007777603b33330666666666666666666666666
66dddd6665dddd66dd55dd66dddddd6666d6d6d5dd6ddddddd6dd66666ddd666ddd66ddd007bb70000777000000007660333333066cccccccccccccccccccc66
66dddd6666ddddddd6d5dddddddd556666dddd66dddddddddddddd6666dddd66dddddddd007bb70000007000000000550333b33066cccccccccccccccccccc66
66dd556666ddd5dddd66ddddddd6d5666655ddddddddd55dddd55d66665ddd66d555dd550073b70000077000000006660033330066cccccccccccccccccccc66
66d6d566666dd6dd6ddddd666ddd666666d5dddddddd6d5dd66d5d66666ddd666555d6d507bbbb7000000000000777760004400066cccccccccccccccccccc66
65dd6666666666666666656666666666666666565666666666666666666656666d55dd667bbb3bb700070000000007660004400066cccccccccccccccccccc66
66dddd6656666666666666666666666556666666666666666666666556666665d666dddd7777777700000000000000550099990066cccccccccccccccccccc66
5666655657d7d7d7d7d7d7d7d7d7d7d557d7d7d557d7d7d7d7d7d7d7d7d7d7d557d7d7d500000000000000000000000010000001100000000000000000000000
666666667d6d6d6d6d6d6d6d6d6d6d6d7d6d6d6d7d6d6d6d6d6d6d6d6d6d6d6d7d6d6d6d00000070000000000000001100000000011000000000700000000000
66665566d655555555555555555555d6d65555d6d655555555555555555555d6d65555d607000777000000000000110000000000000110000007770000000000
666d555d7d565555555655555555556d7d56556d7d565555555555555555656d7d56556d707000700000000000cc00000000000000000cc00000700000070000
66ddddddd655555555565555555565d6d65565d6d655555555555555555555d6d65555d607000000000000000c000000000000000000000c0000000007777700
56d66ddd7d555555555555555555556d7d55556d7d555555555555555555556d7d55556d0000000000000000c00000000000000000000000c000000000070000
5665d6ddd6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d655555555555555555555d6d65555d6000000070000000c0000000000000000000000000c00000700000000
66655ddd5d6d6d6d6d6d6d6d6d6d6d655d6d6d657d555555555555555555556d7d55556d00000070700000c000000000000000000000000000c0007070000000
666d6ddd55555555d6555555555555d655555555d655555555555555555555d6d65555d600000007000000000000000000000000000000000000000700000000
566d5ddd565555656d5555555555556d555555557d555555555555555555556d7d55556d00666660066666600666666006666660066666600666666006600066
56dddddd55555555d6555555555555d655555555d655555555555555555555d6d65555d606666666066666660666666606666666066666660666666606660066
66ddddd6555555556d5555555555556d555555557d555555555555555555556d7d55556d06600000000660000660000006600066066000660660000006666066
666dddd555555555d6555555555555d655555555d656555555555555555565d6d65555d60ddddddd000dd0000dddd0000dddddd00dddddd00dddd0000ddddddd
6666dd66555555556d5555555555556d555555557d555555555555555555556d7d55556d0000000d000dd0000dd000000dd000dd0dd000dd0dd000000dd0dddd
6666666656555565d6555555555555d655555555d6d6d6d6d6d6d6d6d6d6d6d6d65555d60ddddddd000dd0000dddddd00dd000dd0dd000dd0dddddd00dd00ddd
56666566555555556d5555555555556d555555555d6d6d6d6d6d6d6d6d6d6d657d55556d00ddddd0000dd0000ddddddd0dd000dd0dd000dd0ddddddd0dd000dd
00000000004bbb00004b000000400bbb0000000000000000003003006d6d655dd65555d600000000000000000000000000000000000000000000000000000000
00aaaaaa004bbbbb004bb000004bbbbb000000000000000000bbbb0056d6d6d67d55556d00700000000000066000660666666006660066666600000000007000
0a99999904200bbb042bbbbb042bbb0000000008000000000bb7b7b06d655d6dd65555d607770000000000066606660666666606666066666660000000007000
a99aaaaa040000000400bbb00400000000010008800000000bbb99b0d6d555557d55556d0070000000000c06666666066000000066006600066c000000777770
a9aaaaaa0400000004000000040000000015077888000000bbb777bb6d565555d65565d60000000000000c0ddddddd0dddd00000dd00dd000ddc000000007000
a99999994200000042000000420000000155776622800000bbb777bb56d555557d55556d00000700000000cdd0d0dd0dd0000000dd00dd000dd0000000007000
a99999994000000040000000400000000007d676622200000bb777b05d655555d6d6d6d600007070000000cdd000dd0dddddd00ddd00ddddddd0000007000000
a9999999400000004000000040000000007ddd6766220000bb992990d6d555555d6d6d65000007000000000dd000dd0ddddddd0dddd0dddddd00000070700000
aaaaaaaa044444400077770000000c1c0077ddd677622000d7d7d7d76d6d5555099119900000000000000000c000000000000000000000001000700007000000
a49494a14444444407000070066601c188877ddd777620006d6d6d6d56d555559c1717c900000000000000700100000000000000000000010000700000000000
a494a4a1454555457077000706659c1c088876d666776d005556d5555d655555011199100000000000000777001d00000000000000000dd00007770000000000
a49444aa444444447077ee07065995000088866667677680555d6565d65655550111111000000000007000700000dd00000000000007d0000000700000000000
a49999aa45545455000eee070099566000088266667677825656d5556d5555550111111000000000077700000000007700000000077000000000700000000700
a494449904444440700eee071c1566600000882666677822555d6555d6d555560177771000000000777770000000000077700000700000000000000000007770
a494a4440002200007000070c1c066600000002266668222d6d6d6d66d6d6d6d0c7777c000000000077700000000000000000000000000000000000000000700
a494999900022000007777001c10000000000000d66222226d6d6d6d56d6d5d60066660000000000007000000000000000000000000000000000000000000000
0000000042232323232323232323232300000042528252838252528382525282b1b1b1b1b1b1b1b1b1b1b1b10000000082232323331323232333426200000000
000000000000000000000000000000005233b200000000000000000000b342522323235353532323232323232323232323330000132323232323232323232352
0000000003b200000000000000000000000000132323232323232323232383520000000000000000000000000000000062000000000000122222526200930000
0000000000000000000000000000000062b20000000000000000000000b342230000000000000000000000000000000000000000000000000000000000000042
1100000073b20000000000000000000000000000b1b1b10000000000000042831100000011000000000000000000433233000000000000425282526200000000
0000000000000000000000000000000062b20000110000000000000000b373120000000000000000000000000000000000000000000000000000000000000042
32000000000000000000000000000000000000000000000080000000000013237200000072000000000000000000007332000000100000132323836200000011
0000000000000000000000000000000062b200b302b200000000000000b312520000000000000000000000000000000000000000000000009300000000000042
330000000000000000000000000000000021000011111100000011110000b1b10300000003000000000000000000000062001222222263721232133300000012
b312223200000000000000000000000062b20000b10000001100000000b34283000000000000000000000000000000000000000000000000a200000000000042
b1000000000000001100000000000000223243222222222222222232000000000300000003000000000000000000000062921323233312624262b20000000042
b313233300000093000000000000000062110000000000b302b2000000b313520000000000000000000000000000000000001222222222222222223200000042
00000000000061b372b2006100000012525232132382522323238333000061007300000073000000000000000000000062000000000013334262b20000000042
00b1b1b10000000000000000000000005232b20000000000b10000000000b3420000000000000000000000000000000002125223232323232323233300000042
a1000000000000b303b2000000000042832352223242620000007372000000000000000000000000000000000000000062000000000000001333b20000610042
000000000000000000000000000000115262b20000110000000011000000b3420000000000000000000000122222225312526200000000000000000000000042
11111111111111110311111100000042330213232313330000001262000011110000000000000000000000000000000033000000000000000000000000000042
11111100000000000000b372000000725262b200b302b20000b302b20000b3420000000000000000122232132323337213233300000000000000000000000042
53225353535353535253536300000013000000000012320000001333000012220061000000000000000000000000000032000000000093000000000000111142
12536300000000000000b373000000735233b20000b100000000b1000000b342000000122222223242525232435353330000b100000002000000000000020042
10030000000000b303b200000000000000000000001333000000b1b1000042830000000000000000000000000000000033111111110000000000000000123242
030000000000111111000000000000b162b2000000000000000000000000b3423204004252525262132323330000000000000000110000000000020000000042
71030000006100b373b20061000000000000000000b1b10000001111000042520011000000110000000000000000000022223212321111000092000000426242
03000000000012223200000000000000621100000000001100000000000011426200004223232333000000000000000043222222321111111111000000000042
00730000000000000000000000000000000000000011110000001232000042820072000000720000000000000000100052826213331232000021000000426213
730000001111425262000000006100005232b2000000b302b200001100b3125283223273b1b1b1b1000000000000000072132323331222226372111111111142
00000000000000000000000000000000001041000012320021004262000042820003000000030000000000000043536383523312324262111172111111425222
109200001232425262111111000000005262b200000000b10000b302b2b313235252620000000000000000000012324352630000001323331252222222222252
00000000000000000000000000000000222232000042620071004262000042520003000000030000000000000000000052331252624262122252222232425252
222222225262425252222232000000005262b20000000000000000b100b3125352836200006100000000b3123242523273000000000000001323232323232352
00000000000000000000000000000000528262000042620000004262000013230003000000030000000000000000000033432323334262425282525262425252
525252525262425252525262000000005262b20000000000000000000011122283523300000000000000b31333132333b1000000000000009200000000000042
2333435323232323232333000000b342132323232323238283232323522323235223232352232323232323620000425200001323232323232323232323330000
000000000000000000000000000000005233b200000000000000000000724252823312f300000011110000000000000000000000111100001232000000000042
2253630000000000000000000000b313000000000000b34262000000030000000300000003000000000400030000425200000000110000000000000000000000
000000000000000000000000000000006212321111000000000000001103132362721301e3e3e3e3f30000000000000000000000d3f300001362000000000042
6202000000000000000000009300b312000000000000b342620000007300000073000000030000000000000300004282000000b3020000000000000000000000
000000006666666666666666000000003313535363111100001111114323232362737213c1c1c1c101f3d3e3f3001111110000d30101e3e33203000011000042
620000000000000000000000a200b342100000000000b34262000000b1000000b1000000030000000012223300004252c0110000b100c0000011000000c00000
0000000066666666666666660000000012223212632232000012223243532222522233122222223242e0f00101e3e3f3d3e3e3012323c1c13373122232b20042
33000000435353535353535353222282222232020000b342620000006100000000000000030000000042330000004282b302b200000000000002b20000000000
0000666666665757666657576666000042523303126262000042133312321362232343235252523342621352520101e0f0010133122222320212525262b20013
00000000000000000000000000138382232323630000b31333000000110000001100000003000000000300000000425200b100000011000000b1000000000000
00006666666657576666575766660000426212621333620000424363428232730000000013233343525263132323233313233312525282523213528262000012
00006100000000000000000000004252000000000000b31232000000720000007200000073000000000300000000428300000000b30200000000000011000000
000066666666666606000600666600004233423300007300007300001323236300000000b1b1b1b113330212222222222222321352835252526242526200b342
00000000000011000000000000001352000000000000b3426200000003000000030000000000000000030000000042520000000000b10000001100b302b20000
00006666666666660000000066660000731262000000000000000000001232020000000000000000b1b1b142528352825252523242525282826242526200b342
11110000000002000000000000000042111100000000b3133300000003b1b1b10300000000000000007300000000425200001100000000000002b200b1000000
66666666666657575757575766666666125262000000000000000000004252321000000000110000000000135252525282525262132323525262132333000042
5332b2000000b10000000000000000422232b200000000000000000003000000730000001100000000b100000000425200b302b20000000000b1000000000000
66666666666657575757575766666666132333000000000000000000001323332222222222321111110000001352828252232333b1b1b1132323630000000042
d20311111111111111210000000000425262b200000000000000000073000000b10000007200000000000000000042830000b100000000000000000000000000
66666666666657575757575766666666122232000000000000000000007202728252835252331222320000000013232333b1b1b100000000b1b1b10000002142
532353535353535353535353630000425262b2000000000000000000b100000000000000030000000000000000004283b00000000000b0000000001100b00000
66666666666657575757575766666666135262320000000000000000126212625252522333125252523200000000000000000000000000000000610012222252
00000000000000000000000000000042236200000000001111000000000000000000000003000000001100000000425200001000000000110000b302b2000000
00006666666657575757575766660000321333133216000000000012526242625283331222525283525232000000000000000011112100001111111142525252
536311110000000000000000000000423203000000000012320000000000000011000000030000000072000000004252000212226300b302b20000b100000000
00006666666657575710575766660000422263721363000000000213233342335233125283525252825262111111000000111112223271711222324352525252
10920000122222321222631222222252627300000000004262000000110000000300000003000000000300000000428300125233720000b10000000000000000
66666666060006005555060006000000133343235363720000122222226373723312825252835252528252222222223212222252526200004252523213232352
53535353232323331333432323232323523200000000004262000000720000000300000003000000000300000000425200133343330000000000000000000000
66666666000000005555000000000000435363435353330400132323334353331252528352525283528282528252526242525282526211114252525222223213
__label__
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000010000001100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000001100000000011000000000700000000000000000000000000000000000000000000000
00000000000000000000000000000000000007000777000000000000110000000000000110000007770000000000000000000000000000000000000000000000
000000000000000000000000000000000000707000700000000000cc00000000000000000cc00000700000070000000000000000000000000000000000000000
00000000000000000000000000000000000007000000000000000c000000000000000000000c0000000007777700000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000c00000000000000000000000c000000000070000000000000000000000000000000000000000
000000000000000000000000000000000000000000070000000c0000000000000000000000000c00000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070700000c000000000000000000000000000c0007070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000000000000000000000000000000000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000666660066666600666666006666660066666600666666006600066000000000000000000000000000000000000
00000000000000000000000000000000000006666666066666660666666606666666066666660666666606660066000000000000000000000000000000000000
00000000000000000000000000000000000006600000000660000660000006600066066000660660000006666066000000000000000000000000000000000000
0000000000000000000000000000000000000ddddddd000dd0000dddd0000dddddd00dddddd00dddd0000ddddddd000000000000000000000000000000000000
0000000000000000000000000000000000000000000d000dd0000dd000000dd000dd0dd000dd0dd000000dd0dddd000000000000000000000000000000000000
0000000000000000000000000000000000000ddddddd000dd0000dddddd00dd000dd0dd000dd0dddddd00dd00ddd000000000000000000000000000000000000
00000000000000000000000000000000000000ddddd0000dd0000ddddddd0dd000dd0dd000dd0ddddddd0dd000dd000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000700000000000066000660666666006660066666600000000007000000000000000000000000000000000000000
00000000000000000000000000000000000007770000000000066606660666666606666066666660000000007000000000000000000000000000000000000000
0000000000000000000000000000000000000070000000000c06666666066000000066006600066c000000777770000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000c0ddddddd0dddd00000dd00dd000ddc000000007000000000000000000000000000000000000000
00000000000000000000000000000000000000000700000000cdd0d0dd0dd0000000dd00dd000dd0000000007000000000000000000000000000000000000000
00000000000000000000000000000000000000007070000000cdd000dd0dddddd00ddd00ddddddd0000007000000000000000000000000000000000000000000
000000000000000000000000000000000000000007000000000dd000dd0ddddddd0dddd0dddddd00000070700000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000c000000000000000000000001000700007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000700100000000000000000000010000700000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000777001d00000000000000000dd00007770000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007000700000dd00000000000007d0000000700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077700000000007700000000077000000000700000000700000000000000000000000000000000000000
00000000000000000000000000000000000000000000777770000000000077700000700000000000000000007770000000000000000000000000000000000000
00000000000000000000000000000000000000000000077700000000000000000000000000000000000000000700000000000000000000000000000000000000
00000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000005550555055005500505000005550505005505550055005505500000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050505050505000000500505050505050500050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050555050505050555000000500555050505500555050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050505050005000000500505050505050005050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505055505550555000000500505055005050550055005050000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005500055055505000000055505550555055505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005550555055505550505000000550555055505550555055505500555055505550550000000000000000000000000000
00000000000000000000000000000000005000505005000500505000005000050050005050505050005050555050500500505000000000000000000000000000
00000000000000000000000000000000005500555005000500555000005550050055005500550055005050505055500500505000000000000000000000000000
00000000000000000000000000000000005000505005000500505000000050050050005050505050005050505050500500505000000000000000000000000000
00000000000000000000000000000000005000505055500500505000005500050055505050505055505050505050505550555000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000008080813020000000000000000000213000000030303030303030303000202020000000303030303030303030002020213131300030303030303030300020202020202000303030303030303020002020202020000020202020300030000020202020000020000020203030000020202020200
0200000000020200000000000000000002000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000000000000000000000000000000000000026000024353535353535353535353535515300000052545454575254515454514276424276424242532b000000005556424242424246424242430000000000003232323232323232323232323232323232323232323232323232323233000000
000000000000000000000000000000000000000000000000000000000000000026000030160000000000000000000000565700000055565657415656565656560000000000000000582b000000000000000000003b582b1b1b1b0000000000000000000000000000000000000000000000000000000000001b1b1b1b1b000000
00006600000000000000000000000000000000000000000000000000000000003300003700000000001111200000111146470000000000000000000000003b450000000000000000582b000000000000000000003b682b1600000000000000000000000000000000000000000000000000000000000000000000000000000000
00212222230000000000000000000000000000000000000000000000000000000000001b110000111121361b0000212254530000000000000000000000003b520100000000000000582b00000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000003900
002425253823000000000000000000000000000000000000000000000000000000007200202b003422331b000011242554570c00000000000c000000000c3b554643454744000000582b000000000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000002a00
2125323225253600000000000000000000000000000000000000000000000000000000001b00001b300000153b3432325700000000111111111111000000001b5741565643000000582b000000001345001200000000000000000000000000000000000000000000000000000000000000000000000000000000000041464646
3133400024330000000000000000000000000000000000000000000000000000000000000000000030000000001b1b00000000003b4546464345472b000000001b1b1b1b1b000000582b000000001352001700000000000000000000000000000000000000000000000000000017171700000000000000000000000000525454
000050003700000000000000000000000000000000000000000000000000000000000000000000112423111100000000000000003b5556574156572b160000000000000000000000582b000000001352111111111111111111111100000013170000000000000000000000000000000000000000000000000000000000525454
00000000000000000000000000000000000000000000000000000000000000000000000000000034323235353523000000000000001b1b1b1b1b1b00000000000000000000000000582b00000000135542427642427642467642432b000000000000000000000000000000212311111111111111111111111111111111555454
000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000001111111111582b0000000013441b1b1b1b1b1b1b581b1b1b00000000000000000000000000272136242522222334222222222222223621222222235554
00000000000000000064650000000000000000000000000000000000003a000000000000000000000000000000300000000000000000000000000000000000000000006700454647582b0000000013450000000000003b582b000000000000000000000000000021263721252525252523313232322525263425252525252355
00000000000000000074750000000000000000000000000000000000006600000000000000000000000000000037000000000b00000000000b00000000000b000000000000555657682b0000000013550000000000003b682b000000000000000000000000342225262125323232323232353535363132323631323232323236
0000000000000000212222232122230000000000000000000000000000342222000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b00000000000000000000003422232425333133000000000000000000000000000000000000000000
0000010000000021252528263125260000000000000000000000000000002425000000111100003b20000000000000000100000000000000000000000000000000000000000000000016000000000000000100000000000000160000000000000000212331333133000000000000000000000000000000000000000000000000
002122222222233125252538233133000000000000000000000000000000312501000034230000001b000000000034354647454744000000000000000000000000001600000000000000000000000000464646470000000000000000000000000000242536000000000000000000000000000000000000000000000000000000
2225252528252523313232323235360000000000000000000000000000000024222222233700000000000000000000005453525447000000000000000000000000000000000000000000000000000000545154530000000000000000000000000000313300000000000000000000000000000000000000000000000000000000
471b4800000000000000000000000000545453545453000000005254545454510000000000001b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b301b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b30000000323232323232323232323232323232250000200000000000000000000000000000000000000000000000000039000000
530058000000000000000000000000005451535451530000000052515454545400000000160000000000000000000000000000000000000000003b302b00000000000000000000000000003b3000000000000000000000000000000000003b24000029000000000000000000000000000000000000000000000000002a000000
530058000000000000000000000000005456575656570000000052545454515400000000000000000000000000000000000000000000000000003b372b00000000000000000000000000003b3000000000000000000000000000000000003b242222222334353522223536000000000000000034352236212321222222230000
53005800000000000000000000000000574546464647000000005556565454540000000000000000160000001600000021222300000000000000001b0000000016000011000000000000003b3000000000010000000000000000000000003b242528252522362125330000000000000000000000003721252631323225260000
5300580000000000000000000000000046545154545300000000000000525454000011111111111111111111111111113132330000000000000000160000001108003b27000000000000003b3000000022231111111111111111111100003b242525382533213233000000000000000000000000000031323435222331260000
5300680000000000000000000000000054545454545300000000000000555154000034353535353536343535353634353535353600000000000000000000002700003b30000000000000003b3000160028253535353535353535353600003b242832252634330000000000000000000000000000000000000027242523370000
530048454646470000000000000000005454545154530000000000000000525100001b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b00000000000000110000003711111130111100000000003b3000000025330000000000000000000000003b243320313300000000000000000000000000000000000000000037313232230000
5301585556565700000000000000000054565454545745464700000000005556000000000000000000000000000000000000000000000000000000270000001b35353532353600000000003b30000000262b0000000000000000000000003b240000000000000000000000000000000000000000000000000000000000370000
53005242764242764243000000000000530d525657455656570000000000000000000000000000000000000000000000000000000000000000000030000000111b1b1b1b1b1b00000000111130111100262b0000000000000000000000003b240000000000000000000000000000000000000000290000000000000000000000
5300580000000000000000000017000053015800006800000000000000000000000000000000000000000000000000001111111100000000000000370000002700000000000000000000343532353600262b0000000000000000001100003b2400000000000000000000000000000000000000712a0000000000000000000000
53005800000000000000000000170000530d5800001b000000000000000000000000000100000000000000000000000034362123000000000000001b00000037000000000000110000001b1b1b1b1b00262b000000000000000000202b003b240000000000000000000000000000000000002122223621230000000000212320
5300680000000000000000000017000053005800000000000011000000000000000045464700003422233422230000002122252600000000000000000000001b00000000003b2000000000000000000033110000000000000000001b00003b240000000000000000000000000000000021222525332125260000000000312523
53004800000000000000000000000000530d5800001100000048000000000000464752545300002031323631330000002425323300000000001600000000000000000000003b2700000000000000000022232b00000000000000000000003b240000000000212321223621223600002724252533343232330000000000273126
5300580100000000000000000000000053005801004800000058001200000000515352545300000000000000000000002433212300000000000000000000000000000000003b3000000000001600000038262b000000111111111111111111240000000021252624262128330000003024253321222222230000000000242330
53005546464243764348000000000000530d5546465446464653454647000000545352545300000000000000000000003721252600000000000000000000000000010014003b3000000000000000000032332b000000343535353535353522250100342225253331332426000000003031332125252525260000000000242630
570044555741764243680000000000005700445556565656565755565700000051535251530000000000000000000000212525260000000000000000000000003535353435353300000000000000000022232b0000001b1b1b1b1b1b1b3b24252122233132332122232426000000002422222525252525260000000000242637
__sfx__
951f00200b630096310863107631076310763108631096410b6410e6411264115641196411c641206512365126651286512a6612b6612c6612b6612a6512865125651216411d64115641116310d6310b6310b631
111f00002b155241052b1002b1352e1552b1002b1152e13529155240002e11529135240002e115291252400024000291152400026100291152400024000240002615524000240002613524000240002612524000
111f000024155181051f10024135221551f1002411522135261552400022115261351800022115261251800018000261151800018000261151800018000180001800000000000000000000000000000000000000
010f0000287222672225722217222872226722257222d722287222672225722217222872226722257222d722287222672225722217222872226722257222d722287222672225722217222872226722257222d722
010f00002672224722237221f7222672224722237222b7222672224722237221f7222672224722237222b7222672224722237221f7222672224722237222b7222672224722237221f7222672224722237222b722
010f00002472223722217221d722247222372221722297222472223722217221d722247222372221722297222472223722217221d722247222372221722297222472223722217221d72224722237222172229722
5d0f00000065509112092150921500655091150921509215006550911509215092150065509115092150921500655091120921509215006550911509215092150065509115092150921500655091150921509215
5d0f00000065507112072150721500655071150721507215006550711507215072150065507115072150721500655071120721507215006550711507215072150065507115072150721500655071150721507215
5d0f00000065505112052150521500655051150521505215006550511505215052150065505115052150521500655051120521505215006550511505215052150065505115052150521500655051150521505215
950a0000156321e632226322263221632206321e6321d6321c6321a632196321763216622146221262211622106220f6220e6220c6120b6120a61209612076120661205612046120361202612016120061201612
950f00000660207602076020061200612006120061201612016120261203612046120661207612096120b6120d6120f62211622136221362216632176321863219632196321a6321b6321c6321b6321864212642
010f00002d7122d7222d7222d7222d7122d7222d7222d722347123472234722347223471234722347223472234712347223472234722347123472234722347223271232722327223272237712377223772237722
010f00003271232722327223272232712327223072230722307123072230722307222f7122f7222f7222f7222f7122f7222b7222b7222b7122b7222b7222b722327123272232722327222b7122b7222b7222b722
010f00002d7122d7222d7222d7222d7122d7223472234722347123472234722347223471234722347223472234712347223472234722347123472234722347223271232722347223472232712327223072230722
010f0000327123272232722327223271232722377223772237712377223772237722367123672236722367223671236722367220670036712367223772236722367123672232722327222d7122d7222a7222a722
010f00002971229722297222972229712297222972229722297122972229722297222b7122b7222d7222d7222d7122d7222d7222d7222d7122d72230722307223071230722307223072230712307223072230722
010f00002f7122f7222f7222f7222f7122f7222f7222f7222f7122f7222f7222f7222b7122b722287222872228712287222872228722287122872228722287222f7122f7222f7222f7222f7122f7222f7222f722
010f0000317123172231722317223171231722317223172231712317223172231722317123172231722317223171231722317223172231712317222f7222f7222f7122f7222f7222f72234712347223472234722
010f00002d7122d7222d7222d7222d7122d7222d7222d7222d7122d7222d7222d7222d7122d7222d7222d7222d7122d7222d7222d7222d7122d7222d7222d7222b7122b7222b7222b7222b7122b7222b7222b722
5d0f0000006550911234615092152d625091153461509215006550911534615092152d625091153461509115006550911234615092152d625091153461509215006550911534615092152d625091153461534615
5d0f0000006550711234615071152d625071153461507115006550711534615071152d625071153461507115006550711234615071152d625071153461507115006550711534615071152d625071153461534615
5d0f0000006550511234615051152d625051153461505115006550511534615051152d625051153461505115006550511234615051152d625051153461505115006550511534615051152d625051153461534615
011d00001514500100191451512521145191251f14521115001001f12521115001001f1150010000100151141514500100191451512521145191251f14521115001001f12521115001001f115001000010013114
011d0000131450010017145131251a145171251e14521115001001e12521115001001e115211000010013114131450010017145131251a145171251e14521115001001e12521115001001e115211000010015114
c11d00002b055000002b01500000320551c00032025000003201500000000000000030055000003001500000320550000032015000002b055000002b025000002b01500000000000000000000000000000000000
c11d00002d055000002d01500000340551c00034025000003401500000000000000032055000003201500000340550000034015000002d055000002d025000002d01500000000000000000000000000000000000
7d0f0000214453040000400214350040000400214250040028445004000040028435004000040028425004002d44500400004002d43500400004002d425004003444500400004003443500400004003442500400
7d0f00001f44530400004001f43500400004001f4250040026445004000040026435004000040026425004002b44500400004002b43500400004002b425004003244500400004003243500400004003242500200
7d0f00001d44530400004001d43500400004001d42500400244450040000400244350040000400244250040029445004000040029435004000040029425004002644500400004002643500400004002642500200
d61d00200b621096210861107611076110761108611096110b6110e6111261115621196211c621206212362126631286312a6312b6412c6412b6412a6412864125631216311d63115621116210f6210d6210c611
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196002c0002a0003f600000003f600000003f6003f6003f6003f600
020200001107013070190702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
010400000f5701e570125702257017570265701b5602c560215503155027540365402b5303a530305203e52035510000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01030000075700a5700e5701057016570225702f5702f5602c5602c5502f5502f5402c5402c5302f5202f5102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0103000005510075303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
010400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
001000001f57518575275752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000b000019562195751956219552155621556217552155521c5621c5521c5421c5321c5221c512211002150021300213002130021300213002130021300213002870026700257002170016300163001d3001d300
010c0000181751f1752317524175181451f1452314524145181351f1352313524135181251f1252312524125181151f115231152411518115241052b30530305243052b205302053a2052e205002050020500205
010500000353005531075410c541135511b5612457030571275702e5712457030571275702e5712456030561275602e5612455030551275502e5512454030541275402e5412453030531275202e5212451030311
010300001f5302b53022530295301f5202b52022520295201f5102b51022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
__music__
01 00404344
00 00424344
00 00014344
02 00024344
01 03464944
00 04474344
00 03064344
00 04074344
00 05084344
00 04074344
00 03064344
02 03064a44
01 43060b44
00 44070c44
00 03060d44
00 04070e44
00 05080f44
00 04071044
00 43061144
02 43061244
01 03130b1a
00 04140c1b
00 03130d1a
00 04140e1b
00 05150f1c
00 0414101b
00 0313111a
02 0313121a
01 16404344
00 17424344
01 16194344
02 17184344
01 161d4344
00 171d4344
01 161d1944
02 171d1844

