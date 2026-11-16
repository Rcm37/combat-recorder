local ItemNames = {}
local AmmoMapPvME = require("ammomap_pvme")
local EOFVariants = require("eof_variants")
local PvME = require("pvme")
local GearAliasesPvME = require("gear_aliases_pvme")
local gearTokenFallbacks = {
    enhancedfleet = "fleetingboots",
    enhancedlacs = "laceration",
    enhancedblastdiff = "blastdiffusion",
}
-- These entries have pvme emojis, but aren't available on the rot builder. Might be changed later
local unsupportedGearTokens = {
    deathdealerhoodt90 = true,
    deathdealerrobetopt90 = true,
    deathdealerrobebottomt90 = true,
    deathdealerglovest90 = true,
    deathdealerbootst90 = true,
}

local eofAliases = {}

local eofTokens = {
    regular_default = "eof",
    regular_red = "eofred",
    regular_blue = "eofblue",
    regular_yellow = "eofyellow",
    regular_green = "eofgreen",
    regular_purple = "eofpurple",
    regular_pink = "eofpink",
    regular_black = "eofblack",
    ornamented_default = "eofor",
    ornamented_red = "eoforred",
    ornamented_blue = "eoforblue",
    ornamented_yellow = "eoforyellow",
    ornamented_green = "eoforgreen",
    ornamented_purple = "eoforpurple",
    ornamented_pink = "eofpinkor",
    ornamented_black = "eoforblack",
}
for _, variant in ipairs(EOFVariants) do
    for _, itemID in ipairs(variant.ids) do eofAliases[itemID] = eofTokens[variant.key] end
end

local aliases = {
    ["death guard"] = "deathguard90",
    ["annihilation"] = "annihilation",
    ["fractured staff of armadyl"] = "fsoa",
    ["omni guard"] = "omniguard",
    ["seren godbow"] = "sgb",
    ["eldritch crossbow"] = "ecb",
    ["zaros godsword"] = "zgs",
    ["staff of sliske"] = "sos",
    ["armadyl godsword"] = "ags",
    ["bandos godsword"] = "bgs",
    ["saradomin godsword"] = "sgs",
    ["armadyl battlestaff"] = "abs",
    ["dark bow"] = "dbow",
    ["guthix staff"] = "gstaff",
    ["statius's warhammer"] = "swh",
    ["dragon battleaxe"] = "dba",
    ["granite maul"] = "gmaul",
    ["bow of the last guardian"] = "bolg",
    ["ek-zekkil"] = "ezk",
    ["tectonic mask"] = "tectmask",
    ["tectonic robe top"] = "tectbody",
    ["tectonic robe bottom"] = "tectlegs",
    ["elite tectonic mask"] = "elitetectmask",
    ["robe top of the first necromancer"] = "firstnecrorobetop",
    ["vestments of havoc robe top"] = "vestmentsofhavoctop",
    ["vestments of havoc robe bottom"] = "vestmentsofhavocbottom",
    ["dracolich hauberk"] = "dracolichbody",
    ["elite dracolich hauberk"] = "edracobody",
    ["elite dracolich vambraces"] = "edracolichvambs",
    ["masterwork ranged boots"] = "mwrboots",
    ["masterwork ranged vambraces"] = "mwrvambraces",
    ["masterwork ranged chaps"] = "mwrchaps",
    ["masterwork ranged body"] = "mwrbody",
    ["masterwork ranged cowl"] = "mwrcowl",
    ["cinderbane gloves"] = "cinderbanes",
    ["blast diffusion boots"] = "blastdiffusion",
    ["enhanced blast diffusion boots"] = "blastdiffusion",
    ["enhanced fleeting boots"] = "fleetingboots",
    ["enhanced laceration boots"] = "laceration",
    -- The supplied emoji list only has base-item icons for these variants.
    ["enhanced kerapac's wrist wraps"] = "kerapacswristwraps",
    ["enhanced nightmare gauntlets"] = "nightmaregauntlets",
    ["enhanced gloves of passage"] = "glovesofpassage",
    ["shadow glaive"] = "glaivemh",
    ["off-hand shadow glaive"] = "glaiveoh",
    ["deathtouched bracelet"] = "dtb",
    ["deathtouch bracelet"] = "dtb",
    ["malevolent kiteshield"] = "malevkite",
    ["merciless kiteshield"] = "merciless",
    ["vengeful kiteshield"] = "vengeful",
    ["laniakea's spear"] = "lanispear",
    ["dark sliver of leng"] = "lengoh",
    ["dark shard of leng"] = "lengmh",
    ["mechanised chinchompa"] = "mechchin",
    ["the devourer's nexus"] = "devourersnexus",
    ["amulet of souls"] = "aos",
    ["luck of the dwarves"] = "lotd",
    ["luck of the dwarves (i)"] = "lotd",
    ["asylum surgeon's ring"] = "asr",
    ["champion's ring"] = "championring",
    -- Preserve PvME's spelling of the canonical emoji ID.
    ["occultist's ring"] = "occulistring",
    ["reaver's ring"] = "reaverring",
    -- Imbued/overcharged variants share the available base ring icon.
    ["ring of death (i)"] = "rod",
    ["ring of death (o)"] = "rod",
    ["ring of death (i)(o)"] = "rod",
    ["ring of death (o)(i)"] = "rod",
    ["grasping rune pouch (black)"] = "graspingpouchblack",
    ["grasping rune pouch (pink)"] = "graspingpouchpink",
    ["grasping rune pouch (blue)"] = "graspingpouchblue",
    ["amulet of zealots"] = "zealots",
    ["expensive spices"] = "spices",
    ["salve amulet (e)"] = "salveamulet",
    ["grace of the elves"] = "gote",
    ["erethdor's grimoire"] = "grim",
}
local compactAliases = {}
for name, token in pairs(aliases) do compactAliases[name:gsub("[%s%p]", "")] = token end

-- Necromancy armour tiers share their in-game display names. Resolve equipped items
-- by ID instead of assigning every tier the same icon.
local necromancyAliases = {}
local necromancyParts = { HEAD = "hood", BODY = "robetop", LEGS = "robebottom",
    HANDS = "gloves", FEET = "boots" }
for _, family in ipairs({
    { name = "deathwarden", prefix = "NECRO_UNDERWORLD_" },
    { name = "deathdealer", prefix = "NECRO_UNDERWORLD_POWER_" },
}) do
    for _, tier in ipairs({ 70, 80, 90 }) do
        for part, name in pairs(necromancyParts) do
            local token = GearAliasesPvME[family.name .. name .. "tier" .. tier]
            local key = family.prefix .. part .. "_T" .. tier
            necromancyAliases[id.Obj[key]] = token
            if part == "BODY" or part == "LEGS" then
                necromancyAliases[id.Obj[key .. "_AUGMENTED"]] = token
                necromancyAliases[id.Obj[key .. "_AUGMENTED_UNCHARGED"]] = token
            end
        end
    end
end
local dyes = {
    barrows = true, shadow = true, blood = true, ice = true,
    ["third age"] = true, ["3rd age"] = true, aurora = true, soul = true,
}

function ItemNames.Display(name)
    return (name:gsub("^[Aa][Uu][Gg][Mm][Ee][Nn][Tt][Ee][Dd]%s+", ""))
end

local function formatGear(token, name)
    token = gearTokenFallbacks[token] or token
    if token and not unsupportedGearTokens[token] then return token end
    return PvME.Literal(ItemNames.Display(name))
end

function ItemNames.PvME(name)
    local key = ItemNames.Display(name):lower():match("^%s*(.-)%s*$")
    local fullKey = key:gsub("[%s%p]", "")
    key = key:gsub("%s*(%(([^()]*)%))$", function(suffix, dye)
        return dyes[dye] and "" or suffix
    end)
    -- Brackets prevent the rotation builder from finding emoji substrings in names.
    local compact = key:gsub("[%s%p]", "")
    local token = GearAliasesPvME[fullKey] or GearAliasesPvME[compact]
        or aliases[key] or compactAliases[compact]
    return formatGear(token, name)
end

function ItemNames.Special(action, weapon, pvme)
    if pvme then return ItemNames.PvME(weapon) .. " " .. action end
    return action .. " (" .. ItemNames.Display(weapon) .. ")"
end

function ItemNames.Equipment(item)
    local token = AmmoMapPvME[item.id] or eofAliases[item.id] or necromancyAliases[item.id]
    if token then return formatGear(token, item.name) end
    return ItemNames.PvME(item.name)
end

return ItemNames
