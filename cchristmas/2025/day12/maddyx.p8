pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--~madeline x~
--by meep
--based on celeste classic
--by maddy thorson and noel berry

-- "data structures"

function vector(x,y)
 return {x=x,y=y}
end

function zvec()
 return vector(0,0)
end

function rectangle(x,y,w,h)
 return {x=x,y=y,w=w,h=h}
end

-- camera stuff

function init_cam()
 _cam_x,_cam_y,cam_x,cam_y,cam_dx,cam_dy,cam_g=usplit"0,0,0,0,0,0,0.25"
end

function move_cam(ins,g)
 local rm=get_room(ins.hmid(),ins.vmid())
 if not rm then
  return
 end
 local rx,ry,rw,rh=usplit(rm_data[rm])
 local k=g or cam_g
 cam_dx,cam_dy=
  e_appr_delta(cam_x,mid(8*rx,ins.hmid()-63,8*rx+8*rw-128),k),
  e_appr_delta(cam_y,mid(8*ry,ins.vmid()-63,8*ry+8*rh-128),k)
 _cam_x+=cam_dx
 _cam_y+=cam_dy
 cam_x,cam_y=round(_cam_x),round(_cam_y)
end

function cam_draw()
 camera(cam_x,cam_y)
end

-- [entry point]

function _init()
 exec[[poke◆0x5f2e,1
init_cam
init_g_particles
title_init]]
end

function begin_game()
 seconds_f,
 minutes,
 deaths,
 hearts,
 delay_restart=usplit"0,0,0,0,0"
 _update,_draw,ticking=
  game_update,game_draw,true
 hp_max,yolo,has_ryuenjin,
 show_boss_hp=6,{},false,false
 load_room(1)
end

-- [main update loop]

function game_update()
 -- in-game time
 if ticking then
  seconds_f+=1
  minutes+=seconds_f\1800
  seconds_f%=1800
 end
 if show_stats then
  show_stats=max(show_stats-1)
  if show_stats==1 then
   sfx"15"
  end
 end
 -- update each object
 foreach(objects,function(obj)
  if obj.freeze>0 then
   obj.freeze-=1
   return
  end
  obj.move(obj.spd.x,obj.spd.y)
  obj:update()
 end)
 -- room restart
 if delay_restart>0 then
  delay_restart-=1
  if delay_restart==0 then
   load_room(get_room(sx,sy))
  end
 end
 -- change room
 local p=get_player()
 if p then
  local p_room=get_room(p.hmid(),p.vmid())
  if p_room and p_room~=room then
   load_room(p_room)
  end
 end
end

-- [drawing functions]

function init_g_particles()
 clouds={}
 for i=0,8 do
  add(clouds,{
   x=rnd"128",
   y=rnd"32",
   spd=0.25+rnd"0.75",
   w=32+rnd"32",
  })
 end
end

function game_draw()
 -- local copies for _ENV stuff
 local p,
 smoke,
 dead_particles,
 draw_spr,
 cam_dx,
 rnd,
 rectfill=
  get_player(),
  smoke,
  dead_particles,
  draw_spr,
  cam_dx,
  rnd,
  rectfill

 exec[[pal
camera
cls◆3]]

 fillp"0b1010010110100101.1"
 foreach(clouds,function(_ENV)
  x+=spd-(p and cam_dx/2 or 0)
  for i=0,2 do
   rectfill(x-i,y+i,x+w+i,y+16-w*0.1875-i,1)
  end
  if x>128 then
   x,y=-w,rnd"32"
  end
 end)
 fillp()

 for i=0,63 do
  local h=round(92+2*sin((4*rx+i+0.5*cam_x)/64))
  rectfill(i*2,h,i*2+1,127,1)
  rectfill(i*2,h-2,i*2+1,h-2,1)
 end
 cam_draw()
 
 -- sort instances
 pre_draw,post_draw=
  sort(filter(objects,function(_ENV) return layer<0 end),"layer"),
  sort(filter(objects,function(_ENV) return layer>=0 end),"layer")

 -- draw objs + terrain
 exec[[foreach◆pre_draw,draw_obj
cmap◆0b11
foreach◆post_draw,draw_obj]]
 
 -- smoke
 foreach(smoke,function(_ENV)
  _spr+=0.2
  x+=spd.x
  y+=spd.y
  if _spr>=16 then
   del(smoke,_ENV)
  else
   draw_spr(_ENV)
  end
 end)
 
 -- dead particles
 foreach(dead_particles,function(_ENV)
  x+=dx
  y+=dy
  k-=0.2
  if k<=0 then
   del(dead_particles,_ENV)
  end
  rectfill(x-k,y-k,x+k,y+k,6+k*5%2)
 end)
 
 -- reset cam, set secret pal
 exec[[camera
pal◆14,134,1
pal◆3,129,1]]

 -- timer
 if get_obj(player_spawn) then
  exec[[draw_time◆4,4]]
 end
 
 -- health bar
 local p=get_player() or get_obj(player_spawn)
 local hp=p and p.hp or 0
 _y1=47-2*hp_max
 _y2=_y1+1
 exec[[rectfill◆5,50,11,_y1,7
rectfill◆4,49,12,_y2,7
rectfill◆5,49,11,_y2,0
spr◆72,1,50
spr◆72,8,50,1,1,true]]
 for i=0,hp-1 do
  _y1=48-2*i
  _y2=_y1-1
  exec[[rectfill◆6,_y1,10,_y2,11
rectfill◆9,_y1,9,_y2,7]]
 end

 if show_boss_hp then
  local b=get_obj(mandrill)
  local hp=b and (b.state=="spawn" and 16*(1-mid(0,1,(b.t-35)/45)) or b.hp) or 0
  _y1=47-32
  _y2=_y1+1
  exec[[rectfill◆116,50,122,_y1,7
rectfill◆115,49,123,_y2,7
rectfill◆116,49,122,_y2,0]]
  for i=0,hp-1 do
  _y1=48-2*i
  _y2=_y1-1
  exec[[rectfill◆117,_y1,121,_y2,11
rectfill◆120,_y1,120,_y2,7]]
  end
  -- lines
  _y2=b and (b.state=="spawn" and 32+87*(1-mid(0,1,(b.t-35)/45)) or 119) or 119
  line(0,32,0,_y2,7)
  line(127,32,127,_y2,7)
 end
 if show_stats==0 then
	 exec[[camera◆0,-12
rectfill◆36,-1,90,31,0
rectfill◆35,0,91,30,0
rect◆36,0,90,30,5
draw_time◆41,15
camera◆0,-12
spr◆31,48,20]]
	   cprint("deaths:"..deaths,0,13,7)
	   cprint(":"..hearts.."/4",4,22,7)
	   cam_draw()
	end
end
-->8
-- helper functions

-- draw from map relative to camera
function cmap(flag)
 map(cam_x\8,cam_y\8,cam_x\8*8,cam_y\8*8,17,17,flag)
end

-- screen fader
function screen_fade(t,c)
 if t then
  fillp(split"0x.8,0xa05.8,0x5a5a.8,0xfaf5.8,0xffff.8"[mid(1,5,flr(0x1.ffff+0x3.0001*t))])
  color(c)
  exec[[rectfill◆0,0,127,127
fillp]]
 end
end

-- linear approach
function l_appr(val,target,amt)
 return val>target and max(val-amt,target) or min(val+amt,target)
end

-- exponential approach (delta)
function e_appr_delta(val,target,gain)
 return gain*(target-val)
end

-- sgn but with zero
function sign(x)
 return x==0 and 0 or sgn(x)
end

-- round
function round(x)
 return flr(x+0.5)
end

-- get tile relative to room
function tile_at(tx,ty)--,oob)
 return mget(tx,ty)
end

-- 0-pads number to be 2 chars
function two_digit_str(x)
 return x<10 and "0"..x or x
end

-- draw in-game time
function draw_time(x,y)
 camera(-x,-y)
 exec[[rectfill◆0,0,44,6,0
camera
color◆7]]
 ?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1
end

-- draw room title
function draw_room_title(y)
 local w2=2*#rt
 local x1,x2=64-w2,64+w2
 rectfill(x1-6,y,x2+4,y+16,0)
 rect(x1-5,y+1,x2+3,y+15,14)
 ?rt,x1,y+6,7
end

-- table filter (not-in-place)
function filter(tbl,f)
 local filtered={}
 foreach(tbl,function(x)
  if f(x) then add(filtered,x) end
 end)
 return filtered
end

-- table sort by idx k (not-in-place)
function sort(tbl,k)
 local sorted={}
 foreach(tbl,function(x)
  for i=1,#sorted do
   if x[k]<=sorted[i][k] then
    return add(sorted,x,i)
   end
  end
  add(sorted,x)
 end)
 return sorted
end

-- split, access _ENV, and unpack
function usplit(str,d)
 if str then
  local tbl=split(str,d)
  for k,v in pairs(tbl) do
   tbl[k]=_ENV[v] or v
  end
  return unpack(tbl)
 end
end

function exec(fns)
 foreach(split(fns,"\n"),function(ln)
  local fn,params=usplit(ln,"◆")
  fn(usplit(params))
 end)
end

-- get all instances of obj
function get_objs(obj)
 return filter(objects,function(ins) return ins.obj==obj end)
end

-- get first instance of obj
function get_obj(obj)
 return get_objs(obj)[1]
end

-- get player (or player spawn)
function get_player(incl_spawn)
 return incl_spawn and get_obj(player_spawn) or get_obj(player)
end

-- obj sprite drawer
function draw_spr(o,dx,dy)
 spr(o._spr,o.x+(dx or 0),o.y+(dy or 0),1,1,o.flp.x,o.flp.y)
end

-- obj drawer (to pass to foreach)
function draw_obj(o)
 o:draw()
end

-- vector magnitude
function mag(v)
 return sqrt(v.x^2+v.y^2)
end

-- trifill
function trifill(x1,y1,x2,y2,x3,y3,c)
 local pts,top,bot={{x1,y1},{x2,y2},{x3,y3}},0x7fff.ffff,0x8000.0000
 for pt in all(pts) do
  top,bot=min(top,pt[2]),max(bot,pt[2])
 end
 for _y=ceil(top),bot do
  local x1,x2=0x7fff.ffff,0x8000.0000
  for i,p1 in pairs(pts) do
   local p2=pts[1+i%#pts]
   if mid(_y,p1[2],p2[2])==_y then
    local _x=round(p1[1]+(_y-p1[2])/(p2[2]-p1[2])*(p2[1]-p1[1]))
    x1,x2=min(x1,_x),max(x2,_x)
   end
  end
 rectfill(x1,_y,x2,_y,c)
 end
end

-- tri-rect collision
function hit_tri_rect(ax,ay,bx,by,cx,cy,x,y,w,h)
 w-=1
 h-=1
 if min(min(ax,bx),cx)>=x+w or max(max(ax,bx),cx)<=x or
    min(min(ay,by),cy)>=y+h or max(max(ay,by),cy)<=y then
  return
 end
 local function s(ux,uy,vx,vy,wx,wy)
  local nx,ny=uy-vy,vx-ux
  local d,d3=nx*ux+ny*uy,nx*wx+ny*wy
  local b=nx*x+ny*y
  local mn,mx=b+min(nx*w)+min(ny*h),b+max(nx*w)+max(ny*h)
  if mn>=d and mn>=d3 or mx<=d and mx<=d3 then
   return true
  end
 end

 return not (s(ax,ay,bx,by,cx,cy) or 
             s(bx,by,cx,cy,ax,ay) or 
             s(cx,cy,ax,ay,bx,by))
end

-- make particles
function make_particles(tbl,x,y,spd,c,w)
 add(tbl,{x=x,y=y,spd=spd,w=w,c=c,t=0})
end

-- update particles
function update_particles(tbl)
 local d=del
 foreach(tbl,function(_ENV)
  x+=spd.x
  y+=spd.y
  spd.y+=tbl.grav or 0
  t+=1
  if t==tbl.duration then
   d(tbl,_ENV)
  end
 end)
end

function draw_particles(tbl)
 local r=rectfill
 foreach(tbl,function(_ENV)
  r(x,y,x+w-1,y+w-1,c)
 end)
end

function pal_all(c)
 for i=0,15 do
  pal(i,c)
 end
end

function psfx(n)
 sfx"-1"
 sfx(n)
end

function play_music(n,fade,mask)
 if curr_music~=n then
  curr_music=n
  music(n,fade,mask)
 end
end

function spr_r(n,x,y,a,flp)
  local sx,sy,ca,sa=n%16*8,n\16*8,cos(a),sin(a)
  local dx,dy,x0,y0=ca,sa,4+3.5*(sa-ca),4-3.5*(sa+ca)
  for _x=0,7 do
    local srcx,srcy=x0,y0
    for _y=0,7 do
      if (srcx|srcy)&-8==0 then
        local c=sget(sx+srcx,sy+srcy)
        if c~=0 then pset(x+(flp and 7-_x or _x),y+_y,c) end
      end
      srcx,srcy=srcx-dy,srcy+dx
    end
    x0,y0=x0+dx,y0+dy
  end
end

function cprint(t,dx,y,c)
 ?t,64-2*#t+dx,y,c
end

_btn=btn
-->8
-- room stuff

--[[
tx,
ty,
tw,
th,
room_title,
exits:obru,
entrance:{"left","top","bottom"},
]]
rm_data,rexec=
split([[0,0,22,16
22,5,16,27
0,18,22,16
1,34,16,16
17,32,16,16
33,32,16,16
49,23,16,16
65,23,16,16
62,5,24,18
46,5,16,16
86,5,20,18
106,9,16,24
86,23,20,16
77,39,16,16
93,39,16,16
109,39,16,16]],"\n"),
{}

function get_room(x,y)
 for rm=1,#rm_data do
  local rx,ry,rw,rh=usplit(rm_data[rm])
  if x>=8*rx and x<8*(rx+rw) and y>=8*ry and y<8*(ry+rh) then
   return rm
  end
 end
end

function load_room(rm)
 exec[[reload◆0x1000,0x1000,0x2000]]
 room=rm
 rx,ry,rw,rh=usplit(rm_data[rm])
 local p=get_player()
 objects,smoke,dead_particles=
  p and {p} or {},
  smoke or {},
  dead_particles or {}
 for ty=ry,ry+rh-1 do
  for tx=rx,rx+rw-1 do
   local t=tile_at(tx,ty)
   local hash=tx..","..ty
   if tiles[t] and not yolo[hash] then
    local o=init_object(tiles[t],8*tx,8*ty,t)
    o._hash=hash
   end
   if t==1 then
    sx,sy=8*tx,8*ty
   end
  end
 end
 if not get_player(true) then
  init_object(player_spawn,sx,sy,1)
 end
 if rm>=15 then
  if p then
   p.move(2,0)
  end
  if rm==15 then
   exec[[mset◆92,49,47
mset◆92,50,47
memcpy◆0x8000,0,0x2000]]
  else
   exec[[mset◆108,52,47
mset◆108,53,47
memcpy◆0x8000,0,0x2000]]
  end
 end
 play_music(not has_ryuenjin and rm==7 and 17 or 0,0,0b11)
 btn=_btn
 show_stats=false
 show_boss_hp=false
end
--[[
function load_map()
 rx,ry,rw,rh=0,0,0,0
 objects,smoke,dead_particles={},{},{}
 for ty=0,63 do
  for tx=0,127 do
   local t=tile_at(tx,ty)
   if tiles[t] then
    init_object(tiles[t],8*tx,8*ty,t)
   end
  end
 end
end]]
-->8
-- object stuff

-- [player entity]

player={
 init=function(this)
  this.layer,this.grace,this.jbuffer,this.djump,
  this.climb_cd,
  this.dash_cd,this.dash_time,
  this.dash_target_x,this.dash_target_y,
  this.dash_accel_x,this.dash_accel_y,
  this.hitbox,
  this.spr_off,
  this.solid,this.rider,
  this.slash_t,this.sword,this.sparticles,
  this.hp,this.iframes=
  1,0,0,1,
  0,
  0,0,
  0,0,
  0,0,
  rectangle(usplit"1,3,6,5"),
  0,
  true,true,
  0,{},{duration=3},
  hp_max,0
  create_hair(this)
 end,
 update=function(this)
  -- nab camera
  move_cam(this)
  
  -- iframes and dying
  if this.hp==0 then
   kill_obj(this)
   return
  end
    -- spike collision / bottom death
  if this.hp==0 or
   this.is_flag(0,0,"spike") and this.iframes==0 or 
   not get_room(this.hmid(),this.top()-8) then
   kill_obj(this)
   return
  end
  this.iframes=max(this.iframes-1)
  
  -- input
  local h_input,v_input
  if this.iframes>15 then
   h_input,v_input=0,0
  else
   h_input,v_input=
	   tonum(btn"1")-tonum(btn"0"),
	   tonum(btn"3")-tonum(btn"2")
	 end
  local on_ground=this.is_solid(0,1)
  local mid_ryuenjin=this.slash_t>2 and this.slash_type=="ryuenjin"
  local wallslide=not on_ground and h_input~=0 and this.is_solid(h_input,0)
  
  -- update sword
  this.slash_t=max(this.slash_t-1)
  if this.slash_t>2 then
   if this.slash_type=="ryuenjin" then
    local k,xdir=1-(this.slash_t-3)/4,this.flp.x and -1 or 1
    local x1,y1,as=(this.flp.x and 3 or 2)+(1-k)*2,4-k*8,-(1-k)*0.1+k*0.25
    add(this.sword,{xdir*x1,y1,xdir*(x1+8*cos(as)),y1+8*sin(as),4,this.slash_type})
    for i=1,5 do
     local p=sqrt(rnd())
     make_particles(
      this.sparticles,
      this.hmid()+xdir*(x1+p*8*cos(as)),
      this.vmid()+y1+p*8*sin(as),
      vector(rnd"1"-0.5,-0.5-rnd"1"),
      rnd()<0.5 and 8 or rnd()<0.5 and 9 or 10,
      2)
    end
   else
    local k,xdir=1-(this.slash_t-3)/4,(this.flp.x and -1 or 1)*(wallslide and -1 or 1)
    local x1,y1,as=(this.flp.x and 3 or 2)+k*2,-4+k*8,(1-k)*0.35-k*0.1
    add(this.sword,{xdir*x1,y1,xdir*(x1+8*cos(as)),y1+8*sin(as),4,this.slash_type})
   end
  end
  foreach(this.sword,function(s)
   s[5]-=1
	  if s[5]==0 then
	   del(this.sword,s)
	  end
  end)
  update_particles(this.sparticles)
  
  -- physics
  local maxrun,accel,deccel,maxfall,grav=
   (on_ground and this.slash_t>0 or mid_ryuenjin) and 0.5 or 2.0,
   on_ground and 0.93 or mid_ryuenjin and 0.2 or 0.80,
   (on_ground and this.slash_t>0 or mid_ryuenjin) and 1 or 0.16,
   3.0,
   abs(this.spd.y)>0.124 and 0.334 or 0.167

  -- landing smoke
  if on_ground and not this.was_on_ground then
   this.init_smoke(0,4)
  end
  this.was_on_ground=on_ground

  -- jump and dash input
  local jump,slash=btn"4" and not this.p_jump,btn"5" and not this.p_slash
  this.p_jump,this.p_slash=btn"4",btn"5"

  -- jump buffer
  if jump then
   this.jbuffer=4
  elseif this.jbuffer>0 then
   this.jbuffer-=1
  end

  -- grace frames and dash restoration
  if on_ground then
   this.grace=6
   if this.djump<1 then
    sfx"14"
    this.djump=1
   end
  elseif this.grace>0 then
   this.grace-=1
  end
  
  -- set x speed
  this.spd.x=abs(this.spd.x)<=maxrun and
   l_appr(this.spd.x,h_input*maxrun,accel) or
   l_appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)

  -- facing direction
  if this.spd.x~=0 then
   this.flp.x=this.spd.x<0
  end

  -- wall slide
  if h_input~=0 and this.is_solid(h_input,0) then
   maxfall=0.8
   -- wall slide smoke
   if rnd"10"<2 then
    this.init_smoke(h_input*6)
   end
  end

  -- apply gravity
  if not on_ground then
   this.spd.y=l_appr(this.spd.y,maxfall,grav)
  end

  -- jump
  if this.jbuffer>0 then
   if this.grace>0 then
    -- normal jump
    sfx"50"
    this.jbuffer,this.grace,this.spd.y=
     0,0,-3.36
    this.init_smoke(0,4)
   else
    -- wall jump
    local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
    if wall_dir~=0 then
     sfx"2"
     this.jbuffer,this.spd=0,vector(-wall_dir*(maxrun+0.6),-3.36)
     -- wall jump smoke
     this.init_smoke(wall_dir*6)
    end
   end
  end
  if slash and this.slash_t==0 then
   if has_ryuenjin and this.grace>0 and v_input<0 then
    this.spd.y=-4.51
    this.slash_type,this.slash_t="ryuenjin",8
   else
    this.slash_type,this.slash_t="neutral",8
   end
   sfx"19"
  end

  -- animation
  this.spr_off+=0.25
  this._spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or  -- wall slide or mid air
   btn(⬇️) and 6 or -- crouch
   btn(⬆️) and 7 or -- look up
   1+(this.spd.x~=0 and h_input~=0 and this.spr_off%4 or 0) -- walk or stand
 end,

 draw=function(this)
  -- draw player hair and sprite
  pal(8,this.djump==1 and 8 or 12)
  if this.iframes\2%2==1 then
   pal_all"7"
  end
  draw_hair(this)
  draw_spr(this,0,flr(this._spr)==3 and -1 or 0)
  pal()
  -- draw sword
  if this.sword and #this.sword>1 then
	  local px,py=this.hmid(),this.top()
	  for i=1,#this.sword-1 do
	   local x1,y1,x2,y2,_,_type=unpack(this.sword[i])
	   local x3,y3,x4,y4,_,_=unpack(this.sword[i+1])
	   local c=_type=="ryuenjin" and 8 or 9
	   trifill(px+x1,py+y1,px+x2,py+y2,px+x3,py+y3,c)
	   trifill(px+x2,py+y2,px+x3,py+y3,px+x4,py+y4,c)
	  end
	  draw_particles(this.sparticles)
	  cam_draw()
	 end
 end
}

function create_hair(obj)
 obj.hair={}
 for i=1,5 do
  add(obj.hair,vector(obj.x,obj.y))
 end
end

function draw_hair(obj)
 local last=vector(obj.x+4-(obj.flp.x and-2 or 3),obj.y+(btn(⬇️) and 4 or 2.9))
 for i,h in pairs(obj.hair) do
  h.x+=(last.x-h.x)/1.5
  h.y+=(last.y+0.5-h.y)/1.5
  circfill(round(h.x),round(h.y),mid(4-i,1,2),8)
  last=h
 end
end

-- [other entities]

player_spawn={
 init=function(this)
  sfx"1"
  move_cam(this,1)
  this.target,this.t,this.hp=this.y,0,0
 end,
 update=function(this)
  this.t+=1
  if this.t==30 then
   this.init_smoke(0,4)
  end
  if this.t>30 then
   psfx"0"
   this.hp=min(1,(this.t-30)/15)*hp_max
   if this.t==45 then
    this.delete()
    init_object(player,this.x,this.y)
   end
  end
 end,
 draw=function(this)
  if this.t<30 then
	  local k=max(1-this.t/30)
	  local off,px,py=k*-128,this.x+4,this.bottom()
	  rectfill(px-1,py-15+off,px+2,py+off,8)
	  rectfill(px,py-16+off,px+1,py+1+off,8)
	  fillp"0b0001001001001000"
	  rectfill(px,py-15+off,px+1,py+off,0x7e)
	  fillp()
	 else
	  if this.t<40 then
	   pal_all(this.t>33 and 7 or 8)
	  end
	  spr(7,this.x,this.y)
	  pal()
	 end
 end,
}

capsule={
 init=function(this)
  if this._spr==44 then
   this.hitbox=rectangle(usplit"0,4,8,4")
   init_object(capsule,this.x,this.y,0)
  else
   this.y-=8
   this.hitbox=rectangle(usplit"0,0,8,4")
  end
  this.layer=5
 end,
 update=function(this)
  if this._spr==44 then
   if not this.t then
    local p=this.check(player,0,-1)
    if p then
     music"-1"
     btn=function() return false end
     p.spd=zvec()
     if this.hmid()~=p.hmid() then
      p.move(sign(this.hmid()-p.hmid()),this.vmid()-p.vmid())
     else
      this.t=0
     end
    end
   elseif this.t<155 then
    local p=get_player()
    this.t+=1 
    p.spd.x=this.t>=150 and 0 or this.t>135 and 1 or 0
    if this.t==30 then
     sfx"22"
    elseif this.t==120 then
     sfx"18"
     this.init_smoke(0,-4)
    elseif this.t==150 then
     has_ryuenjin=true
     btn=function(i) return i=="2" or i=="5" end
    elseif this.t==155 then
     this.yolo()
     btn=_btn
     play_music(0,0,0b11)
    end
   end
  end
 end,
 draw=function(this)
  sspr(96,this._spr==44 and 20 or 16,8,4,this.x,this.y+(this._spr==44 and 4 or 0))
  if this._spr==44 and this.t then
   if this.t>30 and this.t<120 then
    for i=0,7 do
     if this.t>115 or rnd()<0.5 then
      line(this.x+i,this.y-4,this.x+i,this.y+3,7)
     end
    end
   end
  end
 end
}

heart={
 init=function(this) 
  this.y_,this.off,this.hitbox=
   this.y,0,rectangle(usplit"1,1,6,6")
 end,
 update=function(this)
  local p=this.player_here()
  if p then
   this.yolo()
   this.delete()
   init_object(lifeup,this.hmid(),this.vmid(),"+1")
   hearts+=1
   hp_max+=1
   p.hp+=1
   psfx"11"
  end
  this.off+=1
  this.y=round(this.y_+sin(this.off/40)*1.5)
 end
}

lifeup={
 init=function(this)
  this.spd.y,this.duration=-0.25,30
  sfx"8"
 end,
 update=function(this)
  this.duration-=1
  if this.duration<=0 then
   this.delete()
  end
 end,
 draw=function(this)
  ?this._spr,this.x-4,this.y-4,7+t()*15%3
 end
}

crumble={
 init=function(this)
  this.solid,this.ride=true,true
 end,
 update=function(this)
  local on_ground,hitc,hitp=
   this.is_solid(0,1),
   this.check(crumble,0,-1),
   this.check(player,0,-1) or this.check(player,-1,0) or this.check(player,1,0)
  if not this.t and (hitp or hitc and hitc.t) then
   this.t=this.is_flag(0,1,0) and 0 or 15
   sfx"9"
  elseif this.t then
   this.t=max(this.t-1)
   if this.t==0 then
    this.spd.y=l_appr(this.spd.y,rwl and this.bottom()>=rwl and 2 or 4,0.3)
   end
   if on_ground and not this.wog then
    this.init_smoke(0,4)
   end
  end
  this.wog=on_ground
  if this.oob(0,0) then
   this.delete()
  end
 end,
 draw=function(this)
  spr(this._spr,this.x+(this.t and this.t>0 and rnd"2"-1 or 0),this.y)
 end
}

flag={
 update=function(this)
  if not this.touched and this.player_here() then
   sfx"15"
   this.touched,ticking=true,false
  end
 end,
 draw=function(this)
  for i=0,this.touched and 4 or 1 do
   camera(-i-this.x,-this.y-(this.touched and -sin(t()+i/5) or 2*i))
   exec[[rectfill◆3,0,3,2,11
cam_draw]]
  end
 end
}

met={
 init=function(this)
  enemy_init(this,1,"hide")
  this.flp.x,this.hitbox=
   this._spr==9,rectangle(usplit"0,2,8,6")
 end,
 update=function(this)
  enemy_update(this,this.state=="hide")
  local p=get_player()
  if this.state=="hide" then
   if this.t==0 then
	   local d=p and mag(vector(p.hmid()-this.hmid(),p.vmid()-this.vmid())) or 0x7fff.ffff
	   if d<24 and d>12 then
	    this.state,this.t,this.dir="up",45,sgn(p.x-this.x)
	    this.flp.x=this.dir>0
	   end
	  end
  else
   if p then
    if this.t==40 then
     sfx"4"
     for a=0,0.083,0.0415 do
      local l=init_object(lemon,this.x,this.y,12)
      l.spd=vector(this.dir*2*cos(a),2*sin(a))
     end
    elseif this.t<40 then
     this.spd.x=0.5*this.dir
    end
   end
   if this.t==0 then
    this.state,this.spd.x,this.t="hide",0,60
   end
  end
  this._spr=this.state=="hide" and 8 or this.spd.x~=0 and 9+5*t()%3 or 10
 end,
 draw=function(this)
  draw_spr(this)
 end
}

function hurt_player(this,dmg)
 local p=this.player_here()
 if p and p.iframes==0 then
  sfx"21"
  p.hp=max(p.hp-dmg)
  p.iframes=20
  p.move(2*sign(p.hmid()-this.hmid()),0)
  p.spd.y=-1
  return true
 end
end

gunvolt={
 init=function(this)
  enemy_init(this,8,"idle")
  this.flp.x,this.hitbox,this._spr=
   this._spr==33,rectangle(usplit"3,4,10,12"),16
 end,
 update=function(this)
  enemy_update(this)
  local p=get_player()
  if this.state=="idle" then
   local d=p and mag(vector(p.hmid()-this.hmid(),p.vmid()-this.vmid())) or 0x7fff.ffff
   if this.t==0 and d<48 then
    this.flp.x=p.hmid()>this.hmid()
    this.state,this.t="bobbing",30
   end
  elseif this.state=="bobbing" then
   if this.t==0 then
    this.state,this.t,this.atk="pew",30,rnd()<0.5 and "lemon" or "crawler"
   end
  elseif this.state=="pew" then
   if this.t==15 or this.t==(this.atk=="lemon" and 5 or 12) then
    if this.atk=="lemon" then
     sfx"4"
     local l=init_object(lemon,this.x+4,this.y+5,28)
     l.particles,l.flp.x,l.spd.x={duration=3},this.flp.x,this.flp.x and 2 or -2
    else
     sfx"10"
     init_object(crawler,this.x+4,this.y+10,29).spd.x=this.flp.x and 2.5 or -2.5
    end
   elseif this.t==0 then
    this.state,this.t="idle",3
   end
  end
  this._spr=
   this.state=="idle" and (this.t>0 and 19 or 16+4*t()%2) or 
   this.state=="bobbing" and 16+10*t()%2 or
   this.state=="pew" and (this.t>27 and 19 or 20) or 
   16
 end,
 draw=function(this)
  if this.iframes\2%2==1 then
   pal_all"7"
  end
  spr(flr(this._spr)*2,this.x,this.y,2,2,this.flp.x,false)
  pal()
 end,
}

lemon={
 init=function(this)
  this.hitbox,this.layer=rectangle(usplit"2,4,4,3"),2
 end,
 update=function(this)
  if this.particles then
   update_particles(this.particles)
   make_particles(this.particles,this.hmid(),this.vmid(),vector(-sgn(this.spd.x)*rnd"1",rnd"1"-0.5),rnd()<0.5 and 14 or 6,1)
  end
  local hit_wall=this.is_solid(0,0)
  if hurt_player(this,1) or hit_wall or this.oob(0,0) then
   this.delete()
  end
  if hit_wall then
   this.init_smoke()
  end
 end,
 draw=function(this)
  if this.particles then
   draw_particles(this.particles)
  end
  if this._spr==26 then
   spr(26+15*t()%2,this.x,this.y)
  else
   draw_spr(this)
  end
 end,
}

crawler={
 init=function(this)
  this.solid,this.hitbox,this.t,this.layer=true,rectangle(usplit"2,2,4,4"),120,2
 end,
 update=function(this)
  hurt_player(this,1)
  this.t-=1
  if this.t==0 or this.oob(0,0) then
   this.delete()
  end
  this._spr=29+10*t()%2
 end,
 draw=function(this)
  pal(7,15*t()%2>1 and 9 or 10)
  draw_spr(this)
  pal()
  --rect(this.left(),this.top(),this.right(),this.bottom(),7)
 end,
 on_move=function(this,dx,dy)
  -- bump
  if this.is_solid(dx,dy) then
   if not this.is_solid(-dy,dx) then
    this.spd=vector(-this.spd.y,this.spd.x) 
    return true
   elseif not this.is_solid(dy,-dx) then
    this.spd=vector(this.spd.y,-this.spd.x)
    return true
   else
    this.delete()
   end
   return
  end
  -- float
  local attached=this.is_solid(0,1) or this.is_solid(0,-1) or this.is_solid(1,0) or this.is_solid(-1,0)
  if not attached then
   if this.is_solid(-dx-dy,-dy+dx) then
    this.spd=vector(-this.spd.y,this.spd.x)
    return true
   elseif this.is_solid(-dx+dy,-dy-dx) then
    this.spd=vector(this.spd.y,-this.spd.x)
    return true
   end
  end
 end
}

flammingle={
 init=function(this)
  enemy_init(this,3,"idle")
  this.hitbox,this.a,this.flp.x=
   rectangle(usplit"2,0,4,8"),0,this._spr==59
 end,
 update=function(this)
  enemy_update(this)
  local p=get_player()
  if this.state=="idle" then
   local d=p and mag(vector(p.hmid()-this.hmid(),p.vmid()-this.vmid())) or 0x7fff.ffff
   if this.t==0 and d<64 then
    this.state="pew"
   end
  else
   this.a=(this.a+1)%15
   if p and this.a==5 then
    local l=init_object(lemon,this.x,this.y-6,26)
    local a=atan2(p.hmid()-l.hmid(),p.vmid()-l.vmid())
    l.hitbox,l.spd=
     rectangle(usplit"3,3,3,3"),
     vector(3*cos(a),3*sin(a))
   end
   if this.a==0 then
    this.state,this.t="idle",60
   end
  end
 end,
 draw=function(this)
  if this.iframes\2%2==1 then
   pal_all"7"
  end
  local a=this.a/15
  spr(58,this.x,this.y,1,1,this.flp.x,nil)
  spr_r(59,this.x+(this.flp.x and -1 or 1)*(-1+2*sin(a)),this.y-2-2*cos(a),-a,this.flp.x)
  pal()
 end,
}

jamminger={
 init=function(this)
  enemy_init(this,2,"track")
  this.hitbox,this.tx,this.ty=
   rectangle(usplit"1,3,6,4"),this.x,this.y
 end,
 update=function(this)
  enemy_update(this,nil,0)
  local p=get_player()
  if this.state=="track" then
	  if p then
	   this.tx+=e_appr_delta(this.tx,p.hmid(),0.05)
	   this.ty+=e_appr_delta(this.ty,p.vmid(),0.05)
	   local a=atan2(this.tx-this.hmid(),this.ty-this.vmid())
    this.spd=vector(0.5*cos(a)+0.25*sin(t()),0.5*sin(a))
	  end
	  if this.player_here() then
	   this.ty-=24
	   this.state,this.t="heehee",30
	  end
  else
   this.spd=vector(0.25*sin(t()),-this.t/24)
   if this.t==0 then
    this.state="track"
   end
  end
 end,
 draw=function(this)
  if this.iframes\2%2==1 then
   pal_all"7"
  end
  spr(42,this.x,this.y,1,1,10*t()%2>1,nil)
  pal()
 end,
}

door={
 init=function(this)
  this.layer=-1
  this.hitbox.h+=8
 end,
 update=function(this)
  if not this.t then
   local p=this.check(player,-1,0)
   if p then
    btn=function() return false end
    this.t=0
   end
  else
   this.t=min(this.t+1,40)
   if this.t==40 then
    this.collideable=false
    btn=_btn
   end
  end
 end,
 draw=function(this)
  if not this.t or this.t<30 then
   spr(45,this.x,this.y)
   spr(45,this.x,this.y+8,1,1,nil,true)
   if this.t then
    spr_r(46,this.x,this.y+4,this.t/30)
   end
  else
   local off=min(8,this.t-30)
   spr(45,this.x,this.y-off)
   spr(45,this.x,this.y+8+off,1,1,nil,true)
  end
 end
}

function enemy_init(this,hp,s0)
 this.solid,this.rider,
 this.state,this.t,
 this.hp,this.iframes=
  true,true,s0,0,hp,0
end

function enemy_update(this,immune,grav)
 hurt_player(this,this.obj==mandrill and 2 or 1)
 this.iframes=max(this.iframes-1)
 local s=this.sword_here()
 if s and this.iframes==0 then
  if immune then
   sfx"10"
  else
	  sfx"21"
	  this.hp-=s=="ryuenjin" and 2 or 1
	  this.iframes=5
	  if this.obj~=mandrill and this.hp<=0 then
	   kill_obj(this,2)
	  end
	 end
 end
 this.t=max(this.t-1)
 this.spd.y+=grav or 0.22
end

--[[
0: neutral
1-2: fill hp
4-5: lunge
7: ow
16: jump
17-19: swing
21-22: pump
]]
mandrill={
 init=function(this)
  enemy_init(this,16,"spawn")
  this.t=120
  this._spr=0
  this.hitbox=rectangle(usplit"4,4,8,12")
 end,
 update=function(this)
  if this.hp<=0 and this.state~="dying" then
   music"-1"
   this.state,this.t,this._spr="dying",120,7
  end
  if this.state=="dying" then
   this.t=max(this.t-1)
   if this.t<105 then
    if rnd()<(this.t>85 and 0.25 or this.t>35 and 0.45 or 0.6) then
     sfx"21"
     this.init_smoke(rnd"8",rnd"8")
    end
   end
   if this.t==0 then
    kill_obj(this)
    music(63)
    ticking=false
    show_stats=30
   end
   return
  end
  enemy_update(this)
  local p=get_player()
  if not p then
   return
  end
  if this.state=="spawn" then
   btn=function() return false end
   if this.t>90 then
    p.spd.x=sign(888-p.x)
    p._spr=1+(p.spd.x~=0 and p.spr_off%4 or 0)
   elseif this.t>30 then
    if this.t<=85 then
     show_boss_hp=true
     psfx"0"
    end
    this._spr=this.t>85 and 1 or 2
   end
   if this.t==15 then
    btn=_btn
    this.state,this.t="neutral",10
   end
  elseif this.state=="neutral" then
   this._spr=this.is_solid(0,1) and 0 or 16
   if this.t==0 then
    local s=rnd()
    if s<0.1 then
     this.spd=vector(3*sgn(p.x-this.x),-3)
     this._spr=16
     this.init_smoke(4,12)
     this.state="jump"
     sfx"50"
    elseif s<0.4 then
     this.state,this.t="shock",30
    elseif s<0.7 then
     this.state,this.t="lunge",5
    elseif s<1.0 then
     this.state="swing"
     this.substate="rising"
     this.init_smoke(4,12)
     this._spr=16
     this.spd.y=-6
     sfx"50"
    end
   end
  elseif this.state=="jump" then
   this.spd.x=l_appr(this.spd.x,0,0.1)
   if this.is_solid(0,1) then
    this.init_smoke(4,12)
    this.spd.x=0
    this.state,this.t="neutral",5
   end
  elseif this.state=="shock" then
   this._spr=this.t>25 and 21 or 22
   if this.t==25 or this.t==22 then
    sfx"10"
    init_object(crawler,this.x+4,this.y+10,29).spd.x=2.5
    init_object(crawler,this.x+4,this.y+10,29).spd.x=-2.5
   end
   if this.t==0 then
    this.state,this.t="neutral",15
   end
  elseif this.state=="lunge" then
   this._spr=this.t>0 and 4 or 5
   if this.t==1 then
    sfx"18"
    this.spd.x=4*sgn(p.hmid()-this.hmid())
   end
   if this.t==0 then
    if rnd()<0.5 then
     this.init_smoke(4,12)
    end
    if this.spd.x==0 and (this.is_solid(-1,0) or this.is_solid(1,0)) or this.is_solid(this.spd.x,0) then
     this.state,this.t="neutral",20
    end
   end
  elseif this.state=="swing" then
   if this.substate=="rising" then
    if this.is_solid(0,-1) then
     this.substate="swinging"
    end
   elseif this.substate=="swinging" then
    this.spd.x=sign(p.x-this.x)+0.25*sin(2*t())
    this.spd.y=-1
    this._spr=round(18+sin(3*t()))
    if abs(p.hmid()-this.hmid())<2 then
     this.substate="falling"
    end
   else
    this.spd.x=l_appr(this.spd.x,0,0.05)
    this.spd.y+=0.1
    if this.is_solid(0,1) then
     sfx"9"
     this.init_smoke(1,12)
     this.init_smoke(5,12)
     for dir=-1,1,2 do
	     for a=0,0.083,0.0415 do
	      local l=init_object(lemon,this.x+4,this.y+8,12)
	      l.spd=vector(dir*2*cos(a),2*sin(a))
	     end
	    end
	    this.spd.x=0
	    this.state,this.t="neutral",20
    end
   end
  end
  if this.spd.x~=0 then
   this.flp.x=this.spd.x>0
  end
 end,
 draw=function(this)
  ssload"1"
  if this.iframes\2%2==1 then
   pal_all"7"
  end
  spr(this._spr\1*2,this.x,this.y,2,2,this.flp.x,this.flp.y)
  pal()
  ssload"0"
 end
}

-- [tile dict]
tiles={}
foreach(split([[8,met
9,met
32,gunvolt
33,gunvolt
42,jamminger
44,capsule
45,door
58,flammingle
59,flammingle
61,mandrill
23,crumble
31,heart
73,flag]],"\n"),function(ln)
 local k,v=usplit(ln)
 tiles[k]=v
end)
function init_object(obj,x,y,tile)
 local o={
 obj=obj,
 _spr=tile,
 hitbox=rectangle(usplit"0,0,8,8"),
 _hash="",
 x=x,
 y=y,
 rem=zvec(),
 spd=zvec(),
 flp=vector(),
 freeze=0,
 layer=0,
 collideable=true,
 solid=false,
 init=obj.init or t,
 update=obj.update or t,
 draw=obj.draw or draw_spr,
 on_move=obj.on_move
 }
 -- useful hitbox stuff
 function o.left() return o.x+o.hitbox.x end
 function o.right() return o.left()+o.hitbox.w-1 end
 function o.top() return o.y+o.hitbox.y end
 function o.bottom() return o.top()+o.hitbox.h-1 end
 function o.hmid() return round(o.left()+o.right()>>1) end
 function o.vmid() return round(o.top()+o.bottom()>>1) end
 -- tile-based collisions
 function o.is_flag(ox,oy,flag)
  local x1,x2,y1,y2=o.left(),o.right(),o.top(),o.bottom()
  for i=(x1+ox)\8,(x2+ox)\8 do
   for j=(y1+oy)\8,(y2+oy)\8 do
    local tile=tile_at(i,j)
    if flag=="spike" then
     if ({[17]=o.spd.y>=0 and y2%8>=5,
      [18]=o.spd.y<=0 and y1%8<=2,
      [19]=o.spd.x<=0 and x1%8<=2,
      [20]=o.spd.x>=0 and x2%8>=5})[tile] then
      return true
     end
    elseif fget(tile,flag) then
     return true
    end
   end
  end
 end
 -- hitbox overlap check
 function o.overlaps(other,ox,oy)
  return other.right()>=o.left()+ox and
   other.bottom()>=o.top()+oy and
   other.left()<=o.right()+ox and
   other.top()<=o.bottom()+oy
 end
 -- return all overlapped instances of an obj
 function o.check_all(obj,ox,oy,tbl)
  return filter(tbl or objects,function(other)
   return other.obj==obj and other~=o and other.collideable and o.overlaps(other,ox or 0,oy or 0)
  end)
 end
 -- return first overlapped instance of an obj
 function o.check(...)
  return o.check_all(...)[1]
 end
 -- player check
 function o.player_here()
  return o.check(player,0,0)
 end
 -- sword check
 function o.sword_here()
  local p=get_player()
  if p and p.sword and #p.sword>1 then
   local px,py=p.hmid(),p.top()
   for i=1,#p.sword-1 do
	   local x1,y1,x2,y2,_,_type=unpack(p.sword[i])
	   local x3,y3,x4,y4,_,_=unpack(p.sword[i+1])
	   if hit_tri_rect(px+x2,py+y2,px+x3,py+y3,px+x4,py+y4,o.left(),o.top(),o.hitbox.w,o.hitbox.h) then
	    return _type
	   end
	  end
  end 
 end
 -- yolo
 function o.yolo()
  yolo[o._hash]=1
 end
 -- solid check 
 function o.is_solid(ox,oy)
  return (oy>0 and not o.is_flag(ox,0,2) and o.is_flag(ox,oy,2))
   or o.is_flag(ox,oy,0)
   or o.check(crumble,ox,oy)
   or o.check(capsule,ox,oy)
   or o.check(door,ox,oy)
 end
 function o.oob(ox,oy)
  return get_room(o.hmid()+ox,o.vmid()+oy)~=room
 end
 function o.boundary(ox,oy)
  return o.left()+ox<0 or 
   o.right()+ox>=1024
 end
 -- place free check (solid or oob)
 function o.not_free(ox,oy)
  return o.is_solid(ox,oy) or o.boundary(ox,oy)
 end
 -- per-px movement
 function o.move(ox,oy)
  for axis in all{"x","y"} do
   o.rem[axis]+=axis=="x" and ox or oy
   local amt=flr(o.rem[axis]+0.5)
   o.rem[axis]-=amt
   if o.solid then
    local step=sign(amt)
    local dx=axis=="x" and step or 0
    local dy=step-dx
    for i=1,abs(amt) do
     if o.on_move and o:on_move(dx,dy) then
      return
     end
     if o.not_free(dx,dy) then
      o.rem[axis],o.spd[axis]=0,0
      break
     else
      o[axis]+=step
      if o.ride then
       foreach(filter(objects,function(other) return other.rider and (o.overlaps(other,0,0) or o.overlaps(other,-dx,-dy-1)) end),function(rider)
        if rider.not_free(dx,dy) then
         rider.rem[axis],rider.spd[axis]=0,0
        else
         if dy>0 and rider.spd[axis]==0 then
          rider.spd[axis]=0.5*o.spd[axis]
         end
         rider[axis]+=step
        end
        if rider.not_free(0,0) then
         kill_obj(rider)
        end
       end)
      end
     end
    end
   else
    o[axis]+=amt
   end
  end
 end
 -- instance deletion
 function o.delete()
  del(objects,o)
 end
 -- smoke effect
 function o.init_smoke(ox,oy)
  add(smoke,{
   x=o.x+(ox or 0)-1+rnd"2",
   y=o.y+(oy or 0)-1+rnd"2",
   spd=vector(0.3+rnd"0.2",-0.1),
   flp=vector(rnd()<0.5,rnd()<0.5),
   _spr=13
  })
 end
 -- init event
 o:init()
 -- add to obj list and return instance
 return add(objects,o)
end

function kill_obj(o,mag)
 o.delete()
 if o.obj==pickup then
  o.init_smoke()
  return
 elseif o.obj==player then
  delay_restart=15
  deaths+=1
 end
 psfx"49"
 mag=mag or 3
 for dir=0,0.875,0.125 do
  add(dead_particles,{
   x=o.hmid(),
   y=o.vmid(),
   k=mag-1,
   dx=sin(dir)*mag,
   dy=cos(dir)*mag
  })
 end
end
-->8
-- sprite sheet mgmt.

function load_gfx(i,gfx)
 local idx=0
 for i=1,#gfx,2 do
  for j=1,("0x"..gfx[i])+1 do
   sset(idx%128,idx\128,"0x"..gfx[i+1])
   idx+=1
  end
 end
 memcpy(0x8000+0x2000*i,0,0x2000)
 reload()
end

function ssload(i)
 memcpy(0,0x8000+0x2000*i,0x2000)
end

exec[[memcpy◆0x8000,0,0x2000
load_gfx◆1,f0f0f0f0f0f0f03026f0f0f0f0f0f0f0c026e0150015f0a0150015f0f0f0f07014021500151017500510051005a0150015800510051005f0a015001590150015f060140205100510050027300d02070905000709900510051005600d02070905000709f0900510051005700510051005f05004020d02070905000709042920040207190439700d0207090500070950040207190439f0700d02070905000709600d02070905000709f050041209074904090709200d02010901040709070960040207190439100607090d020109010407090709f06004020719043940040207190439f0500d0209010901070907292014060907090619070419400d02010901040709041900170904060907090619070419f0400d020109010407090419000607090d020109010407090709f05004060c0907090c0907010920140d02070607020709043920060406090709060904390607090d020706070207090439f02006040609070906090439170904060907090619070419f0300d02090706172930340208091204073920060d0207060702040739300402080912040739f020060d02070607020407390607090d020706070207090439f030040208091219401426210607040719301604020809060704071960210607040719f03016040208090607040719400402080912040739f05031700416101a271480112714801a2714f08011271470210607040719f0400a05001ab00a05100517800a051a0017800a05100517f0800a051a0017a01a2714f040110a20050a80110a100a1170110a100a1170110a100a11f070110a100a11900a110a170a110df0200a010d200a11700a010d100d010a700a010d100d010a700a010d100d010af0700a010d100d010aa0110d20110df0102d0a200d010a602d0a100a2d502d0a100a2d502d0a100a2df0502d0a100a2da00a0d300a0df0800a2d602610276026202770260027900627f0f0f0f0a026101709075026202770260027900429f0a0261027f0f060140215000509071940242029702400299006070907f0a02610170907f0f040140205100500042940060406000500070907700604060507090790041904f09014021500050907192026101500151027f01004020d020709050007041940240500051904702400190480070405070419f060140205100500042920260005100510050027f0100412071904190419500704050704198007040507041970070904191409f06004020d020709050007041920240d020709050007090029f0200d02010901040709070150070904191409700709041914097009010417090709f0600412071904190419200604060207190439070907f02004060907090619070150090104170907097009010417090709601409060907090709f0700d02010901040709070130140d020109010407090739f0200d020706070207294014090609070907096014090609070907097006070207090719f0700406090709061907014014060907090619070119f04004020809121960060702070907197006070207090719700400080129f0800d02070607020729500d02070607020729f08031800400080129800400080129a02af0b004020809121970040208091219f0700a05001a00050a802ac02ae01af0c031b031f080110a300a11901ad01ac00a110af0a00a051a050a900a051a050af0700a010d300d010a800a110ab00a110ac0110df090110a100a1170110a100a11f0502d0a300a2d80110dc0110dd01df0900a010d100d010a700a010d100d010af0f0b01dd01df0f0802d0a100a2d502d0a100a2df0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f01000
load_gfx◆2,f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e006600459500459f0f0f0f0f0f020060006600439700439f0f0f0f0f0f0200d2006600439500439f0f0f0f0f0f0200d400c500439400439f0f0f0f0f0f0200d500c60043a30043af0f0f0f0f0f0100c600c200620043a20043af0f0f0f0f0f0100d800c0006000d20043a00043af0f0f0f0f0f0100ca00d200d10043a00043af0f0f0f0f0f0100cf0800af0f0f0f0e01e201e104e105e105e101e502e101e201e005ef0f0f0f0402e002e006e006e006e001e503e002e101e006ef0f0f0f0306e001e201e001e201e001e501e601e103e001e001ef0f0f0f0806200620012201200323012601210620032f0f0f0f060120002001200122012001220120012501230021012101200320012f0f0f0f080122012001220120062005210620022101210220052f0f0f0f0401220120012201200521062006200320012000900120062f0f0f0f0f0f0f03009f0f0f0f0f0c00cf0800439000439f0f0f0f0f0900cf080043a20043af0f0f0f0f0601cf090043a20043af0f0f0f0f0500cf0a0043a40043af0f0f0f0f0300cf0a0043a50043af0f0f0f0f02001f0b0043a60043af0f0f0f0f0000cf0b00437700437f0f0f0f0f001f0b00437900437f0f0f0f0e001f0a00457700457f0f0f0f0d001f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0c001f0f0f01001f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f04000]]

-->8
-- title screen

function title_init()
 start_game_flash,_update,_draw=nil,title_update,title_draw
 music"12"
 snowflakes={}
 for i=0,48 do
  add(snowflakes,{
   x=rnd"128",
   y=rnd"128",
   s=flr(rnd"1.25"),
   spd=0.25+rnd"0.25",
   off=rnd"1",
   c=rnd"1"<0.8 and 7 or 6,
  })
 end
end

function title_update()
 if start_game_flash then
  start_game_flash-=1
  if start_game_flash<=-30 then
   begin_game()
  end
 elseif btn"4" or btn"5" then
  start_game_flash=50
  music(-1,1000)
  sfx"13"
 end
end

function title_draw()
 exec[[pal
cls
ssload◆2]]
 if start_game_flash then
  local c=start_game_flash>10 and (30*t()%10<5 and 7 or 10) or (start_game_flash>5 and 2 or start_game_flash>0 and 1 or 0)
  if c<10 then
   pal_all(c)
  end
 end
 exec[[spr◆0,-1,0,16,16
print◆🅾️+❎,54,72,9
print◆maddy thorson,38,84,2
print◆noel berry,44,90,2
print◆mod by meep,42,104,9
ssload◆0]]
 local sin,rectfill,cam_dx=sin,rectfill,_cdx
 foreach(snowflakes,function(_ENV)
  x=(x+spd)%128
  y=(y+0.5+0.5*sin(off))%128
  off+=0.0125
  rectfill(x,y,x+s,y+s,c)
 end)
end
-->8
-- sfx list
--[[
02: walljump
03: dash
04: player spawn
05: spawn landing
06: refill
07: refill respawn
08: berry collect
09: crumble
10: failed dash
11: chest opening
12: berry follow
13: title flash
14: dash restored
15: flag
16: wind
17: message
x17: orb spawn
x18: mine explode
x19: pew
x20: cry
x21: boom
x22: booooom
x23: trap
x24: arrow hit
x25: boing
x26: storage
x27: solved

47: secret
48: charging
49: player death
50: jump
]]
-->8
-- debug injects
--function draw_time() end
--[[_game_update=game_update
function game_update()
 for i=0,1 do
  if btnp(i,1) then
   load_room(mid(1,room+2*i-1,#rm_data))
  end
 end
 _game_update()
end
__init=_init
function _init()
 __init()
 begin_game()
 --load_room(#rm_data)
end
_load_room=load_room
function load_room(rm,keep_player)
 rm=mid(rm,1,#rm_data)
 _load_room(rm,keep_player)
end]]
__gfx__
00000000070000700700007007000070070000700700007000000000700007000000000000000000000000000000000000000000000000000000000070000000
0000000007722270077222700772227007722270072227700700007007723b700000000000aaaa0000aaaa0000aaaa0000000000007700000770070007000007
0000000002773b7002773b7002773b7002773b7007b37720077222700221ff10000000000aaaaaa00aaaaaa00aaaaaa000000000007770700777000000000000
0000000072288ff772288ff772288ff772288ff77ff8822702773b7072fffff70000000001ba111001ba111001ba111000000000077777700770000000000000
0000000072f1ff1772f1ff1772f1ff1772f1ff1771ff1f2772288ff772fffff700aaaa0099999999999999999999999900077000077777700000700000000000
0000000002fffff002fffff002fffff002fffff00fffff2072fffff7025555200aaaaaa0037373300373733003737330009aa900077777700000077000000000
00000000005555000055550000555500075555000055557002f1ff100055550001ba1110aa333300003333000033aa0000099000070777000007077007000070
000000000070070000700070070000700000070000007000077555700070070099999999000000aa0aa00aa000aa000000000000000000007000000000000000
0300b0b000000000666d666ddd0000000000066670000000000000075ffffff50000000000000000000000000000000000000000000000000000000000000000
003b330000000000676d676d66700000000777767000000000000007ee5eeeee0000000000000000000000000000000000000000000770000770077000600600
02888820000000006770677067777000000007667000000000000007e5eee5ee000000000444444000707070000707000000000000700700070770700ee55ee0
08988880007000700700070066600000000000dd7000000000000007eeeeeeee00000000499ffff4000666000076667000000000070770700070070008788780
088889800070007007000700dd000000000006667000000000000007eee5ee5e0000000049fffff4007656700006560000005000070770700070070008788780
08898880067706770000000066700000000777767000000000000007eeee55ee7770000044444444000666000076667000866000007007000707707000eeee00
02888820d676d676000000006777700000000766700000000000000715ee5ee16067777749fddff4007070700007070000005000000770000770077000066000
00288200d666d6660000000066600000000000dd7000000000000007015eee106660060649fffff4000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012888821d666776d00dddd0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000e5588dd6000000005ddccdd5d666776d0d6776d000000000
0000006000600000000000000000000000000000000000000000000000000000000055e055e0000000099000000000005ddccdd5d666776dd677776d00000000
00000696069600000000006000600000000000000000000000000000000000000000565e565e000000edde000000000049999994d666776ddddddddd00000000
00000eeccee6d0000000069606960000000000600060000000000060006000000000055e055e0000088668800000000049999994d6dddd6ddddddddd00000000
000066cc66eed00000000eeccee6d000000006960696000000000696069600000000065e065e00000dc11cd0000000006ddccdd6dd6776ddd677776d00000000
000eecceeeecd000000066cc66eed00000000eeccee6d0000000eeeceee6d0000000055cc556d00009d88d90000000006dd11dd6d677776d0d6776d000000000
0006ecc66ec9c000000eecceeeecd000000066cc66eed00000066ec66eeed000000093cc9333d00070000007000000001d1cc1d1dddddddd00dddd0000000000
000eeffeeeccc0000006ecc66ec9c000000eecceeeecd00000eeeceee93cd00000093cc9393cd000000000000007600000000000000000000000000000200000
00055cc55e999000000eeffeeeccc0000006ecc66ec9c00000559c5593c9c00000049cc493c9c00000000000000bd70000000000000000000000000000200000
0000e5115556000000055cc55e999000000eeffeeeccc00000093ff939ccc00000093ff939ccc00000dd0000009dd60000000000000000000000000000400000
00000055ee0000000000e5115556000000055cc55e99900000049cc49399900000049cc4939990000099d5000000500000000000007007000000000000400000
00000006e600000000000055ee0000000000e511555600000000e511555600000000e5115556000000d0d0000000600000000000000990000000000000400000
000000c000c00000000000c6e6c0000000000055eec0000000000055eec0000000000055eec00000009009000000900000000000000000000000000000400000
000009c000c90000000009c000c90000000009c6e6c90000000009c6e6c90000000009c6e6c90000006006000000000000000000000000000000000000400000
0000ccf000fcc0000000ccf000fcc0000000ccf000fcc0000000ccf000fcc0000000ccf000fcc0000dd0dd000000000000000000000000000000000000400000
57777777777777777777777557777775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0007777700200000000000000000000000000000000000000000000000000000
77777777777777777777777777777777eeeeeeeeeeeeeeeeeeeeeeeeeee77e770072227700200000000000000000000000555505500055050005505000055050
7777777777777777777777777d7777d7eee55e5e5ee55eee5ee55eeeee777e770007888700400000000000000000000000555555555555555555555005555550
d7777777d777777dd777777d77dddd77ee55555555555555555555eeee777e770007888800400000000000000000000005555555555555555555555005555550
7dddddddeddddddeedddddd777eeee77ee5555555555555555555eeeeeeeeeee0007887800400000000000000000000005555555555555555555550000555500
77eeeeeeeeeeeeeeeeeeee7777eeee77eee5555555555555555555eeeeee77770007887700400000000066d66d66000000555555555555555555555000555550
77eeeeeeeeeeeeeeeeeeee7777eeee77eee555555555555555555eeeeeee777700722270004000000006d6d66d6d600005555555555555555555550005555500
77eeeeeeeeeeeeeeeeeeee7777eeee77ee55555555555555555555eeeeeee7770007770000400000000660000006600005555555555555555555555005555550
77eeeeeeeeeeeeeeeeeeee7777eeee77ee5555555555555555555eeeeeeeeeeeeeeee5eeeeeeeeee000000000000000005555555555555555555555005555550
77eeeeeeeeeeeeeeeeeeee7777eeee77eee555555555555555555eee7777eeeeeeee555eeeeeeeee000000000000000000555555555555555555550005555500
777eeeeeeeeeeeeeeeeee777777ee777eee5555555555555555555ee77777eeeeee55555e5e5eeee000000000000000000555555555555555555550000555550
777eeeeeeeeeeeeeeeeee777777ee777ee55555555555555555555ee77777eeeeeeee5eeee5eeeee000000000000000000555555555555555555555000555550
777eeeeeeeeeeeeeeeeee777777ee777eee555555555555555555eeeeeeeeeeeeeeee5eee5e5eeee000077000000000005555555555555555555555005555500
777eeeeeeeeeeeeeeeeee777777ee777ee55555555555555555555ee777e7eeeeeeee5eeeeeeeeee077777700076000000555555555555555555550000555500
77eeeeeeeeeeeeeeeeeeee7777eeee77ee5555555555555555555eee777e77eeeeeeeeeeeeeeeeee6777d6600777760000555555555555555555555000555550
77eeeeeeeeeeeeeeeeeeee7777eeee77eee555555555555555555eee777e7eeeeeeeeeeeeeeeeeeeddd666607777777005555555555555555555555005555550
77eeeeeeeeeeeeeeeeeeee7777eeee77ee5555555555555555555eeeeeeeeeee5ddddddddddddddd000000000000000005555555555555555555555005555550
77eeeeeeeeeeeeeeeeeeee7777eeee77eee5555555555555555555eeeeeeeeee6667776666666d66000000000000000005555555555555555555550005555500
77eeeeeeeeeeeeeeeeeeee7777eeee77eee5555555555555555555eeeeeeeeee6667776666666d66000000000000000000555555555555555555555005555500
77eeeeeeeeeeeeeeeeeeee7777eeee77ee5555555555555555555eeeee7777ee6667776666666d66000000000000000000555555555555555555550000555500
77eeeeeeeeeeeeeeeeeeee7777eeee77ee5555555555555555555eeeeeeeeeee5ddddddddddddddd760000000000007705555555555555555555550005555550
777777eeee7777eeee777777777ee777eeee55e5eee5ee5e5ee5eeee777e777766677766666d6666777000000000067700555555555555555555555000555550
77777777777777777777777777777777eeeeeeeeeeeeeeeeeeeeeeee777e777766677766666d6666777776000000777700550005505500555055055000555050
d7777777777777777777777dd777777deeeeeeeeeeeeeeeeeeeeeeee777e777766677766666d6666777777700067777700000000000000000000000000000000
57777777777777777777777557777775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed667776d00000000077777606050060500000000000000000000000055555555
77777777777777777777777777777777eeeeeeeeee77e7eeee7e7eee77777e776667999600000000007007000666600500555055550550055500555055555555
7777777777777777777777777d7777d7eeee777ee777777eee77777e77777e776667796600000000006000000050000505555555555555555555555055005555
d777777dd777777dd777777d77dddd77e7ee777eeee77eeee77ee7ee77777e776667776600000000000000000005555005555555555555555555550055005505
7ddddddeeddddddeedddddd777eeee77eeeeeeeeeeee7eeeee7ee77eeeeeeeee5ddddddd0000b000000000000000000000555555555555555555550055555555
777777eeee7777eeee77777777eeee77ee777eeeeee77eeee77777ee777e777766677766000b0000000000000000000000555555555555555555555055550555
77777777777777777777777777777777ee777eeeeeee7eeeeee7e7ee777e7777666777660b0b0b00000000000000000005550555500555555505550055555555
d7777777777777777777777dd777777deeeeeeeeeee7eeeeeeeeeeee777e7777666777660bbbbbb0000000000000000000000000000000000000000055555555
1574000000751515151515471515156715154715151515151515151515151515151515471616767676761676161676161616767616141424000000c6d6d50515
1515151515151515455555555555555555556515151574d5e5000000c404141424b4008700000004141414241111111111111111111111051515000000000000
152500000077151515151515151515151515151515151515151515151515151515151526d6d6e600b7a700c6d5d6e6a7c5d5e6b7000676260000000000c57775
1515154454545454555555555555555555556515157477d5f7d4d4d7d60676671514172700000006154715151414141414141414141414151515000000000000
1574000000067616761667151515167676167616761615151515151515151515151574e60000000000000000f5000000c5e60000000000000000000000c67715
1515154555555555555555555555555555556515151574d5d5d6e600002121067626a7a700000041751515151515151515151515151515151515000000000000
157400000000b7a7c6d505154774e6000000b700c6d6777547151515151515151547260000000000008000c4e5a500c4e5000000009700c20000000000007775
1515154555555555555555555556565656566615151525f7e60000000000000000b7000000000041754715151515151515151515151515151515000000000000
152500000000000000c57515162600000000000000f1771515151515151515151577120000000717141414141424b4c5e5001000a40414141424111111110515
1515154555555555555555555515151515151515151525e500000000000000000000000000000041061515151515151515151515151515151515000000000000
4725b4000000000000c57574e600000000000000071716151515671515151515157400000000c6d5067616471515141414141414141515478595141414141515
1515154555555555555555555515151515151515151574e600000000111111111111111111111111110515151515151515151515151515151515000000000000
151514240000000000c67725000000000000000000b7c506761615151515151515151424000000c5f7d6d6067615151515151547156715151515151515151547
1515154555555555555555555515151515151515151525e500000000041414141414141414141414144715151515151515151515151515151515000000000000
15574774d4e400000000052600000000000000000000c5f7d6d605151515151547151574a60090c5e60000b7c605671515151515151515151515151515151515
1500000000000000000000000015161676167616767626e500000000051515151515151515151515151515151515151515151515151515151515151515150000
15157626f7d6e700000035a700000000001000b500c4d5e6008005471515151515155715141424e5970000000006161515151515151515151515151515151515
15000000000000000000000000253700c6d6f7e5a700c5e600000000751515151515151515151515151515151515151515154715151515151515471515150000
1577d5d5e6000000000035000000000414141424d4f7e6000004157677767616167616151547151424b400000000007515151515151515151515151515151515
1500000000000000000000000025a700a200c6d6d4d4e60000000000751515151515151515151515151515151547151515151515151567151515151567150000
1525f7e50000000000003600001100054715151514240000007574e500b70000c6d5f70676761676161727000002007775151515151515151515151515151515
1500000000000000000000000074000000000000c6e5000000000000051515151515154715151676151515151516767616161676161676761616767616150000
4725d5e6000000000000f500413431061615155715152400000626e60000000000c6d6e6b700b700c6f7e5000000000515151515151515151515151515151515
150000000000000000000000007400000000009000f500000000041415154715151515151526d6d60547151525f7d5e6b7a70000b7b7000000b7c6f7d5050000
1574e500000000000000f50041363121210616161515740000c5e50000000000000000000000000000c5e5000004141515151515151515151515151515151515
1500000000000000000000000025000004141414141414141414155715151516767616762600f1000515151525d5e6000000000000000000000000c6f7050000
1574e500000000000000340000210000002121210647740000c5e50200008797000000000000000000c5f7d43705471567151515151515151515151515151515
150000000000000000000000002500c4057616167676161676167676151526d5f7d5f7e5b70000000576164725e50000000000000000000000000000c5050000
1577e6000000000000003600000000000000000021752500c4d5f7e4000414141414141424b49700b60414141415151515151515151515151515151515151515
150000000000000000000000007400c5350000000000c6e5000000000574f7d5d5d6e6000000000036d5d50525e60000000000000000000000000000c6050000
15250000000000000000a70000000000000000000005151414141414144715151515154715141414141547151557151515151515151515151515151515151515
1500000000000000000000000025d4d535000000110000f5970000000574d6d6e600000000000000a7c6d6062500000000000000000000000000000000050000
15251111111111111111111111111111111111111105151547151515151515151500000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000025d5d535e40041343100c637e40000062600000000000000000000000000c63500000000000000000000000000000000050000
15151414141414141414141414141414141414141415151515151515151515151500000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000074d5d636d6e4413531000000f50000d20000000000000000000000000000003500000000000000000000000000000000050000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000074e5000000c6d47700000000c5e4a50000100097b5000000000000000000003500000000000000000000000000000000050000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000077e500000000c57700000041041414141414141414240000000000000000003600000000000000000000000000000000050000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000077e5000000c4d6770000004106767615671515151574b40000000000000000d200000000000000000000000000d30000050000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000074e50011c4e6413531000000000000051515151515151424b40000000000000000000000000000000000000000000000050000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000025d5d434d600413531000000000000054715151567154715141414141414141496969696969696969696969696969696000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000770000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000
00000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000007660000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000600000000000000000000600000004999669000000499999900000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000006060000000499990000000049999000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000d0006000000049999000000499990000000000000000000000000000007000000000
00000000000000000000000000000000000000000000000000000000000d00000c00000049999000004999900000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000d000000c00000004aaaa00004aaaa00000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c0000000c00060004aaaa0004aaaa000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000d000000000c060d0004aaaa04aaaa0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000c00000000000d000d004aaaa04aaaa0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000c0000000000000000000000000a0000000000000000000000000000000000000000000000
000000000000000000000000000000000ee000ee00eeeee00eeeeee00eeeeee00ee000000eee07ee000ee0eeeeee000000000000000000000000000000000000
000000000000000000000000000000000eee0eee0eeeeeee0eeeeeee0eeeeeee0ee000000eeee0eee00ee0eeeeeee00000000000000000000000000000000000
000000000000000000000000000000000eeeeeee0ee000ee0ee000ee0ee000000ee0000000ee00eeee0ee0ee0000000000000000000000000000000000000000
00000000000000000000000000000000022222220222222202200022022220000220000000220022222220222200000000000000000000000000000000000000
00000000000000000000000000000000022020220220002202200022022000000220000200220022022220220077000000000000000000000000000000000000
00000000000000000000000000000000022000220220002202222222072222200222222202220022002220222277000000000000000000000000000000000000
00000000000000000000000000000000022000220220002202222220022222220222222202222022090220222222200000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000c00000000000000000000000004999904999900000000000000007000000000000000000000000000
0000000000000000000000000000000000000000000000c00000000000000000000000004aaaa0004aaaa0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000cc000000000000000000000000004aaaa0004aaaa0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000c0000000000000000000000000004aaaa000004aaaa000000000000000000000000000000000000000000
000000000000000000000000000000000000000000c0000000000000000000000000004aaaa0000004aaaa000000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000004aaaa00000004aaaa00000000000000000000000000000000000000000
0000000000007000000000000000000000000000c000000000000000000000000000047777000000004777700000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000477770000000000477770000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000004777777000000004777777700000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000700001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000
00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000070000000000000000000000000066000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000
00006000000000000000000000000000000000000000000000000009999900000009999900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000099000990090099090990000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000099090990999099909990000000000000000000000000000000000000000000000000000000
00000000000000000000007000000000000000000000000000000099000990090099090990000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000009999900000009999900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000222022202200220020200000222020200220222002200220220000000000000000000000000000000000000000
00006600000000000000000000000000000000222020202020202020200000020020202020202020002020202000000000000000000000000000000000000000
00006600000000000000000000000000000000202022202020202022200000020022202020220022202020202000000000000000000000000000000000000000
00000000000000000000000000000000000000202020202020202000200000020020202020202000202020202000000000000000000000000000000000000000
00000000000000000000000000000000000000202020202220222022200000020020202200202022002200202000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000220002202220200000002220222022202220202000000000000000000000000000000000000000000000
00000000700000000000000000000000000000000000202020202000200000002020200020202020202000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000202020202200200000072200220022002200222000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000202020202000200000002020200020202020002000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000202022002220222000002220222020202020222000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000007000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000099900990990000009990909000009990999099909990000000000000000000000000000000000000000000
00000000000000000000000000000000000000000099909090909000009090909000009990900090009090000000000000000000000000000000000000000000
00000000000000000000000000000000000000000090909090909000009900999000009090990099009990000000000000000070000000000000000000000000
00000000000000000000000000000000000000000090909090909000009090009000009090900090009000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000090909900999000009990999000009090999099909000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000060000000000000
00000000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000020202020202000000000000000000000000000000000000000000000000010000000000000000000000000000000201010101010101010002020202020202010101010101010101010202020202020101010101010101010102020202020201010101010101010102020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000007751545555555555555555555555555556515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000007751545555656565656565656565656566515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000005751646566515151515151515151515151515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000005751515151515151515151515151515151515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000006061675151515151515151515151515151515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000007a00005051517651515161676751515151515151000000000000000051515151515151515151515151616161676761616751516167676167517461676761675176616761616751515151515151515151515151515151515151515151515151515151515151515151000000000000
000000000000000000000000000000000000000000505151516167627a007b6061675151515100000000000000005151515151515151515174514700000000007a000050476d6e007b0057526e007b5c7f5052006c6d7f5d50515151515151515151515151515151515151515151515151515151515151515151000000000000
00000000000000000000000000000000000000004c575151626d5d5e000000000000775151510000000000000000515151515151515151515151521f00000000000000606200002a0000606200002a6c6d60620000006c6d60515167615151515151515151515151515151515151515151515151515151515151000000000000
00000000000000000000005b00000000004c4d4d5d50745200006c7f4e00000000005751515100000000000000005151515151515151515151765142000000000000001212000000000000000000000000007a00000000007b60527f5d6067515161676761515151515151515151515151515151515151515151000000000000
0000010000780000004c404200000000005c7f5d5d6067620000006c5d4e00004c7d6051765100000000000000005151515151515151515151515151414213000000000000000000000000000000000000000000000000000000636d6d6d6d60627f6e007b606751615151515151515151515151515151515151000000000000
414141414141424d7d5d606200000000006c6d5d5d7f6e00000000006c5d4d4d5e0000505151000000000000000051515151515151515151515151515152130000000000000000000000000000000000000000000000000000000000002a007b6c6e000000000063006067616167676161676761615151515151000000000000
517451515151475e005c5e7a000040420000005c5d5e000000000000006c5d7f5e00005751510000000000000000515151515151515151515151517451471300000000000000000000000000200000000000000000000000000000000000000000000000000000000000007b00007b00006c6d7f5d6051745151000000000000
45454545467651426a5c7f4e795a5052734b4c5d7f5e00790000000000005c5d5d4e0060515100000000000000005151515151515151515151515151514713000000000014731300000000000000790000000000000000000000000000000000000000000000000000000000000000000000006c6d7f50515151000000000000
55555555565151744141414141425067414141414141414141421111111140427f5d4d5d5051000000000000000051515151515151515151515151515177130000000000001200000000004c404142730000000000000000000000000000003a7900000000000000000000000000000000000000005c77575151000000000000
55555555554651515151515174475051515151517551515174514141414176526d6d5d7f50510000000000000000515151515151515151515151515147771300000000000000000000004c6d60515213000000000000000000000000000000404200000000000000000000000000110000001100006c77515151000000000000
555555555556515151745151515257517651515151515151515151515151516200006c5d575100000000000000005151515151515151515151515151517713000000000000000000004c6e00126062130000000000000000000000005a0000504700001111000000000000000014430000004313000077515151000000000000
656565656566515151515151515250515151515151515151515151745151627a0000005c775100000000000000005151515151515151515151515151517713000000000000000000736e000000121200000000000000000000000040421111504711114042000000000000000014531111115313000057755151000000000000
5151515151515151515151515152505174515151515151515151516167626e000000006c575100000000000000005151515151515151515151515151514713000000000000000000120000000000000000000000000000005b00005751414151744142504700000000005a010014574141716213000050515151000000000000
5151515151515151515151515147606167616167616161616767625e005f00000000006b505100000000000000005151515151515151515151515151517713000000000000000000000000000000000000000000704141414211115774515151515152606211114041414142111157765240424e000057515174000000000000
5151515151515151515151745147007b7a5c6e7b00007a5c5d7f5d6d7d6e000000000040515100000000000000005151515151515151515151515151514713000000000000000000000000000000000000000000005051515141415151517551515151414141417451517651414151676260626d4e0050515151000000000000
515151515151515151515151517700004c5e00000000005c7f6d6e0000000000000000505151000000000000000051515151515151515151515151515152131111110000000043111111111111111111111111111150745151515151515151515151515151515151515151676776521300007b005c4d50745151000000000000
5151515174515151515174515147004c7f5e00000000005c5e000000000000000000005051750000000000000000515151515151515151745151515151514141414213000000504141414141414141414141414141515151515151515151515151515151515151515151476d6d575213000000006c7f57515151000000000000
51515151616167676161616761624d5d5d5e000000404141420000000000000000004c775151000000000000000051515151515151515151515151515176515151471300004c575151515151515151515151515151515151515151515151515151515151515151515151471f0060621300000000006c57515151000000000000
515151625d5d7f6d6e7b00006c6d6d7f5d5e0000005051517700000000000000004c6d775151515151515151515151515151745161616761676167676161615151471300005c775174515151515151515151515151515151676167616167616167676767616767676161617217007a0000000000000050745151000000000000
515162006c5d6e00000000000000006c5d5e000000507451474e0000000000794c6e0077515151515151515151515151515151625d7f6d6e0000007b7a6c6d57745213004c7f7751515151515151515151515151515167627f5d6e7b7b6c7f5d5d5d6e7b6c7f6e007b007a000000000000000000000060515151000000000000
51527a00005f000000000000000000006c7f4d4e4a505151476d4e0000000040420000775151515151515151515151515151527f5d6e00000000000000000060616213005c5d77575151444545454545454546515151527a6c5e000000006c6d7f5e0000006f0000000000000000000000000000000014505151000000000000
51470000005c4e000000000000000000006c5d404151515152006c4e5b004c50520000575151515151515151515151515174475d6e000000000000000000007b6c7f4d7d6d7f775151515455555555555555565151514700006f2a00000000005c6e000000000000000000000000000000000000000014505151000000000000
514700004c5d7f4e090000000000000000005c505151515152000040424d6d50471111505151515151515151515151515151475e000000000000000000000000006c6e00005c577551515455555555555555565151514700000000000000002a6f00000000000000000000000000171700000000000014575174000000000000
51474d4d6d6d5d40420000000000000000006c577651515152111157476e0050514141517451515151515151515151515147775e00000000000000005b790000000001004a4051515151545555555555555556515151770000000000000000000000000000000000000000000000000000000000000014505151000000000000
51777f6e005a5c50526a79000900007800000050515151515141415152111150515151515151515151515151515151515151775e00000000000014404141414141414141417451515151545555555555555556515147770000000000000000000000000000000000000000000000000000000000000014575151000000000000
51776e000040417451414141414141424b006b57515151515151745151414151517451515151515151515151515151515151525e00000000000014577451515151515151515151515151545555555555555556515151770000000000000000000000000000000000000000000000000000000000000014575151000000000000
51770000005051515151515151745151414141515151515151515151515151515151515151515151515151515151515151755141424b0000000014606761765151745151515151514445555555555555555556515151524d4e00000000003b00790000000000000000005b000000000000000000000014507451000000000000
__sfx__
490300003f0303f0303f3303f3203f6103f6103f6103f6053f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00120000364413545133451314512f4512d45136661366611f6510d6310561100601046013000130001300013000130001006010000100001000012f0012f0012f00100001000010000100001000010000100001
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000641008410094100b410224302a4403c6403b6403b6403964036640326402d6402864024630216301d6301a63016620116200e6200b61007610056100361010600106000060000600006000060000600
0001000036270342702e2702a270243601d360113500a3400432001300012001d1001010003100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
190e00002b270262702b2702d270302602d2602b260262502b2502d240302302d2100020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
0010002021610206101e6101b610196101561012610116100f6100e6100d6100c6100c6100c6100c6100d6100e6100f610106101161013610156101661017610196101b6101d6101e61020610216102261022610
010800001432120355004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0103000029656316563365633656326562c6561b65613656076560165600656006560060600606006060060600606006060060600606006060060600606006060060600606006060060600606006060060600606
010200002c6612c6612c6611b1511313108111006010c6010460101601016011d6011060103601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
010400002f45032450314502e4502f4503045000000000002f400324002f45032450314502e4502f4503045030400304000000000000000000000000000000000000000000000000000000000000000000000000
00050000212731e273132730a25300223012033b203282033f2032f203282031d2031020303203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203
000c000033343393433d3433e3433f3433c3433e3433d3433e3433b3433e3433c3433f3433b3433e3433f34333343393433d3433e3433f3433c3433e3433d3433e3433b3433e3433c3433f3433b3433e3433f343
0006000021670176401b6001960000600356003560035600356003560000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000200000e6610e6610e6610c65106631006110a601286013f6012f601286011d6011060103601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
0003000008470054700c470174601b460194501e4501a4401e4301b42019400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
010c000032575305753b505005053b50500505005053350533505335053350533505335053f5053f5050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
150c00000f2001b205142301423012230122301123011230122301223011230112300d2300d2300f2320f2320f2320f2310f1200a1201412033620336350d1200f1200f1250f1200a1201412033620336350d120
190c00001b2001b205272302723025230252302423024230252302523024230242302023020230222302223022232222322223222232222322223222232222322223222232222322223222232222322223222235
040c00000f1200f1250f1200a1201412033620336350d1200f1200f1250f1200a1201412033620336350d1201412014125141200f120191203862038635121201412014125141200f12019120386203863512120
000c0000000000000016232162321d2321d23216232162321e2321e23216232162322023220232162321623222232222322223222232202322023520232202322023220232202322023220232202321e2321e232
040c00000d1200d1250d120081201212031620316350b1200d1200d1250d120081201212031620316350b1200f1200f1250f1200a1201412033620336350d1200f1200f1250f1200a1201412033620336350d120
000c00001d2321b232192321923219232192321923219232192321923219232192321b2321423216232192321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b225
000c0000000000000016232162321d2321d23216232162321e2321e232162321623220232202321623216232222322223222232222322023220232202322023220232202321e2321e2321b2321b2321d2321d232
000c00001d2321d232192321923219232192321923219232192321923219232192320f2321223214232192321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b225
010c00000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004001d4241d4321d4321d4321d4321d4321d4321d432
010c00001e4321e4321e4321e4321e4321e4321e4321e432224322243222432224322243222432224322242522442224322243222432204322043520432204352243222432224322243222432224322243222432
040600000d1200d1200d1200d1250d1200d12008120081201212012120316203162031620316350b1200b1200d1200d1200d1200d1250d1200d12008120081201212012120316203162031620316350b1200b120
010600002343223432234322343223432234322343223432234322343223432234322343223432234322343225432254322543225432254322543225432254322543225432254322543225432254322543225425
000c00040a1400a1450a1450a1450a1000a1050a1050a1050a1000a1050a1050a1050a1000a1050a1050a1050a1000a1050a1050a1050a1000a1050a1050a1050a1000a1050a1050a1050a1000a1050a1050a105
010c000000200002002a2302a2302923029230272302723029230292301d2301d2302223022230292302923027230272301d2301d23026230262301d2301d23024230242301d2301d23026230262301d2301d230
010c00000f1400f1450f1450f1450f1400f1450f1450f145111401114511145111451114011145111451114512140121451214512145121401214512145121451314013145131451314513140131451314513145
010c0000292302923029230292302923029230272302723027230272302723027230262302623026230262301b23022230272302723027230272302623027230292302923027230292302a2302a2302a2302a230
010c00001414014145141451414514140141451414514145141401414514145141451414014145141451414519140191451914519145191401914519145191451914019145191451914519140191451914519145
000c0000000000000000000000000000000000000000000000000000002e2302e2302c2302c2302a2302a23029230292302223022230262302623029230292302c2302c23029230292302c2302c2303223032230
010c0000332303323031230312302e2302e230332303323031230312302e2302e2303323033230322323223232232322323223232232322323223232232322323223232232322323223232232322323223232225
010c00002e2302e2302c2302c23029230292302e2302e2302c2302c23029230292302e2302e2352e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e2322e225
010c00001914019145191451914519140191451914519145191401914519145191451914019145191451914516140161451614516145161401614516145161451614016145161451614516140161451614516145
050c00003862038615386152c1232c113251232511322123221131b1231b113151231511317104316000b1000f1200f1250f1200a1201412033620336350d1200f1200f1250f1200a1201412033620336350d120
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0102000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
190c00000d2000d2000d2002c2032c203252032520322203222031b2031b203152031623417234192341a2341b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b2321b225
511400000f2310c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350f2350c23511230112350f2300c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350a2300a2350723007235
711400000a3350733507335073350733507335073350733507335073350733507335223322233221332213322033220332203321f3321f3321f3321f3321f3321f3321f3321f3321f3321f3321f3321f3321f325
511400000f2300c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350f2350c235112301123518245182450c20016245162450c2001424514245142000e2450e2450c2000c2300c2350a2300a235
711400000a3350733507335073350733507335073350733507335073350733507335223322233224332243322033220332203321f3321f3321f3321f3321f3321f3321f3321f3321f3321f3321f3321f3321f325
511400000f2310c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350c2350f2350c235112301123513245132450c20015245152450c2001724517245142001a2451a2450c20018230182351623016235
711400000a3350733507335073350733507335073350733507335073350733507335223322233224332243321f3321f3321f33221332213322133223332233322333226332263322633226332263322633226335
710a00001833218332183321833218332183321833218332183321833218332183352223022230182301823018230182301823018225000000000000000000000000000000000000000000000244422444224442
700a00002433224332243322433224332243322433224332243322433224332243351d2301d2301f2301f2301f2301f2301f2301f225000000000000000000000000000000000000000024300244422444224442
010700000903009030090300903009030090300903009030090300903009030090300903009030090300903009030090300903009030090300903009030090300903009030090300903009030090300903009030
00070000000000000000000000002f1202f1200000000000301203012000000000002f1202f1200000000000321203212000000000002f1202f12000000000003012030120000000000032120000000000000000
000700002432000000000000000024320243200000000000000000000000000000002432024320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700000703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030
__music__
00 1b1c4344
01 1d1e4344
00 1f204344
00 1d214344
00 22231f44
00 1e241d44
00 25264344
00 27284344
00 292a4344
00 2b2c4344
00 2d2e2f44
02 30334344
01 34354344
00 36374344
00 34354344
00 38394344
02 3a3b4344
01 3c3d3e43
00 3f3d3e43
00 003d3e43
02 3f3d3e43
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
00 41424344
00 41424344
03 10424344

