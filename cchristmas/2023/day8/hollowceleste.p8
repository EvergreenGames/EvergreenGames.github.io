pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--✽hollow celeste v1.1✽

--a mod of celeste classic
--part of the advent mod jam
--v1.1 added after the jam
--by sparky9d and lord snek
--original game by:
--maddy thorson + noel berry

--mod based off of:
--~evercore~
--a celeste classic mod base
--v3.6 - tokens + flag fix
--cart by: taco360
--based on meep's smalleste
--and akliant's hex loading
--with help from gonengazit


function vector(x,y)
  return {x=x,y=y}
end

function rectangle(x,y,w,h)
  return {x=x,y=y,w=w,h=h}
end

fruit_count,prebosstimes,prebosstimem,prebosstimef,killedgrubs,dramatic_timer,
objects,got_fruit,
freeze,delay_restart,max_djump,
ui_timer,bossphase,prebuddytimef,prebuddytimes,prebuddytimem,changedkey_tmr=
0,0,0,0,0,0,{},{},
0,0,0,-99,0,0,0,0,0
keypal1,keypal2,changedkey_tmr={13,10,2},{10,2,14},0

poke(0x5f5c,255)
poke(0x5f2e,1)


cartdata("hollow_celeste_vx-snek_sparky")
if dget(0)==0 then
  dset(0,5)
end
dash_button,keys=dget(0),{"s","f","e","d","lshift/tab","a/q"}
menuitem(1,"dash: "..keys[dash_button])
menuitem(2,"set dash key",function()
  dash_button+=1
  if dash_button==7 then
    dash_button=1
  end
  dset(0,dash_button)
  menuitem(1,"dash: "..keys[dash_button])
  changedkey_tmr=120
end)
poke(0x5f5c,255)
poke(0x5f2e,1)


function _init()
  frames,start_game_flash=0,0
  music(37,0,3)
  load_level(0)
end



clouds={}
for i=0,16 do
  add(clouds,{
    x=rnd(128),
    y=rnd(128),
    spd=0.5+rnd(2),
    w=32+rnd(32)
  })
end

particles={}
for i=0,24 do
  add(particles,{
    x=rnd(128),
    y=rnd(128),
    s=flr(rnd(1.25)),
    spd=0.25+rnd(2.5),
    off=rnd(),
    c=6+rnd(2),
  })
end

dead_particles={}


player={
  init=function(this) --yuck lmao
    this.grace,this.jbuffer,this.hitbox,this.spr_off,this.solids,this.djump,this.dash_time,this.dash_target_x,this.dash_accel_x=0,0,rectangle(1,3,6,5),0,true,0,0,0,0,0
    this.hair={} --i genuinely have no idea why but this crashes if added to prev line
    for i=1,5 do
      add(this.hair,vector(this.x,this.y))
    end
    if checkgrubfight and allgrubskilled then
      pause_player,dramatic_timer,this.spr,this.djump=true,180,1,1
    end
  end,
  update=function(this)
    if pause_player then
      if dramatic_timer==120 then
        sfx"6"
      end
      return
    end
    
    local a,on_ground=this.check_here(spike),this.is_solid(0,1)
    if a and (a.spr%10==7 and sign(this.spd.y) or sign(this.spd.x))/sign(16-a.spr%20)<=0 then
      kill_player()
    end
    if this.check_here(thread) or this.check_here(web) or (((this.check(buddyok,0,-8) or this.check(buddyok,0,-16)) and allgrubskilled)) or this.check_here(postgrub) or this.check(buddytail,-4,4) or this.check_here(buddyjump) then
      kill_player()
    end
    local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0

    if this.y>lvl_ph then
      kill_player()
    end

    if on_ground and not this.was_on_ground then
      this.init_smoke(0,4)
    end

    local jump,dash,maxrun=btn(🅾️) and not this.p_jump,btn(dash_button-1,1) and not this.p_dash,1.8
    this.p_jump,this.p_dash,this.jbuffer=btn(🅾️),btn(dash_button-1,1),jump and 4 or deconeifpos(this.jbuffer)

    this.grace=on_ground and 6 or deconeifpos(this.grace)
    if on_ground and this.djump<max_djump then
      sfx"54"
      this.djump=max_djump
    end
    
    if this.dash_time>0 then
      this.init_smoke()
      this.dash_time-=1
      setspdv(this,appr(this.spd.x,this.dash_target_x,this.dash_accel_x),0)
    else

     this.spd.x=abs(this.spd.x)<=1.8 and
     appr(this.spd.x,h_input*maxrun,on_ground and 1.4 or 1.2) or
     appr(this.spd.x,sign(this.spd.x)*maxrun,0.15)

     if this.spd.x~=0 then
       this.flip.x=(this.spd.x<0)
     end

     local maxfall=3

     if h_input~=0 and this.is_solid(h_input,0) then
       maxfall=0.9
       if rnd(10)<2 then
         this.init_smoke(h_input*6)
       end
     end

     if not on_ground then
       setspdy(this,appr(this.spd.y,maxfall,0.32))
     end

     if this.jbuffer>0 then
       if this.grace>0 then
         sfx"1"
         this.jbuffer,this.grace,this.spd.y=0,0,-3.2
         this.init_smoke(0,4)
       else
         local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
         if wall_dir~=0 then
           sfx"2"
           this.jbuffer=0
           setspdv(this,-wall_dir*(maxrun+0.5),-3.3)
           this.init_smoke(wall_dir*6)
         end
       end
     end
      if this.djump>0 and dash then
        this.init_smoke()
        this.djump-=1
        this.dash_time,this.freeze=5,2
        setspdv(this,h_input~=0 and h_input*9 or this.flip.x and -5 or 5,2)
        sfx"3"
        this.dash_target_x,this.dash_accel_x=2*sign(this.spd.x),3.2
      elseif this.djump<=0 and dash and max_djump>0 then
        sfx"9"
        this.init_smoke()
      end
    end
    this.spr_off+=0.25
    this.spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or
      btn(⬇️) and 6 or
      btn(⬆️) and 7 or
      1+(this.spd.x~=0 and h_input~=0 and this.spr_off%4 or 0)

    move_camera(this)

    if (this.y<-4 or this.x>120 and checkgrubfight and allgrubskilled) then
      load_level(lvl_id+1)
    end

    this.was_on_ground=on_ground
  end,

  draw=function(this)
    pal(12,this.djump==1 and 8 or 12)
    draw_hair(this)
    draw_obj_sprite(this)
    pal(12,12)
  end
}




function draw_hair(obj)
  local last=vector(obj.x+4-(obj.flip.x and -1 or 1)*2,obj.y+((btn(⬇️) and not pause_player) and 4 or 3))
  for i,h in pairs(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    circfill(h.x,h.y,max(1,min(2,4-i)),12)
    last=h
  end
end


saw={
  update=function(this)
    if bossphase==2 then
      if  this.x<32 and this.y>36 then
        this.spd.y=-1
        if this.sfxready then
         sfx"42"
         this.sfxready=false
        end
      else
        setspdy(this,this.x<100 and this.y>40 and -1 or 0)
      end
    else
      this.sfxready=true
    end
    if frames%5==0 then
      this.flip.x=not this.flip.x
    end
  end
}

stalactite={
  init=function(this)
    this.hitbox,this.timer,this.solids=rectangle(2,-1,4,7),-1,true
  end,
  update=function(this)
    local hit=get_player()
    if not this.is_solid(0,1) then
      checkforplayer(this)
    end
    
     if this.timer==-1 and hit and hit.y>this.y and hit.y<this.y+96 and hit.x+hit.hitbox.x+hit.hitbox.w>this.x+this.hitbox.x and hit.x+hit.hitbox.x<this.x+this.hitbox.x+this.hitbox.w then
      this.timer=4
      this.init_smoke()
      sfx"23"
    end
    if this.timer==0 then
      if this.spd.y<3 then
        this.spd.y+=0.25
      end
    end
    this.timer=deconeifpos(this.timer)
  end,
  draw=function(this)
    spr(9,this.x,this.y-1)
  end
}

solid_nailable_thingy={
  update=function(this)
    this.metal=false
    if this.check_here(nail) and get_obj(nail).delay>2 then
      this.init_smoke()
      destroy_object(this)
    end
  end
}

fallable_block={
  init=function(this)
    this.spr,this.spd.y,this.timer=53,0,30
    fset(53,0,true)
  end,
  update=function(this)
    if bossphase==1 and this.timer>-1 then
       this.timer-=1
       this.y+=this.timer%2==1 and 1 or -1
       if this.timer==29 then
         sfx"58"
       end
       if bossphase==1 and this.timer<0 then
         fset(53,0,false)
        setspdy(this,2)
       end
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
  end
}

sherboss={
  init=function(this)
    this.health,this.cooldown,this.offset,this.attck,this.offset_ideal,this.metal,this.hitbox=bossphase==0 and 1 or 0,0,0,0,0,false,rectangle(0,0,16,8)
  end,
  update=function(this)
      this.attck-=1
      if this.attck>0 then
        this.y-=sgn(this.attck-61)
      end
    if this.attck==80 then
      local r=get_player().x-13
      init_object(thread,r,8)
      for i=0,5 do
        init_object(web,r+1+(6*i),8)
      end
      init_object(thread,r+37,8)
    end  
    this.cooldown-=1
    if this.check_here(nail) and get_obj(nail).delay>2 and this.attck<0 then
     this.init_smoke(4,0)
      if this.cooldown<0 then
        this.cooldown=10
        this.health-=1
        if this.health>=0 then
          this.attck=121
          sfx"35"
        else
          sfx"37"
        end
      end
    end
    if this.health<0 then
      if this.cooldown<0 then
        this.cooldown=30
      end
      if this.cooldown==0 then
        destroy_object(this)
        init_object(sherboss_run,this.x,this.y-2)
      end
    end
  end,
  draw=function(this)
    spr(112,4,this.y-this.offset-8,1,1) 
    spr((flr(this.attck%4/2)==1 or (this.attck<1 and this.health>-1)) and 23 or 128,0,this.y-this.offset-2,2,1)
  end
}

sherboss_run={
  init=function(this)
    this.onfire,this.spd.y,this.startphase,this.timer,this.right,this.counter,this.cooldown=false,2,bossphase==0 and 0 or 1,0,1,0,0
  end,
  update=function(this)
    this.cooldown-=1
    this.timer+=1
    if this.check(player,4,0) then
      kill_player()
    end
    if this.check(bubble,4,0) or this.check(fire,4,0) then
      this.onfire=true
    end
    checkforrope(this,this.check_here(rope),-4)
    checkforrope(this,this.check_here(rope2),4)
    if bossphase==1 then
      this.right=2
    end
    if this.counter==2 then
      this.right,bossphase=2,1
    end
    if this.y>87 and this.right==1 then
      setspdv(this,2,0)
    end
    if this.x>112 then
      this.right=0
    end
    if this.x<0 and this.right==0 then
      this.right=1
      this.counter+=1
    end
    if this.right==0 then
      this.spd.x=-2
    end
    if this.right==1 and this.spd.y==0 and this.counter<2 then
      this.spd.x=2
    end
    if this.x<0 and this.right==2 and this.cooldown<0 then
      this.spd.x,this.cooldown=0,40
    end
    if this.x<0 and this.right==2 and this.cooldown==0 and this.y<113 then
      setspdy(this,2)
    end
    if this.y>110 and this.cooldown<0 then
      this.cooldown=30
    end
    if this.y>110 and this.cooldown>0 then
      if this.startphase==0 then
        this.x=-3+(flr(this.cooldown%8/4)*-48)
        setspdy(this,0)
      else
         this.x=-(this.cooldown%2*48)
         setspdy(this,0)
      end
      if this.cooldown-this.startphase==29 then
        sfx"43"
      end
    end
    if this.y>110 and this.cooldown==0 then
      if this.startphase==0 then
       init_object(sherboss,0,8)
      else
       bossphase=2
      end
      destroy_object(this)
    end
    end,
    draw=function(this)
    if this.onfire then
      spr(134+(this.timer+2)%4/2,this.x,this.y-6)
    end
    spr(this.cooldown<15 and 98+flr(this.timer%4/2)*32 or 98,this.x,this.y,2,1)
    end
}
    

bubble={
  init=function(this)
    this.lifespan,this.spr=40,103
  end,
  update=function(this)
    this.lifespan-=1
    this.spr=this.lifespan<5 and 115 or 103
    if this.check(player,0,5) then
      kill_player()
    end
    if this.lifespan<0 or bossphase>0 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
  end
}

fire={
  draw=function(this)
    this.spr=70
    draw_obj_sprite(this)
  end
}

thread={
  init=function(this)
    this.x-=4
    this.spr,this.lifespan,this.timer=112,100-(this.y/2),0
  end,
  update=function(this)
    this.lifespan-=1
    this.timer-=1
    if this.lifespan==(96-(this.y/2)) and this.y!=0 then
     if this.y<86 then
      init_object(thread,this.x+4,this.y+8)
     end
    end
    if (this.lifespan<0 and this.y>7) or bossphase==2 then
      destroy_object(this)
      if this.y>80 then
        sfx"41"
      end
    end
    if this.y<8 then
      if this.check(nail,0,8) and get_obj(nail).delay>2 and this.timer<0 then
        this.timer=120
       end
    end
    setspdy(this,this.timer>0 and (this.timer>60 and -1 or 1) or 0)
  end,
  draw=function(this)
    draw_obj_sprite(this)
  end
}

rope={
  init=function(this)
    this.timer,this.spr=-1,132
    if this.y<88 then
      init_object(rope,this.x-1,this.y+8)
    end
  end,
  update=function(this)
    this.timer-=1
    if this.timer==-1 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
  end
}

rope2={
init=function(this)
  this.timer,this.spr=-1,133
    if this.y<88 then
      init_object(rope2,this.x+1,this.y+8)
    end
  end,
  update=function(this)
    this.timer-=1
    if this.timer==-1 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
  end
}

webfire={
  init=function(this)
    this.lifespan,this.spr=30,136--this.spr could theoretically automatically be set to 136 although i don't think so; check
  end,
  update=function(this)
    this.lifespan-=1
    local hit,hit2=this.check_here(rope),this.check_here(rope2)
    if hit and hit.timer<0 then
      hit.timer=30
    end
    if hit2 and hit2.timer<0 then
      hit2.timer=30
    end
    checkforplayer(this)
    --local s=hit2 and -1 or 1 --hehe shit 2
    if this.lifespan==15 and this.y>8 then
      init_object(webfire,this.x+(hit2 and -1 or 1),this.y-8)
    end
    if this.lifespan<0 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
  end
}

  

web={
  init=function(this)
    this.spr,this.lifespan=113,100-(this.y/2)
  end,
  update=function(this)
    this.lifespan-=1
    if this.lifespan==(96-(this.y/2)) and this.y<86 then
      init_object(web,this.x,this.y+8)
    end
    if this.lifespan<0 then
      destroy_object(this)
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
  end
}
  

lava={
  init=function(this)
    this.timer,this.spd.y=rnd(50)-45,0
  end,
  update=function(this)
    if this.timer>15 then
     setspdy(this,2)
    end
    checkforplayer(this)
    this.timer+=1
    
  if (this.y>90 or (this.y>90 and this.x>116)) and bossphase<1 then
    init_object(bubble,this.x,(this.y-this.y%8))
    bruh(this)
  end
  if this.y>106 then
    if bossphase<2 then
      bruh(this)
    else
      destroy_object(this)
    end
  end
  end,
  draw=function(this)
    this.spr=this.timer>15 and this.timer>-1 and 104+16*(flr(this.timer/5)%2) or this.timer>-1 and 116+(flr(this.timer/4)) or 100
    if this.spr!=115 then
      draw_obj_sprite(this)
    end
  end
}

spinner={
  init=function(this)
    this.dir,this.hitbox=1,rectangle(1,5,6,3)
  end,
  update=function(this)
    this.x+=this.dir
    if this.is_solid(this.dir,0) or this.dir==1 and this.x+1>lvl_pw-7 or this.x+1<1 then
      this.dir*=-1
    end
    checkforplayer(this)
  end,
  draw=function(this)
    this.spr=((11+frames/10))
    draw_obj_sprite(this)
  end
}

buddyok={
  init=function(this)
    this.grubthrowtimer,this.iframes,this.health,this.metal=0,0,10,false
    this.solids=not allgrubskilled
  end,
  update=function(this)
    this.iframes-=1 
    if (this.check(nail,0,10) or this.check_here(nail)) and get_obj(nail).delay>2 and this.iframes<0 then
      this.health-=1
      this.iframes=10
    end
    if this.health==0 and allgrubskilled then
      setspdv(init_here(buddyjump,this),2,-1)
      init_object(buddytail,this.x,this.y+16)
      destroy_object(get_obj(pregrub))
      destroy_object(this)
    end
    this.grubthrowtimer-=1
    if dramatic_timer<96 and dramatic_timer>63 then
      for x=72,105 do
        sset(x,dramatic_timer,sget(x,dramatic_timer)==6 and 14 or sget(x,dramatic_timer)==13 and 10 or sget(x,dramatic_timer)==5 and (rnd()>.5 and 3 or 11) or 0)
      end
    elseif dramatic_timer==-5 then
      for x=76,88 do
        for y=70,80 do
          if sget(x,y)==10 then
            sset(x,y,8)
            sset(x,y-1,8)
          end
        end
      end
    elseif dramatic_timer==-39 then
      bossphase=1 
    end
    if bossphase==1 and this.grubthrowtimer<0 then --bp1: cutscene over, throw undead grubs at player
      init_object(pregrub,this.x-12,this.y+12)
      this.grubthrowtimer=120
    end
  end,
 draw=function(this)
   spr(137,96,56,3.5,4)
 end
}

buddyjump={
  init=function(this)
    this.solids,this.timer,this.health,this.hitbox,this.iframes,this.metal=true,30,5,rectangle(0,0,28,16),0,false
  end,
  update=function(this)
  this.iframes-=1
  if this.check_here(nail) and get_obj(nail).delay>2 and this.iframes<0 then
    this.health-=1
    this.iframes=10
  end
  this.timer-=1
  setspdv(this,appr(this.spd.x,0,.1),this.spd.y+.21)
  if this.is_solid(0,1) and this.spd.x==0 and this.timer<1 then
    setspdv(this,2.5*sign(flr((get_player().x-this.x)/16)),this.timer>-1 and -1.7 or rnd()*2-4)
    sfx"7"
  end
  if this.health<1 then
    setspdv(this,(dramatic_timer%2-.5)*2,0)
    dramatic_timer-=1
    initbuddybit(this,-80)
  end
  end,
  draw=function(this)
  spr(137,this.x,this.y,3.5,2)
  end
}

buddybit={
  draw=function(this)
  local a=1.1*sign(this.spd.x)+sign(this.spd.y)--cursed and i'm not even convinced it needs to be
    spr(a==-2.1 and 137 or (a==.1 and  138.5 or (a==-.1 and 153 or 154.75)),this.x,this.y,1.5,1)
  end
}


buddytail={
  update=function(this)
    if dramatic_timer<-80 then
      dramatic_timer-=1
    end
    initbuddybit(this,-120)
  end,
  draw=function(this)
    spr(169,96,72,3.5,2)--could hardcode this line to save tokens but ew
  end
}

buddybitt={
  draw=function(this)
    local a=1.1*sign(this.spd.x)+sign(this.spd.y)--cursed and i'm not even convinced it needs to be
    spr(a==-2.1 and 169 or (a==.1 and  170.75 or (a==-.1 and 185 or 186.75)),this.x,this.y,1.75,1)
  end
}

    
pregrub={
  init=function(this)
   this.timer,this.spinrate,this.spr=1.8,.23,144
   sfx"62"
  end,
  update=function(this)
    this.spinrate*=1.03
    this.timer+=this.spinrate
    this.spr=144+this.timer%4
    if this.spinrate>2 then
      init_here(postgrub,this)
      destroy_object(this)
    end
  end,
  draw=function(this)
    if not pause_player then
      draw_obj_sprite(this)
    end
  end
}

postgrub={
  init=function(this)
    this.solids,this.timer,this.state,this.spd.x,this.player,this.spr=true,40,0,-5,get_player(),152
    setspdy(this,8*(this.y-this.player.y)/(this.player.x-this.x))
    if abs(this.spd.y)>6 then
      setspdy(this,-8*sign(this.y-this.player.y))
    end
  end,
  update=function(this)
   if this.spd.x~=0 then
      this.flip.x=this.spd.x<=0
    end
    if this.check(buddyok,-4,-16) then
      destroy_object(this)
      this.init_smoke()
    end
    this.timer-=1
    if this.state<1 then
      this.timer-=1
      if this.spd.x<-.1 then 
        this.spd.x+=.2
      end
      this.spd.y*=.9
    else
      setspdv(this,this.x<121 and appr(this.spd.x,0,.1) or 0,this.spd.y+.21)
      for g=-1,1 do
        if this.is_solid(g,0) then
          this.spd.x=.4*g
        end
      end
      if this.timer<0 then
        this.timer=60
        setspdv(this,2.5*sign(this.player.x-this.x),rnd()*-2-2)
        sfx"39"
      end
    end
  end,
  draw=function(this)
    if this.state<1 then
      spr(this.timer>0 and 148 or 149-(this.timer/4),this.x,this.y)
      if this.timer<-12 then
        local i=0
        for o in all(objects) do
         if o.type==postgrub then
          i+=1
         end
        end
        if i>11 then
          destroy_object(this)
          this.init_smoke()
        end
          this.state,this.timer=1,40
      end
    else
      draw_obj_sprite(this)
    end
  end,
}
  

nail={
  init=function(this)
    this.delay,this.sprtimer,this.persistent_dir=0,0,0
  end,
  update=function(this)
      local hit=get_player()
    if btnp(❎) and this.delay==0 and not pause_player then
      if btn(2) then
        this.dir,this.hitbox=1,rectangle(1,-2,6,10)
      elseif btn(3) then
        this.dir,this.hitbox=3,rectangle(1,0,6,10)
      elseif btn(0) then
        this.dir,this.hitbox=4,rectangle(-2,1,10,6)
      elseif btn(1) or not hit.flip.x then
        this.dir,this.hitbox=2,rectangle(0,1,10,6)
      else
        this.dir=4
        if this.dir%2==0 then
          this.hitbox=rectangle(this.dir==4 and -2 or 0,1,10,6)
        end
      end
      this.persistent_dir,this.delay,this.sprtimer=this.dir,9,6
    end
    this.x,this.y=this.sprtimer>0 and hit.x+(this.persistent_dir==2 and 8 or this.persistent_dir==4 and -8 or 0) or hit.x,this.sprtimer>0 and hit.y+(this.persistent_dir==3 and 8 or this.persistent_dir==1 and -8 or 0) or hit.y
    if this.delay>3 then
      for o in all(objects) do
        local t=o.type
        if t==spike or  t==saw or t==solid_nailable_thingy or (t==buddyok and allgrubskilled) or t==postgrub or t==spinner or t==sherboss or t==stalactite or t==buddyjump or t==postgrub or (this.dir==3 and (t==grub or t==grub2 or t==grubdead)) --[[and ((this.check(t,0,0) or (t==buddyok and this.check(t,0,-10))))--]] then
          if this.check_here(t) or this.check(buddyok,0,-10) then --free tokens?--most readable token optimized code (also shoutouts to discord user thatfinn aka thatfinn)
           hit.spd,this.delay,hit.dash_time=vector(this.dir%2==1 and hit.spd.x or 3.2*this.dir-9.6,this.dir==1 and 2 or this.dir%2==0 and -1.8 or -3.3),4,0
           if t~=grub then
             sfx(o.metal and 44 or 45)
           end
           this.init_smoke()
           break
          end
        end
      end
    end
    this.delay=deconeifpos(this.delay)
    if this.delay==3 then
      this.dir=0
    end
    
     this.sprtimer=deconeifpos(this.sprtimer)
  end,
  draw=function(this)
    if this.sprtimer>0 then
      spr(65+(this.persistent_dir%2==0 and 2 or 1)+(this.sprtimer>3 and 2 or 0),this.x,this.y,1,1,this.persistent_dir==4,this.persistent_dir==3)
    end
  end
}

flag={
  init=function(this)
    time_ticking=allgrubskilled and checkgrubfight
    this.show=not time_ticking or  checktruesummit
  end,
  draw=function(this)
    if this.show and get_player().spd then
      camera()
      rectfill(27,2,101,39,0)
      if checktruesummit then
        spr(23,28,15,2,1,false,true)
        spr(82,33,6)
        local a,b,c=frames,minutes,seconds
        frames,minutes,seconds=prebuddytimef,prebuddytimem,prebuddytimes
        draw_time(44,9)
        frames,minutes,seconds=a,b,c
      else
        spr(82,51,6)
        ?"x"..fruit_count.."/11",60,9,fruit_count==11 and 9 or 7--disturbing implications
      end
      draw_time(48,16)
      ?"deaths:"..deaths,50,31,deaths==0 and 9 or 7
      camera(draw_x,draw_y)
    end
  end
}

flower={
  draw=function(this)
    spr(allgrubskilled and dramatic_timer<140 and get_player().spd and checkgrubfight and 114 or 62,this.x,this.y)
  end
}

prehunter={
  update=function(this)
    destroy_object(this)
    if fruit_count==11 then
      init_here(hunter,this)
    end
  end
}

hunter={
  draw=function(this)
    spr(101,24,88,2,1)
    if this.player_here() or this.check(player,8,0) then
      rectfill(10,45,117,83,6)
      rect(10,45,117,83,5)
      ?"you are impressive",29,48,5
      ?"little squib. do you",25,55,5
      ?"long for the hunt too?",22,62,5
      ?"prove yourself worthy",24,69,5
      ?"slay all of the beasts",22,76,5
    end
  end
}

player_spawn={
  init=function(this)
    sfx"4"
    this.spr,this.target,this.y,cam_x,cam_y,this.spd.y,this.state,this.delay,this.hair=3,this.y,min(this.y+48,lvl_ph),max(64,min(lvl_pw-64,this.x)),max(64,min(lvl_ph-64,this.y)),-4,0,0,{}
    for i=1,5 do
      add(this.hair,vector(this.x,this.y))
    end
  end,
  update=function(this)
    if this.state==0 then
      if this.y<this.target+16 then
        this.state,this.delay=1,3
      end
    elseif this.state==1 then
      this.spd.y+=0.5
      if this.spd.y>0 then
        if this.delay>0 then
          setspdy(this,0)
          this.delay-=1
        elseif this.y>this.target then
          this.y,this.state,this.delay=this.target,2,5
          setspdv(this,0,0)
          this.init_smoke(0,4)
          sfx"5"
        end
      end
    elseif this.state==2 then
      this.delay-=1
      this.spr=6
      if this.delay<0 then
        destroy_object(this)
        init_here(player,this)
        init_here(nail,this)
        if (checkgrubfight and (not allgrubskilled)) or  checktruesummit then
          sfx"55"
        end
      end
    end
    move_camera(this)
  end,
  draw=function(this)
    pal(12,(max_djump==1 and lvl_id!=21) and 8 or 12)
    draw_hair(this)
    draw_obj_sprite(this)
    pal(12,12)
  end
}

spring={
	init=function(this)
		this.dy,this.delay=0,0
	end,
	update=function(this)
		local hit=this.player_here()
		if this.delay>0 then
			this.delay-=1
		elseif hit then
			hit.y,hit.spd.y,this.dy,this.delay,hit.djump=this.y-4,-4.2,4,10,max_djump
			hit.spd.x*=0.2
			sfx"8"
		end
	 this.dy*=0.75
	end,
	draw=function(this)
		local dy=flr(this.dy)
		sspr(16,8,8,8-dy,this.x,this.y+dy)
	end
}

smoke={
  init=function(this)
    setspdv(this,0.3+rnd(0.2),-0.1)
    this.flip=vector(rnd()<0.5,rnd()<0.5)
    this.x+=-1+rnd(2)
    this.y+=-1+rnd(2)
  end,
  update=function(this)
    this.spr+=0.2
    if this.spr>=32 then
      destroy_object(this)
    end
  end
}


function get_obj(o)
  for obj in all(objects) do
    if obj.type==o then
      return obj
    end
  end
  return vector(0,0) 
end

spike={
  init=function(this)
    this.hitbox=this.spr==17 and rectangle(0,5,8,3) or (this.spr==27 and rectangle(0,0,8,3) or (this.spr==43 and rectangle(0,0,3,8) or rectangle(5,0,3,8)))
  end,
  update=function(this)
    local a=this.check(spike,this.spr<40 and 1 or 0,this.spr>40 and 1 or 0)
    if a and a.spr==this.spr then
      if this.spr%10==7 then
        this.hitbox.w+=a.hitbox.w
      else
        this.hitbox.h+=a.hitbox.h
      end      
      destroy_object(a)
    end
  end
} 



sign1={
  draw=function(this)
    draw_obj_sprite(this)
    if this.player_here() then
      if lvl_id<8 then
        rectfill(10,50,117,80,6)
        rect(10,50,117,80,5)
        ?"⬆️",72,53,5
        ?"press x/v+⬅️⬇️➡️ to",24,59,5
        ?"swing your sword. use it",16,66,5
        ?"to bounce off of spikes.",16,73,5
      else
        rectfill(15,50,117,80,6)
        rect(15,50,117,80,5)
        ?"-- hollownest --",33,53,5
        ?"this memorial to",33,60,5
        ?"all the lost grubs",30,67,5
        ?"may they come home",30,74,5
      end
    end
  end
}

sign2={
  draw=function(this)
    draw_obj_sprite(this)
    if this.player_here() then
      rectfill(10,55,117,71,6)
      rect(10,55,117,71,5)
      ?"press z/c to jump",30,58,5
      ?"and walljump.",38,64,5
    end
  end
}

sign3={
  draw=function(this)
    draw_obj_sprite(this)
    if this.player_here() then
      rectfill(10,55,117,72,6)
      rect(10,55,117,72,5)
      ?"break open the glass jars",15,58,5
      ?"to free the grubs.",27,65,5
    end
  end
}

sign4={
  draw=function(this)
    draw_obj_sprite(this)
    if this.player_here() then
      rectfill(10+camx,64+camy,117+camx,80+camy,6)
      rect(10+camx,64+camy,117+camx,80+camy,5)
      ?"spike bounces work in",22+camx,66+camy,5
      ?"4 directions.",38+camx,73+camy,5
    end
  end
}
--never used function, unfortunate because it looks kinda neat
--[[function srng()
  srand(currseed)
  currseed=rnd()
  srand(rnd())
  return currseed
end--]]

grub={
  if_not_fruit=true,
  init=function(this)
    this.hitbox,this.metal=rectangle(2,5,12,11),false
  end,
  update=function(this)
    local hit=this.check_here(nail)
    if hit and hit.delay>2 then
      init_object(grub2,this.x+4,this.y+8)
      got_fruit[lvl_id]=true
      fruit_count+=1
      destroy_object(this)
      sfx"45"
    end
  end,
  draw=function(this)
    spr(64,this.x,this.y,2,2)
  end
}

grub2={
  init=function(this)
    this.hitbox,this.solids,this.iframes,this.spr,this.metal=rectangle(1,2,6,6),true,7,82,false
  end,
  update=function(this)
    if not this.is_solid(0,1) then
      setspdy(this,appr(this.spd.y,2,0.32))
    elseif frames%30==0 and this.spr~=96 then
      setspdy(this,-2)
    end
   this.iframes=deconeifpos(this.iframes)
    if this.spr~=96 then
      if this.check_here(nail) and this.iframes<1 and get_obj(nail).delay>2 then
        killedgrubs+=1
        this.spr,this.hitbox,this.metal,allgrubskilled=96,rectangle(1,4,6,4),true,killedgrubs==11
        fruit_count-=1
        setspdv(init_object(grubdead,this.x,this.y-2),2*(get_player().x<this.x and 1 or -1),-2)
        sfx"45"
      end
    end
  end,
  draw=function(this)
    draw_obj_sprite(this)
    if this.spr~=96 then
      line(this.x+3,this.y-1,this.x+6,this.y-1,3)
    end
  end
}

grubdead={
  update=function(this)
    this.hitbox,this.solids,this.spr=rectangle(2,4,4,4),true,97
    setspdy(this,appr(this.spd.y,2,0.5))
    this.spd.x*=(this.x<-1 or this.x>377) and 0 or 0.8--minorly jank but not too bad compared to some other stuff i tried
  end
}

cloak={
  init=function(this)
    this.hitbox,this.timer=rectangle(1,4,6,4),-1
  end,
  update=function(this)
    this.spr=83+frames/10
    local hit=this.player_here()
    if hit and max_djump==0 then
      max_djump,hit.djump,this.timer,pause_player=1,1,150,true
      setspdv(hit,0,0)
      sfx"51"
    end
    if this.timer>-1 then
      this.timer-=1
      if btn(❎) and this.timer<121 then
        this.timer=1
      end
    else
      pause_player=false
    end
  end,
  draw=function(this)
    spr(71,104,96,1,2)
    spr(86,96,104)
    if max_djump==0 then
      draw_obj_sprite(this)
    end
    if this.timer>0 then
     rectfill(10,52,117,74,6)
     rect(10,52,117,74,5)
     ?"mothwing cloak",36,55,5
     ?"press "..keys[dash_button].." to",64-(#keys[dash_button]+9)*2,61,5
     ?"dash sideways.",36,67,5
    end
  end
}


-- ssssssssssss
tiles={
  [1]=player_spawn,
  [8]=saw,
  [9]=stalactite,
  [10]=solid_nailable_thingy,
  [11]=spinner,
  [17]=spike,
  [18]=spring,
  [19]=sign1,
  [20]=sign2,
  [21]=sign3,
  [22]=sign4,
  [23]=sherboss,
  [27]=spike,
  [43]=spike,
  [53]=fallable_block,
  [59]=spike,
  [62]=flower,
  [64]=grub,
  [83]=cloak,
  [101]=prehunter,--omg owl house refernec i lvoe falpjack petre griffer!!
  [104]=lava,
  [132]=rope,
  [133]=rope2,
  [137]=buddyok,
  [255]=flag
}


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
    metal=true,
    x=x,
    y=y,
    hitbox=rectangle(0,0,8,8),
    spd=get_obj(),
    rem=get_obj(),
  }

  function obj.is_solid(ox,oy)
    return (oy>0 and not obj.check(platform,ox,0) and obj.check(platform,ox,oy)) or
           tile_flag_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h,0) or
           obj.check(grub,ox,oy) or
           obj.check(solid_nailable_thingy,ox,oy)
  end

  function obj.check_here(a)
    return obj.check(a,0,0)
  end

  function obj.check(type,ox,oy)
    for other in all(objects) do
      local a,b=other.hitbox,obj.hitbox
      if other and other.type==type and other~=obj and other.collideable and
        other.x+a.x+a.w>obj.x+b.x+ox and
        other.y+a.y+a.h>obj.y+b.y+oy and
        other.x+a.x<obj.x+b.x+b.w+ox and
        other.y+a.y<obj.y+b.y+b.h+oy then
        return other
      end
    end
  end

  function obj.player_here()
    return obj.check_here(player)
  end

  function obj.move(ox,oy,start)
    for axis in all({"x","y"}) do
      obj.rem[axis]+=axis=="x" and ox or oy
      local amt=flr(obj.rem[axis]+0.5)
      obj.rem[axis]-=amt
      if obj.solids then
        local step=sign(amt)
        local d=axis=="x" and step or 0
        for i=start+1,abs(amt) do
          if not (obj.is_solid(d,step-d) or (axis=="x" and (obj[axis]+d<-1 or obj[axis]+d>lvl_pw-7))) then
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

function kill_player()
  local obj=get_player()
  delay_restart,dead_particles=15,{}
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
  destroy_object(get_obj(nail))
  end
end


function load_level(lvl)
  sfx"-1"  
  has_key,bossphase,cam_spdx,cam_spdy=false,0,0,0
  foreach(objects,destroy_object)
  local diff_room=lvl_id~=lvl
  lvl_id=lvl
  is_title,checkgrubfight,checktruesummit=lvl_id==0,lvl_id==28,lvl_id==29

  local tbl=split(levels[lvl_id])
  lvl_x,lvl_y,lvl_w,lvl_h,lvl_title,lvl_area=tbl[1],tbl[2],tbl[3]*16,tbl[4]*16,tbl[5],tbl[6]
  lvl_pw,lvl_ph=lvl_w*8,lvl_h*8

  if allgrubskilled and checkgrubfight then
    lvl_title="grub avenger"
  end
  if diff_room then
    if lvl_id==27 then
      music(56,0,3)
    end
    if checktruesummit then
      music(43,0,3)
    end
  end
  if checkgrubfight then 
    music(allgrubskilled and -1 or 43,0,3)
  end
  
  if not is_title then
   if diff_room then reload() end
  	ui_timer=5
  end
  
  if lvl==27 then
    sprindex=0
    for y=64,71 do
      for x=0,71 do
        sprindex+=1
        sset(x,y,sprdata[sprindex]=="b" and 14 or sprdata[sprindex])
      end
    end
  end
  
  
  if lvl==28 then
    local sprindex=0
    --returnstr=""
    for y=72,79 do
      for x=0,71 do
        sprindex+=2
        --sset(x,y,sprdata2[sprindex])
        sset(x,y,sprdata2[sprindex]=="a" and 10 or (sprdata2[sprindex]=="e" and 14 or sprdata2[sprindex]))
        --returnstr=returnstr..sget(x,y)
      end
    end
    sprindex=0
    for y=64,95 do
      for x=72,99 do
        sprindex+=2
        sset(x,y,sprdata3[sprindex]=="d" and 13 or sprdata3[sprindex])
      end
    end  
  end
  
  
  if diff_room and split(mapdata[lvl_id],",",false) then
  	 if mapdata[lvl_id] then
  	   for i=1,#mapdata[lvl_id],2 do
       mset(lvl_x+i\2%lvl_w,lvl_y+i\2\lvl_w,"0x"..sub(mapdata[lvl_id],i,i+1))
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


function _update()
  changedkey_tmr=(deconeifpos(changedkey_tmr))
  if dramatic_timer>-40 then
    dramatic_timer-=1
    if dramatic_timer==-39 and checkgrubfight then
      music(56,0,3)
    end
  elseif checkgrubfight then
    pause_player=false
  end
  if lvl_id>26 and prebosstimef+prebosstimem+prebosstimes==0 then
    prebosstimef,prebosstimem,prebosstimes=frames,minutes,seconds
  end
  if checkgrubfight and prebuddytimef+prebuddytimem+prebuddytimes==0 then
    prebuddytimef,prebuddytimem,prebuddytimes=frames,minutes,seconds
  end
  if time_ticking then
    frames+=1
    seconds+=frames\30
    minutes+=seconds\60
    seconds%=60
  end
  frames%=30
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
    obj.move(obj.spd.x,obj.spd.y,0)--token save; this function is only used once
    if obj.type.update then
      obj.type.update(obj)
    end
  end)

  -- start game
  if is_title then
    if start_game then
      start_game_flash-=1
      if start_game_flash<=-30 then
        max_djump,deaths,frames,seconds,minutes,time_ticking=0,0,0,0,0,true
        music(43,0,3)
        load_level(1)
      end
    elseif btn(🅾️) or btn(❎) then
      music"-1"
      start_game_flash,start_game=50,true
      sfx"38"
    end
  end
end


function _draw()
  if freeze>0 then
    return
  end

  pal()

  if is_title and start_game then
    local c=start_game_flash>10 and (frames%10<5 and 7 or 10) or (start_game_flash>5 and 2 or start_game_flash>0 and 1 or 0)
    if c<10 then
      for i=1,15 do
        pal(i,c)
      end
    end
  end

  camx,camy=is_title and 0 or round(cam_x)-64,is_title and 0 or round(cam_y)-64
  camera(camx,camy)

  local xtiles,ytiles=lvl_x*16,lvl_y*16

  cls()

  if not is_title then
    foreach(clouds, function(c)
      c.x+=c.spd-cam_spdx
      ovalfill(c.x+camx,c.y+camy,c.x+c.w+camx,c.y+16-c.w*0.1875+camy,14)
      if c.x>128 then
        c.x,c.y=-c.w,rnd(120)
      end
    end)
  end

  if lvl_id>8 then
    pal(0,128,1)
    pal(1,129,1)
  end
  for a=1,2 do		
		  map(xtiles,ytiles,0,0,lvl_w,lvl_h,a*4)
  end
  foreach(objects, function(o)
    if o.type==stalactite then
      draw_object(o)
    end
  end)

  map(xtiles,ytiles,0,0,lvl_w,lvl_h,2)

  foreach(objects, function(o)
    --if o.type~=stalactite then
      draw_object(o)
    --end
  end)

  foreach(particles, function(p)
    p.y+=p.spd-cam_spdy
    p.x+=sin(p.off)-cam_spdx
    p.off+=min(0.05,p.spd/32)
    rectfill(p.x+camx,p.y%128+camy,p.x+p.s+camx,p.y%128+p.s+camy,p.c)
    if p.y>132 then
      p.y,p.x=-4,rnd(128)
   	elseif p.y<-4 then
     	p.y,p.x=128,rnd(128)
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
  	 	local a,b,c,d=camx+60,camy+2,camx+124,camy+12
  	 	if lvl_area then
       a-=36
       b+=56
       c-=20
       d+=58
     end
     rectfill(a,b,c,d,0)
     rect(a,b,c,d,6)
     ?lvl_title,(lvl_area and 64 or 93)-#lvl_title*2+camx,lvl_area and 62 or 5+camy,7
     draw_time(4+camx,4+camy)
  	end
  	ui_timer-=1
  end

  if is_title then
				sspr(72,32,56,32,36,18)
				print3d("z/x/c/v",48,57,5)
				print3d("original game by:",32,70,7)
    print3d("maddy thorson",38,78,6)
    print3d("noel berry",44,85,6)
    print3d("mod by:",50,93,12)
    print3d("sparky9d",48,101,13)
    print3d("lord snek",46,108,13)
  end
  if changedkey_tmr>0 then
    if changedkey_tmr<16 then
      fillp(0b0101101001011010.1)
    end
    rectfill(cam_x-58,changedkey_tmr/15+cam_y-6,57+cam_x,changedkey_tmr/15+cam_y+6,keypal1[flr(changedkey_tmr/40)+1])
    rect(cam_x-58,changedkey_tmr/15+cam_y-6,57+cam_x,changedkey_tmr/15+cam_y+6,keypal2[flr(changedkey_tmr/40)+1])
    ?"dash key set to: "..keys[dash_button].."!",cam_x-(#keys[dash_button]*2+36),changedkey_tmr/15+cam_y-2,keypal2[flr(changedkey_tmr/40)+1]
    fillp()
  end
  pal(3,131,1)
  pal(15,140,1)
  pal(14,130,1)
  pal(11,3,1)
  pal(10,141,1)
end

function print3d(text,x,y,c)
  ?text,x+1,y+1,1
  ?text,x,y,c
end

function draw_object(obj)
  (obj.type.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj)
  spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
end

function draw_time(x,y)
  rectfill(x,y,x+44,y+6,0)
  local t,u,v=x+1,y+1,7
  if x==48 then 
    ?two_digit_str(prebosstimem\60)..":"..two_digit_str(prebosstimem%60)..":"..two_digit_str(prebosstimes).."."..two_digit_str(flr((100*prebosstimef)/30)),x-3,y+1,minutes<5 and 9 or 7
    t,u,v=x-3,y+8,minutes<6 and 9 or 7--actually huge --why did i say this
  elseif y==9 and prebuddytimem<6 then
    v=9
  end
    ?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds).."."..two_digit_str(flr((100*frames)/30)),t,u,v
end

function setspdv(obj,x,y)
  obj.spd=vector(x,y)
end

function deconeifpos(var)
  if var>0 then
   var-=1
  end
  return var
end

function setspdy(obj,y)
  obj.spd.y=y
end

function initbuddybit(obj,num)
  if dramatic_timer<num then
      for x=-5,5,10 do
        for y=-5,5,10 do
          setspdv(init_here(num==-80 and buddybit or buddybitt,obj),x,y)
          sfx"40"
        end
      end          
      destroy_object(obj)
    end
end
function get_player()
  return get_obj(player)
end

function bruh(obj) --roundelie reference! also ew wtf i hate this token save i hate this token save i hate this token save i apparently don't care about compressed space
  obj.y,obj.timer,obj.spd.y,obj.x=8,rnd(50)-50,0,rnd(108)+16
end

function checkforrope(obj,hit,xoffset)
  if hit and obj.onfire and hit.timer<0 then
    hit.timer=30
    init_object(webfire,hit.x+xoffset,hit.y)
  end
end

function checkforplayer(obj)
  if obj.player_here() then
    kill_player()
  end
end

function init_here(initee,initer)
  return init_object(initee,initer.x,initer.y) --i don't understand what's going on here at all but idrc too much because it seems to work?
end


function two_digit_str(x)
  return x<10 and "0"..x or x
end


function round(x)
  return flr(x+0.5)
end


function appr(val,target,amount)
  return val>target and max(val-amount,target) or min(val+amount,target)
end

function sign(v)
  return v~=0 and sgn(v) or 0
end


function tile_flag_at(x,y,w,h,flag)
  for i=max(0,x\8),min(lvl_w-1,(x+w-1)/8) do
    for j=max(0,y\8),min(lvl_h-1,(y+h-1)/8) do
      if fget(mget(lvl_x*16+i,lvl_y*16+j),flag) then
        return true
      end
    end
  end
end
-->8
--scrolling level stuff
sprdata,sprdata2,sprdata3,levels,mapdata="50505000000055050005505005000000060000000000006000000008000000000000000055505000000505550050555555550000060000000000006000000000000000000000000055550030030555500055058bb855550006000000000000600080000009000000009000005505003333050555005505500505550006000000000000600088080000000000000000800055505005505500005050333300505506000000000000600899000000000800080089000055558bb850550005555030030055550600000000000060809090008080000000090000005055555555050055505000000505550600000000000060000080000899808008098800000550500505500050550000000505056000000000000006009000000880900000899800","0000020202020000000002020202000000000a0a0a0200000000020a0a0a00000e030e000000000000000e0e0e030e0e00000e0e0e030e0e00000e0e0e030e0e00000e0e0e030e0e00020202020202000002020202020200000a0a0a02020200000202020a0a0a000e020e0000000e000000030e020e020e0000030e020e020e0000030e080e080e0000030e080e080e020202020202020202020202020202020a0a0a020202020202020202020a0a0a0e0e0e0e000e0e0e000e0e0e0e0e0e03000e0e0e0e0e0e03000e0e0e0e0e0e03000e0e0e0e0e0e03020202030202020a0a020202030202020a0a0202020202020202020202020a0a0e020e0e030e0e03000e0e0a030e0000000e0e0a030e0000000e0e0a030e0000000e0e0a030e00000202020202020a0a0a0a0202020202020a02020203020202020202030202020a030e0e0a0e0e0a0a00030a0e0e00000000030a0e0e00000000030a0e0e00000000030a0e0e00000002020202020a0a0a0a0a0a0202020202020202020202020202020202020202020e0e0e030a0a0e0e000e0a0e0e000000000e0a0e0e000000000e0a0e0e000000000e0a0e0e000000000202020a0a0a00000a0a0a02020200000202020202020000020202020202000000000e0e0e0000000e0e0a03000000000e0e0a03000000000e0e0a03000000000e0e0a000000000000020a0a0a000000000a0a0a02000000000202020200000000020202020000000000000000000000000e0a0e0e000000000e0a0e0e000000000e0a0e0e00000e0e0e0a00000000","000000060606060606060606060606060606060506000000000000000006060606060606060605060606060606060606060606000000000006050606060506060606060606060506060606060606050000000000060606060606060606060606060606060606060606060606000000000606060606060606060606060606060606060506060606060000000006060506060606060506060606050606060606060606060500000000060606060d0d0d0d060606060d0d0d0d060606050606060600000000060606060d0d0d0d060606060d0d0d0d060606060606060606000000060606060606060606060606060606060606060606060606060606000006060606060606060506060606060606050606060605060506060000060606060606060606060606060606060606060606060606060606000000060605060606060606050606060606060606060606060606060000000000000506050606060606060606060d0d0d0d0606060606050000000000000606060606060606060606060d0d0d0d0606060606060000000000000606060606060606050606060d0d0d0d0606060606060000000000000006060606060606060606060d0d0d0d060506060506000000000000000006060606060606060606060606060d0d0d0d0606000000000000000000000605060606060605060605060d0d0d0d0606000000000000000000000006060605060606060606060d0d0d0d0506000000000000000000000006060606060606060606060d0d0d0d0606000000000000000000000006060606060606060605060d0d0d0d0606000000000000000000000006060606060606050606060d0d0d0d0606000000000000000000000006050605060606060606060d0d0d0d0606000000000000000000000006060606060606060606060d0d0d0d06060000000000000000000000060606060606060d0d0d0d0606060606060000000000000000000000060606060605060d0d0d0d0606060606000000000000000000000000060506060606060d0d0d0d0606060606000000000000000000000006060506060606060d0d0d0d0605060600000000000000000000000606060606060606060d0d0d0d0606000000000000000000000000060605060606060606060d0d0d0d0606000000000000000000000006050606060506060606060d0d0d0d0600000000000000000000000606060606060606050606060d0d0d0d060000000000",

--every other 0 is unecessary in sprdata2 and 3, but idc much.
	 {[0]="-1,-1,1,1", 
	 "0,0,1,1,king's pass,1",
	 "0,0,1,1,the corner",
	 "0,0,1,1,cliff maze",
	 "3,0,1,1,roundabout",
	 "0,0,1,1,spike juggling",
	 "1,0,1,1,recoil",
	 "0,0,2,1,unstable tunnel",
	 "0,0,1,1,old site,1",
	 "0,0,1,1,saw pit", 
	 "0,0,2,1,passageway",
	 "6,2,1,2,overhang",
	 "2,1,1,2,rockslide", 
	 "0,0,1,1,sibling's grave,1",
	 "0,0,2,1,hallownest ring,1",
	 "6,0,1,1.5,long fall",
	 "3,2,1,2,old trail",
	 "7,0,1,1,roomba rumble",
	 "0,0,2,1,detour",
	 "0,0,1,1,trap",
	 "0,1.5,2,1.5,ancient depths",
	 "7,1,1,1,think fast,1",
	 "7,2,1,1,demolition", --1 no more
	 "3,1,1,1,unstable cage",
	 "4,1,1,3,skyline",
	 "5,0,1,4,elevator shaft",
	 "0,3,3,1,long way out",
	 "0,0,1,1,grub trapper,1",
	 "2,0,1,1,grub hub,1",
	 "4,0,1,1,roomba refuge,1"
},


{[1]="25252526391900313232252624252525254825262a38393a292a31333125482525253233002a2e29000000002a313232323329000000000000000000000f2a392223004000003d15000000000000002a25263900003a21233900003e00003a39252523212222322523212222231c292a252526242526202433242525261a00004825333132322226212525252629000025332900002a313331322548263900002629000000001900002a313233290000260000000e1c103900000f2a2900003a263d01133a282e290000000000000e2925222321232900000000000e39143f124825262426111111111111112122222225252624482222222321222225254825",
[2]="252525482525252533290000002a282432322525252532332900000000002a242223313232332900000000000000003125252222232900000000001900002c2a25482525263919000000002d39123c3a2525253233382e390000002a3422222232323328290f3d2a2f0000002a242525002a292a390021231111111111313232110019000f0024252222223621222222231c2e39111124323232332125254825261a002a3435332900002a313232322533290000002a1a000000002a1a0000312900000000002d390000003a2900002a3f00000000002a2e2f00000f003d013a233912003e000000111100003a21222248222222222339002123000021254825",
[3]="2525252525323329002a2425252525252548253233282900000e3125482525252525261a0f2d2f0000002a2425323232252533281c2839111111112433212222252628282e282834353535332125252525262e29112a1a0e2810282e313232253233111127002a2f2d2e29002a28393122222222261111000f003d3e002a2e382548252525222311111121230000002a2525252525252634353532261c2f0011323225253232332828282e372e1c2f2122233133281a0e2e290f00000e2e1c24252523282e282f000000000000002a31254833281c283901190000000000002d2526282828282122233919001111002a25262838282125252610281c2123393a",
[7]="2525323232333132322525252548252629002a312525252525252525262425252526400000000f003b243232323232260000002a313232322525482533242525252639003d0000003b37290000002a37000000002d2f002a313225262125252525252235362b0000002a39000000002d39003f3a29000e1c2828313324252525252526282900000000002a39003d3a282122231a0000000f2d2e28212525322525482629000011110000002a2122222225252629000011112a1c2824252620242525261111112123111111112425252525252611111121232b2a2831323222252525333435353232222222232425254825252621222225262b002a29092a3132323329090f00092a313232332425252532323331322548262b3e000000002a28282900000000003a2e1a0f2a31323233290000092a3132323535362b0000002d2a390000002c3a382f0f00000f00092a1c2f00000000000f2d1a00000000002a000f0000003c2d2900000000000000000f0000000000000e102900000000000000013f3a212223393e0000000000000000000000000000002a39003d003e00002222222331252522222339000000003d00003a20000000003f2d34222236393d252525252324254825261a003a343536390e281a00003a2122222331332122222525482526242525252628392a281a0e282f2d28393a28242548252222252525",
[9]="253232252600000000003b242525482533282831260000000000112425252525102828283700000000002125253225252e281a2d1a0000000000242526202425192a1a0f2d2f000000002425252225252e390f000f00000000003125482525251c2900000000000000001b24252525251a192c000000000800003a3132323232281a3c003d0000000e1c282122222222222222353600003a1c382831252525252525262b0000000f2d28292a2425482525252639000000082a2e2f0e31322525323233283900000000003f00080124252222222223393d003e3a2122222225252525254825222222222324252525252525252525252525252526242548252525",
[8]="25252525252532323233242629002a103232322525332123202125260019002a2222232426212525222525261c2900192525262426313232323232331a0e1c2925252631332d38281a3a29002a1c2e1c254825231c2828292d290000000f002a2525252628282e2f0f00000000000011323232332e290000000000000000002122222223000000000000000000003a24252525260000000000000000002a2824252532333900000000000019133a292432333a1c2900000000003b212222233125232e290000000000003b244825252225261c390100000000003b24252548252526212223111111111111313225252525262425252222232122222223242525",
[5]="2525262b0000002d24252624252525252525262b0000002a24252631322525252525262b0000000e24252522232425252548332b0000003a2425252533313232252629000000002d313232332734352232262f000000002a29000f3b2422233120371111110019000000003b2425252222222222231c29000000003b313232252525252526282f000000003a2122232425252548262e3900003a2f2d2425263125252525262b0f000e2e1c282425252232322525262b000000002d2a2448252522232425262b00000e1c2e1c2425252525263132332b0000000f3a292425254825252222232b0100163a2e392448252525252525252222222222222324252525",
[13]="252532252610282e2425252624252525252620242628290024252526242525252525222526290000313232332448252525323232263900000f2a28283125252533282828372e2f00193a282828242525281a2d28290000002a28281028243232282e290f0000003a1c282828283721222900000000000e283828282e28212525000000000000002a1a0f2d1c2824252500003f00011900000f0e2e28282425253e3a2122222339000000000f2d2448252222252525331a002c0000002a31252525252525262123393c000000002a242525254825262425222223393d533a31322525252526242525252522222222222225252525262425252548252525252525",
[14]="254825263132323232252525323232322526242525252526002a3132322525252525323328282e28283132332e10282831332425252525262f002d2828312548323329002a2e2f0f2d212340192d28282821252548252526000e1a0f2d2e2425290000000019013a212526392d28281a2d2425252525252600000f000f3a24251100003f3a212223312525222236282e283132323232323311111119002d3132232b0e343532252523242525262b0f002a1c2900092a2122222236281c282122262b001b1b1b314826242548262b0000000f0000193a31252533281028283125262b0000000000242624252526110008000000002a28282426282e28282e2824262b0000000000313331252525232b0000000019002d28242629002a281c28242611111100003a29092a313232332b0000190e281c282e31261111112d2e282425222223003a2e2f00001b1b1b1b0000002d1c2e282e2f1b3135353629000f31252525261c3829000000000000000000000f2a1c290000001b1b1b1b0000002d323232332a290000000000111111110000000e1a11000000000000000000002a002d39000000000000003a21222223393e3d002a272f000011111111000000111c28281c3900000008002d242525252222232f113039003a2122222339123a21283828281a000000003a28242525482525261c2126381c282425482522222225",
[18]="3300002a31323232323232322525252525262425252525332900002a31322548000000001b1b1b1b1b1b1b1b31323248252624252525262900000000002a31324000003a1c2f11111100000000003b313233242532323311111100000000002a3d3a1c282e1c2122232f00000000001b1b1b313321222222222300000000191122222329002a2425260000000000000000002d2125482525252611113a1c28212525261111112448261111111111111100002a2425252532323235362e281024254825222223242525353535353535362f0000242525331b1b1b1b1b000f2a3125253232252624253329000f000f000f0000002425262900000000000000000032332828313324262839190000000000001111313226393a390011111111111110282e29002a312628281a003d003e3a1c2136202e302838281c2122222222222829002c00003b3028282e34222236292a37290f00372e292a282425252525252339013c00003b37290f003b24262b00000f0000000f00000e28243225254825252222230000000f0000003b24262b000000000000000000002a371b3125252525252526000000000000003b24262b00000000110000000000000f003b242525254825332f000b000000003b24262b000000112739000b00000000003b2425252525261a000000000000003b24262b00003a21262a390000000000003b242525",
[19]="482532323329002a24252525252525252526102900000011312525252532252525332900001111212331252526202425331a00000021222525232425252225252e281c2f112425483233312525252525002a281c2125323328282831323225250b002d2824263828282e1a00092a3132003a2e2e2426282e290e29000000002a000f190b2433282f001100000000001100002d1c3028290000272b000000112100002a28301a000011302b08000021250000002a3729001121332b00000024480000000009000021262b0000000e31250000000000000024262b013e00002a240008000000003a24332122231111112439000000003a2e302125252522222225",
[10]="25252525252526242525252525482526242525252525252525262b00003a282425482525323233313232322525252526242525252525252525262b00002a2e242525323328281c2900002a3132252526313225254825252525332b0000000e3125262b2a282e1a113a3900002a3132332e10312525252525262900000000002a25262b000f002a27292a3900001b1b1b002a283132323232330000000011111125262b0000111130113a29000000000000000f2a21222222230000001121222225332b0000343525231a0000000000000000000031252532330000002125254833290000002a2824262a390011110000000000002d24262900193a1c243225251a00000800002a2426002a1c212300000e1c390e2e242600002d282e302e313228390000000000242611002a242639003a381a0e1c31330e1c1a0f0037002a28292a2f00000000312523000024262a1c2828281c1a1b1b2d2e2900000f00002a000000000000002a242611112426002d290f2d282e393a2900000000000000000000000008000000242523212526112d393a1a0f0e290f0000000000000000003f0119000000003a242526242548232e10292a2f000000000800000019000000222223390000002d24252624252526002a2f000000000000000000002d2f00002548262839003a382425262425252600000000000000080000003a1c1a000000",
[27]="00003132323232323232323232323232170084006800846800008500688500680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000008000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000835353535353535353535353535353535000000000000000000000000000000001111111111111111111111111111111122222222222222222222222222222222"
}

-- hi ily


cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0.25

function move_camera(obj)
  cam_spdx,cam_spdy=cam_gain*(4+obj.x+0*obj.spd.x-cam_x),cam_gain*(4+obj.y+0*obj.spd.y-cam_y)

  cam_x+=cam_spdx
  cam_y+=cam_spdy
  
  if cam_x<64 or cam_x>lvl_pw-64 then
    cam_spdx,cam_x=0,max(64,min(lvl_pw-64,cam_x))
  end
  if cam_y<64 or cam_y>lvl_ph-64 then
    cam_spdy,cam_y=0,max(64,min(lvl_ph-64,cam_y))
  end
end


__gfx__
000000000070007000700070007000700070007007007000000000000700000700600600005d05000d00ddd00000000000000000000000000000000111111111
0800008007ccccc707ccccc707ccccc707ccccc77cccc7000007007007ccccc7060660600565d500dddd65dd0000000000000000000000000000011111111110
00800800c7ccccc7c7ccccc7c7c777c7c7ccccc77cccc7c00c7cccc7cc71717c6066560600575600d5d55d6d0000000000000000000000000000111101111100
00088000cc77777ccc77777ccc71717ccc77777cc7777cc0cc7cccc7cc77777c0656666000767000d65555d00000000000000000000000000000111100011100
00088000cc71717ccc71717c0c777770cc71717cc71717c0ccc7777ccc77777c06666560000760000d55556d0077770000777700007777000000111100001000
008008000c7777700c77777000d777000c777770077777c0cc77777c0cddddc06065660600077000d565d65d0777777007777770077777700000011100000000
0800008000d7770000d777000600006006d7770000dddd700c71717000dddd000606606000070000dd6dd5dd6676676676676676676676670000001100000000
000000000060060000600060000000000000060000007000066ddd600060060000600600000700000dd00dd00655556006555560065555600000000100000000
111111110000000000000000005555000055550000555500005555005050000000000505000000001111111176717d6110000001000000000000000050000000
11111011000000000000000005555550055555500555555005555550555000000000055500000000111111101660766111000011005600000650060006000006
11110001007000000000000005dd5d5005dd5d5005dd5d5005dd5d50550500300300555000000000111110000760676011000011006660600066000000000000
11100011007000700499994005555550055555500555555005555550550500333305055500000000111100000700067011100111066606600560000000000000
10110011076000700050050005d5dd5005d5dd5005d5dd5005d5dd50505550500550550500001000111110000700070011111111066666600000600000000000
100101110676067000055000055555500555555005555550055555500505558ee850505000111110111110000000070011111111006660500000006000000000
11011111166706610050050005666650056666500566665005666650005055555555050001111111111111000000000011111111060666000006065006000050
1111111116d717670005500066666666666666666666666666666666000550500505500011111111111111110000000011111111000000006000000000000000
1dddddd11dddddddddddddddddddddd1dd655555555555555555556d1dddddd11111111111111111111111111100000000070000111111111111111110000000
dddd65ddddd6dd66d665dd6565dd65dddd55555555555555555556dddd56d6dd1111111111111111011111116667000000077000011111111111111111100000
d5d55d6ddd656dd5555dd655555dd66dd6d555555555555555555dddd655556d111111111111111000111111d676770000767700000111111111111111110000
d65555ddd6555555555555555555555dddd555555555555555555d6dd55556dd1111111111110000001111117760000007767700000011111111111111111000
dd55556dd6d555555555555555555d6dd6555555555555555555555dd5d55ddd11111111111000000001111110000000076b6770000111111111011111110000
d565d65dddd555555555555555555dddd6d55555555555555555556dd6d55d5d11111111110000000001111176600000063bb677001111111100001111100000
dd6dd5dddd65555555555555555556ddddd5555555555555555555ddddd5556d111111111100000000000111667770007bb3b36b001111111100000111000000
1dddddd1d6555555555555555555555ddd655555555555555555556ddd55555d11111111100000000000000171000000b0bb3bb0011111111000000100000000
d555555dd6555555555555555555556d1dddddddddddddddddddddd1d665556d1111111100000000000000000000001703b3bb0b000000000000000000000000
d555556ddd65555555555555555555dddd665ddddd566dd565d65ddddd555d5d10011111110000000000000100077766b03b33b0000000000000800000000000
d6555d5dddd555555555555555555dddd6d5d5566dd5d656555dd56ddd655ddd1101001111100000000000110000066703b33b0b000000000002820006000000
d5555dddd6d555555555555555555d6ddd6555555555555555555d5dddd555dd111100011110000000001111000000010333b330000000000088e88005000000
d6d555ddd65555555555555555555d5ddd55555555555555555556ddd6d5556d1111110111110000000011110000067733333333000006000002820000600606
ddd556dddd6dd565556ddd55555d556dd655dd556d656dd66dd555ddd555555d1100111111111000001111110077676d03033030006000600006860000600060
d565555ddd56ddd66ddd656d65d665dddd666dd656ddd5d556ddd6dddd6556dd1110111111111110011111110000766600044000060006500000600000560060
d655556d1dddddddddddddddddddddd11dddddddddddddddddddddd11dddddd11111111111111111111111110000001100444000056065000000500000550550
00000000000000000000000000000000000000000777000000000000000000005555555500000000000000000000000000000000000000000000000000000000
00000005500000000007700000000000000000000066770000000000000000005555d55500000000000000000000000000000000000000000000000000000000
00000005000000000000776000000000076600000067760000909000000000005555dd5500000000000000000000000000000000000000000000000000000000
00000555555000000000076700000070077660000007660000080800000000005555555506666066660006666000666600006666000000666600066000000660
000555000055500000000767000007707677600000066000008898000000000055d5555500661106611066666600066110000661100006666660066100000661
00560000000065000000076700777700766000000000000009899890000000005dd55d5500661006610666116660066100000661000066611666066600006661
000600000000600000000007006666007000000000000000880888980007000055555dd500555555510551100551055100000551000055110055105510005511
00600003333006000000000007777000000000000000000088880888007070005555555500555555510551000551055100000551000055100055105515505510
00600033133306000033333300000000000000000000000000000000077000000000000000551115510555005551055100500551005055500555105555555510
00600033c31306000033131300000000000000000000000000000000777700700000000000551005510055555511055555510555555105555551100555555110
0600033b33c30060033333330000000000000000000000000000000d771770070000000005555055550005555110555555515555555100555511000551155100
060003b330000060033b3300000005000000000000500000000000dd777777700000000000111101111000111100011111110111111100011110000011001100
060003b33000006003b3300000000000060000000000060000000dd1d77717000000000000000000000000000000000000000000000000000000000000000000
0600033b3000006003b3300000700000000000600000000000ddd11d1d7776600000000000000000000000000000000000000000000000000000000000000000
0066003b33006600033b3000000660700006600000066000dd111dd1ddd0566600000000000000ccc0000000000cc0000000000000000000cc00000000000000
0000666666660000003b33000067760000677600006776000dddd11d000055560000000000000cc11c000ccc000cc10000ccc0000cccc00ccccc000ccc000000
00000000000000000005505005055000000999000000003333000000000000000000900000000cc10110cc1cc00cc1000cc1cc00ccc11100cc1110cc1cc00000
00000000000000000050555555550500000090000000333b3b333000000000000009900000000ff10f00fff0110ff1000fff111001fff000ff1000fff0110000
00000000000333300505059ee95550500000000000b33331111330000000000000009900000000fff0100fff0000fff000fff000ffff11000fff000fff000000
02820000003333335055055005055505000000000033311111113330000000000009900000000001110000111000011100011100011110000011100011100000
83b3200000332323555050333300505500000000033b3166166113b3000000000009490000000000000000000000000000000000000000000000000000000000
03b33000033333330555003003005055000000000b33111111111333000000000094449000000000000000000000000000000000000070000000000000000000
033b3800833b338055500000000005550000000003b3116616611b30099999900009490000000000700007000000000007000000000760000000000000000000
803b3300082822005050000000000505000000000033311111111300999449990000900000000007700006700007000006000000706657000000700000000000
00066000600006000000000000000000000990000009900000099000000990000009900000000007670076660067700006700007665515500000670000000000
00066000000060000000000000000000009449000094490000999900009999000000990000000056556061550551660065606065515150550006566000000000
00066000060606000000a22000000000009449000094490009944990099449900009900000000555155555055515550555155555150505055555155500000000
0006600066660000000a202000000000000990000099990009944990099449900000990000000551515151505150555551505151501010505551505550000000
0006600000660600000a22a000000000000000000009900000999900099999900009490000005515150505050505051515050505010000050515050555000000
00066000006060000006260000000000000000000000000000099000009999000094449000555150501010101010505050101010100000005050105051500000
00066000060006000000600000099900000000000000000000000000000000000009990005051501010000000000010101000000000000000101000505050000
00066000600000000000500000994990000000000000000000000000000000000000900000101010000000000000000000000000000000000000000010101000
9200a21323535363920000000000a27311000000e0432222620400e082e282120000000000000080000000000000a21352522352525252525252620000a21352
920000000000000000e0730000000000522222226292a20193425222639391a35252525262000000004252526242525200001323232323331323232323232352
000000b1b1b1b1b100000000000000a27211111100a24252629300f3d2c182421111000000000000000000000091a3a15262024252525252845262930000a242
00000000111111000000b1000000000023232323620000a2824252628282828252528452330000000042525262428452a0a0000000000000a2e2829200000013
93000000000000000000000091a39300422222321111425252225363e28282422232c193000000000000000000a283825252225252232323525262e293910042
93000000435332009100000000000000920000a203000000a2132333a282838252525262b20000000042232333425252a0a000000000c2000000820000000000
829300000000001111111100d2e282c142525252223242525233000000f0a2135262d292000000000000000080e0e20123232323339200a213526211a2a10042
6300000000b30393d293110000800000001104000311000000122232c192f0a223235262b20000000073b1b1b1132323a0a000000000c300d3a382c193000000
83a1000000a39312222232e09200a283135284525262425233920000000000a2526292000000000000000000000000a222222232b2000000a2132363f2d2c142
9200000000b3038282e2729300000000007293a31363f20000428462a100000092a213620000000000000000000000002172b20000b31232435353532232a0a0
82920080a382a1425252620000e0c1e2924252525262426290000000000000005262f20000000000000000000000000052525262b200000000b1b1b100a28213
0000800000b303e292110392000000000013535332920000e0425262e29300110000a2739300000000000000000000002262b20000b342629200040042620000
f0000000a20182425252621111111111114252525262133300000000000000112333930000000000000000000000000052525262b2000000000000000000f0a2
0000000000b30311111262110000000000b1b1b103b20000b313233300a2c112000000a2a100000000000000000000115262b20000b342629300000042620000
00000000e0e2a1425252522263435322225252525262829200000000000011128382a1800000000000000091a3930000525284621100000000111111000000a3
939191001111422232425232110011110000000003b2000000b1b1b10000a21300000000f000000000000000000000125262b20000b31333e24353532333a0a0
110000000000a213232323338282821323235252526282930000000000e0125282e2920000000000000000a282a100115252525232910000001222329321a392
a2e2a1b31222845262425252321112225363000073b2000000000000000000a2000000000000000000008000000091425262b2000000a292a00000a3e2930000
32000000000000000090a292f0d2828201e21323236282e2f200000000a3428492000000000080000000e0c1e292b3125252525262920091a342845222223211
11a392b3425252526242525252225252a393009100000000000011000000000011110000002191000000000000e0e2425262b20000000000a000a39291a29300
62c1f2000000910000000000e08282e282f200a2820392000000000000d242520000000000000000000000a29311114223232323332100d28213232323235222
32d2f2b31352522333135252845252528282c1829300000091117211111111112232111111029200000000000000e0132333b20000000000a0a392a382931222
3392000091e0a100000000e0c182e293f0000000a27300000000000000a2135211000000000000a3c1f280a382123213222222222232c18292b1b1b1b1b11352
33920000b3423312223213232352525282e2828312320000a2125222222222225252222232b200000000000000e0c1921000a000000000a31222223243225252
b10000e0a191d29300000000a2a100d2f200000000f00000000000000000d21332119100000000a2a1a3c1e29242522252525252526282a1000000000000a213
92000000b31222525252222232132323a1b0a2824233000000428452522323525252525233b20000000000000011a2c12232b2000000a3824252525263132352
00000000d28282a180000000e082c1829310000000000000110000000000a28252329200000000e08283e2829342845252525252523392f000111111000000a2
00a3c193b34252522352525252222222920000d203009100a342522333828213528452628293a3c1f2000000e072c1e28462b2000000d2e21323233312223242
00000021a28283829300000000d2828212223200000000a372c193000000e082846293d300f310a38292a383a1425252525284526292000000122232f2000000
00a28212532352620242525252525252f20000a27300d2c1824233828282838252525262838292a293001100000392005262b2000000a2c11222324352526213
0000a372c1828282a1000000a3828282428462930000a3920383a100000000a252621222222222329200d292a242525252525252621111111113233300000011
0000a273b1b14252225252232323525200000000a3c182e282738282828282825252526282a100f3d2c17211110311115262b200000000d24252523242525222
3213525262b20000000000000000b34252525252525262425252620000b000b3425252525252528452526242525252522323235252222222639200f000009112
000000b10000132323233392000013230000e0c1828282c192f0a2e282a1f0a252522333a1d2c143222252222252222200000000000000000000000000000000
5232132333b20000000000000000b313525252845252624252526200000000b3425284525252525252526242528452522222321352528462a100000091a3e242
000000000000b1b1b1a2e2c19300a382110000a282828282f20000e0829200005233e282e28292b3425223525252525200000000000000000000000000000000
52522263b20000a3930000000000b372135252525252621352846200000000b342525252525252525252331352525252525252321323236282930011d2920042
1111111100000000000000d2a100d282320000a3018282a1d391e0c1e2c1f21162a100f000f000b3426202425284525200000000000000000000000000000000
232333b20000a392d29300000000b3423213232323233302425262b0000000b3425252528452528452331232132323235284523382e282730182c17292000042
22222232000011111100a38201c182e262e3a38212222222223293f091a293126292000011111111135222525252525200000000000000000000000000000000
b1b1b1000000a293d29200000000b342523243222222321252526200000000b313232323232323236212525222222222525262829200f0e082e2820311111142
528452621111122232b2f0a292d292005222321252525252525222226300a2426200000043535353634252525223232300000000000000000000000000000000
000000000000e0e282c193000000b313233372135252624252526200000000b3122222222222223273425252528452525252339200000000f000a21322222252
23232323631252526211110000f000005252624252525252235252620000004233000000a28293b312525223339200a200000000000000000000000000000000
0000000000009100a282a1910000b342525252321323331323233300000000b3425252845252525232135284525252525262b2000000000000c200a242525252
00c282e28242525252223200000000005252621352525262024252621100001392000000e0e2a1b3132333920000000000000000000000000000000000000000
0000000000a3e293a392a2920000b34252525262b1b1b1b1b1b1b100000000b3135252525252525252321323232323232333b2000000000000c3d3a342525252
91c382c182425284525262c1f2000000528452324252525222525252320000a20000000000e082c11232a100000000a300000000000000000000000000000000
00000000e0a11222329300000000b34284525262b2000000000000000000e312324252525284525284523292f00004002232b20000919100b312222252845252
22223282e213235252233392000000a352525262135252525252522333000000008000000000a2e2136282939110d31200000000000000000000000000000000
0000000000a213525232b2000000b34252525262b2000000001111110000432333132323232323232323330000e300005262110091d29200b313525252525252
232333920000b34262a39200000000d25252525232132323525262a3920000000000000000000000a20382e24322225200000000000000000000000000000000
000000000000b3425262b2000000b34252528462b2000000a312223293a392a282e282e293a3920000000000a3122222525232c182a1b00000b3425223235252
920000000000b313629200b00000a301525223233382828213526292b0000000000000000000000000039200b342525200000000000000000000000000000000
000000000000b3422333b2000000b31323232333b2000000a2135262d2920000a2c192a3e2a1000000000000a21323235252628292f0000000b3423392a21352
00000000000000b3730000000000a2e25233e2828282a1d282136200000000000000e0c19391000000730000b313232300000000000000000000000000000000
9310d3000000b37392000000000000b1b1b1b1b10000000000a213339200000000f000a2c19200000000000000a283c1525233920000000000b373829300a242
0000000000000000f0000000000000006292e0e2a1a2828282e2730000000000000091f0d2a1000000f00000b312222200000000000000000000000000000000
222232000000b0a0000000008000000080000080000000800000a00000000000000091a3829300000000000000e092a22333a1f3100000000000d292f0000042
00000000e300000000000000100000003393f310f091d2a1f000f0000000000000a3a1e0a1d2f20000000000b342525200000000000000000000000000000000
23526293000000000000000080000000800000800000008000000000000000000000d282e282f200000000000000000022222222223293000000f00000000013
0000e043223293f3000000a3729300002222223293a292f0000000000000a3c100a282c182a1008000000000b313525200000000000000000000000000000000
324262a29300000000000000800000008000008000000080000000000000000000a392a2c1e293000000000000000000525252525252329300000000000000a2
000000a2425222320000a312523293a352525252329300000000000080a3828200e0828201829300000000910000425200000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000
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
00000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006666066660006666000666600006666000000666600066000000660000000000000000000000000000000000000
00000000000000000000000000000000000000661106611066666600066110000661100006666660066100000661000000000000000000000000000000000000
00000000000000000000000000000000000000661006610666116660066100000661000066611666066600006661000000000000000000000000000000000000
00000000000000000000000000000000000000555555510551100551055100000551000055110055105510005511000000000000000000000000000000000000
00000000000000000000000000000000000000555555510551000551055100000551000055100055105515505510000000000000000000000000000000000000
00000000000000000000000000000000000000551115510555005551055100500551005055500555105555555510000000000000000000000000000000000000
00000000000000000000000000000000000000551005510055555511055555510555555105555551100555555110000000000000000000000000000000000000
00000000000000000000000000000000000005555055550005555110555555515555555100555511000551155100000000000000000000000000000000000000
00000000000000000000000000000000000000111101111000111100011111110111111100011110000011001100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000077000000000000ccc0000000000cc0000000000000000007cc00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000cc11c000ccc000cc10000ccc0000cccc00ccccc000ccc000000000000000000000000000000000000000000
00000000000000000000000000000000000000000cc10110cc1cc00cc1000cc1cc00ccc11100cc1110cc1cc00000000000000000000000000000000000000000
00000000000000000000000000000000000000000ss10s00sss0110ss1000sss111001sss000ss1000sss0110000000000000000000000000000000000000000
000000000000000000000000000000000000000000sss0100sss0000sss000sss000ssss11000sss000sss000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001110000111000011100011100011110000011100011100000700000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700007000000000007000000000760000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007700006700007000006000000706657000000700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007670076660067700006700007665515500000670000000000000000000000000000000000000000000000
60000000000000000000000000000000000000000056556061550551660065606065515150550006566000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000555155555055515550555155555150505055555155500000000000000000000000000000000000000000000
00000000000000000000000000000000000000000551515151505150555551505151501010505551505550000000000000000000000000000000000000000000
00000000000000000000000000000000000000005515150505050505051515050505010000050515050555000000000000000000000000000000000000000000
00000000000000000000000000000000000000555150501010101010505050101010100000005050105051500000000000000000000000000000000000000000
00000000000000000000000000000000000005051501010000000000010101000000000000000101000505050000000000000000000000000000000000000000
00000000000000000000000000000000000000101010000000000000000000000000000000000006000010101000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055500050505000500550005050500000000000000000000000007000000000000000000000000000
00000000000000000000000000000000000000000000000001510501515105015011050151510000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005010510050105105100051051510000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000050100510505005105100051055510000000000000000000000000000000000000000000000007000
00000000000000000000000000000000000000000000000055505010515150100550501005110000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001110100010101000011010000100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000077077707770077077707700777070000000077077707770777000007770707000000000000000000000000000000000
00000000000000000000000000000000707171710711701107117170717171000000701171717771711100007171717107000000000000000000000000000000
00000000000000000000000000000000717177010710710007107171777171000000710077717171770000007771777100100000000000000000000000000000
00000000000000000000000000000000717171700710717007107171717171000000717071717171711000007170017107000000000000000000000000000000
00000000000000000000000000000000770171717770777177707171717177700000777171717171777000007771777100100007000000000000000000000000
00000000000000000000000000000000011001010111011101110101010101110000011101010101011100000111011100000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000666066606600660060600000666060600660666006600660660000000000000000000000000000000000000000
00000000000000000000000000000000000000666161616160616061610000061161616061616160116061616000000600000000000000000000000000000000
00000000000000000000000000000000000000616166616161616166610000061066616161660166606161616100000000000000000000000000000000000000
00000000000000000000000000000000000000616161616161616101610000061061616161616001616161616100000000000000000000000000000000000000
00000000000000000000000000000000000000616161616661666166610000061061616601616166016601616100000000000000000000000000000000000000
00000000000000000000000000000000000000010101010111011101110000001001010110010101100110010100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000660006606660600000006660666066606660606000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000616060616111610000006161611161616161616100000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000616161616600610000006601660066016601666100000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000616161616110610000006160611061606160016100000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000616166016660666000006661666061616161666100000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000010101100111011100000111011101010101011100000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000ccc00cc0cc000000ccc0c0c0000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000ccc1c0c1c1c00000c1c1c1c10c0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000c1c1c1c1c1c10000cc01ccc1001000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000c1c1c1c1c1c10000c1c001c10c0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000c1c1cc01ccc10000ccc1ccc1001000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000010101100111000001110111000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000dd0ddd0ddd0ddd0d0d0d0d0ddd0dd00000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000d011d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000ddd0ddd1ddd1dd01dd01ddd1ddd1d1d1000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001d1d111d1d1d1d0d1d001d101d1d1d1000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000dd01d100d1d1d1d1d1d1ddd100d1ddd1000000000000000000000000006000000000000000000000
00000000000000000000000000000000000000000000000001100100010101010101011100010111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000d0000dd0ddd0dd0000000dd0dd00ddd0d0d00000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000d100d0d1d1d1d1d00000d011d1d0d111d1d10000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000d100d1d1dd01d1d10000ddd0d1d1dd00dd010000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000d100d1d1d1d0d1d1000001d1d1d1d110d1d00000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000ddd0dd01d1d1ddd10000dd01d1d1ddd0d1d10000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000111011001010111000001100101011101010000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000

__gff__
0000000000000000000000000000040404020000000000000004040204000000030303030303030304040402040404040303030303010303040404020402000200000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000002525252525252629000000002a313248252525332425262425252624252525252525262900000000000000003a3125252525252525252525252525252525252525252525333900000000000000000000293a31323232323232323232323232250000002a313232323232323329000000
00000000000000000000000000000000252525252532332f0000003a1c293a31252526212525262425482631323225254825264000000000000000002a1a2425323232323232323232323232323232322548252628282f0000000000000000003a290009002a390f3a2900002a1c2931000000001b1b1b1b1b1b1b1b00000800
0000000000000000000000000000000025254825262123111100002a28382900254826242525263125252522222324252525260000003e0000000000002a24480000000000000000000000000000000025252533282839000000000000002c002900000000002a1c290000003a2e1c2e00000000000000000000000000000000
000000000000000000000000000000003232323233313321233d003a282e393a3232333132323236313232323233313232323235353536000000000000003132000000000000000000000000000000002532332810281a00000000003d003c3a0000000000000e2e39003f3a293a290040000000001111111100000000000800
000000000000000000000000000000001c29002a393b21252621232e1c2f2a102222232d38290f00002a1c21222222223a282900000000000000000000003a290000000000000000000000000000000033282828282e2839193e003a212222221212120012121212212222353536000000003a393e212222232b000000000000
000000000000000000000000000000002900193a293b24252631263a2900002a2525262a1039000000002a2425252525281a00000000000000000011113a290000000000000000000000003e3e3e3e3e28282e290f002a2e34222223242525252222232b212223343232332e1c2900002222222223242525262b000b00000800
00000000000000000000000000000000013a2e38393b244825233729000000002525261c290f0000ff00002432323232101a3a1c3900000000003b212329000e0000000000000000ff000021222222222e290000000000002a242526313225252548262b242525233a282e1c290000003232323233313232332b001900000000
0000000000000000000000000000000022231c290f3b242525252339000000002525331a0000000000003a37898a8b8c292a2e282900000000003b242639002c00000000000000000000002425252525110000000000000000242525222331322525262b24482526282e1c29000008001b1b1b1b1b1b1b1b1b003a2e39000800
0000000000000000000000000000000048262a39003b31323232332d393a39112533272e1c39190e39002a1a999a9b9c0000002a393a393d00003b24332a393c00000000000000000000002425252525231111110000000000242525482522222525262b242525262e1c290000000000000000000000000000002a1c2e2f0000
000000000000000000000000000000002526002a1c1c290f2a1c1c28281a2a213221263a28292d1c1a3a1c29a9aaabac000000002d38212339003b371b3a2821000000002c00000000002c242525252525222223000000000e313225252525252525332b242525261c29000000000000000000000011111111003a2900111111
00000000000000000000000000000000252611002d1a19000e2e10292d283924222526292a1c292d2e292a27b9babbbc0000000e292a24262a39191b3a283824000000003c3f3e013e3f3c24252525252525252639000000000f2a3132323232252629003132252629000000000000000000003a1c212222232f2a3900212222
000000000000000000000000000000002525232b0f2a290000000f000f0f2a2432323365662a1c1a3e013e242222222239111111111124263a2e281c2e1028242222222222222222222222252525252525252526290000000000002a2821222232330000002a3133272b0000000000000000002a1a2425252600002a1a242525
000000000000000000000000000000004825262b000000000000001911111124222222232123342222222225252525252a2123342223242629002a29000f2a242525252525252525252525252525252525482526113a2f00000000002a2425252223000000002a21262b00000000000800000b002d31254826390b3a28313225
000000000000000000000000000000002525262b000000000000002a2122222525252526242523312525482525252525012425232426313311111111111111313232323232323232323232323232323225252525231a000000000000112425254826000000400024332b00000000003a000000002a1024252621222222222331
000000000000000000000000000000002548332b00000000001111112425252525252526312525232425252525254825222525332426212222222321222222220000000b00000000000b00000000000b32323225262839000800003a3432323225263900000000301a00000000003a2e393f01003d2a31323324254825252522
000000000000000000000000000000002526281c2f0000003b2122222548252525252525232425262425252525252525252526212526242525252624252525250b00000000000b00000000000b0000002a282831261a0f000000000f2a21222225263839212223372a390000003a1a0822222222222222232125252525252525
0000000000000000000000000000000000000000000000000000000000000000263a28313232323232333132323232322900002a39002a39002425261a00003a282e28282425252525252525252525250e2838283728390000000000002425252526103824482523002d393a1c292a392526093b24262b0000000000003b3125
00000000000000000000000000000000000000000000000000000000000000002628290009002a393a29090909090909003f3a1c1a19002d1c2425262a393a2929002a10243232252548252525252533002a2e2828282900000000111124252532332a10313232331c292a1a2d2f002a4826013b24262b000000000000003b31
000000000000000000000000000000000000000000000000000000000000000026290000000e1c2e29000000000000002c21222222233a2e29312526002d29000000002a37292a3125252525323232211100002a290f000000000021222525253a29000f1b1b1b1b2a393a28383900002526393b24262b00000000000b000000
0000000000000000000000000000000000000000000000000000000000000000262f0000000e2e1c39000000000000003c31252525262720212324263a290000000000000f00002a2425323321222225230000000000000000111124252548252e39000000000000002a2e292a28393a25261a3b24262b0b0000000000000000
000000000000000000000000000000000000000000000000000000000000000026393e0000003a292a39000000000000223631323226242225263133290000000000000000000e1c242621222525252526000000110000003a212225252525251c2900000000111111000000000f2d2125261a3b24262b000000000000000000
00000000000000000000000000000000000000000000000000000000000000003321231111112123212300000000000026212222233324482525232b00000000001111190000002a3133242525482525260000002711003a28242525252525252a393d01003b2122232b000000002a2425261a3b24262b0000000b0000000000
0000000000000000000000000000000000000000000000000000000000000000222548222222323324262f000000000026313232323624252525262b00000000112123290000003a28212525252525253339001924231c2e282425253232323222222223393b243233111111111111312533291124262b000000000000000000
000000000000000000000000000000000000000000000000000000000000000025252525252621222526000000000000261b1b1b1b1b24252548262b00000011222526111100002d282425252532323228281c28243329002a31323321222222482525261a3b30212223212222222222332b003432332b000000000000000000
252526312525252525482526242525252548252533303a39242525252526242532323232323331322526390000000000332b0000003b31323232332b0000002125252522232b3a292a31323233292a3928382828302b00000e2122222525482500000000000000000000000000000000232b001b1b1b00000000000000001212
2525252331322525252532332425252525252526212628283132323232332425222222222320212331332a393a390000232b0000000a0f090f0a000000003a3125252525262b0f00001b1b1b1b00002a282e282e302b00003b2425323225252500000000000000000000000000000000262b00000000000000000000003b2122
25252525222324252533282e313232323232252624262a1a212222222223242525252525252331252223392810290000262b0000000a0000000a000000002a3825254825262b000000000000000000001a0e2900372b00003b3133292a31322500000000000000000000000000000000262b00000000000800000000003b2425
2525252525263125262b0f001b1b1b1b1b1b313331332f2a242525252526312525253232323236242526282e28393a39262b0000000a1900190a00000000002a252525252611000000111111000000212900000000000000001b1b00002a2e3100000000000000000000000000000000262b19111111001900190000003b3125
2525254825252324332b000000000000000000001b1b000e242548252525232425331b1b1b1b1b2425262f000f2a2921262b00003a212222233d3a390008000025252525252339123a21222339000e310000000000000000000000000000002a00000000000000000000000000000000262b2a212223392d392a393a393a2e31
25252525253233370000000019111111000000000000000e242532323225332433290000000000313233393a39003a24262b00002a3125482522232a390000003232252525262122222525261a00002a1111000000000000191111000000000000000000000000000000000000000000262b0024482628382e1c2e282e29002a
2525252526290000000000002a212223390000000000000e313329002a373425290800000000001b1b1b2a1a2d1c3824332b0112002a24252525263a290000003828313232333132323225332e2f000022362f001111003a282123000000000000000000000000000000000000000000332b3a3125262d281c281c281c390000
32323225263900001900000000313226290000000011111127290000192d283100000000000000000000002a292a1a242021222339002425254826283900000028291b1b1b1b1b1b1b1b3029000000002611111121361c282924261111000000000000000000000000000000000000002222222324262a292a292a292a290000
__sfx__
0102000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
0113000000000000000e0300000013040000000e0400000014050000000f0500000015060000001106000000170700000000000000000000000000000000000000000000002f0502f0302f010000000000000000
010800000016000160041500413000150041200411001000001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000001a7441a7611a7411a7311a7211a7111a7150000021744217612174121731217212171121715000001c7441c7611c7411c7311c7211c7111c715000001d7441d7611d7411d7311d7211d7111d71500000
011000001a7301a7301c7401c7451d7401d74521750217551a7341a7311c7401c7451d7401d745217502175515730157301a7401a7451c7401c7451d7501d75515734157311a7401a7451c7401c7451d7501d755
011000001a7301a7301c7401c7451d7401d74521750217551a7341a7311c7401c7451d7401d745217502175515730157301a7401a7451d7401d7451c7501c75515734157311a7401a7451d7401d7451c7501c755
001000000000005033000002463500000100330b0332f6250000002033000002d625000000c033070332b6250000005033000002462500000100330b033000002f625246250000005033000002d6202d6202d625
0010000000000050330000005033000002f625050332f625000000703300000070330000030625070333062500000000330000004033040332b625000000403300000000330000004033040332b6250000004033
0010000000000000330000004033040332b625000000403300000000330000004033040332d6202d6202d625000000003300033286252400028625020332362500000020332162521625000001d6250201302013
011000001a7541a7521a7521d7541c755000001875500000265552653526525265152655526535265252651528555285352852528515285552853528525285152955529535295252951529555295352952529515
001000002d5552d5352d5252d5152d5552d5352d5252d515285550000028525000002855500000285250000029555295352952529515295552953529525295152655500000265250000026555000002652500000
001000002155521535215252151521555215352152521515245550000024525000002455500000245250000026555265352652526515265552653526525265152955500000295250000029555000002952500000
011000002d555000002d535000002d525000002d51500000267342674026750267302875500000247650000022745000001c735000002175522750217551f750217550000021755000001c7501c7311c71500000
001000000e0100e01513020130250e0100e015090100901510010100151502015025100101001513020130250e0100e01513020130250e0100e01509010090151001010015150201502510010100151302013025
031000000e0430000000000000002d62500000150230000035615000000000000000110330000034625000000e043000000000000000150230000016033000001603300000000000000039615000003761500000
0110000009010090150e0100e015150201502511010110150c0100c01510010100151602016025130101301507010070150c0100c015130201302510010100150c0200c02507010070150c0200c0250701007015
01030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000e0100e0150e0100e0151502015025110101101510010100151001010015160201602513010130150c0100c0150c0100c01507020070250a0100a015110101101511010110150a0100a0150e0100e015
0310000010043000000e0330000039615000000c04300000396150000010043000000e0330000030625000000c0330000039615000000e0330000010033000000c033000000e0430000034625000003961500000
031000000e7230000000000000001574300000356250070010723007003a61500700000000070013743007000c7330070007723007003a615000000000000700117330070011723007000c723000003262500000
0310000010733000000000013733326150000000000000003a625000000e733000001373300000000000000030625000000000000000157330000010733000003262500000117330000000000000001673300000
011000000e0100e0151501015015110101101500000000000e7250e72411725117240e7250e724157251572410725107241372513724107251072416725167241172511724157251572411725117241872518724
011000001572515724187251872415725157241c7251c724107241072513724137251072410725167241672511725117241572515724117251172418725187240e7240e72511724117250e7240e7251572415725
0310000034625000000e73300000107330000000000000003a625000000e733000000000000000137330000030625000000000000000157330000010733000003262500000117330000000000000001673300000
0110000009725097240c7250c724097250972410725107240c7240c72510724107250c7240c72513724137250e7250e72411725117240e7250e72415725157241172411725157241572511724117251872418725
0110000009724097250c7240c725097240972510724107250000000000150101501511010110151001010015000000000013010130150e0100e0150a0100a015000000000010010100150c0100c0150a0100a015
0310000034625000000e73300000000000000013723000003a625000000e7330000013733000000000000000306250000015723000000000000000326250000035625000000e7330000016733000000000000000
031000000e723000001173300000000000000015743000003261500000000000000015743000000e7230000010723000000000000000356250000000000000001072300000356250000000000000003262500000
000700001a6501a600166401660014640116001165017600146503160014650316001565000000156500000015650000000000000000046000360003650036500365002650026500265002650026500265002650
000c00000c3300c3300c3300c3200c3200c3200c3100c3100c3100c31000000000000000000000000000000000000000000000000000000000000000000000000a3000a3000a3000a3000a3310a3300332103320
01030000176551760517605176501760024300176501b6001b6501c3001b65000300256603e6303f6303f6303f6303f6303f6303f6303f6303f6303f6303e6303e6403e6403e6303d6303d6303e6303d6303d630
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
01050000165501b510195101655000005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
01040000396703b6703e6503f6403f030360203601000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000011630186301d630266202d6203362038620396203f6203f62038620326200070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0105000011770147001177013700117701370011770137001177013700117700000017770000001c770000002b770000000000000000000000000000000000000000000000000000000000000000000000000000
00040000300600000025020000001e0100000000000000000000000000300700000025020000001e010000001e00000000320300000027040270001a060160000000000000000000000000000000000000000000
010200003b5303b5303b5350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003203329043200531806318043180231801318013000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000000000327750000032765000003275500000307350000039775000003976500000397550000037735000002b7752b7752b765000002b75500000297350000026735000002675500000267650000028775
00100000000002d745000002d7552d7552d755000002f765000003074500000307553075530755000003276500000347550000034765347653476500000357750000037755000003776537765377650000039775
0010000000000377550000037765377653776500000397750000039775000003977500000397703977039775000002f775307752d7652f7652b7552d755297452b745297352b7352872529725267152871524715
011000201a7401c7401d740217401a7401c7401d74021740157401a7401c7401d740157401a7401c7401d7401a7201c7201d720217201a7201c7201d72021720157201a7201c7201d720157201a7201c7201d720
011000202d7402c7402d0402c0402f040000002e040000002c0400000028040000002704025040240400000027040250402404023040270402504024040230402d0402d0402d0402d0402d040000000000000000
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
011000201a7201c7201d720217201a7201c7201d72021720157201a7201c7201d720157201a7201c7201d7201a7101c7101d710217101a7101c7101d71021710157101a7101c7101d710157101a7101c7101d710
011000001355000000165500000013550000001055000000135500000016550000001355000000115500000028052280322801000000280522803228010000002f0522f0522f0422f0222f015000000000000000
010300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
011000000c7330e7450c7330e7450c7330e7450c7330e745097230b735097230b735097230b735097230b73505723077350572307735057230773505723077350772309735077230973507723097350772309735
001000000472305735047230573504723057350472305735077230974507733097450773309745077330974505733077450573307745057330774505733077450b7330c7450b7330c7450b7330c7450b7330c745
01060000117701470011770137001177013700117701370011770147001177013700117701370011770137001177513705117751370013770000000b770000000777000000000000000000000000000000000000
011000001357513555135351351513575135551353513515145751455514535145151457514555145351451513575005051355500505135750050013555000001255012550125501255012550000000000000000
0110000013530135101351013510135301351013510135100b5300b5100b5100b5100b5300b5100b5100b51013530135101351013510135301351013510135101255012550125501255012550000000000000000
0110000023570000001a530000001f54000000205500000023570000001a530000001f54000000205500000023570000001a530000002054000000215500000023570000001a5500000019530000001752000000
010800001372113721137210c7210c7210c7211372113721137210c7210c7210c72113731137310c7310c73113731137310c7310c731137410c741137410c741137410c741137410c741137510c761137710c771
011000101175000000107300000011750000001073000000117500000010730117500000010730117501075000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 11141944
00 12151944
02 13161a44
00 4a564c44
01 1b1d1f44
02 1c1e1f44
02 4a564c44
00 20564c44
00 41424344
00 41424344
00 41424344
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
01 0d2e3844
00 0d2e3944
00 0e2f3844
02 0f303944
00 4d6e7944
00 41424344
00 0a141544
00 0a141544
01 0b161944
00 0c181a44
00 0b161944
00 0c181a44
00 101c1b44
00 111d1e44
00 111d1e44
00 121f2144
02 13202244
00 41424344
00 41424344
00 317f4344
01 343f7544
00 34323f44
00 34323f44
00 34353b44
00 34323b44
00 343d3f44
02 343d3f44

