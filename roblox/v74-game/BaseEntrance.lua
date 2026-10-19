-- Server-only spatial helper shared by automatic delivery and the protection line.
local E={}
function E.contains(baseCF,position)
 if not baseCF or not position then return false end
 local p=baseCF:PointToObjectSpace(position)
 -- Extra depth makes crossings reliable at carry speed without a precise touch event.
 if p.Y<.5 or p.Y>11 then return false end
 local entrance=math.abs(p.X)<=23 and p.Z>=-26 and p.Z<=-16
 local originalPad=math.abs(p.X)<=6 and p.Z>=-20 and p.Z<=-12
 return entrance or originalPad
end
function E.activate(core,playerId,baseOwner,now)
 if playerId~=baseOwner then return false end
 local player=core.players[playerId]
 if not player or now<player.lockReady then return false end
 return core:protect(playerId,now)
end
return E

