pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--blanc
--bY sHEEBEEHS

--built on ~evercore~
--a celeste classic mod base
--v2.1.0

--original game by:
--maddy thorson + noel berry

--major project contributions by
--taco360, meep, gonengazit, and akliant

-- [data structures]

poke(0x5f2e,1)

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
      if this.djump<max_djump then
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
  pal(8,djump==1 and 8 or djump==2 and 9+frames\3%2*-2 or 12)
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

doublecrystal={
  init=function(this) 
    this.offset=rnd(1)
    this.start=this.y
    this.timer=0
    this.hitbox=rectangle(-1,-1,10,10)
  end,
  update=function(this) 
    if this.spr==28 then
      this.offset+=0.01
      this.y=this.start+sin(this.offset)*2
      local hit=this.player_here()
      if hit and hit.djump<2 then
        max_djump=2
        psfx(6)
        this.init_smoke()
        hit.djump=max_djump
        this.spr=0
        this.timer=60
        max_djump=1
      end
    elseif this.timer>0 then
      this.timer-=1
    else 
      psfx(7)
      this.init_smoke()
      this.spr=28
    end
  end
}

crystal={
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
  end,
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
    spr(this.state==1 and 26-this.delay/5 or this.state==0 and 23,this.x,this.y) --add an if statement if you use sprite 0 (other stuff also breaks if you do this i think)
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



function init_fruit(this,ox,oy)
  sfx_timer=20
  sfx"16"
  init_object(fruit,this.x+ox,this.y+oy,26).fruit_id=this.fruit_id
  destroy_object(this)
end


platform={
  layer=0,
  init=function(this)
    this.x-=4
    this.hitbox.w=16
    this.dir=this.spr==11 and -1 or 1
    this.semisolid_obj=true
  end,
  update=function(this)
    this.spd.x=this.dir*0.65
    --screenwrap
    if this.x<-16 then
      this.x=lvl_pw
    elseif this.x>lvl_pw then
      this.x=-16
    end
  end,
  draw=function(this)
    spr(11,this.x,this.y-1,2,1)
  end
}

message={
  layer=3,
  init=function(this)
    this.text="#-- mONT bLANC --#warning: sPEED#TECH REQUIRED#"
    this.hitbox.x+=1
  end,
  draw=function(this)
    if this.player_here() then
      for i,s in ipairs(split(this.text,"#")) do
        camera()
        rectfill(22,7*i,105,7*i+6,9)
        rect(22,41,105,7,10)
        ?s,64-#s*2,7*i+1,10
        camera(draw_x,draw_y)
      end
    end
  end
}

orb={
  init=function(this)
    this.spd.y=-4
  end,
  update=function(this)
    this.spd.y=appr(this.spd.y,0,0.5)
    local hit=this.player_here()
    if this.spd.y==0 and hit then
      music_timer=45
      sfx"51"
      freeze=10
      destroy_object(this)
      max_djump=2
      hit.djump=2
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
    for i=0,0.875,0.125 do
      circfill(this.x+4+cos(frames/30+i)*8,this.y+4+sin(frames/30+i)*8,1,7)
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
						line(32,2,96,2,0)
						line(32,31,96,31,0)
						line(32,2,32,31,0)
						line(96,2,96,31,0)
      spr(26,55,6)
      ?"x"..fruit_count,64,9,14
      draw_time(49,16)
      ?"deaths:"..deaths,48,24,14
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
11,platform
12,platform
18,spring
22,crystal
23,fall_floor
26,fruit
28,doublecrystal
45,fly_fruit
86,message
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
    ?"🅾️/❎",55,72,10
    ?"levels by sheebeehs",27,85,2
    ?"maddy thorson",40,93,14
    ?"noel berry",46,101,7

		-- color 10 to color 130
    pal(10,130,1)
    -- particles
  		foreach(particles,draw_particle)

    return
  end

  -- draw bg color
  cls(flash_bg and frames/5 or bg_col and 0 or 0) -- bg color

  -- bg clouds effect
  foreach(clouds,function(c)
    c.x+=c.spd-cam_spdx
    fillp(▒)
    rectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col and 10 or 0) -- cloud color
    fillp()
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

		-- color 14 to color 134
	pal(10,130,1)

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
          [59]=x2%8>=6 and xspd>=0,
          [71]=y2%8>=6 and yspd>=0,
          [72]=y1%8<=2 and yspd<=0,
          [87]=x2%8>=6 and xspd>=0,
          [104]=x1%8<=2 and xspd<=0,})[tile_at(i,j)] then
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
 "0,0,2,1,cAVERN",
 "2,0,1,1,200M",
 "4,0,1,1,300M",
 "6,0,2,1,iCY gROTTO",
 "3,0,1,1,500M",
 "5,0,1,1,600M",
 "0,1,2,1,sUMMIT",
 
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
--	[10]=30
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
0000000000000000000000000888888000000000000000000000000000000000aee22eea5aaaaaa55aaaaaaa0007707770077700aaaaaaa50000444444440000
0000000008888880088888808888888808888880088888000000000008888880ae222eeaaaeeeeaaaaeeeeee0777777677777770eeeeeeaa0000499999940000
000000008888888888888888888ffff888888888888888800888888088f1ff18ae2222eaaeeeeeeaaeeee22e7766666667767777ee22eeea0004555559494000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8aee222eaaee22eeaaee22222767776667666667722222eea0004911199494000
0000000088f1ff1888f1ff1844fffff088f1ff1881ff1f80888ffff888fffff8aee22eeaae222eeaaee22222077666676666776022222eea0049111994999400
0000000044fffff044fffff06422220044fffff00fffff4488fffff844222280aeeeeeeaae2222eaaeee22ee0000000000000000e22eeeea0499111945555540
00000000642222006422220007000070672222000022227608f1ff1064222200aaeeeeaaaee222eaaaeeeeee0000000000000000eeeeeeaa0491119949111940
00000000007007000070007000000000000007000000700067722270007007005aaaaaa5aee22eea5aaaaaaa0000000000000000aaaaaaa54999999499111994
55555555000000000000000000000000222222226666666600077000effffffeeffffffeefff0ffe000000006665666500077000000000000000000070000000
55555555000000000000000000000000222222226666666600711700f555555ff555e55ff55e0f5f0003003067656765007aa700007700000770070007000007
55000055000000000000000000000000222222226666666607113170f555555ff555f55fefe00e5f00bb3b0067706770074a4a70007770700777000000000000
55000055007000700d6666d000000000222222226666666671313337f555555ffefe0e5f000000ee0223b3300700070000744700077777700770000000000000
5500005500700070005005000000000022222222666666667333b3b7f555555ff55e0feffe000000022883000700070007477970077777700000700000000000
55000055067706770005500000000000222222226666666607b3bb70f555555ff555f55ff5e00eff88d88b000000000000799700077777700000077000000000
555555555676567600500500000000002222222266666666007bb700f555555ff55e555ff5e0e55f882200000000000000077000070777000007077007000070
5555555556665666000550000d6666d0222222226666666600077000effffffeeffffffeee00effe022000000000000000000000000000007000000000000000
aee222225aaaaaaaaaaaaaaaaaaaaaa5676666665666666666666666666666655555555555555555555555555500000000000000000000000000000000000000
aeee2222aaeeeeeeeeeeeeeeeeeeeeaa677666666677777777777777777777665555555555555550055555556670000000000000000777770000000000000000
aeee2222aeeeeeeeeeeeeeeeeeeeeeea67766666677766666777777666667776555555555555550000555555677770000000b000007766700000000000000000
aeeee222aeeeeee22eeeeee22eeeeeea67776666677666666667766666666776555555555555500000055555666000000000b00b076777000000000000000000
aeeee222aeeee222222ee222222eeeea6777666667666666666666666666667655555555555500000000555555000000b0003003077660000777770000000000
aeee2222aeee2222222222222222eeea6776666667667766666666666667667655555555555000000000055566700000030300b0077770000777767007700000
aeee2222aeee2222222222222222eeea6776666667667766666666666666667655555555550000000000005567777000030b0030070000000700007707777770
aee22222aee222222222222222222eea676666666766666666666666666666765555555550000000000000056660000003033030000000000000000000077777
22222eeaaee222222222222222222eea666666766766666666666666666666765555555550000000000000050000066600000000000000000088088000000000
2222eeeaaeee2222222222222222eeea666667766766666666666666666666765055555555000000000000550007777600300000000000000088888000000000
2222eeeaaeee2222222222222222eeea666667766766766666666666677666765555005555500000000005550000076600b00003000000000008980000000030
222eeeeaaeeee222222ee222222eeeea66667776676666666666666667766676555500555555000000005555000000550003000b0000000000888880000000b0
222eeeeaaeeeeee22eeeeee22eeeeeea6666777667766666666776666666677655555555555550000005555500000666000b00b30000b0000088388000000b30
2222eeeaaeeeeeeeeeeeeeeeeeeeeeea6666677667776666677777766666777655055555555555000055555500077776300b00b0000b00000000b00003000b00
2222eeeaaaeeeeeeeeeeeeeeeeeeeeaa66666776667777777777777777777766555555555555555005555555000007660b030b30030b0030000b000000b0b300
22222eea5aaaaaaaaaaaaaaaaaaaaaa566666676566666666666666666666665555555555555555555555555000000550303033003033030000b000000303300
22222222666666660777777777777777777777700777777000000000555555556665666500000000000000000000000000000000000000000000000000000000
2ee22222666667767111177711117771111177777111777700000000555555556765676500000000000000000000000000000000000000000000000000000000
2ee22e226666677671cc777cccc777ccccc7771771c7771700000000555555556775677500000000000000000000000000000000000000000000000000000000
222222226666666671c777cccc777ccccc777c1771777c1700000000557555755755575500000000000000000000776000000000000000000000000000000000
2222222266676666717771111777111117771117777711170005dddd557555755755575500000000000000000077776760077000000000000000000000000000
22e222226666667677771111777111117771111777711117005ddddd567756775555555500000000000000000667766667777600000000000000000000000000
222222e2676666667111111111111111111c111771111c1700dddddd567656765555555500000000000000007776666666776666000000000000000000000000
22222222666666667111111111111111111111177111111700d5555556665666555555550000000000000017666eee1e66666666760000000000000000000000
67766776566666657111111111111111111111177111111700000000555556660000000000000000076001eeeeeeee1eee666e67666000077000000000000000
67666776667777667111111c111111111111111771cc11174999999955577776101111010000000076661eeeeeeee1eeeee1eeee666607776600000000000000
676666766777777671111111111cc1111111111771cc111749aa99a9555557661171711100000007766761e2e2e2e1eeeee1eeeeeee677766660000000000000
677666766776677671c11111111cc11111111c1771111c1749999999555555551199111100000176666eee1e2e2e1e2e2eee1e2e2eee666666e1000007700000
67766776676667767111111111111111111111177111111749a9aaa9555556660177711000001eeeee12e2222221e1e2e2e2e1e2e2e2eee1eeee100077660000
677777766766667671111111111111111111111771c1111749999999555777760177711000112e2e212e222222122122222e2e12222e2e1e2e2e210776666100
667777666776667671111111c11111111111111771111117000490005555576601777110012222e212122222112222122222221222222212e2222e6666662e10
56666665677667767111111111111111111111177111c1170004900055555555099d99111aa2a22122212222222222122222222222222122222222e2e2e1a221
56666666666666657111111111111111111111177111111700777700555555555555555501aa2a212a2a1a22222222122222222222221a2a2a2a222a2a212aa1
6677777777777766711111111111111111111117711c11170700007055111155667555550011aa12a2a212a2a2a2a221222222a2a2a212aaa2a2a2a2a21aaa10
6777766777667776711111111111c1111111111771111117707700075117171567777555000011aaaaaaa1aa2a2a2a212a2a2a2a2a21aaa11aaa2a2aa1a11100
67766666666667767111111cc1111111111111177111cc177077bb075111991566655555000000111111111aaaaaa2a2a2a2a2aaaaaa11100111aaa111100000
67766666666667767111111cc1111111111c11177111cc17700bbb071117771155555555000000000000000111111aaaaaaaaa11111100000000111000000000
677766777667777671c11111111111111111111771c11117700bbb07111777116675555500000000000000000000011111111100000000000000000000000000
66777777777777667111111111111111111111177111111707000070511777156777755500000000000000000000000000000000000000000000000000000000
566666666666666507777777777777777777777007777770007777001199d9956665555500000000000000000000000000000000000000000000000000000000
ae2222eaaaaaaaaa07777777777777777777777007777770040000000400000004003bb0000000001eeeee001ee0000001eeee001ee01ee001eeee0000000000
aee222eaeeeeeeee7111777111117771111177777111777704bb300004b0000004bb3bb3000000001eeeeee01ee000001eeeeee01eee1ee01eeeeee000000000
aee222eaeeeeeeee71c777ccccc777ccccc7771771c7771704bb3bb304bb000004bb3000000000001ee11ee01ee000001ee11ee01eeeeee01ee11ee000000000
ae222eeae2eeee2271777ccccc777ccccc777c1771777c1704003bb004bb3bb30400000000000000122222101220000012222220122222201220111000000000
ae222eea22eeee2e7777111117771111177711177777111742000000420b3b004200000000000000122112201220012012211220122122201220122000000000
aee22eeaeeeeeeee77711111777111117771111777711c1740000000400000004000000000000000122222201222222012201220122012201222222000000000
aee22eeaeeeeeeee7111111111111111111111177111111740000000400000004000000000000000122222101222222012201220122012201122221000000000
ae2222eaaaaaaaaa0777777777777777777777700777777040000000400000004000000000000000111111001111111011101110111011100111110000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000776000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077776760077000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000667766667777600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000007776666666776666000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000017666eee1e66666666760000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000076001eeeeeeee1eee666e67666000077000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000076661eeeeeeee1eeeee1eeee666607776600000000000000000000000000000000000000000000000000
00600070000000000000000000000000000000000007766761e2e2e2e1eeeee1eeeeeee677766660000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000176666eee1e2e2e1e2e2eee1e2e2eee666666e1000007700000000000000000000000000000000000000000
00000000000000000000000000000000000000001eeeee12e2222221e1e2e2e2e1e2e2e2eee1eeee100077660000000000000000000000000000000000000000
00000000000000000000000000000000000000112e2e212e222222122122222e2e12222e2e1e2e2e210776666100000000000000000000000000000000000000
000000000000000000000000000000000000012222e212122222112222122222221222222212e2222e6666662e10000000000000000000000000000000000000
0000000000000000000000000000000000001ii2i22122212222222222122222222222222122222222e2e2e1i221000000000000000000000000000000000000
00600000000000000000000000000000000001ii2i212i2i1i22222222122222222222221i2i2i2i222i2i212ii1000000000000000000000000000000000000
0000000000000000000000000000000000000011ii12i2i212i2i2i2i221222222i2i2i212iii2i2i2i2i21iii10000000000000000000000000000000000000
000000000000000000000000000000000000000011iiiiiii1ii2i2i2i212i2i2i2i2i21iii11iii2i2ii1i11100000000000000000000000000000000000000
000000000000000000000000000000000000000000111111111iiiiii2i2i2i2i2iiiiii11100111iii111100000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000111111iiiiiiiii11111100000000111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000
000000000000000000000000000000000000000000001eeeee001ee0000001eeee001ee01ee001eeee0000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001eeeeee01ee000001eeeeee01eee1ee01eeeeee000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001ee11ee01ee000001ee11ee01eeeeee01ee11ee000000770000000000000000000000000000000000000
00000000000000000000000000000000000000000000122222101220000012222260122222201220111000000770000000000000000000000000000000000000
00000000000000000000000000000000000000000000122112201220012012211220122122201220122000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000122222201222222012201220122012201222222000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000122222101222222012201220122012201122221000000000000000070000000000000000000000000000
00000000000000000000000000000000000000000000111111001111111011101110111011100111110000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000iiiii0000i00iiiii0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000ii000ii00i00ii0i0ii000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000ii0i0ii00i00iii0iii000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000ii000ii00i00ii0i0ii000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000iiiii00i0000iiiii0000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770006000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000020002220202022202000022000002220202000000220202022202220222022202220202002200000000000000000000000000
00000000000000000000000000020002000202020002000200000002020202000002000202020002000202020002000202020000000000000000000000000000
00000000000000000000000000020002200202022002000222000002200222000002220222022002200220022002200222022200000000000000000000000000
00000000000000000000000000020002000222020002000002000002020002000000020202020002000266020002000202000200000000000000000000000000
00000000000000000000000000022202220020022202220220000002220222000002200202022202220266022202220202022000000000000000000000000000
00000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eee0eee0ee00ee00e0e00000eee0e0e00ee0eee00ee00ee0ee00000000000000000000000000000000000000
0000000000000000000000000000000000000000eee0e0e0e0e0e0e0e0e000000e00e0e0e0e0e0e0e000e0e0e0e0000000000000000000000000000000000000
0000000000000000000000000000000000000000e0e0eee0e0e0e0e0eee000000e00eee0e0e0ee00eee0e0e0e0e0000000000000000000000000000000000000
0000000000000000000000000000000000000000e0e0e0e0e0e0e0e000e000000e00e0e0e0e0e0e000e0e0e0e0e0000000000000000000000000000000000000
0000000000000000000000000000000000000000e0e0e0e0e7e0eee0eee000000e00e0e0ee00e0e0ee00ee00e0e0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007700077077707000000077707770777077707070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007070707070007000000070707000707070707070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007070707077007000000077007700770077007770000000000000000000000007000000000000000000
00000000000000000000000000000000000000000000007070707070007000000070707000707070700070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007070770077707770000077707770707070707770000000000000000000000000000000000000000000
00000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

__gff__
0000000000000000030303000003040404020000030300000000000200000000030303030303030304040402020000000303030303030303040404020202020203031313131302020200020000020202030313131313020204000200000202020303131313130404020202020202020203001313131300000000000002020200
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
535364311430351515411537204030525353636470682838293b3132144014321414332b2a28382828293b35361541155353535420144014302441376828282814401433525364351541153720302828281028283862535363636424411515151541153752535354204014302441151515375254204014336810573536154115
5354212331320d24411534211432336263641b21332b2a2800001b3b3132332540301b0000002a281000002a48353615635353643114143233353768281028293232337263641b1b2415370a323338103828282828576264212348353615413615363772535353542014323335363641344253543132331b2a38281b1b353636
63643114222223241536373133090a0d38293b081b000029000000001b2526151430111100000047473900003821233523626448483133484828282829002a0026271b1b1b1b003b353721231b2a28282829003829001b1b2033103829353721372122235253536420334848724344353752535343441b0000282900001b1b21
22222331323233353728480a22302b2a1000001b00000000000000003b244115323342441111112122232b002a3114221423482900001b002a2838280000000041372b00000000001b2140302b00002a2800002a0000003b081b2a28001b21142214403062636409081b2a385752641b1b62636363642b00002a000000003b20
403233210d2a48382829001b20332b00290000000000000000000000003536362627525343440a3232332b00001b204040302b1a000011000000002a0000000034480000001100003b2014332b00000029000000000000001b000029003b314040143233481b0a301b0000293b651b0000484821220d2b000000000000003b20
33480a301b00002a1000003b081b0000000000000000000000000000001b21224134626353542b1b1b1b0000003b2032143309112122230000000000000000003768393a3909113a5731331b00000000000000000000000000000000003a38201433484829001b082b000000001b0000002a5731301b00000000000000003b20
38291b702b000000290000001b000000000000000000000000001100003b3114361527096264683911111100163b0821332140221432332b0000000000000000232810382820232838291b000000003a00000000000000003a390000001c2a31336829000000001b00000000000000000000001b082b00000000000000001131
100000082b000000000000000000000000000000000000000000092b003b0931443537202310283821220d11111121142731323233452b00111111000000003a3029002a282030290000111111001c280000000000003a103847111111001142442b0000000000000000000000000000000000001b00000000000000113b4243
2900001b00000000000000000000000000000000000000390011702b1a3b312253441b3130292a2831334243434420401526611b42541111212223000000002833111200003133111111212223393a10000000000000002a5721222223114253542b000000000000000000000000000000000000000000000000003b09115253
000000000000000000001100000000000000110000003a10570a30111111453153642b3b082b00291b3b62535354201441341b3b625343443114332b00003a3843434411001b2122230a40143328382800000000000000003b314014320d5253542b00000000000000000000000000000000000000000000391c0011200d5253
0000000000000000000009110000000000000911000047212309310d42435343541b00001b00000000003b626364311415372b001b52536374082b00000028285353637439003132320d31332a2810283900000000110000003b31332b1b52536411000000003a000000000000000000110000000000003a2800110a33096253
110e0f0156003a00001120232b00003a001120232b112114332023425353535354390000000000000000001b25262731341b00393b62642123103900003b510a636438290000001b3b2527001a002a47280000000009110000001b1b003b526326272b00000010000011000000000011092b0000000000103857424344202362
22222325274738393b0a14332b111147390a143325272030211430626353536364380000001c0000000000113541152637393a10001b2114332838111111242629000000000000001124340000111142383900001120232b00391a00003b652515412700013a383911092b000000002130110011111111252627525354201423
4032332415272122222308424343442122230825153431332014332123626421222339013a00000000003b212335151522233829003b313048292a2123251541000100003a00003b25413411114243532728013b214033393a3800111111251515153421234244470a30110000003a31320d1121222325154134525364314014
33252615413420401433425353536431324023244115262731332140302122141440220d6839000000001120142324414030280100003a08680000203035411522220d0010390011353637212362535341262661313345474747112122232441413637203062534344310d111111424343440a14403035411537626421233132
25154115153420143042535353542122232030241541153421224014302014404014304838281039003b211440302415144022232b00382828393b204023241540302b3a38283b424344211440235253154134424343534344212214403024153421224014235253542122222223525353534420141423243421222214402222
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000003a007600390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000067394244475800000039000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003a42435364212311113a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000003a0000115162636421403025262738390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000383911251526272114323335154127280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003a474244354115343133424344241537212311110000003900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
39000000000001104253534435154127425353543537214014232527113a2800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
381039003b424343535353534424153452535353442114144030244127683839000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

