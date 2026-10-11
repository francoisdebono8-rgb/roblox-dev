local fs=require("@lune/fs");local roblox=require("@lune/roblox");local process=require("@lune/process")
local instances=roblox.deserializeModel((fs.readFile(process.args[1]):gsub("^<%?xml.-%?>%s*", "")))
fs.writeFile(process.args[2],roblox.serializeModel(instances))
print("Binary plugin packaged")
