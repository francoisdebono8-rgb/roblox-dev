-- The heads on Konoha's cliff (14/11, user: « les têtes sont moches […] à
-- terme ça sera les champions, on peut mettre le dev aussi et des trucs
-- drôles pour l'instant »). Four places (Shared/HubMap.Heads):
--   1  the game's creator (game.CreatorId, or Config.Hub.DevUserId);
--   2-4 the last three players who won the tournament, newest first, the
--       same on every server (a DataStore list, MessagingService to tell the
--       other servers at once, a refresh every 5 minutes as a safety).
-- Each one is his own Roblox avatar's head carved in stone by the server
-- (his head and its hair and hats, scaled to the cliff, in rock). While a
-- place is empty, or an avatar cannot load (a local file in Studio), the
-- place keeps its funny head (the ANIMATOR's HeadFunny1..4, Client/HubDress):
-- a carved place turns that unit DressOff and hides its parts (the solid
-- Face stays solid). Presentation only: no gameplay rule lives here.
-- Roblox services are injected (ChampionCliff.new(folder, svc)) so the suite
-- runs it on fakes (ChampionCliff.new(folder, svc):run()).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local HubMap=require(Shared.HubMap)
local Config=require(Shared.Config)

local Cliff={}
Cliff.__index=Cliff
Cliff.MAX=3
Cliff.STORE="NinjaDuelChampions"
Cliff.KEY="latest_v1"
Cliff.TOPIC="NinjaDuelChampion"
Cliff.REFRESH=300
-- A carved head's height (the funny heads fill 26 x 30 x 8).
Cliff.HEIGHT=28
Cliff.STONE=Color3.fromRGB(150,136,118)
-- How far into the cliff a head's centre sits (its face comes out of it).
Cliff.SINK=4

-- ------------------------------------------------------------ pure rules
-- A champion's list as the store keeps it: three at most, ids only checked.
function Cliff.clean(list)
	local out={}
	if type(list)~="table" then return out end
	for _,e in list do
		if #out>=Cliff.MAX then break end
		if type(e)=="table" and type(e.id)=="number" and e.id>0 and e.id==math.floor(e.id) then
			table.insert(out,{id=e.id,name=string.sub(tostring(e.name or ""),1,24),at=tonumber(e.at) or 0})
		end
	end
	return out
end
-- A new champion first; he holds one place only; the oldest goes.
function Cliff.push(list,entry)
	local out={{id=entry.id,name=entry.name,at=entry.at}}
	for _,e in Cliff.clean(list) do
		if #out>=Cliff.MAX then break end
		if e.id~=entry.id then table.insert(out,e) end
	end
	return out
end
-- Who goes where: {[1]=creator, [2..4]=champions} (nil: a funny head).
function Cliff.plan(devId,list)
	local slots={}
	if type(devId)=="number" and devId>0 then slots[1]=devId end
	for i=1,Cliff.MAX do slots[i+1]=list[i] and list[i].id or nil end
	return slots
end
-- Where a carved head goes: its centre a little into the cliff, facing the
-- village (+z).
function Cliff.placeOf(k)
	local at=HubMap.Origin+HubMap.Heads[k]-Vector3.new(0,0,Cliff.SINK)
	return CFrame.new(at)*CFrame.Angles(0,math.pi,0)
end

-- ------------------------------------------------------------ the stone head
-- A player's avatar head, carved: his head with its hair, hats and face
-- accessories, in rock, scaled to the cliff. Yields (Roblox web calls);
-- returns nil when the avatar cannot be loaded.
local KEEP={Hat=true,Hair=true,Face=true,Eyebrow=true,Eyelash=true}
function Cliff.stoneHead(userId)
	local Players=game:GetService("Players")
	local ok,model=pcall(function()
		local desc=Players:GetHumanoidDescriptionFromUserId(userId)
		return Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then return nil end
	local head=model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then model:Destroy() return nil end
	local keep={[head]=true}
	for _,acc in model:GetChildren() do
		if acc:IsA("Accessory") then
			local kind="Unknown"
			pcall(function() kind=acc.AccessoryType.Name end)
			local handle=acc:FindFirstChild("Handle")
			if KEEP[kind] and handle then keep[handle]=true else acc:Destroy() end
		end
	end
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if not keep[d] then d:Destroy() end
		elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Humanoid") or d:IsA("SurfaceAppearance") then
			d:Destroy()
		end
	end
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false;d.CastShadow=true
			d.Material=Enum.Material.Rock;d.Color=Cliff.STONE
			if d:IsA("MeshPart") then pcall(function() d.TextureID="" end) end
		elseif d:IsA("SpecialMesh") then
			d.TextureId=""
		elseif d:IsA("Decal") then
			-- the face, engraved: dark, a little worn
			d.Color3=Color3.fromRGB(60,54,48);d.Transparency=.25
		end
	end
	model.Name="ChampionHead";model.PrimaryPart=head
	local size=head.Size.Y
	if size>0 then pcall(function() model:ScaleTo(model:GetScale()*Cliff.HEIGHT/size) end) end
	return model
end

-- ------------------------------------------------------------ services
function Cliff.defaultServices()
	local svc={}
	pcall(function() svc.store=game:GetService("DataStoreService"):GetDataStore(Cliff.STORE) end)
	pcall(function() svc.messaging=game:GetService("MessagingService") end)
	svc.devId=function()
		local id=Config.Hub and Config.Hub.DevUserId
		if type(id)=="number" and id>0 then return id end
		local found=nil
		pcall(function() if game.CreatorType==Enum.CreatorType.User and game.CreatorId>0 then found=game.CreatorId end end)
		return found
	end
	svc.head=Cliff.stoneHead
	svc.spawn=function(fn,...) task.spawn(fn,...) end
	svc.every=function(seconds,fn) task.spawn(function() while true do task.wait(seconds);fn() end end) end
	svc.now=function() return os.time() end
	return svc
end

-- ------------------------------------------------------------ the cliff
function Cliff.new(folder,svc)
	local self=setmetatable({folder=folder,svc=svc or Cliff.defaultServices(),list={},carved={},serial={},devId=nil},Cliff)
	self.holder=Instance.new("Folder");self.holder.Name="CliffHeads";self.holder.Parent=folder
	return self
end
function Cliff:slotUnit(k)
	for _,d in self.folder:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("HeadSlot")==k then return d end
	end
	return nil
end
-- The funny head back (or kept), its parts seen.
function Cliff:release(k)
	local u=self:slotUnit(k)
	if not u then return end
	u:SetAttribute("DressOff",nil)
	for _,p in u:GetDescendants() do if p:IsA("BasePart") then p.Transparency=0 end end
end
-- A player's stone head at place k (asynchronous: a newer plan wins).
function Cliff:carve(k,userId)
	self.serial[k]=(self.serial[k] or 0)+1
	local serial=self.serial[k]
	self.svc.spawn(function()
		local model=self.svc.head(userId)
		if self.serial[k]~=serial then if model then model:Destroy() end return end
		if not model then self:release(k);return end
		model:SetAttribute("UserId",userId);model:SetAttribute("HeadSlot",k)
		model:PivotTo(Cliff.placeOf(k))
		model.Parent=self.holder
		self.carved[k].model=model
		local u=self:slotUnit(k)
		if u then
			u:SetAttribute("DressOff",true)
			for _,p in u:GetDescendants() do if p:IsA("BasePart") then p.Transparency=1 end end
		end
	end)
end
-- Every place to its plan: a new face carved, an old one taken away.
function Cliff:apply()
	local slots=Cliff.plan(self.devId,self.list)
	for k=1,#HubMap.Heads do
		local want=slots[k]
		local have=self.carved[k]
		if want~=(have and have.id) then
			if have and have.model then have.model:Destroy() end
			self.carved[k]=nil
			if want then
				self.carved[k]={id=want}
				self:carve(k,want)
			else
				self.serial[k]=(self.serial[k] or 0)+1
				self:release(k)
			end
		end
	end
end
-- The champions every server shows (the store; nothing without one).
function Cliff:refresh()
	local store=self.svc.store
	if not store then return end
	local ok,data=pcall(function() return store:GetAsync(Cliff.KEY) end)
	if ok then self.list=Cliff.clean(data);self:apply() end
end
function Cliff:run()
	self.devId=self.svc.devId()
	self:refresh()
	self:apply()
	local messaging=self.svc.messaging
	if messaging then
		pcall(function() messaging:SubscribeAsync(Cliff.TOPIC,function() self:refresh() end) end)
	end
	if self.svc.every then self.svc.every(Cliff.REFRESH,function() self:refresh() end) end
	return self
end
-- A player won the tournament: his face goes up here at once, then on every
-- server.
function Cliff:crown(player)
	local entry={id=player.UserId,name=player.Name,at=self.svc.now()}
	self.list=Cliff.push(self.list,entry)
	self:apply()
	local store,messaging=self.svc.store,self.svc.messaging
	self.svc.spawn(function()
		if store then pcall(function() store:UpdateAsync(Cliff.KEY,function(old) return Cliff.push(old,entry) end) end) end
		if messaging then pcall(function() messaging:PublishAsync(Cliff.TOPIC,{id=entry.id}) end) end
	end)
end

-- ------------------------------------------------------------ the game's one
Cliff.current=nil
function Cliff.begin(folder)
	if Cliff.current or not folder then return Cliff.current end
	Cliff.current=Cliff.new(folder):run()
	return Cliff.current
end
-- Called by Server/Tournament when a player wins the tournament.
function Cliff.champion(player)
	if Cliff.current then Cliff.current:crown(player) return end
	-- no village on this server: the store still learns him
	local svc=Cliff.defaultServices()
	local entry={id=player.UserId,name=player.Name,at=svc.now()}
	svc.spawn(function()
		if svc.store then pcall(function() svc.store:UpdateAsync(Cliff.KEY,function(old) return Cliff.push(old,entry) end) end) end
		if svc.messaging then pcall(function() svc.messaging:PublishAsync(Cliff.TOPIC,{id=entry.id}) end) end
	end)
end

return Cliff
