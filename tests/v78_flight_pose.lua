local Mock=dofile('tools/roblox_mock.lua')
local rootPath=arg[1]or'roblox/v78-game'
local Flight=Mock.loadModule(rootPath..'/FlightPose.lua')
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function near(a,b,msg)check((a-b).Magnitude<.00001,msg)end
for _,rig in ipairs({'R6','R15'})do
 local player=Instance.new('Folder');local character=Instance.new('Model');player.Character=character
 local root=Instance.new('Part',character);root.Name='HumanoidRootPart';root.CFrame=CFrame.new(0,5,0)
 local torso=Instance.new('Part',character);torso.Name='UpperTorso'
 local originals={};local neck
 for _,name in ipairs(rig=='R6'and{'Right Shoulder','Left Shoulder','Neck'}or{'RightShoulder','LeftShoulder','Neck'})do
  local motor=Instance.new('Folder',torso);motor._class='Motor6D';motor.Name=name
  motor.C0=CFrame.new(name=='Neck'and Vector3.new(0,1,0)or Vector3.new(1,.5,0))
  originals[motor]=motor.C0;if name=='Neck'then neck=motor end
 end
 local m={flight=true,flightFacing=Vector3.new(0,0,-1)}
 for _,heading in ipairs({Vector3.new(0,0,-1),Vector3.new(1,.7,.3),Vector3.new(0,1,0),Vector3.new(0,-1,0),Vector3.new(-1,0,0)})do
  root.AssemblyAngularVelocity=Vector3.new(10,6,3)
  Flight.apply(player,m,root,heading*42)
  near(root.CFrame.UpVector,heading.Unit,rig..' body/head axis points along actual flight')
  near((root.CFrame.Rotation*neck.C0.Rotation).LookVector,heading.Unit,rig..' face looks in the flight direction')
  near(root.AssemblyAngularVelocity,Vector3.zero,'No angular inertia remains')
  check(player:GetAttribute('OPDeveloperFlying')==true,'Server publishes cosmetic pose flag')
  for joint in pairs(originals)do if joint~=neck then
   near((root.CFrame.Rotation*joint.C0.Rotation):VectorToWorldSpace(Vector3.new(0,-1,0)),heading.Unit,'Arms extend toward travel')
  end end
 end
 local last=m.flightFacing;Flight.apply(player,m,root,Vector3.zero);near(m.flightFacing,last,'Hover keeps last heading')
 Flight.stop(player,m,root)
 for joint,original in pairs(originals)do
  local a={joint.C0:GetComponents()};local b={original:GetComponents()}
  for i=1,12 do check(math.abs(a[i]-b[i])<.00001,'Landing restores original joint transform')end
 end
 near(root.CFrame.UpVector,Vector3.yAxis,'Landing restores upright character')
 check(player:GetAttribute('OPDeveloperFlying')==nil and m.flightJoints==nil,'Landing clears pose artifacts')
end
local output=arg[2]or'/tmp/opitem-v78-flight-pose.json'
local file=assert(io.open(output,'w'));file:write(Mock.json({passed=true,assertions=checks,rigs={'R6','R15'},actual_module='FlightPose.lua',studio_physics_tested=false}));file:close()
print('FLIGHT POSE PASS '..checks..' assertions; R6/R15 face, arms, vertical travel, hover and restore')
