local Players = game:GetService("Players")

local PipStatusUI = require(script.Parent.PipStatusUI)
local InteractionUI = require(script.Parent.InteractionUI)
local EvolutionReveal = require(script.Parent.EvolutionReveal)
local Notifications = require(script.Parent.Notifications)
local ShopUI = require(script.Parent.ShopUI)
local MutationLabUI = require(script.Parent.MutationLabUI)
local CollectionUI = require(script.Parent.CollectionUI)
local InventoryUI = require(script.Parent.InventoryUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

PipStatusUI.Init(playerGui)
InteractionUI.Init(playerGui)
EvolutionReveal.Init(playerGui)
Notifications.Init(playerGui)
ShopUI.Init(playerGui)
MutationLabUI.Init(playerGui)
CollectionUI.Init(playerGui)
InventoryUI.Init(playerGui)
