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
    contentView:AddText("Last action:")
    contentView.last_action = contentView:AddText("Waiting...")
    contentView:AddDivider()
    contentView:AddText("Manage Combat Recorder settings via Plugin Hub to view full combat log!")
end)

function contentUI.clearLog()
    Settings.update("combat_log", "")
    contentUI.updateCombatLog()
end

function contentUI.updateLastAction(text)
    if contentView == nil or contentView.last_action == nil then
        return
    end
    contentView.last_action.content = text
end
return contentUI