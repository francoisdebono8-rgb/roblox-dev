local modules = script.Parent.Parent.BrickKitMonetization.Modules
local GamePassService = require(modules.GamePassService)
local PurchaseService = require(modules.PurchaseService)

local ownsPass = true
local rewardCount = 0
local gamePassMarketplace = {
	UserOwnsGamePassAsync = function()
		return ownsPass
	end,
}
local gamePassService = GamePassService.new(gamePassMarketplace, function()
	return function()
		rewardCount += 1
		return true
	end
end)
local player = { UserId = 42 }
local passEntry = { id = 55, rewardHandler = "WalkSpeedMinimum", params = {} }

assert(gamePassService:apply(player, passEntry) == true)
assert(rewardCount == 1, "owned pass must apply its reward")
ownsPass = false
assert(gamePassService:apply(player, passEntry) == true)
assert(rewardCount == 1, "unowned pass must not apply its reward")

local failingGamePassService = GamePassService.new({
	UserOwnsGamePassAsync = function()
		error("Marketplace unavailable")
	end,
}, function()
	return function()
		rewardCount += 1
		return true
	end
end)
assert(failingGamePassService:apply(player, passEntry) == false)
assert(rewardCount == 1, "Marketplace errors must fail closed")

local now = 0
local promptCount = 0
local purchaseMarketplace = {
	PromptProductPurchase = function(_, _, id)
		assert(id == 123)
		promptCount += 1
	end,
	PromptGamePassPurchase = function()
		error("unexpected Game Pass prompt")
	end,
}
local purchaseService = PurchaseService.new(purchaseMarketplace, {
	{ type = "DeveloperProduct", id = 123, fallbackLabel = "Allowed" },
}, function()
	return now
end)

assert(purchaseService:requestPurchase(player, "DeveloperProduct", 123) == true)
assert(promptCount == 1)
assert(purchaseService:requestPurchase(player, "DeveloperProduct", 123) == false)
assert(promptCount == 1, "purchase requests must be rate limited")

now = 2
assert(purchaseService:requestPurchase(player, "DeveloperProduct", 999) == false)
assert(promptCount == 1, "unknown IDs must not open a prompt")
now = 4
assert(purchaseService:requestPurchase(player, "DeveloperProduct", "123") == false)
assert(promptCount == 1, "invalid argument types must not open a prompt")

now = 6
local catalog = purchaseService:getCatalog(player)
assert(type(catalog) == "table" and #catalog == 1)
assert(catalog[1].rewardHandler == nil and catalog[1].params == nil, "catalog must not expose reward configuration")
assert(purchaseService:getCatalog(player) == nil, "catalog requests must be rate limited")

return true
