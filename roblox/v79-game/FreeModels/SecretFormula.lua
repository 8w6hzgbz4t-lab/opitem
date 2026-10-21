-- The Krusty Krab's bottled recipe: entirely native Roblox display geometry.
-- No meshes, decals, external assets or runtime interaction are required.
local M={}
local V,C,A,RGB=Vector3.new,CFrame.new,CFrame.Angles,Color3.fromRGB
local GLASS,WOOD,PAPER,METAL=Enum.Material.Glass,Enum.Material.Wood,Enum.Material.SmoothPlastic,Enum.Material.Metal
local TAU=math.pi*2

function M.build(b,key)
 if key~="krabby_patty_formula" then return false end
 local green,darkGreen,paleGreen=RGB(83,172,127),RGB(28,103,78),RGB(190,238,205)
 local parchment,edge,ink=RGB(245,221,166),RGB(178,132,66),RGB(77,55,32)
 local cork,twine,red,gold=RGB(166,112,66),RGB(203,166,104),RGB(174,40,37),RGB(226,178,73)
 local vertical=A(0,0,math.pi/2)
 local function glass(part,transparency)
  part.Transparency=transparency;part.Reflectance=.04;return part
 end
 -- A translucent cylindrical body, rounded shoulders and a separate narrow neck.
 -- The recipe is real geometry inside the glass and remains visible above the label.
 glass(b:cylinder("GreenGlassBottleBody",V(2.44,2.22,2.22),C(0,1.61,0)*vertical,green,GLASS),.65)
 glass(b:ball("RoundedGlassShoulder",V(2.22,.91,2.22),C(0,2.77,0),green,GLASS),.67)
 glass(b:cylinder("HeavyGlassBottleBase",V(.19,2.28,2.28),C(0,.40,0)*vertical,darkGreen,GLASS),.28)
 glass(b:cylinder("LongNarrowBottleNeck",V(1.16,.77,.77),C(0,3.48,0)*vertical,green,GLASS),.55)
 glass(b:cylinder("BottleLip",V(.19,.91,.91),C(0,4.04,0)*vertical,paleGreen,GLASS),.34)
 -- Rings lie horizontally around the bottle, so none cross its front like a halo.
 b:ring("ThickBottomGlassRim",C(0,.39,0)*A(math.pi/2,0,0),1.095,.072,darkGreen,16,GLASS)
 b:ring("ShoulderGlassSeam",C(0,2.76,0)*A(math.pi/2,0,0),1.037,.037,paleGreen,16,GLASS)
 b:ring("MouthGlassEdge",C(0,4.11,0)*A(math.pi/2,0,0),.407,.044,paleGreen,12,GLASS)
 for _,s in ipairs({-1,1}) do
  local part=b:box("BottleReflection"..s,V(.045,1.62,.025),C(s*.77,1.78,-.79)*A(0,s*.22,s*.035),paleGreen,GLASS)
  part.Transparency=.3
  glass(b:box("NeckReflection"..s,V(.025,.68,.018),C(s*.20,3.52,-.34),paleGreen,GLASS),.25)
 end
 -- Warm cork, a bevelled crown and small embedded grain marks; no floating cap.
 b:cylinder("FittedCorkStopper",V(.45,.66,.66),C(0,4.24,0)*vertical,cork,WOOD)
 b:cylinder("CorkCrown",V(.08,.70,.70),C(0,4.48,0)*vertical,RGB(188,139,87),WOOD)
 b:ring("CorkEndGrain",C(0,4.526,0)*A(math.pi/2,0,0),.244,.024,RGB(139,91,51),12,WOOD)
 for i=0,7 do
  local a=i*TAU/8
  b:box("CorkPore"..i,V(.045,.055,.018),C(math.sin(a)*.333,4.20+(i%3)*.058,math.cos(a)*.333)*A(0,a,0),RGB(120,76,43),WOOD)
 end
 -- A cream scroll rolled around a dark hollow centre, with concentric paper ends.
 local scroll=C(.10,1.85,-.06)*A(0,0,-.12)
 b:cylinder("RolledSecretRecipe",V(2.30,.78,.78),scroll*vertical,parchment,PAPER)
 b:box("CurledParchmentEdge",V(.055,2.09,.12),scroll*C(.37,0,-.08)*A(0,0,.015),edge,PAPER)
 for _,s in ipairs({-1,1}) do
  b:cylinder("ScrollHollowEnd"..s,V(.025,.265,.265),scroll*C(0,s*1.163,0)*vertical,ink,PAPER)
  b:ring("RolledPaperEnd"..s,scroll*C(0,s*1.183,0)*A(math.pi/2,0,0),.315,.035,edge,12,PAPER)
  b:ring("InnerPaperRoll"..s,scroll*C(0,s*1.193,0)*A(math.pi/2,0,0),.205,.025,parchment,12,PAPER)
 end
 -- Handwritten recipe strokes are tucked inside; the formula itself stays secret.
 for row=0,5 do
  local y=.70-row*.15
  b:box("RecipeInkStroke"..row,V(.23+(row%3)*.026,.018,.012),scroll*C(-.02,y,-.391),ink,PAPER)
 end
 b:ring("ScrollBinding",scroll*C(0,-.16,0)*A(math.pi/2,0,0),.40,.033,RGB(185,49,40),12,PAPER)
 -- Two visible turns of twine around the neck, a small knot and trailing string.
 for i=0,1 do
  b:ring("NeckTwineTurn"..i,C(0,3.29+i*.095,0)*A(math.pi/2,0,0),.408,.045,twine,12,PAPER)
 end
 b:ball("TwineKnot",V(.16,.14,.10),C(.10,3.32,-.43),twine,PAPER)
 b:line("LeftStringTail",V(.07,3.3,-.46),V(-.14,2.99,-.65),.039,.039,twine,PAPER)
 b:line("LeftStringEnd",V(-.14,2.99,-.65),V(-.09,2.86,-.73),.039,.039,twine,PAPER)
 b:line("SealString",V(.15,3.29,-.45),V(.46,2.89,-.82),.043,.043,twine,PAPER)
 b:line("SealStringLower",V(.46,2.89,-.82),V(.45,2.65,-.92),.043,.043,twine,PAPER)
 -- Red sealing wax and an embossed anchor identify the guarded Krusty Krab recipe.
 b:ball("RedWaxSeal",V(.48,.51,.10),C(.45,2.65,-.97),red,PAPER)
 b:ring("WaxSealImprint",C(.45,2.65,-1.031),.16,.022,gold,12,METAL)
 b:line("SealAnchorStem",V(.45,2.56,-1.049),V(.45,2.75,-1.049),.027,.018,gold,METAL)
 b:line("SealAnchorCrossbar",V(.37,2.68,-1.049),V(.53,2.68,-1.049),.024,.018,gold,METAL)
 b:line("SealAnchorLeft",V(.45,2.56,-1.049),V(.36,2.62,-1.049),.024,.018,gold,METAL)
 b:line("SealAnchorRight",V(.45,2.56,-1.049),V(.54,2.62,-1.049),.024,.018,gold,METAL)
 -- A compact, fitted label uses real SurfaceGui text through Labels.lua.
 b:box("FormulaLabelBorder",V(1.89,1.14,.039),C(0,1.35,-1.095),RGB(133,52,38),PAPER)
 b:box("FormulaLabel",V(1.77,1.02,.035),C(0,1.35,-1.126),RGB(251,232,184),PAPER)
 b:box("FormulaBrand",V(1.62,.27,.023),C(0,2.01,-1.14),RGB(251,232,184),PAPER)
 for _,s in ipairs({-1,1}) do
  b:box("LabelCorner"..s,V(.13,.06,.014),C(s*.75,.91,-1.148),gold,METAL)
 end
 b.model:SetAttribute("ArtVersion",71)
 b.model:SetAttribute("SealedRecipeBottle",true)
 b.model:SetAttribute("RecipeContents","Krabby Patty Secret Formula")
 return true
end

return M
