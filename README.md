# Combat Recorder

Record abilities, equipment changes, and supported ammunition switches for copying or importing into PvME Rotation Builder.

Requires PrettyUI. Recording starts enabled, and settings and the combat log persist between sessions.

## Recording and copying

1. Open the ribbon panel and use **Enable Recording** to start or pause.
2. Enable **Use PvME Rotation Builder Syntax** if you want PvME output. It is off by default.
3. Perform the actions you want to record. The panel shows the latest action.
4. Click **Open Combat Log** for a movable, resizable window, or view the log in Plugin Hub settings.
5. Select the log field and press **Ctrl+A**, then **Ctrl+C** to copy it.
6. Use **Clear Log** in the ribbon panel or settings to begin a new recording.

The floating log updates live and stays open independently of the ribbon panel. Its position is saved for the next session.

Pausing keeps the existing log. Changing the output format affects new entries only. Clear the log first if you want the whole recording in one format.

## Recorded actions

- Abilities with available names.
- Equipment changes. Normal mode includes unequips. PvME mode records only equipped items.
- Supported T80+ ammunition switches from Pernix and Tirannwn quivers.
- Weapon special attacks with the equipped main-hand weapon.
- Essence of Finality special attacks with the stored weapon you configured.

Gear already worn when recording starts is not added to the log. Ammunition quantity changes are not recorded as equipment swaps.

Abilities are separated by ` -> `. Equipment changes and ammunition switches use ` + `.

PvME mode uses ` -> ` when an ability starts a new global cooldown and ` + ` when it does not.

## PvME output

Supported abilities and gear use PvME emoji names. Items without a usable emoji appear in brackets, such as `[Am-zi]`.

Some enhanced and imbued items use their base-item emojis. Enhanced fleeting, laceration, and blast diffusion boots use their base versions. T90 Deathdealer armour uses bracketed names, while T80 uses emojis. Death guard is treated as T90 when its name has no tier.

Regular and ornamented EOFs use separate emojis for each colour.

## Essence of Finality settings

Open Plugin Hub settings and select an **EOF colour and style**, then choose its **Stored weapon**. If the weapon is not listed, enter its name in the custom field.

Each colour and ornament style saves its own weapon choice. Use different variants for EOFs containing different weapons. The selector follows the EOF you have equipped.

Stored weapons must be configured manually. An unconfigured EOF special attack shows an explanatory note in the log.
