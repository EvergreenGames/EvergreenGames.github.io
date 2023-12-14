pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--mademaker 1.7
--made by antibrain

--mouse control required!!

--~evercore~
--a celeste classic mod base
--v2.1.0

--original game by:
--maddy thorson + noel berry

--major project contributions by
--taco360, meep, gonengazit, and akliant

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
--mod vals
_pal=pal
cangrab=true
grabtile=true
ms=0
gx,gy,gw,gh=0,0,0,0
-- [entry point]

function _init()
  poke(0x5f2d, 0x1)
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
    this.grab=false --dont grab player!!
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
    update_hair(this)
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

function update_hair(obj)
  local last=vector(obj.x+4-(obj.flip.x and-2 or 3),obj.y+(btn(⬇️) and 4 or 2.9))
  for h in all(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    last=h
  end
end

function draw_hair(obj)
  for i,h in pairs(obj.hair) do
    circfill(round(h.x),round(h.y),mid(4-i,1,2),8)
  end
end

-- [other objects]

player_spawn={
  layer=2,
  init=function(this)
    sfx"4"
    this.grab=false
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
  draw=function(this)
    if this.spr==22 then
      for i=7,13 do
        pset(this.x+4+sin(this.offset*2+i/10),this.y+i,6)
      end
      draw_obj_sprite(this)
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
    this.grab=false
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
    this.grab=false
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
    ?"0x9982",this.x-7.5,this.y-4,7+this.flash%2
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
    else
     this.start=this.x
    end
  end
}

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
    this.text="-- celeste mountain --#this memorial to those#perished on the climb"
    this.hitbox.x+=4
  end,
  draw=function(this)
    if this.player_here() then
      for i,s in ipairs(split(this.text,"#")) do
        camera()
        rectfill(7,7*i,120,7*i+6,7)
        ?s,64-#s*2,7*i+1,0
        camera(draw_x,draw_y)
      end
    end
  end
}

big_chest={
  init=function(this)
    this.state=max_djump>1 and 2 or 0
    this.hitbox.w=16
  end,
  update=function(this)
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
    elseif this.state==1 then
      this.timer-=1
      flash_bg=true
      if this.timer<=45 and #this.particles<50 then
        add(this.particles,{
          x=1+rnd"14",
          y=0,
          h=32+rnd"32",
        spd=8+rnd"8"})
      end
      if this.timer<0 then
        this.state=2
        this.particles={}
        flash_bg,bg_col,cloud_col=false,2,14
        init_object(orb,this.x+4,this.y+4,102)
        pause_player=false
      end
    end
  end,
  draw=function(this)
    if this.state==0 then
      draw_obj_sprite(this)
      spr(96,this.x+8,this.y,1,1,true)
    elseif this.state==1 then
      foreach(this.particles,function(p)
        p.y+=p.spd
        line(this.x+p.x,this.y+8-p.y,this.x+p.x,min(this.y+8-p.y+p.h,this.y+8),7)
      end)
    end
    spr(112,this.x,this.y+8)
    spr(112,this.x+8,this.y+8,1,1,true)
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
      spr(26,55,6)
      ?"x"..fruit_count,64,9,7
      draw_time(49,16)
      ?"deaths:"..deaths,48,24,7
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
11,platform
12,platform
18,spring
20,chest
22,balloon
23,fall_floor
26,fruit
45,fly_fruit
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
  if cangrab==false then
   mb=0
  end
end

function kill_player(obj)
  mb=0
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
  mb=0
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
 if not(is_title()) then
  menuitem(1,"reset level",function() reload() load_level(lvl_id or 0)end)
 end
  mx=stat(32)
  my=stat(33)
  mb=stat(34)
  for x=0,mx,8 do
   mxs=x
  end
  for y=0,my,8 do
   mys=y
  end
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
  
  
  --grab objs
  foreach(objects,function(o)
  if o.grab!=false and grabtile==true then --check if can grab
   if mb==1 then --if mousedown
    if (mx>o.x and --check if mouse collides with obj o
    my>o.y and
    mx<o.x+o.hitbox.w and
    my<o.y+o.hitbox.h) or o.grabbed==true then
    if cangrab==true or o.grabbed==true then --if no other objs are grabbed
     o.x=mx-o.hitbox.w/2 --move obj to mouse pos
     o.y=my-o.hitbox.h/2
     o.grabbed=true
     gx=o.x
     gy=o.y
     gw=o.hitbox.w
     gh=o.hitbox.h
    end
    for i in all(objects) do --for all objs check if
     if i.grabbed==true then --and obj is grabbed
      cangrab=false --if true then dont let more objs be grabbed
     end
    end
   else
    o.grabbed=false --if nothing is grabbed, set obj.grabbed to false.
   end
   end
end if mb==0 then o.grabbed=false end  end)
if mb==0 then
 cangrab=true --if mouse up, allow for grabbing
end
--grab map tiles
if cangrab==true and mb==1 and fget(mget((mx/8)+lvl_x,(my/8)+lvl_y),7)==false then
 if grabtile!=false then --if grabtile isnt false
  ms=mget((flr(mx)/8)+lvl_x,(flr(my)/8)+lvl_y) --set ms to clicked tile
  mset((flr(mx)/8)+lvl_x,(flr(my)/8)+lvl_y,0) --del clicked tile
    
  grabtile=false --dont let more tiles be grabbed
 end
elseif mb==0 and grabtile==false then --if mouseup then
 mset((flr(mx)/8)+lvl_x,(flr(my)/8)+lvl_y,ms) --set tile at mousepos to tile ms
 grabtile=true --allow for grabbing another tile
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
    cangrab=false
    grabtile=true
    if start_game then
    	for i=1,15 do
        pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
    	end
    end

    cls()

    -- credits
    sspr(unpack(split"72,32,56,32,36,32"))
    ?"🅾️/❎",55,80,5
    ?"maddy thorson",40,96,5
    ?"noel berry",46,102,5
    ?"mod made by antibrain",24,108,5
    --lazy title screen
    ?"\^w\^tmademaker",29,44,7
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

  for i=0,15 do pal(i,1) end --set all pal colors to col 1
    for tx=-1,1 do for ty=-1,1 do if tx==0 or ty==0 then
     map(lvl_x,lvl_y,tx,ty,lvl_w,lvl_h,4) --outline bg tiles
    end end end
  pal=_pal --reset pal to pal()
  camera(draw_x,draw_y) --draw cam
  pal() --reset pal
  map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4) --draw map
  for i=0,15 do pal(i,1) end --set all pal cols to 1 again
  for tx=-1,1 do for ty=-1,1 do if tx==0 or ty==0 then
   map(lvl_x,lvl_y,tx,ty,lvl_w,lvl_h,2) --outline other tiles
  end end end
  pal=stat --set pal to stat for some reason
  foreach(objects,function(o)
      for dx=-1,1 do for dy=-1,1 do if dx==0 or dy==0 then
        camera(draw_x+dx,draw_y+dy) draw_object(o) --outline all objs
      end end
    end
  end)
  pal=_pal --restora pal
  camera(draw_x,draw_y) --draw cam
  pal() --reset pal colors
  
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
  if grabtile==false then --if cant grab tile (tile is grabbed)
   spr(ms,mxs,mys) --draw grabbed tile at mouse pos
   rect(mxs-1,mys-1,mxs+8,mys+8,((((t()*10)%15)+1)))
  end 
  if cangrab==false then
   rect((gx-1),(gy-1),(gx+gw),(gy+gh),((((t()*10)%15)+1)))
  end
  spr(13,(mx-1),(my-1)+ceil(mb/4)) --draw mouse (and move it down a px if mousedown!!)
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

  "0,0,1,1", 
  "1,0,1,1", 
  "2,0,1,1", 
  "3,0,1,1", 
  "4,0,1,1", 
  "5,0,1,1", 
  "6,0,1,1", 
  "7,0,1,1", 
  
  "0,1,1,1", 
  "1,1,1,1",
  "2,1,1,1",
  "3,1,1,1",
  "4,1,1,1",
  "5,1,1,1",
  "6,1,1,1",
  "7,1,1,1",

  "0,2,1,1",
  "1,2,1,1",
  "2,2,1,1",
  "3,2,1,1",
  "4,2,1,1",
  "5,2,1,1",
  "6,2,1,1",
  "7,2,1,1",
  
  "0,3,1,1",
  "1,3,1,1",
  "2,3,1,1",
  "3,3,1,1",
  "4,3,1,1",
  "5,3,1,1",
  "6,3,1,1",
  "7,3,1,1,summit",
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
	[-1]="00000000000000000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000010000039000000000000000000003a00280000380000000000000000000028672800001000390000000000000000283828760028672800000000000000002a28282123283829000000000000006838282125252328393a0000000000002a28212548252523283868000058586828292425252525261028286800281028380031322525482629002a2800002a28393f2123242532332000002800000021222225263133212223283928670100312525482522222525252310382821222324252525252525482525222223"
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
	
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
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700010000000000000000000000
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000777777677777770171000000000000000000000
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a0007766666667767777177100000000000000000000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0007677766676666677177710000000000000000000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000000000000000000177771000000000000000000
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000000000000000000177110000000000000000000
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a0000000000000000000011710000000000000000000
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0000000000000000000000000000000000000000000
555555550000000000000000000000000000000000000000008888000999999009999990099909900300b0b06665666500000000000000000000000070000000
55555555000000000000000000000000000000000000000008888880911111199111411991140919003b33006765676500000000007700000770070007000007
550000550000000000000000000000000aaaaaa00000000008788880911111199111911949400419028888206770677000000000007770700777000000000000
55000055007000700499994000000000a998888a0000000008888880911111199494041900000044089888800700070000000000077777700770000000000000
55000055007000700050050000000000a988888a0000000008888880911111199114094994000000088889800700070000000000077777700000700000000000
55000055067706770005500000000000aaaaaaaa0000000008888880911111199111911991400499088988800000000000000000077777700000077000000000
55555555567656760050050000000000a980088a0000000000888800911111199114111991404119028888200000000000000000070777000007077007000070
55555555566656660005500004999940a988888a0000000000000000099999900999999004004990002882000000000000000000000000007000000000000000
0777777007777777777777777777777077cccccccccccccccccccc77077777705555555555555555555555555500000007777770000000000000000000000000
77777777777777777777777777777777777cccccccccccccccccc777777777775555555555555550055555556670000077777777000777770000000000000000
777c77777777ccccc777777ccccc7777777cccccccccccccccccc777777777775555555555555500005555556777700077777777007766700000000000000000
77cccc77777cccccccc77cccccccc7777777cccccccccccccccc7777777cc7775555555555555000000555556660000077773377076777000000000000000000
77cccc7777cccccccccccccccccccc777777cccccccccccccccc777777cccc775555555555550000000055555500000077773377077660000777770000000000
777cc77777cc77ccccccccccccc7cc77777cccccccccccccccccc77777cccc775555555555500000000005556670000073773337077770000777767007700000
7777777777cc77cccccccccccccccc77777cccccccccccccccccc77777c7cc77555555555500000000000055677770007333bb37070000000700007707777770
0777777077cccccccccccccccccccc7777cccccccccccccccccccc7777cccc77555555555000000000000005666000000333bb30000000000000000000077777
77cccc7777cccccccccccccccccccc77077777777777777777777770777ccc775555555550000000000000050000066603333330000000000000000000000000
777ccc7777cccccccccccccccccccc77777777777777777777777777777cc7775055555555000000000000550007777603b333300000000000ee0ee000000000
777ccc7777cc7cccccccccccc77ccc777777ccc7777777777ccc7777777cc77755550055555000000000055500000766033333300000000000eeeee000000030
77ccc77777ccccccccccccccc77ccc77777ccccc7c7777ccccccc77777ccc777555500555555000000005555000000550333b33000000000000e8e00000000b0
77ccc777777cccccccc77cccccccc777777ccccccc7777c7ccccc77777cccc7755555555555550000005555500000666003333000000b00000eeeee000000b30
777cc7777777ccccc777777ccccc77777777ccc7777777777ccc777777cccc775505555555555500005555550007777600044000000b000000ee3ee003000b00
777cc777777777777777777777777777777777777777777777777777777cc7775555555555555550055555550000076600044000030b00300000b00000b0b300
77cccc77077777777777777777777770077777777777777777777770077777705555555555555555555555550000005500999900030330300000b00000303300
0777700700000000077777777777777777777770077777700000000000000000cccccccc00000000000000000000000000000000000000000000000000000000
7777777700000000700007770000777000007777700077770000000000000000c77ccccc00000000000000000000000000000000000000000000000000000000
7777cc770000000070cc777cccc777ccccc7770770c777070000000000000000c77cc7cc00000000000000000000000000000000000000000000000000000000
777ccccc0000000070c777cccc777ccccc777c0770777c070000000000000000cccccccc00000000000000000000000000006000000000000000000000000000
77cccccc00000000707770000777000007770007777700070002eeeeeeee2000cccccccc00000000000000000000000000060600000000000000000000000000
07cc77cc0000000077770000777000007770000777700007002eeeeeeeeee200cc7ccccc00000000000000000000000000d00060000000000000000000000000
077c77cc000000007000000000000000000c000770000c0700eeeeeeeeeeee00ccccc7cc0000000000000000000000000d00000c000000000000000000000000
777ccccc000000007000000000000000000000077000000700e22222e2e22e00cccccccc000000000000000000000000d000000c000000000000000000000000
777ccccc000000007000000000000000000000077000000700eeeeeeeeeeee000000000000000000000000000000000c0000000c000600000000000000000000
077ccccc000000007000000c000000000000000770cc000700e22e2222e22e00000000000000000000000000000000d000000000c060d0000000000000000000
07cc7ccc0000000070000000000cc0000000000770cc000700eeeeeeeeeeee0000000000000000000000000000000c00000000000d000d000000000000000000
77cccccc0000000070c00000000cc00000000c0770000c0700eee222e22eee0000000000000000000000000000000c0000000000000000000000000000000000
777ccccc000000007000000000000000000000077000000700eeeeeeeeeeee005555555500000000000000000000c00000000000000000000000000000000000
7777cc770000000070000000000000000000000770c0000700eeeeeeeeeeee00555555550000000000000000000c000000000000000000000000000000000000
777777770000000070000000c0000000000000077000000700ee77eee7777e005555555500000000000000000000000000000000000000000000000000000000
07777077000000007000000000000000000000077000c00707777777777777705555555500000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000077000000700777700500000000000000500000000000000000000000000000000000000000000000000000000
00aaaaaa00000000700000000000000000000007700c000707000070550000000000005500000000000000000000000000000000000000000000000000000000
0a99999900000000700000000000c000000000077000000770770007555000000000055500000000000000000000000000000000000000000000000000000000
a99aaaaa000000007000000cc0000000000000077000cc077077bb07555500000000555500000000000000000000000000000000000000000000000000000000
a9aaaaaa000000007000000cc0000000000c00077000cc07700bbb0755555555555555550000000000000c000000000000000000000000000000c00000000000
a99999990000000070c00000000000000000000770c00007700bbb075555555555555555000000000000c00000000000000000000000000000000c0000000000
a999999900000000700000000000000000000007700000070700007055555555555555550000000000cc0000000000000000000000000000000000c000000000
a99999990000000007777777777777777777777007777770007777005555555555555555000000000c000000000000000000000000000000000000c000000000
aaaaaaaa0000000007777777777777777777777007777770004bbb00004b000000400bbb00000000c0000000000000000000000000000000000000c000000000
a49494a10000000070007770000077700000777770007777004bbbbb004bb000004bbbbb0000000100000000000000000000000000000000000000c00c000000
a494a4a10000000070c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb00000000c0000000000000000000000000000000000000001010c00000
a49444aa0000000070777ccccc777ccccc777c0770777c07040000000400bbb004000000000001000000000000000000000000000000000000000001000c0000
a49999aa000000007777000007770000077700077777000704000000040000000400000000000100000000000000000000000000000000000000000000010000
a49444990000000077700000777000007770000777700c0742000000420000004200000000000100000000000000000000000000000000000000000000001000
a494a444000000007000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
a4949999000000000777777777777777777777700777777040000000400000004000000000010000000000000000000000000000000000000000000000000010
00000000000000008242525252528452339200001323232352232323232352230000000000000000b302000013232352526200a2828342525223232323232323
00000000000000a20182920013232352363636462535353545550000005525355284525262b20000000000004252525262828282425284525252845252525252
00000000000085868242845252525252b1006100b1b1b1b103b1b1b1b1b103b100000000000000111102000000a282425233000000a213233300009200008392
000000000000110000a2000000a28213000000002636363646550000005525355252528462b2a300000000004252845262828382132323232323232352528452
000000000000a201821323525284525200000000000000007300000000007300000000000000b343536300410000011362b2000000000000000000000000a200
0000000000b302b2001100000000a282000000000000000000560000005526365252522333b28292001111024252525262019200829200000000a28213525252
0000000000000000a2828242525252840000000000000000b10000000000b1000000000000000000b3435363930000b162273737373737373737374711000000
000000110000b100b302b2000000008200000000000000000000000000560000525233a282828201a31222225252525262820000a20011111100008283425252
0000000000000093a382824252525252000000000011000000000011000000001100000000000000000000020182001152222222222222222222222232b20000
0000b302b200000000b10000000000a2000000000000000093000000000000008462b200a28382828213232352845252629200000011243444b200a282425284
00000000000000a2828382428452525200000000b302b2936100b302b20000007293a3000000000000000000a282931252845252525252232323232362b20000
000000b10000001100000000000000000000000093000086820000a3000000005262b20000a292a28282920013232323621111111124353545b200b312525252
00000000000000008282821323232323820000a300b1a382930000b100000000738283931100000000000000a382821323232323528462829200a20173b20000
000000000000b302b2000000000000000000a3858282868282828282930000005262b2000000000000a2000000000000522222223226363646b200b342525252
00000011111111a3828201b1b1b1b1b182938282930082820000000000000000b100a2827211000000000000828283b122222232132333610000869200000000
00100000000000b1000000000000000086938282828201920000a20182a376865262b200000000000000000000000000525284525232b2b1b10000b342845252
00008612222232828382829300000000828282828283829200000000000000001100a3827372000000000000a2829211525284628382a2000000a20000000000
00021111111111111111111111110000828282a28382820000000000828282825262b200000000000000000000000000525252525262b200000000b342525252
00000113235252225353536300000000828300a282828201939300001100000072828292b10393000000000000a282125223526292000000000000a300000000
0043535353535353535353535363b2008282920082829200061600a3828382a28462b200000000000000000000000000528452525262b2000011111142525252
0000a28282132362b1b1b1b1000000009200000000a28282828293b372b2000073820100110382a3000000000082821362101333610000000000008293000000
0002828382828202828282828272b20083820000a282d3000717f382829200005262b200000000009300000000000000525252528462b200b312223213528452
000000828392b30300000000000000000000000000000082828282b303b20000b1a282837203820193000000a38292b162710000000000009300008382000000
00b1a282820182b1a28283a28273b200828293000082122232122232820000a32333b200000000008292000000000000232323232333b200b342525232135252
000000a28200b37300000000a30000000010000000111111118283b373b200a30000828273039200828300008283001162930000000000008200008282920000
0000009200a28200008200008282000001920000000213233342846282243434000000000000000082000085860000008382829200000000b342528452321323
0000100082000082000000a2829300002222321111125353630182829200008300009200b1030000a28200008282001262829200000000a38292008282000000
00858600008282a3828293008292000082001000001222222252525232253535000000f3100000a3820000a2010000008292000000009300b342525252522222
0400122232b20083930000a383829300528452222262c000a28282820000a38210000000a3738000008293008292001362820000000000828300a38201000000
00a282828292a2828283828282000000343434344442528452525252622535350000001263000083829300008200d2008210d3e300a38200b342525252845252
1232425262b286828293a3820182820052525252846200000082829200008282320000008382930000a28201820000b162839300000000828200828282930000
0000008382000000a28201820000000035353535454252525252528462253535000000032444008282820000829300002222223201828393b342525252525252
525252525262b2b1b1b1132323526200845223232323232352522323233382825252525252525252525284522333b2822323232323526282820000b342525252
52845252525252848452525262838242528452522333828292425223232352520000000000000000000000000000000000000000000000000000000000000000
525252845262b2000000b1b1b142620023338276000000824233b200a2018283525252845252232323235262b1b10083921000a382426283920000b342232323
2323232323232323232323526201821352522333b1b1018241133383828242840000000000000000000000000000000000000000000000000000000000000000
525252525262b20000000000a242627682828392000011a273b20000b3729200525252525233b1b1b1b11333000000825353536382426282410000b30382a2a2
a1829200a2828382820182426200a2835262b1b10000831232b2000080014252000000000000a300000000000000000000000000000000000000000000000000
528452232333b20000001111114262928201a20000b372b200000000b30300002323525262b200000000b3720000a382828283828242522232b200b373928000
000100110092a2829211a2133300a3825262b2000000a21333b20000868242520000000000000100009300000000000000000000000000000000000000000000
525262122232b200a3767212324262838292000000b303b200000000b30300002232132333b200000000b303829300a2838292019242845262b2000000000000
00a2b302b2a30082b302b200110000825262b200000000b1b10000a283a2425200000000a30082000083000000000000000000000094a4b4c4d4e4f400000000
525262428462b200a2830342624262928300000000b303b200000000b303e3415252222232b200000000b30392000000829200000042525262b2000000000000
000000b100a2828200b100b302b211a25262b200000000000000000092b3428400000000827682000001009300000000000000000095a5b5c5d5e5f500000000
232333132362b22100820342621333008293858693b3031111111111114222225252845262b200001100b303b2000000821111111142528462b2000000000000
000000000000110176851100b1b3020084621111111100000000000000b3135200000000828382670082768200000000000000000096a6b6c6d6e6f600000000
82000000a203117200a2031333010193828283824353235353535353535252845252525262b200b37200b303b2000000824353535323235262b2000011000000
0000000000b30282828372b26100b100525232122232b200000000000000b14200000000a28282123282839200000000000000000097a7b7c7d7e7f700000000
9200110000135362b2001353535353539200a2000001828282829200b34252522323232362b200b30300b3030000000092b1b1b1b1b1b34262b200b372b20000
001100000000b1a2828273b200000000232333132333b200001111000000b342000000868382125252328293a300000000000000000000000000000000000000
00b372b200a28303b2000000a28293b3000000000000a282838293b312525252b1b1b1b173b200b30393b30361000000000000000000b34262b271b303b20000
b302b211000000110092b100000000a3b1b1b1b1b1b10011111232110000b342000000a282125284525232828386000000000000000000000000000000000000
80b303b20000820311111111008283b31111111111000082920092b342528452000000a3820000b30382b37300000000000000000000b3426211111103b20000
00b1b302b200b372b200000000000082b21000000000b31222522363b200b3138585868292425252525262018282860000000000000000000000000000000000
00b373b20000a21353535363008292b32222222232111102b20000b31323525200000001839200b3038282820000000011111111930011425222222233b20000
100000b10000b303b200000000858682b27100000000b3425233b1b1000000b182018283001323525284629200a2820000000000000000000000000000000000
9300b100000000b1b1b1b1b100a200b323232323235363b100000000b1b1135200000000820000b30382839200000000222222328283432323232333b2000000
329300000000b373b200000000a20182111111110000b31333b100a30061000000a28293f3123242522333020000820000000000000000000000000000000000
829200001000410000000000000000b39310d30000a28200000000000000824200000086827600b30300a282760000005252526200828200a30182a2000000a3
62820000000000b100000093a382838222222232b20000b1b1000083000000860000122222526213331222328293827600000000000000000000000000000000
017685a31222321111111111000000b322223293000182930000000080a301131000a383829200b373000083920000005284526200a282828283920000000082
62839300000000000000a3828282820152845262b200000093000082a300a3821000135252845222225252523201838200000000000000000000000000000000
828382824252522222222232000000b352526282a38283820000000000838282320001828200000083000082010000005252526200008283820000000000a382
628201930000000000a282828382828252528462b20000a38300a382018283821222324252525252525284525222223200000000000000000000000000000000
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
00000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000060000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000660000000000000000000000000000000000
60000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000d00060000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000d00000c000000000000000000000000000000000000000000000000000000000000
000000000000000600000000000000000000000000000000000000000000d000000c000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000c0000000c000600000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000d000000000c060d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c00000000000d000d000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000777777007777770077770000777777007777770077777700770077007777770077777700000000000000000000000000000
00000000000000000000000000000777777007777770077770000777777007777770077777700770077007777770077777700000000000000000000000000000
00000000000000000000000000000777777007700770077007700770000007777770077007700770077007700000077007700000000000000000000000000000
00000000000000000000000000000777777007700770077007700770000007777770077007700770077007700000077007700000000000000000000000000000
00000000000000000000000000000770077007777770077007700777700007700770077777700777700007777000077770000000000000000000000000000000
00000000000000000000000000000770077007777770077007700777700007700770077777700777700007777000077770000000000000000000000000000000
00000000000000000000000000000770077007700770077007700770000007700770077007700770077007700000077007700000000000000000000000000000
00000000000000000000000000000770077007700770077007700770000007700770077007700770077007700000077007700000000000000000000000000000
00000000000000000000000000000770077007700770077777700777777007700770077007700770c77007776770077066700000000000000000000000000000
00000000000000000000000000000770077007700770077777700777777007700770077007700770077007777770077066700000000000000000000000000000
0000000000000000000000000000000000000000000000cc0000000000000000000000000000000000c000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000c000000000000000000000000000000000000c000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000c0000000000000000000000000000000000000c000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000100000000000000000000000000000000000000c00c000000000000000000000000000000000000000000
000000000000000000000000000000000000000000c0000000000000000000000000000000000000001010c00000000000000000000000000000000000000000
000000000000000000000000000000000000000001000000000000000000000000000000000000000001000c0000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000000000000000000000000000000000
06000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000070000
00000000000000000000000000000000000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005550555055005500505000005550505005505550055005505500000000000000000000000000000000000000
00000000000000000000000000000000000000005550505050505050505000000500505050505050500050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050555050505050555000000500555050505500555050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505050505050005000000500505050505050005050505050000000000000000000000000000000000000
00000000000000000000000000000000000000005050505055505550555000000500505055005050550055005050000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005500055055505000000055505550555055505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050505050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505055005000000055005500550055005550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050505050005000000050505000505050500050000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005050550055505550000055505550505050505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000055500550550000005550555075005550000055505050000055505500555055505550555055505550550000000000000000000000
00000000000000000000000055505050505000005550505050505000000050505050000050505050050005005050505050500500505000000000000000000000
00000000000000000000000050505050505000005050555050505500000055005550000055505050050005005500550055500500505000000000000000000000
00000000000000000000000050505050505000005050505050505000000050500050000050505050050005005050505050500500505000000000000000000000
00000000000000000000000050505500555000005050505055505550000055505550000050505050050055505550505050505550505000000000000000000000
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
00000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
8080000000000000808080808000000084028080800080808080800200000000030303030303030384848402028000000303030303030303848484020202020280001313131382820300000606020202800013131313828284000006060200008000131313138084840006000000020080001313131380808006060606020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
233125254825253232323232332a382425262425252631323232252628282824252525252525323328382828312525253232323233000000313232323232323232333132332432323233313232322525252525482525252525252526282824252548252525262828282824254825252526282828283132323225482525252525
25233132323233212236212222232a242526313232332828002824262a102824254825252526002a2828292810244825212328290000000028282900000000002810000000372829000000002a2831482525252525482525323232332828242525254825323338282a283132252548252628382828282a2a2831323232322525
25252320212222323321254825323624252523201028292900282426003a382425252548253300002900002a0031252524262123003a676838280000000000003828393e003a2800000000000028002425253232323232332122222328282425252532332828282900002a283132252526282828282900002a28282838282448
323233343232333900312525332020244825262828290000002a243300002a2425322525260000000000000000003125242631482321222328280000000000002a2828343536290000000000002839242526212223202123313232332828242548262b000000000000002d00003b242526282828000000000028282828282425
2340283828293a28393a31333435222525482629000000000000302b000000243300312533111100000000000000003124262d313331482620283900000000000010282828290000000011113a2828313233242526103133202828282838242525262b000000000000000000003b2425262a2828670000002a28283828282425
263a2821231028292a2900002a2831252532333a390000110000372b0000112400000037212223000000000000000000242621222223242628290000000000002a2828290000000000002123283828292828313233282829002a002a2828242525332b000000001111000000003b314826112810000000006828282828282425
252223313328290000000000002828242634353536393a273900000000002125001a000024252611111111000000000031332425482631332800000017170000002a000000001111000024261028290028281b1b1b282800000000002a2125482628390000003b34362b000000002824252328283a67003a28282829002a3132
2532332828290000000039003a283824252320202123383028390000003a24480000003a3132323535353667580011112828313232332123290000000000000000000000003b3436003a2426282800003828390000002a29000000000031323226101000000000282839000000002a2425332828283800282828390000001700
2600002a28000000003a283a2828282425252223243236372838675868293132000000282828282820202828283921222829002a28282426000000000000000000000000003b20382828312523000000282828290000000000003a67682828003338280000000010382800000000003133282828282868282828280000001700
330000002867680000281028283422252525482637212320282828382811212200003a28382810291b1b2a28382824252a00000028382426000000171700000000000000003b2728282a283133390000282900000000000000002a28282829002a2839000000002a282900000000000028282838282828282828290000000000
0000003a2828383e3a28282838282425482525262148262729002a28283432250000002a282828111111112810282425000000002a282426000000000000000000000000003b37280000002a28283900280000003928390000000000282800000028290000002a2828000000000000002a282828281028282828675800000000
0000002838282821232800002a2824253232252624253330000000002a28282400000000002a282122222328282824480000003a28273133000000000000171700013f00003b2029000000003828000028013a28281028580000003a28290000002a28000000003a380000000000000000002a2828282828292828290000003a
00013a2123282a31332900111111242500283126243329300000000000002a310000000000002831252533292a0024253e013a3422483600000000000000000035353536003b20000000003d2a28671422222328282828283900582838283d00003a290000000028280000000000000000002a28282a29000058100000002a28
22222225262900212311112122222525002a3837372900301111110000003a2800013f0000002a282426290000002425222222233133000000000000171700002a282039003a2000003a003435353535252525222222232828282810282821220b10000b00000b28100b00000b00000b2c00002838000000002a283917000028
2548252526111124252222252525482500012a2828673f242222230000003828222223000012002a24260000001224252525252600000000171700000000000000382028392827080028676820282828254825252525262a28282122222225253a28013d0000006828390000000000003c0168282800171717003a2800003a28
25252525252222252525252525252525222222222222222525482667586828282548260000270000242600000021252525254826171700000000000000000000002a2028102830003a282828202828282525252548252600002a2425252548252821222300000028282800000000000022222223286700000000282839002838
2532330000002432323232323232252525252628282828242532323232254825253232323232323225262828282448252525253300000000000000000000005225253232323233313232323233282900262829286700000000002828313232322525253233282800312525482525254825254826283828313232323232322548
26282800000030402a282828282824252548262838282831333828290031322526280000163a28283133282838242525482526000000000000000000000000522526000000000000002a10282838390026281a3820393d000000002a3828282825252628282829003b2425323232323232323233282828282828102828203125
3328390000003700002a3828002a2425252526282828282028292a0000002a313328111111282828000028002a312525252526000000000000000000000000522526000000001111000000292a28290026283a2820102011111121222328281025252628382800003b24262b002a2a38282828282829002a2800282838282831
28281029000000000000282839002448252526282900282067000000000000003810212223283829003a1029002a242532323367000000000000000000004200252639000000212300000000002122222522222321222321222324482628282832323328282800003b31332b00000028102829000000000029002a2828282900
2828280016000000162a2828280024252525262700002a2029000000000000002834252533292a0000002a00111124252223282800002c46472c00000042535325262800003a242600000000002425252525482631323331323324252620283822222328292867000028290000000000283800111100000000000028292a0000
283828000000000000003a28290024254825263700000029000000000011003a293b2426283900000000003b212225252526382867003c56573c4243435363633233283900282426111111111124252525482526201b1b1b1b1b24252628282825252600002a28143a2900000000000028293b21230000000000112867000000
2828286758000000586828380000313232323320000000000000000000272828003b2426290000000000003b312548252533282828392122222352535364000029002a28382831323535353522254825252525252300000000003132332810284825261111113435361111111100000000003b31331111111111272829000000
2828282810290000002a28286700002835353536111100000000000011302838003b3133000000000000002a28313225262a282810282425252662636400000000160028282829000000000031322525252525252667580000002000002a28282525323535352222222222353639000000003b34353535353536303800000000
282900002a0000000000382a29003a282828283436202b000000003b2030282800002a29000011110000000028282831260029002a282448252523000000000039003a282900000000000000000031322525482526382900000017000058682832331028293b2448252526282828000000003b201b1b1b1b1b1b302800000000
283a0000000000000000280000002828283810292a000000000000002a3710281111111111112136000000002a28380b2600000000212525252526002d00000028282810000000000011000000112123252525252628000000001700002a212228282908003b242525482628282900000000001b000000000000302900000000
3829000000000000003a102900002838282828000000000000000000002a2828223535353535330000000000002828393300000000313225252533000000000028382829000000003b202b00112125263232323233290000000000000000312528280000003b3132322526382800000000000000000000110000370000000000
290000000000000000002a000000282928292a0000000000000000000000282a332838282829000000000000001028280000000042434424252628390000000028002a0000110000001b001121252526000000000000000000000000000010312829000000001b1b1b313328106700000000001100003a2700001b0000000000
00000100000011111100000000002a3a2a0000000000000000000000002a2800282829002a000000000000000028282800000000525354244826282800000000290000003b202b390000112031323233000000000000000000000000000028282800000000000000001b1b2a2829000001000027390038300000000000000000
1111201111112122230000001111002a00010000000000000000000000002900290000000000000000002a6768282900003f01005253542425262810673a3900013f0000002a3829001121222300002101000000000000003a67000000002a382867586800000100000000682800000021230037282928300000000000000000
22222222222324482611111120201111002739000017170000001717000000000001000000000000000000282838393a0021222352535424253328282838290022232b00000828393b27242526001424230000000000000028290000000000282828102867001717000000282839000031333927100028370000000000000000
254825252526242526212222222222223a303800000000000000000000000000001700000000000000003a28282828280024252652535424262828282828283925262b00003a28103b30313233212225260000000000003a28000000000000282838282828390000005868283828000022233830280028270000000000000000
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

