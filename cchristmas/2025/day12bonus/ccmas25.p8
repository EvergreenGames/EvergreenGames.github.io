pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- celeste classic
-- matt thorson + noel berry

-- made hastily for ccmas 25
-- "this mod sucks ass.
--  anyway, merry christmas!"

-- "data structures"

function vector(x,y)
 return {x=x,y=y}
end

function rectangle(x,y,w,h)
 return {x=x,y=y,w=w,h=h}
end

-- [globals]

objects,got_fruit,
freeze,shake,delay_restart,sfx_timer,music_timer,
screenshake=
{},{},
0,0,0,0,0,
true
puzzle={
0,1,2,3,
4,5,6,7,
8,9,10,11,
12,13,14,15}
cpy_puzzle={}
dispuzzle=10
max_dash=5
idontcareanymore=0

-- [entry point]

function _init()
 shuffle(500)
 for i,v in ipairs(puzzle) do
  cpy_puzzle[i]=v
 end
 title_screen()
end

function title_screen()
 frames,start_game_flash=0,0
 music(40,0,7)
 load_room(7,3)
end

function begin_game()
 max_djump,deaths,moves,frames,seconds,minutes,music_timer=1,0,0,0,0,0,0
 music(0,0,7)
 load_room(0,0)
 menuitem(1,"i'm stuck!", next_room)
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
  x=rnd"128",
  y=rnd"128",
  spd=1+rnd"4",
  w=32+rnd"32"
 })
end

particles={}
for i=0,24 do
 add(particles,{
  x=rnd"128",
  y=rnd"128",
  s=flr(rnd"1.25"),
  spd=0.15+rnd"1",
  off=rnd(),
  c=6+rnd"2",
 })
end

dead_particles={}

-- [player entity]

player={
 init=function(this)
  this.grace,this.jbuffer=0,0
  this.djump=max_djump
  this.dash_time,this.dash_effect_time=0,0
  this.dash_target_x,this.dash_target_y=0,0
  this.dash_accel_x,this.dash_accel_y=0,0
  this.hitbox=rectangle(1,3,6,5)
  this.spr_off=0
  this.solids=true
  this.dashes=max_dash
  create_hair(this)
 end,
 update=function(this)
  if pause_player then
   return
  end

  -- horizontal input
  local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0

  -- spike collision / bottom death
  if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or
   this.y>128 then
   kill_player(this)
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
   if this.djump<max_djump and this.dashes>0 then
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
   this.spd=vector(
    appr(this.spd.x,this.dash_target_x,this.dash_accel_x),
    appr(this.spd.y,this.dash_target_y,this.dash_accel_y)
   )
  else
   -- x movement
   local maxrun=1
   local accel=this.is_ice(0,1) and 0.05 or on_ground and 0.6 or 0.4
   local deccel=0.15

   -- set x speed
   this.spd.x=abs(this.spd.x)<=maxrun and
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
    if rnd()<0.2 then
     this.init_smoke(h_input*6)
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
      psfx"2"
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
   idontcareanymore=this.dashes
			this.djump=this.dashes>0 and this.djump or 0
   if this.djump>0 and dash then
    this.init_smoke()
    this.dashes-=1
    this.djump-=1
    this.dash_time=4
    has_dashed=true
    this.dash_effect_time=10
    -- vertical input
    local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0
    -- calculate dash speeds
    this.spd=vector(
     h_input~=0 and h_input*(v_input~=0 and d_half or d_full) or (v_input~=0 and 0 or this.flip.x and -1 or 1),
     v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0
    )
    -- effects
    psfx"3"
    freeze=2
    shake=6
    -- dash target speeds and accels
    this.dash_target_x=2*sign(this.spd.x)
    this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
    this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
    this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
    -- puzzle
    moves+=1
    if h_input~= 0 then
	    if h_input>0 then
	    	for sx=3,1,-1 do
	    	 for sy=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4]
	    	   puzzle[sx+sy*4]=12
	    	   return
	    	  end
	    	 end
	    	end
	    end
	    if h_input<0 then
	    	for sx=0,2 do
	    	 for sy=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4+2]
	    	   puzzle[sx+sy*4+2]=12
	    	   return
	    	  end
	    	 end
	    	end
	    end
    else
     if v_input>0 then
	    	for sy=3,1,-1 do
	    	 for sx=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4-3]
	    	   puzzle[sx+sy*4-3]=12
	    	   return -- not safe btw
	    	  end
	    	 end
	    	end
	    end
	    if v_input<0 then
	    	for sy=0,2 do
	    	 for sx=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4+5]
	    	   puzzle[sx+sy*4+5]=12
	    	   return
	    	  end
	    	 end
	    	end
	    end
    end
    
   elseif this.djump<=0 and dash then
    -- failed dash smoke
    psfx"9"
    this.init_smoke()
   end
  end

  -- animation
  this.spr_off+=0.25
  this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or  -- wall slide or mid air
   btn(⬇️) and 6 or -- crouch
   btn(⬆️) and 7 or -- look up
   this.spd.x~=0 and h_input~=0 and 1+this.spr_off%4 or 1 -- walk or stand

  -- crouch
  if (btn(⬇️) and on_ground) then
   dispuzzle-=dispuzzle>0 and 1 or 0
  else
   dispuzzle=10
  end

  -- exit level off the top (except summit)
  if this.y<-4 and level_index()<31 then
   next_room()
  end

  -- was on the ground
  this.was_on_ground=on_ground
 end,

 draw=function(this)
  -- clamp in screen
  local clamped=mid(this.x,-1,121)
  if this.x~=clamped then
   this.x=clamped
   this.spd.x=0
  end
  -- draw player hair and sprite
  local c = this.dashes and (this.dashes<1 and 0 or this.djump) or this.jump
  set_hair_color(c)
  draw_hair(this)
  draw_obj_sprite(this)
  unset_hair_color()
  
  --[[if this.dashes then
   rectfill(100,123,128,128,1)
   ?"•••••",102,123,8
  if level_index()<2 then
  -- tung tung
	 for i=0,15 do
	  if puzzle[i+1]~=12 then
	   --?puzzle[i+1],(i%4)*8,flr(i/4)*8,8 
	  	rectfill(124+(i%4)*1,
	  	         124+flr(i/4)*1,
	  	         124+(i%4)*1,
	  	         124+flr(i/4)*1,(i+flr(i/4))%2<1 and 8 or 5)
	  end
	 end
 end
  
  end]]--
 end
}

function create_hair(obj)
 obj.hair={}
 for i=1,5 do
  add(obj.hair,vector(obj.x,obj.y))
 end
end

function set_hair_color(djump)
 pal(8,djump==1 and 8 or djump==0 and 12 or frames%6<3 and 7 or 11)
end

function draw_hair(obj)
 local ii=0
 local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
 for i,h in ipairs(obj.hair) do
  h.x+=(last.x-h.x)/1.5
  h.y+=(last.y+0.5-h.y)/1.5
  circfill(h.x,h.y,mid(4-i,1,2),8)
  last=h
  ii=i
 end
 circfill(last.x,last.y,mid(4-ii,1,2),7)
end

function unset_hair_color()
 pal() -- use pal(8,8) to preserve other palette swaps
end

-- [other entities]



player_spawn={
 init=function(this)
  sfx"4"
  this.spr=3
  this.target=this.y
  this.y=128
  this.spd.y=-4
  this.state=0
  this.delay=0
  this.djump=max_djump
  create_hair(this)
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
     sfx"5"
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
    hit.spd.x*=0.2
    hit.spd.y=-3
    hit.djump=max_djump
    this.delay=10
    this.init_smoke()
    -- crumble below spring
    break_fall_floor(this.check(fall_floor,0,1) or {})
    psfx"8"
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
    hit.dashes=max_dash
    this.spr=0
    this.timer=60
   end
  elseif this.timer>0 then
   this.timer-=1
  else
   --psfx"7"
   --this.init_smoke()
   --this.spr=22
  end
 end,
 draw=function(this)
  if this.spr==22 then
   spr(13+(this.offset*8)%3,this.x,this.y+6)
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
   if this.delay<=0 and not this.player_here() then
    psfx"7"
    this.state=0
    this.collideable=true
    this.init_smoke()
   end
  end
 end,
 draw=function(this)
  spr(this.state==1 and 26-this.delay/5 or this.state==0 and 23,this.x,this.y)
 end
}

function break_fall_floor(obj)
 if obj.state==0 then
  psfx"15"
  obj.state=1
  obj.delay=15--how long until it falls
  obj.init_smoke();
  (obj.check(spring,0,-1) or {}).hide_in=15
 end
end

smoke={
 init=function(this)
  this.spd=vector(0.3+rnd"0.2",-0.1)
  this.x+=-1+rnd"2"
  this.y+=-1+rnd"2"
  this.flip=vector(rnd()<0.5,rnd()<0.5)
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
  --fly away
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
   this.off+=0.05
   this.spd.y=sin(this.off)*0.5
  end
  -- collect
  check_fruit(this)
 end,
 draw=function(this)
  draw_obj_sprite(this)
  --spr(this.spr,this.x,this.y)
  for ox=-6,6,12 do
   spr((has_dashed or sin(this.off)>=0) and 45 or this.y>this.start and 47 or 46,this.x+ox,this.y-2,1,1,ox==-6)
  end
 end
}

function check_fruit(this)
 local hit=this.player_here()
 if hit then
  hit.djump=max_djump
  sfx_timer=20
  sfx"13"
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
  spr(64,this.x,this.y,2,2)
 end
}

function init_fruit(this,ox,oy)
 sfx_timer=20
 sfx"16"
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
   sfx"23"
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
  this.text="-- celeste mountain --#this memorial to those# perished on the climb"
  if this.check(player,4,0) then
   if this.index<#this.text then
    this.index+=0.5
    if this.index>=this.last+1 then
     this.last+=1
     sfx"35"
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
 end,
 draw=function(this)
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
   sspr(0,48,16,8,this.x,this.y)
  elseif this.state==1 then
   this.timer-=1
   shake=5
   flash_bg=true
   if this.timer<=45 and #this.particles<50 then
    add(this.particles,{
     x=1+rnd"14",
     y=0,
     h=32+rnd"32",
     spd=8+rnd"8"
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
  sspr(0,56,16,8,this.x,this.y+8)
 end
}

orb={
 init=function(this)
  this.spd.y=-4
 end,
 draw=function(this)
  this.spd.y=appr(this.spd.y,0,0.5)
  local hit=this.player_here()
  if this.spd.y==0 and hit then
   music_timer=45
   sfx"51"
   freeze=10
   shake=10
   destroy_object(this)
   max_djump=2
   hit.djump=2
  end
  spr(102,this.x,this.y)
  for i=0,0.875,0.125 do
   circfill(this.x+4+cos(frames/30+i)*8,this.y+4+sin(frames/30+i)*8,1,7)
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
  draw_obj_sprite(this)
  --spr(this.spr,this.x,this.y)
  if this.show then
   rectfill(32,2,96,31,0)
   --spr(26,55,6)
   --?"x"..this.score,64,9,7
   draw_time(49,6)
   ?"deaths:"..deaths,48,14,7
   ?"moves:"..moves,48,21,7
  elseif this.player_here() then
   sfx"55"
   sfx_timer=30
   this.show=true
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
   rectfill(31,15,96,80,0)
   for i=0,15 do
    if puzzle[i+1]~=12 then
    	sspr((puzzle[i+1]%4)*16,
    					64+flr(puzzle[i+1]/4)*16,	
    					16,16,
    					32+(i%4)*16,16+flr(i/4)*16)
    end
   end

   --[[
   local level=level_index()
   if level==12 then
    ?"old site",48,62,7
   elseif level==31 then
    ?"summit",52,62,7
   else
    ?level.."00 m",level<10 and 54 or 52,62,7
   end
   ]]--
   draw_time(4,4)
  end
 end
}

function psfx(num)
 if sfx_timer<=0 then
  sfx(num)
 end
end

-- [tile dict]
tiles={}
foreach(split([[
1,player_spawn
8,key
11,platform
12,platform
18,spring
20,chest
22,balloon
23,fall_floor
26,fruit
28,fly_fruit
64,fake_wall
86,message
96,big_chest
118,flag
]],"\n"),function(t)
 local tile,obj=unpack(split(t))
 tiles[tile]=_ENV[obj]
end)

-- [object functions]

function init_object(type,x,y,tile)
 if type.if_not_fruit and got_fruit[level_index()] then
  return
 end

 local obj={
  type=type,
  collideable=true,
  --solids=false,
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
      obj.check(fake_wall,ox,oy)
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
   obj.rem[axis]+=vector(ox,oy)[axis]
   local amt=flr(obj.rem[axis]+0.5)
   obj.rem[axis]-=amt
   if obj.solids then
    local step=sign(amt)
    local d=axis=="x" and step or 0
    for i=start,abs(amt) do
     if not obj.is_solid(d,step-d) then
      obj[axis]+=step
     else
      obj.spd[axis],obj.rem[axis]=0,0
      break
     end
    end
   else
    obj[axis]+=amt
   end
  end
 end

 add(objects,obj);
 (obj.type.init or max)(obj)

 return obj
end

function destroy_object(obj)
 del(objects,obj)
end

function kill_player(obj)
 sfx_timer=12
 sfx"0"
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
--  delay_restart=15
--end

function next_room()
 local level=level_index()
 local answer=true
 for i,v in ipairs(puzzle) do
		if v~=i-1 then answer=false break end
 end
 if answer or level==11 or level==21 or level==30 then -- quiet for old site, 2200m, summit
  music(30,500,7)
 elseif level==12 then -- 1300m
  music(20,500,7)
 end
 for i,v in ipairs(puzzle) do
  cpy_puzzle[i]=v
 end
 if answer then
 load_room(6,3)
 else load_room(0,0)
 end
end

function load_room(x,y)
 for i,v in ipairs(cpy_puzzle) do
  puzzle[i]=v
 end
	for i=0,15 do
 	for u=0,3 do
 	 for v=0,3 do
 	  local p = puzzle[i+1]
 	  local px = (p%4)*4+u
 	  local py = flr(p/4)*4+v
 	  mset((i%4)*4+u,
 	  						flr(i/4)*4+v,
 	  						mget(16+px,py))
 	 end
 	end
 end

 has_dashed,has_key=false,--false
 --remove existing objects
 foreach(objects,destroy_object)
 --current room
 room=vector(x,y)
 -- entities
 for tx=0,15 do
  for ty=0,15 do
   local tile=tile_at(tx,ty)
   if tiles[tile] then
    init_object(tiles[tile],tx*8,ty*8,tile)
   end
  end
 end
 -- room title
 if not is_title() then
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
   camera(-2+rnd"5",-2+rnd"5")
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
  (obj.type.update or max)(obj)
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
   sfx"38"
  end
 end
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
   pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 13 or i)
  end
 end

 -- draw bg color (pad for screenshake)
 cls()
 rectfill(0,0,127,127,flash_bg and frames/5 or new_bg and 2 or 0)

 -- bg clouds effect
 if not is_title() then
  foreach(clouds,function(c)
   c.x+=c.spd
   --crectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,new_bg and 14 or 1)
   if c.x>128 then
    c.x=-c.w
    c.y=rnd"120"
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
 map(rx,ry,is_title() and -4 or 0,0,16,16,2)

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
  crectfill(p.y,p.x,p.y+p.s,p.x+p.s,p.c)
  if p.x>132 then
   p.x=-4
   p.y=rnd"128"
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
  crectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14+p.t*5%2)
 end)

 -- credits
 if is_title() then
  rectfill(0,0,128,30,1)
 	rectfill(0,118,128,130,1)
 	rectfill(0,0,19,130,1)
 	rectfill(124,0,128,130,1)
 	circfill(20,31,1)
 	circfill(20,117,1)
 	circfill(123,31,1)
 	circfill(123,117,1)
 	circfill(10,10,7,0)
 	spr(136,6,6)
 	?"l9 miku",20,4,7
 	?"⬇️",52,4,12
 	?"@pcatto • 3h",64,4,13
 	?"this 97 year old community",20,12,6
 	?"still serves their mods",20,18,6
 	?"the old fashioned way",20,24,6
  ?"z+x",66,82,5
  ?"maddy thorson",48,98,5
  ?"noel berry",52,104,5
  ?"mod by massena",46,110,1
  ?"ワ20  こ3  ♥67k  ∧589k ホ",19,120,13
 end

 -- summit blinds effect
 if level_index()==31 and objects[2].type==player then
  local diff=min(24,40-abs(objects[2].x-60))
  rectfill(0,0,diff,127,0)
  rectfill(127-diff,0,127,127,0)
 end
 
 --dispuzzle
 if dispuzzle<1 then
  rectfill(31,15,96,80,0)
  for i=0,15 do
   if puzzle[i+1]~=12 then
   	sspr((puzzle[i+1]%4)*16,
   					64+flr(puzzle[i+1]/4)*16,	
   					16,16,
   					32+(i%4)*16,16+flr(i/4)*16)
   end
  end
  rectfill(43,81,83,87,0)
  ?"dashes:"..idontcareanymore.."/"..max_dash,44,82,7
 end
end

function draw_object(obj)
 (obj.type.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj)
 spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
end

function draw_time(x,y)
 rectfill(x,y,x+32,y+6,0)
 ?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds),x+1,y+1,7
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

function shuffle(x)
 -- vibe coding without ai
	while(x>0) do
  brk=false
  v_input,h_input=0,0
  if flr(rnd(4))>1 then
   v_input=flr(rnd(2))>0 and 1 or -1
  else
   h_input=flr(rnd(2))>0 and 1 or -1
  end
  if v_input~= 0 then
	    if v_input>0 then
	    	for sy=3,1,-1 do
	    	 for sx=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4-3]
	    	   puzzle[sx+sy*4-3]=12
	    	   brk=true
	    	  end
	    	 end
	    	 if brk then break end
	    	end
	    end
	    if v_input<0 then
	    	for sy=0,2 do
	    	 for sx=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4+5]
	    	   puzzle[sx+sy*4+5]=12
	    	   brk=true
	    	  end
	    	 end
	    	 if brk then break end
	    	end
	    end
    else
	    if h_input>0 then
	    	for sx=3,1,-1 do
	    	 for sy=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4]
	    	   puzzle[sx+sy*4]=12
	    	   brk=true
	    	  end
	    	 end
	    	 if brk then break end
	    	end
	    end
	    if h_input<0 then
	    	for sx=0,2 do
	    	 for sy=0,3 do
	    	  if puzzle[sx+sy*4+1]==12 then
	    	   puzzle[sx+sy*4+1]=puzzle[sx+sy*4+2]
	    	   puzzle[sx+sy*4+2]=12
	    	   brk=true
	    	  end
	    	 end
	    	 if brk then break end
	    	end
	    end
    end
  x-=1
 end
end
__gfx__
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700000060000000600000060000
000000000888888008888880888777780888888008888800000000000877777000a000a0000a0a000000a0000777777677777770000060000000600000060000
000000008887777888877778887eeee788877778877778800888888087e1ee1700a909a0000a0a000000a0007766666667767777000600000000600000060000
00000000887eeee7887eeee787e1ff17887eeee77eeee7808887777887fffff7009aaa900009a9000000a0007677766676666677000600000000600000060000
0000000087e1ff1787e1ff1707fffff087e1ff1771ff1e70887eeee787fffff70000a0000000a0000000a0000000000000000000000600000006000000006000
0000000007fffff007fffff00033330007fffff00fffff7087effff7073333700099a0000009a0000000a0000000000000000000000600000006000000006000
00000000003333000033330007000070073333000033337007f1ff10003333000009a0000000a0000000a0000000000000000000000060000006000000006000
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0000000000000000000000060000006000000006000
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
5777755777577775077777777777777777777770077777700000000000000000cccccccc00000000000000000000000000000000000000000000000000000000
7777777777777777700007770000777000007777700077770000000000000000c77ccccc00000000000000000000000000000000000000000000000000000000
7777cc7777cc777770cc777cccc777ccccc7770770c777070000000000000000c77cc7cc00000000000000000000000000000000000000000000000000000000
777cccccccccc77770c777cccc777ccccc777c0770777c070000000000000000cccccccc00000000000000000000000000006000000000000000000000000000
77cccccccccccc77707770000777000007770007777700070002eeeeeeee2000cccccccc00000000000000000000000000060600000000000000000000000000
57cc77ccccc7cc7577770000777000007770000777700007002eeeeeeeeee200cc7ccccc00000000000000000000000000d00060000000000000000000000000
577c77ccccccc7757000000000000000000c000770000c0700eeeeeeeeeeee00ccccc7cc0000000000000000000000000d00000c000000000000000000000000
777cccccccccc7777000000000000000000000077000000700e22222e2e22e00cccccccc000000000000000000000000d000000c000000000000000000000000
777cccccccccc7777000000000000000000000077000000700eeeeeeeeeeee000000000000000000000000000000000c0000000c000600000000000000000000
577cccccccccc7777000000c000000000000000770cc000700e22e2222e22e00000000000000000000000000000000d000000000c060d0000000000000000000
57cc7cccc77ccc7570000000000cc0000000000770cc000700eeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000
77ccccccc77ccc7770c00000000cc00000000c0770000c0700eee222e22eee000000000000666006606060660066006660606066006600066006000066060600
777cccccccccc7777000000000000000000000077000000700eeeeeeeeeeee005555555500666066606060666066606660606066606660066606000666060600
7777cc7777cc777770000000000000000000000770c0000700eeeeeeeeeeee005555555500006060606060606060600600606060606060060606000606060600
777777777777777770000000c0000000000000077000000700ee77eee7777e00555555550000d0d0d0ddd0d0d0ddd00d00ddd0ddd0d0d00dd00d000d0d0ddd00
57777577775577757000000000000000000000077000c0070777777777777770555555550000d0d0d0d0d0ddd0ddd00d00d0d0d0d0d0d00d0d0d000d0d0ddd00
00000000000000007000000000000000000000077000000700777700500000000000000500dd00ddd0d0d0d0d0d0d00d00d0d0d0d0d0d00ddd0ddd0ddd0ddd00
00aaaaaaaaaaaa00700000000000000000000007700c000707000070550000000000005500dd00dd00d0d0d0d0d0d00d00d0d0d0d0d0d00dd00ddd0dd00ddd00
0a999999999999a0700000000000c000000000077000000770770007555000000000055500000000000000000000000000000000000000000000000000000000
a99aaaaaaaaaa99a7000000cc0000000000000077000cc077077bb07555500000000555500000000000000000000000000000000000000000000000000000000
a9aaaaaaaaaaaa9a7000000cc0000000000c00077000cc07700bbb07555555555555555500060600660606060006600066006660066006600066060606600000
a99999999999999a70c00000000000000000000770c00007700bbb07555555555555555500060606660606060006660066606660066606660666060606660000
a99999999999999a7000000000000000000000077000000707000070555555555555555500060606060606060006060060606000060606060606060606060000
a99999999999999a07777777777777777777777007777770007777005555555555555555000ddd0d0d0d0d0d000d0d00dd00dd000ddd0dd00d0d0d0d0d0d0000
aaaaaaaaaaaaaaaa07777777777777777777777007777770004bbb00004b000000400bbb000ddd0d0d0d0d0d000d0d00d0d0d0000ddd0d0d0d0d0d0d0d0d0000
a49494a11a49494a70007770000077700000777770007777004bbbbb004bb000004bbbbb000ddd0ddd0ddd0ddd0ddd00ddd0ddd00d000d0d0ddd0ddd0ddd0000
a494a4a11a4a494a70c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb00000ddd0dd000dd0ddd0dd000dd00ddd00d000d0d0dd000dd0dd00000
a49444aaaa44494a70777ccccc777ccccc777c0770777c07040000000400bbb00400000000000000000000000000000000000000000000000000000000000000
a49999aaaa99994a7777000007770000077700077777000704000000040000000400000000000100000000000000000000000000000000000000000000010000
a49444999944494a77700000777000007770000777700c0742000000420000004200000000000100000000000000000000000000000000000000000000001000
a494a444444a494a7000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
a49499999999494a0777777777777777777777700777777040000000400000004000000000010000000000000000000000000000000000000000000000000010
66656666666666666666666666666666666666666666666666600006666665660cc00cc000000000555555550000000000000000000000000000000000000000
68755566000000000d66666666666666666666d066100006666600d666687555ccc1c1cc00000000555005550000000000000000000000000000000000000000
688876600d600666006666d0000d66d066100000d00660d66666006666688876cc1ccc1c00000000550000550000000000000000000000000000000000000000
555886610600666d0066600660006600d0066d0006660066666d006666555886cceffffc00000000500000050000000000000000000011111111000006666000
655d66666d0000000166000000d66d00066660016666006666600d6666655d66ccf1ff1c00000000555005550000000000000000001111111111100000066000
5d6d666660016661000600d666666001666610d66666000d66000666665d6d66ccfffffc00000000555005550000000000000000001111111111110000060000
6666666600d6666600000066661000d666661066666660000000666677666666ccddcdcc00000000555555550000000000000000010001111100010006666600
66d006600666610001dd100000d6106666666666666666610006666677666666c010010c00000000555555550000000000000000110001111100011000060000
66006d000000000d6666776666666666666666666666660000666666666666660000000000000000000000000000000000000000110001111100011000660000
661101660000d666666677666666d0000000016666dd0000d6666666666666660000000000000000000000000000000000066001111111111111111000600000
666666666666666666666666666000d6666dd0000000166666666cddddd666660000000000000000000000000000000000660001111199999911111000000000
6662262266222266228668222600166666666666666666666666ddddddddcc660000000000000000000000000000000000600001111199999991111000011110
666222266228226222266226660066666666666666666666666cccddddd6cc660000000000000000000000000000000000666601111199999991111011111110
67762266622622626226622266d00666666666666666666666cdddccdd6666660000000000000000000000000000000000600601117799999991111111111110
677222262262262222266622666666676666666676666ddc6dddcdddcd6666cd0000000000000000000000000000000000666601177777777777111111111100
6622622622622622622622286666666666666666666666cddddddddddc666dcc00000000000000000000000000000000000000001777777777771111111d1000
66666666666666666666666666666666666666666666666cdddddddddd66dccc00000000000000000000000000000000dd000000177777777777711111dd0000
66666666666666666666611111116666666666666666666dddccccddddddcccc00000000000000000000000000000000d00000111777777777777111110d0d00
dd6666666776666666dd11111111666666667766666666dc666cccccdddccccc00000000000000000000000000000000d00011111777777777777110000d0d00
dd6666666776666666dd111111111dd6666677666666666666666cccccdccccc00000000000000000000000000000000d01111111777777777777110000d0d00
111dd6666666666666100001111111d66666666666666666666666cccccccccd000000000000000000000000000000000d111111177777777777711000dd0d00
11111666666666666d0000001111116666666666666666666666666cccccccdd000000000000000000000000000000000dd11111177777777777110000d00d00
1111116666d111116d880000111111666666666666666688888e666cccccccdd0000000000000000000000000000000001111111177777777777110000000000
001111d111111111010199001111116666666666666688888888866ccccc77cd0000000000000000000000000000000001110000177777777771110000000000
00011111111111111010119111111166666666666668888888888866cccc77cc0000000000000000000000000000000000000000117777777771110000000000
000011111111111111111118111111666666666666688888884e6866cccccccc0000000000000000000000000000000000000000117777777701110000000000
00001111111111111111111181111d666666668e666e88888446666ccccccccc0000000000000000000000000000000000000000011100000001110000000000
000011100101011111111111811ddd666666666488888888888e666ccccccccc0000000000000000000000000000000000000999999900000099999999000000
0000100000000011515151111dd66666666688e4488888888888888cc88ccc7c0000000000000000000000000000000000000999999900000099999999000000
0001000000000011545451111dd666666666688e8ee888888888888884cccccc0000000000000000000000000000000000000999999900000099999999000000
00000000010145444444441111666666666888e8eee888888eee88ee448ccccc0000000000000000000000000000000000000000000000000000000000000000
000000010141454444114411116666677688888eee8888888eeee8eeee8e8ccc0000000000000000000000000000000000000000000000000000000000000000
0000000144444444444444451556666778888888888888888eeeee88e8e888cc0000000000000000000000000000000000000000000000000000000000000000
00000054400444444450004411666666e88888828888888888888888888888cc2333435363730213334353537363021200000000000000000000000000000000
000000554444444445000004155666668888888828888888888588888888888c0000000000000000000000000000000000000000000000000000000000000000
000015550001444440144504116666668888888822888888885888888888888c639200a28282820000000000a282821300000000000000000000000000000000
0000555000000444415444441556666e884441000028888885588888888888880000000000000000000000000000000000000000000000000000000000000000
00005550144514444444444416666668884400000002444451000014448888880200000001828293000000000082820300000000000000000000000000000000
00005551544444444444454566666668884116670061444200000002448888880000000000000000000000000000000000000000000000000000000000000000
000555554444444444444454666666888881666d116e4441660076114488888832000000a282828200000000a382820200000000000000000000000000000000
dd551515444444444144444c6666666888817777117ffffe6611d661888888880000000000000000000000000000000000000000000000000000000000000000
d515515554451444144444c66666668888827777777fffff77117771888888886200000000828282768586828282920200000000000094a4b4c4d4e4f4000000
51115555555550004444496666666668888ee77777ffffff77777772888884840000000000000000000000000000000000000000000000000000000000000000
11111015555555544445199666776688884eeefffffffffff77777ee88888424620000000818283848586878a282004300000000000095a5b5c5d5e5f5000000
145154001155554445100996667766688828fffffffffffffffffeee484882220000000000000000000000000000000000000000000000000000000000000000
114444441111111110008999776666788822fffffffffffffffffff84248822233000001091929394959697901a2820300000000000096a6b6c6d6e6f6000000
111494499981111100899900776677774822efffe1ff1dff1ffffff2222822220000000000000000000000000000000000000000000000000000000000000000
1114994499999999999999000777777744222eeeee111111eefffee22228222d0200a3010a1a2a3a4a5a6a7a0100a27300000000000097a7b7c7d7e7f7000000
11444994999999999999994427777777742222eeeeee111eeeeeeed22242222c0000000000000000000000000000000000000000000000000000000000000000
114449994999997799999444227777777472222deeeeed1eeeeed5222222222c630082820b1b2b3b4b5b6b7b8200000200000000000000000000000000000000
111444999999977979944992222777777747222525deeeeeeed52522352222dc0000000000000000000000000000000000000000000000000000000000000000
11114449999997799799994222277777777425252555555555552553333522cc728682820c1c2c3c4c5c6c7c8200001200000000000000000000000000000000
1114ddddddddd776679977622222777777775555555555555555555333333ccc0000000000000000000000000000000000000000000000000000000000000000
1115dddddddddd776776dd7d2222d777777d55555555555555555533333333cc028282820d1d2d3d4d5d6d7d8200004200000000000000000000000000000000
11155dddddddddd6777dd77dd22222777755553dddddd355555555333333333c0000000000000000000000000000000000000000000000000000000000000000
115556777666666d7777777ddd22222775555dddddddddd5555555535533333d038282010e1e2e3e4e5e6e7e0100004200000000000000000000000000000000
1155dd6777666666d77777666662222255556dd111111dd655555315553333330000000000000000000000000000000000000000000000000000000000000000
1d55d55dddddddddd67666666666222333557111111111175555331153333333739200010f1f2f3f4f5f6f7f0100001300000000000000000000000000000000
1d5dd55ddddddddddd7777ddddddd333334f77d111111d7774533355555533330000000000000000000000000000000000000000000000000000000000000000
5d5d5554dddddddddd7777dddddd333335ff777777777777777f1533335533330200000093000000000000930000000200000000000000000000000000000000
55dd555111111111116666dddddd333351fff7777777777fe7771153333333330000000000000000000000000000000000000000000000000000000000000000
55d555511111111110dddd111115333311dfff7777777ffffd77f113333333353200100082000000670000820000000200000000000000000000000000000000
5ddd55111111111110ddd111111553311eeeff7777777ffdde77f115333335550000000000000000000000000000000000000000000000000000000000000000
5d5dd511111111110dddd111111555311eeee777777777eeee77f111333555553312222222324353630212435353631200000000000000000000000000000000
__label__
49999994499999944999999449999994000000000000000000000000499999945777777555000000000000005777777500070000000000000000000000000000
91111119911111199111111991111119000000000000000000000000911111197777777766700000000000007777777700000000000000000000000000000000
9111111991111119911111199111111900000000000000000000000091111119777c77776777700070000000777c777700000000000000000000000000000000
911111199111111991111119911111190000000000000000000000009111111977cccc77666000000000000077cccc7700000000000000000000000000000000
911111199111111991111119911111190000000000000000000000009111111977cccc77550000000000000077cccc7700000000000000000000000000000000
9111111991111119911111199111111900000000000000000000000091111119777cc7776670000000000000777cc77700000000000000000000000000000000
91111119911111199111111991111119000000000000000000000000911111197777777767777000000000007777777700000000000000000000000000000000
49999994499999944999999449999994000000000000000000000000499999945777777566600000000000005777777500000000000000000088880000000000
49999994499999944999999449999994000000000000000000000000000000005777777500000000000000055777777500000000000000000888888000000000
91111119911111199111111991111119000000000000000000000000000000007777777700000000000000557777777700000000000000000878888000000000
91111119911111199111111991111119000000000000000000000000000000007777777700000000000005557777777700000000000000000888888000000000
9111111991111119911111199111111900000000000000000000000000000000777cc7770000000000005555777cc77700000000000000000888888000000000
911111199111111991111119911111190000000000000000000000000000000077cccc77555555555555555577cccc7700000000000000000888888000000000
911111199111111991111119911111190000000000000000000000000000000077cccc77555555555555555577cccc7700000000000000000088880000000000
911111199111111991111119911111190000000000000000000000000000000077c7cc77555555555555555577c7cc7700000000000000000006000000000000
499999944999999449999994499999940000000000000000000000000000000077cccc77555555555555555577cccc7700000000000000000006000000000000
6665666549999994499999946665666500000000000000000000000000000000777ccc77555555555555555577cccc7700000000000000000006000000000000
6765676591111119911111196765676500000000000000000000000000000000777cc7775055555555555555777ccc7700000000000000000000600000000000
6770677091111119911111196770677000000000000000000000000000000000777cc7775555005555555555777ccc7770000000000000000000600000000000
070007009111111991111119070007000000000000000000000000000000000077ccc777555500555555555577ccc77700000000000000000000600000000000
070007009111111991111119070007000000000000000000000000000000000077cccc77555555555555555577ccc77700000000000000000000600000000000
000000009111111991111119000000000000000000000000000000000000000077cccc775505555555555555777cc77700000000000000000000000000000000
0000000091111119911111190000000000000000000000000000000000000000777cc7775555555555555555777cc77700000000000000000000000000000000
000000004999999449999994000000000000000000000000000000000000000057777775555555555555555577cccc7700000000000000000000000000000000
0000000000000000000000000000000049999994000000000000000000000000577777755555555500000666777ccc7700000000000000000000000000000000
0000000000000000000000000000000091111119000000000000000000000000777777775555555000077776777cc77700000000000000000000000000000000
0000000000000000000000000000000091111119000000000000000000000000777c77775555550000000766777cc77700000000000000000000000000000000
000000000000000000000000000000009111111900000000000000000000000077cccc77555550000000005577ccc77700000000000000000000000000000000
000000000000000000000000000000009111111900000000000000000000000077cccc77555500000000066677cccc7700000000000000000000000000000000
0000000000000000000000000000000091111119000000000000000000000000777cc777555000000007777677cccc7700000000000000000000000000000000
0000000000000000000000000000000091111119000000000000000000000000777777775500000000000766777cc77700000000000000000000000000000000
00000000000000000000000000000000499999940000000000000000000000005777777550000000000000555777777500000000000000000000000000000000
57777775577777777777777500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777c77777777ccc77ccc777700000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000
77cccc77777cccccccccc777000000000000000000000000000000000000000000000000000000b0000000000000000000000000007000700000000000700070
77cccc77777cccccccccc77700000000000000000000000000000000000000000000000000000b30000000000000000000000000007000700000000700700070
777cc7777777ccc77ccc777700000000000000000000000000000000000000000000000003000b00000000000000000000000000067706770000000006770677
77777777777777777777777700000000000000000000000000000000000000000000000000b0b300000000000000000000000000567656760000000056765676
57777775577777777777777500000000000000000000000000000000000000000000000000303300000000000000000000000000566656660000000056665666
57777777777777755777777500000000000000000000000000000000000000000000066657777777777777750000000000000000577777755555555557777775
77777777777777777777777700000000000000000000000000000000000000000007777677777777777777770000000000000000777777775555555577777777
7777cccccccc7777777c77770000000000000000000000000000000000000000000007667777ccc77ccc77770000000000000000777c77775555555577777777
777cccccccccc77777cccc77000000000000000000000000000000000000000000000055777cccccccccc777000000000000000077cccc7755555555777cc777
77cccccccccccc7777cccc77000000605555555500000000000000000000000000000666777cccccccccc7770000b0005555555577cccc775555555577cccc77
77cc77ccccc7cc77777cc7770000000055555555000000000000000000000000000777767777ccc77ccc7777000b000055555555777cc7775555555577cccc77
77cc77cccccccc77777777770000000055555555000000000000000000000700000007667777777777777777030b003055555555777777775555555577c7cc77
77cccccccccccc775777777500000000555555550000000000000000000000000000005557777777777777750303303055555555577777755555555577cccc77
77cccccccccccc7755555555000000005555555550000000000000000000000000000666577777755777777777777775555555555777777555555555777cc777
77cccccccccccc77555555500000000055500555550000008888888000ee0ee000077776777777777777777777777777555555557777777755555550777cc777
77cc7cccc77ccc77555555000000000055000055555000088887777800eeeee000000766777c77777777cccccccc777755000055777c777755555500777cc777
77ccccccc77ccc7755555000000000005000000555550008887eeee7000e8e000000005577cccc77777cccccccccc7775500005577cccc775555500077ccc777
777cccccccccc7775555000000000000555005555555500887e1ff1700eeeee00000066677cccc7777cccccccccccc775500005577c7cc775555000077cccc77
7777cccccccc77775550000000000000555005555555550077fffff000ee3ee000077776777cc77777cc77ccccc7cc7755000055777cc7775550000077cccc77
777777777777777755000000000000005555555555555550073333000000b000000007667777777777c777cccccccc77555555557777777755000000777cc777
577777777777777550000000000000005555555555555555007007000000b000000000555777777577c77ccccccccc7755555555577777755000000057777775
0000000000000000000000000000000057777775577777777777777777777775000000005555555577cccccccccccc7700000000666566650000000066656665
0000000000000000000000000000000077777777777777777777777777777777000006000555555577cccccccccccc7700000000676567650000000067656765
00000000000000000000000000000000777c77777777ccc7777777777ccc7777000000000055555577cc7cccc77ccc7700000000677067700000000067706770
0000000000000000000000000000000077cccc77777ccccc7c7777ccccccc777000000000005555577ccccccc77ccc7700000000070007000000000007000700
0000000000000000000000000000000077cccc77777ccccccc7777c7ccccc7770000000000005555777cccccccccc77700000000070007000000000007000700
00000000000000000000000000000000777cc7777777ccc7777777777ccc777700000000000005557777cccccccc777700000000000000000000000000000000
00000000000000000000000000000000777777777777777777777777777777770000000000000055777777777777777700000000000000000000000000000000
00000000000000000000000000000000577777755777777777777777777777750000000000000005577777777777777500000000000000000000000000000000
00000000000000000000000000000000577777755777777500000000000000000000000000000000000006665777777557777775577777750000000000770000
00000000000000000000000000000000777777777777777700000000000000000000000000000000000777767777777777777777777777770000000000770000
0000000000000000000000000000000077777777777c77770000000000000000000000000000000000000766777c7777777c7777777777770000000000000000
00000000000000000000000000000000777cc77777cccc77000000000000000000000000000000000000005577cccc7777cccc77777cc7770000000000000000
0000000000000000000000000000000077cccc7777cccc77000000000000000000000000000000000000066677cccc7777cccc7777cccc770000000000000000
0000000000000000000000000000000077cccc77777cc7770000000000000000000000000000000000077776777cc777777cc77777cccc770000000000000000
0000000000000000000000000000000077c7cc77777777770000000000000000000000000000000000000766777777777777777777c7cc770000000000000000
0000000000000000000000000000000077cccc77577777750000000000000000000000000000000000000055577777755777777577cccc770000000000000000
00000000000000000000000000000000777ccc776665666500000000000000000000000000000000000006665777777577cccccccccccc770000000000000000
00000000000000000000000000000000777cc7776765676500000000000000000000000000000000000777767777777777cccccccccccc770000000000000000
00000000000000000000000000000000777cc7776770677000000000000000000000000000000000000007667777777777cc7cccc77ccc770000000000000000
0000000000000000000000000000000077ccc777070007000000000000000000000000000000000000000055777cc77777ccccccc77ccc770000000000000000
00000000000000000000b0000000000077cccc7707000700000000000000000000000000000000000000066677cccc77777cccccccccc7770000000000000000
0000000000000000000b00000000000077cccc7700000000000000000000000000000000000000000007777677cccc777777cccccccc77770000000000000000
0000000000000000030b003000000000777cc77700000000000000000000000000000000000000000000076677c7cc7777777777777777770000000000000000
000000000000000003033030000000005777777500000000000000000000000000000000000000000000005577cccc7757777777777777750000000000000000
000000000000000057777775000000000000000000000000000000055777777500000000000000000000000077cccc7766656665666566650000000000000000
0000000000000000777777770000000000000000000000000000005577777777000000000000000000000000777ccc7767656765676567650000000000000000
0000000000000000777c777700000000000000000000000000000555777c7777000000000000000000000000777ccc7767706770677067700000000000000000
000000000000000077cccc770000000000000000070000000000555577cccc7700000000000000000000000077ccc77707000700070007000000000000000000
000000000000000077cccc770000000000000000000000000005555577cccc7700000000000000000000000077ccc77707000700070007000000000000000000
0000000000000000777cc77700000000000000000000000000555555777cc777000000000000000000000000777cc77700000000000000000000000000000000
0000000000000000777777770000000000000000000000000555555577777777000000000000000000000000777cc77700000000000000000000000000000000
000000000000000057777775000000000000000000000000555555555777777500000000000000000000000077cccc7700000000000000000000000000000000
0000000000000000000000000000000000000000000000005777777777777775000000000000000000000000777ccc7700000000000000000000000000000000
0000000000000000000000000000000000000000000000007777777777777777000000000000000000000000777cc77700000000000000000000000000000000
0000000000000000000000000000000000000000000000007777ccc77ccc7777000000000000000000000000777cc77700000000000000000000000000000000
000000000000000000000000000000000000000000000000777cccccccccc77700000000000000000000000077ccc77700000000000000000000000000000000
000000000000000000000000000000000000000000000000777cccccccccc77700000000000000000000000077cccc7700000000000000000000000000000000
0000000000000000000000000000000000000000000000007777ccc77ccc777700000000000000000000000077cccc7700000000000000000000000000000000
0000000000000000000000000000000000000000000000007777777777777777000000000000000000000000777cc77700000000000000000000000000000000
00000000000000000000000000000000000000000000000057777777777777750000000000000000000000005777777500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000057777777777777755777777557777775
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777777777777
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777cccccccc777777777777777c7777
000000000070007000700070000000000000000000000000000000000000000000000000000000000000000000000000777cccccccccc777777cc77777cccc77
00000000007000700070007000000000000000000000000000000000000000000000000000000000000000000000000077cccccccccccc7777cccc7777cccc77
00000000067706770677067700000000000000000000000000000000000000000000000000000000000000000000000077cc77ccccc7cc7777cccc77777cc777
00000000567656765676567600000000000000000000000000000000000000000000000000000000000000000000000077cc77cccccccc7777c7cc7777777777
00000000566656665666566600000000000000060000000000000000000000000000000000000000000000000000000077cccccccccccc7777cccc7757777775
00000000577777757777777500000000000000000000000000000000000000000000000000000000600000000000000077cccccccccccccccccccccc77777775
000000007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000777ccccccccccccccccccccc77777777
00000000777c77777ccc7777000000000000000000000000000000000000000000000000000000000006000000000000777ccccccccccccccccccccccccc7777
0000000077cccc77ccccc7770000000000000000000000000499994000000000007000700000000000000000007000707777ccccccccccccccccccccccccc777
0000000077cccc77ccccc7770000000000000000000000000050050000000000007000700000000000000000007000707777cccccccccccccccccccccccccc77
00000000777cc7777ccc7777000000000000000000000000000550000000000006770677000000000000000006770677777cccccccccccccccccccccccc7cc77
000000007777777777777777000000000000000000000000005005000000000056765676000000000000000056765676777ccccccccccccccccccccccccccc77
00000000577777757777777500000000000000000000000000055000000000005666566600000000000000005666566677cccccccccccccccccccccccccccc77
00000000577777775777777500000000000000000000000049999994000000000777777000000000000000000777777077cccccccccccccccccccccccccccc77
00000000777777777777777700000000000000000000000091111119000000007000777700000000000000007000777777ccccccccccccccccccccccccccc777
000000007777ccc7777c7777000000000000000000000000911111190000000070c77707000000000000000070c7770777cc7cccccccccccccccccccccccc777
00000000777ccccc77cccc77000000000000000000000000911111190000000070777c07000000000000000070777c0777cccccccccccccccccccccccccc7777
00000000777ccccc77cccc77000000000000000000000000911111190000000077770007000000000000000077770007777ccccccccccc7ccccccccccccc7777
000000007777ccc7777cc777000000000000000000000000911111190000000077700c07000000000000000077700c077777ccccccccccccccccccccccccc777
00000000777777777777777700000000000000000000000091111119000000007000000700000000000000007000000777777777cccccccccccccccccc6cc777
00000000577777775777777500000000000000000000000049999994000000000777777000000000000000000777777057777777cccccccccccccccccccccc77
0000000066656665666566650000000000000000000000000000000000000000000000000000000000000000000000005777777777cccccccccccccccccccc77
0000000067656765676567650000000000000000000000000000000000000000000000000000000000000000000000007777777777cccccccccccccccccccc77
0000000067706770677067700000000000000000000000000000000000000000000000000000000000000000000000007777ccc777cc7cccccccccccc77ccc77
000000000700070007000700000000000000000000000000000000000000000000000000000000000000000000000000777ccccc77ccccccccccccccc77ccc77
000000000700070007000700000000000000000000000000000000000000000000000000000000000000000000000000777ccccc777cccccccc77cccccccc777
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777ccc77777ccccc777777ccccc7777
00000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000057777667577777777777777777777775

__gff__
0000000000000000000000000000000004020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202020200001313131302020302020202020002000013131313020204020202020202020000131313130004040202020202020200001313131300000002020202020202
0303030303030303020004000000000004040404040404040000000000000000040404040404040400000000000000000404040404040404000000000000000004040404040404040000000000000000040404040404040400000000000000000404040404040404000000000000000004040404040404040000000000000000
__map__
0000000000000000000000000000000027200000000000000000001700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000371b000000003d000000000000001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000003a20000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000003436000000001700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000017171717001111000000000000110011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000017171717002036000000120058202827000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001b17171b003420000000170010202937000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001b1b0000000000001b001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000202b00202123272020343600003f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000002758682724252523212320003b34363d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000003738283031252526313329003b202123000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020293b373431323300000000002a3133000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000202700000000000000003b20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000058000000313300001100001100003b27000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000008a39013e1b1b00007500007500000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020343536000000000000000000000037000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

