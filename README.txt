Vertical Split Screen - DYNASTY WARRIORS 3: Complete Edition Remastered
Version 1.3.0

ABOUT
Local 2-player co-op/versus splits the screen top/bottom by default, which wastes
space on wide and ultrawide monitors. This mod splits it side by side instead:
Player 1 on the left, Player 2 on the right. Each player's HUD (health, musou,
officer gauge, morale, minimap, K.O. counter) is moved into that player's half.
The split can be switched back to top/bottom at any time. In side-by-side mode
each player can widen their own field of view (FOV), and each player can scale
their own HP gauge, the strong enemy's gauge and the minimap block.

REQUIREMENTS
UE4SS for DYNASTY WARRIORS 3 Complete Edition Remastered (Nexus Mods, mod #7).

INSTALL
1. Install UE4SS first (dwmapi.dll and the ue4ss folder next to
   DW3CE_RE\Binaries\Win64\DW3CE_RE-Win64-Shipping.exe).
2. Extract this archive into DW3CE_RE\Binaries\Win64, so you end up with
   DW3CE_RE\Binaries\Win64\ue4ss\Mods\VerticalSplit\Scripts\main.lua
   DW3CE_RE\Binaries\Win64\ue4ss\Mods\VerticalSplit\enabled.txt
3. Start the game and begin a 2-player battle.

USAGE
F8     - next setting (its name and value are shown on screen)
[ / ]  - change the selected setting down / up

Settings, in F8 order:
Split                - side by side <-> top/bottom (the HUD follows)
FOV P1 / P2          - wider view +0..+50%, step 5% (side-by-side mode only)
HP gauge P1 / P2     - own HP gauge scale 50..200%, step 10%
Enemy gauge P1 / P2  - strong enemy's gauge scale 50..200%, step 10%
Minimap P1 / P2      - minimap block (with the morale bar) scale 50..200%

The view widening is applied on top of the game's own camera, so its zooms
still work; cutscene cameras are left untouched. In top/bottom mode both
players always get the game's default view. All settings are saved to
ue4ss\Mods\VerticalSplit\settings.txt.
Keys, steps and ranges are at the top of Scripts\main.lua.

UNINSTALL
Delete the ue4ss\Mods\VerticalSplit folder.

NOTES
- No game files are modified. The split orientation is set at runtime, so
  editing Engine.ini is not needed (the game deletes it on exit anyway).
- Tested on Steam build 25630985 with UE4SS v3.0.1-1152 (experimental).

