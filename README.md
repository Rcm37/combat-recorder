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

- Abilities present in the plugin's ability maps.
- Equipment changes, including equipping and unequipping items. The gear already worn when recording starts establishes a baseline and is not added to the log.
- Supported active-ammunition changes from Pernix and Tirannwn quivers.
- Weapon special attacks annotated with the main-hand weapon equipped when used.
- Essence of Finality special attacks annotated using your configured stored-weapon mapping.

Ability and ammunition coverage depends on the bundled maps. PvME output uses known aliases where available; other equipment names become compact tokens that may not have corresponding PvME icons.

## Essence of Finality configuration

In Plugin Hub settings, select an **EOF colour and style**, then its **Stored weapon**. Regular and ornamented amulets have separate mappings. You can choose a listed weapon or enter a custom weapon name; changes save immediately.

Use distinct colours or ornament styles for amulets containing different weapons. The settings selector follows the currently equipped EOF when it changes. The stored weapon must be configured manually; unconfigured EOF special attacks retain an amulet description in the log.
