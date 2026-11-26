-- The street duel's edge, felt (27/11, passe 3, OUTILLEUR INBOX-OUTILLEUR-
-- PASSE3-20261127: in a duel between two players on the Plaza, bodies
-- stopped 36 studs from its centre « sans mur visible »). A duel in Konoha
-- holds its fighters inside its place's circle (Server/Combat:clamp, the
-- site's radius); the server draws its red ink line (Server/Hub.duelRings).
-- Where a fighter presses on that edge, it glows under him, so the stop reads
-- as the ring's edge. Nothing shows at rest (Studio 27/11: a second line over
-- the red one, chalk or neon, was one line too many).
-- Presentation only: the rule is the server's.
local Ring={}
Ring.__index=Ring
Ring.SEGMENTS=60
-- The line at rest, and where a fighter is close (Transparency).
-- Unseen at rest; glowing where a fighter presses on the edge.
Ring.FAINT=1
Ring.LIT=.2
-- A fighter this near the edge (studs) lights the segments next to him.
Ring.NEAR=6
Ring.GLOW=Color3.fromRGB(255,196,120)

function Ring.new()
	return setmetatable({key=nil,parts={},folder=nil},Ring)
end

-- (pure) The ring a snapshot asks for: {key, origin, radius}, or nil (not a
-- duel, not in the street).
function Ring.wanted(data)
	local site=data and data.site
	if not (data and data.phase=="Duel" and type(site)=="table" and site.street==true) then return nil end
	if typeof(data.origin)~="Vector3" or type(site.radius)~="number" or site.radius<=0 then return nil end
	local o=data.origin
	return {key=string.format("%s:%.1f:%.1f:%.1f",tostring(site.key),o.X,o.Z,site.radius),origin=o,radius=site.radius}
end

-- (pure) The segments of a circle of `radius` round `origin`: {at (flat, at
-- the origin's height), angle, length}.
function Ring.points(origin,radius,n)
	n=n or Ring.SEGMENTS
	local list={}
	local length=2*math.pi*radius/n*1.04
	for i=1,n do
		local a=(i-.5)/n*math.pi*2
		table.insert(list,{at=origin+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius),angle=a,length=length})
	end
	return list
end

-- (pure) How lit a segment at `at` is with fighters at `positions`: LIT
-- next to one within NEAR of the edge, FAINT otherwise.
function Ring.shade(at,positions,origin,radius)
	for _,p in positions do
		local flat=Vector3.new(p.X-origin.X,0,p.Z-origin.Z)
		if radius-flat.Magnitude<=Ring.NEAR then
			local d=(Vector3.new(p.X,0,p.Z)-Vector3.new(at.X,0,at.Z)).Magnitude
			if d<=Ring.NEAR*1.6 then return Ring.LIT end
		end
	end
	return Ring.FAINT
end

function Ring:clear()
	if self.folder then self.folder:Destroy() end
	self.folder=nil;self.parts={};self.key=nil
end

function Ring:build(want)
	self:clear()
	local folder=Instance.new("Folder");folder.Name="NinjaStreetRing"
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={}
	for _,p in game:GetService("Players"):GetPlayers() do if p.Character then table.insert(exclude,p.Character) end end
	local duels=workspace:FindFirstChild("NinjaDuels");if duels then table.insert(exclude,duels) end
	params.FilterDescendantsInstances=exclude
	for _,seg in Ring.points(want.origin,want.radius) do
		-- on the ground there (a step, a slope): the first surface under it
		local hit=workspace:Raycast(seg.at+Vector3.new(0,12,0),Vector3.new(0,-30,0),params)
		local y=if hit then hit.Position.Y else want.origin.Y-3
		local p=Instance.new("Part")
		p.Name="Edge";p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
		p.Material=Enum.Material.Neon;p.Color=Ring.GLOW;p.Transparency=Ring.FAINT
		p.Size=Vector3.new(.9,.08,seg.length)
		-- along the circle: its length tangent to it
		p.CFrame=CFrame.new(Vector3.new(seg.at.X,y+.05,seg.at.Z))*CFrame.Angles(0,-seg.angle,0)
		p.Parent=folder
		table.insert(self.parts,{part=p,at=seg.at})
	end
	folder.Parent=workspace
	self.folder=folder;self.key=want.key;self.want=want
end

function Ring:render(data)
	local want=Ring.wanted(data)
	if not want then if self.key then self:clear() end return end
	if want.key~=self.key then self:build(want) end
	local positions={}
	for _,f in {data.human,data.bot} do
		if type(f)=="table" and typeof(f.position)=="Vector3" then table.insert(positions,f.position) end
	end
	for _,s in self.parts do
		local t=Ring.shade(s.at,positions,want.origin,want.radius)
		if s.part.Transparency~=t then
			s.part.Transparency=t
		end
	end
end

return Ring
