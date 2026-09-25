local modules = script.Parent.Parent.BrickKitMonetization.Modules
local ReceiptRouter = require(modules.ReceiptRouter)

local grantCount = 0
local marked = false
local ledger = {
	check = function()
		return true, marked
	end,
	markProcessed = function()
		marked = true
		return true
	end,
}
local router = ReceiptRouter.new({
	ledger = ledger,
	productsById = {
		[123] = { rewardHandler = "Reward", params = { amount = 5 } },
	},
	resolveReward = function(name)
		if name == "Reward" then
			return function()
				grantCount += 1
				return true
			end
		end
	end,
	getPlayerByUserId = function()
		return {}
	end,
	processedDecision = "Processed",
	retryDecision = "NotProcessedYet",
})

local receipt = { PurchaseId = "purchase-1", ProductId = 123, PlayerId = 7 }
assert(router:process(receipt) == "Processed")
assert(router:process(receipt) == "Processed")
assert(grantCount == 1, "a local receipt repeat must not grant twice")

local failedLedgerRouter = ReceiptRouter.new({
	ledger = {
		check = function()
			return false, false, "unavailable"
		end,
		markProcessed = function()
			error("must not mark")
		end,
	},
	productsById = {
		[123] = { rewardHandler = "Reward", params = {} },
	},
	resolveReward = function()
		return function()
			grantCount += 1
			return true
		end
	end,
	getPlayerByUserId = function()
		return {}
	end,
	processedDecision = "Processed",
	retryDecision = "NotProcessedYet",
})

assert(failedLedgerRouter:process({ PurchaseId = "purchase-2", ProductId = 123, PlayerId = 7 }) == "NotProcessedYet")
assert(grantCount == 1, "ledger failure before grant must fail closed")
assert(failedLedgerRouter:process({ PurchaseId = "purchase-3", ProductId = 999, PlayerId = 7 }) == "NotProcessedYet")
assert(grantCount == 1, "unknown product ID must not grant")

return true
