local Settings = require("settings")
local Recorder = require("recorder")
local LogWindow = {}
local window, logField
local WINDOW_WIDTH, WINDOW_HEIGHT = 680, 120
local POSITION_EVENT_ID = "combat-recorder-log-position"

local function savePosition()
    if not window or not window.root or ui.Interfaces:GetInterface(window.interfaceID) == nil then return end
    local x, y = window.root.x, window.root.y
    if type(x) ~= "number" or type(y) ~= "number" or x < 0 or y < 0
        or x ~= x or y ~= y or x == math.huge or y == math.huge then return end
    local position = string.format("%.0f,%.0f", x, y)
    if position ~= Settings.get("log_window_position") then
        Settings.update("log_window_position", position)
    end
end

local function savedPosition(parent)
    local x, y = Settings.get("log_window_position"):match("^(%d+),(%d+)$")
    x, y = tonumber(x), tonumber(y)
    if not x or not y or x == math.huge or y == math.huge then return nil, nil end
    return math.min(x, math.max(0, parent.width - WINDOW_WIDTH)),
        math.min(y, math.max(0, parent.height - WINDOW_HEIGHT))
end

function LogWindow.Shutdown()
    Recorder.Unsubscribe("log-window")
    Event.Logic.Unsubscribe(POSITION_EVENT_ID)
    savePosition()
    if window then window:Destroy() end
    window, logField = nil, nil
end

local function refreshLog()
    if not window then return end
    if not window.root or ui.Interfaces:GetInterface(window.interfaceID) == nil then
        LogWindow.Shutdown()
        return
    end
    logField:SetText(Settings.get("combat_log"))
end

function LogWindow.Show()
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
    if not parent then return end
    if window and (window.parent ~= parent or not window.root
        or ui.Interfaces:GetInterface(window.interfaceID) == nil) then
        LogWindow.Shutdown()
    end
    if not window then
        local x, y = savedPosition(parent)
        window = prettyui.Window.new(parent, {
            title = "Combat Log",
            x = x, y = y,
            width = WINDOW_WIDTH, height = WINDOW_HEIGHT,
            minWidth = 320, minHeight = 100,
            resizable = true,
            respectInterfaceLock = false,
            onClose = savePosition,
        })
        logField = window:AddTextField({
            text = Settings.get("combat_log"),
            placeholder = "No actions recorded yet",
            maxLength = 9999,
        })
        Recorder.Subscribe("log-window", refreshLog)
        Event.Logic.Subscribe(POSITION_EVENT_ID, savePosition)
    end
    refreshLog()
    if window then window:Show() end
end

return LogWindow
