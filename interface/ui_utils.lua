local uiutils = {}
local Settings = require("settings")
function uiutils.updateSettings(settingsKey, value)
    Settings.update(settingsKey, value)
end
return uiutils