-- Movie-style AllSpark: six engraved mechanical faces, all native Roblox parts.
-- The glyphs are fitted physical strokes, with no decals or external asset IDs.
local M={}
local V,C,A,RGB=Vector3.new,CFrame.new,CFrame.Angles,Color3.fromRGB
local METAL,NEON=Enum.Material.Metal,Enum.Material.Neon
local PI=math.pi

-- Angular Cybertronian-inspired reliefs. Six distinct glyphs contain four strokes
-- each; their face-specific orientation makes every side different and readable.
local glyphs={
 {{-.34,.10,-.04,.28},{-.04,.28,.31,.04},{-.04,.28,-.13,-.29},{-.13,-.29,.28,-.14}},
 {{-.32,.28,.26,.13},{.26,.13,-.18,-.12},{-.18,-.12,.18,-.30},{-.07,.20,-.07,-.19}},
 {{-.33,-.23,-.18,.27},{-.18,.27,.32,.08},{.32,.08,.12,-.29},{-.04,-.01,.31,-.15}},
 {{-.29,.28,-.10,-.25},{-.10,-.25,.30,-.09},{.30,-.09,.12,.26},{-.04,.05,.31,.11}},
 {{-.31,.04,.02,.29},{.02,.29,.30,-.23},{.30,-.23,-.24,-.11},{-.24,-.11,-.06,.06}},
 {{-.30,.25,.23,.13},{.23,.13,.06,-.30},{-.30,-.22,.06,-.30},{-.11,-.05,.29,.04}},
}

function M.build(b,key)
 if key~="transformers_allspark" then return false end
 local core=RGB(57,53,43)
 local bronze=RGB(153,139,111)
 local silver=RGB(174,170,148)
 local relief=RGB(199,186,153)
 local dark=RGB(74,69,54)
 local recess=RGB(116,108,86)
 local cyan=RGB(76,164,177)
 -- The body is closed; six slightly inset armour panels meet twelve diagonal
 -- edge rails. Diamond cross sections give the rails true chamfered corners.
 b:box("AllSparkClosedMetalCore",V(2.91,2.91,2.91),C(),core,METAL)
 local n=0
 for _,s in ipairs({-1,1}) do for _,t in ipairs({-1,1}) do
  n=n+1
  b:box("ChamferedXEdge"..n,V(2.94,.132,.132),C(0,s*1.474,t*1.474)*A(PI/4,0,0),silver,METAL)
  b:box("ChamferedYEdge"..n,V(.132,2.94,.132),C(s*1.474,0,t*1.474)*A(0,PI/4,0),silver,METAL)
  b:box("ChamferedZEdge"..n,V(.132,.132,2.94),C(s*1.474,t*1.474,0)*A(0,0,PI/4),silver,METAL)
 end end
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
  local p=b:ball("WornMetalCorner"..x..y..z,.186,C(x*1.474,y*1.474,z*1.474),bronze,METAL)
  p.Reflectance=.07
 end end end
 local faces={
  {"Front",C(0,0,-1.475)},
  {"Back",C(0,0,1.475)*A(0,PI,0)},
  {"Right",C(1.475,0,0)*A(0,-PI/2,0)},
  {"Left",C(-1.475,0,0)*A(0,PI/2,0)},
  {"Top",C(0,1.475,0)*A(PI/2,0,0)},
  {"Bottom",C(0,-1.475,0)*A(-PI/2,0,0)},
 }
 for faceIndex,entry in ipairs(faces) do
  local label,frame=entry[1],entry[2]
  local prefix="AllSpark"..label
  local plate=b:box(prefix.."RecessedFacePanel",V(2.88,2.88,.102),frame,faceIndex%2==0 and recess or bronze,METAL)
  plate.Reflectance=.055
  -- Thin protective metal borders sit above the dark panel clearance seam.
  for _,s in ipairs({-1,1}) do
   b:box(prefix.."RaisedHorizontalBorder"..s,V(2.62,.043,.036),frame*C(0,s*1.315,-.071),silver,METAL)
   b:box(prefix.."RaisedVerticalBorder"..s,V(.043,2.62,.036),frame*C(s*1.315,0,-.071),silver,METAL)
  end
  -- Two inset strokes segment the ancient plate without turning it into a grid.
  for row=1,2 do
   b:box(prefix.."DarkRecessedDivision"..row,V(2.48,.035,.017),frame*C(0,.43-(row-1)*.86,-.059),dark,METAL)
  end
  for row=1,3 do for col=1,2 do
   local idx=(row-1)*2+col
   local glyph=glyphs[(idx+faceIndex-2)%#glyphs+1]
   local x=(col==1 and -.62 or .62)
   local y=.86-(row-1)*.86
   local rotation=((faceIndex+idx)%3-1)*.065
   local cf=frame*C(x,y,-.09)*A(0,0,rotation)
   for stroke,seg in ipairs(glyph) do
    b:line(prefix.."CybertronianGlyph"..idx.."Stroke"..stroke,
     cf*V(seg[1],seg[2],0),cf*V(seg[3],seg[4],0),.060,.045,
     (idx+faceIndex)%3==0 and silver or relief,METAL)
   end
  end end
  -- Small inset fasteners and one dim seam are part of the cube, never floating.
  for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
   b:box(prefix.."FlushCornerFastener"..x..y,V(.10,.10,.028),frame*C(x*1.17,y*1.17,-.071)*A(0,0,PI/4),dark,METAL)
  end end
  local seam=b:box(prefix.."SubtleCyanPowerSeam",V(.27,.024,.012),frame*C(faceIndex%2==0 and .98 or -.98,-.43,-.066),cyan,NEON)
  seam.Transparency=.30
 end
 b.model:SetAttribute("ArtVersion",72)
 b.model:SetAttribute("AllSparkFaceCount",6)
 b.model:SetAttribute("CybertronianGlyphCount",36)
 b.model:SetAttribute("GlyphStrokeCount",144)
 b.model:SetAttribute("ChamferedMetalEdges",12)
 b.model:SetAttribute("Franchise","Transformers")
 b.model:SetAttribute("ArtReference","Movie AllSpark cube")
 return true
end

return M
