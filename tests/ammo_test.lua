-- Run from combat-recorder: lua tests/ammo_test.lua
id = {}
dofile("../runescape-api-stubs/consts/Obj.lua")
local fixtures = {
    {id.Obj.BANE_ARROW, "bane arrows", nil},
    {id.Obj.MAH5_DRAGONBANE_ARROW, "dragonbane arrows", "dbanearrows"},
    {id.Obj.SNIPER_BOLTS_DI_E, "diamond bakriminel bolts (e)", "diamond"},
    {id.Obj.SNIPER_BOLTS_DR_E, "dragonstone bakriminel bolts (e)", "dragonstonebakri"},
    {id.Obj.DINARROW_JAS_DEMONBANE, "jas demonbane arrows", "jasdemonbanearrow"},
    {id.Obj.PRIMAL_ARROW, "primal arrows", nil},
    {id.Obj.ELDER_ARROW, "elder rune arrows", nil},
    {id.Obj.QBD2_BOLTS, "royal bolts", nil},
    {id.Obj.HLM_WYVERN_BOLT, "wyvern spines", nil},
    {id.Obj.ASC_CRYSTAL_BOLT, "ascension bolts", "ascbolts"},
    {id.Obj.NATURE_BOSS_BOLT, "blight bolts", "blightbolt"},
    {id.Obj.ENCHANTED_BSLAY_HYDRIX_BOLT, "ascendri bolts (e)", "ascendri"},
    {id.Obj.DINARROW_WEN, "wen arrows", "wenarrows"},
    {id.Obj.DINARROW_BIK, "bik arrows", "bikarrows"},
}
config = {Obj={FromID=function() error("Ammo maps must not look up item names") end}}
local normal, pvme = require("ammomap"), require("ammomap_pvme")
for _, fixture in ipairs(fixtures) do
    assert(normal[fixture[1]] == fixture[2])
    assert(pvme[fixture[1]] == fixture[3])
end
assert(normal[id.Obj.SNIPER_BOLTS_RU_E] == "ruby bakriminel bolts (e)")
assert(pvme[id.Obj.SNIPER_BOLTS_RU_E] == "rubybakri")
assert(normal[-1] == nil and normal[0] == nil and normal[1.5] == nil)
assert(normal["invalid"] == nil and normal[id.Obj.MONKFISH] == nil)
assert(normal[id.Obj.BRONZE_ARROW] == nil and pvme[id.Obj.BRONZE_ARROW] == nil, "Below-T80 ammo is outside this map")
assert(getmetatable(normal) == nil and getmetatable(pvme) == nil, "Ammo maps are explicit tables")
local count = 0
for itemID in pairs(normal) do
    count = count + 1
end
local pvmeCount = 0
for itemID, token in pairs(pvme) do
    pvmeCount = pvmeCount + 1
    assert(normal[itemID] and token:match("^[a-z0-9]+$"), "PvME entries are a valid subset of normal ammo")
end
assert(pvmeCount == 20, "Only the matching preset-slot-9 ammo types have tokens")
assert(count == 56, "Expected 19 arrows and 37 bolts")
local ItemNames = require("item_names")
assert(ItemNames.Equipment({id=id.Obj.QBD2_BOLTS, name="Royal bolts"}) == "royalbolts",
    "Equipment without a PvME ammo icon uses a compact token")
assert(ItemNames.Equipment({id=id.Obj.ASC_CRYSTAL_BOLT, name="Ascension bolts"}) == "ascbolts")
assert(ItemNames.Equipment({id=id.Obj.ENCHANTED_ALCHEMICAL_HYDRIX_AMULET,
    name="Essence of finality amulet"}) == "eof", "EOF equipment aliases preserved")
assert(ItemNames.Equipment({id=id.Obj.FRACTURED_STAFF_OF_ARMADYL,
    name="Fractured staff of Armadyl"}) == "fsoa", "Weapon aliases preserved")
print("Ammo maps: 56 normal entries, 20 preset-slot-9 tokens, normal-name fallback and equipment aliases passed")
