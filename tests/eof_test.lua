id = id or {}
dofile("../runescape-api-stubs/consts/Obj.lua")
dofile("../runescape-api-stubs/consts/Struct.lua")
-- Run from combat-recorder: lua tests/eof_test.lua
local saved = {}
PersistentDB = {
    GetString = function(_, key) return saved[key] end,
    SetString = function(_, key, value) saved[key] = value end,
}
local EOF = require("eof")
local checks, ids = 0, {}
for _, variant in ipairs(EOF.Variants) do
    assert(EOF.GetWeapon(variant) == "", "new mappings must be unconfigured")
    EOF.SetWeapon(variant, "Weapon for " .. variant.label)
    for _, itemID in ipairs(variant.ids) do
        assert(not ids[itemID], "EOF ID assigned to multiple variants")
        ids[itemID] = true
        assert(EOF.GetVariant(itemID) == variant, "wrong variant for item " .. itemID)
        assert(EOF.Describe(itemID) == "Weapon for " .. variant.label, "wrong stored weapon")
        checks = checks + 3
    end
    EOF.SetWeapon(variant, "")
    assert(EOF.Describe(variant.ids[1]) == "not configured: " .. variant.label, "clearing mapping must remove weapon")
    checks = checks + 2
end
assert(EOF.GetVariant(50466) == nil, "noted amulet must not be treated as worn EOF")
assert(EOF.Describe(nil) == "unknown EOF", "missing item must not guess stored weapon")
print("EOF: " .. (checks + 2) .. " checks passed")
