local AbilityMap = require("abilitymap")

Event.VarTransmit.Subscribe("myEvent", function(varTransmitEvent)

    local varName = varTransmitEvent.var.configName
    local oldValue = varTransmitEvent.oldValue
    local newValue = varTransmitEvent.newValue

    local varChange = (oldValue or "nil") .. " -> " .. (newValue or "nil")
    if varName == "COMBATV2_JUST_USED_ABILITY" and newValue ~= nil and AbilityMap[newValue] == nil then
        print(newValue)
    end
    if RecordingActive and varName == "COMBATV2_JUST_USED_ABILITY" and newValue ~= nil and AbilityMap[newValue] ~= nil then
        if AbilityLog ~= "" then
            -- TODO need to add logic to determine if an ability is used off-GCD to change the -> to a +
            AbilityLog = AbilityLog .. " -> " .. AbilityMap[newValue]
        else
            AbilityLog = AbilityMap[newValue]
        end

        print(AbilityLog)
    end
    
    

end)

RecordingActive = false
AbilityLog = ""

function StartRecording()
    print("Starting recording...")
    RecordingActive = true

end

function StopRecording()
    RecordingActive = false
end

function ExportRecording()
    -- todo
end

function ClearLog()
    AbilityLog = ""
end

Root = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)

popupButton = ui.Button.new(Root, 37, 2)
popupButton:SetPos(1000, 300)
popupButton:SetSize(200, 50)
popupButton.stylesheetID = id.StyleSheet.BUTTON_ACTION_NEUTRAL_MOBILE
popupButton.text.content = "Start Ability Recording"
popupButton:Subscribe(ui.Hook.ONBUTTONPRESSED, function() StartRecording() end)

popupButton = ui.Button.new(Root, 37, 3)
popupButton:SetPos(1250, 300)
popupButton:SetSize(200, 50)
popupButton.stylesheetID = id.StyleSheet.BUTTON_ACTION_NEUTRAL_MOBILE
popupButton.text.content = "End Ability Recording"
popupButton:Subscribe(ui.Hook.ONBUTTONPRESSED, function() StopRecording() end)

popupButton = ui.Button.new(Root, 37, 4)
popupButton:SetPos(1000, 400)
popupButton:SetSize(200, 50)
popupButton.stylesheetID = id.StyleSheet.BUTTON_ACTION_NEUTRAL_MOBILE
popupButton.text.content = "Export Ability Session"
popupButton:Subscribe(ui.Hook.ONBUTTONPRESSED, function() ExportRecording() end)

popupButton = ui.Button.new(Root, 37, 5)
popupButton:SetPos(1250, 400)
popupButton:SetSize(200, 50)
popupButton.stylesheetID = id.StyleSheet.BUTTON_ACTION_NEUTRAL_MOBILE
popupButton.text.content = "Clear Ability Log"
popupButton:Subscribe(ui.Hook.ONBUTTONPRESSED, function() ClearLog() end)

