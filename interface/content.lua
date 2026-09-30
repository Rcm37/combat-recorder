local contentUI = {}
local Settings = require("settings")
local UIUtils = require("interface/ui_utils")

local contentView = nil

Event.ContentLayerReady.Subscribe("my-plugin-content", function(event)

    local parent = event.component
    contentView = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })
    contentView:AddCheckboxButton({
        { text = "Enable Recording", value = "recording_active", selected = Settings.get("recording_active") },
    }, {
        onChange = function(_, _, changedValue, selected)
            UIUtils.updateSettings(changedValue, selected)
        end,
    })
    contentView:AddCheckboxButton({
        { text = "Use PvME Rotation Builder Syntax", value = "pvme_syntax", selected = Settings.get("pvme_syntax") },
    }, {
        onChange = function(_, _, changedValue, selected)
            UIUtils.updateSettings(changedValue, selected)
        end,
    })
    local ability_log_collapse = contentView:AddCollapseButton("Combat Log", {
        expanded = Settings.get("expanded"),
        onToggle = function(_, expanded)
            UIUtils.updateSettings("expanded", expanded)
        end,
    })
    contentView.combat_log_text = ability_log_collapse:AddTextField({
        text = Settings.get("combat_log"),
    })
    ability_log_collapse:AddText({
        text = "Not intended for user input. CTRL+A CTRL+C to select all and copy"
    })
    ability_log_collapse:AddSimpleButton("Clear Log", function()
        contentUI.clearLog()
    end)
end)

function contentUI.clearLog()
    Settings.update("combat_log", "")
    contentUI.updateCombatLog()
end

function contentUI.updateCombatLog()
    if contentView == nil or contentView.combat_log_text == nil then
        return
    end
    contentView.combat_log_text:SetText(Settings.get("combat_log"))
end
return contentUI