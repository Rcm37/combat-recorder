local Settings = require("settings")
local EOF = { Variants = require("eof_variants") }

-- Preset choices; other weapons can be entered by name.
EOF.Weapons = {
    "Armadyl battlestaff", "Armadyl godsword", "Bandos godsword", "Dark bow",
    "Death guard", "Decimation", "Dragon 2h sword", "Dragon battleaxe", "Dragon claws",
    "Dragon dagger", "Dragon halberd", "Dragon longsword", "Dragon mace",
    "Dragon scimitar", "Dragon spear", "Eldritch crossbow",
    "Gloomfire bow", "Granite maul", "Guthix staff", "Iban's staff", "Legatus's Emberstaff", "Saradomin godsword",
    "Seren godbow", "Staff of light", "Statius's warhammer", "Varanus's Mercy", "Vesta's longsword",
    "Zamorak godsword", "Zamorak staff",
}

local variantsByID = {}
for _, variant in ipairs(EOF.Variants) do
    for _, itemID in ipairs(variant.ids) do variantsByID[itemID] = variant end
end

function EOF.GetVariant(itemID)
    return variantsByID[itemID]
end

function EOF.SetWeapon(variant, name)
    Settings.update("eof_weapon_" .. variant.key, name:match("^%s*(.-)%s*$"))
end

function EOF.GetWeapon(variant)
    return Settings.get("eof_weapon_" .. variant.key)
end

function EOF.Describe(itemID)
    local variant = EOF.GetVariant(itemID)
    if not variant then return "unknown EOF" end
    local weapon = EOF.GetWeapon(variant)
    if weapon == "" then return "not configured: " .. variant.label end
    return weapon
end

return EOF
