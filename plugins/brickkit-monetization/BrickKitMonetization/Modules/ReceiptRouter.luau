local ReceiptRouter = {}
ReceiptRouter.__index = ReceiptRouter

local function validReceipt(receiptInfo)
	return type(receiptInfo) == "table"
		and type(receiptInfo.PurchaseId) == "string"
		and receiptInfo.PurchaseId ~= ""
		and type(receiptInfo.ProductId) == "number"
		and receiptInfo.ProductId > 0
		and type(receiptInfo.PlayerId) == "number"
		and receiptInfo.PlayerId > 0
end

function ReceiptRouter.new(options)
	return setmetatable({
		_ledger = assert(options.ledger, "ledger is required"),
		_productsById = assert(options.productsById, "productsById is required"),
		_resolveReward = assert(options.resolveReward, "resolveReward is required"),
		_getPlayerByUserId = assert(options.getPlayerByUserId, "getPlayerByUserId is required"),
		_processedDecision = assert(options.processedDecision, "processedDecision is required"),
		_retryDecision = assert(options.retryDecision, "retryDecision is required"),
		_log = options.log or function() end,
		_localState = {},
	}, ReceiptRouter)
end

function ReceiptRouter:_markGranted(purchaseId, productId)
	local marked, markError = self._ledger:markProcessed(purchaseId)
	if not marked then
		self._log("warn", "Receipt ledger write failed for product " .. tostring(productId) .. ": " .. tostring(markError))
		return self._retryDecision
	end

	self._localState[purchaseId] = "processed"
	return self._processedDecision
end

function ReceiptRouter:process(receiptInfo)
	if not validReceipt(receiptInfo) then
		self._log("warn", "Rejected malformed receipt")
		return self._retryDecision
	end

	local purchaseId = receiptInfo.PurchaseId
	local productId = receiptInfo.ProductId
	local localState = self._localState[purchaseId]
	if localState == "processed" then
		return self._processedDecision
	elseif localState == "granted" then
		return self:_markGranted(purchaseId, productId)
	elseif localState == "processing" then
		return self._retryDecision
	end

	local entry = self._productsById[productId]
	if not entry then
		self._log("warn", "Rejected receipt for unknown product " .. tostring(productId))
		return self._retryDecision
	end

	local checked, alreadyProcessed, checkError = self._ledger:check(purchaseId)
	if not checked then
		self._log("warn", "Receipt ledger unavailable for product " .. tostring(productId) .. ": " .. tostring(checkError))
		return self._retryDecision
	elseif alreadyProcessed then
		self._localState[purchaseId] = "processed"
		return self._processedDecision
	end

	local player = self._getPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return self._retryDecision
	end

	local reward = self._resolveReward(entry.rewardHandler)
	if not reward then
		self._log("warn", "Reward handler is unavailable for product " .. tostring(productId))
		return self._retryDecision
	end

	self._localState[purchaseId] = "processing"
	local called, granted, rewardError = pcall(reward, player, entry.params, receiptInfo)
	if not called or granted ~= true then
		self._localState[purchaseId] = nil
		if not called then
			rewardError = granted
		end
		self._log("warn", "Reward failed for product " .. tostring(productId) .. ": " .. tostring(rewardError))
		return self._retryDecision
	end

	self._localState[purchaseId] = "granted"
	return self:_markGranted(purchaseId, productId)
end

return ReceiptRouter
