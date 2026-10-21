-- Server-owned Superman pose without rotating forces or gyroscopes.
local M={}
function M.apply(player,m,root,direction)
 if not root or not m.flight then return end
 if direction and direction.Magnitude>.1 then m.flightFacing=direction.Unit end
 local heading=m.flightFacing or Vector3.new(0,0,-1)
 local up=math.abs(heading:Dot(Vector3.yAxis))>.95 and Vector3.zAxis or Vector3.yAxis
 local right=heading:Cross(up).Unit
 -- The character's head points along travel and the torso faces downward.
 root.AssemblyAngularVelocity=Vector3.zero
 root.CFrame=CFrame.fromMatrix(root.Position,right,heading,right:Cross(heading))
 m.flightJoints=m.flightJoints or{}
 local character=player.Character
 if character then for _,joint in ipairs(character:GetDescendants())do
  if joint:IsA('Motor6D')and(joint.Name=='RightShoulder'or joint.Name=='LeftShoulder'or joint.Name=='Right Shoulder'or joint.Name=='Left Shoulder'or joint.Name=='Neck')then
   local original=m.flightJoints[joint]
   if not original then original=joint.C0;m.flightJoints[joint]=original end
   local angle=joint.Name=='Neck'and math.pi/2 or math.pi
   joint.C0=CFrame.new(original.Position)*CFrame.Angles(angle,0,0)*original.Rotation
  end
 end end
 player:SetAttribute('OPDeveloperFlying',true)
end
function M.stop(player,m,root)
 if not m.flightFacing and not m.flightJoints then player:SetAttribute('OPDeveloperFlying',nil);return end
 for joint,original in pairs(m.flightJoints or{})do if joint.Parent then joint.C0=original end end
 m.flightJoints=nil
 if root and root.Parent then
  local direction=m.flightFacing or Vector3.new(0,0,-1)
  local flat=Vector3.new(direction.X,0,direction.Z)
  if flat.Magnitude<.01 then flat=Vector3.new(0,0,-1)end
  root.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit)
  root.AssemblyAngularVelocity=Vector3.zero
 end
 player:SetAttribute('OPDeveloperFlying',nil)
end
return M
