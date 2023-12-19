pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--*actuate*--
--[[
by sparky9d
a celeste mod made in 7 hours
for 12 days of cchristmas

based on evercore v2.1.0,
a cc mod base by
taco360, meep, gonengazit,
and akliant

original game by:
maddy thorson + noel berry
]]

-- [data structures]

function vector(x,y)
  return {x=x,y=y}
end

function rectangle(x,y,w,h)
  return {x=x,y=y,w=w,h=h}
end

-- [globals]

--tables
objects,got_fruit={},{}
--timers
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
--camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

switch=false
actuate=0

poke(0x5f2e,1)

-- [entry point]

function _init()
  frames,start_game_flash=0,0
  music(40,0,7)
  lvl_id=0
end

function begin_game()
  max_djump=1
  deaths,frames,seconds,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,1
  music(0,0,7)
  load_level(1)
end

function is_title()
  return lvl_id==0
end

-- [effects]

clouds={}
for i=0,24 do
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

-- [player entity]

player={
  layer=2,
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
  end,
  update=function(this)
    if pause_player then
      return
    end

    -- horizontal input
    local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0

    -- spike collision / bottom death
    if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
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
      if not this.is_flag(0,1,7) and this.djump<max_djump then
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

      if this.djump>0 and dash then
        switch=not switch
        actuate=2
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
        psfx"3"
        freeze=2
        -- dash target speeds and accels
        this.dash_target_x=2*sign(this.spd.x)
        this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
        this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
        this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
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

    -- exit level off the top (except summit)
    if this.y<-4 and levels[lvl_id+1] then
      next_level()
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
  pal(8,djump==1 and 8 or djump==2 and 7+frames\3%2*4 or 12)
end

function draw_hair(obj)
  local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
  for i,h in ipairs(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    circfill(h.x,h.y,mid(4-i,1,2),8)
    last=h
  end
end

-- [other objects]

player_spawn={
  layer=2,
  init=function(this)
    sfx"4"
    this.spr=3
    this.target=this.y
    this.y=min(this.y+48,lvl_ph)
    cam_x,cam_y=mid(this.x,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
    this.spd.y=-4
    this.state=0
    this.delay=0
    create_hair(this)
    this.djump=max_djump
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
  draw= player.draw
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
        this.spr=0
        this.timer=60
      end
    elseif this.timer>0 then
      this.timer-=1
    else
      psfx"7"
      this.init_smoke()
      this.spr=22
    end
  end
}

swap={
  init=function(this)
    --if true, it goes against the switch global
    this.off=(this.spr%2==0)
    this.extended=this.off
    local aaa={
      [65]=0,
      [66]=0,
      [67]=1,
      [68]=1,
      [69]=2,
      [70]=2,
      [71]=3,
      [72]=3
    }
    this.s_type=aaa[this.spr]
    if this.s_type==0 then
      this.y+=1
      this.hitbox=rectangle(0,5,8,3)
    elseif this.s_type==1 then
      this.x+=1
      this.hitbox=rectangle(5,0,3,8)
    elseif this.s_type==2 then
      this.y-=1
      this.hitbox=rectangle(0,0,8,3)
    else
      this.x-=1
      this.hitbox=rectangle(0,0,3,8)
    end
  end,
  update=function(this)
    if actuate==1 then
      if switch then
        this.extended=not this.off
        this.spr+=(this.off and -1 or 1)
      else
        this.extended=this.off
        this.spr+=(this.off and 1 or -1)
      end
    end
    local hit=this.player_here()
    if hit and this.extended then
      kill_player(hit)
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
    spr(this.state==2 and 21 or this.state==1 and 26-this.delay/5 or this.state==0 and 23,this.x,this.y) --add an if statement if you use sprite 0 (other stuff also breaks if you do this i think)
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
  layer=3,
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
          sfx"14"
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
    hit.djump=max_djump
    sfx_timer=20
    sfx"13"
    got_fruit[this.fruit_id]=true
    init_object(lifeup,this.x,this.y)
    destroy_object(this)
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
    ?"1000",this.x-4,this.y-4,7+this.flash%2
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

function init_fruit(this,ox,oy)
  sfx_timer=20
  sfx"16"
  init_object(fruit,this.x+ox,this.y+oy,26).fruit_id=this.fruit_id
  destroy_object(this)
end

key={
  update=function(this)
    this.spr=flr(9.5+sin(frames/30))
    if frames==18 then --if spr==10 and previous spr~=10
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

flag={
  init=function(this)
    this.x+=5
  end,
  update=function(this)
    if not this.show and this.player_here() then
      sfx"55"
      sfx_timer,this.show,time_ticking=30,true,false
    end
  end,
  draw=function(this)
    spr(118+frames/5%3,this.x,this.y)
    if this.show then
      camera()
      rectfill(32,2,96,31,0)
      rect(32,2,96,31,7)
      spr(26,54,6)
      ?"x"..fruit_count,64,8,7
      draw_time(49,15)
      ?"deaths:"..deaths,48,23,7
      camera(draw_x,draw_y)
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
65,swap
66,swap
67,swap
68,swap
69,swap
70,swap
71,swap
72,swap
18,spring
20,chest
22,balloon
23,fall_floor
26,fruit
45,fly_fruit
64,fake_wall
96,big_chest
118,flag
]],"\n"),function(t)
 local tile,obj=unpack(split(t))
 tiles[tile]=_ENV[obj]
end)


-- [object functions]

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
    return obj.is_flag(ox,oy,0) -- solid terrain
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

  function obj.check(type,ox,oy)
    for other in all(objects) do
      if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
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

function kill_player(obj)
  switch=false
  actuate=0
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

-- [level functions]

function next_level()
  local next_lvl=lvl_id+1

  --check for music trigger
  if music_switches[next_lvl] then
    music(music_switches[next_lvl],500,7)
  end

  load_level(next_lvl)
end

function load_level(id)
  switch=false
  actuate=0
  has_dashed,has_key= false--,false


  --remove existing objects
  foreach(objects,destroy_object)

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
    --chcek for mapdata strings
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

-- [main update loop]

function _update()
  frames+=1
  if time_ticking then
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
  
  if actuate>0 then
    actuate-=1
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
  if is_title() then
    if start_game then
    	for i=1,15 do
        pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
    	end
    end

    cls()

    -- credits
    sspr(unpack(split"72,32,56,32,36,32"))
    ?"🅾️/❎",55,72,5
    ?"maddy thorson",40,84,5
    ?"noel berry",46,90,5
    ?"mod by sparky9d",36,102,4

    -- particles
  		foreach(particles,draw_particle)

    pal(14,129,1)
    pal(4,140,1)
    
    return
  end

  -- draw bg color
  cls(flash_bg and frames/5 or bg_col)

  -- bg clouds effect
  foreach(clouds,function(c)
    c.x+=(c.spd*0.5)-cam_spdx
    ovalfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col)
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
  --0: background layer
  --1: default layer
  --2: player layer
  --3: foreground layer
  local layers={{},{},{}}
  foreach(objects,function(o)
    if o.type.layer==0 then
      draw_object(o) --draw below terrain
    else
      add(layers[o.type.layer or 1],o) --add object to layer, default draw below player
    end
  end)

  -- draw terrain
  map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,2)

  -- draw objects
  foreach(layers,function(l)
    foreach(l,draw_object)
  end)

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

  -- draw level title
  camera()
  if ui_timer>=-30 then
    if ui_timer<0 then
      draw_ui()
    end
    ui_timer-=1
  end
  
  pal(14,129,1)
  pal(4,140,1)
  
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

function draw_ui()
  rectfill(24,58,104,70,0)
  rect(24,58,104,70,7)
  local title=lvl_title or lvl_id.."00 m"
  ?title,64-#title*2,62,7
  draw_time(4,4)
end

function two_digit_str(x)
  return x<10 and "0"..x or x
end

-- [helper functions]

function round(x)
  return flr(x+0.5)
end

function appr(val,target,amount)
  return val>target and max(val-amount,target) or min(val+amount,target)
end

function sign(v)
  return v~=0 and sgn(v) or 0
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
--[map metadata]

--@begin
--level table
--"x,y,w,h,title"
levels={
  "0,0,1.75,1,snowy hollow",
  "0,1,2,1,icicle path",
  "0,2,2,1,freezing point",
  "3,0,1.5,1.5,blizzard cliff",
  "2,0.25,1,1.75,icy outcrop",
  "2,2,1.75,1.25,wind chill",
  "0,3,1,1,sanctuary"
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
	
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
	[7]=30
}

--@end

--replace mapdata with hex
function replace_mapdata(x,y,w,h,data)
  for i=1,#data,2 do
    mset(x+i\2%w,y+i\2\w,"0x"..sub(data,i,i+1))
  end
end

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
    reserve..=num2hex(mget(i%w,i\w))
  end
  printh(reserve,"@clip")
end

--convert mapdata to memory data
function num2hex(v)
  return sub(tostr(v,true),5,6)
end
__gfx__
0000000000000000000000000888888000000000000000000000000000000000000aaa000000a0000000a000edd555dd5555dd5555dd5dde0000055500000000
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a000dd55666555665566665565dd0005500000000000
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a9a000000a00055166416661466611466665d0066660000000000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8000aaa000000a0000000a0005664111111166411111161650607076000000000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0006611111111111111111116650600706000000000
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0006411661111111111111614660609076000000000
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a000611164111111111111661166067a906000000000
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0006611411111111111111411660066660000000000
eeeeeeee000000000000000000000000000000000660660000066000e666666ee666666ee666066e0300b0b0dddeddde55500000000000000000000070000000
eeeeeeee000000000000000000000000000000000000000600688600666ddd66666d6dd666d706d6003b3300d7ded7de00055000007700000770070007000007
ee0000ee00000000000000000000000009999990600000060682886066ddddd666dd7dd6767007d602888820d770d77000666600007770700777000000000000
ee0000ee0070007004cccc40000000009662222960000000688828866dddddd6667606d600000077089888800700070006707060077777700770000000000000
ee0000ee0070007000500500000000009622222900000006688828866dddddd66dd6076667000000088889800700070006070060077777700000700000000000
ee0000ee0d770d7700055000000000009999999960000006062282606ddddd666ddd7d666d700766088988800000000006709060077777700000077000000000
eeeeeeeeed7ded7d005005000000000096200229600000000062260066ddd6666dd6d6666d7076d602888820000000000609a760070777000007077007000070
eeeeeeeeedddeddd0005500004cccc40962222290066066000066000e666666ee666666ee700766e002882000000000000666600000000007000000000000000
e666666ee6666666666666666666666e664111111111111111111666e666666eeeeeeeeeeeeeeeeeeeeeeeeeee00000007777770000000000000000000000000
6666666666666666666666666666666666611111111111111111646666666666eeeeeeeeeeeeeee00eeeeeeedd70000077677677000777770000000000000000
6664166666166416661466611466666666611111111111111111666666664166eeeeeeeeeeeeee0000eeeeeed777700076676667007766700000000000000000
6611116666641111111664111111616666641111111111111111466666161666eeeeeeeeeeeee000000eeeeeddd0000076663366076777000000000000000000
6641146666111111111111111111166666161111111111111111166666641166eeeeeeeeeeee00000000eeeeee00000066663366077660000777770000000000
6661666664116611111111111116146666661111111111111111161666611166eeeeeeeeeee0000000000eeedd70000063663336077770000777767007700000
6666666661116411111111111166116666611111111111111111146666116166eeeeeeeeee000000000000eed77770006333bb36070000000700007707777770
e666666e66114111111111111114116666411111111111111111116666164166eeeeeeeee00000000000000eddd000000333bb30000000000000000000077777
66411166661111111111111111111166e6666666666666666666666e66111166eeeeeeeee00000000000000e00000ddd033333300000000000000000003b0330
6661646666111111111111111111116666666666666666666666666666111666e0eeeeeeee000000000000ee0007777d03b333300000000000aa0aa0003b0b30
6661666666116111111111111641166666616646666146666641466666611466eeee00eeeee0000000000eee000007dd033333300000000000aaaaa003b000b0
6641166666411111111111111661616666166111111166411111116666611166eeee00eeeeee00000000eeee000000ee0333b33000000000000a9a00030000b0
6611166666641111466146611111466666411111646611111111116666411166eeeeeeeeeeeee000000eeeee00000ddd003333000000d00000aaaaa00b000b00
6661146666666111666666411146666666664116661664666416664666111666ee0eeeeeeeeeee0000eeeeee0007777d00055000000d000000aa3aa000300000
6161116666664666666666666666666666666666666666666666666666646666eeeeeeeeeeeeeee00eeeeeee000007dd00055000050d00500000b00000b00000
66411166e6666666666666666666666ee6666666666666666666666ee666666eeeeeeeeeeeeeeeeeeeeeeeee000000ee00999900050550500000b00000000000
566665560000000000000000000000100000c4100110011001100110000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000cc100cccc411c101c1014401440110000001444000000000000000000000000000000000000000000000000000000000000
661664660000000000c000c000000011000044410c000c004c404c401cc0000014cccc0000000000000000000000000000000000000000000000000000000000
666111160000000000c000c0000000000000000000000000cc40cc4001000000014c000000000000000000000000000000006000000000000000000000000000
664111110000000004cc04cc000000100000c410000000000c000c00000000000000000000000000000000000000000000066600000000000000000000000000
5611661100c000c004c404c400000cc100cccc41000000000c000c00110000001444000000000000000000000000000000dd6d60000000000000000000000000
5611641101c101c104410441000000110000444100000000000000001cc0000014cccc000000000000000000000000000dd6d6c0000000000000000000000000
6661111101100110011001100000000000000000000000000000000001000000014c0000000000000000000000000000dddd6ccc000000000000000000000000
6461111100000000000000000000000000000000eeeeeeee111111110000eeee0000000000000000000000000000000cdd6ddcdc000600000000000000000000
5661111100000000000000000000000000000000eeeeeeee166111110000eeee000000000000000000000000000000dccdd4d4cdc066d0000000000000000000
5641661100000000000000000000000000000000eeeeeeee146116110000eeee00000000000000000000000000000ccddc4ddddddd6d6d000000000000000000
6661411100000000000000000000000000000000eeeeeeee111111110000eeee000000000000000000000000000000dd0044d00dd00000d00000000000000000
666611110000000000000000000000000000000000000000111111110000eeeeeeeeeeee06666600066666006666660066040660066666006666660066666600
666161460000000000000000000000000000000000000000116116610000eeeeeeeeeeee66666660666666606666666066040660666666606666666066666660
666666660000000000000000000000000000000000000000114116410000eeeeeeeeeeee660006606600000000660000660d0dd0660006600066000066000000
566665660000000000000000000000000000000000000000111111110000eeeeeeeeeeeedd000dd0dd00000000dd0cc0dd0c0dd0dd000dd060dd0000dddd0000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeee00000000000000eddddddd0dd00000000dd0cc0dd000dd0ddddddd060dd0000dd000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeee000000000000eedd000dd0ddddddd0c0dd0dc0ddddddd0dd000dd0c0dd0000dddddd00
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeee0000000000eeedd000dd00ddddd00c0dd0cdc0ddddd00dd060dd060dd0000ddddddd0
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeee00000000eeee00000000000000cccc00ccddc00000cc00cc6006c600000000000000
0000000000000000000000000000000000000000eeee00000000eeeeeeeeeeeeeeeeeeee0000000000000ccccccccdccccccdddcccccc6666cc4c00000000000
0000000000000000000000000000000000000000eee0000000000eeeeeeeeeeeeeeeeeee000000000000cccccccdcccc4ccddcddc6c66646444ccc0000000000
0000000000000000000000000000000000000000ee000000000000eeeeeeeeeeeeeeeeee0000000000444cc4cc4cdc4c44c1cddccc6c6c6c44c4ccc000000000
0000000000000000000000000000000000000000e00000000000000eeeeeeeeeeeeeeeee000000000c14c4ccc4c4c4c4c14cdcccc6c6c6c14c1cc4c400000000
0000000000000000000000000000000000000000eeee0000004ccc00004c000000400ccc000000001141444c444444411414c1cc66664c14c4c11cc140000000
0000000000000000000000000000000000000000eeee0000004ccccc004cc000004ccccc00000004141414c4c4144441114c1cc6c46cc4144cc111cc1c000000
0000000000000000000000000000000000000000eeee000004100ccc041ccccc041ccc000000001e1111114c4111141414c1c1cc4c44114c4c4c1411ccc00000
0000000000000000000000000000000000000000eeee0000040000000400ccc0040000000000011eeee1e1111e1e11144cce1ec1141c1cc114c441111ccc0000
0000000000000000000000000000000000000000eeee000004000000040000000400000000000eeee0ee1e1e1ee1e1e114c1eee011111c1111441414c1c40000
0000000000000000000000000000000000000000eeee000041000000410000004100000000000e0e0000e0eee10ee01e11100e00010101001111414c4c404000
0000000000000000000000000000000000000000eeee0000400000004000000040000000000000e0e0e0000e10000e01010000e000100001001010c400041000
0000000000000000000000000000000000000000eeee0000400000004000000040000000000e0000000e00000e00000000001000000010000100000040100010
5252526242525252525252526213525252525252655262743442525252525223525252525252334252525223526242526242525262b2a28292b3425200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5252526213525252655223235232132352232352525262743442235252233312525265232333125252526202423342526242652333b2a38376b3425200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5252525263132352523356a21333828273123213232362743473a21333122252232333f3a28213235252652262125252621333920000a2560011425200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
526523338293f3133392000000a25666834252329266737400f300a212525252223292000066837613232323334252232332560000002400b312655200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
523392a28256860156000014141414a3821352621100a2930000c2a3425265525262c100000055669200f3a2125262015673c100110071001142522300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
625600005500a2829300e0432222328292b1426532b200668693c312525252525262760000c2a385000000864252629200f300b3021111111252331200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33c100000000006692000075425233560000135262b20000a2432252525223235265d09310c3b0d0d30044b05265620000148676824353225262125200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3276000000000000111100a21333b2000000b14233b2000000b3425252331222525252d0b0c05252d084444252523311007192a2565566132333425200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52d09310d30000b31232111112321100000000035666930000b3135262125252525252624252525233844442526212321111110000000000f366135200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5252c0c0d09300b313522222525232b20000110376869200000066133342525223232333135265628400444252331323222232840000000000a3824200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
525252653356000071425252655233b200441233825693140000a35666132352223254545413526284001142339300b342526284000000006682831300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323526283760000a21323525262b200004403839200a2720075560000f3b313526200a10086426284444362015661b3426533840000000000a2561200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2232133392000000111232132333b2001144735600001103110000006100000052337600a383133384004403829300114262b200759324240000004200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52523282570061861265522232b200117284669300b3432332c10000000000a362b2a276825655000000447356a276122333b2000066b0d00000114200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
655262920085a382425252526211111262848601769371b303760000a376865633b200a3829300000000758393868273b271930000e042621111126500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52526200a382015642525252522222526284a282825600b3030193869266930032b200668282577593118656556692f300a28276001142523212525200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
526242525252526242525252235252520000000000000000000000000000000062b2118682019300667266930000000000860192001252526213525200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5262425252526562135265620242525200000000000000000000000000000000621172a292668276000311a276000011a356a276861365525232425200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5265324252525252324252522252522300000000000000000000000000000000652262c100a3920011423286920011720157006692b142525262425200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
525233425252525262425252525233120000000000000000000000000000000052526200868276001252629200a312629200000000a342525262425200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23331252525252526213232352621252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56001323655252233300f30013334265000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9300f3a21323330000008500a2435252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
017685868282000000a3827600664252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
82828282828282768682839200001323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8256a283926682568282550000a31222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
920000550000a286920000c2a3125252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
93100000c2000066936700c312526552000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22223293c300e3122222223213232352000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52653312222232135252526522223213000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52621252525252324252525252525222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52624252525265624252525252525252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000700000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000600000000000000000000000000000600000000006600000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000066600000000000000000000000000000000000000000000000000000000000000
00000000600000000000000000000000000000000000000000000000000000dd6d60000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000dd6d6c0000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000dddd6ccc000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000cdd6ddcdc000600000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000006600000000000000000000dccddsdscdc066d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000660000000000000000000ccddcsddddddd6d6d000000000770000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000dd00ssd00dd00000d00000000770000000000000000000000000000000000000000000
000000000000000000000000000000000000066666000666660066666600660s0660066666006666660066666600000000000000000000000000000000000000
000007000000000000000000000000000000666666606666666066666660660s0660666666606666666066666660000000000000000000000006600000000000
000000000000000000000000000000000000660006606600000000660000660d0dd0660006600066000066000000000000000000000000000006600000000000
000000000000000000000000000000000000dd000dd0dd00000000dd0cc0dd0c0dd0dd000dd060dd0000dddd0000000000000000000000000000000000000000
000000000000000000000000000000000000ddddddd0dd00000000dd0cc0dd000dd0ddddddd060dd0000dd000000000000000000000000000000000000000000
000000000000000000000000000000000000dd000dd0ddddddd0c0dd0dc0ddddddd0dd000dd0c0dd0000dddddd00000000000000000000000000000000000000
000000000000000000000000000000000000dd000dd00ddddd00c0dd0cdc0ddddd00dd060dd060dd0000ddddddd0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc00c66dc00000cc00cc6006c600000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000cccccccc66cccccdddcccccc6666ccsc00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000cccccccdccccsccddcddc6c666s6sssccc0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000sssccsccscdcscssc1cddccc6c6c6csscsccc000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000c1scscccscscscsc1scdcccc6c6c6c1sc1ccscs00000000000000000000000000000000000000000000
0000000000000000000060000000000000000000000011s1ssscsssssss11s1sc1cc6666sc1scsc11cc1s0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000s1s1s1scscs1ssss111sc1cc6cs6ccs1sscc111cc1c000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001h111111scs1111s1s1sc1c1ccscss11scscsc1s11ccc00000000000000000000000000000000000000000
0000000000000000000000000000000000000000011hhhh1h1111h1h111sscch6hc11s1c1cc11scss1111ccc0000000000000000000000000000000000000000
00000000000000000000000000000000000000000hhhh0hh1h1h1hh1h1h11sc1hhh011111c1111ss1s1sc1cs0000000000000000000000000000000000000000
00000000000000000000000000000000000000000h0h0000h0hhh10hh01h11100h00010101001111s1scscs0s000000000000000000000000000000000000000
000000000000000000000000000000000000000000h0h0h0000h10000h01010000h000100001001010cs000s1000000000000000000000000000000000000000
000000000000000000000000000000000000000h0000000h00000h000000000010000000100001000000s0100010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000006000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005550555055005500505000005550505005505550055005505500000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050505050505000000500505050505050500050505050000000000000000000000000000000000000
00000000000000000000000000000600000000005050555050505050555000000500555050505500555050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050505050005000000500505050505050005050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505055505550555000000500505055005050550055005050000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005500055055505000000055505550555055505050000000000000000000000000000000000000000000
00000000000000000000000000000000000700000000005050505050005000000050505000505050505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000070000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000
000000000000000000000000000000000000sss00ss0ss000000sss0s0s000000ss0sss0sss0sss0s0s0s0s0sss0ss0000000000000000000000000000000000
000000000000000000000000000000000000sss0s0s0s0s00000s0s0s0s00000s000s0s0s0s0s0s0s0s0s0s0s0s0s0s000000000000000000000000000000000
000000000000000000000000000000000000s0s0s0s0s0s00000ss00sss00000sss0sss0sss0ss00ss00sss0sss0s0s000000000000000000000000000000000
000000000000000000000000000000000000s0s0s0s0s0s00000s0s000s0000000s0s000s0s0s0s0s0s000s000s0s0s000000000000000000000000000000000
000000000000000000000000000000000000s0s0ss00sss00000sss0sss00000ss00s000s0s0s0s0s0s0sss000s0sss000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000838383020004020000000000000000000202000000030303030303030304040402020000000303030303030303040404020202020200000000000000000000020202020202000000000004030404020202020202020000000000040404040202020202020200000000000400000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2525322526242525252526242525252525252624262b00004324252500000000000000000000000000000000000000002525252525252525332425262b00682828290024252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25332a2426312525253233313225255625253324262b00004324323200000000000000000000000000000000000000002525252556252526212556332b3a106629001124252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26392c2425233132332867682931323225262425262b586843372122000000000000000000000000000000000000000025252525253232333132264857652900003b2125562525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25222225253375002a38285500003f6631332425332b2a67001b313200000000000000000000000000000000000000002525253233212236293f304800000017003b2425252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252525562665000000666500000000002a672426293a102900001b2100000000252629003a6566292425252525252525252533212225262b0068374800000000003b3125253232320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25252532331c0000000000111100000000663126682900005839002400000000252611576500000e3125252525252525252621252525262b002a55000000001111000031332122220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525332123424200576768212311000000002a37653911002a2a6724000000002525232b00004242422425252525252532332425252526110000000058003b2123111121222525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526212525223600002a2a3125231100000000290066271100001124000000002525332b003b2122222532323225252522233132252556232b0000682839112425362125253225250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526313232333f00000000442425230000003a4242422423111121250000000025264700163b24252526292a6724252525252223312525332b0068296600212526212525262024250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
562535363829000000000044312526675800573435352525222225560000000032334700003b2425253375162a242525562525252324264700002a75002a315626312525252225250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
253367682900000000000000662426296675003f2a28312525323225000000003f174700003b3125261b00005724252525252525263126470000000000001b2425233125562525320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33292a2900000041414168750e24331100000000006628313321232400000000002a686758004324261100004424323232322525331b37470000003a673a682425252331323233210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
233d01000000683422232900113721233900000000002a212225263100000000110066752a6743242523670044372821222331332b00663968750017556665242525333f006634250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252222233900002a242611002122562638001100581600242525252200000000231111003a10433125262900003f2a24252522232b0000662911110000001131252665001a002a240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252525252311111124562311242525262a6727682900573156252525000000002522232b6665003b2426111100683924252556332b0000003b212311111121233126000000000e240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25562525262122222525262125252526006630103900002a2425252500000000252526110000163b313222233a28103125252647006839003b3132222222252523371100000068310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252526242556252525253324252525323331252526313232263a2867242525252523110068673a38313355662828322526473a38286711212331322525562535364700002a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525253233242532323232332125253233652a6724252523556637663828242525252532362b2a282828291700002a65233133476628652a213233653f31252533102867000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2532336566243329003f3a28313233282900002a31325626113a293a286531322525332955006829576500000000001125232b003a29000e37650000003a2426482a652a394141410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3368290000304700005566291b1b1b2a39000000003f312523655566291121222526655800002a00004242420068672125262b576500005729002c005728312648000000660b0c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232900000e3747000000000000000068650000000000002426000000442125253226752a67110000000b0c0d3a292a2425262b000000000000003c3a6566283748000000113125250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26170000002a675800111158687557290000000000424231331c00004424252528371c572827000011242526651111245625363e015800006834222311002a6500005867212331250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26110057673d002a39212365291100003a580000683422232b000000443125562a3900002a37111121252526112122252533212222236768652a2425231c000000682828242523240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252311110b0d3a2838242611112700006638673a291b31262b000000003b242567650000003b21222525253235252525262125252525232900682425260000003a663829242526240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56252222323329552a31252222261100002a282875001b302b000068393b313229000000003b3125252533652a3125250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252525333f556639002a31562525230000682865000000372b003a2810671768000068396867293125262900006631250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25323329000000550000663132323311682828670000003f005765552a28172a1100662829553a2824336700003a65240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3321230000000000000000002a2122231075002a67000000414141416865000023110055005710283028290000550e240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222526110058586839002c000e242533290000000000583a0b0c0c0d29001111252300120068286537386700000000240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252300002a652a673c013a24261b0000000058683865312525261111212225260017002a29002a296639013e21250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252611111111112122222225261111683900002a29672824563321222525252611000000000000682122222225250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525562522222223212525252556262123282839006875572824262125252525252523000000000000212525252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
511000100406300605017050406324645040632b64501705090630170509063236052b645017051d6250170501705017050060523605017050160500605017050060525605016052360525605017052360500000
01100000077450f7451674513745077450f7451674513745077450f7451674513745077450f7451674513745057450e7451574511745057450e7451574511745057450e7451574511745057450e7451574511745
01100000130501505016050180501a0501b0501d0501f050006052360501705016050060501705006052560501605236052560501705236050000000000000000000000000000000000000000000000000000000
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01100000077450f7451674513745077450f7451674513745077450f7451674513745077450f7451674513745057450e7451574511745057450e7451574511745057450e7451574511745057450e7451574511745
012000001371413721137311374113751137501375013750117511175011750117500c7510c7500e7510e7500e7500e7500e7410e725017050060500000000000c7240c7410e7510e7500e7500e7500e7410e725
4920000002050020500205002050290001600022000220000305003050000000000005050050501f0021f00000050000500005000050030500305000000000000505005050050500505003050030500000000000
0108002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
01100000037450c745157450f745037450c745157450f745037450c745157450f745037450c745157450f745027450a745137450e745027450a745137450e745027450a745137450e745027450a745137450e745
0110000000050000500005000050000500005000050000501d7000000000000000000000000000000000000005050050500505005050050500505005050050500205002050020500205002050020500205002050
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
011000202b545274002e7452e400357453374535745337453074030745244002b400327403274530740307452e7402e7453074030745000000000000000000002b745000002e7450000035740357453074030745
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
91100020326103261032610326103161031610306102e6102a610256101b610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
91400000303453020530335333252b33530205303253020530205303253020530205303153020530205303152b3452b3052b33527325293352b3052b3252b3052b3052b3252b3052b3052b3152b3052b3052b315
__music__
01 12134344
00 120a1344
00 0b160a44
00 15160a44
00 0b160a44
02 15165344
00 41424344
00 41424344
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

