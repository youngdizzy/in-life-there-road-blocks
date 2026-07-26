-- A minimal, server-authoritative item inventory: quantities keyed by item
-- id, stored in profile.Inventory. This is intentionally generic (it
-- doesn't know what a "mutation item" is) so any future item type can
-- reuse it without a second inventory system being built.

local InventoryService = {}

function InventoryService.GetQuantity(profile, itemId)
	return profile.Inventory[itemId] or 0
end

function InventoryService.HasItem(profile, itemId, quantity)
	return InventoryService.GetQuantity(profile, itemId) >= (quantity or 1)
end

function InventoryService.AddItem(profile, itemId, quantity)
	quantity = quantity or 1
	profile.Inventory[itemId] = InventoryService.GetQuantity(profile, itemId) + quantity
end

-- Returns false if the profile doesn't have enough of the item -- callers
-- must check this instead of assuming success.
function InventoryService.RemoveItem(profile, itemId, quantity)
	quantity = quantity or 1
	if not InventoryService.HasItem(profile, itemId, quantity) then
		return false
	end

	local remaining = InventoryService.GetQuantity(profile, itemId) - quantity
	if remaining <= 0 then
		profile.Inventory[itemId] = nil
	else
		profile.Inventory[itemId] = remaining
	end
	return true
end

return InventoryService
