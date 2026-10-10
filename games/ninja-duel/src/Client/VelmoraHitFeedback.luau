-- Adapted from Velmora src/client/Combat/HitFeedback.luau.
-- Copyright (c) 2026 Yashveer Singh, MIT.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Feedback={}
function Feedback.burst(position,color,damage,blocked)
	local anchor=Instance.new("Part");anchor.Name="LocalImpact";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.Transparency=1;anchor.Size=Vector3.one;anchor.Position=position;anchor.Parent=workspace
	local light=Instance.new("PointLight");light.Color=color;light.Brightness=if blocked then 5 else 3;light.Range=if blocked then 11 else 8;light.Parent=anchor
	TweenService:Create(light,TweenInfo.new(.2),{Brightness=0}):Play()
	for i=1,(if blocked then 10 else 7) do
		local shard=Instance.new("Part");shard.Anchored=true;shard.CanCollide=false;shard.CanQuery=false;shard.Material=Enum.Material.Neon;shard.Color=color;shard.Size=Vector3.new(.08,.08,math.random(5,11)/10);shard.CFrame=CFrame.lookAt(position,position+Vector3.new(math.random()-0.5,math.random()-0.5,math.random()-0.5));shard.Parent=workspace
		TweenService:Create(shard,TweenInfo.new(.18,Enum.EasingStyle.Quad),{CFrame=shard.CFrame*CFrame.new(0,0,-math.random(2,5)),Transparency=1}):Play();Debris:AddItem(shard,.22)
	end
	if damage and damage>0 then
		local bill=Instance.new("BillboardGui");bill.Size=UDim2.fromOffset(80,40);bill.StudsOffset=Vector3.new(0,2.5,0);bill.AlwaysOnTop=true;bill.Parent=anchor
		local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=string.format("-%d",math.floor(damage+.5));label.TextColor3=color;label.TextStrokeTransparency=.15;label.Font=Enum.Font.GothamBlack;label.TextScaled=true;label.Parent=bill
		TweenService:Create(bill,TweenInfo.new(.45),{StudsOffset=Vector3.new(0,4.5,0)}):Play();TweenService:Create(label,TweenInfo.new(.45),{TextTransparency=1,TextStrokeTransparency=1}):Play()
	end
	Debris:AddItem(anchor,.55)
end
return Feedback
