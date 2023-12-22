pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- ultimate selfie
-- by wuffmakesgames+smellyfishtiks

-- @data-structures
function vector(x,y) return def_table("x,y",x,y) end
function rectangle(...) return def_table("x,y,w,h",...) end

-- @globals
objects,particles,got_fruit,dialogue_finished={},{},{},{}
freeze,screenflash,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,0,0
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25

_switches_pressed = 0
water_height,water_y,water_state_active = 8,0,false

-- [entry point]
function _init()
    car_offset,timer=46,0
    frames,start_game_flash,lvl_id,lvl_bg=0,0,0,2
    music(1)
    replace_mapdata(112,0,16,16,bg_data[2])
    def_table_ext(_ENV,"win_timer,max_djump,deaths,frames,seconds,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col,screenflash",unsplit"0,1,0,0,0,0,0,true,0,0,1,0")
end

function begin_game()
    def_table_ext(_ENV,"dialogue_timer,win_timer,max_djump,deaths,frames,seconds,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col,screenflash",unsplit"0,0,1,0,0,0,0,0,true,0,0,1,0")
    music(0,100)
    load_level(1,1)
    menuitem(1,"★ restart",function() _instant_death=true end)
end

-- [effects]
fx_death={}



-- @draw
function _draw()
    if (freeze>0) return
    if screenflash > 0 then
        screenflash-=1
        cls(7)
        return
    end
    -- reset all palette values
    dpal()

    -- start game flash
    if is_title() then _draw_title()
    else _draw_game() end

    if game_win then
        win_timer += 1

        -- sfx
        if (win_timer == 35) sfx"63"
        if (win_timer == mid(win_timer,60,90) and win_timer % 15 == 0) sfx"9"

        if (win_timer >= 40) draw_win(32,4)
    end
    
end

function draw_win(x,y)
    local w,h = 64,42
    rectfill(x+2,y+2,x+w+2,y+h+2,0)
    rectfill(x,y,x+w,y+h,0)
    rect(x,y,x+w,y+h,7)

    -- score
    if win_timer >= 60 then
        spr(48,x+12,y+6)
        ?"x "..fruit_count,x+24,y+9,7
    end
    if win_timer >= 75 then
        spr(25,x+12,y+18)
        draw_time(x+24,y+19)
    end
    if win_timer >= 90 then
        spr(49,x+12,y+30)
        ?"x "..deaths,x+24,y+32,7
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

function draw_object_outline(col,obj)
    local _pal = dpal
    dpal = t

    -- outline
    for i=0,15 do pal(i,col) end
    for xx = -1,1 do for yy = -1,1 do if xx&yy==0 then
        camera(draw_x+xx,draw_y+yy)
        draw_object(obj)
    end end end

    -- reset
    camera(draw_x,draw_y)
    dpal = _pal
    dpal()
end

function draw_object(obj)
    (obj.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj,ox,oy)
    ox,oy = ox or 0, oy or 0
    spr(obj.spr,obj.x+ox,obj.y+oy,1,1,obj.flip_x,obj.flip_y)
end

function draw_time(x,y)
    ?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds),x+1,y+1,7
end

function draw_ui()
    -- rectfill(24,58,104,70,0)
    -- local title=lvl_title or lvl_id.."00 m"
    -- ?title,64-#title*2,62,7
    rectfill(4,4,36,17,0)
    draw_time(4,4)
    ?"x"..deaths,11,12,7
    spr(26,5,12)
end

function two_digit_str(x)
    return x<10 and "0"..x or x
end

function dpal(c0,c1,p)
    if c0 then pal(c0,c1,p)
    else pal() end
    pal(13,-4,1)
    pal(14,-10,1)
end

function draw_water(x,y,w,h)
    w,h = min(w,128),min(h,128)
    pal({[0]=13,13,12,12, 13,13,12,7, 14,12,12,7, 7,12,12,7})
    palt(0,false)

    -- set the screen memory as the spritesheet
    -- and stretch screen->screen
    poke(0x5f54, 0x60) 
    sspr(x,y,w,h,x,y) 
    poke(0x5f54, 0x00)
    dpal() -- return to defaults
end

function draw_background()
    if lvl_bg == 1 then
        map_parallax(unsplit"112,8,0,0,8,8,0.2,0.2,1,1")
        map_parallax(unsplit"112,0,0,0,8,8,0.3,0.3,1,1")
    else
        map_parallax(unsplit"112,0,0,0,16,8,0,0,1")
        map_parallax(unsplit"112,8,0,64,16,2,0.1,0,1")
        map_parallax(unsplit"112,10,0,80,16,6,0.2,0,1")
    end
end

function map_parallax(celx,cely,x,y,celw,celh,spd_x,spd_y,tile_x,tile_y)
    local pw,ph = celw*8,celh*8
    local offx,offy = (draw_x*spd_x) % pw, (draw_y*spd_y) % ph
    local width = tile_x and 128\pw + 1 or 1
    local height = tile_y and 128\ph + 1 or 1

    camera_push(0,0)
    for i = 0,width*height-1 do
        local xx,yy = (i%width)*pw, (i\width)*ph
        map(celx,cely,x+xx-offx,y+yy-offy,celw,celh)
    end
    camera_pop()
end


function _update()
    timer += 1

    -- timers
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

    -- start game
    if is_title() then _update_title()
    else _update_game() end
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




-- @scene-title
function _update_title()
    if (rnd()>0.5) init_smoke(car_offset,98,1.2,nil,7)

    if start_game then
        start_game_flash-=1
        if start_game_flash<=-30 then
            begin_game()
        end
    elseif car_drive then
        car_offset += 2
        if car_offset > 148 then
            start_game = true
            sfx"14"
        end
    elseif btn(🅾️) or btn(❎) then 
        car_drive,start_game_flash=true,50
        music"-1"
        sfx"13"
    else draw_x += 2 end
end

function _draw_title()

    cls()
    draw_background()

    for i=0,16,2 do
        spr(112,i*8-draw_x%16,96,2,1)
    end

    foreach(particles,draw_object)
    
    -- car
    palt(15,1)
    palt(0,false)
    spr(36,car_offset,88+((draw_x+car_offset)%32<16 and 1 or 0),5,2)
    palt()
    
    -- ground
    for i=0,16 do
        local x = i*8-draw_x%8
        spr(87,x,104)
        spr((i-draw_x\8)%2==0 and 84 or 103,x,112)
    end

    -- title
    for i=0,15 do pal(i,0) end
    camera(0,sin(t()*0.5)*2.5)
    spr(unsplit"89,37,25,7,3") dpal()

    -- flash
    if start_game then
        for i=1,15 do
        pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i, start_game_flash<=10 and 1 or 0)
        end
    end

    -- title
    spr(unsplit"89,36,24,7,3")
    camera()

    -- credits
    local credits = " ★ original game - maddy thorson, noel berry ★ programming - wuffmakesgames ★ level design - smellyfishstiks ★ music - robby duguay, gruber"
    local credits_width = text_width(credits)
    for i=0,1 do
        ?credits,(i*credits_width-timer) % (credits_width*2)-credits_width,121,6
    end
    -- sspr(unpack(split"72,32,56,32,36,32"))
    -- ?"🅾️/❎",55,80,5
    -- ?"maddy thorson",40,96,5
    -- ?"noel berry",46,102,5
end


-- @scene-game
function _update_game()

    -- switch state
    _switch_active = _switches_pressed > 0

    -- water
    scroll_tile(43,2,2)
    scroll_tile(44,2,2)

    water_y = lvl_ph - water_height
    water_height = tween(water_height, water_state_active and lvl_water_hi or lvl_water_low, 0.25)
    water_exists = water_height > 0

    -- restart (soon)
    if delay_restart>0 then
        cam_spdx,cam_spdy=0,0
        delay_restart-=1
        if (delay_restart==0) load_level(lvl_id)
    end

    -- update each object
    _switches_pressed = 0
    foreach(objects,function(obj)
        obj.move(obj.spd.x,obj.spd.y,0);
        (obj.update or stat)(obj)

        -- timers
        for timer in all(obj.timers) do
            timer[1] -= 1
            if timer[1] <= 0 then
                timer[2](obj) 
                del(obj.timers,timer)
            end
        end
    end)

end

function _draw_game()
    -- draw bg color
    cls(flash_bg and frames/5 or bg_col)

    --set cam draw position
    draw_x=round(cam_x)-64
    draw_y=round(cam_y)-64
    camera(draw_x,draw_y)

    -- draw parallax bg
    draw_background(lvl_bg)

    -- draw bg terrain
    map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4)

    --set draw layering
    local layers={{},{},{}}
    foreach(objects,function(o)
        if o.layer==0 then
            if (o.outline) draw_object_outline(o.outline,o)
            draw_object(o) --draw below terrain
        else
            add(layers[o.layer],o) --add object to layer, default draw below player
        end
    end)
    foreach(particles,function(o)
        if o.layer==0 then draw_object(o)
        else add(layers[o.layer or 1],o) end
    end)

    -- outlines
    foreach(objects,function(o)
        if (o.outline and mid(o.layer,1,2) == o.layer) draw_object_outline(o.outline,o)
    end)

    -- draw terrain
    map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,2)

    -- draw objects
    foreach(layers,function(l)
        foreach(l,function(o)
            if (o.outline and o.layer == 3) draw_object_outline(o.outline,o)
            draw_object(o)
        end)
    end)

    -- dead particles
    foreach(fx_death,function(self)
        local move,spd = self.time < 1.5, self.time+1
        if move then
            self.x += sin(self.dir)*spd
            self.y += cos(self.dir)*spd
            self.dir += 0.025
        end
        -- draw
        if (self.time <= 0) del(fx_death,self)
        self.time -= 0.1
        circfill(self.x,self.y,3 * ((3 + self.time)/2 - 1), (move and 5*self.time % 2 > 1) and self.col1 or self.col2)
    end)

    camera()

    -- water
    if water_exists then
        draw_water(0,max(water_y-draw_y,0),128,128)
        line(0,water_y-draw_y,128,water_y-draw_y,7)
    end

    -- draw level title
    if ui_timer > 0 then
        if ui_timer < 30 then
        draw_ui()
        end
        ui_timer -= 1
    end
end



-- @helpers

function new_type() return setmetatable({}, {__index=_ENV}) end
function is_title() return lvl_id == 0 end

function round(x) return flr(x+0.5) end
function appr(from,to,by) return from > to and max(from-by,to) or min(from+by,to) end
function tween(from,to,by) return from+(to-from)*by end
function sign(v) return v~=0 and sgn(v) or 0 end
function tick(val,amount) return appr(val,0,amount or 1) end

function shortif(bool,val1,val2)
    if bool then return val1 end
    return val2
end

function tile_at(x,y) return mget(lvl_x+x,lvl_y+y) end
function spikes_at(obj,xspd,yspd)
    local x1,y1,x2,y2 = obj.left(),obj.top(),obj.right(),obj.bottom()
    local bottom,top,left,right = 
        y2%8 >= 6 and yspd >= 0,
        y1%8 <= 2 and yspd <= 0,
        x1%8 <= 2 and xspd <= 0,
        x2%8 >= 6 and xspd >= 0

    for i=max(0,x1\8),min(lvl_w-1,x2/8) do
        for j=max(0,y1\8),min(lvl_h-1,y2/8) do
            if (def_table("16,18,19,17",bottom,top,left,right)[tile_at(i,j)]) return true
        end
    end

    -- objects
    if objects[hidden_spike] then
        for other in all(objects[hidden_spike]) do
            if (other.state == 2 and obj.touching(other,0,0) and def_table("78,79,77,76",bottom,top,left,right)[other.spr]) return true
        end
    end

end

-- print
function text_width(text) return print(text,0,128) end
function text_height(text) print(text,0,128) return peek(0x5f27) - 128 end

function print_align(text,x,y,color,align_x,align_y)
    align_x,align_y = align_x or 0,align_y or 0
    x -= align_x*text_width(text)
    y -= align_y*text_height(text)
    return print(text,x,y,color)
end

-- camera
function camera_push(x,y)
    __cam_x,__cam_y = peek2(0x5f28),peek2(0x5f2a)
    camera(x,y)
end
function camera_pop() camera(__cam_x,__cam_y) end

-- math
function pdir(x1,y1,x2,y2) return atan2(y1-y2,x1-x2)-0.5 end
function pdist(x1,y1,x2,y2) return sqrt((x2-x1)^2+(y2-y1)^2) end
function lendir_x(len,dir) return sin(dir)*len end
function lendir_y(len,dir) return cos(dir)*len end

-- tables
function def_table(names,...) return def_table_ext({},names,...) end
function def_table_ext(table,...)
    local args = {...}
    names = split(deli(args,1))
    
    for i,v in pairs(names) do
        table[v] = args[i]
    end
    return table
end

-- data
function ssplit(str,sep,num)
    local data = def_table("true,false",true,false)
	local t = split(str,sep,num or 1)

	for i,v in pairs(t) do
		if (data[v] ~= nil) t[i] = data[v]
		if (v == "{}") t[i] = {}
	end

	return t
end

function unsplit(str,sep,num) return unpack(ssplit(str,sep,num)) end

function scroll_tile(tile,h,incr)
    if (tile>255) return

    -- args
    local temp
    local sheetwidth,spritestart,spritewide,spritehigh=64,0,4,h*8-2
    local startcol,startrow = tile%16,flr(tile/16)
    
    for i = 1,incr do
        -- save bottom row of sprite
        temp=peek4(spritestart+(startrow*sheetwidth*8)+(spritehigh*sheetwidth)+startcol*spritewide) -- 7th row
        for i=spritehigh,0,-1 do
            poke4(spritestart+(startrow*sheetwidth*8)+((i+1)*sheetwidth)+startcol*spritewide,peek4(spritestart+(startrow*sheetwidth*8)+(i*sheetwidth)+startcol*spritewide)) 
        end

        --now put bottom row on top!
        poke4(spritestart+(startrow*sheetwidth*8)+startcol*spritewide,temp)
    end
end 


function next_level()
    local next_lvl=lvl_id+1

    --check for music trigger
    if music_switches[next_lvl] then
        music(music_switches[next_lvl],500,7)
    end

    if (next_lvl == 2) lvl_bg = 1

    load_level(next_lvl,1)
end

function load_level(id,fixwater)
    has_dashed,water_state_active,has_key,_instant_death = false,false--,false
    

    --remove existing objects
    objects,particles = {},{}

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
    lvl_bg = (tbl[6] or 0) + 1
    dialogue_timer,dialogue_pos,lvl_dialogue = 15,1,tbl[7] ~= 0 and split(tbl[7],"__")

    lvl_pw,lvl_ph=lvl_w*8,lvl_h*8
    lvl_water_hi,lvl_water_low = false,8

    --level title setup
    ui_timer=35

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

            -- water level
            if (tile == 27) lvl_water_low = 0
            if tile == 14 then 
                if lvl_water_hi then lvl_water_low = lvl_ph-ty*8
                else lvl_water_hi = lvl_ph-ty*8 end
            end

            -- exit
            if (tile == mid(tile,28,31) and tile_at(tx,ty+1)~=1) lvl_exit = tile-28
        end
    end

    if (fixwater) water_height = lvl_water_low
    replace_mapdata(112,0,lvl_bg == 1 and 8 or 16,16,bg_data[lvl_bg])
end


-- @particles

function init_smoke(x,y,dx,dy,col)
    local fx = def_table("layer,x,y,dx,dy,spr,flip_x,flip_y",
        2,x,y, dx or 0.3 + rnd"0.2", dy or 0.1,45,rnd()<0.5,rnd()<0.5)

    function fx:draw()
        self.x -= self.dx
        self.y -= self.dy
        self.spr += 0.2

        dpal(7,col or 7)
        spr(self.spr,self.x,self.y,1,1,self.flip_x,self.flip_y)
        dpal(7,7)
        if (self.spr+0.2 >= 48) del(particles,fx)
    end

    return add(particles,fx)
end

function init_popup(x,y,dx,dy,text)
    local timer,fx = 90,def_table("layer",3,x,y,dx or 0,dy or -0.2)
    dx,dy = dx or 0,dy or -0.2
    function fx:draw()
        x += dx
        y += dy

        for i=1,3 do print(text,x+i%2,y+i\2,1) end
        print(text,x,y,7)

        timer -= 1
        if (timer <= 0) del(particles,fx)
    end

    return add(particles,fx)
end



-- [tile dict]

tiles = {}
function new_type(...)
  local obj = setmetatable({}, {__index=_ENV})
  for i in all({...}) do
    tiles[i] = obj
  end
  return obj
end

-- [object functions]
function init_object(type,x,y,tile)
  --generate and check berry id
  local id=x..","..y..","..lvl_id
  if type.check_fruit and got_fruit[id] then
    return
  end

  local obj = def_table("timers,type,collideable,layer,sx,sy,x,y,spd,rem,spr,outline,flip,hitbox,fruit_id",
    {},type,true,1,x,y,x,y, vector(0,0),vector(0,0), tile,1, vector(), rectangle(0,0,8,8), id)
  setmetatable(obj,{__index=type})

  -- functions
  function obj.new_timer(duration,callback) add(obj.timers,{duration,callback}) end

  function obj.left() return obj.x+obj.hitbox.x end
  function obj.right() return obj.left()+obj.hitbox.w-1 end
  function obj.top() return obj.y+obj.hitbox.y end
  function obj.bottom() return obj.top()+obj.hitbox.h-1 end

  -- collisions
  function obj.is_solid(ox,oy)
    if (obj.is_flag(ox,oy,0)) return true
    if (obj.is_flag(ox,oy,3) and not obj.is_flag(0,0,3) and oy>0) return true

    for o in all(objects) do
      if o!=obj and (o.solid_obj or o.semisolid_obj and not obj.objcollide(o,ox,0) and oy>0) and obj.objcollide(o,ox,oy) then
        return true
      end
    end
  end

  function obj.is_ice(ox,oy) return obj.is_flag(ox,oy,4) end
  function obj.is_flag(ox,oy,flag)
      return obj.check_ext(ox,oy,function(xx,yy) return fget(tile_at(mid(xx,0,lvl_w-1),mid(yy,0,lvl_h-1)),flag) end)
  end
  function obj.check_ext(ox,oy,func)
      for xx = (obj.left()+ox)\8, (obj.right()+ox)/8 do
      for yy = (obj.top()+oy)\8, (obj.bottom()+oy)/8 do
          local output = func(xx,yy)
          if (output) return output
      end end
  end

  function obj.objcollide(other,ox,oy)
    return other.collideable and obj.touching(other,ox,oy)
  end

  function obj.touching(other,ox,oy)
    return other.right()>=obj.left()+ox and
    other.bottom()>=obj.top()+oy and
    other.left()<=obj.right()+ox and
    other.top()<=obj.bottom()+oy
  end

  function obj.check(type,ox,oy,list)
    for other in all(objects[type]) do
      if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
        if list then add(list,other)
        else return other end
      end
    end
    return (list~=nil and #list > 0 and list)
  end

  function obj.player_here()
    return obj.check(player,0,0)
  end

  function obj.check_rider(ox,oy)
    for other in all(objects) do
      if other and other.moveable and other~=obj and obj.touching(other,ox or 0,oy or 0) then
        return other
      end
    end
  end

  function obj.move(ox,oy,start)
    for axis in all{"x","y"} do
      obj.rem[axis]+=axis=="x" and ox or oy

      local amt=round(obj.rem[axis])
      obj.rem[axis]-=amt
      local upmoving=axis=="y" and amt<0
      local riding=not obj.check_rider() and obj.check_rider(0,upmoving and amt or -1)
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
        local hit=obj.check_rider()
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
    return init_smoke(obj.x+(ox or 0),obj.y+(oy or 0))
  end

  if (obj.init) obj:init()
  if (not objects[type]) objects[type] = {}
  add(objects[type],obj)
  add(objects,obj)

  return obj
end

function destroy_object(obj)
  del(objects,obj)
end

function kill_player(obj)
  sfx_timer=12
  sfx"16"
  deaths+=1
  destroy_object(obj)
  create_death_particles(obj,3,7)
  delay_restart=15
end

function create_death_particles(obj,col1,col2)
    for dir = 0,0.875,0.125 do
        add(fx_death,{
            x=obj.x + 4,
            y=obj.y + 4,
            dir=dir,
            time=2,
            col1=col1 or 8,
            col2=col2 or 7,
        })
    end
end



-- @player
player = new_type()

function player:init()
    self.layer = 2
    self.was_on_ground = self.is_solid(0,1)
    def_table_ext(self,"outline,grace,jbuffer,djump,dash_time,dash_effect_time,dash_target_x,dash_target_y,dash_accel_x,dash_accel_y,hitbox,spr_off,collides,moveable",
        0,0,0, max_djump, 0,0, 0,0, 0,0, rectangle(1,-1,6,9), 0, true,true)
end

function player:animate(on_ground,under_water,input_off)
    local down,up = shortif(input_off,false,btn"3"),shortif(input_off,false,btn"2")
    if on_ground and not self.was_on_ground and self.collides then
        self.init_smoke(0,4)
        self.was_on_ground = on_ground
    end

    -- sprites
    local walkspr = 1+self.spr_off%4
    self.spr_off+=0.25
    self.bodyspr = under_water and walkspr or
        not on_ground and (self.is_solid(input_x,0) and self.collides and 5 or 3) or  -- wall slide or mid air
        self.spd.x~=0 and input_x~=0 and walkspr or -- walk
        down and 6 or 1 -- crouch or stand
    self.headspr = up and 8 or 7
end
function player:state_free(maxrun,on_ground)
    -- x movement
    local accel=self.is_ice(0,1) and 0.05 or on_ground and 0.6 or 0.4
    local deccel=0.15

    -- set x speed
    self.spd.x=abs(self.spd.x)<=1 and
    appr(self.spd.x,input_x*maxrun,accel) or
    appr(self.spd.x,sign(self.spd.x)*maxrun,deccel)

    -- y movement
    local maxfall=2

    -- wall slide
    if input_x~=0 and self.is_solid(input_x,0) and not self.is_ice(input_x,0) then
        maxfall=0.4
        -- wall slide smoke
        if not on_ground and rnd"10"<2 then
            self.init_smoke(input_x*6)
        end
    end

    -- apply gravity
    if not on_ground then
        self.spd.y=appr(self.spd.y,maxfall,abs(self.spd.y)>0.15 and 0.21 or 0.105)
    end
end
function player:state_water(maxrun,on_ground)
    local fric = 0.6
    if (btn"4") input_y = -1

    if input_x ~= 0 or input_y ~= 0 then
        local dir = pdir(0,0,input_x,input_y)
        self.spd = vector(
            appr(self.spd.x, sin(dir)*maxrun, fric),
            appr(self.spd.y, cos(dir)*maxrun, fric)
        )
    else
        self.spd.x = appr(self.spd.x,0,0.15)
        self.spd.y = appr(self.spd.y,0,0.15)
    end

end

function player:update()
    move_camera(self)
    if (_instant_death) self:kill_player()

    -- speak, theo.
    if lvl_dialogue and not dialogue_finished[lvl_id] then
        dialogue_timer -= 1
        if dialogue_timer <= 1 then
            init_popup(self.x+4,self.y-6,nil,nil,lvl_dialogue[dialogue_pos])
            dialogue_pos += 1
            dialogue_timer = 30
            if (dialogue_pos > #lvl_dialogue) dialogue_finished[lvl_id] = true
        end
    end

    -- horizontal input
    input_x=btn(➡️) and 1 or btn(⬅️) and -1 or 0
    input_y=btn(⬆️) and -1 or btn(⬇️) and 1 or 0

    -- spike collision / bottom death
    if spikes_at(self,self.spd.x,self.spd.y) or (lvl_exit ~= 3 and self.y>lvl_ph) then
        kill_player(self)
    end

    -- on ground checks
    local on_ground,under_water = self.is_solid(0,1), water_exists and self.y+4 > water_y

    -- jump and dash input
    input_jump,input_dash=btn(🅾️) and not self.p_jump,btn(❎) and not self.p_dash
    self.p_jump,self.p_dash=btn(🅾️),btn(❎)

    -- buffers
    self.jbuffer = input_jump and 4 or tick(self.jbuffer)
    self.grace = on_ground and 6 or (water_exists and self.top() < water_y and self.bottom() >= water_y) and 6 or tick(self.grace)

    if (on_ground or under_water) and self.djump<max_djump then
        psfx"15"
        self.djump=max_djump
    end

    -- dash effect timer (for dash-triggered events, e.g., berry blocks)
    self.dash_effect_time-=1

    -- dash startup period, accel toward dash target speed
    if self.dash_time>0 then
        self.init_smoke()
        self.dash_time-=1
        self.spd=vector(appr(self.spd.x,self.dash_target_x,self.dash_accel_x),appr(self.spd.y,self.dash_target_y,self.dash_accel_y))
    else
        local maxrun = under_water and 0.8 or 1;
        (under_water and self.state_water or self.state_free)(self,maxrun,on_ground,input_x,input_y)

        -- facing direction
        if (self.spd.x ~= 0) self.flip_x = self.spd.x < 0

        -- jump
        if self.jbuffer>0 then
            if self.grace>0 then
                -- normal jump
                psfx"17"
                self.jbuffer=0
                self.grace=0
                self.spd.y=-2
                self.init_smoke(0,4)
            else
                -- wall jump
                local wall_dir=(self.is_solid(-3,0) and -1 or self.is_solid(3,0) and 1 or 0)
                if wall_dir~=0 then
                    psfx"18"
                    self.jbuffer=0
                    self.spd=vector(wall_dir*(-1-maxrun),-2)
                    if not self.is_ice(wall_dir*3,0) then
                        -- wall jump smoke
                        self.init_smoke(wall_dir*6)
                    end
                end
            end
        end

        -- dash
        if input_dash then
            local d_full,d_half = 5,3.5355
        
            if self.djump>0 then
                self.init_smoke()
                self.djump-=1
                self.dash_time=4
                has_dashed=true
                self.dash_effect_time=10
                -- vertical input
                -- calculate dash speeds
                self.spd=vector(input_x~=0 and
                input_x*(input_y~=0 and d_half or d_full) or
                    (input_y~=0 and 0 or self.flip_x and -1 or 1)
                ,input_y~=0 and input_y*(input_x~=0 and d_half or d_full) or 0)
                -- effects
                psfx"19"
                freeze=2
                -- dash target speeds and accels
                self.dash_target_x=2*sign(self.spd.x)
                self.dash_target_y=(self.spd.y>=0 and 2 or 1.5)*sign(self.spd.y)
                self.dash_accel_x=self.spd.y==0 and 1.5 or 1.0606 -- 1.5 * sqrt()
                self.dash_accel_y=self.spd.x==0 and 1.5 or 1.0606
                if (self.spd.x ~= 0) self.flip_x = self.spd.x < 0
            
            -- failed dash smoke
            elseif self.djump<=0 then
                psfx"9"
                self.init_smoke()
            end
        end
    end

    -- animation
    self:animate(on_ground,under_water)

    -- exit level off the top (except summit)
    if levels[lvl_id+1] then
        if ({[0]=self.x < -4, [1]=self.x > lvl_pw-4, [2]=self.y < -4, [3]=self.y > lvl_ph})[lvl_exit] then 
            next_level()
        end
    end

    -- objects
    for obj in all(objects) do
        if (obj == self) break
        local hit = self.touching(obj,0,0)

        if obj.type == pushbox then
            if self.dash_time > 0 and self.touching(obj,self.dash_target_x,0) then
                obj.spd = vector(self.flip_x and -2 or 2,-1)
                obj.force = obj.spd.x
                self.spd = vector(-sign(self.spd.x),-1)
                self.dash_time,self.dash_effect_time = 0,0
            elseif self.touching(obj,input_x,0) then obj:repush(input_x*0.5,0) end
        elseif obj.type == water_switch and hit then
            water_state_active = obj.state
        elseif (obj.type == vspring or obj.type == hspring) and hit then
            do_spring(self,obj)
            def_table_ext(self,"dash_time,dash_effect_time",0,0)
            if (self.djump < max_djump) self.djump = max_djump
        elseif obj.type == mirror then
            obj.active = hit and on_ground
            if obj.active and btnp"2" then
                self:destroy_object()
                local other = init_object(player_mirror,self.x,self.y,1)
                other.target = obj
                obj.active = false
            end
        end
    end

    -- clamp in screen
    local clamped=mid(self.x,lvl_exit == 0 and -16 or -1, lvl_exit == 1 and lvl_pw+16 or lvl_pw-7)
    self.y = mid(self.y,-16,lvl_ph+4)
    if self.x ~= clamped then
        self.x = clamped
        self.spd.x = 0
    end
end

function player.draw(self)
    local sprite = self.bodyspr
    local ox,oy = 0,fget(sprite,7) and -1 or 0
    spr(sprite,self.x+ox,self.y+oy,1,1,self.flip_x,self.flip_y)

    if (sprite == 6) oy = 1

    local flip = self.flip_x
    if (sprite == 5) flip = not self.flip_x

    set_hair_color(self.djump)
    spr(self.headspr,self.x+ox,self.y+oy-3,1,1,flip,self.flip_y)
    dpal()

end

function set_hair_color(djump)
    dpal(2,djump==1 and 2 or djump==2 and 7 or 5)
end

-- #player spawn
player_spawn = new_type(1)
player_spawn.draw = player.draw
player_spawn.animate = player.animate

function player_spawn:init()
    def_table_ext(self,"outline,layer,spr,spr_off,flag,delay,djump",0,3,3,0,0,0,max_djump)
    self.dir = tile_at(self.x/8,self.y/8-1)-28
    self.state = self[split("state_horizontal,state_horizontal,state_up,state_down")[self.dir+1]]

    sfx"20"
    cam_y = mid(self.y,64,lvl_ph-64)

    -- going up
    if self.dir == 2 then
        self.target = self.y
        self.y = min(self.y+48,lvl_ph)
        self.spd.y =- 4

    -- falling down
    elseif self.dir == 3 then
        self.target = self.y
        self.y = -32
        self.spd.y = 3
        
    -- walking in
    else
        self.gravity = true
        self.layer = 2
        self.collides = true
        self.target = self.x
        self.x = self.dir == 0 and lvl_pw or -8
        cam_x = self.x
    end
    self.flip_x = self.dir == 0

    cam_x = mid(self.x+4,64,lvl_pw-64)
end

function player_spawn:update()
    move_camera(self)
    local on_ground,under_water = self.collides and self.is_solid(0,1), self.y+4 > water_y
    input_x,input_y = 0,0
    self:state()
    self:animate(on_ground,under_water,true)

    -- apply gravity
    if self.gravity and not on_ground then
        self.spd.y=appr(self.spd.y,2,abs(self.spd.y)>0.15 and 0.21 or 0.105)
    end

    -- exit
    if self.flag == 2 then
        self.delay -= 1
        self.spr = 6

        if self.delay < 0 then
            destroy_object(self)
            local player = init_object(player,self.x,self.y)
            def_table_ext(player,"spd,flip_x,flip_y",self.spd,self.flip_x,self.flip_y)
        end
    end
end

function player_spawn:state_up()
    if self.flag == 0 and self.y < self.target+16 then
        self.flag = 1
        self.delay = 3
    -- falling
    elseif self.flag == 1 then
        self.spd.y += 0.5
        if self.spd.y > 0 then
            if self.delay > 0 then
                -- stall at peak
                self.spd.y = 0
                self.delay -= 1
            elseif self.y > self.target then
                -- clamp at target y
                self.y = self.target
                self.spd = vector(0,0)
                self.flag = 2
                self.delay = 5
                self.init_smoke(0,4)
                sfx"21"
            end
        end
    end
end
function player_spawn:state_down() if (self.y >= self.target) self.flag,self.y = 2,self.target end
function player_spawn:state_horizontal()
    self.spd.x = sign(self.target-self.x)
    input_x = self.spd.x
    if (abs(self.x-self.target) < 2) self.flag = 2
end


-- @objects

-- #hidden spikes
hidden_spike = new_type(unsplit"76,77,78,79")
function hidden_spike:init()
    self.dir = self.spr - 76
    self.outline = false
    self.layer = 0
    self.off = 3
    self.state = 0
end
function hidden_spike:update()
    if self.state == 0 then
        if (self.player_here()) self.state = 1
    elseif self.state == 1 then
        if (not self.player_here()) self.state = 2
    else self.off = appr(self.off,0,1) end
end
function hidden_spike:draw()
    palt(8,true)

    local dir,off,ox,oy = self.dir,self.off,0,0
    if dir==0 then ox=off
    elseif dir==1 then ox-=off
    elseif dir==2 then oy=off
    elseif dir==3 then oy-=off end
    draw_obj_sprite(self,ox,oy)

    palt()
end

-- #mirror
mirror = new_type(57)
function mirror:init()
    self.hitbox.w = 32
    self.outline = false
    self.layer = 0
end
function mirror:draw()
    local top = self.y-34
    local rtop = top+4

    -- mirror
    rectfill(self.x+5,rtop,self.x+26,self.y+7,12)
    clip(self.x+5-draw_x,rtop,22,38)

    -- reflections
    foreach(objects,function(o)
        if (o.type == mirror or o.layer < 1) return

        local x = o.x
        o.flip_x = not o.flip_x
        o.x = self.x+40 - (o.x-self.x+16)

        -- sprite
        local outlined = o.outline and mid(o.layer,1,2) == o.layer
        ;(outlined and draw_object_outline or draw_object)(o.outline or o,o)
        if (outlined) draw_object(o)
        
        -- reset
        o.flip_x,o.x = not o.flip_x,x
    end)

    -- shine
    for i = 0,1 do line(self.x+8+i,rtop,self.x,rtop+8+i,7) end
    for i = 0,6 do line(self.x+20+i,rtop,self.x,rtop+20+i,7) end
    for i = 0,1 do line(self.x+29+i,rtop,self.x,rtop+29+i,7) end
    line(self.x+38,rtop,self.x,rtop+38,7)

    clip()

    -- border
    spr(41,self.x,top,2,1)
    spr(41,self.x+16,top,2,1,1)
    spr(57,self.x,self.y)
    spr(57,self.x+24,self.y,1,1,1)

    sspr(72,24,8,1,self.x,top+8,8,30)
    sspr(72,24,8,1,self.x+24,top+8,8,30,1)

    -- text
    if self.active then
        print_align("⬆️",self.x+self.hitbox.w*0.5,top-7,7,0.5,1)
        print_align("take selfie",self.x+self.hitbox.w*0.5,top-1,7,0.5,1)
    end
end

-- #water switch
water_switch = new_type(12,13)
function water_switch:init()
    self.layer,self.off = 0,self.x*0.0025
    self.state = self.spr == 12
    self.hitbox = rectangle(-1,-1,10,10)
end
function water_switch:update()
    local active = self.state ~= water_state_active
    self.spr = active and (self.state and 12 or 13) or 14
    self.off += 0.001
    self.y = active and self.sy+sin(self.off*10)*2.5 - 4 or self.sy-4
end

-- #waterfall
waterfall = new_type(59,60)
function waterfall:init()
    self.layer = (self.spr == 59 and 0 or 3)
    self.outline = false
end
function waterfall:update()
    if (self.x ~= mid(self.x,cam_x-64-16,cam_x+64)) return
    
    if self.layer == 0 then
        local tx,ty = self.x\8, water_y\8-1
        if (fget(tile_at(tx,ty),0) and fget(tile_at(tx+1,ty),0)) return
    end

    if water_exists then
        local smoke = init_smoke(self.x-4+rnd"24",water_y-2)
        smoke.layer = self.layer
    end
end
function waterfall:draw()
    if (self.x ~= mid(self.x,cam_x-64-16,cam_x+64)) return
    
    for i=0,water_y\8,2 do
        local y = self.y + i*8
        if water_y-y < 16 then sspr(88,16,16,water_y-y,self.x,y)
        else spr(43,self.x,y,2,2) end
    end

    camera_push(0,0)
    draw_water(self.x-draw_x,max(self.y-draw_y,0),16,min(water_y-self.y,water_y-draw_y))
    camera_pop()
end

-- push box
pushbox = new_type(11)
function pushbox:init()
    def_table_ext(self,"layer,force,solid_obj,collides,collideable,moveable",unsplit"2,0,true,true,true,true")
    self.maxfall = 3
end
function pushbox:update()
    local water = water_exists and self.y+4 > water_y
    self.maxfall = 3
    if water and not self.was_in_water then 
        self.splashed = true
        self.maxfall = 1
        self.spd.y*=0.3
    elseif not water and self.splashed then
        self.maxfall = 3
        self.splashed = false
    elseif self.splashed and water then
        self.maxfall = -2
    end

    if abs(self.force) > 1 and self.is_solid(self.force,0) then
        self.spd.x = -self.force
        self.force = 0
    end

    self.force = appr(self.force, 0, 0.25)
    self.spd.x = appr(self.spd.x, 0, 0.25)
    self.spd.y = appr(self.spd.y, self.maxfall, 0.25)
    self.pushed = false

    local hit = self.check(switch,0,1)
    if (hit) hit.pressed = true

    local spring = self.check(vspring,0,0) or self.check(hspring,0,0)
    if (spring) do_spring(self,spring)

    self.was_in_water = water
    self.x = mid(self.x,0,lvl_pw-8)
end
function pushbox:repush(ox,oy)
    local hit = self.check(pushbox,sign(ox),oy)
    if (hit and not hit.pushed) hit:repush(ox,oy)
    self.move(ox,oy,1)
    self.pushed = true
    self.x = mid(self.x,0,lvl_pw-8)
end

-- #horizontal door
h_door = new_type(34,35)
function h_door:init()
    def_table_ext(self,"layer,outline,solid_obj,collideable",0,false,1,1)
    
    while not self.is_solid(1,0) do
        self.hitbox.w += 8
    end
    self.max_length = self.hitbox.w
    self.state = self.spr == 35
    if (self.state) self.hitbox.w = 2
end
function h_door:update()
    self.hitbox.w = appr(self.hitbox.w,shortif(_switch_active==self.state,self.max_length,2),2)
end
function h_door:draw()
    local off = self.hitbox.w - self.max_length
    for i = 0,self.max_length-1,8 do
        spr(35,max(self.x-6,self.x+i+off),self.y)
    end
    spr(34,max(self.x-6,self.x+off),self.y)
end

-- #vertical door
v_door = new_type(50,51)
function v_door:init()
    def_table_ext(self,"layer,outline,solid_obj,collideable",0,false,1,1)
    
    while not self.is_solid(0,1) do
        self.hitbox.h += 8
    end
    self.max_length = self.hitbox.h
    self.state = self.spr == 51
    if (self.state) self.hitbox.h = 2
end
function v_door:update()
    self.hitbox.h = appr(self.hitbox.h,shortif(_switch_active==self.state,self.max_length,2),2)
end
function v_door:draw()
    local off = self.hitbox.h - self.max_length
    for i = 0,self.max_length-1,8 do
        spr(51,self.x,max(self.y-6,self.y+i+off))
    end
    spr(50,self.x,max(self.y-6,self.y+off))
end
-- #switch
switch = new_type(32)
function switch:init()
    self.layer = 0
    self.hitbox = rectangle(0,5,8,3)

    self.state = self.spr == 33
    self.pressed = self.state
end
function switch:update()
    if (self.pressed) _switches_pressed += 1

    self.spr = self.pressed and 33 or 32
    self.pressed = false
end
-- #vertical spring
vspring = new_type(20)
function vspring:init()
    def_table_ext(self,"depth,hide,state,dir",unsplit"0,0,0,0")
end
-- #horizontal spring
hspring = new_type(22)
function hspring:init()
    def_table_ext(self,"depth,hide,state,dir",0,0,0,self.is_solid(-1,0) and 1 or -1)
    self.flip_x = self.dir < 1
end

function do_spring(obj,spring)
    if (spring.state ~= 0) return
    spring.new_timer(10,function(self) 
        spring.state = spring.state == 1 and 0
        spring.spr -= 1
    end)
    obj.spd = spring.type == vspring and vector(obj.spd.x*0.2, -3) or vector(3*spring.dir, -1.5)
    spring.state = 1
    spring.spr += 1

    spring.init_smoke()
    psfx(8)
end

-- #refill
refill = new_type(15)
function refill:init()
    self.offset=rnd()
    self.start=self.y
    self.timer=0
    self.hitbox=rectangle(-1,-1,10,10)
end
function refill:update()
    if self.spr==15 then
        self.offset+=0.01
        self.y=self.start+sin(self.offset)*2
        local hit=self.player_here()
        if hit and hit.djump<max_djump then
            psfx"22"
            self.init_smoke()
            hit.djump=max_djump
            self.spr=0
            self.timer=60
        end
        elseif self.timer>0 then
        self.timer-=1
        else
        psfx"23"
        self.init_smoke()
        self.spr=15
    end
end

-- #crumble block
fall_floor = new_type(-1)
function fall_floor:init()
    self.solid_obj=true
    self.state=0
end
function fall_floor:update()
    -- idling
    if self.state==0 then
    for i=0,2 do
        if self.check(player,i-1,-(i%2)) then
        break_fall_floor(self)
        end
    end
    -- shaking
    elseif self.state==1 then
    self.delay-=1
    if self.delay<=0 then
        self.state=2
        self.delay=60--how long it hides for
        self.collideable=false
    end
    -- invisible, waiting to reset
    elseif self.state==2 then
    self.delay-=1
    if self.delay<=0 and not self.player_here() then
        psfx"23"
        self.state=0
        self.collideable=true
        self.init_smoke()
    end
    end
end
function fall_floor:draw()
    spr(self.state==1 and 26-self.delay/5 or self.state==0 and 23,self.x,self.y) --add an if statement if you use sprite 0 (other stuff also breaks if you do self i think)
end

function break_fall_floor(obj)
    if obj.state==0 then
        psfx"12"
        obj.state=1
        obj.delay=15--how long until it falls
        obj.init_smoke();
        (obj.check(vspring,0,-1) or {}).hide_in=15
    end
end
-- #fruit
fruit = new_type(48)
fruit.check_fruit=true
function fruit:init()
    self.start=self.y
    self.off=0
end
function fruit:update()
    check_fruit(self)
    self.off+=0.025
    self.y=self.start+sin(self.off)*2.5
end
-- #flying fruit
fly_fruit = new_type(61)
fly_fruit.check_fruit=true
function fly_fruit:init()
    self.start=self.y
    self.step=0.5
    self.sfx_delay=8
end
function fly_fruit:update()
    --fly away
    if has_dashed then
    if self.sfx_delay>0 then
        self.sfx_delay-=1
        if self.sfx_delay<=0 then
        sfx_timer=20
        sfx"11"
        end
    end
    self.spd.y=appr(self.spd.y,-3.5,0.25)
    if self.y<-16 then
        destroy_object(self)
    end
    -- wait
    else
    self.step+=0.05
    self.spd.y=sin(self.step)*0.5
    end
    -- collect
    check_fruit(self)
end
function fly_fruit:draw()
    for ox=-6,6,12 do
    spr((has_dashed or sin(self.step)>=0) and 61 or self.y>self.start and 63 or 62,self.x+ox,self.y-2,1,1,ox==-6)
    end
    spr(48,self.x,self.y)
end

function check_fruit(self)
local hit=self.player_here()
if hit then
    hit.djump=max_djump
    sfx_timer=20
    sfx"10"
    got_fruit[self.fruit_id]=true
    init_object(lifeup,self.x,self.y)
    destroy_object(self)
    if time_ticking then
    fruit_count+=1
    end
end
end

-- #popup
lifeup={
init=function(self)
    self.spd.y=-0.25
    self.duration=30
    self.flash=0
end,
update=function(self)
    self.duration-=1
    if self.duration<=0 then
    destroy_object(self)
    end
end,
draw=function(self)
    self.flash+=0.5
    ?"1000",self.x-4,self.y-4,7+self.flash%2
end
}
-- -- #fake wall
-- fake_wall={
-- check_fruit=true,
-- init=function(self)
--     self.solid_obj=true
--     self.hitbox=rectangle(0,0,16,16)
-- end,
-- update=function(self)
--     self.hitbox=rectangle(-1,-1,18,18)
--     local hit=self.player_here()
--     if hit and hit.dash_effect_time>0 then
--     hit.spd=vector(sign(hit.spd.x)*-1.5,-1.5)
--     hit.dash_time=-1
--     for ox=0,8,8 do
--         for oy=0,8,8 do
--         self.init_smoke(ox,oy)
--         end
--     end
--     init_fruit(self,4,4)
--     end
--     self.hitbox=rectangle(0,0,16,16)
-- end,
-- draw=function(self)
--     sspr(0,32,8,16,self.x,self.y)
--     sspr(0,32,8,16,self.x+8,self.y,8,16,true,true)
-- end
-- }

function init_fruit(self,ox,oy)
sfx_timer=20
sfx"16"
init_object(fruit,self.x+ox,self.y+oy,26).fruit_id=self.fruit_id
destroy_object(self)
end

-- -- #key
-- key={
-- update=function(self)
--     self.spr=flr(9.5+sin(frames/30))
--     if frames==18 then --if spr==10 and previous spr~=10
--     self.flip_x = not self.flip_x
--     end
--     if self.player_here() then
--     sfx"13"
--     sfx_timer=10
--     destroy_object(self)
--     has_key=true
--     end
-- end
-- }
-- -- #chest
-- chest={
-- check_fruit=true,
-- init=function(self)
--     self.x-=4
--     self.start=self.x
--     self.timer=20
-- end,
-- update=function(self)
--     if has_key then
--     self.timer-=1
--     self.x=self.start-1+rnd"3"
--     if self.timer<=0 then
--         init_fruit(self,0,-4)
--     end
--     end
-- end
-- }
-- -- #flag
-- flag={
-- init=function(self)
--     self.x+=5
-- end,
-- update=function(self)
--     if not self.show and self.player_here() then
--     sfx"55"
--     sfx_timer,self.show,time_ticking=30,true,false
--     end
-- end,
-- draw=function(self)
--     spr(118+frames/5%3,self.x,self.y)
--     if self.show then
--     camera()
--     rectfill(32,2,96,31,0)
--     spr(26,55,6)
--     ?"x"..fruit_count,64,9,7
--     draw_time(49,16)
--     ?"deaths:"..deaths,48,24,7
--     camera(draw_x,draw_y)
--     end
-- end
-- }

function psfx(num)
    if sfx_timer<=0 then
        sfx(num)
    end
end



-- @cutscenes
player_mirror = new_type()
player_mirror.draw = player.draw
function player_mirror:init()
    def_table_ext(self,"outline,state,djump,layer,timer,spr_off",0,0,max_djump,2,0,0)
end
function player_mirror:update()
    self.timer = tick(self.timer)
    input_x,input_y = sign(self.spd.x),0
    player.animate(self,1,false,true)

    if self.state == 0 and self.target then
        local x = self.target.x + 24
        local spd = sign(x - self.x)

        self.spd.x = appr(self.spd.x,spd,0.6)

        if abs(self.x - x) < 1 then 
            self.state = 2
            self.timer = 15
        end
    elseif self.state == 2 then
        self.spd.x = 0
        if self.timer <= 0 then
            self.timer = 30
            self.state = 3
        end
    elseif self.state == 3 then
        self.bodyspr = 10

        if self.timer <= 0 then
            time_ticking = false
            screenflash = 16
            self.state = 4
            self.timer = 16
            sfx"13"
        end
    elseif self.state == 4 and self.timer <= 0 then
        game_win = true
        self:destroy_object()
        music(-1)
    end
end



-->8
--[map metadata]

--@conf
--[[
autotiles={{73, 75, 74, 64, 64, 66, 65, 96, 96, 98, 97, 80, 80, 82, 81, 68, 69, [0] = 65}, {86, 88, 87, 86, 86, 88, 87, 118, 118, 120, 13, 102, 102, 104, 81, 84, 103, [0] = 86}, {70, 72, 71, 71, 70, 72, 71, 71, 70, 72, 71, 71, 70, 72, 71, [0] = 115}}
composite_shapes={}
param_names={"background", "dialogue"}
]]
--@begin
--level table
--"x,y,w,h,title"
levels={
  "0,0,2.6875,1,0b0001,1,well...__this is the place",
  "2.6875,0,1,1,0b0001,0,0",
  "3.6875,0,1.3125,1,0b0001,0,0",
  "0,1,2,1,0b0001,0,0",
  "5,0,1,1,0b0001,0,hmm__decent lighting",
  "2,1,1,1,0b0001,0,0",
  "3,1,2,1,0b0001,0,0",
  "6,0,1,1,0b0001,0,0",
  "5,1,2.25,1,0b0001,0,what even",
  "5.875,1,2.125,1,0b0001,0,0",
  "0,2,1,2,0b0001,0,0",
  "4,2,1.6875,1,0b0001,0,i'm close...",
  "1,3,1,1,0b0001,0,..."
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={
  [4] = "515151515151515151514551515200003b005051520000000000000060616161515151515144515151515144515200000000606162000000000000000000320051455151515151515144455151520000000000000000000000000000001d0000515151515151515151515151515213000000000000534300000000000000005351515151515151515151515151521300000040414141420000000000404141415151446161616161616144515152130000006061616162000000000060615151515152003b00000000005051515213000000000000000000000c00000000505161616200000000000000606161621300000000000000000000000000000050510000000000000000000032000000000000000c0000000000000000000000505100001d0000000000000000000d000000000000000000000010101000000050446465015300000b00000000000000000043000000000000005657584647485045414141414246470000004041414141414142464700000e006651680000005051515151445200000000005044454444444552000000000000665168000000505151445151520073002000504545515144515200000000000066546800000050444445515152575757575750515151515144520000000000006667680000005051515151515251676751675051514551515152000000000e006651680000005051",
  [5] = "515213003b1e0000115051515151515145521300000000001150445151514551445213000e3d000011505145515151515152130000000000115051515151514444521300000000001150455151515151515213000000000011504544454451516162000000000000006061616161455100000000000000000000003b0000505100001d000000000000000e000000505100730143530010000000000064655051414141414141420000000000404145515144515151515200000000005051445151515144454452000000000050515151515151515151520000000e00505151545154515151514400000c00004551445151444551545151000000000051515145",
  [10] = "45456651680000003b00000000000000000000000000000000504451455151515144514466676800000000000000000000000000000000000000005045515151515151515151767778000000000000000000000000000000000000000050515151515151515151455200000000000000000000000000000000000000000000505151445151515151515152000000000000000c000000000000000000000d000000504551515151515151444452000b00000000000000000000000b00000000000000005044455151514551514556575758000000000000000000005657584647474747474860616161455151515151666751681600000000000000000066546800000000000e0000000011505151515144665154680000000000000000000066676800000000000000000000115045444544627677777800000000000000000000665168530000000000000000001160616161610000000000000000000000000000007677784b46470000000000000000000032000000001d000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000001d000000414141414141421300000000000074750000007340414200000000200000436465005144454451455213000000001156575757575758504452160000404141414141414145455151515152130000000011665451675167685051521010105045515151454451"
}

--@end

music_switches = {}
bg_data = {
  "8c8d0000008a8b519c9d000000009a9bacad00000000aaabbcbd00000000babb51cc000000c9cacb51dc000000dadb5151eced0000eb515151fcfd0000fafb5100008e5151518f0000009e5151519f00000000ae5151af00000000be5151bf000000cdce5151cf000000ddde5151df000000ee515151ef000000fe515151ff00",
  "8888888888888888888888888888888888888888a9a8888888888888a9a88888a8a9898989898989a8a9898989a8a98989898989898989898989898989898989b9b88989898989b9b88989b9b889b9b8d9d9d9d9d9b8b9d9d9d9d9d9b8b9d9d9b9b889898989898989b9b88989898989d9b8b9d9d9d9d9d9d9d9d9d9d9b8b9d9e8d9e8d9e8d9e8d9e8d9e8d9e8d9e8d9f8f9f8f9f8f9f8f9f8f9f8f9f8f9f8f9c898c898c898c898c898c898c898c898d8e9d8e9d8e9d8e9d8e9d8e9d8e9d8e999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
}

--replace mapdata with hex
function replace_mapdata(x,y,w,h,data)
  for i=1,#data,2 do
    mset(x+i\2%w,y+i\2\w,"0x"..sub(data,i,i+1))
  end
end

--copy mapdata string to clipboard
function get_mapdata(x,y,w,h)
  local reserve=""
  for i=0,w*h-1 do
    reserve..=num2hex(mget(x+i%w,y+i\w))
  end
  printh(reserve,"@clip")
end

--convert mapdata to memory data
function num2hex(v)
  return sub(tostr(v,true),5,6)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666666600000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000222000002220000000000000000365555556000ccc0000099900000222000007b000
000000000000000000000000090000000900000000000000000000000022222000222220000000000000000365e5ee560000ccc000009990000022200077bb00
0000000009000000090000000900000009000000000000900000000001221110012444000000000009000004655ee55600ccccc000999990002222200777bbb0
000000000920000009200000092000000920000000000290090000000121440001244400000000000920000065ee55560c77ddc009774490022111200bbb3330
000000000934334009343340003433400034334000434320092000000124440001224400000000000934333065e55e560ccdddc0099444900221112000bb3300
0000000000222220002222200022222004222220000222400934334000124420001222200000000000222220655555560ccdddc00994449002211120000b3000
00000000004004000040004004000040000004000000400004222220000222200002222000000000004004006666666600cccc00009999000022220000000000
00000000000006666765676555000000000000000000000000000000000000000000000000666000577750000080080000080000000000000000a00000bbb000
0000000000077777676567656660000000000000000000000000400040000000000000000618160066666000000880000088000000009000000aaa0000bbb000
000000000000066667606760777770000000000000000000050590009000000000000000611811606161600000088000088888880000990000aaaaa000bbb000
00700070000000550700070066600000049999400000000050509000900000000000000061188860566650000080080088888888999999900aaaaaaa00bbb000
0070007000000666070007005500000000500500000000005050900090000000000000006111116006160000000000000888888899999999000aaa00bbbbbbb0
0676067600077777000000006660000000055000000000000505900090000000000000000611160000000000777777770088000099999990000aaa000bbbbb00
5676567600000666000000007777700000500500000000000000400040000000000000000066600000000000cccccccc0008000000009900000aaa0000bbb000
5676567600000055000000006660000000055000049999400000000000000000000000000000000000000000cccccccc0000000000009000000aaa00000b0000
00000000000000006666006600000000ffffffffffffffffffffffffffffffffffffffff00000000000000eec00000000000000c000000000000000070000000
00000000000000005556665666666666ffffffffffffffffffffffffffffffffffffffff00ee0000eeeeee15c00000000000000c007700000770070007000007
00000000000000005556515655655565ffffffffffffffffffffffffffffffffffffffff00e5555155155515c00000000000000c007770700777000000000000
00000000000000005556515655655565fffffffff777777777777777777fffffffffffff0001111155111115c00000000000000c077777700770000000000000
00bbb700000000005556515655655565ff6fffffddddddddddddddddddddffffffffffff0005150000000001c00000000000000c077777700000700000000000
ee333766000000005556515655655565ff6fffddcdcccccdcccccdcc7777dfffffffffff0005100000000000c00000000000000c077777700000077000000000
55555ee600bbb7005556115611111111ff6ffddccdcccccdccccccdccccccdffffffffff0005100000000000c00000000000000c070777000007077007000070
55555ee655555ee61116001100000000ff6fddcccdcccccdccccccddccccccdfffffffff0005100000000000c00000000000000c000000007000000000000000
0300b0b0166666101555555601555560ff6dddddd77dddd77dddddd111111111ffffffff0005100000000000cd000000000000dc000000000000000000000000
003b3300667776601555555601555560ccccccccdcccccdccccccccccccc1ddddddddfff0005100000000000cdddd000000ddddc000777770000000000000000
02888820666666601555555601666660cccc7777cc77777cc7777777ccccdddddddddfff0005100000000000cddddddddddddddc007766700000000000000000
08988880611611606666666601555560fdc7d000dccccccdcccd000d77c9771111117fff0005100000000000c00dddddddddd00c076777000000000000000000
08888980611611600155556001555560666d00000ccccccdccc00000ccc977d1dd1d7fff0005100000000000c0000dddddd0000c077660000777770000000000
08898880166666100111116001555560ffdd05000ccccccdccc05000ccc1ddd1dd1dffff0001100000000000c00000000000000c077770000777767007700000
02888820061616001555555601666660ffff00000ff00000fff00000ff00000fffffffff000ee10000000000c00000000000000c000000000000007700777770
00288200000000001666666601555560fffff000ffff000fffff000ffff000ffffffffff0005510000000000c00000000000000c000000000000000000077777
0777c777777c777c777c777000000000111ddccd11dccc116e66666e6666666e666666e60777c777777c777c777c777088888666558888888888888867656765
77cc7cc7ccc7dcc7ccc7ccc7000000001dd1dddc11ddddc155555555555555555555555577cc7cc7ccc7dcc7ccc7ccc788877777666888888888888867656765
7ccc7cccdcccdcccccccccc7000000001dd1dddcdd1dddd10055000000000000000055007ccc7cccdcccdcccccccccc788888666777778888888888867686768
7cccdccddcc77ccddc77dcc7000000001dcc1ddddd1ddcc105e000000000000000000e507cccdccddcc77ccddc77dcc788888855666888888878887887888788
ccdddddd7dcccdccdcccdccc000000001dddcddddcc1ddd1e6000000000000000000006eccdcccdc7dccccd77cccd77c88888666558888888878887887888788
7cdc77ddc7ddddccdddddcc7000000001dddd111ddd1ddd16000000000000000000000067ccddddcc7cc77dcc7ddccc788877777666888888676867688888888
7cdcc77dccddddddddcc7dd7001cc00011ddd1111dd111110000000000000000000000007ccdccdcccdccc7ccddcccc788888666777778885676567688888888
cdddcccddd1ddd11ddccccdc001dcc00111111111111111100000000000000000000000007dd1dddddd1ddd1dddd1d7088888855666888885676567688888888
777cdcc1111111111ddcc77c00000000111eeee100000000066e666e66ee666ee666e66000000000000055555555000000000000000000055555555000000000
7cc7dddd11111111dc7dccc70000000011155eee000000006ee6eee6ee6eeee6eeee6ee655550055555557777775055550005555555555557777775555555555
7cccdc7d11111111dcc7dcc7000000001555555e000000006eeeeeeeeeeeeeeeeeeeeee657750057757757777775557755055775577777557777775777777775
ccccdcc1111111111cc7dcc7000000001555555e00000000eee5eee5ee55eee5eeee5eee57750057757755577557757775557775777777755577555777777775
7ccdddc7111111111dccdddc001ccc001555555500000000e66555ee555ee55e55555e6e57750057757750577557757777577775775557750577505777555555
7ccdddcc11111111ddccc77c01ddccc011555555000000006ee65555e5555e55e555eee657750057757750577557757777777775775557750577505777555550
cdddc7dd11111111ddddccc701dddcc011111551000000006eee5555e5555e55e555eee657750057757750577557757757775775777777750577505777777750
7ccdcc7111111111ddddcccc01dddccd1111111100000000eee555555155511555555eee57750057757750577557757755755775777777750577505777777750
c77ddccddd11ddd1ddddd77c000000000001ccccccc00000e6655ee5111111111555ee6e57750057757750577557757755555ddddd5557750577505777555550
7ccc77ddddddc77ddc7dccc700000000001ddccccccc00006ee6555e11115ee1155eeee657755557757750577557757dddd0dd777dd057750577505777500000
7ccccc7ddc7dccc7dcc7ccc700000000001ddccccccc00006eee555e1115555e555eeee657777777757750577557757d77d0d77777ddddd50577505777555555
7ccccccddcc7dcccdcc7dccc00000000001dddddddddd000eee5ee555e15555e555eeee657777777757dddddd557757d77d0d77d77dd77d50577505777777775
ccdcccdc7dccccd77cccd77c0000000001cccc1dcccccc00e66555e155e5555e5555ee6e5577777755dd7777dddddddd77d0d77ddddd77d0ddddd05777777775
7ccddddcc7cc77dcc7ddccc7000000001ddddcc1dddcccc06eee55e155e555511ee55ee60555555550d77777dd7777dd77ddd77dddd7ddddd777dd5555555555
7ccdccdcccdccc7ccddcccc7000000001dddddc1dddcccc06eee555155155511555e5ee60000000000d77777d77dd77dd77d77777dd77dd777777dd000000000
07dd1dddddd1ddd1dddd1d70000000001dddddc1dddcccc0eeeee55511111111555e5eee0000000000d777ddd77d777dd77d77777d77dd777dd777d000000000
005ee6000000000000000000000000000005666666600000e6655e5551e66155e665556e0000000000d77777d77777ddd77dd77ddd77dd7777dd77d000000000
eeeeeeeeeeeeeeee0000000000000000005ee666666600006ee6555ee5eee65eeee655560000000000ddd7777d77dd77d77dd77dd77ddd77d77777d000000000
55555555555555550000000000000000005ee666666600006eee555eee5eee5eeeee5556000000000000ddd77d777777d77dd77dd77d0d777dd77dd000000000
55555555555555550000000000566600005eeeeeeeeee000eee55ee5ee5555555ee5566e00000000000ddd777dd777dddddddddddddd0dd7777ddd0000000000
eeeeeeeeeeeeeeee0000000005e666600566665e666666006eee555e55555ee55555eee600000000000d77777dddddd000000000000000dd777d000000000000
00555500000000000000000005ee66605eeee665eee66660655e555e5ee5555e5e55eee600000000000d7777dd000000000000000000000ddddd000000000000
005ee60000000000000000005eeeeee65eeeee65eee66660e5555555555e555555e5eee600000000000dddddd000000000000000000000000000000000000000
005ee60000000000000000005eeeeee65eeeee65eee666600e5eeee5eeee5eeeeeee5e6000000000000000000000000000000000000000000000000000000000
15151525000000000000000005441515000000000000000000000000000000004444444499999999000000dddd11111111111111111111000000111111110000
54250000000544151515151515151515155415151515155415151515151515154444444499999999000000ddddd11111111111111dddd1000000111111100000
1616162600000000000000000554151500000000000000000000000000000000444444449999999900000001dddddd111111111ddddddc000000011111110000
152500000005151544161616161615151515151515151515441544151515151544444444999999990000000ddddddd11111111dddddddc000000011111110000
000000000000000000000000054415150000000000000000000000000000000044444444999999990000000ddddddd11111111dddddddc000000001111110000
442500f1000515542600b300000005154416161616541515151515151515151544444444999999990000000ddddddd11111111ddddddc0000000001111110000
00d100000000000000000000061616540000000000000000000000000000000044444444999999990000000dddddd111111111dddddc00000000000111110000
1525001000051525000000000000065425000000000616164415151654151515444444449999999900000000ddd111111111111dddd000000000001111100000
57100000000000000000000000000005000000000000000000000000000000003333333311111111dd1dddd111111111111111111dd000000000001110000000
15250000000515250000000000000006260000000000c3000515150005151515333333331111111100dddddd11111111111111ddddc000000000001111000000
7575757585000000000000000000000500000000000000000000000000000000333333331111111100dddddd111111111111ddddddc000000000001111000000
15250000000515250000b0000000000000000000000000000515540005151515333333331111111100dddddd111111111111ddddddc000000000001111000000
4576157686000000000000000000000500000000000000000000000000000000333333331111111100dddddd111dd111111dddddddc000000000001111000000
15250000000515250000020000000000000000000000000005151500055415443333333311111111000ddd11dddddd11111dddddddc000000000000110000000
151515158637b000000000000000000500000000000000000000000000000000333333331111111100000ddddddddd111111dddd110000000000000100000000
1525000000051544141414141424000000000424000000000654150006161616333333331111111100000ddddddddd1111111dddddc000000000000010000000
15151515457575856400000000000005000000000000000000000000000000004444444449999999000000dddddddd11111ddddddddc00001111111110000000
1525000000065415151515155425000000000554243200000005150000b300009444444444999999000000dddd111111111ddddddddc00000111111110000000
7645154515457686000000000000000500000000000000000000000000000000994444444449999900000001ddddd11111dddddddddc00001111111110000000
152500000000061616161616162600000000051525000000000616000000000099944444444499990000000dddddd11111dddddddddc00001111111110000000
777777777777778700000000000000050000000000000000000000000000000099994444444449990000000dddddd11111dddddddddc00001111111100000000
5425000000000000000000002300000000000554250000000000000000000000999994444444449900000000dddd11111111ddddddc000001111111110000000
25000000000000000000000000000005000000000000000000000000000000009999994444444449000000000111111111111111dd1000001111111111000000
15250000000000000000000000000000000444152500000000d1000000000000999999944444444400000000ddd11111111111ddddc000001111111111000000
2500000000000000000000000000000500000000000000000000000000000000999999999aaaaaaa00000000ddd11111111111dddddc00000111111111000000
1525000000000000000000000000000000051515250000000000000002000000a999999999aaaaaa0000000dddd11111111111dddddc00000011111111100000
2500000000000000000000000000000500000000000000000000000000000000aa999999999aaaaa0000000dddd111111111111ddddc00000111111111100000
1544141414141414141414141414141414541515441414141414141414141414aaa999999999aaaa0000000dddd111111111111ddddc00000111111111100000
2500000001010101010101010000000500000000000000000000000000000000aaaa999999999aaa0000000ddd11111111111111dddc00000111111111100000
1515154415151515151515154454151515151515151515151515547644155415aaaaa999999999aa00000001d1111111111111111ddd00000111111111100000
2531000004141414141414240000000500000000000000000000000000000000aaaaaa999999999a0000000111111111111111111ddd00001111111111000000
1515151515151515151515151515151515151515151515151515151515151515aaaaaaa99999999900000dddd1111111111111111dd000001111111100000000
253100000544151515445425000000051515151515151515151515151515151533333333000000000000dddddd11111111100000000000001111111111000000
542500000005441515151515151515151554151515151554151515000000000033333333000000000000dddddd111111dddc0000000000001111111111100000
2531000005151515441616260000000515151515151515151515151515151515333333330000000000000ddddd111111ddddc000000000000111111111100000
15250000000515154416161616161515151515151515151544154400000000003333333300000000000001ddd11111111ddddc00000000011111111111100000
25000011051515152521212100000005151515151515151515151515151515153331133300000000000001111111111111dddc00000000111111111111100000
442500f1000515542600b30000000515441616161654151515151500000000003331133300000000ddd111111111111111dddc00000000111111111111100000
25000011051515152500000000000005151515441616161616161616541515153311113300000ddddddd111111111111111ddc00000000111111111111110000
1525001000051525000000000000065425000000000616164415150000000000331111330000dddddddd111111111111111ddc00000000111111111111111000
250000110515155425000001010101051515152500000000000000000515151531111113aaaaaaaa000ddddddddd1111111ddd00000000111111111111111000
15250000000515250000000000000006260000000000b300051515000000000031111113aaaaaaaa000ddddd1dd11111111ddd00000000111111111111111000
250000000616161626000014141414541515152500000000000000000515151511111111aaaaaaaa000ddddd11111111111dd000000000011111111111111000
15250000000515250000b000000000000000000000000000051554000000000011111111aaaaaaaa000dddd11111111111111000000000011111111111111000
250000000000000000000000000544544415542500000000000000000554154411111111aaaaaaaa000011111111111111111110000000001111111111111000
152500000005152500000200000000000000000000000000051515000000000011111111aaaaaaaa00ddddd11111111111111dcc000000000111111111110000
250000000000000000000000000544151616162600000000000000000616161611111111aaaaaaaa0ddddddd111111111111dddd000000001111111111100000
152500000005154414141414142400000000042400000000065415000000000011111111aaaaaaaa0ddddddd111111111111dddd000000011111111111111000
2500000000000000000000036105541500b30000000000000000000000b30000aaaaaaaa33311333000000000ddddddd1111ddddc00000000000000111111100
1525000000065415151515155425000000000554243200000005150000000000aaaaaaaa33311333000000000ddddd111111ddddc00000000000000111111100
2501010100000000000000000005151500000000000000000000000000000000aaaaaaaa33111133000000000ddddd1111111dddd00000000000000111111100
1525000000000616161616161626000000000515250000000006160000000000aaaaaaaa33111133000000000ddddd1111111dddd00000000000000111111100
4414142400000001010101010105151500000000000000000000000000000000aaa33aaa31111113000000000ddddd11111111ddd00000000000001111111100
5425000000000000000000002300000000000554250000000000000000000000aaa33aaa31111113000000000ddddd1111111111cc0000000000011111111000
445444250000000414141414145415150000d100000093000000000000000000aa3333aa111111110000000000dddd11111111ddddc000000000011111111000
15250000000000000000000000000000000444152500000000d1000000000000aa3333aa111111110000000000ddd111111111ddddc000000000001111111100
1515442500f10005444454544454151500001002006575757575850002000000a333333aaaa33aaa000000111111111111111dddddc000000000111111111100
1525000000000000000000000000000000051515250000000000000000000000a333333aaaa33aaa000000dddd11111111111dddddc000000001111111111100
1515542500b1000554151515151515151414141414664515157686141414141433333333aa3333aa000000dddd11111111111dddddc000000001111111111100
154414141414141414141414141414141454151544141414141414000000000033333333aa3333aa000000ddddd11111111111ddddd000000001111111111100
151544250000000554151515151515155415544454661515151586764415541533333333a333333a000000ddddd111111111111ddd0000000001111111111100
151515441515151515151515445415151515151515151515151554000000000033333333a333333a000000ddddd1111111111dddc00000000001111111111100
15154425000000054415151515151515151515151545151515154515151515153333333333333333000000ddd11111111111ddddc00000000001111111111000
15151515151515151515151515151515151515151515151515151500000000003333333333333333000000dddd1111111111dddc000000000000111111111000
__label__
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444499999994444444444444444444444444444444444444444444444444444444449999999444444444444444444444444
44444444444444444444444444444444449999999444444444444444444444444444444444444444444444444444444444999999944444444444444444444444
44444444444444444444444444444444444999999944444444444444444444444444444444444444444444444444444444499999994444444444444444444444
44444444444444444444444444444444444499999994444444444444444444444444444444444444444444444444444444449999999444444444444444444444
44444444444444444444444444444444444449999999444444444444444444444444444444444444444444444444444444444999999944444444444444444444
44444444444444444444444444444444444444999999944444444444444444444444444444444444444444444444444444444499999994444444444444444444
44444444444444444444444444444444444444499999994444444444444444444444444444444444444444444444444444444449999999444444444444444444
44444444444444444444444444444444444444449999999444444444444444444444444444444444444444444444444444444444999999944444444444444444
44444444499999999999999999999999999999999999999999999999999999994444444449999999999999999999999999999999444444444999999999999999
94444444449999999999999999999999999999999999999999999999999999999444444444999999999999999999999999999999944444444499999999999999
99444444444999999999999999999999999999999999999999999999999999999944444444499999999999999999999999999999994444444449999999999999
99944444444499999999999999999999999999999999999999999999999999999994444444449999999999999999999999999999999444444444999999999999
99994444444449999999999999999999999999999999999999999999999999999999444444444999999999999999999999999999999944444444499999999999
99999444444444999999999999999999999999999999999999999999999999999999944444444499999999999999999999999999999994444444449999999999
99999944444444499999999999999999999999999999999999999999999999999999994444444449999999999999999999999999999999444444444999999999
99999994444444449999999999999999999999999999999999999999999999999999999444444444999999999999999999999999999999944444444499999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999955555555999999999999999999955555555999999999999999999999999999999999999999999999
99999999999999999999999999999999999955559955555557777775055559995555555555557777775555555555999999999999999999999999999999999999
99999999999999999999999999999999999957750957757757777775557755955775577777557777775777777775099999999999999999999999999999999999
99999999999999999999999999999999999957750957757755577557757775557775777777755577555777777775099999999999999999999999999999999999
99999999999999999999999999999999999957750957757750577557757777577775775557750577505777555555099999999999999999999999999999999999
99999999999999999999999999999999999957750957757750577557757777777775775557750577505777555550099999999999999999999999999999999999
99999999999999999999999999999999999957750957757750577557757757775775777777750577505777777750999999999999999999999999999999999999
9aaaaaaa999999999999999999999999999957750957757750577557757755755775777777750577505777777750aaaa99999999999999999aaaaaaa99999999
99aaaaaaa99999999999999999999999999957750957757750577557757755555sssss5557750577505777555550aaaaa99999999999999999aaaaaaa9999999
999aaaaaaa9999999999999999999999999957755557757750577557757ssss0ss777ss057750577505777500000aaaaaa99999999999999999aaaaaaa999999
9999aaaaaaa999999999999999999999999957777777757750577557757s77s0s77777sssss50577505777555555aaaaaaa99999999999999999aaaaaaa99999
99999aaaaaaa99999999999999999999999957777777757ssssss557757s77s0s77s77ss77s505775057777777750aaaaaaa99999999999999999aaaaaaa9999
999999aaaaaaa999999999999999999999995577777755ss7777ssssssss77s0s77sssss77s0sssss0577777777509aaaaaaa99999999999999999aaaaaaa999
9999999aaaaaaa99999999999999999999999555555550s77777ss7777ss77sss77ssss7sssss777ss5555555555099aaaaaaa99999999999999999aaaaaaa99
99999999aaaaaaa9999999999999999999999900000000s77777s77ss77ss77s77777ss77ss777777ss0000000000999aaaaaaa99999999999999999aaaaaaa9
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999s777sss77s777ss77s77777s77ss777ss777s0aaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99999s77777s77777sss77ss77sss77ss7777ss77s0aaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9999sss7777s77ss77s77ss77ss77sss77s77777s0aaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99990sss77s777777s77ss77ss77s0s777ss77ss0aaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999sss777ss777ssssssssssssss0ss7777sss00aaaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99s77777ssssss00000000000000ass777s000aaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9s7777ss000000aaaaaaaaaaaaaaasssss0aaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaassssss009aaaaaaaaaaaaaaaaaaaa00000aaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaa
9aaaaaaa99999999999999999999999999999999999999990000009999999999999999999aaaaaaa999999999999999999999999999999999999999999999999
99aaaaaaa99999999999999999999999999999999999999999999999999999999999999999aaaaaaa99999999999999999999999999999999999999999999999
999aaaaaaa99999999999999999999999999999999999999999999999999999999999999999aaaaaaa9999999999999999999999999999999999999999999999
9999aaaaaaa99999999999999999999999999999999999999999999999999999999999999999aaaaaaa999999999999999999999999999999999999999999999
99999aaaaaaa99999999999999999999999999999999999999999999999999999999999999999aaaaaaa99999999999999999999999999999999999999999999
999999aaaaaaa99999999999999999999999999999999999999999999999999999999999999999aaaaaaa9999999999999999999999999999999999999999999
9999999aaaaaaa99999999999999999999999999999999999999999999999999999999999999999aaaaaaa999999999999999999999999999999999999999999
99999999aaaaaaa99999999999999999999999999999999999999999999999999999999999999999aaaaaaa99999999999999999999999999999999999999999
aaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaa
aaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaa
aaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaaaa
aaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaaa
aaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaaa
aaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaaa
aaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaaa
aaaaaaaaaaaaaaa999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaa
aa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaaaa33aaaaaaaaaaaa
a3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaa
a3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaaa3333aaaaaaaaaaa
333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa
333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa333333aaaa33aaaa
3333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa3
3333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa33333333aa3333aa3
3333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a3
3333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a33333333a333333a3
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33113333333333333311333333333333331133333333333333113333333333333311333333333333331133333333333333113333333333333311333333333333
33113333333333333311333333333333331133333333333333113333333333333311333333333333331133333333333333113333333333333311333333333333
31111333333333333111133333333333311113333333333331111333333333333111133333333333311113333333333331111333333333333111133333333333
31111333333333333111133333333333311113333333333331111333333333333111133333333333311113333333333331111333333333333111133333333333
11111133331133331111113333113333111111333311333311111133331133331111113333113333111111333311333311111133331133331111113333113333
11111133331133331111113333113333111111333311333311111133331133331111113333113333111111333311333311111133331133331111113333113333
11111113311113311111111331111331111111133111133111111113311113311111111331111331111111133111133111111113311113311111111331111331
11111113311113311111111331111331111111133111133111111117777777777777777771111331111111133111133111111113311113311111111331111331
111111131111113111111113111111311111111311111131611111ssssssssssssssssssss111131111111131111113111111113111111311111111311111131
1111111311111131111111131111113111111113111111316111sscscccccscccccscc7777s11131111111131111113111111113111111311111111311111131
111111111111111111111111111111111111111111111111611ssccscccccsccccccsccccccs1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111161sscccscccccsccccccssccccccs111111111111111111111111111111111111111111111111111
m61111111111115mm61111111111115mm61111111111115m6ssssss77ssss77ssssss1111111115mm61111111111115mm61111111111115mm61111111111115m
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccccccccscccccsccccccccccccc1ssssssssmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
5555555555555555555555555555555555555555555575cccc7777cc77777cc7777777ccccsssssssss555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555777sc7s000sccccccscccs000s77c9771111117555555555555555555555555555555555555555555555
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm77666s00000ccccccsccc00000ccc977s1ss1s7mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
551111111111115555111111111111555511111111117777ss05000ccccccsccc05000ccc1sss1ss1s1111111111115555111111111111555511111111111155
m61111111111115mm61111111111115mm611111111111777m70000011000005mm00000110000015mm61111111111115mm61111111111115mm61111111111115m
m61111111111115mm61111111111115mm61111111111177mm61000111100015mm60001111000115mm61111111111115mm61111111111115mm61111111111115m
666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm666m66mm
mmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6mmmm6mm6m
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55mmm5mm55
m55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555mm55m555m
5m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m555
5m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m5555m55m555
51155155511551555115515551155155511551555115515551155155511551555115515551155155511551555115515551155155511551555115515551155155
mmm111111111111mmmm111111111111mmmm111111111111mmmm111111111111mmmm111111111111mmmm111111111111mmmm111111111111mmmm111111111111m
5mmm11115mm111155mmm11115mm111155mmm11115mm111155mmm11115mm111155mmm11115mm111155mmm11115mm111155mmm11115mm111155mmm11115mm11115
555m1115555m1555555m1115555m1555555m1115555m1555555m1115555m1555555m1115555m1555555m1115555m1555555m1115555m1555555m1115555m1555
555m5m15555m1555555m5m15555m1555555m5m15555m1555555m5m15555m1555555m5m15555m1555555m5m15555m1555555m5m15555m1555555m5m15555m1555
555555m5555m1555555555m5555m1555555555m5555m1555555555m5555m1555555555m5555m1555555555m5555m1555555555m5555m1555555555m5555m1555
555555m555511155555555m555511155555555m555511155555555m555511155555555m555511155555555m555511155555555m555511155555555m555511155
15515515551111111551551555111111155155155511111115515515551111111551551555111111155155155511111115515515551111111551551555111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611111111166166616661166166616611666161111111166166616661666111111111111166616661661166116161111166616161166166611661166166
11116661111111616161611611611116116161616161111111611161616661611111111111111166616161616161616161111116116161616161616111616161
11666666611111616166111611611116116161666161111111611166616161661111116661111161616661616161616661111116116661616166116661616161
11166666111111616161611611616116116161616161111111616161616161611111111111111161616161616161611161111116116161616161611161616161
11161116111111661161616661666166616161616166611111666161616161666111111111111161616161666166616661111116116161661161616611661161
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
000000800000000000000000000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000303030403030a0a0a03030300000000030303040300030303000000000000000303030004040303030000000000000004040404040403030300000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000005044515200000000000000003c005044515151523c00000000000000006654515151515100000000006045514461616161616145003b000000003b0000504445520000000000000000000000000000000000000000000000005151515152000000000e00606161445100000000000000000000000000000000
0000000000000060616162000000000000000000006061455144620000000000000000006667515167515100001e0000005051523d0000000000500000000000000000005051515200000d0000001d00000000000000000000000000000000005151515152000000001e00003b00505100000000000000000000000000000000
00000000000000003b00000000000000000000000000006061620000000000000000000066515151515151530b0000000050515200000000000050000000003d00000000505145520000000000004353000000000000000000000000000000005151515152000000000000000c00505100000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000066676751675467414142130000606162000b0000000050000000000000000000504551524647474748404141000000000000000000000000000000005151456162000000000000101010505100000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000076777777777777454462130000000000730b00000000500000000000000000006061616200000e0000504444000000000000000000000000000000005151521212000000000000404141445100000000000000000000000000000000
0000000000000000000b0000000000000000000000000000000000000000000000000000003b005045515151516213000011565757584600000050000000000000000000003b00000000000000504451000000000000000000000000000000005145520000000000000000505151515100000000000000000000000000000000
0000000000474840414142000000000000000000000000000000000000000000000000000000005051514451516213000011665167680000000050000000000000000000000000000000000000504451000000000000000000000000000000005151520000000000000000505145616100000000000000000000000000000000
0000000000000050445152000000000000000000000000000000000000000000000000000000005045515144516213000011767777780000001150000000000000000000000000000000000000505151000000000000000000000000000000005151520000000000000000505152000000000000000000000000000000000000
0000000000000060514552000000000000000000000000000000000000000000000000000000006061616161616213000000000000000000001150000000000000000000000000000000000000504551000000000000000000000000000000005151521010141010000000505152003000000000000000000000000000000000
0000000000000000606162000000565758000000000000000000000000000000534300000000000033000000000000000000000000000000001150000000000000000000000000000000000000505151000000000000000000000000000000005151444141414142000000505152000000000000000000000000000000000000
00000000000000000000000000006654680000000000000000000000000056575846470000000000001d00001d0000000000000000000000001150000000000000000000000000000000000000504451000000000000000000000000000000006161616161616162000000606162000000000000000000000000000000000000
0000001d00000000000000000000665168747500004300000000000000736654680000000064650043530000010000000b004364650000530011500000001e00000000000000000000000c0000504551000000000000000000000000000000000000000000000000000000121212000000000000000000000000000000000000
00747501007071707170737071706651675757584647474747474748565767516800004041414141414141414141414141414141414141414141457300000100004300007374750000000000005051510000000000000000000000000000000000001d0000000000000000000000000000000000000000000000000000000000
5757575757575757575757575757665151675168000000000000000066545151680000504551445151444445514451455151445145444451515144575757575757575757575757580000000000505151000000000000000000000000000000000073017475000000000000101010101000000000000000000000000000000000
5451675151516754515451515151665151454141420000000000004041414451680000505151514451515151515145515151515151515151514551675451675154675167515467680000000000505151000000000000000000000000000000005757575758000000000000404141414100000000000000000000000000000000
51515151675151515151515151516667515151445200000000000050455151676800005051515151515151514551515151515144515151515151515151515151515151515151516800000e0000504451000000000000000000000000000000005167515468000000000e00504451454400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005200000000006667546754516767516751523b0000005045445151444445515261616161616161616161615044515151520000000000606161623b000000000000000000000000007677783b000000003b505145000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005222001e0000767777777777777754675152221e00006061616161616161616200000000000000003b00006061614551520000000000330000000000001010101010000000000000123212000000000000504551000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000052000000000000003b000000003b6651515200000000000000003b000000000000000000000000000000000000005045520000000000000000000000004041414142000000000000000000000000000000505151000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005200000d000000000000000000006667515200000000000000000000000000000000000000000000000000000000504452000b000000004353200000005051445152000000000000000000000000000000505144000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000520000000000000000000000435366545152000000000000000000565757575800000000000000000000000000005051575758220000404141420000115051514552464700000000000000000000000000504544000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005200000000404141414246474856545151520000000000000000006651516768000000000d0000000000000000005044515168000000505151520000115045514452000000000000001010101000000000606161000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005200000e0060616161620000007667546262464700000000000000767777546873000000000000734300000000005044777778000000606161620000116061616162000000000000004041414200000000003200000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000052000000001212121212000000126667000000000000000000000000000066545758464747474856575758000000504552000000000000000000000000121212123200000000000000505144520000000000001d000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000052000000000000000000000000006654000000000000000e00000000000076777778000000000066546768000000504452001e000000000000000000000000000000000000000000005051515200000000646543000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000520000000000207300000000000066670000001e000000000000000000000000000000000000007677777800000050455200011b0000000000000000000000000000000010101010105051515200000040404141000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005200000000494a4b4647474747486651536465010000000b000000000000000000000000000000000000000000005051524647474747000000000000000000000000000056575757575045515200000050444451000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000520000000000000000000000000066514141414141424647470000000000000c00000000000000000000000000005051520000000000000000000000004e4e4e4e100e0076777777775051515246474850514445000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005200001e000000000000000c0000665445514445445200000000000000747553000000000000000000000043205350445200000010101010100000000040414141420000000000001150515152000b0050455151000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000524300010000000b00004300747566675151515144520000001010104041414141421010101010101010105657585051522300004041414142000000005045514552000000000000115045515200207350515151000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000004442464748404141414141414141414151455151455200000040414145454445444541414141414141414166676850445200300050444551520000000050514444520000000c0000115044455257575750514544000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000455200000050454445515145514445445144455144520000005045445151514451444544514544444544446651685044520000005051514552000000005051444552000000000000115045445254675150444551000000000000000000000000
__sfx__
013d00200a6100f611156111c6112c6113161131611236111b6110d6110d6110c6110b6110a621096110861107611096110b6110161106611076110f611186111c61125611256111c61116611126110d61109611
0108080a1307014070180701806018050180401803018020180141801500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b0809245701d5701c5701c5601c5501c5401c5301c5201c5100050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010200280c31500000000000000000000000000f2250000000000000000c3000c415000000000000000000000c3000000000000000000c30000000000000741500000000000c2150000000000000000c30000000
010300280000000000246250000000000000000000000000246150000000000000000c30018625000000000018000180002430018000180001800024300180001800018000000000000000000000000000000000
011000010017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01090004180701a07015070160700c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c000000000000000000000000000000000
0109000418070160701307011070295052650529505265052d505295052950526505225051f5051d505215052e5052b50528505245052d5052d5052850528505265052e5052b5052850524505215051d50521505
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
007800000c8410c8410c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c84018841188401884018840188401884018840188402483124830248302483024830248302483024830
01780000269542694026930185351870007525075240752507534000002495424940249301d5241d7000c5250c5242952500000000002b525000001d5241d5250a5440a5450a5440a5201a7341a7350a0350a024
017800000072400735007440075500744007350072400715007340072500000057440575505744057350572405735057440575503744037350372403735037440375503744037350372403735037440373503704
017800000a0041f734219442194224a5424a5224a45265351a5341a5350000026934269421ba541ba501ba550c5340c5450c5540c555000001f9541f9501f955225251f5341f52522a2022a3222a452b7342b725
011800200c0351004515055170550c0351004515055170550c0351004513055180550c0351004513055180550c0351104513055150550c0351104513055150550c0351104513055150550c035110451305515055
010c0020102451c0071c007102351c0071c007102251c007000001022510005000001021500000000001021013245000001320013235000001320013225000001320013225000001320013215000001320013215
0030002000040000400003000030020400203004040040300504005040050300503005020050200502005020070400704007030070300b0400b0400b0300b0300c0400c0400c0300c0300c0200c0200c0200c020
003000202874028740287302872026740267301c7401c7301d7401d7401d7401d7401d7301d7301d7201d72023740237402373023720267402674026730267201c7401c7401c7401c7401c7301c7301c7201c720
00180020010630170000000010631f633000000000000000010630000000000000001f633000000000000000010630000000000010631f633000000000000000010630000001063000001f633000000000000000
00180020176151761515615126150e6150c6150b6150c6151161514615126150d6150e61513615146150e615136151761517615156151461513615126150f6150e6150a615076150561504615026150161501615
011800101154300000000001054300000000000e55300000000000c553000000b5630956300003075730c00300000000000000000000000000000000000000000000000000000000000000000000000000000000
001800200e0351003511035150350e0351003511035150350e0351003511035150350e0351003511035150350c0350e03510035130350c0350e03510035130350c0350e03510035130350c0350e0351003513035
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002200022000220001b0002400024000270001f0002b0002200027000220002900029000290001600022000220002b0001b000240002400027000180001d0001d0001f0001f0001f0001d0001d0001d000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
__music__
03 18191a1b
01 1c1c4243
00 1d1d431c
00 1e1d431c
00 1f1e201c
00 1f1e201c
00 1e41431c
00 211d451c
00 1e21201c
00 1e1f201c
00 1e1f201c
02 221d2223
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354
00 51525354

