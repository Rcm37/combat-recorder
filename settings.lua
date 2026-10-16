local Settings = {}
local listeners = {}

function Settings.Subscribe(key, callback)
    listeners[key] = callback
end

function Settings.Unsubscribe(key)
    listeners[key] = nil
end

local PLUGIN_DB_PREFIX = "combat_recorder_"

local CachedSettings = {}

-- Settings and their default values/types
local ValidSettings = {
    recording_active = {
        default = true,
        type = "boolean"
    },
    pvme_syntax = {
        default = false,
        type = "boolean"
    },
    expanded = {
        default = true,
        type = "boolean"
    },
    combat_log = {
        default = "",
        type = "string"
    }
}

for _, variant in ipairs(require("eof_variants")) do
    ValidSettings["eof_weapon_" .. variant.key] = { default = "", type = "string" }
end

local function assertValidSetting(settingName)
    if ValidSettings[settingName] == nil then
        error("Unknown setting: " .. tostring(settingName))
    end
end

local function makeKey(settingName)
    return PLUGIN_DB_PREFIX .. settingName
end

function Settings.update(settingName, value)
    assertValidSetting(settingName)

    local setting = ValidSettings[settingName]

    if type(value) ~= setting.type then
        error("Setting " .. settingName .. " expects " .. setting.type .. ", got " .. type(value))
    end

    if setting.type == "boolean" then
        PersistentDB:SetBool(makeKey(settingName), value)
    elseif setting.type == "string" then
        PersistentDB:SetString(makeKey(settingName), value)
    end

    CachedSettings[settingName] = value
    for _, callback in pairs(listeners) do callback(settingName, value) end
end

function Settings.get(settingName)
    assertValidSetting(settingName)
    if CachedSettings[settingName] ~= nil then
        return CachedSettings[settingName]
    end

    local setting = ValidSettings[settingName]
    local value

    if setting.type == "boolean" then
        value = PersistentDB:GetBool(makeKey(settingName))
    elseif setting.type == "string" then
        value = PersistentDB:GetString(makeKey(settingName))
    end

    if value == nil then
        value = setting.default
        if setting.type == "boolean" then
            PersistentDB:SetBool(makeKey(settingName), value)
        elseif setting.type == "string" then
            PersistentDB:SetString(makeKey(settingName), value)
        end
    end
    CachedSettings[settingName] = value

    return value
end

return Settings
