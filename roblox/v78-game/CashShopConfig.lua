-- Configure real product IDs, verify Roblox prices, then enable checkout.
-- Disabled by default: missing IDs never produce a purchase prompt.
-- Only cash, base levels and the nine ordinary unlockable powers belong here.
-- Conveyor collectibles and every developer privilege are excluded.
return {
 Enabled=false,
 PreviewOnly=true,
 CashPerRobux=200,
 ProductInfoTTL=120,
 PromptCooldown=3,
 OpenCooldown=.5,
 Offers={
  {id='pocket',name='Pocket Cash',category='cash',robux=25,cash=5000,productId=0},
  {id='stack',name='Vault Stack',category='cash',robux=100,cash=20000,productId=0},
  {id='chest',name='Treasure Chest',category='cash',robux=250,cash=50000,productId=0},
  {id='fortune',name='Grand Fortune',category='cash',robux=500,cash=100000,productId=0},
  {id='level_one',name='One Base Level',category='levels',robux=25,levels=1,productId=0},
  {id='level_five',name='Five Base Levels',category='levels',robux=100,levels=5,productId=0},
  {id='unlock_dash',name='Dash Unlock',category='powers',robux=2,power='dash',productId=0},
  {id='unlock_gravity',name='Pull Unlock',category='powers',robux=6,power='gravity',productId=0},
  {id='unlock_slow',name='Slow Field Unlock',category='powers',robux=8,power='slow',productId=0},
  {id='unlock_slam',name='Ground Slam Unlock',category='powers',robux=25,power='slam',productId=0},
  {id='unlock_repulse',name='Knockback Pulse Unlock',category='powers',robux=70,power='repulse',productId=0},
  {id='unlock_shield',name='Force Field Shield Unlock',category='powers',robux=90,power='shield',productId=0},
  {id='unlock_lightning',name='Lightning Strike Unlock',category='powers',robux=325,power='lightning',productId=0},
  {id='unlock_kiblast',name='Ki Blast Unlock',category='powers',robux=325,power='kiblast',productId=0},
  {id='unlock_spinjitzu',name='Spinjitzu Unlock',category='powers',robux=80,power='spinjitzu',productId=0},
 },
}
