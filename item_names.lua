local ItemNames = {}
local AmmoMapPvME = require("ammomap_pvme")
local EOFVariants = require("eof_variants")

local eofAliases = {}
for _, variant in ipairs(EOFVariants) do
    local style, colour = variant.key:match("^(.-)_(.+)$")
    local alias
    if colour == "default" then
        alias = style == "regular" and "eof" or "eofor"
    else
        alias = "eof" .. colour .. (style == "regular" and "u" or "")
    end
    for _, itemID in ipairs(variant.ids) do eofAliases[itemID] = alias end
end

local aliases = {
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
    ["robe top of the first necromancer"] = "firstnecrorobetop",
    ["vestments of havoc robe top"] = "vestmentsofhavoctop",
    ["vestments of havoc robe bottom"] = "vestmentsofhavocbottom",
    ["dracolich hauberk"] = "dracolichbody",
    ["elite dracolich hauberk"] = "edracobody",
    ["cinderbane gloves"] = "cinderbanes",
    ["blast diffusion boots"] = "blastdiffusion",
    ["amulet of souls"] = "aos",
    ["luck of the dwarves"] = "lotd",
    ["grace of the elves"] = "gote",
    ["erethdor's grimoire"] = "grim",
}
local dyes = {
    barrows = true, shadow = true, blood = true, ice = true,
    ["third age"] = true, ["3rd age"] = true, aurora = true, soul = true,
}

function ItemNames.Display(name)
    return (name:gsub("^[Aa][Uu][Gg][Mm][Ee][Nn][Tt][Ee][Dd]%s+", ""))
end

function ItemNames.PvME(name)
    local key = ItemNames.Display(name):lower():match("^%s*(.-)%s*$")
    key = key:gsub("%s*(%(([^()]*)%))$", function(suffix, dye)
        return dyes[dye] and "" or suffix
    end)
    -- Unmapped names become compact tokens, which may not have a PvME icon.
    return aliases[key] or (key:gsub("[%s%p]", ""))
end

function ItemNames.Special(action, weapon, pvme)
    if pvme then return ItemNames.PvME(weapon) .. " " .. action end
    return action .. " (" .. ItemNames.Display(weapon) .. ")"
end

function ItemNames.Equipment(item)
    return AmmoMapPvME[item.id] or eofAliases[item.id] or ItemNames.PvME(item.name)
end

return ItemNames
