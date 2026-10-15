-- Readable text belongs on real surfaces rather than floating billboards.
local L={}
L.Definitions={
 mtg_black_lotus_card={
  {part="TitleSurface",text="BLACK LOTUS",color={30,26,22},size=42,align="Left"},
  {part="TypeSurface",text="Artifact",color={30,26,22},size=30,align="Left"},
  {part="RulesSurface",text="Sacrifice Black Lotus: Add three mana of any one color.\n\nA rare bloom of extraordinary power.",color={42,35,28},size=25,align="Left"},
 },
 mirror_force_card={
  {part="TitleSurface",text="MIRROR FORCE",color={255,244,217},size=72,align="Left"},
  {part="CardTypeSurface",text="[TRAP CARD]",color={255,244,217},size=35,align="Right"},
  {part="EditionSurface",text="SPELLBINDING ARCHIVE",color={246,222,195},size=14,align="Left"},
  {part="RulesSurface",text="When an opponent's monster declares an attack:\nDestroy all your opponent's Attack Position monsters.",color={45,31,29},size=40,align="Left"},
 },
 power_console={
  {part="MonitorScreen",text="POWER\nLOADOUT",color={118,233,255},size=26,align="Right"},
 },
}
local suppressed={mtg_black_lotus_card={"LotusRules","LotusFlavor"},mirror_force_card={"MirrorRules"}}
function L.apply(model,key)
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   for _,prefix in ipairs(suppressed[key] or {}) do
    if part.Name:sub(1,#prefix)==prefix then part.Transparency=1 end
   end
  end
 end
 -- Offline geometry recording has no Roblox GUI constructors.
 if not UDim2 then return end
 for index,definition in ipairs(L.Definitions[key] or {}) do
  local part=model:FindFirstChild(definition.part,true)
  if part then
   local gui=Instance.new("SurfaceGui")
   gui.Name="NativeText"..index;gui.Face=Enum.NormalId.Front
   gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=35
   gui.LightInfluence=.15;gui.AlwaysOnTop=false;gui.MaxDistance=300
   local text=Instance.new("TextLabel")
   text.Name="Caption";text.BackgroundTransparency=1
   text.Position=UDim2.fromOffset(12,6);text.Size=UDim2.new(1,-24,1,-12)
   text.Text=definition.text;text.Font=Enum.Font.GothamBold
   text.TextSize=definition.size;text.TextScaled=false;text.TextWrapped=true
   text.TextColor3=Color3.fromRGB(definition.color[1],definition.color[2],definition.color[3])
   text.TextXAlignment=Enum.TextXAlignment[definition.align]
   text.TextYAlignment=Enum.TextYAlignment.Center
   text.Parent=gui;gui.Parent=part
  end
 end
end
return L
