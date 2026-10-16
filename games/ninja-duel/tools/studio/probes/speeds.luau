-- Server: Lee's walk and sprint speeds, base then Fifth Gate (measured over 1 s each).
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local function measure(sprint)
	dev:Invoke("move","human",Vector3.zero);dev:Invoke("place",Vector3.new(-30,3,40),Vector3.new(30,3,-60));task.wait(.4)
	dev:Invoke("sprint","human",sprint)
	local p0=dev:Invoke("state").human.position;local t0=os.clock()
	local peak=0
	while os.clock()-t0<1.2 do
		dev:Invoke("move","human",Vector3.new(0,0,-1),.3);dev:Invoke("sprint","human",sprint)
		local v=dev:Invoke("state").human.velocity;local f=Vector3.new(v.X,0,v.Z).Magnitude
		if f>peak then peak=f end
		task.wait(.05)
	end
	local p1=dev:Invoke("state").human.position
	dev:Invoke("move","human",Vector3.zero);dev:Invoke("sprint","human",false)
	return string.format("avg %.1f peak %.1f",(Vector3.new(p1.X-p0.X,0,p1.Z-p0.Z)).Magnitude/(os.clock()-t0),peak)
end
local out={}
table.insert(out,"base walk: "..measure(false))
table.insert(out,"base sprint: "..measure(true))
dev:Invoke("health","human",30);task.wait(.1)
local r=dev:Invoke("act","human","Awaken")
task.wait(1.2)
table.insert(out,"awaken: "..tostring(r and r.ok)..":"..tostring(r and r.reason))
table.insert(out,"gate walk: "..measure(false))
table.insert(out,"gate sprint: "..measure(true))
return table.concat(out," | ")
