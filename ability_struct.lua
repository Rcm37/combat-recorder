local AbilityStruct = {}

function AbilityStruct.GetName(abilityID)
    if type(abilityID) ~= "number" or abilityID <= 0 or abilityID % 1 ~= 0 then return nil end
    local ok, name = pcall(function()
        local struct = config.Struct.FromID(abilityID)
        if not struct then return nil end
        return struct:GetParamValue(config.Param.COMBATV2_ABILITY_NAME)
    end)
    if ok and type(name) == "string" and name:find("%S") then return name end
end

return AbilityStruct
