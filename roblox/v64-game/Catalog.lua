local C={}
-- Relative selection weights within each rarity; overall conveyor cadence is unchanged.
C.SpawnSettings={PokemonWeightMultiplier=.2,PokemonIds={item12=true,item20=true,item21=true,item22=true,item39=true,item40=true}}
C.Tiers={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Ethereal"}
C.Colors={{166,180,203},{78,215,145},{75,153,255},{180,108,255},{255,196,73},{255,88,126},{113,248,255}}
C.Weights={40,25,18,10,5,1.7,.3}
C.Items={
 {id="item01",name="Minecraft Diamond Sword",model="pixel",tier=1,price=100,income=3,power="pulse",ability="Diamond Sweep",radius=10,windup=0.45,cooldown=12,category="Relic"},
 {id="item02",name="Infinity Gauntlet",model="gauntlet",tier=6,price=180000,income=1800,power="pull",ability="Gravity Snap",radius=12,windup=1.1,cooldown=20,category="Relic"},
 {id="item03",name="The One Ring",model="oneRing",tier=5,price=65000,income=700,power="shield",ability="Veil of Protection",radius=3,windup=0,cooldown=18,category="Relic"},
 {id="item04",name="Green Chaos Emerald",model="emerald",tier=5,price=52000,income=620,power="dash",ability="Chaos Burst",radius=1,windup=0,cooldown=15,category="Relic"},
 {id="item05",name="Mario Kart Blue Shell",model="shell",tier=2,price=600,income=14,power="slow",ability="Spiny Shock",radius=10,windup=0.7,cooldown=14,category="Relic"},
 {id="item06",name="Buster Sword",model="buster",tier=3,price=2800,income=52,power="slam",ability="Braver",radius=12,windup=0.7,cooldown=15,category="Relic"},
 {id="item07",name="Portal Gun",model="portalgun",tier=3,price=3600,income=65,power="dash",ability="Portal Surge",radius=1,windup=0,cooldown=14,category="Relic"},
 {id="item08",name="Millennium Puzzle",model="puzzle",tier=4,price=14000,income=195,power="shadow",ability="Shadow Game",radius=11,windup=1.1,cooldown=18,category="Relic"},
 {id="item09",name="Halo Energy Sword",model="energy",tier=3,price=3200,income=58,power="pulse",ability="Plasma Sweep",radius=10,windup=0.45,cooldown=12,category="Relic"},
 {id="item10",name="Mjölnir",model="hammer",tier=5,price=45000,income=550,power="slam",ability="Thunderclap",radius=14,windup=0.9,cooldown=18,category="Relic"},
 {id="item11",name="Call of Duty Zombies Ray Gun",model="raygun",tier=3,price=4000,income=72,power="pulse",ability="Ray Burst",radius=12,windup=0.65,cooldown=14,category="Relic"},
 {id="item12",name="Master Ball",model="masterball",tier=4,price=16000,income=220,power="slow",ability="Capture Field",radius=11,windup=0.8,cooldown=16,category="Relic"},
 {id="item13",name="Exodia — Five-Card Set",model="cards",tier=7,price=800000,income=6000,power="shadow",ability="Forbidden Seal",radius=14,windup=1.4,cooldown=24,category="Relic"},
 {id="item14",name="Zeno's Button",model="zenobutton",tier=7,price=1000000,income=7400,power="pulse",ability="Erasure Pulse",radius=14,windup=1.5,cooldown=25,category="Relic"},
 {id="item15",name="Link's Master Sword",model="master",tier=4,price=12000,income=175,power="pulse",ability="Sacred Slash",radius=12,windup=0.6,cooldown=14,category="Relic"},
 {id="item16",name="Doom BFG 9000",model="bfg",tier=6,price=210000,income=2100,power="pulse",ability="BFG Wave",radius=14,windup=1.2,cooldown=22,category="Relic"},
}
for _,d in ipairs(require(script.Parent.ExpandedCatalog)) do table.insert(C.Items,d) end
for _,d in ipairs(require(script.Parent.FreeCatalog)) do table.insert(C.Items,d) end
C.ById={}; C.ByTier={}
for tier in ipairs(C.Tiers) do C.ByTier[tier]={} end
for _,d in ipairs(C.Items) do
 assert(not C.ById[d.id],'Duplicate collectible ID: '..d.id)
 d.spawnWeight=d.spawnWeight or 1
 if C.SpawnSettings.PokemonIds[d.id] then d.spawnWeight=d.spawnWeight*C.SpawnSettings.PokemonWeightMultiplier end
 assert(d.spawnWeight>0 and C.Tiers[d.tier] and d.price>0 and d.income>0,'Invalid collectible configuration')
 d.rarity=C.Tiers[d.tier]; C.ById[d.id]=d
 table.insert(C.ByTier[d.tier],d)
end
function C.roll(rng)
 local total=0
 for tier,w in ipairs(C.Weights) do if #C.ByTier[tier]>0 then total=total+w end end
 local value=rng:NextNumber()*total
 for tier,w in ipairs(C.Weights) do
  local pool=C.ByTier[tier]
  if #pool>0 then
   value=value-w
   if value<0 then
    local itemTotal=0
    for _,d in ipairs(pool) do itemTotal=itemTotal+d.spawnWeight end
    local itemRoll=rng:NextNumber()*itemTotal
    for _,d in ipairs(pool) do itemRoll=itemRoll-d.spawnWeight; if itemRoll<0 then return d.id end end
    return pool[#pool].id
   end
  end
 end
 return C.Items[1].id
end
return C
