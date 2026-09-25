local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent
local modules = root.Modules

local Config = require(root.Config)
local BuiltInRewards = require(modules.BuiltInRewards)
local ConfigValidator = require(modules.ConfigValidator)
local CustomRewards = require(modules.CustomRewards)
local GamePassService = require(modules.GamePassService)
local PurchaseService = require(modules.PurchaseService)
local ReceiptLedger = require(modules.ReceiptLedger)
local ReceiptRouter = require(modules.ReceiptRouter)

local function log(level, message)
	local text = "[BrickKit Monetization] " .. message
	if level == "warn" then
		warn(text)
	else
		print(text)
	end
end

local function resolveReward(name)
	return BuiltInRewards.resolve(name) or CustomRewards.resolve(name)
end

local function rewardExists(name)
	return BuiltInRewards.exists(name) or CustomRewards.exists(name)
end

local validEntries, configIssues = ConfigValidator.validate(Config, rewardExists)
for _, issue in ipairs(configIssues) do
	log("warn", "Config entry " .. tostring(issue.index) .. ": " .. issue.message)
end

if ReplicatedStorage:FindFirstChild("BrickKitMonetization") then
	error("[BrickKit Monetization] ReplicatedStorage/BrickKitMonetization already exists; nothing was overwritten")
end

local productsById = {}
local gamePassEntries = {}
for _, entry in ipairs(validEntries) do
	if entry.type == "DeveloperProduct" then
		productsById[entry.id] = entry
	else
		table.insert(gamePassEntries, entry)
	end
end

local ledger = ReceiptLedger.new(DataStoreService, "BrickKitMonetizationReceiptsV1")
local router = ReceiptRouter.new({
	ledger = ledger,
	productsById = productsById,
	resolveReward = resolveReward,
	getPlayerByUserId = function(userId)
		return Players:GetPlayerByUserId(userId)
	end,
	processedDecision = Enum.ReceiptDecision.Processed,
	retryDecision = Enum.ReceiptDecision.NotProcessedYet,
	log = log,
})

local activeEntries = {}
for _, entry in ipairs(validEntries) do
	if entry.type == "DeveloperProduct" then
		local bound, bindError = pcall(function()
			return MarketplaceService:BindReceiptHandler(
				Enum.ReceiptType.DeveloperProduct,
				function(receiptInfo)
					return router:process(receiptInfo)
				end,
				{ entry.id }
			)
		end)

		if bound then
			table.insert(activeEntries, entry)
		else
			log("warn", "Disabled Developer Product " .. tostring(entry.id) .. " because receipt binding failed: " .. tostring(bindError))
		end
	else
		table.insert(activeEntries, entry)
	end
end

local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "BrickKitMonetization"

local getCatalog = Instance.new("RemoteFunction")
getCatalog.Name = "GetCatalog"
getCatalog.Parent = remoteFolder

local requestPurchase = Instance.new("RemoteEvent")
requestPurchase.Name = "RequestPurchase"
requestPurchase.Parent = remoteFolder

remoteFolder.Parent = ReplicatedStorage

local purchaseService = PurchaseService.new(MarketplaceService, activeEntries)
local gamePassService = GamePassService.new(MarketplaceService, resolveReward, log)
local gamePassById = {}
for _, entry in ipairs(gamePassEntries) do
	gamePassById[entry.id] = entry
end

getCatalog.OnServerInvoke = function(player, ...)
	if select("#", ...) ~= 0 then
		return nil
	end

	local catalog = purchaseService:getCatalog(player)
	return catalog
end

requestPurchase.OnServerEvent:Connect(function(player, productType, id, ...)
	if select("#", ...) ~= 0 then
		return
	end

	local requested, reason = purchaseService:requestPurchase(player, productType, id)
	if not requested and reason ~= "rate_limited" then
		log("warn", "Rejected purchase request: " .. tostring(reason))
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId)
	local entry = gamePassById[gamePassId]
	if entry then
		gamePassService:apply(player, entry)
	end
end)

local characterConnections = {}

local function installTemplate(player, templateName, destinationName)
	local templates = root:FindFirstChild("Templates")
	local template = templates and templates:FindFirstChild(templateName)
	local destination = player:WaitForChild(destinationName, 10)
	if template and destination and not destination:FindFirstChild(templateName) then
		template:Clone().Parent = destination
	end
end

local function applyGamePassesForCharacter(player, character)
	task.defer(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and player.Parent then
			gamePassService:applyAll(player, gamePassEntries)
		end
	end)
end

local function onPlayerAdded(player)
	if characterConnections[player] then
		return
	end

	installTemplate(player, "MonetizationClient", "PlayerScripts")
	installTemplate(player, "BrickKitShop", "PlayerGui")

	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		applyGamePassesForCharacter(player, character)
	end)

	if player.Character then
		applyGamePassesForCharacter(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	purchaseService:forget(player)
	local connection = characterConnections[player]
	if connection then
		connection:Disconnect()
		characterConnections[player] = nil
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.defer(onPlayerAdded, player)
end

log("info", "Server core started with " .. tostring(#activeEntries) .. " active entries")
