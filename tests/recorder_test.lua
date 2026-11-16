id = id or {}
dofile("../runescape-api-stubs/consts/Obj.lua")
dofile("../runescape-api-stubs/consts/Struct.lua")
-- Run from combat-recorder: lua tests/recorder_test.lua
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local subscriptions = {}
local views = {}
ui = { Hook = { ONINVTRANSMIT = "ONINVTRANSMIT" } }
id.Component = { TOPLEVEL_V2__GAME_AREA = {} }
local gameArea = { interfaceID = 1, width = 1920, height = 1080 }
ui.Interfaces = {
    GetComponent = function(_, componentID)
        assert(componentID == id.Component.TOPLEVEL_V2__GAME_AREA)
        return gameArea
    end,
    GetInterface = function(_, interfaceID) return interfaceID == 1 and {} or nil end,
}
local subscribeCalls = {}
local function event(name)
    subscriptions[name] = {}
    return {
        Subscribe = function(key, callback)
            subscribeCalls[name] = (subscribeCalls[name] or 0) + 1
            subscriptions[name][key] = callback
        end,
        Unsubscribe = function(key) subscriptions[name][key] = nil end,
    }
end
Event = { VarTransmit = event("VarTransmit"), ContentLayerReady = event("ContentLayerReady"),
    SettingsLayerReady = event("SettingsLayerReady"), InventoryAdded = event("InventoryAdded"),
    InventoryUpdated = event("InventoryUpdated"), InventoryRemoved = event("InventoryRemoved"), Logic = event("Logic") }
local function emit(name, payload)
    for _, callback in pairs(subscriptions[name]) do callback(payload) end
    if name == "InventoryUpdated" or name == "InventoryAdded" or name == "InventoryRemoved" then
        for _, view in ipairs(views) do
            local callback = view.root.hooks.ONINVTRANSMIT
            if callback then callback() end
        end
    end
end
local saved, reads, writes, failWrites = {}, 0, 0, false
local function read(_, key) reads = reads + 1; return saved[key] end
local function write(_, key, value)
    if failWrites then error("simulated database failure") end
    writes = writes + 1
    saved[key] = value
end
PersistentDB = { GetBool = read, GetString = read, SetBool = write, SetString = write }
local wornSlots, wornAvailable = {}, true
local wornFields = {
    isValid = true, slotCount = 18,
    GetSlot = function(_, index) return wornSlots[index] end,
}
-- Non-iterable inventory proxy with an isValid property.
local worn = setmetatable({}, {
    __index = wornFields,
    __pairs = function() error("cannot call pairs on inventory proxy") end,
})
if newproxy then
    worn = newproxy(true)
    getmetatable(worn).__index = wornFields
end
Inventory = { Find = function(id)
    assert(id == 94, "must look up worn inventory")
    return wornAvailable and worn or nil
end }
prettyui = { SimpleView = { new = function(_, options)
    local view = { text = {}, fields = {}, buttons = {}, toggles = {}, combos = {}, options = options }
    view.root = { hooks = {} }
    function view.root:Subscribe(hook, callback) self.hooks[hook] = callback end
    function view:AddTitle() end
    function view:AddDivider() end
    function view:AddCheckboxButton(items, options)
        self.toggles[items[1].value] = options.onChange
    end
    function view:AddText(options)
        local text = { content = type(options) == "table" and options.text or options }
        self.text[#self.text + 1] = text
        return text
    end
    function view:AddTextField(options)
        local field = { text = options.text, updates = 0, onChange = options.onChange }
        function field:SetText(text)
            assert(not view.destroyed, "updated a destroyed view")
            self.text = text
            self.updates = self.updates + 1
        end
        self.fields[#self.fields + 1] = field
        return field
    end
    function view:AddComboBox(options)
        local combo = { entries = options.entries, selected = options.selectedID, onChange = options.onChange }
        local customDropdown = options.entries[1].order ~= nil
        local function labelFor(id)
            for _, entry in ipairs(combo.entries) do
                if entry.id == id then return entry.label end
            end
        end
        combo.selectedLabel = labelFor(combo.selected)
        function combo:Select(id, trigger)
            self.selected = id
            if customDropdown then self.selectedLabel = labelFor(id) end
            -- Native dropdowns can keep stale headers after a silent selection.
            if trigger then
                self.selectedLabel = labelFor(id)
                self.onChange(self, id)
            end
        end
        self.combos[#self.combos + 1] = combo
        return combo
    end
    function view:AddSimpleButton(label, callback) self.buttons[label] = callback end
    function view:Destroy()
        self.destroyed = true
        self.root.hooks = {}
    end
    views[#views + 1] = view
    return view
end } }
local floatingWindows = {}
prettyui.Window = { new = function(parent, options)
    local window = prettyui.SimpleView.new()
    table.remove(views)
    window.parent, window.interfaceID, window.options = parent, parent.interfaceID, options
    window.root.x, window.root.y = options.x or 80, options.y or 80
    function window:Show() self.root.hidden = false end
    function window:Close()
        if self.options.onClose then self.options.onClose(self) end
        self.root.hidden = true
    end
    floatingWindows[#floatingWindows + 1] = window
    return window
end }

local Settings = require("settings")
local Recorder = require("recorder")
local ContentPane = require("interface/content")
local SettingsPane = require("interface/settings")
for name, callbacks in pairs(subscriptions) do
    expect(next(callbacks), nil, "requiring modules does not subscribe to " .. name)
end
expect(Settings.get("recording_active"), true, "default recording")
local previousReads, previousWrites = reads, writes
expect(Settings.get("recording_active"), true, "repeat default read")
expect(reads, previousReads, "default cached")
expect(writes, previousWrites, "default only written once")
Settings.update("combat_log", "Saved log")
Settings.update("pvme_syntax", false)
local reloaded = dofile("settings.lua")
expect(reloaded.get("combat_log"), "Saved log", "read saved string")
expect(reloaded.get("pvme_syntax"), false, "read saved false")
previousReads = reads
reloaded.get("combat_log")
reloaded.get("pvme_syntax")
expect(reads, previousReads, "loaded settings cached")
previousWrites = writes
expect(pcall(Settings.update, "recording_active", "false"), false, "reject wrong boolean type")
expect(pcall(Settings.update, "combat_log", false), false, "reject wrong string type")
expect(pcall(Settings.update, "combat_log", nil), false, "reject nil")
expect(pcall(Settings.update, "unknown", true), false, "reject unknown setting")
expect(writes, previousWrites, "invalid values never written")
failWrites = true
expect(pcall(Settings.update, "recording_active", false), false, "boolean write fails")
expect(pcall(Settings.update, "combat_log", "Bad log"), false, "string write fails")
expect(Settings.get("recording_active"), true, "failed boolean write preserves cache")
expect(Settings.get("combat_log"), "Saved log", "failed string write preserves cache")
failWrites = false
Settings.update("combat_log", "")

Settings.update("recording_active", false)
dofile("main.lua")
expect(next(subscriptions.VarTransmit), nil, "saved disabled state skips recording subscription")
expect(next(subscriptions.InventoryUpdated), nil, "saved disabled state skips equipment subscription")
expect(next(subscriptions.ContentLayerReady) ~= nil, true, "disabled startup retains content UI")
expect(next(subscriptions.SettingsLayerReady) ~= nil, true, "disabled startup retains settings UI")
Settings.update("recording_active", true)
local function transmit(name, newValue, oldValue)
    emit("VarTransmit", { var = { configName = name }, newValue = newValue, oldValue = oldValue })
end
local function ability(id) transmit("COMBATV2_JUST_USED_ABILITY", id) end
local function ammo(id, old) transmit("QUIVER_ACTIVE_AMMO", id, old) end
local abilityNameParam = {}
local abilityNames = {
    [19255] = "balanced<nbsp>strike", [14682] = "backhand",
    [28430] = "weapon special attack", [11748] = "essence of finality",
    [999998] = "New<nbsp>Ability!", [999997] = "   ",
}
config = { Param = { COMBATV2_ABILITY_NAME = abilityNameParam }, Struct = {} }
config.Struct.FromID = function(id)
    if id == 999996 then error("unavailable struct") end
    if abilityNames[id] == nil then return nil end
    return { GetParamValue = function(_, param)
        expect(param, abilityNameParam, "names use the documented ability name param")
        return abilityNames[id]
    end }
end
ability(999998)
expect(Settings.get("combat_log"), "New Ability!", "normal output uses struct name for unmapped ability")
Settings.update("pvme_syntax", true)
ability(999998)
expect(Settings.get("combat_log"), "New Ability! -> [New Ability!]", "unmapped PvME ability is literal text")
ability(19255)
expect(Recorder.GetLastAction(), "balancedstrike", "existing PvME translation takes priority over struct name")
Settings.update("pvme_syntax", false)
local nameTestLog = Settings.get("combat_log")
ability(999997)
ability(999996)
expect(Settings.get("combat_log"), nameTestLog, "blank and failed names are skipped")
Recorder.ClearLog()
ability(19255)
expect(Settings.get("combat_log"), "balanced strike", "first ability has no separator")
expect(Recorder.GetLastAction(), "balanced strike", "record before panes open")
local parent = { component = { width = 400, height = 600 } }
emit("ContentLayerReady", parent)
local content = views[#views]
expect(content.text[2].content, "balanced strike", "pane shows last action recorded before opening")
emit("SettingsLayerReady", parent)
local settingsPane = views[#views]
expect(parent.component.height, 600, "settings does not enlarge Plugin Hub's host")
expect(settingsPane.options.height, 600, "settings viewport uses the visible host height")
expect(settingsPane.fields[1].text, "balanced strike", "pane shows saved log")
expect(settingsPane.combos[1].selected, 1, "no equipped EOF uses default variant")
content.buttons["Open Combat Log"]()
local floatingLog = floatingWindows[#floatingWindows]
expect(floatingLog.parent, gameArea, "floating log belongs to game area instead of ribbon pane")
expect(floatingLog.fields[1].text, "balanced strike", "floating log opens with saved recording")
content.buttons["Open Combat Log"]()
expect(#floatingWindows, 1, "repeated clicks reuse floating log window")
floatingLog.root.x, floatingLog.root.y = 230, 160
emit("Logic")
expect(dofile("settings.lua").get("log_window_position"), "230,160", "dragged position persists across settings reload")
ability(14682)
expect(Settings.get("combat_log"), "balanced strike -> backhand", "ability separator")
expect(content.text[2].content, "backhand", "last action refreshed")
expect(settingsPane.fields[1].text, "balanced strike -> backhand", "log field refreshed")
expect(floatingLog.fields[1].text, "balanced strike -> backhand", "floating log refreshes live")
ammo(41629, 41627)
expect(Settings.get("combat_log"), "balanced strike -> backhand + ruby bakriminel bolts (e)", "ammo separator and map")
expect(content.text[2].content, "ruby bakriminel bolts (e)", "ammo last action")

local previousLog, previousUpdates = Settings.get("combat_log"), settingsPane.fields[1].updates
ability(-999)
ammo(-999, 41629)
ammo(41629, 41629)
ammo(41627, nil)
transmit("IRRELEVANT", 19255)
ability(nil)
ammo(nil, 41629)
emit("VarTransmit", nil)
emit("VarTransmit", {})
expect(Settings.get("combat_log"), previousLog, "unknown or ineligible events do not append")
expect(content.text[2].content, "ruby bakriminel bolts (e)", "unknown IDs do not clear last action")
expect(settingsPane.fields[1].updates, previousUpdates, "ignored events do not refresh UI")
expect(ProcessAbility, nil, "ability processing is not global")
expect(ProcessAmmo, nil, "ammo processing is not global")
expect(RelevantVarNames, nil, "variable definitions are not global")

content.toggles.recording_active(nil, nil, "recording_active", false)
expect(next(subscriptions.VarTransmit), nil, "disable removes recording subscription")
expect(next(subscriptions.InventoryAdded), nil, "disable removes inventory added subscription")
expect(next(subscriptions.InventoryUpdated), nil, "disable removes inventory updated subscription")
expect(next(subscriptions.InventoryRemoved), nil, "disable removes inventory removed subscription")
expect(next(subscriptions.ContentLayerReady) ~= nil, true, "disable retains content UI")
expect(next(subscriptions.SettingsLayerReady) ~= nil, true, "disable retains settings UI")
expect(Recorder.GetLastAction(), "ruby bakriminel bolts (e)", "disable preserves last action")
ability(19255)
expect(Settings.get("combat_log"), previousLog, "disabled recording ignores abilities")
content.toggles.recording_active(nil, nil, "recording_active", true)
expect(next(subscriptions.VarTransmit) ~= nil, true, "reenable restores recording subscription")
expect(Settings.get("combat_log"), previousLog, "reenable retains log")
expect(Recorder.GetLastAction(), "ruby bakriminel bolts (e)", "reenable retains last action")
local previousSubscriptions = subscribeCalls.VarTransmit
Settings.update("recording_active", true)
expect(subscribeCalls.VarTransmit, previousSubscriptions, "repeated enable does not resubscribe")
failWrites = true
expect(pcall(Settings.update, "recording_active", false), false, "failed toggle write propagates")
expect(next(subscriptions.VarTransmit) ~= nil, true, "failed toggle retains recording subscription")
failWrites = false
content.toggles.pvme_syntax(nil, nil, "pvme_syntax", true)
content.buttons["Clear Log"]()
expect(Settings.get("combat_log"), "", "clear persists empty log")
expect(settingsPane.fields[1].text, "", "clear refreshes field")
expect(floatingLog.fields[1].text, "", "ribbon clear also refreshes floating log")
expect(content.text[2].content, "ruby bakriminel bolts (e)", "clear preserves last action")
ability(19255)
ammo(41629, 41627)
expect(Settings.get("combat_log"), "balancedstrike + rubybakri", "PvME ability and ammo maps")
settingsPane.buttons["Clear Log"]()
ammo(41627, 41629)
expect(Settings.get("combat_log"), "emeraldbakri", "first ammo has no separator")
ability(14682)
ability(14682)
expect(Settings.get("combat_log"), "emeraldbakri -> backhand -> backhand", "repeat abilities still recorded")

previousLog, previousUpdates = Settings.get("combat_log"), settingsPane.fields[1].updates
failWrites = true
expect(pcall(ability, 19255), false, "failed log write propagates")
expect(Settings.get("combat_log"), previousLog, "failed recording preserves log")
expect(Recorder.GetLastAction(), "backhand", "failed recording preserves last action")
expect(settingsPane.fields[1].updates, previousUpdates, "failed recording does not notify UI")
expect(pcall(Recorder.ClearLog), false, "failed clear propagates")
expect(Settings.get("combat_log"), previousLog, "failed clear preserves log")
failWrites = false

emit("ContentLayerReady", parent)
local reopenedContent = views[#views]
expect(content.destroyed, true, "old content destroyed on reopen")
expect(floatingLog.destroyed, nil, "ribbon reopening leaves independent floating log intact")
floatingLog:Close()
expect(reopenedContent.text[2].content, "backhand", "last action retained on reopen")
wornSlots[3] = { obj = { id = 51065, name = "Ornamented red EOF" }, count = 1 }
emit("SettingsLayerReady", parent)
local reopenedSettings = views[#views]
expect(reopenedSettings.combos[1].selected, 10, "pane defaults to worn ornamented red EOF")
wornSlots[3] = nil
expect(settingsPane.destroyed, true, "old settings destroyed on reopen")
ability(19255)
expect(reopenedContent.text[2].content, "balancedstrike", "new content receives updates")
expect(floatingLog.root.hidden, true, "recording does not reopen a closed floating window")
reopenedContent.buttons["Open Combat Log"]()
expect(#floatingWindows, 1, "closed floating log reopens without duplication")
expect(floatingLog.root.hidden, false, "floating log is shown again")
expect(floatingLog.fields[1].text, Settings.get("combat_log"), "reopened floating log shows current recording")
expect(reopenedSettings.fields[1].text, Settings.get("combat_log"), "new settings receives updates")

-- Configure regular and ornamented EOFs separately through the real pane callbacks.
local EOF = require("eof")
local variantCombo, weaponCombo = reopenedSettings.combos[1], reopenedSettings.combos[2]
expect(#variantCombo.entries, 16, "all colours and ornament styles available")
expect(variantCombo.entries[1].order, 1, "EOF selector uses custom ordered dropdown")
expect(weaponCombo.entries[1].order, 1, "weapon selector uses custom ordered dropdown")
local function chooseWeapon(name)
    for _, choice in ipairs(weaponCombo.entries) do
        if choice.label == name then weaponCombo:Select(choice.id, true); return end
    end
    error("missing weapon choice: " .. name)
end
variantCombo:Select(2, true) -- Regular red
for _, choice in ipairs({ { "Annihilation", "annihilation eofspec" }, { "Zaros godsword", "zgs eofspec" } }) do
    chooseWeapon(choice[1])
    expect(Settings.get("eof_weapon_regular_red"), choice[1], "new EOF dropdown option saves weapon")
    expect(require("item_names").Special("eofspec", EOF.GetWeapon(EOF.Variants[2]), true), choice[2],
        "new EOF option uses explicit PvME mapping")
end
chooseWeapon("Dark bow")
expect(Settings.get("eof_weapon_regular_red"), "Dark bow", "regular red selection saved")
variantCombo:Select(10, true) -- Ornamented red
chooseWeapon("Guthix staff")
expect(Settings.get("eof_weapon_ornamented_red"), "Guthix staff", "ornamented red selection saved separately")
variantCombo:Select(2, true)
expect(reopenedSettings.fields[2].text, "Dark bow", "switching variant restores saved selection")
variantCombo:Select(3, true) -- Regular blue, custom weapon
reopenedSettings.fields[2].onChange(nil, nil, "  A custom weapon  ")
expect(Settings.get("eof_weapon_regular_blue"), "A custom weapon", "custom weapon names saved and trimmed")
variantCombo:Select(2, true)
expect(EOF.Describe(51051), "Dark bow", "regular red item mapping")
expect(EOF.Describe(51065), "Guthix staff", "ornamented red item mapping")
expect(dofile("settings.lua").get("eof_weapon_regular_red"), "Dark bow", "EOF mapping survives settings reload")

local function item(id, name, count)
    return { obj = { id = id, name = name }, count = count or 1 }
end
local function updateWorn()
    emit("InventoryUpdated", { inv = { id = 94 }, slotsUpdated = {} })
end
Recorder.ClearLog()
wornSlots[4] = item(1000, "Test sword")
wornSlots[5] = item(2000, "Test armour")
wornSlots[14] = item(41627, "Emerald bolts", 100)
updateWorn()
expect(Settings.get("combat_log"), "[Test sword] + [Test armour] + emeraldbakri", "PvME swaps bracket unmapped names in slot order")
expect(reopenedSettings.fields[1].text, Settings.get("combat_log"), "equipment swaps refresh log pane")
local unchangedLog = Settings.get("combat_log")
wornSlots[14].count = 99
updateWorn()
expect(Settings.get("combat_log"), unchangedLog, "ammo count decrease is not a swap")
wornSlots[14].count = 200
updateWorn()
expect(Settings.get("combat_log"), unchangedLog, "ammo count increase is not a swap")
wornSlots[4] = item(1001, "Test axe")
emit("InventoryUpdated", { inv = { id = 93 } })
expect(Settings.get("combat_log"), unchangedLog, "ignore other inventories")
Recorder.ClearLog()
ability(28430)
expect(Settings.get("combat_log"), "[Test axe] spec", "special reads current main hand before inventory update callback")
updateWorn()
expect(Settings.get("combat_log"), "[Test axe] spec + [Test axe]", "special lookup does not consume swap detection")
wornSlots[5] = nil
local beforeUnequip = Settings.get("combat_log")
updateWorn()
expect(Settings.get("combat_log"), beforeUnequip, "PvME unequip adds no entry or separator")
expect(Recorder.GetLastAction(), "[Test axe]", "PvME unequip preserves last recorded action")
wornSlots[14] = item(41629, "Ruby bolts", 100)
updateWorn()
expect(Recorder.GetLastAction(), "rubybakri", "PvME ammo swaps use existing ammo aliases")
wornSlots[5] = item(2001, "Augmented Tectonic robe top")
updateWorn()
expect(Recorder.GetLastAction(), "tectbody", "PvME armour alias strips augmentation")
wornSlots[5] = item(id.Obj.NECRO_UNDERWORLD_BODY_T90_AUGMENTED, "Augmented Deathwarden robe top")
updateWorn()
expect(Recorder.GetLastAction(), "wardentop90", "PvME Deathwarden swaps resolve tier from item ID")
wornSlots[5] = item(id.Obj.NECRO_UNDERWORLD_BODY_T80_AUGMENTED, "Augmented Deathwarden robe top")
updateWorn()
expect(Recorder.GetLastAction(), "wardentop80", "same display name resolves to different tier icon")
wornSlots[5] = item(2003, "Elite tectonic mask")
updateWorn()
expect(Recorder.GetLastAction(), "elitetectmask", "new gear aliases reach the recording log")
wornSlots[5] = nil
wornSlots[14] = item(41627, "Emerald bolts", 100)
beforeUnequip = Settings.get("combat_log")
updateWorn()
expect(Settings.get("combat_log"), beforeUnequip .. " + emeraldbakri", "mixed PvME changes record only the equipped item")
Settings.update("pvme_syntax", false)
wornSlots[5] = item(2002, "Test armour")
updateWorn()
expect(Recorder.GetLastAction(), "equip Test armour [Body]", "normal equipment syntax retains equip and slot")
wornSlots[5] = nil
updateWorn()
expect(Recorder.GetLastAction(), "unequip Test armour [Body]", "normal mode still records unequips")
Settings.update("pvme_syntax", true)

wornSlots[3] = item(51051, "Red EOF")
updateWorn()
expect(Recorder.GetLastAction(), "eofred", "regular red EOF swaps use canonical regular token")
Recorder.ClearLog()
ability(11748)
expect(Settings.get("combat_log"), "dbow eofspec", "EOF uses stored weapon instead of main hand")
wornSlots[3] = item(51065, "Ornamented red EOF")
updateWorn()
expect(Recorder.GetLastAction(), "eoforred", "ornamented red EOF swaps use distinct ornamented token")
expect(reopenedSettings.combos[1].selected, 10, "open pane follows ornamented EOF swap")
expect(reopenedSettings.combos[1].selectedLabel, "Ornamented - Red", "live swap refreshes visible EOF dropdown label")
expect(reopenedSettings.combos[2].selectedLabel, "Guthix staff", "live swap refreshes visible weapon dropdown label")
expect(reopenedSettings.fields[2].text, "Guthix staff", "EOF swap refreshes saved weapon field")
Recorder.ClearLog()
ability(11748)
expect(Settings.get("combat_log"), "gstaff eofspec", "ornamented EOF uses separate stored weapon")
wornSlots[3] = item(51055, "Yellow EOF")
Recorder.ClearLog()
ability(11748)
expect(Settings.get("combat_log"), "eofspec [not configured: Regular - Yellow]", "unconfigured EOF description is literal text")
wornSlots[3] = nil
Recorder.ClearLog()
ability(11748)
expect(Settings.get("combat_log"), "eofspec [unknown EOF]", "missing EOF does not reuse stale weapon")
wornSlots[4] = nil
Recorder.ClearLog()
ability(28430)
expect(Settings.get("combat_log"), "spec [unknown weapon]", "missing main hand description is literal text")
Settings.update("pvme_syntax", false)
wornSlots[4] = item(1000, "Test sword")
Recorder.ClearLog()
ability(28430)
expect(Settings.get("combat_log"), "weapon special attack (Test sword)", "normal syntax includes main hand weapon")
Settings.update("pvme_syntax", true)
wornSlots[4] = item(1000, "Augmented Omni guard")
Recorder.ClearLog()
ability(28430)
expect(Settings.get("combat_log"), "omniguard spec", "PvME Omni guard alias precedes special")
wornSlots[4] = item(1000, "Augmented Fractured staff of Armadyl (ice)")
Recorder.ClearLog()
ability(28430)
expect(Settings.get("combat_log"), "fsoa spec", "PvME FSOA alias handles augmentation and dye")
Settings.update("pvme_syntax", false)
Recorder.ClearLog()
ability(28430)
expect(Settings.get("combat_log"), "weapon special attack (Fractured staff of Armadyl (ice))", "normal syntax retains parentheses and full weapon name")
wornSlots[4] = item(1000, "Test sword")
wornSlots[3] = item(51051, "Red EOF")
Recorder.ClearLog()
ability(11748)
expect(Settings.get("combat_log"), "essence of finality (Dark bow)", "normal syntax includes stored EOF weapon")
Settings.update("pvme_syntax", true)

-- Reloads, reconnects and pauses establish a fresh baseline instead of logging gear.
unchangedLog = Settings.get("combat_log")
expect(require("equipment").GetEquipped(4).name, "Test sword", "read weapon from non-iterable direct proxy")
expect(require("equipment").GetEquipped(3).id, 51051, "read EOF from non-iterable direct proxy")
emit("InventoryRemoved", { inv = { id = 94 } })
wornAvailable = false
updateWorn()
expect(Settings.get("combat_log"), unchangedLog, "unavailable inventory produces no phantom unequips")
wornAvailable = true
emit("InventoryAdded", { inv = { id = 94 } })
updateWorn()
expect(Settings.get("combat_log"), unchangedLog, "inventory added establishes baseline")
Settings.update("recording_active", false)
wornSlots[4] = item(1001, "Test axe")
updateWorn()
Settings.update("recording_active", true)
updateWorn()
expect(Settings.get("combat_log"), unchangedLog, "reenabling does not log gear changed while paused")
expect(Recorder.GetLastAction(), "essence of finality (Dark bow)", "pause preserves last recorded action")

Settings.update("recording_active", false)
emit("SettingsLayerReady", parent)
reopenedSettings = views[#views]
expect(reopenedSettings.combos[1].selected, 2, "pane defaults to worn regular red EOF while recording is off")
expect(reopenedSettings.fields[2].text, "Dark bow", "worn EOF selection loads matching saved weapon")
expect(Settings.get("combat_log"), unchangedLog, "opening pane does not add equipment actions")
wornSlots[3] = item(51065, "Ornamented red EOF")
updateWorn()
expect(reopenedSettings.combos[1].selected, 10, "open pane follows EOF swaps while recording is off")
expect(reopenedSettings.combos[1].selectedLabel, "Ornamented - Red", "paused swap refreshes visible EOF dropdown label")
expect(reopenedSettings.fields[2].text, "Guthix staff", "paused EOF swap loads matching weapon")
expect(next(subscriptions.InventoryUpdated), nil, "UI hook does not resume gameplay inventory subscriptions")
expect(Settings.get("combat_log"), unchangedLog, "paused EOF swap is not recorded")
reopenedSettings.combos[1]:Select(3, true)
wornSlots[14].count = 199
updateWorn()
expect(reopenedSettings.combos[1].selected, 3, "unrelated inventory changes preserve manual EOF selection")
wornSlots[3] = item(51051, "Red EOF")
updateWorn()
expect(reopenedSettings.combos[1].selected, 2, "next actual EOF swap updates manual selection")
expect(reopenedSettings.combos[1].selectedLabel, "Regular - Red", "regular EOF label replaces prior ornamented label")
expect(Settings.get("eof_weapon_ornamented_red"), "Guthix staff", "programmatic refresh preserves ornamented mapping")
expect(Settings.get("eof_weapon_regular_red"), "Dark bow", "programmatic refresh preserves regular mapping")
expect(reopenedSettings.fields[2].text, "Dark bow", "next swap restores correct saved mapping")
EOF.SetWeapon(EOF.Variants[11], "Death guard")
EOF.SetWeapon(EOF.Variants[15], "Varanus's Mercy")
wornSlots[3] = item(51067, "Ornamented blue EOF")
updateWorn()
expect(reopenedSettings.combos[1].selectedLabel, "Ornamented - Blue", "blue ornamented EOF shown visibly")
wornSlots[3] = item(51075, "Ornamented pink EOF")
updateWorn()
expect(reopenedSettings.combos[1].selected, 15, "pink ornamented EOF selected logically")
expect(reopenedSettings.combos[1].selectedLabel, "Ornamented - Pink", "blue-to-pink swap changes visible dropdown header")
expect(reopenedSettings.combos[2].selectedLabel, "Varanus's Mercy", "pink EOF weapon dropdown visibly follows swap")
expect(reopenedSettings.fields[2].text, "Varanus's Mercy", "pink EOF stored weapon field follows swap")
expect(EOF.GetWeapon(EOF.Variants[11]), "Death guard", "live selection does not overwrite blue mapping")
wornSlots[3] = item(51051, "Red EOF")
updateWorn()
Settings.update("recording_active", true)

floatingLog.root.x, floatingLog.root.y = 310, 200
PluginShutdown()
expect(dofile("settings.lua").get("log_window_position"), "310,200", "shutdown saves final coordinates without a drag callback")
expect(reopenedContent.destroyed, true, "content destroyed on shutdown")
expect(reopenedSettings.destroyed, true, "settings destroyed on shutdown")
expect(floatingLog.destroyed, true, "floating log destroyed on shutdown")
expect(next(reopenedSettings.root.hooks), nil, "pane inventory hook removed with view")
Settings.update("recording_active", false)
Settings.update("recording_active", true)
for name, callbacks in pairs(subscriptions) do expect(next(callbacks), nil, name .. " unsubscribed") end
previousLog = Settings.get("combat_log")
ability(19255)
expect(Settings.get("combat_log"), previousLog, "no recording after shutdown")
PluginShutdown()
Recorder.Start()
ContentPane.Start()
SettingsPane.Start()
require("interface/log_window").Show()
expect(floatingWindows[#floatingWindows].options.x, 310, "floating log restores saved horizontal position after restart")
expect(floatingWindows[#floatingWindows].options.y, 200, "floating log restores saved vertical position after restart")
expect(Recorder.GetLastAction(), nil, "restart clears session last action")
ability(14682)
expect(Settings.get("combat_log"), previousLog .. " -> backhand", "restart retains saved log")
config.Obj = {FromID=function() error("Ammo recording must use explicit maps") end}
Settings.update("pvme_syntax", false)
Recorder.ClearLog()
ammo(id.Obj.DINARROW_JAS_DEMONBANE, id.Obj.SNIPER_BOLTS_RU_E)
expect(Settings.get("combat_log"), "jas demonbane arrows", "T95 ammo records its explicit name")
Settings.update("pvme_syntax", true)
Recorder.ClearLog()
ammo(id.Obj.DINARROW_JAS_DEMONBANE, id.Obj.SNIPER_BOLTS_RU_E)
expect(Settings.get("combat_log"), "jasdemonbanearrow", "T95 ammo records its explicit PvME token")
Recorder.ClearLog()
ammo(id.Obj.QBD2_BOLTS, id.Obj.DINARROW_JAS_DEMONBANE)
expect(Settings.get("combat_log"), "[royal bolts]", "PvME ammo without an icon is literal text")
ammo(id.Obj.SNIPER_BOLTS_DI_E, id.Obj.QBD2_BOLTS)
expect(Settings.get("combat_log"), "[royal bolts] + diamond", "PvME ammo uses the canonical preset-slot-9 ID")
PluginShutdown() -- Safe without opening panes.
for name, callbacks in pairs(subscriptions) do expect(next(callbacks), nil, name .. " cleaned up without panes") end
print("Combat Recorder: " .. checks .. " checks passed")
