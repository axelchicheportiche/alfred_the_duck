pico-8 cartridge // http://www.pico-8.com
version 38
__lua__


--page 0
--variables

function _init()
  player={
    sp=1,
    x=59,
    y=59,
    w=8,
    h=8,
    flp=false,
    dx=0,
    dy=0,
    max_dx=2,
    max_dy=3,
    acc=0.5,
    boost=4,
    anim=0,
    running=false,
    jumping=false,
    falling=false,
    sliding=false,
    landed=false,
    leek=0,
    lives=5
  }

  gravity=0.3
  friction=0.85

  --simple camera
  cam_x=0

  --map limits
  map_start=0
  map_end=1024

  --bullets
  ibullets()

  --enemies:
 	ienemies()
end

-- page 1

--update and draw

function _update()
  player_update()
  player_animate()

  --simple camera
  cam_x=player.x-64+(player.w/2)
  if cam_x<map_start then
     cam_x=map_start
  end
  if cam_x>map_end-128 then
     cam_x=map_end-128
  end
  camera(cam_x,0)
  --bullets
	--	ibullets() a virer
		ubullets()
	--enemies:
		uenemies()

end

function _draw()
  cls(12)
  map(0,0)
  spr(player.sp,player.x,player.y,1,1,player.flp)
		--bullets
		ubullets()
		dbullets()
		--enemies
			uenemies()
			denemies()


end

-- page 2
--collisions

function collide_map(obj,aim,flag)
  --obj = table needs x,y,w,h
  --aim = left,right,up,down

  local x=obj.x  local y=obj.y
  local w=obj.w  local h=obj.h

  local x1=0	 local y1=0
  local x2=0  local y2=0

  if aim=="left" then
    x1=x-1  y1=y
    x2=x    y2=y+h-1

  elseif aim=="right" then
    x1=x+w-1    y1=y
    x2=x+w  y2=y+h-1

  elseif aim=="up" then
    x1=x+2    y1=y-1
    x2=x+w-3  y2=y

  elseif aim=="down" then
    x1=x+2      y1=y+h
    x2=x+w-3    y2=y+h
  end

  --pixels to tiles
  x1/=8    y1/=8
  x2/=8    y2/=8

  if fget(mget(x1,y1), flag)
  or fget(mget(x1,y2), flag)
  or fget(mget(x2,y1), flag)
  or fget(mget(x2,y2), flag) then
    return true
  else
    return false
  end

 end


 -- page 3

 --player


function player_update()
  --physics
  player.dy+=gravity
  player.dx*=friction

  --controls
  if btn(⬅️) then
    player.dx-=player.acc
    player.running=true
    player.flp=true
  end
  if btn(➡️) then
    player.dx+=player.acc
    player.running=true
    player.flp=false
  end

		--shoot
		if btnp(🅾️) then
			shoot(player.dx)
		end


  --slide
  if player.running
  and not btn(⬅️)
  and not btn(➡️)
  and not player.falling
  and not player.jumping then
    player.running=false
    player.sliding=true
  end

  --jump
  if btnp(❎) and player.landed then
    player.dy-=player.boost
    player.landed=false
  end

  -- double jump or flying
 -- if btnp(❎) and player.jumpcount<2 then
 -- player.dy-=player.boost
 -- player.landed=false
 -- player.jumpcount+=1
--end

  --check collision up and down
  if player.dy>0 then
    player.falling=true
    player.landed=false
    player.jumping=false

    player.dy=limit_speed(player.dy,player.max_dy)

    if collide_map(player,"down",0) then
      player.landed=true
      player.falling=false
      player.dy=0
      player.y-=((player.y+player.h+1)%8)-1
    end
  elseif player.dy<0 then
    player.jumping=true
    if collide_map(player,"up",1) then
      player.dy=0
    end
  end

  --check collision left and right
  if player.dx<0 then

    player.dx=limit_speed(player.dx,player.max_dx)

    if collide_map(player,"left",1) then
      player.dx=0
    end
  elseif player.dx>0 then

    player.dx=limit_speed(player.dx,player.max_dx)

    if collide_map(player,"right",1) then
      player.dx=0
    end
  end

  --stop sliding
  if player.sliding then
    if abs(player.dx)<0.2
    or player.running then
      player.dx=0
      player.sliding=false
    end
  end

  player.x+=player.dx
  player.y+=player.dy

  --limit player to map
  if player.x<map_start then
    player.x=map_start
  end
  if player.x>map_end-player.w then
    player.x=map_end-player.w
  end
  interract(player.x,player.y)
end

function player_animate()
  if player.jumping then
    player.sp=7
  elseif player.falling then
    player.sp=8
  elseif player.sliding then
    player.sp=9
  elseif player.running then
    if time()-player.anim>.1 then
      player.anim=time()
      player.sp+=1
      if player.sp>6 then
        player.sp=3
      end
    end
  else --player idle
    if time()-player.anim>.3 then
      player.anim=time()
      player.sp+=1
      if player.sp>2 then
        player.sp=1
      end
    end
  end
end

function limit_speed(num,maximum)
  return mid(-maximum,num,maximum)
end

-- page 4

--map

function next_tile(x, y, sp)
  mset(x, y, sp + 1)
end

function pick_up_leek(x,y,sp)
  next_tile(x, y, sp)
  player.leek+=1
  --sfx(effetsonore)
end


-- page 5

--interaction

------interact_leek
function check_flag(flag,x,y)
  --printh("check_flag_","alfred_the_duck_log", false, true)
      local sp=mget(x,y)
    --	printh("sprite :"..sp,"alfred_the_duck_log", false, true)
      return fget(sp,flag)
  end


  function interract(x,y)
    --	printh("interract_start","alfred_the_duck_log", false, true)
      local tx = flr(x / 8)
      local ty = flr(y / 8)

     -- printh(x .. "," .. y,"alfred_the_duck_log", false, true)
     -- printh(tx .. "," .. ty,"alfred_the_duck_log", false, true)

     -- printh("flag 2:"..tostring(check_flag(2, x, y)),"alfred_the_duck_log", false, true)
     -- printh("flag 3:"..tostring(check_flag(3, x, y)),"alfred_the_duck_log", false, true)
      if check_flag(2, tx, ty) then
              local sp = mget(tx,ty)
          pick_up_leek(tx,ty,sp)
      end
   -- printh("interract_end","alfred_the_duck_log", false, true)
  end


  --gestion lives
  function player_hit()
    lives = lives-1
  end



  -- page 6

  --bullets

function ibullets()
  --	printh(buls[],"alfred_the_duck_log", false, true)
    buls={}
  end


  function ubullets()
    --	printh("enter_ubullets","alfred_the_duck_log", false, true)

      for b in all(buls) do
    --	printh("enter_ibullets_for","alfred_the_duck_log", false, true)

      b.x=b.x+1
      end

  end

  --draw bullets
  function dbullets()
      printh("enter_dbullets","alfred_the_duck_log", false, true)

      for b in all(buls) do
      spr(12,b.x,b.y)

      end
  end


  function shoot(x,y)

    add(buls,{
    x=player.x,
    y=player.y,
    spd=2})
  --	printh(,"log_bullet", false, true)

  end

  -- page 7

  --enemies

function ienemies()
  walking_enemies = {
{x=0,
 y=80,
 dx=1,
 dist=0,
 max_dist=128},

 {x=32,
 y=80,
 dx=1,
 dist=0,
 max_dist=128}
}
end


function uenemies()
 for e in all(walking_enemies) do
    e.x += e.dx
    e.dist += e.dx
    if (e.dist >= e.max_dist or e.dist <= 0) e.dx = -e.dx
end
-- check for collisions with player
--if check_collision(player.x, player.y, 8, 8, e.x, e.y, 8, 8) then
  --player_hit()
--end
end

function denemies()
for e in all(walking_enemies) do
spr(17,e.x,e.y)
end
end
