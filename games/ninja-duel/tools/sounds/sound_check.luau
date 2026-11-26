-- The sound check (OUTILLEUR, passe commune 3, 26/11; DEC-055: « le
-- contrôle des sons : chaque son se charge, a la bonne durée et un volume
-- cohérent, avec sa licence notée »).
--
-- A client module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py sound              (eval_client_runtime)
--   _G.NDSoundCheck.start()   every sound of Shared/SoundBank.all() and the
--                             street's blows (Client/HubFightClient's SOUNDS):
--                             loaded or not, its length, its loudness
--   _G.NDSoundCheck.state()   "son i/n" then "fini"
--   _G.NDSoundCheck.read()    the rows, as JSON (tools/sounds/report.py)
--   _G.NDSoundCheck.now()     what plays now (SoundService: music, ambience)
--
-- The loudness is measured without a sound heard: each sound plays in a
-- SoundGroup at volume 0, `Sound.PlaybackLoudness` sampled 0,6 s at five
-- places of a long track (once from the start for a short one). `effective`
-- is that loudness times the bank's volume: what the mix gives it, to
-- compare with its layer's level (SoundBank.LEVEL) and with the other layers.
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")

local Check={}
-- The street's blows (Client/HubFightClient: SOUNDS and their volumes).
Check.STREET={
	{key="street.hit",id="rbxassetid://9117971636",volume=.35},
	{key="street.heavy",id="rbxassetid://9117969717",volume=.5},
	{key="street.wood",id="rbxassetid://9114221862",volume=.35},
	{key="street.stone",id="rbxassetid://9118588165",volume=.35},
	{key="street.challenge",id="rbxassetid://9126284094",volume=.35},
}
local rows={}
local status="vide"
local function r1(x) return math.floor(x*10+.5)/10 end

local function list()
	local SB=require(RS:WaitForChild("NinjaDuel"):WaitForChild("SoundBank"))
	local out={}
	for _,e in SB.all() do
		local s=e.sound
		table.insert(out,{key=e.key,id=s.id,name=s.name,source=s.source,length=s.length,bankLoud=s.loudness,volume=s.volume,layer=s.layer,level=SB.LEVEL[s.layer]})
	end
	for _,e in Check.STREET do table.insert(out,{key=e.key,id=e.id,volume=e.volume,layer="street"}) end
	return out
end

local function measure(e,group)
	local s=Instance.new("Sound")
	s.SoundId=e.id;s.SoundGroup=group;s.Volume=e.volume or 1;s.Parent=SoundService
	local fetch="?"
	pcall(function() ContentProvider:PreloadAsync({s},function(_,st) fetch=tostring(st) end) end)
	local t0=os.clock()
	while not s.IsLoaded and os.clock()-t0<10 do task.wait(.1) end
	local row={}
	for k,v in e do row[k]=v end
	row.loaded=s.IsLoaded;row.fetch=fetch;row.measured=r1(s.TimeLength)
	if s.IsLoaded and s.TimeLength>0 then
		s:Play()
		local spots=if s.TimeLength>8 then 5 else 1
		local mean,peak=0,0
		for k=1,spots do
			s.TimePosition=if spots>1 then s.TimeLength*k/(spots+1) else 0
			local sum,n=0,0
			local t1=os.clock()
			local span=if spots>1 then .6 else math.min(s.TimeLength,1.2)
			while os.clock()-t1<span do
				task.wait()
				local l=s.PlaybackLoudness
				peak=math.max(peak,l);sum+=l;n+=1
			end
			mean+=if n>0 then sum/n else 0
		end
		s:Stop()
		row.loudness=r1(mean/spots);row.peak=r1(peak)
		row.effective=r1(mean/spots*(e.volume or 1));row.effectivePeak=r1(peak*(e.volume or 1))
	end
	s:Destroy()
	return row
end

function Check.start()
	if status=="en cours" then return "déjà en cours" end
	rows={};status="en cours"
	local group=SoundService:FindFirstChild("NDSilent") or Instance.new("SoundGroup")
	group.Name="NDSilent";group.Volume=0;group.Parent=SoundService
	local all=list()
	task.spawn(function()
		for i,e in all do
			status="son "..i.."/"..#all
			local ok,row=pcall(measure,e,group)
			table.insert(rows,if ok then row else {key=e.key,id=e.id,error=tostring(row)})
		end
		status="fini"
	end)
	return #all.." sons"
end
function Check.state() return status end
function Check.read() return HttpService:JSONEncode(rows) end
function Check.now()
	local out={}
	for _,d in SoundService:GetDescendants() do
		if d:IsA("Sound") and d.IsPlaying then
			table.insert(out,{name=d.Name,id=d.SoundId,volume=r1(d.Volume*100)/100,group=d.SoundGroup and d.SoundGroup.Name})
		end
	end
	return HttpService:JSONEncode(out)
end

return Check
