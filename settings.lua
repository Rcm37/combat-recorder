local Settings = {}

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

    CachedSettings[settingName] = value

    if setting.type == "boolean" then
        PersistentDB:SetBool(makeKey(settingName), value)
    elseif setting.type == "string" then
        PersistentDB:SetString(makeKey(settingName), value)
    end
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
        if setting.type == "boolean" then
            PersistentDB:SetBool(makeKey(settingName), setting.default)
        elseif setting.type == "string" then
            PersistentDB:SetString(makeKey(settingName), setting.default)
        end

        return setting.default
    end
    CachedSettings[settingName] = value

    return value
end

return Settings