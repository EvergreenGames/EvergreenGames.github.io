pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--~amazon~
--by meep
function vector(f,e)return{x=f,y=e}end function zvec()return vector(0,0)end function rectangle(f,e,n,d)return{x=f,y=e,w=n,h=d}end function init_cam()_cam_x,_cam_y,cam_x,cam_y,cam_dx,cam_dy,cam_g=usplit"0,0,0,0,0,0,0.1"end function move_cam(f,e)local e=cam_lock and 0or e or cam_g cam_dx,cam_dy=e_appr_delta(cam_x,mid(0,f.hmid()-63,8*rw-128),e),e_appr_delta(cam_y,mid(0,f.vmid()-63,8*rh-128),e)_cam_x+=cam_dx _cam_y+=cam_dy cam_x,cam_y=round(_cam_x),round(_cam_y)end function cam_draw()camera(cam_x,cam_y)end function _init()exec[[cartdata◆rainforeste
poke◆0x5f2e,1
init_cam
init_g_particles
title_init]]end function begin_game()seconds_f,minutes,deaths,fruits,delay_restart,room_title=usplit"0,0,0,0,0,0"_update,_draw,ticking=game_update,game_draw,true fill(1)end function game_update()if(ticking)seconds_f+=1minutes+=seconds_f\1800seconds_f%=1800
foreach(objects,function(f)if(f.freeze>0)f.freeze-=1return
f.move(f.spd.x,f.spd.y)f:update()end)if(delay_restart>0)delay_restart-=1if(delay_restart==0)collect,held,room_goto=false,nil,room
if(room_goto)fill(room_goto)room_goto=false
end function init_g_particles()birbs,clouds={},{}for f=1,3do add(birbs,{x=rnd"256",y=rnd"48",off=rnd"1"})end for f=0,8do add(clouds,{x=rnd"128",y=rnd"32",spd=.25+rnd"0.75",w=32+rnd"32"})end end local print,e,n,d,f=print,rnd,del,rectfill,t function draw_birbs()foreach(birbs,function(_ENV)x-=.4if(x<0)x,y=128+e"128",e"48"
?f()%.5<.25and"ˇ"or"…",x-7,y+4*sin(off+f()/4),14
end)end function game_draw()local o,r,l,i,a,c,f,u,t=8*rh,8*rw,clouds,smoke,dead_particles,cam_dx,rwl,draw_spr,t()exec[[pal
camera
cls◆10
fillp◆0b0101101000000101.1
rectfill◆0,124,127,127,0
fillp]]exec[[fillp◆0b0000010100001010.1
pal◆1,0]]for f=-4,0,4do for e=f,r,16do draw_tree(e+room/128,72+4*f)end pal()end fillp"0b1010010110100101.1"foreach(l,function(_ENV)x+=spd-c/2for f=0,2do d(x-f,y+f,x+w+f,y+16-w*0x.3-f,1)end if(x>128)x,y=-w,e"32"
end)exec[[draw_birbs
fillp
cam_draw
ssload◆1]]foreach(split(rbg,";"),function(f)draw_plant(usplit(f," "))end)exec[[ssload◆0
camera◆0,cam_y]]if f do for e=0,127,2do for n=-1,0do d(e,f+(2+sin(t>>2))*sin(4*t+e+cam_x>>6)+n,e+1,o-1,1-n*11)end end foreach(objects,function(n)local d=n.bottom()>=f+2if(n.w~=d and abs(n.spd.y)>1.5)for d=1,20do make_particles(water_particles,n.hmid(),f,vector(e"1.5"-.75,-1.25-e(abs(n.spd.y)/2)),e"1"<.5and 12or 1,2)end
n.w=d end)camera(0,cam_y-8*rh+128)exec[[fillp◆0b0101101000000101.1
rectfill◆0,124,127,127,10
fillp]]end exec[[cam_draw
update_particles◆water_particles,1
draw_particles◆water_particles,1]]pre_draw,post_draw=sort(filter(objects,function(_ENV)return layer<0end),"layer"),sort(filter(objects,function(_ENV)return layer>=0end),"layer")exec[[foreach◆pre_draw,draw_obj
cmap◆0b11
foreach◆post_draw,draw_obj]]local e=t%4\.25while f and e<8*rh do for n=max(f+3,e),min(min(cam_y+127,o-1),e+1)do for f=cam_x,cam_x+128do if(not fget(tile_at(f\8,n\8),0))pset(f,n,pget(f,e))
end end e+=16end foreach(i,function(_ENV)_spr+=.2x+=spd.x y+=spd.y if(_spr>=32)n(i,_ENV)else u(_ENV)
end)foreach(a,function(_ENV)x+=dx y+=dy k-=.2if(k<=0)n(a,_ENV)
d(x-k,y-k,x+k,y+k,6+k*5%2)end)exec[[camera
pal◆11,139,1
pal◆13,132,1
pal◆2,130,1
pal◆14,131,1
pal◆10,129,1]]if(room_title>0)room_title-=1exec[[draw_time◆4,4
draw_room_title◆32]]
if(dialog)draw_dialogue(unpack(dialog))dialog=nil
end function draw_dialogue(e,f)for e in all(split(e,"◆"))do local d,e,n,t=usplit(e,";")camera(0,round(8*-.5^f)+96-(t or 96))for n=1,#e+n do f-=1if f<=0do _spr=2*d exec[[ssload◆2
rectfill◆6,97,123,116,5
rectfill◆5,98,124,115,5
rectfill◆5,96,122,115,7
rectfill◆4,97,123,114,7
palt◆0
spr◆_spr,6,98,2,2
ssload◆0]]?sub(e,1,n),25,99,0
if(n<#e and n%3==0)sfx"17"
goto f end end end::f::palt()end function cmap(f)map(rx+cam_x\8,ry+cam_y\8,cam_x\8*8,cam_y\8*8,17,17,f)end function l_appr(f,e,n)return f>e and max(f-n,e)or min(f+n,e)end function e_appr_delta(f,e,n)return n*(e-f)end function sign(f)return f==0and 0or sgn(f)end function round(f)return flr(f+.5)end function tile_at(f,e)if(f>=0and f<rw and e>=0and e<rh)return mget(rx+f,ry+e)
end function two_digit_str(f)return f<10and"0"..f or f end function draw_time(f,e)camera(-f,-e)exec[[rectfill◆0,0,44,6,0
camera
color◆7]]?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),f+1,e+1
end function draw_room_title(f)local e=2*#rt local e,n=64-e,64+e d(e-6,f,n+4,f+16,0)rect(e-5,f+1,n+3,f+15,14)?rt,e,f+6,7
end function filter(e,n)local f={}foreach(e,function(e)if(n(e))add(f,e)
end)return f end function sort(e,n)local f={}foreach(e,function(e)for d=1,#f do if(e[n]<=f[d][n])return add(f,e,d)
end add(f,e)end)return f end function perm(f)local d={}while#f>0do local e=f[1+flr(e(#f))]add(d,e)n(f,e)end return d end function usplit(f,e)if(f)local f=split(f,e)for n,e in pairs(f)do f[n]=_ENV[e]or e end return unpack(f)
end function exec(f)foreach(split(f,"\n"),function(f)local f,e=usplit(f,"◆")f(usplit(e))end)end function cprint(f,e,n,d)?f,64-2*#f+e,n,d
end function get_objs(f)return filter(objects,function(e)return e.obj==f end)end function get_obj(f)return get_objs(f)[1]end function get_player()return get_obj(player)or get_obj(player_spawn)end function draw_spr(f)spr(f._spr,f.x,f.y,1,1,f.flp.x,f.flp.y)end function draw_obj(f)f:draw()end function mag(f)return sqrt(f.x^2+f.y^2)end function make_particles(f,e,n,d,t,o)add(f,{x=e,y=n,spd=d,w=o,c=t,t=0})end function update_particles(f)local e=n foreach(f,function(_ENV)x+=spd.x y+=spd.y spd.y+=f.grav or 0t+=1if(t==f.duration)e(f,_ENV)
end)end function draw_particles(f)local e=d foreach(f,function(_ENV)e(x,y,x+w-1,y+w-1,c)end)end function psfx(f)sfx"-1"sfx(f)end function play_music(f,e,n)if(curr_music~=f)curr_music=f music(f,e,n)
end rm_data,rexec=split([[0,0,32,16,trail entrance,0b10,left,0,nil,1 4 16 1;2 0 76;3 40 80;1 120 0;2  112 80 1;2 130 72;1 148 -4;1 192 -16 1;3 184 64 1;2 228 64
32,0,16,16,grass tuesday,0b10,left,0,nil,2 -16 80;2 24 96;1 64 -48;2 80 44 2
48,0,16,16,way of life,0b10,left,0,nil,1 -32 3;1 48 72 1;2 24 116;2 48 96;2 96 32 2;3 64 56
64,0,16,16,falling rocks,0b01,left,0,nil,3 -12 104;4 88 72;2 24 112;2 64 108
80,0,16,16,spike pit,0b10,left,0,nil,2 36 48;2 72 80;4 82 16;1 -64 24 1
96,0,16,16,the corner,0b01,left,0,nil,1 64 8 1;4 44 56;2 32 84;2 0 80 1
112,0,16,16,eroded ravine,0b10,left,0,nil,2 -22 68;4 0 64;2 84 88;2 80 8;3 92 4
0,16,16,16,lush grotto,0b10,left,0,nil,1 -44 88 1;1 88 -24 1;2 0 8;2 -20 72 1;3 64 104 1
16,16,16,16,bare necessities,0b01,left,0,120,1 -32 0;2 -20 92;4 80 0
32,16,16,16,frozen dropoff,0b01,bottom,0,nil,4 16 72;3 -8 88 1;3 48 96;1 76 56 1;1 64 4 1;2 88 48
48,16,16,16,kerchak pass,0b10,left,0,nil,3 -16 0;3 36 24;2 20 116;4 -20 88 1;4 80 72
0,32,16,32,mossy gateway,0b10,left,0,nil,1 0 152;1 80 120 1;2 -14 196;3 80 184 1;2 -16 120 1;4 0 16 1;4 80 0;2 96 232
64,16,16,16,vine and dandy,0b10,left,0,nil,2 -8 24;4 60 16;4 -16 96;2 24 112;1 104 88
80,16,32,16,the lonely island,0b10,left,0,80,1 -32 -32;4 40 0;2 141 56
112,8,16,24,monument valley,0b10,left,63,nil,1 -24 56;2 24 156;2 100 88 1;4 64 128 1;2 50 40
32,32,16,16,ship happens,0b01,left,0,88,1 -45 -20;2 -36 60;4 100 56;2 88 8
48,32,32,16,ferrytale,0b10,top,0,96,2 -20 8;3 32 0;4 180 16
80,32,16,16,part of your world,0b10,left,0,16
16,32,16,32,enduriance,0b01,left,0,240,1 93 104;4 16 96 1;2 -4 48;3 -8 37
96,32,16,16,dekurate,0b01,left,63,nil,1 20 20
112,32,16,16,base camp,0b00,left,63,nil,4 -16 48;3 -24 16
32,48,16,16,flyin' dirty,0b10,left,12,nil,1 -40 8;2 0 96;2 32 96;3 72 96
48,48,16,16,gonen's vines,0b10,left,12,nil,3 -18 100;4 26 64
64,48,16,16,bump jump mania,0b10,left,12,nil,3 20 98 1;3 44 70;2 32 24;4 84 0
80,48,32,16,celestial valley,0b10,left,12,120,4 40 64 1;3 108 40 1;2 180 -4;4 194 78
112,48,16,16,???,0b00,bottom,-1,nil,4 -10 42 1;1 74 30 1]],"\n"),{[7]="reload",[15]="load_data◆5575555556517651745151775151547555556565665151676167676151745455556651747751524d00004d4c57515455565176516767620000000000507754756651746200004d0000000000575154557751474d0000000000000000577664657476520000004b48000000305051517451514700000040414141414151745151,112,8,16",[19]="init_object◆pickup,120,224,13"}function load_data(e,d,t,n)for f=1,#e,2do mset(d+f\2%n,t+f\2\n,"0x"..sub(e,f,f+1))end end function fill(f)room,rx,ry,rw,rh,rt,re,rs,rmc,rwl,rbg=f,usplit(rm_data[f])cam_lock,objects,smoke,dead_particles,water_particles,rwl=false,{},{},{},{duration=20,grav=.2},tonum(rwl)if(rexec[f])exec(rexec[f])
for e=0,rh-1do for n=0,rw-1do local f=tile_at(n,e)if(tiles[f])init_object(tiles[f],8*n,8*e,f)
end end if(not stfu)play_music(rmc,0,3)
collect,room_title,cam_lock=nil,40,f==15end player={init=function(f)f.layer,f.grace,f.jbuffer,f.djump,f.climb_cd,f.dash_cd,f.dash_time,f.dash_target_x,f.dash_target_y,f.dash_accel_x,f.dash_accel_y,f.hitbox,f.spr_off,f.solid,f.rider=1,0,0,1,0,0,0,0,0,0,0,rectangle(usplit"1,3,6,5"),0,true,true create_hair(f)end,update=function(f)move_cam(f)local n,d,t=tonum(btn"1")-tonum(btn"0"),tonum(btn"3")-tonum(btn"2"),f.is_solid(0,1)if(f.is_flag(0,0,"spike")or f.y>rh*8or f.spd.y>=0and f.check(plat,0,1))kill_obj(f)return
if(re&1>0and f.bottom()<0or re&2>0and f.left()>=8*rw)room_goto=room+1
if(t and not f.was_on_ground)f.init_smoke(0,4)
f.was_on_ground=t local i,o=btn"4"and not f.p_jump,btn"5"and not f.p_dash f.p_jump,f.p_dash=btn"4",btn"5"if i do f.jbuffer=4elseif f.jbuffer>0do f.jbuffer-=1end if t do f.grace=6if(f.djump<1)sfx"14"f.djump=1
elseif f.grace>0do f.grace-=1end f.climb_cd,f.dash_cd=max(f.climb_cd-1),max(f.dash_cd-1)if(o)local e=f.check(pickup)if not held and e do o,held=false,e e.delete()elseif held do add(objects,held)held.x,held.y=f.x,f.y held.move(0,-6)o,held,held.spd=false,nil,vector((d>0and 1.25or 3)*(n~=0and n or f.flp.x and-1or 1),d-1)sfx"24"end
if f.climbing do f._spr=8+f.y\4%2local t,e=unpack(f.climbing)if(not f.not_free(0,d))e=mid(1,#t,e+.25*d)
local o,i,a=e%1,t[flr(e)],t[ceil(e)]local o,i=o*round(a.x)+(1-o)*round(i.x)-f.hmid(),o*round(a.y)+(1-o)*round(i.y)-f.vmid()f.move(o,i)f.climbing={t,e}if(f.jbuffer>0)f.climbing,f.climb_cd,f.jbuffer,f.spd.y=nil,5,0,d>0and 1or-3.36f.move(2*n,0)
if(abs(o)+abs(i)>4)f.climbing=nil
return end if f.dash_time>0do f.init_smoke()f.dash_time-=1f.spd=vector(l_appr(f.spd.x,f.dash_target_x,f.dash_accel_x),l_appr(f.spd.y,f.dash_target_y,f.dash_accel_y))else local i,l,a,r=2,t and.93or.8,3,abs(f.spd.y)>.124and.334or.167if(rwl and f.bottom()>=rwl)i/=1.2a/=2r/=2
f.spd.x=abs(f.spd.x)<=i and l_appr(f.spd.x,n*i,l)or l_appr(f.spd.x,sign(f.spd.x)*i,.16)if(f.spd.x~=0)f.flp.x=f.spd.x<0
if(n~=0and f.is_solid(n,0))a=.8if(e"10"<2)f.init_smoke(n*6)
if(not t)f.spd.y=l_appr(f.spd.y,a,r)
if f.jbuffer>0do if(f.grace>0)sfx"25"f.jbuffer,f.grace,f.spd.y=0,0,-3.36f.init_smoke(0,4)else local e=f.is_solid(-3,0)and-1or f.is_solid(3,0)and 1or 0if(e~=0)sfx"23"f.jbuffer,f.spd=0,vector(-e*(i+1.06),-3.36)f.init_smoke(e*6)
end if f.djump>0and f.dash_cd==0and o do f.init_smoke()f.djump-=1f.dash_time,f.spd=4,vector(n~=0and n*(d~=0and 4.6528or 6.58)or(d~=0and 0or f.flp.x and-1or 1),d~=0and d*(n~=0and 4.6528or 6.58)or 0)sfx"28"f.dash_target_x,f.dash_target_y,f.dash_accel_x,f.dash_accel_y=3.07*sign(f.spd.x),(f.spd.y>=0and 3.07or 2.55)*sign(f.spd.y),f.spd.y==0and 2.37or 1.6758,f.spd.x==0and 2.37or 1.6758elseif f.djump<=0and o do sfx"10"f.init_smoke()end end f.spr_off+=.25f._spr=not t and(f.is_solid(n,0)and 5or 3)or btn(⬇️)and 6or btn(⬆️)and 7or 1+(f.spd.x~=0and n~=0and f.spr_off%4or 0)end,draw=function(f)pal(8,f.djump==1and 8or 12)draw_hair(f)draw_spr(f)pal()local e=flr(f._spr)spr(16,f.x,f.y+(e==3and-7or e==6and-5or-6))if(held)spr(held._spr,f.x,f.y-6,1,1,held.flp.x,false)
end,on_move=function(f,n,e)if not f.climbing and f.climb_cd==0and(btn(⬆️)or btn(⬇️))do for n in all(get_objs(vine))do for d,e in ipairs(n.rope)do if(abs(round(e.x)-f.hmid())<=1and e.y>=f.top()and e.y<=f.bottom())f.climbing,e.spd,f.spd,f.rem.x,f.dash_time={n.rope,d},e.spd+f.spd.x,zvec(),e.x-round(e.x),0return true
end end end local n,e=f.dash_time>0and f.check(boat,sign(f.dash_target_x),sign(f.dash_target_y)),e>0and f.check(boat,0,1)if(n or e and e.bottom()>=rwl)local n=n or e for e in all(split(f.dash_time>0and"x,y"or"y"))do n.spd[e]=mid(n.spd[e]+.25*f.spd[e],-2,e=="y"and 1or 2)end f.spd=zvec()return true
if(btn"5"and not f.p_dash)local e=f.check(pickup)if(not held and e)f.p_dash,held=true,e e.delete()
end}function create_hair(f)f.hair={}for e=1,5do add(f.hair,vector(f.x,f.y))end end function draw_hair(f)local e=vector(f.x+4-(f.flp.x and-2or 3),f.y+(btn(⬇️)and 4or 2.9))for n,f in pairs(f.hair)do f.x+=(e.x-f.x)/1.5f.y+=(e.y+.5-f.y)/1.5circfill(round(f.x),round(f.y),mid(4-n,1,2),8)e=f end end player_spawn={init=function(f)sfx"29"f._spr,f.target,f.state,f.delay,f.djump=3,f.y,0,0,1if rs=="left"do f.spd=vector(1.6,-2)f.y-=8f.x-=24elseif rs=="top"do f.spd.y=1f.y=max(f.y-48,-4)else f.spd.y=-4f.y=f.y+48end if(collect)init_object(fruit,f.x,f.y,collect).follow=true
create_hair(f)move_cam(f,1)end,update=function(f)move_cam(f)if f.state==0do if(f.y<f.target+16)f.state,f.delay=1,3
elseif f.state==1do f.spd.y+=.5if(f.spd.y>0)if f.delay>0do f.spd.y=0f.delay-=1elseif f.y>f.target do f.y,f.spd,f.state,f.delay=f.target,zvec(),2,5f.init_smoke(0,4)sfx"30"end
elseif f.state==2do f.delay-=1f._spr=6if(f.delay<0)f.delete()init_object(player,f.x,f.y,1)
end end,draw=player.draw}stromboli={init=function(f)exec[[fset◆50,0,1]]end,update=function(f)if not f.open do foreach(f.check_all(pickup,1,0),function(e)if(e._spr==13)e.delete()f.open,f._spr=true,51init_object(rigamarole,f.x,f.y)f.init_smoke()exec[[sfx◆11
fset◆50,0]]
end)end end,draw=function(f)draw_spr(f)if(f.open)line(f.x-1,f.y,f.x-1,f.y+7,13)line(f.x,f.y+8,f.x+2,f.y+8)
end}rigamarole={init=function(f)f.hitbox,f.layer,f.seed=rectangle(usplit"0,0,4,8"),10,0end,update=function(f)f.seed+=1end,draw=function(f)if f.player_here()do exec[[camera◆-16,0
rect◆24,32,103,95,0
rectfill◆25,33,102,94,5
line◆25,33,102,33,6
rect◆31,39,96,88,0
line◆63,38,63,89,0
print◆NOOTV,78,89,7]]srand(f.seed\2)for f=32,63do for n=40,87do local e=e()<.667and 10or e()<.5and 1or 0pset(f,n,e)pset(f+32,n,e)end end local function e(f,e)pset(f,e,icanteven and 9or pget(f+33,e))end for f=50,77,27do for n=33,61do e(n,f)end end for f=0,4do for n=0,4do if(bits[1+5*f+n]==1)local f,n=35+5*n,52+5*f for f=f,f+4do for n=n,n+3do e(f,n)end end
end end f.t=min(32767,f.t+.5)dialog={[[2;aww there's no signal...;20;103]],f.t}else f.t=0end end}plat={init=function(f)f.solid,f.ride,f.off,f._y,f.vine=true,true,.5,f.y,init_object(vine,f.x,f.y+8)end,update=function(f)f.off+=.05f.spd=vector(sign(f._spr-41)*.5,sin(f.off)*.5)local n,e=(f.x+16)%160-16,f.vine.rope for d=0,#e do e[d].x+=n-f.x e[d].y=f.y+8+4*d end e[0].x,f.x=n+4,n end,draw=function(f)draw_spr(f)spr(39,f.x,f.y-8)for e=-6,6,12do spr(sin(f.off)>=0and 56or f.y>f._y and 58or 57,f.x+e,f.y-2,1,1,e==-6)end end}thing={init=function(f)for f=1,fruits do local f=init_object(pickup,18+7*f,95,12)f.init_smoke()end if(fruits==10)for f=0,4do for e=0,4do mset(99+2*f,35+2*e,14)end end exec[[memcpy◆0x8000,0,0x2000]]
end,update=function(f)local e=get_player()if not f.done do local e={}foreach(get_objs(pickup),function(f)if(f.is_solid(0,1)and f._spr==12)for n=f.left()\8,f.right()\8do for f=f.top()\8,f.bottom()\8do e[n..","..f]=1end end
end)local n=true for f=0,24do local d,t=f\5,f%5if(bits[1+f]==1and not e[3+2*t..","..2+2*d])n=false
end if(n)for e=0,4do for n=0,4do mset(99+2*e,35+2*n,0)f.init_smoke(24+16*n-f.x,24+16*e-f.y)end end f.t,f.done,quietus=0,true,34exec[[memcpy◆0x8000,0,0x2000
play_music◆-1,500
psfx◆27]]
else f.t+=1if f.t<120do e.freeze,e._spr=32767,3e.move(.1*(63-e.hmid()),.1*(63-e.vmid()))local n=0foreach(get_objs(pickup),function(e)local f,d=n/10+f.t/60,f.t<70and 32or 8if(e._spr==12)e.freeze=32767e.move(.1*(63+d*cos(f)-e.hmid()),.1*(63+d*sin(f)-e.vmid()))n+=1
end)else if(f.t==120)sfx"18"
foreach(get_objs(pickup),function(f)kill_obj(f)end)e.move(0,.1*(-32-e.y))if(e.bottom()<0)fill"22"
end end end,draw=function(f)local e=get_player()if(f.t and f.t>=120)spr(43,e.x-12,e.y-2,4,2)
end}refill={init=function(f)f.offset,f.timer,f.hitbox,f.active=e(),0,rectangle(usplit"-1,-1,10,10"),true end,update=function(f)if f.active do f.offset+=.02local e=f.player_here()if(e and e.djump<1)sfx"31"f.init_smoke()e.djump,f.active,f.timer=1,false,60
elseif f.timer>0do f.timer-=1else sfx"32"f.init_smoke()f.active=true end end,draw=function(f)spr(f.active and 22or 21,f.x,f.y+round(sin(f.offset)))end}_l=fill function fill(f)_l(min(quietus and 26or 21,f))end fruit={init=function(f)f.y_,f.off,f.follow,f.tx,f.ty,f.layer=f.y,0,false,f.x,f.y,.5end,update=function(f)if not f.follow and f.player_here()do f.follow,collect=true,f._spr sfx"12"elseif f.follow do local e=get_player()if e do if e.obj==player_spawn do f.x+=e_appr_delta(f.x,e.x,.2)f.y_+=e_appr_delta(f.y_,e.y-4,.1)if(e.state==2and e.delay==0)init_object(lifeup,f.x,f.y)f.delete()fruits+=1
else f.tx+=e_appr_delta(f.tx,e.x,.4)f.ty+=e_appr_delta(f.ty,e.y,.4)local e=vector(f.x-f.tx,f.y_-f.ty)local n=max(1,mag(e))local d=n>12and.2or.1f.x+=e_appr_delta(f.x,f.tx+12*e.x/n,d)f.y_+=e_appr_delta(f.y_,f.ty+12*e.y/n,d)end end end f.off+=1f.y=round(f.y_+sin(f.off/40)*1.5)end}lifeup={init=function(f)f.spd.y,f.duration=-.25,30sfx"8"end,update=function(f)f.duration-=1if(f.duration<=0)f.delete()
end,draw=function(f)?"1000",f.x-4,f.y-4,7+t()*15%3
end}crumble={init=function(f)f.solid,f.ride=true,true end,update=function(f)local e,n=f.is_solid(0,1),f.check(crumble,0,-1)if not f.t and(f.check(player,0,-1)or f.check(boat,0,-1)or n and n.t)do f.t=f.is_flag(0,1,0)and 0or 15sfx"9"elseif f.t do f.t=max(f.t-1)if(f.t==0)f.spd.y=l_appr(f.spd.y,rwl and f.bottom()>=rwl and 2or 4,.3)
if(e and not f.wog)f.init_smoke(0,4)
end f.wog=e if(f.top()-8>=rh*8)f.delete()
end,draw=function(f)spr(f._spr,f.x+(f.t and f.t>0and e"2"-1or 0),f.y)end}flag={update=function(f)f.spd.y+=.22f.solid=true if(not f.touched and f.player_here())sfx"15"f.touched,ticking=true,false
local e=f.check(pickup,0,0)if(e and e._spr==12)f.red=true kill_obj(e)
end,draw=function(f)draw_spr(f)for e=0,f.touched and 4or 1do camera(-e-f.x,-f.y-(f.touched and-sin(t()+e/5)or 2*e))if(f.red)exec[[pal◆11,8]]
exec[[rectfill◆3,0,3,2,11
pal
pset◆3,0,11
cam_draw]]end if f.touched do if(fruits>10)exec[[spr◆47,60,4]]
exec[[camera◆0,-12
rectfill◆36,-1,90,31,0
rectfill◆35,0,91,30,0
rect◆36,0,90,30,5
draw_time◆41,15
camera◆0,-12
spr◆11,48,20]]cprint("deaths:"..deaths,0,13,7)cprint(":"..(fruits<10and" "or"")..min(10,fruits).."/10",4,22,7)cam_draw()end end}local e,f,d=e,fillp,circfill camp={init=function(f)f.smoke={}end,update=function(f)f._spr=t()*7%4+52if(e()<.25)add(f.smoke,{x=f.x+3,y=f.y-e"2",t=90,m=.25+e"0.75",c=e()<.7and 5or 2})
foreach(f.smoke,function(_ENV)t-=1if(t==0)n(f.smoke,_ENV)
x+=m/6+e"1"-.5y-=m/4end)end,draw=function(e)draw_spr(e)foreach(e.smoke,function(_ENV)if(t<40)f"0b1010010110100101.1"
d(x,y,2*m,c)f()end)end}vine={init=function(f,e)f.rope={[0]=vector(f.x+4,f.y)}for e=1,9do add(f.rope,{x=f.x+4,y=f.y+4*e,spd=0})end end,update=function(f)local e=get_player()foreach(f.rope,function(f)if(e and f.x>=e.left()and f.x<=e.right()and f.y>=e.top()and f.y<=e.bottom())f.spd+=.5*e.spd.x
end)for n,e in ipairs(f.rope)do local d=-.15*abs(e.spd)*e.spd for n=n-1,min(#f.rope,n+1),2do local f=vector(f.rope[n].x-e.x,f.rope[n].y-e.y)d+=(1-2/mag(f))*f.x end e.spd*=.93334e.spd+=d/2e.y=f.y+4*n end foreach(f.rope,function(f)f.x+=f.spd end)end,draw=function(e)for n=1,#e.rope do local e,n=e.rope[n-1],e.rope[n]f"0b1111111100001111"line(round(e.x),e.y,round(n.x),n.y,59)f()end end}pickup={init=function(f)f.rider,f.solid,f.layer,f.hitbox,f.particles=true,true,2,rectangle(usplit"1,3,6,5"),{duration=5}end,update=function(f)local n=f.is_solid(0,1)if(not n)f.spd.y=l_appr(f.spd.y,4,.22)
f.spd.x=l_appr(f.spd.x,0,n and 1or.1)if(f.top()>=rh*8)f.delete()
if f.lethal do make_particles(f.particles,f.hmid()+e"4"-2,f.vmid()+e"4"-2,zvec(),8,2)local e=f.player_here()or f.check(pickup,0,0)if(e)kill_obj(e)
if(n)f.init_smoke()f.lethal,f._spr=false,12
end update_particles(f.particles)end,draw=function(f)draw_particles(f.particles)draw_spr(f)end}chest={init=function(f)f.ox=f.x end,update=function(f)if not f.t do foreach(f.check_all(pickup,0,0),function(e)if(e._spr==24)e.delete()f.t=15sfx"11"
end)else f.x=f.ox+e"2"-1f.t-=1if(f.t==0)init_object(fruit,f.ox,f.y-8,11)f.init_smoke()f.delete()
end end}boat={init=function(f)f.layer,f.ride,f.solid,f.hitbox=0,true,true,rectangle(usplit"0,2,16,6")end,update=function(f)local e=rwl and f.bottom()>=rwl f.spd=vector(l_appr(f.spd.x,0,e and.05or.15),e and l_appr(f.spd.y,e_appr_delta(f.y,rwl-6,.1),f.y>rwl and 1or.15)or l_appr(f.spd.y,3,.22))end,draw=function(f)spr(32,f.x,f.y,2,1)end}fish={init=function(f)f.y+=8f.flp.y,f.v,f.solid,f.rider,f.hitbox=true,0,true,true,rectangle(usplit"1,1,6,6")end,update=function(f)local n,e,o=f.top()<rwl,get_obj(fruit),f.is_solid(0,1)local d=e and vector(e.x-f.x,e.y_-f.y)local t=d and mag(d)if(not e or e.y_<60or t>=60or n)f.v=l_appr(f.v,0,o and.2or.1)f.spd.y=n and l_appr(f.spd.y,4,.22)or f.y<128and.5or 0else f.v=l_appr(f.v,5,.05)f.spd.y+=e_appr_delta(f.spd.y,f.v*d.y/t,.05)
f.spd.x+=e_appr_delta(f.spd.x,t and f.v*d.x/t or 0,.1)if(n and not f.wd)f.spd.y=-2
f.wd=n local e=f.player_here()or f.check(fruit,0,0)if(e)collect=nil kill_obj(e)
if(f.v<.5and o)f.delete()f.init_smoke()local e=init_object(pickup,f.x,f.y-1,34)e.spd.y,e.flp.x=-1,f.flp.x
if(f.spd.x~=0)f.flp.x=f.spd.x<0
end}fwall={init=function(f)f.particles={grav=.22,duration=60}end,update=function(f)if f.collideable do f.hitbox=rectangle(usplit"-2,-2,28,12")local n=f.player_here()if(n and n.dash_time>0)sfx"9"for n=0,16,8do f.init_smoke(n)for d=1,4do make_particles(f.particles,f.x+n+e"8",f.y+e"8",vector(e"2"-1,-1-e"0.5"),5,2)end end f.collideable,cam_lock=false,false
f.hitbox=rectangle(usplit"0,0,24,8")end update_particles(f.particles)end,draw=function(f)if(f.collideable)camera(-f.x,cam_y-f.y)exec[[spr◆127,0,0
spr◆127,8,0
spr◆127,16,0
cam_draw]]
draw_particles(f.particles)end}adelie={update=function(f)f.hitbox=rectangle(usplit"-4,0,12,8")foreach(f.check_all(pickup,0,0),function(e)if(e._spr==34)sfx"22"e.init_smoke()e.delete()init_object(fruit,f.x,f.y-8,11)f._spr,f.t=49,0
end)end,draw=function(f)draw_spr(f)if(f.player_here())f.t=min(32767,f.t+.5)dialog={f._spr==49and"1;noot noot! ♥;20◆3;:madepog:;20"or"0;noot noot? noot noot...;20◆2;aww...;20",f.t}else f.t=0
cam_draw()end}monument={draw=function(f)f.hitbox=rectangle(usplit"0,0,16,16")if(f.player_here())f.t=min(32767,f.t+.5)dialog={[[2;"THIS MONUMENT WAS PUT
UP 3.5 YEARS AGO...";20;4◆2;"...THEN MEEP FORGOR.";20;4◆2;cool!;20;4]],f.t}else f.t=0
camera(cam_x-f.x,cam_y-f.y)exec[[spr◆91,0,0,2,2
spr◆93,12,0
spr◆93,-4,0,1,1,1
cam_draw]]end}npc={update=function(f)f.spd.x=1f._spr=35+6*t()%3if(f.left()>=8*rw)f.delete()
end}soil={update=function(f)local f=f.check(pickup,0,-1)if(f and f._spr==15)f.delete()f=init_object(fruit,f.x,f.y,47)f.follow,collect=true,47
end}meepisms=split([[you're one in a melon.◆it takes two to mango.◆we would've made a great 
pear.◆want a peach of me?◆not very a-peel-ing.◆so un-raisin-able.◆orange you selfish.◆my fruits are berry 
special.◆guava nice day.◆i juice can't even.◆this is fine(apple).◆you're coco-nuts.◆don't be des-pear-ate.◆well we're in a jam.◆squeeze the day.◆this is fruit-ile.◆you didn't ask for 
persimmon.◆fruit flies like a 
banana.◆practice what you peach.◆you won't live apple-y 
ever after.◆don't take it for 
pome-granted.◆i'll de-cider your fate.◆don't blink durian your 
defeat.◆pre-pear for trouble.◆you don't know jack-
fruit.◆how melon-cholic.◆got any grapes?]],"◆")patooty={init=function(f)f.t,f.m,f._spr,f.flp.x,f.hitbox,f.solid,f.state,f.health=stfu and 9.5or 0,1+flr(e(#meepisms)),35,true,rectangle(usplit"1,3,6,5"),true,"idle",3end,update=function(f)if(stfu)exec[[play_music◆26,0,0b11]]
local n=get_player()if(f.state~="dying"and f.player_here())kill_obj(n)
if(n and n.obj==player_spawn)return
f.t+=.5if not stfu do n.freeze=32767dialog={[[4;why do you keep taking 
my fruits!?;20;4◆2;i'm running hundo...;20;4]].."◆4;"..meepisms[f.m]..";20;4",f.t}if(f.t>136)stfu,f.t,n.freeze=true,9.5,0
return end local d=f.is_solid(0,1)f._spr=d and 35+(f.spd.x<0and 6*t()%3or 0)or 37if(f.state~="iceman")f.spd.y+=.33
if f.state=="dying"do if(e()<.5)f.x=112+e"2"-1
if(e()<.03)sfx"19"f.init_smoke()
dialog={[[4;fine, keep the fruits...
'twas grape knowing you.;20;4◆2;why are you like this?;20;4◆4;3.5 years of neglect...;20;4◆4;i'm not...;20;4◆4;from concentrate!!!;20;4]],f.t}if(f.t>225)init_object(flag,56,96,63).init_smoke()kill_obj(f)play_music(63,1000)
return end if(f.state~="hit"and not get_obj(pickup)and n and n.x>=88)f.state,f.spd.y="fruity",max(f.spd.y)
local n=f.check(pickup,0,0)if n and not n.lethal do kill_obj(n)if(mag(n.spd)>.01)sfx"19"f.state,f.t,f.spd.y="hit",0,-1f.health-=1if(f.health==0)music"-1"f.state,f.t="dying",0
end if f.state=="idle"do f.spd.x=.25*(112-f.x)if(f.t==10)f.t,f.state,f.q=0,"iceman",perm(split"0,0,0,0,1,1,2,2,3,3,4,4")
elseif f.state=="iceman"do if#f.q>0do f.spd.y=.4*(96-8*f.q[1]-f.y)if(f.t%6==0)sfx"18"init_object(pew,f.x,f.y).spd.x=-3deli(f.q,1)
else f.state,f.t="idle",0end elseif f.state=="fruity"do if d do if(f.x>88)f.spd.x=-2else f.spd=vector(1,-2-e(3))
elseif f.spd.x>0and f.spd.y>-2do sfx"26"local e=init_object(pickup,f.x,f.y,38)e.lethal,e.spd=true,vector(-4,-2)f.state,f.t="idle",0end elseif f.state=="hit"do if(f.t==10)f.state,f.t="idle",0
end end,draw=function(f)if(f.state=="hit"and f.t\1%2==0)return
draw_spr(f)end}pew={update=function(f)local e=f.player_here()if(e)kill_obj(e)
f.hitbox=rectangle(usplit"1,1,6,6")if(f.right()<0)f.delete()
end}tiles={}foreach(split([[1,player_spawn
10,vine
12,pickup
13,pickup
15,pickup
27,camp
22,refill
23,crumble
24,pickup
25,chest
26,thing
32,boat
34,fish
35,npc
37,patooty
40,plat
41,plat
42,plat
48,adelie
50,stromboli
11,fruit
63,flag
91,monument
94,soil
127,fwall]],"\n"),function(f)local f,e=usplit(f)tiles[f]=e end)bits={}for f=0,24do add(bits,f<10and 1or 0)end bits=perm(bits)function init_object(f,d,o,i)local f={obj=f,_spr=i,hitbox=rectangle(usplit"0,0,8,8"),x=d,y=o,rem=zvec(),spd=zvec(),flp=vector(),freeze=0,layer=0,collideable=true,solid=false,init=f.init or t,update=f.update or t,draw=f.draw or draw_spr,on_move=f.on_move}function f.left()return f.x+f.hitbox.x end function f.right()return f.left()+f.hitbox.w-1end function f.top()return f.y+f.hitbox.y end function f.bottom()return f.top()+f.hitbox.h-1end function f.hmid()return round(f.left()+f.right()>>1)end function f.vmid()return round(f.top()+f.bottom()>>1)end function f.is_flag(e,n,d)local t,o,i,a=f.left(),f.right(),f.top(),f.bottom()for e=mid(0,rw-1,(t+e)\8),mid(0,rw-1,(o+e)\8)do for n=mid(0,rh-1,(i+n)\8),mid(0,rh-1,(a+n)\8)do local e=tile_at(e,n)if d=="spike"do if(({[17]=f.spd.y>=0and a%8>=5,[18]=f.spd.y<=0and i%8<=2,[19]=f.spd.x<=0and t%8<=2,[20]=f.spd.x>=0and o%8>=5})[e])return true
elseif fget(e,d)do return true end end end end function f.overlaps(e,n,d)return e.right()>=f.left()+n and e.bottom()>=f.top()+d and e.left()<=f.right()+n and e.top()<=f.bottom()+d end function f.check_all(n,d,t,e)return filter(e or objects,function(e)return e.obj==n and e~=f and e.collideable and f.overlaps(e,d or 0,t or 0)end)end function f.check(...)return f.check_all(...)[1]end function f.player_here()return f.check(player,0,0)end function f.is_solid(e,n)return not f.climbing and n>0and not f.is_flag(e,0,2)and f.is_flag(e,n,2)or f.is_flag(e,n,0)or f.check(crumble,e,n)or f.check(boat,e,n)or f.check(fwall,e,n)or f.check(plat,e,n)end function f.oob(e,n)return f.left()+e<0or re&2==0and f.right()+e>=8*rw or re&1==0and f.bottom()+24+n<0end function f.not_free(e,n)if(f.obj==plat)return false
return f.obj~=plat and(f.oob(e,n)or f.is_solid(e,n))end function f.move(n,d)for e in all{"x","y"}do f.rem[e]+=e=="x"and n or d local n=flr(f.rem[e]+.5)f.rem[e]-=n if f.solid do local d=sign(n)local t=e=="x"and d or 0local o=d-t for n=1,abs(n)do if(f.on_move and f:on_move(t,o))return
if f.not_free(t,o)do f.rem[e],f.spd[e]=0,0 break else f[e]+=d if f.ride do foreach(filter(objects,function(e)return e.rider and(f.overlaps(e,0,0)or f.overlaps(e,-t,-o-1))end),function(n)if n.not_free(t,o)do n.rem[e],n.spd[e]=0,0else if(o>0and n.spd[e]==0)n.spd[e]=.5*f.spd[e]
n[e]+=d end if(n.not_free(0,0))if(f.obj==boat)f[e]-=d f.spd[e]=0else kill_obj(n)
end)end end end else f[e]+=n end end end function f.delete()n(objects,f)end function f.init_smoke(n,d)add(smoke,{x=f.x+(n or 0)-1+e"2",y=f.y+(d or 0)-1+e"2",spd=vector(.3+e"0.2",-.1),flp=vector(e()<.5,e()<.5),_spr=29})end f:init()f.w=rwl and f.bottom()>=rwl+2return add(objects,f)end function kill_obj(f)f.delete()if f.obj==pickup or f.obj==fruit do f.init_smoke()return elseif f.obj==player do delay_restart=15deaths+=1end psfx"20"for e=0,.875,.125do add(dead_particles,{x=f.x+4,y=f.y+4,k=2,dx=sin(e)*3,dy=cos(e)*3})end end function load_gfx(n,f)local e=0for n=1,#f,2do for d=1,("0x"..f[n])+1do sset(e%128,e\128,"0x"..f[n+1])e+=1end end memcpy(32768+8192*n,0,8192)reload()end function ssload(f)memcpy(0,32768+8192*f,8192)end exec[[memcpy◆0x8000,0,0x2000
load_gfx◆1,f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f06001400ef0f0f001f06001f0f0e011ae01f0f0900e4001f00001f0f0c0fe2ef0f0600e4001800120011011f0f0b0fe4ef0a001900e30118001200e1011f0f09001fe6ef09001801e30216011200e0021f0f080fe8ef09011701e30216011200e00313001f0f010fe9e000e200ef030113001201e1001002120012011101e003100011001f0f021fe7e017e01f000212001201e1001002120012021001e0031000e0011f05001400e005e01fefe1ee0212001201e010041100e012021001e0031000e0011f040212001fefebed00e211001202e0041100e111021002e00310e0021f0203e11fefeded00e210011202e0041101e010031002e00211e0021f0006e01fefeeec00e51202e0041101e0100412e00211e31f001fefefe6eb01e51103e1041002e00412e00211e31d021fefefe6eb02e41103e1041002e512e00212e21c001fefefe8e01b02e41103e1041002e513e212e21c04e01fe5e01feeea02e41104e0041002e513e212e11c0fefefede902e41005e51002e513e00112e11a0fefe01be01fe1e902e515e51003e413e00112e11c0fede01be02fe2e802e515e514e413e212e01c0fefebe02fe1e903e415e514e314e213eb0fefe01be12fe0e903e415e514e314e213ea0fefe0e01ae011201de01a03e416e010e115e010e114e213e90fefe0e219e420e019e11b02e210e016e010e115e010e114e010e013e7011fefe417e0132ae014e902e210e018e016e010e01ce5041feee417e22fe3e803e011e01fe0e01ee6051fe9e010e616e22fe3e01706e01fefe0e5051febe01025112011e010e0102fe5e80fefe6e015041fede1211326e01fe5e80fefe6e015051fece62fefe70fefe6e0160418e01fe3e42fefe8001fefe4e117011fefe0e2201fefef0f0f08001be01be010e114e22fefe0ef06031503ef040ae111e01be01221e22fefe1ef020819ef0209e41de72fefe2ef000713e011e212ef01001be11ee0152ae01fe5ef00071ae012ef010be010e01fe42016e11fe6ef010611e11bef000be01fe2e01421142fe7e01f010014e011e0102019e31c0fefe1e9201fe0e016ef07e013e12017e51d0fefe7211fe5e11f0006e016e313e81d0feee521001fe2e013ef0006e018ef101c0feee4230fe2e111ef010fe0e02f1d0fece014220fe3ef0504e01aef101e001febe423001fe1ef040113e019e010ee1f00021fe7e014240fe0ef04031fed1f02021fe5e114250fe0ef020814e0120021e00514e01f04021fe4e0100426001cef040f110127e115ef00041ee014e104280aef050f10100022e106e014ef00021fe1e110e01104290017ef070c100212e109e013ef00001fe6e1042c0012e000ef080a120011e020011eef00001fe6e010042f0f0e04150011e31be011ef010fe7e0142f0f0f080110e0241cef02001fe6e0142f0f0f070111e0251aef050fe5e0142f0f0f060214e614ef090fe5e42f0f0e041104e016e71f0a07e113e014e0142f0f0a0916e016e61f0908e415e1142f0f09091fe0e41f0b08e01027e1042f0f080a18e016e31f0c0018e01125e1042f0f080a18e016e21f0e0ae123e2042f0f080b17e015ef0f030ae221e2042f0f090b1cef0f050ae223042f0f0a0c100024ef0f0805e015e321042f0f0e0414042f0f0b0be92f0f0f0f0f0f090012e016e0092f0f0f0f0f0f090010e116e1082f0f0f08002f0f0f030013e014062f0f0f07012f0f0f0e062f0f0f020211e12f0f0f0f052f0f0f000313e01f0f0f0f052f0f0f020016ef0f0f0e052f0f0f0015e01022ef0f0f0d052f0f0f07e01020001f0f0f0d052f0f0f000017e02f0f0f0d062f0f0e0015e004ef0f0f0c062f0f0e07e00021e01f0f0f0c062f0f0f08e02000220316e11f0f0c062f0f0e0014e003e010221de01f0f0a062f0f0e06e00021e010001ae100ef0f0d062f0f0f06e22105e001e002ef0f0f062f0f0e0012e201e0102102e001e001e100ef0f0f00062f0f0f03e011022102e001e101ef0f0f02062f0f0f0013e102210120e002e00010ef0f0f02062f0f0f0010e403210020100011ef0f0f05062f0f0f00150321002f0f0f0a062f0f0f05042100221f0f0f07062f0f0f0603200011231f0f0f05062f0f0f06032210211f0f0f07072f0f0f0300100322102f0f0f09072f0f0f0000110112e121102f0f0f09072f0f0f0315e021012f0f0f08072f0f0d00110012e003e022002f0f0f08072f0f0d0214e00120e022012f0f0f07072f0f0e0017e22300200011e21f0f0f082f0f0b0010e003e004e22206e21f0f0d082f0f0b0016e102e22105ef0f0f02082f0f0a001007e100e32006e000e31f0f0c082f0f0905e103e10324e005e21f0f0b082f0f080012e101e100e30322e00024ef0f0f00082f0f0800e001e01101e60221e101e001e101e01f0f0c082f0f08001b0520102002e105e01f0f0b082f0f0f02031622e024ef0f0f092f0f0f0204132011e00027e11f0f090a2f0f0f0403122010e103e002ef0f0c0a2f0f0f08042002e102e100e01f0f090a2f0f0f080422e00021e003ef0f0a0a2f0f0f0604112010e002e001ef0f0d0a2f0f0f030010e103122101e004e01f0f0a0a2f0f0f020013e0100020e011200010e121e002ef0f090b2f0f0f0405e323001200ef0f0b0c2f0f0f000010e106e222002102e01f0f090c2f0f0f0006e100e322002100e000e01f0f090c2f0f0f0205e005210024001f0f090c2f0f0f00001102e002e421002f0f0e0e2f0f0f05e101e420002f0f0f0e2f0f0f0005e204200021022f0f0a0e2f0f0e00e101e101e2092f0f0a0f202f0f0d04e503152f0f0b0f202f0f0d01e800e2152f0f0b0f212f0f0f05001001e62f0f0b0f222f0f0f0504e52f0f0b0f232f0f0f0402e021e42f0f0a0f252f0f0f0200e002e020132f0f0b0f272f0f0f0002e010e52f0f0b0f292f0f0e02e1052f0f0a0f2b2f0f0d00e4042f0f0a0f2e2f0f090010e013052f0f080f2f202f0f0f052c0
load_gfx◆2,f2f20004091d390430120004091d3904304220030b0e031b030012f0f0f0f2f204071d09144914000204071d091449140022001d281e2b0012f0f0f0f2f21d590458001d590458000200580e18030b0012f0f0f0f2f229149800291498100809a80002f0f0f012806280320004980d3804980d5819a8f0f0f0200a610a1022100a610a10020001580d080dc80d080d7809380d88f0f0f00aa10a00120aa10a00110d280d080408040d0804180d080d280d080408040d0804180d380d0802141d58f0f0f0c10a0002c10a11280d2f080f180f180d380d2f080f180f180d48021f060f041d280df0f0f05117211701000251172117010a01080d040f06012f080601181d080d040f06072f080607181d080d181f17011f043df0f0f051172117010a0051172117010a011d0f17111f0d0701084d0f27011f0d0701082d080d18040f07111f0701041df0f0f0311c11490c0100714921080d1f272f170f1d00080d1f17012f07010f1d00180d18043f092ff0f0f010311c11490c0100714921080d0f094f091f091d00080d0f095f040f091d00280d040f095f090002f0f0f051064706110051064706110a080d042f045f1d00080d043f21041f1d00582f141f0d0002f0f0f0410667060100410667060100080d142f142f141d080d142f112f141d000d48042f2d08f0f0f00041870100418701001819143f1409041d1819140f110f1409041d02001d18240d002d0002f0f0f0418701004187010008140917340917140d08140917340917140d0200131b042f1b030012f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
load_gfx◆3,0095f0a05550356005f0f0f0f040a5f040b51075f0f0f0f0b0152075f00095f0f0f0f0f0c065f0f090010001f0f0f0f0f0f0f0d001f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f05021a0311031f0f0f0f0f0f08021a061f0f0f0f0f0f0b05130d1f0f0f0f0f0f04071601103000110319001f0f0f0f0f07003011051700100010001100100039021f0f0f0f0f05023110003000100116001031001300140310041f0f0f0f0f03003012300010011100110033001100130036081f0f0f0f0f0203301200103101113600130016003b1f0f0f0f0d00113022300211301020300213011503100010081f0f0f0f0e0210302233113010201002130411051100110310003f0f0f0f0e041030213211321034110510061000100410001f0f0f0f07006206102b11301031110f151f0f0f0f0e0b13331331100411302110391f0f0f0f0f0b13311030103111341130213111391f0f0f0f0c026233156110203110301020361033133112641f0f0f0f0500610010036232176210641039143260316412006f0f0f0f04011102351861116911311131116131641f0f0f0f06041006301021146435601062103311301063316030116f0f0f0f08002011053311336730671032103311301161336f0f0f0f05011f311330143010c010c010c010c0331234123461006f0f0f0f000311301231173013301430c010c010c010c010c91021133f0f0f0f080511311230173111311132c070c070c078143010311f0f0f0f070a1131163010213211300270c2791230103011201f0f0f0f040210211022102510310230102210211105c1102210261020342f0f0f0f03001021130110211021110171003511017002c200102210241021122010201f0f0f0f02011021037201102010057101102010047000c0027108102411211f0f0f0e006101100871001001657063006370607001637000100011001020130110022f0f0f0f0401716675657362716000c002627000700060720161710060002f0f0f0f0003756400706102710174017601640171017061027f0f0f0f0205746004310132013104310631043101300070013f0f0f0f050167700630023002300630063006300231013f0f0f0f0a0371013201300630013201350130013201300330013f0f0f0f0f00061006100611041101120110061f0f0f0f0f0001120110011000100110011201100115011201100110031f0f0f0f0f00011201100112011001120110051106100111021f0f0f0f0f00011201100112011001120110061104110112011f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f09009f070171317f0f0f0f0f0f02009f060071807f0f0f0f0f0f030090009f05018f0f0f0f0f0f060090009f019f0f0f0f0f0f0a00900496069f0f0f0f0f0f0c0f909f0f0f0f0f0f0f010a9f0f0]]function draw_plant(f,e,n,d)local f,t,o=usplit(split([[0,10,16 10,6,4 74,6,4 138,6,8]]," ")[f])spr(f,e,n,t,o,d)end function draw_tree(n,f)srand(n)local o=f-e"16"for f=1,10do for t=1,2+e(f)do d(round(-cam_x/4)+n+2*e(f)-f,o,e"3.5",1)end o+=2+e"3"end srand(t())end function title_init()start_game_flash,_update,_draw=nil,title_update,title_draw music"63"end function title_update()if start_game_flash do start_game_flash-=1if(start_game_flash<=-30)begin_game()
elseif btn"4"or btn"5"do start_game_flash=50exec[[play_music◆-1,2000
sfx◆13]]end end function title_draw()exec[[pal
cls
ssload◆3]]if(start_game_flash)local f=start_game_flash>10and(30*t()%10<5and 7or 10)or(start_game_flash>5and 2or start_game_flash>0and 1or 0)if(f<10)for e=1,15do pal(e,f)end
exec[[draw_birbs
fillp◆0b0000010100001010.1
draw_tree◆8,40
draw_tree◆24,40
draw_tree◆104,48
draw_tree◆120,48
sspr◆0,0,67,52,30,16
print◆🅾️+❎,54,72,14
print◆maddy thorson,38,84,1
print◆noel berry,44,90,1
print◆mod by meep,42,104,14
print◆music by rubyred,32,110,14
pal◆11,139,1
pal◆13,132,1
pal◆2,130,1
pal◆14,131,1
pal◆10,129,1]]end
__gfx__
00000000000000000000000008888880000000000000000000000000000000000888888008888880000bb0000300b0b000000000000000002999999200000000
00b7b700088888800888888088888888088888800888880000000000088888808888888888888888000b0000003b3300000000000003b3004444444400000000
0b7b7000888888888888888888888ff88888888888888880088888808881ff188888888888888888000bb0000288882000b03b0000030b000222222000b03b00
b7b7000088888ff888888ff888f1ff1888888ff8888ff8808888888888fffff888888f1088888f100000bb0008988880000330000003b3000000000000033000
b7b7000088f1ff1888f1ff1808fffff088f1ff1881ff1f8088888ff888fffff888888ff088888ff000000b0008888980008889000000e0000000000000888800
0b7b700008fffff008fffff00049990008fffff00fffff8088fffff80849998088889900888899000000bb000889888000988800000330000000000000888800
00b7b700004999000049990007000070074999000049997008f1ff10004999000888070008887000000bb00002888820008898000000b0000000000000888800
00000000007007000070007000000000000007000000700007799970007007000000000000000000000b00000028820000088000000330000000000000077000
0000000000000000fffefffeee00000000000fff0007700000077000577777750000000000000000000000000000000000009000000000000000000070000000
0000000000000000f7fef7feff7000000007777f00700700007bb700663b66360000000000000000000880900000080000800000007700000770070007000007
0000000000000000f770f770f7777000000007ff0700007007bbb370656666660000000004444440008980008080000009889880007770700777000000000000
000000000070007007000700fff00000000000ee700000077bbb3bb76666666600000000499ffff4088880800089880000889880077777700770000000000000
000000000070007007000700ee00000000000fff7000000773b33bb7666366560000000049fffff4089988800089990008899800077777700000700000000000
000000000f770f7700000000ff7000000007777f0700007007333370666b33667770000044444444089998000099980000899800077777700000077000000000
00994900ef7fef7f00000000f7777000000007ff0070070000733700156663616067777749fddff40d9998d00d8992d00d8882d0070777000007077007000070
04442440efffefff00000000fff00000000000ee0007700000077000015666106660060649fffff40d2d2dd00d2d2dd00d2d2dd0000000007000000000000000
000000000000000000000000000b0300000b0300000b03000000000000000000aeeeeeeaaeeeeeeaaeeeeeea000000000000000000000000000000000300b0b0
0000000000000000000000000888388008883880088838800000000000000000e111111ee111111ee111111e00000000000000000000000000000000003b3300
ddd4dd4dd4dd4ddd000d888089888888898888888988888808980b0000000000e111111ee111111ee111111e0000000000000000000000000000000002888820
4444444444444444e0eee888888fff88888fff88888fff888888300000000000e111111ee111111ee111111e0000000000000000000000000000000008888880
4444444444444444eeeeeea788f1ff1088f1ff1088f1ff108988330000700700e111111ee111111ee111111e0000000000000000000000000000000008888880
0444444444444440e0eeeeee088ffff8088ffff8088ffff808890b0000700700e111111ee111111ee111111e0000000000000000000000000000000008888880
00dddddddddddd00000eeee0003bbb00003bbb00073bbb00000000000f77f770e111111ee111111ee111111e0000000000003003b03b00000000000000777700
000022222222000000111000007007000007600000000070000000000f7ff7f0aeeeeeeaaeeeeeeaaeeeeeea00007777770003bb33b000777777000000077000
0000000e0000000e444d666600000000000000000000000000009000000000000000000000000000000000000000077667700888888007766770000000200000
000000ee000000ee4445565506060000000880900000080000800000000090000007777700000000000000000000007777678888889876777700000000200000
001111ee101111e14445a6a500600000008980008080000009889880000080000077667000000000000000000000000766778988888877667000000000400000
0171711e1171711144d53ba525550000088880800089880000889880008089000767770000000000000000000000000777668888988866777000000000400000
0c991c1e119911114466bbb65aa10000089988800089990008899800008998000776600007777700000000000000000076708888888807670000000000400000
117771110177711e44655a555aa10000089998000099980000899800008998000777700007777670077000000000000000008898889800000000000000400000
197791110977911e44655aa55aa100000d9998d00d8992d00d8882d00d8898d00000000000000077007777700000000000000888888000000000000000400000
e966911ee966911e44d35535255500000d2d2dd00d2d2dd00d2d2dd00d2d2dd00000000000000000000777770000000000000088980000000000000000400000
13bbb3b33bb3bbb3bb3b3b311bb3bbb14444444444444444444444444444443300000000000000000000000000000000030000030030330000000000b6666666
333333333333333333333333333333334444444444444444444444444444441300000000000bbbb000000000003bb0000b00000300300b000000000055555655
33333333333333333333333333333333444d4dddd4d444dddd4d4444444344330000000000bbbbbb033000000b000b0003b00003000000000000000055555655
333333333333333333333333333333334444ddddddddddddddd4d4444441333300000000003bbbb603330bb00b000b00033b000300000000003b3b0033553b55
3333331111333331133113333133333344dddddddddddddddddddd44444411330000b0000036e6e3bb333bb30300300003030330000000000b3833b06666bbb6
33111144441111144114413334111113444dddddddddddddddddd444444444330003000000033330bbb3bb330030000003033300000000000333383055655555
3344444444444444444444133444444344d4dddddddddddddddddd444444433303030b0030330000003bb300000b0000b3000000000000000b83b33055655555
3144444444444444444444433444444344dddddddddddddddddddd44444441130333330333330300000330000003b0b003000000000000000033830055b35535
34444444444444444444444334444443444ddddddddddddddddddd443344444400dd4d003333333333333333000050055055000000000000331d2d2d444d6666
3444444444444444444444433444444344ddddddddddddddddddd4443144444400dd4d003b3bb3333b3bb333000005555550000000777777331ddddd44455655
33444444444444444444443333444433444dddddddddddddddddd4443344444400dddd00bb1b3bb3bb2b3bb3000006666660000007766770314ddddd44455655
33444444444444444444443333444433444ddddddddddddddddddd443333444400dd4d00b10b11b3b12b22b30000666666760000767777001444d4d444d53b55
3344444444444444444444333344443344ddddddddddddddddddd4443313444400dddd001001001110222211000067666666000077667000444444444466bbb6
33444444444444444444443333444433444ddddddddddddddddddd443341444400dddd00000000000002dddd00006666766600006677700044444d4444655555
31444444444444444444441331444413444ddddddddddddddddd4d443134444400dd4d00000000000000d4dd0000666666660000076700004444444444655555
3444444444444444444444433444444344ddddddddddddddddddd4443314444400dd4d0000000000000000d40000667666760000000000004444444444d35535
3444444444444444444444433444444344dddddddddddddddddddd444444444400dd4d00000e00003333333300000666666000000000000022dd2dd2b6666d44
34444444444444444444444334444443444ddddddddddddddddddd444444444400dddd00e0dee0003b3bb333000000667600000000000000dddddddd55555644
3444444444444444444444433444444344ddddddddddddddddddd4444444444400dd4d000d000000bb2b3bb35777777777777775000000004ddddddd55555644
34444444444444444444444334444443444ddddddddddddddddddd444443444400ddddddde000000b12b22b3656366565656666600000000d4d4d4d433553bd4
34444444444444444444444334444443444d4ddddddddddddddd44444441344400dd4dd00000000012222211555b65566566653600000000dd44dd4d6666bbb4
334444444444444444444433334344334444444d4d4d444d4d44d444434434440ddd4d0000000000dddd2000355656665653666600000000d444d4d455655544
333333444433334444333333333333334444444444444444444444444133334300dd4d0000000000dd4d0000655655366536555600000000dddddddd55655544
133333333333333333333335133333314444444444444444444444443333333300dddd00000000004d000000666663b666666b360b0b00302d2d22d255b35d44
13bbb3b33bb3bbb3bb3b3b311bb3bbb144444444dddddddd444444444444444400dd4d00033333333333333333333330000000000000000000022000b6666666
3333333333333333333333333333333344444444dddddddd444444444444444400dddd00bb33b3bb3b3bb333b3bb33bb00b00b00000000000002200055255655
3333333333333333333333333333333344664444dd66dddd44d44dd44433334400dd4d00b33bb3bbbb2b3bb3bb3bb33b0030030000300300000d200055525652
3333333333333333333333333333333344664444dd66dddd444dd4444333333400dd4d00311b31b1b12b22b3b111b13b03b0b000003000b0000dd00033553b55
3333331111333331133113333133333344444444dddddddd444444444131331400dddd001001101010222211100010110300300000300030000dd0006666bbb6
3311114444111114411441333411111344444464dddddd6d4dd44d444414134400dddd0000000000002dd200000000000b00330000030b00000dd00055655555
3333334444333344443333333344443344644444dd6ddddd444dd4444444414402dddd000000000000dd4d000000000000300b0000b303000032d0b055655255
1333333333333333333333311333333144444444dddddddd44444444444444442ddd2dd00000000000dd4d0000000000003003000030030000b3233052b32535
55555555555557555556565656565555000000000000000000000075474555550000000000000000000000000000751500000000000075250000000075465666
2500000000064715455555555555555700020000000000000000000000000000a100000000000000000000000000000555652500000000000000000000000000
575556565656565666771547156746550000000000000000000000f6154655570000000000000000000000000000057700000000000005740000000005151547
7400000000c405774656555755555555001000000000000000000000000000009400000000000000000000000000000556662600000000000000000000000000
556615151567154715151676161577450000000000000000000000f67767465500000000000000000000000084e475150010b400008475260000000075677676
260000020000751547154656555555550000000000000000000091d7000000a4240000000000000000000000000000f67726c400000000000000000000000000
66154716767616167626d4c4007515450000000000000000000000061647771500000000000000000000b484041415441414240000042500000097a50626d4d4
a000000097a50616166777154555575584a484c7000000008404142484a48404250000000000000000000000000000f626a00000000000000000000000000000
67772600d400d400a0000000000547450000000000000000000000a0c406151500000000000000000000041415154745157774000075260000000000d4000000
00000000000021212106151545555555141414273100000007157747141414157400000000000000000000000000000500000000000000000000000000000000
1525c40000000000000000009175154500000000000000001100000000d4f66700000000000000000000756747151545477626004135d4000000000000000000
000000000000000000217547455555556747743100000000d406761676764715f500000000000000000000000000041500000000000000000000000000000000
472600000000000000000000041577450000000000000041373100000000f64700000000000000000000f6771676674626d4a000413600000000000000000000
0000000000000000000075154555575564152531000011000000d40000c40667f400000000000000000000000000057700000000000000000000000000000000
25d40000000000000000000075154455000000e484000000210000000000f61500000000000000000000f62600c40615c4000000000000000000000000000000
000000000000000000000515465656566647743100413431000000000000d405f500000000000000000000000000f41500000000000000000000000000000000
741111110000000000000000f6474555111111042431000000000000000075770000000000000000000035d40000d47500000000000000000000000000000000
0000000000111100000075774767154715772631004135310000001100000005f500000000000000000000000000f41500000000000000000000000000000000
151414240000000011111171f615465714141467253100000000000000000676100000000000000000003600000000f600000000000000000000000000000000
0000000000042700000006761616767615263100004135310000003431000075f500000000000000000000000000f61500000000000000000000000000000000
47156725110000000414240006771545774715157431000000000000001100c4240000000000000000002102000000f600000000000000000000000000000000
0000000000350000000021212121212125f4310000413511111111353100007574000000000000000000000000000544a7b700000000840000b100f300840000
157715472400000075772600c4051545545464777431000000000000413731007400000000000000000000000000007500000000000000000000000000000000
0000000000360000000000000000000074d400000011061717171726000000052600000000000000000000000004474585000000041414141414141414240000
1515151574a6b7a50626d40000756745575565152531000000610000002100002500c70000000000000000000000a40500000000000000000000000000000000
00000000002100000000000000000000740000004137d4d4000000000000a475c4000000000000000000000000754455869600a4061647151515156715151414
6716761626000000a000000000061546555566477431000000000000000000004714240000d70000000000c70000041500000000000000000000b00000000000
000000000000000000001111111111112581000000000000000000000084044700000084000000b4840000000005455587108404142405445454545454647715
26d400d4d40000000000000000d47547556567152600110000000000610000006415471414241111111111041414671500000000000000000000000000000000
00000000000000000041041414141414472400000000000000000000000467150010840414142404141424041415455514141447152575455555555555555454
c400000000000000000000000000061555654774d441373100110000000000006515151515151424041414156715154400c7000000d70000000000c7d700d700
0000000000d700c7004175471577471515740000d700000000000000d77515441424041515477405776725056777455554545454647405455555555555555555
0000001100000000000000000000d405556515f40000210041373100000000000000000000000000000000000000000055652500000000000000000000067715
0000000000000000000000000041f4150000000000000000000000000000000000000000000000000041751515250000555555652575154555576525f4154555
84810034000000000000000000000005576577230000000000210000000061000000000000000000000000000000000055657400000000000000000000000647
0000000000000000000000000041f4470000000000000000000000000000920000000000000000111111051547260000575555652505474655556525f4674555
14141425000000000000000000000075556515f5000000000000000000000000000082000000b40000000000823200005765f5000092001111000000000041f6
0000000000000000000000000041f67600000000000000000000000000000000000000000000410414e5157726d40000555656666724161546566625f6154557
1577762600000000000000000000000655661574b400000000000000000011000000373100410717f4f4f4f4f4f414146577f5000000410424310000000041f6
000000000000000000000000004135c400000000000000000000000000000000001111110000410615151526c4000000664716761626d4067715762605474656
6726d4a00000000000000000000000046567154724310000000000000041373100002100000021d400000000d4c40615761625310000417525310000000041f4
8200000000820000000082000041358200000000000000000000000000000000410414241100004105472634000000001626d400000000000626c40006761616
25c400000000000000000000000000f665157716263100000000000011002100110000001100000011000000000041f4d4c43531000041f625111100920041f4
000011111111111111111111004135000000000000000000000000000000000041f6771524310041f425042500000000f40000000000000000000000d40000f4
26000000000000000000000000000005651525d4a00000000000004137310000341111113411111134110000000041f610003531000041f415142431000041f6
000007171717141417171727004135940000000000000000000000000000000041f4151574310041f425752500000004f40000000000000000000000000000f4
d4000000000000000000000000000075654725000000000000000000210000001514141415141414152400000000410627713631000041f47776263100004175
0000c4d4004105f53100d4d400417514000000000000000000000000000000004105154726310041f6740626000000f6f40000000000000000000000000000f4
0000000000000000000000000000007566772500000000000000000000000000761676161647151515260000000000f400002100000041f42531d40000004105
00000000004105f43100000000410544000000000000000000006100000000004175152631000011051627a6950000f4f40000000000000000000000000000f4
000000000000000000000000000000f647677400000000000000000000000000a2000021210615772621a200000000f400000000000041f67431000000004105
00000000004175f4310000000000f64500000000001100000000000000000000410525310000110426000000000000f4f40000000000000000000000000000f4
a400100000000000000084000084b4f67676250000000000000000000000000000f000000021752521000000000000f400000000000041062531000011111175
000000000041057431001111111105460000000041340000000000000000000041f6263100410425d400000000004104f40000000000000000000000000000f4
14141424000000000000344104141477212136000000000000000000000000001084000000000626000000000000410400000000000000c43500000007171776
000000000041f62531000717171716760000000041351100000000000000000041f43100004106260000000000004175f40000000000000000000000000000f4
4715777400000000000036710676761600000200000000000000000000000094142400000000212100000000000041050000000000000000f40000002100c4d4
000000000041f4253100d4a0c42121210000000041f624310000000000000000113511000000d4c40000000000004105f4100000b4a4000000008400000052f4
54641525000000000000d4710000c4d400001000000000000000000000000004162600111100000000111100000041f60000000000000000f400000000000000
100000000041057431000000000000001000000041f4743100000000000000410415241100000000000000000000041514141414240414141414141414141414
576567740000000000e400718494000000000000000000000000000000000075c4d400042411111111042400000041f60000000000000000f400000011000000
a6950000004175253100000000110000a695000041f4253100000000000000417547152411000000001100000000f61515471577250515151547151515157715
55654725000000000004247104141414000000c700000000000000d7c70000f60000000515240424041525000000417500000000000000003500000034000000
000000000041052531000000413431000000000041f47431000000000000004105446415f400000000f400000000751554545464257567445454545454545454
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
00000000000000000000000000000005555555555000000000000000000000000000555555000000555500000005000000000000000000000000000000000000
00000000000000000000000000000000055555555555000000000000000000000555555555555005555555500000000000000000000000000000000000000000
00000000000000000000000000000000000550005555555500000000000000000555555555500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005555555000000000000000000000000000000000000000000101000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001110000000000011110011110000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000111000000000001111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000011111100001111111111111100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000011111111000000011301001111000000000010000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000031001111110000000010101001030000000000111000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000333110301011000000013001000010000011110111110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000313330101100100300001001000030000000111111111000000000000000000000000000000000000000
00000000000000000000000000000000000000000000333310001300113300000001000010000000311111111111100000000000000000000000000000000000
0000000000000000000000000000000000000000000133i3330111331i3011100001100000011110101111111110000000000000000000000000000000000000
0000000100000000000000000000000000000000001113i3331111331i1011100001111100111111001001111030000000000001000000000000000000000000
000000101000000000000000000000000000000000111113i3311133111311111001111110111111101011111010000000000010100000000000000000000000
0000001111000000000000000000000000060001111111i111111111111331311001111111111111111111111000000000000011111000000000000000000000
00000101010000000000000000000000000000001111111111113333111133331101111133i11311111111110000000000000101010100000000000000000000
000001111110000000000000000000000000000011111111111133331131311331111133i3311331111111111000000000000111111100000000000000000000
00000010101000000000000000000000000000666333111166666611i31131i31111111311113333116661111100000000000010101000000000001010000000
00001111110000000000001110000000600106666333111666666661116111113111111111133333666366111110006000000111111100000000011111000000
00010101010000000000000100000000000011003331111116666666661166111111111133113311663366111110000000000101010100000000010101000000
000111111111000000000111111000000011111033333331i1166666333336666661611131111331633336631660000000000111111100000000011111000000
000010101010000000001010101000000000i1003333331111336666333333336111111113111311113316633666600000000010101000000000001010000000
000011111000000000001111111100000001133333333333333331133331333331c1c1c1c3111133311111333666660060001111110000000000111111000000
00000101010100000000010101010000001111331333113333333313333133333c1c1c1c1c1111111111i1133330000000000101010100000001010100000000
000001000000000000000111111100000000111111331133313333333311331133ccc7c7c7111111111333331311000000001111110000000011111110000000
00000000000000000000101010100000000011111111111331133333331i33111330777c7771111111111333131ii10000101010101010000010101010000000
00010000000100000001111111110000000111i11i111i1111113003331i111i1100cccccc11i111i1111111i3iiiii001111111111111000011111110000000
000100010001000000010101010100000001i11000011i11i11007700311111100770ccc0001i111i11111i11iii1i1001010101010101000001010100000000
000101111101000000111111111110000011i00777700011i107777770011i10777770c077700111111111i11111ii1101111111111111000011111000111000
000010101010000000101010101010060011077777777700106677777760000677776706677770101001i10000110iii00101010101010000010101000101000
0000111111101100001111111111000000000776677777776666667777776666777660c06667770706700066770060i001110000111110000001110011111110
00010101010000000101010101000000777766666600000760077700770000077000000066000007700776007770000000000000010100000000000001010100
01111111111000000111110111000077777766666033333003300033003333300333333300333330033070330000000000000101111100000000111011111110
10101010101000000010100010000066777777770333333303330333033333330333333303333333033300330000000000001010101000000000101000101010
11111111111100000111110000001110000777700330003303333333033000330000003303300033033330330000000000000101111100000001111100111111
01010101010100000101010000010101000000000111111101111111011111110011111001100011011111110000000000000000010100000001010100010101
01111100111000001111111001111111000000000110001101101011011000110110000001100011011011110000000000000000111110010000111000011111
00101000000000001010101010101010000000000110001101100011011000110111111001111111011001110000001010000000101010101000101010001010
00000011100111001111111111111111100000000110001101100011011000110111111100111110011000110000011111000000111111111111111111011111
01000001000101000101010101010101000000000000000000000000000000000000000000000000000000000000010101000000010101010101010101000101
11110000111111111111111111111111100000000000000000000000000000000000000000000000000000000000011111011100000111111111111111110111
10101000101010101010101010101010000000000000000000900000000000000000000000077337700000000000001010101010000010101010101010100010
11110000111111111111111111111100000000000000000000009000000000000000000000007887000000000000000011111111000000111111111111000011
01000001010101010101010101010100000000000000000000009090000000000000000000000880000000000000000001010101010000010101010100000001
00100011111111111111011111111110000000000000000000000090900000000000000009900000000000000000000011111111000000011111111111110000
00100010101010101010101010101010000000000000000000000090999990000000999999900000000000000000000000101010000000001010101010101010
00100011111111111110001001111110000000000000000000000000999999999999999990000000000000000000000000011100000000001111111111111111
00000001010101010100000000010100000000000000000000000000000999999999990000000000000000000000000000000000000000000101010101010001
00000000111000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111110000
00000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000
00000000000000000100000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000jjjjj0000000jjjjj00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000jj000jj00j00jj0j0jj0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000jj0j0jj0jjj0jjj0jjj0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000jj000jj00j00jj0j0jj0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000jjjjj0000000jjjjj00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000111011101100110010100000111010100110111001100110110000000000000000000000000000000000000000
00000000000000000000000000000000000000111010101010101010100000010010101010101010001010101000000000000000000000000000000000000000
00000000000000000000000000000000000000101011101010101011100000010011101010110011101010101000000000000000000000000000000000000000
00000000000000000000000000000000000000101010101010101000100000010010101010101000101010101000000000000000000000000000000000000000
00000000000000000000000000000000000000101010101110111011100000010010101100101011001100101000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000110001101110100000001110111011101110101000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000101010101000100000001010100010101010101000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000101010101100100000001100110011001100111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000101010101000100000001010100010101010001000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000101011001110111000001110111010101010111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000jjj00jj0jj000000jjj0j0j00000jjj0jjj0jjj0jjj0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000jjj0j0j0j0j00000j0j0j0j00000jjj0j000j000j0j0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000j0j0j0j0j0j00000jj00jjj00000j0j0jj00jj00jjj0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000j0j0j0j0j0j00000j0j000j00000j0j0j000j000j000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000j0j0jj00jjj00000jjj0jjj00000j0j0jjj0jjj0j000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000jjj0j0j00jj0jjj00jj00000jjj0j0j00000jjj0j0j0jjj0j0j0jjj0jjj0jj0000000000000000000000000000000000
00000000000000000000000000000000jjj0j0j0j0000j00j0000000j0j0j0j00000j0j0j0j0j0j0j0j0j0j0j000j0j000000000000000000000000000000000
00000000000000000000000000000000j0j0j0j0jjj00j00j0000000jj00jjj00000jj00j0j0jj00jjj0jj00jj00j0j000000000000000000000000000000000
00000000000000000000000000000000j0j0j0j000j00j00j0000000j0j000j00000j0j0j0j0j0j000j0j0j0j000j0j000000000000000000000000000000000
00000000000000000000000000000000j0j00jj0jj00jjj00jj00000jjj0jjj00000j0j00jj0jjj0jjj0j0j0jjj0jjj000000000000000000000000000000000
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
0000000000000000000000000000060002020202020000000000000000000000000000000000000200000000000000000000000000000000000000000000000001010101010101010202020202020201010101010101010102060600000001010101010101010101020206000002020101010101010101010206060602020200
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
006869000000000000000000000000000000000000000000000000000000000000006074545556520000000000000000656565656565667647000000000000006161677651746761676751524f00006000000000000000005064665161616161775f000000000000000000000011505165656565665162000000000000000000
48784e000000000000000000000000000000000000000000000000000000000000004d50545566470000000000000000517461616161515147000000000000000000735751474c000000607742000040000000000000000060745162004d00005162000000000000000000000040517761615151744700000000000000000000
41414142000000000000000000000000000000000000000000000000000000000000005764665162000000000000000077624d00004c577462000000000000000000005074620000000000505200005000000000000000001260624d00000000624d00000000000000160000006f51514d7350775162000000000000184e4b00
76517447000000000000000000000000000000000000004e4b00000000000000000b00507751470000000000000000005200000000005047000000000000000001480057524d00000000005747000050480100000000000000121200000000004c0000000000000000000000006f517400005751470000000000484041414141
5151516200000000000000000000000000000000004840414142000000000000000000575174520000000000000000004700000000005752000000000000004041421757520000004e48005052000057426a7b00000000000000000000484940000000000000000000000000006f5151000057745f0000000014407751517651
7467620000000000000000000000000000000000004074515147000000000000000000607651520000000000000000006200000018005062000000000019005777620050470000004042175047000057470000004b000000000000000040415100000000000000000000000000575144000060515f0000000014507451444545
624d0000000000000000000000000000000000000050775174620000000000000000004c5076520000000000000000004d000017171763000000000040414151474d0050520000005062005047000050620000004041420000000000006051510000000000000000000000000050775400004d50470000160014505144555555
4c0000000000000000000000000000000000000000606761624d00000000000000000000607747000000004a4b0048000000000000004d00000000005077517462000050470000145300005752000060000000005751521100000000000050440000000011110000001600001157515400000057520000000014575154557555
000000000000000000000000000000000000000000004c004d00000000000000000000004d5062000000404141414270000000000000000000000000575151514c000057620000146300005062000014000000005751514211110000000050540000000040420000000000114076515400000060620000000014505164656565
0000000000000000000000000000000000000000000000000000000000000000000000000063000000005777515176410000000000000000004b480050514445000000634d0000004d0000634d0000140000000057515161414200000000506400000000505f00000011114051515154000000004c0000000000577774515151
000000000000000000000000000000000000000000000000000000004b49484800000000004c00000000575144454545000000000000000000404141745154550000004d000000000000004c00000000000017175077624d605f00000011505100000000575f000000404151775144554b014800000000000000606761677651
000148000000000000000000000000000000484e0000000048004a404141414100014800000000000011505154555555000000000000000000577651515154550000000000000000000000000000000000000000606200004c4f0019004f6f760000004e504700000057765144455555414142000000000000004c0000735751
41414142004a000000000000000000004a4041414142484041414151745177514141424b000000000040517454555575000000000000000000505151514455750000000000000000000000000000000000000000004d0000004f114f114f6f514b01484051520000115751445555557577515200000016000000110000005051
51745151414141424b00000000004840415151517651415177515151515144457651514200000000005751445555555548010000000000484a57514445555555000000000000000000000000000000007a7b000000004b184a4f4f4f4f4f4f6f4141415176471111407451545555555546764700000000000000430019005774
4545465176515151420000000040415151764445465174515144454545455575454676474a4800004e505154557555554141420000004041415174545555555500000000000000000000000000000000686900000000404141424f734f6f76515174775151514141515177545575555556515200000000000000574141417751
55555545454546764700000000577451514455555545454545555575555555555556775141414141417451545555555551775200000050765151445555557555000000000000000000000000000000005800797a7b005051765240426f7451444545454546515174515144555555555556744700000000000000507651745151
0000000060674f4f4f7464667762000000000000000060616762000000006f7662000000577477616767617651676174000000000000005054756652000000000000000000000000000000145051547500000000000000505456470000000000000000000000000000000000000000005177527f000060616761677451515174
000000000000121212607651470000000000000000004d004c0a000000006f514c0000006067624c4d000060624d4d574e000000000000575456766200000000000000000000000000001440777454550000000000000057646647000000000000000000000000000000000000000000746762000000004d00004d6076776761
4801480000000000000050776200000000000000000000000000000000405144000000004d0a4d000000000a4c0000504200014b4a0000506466524d000000000000001111111100000014575144555500000000000000607751520000000000000000000b0000000000000000000000624c0000000000000000004d50624c00
4141421111111111000057474d0000000000000000000000000000000057775400000000000000000000000000000050677171717200006f775147000049480000000040414142130000145076547555000000000000004d5776470000000000000000000000000000000000000000004d0000000000000000000000634d0000
775174414141717200006062000000000000000000000000000000000057515400000000000000000000000000160057004c4d004d00006f745147000070714148014b50767452130000146f5154555500000000000000006f515f0000000000000000797a7b0000000000000000000000000000000000000000000000000000
7451676167624d0000004c00000000000000000000000000000000000050745400000000000000000000000000000057000000000000006f51775200000a14504141417451676213000014577464656500000000000000006f514700000000000000000068000000000000000000000000000000000000000000000000004a40
67624d0000000000000000000000000000000000000000000000000000575154000000000000000000000000000011500011111111111150767447130000145774765177471300000000146f51517674006e0000000000005774620000000000000000797a7b0000000000000000000000000000000000000000000048404151
424c000000000000000011110000000000000000000000000000000000607764000000001111110000000000111140740070717141414167616762130000146067616751521300000000146f51776167017e4a000000000050477300000000000000000068690000000000000000000000000000000000000000000040747751
52000000000000000014404200000000000000000000000000000000004350740000001470717213000000114041515100000a4d6067624c004d0a000000004f4d004d57471300001111115776624d004141420000000000606212000000000000004a00784e48000000004b0000000000000000000000000000000050515176
47000b0000000000001457520000000000000000000000000000000000636067000000004d0a4c00000000405151514400000000004d4d00000000000000004f000000606200000070414177524d00005174472000000000004d0000000000000000404141414200000070420000000000000000000000000000000057514445
5200000000001600001450474800000000000000000000000000000000404141000000000000000000000057745144550000000000000000000000000000004f0016004c0a0000004d6067616200000077616200000000000000000000000000000050745151470000000063000000000000000000000000000000006f765455
47111100000000000014575273004e4800000000000000000000000000507774000000000000000000000060517654550000000000110000000000000000004f000000000000000000004c4d0a00000052734d00000000001111000000000000000060517677620000000000000000000000000000000000000000006f775475
514142000000000000146074414141410000000000000000000000000050514400000000000000000000004d5751545500000000004f0000000000000000004000000000000000000000000000000011620000000000001440421300000000000000006067624d0000000000000000004801000000005b00000000006f515455
51775f000000000000000057517651774a01480000000000000000004850745400014b0000000000000011115051545500000000004f00000000000000001157000000000000000000000000000014404d00000000000014606213000000000000000000004d00000000000000000000414142484b00000048004a4857515455
46515f00000000000000005777514445414142000000000000000000405151544840420000000000001140415151547500000000004f0000000000000000405100000000000000000000000000001450000000000000000000000000000000000000000000000000000000000000000074767741414141424041414174515455
56764700000000000000005076515475777647000000000000000000575144554151470000000000004051765144555500000000004f0000000000000000507700000000000000000000000000001450007c0000000000000000007c7d00226d7c00000000000000007d00007d00000045465151767451475751515176515475
__sfx__
150400080c2700c2700c2700c2700c2700c2700c2700c270002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
1114000002070020500204002030020200201009050090300e0700e0500e0400e0300e0200e010090500903002070020500204002030020200201009050090300e0700e05002040020300a050000000905000000
1714000026714267312675126751267422673226722267122d7312d7412d7512d7422d7322d7222e7552b7552d7312d7412d7512d7412d7312d7222d7122d7151501415021150311504115051150611507126754
071400000e75321115186151a7151c61521115020331a71532655217150c6151a7152461518615020331a7150e753211140c7431a7151c61421715020331a715326553000018616300001c61521115246151a715
111400000707007050070400703007020070100e0500e0301307013050130401303013020130100e0500e0300707007050070400703007020070100e0500e0301307013050070400703005050070000405007000
151400002b7542d7322b7502b7512b7412b7322b7222b7122d7002d7002d7002d015390152d7002e70026754297542b7322975029751297412973229722297120e1140e1210e1210e12128714287212873128742
1714000026714267312675126751267422673226722267122d7312d7412d7512d7422d7322d7222e7552b7552d7312d7412d7512d7412d7312d7222d7122d7151501415021150311504115051150611507132754
1514000034754357323475034751347413473234722347122d7002d7003270032700327443275132742327322d7512d7512d7412d7322d7222d7122d7122d7150e1140e1210e1210e12128714287212873128742
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
0010002021610206101e6101b610196101561012610116100f6100e6100d6100c6100c6100c6100c6100d6100e6100f610106101161013610156101661017610196101b6101d6101e61020610216102261022610
010800001432120355004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0001000036270342702e2702a270243601d360113500a3400432001300012001d1001010003100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00050000212731e273132730a25300223012033b203282033f2032f203282031d2031020303203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203
0102000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
011000002a3542935426354203541f354273542b3542f3542f355013053f3042f3043f3042f3043f3040030400304003040030400304003040030400304003040030400304003040030400304003040030400304
000400003045033450314502e4502f45030440000000000001400264002f40032400314002e4002f4003040030400304000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000e6610e6610e6610c65106631006110a601286013f6012f601286011d6011060103601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
0102000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002d751267511b7410c7310171107701047013370133701337013f7013f7010070100701007010070100701007010070100701007010070100701007010070100701007010070100701000000000000000
1d160000217702477026772267722677226772267722477028772287722877228772217702477027772277622676026750247401f720217622176221762217621d70035700247002e7001d7002e7002470037700
000200000641008410094100b410224302a4403c6403b6403b6403964036640326402d6402864024630216301d6301a63016620116200e6200b61007610056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
1114000005070050550507005050050400503005020050100507005055050700505005040050300c0500c03011070110550507005050050400503005020050100707007050070400703005050000000405000000
1714000029752297151d6651d615356553561529665296153c6663c615356553560010053040433c6553c61529765297553c6673c615356553561529665296152b7642b71510053100133c6553c6152873428741
171400002676426750267322671226712267002671226700267122600026715260002671504000267153c60029700297003c6003c600356003560029600296001501415021150311504115051150611507115075
1714000029752297151d6651d615356553561529665296153c6663c615356553560010053040433c6553c61529765297553c6673c615356553561529665296152b7642b71510053100132d7442d7412d7522d752
131200000c0631862524645000000c6550000030635000000c0631862524645006250c6550000030635000000c0631862524645000000c6550000030635000000c0631862524645006250c65500000306352b635
151200002673528735297452b7452d7552673528735297452b7452d755267352873529745307452e7552d7552b7352d7352674528745297552b7352d7352674528745297552b7352d73526745307452e7552d755
8d120000022240222102231022310224102241022510225102251022510224102241022310223102221022210e2240e2210e2310e2310e2410e2410e2510e2510e2510e2510e2410e2410e2310e2310e2210e221
8d1200000a8240a8210a8310a8310a8410a8410a8510a8510a8510a8510a8410a8410a8310a8310a8210a82116824168211683116831168411684116851168511685116851168411684116831168311682116821
8d1200000a8140a8110a8210a8210a8310a8310a8410a8410a8410a8410a8310a8310a8210a8210a8110a81116814168111682116821168311683116841168410c8400c8410c8310c8310c8210c8210c8110c811
17120000267652671526715297653a665297152876528715287152b7652b7152b71539665297152876528715287542975028750267503b6652671026715267002670026700000000000039665000000000000000
171200002676526715267152976539665297152876528715287152b7652b7152b7153b665297152b7652b7152d7402d7102d7152d71539665267002670026700307642e7502b7402d7503a6652d7222d7123c624
151200000c0630c0132673528735297452b7452d7552673528735297452b7452d755267352873529745307452e7552d7552e7552d7552674528745297552b7352d7352674528745297552b7352d735267450c063
151000000205502055020550204505055050550505505045040550405504055040550705507055070550705502045020550205502055020450205509055090550205502055020550205509045090650206502065
111000002d3602d3502d3222d3122b3502b34029350293402b3602935000300283502833029350283502636026350263402632226312003000030015115151251512515115003000030021354223502435026352
011000000c0630c6150c06300000186550c06318615000000c06300000000000c0631c655000000c61500000000000c0630c06300000286550c06318615000000c06300000000000c0631c655000000c61500000
15100000070550705507055070450a0550a0550a0550a045090550905509055090550205502055020550204507065070650706507065070550705511055130550705507055070550704511055130550205502055
11100000283602835229350283602835028322283122930015115151251512515115303002b30030351303152d3502d3422d3222d31526350293402d3502b3602b3502b32229350283502832228312293502b350
111000002d3602d3502d3222d3122b3502b34029350293402b36029350003002835028330293502b3502d3602d3502d3402d3222d312243002e3002e3302d3502d3402d3302d3222d31221354223502435026352
151000000207502055020000200005075050550500005000040750405504000040000707507055070000700002075020550200002000020750205509065090550207502055020000200009000090000200002000
131000003e6703e6552d525265252d5002d5002d525265252d525325152d525265250050000500295252852526515285000050000500005000050000500005002650028500005000050032650326303262032615
111000002d356213362d31615316293561d33629316113162b3561f3362b31613316263561a336263160e316283561c336283161c316223561633622316163162b3502b332293502835028320283122935029322
1110000028350293402834026350263402632026312263122d300213002d356213162d300213562d3162130628354293422834026350263402632026312263122d300213002d356213262d300213562d31621654
100b0000122001220013200132001520015200152001520015200152001620016200182001820018200182001820018200182001820016200162001520015200152001520015200152050c605152000c6050c605
580b0000266030000000000000000000000000000000000026603000000000000000000000000000000000002660300000000000000002603000000000000000266050000000000000000c0000c0000c0000c000
100b00000e2000e2000e2000e2001220012200132001320015200152001520015200132001320015200152001620016200162001620015200152001520015200132001320013200132000c605152000c6050c605
000b00001a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051a9001a9050c605152000c6050c6051a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051a9001a9050c605152000c6050c605
000b00001a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051b9001b9051b9001b9051b9001b9051b9001b9051b9001b9051b9001b9051a9001a9051a9001a9050c605152000c6050c605
000b00001a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051f9001f9051e9001e9051b9001b9051b9001b9051e9001e9051e9001e9051a9001a9051a9001a9050c605152000c6050c605
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00400000302053020530205332052b20530205302053020530205302053020530205302053020530205302052b2052b2052b20527205292052b2052b2052b2052b2052b2052b2052b2052b2052b2052b2052b205
__music__
01 01024303
00 04054303
00 01064303
00 04074303
00 01024303
00 04054303
00 01064303
00 04074303
00 21224303
00 01234303
00 21244303
02 01234303
01 25262744
00 25262744
00 25262844
00 25262944
00 25262744
00 25262744
00 25262844
00 25262944
00 252a2744
00 252b2744
00 252a2844
00 252b2944
00 2c262744
02 2c262944
01 2d2e2f44
00 30312f44
00 2d322f44
00 30312f44
00 2d2e2f44
00 30312f44
00 2d322f44
00 30312f44
00 33342f44
00 2d352f44
00 30362f44
00 2d352f44
00 30362f44
02 33342f44
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
03 10424344

