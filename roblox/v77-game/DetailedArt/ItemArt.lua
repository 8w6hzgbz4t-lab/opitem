-- Detailed visuals only; prices, rarity, income and abilities stay in the existing Catalog.
local P=require(script.Parent.Primitives)
local Puzzle=require(script.Parent.MillenniumPuzzle)
local families={
 Weapons=require(script.Parent.Weapons), Artifacts=require(script.Parent.Artifacts),
 Technology=require(script.Parent.Technology), Figures=require(script.Parent.Figures),
 ExtraItems=require(script.Parent.ExtraItems),
}
local A={}
A.Items={
 {id="item01",name="Minecraft Diamond Sword",model="pixel"},
 {id="item02",name="Infinity Gauntlet",model="gauntlet"},
 {id="item03",name="The One Ring",model="oneRing"},
 {id="item04",name="Green Chaos Emerald",model="emerald"},
 {id="item05",name="Mario Kart Blue Shell",model="shell"},
 {id="item06",name="Buster Sword",model="buster"},
 {id="item07",name="Portal Gun",model="portalgun"},
 {id="item08",name="Millennium Puzzle",model="puzzle"},
 {id="item09",name="Halo Energy Sword",model="energy"},
 {id="item10",name="Mjölnir",model="hammer"},
 {id="item11",name="Call of Duty Zombies Ray Gun",model="raygun"},
 {id="item12",name="Master Ball",model="masterball"},
 {id="item13",name="Exodia — Five-Card Set",model="cards"},
 {id="item14",name="Zeno's Button",model="zenobutton"},
 {id="item15",name="Link's Master Sword",model="master"},
 {id="item16",name="Doom BFG 9000",model="bfg"},
 {id="item17",name="Jellyfishing Net",model="jellyNet"},
 {id="item18",name="LeBron's Face Mask",model="faceMask"},
 {id="item19",name="Broly's Jewelry",model="brolyJewelry"},
 {id="item20",name="Poke Ball",model="pokeBall"},
 {id="item21",name="Thunder Evolution Stone",model="evolutionStone"},
 {id="item22",name="Rainbow Legendary Feather",model="legendFeather"},
 {id="item23",name="Millennium Rod",model="millenniumRod"},
 {id="item24",name="Duel Disk",model="duelDisk"},
 {id="item25",name="Exodia Head and Torso",model="exodiaHead"},
 {id="item26",name="Exodia Left Arm",model="exodiaLeftArm"},
 {id="item27",name="Exodia Right Arm",model="exodiaRightArm"},
 {id="item28",name="Exodia Left Leg",model="exodiaLeftLeg"},
 {id="item29",name="Exodia Right Leg",model="exodiaRightLeg"},
 {id="item30",name="Minecraft Diamond Axe",model="diamondAxe"},
 {id="item31",name="Enchanted Diamond Pickaxe",model="enchantedPickaxe"},
 {id="item32",name="End Crystal",model="endCrystal"},
 {id="item33",name="Command Block",model="commandBlock"},
 {id="item34",name="Sting",model="sting"},
 {id="item35",name="The Arkenstone",model="arkenstone"},
 {id="item36",name="Dwarven Treasure",model="dwarfTreasure"},
 {id="item37",name="Emerald Materia",model="materia"},
 {id="item38",name="Revolver Gunblade",model="gunblade"},
 {id="item39",name="Fire Evolution Stone",model="fireStone"},
 {id="item40",name="Water Evolution Stone",model="waterStone"},
 {id="item41",name="Iron Man Armor Suit",model="ironArmor"},
 {id="item42",name="Triforce",model="triforce"},
 {id="item43",name="Dragon Balls",model="dragonballs"},
 {id="item44",name="Yusei Fudo Red Duel Runner",model="duelrunner"},
 {id="item45",name="Freddy Fazbear Empty Suit",model="freddysuit"},
 {id="item46",name="Golden Freddy Empty Suit",model="goldenfreddysuit"},
}
local byId={}
for _,d in ipairs(A.Items) do byId[d.id]=d end
local routes={}
local function add(family,keys)
 for _,key in ipairs(keys) do routes[string.lower(key)]={family=family,key=key} end
end
add('Weapons',{'pixel','buster','master','energy','hammer','sting','pickaxe','diamondaxe','lightsaber','keyblade','gunblade'})
add('Artifacts',{'gauntlet','oneRing','emerald','shell','zenobutton','cards','materia','commandblock','endcrystal','arkenstone','deathnote','triforce','millenniumRod','dwarfTreasure'})
add('Technology',{'portalgun','raygun','bfg','omnitrix','facemask','jellynet','pegasus','nemesis','dueldisk'})
add('Figures',{'masterball','pokeball','evolutionstone','firestone','waterstone','legendfeather','missingno','ironman','megaknight','pekka','brolyjewelry','exodiahead','exodialeftarm','exodiarightarm','exodialeftleg','exodiarightleg'})
routes.enchantedpickaxe=routes.pickaxe
add('ExtraItems',{'dragonballs','duelrunner','freddysuit','goldenfreddysuit'})
routes.ironarmor=routes.ironman
local function key(value) return string.lower(tostring(value or '')):gsub('[^%w]','') end
function A.supports(model) return key(model)=='puzzle' or routes[key(model)]~=nil end
function A.create(parent,options)
 options=options or {};local copy={}
 for k,v in pairs(options) do copy[k]=v end
 local d=byId[copy.itemId or copy.id]
 if d then
  if not A.supports(copy.model) then copy.model=d.model end
  if not copy.name or copy.name==d.id then copy.name=d.name end
 end
 local modelKey=key(copy.model or (d and d.model))
 assert(modelKey=='puzzle' or routes[modelKey], 'No detailed art for '..tostring(copy.model))
 if modelKey=='puzzle' then return Puzzle.create(parent,copy) end
 local route=routes[modelKey];local builder=P.new(parent,copy)
 assert(families[route.family].build(builder,route.key),'Art route did not build')
 return builder:finish()
end
return A

