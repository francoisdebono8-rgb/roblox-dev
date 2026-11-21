-- The kits' fingerprint (OUTILLEUR, 20/11; DEC-043, étape 1, OUTILLEUR 2).
-- For each prodigy of the beta: how far he hits, how fast, how he moves, how
-- much damage he does per second, how long he lasts, and what only he has.
-- Read from the game's own data with the combat's own rules (Server/Brawler:
-- a strike's startup, active and recovery scaled by the fighter's
-- AttackProfile, its step-in by CombatTravel, its damage by CombatDamage), for
-- three versions of each kit:
--   prodige  the prodigy as the AI and the masters play him (Fighters)
--   depart   a player's kit with no node of its tree (SkillBuilds.build gated:
--            the kit objects he has not earned are taken away)
--   arbre    a player's kit with every wired node of its tree (the first of an
--            exclusive choice), SkillBuilds.apply
-- and (21/11, DEC-045, step 2) what each of the five chakra natures of the
-- ninja's tree adds to a kit (Shared/NinjaTree.Infusion: the contract the
-- combat follows), with the infused kunai, the infused blade and the mastery.
-- Pure: no instance, no remote. The modules come from the caller:
--   KitPrint.compute({Fighters=, Attacks=, Combo=, BetaRoster=, SkillBuilds=,
--                     Config=, NinjaTree=})   (Config, NinjaTree: optional)
-- tools/kits/empreinte.py compares the kits with each other, and a version
-- with another (before / after a change).
local KitPrint={Version=3}

local function num(v) return if type(v)=="number" and v==v and math.abs(v)~=math.huge then v else nil end
local function round(v,d) if not num(v) then return nil end local m=10^(d or 2);return math.floor(v*m+.5)/m end

-- A strike as Brawler.start builds it for this fighter (without a chakra
-- load, a drawn kunai or an awakening).
function KitPrint.strike(def,Attacks,name)
	local base=Attacks[name]
	if not base then return nil end
	local profile=def.AttackProfile and (def.AttackProfile[name] or def.AttackProfile[base.clip or ""])
	local s={name=name,startup=base.startup,active=base.active,recovery=base.recovery,
		travel=(base.travel or 0)*(def.CombatTravel or 1),range=base.range,contact=base.contact or 3.6,damageScale=1,
		damage=base.damage or 0,reaction=base.reaction}
	if profile then
		s.startup*=profile.startup or 1;s.active*=profile.active or 1;s.recovery*=profile.recovery or 1
		s.travel*=profile.travel or 1;s.range=profile.range or s.range;s.contact=profile.contact or s.contact
		s.damageScale=profile.damage or 1
	end
	s.damage=s.damage*s.damageScale*(def.CombatDamage or 1)
	s.time=s.startup+s.active+s.recovery
	-- how far the strike lands from where he stands: its step-in plus the
	-- contact distance, plus the stud past it the volume reaches (Brawler)
	s.reach=s.travel+s.contact+1
	return s
end

-- The ground string, in the order Brawler plays it: 4 hits (StringLength 5:
-- Lee, Naruto), the last always Light3, the middle ones Light4, Light5.
function KitPrint.string(def)
	local length=def.StringLength or 4
	local names={}
	for index=1,length do
		table.insert(names,if index>=length then "Light3" elseif index<=2 then "Light"..index else "Light"..(index+1))
	end
	return names
end

local COMMON={Name=true,FullName=true,Age=true,Title=true,Color=true,Routes=true,Description=true,Health=true,Chakra=true,
	ChakraRegen=true,Speed=true,SprintScale=true,JumpScale=true,AirControlScale=true,AccelerationScale=true,CombatTravel=true,
	CombatDamage=true,DashScale=true,GuardStrength=true,PreferredRange=true,ComboToolCancel=true,CombatStyle=true,Tool=true,
	ToolMastery=true,Awakening=true,AttackProfile=true,Skin=true,Hair=true,Outfit=true,Techniques=true,SealJutsu=true,
	StrikeTurnScale=true,StringLength=true,Motion=true,Portrait=true,Look=true,Voice=true,Intro=true}

-- What a kit is made of, as numbers and names. Config (optional): the run is
-- Config.Movement.SprintSpeed x SprintScale, as the game moves (DEC-044, 20/11:
-- it was the walk x SprintScale here, and Gaara's run came out slower than
-- his walk).
function KitPrint.kit(def,Attacks,Config)
	local out={}
	-- the ground string
	local hits,damage,time={},0,0
	for _,name in KitPrint.string(def) do
		local s=KitPrint.strike(def,Attacks,name)
		if s then
			table.insert(hits,{name=name,startup=round(s.startup,3),damage=round(s.damage,2),reach=round(s.reach,2),time=round(s.time,3)})
			damage+=s.damage;time+=s.time
		end
	end
	local first=KitPrint.strike(def,Attacks,"Light1")
	local heavy=KitPrint.strike(def,Attacks,"Heavy")
	local launch=KitPrint.strike(def,Attacks,def.LauncherMove or "Launcher")
	local dash=KitPrint.strike(def,Attacks,"DashAttack")
	out.string={hits=hits,count=#hits,damage=round(damage,2),time=round(time,3),dps=round(if time>0 then damage/time else 0,2)}
	out.firstHit=first and round(first.startup,3)
	out.reach=first and round(first.reach,2)
	out.heavy=heavy and {damage=round(heavy.damage,2),startup=round(heavy.startup,3),reach=round(heavy.reach,2)}
	out.launcher=launch and {name=launch.name,damage=round(launch.damage,2),startup=round(launch.startup,3),reach=round(launch.reach,2)}
	out.dash=dash and {damage=round(dash.damage,2),reach=round(dash.reach,2)}
	-- moving
	local awake=def.Awakening or {}
	local sprint=Config and Config.Movement and num(Config.Movement.SprintSpeed)
	local run=if sprint then sprint*(num(def.SprintScale) or 1) elseif num(def.Speed) then def.Speed*(num(def.SprintScale) or 1) else nil
	out.move={walk=num(def.Speed),run=round(run,2),jump=num(def.JumpScale) or 1,
		air=num(def.AirControlScale) or 1,accel=num(def.AccelerationScale) or 1,dash=num(def.DashScale) or 1,
		awakenSpeed=num(awake.Speed) or 1}
	-- lasting
	out.body={health=num(def.Health),chakra=num(def.Chakra),regen=num(def.ChakraRegen),guard=num(def.GuardStrength) or 0,
		preferredRange=num(def.PreferredRange)}
	-- the jutsu
	-- a technique a player has not earned yet (Locked: a kit object's or an
	-- Unlock node's) is not in his kit: listed apart, never counted
	local techs,burst,sustained,farthest,teleports,mobile,locked={},0,0,0,0,0,{}
	for _,t in def.Techniques or {} do
		if t.Locked==true then table.insert(locked,t.Id);continue end
		local dmg=num(t.Damage) or 0
		local cd=num(t.Cooldown)
		table.insert(techs,{id=t.Id,name=t.Name,family=t.Family,element=t.Element,damage=dmg,range=num(t.Range),cooldown=cd,
			cost=num(t.Cost),mobile=t.Mobile==true,teleport=t.Family=="Teleport" or t.To~=nil})
		burst+=dmg
		if dmg>0 and cd and cd>0 then sustained+=dmg/cd end
		if num(t.Range) and dmg>0 then farthest=math.max(farthest,t.Range) end
		if t.Family=="Teleport" or t.To~=nil then teleports+=1 end
		if t.Mobile then mobile+=1 end
	end
	out.jutsu={list=techs,count=#techs,burst=round(burst,2),dps=round(sustained,2),farthest=farthest,teleports=teleports,mobile=mobile,
		seals=if type(def.SealJutsu)=="table" then #def.SealJutsu else 0,locked=locked}
	-- the tool button
	local tm=def.ToolMastery or {}
	out.tool={kind=tm.Kind or def.Tool,count=num(tm.Count),speed=num(tm.Speed),damage=num(tm.Damage),recover=num(tm.Recover)}
	out.style=def.CombatStyle
	-- what only some kits have: their own fields, and their own flags inside
	-- the tool, the awakening and the substitution
	local own={}
	for key,value in def do
		if not COMMON[key] and type(key)=="string" and value~=nil and value~=false then table.insert(own,key) end
	end
	for key,value in tm do if key~="Kind" and key~="Count" and key~="Speed" and key~="Damage" and key~="Recover" and value then table.insert(own,"Tool."..key) end end
	for key,value in awake do
		if key~="Name" and key~="Speed" and key~="Regen" and key~="Cooldown" and key~="Color" and key~="Duration" and key~="Damage" and value then
			table.insert(own,"Awakening."..key)
		end
	end
	table.sort(own)
	out.own=own
	out.awakening=awake.Name
	return out
end

-- What one chakra nature adds to a kit, from the contract of the ninja's tree
-- (NinjaTree.Infusion): an infused hit fires its effect at most once every Gap
-- seconds, so a kit that lands its third basic hit or its kunai more often
-- than that gets the effect at that rate, whatever its speed. opts: kunai,
-- blade, mastery (default: all three, the whole infusion branch). The mastery
-- multiplies what the effect does (Strong). A kit with no thrown blade (Lee's
-- tool deflects) carries nothing on a kunai. Per second of duel:
--   burnDps    health the burn takes             (Fire)
--   kunaiRange the thrown blade's flight, x      (Wind)
--   frozen     share of the time he is frozen   (Lightning)
--   guardDps   extra damage on his guard        (Earth)
--   slowed     his average loss of speed        (Water)
function KitPrint.nature(def,N,nature,opts)
	opts=opts or {kunai=true,blade=true,mastery=true}
	local inf=N and N.Infusion
	local e=inf and inf[nature]
	if not e then return nil end
	local gap=num(inf.Gap) or 4
	local strong=if opts.mastery then num(inf.Strong) or 1 else 1
	local tool=def.ToolMastery or {}
	local throw=tool.Kind=="kunai" or tool.Kind=="shuriken"
	local carriers={}
	if opts.blade then table.insert(carriers,"blade") end
	if opts.kunai and throw then table.insert(carriers,tostring(tool.Kind)) end
	local on=#carriers>0
	local out={nature=nature,carriers=carriers,answer=e.Answer,gap=gap,strong=strong}
	if num(e.Burn) then out.burnDps=if on then round(e.Burn*strong/gap,3) else 0 end
	if num(e.Stun) then out.frozen=if on then round(e.Stun*strong/gap,4) else 0 end
	if num(e.GuardDamage) then out.guardDps=if on then round(e.GuardDamage*strong/gap,3) else 0 end
	if num(e.Slow) then out.slowed=if on then round(e.Slow*strong*(num(e.SlowTime) or 0)/gap,4) else 0 end
	if num(e.KunaiRange) then
		-- the thrown blade flies further and faster
		local thrown=opts.kunai and throw
		out.kunaiRange=if thrown then round(1+(e.KunaiRange-1)*strong,3) else 1
		out.kunaiSpeedBase=num(tool.Speed)
		out.kunaiSpeed=if thrown then round((num(tool.Speed) or 0)*(1+((num(e.KunaiSpeed) or 1)-1)*strong),2) else num(tool.Speed)
		-- (21/11, Server/NinjaArts.gust) the blade's last hit throws the body
		-- further, by the same factor: a kit without a throw gets this one
		out.push=if opts.blade then round(1+(e.KunaiRange-1)*strong,3) else 1
	end
	return out
end

-- The tree's nodes a player can stack: every wired one, in tree order, its
-- requirements met, the first of each exclusive choice.
function KitPrint.fullTree(SkillBuilds,id)
	local tree=SkillBuilds.tree(id)
	if not tree then return nil end
	local active,groups,list={},{},{}
	for _,node in tree.Nodes do
		local ok=SkillBuilds.wired(id,node.Id)
		for _,need in node.Requires or {} do if not active[need] then ok=false end end
		if ok and node.RequiresAny then
			local any=false
			for _,need in node.RequiresAny do if active[need] then any=true end end
			ok=any
		end
		if ok and node.Exclusive and groups[node.Exclusive] then ok=false end
		if ok then
			active[node.Id]=true;table.insert(list,node.Id)
			if node.Exclusive then groups[node.Exclusive]=node.Id end
		end
	end
	return list,#tree.Nodes
end

function KitPrint.compute(mods)
	local out={version=KitPrint.Version,kits={},order={}}
	for _,id in mods.BetaRoster do
		local def=mods.Fighters[id]
		if def then
			table.insert(out.order,id)
			local entry={id=id,name=def.Name,title=def.Title,versions={}}
			entry.versions.prodige=KitPrint.kit(def,mods.Attacks,mods.Config)
			local SB=mods.SkillBuilds
			if SB and SB.tree(id) then
				local ok,start=pcall(function() return SB.build(id,{},{gated=true}) end)
				if ok and start then
					entry.versions.depart=KitPrint.kit(start.def,mods.Attacks,mods.Config)
					entry.locks=start.locks
				end
				-- the whole tree, as a player's kit (gated: what no node of it
				-- gives stays locked)
				local nodes,total=KitPrint.fullTree(SB,id)
				local ok2,full=pcall(function()
					local kit=SB.apply(id,nodes)
					if SB.gate then SB.gate(kit) end
					return kit
				end)
				if ok2 and full then
					entry.versions.arbre=KitPrint.kit(full.def,mods.Attacks,mods.Config)
					entry.tree={nodes=#nodes,total=total,spent=full.spent,locks=full.locks}
					-- (21/11, DEC-045) the node at the top that changes a technique's
					-- nature (`Transform = true`); a kit may have none yet
					local transform={}
					for _,node in SB.tree(id).Nodes do
						if node.Transform==true then table.insert(transform,{id=node.Id,name=node.Name}) end
					end
					entry.tree.transform=transform
					-- then each chakra nature, with the whole infusion branch
					if mods.NinjaTree then
						entry.natures={}
						for _,nature in mods.NinjaTree.Natures or {} do
							entry.natures[nature]=KitPrint.nature(full.def,mods.NinjaTree,nature)
						end
					end
				end
			end
			out.kits[id]=entry
		end
	end
	return out
end

return KitPrint
