pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function zg(n,e)return{x=n,y=e}end function zh(n,e,t,o)return{x=n,y=e,w=t,h=o}end function yk(e,n)_ENV[e]=_ENV[n]or n end True=true function usplit(n,e,t,o)if n then local n=split(n,e)for d,e in pairs(n)do n[d]=not t and o[e]or e end return unpack(n)end end function yb(e,n)n=n or _ENV foreach(split(e,"\n"),function(e)local e,t=usplit(e," ",true)n[e](usplit(t,",",e=="yk"or e=="yh",n))end)end _camera=camera camera=function(n,e)n,e=n or 0,e or 0_camera(n+tl*15,e+tl*28)end yb[[yk freeze,0
yk dr,0
yk st,0
yk ut,-99
yk cx,0
yk cy,0
yk ce,0
yk cz,0
yk cg,0.1
yk cox,0
yk coy,0
yk _pal,pal
yk sk,0
yk tl,1]]xd,got_fruit,obj_bins={},{},{solids={}}local n=_ENV function _init()xd,got_fruit,obj_bins={},{},{solids={}}yb[[yk max_djump,1
yk ds,0
yk fs,0
yk ss,0
yk ss_f,0
yk ms,0
yk bc,0
music 0,0,7
load_level 1]]end dead_particles={}function bt(e,t)local n={}for t,o in pairs(t)do n[split(e)[t]]=o end return n end stars,stars_falling={},true for n=0,15do add(stars,bt("x,y,off,zcy,size",{rnd"128",rnd"128",rnd(),rnd"0.75"+.5,rnd{1,2}}))end function create_type(n,e,t)return{init=n,update=e,draw=t}end xb=create_type(function(_ENV)hb=zh(args"1,3,6,5")yb[[yh djump,max_djump
yh collides,True
yh layer,2
yh grace,0
yh jbuffer,0
yh dash_time,0
yh dash_effect_time,0
yh dash_target_x,0
yh dash_target_y,0
yh dash_accel_x,0
yh dash_accel_y,0
yh spr_off,0
yh berry_timer,0
yh bc,0]]dream_particles={}end,function(_ENV)foreach(dream_particles,function(n)n.x+=n.dx n.y+=n.dy n.t-=1if n.t<=0then del(dream_particles,n)end end)if dreaming then dream_time+=1if dream_time%5==0then add(dream_particles,bt("x,y,dx,dy,t,type",{x,y,zc.x/8,zc.y/8,10,2}))end add(dream_particles,bt("x,y,dx,dy,t,type",{x+4,y+4,rnd"0.5"-.25,rnd"0.5"-.25,7,1}))if not zp(xk,0,0)then layer,ye,zc,dash_time,dash_effect_time,dreaming=2,_ye,zg(mid(dash_target_x,-2,2),mid(dash_target_y,-2,2)),0,0sfx(28,-2)sfx"27"if zc.x~=0then grace=4end end end local e=pause_xb and(h_input or 0)or split"0,-1,1,1"[btn()%4+1]if is_flag(0,0,-1)or y>lvl_ph and not exit_zl then kill_xb(_ENV)end local t=zm(0,1)if zm(0,1,true)then berry_timer+=1else berry_timer,bc=0,0end for t,e in inext,fruitrain do if e.type==fruit and(not e.golden or lvl_id==35and x>=60)and berry_timer>5then bc+=1n.bc+=1if e.golden then n.collected_golden=true end berry_timer,got_fruit[e.fruit_id]=-5,true init_object(lifeup,e.x,e.y,bc)del(fruitrain,e)destroy_object(e);(fruitrain[t]or{}).target=e.target end end if t and not was_on_ground then ye(0,4)end local o,d=j_input,d_input if not pause_xb then o,d=btn(🅾️),btn(❎)end local i,f=o and not p_jump,d and not p_dash p_jump,p_dash=o,d if i then jbuffer=5end jbuffer=max(jbuffer-1)if t then grace=7if djump<max_djump then psfx"22"djump=max_djump end end grace=max(grace-1)dash_effect_time-=1if dash_time>0then ye()dash_time-=1zc=zg(appr(zc.x,dash_target_x,dash_accel_x),appr(zc.y,dash_target_y,dash_accel_y))else local o=t and.6or.4zc.x=abs(zc.x)<=1and appr(zc.x,e,o)or appr(zc.x,sign(zc.x),.15)if zc.x~=0then zb.x=zc.x<0end local o=2if zm(e,0)then o=.4if rnd()<.2then ye(e*6)end end if not t then zc.y=appr(zc.y,o,abs(zc.y)>.15and.21or.105)end if jbuffer>0then if grace>0then psfx"18"jbuffer,grace,zc.y=0,0,-2ye(0,4)else local n=zm(-3,0)and-1or zm(3,0)and 1if n then psfx"19"jbuffer,zc=0,zg(n*-2,-2)ye(n*6)end end end if f then if djump>0then ye()djump-=1dash_time,n.has_dashed,dash_effect_time=4,true,10local t=btn(⬆️)and-1or btn(⬇️)and 1or 0local o=e&t==0and 5or 3.53553zc=zg(e~=0and e*o or t~=0and 0or zb.x and-1or 1,t*o)psfx"20"n.freeze,n.sk=2,5dash_target_x,dash_target_y,dash_accel_x,dash_accel_y=2*sign(zc.x),split"-1.5,0,2"[t+2],t==0and 1.5or 1.06066,zc.x==0and 1.5or 1.06066if ph_input==-e and oob(ph_input,0)then zc.x=0end else psfx"21"ye()end end end spr_off+=.25za=t and(not pause_xb and btn(⬇️)and 6or(not pause_xb and btn(⬆️)or u_input)and 7or zc.x*e~=0and 1+spr_off%4or 1)or zm(e,0)and 5or 3update_hair(_ENV)if(exit_zj and zi()>=lvl_pw or exit_zk and y<-4or exit_zi and zj()<0or exit_zl and zk()>=lvl_ph)and levels[lvl_id+1]then next_level()end was_on_ground,ph_input=t,e end,function(_ENV)draw_dreams(_ENV,1,12)if not dreaming then pal(8,djump==1and 8or 12)draw_hair(_ENV)draw_obj_za(_ENV)pal()end end)function draw_dreams(_ENV,o,e)foreach(dream_particles,function(_ENV)if type==1then n.circfill(x,y,t/2,n.split"1,13"[t]or e)end end)foreach(dream_particles,function(n)if n.type==2then local t=2.5-n.t/4for t=0,15do pal(t,split"1,1,1,13,13,13"[n.t]or e)end sspr(8,0,8,8,n.x-t/2,n.y-t/2,8+t,8+t)end end)pal()if dreaming then for n=0,15do pal(n,e)end draw_obj_za(_ENV)local t=split"8,8,8, 16,16,16, 24, 32,32,32"[dream_time%10+1]pal(7,({e,e,o,o,e,o})[dream_time%7]or 7)local e,n=split"0,5"[dream_time]or rnd()<.4and 4or 0,2if dream_time<3then n,t=4,0end sspr(t,48,8,8,x-n,y-e/2,8+n*2,8+e)pal()end end function create_hair(_ENV)hair={}for n=1,5do add(hair,zg(x,y))end end function update_hair(_ENV)local e=zg(x+(zb.x and 6or 1),y+((not pause_xb and btn(⬇️)or type==xb_spawn and entrance_dir==6)and 4or 2.9))foreach(hair,function(n)n.x+=(e.x-n.x)/1.5n.y+=(e.y+.5-n.y)/1.5e=n end)end function draw_hair(_ENV,e)for t,n in inext,hair do circfill(round(e and 207-n.x+e or n.x),round(n.y),split"2,2,1,1,1"[t],8)end end xb_spawn=create_type(function(_ENV)yb[[yh layer,2
yh za,3
yh target,y
sfx 15]]local e,t,o=0,0,zp(camera_trigger,0,0)if o then e,t=o.offx,o.offy n.cox,n.coy=e,t end n.cx,n.cy=mid(x+e+4,64,lvl_pw-64),mid(y+t+4,64,lvl_ph-64)yb[[yh state,0
yh delay,0]]zb.x=entrance_dir%2==1if entrance_dir<=1then y,zc.y=lvl_ph,-4elseif entrance_dir<=3then if not zm(0,1)then xb_start_zcy=2end y,zc.y,state=-8,1,1elseif entrance_dir<=5then local n=entrance_dir==4and 1or-1zc,x=zg(1.7*n,-2),x-24*n else state,delay=2,20end create_hair(_ENV)update_hair(_ENV)yb[[yh djump,max_djump]]foreach(fruitrain,function(n)fruitrain[1].target=_ENV add(xd,n)n.x,n.y=x,y fruit.init(n)end)end,function(_ENV)if state==0and y<target+16then state,delay=1,3elseif state==1then zc.y=min(zc.y+.5,3)if zc.y>0then if delay>0then zc.y=0delay-=1elseif y>target then state,zc=2,zerovec()if not xb_start_zcy then y,delay,n.sk=target,5,4ye(0,4)sfx"16"end end end elseif state==2then if tl<=0then delay-=1elseif tl<1then n.tl=appr(tl,0,max(tl/10,.01))elseif tl==1and(btn(4)or btn(5))then n.tl-=.01sfx"61"end za=6if delay<0then destroy_object(_ENV)local n=init_object(xb,x,y)n.zb,n.hair,n.zc.y=zb,hair,xb_start_zcy or 0;(fruitrain[1]or{}).target=n end end update_hair(_ENV)end,xb.draw)camera_trigger={update=function(_ENV)if timer and timer>0then timer-=1if timer==0then n.cox,n.coy=offx,offy else n.cox+=cg*(offx-cox)n.coy+=cg*(offy-coy)end elseif yc()then timer=5end end}xe=create_type(function(_ENV)offset,timer,hb=rnd(),0,zh(args"-1,-1,10,10")end,function(_ENV)if timer>0then timer-=1if timer==0then psfx"12"ye()end else offset+=.02local n=yc()if n and n.djump<max_djump then psfx"11"ye()n.djump,timer=max_djump,60end end end,function(_ENV)if timer==0then spr(15,x,y+sin(offset)+.5)else palt"0xfeff"draw_obj_za(_ENV)palt()end end)xf=create_type(function(_ENV)yb[[yh solid_obj,True
yh state,0
yh unsafe_ground,True
yh delay,0]]end,function(_ENV)if delay>0then delay-=.2elseif state==0then for n=-1,1do if zp(xb,n,abs(n)-1)then psfx"13"state,delay=1,2.79ye()break end end elseif state==1then state,delay,yg=2,11.79else if not yc()then psfx"12"state,yg=0,true ye()end end za=state==1and 25.8-delay or state==0and 23end)smoke=create_type(function(_ENV)layer,zc,zb=3,zg(.3+rnd"0.2",-.1),zg(rnd()<.5,rnd()<.5)x+=-1+rnd"2"y+=-1+rnd"2"end,function(_ENV)za+=.2if za>=29then destroy_object(_ENV)end end)fruitrain={}fruit=create_type(function(_ENV)yb[[yh y_,y
yh off,0
yh tx,x
yh ty,y]]golden=za==11if golden and ds>0then destroy_object(_ENV)end end,function(_ENV)if target then tx+=.2*(target.x-tx)ty+=.2*(target.y-ty)local n,e=x-tx,y_-ty local t,o=atan2(n,e),n^2+e^2>r^2and.2or.1x+=o*(r*cos(t)-n)y_+=o*(r*sin(t)-e)else local n=yc()if n then n.berry_timer,target,r=0,fruitrain[#fruitrain]or n,fruitrain[1]and 8or 12add(fruitrain,_ENV)psfx"62"end end off+=.025y=y_+sin(off)*2.5end)fruit.zp_fruit=true lifeup=create_type(function(_ENV)zc.y=-.25yb[[yh duration,30
yh flash,0
yk st,20
yh ze,false
sfx 9]]end,function(_ENV)duration-=1if duration<=0then destroy_object(_ENV)end flash+=.5end,function(_ENV)?split"1000,2000,3000,4000,5000,1up"[min(za,6)],x-4,y-4,7+flash%2
end)badeline=create_type(function(_ENV)for n in all(xd)do if(n.type==xb_spawn or n.type==badeline)and not n.tracked then bade_track(_ENV,n)break end end states,timer={},0end,function(_ENV)xb_input=xb_input or btn()~=0if tracking.type==xb_spawn then local n=find_xb()if n.type==xb then bade_track(_ENV,n)end elseif tracking.type==badeline and tracking.timer<30then return end if not xb_input and(tracking.type==xb or timer==29)then return end if timer<50then timer+=1end local n,t,e=smokes,{},states smokes={}do local _ENV=tracking foreach(dream_particles,function(n)local e=add(t,{})for n,t in pairs(n)do e[n]=t end end)add(e,{x,y,zb.x,za or 1,n,dreaming,dream_time,t,layer,tangible or type==xb})end if#e>=30then x,y,zb.x,za,n,dreaming,dream_time,dream_particles,layer,tangible=unpack(deli(e,1))for n in all(n)do ye(unpack(n))end end if timer==30then create_hair(_ENV)end if timer>=30then update_hair(_ENV)end local n=yc()if n and tangible then kill_xb(n)end end,function(_ENV)if timer>=30then draw_dreams(_ENV,2,8)if not dreaming then palsplit"8,2,1,4,5,6,5,2,9,10,11,8,13,14,6"draw_hair(_ENV)draw_obj_za(_ENV)pal()end end end)function bade_track(_ENV,n)n.tracked,tracking=true,n local e=n.ye n.ye=function(...)add(smokes,{...})e(...)end end function resize_rect_obj(_ENV,n,e)while(zj()<lvl_pw-1and tile_at(zj()\8+1,y/8)==n)hb.w+=8
while(zl()<lvl_ph-1and tile_at(x/8,zl()\8+1)==e)hb.h+=8
end xg=create_type(function(_ENV)resize_rect_obj(_ENV,args"67,67")yb[[yh collides,True
yh solid_obj,True
yh timer,0]]end,function(_ENV)if not state and zp(xb,0,-1)then state,timer=0,10sfx"13"elseif timer>0then timer-=1if timer==0then state+=1zc.y=.4end elseif state==1then if zc.y==0then for n=0,hb.w-1,8do ye(n,hb.h-2)sfx"25"end timer=6end zc.y=appr(zc.y,4,.4)end end,function(_ENV)local d,i=x,y if timer>0then d+=rnd"2"-1i+=rnd"2"-1end local t,o,f,l=hb.w-8,hb.h-8,split"37,80,81,?,42,41,43,42,58,57,59,58,?,80,81,?",split"0,0,0,0,0,0x8000,0x8000,0,0,0x8000,0x8000,0,0,0,0,0"for n=0,t,8do for e=0,o,8do local t=(n==0and 1or n==t and 2or(n==8or n==t-8)and 3or 0)+(e==0and 4or e==o and 8or(e==8or e==o-8)and 12or 0)+1palt(l[t])spr(tonum(f[t])or(n+e)%16==0and 44or 60,n+d,e+i)end end palt()end)xh=create_type(function(_ENV)yb[[yh off,2]]end,function(_ENV)if not collected and yc()then collected=true controller.missing-=1ye()sfx"23"end off+=collected and.5or.2off%=4end,function(_ENV)palt"0x80"if controller.active then za=68pal(12,2)else za=split"68,69,70,69"[1+flr(off)]zb.x=off>=3if collected then pal(12,7)end end draw_obj_za(_ENV)palt()pal()end)xi=create_type(function(_ENV)yb[[yh delay,0
yh end_delay,0
yh solid_obj,True]]resize_rect_obj(_ENV,72,87)end,function(_ENV)if missing==0and not active then active,delay=true,20foreach(switches,function(_ENV)ye()ye()end)n.st=20sfx"24"end if end_delay>0then end_delay-=1if end_delay==0then delay=10if dirx~=0then for n=0,hb.h-1,8do ye(dirx==-1and-6or hb.w-2,n)end end if diry~=0then for n=0,hb.w-1,8do ye(n,diry==-1and-6or hb.h-2)end end end end if delay>0then delay-=1elseif active then local n,e=target.x-x,target.y-y local t,o=min(abs(n)+1,distx/4)/8,min(abs(e)+1,disty/4)/8zc=zg(t*sign(n),o*sign(e))if not done then if n==0and e==0then end_delay,done=5,true sfx"25"end end end end,function(_ENV)local n,e=x,y if delay>3then n+=rnd"2"-1e+=rnd"2"-1end local t,o=n+hb.w-8,e+hb.h-8for t in all{n,t}do for o in all{e,o}do spr(71,t,o,1,1,t~=n,o~=e)end end for n=n+8,t-8,8do spr(72,n,e)spr(72,n,o,1,1,true,true)end for e=e+8,o-8,8do spr(87,n,e)spr(87,t,e,1,1,true)end rectfill(n+8,e+8,t,o,1)spr(88,n+hb.w/2-4,e+hb.h/2-4)end)xi.end_init=function(_ENV)switches={}foreach(xd,function(n)if n.type==xh then add(switches,n)n.controller=_ENV elseif n.za==88then target=n destroy_object(n)local n,e=n.x-x,n.y-y dirx,diry,distx,disty=sign(n),sign(e),abs(n),abs(e)end end)missing=#switches end xj={}function calc_seg(n)local e=xks_active and time()or 0if(n[2])return(sin(e/n[2]+n[2])+sin(e/n[3]+n[3])+2)/2
return 0end function build_segs(e,t)local o={}for n=1,2do local n,e,d={{e},{e+4}},e+10+flr(rnd"6"),e+4while(e<t-4)add(n,{e,rnd"3"+2,rnd"3"+2})d=e e+=flr(rnd"6")+6
n[d>t-8and#n or#n+1]={t-4}add(n,{t})add(o,n)end return o end function draw_ze(_ENV,n,e,o,d,f,i)for n,t in ipairs{n,e}do local n,d=d[n],split"-1,1"[n]for e=1,#n-1do ly,ry=n[e][1],n[e+1][1]if ry<o or ly>=o+129then goto n end local n,e=t+d*calc_seg(n[e]),t+d*calc_seg(n[e+1])local o,e=(e-n)/(ry-ly),n for n=ly,ry do e+=o local e,o,d=round(e),ze_size,0if f then rectfill(n,e,n,t,0)e,n,o,d=n,e,d,o else rectfill(e,n,t,n,0)end if#disp_shapes==0then rectfill(e-o,n-d,e+o,n+d,i)else local t,d,f,o=displace(disp_shapes,e,n)t=max(4-t,0)pset(e+d*t*o,n+f*t*o,i)end end::n::end end end xk=create_type(function(_ENV)layer,kill_timer,particles=3,0,{}resize_rect_obj(_ENV,65,65)for n=1,hb.w*hb.h/32do add(particles,bt("x,y,z,c,s,t",{rnd(hb.w-1)+x,rnd(hb.h-1)+y,rnd(),split"3, 8, 9, 10, 12, 14"[flr(rnd"6")+1],rnd(),flr(rnd"10")}))end dtimer,disp_shapes,xsegs,ysegs,pitch,ze=1,bt("min_x,min_y,max_x,max_y",split"10000,-10000,10000,-10000"),build_segs(x,zj()),build_segs(y,zl()),0ze_size=0end,function(_ENV)local n=yc()if n then local _ENV,e=n,_ENV dash_effect_time,dash_time=10,2local t=(dash_target_y==0or dash_target_x==0)and 2.5or 2dash_target_x,dash_target_y=sign(dash_target_x)*t,sign(dash_target_y)*t if not dreaming then zc=zg(dash_target_x*(dash_target_y==0and 2.5or 1.7678),dash_target_y*(dash_target_x==0and 2.5or 1.7678))dream_time,dreaming=0,true _ye,ye=ye,function()end sfx"28"e.pitch=5end if abs(zc.x)<abs(dash_target_x)or abs(zc.y)<abs(dash_target_y)then yd(dash_target_x,dash_target_y,0)if zm(dash_target_x,dash_target_y)or oob(dash_target_x,dash_target_y)then sfx(28,-2)kill_xb(n)end end djump,layer=max_djump,3local _ENV=e if dtimer>0then dtimer-=1if dtimer==0then dtimer=4add(disp_shapes,{n.x+4,n.y+4,0})end end poke(14704,204+pitch)poke(14706,211+pitch)pitch=min(pitch+1.5,27)+(pitch>=27and rnd"8"or 0)else dtimer=1end disp_shapes.min_x,disp_shapes.max_x,disp_shapes.min_y,disp_shapes.max_y=args"10000,-10000,10000,-10000"for n in all(disp_shapes)do local e,t=unpack(n)n[3]+=2if n[3]>=15then del(disp_shapes,n)end disp_shapes.min_x,disp_shapes.max_x,disp_shapes.min_y,disp_shapes.max_y=min(disp_shapes.min_x,e),max(disp_shapes.max_x,e),min(disp_shapes.min_y,t),max(disp_shapes.max_y,t)end foreach(particles,function(n)if xks_active then n.t+=1n.t%=16end end)end,function(_ENV)rectfill(x+1,y+1,zj()-1,zl()-1,0)if not xks_active then palsplit"1,2,5,4,5,6,7,5,6,6,11,13,13,13,15"end local d={}foreach(particles,function(n)local e,t=(n.x+cx*n.z-65)%(hb.w-2)+1+x,(n.y+cy*n.z-65)%(hb.h-2)+1+y local o,f,l,i=displace(disp_shapes,e,t)o=max(6-o,0)e+=f*i*o t+=l*i*o if n.s<.2and n.t<=8then add(d,{e,t,n.c})else pset(e,t,n.c)end end)foreach(d,function(n)local n,e,t=unpack(n)line(n-1,e,n+1,e,t)line(n,e-1,n,e+1,t)end)pal()local n=xks_active and 7or 5draw_ze(_ENV,x,zj(),draw_y,ysegs,false,n)draw_ze(_ENV,y,zl(),draw_x,xsegs,true,n)for e in all{x+1,zj()-1}do for t in all{y+1,zl()-1}do pset(e,t,n)end end end)function displace(n,t,o)local e,d,f,l,i=10000,0,0,0,0if t>=n.min_x-20and t<=n.max_x+20and o>=n.min_y-20and o<=n.max_y+20then for n in all(n)do local n,r,a=unpack(n)if abs(t-n)+abs(o-r)<=20then local n,t=t-n,o-r local o=atan2(n,t)local o=n*cos(o)+t*sin(o)local r=abs(o-a)if r<e then e,d,f,l,i=r,o,n,t,a end end end end if e>10then return e,0,0,0end local n=sign(d-i)/d local n,t=n*f,n*l return e,n,t,(15-i)/15end xl=create_type(function(_ENV)hb.h=24end,function(_ENV)if not done and yc()then n.co_trans,done=cocreate(circ_transition),true end end,function(_ENV)palt"0"spr(148,x,y,1,3)palt()end)mirror=create_type(function(_ENV)hb=zh(args"-5,-20,42,60")yb[[yh reflect_off,0
yh mirror_col,12
yh ze,false]]end,function(_ENV)if p and not yc()and not cutscene and not n.mirror_broken then p.zc.x,p.dash_time=0,0n.cutscene,n.cutscene_env,n.pause_xb=cocreate(mirror_cutscene),_ENV,true else p=p or yc()end end,function(_ENV)rectfill(x+3,y+7,x+28,y+23,mirror_col)if p then palsplit"8,2,1,4,5,6,5,2,9,10,11,8,13,14,15"clip(x+3-cx+64,y+7-cy+64,26,17)draw_hair(p,reflect_off)spr(p.za,2*x-p.x+24+reflect_off,p.y,1,1,not p.zb.x)pal()clip()end palt"0x80"camera(draw_x-x,draw_y-y)if broken then spr(args"128,0,4,4,2.5")else sspr(args"0,84,32,12,0,4")spr(args"132,0,16,4,1")end camera(draw_x,draw_y)palt()end)function mirror_cutscene(_ENV)yb[[music -1,500
wait 30
music 16,500]]p.zb.x=not p.zb.x wait"20"p.h_input=sgn(x+6-p.x)while(abs(x+6-p.x)>1)yield()
p.h_input,p.zc.x=0,0yield()p.zb.x=false wait"30"n.co_trans=cocreate(cutscene_transition)yb[[sfx 10
wait 50]]for n=0,-3,-1do reflect_off=n yield()end yb[[wait 30
sfx 8]]for n=1,6do mirror_col=split"12,7"[n%2+1]wait"2"end yb[[wait 15
yh reflect_off,-128
yh broken,True
yk sk,2]]baddy=init_object(xa,197-p.x,p.y)baddy.zb.x=true yb[[ye 4,8
ye 24,8]]wait(3,rectfill,x,y+5,x+32,y+23,7)baddy.yb[[wait 20
yh h_input,-1
wait 10
yh j_input,True
wait 10
yh d_input,True
wait 50]]destroy_object(baddy)p.u_input=true while(n.coy>-60)n.coy+=-12-.2*n.coy yield()
yb[[yk xks_active,True]]block=zp(xk,0,-16)block.ze_size=2yb[[yk sk,100
sfx 28
yh pitch,-6]]for n=block.zl()-1,block.y+8,-.5do rectfill(block.x+1,block.y+1,block.zj()-1,n,7)if n%2<.5then for e=1,block.hb.w,8do block.ye(e-3,n-block.y-8)end end poke(14704,204+pitch)poke(14706,211+pitch)pitch+=.5yield()end block.yb[[sfx 28,-2
sfx 27
yk sk,0
wait 3
yh ze_size,1
wait 3
yh ze_size,0
music 17,0,7
wait 20]]while(n.coy<-1)n.coy+=-.2*n.coy yield()
p.yb[[yk coy,0
yk mirror_broken,True
yh u_input,false]]end function wait(n,e,...)for n=1,n do(e or stat)(...)yield()end end xa=create_type(function(_ENV)xb.init(_ENV)create_hair(_ENV)end,xb.update,function(_ENV)palsplit"8,2,1,4,5,6,5,2,9,10,11,8,13,14,15"draw_hair(_ENV)draw_obj_za(_ENV)pal()end)function cutscene_transition()for n=1,305do local e,n=n<=15and n or n<=245and 15or 306-n,n<=245and 15or 60local n=15-15*(1-e/n)^3camera()rectfill(0,0,128,n,0)rectfill(0,128-n,args"128, 128, 0")yield()end end campfire=create_type(function(_ENV)yb[[yh off,0
yh layer,0
yh ze,false]]end,function(_ENV)off+=.2end,function(_ENV)camera(-x,-y)yb[[rectfill -8,0,16,8,0
spr 8,0,0,2,1]]if stars_falling then palsplit"1,2,3,4,5,6,7,11,7"end spr(split"12,13,14"[flr(off)%3+1],4,-2)pal()camera()end)memorial=create_type(function(_ENV)index,text,hb.w,ze=6,"-- celeste mountain --\nthis memorial to those\n perished on the climb",16end,nil,function(_ENV)camera(-x,-y)yb[[spr 149,0,-16,2,3
spr 183,4,-24
camera]]if yc()then if stars_falling then for n=1,8do pos=rnd(#text)+1c=n<=3and rnd(split(text,""))or text[pos]if ptext[pos]~="\n"and c~="\n"then ptext=sub(ptext,1,pos-1)..c..sub(ptext,pos+1)end end end index+=.5?"⁶x5⁶y8"..sub(ptext,1,index),args"8,16,7"
if index%1==0and index<#text then?"⁷s4i6<<<x5d#4"
end else yb[[yh ptext,text
yh index,0]]end end)end_screen=create_type(function(_ENV)foreach(fruitrain,function(e)n.bc+=1if e.golden then yb[[yk collected_golden,True]]end end)end,nil,function(_ENV)yb[[rectfill 17,16,110,91,7
rectfill 16,17,111,91,7
rectfill 15,18,112,91,7
rectfill 15,92,112,110,6
rectfill 16,92,111,111,6
rectfill 17,92,110,112,6
rectfill 15,22,113,42,1
rectfill 16,23,113,41,3
rectfill 15,43,112,43,6
fillp 0b1100000000000000.1000
rectfill 15,92,112,92,13
fillp]]for n=7,16do line(n,16+n,18,16+n,3)line(n,16+n,n+3,16+n,10)line(n,48-n,18,48-n,3)line(n,48-n,n+3,48-n,10)end?"⁶jd6⁴iᶜbCHAPTER 2⁶je8⁴iᶜ7old site⁶j7p³jᶜ0chapter complete!⁶jdc⁵jjᶜ0⁙ "..bc.."/18⁶jdj⁵jhᶜ0⁙ ⁶jdg³jᶜ0⁙ "..ds
draw_time(args"63,77,0")palsplit"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"berry_za=collected_golden and 11or 10yb[[spr berry_za,43,49
spr berry_za,41,49
spr berry_za,42,50
spr berry_za,42,48
spr 151,43,63
spr 151,41,63
spr 151,42,64
spr 151,42,62
spr 167,43,76
spr 167,41,76
spr 167,42,77
spr 167,42,75
spr 212,94,25,2,2
spr 212,92,25,2,2
spr 212,93,26,2,2
spr 212,93,24,2,2
pal
spr berry_za,42,49
spr 151,42,63
spr 167,42,76
spr 212,93,25,2,2]]end)psfx=function(n)if st<=0then sfx(n)end end tiles={}foreach(split([[1,xb_spawn
8,campfire
10,fruit
11,fruit
15,xe
23,xf
66,xg
68,xh
71,xi
88,xj
64,xk
6,xl
7,end_screen
181,memorial
128,mirror
]],"\n"),function(n)local n,e=unpack(split(n))tiles[n]=_ENV[e]end)function init_object(e,t,o,i)local d=lvl_id==29and"320,48,2"or t..","..o..","..(linked_levels[lvl_id]or lvl_id)if e.zp_fruit and got_fruit[d]then return end local _ENV=setmetatable({},{__index=n})type,yg,za,zb,x,y,hb,zc,zd,fruit_id,ze,draw_seed=e,true,i,zg(),t,o,zh(args"0,0,8,8"),zerovec(),zerovec(),d,true,rnd()function zi()return x+hb.x end function zj()return zi()+hb.w-1end function zk()return y+hb.y end function zl()return zk()+hb.h-1end function zm(n,e,o)for t in all(obj_bins.solids)do if t~=_ENV and(t.solid_obj or t.semisolid_obj and not ya(t,n,0)and e>0)and ya(t,n,e)and not(o and t.unsafe_ground)then return true end end return e>0and not is_flag(n,0,3)and is_flag(n,e,3)or is_flag(n,e,0)or zp(xk,n,e)and(not xks_active or dash_effect_time<=2or not zp(xk,sign(dash_target_x),sign(dash_target_y))and not dreaming)end function oob(n,e)return not exit_zi and zi()+n<0or not exit_zj and zj()+n>=lvl_pw or zk()+e<=-8end function is_flag(e,t,n)for o=mid(0,lvl_w-1,(zi()+e)\8),mid(0,lvl_w-1,(zj()+e)/8)do for e=mid(0,lvl_h-1,(zk()+t)\8),mid(0,lvl_h-1,(zl()+t)/8)do local t=tile_at(o,e)if n>=0then if fget(t,n)and(n~=3or e*8>zl())then return true end elseif({zc.y>=0and zl()%8>=6,zc.y<=0and zk()%8<=2,zc.x<=0and zi()%8<=2,zc.x>=0and zj()%8>=6})[t-15]then return true end end end end function ya(n,e,t)return n.yg and n.zj()>=zi()+e and n.zl()>=zk()+t and n.zi()<=zj()+e and n.zk()<=zl()+t end function zp(e,t,o)for n in all(obj_bins[e])do if n.type==e and n~=_ENV and ya(n,t,o)then return n end end end function yc()return zp(xb,0,0)end function yd(e,t,i)for n in all{"x","y"}do zd[n]+=zg(e,t)[n]local e=round(zd[n])zd[n]-=e local d=n=="y"and e<0local t,o=not yc()and zp(xb,0,d and e or-1)if collides then local t,f=sign(e),_ENV[n]local d=n=="x"and t or 0for e=i,abs(e)do if zm(d,t-d)or oob(d,t-d)then zc[n],zd[n]=0,0 break else _ENV[n]+=t end end o=_ENV[n]-f else o=e if(solid_obj or semisolid_obj)and d and t then o+=zk()-zl()-1local n=round(t.zc.y+t.zd.y)n+=sign(n)if o<n then t.zc.y=max(t.zc.y)else o=0end end _ENV[n]+=e end if(solid_obj or semisolid_obj)and yg then yg=false local d=yc()if d and solid_obj then d.yd(n~="x"and 0or e>0and zj()+1-d.zi()or e<0and zi()-d.zj()-1,n~="y"and 0or e>0and zl()+1-d.zk()or e<0and zk()-d.zl()-1,1)if yc()then kill_xb(d)end elseif t then t.yd(zg(o,0)[n],zg(0,o)[n],1)end yg=true end end end function ye(n,e)init_object(smoke,x+(n or 0),y+(e or 0),26)end function yh(e,n)_ENV[e]=_ENV[n]or n end function yb(e)n.yb(e,_ENV)end add(xd,_ENV)obj_bins[type]=obj_bins[type]or{}add(obj_bins[type],_ENV);(type.init or time)(_ENV)if solid_obj or semisolid_obj then add(obj_bins.solids,_ENV)end return _ENV end function destroy_object(n)del(xd,n)del(obj_bins[n.type],n)del(obj_bins.solids,n)end function kill_xb(n)st,sk=12,9sfx"17"sfx(28,-2)ds+=1destroy_object(n)for e=0,.875,.125do add(dead_particles,bt("x,y,t,dx,dy",{n.x+4,n.y+4,2,sin(e)*3,cos(e)*3}))end foreach(fruitrain,function(n)full_restart=full_restart or n.golden end)fruitrain={}co_trans=cocreate(transition)end function next_level()local n=music_triggers[lvl_id]if lvl_id==31then for n=14772,15520,68do poke(n+65,20)end end if n then music(args(n))end load_level(lvl_id+1)end function load_level(n)foreach(xd,destroy_object)ut,ce,cz,has_dashed=5,0,0local e=lvl_id~=n lvl_id=n local n=split(levels[lvl_id])for e=1,4do _ENV[split"lvl_x,lvl_y,lvl_w,lvl_h"[e]]=n[e]*16end lvl_pw,lvl_ph=lvl_w*8,lvl_h*8bad_num=n[7]or 0local t=tonum(n[5])or 1for n,e in inext,split"exit_zk,exit_zj,exit_zl,exit_zi"do _ENV[e]=t&.5<<n~=0end entrance_dir=tonum(n[6])or 0if e then reload(4096,4096,8192)end if mapdata[lvl_id]then lvl_x,lvl_y=0,0if e then for n=0,#mapdata[lvl_id]-1do mset(n%lvl_w,n\lvl_w,ord(mapdata[lvl_id][n+1])-1)end end end cox,coy=0,0local n=camera_offsets[lvl_id]if n~="{}"then for n in all(split(n,"|"))do local n,e,t,o,d,i=unpack(split(n))local _ENV=init_object(camera_trigger,n*8,e*8)hb.w,hb.h,offx,offy=t*8,o*8,d,i end end for e=0,lvl_w-1do for t=0,lvl_h-1do local n=tile_at(e,t)if tiles[n]then init_object(tiles[n],e*8,t*8,n)end end end for n=1,bad_num do init_object(badeline,0,0)end foreach(xd,function(_ENV)(type.end_init or time)(_ENV)end)end function _update()fs+=1if lvl_id<=35and tl==0then ss+=fs\30ms+=ss\60ss%=60ss_f=fs%30end fs%=30st=max(st-1)if freeze>0then freeze-=1return end if btnp(⬆️,1)then screensk=not screensk end if dr>0then ce,cz=0,0dr-=1if dr==0then if full_restart then full_restart=false _init()else load_level(lvl_id)end end end foreach(xd,function(_ENV)yd(zc.x,zc.y,(type==xb or type==xa)and 0or 1);(type.update or time)(_ENV)draw_seed=rnd()end)local n=find_xb()if n then ce,cz=cg*(4+n.x-cx+cox),cg*(4+n.y-cy+coy)cx+=ce cy+=cz local n,e=mid(cx,64,lvl_pw-64),mid(cy,64,lvl_ph-64)if cx~=n then ce,cx=0,n end if cy~=e then cz,cy=0,e end end end function _draw()if freeze>0then return end pal()draw_x,draw_y=round(cx)-64,round(cy)-64if sk>0then sk-=1if screensk then draw_x+=-2+rnd"5"draw_y+=-2+rnd"5"end end cls()if tl>0then local n,t,e=flr(15*(1-tl)),ceil(28*(1-tl)),flr(30*(1-tl))yb[[_camera
rectfill 0,60,128,128,1
fillp 0b1111000011110000
rectfill 0,50,128,60,1
fillp
spr 192,23,2,8,1
spr 208,87,2,3,1
spr 224,34,12,4,1
spr 240,66,12,4,1]]?args"•-                       -•, 10, 8, 7"
?args"based on celeste by exok games, 5, 120, 13"
tmp_a,tmp_b,tmp_c,tmp_d,tmp_e,tmp_f,tmp_g,tmp_h=9-n,22-t,118+n,116+e,15-n,28-t,112+n,97+e yb[[rectfill tmp_a,tmp_b,tmp_c,tmp_d,7
rectfill tmp_e,tmp_f,tmp_g,tmp_h,0
color 1
pset tmp_a,tmp_b
pset tmp_a,tmp_d
pset tmp_c,tmp_b
pset tmp_c,tmp_d]]?"press 🅾️/❎",42,101+e,13
?"by the n.p8 team",32,109+e,1
clip(15-n,28-t,98+n*2,70+t+e)end for i=stars_falling and-4or 0,0do foreach(stars,function(n)local f,t,d=n.x,n.y,flr(min(1,sin(n.off)*2))local o=t+i local e=o<t and d-1or d if o~=t then palsplit"1,2,3,4,5,1,1,8,9,10,11,12,1"elseif stars_falling then palsplit"1,2,3,4,5,12,6,8,9,10,11,12,12"end camera(-f,-o)if e<=-2then pset(0,0,stars_falling and(o==t and 12or 1)or 7)end if n.size==2then if e==-1then yb[[spr 73,-3,-3]]elseif e==0then yb[[line -5,0,5,0,13
line 0,-5,0,5,13
spr 74,-3,-3]]elseif e>0then yb[[spr 89,-7,-7,1.875,1.875]]end else if e==-1then yb[[line -1,-1,1,1,13
line -1,1,1,-1,13]]elseif d>-1then yb[[line -2,-2,2,2,13
line -2,2,2,-2,13]]end end if i==0then n.x+=-ce/4*(2-n.size)n.y+=-cz/4*(2-n.size)n.off+=.01if n.x>128then n.x=-8n.y=rnd"120"elseif n.x<-8then n.x=128n.y=rnd"120"end if stars_falling then n.y+=n.zcy if n.y>128then n.y=-8n.x=rnd"120"n.zcy=rnd"0.75"+.5end pal()end end end)end camera(draw_x,draw_y)map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4)palsplit"1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"pal=time foreach(xd,function(_ENV)if ze then for n=1,4do camera(draw_x+split"-1,0,0,1"[n],draw_y+split"0,-1,1,0"[n])draw_object(_ENV)end end end)pal=_pal camera(draw_x,draw_y)pal()local e={{},{},{}}foreach(xd,function(_ENV)if layer==0then draw_object(_ENV)else add(e[layer or 1],_ENV)end end)palt"0x80"map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,2)palt()foreach(e,function(n)foreach(n,draw_object)end)map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,8)foreach(dead_particles,function(_ENV)x+=dx y+=dy t-=.2if t<=0then n.del(n.dead_particles,_ENV)end rectfill(x-t,y-t,x+t,y+t,14+5*t%2)end)if cutscene then coresume(cutscene,cutscene_env)if costatus(cutscene)=="dead"then pause_xb,cutscene,cutscene_env=false end end if ut>=-30then if ut<0then rectfill(draw_x+4,draw_y+4,draw_x+48,draw_y+10,0)draw_time(draw_x+5,draw_y+5,7)end ut-=1end if(co_trans and costatus(co_trans)~="dead")coresume(co_trans)
color"0"end function draw_object(_ENV)srand(draw_seed);(type.draw or draw_obj_za)(_ENV)end function draw_obj_za(_ENV)spr(za,x,y,1,1,zb.x,zb.y)end function draw_time(n,e,t)?two_digit_str(ms\60)..":"..two_digit_str(ms%60)..":"..two_digit_str(ss).."."..two_digit_str(round(ss_f/30*100)),n,e,t
end function two_digit_str(n)return sub("0"..n,-2)end function round(n)return flr(n+.5)end function appr(n,t,e)return mid(n-e,n+e,t)end function sign(n)return n~=0and sgn(n)or 0end function args(n)return unpack(split(n))end function palsplit(n)pal(split(n))end function zerovec()return zg(0,0)end function tile_at(n,e)return mget(lvl_x+n,lvl_y+e)end function spikes_at(n,e,t,o,d,i)for f=max(0,n\8),min(lvl_w-1,t/8)do for l=max(0,e\8),min(lvl_h-1,o/8)do if({o%8>=6and i>=0,e%8<=2and i<=0,n%8<=2and d<=0,t%8>=6and d>=0})[tile_at(f,l)-15]then return true end end end end function transition(n)local t={}for e=0,7do for d=0,7do local o=rnd"1.5"+(n and 6-e or e)add(t,bt("x,y,delay,radius",{(e-.8+rnd"0.6")*20,(d-.8+rnd"0.6")*20,o,n and 30-2*o or 0}))end end for e=1,15do camera()local e=circfill foreach(t,function(_ENV)if not n then delay-=1if delay<=0then radius+=2end elseif radius>0then radius-=2else radius=0end if(radius>0)e(x,y,radius,0)
end)yield()end if not n then dr=1for n=1,3do cls()yield()end co_trans=cocreate(transition)coresume(co_trans,true)end end function circ_transition()local n=find_xb()n.zc,pause_xb=zerovec(),true sfx"26"radii=split"128,120,112,104,96,88,80,72,64,56,48,40,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,28,24,20,16,12,8,4,0,0,0,0,0,0,0,0,0,0,0,0,4,8,12,16,20,24,28,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,40,48,56,64,72,80,88,96,104,112,120,128"s=""for e,t in ipairs(radii)do if e==48then n,stars_falling,pause_xb=zg(64,64),next_level()local e=find_xb()if e then n=zg(e.x,e.target)end end inv_circle(n.x+4,n.y+4,t)yield()end end function inv_circle(e,t,n)color"0"rectfill(-1,-1,128,t-n)rectfill(-1,t+n,128,128)rectfill(-1,-1,e-n,128)rectfill(e+n,-1,128,128)for o=n,n*sqrt"2"+1do for n=0,3do circ(e+n\2,t+n%2,o)end end end function find_xb()for _ENV in all(xd)do if type==xb or type==xb_spawn then return _ENV end end end levels=split([[0,0,1,1,0b0010,6,0,
  -3.5,2.9375,3,1,0b0100,4,0,
  0.3125,-2.0625,1.1875,2,0b0010,2,0,
  -1.25,1,1.25,1,0b0010,4,0,
  0,1,1,1,0b0010,4,0,0,
  1,1,2,1,0b0010,4,0,
  1.75,-1.875,1.3125,1.5,0b1000,4,0,
  1.5625,4.3125,1.4375,1.3125,0b1000,5,0,
  2,2,2,1,0b1001,5,0,
  -1.25,-2.0625,1.1875,2,0b1000,5,0,
  3,3,1,1,0b0001,5,0,0,
  -3.5,4,3,1,0b0001,0,0,
  7,0,1,1,0b0001,0,0,
  5,0,1,1,0b0001,0,1,
  2,3,1,1,0b0001,0,1,0,
  5.9375,-4.1875,1,1.4375,0b0001,1,2,
  1,0,1,1,0b0010,0,1,
  2,0,1,1,0b0001,4,2,
  3,0,1,1,0b0010,0,1,
  4,0,1,1,0b0001,4,2,
  7,1,1,1,0b0001,0,3,
  7,2,1,1,0b0001,0,1,
  9.5,-2.5,1,2,0b0010,0,2,
  10.5,-2.5,2,1,0b0010,4,1,
  12.5,-2.5,3,1,0b0010,4,2,
  15.5,-2.5,1,2,0b0010,4,1,
  10.1875,0.375,1,2.0625,0b0100,2,2,
  6,0,1,4,0b0100,2,4,
  -0.1875,5.6875,2,1.5,0b0010,2,0,0,
  3,1,3,1,0b0010,4,0,
  7,3,1,1,0b0000,4,0,
  0,0,1,1,0b0010,6,0,
  0,3,3,1,0b0010,4,0,0,
  3,3,3,1,0b0010,4,0,
  7,3,1,1,0b0000,4,0,
  8.125,3.875,0.0625,0.0625,0b0001,4,0,0]],"\n")camera_offsets=split([[{}
25,4,2,5,-18,0|29,3,2,8,0,0
{}
{}
{}
16,2,1,5,16,0|15,2,1,5,0,0
6,11,1,7,74,0|4,15,1,3,0,0|10,8,7,1,24,0|10,12,7,1,56,0
12,6,2,8,-20,56|20,15,1,1,0,56|14,6,5,1,0,0|14,8,7,1,0,56
{}
{}
{}
25,4,2,5,-18,0|29,3,2,8,0,0
{}
{}
{}
1,16,15,1,0,0|1,14,3,1,0,-32
{}
{}
{}
{}
{}
{}
11,17,4,3,0,0|4,7,4,3,0,20
{}
13,2,2,14,32,0
0,1,6,1,0,24
9,12,5,1,0,16
1,19,3,5,0,24|1,17,3,2,0,0
{}
0,7,5,5,20,0
{}
{}
{}
{}
{}
{}]],"\n")mapdata={nil,"!&&&9'&`¹233339&!&&&&3333&&9&'■■■■■%9&'¹¹¹¹¹¹¹¹¹333!&4V&`¹¹^&V%&&&9&4;-)&%9&&!######&&',¹¹L¹¹¹¹¹&○o%'om&&__o&&%9&&&'&¹Q-&%!3333&&&!&&&&-,¹\\¹¹¹¹¹p¹n%'mmVWo&&V\"9&339'█t:=-24█¹¹⁘%!33333&&=$\\¹¹¹¹¹█¹n%9##$g&ABB%!4○&%'¹t¹QRop¹¹¹⁘24¹¹¹~o2333,`¹^`¹¹¹~%&33!#$B¹¹%'p¹n24¹u¹:<&&`¹¹¹□□¹¹¹¹n&○○oQ,¹np¹¹¹¹24V&2&'B¹¹24p¹~█¹¹¹¹¹¹o&p¹¹¹¹¹¹¹■■~█¹ᵇnQR^op¹¹¹¹¹¹~p¹%'B¹¹&█¹¹¹t¹¹¹¹¹¹nVp¹¹¹¹¹w¹゛$¹¹¹¹~Q),&V`¹¹¹¹¹¹l¹2'B¹¹p¹¹¹¹t¹¹¹q¹¹no█¹¹¹¹¹◀▶%'ma¹¹*-=Ro&p¹¹¹¹¹¹¹¹~8B¹¹p¹¹¹¹m¹¹NMNN゛$¹¹¹¹¹¹¹^24‖◀◀▶Q&&=,o&¹¹¹¹¹¹¹¹¹¹~&op¹^`¹¹¹¹¹O¹^%0■■¹¹¹¹^Vp¹¹¹¹¹Q=&&-+,¹¹¹¹¹¹¹¹¹¹¹nV&_op¹¹¹¹゛ ¹n%&#$¹¹¹¹n&o`¹¹¹*))&&&&-¹²¹¹¹¹¹¹¹¹¹n&&h&paL¹¹.'^&%&90¹¹S_*++$■■*-=&;-&&&++,¹¹¹¹¹¹¹^o&Vi*++,■■%'&o.&&0¹¹¹~Q-)=$‖▶%)RV:=9&=)-++,‖◀▶\"####+)-)&##90V&.!&0■■■■:&&&'¹^%&R&o%!&&&&)=R¹¹¹%!&&!)-&&-&&&0o&.&&9##゜゜=&&=R^N%9'o&%&!","&&&&&&&0&○○.&&&&&&&&&&&&&/@█²¹>/&&&&&&&&&&/?@█¹¹¹~>?/&&&/&&&/0v¹¹¹¹¹¹~○.&/&&????@¹¹¹¹¹¹¹¹¹>??/&¹ABBB¹¹¹¹¹¹¹¹¹vtt.&¹B¹¹¹¹¹¹¹¹¹¹¹¹¹tv./¹B¹¹¹¹¹¹¹¹¹¹¹¹¹u¹.&゜゜゜ P¹¹¹¹¹¹¹¹¹¹¹¹.&&&/0¹¹¹¹¹¹¹¹¹¹¹¹¹./&&&0‖◀◀¹¹¹¹¹¹¹¹¹¹./&/?@`¹¹¹¹¹¹¹゛ ‖◀▶>/&0○&&`¹¹¹¹¹¹.0¹¹¹¹>&0¹~○゛ ABBB゛/0¹¹¹¹¹&0¹¹¹>0B¹¹¹>/0¹¹u¹¹&0¹¹¹¹x¹¹~○&>/ au¹a&/,¹¹¹¹¹¹¹¹~&>/゜゜゜゜&/-+,¹¹¹¹¹¹¹~○:--/&&&/-R¹¹¹¹¹¹¹¹¹¹Q-.&&&&//゜ ‖◀¹¹¹¹¹¹Q-.&&/????@■■■■■■¹¹:;.&&0¹¹¹ABBBBBBB¹¹]N.&/0¹ᵇ¹B¹¹¹¹¹¹¹¹¹¹].&/@¹¹¹B¹¹¹¹¹¹¹¹¹¹¹.&0⁙¹¹¹゛゜゜゜゜}¹¹¹¹¹¹./0⁙¹¹^>???@v¹¹¹¹¹¹>?0⁙¹¹~V&&&█¹¹¹¹¹¹¹~&0⁙¹¹¹~T&p¹¹¹¹¹¹¹¹¹n0⁙¹¹¹¹n&p¹¹¹wrsa¹¹n0■¹¹¹¹n&`¹¹゛゜゜゜゜゜゜゜/ ⁙¹^_&&&\\_.//&&/&/&0⁙^&&&&o&&./&&&&&&","???/&&&/?????/&&&&&&&o○>?&/@t¹t¹n>?/&/??V█¹¹n.@¹t¹u¹~&V.?@o&p¹¹¹~y⁙¹t¹¹¹¹n&yV&&Vp²¹¹¹y⁙¹u¹■■¹~ox○○&&゜゜}¹¹y⁙¹¹¹゛ ¹¹~█¹¹~o/@¹¹¹x⁙¹¹¹.0¹¹¹¹¹¹¹n0¹a¹¹¹¹¹▮¹.0¹▮¹¹¹¹¹n0NMNP¹¹¹¹¹.0¹¹¹¹¹◀▶゛0NNP¹¹¹¹¹^.0__`¹¹¹¹.0¹¹¹¹¹¹¹^o.0&o○U¹¹■.0■¹¹¹¹¹¹~○.0○█¹¹¹¹゛// ¹¹¹¹¹■■■.0■¹¹¹¹■.&&0■■■■■゛゜゜// ■■■■゛/&&/゜゜゜゜゜/&&&&/゜゜゜゜/&&&&&&//&&&&&&&&&//&&&",nil,nil,"&&/&&&&&/??//?//?/&&&&/???//?@&○.@¹>@v>?/&?@&&o>@█○█¹x¹¹¹t¹~&.&&V&&V█¹¹¹¹¹t¹¹¹v¹¹n>/o&V&p¹¹¹¹¹¹u¹¹¹¹¹¹~&.゜゜゜゜゜゜ ¹¹¹¹¹¹¹¹¹¹¹¹n.&&&&&/0u¹¹¹¹¹¹¹¹¹aq゛/&&&&&&/゜ ¹¹¹¹¹¹¹゛゜゜//&&&&&&&&/ ABBBBB.//&&&&&&&&&/&0B¹¹¹¹¹.&&&&&&&&&/??/0B¹¹¹¹¹./&&&&&&&&0&&>0B¹¹¹¹¹.??/&&&&&&0&○○xB¹¹¹¹¹x~&.&&&&//@█¹¹¹B¹¹¹¹¹¹¹n.&/???@█¹¹¹¹¹¹¹¹¹¹¹¹~.&0○○█¹¹¹¹¹¹¹¹¹¹¹¹¹¹O>/0ma¹¹¹¹¹¹¹¹▒¹¹¹¹¹¹O¹.0mm¹¹¹²¹¹¹¹¹¹¹¹¹¹]NM.0mm゛゜゜}¹¹¹¹¹¹¹¹¹¹¹¹O.@‖▶./0¹¹¹゛゜゜゜゜゜゜ ¹m゛/p¹¹./0ma¹.//&/&/0wm.&p¹¹.&/゜゜゜/&&&&&&/゜゜/&&`u./&&//&&&&&&&&&&&&゜゜゜/&&&&&&&&&&&&&&&&&","&&&&&&&&&&&&&/?????/&&&&&&&&&&&&&&&/@o&█¹¹>/&&&&&&&&&&&&&/0V&pᵇ¹¹¹.&&&&&&&&&&&&&/0&W&_`¹¹./&&&&&//&&&&&&/ gV&o`゛&&&&/????/&&//&&0ABBBB./&&/@tt¹v>????/&0B¹¹¹¹>?/&@¹vt¹¹¹¹¹¹¹>?0B¹¹¹¹¹¹.&¹¹¹u¹¹¹¹¹¹¹¹OxB¹¹¹¹NN./¹¹¹¹■■■■■¹¹¹O¹B¹¹¹¹P¹./¹¹¹¹ABBBB¹amOqB¹¹¹¹¹^>/゜ ‖¹B¹¹¹¹NNMNNB¹¹¹¹¹no./0¹¹B¹¹¹¹¹¹O¹¹B¹¹¹^^&&>&@¹¹B¹¹¹¹¹¹O¹¹B¹¹¹n&V○o0¹¹¹¹¹¹¹¹¹¹O゛ B¹¹¹nV█¹n0■¹¹¹¹¹¹¹¹*+/0B¹¹¹np²¹n&,¹¹¹¹¹¹¹*-=&/゜゜゜゜゜゜゜゜゜-R■■■■■■■Q&&&&&//&/&&//&)+゜++゜゜+)&&&&&&&&&&&&&&&&-=&-/=&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&",nil,"&&&&&&&0;-=.&&&&&&&&&&&&&/@○:;>/&&&&&&&&&&/?@█¹¹¹~>?/&&&/&&&/0v¹¹¹¹¹¹~○.&/&&????@¹¹¹¹¹¹¹¹¹>??/&¹ABBB¹¹¹¹¹¹¹¹¹vtt.&¹B¹¹¹¹¹¹¹¹¹¹¹¹¹tv./¹B¹¹¹¹¹¹¹¹¹¹¹¹¹u¹.&゜゜゜ P¹¹¹¹¹¹¹¹¹¹¹¹.&&&/0¹¹¹¹¹¹¹¹¹¹¹¹¹./&&&0‖◀◀¹¹¹¹¹¹¹¹¹¹./&/?@`¹¹¹¹¹¹¹゛ ‖◀▶>/&0○&&`¹¹¹¹¹¹.0¹¹¹¹>&0¹~○゛ ABBB゛/0¹¹¹¹¹&0¹¹¹>0B¹¹¹>/0¹¹u¹¹&0¹¹¹¹x¹¹~○&>/ au²a&/,¹¹¹¹¹¹¹¹~&>/゜゜゜゜&/-+,¹¹¹¹¹¹¹~○:;;/&&&/-R¹¹¹¹¹¹¹¹¹¹n&.&&&&//゜ ‖◀¹¹¹¹¹¹n&.&&/????@■■■■■■¹¹~o.&&0¹¹¹ABBBBBBB¹¹¹~.&/0¹ᵇ¹B¹¹¹¹¹¹¹¹¹¹¹.&/@¹¹¹B¹¹¹¹¹¹¹¹¹¹¹.&0⁙¹¹¹゛゜゜゜゜}¹¹¹¹¹¹./0⁙¹¹^>???@v¹¹¹¹¹*>?0⁙¹¹~V&&&█¹¹¹¹¹¹Q=-0⁙¹¹¹~T&p¹¹¹¹¹¹¹Q-=0⁙¹¹¹¹n&p¹¹¹wrs*-=-0■¹¹¹¹n&`¹¹゛゜゜゜゜゜゜゜/ ⁙¹^_&&&\\_.//&&/&//0⁙^&&&&o&&./&&&&&&",nil,"!&&&9'&`¹233339&!&&&&3333&&9&'■■■■■%9&'¹¹¹¹¹¹¹¹¹333!&4V&`¹¹^&V%&&&9&4o&&V%9&&!######&&',¹¹L¹¹¹¹¹&○o%'om&&__o&&%9&&&'&○○&&%!3333&&&!&&&&-,¹\\¹¹¹¹¹p¹n%'mmVWo&&V\"9&339'█t¹~V24█¹¹⁘%!33333&&=$\\¹¹¹¹¹█¹n%9##$g&ABB%!4○&%'¹t¹¹nop¹¹¹⁘24¹¹¹~o2333,`¹^`¹¹¹~%&33!#$B¹¹%'p¹n24¹u¹¹n&&`¹¹¹□□¹¹¹¹n&○○oQ,¹np¹¹¹¹24V&2&'B¹¹24p¹~█¹¹¹¹¹~o&p¹¹¹¹¹¹¹■■~█¹ᵇnQR^op¹¹¹¹¹¹~p¹%'B¹¹&█¹¹¹t¹¹¹¹¹¹nVp¹¹¹¹¹w¹゛$¹¹¹¹~Q),&V`¹¹¹¹¹¹l¹2'B¹¹p¹¹¹¹t¹¹¹q¹¹no█¹¹¹¹¹◀▶%'ma¹¹*-=Ro&p¹¹¹¹¹¹¹¹~8B¹¹p¹¹¹¹m¹¹NMNN゛$¹¹¹¹¹¹¹^24‖◀◀▶Q&&=,o&¹¹¹¹¹¹¹¹¹¹~&op¹^`¹¹¹¹¹O¹^%0■■¹¹¹¹^Vp¹¹¹¹¹Q=&&-+,¹¹¹¹¹¹¹¹¹¹¹nV&_op¹¹¹¹゛ ¹n%&#$¹¹¹¹n&o`¹¹¹*))&&&&-¹¹¹¹¹¹¹¹¹¹¹n&&h&paL¹¹.',&%&90¹¹S_*++$■■*-=&;-&&&++,¹¹¹¹²¹¹^o&Vi*++,■■%'=,.&&0¹¹¹~Q-)=$‖▶%)RV:=9&=)-++,‖◀▶\"####+)-)&##90)-.!&0■■■■:&&&'¹^%&R&o%!&&&&)=R¹¹¹%!&&!)-&&-&&&0-).&&9##゜゜=&&=R^N%9'o&%&!",nil,nil,nil,"¹¹¹¹¹¹¹¹¹¹¹%'&&%¹¹¹¹¹¹¹¹■■■%'AB%¹¹¹■■■■■*++%'B¹%¹¹¹5#6663;;;4B¹%¹¹¹¹1□□□¹¹~○&&&%■¹¹¹1⁙¹¹¹¹¹¹~○○%,■■■1⁙ᵇ¹■■¹¹¹■■%-+++'⁙¹¹\"$■■■\"#9&);9'⁙¹¹%'ABB%!&=<o24⁙¹¹2'B¹¹29&RV&p¹¹¹¹¹8B¹¹¹%&R&o&`¹¹¹¹t¹vt¹29'&&Vp¹¹¹¹t¹▮t¹⁘%'&WV█¹¹¹¹t¹¹u¹⁘%'og█v¹¹¹¹u¹¹¹¹⁘2'‖▶(¹¹¹¹q¹¹¹¹¹¹¹'`¹1¹¹¹¹O¹¹¹¹¹¹¹'o`1¹¹¹¹O¹¹¹¹¹¹¹'&V8■■■¹O¹a¹¹¹¹¹'V○ABBBqO]MPm¹¹■'█OB¹¹¹NMNOmm²¹\"'¹O□□□□¹O¹O(‖◀▶%'¹O¹¹¹¹¹O¹O1¹¹¹%",nil,nil,nil,nil,nil,nil,"¹¹¹¹¹¹^_&*-=!&9&¹¹¹■*#666;;33333¹■■*-4v¹Y¹~○&pHI⁘5+-R¹¹¹¹¹¹¹~█X¹¹t2)4¹¹¹¹wrs¹aX^¹v¹1¹¹¹¹\"#$‖◀▶\"#■■■1`¹¹¹%&'ABB%9+++Ro__`29'B¹¹%&33!R&WV&_%'B¹¹%!¹t24Vg&&o%'B¹¹%9¹u¹ABBBB&2'B¹¹%&¹¹¹B¹¹¹¹█¹1B¹¹%&aE¹B¹¹¹¹¹¹1B¹¹%&##7B¹¹¹¹`¹1B¹¹%&&4¹B¹¹¹¹pE1B¹¹%!'¹¹B¹¹¹¹&`1B¹¹%&4¹¹B¹¹¹¹5#'B¹¹%9¹¹¹B¹¹¹¹o2'B¹¹%!¹¹¹B¹¹¹¹█t1B¹¹%&¹¹¹¹¹(t¹¹t1B¹¹%&¹¹¹E¹1t¹¹v1B¹¹%9¹¹「「「1t¹¹¹1B¹¹%&¹¹¹¹¹1CDDD1B¹¹%&■■■■■1D¹¹¹1B¹¹%&###664¹¹^_1B¹¹%&&34Vp¹¹¹nV1B¹¹%9'&o&█¹¹¹~&8B¹¹%9'V○█¹¹¹¹¹~○o&&%&'█²¹ma¹¹¹¹¹n&V%&'‖◀▶\"$¹¹¹¹^&V&%&'_`¹%'■■■■\"###9&'&&_%9####&&!&&&","&&&&&&&9&&&!&&&&&&!&&&&&333!&&&&&&9&!&&333!333!&&&339&!'a¹~29&&!&3333!'ABB1¹¹¹%&&'□□2334NP¹n2!33'¹t¹t24B¹¹1¹E¹%!9'⁙¹¹~&p¹¹¹~█1Yn4¹t¹v¹¹B¹¹8¹¹¹233'⁙¹¹E~█¹¹¹¹¹8¹~¹¹t¹¹¹¹B¹¹¹¹▮¹ABB1⁙¹¹■■■■■¹¹¹¹HI¹¹v¹¹¹¹B¹¹¹¹¹¹B¹¹1⁙¹¹ABBBB¹¹¹¹X¹¹¹¹¹¹¹¹B¹¹¹¹¹¹B¹¹8⁙¹¹B¹¹¹¹¹¹q▶5#a¹¹¹¹¹¹B¹¹¹¹¹¹B¹¹¹¹¹¹B¹¹¹¹¹qO¹¹%m¹¹¹¹¹¹B¹¹¹¹¹¹B¹¹¹¹¹¹B¹¹¹¹NNMNN%m²m¹¹¹¹B¹¹¹L¹¹B¹¹¹¹L¹¹t¹t¹¹¹Oa¹%##$¹¹¹¹¹tv¹n`¹B¹¹¹^p¹¹t¹u¹¹]NNN%!&'■■■¹¹t¹¹np¹B¹¹¹np¹¹t¹¹¹¹¹¹¹¹Q&&9##$⁙¹v¹^op¹¹*,■n&`¹u¹L¹¹¹¹¹■Q&&&&9'■¹¹¹n&&`■Q=,&&V_U¹\\¹¹¹¹■*-&&&&&!$¹¹¹n&Vp*=)RV&&p¹¹n`¹¹¹*=&","33;;;-'¹¹%&&9!&&'&`¹%&&!9&&-R¹¹¹¹%9&3339&&!=&&&&¹¹¹~V:)##!33333&9###9&3333!&)+,¹a%&4ot○%&33;;-&&¹¹¹¹~&Q=&'V█¹¹~23&&&&4&&○t239&=+#&'p█u¹24¹~○&:=&¹²¹¹¹nQ&!4█¹¹¹¹~o%&94&○█¹t~U23&&-&'█¹¹¹AB¹¹t~oQ=#$¹¹¹~%)'v¹¹¹¹¹¹~%&'oV█¹¹u¹¹~&%&&9'¹¹¹¹B¹¹¹t¹~%)!4¹¹¹¹%!'¹¹¹¹w¹¹¹%!4○¹¹¹¹¹¹¹¹~%&&34¹▮¹¹B¹¹¹v¹¹2&'¹¹¹¹¹%9'¹¹¹\"$¹¹¹24█¹¹¹¹▮¹¹¹¹¹%!4AB¹¹¹¹B¹¹¹¹¹¹v2'¹am¹¹%&']MN2'¹¹¹AB¹¹¹¹¹¹¹¹¹¹¹%'¹B¹¹¹¹⁘\"$¹¹¹¹¹¹¹'NMNP¹234NP¹⁘1¹¹¹B¹¹¹¹¹¹■■■¹m¹%4¹B¹¹¹¹⁘%'¹¹¹¹¹¹¹'NNP¹¹ABB¹¹¹⁘1¹¹¹B¹¹¹¹■■\"#$]MN8v¹B¹¹¹¹⁘%'¹¹¹¹rs¹'¹¹¹¹¹B¹¹¹¹¹⁘8¹¹¹B¹¹¹¹\"#9!4NP¹¹¹¹B¹¹¹¹⁘%'¹¹¹¹\"##'¹¹¹¹¹B¹¹¹¹¹¹t¹¹¹B¹¹¹¹2!&'v¹¹¹¹¹¹B¹¹¹¹⁘%'¹¹¹¹29&'¹¹¹¹¹B¹¹¹¹¹¹u¹¹¹B¹¹¹¹t%&'■■¹¹¹¹¹B¹¹¹¹■%'¹¹¹¹n%&'■■¹¹¹B¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹v%&=+,¹¹¹¹¹¹¹¹¹⁘\"&'■¹¹^o%9)+,`¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹^_%&&-R`¹¹¹¹¹¹¹¹⁘%!&$`¹^&%!&-R&`¹¹¹¹¹¹¹¹¹¹¹¹¹¹^_&V%9&&R&_`¹¹¹¹¹¹⁘%&&'&_&&%&","m¹¹¹¹¹ABBB%&&&&&mm²¹a¹B¹¹¹59&&&&###++,B¹¹¹V5&&!&9&)&-RB¹¹¹&&%!39&&&&=RB¹¹¹&o54o%&&&&!RB¹¹¹V○█¹n%&&&&='B¹¹¹█¹t¹n%&&&39'B¹¹¹¹¹v¹~%&!4V%'B¹¹¹¹¹E¹¹%&'o&2'B¹¹¹¹¹¹¹¹Q&'&○V1B¹¹¹¹¹¹¹¹Q9'pv~1B¹¹¹¹¹¹¹¹Q&'█E¹8B¹¹¹¹¹■■■Q&'¹▮¹¹B¹¹¹■■*++)!4¹¹¹¹B¹¹¹*+=&-&R¹¹¹¹¹B¹¹¹Q)&&&&R¹¹¹¹¹\"#++-&&&&&R¹¹■■■%!&=&&&&&&R¹¹5##33339&&&&&R¹¹□24ABBB2!&&&&R¹¹¹□□B¹¹¹V2&&&&'m¹¹¹¹B¹¹¹&&%&&!'NME¹¹B¹¹¹&V%933'NNMP¹B¹¹¹&&2'Y_'¹¹O¹¹B¹¹¹o&&1^&'¹¹O¹¹B¹¹¹&o█1&o'¹¹¹¹¹B¹¹¹○○v8~█'■¹¹¹¹B¹¹¹¹t¹¹HI9,■■■¹B¹¹¹¹v¹¹X¹&-++$■B¹¹¹¹¹¹¹X¹&&&-!$B¹¹¹arswX¹&&&&&'B¹¹¹\"#####","&&'&&%&&333&9&&&&9'&○%94¹v¹%333!&&'█¹24¹¹¹¹8¹¹¹%!34¹¹⁘ABBBBB¹¹¹%'HI¹¹⁘B¹¹¹¹¹¹E¹%'X¹¹¹¹¹¹(_`¹¹¹¹%'X¹¹²¹¹¹%$&`¹rs%'¹¹\"####9!#####9'__23333333&!&&&'&&○█¹t¹¹~○23&9&'○█¹¹¹u¹¹¹¹O¹%&&'Y¹¹¹¹¹¹■¹¹O]2!&'¹¹¹¹¹¹](¹MPm¹%&'w¹¹¹¹¹¹1NNNNN2!!#$¹¹¹¹¹1¹¹¹¹¹n%&&'¹¹「「¹1¹¹¹¹¹n%&&'■■¹¹¹1¹¹¹¹¹~%&&=+,■■■1¹「「¹¹¹%&&&&-+++'■■■■¹¹%&&&&&&=)!+++,AB%&&&&&&&&&)&-RB¹%&!339&&&!&&!'□□%94○&%&!333334¹¹%'v¹~%!'&○█t¹¹CD%'¹¹¹23'█¹¹t¹¹D¹%'ABB¹¹8CD¹u¹¹D¹%'B¹¹¹¹¹D¹¹¹¹¹¹¹%'B¹¹¹¹¹D¹¹¹¹¹¹¹%'B¹¹¹¹¹D¹¹¹¹¹¹a%'B¹¹■■¹¹¹¹¹¹¹]NQ'B¹¹\",■■■■¹¹¹¹¹%'¹¹¹%-+++,■■■■■Q'¹¹¹%&)=&=+++++)",[29]="&&'¹¹¹¹%&&&&&&&&&&&&&&&&4&&&&&&&&&'¹²¹¹%&&3&&&&&&&&&3334&&V&&&&&&&'¹¹¹¹%&4□%&&&33334&&&&&&&&&○○○&&'¹¹¹¹%'□¹%&&4&&&&&&V&&&&&&█tt¹&&'¹¹¹¹%'¹¹%&'&&&&&&&&&&&&&█¹tt¹&&'¹¹¹¹24¹¹%&'V&&&&&&&&&&&p¹¹tt¹&&'¹¹¹¹tt¹¹2&'&&&&&&&&&&&Vp¹¹tt¹&&'¹¹¹¹ut¹¹¹%'&&&&V○○&&&&&p¹¹tt¹9&'¹¹¹¹¹t¹¹¹%4○○○&p¹tn&&&&█¹¹¹t¹&&',¹¹L¹u¹¹¹8□¹¹tnp¹un&&&paa¹¹v¹&&&-,¹\\¹¹¹¹¹□¹¹¹t~█¹¹n&V&pNMP¹¹¹33&&=$\\¹¹¹¹¹¹¹¹¹t¹¹¹¹n&&○█NP¹¹¹¹~o2333,`¹^`¹¹¹¹¹t¹¹¹¹n&p¹t¹¹¹¹¹¹¹n&○○oQ,¹np¹¹¹¹¹u¹¹¹¹n&p¹t¹¹¹¹¹¹■~█¹ᵇnQR^op¹¹¹¹¹¹¹¹¹¹n&█¹t¹¹¹¹¹¹$¹¹¹¹~Q),&V`¹¹¹¹¹¹¹¹¹~█¹¹t¹¹¹¹¹¹'ma¹¹*-=Ro&p¹¹¹¹¹¹¹¹¹¹U¹¹t¹¹¹¹¹¹4‖◀◀▶Q&&=,o&`¹¹¹¹¹¹¹¹¹^¹¹t¹¹¹¹¹¹¹¹¹¹¹Q=&&-+,p¹¹¹¹¹¹¹¹¹¹¹¹u¹¹¹¹¹¹`¹¹¹*))&&&&-,¹¹¹¹*+,¹¹¹¹¹¹¹¹¹¹¹¹$■■*-=&;-&&&-++++-=Rqa¹uq¹¹¹*+++=$‖▶%)RV:=9&&=)=-=&)++++++++--=)&'¹^%&R&o%!&&&&&&-&&=)=---))&&&&=R^N%9'o&%&!&&&&&&&&&&&&&&&&&&&&",[33]="!&&&9&&&&&&&&&&&!&&&&3333&&9&&&&&&&&9&&&&&&&&4¹¹33&&&&&&&&33&&&&&&9&4tt~&%9&&!&&&&&&&&&&&&33&'¹¹¹¹2!&&&&&'&&2&&9&&&'¹tutn2333333&&!&&&&&&'¹t24¹¹¹¹¹%&&&&&4○○&%&&3334¹t¹vn&&&p¹¹%!33333&&&'¹tnp¹¹¹¹¹%9&&&'NMPn%!4¹a¹¹¹u¹¹n&o○█¹¹24¹¹~&&2333¹tnp¹¹¹¹¹%&3334NP¹~%'a¹mw¹¹¹¹^&&ptt¹¹¹¹¹¹¹n&p¹t¹¹vnp¹¹¹¹¹24tt¹t¹¹¹¹24NMNMP¹¹¹n&&p¹t¹¹¹¹¹¹¹n&█¹t¹¹¹np¹¹¹¹¹npvt¹t¹¹¹¹np¹O¹O¹¹¹¹n&&p¹v¹¹¹¹¹¹¹np¹¹v¹¹¹np¹¹¹¹¹np¹t¹v¹¹¹¹np¹O¹O¹¹¹¹nV&p¹¹¹¹¹¹¹¹¹np¹¹¹¹¹¹np¹¹¹¹¹np¹v¹¹¹¹¹¹np¹O¹O¹¹¹^&&hp¹¹¹¹¹¹¹¹¹np¹¹¹¹u¹np¹¹¹¹¹np¹¹¹¹¹¹¹¹np¹O¹O¹¹¹^w&i&`u¹¹¹¹¹¹^&\"$¹¹¹uunp¹¹¹²¹np¹¹¹¹¹¹¹¹np¹O¹O¹¹゛゜゜゜###$¹¹¹¹¹^o&%'¹¹uuun*++++,np¹¹¹¹ua¹¹np¹O¹O¹¹%&&&&&90‖◀◀▶*+,(24¹*++++-=)=)-+++,¹uumrsnp*++,‖▶%9&&&&&0¹¹¹¹Q-)++++-=)=-=&&&&&)=-R‖◀▶\"###+)-)Ru]%&&&&!&0■■■■Q=&=9)&&&&&&-&&&&&&&&R¹¹¹%&&99-&=RNN%&&&&&&9####9-&&&&&&&&&&&&&",[34]="¹¹¹¹¹¹¹¹■%'&&&&&&%&'¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹\"&'&&&&o&%&4¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹%&'○o&&&&%'¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹%&'■n&&○○%'¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹2&&$~op¹¹24¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹%&'¹~█¹¹□□¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹%&4¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹*++¹¹¹¹¹¹¹¹¹24¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹^\\\\\\`¹¹¹¹Q=)¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹^n&o&&`¹¹¹Q-&¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹^\\_&&&&&&p¹\"$Q=&¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹nh&&&&&oa&`24:-&¹¹²¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹¹*+,q¹¹¹¹¹^aiwrsaa######$Q=+++,¹¹¹¹¹¹##$¹¹¹¹■■¹¹*)=)#$¹u¹¹n\"#####$2333334Q----R¹¹¹¹¹5%&'¹¹¹¹\"$¹¹Q-&&&&$uuan%9&&&!'*+++++=-&&&&-+,¹W¹\"9&),¹m¹24*+-&&&&&'uu*+-&&&9&'Q=--)-&&&&&&&--+++%&&&-+++++=-=&&&&&&++)-&&&&&&'Q&&&&&&&&",[36]="⁸"}linked_levels=bt("9,12",split"3,2")music_triggers=bt("12,13,28,31",split([[-1,5000,0
38,0,7
-1,32000,7
0,0,7]],"\n"))
__gfx__
000000000000000000000000088888800000000000000000000000000000000000000000000000000300b0b00a0aa0a000000000000000000008000000077000
00000000088888800888888088888888088888800888880000000000088888800000000000000000003b33000aa88aa0000080000008008000000008007bb700
000000008888888888888888888ffff888888888888888800888888088f1ff180000000000000000028888200299992000080080080880080000000007bbb370
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff800000000000000000898888009a999900800008800098000080000807bbb3bb7
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff800000122021000000888898009999a9089088098000898008908808873b33bb7
0000000008fffff008fffff00033330008fffff00fffff8088fffff808333380000014442442100008898880099a999089899889088999880889989807333370
00000000003333000033330007000070073333000033337008f1ff10003333000012442211224210028888200299992080008008800880080000800000733700
00000000007007000070007000000000000007000000700007733370007007001244424442442421002882000029920000080000008900000088000000077000
888888886665666555888888888886664fff4fff4fff4fff4fff4fffd666666dd666666dd666066d0000000000000000700000000d6666660d666d6d066666d0
888888886765676566788888888777764444444444444444444444446dddddd56ddd5dd56dd50dd5007700000770070007000007dddd66661ddddddd1dd6666d
88888888677867786777788888888766000450000000000000054000666ddd55666d6d5556500555007770700777000000000000ddd6dddd1ddddddd11ddd66d
8878887887888788666888888888885500450000000000000000540066ddd5d5656505d5000000550777777007700000000000001dddddd1111ddd11111ddddd
887888788788878855888888888886660450000000000000000005406ddd5dd56dd506556500000007777770000070000000000001ddddd11111111111111ddd
867786778888888866788888888777764500000000000000000000546ddd6d656ddd7d656d500565077777700000077000000000d11111111111101111111110
5676567688888888677778888888876650000000000000000000000505ddd65005d5d65005505650070777000007077007000070dd1111110011011011111ddd
56665666888888886668888888888855000000000000000000000000000000000000000000000000000000007000000000000000dd111110000000000111ddd6
00000000ddd0ddd0ddddd5000ddd0ddddd555100000000000015555d0d5505d00cccccc0077777777777777777777770cc000000011111000000000000111d66
00000000d5515551555555111555155d55555100000000000000111155555155cccccccc7777777777677767777777771c00cc00dd111100000001000011d166
00555550d55155511111111111111110111100000000000001555dd0011111101ccccccc7677667777766677777777770000ccc06ddd1110011011100001ddd6
005ddd50555155505dddd1551555555d0dd55d100000000001555dd0dd55111d1cc1ccc17766677777776d676777677700001ccc66ddd110011011100001dddd
000ddd0055505d505ddd515515d55ddd0dd5551000000000015555d0dd5551dd1cc11c1077d67777dd77dcd7666677700cc01ccc66ddd110000001100001ddd6
000005550110011155555055110001100d5555100000000000001111d555515d111111007dcd667dccddcccd6d6777661ccc11c1dd6dd1100011000000111ddd
55500555d55555101111101100055ddd1111000000000000001555dd55555155011010007cccd66cccccccccccc66d661ccc0111dddd111001111100011111dd
55500000d5555510000000000015555ddd55510000000000001555dddd55515d000000007ccccccc0ccc00cccccd6dd611c00000ddd111000011100001111110
dd55515dd5555100000000000015555dddd15ddddddddd51ddd51ddd555551550000000077cccccc00cccccccccccc770ccc1000011111000000000000111d66
55555155d55551001100000000155ddddd51555555555551555515dd555551105500000077cccccccccccccccccccc771cc11000ddd11110000000001111dd66
01111110010001115500111011111110555111111111111111111555011111105505555067c7cccccccccccccccc7c671111000066dd1111111100111111ddd6
dd5111dd55505d51dd00555015d55ddd011111155111111151111110d551555d000555506ccccccccccccc6cccccccc60011cc1066dd11111111101111111ddd
dd5111dd55515551dd1155511555555d555551155155555151155555d5515555000000006ccccccccc6cccccccccccc6001cccc0dddd11111ddd111166611dd6
55511155d55155511111555111111110555551111155555111155555011155550555550066ccccc6cccccccc6ccccc660111cc106dddd11d666dd11ddd6611dd
01111110d5515551555155511555155ddd555155515d5551551555ddd55155dd055555006ccc66c6666ccc666c66ccc61c111100ddddd1d666ddd1dddddd11dd
5555515d0dd0ddd0dd50dd500ddd0dd0dddd505dd0dddd50d505dddd0d505dd000000000066666660666666666666660cc1000000dddd0ddddddd0ddddddd110
0000000000000000577777777777777788cccc8888cccc8888cccc881dddd15ddddd51dd000d0000100600101111011115555555555555551500000055505500
00008000000b000077777777777777778c0000c88c0000c88c0000c8d555515555d551550d0d0d000d060d001111011115111111111111111500000011111000
00b00000000000007777ccccccccccccc00cc00cc00c100cc00cc00cd55551555555515500d6d000006760001111011115000000000000001500000000000000
0000000000000000777cc7ccccccccccc0c00c0cc010c10cc00cc00cd555111111111111dd676dd0667776600000011115000000000000001500000000000000
0000b000080000b077ccc7ccccccccccc0cccc0cc01cc10cc00cc00c555111111111111100d6d000006760001110011115000000000000001500000000000000
0b0000000000000077c77777ccccccccc00cc00cc00c100cc00cc00c55511111111111110d0d0d000d060d001110000015000000000000001500000000000000
00000080000b000077cc777ccccccccc8c0000c88c0000c88c0000c81111111111111111000d0000100600101110111115000000000000001500000000000000
000000000000000077ccc7cccccccccc88cccc8888cccc8888cccc88d55111111111111100000000000000000000000015000000000000001500000000000000
7cccccccccccccc71111101100111010111101110000000015555551d5511111111cc11100000001000000001111111100555505111011101110110001101110
77ccccc0cccccc771111101101111010111101110001111050500505d551111111cccc1100000001000000001111111100001111111011101110110001101111
76ccccc0cccc77771111001101111010111101110001111051511515d55111111cc11cc10000010d010000000001111000000000111011101110110001101111
667cccc000ccccc70000000100001010000000110000000051511515555111111cc11cc10001000d000100000000000000000000000011100000000000001111
6ccccccc0ccccc771100000001100000100000000111010051511515111111111cccccc100001006001000001100011100000000111011100000000000000000
7cccccccccccc6771110111101101110110111110111010051511515d55111111cccccc100100d060d0010001110111100000000111011101110110000111111
7cccccccccccc6671110111101101110110111110000000051511515d551111111cccc1100000067600000000000111000000000111000001110110000111111
77cccccccccccc671110111101101110110111110000000051515515d5511111111cc11111dd6677766dd1100000000000000000111000000000000000111111
00000000000770000007700000077000000000000007700051515515155555515000000500000067600000001111011111155555000000001110000000000000
00000050000770000077770000700700707777070077770051510515500000055000000500100d060d0010001111011110151115100001001110000000011110
00000050007777007777777707000070777777770777777051511515500000055000000500001006001000000000011110151155111101101110111100011111
0050050500777700077777707777777777777777777777775151151550000005500000050001000d000100001110011110151555111100100000111100111111
0505051d07777770077007707777777707777770777777775151151550000005500000050000010d010000001110000010155515000000000000111100100111
051d0515077777707777777707777770077777700777777051511515500000055000000500000001000000001110111110155115110011000000000000011011
0515051d777777770077770000777700077777700077770051511515500000055000000500000001000000001110111110151115111011110000000000111111
051d051d777777770007700000000000777777700007700055555555500000055000000500000000000000001110111111155555011001100000000000011111
000000000000000000000000000115000111111500011500000000000dd11dd1011111100d666660066d0d66666d0d660d6666d0011100000000000000000000
00000000000000000000000000010500001010100001050000011100111111d1dd1111ddd6d6666d66dd1ddddddd1ddd1dd6666d111100000001111000001111
000000000000000000000000000151000050505000015100001505101611111066d111d6ddddd66666dd11dddd1111dd1ddd666d111100000000111000001111
00000000000000000000000000005000005050500000500000150510d661116666d11dd60111ddddd6dd1111111111111ddddd6d111100000000000000001111
10000000055555555555555000011500005050500001100000150510dd6611d66dd11dd0d1111110ddd1111000000100011ddddd111101110000001111101111
100000000111111111111150000105000050505000050000001111111dd11ddd6dd111166ddd11d6dd11d6d0ddd0dd10111111dd111101110110100111101111
100000000001100000011000000151000010101000000000001010511ddd66d1ddd111dddddd1ddd0111ddd1ddd1ddd11dd11110111101110110111111101111
15000000000150000001500000005000011111150000000000101051011ddd100dd111dd0dd111d000111dd111111dd1ddd11100111101110110111111101111
dd5888888888881551888888888885dd85077777787888888887778888888058e3e3e3e3e3e3e3e2e25252e2e3e3e3e3e25252e2e3e3525252525252e2e3e3e3
d155d5d5ddddd556d55ddddd5d5d551d810777778788888888777888888870185252620101000000000003000000428352627484841302232323022323520252
5501111111115151151511111111105585077778788888888777888888878058e752e652f700d7d3e3e2e2f3f737d7e7d3e2e2f352e6d2e252e2e3e3f3e7e7e7
8510000000001505505100000000015881077787888888887778888888788018525282a2b20000000101030000014252836275d5f50003215731033737132323
8510ccc7777700c00700711ccccc01588507787888888887778888888788805800d752f6000000d752d2f2f600470057d7d3f2e6e752d2e3e3f30414f7000000
85071077777cc11c1c17cc711cccc05851078788888888777888888878888015525252521501010192a262d700432302526200d6f60073214431733737000057
850cc71077cc1cc17c71c777c100c058151078888888877788888887888801511727d6f700000000d6d2f2f70000000000d787f6a0d787005731140000000000
850cccc71011ccc1cc71777ccc7000585100888888887778888888788888001552525252c2a2a2a252826252e5f737425262d5e652f500000000003747004400
850ccc1cc710cc17ccc717ccc00770580000044000000d0550d0000006666600e1f1f60000000000d7d2f20000006700000077f7000087c60031140000001000
85011c1cccc7107ccccc71c0077cc058000564460000050110500000667776605252825283a3a3c3528362e7f700474283625252e6e745000000005700671727
850c711cccc111000ccc00077cc770580060024000666d666d6d660066666660e2f2f7000000000000d2f20414d1f10000310414141487d4f43114000000d1e1
850cc71cc11ccc10000071cccc7770580550024006dddddddddddd60611611605202a3c362111105c32333000000004202625552f73700000000000000432222
850cc77117ccc0000177cc1cc77770585aa50240dddddd5555dddddd6116116052f300000101010000d3f31400d2f20000311400000077000031140000c4d2e2
810c7c717cc11711171cc7c17777c01800000420dddd5d5dd5d5dddd16666610836211133300001333370000000000425262e7f7003700000000000000004283
8507c771cc017cc1cc717c7c1771105800000440dddddd5555dddddd06060600f23700310414142100d6f61111d2f24100311400000037000000d1f1d4f4d252
810c77c1017cccc1c11717ccc11cc01800000440dddddddddddddddd000000005262e5e7f7000000573700000000004252628537004700010101000000001352
85077c017ccccc111cc771c11c1cc05800000440dd555555555555dd00666000f23700311400002100d652f500d2f20000311400000037000000d2f20101d2e2
5107017ccccc11cc1c77771ccc1cc01500000440dddddddddddddddd061816000233f60000000000005700000000014283620047000000041414f5000000d613
15107ccccc11cccc11777c71ccc10151666666205dd5555d555d5ddd61181160f25700311400002100d75552e5d2f20000311400000057000000d2e2e1e1e252
5100cccc11cccccc1c17ccc71cc10015dddd6620dddddddddddddddd611888606252f7000000000000000000000092c3023300000000d5140000f6000000d655
dd5888888888881551888888888885dddd1166205ddd55d5d55dddd561111160f2000000370037000000d65252d2f20000311400000000000000d2e252525252
d155d5d5ddddd556d55ddddd5d5d551dd1115540dddddddddddddddd0611160062f60000000000243400000000000552620000000000d6555252e6f54400d7e6
55011111111151511515111111111055d11d6640ddd55555d5555ddd00666000f200000037f047000000d7e755d2f200d5e555e7e7f700000000d25252525252
85100000000015055051000000000158d11d6640dddddddddddddddd0000000062f70000000000340000000000004282620000000000d6e6525252f6000000d6
85108888888700700800888888870158d11d6640dd555555555555dd00000000f20000005700000000000000d7d2f2e5e6e7f700000000000000d2e252525252
85088888887777778788888888777058d11166405ddddddddddddddd00000000620000000101000000000001010142526200000000d55252555255f7000006d6
85088888877777787888888887778058dd11554055dddd5555ddddd500000000f2010000000000000000010101d2f2e7f7000000000000010101d2e252525252
85088888777777878888888877788058dd5d6620d55ddd5dd5dddd5d000000006200000092b2010000000092a2a202526210000012a2a2a2a2a2b20101011222
85088887777778788888888777888058005066205ddddd5555dddddd00000000e2f1010101010101010192a2a2e2f20101010101010101d1e1e1e25252525252
85088877777787888888887778888058005002205ddddddddddddddd000d5000152434340552b2000001010552c352526241611202c3c28252c2c32222220283
850887777778788888888777888880580005022055dd5dd55dddddd50005500052e2e1e1e1e1e1e1e1a2c3c25252e2e1e1a2a2a2a2a2e1e2e252525252525252
8508777777878888888877788888805800005240555dd5dddddd5d55000550001534000005c362000192a2822323230262000042525252525252525202525252
7700077077777700770007707700000077777700077777007777770077777700525252525252525252023337d6e61352f2e652d3e3e25252e2e3e3e3e3e3e3e2
77700770777777707700077077000000777777707777777077777770777777701500000005c26200432323330000004200000000000000000000000000000000
7777077077000000770707707700000077000000770000000077000077000000525252525252525283331137d7e7e742f255525552d3e3e3f255525252e652d3
ccccccc0cccc0000ccccccc0cc000000cccc0000ccccccc000cc0000cccc000015000000138362000000670000a0004200000000000000000000000000000000
cc0cccc0cc000000ccccccc0cc0000c0cc000000000000c000cc0000cc00000052835252525252526211005700172742f3e75252e7e7e7e68752e6e7e7e7e655
cc00ccc0cccccc00ccc0ccc0ccccccc0cccccc00ccccccc000cc0000cccccc006200000037132322222232000000004200000000000000000000000000000000
cc000cc0ccccccc0cc000cc0ccccccc0ccccccc00ccccc0000cc0000ccccccc0022323025252525262000000001222020037d7f7005700d78752f7010100d752
00000000000000000000000000000000000000000000000000000000000000006200440047d75213232333717171714200000000000000000000000000000000
000777777000777770000000000000005544402444444455000000000000000062111113835252026241515161428352004700370000000087f700a7c700f0d6
0007777777077000770000000000000011444244444444110000000000000000620000000000d7e7f700570000d5e54200000000000000000000000000000000
000770007707700077000000000000000044444444444400000000000000000062000011132323233300000000132352000000370004141487000004140000d7
000ccccccc00ccccc0000000000000000044242424244400000000000000000062000000000000000000000000d6524200000000000000000000000000000000
000cccccc00cc000cc000000000000000044222222244400000000000000000062c60000041400370000f0000057314201010047001400008700001400000000
cc0cc000000cc000cc000000000000000044222222244400000000000000000015010100000000000101000044d7524200000000000000000000000000000000
cc0cc0000000ccccc0000000000000000044422222444400000000000000000062d4f400140000470000000000003142b2b2010000000000770000d1f1010101
0000000000000000000000000000000000444422424444000000000000000000c2a2b20101000000041400000000d742000000000000000000000000d5e5f500
077777007700000077777700000000000044424222444400000000000000000062f40000140000000000010100003142c382b20000000000000000d2e2e1e1e1
777777707700000077777770000000000044422222444400000000000000000052c32353630000001400000000000042000000000000000000000000d652f600
7700077077000000770007700000000000442222242444000000000000000000620000c51400000000311232f500014252c2150000000000000000d252525252
dd000dd0dd000000dd000dd000000000004444444444440000000000000000005262c600000000001400000000000042000000000000000000000000d652f600
dd000dd0dd0000d0dd000dd00000000000444204444442000000000000000000620000001400010101014262f7001283c252150000000000000000d3e3e25252
ddddddd0ddddddd0ddddddd000000000004042004444420000000000000000000233d4f400000000140000000000014200000000000000000000d5e56052f600
0ddddd00ddddddd0dddddd000000000000202000200420000000000000000000620000001222320414144262d5d5425252521500000000000000000000d25252
00000000000000000000000000000000000000000000000000000000000000006257000000000000000000000000128300000000001232000000d652525252f5
0777770077700777777007777770000000000000000000000000000000000000620000004283621400001333d5e6425252521501010000000000000000d3e3e3
77777770777707777777077777770000000000000000000000000000000000006200000000000000000000000000425200100000004283320000d652525252f6
7700000007700007700007700000000000000000000000000000000000000000620610004252620000000414e5554202525282a2b2010000000000000000d6e6
ddddddd00dd0000dd0000dddd00000000000000000000000000000000000000062004400000101018500748484844252a2b2000012025282a2a2a2a2a2a2a2a2
000000d00dd0000dd0000dd000000000000000000000000000000000000000006241516142026200a0d5140052e64252525252c252b21727000000000010d6e6
ddddddd0ddd0000dd0000dddddd000000000000000000000000000000000000062000017271222320101750000004202c2c2a2a2c2525252c2c3c2c282c2c382
0ddddd00dddd000dd0000ddddddd00000000000000000000000000000000000062000000425262e5e5e614005552428352525252c282a2b241515161d1e1e1e1
0000000000000000000000000000000000000000000000000000000000000000522222222202528322222232000042525252c282525252525252c35252525252
__map__
00000000000000000000000000000000001010503a3a32323232323232323238252520261200001350282c25252525253825323232323232323232323220252526000000313232323232323232323238252538323220252525252026556d7f242625257e24202525252025252532323825265f00242525202532322538252525
00000000000000000000000000000000102935336d256e257e7e7e25556e25242525253312000013393a3c2c2825252532337e7f00737500404141256e31252526474848000000000000000058007324203233256e313220253832337e000024267e7f003132323232323232331111242026255f3132323233004e3132202525
00000000000000000000000000000000223b73006d25257f0000007d7e7e6e242538267f000000000073393a3a323825256f0000007400004100007d7e252425265700000044006c000000000000732426252525557e7e313233404100000024260000000040414141414141000000242526404141414141414d4f007d242525
00000000000000000000000000000000260073007d556f000000000044006d2420323300101010100075007300002425556f44000000000041000000447d243826575d5e5f00006c6c0060000000732426256e7e7f0000730000410000006024267601000041000000000000000000242526410000000000005f600000313232
0000000000000000000000000000000026007300006d6f000000343535352220266f7300404141410000007300002420256e5f00000000004100000000002425265e256e21222222351415162700732426557f00000000740000410000151624382222222222222222222222234f0024202641000000000000255e5f40414141
0000000000000000000000000000000026007500007d7f000000007300733138265b73004100000000000075001024252222222236007000410000000010242026552525242532330000440037007324266f00000000000000004100000000242525252025253825202525382600002425264100000000000055256e41000000
0000000000000000000000000000000026000015162123000000007300740024265b7400000000000000000000213825252032334d4d4c4d4100005f0021382526252525243300750000000073007324266f00000000760000004100000000242032323232323232322525252640412425265525256e25212222222341000000
00000000000000000000000000000000260000000024265d0000007400000024266f007000000000000000000031323825335f7300004e004100006f0024252526252555305f00000000000073747324267f00000021234f0000410000006c2426257e7f00111111112425252641002425252222223535323238252641000000
00000000000000000000000000000000260000000024266d5f00000000000024266f4d4c4f6c000000000010106d253726256f745c4d4e004100006f002432322625252530255e404141412122222238260000000024334d5d5e2123105c4d24267f0a00000000001324382526410024252520323325256f0024253823257f00
0000000000000000000000000b000000260000000031335d6f00000000000031267f4d4d4c4d4f0000000040416d5525336e7f0000005d5e410000555f305800337e7e6e3725254100000024202525252023141500306e537e7e24202b10102426000000101000001324252526410024252526404141414141242025267f0000
00000000000000b5000000005e5b5b00267601000000586d255f000000004748260000004e00000000000041006d25557e5f0000005d6e25410000256e3700000000007d6e256e4100000024382525252526000000377f00000031383c2a2a3c26101010292b1200132420323300002425252641000000000031322526000000
000000000000292a2a2b005d6e25255f3823141621235d256e6f006000005700330000004e00000000000041006d6e2500000000007d7e5541000025255f4748000100006d5625555f0000503c2525252526000000000000000073312c282525264041415051120013313375000000242538264100000000006e253133000000
2b0000000000502c2c2c2a2b0108006f2526005d24266d6e256f6c6c000057000000005d5b5e5f00000000006d555525000176717200007d4100006e256f575d222223006d666e256f6000502525252538265f00000000000000755f502c252526410000243b0000000000000000002425323341000000000055566f00000000
2c2a2b1416292c2525252c2c2222222a20265b6e2438222a2a2a2a2a2a22222200005225256e255e5200000f6d6e2525231416292b0000002122222a2a2a2a2a202538222a2a2a2a2a2a2a2c252525252526255f700000000000006e503c25252641000037730000000000000000002426007d6e252122222325666f76717200
2528510000502c252525252538252528382655252425382c3c252c28383825200060016d2525557f0000005d2525256e265f0050515f0000243825252c252c3c252525252c253c25282c3c252525252525202222237000000100600050252525260000000073000000000010101010242601006d552425252522222222222222
2525510000502c252525252525202525252625552420252525252525252525252222231415256f000000006d6e25552526255e50516e5f00242025252525252525252525252525252525252525252525252525203822231415162122282525252600000000740000005d56292a2a2a3c26141621222525202525252525252525
25252e3e3e3e3e3e3e3e2e2525253e3e2525252525252e2e2e3e3e3e2e2e2525252e252525252e3e3e2e252525252525000000000000000010242625252525252524252600000000000000000000000000006d6e25252525257f000000000000265f00000000005d5e2566502c25282525260000243825323220252525252525
253e3f7f00000073007d2d2e3e3f000025252e2e3e3e3e3e3f5525253d3e3e2e2e3e3e2e252e3f6e252d2525252525250000000000000000212526252525256e2524253300000000000000000000000000007d7e7e6e25256f73000000000000266f000010102122222222202525252538260000243233111124382532382525
2f7e7f00000f007400102d2f00000000252e3e3f6e252525557e256e7e7f733d3f55252d2e3f257e7e3d2e252525252500000000000000002425267e6e2525252524260000000000000000000000000000000073006d25256f7400000000000026255e5e21223820253825252525252532260000370000000031323311242025
2f10000000000000001d2e3f4f0000002e3f007d5525256e7f006d5f00007300006d6e2d2f556f00007d2d25252525250000000000000000242526106d25257e7e24260000000000000000000000000000000074006d256c6f000000000000003835365524252525252525252525252500370000730000000073007300242525
251f6c0000100000003d2f75000076002f1200007d55256f00006d5f60007300007d252d2f257f0f00002d2e252525250000000000000000312525237d6e6f000031330000000000000000000000000000000000006d6c6c6f0000000000000026756d2524252525252525203225252500750000731010100073007300312525
252f4d4d4c794f000073780000007a1e2f120000006d7e7f00006d555f00740010006d2d2f7f000000002d2e25252525000000000000000000242526007d7f0000111100000040414141414100000000000000132222222222230000000000002600343532252525202525331124252500000000734041410073007400002438
2e3f005c4d781000007578000f00132d2f12000f005b1010105d25256f00000079007d2d2f00000000002d2525252525000000000000000000242526000000000000000000004100000000000000000000000013313232323226404141292a2a260000000034203232323300003138251010000073410000007400000f002420
3f000000003d1f005d5e77000000132d2f1200005d25292a2b6d55256f0000007800003d3f00000000003d2e252525250000000000000000003132330000000000101000000041000000000000000000000000006d2525256e37410000503c2826607000000030257e7f0000001324252a2b1010731111110000000000002425
000000000013784f6d6f114b0000132d3f1200007d6e502c51256e7e7f000000785f000000000010006c002d2e3e2e2500000000000000404141414141410000002123000000002122222300000000000000005d6d252525256f410000502c25252223000000307f0000000000132425282c2a2b105b5b5f00101010005d2425
00000000001378006d7e537f0000132d00000000007d392e2f7d6f4243430010786e5e5f000000794d4c4d2d2f253d3e00000000000000410000000000000000003133000000003132323300000000005d5b5e2525252525256f410000503c2525202600005d300000001000001324252525252c2b7e25255b4041415b252425
010000000013785d7f0000000000132d000000000000132d3f006b43000000292f7e7e7f000010784d4d4d3d3f7e7f0000000000000000410000000000000000006d6f00000000292a2b00000000005d6e5625252525256e256f000000392c252525265e5e25304d4c4f2712000024252525252551007d7e7e41007e6e252420
1e1f00000013776f000000000000132d00000000000013780000004300005d502f14150000001d2f000000111100730000000100000000000034222223000000006d6f00000000502c5100000000006d60667671726c762525255f000000503c252526252525375c4d4d3012000024252525252851007373001111117d7e2425
2e2f4f0000007d7e000000000010102d0000000000001377000000005d5e7f2d2f00000010102d2f10000000000074002a2a2a2b000000000000242526000000006d6f0000292a282c3b00000000007d21222222222223252525255e5e5e502c25382625257e7f0000003012005d24252525252c260073740000000010102425
252f10101000000000000010101d1e2e0001000000000000000010006d7f10502f1010101d1e2e2e1f000000007671722c2c2c51000000000010242526000000006d6f0000502c3c510000000000000024382525252025232525252525292c25252526257f0000000000375d5e25242525252525261074740000000021223825
25251e1e1f1010101010101d1e2525251e1e1e1f10101010101079006b00292c251e1e1e2e2525252f101010101d1e1e2525252c2a2b005600213825282b006c006d6f292a2c25252c2b00000000292a2c252525382525282a2a2a2a2a3c25252538267f000000000000116d2525242025252525202374740000010024202525
2525252e2e1e1e1e1e1e1e252525252525252e2e1e2a2a1e2a2a5100000050252e252525252525252e1e1e1e1e252525252525252c2c2a2a2a242525252c2a2a2a2a2a3c2c3c2525252c2a2a2a2a282c25252525252525253c2c2c282c2525252525260000000000005c277e7e7e242525252525253822231415151624252525
__gff__
0000000000000000000000000000000002020202080808000000000000030303030303030306030303030303030303030303030303030303030303030303030300000000000000000000000604040404030306060606060000000006040606060404040404040604040000040606060604040404040404030303030303060606
__sfx__
110600080c5500c5500c5500c5520c5500c5500c5500c552000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010518201813018070180701807018050180501805018050180401804018040180401803018030180301803018020180201802018020180101801018010180101801018010180101801018010180101801018010
03040000180433d6703d6503d6403d6203d6103d6203d635000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001807300150001500015000150001500015000150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000180730c1500c1500c1500c1500c1500c1500c150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800080015000150001500015000150001500015000150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8919001015d1015d1215d1015d1115d2115d2015d2015d2215d2015d2015d2215d2115d1115d1015d1215d1000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d00
0134000015900189001c9002090024900289002d9003090015900189001c9002090024900289002d9003090000000000000000000000000000000000000000000000000000000000000000000000000000000000
03040000366352a6542b60027300376352a6541d30026300376352a654193000030000300003000030000300003000030000300003000c0000030000300003000c073306603e474306702f6502d6402b62029615
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
4d1800002d9302d92028920289102f9202f91030920309103091030910309103091500900009000090000900009000c1000090000900009000090000900009002c9202d9202f9302f9202f910289202891028915
030400000c073306603e4741867021670246442b6252d6002b6002960030600306003060030600306003060030600306003060030600306002460024600246001860018600186000c6000c600006000060000600
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
01100000070000a0000e0001000016000220002f0002f0002c0002c0002f0002f0002c0002c0002f0002f0002c000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
0102000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
0103000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
030200003d6133f65530654346413464134641356413564135611346213763137641376103761037620376203763037630396103962039630396103961039610396143b6143b6143b6143d6143d6003d6143b600
71050000371752b1502b1502b1402b1302b1202b1102b110331752715027150271402713027120271102711027110271102711027110271102711027110271102711027110271102711027110271102711027115
4b0300000c0733265432651326413164131631316313062130621306112f6112f6112f611236112361117611176110b6110b61500000000000000000000000000000000000000000000000000000000000000000
950c0000210021f0511d0611c0711a0711c00017000210002100009000150001005109071040710007100000000000405109061100711507100000000000000000000000000000015000180511a0711d07121071
4b0300003e62438625206263b62438625206262f62420626146162060023614146152060023614146152360014600206002060000000236001460017600086000000000000000000000000000000000000000000
0f02000414032180541f7713b6243862500100001000010000100001000010000100001000010000100001000010000100001000c0001f0000010000100001000010000100001000010000100001000010000000
190d002009760097400c7500c7301075010730147501473018850188301c8501c8302085020830248502483028850288301c8301c8202083020820248302482028830288201c8201c81020820208102482024810
190d002007760077400c7500c7301075010730137501373018850188301c8501c8301f8501f830248502483028850288301c8301c8201f8301f820248302482028830288201c8201c8101f8201f8102482024810
190d0020057600574009750097300c7500c7301075010730158501583018850188301c8501c8302185021830248502483018830188201c8301c8202183021820248302482018820188101c8201c8102182021810
190d0020047600474008750087300b7500b7301075010730148501483017850178301c8501c8302085020830238502383017830178201c8301c8202083020820238302382017820178101c8201c8102082020810
011a00001c9501c9501c9501c9501c9401c9301c9201c9101c9101c9101c9101c9101c9101c9101c9101a94018950189501895018950189401893018920189101891018910189101891018910189101891017940
011a0000159501595015950159501594015930159201591015910159101591015910159101591015910159101591015910159101591015910159101591015910159101591015910159151593017940189501a950
011a00001c9701c9701c9701c9701c9601c9601c9501c9401c9301c9201c9101c9151a6001a600186001896717970179701797017970179601795017940179301792017910159501594017970179601795018960
011a0000149501495014950149501494014930149201491014910149101491014910149101491014910149101491014910149101491014910149101491014910149101491014912149151490014900149001a900
011a00001095010950109501095010940109301092010910109101091010910109101091010910109101091010910109101091010910109101091010910109101091010910109121091514900149001596015950
010d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001593015920179301792018940189301a9401a930
011a00000900009000209302092020910149002093020930209202091521940219302191015900219402194021920219152395023940239201790023940239302392023915249402493024910189002493024920
011a000009000090001f9301f9201f910139001f9301f9301f9201f91521940219302191015900219402194021910219152395023940239201790023940239302392023915249402493024910189002493024920
030d00201505315d003d62415d001505321d003d62421d0018a7018a703d62415d003c62521d003d63421d003d620000003c6250000015053000003d6240000018a7018a7015053000003c625000003d62400000
030d002015b5015d5015d5015d5015c5021d5021d5021d5018a7018a7015d5015d5021d6021d6021d6021d6015d7015d7015d7015d7015c6021d6021d6021d6018a7018a7015b6015d6021d5021d5021d5021d50
030d002000000000003d6240000000000000003d6240000000000000003d624000003c62521d003d634000003d620000003c6250000000000000003d62400000000000000000000000003c625000003d62400000
030d002013b5013d5013d5013d5013c501fd501fd501fd5018a7018a7013d5013d501fd601fd601fd601fd6013d7013d7013d7013d7013c601fd601fd601fd6018a7018a7013b6013d601fd501fd501fd501fd50
030d002011b5011d5011d5011d5011c501dd501dd501dd5018a7018a7011d5011d501dd601dd601dd601dd6011d7011d7011d7011d7011c601dd601dd601dd6018a7018a7011b6011d601dd501dd501dd501dd50
030d002010b5010d5010d5010d5010c501cd501cd501cd5018a7018a7010d5010d501cd601cd601cd601cd6010d7010d7010d7010d7010c601cd601cd601cd6018a7018a7010b6010d601cd501cd501cd501cd50
03080020150731c9003f61515d003f62518a003f63015d003d6753d6053f6151a9003f625189003f63515b003f63514d003f61514d001505318a003f63015d003d67518a001507314d003f62518a003f6263f636
0920000015d7015d5015d7015d5015d7015d5415d7415d5414d7014d5014d7014d5014d7014d5414d7414d5413d7013d5013d7013d5013d7013d5413d7413d5412d7012d5012d7012d5012d7012b5013d6514d75
010800201c9601c9550000000000159301592518940189351a9401a9351893018925179301792515930159251c9501c9451800018000159301592518940189351a9401a935189301892517940179351595015945
0510000015d7021d7023d7024d7015d7021d7023d7024d7015d6021d6023d6024d6015d6021d6023d6024d6015d5021d5023d5024d5015d5021d5023d5024d5015d4021d4023d4024d4015d5021d5023d6024d60
011000002d8702d8502d8402d8352d860288502f840308502d830288202f810308202d820288102f810308102d815288152c8502d8502f8602f8552d8502c8402c8302c8252d8102c8102f8102f8152d8152c815
011000002b8702b8502b8402b8352b860268502d8402f8502b830268202d8102f8202b820268102d8102f8102b815268152a8502b8502d8602d8552b8502a8402a8302a8252b8102a81028870288502884228835
011000002d8702d8502d8402d8352d860288502f840308502d830288202f810308202d820288102f810308102d815288152f850308503286032855308502f8402f8302f8252f810308103281032815308152f815
031000002d8702d8502d8402d8352d860288502f840308502d830288202f810308202d820288102f810308102d81528815308503285034860348553285030840308303082530810308153f6143f6113f6213f631
0120000009560095410954109551095510954109541095310b5600b5410b5410b5510b5510b5410b5410b5310c5600c5410c5410c5510c5510c541095500c5400e5600e5410e5410e5510e5510e5410e5410e531
012000002d8702d8502d8522d8452d860288502f84030860308503085030840308403084030835308603285534861348503284030850308503084230840308303082030810000000000030800308002f8502f857
112000002d8702d8502d8522d8452d860288502f84030860308503085030840308403084030835308603285533861338503284030850308503084532815308572f8702f8502f8402f8402f8322f8202f8152d745
11200000347423472534712347152d860288502f8403086032757307152f7202f715308402d745307453275534861348503284030850308503084230840308303082030810000000000030800308002f8502d745
11200000347423472534712347152d860288502f8403086032757308302f7352f715308402d745307453275533861338503284030850308503084532815308572f8702f8502f8402f8402f8302f8302f8202f810
03080020150731c9003f60015d003f6143f6203f6203f6003d6753d6053f6001a9003f600189003f60015b001501314d003f60014d001505318a003f60015d003d67518a001507314d003f636246263f6003f600
070500001507339655150701c0502106021040210202101015d1415d1015d1015d1015d1015d1015d1015d1015d2015d2015d2015d2015d3015d3015d3015d3015d2015d2015d2015d2015d1015d1015d1015d15
07020000180532d0522d0353f6103e6253c6153c6003c6003c6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 1d424344
00 1d424344
00 1e424344
00 1e424344
00 1f424344
00 1f424344
00 20424344
00 20264344
00 1d214344
00 1e224344
00 1f214344
00 20244344
00 1d274344
00 1e284344
00 1f274344
02 20274344
03 06424344
01 1d232944
00 1e252944
00 1f232944
00 20252944
00 1d232a2b
00 1e252c2b
00 1f232d2b
00 20252e2b
00 1d272a2b
00 1e282c2b
00 1f272d2b
00 20272e2b
00 1d272a2b
00 1e282c2b
00 1f272d2b
00 20272e2b
00 1d272944
00 1e282944
00 1f272944
02 20272944
00 41424344
01 3c303144
00 2f303144
00 2f323331
00 2f323431
00 2f323331
00 2f323431
00 2f323331
00 2f323431
00 2f323531
00 2f323631
00 3c373144
00 2f373144
00 2f303831
00 2f303931
00 2f303a31
00 2f303b31
00 2f323331
00 2f323431
00 2f323331
00 2f323431
00 2f323331
00 2f323431
00 2f323531
00 2f323631
00 3c373144
02 2f373144
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000770007707777770077000770770000007777770007777700777777007777770000077777700077777000000000000000000000000
00000000000000000000000777007707777777077000770770000007777777077777770777777707777777000077777770770007700000000000000000000000
00000000000000000000000777707707700000077070770770000007700000077000000007700007700000000077000770770007700000000000000000000000
00000000000000000000000ccccccc0cccc0000ccccccc0cc000000cccc0000ccccccc000cc0000cccc0000000ccccccc00ccccc000000000000000000000000
00000000000000000000000cc0cccc0cc000000ccccccc0cc0000c0cc000000000000c000cc0000cc000000000cccccc00cc000cc00000000000000000000000
00000000000000000000000cc00ccc0cccccc00ccc0ccc0ccccccc0cccccc00ccccccc000cc0000cccccc00cc0cc000000cc000cc00000000000000000000000
00000000000000000000000cc000cc0ccccccc0cc000cc0ccccccc0ccccccc00ccccc0000cc0000ccccccc0cc0cc0000000ccccc000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000777770077000000777777000000000007777700777007777770077777700000000000000000000000000000000000
00000000000000000000000000000000007777777077000000777777700000000077777770777707777777077777770000000000000000000000000000000000
00000000000000000000000000000000007700077077000000770007700000000077000000077000077000077000000000000000000000000000000000000000
0000000000000000000000000000000000dd000dd0dd000000dd000dd000000000ddddddd00dd0000dd0000dddd0000000000000000000000000000000000000
0000000000000000000000000000000000dd000dd0dd0000d0dd000dd000000000000000d00dd0000dd0000dd000000000000000000000000000000000000000
0000000000000000000000000000000000ddddddd0ddddddd0ddddddd000000000ddddddd0ddd0000dd0000dddddd00000000000000000000000000000000000
00000000000000000000000000000000000ddddd00ddddddd0dddddd00000000000ddddd00dddd000dd0000ddddddd0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000017777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777771000000000
00000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000
00000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000
00000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000
00000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000
00000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000
00000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000
000000000777777000000000000000000000000000000000d5000000000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000000000055000000000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000000000055000000000000000000000000000000000000000000000000000000000000000777777000000000
0000000007777770000000000000000000000000000000d0550d0000000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000000005011050000000000000000000000000000000000000000000000000000000000000777777000000000
0000000007777770000000000000000000000000000666d666d6d660000000000000000000000000000000000000000000000000000000000777777000000000
0000000007777770000000000000000000000000006dddddddddddd6000000000000000000000000000000000000000000000000000000000777777000000000
00000000077777700000000000000000000000000dddddd5555dddddd00000000000000000000000001011010000000000000000000000000777777000000000
00000000077777700000000000000000000000000dddd5d5dd5d5dddd0000000000000000000000001a1aa1a1000000000000000000000000777777000000000
00000000077777700000000000000000000000000dddddd5555dddddd0000000000000000000000001aa88aa1000000000000000000000000777777000000000
00000000077777700000000000000000000000000dddddddddddddddd00000000000000000000000012999921000000000000000000000000777777000000000
00000000077777700000000000000000000000000dd555555555555dd00000000000000000000000019a99991000000000000000000000000777777000000000
00000000077777700000000000000000000000000dddddddddddddddd00000000000000000000000019999a91000000000000000000000000777777000000000
000000000777777000000000000000000000000005dd5555d555d5ddd000000000000000000000000199a9991000000000000000000000000777777000000000
00000000077777700000000000000000000000000dddddddddddddddd00000000000000000000000012999921000000000000000000000000777777000000000
000000000777777000000000000000000000000005ddd55d5d55dddd500000000000000000000000001299210000000000000000000000000777777000000000
00000000077777700000000000000000000000000dddddddddddddddd00000000000000000000000000111100000000000000000000000000777777000000000
00000000077777700000000000000000000000000ddd55555d5555ddd00000000000000000000000000000000000000000000000000000000777777000000000
11111111177777700000000000000000000000000dddddddddddddddd00000000000000000000000000000000000000000000000000000000777777111111111
00000000077777700000000000000000000000000dd555555555555dd00000000000000000000000011101100111111111111111100000000777777000000000
111111111777777000000000000000000000000005ddddddddddddddd00000000000000000000000011101100111111111111111100000000777777111111111
0000000007777770000000000000000000000000055dddd5555ddddd500000000000000000000000011101100000111100001111000000000777777000000000
11111111177777700000000000000000000000000d55ddd5dd5dddd5d00000000000000000000000000000000000000000000000000000000777777111111111
000000000777777000000000000000000000000005ddddd5555dddddd00000000000000000000000000000000110001111100011100000000777777000000000
111111111777777000000000000000000000000005ddddddddddddddd00000000000000000000000011101100111011111110111100000000777777111111111
0000000007777770000000000000000000000000055dd5dd55dddddd500000000000000000000000011101100000011100000111000000000777777000000000
11111111177777700000000000000000000000000555dd5dddddd5d5500000000000000000000000000000000000000000000000000000000777777111111111
00000000077777700000000000000000007777777777777777777777777777770000000001110111011100000000000000000000001101110777777000000000
11111111177777700000000000000100077777777776777677767776777777777000000001110111011100000000000000000000001101111777777111111111
11111111177777700000000000010101076776677777666777776667777777777000000001110111011101111000000000000000001101111777777111111111
11111111177777700000000000011c1107766677777776d6777776d6767776777000000000000111000001111000000000000000000001111777777111111111
11111111177777700000000000111c11177d67777dd77dcd7dd77dcd766667770000000001110111000001111000000000000000000000000777777111111111
11111111177777700000000000111c1117dcd667dccddcccdccddcccd6d677766000000001110111000000000000000000000000000111111777777111111111
111111111777777000000000001c1c1c17cccd66cccccccccccccccccccc66d66000000001110000000000000000000000000000000111111777777111111111
1111111117777770000000000011c6c117ccccccc0ccc00cc0ccc00cccccd6dd6000000001110000000000000000000000000000000111111777777111111111
111111111777777000000000cccc666cc7ccccccccc000000cc000000cc000000777777777777777000000000000000000000000000000000777777111111111
1111111117777770000000000001c6c1077ccccc01c00cc001c00cc001c00cc0077677767777777770000000000000b0000b0000000011110777777111111111
111111111777777000000000000c0c0c076ccccc00000ccc00000ccc00000ccc07776667777777777888888800000b70bb0bb000000011111777777111111111
11111111177777700000000000100c001667cccc000001ccc00001ccc00001ccc77776d67677767788888888800000bb77b7b000000111111777777111111111
11111111177777700000000000000c0006ccccccc0cc01ccc0cc01ccc0cc01cccdd77dcd766667778888ffff800000122b210000000100111777777111111111
11111111177777700000000000000c0007ccccccc1ccc11c11ccc11c11ccc11c1ccddcccd6d67776888fffff8000014bb2442100000011011777777111111111
1111111117777770000000000000000007ccccccc1ccc01111ccc01111ccc0111ccccccccccc66d6888f1ff10001244221122421000111111777777111111111
11111111177777700000000000000000077cccccc11c0000011c0000011c000000ccc00cccccd6dd687733370124442444244242100011111777777111111111
111111111777777ff4fff4fff07777777cc000000000000000000000000000000cc000000cc000000ddddd500ddddd500ddddd50077777777777777111111111
1111111117777774444444444777777771c00cc000000000000000000000000001c00cc001c00cc0055555511555555115555551177677767777777111111111
1111111117777770000054000767766770000ccc00000000000000000000000000000ccc00000ccc011111111111111111111111177766677777777111111111
11111111177777700000054007766677700001ccc00000000000000000000000000001ccc00001ccc5dddd1555dddd1555dddd15577776d67777777111111111
111111111777777000000054077d677770cc01ccc0000000000000000000000000cc01ccc0cc01ccc5ddd51555ddd51555ddd5155dd77dcd7777777111111111
11111111177777700000000547dcd667d1ccc11c10000000000000000000000001ccc11c11ccc11c1555550555555505555555055ccddcccd777777111111111
11111111177777700000000057cccd66c1ccc01110000000000000000000000001ccc01111ccc0111111110111111101111111011cccccccc777777111111111
11111111177777700000000007ccccccc11c0000000000000000000000000000011c0000011c000000000000000000000000000000ccc00cc777777111111111
11111111177777700000000007ccccccccc00000000000000000000000000000000000000000000000000000000000000000000000cccccc0777777111111111
111111111777777000000000077ccccc01c00cc000000000000000000000000000000000000000000550000000000000000000000cccccccc777777111111111
111111111777777000000000076ccccc00000ccc000000000000000000000000000000000000000005505555000000000000000001ccccccc777777111111111
1111111117777770000100000667cccc000001ccc00000000000000000000000000000000000000000005555000000000000000001cc1ccc1777777111111111
11111111177777700001000006ccccccc0cc01ccc00000000000000000000000000000000000000000000000000000000000000001cc11c10777777111111111
11111111177777700001000007ccccccc1ccc11c1000000000000000000000000000000000000000005555500000000000000000011111100777777111111111
11111111177777700001000007ccccccc1ccc0111000000000000000000000000000000000000000005555500000000000000000001101000777777111111111
1111111117777770000c0000077cccccc11c00000000000000000000000000000000000000000000000000000000000000000000000000000777777111111111
11111111177777700000000007ccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000777777111111111
111111111777777000000000077ccccc01c00cc00000000000000000000000000000000000000000000000000000000000000000000000000777777111111111
111111111777777000000000076ccccc00000ccc0000000000000000000000000000000000000000000000000005555500000000000000000777777111111111
1111111117777770000000000667cccc000001ccc000000000000000000000000000000000000000000000000005ddd500000000000000000777777111111111
11111111177777700000000006ccccccc0cc01ccc000000000000000000000000000000000000000000000000000ddd000000000000000000777777111111111
11111111177777700000000007ccccccc1ccc11c1000000000000000000000000000000000000000000000000000005550000000000000000777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
111111111777777777777777777777777777777777ddd7ddd7ddd77dd77dd777777ddddd7777d77ddddd77777777777777777777777777777777777111111111
111111111777777777777777777777777777777777d7d7d7d7d777d777d7777777dd777dd77d77dd7d7dd7777777777777777777777777777777777111111111
111111111777777777777777777777777777777777ddd7dd77dd77ddd7ddd77777dd7d7dd77d77ddd7ddd7777777777777777777777777777777777111111111
111111111777777777777777777777777777777777d777d7d7d77777d777d77777dd777dd77d77dd7d7dd7777777777777777777777777777777777111111111
111111111777777777777777777777777777777777d777d7d7ddd7dd77dd7777777ddddd77d7777ddddd77777777777777777777777777777777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
11111111177777777777777777777777111717177777111717171117777711777777111711177777111711171117111777777777777777777777777111111111
11111111177777777777777777777777171717177777717717171777777717177777171717177777717717771717111777777777777777777777777111111111
11111111177777777777777777777777117711177777717711171177777717177777111711177777717711771117171777777777777777777777777111111111
11111111177777777777777777777777171777177777717717171777777717177777177717177777717717771717171777777777777777777777777111111111
11111111177777777777777777777777111711177777717717171117777717177177177711177777717711171717171777777777777777777777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
11111111177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777111111111
11111111117777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777771111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ddd1ddd11dd1ddd1dd1111111dd1dd1111111dd1ddd1d111ddd11dd1ddd1ddd11111ddd1d1d11111ddd1d1d11dd1d1d111111dd1ddd1ddd1ddd11dd1111
11111d1d1d1d1d111d111d1d11111d1d1d1d11111d111d111d111d111d1111d11d1111111d1d1d1d11111d111d1d1d1d1d1d11111d111d1d1ddd1d111d111111
11111dd11ddd1ddd1dd11d1d11111d1d1d1d11111d111dd11d111dd11ddd11d11dd111111dd11ddd11111dd111d11d1d1dd111111d111ddd1d1d1dd11ddd1111
11111d1d1d1d111d1d111d1d11111d1d1d1d11111d111d111d111d11111d11d11d1111111d1d111d11111d111d1d1d1d1d1d11111d1d1d1d1d1d1d11111d1111
11111ddd1d1d1dd11ddd1ddd11111dd11d1d111111dd1ddd1ddd1ddd1dd111d11ddd11111ddd1ddd11111ddd1d1d1dd11d1d11111ddd1d1d1d1d1ddd1dd11111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111