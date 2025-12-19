pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- scoliosis

--[[
	credits:
		maddy thorson and noel berry - made the original game
		ahumanhuman - made most of the mod
		vei - made the first level (egg?!) and helped plan
	scrapped things:
		more levels
		2nd dash
		2 npcs
		my sanity
		deeper lore stuff
]]


poke(0X5F5C,255)

function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

local _g = _ENV

--global tables
objects,got_fruit={},{}
--local? timers
local freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
--global camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

-- [entry point]

function _init()
	frames,start_game_flash=0,0
	
	upd=celeste_upd
	drw=celeste_drw
		
	dialogue,dialogue_timer,
	show_dialogue,shown_dialogue,
	dialogue_speed=
	"",0,false,"",2
	dialogue_str_split={}
	show_quest_accept_box=false
	quest=0
	quest_count=0
	finished_flower_quest=false
	raw_eggs,eggs,eggs_cooked,eggs_fed=0,0,0,0
	has_blahaj = false
	
	music(40,0,7)
	lvl_id=0
end

function begin_game()
	max_djump=1
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,1
	music(0,0,7)

	load_level(1, 4)
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
	upd()
end

function celeste_upd()

	if has_blahaj then
		menuitem(1,"fEED bLAHAJ",function()
			should_feed_blahaj=true
		end)
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
			load_level(lvl_id, lvl_spawn_direction)
		end
	end

	-- update each object
	foreach(objects,function(_ENV)
		move(spd.x,spd.y,0);
		(type.update or stat)(_ENV)
	end)

	--move camera to player
	foreach(objects,function(obj)
		if obj.type==player or obj.type==player_spawn then
			move_camera(obj)
		end
	end)

	if not show_quest_accept_box and show_dialogue then
		update_dialogue()
	end
	update_quest()
	
	-- start game
	if is_title() then
		if start_game then
			start_game_flash-=1
			if start_game_flash<=-30 then
				begin_game()
			end
		elseif btn(🅾️) or btn(❎) then
			music"-1"
			start_game_flash,start_game=5,true
			sfx"38"
		end
	end
end
-->8
-- [draw loop]

function _draw()
	drw()
end

function celeste_drw()
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
		spr(76,60,32)
		sspr(us"72,40,56,16,36,40")
		sspr(us"112,56,16,8,76,56")
		spr(121,36,56)
		pset(44,56,12)
		?"🅾️/❎",55,80,5
		?"maddy thorson",40,96,5
		?"noel berry",46,102,5
		draw_centered_text("mod by: AHUMANHUMAN",112,5)

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


	camera()
	
	--draw quest
	if quest and not show_dialogue and quest!=0 then
		draw_quest()
	end
	if show_quest_accept_box then
		draw_quest_accept_box()
	end

	-- draw level title
	
	if ui_timer>=-30 then
		if ui_timer<0 then
			draw_ui()
		end
		ui_timer-=1
	end

	-- draw dialogue
	-- dialogue should appear above the ui (timer and stuff)
	if show_dialogue then
		rectfill(1,1,75,33,0)
		rect(1,1,75,33,7)
		?shown_dialogue,3,3,7
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
	print(two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,7)
end

function draw_ui()
	if (lvl_title) rectfill(24,58,104,70,0) ?lvl_title,64-#lvl_title*2,62,7
	draw_time(4,4)
end
-->8
-- [player class]

player={
	init=function(_ENV)
		grace,jbuffer=0,0
		djump=max_djump
		dash_time,dash_effect_time=0,0
		dash_target_x,dash_target_y=0,0
		dash_accel_x,dash_accel_y=0,0
		hitbox=rectangle(1,3,6,5)
		spr_off=0
		collides=true
		create_hair(_ENV)
		
		
		layer=1
	end,
	update=function(_ENV)
		if pause_player then
			return
		end
		if lvl_id==1 then
			hitbox=rectangle(2,4,4,4)
		end

		-- horizontal input
		local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0

		-- spike collision / bottom death
		if spikes_at(left(),top(),right(),bottom(),spd.x,spd.y) or 
		(y>lvl_ph and lvl_exits&0b0010 != 2) then
			kill_player(_ENV)
		end

		-- on ground checks
		local on_ground=is_solid(0,1)

		-- landing smoke
		if on_ground and not was_on_ground then
			init_smoke(0,4)
		end

		-- jump and dash input
		local jump,dash=btn(🅾️) and not p_jump,btn(❎) and not p_dash
		p_jump,p_dash=btn(🅾️),btn(❎)

		-- jump buffer
		if jump then
			jbuffer=4
		elseif jbuffer>0 then
			jbuffer-=1
		end

		-- grace frames and dash restoration
		if on_ground then
			grace=6
			if djump<max_djump then
				psfx"54"
				djump=max_djump
			end
		elseif grace>0 then
			grace-=1
		end

		-- dash effect timer (for dash-triggered events, e.g., berry blocks)
		dash_effect_time-=1

		-- dash startup period, accel toward dash target speed
		if dash_time>0 then
			if dash_time>2 then
				init_smoke()
			end
			dash_time-=1
			spd=vector(appr(spd.x,dash_target_x,dash_accel_x),appr(spd.y,dash_target_y,dash_accel_y))
		else
			-- x movement
			local maxrun=1
			local accel=is_ice(0,1) and 0.05 or on_ground and 0.6 or 0.4
			local deccel=0.15

			-- set x speed
			spd.x=cracked and 0 or abs(spd.x)<=1 and
			appr(spd.x,h_input*maxrun,accel) or
			appr(spd.x,sign(spd.x)*maxrun,deccel)

			-- facing direction
			if spd.x~=0 then
				flip.x=spd.x<0
			end

			-- y movement
			local maxfall=2

			-- wall slide
			if h_input~=0 and is_solid(h_input,0) and not is_ice(h_input,0) then
				maxfall=0.4
				-- wall slide smoke
				if rnd"10"<2 then
					init_smoke(h_input*6)
				end
			end

			-- apply gravity
			if not on_ground then
				spd.y=appr(spd.y,maxfall,abs(spd.y)>0.15 and 0.21 or 0.105)
			end

			-- jump
			if jbuffer>0 and lvl_id!=1 then
				if grace>0 then
					-- normal jump
					psfx"1"
					jbuffer=0
					grace=0
					spd.y=-2
					init_smoke(0,4)
				else
					-- wall jump
					local wall_dir=(is_solid(-3,0) and -1 or is_solid(3,0) and 1 or 0)
					if wall_dir~=0 then
						psfx"2"
						jbuffer=0
						spd=vector(wall_dir*(-1-maxrun),-2)
						if not is_ice(wall_dir*3,0) then
							-- wall jump smoke
							init_smoke(wall_dir*6)
						end
					end
				end
			end

			-- dash
			local d_full=5
			local d_half=3.5355339059 -- 5 * sqrt(2)

			if upd==celeste_upd and djump>0 and dash and not cracked then
				init_smoke()
				djump-=1
				dash_time=4
				_g.has_dashed=true
				dash_effect_time=10
				-- vertical input
				local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0
				-- calculate dash speeds
				spd=vector(h_input~=0 and
					h_input*(v_input~=0 and d_half or d_full) or
					(v_input~=0 and 0 or flip.x and -1 or 1)
				,v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0)
				-- effects
				psfx"3"
				freeze=2
				-- dash target speeds and accels
				dash_target_x=2*sign(spd.x)
				dash_target_y=(spd.y>=0 and 2 or 1.5)*sign(spd.y)
				dash_accel_x=spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
				dash_accel_y=spd.x==0 and 1.5 or 1.06066017177
			elseif djump<=0 and dash then
				-- failed dash smoke
				psfx"9"
				init_smoke()
			end
		end

		-- animation
		spr_off+=0.25
		sprite = not on_ground and (is_solid(h_input,0) and 5 or 3) or	-- wall slide or mid air
		btn(⬇️) and 6 or -- crouch
		btn(⬆️) and 7 or -- look up
		spd.x~=0 and h_input~=0 and 1+spr_off%4 or 1 -- walk or stand

		if _g.should_feed_blahaj then 
			_g.should_feed_blahaj=false
			if eggs>0 then
				feed_blahaj(_ENV)
			else
				init_object(lifeup,x,y-4,0).text="no cooked eggs"
			end
		end

		-- top of level
		if y<-4 and (lvl_exits >> 3) & 1 == 1 then
			load_level(tonum(tostr(lvl_exits_destinations, true)[3]),3)
		end

		-- right of level
		if x>lvl_pw-6 and (lvl_exits >> 2) & 1 == 1 then
			load_level(tonum(tostr(lvl_exits_destinations, true)[4]),4)
		end

		-- bottom of level
		if y>lvl_ph-4 and (lvl_exits >> 1) & 1 == 1 then
			load_level(tonum(tostr(lvl_exits_destinations, true)[5]),1)
		end

		-- left of level
		if x<0 and (lvl_exits >> 0) & 1 == 1 then
			load_level(tonum(tostr(lvl_exits_destinations, true)[6]),2)
		end

		-- was on the ground
		was_on_ground=on_ground
	end,

	draw=function(_ENV)
		-- clamp in screen
		local clamped=mid(x,-1,lvl_pw-7)
		if x~=clamped then
			x=clamped
			spd.x=0
		end
		-- draw player hair and sprite
		set_hair_color(djump)
		
		if lvl_id!=1 then
			draw_hair(_ENV)
		elseif not cracked then
			sprite=77
		else
			local o,s=0,0.7
			if spr_off then
				o=spr_off*s<3 and spr_off*s%3 or 2
				if spr_off*s>6 then
					load_level(2,1)
				end
				if spr_off*s>3 then
					o=-76
					draw_top_hat(_ENV)
				end
			end
			sprite=77+o
		end
		draw_obj_sprite(_ENV)
		pal()
		
		if (lvl_id==1 and cracked and spr_off and spr_off*0.7>3) or lvl_id!=1 then
			-- torp hat
			draw_top_hat(_ENV)
		end
		
	end
}

function draw_top_hat(_ENV)
	rectfill(x+2,y+1,x+5,y-3-eggs_fed*3,6)
end

function create_hair(obj)
	obj.hair={}
	for i=1,5 do
		add(obj.hair,vector(obj.x,obj.y))
	end
end

function feed_blahaj(this)
	eggs-=1
	eggs_fed+=1
	should_feed_blahaj=false
	local blahaj_to_feed=this.blahaj
	blahaj_to_feed.mouth_open=true
	blahaj_to_feed.timer=30
end

function set_hair_color(djump)
	pal(2,djump==1 and 2 or djump==2 and 10+frames\3%3*2 or 3)
end

function draw_hair(obj)
	local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x,h.y,mid(4-i,1,2),2)
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
	init=function(_ENV)
		
		sfx"4"
		target=y
		y=sprite==1 and 0 or min(y+48,lvl_ph)
		_g.cam_x,_g.cam_y=mid(x+4,64,lvl_pw-64),mid(y,64,lvl_ph-64)
		spd.y=-4
		state=sprite==1 and 2 or 0
		init_sprite=sprite
		sprite=3
		delay=0
		create_hair(_ENV)
		djump=max_djump
		
		--spawn blahaj
		if has_blahaj then
			blahaj=init_object(_g.blahaj,x,y,0)
			blahaj.parent=_ENV
		end
		
		layer=1
	end,
	update=function(_ENV)
		-- jumping up
		if state==0 and y<target+16 then
			state=1
			delay=3
		-- falling
		elseif state==1 then
			spd.y+=0.5
			if spd.y>0 then
				if delay>0 then
					-- stall at peak
					spd.y=0
					delay-=1
				elseif y>target then
					-- clamp at target y
					y=target
					spd=vector(0,0)
					state=2
					delay=5
					init_smoke(0,4)
					sfx"5"
				end
			end
			-- landing and spawning player object
		elseif state==2 then
			delay-=1
			sprite=6
			if delay<0 then
				destroy_object(_ENV)
				local p=init_object(player,x,y)
				if init_sprite==1 then
					p.spd.y=2
				end
				p.blahaj=blahaj
				blahaj.parent=p
			end
		end
	end,
	draw= player.draw
}
-->8
--[objects]

--[[
	i had to minify the code because
	the cart couldnt be turned into
	a png/cart image
	
	you can find the original, un-minified
	code at :
	https://gist.github.com/wywy21/11927dfaf240a308fc47b5e424822e93
]]

door={
init=function(_ENV)
hitbox=rectangle(0,0,8,32)
solid_obj=true
timer=.5
end,
update=function(_ENV)
hitbox=rectangle(-16,-16,32,64)
local hit=player_here()
draw_text=hit
if hit and eggs_fed>=3and timer==.5do
timer=30
end
if timer>0and timer~=.5do
timer-=1
elseif timer~=.5do
destroy_object(_ENV)
end
hitbox=rectangle(0,0,8,32)
end,
draw=function(_ENV)
local off=timer==.5and 0or abs(timer/2-15)
printh(off)
rectfill(x,y,x+7,y+16-off,12)
rectfill(x,y+31,x+7,y+16+off)
line(x,y,x,y+31,7)
line(x+7,y,x+7,y+31)
if draw_text do
?"²7you need\nto have fed\nyour blahaj\n3 eggs",x-40,y+5,12
end
end
}
seed_pack={
check_fruit=true,
update=function(_ENV)
local hit=player_here()
if hit and hit.is_solid(0,1)and not pause_player and btnp(❎)do
_g.has_seed_pack=true
_g.got_fruit[fruit_id]=true
destroy_object(_ENV)
end
end,
draw=function(_ENV)
draw_obj_sprite(_ENV)
local hit=player_here()
if hit and hit.is_solid(0,1)and not pause_player do
?"❎",x,y-6,7
end
end
}
blahaj={
init=function(_ENV)
start=y
sy=y
off=0
tx=x
ty=y
timer=-100
end,
update=function(_ENV)
--[[
	follow code from ooooggll's
	golden berry mod:
	https://www.lexaloffle.com/bbs/?tid=46452
]]
if parent do
local p=parent
tx+=.2*(p.x-tx)
ty+=.2*(p.y-ty)
local a,k=atan2(x-tx,sy-ty),(x-tx)^2+(sy-ty)^2>144and.2or.1
x+=k*(tx+12*cos(a)-x)
sy+=k*(ty+12*sin(a)-sy)
off+=1
y=sy+sin(off/40)*2.5
if k*(tx+12*cos(a)-x)~=0do
flip.x=k*(tx+12*cos(a)-x)<0
end
end
if timer>-30do
timer-=1
if timer<0do
mouth_open=false
end
end
end,
draw=function(_ENV)
spr(122,x-(flip.x and 0or 8),y,1,1,flip.x,flip.y)
spr(mouth_open and 125or 123,x-(flip.x and 8or 0),y,1,1,flip.x,flip.y)
if timer>0do
local s=timer/3
sspr(96,56,8,8,x+(flip.x and-s-5or 5),y+s/2+4,s,s)
elseif timer>-30do
?"♥",x+cos(off/10)-(flip.x and 8or 0),y+sin(off/10),8
end
end
}
egg_cracker={
init=function(_ENV)
hitbox=rectangle(-8,0,32,8)
end,
update=function(_ENV)
local hit=player_here()
if hit and not hit.cracked do hit.cracked=true hit.spr_off=0
end end,
draw=function()end
}
stove={
init=function(_ENV)
sprite=75
hitbox=rectangle(0,0,16,16)
end,
update=function(_ENV)
local hit=player_here()
if hit and btnp(❎)and not pause_player
and hit.is_solid(0,1)do
if raw_eggs>0do
init_mini_game()
transition(mini_game_upd,mini_game_drw)
else
init_object(lifeup,x-8,y,0).text="no raw eggs"
end
end
end,
draw=function(_ENV)
if tile_at(x/8,y/8+1)==75do
draw_obj_sprite(_ENV)
end
palt(14,true)
pal(split"1,1,1,1,1,1,1,1,1,1,1,1,1,1,1")
for _x=-1,1,2do
for _y=-1,0do
sspr(0,48,16,16,x+_x,y+_y)
end
end
pal()
palt(14,true)
palt(0,false)
sspr(0,48,16,16,x,y)
pal()
local hit=player_here()
if hit and hit.is_solid(0,1)and not pause_player do
?"❎",x+5,y-6,7
end
end
}
flower={
check_fruit=true,
update=function(_ENV)
local hit=player_here()
if hit and btnp(❎)and not pause_player
and hit.is_solid(0,1)and quest==62do
destroy_object(_ENV)
_g.got_fruit[fruit_id]=true
_g.quest_count-=1
if _g.quest_count<=0do
_g.finished_flower_quest=true
end
end
end,
draw=function(_ENV)
local hit=player_here()
if hit and hit.is_solid(0,1)and not pause_player and quest==62do
?"❎",x+1,y-6,7
end
draw_obj_sprite(_ENV)
end
}
big_flower={
init=function(_ENV)
hitbox=rectangle(us(({
[132]="4,14,8,2",
[145]="2,6,4,2",
[146]="2,6,4,2"
})[sprite]))
end,
update=function(_ENV)
local hit=player_here()
if hit do
kill_player(hit)
end
end,
draw=function(_ENV)
local sspr_places={
[132]="32,64,16,16",
[145]="8,72,8,8",
[146]="16,72,8,8"
}
sspr(us(sspr_places[sprite]..","..tostr(x)..","..tostr(y)))
end
}
npc={
check_fruit=true,
init=function(_ENV)
flip.x=check(npc_flipper,0,-1)
end,
update=function(_ENV)
local hit=player_here()
if hit and btnp(❎)and not pause_player
and hit.is_solid(0,1)and not npc.dialogue[sprite].finished(_ENV,npc.dialogue[sprite])do
text=npc.dialogue[sprite].update(_ENV,npc.dialogue[sprite])
if text do start_dialogue(_ENV,text)
end hit.spd=vector(0,0)
end
end,
draw=function(_ENV)
local hit=player_here()
if hit and hit.is_solid(0,1)and not pause_player
and not npc.dialogue[sprite].finished(_ENV,npc.dialogue[sprite])do
?"❎",x,y-6,7
end
draw_obj_sprite(_ENV)
end,
dialogue={
[28]={
dia={
[[hELLO!
iT'S ME aDELIE...
]],
[[aRE YOU NEW 
AROUND HERE? i 
HAVEN'T SEEN YOU 
BEFORE...
]],
[[hERE EVERYTHING
REVOLVES AROUND
eggs!!!     ...
]],
[[i HAVE A SPARE
EGG THAT i CAN
GIVE YOU TO GET
YOU STARTED...
]],
[[dOWN BELOW, THERE
IS A STOVE WHERE
YOU CAN COOK THAT
EGG. cOME BACK
WHEN YOUR DONE.
]],
[[yay! yOU DID IT!!
I'D TAKE THE EGG
BACK FROM YOU BUT
i HAVE A BETTER
IDEA...
]],
[[i FOUND THIS COOL
PLUSH IN MY
BASEMENT. i WAS
WONDERING IF YOU
WOULD LIKE IT...
]],
[[dID YOU SAY NO?!?
wELL TOO BAD,
YOU'RE TAKING IT
ANYWAY.
]],
[[tHANKS FOR TAKING
THIS FROM ME. yOU
CAN FEED IT THAT
COOKED EGG YOU
MADE. I GOTTA GO!
]]
},
state=1,
update=function(this,NPC)
local dia=NPC.dia
if NPC.state==8and quest_acception do
NPC.state+=1
end
if NPC.state==9do
has_blahaj=true
local blahaj,player=init_object(blahaj,this.x,this.y,0),find_player()
player.blahaj=blahaj
blahaj.parent=player
init_object(lifeup,this.x-12,this.y-4,0).text="got blahaj"
end
str=dia[NPC.state]
return str
end,
on_end=function(this,NPC)
if NPC.state==4do
raw_eggs+=1
init_object(lifeup,this.x-14,this.y-4,0).text="+1 raw egg"
end
if NPC.state==7do
asking_for_blahaj=true
open_quest_box(0,0)
end
NPC.state+=1
if NPC.state>#NPC.dia do
destroy_object(this)
got_fruit[this.fruit_id]=true
init_object(lifeup,this.x-20,this.y-4,0).text="new menuitem"
end
end,
finished=function(this,NPC)
if eggs>0do
return NPC.state>#NPC.dia
else
return NPC.state>5
end
end
},
[134]={
dia={
[[i'M MAKING A NICE
BOUQUET FOR SOME
ONE AND NEED SOME 
FLOWERS, COULD YOU 
COLLECT 20 FLOWERS
]],[[i HAVE A REWARD
FOR YOU IF YOU 
BRING ME THEM.
]],
[[tHANK YOU A TON,
HERE IS AN EGG,
STAY SAFE OUT
THERE.
]]
},
state=1,
update=function(this,NPC)
return NPC.dia[NPC.state]
end,
on_end=function(this,NPC)
if NPC.state==2do
quest=62
quest_count=20
end
if NPC.state>#NPC.dia-1do
raw_eggs+=1
init_object(lifeup,this.x-14,this.y-4,0).text="+1 raw egg"
end
NPC.state+=1
end,
finished=function(this,NPC)
return NPC.state>(finished_flower_quest and 3or 2)
end
},
[150]={
dia={
[[i LOST MY SEEDS
DOWN BELOW, COULD
YOU PLEASE GRAB
THEM FOR ME?
]],[[pLEASE BE CAREFUL
ABOUT MY FLOWERS,
i'D HATE TO HAVE
THEM TRAMPLED
]],[[tHANK YOU SO
MUCH, I HAVE AN
EGG FOR YOU.
]]
},
state=1,
update=function(this,NPC)
if has_seed_pack do NPC.state=3
end return NPC.dia[NPC.state]
end,
on_end=function(this,NPC)
NPC.state+=1
if NPC.state==4do
raw_eggs+=1
init_object(lifeup,this.x-14,this.y-4,0).text="+1 raw egg"
end
end,
finished=function(this,NPC)
return NPC.state==(has_seed_pack and 4or 3)
end
}
}
}
npc_flipper={draw=function()end}
spring={
init=function(_ENV)
delta=0
dir=sprite==18and 0or is_solid(-1,0)and 1or-1
show=true
layer=-1
end,
update=function(_ENV)
delta=delta*.75
local hit=player_here()
if show and hit and delta<=1do
if dir==0do
hit.move(0,y-hit.y-4,1)
hit.spd.x*=.2
hit.spd.y=-3
else
hit.move(x+dir*4-hit.x,0,1)
hit.spd=vector(dir*3,-1.5)
end
hit.dash_time=0
hit.dash_effect_time=0
hit.djump=max_djump
delta=8
psfx"8"
init_smoke()
break_fall_floor(check(fall_floor,-dir,dir==0and 1or 0))
end
end,
draw=function(_ENV)
if show do
local delta=min(flr(delta),4)
if dir==0do
sspr(16,8,8,8,x,y+delta)
else
spr(19,dir==-1and x+delta or x,y,1-delta/8,1,dir==1)
end
end
end
}
fall_floor={
init=function(_ENV)
solid_obj=true
state=0
end,
update=function(_ENV)
if state==0do
for i=0,2do
if check(player,i-1,-(i%2))do
break_fall_floor(_ENV)
end
end
elseif state==1do
delay-=1
if delay<=0do
state=2
delay=60
collideable=false
set_springs(_ENV,false)
end
elseif state==2do
delay-=1
if delay<=0and not player_here()do
psfx"7"
state=0
collideable=true
init_smoke()
set_springs(_ENV,true)
end
end
end,
draw=function(_ENV)
spr(state==1and 26-delay/5or state==0and 23,x,y)
end
}
function break_fall_floor(_ENV)
if _ENV and state==0do
psfx"15"
state=1
delay=15
init_smoke()
end
end
function set_springs(_ENV,state)
hitbox=rectangle(-2,-2,12,8)
local springs=check_all(spring,0,0)
foreach(springs,function(s)s.show=state end)
hitbox=rectangle(0,0,8,8)
end
balloon={
init=function(_ENV)
offset=rnd()
start=y
timer=0
hitbox=rectangle(-1,-1,10,10)
end,
update=function(_ENV)
if sprite==22do
offset+=.01
y=start+sin(offset)*2
local hit=player_here()
if hit and hit.djump<max_djump do
psfx"6"
init_smoke()
hit.djump=max_djump
sprite=0
timer=60
end
elseif timer>0do
timer-=1
else
psfx"7"
init_smoke()
sprite=22
end
end,
draw=function(_ENV)
if sprite==22do
for i=7,13do
pset(x+4+sin(offset*2+i/10),y+i,6)
end
draw_obj_sprite(_ENV)
end
end
}
smoke={
init=function(_ENV)
spd=vector(.3+rnd"0.2",-.1)
x+=-1+rnd"2"
y+=-1+rnd"2"
flip=vector(rnd()<.5,rnd()<.5)
layer=3
end,
update=function(_ENV)
sprite+=.2
if sprite>=32do
destroy_object(_ENV)
end
end
}
fruit={
check_fruit=true,
init=function(_ENV)
start=y
off=0
end,
update=function(_ENV)
check_fruit(_ENV)
off+=.025
y=start+sin(off)*2.5
end
}
fly_fruit={
check_fruit=true,
init=function(_ENV)
start=y
step=.5
sfx_delay=8
end,
update=function(_ENV)
if has_dashed do
if sfx_delay>0do
sfx_delay-=1
if sfx_delay<=0do
sfx_timer=20
sfx"14"
end
end
spd.y=appr(spd.y,-3.5,.25)
if y<-16do
destroy_object(_ENV)
end
else
step+=.05
spd.y=sin(step)*.5
end
check_fruit(_ENV)
end,
draw=function(_ENV)
spr(26,x,y)
for ox=-6,6,12do
spr((has_dashed or sin(step)>=0)and 45or y>start and 47or 46,x+ox,y-2,1,1,ox==-6)
end
end
}
function check_fruit(_ENV)
local hit=player_here()
if hit do
hit.djump=max_djump
sfx_timer=20
sfx"13"
got_fruit[fruit_id]=true
init_object(lifeup,x,y)
if _g.quest==26do
_g.quest_count-=1
end
destroy_object(_ENV)
if time_ticking do
_g.fruit_count+=1
end
end
end
lifeup={
init=function(_ENV)
spd.y=-.25
duration=30
flash=0
text="1000"
end,
update=function(_ENV)
duration-=1
if duration<=0do
destroy_object(_ENV)
end
end,
draw=function(_ENV)
flash+=.5
?text,x-4,y-4,7+flash%2
end
}
fake_wall={
check_fruit=true,
init=function(_ENV)
solid_obj=true
hitbox=rectangle(0,0,16,16)
end,
update=function(_ENV)
hitbox=rectangle(-1,-1,18,18)
local hit=player_here()
if hit and hit.dash_effect_time>0do
hit.spd=vector(sign(hit.spd.x)*-1.5,-1.5)
hit.dash_time=-1
for ox=0,8,8do
for oy=0,8,8do
init_smoke(ox,oy)
end
end
init_fruit(_ENV,4,4)
end
hitbox=rectangle(0,0,16,16)
end,
draw=function(_ENV)
sspr(0,32,8,16,x,y)
sspr(0,32,8,16,x+8,y,8,16,true,true)
end
}
function init_fruit(_ENV,ox,oy)
sfx_timer=20
sfx"16"
init_object(fruit,x+ox,y+oy,26).fruit_id=fruit_id
destroy_object(_ENV)
end
key={
update=function(_ENV)
sprite=flr(9.5+sin(frames/30))
if frames==18do
flip.x=not flip.x
end
if player_here()do
sfx"23"
sfx_timer=10
destroy_object(_ENV)
_g.has_key=true
end
end
}
chest={
check_fruit=true,
init=function(_ENV)
x-=4
start=x
timer=20
end,
update=function(_ENV)
if has_key do
timer-=1
x=start-1+rnd"3"
if timer<=0do
init_fruit(_ENV,0,-4)
end
end
end
}
cloud={
init=function(_ENV)
x-=4
hitbox.w=16
dir=sprite==11and-1or 1
semisolid_obj=true
layer=2
end,
update=function(_ENV)
spd.x=dir*.65
if x<-16do
x=lvl_pw
elseif x>lvl_pw do
x=-16
end
end,
draw=function(_ENV)
spr(11,x,y-1,2,1)
end
}
message={
init=function(_ENV)
text="-- celeste mountain --#this memorial to those#who didn't use freedom mode#in labyrinth"
hitbox.x+=4
layer=4
end,
draw=function(_ENV)
if player_here()do
for i,s in ipairs(split(text,"#"))do
camera()
rectfill(7,7*i,120,7*i+6,7)
?s,64-#s*2,7*i+1,0
camera(draw_x,draw_y)
end
end
end
}
big_chest={
init=function(_ENV)
state=max_djump>1and 2or 0
hitbox.w=16
end,
update=function(_ENV)
if state==0do
local hit=check(player,0,8)
if hit and hit.is_solid(0,1)do
music(-1,500,7)
sfx"37"
pause_player=true
hit.spd=vector(0,0)
state=1
init_smoke()
init_smoke(8)
timer=6
particles={}
end
elseif state==1do
timer-=1
flash_bg=true
if timer<=45and#particles<50do
add(particles,{
x=1+rnd"14",
y=0,
h=32+rnd"32",
spd=8+rnd"8"})
end
if timer<0do
state=2
particles={}
flash_bg,bg_col,cloud_col=false,0,13
init_object(orb,x+4,y+4,102)
pause_player=false
end
end
end,
draw=function(_ENV)
if state==0do
draw_obj_sprite(_ENV)
spr(65,x+8,y,1,1,true)
elseif state==1do
foreach(particles,function(p)
p.y+=p.spd
line(x+p.x,y+8-p.y,x+p.x,min(y+8-p.y+p.h,y+8),7)
end)
end
spr(81,x,y+8)
spr(81,x+8,y+8,1,1,true)
end
}
orb={
init=function(_ENV)
spd.y=-4
end,
update=function(_ENV)
spd.y=appr(spd.y,0,.5)
local hit=player_here()
if spd.y==0and hit do
music_timer=45
sfx"51"
freeze=10
destroy_object(_ENV)
_g.max_djump=2
hit.djump=2
end
end,
draw=function(_ENV)
draw_obj_sprite(_ENV)
for i=0,.875,.125do
circfill(x+4+cos(frames/30+i)*8,y+4+sin(frames/30+i)*8,1,7)
end
end
}
flag={
update=function(_ENV)
if not show and player_here()do
sfx"55"
_g.sfx_timer,show,_g.time_ticking=30,true,false
end
end,
draw=function(_ENV)
spr(118+frames/5%3,x,y)
if show do
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
function init_object(type,x,y,tile)
local id=x..","..y..","..lvl_id
if type.check_fruit and got_fruit[id]do
return
end
local obj={
type=type,
collideable=true,
sprite=tile,
flip=vector(),
x=x,
y=y,
hitbox=rectangle(0,0,8,8),
spd=vector(0,0),
rem=vector(0,0),
layer=0,
fruit_id=id
}
setmetatable(obj,{__index=_g})
function obj.left()return obj.x+obj.hitbox.x end
function obj.right()return obj.left()+obj.hitbox.w-1end
function obj.top()return obj.y+obj.hitbox.y end
function obj.bottom()return obj.top()+obj.hitbox.h-1end
function obj.is_solid(ox,oy)
for o in all(objects)do
if o~=obj and(o.solid_obj or o.semisolid_obj and not obj.objcollide(o,ox,0)and oy>0)and obj.objcollide(o,ox,oy)do
return true
end
end
return oy>0and not obj.is_flag(ox,0,3)and obj.is_flag(ox,oy,3)or
obj.is_flag(ox,oy,0)
end
function obj.is_ice(ox,oy)
return obj.is_flag(ox,oy,4)
end
function obj.is_flag(ox,oy,flag)
for i=max(0,(obj.left()+ox)\8),min(lvl_w-1,(obj.right()+ox)/8)do
for j=max(0,(obj.top()+oy)\8),min(lvl_h-1,(obj.bottom()+oy)/8)do
if fget(tile_at(i,j),flag)do
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
for other in all(objects)do
if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy)do
return other
end
end
end
function obj.check_all(type,ox,oy)
local tbl={}
for other in all(objects)do
if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy)do
add(tbl,other)
end
end
if#tbl>0do return tbl end
end
function obj.player_here()
return obj.check(player,0,0)
end
function obj.move(ox,oy,start)
for axis in all{"x","y"}do
obj.rem[axis]+=axis=="x"and ox or oy
local amt=round(obj.rem[axis])
obj.rem[axis]-=amt
local upmoving=axis=="y"and amt<0
local riding,movamt=not obj.player_here()and obj.check(player,0,upmoving and amt or-1)
if obj.collides do
local step=sign(amt)
local d,p=axis=="x"and step or 0,obj[axis]
for i=start,abs(amt)do
if not obj.is_solid(d,step-d)do
obj[axis]+=step
else
obj.spd[axis],obj.rem[axis]=0,0
break
end
end
movamt=obj[axis]-p
else
movamt=amt
if(obj.solid_obj or obj.semisolid_obj)and upmoving and riding do
movamt+=obj.top()-riding.bottom()-1
local hamt=round(riding.spd.y+riding.rem.y)
hamt+=sign(hamt)
if movamt<hamt do
riding.spd.y=max(riding.spd.y,0)
else
movamt=0
end
end
obj[axis]+=amt
end
if(obj.solid_obj or obj.semisolid_obj)and obj.collideable do
obj.collideable=false
local hit=obj.player_here()
if hit and obj.solid_obj do
hit.move(axis=="x"and(amt>0and obj.right()+1-hit.left()or amt<0and obj.left()-hit.right()-1)or 0,
axis=="y"and(amt>0and obj.bottom()+1-hit.top()or amt<0and obj.top()-hit.bottom()-1)or 0,
1)
if obj.player_here()do
kill_player(hit)
end
elseif riding do
riding.move(axis=="x"and movamt or 0,axis=="y"and movamt or 0,1)
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
function find_player()
for obj in all(objects)do
if obj.type==player do
return obj
end
end
return nil
end
function move_camera(obj)
cam_spdx=cam_gain*(4+obj.x-cam_x)
cam_spdy=cam_gain*(4+obj.y-cam_y)
cam_x+=cam_spdx
cam_y+=cam_spdy
local clamped=mid(cam_x,64,lvl_pw-64)
if cam_x~=clamped do
cam_spdx=0
cam_x=clamped
end
clamped=mid(cam_y,64,lvl_ph-64)
if cam_y~=clamped do
cam_spdy=0
cam_y=clamped
end
end
function draw_object(_ENV)
(type.draw or draw_obj_sprite)(_ENV)
end
function draw_obj_sprite(_ENV)
spr(sprite,x,y,1,1,flip.x,flip.y)
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

function load_level(id, direction)
	has_dashed,has_key= false

	--remove existing objects
	foreach(objects,destroy_object)

	--reset camera speed
	cam_spdx,cam_spdy=0,0

	local diff_level=lvl_id~=id

	--set level index
	lvl_id=id

	lvl_spawn_direction = direction

	--set level globals
	local tbl=split(levels[lvl_id])
	for i=1,4 do
		_ENV[split"lvl_x,lvl_y,lvl_w,lvl_h"[i]]=tbl[i]*16
	end
	lvl_exits = tbl[5]
	lvl_exits_destinations = tbl[6]
	lvl_title=tbl[7]
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8

	--level title setup
	ui_timer=5

	--reload map
	if diff_level then
		reload()
		--check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
		end
	end

	-- entities
	for tx=0,lvl_w-1 do
		for ty=0,lvl_h-1 do
			local tile=tile_at(tx,ty)
			if tiles[tile] and (tiles[tile] != player_spawn or tile == direction) then
				init_object(tiles[tile],tx*8,ty*8,tile)
			end
		end
	end
end

--replace mapdata with hex
function replace_mapdata(x,y,w,h,data)
	for i=1,#data do
		local c = ord(sub(data,i,i))-1
		if c < 0 then c = 255 end
		mset(x+((i-1)%w),y+(i-1)/w,c)
	end
end
-->8
-- [metadata]

--[["x,y,w,h,
bitfield of exits (up, right, down, left)
where the exits go (single digit hex number for the room)
title"]]
levels={
	"0,0,2,1,0,0,egg?!",
	"5,1,2,2,0b0111,0x0356,hub!",
	"7,2,1,2,0b1001,0x8004",
	"6,3,1,1,0b1000,0x2000",
	"4,3,2,1,0b1000,0x2000",
	"4,2,1,1,0b1100,0x7200",
	"3,1,2,1,0b0010,0x0060",
	"7,1,1,1,0b0110,0x0930",
	"7,0,1,1,0,0,summit!"
}

--@begin
mapdata={
  nil,
  "TTU&'¹¹¹¹¹¹1,¹¹²¹¹¹<%&33333&&cTTTTU&'¹¹¹¹¹¹1,¹¹¹¹¹¹<%4,¹¹)¹2&&cTTTe&'¹¹¹¹¹¹1,¹¹¹¹¹¹<1,¹¹¹)¹¹2&&cTe&&4¹¹¹¹¹¹1,¹¹¹¹¹¹<1,¹¹¹+:¹¹%&&e&&4¹¹¹¹¹¹¹1,¹¹¹¹¹¹<1,¹¹¹¹)¹¹%&&&&4¹¹¹¹¹¹¹¹1¹¹¹¹¹¹¹¹1:¹¹¹¹+:¹%&&&4¹¹¹¹¹¹¹¹¹1¹¹¹¹¹¹¹¹%$:¹¹¹¹+)%&&'¹¹¹¹¹¹¹¹¹¹1¹¹¹¹¹¹¹¹%'9:¹¹¹¹¹2&&'¹¹¹¹¹¹¹¹¹¹1¹¹¹¹¹¹¹¹%')*¹¹¹¹;*%&'¹¹¹¹¹¹¹¹¹¹1¹¹¹¹¹¹¹¹%'9:¹¹¹;*¹%&'¹>>@¹¹@>¹¹1hYYYYYYi%&$9:¹;*¹¹%&&##########'¹¹+hi*+:%I&#$:)>>¹%&&3333333&334¹¹;)¹¹¹+23333666##&&'¹;9*¹+:1¹¹¹¹;*+:¹¹¹¹)¹¹)¹¹¹23&I';)*¹¹¹+1¹¹;9*¹¹+:¹¹;*¹¹)¹¹¹¹;2&'9*¹¹¹¹¹1:;■*¹¹¹¹+)9)¹;)*¹¹¹;*¹%4*¹¹¹¹¹¹1))*¹¹¹¹¹¹))■)*¹¹¹¹;9hi2¹¹¹¹¹¹¹;8ᵉᶠ▮(¹¹¹¹;*¹;*¹¹¹¹;*¹;*+¹¹¹¹¹¹;)):¹¹1¹¹;)*¹¹)¹¹¹¹;*¹;*¹¹¹⁵¹¹¹;9)*+:?1))*>?¹@)¹¹¹;*¹;*@?>#7ᵉᶠᶠ+■5666636666666667ᵉᶠᶠᶠ▮56##'¹¹¹¹¹+*+:¹¹¹¹¹;*¹)¹¹)¹¹¹¹;9*¹2&':¹¹¹¹¹¹¹+GH¹¹;*¹¹9¹¹+:¹;)9*¹¹¹%'):¹¹¹¹¹¹?WX>;*¹¹¹):¹;))9)*¹¹¹¹%'+9:¹¹¹¹;\"##7*¹¹¹¹+))9)))*¹¹¹¹¹%'¹+):¹¹;)%34*¹¹¹¹¹¹+)*¹¹+:¹¹¹¹?%'¹¹+9:;)98*+:¹¹¹¹¹¹¹)¹¹¹¹+:¹¹¹\"&'>¹¹+))9)*¹¹+:¹¹¹¹¹¹+):¹¹¹+:¹¹%&&$?¹;)))*¹¹¹¹+:¹¹¹¹¹¹¹+:¹¹¹+:@%&&&$;9)9*¹¹¹¹¹¹+:¹¹a¹¹¹¹)¹¹¹¹+\"&I&I&####$¹¹¹¹¹?¹+:⁴¹¹>>¹)¹¹¹¹\"&&&&&&&&I&'¹¹¹「「\"#######$ᵉᶠᶠ▮\"#&I&&",
  "333&34¹¹¹23&IcTT:¹¹1¹¹¹¹¹¹¹23&cd+:¹1¹¹¹²¹¹¹¹¹23I¹+:1ᵉᶠᶠᶠᶠ¹¹¹¹¹¹2$「「8¹¹¹¹¹¹¹¹¹¹;*'¹;*¹¹¹¹¹¹¹¹¹;9¹';*¹¹¹¹¹¹¹¹¹;*+:'*⁵¹¹¹¹¹¹¹¹;*゛¹+'ᵉᶠᶠ¹¹¹¹¹¹;*¹。¹¹'¹¹¹¹¹¹¹¹¹566###'¹¹¹¹¹¹¹¹¹¹+923&':¹¹¹¹¹¹¹¹¹¹+))2'):¹¹¹¹¹¹¹¹¹¹¹+9&$9:¹¹¹¹¹¹¹¹¹¹¹+&'+):¹¹¹¹¹¹¹¹¹¹¹&&$+9:¹¹¹¹¹¹¹?@¹334「「「¹;hYYi56##¹;)*¹¹;9*¹¹+hi2I;)hYYi)*¹¹¹¹¹+929*¹¹¹¹¹¹¹¹¹¹¹¹¹+*¹¹¹¹¹¹¹¹¹¹ᶠᶠᶠᶠ▮¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹;¹¹¹¹¹¹¹¹¹¹¹¹¹¹;*¹¹¹¹¹¹¹¹¹¹¹¹?;*\"¹¹¹¹¹¹¹¹¹¹¹;5663¹¹?¹¹¹¹¹¹¹;LLL▒▒####$>¹¹¹;LaLL➡️➡️&I&&&$¹@;*LLLLJKDE&33366666666##T\"4¹;)9:;)9*¹¹2I#4¹;)))))*¹¹¹¹¹2'¹;)9)*+*¹¹¹¹¹¹¹",
  "333334¹¹¹¹%I&33&)9*¹¹¹¹¹¹¹%&4*;%9*¹¹¹¹¹ᶠᶠ▮%4*;9%*¹¹¹¹¹¹¹¹;1*;*+%:¹¹¹¹¹¹¹;*1;*¹¹%):¹¹¹¹>;\"64*¹¹¹%9*¹¹¹?\"64*¹¹¹³¹%)¹¹¹<\"4*¹¹¹(ᵉᶠᶠ2*¹¹¹<1,¹¹¹¹1¹¹¹¹¹¹¹¹<1,¹¹¹¹1¹¹¹@¹¹¹¹<1,¹¹¹¹1>¹\"#?>@¹<8,¹>?@%##&&##$¹¹+:;\"##&&&CD&I',¹¹+)%&&&ICTT&&',¹¹¹<%I&&CTU\"&&',¹¹¹<%&&&STU%",
  "333333333333333333333334¹¹¹+92&&¹¹;)*¹¹¹¹¹¹¹¹¹+:;)*¹¹¹¹¹¹¹²¹+9%&¹;9*¹¹¹¹¹¹¹¹¹¹¹9)*¹¹¹¹¹¹¹¹¹¹¹+2&;)*¹¹¹¹¹¹¹¹¹¹¹;)9¹□□□□□¹¹¹¹¹¹¹+%9*¹¹¹¹¹¹¹¹¹¹¹;9*+:\"###$¹¹¹¹¹¹¹;%*¹¹¹¹¹¹¹¹¹¹¹;)*?¹+%&I&'¹❎¹¹?;9)%:¹¹¹@>?¹¹¹¹5666666333336666666#&9:ᶠ▮5#7ᵉᶠ¹¹+:¹¹¹¹¹;*¹¹;*¹¹+9:;2&)):¹¹8¹¹¹¹¹¹+hYYYi*¹¹;9:¹¹¹+))*%+9):¹¹¹¹¹¹¹¹¹¹¹+hYYYi*¹+:¹¹¹+9:%;*+9:¹¹¹¹¹¹¹¹¹¹¹¹✽¹¹¹¹¹¹+:¹¹¹+)%$¹¹+):¹¹¹¹¹¹¹★⧗¹¹¹¹⧗⧗★¹¹¹+:¹⬆️?+%'¹¹¹+9:?@🐱⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️░\"###&&$□□□\"###&&&333333333333334%&I&&E&###ICDDE&'CDDtttttttttDDE%&&&&TDDDDDTTTUI'STU\"##$\"###$STU%&&&I",
  "334)¹¹¹23&I&3333¹¹¹)¹¹¹¹¹%&')*¹¹¹¹;*¹²¹¹¹%&4*¹¹¹¹¹+:¹ᶠᶠᶠ▮%4*¹¹¹>¹¹¹)¹¹¹¹¹1*¹¹¹³\"¹;)*¹¹;))1¹¹¹¹\"&))¹¹¹;*¹¹1¹¹¹?%&¹+:¹¹)¹¹¹1¹¹¹\"&&¹¹+)))¹ᶠ▮1¹¹¹%&&¹¹¹)¹):¹¹8¹¹<%I&¹¹;*¹+))):¹¹<%&&))*¹¹¹9*¹+:¹<%&&¹)¹¹¹;*¹¹¹)¹□%&&¹))))*¹¹¹;))5&&&¹+:¹¹¹¹;)*¹¹、%&I¹¹+:¹¹¹)¹¹¹¹<%&&",
  "¹¹¹¹¹¹¹¹+:¹¹¹¹+:¹¹¹¹¹¹¹¹¹¹%&cTTT¹¹¹¹¹¹¹¹¹+)):¹¹+:¹¹¹¹¹¹¹¹¹%&&STT¹¹¹¹¹¹¹¹¹¹¹¹)¹¹¹+):¹¹¹¹¹¹;%&&STT¹¹¹¹¹¹¹¹¹¹¹¹)¹¹¹¹¹+)):¹¹;*%&&cTT¹¹¹¹¹¹¹¹¹¹¹¹)¹¹¹¹¹¹)¹+:¹)¹2&&&cd¹¹¹¹¹¹¹¹¹¹¹¹+:¹¹¹¹;*¹¹)¹):¹23&&&¹¹¹¹¹¹¹¹¹¹¹¹¹)¹¹¹;*¹¹¹)9))¹¹¹2&&¹¹¹¹¹¹¹¹¹¹;)))):¹)¹¹¹¹)*¹+:¹¹¹2&¹☉웃⌂⬅️😐¹¹¹;*¹¹¹+))*¹¹¹;*¹¹¹)¹¹¹¹%¹▤▥あいう¹¹¹)¹¹¹¹¹)*¹¹¹¹)¹¹¹¹+:¹¹¹%?そたちつて¹♥¹)¹¹¹;)*¹¹¹¹;):¹¹¹¹)¹¹¹%##########$¹;*¹¹¹¹¹¹)¹+:¹¹¹+a¹¹%&&&333333&&$)¹¹¹¹¹¹¹)¹¹)¹¹¹¹¹¹\"&334CDDDDE2&&#$?@¹¹¹;*¹¹+:¹¹?\"#&&DDDTTTTTTE2&&&#$¹¹@)¹¹¹⁴)¹¹\"&&&&TTTTTTTTTTE%&&&&##$)¹¹¹\"###&&&&&",
  "TTTTTe&&333333&&Tddde&34¹¹¹+:¹2&e&&&&4¹¹¹¹¹¹)¹;%&&&&4)):¹¹;)))*%&&34¹¹¹))9)¹¹)¹%&')¹¹¹;)*¹+:¹+:%&'):¹;*¹¹¹¹)¹¹+2&'¹)))¹¹¹¹¹+:¹¹Q&'¹)¹+:¹¹¹¹¹+)))&4;*¹¹+):¹¹¹¹¹¹¹'¹)¹¹¹¹¹+):¹¹¹¹¹'@)¹¹¹¹¹¹¹+:¹¹¹C&#$¹¹¹¹¹¹¹¹+):¹S&&&$¹¹¹⁴¹¹¹¹¹+)S&&&&#$ᵉᶠ¹>¹?@¹CT&&&&&'¹¹¹\"##$CTT",
  "¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹w¹¹¹¹¹¹¹¹¹¹¹¹¹>\"##¹¹¹¹¹¹¹¹¹¹¹?\"&&&¹¹¹¹¹¹¹¹¹¹¹\"&&&&¹¹¹¹¹¹¹¹¹¹F%&&&&¹¹¹¹¹¹¹¹¹¹V2333&¹¹¹¹¹¹¹¹¹CTDDDE%¹¹¹¹¹¹@?CTTTTTU%?>⁵?@>\"7STTTTTU2######4CTTTTTTTD&&&&&4CTTTTTTTTT&&&&'CTTTTTTTTTT&&&&'STTTTTTTTTT"
}
moresprites=true

--@end

--tiles stack
--assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
1,player_spawn
2,player_spawn
3,player_spawn
4,player_spawn
8,key
11,cloud
12,cloud
18,spring
19,spring
20,chest
21,npc
22,balloon
23,fall_floor
26,fruit
28,npc
29,npc_flipper
45,fly_fruit
62,flower
64,fake_wall
65,big_chest
78,egg_cracker
80,door
86,message
96,stove
118,flag
132,big_flower
134,npc
145,big_flower
146,big_flower
147,seed_pack
150,npc
]],"\n"),function(t)
 local tile,obj=unpack(split(t))
 tiles[tile]=_ENV[obj]
end)

-->8
-- [dialogue]

function start_dialogue(obj, str)
	last_npc_talked=obj
	pause_player,
	dialogue_index,dialogue_timer,
	show_dialogue,shown_dialogue,
	dialogue_speed=
	true,1,0,true,"",2
	dialogue_str_split=split(str,"|")
	dialogue=dialogue_str_split[1]
end

function update_dialogue()
	local proceed=btnp(❎) or btnp(🅾️)
	if proceed and dialogue_timer>=10 then
		if shown_dialogue!=dialogue then
			dialogue_speed=0
		else
			pause_player,show_dialogue=false,false
			local npc_dialogue = npc.dialogue[last_npc_talked.sprite]
			npc_dialogue.on_end(last_npc_talked, npc_dialogue)
		end
	end
	dialogue_timer+=1
	if dialogue_timer%dialogue_speed==0 and dialogue!=shown_dialogue then
		shown_dialogue..=dialogue[dialogue_index]
		dialogue_index+=1
	end
end
-->8
-- [quests]

quest_names={
	[26]="sTRAWBERRY",
	[62]="fLOUR",
}

function draw_quest()
	rectfill(6,6,17,17,13)
	rect(6,6,17,17,1)
	spr(quest,8,8)
	local text='X'..quest_count
	?text,12-text_width(text)/2,19,7
end

function draw_quest_accept_box()
	rect(14,89,114,121,7)
	rectfill(15,90,113,120,0)
	if asking_for_blahaj then
		?'dO YOU ACCEPT THE PLUSH?',17,92,7
	else
		?'dO YOU ACCEPT THE QUEST?',17,92,7
	end
	?(quest_acception and ">" or "")..'yES',38,106,6
	?(quest_acception and "" or ">")..'nO',80,106,6
end

function open_quest_box(item, count)
	pause_player = true
	show_quest_accept_box = true
	potential_quest = item
	potential_quest_count = count
	quest_accept_box_timer = 0
end

function update_quest()
	if quest_count<1 then
		quest=0
	end

	if show_quest_accept_box then
		quest_accept_box_timer+=1
		if btnp(⬅️) then
			quest_acception = true
		end
		if btnp(➡️) then
			quest_acception = false
		end
		if (btnp(❎) or btnp(🅾️)) and quest_accept_box_timer >= 15 then
			if quest_acception then
				quest = potential_quest
				quest_count = potential_quest_count
			end
			show_quest_accept_box,pause_player=false,false
			
		end
	end
end
-->8
--egg minigame
function dist(x0,y0,x1,y1)
	return sqrt((x1-x0)^2+(y1-y0)^2)
end

function init_mini_game()
	menuitem(1)
	menuitem(1,"back to celeste",function()
		menuitem(1)
		transition(celeste_upd,celeste_drw)
	end)
	
	score=0
	goal=(eggs_cooked+1)*5
	
	fly_out_r=42
	bhit_r=7
	butx=48
	buty=16
	circle={
		xo=0,
		yo=0,
		vx=0,
		vy=0
	}
	
	egg={
		xo=0,
		yo=0,
		vx=0,
		vy=0,
		hit_r=12
	}
	upd=celeste_upd
	drw=celeste_drw
end

function mini_game_upd()
	
	-- unpack everything
	cxo,cyo,cvx,cvy=circle.xo,circle.yo,circle.vx,circle.vy
	exo,eyo,evx,evy,ehit_r=egg.xo,egg.yo,egg.vx,egg.vy,egg.hit_r
	
	if (btnp(➡️)) cxo+=10
	if (btnp(⬅️)) cxo-=10
	if (btnp(⬆️)) cyo-=10
	if (btnp(⬇️)) cyo+=10
	cvx=0-cxo/4
	cvy=0-cyo/4
	cxo+=cvx
	cyo+=cvy

	evx=appr(evx,-cvx*2,0.05)
	evy=appr(evy,-cvy*2,0.05)
--	if (abs(evx)>0.1)	evx+=(rnd()-0.5)*2
--	if (abs(evy)>0.1)	evy+=(rnd()-0.5)*2
	exo+=evx
	eyo+=evy
	
	-- fly out
	if dist(exo+50,eyo+50,52+cxo/2,52+cyo/2)>fly_out_r then
		fly_out()
	end
	
	if col_butter() then
		got_butter()
	end
	
	--pack up
	circle={
		xo=cxo,
		yo=cyo,
		vx=cvx,
		vy=cvy
	}
	egg={
		xo=exo,
		yo=eyo,
		vx=evx,
		vy=evy,
		hit_r=ehit_r
	}
end

function mini_game_drw()
	cls(14)
	fillp(0xcc33+0.5)
	rectfill(us"0,0,127,127,12")
	fillp()
	
	draw_pan()
	draw_butter(butx,buty)
	draw_egg()

	
	?score.."/"..goal,1,2,6
	?score.."/"..goal,1,1,7
end
function draw_pan()

	local r=52
	circfill(r+cxo,r+cyo,r,0)
	circ(r+cxo,r+cyo,r,1)
	for ox=-1,1 do
		for oy=-1,1 do
			circ(r+cxo+ox,r+cyo+oy,r-1,1)
		end
	end
	camera(-cxo,-cyo)
	
	foreach(split(
	[[116,116,9,1
	100,100,10,0
	92,92,10
	107,107,9
	112,112,9]],"\n"),compose(circfill, us))
	
	foreach(split(
	[[95,81,125,112,1
	95,82,125,113
	94,82,125,114
	93,82,125,115
	81,95,112,125
	81,94,113,125
	81,93,114,125
	81,92,115,125]],"\n"),compose(line, us))
	camera()
end

function draw_egg()
	local r=16
	camera(-exo, -eyo)
	-- egg whites
	for _x=-1,1,2 do
		for _y=-1,1,2 do
			circfill(52+_x,52+_y,r,1)
			circfill(55+_x,50+_y,r)
			circfill(46+_x,46+_y,r)
		end
	end
	circfill(52,52,r,7)
	circfill(55,50,r)
	circfill(46,46,r)
	--	yolk
	
	for _x=-1,1,2 do
		for _y=-1,1,2 do
			circfill(52+_x,50+_y,r/2,15)
			circfill(48+_x,48+_y,r/2)
		end
	end
	circfill(52,50,r/2,9)
	circfill(48,48,r/2)

	camera()
end

function draw_butter(x,y)
	x+=cxo
	y+=cyo
	fillp(▒*(((flr(x)%2==1 or flr(y)%2==1) and not (flr(x)%2==flr(y)%2)) and -1 or 1))
	circfill(x,y,bhit_r,15)
	fillp()
	
	--func draw
	for _x=-1,1,2 do
		for _y=-1,1,2 do
			camera(-_x, -_y)
			rectfill(x-3+0,y-2+0,x+0,y+1+0,1)
			rectfill(x+0,y-1+0,x+4+0,y+2+0)
			line(x-3+0,2+y+0,4+x+0,3+y+0)
			camera()
		end
	end
	
	rectfill(x-3,y-2,x,y+1,10)
	rectfill(x,y-1,x+4,y+2)
	line(x-3,2+y,4+x,3+y,9)
end

function col_butter(radius_off)
	radius_off=radius_off or 0
	return dist(exo+50,eyo+50,butx+cxo,buty+cxo)<ehit_r+bhit_r+radius_off
end

function got_butter()
	score+=1
	if score>=goal then
		won()
	end
	
	repeat
	 butx=rnd(128)
	 buty=rnd(128)
	until valid_butter()
end

function valid_butter()
	in_pan=dist(butx,buty,52,52)<42
	
	return in_pan and not col_butter(7)
end

function fly_out()
	upd=flew_out_upd
	drw=flew_out_drw
end

function flew_out_upd()
	if btn(🅾️) or btn(❎) then
		transition(celeste_upd,celeste_drw)
		menuitem(1)
	end
end

function flew_out_drw()
	cls(0)
	draw_centered_text("you flew out of the pan",64,7)
	draw_centered_text("🅾️/❎",70,7)
end

function won()
	raw_eggs-=1
	eggs+=1
	eggs_cooked+=1
	upd=won_upd
	drw=won_drw
end

function won_upd()
	if btn(🅾️) or btn(❎) then
		transition(celeste_upd,celeste_drw)
		menuitem(1)
	end
end

function won_drw()
	cls()
	draw_centered_text("yOU WON",32,7)
	?"yOU GOT 1",39,39,7
	draw_centered_text("yOU NOW HAVE : "..eggs,46,7)
	spr(124,79,38)
	draw_centered_text("rETURN TO cELESTE",72,7)
	draw_centered_text("🅾️/❎",79,7)
end
-->8
--helpers
function text_width(str)
	return print(str,0,-20)
end
function draw_centered_text(str,y,c)
	?str,(128-text_width(str))/2,y,c
end

function transition(u,d)
	fade=1
	upd,drw=transition_upd,transition_drw
	n_upd=u
	n_drw=d
end

function transition_upd()
	fade-=0.1
	if fade<0 then
		upd=n_upd
	end
end

function transition_drw()
	screen_fade(fade)
	if fade<0 then
		drw=n_drw
		fillp()
	end
end

function screen_fade(f,c)
if f then
fillp(f<=0and.5or 
f<.33333and 2565.5or 
f<.66666and 23130.5or 
f<1and 64245.5or-.5)
rectfill(0,0,127,127,7)
end
end

function compose(f, g)
	return function(...)
		return f(g(...))
	end
end

function us(a)
	return unpack(split(a))
end
__gfx__
000000000000000000000000066666600000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700494949494949494949494949
000000000666666006666660222222220666666006666600000000000666666000a000a0000a0a000000a0000777777677777770222222222222222222222222
000000002222222222222222222ffff222222222222222200666666022f1ff1200a909a0000a0a000000a0007766666667767777000420000000000000024000
00000000222ffff2222ffff222f1ff12222ffff22ffff2202222222222fffff2009aaa900009a9000000a0007677766676666677004200000000000000002400
0000000022f1ff1222f1ff1202fffff022f1ff1221ff1f20222ffff222fffff20000a0000000a0000000a0000000000000000000042000000000000000000240
0000000002fffff002fffff000bbbb0002fffff00fffff2022fffff202bbbb200099a0000009a0000000a0000000000000000000420000000000000000000024
0000000000bbbb0000bbbb000700007007bbbb0000bbbb7002f1ff1000bbbb000009a0000000a0000000a0000000000000000000200000000000000000000002
000000000070070000700070000000000000070000007000077bbb700070070000aaa0000009a0000000a0000000000000000000000000000000000000000000
555555550000000000000000000000000000000000000000008888004999999449999994499909940300b0b06665666500000000000000000000000070000000
55555555000000000000000000040000000000000776006008888880911111199111411991140919003b33006765676500111100007700000770070007000007
550000550000000000000000000950500aaaaaa07777667708788880911111199111911949400419028888206770677001171710007770700777000000000000
55000055007000700499994000090505a998888a777ffff708888880911111199494041900000044089888800700070001119910077777700770000000000000
55000055007000700050050000090505a988888a67fffff608888880911111199114094994000000088889800700070011177711077777700000700000000000
55000055067706770005500000095050aaaaaaaa06f4fff008888880911111199111911991400499088988800000000011177711077777700000077000000000
55555555567656760050050000040000a980088a0034330000888800911111199114111991404119028888200000000001177710070777000007077007000070
55555555566656660005500000000000a988888a002402000000000049999994499999944400499400288200000000001199d990000000007000000000000000
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
5777755700000000077777777777777777777770077777700000000000000000cccccccc22222222222222222222222200000000000000000000000000000000
7777777700aaaaaa700007770000777000007777700077770000000000000000c77ccccc11444444444444444444424400000000000000000000000000000000
7777cc770a99999970cc777cccc777ccccc7770770c777070000000000000000c77cc7cc77114444444444414444424400000000000000000000000000000000
777ccccca99aaaaa70c777cccc777ccccc777c0770777c070000000000000000cccccccc77771111111111144444424400006000000ff0000ff2200000222200
77cccccca9aaaaaa707770000777000007770007777700070002eeeeeeee2000cccccccc8888888888888884222222220006060000ff2f00ff22220f02222220
57cc77cca999999977770000777000007770000777700007002eeeeeeeeee200cc7ccccc88888888888888842444444400d0006000ffff0000ff20f702f12120
577c77cca99999997000000000000000000c000770000c0700eeeeeeeeeeee00ccccc7cc1661111111111661244444440d00000c00ffff0000ffff00ffbbbb0f
777ccccca99999997000000000000000000000077000000700e22222e2e22e00cccccccc166199999999166124444444d000000c000ff000000ff00ff07ff7ff
777cccccaaaaaaaa7000000000000000000000077000000700eeeeeeeeeeee000000000000000000000000000000000c0000000c000600000000000000000000
577ccccca49494a17000000c000000000000000770cc000700e22e2222e22e00000000000000000000000000000000d000000000c060d0000000000000000000
57cc7ccca494a4a170000000000cc0000000000770cc000700eeeeeeeeeeee0000000000000000000000000000000c00000000000d000d000000000666000000
77cccccca49444aa70c00000000cc00000000c0770000c0700eee222e22eee0000000000000000000000000000000c0000000000000000000000006000000000
777ccccca49999aa7000000000000000000000077000000700eeeeeeeeeeee005555555506600006660006660060c00060000660006660006000060000000000
7777cc77a494449970000000000000000000000770c0000700eeeeeeeeeeee00555555556600006600006606006c000000006606006000000000066000000000
77777777a494a44470000000c0000000000000077000000700ee77eee7777e005555555566000660000600060060000000006006006000000000006000000000
57777577a49499997000000000000000000000077000c00707777777777777705555555506600600000600060060000060006006006000006000000d00000000
eeeeeeeeeeeeeeee7000000000000000000000077000000700777700500000000000000500dd0d00000d000d00d00000d000d00d000d0000d0000000d0000000
eeeeeeeeeeeeeeee700000000000000000000007700c0007070000705500000000000055000ddd00000dd0dd00d00000d000dd0d000dd000d00000000d000000
eeeeeeeeeeeeeeee700000000000c0000000000770000007707700075550000000000555000ddd000000ddd000dddd00dd000ddd00dd0000d00000000d000000
e0eeeee0000eeeee7000000cc0000000000000077000cc077077bb0755550000000055550ddd0ddddd00000000d000000000000000000000000000dddd000000
ee0eee0eeeeeeeee7000000cc0000000000c00077000cc07700bbb0755555555555555550000000000000c000000000000000000000000000000c00000000000
eee000eeeeeeeeee70c00000000000000000000770c00007700bbb075555555555555555000000000000c00000000000000000000000000000000c0000000000
cccccccccccccccc700000000000000000000007700000070700007055555555555555550000000000cc0000000000000000000000000000000000c000000000
cccccccccccccccc07777777777777777777777007777770007777005555555555555555000000000c000000000000000000000000000000000000c000000000
ecc6cc6cc6cc6cce07777777777777777777777007777770004bbb00004b000000400bbb0000000000000000010000000011771001000000000000c000000000
ecccccccccccccce70007770000077700000777770007777004bbbbb004bb000004bbbbb0000000100000000111000000177777111100000000000c00c000000
ecc1111111111cce70c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb00000000c01000000111111100177aa771111111000000001010c00000
ecc1555555551cce70777ccccc777ccccc777c0770777c07040000000400bbb00400000000000100110001111111711017aaa9771111711000000001000c0000
ecc1555555551cce7777000007770000077700077777000704000000040000000400000000000100111111111111111177aaa977111111110000000000010000
ecc1555555551cce77700000777000007770000777700c074200000042000000420000000000010011111111777777117779977177777ee10000000000001000
ecc1111111111cce7000000000000000000000077000000740000000400000004000000000000000110001177777ee71117777107777eeee0000000000000000
ecccccccccccccce077777777777777777777770077777704000000040000000400000000001000010000017777777000011771077777e000000000000000010
2222222257bbbbbbbbbbbbbbbbbbbbb5000000000990000000000000000099999999999999999999999999999999000000000000000000000000000000000000
44444244777b33bb333bb3333bb37777000000009aa9000000000000009911111111111111111111111111111111990000000000000000000000000000000000
44444244777777777333333777777777000000009aaa900009999990091144444444444444444444444444444444119000000000000000000000000000000000
eeeeeeee777ccccc77733777ccccc7770099009009aa9000999ffff9091444444444444444444444444444444444419000000000000000000000000000000000
eeeeeeee77cccccccc7777cccccccc77009999990099990099f1ff19914444442222222224444444444442222244441900000000000000000000000000000000
eeeeeeee77cc77ccccccccccccc7cc7700099aa90009330009ffff60991444442444244424444444444442424244419900000000000000000000000000000000
aaaaaaaa77cc77cccccccccccccccc77000099990003300000aaaa06009144442444244424444444444442222244190000000000000000000000000000000000
aaaaaaaa77cccccccccccccccccccc77000330000033300000700706009144442444244424444444444442424244190000000000000000000000000000000000
aaaaaaaa088000000ee00ee009dffd90003300000033000000111100009144442222222224444444444442222244190000000000000000000000000000000000
cccccccc8820088002ee02ee0ffddff0003300000330000001111110000914442444244424444444444444444441900000000000000000000000000000000000
cccccccc22308820002e03229ffffff9000330000330000011144411000914442444244424444444444444444441900000000000000000000000000000000000
cccccccc0030320000320300f333333f000333000033000011474471000914442444244424444444444444444441900000000000000000000000000000000000
222222220003300000333000f337373f0000330000330b0001444440000914442222222224444222222244444441900000000000000000000000000000000000
244444440b03030bb03033b0f373733f00b0330000bbbb0000aaaa00000914444444444444442244444224444441900000000000000000000000000000000000
244444440bb0033bb3303bb09333333900bbbbb00bbbbb0000222200000914444444444444442444444424444441900000000000000000000000000000000000
2444444400bb0bbbbbb0bb0009ffff9000bbbbbb0bbbb00000700700000914444444444444442444444424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444444424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444444424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444442424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444444424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444444424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444444424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444444424444441900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000914444444444444442444444424444441900000000000000000000000000000000000
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
00000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000d60060000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000d00000c000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000d000000c000000000000000000000000000000000000000000000000000000000000
00000000000000000000006000000000000000000000000000000000000c0000000c000600000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000d000000000c060d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c00000000000d000d000000000666000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c0000000000000000000000006000000000000000000000000000000000000000000000
00000000000000000000000000000000000006600006660006660060c00060000660006660006000060000000000000000000000000000000000000000000000
0000000000000000000000000000000000006600006600006606006c000000006606006000000000066000000000000000000000000000000000000000000000
00000000000000000000000000000000000066000660000600060060000000006006006000000000006000000000000000000000000000000000000000000000
00000000000000000000000000000000000006600600000600060060000060006006006000006000000d00000000000000000000000000000000000000000000
00000000000000000000000000000000000000dd0d00000d000d00d00000d000d00d000d0000d0000000d0000000000000000000000000000000000000000000
000000000000000000000000000006000000000ddd00000dd0dd00d00000d000dd0d000dd000d00000000d000000000000000000000000000000000000000000
000000000000000000000000000000000000000ddd000000ddd000dddd00dd060ddd00dd0000d00000000d000000000000000000000000000000000000000000
0000000000000000000000000000000000000ddd0ddddd00000000d000000000000000000006000000dddd000000700000000000000000000000000000000000
0000000000000000000000000000000000000000000000000c000000000000000000000000000000c00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c00000000000000000000000000000000c0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000cc0000000000000000000000000000000000c000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000c000000000000000000000000000000000000c000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000600c0000000000000000000000000000000000000c000000000000000000000000000000000000000000000
0000600000000000000000000000000000000000000100000000000000000000000000000000000000c00c000000000000000000000000000000000000000000
000000000000000000000000000000000000000700c0000000000000000000000000000000000000001010c00000000000000000000000000000000000000000
000077000000000000000000000000000000000001000000000000000000000000000000000000000001000c0000000000000000000000000000000000000000
00007700000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000066000000000000000700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000000000000000000000000000000660
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000660
00000000000000000000000000000000000000000000006000000005505055005005550555000000000000000000000000000000000000000000000000000000
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
00000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000005050505050005000000050605000505050500050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000555005505500000055505050000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000555050505050000050505050050000000550505050505550055055005050505055500550550000000000000000000000000000
00000000000000000000000000505050505050000055005550000000005050505050505550505050505050505055505050505000000000000000000000000000
00000000000000000000000000505050505050000050500050050000005550555050505050555050505550505050505550505000000000000000000000000000
00000000000000000000000000505055005550000055505550000000005050505005505050505050505050055050505050505000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000008080804020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202000200001313131302020302020202000000000013131313020204020202020202020000131313130004040202020202020200001313131300000002000000000202
0203030302020002020202020000000002020200020200020202020200000000000000000000000202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2532323232323232323232323232322525252525252525252525252525252525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2642437373740000000000000000002425482525253233724343737425254825000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2662640000000000001111000000112425253232330000006264000031252525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000004274000000212525330000110000000000000000312525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000425400000000312526000811270000000000110000002425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
260d0e0e00000000525400000000003133000021260d0e000000450000003125000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000042536400171700000000000024260000000011550000000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
263d000000000052540000000000001111000024330000140042540000000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25230000000000525400000000000021230000372b0021231162540000000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252600000000005254000011110011243300001b000024252223540000000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4826000000000052541111212300212600000000001224252533540000000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2533000000004253534421252611242600000000001724253300551100000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26000000000052535364312525222526003f0000000024260000524400000031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
263f00043f00525354274524254825252223000000002426002c525400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25222222237263635430652425252525252523003d212525233c6264004e3e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252525222223552422252525252525252522222525252522222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

