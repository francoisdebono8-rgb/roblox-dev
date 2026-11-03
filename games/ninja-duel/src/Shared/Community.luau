-- Where the players meet outside the game (beta, user 03/11: "find how to
-- bring people to the Discord"). The invite is shown in the game only to the
-- players Roblox lets see a Discord reference (PolicyService: age, country);
-- everyone else never sees it, and the in-game BUG / IDEA form stays their way
-- to reach us. Text only: Roblox does not open outside links from a game.
local Community={}

Community.DiscordInvite="discord.gg/mJ6Gyax7W"

-- True when this player may be shown the Discord invite. Yields (a web call);
-- false on any doubt.
function Community.canShowDiscord(player)
	local ok,allowed=pcall(function()
		local info=game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(player)
		for _,name in info.AllowedExternalLinkReferences or {} do
			if name=="Discord" then return true end
		end
		return false
	end)
	return ok and allowed==true
end
return Community
