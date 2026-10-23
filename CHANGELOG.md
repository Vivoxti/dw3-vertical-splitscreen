# Changelog

## 1.3.0
- New in-game settings menu: F8 picks the next setting and shows it on screen, `[` / `]` change it. It replaces the separate FOV hotkeys; the split mode is now the first menu item.
- Per-player scale (50–200%) for the own HP gauge, the strong enemy's gauge and the minimap block (minimap with the morale bar), in both split modes.
- Fixed a crash that could happen when pressing the hotkeys quickly: delayed actions now run on the game thread.

## 1.2.0
- F8 now switches the split itself, side by side ↔ top/bottom, at any time. The HUD follows.
- In top/bottom mode both players always use the game's default FOV.
- The split mode is remembered. Settings moved to `settings.txt`; an existing `fov.txt` is imported automatically.

## 1.1.0
- Per-player wider view (0–50%) with hotkeys, shown in that player's half and remembered between sessions.

## 1.0.0
- Side-by-side 2-player split screen.
- 2-player HUD moved into each player's half.
