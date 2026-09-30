local uiutils = {}
local Settings = require("Settings")
function uiutils.updateSettings(settingsKey, value)
    Settings.update(settingsKey, value)
end
return uiutils