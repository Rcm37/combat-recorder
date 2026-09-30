local settingsUI = {}
local Settings = require("settings")
local UIUtils = require("interface/ui_utils")

local settingsView

Event.SettingsLayerReady.Subscribe("my-plugin-settings", function(event)

    local parent = event.component
    settingsView = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })
    settingsView:AddCheckboxButton({
        { text = "Enable Recording", value = "recording_active", selected = Settings.get("recording_active") },
    }, {
        onChange = function(_, _, changedValue, selected)
            UIUtils.updateSettings(changedValue, selected)
        end,
    })
    settingsView:AddCheckboxButton({
        { text = "Use PvME Rotation Builder Syntax", value = "pvme_syntax", selected = Settings.get("pvme_syntax") },
    }, {
        onChange = function(_, _, changedValue, selected)
            UIUtils.updateSettings(changedValue, selected)
        end,
    })
    local ability_log_collapse = settingsView:AddCollapseButton("Combat Log", {
        expanded = Settings.get("expanded"),
        onToggle = function(_, expanded)
            UIUtils.updateSettings("expanded", expanded)
        end,
    })
    settingsView.combat_log_text = ability_log_collapse:AddTextField({
        text = Settings.get("combat_log"),
    })
    ability_log_collapse:AddText({
        text = "Not intended for user input. CTRL+A CTRL+C to select all and copy"
    })
    ability_log_collapse:AddSimpleButton("Clear Log", function()
        settingsUI.clearLog()
    end)
end)

function settingsUI.clearLog()
    Settings.update("combat_log", "")
    settingsUI.updateCombatLog()
end

function settingsUI.updateCombatLog()
    if settingsView == nil or settingsView.combat_log_text == nil then
        return
    end
    settingsView.combat_log_text:SetText(Settings.get("combat_log"))
end
return settingsUI