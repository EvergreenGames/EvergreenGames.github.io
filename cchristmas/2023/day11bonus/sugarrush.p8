pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- sugar rush
-- by ruby+meep+taco+gonen
-- based on celeste classic
-- by maddy thorson and noel berry

-- entry point

function _init()
 exec[[poke◆0x5f2e,1
init_cam
init_g_particles
title_init]]
end

-- set up secret palette
function secret_pal()
 pal(10,130,1)
end


-->8
-- helper functions

-- data structures

function vector(x,y)
 return {x=x,y=y}
end

function zvec()
 return vector(0,0)
end

function rectangle(x,y,w,h)
 return {x=x,y=y,w=w,h=h}
end

-- camera stuff

function init_cam()
 exec[[gset◆_cx,0
gset◆_cy,0
gset◆_cdx,0
gset◆_cdy,0
gset◆_cg,0.1
gset◆cam_x,0
gset◆cam_y,0]]
end

function move_cam(ins,g)
 if (cam_lock) return
 local k=g or _cg
 _cdx,_cdy=
  e_appr_delta(_cx,mid(0,ins.hmid()-63,8*rw-128),k),
  e_appr_delta(_cy,mid(0,ins.vmid()-63,8*rh-128),k)
 _cx+=_cdx
 _cy+=_cdy
 cam_x,cam_y=round(_cx),round(_cy)
end

function cam_draw()
 exec[[camera◆cam_x,cam_y]]
end

-- draw from map relative to camera
function cmap(flag)
 map(rx+cam_x\8,ry+cam_y\8,cam_x\8*8,cam_y\8*8,16+ceil(cam_x%8),16+ceil(cam_y%8),flag)
end

-- screen fader
function screen_fade(t,c)
 if t then
  fillp(
   t<=0 and 0b0000000000000000.1 or
   t<0.33333 and 0b0000101000000101.1 or
   t<0.66666 and 0b0101101001011010.1 or
   t<1 and 0b1111101011110101.1 or
   0b1111111111111111.1)
  exec[[rectfill◆0,0,127,127,7
fillp]]
 end
end

-- l2 distance
function l2dist(x1,y1,x2,y2)
 local dx,dy=
  (x1-x2)/1024,(y1-y2)/1024
 return 1024*sqrt(dx*dx+dy*dy)
end

-- linear approach
function l_appr(val,target,amt)
 return val>target and max(val-amt,target) or min(val+amt,target)
end

-- exponential approach (delta)
function e_appr_delta(val,target,gain)
 return gain*(target-val)
end

-- sgn but with zero
function sign(x)
 return x==0 and 0 or sgn(x)
end

-- round
function round(x)
 return flr(x+0.5)
end

-- get tile relative to room
function tile_at(tx,ty,oob)
 if tx>=0 and tx<rw and ty>=0 and ty<rh then
  return mget(rx+tx,ry+ty)
 end
 return oob
end

-- set tile relative to room
function tile_set(tx,ty,tile)
 if tx>=0 and tx<rw and ty>=0 and ty<rh then
  mset(rx+tx,ry+ty,tile)
 end
end

-- 0-pads number to be 2 chars
function two_digit_str(x)
 return x<10 and "0"..x or x
end

-- draw in-game time
function draw_time(x,y)
 rectfill(x,y,x+44,y+6,0)
 ?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds_f\30).."."..two_digit_str(round(seconds_f%30*100/30)),x+1,y+1,7
end

-- rotate sprite
function spr_r(n,x,y,a)
 local sx,sy,ca,sa=n%16*8,n\16*8,cos(a),sin(a)
 local dx,dy,x0,y0=ca,sa,4+3.5*(sa-ca),4-3.5*(sa+ca)
 for _x=0,7 do
  local srcx,srcy=x0,y0
  for _y=0,7 do
   if (srcx|srcy)&-8==0 then
    local c=sget(sx+srcx,sy+srcy)
    if c~=0 then
     pset(x+_x,y+_y,c) end
    end
    srcx,srcy=srcx-dy,srcy+dx
   end
  x0,y0=x0+dx,y0+dy
 end
end

-- big rotate
function spr_rr(n,x,y,a)
  local sx,sy,ca,sa=n%16*8,n\16*8,cos(a),sin(a)
  local dx,dy,x0,y0=ca,sa,31.5*(sa-ca)+32,-31.5*(ca+sa)+32
  for _x=0,63 do
    local srcx,srcy=x0,y0
    for _y=0,63 do
      if band(bor(srcx,srcy),-64)==0 then
        local c=sget(sx+srcx,sy+srcy)
        if c!=0 then
          pset(x+_x,y+_y,c)
        end
      end
      srcx,srcy=srcx-dy,srcy+dx
    end
    x0,y0=x0+dx,y0+dy
  end
end

-- table filter (not-in-place)
function filter(tbl,f)
 local filtered={}
 foreach(tbl,function(x)
  if f(x) then add(filtered,x) end
 end)
 return filtered
end

-- table sort by idx k (not-in-place)
function sort(tbl,k)
 local sorted={}
 foreach(tbl,function(x)
  for i=1,#sorted do
   if x[k]<=sorted[i][k] then
    return add(sorted,x,i)
   end
  end
  add(sorted,x)
 end)
 return sorted
end

-- get all instances of obj
function get_objs(obj)
 return filter(objects,function(ins) return ins.obj==obj end)
end

-- get first instance of obj
function get_obj(obj)
 return get_objs(obj)[1]
end

-- get player (/player spawn)
function get_player(and_spawn)
 return get_obj(player) or and_spawn and get_obj(player_spawn)
end

-- set whole palette
function pal_all(c)
 for i=1,15 do
  pal(i,c)
 end
end

-- obj sprite drawer
function draw_spr(o,dx,dy)
 spr(o._spr,o.x+(dx or 0),o.y+(dy or 0),1,1,o.flp.x,o.flp.y)
end

-- music handler
function pmusic(id,fade,mask)
 if curr_music~=id then
  curr_music=id
  music(id,fade,mask)
 end
end

-- outliner
function outline(fn)
 exec[[pal_all◆0]]
 pal=stat
 foreach(split"-1 0,1 0,0 -1,0 1",function(d)
  local dx,dy=usplit(d," ")
  local dx,dy=usplit(d," ")
  camera(cam_x+dx,cam_y+dy)
  fn()
 end)
 pal=_pal
 exec[[pal
cam_draw]]
end

-- obj drawer
function draw_obj(o)
 o:draw()
end

-- glow effect
function glow(o)
 for i=0,0.875,0.125 do
  local a=i+t()%2/2
  pset(o.hmid()+5.5*cos(a),o.vmid()+5.5*sin(a),7)
 end
end

-- useful copies of stuff
_pal=pal
_btn=btn

-- centeredprint
function cprint(t,y,c,dx)
 ?t,64-2*#t+(dx or 0),y,c
end

-- set global var
function gset(k,v)
 _ENV[k]=_ENV[v] or v
end

-- split, access _ENV, and unpack
function usplit(str,d,a)
 if str then
  local tbl=split(str,d)
  for k,v in pairs(tbl) do
   tbl[k]=not a and _ENV[v] or v
  end
  return unpack(tbl)
 end
end

-- execute list of fns
function exec(fns)
 foreach(split(fns,"\n"),function(ln)
  local fn,params=usplit(ln,"◆",true)
  _ENV[fn](usplit(params,",",fn=="gset"))
 end)
end

-- load sprite sheet from rle-hex
function load_gfx(i,gfx)
 local idx=0
 for i=1,#gfx,2 do
  for j=1,("0x"..gfx[i])+1 do
   sset(idx%128,idx\128,"0x"..gfx[i+1])
   idx+=1
  end
 end
 save_ss(i)
 reload()
end

function save_ss(i)
 memcpy(0x8000+0x2000*i,0,0x2000)
end

function ssload(i)
 memcpy(0,0x8000+0x2000*i,0x2000)
end

exec[[save_ss◆0
load_gfx◆1,f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7770ef7f7f7f7f7f7f7d71ef7f7f7f7f7f7f7c72e00f7f7f7f7f7f7f7a73e00f7f7575ef7f7f7f7e73e00f7f727bef7f7f7f7b71e000e00f7f707eef7f7f7f7972e000e10f7f79e004ef7f7f7f7875e10f7c7fe2ef7f7f7f7775e10f7b7fe003ef7f7f7f7573e001e20f7a7fe400ef7f7f7f7477e10f7979e000ea0f7f7f7f7477e10f797de80f7f7f7f7473e002e20f777fe000e60f7f7f7f7373e003e20f767fe000e70f7f7f7f7278e20f757de000ea0f7f7f7f7174e003e30f747de000e000e80f7f7f7f717ae20f7379ef020f7f7f7f707ae30f727dee0f7f7f7f7075e003e30f727fec0f7f7f7570e975e003e40f717fe1eb0f7f7f7371e975e004e30f707fe4e90f7f7f7372e875e004e40f7fe3e000e80f7f7f7273e876e004e30f7fe0e000e100e80f7f7f7272e00777e004e40e7fe0e001e000e80f7f7f7272e00777e004e40d7fe0e000e600e40f7f7f7173e10678e004e40c7fe000e000e900e00f7f7f7173e10678e004e50b7de000e000ec0f7f7f7272e20678e005e50a7de000e000eb0f7f7f7373e10679e004e400ea79ef030f7f7f7373e10679e005e50978e004ee0f7f7f7372e20679e005e400e0087fe0ec0f7f7f7372e000e0067ae006e4087fe2eb0f7f7f7172e4047be005e400e0077fe0e000e000e90f7f7170e20b72e200e0047ce006e300e0067ee000ed0f7f7070e00170e00a71e001e2047ce006e400e57def020f7e70e00270e00a70e102e1047de007e4047def020f7d70e00f71e002e200e37fe5e000e200e0037bef040f7d70e00f75e000e1037ee008e3037bef040f7d70ef7070e002e4037fe8e200e00279ef0000e50f7c70ef7073e300e0037feae20279ef070f7c70ef73e100e300e27febe100e178ef080f7c70ef73e003e2027fe7e000e001e100e079ef070f7c70ef72e102e3027fe4e000e100e100e200e007e404ee0f7c70ef72e003e000e1017fe5e000e600e000e007e306ed0f7c70e00e76e100e100e07fe1ec00e206e403e400eb0f7b70e00d72e002e6007fe000ed00e206e205ef000f7c700d76e300e1007cef0200e205e303e700e90f7c70e00c71e002e70cef0706e203ef020f7c70e00c71e002e101e409ef0a04e302e900e80f7d70ec75e101e407e507ee05e203ef020f7e700a71e002e102e406e30cec04e302ef030f7e70ea75e102e306e208e000e000e000e000ea05e202ef040f7e700975e101e405e206e900eb03e302e102ef0f7e70e974e103e205e105ef0904e301e001ef010f7e70e00775e102e205e104ef0200e703e400e002ef010f7470e000e100e470e774e202e204e104e600ef0504e203ef020f7171e000e600e072e674e102e204e104e208ef0203e303ef020f7070e001e000e703e574e103e103e103e207e000e000ef0104e301e100ef000f74eb01e475e102e104e102e106ef0803e401e001ef000d78ea00e474e202e103e103e008ef0804e201e100ef010c76ed00e374e102e203e00fe0ef0503e401ef040b78ec00e275e102e103e10de020e020ef0503e000e201e100ef000b77ee00e175e102e10fe2e020e020e020e02f0204e000e203e200ed0a78ee00e174e202e00fe0ea2f0302e009ef0a76ef010174e102e10ded20ef0000e00fe0ec0978ef0006e102e10cef202f00e00fe1eb0975ef0305e202e00bef222f000fe000e000ea0976ef0205e201e00be922e72e0fe2e000e000e90774ef0505e101e00be728e42d0fe1ef0578ef0304e20ee529e020e42c0fe2e000ec0376e000ef0603e30ce528e120e52b0fe1e000ee0277e000ef0603e30be527eb290fe3e000ed007027e000ef0702e30ce427ec280fe2e000ef0220e025e000ef0601e40be526e520e7270fe3e000ef0324e001e000e100e000e101e001e800e4002be426e620e7270fe0e000ef02022fe4e300e300e000e4002ae526e52207250fe2e000ef03012be601e600e6012ae426e52100e008240fe0ef070128e105e500e001e80129e526e420002000e008240fe1e000ef05022ae204ed012ae525e4220020e009230ee000ef0800200ae004e600e80328e525e2200020002000e208220fe0e000ef0700200125e000e001e600e000e90229e526e220022001e00a210ee000ef0d04e000ef060527e525e821e10a200fe000ef0d02ef09022ae525e6200021e10b2ce000ef0d00e005ef0100230420e027e525e1200521e10b2ce000e000ef0d06e000ec0123032ae625e722e20a2be000e000ef0f04e220e800e2230623e005e425e520e020e5092ce000e000ef0e03e223e501e920e026e002e001e325e520e00021e10020e00928e000e100ef0f0004e025e301ea27e102e001e00225e520e00020e20020e008200be000ef0f0003e025e02300e929e102e100e000e125e421e00020e20020e00927e000ef0f0409e12200e820e127e004e001e100e223e420e10020e1002000e1082be000ef0f0002e025e120e10821e026e005e101e100e00024e32301e60420e22004e000ef0f03012008e220e10220e020e327e005e102e100e00321e42000e001e50a28e000ef0f002009e121e103e22fe0e202e100e00220e020e520e001e300e620e323e000ef08022a0027e122e104e220e025e004e203e200e00b20e000e000e30b2002e002e101e200ee0328002007e122e102e22fe103e300e10a2001e000e30620e42ee001eb0526002106e023e102e320e025e003e203e70a25e000e720e527e300ee0824002105e024e101e327e004e103e400e20b20e609200228ef020a2406e024e101e320e025e002e203e90620e320e100e30920032000e000e000e201ef0c2205e025e101e22be203e500e30620e0002100e002e301200220e120042100e200ef010f2004e026e100e0200120e025e002e103e400e60420e1012001e400e00020e00520052f050f2223e027e100e0200127e001e103ec042000e300e000e000e200e100e10420072f010f242ce100210020e028e102e600e80322002000e000e600210120e221082c0f272ce2022ae101e600e70420002301e500e822082b0f282fe1e426e100e500eb0320e20021e6012105210a270f2a2fe1e420e120e020e021e300eb0626e000e000e2002000e000e12000220b260420002000200b200120e028e008e720e020e021ef0000200321e101e000e200e100e000e104210c2402200120002000200920002ce105ee20e1240224002001200320e30020eb012000210d2400200020002001200a210de206ed20e12200e2200022002100200320e301eb03210e20e10320002000200021002006200ce403ef2322032000210020022003230020e200e8012000210e20e1032001200020002007210ce404e020ef2020e106200020002000200420e00120e001e100e603220d20e108200021002004200ce501e020ef2320e1042000200020002000200420e100e001e300e40220002100ed20e1052000200020002000200420002ae603e020ec21e00120e10a2000e10321e000e000eb022100e10c20e107200020002000200020032005e000e020e602ef20e001e100e10a2000e10221e001e000e700e2002300e10c20e1052000200020002000200020032103e100e020e504e020e020e22000200321e001e40b20e10220e200e000ec00210020e10c20e107200020002000200020042102e10022e203e020e722e1002000e002e40a21e10220e200e000ec002200e200200920e10620012000200020032001260023e004e020e623e201e002e100e2082001e20120e200ef0101e5062100e20021e00120032000200020052504e001e020e020e723e201e002e100e30120e0022100e3002f0701e60420e101e101e103200020002004200020002504e003e020e022e224e102e002e001e400e3002002ef0a02e7012002e100e200e3052000240220002304e001e020e123e104e102e101e101e401e400ef0c01ec01e100e200e301200020002000240220002302e000e20020e024e203e102e002e002e500ef0e00e200ed01e001e803200027012404e305e500e103e002e002ef0d00e000e000e600ec01e101e900200020002e01e001e405e60ce601ed0fe0ee02e002eb002600e000e400e000e002ef02e009e701e80ce324e001e600e301e102ef0401e603ee03e00be60fee2fe1e103e901ef0101ec07e00fe9ef2e2ae001e001ea01ef0004e30fe0ef2f2f2927e001e104e800e400e100e000e000e000e
load_gfx◆2,f080d1f0f0f08077f077f040f141f0f0f05077f077f020f1012751f0f0f02077f077f0003107e15731f0f0f00077f077e03137d17731f0f0e077f077c03167c19721f0f0d077f077b02197c19721f0f0c077f077a021b7b1b721f0f0a077f0779011e7a1b731f0f0f010f9f00011f7b1a741f0f0f000f9f011f717a1a751f0f0f0f9e011f73791a761f0f0e0f9d011f75781a761f0f0e0f9c041f73781a771f0f0d0f9c091f7719791f0f0c0f9b0d1c7719791f0f0c0f9b0f1a77197a1f0f0f0f060f121976187b1f0f0f0f060f131876187c1f0f0f0f040f151776177d1f0f0f0f040f161675187e1f0f0f0f020f181575177f1f0f0f0f020f191475177c11701f0f0f0f020f1a1374177c12711f0f0f0f010916791374167c13711f0f0f0f00061e761273167c14711f0f0f0f00031f73741272167c16701f0f0f0f00011f77731172147d17701f0f0f0f00011f78721171147c19711f0f0f0f011f7a711070137d1a711f0f0f0f011f7b701070117d1c711f0f0f0f011f7079117e1f711f0f0f0f011d7d10711f7c711f0f0f0f011b7d117110701f7b711f0f0f0f01197d137011711f7a711f0f0f0f01177d147111731f78711f0f0f0f01167c157212741f74721f0f0f0f0001157c167212761f70741f0f0f0f0001147c167313771b771f0f0f0f0101127c1773147f1a1f0f0f0f0101117c1774147f1a1f0f0f0f0101107d1774157f181f0f0f0f030e1775167f171f0f0f0f030d1875177f161f0f0f0f030d1876177f141f0f0f0f050b1976187f131f0f0f0f050b1877197f111f0f0f0f070a18771b7f1f0f0f0f070919781d7b1f0f0f0f090819781f70771f0f0f0f0b0719791f74721f0f0f0f0c0619791f74711f0f0f0f0d061a791f72711f0f0f0f0f041b7a1f70711f0f0f0f0f01031b7a1f711f0f0f0f0f03021b7b1c721f0f0f0f0f05031a7b1a721f0f0f0f0f0802197c17731f0f0f0f0f0a03177d15721f0f0f0f0f0e03167d12731f0f0f0f0f0f0104137f121f0f0f0f0f0f0506107f1f0f0f0f0f0f0a0f111f0f0f0f0f0f0f02071f0f0f0f0f0f0f0300100c1f0f0f000c10001f0f0d061070107010781f0f0b0418771f0f0602107019791f0f07041e741f0f03021d7c1f0f00091f751f0e021f7f1f0b0b1f761f0b021f727e1f0b0c1e771f09051f707a12721f080f1d771f07061f717a12711f060f121c791f040a1e7915711f030f131c7a1f020c1d7916711f0101107f121b7b1f000e1c7a16711f02137f1b7c1e0f111b7817721d02177d197a11711c0f121b7819711c01197c1a7a11701c0f131a7819711b011d7a197912711a0f1618781a7119011f7919781471180f1719771b7018021f717719791470180110701071107f18771c7116021f73761879167115011b7b17771b7315011f74761878177115011e7817771b7315001f76761778187015001f717716761b7513021f76751679187014011f717716761b7513011f787416781a7013011f747514761c76120016731e7416771b7012011f757514761a78110f101070187415771c7111011f777314751b78110f13187215781d7011011f777313751a7a110f16157313781d7110011f797213741b7a100f18147213781e741f7a7112741a7c110f18137213761f74187c157112721b7f1f1a127112761f76157f10147012711c7d100f1c117012751f7077127f16127010711a7f1f121576117010731f7178127f181e7f1f121b70107012701f747f1f14107010711470107f1f131f72721f727f1f1971107f1f171f72741f707f1e1a71147f1613771f727214731a7f1e1b711170157f1114781f7073167f1f1b1b7112711779107017771f751271137f1f171b731272187011701d7010041e761371147f18100c1b7312721f7a7010021f761373147f1711091b7413741f787010011e771571167f1611091a7514731f777111011c771573177f1411071b7515741f767111011b7816721a7f1012071b7515751f757111011a7915741b7a117211061b7615761f737113001a7816741f797013051a7716771f71711301197717751f777014051a7716791f701500187817751f767214021b78177b1b711501167917761f757115021b77187d1170147010711600167918771f737017011b78187f161801157918781f717019011a77197f161901137919791f7119011a78187f151b001379197a1e711a0119781a7f131b011279197b1c711c0117791a7f121d01107a1a7c19711d0217781c7f1f0011791a7f15721f01157a1c7e1f000b1b7f1210721f010114791f7a1f020b1b7f151f020214791e791f040a1c7f121f0601127a1f71761f05091d7f101f0802117a1f71721f0a071d7f1f0b01107a1f71721f0b071e7b1f0f0c1e721f0f00041f791f0f000c197010721f0f04031f70761f0f050916751f0f07001003127018751f0f090f121f0f0c00100f101f0f0f020610001f0f0f08021f0e0
load_gfx◆3,f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0001ef0f0f0f0f0f0f0b0170ef0f0f0f0f0f0f0b0170ef0f0f0f0f0f0f0a00e171ef0f0f0f0f0f0f0900e270ef0f0f0f0f0f0f0900e272ef0f0f0f0f0f0f0701e173ef0f0f0f0f0f0f0601e274ea05ef0f0f0f0f0f0301e375e80373ef0f0f0f0f0f0201e276e70474ef0f0f0f0f0f010be600e376ef0f0f0f0f080070e505e52501e178ef0f0f0f0f070171e403e126e40cef0f0f0f0f060170e020e406e372e201e525ef0f0f0f0f060070e020e020e204e771e20125e123ef0f0f0f0f060070e020e020e202e476e201e175e022ef0f0f0f0f0600e022e02202e272e52100e376e021ef0f0f0f0f0500e023e020e105e22470e100e278e020ef0f0f0f0f05002074e02103e129700def0f0f0f0f06002071e022e201e02a71e125e222e3041f0f0f0f0d0170e020e021e3002876e023e022e021e3041f0f0f0f0d0071e021e021e2067ae022e023e020e4031f0f0f0f0c0171e021e021e10fe3e021e024e02013031f0f0f0f0c0170e022e021e004e727e021e025e212011f0f0f0f0c0171e022e021e00427e125e021e022e021e3110014011f0f0f0f060071e024e025dae025e021e021e121e21420031f0f0f0f0602e023e8d9e025e021e021e121e204241f0f0f0f0601e021e124d351d9e024e022e020e020e021e5051f0f0f0f050120e020e024d153d051d8e028e022e021e7031f0f0f0f050424d058d325e027e022e021e2011f0f0f0f0c0225d05ad2e024e028e120e022e0021f0f0f0f0b012fd3d022e02fe023e41f0f0f0f08035cd253d023e02fe3e61f0f0f0f0501d15cd156d3e026e626e41f0f0f0f0507d070e075d157d023e024e02174e025ef0f0f0f0a05d171e273d059d3e023e05275e025e202df0f0f0f0206d071e171e3d059d023e021e050e177e025e004df0f0f0f0105d071e270e171d154d054d022e020e150e078e025e5df0f0f0f0105d1e271e171d154d055d4215ae222e026df0f0f0f06d0e271e271d253d059d25ae527df0f0f0f07d071e171e3d251d151d058d05ae25128df0f0f0e08d1e171e073d552d059dae0d359df0f0f0d0ad071e6d353d059daeedf0f0f0c0bd1ffd05ad0f6e0ffdf0f0f0c0bd1ffd05ad070f070f070f070f07fd0df0f0f0a0bd051fed05cd070f070f070f0715fdf0f0f0a0ad3f05fdcd4f35fdf0f0f080ad6f05fdbd2f55edf0f0f070bd6f35fd7d052f65edf0f0f050ad15ff755d552f656f156df0f0f0301d4f55ff5f059f352f45df152df0f0f000fffffffffff0f0e0ffffffffff1ff0f0f01f401f102f101f402f401f504f501f102f101f401f102f102ff0f0f0304f101f201f104f204f105f405f101f201f104f101f201ff0f0f0506f001f201f006f006f006f306f001f201f006f001f201ff0f0f0501f501f201f001f201f001f201f001f201f301f201f001f201f001f501f201ff0f0f050640014201400145064005440541014201400640064f0f0f0b004001420140014102400142014001420143014201400142014600400142014f0f0f050640064003400140014201400142014301420140064006400142014f0f0f06044204420540014201400142014301420141044204410142014f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a0]]

-->8
-- game init/update/draw

function game_init()
 exec[[
gset◆ticking,1
gset◆seconds_f,0
gset◆minutes,0
gset◆deaths,0
gset◆fruits,0
gset◆delay_restart,0
gset◆_update,game_update
gset◆_draw,game_draw
load_room◆1]]
end

function game_update()
 -- in-game time
 if ticking then
  seconds_f+=1
  minutes+=seconds_f\1800
  seconds_f%=1800
 end
 
 -- update each object
 foreach(objects,function(obj)
  if obj.freeze>0 then
   obj.freeze-=1
   return
  end
  obj.move(obj.spd.x,obj.spd.y)
  obj:update()
 end)
 
 -- room restart
 if delay_restart>0 then
  delay_restart-=1
  if delay_restart==0 then
   exec[[
gset◆collect
load_room◆room]]
  end
 end
 
 -- change room
 if room_goto then
  exec[[
load_room◆room_goto
gset◆room_goto]]
 end
end

function game_draw()
 _bgyoff=8-min(8,round(cam_y/8))
 exec[[
pal
cls◆10
camera
draw_clouds
ssload◆1
palt◆0
palt◆7,1
pal◆14,2
pal◆2,10
pal◆0,10
spr◆0,0,_bgyoff,16,16
pal
ssload◆0
cam_draw]]

 outline(function() cmap"0x02" end)
	foreach(objects,function(o)
  if (o.outline) outline(function() o:draw() end)
 end)
 
 exec[[
pal
cam_draw
cmap◆0x02]]
 foreach(sort(objects,"layer"),draw_obj)
 
 -- candy fx
 foreach(get_objs(candy),function(c)
  -- bouncing circle
  for d=0,1 do
	  local off=round(10*(t()+3*d))%8
	  local k=(off-1)/7
	  if c._spr==21 then
	   off=7-off
	  end
	  fillp(
	   k<=0 and 0b0000000000000000.1 or
	   k<0.33333 and 0b0000101000000101.1 or
	   k<0.66666 and 0b0101101001011010.1 or
	   k<1 and 0b1111101011110101.1 or
	   0b1111111111111111.1)
	  circ(c.x+4,c.y+4,c.rad-off/2,7)
	  fillp()
	 end
	 -- particles
  foreach(c.fx,function(p)
   local pc,oob=pget(p.x,p.y),
    p.x-cam_x<0 or p.x-cam_x>=128 or p.y-cam_y<0 or p.y-cam_y>=128
   p.t+=1
   if (p.t==30) del(c.fx,p)
   local k=p.t^2/900
   p.x,p.y=
    k*p.ex+(1-k)*p.sx,
    k*p.ey+(1-k)*p.sy
   if (not oob) rectfill(p.x,p.y,p.x+1,p.y+1,pc)
  end)
 end)
 
 -- smoke
 foreach(smoke,function(p)
  p._spr+=0.2
  p.x+=p.spd.x
  p.y+=p.spd.y
  if p._spr>=16 then
   del(smoke,p)
  else
   draw_spr(p)
  end
 end)

 -- dead particles
 foreach(dead_particles,function(p)
  p.x+=p.dx
  p.y+=p.dy
  p.t-=0.2
  if p.t<=0 then
   del(dead_particles,p)
  end
  rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,6+p.t*5%2)
 end)
 
 exec[[
camera
draw_snowflakes
secret_pal]]

 -- timer
 if get_obj(player_spawn) then
  exec[[draw_time◆4,4]]
 end
end

-- global particles
function init_g_particles()
 dead_particles,smoke,snowflakes,clouds={},{},{},{}
 for i=0,48 do
  add(snowflakes,{
   x=rnd"128",
   y=rnd"128",
   s=flr(rnd"1.25"),
   spd=0.75+rnd"0.75",
   off=rnd"1",
   c=rnd"1"<0.8 and 7 or 6,
  })
 end
 for i=0,16 do
  add(clouds,{
   x=rnd"128",
   y=rnd"48",
   spd=0.25+rnd"0.75",
   w=32+rnd"32",
   c=2
  })
 end
end

function draw_snowflakes()
 local sin,rectfill,cam_dx=sin,rectfill,_cdx
 foreach(snowflakes,function(_ENV)
  x=(x+spd-cam_dx)%128
  y=(y+0.5+0.5*sin(off))%128
  off+=0.0125
  rectfill(x,y,x+s,y+s,c)
 end)
end

function draw_clouds()
 fillp"0b1010010110100101.1"
 foreach(clouds,function(c)
  c.x+=c.spd-_cdx/4
  for i=0,2 do
   rectfill(c.x-i,c.y+i,c.x+c.w+i,c.y+16-c.w*0.1875-i,c.c)
  end
  if c.x>128 then
   c.x-=128+c.w
   c.y=rnd"48"
  elseif c.x+c.w<0 then
   c.x+=127+c.w
  end
 end)
 fillp()
end
-->8
-- room stuff

rm_data=split([[
0,0,29,16,0b10,left
29,0,16,16,0b10,left
45,0,19,20,0b10,left
64,0,16,16,0b10,left
80,0,16,16,0b10,left
96,0,16,16,0b10,left
112,0,16,16,0b10,left
0,16,16,26,0b10,left
16,16,29,16,0b10,left
64,16,16,16,0b10,left
45,20,19,22,0b10,left
80,16,16,16,0b01,bottom
0,42,16,22,0b10,left
45,42,19,22,0b10,bottom
112,16,16,16,0b00,left]],"\n")

function room_globals(rm)
 room,rx,ry,rw,rh,re,rs=rm,usplit(rm_data[rm])
end

function load_room(rm)
 room_globals(rm)
 objects,smoke,dead_particles={},{},{}
 for ty=0,rh-1 do
  for tx=0,rw-1 do
   local t=tile_at(tx,ty)
   if tiles[t] then
    init_object(tiles[t],8*tx,8*ty,t)
   end
  end
 end
 local cdy2=14
 if room==cdy2 then
  init_object(candy2,76,64)
 end
 cam_lock,exit_lock,collect=
  nil,room==cdy2,nil
 pmusic(room==cdy2 and 63 or 
room==15 and 63 or
0,1000,0b11)
end
-->8
-- object stuff

-- [player entity]

player={
 init=function(this)
  this.layer,this.grace,this.jbuffer,this.djump,
  this.dash_cd,this.dash_time,
  this.dash_target_x,this.dash_target_y,
  this.dash_accel_x,this.dash_accel_y,
  this.hitbox,
  this.spr_off,
  this.solid,this.rider,
  this.gravity=
  1,0,0,1,
  0,0,
  0,0,
  0,0,
  rectangle(usplit"1,3,6,5"),
  0,
  true,true,
  true
  create_hair(this)
 end,
 update=function(this)
  -- input
  local h_input,v_input,on_ground=
   tonum(btn"1")-tonum(btn"0"),
   tonum(btn"3")-tonum(btn"2"),
   this.is_solid(0,1)

  -- spike collision / bottom death
  if this.is_flag(0,0,"spike") or
   this.top()>=rh*8 then
   kill_obj(this)
   return
  end

  -- exit level off the top (except summit)
  if re&0b01>0 and this.bottom()<0 or
   re&0b10>0 and this.left()>=8*rw then
   room_goto=room+1
  end

  -- landing smoke
  if on_ground and not this.was_on_ground then
   this.init_smoke(0,4)
  end

  -- jump and dash input
  local jump,dash=btn"4" and not this.p_jump,btn"5" and not this.p_dash
  this.p_jump,this.p_dash=btn"4",btn"5"

  -- jump buffer
  if jump then
   this.jbuffer=4
  elseif this.jbuffer>0 then
   this.jbuffer-=1
  end

  -- grace frames and dash restoration
  if on_ground then
   this.grace=6
   if this.djump<1 then
    sfx"14"
    this.djump=1
   end
  elseif this.grace>0 then
   this.grace-=1
  end

  -- dash cooldown
  this.dash_cd=max(this.dash_cd-1)

  -- dash startup period, accel toward dash target speed
  if this.dash_time>0 then
   this.init_smoke()
   this.dash_time-=1
   this.spd=vector(
    l_appr(this.spd.x,this.dash_target_x,this.dash_accel_x),
    l_appr(this.spd.y,this.dash_target_y,this.dash_accel_y)
   )
  else
   -- x movement
   local maxrun,accel,deccel=
    2.0,on_ground and 0.93 or 0.80,0.16

   -- set x speed
   this.spd.x=abs(this.spd.x)<=maxrun and
    l_appr(this.spd.x,h_input*maxrun,accel) or
    l_appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)

   -- facing direction
   if this.spd.x~=0 then
    this.flp.x=this.spd.x<0
   end

   -- y movement
   local maxfall=3.0

   -- wall slide
   if h_input~=0 and this.is_solid(h_input,0) then
    maxfall=0.8
    -- wall slide smoke
    if rnd(10)<2 then
     this.init_smoke(h_input*6)
    end
   end

   -- apply gravity
   if not on_ground and this.gravity then
    this.spd.y=l_appr(this.spd.y,maxfall,abs(this.spd.y)>0.124 and 0.334 or 0.167)
   end

   -- jump
   if this.jbuffer>0 then
    if this.grace>0 then
     -- normal jump
     sfx"50"
     this.jbuffer,this.grace,this.spd.y=
      0,0,-3.36
     this.init_smoke(0,4)
    else
     -- wall jump
     local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
     if wall_dir~=0 then
      sfx"2"
      this.jbuffer,this.spd=0,vector(-wall_dir*(maxrun+1.06),-3.36)
      -- wall jump smoke
      this.init_smoke(wall_dir*6)
     end
    end
   end

   -- dash
   local d_full,d_half=6.58,4.6528

   if this.djump>0 and this.dash_cd==0 and dash then
    this.init_smoke()
    this.djump-=1
    this.dash_time,this.spd=4,
    vector(
     h_input~=0 and h_input*(v_input~=0 and d_half or d_full) or (v_input~=0 and 0 or this.flp.x and -1 or 1),
     v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0
    )
    sfx"3"
    -- dash target speeds and accels
    this.dash_target_x,this.dash_target_y,this.dash_accel_x,this.dash_accel_y=
     3.07*sign(this.spd.x),
     (this.spd.y>=0 and 3.07 or 2.55)*sign(this.spd.y),
     this.spd.y==0 and 2.37 or 1.6758,
     this.spd.x==0 and 2.37 or 1.6758
   elseif this.djump<=0 and dash then
    -- failed dash smoke
    sfx"10"
    this.init_smoke()
   end
  end

  -- animation
  update_hair(this)
  this.spr_off+=0.25
  this._spr = not on_ground and (this.is_solid(h_input,0) and 5 or 3) or  -- wall slide or mid air
   btn"3" and 6 or -- crouch
   btn"2" and 7 or -- look up
   1+(this.spd.x~=0 and h_input~=0 and this.spr_off%4 or 0) -- walk or stand

  -- was on the ground
  this.was_on_ground=on_ground
  move_cam(this)
 end,

 draw=function(this)
  local s=flr(this._spr)
  pal(8,this.djump==1 and 8 or 12)
  for i,h in pairs(this.hair) do
   circfill(round(h.x),round(h.y),mid(4-i,1,2),8)
  end
  draw_spr(this)
  pal()
 end,
}

function create_hair(obj)
 obj.hair={}
 for i=1,5 do
  add(obj.hair,vector(obj.x,obj.y))
 end
end

function update_hair(obj)
 local last=vector(obj.x+4-(obj.flp.x and-2 or 3),obj.y+(btn(⬇️) and 4 or 2.9))
 for i,h in pairs(obj.hair) do
  h.x+=(last.x-h.x)/1.5
  h.y+=(last.y+0.5-h.y)/1.5
  last=h
 end
end

-- [other entities]

player_spawn={
 init=function(this)
  sfx"4"
  this._spr,this.target,
  this.state,this.delay,this.djump=
   3,this.y,0,0,1
  if rs=="left" then
   this.spd=vector(1.6,-2)
   this.y-=8
   this.x-=24
  elseif rs=="top" then
   this.spd.y=1
   this.y=max(this.y-48,-4)
  else
   this.spd.y=-4
   this.y=this.y+48
  end
  if collect then
   init_object(fruit,this.x,this.y,collect).follow=true
  end
  create_hair(this)
  move_cam(this,1)
 end,
 update=function(this)
  -- jumping up
  if this.state==0 then
   if this.y<this.target+16 then
    this.state,this.delay=1,3
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
     this.y,this.spd,
     this.state,this.delay=
      this.target,zvec(),
      2,5
     this.init_smoke(0,4)
     sfx"5"
    end
   end
  -- landing and spawning player object
  elseif this.state==2 then
   this.delay-=1
   this._spr=6
   if this.delay<0 then
    this.delete()
    init_object(player,this.x,this.y,1)
   end
  end
  update_hair(this)
  move_cam(this)
 end,
 draw=player.draw
}

refill={
 init=function(this)
  this.offset,this.timer,this.hitbox,this.active,this.layer=
   rnd"1",0,rectangle(usplit"-1,-1,10,10"),true,-1
 end,
 update=function(this)
  if this.active then
   this.offset+=0.02
   local hit=this.player_here()
   if hit and hit.djump<1 then
    sfx"6"
    this.init_smoke()
    hit.djump,this.active,this.timer=1,false,60
   end
  elseif this.timer>0 then
   this.timer-=1
  else
   sfx"7"
   this.init_smoke()
   this.active=true
  end
 end,
 draw=function(this)
  spr(this.active and 9 or 8,this.x,this.y+round(sin(this.offset)))
 end
}

fake_wall={
 update=function(this)
  this.hitbox=rectangle(usplit"-1,-1,18,18")
  local hit=this.player_here()
  if hit and hit.dash_time>0 then
   sfx"11"
   hit.spd,hit.dash_time=vector(sign(hit.spd.x)*-2.5,-2.5),0
   for ox=0,8,8 do
    for oy=0,8,8 do
     this.init_smoke(ox,oy)
    end
   end
   if this._spr==32 then
    init_object(fruit,this.x+4,this.y+4,10)
   end
   this.delete()
  end
  this.hitbox=rectangle(usplit"0,0,16,16")
 end,
 draw=function(this)
  spr(32,this.x,this.y,2,2)
 end
}

fruit={
 init=function(this) 
  this.y_,this.follow,this.tx,this.ty,this.layer=
   this.y,false,this.x,this.y,1
 end,
 update=function(this)
  if not this.follow and this.player_here() then
   this.follow,collect=true,this._spr
   sfx"12"
  elseif this.follow then
   local p=get_player(true)
   if p then
    if p.obj==player_spawn then
     this.x+=e_appr_delta(this.x,p.x,0.2)
     this.y_+=e_appr_delta(this.y_,p.y-4,0.1)
     if p.state==2 and p.delay==0 then
      init_object(lifeup,this.x,this.y)
      this.delete()
      fruits+=1
     end
    else
     this.tx+=e_appr_delta(this.tx,p.x,0.4)
     this.ty+=e_appr_delta(this.ty,p.y,0.4)
     local vx,vy=this.x-this.tx,this.y_-this.ty
     local mag=max(1,sqrt(vx^2+vy^2))
     local k=mag>12 and 0.2 or 0.1
     this.x+=e_appr_delta(this.x,this.tx+12*vx/mag,k)
     this.y_+=e_appr_delta(this.y_,this.ty+12*vy/mag,k)
    end
   end
  end
  this.y=round(this.y_+1.5*sin(t()*0.75))
 end
}

lifeup={
 init=function(this)
  this.spd.y,this.duration,this.outline=-0.25,30
  sfx"8"
 end,
 update=function(this)
  this.duration-=1
  if this.duration<=0 then
   this.delete()
  end
 end,
 draw=function(this)
  ?"1000",this.x-4,this.y-4,7+t()*15%4
 end
}

crumble={
 init=function(this)
  this.solid,this.ride,this.dx=true,true,0
 end,
 update=function(this)
  local on_ground=this.is_solid(0,1)
	 local h=this.check(crumble,0,-1)
  if not this.t and this.check(player,0,-1) then
   this.t=15
   sfx"9"
  elseif this.t then
   this.t=max(this.t-1)
   if this.t==0 then
    this.spd.y=l_appr(this.spd.y,6,0.3)
   end
  end
  if on_ground then
   this.t=0
   if not this.was_on_ground then
    this.init_smoke(0,4)
   end
  end
  if this.top()-8>=rh*8 then
   this.delete()
  end
  this.dx,this.was_on_ground=
   this.t and this.t>0 and rnd"2"-1 or 0,
   on_ground
 end,
 draw=function(this)
  spr(this._spr,this.x+this.dx,this.y)
 end
}

flag={
 update=function(this)
  if not this.touched and this.player_here() then
   exec[[sfx◆15
gset◆ticking]]
   this.touched=true
  end
 end,
 draw=function(this)
  if this.touched then
   for i=0,4 do
    local fx,fy=this.x+3,this.y+1-sin(t()+i/5)
    rectfill(fx+i,fy,fx+i,fy+2,11)
   end
   exec[[camera◆-29,-86
rectfill◆35,0,91,29,0
rectfill◆34,1,92,28,0
draw_time◆41,2
spr◆10,52,20]]
   cprint("deaths:"..deaths,12,7)
   cprint(":"..fruits.."/3",21,7,4)
   cam_draw()
  else
   for i=0,1 do
    local fx,fy=this.x+3,this.y+1+2*i
    rectfill(fx+i,fy,fx+i,fy+2,11)
   end
  end
 end
}

candy={
 init=function(this)
  if this._spr>21 then
   local p=init_object(spikeball,this.x+25,this.y,22)
   p.cx,p.cy=this.x,this.y
   this._spr-=16
  end
  this.rad=25
  this.force=this._spr==20 and 4.5 or -6
  this.hitbox=rectangle(1,1,6,6)
  this.fx={}
 end,
 update=function(this)
  -- particle effects
  for _=0,1+rnd"2"\1 do
	  local a=rnd"1"
	  local ca,sa=cos(a),sin(a)
	  local sx,sy,ex,ey=
	   this.x+4+this.rad*ca,
	   this.y+4+this.rad*sa,
	   this.x+4+6*ca,
	   this.y+4+6*sa
	  if this._spr==21 then
	   sx,sy,ex,ey=ex,ey,sx,sy
	  end
	  add(this.fx,{x=sx,y=sy,sx=sx,sy=sy,ex=ex,ey=ey,t=0})
  end
  -- do the thing
  local p=get_player()
  if p and l2dist(this.hmid(),this.vmid(),p.hmid(),p.vmid())<this.rad then 
   this.p=p
   goto player_find
  end
  if this.p then
   this.p.gravity,this.p=
    true,nil
  end
  ::player_find::
  if this.p then
   this.p.gravity=false
   local dx,dy=
    this.x-this.p.x,
    this.y-this.p.y
   local fx,fy=
    sign(dx)*(this.rad-abs(dx))/this.rad,
    sign(dy)*(this.rad-abs(dy))/this.rad
   this.p.spd=vector(
    l_appr(this.p.spd.x,fx*this.force,0.33),
    l_appr(this.p.spd.y,fy*this.force,0.33)
   )
  end
  if this.player_here() then
   kill_obj(this.p)
  end
 end,
 draw=function(this)
  spr_r(this._spr,this.x,this.y,-t())
 end,
}

spikeball={
 init=function(this)
  this.hitbox=rectangle(1,1,6,6)
  this.a=0
 end,
 update=function(this)
  this.a+=0.01
  this.x,this.y=round(this.cx+25*cos(this.a)),round(this.cy+25*sin(this.a))
  local p=this.player_here()
  if p then
   kill_obj(p)
  end
 end,
 draw=function(this)
  spr_r(this._spr,this.x,this.y,-t())
 end,
}

candy2={
 init=function(this)
  this.layer,this._y,this.y=
   -1,this.y,256
  this.hitbox=rectangle(usplit"-16,-12,32,16")
  this.state,this.t="rise",60
  this.t_ref=t()
  this.pattern={this.x,112,32,32,0.2}
  this.health=3
  this.particles={}
 end,
 update=function(this)
  local cx,cy,crx,cry,frq=unpack(this.pattern)
  local _t=t()-this.t_ref
  this.t=max(this.t-1)
  if this.candies then
   for i=1,3 do
    for axis in all{"x","y"} do
     this.candies[i][axis]+=e_appr_delta(this.candies[i][axis],this.targets[i][axis]-4,this.state=="revenge" and 0.15 or 0.1)
    end
   end
  end
  if this.state=="rise" then
   this.y+=e_appr_delta(this.y,this._y,0.05)
   if this.t==30 then
    pmusic(14,1000,0b11)
   end
   if this.t==0 then
    this.state="chill"
  		this.candies={}
  		this.targets={vector(this.x,80),vector(this.x,96),vector(this.x,112)}
  		sfx"19"
  		for i=1,3 do
  		 add(this.candies,init_object(candy,this.x-4,this.y-4,i<3 and 20 or 21))
  		end
   end
  elseif this.state=="chill" then
   for i=1,3 do
    this.targets[i]=vector(cx+crx*cos(frq*_t+i/3),cy+cry*sin(frq*_t+i/3))
   end
   local p=this.player_here()
   if p and p.dash_time>0 then
    sfx"17"
    this.health-=1
    if this.health>0 then
     this.state,this.t="ow",75
     for i=1,3 do
      this.targets[i]=vector(cx+crx*cos(1/4+i/3),this.y+16)
     end
     this.pattern={this.x,112,32,32,frq+0.1}
    else
     for _y=42,62 do
      for _x=45,63,18 do
       mset(_x,_y,0)
       this.init_smoke(8*(_x-rx)-this.x,8*(_y-ry)-this.y)
      end
     end
     exec[[save_ss◆0]]
     p.gravity=true
     for i=1,3 do
      this.candies[i].delete()
     end
     pmusic(-1)
     this.state,this.t="boom",180
    end
   end
  elseif this.state=="ow" then
   local cx,cy,crx,cry,frq=unpack(this.pattern)
   if this.t==0 then
    this.state,this.t="revenge",180
   end
  elseif this.state=="revenge" then
   local p=get_player()
   for i=1,3 do
    if this.t==240-60*i-1 then
     sfx"1"
    end
    if this.t<240-60*i then
     this.targets[i]=
      p and this.t>210-60*i and vector(p.hmid()+4*p.spd.x,p.vmid()+2*p.spd.y)
      or vector(cx+crx*cos(frq*_t+i/3-1/3),cy+cry*sin(frq*_t+i/3-1/3))
    end
   end
   if this.t==0 then
    this.state="chill"
   end
  elseif this.state=="boom" then
   if this.t>90 then
    if rnd"1"<0.33 then
     init_object(circle,this.x-38+rnd"77",this.y-38+rnd"77")
     sfx"17"
    end
   elseif this.t==90 then
    init_object(dust,this.x,this.y)
   elseif this.t==50 then
    this.delete()
   end
  end
 end,
 draw=function(this)
  if this.state=="ow" and this.t>70 then
   pal_all(7)
  end
  local shake=this.state=="ow" and this.t>30 or this.state=="boom"
  local ox,oy=
   shake and rnd"3"-1 or 0,
   shake and rnd"3"-1 or 0
  ssload"2"
  spr(({0,128,136})[7.5*t()%3\1+1],this.x-32,this.y-32,8,8,true,false)
  pal(7,this.state=="revenge" and 14 or 7)
  spr(12,this.x-16+ox,this.y-12+oy,4,2)
  ssload"0"
  pal()
 end,
}

circle={
 init=function(this)
  this.t,this.layer,this.outline=1,9
 end,
 draw=function(this)
  this.t+=1
  if this.t==15 then
   this.delete()
  end
  circfill(this.x,this.y,sqrt(10*this.t),7)
 end,
}

dust={
 init=function(this)
  this.t,layer,this.outline=0,10
  sfx"18"
 end,
 draw=function(this)
  this.t+=1
  if this.t<32 then
   circfill(this.x,this.y,4*this.t,7)
   return
  else
   camera()
   screen_fade((this.t-40)/60,7)
   cam_draw()
   if this.t>90 then
    pmusic(63,1000)
    exit_lock=false
   end
  end
 end
}

-- [tile dict]
tiles={}
foreach(split([[1,player_spawn
9,refill
32,fake_wall
33,fake_wall
10,fruit
11,crumble
12,flag
20,candy
21,candy
36,candy
37,candy]],"\n"),function(ln)
 local k,v=usplit(ln)
 tiles[k]=v
end)

-- [object functions]

function init_object(obj,x,y,tile)
 local o={
 obj=obj,
 _spr=tile,
 hitbox=rectangle(usplit"0,0,8,8"),
 x=x,
 y=y,
 rem=zvec(),
 spd=zvec(),
 flp=vector(),
 freeze=0,
 layer=0,
 collideable=true,
 solid=false,
 outline=true,
 init=obj.init or t,
 update=obj.update or t,
 draw=obj.draw or draw_spr,
 on_move=obj.on_move
 }
 -- useful hitbox stuff
 function o.left() return o.x+o.hitbox.x end
 function o.right() return o.left()+o.hitbox.w-1 end
 function o.top() return o.y+o.hitbox.y end
 function o.bottom() return o.top()+o.hitbox.h-1 end
 function o.hmid() return round(o.left()+o.right()>>1) end
 function o.vmid() return round(o.top()+o.bottom()>>1) end
 -- tile-based collisions
 function o.is_flag(ox,oy,flag)
  local x1,x2,y1,y2=o.left(),o.right(),o.top(),o.bottom()
  for i=mid(0,rw-1,(x1+ox)\8),mid(0,rw-1,(x2+ox)\8) do
   for j=mid(0,rh-1,(y1+oy)\8),mid(0,rh-1,(y2+oy)\8) do
    local tile=tile_at(i,j)
    if flag=="spike" then
     if ({[16]=o.spd.y>=0 and y2%8>=5,
      [17]=o.spd.y<=0 and y1%8<=2,
      [18]=o.spd.x<=0 and x1%8<=2,
      [19]=o.spd.x>=0 and x2%8>=5})[tile] then
      return true
     end
    elseif fget(tile,flag) then
     return true
    end
   end
  end
 end
 -- hitbox overlap check
 function o.overlaps(other,ox,oy)
  return other.right()>=o.left()+ox and
   other.bottom()>=o.top()+oy and
   other.left()<=o.right()+ox and
   other.top()<=o.bottom()+oy
 end
 -- return all overlapped instances of an obj
 function o.check_all(obj,ox,oy,tbl)
  return filter(tbl or objects,function(other)
   return other.obj==obj and other~=o and other.collideable and o.overlaps(other,ox or 0,oy or 0)
  end)
 end
 -- return first overlapped instance of an obj
 function o.check(...)
  return o.check_all(...)[1]
 end
 -- player check
 function o.player_here()
  return o.check(player,0,0)
 end
 -- solid check 
 function o.is_solid(ox,oy)
  return (oy>0 and not o.is_flag(ox,0,2) and o.is_flag(ox,oy,2))
   or o.is_flag(ox,oy,0)
   or o.check(fake_wall,ox,oy)
   or o.check(crumble,ox,oy)
 end
 -- oob check
 function o.oob(ox,oy)
  return o.left()+ox<0 or 
   (re&0b10==0 or exit_lock) and o.right()+ox>=8*rw or
   re&0b01==0 and o.bottom()+24+oy<0
 end
 -- place free check (solid or oob)
 function o.not_free(ox,oy)
  return o.is_solid(ox,oy) or
   o.oob(ox,oy)
 end
 -- per-px movement
 function o.move(ox,oy)
  for axis in all{"x","y"} do
   o.rem[axis]+=axis=="x" and ox or oy
   local amt=flr(o.rem[axis]+0.5)
   o.rem[axis]-=amt
   if o.solid then
    local step=sign(amt)
    local dx=axis=="x" and step or 0
    local dy=step-dx
    for i=1,abs(amt) do
     if o.on_move and o:on_move(dx,dy) then
      return
     end
     if o.not_free(dx,dy) then
      o.rem[axis],o.spd[axis]=0,0
      break
     else
      o[axis]+=step
      if o.ride then
       foreach(filter(objects,function(other) return other.rider and (o.overlaps(other,0,0) or o.overlaps(other,-dx,-dy-1)) end),function(rider)
        if o.overlaps(rider,-dx,-dy-1) and rider.not_free(dx,dy) then
         rider.rem[axis],rider.spd[axis]=0,0
        else
         rider[axis]+=step
        end
        if rider.not_free(0,0) then
         kill_obj(rider)
        end
       end)
      end
     end
    end
   else
    o[axis]+=amt
   end
  end
 end
 -- instance deletion (queued or immediate)
 function o.delete()
  del(objects,o)
 end
 -- smoke effect
 function o.init_smoke(ox,oy)
  add(smoke,{
   x=o.x+(ox or 0)-1+rnd"2",
   y=o.y+(oy or 0)-1+rnd"2",
   spd=vector(0.3+rnd"0.2",-0.1),
   flp=vector(rnd"1"<0.5,rnd"1"<0.5),
   _spr=13
  })
 end
 -- add to obj list, init event
 add(objects,o)
 o:init()
 -- return instance
 return o
end

function kill_obj(o)
 if (not o) return
 o.delete()
 if o.obj==player then
  exec[[gset◆delay_restart,15]]
  deaths+=1
 end
 exec[[sfx◆-1
sfx◆49]]
 for dir=0,0.875,0.125 do
  add(dead_particles,{
   x=o.x+4,
   y=o.y+4,
   t=2,
   dx=sin(dir)*3,
   dy=cos(dir)*3
  })
 end
end
-->8
-- title init/update/draw

function title_init()
 exec[[gset◆start_game_flash
gset◆_update,title_update
gset◆_draw,title_draw]]
 pmusic(63,1000)
end

function title_update()
 if start_game_flash then
  start_game_flash-=1
  if start_game_flash<=-30 then
   game_init()
  end
 elseif btn"4" or btn"5" then
  exec[[gset◆start_game_flash,50
pmusic◆-1,500
sfx◆13]]
 end
end

function title_draw()
 exec[[pal
cls]]

 if start_game_flash then
  local c=start_game_flash>10 and (30*t()%10<5 and 7 or 10) or (start_game_flash>5 and 2 or start_game_flash>0 and 1 or 0)
  if c<10 then
   pal_all(c)
  end
 end
 
 
 exec[[ssload◆3
spr◆0,0,0,16,16
cprint◆🅾️+❎,72,2,-4
cprint◆maddy thorson,84,1
cprint◆noel berry,90,1
cprint◆mod by,104,15
cprint◆ruby | meep | taco | gonen,112,2
secret_pal
draw_snowflakes]]
end
__gfx__
000000000000000000000000088888800000000000000000000000000000000000077000000770000300b0b0dd6666dd00200000000000000000000070000000
000000000888888008888880888888880888888008888800000000000888888000700700007bb700003b33006666dd6600200000007700000770070007000007
00000000888888888888888888888ff88888888888888880088888808881ff180700007007bbb37002888820666d666600400000007770700777000000000000
0000000088888ff888888ff888f1ff1888888ff8888ff8808888888888fffff8700000077bbb3bb7089888806666666600400000077777700770000000000000
0000000088f1ff1888f1ff1808fffff088f1ff1881ff1f8088888ff888fffff87000000773b33bb708888980666d66d600400000077777700000700000000000
0000000008fffff008fffff000dccc0008fffff00fffff8088fffff808dccc80070000700733337008898880666ddd6600400000077777700000077000000000
0000000000dccc0000dccc000700007007dccc0000dccc7008f1ff1000dccc00007007000073370002888820dd666d6d00400000070777000007077007000070
000000000070070000700070000000000000070000007000077ccc70007007000007700000077000002882000dd666d007777000000000007000000000000000
00000000666566655500000000000666002782000037b30000007000088778877887788778877881000000000000000000000000000000000000000000000000
00000000676567656670000000077776087887700b7bb77000007000887788778877887788778877000000000000000000000000000000000000000000000000
00000000677067706777700000000766287878823b7b7bb300765700770000000000000000000078000000000000000000000000000000000000000000000000
00700070070007006660000000000055788727787bb7377b77566600780000000000000000000088000000000000000000000000000000000000000000000000
0070007007000700550000000000066687727887b7737bb700666577088000000000000000000780000000000000000000000000000000000000000000000000
06770677000000006670000000077776288787823bb7b7b300756700000000000000000000000000000000000000000000000000000000000000000000000000
5676567600000000677770000000076607788780077bb7b000070000000000000000000000000000000000000000000000000000000000000000000000000000
5666566600000000666000000000005500287200003b730000070000000000000000000000000000000000000000000000000000000000000000000000000000
522eee2ee22ee2250000000000000000002772000037730000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee0000000000000000077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
7eeeeeee7eeeeee20000000000000000278778723787787300000000000000000000000000000000000000000000000000000000000000000000000000000000
877eeee8877eeee80000000000000000777887777778877700000000000000000000000000000000000000000000000000000000000000000000000000000000
28888882288888820000000000000000777887777778877700000000000000000000000000000000000000000000000000000000000000000000000000000000
1222222ff22222240000000000000000278778723787787300000000000000000000000000000000000000000000000000000000000000000000000000000000
49ffffffffffff940000000000000000077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
49ffffffffffff910000000000000000002772000037730000000000000000000000000000000000000000000000000000000000000000000000000000000000
49ffffffffffff910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19ffffffffffff940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000
19ffffffffffff910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0000000001000
49ffffffffffff91000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088000c00c000000088000
49ffffffff99ff94000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700700c00c000000788700
1499ff9999449944000000000000000000000000000000000000000000000000000000000000000000000000000d000000000000008000000c0c0c0000e77700
5444994444444445000000000000000000000000000000000000000000000000000000000000000000000000000d0d000000000000700000000c0c00077eeee0
05514455115514500000000000000000000000000000000000000000000000000000000000000000000000000d0d0d000eeeeee000800000000c0c000e7777e0
5eeeeeeeeeeeeeeeeeeeeee55eeeeee55eeeeeeeeeeeeeeeeeeeeee529ffff9229ffff9229ffff9249ffffffffffff9400000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee29ffff9229ffff9229ffff9249ffffffffffff9400000000000000000000000000000000
7eeeeeee7eeeeeee7eeeeeee7eeeeeee7eeeeeee7eeeeeee7eeeeeee29ffff9229ffff9229ffff9249ffffffffffff9400000000000000000000000000000000
877eeee8877eeee8877eeee8877eeee8877eeee8877eeee8877eeee829ffff9229ffff9229ffff9249ffffffffffff9400000000000000000000000000000000
288888822888888228888882288888822888888228888882288888829ffffff99ffffff99ffffff949ffffffffffff9400000000000000000000000000000000
4222222ff222222ff2222224422222244222222ff222222ff2222224ffffffffffffffffffffffff49ffffffffffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449fffff99ffffff99fffff949ffffffffffffffffffffff949fffff99fffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9449ffff9449ffff9449ffffffffffffffffffff9449ffff9449ffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429ffffffffffffffffffff9249ffff9229ffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429ffffffffffffffffffff9249ffff9229ffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429fffffffff9f99fffffff9249ffff9229ffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429fffffffffff99fffffff9249ffff9229ffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449fffff99ffffff99fffff949ffffffff99ffffffffffff949fffff99fffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffffffffffffffffffff94fffffffff99fffffffffffff49ffffffffffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449fffff99ffffff99fffff949fffffffffff9ffffffffff949ffffffffffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9449ffff9449ffff9449ffffffffffffffffffff9449ffffffffffff9400000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429ffffffffffffffffffff92eeeeeeeeeeeeeeee00000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429ffffffffffffffffffff92eeeeeeeeeeeeeeee00000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429ffffffffffffffffffff927eeeeeee7eeeeeee00000000000000000000000000000000
49ffffffffffffffffffff9449ffff9449ffff9229ffff9229ffff9429ffffffffffffffffffff92877eeee8877eeee800000000000000000000000000000000
49ffffffff99ff99ff99ff9449ffff9449fffff99f99ff999f99ff949ffffffffffffffffffffff9288888822888888200000000000000000000000000000000
4499ff999944994499449944449999444499ff999944994499449944fffffffffffffffffffffffff222222ff222222f00000000000000000000000000000000
544499444444444444444445544444455444994444444444444444459ffffff99ffffff99ffffff9fffffff99fffffff00000000000000000000000000000000
0555445544554455445544500555555005554455445544554455445049ffff9449ffff9449ffff94ffffff9449ffffff00000000000000000000000000000000
5eeeeeeeeeeeeeeeeeeeeee55eeeeee5ffffffffffffffffffffff9229ffffff29ffffffffffff92ffffff9229ffffff00000000000000000000000000000000
7eeeeeee7eeeeeeeeeeeeeee7eeeeeeeffffffffffffffffffffff9229ffffff29ffffffffffff92ffffff9229ffffff00000000000000000000000000000000
877eeee8877eeee88eeeeee8877eeee8ffffffffffffffffffffff9229ffffff29ffffffffffff92ffffff9229ffffff00000000000000000000000000000000
28888882288888822888888228888882ffffffffffffffffffffff9229ffffff29ffffffffffff92ffffff9229ffffff00000000000000000000000000000000
4222222ff222222ff222222442222224fffffffffffffffffffffff99fffffff9ffffffffffffff9ff99ff999f99ff9900000000000000000000000000000000
49ffffffffffffffffffff9449ffff94ffffffffffffffffffffffffffffffffffffffffffffffff994499449944994400000000000000000000000000000000
49999999999999999999999449999994fffffff99ffffffffffffffffffffffffffffff99fffffff444444444444444400000000000000000000000000000000
54444444444444444444444554444445ffffff9449ffffffffffffffffffffffffffff9449ffffff445544554455445500000000000000000000000000000000
11110000000000000000000616571515000000000000000000000000000000000000000000000000000000000015151515951717270000000041003105151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004100000000000031051515000000000000000000000000000000000000000000000000000000000015151547261111110000000000003105151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000031051515000000000000000000000000000000000000000000000000000000000015158525210000000000000101010477151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000031065715000000000000000000000000000000000000000000000000000000000015151525210041000000000717177515151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000310515000000000000000000000000000000000000000000000000000000000016161626210000000000001111110657151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010b300000000000000000000310515000000000000000000000000000000000000000000000000000000000000000000000000000000000000003105158515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14142421000000000000000000310657000000000000000000000000000000000000000000000000000000000000000000000000000000000000003105151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15152521000000000000000000003105000000000000000000000000000000000000000000000000000000000000001000000000000000000000003105151585
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15152521000000000000000000003105000000000000000000000000000000000000000000000000000000000014141414141414141414141414141477151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15152521000000000000000000003105000000000000000000000000000000000000000000000000000000000015151515151515151515151515158515151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
85151547161616260000000000000005000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
47161626111111110000000000000006000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25111111000000000000000000000000000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000041000000b300000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25000000000000000000000000000414000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25000000000000000000000000000657000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25000000000000000001010100003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25000000410000003107172721003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25000000000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25000000000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25010101000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67141424010101010000410000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151547a7171717270000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15152500000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15152500000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15152500004100000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16162600000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000010a3000000c30000000000003105000000000000000000000000000000000000000000000000000000000021000000000000000000000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
141414141414142400000000000031050000000000000000000000000000000000000000000000000000000000210000b3000000000010000000000000000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15151515151515250000000000003105000000000000000000000000000000000000000000000000000000000014141414141414141414141414141414141414
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000ee0000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000077e00000000000000000000000000770000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000077e000000000000000000000000000770000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000e77ee000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000e777e0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000e777eee000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000ee77eeee000600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000070000000ee777eeeee00000000000eeeeee000000000000000000000000000000000000000000000
0000000000000000000000000000000000006000000000000000000ee7777eeeeee0000000007777eeee00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000ee777eeeeeee0000000077777eeeee0000000000000000000000000000000000000000006
0000000000000000000000000000000000000000000000000000000eeeeeeeeeeee0000000e7777eeeeeee000000000000000000000000000000000000000006
000000000000000000000000000000700000000000000007e000000eeeeee222222000000ee77eeeeeeeee000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000077ee00000eeee22eeeeeee00000eeeeeeeeeeeee000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077e2e00000eeeeeee7777eee000ee222222eeeeee000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000007e2e2e000eeeee77777777ee00022eeeeee22eeee000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000007e2e2e000eee77777eeeeeee000ee77eeeeee2eee000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000e2eee2000eee777eee22222200e7777eeeeeee2ee000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000e2eeee2e00eeeeee22277777e00e777eeeeeeeee2e000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000027eeeee200eeee2277777777770eeeeeeeeeeeeee0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000027ee2eee000ee277777777777ee22eeeeee222eee0000111110000000000000000700000000000000000
0000000000000000000000000000000000000000000077e2e2ee00002777777777eeeeeee2eeee2eee2ee0000111110000000000000000000000000000000000
000000000000000000000000000000000000000000007ee2ee2ee0007777777eeeeeeeeeee2eee2eeee2e0000011110000000000000000000000000000000000
000000000000000000000000000000000000000000077ee2ee2ee00eeeeeeeeeeeeeeeeeeee2ee2eeeee21000011110000000000000000000000000000000000
000000000000000000000000000000000000000000077e2eee2ee0eeeee22222222eeeeeeee2ee2eeeeee1110001100000000000000000000000000000000000
00000000000000000000000000000000000000000077ee2eee2ee022222eeeeeeee22eeeeee2ee2eee2ee1111001000001100000000000000000000000000000
0000000000000000000000000000000000000000007ee2eeeee2ddddddeeeeeeeeeee2eeeeee2ee2ee22ee111222220111100000000000000000000000000000
000000000000000000000000000000000000000000eee27eeedddddddddeeeeeeeeee2eeeeee2ee2ee22ee000222221111100000000000000000000000000000
000000000000000000000000000000000000000000ee2ee22ddddd5555ddeeeeeeeeee2eeeee2eee2e2e2ee00000011111100000000007000000000000000000
0000000000000000000000000000000000000000022e2e2ddddd55dddd5ddeeeeeeeee2eeeeeeeee2eee2ee00000000111100000000000000000000000000000
0000000000000000000000000000000000000000022222ddddd5ddddddddd2222eeeeee2eeeeeeee2eee2ee00011000000000000000000000000000000000000
00000000000000000000000000000000000000000222dddddd5dddddddddddeee2eeeee2eeeeeeeee22e2eee0111000000000000000000000000000000000000
000000000000000000000000000000000000000022dddddddddddddddddddd2eee2eeeeeeeeeeeeeeee2eeee1111100000000000000000000000000000000000
000000000000000000000000000000000000005555ddddddddddddd555dddd2eeee2eeeeeeeeeeeeeeeeeeee1111111000000000000000000000000000000000
0000000077000000000000000000000000000dd55ddddddddddddd55dddddddeeee2eeeeeee2226222eeeeeee111110000000000000000000000000000000000
000006007700000000000000000000000000dddddddd7e7dddddd55dddddddd2eeee2eeeee277eeeee2eeeeee000000000000000000000000000000000000000
000000000000000000000000000000000000dddddd77ee777dddd5ddddddddddeeee2eeee5777eeeeee2eeeeee000ddd00000000000000000000000000000000
00000000000000000000000000000000000ddddddd7ee77eedddd5ddd6dddddd2eeee2ee5e77eeeeeeee2eeeeee0ddddd0000000000000000000000000000000
00000000000000000000000000000000000ddddd77ee777e77dd55ddddd5ddddd2eee2e55e7eeeeeeeee2eeeeeedddddd0000000000000000000000000000000
00000000000000000000000000000000000ddddddee777ee77dd55ddddd5dddddd2222255eeeeeeeeeee222eee2ddddddd000000000000000000000000000000
0000000000000007700000000000000000ddddddde777ee777dd555dddd5dddddddddd555eeeeeeeeeee222222dddddddd000000000000000000000000000000
0000000000000007700000000000000070dddddddd7ee77eedddd555dd55dd5ddddddddd5eeeeeeeeeee55522ddddddddd000000000000000000000000000000
000000000000000000000000000000000dddddddddee77ee7dddd555555ddd5ddddddddddeeeeeeeeeeed5555dddddddddd00000000000000000000000000000
000000000000000000000000000000000ddddddddddd7eeddddddd5555dddd5ddddddddddeeeeeeeeeeeddddddddddddddd00000000000000000000000000000
00000000000000000000000000000000ddddddddddddffdddddddddddddddd5dddddddddddfeeeeeeefdddddddddddddddd00000000000000000000000000000
00000000000000000000000000000000ddddddddddddffdddddddddddddddd5ddddddddddd767f7f7f7ddddddddddddddddd0000000000000000000000000000
0000000000000000000000000000000dddddddddddd5ffddddddddddddddd5ddddddddddddd7f7f7f755dddddddddddddddd0000000000000000000000000000
0000000000000000000000000000000dddddddddddffff5dddddddddddddddddddddddddddddfffff5555dddddddddddddddd000000000000000000000000000
000000000000000000000000000000dddddddddddfffffff5ddddddddddddddddddddddddddddfff555555ddddddddddddddd000000000000000000000000000
00000000000000000000000000000ddddddddddddfffffff5555dddddddddddddddddddddddd5fff5555555ddddddddddddddd00000000000000000000000000
0000000000000000000000000000ddddddddddd55ffffffffffffff7f55555555dddddd555555fff5555555fffffff55ddddddd0000000000000000000000000
000000000000000000000000000ddfffff555555ffffffffffffffffffff7f5ffffffffff5555fff55555ffffffffffffff55ddd000000000000000000000000
0000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000007000000000000000
000000000000000000070000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000
00000000000000000000000000ff00000ff00fff00ff00000fff00000ff000000fffff000000ff00fff00ff00000ff00fff00fff000000000000000000000000
0000000000000000000000000000fffff00ff000ff00fffff0007ffff00ffffff00000ffffff00ff000ff00fffff00ff000ff000000000000000000000000000
000000000000000000000000000fffffff0ff000ff0fffffff0fffffff0fffffff0000fffffff0ff000ff0fffffff0ff000ff000000000000000000000000000
000000000000000000000000000ff000000ff000ff0ff000ff0ff000ff0ff000ff0000ff000ff0ff000ff0ff000000ff000ff000000000000000000000000600
00000000000000000000000000044444440440004404400000044444440444444000004444440044000440444444404444444000000000000000000000000000
00000000000000000000000000000000040440004404400444044000440440004400004400044044000440000000404400044000000000000000000000000000
00000000000000000000000000044444440444444404444044044000440440004400004400044044444440444444404400044000000000000000000000000000
00000000000000000000000000004444400044444000444444044000440440004400004400044007444400044444004400044000000000000000000000070000
00000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000002222200000002222200000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000022000220020022020220007070000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000022020220222027202220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000022000220020022020220000000000000000000000000000000000000000000007000000000
00000000000000000000000000000000000000000000000000000002222200000002222200000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000
00000000000000000000000000000000000000111011101100110010100000111010100110111001100110110000000000000000000000000000000000000000
00000000000000000000000000000000000000111010101010101010100000010010101010101010001010101000000000000000000000000000000000000000
00000000000000000000000000000000000000101011101010101011100000010011101010110011101010101000000000000000000000000000000000000000
00000000000000000000000000000000000000101010101010101000100000010010101010101000101010101700000000000000000000000000000000000000
00000000000000000000000000000000000000101010101110111011100000010010101100101011001100101000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000700
00000000000000000000000000000000000000000000110001101110100000001110111011101110101000000700000000000000000000000000000000000000
00000000000000000000000000000000000000000000101010101000100000001010100010101010101000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000101010101100100000001100110011001100111000000000000000000000700000000000000000000000
00000000000000000000000000000000000000000000101010101000100000001010100010101010001000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000101011001110111000001110111010101010111000000000000000000070000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000
00000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000fff00ff0ff000000fff0f0f00000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000fff0f0f0f0f00000f0f0f0f00000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000f0f0f0f0f0f00000ff00fff00000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000f0f0f0f0f0f00000f0f000f00000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000f0f0ff00fff00000fff0fff00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000022202020222020200000020000002220222022202220000002000000222022200220022000000200000002200220220022202200000000000000
00000000000020202020202020200000020000002220200020002020000002000000020020202000202000000200000020002020202020002020000000000000
00000000000022002020220022200000020000002020220022002220000002000000020022202000202000000200000020002020202022002020000000000000
00000000000020202020202000200000020000002020200020002000000002000000020020202000202000000200000020202020202020002020000000000000
00000000000020200220222022200000020700002020222022202000000002000000020020200220220000000200000022202200202022202020000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000200000012020202000000060606000000000000000000000000000000000000000000000000000000000000000000020202020203030303030303030303030300000000030303030303030303030303000000000303030303030303030303030000000003030303030303030303030300000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000606161755151515151515151515200000000000000616161616161616175515200000000006161616161755151515151515151515151515158515152120000000000000000001050000000000000001350515151515151515851515151515151517461616161616158517461620000000000000000000000
0000000000000000111111505874616161616161755200000000000000000000000000000050515200000000000000000000606161616161755851515151515158515152120000001010100000004077000a00000000001350515151587461615851515151515151746200000000000058746211110000000000000000000000
0000000000000000000000606162000000000000505200000000000000000000000000000060755200000000000000000000000000000000607551515151515151515152120000134041420000005051000000000000001350515174616200005151515151585151520000000000000051521100000000000010101000000000
0000000000000000000000111111000000000000505200000000000000000000000000000011505200000000000001000000000000000000005058585151515151746162120000135051520000005051000000000000001350746162000000005174616161617551520000000000000061620000000000001340414200000000
000000000000000000000000000000000000000050520000000000003c0000000000000000004a620000003b0041414200003d003f000000005051585151515174620000000900006075520000005051000000001400001360620000000000007462000000006061620000000000000011110000000000001350517642003e00
0000000000000000000000000000000000000000505200000000004041000000003f000000006311000000404151517641414141414200000050515858515151520000000000000000505200000060610000000000000000111100000000000062110000000011111100000000003d0000000000000000001350515176414141
0000000000000000000000101010404200000000505200000040417751000000004042000000110000000050515174616161617551520000005051515151515862000000001400000050520000001111000000000000000000000000000000001100000000000000000000000013404100000000000900001350515151515151
0000000000003f000000004041417752000000004a62000000505151510001000050520000000000000000505151520000000060614b0000005051515151515100000000000000000050520000000000000000000000000000000000000000400000000000000000000000000013505100000000000000001350515158515151
000000000040414200000050515151520000000063110009005051515141420000505200000014000000005051515200000900000063000000505151746161610000000000000000005052000900000000000000000000000014000000003f500000000000000015000000000013505100000000000000001350515151515151
00000000006061620000005051515152000000001100000000505151515152000060620000000000000000505151520000000000000014000050746162000000000000000000000000604b0000001010000000000000000000000000000040770000000000000000000000000013505100000000002500001360755151515151
0000000000000000000000505151515200000000000000000050585151515200000000000000000000000050515152000010000000000000005052000000000000000000000000000013531000004041000000000000000000000000000050510000000000000000000000000013505100000000000000000013505851515151
000000000000000000000050585151523b000000000000000050515151616200000000000000000000000050515152000043000000000000004a620000000000000000000000000000135a4200005051000000001400000000000000000060750000000000001010100000000013505100000000000000000013505158515151
0000000000000000003e005051515176414200000009000000505851510000000000000000003e00000000505151520000531010101010101053000000003e0000000000000000000013505200005051000000000000000000000000000013500001003b003c4041423a3e3f0013505100000000000000000013505851515151
0000000100003e00004041775151515174620000000000000050515151000000003d3c00404141414141417751515200005a4141414141416a660000000040413c013b0000000000101050521000505100000000000000000000000000001350414141414141775176414141414177510001003d000000000013505151515151
414141414141414141775151515158746212000000000000407751515141414141414141775151515151515851515200006061616161616162000000000050514141420000001010404177764210505101003e000000000000000000000013505151585151515151515151515151585141414142120000000013505151515851
5151515151515151515151515851515212000000000000005051515858515151515151515151515151585151515152000000000000000000140000000000505151515200000040417751515176417751414142120000000000000000000013505151515151515151515151515851515151515152120000000013505158515151
5851515151515151515151515151515158515151515151515151515151515151515151515174616161616161615852000000000000000000000000000000505158746161616175521200000000000000000060755174616161755151515151510000000000000000000000000000000000000000000000000000000050515151
5851515151515151746161616161616158746161617551746161616161616161616161757462000000000000005152000000000000090000000000004041775158520000000050521200000000003f00000000505152111111505151585151510000000000000000000000000000000000000000000000000000000050515151
5151515151746161621111111111111174620000005074620000000011111111110000604b00000000000000005152000000000010101010101010105051515151520000000050521200000000404141000000507462000000505151515151510000000000000000000000000000000000000000000000000000000050515151
515174616162111111000000000000005200000000604b00000000000000000000000000530000000000003b005152000000000040414141414141417751515851520001000050521200000040775851000000606211000a00505151515858510000000000000000000000000000000000000000000000000000000050585851
517462111111000000000000000000005201000000005300000000001010101010000000531819000013404141585151517461616212000000000000000000005152181900005052120000004a617551000000111100000000606161616175510000000000000000000000000000000000000000000000000000000050515851
5152110000000000000000000000000062181900000053000000000040414141420000005300000000135051515851517462111111000000000000000000000074620000000050521200000053245058000000240000000000111111111160750000000000000000000000000000000000000000000000000000000050515858
515200000000000000000000000000000000000000005300000017186061616162000000530000000013607551515151521200000000000000000000000000005212000000005052120000005a417751000000000000000000000000000011500000000000000000000000000000000000000000000000000000000050515151
51521000000000140000000000150000000000000000630000000000111111111100000063000000000013505151515152120014000000007071716b414141416212000000005052120000005051515100000000000000000000000000000050000000000000000000000000000000000000000000000000000c000050515151
517642100000000000000000000000000000000000001100000000000000000000000000110000000000135051515151521200000000000011111160755151510000000000005052120000004a617551000000000000000000000000000000500000000000000000000000000000000000000000000000404141414177515151
5151764212000000000000000000000000000000000024000000000000000000000000002400000000001350515151517642101010000000000000135051515100000000000050521200000053245051000000101010000000100024000000500000000000000000000000000000000000000000000000505151585151515151
515151521200000000001010101010100000000000000000000000000000000000000000000000000000135051515151515971717200000000150013505151580000000000005052120000005a417751000013707172120013731200000000500000000000000000000000000000000000000000000000505851515851515151
51585152120000000013404141414141100000000000000000000000000000000000000000000000000013607551515174621111110000000a0000135051515100000000000060621200000050515151000000111111000000110000000000500000000000000000000000000000000000000000001718505151515158515151
515151521200000000135058515151514210000000000000000000000000000000000000000000000000001350515851521200000000000010101040775151510000000000001111000000004a617551000000000000000000000000000010500000000000000000000000000000000000000000000000505158515851515151
515174621200000000136075515151517642120000000000000000000000000000000000000000000000001350515151521200140000000070717157515851510000000000000000000000005324505100000000000000000010101010104077000000000000000000000000000000000001003d003d00505151585151515151
517462110000000000000050515158515152120000000000000000000000000000000000000000000000001350515151521200000000000011111160755151510000000000000000000000005a417751000000000000013e00404141414177510000000000000000000000000000000041414141414141775151515151515851
6162110000000000000000505851515151521200000000000000000000000000000000000000000000000013505158517642101010000000000000135051515100000000000000000000000050515151000000000017404141775151585151510000000000000000000000000000000051515151515151515151515158515151
__sfx__
001000002d0502d00032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
0001000036270342702e2702a270243601d360113500a3400432001300012001d1001010003100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000641008410094100b410224302a4403c6403b6403b6403964036640326402d6402864024630216301d6301a63016620116200e6200b61007610056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
0010000021610206101e6101b610196101561012610116100f6100e6100d6100c6100c6100c6100c6100d6100e6100f610106101161013610156101661017610196101b6101d6101e61020610216102261022610
00050000212731e273132730a25300223012033b203282033f2032f203282031d2031020303203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203
000800000c3730c3730c3730c3730c3730c3730c3730d3730f3731137313373173731a37320373263732e37333373393733d3733e3733f3733c3733e3733d3733e3733b3733e3733c3733f3633b3533e3333f313
010400002f45032450314502e4502f4503045000000000002f400324002f45032450314502e4502f4503045030400304000000000000000000000000000000000000000000000000000000000000000000000000
010e00000070000700007000070021750217501e7501e75021750217501e7501e7502175021750007000070021750217502175521705217051d7501e7511e7510070000700007000070000700007000070000700
010e00000b5300b5300b5300b5300b5300b53517500175050b5300b5350b5300b5350b5300b5350b5300b53509530095300953009530095300953500500005000953009535095300953509530095350953009535
010e00000753007530075300753007530075351710017105075300753507530075350753007535376103762502530025300253002530025300253500100001000253002535025300253502530025353261032625
010e00000070000700007000070021750217501e7501e75021750217501e7501e750217502175000700007001c7501c7501d7001e7001e70000700197501975018700007001a7501a750007001c7501c75000700
010e00000e5300e5300e5300e5300e5300e53517500175050e5300e5350e5300e5350e5300e5350e5300e5350d5300d5300d5300d5300d5300d53500500005000d5300d5350d5300d5350d5300d5350d5300d535
010e00000b5300b5300b5300b5300b5300b53517100171050b5300b5350b5300b5350b5300b5353b6103b62509530095300953009530095300953500100001000953009535095300953509530095353961039625
010e00001e7501e750007000070021750217501e7501e75021750217501e7501e7502175021755217502175521750217502175521705217051d7501e7511e75118700007001a7001a700007001c7001c70000700
010e00000070000700007000070021750217501e7501e75021750217501e7501e750217502175000700007001c7501c7501d7001e7001d7001e7001c7501c750007001d7001e7501e750007001c7501c75000700
010e00001a7501a750007000070023750237552375023755237502375521750217552175021755217502175521750217552375023755237502375523750237552375023755217502175521750217550070000700
010e00000070000700007000070023750237552375023755237502375521750217552175021755217502175521750217551e7501e7501c7501c750197501975000700007001a7501a750007001c7501c75000700
010e00001e7501e75000700007002170021700217502175021700217001e7001e7001c7501c75000700007000070000700007000070021700217001f7001f70021700217001f7001f70021700217000070000700
010e00000e5300e5300e5300e5300e5300e53517500175050e5300e5350e5300e5350e5300e5350e5300e5350d5300d5300d5300d5300d5200d51500500005000d5000d5000d5000d5000d5000d5000d5000d500
010e00000b5300b5300b5300b5300b5300b53517100171050b5300b5350b5300b5350b5300b5353b6103b62509530095300953009530095200951539610396250910009100396103962539610396253961039625
010e00001573015730007000070012730127300070000700157301573515730157301273012730007000070017730177301573015730177301773015730157301773017730157301573515730157351573015730
010e000009030090300903009030090300903500000000000b0300b0350b0300b0350b0300b0350b0300b0350e0300e0300e0300e0300e0300e03500000000000d0300d0350d0300d0350d0300d0350d0300d035
010e0000020300203002030020300203002035000000000004030040350403004035040300403534610346250b0300b0300b0300b0300b0300b03500000000000903009035090300903509030090353961039625
010e00002673026735267302673526730267352673226732267322673500000000000000000000000000000026730267352673026735267302673526732267322673226735000000000000000000000000000000
000e0000260322603200002000022a0322a0322803228032000020000226032260322a0322a0322803228032260322603200002000022a0322a0320000200002000020000226032260322b0322b0322a0322a032
000e0000260322603200002000022a0322a0322803228032000020000226032260322a0322a0322803228032260322603526032260322a0322a0320000200002280322803228022280152b0002b0002a0002a000
010d00000c0530445504255134453f6150445513245044550c0531344513245044553f6150445513245134450c0530445504255134453f6150445513245044550c0531344513245044553f615044551324513445
010d00000c0530045500255104453f6150045510245004550c0530044500245104553f6150045510245104450c0530045500255104453f6150045510245004550c0531044510245004553f615004551024500455
010d00000c0530245502255124453f6150245512245024550c0531244512245024553f6150245502255124450c0530245502255124453f6150245512245024550c0530244512245024553f615124550224512445
010d00002b5552a4452823523555214451f2351e5551c4452b235235552a445232352d5552b4452a2352b555284452a235285552644523235215551f4451c2351a555174451e2351a5551c4451e2351f55523235
010d000028555234452d2352b5552a4452b2352f55532245395303725536540374353b2503954537430342553654034235325552f2402d5352b2502a4452b530284552624623530214551f24023535284302a245
010d00002b5552a45528255235552b5452a44528545235452b5352a03528535235352b0352a03528735237352b0352a03528735237351f7251e7251c725177251f7151e7151c715177151371512715107150b715
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0102000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00100000326003260032600326003160031600306002e6002a600256001b600136000f6000d6000c6000c6000c6000c6000c6000f600146001d600246002a6002e60030600316003360033600346003460034600
00400000302053020530205332052b20530205302053020530205302053020530205302053020530205302052b2052b2052b20527205292052b2052b2052b2052b2052b2052b2052b2052b2052b2052b2052b205
__music__
01 14151644
00 17181944
00 1a151644
00 1b181944
00 1c151644
00 1d181944
00 14151644
00 1e1f2044
00 21222344
00 24222344
00 21222344
00 24222344
00 25222344
02 26222344
01 27424344
00 28424344
00 29424344
00 27424344
00 272a4344
00 282a4344
00 292b4344
02 272c4344
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

