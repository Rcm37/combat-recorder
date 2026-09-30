local Settings = require("settings")
local settingsUI = require("interface/settings")
local contentUI = require("interface/content")
function PluginShutdown()
    Event.SettingsLayerReady.Unsubscribe("my-plugin-settings")
    if settingsUI then
        settingsUI = nil
    end
    Event.ContentLayerReady.Unsubscribe("my-plugin-content")
    if contentUI then
        contentUI = nil
    end
end

-- END UI STUFF

local AbilityMap = require("abilitymap")
local AbilityMapPvME = require("abilitymap_pvme")
local AmmoMap = require("ammomap")
local AmmoMapPvME = require("ammomap_pvme")

Event.VarTransmit.Subscribe("myEvent", function(varTransmitEvent)
    local varName = varTransmitEvent.var.configName
    local oldValue = varTransmitEvent.oldValue
    local newValue = varTransmitEvent.newValue

    local varChange = (oldValue or "nil") .. " -> " .. (newValue or "nil")
    local updatedLog = false

    local abilityName = nil
    local ammoName = nil
    if Settings.get("recording_active") and varName == "COMBATV2_JUST_USED_ABILITY" and newValue ~= nil then
        abilityName = ProcessAbility(newValue)
        updatedLog = true
    end

    if Settings.get("recording_active") and varName == "QUIVER_ACTIVE_AMMO" and newValue ~= nil and oldValue ~= nil and newValue ~= oldValue then
        -- NOTE: only works with pernix and tirannwn quivers
        ammoName = ProcessAmmo(newValue)
        updatedLog = true
    end

    if updatedLog then
        -- I know this logic for updating the last action is very brittle and will break as soon as a 3rd kind of thing is added
        -- I will refactor it when I'm not on as tight of a timeline
        if abilityName == nil then
            if contentUI then contentUI.updateLastAction(ammoName) end
        else
            if contentUI then contentUI.updateLastAction(abilityName) end
        end
        if settingsUI then settingsUI.updateCombatLog() end
        
    end
end)

function ProcessAbility(newValue)
    local abilityName = ""
    if Settings.get("pvme_syntax") then
        abilityName = AbilityMapPvME[newValue]
    else
        abilityName = AbilityMap[newValue]
    end
    if abilityName ~= nil then
        local combatLog = Settings.get("combat_log")
        if combatLog ~= "" then
            -- TODO need to add logic to determine if an ability is used off-GCD to change the -> to a +
            combatLog = combatLog .. " -> " .. abilityName
        else
            combatLog = abilityName
        end
        Settings.update("combat_log", combatLog)
        return abilityName
    end
end

function ProcessAmmo(newValue)
    local ammoName = ""
    if Settings.get("pvme_syntax") then
        ammoName = AmmoMapPvME[newValue]
    else
        ammoName = AmmoMap[newValue]
    end
    if ammoName ~= nil then
        local combatLog = Settings.get("combat_log")

        if combatLog ~= "" then
            combatLog = combatLog .. " + " .. ammoName
        else
            combatLog = ammoName
        end
        Settings.update("combat_log", combatLog)
    end
    return ammoName
end
