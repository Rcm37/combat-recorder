local Settings = require("settings")
local Equipment = require("equipment")
local EOF = require("eof")
local ItemNames = require("item_names")
local AbilityStruct = require("ability_struct")
local Recorder = {}
local EVENT_ID = "combat-recorder-var-transmit"
local lastAction
local listeners = {}

-- Each action describes how to recognize, name, and append a variable change.
-- Add new action types here; logging and UI notifications are shared below.
local ActionTypes = {
    COMBATV2_JUST_USED_ABILITY = {
        getName = AbilityStruct.GetName,
        pvmeMap = require("abilitymap_pvme"),
        separator = " -> ",
    },
    QUIVER_ACTIVE_AMMO = {
        map = require("ammomap"),
        pvmeMap = require("ammomap_pvme"),
        separator = " + ",
        -- Pernix and Tirannwn quiver changes.
        accepts = function(event)
            return event.oldValue ~= nil and event.newValue ~= event.oldValue
        end,
    },
}

local function notify()
    for _, callback in pairs(listeners) do callback() end
end

local function appendAction(name, separator)
    local log = Settings.get("combat_log")
    Settings.update("combat_log", log == "" and name or (log .. separator .. name))
    lastAction = name
    notify()
end

local function onEquipmentChanged(changes)
    local actions = {}
    local pvme = Settings.get("pvme_syntax")
    for _, change in ipairs(changes) do
        if pvme then
            local item = change.item or change.previous
            actions[#actions + 1] = (change.item and "" or "unequip ") .. ItemNames.Equipment(item)
        elseif change.item then
            actions[#actions + 1] = "equip " .. change.item.name .. " [" .. change.slotName .. "]"
        else
            actions[#actions + 1] = "unequip " .. change.previous.name .. " [" .. change.slotName .. "]"
        end
    end
    appendAction(table.concat(actions, " + "), " + ")
end

function Recorder.Subscribe(key, callback)
    listeners[key] = callback
end

function Recorder.Unsubscribe(key)
    listeners[key] = nil
end

function Recorder.GetLastAction()
    return lastAction
end

function Recorder.ClearLog()
    Settings.update("combat_log", "")
    notify()
end

local function onVarTransmit(event)
    if event == nil or event.var == nil or event.newValue == nil
        or not Settings.get("recording_active") then
        return
    end

    local action = ActionTypes[event.var.configName]
    if not action or (action.accepts and not action.accepts(event)) then return end

    local pvme = Settings.get("pvme_syntax")
    local name
    if action.getName then
        if pvme then name = action.pvmeMap[event.newValue] end
        if name == nil then
            name = action.getName(event.newValue)
            if pvme and name then name = name:lower():gsub("[%s%p]", "") end
        end
    else
        name = pvme and action.pvmeMap[event.newValue] or nil
        if name == nil then name = action.map[event.newValue] end
    end
    if name == nil then return end

    if event.var.configName == "COMBATV2_JUST_USED_ABILITY" then
        if event.newValue == id.Struct.COMBATV2_ABILITY_CONSTITUTION_SPECIAL_ATTACK then
            local weapon = Equipment.GetEquipped(Equipment.MAIN_HAND)
            name = weapon and ItemNames.Special(name, weapon.name, pvme) or (name .. " (unknown weapon)")
        elseif event.newValue == id.Struct.COMBATV2_ABILITY_CONSTITUTION_ALCHEMICAL_HYDRIX_AMULET then
            local amulet = Equipment.GetEquipped(Equipment.NECK)
            local variant = amulet and EOF.GetVariant(amulet.id)
            local storedWeapon = variant and EOF.GetWeapon(variant)
            if storedWeapon and storedWeapon ~= "" then
                name = ItemNames.Special(name, storedWeapon, pvme)
            else
                name = name .. " (" .. EOF.Describe(amulet and amulet.id) .. ")"
            end
        end
    end
    appendAction(name, action.separator)
end

local active = false

-- Keep the last recorded action when disabled.
local function setEnabled(enabled)
    if active == enabled then return end
    if enabled then
        Equipment.Start(onEquipmentChanged)
        Event.VarTransmit.Subscribe(EVENT_ID, onVarTransmit)
    else
        Event.VarTransmit.Unsubscribe(EVENT_ID)
        Equipment.Shutdown()
    end
    active = enabled
end

local function onSettingChanged(name, value)
    if name == "recording_active" then setEnabled(value) end
end

function Recorder.Start()
    Settings.Subscribe(EVENT_ID, onSettingChanged)
    setEnabled(Settings.get("recording_active"))
end

function Recorder.Shutdown()
    Settings.Unsubscribe(EVENT_ID)
    setEnabled(false)
    listeners = {}
    lastAction = nil
end

return Recorder
