pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--solanum
--a celeste classic mod
--made for the 12 days of cchristmas mod jam
--by cominixo

--made with:
--~evercore~
--a celeste classic mod base
--v2.2.0
--major project contributions by
--taco360, meep, gonengazit, and akliant

--original game by:
--maddy thorson + noel berry


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
  music(40,0,7)
  lvl_id=0
end

function begin_game()
  max_djump=1
  fireworks_start=false
  deaths,frames,seconds,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,1
  music(-1,0,7)
  load_level(1)
end

function is_title()
  return lvl_id==0
end

-- [effects]

fireworks={}

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
          local wall_dir=((this.is_solid(-3,0) and not this.is_ice(-3,0)) and -1 or (this.is_solid(3,0) and not this.is_ice(3,0)) and 1 or 0)
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
    obj_outline(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
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
  pal(2,djump==1 and 2 or djump==2 and 14 or 12)
end

function draw_hair(obj)
  local last=vector(obj.x+(obj.flip.x and 6 or 2),obj.y+(btn(⬇️) and 4 or 3))
  
  -- outline
  for i,h in ipairs(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    circfill(h.x-1,h.y,mid(4-i,1,2),0)
    circfill(h.x+1,h.y,mid(4-i,1,2),0)
    circfill(h.x,h.y+1,mid(4-i,1,2),0)
    circfill(h.x,h.y-1,mid(4-i,1,2),0)
    
    last=h
  end
  for i,h in ipairs(obj.hair) do
    circfill(h.x,h.y,mid(4-i,1,2),2)
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
      for i=7,13 do
        pset(this.x+4+sin(this.offset*2+i/10),this.y+i,6)
      end
      obj_outline(this.spr,this.x,this.y,1,1,false,false,true)
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

bg_smoke={
  layer=0,
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
  end,
  draw=function(this)
   obj_outline(this.spr,this.x,this.y,1,1,false,false,true)
  	draw_obj_sprite(this)
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
  		for ox=-6,6,12 do
      local s = (has_dashed or sin(this.step)>=0) and 45 or this.y>this.start and 47 or 46
      obj_outline(s,this.x+ox,this.y-2,1,1,ox==-6,false,true)
      spr(s,this.x+ox,this.y-2,1,1,ox==-6)
    end
    obj_outline(26,this.x,this.y,1,1,false,false,true)
    spr(26,this.x,this.y)
    
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
    ?"gift!",this.x-4,this.y-4,13+this.flash%2
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
    this.semisolid_obj=true
  end,
  draw=function(this)
  		draw_obj_sprite(this)
   end
}

slidelie={
  layer=0,
  init=function(this)
    this.start_x = this.x
    this.start_y = this.y
    this.solid_obj=true
    this.hitbox.h-=1
    this.hitbox.y+=1
    this.timer=15
    this.collides=true
    this.collides_y=true
    this.spd.y=0
    this.dir=1--this.spr==11 and -1 or 1
  end,
  update=function(this)
    	
    local slidelie_below = this.check(slidelie, 0, 2)
    local on_ground=this.is_solid(0,1) and not slidelie_below
    -- apply gravity
    if not on_ground then
      this.spd.y=appr(this.spd.y,1.65,abs(this.spd.y)>0.15 and 0.21 or 0.105)
    end
    if slidelie_below then
    		this.spd.y = slidelie_below.spd.y
    end
    
    if this.check(player,0,-2) then
    		this.spd.x=this.dir*1.65
    else
      this.spd.x=this.dir*0.65
    end
    this.timer -= 1
    if this.timer==0 then
    		if (not slidelie_below and on_ground) then
      	this.init_bg_smoke(-7, 3)
      end
      this.timer = 15
    end
    
    if this.is_solid(0,0) and not this.is_flag(0, 0, 6) then
   			 -- death particles
    	  for dir=0,0.875,0.125 do
					    add(dead_particles,{
					      x=this.x+4,
					      y=this.y+4,
					      t=2,
					      dx=sin(dir)*3,
					      dy=cos(dir)*3
					    })
  			  end
  			  this.x=this.start_x
    	  this.y=this.start_y
    
    
    elseif (this.is_flag(-8, 0, 5) or this.y > lvl_ph) then
    		this.x=this.start_x
    		this.y=this.start_y
    end
        
  end,
  draw=function(this)
  		obj_outline(this.spr,this.x,this.y,1,1)
    spr(14,this.x,this.y)
    obj_outline(this.spr+1,this.x,this.y-8,1,1)
    spr(15,this.x,this.y-8)
  end
}

slidelie_spawn={
  init=function(this)
				init_object(slidelie,this.x,this.y,14)
  end
}

message={
  layer=3,
  init=function(this)
    this.text="-- solanum mountain --#you walk in the footsteps of#those who came before you#and your path guides#those who will follow later."
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
      rect(6,6,121,7*5+7,1)

    end
  end
}

help_sign={
  layer=3,
  init=function(this)
    this.text="solanum mountain#-- caution --##slippery ice ahead!"
  end,
  draw=function(this)
    if this.player_here() then
      for i,s in ipairs(split(this.text,"#")) do
        camera()
        rectfill(7,7*i,120,7*i+6,7)
        ?s,64-#s*2,7*i+1,0
        camera(draw_x,draw_y)
      end
      rect(6,6,121,7*4+7,1)
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
        flash_bg,bg_col,cloud_col=false,0,5
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
      fireworks_start=true
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
      draw_time(42,16)
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
13,platform
14,slidelie
81,slidelie_spawn
18,spring
20,chest
22,balloon
23,fall_floor
26,fruit
45,fly_fruit
64,fake_wall
86,message
28,help_sign
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
      if obj.collides and (not obj.collides_y or axis=="y")then
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
  
  function obj.init_bg_smoke(ox,oy)
    init_object(bg_smoke,obj.x+(ox or 0),obj.y+(oy or 0),29)
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
  frames=(frames+1)%30
  if time_ticking then
    seconds+=1
    minutes+=seconds\1800
    seconds%=1800
  end

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
  
  if (fireworks_start) then
  		if frames%30 == 0 then
  					-- spawn firework
  					local f_x = rnd(128)
  					local f_y = rnd(100)
  					local col=rnd({8,10,11,12,14,7})

  					for i=0,80 do
		       local p={}
									p.x=f_x
								 p.y=f_y
								 
								 local speed = rnd(1.5)
								 local angle = rnd()
								 
									p.col = col
								 
								 p.dx=sin(angle) * speed
								 p.dy=cos(angle) * speed
								 sfx"63"
								 add(fireworks,p)
      	end
   	end
  end

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
    ?"🅾️/❎",55,80,5
    ?"mod by cominixo",36,96,5
    ?"original game by:",32,108,5
    ?"maddy thorson",40,114,5
    ?"noel berry",46,120,5

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
  
  
  foreach(fireworks, function(p)
		  if p.y > 128 then
		   del(fireworks,p)
		  else
		  
		   p.x+=p.dx
		   p.y+=p.dy
		   
		   p.dy+=0.04
		    
		   line(p.x,p.y,p.x+p.dx,p.y+p.dy,p.col)
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
  rectfill(x,y,x+44,y+6,0)
  ?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds\30).."."..two_digit_str(flr(100*(seconds%30)\30)),x+1,y+1,7
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
  "0,0,1,1,trailhead",
  "1,0,1,1,100m",
  "2,0,2,1,200m",
  "4,0,2,1,300m",
  "1,1,1,2,400m",
  "6,0,1,1,old site",
  "2,1,1,1,600m",
  "3,1,1.75,1,700m",
  "4.75,1,1,1,800m",
  "5.75,1,1.3125,1,900m",
  "2,2,1,1.625,1000m",
  "3,2,1.9375,1,1100m",
  "4.9375,2,1.375,1.5,the end?",
  "0,1,1,1,summit"
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
  nil,
  nil,
  "252525323232252525323232323232330000000000000000000000000000242625323300000024252600000000002a39000000000000000000000000003f3133330000003a28312551003f0000000028000000000000000000000021222220000000000028000024252223000800002a39000000000000000000003132330000000000002a3900313232330000003d0010283900000000000000002800000000000000000038004244002a212222222328002a390000212300003a2900000000000000000028005254000031323232332900002a28394126003a29000000000000000000002814525400003a38282829424344212222252600280000000000000000000000343662642828282900000062636431323232333a2800002c000000000000000072442123000000000000000000003a28283828282900003c0000000000000000005524330000000000003e00003a29000000280000002122222222000100000000653700000000000c21233a28293f00000028000000242525252522222300000000000000000000002426290000212223002a39003a31323232322525260000000000000000000000242600000024252500002a2828290000000025255111111111111111111111114126000000313233000000000000000000002525252222222222222222222222252600000000000000000000000000000000",
  "25252525323232323232323232322600000000000000001111000000000000002532323300000000000000004000300000000000000000212300000000000000330000000000000000003e00000030003f00000000000024260000000000000000000000000000000000424421222522232839000000002426000000111100001111110000000000000062643132252526002a28390000313300000021230000434344000000001600000000003a3132330000002a28282839000000242600005353540000001100000000003a29000045000000000000002a39000031330000636364001600451111111100380000005500000000000000002800003a1000002839000000005521222223682900000055000000004243434438282828290000002a2838282855313225252317170000652839000062636364280000000000000000000000006500002425260000000000002a38282123003a2900000000000000000000000000000024252600000000000000000024263a2800000000000000000001003d00000000242551111111111111111111412628290000000000000022222222230000000031323235353535353535353532332900000000000000002525252526000000000000000000000000000000003a2900000000000000000025252525260000000000000000000000000000003a2900000000000000000000",
  "000000000000380024262a380000000000000000000028003126002a3900000000000000003a2900003000002a39000000000000002817000030000000280000000000003a29170000300000002a39000000173a2800000000300012000010000000172828382828283042434400280028282838282817000037626364002a28000000002829170000000000000000000000173a290000000000000000000000000017280000000000000000111111110000002a3900000000000000450b0c42000000002a3900003d000000550000520000000000282122230000006500006200000000001031323300000028003a1000000000002a390000000000382829000000000000002a283900000028000000000000000000002a28282828290000000000000000000000002a2122230b0d0c3f00000000270b000000242526002d00230000000037000000002432330000005100003a382900000000300000000000353536290000000000003700000000000000280000000000000028000000000000002a390000000000001000000000000000002a390000000000280000000000000000003800003f0000280000000000000000002a390021233a2900000000000000000000280041262800013e000000000000000021222526282122230000000000000000242525262824252600000000000000002425252628242526000000",
  "0000000000000000000000000000000000000000000000000000000000000000000000000027003e00000000000000000000000000242222222300003a67000000000000003132252533003a28003f00000000000000003133000038292123000000000000000000000000280024260000006700003a6700006810283931330000002a390028000000000000280000000000002a28383900004647002a2839000000000000002a390056570000002800000000002c00002800212300003a29000000003d3c0000283924252223280000010021222223002a28242525261000002222252525260000382425252523000025252525252600002824252525260000",
  "00000031323232323232323232323225000000100000000010000000000000240b003a29000000002800000000000024003a2900000011002a39110000000024282900000000272b0028272b00160024111111110000302b3a29302b00000031222222231100372b2800372b003a2829323232252328390028000000003828000000003126002a283828676828282900000100003000002829002a290000000022233a2830003a290011110000000000323328003000280000424400003e120000002a39303a29000052540000212300000000103728000000525400002426000000002a28290000005254000031330000171700000017170052540000000000",
  "253232323232323232253232252525252600000000000028000000003300003a290000003e3040002425252526000000000000280000000000000028000000002126000031323232252222233f003a38000000000000452800110000242600003a2828392425323236002829000000000000553800450000242638282900002824260000003a2900002c0000002755280055000031330000003a28102426281028280000003c00000030552800550000004500004529002824260000002800212223000000376528005500000065003a55003a29242600003a2900313233000000003a2911650b0000003a285528290031330000280000000000000021232800343628382828290065000000000000002a39000000000000255128003a291111111111111111111111111100002828283900000025260b0c212222222235353535353535222223000028002a1000000025260100242532323300002a10283900313233003a2900002a39001125252222252600000000000000002a282838282829000000002a2821252525252551003d3f3e3d003e3f001111111111111111111111114125252525252522222222222222222222222222222222222222222222",
  "25263900000028002a39003a2839003a25262a3839002800002a282900282829252600002a282900000028003a2900002525424400280000003a10282900000025266263743800000028290000003f0025260000002800003a29003e0000212225330000002800002a3900424373742533000000002800000028006264002425390000003a290000002a3900000031252a390000100000000000280000000024002a39002a390060000038390000002400003800002a6700006828290000002400012a390000212222232800002c0024002123286700242525262800003c00242225252222222525252523000021222525252525252525252525252222252525",
  "0000000000000000242525252525323232323232252223003e00003a28313232322526000000004000243225222245003800000000003133283900000000313931252555002800000000000000002a390000000028003132653a290000212300000000002800000000283900000028000000242611000000002a39000000002a28102828000000242523000000000028000000000000002a283900003132260000000000380000000000000000002a3828283931222300000028000000000000111100000000002800313317170028001100000000424400000000002a3900000000002a39170000000052540000000000002a390000000000281700000000525411000000160000280000000000280000000000525427000000000000100000000000280000000100525437000000000000280000000000280000222222525400000000000000280000000000280000",
  "0000000000000000000000000000003a3e000000000000000000000000003a2923000000000000000000000000002800330000424344000000000000003a280000000062636374000000003a283828000000000028000000003a282900282900000000002a2828382829000000280000000000000000000000000000002800001100000000000000000000003a2900002300000000000000000000002800000051000000000000000000000010000000511111111100003a390000002800000073737373740000280000000028000000002800000000002a3900000028000000002a3900000000001000000c4243440000002a3900000000280000006263640000000028000000002a2838283900000000000028390000000000002a28000000003a283828390000001111002800000028290000002a3900002123282900000000000000000028000041260000000000000000000000280000412600000000000000000000002800114126000000000000000001003d100021252600000000000000212222232800242526000000000000002425252628002425260000000000",
  "25252525323232323232323232323232322526003f000000000000002800003232323300000000000000002800001b1b3132222300003e0000003a29000000000000000000000000003a29000000000000313235222300003a2900000000000100000000000000003800000011110000000000242600002800000000222222223600000000000028000000212328390008002426000010000000003225255100003e0000003a290000002426002800000042440000280000000000313232353536000000280000000024252222224243535400002800000000000000002a283900003a2800000000313232322552536364000028000c42430000000000002a2828282828390000000000002452540000003a29000062630000000000000028100000002a28282839000031525400003a290000000000000000002700002a2800003d000000002a28282852540000280000000000000000003f30000000280000212223000000000000626400003800111100000000140021260000002800004125252223000000000000003a29004244000000222222252600000028000041253232330000000000000028000052540000002525252526000000380000313300000000001111000000280000525400000025252525260000002800000000000000000042440000002800005254000000",
  "00400024252525513f00000000000000000000000000000000313232323235360000000000000000000000000000000000000028000000000000000000000000000000003d000000002a283828424400000000000000000000002123000000000000005253440000000000000000002125510000000000000062636400000000000000002225252522230000000000002a390000000000000000252532323233000000000000002a10390000000000003233280000000000000000000000002a42434400000000002800000000000000000000000000525353440000003a290000000000000000000000003a626363640000001000000000000000000000003a282900000000000000280000000000000000000000380000000000000000222300000000000000004243437400000000000000002551003f0000000000006263640000000000000000002525223600000000000000000000000000000000000025323300000000000000000000000000000000000000260028000000000000000000000000000000000000003300380000000000000000000000000000000000000000002a28390000003e00010000000000000000000000000000002a2838282122222300000000000000000000000000000000000024252526003d00000000000000000000000000000000242525252223000000000000000000000000000000002425252525260000000000000000",
  "535364000000000000000000003125255354000000000000000000000000313253540000000000000000000000000000535400000000000000000000000000005364000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c0000000000000000000000000000003c0000000000000000000000000000212300000000000000000000000000002426003f00000000760000000000000024252223003e00002123003d00003d002425252522222222252522220100212225252525252525252525252522222525252525252525482525252525"
}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={
 [1]=-1,
	[2]=0,
	[6]=30,
	[7]=20,
	[14]=30
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
-->8

function obj_outline(n,x,y,w,h,flip_x,flip_y,is_floating)
  -- reset palette to black
  for c=1,15 do
    pal(c,0)
  end 
  -- draw outline
  spr(n,x-1,y,w,h,flip_x,flip_y)
  spr(n,x+1,y,w,h,flip_x,flip_y)
  spr(n,x,y-1,w,h,flip_x,flip_y)
  if (is_floating) spr(n,x,y+1,w,h,flip_x,flip_y)
  -- reset palette
  pal()
    	
end
__gfx__
0000000000000000000000000a2222200000000000000000000000000000000000aaaaa0000aaa000000a0005d5ddd5dddd5d5d5ddd5ddd50077777700000000
000000000a2222200a222220922222220a22222002222a00000000000a22222000a000a0000a0a000000a0005d555555555555d5555555550001111000000000
000000009222222292222222222ffff292222222222222900a22222092f1ff1200a909a0000a0a000000a000d55000000000055d000000001111171700000000
00000000222ffff2222ffff222f1ff12222ffff22ffff2209222222222fffff2009aaa900009a9000000a0005500000000000055000000000111119977000000
0000000022f1ff1222f1ff1202fffff022f1ff1221ff1f20222ffff222fffff20000a0000000a0000000a0005000000000000005000000001111117777880000
0000000002fffff002fffff000dddd0002fffff00fffff2022fffff202dddd200099a0000009a0000000a0005000000000000005000000001111177702888000
0000000000dddd0000dddd000700007007dddd0000dddd7002f1ff1000dddd000009a0000000a0000000a0000000000000000000000000000111777000288800
000000000070070000700070000000000000070000007000077ddd700070070000aaa0000009a0000000a000000000000000000000000000099d990000288880
dddddddd0000000000000000000000000000000000000000008888004999999449999994499909940bb00bb06665666500000000000000000000000070000000
dddddddd0000000000000000000000000000000000000000088888809111111991114119911409190b0bb0b06765676554444445007700000770070007000007
dd0000dd0000000000000000000000000aaaaaa0000000000878888091111119911191194940041988bbbb886770677045959594007770700777000000000000
dd0000dd007000700499994000000000a998888a0000000008888880911111199494041900000044288bb8820700070049559954077777700770000000000000
dd0000dd007000700050050000000000a988888a0000000008888880911111199114094994000000033bb3300700070049999994077777700000700000000000
dd0000dd067706770005500000000000aaaaaaaa0000000008888880911111199111911991400499033bb3300000000054444445077777700000077000000000
dddddddd567656760050050000000000a980088a0000000000888800911111199114111991404119088bb8800000000000044000070777000007077007000070
dddddddd566656660005500004999940a988888a0000000000000000499999944999999444004994088bb8800000000000044000000000007000000000000000
5777777557777777777777777777777516666666666666666666666157777775dddddddddddddddddddddddd5500000000000000000000000000000000000000
7777777777777777777777777777777711666666666666666666661177777777ddddddddddddddd00ddddddd66700000000a7000000777770000000000000000
7555555775557777755577777555555711666666666666666666661175555557dddddddddddddd0000dddddd67777000000aa000007766700000000000000000
5666666551665555566655555666661511166666666666666666611155666655ddddddddddddd000000ddddd6660000000033000076777000000000000000000
1666666116666666666666666666666111166666666666666666611116666661dddddddddddd00000000dddd5500000000033000077660000777770000000000
1666666116666666666666666666666111666666666666666666661116666661ddddddddddd0000000000ddd6670000000833300077770000777767007700000
1166611116666666666666666666666111666666666666666666661116666661dddddddddd000000000000dd6777700000388800070000000700007707777770
5111111516666666666666666666666116666666666666666666666116666661ddddddddd00000000000000d666000000033bb00000000000000000000077777
1666666116666666666666666666666157777777777777777777777516666661ddddddddd00000000000000d00000666083333300000000000d0000000000000
1666666116666666666666666666666177777777777777777777777716666661d0dddddddd000000000000dd0007777603883330000000000ddd000000000000
1166666116666666666666666666666177555775557777555775557716666661dddd00ddddd0000000000ddd000007660333888000000000ddadd00000000030
1166661116666666666666666666666175666556665555666556665716666661dddd00dddddd00000000dddd000000553333b338000000000ddd0000000000b0
1166661116666666666666666666666156666666666666666666666516666661ddddddddddddd000000ddddd00000666333333330000b00000d3000000000b30
1166661111166666666666666666611116666666666666666666666116666661dd0ddddddddddd0000dddddd0007777600044000000b0000000bb00003000b00
1666661111111666666666666661111111666666666666666666661111666611ddddddddddddddd00ddddddd0000076600044000030b00300000b00000b0b300
1666666151111111111111111111111551111111111111111111111551111115dddddddddddddddddddddddd0000005500999900030330300000b00000303300
0111100101666666077777777777777777777770077777700000000d600000006666666600000000000000000000000000000000000000000000000000000000
166661160016666670000666000066600000666770006667000ddd0dd0ddd0006666666600000000000000000000000000000000000000000000000000000000
15556666001666667011666111166611111666077016660700dd000dd000dd006666666600000000000000000000000007000000000000000000000000000000
1666566600016666701666111166611111666107706661070dd0000000000dd0666666660000000000000000000000000ee00000000000000000000000000000
1566666600016666706660000666000006660007766600070d11dddddddd11d0666666660000000000d0000000000000e0200000000000000000000000000000
0156666600166666766600006660000066600007766000070d1dddddddddd1d066666666000000000ddd00000000000020020000000000000000000000000000
0165566600166666700000000000000000010007700001070d1dddddddddd1d06666666600000000ddadd0000000000200002000000000000000000000000000
16666566016666667000000000000000000000077000000700d11111d1d11d0066666666000000000ddd000000000020000020000e0000000000000000000000
16666666666666107000000000000000000000077000000700dddddddddddd00000000000000000000d300000000002000000220e02000000000000000000000
01666666666661007000000100000000000000077011000700d11d1111d11d000000000000000000000bb0000000020000000002000200000000000000000000
01566566666661007000000000011000000000077011000700dddddddddddd0000000000000000000000b0000000200000000000000020000000000000000000
16555666666610007010000000011000000001077000010700ddd111d11ddd0000000000000000000000b0000000200000000000000000000000000000000000
16656666666610007000000000000000000000077000000700dddddddddddd00dddddddd0aaaaa000aaaaa00aa0000000aaaaa00aa000aa0aa000aa0aa000aa0
16556666666661007000000000000000000000077010000700dddddddddddd00ddddddddaaaaaaa0aaaaaaa0aa000000aaaaaaa0aaa00aa0aa000aa0aaa0aaa0
15561166666661007000000010000000000000077000000700dd77ddd7777d00ddddddddaa000000aa000aa0aa000000aa000aa0aaaa0aa0aa000aa0aaaaaaa0
0111001166666610700000000000000000000007700010070777777777777770dddddddd99999990990009909900000099999990999999909900099099999990
00000000000000007000000000000000000000077000000700777700d00000000000000d00000090990009909900009099000990990999909900099099090990
00aaaaaa000000007000000000000000000000077001000707000070dd000000000000dd99999990999999909999999099000990990099909999999099000990
0a999999000000007000000000001000000000077000000770770007ddd0000000000ddd09999900099999009999999099000990990009900999990099000990
a99aaaaa00000000700000011000000000000007700011077077ee07dddd00000000dddd00000000000000000000000000000000000000000000000000000000
a9aaaaaa0000000070000001100000000001000770001107700eee07dddddddddddddddd00000000000020000000000000000000000000000000200000000000
a99999990000000070100000000000000000000770100007700eee07dddddddddddddddd00000000002200000000000000000000000000000000020000000000
a9999999000000007000000000000000000000077000000707000070dddddddddddddddd00000000010000000000000000000000000000000000002000000000
a9999999000000000777777777777777777777700777777000777700dddddddddddddddd00000000200000000000000000000000000000000000002000000000
aaaaaaaa000000000777777777777777777777700777777000433300004300000040033300000001000000000000000000000000000000000000002000000000
a49494a1000000007000666000006660000066677000666700433333004330000043333300000020000000000000000000000000000000000000002002000000
a494a4a1000000007016661111166611111666077016660704200333042333330423330000000020000000000000000000000000000000000000001010200000
a49444aa000000007066611111666111116661077066610704000000040033300400000000000100000000000000000000000000000000000000000100020000
a49999aa000000007666000006660000066600077666000704000000040000000400000000000100000000000000000000000000000000000000000000010000
a4944499000000007660000066600000666000077660010742000000420000004200000000000100000000000000000000000000000000000000000000001000
a494a444000000006000000000000000000000077000000740000000400000004000000000000000000000000000000000000000000000000000000000000000
a4949999000000000777777777777777777777700777777040000000400000004000000000010000000000000000000000000000000000000000000000000010
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
00000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000
00000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000600000000000000000060000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000ee00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000d0000000000000e0200000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000ddd00000000000020020000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000ddadd0000000000200002000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000ddd000000000020000020000e0000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000d300000000002000000220e02000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000bb0000000020000000002000200000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b0000000200000000000000020000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b0000000200000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000aaaaa000aaaaa00aa0000000aaaaa00aa000aa0aa000aa0aa000aa0000000000000000000000000000000000000
000000000000000000000000000000000000aaaaaaa0aaaaaaa0aa000000aaaaaaa0aaa00aa0aa000aa0aaa0aaa0000000000000000000000000000000000000
000000000000000000000000000000000000aa000000aa000aa0aa000000aa000aa0aaaa0aa0aa000aa0aaaaaaa0000000000000000000000000000000000000
00000000000000000000000000000000000099999990990009909900000099999990999999909900099099999990000000000000000000000000000000000000
00000000000000000000000000000000000000000090990009909900009099000990990999909900099099090990000000000000000000000000000000000000
00000000000000000000000000000000000099999990999999909999999099000990990099969999999099000990000000000000000000000000000000000000
00000000000000000000000000000000000009999900099999009999999099000990990009900999990099000990000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000020000000000000000000000000000000200000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000002200000000000000000000000000000000020000000000000000000000000000000000000000000000
06000000000000000000000000000000000000000000010000000000000000000000000000000000002000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000200000000006000000000000000000000000002000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000701000000000000000000000000000000000000002000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000020000000000000000000000000000000000000002002000000000000000000000000000000000000000000
00000000000000000000000000000000000000000020000000000000000000000000000000000000001010200000000000000000000000000000000077000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000100020000000000000000000000000000000077000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000700000000
00000000000000000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550000500555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005505055005005550555000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005500055005005505055000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000555550050000555550000000000000000000000000000000000000000000000000000000
00000060000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055500550550600005550505000000550055055505550550055505050055000000000000000000000000000000000
00000000000000000000000000000000000055505050505000005050505000005000505055500500505005005050505000000000000000000000000000000000
00000000000000000000000000000000000050505050505000005500555000005000505050500500505005000500505000000000000000700000000000000000
00000000000000000000000000000000000050505050505000005050005000005000505050500500505005005050505000000000000000000000000000000000
00000000000000000000000060000000000050505500555000005550555000000550550050505550505055505050550000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000055055505550055055505500555050000000055055505550555000005550505000000000000000000000000000000000
00000000000000000000000000000000505050500500500005005050505050000000500050505550500000005050505005000000000000000000000000000000
00000000000000000000000000000000505055000500500005005050555050000000500055505050570000005500555000000000000000000000000000000000
00000000000000000000000000000000505050500500505005005050505050000000505050505050500000005050005005000000000000000000000000000000
00000000000000000000000000000000550050505550555055505050505055500000555050505050555000005550555000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000004020000000000000000000202000000030303030303030304040402020000000303030303030303040404020202020200631313131302020300000002020202004313131313020204000000020202020000131313130004040202020202020200001313131300000002020202020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000024252525252621222222230000002425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000024253232323331323232330000003125000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000031332a28283900000000000000000031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000003e000000000000270000002a2828282828282828282838000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000212222230000000030000000424343434344280000002a28000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000313232330000000030000000525353535354280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000002a3828290000000030000000626363636364280000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000424344000000282800000000003028282828283900003a28151a002123000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000006263640000002838000000000030003e00002a10676810290000002426000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002122236828280000000000222334362b002a2828290000003a2426000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003132334243434400000000252522232b00002a2828382828293133000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003a2828626363640b0c2123323232332b0000002a28290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002c002838000000000000003133300000000000003d0028000000003f20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001003c3a28280000000000000045003000013e00002122230b0c4244222223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
212222222328293e003f001c0000550030002123000024252600005254242526000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323233212222222222230000650030003133000031323300006264313233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
004000002a2550000000000000002d2250000000000000003123500000000000000000000000002d22500000322450000031235000002f235000002d225000002f23500000312550000034255000003125530205
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
00100020196103261032610326103161031610306102e6102a610256101b610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
00400000262550000000000000002d2250000000000000003123500000000000000000000000002d22500000322450000031235000002f235000002d225000002f2350000031255000002d255302053020500000
001000000000028650156200a62005610046000060000600016000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00 3d3e4344
00 3d7e4344
00 3d7e4344
00 3d4a4344
02 3d284344
00 41424344
00 41424344
01 383a3c44
02 393b3c44