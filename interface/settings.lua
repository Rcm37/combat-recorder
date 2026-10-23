local Settings = require("settings")
local Recorder = require("recorder")
local EOF = require("eof")
local Equipment = require("equipment")
local SettingsPane = {}
local EVENT_ID = "combat-recorder-settings-pane"
local view, combatLogField

local function refreshLog()
    if combatLogField then combatLogField:SetText(Settings.get("combat_log")) end
end

local function closeView()
    Recorder.Unsubscribe("settings-pane")
    if view then view:Destroy() end
    view, combatLogField = nil, nil
end

local function onLayerReady(event)
    closeView()
    local parent = event.component
    view = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })
    combatLogField = view:AddTextField({
        maxLength = 9999,
        text = Settings.get("combat_log"),
    })
    view:AddText({
        text = "Not intended for user input. CTRL+A CTRL+C to select all and copy"
    })
    view:AddSimpleButton("Clear Log", function() Recorder.ClearLog() end)
    view:AddTitle("Essence of Finality Weapons")
    view:AddText("Assign the stored weapon for each EOF colour and style. Regular and ornamented amulets have separate selections. Changes save immediately.")
    view:AddText("Use different colours or ornament styles for EOFs containing different weapons.")
    -- Explicit ordering selects PrettyUI's custom dropdown instead of the native
    -- ComboField, whose header can retain its initial label after a live swap.
    local variants, weapons = {}, { { id = 1, label = "Not configured", order = 1 } }
    local amulet = Equipment.GetEquipped(Equipment.NECK)
    local wornVariant = amulet and EOF.GetVariant(amulet.id)
    local selectedVariantID = 1
    for index, variant in ipairs(EOF.Variants) do
        variants[#variants + 1] = { id = index, label = variant.label, order = index }
        if variant == wornVariant then selectedVariantID = index end
    end
    for index, name in ipairs(EOF.Weapons) do
        weapons[#weapons + 1] = { id = index + 1, label = name, order = index + 1 }
    end
    local customID = #EOF.Weapons + 2
    weapons[#weapons + 1] = { id = customID, label = "Custom weapon (enter below)", order = customID }
    local selectedVariant = EOF.Variants[selectedVariantID]
    local variantCombo, weaponCombo, weaponField

    local function choiceFor(name)
        if name == "" then return 1 end
        for index, weapon in ipairs(EOF.Weapons) do
            if weapon == name then return index + 1 end
        end
        return customID
    end

    local function loadMapping()
        local name = EOF.GetWeapon(selectedVariant)
        weaponCombo:Select(choiceFor(name), false)
        weaponField:SetText(name)
    end

    view:AddText("EOF colour and style")
    variantCombo = view:AddComboBox({
        entries = variants, selectedID = selectedVariantID,
        onChange = function(_, selectedID)
            selectedVariant = EOF.Variants[selectedID]
            loadMapping()
        end,
    })
    view:AddText("Stored weapon")
    weaponCombo = view:AddComboBox({
        entries = weapons, selectedID = 1,
        onChange = function(_, selectedID)
            if selectedID == customID then return end
            local name = selectedID == 1 and "" or EOF.Weapons[selectedID - 1]
            EOF.SetWeapon(selectedVariant, name)
            loadMapping()
        end,
    })
    weaponField = view:AddTextField({
        text = "", placeholder = "Enter a weapon name if it is not listed",
        onChange = function(_, _, text)
            EOF.SetWeapon(selectedVariant, text)
            weaponCombo:Select(choiceFor(EOF.GetWeapon(selectedVariant)), false)
        end,
    })
    loadMapping()
    -- A component hook follows this pane's lifetime and keeps the selector live
    -- without reactivating the recorder's gameplay subscriptions while paused.
    local lastWornVariant = wornVariant
    view.root:Subscribe(ui.Hook.ONINVTRANSMIT, function()
        if parent.visibleGlobal == false then return true end
        local currentAmulet = Equipment.GetEquipped(Equipment.NECK)
        local currentVariant = currentAmulet and EOF.GetVariant(currentAmulet.id)
        if currentVariant == lastWornVariant then return true end
        lastWornVariant = currentVariant
        if currentVariant then
            for index, variant in ipairs(EOF.Variants) do
                if variant == currentVariant then
                    selectedVariant = variant
                    variantCombo:Select(index, false)
                    loadMapping()
                    break
                end
            end
        end
        return true
    end)
    Recorder.Subscribe("settings-pane", refreshLog)
end

function SettingsPane.Start()
    Event.SettingsLayerReady.Subscribe(EVENT_ID, onLayerReady)
end

function SettingsPane.Shutdown()
    Event.SettingsLayerReady.Unsubscribe(EVENT_ID)
    closeView()
end

return SettingsPane
