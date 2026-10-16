local Equipment = {}
local EVENT_ID = "combat-recorder-equipment"
local WORN_ID = 94 -- id.Inv.WORN
-- GetSlot uses one-based indexes, unlike the game's zero-based worn slots.
Equipment.MAIN_HAND = 4
Equipment.NECK = 3
local slotNames = {
    [1] = "Head", [2] = "Cape", [3] = "Neck", [4] = "Main hand", [5] = "Body",
    [6] = "Off hand", [8] = "Legs", [10] = "Hands", [11] = "Feet", [13] = "Ring",
    [14] = "Ammo", [15] = "Aura", [18] = "Pocket",
}
local snapshot, onChanged

local function field(object, key)
    local ok, value = pcall(function() return object[key] end)
    if ok then return value end
end

local function readEquipment()
    -- Inventory.Find returns a single, non-iterable proxy.
    local inventory = Inventory.Find(WORN_ID)
    if not inventory or field(inventory, "valid") == false
        or field(inventory, "isValid") == false then return nil end
    local slotCount = field(inventory, "slotCount")
    if type(slotCount) ~= "number" then return nil end

    local result = { slotCount = slotCount }
    for index = 1, slotCount do
        local slot = inventory:GetSlot(index)
        if slot and slot.obj and slot.obj.id >= 0 and slot.count > 0 then
            -- Copy values; do not retain inventory or item userdata across events.
            result[index] = { id = slot.obj.id, name = slot.obj.name }
        end
    end
    return result
end

function Equipment.GetEquipped(index)
    -- Read at ability time instead of relying on inventory/variable event order.
    local current = readEquipment()
    return current and current[index]
end

local function isWorn(event)
    return event and event.inv and event.inv.id == WORN_ID
end

local function onInventoryAdded(event)
    if isWorn(event) then snapshot = readEquipment() end
end

local function onInventoryRemoved(event)
    if isWorn(event) then snapshot = nil end
end

local function onInventoryUpdated(event)
    if not isWorn(event) then return end
    local current = readEquipment()
    if not current then snapshot = nil; return end
    if not snapshot then snapshot = current; return end

    local changes = {}
    for index = 1, math.max(current.slotCount, snapshot.slotCount) do
        local previous, item = snapshot[index], current[index]
        local previousID, itemID = previous and previous.id, item and item.id
        if previousID ~= itemID then
            changes[#changes + 1] = {
                slot = index, slotName = slotNames[index] or ("Slot " .. index),
                previous = previous, item = item,
            }
        end
    end
    snapshot = current
    if #changes > 0 and onChanged then onChanged(changes) end
end

function Equipment.Start(callback)
    onChanged = callback
    snapshot = readEquipment() -- Establish a baseline without logging current gear.
    Event.InventoryAdded.Subscribe(EVENT_ID, onInventoryAdded)
    Event.InventoryUpdated.Subscribe(EVENT_ID, onInventoryUpdated)
    Event.InventoryRemoved.Subscribe(EVENT_ID, onInventoryRemoved)
end

function Equipment.Shutdown()
    Event.InventoryAdded.Unsubscribe(EVENT_ID)
    Event.InventoryUpdated.Unsubscribe(EVENT_ID)
    Event.InventoryRemoved.Unsubscribe(EVENT_ID)
    snapshot, onChanged = nil, nil
end

return Equipment
