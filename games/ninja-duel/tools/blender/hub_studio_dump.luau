-- Studio command bar, after the 3D Importer has inserted the FBX of
-- tools/blender/hub_fbx.py: prints the JSON for imports/hub/Hub.studio.json
-- (every MeshPart named <Model>__<Piece> in the workspace, its mesh id and size).
local HttpService=game:GetService("HttpService")
local out={}
for _,d in workspace:GetDescendants() do
	if d:IsA("MeshPart") and string.find(d.Name,"__",1,true) and d.MeshId~="" then
		table.insert(out,{name=d.Name,mesh=d.MeshId,size={d.Size.X,d.Size.Y,d.Size.Z}})
	end
end
table.sort(out,function(a,b) return a.name<b.name end)
print(HttpService:JSONEncode(out))
print(#out.." pieces")
