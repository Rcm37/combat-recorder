local Recorder = require("recorder")
local ContentPane = require("interface/content")
local SettingsPane = require("interface/settings")

Recorder.Start()
ContentPane.Start()
SettingsPane.Start()

function PluginShutdown()
    SettingsPane.Shutdown()
    ContentPane.Shutdown()
    Recorder.Shutdown()
end
