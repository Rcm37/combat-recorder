-- Run from combat-recorder: lua tests/log_window_test.lua
id = {}
dofile("../runescape-api-stubs/consts/Obj.lua")
id.Component = { TOPLEVEL_V2__GAME_AREA = 1 }
local saved, writes, logic, listeners = {}, 0, {}, {}
PersistentDB = {
    GetString = function(_, key) return saved[key] end,
    SetString = function(_, key, value) saved[key], writes = value, writes + 1 end,
}
package.loaded.recorder = {
    Subscribe = function(key, callback) listeners[key] = callback end,
    Unsubscribe = function(key) listeners[key] = nil end,
}
Event = { Logic = {
    Subscribe = function(key, callback) logic[key] = callback end,
    Unsubscribe = function(key) logic[key] = nil end,
} }
local parent = { interfaceID = 1, width = 1920, height = 1080 }
local available = true
ui = { Interfaces = {
    GetComponent = function() return parent end,
    GetInterface = function() return available and {} or nil end,
} }
local windows = {}
prettyui = { Window = { new = function(owner, options)
    local window = { parent = owner, interfaceID = owner.interfaceID,
        root = { x = options.x or 80, y = options.y or 80 }, options = options }
    function window:AddTextField(fieldOptions)
        local field = { text = fieldOptions.text }
        function field:SetText(value) self.text = value end
        return field
    end
    function window:Show() end
    function window:Close() self.options.onClose(self) end
    function window:Destroy() self.root, self.destroyed = nil, true end
    windows[#windows + 1] = window
    return window
end } }
local function reload()
    package.loaded.settings = nil
    package.loaded["interface/log_window"] = nil
    return require("interface/log_window")
end
local LogWindow = reload()
LogWindow.Show()
local first = windows[#windows]
assert(first.options.onPositionChange == nil, "persistence does not require PrettyUI's drag callback")
first.root.x, first.root.y = 450, 300
logic["combat-recorder-log-position"]()
assert(saved.combat_recorder_log_window_position == "450,300", "actual root position persists")
local previousWrites = writes
logic["combat-recorder-log-position"]()
assert(writes == previousWrites, "stationary window does not repeatedly write position")
first.root.x, first.root.y = 620, 410
LogWindow.Shutdown()
assert(saved.combat_recorder_log_window_position == "620,410", "shutdown captures movement before next logic tick")
assert(first.destroyed and next(logic) == nil and next(listeners) == nil, "shutdown cleans up window and subscriptions")

LogWindow = reload()
LogWindow.Show()
local second = windows[#windows]
assert(second.root.x == 620 and second.root.y == 410, "fresh modules restore position from persistent storage")
second.root.x, second.root.y = 650, 420
second:Close()
assert(saved.combat_recorder_log_window_position == "650,420", "closing saves actual coordinates")
LogWindow.Shutdown()

parent.width, parent.height = 800, 200
LogWindow = reload()
LogWindow.Show()
local third = windows[#windows]
assert(third.root.x == 120 and third.root.y == 80, "restored position fits a smaller game area")
available = false
LogWindow.Shutdown()
assert(saved.combat_recorder_log_window_position == "650,420", "unloaded interface cannot overwrite saved position")
assert(next(logic) == nil and next(listeners) == nil)
print("Floating log: position polling, close/shutdown saving, fresh reload, and bounds passed")
