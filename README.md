# Combat Recorder

A RuneScape plugin that records a sequence of abilities, equipment changes, and supported quiver ammunition switches, with an optional format for PvME Rotation Builder.

## Setup

Requires **PrettyUI** (dependency ID `6398181`). Load the `combat-recorder` directory as a development plugin with PrettyUI available. The plugin requests no additional permissions.

Recording is enabled by default. Settings and the combat log persist between sessions.

## Recording and copying a rotation

1. Open the plugin's ribbon panel and use **Enable Recording** to start or pause recording.
2. Choose **Use PvME Rotation Builder Syntax** before recording if you want that output format. It is off by default.
3. Perform the actions you want to capture. The ribbon panel displays the latest recorded action.
4. Open **Combat Recorder settings in Plugin Hub** to view the full log. Select the log field and use **Ctrl+A**, then **Ctrl+C** to copy it.
5. Use **Clear Log** to begin a fresh sequence.

Abilities are joined with ` -> `; equipment changes and ammunition switches use ` + `. Pausing preserves the existing log. Changing the output format affects new entries, so clear the log first if you want a sequence entirely in one format.

## Supported actions

- Abilities with a nonempty `COMBATV2_ABILITY_NAME` in their API struct. Normal output preserves the game's name and capitalization.
- Equipment changes, including equipping and unequipping items. The gear already worn when recording starts establishes a baseline and is not added to the log.
- Active-ammunition changes from Pernix and Tirannwn quivers for explicitly mapped T80+ arrows and bolts.
- Weapon special attacks annotated with the main-hand weapon equipped when used.
- Essence of Finality special attacks annotated using your configured stored-weapon mapping.

Ability names come from `config.Struct.FromID(abilityID):GetParamValue(config.Param.COMBATV2_ABILITY_NAME)`. Missing, empty, or unreadable names are skipped. PvME output keeps the bundled ID-based translations (including special attacks) and falls back to a lowercase name with spaces and punctuation removed. These generated ability tokens and unmapped equipment tokens may not have corresponding PvME icons.

Ammo uses explicit `id.Obj` entries in `ammomap.lua` and `ammomap_pvme.lua`, with no runtime lookup or generated tokens. Coverage includes standard completed T80+ quiver arrows and bolts: bane and tuned bane, stalker/wild/araxyte, elder rune/primal, black stone, dinarrows and their god variants, deathspore/splintering, royal/wyvern/Ascension/Ascendri/blight, onyx bolts (e), and plain, gem-tipped and enchanted bakriminel bolts. Below-T80 ammo, Daemonheim-only ammo, old poisoned variants, stack-display configs, and unfinished components are outside this map. Unknown ammo is skipped.

The PvME ammo map contains only canonical `id` values for matching `preset_slot: 9` entries in [PVME's emoji definitions](https://github.com/pvme/pvme-settings/blob/master/emojis/emojis_v2.json). Stack artwork, quivers, pouches and other non-ammo entries are excluded. Ammo without a matching PvME entry retains its normal name, including spaces, in quiver-switch logs. Equipment-change logs use a compact token when no explicit PvME alias exists.

Tier coverage reference: [arrows](https://runescape.wiki/w/Arrows), [bolts](https://runescape.wiki/w/Bolts), and [bane ammunition](https://runescape.wiki/w/Bane_ammunition).

## Essence of Finality configuration

In Plugin Hub settings, select an **EOF colour and style**, then its **Stored weapon**. Regular and ornamented amulets have separate mappings. You can choose a listed weapon or enter a custom weapon name; changes save immediately.

Use distinct colours or ornament styles for amulets containing different weapons. The settings selector follows the currently equipped EOF when it changes. The stored weapon must be configured manually; unconfigured EOF special attacks retain an amulet description in the log.
