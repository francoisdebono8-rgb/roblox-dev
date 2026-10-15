-- All balance knobs live here. No marketplace asset is enabled by default.
local C = {}
C.Schema = 1
C.MaxCoins = 1e12
C.InventoryBase = 30
C.DisplaySlots = 4
C.OfflineCap = 7200
C.PrestigeCost = 150000
C.PrestigeBonus = 0.25
C.ForgeSeconds = 7
C.HammerReduction = 0.35
C.Rarities = {
 {Name='Common', Weight=62, Multiplier=1, Color={174,180,184}},
 {Name='Uncommon', Weight=25, Multiplier=1.35, Color={110,215,151}},
 {Name='Rare', Weight=9.5, Multiplier=2, Color={93,178,255}},
 {Name='Epic', Weight=2.9, Multiplier=3.5, Color={193,132,255}},
 {Name='Legendary', Weight=0.55, Multiplier=6, Color={255,195,80}},
 {Name='Mythic', Weight=0.05, Multiplier=10, Color={255,104,143}},
}
C.Mutations = {
 {Name='None', Weight=94, Multiplier=1},
 {Name='Heated', Weight=3, Multiplier=1.5, Color={255,120,45}},
 {Name='Frozen', Weight=1.8, Multiplier=1.8, Color={107,234,255}},
 {Name='Arcane', Weight=1, Multiplier=2.3, Color={183,119,255}},
 {Name='Glitched', Weight=0.2, Multiplier=4, Color={112,255,188}},
}
C.Weapons = {
 {Name='Rusted Shortsword', Shape='Shortsword', Zone=1, Value=14},
 {Name='Iron Saber', Shape='Saber', Zone=1, Value=21},
 {Name='Steel Axe', Shape='Axe', Zone=1, Value=30},
 {Name='Ember Dagger', Shape='Dagger', Zone=2, Value=65},
 {Name='Magma Hammer', Shape='Hammer', Zone=2, Value=95},
 {Name='Obsidian Greatsword', Shape='Greatsword', Zone=2, Value=135},
 {Name='Arcane Katana', Shape='Katana', Zone=3, Value=250},
 {Name='Void Scythe', Shape='Scythe', Zone=3, Value=360},
 {Name='Runic Greatblade', Shape='Runic', Zone=3, Value=500},
}
C.Zones = {
 {Name='Village Forge', Cost=0, Color={231,156,78}},
 {Name='Magma Foundry', Cost=2500, Color={255,98,48}},
 {Name='Arcane Forge', Cost=25000, Color={158,133,255}},
}
C.Upgrades = {
 Speed={Name='Forge speed', Base=20, Growth=2.5, Max=12, Effect=0.10, Description='10% faster per level'},
 Value={Name='Weapon value', Base=30, Growth=2.8, Max=12, Effect=0.25, Description='+25% sell value per level'},
 Luck={Name='Rare luck', Base=70, Growth=2, Max=10, Effect=0.18, Description='+18% rare weight per level'},
 Display={Name='Armory income', Base=50, Growth=1.9, Max=10, Effect=0.30, Description='+30% rack income per level'},
 Capacity={Name='Inventory', Base=100, Growth=2.2, Max=6, Effect=10, Description='+10 inventory slots per level'},
}
C.DisplayRate = 0.0025 -- weapon value per second; collection helps, active forging leads
C.Monetization = {
 AutoForge={Kind='Pass', Id=nil, Target=99, Name='Auto Forge', Benefit='Repeat the forge cycle automatically.'},
 AutoMerge={Kind='Pass', Id=nil, Target=129, Name='Auto Merge', Benefit='Merge eligible weapons up to your chosen rarity.'},
 DoubleCoins={Kind='Pass', Id=nil, Target=149, Name='2× Coins', Benefit='Double weapon sales and armory income.'},
 DisplaySlots={Kind='Pass', Id=nil, Target=79, Name='+2 Display Slots', Benefit='Show six weapons instead of four.'},
 Starter={Kind='Pass', Id=nil, Target=49, Name='Starter Pack', Benefit='500 coins, 10 minutes of luck and a gold forge accent.'},
 Small={Kind='Product', Id=nil, Target=29, Name='Coin Pouch', Minutes=5, Floor=250, Cap=100000},
 Medium={Kind='Product', Id=nil, Target=79, Name='Coin Chest', Minutes=20, Floor=1200, Cap=500000},
 Large={Kind='Product', Id=nil, Target=199, Name='Coin Vault', Minutes=60, Floor=4000, Cap=1500000},
}
C.Sounds = {hammer_hit=nil, forge_fire=nil, quench=nil, rarity_reveal=nil, legendary_reveal=nil, merge=nil, coins=nil, upgrade=nil, zone_unlock=nil, button_click=nil, music=nil}
return C
