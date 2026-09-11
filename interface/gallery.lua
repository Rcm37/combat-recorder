local gallery = {}
local Settings = require("Settings")

local GUI_WIDTH = 400
local GUI_HEIGHT = 260

-- Main gallery surfaces.
local toggleGUI = nil
local onClose = nil

-- Build our primary window
local function createDemoWindow(gameArea)
    return prettyui.Window.new(gameArea, {
        title = "Combat Recorder",
        x = 20,
        y = 20,
        xAnchor = 0,
        yAnchor = 0,
        width = GUI_WIDTH,
        height = GUI_HEIGHT,
        minWidth = 240,
        minHeight = 260,
        onClose = function()
            if onClose then onClose() end
        end,
    })
end

local function createWindow(window)
    window:AddCheckboxButton({
        { text = "Enable Recording", value = "recording_active", selected = Settings.get("recording_active") },
    }, {
        onChange = function(_, _, changedValue, selected)
            updateSettings(changedValue, selected)
        end,
    })
    window:AddCheckboxButton({
        { text = "Use PvME Rotation Builder Syntax", value = "pvme_syntax", selected = Settings.get("pvme_syntax") },
    }, {
        onChange = function(_, _, changedValue, selected)
            updateSettings(changedValue, selected)
        end,
    })
    local ability_log_collapse = window:AddCollapseButton("Combat Log", {
        expanded = Settings.get("expanded"),
        onToggle = function(_, expanded)
            updateSettings("expanded", expanded)
        end,
    })
    gallery.combat_log_text = ability_log_collapse:AddTextField({
        text = Settings.get("combat_log"),
    })
    ability_log_collapse:AddText({
        text = "Not intended for user input. CTRL+A CTRL+C to select all and copy"
    })
    ability_log_collapse:AddSimpleButton("Clear Log", function()
        gallery.clearLog()
    end)
end

function gallery.Build(onCloseHandler)
    onClose = onCloseHandler
    if toggleGUI ~= nil then return true end

    local gameArea = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
    if gameArea == nil then return false end

    toggleGUI = createDemoWindow(gameArea)

    createWindow(toggleGUI)

    return true
end

function gallery.clearLog()
    Settings.update("combat_log", "")
    gallery.updateCombatLog()
end

function gallery.updateCombatLog()
    gallery.combat_log_text:SetText(Settings.get("combat_log"))
end

function updateSettings(settingsKey, value)
    Settings.update(settingsKey, value)
end

function gallery.Show()
    if toggleGUI then toggleGUI:Show() end
end

function gallery.Close()
    if toggleGUI then toggleGUI:Close() end
end

function gallery.Destroy()
    -- Destroy the roots we own; child components are destroyed with them.
    if toggleGUI then toggleGUI:Destroy() end

    -- Release retained component handles.
    onClose = nil
    toggleGUI = nil
end

return gallery
