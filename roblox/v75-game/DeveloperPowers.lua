-- Server-only Royal Seal. All hits use the existing shield, immunity and loot ledger.
local M={}
local WINDUP,RADIUS,MAX_DISTANCE=.65,18,24
local GOLD=Color3.fromRGB(255,210,98)
local function finiteVector(v)
 return typeof(v)=='Vector3' and v.X==v.X and v.Y==v.Y and v.Z==v.Z
  and math.abs(v.X)<100000 and math.abs(v.Y)<100000 and math.abs(v.Z)<100000
end
function M.cast(phase,admin,player,rodOrigin)
 if not admin or not admin:authorized(player) then return false,'Access denied.' end
 local ready,root=admin:readyForMods(player)
 if not ready then return false,root end
 local ctx=phase.ctx
 if not ctx.config.EnablePowers then return false,'Powers are disabled.' end
 local runtime=ctx.runtime[player.UserId]
 if not runtime or not ctx.movementSafe(player) then return false,'Character movement unavailable.' end
 local origin=root.Position
 if not finiteVector(rodOrigin) or (rodOrigin-origin).Magnitude>12 then rodOrigin=origin+Vector3.new(0,1,-1) end
 local direction=root.CFrame.LookVector
 runtime.castSerial=(runtime.castSerial or 0)+1
 local serial=runtime.castSerial
 ctx.fx:FireAllClients('developerRoyalSeal',origin,RADIUS,'Royal Seal',WINDUP,GOLD,player.UserId,.85,direction,rodOrigin)
 task.delay(WINDUP,function()
  local state=phase.core.players[player.UserId]
  local current=ctx.body(player)
  if not admin:authorized(player) or ctx.runtime[player.UserId]~=runtime or runtime.castSerial~=serial
   or not state or state.carry or state.pending or not current or current~=root
   or (current.Position-origin).Magnitude>7 or not ctx.movementSafe(player)
   or os.clock()<(runtime.shockUntil or 0) or os.clock()<(runtime.interruptedUntil or 0) then return end
  local now=os.clock()
  for id,target in pairs(ctx.runtime) do
   if id~=player.UserId then
    local targetRoot=ctx.body(target.player)
    if targetRoot and (targetRoot.Position-origin).Magnitude<=math.min(RADIUS,MAX_DISTANCE)
     and ctx.los(origin,targetRoot.Position) then
     local previous=target.shockUntil
     phase:hitPower(player.UserId,target,'lightning',origin,now)
     -- A blocked hit never drops an item. Only a newly applied stun can release it.
     if target.shockRoot==targetRoot and target.shockUntil~=previous and (target.shockUntil or 0)>now then
      phase:finish(target.player,false,'Royal Seal knocked the item loose. Your reservation was returned safely.')
     end
    end
   end
  end
  ctx.fx:FireAllClients('developerRoyalSeal',origin,RADIUS,'Royal Seal',nil,GOLD,player.UserId,.85,direction,rodOrigin)
  ctx.refresh()
 end)
 return true,'Royal Seal cast. Nearby unshielded carriers are briefly stopped and release their loot.'
end
return M
