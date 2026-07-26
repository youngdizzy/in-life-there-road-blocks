-- The only place that talks to MarketplaceService. Gamepass ownership
-- checks, purchase prompts, and developer product receipts all flow
-- through here so there is exactly one place that ever writes
-- profile.OwnedGamepasses or grants a developer product's contents --
-- never a LocalScript, never scattered across other services.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local DataManager = require(script.Parent.DataManager)
local BoostService = require(script.Parent.BoostService)
local CosmeticService = require(script.Parent.CosmeticService)
local HabitatThemeService = require(script.Parent.HabitatThemeService)
local StateService = require(script.Parent.StateService)

local MonetizationService = {}

local function notify(player, message, kind)
	Remotes.get("Notify"):FireClient(player, { Text = message, Kind = kind or "info" })
end

-- Side effects for the moment a gamepass is *newly* confirmed owned
-- (PromptGamePassPurchaseFinished only -- NOT the join-time ownership
-- check, which must never force a player's chosen habitat theme back to
-- VIP if they'd deliberately switched to Default). VIPHabitat auto-selects
-- the VIP theme once, on purchase, as a nice immediate payoff; the player
-- can switch back via HabitatThemeService any time after.
local function applyGamepassPurchaseEffects(player, profile, key)
	if key == "VIPHabitat" then
		HabitatThemeService.SelectTheme(player, profile, "vip")
	end
end

-- Called once per join, after the profile is loaded and before the habitat
-- is handed out. Only ever sets OwnedGamepasses[key] = true -- a transient
-- API failure must never look like a revoked purchase.
function MonetizationService.CheckOwnedGamepasses(player, profile)
	for key, cfg in pairs(MonetizationConfig.Gamepasses) do
		if type(cfg.Id) == "number" and cfg.Id > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, cfg.Id)
			end)
			if ok and owns then
				profile.OwnedGamepasses[key] = true
			elseif not ok then
				warn(("MonetizationService: gamepass ownership check failed for %s (%s): %s"):format(
					player.Name,
					key,
					tostring(owns)
				))
			end
		end
	end
end

local function grantDevProduct(player, profile, key)
	local product = MonetizationConfig.DevProducts[key]

	if product.Gems then
		profile.Gems += product.Gems
	end

	if product.BoostType then
		BoostService.Grant(profile, product.BoostType, product.DurationSeconds)
	end

	if product.CosmeticId then
		CosmeticService.Unlock(profile, product.CosmeticId)
	end

	StateService.Push(player, profile)
	notify(player, ("Purchased %s!"):format(product.Name), "success")
end

function MonetizationService.Init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end
		local profile = DataManager.GetProfile(player)
		if not profile then
			return
		end
		for key, cfg in pairs(MonetizationConfig.Gamepasses) do
			if cfg.Id == gamePassId then
				profile.OwnedGamepasses[key] = true
				applyGamepassPurchaseEffects(player, profile, key)
				StateService.Push(player, profile)
				notify(player, ("Thanks for buying %s!"):format(cfg.Name), "success")
				break
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local profile = DataManager.GetProfile(player)
		if not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if DataManager.HasProcessedReceipt(profile, receiptInfo.PurchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local key = MonetizationConfig.DevProductById[receiptInfo.ProductId]
		if not key then
			warn("MonetizationService: unknown developer product id", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local ok, err = pcall(grantDevProduct, player, profile, key)
		if not ok then
			warn(("MonetizationService: failed to grant %s to %s: %s"):format(key, player.Name, tostring(err)))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		DataManager.MarkReceiptProcessed(profile, receiptInfo.PurchaseId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	Remotes.get("PromptGamepass").OnServerEvent:Connect(function(player, gamepassKey)
		local cfg = MonetizationConfig.Gamepasses[gamepassKey]
		if type(cfg) ~= "table" or type(cfg.Id) ~= "number" or cfg.Id <= 0 then
			notify(player, "That gamepass isn't set up yet.", "warning")
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, cfg.Id)
	end)

	Remotes.get("PromptDevProduct").OnServerEvent:Connect(function(player, productKey)
		local cfg = MonetizationConfig.DevProducts[productKey]
		if type(cfg) ~= "table" or type(cfg.Id) ~= "number" or cfg.Id <= 0 then
			notify(player, "That product isn't set up yet.", "warning")
			return
		end
		MarketplaceService:PromptProductPurchase(player, cfg.Id)
	end)
end

return MonetizationService
