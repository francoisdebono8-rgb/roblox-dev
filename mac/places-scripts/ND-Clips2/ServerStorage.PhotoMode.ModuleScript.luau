return function(white,show)
 game.Selection:Set({})
 local set=workspace:FindFirstChild("PhotoSet")
 local hold=game.ServerStorage:FindFirstChild("PhotoHold") or Instance.new("Folder",game.ServerStorage) hold.Name="PhotoHold"
 set.BG.Color=white and Color3.new(1,1,1) or Color3.new(0,0,0)
 if show then for _,c in hold:GetChildren() do c.Parent=set end
 else for _,c in set:GetChildren() do if c:IsA("Model") then c.Parent=hold end end end
 return "ok"
end