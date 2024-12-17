pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- [initialization]
-- evercore v2.3.0
local _g = _ENV
poke(0x5f2e,1)

-- [globals] --
objects,got_fruit={},{}
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

-- [init] --
function is_title() return not lvl_id end
function _init()
	frames,start_game_flash=0,0
	for i=0,32 do fx_fire(rnd"128",90-8+rnd"16") end
	music(0)
	-- begin_game()

	-- backgrounds --
	bg_bush_far = parse_bg("10,5,44,1|70,30,23,1|104,11,26,1|42,34,11,1|122,40,14,1|25,92,19,1|7,102,15,1|36,103,19,1|78,94,13,1|69,119,28,1|110,94,10,1|90,96,18,1|126,94,9,1|128,98,-1,130,2,1|-1,28,134,-2,2,1|88,101,14,2|113,110,17,2|72,113,14,2|25,102,14,2|49,107,10,2|6,108,13,2|1,34,9,2|87,23,9,2|73,31,13,2|50,13,24,2|24,29,12,2|6,19,19,2|116,24,11,2|100,11,18,2|124,35,12,2|126,115,10,1|104,124,23,1|112,109,11,1|87,100,10,1|73,114,13,1|53,114,11,1|22,106,11,1|6,115,14,1|34,114,11,1|66,123,10,1|123,109,6,1|124,27,13,1|107,14,12,1|85,17,12,1|73,24,13,1|56,14,17,1|31,21,10,1|18,24,9,1|6,17,17,1|-3,21,129,-2,1,1")
	bg_trees = parse_bg("90,21,13,1|94,30,12,1|97,16,11,1|97,39,5,1|74,59,9,1|68,72,13,1|80,66,10,1|99,85,9,1|89,90,10,1|97,102,10,1|40,39,10,1|33,36,11,1|30,20,10,1|25,69,10,1|35,59,7,1|34,73,8,1|26,86,8,1|36,103,8,1|36,110,6,1|71,116,9,1|78,122,9,1|3,53,11,1|4,37,6,1|6,83,6,1|5,67,5,1|4,93,9,1|3,85,8,1|100,59,8,1|70,32,8,1|74,42,6,1|68,6,8,1|1,121,7,1|87,15,5,2|95,12,5,2|89,33,5,2|95,31,3,2|102,58,5,2|97,58,3,2|99,67,3,1|75,56,4,2|79,62,5,2|85,64,5,2|76,72,3,2|71,72,3,2|96,84,5,2|88,87,5,2|92,101,2,2|96,98,5,2|37,58,4,2|32,62,5,2|30,17,6,2|37,22,7,2|33,39,4,2|38,39,5,2|28,82,3,2|31,85,3,2|37,100,4,2|32,102,3,2|5,82,5,2|1,94,5,2|5,88,4,2|6,41,7,2|4,50,2,2|4,60,5,2|2,119,4,2|73,112,5,2|77,119,4,2|77,41,3,2|73,38,3,2|106,-1,131,128,0,1|70,130,43,-2,0,1|27,-1,11,128,0,1|40,0,52,130,1,1|60,129,57,-1,1,1|100,-3,116,129,1,1|122,-2,120,129,1,1|14,128,6,-3,1,1|18,-1,20,129,1,1|100,-1,105,129,2,1|109,128,108,-3,2,1|38,128,43,-1,2,1|46,-1,47,129,2,1|5,128,7,-2,2,1")
	bg_bushes = parse_bg("14,103,18,0|47,104,11,0|33,96,12,0|65,99,12,0|88,103,16,0|124,96,17,0|108,106,18,0|4,19,20,0|30,15,18,0|55,27,17,0|91,21,15,0|74,22,12,0|111,26,10,0|124,21,8,0|6,110,14,1|21,105,13,1|36,104,10,1|50,110,11,1|65,103,11,1|81,103,8,1|93,110,15,1|122,107,16,1|3,20,12,1|17,17,10,1|30,18,8,1|53,21,12,1|37,11,12,1|79,18,10,1|66,14,11,1|118,13,7,1|126,16,7,1|115,19,10,1|92,20,10,1|105,14,10,1|8,117,15,0|20,110,13,0|34,110,11,0|47,117,13,0|63,113,14,0|84,110,11,0|98,117,12,0|121,108,10,0|113,117,12,0|116,13,12,0|128,11,9,0|90,17,7,0|100,10,9,0|78,14,10,0|60,14,8,0|52,16,11,0|34,8,11,0|15,13,10,0|2,20,8,0|0,115,135,129,0,1|129,11,-2,-3,0,1")
end

function begin_game()
	max_djump=1
	deaths,frames,seconds_f,minutes,music_timer,time_ticking,fruit_count,bg_col=0,0,0,0,0,true,0,2
	load_level(1)
	music(1)
end


-- [update] --
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
			load_level(lvl_id)
		end
	end

	-- inputs
	input_x = btn(➡️) and 1 or btn(⬅️) and -1 or 0
	input_y = btn(⬆️) and -1 or btn(⬇️) and 1 or 0
	press_a,press_b = not input_a and btn"4", not input_b and btn"5"
	input_a,input_b = btn"4",btn"5"

	-- update each object
	foreach(objects,function(obj)
		obj.move(obj.spd.x,obj.spd.y,0);
		(obj.class.update or stat)(obj)
	end)

	-- start game
	if is_title() then
		-- if start_game then
		-- 	start_game_flash-=1
		-- 	if start_game_flash<=-30 then
		-- 		begin_game()
		-- 	end
		if not transition_target and (btn(🅾️) or btn(❎)) then
			transition("begin")
			-- music"-1"
			-- start_game_flash,start_game=50,true
			sfx"38"
			music(-1,500)
		end
	end
end


-- [draw] --
function _draw()
	if freeze > 0 then
		return
	end

	-- reset all palette values
	pal()

	-- draw bg color
	cls(bg_col)

	-- parallax
	draw_bg(bg_bush_far)
	draw_bg(bg_trees)
	if(is_title()) foreach(particles,draw_object)
	draw_bg(bg_bushes)

	-- start game flash
	if is_title() then
		if start_game then
			for i=1,15 do
				pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
			end
		end

		-- credits
		px_disp(title_data,12,3,12)
		outline(0,function()
			print_align("🅾️/❎",64,90,4,.5,.5)
			print_align("a mod by",64,103,6,.5,.5)
			print_align("howf n' snek",64,110,6,.5,.5)
			print_align("music by fettuccini",64,127,7,.5,1)
		end)

		for i=0,5 do fx_fire(rnd"128",90-8+rnd"16") end
		transition_draw()
		npal()
		return
	end

	--set cam draw position
	draw_x,draw_y = round(cam_x)-64,round(cam_y)-64
	tile_x,tile_y = draw_x\8,draw_y\8
	camera(draw_x,draw_y)

	-- draw bg terrain
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4)
	
	--set draw layering
	--positive layers draw after player
	--layer 0 draws before player, after terrain
	--negative layers draw before terrain
	local pre_draw,post_draw={},{}
	foreach(table_concat(particles,objects),function(obj)
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
	draw_grass()
	
	-- draw fg objects
	foreach(post_draw,draw_object)

	-- dead particles
	foreach(death_fx,function(p)
		p.x+=p.dx
		p.y+=p.dy
		p.t-=0.2
		if p.t<=0 then
			del(death_fx,p)
		end
		rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14+5*p.t%2)
	end)
	
	
	-- draw level title
	camera()
	transition_draw()
	if ui_timer>=-30 then
		-- if ui_timer<0 then
			draw_ui()
		-- end
		ui_timer-=1
	end
	--?#particles,0,0

	-- palette
	npal()

end

function npal()
	pal({[0]=128,130,133,5,134,15,9,4,131,3,139,11,140,12,7,8},1)
end

function outline(col,func)
	local cx,cy = peek2(0x5f28),peek2(0x5f2a)
	for i=0,15 do pal(i,col) end
	for xx=-1,1 do
	for yy=-1,1 do
		camera(cx+xx,cy+yy)
		func()
	end end
	camera(cx,cy)
	pal() func() 
end

-- [draw helpers] --
function draw_time(x,y)
	rectfill(x,y,x+44,y+6,0)
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,14
end

function draw_ui()
	rectfill(24,58,104,70,0)
	local title=lvl_title or lvl_id.."00 m"
	?title,64-#title*2,62,14
	draw_time(4,4)
end

function draw_grass()
	for tx = tile_x,tile_x+16 do
	for ty = tile_y,tile_y+16 do
		local tile = tile_at(tx,ty)
		if fget(tile,6) then
			if (tile == 69) tile += 1
			spr(tile+1.5+sin(time()*1.2+tx/4),tx*8,ty*8)
		end
	end end
end


-- [effects] --
death_fx = {}

-- [helpers] --
function vector(x,y) return {x=x,y=y} end
function rectangle(x,y,w,h) return {x=x,y=y,w=w,h=h} end

function psfx(...)
	if (sfx_timer<=0) sfx(...)
end

function dsfx(n,start,len)
	sfx(n,-1,(start or 0)*8,(len or 1)*8)
end

function maybe(v) return rnd"1" <= (v or 0.5) end
function round(x) return flr(x+0.5) end
function appr(val,to,by) return val>to and max(val-by,to) or min(val+by,to) end
function sign(v) return v~=0 and sgn(v) or 0 end

function two_digit_str(x) return x<10 and "0"..x or x end
function table_concat(t1,t2)
	local t = {}
	foreach(t1,function(o) add(t,o) end)
	foreach(t2,function(o) add(t,o) end)
	return t
end

function tile_at(x,y) return mget(lvl_x+x,lvl_y+y) end
function spikes_at(x1,y1,x2,y2,xspd,yspd)
	for i=max(0,x1\8),min(lvl_w-1,x2/8) do
		for j=max(0,y1\8),min(lvl_h-1,y2/8) do
			if({[60]=y2%8>=6 and yspd>=0,
			[61]=y1%8<=2 and yspd<=0,
			[62]=x1%8<=2 and xspd<=0,
			[63]=x2%8>=6 and xspd>=0})[tile_at(i,j)] then
				return true
			end
		end
	end
end


-- [levels] --
function next_level()
	local next_lvl=lvl_id+1

	--check for music trigger
	if music_switches[next_lvl] then
		music(music_switches[next_lvl],500,7)
	end
	
	transition(next_lvl)
--	load_level(next_lvl)
end

function load_level(id)
	if(id=="begin") return begin_game()
	has_dashed,has_key= false

	--remove existing objects
	foreach(objects,destroy_object)
	particles = {}

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



-- [particles] --
particles = {}

-- [@smoke]
function fx_smoke(x,y,flag,spd_x)
	local fx = { layer=3, visible=true }
	local sprite,flip_x,flip_y = flag or 32,maybe(),maybe()
	x,y,spd_x = x-1+rnd"2",y-1+rnd"2",0.3+rnd"0.2"

	-- process
	function fx.draw()
		spr(sprite,x,y,1,1,flip_x,flip_y)
		x += spd_x
		y -= 0.1
		sprite += 0.2
		if (sprite >= flag+3) del(particles,fx)
	end
	
	return add(particles,fx)
end



-- [objects] --
tiles = {}
function new_class(...)
	local class = setmetatable({},{__index=_ENV})
	for _,i in pairs({...}) do tiles[i] = class end
	return class
end

function init_object(_type,_x,_y,_flag)
	local id = _x..",".._y..","..lvl_id
	if _type.is_fruit and got_fruit[id] then
		return
	end

	local _ENV = setmetatable({},{__index=_type})
	class,collideable,fruit_id = _type,true,id
	x,y,xstart,ystart,sprite,flag,layer,visible = _x,_y,_x,_y,_flag,_flag,0,true
	hitbox,spd,rem = rectangle(0,0,8,8),vector(0,0),vector(0,0)

	function left() return x+hitbox.x end
	function right() return left()+hitbox.w-1 end
	function top() return y+hitbox.y end
	function bottom() return top()+hitbox.h-1 end

	function is_solid(ox,oy)
		for o in all(objects) do
			if o!=_ENV and (o.solid_obj or o.semisolid_obj and not objcollide(o,ox,0) and oy>0) and objcollide(o,ox,oy) then
				return true
			end
		end
		return oy>0 and not is_flag(ox,0,3) and is_flag(ox,oy,3) or -- jumpthrough or
		is_flag(ox,oy,0) -- solid terrain
	end

	function is_ice(ox,oy)
		return is_flag(ox,oy,4)
	end

	function is_flag(ox,oy,flag)
		for i=max(0,(left()+ox)\8),min(lvl_w-1,(right()+ox)/8) do
			for j=max(0,(top()+oy)\8),min(lvl_h-1,(bottom()+oy)/8) do
				if fget(tile_at(i,j),flag) then
					return true
				end
			end
		end
	end

	function objcollide(other,ox,oy)
		return other.collideable and touching(other,ox,oy)
	end

	function touching(other,ox,oy)
		return other.right()>=left()+ox and
		other.bottom()>=top()+oy and
		other.left()<=right()+ox and
		other.top()<=bottom()+oy
	end

	--returns first object of class colliding with _ENV
	function check(class,ox,oy)
		for other in all(objects) do
			if other and other.class==class and other~=_ENV and objcollide(other,ox,oy) then
				return other
			end
		end
	end
	
	--returns all objects of class colliding with _ENV
	function check_all(class,ox,oy)
		local tbl={}
		for other in all(objects) do
			if other and other.class==class and other~=_ENV and objcollide(other,ox,oy) then
				add(tbl,other)
			end
		end
		
		if #tbl>0 then return tbl end
	end

	function player_here()
		return check(player,0,0)
	end

	function move(ox,oy,start)
		for axis in all{"x","y"} do
			rem[axis]+=axis=="x" and ox or oy
			local amt=round(rem[axis])
			rem[axis]-=amt
			local upmoving=axis=="y" and amt<0
			local riding=not player_here() and check(player,0,upmoving and amt or -1)
			local movamt
			if collides then
				local step=sign(amt)
				local d=axis=="x" and step or 0
				local p=_ENV[axis]
				for i=start,abs(amt) do
					if not is_solid(d,step-d) then
						_ENV[axis]+=step
					else
						spd[axis],rem[axis]=0,0
						break
					end
				end
				movamt=_ENV[axis]-p --save how many px moved to use later for solids
			else
				movamt=amt
				if (solid_obj or semisolid_obj) and upmoving and riding then
					movamt+=top()-riding.bottom()-1
					local hamt=round(riding.spd.y+riding.rem.y)
					hamt+=sign(hamt)
					if movamt<hamt then
						riding.spd.y=max(riding.spd.y,0)
					else
						movamt=0
					end
				end
				_ENV[axis]+=amt
			end
			if (solid_obj or semisolid_obj) and collideable then
				collideable=false
				local hit=player_here()
				if hit and solid_obj then
					hit.move(axis=="x" and (amt>0 and right()+1-hit.left() or amt<0 and left()-hit.right()-1) or 0,
									axis=="y" and (amt>0 and bottom()+1-hit.top() or amt<0 and top()-hit.bottom()-1) or 0,
									1)
					if player_here() then
						kill_player(hit)
					end
				elseif riding then
					riding.move(axis=="x" and movamt or 0, axis=="y" and movamt or 0,1)
				end
				collideable=true
			end
		end
	end

	function init_smoke(ox,oy)
		return fx_smoke(x+(ox or 0),y+(oy or 0),29)
	end

	function do_gravity(maxfall)
		if not is_solid(0,1) then
			spd.y = appr(spd.y,(maxfall or 2),abs(spd.y)>0.15 and 0.21 or 0.105)
		end
	end

	add(objects,_ENV);

	(init or stat)(_ENV)

	return _ENV
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
	if obj.visible then (obj.draw or draw_obj_sprite)(obj) end
end

function draw_obj_sprite(obj)
	spr(obj.sprite,obj.x,obj.y,1,1,obj.flip_x,obj.flip_y)
end


-- [@player]
player = new_class()
function player.init(_ENV)
	grace,jbuffer=0,0
	djump=max_djump
	dash_time,dash_effect_time=0,0
	dash_target_x,dash_target_y=0,0
	dash_accel_x,dash_accel_y=0,0
	spr_off=0
	collides=true
	
	drop_buffer = 0

	hitbox = rectangle(1,3,6,5)
	layer=1
	was_on_ground = is_solid(0,1)
end
function player.update(_ENV)
	if pause_player then
		return
	end
	move_camera(_ENV)

	-- spike collision / bottom death
	if spikes_at(left(),top(),right(),bottom(),spd.x,spd.y) or y>lvl_ph then
		kill_player(_ENV)
	end

	-- on ground checks
	local on_ground=is_solid(0,1)

	-- landing smoke
	if on_ground and not was_on_ground then
		init_smoke(0,4)
	end

	-- inputs
	if (holding == false and not input_b) holding = nil
	jbuffer = press_a and 4 or appr(jbuffer,0,1)
	drop_buffer = (input_y > 0 and input_x == 0) and 4 or appr(drop_buffer,0,1)

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

	-- find object to carry
	local to_carry
	hitbox = rectangle(0,0,8,8)
	if holding==nil and (input_b or dash_effect_time > 0) then
		for other in all(objects) do
			if other.can_carry and touching(other,0,0) then
				to_carry = other
			end
		end
	end
	hitbox = rectangle(1,3,6,5)

	-- dash effect timer (for dash-triggered events, e.g., berry blocks)
	dash_effect_time-=1

	-- <dashing> --
	if dash_time>0 then
		init_smoke()
		dash_time-=1
		spd=vector(appr(spd.x,dash_target_x,dash_accel_x),appr(spd.y,dash_target_y,dash_accel_y))
	
	-- <free> --
	else
		-- x movement
		local maxrun=1
		local accel=is_ice(0,1) and 0.05 or on_ground and 0.6 or 0.4
		local deccel=0.15

		-- set x speed
		spd.x=abs(spd.x)<=1 and
		appr(spd.x,input_x*maxrun,accel) or
		appr(spd.x,sign(spd.x)*maxrun,deccel)

		-- facing direction
		if spd.x~=0 then
			flip_x=spd.x<0
		end

		-- y movement
		local maxfall=2

		-- wall slide
		if input_x~=0 and is_solid(input_x,0) and not is_ice(input_x,0) then
			maxfall=0.4
			-- wall slide smoke
			if rnd"10"<2 then
				init_smoke(input_x*6)
			end
		end

		-- apply gravity
		do_gravity(maxfall)

		-- jump
		if jbuffer>0 then
			if grace>0 then
				-- normal jump
				dsfx(62,1)
				jbuffer=0
				grace=0
				spd.y=-2
				init_smoke(0,4)
			else
				-- wall jump
				local wall_dir=(is_solid(-3,0) and -1 or is_solid(3,0) and 1 or 0)
				if wall_dir~=0 then
					dsfx(62)
					jbuffer=0
					spd=vector(wall_dir*(-1-maxrun),-2)
					if not is_ice(wall_dir*3,0) then
						-- wall jump smoke
						init_smoke(wall_dir*6)
					end
				end
			end
		end

		-- <throw-object> --
		if holding then

			if press_b then
				local ox,oy = holding.x-x,holding.y-y
				holding.x,holding.y = x,y
				holding.move(ox,oy,0)
				holding.spd = vector(drop_buffer > 0 and 0 or spd.x*0.5 + (input_x ~= 0 and input_x*2 or flip_x and -2 or 2),drop_buffer > 0 and min(spd.y*1.5,0) or -1.5)
				
				holding.held = false
				holding = false
			end

		-- <dash> --
		elseif press_b and (not to_carry or not on_ground) then
			local d_full=5
			local d_half=3.5355339059 -- 5 * sqrt(2)

			if djump > 0 then
				init_smoke()
				djump-=1
				dash_time=4
				_g.has_dashed=true
				dash_effect_time=10

				-- calculate dash speeds
				spd=vector(input_x~=0 and
					input_x*(input_y~=0 and d_half or d_full) or
					(input_y~=0 and 0 or flip_x and -1 or 1)
				,input_y~=0 and input_y*(input_x~=0 and d_half or d_full) or 0)

				-- effects
				psfx"3"
				_g.freeze=2

				-- dash target speeds and accels
				dash_target_x=2*sign(spd.x)
				dash_target_y=(spd.y>=0 and 2 or 1.5)*sign(spd.y)
				dash_accel_x=spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
				dash_accel_y=spd.x==0 and 1.5 or 1.06066017177

			-- failed dash smoke
			else
				psfx"9"
				init_smoke()
			end
		end
	end

	-- pick up object
	if to_carry then
		holding,to_carry.held = to_carry,true
	end

	if holding then
		holding.x = x
		holding.y = y-6
		holding.spd = vector(0,0)
		holding.flip_x = flip_x
	end

	-- animation
	spr_off+=0.25
	sprite = not on_ground and (is_solid(input_x,0) and 5 or 3) or	-- wall slide or mid air
	btn(⬇️) and 6 or -- crouch
	btn(⬆️) and 7 or -- look up
	spd.x~=0 and input_x~=0 and 1+spr_off%4 or 1 -- walk or stand

	-- exit level off the top (except summit)
	if y<-4 and levels[lvl_id+1] then
		next_level()
		pause_player=true
	end

	do_spring(_ENV)

	-- was on the ground
	was_on_ground=on_ground
end

function player.draw(_ENV)
	-- clamp in screen
	local clamped=mid(x,-1,lvl_pw-7)
	if x~=clamped then
		x=clamped
		spd.x=0
	end
	-- draw player hair and sprite
	set_hair_color(djump)
	draw_hair(_ENV)
	draw_obj_sprite(_ENV)
	pal()
end

function create_hair(obj)
	obj.hair={}
	for i=1,5 do
		add(obj.hair,vector(obj.x,obj.y))
	end
end

function set_hair_color(djump)
	pal(15,djump==1 and 15 or djump==2 and 11 or 13)
end

function draw_hair(obj)
	local last=vector(obj.x+(obj.flip_x and 6 or 2),obj.y+(obj.sprite==6 and 4 or 3))
	for i,h in ipairs(obj.hair) do
		h.x+=(last.x-h.x)/1.5
		h.y+=(last.y+0.5-h.y)/1.5
		circfill(h.x,h.y,mid(4-i,1,2),15)
		last=h
	end
end

function kill_player(obj)
 if lvl_id==16 then
  next_level()
 else
	 sfx_timer=12
	 sfx"63"
	 _g.deaths+=1
	 destroy_object(obj)
	 for dir=0,0.875,0.125 do
		 add(death_fx,{
			 x=obj.x+4,
			 y=obj.y+4,
			 t=2,
			 dx=sin(dir)*3,
			 dy=cos(dir)*3
		 })
	 end
	 transition(lvl_id)
	--  delay_restart=15
 end
end

-- [@spawn]
player_spawn = new_class(1)
player_spawn.draw = player.draw
function player_spawn.init(_ENV)
	sfx"4"
	sprite=3
	target=y
	
	_g.cam_x,_g.cam_y=mid(x+4,64,lvl_pw-64),mid(y,64,lvl_ph-64)
	move_camera(_ENV)

	y=min(y+48,lvl_ph)
	spd.y=-4
	state=0
	delay=0
	create_hair(_ENV)
	djump=max_djump
	
	layer=1
end
function player_spawn.update(_ENV)
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
			init_object(player,x,y).hair = hair
		end
	end
end


-- [@bow]
bow = new_class(51)
bow.can_carry = true
function bow.init(_ENV)
	collides = true
	timer = 45
	hitbox = rectangle(1,3,6,5)
end
function bow.update(_ENV)
	x = mid(x,0,lvl_pw-8)

	-- shoot while held
	if held then
		timer -= 1
		if timer <= 0 then
			timer = 45
			init_smoke()
			init_object(arrow,x+(flip_x and -4 or 4),y,flip_x and 0.5 or 0.99)
		end
		return
	end

	-- movement
	spd.x = appr(spd.x,0,is_solid(0,1) and 0.15 or spd.y > 0 and 0.15 or 0)
	do_gravity()
	do_spring(_ENV)
	
end

-- [@flag]
flag = new_class(37)
function flag.update(_ENV)
	if not show and player_here() then
		sfx"55"
		sfx_timer,show,_g.time_ticking=30,true,false
	end
end
function flag.draw(_ENV)
	spr(37+frames/5%3,x,y)
	if(not show) return
	local oy = lvl_id==17 and 48 or 0
	camera(0,-oy)
	rectfill(32,2,96,31,0)
	spr(12,53,5)
	?"⁙".._g.fruit_count.."/7",62,8,14
	draw_time(43,15)
	?"deaths:".._g.deaths,48,24,14
	camera(draw_x,draw_y)
end

-- [@dart-trap]
dart_trap = new_class(34,35)
function dart_trap.init(_ENV)
	timer = lvl_id!=15 and 45 or 60
	dir = flag == 34 and -1 or 1
end
function dart_trap.update(_ENV)
	timer = appr(timer,0,1)
	if timer <= 0 then
		timer = lvl_id!=15 and 45 or 60
		init_smoke(dir*4).layer = -1
		init_object(arrow,x+dir*7,y,dir < 0 and 0.5 or 0.99)
	end
end

-- [@arrow]
arrow = new_class()
function arrow.init(_ENV)
	hitbox = rectangle(2,2,4,4)
	dsfx(61,0,2)
end
function arrow.update(_ENV)
	x += 2*cos(flag)*2
	y += 2*sin(flag)*2
	flag = appr(flag,0.75,0.01)

	-- kill player/destroy
	hit=player_here()
	if (hit) kill_player(hit)
	if (y > lvl_ph) destroy_object(_ENV)

	-- burn objects
	if on_fire then
		local burnable = check(tree,0,0) or check(message,0,0)
		if burnable and (not burnable.on_fire) then
			burnable.on_fire=true
			burnable.timers=35
			sfx"28"

			local othertree=check(tree,0,burnable.treetop and burnable.y-y+8 or burnable.y-y-8)
			if othertree then
				othertree.on_fire=true
				othertree.timers=35
			end
		end

		-- light unlit brazier
		local unlit = check(unlit,0,2)
		if unlit and not unlit.on_fire then
			init_object(flame,unlit.x,unlit.y-6,54)
			unlit.on_fire=true 
			sfx"28"
		end

	-- catch flame
	elseif check(flame,0,0) then
		on_fire=true
		dsfx(61,2,2)
	end
end
function arrow.draw(_ENV)
	local x,y = x+4,y+4
	local ox,oy = cos(flag),sin(flag)
	line(x-ox*3,y-oy*3,x+ox*3,y+oy*3,7)
	line(x-ox*3,y-oy*3,x-ox*2,y-oy*2,14)
	pset(x+ox*3,y+oy*3,14)
	if (on_fire) spr(frames%4<3 and 43 or 59,x-4+ox*3,y-7+oy*3)
end

-- [@unlit]
unlit = new_class(9)
function unlit.init(_ENV)
 	on_fire=false
	solid_obj = true
	hitbox = rectangle(1,2,6,6)
end

-- [@torch]
torch = new_class(50)
function torch.init(_ENV)
	solid_obj = true
	hitbox = rectangle(1,2,6,6)
	init_object(flame,x,y-6,54)
end

-- [@flame]
flame = new_class(54)
function flame.init(_ENV)
	hitbox=rectangle(1,0,6,8)
end
function flame.update(_ENV)
	layer = 3
	sprite += 0.4
	if (sprite >= flag + 5) sprite = flag

	local hit = check(player,0,4)
	if hit and hit.spd.y>=0 then
		kill_player(hit)
	end
end

-- [@tree]
tree = new_class(89,105)
function tree.init(_ENV)
	solid_obj = true
	timer=-5
	treetop=sprite==89
end
function tree.update(_ENV)
	if on_fire and not burnt_out then
		timers = max(timers-1)
		fx_fire(x+8-rnd"8",y+8-rnd"8")
		if timers<1 then
			if treetop then destroy_object(_ENV)
			else sprite=104 end
			burnt_out = true
		end
	end
end

-- [@fx_fire]
function fx_fire(x,y)
    local fx = { layer=1000, visible=true }
    local timer = 35
    x += 4-rnd"8"
    y += 4-rnd"8"
    function fx.draw()
        timer-=1
        y-=.2
        x+=sin(timer)/2
        circfill(x,y,(timer/20),timer>22 and 6 or timer>15 and 15 or 3)
        if(timer<=0) del(particles,fx)
    end
    return add(particles,fx)
end



-- [@balloon]
balloon = new_class(19)
function balloon.init(_ENV)
	offset=rnd()
	start=y
	timer=0
	hitbox=rectangle(-1,-1,10,10)
end
function balloon.update(_ENV)
	if visible then
		offset+=0.01
		y=start+sin(offset)*2
		local hit=player_here()
		if hit and hit.djump<max_djump then
			psfx"6"
			init_smoke()
			hit.djump=max_djump
			visible=false
			timer=60
		end
	elseif timer>0 then
		timer-=1
	else
		psfx"7"
		init_smoke()
		visible = true
	end
end
function balloon.draw(_ENV)
	for i=7,13 do
		pset(x+4+sin(offset*2+i/10),y+i,6)
	end
	draw_obj_sprite(_ENV)
end

-- [@message]
message = new_class(106)
function message.init(_ENV)
	text="-- burning trail --#only you can prevent#forest fires"
end
function message.update(_ENV)
	if timers==0 then
		destroy_object(_ENV)
	end
	if on_fire and timers>0 then
		fx_fire(x+8-rnd"8",y+8-rnd"8")
		timers-=1
	end
end
function message.draw(_ENV)
	draw_obj_sprite(_ENV)
	if player_here() then
		camera()
		for i,s in ipairs(split(text,"#")) do
			rectfill(7,7*i,120,7*i+6,14)
			?s,64-#s*2,7*i+1,0
		end
		camera(draw_x,draw_y)
	end
end

-- [@fakewall]
fake_wall = new_class(32)
fake_wall.is_fruit = true
function fake_wall.init(_ENV)
	solid_obj=true
	hitbox=rectangle(0,0,16,16)
end
function fake_wall.update(_ENV)
	hitbox=rectangle(-1,-1,18,18)
	local hit=player_here()
	if hit and hit.dash_effect_time>0 then
		hit.spd=vector(sign(hit.spd.x)*-1.5,-1.5)
		hit.dash_time=-1
		for ox=0,8,8 do
			for oy=0,8,8 do
				init_smoke(ox,oy)
			end
		end
		init_fruit(_ENV,4,4)
	end
	hitbox=rectangle(0,0,16,16)
end
function fake_wall.draw(_ENV)
	spr(sprite,x,y,1,2)
	spr(sprite,x+8,y,1,2,1,1)
end


-- [@fall-floor]
fall_floor = new_class(16)
function fall_floor.init(_ENV)
	solid_obj=true
	state=0
end
function fall_floor.update(_ENV)
	-- idling
	if state==0 then
		for i=0,2 do
			if check(player,i-1,-(i%2)) then
				break_fall_floor(_ENV)
			end
		end
	-- shaking
	elseif state==1 then
		delay-=1
		if delay<=0 then
			state=2
			delay=60--how long it hides for
			collideable,visible=false,false
			set_springs(_ENV,false)
		end
		-- invisible, waiting to reset
	elseif state==2 then
		delay-=1
		if delay<=0 and not player_here() then
			psfx"7"
			state=0
			collideable,visible=true,true
			init_smoke()
			set_springs(_ENV,true)
		end
	end
end
function fall_floor.draw(_ENV)
	spr(state==1 and 19-delay/5 or state==0 and 16,x,y) --add an if statement if you use sprite 0 (other stuff also breaks if you do this i think)
end

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
	foreach(springs,function(s) s.visible=state end)
	obj.hitbox=rectangle(0,0,8,8)
end


-- [@fruit]
fruit = new_class(12)
fruit.is_fruit=true
function fruit.init(_ENV)
	start=y
	off=0
end
function fruit.update(_ENV)
	check_fruit(_ENV)
	off+=0.025
	y=start+sin(off)*2.5
end

-- [@fly-fruit]
fly_fruit = new_class(45)
fly_fruit.is_fruit=true
function fly_fruit.init(_ENV)
	start=y
	step=0.5
	sfx_delay=8
end
function fly_fruit.update(_ENV)
	--fly away
	if has_dashed then
		if sfx_delay>0 then
			sfx_delay-=1
			if sfx_delay<=0 then
				_g.sfx_timer=20
				sfx"14"
			end
		end
		spd.y=appr(spd.y,-3.5,0.25)
		if y<-16 then
			destroy_object(_ENV)
		end
		-- wait
	else
		step+=0.05
		spd.y=sin(step)*0.5
	end
	-- collect
	check_fruit(_ENV)
end
function fly_fruit.draw(_ENV)
	spr(12,x,y)
	for ox=-6,6,12 do
		spr((has_dashed or sin(step)>=0) and 45 or y>start and 47 or 46,x+ox,y-2,1,1,ox==-6)
	end
end

function check_fruit(_ENV)
	local hit=player_here()
	if hit then
		hit.djump=max_djump
		sfx_timer=20
		sfx"13"
		got_fruit[fruit_id]=true
		init_object(lifeup,x,y)
		destroy_object(_ENV)
		if _g.time_ticking then
			_g.fruit_count+=1
		end
	end
end

function init_fruit(_ENV,ox,oy)
	sfx_timer=20
	sfx"16"
	init_object(fruit,x+ox,y+oy,12).fruit_id=fruit_id
	destroy_object(_ENV)
end


-- [@lifeup]
lifeup = new_class()
function lifeup.init(_ENV)
	spd.y=-0.25
	duration=30
	flash=0
end
function lifeup.update(_ENV)
	duration-=1
	if duration<=0 then
		destroy_object(_ENV)
	end
end
function lifeup.draw(_ENV)
	flash+=0.5
	?"1000",x-4,y-4,14+flash%2
end


-- [@spring]
spring = new_class(14,15)
function spring.init(_ENV)
	delta=0
	dir=flag==14 and 0 or is_solid(-1,0) and 1 or -1
	layer=-1
end
function spring.update(_ENV)
	delta=delta*0.75
	-- local hit=player_here()
	
	-- if visible and hit and delta<=1 then
	-- 	if dir==0 then
	-- 		hit.move(0,y-hit.y-4,1)
	-- 		hit.spd.x*=0.2
	-- 		hit.spd.y=-3
	-- 	else
	-- 		hit.move(x+dir*4-hit.x,0,1)
	-- 		hit.spd=vector(dir*3,-1.5)
	-- 	end
	-- 	hit.dash_time=0
	-- 	hit.dash_effect_time=0
	-- 	hit.djump=max_djump
	-- 	delta=8
	-- 	psfx"8"
	-- 	init_smoke()
		
	-- 	break_fall_floor(check(fall_floor,-dir,dir==0 and 1 or 0))
	-- end
end
function spring.draw(_ENV)
	local delta=min(flr(delta),4)
	clip(x-draw_x,y-draw_y,8,8)
	spr(sprite,x-delta*dir,y+delta*tonum(dir==0),1,1,dir>0)
	clip()
end

function do_spring(obj)
	local hits = obj.check_all(spring,0,0)
	foreach(hits,function(_ENV)
		if visible and delta <= 1 then
			if dir==0 then
				obj.move(0,y-obj.y-4,1)
				obj.spd.x*=0.2
				obj.spd.y=-3
			else
				obj.move(x+dir*4-obj.x,0,1)
				obj.spd=vector(dir*3,-1.5)
			end
			obj.dash_time=0
			obj.dash_effect_time=0
			obj.djump=max_djump
			delta=8
			psfx"8"
			init_smoke()
			
			break_fall_floor(check(fall_floor,-dir,dir==0 and 1 or 0))
		end
	end)
end



-- [bg parser] --
function parse_bg(s)
	local data,out = split(s,"|"),{}
	
	-- create table of shapes
	for i = 1,#data do
		out[i]=split(data[i])
	end
	
	return out
end

function draw_bg(bg)
	for i=1,#bg do
		local cur = bg[i]
		
		-- cache properties
		local s1,s2,s3,s4,s5,s6=
		cur[1],cur[2],
		cur[3],cur[4],
		cur[5],cur[6]
		
		-- circle filled
		if not s5 then
			circfill(s1,s2,s3,s4)
			
		-- circle outlined
		elseif not s6 then
			circ(s1,s2,s3,s4)
			
		-- rectangle filled
		elseif s6==1 then
			rectfill(s1,s2,s3,s4,s5)
			
		-- rectangle outlined
		elseif s6==2 then
			rect(s1,s2,s3,s4,s5)
			
		end
	end
	
end



-->8
-- [metadata]

--@begin
--level table
--"x,y,w,h,title"
levels = {
	"1,0,1,1",
	"0,0,1,1",
	"2,0,1,1.5",
	"3,0,1,1",
	"4,0,1,1",
	"0,1,1,1",
	"1,1,1,1",
	"5,0,1.625,1",
	"7,0,1,1",
	"3,1,1,1",
	"5,1,1,1,old trail",
	"4,1,1,1",
	"6,1,1,1",
	"0,2,1,1",
	"1,2,2,1",
	"3,2,1,1,summit",
	"4,2,1,1,bad ending"
	
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata = {
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches = {
}

--@end

-->8

title_data="106/72/c✽0♥cテc✽0☉cツc✽0🐱f⬇️0♥cセc✽0🐱f░0♥cスc✽0⬇️f♥0░cわ0☉c⌂c✽0░f⬇️6🐱f🐱0⬇️cわ0⬅️c♥c●0░f🐱6⬇️f🐱0🐱cわ0🐱f░0♥c✽c✽0✽f🐱6⬇️f🐱0🐱cわ0🐱f♥0●c⬇️c▒0웃f⬇️6🐱f🐱0🐱cわ0✽f●0✽c🐱0♥f⌂0🐱cわ0♥f●0░c▒0⬇️f●6⬇️f░0⬇️cっ0✽f●0░0🐱f░6●f🐱0✽cゅ0⬇️f♥0⬇️0🐱f⬇️6●f🐱0✽cア0🐱f⬇️6🐱f⬇️0🐱0🐱f⬇️6●f░0⬇️cし0●cか0░f⬇️6⬇️f🐱0🐱0🐱f░6░f●0🐱cさ0♥cお0✽f░6🐱f🐱0🐱0🐱f░0😐cこ0░f🐱0🐱cう0✽f●6🐱f🐱0🐱0⬇️f▒0🅾️cこ0⬇️f⬇️0🐱c▥0♥f♥6🐱f🐱0🐱0☉6●0✽cけ0🐱f⬇️0✽c⬆️0☉f웃6🐱f🐱0🐱c▒0✽6⌂0░cく0🐱f░0✽c➡️0♥f⬅️6⬇️f🐱0🐱c🐱0🐱6●0🐱a⬇️6🐱0⬇️cく0🐱f🐱6🐱f🐱0⬇️c…0✽f웃6🐱f⬇️6🐱f⬇️0🐱c🐱0🐱6░0✽a░6▒0🐱cく0🐱f🐱6⬇️f🐱0🐱c◆0░f⌂6⬇️f☉0🐱c🐱0🐱6🐱a🐱0●a░0🐱c♪0…c░0⬇️f🐱6🐱f🐱0🐱c🅾️0░f♥6♥f☉0🐱c🐱0🐱a░0♥9🐱a▒0🐱c⬅️0あf░0⬇️c🅾️0⬇️f░6⌂f☉0⬇️c🐱0🐱a⬇️9▒0⬇️c▒0⬇️9🐱a▒0🐱c●0웃6▒a✽6🐱0🐱a▒6▒0➡️c♪0⬇️f░6웃f⌂0⬇️c🐱0⬇️a🐱9🐱0🐱c▒0⬇️9🐱a▒0◆6🐱a♥6🐱0▒a▒6▒0▒6░0🅾️c✽0웃f⬇️6♥f⬅️0░c▒c🐱0⬇️a▒9⬇️0●9🐱a▒0⌂6⬇️0🐱a🐱9🐱0░a⬇️0▒a⬇️6✽0░6⬇️0⧗f⬇️6●f😐0✽c▒c⬇️0⬇️9⬇️0✽9⬇️0✽6⬇️0⬇️6▒a🐱0🐱a🐱9▒0●a🐱0▒9▒a✽6⬇️0⬇️6⬇️0🐱6🐱0웃6⬇️0⬇️f⬇️6✽f⬅️0✽c⬇️c⬇️0⬇️9░0🐱9●a🐱0🐱6🐱a▒0⬇️a⬇️9▒0🐱9🐱0웃9⬇️0⬇️a▒6🐱0⬇️a🐱0⬇️6♥0░6⬇️0⬇️f🐱6●f웃0●c░c░0🐱9♪a⬇️9▒a🐱0░a▒9🐱0🐱9🐱0⬇️c▒0✽9🐱0░a🐱6▒0⬇️a🐱0🐱6░a⬇️6🐱0🐱6⬇️0░f🐱6✽f●0☉c●c░0⬇️9☉0░9🐱a▒9🐱a🐱0⬇️a▒9⬇️0▒9🐱0⬇️c⬇️0🐱9⬇️0░9▒a▒6▒0⬇️a🐱0🐱a☉6▒0🐱6⬇️0░f🐱6✽f░0☉c☉c░0⬇️9●0♥9░a🐱0░9⬇️0▒9⬇️0🐱c⬇️0🐱9⬇️0░9▒a🐱0🐱9▒a🐱0🐱a⬇️0⬇️a🐱6🐱0▒6🐱0✽f🐱6✽f⬇️0✽c😐c✽0⬇️9░0웃9░a▒0░9⬇️0▒9⬇️0⬇️c▒0⬇️9⬇️0░9▒a🐱0🐱9▒a🐱0🐱a🐱9▒0░a🐱6▒0▒6🐱0✽f⬇️6⬇️f░0✽c😐c✽0⬇️9░0⬇️c⬇️0░9⬇️a🐱0░9⬇️0▒9🐱0⬇️c▒0⬇️9🐱0✽9▒a▒0⬇️9▒a▒0🐱a🐱9▒0✽9▒a▒6▒0✽c▒0🐱f⬅️0●c⌂c●0🐱9░0⬇️c░0⬇️9░a▒0░9⬇️0▒9⬇️0🐱c▒0🐱9⬇️0░9🐱a▒0⬇️9▒a▒0🐱a▒9🐱0✽9▒a▒6▒0✽c▒0⬇️f😐0✽c웃c●0⬇️9░0🐱c✽0🐱9✽a▒0⬇️9♥0🐱c▒0🐱9⬇️0░9▒a🐱0🐱9🐱a▒0🐱9⬇️0░9🐱a▒0⬇️c░0⬇️f🅾️0✽c♥c●0⬇️9░0⬇️c⬇️0⬇️9⬇️0▒9⬇️0🐱9♥0🐱c▒0🐱9⬇️0░9▒a🐱0🐱9⬇️0🐱9🐱0✽9▒a🐱0⬇️c✽0⬇️f🅾️0✽c●c♥0⬇️9⬇️0⬇️c🐱0░9⬇️0▒9⬇️a🐱9░0▒9🐱0🐱c▒0🐱9⬇️0░9▒a🐱0🐱9⬇️0▒9⬇️0✽9▒a▒6▒0🐱c●0░f◆0░c✽c♥0⬇️9░0♥9⬇️0⬇️9✽0▒9🐱0▒9🐱0🐱c▒0🐱9⬇️0웃9⬇️0▒9⬇️0░9🐱a▒6▒0🐱c♥0░f◆0⬇️c✽c☉0🐱9░0●9░0░9⬇️0웃c▒0★9⬇️0░9🐱a▒0⬇️c☉0░f◆0⬇️c░c☉0⬇️9░0░9░0➡️c▒0★9⬇️0░9▒a🐱0웃c⬇️0●f😐0⬇️c░c☉0⬇️9⬅️0⬅️c●0…c🐱0웃9▒a🐱0⬆️f✽6⬇️f⬇️0⬇️c⬇️c웃0⬇️9웃0░c⌂0♪4✽0🐱c🐱0…6⬇️0●c⬇️0●f⬇️6░f🐱0⬇️c⬇️c웃0⬇️9●0●c⬅️0●4⌂3🐱0🐱c웃0☉3▒6⬇️0▒6⬇️0🐱c✽0●f🐱6⬇️f⬇️0🐱c⬇️c⌂0♪c😐0🐱4⬅️3✽0🐱c◆0🐱3▒4▒6🐱0▒6⬇️0🐱c♥0░f🐱6⬇️f⬇️0🐱c⬇️c⌂0⌂c✽0●c░0🐱4🐱3⌂0❎3▒4🐱0🐱4▒6🐱0🐱c웃0⬇️f🐱6🐱f⬇️0🐱c⬇️c▥0☉c🐱0🐱3✽0🐱3🐱4▒0お4▒6🐱0🐱c웃0⬇️f🐱6🐱f⬇️0🐱c⬇️c▥0🐱9🐱0✽c▒0웃3🐱4▒0⬇️3🐱0▒3🐱4░0⬇️3░4⬇️0⬇️3▒4🐱0▒3▒4▒6🐱0🐱c웃0⬇️f♥0🐱c⬇️c▥0🐱9🐱a🐱0♪3🐱4▒0⬇️3♥4⬇️0▒3●4⬇️0🐱3▒4🐱0▒3▒4▒6▒0⬇️c웃0⬇️f●0⬇️c⬇️c➡️0⌂9🐱a⬇️0░c●0🐱3🐱4▒0⬇️3✽0🐱3▒4🐱0▒3🐱0⬇️3🐱4🐱0🐱3▒4🐱0▒4🐱6▒0⬇️c☉0⬇️f🐱6🐱f⬇️0⬇️c⬇️c…0😐9🐱a░0🐱c●0🐱3🐱4▒0⬇️3░0░4🐱0♥3▒4🐱0🐱3▒4🐱0▒4🐱6▒0🐱c♥0✽f🐱6🐱f⬇️0🐱c░c◆0░a░0♥9░0♥c▒0🐱3🐱4▒0⬇️3🐱4▒0⌂3✽4🐱0🐱3▒4▒0🐱4▒6🐱0🐱c▒0⌂f🐱6🐱f░0🐱c░c◆0⬇️9⬇️a⬇️0➡️c▒0🐱3⬇️0⬇️3🐱4▒0웃3●4🐱0▒3▒4🐱0🐱6🐱0😐f⬇️6⬇️f⬇️0⬇️c░c◆0🐱9✽a░0⬅️a🐱0🐱c▒0🐱3⬇️0⬇️3🐱4▒0⬇️c⬇️0🐱3⬇️0🐱3🐱4🐱0▒3▒4🐱0🐱6🐱0●f♥6░f⬇️0░c░c◆0🐱9●a✽0🐱c░0⬇️a🐱0🐱c▒0🐱3⬇️0⬇️3🐱4▒0⬇️c⬇️0🐱3🐱0░3▒4🐱0▒3▒4🐱0▒4▒6🐱0🐱f⬅️6⬇️f⬇️0░c✽c◆0🐱9⬇️0░a░0🐱c░0⬇️a🐱0🐱c▒0🐱3⬇️0░3▒4🐱0🐱c⬇️0🐱3🐱0░3▒4🐱0▒3▒4🐱0▒4▒6🐱0🐱f…0░c●c◆0⬇️9🐱0⌂c⬇️0⬇️a⬇️0🐱c▒0🐱3⬇️0░3🐱4▒0🐱c⬇️0🐱3♥4🐱0▒3▒4🐱0▒4▒6🐱0░f😐0✽c♥c◆0◆c🐱0░a⬇️0🐱c▒0🐱3⬇️0░3🐱4▒0🐱c⬇️0🐱3♥4🐱0▒3▒4🐱0▒4▒6🐱0⬆️c☉c…0웃c⬇️0♥a⬇️0⬇️c▒0🐱3⬇️0░3🐱4▒0🐱c⬇️0⬇️3░0▒4⬇️0✽4▒6🐱0★c⌂c♪0ˇa░0⬇️c▒0🐱3⬇️0░3🐱4▒0🐱c⬇️0…4▒6🐱0🐱cあc♪0♥a⬇️0♥a☉0🐱c🐱0🐱3⬇️0웃c░0😐c▒0♥cあc♪0🐱a🐱0⬇️a♪9▒a░0🐱c🐱0🅾️c➡️0♥cあc♪0🐱a░0🐱a⬅️9▒a✽0🐱c🐱0♥cみc♪0🐱9🐱a☉9♥a✽0⬇️cるc♪0⬇️9🅾️a♥0⬇️cるc♪0░9⌂a웃0⬇️cれc♪0🐱a…9⬇️a🐱0⬇️cれc♪0🐱a🅾️9░a🐱0⬇️cろc♪0🐱a░9░a░9⬇️0▒9⬇️0░cろc♪0✽9🐱a░9░0웃cわc♪0✽9☉0⌂cをc…0🅾️cアc…0😐cウ"
function px_disp(data,x,y,t)
	local px,py=0,0
	local w,h,s=unpack(split(data,"/"))
	
	for i=1,#s-1,2 do
		local col,len=tonum(s[i],1),ord(s[i+1])-128
		if col~=t then
			line(x+px,y+py,x+px+len-1,y+py,col)
		end
		px+=len
		if px>=w then
			px=0
			py+=1
		end
	end
	
	return w,h
end

function print_align(str,x,y,c,ha,va)
	local w,h = print(str,0,128)
	?str,x-w*(ha or 0),y-(h-128)*(va or 0),c
end
-->8
function transition(id)
	if (transition_target) return
	transition_target,transition_timer,transition_dir = id,0,1
	game_paused = false
end

function transition_draw()
	if (not transition_target) return
	local col = 0
	transition_timer = appr(transition_timer,transition_dir,.1)

	-- transition out
	if transition_dir==1 then
		local yy = 128-128*transition_timer
		rectfill(0,yy,128,128,col)
		for i=0,128,8 do polyfill(col,i,yy-1,i+4,yy-5,i+8,yy-1) end
		if (transition_timer==1) load_level(transition_target) transition_dir=0
	
	-- transition in
	else
		local yy = 128*transition_timer
		rectfill(0,0,128,yy,col)
		for i=0,128,8 do polyfill(col,i,yy,i+4,yy+4,i+8,yy) end
		if (transition_timer==0) transition_target=nil
	end
end

function polyfill(col,...)
	color(col)
	local p={...}
	local p0,spans=p[#p],{}
	local x0,y0=p[#p-1],p[#p]
	
	for i=1,#p-1,2 do
	 local x1,y1=p[i],p[i+1]
	 local _x1,_y1=x1,y1
	 if(y0>y1) x0,y0,x1,y1=x1,y1,x0,y0
	 local cy0,cy1,dx=y0\1+1,y1\1,(x1-x0)/(y1-y0)
	 if(y0<0) x0-=y0*dx y0=0
	 x0+=(-y0+cy0)*dx
	 for y=cy0,min(cy1,127) do
	  local x=spans[y]
	  if x then
	   local x,x0=x,x0
	   if(x0>x) x,x0=x0,x
	   rectfill(x0+1,y,x,y,col)
	  else
	   spans[y]=x0
	  end
	  x0+=dx                   
	 end           
	 --break
	 x0,y0=_x1,_y1
	end
end

__gfx__
0000000000000000000000000ffffff000000000000000000000000000661660000000000000000000000000000000000bba0bb00e7667e00000000000000000
000000000ffffff00ffffff0f11661660ffffff00fffff000000000001fffff000000000000000000000000000000000baa2aaab0e6ff6e00000000000070000
00000000f1166166f11661661ffff55ff1166166661661f00ffffff01ff1f51f0000000004333340000000000000000002ffff20077777700000000000063030
000000001ffff55f1ffff55ffff1551f1ffff55ff55fff10f1166166fff5555f000000000444444000000000000000000f6ffff0077666e00766667000060303
00000000fff1551ffff1551f0f555550fff1551ff1551ff01ffff5ffff55555f000000000033330000000000000000000ffff6f0076667e00030030000060303
000000000f5555500f555550007767000f555550055555f0ffff555f0f1111f0000000000034340000000000000000000ff6fff0076766e00003300000063030
0000000000776700007767000e0000e00e776700007677e00f515510007767000000000000343400000000000000000000ffff00077666700030030000070000
0000000000e00e0000e000e00000000000000e000000e0000ee777e000e00e0000000000033333300000000000000000000ff000007777000003300000000000
76666667766666677666066700000000006666600006660000006000000000000000000000000000000000000000000000ffff000000000000000000e0000000
6111111661117116611706160000000000600060000606000000600000000000000000000000000000000000000000000ffffff000ee00000ee00e000e00000e
6111111661116116767007160666666000670760000606000000600000000000000000000000000000000000000000000feffff000eee0e00eee000000000000
6111111667670716000000776ffffff600766670000767000000600000000000000000000000000000000000000000000ffffff00eeeeee00ee0000000000000
6111111661170676670000006ffffff600006000000060000000600000000000000000000000000000000000000000000ffffff00eeeeee00000e00000000000
6111111661116116617007666666666600776000000760000000600000000000000000000000000000000000000000000ffffff00eeeeee000000ee000000000
6111111661171116617071166ff00ff6000760000000600000006000000000000000000000000000000000000000000000ffff000e0eee00000e0ee00e0000e0
7666666776666667770076676ffffff600666000000760000000600000000000000000000000000000000000000000000000000000000000e000000000000000
988899880000000089a9999999999998000000000070000000700000007000000000000000000000000000000000300000000000000000000000000000000000
88aa98a9000000008a9999999999aa9800000008007ddddd007d0000007dddd00000000000000000000000000003030000000000000eeeee0000000000000000
8aa999a9000000006899999999aaa98600000068072ddd00072dd000072ddddd000000000000000000000000000030000000000000eedde00000000000000000
89a9aa9900000000068aa999999988600000069807dd000007ddddd007d0000d00000000000000000000000000030000000000000edeee000000000000000000
989a9999000000000689aaa99999986000000698070000000700dddd0700000000000000000000000000000000000000000000000eedd0000eeeee0000000000
8aa999990000000068a99999999aa986000000687200000072000000720000000000000000000000000000000003f000000000000eeee0000eeeede00ee00000
8a9aa99900000000889aa9999999aa9800000008700000007000000070000000000000000000000000000000000ff000000000000e0000000e0000ee0eeeeee0
89a999990000000098899999999999980000000070000000700000007000000000000000000000000000000000006000000000000000000000000000000eeeee
9aaa9999000000000000000000077000000770000000000000000000000000ff0000000f00000000000000000000000000000000aaeaeea00a000000000000aa
8a99999900000000000000000000e700000e77000000000000000ff0000000000000000000000000000ffff00000000000000000aee0aeeaaeeee000000eeeea
899aa99900000000043333400000e070000e070000000000000000ff000f0000000ff000000fff000000f66f0000330000e000000ea00ae0eeaaae0000000aee
98aa9999000000000444444060e7e77e076e7e0000000000000ff000000ff000000fff000000ff0000000ff0000033000ea000e00e000ae0ea0000000000000a
9a99a99900000000003333007600e070076e070000000000000fff0000ffff000ffffff000ff66f000000000000033000ea000e00e000ae0a0000000000000ae
8aa99a9900000000003434000770e700007770000000000000ffff000ffffff00fff66f00ffffff0000fff00000f30000ea00ae000000e00eea0000000eaaaee
89aa88aa00000000003434000066660000666600000000000ff6fff00ff66ff00fff66f00fff66f000f6fff00003f000aeea0eea00000000aeeee000000eeeea
9899898800000000033333300777777007777770000000000ff66ff000f66f0000f66f0000f66f0000f66ff0000060000aeeaeaa00000000aa000000000000a0
9babbababababababababab9988998899999a9a90000000000000000000000000000000000000000000000800000008000000ff0676767676767676767676767
babbbab8bab8bab8bab8bbab89aa89aa99999a9a08000800000000000000000000000000000000000029aa800029aa8000fffff0222222222222222222222222
babbbab8bab8bab8bab8bbab9aa9a99a9aaa99aa0800080000b0000000b000000000b0000000000007faff9a07f92f9a0fffffff000720000000000000027000
bab8bab8bab8bab8bab8bbab9a99aa9aa9a9999a0908089000b000b000ab00ab000ab00b00000000097f99f2092f99f20fffffff007200000000000000002700
bab88b88bab88b88bab88bab88999a999a999a9909889898b0ba00b00b0b00b000ab00baab000000f7a9f792f7f9f792fffff6ff072000000000000000000270
bb8888988b8888898b8888bb98a99999a9999aa909889898b00b0ba00b0b0ab00b0b00b00ba0000baaff7ff0aa3ffff0ffff66f0720000000000000000000027
888aa9aa888a989a8889a8888a999999a99a99a989888898ab0bab0a0b0bab0a0b0baba00ab00abb9ff66fa893f66ff8fff66fff200000000000000000000002
88999aa99899a99a989a99888a99999999a99999898888880bababa00bababa00bababaabbababa00f6666f00f6666f00f6666f0000000000000000000000000
89a99999999999999999999898998889a9a9aaa900000000000000000000000000000000000b90000000000000f6ff0000f66f00000000006767676767676776
8a9999999999999999999aa98a98aa88aa999a9a0000000000000000000000000000000000baab0000000000009ff00000fff000000000006722222222222276
9899999999999999999aaa98a98a9aa89aaa99a90000000000000000000000000000000007989bb00000000000077000000f7000000000002200000000000022
89aa999999999999999999a9a9aa98a9a9a9a99a000000000000000000000000000000000088a8bb000000000007700000077000000000000000000000000000
9aaaaa999999999999999998999a9889aa99a99900000b000000b000000b0000000000000b89a980000000000007700000077000000000000000000000000000
8a999999999999999999aa889a999a9899a9aa9a0b000b000b00b000000b000000000000bb9b9b90000000000077770000777700000000000000000000000000
889aa9999999999999999aa99a9999a9aa9a9a9a0ab0ba0b0ba0b00a0b0ab0b0bb0b000b089b99b0000000000077170000771700000000000000000000000000
988999999999999999999998999999a89a9999a900a0a0ba00a0a0b00aa0a0a00aa0a0ba00827800000000007717777077177770000000000000000000000000
9aaa9999999999999999aa89899999980a802080009809980000000000000000077007700ba9aab07779aa760000000000000000000000000000000720000000
8a999999999999999aa999a8899999980a29228a00080080000000000000000002772720bb89a9bb74a924560000000000000000000720000000000720000000
899aa999999a99999999a89989999998299a2a9a00998080006000000000000000277200b8ab9a8b799545470000000000000000000720000000007207000000
98aa999999aa999a999aaa8989999998829aaa920090889006690000000000000002700009b89a90925454570000000000000000002722000000007007000000
9a999999999a9a9a999999a889999998a2a2a2220000809966906000000000000002700000896800254545470000000000000000007207000000072002700000
8aa99a999a999a8999a88aa889999998aaa092900098800900096600000000000027700000276000777777770000000000000000007007000000070000700000
89aa88aaa89aa88aaa98aa88899999989a2299a809908900000a900a000000000022720000227600008220a000000000000000000a9009a0000002008aa9a000
98998988998899888989988998888889000289a00000800090a900a900000000727227707272276000027a000000000000000000aa82929a000a9988999a9a00
9babbababababababababab998888889000000000000000000000000000000000000000000000000000000000000000000000000a927272a00a9a9aa8899a9a0
babbbab8bab8bab8bab8bbab89999998000000000000000000000000000000000000000000000000000000000000000000000000a972728900aa929a82229aa0
babbbab8bab8bab8bab8bbab899999980000000000000000000000000000000000000000000000000000000000000000000000000a09809000a9222a227280a0
bab8bab8bab8bab8bab8bbab899999980000000000000000000000000000000000000000000000000000000000000000000000000000900000a0222927278000
bab88b88bab88b88bab88bab89999998000000000000000000000000000000000000000000000000000000000000000000000000000000000000827272789000
bb8888988b8888898b8888bb89999998000000000000000000000000000000000000000000000000000000000000000000000000000000000000082727889000
88899999888998998889988889999998000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000890000
98888888888888888888888998888889000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000
44250000000000000000000000000000454544444525054544454444454445442505444445444445250525000000054500000000000000000000000000000000
44441515161616161616161615454544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45250000000000000000000000000000444544454425054444454545441616162605454445444544250525000000054400000000000000000000000000000000
45444425d6000000000000d605154445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
452500000000000000000000000000004544161616260544454444442656e6f65606161616161616260525000000054500000000000000000000000000000000
15444425d7000000105200d705444515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44252323000000000000000055550000162600e6f6560616161616265600e7f70056005600d60056560525000000054500000000000000000000000000000000
44441525d4e4e4e4e4e4e4f405441544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44440424000000000000000004240000355600e7f700565656565656000000000000005600d70000560525000000054400000000000000000000000000000000
1616162600000000000000000616161600000000000000000000000000baab00000000000000000000baab000000000000000000000000000000000000000000
45250515350000000000000022250000255600000000005656565600000000000000000000000000000525540000054500000000000000000000000000000000
565656560000000000000000565656560000000000000000000000000088a8ab00000000000000000088a8bb0000000000000000000000000000000000000000
44250544320000662366000005250000255600000000000056560000000000000000000000000000000515350000054400000000000000000000000000000000
56560056000000000000000000565656000000000000000000000000bb9b9b900000000000000000bb9b9b900000000000000000000000000000000000000000
45250544259055041424000005250000250000000000000056560000000064645454232323232354550616260000054400000000000000665552556600000000
00560056000000000000000000560056000000000000000000000000008278000000000000000000008278000000000000000000000000000000000000000000
16160616260424061626550022250000250000000000000000000000000004141414240414141414141414240000054500000000000000041414142400000000
00560000000000000000000000560056000000000000000002772720ab89a9ab0000000000000000bb89a9bb0000000000000000000000000000000000000000
56565656344544240414249006260000320000000000000000000000000022444444250544454445444544250000061600000000000000054544442500000000
0000000000000000000000000056000000000000000000000002700009b89a90000000000007000009b89a900000000000000000000000000000000000000000
56565656064445252215250424240000320000000000000000000000000022454444250545444444454445260000343500000000000054064445452500000000
00000000000000000000000000000000000000000000000000277000002770000000000000272000002760000000000000000000000000000000000000000000
00000000560616262215260616260000320000000000663366000000000022444444250616164545444426560000054400000000005404350545442564645500
00000000009500950000000095009500000000000000000072722770727227700000000072722770727227600000000000000000000000000000000000000000
00000000950000000626000000000000260000000000041424000000000006161616260000000616162656560000054400000000000445250616162604142400
00005500009655965464545496009600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66001000965464645555545564645455000000005454051525545400000095000000000000000000000000000000054455103355550544250414141444452554
00041414240414240414142404142404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14141414141414142404141414141414555510550414444444142455555596665564555454556454555454546466054414141414240545250545444445454414
00064544250616260545442506162605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45454445454445442505444445454444141414144545454545454514141414141414141424041414141414141424054444444544250544250544454544444544
00000515451414144515454414141444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccc775500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccc776670000000000000000000000000070000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccc77ccc776777711111111111111110000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccc77ccc776661111111111111111110000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccc7775511111111111111111110000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccc77776671111111111111111110000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccc77cccccccccc777777776777711111111111111110000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccc77cccccccccc777777756661111111111111111110000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccc77555555551111111111111111111110000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccc777555555500000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
ccccccccccccccccccccccccccccc777555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccc7777555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccc7777555500000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000
ccccccccccccccccccccccccccccc777555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccc777550000000300b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccc6cccccccccc7750000000003b330000000000000000000000000000000000000000000007000000000000000000000000000000000000
cccccccccccccccccccccccccccccc77000000000288882000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccc77000000700898888000000000000000000000000000000111111111111111111111111111111111111111111111110000
ccccccccccccccccccccccccc77ccc77000000000888898000000000000000000000000000000111111111111111111111111111111111111111111111110000
ccccccccccccccccccccccccc77ccc77070000000889888000000000000000000000000000000111111111111111111111111111111111111111111111110000
ccccccccccccccccccc77cccccccc777000000000288882000000000000000000000000000000111111111111111111111111111111111111111111111110000
ccccccccccccccccc777777ccccc7777000000000028820000000000000000000000000000000111111111111111111111111111117111111111111111110000
cccccccccccccccc7777777777777777000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111110000
cccccccccccccccc7777777777777775000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111110000
cccccccccccccc775777777566656665000006000000000000000000000000000000000000000111111111111111111111111111111111111111111111110000
ccccccc66cccc7777777777767656765000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccc66cccc777777c777767706770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccc777777cccc7707000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccc777777cccc7707000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccc777777cc77700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccc7777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccc775777777500000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111
cccccccccccccc776665666700000000000000000000000000000000000000000000000000111111111111111111111111111111111771111111111111111111
ccccccccccccc7776766676500000000000000000000000000000000000000000000000000111111111111111111111111111111111771111111111111111111
ccccccccccccc7776770677000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111
cccccccccccc77770700070000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111
cccccccccccc77770700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccc770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccc770000000000000000000000000000000000000000001111111111111111111111111111111111110000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000001111111111111111111111111111111111110000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000001111111111111111111111111111111111110000000000000000000000000000000000
cccccccccccc77770000000000000000000000000000000000000000001111111111111111111111111111111111110000000000000000000000000000000000
cccccccccccc77770000000000000000000000000000000000000000001111111111111111111111111111111111110000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000001111111111111111111111111111111111110000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000111111111111111111111111111111111111111111111111110000000000000000000000000000000000
cccccccccccccc770000000000000000000000000000111111111111111111111111111111111111611111111111110000000000000000000000000000000000
cccccccccccccc770000000000000000000000000000111111111111111111111111111111111111111111111111110000000000000000000000000000000000
cccccccccccccc770000000000000000000000000000111111111111111111111111111111111111111111111111110000000000000000000000000000000000
ccccccccc77ccc770000000000000000000000000000111111111111111111111111111111111111111111111110000000000000000000000000000000000000
ccccccccc77ccc770000000000000000000000000000111111111111111111111111111111111111111111111110000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000111111111111111111111111111111111111111111111110000000000000000000000000000000000000
cccccccccccc77770000000000000000000000000000111111111111111111111111111111111111111111111110000000000000000000000000000000000000
cccccccc777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc777777750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccc77551111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000
cccccc77667111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000
c77ccc77677771111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000600000000000000
c77ccc77666111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000
ccccc777551111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000
cccc7777667111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000
77777777677771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777775666111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555511111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51555555551111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55551155555111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55551155555511111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555551111000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55155555555555111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555500000000000000000000000000000000000000000000000000000000001111111111111111111114999999449999994499999941110000000000000
55555555550000000000000000000000000000000000000000000000000000000001111111111111111411119111111991111119911111191111100000000000
55555555555000000000000000000000000000006000000000000000000000000001111111111111111951519111111991111119911111191111100000000000
55555555555500000000000000000000000000000000000000000000000000000001111111111111111915159111111991111119911111191111100000000000
55555555555550000000000000000000000000000000000000000000000000000001111111111111111915159111111991111119911111191111100000000000
55555555555555000000000000000000000000000000000000000000000000000001111111111111111951519111111991111119911111191111100000000000
55555555555555500000000000000000000000000000000000000000000000000001111111111111111411119111111991111119911111191111100000000000
55555555555555550000000000000000000000000000000000000000000000000001111111111111111111114999999449999994499999941111100000000000
55555555555555555555555500000000077777700000000000000000000000000000000000000111111111111111111111111111111111111111100000000000
55555555555555555555555000000000777777770011111111111111111111111111111111111111111111111111111111111111111111111111100000000000
55555555555555555555550000000000777777770011111111111111111111111111111111111111111111111111111111000000000000000000000000000000
55555555555555555555500000000000777733770011111111111111111111111111111111111111111111111111111111000000000000000000000000000000
55555555555555555555000000000000777733770011111111111111111117711111111111111111111111111111111111000000000000000000000000000000
55555555555555555550000000000000737733370011111111111111111117711111111111111111111111111111111111000000000000000000000000000000
555555555555555555000000000000007333bb370011111111111111111111111111111111111111111111111111111111000000000000000000000000000000
555555555555555550000000000000000333bb300011111111111111111111111111111111111111111111111111111111000000000000000000000000000000
55555555555555555000000000060000033333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555555555555550000000000000003b33330000000008888888000ee0ee00000000000000000000000000000000000000000000000000000000000000000
5555555555555555555000000000003003333330000000088888888800eeeee00000000000000000000000000000000000000000000000000000000000000000
555555555555555555550000000000b00333b33000000008888ffff8000e8e000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555500000000b30003333000000b00888f1ff1800eeeee00000000000000000000000000000000000000000000000000000000000000000
55555555555555555555550003000b0000044000000b000088fffff000ee3ee00000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555000b0b30000044000030b0030083333000000b0000000000111111111111111111111111111888811111111110000000000000000
555555555555555555555555003033000099990003033030007007000000b0000000000111111111111111111111111118888881111111110000000000000000
55555555555555555555555557777777777777777777777557777777777777750000000111111111111111111111111118788881111111110000000000000005
55555551155555555555555577777777777777777777777777777777777777770000000111111111111111111111111118888881111111110000000000000055
5555550000555555550000557777ccccc777777ccccc77777777cccccccc77770000000111111111111111111111111118888881111111110000000000000555
555550000005555555000055777cccccccc77cccccccc777777cccccccccc7770000000111111111111111111111111118888881111111110000000000005555
55550000000055555500005577cccccccccccccccccccc7777cccccccccccc770000000111111111111111111111111111888811111111110000000000055555
55500000000005555500005577cc77ccccccccccccc7cc7777cc77ccccc7cc770000000111111111111111111111111111161111111111110000000000555555
55000000000000555555555577cc77cccccccccccccccc7777cc77cccccccc770000000111111111111111111111111111161111111111110000000005555555
50000000000000055555555577cccccccccccccccccccc7777cccccccccccc770000000111111111111111111111111111161111111111110000000055555555
00000000000000005555555577cccccccccccccccccccc7777cccccccccccc775000000000000005500000000000000000006000000000050000000055555555
000000000000000005555555777cccccccccccccccccc77777cccccccccccc775500000000000055550000000000000000006000000000550000000050555555
000000000000000000555555777cccccccccccccccccc77777cc7cccc77ccc775550000000000555555000000000000000006000000005550000000055550055
0000000000000000000555557777cccccccccccccccc777777ccccccc77ccc775555000000005555555500000000000000006000000055550600000055550055
0000000000000000000055557777cccccccccccccccc7777777cccccccccc7775555511111155555555555551111111100000000000555550000000055555555
000000000000000000000555777cccccccccccccccccc7777777cccccccc77775555551111555555555555551111111100000000005555550000000055055555
000000000000000000000055777cccccccccccccccccc77777777777777777775555555115555555555555551111111100000000055555550000000055555555
00000000000000006600000577cccccccccccccccccccc7757777777777777755555555555555555555555551111111100000000555555550000000055555555
00000000000000006600000077cccccccccccccccccccccc77777775555555555555555555555555111111111111111100000000555555555000000055555555
000000000000000000000000777ccccccccccccccccccccc77777777155555555555555555555551111111111111111100000000555555555500000055555555
000000000000000000000000777ccccccccccccccccccccccccc7777005555555555555555555511111111111111111111111111555555555551110055555555
0000000000000000007000707777ccccccccccccccccccccccccc777000555555555555555555111111111111111111111111111555555555555110055555555
0000000000000000007000707777cccccccccccccccccccccccccc77000155555555555555551111111111111111111111111111555555555555510055555555
000000000000000006770677777cccccccccccccccccccccccc7cc77000115555555555555511111111111111111111111111111555555555555550055555555
000000000000000056765676777ccccccccccccccccccccccccccc77000111555555555555111111111111111111111111111111555555555555555055555555
00000000000000005666566677cccccccccccccccccccccccccccc77000111155555555551111111111111111111111111111111555555555555555555555555
000000000000000557777777cccccccccccccccccccccccccccccc77000111155555555511111111111111111111111111111115555555555555555555555555
000000000000005577777777ccccccccccccccccccccccccccccc777000000555555555000000000000000001111111111111155555555551555555555555555
00000000000005557777ccccccccccccccccccccccccccccccccc777000005555555550000000000000000001111111111111555555555551155555555555555
0000000000005555777cccccccccccc6cccccccccccccccccccc7777000055555555500000000000000000001111111111115555555555551115555555555555
000000000005555577cccccccccccccccccccccccccccccccccc7777000555555555000000000000000000000000000000055555575555550000555555555555
000000000055555577cc77ccccccccccccccccccccccccccccccc677005555555550000000000000000000000000000000555555555555550000055555555555
000000000555555577cc77ccccccccccccccccccccccccccccccc777055555555500000000000000000000000000000005555555555555550000005555555555
000000005555555577cccccccccccccccccccccccccccccccccccc77555555555000000000000000000000000000000055555555555555550000000555555555

__gff__
00000000000000000000000000000000000000000000000000000000000000000000030300000000000000000000000000000000000000000000000002020202030303030344400000000000000a0a0a03030303034000000000000000000a0a0303030302040400020000000002020203030303000000000000000000020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5161615144515152000060445151514454545452504454445444545200000050515161616161616161515200000000005454525054445454445452000000000061616144545454442300000000504454604454544454525054444454445250515200000000005044515100000000000000505161616161626061616161615151
52006d6051514462000000606161616154544452606161616161545200000050516200656d006e6f6560620000000000544452504444544444442300000000006500002254446161620000000050444453604444544452504454444454525051520000000000504454510000000000000050526500006e6f0000656565655051
52007d65604452650000006e6f65200061616162006e6f006500505200000050523e00657d007e7f000000000000005944445250544454445454620000000000650c00224452656e6f0000000060616151536061616162606161616154525051520000000000504454540000000000000060626500007e7f0000006565656061
52000000005052650000007e7f00300041414200007e7f006500606200000050523e000000000000000000000066556961616260616161616162000000000000000000224452657e7f000000006e6f004451536565006e6f0065653f606250515200000000005054444400000000000000590000000000000000000065656543
6245010000606255000000000000404144445200000000006500000000000060523e000000000000003c3c00004041414141414265650000006d000000000000000000606162000000000000007e7f004454526565007e7f0065003f435360616200000000006061616100000000000066694546325566000000000000656550
41414200004040424d5f0000550050514454520000000000000000000000006d523e0c000000000000404200002254445454545265000000007d0000000000000000006d00000000000000000000000054445265000000000000003f505265000000000000006e6f0065000000000000414141414141423e0000000000006550
514462000022512300000000707154445454520000000000000000000000007d52000000000000000050520000504444444461624545553246464655556600000000007d00000000000000000000454544445200000000000000003f505265000000000000007e7f0065000000000000444444444454523e0000000000000050
5152000000505162000000006d0060445444520000003c3c3c3c0000000000006232323245464646325052000050445454524041404141424041414141420000325546556600000000006655554640416161620000003c3c0000003f6062555532000000000000000000000000000000445444445444523e0000000000000050
445200000060623d000000007d0065504461620000004041414200000000000041414142404141414144520000504444445260616161616260616154546200004141414142000000000040414141444465656500000040420000003f4041414141423e00000000555546000000000000444454444461623e0000000000000050
61620000003d3d000000000000000022626500000000504454520000000000004454445250544454445462000050545454546162006e6f0065000060616200004454544423000000000022445444544400650000000050520000003f6061616144523e000000004041410000000000005444444462006d000000000000000050
65000000000000000000000000000050006500000000605444626600000000006161616260616161616200000050444461616265007e7f006500006540410000616144546200000000006061445444540000000000005052000000006500006550523e000000005044620000000000004444445265007d000000000066464660
0000000000000000000000000000005000000000000000506240424546554632414141414200006e6f000000005054546500590000000000000000005052000000656062000000000000006d224454546601330000005052000000006500006560623e0000000060626500000000000054444452650000000000003f40414141
4566465566000000000000000000005045460100000000404144524041414141444444445200007e7f00000000604444000c696601000000000000006062000000000000000000000000007d50544444414142000000505200000000000000000059000000000059000c00000000000044444452000000000000003f50545444
4141414142550000000000000055455041414200000000504454525044545444616154442300000000000000000050544545404142554646325533005900000045015546556646554600325550445444545452000000505200000000454532454569454645464569666600000000000044445452450155463300003f50444454
4451444454425546474655454540415454445200000000605444625044445444414250545200000000000000000060614141445444414141414142556955555541414141414240414141414250544454544462000000505200000000404141414240414141414141414100000000000044544452404141414200003f50544454
5444515151524041414141414250445151520000000000005052504454544451445260616245554600000000000065655444544451444444444444414141414144544454445250544444545250444444445265000000505200000000505151515250515151515151515100000000000044444452504454445200003f50445444
0000000000000000000000005054445100505161616161616162605454545444445240414041414200000000000000655444446161616200000000000060616144545200000000000000000000000050445444545200000000005044544454445250545444544452504444520000000000000000000000000000000000000000
00000000000000000000000050445444005052656565656565435360445444546162606144514423000000000000555544616265006e6f0000000000006d006554445200000c00000000000000000050544454445200000000005054544444545453604454445452504454520000000000000000000000000000000000000000
454645554666000000000000505444540050526500000065655054536044544465006d0060445452000066555545404162650065007e7f0000000000007d000044545200000000003c3c3c3c00000050445444546200000000005044445454445454535044544452505444523266660000000000000000000000000000000000
414142404142000000000000224454440060625555320000655044545350444465007d00656061620000404141414444656500650000003c3c0000000000000061616245465555464041414200000050616161620000000000006061614444544444525054445452504454544141420000000000000000000000000000000000
44445250442300000000000060616161006d6540414200000050446162606161000000005900000000005044544454516565000000000040420000003c3c00004141414141414142504454520000006065656e6f0000000000006e6f656061615444526061616162606161614454520000000000000000000000000000000000
444452505452000000000000006e6f00007d65505152000000505265656e6f004547016669665555464650444454445465000000000000505200000040413e005444445444546162606144520000004365657e7f0000000000007e7f6565656544545265006e6f00006e6f006044520000000000000000000000000000000000
444452504452000000000000007e7f00000000505152000000606200007e7f004141414141414240414154444454445400000000000032545200000050523e00544454444452404141425052000000506565000000000000000000006565656554545265007e7f00007e7f006550524d00000000000000000000000000000000
44445250542300000000000066464646000000505152000000656559000000004444444444445250444454445454545400000000000040445200000060623e0061616161616250445452606200000050454545000000006a45453245595959595444526500000000000000006550520000000000000000000000000000000000
44445250445200000000000040414141000000505152000000656569663245450000000000000000000000000000000055460155663350545200000059000000656e6f656e6f606144523e0000000050414142000000004041414142696969694454526566013332000000000060620000000000000000000000000000000000
616162504423000000000000224454444d4e4f605152000000404141414141410000000000000000000000000000000041414141414250445200000069454646657e7f657e7f656550523e0000000060545452000000005044544452414141414461626540414142000000000000590000000000000000000000000000000000
65656560445200000000000022544454000000655052000000606154444444540000000000000000000000000000000044445444546250545200000040414141000000000000000060623e0000000000444452000000005044545452604454546220005950445452554609454645696600000000000000000000000000000000
6500650060610000000000005044544400000065606200000065655054544444000000000000000000000000000000004454445462434454520000005054444455013332464609660059000000000000445452000000005054445444535044445330006950544462404141424041414100000000000000000000000000000000
0000000000000000000000005054445400000000005900000000655044445454000000000000000000000000000000005444545243545444520000005044545441414141414141424569454632550955544452550133556044444454525044544453435360616243544454525044544400000000000000000000000000000000
4501464646554646555555005044544446454666456955330166455044544444000000000000000000000000000000006161616260616161623c3c3c5054444444545444544454524041414141414241445452404141414250545444525054445452505243534344545444525054445400000000000000000000000000000000
4141424041414141414141425054445441414141424140414141425054445444000000000000000000000000000000004141414142404141414142425044445454545444545444525044445444545444445452504454445250544454525044545452505250525054544454526044445400000000000000000000000000000000
5454525054445444545444525044544454544444525044445444525044545454000000000000000000000000000000004444444452505454545454525054444444544454444454525054445444444444544452505444545250445454525044544452505250525044445444445350544400000000000000000000000000000000
__sfx__
10100c0018775187251c7751c7251f7751f72524775247251f7751f7251c7751c72518700187001c7001c7001f7001f70024700247001f7001f7001c7001c70018700187001c7001c7001f7001f7002470024700
10100c0018775187251d7751d7252077520725247752472520775207251d7751d72518700187001c7001c7001f7001f70024700247001f7001f7001c7001c70018700187001c7001c7001f7001f7002470024700
00c000001885018850189501895018850188501895018950188501885018950189501885018850189501895014850148500f8500f85011950119500c9500c95013950139500e9500e9500e8500e8500e95013850
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
68c000001c5441f544205441d5441f5441f54524544245451c5441f544205441d5441f5441f545245442654427544245442b5442b5452e534295442c5442c5451c504185441a54422544215441e5441f5441f545
002000001d0401d0401d0301d020180401804018030180201b0301b02022040220461f0351f03016040160401d0401d0401d002130611803018030180021f061240502202016040130201d0401b0221804018040
00100000070700706007050110000707007060030510f0700a0700a0600a0500a0000a0700a0600505005040030700306003000030500c0700c0601105016070160600f071050500a07005050030510a0700a060
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
c40f00201a7341a7241c7341c7241d7341d7242173421724237342372421734217241d7341d7241c7341c7241a7341a72418734187241a7341a7241c7341c7241f7341f72421734217241f7341f7241c7341c724
91f000000277402775077740777500774007750277402775097740977507774077750c7740c775047740477502774027751177415774107740c7740e7740e7750777407775057740577504774047750077400775
011000001250015500125000000012500155001250000000155001850015500000001550018500155000000012500155001250000000125001550012500000001550018500155000000015500185001550000000
010800200e5500000015550000000e5500000015550000000e5500000016550000000e5500000016550000000e5500000015550000000e5500000015550000000e5500000016550000000e550000001655000000
012000201f5501a550175501a5500000000000006600000000000175701657117571185511755016573000001f5501a550175501a550000000000000660000000000000000000000000000000000000000000000
011000202b700267002b7002f70032700000002f7000000037700000003270000000000000000000000000002f7002b7002f7003270037700000003b700000003770037700377003770037700000000000000000
91100000130001300013000007000e00000700130000000000000000000e00000000170001700000700007000e0000e0000070000700130001300000000000000e0000e0000e0000e0000e0000e0000000000000
011000202f7502b75000000247002b7502f7500000024700267502b7502b7502b7502b7200000000000000002f7502b75000000247002b7502f7500000024700267502b7502b7502b7502b720000000000000000
0110002023700217002370021700267000000023700180001f7001800000000000001a7000000000000000002370021700237002170026700000002b700000002f7002b700267002b7002f7002f7002f7002f700
c11000002b500000000000000000235000000000000000002f500000000000000000235000000000000000002b500000000000000000235000000000000000002f50000000000000000023500000000000000000
01100020217002370021700237001f700000002670000000237000000021700000001f700187001a700000001f700217001f700217001f7000000023700000001f700000001a7000000017700000001a7001f700
010400000c6100c6100c6100e6201062011630136401565017660156701367011650106400e6300c6200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
350800002200023000115000a5000a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200e7000c0001270014700157000c000147000c0000c0000c0000c0000c0000e7000c0001270014700157000c0001470000000000000000000000000000e700000001a7000000015700000001270000000
011000200e70011700127000000015700167001a70000000157001470012700000000e7000b70009700000000e70011700127000000015700167001a70000000157001470012700000000e7000b7000970000000
491000001360013600000000000013600136000000000000136001360000000000001360013600000000000013600136000000000000136001360000000000001360013600000000000013600136000000000000
011000200a30000000136000000013600000001360000000000000000000000000000000000000136000000013600000001360000000000000000000000000001360000000136000000013600000001360000000
000c00000c3000c3000c3000c3000c3000c3000c3003a0000c3000c3000c3000c3000c3000c3000c3003f0000a3000a3001330013300073000730007300113000a3000a3000a3003c0000f3000f3000f3003a000
00040000336251a605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163401d36022370223702236022350223402232013300133001830018300133001330016300163001d3001d300
000100000b6150a615096250962509625096250a6250b6350c6350e645106451265515655186501b6501d6401d6451d6351d6251c6251a62518615166151561513615116150f6150d6150c6150c6150b6150a615
001000102f60001000010003f600010003f6002f60001000010003f600010003f6002f6003f600010003f60000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000016270162701f2711f2701f2701f270182711827013271132701d2711d270162711627016270162701b2711b2701b2701b270000001b200000001b2000000000000000000000000000000000000000000
00080020245003050024500305001b500275001f5002b5001f5002b5001f5002b5001f5002b5001f5002b5001b500275001b500275001b500275001d500295001d500295001d500295001f5002b5001f5002b500
002000200c2000c2000c2000c2000c2000c2000c2000a2000f2000f2000f2000f2000f2000f2000f2001620013200132001320013200132001320013200132001320007200162001320013200132000f2000f200
00100000072000720007200072000f2000f2000c2000c2000c2000c2000c2000c20007200072000720007200072000720007200072000c2000c20011200112001120011200132001320016200162001620016200
000800201f5002b5001f5002b50018500245001b500275001b500275001850024500185002450018500245001b500275001b500275001d500295001d500295001f5002b5001f5002b5001f5002b5001b50027500
00100020112001120011200112001320013200182001820018200182001d2001d2000f2001820013200162000f2000f2000f2000f2001120011200162001620016200162001b2001b200222001f2001820013200
00100010010002f600010003f6002f6003f600010003f600010003f6002f600010002f6003f600010003f60000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000100100001000010003f6002f6003f6003f60001000010003f600010003f6002f6003f6002f6003f60000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000002900029000290002b000290002b000290002b00033000300002e0002e00030000300002b0002b0002e0002e0002e000300002e000300002e000300002b0002e0002b0002e0002b0002b0002900029000
000800202450024500245002450024500245002450024500245002450024500245002450000500245000050024500005002450000500245000050024500005002450000500245000050024500005002450000500
000800201f5001f5001f5001f5001f5001f5001f5001f5001f5001f5001f5001f5001f500000001f500000001f500000001f500000001f500000001f500000001f500000001f500000001f500000001f50000000
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
002000200c2000c2000c2000c2000c2000a2000a2000a2000f2000f2000f2000f2000f2000c2000c2000c2000c2000c2000c2000c2000c2000a2000a2000a2000f2000f2000f2000f2000f200112001120011200
002000001320013200132001320013200112001120011200162001620016200162001620013200132001320013200132001320013200132000f2000f2000f2000c20011200162000f20016200162000c2000c200
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
001000003c5003c5003c5003c5003c5003c50037500375003a5003a5003a5003a5003a5003a5003a5003a50035500355003550035500355003550035500355003550035500335003350033500335003350033500
00100000355003550035500355003550035500355003550037500375003350033500335003350033500335003a5003a5003a5003a5003a5003a50033500335003350033500335003350033500335003350033500
001000200c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000f0001100011000110001100011000110000a0000a0000a0000a0000a0000a0000a0000a0000a00000000
001000000500005000050000500005000050000700007000070000700007000000000f0000f0000f000000000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c000000000c0000c0000c0000c000
0010000003600246000060003600246001b60022600036000060003600116003360022600006001d6000a60037600186002e6001d600006003760037600186002e6001d60011600036000060003600246001d600
000100001b0501b050150001505014050091500c0500315005050050500000000000000000000000000000001415018640226001214014630000000e130116200000000000076300562003610000000000000000
000300000d0701007016070220700000000000000000000011070130701a07024070000000000000000000000a0600a0500904006030031200311000000000000000000000000000000000000000000000000000
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
__music__
03 020a4a4c
03 11124d4c
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344
00 7d7e4344

