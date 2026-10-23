-- Run from combat-recorder: lua tests/recorder_test.lua
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local subscriptions = {}
local views = {}
ui = { Hook = { ONINVTRANSMIT = "ONINVTRANSMIT" } }
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
    InventoryUpdated = event("InventoryUpdated"), InventoryRemoved = event("InventoryRemoved") }
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
prettyui = { SimpleView = { new = function()
    local view = { text = {}, fields = {}, buttons = {}, toggles = {}, combos = {} }
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
ability(19255)
expect(Settings.get("combat_log"), "balanced strike", "first ability has no separator")
expect(Recorder.GetLastAction(), "balanced strike", "record before panes open")
local parent = { component = { width = 400, height = 600 } }
emit("ContentLayerReady", parent)
local content = views[#views]
expect(content.text[2].content, "balanced strike", "pane shows last action recorded before opening")
emit("SettingsLayerReady", parent)
local settingsPane = views[#views]
expect(settingsPane.fields[1].text, "balanced strike", "pane shows saved log")
expect(settingsPane.combos[1].selected, 1, "no equipped EOF uses default variant")
ability(14682)
expect(Settings.get("combat_log"), "balanced strike -> backhand", "ability separator")
expect(content.text[2].content, "backhand", "last action refreshed")
expect(settingsPane.fields[1].text, "balanced strike -> backhand", "log field refreshed")
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
settingsPane.buttons["Clear Log"]()
expect(Settings.get("combat_log"), "", "clear persists empty log")
expect(settingsPane.fields[1].text, "", "clear refreshes field")
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
expect(reopenedContent.text[2].content, "backhand", "last action retained on reopen")
wornSlots[3] = { obj = { id = 51065, name = "Ornamented red EOF" }, count = 1 }
emit("SettingsLayerReady", parent)
local reopenedSettings = views[#views]
expect(reopenedSettings.combos[1].selected, 10, "pane defaults to worn ornamented red EOF")
wornSlots[3] = nil
expect(settingsPane.destroyed, true, "old settings destroyed on reopen")
ability(19255)
expect(reopenedContent.text[2].content, "balancedstrike", "new content receives updates")
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
expect(Settings.get("combat_log"), "testsword + testarmour + emeraldbakri", "PvME swaps contain only shortnames in slot order")
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
expect(Settings.get("combat_log"), "testaxe spec", "special reads current main hand before inventory update callback")
updateWorn()
expect(Settings.get("combat_log"), "testaxe spec + testaxe", "special lookup does not consume swap detection")
wornSlots[5] = nil
updateWorn()
expect(Recorder.GetLastAction(), "unequip testarmour", "PvME unequips retain removal marker without slot")
wornSlots[14] = item(41629, "Ruby bolts", 100)
updateWorn()
expect(Recorder.GetLastAction(), "rubybakri", "PvME ammo swaps use existing ammo aliases")
wornSlots[5] = item(2001, "Augmented Tectonic robe top")
updateWorn()
expect(Recorder.GetLastAction(), "tectbody", "PvME armour alias strips augmentation")
Settings.update("pvme_syntax", false)
wornSlots[5] = item(2002, "Test armour")
updateWorn()
expect(Recorder.GetLastAction(), "equip Test armour [Body]", "normal equipment syntax retains equip and slot")
Settings.update("pvme_syntax", true)

wornSlots[3] = item(51051, "Red EOF")
updateWorn()
expect(Recorder.GetLastAction(), "eofredu", "regular red EOF swaps use colour-specific PvME token")
Recorder.ClearLog()
ability(11748)
expect(Settings.get("combat_log"), "dbow eofspec", "EOF uses stored weapon instead of main hand")
wornSlots[3] = item(51065, "Ornamented red EOF")
updateWorn()
expect(Recorder.GetLastAction(), "eofred", "ornamented red EOF swaps use distinct PvME token")
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
expect(Settings.get("combat_log"), "eofspec (not configured: Regular - Yellow)", "unconfigured EOF labeled honestly")
wornSlots[3] = nil
Recorder.ClearLog()
ability(11748)
expect(Settings.get("combat_log"), "eofspec (unknown EOF)", "missing EOF does not reuse stale weapon")
wornSlots[4] = nil
Recorder.ClearLog()
ability(28430)
expect(Settings.get("combat_log"), "spec (unknown weapon)", "missing main hand labeled honestly")
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

PluginShutdown()
expect(reopenedContent.destroyed, true, "content destroyed on shutdown")
expect(reopenedSettings.destroyed, true, "settings destroyed on shutdown")
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
expect(Recorder.GetLastAction(), nil, "restart clears session last action")
ability(14682)
expect(Settings.get("combat_log"), previousLog .. " -> backhand", "restart retains saved log")
PluginShutdown() -- Safe without opening panes.
for name, callbacks in pairs(subscriptions) do expect(next(callbacks), nil, name .. " cleaned up without panes") end
print("Combat Recorder: " .. checks .. " checks passed")
