-- Deterministic hit gate used by the real server and regression tests.
local R={}
function R.hit(target,key,now,immunity)
 if now<(target.shield or 0) and (target.shieldHits or 0)>0 then
  target.shieldHits=0;target.shield=0;return 'shield'
 end
 if key=='tag' then
  if now<(target.tagImmune or 0) then return 'immune' end
  target.tagImmune=now+2
 else
  if now<(target.immune or 0) then return 'immune' end
  target.immune=now+immunity
 end
 return 'hit'
end
return R
