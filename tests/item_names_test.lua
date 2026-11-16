-- Run from combat-recorder: lua tests/item_names_test.lua
id = {}
dofile("../runescape-api-stubs/consts/Obj.lua")
local ItemNames = require("item_names")

assert(ItemNames.PvME("elitetectonicmask") == "elitetectmask", "compact recorded names match aliases")
assert(ItemNames.Equipment({ id = id.Obj.ENCHANTED_ALCHEMICAL_HYDRIX_AMULET_ORNATE_PINK_USED,
    name = "Essence of finality amulet (or)" }) == "eofpinkor", "ornamented pink uses its irregular canonical ID")
assert(ItemNames.PvME("Augmented Dark shard of Leng (ice)") == "lengmh", "augmentation and dye retain gear match")
assert(ItemNames.PvME("Dark sliver of Leng") == "lengoh", "off-hand has its own icon")
assert(ItemNames.PvME("Shadow glaive") == "glaivemh")
assert(ItemNames.PvME("Off-hand Shadow glaive") == "glaiveoh")
assert(ItemNames.PvME("Grasping rune pouch (pink)") == "graspingpouchpink", "colour is not stripped like a dye")
assert(ItemNames.PvME("Luck of the Dwarves (i)") == "lotd", "imbued ring uses approved base-item icon")
assert(ItemNames.PvME("Enhanced Kerapac's wrist wraps") == "kerapacswristwraps", "enhanced gloves use approved base icon")
assert(ItemNames.PvME("Occultist's ring") == "occulistring", "PvME's spelling is used verbatim")
assert(ItemNames.PvME("Salve amulet (e)") == "salveamulet", "enchantment suffix matches")
assert(ItemNames.PvME("Am-zi") == "[Am-zi]", "missing emoji is literal text")
assert(ItemNames.PvME("Unlisted gear") == "[Unlisted gear]", "unmapped gear preserves its readable name")
assert(ItemNames.PvME("A test fsoa weapon") == "[A test fsoa weapon]", "emoji substring stays inside literal text")
assert(ItemNames.PvME("Augmented Unlisted gear (ice)") == "[Unlisted gear (ice)]", "fallback preserves dye information")
assert(ItemNames.Special("spec", "Unlisted gear", true) == "[Unlisted gear] spec", "special brackets only the unmapped weapon")

for _, tier in ipairs({ 70, 80, 90 }) do
    for _, part in ipairs({
        { "HEAD", "hood", "hood" }, { "BODY", "robe top", "top" },
        { "LEGS", "robe bottom", "legs" }, { "HANDS", "gloves", "gloves" },
        { "FEET", "boots", "boots" },
    }) do
        local token = tier == 70 and ("deathwarden" .. part[2]:gsub(" ", "") .. "t70")
            or ("warden" .. part[3] .. tier)
        local key = "NECRO_UNDERWORLD_" .. part[1] .. "_T" .. tier
        local name = "Deathwarden " .. part[2]
        assert(ItemNames.Equipment({ id = id.Obj[key], name = name }) == token, "tier comes from equipment ID")
        assert(ItemNames.PvME(name .. " (tier " .. tier .. ")") == token, "tier-qualified names match")
        if part[1] == "BODY" or part[1] == "LEGS" then
            for _, suffix in ipairs({ "_AUGMENTED", "_AUGMENTED_UNCHARGED" }) do
                assert(ItemNames.Equipment({ id = id.Obj[key .. suffix], name = "Augmented " .. name }) == token)
            end
        end
    end
end
assert(ItemNames.Equipment({ id = id.Obj.NECRO_UNDERWORLD_FEET_T60, name = "Deathwarden boots" }) == "[Deathwarden boots]",
    "unlisted lower tiers are not assigned a higher-tier icon")
for _, tier in ipairs({ 70, 80, 90 }) do
    for _, part in ipairs({
        { "HEAD", "hood", "hood" }, { "BODY", "robe top", "top" },
        { "LEGS", "robe bottom", "legs" }, { "HANDS", "gloves", "gloves" },
        { "FEET", "boots", "boots" },
    }) do
        local token = tier == 80 and ("dealer" .. part[3] .. "80")
            or ("deathdealer" .. part[2]:gsub(" ", "") .. "t" .. tier)
        local key = "NECRO_UNDERWORLD_POWER_" .. part[1] .. "_T" .. tier
        local name = "Deathdealer " .. part[2]
        if tier == 90 then
            token = "[" .. name .. "]"
            assert(ItemNames.PvME(name .. " (tier 90)") == "[" .. name .. " (tier 90)]",
                "explicit tier-90 names also use literal text")
        end
        assert(ItemNames.Equipment({ id = id.Obj[key], name = name }) == token, "Deathdealer tier comes from ID")
        if part[1] == "BODY" or part[1] == "LEGS" then
            for _, suffix in ipairs({ "_AUGMENTED", "_AUGMENTED_UNCHARGED" }) do
                assert(ItemNames.Equipment({ id = id.Obj[key .. suffix], name = "Augmented " .. name }) == token)
            end
        end
    end
end
print("Item names: gear aliases, variants, tier icons, and tier-90 Deathdealer literal text passed")
