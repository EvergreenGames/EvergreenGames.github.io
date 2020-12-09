pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--~classicnet~
--by rubyred

--original game by:
--matt thorson + noel berry
--evercore by: taco360
--pico8com by: neapolita

-- [data structures]

function vector(x,y)
  return {x=x,y=y}
end

function rectangle(x,y,w,h)
  return {x=x,y=y,w=w,h=h}
end

-- [globals]

objects,got_fruit,
freeze,delay_restart,sfx_timer,music_timer,
ui_timer,pid,lvl_id,show_menu=
{},{},
0,0,0,0,-99,-1,0,false

DEBUG=""

-- [entry point]

function _init()
  serial(0x804, 0x5300, 3) --read encoding info
  if peek(0x5300)~=0 then
    update_omsgs=update_omsgs_stdl
    update_imsgs=update_imsgs_stdl
  end
  poke(0x5f2d, 1)
  frames,start_game_flash=0,0
  send_msg("cartload","")
  music(40,0,7)
  load_level(0)
end

function begin_game()
  max_djump,deaths,frames,seconds,minutes,music_timer,time_ticking=1,0,0,0,0,0,true
  music(0,0,7)
  if tonum(username) then username = "_"..username end
  load_level(1)
end

function is_title()
  return lvl_id==0
end

-- [effects]

function rnd128()
  return rnd(128)
end

clouds={}
for i=0,16 do
  add(clouds,{
    x=rnd128(),
    y=rnd128(),
    spd=1+rnd(4),
    w=32+rnd(32)
  })
end

particles={}
for i=0,24 do
  add(particles,{
    x=rnd128(),
    y=rnd128(),
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
    if spikes_at(this.x+this.hitbox.x,this.y+this.hitbox.y,this.hitbox.w,this.hitbox.h,this.spd.x,this.spd.y)
	   or	this.y>lvl_ph then
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
        this.flip.x=(this.spd.x<0)
      end

      -- y movement
      local maxfall=2
    
      -- wall slide
      if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) then
        maxfall=0.4
        -- wall slide smoke
        if rnd(10)<2 then
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
          psfx(1)
          this.jbuffer=0
          this.grace=0
          this.spd.y=-2
          this.init_smoke(0,4)
        else
          -- wall jump
          local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
          if wall_dir~=0 then
            psfx(2)
            this.jbuffer=0
            this.spd.y=-2
            this.spd.x=-wall_dir*(maxrun+1)
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
        psfx(3)
        freeze=2
        -- dash target speeds and accels
        this.dash_target_x=2*sign(this.spd.x)
        this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
        this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
        this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
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
    
   	--move camera to player
   	--this must be before next_level
   	--to avoid loading jank
    move_camera(this)
    
    -- exit level off the top (except summit)
    if this.y<-4 and levels[lvl_id+1] and lvl_topexit then
      next_level()
    end
    
    -- was on the ground
    this.was_on_ground=on_ground

    if tonum(username) then username = "_"..username end
    send_msg("update",this.x..","..this.y..","..this.spr..","..this.djump..","..(this.flip.x and 1 or 0)..","..this.dash_time..","..this.spd.x..","..this.spd.y, 0)
  end,
  
  draw=function(this)
    -- clamp in screen
  		if this.x<-1 or this.x>lvl_pw-7 then
   		this.x=clamp(this.x,-1,lvl_pw-7)
   		this.spd.x=0
  		end
    -- draw player hair and sprite
    set_hair_color(this.djump)
    draw_hair(this,this.flip.x and -1 or 1)
    spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
    unset_hair_color()
    print(username, this.x+4-(#username*2), this.y-6, 7)
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

function draw_hair(obj,facing)
  local last=vector(obj.x+4-facing*2,obj.y+(btn(⬇️) and 4 or 3))
  for i,h in pairs(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    circfill(h.x,h.y,clamp(4-i,1,2),8)
    last=h
  end
end

function unset_hair_color()
  pal(8,8)
end

extern_player={
  init=function (this)
    this.dash_time=0
    this.solids=true
    this.persist=true
    create_hair(this)
  end,
  update=function(this)
    if this.dash_time > 0 then
      this.init_smoke()
    end
    this.spd.y=appr(this.spd.y,2,abs(this.spd.y)>0.15 and 0.21 or 0.105)
  end,
  draw=function(this)
    -- draw player hair and sprite
    set_hair_color(this.djump)
    draw_hair(this,this.flip.x and -1 or 1)
    spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
    unset_hair_color()
    print(this.name, this.x+4-(#(this.name)*2), this.y-6, 7)
  end
}

-- [other entities]

player_spawn={
  init=function(this)
    sfx(4)
    this.spr=3
    this.target=this.y
    this.y=min(this.y+48,lvl_ph)
		cam_x=clamp(this.x,64,lvl_pw-64)
		cam_y=clamp(this.y,64,lvl_ph-64)
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
    move_camera(this)
  end,
  draw=function(this)
    set_hair_color(max_djump)
    draw_hair(this,1)
    spr(this.spr,this.x,this.y)
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
        hit.spd.y=-3
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
      spr(13+this.offset*8%3,this.x,this.y+6)
      spr(this.spr,this.x,this.y)
    end
  end
}

fall_floor={
  init=function(this)
    this.state=0
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
      if this.state~=1 then
        spr(23,this.x,this.y)
      else
        spr(26-this.delay/5,this.x,this.y)
      end
    end
  end
}

function break_fall_floor(obj)
 if obj.state==0 then
  psfx(15)
    obj.state=1
    obj.delay=15
    obj.init_smoke()
    local hit=obj.check(spring,0,-1)
    if hit then
      hit.hide_in=15
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
    this.step=0.5
    this.sfx_delay=8
  end,
  update=function(this)
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
    else
      this.step+=0.05
      this.spd.y=sin(this.step)*0.5
    end
    check_fruit(this)
  end,
  draw=function(this)
    draw_obj_sprite(this)
    for ox=-6,6,12 do
      spr(has_dashed or sin(this.off)>=0 and 45 or (this.y>this.start and 47 or 46),this.x+ox,this.y-2,1,1,ox==-6)
    end
  end
}

function check_fruit(this)
  local hit=this.player_here()
  if hit then
    hit.djump=max_djump
    sfx_timer=20
    sfx(13)
    got_fruit[lvl_id]=true
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
    sspr(0,32,16,16,this.x,this.y)
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
    if this.x<-16 then this.x=lvl_pw
    elseif this.x>lvl_pw then this.x=-16 end
    if not this.player_here() then
      local hit=this.check(player,0,-1)
      if hit then
        hit.move(this.x-this.last,0,1)
      end
    end
    this.last=this.x
  end,
  draw=function(this)
    spr(11,this.x,this.y-1,2,1)
  end
}

world_portal={
  load_index=1,
  init=function(this)
    if levels_objectdata[lvl_id] then
      this.destination = split(levels_objectdata[lvl_id])[world_portal.load_index]
      world_portal.load_index+=1
    end
  end,
  draw=function(this)
    this.text=split(levels[this.destination])[5].."#down + dash to travel"
    if this.check(player,4,0) then
      if btn(3) and btn(5) then
        load_level(this.destination)
      end
      if this.index<#this.text then
       this.index+=0.5
        if this.index>=this.last+1 then
          this.last+=1
          sfx(35)
        end
      end
      local _x,_y=round(cam_x)-64+8,round(cam_y)-64+96
      for i=1,this.index do
        if sub(this.text,i,i)~="#" then
          rectfill(_x-2,_y-2,_x+7,_y+6 ,7)
          ?sub(this.text,i,i),_x,_y,0
          _x+=5
        else
          _x=round(cam_x)-64+8
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
    this.x+=5
    this.score=0
    for _ in pairs(got_fruit) do
      this.score+=1
    end
  end,
  draw=function(this)
    this.spr=118+frames/5%3
    draw_obj_sprite(this)
    if this.show then
      rectfill(32,2,96,31,0)
      spr(26,55,6)
      ?"x"..this.score,64,9,7
      draw_time(49,16)
      ?"deaths:"..deaths,48,24,7
    elseif this.player_here() then
      sfx(55)
      sfx_timer,this.show,time_ticking=30,true,false
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
  [86]=world_portal,
  [96]=big_chest,
  [118]=flag
}

-- [object functions]

function init_object(type,x,y,tile)
  if type.if_not_fruit and got_fruit[lvl_id] then
    return
  end

  local obj={
    type=type,
    collideable=true,
    solids=false,
    spr=tile,
    flip=vector(false,false),
    x=x,
    y=y,
    hitbox=rectangle(0,0,8,8),
    spd=vector(0,0),
    rem=vector(0,0),
  }

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
    return tile_flag_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h,flag)
  end

  function obj.check(type,ox,oy)
    for other in all(objects) do
      if other and other.type==type and other~=obj and other.collideable and
        other.x+other.hitbox.x+other.hitbox.w>obj.x+obj.hitbox.x+ox and 
        other.y+other.hitbox.y+other.hitbox.h>obj.y+obj.hitbox.y+oy and
        other.x+other.hitbox.x<obj.x+obj.hitbox.x+obj.hitbox.w+ox and 
        other.y+other.hitbox.y<obj.y+obj.hitbox.y+obj.hitbox.h+oy then
        return other
      end
    end
  end

  function obj.player_here()
    return obj.check(player,0,0)
  end
  
  function obj.move(ox,oy,start)
    for axis in all({"x","y"}) do
      obj.rem[axis]+=axis=="x" and ox or oy
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

  function obj.init_smoke(ox,oy) 
    init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),29)
  end

  add(objects,obj)

  if obj.type.init then
    obj.type.init(obj)
  end

  return obj
end

function destroy_object(obj)
  del(objects,obj)
end

function kill_player(obj)
  sfx_timer=12
  sfx(0)
  deaths+=1
  destroy_object(obj)
  dead_particles={}
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

-- [room functions]


function next_level()
  local next_lvl=lvl_id+1
  if next_lvl==3 then
    music(30,500,7)
  elseif next_lvl==2 then
    music(20,500,7)
  end
  load_level(next_lvl)
end

function load_level(lvl)

  has_dashed=false
  has_key=false
  
  foreach(objects,function(o)
    if not o.persist then
      destroy_object(o)
    end
  end)

  world_portal.load_index=1 --this is bad
  
  cam_spdx=0
	cam_spdy=0
		
  local diff_room=lvl_id~=lvl

  if diff_room then
    send_msg("room",username..","..lvl)
    foreach(objects,destroy_object)
    clients={}
  end
  
  lvl_id=lvl

  if diff_room and lvl_id==30 then
      max_djump,deaths,frames,seconds,minutes,music_timer,time_ticking=1,0,0,0,0,0,true
  end
  
  local tbl=get_lvl()
  lvl_x,lvl_y,lvl_w,lvl_h,lvl_title,lvl_topexit=tbl[1],tbl[2],tbl[3]*16,tbl[4]*16,tbl[5],tbl[6]==1
  lvl_pw=lvl_w*8
  lvl_ph=lvl_h*8
  
  
  --reload map
  --level title setup
  if not is_title() then
   if diff_room then reload() end 
  	ui_timer=5
  end
  
  if diff_room and get_data() then
  	for i=0,get_lvl()[3]-1 do
      for j=0,get_lvl()[4]-1 do
        replace_room(lvl_x+i,lvl_y+j,get_data()[i*get_lvl()[4]+j+1])
      end
  	end
  end
  
  for tx=0,lvl_w-1 do
    for ty=0,lvl_h-1 do
      local tile=mget(lvl_x*16+tx,lvl_y*16+ty)
      if tiles[tile] then
        init_object(tiles[tile],tx*8,ty*8,tile)
      end
    end
  end

end

-- [main update loop]

function _update()
  poke(0x5f30,1)
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
    obj.move(obj.spd.x,obj.spd.y,0)
    if obj.type.update then
      obj.type.update(obj)
    end
  end)
  
  -- start game
  if is_title() then
    if start_game then
      start_game_flash-=1
      if start_game_flash<=-30 then
        begin_game()
      end
    elseif btn(2) and pid ~= -1 then
      music(-1)
      start_game_flash,start_game=50,true
      sfx(38)
    end
    if stat(30) then
      local c = stat(31)
      if c=="p" then poke(0x5f30,1) end
      if c=="\b" then
        username = sub(username, 1, #username-1)
      elseif c ~= "," and ord(c) > 31 and ord(c) < 126 and #username < 18 then
        username = username..c
      end
    end
  else
    if stat(30) then
      local c = stat(31)
      if c=="\t" then
        show_menu=not show_menu
      end
      if c=="r" and show_menu then
        load_level(1)
      end
    end
  end
end

-- [drawing functions]

function _draw()
  if freeze>0 then
    return
  end
  
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
		
  local camx=is_title() and 0 or round(cam_x)-64
  local camy=is_title() and 0 or round(cam_y)-64
  camera(camx,camy)

  local xtiles=lvl_x*16
  local ytiles=lvl_y*16
  
  -- draw bg color
  cls(flash_bg and frames/5 or new_bg and 2 or 0)

  -- bg clouds effect
  if not is_title() then
    foreach(clouds, function(c)
      c.x+=c.spd-cam_spdx
      rectfill(c.x+camx,c.y+camy,c.x+c.w+camx,c.y+16-c.w*0.1875+camy,new_bg and 14 or 1)
      if c.x>128 then
        c.x=-c.w
        c.y=rnd(120)
      end
    end)
  end

		-- draw bg terrain
  map(xtiles,ytiles,0,0,lvl_w,lvl_h,4)
		
		-- platforms
  foreach(objects, function(o)
    if o.type==platform then
      draw_object(o)
    end
  end)
		
  -- draw terrain
  map(xtiles,ytiles,0,0,lvl_w,lvl_h,2)
  
  -- draw objects
  foreach(objects, function(o)
    if o.type~=platform then
      draw_object(o)
    end
  end)
  
  foreach(particles, function(p)
    p.x+=p.spd-cam_spdx
    p.y+=sin(p.off)-cam_spdy
    p.off+=min(0.05,p.spd/32)
    rectfill(p.x+camx,p.y%128+camy,p.x+p.s+camx,p.y%128+p.s+camy,p.c)
    if p.x>132 then 
      p.x=-4
      p.y=rnd128()
   	elseif p.x<-4 then
     	p.x=128
     	p.y=rnd128()
    end
  end)
  
  foreach(dead_particles, function(p)
    p.x+=p.dx
    p.y+=p.dy
    p.t-=0.2
    if p.t<=0 then
      del(dead_particles,p)
    end
    rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14+5*p.t%2)
  end)
  
  if ui_timer>=-30 then
  	if ui_timer<0 then
      draw_level_title(camx,camy)
  	end
  	ui_timer-=1
  end

  if not connected and not is_title() then
    ?"not connected",camx+1,camy+120,8
  end
  if show_menu then draw_ui(camx,camy) end
  
  if is_title() then
		sspr(72,32,56,32,36,32)
    ?"evergreen games presents",16,10,6
    ?"⬆️ to start",44,80,5
    ?"matt thorson",42,96,5
    ?"noel berry",46,102,5
    local unstr = "username: "..username
    ?unstr,46-(#username*2),110,7
    if frames%30<15 then
      local x = 66+(#unstr*2)
      line(x, 109, x, 115, 7)
    end
  end
  update_msgs() -- maybe shouldn't be in draw
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

function draw_ui(camx,camy)
  ?DEBUG,camx+1,camy+112,7
  rectfill(camx+0, camy+0, camx+70, camy+16, 0)
  local ecount=0
  for v in all(objects) do
    if v.type==extern_player then ecount+=1 end
  end
  ?"players: "..(ecount+1),camx+1,camy+1,7
  ?"press r to reset",camx+1,camy+8,7
end

function draw_level_title(camx,camy)
 rectfill(24+camx,58+camy,104+camx,70+camy,0)
 local title=lvl_title
 if title then
  ?title,hcenter(title,camx),62+camy,7
 end
 if lvl_id >=30 and lvl_id <= 60 then
  draw_time(4+camx,4+camy)
  end
end

function two_digit_str(x)
  return x<10 and "0"..x or x
end

-- [helper functions]

function round(x)
  return flr(x+0.5)
end

function clamp(val,a,b)
  return max(a,min(b,val))
end

function appr(val,target,amount)
  return val>target and max(val-amount,target) or min(val+amount,target)
end

function sign(v)
  return v~=0 and sgn(v) or 0
end

function maybe()
  return rnd(1)<0.5
end

function hcenter(s,camx)
  return (64-#s*2)+camx
end

function tile_flag_at(x,y,w,h,flag)
  for i=max(0,x\8),min(lvl_w-1,(x+w-1)/8) do
    for j=max(0,y\8),min(lvl_h-1,(y+h-1)/8) do
      if fget(tile_at(i,j),flag) then
        return true
      end
    end
  end
end

function tile_at(x,y)
  return mget(lvl_x*16+x,lvl_y*16+y)
end

function spikes_at(x,y,w,h,xspd,yspd)
  for i=max(0,x\8),min(lvl_w-1,(x+w-1)/8) do
    for j=max(0,y\8),min(lvl_h-1,(y+h-1)/8) do
      local tile=tile_at(i,j)
      if (tile==17 and ((y+h-1)%8>=6 or y+h==j*8+8) and yspd>=0) or
         (tile==27 and y%8<=2 and yspd<=0) or
         (tile==43 and x%8<=2 and xspd<=0) or
         (tile==59 and ((x+w-1)%8>=6 or x+w==i*8+8) and xspd>=0) then
         return true
      end
    end
  end
end

-->8
--lvl data

--"x,y,w,h,title,top exit"
levels={
	[0]="-1,-1,1,1",
  [1]="4,0,3,2,og classicnet world",
	[2]="0,0,4,4,sparky's world",
  [3]="0,0,3,2,snek's world",
  [30]="0,0,1,1,100m,1",
  [31]="1,0,1,1,200m,1",
  [32]="2,0,1,1,300m,1",
  [33]="3,0,1,1,400m,1",
  [34]="4,0,1,1,500m,1",
  [35]="5,0,1,1,600m,1",
  [36]="6,0,1,1,700m,1",
  [37]="7,0,1,1,800m,1",
  [38]="0,1,1,1,900m,1",
  [39]="1,1,1,1,1000m,1",
  [40]="2,1,1,1,1100m,1",
  [41]="3,1,1,1,old site,1",
  [42]="4,1,1,1,1300m,1",
  [43]="5,1,1,1,1400m,1",
  [44]="6,1,1,1,1500m,1",
  [45]="7,1,1,1,1600m,1",
  [46]="0,2,1,1,1700m,1",
  [47]="1,2,1,1,1800m,1",
  [48]="2,2,1,1,1900m,1",
  [49]="3,2,1,1,2000m,1",
  [50]="4,2,1,1,2100m,1",
  [51]="5,2,1,1,2200m,1",
  [52]="6,2,1,1,2300m,1",
  [53]="7,2,1,1,2400m,1",
  [54]="0,3,1,1,2500m,1",
  [55]="1,3,1,1,2600m,1",
  [56]="2,3,1,1,2700m,1",
  [57]="3,3,1,1,2800m,1",
  [58]="4,3,1,1,2900m,1",
  [59]="5,3,1,1,3000m,1",
  [60]="6,3,1,1,summit,0",
}

--refactor
levels_objectdata={
  [1]="2,30,3",
  [2]="1",
  [3]="1",
  [41]="1",
  [60]="1"
}

--rooms separated by commas
mapdata={
  [3]="260000000000000000000000000000002600000027000000000000000000000026120000300000000000000000000000253600003000000000000000000000002600000030464700000000000000000026000000305657003d3e0000000000002600000031353535353535353600000026000000001600000000000000000000260000000000000000000000000000002611111111000011111111112700000025353535360000213535353526000000261b1b1b1b00003000000000370000002600000000000030000000000000000026000011111111300000000000000000260000343535353235360000343535352600001b1b1b1b1b1b1b000000000000,26000000000000000000000000000000260000110000000000000000000000002611112700000000000000000000000032353526000000000000000011111111000000300000000000000000212222221c0000300000000000000000313232330000003000000000000000001b1b1b1b000011300000000000000000000000000000212611000000000000001111111100003132362b0000000000002122222300001b1b1b0000000000000024202526000000000000000000000000242520263535362b0000002136000000313232331b1b1b000000003700000000000000000000000000000000000000000000000000000000000000000000000000000000,000000000020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111110000000000000000000000212222353600000000000000000000003125262b0000000000000027000000000024262b0000000000000037000000000024262b0000000000000000000000000024262b000000000000000000000000002425222222232b0000002700000000002425323232332b00002130000000000024261b1b1b1b000000313000000000002426000000000000003b3000000000002426000000000000003b3300000000002425222300000000003b0000000000003132323300000000003b,0000000100001b1b1b1b00000000003b00000027000000000000000000000000000000300000000016000000000000001111113011111111111111000000111135353532353535352222232b0000343500000000000000003125262b0000000000000000000000000024262b0000000000000000000000000031332b000000000016000000000000001b1b000000111100000000000000000000000000002122000000000000000000000000000024250000000000000000000000000000242500000000000034360000000000003132000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000232b0000000000000000000000000000262b0000000000000000000000000000302b0000000000000000000000000000302b0000000000000000000000000000302b000000000000000000000000000030111111212300000000000000000000,313535353233000000000000000000001b1b1b1b1b1b000000000000000000000000000000000000000000000000000011111111000000000000000000000000353535360000000000000000000000000000000000000000212300000000000000000000000040412426000000000000000000000000501a24260000000000001111111100000000242600000000000022222223000000003126000000000000252525263d3d123d3d300000000000002525252522222222223300000000000032323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  [30]="2331252548252532323232323300002425233132323233290000282900000024252523201028380000002a0000003d243232332828282900000000003f2020242340283828293a283900000034352225263a2828281028290000000000003125252235353628280000000000003a2824253338282829000000000000002838242600002a28000000003a283a28282824330000002867580000281028283422250000003a2828383e3a282828382824250000002838282821232800002a28242500013a2123282a313329001111112425222222252629002123111121222225252548252526111124252222252525482525252525252222252525252525252525",
  [31]="252624252526313232322526282828242526313232332828002824262a102824252523201028292900282426003a38244825262828290000002a243300002a242548262900000000000030000000002425323300000000110000370000003e2426003d003a390027000000000000212525232020102900303900000000582448252522232839003728583900682831322525482628286720282828382828212248252526002a282729002a282834322532322526003a2830000000002a282824002831263a3829300000000000002a31002a3837282900301111110000003a2800012a2828673f24222223000000382822222222222222252548266758682828",
  [32]="25252525252532332838282831252525254825252526002a282829281024482525252548253300002900002a003125252532252526000000000000000000312533003125333d3f00000000000000003100000037212223000000000000000000001a000024252611111111000000002c0000003a31323235353536675800003c0000002828282828202028282839212200003a283828102900002a28382824250000002a28282800000000281028242500000000002a281111111128282824480000000000002834222236292a00242500013f0000002a282426290000002425222223000012002a242600000012242525482600002700002426000000212525",
  [33]="323232323300000031323232323232322828282900000000282829000000000028382900003a676838280000000000002900000000212223282800000000000000001c3a3a31252620283900000000003958682828282426282900000000000028382828283831332800000017170000282828281028212329000000000000002829002a2828242600000000000000002a000000283824260000001717000000000000002a28242600000000000000000000003a2828313300000000000017173e013a3828292a000000000000000000222222232900000000000000171700002525252600000000171700000000000025254826171700000000000000000000",
  [34]="323300000024323232333132323225252810000000372829000000002a2831483828393e003a280000000000002800242a2828343536290000000000002839240010282828290000000011113a2828312a282829000000000000212328382829002a00000000111100002426102829000000000000003436003a242628280000000000000000203828283125230000000000000000002728282a28313339000000000000000037280000002a2828390000013f0000002029000000003828000035353536000020000000003d2a2867142a282039003a2000003a00343535353500382028392827080028676820282828002a2028102830003a28282820282828",
  [35]="25252548252525252525252628282425252525252548252532323233282824252525323232323233212222232828242525262122232021233132323328282425323324252610313320282828283824252828313233282829002a002a2828242528281b1b1b282800000000002a2125483828390000002a290000000000313232282828290000000000163a6768282800282900000000000000002a28282829002800000039283900000000002828000028013a28281028580000003a2829000022222328282828283900582838283d0025252522222223282828281028282122254825252525262a28282122222225252525252548252600002a242525254825",
  [36]="2548252525262828282824254825252525254825323338282a28313225254825252532332828282900002a283132252548262b000000000000001c00003b242525262b000000000000000000003b242525332b0c00000011110000000c3b31482628390000003b34362b00000000282426101000000000282839000000002a243338280b00000010382800000b0000312a2839000000002a28290000000000000028290000002a282800000000000000002a280c0000003a380c00000000000c003a29000000002828000000000000000b10000000000b28100000000b0000003a28013d00000068283900000000000028212223000000282828000000000000",
  [37]="262828282831323232254825252525252628382828282a2a283132323232252526282828282900002a2828283828244826282828000000000028282828282425262a2828670016002a2828382828242526112810000000006828282828282425252328283a67003a28282829002a31322533282828380028282839000000170033282828282868282828280000001700282828382828282828282900000000002a28282828102828282867580000000000002a2828282828292828290000003a00002a28282a29000058100012002a282c00002838000000002a2839170000283c0168282800171717003a2800003a2822222223286700000000282839002838",
  [38]="2532330000002432323232323232252526282800000030402a282828282824253328390000003700002a3828002a2425282810290000000000002828390024482828280016000000162a282828002425283828000000000000003a2829002425282828675800000058682838000031322828282810290000002a282867000028282900002a0000000000382a29003a28283a00000000000000002800000028283829000000000000003a102900002838290000000000000000002a000000282900000100000011111100000000002a3a1111201111112122230000001212002a2222222222232448261111112020111125482525252624252621222222222222",
  [39]="2525262828282824253232323225482525482628382828313338282900313225252526282828282028292a0000002a31252526282900282067000000000000002525262700002a2029000000000000004825263700000029000000000000003a323233200000000000000000002728283535353611110000000000001130283828282834362000000000000020302828283810292a000000000000002a371028282828000000000000000000002a282828292a0000000000000000000000282a2a0000000000000000000000002a280000010000000000000000000000002900002739000017170000001717000000003a303800000000000000000000000000",
  [40]="2532323232323232252628282824482526280000163a282831332828382425253328111111282828000028002a3125253810212223283829003a1029002a24252834252533292a0000002a0011112425293b2426283900000000003b21222525003b2426290000000000003b31254825003b3133000000000000002a2831322500002a290000111100000000282828311111111111112136000000002a28380b2235353535353300000000000028283933283828282900000000000000102828282829002a0000000000000000282828290000000000000000002a67682829000001000000001717000000282838393a001717000000000000003a2828282828",
  [41]="252525330000000000000000000000524825260000000000000000000000005225252600000000000000000000000052323233670000000000000000000042002223282800002c46472c0000004253532526382867003c56573c42434353636325332828283921222223525353640000262a2828102824252526626364000000260029002a28244825252300000000002600000000212525252526001c000000330000000031322525253300000000000000000042434424252628390000000000000000525354244826282800000000003f01005253542425262810673a39000021222352535424253328282838290000242526525354242628282828282839",
  [42]="252532323232333132323232332829002526000016000000002a1028283839002526000000001111000000292a2829002526390000002123000000000021222225262800003a242600001600002425253233283900282426111111111124252529002a283828313235353535222548250016002828282900000000003132252539003a282900000000000000002831322828281000000000001100002a38282928382829000000003b202b006828280028002a0000110000001b002a2010292c290000003b202b39000000002900003c013f0000002a3829001100000000002122232b00000828393b2700000000142425262b00003a28103b30000000212225",
  [43]="2628292867000000000028283132323226281a3820393d000000002a3828282826283a28201020111111212223282810252222232122232122232448262828282525482631323331323324252620283825482526201b1b1b1b1b24252628282825252525230000000000313233281028252525252667580000002000002a282825254825263829000000170000586828252525252628000000001700002a2122323232323329000000000000000031251b1b1b1b0000000000000000000010310000000000000000000000000000282801000000000000003a67000000002a3823000000120000002829000000000028260000002700003a2800000000000028",
  [44]="2525253233282800312525482525254825252628282829003b2425323232323225252628382800003b24262b002a2a3832323328282800003b31332b000000282222232829286700002829000000000025252600002a28143a29000000000000482526111111343536111111110000002525323535352222222222353639000032331028293b2448252526282828000028282908003b2425254826282829120028280000003b313232252638280017002829160000001b1b1b313328106700002800000000000000001b1b2a28290000286758680000010000000068280000002828102867001717171717282839000028382828283900000058682838280000",
  [45]="2525482628382831323232323232254832323233282828282828102828203125282828282829002a2800282838282831102829000000000029002a2828282900283800111100001200000028292a160028293b2123000017000011286700000000003b3133111111111127282900003b00003b3435353535353630380000001700003b201b1b1b1b1b1b3028000000170000001b00000000000030290000003b000000000000001100003700000000000000001100003a2700001b000000000001000027390038300000000000000000212300372829283000000000000000003133392710122837000000000000000022233830281728270000000000000000",
  [46]="00000000000000002824252525254825000000000000586828244825252525250000000000002a10283132252548252500000000000000002a2828242525254800000000000000393a28282425252525000000000000002a283828244825252500000000000000002828283132323232000000111111113a2828101b1b1b1b1b000068212222232838282839000000000000103132252522353535360000000000002a28283132261b1b1b1b000000000000002838293b3000000000001200000000002a28003b37000000003a27000000000100280000280000002a2830000040002122232b0038391200683830390021232425262b68282827282810302800",
  [47]="332900003132323225323232323225321b0016001b1b1b1b301b1b1b1b1b301b0000000000000000370000000000370000000000000000001b00000000001b0000001600001100000000001100000000000000003b202b3916003b202b0016002800003a001b3a283900001b0000000028392828390028280000000000000000282828282838282900000000000016002838002a28282810393900001100000029000000002a28282828393b272b000000000000000000282828283b302b000000010000001111111128383b372b003a222223111121353536102828290000382548252222260c002a28282800003a2825252525482600000028282900002828",
  [48]="00000000000000003b20000031323225000000000000001111200000002a28240000000000003b34353600140000103100000000000000003b3435363900001b1100000000000000000000201028001127393a00000000000000001b2a2839213728383911000000000000113a2828311b002a282711000000003b272828381b11003a283727000000003b372a282911272828291b3039000000001b002a2821372810001130283a00000011002828311b2a283827302810390000273a28291b00002828373029002838003728380011000029001b3000002a28000028280021010000003a37080000283900282900312300000038283900002a28102800001b",
  [49]="2526002a28382425253232323232323225330000002a31323300002900003829262b0000000000000000000000002a0026727373737373737373737411000016252222222222222222222222232b0000254825252525253232323232262b0000323232322548262829002a10372b0016222222233132331600006829000000002525482638282a0000002a000000000025322526290000000000003a00000000260131331600000000000028390000002617000000000000390000382800000026390000000000002800002828290000262829000000003a2829002828000000262800000000002838003a281000000026383900000000282800282828390000",
  [50]="000000000000002a10282900313232250000000000001100002a0000002a283100000000003b202b0012000000002a280000001100001b003b202b000000162800003b202b000000001b00000000002a0000001b0000001100000000000000000000000000003b202b00001600000000000100000000001b00000000000000000020111111111111111111111111001600343535353535353535353535362b0000202838282828202828282828272b00001b2a282810281b2a28382a28372b0000000029162a28000028160028280000005868000028283a2828390028291600002a282828292a28283828282800000000000038280000002a28102800000000",
  [51]="636363645253535354550000005552530000000062636363645500000055525300000000000000000065000000556263000000000000000000000000006500000000000000000000390000000000000000000000390000682800003a0000000000003a58282868282828282839000000683928282828102900002a10283a67682828282a38282800000000002828282828282900282829006061003a2838282a382800002a283d0070713f28282900002828390000282122232122232800003a10290000002031323324482628424343280001000021222222252525235253534343434344242548252525252652535353535353542425252525254826525353",
  [52]="25482525262b0000000000002425252525252548262b3a00000000002425482525252532332b2829001111202425252525253328282828103a212222252525254826282828382828283132322548252525262828102a002a28282900313232322526382829000000002a0000000000002526282839000000000000000000000025262829000000000000000000000000482600000000000000000000000000002526000000000000390000000000000032330000000000002829000000000000000000000000000028000058680000000000003f0100003a2800002a1000000000000021360000382839000028001c0000000030424400282828000028390000",
  [53]="2628282824254825252548252525252526283828313232323232323225254825261029002829000000002a2831252525262800002a001111110000283824252526290000001142434400002a2824254826111111114253535400003b2125252525222222236263636400003b2425252525254825252328382900003b24482525252525252526102a0000003b242525252548252525262900001111112425252525252525482600003b2122233125482532323232323300003b2425252331252538282829000000003b2425482523313228290000000039003b2425252525222228013d3e003a28003b2425252548252522222223102838393b24252525252525",
  [54]="2525252525262b1b1b1b3132322526002525254825262b0000001b1b1b2426002525252525262b00000000002a2426672548253232332b0000001100282426292525262122232b003a67272b2a2426382525262448262b002a38302b122426293232333132262b120028302b17313300280000002a301127002a302b0010103929001100003135262b00313535353535003b272b002a38302b0000002a28393b083b302b00002830111111110028383b003b372b00002a31353535360028293b39001b000000001b1b1b1b1b002a003b2829000001001400000000000000003b1067583a21222311111111110012003b2838282824252522222222230017003b",
  [55]="48253232323232322525323232332828323328670000002824332b2a28102838282838290000112a372b003a2827290028102a00003b2700290000003830000028290000003b30000000003a2830000038000000003b3000000000002a303e1428395868393b301111111111112422222828382834353235353535353525254829002a0000102828282829003b2425250000000000002a2838282867212525251111111111000028290029282425482522222222231111202b00002a31322525323232323235361b000000001b1b312539013d00002a28000000000000002824222223390010283900000000083a1031252526283a2838280000000000382828",
  [56]="25252525252525252525482532332b282525254825253232323225261b1b00382525252525331b1b1b1b31330000002832322525262b000000003b2700003a2822233132332b000000003b302839002a25252222232b000000003b302900000025254825262b000011003b302b00000025252525262b003b27003b302b00000032323232262b163b30003b30000000001b1b1b1b372b003b30393b30160000000000003a2800003b30283b3700000000000000103829003b3028282800000000000000002800003b3028382900000000000000682867003b30002a286700000001003a382829003b370000382900000023001028280000003800002810000000",
  [57]="32323232322526282800003b242525252901003a282426382900003b2432323235353536282426281400003b30282a2a2828382828242522232b003b372908003828291029244825262b0000000000002829000000242525262b0000000000002811111111242548262b0000000000002834353535323225262b000011000000291b1b1b1b1b3b24262b003b272b00000000000000003b24262b173b302b00000000000000003b2426111111302b0000111111113900112425222222332b00002222222328383432323232332b00000025252526002828003a10282a0016003a25482526002a2828283829000000002825252526171728382800000000003a28",
  [58]="25482525252525484825252526382824323232323232323232323225261028311a2829002a2838282810282426002a380010001100292a2829112a3133003a28002a3b202b3a16283b202b00110000280000001b002a2828001b003b202b112a0000000000001110675811001b3b201600000000003b20282838272b16001b000011000000001b2a2828372b000000003b202b110000001100291b000000003a001b3b202b003b272b000000000000280100001b00003b302b000000005868282339000000003b372b000000002a1028262800000000001b000000393a283828263839120000000000003a28282828102628102739000000002a282838282828",
  [59]="25482525323328282924253232322525252532331b1b1028143133382828244825261b1b00003821232b00000810242525262b0000002a31332b00006828242525262b000000001b1b00002a382a242525262b000000000000000000293b2448482611111111000000160000003b31252525232122232b000000000000001b243232333132332b000011110000003b241b1b1b1b1b1b00111121231100003b242b01000000003b21222532362b003b312b17000000003b2425331b1b0000001b1111111100003b31331b003a00160000222222232b00001b1b00003800000068254825262b160000390000283a003a28252548262b00003a38003a2810283828",
  [60]="00000000000000000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000010000039000000000000000000003a00280000380000000000000000000028672800001000390000000000000000283828760028672800000000000000002a28282123283829000000000000006838282125252328393a0000000000002a28212548252523283868000058586828292425252525261028286800281028380031322525482629002a2800002a28393f2123242532332000002900000021222225263133212223283946470100312525482522222525252310565721222324252525252525482525222223"
}

function get_lvl()
	return split(levels[lvl_id])
end

function get_data()
	return split(mapdata[lvl_id],",",false)
end

cam_x=0
cam_y=0
cam_spdx=0
cam_spdy=0
cam_gain=0.25

function move_camera(obj)
  cam_spdx=cam_gain*(4+obj.x+0*obj.spd.x-cam_x)
  cam_spdy=cam_gain*(4+obj.y+0*obj.spd.y-cam_y)

  cam_x+=cam_spdx
  cam_y+=cam_spdy

  if cam_x<64 or cam_x>lvl_pw-64 then
    cam_spdx=0
    cam_x=clamp(cam_x,64,lvl_pw-64)
  end
  if cam_y<64 or cam_y>lvl_ph-64 then
    cam_spdy=0
    cam_y=clamp(cam_y,64,lvl_ph-64)
  end
end

--replace mapdata with hex
function replace_room(x,y,room)
 for y_=1,32,2 do
  for x_=1,32,2 do
   local offset=4096+(y<2 and 4096 or -4096)
   local hex=sub(room,x_+(y_-1)*16,x_+(y_-1)*16+1)
   poke(offset+x*16+y*2048+(y_-1)*64+x_/2, "0x"..hex)
  end
 end
end

-->8
--network
chars=" !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
s2c={} c2s={}
for i=1,95 do
  c=i+31
  s=sub(chars,i,i)
  c2s[c]=s
  s2c[s]=c
end

omsg_queue={} 
omsg=nil 
imsg=""

function split_str(str,sep)
 astr={} index=0
 for i=1,#str do
  if (sub(str,i,i)==sep) then
   chunk=sub(str,index,i-1)

   index=i+1
    add(astr,chunk)
  end
 end
 chunk=sub(str,index,#str)
 add(astr,chunk)
 return astr
end

function send_msg(msg_type,data,reliable)
  reliable = reliable or 1

  local msg = msg_type..","..reliable..","..pid..","..data

  if reliable==0 then
    for v in all(omsg_queue) do
      if split(v)[1]==msg_type then
        del(omsg_queue, v)
      end
    end
  end


  if reliable or #omsg_queue <= max_output_queue then
    add(omsg_queue,msg)
  end
end

function update_msgs()
  update_omsgs()
  update_imsgs()
end

function update_omsgs_stdl()
  if (omsg==nil and count(omsg_queue)>0) then
    omsg=omsg_queue[1]
    del(omsg_queue,omsg)
    for i=1,#omsg do
      poke(0x4300+i, s2c[sub(omsg,i,i)])
    end
    poke(0x4300+#omsg+1, 0x0a)
    serial(0x805,0x4301, #omsg+1)
    omsg=nil
  end
end

function update_imsgs_stdl()
  imsg=""
  serial(0x804, 0x5300, 1)
  local c = peek(0x5300)
  while c~=0x0a do
    imsg=imsg..c2s[c]
    serial(0x804, 0x5300, 1)
    c = peek(0x5300)
  end
  if imsg~="" then
    process_input()
  end
  poke(0x4ffe, 0x66)
  poke(0x4fff, 0x0a)
  serial(0x805,0x4ffe, 2)
end

function update_omsgs()
  if (peek(0x5f80)==1) return
 
  if (omsg==nil and count(omsg_queue)>0) then
    omsg=omsg_queue[1]
    del(omsg_queue,omsg)
  end 
    
  if (omsg!=nil) then
   poke(0x5f80,1)
    memset(0x5f81,0,63)
    chunk=sub(omsg,0,63)
    for i=1,#chunk do
      poke(0x5f80+i,s2c[sub(chunk,i,i)])
    end
    omsg=sub(omsg,64)
    if (#omsg==0) then
      omsg=nil
      if (#chunk==63) poke(0x5f80,2)
    end
  end
end

function update_imsgs()
  control=peek(0x5fc0)
  if (control==1 or control==2) then
    for i=1,63 do
      char=peek(0x5fc0+i)
      if (char==0) then
        process_input()
        imsg=""
        break
      end
      imsg=imsg..c2s[char]
    end
    if (control==2) then
      process_input()
      imsg=""
    end
    poke(0x5fc0,0)
  end
end

clients={}
pid=0
username=""
max_output_queue=4
connected = false

--POSSIBLE MESSAGES
--cartload - local message everytime the cart is loaded
--init - sets pid
--room - sent to server when new room joined
--connect - recieved when a new player joins the room
--sync - recieved from each player in a room when client joins
--disconnect - received when a player disconnects from current room
--update - player entity data from each player in room

function process_input()
  local data = split(imsg)
  local message={}
  message.type=data[1]
  message.reliable=data[2]==1
  message.pid=data[3]
  deli(data,1)
  deli(data,1)
  deli(data,1)
  message.data=data

  if message.type~="init" and is_title() then return end

  if message.type=="init" then
    pid = data[1]
    connected = true
  elseif message.type=="connect" then
    local c = {}
    c.pid = message.pid
    c.name = data[1]
    local o = init_object(extern_player, -64, -64)
    o.pid = c.pid
    o.name = c.name
    add(clients, c)
  elseif message.type=="sync" then --different than connect, bc connect fx
    local c = {}
    c.pid = message.pid
    c.name = data[1]
    local o = init_object(extern_player, -64, -64)
    o.pid = c.pid
    o.name = c.name
    add(clients, c)
  elseif message.type=="disconnect" then
    for v in all(objects) do
      if v.pid==data[1] then
        del(objects,v)
      end
    end
    for v in all(clients) do
      if v.pid==data[1] then
        del(clients,v)
      end
    end
  elseif message.type=="update" then
    local o
    for v in all(objects) do
      if v.pid==message.pid then
        o=v
        break
      end
    end
    if not o then return end
    o.x = data[1]
    o.y = data[2]
    o.spr = data[3]
    o.djump = data[4]
    o.flip.x = data[5]==1
    o.dash_time = data[6]
    o.spd.x = data[7]
    o.spd.y = data[8]
  end
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
7777777777777777700007770000777000007777700077770000000000000000c77ccccc10111101101111010000000000000000000000000000000000000000
7777cc7777cc777770cc777cccc777ccccc7770770c777070000000000000000c77cc7cc11171711117171110000000000000000000000000000000000000000
777cccccccccc77770c777cccc777ccccc777c0770777c070000000000000000cccccccc11119911119911110000000000006000000000000000000000000000
77cccccccccccc77707770000777000007770007777700070002eeeeeeee2000cccccccc01177710017771100000000000060600000000000000000000000000
57cc77ccccc7cc7577770000777000007770000777700007002eeeeeeeeee200cc7ccccc01177710017771100000000000d00060000000000000000000000000
577c77ccccccc7757000000000000000000c000770000c0700eeeeeeeeeeee00ccccc7cc0117771001777110000000000d00000c000000000000000000000000
777cccccccccc7777000000000000000000000077000000700e22222e2e22e00cccccccc1199d991199d991100000000d000000c000000000000000000000000
777cccccccccc7777000000000000000000000077000000700eeeeeeeeeeee000000000000000000000000000000000c0000000c000600000000000000000000
577cccccccccc7777000000c000000000000000770cc000700e22e2222e22e00000000000000000000000000000000d000000000c060d0000000000000000000
57cc7cccc77ccc7570000000000cc0000000000770cc000700eeeeeeeeeeee0000000000000000000000000000000c00000000000d000d000000000000000000
77ccccccc77ccc7770c00000000cc00000000c0770000c0700eee222e22eee000000000000000000000000000000000000000000000000000000000000000000
777cccccccccc7777000000000000000000000077000000700eeeeeeeeeeee005555555506666600660000000666660006666600066666006666000666660000
7777cc7777cc777770000000000000000000000770c0000700eeeeeeeeeeee005555555566666660660000006666666066666660666666606666606666666000
777777777777777770000000c0000000000000077000000700ee77eee7777e005555555566000660660000006600066066000000660000000066006600066000
57777577775577757000000000000000000000077000c007077777777777777055555555dd000000dd000000ddddddd0ddddddd0ddddddd000dd00dd00000000
000000000000000070000000000000000000000770000007007777005000000000000005dd000dd0dd0000d0dd000dd0000000d0000000d000dd00dd000dd000
00aaaaaaaaaaaa00700000000000000000000007700c0007070000705500000000000055ddddddd0ddddddd0dd000dd0ddddddd0ddddddd0dddd00ddddddd000
0a999999999999a0700000000000c00000000007700000077077000755500000000005550ddddd00ddddddd0dd000dd00ddddd000ddddd00ddddd00ddddd0000
a99aaaaaaaaaa99a7000000cc0000000000000077000cc077077bb07555500000000555500000000000000000000000000000000000000000000000000000000
a9aaaaaaaaaaaa9a7000000cc0000000000c00077000cc07700bbb0755555555555555550000000000000c000000000000000000000000000000000000000000
a99999999999999a70c00000000000000000000770c00007700bbb075555555555555555000000000000c0000000000000007700077077777700777777000000
a99999999999999a700000000000000000000007700000070700007055555555555555550000000000cc00000000000000007770077077777770777777700000
a99999999999999a07777777777777777777777007777770007777005555555555555555000000000c0000000000000000007777077077000000007700000000
aaaaaaaaaaaaaaaa07777777777777777777777007777770004bbb00004b000000400bbb00000000c00000000000000000009999999099990000009900000000
a49494a11a49494a70007770000077700000777770007777004bbbbb004bb000004bbbbb00000001000000000000000000009909999099000000009900000000
a494a4a11a4a494a70c777ccccc777ccccc7770770c7770704200bbb042bbbbb042bbb00000000c0000000000000000000009900999099999900009900000000
a49444aaaa44494a70777ccccc777ccccc777c0770777c07040000000400bbb00400000000000100000000000000000000009900099099999990009900000000
a49999aaaa99994a7777000007770000077700077777000704000000040000000400000000000100000000000000000000000000000000000000000000010000
a49444999944494a77700000777000007770000777700c0742000000420000004200000000000100000000000000000000000000000000000000000000001000
a494a444444a494a7000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
a49499999999494a0777777777777777777777700777777040000000400000004000000000010000000000000000000000000000000000000000000000000010
00000000030000004252620000000000000000132353535353330000a10000004252523300000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000030000004252620000000000000000000000000000000000000000114252620000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000030000004252620000000000000000000011111111111111111111125252620000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000030000001323330000000000000000000043532222222222222222525252330000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000031100000000000000000000000000000000001323232323232323235262000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000423200000000000000000000000000000000000000000000000000001333000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111426211111111111112222222320000000000000000000061000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222525222222222222252525252522222320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252522222321111111111111111111232000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252522222222222222222225233000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252525252525252525252523300000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252525252525252525252330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252525252525252525233000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252525252525252523300000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252525252525252330000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252525252525233000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525252525252525252525252525252525252525252525252523300000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52232323232323232323232323232323232323232323232323330000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62000000000000000000000000000000000000000000000000000000000072000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62000011000011000011000011000011000011000011000011000011000003000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62111102111102111102111102111102111102111102111102111102111103000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52225353535353535353535353535353535353535353535353535353536373000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52620000000000000000000000000000000000000000000000000000000000000000000072000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52620000001100000011000000110000001100000011000000110000001100000011000003000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52621111110211111102111111021111110211111102111111021111110211111102111103000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52235353535353535353535353535353535353535353535353535353535353535353536373000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62000000000000000000000000000000000000000000000000000000000000000000000000000000720000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62000000001100000000110000000011000000001100000000110000000011000000001100000000030000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62000000000200000000020000000002000000000200000000020000000002000000000200000000030000000000000000000000000000000000000000000000
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
0000000000000000000000000000000004020000000000000000000200000000030303030303030304040402020000000303030303030303040404020202020200001313131302020302020202020202000013131313020204020202020202020000131313130004040202020202020200001313131300000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000003a290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001111000000000000000000000000000000000000000000113a29000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002123000000000000000000000000000000000000000000202900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000313300000000000000000000000000000000000000003a290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000113a29000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001111000000000000000000000000000000202900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111100000000212300000011110000000000000000003a290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
2123000000003133000000212300000000000000113a29000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002122230000000000000000000000000000000000000000000000000000000000000000000000000000000000
3133000000000000000000313300000000000000202900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003132330000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000111100000011110000000000000000003a290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046470000000000000000000017000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002123000000212300000000000000113a29000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056570000000000000000000017000000000012000000000000000000000000000000000000000000000000000000000000000000000000
0000003133000000313300000000000000202900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020201111111111110000000017000000212320000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000003a290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022222222222222230000000000000000242522222300000000000000000000000000000000000000000000000000000000000000000000
0000111100000000000000000000113a29000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525260000000000000000242525252600000017170000000000000000000000000000000000000000000000000000000000
0000212300001111000000000000202900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525260000000001000000242525252600000000000000000046470000000000000000000000000000000000000000000000
000031330000212300000000003a290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252222222222222222252525252611111111111111200056570000000000000000000000000000000000000000000000
3900000000003133000000113a29000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252522222222222222222222230000000000000000000000000000000000000000000000
2839000000000000000000202900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252525330000000000000000000000000000000000000000000000
2a2839111100000000003a290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
002a282123000000113a29000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
00002a3133000000202900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
000000003e3d493f3d4a3e3d003f493d4a3e000000000000000000000000000000000000000000003e3d3f00000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
00000000212235353535352222222222222223493f3e3f3d4a004647000000000000000000003e3f21222300000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
000000002433000000000031323232323232322222222222233d56573f3e0000000049013e4a212225253300000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525323233000000000000000000000000000000000000000000000000
0000000030000000000000000000000000000031323232252522222222233f3d493e21222222252532330000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252526464700000000000000000000000000000000000000000000000000
0000000030000000000016000000160000001600000000313225252532322222233425252525323300000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252526565700000000000000000000000000000000000000000000000000
0000000030000000001111111111111111111100000000000024253300003132252331252533000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525222223000000000000000000000000000000000000000000000000
00000000300000001121222235353535222223003d0000000024330000000000242523313300000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
0000000030000000212525330000000031323222233d12494a30000000000000242525230000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525252525252525252525252525252526000000000000000000000000000000000000000000000000
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

