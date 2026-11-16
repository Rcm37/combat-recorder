local GCD = {}
local previousClient, previousServer

local function readStart(domain, name)
    local ok, value = pcall(function() return var[domain][name].value end)
    if ok and type(value) == "number" and value >= 0 and value < math.huge then return value end
end

local function snapshot()
    return readStart("VarClient", "COMBATV2_GLOBAL_COOLDOWN_START_CLIENT"),
        readStart("VarPlayer", "COMBATV2_GLOBAL_COOLDOWN_START")
end

function GCD.Reset()
    previousClient, previousServer = snapshot()
end

function GCD.Separator()
    local client, server = snapshot()
    -- Prefer the client marker so its server counterpart cannot count the same GCD twice
    local changed
    if client then changed = client > 0 and client ~= previousClient
    elseif server then changed = server > 0 and server ~= previousServer end
    previousClient, previousServer = client, server
    if client == nil and server == nil then return " -> " end
    return changed and " -> " or " + "
end

return GCD
