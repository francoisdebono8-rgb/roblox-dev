-- Every authored clip of the game (Client/AuthoredClips* and AuthoredJutsu*, the
-- same merge Client/AuthoredMotion does: a jutsu clip of the same name wins) as
-- one JSON file, for tools/syphodev/audit_clips.py.
--   lune run tools/syphodev/clips_dump.luau <out.json>      (from games/ninja-duel)
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local luau=require("@lune/luau")
local process=require("@lune/process")

local function load(path)
	return luau.load(fs.readFile(path),{debugName=path})()
end
local all,source={},{}
local function add(prefix)
	local i=1
	while fs.isFile(("src/Client/%s%d.luau"):format(prefix,i)) do
		local path=("src/Client/%s%d.luau"):format(prefix,i)
		for name,clip in load(path) do all[name]=clip;source[name]=path end
		i+=1
	end
	return i-1
end
local a=add("AuthoredClips")
local j=add("AuthoredJutsu")
local n=0
for name,clip in all do clip.source=source[name];n+=1 end
fs.writeFile(process.args[1] or "clips.json",serde.encode("json",all))
print(("%d clips from %d AuthoredClips and %d AuthoredJutsu modules"):format(n,a,j))
