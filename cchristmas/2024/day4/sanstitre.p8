pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--
-- mod of celeste by kdx
-- maddy thorson + noel berry

--pst
--hey runners
--press p2 right to skip intro
--you are welcome

-- globals --
-------------

playerbody=6
room = { x=0, y=0 }
objects = {}
types = {}
freeze=0
shake=0
will_restart=false
delay_restart=0
got_fruit={}
has_dashed=false
sfx_timer=0
has_key=false
pause_player=false
flash_bg=false
music_timer=0
screenshake=false
lastroom=3
over=false

k_left=0
k_right=1
k_up=2
k_down=3
k_jump=4
k_dash=5

-- entry point --
-----------------

function _init()
	menuitem_screenshake()
	title_screen()
end

function title_screen()
	got_fruit = {}
	for i=0,29 do
		add(got_fruit,false) end
	frames=0
	seconds=0
	deaths=0
	max_djump=1
	start_game=false
	start_game_flash=0
	--music(40,0,7)
	
	load_room(7,3)
end

function begin_game()
	frames=0
	seconds=0
	minutes=0
	music_timer=0
	start_game=false
	--music(0,0,7)
	load_room(0,0)
end

function level_index()
	return room.x%8+room.y*8
end

function is_title()
	return level_index()==31
end

-- effects --
-------------

clouds = {}
--[[for i=0,16 do
	add(clouds,{
		x=rnd(128),
		y=rnd(128),
		spd=1+rnd(4),
		w=32+rnd(32)
	})
end]]

particles = {}
for i=0,24 do
	add(particles,{
		x=rnd(128),
		y=rnd(128),
		s=0+flr(rnd(5)/4),
		spd=0.25+rnd(5),
		off=rnd(1),
		c=6+flr(0.5+rnd(1))
	})
end

dead_particles = {}

-- player entity --
-------------------

player = 
{
	init=function(this) 
		this.p_jump=false
		this.p_dash=false
		this.grace=0
		this.jbuffer=0
		this.djump=max_djump
		this.wjump=1
		this.dash_time=0
		this.dash_effect_time=0
		this.dash_target={x=0,y=0}
		this.dash_accel={x=0,y=0}
		this.hitbox = {x=1,y=3,w=6,h=5}
		this.spr_off=0
		this.was_on_ground=false
		create_hair(this)
	end,
	update=function(this)
		if (pause_player) return
		
		local input = btn(k_right) and 1 or (btn(k_left) and -1 or 0)
		
		-- spikes collide
		if spikes_at(this.x+this.hitbox.x,this.y+this.hitbox.y,this.hitbox.w,this.hitbox.h,this.spd.x,this.spd.y) then
			kill_player(this) end
			
		-- bottom death
		if this.y>128 then
			kill_player(this) end

		local on_ground=this.is_solid(0,1)
		local on_ice=this.is_ice(0,1)
		
		-- smoke particles
		if on_ground and not this.was_on_ground then
			init_object(smoke,this.x,this.y+4)
		end

		local jump = btn(k_jump) and not this.p_jump
		this.p_jump = btn(k_jump)
		if (jump) then
			this.jbuffer=4
		elseif this.jbuffer>0 then
			this.jbuffer-=1
		end
		
		local dash = btn(k_dash) and not this.p_dash
		this.p_dash = btn(k_dash)
		
		if on_ground then
			this.grace=6
			if this.djump<max_djump or this.wjump<1 then
				psfx(54)
			end
			this.djump=max_djump
			this.wjump=1
		elseif this.grace > 0 then
			this.grace-=1
		end

		this.dash_effect_time -=1
		if this.dash_time > 0 then
			init_object(smoke,this.x,this.y)
			this.dash_time-=1
			this.spd.x=appr(this.spd.x,this.dash_target.x,this.dash_accel.x)
			this.spd.y=appr(this.spd.y,this.dash_target.y,this.dash_accel.y)  
		else

			-- move
			local maxrun=1
			local accel=0.6
			local deccel=0.15
			
			if not on_ground then
				accel=0.4
			elseif on_ice then
				accel=0.05
				if input==(this.flip.x and -1 or 1) then
					accel=0.05
				end
			end
		
			if abs(this.spd.x) > maxrun then
				this.spd.x=appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)
			else
				this.spd.x=appr(this.spd.x,input*maxrun,accel)
			end
			
			--facing
			if this.spd.x!=0 then
				this.flip.x=(this.spd.x<0)
			end

			-- gravity
			local maxfall=2
			local gravity=0.21

			if abs(this.spd.y) <= 0.15 then
				gravity*=0.5
			end
		
			-- wall slide
			if input!=0 and this.is_solid(input,0) and not this.is_ice(input,0) and this.wjump>0 then
				maxfall=0.4
				if rnd(10)<2 then
					init_object(smoke,this.x+input*6,this.y)
				end
			end

			if not on_ground then
				this.spd.y=appr(this.spd.y,maxfall,gravity)
			end

			-- jump
			if this.jbuffer>0 then
				if this.grace>0 and this.wjump>0 then
					-- normal jump
					psfx(1)
					this.jbuffer=0
					this.grace=0
					this.spd.y=-2
					--this.wjump-=1
					init_object(smoke,this.x,this.y+4)
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
					if wall_dir!=0 and this.wjump>0 then
						this.djump=max_djump
						this.wjump-=1
						psfx(2)
						this.jbuffer=0
						this.spd.y=-2
						this.spd.x=-wall_dir*(maxrun+1)
						if not this.is_ice(wall_dir*3,0) then
							init_object(smoke,this.x+wall_dir*6,this.y)
						end
					end
				end
			end
		
			-- dash
			local d_full=5
			local d_half=d_full*0.70710678118
		
			if this.djump>0 and dash then
				init_object(smoke,this.x,this.y)
				this.djump-=1		
				this.dash_time=4
				has_dashed=true
				this.dash_effect_time=10
				local v_input=(btn(k_up) and -1 or (btn(k_down) and 1 or 0))
				if input!=0 then
					if v_input!=0 then
						this.spd.x=input*d_half
						this.spd.y=v_input*d_half
					else
						this.spd.x=input*d_full
						this.spd.y=0
					end
				elseif v_input!=0 then
					this.spd.x=0
					this.spd.y=v_input*d_full
				else
					this.spd.x=(this.flip.x and -1 or 1)
					this.spd.y=0
				end
				
				psfx(3)
				freeze=0
				shake=6
				this.dash_target.x=2*sign(this.spd.x)
				this.dash_target.y=2*sign(this.spd.y)
				this.dash_accel.x=1.5
				this.dash_accel.y=1.5
				
				if this.spd.y<0 then
					this.dash_target.y*=.75
				end
				
				if this.spd.y!=0 then
					this.dash_accel.x*=0.70710678118
				end
				if this.spd.x!=0 then
					this.dash_accel.y*=0.70710678118
				end				
			elseif dash and this.djump<=0 then
				psfx(9)
				init_object(smoke,this.x,this.y)
			end
		
		end
		
		-- animation
		this.spr_off+=0.25
		if not on_ground then
			if this.is_solid(input,0) then
				this.spr=5
			else
				this.spr=3
			end
		elseif btn(k_down) then
			this.spr=6
		elseif btn(k_up) then
			this.spr=7
		elseif (this.spd.x==0) or (not btn(k_left) and not btn(k_right)) then
			this.spr=1
		else
			this.spr=1+this.spr_off%4
		end
		
		-- next level
		if this.y<-4 and level_index()<30 then next_room() end
		
		-- was on the ground
		this.was_on_ground=on_ground
		
	end, --<end update loop
	
	draw=function(this)
	
		-- clamp in screen
		if this.x<-1 or this.x>121 then 
			this.x=clamp(this.x,-1,121)
			this.spd.x=0
		end
		
		set_hair_color(this.djump)
		draw_hair(this,this.flip.x and -1 or 1)
		pal(6,this.wjump>0 and playerbody or 12)
		spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)		
		unset_hair_color()
	end
}

psfx=function(num)
	if sfx_timer<=0 then
		--sfx(num)
	end
end

create_hair=function(obj)
	obj.hair={}
	for i=0,4 do
		add(obj.hair,{x=obj.x,y=obj.y,size=max(1,min(2,3-i))})
	end
end

set_hair_color=function(djump)
	pal(8,(djump==1 and playerbody or djump==2 and (7+flr((frames/3)%2)*4) or 12--[[12]]))
end

draw_hair=function(obj,facing)
	local last={x=obj.x+4-facing*2,y=obj.y+(btn(k_down) and 4 or 3)}
	foreach(obj.hair,function(h)
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x,h.y,h.size,8)
		last=h
	end)
end

unset_hair_color=function()
	pal(8,8)
end

player_spawn = {
	tile=1,
	init=function(this)
		--sfx(4)
		this.spr=3
		this.target= {x=this.x,y=this.y}
		this.y=128
		this.spd.y=-4
		this.state=0
		this.delay=0
		this.solids=false
		create_hair(this)
	end,
	update=function(this)
		-- jumping up
		if this.state==0 then
			if this.y < this.target.y+16 then
				this.state=1
				this.delay=3
			end
		-- falling
		elseif this.state==1 then
			this.spd.y+=0.5
			if this.spd.y>0 and this.delay>0 then
				this.spd.y=0
				this.delay-=1
			end
			if this.spd.y>0 and this.y > this.target.y then
				this.y=this.target.y
				this.spd = {x=0,y=0}
				this.state=2
				this.delay=5
				shake=5
				init_object(smoke,this.x,this.y+4)
				--sfx(5)
			end
		-- landing
		elseif this.state==2 then
			this.delay-=1
			this.spr=6
			if this.delay<0 then
				destroy_object(this)
				init_object(player,this.x,this.y)
			end
		end
	end,
	draw=function(this)
		set_hair_color(max_djump)
		draw_hair(this,1)
		spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
		unset_hair_color()
	end
}
add(types,player_spawn)

spring = {
	tile=18,
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
			local hit = this.collide(player,0,0)
			if hit ~=nil and hit.spd.y>=0 then
				this.spr=19
				hit.y=this.y-4
				hit.spd.x*=0.2
				hit.spd.y=-3
				hit.djump=max_djump
				this.delay=10
				init_object(smoke,this.x,this.y)
				
				-- breakable below us
				local below=this.collide(fall_floor,0,1)
				if below~=nil then
					break_fall_floor(below)
				end
				
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
			this.hide_in-=1
			if this.hide_in<=0 then
				this.hide_for=60
				this.spr=0
			end
		end
	end
}
add(types,spring)

function break_spring(obj)
	obj.hide_in=15
end

balloon = {
	tile=22,
	init=function(this) 
		this.offset=rnd(1)
		this.start=this.y
		this.timer=0
		this.hitbox={x=-1,y=-1,w=10,h=10}
	end,
	update=function(this) 
		if this.spr==22 then
			this.offset+=0.01
			this.y=this.start+sin(this.offset)*2
			local hit = this.collide(player,0,0)
			if hit~=nil and hit.djump<max_djump then
				psfx(6)
				init_object(smoke,this.x,this.y)
				hit.djump=max_djump
				this.spr=0
				this.timer=60
			end
		elseif this.timer>0 then
			this.timer-=1
		else 
			psfx(7)
			init_object(smoke,this.x,this.y)
			this.spr=22 
		end
	end,
	draw=function(this)
		if this.spr==22 then
			spr(13+(this.offset*8)%3,this.x,this.y+6)
			spr(this.spr,this.x,this.y)
		end
	end
}
add(types,balloon)

fall_floor = {
	tile=23,
	init=function(this)
		this.state=0
		this.solid=true
	end,
	update=function(this)
		-- idling
		if this.state == 0 then
			if this.check(player,0,-1) or this.check(player,-1,0) or this.check(player,1,0) then
				break_fall_floor(this)
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
			if this.delay<=0 and not this.check(player,0,0) then
				psfx(7)
				this.state=0
				this.collideable=true
				init_object(smoke,this.x,this.y)
			end
		end
	end,
	draw=function(this)
		if this.state!=2 then
			if this.state!=1 then
				spr(23,this.x,this.y)
			else
				spr(23+(15-this.delay)/5,this.x,this.y)
			end
		end
	end
}
add(types,fall_floor)

function break_fall_floor(obj)
	if obj.state==0 then
		psfx(15)
		obj.state=1
		obj.delay=15--how long until it falls
		init_object(smoke,obj.x,obj.y)
		local hit=obj.collide(spring,0,-1)
		if hit~=nil then
			break_spring(hit)
		end
	end
end

smoke={
	init=function(this)
		this.spr=29
		this.spd.y=-0.1
		this.spd.x=0.3+rnd(0.2)
		this.x+=-1+rnd(2)
		this.y+=-1+rnd(2)
		this.flip.x=maybe()
		this.flip.y=maybe()
		this.solids=false
	end,
	update=function(this)
		this.spr+=0.2
		if this.spr>=32 then
			destroy_object(this)
		end
	end,
	--draw=function()end
}

fruit={
	tile=26,
	if_not_fruit=true,
	init=function(this) 
		this.start=this.y
		this.off=0
	end,
	update=function(this)
		local hit=this.collide(player,0,0)
		if hit~=nil then
			hit.djump=max_djump
			sfx_timer=20
			--sfx(13)
			got_fruit[1+level_index()] = true
			init_object(lifeup,this.x,this.y)
			destroy_object(this)
		end
		this.off+=1
		this.y=this.start+sin(this.off/40)*2.5
	end
}
add(types,fruit)

fly_fruit={
	tile=28,
	if_not_fruit=true,
	init=function(this) 
		this.start=this.y
		this.fly=false
		this.step=0.5
		this.solids=false
		this.sfx_delay=8
	end,
	update=function(this)
		--fly away
		if this.fly then
			if this.sfx_delay>0 then
				this.sfx_delay-=1
				if this.sfx_delay<=0 then
					sfx_timer=20
					--sfx(14)
				end
			end
			this.spd.y=appr(this.spd.y,-3.5,0.25)
			if this.y<-16 then
				destroy_object(this)
			end
		-- wait
		else
			if has_dashed then
				this.fly=true
			end
			this.step+=0.05
			this.spd.y=sin(this.step)*0.5
		end
		-- collect
		local hit=this.collide(player,0,0)
		if hit~=nil then
			hit.djump=max_djump
			sfx_timer=20
			--sfx(13)
			got_fruit[1+level_index()] = true
			init_object(lifeup,this.x,this.y)
			destroy_object(this)
		end
	end,
	draw=function(this)
		local off=0
		if not this.fly then
			local dir=sin(this.step)
			if dir<0 then
				off=1+max(0,sign(this.y-this.start))
			end
		else
			off=(off+0.25)%3
		end
		spr(45+off,this.x-6,this.y-2,1,1,true,false)
		spr(this.spr,this.x,this.y)
		spr(45+off,this.x+6,this.y-2)
	end
}
add(types,fly_fruit)

lifeup = {
	init=function(this)
		this.spd.y=-0.25
		this.duration=30
		this.x-=2
		this.y-=4
		this.flash=0
		this.solids=false
	end,
	update=function(this)
		this.duration-=1
		if this.duration<= 0 then
			destroy_object(this)
		end
	end,
	draw=function(this)
		this.flash+=0.5

		print("1000",this.x-2,this.y,7+this.flash%2)
	end
}

fake_wall = {
	tile=64,
	if_not_fruit=true,
	update=function(this)
		this.hitbox={x=-1,y=-1,w=18,h=18}
		local hit = this.collide(player,0,0)
		if hit~=nil and hit.dash_effect_time>0 then
			hit.spd.x=-sign(hit.spd.x)*1.5
			hit.spd.y=-1.5
			hit.dash_time=-1
			sfx_timer=20
			--sfx(16)
			destroy_object(this)
			init_object(smoke,this.x,this.y)
			init_object(smoke,this.x+8,this.y)
			init_object(smoke,this.x,this.y+8)
			init_object(smoke,this.x+8,this.y+8)
			init_object(fruit,this.x+4,this.y+4)
		end
		this.hitbox={x=0,y=0,w=16,h=16}
	end,
	draw=function(this)
		spr(64,this.x,this.y)
		spr(65,this.x+8,this.y)
		spr(80,this.x,this.y+8)
		spr(81,this.x+8,this.y+8)
	end
}
add(types,fake_wall)

key={
	tile=8,
	if_not_fruit=true,
	update=function(this)
		local was=flr(this.spr)
		this.spr=9+(sin(frames/30)+0.5)*1
		local is=flr(this.spr)
		if is==10 and is!=was then
			this.flip.x=not this.flip.x
		end
		if this.check(player,0,0) then
			--sfx(23)
			sfx_timer=10
			destroy_object(this)
			has_key=true
		end
	end
}
add(types,key)

chest={
	tile=20,
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
				sfx_timer=20
				--sfx(16)
				init_object(fruit,this.x,this.y-4)
				destroy_object(this)
			end
		end
	end
}
add(types,chest)

platform={
	init=function(this)
		this.x-=4
		this.solids=false
		this.hitbox.w=16
		this.last=this.x
	end,
	update=function(this)
		this.spd.x=this.dir*0.65
		if this.x<-16 then this.x=128
		elseif this.x>128 then this.x=-16 end
		if not this.check(player,0,0) then
			local hit=this.collide(player,0,-1)
			if hit~=nil then
				hit.move_x(this.x-this.last,1)
			end
		end
		this.last=this.x
	end,
	draw=function(this)
		spr(11,this.x,this.y-1)
		spr(12,this.x+8,this.y-1)
	end
}

message={
	tile=86,
	last=0,
	draw=function(this)
		this.text="-- celeste mountain --#this memorial to those# perished on the climb"
		if this.check(player,4,0) then
			if this.index<#this.text then
				this.index+=0.5
				if this.index>=this.last+1 then
					this.last+=1
					--sfx(35)
				end
			end
			this.off={x=8,y=96}
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
	end
}
add(types,message)

big_chest={
	tile=96,
	init=function(this)
		this.state=0
		this.hitbox.w=16
	end,
	draw=function(this)
		if this.state==0 then
			local hit=this.collide(player,0,8)
			if hit~=nil and hit.is_solid(0,1) then
				--music(-1,500,7)
				--sfx(37)
				pause_player=true
				hit.spd.x=0
				hit.spd.y=0
				this.state=1
				init_object(smoke,this.x,this.y)
				init_object(smoke,this.x+8,this.y)
				this.timer=60
				this.particles={}
			end
			spr(96,this.x,this.y)
			spr(97,this.x+8,this.y)
		elseif this.state==1 then
			this.timer-=1
			shake=5
			flash_bg=true
			if this.timer<=45 and count(this.particles)<50 then
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
		spr(113,this.x+8,this.y+8)
	end
}
add(types,big_chest)

orb={
	init=function(this)
		this.spd.y=-4
		this.solids=false
		this.particles={}
	end,
	draw=function(this)
		this.spd.y=appr(this.spd.y,0,0.5)
		local hit=this.collide(player,0,0)
		if this.spd.y==0 and hit~=nil then
			music_timer=45
			--sfx(51)
			freeze=10
			shake=10
			destroy_object(this)
			max_djump=2
			hit.djump=2
		end
		
		spr(102,this.x,this.y)
		local off=frames/30
		for i=0,7 do
			circfill(this.x+4+cos(off+i/8)*8,this.y+4+sin(off+i/8)*8,1,7)
		end
	end
}

flag = {
	init=function(this)
		this.timer=0
	end,
	update=function(this)
		this.timer+=1
	end,
	draw=function(this)
		if this.timer<150 then
		elseif this.timer<150+360 then
			draw_time(48,5*8,true,0)
			cprint("deaths:"..deaths,64,6*8,0)
		elseif this.timer<150+360*1.5 then
		elseif this.timer<150+360*2.5 then
			pal(6,0)
			spr(89,5*8,5*8,6,3)
			pal(6)
		elseif btn(1,1) then
			draw_time(48,5*8,true,0)
			cprint("deaths:"..deaths,64,6*8,0)
		end
	end
}

room_title = {
	init=function(this)
		this.delay=5
	end,
	draw=function(this)
		this.delay-=1
		if this.delay<-30 then
			destroy_object(this)
		elseif this.delay<0 then
			draw_time(4,4,nil,8)
		end
	end
}

-- object functions --
-----------------------

function init_object(type,x,y)
	if type.if_not_fruit~=nil and got_fruit[1+level_index()] then
		return
	end
	local obj = {}
	obj.type = type
	obj.collideable=true
	obj.solids=true

	obj.spr = type.tile
	obj.flip = {x=false,y=false}

	obj.x = x
	obj.y = y
	obj.hitbox = { x=0,y=0,w=8,h=8 }

	obj.spd = {x=0,y=0}
	obj.rem = {x=0,y=0}

	obj.is_solid=function(ox,oy)
		if oy>0 and not obj.check(platform,ox,0) and obj.check(platform,ox,oy) then
			return true
		end
		if obj.y+oy>120 and level_index()==lastroom then return true end
		return solid_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h)
			or obj.check(fall_floor,ox,oy)
			or obj.check(fake_wall,ox,oy)
	end
	
	obj.is_ice=function(ox,oy)
		return ice_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h)
	end
	
	obj.collide=function(type,ox,oy)
		local other
		for i=1,count(objects) do
			other=objects[i]
			if other ~=nil and other.type == type and other != obj and other.collideable and
				other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+ox and 
				other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+oy and
				other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+ox and 
				other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+oy then
				return other
			end
		end
		return nil
	end
	
	obj.check=function(type,ox,oy)
		return obj.collide(type,ox,oy) ~=nil
	end
	
	obj.move=function(ox,oy)
		local amount
		-- [x] get move amount
		obj.rem.x += ox
		amount = flr(obj.rem.x + 0.5)
		obj.rem.x -= amount
		obj.move_x(amount,0)
		
		-- [y] get move amount
		obj.rem.y += oy
		amount = flr(obj.rem.y + 0.5)
		obj.rem.y -= amount
		obj.move_y(amount)
	end
	
	obj.move_x=function(amount,start)
		if obj.solids then
			local step = sign(amount)
			for i=start,abs(amount) do
				if not obj.is_solid(step,0) then
					obj.x += step
				else
					obj.spd.x = 0
					obj.rem.x = 0
					break
				end
			end
		else
			obj.x += amount
		end
	end
	
	obj.move_y=function(amount)
		if obj.solids then
			local step = sign(amount)
			for i=0,abs(amount) do
				if not obj.is_solid(0,step) then
					obj.y += step
				else
					obj.spd.y = 0
					obj.rem.y = 0
					break
				end
			end
		else
			obj.y += amount
		end
	end

	add(objects,obj)
	if obj.type.init~=nil then
		obj.type.init(obj)
	end
	return obj
end

function destroy_object(obj)
	del(objects,obj)
end

function kill_player(obj)
	sfx_timer=12
	--sfx(0)
	if level_index()==lastroom then
		over=true
		init_object(flag,0,0) 
	else
		deaths+=1
		shake=10
	end
	destroy_object(obj)
	dead_particles={}
	for dir=0,7 do
		local angle=(dir/8)
		add(dead_particles,{
			x=obj.x+4,
			y=obj.y+4,
			t=10,
			spd={
				x=sin(angle)*3,
				y=cos(angle)*3
			}
		})
	end
	if not over then
		restart_room()
	end
end

-- room functions --
--------------------

function restart_room()
	will_restart=true
	delay_restart=15
end

function next_room()
	if room.x==2 and room.y==1 then
		--music(30,500,7)
	elseif room.x==3 and room.y==1 then
		--music(20,500,7)
	elseif room.x==4 and room.y==2 then
		--music(30,500,7)
	elseif room.x==5 and room.y==3 then
		--music(30,500,7)
	end

	if room.x==7 then
		load_room(0,room.y+1)
	else
		load_room(room.x+1,room.y)
	end
end

function load_room(x,y)
	has_dashed=false
	has_key=false

	--remove existing objects
	foreach(objects,destroy_object)

	--current room
	room.x = x
	room.y = y

	-- entities
	for tx=0,15 do
		for ty=0,15 do
			local tile = mget(room.x*16+tx,room.y*16+ty);
			if tile==11 then
				init_object(platform,tx*8,ty*8).dir=-1
			elseif tile==12 then
				init_object(platform,tx*8,ty*8).dir=1
			else
				foreach(types, 
				function(type) 
					if type.tile == tile then
						init_object(type,tx*8,ty*8) 
					end
				end)
			end
		end
	end
	
	if not is_title() then
		init_object(room_title,0,0)
	end
end

-- update function --
-----------------------

function _update()
	if not over then
		frames=((frames+1)%30)
	end
	if frames==0 then
		seconds=((seconds+1)%60)
		if seconds==0 then
			minutes+=1
		end
	end
	
	if music_timer>0 then
		music_timer-=1
		if music_timer<=0 then
			--music(10,0,7)
		end
	end
	
	if sfx_timer>0 then
		sfx_timer-=1
	end
	
	-- cancel if freeze
	if freeze>0 then freeze-=1 return end

	-- screenshake
	if screenshake and shake>0 then
		shake-=1
		camera()
		if shake>0 then
			camera(-2+rnd(5),-2+rnd(5))
		end
	end
	
	-- restart (soon)
	if will_restart and delay_restart>0 then
		delay_restart-=1
		if delay_restart<=0 then
			will_restart=false
			load_room(room.x,room.y)
		end
	end

	-- update each object
	foreach(objects,function(obj)
		obj.move(obj.spd.x,obj.spd.y)
		if obj.type.update~=nil then
			obj.type.update(obj) 
		end
	end)
	
	-- start game
	if is_title() then
		if not start_game and (btn(k_jump) or btn(k_dash)) then
			--music(-1)
			start_game_flash=50
			start_game=true
			--sfx(38)
		end
		if start_game then
			start_game_flash-=1
			if start_game_flash<=-40 then
				begin_game()
				particles = {} -- disable snow
			end
		end
	end
	if is_title() and btn(1,1) then
		start_game_flash=0
		begin_game()
		particles = {} -- disable snow
	end
end

-- drawing functions --
-----------------------
function _draw()
	if freeze>0 then return end
	
	-- reset all palette values
	pal()
	
	-- start game flash
	if start_game then
		local c=10
		if start_game_flash>10 then
			if frames%10<5 then
				c=7
			end
		elseif start_game_flash>0 then
			c=9
		elseif start_game_flash>-10 then
			c=8
		else 
			c=0
		end
		if c<10 then
			pal(6,c)
			pal(12,c)
			pal(13,c)
			pal(5,c)
			pal(1,c)
			pal(7,c)
		end
	end

	-- clear screen
	local bg_col = 0
	if flash_bg then
		bg_col = frames/5
	elseif new_bg~=nil then
		bg_col=2
	end
	cls(0)
	rectfill(0,0,128,128,bg_col)

	-- clouds
	if not is_title() then
		foreach(clouds, function(c)
			c.x += c.spd
			rectfill(c.x,c.y,c.x+c.w,c.y+4+(1-c.w/64)*12,new_bg~=nil and 14 or 1)
			if c.x > 128 then
				c.x = -c.w
				c.y=rnd(128-8)
			end
		end)
	end

	-- draw bg terrain
	map(room.x * 16,room.y * 16,0,0,16,16,4)

	-- platforms/big chest
	foreach(objects, function(o)
		if o.type==platform or o.type==big_chest then
			draw_object(o)
		end
	end)

	-- draw terrain
	local off=is_title() and -4 or 0
	map(room.x*16,room.y * 16,off,0,16,16,2)
	
	-- draw objects
	foreach(objects, function(o)
		if o.type~=platform and o.type~=big_chest then
			draw_object(o)
		end
	end)
	
	-- draw fg terrain
	map(room.x * 16,room.y * 16,0,0,16,16,8)
	
	-- particles
	foreach(particles, function(p)
		p.x += p.spd
		p.y += sin(p.off)
		p.off+= min(0.05,p.spd/32)
		rectfill(p.x,p.y,p.x+p.s,p.y+p.s,p.c)
		if p.x>128+4 and is_title() and not start_game then 
			p.x=-4
			p.y=rnd(128)
		end
	end)
	
	-- dead particles
	foreach(dead_particles, function(p)
		p.x += p.spd.x
		p.y += p.spd.y
		p.t -=1
		if p.t <= 0 then del(dead_particles,p) end
		rectfill(p.x-p.t/5,p.y-p.t/5,p.x+p.t/5,p.y+p.t/5,6)
	end)
	
	-- draw outside of the screen for screenshake
	rectfill(-5,-5,-1,133,0)
	rectfill(-5,-5,133,-1,0)
	rectfill(-5,128,133,133,0)
	rectfill(128,-5,133,133,0)
	
	-- credits
	if is_title() then
		cprint("❎+🅾️  ",64,80,5)
		cprint("MADDY THORSON",64,96,5)
		cprint("NOEL BERRY",64,102,5)
		cprint("MOD BY KDX",64,116,5)
	end
	
	if level_index()==30 then
		local p
		for i=1,count(objects) do
			if objects[i].type==player then
				p = objects[i]
				break
			end
		end
		if p~=nil then
			local diff=min(24,40-abs(p.x+4-64))
			rectfill(0,0,diff,128,0)
			rectfill(128-diff,0,128,128,0)
		end
	end

	-- look at my sick shader code
	for i=0x6000,0x7fff,16 do
		local r=flr(rnd'65535')
		poke2(i+0, peek2(i+0) ^^((r&1)    /1    )^^((r&2)    /2    *256))
		poke2(i+2, peek2(i+2) ^^((r&4)    /4    )^^((r&8)    /8    *256))
		poke2(i+4, peek2(i+4) ^^((r&16)   /16   )^^((r&32)   /32   *256))
		poke2(i+6, peek2(i+6) ^^((r&64)   /64   )^^((r&128)  /128  *256))
		poke2(i+8, peek2(i+8) ^^((r&256)  /256  )^^((r&512)  /512  *256))
		poke2(i+10,peek2(i+10)^^((r&1024) /1024 )^^((r&2048) /2048 *256))
		poke2(i+12,peek2(i+12)^^((r&4096) /4096 )^^((r&8192) /8192 *256))
		poke2(i+14,peek2(i+14)^^((r&16384)/16384)^^((r&32768)/32768*256))
	end
	--if someone is reading this,
	--would writing my own rnd run faster in the end?

	--- palette
	-- background
	pal(0,129,1)
	pal(1,1,1)
	-- solids
	pal(2,140,1)
	pal(3,1,1)
	--[[local sp={
		140,1,
		130,140,
		135,130,
	}
	if level_index()<#sp/2 then
		pal(2,sp[level_index()*2+1],1)
		pal(3,sp[level_index()*2+2],1)
	end]]
	-- spikes
	pal(4,142,1)
	pal(5,135,1)
	-- player
	pal(6,9,1)
	pal(7,10,1)
	-- title fading // dim text
	if is_title() then
		pal(8,136,1)
		pal(9,137,1)
	else
		pal(8,140,1)
		pal(9,1,1)
	end
	-- smoke
	pal(10,134,1)
	pal(11,133,1)
	-- hair (djump=0)
	pal(12,129,1)
	pal(13,140,1)
	-- eyes
	pal(14,7,1)
	pal(15,135,1)
end

function draw_object(obj)

	if obj.type.draw ~=nil then
		obj.type.draw(obj)
	elseif obj.spr > 0 then
		spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
	end

end

function draw_time(x,y,b,c)

	local s=seconds
	local m=minutes%60
	local h=flr(minutes/60)
	
	--rectfill(x,y,x+32,y+6,0)
	;(b and print or fprint)((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s),x+1,y+1,c or 7,0)

end

-- helper functions --
----------------------

function clamp(val,a,b)
	return max(a, min(b, val))
end

function appr(val,target,amount)
	return val > target 
		and max(val - amount, target) 
		or min(val + amount, target)
end

function sign(v)
	return v>0 and 1 or
								v<0 and -1 or 0
end

function maybe()
	return rnd(1)<0.5
end

function solid_at(x,y,w,h)
	return tile_flag_at(x,y,w,h,0)
end

function ice_at(x,y,w,h)
	return tile_flag_at(x,y,w,h,4)
end

function tile_flag_at(x,y,w,h,flag)
	for i=max(0,flr(x/8)),min(15,(x+w-1)/8) do
		for j=max(0,flr(y/8)),min(15,(y+h-1)/8) do
			if fget(tile_at(i,j),flag) then
				return true
			end
		end
	end
	return false
end

function tile_at(x,y)
	return mget(room.x * 16 + x, room.y * 16 + y)
end

function spikes_at(x,y,w,h,xspd,yspd)
	for i=max(0,flr(x/8)),min(15,(x+w-1)/8) do
		for j=max(0,flr(y/8)),min(15,(y+h-1)/8) do
			local tile=tile_at(i,j)
			if tile==17 and ((y+h-1)%8>=6 or y+h==j*8+8) and yspd>=0 then
				return true
			elseif tile==27 and y%8<=2 and yspd<=0 then
				return true
			elseif tile==43 and x%8<=2 and xspd<=0 then
				return true
			elseif tile==59 and ((x+w-1)%8>=6 or x+w==i*8+8) and xspd>=0 then
				return true
			end
		end
	end
	return false
end
-->8
-- centered print
function cprint(txt,x,y,c,c2)
	fprint(txt,x-#txt*2,y,c,c2)
end

-- fancy print
function fprint(txt,x,y,c,c2)
	if c2 then
		print(txt,x-1,y,c2)
		print(txt,x+1,y,c2)
		print(txt,x,y-1,c2)
		print(txt,x,y+1,c2)
		print(txt,x-1,y-1,c2)
		print(txt,x-1,y+1,c2)
		print(txt,x+1,y-1,c2)
		print(txt,x+1,y+1,c2)
	end
	print(txt,x,y,c)
end
-->8
function menuitem_screenshake()
	menuitem(1,"screenshake "..(screenshake and"on"or"off"),menu_screenshake)
end

function menu_screenshake()
	screenshake=not screenshake
	menuitem_screenshake()
end
-->8
music=function()end
sfx=music
-->8
anything=to make=me feel=alive
__gfx__
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700000060000000600000060000
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000777777677777770000060000000600000060000
00000000888888888888888888866668888888888888888008888880886e66e800a909a0000a0a000000a0007766666667767777000600000000600000060000
000000008886666888866668886e66e888866668866668808888888888666668009aaa900009a9000000a0007677766676666677000600000000600000060000
00000000886e66e8886e66e808666660886e66e88e66e68088866668886666680000a0000000a0000000a0000000000000000000000600000006000000006000
00000000086666600866666000666600086666e00666668088666668086666800099a0000009a0000000a0000000000000000000000600000006000000006000
000000000066660000666600060000600666660000666660086e66e0006666000009a0000000a0000000a0000000000000000000000060000006000000006000
000000000060060000600060000000000000060000006000066666600060060000aaa0000009a0000000a0000000000000000000000060000006000000006000
555555550000000000000000000000000000000000000000008888004999999449999994499909940300b0b0444044400300b0b0000000000000000000000000
55555555000000000000000000000000000000000000000008888880911111199111411991140919003b330044404440003b330000aaaa0000a0aa000a0000a0
550000550000000000000000000000000aaaaaa000000000087888809111111991119119494004190288882044404440028888200aaaaaa00aa00aa000000000
55000055004000400499994000000000a998888a11111111088888809111111994940419000000440898888004000400789888870aa00aa00a00000000000000
55000055004000400050050000000000a988888a10000001088888809111111991140949940000000888898004000400788889870aa00aa0000000a000000000
55000055044404440005500000000000aaaaaaaa11111111088888809111111991119119914004990889888000000000088988800aaaaaa00aa00aa000000000
55555555044404440050050000000000a980088a144444410088880091111119911411199140411902888820000000000288882000aaaa0000aa0a000a0000a0
55555555044404440005500004999940a988888a1444444100000000499999944999999444004994002882000000000000288200000000000000000000000000
22222222cccccccccccccccccccccccc222222222222222255555555c555555c4444444455555555555555550000000007777770000000000000000000000000
22222222ccccccc22ccccccccccccccc222222222222222255555555555555554444444455555550055555554440000077777777000777770000000000000000
22222222cccccc2222cccccccccccccc222222222222222255555555555555554444444455555500005555554444400077777777007766700000000000000000
22222222ccccc222222ccccccccccccc222222222222222255555555555555554444444455555000000555554440000077773377076777000000000000000000
22222222cccc22222222cccccccccccc222222222222222255555555555555554444444455550000000055550000000077773377077660000777770000000000
22222222ccc2222222222ccccccccccc222222222222222255555555555555554444444455500000000005554440000073773337077770000777767007700000
22222222cc222222222222cccccccccc22222222222222225555555555555555444444445500000000000055444440007333bb37000000000000007700777770
22222222c22222222222222ccccccccc22222222222222225555555555555555444444445000000000000005444000000333bb30000000000000000000077777
ccccccccc22222222222222c2222222222222222222222225555555c555555555555555550000000000000050000044403333330000000000000000000000000
ccc22ccccc222222222222cc22222222222222222222222255555555555555555055555555000000000000550004444403b333300000000000ee0ee000000000
cc2222ccccc2222222222ccc222222222222222222222222555555555555555555550055555000000000055500000444033333300000000000eeeee000000030
c222222ccccc22222222cccc2222222222222222222222225555555555555555555500555555000000005555000000000333b33000000000000e8e00000000b0
c222222cccccc222222ccccc222222222222222222222222555555555555555555555555555550000005555500000444003333000000b00000eeeee000000b30
cc2222cccccccc2222cccccc22222222222222222222222255555555555555555505555555555500005555550004444400044000000b000000ee3ee003000b00
ccc22cccccccccc22ccccccc22222222222222222222222255555555555555555555555555555550055555550000044400044000030b00300000b00000b0b300
cccccccccccccccccccccccc2222222c22222222c222222c5555555cc555555c5555555555555555555555550000000000999900030330300000b00000303300
02222002220222200777777777777777777777700777777000000000000000002222222200000000000000000000000000000000000000000000000000000000
22222222222222227000077700007770000077777000777700000000000000002222222200000000000000000000000000000000000000000000000000000000
222222222222222270cc777cccc777ccccc7770770c7770700000000000000002222222200000000000000000000000000000000000000000000000000000000
222222222222222270c777cccc777ccccc777c0770777c0700000000000000002222222200000000000000000000000000000000000000000000000000000000
2222222222222222707770000777000007770007777700070002eeeeeeee20002222222200000000000000000000000000000000000000000000000000000000
022222222222222077770000777000007770000777700007002eeeeeeeeee2002222222200000000000000000000000000000000000000000000000000000000
02222222222222207000000000000000000c000770000c0700eeeeeeeeeeee002222222200000000000000000000000000000000000000000000000000000000
22222222222222227000000000000000000000077000000700e22222e2e22e002222222200000000000000000000000000000000000000000000000000000000
22222222222222227000000000000000000000077000000700eeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000
02222222222222227000000c000000000000000770cc000700e22e2222e22e000000000000000000000000000000000000000000000000000000000000000000
022222222222222070000000000cc0000000000770cc000700eeeeeeeeeeee000000000000000000000000000066000000000000000600000000000000000000
222222222222222270c00000000cc00000000c0770000c0700eee222e22eee000000000000000000000000000666600000000000000660000600000000000000
22222222222222227000000000000000000000077000000700eeeeeeeeeeee005555555500000000000000000600660000000000006060666600000000000000
222222222222222270000000000000000000000770c0000700eeeeeeeeeeee005555555500000000000000000600066000000000006666600000000000000000
222222222222222270000000c0000000000000077000000700ee77eee7777e005555555500000000000000000600006000000000006060000000000000000000
02222022220022207000000000000000000000077000c00707777777777777705555555500000000000000000600006000000000006060006666000000000000
00000000000000007000000000000000000000077000000700777700500000000000000500000000000000006000060000000600006060006006000000000000
00aaaaaaaaaaaa00700000000000000000000007700c000707000070550000000000005500000666600000006000060000000660006060006000600000000000
0a999999999999a0700000000000c000000000077000000770770007555000000000055500000600000000006000060666660666006060006006600000000000
a99aaaaaaaaaa99a7000000cc0000000000000077000cc077077bb07555500000000555500000600066666006000600600660606606660006660000000000000
a9aaaaaaaaaaaa9a7000000cc0000000000c00077000cc07700bbb07555555555555555500000600060006006600600606606600666600666000066600000000
a99999999999999a70c00000000000000000000770c00007700bbb07555555555555555500000600060066000666000660006066666666606666660000000000
a99999999999999a7000000000000000000000077000000707000070555555555555555500000660066660000666666600006000006660000000000000000000
a99999999999999a0777777777777777777777700777777000777700555555555555555500000006666000066600000600666000000000000000000000000000
aaaaaaaaaaaaaaaa07777777777777777777777007777770004bbb00004b000000400bbb00000000006666660000000666600000000000000000000000000000
a49494a11a49494a70007770000077700000777770007777004bbbbb004bb000004bbbbb00000000000000000000000660000000000000000000000000000000
a494a4a11a4a494a70c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb0000000000000000000000000000000000000000000000000000000000
a49444aaaa44494a70777ccccc777ccccc777c0770777c07040000000400bbb00400000000000000000000000000000000000000000000000000000000000000
a49999aaaa99994a7777000007770000077700077777000704000000040000000400000000000000000000000000000000000000000000000000000000000000
a49444999944494a77700000777000007770000777700c0742000000420000004200000000000000000000000000000000000000000000000000000000000000
a494a444444a494a7000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
a49499999999494a0777777777777777777777700777777040000000400000004000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000094a4b4c4d4e4f400000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000095a5b5c5d5e5f500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000096a6b6c6d6e6f600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000097a7b7c7d7e7f700000000
__label__
hhhhhhhhhh1h1h1hhh1hhhhh1hhhhhhhhh1h1hhhhhhh1h1hhhhh1hhhhhhhhhhhhhhhhh1h1hhhhhhh1hhhhhhh1h1hhhhhhh1hhhhh1h1h1hhhhhhhhh1hhh1h1hhh
hhhh1hhh1hhh1h1h1h1h1hhh1hhhhhhh1hhhhhhh1hhhhh1hhhhhhh1hhhhh1h1h1h1hhh1h1h1h1h1hhh1hhh1h1h1hhhhhhh1hhhhhhhhhhhhh1h1hhh1hhhhh1h1h
hhhhhh1hhhhh1h1h1hhhhhhhhhhhhhhhhh1hhhhh1h1hhh1hhhhhhh1h1h1h1h1h1h1hhh1hhh1h1hhhhh1hhhhhhhhhhh1h1hhh1hhhhhhahhhh1h1h1hhhhh1h1h1h
1hhh1hhh1h1hhhhh1hhh1hhhhh1hhhhh1hhhhhhhhh1hhh1h1h1hhhhh1hhh1h1h1h1h1hhhhhhh1hhh1h1hhhhh1hhhhh1h1h1hhhhh1hhh1h1hhh1h1h1hhh1h1hhh
hhhhhh1hhh1h1hhh1h1h1h1h1h1h1hhh1h1hhh1h1h1hhhhhhh1h1h1h1hhh1hhhhhhh1hhh1hhh1hhhhhhhhhhh1h1hhh1h1hhhhhhhhh1hhh1hhh1h1hhh1hhhhhhh
hhhhhh1h1h1h1hhhhhhh1h1hhahhhhhhhhhhhhhh1hhhhh1h1h1hhh1hhh1h1h1h1h1hhh1hhh1h1h1h1h1hhh1hhhhhhhhh1h1hhh1hhh1hhh1hhh1hhh1hhh1h1hhh
hhhh1hhhhhhh1hhhhhhh1h1h1h1hhh1hhhhhhh1hhhhh1h1hhhhh1hhhhhhhhh1hhhhhhh1hhh1h1h1hhhhh1hhh1hhhhhhh1hhhhh1hhh1h1hhh1h1h1hhh1h1hhh1h
1hhhhhhhhh1hhh1h1hhhhhhh1hhh1hhhhh1h1h1h1h1hhhhh1h1hhh1h1h1h1hhhhh1h1h1hhh1hhhhhhh1h1h1h1hhhhh1hhhhh1hhhhh1hhhhh1h1hhh1h1hhhhhhh
1hhhhh1hhh1hhhhh1hhh1h1hhh1h1h1hhh1hhh1h1hhhhhhhhh1hhhhhhh1hhh1hhhhh1hhh1hhh1h1hhhhhhh1hhh1hhhhhhh1hhhhh1hhh1h1h1hhh1h1h1h1h1h1h
1h1hhhhhhhhh1h1h1hhh1hhhhh1hhhh9hhhh1hhhhhhhhhhhhh1h1h1hhh1h1h1h1h1h1hhh1h1h1h1h1h1hhhhh1h1h1hhh1hhh1h1h1hhhhhhhhhhhhh1h1h1hhh1h
hhhhhh1hhhhh1hhhhh1h1h1hhhhh1h1hhhhhhhhhhh1h1h1hhh1h1hhh1hhhhhhh1h1hhhhhhh1h1hhhhhhh1hhh1h1h1h1hhh1hhh1h1h1h1hhhhhhhhh1hhh1hhh1h
1hhh1hhhhhhh1hhh1hhh1hhhhh1h1hhhhhhhhhhhhhhh1h1h1hhhhh1hhhhh1h1h1hhhhhhhhh1hhh1hhh1hhh1h1hhhhh1h1hhhhhhh1h1hhhhh1h1hhh1hhh1h1h1h
hh1hhh1hhh1hhh1hhh1h1h1hhh1hhh1hhh1h1h1hhhhhhh1h1hhh1h1hhhhhhh1hhhhh1h1h1h1h1hhhhh1h1h1hhh1h1h1hhh1hhhhhhh1hhhhh1h19ah1h1hhhhh1h
1hhhhhhhhh1hhh1hhhhh1hhhhhhh1hhh1hhhhhhh1h1hhh1h1hhh1hhhhh1h1h1h1hhh1h1h1hhhhhhh1hhhhh1h1h1h1hhhhhhh1h1h1h1hhhhh1hh99h1hhhhh1hhh
1h1hhh1h1hhh1h1hhh1hhhhh1h1hhhhh1hhh1h1hhh1hhhhh1h1hhhhhhh1h1h1h1hhhhh1hhhhh1h1hhh1hhh1h1hhh1h1h1hhhhhhhhh1hhhhh1hhh1hhhhh1hhh1h
hh1hhh1hhh1hhh1hhhhhhhhh1h1h1hhhhhhhhhhhhh1h1h1hhhhhhhhhhhhhhhhh1hhhhh1hhhhhhhhhhh1hhhhhhhhh1hhh1h1hhhhh1hhh1hhh1hhhhh1hhhhh1h1h
1h1h1hhh1hhhhhhhhh1h1h1hhhhh1h1hhh1hhhhh1h1hhhhh1hhhhh1h1hhh1hhh1hhh1hhhhh1h1h1h1hhhhh1hhh1hhh1hhh1hhhhhhh1hhhhh1hhhhh1hhhhh1h1h
hh1hhh1hhhhhhh1hhh1hhhhhhhhh1hhh1hhhhh1hhh1hhhhhhhhh1hhh1h1hhh9h1h1hhh1hhh1hhh1hhhhhhhhhhh1hhhhh1h1hhh1h1h1hhhhhhh1hhh1hhh1hhh1h
1h1hhhhhhh1hhhhh1hhhhhhhhh1hhhhh1h1h1h1hhh1hhh1hhhhhhh1h1h1h1h1h1h1h1hhhhhhhhh1h1h1hhh1hhhhh1hhh1hhhhhhhhhhhhhhhhhhh1h1hhh1hhh1h
hhhhhh1h1h1hhhhh1hhh1h1h1h1h1h1hhh1hhh1h1h1h1hhhhh1hhhhh1hhh1hhhhh1h1hhhhhhh1h1h1hhh1hhhhhhh1hhh1hhhhh1h1h1hhhhh1hhhhhhh1hhh1h1h
1h1h1hhh1hhh1h1h1h1hhh1hhhhh1h1h1hhh1h1h1hhhhh1hhh1hhhhhhhhhhh1h1h1hhhhhhhhh1hhhhh1hhh1hhhhh1hhh1hhhhhhhhhhh1h1hhh1hhh1h1hhh1h1h
1h1h1hhh1hhh1h1hhh1hhhhh1hhh1hhhhh1h1h1hhh1hhhhh1hhhhh1hhh1hhh1h1hhh1hhh1h1h1h1hhhhhhhhhhhhh1hhhhh1hhh1h1hhh1hhh1hhh1h1h1h1hhhhh
1h1h1hhhhhhhhhhh1h1hhhhh1h1hhhhh1hhhhhhh1hhh1hhh1h1hhh1h1h1hhhhhhh1h1h1hhh1h1hhhhh1hhh1h1hhhhhhhhh1hhhhh1hhhhhhh1h1h1h1hhhhhhh1h
1hhhhhhhhh1h1hhh1hhhhh1hhh1hhh1hhhhh1hhhhhhh1h1hhh1h1h1h1h1h1h1h1h1h1hhh1h1hhhhh1h1hhh1h1h1h1h1hhhhh1h1h1hhh1h1hhhhh1h1hhh1hhhhh
1h1hhhhhhh1hhh1h1hhh1h1hhh1h1hhh1hhhhhhh1hhh1hhhhhhhhh1h1h1hhhhhhhhhhh1h1hhh1h1h1hhhhh1h1h1hhhhh1h1hhhhhhhhhhhhhhhhhhhhh1hhhhh1h
1h1h1hhhhhhhhh1h1h1h1h1hhhhhhh1hhhhhhhhh1h1hhh1hhh1hhhhh1hhh1hhh1hhh1h1h1h1h1h1h1hhh1hhh1h1hhh1h1hhhhh1h1hhh1h1hhhhhhhhh1hhh1hhh
hhhh1hhh1hhhhh1h1h1hhh1hhhhhhhhh1h1hhh1h1h1h1hhhhh1hhhhhhh1hhhhhhhhh1h1h1h1h1hhh1h1hhh1h1h1h1hhh1h1h1h9hhh1hhhhhhhhhhhhhhhhh1h1h
hhhh1hhhhh1h1h1hhhhh1hhh1hhh1hhh1h1h1hhhhhhhhh1hhh1h1h1h1h1hhhhhhhhh1h1hhhhhhh1hhh1h1hhh1h1h1h1hhhhh1hhhhhhhhhhh1hhh1hhh1h1hhhhh
1hhh1h1h1h1hhhhhhhhhhh1hhhhh1h1hhh1hhh1h1hhh1hhh1h1hhhhh1hhh1h1h1h1hhhhh1h1hhhhh1hhhhhhhhhhhhh1hhhhhhh1hhhhh1hhh1h1h1h1hhh1hhhhh
hhhhhhhh1hhhhhhh1h1hhh1h1hhh1hhhhhhh1h1h1hhh1hhh1h1h1h1hhh1hhh1hhhhh1hhhhh1h1h1hhh1h1h1hhhhh1h1h1h1hhhhhhh1hhh1hhh1h1hhhhh1hhh1h
1h1h1hhh1h1hhhhhhh1hhh1hhh1hhhhhhhhh1hhhhhhhhh1hhh1h1hhhhhhh1h1hhhhh1h1hhhhhhhhh1hhh1h1h1hhhhhhhhhhhhh1h1hhh1h1hhh1hhhhh1h1h1hhh
1hhhhh1hhh1h1haa1hhhhhhh1hhhhhhhhhhhhh1hhhhhhh1h1hhhhh1h1h1h1hhhhh1hhhhhhhhh1hhh1hhhhh1hhh1h1h1hhhhh1hhh1h1h1hhhhhhhhh1hhhhhhh1h
1h1hhhhhhh1h1haahhhh1hhhhhhhhh1h1hhh1hhh1h1hhhhh1h1h1h1h1hhhhhhhhh1hhhhhhhhhhhhhhhhhhh1hhhhh1h1h1h1hhh1h1hhhhhhhhh1hhhhhhhhh1hhh
hh1hhh1h1hhh1hhhhh1h1hhh1h1h1h1hhhhh1h1hhhhh1hhhhh1hhhhhhh1hhh1hhh1hhh1hhh1h1h1h1hhhhh1hhh1h1h1hhhhh1h1hhh1hhhhhhh1h1hhh1hhhhhhh
1h1hhhhh1h1hhh1hhhhh1h1hhhhh1hhhhh1h1h1h1h1hhh1hhh1h1h1h1h1hhh1hhh1hhhhh1h1h1hhhhh1hhhhh1hhh1h1hhh1hhhhh1hhh1hhhhh1hhh1hhhhhhh1h
hh1hhh1hhh1hhhhh1hhhhhhhhhhhhh1hhh1hhh1hhhhhhh1h1h1h1h1h1h1h1hhhhhhhhh1h1h1h1hhhhhhhhh1h1h1hhhhh1hhhhhhhhhhh1hhh1h1hhh1hhh1h1h1h
1hhhhhhh1h1hhh1h1hhh1hhhhhhhhh1hhh1hhh1h1hhhhh1h1h1hhhhhhh1h1hhhhh1hhh1hhhhh1hhh1h1h1h1h1hhh1hhh1h1h1hhh1h1hhhhhhh1hhhhh1h1hhhhh
hh1hhh1h1h1h1hhh1hhhhh1hhh1h1hhh1hhh1h1hhhhh1hhhhhhh1hhh1h1hhh1hhh1h1h1h1hhhhh1h1h1h1h1hhhhhhh1hhhhh1hhh1hhh1h1hhhhhhhhhhhhhhh1h
1h1h1hhh1hhh1hhh1hhh1hhh1hhh1hhh1h1h1h1hhh1h1h1h1h1h1hhhhh1h1hhhhh1h1h1hhh1hhh1h1hhh1h1hhh1hhhhhhhhhhhhh1hhhhhhh1hhh1hhh1hhh1hhh
hh1h1h1hhh1hhh1hhhhhhhhh1hhh1hhh19hhhh1h1hhhhhhhhhhhhhhh1hhh1hhhhhhhhh1hhh1h1h1h1hhhhhhh1hhh1h1h1h1hhh1hhhhhhhhh1h1hhh1hhhhhhhhh
1h1hhh1hhh1h1h1hhh1h1hhhhh1h1hhh1h1h1hhh1hhh1h1hhh1h1hhhhh1hhhhh1h1hhh1hhh1h1hhhhh1hhhhhhh1hhhhhhhhh1h1h1hhh1hhhhh1hhhhh1hhh1hhh
1hhh1h1hhh1h1hhh1h1hhh1h1h1h1h1hhhhhhhhhhh1hhh1hhhhhhh1h1hhh1h1h1h1hhh1hhh1h1h1h1hhh1h1hhh1h1h1h1hhh1h1hhhhh1hhh1hhhhh1hhhhhhh1h
1hhh1h1h1hhhhh1h1hhh1hhhhh1hhh1hhh1hhh1h1hhh1hhh1h1h1h991h1h1h1h1hhhhhh9hh1h1h1h1h1h1hhhhhhh1h1h1h1h1hhhhhhhhh1h1h1h1hhh1h1h1hhh
1h1hhhhhhh1h1hhh1hhh1h1h1h1hhhhh1hhh1h1hhhhhhh1hhh1h1999ah1h1h1h1h1h1h19ahhh191hhh1hhh1h1h1h1h1hhhhh1hhh1hhhhh1hhhhh1hhhhhhhhhhh
hhhh1h1h1h1h1h1h19hhhhhh1h1h1hhhhhhh1hhhhhhhhhhh1h1hh91ha91hhh1hhh1hhh9hah99a91h1h1h1hhhhhhhhh1h1h1h1hhh1hhh1h1hhh1h1h1hhhhhhhhh
1h1h1hhh1hhh1h1h1h1h1h1h1hhhhh1h1h1hhh1h1h1hhhhhhh1h191h19ah1h1hhhhhhha9999hhh1h1h1hhhhhhhhhhh1hhh1h1hhh1hhhhh1hhh1hhhhhhh1h1h1h
1hhhhhhhhh1hhhhh1h1hhhhhhh1hhh1hhh1h1h1hhh1h1h1h1h1hh91h1h9h1h1h1h1h1hah9h1hhh1hhhhh1hhhhhhh1hhh1h1h1hhhhhhh1hhh1h1hhh1h1hhhhhhh
hh1hhhhh1hhh1hhhhh1hhh1hhhhhhh1hhhhh1hhhhhhhhhhhhh1hh91hhhahhhhhhhhhhhahah1h99991h1h1hhh1hhhhhhhhh1hhh1h1h1h1hhh1hhh1hhhhh1h1h1h
1hhhhh1hhhhhhh1hhh1h1hhhhhhhhh1h1hhhhh1hhhhh1hhh1hhhahhhh91h1hhh191hhhah9hhhah191hhh1h1hhhhh1hhhhh1hhh1h1h1hhh1h1h1h1h1h1hhh1h1h
1hhh1h1h1h1h1hhh1hhhhhhh1hhh1hhhhh1h1hhh19a9ahhhhhhh9hhh191h1hhh19ahhhahah1h9h1hah1hhh1h1hhh1hhhhhhhhh1hhhhh1hhhhh1hhh1h1hhh1hhh
hhhhhhhhhhhhhh1hhh1h1hhhhhhh1h1h1hhhhh1hh91hhhhhhhhhahhhh9h9a9a919991hah9hhhahh99hhh1hhhhh1h1hhh1hhhhhhhhhhhhhhhhh1hhhhh1hhhhhhh
hhhh1h1hhhhh1hhh1hhhhh1h1hhh1hhhhh1hhh1h191hh9a9991h9h1h9h19hh99h9h99h99ahhha99h1h1h1h1h1hhh1h1hhh1hhh1h1h1h1hhhhhhh1h1h1hhh1hhh
hh1h1h1hhhhh1h1h1h1h1hhh1hhh1h1h1hhh1hhhh91h191h19hha9hhah19h9aha9hha999hh999h1hh9a91hhh1h1h1hhhhhhhhhhhhhhh1hhh1hhh1hhhhh1h1hhh
hhhhhh1h1h1h1hhh1hhh1h1h1hhhhh1hhh1hhh1h191h191h991h19a9hhh99hhhaha99999999h99a9a91h1h1hhhhhhhhh1h1h1h1hhh1h1hhh1h1hhh1h1h1hhhhh
hh1h1hhh1h1hhh1hhh1h1h1h1h1hhhhh1hhh1h1h19ah19999hhhh9a9a9a9hhhh9hhhhha9ah1h1hhhhh1h1h1h1h1hhh1hhh1hhh1hhh1h1hhhhh1h1h1hhhhhhhhh
1hhh1h1h1h1h1h1h1h1hhh1hhhhh1h1h1hhhhhhhhhh9a99hhhh999hhhhh91ha99h1hhhhh1h1hhh1hhh1h1h1h1h1hhhhh1h1hhhhh1h1h1hhhhhhhhhhh1h1hhhhh
1hhhhhhh1h1hhhhh1hhhhhhh1hhh1hhh1hhhhh1hhhhh1h9999a91hhh1h19a9ahhhhh1h1h1hhh1hhh1h1hhhhhhhhh1h1h1hhh1hhhhh1h9h1hhhhhhh1h1h1hhh1h
1hhh1h1h1hhhhhhh1hhh1h1h1h1h1h1h1h1h1hhh1hhhhhhhhh1hhh1h1h199hhhhhhh1hhh1hhhhhhh1h1hhhhhhhhh1hhh1hhhhh1h1h1h1hhhhhhh1h1h1hhhhhhh
hh1h1hhh1hhhhh1h1hhhhhhh1h1hhhhh1h1hhh1h1hhh1h1hhhhh1hhhhh1hhhhhhh1hhh1hhhhh1h1hhhhhhh1hhhhhhhhh1hhh1hhhhh1h1h1h1hhh1h1hhh1h1hhh
1hhh1hhh1hhhhhhh1hhh1hhhhhhhhh1hhh1hhh1hhh1h1h1h1hhh1h1h1hhh1h1hhh1hhh1hhh1h1hhh1hhh1hhh1hhhhhhh1h1hhhhhhh1hhh1h1h1h1h1h1hhhhhhh
1h1h1h1hhhhhhh1h1h1h1hhhhhhhhhhhhh1hhh1hhh1h1hhhhh1hhhhh1h1h1hhhhh1h1h1h1hhhhhhh1hhhhh1hhhhhhh1h1h9h1h1h1h1hhh1h1hhh1h1h1hhh1h1h
hh1h1hhh1hhh1hhhhh1h1h1h1h1h1h1h1hhh1h1hhhhh1hhhhhhhhhhhhhhh1h1hhh1h1hhh1hhh1h1h1h1hhhhh1hhh1h1h1h1hhhhhhhhhhh1h1h1h1h1hhh1h1h1h
1hhh1hhhhhhh1hhhhhhhhhhhhhhh1h1hhh1hhh1hhh1hhhhh1h1hhh1hhhhh1hhhhh1hhh1hhh1hhh1hhhhhhhhhhh1h1h1h1hhhhhhhhh1hhhhhhhhhhhhh1hhhhhhh
1h1h1hhh1h1h1hhhhhhhhh1hhhhh1h1h1hhhhhhh1hhh1hhh1h1hhh1h1h1h1hhhhh1hhhhhhhhh1hhhhhhh1hhh1hhh1hhh1h1hhh1hhhhh1hhhhh1h1h1h1hhh1hhh
1hhhhh1h1h1hhhhhhh1h1h1hhhhh1hhh1hhhhhhh1hhh1h1hhhhhhhhh1h1h1h1h1h1hhhhhhhhh1hhhhhhhhhhh1h1h1hhh1h1hhhhh1h1h1hhhhhhhhhhh1h1hhh1h
1hhhhh1h1hhhhh1h1hhh1h1h1hhh1h1hhhhh1hhh1hhh1hhh1hhh1hhh1h1h1hhhhh1hhhhhhh1h1h1h1h1hhh1hhhhh1hhhhh1h1h1hhhhh1h1hhhhh1hhhhhhh1h1h
hh1hhhhhhhhhhh1hhh1hhhhhhh1hhhhh1h1hhh1hhh1hhhhh1hhhhh1h1hhhhhhh1h1h1h1hhh1h1hhh1h1h1h1h1h1hhh1hhhhh1hhhhhhhhhhhhh1hhhhh1h1hhhhh
1hhh1h1hhh1h1h1h1hhhhh1h1h1h1hhhhh1h1hhh1h1h1h1h1h1hhh1hhh1h1h1hhh1h1hhh1h1h1hhh1hhh1h1h1hhhhh1h1hhhhhhhhh1hhhhhhhhhhhhh1h1h1h1h
hh1hhhhhhh1hhhhhhh1hhh1hhhhhhh1h1hhh1h1hhh1hhhhh1hhhhh1hhhhhhhhh1h1hhhhhhhhhhh1h1h1hhhhhhhhh1hhhhhhhhhhhhh1h1hhhhh1h1h1hhhhh1h1h
hhhhhhhhhhhh1h1hhh1h1hhhhh1h1h1h1hhh1hhhhhhhhhhhhh1hhhhh1h1hhh1h1h1h1hhh1hhhhh1hhh1hhh1h1h1hhh1hhh1h1h1hhh1hhhhh1hhh1hhh1hhh1h1h
hhhhhh1hhh1hhh1h1h1h1hhhhh1hhh1hhhhh1h1hhh1h1h1h1h1hhh1h1hhh1hhhhh1hhhhh1h1h1h1hhhhhhh1hhhhhhh1hhhhhhhhhhh1h1h1h1hhh1hhh1hhhhh1h
1h1hhh1h1h1h1hhhhhhh1h1hhh1hhh1h1h1hhhhh1hhh1hhhhh1hhh1h1h1hhhhh1h1hhh1hhhhhhhhh1hhhhhhhhhhh1hhhhh1h1h1h1hhhhhhhhh1hhhhh1hhhhh1h
hh1hhh1hhh1hhhhh1hhh1h1h1h1hhh1hhhhh1h1hhhhhhh1hhh1h1hhh1h1h1h1hhhhhhhhhhhhhhh1h1h1h1h1h1h1hhh1hhhhh1hhhhh1hhhhhhh1hhhhh1h1hhhhh
1hhhhhhhhh1hhhhhhh1hhh1h1hhh1hhh1h1h1hhhhh1hhh1h1hhhhh1hhhhh1hhhhhhhhhhh1h1h1hhh1h1hhhhh1h1h1hhh1h1hhh1hhh1hhh1hhh1h1h1hhh1h1hhh
1h1h1h1hhh1hhhhh1h1h1hhhhh1hhhhh1h1hhhhhhhhhhh1h1h1hhhhh1h1hhh1hhhhhhh1h1hhhhh1hhh1h1h1hhh1h1h1hhh1hhhhhhh1hhhhhhhhhhhhhhhhh1h1h
hh1hhh1hhh1h1h1hhhhh1hhh1h1h1h1h1h1hhhhh1hhhhh1h1hhhhh1hhh1h1hhhhh1hhhhhhh1h1h1h1hhh1hhh1h1hhhhh1hhh1h1h1hhhhhhh1hhhhhhh1h1h1hhh
hhhh1hhh1hhhhh1hhhhh1hhhhhhh1hhhhhhh1hhhhhhh1h1hhhhh1h1h1h1hhh1hhhhh1h1h1h1h1h1hhhhhhh1h1h1h1hhhhh1hhh1h1hhhhh1h1hhh1hhh1hhhhh1h
hh1h1h1h1h1h1hhhhh1h1hhh1h1hhh1h1h1h1hhh1h1h1h1h1h1hhhhhhh1h1h1h1hhhhh1hhh1hhhhhhh1hhh1h1h1hhh1hhhhh1h1h1hhh1hhh1hhh1hhhhh1h1hhh
1h1hhhhhhhhhhh1h1hhh1hhh1hhh1hhh1hhh1h1h1hhhhh1h1hhh1hhh1hhhhh1hhhhh1h1h1hhh1hhh1hhh1hhhhhhh1hhhhhhhhhhh1h1h1h1hhh1h1h1hhhhhhhhh
1h1hhhhh1h1h1h1h1hhh1hhh1hhhhh1hhh1hhhhhhh1h1h1h1hhh1hhh1h1hhhhhhhhhhh1hhh1hhhhh1hhh1h1h1h1hhhhh1h1h1hhhhhhhhhhhhh1h1hhh1h1hhhhh
hh1hhhhh1hhh1h1hhh1hhh1hhhhh1hhh1h1hhhhhhhhh1h1hhhhh1hhnnnnn1hhh1hhnnnnn1h1hhh1h1h1hhhhhhhhhhhhh1hhh1h1h1hhh1h1hhhhhhhhhhh1h1h1h
hhhh1h1hhh1hhh1h1hhhhh1h1h1hhhhh1h1h1hhh1h1h1hhh1hhhhhnnhnhnnh1nhhunhhhnuhhh1h1hhh1hhh1h1hhhhh1hhhhhhh1hhh1h1hhhhhhh1hhh1hhh1hhh
1h1hhhhhhh1h1h1h1h1h1hhh1h1hhh1hhh1hhh1hhh1hhhhhhh1h1hunnhunnhnnnhnnhnhnnhhhhhhh1h1hhhhhhhhhhh1hhh1hhhhhhh1hhhhhhh1h1hhhhh1h1hhh
hhhhhh1h1hhhhhhh1h1hhh1hhh1h1hhh1h1hhhhhhh1hhhhhhh1hhhnnhn1nnh1n1hun1h1nuh1h1h1h1hhh1h1h1h1h1h1h1h1hhhhhhhhhhh1h1hhhhhhhhh1hhhah
1hhhhhhhhh1h1h1hhh1hhhhh1h1hhh1h1hhhhhhhhh1hhhhh1hhh1h1nnnnnhh1hhhhnnnun1hhh1h1hhh1h1hhh1hhh1h1h1h1h1h1h1h1hhh1h1h1h1h1hhh1h1h1h
hh1hhhhh1hhhhhhh1h1hhhhh1hhh1h1hhh1hhh1h1h1h1hhhhhhh1h1h1hhh1hhhhhhh1h1hhhhhhhhhhhhhhhhh1h1h1h1hhh1h1h1h1hhh1hhhhhhh1hhh1h1h1h1h
1hhhhhhh1h1h1hhh1h1hhh1h1hhhhhhhhh1hhh1hhhhhhhhh1hhh1h1hhhhhhhhh1hhh1hhhhh1hhhhh1hhhhh1hhh1h1h1hhhhh1hhh1h1h1h1hhh1hhh1h1h1hhhhh
hh1hhh1h1h1hhh1h1hhhhhhh1h1hhhhh1hhh1h1hhhhh1h1hhhhhhhhh1hhh1hhh1hhhhhhhhhhh1hhh1hhhhhhhhh1hhhhh1hhh1h1h1hhhhhhhhh1hhh1hhh1h1hhh
1hhhhhhh1hhh1h1hhhhh1hhh1hh91h1h1hhhhh1h1h1hhhhh1h1hhhhhhh1hhhhhhh1h1hhh1h1h1hhh1h1hhh1h1hhh1hhh1hhhhh1hhh1hhh1hhhhh1hhhhhhh1h1h
1hhhhhhhhh1hhh1hhh1h1h1hhhhhhh1h1hhhhhhh1hhh1h1hhhhhhh1h1hhh1hhhhhhhhh1hhhhhhh1h1hhhhh1hhhhhhh1h1h1hhhhh1hhhhhhh1h1hhhhhhhhh1h1h
1hhhhhhh1h1hhh1hhhhh1h1hhhhh1hhh1hhh1h1hhhhh1hhh1h1h1h1hhh1hhhhh1hhhhhhhhhhhhh1hhh1hhh1h1hhh1h1hhhhhhhhh1hhh1h1h1hhh1hhhhhhhhhhh
1h1h1h1hhhah1h1h1hhh1hhh1h1h1hhhhh1hhh1h1hhhhhhhhhhhhhhhhhhh1hhhhh1hhh1h1hhh1h1h1hhh1h1hhh1h1hhh1hhh1h1hhhhh1hhh1hhhhhhh1hhhhhhh
1h1h1h1h1h1hhhhh1hhhhhhh1h1h1h1hhhhh1h1h1h1h1h9h1hhh1hhh1h1h1h1hhh1hhhhh1h1h1hhh1hhh1h1hhhhh1hhh1hhhhhhhhh1hhhhhhhhh1hhhhhhhhh1h
1h1h1hhh1h1h1hhhhh1h1h1hhh1hhhhhhhhh1h1hhhhhhhhhhhhhhh1hhhhhhh1h1h1h1h1h1h1h1h1h1hhhhh1h1hhh1h1h1h1h1hhhhhhhhhhh1h1h1hhh1h1h1h1h
1h1h1h1h1h1h1hhhhhhh1h1hhh1h1hhh1h1hhhhh1h1h1h1hhhhhhhhhhh1hhh1ahhhhhhhhhhhh1hhhhh1hhh1hhh1hhhhh1hhhhhhh1h1hhhhhhhhh1hhhhh1h1h1h
hhhh1h1h1hhhhh1hhhhh1h1h1h1hhhhhhh1h1h1hhhhh1hhhhh1hhhhh1hhhhh1hhh1hhhhhhhhh1hhh1hhh1hhh1h1h1h1h1hhhhh1h1hhhhhhh1hhhhh1hhhhhhh1h
1hhhhh1h1hhhhh1hhhah1h1h1hhh1hhhhh1h1hhhhh1h1h1hhh1h1h1h1h1h1hhhhhhh1h1h1hhh1h1hhhhhhh1hhhhh1h1hhhhh1hhhhh1hhh1hhh1h1hhh1h1h1hhh
1h1h1hhhhhhh1h1hhh1h1h1h1hhh1h1hhhhhhhnnnh1nuhnnhhnn1hnhnhhhhhnnnhuhnh1nuhunhh1nnhhnnhnn1hhh1hhh1hhhhhhhhh1h1h1hhh1h1h1hhh1h1h1h
hhhh1h1h1hhh1hhh1h1h1h1h1hhhhh1hhh1h1hnnuhuhnhuhuhuhnhnnuhhhhhhn1huhuhuhuhuhnhuh1huhnhnhnh1h1h1h1hhhhhhhhhhhhhhhhhhh1hhhhhhhhhhh
1h1h1hhh1h1hhh1hhhhh1h1h1hhh1h1h1h1hhhnhuhnnnhnhuhuhnhhhuh1hhh1nhhnnnhnhnhun1h1huhnhnhnhuhhhhhhh1h19hh1h1hhh1h1hhhhhhh1h1h1h1hhh
1h1hhh1h1hhh1hhhhhhh1hhhhh1hhhhhhh1h1huhnhuhnhnnhhun1hnn1h1hhh1nhhuhnhnn1hnhuhun1hunhhuhnhhhhh1hhh1hhhhhhh1h1h1hhhhh1h1h1h1hhhhh
1h1h1h1hhhhhhhhhhhhhhh1hhhhhhhhhhhhhhhhhhh1hhhhhhhhhhh1hhhhhhhhh1hhhhhhhhh1h1hhhhh1hhh1h1hhhhhhh1hhhhh1hhh1h1h1h1hhh1h1h1h1h1hhh
hh1h1h1hhhhh1hhhhhhhhhhhhh1hhh1hhhhh1h1h1hhh1h1hhh1hhh1h1hhh1h1hhhhh1hhh1hhhhhhh1hhhhh1hhh1hhh1hhhhhhh1hhhhhhhhh1hhhhhhh1hhh1hhh
hhhhhh1h1h1h1hhh1h1hhhhh1h1hhhhhhhhh1h1h1h1hunhh1nuhnnnhnh1h1hhhunhhunuhnnhhnn1hnhuhhh1h1h1h1h1h1h1h1hhh1hha1h1h1hhhhh1hhh1hhh1h
hh1hhhhh1h1hhhhhhhhh1hhhhh1hhhhhhhhhhh1hhh1hnhuhuhnhnnhhnhhhhhhhnn1hunhhnhuhuhuhnnnhhhhhhhhh1hhhhh1h1hhh1hhhhhhhhhhhhhhhhh1h1hhh
hhhhhh1hhhhhhh1hhh1h1h1h1hhh1h1hhh1h1hhh1h1hnhuhuhnhnh1huhhh1h1huhuhnh1hun1hun1h1huhhh1hhhhh1hhhhh1h1h1hhhhh1h1h1hhh1hhhhhhh1hhh
1h1hhhhhhh1h1hhhhh1h1h1h1hhh1hhhhh1hhhhhhh1huhuhunhhhnuhhnuh1h1hnnnhhnnhnhnhuhuhnnhh1h1hhhhh1hhh1hhh1h1h1hhh1hhhhh1h1h1h1h1h1h1h
1h1h1hhh1hhh1h1h1hhh1h1h1hhhhh1h1h1hhhhhhh1hhh1hhhhh1h1hhhhh1h1hhh1h1h1hhhhhhhhh1hhhhh1hhh1hhh1hhhhh1h1h1h1h1h1hhhhhhhhhhhhhhhhh
hh1h1hhh1hhh1hhh1hhh1h1hhhhhhhhhhh1h1h1hhh1h1h1hhhhh1h1hhh1hhh1h1h1hhh1hhhhh1h1hhh1hhhhh1h1hhhhh1hhhhhhh1h1hhh1hhh1hhh1hhh1hhh1h
hhhh1h1h1hhh1h1h1hhh1hhhhhhh1h1h1h1hhhhh1h1hhh1hhh1h1h1h1hhh1hhh1hhhhhhhhh1hhh1hhh1h1hhhhhhhhhhhhhhh1hhhhh1h1hhh1hhh1h1h1hhhhhhh
hhhh1hhhhh1hhhhhhh1hhh1hhh1h1hhhhhhh1hhh1hhh1h1h1hhhhhhhhh1hhh1h1h1hhh1h1h1hhh1hhhhh1hhh1hhhhhhh1hhh1h1hhhhhhh1hhh1h1hhh1h1hhh1h
hh1h1h1h1h1h1hhhhh1hhhhhhhhh1h1h1hhh1h1hhh1hhh1hhh1h1h1h1hhh1hhhhh1hhh1h1hhh1h1hhh1hhh1h1hhh1h1hhh1h1hhh1h1h1h1hhhhhhhhhhhhhhh1h
hh1hhh1hhh1h1hhhhhhhhh1h1h1h1hhhhhhhhhhhhhhh1h1h1h1h1hhhhhhhhhhh1hhh1h1hhh1hhh1hhh1h1h1hhhhhhh1h1hhhhh1h1hhhhh1h1h1hhhhh1h1hhh1h
hh1h1hhhhhhh1hhh1h1hhh1hhhhhhh1hhh1hhhhh1h1hhh1hhhhh1h1h1h1h1h1h1h1h1h1hhh1h1hhhhhhhhh1h1h1h1hhh1h1hhhhh1h1hhh1hhhhhhh1hhhhhhh1h
1h1hhhhhhh1h1hhh1h1hhh1hhhhh1hhhhh1hhhhhhhhh1hhh1h1h1h1h1hhhhh1h1h1hhh1hhh1h1h1h1hhhhhhhhhhhhhhhhh1hhhhh1hhh1h1h1h1hhh1h1hhhhhhh
hhhh1hhhhh1h1hhhhh1h1hhh1h1h1hhhhh1h1hhhhhhhhh1h1hhhhhhhhh1hhhhhhhhh1hhh1h1hhhhh1hhh1h1hhh1h1h1hhhhhhh1hhhhh1hhh1h1h1h1h1h1h1hhh
1h1h1hhh1hhh1h1hhhhhhh1hhh1h1hhh1hhh1hhhhh1hhh1hhhhh1h1hhh1h1hhh1hhhhhhh1h1hhh1hhh1h1hhhhh1h1hhh1h1h9h1hhh1h1hhhhh1hhhhhhhhhhhhh
1h1h1hha1h1hhhhh1hhh1hhhhh1h1hhhhhhhhhhh1hhhunuhhnnhun1hhh1hnnhhuhuh1h1hnhuhunhhuhnh1hhhhh1h1h1hhhhh1h1hhhhh1hhh1h1h1hhhhhhh1hhh
1h1h1hhh1h1h1hhhhhhhhh1h1h1h1hhh1hhh1h1hhh1hunuhuhnhuhuhhh1hunhhnnnh1hhhnn1hnhnh1nhh1hhhhh1hhh1hhhhhhh1hhh1hhhhh1hhhhhhhhh1hhh1h
hhhhhhhh1hhh1h1h1hhhhhhh1h1hhhhh1h1hhh1hhh1huhnhuhuhuhnhhhhhnhnhhhnhhhhhuhnhnhnh1n1hhh1hhh1h1h1hhhhhhh1hhhhhhh1h1h1hhhhh1hhh1h1h
hhhhhh1hhh1h1h1h1h1h1h1hhh1hhh1h1h1hhhhh1hhhuhnhnn1hunhh1h1hunnhnnhh1hhhuhnhnn1huhnh1h1hhhhhhhhh1h1h1h1hhhhhhhhh1h1h1hhhhhhh1hhh
1h1hhhhhhhhh1h1hhh1h1hhh1h1hhh1h1hhhhh1hhhhhhhhh1hhhhhhhhh1h1hhhhhhhhhhh1hhh1hhh1h1h1h1h1hhh1h1hhhhh1h1hhh1hhh1h1h1hahhh1h1hhhhh
hh1hhhhh1h1h1hhh1hhh1hhhhh1hhhhh1h1hhh1hhh1hhhhh1hhh1h1h1hhhhh1h1h1h1h1hhhhh1hhhhhhh1h1h1h1h1hhhhh1hhhhhhhhhhh1hhh1hhhhhhhhhhhhh
hhhh1hhh1h1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h1hhh1h1h1hhh1h1h1hhhhh1hhh1h1hhh1hhhhhhhhh1h1h1hhh1h1hhh1h1hhhhhhh1h1h1hhhhhhhhhhh1h1h1h
1hhhhh1hhhhh1h1h1hhh1h1h1h1h1hhhhhhhhh1hhh1hhhhhhh1h1hhh1hhhhhhhhh1hhhhh1hhhhh1h1h1hhh1hhhhhhh1h1hhh1hhhhh1hhhhh1hhhhhhh1hhh1h1h
1h1hhhhh1hhh1hhh1h1hhhhh1h1h1h1hhh1hhhhhhh1h1h1hhhhhhh1h1hhh1hhh1hhh1hhh1hhh1h1hhh1hhhhh1h1h1hhh1hhh1h1hhh1hhhhh1h1hhh1hhh1hhh1h
1hhh1hhhhhhh1h1h1hhh1hhh1hhhhh1hhh1hhhhhhhhh1h1hhhhhhh1hhhhh1h1hhhhhhh1h1h1hhhhhhh1h1h1h1h1h1hhhhhhhhh1h1h1hhhhhhh1h1h1h1hhhhhhh
hhhh1h1h1h1h1hhhhh1hhhhhhhhhhhhhhhhhhh1h1hhhhh1h1h1hhh1h1h1h1hhh1hhh1hhh1h1hhh1hhhhhhh1hhh1hhhhhhh1hhh1hhhhh1hhh1hhhhh1hhhhh1hhh

__gff__
0000000000000000000000000000000004020000000000000000000200000000030303030303030303040402020000000303030303030303040404020202020200001313131302020302020202020202000013131313020204020202020202020000131313130004040202020202020200001313131300000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
312b0032312125323231253232313131312b3b32222120202222222122202232000000003b22223225323232000000002828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21003b21211b1b000000000000000031000000322220212b0000001b1b20212111000000001b1b0031313200000000002828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
250000253100000011110000000000210000112121222b0000110000001b1b323121001100000000001b00003b3222002828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2521001b1b0011113231110000003b25002232222b0000001132312b00000031203221212b001100000000003b2121312828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21250000000031312221252b00003232001b203200001111312221110000001b202532313121252b00000000003221222828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25321111000021251b0000003b22313200002020003b2222222132320000000021321b0000001b0000000000003b25212828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25212525111125210000000011252122000032320000001b2120323200000021222500000011110000000000003b32312828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3225223131323200000000003225213200003231220011003132221b00001121213200003b32232b00001111000022002828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0031253225252b000000110025212231003b22322122210032210000003b2131321b0000001b1b00003b23212b0021002828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002500320000000000220022322222000000202032000022312b00003b22221b0011001111000000001b1b000000002828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003100000000000011252221212522110000322200002131222b0000003222003b22212532000011110011000000002828282828282828282828282828282800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000021323132252122311100220000313132220000003b322200001b003b250000223221222b0000001b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002532322525223131210000001121212b00000011002220000000000025000031212232000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000011002532213231222121312b0021313231000001002200003200001101003211003b322100000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000001000000003200223221313231312000000000322100002121312000000000113132253125000031222b000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31313232000022252232322531252532310000000021003b3232313231002121003131212531310000322200000022320000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
011000201c77523050187751a0501c655237751a05018050237751c050230501a05018655230501c7751a05018775230501c775230501a65518775230501c050237751a05018050230501c6551a0501877523655
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
02 554a5644
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

