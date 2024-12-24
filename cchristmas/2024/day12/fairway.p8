pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--~fairway~
--by meep
--a mod of celeste classic
--by maddy thorson and noel berry
function _init()cartdata"aoccfairway"exec[[poke◆0x5f2e,1
mouse_init
init_cam
init_snowflakes
init_bloops
title_init]]n_hats=8menuitem(1,"quick restart",game_init)menuitem(2,"clear score",function()dset(0,0)end)menuitem(3,"clear hats",function()for f=1,n_hats+1do dset(f,0)end hat=nil end)if(dget(n_hats+1)>0)hat=dget(n_hats+1)
end function _update60()exec[[update_mouse
update_fn]]end function _draw()exec[[cls
draw_fn
camera
draw_mouse]]end function mouse_init()exec[[poke◆0x5f2d,0x1]]end function update_mouse()mx,my,_mb,_mbp=stat"32",stat"33",stat"34",_mb end function draw_mouse()spr(0,mx-1,my-1)end function mouse(f,n)return(n and _mbp or _mb)&1<<f~=0end function mousep(f)return mouse(f)and not mouse(f,true)end function mouser(f)return not mouse(f)and mouse(f,true)end function vector(f,n,e)return{x=f,y=n,z=e}end function zvec()return vector(0,0,0)end function rectangle(f,n,e,d)return{x=f,y=n,w=e,h=d}end function new_tbl(n,e)local f={}for n=1,n do add(f,e)end return f end function cmap(e)local f,n,d,o=mid(0,rw-1,cam_x\8),mid(0,rh-1,cam_y\8),mid(0,rw-1,cam_x\8+16),mid(0,rh-1,cam_y\8+16)map(rx+f,ry+n,f*8,n*8,d-f+1,o-n+1,e)end function l2(e,d,o,t,f,n)f,n=f or 0,n or 0local f,n,e=o-e>>8,t-d>>8,n-f>>8return max(.00002,sqrt(f^2+n^2+e^2)<<8)end function drag_info()return atan2(hmx-mx,hmy-my),min(48,log(l2(mx,my,hmx,hmy))/.9)end function round(f)return flr(f+.5)end function log(n)local f=0for e=1,10do f-=1-n/2.71828^f end return f/1.5end function sign(f)return f==0and 0or sgn(f)end function l_appr(f,n,e)return f>n and max(f-e,n)or min(f+e,n)end function e_appr_delta(f,n,e)return e*(n-f)end function init_cam()exec[[gset◆_cx,0
gset◆_cy,0
gset◆_cdx,0
gset◆_cdy,0
gset◆_cg,0.15
gset◆cam_x,0
gset◆cam_y,0]]end function move_cam(f,n)if(not free_cam)local n=n or _cg _cdx,_cdy=e_appr_delta(_cx,f.hmid()-63,n),e_appr_delta(_cy,f.vmid()+f.z-63,n)_cx+=_cdx _cy+=_cdy
cam_x,cam_y=round(_cx),round(_cy)end function cam_draw()exec[[camera◆cam_x,cam_y]]end function tile_at(f,n)if(f>=0and f<rw and n>=0and n<rh)return mget(rx+f,ry+n)
return 0end function ripple(f,n)for n=1,n do add(ripples,{x=f.hmid(),y=f.vmid(),t=-4*(n-1),tmax=16-5*(n-1)})end end function splash(f,n,e)for n=1,n do add(splashes,{x=f.hmid(),y=f.vmid(),dx=rnd"2"-1,dy=-2-rnd"1",t=20+rnd"10"\1,c=e and(rnd()<.75and 9or 4)or(rnd()<.75and 1or rnd()<.75and 12or 7)})end end function psfx(f,n)if(sfx_timer==0)sfx(f)sfx_timer=n
end function tile_set(f,n,e)if(f>=0and f<rw and n>=0and n<rh)mset(rx+f,ry+n,e)
end function two_digit_str(f)return f<10and"0"..f or f end function update_time()if(ticking)seconds_f+=1minutes+=seconds_f\3600seconds_f%=3600
end function draw_time(f,n)rectfill(f,n,f+44,n+6,0)?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\60).."."..two_digit_str(round(seconds_f%60*100/60)),f+1,n+1,7
end function draw_strokes(f,n)local e,e=get_player(),rx==96and ry==48local e=tostr(e and strokes or rm_strokes,2)rectfill(f,n-1,f+11+4*#e,n+9,0)rectfill(f-1,n,f+12+4*#e,n+8,0)spr(11,f,n+1)?":"..e,f+8,n+2,7
end chtxt=split([[100,65,83,72,32,50,48,48,32,84,73,77,69,83,32,73,78,32,65,32,82,85,78,33
98,69,65,84,32,84,72,69,32,71,65,77,69,33
99,79,76,76,69,67,84,32,69,86,69,82,89,32,70,82,85,73,84,33
98,79,85,78,67,69,32,53,32,84,73,77,69,83,32,73,78,32,65,32,68,65,83,72,33
102,73,78,73,83,72,32,73,78,32,85,78,68,69,82,32,51,32,77,73,78,85,84,69,83,33
102,73,78,73,83,72,32,73,78,32,85,78,68,69,82,32,56,48,32,68,65,83,72,69,83,33
99,99,32,80,76,65,89,69,82,32,87,72,69,78,46,46,46
102,73,78,73,83,72,32,87,73,84,72,79,85,84,32,65,78,89,32,70,65,76,76,83,33]],"\n")function ch(f)if(dget(f)==0)dset(f,1)add(chs,{_spr=16+f,txt=stromboli(chtxt[f]),t=0})
end function filter(n,e)local f={}foreach(n,function(n)if(e(n))add(f,n)
end)return f end function sort(n)local f={}foreach(n,function(n)for e,d in inext,f do if(n.y<=d.y)return add(f,n,e)
end add(f,n)end)return f end function screen_fade(f,n)if(f)fillp(f<=0and.5or f<.33333and 2565.5or f<.66666and 23130.5or f<1and 64245.5or-.5)exec[[rectfill◆0,0,127,127,7
fillp]]
end function get_objs(f)return filter(objs,function(n)return n.obj==f end)end function get_obj(f)return get_objs(f)[1]end function get_player()return get_obj(player)end function pal_all(f)for n=1,15do pal(n,f)end end function draw_spr(f,n,e)spr(f._spr,f.x+(n or 0),f.y+(e or 0)+f.z/2,1,1,f.flp.x,f.flp.y)end function draw_obj(f)f:draw()end function drag_arrow()local f=get_player()if f and f.state=="drag"do local d,e=drag_info()local f,n=f.hmid(),f.vmid()exec[[camera
pal◆1,0]]spr(16,hmx-1,hmy-1)exec[[line◆hmx,hmy,mx,my,0
pal
cam_draw]]if e>=8do if(e==48)d+=rnd"0.005"-.0025
local o=split"3,11,10,9,8"[1+(e-8)\10]cpoly_r({vector(f+8,n-1),vector(f+e,n-1),vector(f+e,n+1),vector(f+8,n+1)},f,n,d,o)cpoly_r({vector(f+e,n-3),vector(f+e+5,n),vector(f+e,n+3)},f,n,d,o)end end end function stromboli(n)local f=""for n in all(split(n))do f..=bar(n)end return f end function outline(n)exec[[pal_all◆0]]pal=stat foreach(split"-1 0,1 0,0 -1,0 1",function(f)local e,d=usplit(f," ")local f,e=usplit(f," ")camera(cam_x+f,cam_y+e)n()end)pal=_pal exec[[pal
cam_draw]]end _pal=pal function obj_outlines()foreach(objs,function(f)if(f.outline)outline(function()f:draw()end)
end)exec[[pal
cam_draw]]end function cmap2()cmap"0x02"end function cmap1()cmap"0x01"end function cpoly_r(e,d,o,f,t)local function i(n,e)n,e=n-d,e-o return d+cos(f)*n-sin(f)*e,o+sin(f)*n+cos(f)*e end local n,d=32767.99999,32768for f in all(e)do f.x,f.y=i(f.x,f.y)n,d=min(n,f.y),max(d,f.y)end for f=ceil(n),d do local d,o=32767.99999,32768for t,n in pairs(e)do local e=e[1+t%#e]if(mid(f,n.y,e.y)==f)local f=round(n.x+(f-n.y)/(.00002+e.y-n.y)*(e.x-n.x))d,o=min(d,f),max(o,f)
end rectfill(d,f,o,f,t)end end function cprint(f,n,e,d)?f,64-2*#f+n,e,d
end function gset(n,f)_ENV[n]=_ENV[f]or f end function usplit(f,n,e)if(f)local f=split(f,n)for d,n in pairs(f)do f[d]=not e and _ENV[n]or n end return unpack(f)
end function exec(f)foreach(split(f,"\n"),function(f)local f,n=usplit(f,"◆",true)_ENV[f](usplit(n,",",f=="gset"))end)end function load_gfx(e,f)local n=0for e=1,#f,2do for d=1,("0x"..f[e])+1do sset(n%128,n\128,"0x"..f[e+1])n+=1end end save_ss(e)reload(0,0,8192)end function save_ss(f)memcpy(32768+8192*f,0,8192)end function ssload(f)memcpy(0,32768+8192*f,8192)end function init_snowflakes()snowflakes={}for f=0,64do add(snowflakes,{x=rnd"128",y=rnd"128",s=flr(rnd"1.25"),spd=.375+rnd"0.375",off=rnd"1",c=rnd"1"<.8and 7or 6})end end function draw_snowflakes(f)local n,e,d,o,f=sin,rectfill,_cdx,_cdy,f or 1foreach(snowflakes,function(_ENV)x=(x+spd/f-d)%128y=(y+.5+.25*n(off)-o)%128off+=.00625e(x,y,x+s,y+s,c)end)end function init_bloops()bloops={}for f=0,32do add(bloops,{x=rnd"128",y=rnd"128",s=rnd"8",spd=.125+rnd"0.125"})end end function draw_bloops()local f,n,e=rectfill,_cdx,_cdy foreach(bloops,function(_ENV)x=(x+spd/4-n)%128y=(y-spd-e)%128f(x,y,x+s,y,1)end)end function game_init()ccwhen=generate()exec[[gset◆mu,0.25
gset◆px_f,0.5
gset◆grav,1
gset◆seconds_f,0
gset◆minutes,0
gset◆strokes,0
gset◆fruits,0
gset◆falls,0
gset◆sfx_timer,0
gset◆update_fn,game_update
gset◆draw_fn,game_draw
load_room◆1]]chs={}end function game_update()update_time()sfx_timer=max(sfx_timer-1)local f=get_player()if(f and f.state=="idle"and(mousep"1"or btnp(🅾️,1)))free_cam=not free_cam if(free_cam)_cdx,_cdy=0,0
if(free_cam)local f,n=tonum(btn(➡️)or btn(➡️,1))-tonum(btn(⬅️)or btn(⬅️,1)),tonum(btn(⬇️)or btn(⬇️,1))-tonum(btn(⬆️)or btn(⬆️,1))_cx=mid(-64,8*rw-64,_cx+2*f)_cy=mid(-64,8*(room==16and rh-16or rh)-64,_cy+2*n)move_cam()return
foreach(objs,function(f)f.move(f.spd.x,f.spd.y,f.spd.z)f:update()end)if(room_goto)exec[[load_room◆room_goto
gset◆room_goto]]
if results_t do if mousep"0"and(rx~=96or ry~=48)do if(results_t==181)room_goto=min(#rm_data,room+1)
results_t=min(181,results_t\60*60+59)end results_t=min(181,results_t+1)if(results_t%60==0)sfx"6"
end end function game_draw()exec[[pal
camera
cls◆2
draw_bloops
cam_draw]]foreach(ripples,function(f)local n=max(f.t)f.t+=.5if(f.t==f.tmax)del(ripples,f)else oval(f.x-n,f.y-n/2,f.x+n+1,f.y+1+n/2,1)
end)exec[[outline◆cmap2
cmap◆0x02]]foreach(objs,function(f)if(f.shadow)if(f.obj==tutorial)rectfill(f.x+5,f.y+4,f.x+18,f.y+5,1)else spr(6,f.x,f.y+1)
end)exec[[outline◆cmap1]]foreach(filter(objs,function(f)return f.obj==whencc end),draw_obj)exec[[obj_outlines
cmap◆0x01]]foreach(sort(filter(objs,function(f)return f.obj~=whencc end)),draw_obj)drag_arrow()foreach(splashes,function(f)f.x+=f.dx f.y+=f.dy f.dy+=.2f.t-=1if(f.t<=0)del(splashes,f)else rectfill(f.x,f.y,f.x+1,f.y+1,f.c)
end)foreach(smoke,function(f)f._spr+=.1f.x+=f.spd.x f.y+=f.spd.y if(f._spr>=16)del(smoke,f)else draw_spr(f)
end)exec[[camera
draw_snowflakes
rect◆0,0,127,127,1]]local f,n=rx==96and ry==48,get_player()if(not f and(not n or n.state~="goal"))exec[[draw_strokes◆4,4]]
if results_t do stroke_str=":"..tostr(f and strokes or rm_strokes,2)stroke_x=60.5-2*#stroke_str fruit_str=":"..(f and fruits or rm_fruit)fruit_x1=60.5-2*#fruit_str fruit_x2=fruit_x1+8falls_str=":"..tostr(falls,2)falls_x1=60.5-2*#falls_str falls_x2=falls_x1+8exec[[camera◆0,-78
rectfill◆32,-1,95,43,0
rectfill◆31,0,96,42,0
rect◆32,0,95,42,5]]if(f)draw_time(42,4)
cprint(f and""or"hole!",0,4,7)if(results_t>=60)exec[[draw_strokes◆stroke_x,12]]
if(results_t>=120)exec[[spr◆10,fruit_x1,22
print◆fruit_str,fruit_x2,24,7]]
if(results_t>=180)if(not f)exec[[cprint◆[click],0,34,7]]else exec[[spr◆26,falls_x1,32
print◆falls_str,falls_x2,34,7]]
cam_draw()end if(free_cam and t()%.75<.375)exec[[rectfill◆0,0,23,2,3
rectfill◆0,0,2,23
rectfill◆104,0,127,2
rectfill◆125,0,127,23
rectfill◆0,104,2,127
rectfill◆0,125,23,127
rectfill◆104,125,127,127
rectfill◆125,104,127,127]]
if#chs>0do cam_draw()local f=chs[1]if(f.t==0)sfx"13"
f.t+=1if(f.t==330)del(chs,f)
local n=f.t<300and round(-24*.85^f.t)or round(-24+24*.85^(f.t-300))rectfill(cam_x+4,cam_y+3+n,cam_x+123,cam_y+19+n,7)rectfill(cam_x+3,cam_y+4+n,cam_x+124,cam_y+18+n,7)?"★ NEW HAT",cam_x+4,cam_y+4+n,14
local function e()spr(f._spr,cam_x+7,cam_y+9+n)end outline(e)e()local f=f.txt?f,cam_x+64-2*#f+7,cam_y+12+n,2
end pal(2,129,1)end rm_data=split([[0,0,16,16
16,0,16,16
32,0,16,16
48,0,16,16
96,16,16,16
64,0,32,16
96,0,32,16
112,16,16,32
0,32,16,16
112,48,16,16
0,48,16,16
0,16,16,16
16,16,32,16
48,16,16,16
64,16,32,16
16,32,32,32
96,48,16,16]],"\n")function room_globals(f)room,rx,ry,rw,rh=f,usplit(rm_data[f])end function load_room(f)room_globals(f)objs,smoke,splashes,ripples,rm_strokes={},{},{},{},0for f in all(rm_objs[f])do local f,n,e=unpack(f)init_object(tiles[f],8*n,8*e,f)end local f=rx==96and ry==48ticking,rm_fruit,free_cam,results_t=not f,0,false,false pmusic(f and 63or 0,0,3)end function pmusic(f,n,e)if(curr_music~=f)curr_music=f music(f,n,e)
end player_spawn={init=function(f)f.t,f.facing,f.layer=0,1,10f.rec=rectangle(f.x+3,0,0,127)f.y-=80move_cam(f,1)f.y+=80f.outline=false sfx"4"end,update=function(f)f.t+=1if f.t<32do move_cam(f,.2)if(f.t>15)f.rec.w+=e_appr_delta(f.rec.w,8,.5)
if(f.t==25)for n=-6,2,4do f.init_smoke(n,3)end
elseif f.t==32do local f=init_object(player,f.x,f.y,1)elseif f.t==50do f:delete()end end,draw=function(f)fillp(f.t<25and.5or f.t<27and 2565.5or f.t<29and 23130.5or f.t<30and 64245.5or-.5)local f,n=f.rec,f.rec.w+round(rnd())rectfill(f.x-n,cam_y,f.x+n+1,cam_y+127,7)fillp()end}player={init=function(f)f.solid,f.shadow,f.djump,f.dash_time,f.hitbox,f.last,f.boing,f.state,f.m,f.respawn=true,true,1,0,rectangle(usplit"1,3,6,5"),{x=f.x,y=f.y,rx=f.rem.x,ry=f.rem.y},0,"idle",2.5,0create_hair(f)end,update=function(f)if f.respawn>0do f.respawn-=1if(f.respawn==0)f.shadow,f.x,f.y,f.rem.x,f.rem.y,f.djump,f.spd=true,f.last.x,f.last.y,f.last.rx,f.last.ry,1,zvec()create_hair(f)update_hair(f)f.init_smoke()sfx"9"
return end local n=tile_at(f.hmid()\8,f.vmid()\8)local d,o,n=fget(n,2),fget(n,3),l2(0,0,f.spd.x,f.spd.y)local n=d or n>1.75local e=n and f.z==0and f.spd.z>=0if(f.dash_time>0)f.dash_time-=1f.init_smoke()
if(e and d and f.dash_time==0and f.djump==0)f.djump=1sfx"5"
if f.state=="idle"do f.boing=0if(mousep"0")hmx,hmy,f.state=mx,my,"drag"
elseif f.state=="drag"do local e,n=drag_info()if not mouse"0"do if n<8do f.state="idle"else local n=px_f*n/f.m if(o)n/=1.5splash(f,10,true)
f.djump-=1rm_strokes+=.00002if(strokes+rm_strokes>=.00306)ch(1)
f.spd,f.state,f.dash_time=vector(n*cos(e),n*sin(e),-max(n-4)/3),"hit",6sfx"0"end end elseif f.state=="hit"do f.z=f.z+f.spd.z if n do f.z=min(0,f.z)elseif f.z>0do ripple(f,3)splash(f,20)f.spd=zvec()f.respawn=45f.shadow=false if(rx~=96or ry~=48)falls+=.00002
_cdx,_cdy=0,0sfx"8"return end local t,d=f.spd.z,f.z==0and n and not d if(d)ripple(f,1)splash(f,5)psfx(2,8)
f.spd.z=e and 0or f.z==0and n and-l_appr(f.spd.z,0,.75)or f.spd.z+grav*.1local n=l2(0,0,f.spd.x,f.spd.y,0,f.spd.z)if(t>0and f.spd.z<=0or o and n>0)f.init_smoke()
local d=d and 1.5or o and 3or 1local e=(.1*n)^2+(e and d*mu*grav/f.m or 0)local e=max(n-e)f.spd.x*=e/n f.spd.y*=e/n if(e==0)f.state="idle"f.last={x=f.x,y=f.y,rx=f.rem.x,ry=f.rem.y}
end if(f.spd.x~=0)f.flp.x=f.spd.x<0
f._spr=e and 1or 3draw_hair(f)update_hair(f)move_cam(f)end,draw=function(f)if(f.respawn>0)return
local n=flr(f._spr)local n=n==3and-1or n==6and 1or 0pal(8,f.djump==1and 8or 12)draw_hair(f)draw_spr(f)pal()if hat do if(hat==18or hat==24)n+=2
spr(hat,f.x,f.y+f.z/2-5+n,1,1,f.flp.x,f.flp.y)end end,on_move=function(n)for f in all(objs)do if f.obj==spring do local f=n.overlaps(f,0,0)if(f and f.delta<=1)return spring.boop(f,n)
elseif f.obj==bumper or f.obj==diglett do if f.obj~=diglett or f.h>.25do if f.shake<5do local e,d if(f.obj==bumper)e,d=f.x+8,f.y+8else e,d=f.x+4,f.y+6
local o=l2(n.hmid(),n.vmid(),e,d)if f.obj==bumper and o<12or o<6do local e=atan2(e-n.hmid(),d-n.vmid())local e,d,o,t=cos(2*e),sin(2*e),n.spd.x,n.spd.y n.spd=vector(-e*o-d*t,e*t-d*o,n.spd.z)sfx"12"n.boing+=1if(n.boing>=5)ch(4)
f.shake=20return true end end end end end end}function create_hair(f)f.hair={}for n=1,5do add(f.hair,vector(f.x,f.y))end end function update_hair(f)local n=vector(f.x+4-(f.flp.x and-2or 3),f.y+f.z/2+(btn(⬇️)and 4or 2.9))for e,f in pairs(f.hair)do f.x+=(n.x-f.x)/1.25f.y+=(n.y+.5-f.y)/1.25n=f end end function draw_hair(f)for n,f in pairs(f.hair)do circfill(round(f.x),round(f.y),mid(4-n,1,2),8)end end flag={init=function(f)f.hitbox,f.t=rectangle(usplit"1,2,6,7"),0end,update=function(f)local n=f.player_here()if(not f.touched and n and n.state=="idle")sfx"3"strokes+=rm_strokes f.touched,n.state,ticking=true,"goal"
if(f.touched and not results_t)results_t=0
end,draw=function(f)spr(f._spr,f.x,f.y)if(f.touched)for n=0,4do local f,e=f.x+3,f.y+1-round(sin(t()+n/5))rectfill(f+n,e,f+n,e+2,11)end else for n=0,1do local f,e=f.x+3,f.y+1+2*n rectfill(f+n,e,f+n,e+2,11)end
end}diglett={init=function(f)f._t,f.h,f._spr,f.shake=f._spr==37and 60or 0,0,36,0end,update=function(f)f.h=sin(f._t/120)f._t+=1f.shake=max(f.shake-1)end,draw=function(f)spr(f._spr,f.x,f.y)if(f.h>0)local n=round(7*f.h)sspr(40,16,8,n,f.x,f.y+7-n)
end}spring={init=function(f)f.delta,f.dir=0,f._spr==48and(f.is_solid(0,1)and-1or 1)or(f.is_solid(-1,0)and 1or-1)end,update=function(f)f.delta*=.875end,boop=function(n,f)local e=sign(n._spr==48and f.spd.y or f.spd.x)==sign(n.dir)if(e and l2(0,0,f.spd.x,f.spd.y)<1.5)return false
if n.delta<=1do n.delta=8if(n._spr==48)f.move(0,n.y-f.y+n.dir*4)f.spd.x*=.1f.spd.y=-.5*tonum(sign(f.spd.y)==-sign(n.dir))*f.spd.y+4*n.dir else f.move(n.x-f.x+n.dir*4,0)f.spd.x=-.5*tonum(sign(f.spd.x)==-sign(n.dir))*f.spd.x+4*n.dir f.spd.y*=.1
f.spd.z,f.dash_time,f.djump,f.state=-1,0,1,"hit"psfx(7,8)n.init_smoke()end return true end,draw=function(f)local n=f.delta>1and-16or 0if(f._spr==48)spr(48+n,f.x,f.y,1,1,false,f.dir==1)else spr(49+n,f.x,f.y,1,1,f.dir==1)
end}bumper={init=function(f)f.shake,f.dx,f.dy=0,0,0end,update=function(f)f.shake=max(f.shake-1)f.dx,f.dy=f.shake>0and rnd"4"-2or 0,f.shake>0and rnd"4"-2or round(sin(t()/2))end,draw=function(f)if(f.shake>0)pal_all"7"
spr(34,f.x+f.dx,f.y+f.dy,2,2)pal()end}fruit={init=function(f)f.shadow=true f.sx,f.sy=f.x,f.y f.y_,f.follow,f.tx,f.ty=f.y,false,f.x,f.y end,update=function(f)if not f.follow and f.player_here()do f.follow=true sfx"10"elseif f.follow do local n=get_player()if n and n.respawn==0do if(n.state=="goal")sfx"11"init_object(lifeup,f.x,f.y,"1000")f:delete()rm_fruit+=1fruits+=1
f.tx+=e_appr_delta(f.tx,n.x,.4)f.ty+=e_appr_delta(f.ty,n.y,.4)local e,d=f.x-f.tx,f.y_-f.ty local n=max(1,sqrt(e^2+d^2))local o=n>12and.2or.1f.x+=e_appr_delta(f.x,f.tx+12*e/n,o)f.y_+=e_appr_delta(f.y_,f.ty+12*d/n,o)end end f.y=round(f.y_+1.5*sin(t()*.75))end}lifeup={init=function(f)f.spd.y,f.duration,f.outline=-.125,60end,update=function(f)f.duration-=1if(f.duration<=0)f.delete()
end,draw=function(f)?f._spr,f.x+4-2*#f._spr,f.y-4,7+t()*15%4
end}ysadelie={}fire={init=function(f)f.x-=4f.outline=false f.particles={}end,update=function(f)if not f.touched and f.player_here()do f.touched=true results_t=0ch(2)if(fruits==#rm_data-1)ch(3)
if(minutes<3)ch(5)
if(strokes<.00123)ch(6)
if(falls==0)ch(8)
local f=dget(0)if(f==0or strokes<f)dset(0,strokes)
end if(f.touched)if(rnd()<.75)if rnd()<.25do add(f.particles,{x=f.x+1+rnd"5",y=f.y+4,r=2,c=8,t=20})elseif rnd()<.5do add(f.particles,{x=f.x+2+rnd"4",y=f.y+4,r=1,c=9,t=30})elseif rnd()<.5do add(f.particles,{x=f.x+2+rnd"4",y=f.y+4,r=0,c=10,t=40})end
end,draw=function(n)outline(function()draw_spr(n)end)draw_spr(n)foreach(n.particles,function(f)f.t-=1if(f.t==0)del(n.particles,f)
f.y-=.2circfill(f.x,f.y,f.r,f.c)end)end}tree={draw=function(f)spr(38,f.x,f.y-8,2,2)if(ccwhen[3])spr(52,f.x+5,f.y-10)
end}tutorial={draw=function(f)f.shadow=true spr(f._spr,f.x,f.y-8,3,1)spr(59,f.x,f.y)spr(59,f.x+16,f.y)end}whencc={init=function(f)f.outline=false f.hitbox=rectangle(usplit"0,0,40,40")f.buffer={}end,update=function(f)if not f.solved do local n=get_player()if n do if n.respawn~=0do f.buffer={}elseif f.last~="idle"and n.state=="idle"do local n,e=(n.hmid()-f.x)\8,(n.vmid()-f.y)\8if n>=0and n<5and e>=0and e<5do local d=n..","..e if not ccwhen[1][1+e*5+n]do local n for f in all(f.buffer)do if(f==d)n=true
end if(not n)add(f.buffer,d)if(#f.buffer>5)local n,e=usplit(f.buffer[1])f.init_smoke(8*n,8*e)deli(f.buffer,1)
end end end f.last=n.state end local n=#f.buffer==5for f in all(f.buffer)do local f,e=usplit(f)if(ccwhen[2][1+e]~=1+f)n=false
end f.solved=n else if(not f.t)f.t=180ccwhen[3]=true ch(7)f.particles={}for d,n in pairs(f.buffer)do local n,e=usplit(n)add(f.particles,{x=f.x+8*n,y=f.y+8*e,idx=d,spd=0})f.init_smoke(8*n,8*e)end else f.t=max(f.t-1)
end end,draw=function(f)for n=0,24do if(ccwhen[1][1+n])local n,e=n\5,n%5spr(53,f.x+8*e,f.y+8*n)spr(28,f.x+8*e,f.y+8*n-1)
end for n in all(f.buffer)do local n,e=usplit(n)spr(27,f.x+8*n,f.y+8*e)end if f.t do foreach(f.particles,function(n)if f.t>60do n.x+=e_appr_delta(n.x+3,f.hmid()+16*cos(t()/2+n.idx/5),.25)n.y+=e_appr_delta(n.y+3,f.vmid()+16*sin(t()/2+n.idx/5),.25)elseif f.t>0do if(f.t==60)sfx"11"
n.spd+=.2n.y-=n.spd else del(f.particles,n)end spr(52,n.x+1,n.y+2)end)end end}tiles={}foreach(split([[5,player_spawn
38,tree
10,fruit
12,flag
7,fire
8,ysadelie
34,bumper
35,bumper
40,tutorial
56,tutorial
48,spring
49,spring
36,diglett
37,diglett
29,whencc]],"\n"),function(f)local f,n=usplit(f)tiles[f]=n end)function init_object(f,n,e,d)local f={obj=f,_spr=d,hitbox=rectangle(usplit"0,0,8,8"),x=n,y=e,z=0,rem=zvec(),spd=zvec(),flp=vector(),layer=0,collideable=true,solid=false,outline=true,init=f.init or t,update=f.update or t,draw=f.draw or draw_spr,on_move=f.on_move}function f.left()return f.x+f.hitbox.x end function f.right()return f.left()+f.hitbox.w-1end function f.top()return f.y+f.hitbox.y end function f.bottom()return f.top()+f.hitbox.h-1end function f.hmid()return round(f.left()+f.right()>>1)end function f.vmid()return round(f.top()+f.bottom()>>1)end function f.is_flag(n,e,d)local f,o,t,i=f.left(),f.right(),f.top(),f.bottom()for f=(f+n)\8,(o+n)\8do for n=(t+e)\8,(i+e)\8do local f=tile_at(f,n)if(fget(f,d))return true
end end end function f.overlaps(n,e,d)if(n.right()>=f.left()+e and n.bottom()>=f.top()+d and n.left()<=f.right()+e and n.top()<=f.bottom()+d)return n
end function f.check_all(e,d,o,n)return filter(n or objs,function(n)return n.obj==e and n~=f and n.collideable and f.overlaps(n,d or 0,o or 0)end)end function f.check(...)return f.check_all(...)[1]end function f.player_here()return f.check(player,0,0)end function f.is_solid(n,e)return f.is_flag(n,e,0)end function f.not_free(n,e)return f.is_solid(n,e)end function f.move(e,d)for n in all{"x","y"}do f.rem[n]+=n=="x"and e or d local e=flr(f.rem[n]+.5)f.rem[n]-=e if f.solid do local d=sign(e)local o,t=n=="x"and d or 0,n=="y"and d or 0for e=1,abs(e)do if(f.on_move and f:on_move(o,t))return
if f.not_free(o,t)do f.rem[n]=0f.spd[n]=-l_appr(f.spd[n],0,2)if(f.obj==player and f.spd[n]~=0)sfx"1"
break else f[n]+=d end end else f[n]+=e end end end function f.delete()del(objs,f)end function f.init_smoke(n,e,d)add(smoke,{x=f.x+(n or 0)-1+rnd"2",y=f.y+(e or 0)-1+rnd"2",z=f.z+(d or 0)-1+rnd"2",spd=vector(.3+rnd"0.2",-.1),flp=vector(rnd"1"<.5,rnd"1"<.5),_spr=13})end add(objs,f)f:init()return f end function title_init()exec[[gset◆update_fn,title_update
gset◆draw_fn,title_draw]]countdown=nil music(63,1000)end function title_update()if countdown do countdown-=1if(countdown==0)game_init()
return end hats={}for f=1,n_hats do if(dget(f)>0)add(hats,16+f)
end if not countdown and mousep"0"do for n,f in pairs(hats)do local n=2+10*(n-1)if mx>=n and mx<n+8and my>=101and my<109do if(dget(n_hats+1)==f)hat=nil else hat=f
dset(n_hats+1,hat)return end end countdown=120music(-1,1000)sfx"14"end end function title_draw()exec[[cls◆0
rectfill◆0,61,127,108,1
circfill◆127,-8,24,7]]for f=62,86,2do local n=(f-61)/20line(96+20*n^2+sin(t()/2+n),f,127,f,12)end exec[[palt◆0b0000010000000000
ssload◆1
spr◆0,0,0,128,128
pal
ssload◆0
print◆BY mEEP,62,54,9
print◆mADDY tHORSON,2,115,6
print◆nOEL bERRY,2,121,6]]for n,e in pairs(hats)do local function f()spr(e,2+10*(n-1),101)end outline(f)f()end for f,n in pairs(hats)do local f=2+10*(f-1)if hat==n do?"^",f+3,111,5
pset(f+4,112,5)end if(not countdown and mx>=f and mx<f+8and my>=101and my<109)rect(f-1,100,f+8,109,6)
end local function f()local f=tostr(dget(0),2)spr(11,114-4*#f,119)spr(9,119-4*#f,118)?f,127-4*#f,120,7
end if(dget"0">0)outline(f)f()
?"[click]",50,68,13
exec[[draw_snowflakes◆3]]if(countdown)screen_fade(max(countdown-60)/60)
end function perlin_init(e,d)d=d or rnd()e/=.70711local function o(f)return f^3*(f*(f*6-15)+10)end local function t(n,e,f)return(1-f)*n+f*e end local function i(f,n)f*=57005.74584n*=-274.2706n^^=f<<16|n>>>16f^^=n<<16|f>>>16return f*(d~-8528.0203)%1end local function f(f,n)f,n=(f-n)/e,(n+f)/e local e,d=f\1,n\1local function l(e,d)local o=i(e,d)return cos(o)*(f-e)+sin(o)*(n-d)end local function i(n)return t(l(e,n),l(e+1,n),o(f-e))end return t(i(d),i(d+1),o(n-d))end return f,i end _tdict={}foreach(split([[0b00000000,115
0b00000001,99
0b00000010,67
0b00000011,83
0b00000100,114
0b00000101,102
0b00000110,70
0b00000111,86
0b00001000,112
0b00001001,100
0b00001010,68
0b00001011,84
0b00001100,113
0b00001101,101
0b00001110,69
0b00001111,85
0b00010101,98
0b00010111,75
0b00011101,122
0b00011111,105
0b00101001,96
0b00101011,74
0b00101101,123
0b00101111,103
0b00111101,97
0b00111111,104
0b01000110,66
0b01000111,91
0b01001110,106
0b01001111,73
0b01010111,82
0b01011111,89
0b01101111,120
0b01111111,116
0b10001010,64
0b10001011,90
0b10001110,107
0b10001111,71
0b10011111,121
0b10101011,80
0b10101111,87
0b10111111,117
0b11001110,65
0b11001111,72
0b11011111,118
0b11101111,119
0b11111111,81]],"\n"),function(f)local f,n=usplit(f)_tdict[f]=n end)perlin,rnd2d=perlin_init(16,69)function compute_tile(n,e,d)local f=0foreach(split([[1|0,-1
2|0,1
4|-1,0
8|1,0
16|0,-1+-1,0+-1,-1
32|0,-1+1,0+1,-1
64|0,1+-1,0+-1,1
128|0,1+1,0+1,1]],"\n"),function(o)local o,t=usplit(o,"|")for f in all(split(t,"+"))do local f,o=usplit(f)if(not fget(tile_at(n+f,e+o,81),d))return
end f+=o end)return _tdict[f]end function autotile(f,n)local e,d,e=f,n,tile_at(f,n)if e>=64and fget(e,2)do local d=e==79e=compute_tile(f,n,2)if(not d and e==81and rnd2d(f,n)<.1)local d=split"88,124,125,126,127"e=d[rnd2d(n,f)*#d\1+1]
tile_set(f,n,e)elseif e==0do local e=tile_at(f,n-1)if(e>=43and fget(e,2))tile_set(f,n,76)
end end function tblmax(n)local f=32768foreach(n,function(n)if(n>f)f=n
end)return f end function sample(f)local o,n,e=rnd(),0,0for f in all(f)do n+=f end for d=1,#f do e+=f[d]/n if(o<e)return d
end return#f end function generate()local d,f=new_tbl(25,false),split([[1,3,5,2,4
1,4,2,5,3
2,4,1,3,5
2,4,1,5,3
2,5,3,1,4
3,1,4,2,5
3,1,5,2,4
3,5,1,4,2
3,5,2,4,1
4,1,3,5,2
4,2,5,1,3
4,2,5,3,1
5,2,4,1,3
5,3,1,4,2]],"\n")for n=1,#f do f[n]=split(f[n])end local n=f[1+flr(rnd(#f))]del(f,n)local e=new_tbl(25,0)foreach(f,function(d)for f=1,5do if(d[f]~=n[f])e[(f-1)*5+d[f]]+=.125
end end)while#f>0do local o,t={},tblmax(e)for n,f in pairs(e)do o[n]=f*f/t end d[sample(o)]=true for t=#f,1,-1do local o=f[t]for i=1,5do if d[(i-1)*5+o[i]]do for f=1,5do if(o[f]~=n[f])e[(f-1)*5+o[f]]-=.125
end deli(f,t)end end end end return{d,n}end function preprocess()rm_objs={}for n=1,#rm_data do rm_objs[n]={}room_globals(n)for e=0,rh-1do for d=0,rw-1do local f=tile_at(d,e)if(tiles[f])add(rm_objs[n],{f,d,e})if(f~=5and f~=29)tile_set(d,e,f==35and 0or 79)
end end for f=0,rh-1do for n=0,rw-1do autotile(n,f)end end end _game_init=game_init function game_init()_game_init()ccwhen=generate()end end preprocess()exec[[gset◆bar,chr
save_ss◆0
load_gfx◆1,f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f55510f5f5f5f5f5f5f5c5001200c530f5f5f5f5f5f59500320095103320f5f5f5f5f5f565003203106500017300f5f5f5f5f5f555003213016003018300f5f5f5f5f5f5350032230103510301830100f5f5f5f5f5f525003223010351030183010300f5f5f5f5f5f515003223010351030183011310f5f5f5f5f5f500322301035103018301131110f5f5f5f5f5c500422301035103018301133130f5f5f5f5f58500421301036103018301137100f5f5f5f5f57500322301036103018301135110f5f5f5f5f58500322301036103018301133110f5f5f5f5f5a500322301036103018301131110f5f5f5f5f5c50032230103610301830130f5f5f5f5f5d50042230103610301830100f5f5f5f5f5f505004223010361030183010300f5f5f5f5f5f5003233010361030183011300f5f5f5f5f5e5003233010361030183011300f5f5f5f5f5d500423301036103018301130100f5f5f5f5f5c500422301037103018301131100f5f5f5f5f5b5003233010371030113104301131100f5f5f5f5f5a50042330103710301030015102301132100f5f5f5f5f5950042200301037103010045001301133100f5f5f5f5f5850032002520711065000301133100f5f5f5f5f585003200557085000301134100f5f5f5f5f575003200f5750001135100f5f5f5f5f55500043200f58500136100f5f5f5f5f54500043200f59580f5f5f5f5f55500042200f50510f5f5f5f5f5f565000402040200557015001700f56560f5f5f5f5750024020045007700050017000510f5250067001520f5f5f5f5150004020402003500970005100500175015105520871027003510f5f5f5a50024020035002730270005100500771017003500170027203700270025001700f5f5f5950024020035001700350017101710870017003500173025002710270015001700f5f5f5950024020045104500171017102730170017002500270065001710270015001700f5f5f59500240200556017101700050017002520170025002760050017000500170015001700f5f5f5950024020045005700171017000500170045001700250017105710170005001700150017001520f5f5f54500340035009710170005001700450017200500170077001700050017001500170005002700f5f5f53500340035002710471017000500170045001700171017002710570005001700150017103700f5f5f535003400350017001500371017000500170045004710170017001500470005001700050027003700f5f5f54500240200350017204710172017004500870027105700050027106700f5f5f5550034003500a7003700170055007700b710a700f5f5f565002402003500670027003700170055002700270005005710270005007710f5f5f575002402004560052005300510752005202550152025302700f5f5f5850002240200f5f5f595003700f5f5f5850002240200f5f5f585004700f5f5f58500022400f5f5f595004700f5f5a520a5003400f5f5f5850027001700f5f5950022009500022400f5f5f575006700f5f585001210a5003400f5f5f5750027002700f5f58500024085003400f5f5f5750017002700f5f5851052204500340200f5f5f575005700f5f57500a2003500340200f5f5f575004700f5f5750008821802002500022400f5f5f585003700f5f57500020802184208120802001500022400f5f5f59530f5f575000238620822001500022400f5f5f5f5f5f5550002080218b20005000204020400f5f5f5f5f5f55500f20210122400f5f5f5f5f5f54500f222001204020400f5f5f5f5f5f54500f2220012040200f5f5f5f5f5f555000200f25200f5f5f5f5f5f56510f212082200f5f5f5f5f5f57500f20802380200f5f5f5f5f5f56500f222380200f5f5f5f5f5f56500f232280200f5f5f5f5f5f5550003f242080240f5f5f5f5f5f5150013f208424700f5f5f5f5f5b5400613f2426700f5f5f5f5f59500470613f2525700f5f5f5f5f59500471623f2227700f5f5f5f5f58500472d23e20d029770f5f5f5f5f50500477d620d42f73700f5f5f5f5e50047bd422df75700f5f5f5f5b52057fd0df78700f5f5f5f5b577fd0df79700f5f5f5f5b577ed070df7a700f5f5f5f5a567ed070df7b700f5f5f5f5a577cd070df7d700f5f5f5f595670d07ad070df7f710f5f5f5f575770d070d070d074d070df7f72730f5f5f5f535870d070d070d070d070d070df7f77700f5f5f5f525f7f7f7c700f5f5f5f515f7f7f7c700f5f5f5f515f7f7f7d700f5f5f5f505f7f7f7d700f5f5f5f505f7f7f7e700d500f5f5f505f7f7f7e700c5000300f5f5f5f7f7f7e700c5000300f5f5f5f7f7f7f70095200320f5f5d5f7f7f7f707106500130003001300f5f5c5f7f7f7f72700550013002300f5f5d5f7f7f7f737704300f5f5d5f7f7f7f7b7330730f5f5a5f7f7f7f7f74730f5f565f7f7f7f7f78700f5f555f7f7f7f7f78700f5f555f7f7f7f7f797f010f535f7f7f7f7f7f7b710f515f7f7f7f7f7f7d700f505f7f7f7f7f7f7e710e5f7f7f7f7f7f7f707e0f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
ssload◆0]]
__gfx__
0100000000000000000000000888888000000000cccccccc000000000000000000000000a070a0000300b0b00100000000200000000000000000000070000000
1710000008888880088888808888888808888880cc7777cc000000000000000000000000aa77a000003b33000100000000200000007700000770070007000007
17710000888888888888888888888ff888888888c777777c000000000000000010111101aa77a0000288882000d0000000400000007770700777000000000000
1777100088888ff888888ff888f1ff1888888ff8c777777c00000000000000001171711100000000089888800060000000400000077777700770000000000000
1777710088f1ff1888f1ff1808fffff088f1ff18c777777c0000000004404400119911110000000008888980000d000000400000077777700000700000000000
1771100008fffff008fffff0001d5d0008fffff0c777777c0011110000544000017771100000000008898880000d666000400000077777700000077000000000
01171000001d5d00001d5d0007000070071d5d00cc7777cc0111111000445000097791100000000002888820000066d000400000070777000007077007000070
0000000000700700007000700000000000000700cccccccc00111100044044000966911000000000002882000000000007776000000000007000000000000000
10100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000067777776677777774644446454545454
01000000000000000000000000000000000000000000000000000000000000000000000000000000c00c00c000d00d0077777777777777775555555556565656
1010000000000000000000000000000000000000000000000000000000000000000000000000000008888800000dd0007776e777777776cc4644446454545454
0000000007700000001111000000000000000000000000000000000000000000000000000000000088c88880000dd00077eeee77777ccccc5555555554545454
0000000006600000011000000300b0b00000000000a070a00007007000007000000000000000000088f1f18000d00d0077eeee7777cccccc4644446454545454
000000000077770011000000003b33000017170000aa77a0007e07e000aa77a00000000000000000c8cfffc000000000777ee77777cccccc5555555554545454
000000000777776011000001028888800111999000aa77a000777760000a77000111111000000000ccccccc0000000007777777777cccccc4644446456565656
00000000070000001100000100000000010000000000000007000000055a5a50000110100000000011111110000000006777777677cccccc5555555554545454
00000000000000000000011dd110000000000000000000000000000000000000055444444551445467774440ffffffff7ffffffffffffff7c77777777777777c
0000000000000006000111dccd11100000000000004444000000000300000000454445444411144447644544ffffffff7ffffffffffffff77ffffffffffffff7
0000000000000007001dd1dccd1dd10000000000044444400000000b000000004884454441d1415414414544ffffffff7ffffffffffffff77ffffffffffffff7
0000000000000007011dcdccccdcd1100000000004244240000000bb300000004f8877774111114111441414ffffffff7ffffffffffffff77ffffffffffffff7
00000000000000070dddcc5445ccddd00000000004488440000000bbb3000000433444444144414414444114ffffffff7ffffffffffffff77ffffffffffffff7
00000000000000071dcc54444445ccd1000000000444444000000bbbbb300000444744444144415444441114ffffffff7ffffffffffffff77ffffffffffffff7
000000000000000611d4774444774d115222222504444440000033b33b3b0000454444444154415445444444ffffffff7ffffffffffffff77ffffffffffffff7
06777760000000001544774444774451dd76d5d6000000000000033333330000554444555511145555444455ffffffff7ffffffffffffff77ffffffffffffff7
00000000000000001544449999444451007000000000000000003bbbb3b000000567444445514454455447700001100077777777ffffffff7ffffffffffffff7
000000000006000011d4449999444d11aa77a00000000000000003b3b33b000045444544441114444544456700011000ffffffffffffffff7ffffffffffffff7
00000000000750501dcc54444445ccd10a770000000000000000b33333300000444445444141d1541444454400041000ffffffffffffffff7ffffffffffffff7
06777760000705050dddcc5445ccddd00a0a0000000000000003bbbbb3bbb00044774774411111411144d14400044000ffffffffffffffff7ffffffffffffff7
0050050000070505011dcdccccdcd110000000000000000000003b3b3b3b000044714714414441441444114400044000ffffffffffffffff7ffffffffffffff7
0005500000075050001dd1dccd1dd10000000000000000000003333333333000447147144144415444d1d1d100000000ffffffffffffffff7ffffffffffffff7
0050050000060000000111dccd1110000000000000000000000000055000000045444444415441544511111100000000ffffffffffffffff7ffffffffffffff7
00055000000000000000011dd110000000000000dddddddd000000044000000055444455551114555544445500000000ffffffff77777777c77777777777777c
6777777777777777777777766777777667777777777777777777777677cccc7777cccc7777cccc7777ccccccccccc677666666665555565577777777cccccccc
7777777777777777777777777777777777777777777777777777777776cccc6776cccc6776cccc67776cccccccccc777666666665555565566766666cccccccc
777776cc6777777cccc6777777777777777776cc6777777cccc67777cccccccccccccccccccccccc777cccccccccc777dddddddd5555565566766666cccccccc
777ccccccc677cccccccc777776cc677777ccccccc677cccccccc777cccccccccccccccccccccccc777ccccccccc7777000000006666666666766666cccccccc
77ccccccccccccccccccc67777cccc7777ccccccccccccccccccc677cccccccccccccccccccccccc777ccccccccc7777000000005565555577777777cccccccc
77cccccccccccccccccccc7777cccc7777cccccccccccccccccccc77cccccccccccccccccccccccc777ccccccccc6777000000005565555566666766cccccccc
77cccccccccccccccccccc7777cccc7777cccc6776cccc6776cccc7776cccccccccccccccccccc67776ccc6776ccc777000000005565555566666766cccccccc
77cccccccccccccccccccc7777cccc7777cccc7777cccc7777cccc7777cccccccccccccccccccc7777cccc7777cccc77000000006666666666666766cccccccc
77ccccccccccccccccccc67777ccc77777cccc7777cccc7777ccc67777cccccccccccccccccccc7777cccc7777ccc67700000000000000000000000000000000
776cccccccccccccccccc77777ccc777776ccc6776cccc6776ccc77776cccccccccccccccccccc67776ccc6776ccc77700000000000000000000000000000000
777cccccccccccccccccc77777ccc677777cccccccccccccccccc777cccccccccc77cccccccccccc777cccccccccc77700000000000000000000000000000000
777ccccccccccccccccc777777cccc77777ccccccccccccccccc7777cccccccccc77cc7ccccccccc777ccccccccc777700000000000000000000000000000000
777ccccccccccccccccc777777cccc77777ccccccccccccccccc7777cccccccccccccccccccccccc777ccccccccc777700000000000000000000000000000000
777ccccccccccccccccc6777776ccc77777ccccccccccccccccc6777cccccccccccc7ccccccccccc777ccccccccc677700000000000000000000000000000000
776cccccccccccccccccc777777ccc77776ccc6776cccc6776ccc77776cccccccccccccccccccc67776cccccccccc77700000000000000000000000000000000
77cccccccccccccccccccc77777ccc7777cccc7777cccc7777cccc7777cccccccccccccccccccc7777cccccccccccc7700000000000000000000000000000000
777ccccccccccccccccccc7777cccc77777ccc7777cccc7777cccc7777cccccccccccccccccccc77777777777777777700000000000000000000000000000000
776ccccccccccccccccccc7777cccc77776ccc6776cccc6776cccc7776cccccccccccccccccccc67777777777777777700000000000000000000000000000000
77cccccccccccccccccccc7777ccc67777cccccccccccccccccccc77cccccccccccccccccccccccc6777777c6777777c00000000000000000000000000000000
77ccccccccccccccccccc77777ccc77777ccccccccccccccccccc777cccccccccccccccccccccccccc677ccccc677ccc00000000000000000000000000000000
777ccccccc677ccccccc6777776c7777777ccccccc677ccccccc6777cccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
777776ccc777776cccc6777777777777777776ccc777776cccc67777cccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000
7777777777777777777777777777777777777777777777777777777776cccc6776cccc6776cccc67cccccc6776cccccc00000000000000000000000000000000
6777777777777777777777766777777667777777777777777777777677cccc7777cccc7777cccc77cccccc7777cccccc00000000000000000000000000000000
67777777777777777777777667777776cccccccccccccccccccccc7777cccccc77cccccccccccc77cccccc7777cccccccccccccccccccccccccccccccccccccc
77777777777777777777777777777777cccccccccccccccccccccc6776cccccc76cccccccccccc67cccccc6776ccccccccccccccccccccccccccccccccccccbc
7777cc67ccccc76cccc677777776c777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3c
777cccccccccccccccccc77777cccc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccccccccccccccbccccccccb3c
7776cccccccccccccccc677777cccc77cccccccccccccccccccccccccccccccccccccccccccccccccc677ccccc677cccc777777ccccccccccccbcccccbccc3cc
77776cccc67777cccccc7777777cc777ccccccccccccccccccccccccccccccccccccccccccccccccc777776cc777776c6777d66ccc7776ccc3c3cc3ccc3c33cc
77777777777777777777777777777777cccccc6776cccccccccccccccccccccccccccc6776cccccc7777777777777777ddd6666cc777776cc313313ccc3133cc
67777777777777777777777667777776cccccc7777cccccccccccccccccccccccccccc7777cccccc7777777777777777cccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000e4e4e4e40037000000000000000000000000000037
37000000000000000000000000000037370000000000000000000000000000373700000000000000000000000000003700000000e10000373737000000000000
00000000373742373737370000000000000000000000003200000032000000000000c000000000000000e4d4d4d4d4e400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e100000000000000e4000000
00000037a037523737c03700000000000000003700000000000000000000000000003700000000000000e4a0373737e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e4e100000000000000d4000000
000000373737423737373700000000000037375037370000003700000000000000000000000000000000e437373737e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d437f1f1f1f1f1f1f137000000
000000425242520000000000000000000000373737000037373737370000000000000000000000000000d4e4000000e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1000000
00000037373737000000000000000000000037003700320037373700320000000000000037000000370000e4000000e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1000000
00000037373737000000000000000000000032000000000037003700000000000000000037000000370000e4000000e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1000000
00000037373737000000000000000000000000000037000000320000000000000000000000000000000000e4000000e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1000000
00000042425252000000000000000000000000373737373700000000000000000000000000000000000000d4000000e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1000000
0000003737373700000000000000000000000000373737000000000000000000000037000000370000003700000000e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1000000
0000003737373700000000000000000000000000370037000000000000000000000037000000370000003700000000e400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373700000000000000e1e40000
0037373737373700000000000000000000000000000000003200000000000000000000000000000000000000000000e400000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000375037f1f1f1f1f1f1f137d40000
00375037373737000000000000000000000000000000000000000000000000000000e4e4e4e4e4e4e4e40000000000e400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003737370000000000000000000000
00373737373700000000000000000000000000000000000000000000000000373737d4d4d4d4d4d4d4d40000000000e400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000e4e4e4e4e4e4e40000000037373737373737373700000000000000000000e400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000d4d4d4d4d4d4d40000000000373737373737373700000000000000000013e437000000000000000000000000000037
37000000000000000000000000000037370000000000000000000000000000373700000000000000000000000000003700000000000000000000000000000000
000000000000000000000000000000e4000000000000000000000000000000000000e4e4e4e4e4e4e4e4e4e4e4e4e4e437000000000000000000000000000037
37000000000000000000000000000037370000000000000000000000000000370000000000000000000000000000000000000000000000000000000000000000
000000000000e41300000000373737e4000000000000000000000000000000000000d4d4d4d4d4d4d4d4d4d4d4d4d4d400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e4e4000000e400000000003737c0d4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e4d4d4000000d4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e4a03700000000520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d4373700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000e40000e4e4e4e4e4e4e400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000376237370000000000000000003752373737a03737375237000000
0000000000e40000d4d4d4d4d4d4e400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000037373737373700000000000037373737375237373742373737373700
0000000000e43737420000000013e400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000037503770803700000000000037503742373737523737374237c03700
0000000000e43737420000000000e400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000037373737373700000000000037373737374237373752373737373700
00e4e4e4e4e4e4e4e4e4e4000000e400000000d13737373700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000373737370000000000000000003752373737423737375237000000
00d4d4d4d4d4d4d4d4d4d4000000e400000000373737373700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0037373700000000000000000000e400000000373737373700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0037503700000000000000000003e400000000373737373700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0037373700000000000000e4e4e4d400000000373737373700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000d4d4d40000000000000000000000000000000000000000000000000000000000000000000037000000000000000000000000000037
37000000000000000000000000000037370000000000000000000000000000370000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777
00000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777
00000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000007777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777777777777777777
00000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000077777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777777777777777
00000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000777777777777777777
00000000000000000000000000000000000002222000000000000033330000000000000000000000000000000000000000000000000000077777777777777777
00000000000000000000000000000000000002222300000000001333333330000000000000000000000000000000000000000000000000007777777777777777
00000000000000000000000000000000000002222331000000031333333333000000000000000000000000000000000000000000000000000077777777777777
00000000000000000000000000000000000022223331311111131333333333100000000000000000000000000000000000000000000000000007777777777777
00000000000000000600000000000000000022223331311111131333333333130000000000000000000000000000000000000000000000000000077777777777
00000000000000000000000000000000000022223331311111131333333333133000000000000000000000000000000000000000000000000000000777777777
00000000000000000000000000000000000022223331311111131333333333133110000000000000000000000000000000000000000000000000000000077777
00000000000000000000000000000000000222223331311111131333333333133111100000000000000000000000000000000000000000000000000060000000
00070000000000000000000000000000000222223313111111131333333333133111111110000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000222233313111111131333333333133111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000222233313111111131333333333133111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000222233313111111131333333333133110000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000222233313111111131333333333100000000000000000000000000000000000000000000000000000000000000077
00000000000000006000000000000000002222233313111111131333333333100000000000000000000000000000000000000000000000000000000000000077
00000000700000000000000000000000602222233313111111131333333333130000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000700000000002222333313111111131333333333133000000000000000000000000000770000000000000000000000000000000000
00000000000000000000000000000000002222333313111111131333333333133000000000000000000000000000770000000000000000000000000000000000
00000000000000000000000000000000022222333313111111131333333336133100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000022222333131111111131333633333133110000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000022223333131111111131330033333133110000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222223333131111111131300000333133111000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222220003131111111131000000033133111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222200000001111111100000000003133111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222200000000000000000000000003133111110000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222200000000000000000000000000133111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000004222200000700000000000000000000033111111100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000004222200000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000
00000000000000000000000000000004222000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000
00000000000000000000000000000004242000000000000000000770000000000000000000000000000007000000000000000770000000000000000000000000
00000000000000000000000000000004442000000077777777000770000000000000000000000007777777000000000000000000000007000000000000000000
00000000000000000000000000000004242000000777777777700000077000000000000000000077777777700777000000000000000000000000000000000000
00000000000000000000000000000004442000000777000077700000077777777077700000077077700077770777000007700000000000000000000000000000
00000000000000000000000000000004442000000770000007700770077777777707700000077000000007770077700007700000000000000000000000000000
00000000000000000000000000000004442000000000000007700770077700007707700000777000000000770077700007700000000000000000000000000000
00000000000000000000000000000004442000000000000707700770007700000007700000777000000000770007700007700000000000000000000000000000
00000000000000000000000000000004442000000077777707700770006700000007700000770077777700770007700007700000000000000000000000000000
00000000000000000000000000000004444000000777777777700770007700000007700000770777777770770007700007700077700000000000000000000000
00000000000000000000000000000004444000000777007777700770007700000007707700770777007777770007700007700777700000000000000000000000
00000000000000000000000000000004444000000770000777700770007700000007777700770770000777770007700077707777000000000700000000000000
00000000000000000000000000000004442000000770007777700770007700000007777777770777007777770007770077777770700000000000000000000000
00000000000000000000000000000004444000000777777777770777707700000000777777770777777777777007777777777700000000000000000000000000
00000000000000000000000000000004442000000777777707770777707700000000777077700077777700777000777777770000000000000000007000000000
00000000000000000000000000000004442000000000000000000000000000000007000000000000000000000000000077700000000000000000000000000000
00000000000000000000000000000024442000000000000000000000000000000000000000000000000000000000000777700000000000000000000000000000
00000000000000000000000000000024442000000000000000000000000000000000000000999000000000000000007777700000000000000000000000000000
00000000000000000000000000000024440000000000000000000000000000990090900000999099909990099000007777700000000000000000000000000000
00000000000000007000000000000044440000000000000000000000000000790099900000909099009900909000077707700000000000000000000000000000
00000000000000022200000000000024440000000000000000000000000000909000900000909090009000999000777777700000000000000000000000000000
00000000000000220770000000000044440000000000000000000000000000999099000000909009900990900000777077700000000000000000000000000000
00000000000000200770000000000044440000000000000000000000000000000000000000000000000000000000770777000000000000000000000000000000
70000000000000222222000000000444420000000000000000000000000000000000000000000000000000000000777777000000000000000000000000000000
11111111111022222222222611110444420111111111111111111111111111111111111111111111111111111110777770111111111111111111111111111111
1111177111082222222228820111024440111111111771111111111111111111111111111111111111111111111777770cccccccc7cccccccccccccccccccccc
11111771102828822222822820110244401111111117711111111111111111111111111111111111111111111111000011111111111111111111111111111111
111111110288882222222822201102444011111111111111111111111111111111111111111111111111111111111111cccccccccccccccccccccccccccccccc
11111111028288222227222222010242401111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111022222222222222222002244401111111111111111111111111111111111111111111111111111111111111111cccccccccccccccccccccccccccccc
11111110222222222222222222202242401111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111110222222222222222222202242011111111111111111dd111dd1d111ddd11dd1d1d11dd1111111111111111111111ccccccccccccccccccccccccccccc
11111110202222222222222222222222011111111111111111d111d111d1111d11d111d1d111d111111111111111111111111111111111111111111111111111
11111111002222222222222222228222011111111111111111d111d111d1111d11d111dd1111d11111111111111111111111cccccccccccccccccccccccccccc
11111111102222222222222222828888201111111111111111d111d111d1111d11d111d1d111d111111111111111111111111111111111111111111111111111
11111111102222222222222222222888820111111111111111dd111dd1ddd7ddd11dd1d1d11dd1111111111111111111111111cccccccccccccccccccccccccc
11111111110222222222222222222228882011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111110322222222222222222222282700001111111111111111111111111111111111111111111111111111111111111111cccccccccccccccccccccccc
11111111110332222222222222222822222777770111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111100000633222222222222222222222777777701111111111111111111111111111111111111111111111111111111111111111cccccccccccccccccccccc
11110777776332222222222222222222222777777011111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111077777663332222222222222222222777777770111111111111111111111111111111111111111111111111111111111111111111ccccccccccccccccccc
1111077777ddd333222222222222222d277777777770000000011111111111111111111111111111111111111111111111111111111111111111111111111111
1111077777dddddddd2222222d222227777777777777777777701111111111111111111111111111111111111111111111111111111711111ccccccccccccccc
111077777dddddddddddd22222ddd777777777777777777777701111111111161111111111111111111111111111111111111111111111177111111111111111
000777777ddddddddddddddddd7777777777777777777777777011111111111111111111111111111111111111111111111111111111111771111ccccccccccc
77777777ddddddddddddddddd7777777777777777777777777701111111111111111111111111111111111111111111111111111117111111111111111111111
77777777ddddddddddddddd7d7777777777777777777777777770111111111111111111111111111111111111111111111111111111111111111111111cccccc
7777777ddddddddddddddd7d77777777777777777777777777770111111111111111111111111111111111111111111111111111117111111111117111111111
77777777ddddddddddddd7d77777777777777777777777777777701111111111111111111116111111111111111111111111111111111111111111111111111c
7777777d7ddddddddddd7d7777777777777777777777777777777700111111111111111177111111111111111111111111111111111111111111111111111111
77777777d7d7d7ddddd7d77777777777777777777777777777777777000011111111111167111111111111111111111111111111111111111111111111111111
777777777d7d7d7d7d7d777777777777777777777777777777777777777701111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777770111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777770111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777011111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777011111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777701111111111111101111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777701111111111111030111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777701111111111111030111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777770111111111100030001111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777001111111033030330111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777770171111033033301111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777000000003333301111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777773333700001111111111111111111111111111111111111711111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777770000111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777011111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777011111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000000000000011111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777011111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000000000
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77666777777777777777777777666777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77666776676677667767677777767767677667667776677667667777777777777777777777777777777777777777777777777777777777777777777777777777
77676767676767676766677777767767676767676767776767676777777777777777777777777777777777777777777777777777777777777777777777777777
77676766676767676777677777767766676767667777676767676777777777777777777777777777777777777777777777777777777777777777777777777777
77676767676677667766777777767767676677676766776677676777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77667777777777777777776667777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77676776677667677777776767666766776677676777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77676767676677677777776677667767676767666777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77676767676777677777776767677766776677776777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77676766777667766777776667766767676767667777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

__gff__
000000000006000000000000000000000000000000000000000000000606060600000000000001010000000e0e0e0e0e0000000000020101000000000e0e0e0e06060606060606060606060602010106060606060606060606060606000003000606060606060606060606060000000006060606060606060606060606060606
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000004e4e4e4e0000000000000000733873730000000000000000000000000000000000004e4e4e000000000000000000000000000000000000000000000000004e4e4e4e4e00000000000000000000000000000000000000004e4e4e000000000000004e4e4e0000000000004e4e4e000000000000004e4e4e0000000000
0000004e4d4d4d4d00000000000000007373737373004e00730c73000000000000000000004e4d4d4d0000000000000000000000000000000000000000000000004e4d4d4d4d4d00000000000000004e00000000000000000000004d4d4d4e00000000004e4d4d4d0000000000004d4d4d4e0000000000004d4d4d0000000000
00004e4d737373730000000000004e007373057373004e00737373000000000000000000004e730a730000000000000000000000007373737373737300000000004e737373737300000000737373734e0000000000000000000000730a734e00000000004e7330730000000000007373734e0000000000007373730000000000
00004d73737373737373737373734d4e7373737373004e00737373000000000000000000004e7373730000737373734e0000000000732e3c2f730a7300000000004e31737373731f1f1f1f737373734e00000000000000000000007373734e00000000004e7373730000000000007373734e000000000000730c730000000000
000073732e2f73737373737373730a4e7373737373004e00737373000000000000000000004e3173731f1f730c73734e0000000000732c2b2d73737300000000004d737373737300000000737373734e00000000000000000000007373734d00000000004d73737300000000004e0000004e0000000000007373730000000000
0000732e2b3f7373737373730c73734e7373737373004e00737373000000000000000000004d7373730000737373734e00002e2f00733e3d3f73000000000000000000001e0000000000004e4e73734d0000000000000000004e0000000000000000000000001e00000000004e4e0000004e4e00000000000000000000000000
0000733e3f737373737373737373734e7373737373004d007373730000000000000000000000001e0000004e4e4e4e4d00003e3f007373737373007300000000000000001e0000000000004d4e7373731f1f1f1f2e3c3c3c2f4e000000000000000000004e001e00000000004d4d0000004d4d0000000000004e000000000000
0000737373734e4e7373737373734e4d73737373730000000000000000000000000000000000001e0000004d4d4d4d0000000000000000000000000000000000000000001e000000000000004e000000000000003e3d3d3d3f4d000000000000000000004e73737300000000000000000000000000007373734e000000000000
0000737373734d4d0000000000004d007373737373007373737373000000004e000000000000001e000000000000000000007373737373004e00737373737300000000001e000000000000004e00000000000000000000000000000000000000000000004e73737300000000000000000000000000007373734d000000000000
000000737373737300000000000000007373737373007373737373007373734e000000737373737300000000000000007300732e3c2f73004e00732e3c2f7300000000001e000000000000004e00000000000000000000000000000000000000000000004e737373000000004e4e0000004e4e000000001e0000000000000000
00007373737373730000000000000000737373737300737373737300730a734e000073737373737373000000000000000000732c2b2d73004e00732c2b2d73000000007373730000000000004d000000000000000000000000737373734e0000000000004d4e4e4e000000004d4e0000004e4d000000001e0000000000000000
007373737373737300000000000000007373737373007373737373007373734d007373737373733073000000000000007373733e3d3f73004e00733e3d3f730000000073057300000000000000000000000000000000000000730c73314e000000000000004d4d4d00000000004e0000004e000000000073731f1f730a000000
002873737305737300000000000000004e4e4e4e4e00000000000000000000000073057373734e4e730000000000000073057373737373004d0073730c73730000000073737300000000000000000000000000000000000000737373734e0000000000000000000000000000004e7373734e0000000000737300007373000000
007373737373737300000000000000004d4d4d4d4d00000000000000000000000073737373004d4d00000000000000007373730000000000000000737373000000000000000000000000000000000000000000000000000000000000004d0000000000000000000000000000004e7305734e0000000000000000000000000000
000073737373730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d7373734d0000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004e4e4e4e000000000000000000000000000000000000000000000000000000000000000000000000004e73730000000000000000000000000000000000000000000000000000000000000000000000000000737373730000230000000000007373730000737373000000000000000000000000000000000000
000000000000004d4d4d4d000000000000000000000000000000000000000000000000000000000000000000000000004e0c7373000000000000000000314e00000000737300000000000000004e0000000000230000000000737373730000000000000000007373730000730c73000000000000000000000000004e00000000
0000000000000073730c73000000000000000000000000000000000000000000000000000000000000000000000000004e737373000000000000000000734d00000000730a73000023000000004e7373730000000000000000737373730000000000000000007373314e4e4e4e4e000000000000000073737300004d00000000
0000000000000073737373000000000000000000000000000000000000000000000000000000000000000000000000004d4e4e4e000000000000230000000000000000737373000000000000004d730c7300000000000000004e4e4e4e4e00000000000000007373734d4d4d4d4d0000000000000000730c731f1f7300000000
00000000007300001e1e0000007373730000000073737373007373737373730000737373737373730000000000000000004d4d4d000000000000000000000000000000000000000000000000000073737300000000000000004e4d4d4d4d00000000000000007373730000000000000000000000000073737300001e00000000
00000000000000737373730000730a73000000737373737300737373737373000073737373737373737300000000000000000000000023000000000000004e0000000000004e4e00004e4e4e4e4e00000000000000000000004e00000000000000000000004e3173730000000000000000000000000000000000001e00000000
0000000000007373737373730073737300000073737373730000737373734e000000737373737373737373737300000000000000000000000000000073304e0000000000004e4d00004d4d4d4d4d00000000000000002e3c2f4e00007373737300000000004d7373730000000000000000000000000000000000001e00000000
0000000000007373227373730000000000007373730000000000004e4e4e4d00230000000000007373737373730000000000000000000000000000004e4e4d0000000000004e737373737300000000000000000000002c2b2d4e0000737373730000000000007373730000007373730000000000000000000000001e00000000
0000000000007373737373730073000000007305730000000000004d4d4d000000000000000000737373730c730000000000000000000000000000004d4d000000000000004e737373737373730000000000000000003e3d3f4e00004e4e4e4e0000000000007373314e0000730a730000000000000000000000001e00000000
000000000000737373737373000000000000737373730000000000000000000000000000000000000073737373000000000000000000000000000000000000000000004e4e4e4e22734e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e00004d4d4d4d0000000000007373734d000073737300000000004e0000000000001e00000000
000000000000007373737300000000000000737373737373000073737373730000737373730000000073737300000000000000000000000000000000000000000000004d4d4d4d73734d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d00000000000000000000000073737300000000000000000000004d0000000000001e4e000000
00000000000000001e1e0000000000000000007373737373007373227373730a73737322737300000000000000000000000000004e737373734e7373734e0000000000737373737373737373000000000000000000002e2f00000000004e000000000000004e3173737300000000000000000000731f1f1f1f1f1f734d000000
000000000000007373737300000000000000007373737373007373737373737373737373737300000000000000000000000000004e737305734e730a734e000000000073057373737373000000000000002e2f0000003e3f00000073734e000000000000004d73730573000000000000000000001e0000000000000000000000
000000000000007305737300000000000000000073737300000073737373000000737373730000000000000000000000000000004e737373734e7373734e000000000073737300000000000000000000003e3f000000000000000073734d000000000000000000737373000000000000000000001e0000000000000000000000
000000000000007373737300000000000000000000000000000000000000000000000000000000000000000000000000000000004d4e4e4e4e4d4e4e4e4d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e0000737373000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d4d4d4d004d4d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e0000730a73000000000000
__sfx__
000200000641008410094100b410224302a4403c6403b6403b6403964036640326402d6402864024630216301d6301a63016620116200e6200b61007610056100361010600106000060000600006000060000600
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001362018640156501763013650176401462000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
00080000360513505133051310512f0512d051366613666130651226411262108611046113000030000300003000030005006010000100001000012f0012f0012f00100001000010000100001000010000100001
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000021670176401b6001960000600356003560035600356003560000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001a6701e6601a6501767021650176601a670136501a6501b6401f620146100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
00020000144501d450294502944029440294302942029410354003540000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
001000001b54020550245502c5602c5002c5000050032500355000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
790c0000242452b24530245242352b23530235242352b23530235242252b22530225242252b22530225242152b21530215242152b21530215242052b20530205242052b205302053a2052e205002050020500205
0010002021610206101e6101b610196101561012610116100f6100e6100d6100c6100c6100c6100c6100d6100e6100f610106101161013610156101661017610196101b6101d6101e61020610216102261022610
910c00000712007120071200712007120071200712007125131201312013120131201312013120131201312517120171201712017120171201712017120171251312013120131201312013120131201312013125
010c0000000000000000000000001a0301a0351a0301a0301a0301a0351f0301f0301f0301f0301f0301f0351f0301f0301f0301f035210302103523030230302303023035210302103021030210352103021035
010c00000e1200e1200e1200e1200e1200e1200e1200e125121201212012120121201212012120121201212515120151201512015120151201512015120151251212012120121201212012120121201212012125
010c0000210302103021030210351a0301a0351a0301a0301a0301a0301a0301a03517030170351a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a035
010c00000c1200c1200c1200c1200c1200c1200c1200c120101201012010120101201012010120101201012013120131201312013120131201312013120131201012010120101201012010120101201012010120
010c0000000000000000000000001c0301c0351c0301c0301c0301c035240302403024030240302403024035240302403024030240352303023030230302303521030210351f0301f0301f0301f0301f0301f035
010c00000712007120071200712007120071200712007125131201312013120131201312013120131201312517120171201712017120171201712017120171251312013120131201312013120131201312013125
010c0000210302103021030210352303023030230302303521030210302103021035230302303023030230302303023030230302303023030230302303023030230302302023020230151c0001c0001c0001c000
010b0000210302103021030210351a0301a0351a0301a0301a0301a0351c0301c0301c0301c0351a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a0301a035
010c00002103021030210302103523030230302303023035210302103021030210351f0321f0321f0321f0321f0321f0321f0321f0321f0321f0321f0321f0351f0301f0301f0301f0351e0301e0301e0301e035
010c0000101201012010120101251012010120101201012517120171201712017120101201012010120101250e1200e1200e1200e1250e1200e1200e1200e125121201212012120121250e1200e1200e1200e125
010c00001c0301c0301c0301c0301c0301c0351c0301c0351c0301c0351f0301f0301f0351c0301c0301c0351e0301e0301e0301e035170321703217032170321703217032170321703217032170351a0301a030
010c00000c1200c1200c1200c1250c1200c1200c1200c125131201312013120131250c1200c1200c1200c12507120071200712007125071200712007120071250e1200e1200e1200e1250e1200e1200e1200e125
010c00001c0301c0351c0301c0301c0351c0301c0301c0351a0301a03518030180301803515030150301503517032170321703217032170321703217032170351f0301f0301f0301f0351e0301e0301e0301e035
010c00001c0301c0301c0301c0351c0301c0301c0301c0351c0301c0351f0301f0301f0301c0301c0301c030210302103021030210351a0321a0321a0321a0321a0321a0321a0321a0351a0301a0351a0301a035
010c00000c1200c1200c1200c1250c1200c1200c1200c125131201312013120131250c1200c1200c1200c1250c1200c1200c1200c1250c1200c1200c1200c1251312013120131201312013120131201312013125
010c00001c0301c0301f0301f0301f0351f0301f0301f0351f0301f03521030210302103523030230302303523032230322303223032230322303223032230322303223032230322303223032230322303223035
010c00000e1220e1220e1220e1220e1220e1220e1220e1220e1220e1220e1220e1120e1120e115001000010000100001000010000100001000010000100001000e1200e1200e1200e12502120021200212002125
010c0000210322103221032210322103221032210322103221032210322102221022210122101526000260002603426032260322603226032260351f0301f0351f0301f035210302103523030230352403024035
010c000013120131201312013125131201312013120131251f1201f1201f1201f1251312013120131201312512120121201212012125121201212012120121251e1201e1201e1201e12512120121201212012125
010c000026030260352603026030260352603026030260352603026035240302403024035230302303023035260302603526030260302603526030260302603526030260352803028030280352a0302a0302a035
010c000010120101201012010125101201012010120101251c1201c1201c1201c125101201012010120101250e1200e1200e1200e1250e1200e1200e1200e1251a1201a1201a1201a1250e1200e1200e1200e125
010c00002b0322b0322b0322b0322b0322b0352303023035230302303023030230352803028035260322603226032260322603226032260322603226032260350000000000230302303521030210351f0321f032
010c0000001200c1200c1200c1250c1200c1200c1200c125181201812018120181250c1200c1200c1200c1250b1200b1200b1200b1250b1200b1200b1200b125171201712017120171250b1200b1200b1200b125
010c00001f0321f0321f0321f0321f0321f0321f0321f0321f0321f0351f0301f0352803028030280302803526032260322603226032260322603226032260322603226032260322603521030210352303023035
010c0000151201512015120151251512015120151201512521120211202112021125151201512015120151251a1201a1201a1201a1251a1201a1201a1201a1250e1200e1200e1200e1250e1200e1200e1200e125
010c0000210302103021030210352303023030230302303524030240302403024035260302603523030230302303023035210322103221032210351f0301f0351f0301f035210302103523030230352403024035
010c00001512015120151201512517120171201712017125181201812018120181251a1201a1201a1201a12513122131221312213122131221312213122131221312213122131221312213122131221312213122
010c00002103021030210302103523030230302303023035240302403024030240351e0301e0352103021030210302103021030210351f0321f0321f0321f0321f0321f0321f0321f0321f0321f0321f0321f032
010c00001312213122131221311213112131151310213105021200212002120021250212002120021200212502120021202663026625021200212026630266250212002120266302662502120021202663026625
010c00001f0321f0321f0221f0221f0121f0151f0021f0051a0341a0350e0300e03513030130350e0300e0351a0301a0350e0300e03513030130350e0300e0351a0301a0350e0300e03513030130350e0300e035
010c00001310213102131021310213102131051310213105021200212002120021250212002120021200212502120021202663026625021200212026630266250212002120266302662502120021202663026625
010c00001f0021f0021f0021f0021f0021f0051f0021f0051a0341a0350e0300e03513030130350e0300e0351a0301a0350e0300e03513030130350e0300e0351a0301a0350e0300e03513030130350e0300e035
__music__
00 2f304344
01 10114344
00 12134344
00 14154344
00 16174344
00 10114344
00 12184344
00 14154344
00 10194344
00 1a1b4344
00 1c1d4344
00 1a1e4344
00 1f204344
00 21224344
00 23244344
00 25264344
00 27284344
00 292a4344
00 23244344
00 25264344
00 27284344
00 2b2c4344
02 2d2e4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 0f424344

