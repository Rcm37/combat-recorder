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
    settingsView.combat_log_text = settingsView:AddTextField({
        maxLength = 9999,
        text = Settings.get("combat_log"),
    })
    settingsView:AddText({
        text = "Not intended for user input. CTRL+A CTRL+C to select all and copy"
    })
    settingsView:AddSimpleButton("Clear Log", function()
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