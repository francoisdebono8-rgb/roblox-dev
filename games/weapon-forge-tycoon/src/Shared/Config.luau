-- All balance knobs live here. No marketplace asset is enabled by default.
local C = {}
C.Schema = 4
C.MaxCoins = 1e12
C.InventoryBase = 30
C.DisplaySlots = 4
C.OfflineCap = 7200
C.PrestigeCost = 150000
C.PrestigeBonus = 0.25
C.PrestigeMinorBonus = 0.03
C.ForgeMinimumSeconds = 4
C.ExpectedRarityValue = 1.55
C.StarterCoins = 500
C.StarterLuckSeconds = 600
C.StarterLuckBonus = 0.5
C.ForgeSeconds = 7
C.HammerReduction = 0.35
C.PerfectValueBonus = .12
C.PerfectLuckBonus = .1
C.PerfectWindow = .3
C.SecretChance = .0005
C.EventSeconds = 300
C.EventInterval = 1800
C.MaterialCap = 80
C.MarketTax = .08
C.MarketMaxPrice = 100000000
C.MarketExpiry = 86400
C.Materials = {
 {Name='Iron', Zone=1, Cost=0, Multiplier=1, Color={178,191,201}, Parts=2, Mutations={1,2}},
 {Name='Steel', Zone=1, Cost=3, Multiplier=1.25, Color={217,234,242}, Parts=2, Mutations={1,2}},
 {Name='Obsidian', Zone=2, Cost=8, Multiplier=1.4, Color={69,56,91}, Parts=3, Mutations={1,2,3}},
 {Name='Emberstone', Zone=2, Cost=12, Multiplier=1.6, Color={255,111,52}, Parts=3, Mutations={1,2,3}},
 {Name='Arcane Crystal', Zone=3, Cost=35, Multiplier=1.9, Color={146,163,255}, Parts=3, Mutations={1,3,4,5}},
}
C.Parts = {Blade={'Classic','Tempered','Serrated'},Guard={'Cross','Swept','Gemstone'},Handle={'Leather','Ocean wrap','Runebound'}}
C.Events = {
 {Name='Heat Wave', Mutation=2, Weight=3, Color={255,136,65}},
 {Name='Arcane Surge', Mutation=4, Weight=3, Color={188,135,255}},
 {Name='Lucky Forge', Luck=.35, Color={107,255,167}},
}
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
 {Name='Forge Village', Cost=0, Color={231,156,78}},
 {Name='Magma Quarry', Cost=2500, Color={255,98,48}},
 {Name='Arcane Ruins', Cost=25000, Color={158,133,255}},
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
 MarketListings={Kind='Pass',Id=nil,Target=79,Name='+2 Market Listings',Benefit='Five offers instead of three.'},
 ResourceBoost={Kind='Product',Id=nil,Target=29,Name='Resource Boost',Benefit='10 minutes of double collected materials.',ResourceBoost=true},
 LuckyForge={Kind='Product', Id=nil, Target=29, Name='Lucky Forge Boost', Benefit='10 minutes of +50% rare luck.', Boost=true},
 AutoForge={Kind='Pass', Id=nil, Target=99, Name='Auto Forge', Benefit='Repeat the forge cycle automatically.'},
 AutoMerge={Kind='Pass', Id=nil, Target=129, Name='Auto Merge', Benefit='Merge eligible weapons up to your chosen rarity.'},
 DoubleCoins={Kind='Pass', Id=nil, Target=149, Name='2× Coins', Benefit='Double weapon sales and armory income.'},
 DisplaySlots={Kind='Pass', Id=nil, Target=79, Name='+2 Display Slots', Benefit='Show six weapons instead of four.'},
 Starter={Kind='Pass', Id=nil, Target=49, Name='Starter Pack', Benefit='Progression coins, 10 minutes of luck, gold trim and a Rare or Epic weapon.'},
 Small={Kind='Product', Id=nil, Target=29, Name='Coin Pouch', Minutes=5, Floor=250, Cap=100000},
 Medium={Kind='Product', Id=nil, Target=79, Name='Coin Chest', Minutes=20, Floor=1200, Cap=500000},
 Large={Kind='Product', Id=nil, Target=199, Name='Coin Vault', Minutes=60, Floor=4000, Cap=1500000},
}
C.Sounds = {hammer_hit=nil, forge_fire=nil, quench=nil, rarity_reveal=nil, legendary_reveal=nil, merge=nil, coins=nil, upgrade=nil, zone_unlock=nil, button_click=nil, music=nil}
return C
