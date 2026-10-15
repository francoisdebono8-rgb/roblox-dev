-- Included only in the QA artifact. Does not modify any player profile.
task.wait(3)
assert(game:GetService('RunService'):IsStudio(),'QA scripts must never ship')
local root=workspace:WaitForChild('ForgeAndFlex',10); assert(root)
for i=1,6 do
 local plot=root:FindFirstChild('Workshop '..i); assert(plot and plot:FindFirstChild('Anvil') and plot:FindFirstChild('Furnace'))
 assert(plot:FindFirstChild('Zone gate 2') and plot:FindFirstChild('Zone gate 3'))
end
local S=game.ReplicatedStorage.WFT
local W=require(S.WeaponModel)
local Profile=require(S.Profile)
local Http=game:GetService('HttpService')
local p=Profile.new(os.time()); p.Coins=100; p.Inventory={{Id='native',Blueprint=9,Rarity=6,Mutation=5,Locked=true,Displayed=false}}
local loaded=Profile.load(Http:JSONDecode(Http:JSONEncode(p)),os.time())
assert(loaded.Coins==100 and loaded.Inventory[1].Locked and loaded.Inventory[1].Mutation==5)
local scratch=Instance.new('Folder')
for i=1,9 do
 local m=W.build({Blueprint=i,Rarity=6,Mutation=5},scratch,CFrame.new(),1)
 assert(#m:GetChildren()>=4)
 for _,v in ipairs(m:GetChildren()) do if v:IsA('BasePart') then assert(v.Anchored and not v.CanCollide) end end
end
scratch:Destroy()
for _,player in ipairs(game:GetService('Players'):GetPlayers()) do
 local index=player:GetAttribute('Plot'); local plot=index and root:FindFirstChild('Workshop '..index)
 if plot and player.Character then assert((player.Character:GetPivot().Position-plot:FindFirstChild('Workshop spawn').Position).Magnitude<18,'Player spawned away from assigned forge') end
end
print('WFT_NATIVE_QA PASS: 6 plots, 9 weapon models, safe parts, native JSON save/load')
