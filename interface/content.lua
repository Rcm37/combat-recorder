local Settings = require("settings")
local Recorder = require("recorder")
local ContentPane = {}
local EVENT_ID = "combat-recorder-content-pane"
local view, lastActionText

local function refreshLastAction()
    if lastActionText then
        lastActionText.content = Recorder.GetLastAction() or "Waiting..."
    end
end

local function closeView()
    Recorder.Unsubscribe("content-pane")
    if view then view:Destroy() end
    view, lastActionText = nil, nil
end

local function onLayerReady(event)
    closeView()
    local parent = event.component
    view = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })
    view:AddCheckboxButton({
        { text = "Enable Recording", value = "recording_active", selected = Settings.get("recording_active") },
    }, {
        onChange = function(_, _, changedValue, selected)
            Settings.update(changedValue, selected)
        end,
    })
    view:AddCheckboxButton({
        { text = "Use PvME Rotation Builder Syntax", value = "pvme_syntax", selected = Settings.get("pvme_syntax") },
    }, {
        onChange = function(_, _, changedValue, selected)
            Settings.update(changedValue, selected)
        end,
    })
    view:AddText("Last action:")
    lastActionText = view:AddText(Recorder.GetLastAction() or "Waiting...")
    view:AddDivider()
    view:AddText("Manage Combat Recorder settings via Plugin Hub to view full combat log!")
    Recorder.Subscribe("content-pane", refreshLastAction)
end

function ContentPane.Start()
    Event.ContentLayerReady.Subscribe(EVENT_ID, onLayerReady)
end

function ContentPane.Shutdown()
    Event.ContentLayerReady.Unsubscribe(EVENT_ID)
    closeView()
end

return ContentPane
