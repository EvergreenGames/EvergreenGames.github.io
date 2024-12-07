pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--~flare~
-- evercore-based mod
-- made in 4 days by vei!


--~evercore~
--a celeste classic mod base
--v2.2.0

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

-- [entry point]

function _init()
  frames,start_game_flash=0,0
  music(12,0,7)
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
    spd=0+rnd"2",
  w=16+rnd"16"})
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
    cam_x,cam_y=mid(this.x+4,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
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
  end,
  draw=function(this)
    if this.spr==22 then
      for i=10,12 do
        pset(this.x+4+sin(this.offset*1+i/10),this.y+i,9)
      end
      for i=9,13 do
        pset(this.x+4+sin(this.offset*2+i/10),this.y+i,10)
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
    this.text="run, for she wakes -#confined to this planet#but not for long."
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
    		music(0,500,0)
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
    ?"veitamura",47,90,5
    ?"🅾️/❎",55,80,5
    ?"original game by:",32,102,5
    ?"maddy thorson",40,108,5
    ?"noel berry",46,114,5

    -- particles
  		foreach(particles,draw_particle)

    return
  end

  -- draw bg color
  cls(flash_bg and frames/5 or bg_col)

  -- bg clouds effect
  foreach(clouds,function(c)
    c.x+=c.spd-cam_spdx
    rectfill(c.x,c.y,c.x+c.w,c.y+10-c.w*1.3*0.1875,14)
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
  "2,0,2,1,aWAKENING",
  "2,1,2.6875,2,mEANDER",
  "2,3,1.5625,1,oUTCROP",
  "3.5625,3,1.0625,1,iNTROSPECTION",
  "0,1,2,1.625,pLUMMET",
  "0,2.625,2,1.375,bREACH",
  "4.6875,0,1,1.3125,sKYWARD",
  "4.6875,1.3125,1.3125,2.25,sPEARHEAD",
  "6,1.3125,1,1.6875,fLOATING",
  "5.6875,0,2.3125,1.3125,fORWARD iN tIME",
  "0,1,2,3,tERMINAL vELOCITY",
  "0,0,1,1,oRBIT"
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
  "2600000000000000313232323225252525252525252525252525252525252525252300000000003a2867000028242525252548252525252525252525252525252526003a28282828282839002831452525252525252525252525252525252525252628282828282828001111283b553125252525252525252525252532252525253367002a28282828002123283b550031322525252548252525252645242525333a283900002a2828002433283b5500000031322525323232323233552425250d2828282122232a28283728283b62446768280024260d2828282828553125252828282824252628282800002a393b552b2a283924332828282828285244242500002a28312526282828390000283b552b0028283728282828382828525424250000002a2831332a2829283900283b652b0028290e28282828282828525424250000000028283900283a2828002a391b003a28002a2828282828282852542425222300002a28282828282828390028003a282800000000002a282842535431252526002c002a2828282828282828282828002a39003d000100284253535400312525233c00002a21222222232a2828282800002a2821222222222363536344002525252300000024254825260028282828000042433125252525253655006243252525263a392125252525263a282828283b4253535424254825264254000052",
  "2525252525252525252525252525252525252525252525482525252525252525252525253232323300000025252525252525252525252525252525252525252525252525252525252525252532323300280028000000252525252525252525252525254825252525252525252525252525252532323233003a28002828290000002525252525252525252525252525252525252525252525253232323233280000003a290000282900000000482525252525252525252525252525252525253232323233000000282828003a282900003a28000000002125252525252525252525482525253225253233002a28290000003a10292a2829000000002a2810390021252525252525252525323232323233002426280000002800003a2828160000000000003f002122232a39242525252532323232331029000000000031262a39003a2828282828290000111111112122222525262b2a242525323300003a280e290000000000000037002828282828282911111111212222222525252525262b002425260028001a283900000000000000000000002828282829000021222222252525252525252525260000242526002a3900282839001111111111000000002a28280000212225252525252525252548252525330000242525230028282828290072737373440000000000282800343232322525252525252525252525261b003a242525263a2828282839212222222362734400003a282800003a28393132323232322525252525266768292425252628281111111124252525252223627373742828282829002a28283900000031323225252600003b2425252611112122222225252525252525222222232828290000000000002839000000000024252639003b2425252522222548252525252525252525252525252222230000003d0000282900000000003125262a393b31252525252525252525252525254825252525252525252522222222230028000000000000002433002a393b31252525252525252525252525252525252548252525252525252525222223111111000000370000002a3900252525252525252525252525252525252548252525252525252525253232353536282828390000003a28392525252525252525254243442525252525252525253232323232323328000000000000002a2828282828282525252525252525255253542525323232323232332839000000003a29000000000016000000282828282a25252525252525252562535432334243740d3828393a2839003a28280000000000000000003a106768283a25252525253232323223626373736364282829002828282828282828283900000000000000280000002a28323232323300003a28312222360000000000003a28282828282828002a282839000000003a2900000000280000280000003a2828003133000000000000002a2828292a282828003a29002a390000002811111111212200002800003a29002a3900000000000000000000002800002828286829000000280012002122222222252500002a2828290000002800000011111100000000002800002a28291111111121222222222525252525252500003a28280000000028000000424344000000003a28001121222222222222252525252525252525252525003a29002a3900003e28394243536364212300002a102122252525252525252525252525484825252525252829000100280000212222525354222225252300002a3125252525482525252525252525252525252525252921222222222222252525525354252525252600000000242525252525252525252525252525252525252522252525254825252525255253542525252526000000002425252525252525252525252525252525252525",
  "25262b3a29002828282828313232323225252525252525252525332b10282828282828282828290028312525323232323232262b00002a29000000002a2829000028002426002a2868290026110000000000002d00002900110028002433003a2900000025232b0000000000000000000027002a39370000280000000025332b00003b2122232b0000212600002800003a2900000000331b1111003b3132332b003b242600002a2828290000002122003b212339002a283900003b31330000002829002135222525003b31262b3900002a2828283900000000280021334524252500003b372b290000000000002a2839003a28393742642425250000000e290000111100000011002a2828282942643a3132250001002800000021230000114500002828003b552a292a10310021222222360024260000425400002828003b650000006768002425323300002426000052540000282800001b0000002a280024260d29001124330011525400002829000000000000002822252629000021260000425353440028000000000000000028",
  "005524252525260000000000002425252500552425482526000000000000312525250055312525252600000000003a392425250052442425253300003a28282828313225006254242526003a28292a28002a0e2831003b552425263a29001600280000002a28003b553125262800000000280000000000003b5244242629000000002a3900000000003b525431260000000000002800464700003b625400372867000000002a395657000000006500002a283900003d0021222222003f0000000000282839002122252525252223111111000028002a28242525482525252522222300002839002125252525252525252525260100282839242548252525252525482525233a29002a24252525252525",
  "54242600000000242525252525252532323232323232323232323362535353535431262839000024482525323232330000000000002a2828282828286253535353443000280000312525262b28000000000000000000000000002a2828525353535430002a393a282425262b2a3900002c00002122222236000000002a52535353542423392828002425262b002839003c002125323233281717000000525353535424262a28283b2425262b002a2821222225261b1b1b283900000000525353535424260000283b2425262b000010242525253300000028280000003b52535353542426000028002425262b00002a24482526390000002a283900003b62535353542426000028003125262b00000024252526282839000028280000003b62535364243317002a282824262b0000003125252523292a39002829000000003b525421262b28000000002425232b0000282425252600002a392a342222222223626424262b2a390000003125262b003a29242525263d3a282a39003125254825222225262b00280000000024332b00280024252525232829002a390024252525252525332b002a39171700372b003a29002425254825230000002800243232323248262b0000002a2829003a3968280000313225252526000000283a371b1b1b1b25262b000000002800002a28282900001b1b312525252300002a2828290000002533001717003a29000000282800000000001b31252526000000282839000000261b002a2828290000000028380000160000001b31252600003a28282a390000262b003a282900000000002829000000000000001b3133000028282828282868262b002828000000000000283900001100000000001b1b003a29002a28282828332b00283800000000003a28280011273900001111003a282800000000002a2800003a2829000000000028282900212628003b3436282900280000000045000000002828003f000100002828001124262a3900282900000028003e00215243430000282800212223003a28283b21252600281028000000002a28212225625353003a282900242525232a28293b242526002a28280000000021222525252552530028280000242525260028003b24482600000028390000002425252525255253",
  "002a2838282900003b24252526525353535353535353536363643900000000000000002a280000003b3125252662535363636363636364002a282839000000000000000028000000003b3125252352640000003a282900000000002a390000000014013a2839000000003b2425266528393a2829000000000000003a10390000222222223629001111003b2425330028282900000000003b21222222222222222525253300000021232b3b2426393a28290000000000003b24252525252525252532330000000024332b3b31262829003b21233f0000003b242525252525252533424468675868370000003b37290000002425230000003b31252525252525254353542a39002a29000000001b00000000313226110000003b24252525252525535364002a3900000000001121230000003a2824230000003b3125252525252553542b003a28000000003b21253300000028292426000000003b24252525252553542b3a2900000000003b24263900003a29002426000000003b24252525252553642b280011000016003b24330d003a2900003133000000003b242525252525542b00283b202b0000003b372b2828280000002800000000003b31252525252553442b28001b00000000001b002a382800003a290008000000003b242525252553542b2800000000160000000000002a393a28000000000000003b312525252553642b2800000000000000002839000028282900003d00000000003b24252525542b002800000000000011002a283900282800002123003a3900003b24252525642b3a2900000016003b202b002838282828282824263a281039003b24252525393a29000000000000001b003a28002a28000000242523282829003b2425252510290000000000000000003a282900002a390021252526282900003b24252525280000000000000000003a282900000000280024252526290000003b24252525",
  "2a283900586829003b24252653535353002a3828290000003b3125265353535300002a2900000000003b312662535353230000000000000000003b31353523533236000000000000000000003b623135282900000000000000000000003b52532a0000000000000000000000003b6263000000000000000000000000006828280000000000000000000000003a29292a0000000000000000000000003829000000000000000000000000000028390000000001000000000000003a392a280000222222222236000000002a282828390025253232333900000000000000002a283233280e28283900000000000000000000002a102828283900000000000000000000002a282828280000000060000000000000002a28382839000000000000000000000000282828290000212223000000000000002a2828002122254825360000000000000028283924252525260000",
  "252525252525252525323233550000000000525353254825253232323233727373640000000042535353252532330d290000001b1b1b1b00000042535353632533002a2900000000000000000000005253536400330000000000111111001600000000115253640000390000000011212223110000000000425364000000280016003b3432323236000000001152542839002128390000001b1b1b1b1b11111111425364282839242828670000000000003b4243434353542a282821252900111111111100163b626363636364002a282425003b21222222232b00001b1b1b1b1b1b0028283125003b31323232332b00000000000000003a283a0e2400001b1b1b1b1b00000000000000003a28382122250000000000000000000000000000002a28212525250000003a2828282839000000002c00002a24252525003a28282810282829000000003c00212225254825282828282828290000000000212222252525252525282828290000000000171721252525323232323232000000000000111111000024253233003a391b1b1b0000000011112122362b00242628393a28282810390000003b343532331b001124262a282900003d1428000000001b1b1b1b00002125330000003b212222223d0000000000000000003126000000003b3125252522222300000000000000003700000000003b3132252548263a283900000000000000000000000000002425323328282828390000003f00000000000000003133002a29002a28280000212223000000000000000000000000000028380000242525232b00000000000000000000000028280000313232330000003b21222200000000000028280000002828283900003b242525000000000000282839000000002a2828393b31252500000000003a29002800000000002a282839003132000000003a2900002a3900171700002a38282828280001000028001717002a3900000000002a282900003e2122232900000000002800000000000028000800222525260000000000002839000000000028390000",
  "53535364242525252525260000000000535354212525252525323300000000005353642425252525260000000000000053542125253232252600002c0000000053542425332800242523003c00000000535431333a28283132323522232b000053543a282829000000000031332b0000535428282900000000002a2828390000535428290000000000111100002a282853542800001111003b2123000000002a535429000021232b3b31263900110000535400000024262b001b371039272b00535400001124332b00001b3435332b005354000021262b00000000001b1b00005354000024262b0000000000000000006354000031332b000000000000000000235512003a3900000011111111000000265244002828001111212222230016002652540028283921222525323300000026625400282828242532331b1b0000002523553a28382125331b1b000000000025265528292a24261b0000000000000025265529002125332839000000000000252652440031331b2a2800003f010000252652534400000000283900212300002526535353434400002a28393125230025252353535353440000282839242522",
  "252525252532323232323232322525252525252526525353535400000000000000000000002525253233000000002a6758683132323225482526525353535417003e000000000000000025323300003a28282900002a3900000028313232335253535364002122230000000000000026003a3828282900000000002a39003a290028293b52535364000024252600000000000000333a2828282900000000171700283829003a28003b5253543a39002425260000000000000028282900001111111100000000282900002a28003b5253542828393125263f0000000000002900000000724343441111003a290000003a28003b5253542828280024252300000000000000001600000062535373741129000000002a28003b625354281a28393125260000000000003900000000000062642122231111000000002800003b52542829282839242600000000000028282828283900002125252522232b0000002900003b52542839282921252600000000003a29000011002a10682425482525262b0000000000003b526428382821252526000000000028001111272b0028392425252525262b0000000000114254002a282931322526000000003a28112122332b0028292425252525262b00000011117263637343442b1b1b31330000000028282232331b003a28002425252525262b00001121222222222352542b00001b1b0000003a2828331b1b00002828393125252525332b00003432322525253352542b0000000000003a2838281b000000002800283924254826390000000000003132330052542b0000000000002828282800000000002a282828242525260d3900000000002a28394253642b00000000000028282828000001003d002a282924252526290000000000000028286264000000000000003a2810290022222222230000280024252526000011111100000028280000000000121200002828280000254825253236002800242525330011424344000000282800000000001717000028282900002525252600003a280024252600004253535400000028280000000000000000002828000000",
  "00000000000000005253635353535353535363640024252532323232323232320000000000000000525400626363535353542122222525333a2838282828290000000000000000005254000000006263636424252525332828290000160000000000000000000000525344003f3a282122222525252600000800001100000000000000000014002122222222222222252525252525252311111111452b000000000000002122222525252525252525252525252525252522364243542b00000000003b212525253232323232323232323232322525252526725353542b00000000003b2432323300525353442b2a28283900003132323232236263542b00000000003b373a283900625353542b0000002a39000028007263313536552b0000000000003a292a2828395253542b000000002800002a39003a28627363442b000000003a382900002a285253542b00000000280000002a2829000000005244000000000028000016002a5253542b0000003a29000000002800000000006254000011003a2900000000005253542b00000028000000212223000000000000650000233a29000000000000525353442b000028003b2125252600000000000000003a262867001111000000525353542b00002a393b242525260000000000003a28282600003b4244000000525353542b000000283b242525260000003a28282900122600003b6254110000625353542b003a28283b24252533282828290000000017260000003b52440011115253542b3a2838293b2425260000000000000000003a330000001152541121236253542b282829003b2425260000000000003a393a281b0000003462642225252352542b280000003b2425260d282828283828282967000000001b1b313232323352542b2a3900003b2425260000002a28282829002a0000000000001b1b1b1b1b62542b00280000212525260000000000002a283900000000000016000000000000552b0028000024252526000000000000002a2828111111110000000000000000552b002a3900242525260000000000000000002a222222231111110000000000652b0000280024252526001717170000000000003232322522222300000000001b0000002800242532330000000000000000000000280031323233000000000000000000280024262b0000000000000000111111002800003a2828000000000000000000280024262b00000000000011112122350028393a282900000000000000000000280024262b000000000011212225263a00282828291717000000000000000000282125330000000000112125253233283a38282900000000000000000000003a2824262b0000000000343232333a282828282900000000000000000000003a382125332b00160000003a29000028290028290000000000000000000000002a2831332b0000000000002a39003a2800002900000000000000000000003a281028282839000000000000002a392a28390000000000000000000000003a2900002828282839000000000000002800002839000000000000000000003a2900003a2900002a282839000000003a2900002a280000000000000000003a2900000028000000002a28282839003a2900000000280000000000000000002800000000280000000000002a3828282800000000002800000000000000003a290000000028000000000000002a28002839000000002a000000000000000028000000003a2900000000000000002a2828283900000000000000000000000028000000002800000000001200000000002a28283900000000000000000000002800000000212222222222360000000000002a38280000000000000100000021222222222225252525323300000000000000002a28390000000021222222222525252525253232323300000000000000000000002a28000022222525252525252525253233000000000000000000000000000000002a390025252525252525253232330e28000000000000000000000000000000000028002525252525253233002a28282839000000000000000000000000000000002a2825252525252600000000002a3828000000000000000000000000000000000028",
  "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000076003e00000000002c0000000000343522222300000000003c00000000003a28313233390000000021230000000028000000282839000068242600000000280000002a2928393a2924333900003a29000000000028282900370d2800002800000000000028290000002a280000290000000000002a000000000028000000001200000000000000000000280000000021223600000000000100002a3900003a31332800003a0000270000002800002a280e290000280021263900002a3900002a280000002800242523390000280000002839000028"
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
 [1]=0,
	[4]=30,
	[5]=1,
	[7]=30,
	[8]=4,
	[12]=30,
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
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700155555155513b21500000000
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000777777677777770911551c1513bb82100000000
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a000776666666776777799911cc113bb182100000000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0007677766676666677aa9991d11bb1182100000000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a00000000000000000001aaa99155111882100000000
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000000000000000000c11aaa155551811500000000
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a0000000000000000000cd1111555555155500000000
000000000070070000700070000000000000070000007000077333700070070000aaa0000009a0000000a0000000000000000000115555555555555500000000
555555550000000000000000000000000000000000000000011111104999999449999994499909940300b0b06665666500000000000000000000000070000000
55555555000000000000000000000000000000000000000011cccc11944114499111411991140919003b33006765676500000000007700000770070007000007
550000550000000000000000000000000aaaaaa0000000001ce77ec1911441199414414949400419028888206770677000000000007770700777000000000000
55000055007000700499994000000000a998888a0000000001cccc10911441199494049900000044089888800700070000000000077777700770000000000000
55000055007000700050050000000000a988888a0000000001e77e10994994999199094900000000088889800700070000000000077777700000700000000000
55000055067706770005500000000000aaaaaaaa000000001ceeeec1440000440400009900000000088988800000000000000000077777700000077000000000
55555555567656760050050000000000a980088a0000000011cccc11000000000000000900000000028888200000000000000000070777000007077007000070
55555555566656660005500004999940a988888a0000000000111100000000000000000000000000002882000000000000000000000000007000000000000000
511111155111111111111111111111151661dddddddddddddddd1661511111155555555555555555555555555500000000110000000000000000000000000000
116666111166666666666666666666111661dddddddddddddddd1661116666115555555555555550055555556670000001551000000777770000000000000000
166d66611666dddd16666661dddd666116661dddddddddddddd16661166116615555555555555500005555556777700019151100007766700000000000000000
16dddd61166dddddd116611ddd1dd66116661dddddddddddddd16661161dd16155555555555550000005555566600000191f5100076777000000000000000000
1677dd6116dd111dddd11dddd171dd6116661dddddddddddddd16661161dd1615555555555550000000055555500000001ff1100077660000777770000000000
1667766116d17771ddddddddd1771d6116661dddddddddddddd16661161dd1615555555555500000000005556670000001ff1100077770000777767007700000
1166661116d17771dddddddddd171d611661dddddddddddddddd1661161dd1615555555555000000000000556777700001ff5110070000000700007707777770
5111111516dd111dddddddddddd1dd611661dddddddddddddddd1661161dd1615555555550000000000000056660000001ff5110000000000000000000077777
161dd16116dddddddddddddddd11dd61511111111111111111111115161dd1615555555550000000000000050000066611f51111000000000011111000000010
161dd16116dd11ddddddddddd1771d61116666666666666666666611161dd161505555555500000000000055000777761ff519410000000001ccccc1000001b1
161dd16116d1771ddddddddd17771d61166dd166661dd166661dd661161dd161555500555550000000000555000007661ff51941000010001cccccc101001b31
161dd16116dd171dddd11ddd1771dd6116dddd1111dddd1111dddd61161dd161555500555555000000005555000000551ff11911000181001ccf4ff11b101bb1
161dd161166dd1ddd116611dd11dd66116dd11ddddd11ddddd11dd61161dd161555555555555500000055555000006661ff194100001810001ff44f11b101b31
161dd1611666dddd16666661dddd66611661661ddd1661ddd1661d6116611661550555555555550000555555000777761f19941000128100001114f113b11b10
161dd161116666666666666666666611116666666666666666666611116666115555555555555550055555550000076611194110000128100001441001b1b310
161dd1615111111111111111111111155111111111111111111111155111111555555555555555555555555500000055119941000001288100014100001b3310
5777755700000000077777777777777777777770077777700000000000000000d11ddddd00000000000000000000009999999999999990000000000000000000
77777777000000007000077700007770000077777000777700111111111111001771dddd00000000000000000099890998000a00888a99999000000000000000
7777cc770000000070cc777cccc777ccccc7770770c7770701cccccccccccc101761dd1d000000000000000998888888aaaaa000aaa8a88a9900000000000000
777ccccc0000000070c777cccc777ccccc777c0770777c071cccccccccccccc1d11dd1610000000000000099a88880aaa000000000000a888890000000000000
77cccccc00000000707770000777000007770007777700071ccc555cc555ccc1ddddd16100000000000099a8080aaa0000099988000000aaa889900000000000
57cc77cc00000000777700007770000077700007777000071cccccccccccccc1dddddd1d0000000000990aa089aa0000009988000000990aaaa8990000000000
577c77cc000000007000000000000000000c000770000c071c5c55cc555c55c1dddddddd000000000990aa8880000000098aaa000000888000aa890000000000
777ccccc00000000700000000000000000000007700000071cccccccccccccc1dddddddd000000099a88088900000000998a00000000aa88000aa89000000000
777ccccc00000000700000000000000000000007700000071ccc55c5c5555cc10000000000000099a88aa8900000000098aa000008800a080000089000000000
577ccccc000000007000000c000000000000000770cc00071cccccccccccccc1000000000000009888aa89000000000098a00000aa000aa000000a8900000000
57cc7ccc0000000070000000000cc0000000000770cc00071cc1111111111cc10000000000009900aaa990000000000098a000000000000000000aa900000000
77cccccc0000000070c00000000cc00000000c0770000c071c10000c000001c1000000000009980aa00000000000000090000000000000000000009000000000
777ccccc000000007000000000000000000000077000000701000000c000001055555555000800aa666666006600000006666600666666006666660000000000
7777cc770000000070000000000000000000000770c000070000001c010011105555555500900aa0666666606600000066666660666666606666666000000000
777777770000000070000000c000000000000007700000070000116116116610555555550998aa00660000006600000066000660660006606600000000000000
57777577000000007000000000000000000000077000c00700016666666a666055555555098aaa90dddd0000dd000000ddddddd0dddddd00dddd000000000000
000000000000000070000000000000000000000770000007007777005000000000000005988aaa90dd000000dd0000d0dd000dd0dd000dd0dd00000000000000
00aaaaaa00000000700000000000000000000007700c000707000070550000000000005598aaaa00dd000000ddddddd0dd000dd0dd000dd0dddddd0000000000
0a99999900000000700000000000c00000000007700000077077000755500000000005550aaaa800dd000000ddddddd0dd000dd0dd000dd0ddddddd000000000
a99aaaaa000000007000000cc0000000000000077000cc077077bb0755550000000055550aaa8900000000000000000000000000000000000000000000000000
a9aaaaaa000000007000000cc0000000000c00077000cc07700bbb075555555555555555aaaa8900000000000000000000009880099999900aa8900000000000
a99999990000000070c00000000000000000000770c00007700bbb075555555555555555aaa08900000000000000000000009988aaaaa000aa88000000000000
a99999990000000070000000000000000000000770000007070000705555555555555555aaa8800000000000000000000000009888000000a890000000000000
a99999990000000007777777777777777777777007777770007777005555555555555555aaa89000000000000000001111111111900000009000000000000000
aaaaaaaa0000000007777777777777777777777007777770004bbb00004b000000400bbbaa089000000000001111115555555555111111110000000000000000
a49494a10000000070007770000077700000777770007777004bbbbb004bb000004bbbbba0889000000011115555555555555555555555551111100000000000
a494a4a10000000070c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb00a089000011115555555555ddddddddd5555555555555511100000000
a49444aa0000000070777ccccc777ccccc777c0770777c07040000000400bbb004000000a0890111555555555555dddddddddddd555555555555555511100000
a49999aa0000000077770000077700000777000777770007040000000400000004000000a001155555555555555ddddddddddddd555555555555555555511000
a49444990000000077700000777000007770000777700c074200000042000000420000000015555555555555555ddddddddddddd555555555ddddddd55555100
a494a444000000007000000000000000000000077000000740000000400000004000000001555555555555dd555dddddddddddddd555555dddddddddddd55510
a4949999000000000777777777777777777777700777777040000000400000004000000015555555555dddddd55dddddddddddddd55555ddddddddddddd55551
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
__label__
cccccccccccccccccccccccccccccccccccccc775500000000000000000000000000000000070000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccc776670000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccc77ccc776777700000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccc77ccc776660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccc7cccccc6ccccccccc7775500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccc77776670000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc777777776777700000000000000000000000000000000000000000000011111111111111111111111111111111111111
cccccccccccccccccccccccccccccccc777777756661111111111111111111111111111111111100000000000011111111111111111111111111111111111111
cccccccccccccccccccccccccccccc77011111111111111111111111111111111111111111111100000000000011111111111111111111111111111111111111
ccccccccccccccccccccccccccccc777011111111111111111111111111111111111111111111100000000000011111111111111111111111111111111111111
ccccccccccccccccccccccccccccc777011111111111111111111111111111111111111111111100000000000011111111111111111111111111111111111111
cccccccccccccccccccccccccccc7777011111111111111111111111111111111111111111111100000000000011111111111111111111111111111111111111
cccccccccccccccccccccccccccc7777011111111111111111111111111111111111111111111100000000000011111111111111111111111111111111111111
ccccccccccccccccccccccccccccc777011111111111111111111111111111111111111111111100000000000011111111111111111111111111111111111111
ccccccccccccccccccccccccccccc777011111111311b1b111111111111111111111111111111100000000000011111111111111111111111111111111111111
cccccccccccccccccccccccccccccc7700000000003b330000000000000000000000000000000000000000000011111111111111111111111111111111111111
cccccccccccccccccccccccccccccc77000000000288882000000000000000000000000000000000000070000000000000000000000000000000000000000000
cccccccc66cccccccccccccccccccc77000000000898888000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc66ccccccccccccccc77ccc77000000000888898000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccc77ccc77000000000889888000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccc77cccccccc777000000000288882000000000000000000000000000000000000000000000000000000000000000000000006600000000
ccccccccccccccccc777777ccccc7777000000000028820000000000000000000000000000000000000000000000000000000000000000000000006600000000
cccccccccccccccc7777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6ccccccccccccccc7777777777777775111111111111111111111000000000000000000000000000000000000000000000000001111111111111111111111111
cccccccccccccc776665666566656665111111111111111111111000000000000000000000000000000000000000000000000001111111111111111111111111
ccccccccccccc7776765676567656765111111111111111111111000000000000000000000000000000000000000000000000001111111111111111111111111
ccccccccccccc7776771677167716771111111111111111111111111111111111111111111111111111111110000000000000001111111111111111111111111
cccccccccccc77771711171117111711111111111111111111111111111111111111111111111111111111110000000000000001111111111111111111111111
cccccccccccc77771711171117111711111111111111111111111111111111111111111111111111111111110000000000000001111111111111111111111111
ccccccccccccc7770000000000000011111111111111111111111111111111171111111111111111111111110000000000000001161111111111111111111111
ccccccccccccc7770000000000000011111111111111111111111111111111111111111111111111111111110000000000000001111111111111111111111111
cccccccccccccc770000000000000011111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000
cccccccccccccc770000000000000011111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccc77770000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000000000000000000
cccccccccccc77770000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000111111111111111111111111111111111111111111111100060000000000000000000000000000000000000
cccccccccccccc770000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000000000000000000
cccccccccccccc770000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000000000000000000
cccccccccccccc770000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000000000000000000
ccccccccc77ccc770000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000000000000000000
ccccccccc77ccc770000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccc7770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccc77770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc777777750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccc77550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccc77667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c77ccc77677770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
c77ccc77666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000011
ccccc777550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000011
cccc7777667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
77777777677770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
77777775666000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000011
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777700000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777770000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777770000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777733770000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777733770000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000737733370000001111111111
555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007333bb370000001111111111
555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333bb300000001111111111
55555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333300000001111111111
50555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee0ee003b333300000001111111111
55550055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeee0033333300000001111111111
555500555555000000000000000000000000000000000000000000000000000000111111111111111111111111111111111e8e111333b3300000001111111111
55555555555550000000000000000000000000000000000000000000000000000011111111111111111111111111b11111eeeee1113333000000001111111111
5505555555555500000000000000000000000000000000000000000000000000001111111111111111111111111b111111ee3ee1110440000000001111111111
5555555555555550000000000000000000000000000000000000000000000000001111111117111111111111131b11311111b111110440000000000000000111
5555555555555555000000000000000000000000000000000000000000000000001111111111111111111111131331311111b111119999000000000000000111
55555555555555550000000000000000077777700000000000000000000000000011111111111111511111115777777777777777777777755000000000000005
55555555555555500000000000000000777777770000000000000000000000000011111111111111551111117777777777777777777777775500000000000055
55555555555555000000000000000000777777770000000000000000000000000011111111111111555111117777ccccc777777ccccc77775550000000000555
5555555555555000000000000000000077773377111111111111111111111111111111111111111155551111777cccccccc77cccccccc7775555000000005555
555555555555000000000000000000007777337711111111111111111111111111111111111111115555511177cccccccccccccccccccc775555500000055555
555555555550000000000000000000007377333711111111111111111111111111111111111110005555550077cc77ccccccccccccc7cc775555550000555555
555555555500000000000000000000007333bb3711111111111111111111111111111111111110005555555077cc77cccccccccccccccc775555555005555555
555555555000000000000000000000000333bb3111111111111111111111111111111111111110005555555577cccccccccccccccccc66775555555555555555
555555555555555555555555000000000333333111111111111111111111111111111111111110055555555577ccccccccccccccc6cc66775555555555555555
5555555555555555555555500000000003b3333111111111111111111111111111111111111110555055555577cccccccccccccccccccc775555555550555555
555555555555555555555500000000300333333111111111111111111111111111111111111115555555005577cc7cccccccccccc77ccc775555555555550055
555555555555555555555000000000b00333b33111111111111111111111111111111111111155555555005577ccccccccccccccc77ccc775555555555550055
55555555555555555555000000000b3000333311111111111111111111111111111111111115555555555555777cccccccc77cccccccc7775555555555555555
55555555555555555550000003000b00000440000000000000000000000000000000000000555555550555557777ccccc777777ccccc77775555555555055555
55555555555555555500000000b0b300000440000000000000000000000000000000000005555555555555557777777777777777777777775555555555555555
55555555555555555000000000303300009999000000000000000000000000000000000055555555555555555777777777777777777777755555555555555555
55555555555555555777777777777777777777750000000000000000000000000000000555555555555555555555555500000000555555555555555555555555
55555555505555557777777777777777777777770000000088888880000000000000005550555555555555555555555000000000055555550555555555555555
55555555555500557777ccccc777777ccccc77770000000888888888000000300000055555550055555555555555550000000000005555550055555555555555
5555555555550055777cccccccc77cccccccc77700000008888ffff8000000b00000555555550055555555555555500000000000000555550005555555555555
555555555555555577cccccccccccccccccccc770000b00888f1ff1800000b300005555555555555555555555555000000000000000055550000555555555555
555555555505555577cc77ccccccccccccc7cc77000b000088fffff003000b000055555555055555555555555550000000000000000005550000055555555555
555555555555555577cc77cccccccccccccccc77131b11311833331000b0b3000555555555555555555555555500000000888800000000550000005555555555
555555555555575577cccccccccccccccccccc771313313111711710703033005555555555555555555555555000000008888880000000050000000555555555
7777777777777777cccccccccccccccccccccccc7777777777777777777777755555555555555555555555550000000008788880000000000000000055555555
7777777777777777cccccccccccccccccccccccc7777777777777777777777775555555555555555555555550000000008888880000000000000000055555550
c777777cc777777cccccccccccccccccccccccccc777777cc777777ccccc77775555555555555555555555550000000008888880000000000000000055555500
ccc77cccccc77cccccccccccccccccccccccccccccc77cccccc77cccccccc7775555555555555555555555550000000008888880000000000000000055555000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc775555555555555555555555550000000000888800000000000000000055550000
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc775555555555555555555555550000000000006000000000000000000055500000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc775555555555555555555555550000000000060000000000000000000055000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc775555555555555555555555550000000000060001111111111111111151111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc775555555555555555555555550000000000060001111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc775555555555555550555555500000000000060001111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccc775500005555555500555555600000000000006001111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccc775500005555555000555550000000000000006001111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccc77cccccccc7775500005555550000555500000000000000000001111111111111111111111111
cccccccccccccc7cccccccccccccccccccccccccccccccccc777777ccccc77775500005555500000555000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccc77777777777777775555555555000000550000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccc77777777777777755555555550000000500000000000000000000000007700000000000000000000
ccccccccccccccccccccccccccccccccccccccccc77ccc7700000000555555555555555500000000000000000000000000000000007700000000000000000000
ccccccccccccccccccccccccccccccccccccccccc77cc77700000000055555555555555000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccc77700000000005555555555550000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccc777770000000000555555555500000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccc777700000000000055555555000000000000000000000000000000000000000000000111111111111111
ccccccccccccccccccccccccccccccccccccccccccccc77700000000000005555550000000000000000000000000000000000000000000000111111111111111
ccccccccccccccccccccccccccccccccccccccccccccc77700000000000000555500000000000000000000000000000000000000000000000111111111111111
cccccccccccccccccccccccccccccccccccccccccccccc7700000000000000055000000000000000000000000000000000000000000000000111111111111111
cccccccccccccccccccccccccccccccccccccccccccccc7700000000000000000000000000000000000000000000000000000000000000000111111111111111
ccccccccccccccccccccccccccccccccccccccccccccc77700000000000000000000000000000000000000000000000000000000000000000111111111111111
ccccccccccccccccccccccccccccccccccccccccccccc77700000000000000000000000000000000000000000000000000006000000000000111111111111111
cccccccccccccccccccccccccccccccccccccccccccc777700000000000000000000000000000000000000000000000000000000000007000111111111111111
cccccccccccccccccccccccccccccccccccccccccccc777700000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccc77700000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccc77700000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccc7700000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000002020004020000000000000000000204000000030303030303030304040402020000000303030303030303040404020202020200001313131304040300020202020202000013131313040404020202020202020000131313130004040202020200000000001313131300000002020202000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
012800000c0700c5700c5600c5550c5400c5300c5200c5250c0700f5700f5600f5550f5400f5300f5200f5250c0700e5700e5500e5300e5750a5700a5500a5300a5550c5700c5700c5700c5700c5700c5750c500
491400200c05300000000000c0532461500000000000c0530c053000000c0530000024615000000c053246000c053246000c0000c0532461524600246000c0530c053246000c05324600246150c0000000024600
012800000c0300c7700c7600c7550c7400c5300c5200c525100300a7700a7600a7550a7400a5300a5200a525110300c7700c7500c7300c5250e7700e7500e7300e5550f7700f7500f7300f5400f5300f5250c500
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010c00000c0430c043020050c0430c043020050c043020050c043020053c615286050c043286053c615020050c0430c043020050c0430c043020050c043020050c043020053c615286053c615286052460502000
a10c00000717007160071500714007130071250914007140051600512500160001250216002125021600212507160071500714507125071600715007145071250016000150001450013500130001300013000130
a10c00000216002160021600214502140021450c1400c1450214002145021000e10002140021450c1000c10009140091450710009100071400714511100131000917009160091300912109170091600913009125
a10c0000071700716007150071400713007125091400914502160021500214002135021600215002140021350013100140001500016505131051400515005165071300714007150071650c1310c1400c1500c165
a10c00000517005160051600515005140051300216002155021500214002135021000215002140021350000000170001650014000135001200012500000000000017000165001400013500120001250000000000
001000202e750377502e730377302e720377202e71037710227502b750227302b7301d750247501d730247301f750277501f730277301f7202772029750307502973030730297203072029710307102971030710
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
050c0000135701f560135501f540135301f525155401f540115601d5250c560185250e5601a5250e5601a525135601f550135451f525135601f550135451f5250c560185500c545185350c530185300c53018530
050c00000e5601a5600e5601a5450e5401a5450c540185450e5401a5450e5001a5000e5401a5450c5001850015540215451350021500135401f545115001f5001557021560155302152115570215601553021525
050c0000135701f560135501f540135301f52515540215450e5601a5500e5401a5350e5601a5500e5401a5350c531185400c55018565115311d540115501d565135301f540135501f5650c531185400c55018565
050c0000115701d560115601d550115401d5300e5601a5550e5501a5400e5351a5000e5501a5400e535185000c570185650c540185350c520185250c500185000c570185650c540185350c520185250000000000
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
03 0a4a5644
01 0a0b4c44
00 0c0b4c44
02 0a0b0c44
01 12115244
00 13114c44
00 14114c44
00 15115144
00 12111844
00 13111944
00 14111a44
02 15111b44
03 0b5b5a44
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

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000