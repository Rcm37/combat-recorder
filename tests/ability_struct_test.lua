id = id or {}
dofile("../runescape-api-stubs/consts/Obj.lua")
dofile("../runescape-api-stubs/consts/Struct.lua")
-- Run from combat-recorder: lua tests/ability_struct_test.lua
local AbilityStruct = require("ability_struct")
local nameParam = {}
config = { Param = { COMBATV2_ABILITY_NAME = nameParam }, Struct = {} }
local nameValue = "Soul Strike"
config.Struct.FromID = function(id)
    if id == 999 then error("unavailable struct") end
    if id == 888 then return nil end
    return { GetParamValue = function(_, param)
        assert(param == nameParam)
        return nameValue
    end }
end
assert(AbilityStruct.GetName(123) == "Soul Strike")
nameValue = ""
assert(AbilityStruct.GetName(123) == nil)
nameValue = "   "
assert(AbilityStruct.GetName(123) == nil)
nameValue = 42
assert(AbilityStruct.GetName(123) == nil)
assert(AbilityStruct.GetName(999) == nil)
assert(AbilityStruct.GetName(888) == nil)
assert(AbilityStruct.GetName(0) == nil)
assert(AbilityStruct.GetName(-1) == nil)
assert(AbilityStruct.GetName(nil) == nil)
print("Ability struct names: all checks passed")
