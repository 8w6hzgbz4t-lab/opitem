-- Execute actual rod/seal client effects with controlled Tween/Debris services.
local Mock=dofile('tools/roblox_mock.lua')
local now,tweens,removals=0,{},{}
local signal={listeners={}}
function signal:Connect(callback)
 local connection={Connected=true,callback=callback}
 function connection:Disconnect()self.Connected=false end
 self.listeners[#self.listeners+1]=connection;return connection
end
function signal:Fire(...)for _,c in ipairs(self.listeners)do if c.Connected then c.callback(...)end end end
local services={
 TweenService={Create=function(_,part,info,goal)
  local record={part=part,info=info,goal=goal};tweens[#tweens+1]=record
  return {Play=function()record.played=true end}
 end},
 Debris={AddItem=function(_,part,lifetime)removals[#removals+1]={part=part,expires=now+lifetime}end},
}
game={GetService=function(_,name)return assert(services[name],name)end}
TweenInfo={new=function(lifetime)return {Time=lifetime}end}
workspace=Instance.new('Folder');workspace.Name='Workspace'
workspace.CurrentCamera={CFrame=CFrame.new(0,8,0)}
local player=Instance.new('Folder');player.Name='TestPlayer'
local gui=Instance.new('Folder',player);gui.Name='PlayerGui'
local fx=Mock.loadModule((arg[1]or'roblox/v75-game')..'/DeveloperEffects.lua')
local session=fx.start({FX={OnClientEvent=signal}},player)
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function parts()
 local result={};for _,part in ipairs(workspace:GetDescendants())do if part:IsA('BasePart')then result[#result+1]=part end end;return result
end
local function clear()
 now=now+2
 for _,record in ipairs(removals)do if now>=record.expires and record.part.Parent then record.part:Destroy()end end
 check(#parts()==0,'Short-lived effects must be removable through Debris')
 table.clear(tweens);table.clear(removals)
end
local function safe()
 local count=#parts();check(count>0 and count<=80,'Each cast has a bounded nonempty native effect')
 for _,part in ipairs(parts())do
  check(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,'Client effects cannot affect physics or queries')
  for _,value in ipairs({part.CFrame:GetComponents()})do check(value==value and math.abs(value)<10000,'Effect transform remains finite')end
 end
 for _,record in ipairs(tweens)do check(record.played and record.goal.Transparency==1,'Every effect must fade out')end
 check(#removals==count,'Every visual part must have a Debris lifetime')
 return count
end
local origin=Vector3.new(0,4,-10);local rod=Vector3.new(1,5,-1)
signal:Fire('tag',origin,7,'Tag');check(#parts()==0,'Ordinary player effects must not gain developer cosmetics')
signal:Fire('shield',origin,3,'Shield',nil,nil,77,3,nil,rod)
local normalRod=safe();check(parts()[1].Name=='MillenniumRodLight','A developer cast starts at the rod origin')
local beam=parts()[1];check((beam.Position-(rod+origin)*.5).Magnitude<1e-6,'Rod beam connects to its real target center')
check(math.abs(beam.Size.Z-(origin-rod).Magnitude)<1e-6,'Beam length matches the rod-to-target distance')
clear()
signal:Fire('developerRoyalSeal',origin,18,'Royal Seal',.65,nil,77,.85,nil,rod)
local normalWarning=safe();check(normalWarning>normalRod,'Royal Seal has a visible warning boundary');clear()
signal:Fire('developerRoyalSeal',origin,18,'Royal Seal',nil,nil,77,.85,nil,rod)
local normalImpact=safe();check(normalImpact>normalWarning,'Seal impact adds its eye and rune details');clear()
gui:SetAttribute('OPReducedEffects',true)
signal:Fire('developerRoyalSeal',origin,18,'Royal Seal',.65,nil,77,.85,nil,rod)
local reducedWarning=safe();check(reducedWarning<normalWarning,'Reduced effects preserve a simpler visible warning');clear()
signal:Fire('developerRoyalSeal',origin,18,'Royal Seal',nil,nil,77,.85,nil,rod)
check(safe()<normalImpact,'Reduced effects create fewer impact parts');clear()
workspace.CurrentCamera.CFrame=CFrame.new(1000,0,0)
signal:Fire('developerRoyalSeal',origin,18,'Royal Seal',nil,nil,77,.85,nil,rod)
check(#parts()==0 and #tweens==0,'Distant effects must be culled before allocation')
workspace.CurrentCamera.CFrame=CFrame.new(0,8,0)
signal:Fire('developerRoyalSeal',{X=0,Y=0,Z=0},18)
check(#parts()==0,'Malformed origins must fail without creating geometry')
session.destroy();signal:Fire('shield',origin,3,'Shield',nil,nil,77,3,nil,rod)
check(#parts()==0 and not signal.listeners[1].Connected,'Cleanup disconnects effects and removes the folder')
local report={passed=true,assertions=checks,normal_rod_parts=normalRod,normal_warning_parts=normalWarning,normal_impact_parts=normalImpact,
 reduced_warning_parts=reducedWarning,finite_noninteractive_geometry=true,debris_cleanup_verified=true,distant_culling_verified=true,
 actual_module='DeveloperEffects.lua',studio_rendering_tested=false}
local file=assert(io.open(arg[2]or'/tmp/opitem-v75-effects.json','w'));file:write(Mock.json(report));file:close()
print('PASS '..checks..' developer visual assertions; actual rod rays, seal warnings/impact, reduced effects, bounds and cleanup')
