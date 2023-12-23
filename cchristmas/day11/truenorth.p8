pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--~true north~
--by meep
--based on celeste classic
--by maddy thorson and noel berry
function vector(f,n)return{x=f,y=n}end function zvec()return vector(0,0)end function rectangle(f,n,e,d)return{x=f,y=n,w=e,h=d}end function init_cam()exec[[gset◆_cx,0
gset◆_cy,0
gset◆_cdx,0
gset◆_cdy,0
gset◆_cg,0.1
gset◆cam_x,0
gset◆cam_y,0]]end function move_cam(f,n)if(cam_lock)return
local n=n or _cg _cdx,_cdy=e_appr_delta(_cx,mid(0,f.hmid()-63,8*rw-128),n),e_appr_delta(_cy,mid(0,f.vmid()-63,8*rh-128),n)_cx+=_cdx _cy+=_cdy cam_x,cam_y=round(_cx),round(_cy)end function cam_draw()exec[[camera◆cam_x,cam_y]]end function _init()cartdata"aocctruenorth"exec[[poke◆0x5f2e,1
init_cam
init_g_particles
title_init]]menuitem(1,"quick restart",function()begin_game()load_room(2)end)menuitem(2,"clear save data",function()for f=0,5do dset(f,0)end end)end function begin_game()hat,run_chievs=dget"5",{}exec[[gset◆seconds_f,0
gset◆minutes,0
gset◆deaths,0
gset◆fruits,0
gset◆delay_restart,0
gset◆held
gset◆storage
gset◆game_is_good
gset◆_update,game_update
gset◆_draw,game_draw
load_room◆1]]end function game_update()update_time()if(closet)closet_update()return
foreach(objects,function(f)if(f.freeze>0)f.freeze-=1return
f.move(f.spd.x,f.spd.y)f:update()end)if delay_restart>0then delay_restart-=1if(delay_restart==0)exec[[gset◆collect
gset◆held
load_room◆room]]
end if(room_goto)exec[[load_room◆room_goto
gset◆room_goto]]
end function draw_mountains(f,n)camera(cam_x-f,cam_y-n)exec[[spr◆0,0,0,16,7
spr◆112,128,0,5,7]]end function game_draw()exec[[pal
camera
cls◆12
rectfill◆0,0,127,1,7
rectfill◆0,3,127,3,7
rectfill◆0,6,127,6,7
rectfill◆0,78,127,127,6
draw_clouds
cam_draw
ssload◆1]]local f=round(cam_x*.75-rx-ry*1024)local n=cam_x-f for n=n\166,(n+127)\166do draw_mountains(166*n+f,cam_y+38)end exec[[ssload◆0,0x1000]]outline(function()cmap"0x02"end)exec[[obj_outlines
cmap◆0x02]]foreach(sort(objects,"layer"),draw_obj)foreach(debris,function(f)f.x+=f.dx f.y+=f.dy f.dy+=.1f.t+=1if(f.t>=30)del(debris,f)
rectfill(f.x,f.y,f.x+1,f.y+1,f.c)end)foreach(smoke,function(f)f._spr+=.2f.x+=f.spd.x f.y+=f.spd.y if(f._spr>=16)del(smoke,f)else draw_spr(f)
end)foreach(dead_particles,function(f)f.x+=f.dx f.y+=f.dy f.t-=.2if(f.t<=0)del(dead_particles,f)
rectfill(f.x-f.t,f.y-f.t,f.x+f.t,f.y+f.t,6+f.t*5%2)end)exec[[camera
draw_snowflakes
secret_pal]]if(closet)closet_draw()
if(get_obj(player_spawn)and room>1)exec[[draw_time◆4,4]]
end function secret_pal()exec[[pal◆2,132,1]]end function cmap(f)map(rx+cam_x\8,ry+cam_y\8,cam_x\8*8,cam_y\8*8,16+ceil(cam_x%8),16+ceil(cam_y%8),f)end function screen_fade(f)if(f)fillp(f<=0and.5or f<.33333and 2565.5or f<.66666and 23130.5or f<1and 64245.5or-.5)exec[[rectfill◆0,0,127,127,7
fillp]]
end function l_appr(f,n,e)return f>n and max(f-e,n)or min(f+e,n)end function e_appr_delta(f,n,e)return e*(n-f)end function sign(f)return f==0and 0or sgn(f)end function round(f)return flr(f+.5)end function tile_at(f,n,e)if(f>=0and f<rw and n>=0and n<rh)return mget(rx+f,ry+n)
return e end function tile_set(f,n,e)if(f>=0and f<rw and n>=0and n<rh)mset(rx+f,ry+n,e)
end function two_digit_str(f)return f<10and"0"..f or f end function update_time()if(ticking)seconds_f+=1minutes+=seconds_f\1800seconds_f%=1800
end function draw_time(f,n)rectfill(f,n,f+44,n+6,0)?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),f+1,n+1,7
end function filter(n,e)local f={}foreach(n,function(n)if(e(n))add(f,n)
end)return f end function sort(n,e)local f={}foreach(n,function(n)for d=1,#f do if(n[e]<=f[d][e])return add(f,n,d)
end add(f,n)end)return f end function get_objs(f)return filter(objects,function(n)return n.obj==f end)end function get_obj(f)return get_objs(f)[1]end function get_player()return get_obj(player)or get_obj(player_spawn)end function pal_all(f)for n=1,15do pal(n,f)end end function draw_spr(f,n,e)spr(f._spr,f.x+(n or 0),f.y+(e or 0),1,1,f.flp.x,f.flp.y)end function outline(n)exec[[pal_all◆0]]pal=stat foreach(split"-1 0,1 0,0 -1,0 1",function(f)local e,d=usplit(f," ")local f,e=usplit(f," ")camera(cam_x+f,cam_y+e)n()end)pal=_pal cam_draw()end _pal=pal function obj_outlines()foreach(objects,function(f)if(f.outline)outline(function()f:draw()end)
end)exec[[pal
cam_draw]]end function draw_obj(f)f:draw()end function glow(f)for n=0,.875,.125do local n=n+t()%2/2pset(f.hmid()+5.5*cos(n),f.vmid()+5.5*sin(n),7)end end _btn=btn function cprint(f,n,e,d)?f,64-2*#f+n,e,d
end function gset(n,f)_ENV[n]=_ENV[f]or f end function usplit(f,n,e)if(f)local f=split(f,n)for d,n in pairs(f)do f[d]=not e and _ENV[n]or n end return unpack(f)
end function exec(f)foreach(split(f,"\n"),function(f)local f,n=usplit(f,"◆",true)_ENV[f](usplit(n,",",f=="gset"))end)end function load_gfx(e,f)local n=0for e=1,#f,2do for d=1,("0x"..f[e])+1do sset(n%128,n\128,"0x"..f[e+1])n+=1end end save_ss(e)reload()end function save_ss(f)memcpy(32768+8192*f,0,8192)end function ssload(f)memcpy(0,32768+8192*f,8192)end for i=0,191 do sset(16+i%24,16+i\24,tonum("0x"..sub("00000400000000000000000000000460000000000000d00000004060000010000000dd000000406000006000d0066d600004006000005000dd66d6160004000600000600dd66d6660020000600500600d00666607776000600066000000d0d00",i+1,i+1))) end exec[[save_ss◆0
load_gfx◆1,f0f09007f0f0f0f0f0f0f0d027f0f0f0f0f0f0f0b037f0f0f0f0f0f0f0a057f0f0f0f0f0f0f0077067f0f0f0f0f0f0d0376077f0f0f0f0f0f0b05740070677f0f0f0f0f0f0907720070687f0f0f0f0f0f070a7000706070687f0f0f0f0f0f050c706070697f0f0f0f0f0f040e706070697f0f0f0f0a007f050f7e7f0f0f0f08027f030f7f7f0f0f0f07047f010f7f717f0f0f0f05067e0f7f737f0f0f0f04077d0f7f757f0f0f0f0200677c0f7f777f0f0f0f010070667c0f7f777f0f0f0f0000706070657c0f7f787f0f0f0e00706070667c0f7f787f0f0f0d00706070677c0f7f797f0f0f0b0c7c0f7f7a7f0f03007f040d7c0f7f7a7f0f02027f020e7c0f7f7b7f0f000470007e0f7c0f7f7b7f0f087c0f707b007060706f7f797f0d00706670607a0f717a0070607060706f7f797f0b00706470627060790f717900706070607060706f7f727060706070607f0a007060706070607060706070607060770f7278007060706070607060706f7c7060706070607060706070607f080070607060706070607060706070607060750f7377007060706070607060706f7a70607060706070607060706070607f0800706070607060706070607060706070607060730f74760070607060706070607060706f7a70607060706070607060706070607f06007060706070607060706070607060706070607060710f757500706070607060706070607060706f78706070607060706070607060706070607f050060706070607060706070607060706070607060706f7774007060706070607060706070607060706f767060706070607060706070607060706070607f04007060706070607060706070607060706070607060706f76730070607060706070607060706070607060706f7470607060706070607060706070607060706070607f02007060706070607060706070607060706070607060706f777200706070607060706070607060706070607060706f7270607060706070607060706070607060706070607f02007060706070607060706070607060706070607060706f7871007060706070607060706070607060706070607060706e7060706070607060706070607060706070607060706070607f00007060706070607060706070607060706070607060706f767060706000706070607060706070607060706070607060706070607060706a706070607060706070607060706070607060706070607060706070007200780070607060706070607060706070607060706070607060706f70706070607060706170607060706070607060706070607060706070607060706070607066706070607060706070607060706070607060706070607060706070607060706070007060760070607060706070607060706070607060706070607060706f707060706070607060716070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060740070607060706070607060706070607060706070607060706f707060706070607060706170607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070007000706070607060706070607060706070607060706070607060706e706070607060706070607060007060706070607060706070607060706070607060706070607060706070607060706070607060706070607060706070007000706070607060706070607060706070607060706070607060706070607060706070007000706070607060706070607060706e706070607060706070607060710070607060706070607060706070607000700070007060706070607060706070607060706070607060706070007400706070607060706070607060706070607060706070607060706070607060740070607060706070607060706c70607060706070607060706070607062007060706070607060706070607600700070607060706070607060706070607060706076007060706070607060706070607060706070607060706070607060706070607060740070607060706070607060706a706070607060706070607060706070607300700070007060706070607a007060706070607060706070607060706076007060706070607060706070607060706070607060706070607060706070607060700074007060706070607060706070607060706070607060706070607000700070607060706070607068007060706070607a00706070607060706070607060706076007060706070607060706070607060706070607060706070607060706070607060760070607060706070607060706070607060706070607060700074007060706070607060770070607060706070607a0070607060706070607060706078007000706070607060706070607000700070607000706070607060700070007800706070607060706070607060706070607060700078007060706070007700706070607060706070607a00700070007060706070607c00706070607060706074007200706070007c007060706070607060706070607060706070007a00706070007900706070607060706070607f00007000700070007c007060706070607060760070007f000070007060706070607060706070607e00770070007000706070607060706070607f0f0200700070607060706070607f0e007000700070607060706070607f050070007060706070607060706070007f0f02007000700070607060706070607f0f020070007000706070607f070070007000700070007f0f0a0070607060706070607f0f06007000700070007f0f0f0f0700700070007000700070007f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e007f0f0f0f0f0f0f0e017f0f0f0f0f0f0f0d027f0f0f0f0f0f0f0c037f0f0f0f0f0f0f0b047f0f0f0f0f0f0f0a047f0f0f0f0f0f0f0a047f0f0f0f0f0f0f0a04706f0f0f0f0f0f0f09037060706f05017f0f0f0f0f0f000270607060706f03037f0f0f0f0f0f03706070607f02057f0f0f0f0f0e027060706070607f00077f0f0f0f0f0d037060706070607e097f0f0f0f0f0c0a7d00687f0f0f0f0f0c0b7b00607062706070627f0f0f0f0f0b0c7900607060706070607060706070607f0f0f0f0f0a0d77006070607060706070607060706070607f0f0f0f0f090e7500607060706070607060706070607060706f0f0f0f0f090e74006070607060706070607060706070607060706f0f0f0f0f080f720060706070607060706070607060706070607060706f0f0f0f0f070f707000607060706070607060706070607060706070607060706f0f0f0f0f0600706070607066706070607060706070607060706070607060706070607060706070607f0f0f0f0f060060706070607060706070607060706070607060706070607060706070607060706070607060706070607f0f0f0f0f050070607060706070607060706070607060706070607060706070607060706070607060706070607060706f0f0f0f0f050060706070607060706070607060706070607060706070607060706070607060706070607060706070607f0f0f0f0f0500706070607060706070607060706070607060706070607060706070607060706070607060706070007f0f0f0f0f0600607060706070607060706070607060706070607060706070607060706070607060706070007f0f0f0f0f090070607060706070607060706070607060706070607060706070607060706070607060706f0f0f0f0f0b00607060706070607060706070607060706070607060706070607060706070607060706f0f0f0f0f0c00706070607060706070607060706070607060706070607060706070607060706070607f0f0f0f0f0c006070607060706070607060706070607060706070607060706070607060706070607f0f0f0f0f0f0000607060706070607060706070607060706070607060706070607060706070607f0f0f0f0f0f00006070607060706070607060706070610070607060706070607060706070607f0f0f0f0f0f000060706070607060706070607063007060706070607060706070007060706f0f0f0f0f0e0070607060706070607060760070607060706070607200700070607f0f0f0f0f0d0070607060700070007800706070607060760070007f0f0f0f0f0d0070007e00700070007f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f010
load_gfx◆2,fc8cf7f7f7f7f7f767fc7cf7f7f7f7f7f777fc5cf7f7f7f7f7f797fc2cf7f7f7f7f7f7c7fc0c16f7f7f7f7f7f7c7ec26f7f7f7f7f7f7d7dcf7f7f7f7f7f7f717ccf7f7f7f7f7f7f727ccf7d703f7f7f7f7f737acf7f703f7f7f7f7f7379cf7f713f7f7f7f7f7377cf7f71713f7f7f7f7f7373cf7f75713f7f7f7f7f7372c16f7f737130bf7f7f7f7f7371c16f7f747031bf7f7f7f7f7370c16f7e71347030bf7f7f7f7f7470c06f7f7031b371bf787060706f7f7f78706f7f707130b27030bf7f7f7f7f7f7f787031b17030bf7f7f7f7f7f7f787130b17030bf7f7f7d7561706f7f727a6471307130b0703f7f74726f717269706f7f7b63743071bf7f71766f716f7f7b725b6173307030b03f7f73736e726e706f7c725d6072307030bf7f7f7f7f7f707461765960753f7f7f7f7f7f7461785860743f7f7f7f7f7f777858607434716f7f7f7f7f7f7078536450746f7f7f7f7f7f777f5051756f7f7f7f7f7f787c5f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7d716f7f7f7f7f7f7f7b726f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7b716f7f7f7f7f7f7f7f7f7f7d746f7f76766f7f7f7f7f736f7f72776f7f7f7f7f7f7f77736f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c726f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7870238f7f7f7f7f7f7f7b7122802f7f7f7f7f7f7f7b7122802f7f7f7f7f7f7f7b7022802f7f7f7f7f7f7f7b70228f7f7f7f7f7f7f7c7020802f7f7f70766f7f7f7b7423822f7f7d7c6f7f7f7672208027802f7f7c7366536f7f7f737320802a8f7f7a716c516f7f7f717320802c8f7f79706e506f7f7f707320802e8f7f787f505f7f7f7320802f808f7f787e5f7f7f7320802f828f7f787c5f7f7f707220802f838f7f7b765f7f7f7272208020802f8080e18f7f7f7f7f7f747320802380e9802181e08f7f7f7f7f7f7472208020802182e2802181e08123802f7f7f7f7f7f727420802282e18020802081e08222802f7f7f7f7f7f7273208020802280e18020812081e080200121802f7f7f7f7f7f727420802080238020802080238020f00120802f7f7f7f7f7f7275208020802284238021f0022f7f7f7f7f7f717f22228020e071f0012f7f7f7f7f7f717f21f0228000e170f0410f7f7f7f7f7f717e20f070f0218020e270f04f7f7f7f7f7f737e20f070f320e270ff7f7f7f7f7f747e22f021f00370ff7f7f7f7f7f747e2044f470f09f7f7f7f7f7f727f202042f670ff7f7f7f7f7f72700f23f271e170ff7f7f7f7f7f727f2023f670ff7f7f7f7f7f727002200b23f670ff7f7f7f7f7f71700020002004200624f470ff7f7f7f7f7f7271002202200020002002200043f370ff7f7f7f7f7f727502200020002000200220004094f09f7f7f7f7f7f7277002000240020002000209f7f7f7f7f7f787100760026002000210f7f7f7f7f7f7a7f040f7f7f7f7f7f797e00560f7f7f7f7f7f787d01d70f7f7f7f7f7f777c02d80f7f7f7f7f7f757b005004d70f7f7f7f7f7f747a0051d050d251d30f7f7f7f7f7f767a00d0cbd00f7f7f7f7f7f75790050d3c9d00f7f7f7f7f7f70d27a02d3c5d2c00f7f7f7f7f7f71d1790057d052d2c0d05f7f7f7f7f7b70d17160d06079005bd2c0d05f7f7f7f7f7b71d160d0601060760150d055d053d1c0d05f7f7f7f7f7c71d160d261750152d45003d1c0d05f7f7f7f7f7c70d17363730251c4d05006d05f7f7f7f7f7f70d070d17
load_gfx◆3,f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0609726f0f04067f0f0f0f0507766f0f0507716f0f0f090d7f0f0f02756f0f0f0806766d006f0f0f0f0f0f03056f0300607b0074657f0f0f0f0f0f04006070607907667f0f0f0f0f0f010060706070607e0e7f0f0f0f0f0a00607060706070607d0e7f0f0f0f0f0900607060706070617f0f0f0f0f0f0f0500607060706070627f0f0f0f0f0f0f05007060706070647f0f0f0f0f0f0f030070607060706675007f0f0f0f0f0f0a007060706a7300617f0f0f0f0f0f080f7071006070617f0f0f0f0f0f070f717060706070617f0f0f0f0f0f050f73706070637f0f0f0f0f0f030f75706070627f0f0f0f0f0f020f77706070627f0f0f0f0f0f010f7870647f0f0f0f0f0f0f7a70647f0f0f0f0f0d0f7f727f0f0f0f0f0b006f7f747f0f0f0f0f09006f7f74706f0f0f0f0f070263776f76726f0f0f0f0f05046179697663746f0f0f0f0f030f62687860766f0f0f0f0f01005c6056657f626f0f0f0f0f0050605a605060576174605060506058605069003f0f0f0f000131006050605260326050305060506050305a605060306050605132603060506050340031013f0f0f0f0001300030533062306050603060506050603060516033603060506230605062306052305061330031013f0f0f0f0430663060506230605062306050603060506130506230605063305062306331013100213000c000c000cf0f0f090130506053306052305330605630543050633053306830600230013012c010c010cf0f0f03003104305330605130605062306056305030506130506130206051302130506051306530223015c010cf0f0f04013101302030633053302051302130503020605062306053306133c020305430503020305130203075c031cf0f0f0501300230215060523050302130663025305130203061c033c130605060302050605060306050705036c03f0f0f07023170502052c0302051302050c334c061302130605fc6c050605077c23f0f0f04013021316fc6c030506fcfc4c030123f0f0f04023071c034c03fcfcfc6c060743f0f0f040633c13fcfcfc6c0613010203f0f0f04033060c133c130c131c035c03fcfc9c33f0f0f0700302431c730c035c035c03dc13fc63f0f0f0601302530c331c130c034c135c03dc134c03ac030c060213f0f0f07017333c231c530c07334703174c034c135c034c231c33020013f0f0f0700617b306232743172302470c034c2337331c030c131c131702f0f0f0a053171302174347133723571327030713570337330c06071306f0f0f0e002035007031002030280172310271013401350135003071003f0f0f090571057101720170057101300172017104710571057101700030017f0f0f0506700670017201700673027101700670067006700172017f0f0f0701730172017001720170017803700170017201700172017201730172017f0f0f0701e305e101e201e003e606e001e201e005e301e306ef0f0f0701e301e201e001e201e001e801e003e001e201e001e201e201e301e201ef0f0f0701e301e201e006e005e401e102e006e001e201e201e301e201ef0f0f0701e301e201e104e106e301e201e104e101e201e201e301e201ef0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a0]]rm_data=split([[0,0,48,16,0b10,left
48,0,16,16,0b10,left
64,0,16,16,0b01,left
80,0,16,16,0b01,bottom
96,0,16,16,0b01,bottom
112,0,16,16,0b01,bottom
0,16,32,16,0b10,bottom
32,16,16,16,0b01,left
48,16,16,16,0b10,left
64,16,16,16,0b10,left
80,16,16,16,0b10,left
96,16,16,16,0b01,left
112,16,16,16,0b01,bottom
0,32,32,16,0b10,bottom
32,32,32,16,0b01,left
64,32,16,16,0b10,bottom
80,32,32,16,0b01,left
112,32,16,16,0b00,bottom]],"\n")function room_globals(f)room,rx,ry,rw,rh,re,rs=f,usplit(rm_data[f])end function load_room(f)if(f>1)ticking=true
if(f<14)reload()
room_globals(f)objects,smoke,dead_particles={},{},{}for n=0,rh-1do for e=0,rw-1do local f=tile_at(e,n)if(tiles[f])init_object(tiles[f],8*e,8*n,f)
end end if(room==13)init_object(pickup,12,63,35)
cam_lock,exit_lock,collect=nil,nil,nil pmusic(room==18and 63or 0,1000,3)end function pmusic(f,n,e)if(curr_music~=f)curr_music=f music(f,n,e)
end player={init=function(f)f.layer,f.grace,f.jbuffer,f.djump,f.dash_cd,f.dash_time,f.dash_target_x,f.dash_target_y,f.dash_accel_x,f.dash_accel_y,f.hitbox,f.spr_off,f.solid,f.rider=1,0,0,1,0,0,0,0,0,0,rectangle(usplit"1,3,6,5"),0,true,true create_hair(f)end,update=function(f)local n,t,d=tonum(btn"1")-tonum(btn"0"),tonum(btn"3")-tonum(btn"2"),f.is_solid(0,1)if(f.is_flag(0,0,"spike")or f.top()>=rh*8)kill_obj(f)return
if(re&1>0and f.bottom()<0or re&2>0and f.left()>=8*rw)room_goto=room+1storage,held=held,nil
if(d and not f.was_on_ground)f.init_smoke(0,4)
local e,o=btn"4"and not f.p_jump,btn"5"and not f.p_dash f.p_jump,f.p_dash=btn"4",btn"5"if e then f.jbuffer=4elseif f.jbuffer>0then f.jbuffer-=1end if d then f.grace=6if(f.djump<1)sfx"14"f.djump=1
elseif f.grace>0then f.grace-=1end f.dash_cd=max(f.dash_cd-1)if o then local e=f.check(pickup)or f.check_pickup(24,0,1)if not held and e and btn"3"and d then o,held=false,e e.delete()elseif held then if held.action and not(btn"3"and d)then o=held.action(f)else e=init_object(pickup,f.x,f.y,held._spr)e.move(0,-6)while(e.is_solid(0,0))e.y+=1
e.spd,e.flp.x,o,held=vector((t>0and 1.25or 3)*(n~=0and n or f.flp.x and-1or 1),t-1),held.flp.x,false,false sfx"24"end end end if f.dash_time>0then f.init_smoke()f.dash_time-=1f.spd=vector(l_appr(f.spd.x,f.dash_target_x,f.dash_accel_x),l_appr(f.spd.y,f.dash_target_y,f.dash_accel_y))else local e,c,i=2,d and.93or.8,.16f.spd.x=abs(f.spd.x)<=e and l_appr(f.spd.x,n*e,c)or l_appr(f.spd.x,sign(f.spd.x)*e,i)if(f.spd.x~=0)f.flp.x=f.spd.x<0
local c=3if n~=0and f.is_solid(n,0)then c=.8if(rnd(10)<2)f.init_smoke(n*6)
end if(not d)f.spd.y=l_appr(f.spd.y,c,abs(f.spd.y)>.124and.334or.167)
if f.jbuffer>0then if f.grace>0then sfx"29"f.jbuffer,f.grace,f.spd.y=0,0,-3.36f.init_smoke(0,4)else local n=f.is_solid(-3,0)and-1or f.is_solid(3,0)and 1or 0if(n~=0)sfx"2"f.jbuffer,f.spd=0,vector(-n*(e+1.06),-3.36)f.init_smoke(n*6)
end end local e,d=6.58,4.6528if f.djump>0and f.dash_cd==0and o then f.init_smoke()f.djump-=1f.dash_time,f.spd=4,vector(n~=0and n*(t~=0and d or e)or(t~=0and 0or f.flp.x and-1or 1),t~=0and t*(n~=0and d or e)or 0)sfx"3"f.dash_target_x,f.dash_target_y,f.dash_accel_x,f.dash_accel_y=3.07*sign(f.spd.x),(f.spd.y>=0and 3.07or 2.55)*sign(f.spd.y),f.spd.y==0and 2.37or 1.6758,f.spd.x==0and 2.37or 1.6758elseif f.djump<=0and o then sfx"10"f.init_smoke()end end update_hair(f)f.spr_off+=.25f._spr=not d and(f.is_solid(n,0)and 5or 3)or btn"3"and 6or btn"2"and 7or 1+(f.spd.x~=0and n~=0and f.spr_off%4or 0)f.was_on_ground=d move_cam(f)end,draw=function(f)local n=flr(f._spr)local n=n==3and-1or n==6and 1or 0pal(8,f.djump==1and 8or 12)for n,f in pairs(f.hair)do circfill(round(f.x),round(f.y),mid(4-n,1,2),8)end draw_spr(f)pal()spr(hat,f.x,f.y+-5+n,1,1,f.flp.x,f.flp.y)if(held)spr(held._spr,f.x,f.y-7+n,1,1,held.flp.x,false)
end,on_move=function(f)local n=f.check_pickup(50)if n then if f.spd.y>1and f.bottom()<=n.vmid()then f.spd.y,n.spd.y,f.dash_time=(f.jbuffer>0or btn"4")and-3.694or-2,-.1,0if(f.spd.y==-3.694)sfx"23"
return true end end end}function create_hair(f)f.hair={}for n=1,5do add(f.hair,vector(f.x,f.y))end end function update_hair(f)local n=vector(f.x+4-(f.flp.x and-2or 3),f.y+(btn(⬇️)and 4or 2.9))for e,f in pairs(f.hair)do f.x+=(n.x-f.x)/1.5f.y+=(n.y+.5-f.y)/1.5n=f end end player_spawn={init=function(f)sfx"4"held,f._spr,f.target,f.state,f.delay,f.djump=storage,3,f.y,0,0,1if rs=="left"then f.spd=vector(1.6,-2)f.y-=8f.x-=24elseif rs=="top"then f.spd.y=1f.y=max(f.y-48,-4)else f.spd.y=-4f.y=f.y+48end if(collect)init_object(fruit,f.x,f.y,collect).follow=true
create_hair(f)move_cam(f,1)end,update=function(f)if f.state==0then if(f.y<f.target+16)f.state,f.delay=1,3
elseif f.state==1then f.spd.y+=.5if(f.spd.y>0)if f.delay>0then f.spd.y=0f.delay-=1elseif f.y>f.target then f.y,f.spd,f.state,f.delay=f.target,zvec(),2,5f.init_smoke(0,4)sfx"5"end
elseif f.state==2then f.delay-=1f._spr=6if(f.delay<0)f.delete()init_object(player,f.x,f.y,1)
end update_hair(f)move_cam(f)end,draw=player.draw}refill={init=function(f)f.offset,f.timer,f.hitbox,f.active,f.layer=rnd"1",0,rectangle(usplit"-1,-1,10,10"),true,-1end,update=function(f)if f.active then f.offset+=.02local n=f.player_here()if(n and n.djump<1)sfx"6"f.init_smoke()n.djump,f.active,f.timer=1,false,60
elseif f.timer>0then f.timer-=1else sfx"7"f.init_smoke()f.active=true end end,draw=function(f)spr(f.active and 9or 8,f.x,f.y+round(sin(f.offset)))end}fruit={init=function(f)f.y_,f.follow,f.tx,f.ty,f.layer=f.y,false,f.x,f.y,1end,update=function(f)if not f.follow and f.player_here()then f.follow,collect=true,f._spr sfx"12"elseif f.follow then local n=get_player()if n then if n.obj==player_spawn then f.x+=e_appr_delta(f.x,n.x,.2)f.y_+=e_appr_delta(f.y_,n.y-4,.1)if(n.state==2and n.delay==0)sfx"8"init_object(lifeup,f.x,f.y,"1000")f.delete()fruits+=1
else f.tx+=e_appr_delta(f.tx,n.x,.4)f.ty+=e_appr_delta(f.ty,n.y,.4)local e,d=f.x-f.tx,f.y_-f.ty local n=max(1,sqrt(e^2+d^2))local t=n>12and.2or.1f.x+=e_appr_delta(f.x,f.tx+12*e/n,t)f.y_+=e_appr_delta(f.y_,f.ty+12*d/n,t)end end end f.y=round(f.y_+1.5*sin(t()*.75))end}lifeup={init=function(f)f.spd.y,f.duration,f.outline=-.25,30end,update=function(f)f.duration-=1if(f.duration<=0)f.delete()
end,draw=function(f)?f._spr,f.x+4-2*#f._spr,f.y-4,7+t()*15%4
end}pickup={init=function(f)f.rider,f.solid,f.layer,f.hitbox=true,true,2,rectangle(usplit(f._spr==24and"1,0,6,8"or"1,3,6,5"))f.action=({[34]=function(f)return false end})[f._spr]end,update=function(f)local n=f.is_solid(0,1)if(not n)f.spd.y=l_appr(f.spd.y,6,.22)
f.spd.x=l_appr(f.spd.x,0,n and 1or.1)if(f.bottom()-7>=rh*8)f.delete()
end,draw=function(f)draw_spr(f)end,on_move=function(f)if f._spr==50then local o f.hitbox=rectangle(usplit"-1,3,10,5")for n in all{"x","y"}do if abs(f.spd[n])>=2then local d=sign(f.spd[n])local e,t=n=="x"and d or 0,n=="y"and d or 0::f::local e,t=f.is_flag(e,t,3)if(e)f.init_smoke(8*e-f.x,8*t-f.y)tile_set(e,t,0)f.spd[n]=-mid(f.spd[n],f.spd[n]-2*d,0)o=true for f=1,6do add(debris,{x=8*e+4,y=8*t+4,dx=rnd()-.5,dy=-.5-rnd"1.5",c=(split"1,5,6")[1+rnd"3"\1],t=0})end goto f
end end f.hitbox=rectangle(usplit"1,3,6,5")if(o)sfx"9"return true
end local n=sign(f.spd.x)if(f.is_solid(n,0))f.spd.x=-mid(f.spd.x,f.spd.x-n,0)return true
end}crumble={init=function(f)f.solid,f.ride,f.dx=true,true,0end,update=function(f)local n,e=f.is_solid(0,1),f.check(crumble,0,-1)if not f.t and f.check(player,0,-1)then f.t=15sfx"9"elseif f.t then f.t=max(f.t-1)if(f.t==0)f.spd.y=l_appr(f.spd.y,6,.3)
end if n then f.t=0if(not f.was_on_ground)f.init_smoke(0,4)
end if(f.top()-8>=rh*8)f.delete()
f.dx,f.was_on_ground=f.t and f.t>0and rnd"2"-1or 0,n end,draw=function(f)spr(f._spr,f.x+f.dx,f.y)end}chest={init=function(f)f.ox=f.x end,update=function(f)if not f.t then foreach(f.check_all(pickup,0,1),function(n)if(n._spr==26)n.delete()f.t=15sfx"11"
end)else f.x=f.ox+rnd"2"-1f.t-=1if(f.t==0)init_object(fruit,f.ox,f.y-8,10)f.init_smoke()f.delete()
end end}flag={update=function(f)if not f.touched and f.player_here()then exec[[sfx◆15
gset◆ticking]]f.touched=true if(fruits==4)init_object(chiev,f.x,f.y-16,38)
end end,draw=function(f)if f.touched then for n=0,4do local f,e=f.x+3,f.y+1-sin(t()+n/5)rectfill(f+n,e,f+n,e+2,11)end exec[[camera◆0,-84
rectfill◆36,-1,90,38,0
rectfill◆35,0,91,37,0
rect◆36,0,90,37,5
draw_time◆41,2
spr◆10,52,19]]cprint("deaths:"..deaths,0,12,7)cprint(":"..fruits.."/4",4,21,7)for n,f in pairs{51,52,53,54,38}do if(f==38and fruits==4or run_chievs[f])spr(f,36+8*n,27)
end cam_draw()else for n=0,1do local f,e=f.x+3,f.y+1+2*n rectfill(f+n,e,f+n,e+2,11)end end end}chimney={init=function(f)f.smoke,f.outline={}end,update=function(n)if(rnd()<.25)add(n.smoke,{x=n.x+3,y=n.y-rnd"2",t=90,m=.25+rnd"0.75",c=rnd()<.7and 6or 7})
foreach(n.smoke,function(f)f.t-=1if(f.t==0)del(n.smoke,f)
f.x+=f.m/6+rnd"1"-.5f.y-=f.m/4end)end,draw=function(f)foreach(f.smoke,function(f)if(f.t<40)fillp"0b1010010110100101.1"
circfill(f.x,f.y,2*f.m,f.c)fillp()end)end}house={update=function(f)f.hitbox=rectangle(usplit"5,-1,6,9")local f=f.player_here()if(f and btn"3"and btn"5")exec[[gset◆closet,1
gset◆_cursor,0]]
end,draw=function(f)if f.player_here()then?"⬇️+❎",f.x-2,f.y-9,7
end end}function closet_update()if(btnp"0")_cursor=max(_cursor-1)
if(btnp"1")_cursor=min(5,_cursor+1)
if(btnp"5"and(_cursor==0or dget(_cursor-1)==1))hat=_cursor>0and hatbl[_cursor-1]dset(5,hat)closet=false
end function closet_draw()exec[[camera
rectfill◆33,47,94,58,0
spr◆16,35,49]]for f=0,4do if(dget(f)==1)spr(hatbl[f],45+f*10,49)
end rect(34+_cursor*10,48,43+_cursor*10,57,7)end hatbl={}foreach(split([[0,51
1,52
2,53
3,54
4,38
51,0
52,1
53,2
54,3
38,4]],"\n"),function(f)local f,n=usplit(f)hatbl[f]=n end)chiev={init=function(f)if(run_chievs[f._spr])f.delete()
end,update=function(f)if(f.player_here())run_chievs[f._spr]=true dset(hatbl[f._spr],1)sfx"26"init_object(lifeup,f.x,f.y,":madepog:")f.delete()
end,draw=function(f)draw_spr(f)glow(f)end}msg={init=function(f)f.layer,f.k=10,0f.msg,f.dx=usplit(room==18and"I WAS ONE WITH THE COSMOS,0"or f._spr==44and"THE WALLS WERE SHIFTING!,0"or f._spr==56and"BANFF NATIONAL PARK ⌂ˇ,-4"or"SNOWBALL STUCK? WALLSLIDE!,0")end,update=function(f)local e=f.player_here()f.k=e and min(f.k+1,3)or max(f.k-1)local n=f.check_pickup(37)if(f._spr==44and n)sfx"25"n.init_smoke()n.delete()init_object(chiev,f.x,f.y-16,54)
if(e and not f.player_was_here)sfx"11"
f.player_was_here=f.player_here()end,draw=function(f)if(f.k>0)__msg,__mdx=f.msg,f.dx camera(0,3-f.k)pal(7,min(7,flr(5+f.k)))exec[[rectfill◆4,112,123,122,7
rectfill◆5,111,122,123,7
cprint◆__msg,__mdx,115,1
pal]]
end}rod={init=function(f)if(not storage or storage._spr~=35and storage._spr~=36)f.delete()
end,update=function(f)if(f.player_here()and held and held._spr==35)mg_init()
end}adelie={update=function(f)f.solid=true local n=f.check_pickup(36)if not f.yad and n then sfx"17"f.yad,f._spr=true,42n.init_smoke()n.delete()init_object(chiev,f.x,f.y-16,53)elseif f.yad then if(f.is_solid(0,1))f.spd.y=-2
f.spd.y=l_appr(f.spd.y,3,abs(f.spd.y)>.124and.334or.167)end end}tiles={}foreach(split([[1,player_spawn
9,refill
10,fruit
11,crumble
12,flag
24,pickup
50,pickup
35,pickup
36,pickup
37,pickup
61,house
31,chimney
39,msg
44,msg
51,chiev
52,chiev
53,chiev
56,msg
34,rod
41,adelie]],"\n"),function(f)local f,n=usplit(f)tiles[f]=n end)function init_object(f,n,e,d)local f={obj=f,_spr=d,hitbox=rectangle(usplit"0,0,8,8"),x=n,y=e,rem=zvec(),spd=zvec(),flp=vector(),freeze=0,layer=0,collideable=true,solid=false,outline=true,init=f.init or t,update=f.update or t,draw=f.draw or draw_spr,on_move=f.on_move,action=f.action}function f.left()return f.x+f.hitbox.x end function f.right()return f.left()+f.hitbox.w-1end function f.top()return f.y+f.hitbox.y end function f.bottom()return f.top()+f.hitbox.h-1end function f.hmid()return round(f.left()+f.right()>>1)end function f.vmid()return round(f.top()+f.bottom()>>1)end function f.is_flag(n,e,d)local t,o,c,i=f.left(),f.right(),f.top(),f.bottom()for n=mid(0,rw-1,(t+n)\8),mid(0,rw-1,(o+n)\8)do for e=mid(0,rh-1,(c+e)\8),mid(0,rh-1,(i+e)\8)do local r=tile_at(n,e)if d=="spike"then if(({[17]=f.spd.y>=0and i%8>=5,[18]=f.spd.y<=0and c%8<=2,[19]=f.spd.x<=0and t%8<=2,[20]=f.spd.x>=0and o%8>=5})[r])return true
elseif fget(r,d)then return n,e end end end end function f.overlaps(n,e,d)return n.right()>=f.left()+e and n.bottom()>=f.top()+d and n.left()<=f.right()+e and n.top()<=f.bottom()+d end function f.check_all(e,d,t,n)return filter(n or objects,function(n)return n.obj==e and n~=f and n.collideable and f.overlaps(n,d or 0,t or 0)end)end function f.check(...)return f.check_all(...)[1]end function f.check_pickup(n,e,d)for f in all(f.check_all(pickup,e,d))do if(f._spr==n)return f
end end function f.player_here()return f.check(player,0,0)end function f.is_solid(n,e)for d in all(filter(objects,function(f)return f.obj==pickup and f._spr==24end))do if(e>0and not f.overlaps(d,n,0)and f.overlaps(d,n,e))return true
end return e>0and not f.is_flag(n,0,2)and f.is_flag(n,e,2)or f.is_flag(n,e,0)or f.is_flag(n,e,3)or f.check(crumble,n,e)end function f.oob(n,e)return f.left()+n<0or(re&2==0or exit_lock)and f.right()+n>=8*rw or re&1==0and f.bottom()+24+e<0end function f.not_free(n,e)return f.is_solid(n,e)or f.oob(n,e)end function f.move(e,d)for n in all{"x","y"}do f.rem[n]+=n=="x"and e or d local e=flr(f.rem[n]+.5)f.rem[n]-=e if f.solid then local o=sign(e)local d=n=="x"and o or 0local t=o-d for e=1,abs(e)do if(f.on_move and f:on_move(d,t))return
if f.not_free(d,t)then f.rem[n],f.spd[n]=0,0 break else f[n]+=o if f.ride then foreach(filter(objects,function(n)return f~=n and n.rider and(f.overlaps(n,0,0)or f.overlaps(n,-d,-t-1))end),function(e)if(f.overlaps(e,-d,-t-1)and e.not_free(d,t))e.rem[n],e.spd[n]=0,0else e[n]+=o
if(e.not_free(0,0))kill_obj(e)
end)end end end else f[n]+=e end end end function f.delete()del(objects,f)end function f.init_smoke(n,e)add(smoke,{x=f.x+(n or 0)-1+rnd"2",y=f.y+(e or 0)-1+rnd"2",spd=vector(.3+rnd"0.2",-.1),flp=vector(rnd"1"<.5,rnd"1"<.5),_spr=13})end add(objects,f)f:init()return f end function kill_obj(f)if(not f)return
f.delete()if f.obj==pickup then f.init_smoke()return elseif f.obj==player then exec[[gset◆delay_restart,15]]deaths+=1end exec[[sfx◆-1
sfx◆28]]for n=0,.875,.125do add(dead_particles,{x=f.x+4,y=f.y+4,t=2,dx=sin(n)*3,dy=cos(n)*3})end end function init_g_particles()dead_particles,smoke,snowflakes,clouds,debris={},{},{},{},{}for f=0,48do add(snowflakes,{x=rnd"128",y=rnd"128",s=flr(rnd"1.25"),spd=.75+rnd"0.75",off=rnd"1",c=rnd"1"<.8and 7or 6})end for f=0,16do add(clouds,{x=rnd"128",y=rnd"48",spd=.25+rnd"0.75",w=32+rnd"32",c=rnd"1"<.5and 6or 7})end end function draw_snowflakes()local f,n,e=sin,rectfill,_cdx foreach(snowflakes,function(_ENV)x=(x+spd-e)%128y=(y+.5+.5*f(off))%128off+=.0125n(x,y,x+s,y+s,c)end)end function draw_clouds()fillp"0b1010010110100101.1"foreach(clouds,function(f)f.x+=f.spd-_cdx/4for n=0,2do rectfill(f.x-n,f.y+n,f.x+f.w+n,f.y+16-f.w*0x.3-n,f.c)end if f.x>128then f.x-=128+f.w f.y=rnd"48"elseif f.x+f.w<0then f.x+=127+f.w end end)fillp()end
function mg_update()_t=max(_t-1)_sfxcd=max(_sfxcd-1)if _state=="intro"then if(_t==0)exec[[gset◆_state,wa
gset◆_t,90]]
elseif _state=="wa"then if(_t==30)sfx"21"
if(_t<30)_mgpy=_t\2%2==0and 2or 0_mgrx,_mgry=64+rnd"4"-2,64+rnd"4"-2_mgfx=81+rnd"3"-1
if(_t==0)exec[[gset◆_state,fi
gset◆_t,0
gset◆_progress,0.5
gset◆_rod,0]]_fish,_fish_t=.5,.5
elseif _state=="fi"then if(btn"5"and _sfxcd==0)sfx"18"_sfxcd=2
_mgrx,_mgry=64-10*abs(sin(t()/2)),64_mgfx=81+rnd"3"-1_fish_t=mid(0,1,_fish_t+rnd"0.3"-.15)_fish+=.1*(_fish_t-_fish)_rod=btn"5"and min(.75,_rod+.025)or max(_rod-.015)_progress=_fish>=_rod and _fish<=_rod+.25and min(1,_progress+.01)or max(_progress-.01)if(_progress==0)exec[[gset◆_state,sadeline
gset◆_mgrx,64
gset◆_mgry,64
gset◆_len,0
gset◆_t,60
sfx◆22]]
if(_progress==1)exec[[sfx◆20
gset◆_state,ca
gset◆_t,30]]
elseif _state=="sadeline"then if(_t>48)_mgpy=_t\3%2==0and 2or 0
if(_t==30)sfx"19"
if(_t<30)_len+=.2*(1-_len)
if(_t==0)exec[[gset◆_state,wa
gset◆_len,1
gset◆_t,90]]
elseif _state=="ca"then if(_t==0)local f=init_object(pickup,0,0,36)storage,held=f,f f.delete()exec[[pmusic◆0,1000,0b11
gset◆_update,game_update
gset◆_draw,game_draw]]
end end function mg_dr_rod()line(_mgrx,_mgry,_mgrx+_len*(_mgfx-_mgrx),_mgry+_len*(_mgfy-_mgry),6)for f=28,30do line(f,127,_mgrx,_mgry,f<30and 4or 2)end end function mg_dr_player(f,n)spr(144,0+(f or 0),72+(n or 0),5,7)end function mg_draw()if(_state=="intro"and _t>15)screen_fade((_t-15)/15,7)return
exec[[cls◆7
spr◆0,0,0,16,16
rectfill◆0,64,40,127,7
rectfill◆120,120,127,127,7
mg_dr_rod
mg_dr_player◆0,_mgpy]]if(_state=="intro"and _t>0)screen_fade(1-_t/15,7)return
if _state=="fi"or _state=="ca"then _pc=_progress==0and 0or 8+min(3,6*_progress)_px=17+_progress*67_fy=32+(1-_fish)*70_rodb=31+80*(1-_rod)_rodt=31+80*(1-_rod-.25)?"❎",78,74,0
exec[[rect◆14,30,87,42,0
rect◆15,31,86,41,7
rectfill◆16,32,85,40,0
rectfill◆17,33,_px,39,_pc
rect◆100,30,113,112,0
rectfill◆102,32,111,110,0
spr◆255,103,_fy
rect◆101,_rodt,112,_rodb,9]]rect(100,_rodt-1,113,_rodb+1,10)rect(99,_rodt-2,114,_rodb+2,0)end if _state=="sadeline"and _t>30then?":(",34,80,0
end if(_state=="ca")screen_fade((_t-15)/15,7)
end
function title_init()exec[[gset◆start_game_flash
gset◆_update,title_update
gset◆_draw,title_draw
ssload◆3]]pmusic(63,1000)end function title_update()if start_game_flash then start_game_flash-=1if(start_game_flash<=-30)begin_game()
elseif btn"4"or btn"5"then exec[[gset◆start_game_flash,50
pmusic◆-1,500
sfx◆13]]end end function title_draw()pal()if start_game_flash then local f=start_game_flash>10and(30*t()%10<5and 7or 10)or(start_game_flash>5and 2or start_game_flash>0and 1or 0)if(f<10)pal_all(f)
end exec[[cls
spr◆0,0,0,16,16
print◆🅾️+❎,54,72,7
print◆maddy thorson,38,84,5
print◆noel berry,44,90,5
print◆mod by meep,42,104,6
print◆music by radiohead,28,112,1
draw_snowflakes
secret_pal]]end function mg_init()exec[[sfx◆27
pmusic◆63,1000
gset◆_t,30
gset◆_update,mg_update
gset◆_draw,mg_draw
gset◆_mgpy,2
gset◆_mgrx,64
gset◆_mgry,64
gset◆_mgfx,81
gset◆_mgfy,90
gset◆_len,1
gset◆_state,intro
gset◆_sfxcd,0
palt◆0
palt◆7,1
ssload◆2]]end
__gfx__
000000000000000000000000088888800000000000000000000000000000000000077000000770000300b0b0dd6666dd00200000000000000000000070000000
000000000888888008888880888888880888888008888800000000000888888000700700007bb700003b33006666dd6600200000007700000770070007000007
00000000888888888888888888888ff88888888888888880088888808881ff180700007007bbb37002888820666d666600400000007770700777000000000000
0000000088888ff888888ff888f1ff1888888ff8888ff8808888888888fffff8700000077bbb3bb7089888806666666600400000077777700770000000000000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f8088888ff888fffff87000000773b33bb708888980666d66d600400000077777700000700000000000
0000000008fffff008fffff0001d5d0008fffff00fffff8088fffff8081d5d80070000700733337008898880666ddd6600400000077777700000077000000000
00000000001d5d00001d5d0007000070071d5d00001d5d7008f1ff10001d5d00007007000073370002888820dd666d6d00400000070777000007077007000070
000000000070070000700070000000000000070000007000077d5d70007007000007700000077000002882000dd666d007777000000000007000000000000000
00000000000000006665666555000000000006660000000000000000000000006777777616651565222222222222222222222222000000007770000000000000
00000000000000006765676566700000000777760000000000000000000000007000777715551111444442444444424444444244000000007442222210000000
008008000000000067706770677770000000076600000000000000000000000070c77707111115160000110000000000001100000000007764422222105d0000
000880000070007007000700666000000000005500000000000000000000000070777c0761651155000110000000000000011000000006772222111176550000
000880000070007007000700550000000000066600000000000000000000000077770007111156110022000000000000000022000000777411144211115d0000
008008000677067700000000667000000007777600000000000000000000000077700c0715115511022000000000000000000220000744712221144211556700
00000000567656760000000067777000000007660000000000000000000000007000000751151115220000000000000000000022004611222267211442117760
00000000566656660000000066600000000000550000000000000000000000006777777616651655200000000000000000000002244444444444444444411111
00000000000000000000000000000000000000000000000000000000077414200000000000000000101111010000000000000000002111111121111111111120
00000000000000000000000000000000000000000000000000000000047114400000000000000000117171110000000000994400004411222222221241221120
00000444444000000000000000000000000000000077776000000000414444200000000000111100119911110000000002762220004412222222222241222120
00004444444400000000000000000000000000000c77777c00000000441414000000000001717110017771100000717744444444004422222222221421121120
00004464464400000000000000000000000000000ccc7c760300b0b021442000000000000c991c10017771100006777701ff1f20004411211221211441111120
000044466444000000000000000000000000000000c77770003b330000022000000000001177711101777110000677770feffff0002412222222222441222120
0000246446420000000000000000000000000000000c770002888880077220000000000019779111019dd9117070717700464200002422222222717422221120
00044244442440000000000000000000000000000000c00000000000777427700000000009dd9110009009006f60677600700700004412999912177421122120
004444aaaa4444000077770000000000000000000000000000000000050000500774142000000000000000000000000000000000004419121191771441111120
00aaa9a87a9aaa000777677000000000000000000000000000000000505005050471144000000000000000000000000000000000004429212191711441111120
00aaa9a88a9aaa007777777700000000000700000000000000000000050000504144442000000000000000300000000000000000004429212141111421222120
00aaa9aaaa9aaa007777767707700000007e00770000000000000000224442244414140000000000000000b00000000000000000004229222141999441121120
00aaa9aaaa9aaa007767777706600000007e07e0000000000000000066644646214420000000b00000000b300000770000000000004424212641222441111120
00aaa999999aaa007777777700777700007e07e000171700004499007772247400022000000b000003000b000777777000000000004424212141222441111120
000500055000500007776770077777600077776001119990022267204744474707722000030b003000b0b3006777d66000777600066724212141222441761120
0055005555005500007777000700000007000000010000004444444424422242777427700303303000303300ddd6666007777760667774212141222277777626
57777777777777777777777557777775577777777777777777777775766555677665556776655567666555555555556600000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777776656677766566777665667665555511515566700555505500055050005505000055050
77776677777766777777667777776677777766777777667777776677666656666666566666665666665551111155566600511151155511515551155005511550
66766676667666766676667666766676667666766676667666766676666151666661516666615166766551111555556605111111111111111111115005111150
66667666766676667666766666667666666676667666766676667666666555666665556666655566666555511115556605111111111111111111150000511500
66116611661166116611666666666667661166116611661166116666661555166615551666155516665555111115566700511111111111111111115000511150
66555555555555555555666666611666665555555555555555556666555555555555555555555555665551555555566605111111111111111111150005111500
76655515551151555155116676655166766555566655555666551166665555155511515551555556766555566655556605111111111111111111115005111150
66655555111111115555556666655566666555677665556776655566766555551111111155555567666555677665556605111111111111111111115005111150
66555551111111111515566766555667665556677766566777665667776655511111111115155667665556677766566700511111111111111111150005111500
66555111111111111155566666555666665556666666566666665666666651111155111111555666665556666666566600511111111111111111150000511150
76655111111111111555556676655566766551666661516666615566666151111155115115555166766551666661556600511111111111111111115000511150
66655551111111111115556666655566666555666665556666655566666555511111111111155566666555666665556605111111111111111111115005111500
66555511111111111115566766555667665555166615551666155667661555111111511111155516665555166615566700511111111111111111150000511500
66555151111111111555566666555666665555555555555555555666555551511111111115555555665555555555566600511111111111111111115000511150
76655555111111115555556676655566766555566655555666555566665555551111111155555556766555155155556605111111111111111111115005111150
66655555111111111551556666655566666555677665556776655566766555551111111115515567777777777777777705111111111111111111115005111150
66555511111111111155566766555667665556677766566777665667776655111111111111555667777777777777777705111111111111111111150005111500
66555551111111111555566666555666665556666666566666665666666655511111111115555666777766777777667700511111111111111111115005111500
76655151111111115515556676655566766551666661516666615566666151511111111155155166667666766676667600511111111111111111150000511500
66655555111111111555556666655566666555666665556666655566666555551111111115555566766676667666766605111111111111111111150005111150
66555551151551511555556766655667665555166615551666155567661555511515515115555516661166116611661100515551151155111511515000511550
66665555555555555555566666666666666655555555555555555666555555555555555555555555555555555555555500550005505500555055055000555050
56666666666666666666666556666665566666666666666666666665665555566655555666555556555155566655515500000000000000000000000000000000
57777777777777777777777557777775111111111111111115555567766555517665555515515567155555677665555100000000000000000000000011111111
77777777777777777777777777777777111111111111111115555667776655117766551111555667115556677766551100555055550550055500555011001111
77776677777766777777667777776677111111111111111111555666666655556666555115555666155556666666555105111511115115511155115010001111
66766676667666766676667676766676111111111111111115555166666155556661515155155166115551666661551505111111111111111111150010011111
66667666766676667666766666611666111115111151151115555566666555516665555515555566151555666665555100511111111111111111150011111101
66116611661166116611666666555566111151511515111111555516661555116615555115555516155555166615555500515111155111111151115011111111
66555555555555555555666666655666151555555555551111151555555551515555555555555555555555555555555505550555500555555505550011101111
56666666666666666666666556666665115555566655511111515551551151115155555666555515666666666666666600000000000000000000000011111111
85151515151515151547161626061616161657151515472605151515151515154726061616165715151547161616161616161616165715851525f7d5d5052505
85151515151515151585154716162606000000000000000000000000000000000000000000054726047715151515151500000000000000000000000000000000
851515151515151547262121212121212121065715472604771515158515151526f7d6e600000515471626d6d6d6d6d6f7d5d5f7d50616574726d5d6f7052506
15151515158515151515472600000000000000000000000000000000000000000000000000a42604771515158515151500000000000000000000000000000000
1515151515851515250000000000000000000006162607b71616161616165715d5e500000000054726e6000000000000c6d6f7d5d6d6d6062634e500c6069714
15151547161616161657253100000000000000000000000000000000000000000000000000360477158515151585151500000000000000000000000000000000
1515151515151547260000000000000000000000c6f7d5d5f7d5f7d6e6000616f7e600000092a42600000000000000000000c6e60000004104b5e60000410515
15851525000000000006b4310000000000000000000000000000000000000000000000a3c4047715151515151515151500000000000000000000000000000000
151515158547162600000000111111110000000000c6f7d5d6d6e60000000000e5000000b1c13600000000000000110000000000000000410525000000410585
151515250000000000003631000004140000000000000000000000000000000000c4d43704771515154716161657851500000000000000000000000000000000
15154716162644270000000004141424000000000000c5e60000000000000000e600000000000000000000000000340000000000000000410525000000410515
1515152581000000000000000000058500000000000000000000000000000093041414a6b71657854726d6d6f706165700000000000000000000000000000000
154726041414b5000000000005151525000000001100f50011000000110000000000b0000000000000001100c4d7350000000000000000410525a1b10041a416
15851567240000000000000000000657c300000000000000000000000000000477471626f7f7065725310000c6d6d6050000000000000000000000000000c000
16260775151525000000000005151525a1b100003400c5d434e40000340000000000000000000000f40034d7e50036d7e40000c3930000410626000000413504
15161616b4000000001100000000000524000000000000000000c30000000005152531c6d5d5d505253100000052000500000000000000000212c30004141414
d5d6d60657152500000041047715152500c4d4d435d4d5d635d6d4d435e7000000000000000011c4d6d73600f5000000f5000414243100000000000000413605
26000000360000000034000000000005672400000000000093000424d4e4000515253100c5f7d505253100000007b6770000000000a300c20313042405151515
e60000c6061626000000410657151525d4d6d6d636d6e6003600c6d63600000000000000000034e600002100c5e40000f5047715253100000000000000110477
00000000210000001135000000000005472600000000000004147725d5e5000657253100c6d5f7a4263100000000065700000000000414141414772505151515
00000000000000000000000005154726e6000000210000002100000021000000111111111111351111111111042400c404771515253100000000000041340515
000000000000000004b500000000000526e500000000000477151525f7e50000a426310000c6d636210000000000000500000000047715858515152505151515
0000000000000000000000000657250000000000000000000000000000000000a6270414141484141414142406b4d4f705151547263100009000000041350585
000000000000000005250000a0000005d5e600000000000515151525d5f7e4003631000000000021000000000000110500000004771515151515152505151515
00100000002200b300000000c5052500000000000000000000000000000000002607b71616161616161616a72736d5d605151525000000000000000011350657
00100000000000000626111100000005e5000000000004771585159527f7e5c30000000000000000000000000011047700000005151515151585152505151515
a1b1c10414141424e40000c4d5a426e4000000000000000000000000000000000000c6f7d6d6f7d6d6e50000c6f7e50005154726000000000000000004842406
b1c13400000000000414142411111105e50000000717b716161616260414142407b6241111111111111111111104771500100005158515151515852506571515
0000c40515151525d5d4d4d5f736d5e500000000000000000000000000000000001093f50000f50000c5e4a300c6e5b305152500000000000000000005156714
00003600000000110515156714142406e50010b304141414141414147715856724056714141414141414141414771585142407b7571515151515156724058515
d4d4f70515151525f7d5f7d5d5d5d5f7d4e400000000000000000000000000001414142400003400000414240000340475152500000000000000000005851515
00003411111111047715151585156714141414147715151515151515851515152505158515151515151515858515151515671424065715151515151525065715
37000000000000000000000000000037370000000000000000000000000000373700000000000000000000000000003737000000000000000000000000000037
37000000000000000000000000000037370000000000000000000000000000373700000000000000000000000000003737000000000000000000000000000037
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
37000000000000000000000000000037370000000000000000000000000000373700000000000000000000000000003737000000000000000000000000000037
37000000000000000000000000000037370000000000000000000000000000373700000000000000000000000000003737000000000000000000000000000037
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066000000000000000000000000000000077777777776660000000000000007000000000000007000000777777700000000000000000000000000000000
00000000000000000000000000000000000000777777776666666000000000000000000000000000000000000007777777766000007000000000000000000000
00700000000000000000000000000007777777777777700000000000000000000000000000000000000000000000077766666600000000070000000000000000
00000000000000000000007000000007777777666666600000000000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666666000000000000000000006700000000000076666677777700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000067670000000000666666667777777000006000000000000000000000000000000700000
00000000000000000000000000000000000000000000000000000000676767000000000000000777777777777777000000000000000000000000000000000000
00000070000000000000000000000000000000000000000000000006767676700000000000000777777777777777000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000067676767700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000676767677700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000767676777770000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000707676767777777000000700000000000000000000000000000000000000000000000000000000
00000000000000070000000000000000000000000000000000076767777777777700006770000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000000777777777777777770067677000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000777777777777777777676767700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007777777777777777777767677770000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077777777777777777777776767770000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000777777777777777777777777676777000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000777777777777777777777777767777700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000007777777777777777777777777776777770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077777777777777777777777777777777777000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000677777777777777777777777777777777777770000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000677777777777777777777777777777777777776000000000000000000000000000000000000000000000
00000000000000000006000000000000000000000006667777666666667777777777777777777777766600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066666776666666666777777777766666667777666660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000666666666666666666677777777766666666676666666000000000000000000000000000000000000000000
00000000000000000000000000000000000000005666666666666656666666777777666666666666666666600000000000000000000000000000000000000000
00000000000000000000000000000000000000056566666666666565666666667766666565656666666665600000000003000000000000000000000000000000
00000000000000000000000000000000000330065656663666535656535666666666665636565336663656530000030033000000000000000000000000000000
00770000000000000000000000000000000330353333633365636565636566366663656333656333653335633000030033000000000000000000000000000000
007700000000000000000000000000000033333633333336563336563336563656335633365633335633363333003300k330c0c0c00000000000000000000000
000000000000000000000000000000000003356533336533353333653333333533333563333533336333333333603330331ccc1c1c0000000000000000000000
000000000000000000000000000000300333335333365336563336533333335356335633k6533k33565336333333k3331cccccc1c00000000000000000000000
000000000000000000000000000000330033k36333353333k533k3353k656333653333633cccck353333353k3533k37cccccc3cc000000000000000000000000
000000000000000000000000000000330333k556533353k3363333333k333333533k36cc3cccc336563k5656365753ccccccc300000000000000000000000000
000000000000000000000000000000333775k5ccc3k533k5c3333ccccc637k3365ccccccccccccccccccccccc5657cccccccc333000000000000000000000000
0000000000000000000000000000033k3366ccccccccccccccccccccccc356ccccccccccccccccccccccccccccccccccccc31333000000000000000000000000
000000000000000000000000000003337cc3ccccc3ccccccccccccccccccccccccccccccccccccccccccccccccccccccc6733333000000000000000000000000
000000000000000000000000000003333333cccc33cccccccccccccccc7cccccccccccccccccccccccccccccccccccccc6331k30000000000000000000000000
000000000000000000000000000033336c33cccc33c33cc3cccccc3cccccccccccccccccccccccccccccccccccccccccc3333000000000000000000000000000
000000000000000000000000000003k33333cc33333333c3cccccc3cccccc3cccccccccccccc33cccccccccccccccc3333333000000000000000000000000000
000000000000000000000000000033k333333c3333cc33c3ccccc33cccccc3cccccccccccccc33ccccc3ccccccccccc3c6k33000000000000000000000000000
00000000000000000000000000000773333cccc333cc333333c7333377777377ccccc3ccccc33cccccc3ccccc333cc3333k03300000000000000000000000000
00000000000000000000000000000067733333333333363337773333377333k77777c3ccccc33377773333cc3c33cc3377k00000000000000000000000000000
0000000000000000000000000700003333337733k773333377777337777333777777337773733777777377773333c67336000000000000000000000000000000
070000000000000000000000000000000k30000007300k3k00000000077333007770033000003300000033000000370030000000000000000000000000000000
00000000000000000000000000077777700777777007700077077777700330770007700777770077777700777777007703077060000000000000000000000000
00000000000000000000000000077777770777777707700077077777770000777007707777777077777770777777707700077000000000000000007000000000
00000000000000000000000000000770000770007707700077077000000000777707707700077077000770007700007700077000000000000000000000000000
00000000000000000000000000000ee0000eeeeee00ee000ee0eeee0000000eeeeeee0ee000ee0eeeeee0000ee0000eeeeeee000000000000000000000000000
00000000000000000000000000000ee0000ee000ee0ee000ee0ee000000000ee0eeee0ee000ee0ee000ee000ee0000ee000ee000000000000000000000000000
00000000000000000000000000000ee0000ee000ee0eeeeeee0eeeeee00000ee00eee0eeeeeee0ee000ee000ee0000ee000ee000000000000000000000000000
00000000000000000000000000000ee0000ee000ee00eeeee00eeeeeee0000ee000ee00eeeee00ee000ee000ee0000ee000ee000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000007777700000007777700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077000770070077070770000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077070770777077707770000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077000770070077070770000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000007777700000007777700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000555055505500770050500000555050500550555005500550550000000000000000000000000000000000000000
00000000000000000000000000000000000000555050505050505050500000050050505050505050005050505000000000000000000000000000000000000000
00000000000000000000000000000000000000505055505050505055500000050055505050550055505050505000000000000000000000000000000000000000
00000000007000000000000000000000000000505050505050505000500000050050505050505000505050505000000000000000070000000000000000000000
00000000000000000000000000000000000000505050505550555055500000050050505500505055005500505000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000550005505550500000005550555055505550505000000000000000000000000000000000000000000000
00000000000000000000000070000000000000000000505050505000500000005050500050505050505000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000505050505500500000005500550055005500555000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000505050505000500000005050500050505050005000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000505055005550555000005550555050505050555000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066600660660000006660606000006660666066606660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066606060606000006060606000006660600060006060000000000000000000000000000000000000000000
00000000000000000000000000000000000000000060606060606000006600666070006060660066006660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000060606060606000006060006000006060600060006000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000060606600666000006660666000006060666066606000000000000000000000000000070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007700000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007700001110101001101170011000001110101000001110111011001110011010101110111011000000000000000000000000000000
00000000000000000000000000001110101010000100100000001010101000001010101010100100101010101000101010100000000000000000000000000000
00000000000000000000000000001010101011100100100000001100111000001100111010100100101011101100111010100000000000000000000000000000
00000000000000000000000000001010101000100100100000001010001000001010101010100100101010101000101010100000000000000000000000000000
00000000000000007000000000001010011011001110011000001110111000001010101011101110110010101110101011100000000000000000000000000000
00000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000007000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000

__gff__
000000000000000000000000020000000012020202000000000a060606020202020200000000000200000202020202020202001010100002020202020202020203030303030303030303030302020202030303030303030303030303020202020303030303030303030303030202020203030303030303030303030302020202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001460616161755152000000607551515851515151515151746161616161616161620000000000500000000000000000000000000050515158526061616161616162606200000050
000000000000000000000000000000000000000000000000000000000000000000000000000000000000004c4e0000000000000000000000000000006c7f606152000000006061616175515158515151626d6e0000006c7f5e000000000000500000000000000000000000000050515161627f5e0000000000005c5e00000050
000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c7f4e0000000000000000000000000000005c7f5d52000000000000005c606161617551516e000000000a005c5e00000000000050000000000000000000000000005051516c5d5d7f4d4e0000004c7f6e00000050
000000000000000000000000000000000000000000000000000000000000000000000000000000004f004c4042404141000000000000000000000000006c6d5d52000000000000005c5e005f00607551000000000000005c7f4e00000000006000000000000000000000000039505851006c6d5d5d5d4d4d4d7f5e0000000050
000000000000000000000000000000000000000000000000000000000000000000000000000000005c4d5d4a625051510000000000000000000000000000006c7642003c000000005c7f4d5e000050510000000014404141425e000000000040000000000000000000000000407758510000005c5d7f5d7f4041414141416a7b
000000000000000000000000000000000000000000000000000000000000000000000000000000005c707166407751580000000000000000000000000000000051766a720000004c5d5d5d7f4d4d50580000000014606175526e0000000000500000000000000011000000005051585800003a40416a71717b61616161616200
00000000000039000000000000000000000000000000000000000000000000000000000000004c404141414177746161000000000000000000000000000000005174624042004c5d7f5d5d5d6d6d505100000000000000607a461100000000500000000000007c434e00004c505151510000447b61625d5d7f6d6d6e00000000
000000000043704600000000000000000000000000000000000000000000000000000000384c7f5051515851746240410000000000000000003c3b00003a3c00746240777641414141425d6e0000505100000000000000005c5a4200001b1c6000000000000000535e00005c505151510000536d5d6d7f6d6e00000000000000
00000000404842647200000000000000000000000000000000001d1e1f00000000001b1c40414177515151515240775100000000000000004041414141416a7162707b6161616161614b5e000000505100000000000000006c5052130000144000000000000000636c4d4d4077515151000053005f005f0039003b0000000000
0000000060617a726e00000000000000000000000000000000002d2e2f00000000000000607551515151517462505151000000000000004c50517461616162405d6e00376c6d7f5d5d536e0000145058000000000000000000606213000014500000000000000012006c5d4a616161750000630b730b730b40414141421b1b1c
000000006c7f5d5e00000000000000000000000000003c00003c3d3e3f3a003c002c0000005051515151515240775151000000000000005c4a616240414141775e00000000006c6d6d630000001450510032000000000000006c6d4d4d4e00503c0100001100000000006c636d7f5d50000000000000000060755158524e0000
00000000006c5d7f4e00000039000000390000000000404141414141416a71721a1b1b1b1c60617551515852505151510000000000004c7f63404177585151516e00000000000000000000000014505141420000000000000000006c6d5d4d504142004c434e001100000000006c7f50000000000000000000606161627f4e00
003b000100005c5d5d4e00404270717171724041414177515151587461624041424e00000000436075515152505158510000000000005c5d407751585151515100013a32003b00000000000000145051515200010000003b00000000006c6d5051524d6d636d4d430000000000325c50000000000000000000000000006c6d4d
41414142434d7f5d40414177764141414141775151515151515174624041775176424d4e1b1c647250515152607551510001003b3c005c7f5051585151515151414141414142111111111111111150515876421b1b1c4042000000000000005051525e0012006c6300000000004041770000000000000000000000000001005c
51515852646b414177515151515158515151515151515151517462407751515851527f5d4d4d7f5d505151764250515141414141416a72407751515151515851515158515176414141414141414177586175524e00006062000b0b000b0b005051526e000000007300000000005058511111111111111111111111431a1b1c40
51515176425051515151515158515151515151515151515151524077585151515176425d7f5d5d5d505151515260755151515151515240775151515158515151585151515151515151515151585151514250525d4d4d40424e000000000000505152000000000012000000000050515141414141414240414141415b00000050
390000003300000000000050515174626d6e00000000000000000000000000605200000000004a6250515151764250516161616161626075515151515151515161616161616175517461616161616175616161617551515158515158526075510000006061616162606161616161617500006c7f635058746161616161617551
4200000000000000000000507461625e0000000000000000000000000000006c52000000000053407751515158525051006c6d6d6d5d7f6061616161755151510000006c7f5d6068626d6d7f5d6d5d607f6d6d6d50517461616161757642505100000000006c7f5e00000000000000500000006c407774627f6d6e0019195051
5200000000000000001b1c60627f7f6e000000000000000000000000000000005200000000006360755151515152505100000000006c6d6d6d6e006c60755151000000006c6d7f536e00006c6e005c7f5e0000005058526d6e005c60755250510000000000006c5d4e00000000000050000000006061626d6e00000000266075
5213000000000000000000006c6d6e00000000000000000000000000000000005200000000006c7f6061617551525051270132000000000000000000005058510001000000005c530034000000006c6d6e0018004a61620000005c7f50525051000000003c3b005c7f4e3900000000501a1b0000001900000000000000001450
5213000000000000000000000000000000000000000000000000000000000000520000000000005c7f6e0060614b5051414219191919191919191919195058514142000000006c5300000000000000000000406a666d6e0000006c5d4a625051000b0b40416a7240416a72000000005000000000001900000000000000001450
5213000000000000000000000000000000000000000000000000000000000000521919000000005c5e000000005350585152191919191919191919191950585851520000000000634e00000000000000000060626e0000000000006c63407758000000606162707b75525e0000003c5042003a00001900000000000000001450
62130000000000000000000000000000000000000000000000000000000000005219191900004c7f5e000000005350515152191919191919191919191950515151520000000000436e0000000000000000000000000000000043000040786161000000000000001450525e000014407759724041414213000000000000001460
4200000000000000000000000000000000000000000000000000000000004c4d764219193b4c7f5d7f4e000000635051515219191919191919191919196075515152000000000053000000000000000000000000000014406a66191960626e00000000000000001450527f4e0014505152707b75515213001919000000001440
520000000000000000000000000000000000000009000000000000000019404151764142404141414142130000407751617a7219191919191919191919196061616200000000006300000000000000000000000000001450524300005c6e0000000000000000001450526d7f4e14607562191960616213001919000000001450
5200000000000000000000000000000000000000000000000000000000407751616161626075515151521300005051515d7f6e0000000000000000000000000041421300000000000000000000000000000000000000144a6253004c6e00000000000000000000145052006c6d4d5d60000000005c6e00000000000000001450
520000000000000000000000000000000000000000000000000000004c5051515d7f6d6d6d60616161621300005051515d5e00000000000000000000003c0000515213000000000000000000000000000000000000000053405b4d6e00404141000000000000001450597213006c7f400000007c5e0000000000000000001450
520000000000000000000000000000090000000000000000000000005c5051517f6e00000000191900000000005051517f6e000a000000000000000000404141515213000000000000000000000000000000000000004c5350526e000060755100000000000000146062000000005c50000000005f0000000000001919001450
520000000000000000000000000000000000000000000000000000005c5051515e010032390019193a3c0000005051515e00000000000000000000004c505158515213000000000000000000000000000000000000005c53604b13000014505100010039000000001212000000006c500001004c5e3200000000191919001450
52000000004c4e004c4e00000000000000000000000000000000004c5d60616171716b414141414141421111115051515e00000000000000000000005c5051515152130000000000000000000000000000010032004c5d5a42531300001460611a1b1c430000000000000000003a3b501a1b1c70714200000000000000001450
5200013b4c7f5d4d7f5d4e000000390000000000000000000000006c5d404141414250515151515151764141417758515e000000000000000000004c7f5058515152130000000000000000000000191941414141414141775253130000001440000a00534e000000000000001c40417700000019195300000000000000001450
521a1b404141414141414141414240420000000000000000000000005c505151515250515151515151515151585151515e000000000000000000005c5d5051515152130000000000000000001b1c706b5151515151515151525313000000145000004c535e00000000000000005051510000001919534e000000000000001450
__sfx__
920500000c17330670306613065130641306313062500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d060002183571f357183001f30000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000641008410094100b410224302a4403c6403b6403b6403964036640326402d6402864024630216301d6301a63016620116200e6200b61007610056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000a00002e06112061120012700127001240011d001260012a0011c00119001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
0010002021610206101e6101b610196101561012610116100f6100e6100d6100c6100c6100c6100c6100d6100e6100f610106101161013610156101661017610196101b6101d6101e61020610216102261022610
000400002f45032450314502e4502f45030450000000000001400264002f45032450314502e4502f4503045030400304000000000000000000000000000000000000000000000000000000000000000000000000
9006000037635316152e605376052e605376052e60537605226052b605226052b6051d605246051d605246051f605276051f605276051f6052760529605306052960530605296053060529605306052960530605
0001000036270342702e2702a270243601d360113500a3400432001300012001d1001010003100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001000001b54020550245502c5602c5002c5000050032500355000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00050000212731e273132730a25300223012033b203282033f2032f203282031d2031020303203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203
010300000977009770097700977008760077500673005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
0006000021670176401b6001960000600356003560035600356003560000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000200000e6710e6710e6710c67106661006410a601286013f6012f601286011d6011060103601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
000c000032575305753b505005053b50500505005053350533505335053350533505335053f5053f5050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
071000002b1552b1052b1552b155291552b1502b1402b1251f1051e1051c1051e1051e1051e1051e105211052110521105211051a1051a1051a1051a1050e1050e1050e1050e1050010500105001050010500105
011000002a3542935426354203541f354273542b3542f3542f355013053f3042f3043f3042f3043f3040030400304003040030400304003040030400304003040030400304003040030400304003040030400304
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0102000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000713207132071320713207132071350713207135071320713507132071353761037625020320203507132071320713207132071320713507132071350713207135071320713537610376250203202035
011000000e700137000e7400e740177401774013740137400e7400e740177401774013740137400e7400e740187401874013740137400e7400e740177401774013740137400e7400e74017740177401374013740
011000000b1320b1320b1320b1320b1320b1350b1320b1350b1320b1350b1320b1353b6103b62506032060350b1320b1320b1320b1320b1320b1350b1320b1350b1320b1350b1320b1353b6103b6250603206035
011000000e7000e70012740127401b7401b740177401774012740127401b7401b740177401774012740127401c7401c740177401774012740127401b7401b740177401774012740127401b7401b7401774017740
011000000013200132001320013200132001350013200135001320013500132001353061030625070320703500132001320013200132001320013500132001350013200135001320013530610306250703207035
01100000137001370013740137401c7401c740187401874013740137401c7401c740187401874013740137401d7401d740187401874013740137401c7401c740187401874013740137401c7401c7401874018740
01100000177001770013740137401b7401b740187401874013740137401b7401b740187401874013740137401d7401d740187401874013740137401b7401b740187401874013740137401b7401b7401874018740
01100000177001770013740137401b7401b740187401874013740137401b7401b740187401874013740137401d7401d740187401874013740137401a0401a04021045210451f0401f0401e0401e0401f0401f040
011000001f0401f0450000000000177401774013740137400e7400e740177401774013740137400e7400e740187401874013740137400e7400e7401a0451a045210402104521040210451f0401f0401e0401e040
011000001e0401e04000000000001b7401b740177401774012740127401b7401b740177401774012740127401c7401c740177401774012740127401b0401b040210402104521040210451e0401e0401f0401f040
011000001f0401f0401c0401c0401c0401c040187401874013740137401c7401c740187401874013740137401d7401d740187401874013740137401a0451a04521040210401f0401f0401e0401e0401f0401f040
011000001f0401f0401b0401b0401b0401b040187401874013740137401b7401b740187401874013740137401d7401d740187401874013740137401a0401a040210402104521040210451e0401e0401f0401f040
011000001f0401f0401a7401a740177401774013740137400e7400e740177401774013740137400e7400e740187401874013740137401a0401a0451a0401a04521040210401f0401f0401e0401e0451e0401e040
011000001e0401e0401e0401e0401b7401b740177401774012740127401b7401b740177401774012740127401c7401c740177401774021040210452104021045210402104521040210451f0401f0402304023040
0110000023040230401f7401f7401c7401c740187401874013740137401c7401c740187401874013740137401d7401d740187401874013740137401f0401f0451f0401f04521040210401f0401f0402204022040
0110000000132001320013200132001320013500132001350013200135001320013530610306250703207035001320013200132001320013200135070421f0451f0401f0451f0401f0401f0401f0451a0401a040
0110000022040220401f7401f7401b7401b740187401874013740137401b7401b7401874018740137401374018740187401874018740187401874000000180451804018045230402304023040230452304023040
011000002304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023045000001f0401f045230402304023040230401e0401e040
011000001a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a045000001a0401a0451a0401a0401a0401a0401b0401b040
01100000071320713507132071320e1320e13207132071350713207135071320713232610326250713207135071320713507132071320e1320e13207132071350713207135071320713232610326250713207132
011000001e0401e0451e0401e0401e0401e0401c0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0451b00023045230402404024040230402304523045210402304023040
011000001b0401b0451b0401b0401b0401b0400b1020b1050b1020b1050b1020b10217142171420b1020b1050b1020b1050b1020b10217142171420b1020b1051b0401b0400b1020b10217142171421c0401c040
011000000b1320b1350b1320b13212132121320b1320b1350b1320b1350b1320b13236610366250b1320b1350b1320b1350b1320b13212132121320b1320b1350b1320b1350b1320b13236610366250b1320b135
011000002304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023045000001f0401f04021040210401f0401f0402204022040
011000001c0401c0401f0401f0401c0401c0401f0401f0401c0401c0401f0401f0401c0401c0401f0401f0401c0401c0401f0401f0401c0401c0401c04500000000000000000000000000c1420c1421b0401b040
011000000c1320c1350c1320c13213132131320c1320c1350c1320c1350c1320c13237610376250c1320c1350c1320c1350c1320c13213132131320c1320c1350c1320c1350c1320c13237610376250c1320c135
0110000022040220401f0401f0401f0401f0401f0401f0401f0401f0401f0401f0401f0401f0401f045000001d0421d0421d0421d0421d0421d0421d0421d0421d0421d0421d0421d0421d0421d0421d04500000
011000001b0401b0451b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0450000018042180421804218042180421804218042180421804218042180421804218042180421804500000
011000000c1320c1350c1320c13213132131320c1320c1350c1320c1350c1320c13237610376250c1320c13530610306250013100132306103062500131001323061030625001310013230610306250013100132
000b00001a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051b9001b9051b9001b9051b9001b9051b9001b9051b9001b9051b9001b9051a9001a9051a9001a9050c605152000c6050c605
000b00001a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051a9001a9051f9001f9051e9001e9051b9001b9051b9001b9051e9001e9051e9001e9051a9001a9051a9001a9050c605152000c6050c605
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00400000302053020530205332052b20530205302053020530205302053020530205302053020530205302052b2052b2052b20527205292052b2052b2052b2052b2052b2052b2052b2052b2052b2052b2052b205
__music__
01 1e1f4344
00 20214344
00 22234344
00 22244344
00 1e1f4344
00 20214344
00 22234344
00 22254344
00 1e264344
00 20274344
00 22284344
00 22294344
00 1e2a4344
00 202b4344
00 222c4344
00 2d2e4344
00 2f303144
00 32333444
00 35363744
02 38393a44
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
01 5c4d5d5f
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
01 5c4d5d5f
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 5f4e6062
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 10424344

