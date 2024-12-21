pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--winterglass

-- celeste classic
-- matt thorson + noel berry

-- "data structures"

function vector(x,y)
  return {x=x,y=y}
end

function rectangle(x,y,w,h)
  return {x=x,y=y,w=w,h=h}
end

-- [globals]

room,
objects,got_fruit,
freeze,shake,delay_restart,sfx_timer,music_timer,
screenshake,
time_ticking=
vector(0,0),
{},{},
0,0,0,0,0,
true,
true

-- [entry point]

function _init()
  title_screen()
end

function title_screen()
  frames,start_game_flash=0,0
  music(40,0,7)
  load_room(7,3)
end

function begin_game()
  max_djump,deaths,frames,seconds,minutes,music_timer=1,0,0,0,0,0
  music(0,0,7)
  load_room(0,0)
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
    x=rnd(128),
    y=rnd(128),
    spd=1+rnd(4),
    w=32+rnd(32)
  })
end

particles={}
for i=0,24 do
  add(particles,{
    x=rnd(128),
    y=rnd(128),
    s=flr(rnd(1.25)),
    spd=0.25+rnd(5),
    off=rnd(1),
    c=6+rnd(2),
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
      if this.djump<max_djump then
        psfx(54)
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
      local maxrun=2.0
      local accel=on_ground and 0.93 or 0.80
      local deccel=0.16

      -- set x speed
      this.spd.x=abs(this.spd.x)<=maxrun and
        appr(this.spd.x,h_input*maxrun,accel) or
        appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)

      -- facing direction
      if this.spd.x~=0 then
        this.flip.x=this.spd.x<0
      end

      -- y movement
      local maxfall=3.0

      -- wall slide
      if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) then
        maxfall=0.8
        -- wall slide smoke
        if rnd(10)<2 then
          this.init_smoke(h_input*6)
        end
      end

      -- apply gravity
      if not on_ground then
        this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.124 and 0.334 or 0.167)
      end

      -- jump
      if this.jbuffer>0 then
        if this.grace>0 then
          -- normal jump
          psfx(1)
          this.jbuffer=0
          this.grace=0
          this.spd.y=-3.36
          this.init_smoke(0,4)
        else
          -- wall jump
          local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
          if wall_dir~=0 then
            psfx(2)
            this.jbuffer=0
            this.spd=vector(-wall_dir*(maxrun+1.06),-3.36)
            if not this.is_ice(wall_dir*3,0) then
              -- wall jump smoke
              this.init_smoke(wall_dir*6)
            end
          end
        end
      end

      -- dash
      local d_full=6.58
      local d_half=4.6528

      if this.djump>0 and dash then
        this.init_smoke()
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
        psfx(3)
        freeze=2
        shake=6
        -- dash target speeds and accels
        this.dash_target_x=3.07*sign(this.spd.x)
        this.dash_target_y=(this.spd.y>=0 and 3.07 or 2.55)*sign(this.spd.y)
        this.dash_accel_x=this.spd.y==0 and 2.37 or 1.6758
        this.dash_accel_y=this.spd.x==0 and 2.37 or 1.6758
      elseif this.djump<=0 and dash then
        -- failed dash smoke
        psfx(9)
        this.init_smoke()
      end
    end

    -- animation
    this.spr_off+=0.25
    this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or  -- wall slide or mid air
      btn(⬇️) and 6 or -- crouch
      btn(⬆️) and 7 or -- look up
      1+(this.spd.x~=0 and h_input~=0 and this.spr_off%4 or 0) -- walk or stand

    -- exit level off the top (except summit)
    if this.y<-4 and level_index()<31 then
      next_room()
    end

    -- was on the ground
    this.was_on_ground=on_ground
  end,

  draw=function(this)
    -- clamp in screen
    if this.x<-1 or this.x>121 then
      this.x=mid(this.x,-1,121)
      this.spd.x=0
    end
    -- draw player hair and sprite
    set_hair_color(this.djump)
    draw_hair(this)
    draw_obj_sprite(this)
    --spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
    unset_hair_color()
  end
}

function create_hair(obj)
  obj.hair={}
  for i=1,5 do
    add(obj.hair,vector(obj.x,obj.y))
  end
end

function set_hair_color(djump)
  pal(8,djump==1 and 8 or djump==2 and 7+(frames\3)%2*4 or 12)
end

function draw_hair(obj)
  local last=vector(obj.x+4-(obj.flip.x and -1 or 1)*2,obj.y+(btn(⬇️) and 4 or 3))
  for i,h in pairs(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    circfill(h.x,h.y,mid(4-i,1,2),8)
    last=h
  end
end

function unset_hair_color()
  pal() -- use pal(8,8) to preserve other palette swaps
end

-- [other entities]

player_spawn={
  init=function(this)
    sfx(4)
    this.spr=3
    this.target=this.y
    this.y=128
    this.spd.y=-4
    this.state=0
    this.delay=0
    create_hair(this)
  end,
  update=function(this)
    -- jumping up
    if this.state==0 then
      if this.y<this.target+16 then
        this.state=1
        this.delay=3
      end
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
          sfx(5)
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
  draw=function(this)
    set_hair_color(max_djump)
    draw_hair(this)
    draw_obj_sprite(this)
    --spr(this.spr,this.x,this.y)
    unset_hair_color()
  end
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
        hit.spd.y=-10
        hit.djump=max_djump
        this.delay=10
        this.init_smoke()
        -- crumble below spring
        local below=this.check(fall_floor,0,1)
        if below then
          break_fall_floor(below)
        end
        psfx(8)
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

function break_spring(obj)
  obj.hide_in=15
end

balloon={
  init=function(this)
    this.offset=rnd(1)
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
        psfx(6)
        this.init_smoke()
        hit.djump=max_djump
        this.spr=0
        this.timer=60
      end
    elseif this.timer>0 then
      this.timer-=1
    else
      psfx(7)
      this.init_smoke()
      this.spr=22
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
      if this.check(player,0,-1) or this.check(player,-1,0) or this.check(player,1,0) then
        break_fall_floor(this)
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
        psfx(7)
        this.state=0
        this.collideable=true
        this.init_smoke()
      end
    end
  end,
  draw=function(this)
    if this.state~=2 then
      spr(this.state==1 and 26-this.delay/5 or 23,this.x,this.y)
    end
  end
}

function break_fall_floor(obj)
 if obj.state==0 then
  psfx(15)
    obj.state=1
    obj.delay=15--how long until it falls
    obj.init_smoke()
    local hit=obj.check(spring,0,-1)
    if hit then
      break_spring(hit)
    end
  end
end

smoke={
  init=function(this)
    this.spd=vector(0.3+rnd(0.2),-0.1)
    this.x+=-1+rnd(2)
    this.y+=-1+rnd(2)
    this.flip=vector(maybe(),maybe())
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
        sfx(14)
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
    sfx(13)
    got_fruit[level_index()]=true
    init_object(lifeup,this.x,this.y)
    destroy_object(this)
  end
end

lifeup={
  init=function(this)
    this.spd.y=-0.25
    this.duration=30
    this.x-=2
    this.y-=4
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
    ?"1000",this.x-2,this.y,7+this.flash%2
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
  sfx(16)
  init_object(fruit,this.x+ox,this.y+oy,26)
  destroy_object(this)
end

key={
  if_not_fruit=true,
  update=function(this)
    local was=flr(this.spr)
    this.spr=9.5+sin(frames/30)
    if this.spr==10 and this.spr~=was then
      this.flip.x=not this.flip.x
    end
    if this.player_here() then
      sfx(23)
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
      this.x=this.start-1+rnd(3)
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
        hit.move(this.x-this.last,0)
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
    this.text="-- celeste mountain --#     have a berry     "
    if this.check(player,4,0) then
      if this.index<#this.text then
       this.index+=0.5
        if this.index>=this.last+1 then
          this.last+=1
          sfx(35)
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
        sfx(37)
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
          x=1+rnd(14),
          y=0,
          h=32+rnd(32),
          spd=8+rnd(8)
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
      sfx(51)
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
      time_ticking = false
      rectfill(32,2,96,31,0)
      spr(26,55,6)
      ?"x"..this.score,64,9,7
      draw_time(49,16)
      ?"deaths:"..deaths,48,24,7
    elseif this.player_here() then
      sfx(55)
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
      rectfill(24,58,104,70,0)
      local level=level_index()
      if level==12 then
        ?"old site",48,62,7
      elseif level==31 then
        ?"summit",52,62,7
      else
        ?level.."00 m",level<10 and 54 or 54,62,7
      end
      draw_time(4,4)
    end
  end
}

psfx=function(num)
  if sfx_timer<=0 then
   sfx(num)
  end
end

-- [tile dict]
tiles={
  [1]=player_spawn,
  [8]=key,
  [11]=platform,
  [12]=platform,
  [18]=spring,
  [20]=chest,
  [22]=balloon,
  [23]=fall_floor,
  [26]=fruit,
  [28]=fly_fruit,
  [64]=fake_wall,
  [86]=message,
  [96]=big_chest,
  [118]=flag
}

-- [object functions]

function init_object(type,x,y,tile)
  if type.if_not_fruit and got_fruit[level_index()] then
    return
  end

  local obj={
    type=type,
    collideable=true,
    solids=false,
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

  function obj.move(ox,oy)
    for axis in all({"x","y"}) do
      obj.rem[axis]+=axis=="x" and ox or oy
      local amt=flr(obj.rem[axis]+0.5)
      obj.rem[axis]-=amt
      if obj.solids then
        local step=sign(amt)
        local d=axis=="x" and step or 0
        for i=1,abs(amt) do
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
  (obj.type.init or stat)(obj)

  return obj
end

function destroy_object(obj)
  del(objects,obj)
end

function kill_player(obj)
  sfx_timer=12
  sfx(0)
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
  if level==11 or level==21 or level==30 then -- quiet for old site, 2200m, summit
    music(30,500,7)
  elseif level==12 then -- 1300m
    music(20,500,7)
  end
  load_room(level%8,level\8)
end

function load_room(x,y)
  has_dashed,has_key=false,false
  --remove existing objects
  foreach(objects,destroy_object)
  --current room
  room.x,room.y=x,y
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
  if level_index()<31 and time_ticking then
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
      camera(-2+rnd(5),-2+rnd(5))
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
    obj.move(obj.spd.x,obj.spd.y);
    (obj.type.update or stat)(obj)
  end)

  -- start game
  if is_title() then
    if start_game then
      start_game_flash-=1
      if start_game_flash<=-30 then
        begin_game()
      end
    elseif btn(🅾️) or btn(❎) then
      music(-1)
      start_game_flash,start_game=50,true
      sfx(38)
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
    local c=start_game_flash>10 and (frames%10<5 and 7 or 10) or (start_game_flash>5 and 2 or start_game_flash>0 and 1 or 0)
    if c<10 then
      for i=1,15 do
        pal(i,c)
      end
    end
  end

  -- draw bg color (pad for screenshake)
  cls()
  rectfill(0,0,127,127,flash_bg and frames/5 or new_bg and 2 or 0)

  -- bg clouds effect
  if not is_title() then
    foreach(clouds,function(c)
      c.x+=c.spd
      crectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,new_bg and 14 or 1)
      if c.x>128 then
        c.x=-c.w
        c.y=rnd(120)
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
    crectfill(p.x,p.y,p.x+p.s,p.y+p.s,p.c)
    if p.x>132 then
      p.x=-4
      p.y=rnd(128)
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
    ?"z+x",58,80,5
    ?"maddy thorson",38,96,5
    ?"noel berry",44,102,5
  end

  -- summit blinds effect
  if level_index()==31 and objects[2].type==player then
    local diff=min(24,40-abs(objects[2].x-60))
    rectfill(0,0,diff,127,0)
    rectfill(127-diff,0,127,127,0)
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

function maybe()
  return rnd(1)<0.5
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
-->8
__draw=_draw
function _draw()
  __draw()
end
__gfx__
000000000000000000000000088888800000000000000000000000000000000000aaaaa0000aaa000000a0000007707770077700000060000000600000060000
000000000888888008888880888888880888888008888800000000000888888000a000a0000a0a000000a0000777777677777770000060000000600000060000
000000008888888888888888888ffff888888888888888800888888088f1ff1800a909a0000a0a000000a0007766666667767777000600000000600000060000
00000000888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8009aaa900009a9000000a0007677766676666677000600000000600000060000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff80000a0000000a0000000a0000000000000000000000600000006000000006000
0000000008fffff008fffff00033330008fffff00fffff8088fffff8083333800099a0000009a0000000a0000000000000000000000600000006000000006000
00000000003333000033330007000070073333000033337008f1ff10003333000009a0000000a0000000a0000000000000000000000060000006000000006000
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
57cc7cccc77ccc7570000000000cc0000000000770cc000700eeeeeeeeeeee0000000000000000000000000000000c00000000000d000d000000000000000000
77ccccccc77ccc7770c00000000cc00000000c0770000c0700eee222e22eee0000000000000000000000000000000c0000000000000000000000000000000000
777cccccccccc7777000000000000000000000077000000700eeeeeeeeeeee005555555506666600666666006600c00066666600066666006666660066666600
7777cc7777cc777770000000000000000000000770c0000700eeeeeeeeeeee00555555556666666066666660660c000066666660666666606666666066666660
777777777777777770000000c0000000000000077000000700ee77eee7777e005555555566000660660000006600000066000000660000000066000066000000
57777577775577757000000000000000000000077000c007077777777777777055555555dd000000dddd0000dd000000dddd0000ddddddd000dd0000dddd0000
000000000000000070000000000000000000000770000007007777005000000000000005dd000dd0dd000000dd0000d0dd000000000000d000dd0000dd000000
00aaaaaaaaaaaa00700000000000000000000007700c0007070000705500000000000055ddddddd0dddddd00ddddddd0dddddd00ddddddd000dd0000dddddd00
0a999999999999a0700000000000c00000000007700000077077000755500000000005550ddddd00ddddddd0ddddddd0ddddddd00ddddd0000dd0000ddddddd0
a99aaaaaaaaaa99a7000000cc0000000000000077000cc077077bb07555500000000555500000000000000000000000000000000000000000000000000000000
a9aaaaaaaaaaaa9a7000000cc0000000000c00077000cc07700bbb0755555555555555550000000000000c000000000000000000000000000000c00000000000
a99999999999999a70c00000000000000000000770c00007700bbb075555555555555555000000000000c00000000000000000000000000000000c0000000000
a99999999999999a700000000000000000000007700000070700007055555555555555550000000000cc0000000000000000000000000000000000c000000000
a99999999999999a07777777777777777777777007777770007777005555555555555555000000000c000000000000000000000000000000000000c000000000
aaaaaaaaaaaaaaaa07777777777777777777777007777770004bbb00004b000000400bbb00000000c0000000000000000000000000000000000000c000000000
a49494a11a49494a70007770000077700000777770007777004bbbbb004bb000004bbbbb0000000100000000000000000000000000000000000000c00c000000
a494a4a11a4a494a70c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb00000000c0000000000000000000000000000000000000001010c00000
a49444aaaa44494a70777ccccc777ccccc777c0770777c07040000000400bbb004000000000001000000000000000000000000000000000000000001000c0000
a49999aaaa99994a7777000007770000077700077777000704000000040000000400000000000100000000000000000000000000000000000000000000010000
a49444999944494a77700000777000007770000777700c0742000000420000004200000000000100000000000000000000000000000000000000000000001000
a494a444444a494a7000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
a49499999999494a0777777777777777777777700777777040000000400000004000000000010000000000000000000000000000000000000000000000000010
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c400000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000095a5b5c5d5e5f500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000096a6b6c6d6e6f600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009700000000e7f700000000
__label__
cccccccccccccccccccccccccccccccccccccc77000000000000000077cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc7770000000000000000777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc7770000000000000000777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc777700000000000000007777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc777700000000000000007777ccccccccccccccccccccccccccccccc77cccccc77cccccc77cccccccccccccc77ccc
ccccccccccccccccccccccccccccccccccccc7770000000000000000777cccccccccccccccccccccccccccccc777777cc777777cc777777cccccccccc777777c
ccccccccccccccccccccccccccccccccccccc7770000000000000000777ccccccccccccccccccccccccccccc777777777777777777777777cccccccc77777777
cccccccccccccccccccccccccccccccccccccc77000000000000000077cccccccccccccccccccccccccccccc777777777777777777777777cccccccc77777777
cccccccccccccccccccccccccccccccccccccc77000000000000000077cccccccccccccccccccccccccccc77077777777777777777777770777ccc7700000000
ccccccccccccccccccccccccccccccccccccc777000000000000000077cccccccc7cccccccccccccccccc777700007770000777000007777777cc77700000000
ccccccccccccccccccccccccccccccccccccc777000000000000000077cc7cccccccccccccccccccccccc77770cc777cccc777ccccc77707777cc77700000000
cccccccccccccccccccccccccccccccccccc7777000000000000000077cccccccccccccccccccccccccc777770c777cccc777ccccc777c0777ccc77700000000
ccc77cccccc77cccccc77ccccccccccccccc77771111111000000000777cccccccc77ccccccccccccccc777770777000077700000777000777cccc7700000000
c777777cc777777cc777777cccccccccccccc77711111110000000007777ccccc777777cccccccccccccc77777770000777000007770000777cccc7700000000
777777777777777777777777ccccccccccccc77711111110000000007777777777777777ccccccccccccc7777000000000000000000c0007777cc77700000000
777777777777777777777777cccccccccccccc7711111110000000005777777777777777cccccccccccccc777000000000000000600000075777777500000000
77777777777777777777777177cccccccccccc771111111000000000077777777777777077cccccccccccc777000000000000000000000070000000000000000
11117771111177711111777777cccccccccccc771111111000000000700007770000777777cccccccccccc777000000c00000000000000070000000000000000
ccc777ccccc777ccccc7770777cc7cccc77ccc77000000000000000070cc777cccc7770767cc7cccc77ccc7770000000000cc000000000070000000000000000
c6777ccccc777ccccc777c0777ccccccc77ccc77000000000000000070c777cccc777c0777ccccccc77ccc7770c00000000cc000000000070000000000000000
077700000777000007770007777cccccccccc77700000000000000007077700007770007777cccccccccc7777000000000000000000c00070000000000000000
7770000077700000777000077777cccccccc7777000000000000000077770000777000077777cccccccc77777000000000000066000000070000000000000000
0000000000000000000c00077777777777777777000000000000000070000000000c0007777777777777777770000000c0000066000000070000000000000000
00000000000000000000000757777777777777750000000000000000700000000000000757777777777777757000000000000000777777700000000000000000
00000770000000000000000077777777777777700000000000000000700000000000000077777777777777770000000000000007000000000000000000000000
000007700000000000000000000077700000777700000000000000007000000c0000000000007770000077700000000000000007000000000000000000000000
0000c0000000c000000cc000ccc777ccccc77707000000000000000070000000000cc000ccc777ccccc777cc000cc00000000007000000000000000000000000
c0000000c0000000000cc000cc777ccccc777c07000000000000000070c00000000cc000cc777ccccc777ccc000cc00000000c07000000000000000000000000
c0000000c00000000000000007770000077700070000000000000000700000000000000007770000077700000000000000000007000000000000000000000000
00000000000000000000000077700000777000070000000000000000700000000000000077700000777111111111111111111117111111111111111100000000
0000000000000000c000000000000000000c0007000000000000000070000000c00000000000000000011111c111111111111117111111111111111100000000
77777777777777770000000000000000000000070000000000000000700000000000000000000000000111111111111111111117111111111111111100000000
66656665666566657000000000000000000000070000000000000000700000000000000000000000000111111111111111111117111111111111111100000000
67656765676567657000000000000000000000070000000000000000700000000000000000000000000111111111111111111117111111111111111100000000
6770677067706770700000000000c000000000070000000000000000700000000000c0000000c0000001c1111111c11111111117111111111111111100000000
07000700070007007000000cc00000000000000700000000000000007000000cc0000000c0000000c0011111c111111111111117111111111111111100000000
07000700070007007000000cc0000000000c000700000000000000007000000cc0000000c0000000c0011111c1111111111c1117111161111111111100000000
000000000000000070c111111111111111111117111111111111111171c111111111111111100000000111111111111111111117111111111111111100000000
00000000000000007011111111111111111111171111111111111111711111111111111111100000000111111111111111111117111111111111111100000000
00000000000000000777777777777777777777711111111111111111177777777777777777777777777777777777777777777770000000000000000000000000
00000000000000006665666566656665666566651111111111111111666566656665666566656665000000000000000000000000000000000000000000000000
00000000000000006765676567656765676567651111111111111111676567656765676567656765000000000000000000000000000000000000000000000000
00000000000000006771677167716771677167711111111111111111677167716771677167706770000000000000000000000000000000000000000000000000
00000770000000000711171117111711171117111111111111111111171117111711171117107700000000000000000000000000000000000000000000000000
00000770000000000700070007000700070007000000000000000000070007000700070007007700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111100000000000000000000000
00000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111100000000000000000000000
00000000000000000000000000000070000000000000000000000000011111111111111111111111111111111111111111111111100000000000000000000000
00000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111100000000000000000000000
00000000000000001111111111111111111611111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000
00000000000000001111111111111111111111111111111111111111111111111111111111111111111116111111111111111111100000000000000000000000
00000000000000001111111111111111117111711171117111711171111111111111111111111111117111711171117111711171100000000000000000000000
00000000000000001111111111111111117111711171117111711171111111111111111111111111117111711171117111711171100000000000000000000000
00000000000000001111111111111111167716771677167716771677111111111111111111111111167706770677067706770677000000000000000000000000
00000000000000001111111111111111567656765676567656765676111111111111111111111111567656765676567656765676000000000000000000000000
00000000000000001111111111111111566656665666566656665666111111111111111111111111566656665666566656665666000000000000000000000000
00000000000000000000000000000666577777750777777777777777777777777777777777777777777777777777777777777777777777700000000000000000
00000000000000000000000000077776777777777000777000007770000077700000777000007770000077700000777000007770000077770000000000000000
000000000000000000000000000007667777777770c777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc777070000000000000000
00000000000000000000000000000055777cc77770777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc777c070000000000000000
0000000000000000000000000000066677cccc777777000007770000077700000777000007770000077700000777000007770000077700070000000000000000
0000000000000000000000000007777677cccc777770000077700000777000007770000077700000777000007770000077700000777000070000000000000000
0000000000000000000000000000076677c7cc777000000000000000000000000000000000000000000000000000000000000000000c00070000000000000000
0000000000000000000000000000005577cccc770777777777777777777777777777777777777777777777777777777777777777000000070000000000000000
0000000000000000000000000000066677cccccc7777777777777777777777777777777777777777777777777777777777777775700000070000000000000000
00000000000000000000000000077776777ccccc7777777777777777777777777777777777777777777777777777777777777777700c00070000000000000000
00000000000000000000111111111766777cccccc777777cc777777cc777777cc777777cc777777cc777777cc777777ccccc7777700000070000000000000000
000000000000000000001111111111557777ccccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccccc7777000cc070000000000000000
000000000000000000001111111116667777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777000cc070000000000000000
11111111111111111111111111177776777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc7770c000070000000000000000
11111111111111111111111111111766777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77700000070000000000000000
1111111111111111111111111111115577cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77077777700000000000000000
1111111111111111111111111111166677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777750000000000000000
1111111111111111111111111117777677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777771111111111111111
1111111111111111111111111111176677cc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccc77771111111111111111
1111111111111111111111111111116677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7771111111111711171
11111111111111111111111111111666777cccccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccc77cccccccc7771111111111711171
111111111111111111111111111777767777ccccc777777cc777777cc777777cc777777cc777777cc777777cc777777cc777777c7ccc77771111111116771677
00000000000000000000000000000766777777777777777777777777777777777777777777777777777777777777777777777777777777770000000056765676
00000000000000000000000000000055577777777777777777777777777777777777777777777777777777777777777777777777777777750000000056665666
00000000000000000000000000000000666566656665666566656665666566656665666566656665666566656665666566656665666566650000000057777777
00000000000000000000000001111111676567656765676567656765676567656765676567656765676567656766676567656765676567650000000077777777
0000000000000000000000000111111167716771677167716771677167716771677167716771677167716771677167716770677167716771111111117777cccc
000000000000000000000000011111111711171117111711171117111711171117111711171117111711171117111711170017111711171111111111777ccccc
00000000000000000000000001111111171117111711171117111711171117111711171117111711171117111711171117001711171117111111111177cccccc
00000000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111110001111111111111111111177cc77cc
00000000000000000000000001111111111111111111111111111111111111111111111111111166111111111111111110001111111111111111111177cc77cc
00000000000000000000000001111111111111111111111111111111111111111111111111111166111111111111111110001111111111111111111177cccccc
00000000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000077cccccc
000000008888888000000000011111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000777ccccc
000000088888888800000000011111111111111111111111111111111111111111111111111111111111711111111111100000000000000000000000777ccccc
00000008888ffff8000000000111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000007777cccc
0000000888f1ff18000000000000000660000000001111111111111111111111111111111111111111111111100000000000000000000000000000007777cccc
0000000088fffff000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777ccccc
000000000833330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777ccccc
00000000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077cccccc
00000000577777750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077cccccc
000000007777777700ee0ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077cccccc
000000007777777700eeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077cc7ccc
00000000777cc777000e8e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077cccccc
0000000077cccc7700eeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777ccccc
0000000077cccc7700ee3ee000000000000000000000000000000000000000000000000000000000000000000300b0b00000000000000000000000007777cccc
0000000077c7cc770000b0000000000700000000000000000000000000000000000000000000000000000000003b330000000000000000000000000077777777
0000000077cccc770000b00000000000000000000000000000000011111111111111111111111111111111111288882111111111110000000000000057777777
0000000077cccccc7777777500000000000000000777777000000011111111111111111111111111111111111898888111111111110000000000000066656665
00001111777ccccc7777777711111111111110007777777700000011111111111111111111111111111111111888898111111111110000000000000067656765
00001111777ccccccccc777711111111111110007777777700000011111111111117111111111111111111111889888111111111110000000000000067706770
000011117777ccccccccc77711111111111110007777337700000011111111111111111111111111111111111288882111111111110000000000000007000700
000011117777cccccccccc7711111111111110007777337700000011111111111112eeee6eee2111111111111128821111111111110000000000000007000700
00001111777cccccccc7cc771111111111111000737733370000001111111111112eeeeeeeeee211111111111111111111111111110000000000000000000000
00001111777ccccccccccc7711111111111110007333bb37000000111111111111eeeeeeeeeeee11111111111111111111111111110000000000000000000000
0000111177cccccccccccc7711111111111110000333bb30000000000000000000e22222e2e22e00000000000000000000000000000000000000000000000000
0000111177cccccccccccc77111111111111100003333330000000000000000000eeeeeeeeeeee00000000000000000000000011111111111111111111111111
00001111777cccccccccc777111111111111100003b33330000000000000000000e22e2222e22e00000000000000000000000011111111111111111111111111
00001111777cccccccccc777111111111111100003333330000000300000000000eeeeeeeeeeee00000000000000000000000011111111111111111111111111
000011117777cccccccc777711111111111110000333b330000000b00000000000eee222e22eee00000000000000000000000011111111111111111111111111
000000007777cccccccc777700000000000000000033330000000b300000000000eeeeeeeeeeee00000000000000000000000011111111111111111111111111
00000000777cccccccccc77700000000000000000004400003000b000000000000eeeeeeeeeeee00000000000000000000000000000000000000000000000000
00000000777cccccccccc77700000000000000000004400000b0b3000000000000ee77eee7777e00000000000000000000000000000000000000000000000000
0000000077cccccccccccc7700000000000000000099990000303300000000000777777777777770000000000000000000000000000000000000000000000000
0000000077cccccccccccc7700000000000000000777777777777777777777777777777777777777777777777777777777777770000000000000000000000000
00000000777cccccccccc77700000000000000007000077700007770000077700000777000007770000077700000777000007777000000000000000000000000
00000000777cccccccccc777000000000000000070cc777cccc777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc77707000000000000000000000000
000000007777cccccccc7777000000000000000070c777cccc777ccccc777ccccc777ccccc777ccccc777ccccc777ccccc777c07000000000000000000000000
000000007777cccccccc777700000000000000007077700007770000077700000777000007770000077700000777000007770007000000000000000000000000
00000000777cccccccccc77700000000000000007777000077700000777000007770000077700000777000007770000077700007000000000000000000000000
00000000777cccccccccc777000000000000000070000000000000000000000000000000000000000000000000000000000c0007000000000000000000000000
0000000077cccccccccccc7700000000000000007000000000000000000000000000000000000000000000000000000000000007000000000000000000000000

__gff__
0000000000000000000000000000000004020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202020200001313131302020302020202020002000013131313020204020202020202020000131313130004040202020202020200001313131300000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
25252525260000242525253232322532000000005253636363636363636353530000000000000000000000000000000032323232323225252525260000005253535353535353536400000052535353535354000052636363636353536363635300000000000000000000003b302b1b3b00000000000000000000000000000000
32323225260000313225264243443700000000006264000000000000003b5253000000000000000000000000000000001b1b1b1b1b1b312525252523000052535363636353535400000042535353536353542b3b552b0011000062641b1b1b5200000000000000000000003b302b013b00000000000000000000000000000000
43434431330000424431335253640000000000001b1b0000001111001600525300000000000000000000000000000000001a000000001b313232323300005253541b1b3b52536400424353535353640053542b3b652b3b752b00001b0000005200000000000000000000003b302b173b00000000000000000000000000000000
6363534344000052534343535400000000160011110000001142442b0000525300000000000000000000000000000000000000000000001b1b1b1b1b00425353542b003b52540000625353536364000053542b000000001b000000000000115200000000000000000000003b302b002100000000000000000000000000000000
1b1b626364000062636363636400000000003b42442b003b42535400003b52530000001100000000000000000000000000111111000000160000000000525363542b111152540000006263540000001153642b3b7500001100000000003b425300000000000000000000003b302b002400000000000000000000000000000000
00001b1b1b00001b1b1b00000000000000000052542b003b52535400003b52530000004512000000000000000000000011212236110000111111112123526400534373435364000000003b552b001172542b00001b00004511000000003b626300000000000000000000003b302b003100000000000000000000000000000000
0000000011111100000011111100000000000052542b003b5253542b00005253000000524411111100110000110000003532334244000042434344242665000053642762641b000016003b6500007521642b00000011116243442b00003b212200000000000000000000003b302b003b2c000000000000000000000000002c00
0000003b27727373737373737344000000000052542b003b5253540000005253000000525343434400451111450000001b1b1b62640000526353543133000000642125232b0011111111001b00452132000000003b21222352542b00163b312500000000000000000000003b302b00213c000000000000000000000000003c3f
0000003b24222222222222222365000000000052542b003b52535400003b52530000006263636363736373736400001100000000000011551b62637400000001222525332b3b343535362b0000553042000000000031252662642b0000003b24000000002c0000000012003b302b0031230100000000000000000000003d2122
0000003b31323232323232323236001100000052542b003b5253542b0000525300000000003b3435353535362b00004200001100000072642b1b1b1b000000212532332b00001b1b1b1b0000005530520000000000003125232b000000003b310000003d3c0000000027003b302b003b25230000000000000000000000212525
000000001b1b1b1b1b1b1b1b1b1b002100003b62642b003b6263542b000062630000000000001b1b1b1b1b1b00000052003b200000001b1b0000000000000024260000001100000000000000005530620000000000000031332b00000000000000000021233f00212233003b302b003b25263d00000000000000002122252525
000100000000000000000000000000240000001b1b0000001b3b6500000000000000000000000000160000000000115211111b000000000000000000002c3d24260001002711000011000000006531220000000000000000000000000000000000000031252222253300003b302b002125252300000000000000212525252525
00273e00000000000000000000000031000000000000111111001b00000000003e01000000111111110011111142435322232b000000001100001100003c212526001700374500002000000000007531000000000000000000000000000100003e010000313232330000003b302b003125252600000000003f21252525252525
00242300002c00004647001a0000001b00000000000042434400000000002c00223600003b343535362b72434353535332332b00000000202b00202b00212525330000004254003b45110000000000720000000000000000000000002122233e22230000000000000000003b302b003b252525233e3d763e2125252525252525
00242600003c3f005657000000000000004243434400525364000000013f3c0033000000001b1b1b1b001b52535353531b1b00000000001b00001b00002425250000000052542b1152440000000000000000000000000000000000003132252225253600000000000000003b302b002125252525222222222525252525252525
00242600004243434343434344000000005253535400525400004243434344000000000000000000000000525353535300000000000000000000000000242525000000005253434353540000000000000000000000000000000000000000242525260000000000000000003b302b002425252525252525252525252525252525
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

