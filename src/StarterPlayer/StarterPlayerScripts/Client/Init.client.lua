local Players = game:GetService("Players")

local PipStatusUI = require(script.Parent.PipStatusUI)
local InteractionUI = require(script.Parent.InteractionUI)
local EvolutionReveal = require(script.Parent.EvolutionReveal)
local Notifications = require(script.Parent.Notifications)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

PipStatusUI.Init(playerGui)
InteractionUI.Init(playerGui)
EvolutionReveal.Init(playerGui)
Notifications.Init(playerGui)
