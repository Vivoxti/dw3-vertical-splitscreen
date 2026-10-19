# Заливка на Nexus Mods

Страница игры: https://www.nexusmods.com/dynastywarriors3completeeditionremastered → **Upload mod**.

## Поля
| Поле | Значение |
|---|---|
| Mod name | Vertical Split Screen |
| Version | 1.2.0 |
| Category | Gameplay (или User Interface, если есть) |
| Author | Vivoxti |
| Brief overview | текст из `summary.txt` |
| Detailed description | содержимое `description.bbcode` (вставлять в BBCode-режиме) |
| Requirements → Nexus mods | UE4SS for Dynasty Warriors 3 Complete Edition Remastered (mod #7) |
| Permissions | по желанию; исходники и так открыты на GitHub под MIT |

## Файл
- Main file: `dist/VerticalSplit-1.2.0.zip`, version 1.2.0. Пересобрать: `.\package.ps1`.
- Внутри архива пути от `Binaries\Win64` (`ue4ss/Mods/VerticalSplit/...`): так ставят и вручную, и через Vortex.

## Скриншоты (нужно снять заново, старые — с горизонтальным HUD)
1. Главный: бой на двоих, вертикальный сплит, оба HUD на своих половинах.
2. Тот же момент в горизонтальном режиме (после F8) — для сравнения.
3. Подсказка «FOV P1: +15%» и разница обзора между половинами.
4. Желательно на 21:9: это главная аудитория мода.

Скриншоты Steam (F12) лежат в `C:\Program Files (x86)\Steam\userdata\110301670\760\remote\3841510\screenshots`.

## После публикации
- Вставить ссылку на страницу Nexus в `README.md` (раздел Installation/Requirements) и в описание GitHub-репозитория.
- При обновлении: поднять `VERSION` в `main.lua`, дописать `CHANGELOG.md`, `.\package.ps1`, новый релиз на GitHub, новый файл на Nexus.
