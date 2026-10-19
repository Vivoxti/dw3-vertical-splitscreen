Vertical Split Screen - DYNASTY WARRIORS 3: Complete Edition Remastered
Version 1.1.0

ABOUT
Local 2-player co-op/versus splits the screen top/bottom by default, which wastes
space on wide and ultrawide monitors. This mod splits it side by side instead:
Player 1 on the left, Player 2 on the right. Each player's HUD (health, musou,
officer gauge, morale, minimap, K.O. counter) is moved into that player's half.
Each player can also widen their own field of view (FOV).

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
[ / ]  - Player 1 (left) wider view -5% / +5%
; / '  - Player 2 (right) wider view -5% / +5%
F8     - toggle the HUD between side-by-side and the original top/bottom layout
The view widening (0..+50%) is applied on top of the game's own camera, so its
zooms still work; cutscene cameras are left untouched. The value is shown
briefly in that player's half and saved to ue4ss\Mods\VerticalSplit\fov.txt.
Keys, step and range are at the top of Scripts\main.lua.

UNINSTALL
Delete the ue4ss\Mods\VerticalSplit folder.

NOTES
- No game files are modified. The split orientation is set at runtime, so
  editing Engine.ini is not needed (the game deletes it on exit anyway).
- Tested on Steam build 25630985 with UE4SS v3.0.1-1152 (experimental).

---------------------------------------------------------------------------
RU: Вертикальный сплитскрин

Мод делит экран для двух игроков не сверху/снизу, а слева/справа
(игрок 1 слева, игрок 2 справа) и переносит HUD каждого игрока в его половину.

Нужен UE4SS (мод №7 на Nexus). Распакуйте архив в DW3CE_RE\Binaries\Win64 —
должна получиться папка ue4ss\Mods\VerticalSplit. F8 переключает раскладку HUD.
FOV: [ и ] — игрок 1 (слева), ; и ' — игрок 2 (справа), шаг 5%, от 0 до +50%.
Значения сохраняются в ue4ss\Mods\VerticalSplit\fov.txt.
Удаление: удалить папку ue4ss\Mods\VerticalSplit.
