pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- adelie golf
-- by calverin
-- based on celeste classic by maddy thorson + noel berry

menuitem(1,"restart level(🅾️)",function() for o in all(objects) do if o.type==player then kill_player(o) break end end end)
menuitem(2,"⬅️level➡️ w/ s/f",function() cheated=true menuitem(2,"[cheat mode on]") return true end)

-- "data structures"

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

poke(0x5f2d,1)--mouse

-- [globals]

room,
objects,got_fruit,
freeze,shake,delay_restart,sfx_timer,music_timer,
screenshake=
vector(0,0),
{},{},
0,0,0,0,0,
true

mx,my,mx_p,my_p,mv,mb,ms_x,ms_y=0,0,0,0,{x=0,y=0},0,0,0 --mouse vars
is_aiming=false
hit_effect = 0
stroke = 0
--par = 0
total_strokes = 0
strokes = {}
pars = { 	  -- best strokes on the right
	6, -- 100m
	7, -- 200m
	5, -- 300m
	7, -- 400m 2
	4, -- 500m 
	4, -- 600m
	5, -- 700m
	4, -- 800m
	5, -- 900m 2
	7, -- 1000m
	5, -- 1100m
	5, -- 1200m
	99, -- old site
	5, -- 1400m
	5, -- 1500m
	5, -- 1600m
	5, -- 1700m
	5, -- 1800m
	5, -- 1900m
	5, -- 2000m
	5, -- 2100m
	5, -- 2200m
	5, -- 2300m
	5, -- 2400m
	5, -- 2500m
	5, -- 2600m
	5, -- 2700m
	5, -- 2800m
	5, -- 2900m
	5, -- 3000m
	3, -- summit
}
cheated = false
finished = false

-- [entry point]

function _init()
	title_screen()
end

function title_screen()
	frames,start_game_flash=0,0
	music(40,0,7)
	load_room(7,3)
end

function begin_game()
	deaths,frames,seconds,minutes,music_timer=1,0,0,0,0,0
	music(0,0,7)
	load_room(0,0)
	finished=true
end

function level_index()
	return room.y*8+room.x+1
end

function is_title()
	return level_index()==32
end

-- [effects]

clouds={}
for i=0,16 do
	add(clouds,{
		x=rnd(128),
		y=rnd(128),
		spd=1+rnd(4),
		w=32+rnd(32)
	})
end

particles={}
for i=0,24 do
	add(particles,{
		x=rnd(128),
		y=rnd(128),
		s=flr(rnd(1.25)),
		spd=0.25+rnd(5),
		off=rnd(),
		c=6+rnd(2),
	})
end

dead_particles={}

-- [player entity]

player={
	init=function(this)
		this.grace=0
		this.hitbox=rectangle(0,0,8,8)
		this.spr_off=0
		this.solids=true
		this.balloons=0
		this.balloon_list={}
		is_aiming=false
		this.shot_direction=vector(0,0)
		this.at_limit=false
		this.rot=0
		this.standing_still=0
		this.was_on_ground=false
		this.was_under_ground=false
		this.club_pos=vector(0,0)
		this.club_ang=0
	end,
	update=function(this)
		if pause_player then
			return
		end

		-- horizontal input
		local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0

		if (btnp(4)) kill_player(this)

		-- spike collision / bottom death
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or
			this.y>128 then
			kill_player(this)
		end

		-- on ground checks
		local on_ground=this.is_solid(0,1)
		local under_ground=this.is_solid(0,-1)

		if on_ground and under_ground then this.spd.y=0 end


		if this.right()>=ms_x-2 and this.bottom()>=ms_y-2 and this.left()<=ms_x+4 and this.top()<=ms_y+4 then 
			if not is_aiming and hit_effect == 0 and mb==1 and this.spd.x == 0 and abs(this.spd.y) <= 0.5 and not (this.balloons==3 and not under_ground) then
				is_aiming=true
				stroke += 1
				total_strokes += 1
			end
		end
		if is_aiming then
			local radius = 32
			local v = vector(ms_x - 6 - this.x + 4, ms_y - 7 - this.y + 4)
			local magnitude = sqrt(v.x^2 + v.y^2)
			local unit_v = vector(-v.x / magnitude, -v.y / magnitude)
			if magnitude > radius then
				this.at_limit = true
				magnitude = radius
			else
				this.at_limit = false
			end
			shot_direction = vector(unit_v.x * magnitude, unit_v.y * magnitude)
			if mb == 0 then
				is_aiming=false
				hit_effect = 4
			end
		end

		if hit_effect > 0 then
			hit_effect -= 1
			this.init_smoke((this.club_pos.x-this.x + 4),(this.club_pos.y-this.y + 4))
			if hit_effect == 0 then
				on_ground = false
				this.was_on_ground = false
				this.spd.x = shot_direction.x / 6
				this.spd.y = shot_direction.y / 6
				psfx(3)
				this.init_smoke()
			end
		end


		if under_ground and this.spd.y < 0 and not this.was_under_ground then
			this.spd.y *= -0.6
			this.spd.x *= this.is_ice(0,-1) and 0.9 or 0.6
			if abs(this.spd.y) < 0.2 then
				this.spd.y = 0
			end
			if abs(this.spd.x) < 0.1 then
				this.spd.x = 0
			end
		end

		-- landing smoke
		if (on_ground and not this.was_on_ground) then
			if abs(this.spd.y)>=1.5 then
				this.init_smoke(0,4)
				psfx(5)
			end
			if this.spd.y > 0 and (this.check(platform,this.x/8,(this.y/8)+1) or this.check(platform,(this.x/8)+1,(this.y/8)+1) or this.check(platform,(this.x/8)-1,(this.y/8)+1) or this.check(platform,this.x/8,(this.y/8)) or this.check(platform,(this.x/8)+1,(this.y/8)) or this.check(platform,(this.x/8)-1,(this.y/8))) then this.spd.y = 0 this.spd.x *= 0.5 end
			if this.spd.y > 0 then this.spd.y *= -0.6 end
			this.spd.x *= this.is_ice(0,1) and 0.9 or 0.6
			if abs(this.spd.y) < 0.2 then
				this.spd.y = 0
			end
			if abs(this.spd.x) < 0.1 then
				this.spd.x = 0
			end
		end

		-- x movement
		local maxrun=1
		local accel=this.is_ice(0,1) and 0.05 or on_ground and 0.6 or 0.4

		-- set x speed
		this.spd.x=appr(this.spd.x,0,((on_ground or under_ground) and 0.05 or 0.01) + this.balloons/100)

		if ((this.is_solid(1,0) or this.x + 8 > 127) and this.spd.x > 0) or ((this.is_solid(-1,0) or this.x < 2) and this.spd.x < 0) then
			if abs(this.spd.x)>=1.5 then
				this.init_smoke(this.spd.x/2,0)
				psfx(5)
			end
			this.spd.x*=-.8
		end

		-- y movement
		local l_grav = 1 - (this.balloons / 2)
		local maxfall = 2 - (this.balloons * 0.75)

		if (l_grav == 0) l_grav = -0.5
		if (maxfall == 0) maxfall = -0.5

		-- apply gravity
		if not on_ground then
			this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.15 and 0.21*abs(l_grav) or 0.105*abs(l_grav))
		end

		-- exit level off the top (except summit)
		if this.y<-4 and level_index()<31 then
			next_room()
		end

		-- was on the ground
		this.was_on_ground=on_ground
		this.was_under_ground=under_ground

		-- update rotation
		if this.spd.x~=0 then
			this.rot+=this.spd.x/2
		end

		if this.spd.x == 0 and this.spd.y == 0 and (on_ground or under_ground) then
			this.standing_still+=1
		else
			this.standing_still=0
		end
	end,

	draw=function(this)
		-- clamp in screen
		local clamped=mid(this.x,-1,121)
		if this.x~=clamped then
			this.x=clamped
			--this.spd.x=0
		end
		if this.balloon_list~=nil then draw_balloons(this) end
		
		-- outline
		--for i=0, 15 do pal(i,6) end
		--for dx=-1,1 do for dy=-1,1 do if dx&dy==0 then
		--	camera(dx,dy) spr(1, this.x, this.y)
		--end end end
		--pal()
		--camera()

		-- aiming arrow
		if is_aiming or hit_effect > 0 then
			
			if is_aiming then
				if this.at_limit then
					circ(this.x+4, this.y+4, 32, 8)
				end
				-- main line
				line(this.x+4, this.y+4, this.x+4+shot_direction.x, this.y+4+shot_direction.y, 7)
				-- arrow head
				local arrow_head = vector(mid(-6,shot_direction.x * 0.25,6), mid(-6,shot_direction.y * 0.25,6))
				line(this.x+4+shot_direction.x, this.y+4+shot_direction.y, this.x+4+shot_direction.x-arrow_head.x-arrow_head.y, this.y+4+shot_direction.y-arrow_head.y+arrow_head.x, 7)
				line(this.x+4+shot_direction.x, this.y+4+shot_direction.y, this.x+4+shot_direction.x-arrow_head.x+arrow_head.y, this.y+4+shot_direction.y-arrow_head.y-arrow_head.x, 7)
				this.club_pos = vector(-shot_direction.x + this.x + 4, -shot_direction.y + this.y + 4)
				this.club_ang = atan2(shot_direction.y, shot_direction.x) + 0.25
			else
				-- the golf club moves towards the ball with easing
				this.club_pos.x += (this.x + 4 - this.club_pos.x) / (hit_effect*2)
				this.club_pos.y += (this.y + 4 - this.club_pos.y) / (hit_effect*2)
				-- and rotates as it gets closer so that the end hits the ball
				local club_distance = sqrt((this.club_pos.x - this.x - 4)^2 + (this.club_pos.y - this.y - 4)^2)
				this.club_ang += (atan2(shot_direction.y, shot_direction.x) - this.club_ang) / (club_distance / 2)
			end
			-- rotate golf club perpindicular to shot direction
			rspr(72, 48, this.club_pos.x - 8, this.club_pos.y - 8, this.club_ang, 2, 2)
		elseif ((this.standing_still or 0) > 75 and hit_effect == 0) then
			-- current attempt
			--draw_par(this.x, this.y, 1)
		end

		spr(1 + (this.rot or 0)%4, this.x, this.y)
	end
}
-- [other entities]



function create_balloons(obj,id,remove)
	if remove == nil then
		add(obj.balloon_list,{x=obj.x,y=obj.y,offset=rnd(100),id=id})
	else
		obj.balloons -= 1 -- remove balloon from count
		for o in all(objects) do 
			if o.type == balloon_pickup then
				if o.id == remove.id then
					init_object(smoke,remove.x,remove.y,29)
					o.collected = false
					del(obj.balloon_list,remove)
				end
			end
		end
	end
end

function draw_balloons(obj)
	local last=vector(obj.x+(obj.balloons-1)*3.5,obj.y-(btn(⬇️) and 12 or 13))
	for o in all(obj.balloon_list) do
		--if spikes_at(o.x+1,o.y-7,o.x+6,o.y-1,(last.x-o.x)/1.75,(last.y+0.5-o.y+sin(o.offset/50))/1.75) then init_object(smoke,o.x,o.y,29) create_balloons(obj,0,o) end
		o.x+=(last.x-o.x)/1.75
		o.y+=(last.y+0.5-o.y+sin(o.offset/50))/1.75

		spr(22,o.x,o.y)
		last=vector(o.x-(obj.balloons > 1 and 6 or 0),o.y)
		o.offset=(o.offset+1)%100
		line(o.x+4,o.y+7,obj.x+(obj.flip.x and 4 or 3),obj.y+2,6)
	end
end
player_spawn={
	init=function(this)
		sfx(4)
		this.spr=1
		this.target=this.y
		this.y=128
		this.spd.y=-4
		this.state=0
		this.delay=0
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
					shake=5
					this.init_smoke(0,4)
					sfx(5)
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
	draw=player.draw
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
				--hit.spd.x*=0.2
				hit.spd.y=-3.5
				this.delay=10
				this.init_smoke()
				-- crumble below spring
				break_fall_floor(this.check(fall_floor,0,1) or {})
				psfx(8)
			end
		elseif this.delay>0 then
			this.delay-=1
			if this.delay<=0 then
				this.spr=18
			end
		end
		-- begin hiding
		if this.hide_in>0 then
			this.hide_in-=0.5
			if this.hide_in<=0 then
				this.hide_for=60
				this.spr=0
			end
		end
	end
}

balloon_pickup={
	init=function(this)
		this.offset=rnd(100)
		this.start=this.y
		this.timer=0
		this.hitbox=rectangle(-1,-1,10,10)
		this.id=rnd(10000000)
		this.collected=false
	end,
	update=function(this)
		if this.spr==22 then
			this.offset=(this.offset+1)%100
			this.y=this.start+sin(this.offset/100)*2
			local hit=this.player_here()
			if hit then --and hit.balloons<5 then
				psfx(6)
				this.init_smoke()
				hit.balloons+=1
				--hit.spd.x*=0.7
				create_balloons(hit,this.id,nil)
				this.spr=0
				this.timer=60
				this.collected = true
			end
		elseif this.timer>0 then
			this.timer-=1
		elseif not this.collected then
			psfx(7)
			this.init_smoke()
			this.spr=22
		end
	end,
	draw=function(this)
		if this.spr==22 then
			for i=7,13 do
				pset(this.x+4+sin(this.offset/50+i/10),this.y+i,6)
end
			draw_obj_sprite(this)
			--spr(this.spr,this.x,this.y)
		end
	end
}

fall_floor={
	init=function(this)
		this.state=0
		--this.delay=0
	end,
	update=function(this)
		-- idling
		if this.state==0 then
			for i=0,2 do
				if this.check(player,i-1,-(i%2)) then
					break_fall_floor(this)
				end
			end
			if this.check(player,0,1) then break_fall_floor(this) end
		-- shaking
		elseif this.state==1 then
			this.delay-=0.5
			if this.delay<=0 then
				this.state=2
				this.delay=60--how long it hides for
				this.collideable=false
			end
		-- invisible, waiting to reset
		elseif this.state==2 then
			this.delay-=1
			if this.delay<=0 and not this.player_here() then
				psfx(7)
				this.state=0
				this.collideable=true
				this.init_smoke()
			end
		end
	end,
	draw=function(this)
		spr(this.state==1 and 26-this.delay/12 or this.state==0 and 23,this.x,this.y)
	end
}

function break_fall_floor(obj)
	if obj.state==0 then
		psfx(15)
		obj.state=1
		obj.delay=35--how long until it falls
		obj.init_smoke();
		(obj.check(spring,0,-1) or {}).hide_in=35
	end
end

smoke={
	init=function(this)
		this.spd=vector(0.3+rnd(0.2),-0.1)
		this.x+=-1+rnd(2)
		this.y+=-1+rnd(2)
		this.flip=vector(maybe(),maybe())
	end,
	update=function(this)
		this.spr+=0.2
		if this.spr>=32 then
			destroy_object(this)
		end
	end
}

fruit={
	if_not_fruit=true,
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
	if_not_fruit=true,
	init=function(this)
		this.start=this.y
		this.off=0.5
		this.sfx_delay=8
	end,
	update=function(this)
		this.off+=0.05
		this.spd.y=sin(this.off)*0.5
		-- collect
		check_fruit(this)
	end,
	draw=function(this)
		draw_obj_sprite(this)
		--spr(this.spr,this.x,this.y)
		for ox=-6,6,12 do
			spr((sin(this.off)>=0) and 45 or this.y>this.start and 47 or 46,this.x+ox,this.y-2,1,1,ox==-6)
		end
	end
}

function check_fruit(this)
	local hit=this.player_here()
	if hit then
		sfx_timer=20
		sfx(13)
		if this.type==fly_fruit then
			hit.spd.y -= 2
		end
		got_fruit[level_index()]=true
		init_object(lifeup,this.x,this.y)
		destroy_object(this)
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
	if_not_fruit=true,
	update=function(this)
		this.hitbox=rectangle(-1,-1,18,18)
		local hit=this.player_here()
		if hit then
			hit.spd=vector(hit.spd.x*0.5,hit.spd.y*0.5)
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
		spr(64,this.x,this.y,1,2)
		spr(64,this.x+8,this.y,1,2,true,true)
	end
}

function init_fruit(this,ox,oy)
	sfx_timer=20
	sfx(16)
	init_object(fruit,this.x+ox,this.y+oy,26)
	destroy_object(this)
end

key={
	if_not_fruit=true,
	update=function(this)
		this.spr=9.5+sin(frames/30)
		if frames==18 then
			this.flip.x=not this.flip.x
		end
		if this.player_here() then
			sfx(23)
			sfx_timer=10
			destroy_object(this)
			has_key=true
		end
	end
}

chest={
	if_not_fruit=true,
	init=function(this)
		this.x-=4
		this.start=this.x
		this.timer=20
	end,
	update=function(this)
		if has_key then
			this.timer-=1
			this.x=this.start-1+rnd(3)
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
		this.last=this.x
		this.dir=this.spr==11 and -1 or 1
	end,
	update=function(this)
		this.spd.x=this.dir*0.65
		if this.x<-16 then this.x=128
		elseif this.x>128 then this.x=-16 end
		if not this.player_here() then
			local hit=this.check(player,0,-1)
			if hit then
				--hit.move_x(this.x-this.last,1)
				--hit.move_loop(this.x-this.last,1,"x")
				hit.move(this.x-this.last,0,1)
			end
		end
		this.last=this.x
	end,
	draw=function(this)
			spr(11,this.x,this.y-1,2,1)
	end
}

message={
	draw=function(this)
		this.text="-- adelie putt-putt --#:)this mod is for you!#thx for being so cool!#(ty to meep+ruby too!)"
		if this.check(player,4,0) then
			if this.index<#this.text then
			 this.index+=0.5
				if this.index>=this.last+1 then
					this.last+=1
					sfx(35)
				end
			end
			local _x,_y=8,96
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(_x-2,_y-2,_x+7,_y+6 ,7)
					?sub(this.text,i,i),_x,_y,0
					_x+=5
				else
					_x=8
					_y+=7
				end
			end
		else
			this.index=0
			this.last=0
		end
	end
}

big_chest={
	init=function(this)
		this.state=0
		this.hitbox.w=16
		this.spr=0
	end,
	draw=function(this)
		if this.state==0 then
			local hit=this.check(player,0,8)
			if hit and hit.is_solid(0,1) then
				music(-1,500,7)
				sfx(37)
				pause_player=true
				hit.spd=vector(0,0)
				this.state=1
				this.init_smoke()
				this.init_smoke(8)
				this.timer=60
				this.particles={}
			end
			sspr(0,48,8,16,this.x,this.y,8,16,false,false)
			sspr(0,48,8,16,this.x+8,this.y,8,16,true,false)
		elseif this.state==1 then
			this.timer-=1
			shake=5
			flash_bg=true
			if this.timer<=45 and #this.particles<50 then
				add(this.particles,{
					x=1+rnd(14),
					y=0,
					h=32+rnd(32),
					spd=8+rnd(8)
				})
			end
			if this.timer<0 then
				this.state=2
				this.particles={}
				flash_bg=false
				new_bg=true
				init_object(orb,this.x+4,this.y+4)
				pause_player=false
			end
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
	draw=function(this)
		this.spd.y=appr(this.spd.y,0,0.5)
		if this.spd.y >= -0.001 then
			this.spd.y = -6
		end
		local hit=this.player_here()
		if this.spd.y==0 and hit then
			music_timer=45
			sfx(51)
			freeze=10
			shake=10
			destroy_object(this)
		end
		sspr(88,49,19,15,this.x-5,this.y-3)
		spr(5, this.x, this.y + 100, 1, 1, this.y%40<20 and true or false)
		spr(5, this.x, this.y + 130, 1, 1, this.y%40>20 and true or false)
		spr(5, this.x, this.y + 160, 1, 1, this.y%40<20 and true or false)
		spr(5, this.x, this.y + 190, 1, 1, this.y%40>20 and true or false)
		for i=0,0.875,0.125 do
			circfill(this.x+4+cos(frames/30+i)*16,this.y+4+sin(frames/30+i)*16,2,7)
		end
	end
}

flag={
	init=function(this)
		--this.show=false
		this.x+=5
		this.score=0
		for _ in pairs(got_fruit) do
			this.score+=1
		end
	end,
	draw=function(this)
		this.spr=118+frames/5%3
		rectfill(this.x-5,this.y,this.x+3,this.y+7,5)
		spr(102,this.x-3,this.y)
		spr(102,this.x,this.y-8)
		spr(this.spr,this.x+7,this.y-16)
		--spr(this.spr,this.x,this.y)
		if this.show then
			local c = cheated and 6 or 7
			rectfill(32,2,96,40,0)
			spr(26,55,6)
			?"x"..this.score,64,9,c
			draw_time(49,16,c)
			?"deaths:"..deaths,48,25,c
			?"strokes:"..stroke,46,33,c

		elseif this.player_here() then
			sfx(55)
			sfx_timer=30
			this.show=true
			finished=true
		end
	end
}

room_title={
	init=function(this)
		this.delay=5
	end,
	draw=function(this)
		this.delay-=1
		if this.delay<-30 then
			destroy_object(this)
		elseif this.delay<0 then
			rectfill(24,58,104,70,0)
			rectfill(50,70,75,76,0)
			local level=level_index()
			if level==12 then
				?"old site",48,62,7
			elseif level==31 then
				?"summit",52,62,7
			else
				?level.."00 m",level<10 and 54 or 54,62,7
			end
			--par = pars[level_index()]
			--local offset = (par < 10 and 12 or 14)
			--if par > 9 then offset += 2 end
			--local x = 64
			--local y = 70
			--print("pAR: " .. par, x - offset, y, 6)
			--draw_par(54, 64, 0)
			draw_time(4,4)
		end
	end
}

--[[
function draw_par(x, y, bg)
	stroke = stroke or -1
	par = pars[level_index()]
	local c = 8
	if stroke == par then
		c = 9
	elseif stroke < par / 2 then
		c = 11
	elseif stroke < par then
		c = 10
	end

	local offset = (stroke < 10 and 12 or 14)
	if par > 9 then offset += 2 end
	rectfill(x - offset + 4, y + 10, x + 4 + offset, y + 16, 0)
	print("pAR" .. stroke .. "/" .. par, x + 5 - offset, y + 11, c)
end
--]]

psfx=function(num)
	if sfx_timer<=0 then
	 sfx(num)
	end
end

-- [tile dict]
tiles={
	[1]=player_spawn,
	[8]=key,
	[11]=platform,
	[12]=platform,
	[18]=spring,
	[20]=chest,
	[22]=balloon_pickup,
	[23]=fall_floor,
	[26]=fruit,
	[28]=fly_fruit,
	[64]=fake_wall,
	[86]=message,
	[96]=big_chest,
	[118]=flag
}

-- [object functions]

function init_object(type,x,y,tile)
	if type.if_not_fruit and got_fruit[level_index()] then
		return
	end

	local obj={
		type=type,
		collideable=true,
		solids=false,
		spr=tile,
		flip=vector(),
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

	function obj.init_smoke(ox,oy)
		init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),29)
	end

	function obj.is_solid(ox,oy)
		return (oy>0 and not obj.check(platform,ox,0) and obj.check(platform,ox,oy)) or
			obj.is_flag(ox,oy,0) or
			obj.check(fall_floor,ox,oy) or
			--obj.check(fake_wall,ox,oy) or
			(oy>0 and not obj.is_flag(ox,0,3) and obj.is_flag(ox,oy,3))
	end

	function obj.is_ice(ox,oy)
		return obj.is_flag(ox,oy,4)
	end

	function obj.is_flag(ox,oy,flag)
		for i=max(0,(obj.left()+ox)\8),min(15,(obj.right()+ox)/8) do
			for j=max(0,(obj.top()+oy)\8),min(15,(obj.bottom()+oy)/8) do
				if fget(tile_at(i,j),flag) then
					return true
				end
			end
		end
		--return tile_flag_at(obj.left()+ox,obj.top()+oy,obj.right()+ox,obj.bottom()+oy,flag)
	end

	function obj.check(type,ox,oy)
		for other in all(objects) do
			if other and other.type==type and other~=obj and other.collideable and
				other.right()>=obj.left()+ox and
				other.bottom()>=obj.top()+oy and
				other.left()<=obj.right()+ox and
				other.top()<=obj.bottom()+oy then
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
			local amt=flr(obj.rem[axis]+0.5)
			obj.rem[axis]-=amt
			if obj.solids then
				local step=sign(amt)
				local d=axis=="x" and step or 0
				for i=start,abs(amt) do
					if not obj.is_solid(d,step-d) then
						obj[axis]+=step
					else
						break
					end
				end
			else
				obj[axis]+=amt
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

function kill_player(obj)
	sfx_timer=12
	sfx(0,1)
	deaths+=1
	shake=10
	destroy_object(obj)
	dead_particles={}
	for dir=0,0.875,0.125 do
		add(dead_particles,{
			x=obj.x+4,
			y=obj.y+4,
			t=2,--10,
			dx=sin(dir)*3,
			dy=cos(dir)*3
		})
	end
	--restart_room()
	delay_restart=15
end

-- [room functions]

--function restart_room()
--	delay_restart=15
--end

function next_room(go_back)
	go_back = go_back or false
	local level=level_index() - (go_back and 2 or 0)
	if level < 0 then
		level = 0
	end
	if level > 30 then
		level = 30
	end
	if level > 0 then
		strokes[level] = stroke
	end
	if level==11 or level==21 or level==30 then -- quiet for old site, 2200m, summit
		music(30,500,7)
	elseif level==12 then -- 1300m
		music(20,500,7)
	end
	load_room(level%8,level\8)
end

function load_room(x,y)
	is_aiming=false
	hit_effect = 0
	has_key=false
	local level = level_index()
	stroke = 0
	--par = pars[level]
	--remove existing objects
	foreach(objects,destroy_object)
	--current room
	room.x,room.y=x,y
	-- entities
	if not is_title() then
		for tx=0,15 do
			for ty=0,15 do
				local tile=tile_at(tx,ty)
				if tiles[tile] then
					init_object(tiles[tile],tx*8,ty*8,tile)
				end
			end
		end
		-- room title
		init_object(room_title,0,0)
	end
end

-- [main update loop]

function _update()
	frames+=1
	if level_index()<31 then
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

	-- screenshake
	if btnp(⬆️,1) then
		screenshake=not screenshake
	end
	if shake>0 then
		shake-=1
		camera()
		if screenshake and shake~=0 then
			camera(-2+rnd(5),-2+rnd(5))
		end
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
		elseif mb~=0 then
			music(-1)
			start_game_flash,start_game=50,true
			sfx(38)
		end
	elseif cheated then
		-- go back/forward a level
		if (btnp(0,1)) then
			next_room(true)
		end
		if (btnp(1,1)) then
			next_room()
		end
	end

	-- setting mouse vars
	mx_p,my_p=mx,my -- previous positions
	mx,my,mb=stat(32),stat(33),stat(34)

	mv.x = mx-mx_p
	mv.y = my-my_p
end

-- [drawing functions]

function _draw()
	if freeze>0 then
		return
	end

	-- reset all palette values
	pal()

	-- start game flash
	if is_title() and start_game then
		for i=1,15 do
			pal(i,start_game_flash>10 and (frames%10<5 and 7 or i) or (start_game_flash>5 and 2 or start_game_flash>0 and 1 or 0))
		end
	end

	-- draw bg color (pad for screenshake)
	cls()
	rectfill(0,0,127,127,flash_bg and frames/5 or new_bg and 2 or 0)

	-- bg clouds effect
	if not is_title() then
		foreach(clouds,function(c)
			c.x+=c.spd
			crectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,new_bg and 14 or 13)
			if c.x>128 then
				c.x=-c.w
				c.y=rnd(120)
			end
		end)
	end

	local rx,ry=room.x*16,room.y*16

	-- draw bg terrain
	map(rx,ry,0,0,16,16,4)

	-- draw clouds + orb chest
	foreach(objects,function(o)
		if o.type==platform then
			draw_object(o)
		end
	end)

	-- draw terrain (offset if title screen)
	if is_title() then
		sspr(80, 32, 46, 17, 18, 28, 92, 34)
	else
		map(rx, ry, 0, 0, 16, 16, 2)
	end
	-- draw objects
	foreach(objects,function(o)
		if o.type~=platform then
			draw_object(o)
		end
	end)

	-- draw fg terrain (not a thing)
	--map(room.x*16,room.y*16,0,0,16,16,8)

	-- particles
	foreach(particles,function(p)
		p.x+=p.spd
		p.y+=sin(p.off)
		p.off+=min(0.05,p.spd/32)
		crectfill(p.x,p.y,p.x+p.s,p.y+p.s,p.c)
		if p.x>132 then
			p.x=-4
			p.y=rnd(128)
		end
	end)

	-- dead particles
	foreach(dead_particles,function(p)
		p.x+=p.dx
		p.y+=p.dy
		p.t-=0.2--1
		if p.t<=0 then
			del(dead_particles,p)
		end
		pal(1,9)
		pal(2,1)
		crectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,1+p.t*5%2)
		pal(1,1)
		pal(2,2)
	end)

	-- credits
	if is_title() then
		?"click",52,80,5
		?"maddy thorson",40,96,5
		?"noel berry",46,102,5
		?"mod by ✽calverin✽",30,114,9
	end

	-- summit blinds effect
	if level_index()==31 and objects != nil and objects[2] != nil and objects[2].type==player then
		local diff=min(24,40-abs(objects[2].x-60))
		rectfill(0,0,diff,127,0)
		rectfill(127-diff,0,127,127,0)
	end

	-- move cursor
	ms_x=appr(ms_x,mx,15)
	ms_y=appr(ms_y,my,15)
	
	if (not is_aiming and hit_effect == 0) then
		spr(73,ms_x,ms_y)
	end

	if finished then
		--draw_scorecard()
	end

	if level_index()==1 then
		?"cLICK+dRAG TO aIM,rELEASE TO hIT", 0, 122, 6
		?"🅾️ TO rESTART", 76, 116, 6
	end
end

function draw_scorecard()
	-- horizontal card, shows time on top
	rectfill(8, 8, 107, 64, 15)
	draw_time(43,2)
	?"deaths:"..deaths,48,10,7
	-- level: 100-1500			total
	-- par: pars[100-1500]  	  x
	-- stroke: strokes[100-1500]  x
	-- level: 1600-30000		total
	-- par: pars[1600-30000]	  x
	-- stroke: strokes[1600-30000]x
	-- score: score
end

function draw_object(obj)
	(obj.type.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj)
	spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
end

function draw_time(x,y,c)
	c = c or 7
	rectfill(x,y,x+32,y+6,0)
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds),x+1,y+1,c
end

function two_digit_str(x)
	return x<10 and "0"..x or x
end

function crectfill(x1,y1,x2,y2,c)
	if x1<128 and x2>0 and y1<128 and y2>0 then
		rectfill(max(0,x1),max(0,y1),min(127,x2),min(127,y2),c)
	end
end

-- [helper functions]

function appr(val,target,amount)
	return val>target and max(val-amount,target) or min(val+amount,target)
end

function sign(v)
	return v~=0 and sgn(v) or 0
end

function maybe()
	return rnd()<0.5
end

function tile_at(x,y)
	return mget(room.x*16+x,room.y*16+y)
end

function spikes_at(x1,y1,x2,y2,xspd,yspd)
	for i=max(0,x1\8),min(15,x2/8) do
		for j=max(0,y1\8),min(15,y2/8) do
			if ({[17]=yspd>=0 and y2%8>=6,
					 [27]=yspd<=0 and y1%8<=2,
					 [43]=xspd<=0 and x1%8<=2,
					 [59]=xspd>=0 and x2%8>=6})[tile_at(i,j)] then
				return true
			end
		end
	end
end

function rspr(sx,sy,x,y,a,w,h) -- by gabe_8_bit
	sw=(w or 1)*8
	sh=(h or 1)*8
	x0=flr(0.5*sw)
	y0=flr(0.5*sh)
	sa=sin(a)
	ca=cos(a)
	for ix=sw*-1,sw+4 do
		for iy=sh*-1,sh+4 do
			dx=ix-x0
			dy=iy-y0
			xx=flr(dx*ca-dy*sa+x0)
			yy=flr(dx*sa+dy*ca+y0)
			if (xx>=0 and xx<sw and yy>=0 and yy<=sh-1) then
				local col = sget(sx+xx,sy+yy)
				if col != 0 then
					pset(x+ix,y+iy,col)
				end
			end
		end
	end
end

__gfx__
000000000011110000111100006666000011110010111101000000000000000000aaaaa0000aaa000000a00000077077700777006ddd6ddd6ddd6ddd6ddd6ddd
000000000111111001111160067777600611111011171711000000000000000000a000a0000a0a000000a0000777777677777770666666666666666666666666
000000001171171111711776117777116771171111119911000000000000000000a909a0000a0a000000a0007766666667767777600000660000000066000006
0000000011199111111917761111111167719111011777100000000000000000009aaa900009a9000000a0007677766676666677600066550000000055660006
00000000111111111119177611199111677191110117771000000000000000000000a0000000a0000000a0000000000000000000606655000000000000556606
00000000117777111171177611711711677117110117771000000000000000000099a0000009a0000000a0000000000000000000665500000000000000005566
00000000067777600111116001111110061111100117771000000000000000000009a0000000a0000000a0000000000000000000550000000000000000000055
00000000006666000011110000111100001111001199d990000000000000000000aaa0000009a0000000a0000000000000000000000000000000000000000000
555555550000000000000000000000000000000000000000008888004999999449999994499909940300b0b0666566650300b0b0000000000000000070000000
55555555000000000000000000000000000000000000000008888880911111199111411991140919003b330067656765003b3300007700000770070007000007
550000550000000000000000000000000aaaaaa00000000008788880911111199111911949400419028888206770677002888820007770700777000000000000
55000055007000700499994000000000a998888a1111111108888880911111199494041900000044089888800700070078988887077777700770000000000000
55000055007000700050050000000000a988888a1000000108888880911111199114094994000000088889800700070078888987077777700000700000000000
55000055067706770005500000000000aaaaaaaa1111111108888880911111199111911991400499088988800000000008898880077777700000077000000000
55555555567656760050050000000000a980088a1444444100888800911111199114111991404119028888200000000002888820070777000007077007000070
55555555566656660005500004999940a988888a1444444100000000499999944999999444004994002882000000000000288200000000007000000000000000
5777777557777777777777777777777577cccccccccccccccccccc77577777755555555555555555555555555500000007777770000000000000000000000000
77777777777777777777777777777777777cccccccccccccccccc777777777775555555555555550055555556670000077777777000777770000000000000000
777c77777777ccccc777777ccccc7777777cccccccccccccccccc777777777775555555555555500005555556777700077777777007766700000000000000000
77cccc77777cccccccc77cccccccc7777777cccccccccccccccc7777777cc7775555555555555000000555556660000077773377076777000000000000000000
77cccc7777cccccccccccccccccccc777777cccccccccccccccc777777cccc775555555555550000000055555500000077773377077660000777770000000000
777cc77777cc77ccccccccccccc7cc77777cccccccccccccccccc77777cccc775555555555500000000005556670000073773337077770000777767007700000
7777777777cc77cccccccccccccccc77777cccccccccccccccccc77777c7cc77555555555500000000000055677770007333bb37000000000000007700777770
5777777577cccccccccccccccccccc7777cccccccccccccccccccc7777cccc77555555555000000000000005666000000333bb30000000000000000000077777
77cccc7777cccccccccccccccccccc77577777777777777777777775777ccc775555555550000000000000050000066603333330000000000000000000000000
777ccc7777cccccccccccccccccccc77777777777777777777777777777cc7775055555555000000000000550007777603b333300000000000ee0ee000000000
777ccc7777cc7cccccccccccc77ccc777777ccc7777777777ccc7777777cc77755550055555000000000055500000766033333300000000000eeeee000000030
77ccc77777ccccccccccccccc77ccc77777ccccc7c7777ccccccc77777ccc777555500555555000000005555000000550333b33000000000000e8e00000000b0
77ccc777777cccccccc77cccccccc777777ccccccc7777c7ccccc77777cccc7755555555555550000005555500000666003333000000b00000eeeee000000b30
777cc7777777ccccc777777ccccc77777777ccc7777777777ccc777777cccc775505555555555500005555550007777600044000000b000000ee3ee003000b00
777cc777777777777777777777777777777777777777777777777777777cc7775555555555555550055555550000076600044000030b00300000b00000b0b300
77cccc77577777777777777777777775577777777777777777777775577777755555555555555555555555550000005500999900030330300000b00000303300
5777755700000000077777777777777777777770077777700000000000000000cccccccc00100000011111001111110011111100110000010011110011111100
7777777700ee0000700007770000777000007777700077770000000000000000c77ccccc01710000111111101111111011111110110000141011111011111110
7777cc770eee000070cc777cccc777ccccc7770770c777070000000000000000c77cc7cc01771000110001101100011011000000110000141001100011000000
777ccccceeeeeeee70c777cccc777ccccc777c0770777c070000000000000000cccccccc01777100999999909900099099990000990001410009900099990000
77cccccceeeeeeee707770000777000007770007777700070002eeeeeeee2000cccccccc01777710777777707700077077000000770001410007700077000000
57cc77cc2eee222277770000777000007770000777700007002eeeeeeeeee200cc7ccccc01777100770007707777777077777700777715100077770077777700
577c77cc02ee00007000000000000000000c000770000c0700eeeeeeeeeeee00ccccc7cc01711710660006606666660066666660666615100066666066666660
777ccccc002200007000000000000000000000077000000700e22222e2e22e00cccccccc00100110000000000000000000000000000151000000000000000000
777ccccc000ee0007000000000000000000000077000000700eeeeeeeeeeee000000000000000000000000000000000000000000000151000000000000000000
577ccccc000ee0007000000c000000000000000770cc000700e22e2222e22e000000000000000000000000000000000001111000001510000000000000000000
57cc7ccc000ee00070000000000cc0000000000770cc000700eeeeeeeeeeee000000000000000000000000001111100011111100001510000111111000000000
77cccccc0eeeeee070c00000000cc00000000c0770000c0700eee222e22eee000000000000000000000000011111110117117110015100000111111100000000
777ccccc0eeeeee07000000000000000000000077000000700eeeeeeeeeeee005555555500000000000000011000110111991110015111000110000000000000
7777cc7702eeee2070000000000000000000000770c0000700eeeeeeeeeeee0055555555000000000000000990000001111111101d6677100999900000000000
77777777002ee20070000000c0000000000000077000000700ee77eee7777e00555555550000000000000007700777011777711015d666610770000000000000
57777577000220007000000000000000000000077000c00707777777777777705555555500000000000000077770770067777600015555510770000000000000
00000000000000007000000000000000000000077000000700000042500000000000000500001111000000006666660006666000001111100660000000000000
00aaaaaa0000ee00700000000000000000000007700c000700000040550000000000005500001441000000000101010100010101010000000000000000000000
0a9999990000eee0700000000000c000000000077000000700000420555000000000055500001441000000001a1a1a1a111a1a1a1a1000000000000000000000
a99aaaaaeeeeeeee7000000cc0000000000000077000cc0700000400555500000000555500001441000000001c1c1c1c1a1c1c1c1c1000000000000000000000
a9aaaaaaeeeeeeee7000000cc0000000000c00077000cc070000040055555555555555550000144100000000191919191c191919191000000000000000000000
a99999992222eee270c00000000000000000000770c0000700004200555555555555555500001551000000001919191919191919191000000000000000000000
a99999990000ee207000000000000000000000077000000700004000555555555555555500001551000000001919191919191919191000000000000000000000
a9999999000022000777777777777777777777700777777000004000555555555555555500001551000000001919191919191919191000000000000000000000
aaaaaaaa000ee0000777777777777777777777700777777000488800004800000040088800001551000000001919191919191919191000000000000000000000
a49494a100eeee007000777000007770000077777000777700488888004880000048888800001551000000000199191919191919910000000000000000000000
a494a4a10eeeeee070c777ccccc777ccccc7770770c7770704200888042888880428880000001551100000000011999919199991100000000000000000000000
a49444aa0eeeeee070777ccccc777ccccc777c0770777c0704000000040088800400000000001555111110000000111999991110000000000000000000000000
a49999aa022ee2207777000007770000077700077777000704000000040000000400000000001dd6667711000000000199910000000000000000000000000000
a4944499002ee20077700000777000007770000777700c07420000004200000042000000000011dd666671000000000199910000000000000000000000000000
a494a444000ee000700000000000000000000007700000074000000040000000400000000000011dd66661000000001999991000000000000000000000000000
a4949999000220000777777777777777777777700777777040000000400000004000000000000011111111000000000111110000000000000000000000000000
00000000000000008242525252528452339200001323232352232323232352230000000000000000b302000013232352526200a2828342525223232323232323
00000000000000a20182920013232352363636462535353545550000005525355284525262b20000000000004252525262828282425284525252845252525252
00000000000085868242845252525252b1006100b1b1b1b103b1b1b1b1b103b100000000000000111102000000a282425233000000a213233300009200008392
000000000000110000a2000000a28213000000002636363646550000005525355252528462b2a300000000004252845262828382132323232323232352528452
000000000000a201821323525284525200000000000000007300000000007300000000000000b343536300410000011362b2000000000000000000000000a200
0000000000b302b2002100000000a282000000000000000000560000005526365252522333b28292001111024252525262019200829200000000a28213525252
0000000000000000a2828242525252840000000000000000b10000000000b1000000000000000000b3435363000000b162273737373737373737374711000000
000000110000b100b302b20000006182000000000000000000000000005600005252338282828201a31222225252525262820000a20011111100008283425252
0000000000000093a38282425252525200006100001100000000001100000000110000000000000000000002d0e0e0e003222222222222222222222232b20000
0000b302b200000000b10000000000a200000000000000009300000000000000846282828283828282132323528452526292000000112434440000a282425284
00000000000000a2828382428452525200000000b302b2936100b302b20061007293a30000000000000000b1a393111103845252525252232323232362b20000
000000b10000001100000000000000000000000093000086820000a3000000005262828201a200a282829200132323236211111111243535450000b312525252
00000000000000008282821323232323820000a300b1a382930000b100000000738283931100000000000011a282122223232323528462829200a20173b20000
000000000000b302b2000061000000000000a385828286828282828293000000526283829200000000a20000000000b05222222232263636460000b342525252
00000011111111a3828201b1b1b1b1b182938282930082820000000000000000b100a282721100000000b3722121132322222232132333610071869200000000
00100000000000b1000000000000000086938282828201920000a20182a37686526282829300000000000000000000005252845252328283920000b342845252
00008612222232828382829300000000828282828283829200000000000061001100a382136300000000b373d0e0b1b1035284628382a2000071a20000000000
00021111111111111111111111110061828282a28382820000000000828282825262829200000000000000000000000052525252526201a2000000b342525252
00000113235252225353536300000000828300a28282820193930000110000007282829200000000000000b1000011110323526292000000000000a300000000
0043535353535353535353535363b2008282920082829200060000a3828382a28462000000000000000000000000000052845252526292000011111142525252
0000a28282132362b1b1b1b1000000009200000000a28282828293b372b2000073820100000000a3000000110000122262101333610000000000008293000000
0002828382828202828282828272b20083820000a282d3000000f38282920000526200000000000093b00000000000005252525284620000b312223213528452
000000828392b30300000000002100000000000000000082828282b303b20000b1a2821222328201930000722121132362710000000000000000008382000000
00b1a282820182b1a28283a28273b200828293000082122232122232820000a3233300000000000082920000000000002323232323330000b342525232135252
000000a28200b37300000000a37200000010000000111111118283b373b200a3000082428462920082830073d0e0e0e00361000000000000a300008282920000
0000009261a28200008261008282000001920000000213233342846282243434000000000000000082000085860000008382829200000000b342528452321323
0000100082000082000000a2820300002222321111125353630182829200008300e0f04252620000a28200000000000003000000000000a38292008282000000
00858600008282a3828293008292610082001000001222222252525232253535000000f3100000a3820000a2010000008292616161009300b342525252522222
0400122232b200839321008683039300528452222262c000a28282820000a3821000004284620080008293000021122262710000000000828300a38201000000
00a282828292a2828283828282000000343434344442528452525252622535350000001263000083829300008200c1008210d3e300a38200b342525252845252
1232425262b28682827282820103820052525252846200000082829200008282320000132333717171a282717112232362839300000000828200828282930000
0000008382000000a28201820000000035353535454252525252528462253535000000032444008282820000829300002222223201828393b342525252525252
525252525262b171b1b113232352620084522323232323235252232323338282525252525252525252528452233301822323232323526282820071b342525252
52845252525252848452525262838242528452522333717171425223232352520000000000000000000000000000000000000000000000000000000000000000
52525284526200000000b1b1b142620023338276000000b3423392a282018283525252845252232323232362b1b1a283921000a382426283920000b342232323
23232323232323232323235262018213525223339300018241133383828242840000000000000000000000000000000000100000000000000000000000000000
525252525262000000000000a242627682828392000000b3730000a38282920052525252523382830000b103000000825353638382426282410000b30382a2a2
a1829200a2828382820182426200a2835262a2839200831232b2000080014252000000000000a300000000000000000000000000001600000000000000000000
528452232333d0e0e0001100824262928201a20000000000b100000083920000232352526200a2829300b3030000a382828283828242522232b200b373928000
000100110092a2829211a2133300a382526293000000a21333b20000868242520000000000000100009300000000000000000000001700000000000000000000
5252621222320000a3767200a24262838292000000000000000000a3827200002232132333d0e0a292000003829300a2838292019242845262b2000000000000
e0e0f002b2a36182b302b200110000a25262920000000000000000a283a2425200000000a3008200008300000000000000000000000000000000000000000000
5252624284620000a283030000426292830000006100720000000000a203e3415252222232a393000000000392000061829200717142525262b2000000000000
000000b100a2828200b100b302d0e0e05262d0e0e0e0000000000000920042840000000082768200000100930000000000000000000000000000000000000000
2323331323620021008203000013330082938586930003111111111111422222525284526201920011000003b2000000820011111142528462b2000000006100
000000000000000176851100b10000008462111111110000006100e0e0f013520000000082838200008276820000000000000000000000000000000000000000
82000000a2031172d0a2030000010193d0e0f043535323535353535353525284525252526292000072000003b2000000820043535323235262b2000011000000
0000000000b30282828372b261000000525232122232b200000000000000b14200000000a2827293a37283920000000000000000000000000000000000000000
92000000001353620000135353535353859270000001828282829200b34252522323232362b2610003000003000000009200b1b1b1b1b34262b200b37293a393
00110000000000a2828273b20000000023233313233300000011110000000042000000868382036782038293a300000000000000000000000000000000000000
e0f072b200a2830300000071a2829300920000000061a2828382827612525252b1b1b1b173b200000393000361000000000000000000b34262b271b303828392
0002b211000000000092b10000000021b1b1b1b1b10000001112321100000042000000a282125222225232828386000000000000000000000000000000000000
80b303b200008203210011110082830011211111110000829200928242528452000000a3820000000382937300000000000000000000b3426211111103016100
00b1b302b2e0f072b200000000435363b21000000000001222522363000000138585868292425252525262018282860000000000000000000000000000000000
93b373b20000a21353535363d0e0e0e02222222232000000000000a21323525200000001839200b3038282820000000000717100930011425222222233920000
100000b10000b303b200000000858693b27171717171b3425233b1b1000000b182018283001323525284629200a2820000000000000000000000000000000000
9200b100000000b1b1b1b1b100000000232323232353536300006100b1b1135200000000820000b30382839200007171111111118283432323232333d0e0e000
329300000000b373d0e0e0e000a20182111111110000b31333b100a36100000000a28293f3123242522333020000820000000000000000000000000000000000
210000001000410000000000000000009310000000a28200000000000000824200000086827621b30300a282760000002222223200828200a30182a2006100a3
62820000000000b100000093a382838222222232b261000000000083000000860000122222526213331222328293827600000000000000000000000000000000
717185a31222321111111111002100002232d300000182930000000080a301131000a383829271b373d0e083920000005284526200a282828283920000000082
62839321000000000000a3828282820152845262b200000093000082210000821000135252845222225252523201838200000000000000000000000000000000
9300a28242525222222222320071000052523293a382838200435363717171823200018282000000830000820100000052525262717182838200000071717182
628201729300000000a282828382828252528462b27100a38300a382717183821222324252525252525284525222223200000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000f000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000f00000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000
00000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000070000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000f00000000000060600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000d000600000000000000660000000000000000000000000000000f0000000000000
0000000000000000000000000000000000000000000000000000000000000d00000c00f000000000066000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000d000000c000000000000000000000000000000000000000000000000060000000000
00000000000000000000000000000000000000000000000000000000000c0000000c000600000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000d000000000c060d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c00000000000d000d000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006666600666666006600c00066666600066666006666660066666600000000000000000000000000000000000000
0000000000000000000000000000000000006666666066666660660c000066666660666666606666666066666660000000000000000000000000000000000000
00000000000000000000000000000000000066000660660000006600000066000000660000000066000066000000000000000000000000000000000000000000
000000000000000000000000000000000000dd000000dddd0000dd000000dddd0000ddddddd000dd0000dddd0000000000000000000000000000000000000000
000000000000000000000000000000000000dd000dd0dd000000dd0000d0dd000000000000d000dd0000dd000000000000000000000000000000000000000000
000000000000000000000000000000000000ddddddd0dddddd00ddddddd0dddddd00ddddddd000dd0000dddddd00000000000000000000000000000000000000
0000000000000000000000000000000000000ddddd00ddddddd0ddddddd0ddddddd00ddddd0000dd0000ddddddd000000f000000000000000f00000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000c000000000000000000000000000000c00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c00000000000000000000000000000000c0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000cc0000000000000000000000000000000000c000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000c000000000000000000000000000000000000c000000000000000000000000000000000000000000000
0000000000000000000000000000f0f0f0f0f0f0f0f0c0f00000000000000000000000000000000000c000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000100000000000000000000000000000000000000c00c000000000000000000000000000000000000000000
000000000000000000000000000000000000000000c0000000000000000000000000000000000000001010c0f000000000000000000000000000000000000000
000000000000000000000000000000000000000001000000000000000000000000000000000000000001000c00000000000000000000000000000000f0f0f0f0
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000600000000000000000000000000000000
000000000000000000000000000000000000000001000000000000000000000000000000000000000000000010000000000000f000f000f000f000f000f00000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000f0000000f00000000000f00000000000f0f0f000f00000000000f0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000f0f00000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000f000f0000000f000f000f000f000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000f000f000f000f0000000f000f0000000000000000000000000
00f000f000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005050000005500000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005050050050006000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000500555050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005050050050000000000000600000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005050000005500000000000f00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000
000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000f0000000000000000000000000f0000000000000000000000000000000000000000000f00000000000000000000
0000000000f000000000f000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000
0000000000000000f000f000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000f000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000700000000006600f0000000000000000000000000000f0000000000000000000f000f00
000000000000f000000000000000000f000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000f00000000000000000000000f00000f0000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000f000f00000000000000000000000000000000
f0000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055505550555055500000555050500550555005500550550000000000000000000000000000000000000000
0000000000000000000000000f000000000000000055505050f500050000000500505050505050500050505050000000000000f0000000000000000000000000
00000000000000000000000000000000000000000050505550050005000000050055505050550055505050505000000000000000000000000000000000000000
000000000f00000000000000000000000000f0000050505050050005000000050050505050505000505050505000000000000000000000000000000000000000
000000000000000000000000000000000000000000505050500500050000000500505055005050550055005050000000f0000000000000000000000000000000
f000000000000000000000000000000000000000f00000000000000000000f0000000000000000000000000000000000000000000000000000000f0000000000
0000000000000000000000000000000000000000000060550f0550555050f0000055505550555055505050000000000000000000000000000000000000000000
000f000f000000000000000000000000000000000000005050505f50005000000050505000505050505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
000f0000000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000050505500555055500000555055505050505055500000000f0000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000f00000000000000000000000f0000000000000000000000000000000000000f0000000000000
000000000000000000000000000000f000000000f0000000000000f0f0f0f000f0f0f0f0f000000000000000000000000000000000000000000000000000000f
000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000f00000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000
00000000000600000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000600000000000000000000000000000000000000000
0000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000f0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000f00000000f000000000000000000000
0000000000000000000f00000f0000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000f00000
0000000000f0000f0000000000000000000000000000000000000f00000000000f000000f0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000f0000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000f000000000000000f0000000000000f0000000000000000000000000000000000000000000
000000000000000000000000000000f00000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000f00000000000000f00000000000000000000000000000000000000000000000f0f00000000000
0000000000000000000000000000000000000000f000f00f0f00f000000000000000000000000000000000000000000000000000000000000000000000000000
00000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
000000000000000000000000000a0a0a04020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202020200021313131302020300000000000000000213131313020204130202020002020002131313130004040000000002020000021313131300000000000000020000
0002131313131313131302020202020202021313131313131313020202020202020213131313131313130202020202020202131313131313131302020202020202020000000000000000020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2331252548252532323232323300002425262425252631323232252628282824252525252525323328382828312525253232323233000000313232323232323232330000002432323233313232322525252525482525252525252526282824252548252525262828282824254825252526282828283132323225482525252525
252331323232332900002829000000242526313232332828002824262a102824254825252526002a2828292810244825282828290000000028282900000000002810000000372829000000002a2831482525252525482525323232332828242525254825323338282a283132252548252628382828282a2a2831323232322525
252523201028380000002a0000003d24252523201028292900282426003a382425252548253300002900002a0031252528382900003a676838280000000000003828393e003a2800000000000028002425253232323232332122222328282425252532332828282900002a283132252526282828282900002a28282838282448
3232332828282900000000003f0020244825262828290000002a243300002a2425322525260000000000000000003125290000000021222310290000000000002a28283435360d0e00000000002839242526212223202123313232332828242548262b000000000000001c00003b242526282828000000000028282828282425
2340283828293a2839000e0f343522252548262900000000000030000000002433003125333d3f00000000000000003100001c3a3a3125260d0e0e00000000000010282828290000000011113a2828313233242526103133202828282838242525262b000000000000000000003b2425262a2828670016002a28283828282425
263a282828102829000000000000312525323300000000110000370000003e24000000372122230d0e00000000000000395868282828242639000000000000002a2828290000000000002123283828292828313233282829002a002a2828242525332b0c00000011110000000c3b314826112810000000006828282828282425
252235353628280000000000003a282426003d003a39002700000000000f2125001a000024252611111111000000002c28382828283831332800000000000000002a000000001111000024261028290028281b1b1b282800000000002a2125482628390000003b34362b000000002824252328283a67003a28282829002a3132
253338282829000000000000002838242523202010293a3039000000005824480000003a31323235353536675800003c282828281028212329000000000000000000000e0e0f3436003a2426282900003828390000002a29000000000031323226101000000000282839000000002a2425332828283800282828390000001700
2600002a28000000003a283a2828282425252223290038372858390068283132000000282828282820202828283921222829002a282824260000000000000000000000000000203828283125230d0e0e282828290000000000163a67682828003338280b00000010382800000b00003133282828282868282828280016001700
330000002867580000281028283422252525482600002a20282828382828212200003a283828102900002a28382824252a000000283824260d0e0000000000000000000000002728282a283133390000282900000000000000002a28282829002a2839000000002a282900000000000028282838282828282828290000000000
0000003a2828383e3a28282838282448482525260d0e0f2729002a290f3432250000002a282828000000000e0e0f2425000000002a282426000000000000000000000000000037280000002a28283900280000003928390000000000282800000028290000002a2828000000000000002a282828281028282828675800000000
0000002838282821230d0e002a28242532322526003a3930000000003a28282400000000002a28111111113a103924480000003a28283133000000000000000000013f0000002029000000003828000028013a28281028580000003a28290000002a280c0000003a380c00000000000c00002a2828282828292828290000003a
00013a2123282a313300001111112425002831333a3829300d0e0e002a292a31000100000000283422223628283824253e013a3828292a00000000000000000035353536000020000000003d2a28671422222328282828283900582838283d00003a290000000028280000000000000000002a28282a2900002a100012002a28
22222225262900212311112122222525002a3810282900301111110000003a2800273f0000002a2824262900002a2425222222232900000000001717170000002a282039003a2000003a003435353535252525222222232828282810282821220b10010000000b28100000000b0000002c000028380000000017171717170028
2548252526111124252222252525252500012a2829123f242222230000003828222523000012002a2426000000122425252525260000001717170000000000000038202839282708002a676820282828254825252525262a28282122222225253a28203d0000006828390000000000003c0168282800171717003a3900003a28
25252525252222252525252525252525222222222222222525482667586828282548260000270000242617171721252525254826171717000000000000000000002a20281028301717172a28202828282525252548252600002a2425252548252821222300000028282800000000000022222223286700000000282839002838
2532330000002432323232323232252525252628282828242532323232254825253232323232323225262828282448252525253300000000000000000000005225253232323233313232323233282900262829286700000000002828313232322525253233282800312525482525254825254826283828313232323232322548
26282800000030402a282828282824252548262838282831333828290031322526280000163a28283133282838242525482526000000000000000000000000522526000016000000002a10282838390026281a3820393d000000002a3828282825252628282829003b2425323232323232323233282828282828102828203125
3328390000003700002a3828002a2425252526282828282028292a0000002a313328111111282828000028002a312525252526000000000000000000000000522526000000001111000000292a28290026283a2820102011111121222328281025252628382800003b242600002a2a38282828282829002a2800282838282831
28281029000000000000282839002448252526282900282067000000000000003810212223283829003a1029002a24253232336700000000000000000000420025260d0e0e0f212300000000002122222522222321222321222324482628282932323328282800003b31330000000028102829000000000029002a2828282900
2828280016000000162a282828002425252526272b002a2029000000000000002834252533292a0000002a00111124252223282800002c46472c00000000525325262800003a2426000016000024252525254826313233313233242526200d0e22222328292a67000028290000000000283800111112121200000028292a1600
283828000000000000003a2829002425482526372b000029000000000000003a293b24262839000000000000212225252526382867003c56573c0000000052533233283900282426111111111124252525482526201b1b1b1b1b2425262839002525260000002a143a290000000000000e0e0f21231717170000112867000000
282828675800000010390e0e0e0f31323232332039000000000000003a272828003b24262900000000000000312548252533282828392122222300000000625329002a290e0f31323535353522254825252525252300000000003132332810394825261134353535361111112700000000003b3133111111111127282900003b
2828282810290000002a28286700002835353536283900000000000010302838003b313300000000000e0e0e0f313225262a282810282425252600000e0e0f5200160010382829000000000031322525252525252667580000002000002a2828252532353535222222222235330d0e0e00003b34353535353536303800000017
282900002a0000000000382a29003a282828283436200d0e00000e0f20302a2900002a2900001100000000003a282831260029002a282448252523000000005239003a282900000000000000002831322525482526382900000000000058682832331028293b2448252526282839000000003b201b1b1b1b1b1b302800000017
283a0000000000000000280000002828283810292a000000000000002a300000111111111111270000000b002a2838002600000000212525252526001c0000622828281000000000000000002a38282925252525262800000000000e0e0f212228282908003b242525482628282900000000001b00000000000030290000003b
3829000000000000003a10290000283828282800000000000000000000370d0e223535353535330000000000002828393300000e0f313225252533000000000028382829000e0e0e0f34233a682828003232323233290000000000000000312528280000003b3132322526382800000000000000000000110000370000000000
290000000000000000002a000000282928292a00000000000000000000003a393328382828290b0000000000001028280000000042434424252628390000000028002a0000110000001b31353610292c1b1b1b1b0000000000000000000010312829160000001b1b1b313328106712000000001100003a2700001b0000000000
00000100000011111100000000002a3a2a0000000000000000000000002a1028282829002a000000000000000028282800000000525354244826282800000000290000003b202b39000000002900003c0000000000000000000000000000282828000000000000000000002a2829170001000027390038300000000000000000
1111343611112122230000001212002a00010000000000000000000000002a28290000000000000000002a6768282900003f01005253542425262810673a390001000000002a38290000000000000f2101000000000000003a67120000002a382867586800000100000000002800000021230037282928300000000000000000
22222222222324482611111134353536002739000000000000171717171700380001000000001717170000282838393a0021222352535424253328282838290022232b00000828393b270d0e00001424230000001200000028291700000000282828171717171717171717172839000031333927101228370000000000000000
254825252526242526212222222222223a303800000000000000000000000000001717170000000000003a28282828280024252652535424262828282828283925262b00171717103b30000000212225260000002700003a28001700000000282838282828390000005868283828000022233830281728270000000000000000
__sfx__
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000862008620086200c620166402d65028650276500f650145500e550095500855006550035700057000570005700b4000a400094000740006400054000740006400084000440004400044000440000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300001177011770127601375013740117300e7200d715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
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

