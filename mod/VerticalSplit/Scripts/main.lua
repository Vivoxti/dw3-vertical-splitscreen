-- Vertical Split Screen for DYNASTY WARRIORS 3: Complete Edition Remastered
-- Splits the 2-player screen side by side (P1 left, P2 right) and moves each player's HUD to their half.
-- Settings are changed in game: F8 picks the setting (shown on screen), [ and ] change it.
-- Settings: split side by side / top-bottom, and per player: wider view (side-by-side mode only),
-- own HP gauge, strong enemy's gauge and minimap block scale.
-- They are saved to settings.txt next to this mod. Requires UE4SS.

local MOD_NAME = "VerticalSplit"
local VERSION = "1.3.0"

local Config = {
    VerticalSplit = true,  -- default mode when settings.txt doesn't exist yet

    -- Controls: SelectKey moves to the next setting and shows it, Down/Up change it.
    SelectKey = Key.F8,
    DownKey = Key.OEM_FOUR, -- [
    UpKey = Key.OEM_SIX,    -- ]

    -- FOV widening in percent of the view size (camera overscan), side-by-side mode only.
    -- Applied on top of the game's own camera, so its zooms keep working. 0 = the game's default view.
    FovStep = 5,
    FovMin = 0,
    FovMax = 50,

    -- HUD scale in percent, per player, both split modes: own HP gauge, strong enemy's gauge, minimap block.
    GaugeScaleStep = 10,
    GaugeScaleMin = 50,
    GaugeScaleMax = 200,

    HintSeconds = 3,
}

---------------------------------------------------------------------------
-- helpers

local function log(fmt, ...)
    print(string.format("[%s] " .. fmt .. "\n", MOD_NAME, ...))
end

local function try(f, ...)
    local ok, r = pcall(f, ...)
    if ok then return r end
    return nil
end

local function prop(obj, name)
    return try(function() return obj[name] end)
end

local function valid(o)
    return o ~= nil and try(function() return o:IsValid() end) == true
end

local function nameOf(o) return try(function() return o:GetFName():ToString() end) or "?" end
local function classOf(o) return try(function() return o:GetClass():GetFName():ToString() end) or "?" end
local function fullName(o) return try(function() return o:GetFullName() end) or "?" end

local ClassCache = {}
local function isA(o, path)
    local c = ClassCache[path]
    if not valid(c) then
        c = StaticFindObject(path)
        ClassCache[path] = c
    end
    return valid(c) and try(function() return o:IsA(c) end) == true
end

local function guarded(fn)
    return function()
        local ok, err = pcall(fn)
        if not ok then log("error: %s", tostring(err)) end
    end
end

local function inGameThread(fn)
    ExecuteInGameThread(guarded(fn))
end

-- Runs fn on the game thread after ms. Not ExecuteWithDelay: that calls back into Lua from its own
-- thread while the game thread runs our per-frame loop, which can corrupt the Lua state and crash.
local function delayed(ms, fn)
    ExecuteInGameThreadWithDelay(ms, guarded(fn))
end

local ModDir = (function()
    local src = debug.getinfo(1, "S").source:gsub("^@", "")
    return src:match("^(.*)[/\\]Scripts[/\\][^/\\]*$") or "."
end)()

---------------------------------------------------------------------------
-- settings file: split mode + per-player FOV and gauge scale

local FovOffset = { 0, 0 }
local GaugeOrder = { "Hp", "Enemy", "Map" }
local GaugeLabel = { Hp = "HP gauge", Enemy = "Enemy gauge", Map = "Minimap" }
local GaugeScale = { Hp = { 100, 100 }, Enemy = { 100, 100 }, Map = { 100, 100 } }
local SettingsFile = ModDir .. "/settings.txt"
local LegacyFovFile = ModDir .. "/fov.txt" -- v1.1.0

local function LoadSettings()
    local f = io.open(SettingsFile, "r") or io.open(LegacyFovFile, "r")
    if not f then return end
    for line in f:lines() do
        local key, v = line:match("^%s*(%w+)%s*=%s*(-?%d+%.?%d*)")
        v = tonumber(v)
        if key == "Vertical" and v then
            Config.VerticalSplit = v ~= 0
        elseif key and v then
            local i = tonumber(key:match("^P(%d)$"))
            if i and FovOffset[i] then FovOffset[i] = math.max(Config.FovMin, math.min(Config.FovMax, v)) end
            local kind, p = key:match("^(%a+)ScaleP(%d)$")
            local scale = GaugeScale[kind]
            p = tonumber(p)
            if scale and scale[p] then scale[p] = math.max(Config.GaugeScaleMin, math.min(Config.GaugeScaleMax, v)) end
        end
    end
    f:close()
    log("settings: %s split, FOV P1 +%g%%, P2 +%g%%, HP gauge P1 %g%%, P2 %g%%, enemy gauge P1 %g%%, P2 %g%%, "
        .. "minimap P1 %g%%, P2 %g%%", Config.VerticalSplit and "vertical" or "horizontal", FovOffset[1], FovOffset[2],
        GaugeScale.Hp[1], GaugeScale.Hp[2], GaugeScale.Enemy[1], GaugeScale.Enemy[2], GaugeScale.Map[1], GaugeScale.Map[2])
end

local function SaveSettings()
    local f = io.open(SettingsFile, "w")
    if not f then
        log("cannot write %s", SettingsFile)
        return
    end
    f:write(string.format("Vertical=%d\nP1=%g\nP2=%g\n", Config.VerticalSplit and 1 or 0, FovOffset[1], FovOffset[2]))
    for _, kind in ipairs(GaugeOrder) do
        for i, s in ipairs(GaugeScale[kind]) do f:write(string.format("%sScaleP%d=%g\n", kind, i, s)) end
    end
    f:close()
end

---------------------------------------------------------------------------
-- splitscreen orientation

local function ApplySplitLayout()
    local settings = StaticFindObject("/Script/EngineSettings.Default__GameMapsSettings")
    if not valid(settings) then
        log("GameMapsSettings not found, split orientation unchanged")
        return
    end
    -- ETwoPlayerSplitScreenType: 0 = Horizontal (top/bottom), 1 = Vertical (side by side)
    settings.TwoPlayerSplitscreenLayout = Config.VerticalSplit and 1 or 0

    -- the engine only reads the setting when it lays out the player viewports; toggling the
    -- splitscreen override makes it re-layout right now (skipped if the game itself disabled splitscreen)
    local gvc = FindFirstOf("GameViewportClient")
    if valid(gvc) and try(function() return gvc:IsSplitscreenForceDisabled() end) == false then
        gvc:SetForceDisableSplitscreen(true)
        gvc:SetForceDisableSplitscreen(false)
    end
    log("2P split: %s", Config.VerticalSplit and "vertical" or "horizontal")
end

---------------------------------------------------------------------------
-- HUD relayout

-- visit(widget, ctx) for every widget below root, descending into child UserWidgets;
-- visit returns false to skip the widget's children, or a new ctx for them
local function walk(w, visit, ctx)
    if not valid(w) then return end
    local r = visit(w, ctx)
    if r == false then return end
    ctx = r or ctx
    if isA(w, "/Script/UMG.UserWidget") then
        local tree = prop(w, "WidgetTree")
        if valid(tree) then walk(prop(tree, "RootWidget"), visit, ctx) end
    elseif isA(w, "/Script/UMG.PanelWidget") then
        local slots = prop(w, "Slots")
        if slots then
            slots:ForEach(function(_, e)
                local s = e:get()
                if valid(s) then walk(prop(s, "Content"), visit, ctx) end
            end)
        end
    end
end

local LEFT = { Minimum = { X = 0.0, Y = 0.0 }, Maximum = { X = 0.5, Y = 1.0 } }
local RIGHT = { Minimum = { X = 0.5, Y = 0.0 }, Maximum = { X = 1.0, Y = 1.0 } }

-- widgets inside BP_2d_hud_multi -> half of the screen they belong to (P1 = left, P2 = right)
local HalfTargets = {
    BP_parts_2d_hud_split_screen_up = LEFT,
    BP_parts_2d_hud_split_screen_down = RIGHT,
    BP_parts_count_1000ko_direction_up = LEFT,
    BP_parts_count_1000ko_direction_down = RIGHT,
}

local Saved = {} -- slot full name -> original (top/bottom) layout

local function saveSlot(slot)
    local key = fullName(slot)
    if Saved[key] then return end
    local ld = slot.LayoutData
    Saved[key] = {
        Anchors = { Minimum = { X = ld.Anchors.Minimum.X, Y = ld.Anchors.Minimum.Y }, Maximum = { X = ld.Anchors.Maximum.X, Y = ld.Anchors.Maximum.Y } },
        Offsets = { Left = ld.Offsets.Left, Top = ld.Offsets.Top, Right = ld.Offsets.Right, Bottom = ld.Offsets.Bottom },
        Alignment = { X = ld.Alignment.X, Y = ld.Alignment.Y },
        AutoSize = slot.bAutoSize,
    }
end

local function setCanvasLayout(slot, l)
    slot:SetAutoSize(l.AutoSize or false)
    slot:SetAnchors(l.Anchors)
    slot:SetOffsets(l.Offsets)
    slot:SetAlignment(l.Alignment)
end

local function RelayoutMultiHud(hud, sideBySide)
    local tree = prop(hud, "WidgetTree")
    if not valid(tree) then return end
    local done = 0
    walk(prop(tree, "RootWidget"), function(w)
        local target = HalfTargets[nameOf(w)]
        local slot = prop(w, "Slot")
        if target and valid(slot) and classOf(slot) == "CanvasPanelSlot" then
            saveSlot(slot)
            if sideBySide then
                setCanvasLayout(slot, { Anchors = target, Offsets = { Left = 0, Top = 0, Right = 0, Bottom = 0 }, Alignment = { X = 0, Y = 0 }, AutoSize = false })
            else
                setCanvasLayout(slot, Saved[fullName(slot)])
            end
            done = done + 1
        end
    end)
    log("2P HUD %s (%d widgets)", sideBySide and "side by side" or "original", done)
end

local function RelayoutAll()
    for _, hud in ipairs(FindAllOf("BP_2d_hud_multi_C") or {}) do
        RelayoutMultiHud(hud, Config.VerticalSplit)
    end
end

---------------------------------------------------------------------------
-- per-player gauge scale (own HP gauge, strong enemy's gauge, minimap block)

local PartPlayer = { BP_parts_2d_hud_split_screen_up = 1, BP_parts_2d_hud_split_screen_down = 2 }

-- gauge widget class -> setting it follows + pivot (the corner it grows from)
local TOP_LEFT, BOTTOM_LEFT = { X = 0, Y = 0 }, { X = 0, Y = 1 }
local TOP_RIGHT, BOTTOM_RIGHT = { X = 1, Y = 0 }, { X = 1, Y = 1 }
local GaugeClasses = {
    bp_parts_gauge_pc_multi_C = { kind = "Hp", pivot = BOTTOM_LEFT },
    bp_parts_gauge_pc_C = { kind = "Hp", pivot = BOTTOM_LEFT },
    BP_parts_gauge_enemy_multi_C = { kind = "Enemy", pivot = TOP_LEFT },
    BP_parts_gauge_enemy_C = { kind = "Enemy", pivot = TOP_LEFT },
    BP_parts_minimap_C = { kind = "Map", pivot = TOP_RIGHT },
    -- morale bar right above the minimap: grows up from the same edge, so the two stay together
    BP_parts_gauge_moral_C = { kind = "Map", pivot = BOTTOM_RIGHT },
}
local Gauges = {} -- { w = gauge widget, kind, pivot, i = player index }

-- list of { w, kind, pivot, i }; gauges nested inside another gauge are left to their parent
local function findGauges(hud)
    local found, loose = {}, {} -- class -> player index -> widget / class -> widgets outside the player parts
    walk(prop(prop(hud, "WidgetTree"), "RootWidget"), function(w, player)
        local p = PartPlayer[nameOf(w)]
        if p then return p end
        local cls = classOf(w)
        if not GaugeClasses[cls] then return end
        if player then
            found[cls] = found[cls] or {}
            found[cls][player] = found[cls][player] or w
        else
            loose[cls] = loose[cls] or {}
            table.insert(loose[cls], w)
        end
        return false -- don't look inside a gauge
    end)
    local list = {}
    for cls, info in pairs(GaugeClasses) do
        for i, w in pairs(found[cls] or loose[cls] or {}) do -- fallback: tree order = player order
            list[#list + 1] = { w = w, kind = info.kind, pivot = info.pivot, i = i }
        end
    end
    return list
end

local function setGaugeScale(g)
    local s = GaugeScale[g.kind][g.i] / 100
    g.w:SetRenderTransformPivot(g.pivot)
    g.w:SetRenderScale({ X = s, Y = s })
end

local function ApplyGaugeScaleAll(quiet)
    local before = #Gauges
    Gauges = {}
    for _, hud in ipairs(FindAllOf("BP_2d_hud_multi_C") or {}) do
        for _, g in ipairs(findGauges(hud)) do
            if GaugeScale[g.kind][g.i] then
                setGaugeScale(g)
                Gauges[#Gauges + 1] = g
            end
        end
    end
    if not quiet or #Gauges ~= before then
        log("HP gauge P1 %g%%, P2 %g%%, enemy gauge P1 %g%%, P2 %g%%, minimap P1 %g%%, P2 %g%% (%d widgets)",
            GaugeScale.Hp[1], GaugeScale.Hp[2], GaugeScale.Enemy[1], GaugeScale.Enemy[2],
            GaugeScale.Map[1], GaugeScale.Map[2], #Gauges)
    end
end

-- After a setting change: rescale the gauges found earlier, search the HUD again only if one is gone.
local function RescaleGauges()
    local missing = #Gauges == 0
    for _, g in ipairs(Gauges) do
        if valid(g.w) then setGaugeScale(g) else missing = true end
    end
    if missing then ApplyGaugeScaleAll() end
end

-- Once a second: put the scale back if the game reset a gauge's render transform.
-- Every 5 s: look for gauges again if a scaled one is missing (e.g. the HUD was rebuilt).
local KeepTick = 0
local function KeepGaugeScale()
    KeepTick = KeepTick + 1
    local have = {}
    for _, g in ipairs(Gauges) do
        if valid(g.w) then
            have[g.kind .. g.i] = true
            local x = try(function() return g.w.RenderTransform.Scale.X end)
            if x and math.abs(x - GaugeScale[g.kind][g.i] / 100) > 0.001 then setGaugeScale(g) end
        end
    end
    if KeepTick % 5 ~= 0 then return end
    for kind, scale in pairs(GaugeScale) do
        for i, s in ipairs(scale) do
            if s ~= 100 and not have[kind .. i] then
                ApplyGaugeScaleAll(true)
                return
            end
        end
    end
end


---------------------------------------------------------------------------
-- per-player FOV

local GameEngine
local function localPlayerCameras()
    if not valid(GameEngine) then GameEngine = FindFirstOf("GameEngine") end
    local gi = valid(GameEngine) and prop(GameEngine, "GameInstance")
    local lps = valid(gi) and prop(gi, "LocalPlayers")
    local cams = {}
    if lps then
        local n = 0 -- own counter: player order = LocalPlayers order (P1 first)
        lps:ForEach(function(_, e)
            n = n + 1
            local lp = e:get()
            local pc = valid(lp) and prop(lp, "PlayerController")
            local pcm = valid(pc) and prop(pc, "PlayerCameraManager")
            if valid(pcm) then cams[n] = pcm end
        end)
    end
    return cams
end

-- The game animates CameraComponent.FieldOfView itself (it interpolates from the current value),
-- so writing to it fights the game. Instead we use the camera's Overscan, which widens the view
-- frustum by a fraction on top of the FOV and is never touched by the game. Only player pawns'
-- cameras are changed; cutscene cameras keep their authored framing.
local Cams = {} -- player index -> { vt = view target address, cam = CameraComponent, orig, applied }

local function findViewCamera(vt)
    local best
    for _, c in ipairs(FindAllOf("CameraComponent") or {}) do
        local owner = try(function() return c:GetOwner() end)
        if valid(owner) and owner:GetAddress() == vt:GetAddress() then
            if try(function() return c:IsActive() end) then return c end
            best = best or c
        end
    end
    return best
end

local function cameraFor(i, pcm)
    local vt = try(function() return pcm.ViewTarget.Target end)
    if not valid(vt) then return nil end
    local vtAddr = vt:GetAddress()
    local e = Cams[i]
    if e and e.vt == vtAddr then
        if valid(e.cam) then return e end
        -- no camera found for this view target: retry only every ~5 s, FindAllOf is not free
        e.retry = (e.retry or 0) + 1
        if e.retry < 300 then return nil end
    end
    -- switching view target: give the previous camera its original overscan back
    if e and valid(e.cam) and e.applied then try(function() e.cam.Overscan = e.orig end) end
    local cam = isA(vt, "/Script/Engine.Pawn") and findViewCamera(vt) or nil
    e = { vt = vtAddr, cam = cam, orig = valid(cam) and prop(cam, "Overscan") or 0 }
    Cams[i] = e
    return valid(cam) and e or nil
end

local function wantedFov(i)
    return Config.VerticalSplit and (FovOffset[i] or 0) or 0
end

local function overscanApplied(i)
    return Cams[i] and Cams[i].applied and Cams[i].applied ~= 0
end

local Frame = 0
local function ApplyFov()
    Frame = Frame + 1
    if wantedFov(1) == 0 and wantedFov(2) == 0 and not overscanApplied(1) and not overscanApplied(2) then
        return
    end
    for i, pcm in pairs(localPlayerCameras()) do
        local e = cameraFor(i, pcm)
        if e then
            local want = wantedFov(i) / 100
            -- write only when the wanted value changes; re-check once a second in case something resets it
            if e.applied ~= want or Frame % 60 == 0 then
                if prop(e.cam, "Overscan") ~= want then
                    e.cam.Overscan = want
                    try(function() e.cam.bCropOverscan = false end)
                    try(function() e.cam.bScaleResolutionWithOverscan = false end)
                end
                if e.applied ~= want then
                    log("P%d FOV +%g%% (%s)", i, wantedFov(i), fullName(e.cam))
                end
                e.applied = want
            end
        end
    end
end

---------------------------------------------------------------------------
-- on-screen hint inside the 2P HUD (one text per player, placed in that player's view)

local Hints = {}    -- player index -> { hud, text, slot }
local HintGen = { 0, 0 }
local VIS_COLLAPSED, VIS_HIT_TEST_INVISIBLE = 1, 3

local function findHudFont(hud)
    local font
    walk(prop(prop(hud, "WidgetTree"), "RootWidget"), function(w)
        if not font and classOf(w) == "TextBlock" then font = prop(w, "Font") end
    end)
    return font
end

local function hintAnchor(i)
    if Config.VerticalSplit then
        return (i == 1) and 0.25 or 0.75, 0.08 -- top center of the left/right half
    end
    return 0.5, (i == 1) and 0.06 or 0.56     -- top center of the upper/lower half
end

local function hintText(i)
    local hud = FindFirstOf("BP_2d_hud_multi_C")
    if not valid(hud) then return nil end
    local h = Hints[i]
    if not (h and h.hud == fullName(hud) and valid(h.text)) then
        local tree = prop(hud, "WidgetTree")
        local root = valid(tree) and prop(tree, "RootWidget")
        if not valid(root) or not isA(root, "/Script/UMG.CanvasPanel") then return nil end
        local text = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), tree)
        if not valid(text) then return nil end
        local font = findHudFont(hud)
        if font then try(function() text:SetFont(font) end) end
        try(function() text:SetShadowOffset({ X = 2, Y = 2 }) end)
        try(function() text:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.85 }) end)
        local slot = root:AddChildToCanvas(text)
        slot:SetAlignment({ X = 0.5, Y = 0.5 })
        slot:SetOffsets({ Left = 0, Top = 0, Right = 0, Bottom = 0 })
        slot:SetAutoSize(true)
        slot:SetZOrder(100)
        text:SetVisibility(VIS_COLLAPSED)
        h = { hud = fullName(hud), text = text, slot = slot }
        Hints[i] = h
    end
    local x, y = hintAnchor(i)
    h.slot:SetAnchors({ Minimum = { X = x, Y = y }, Maximum = { X = x, Y = y } })
    return h.text
end

local function ShowHint(i, msg)
    local text = hintText(i)
    if not text then return end
    text:SetText(FText(msg))
    text:SetVisibility(VIS_HIT_TEST_INVISIBLE)
    HintGen[i] = HintGen[i] + 1
    local gen = HintGen[i]
    delayed(Config.HintSeconds * 1000, function()
        if HintGen[i] == gen and valid(text) then text:SetVisibility(VIS_COLLAPSED) end
    end)
end

---------------------------------------------------------------------------
-- settings menu: F8 picks a setting, [ / ] change it

local function ToggleSplit()
    Config.VerticalSplit = not Config.VerticalSplit
    SaveSettings()
    ApplySplitLayout()
    RelayoutAll()
    -- FOV follows automatically: ApplyFov drops the widening in horizontal mode
end

local function ChangeFov(i, dir)
    FovOffset[i] = math.max(Config.FovMin, math.min(Config.FovMax, FovOffset[i] + dir * Config.FovStep))
    SaveSettings()
end

local function ChangeGaugeScale(kind, i, dir)
    local scale = GaugeScale[kind]
    scale[i] = math.max(Config.GaugeScaleMin, math.min(Config.GaugeScaleMax, scale[i] + dir * Config.GaugeScaleStep))
    SaveSettings()
    RescaleGauges()
end

-- player = whose half shows the hint (nil = both); sideBySideOnly = skipped in top/bottom mode
local Settings = {
    {
        label = "Split",
        value = function() return Config.VerticalSplit and "side by side" or "top / bottom" end,
        change = function() ToggleSplit() end,
    },
}
for i = 1, 2 do
    table.insert(Settings, {
        player = i, sideBySideOnly = true, label = string.format("FOV P%d", i),
        value = function() return string.format("+%g%%", FovOffset[i]) end,
        change = function(dir) ChangeFov(i, dir) end,
    })
    for _, kind in ipairs(GaugeOrder) do
        table.insert(Settings, {
            player = i, label = string.format("%s P%d", GaugeLabel[kind], i),
            value = function() return string.format("%g%%", GaugeScale[kind][i]) end,
            change = function(dir) ChangeGaugeScale(kind, i, dir) end,
        })
    end
end

local Selected = 1

local function available(s)
    return not (s.sideBySideOnly and not Config.VerticalSplit)
end

local function ShowSetting()
    local s = Settings[Selected]
    local msg = string.format("%s: %s    [ / ] change, F8 next", s.label, s.value())
    if s.player then
        ShowHint(s.player, msg)
    else
        ShowHint(1, msg)
        ShowHint(2, msg)
    end
end

local function SelectNext()
    repeat
        Selected = Selected % #Settings + 1
    until available(Settings[Selected])
    ShowSetting()
end

local function ChangeSelected(dir)
    if not available(Settings[Selected]) then Selected = 1 end
    Settings[Selected].change(dir)
    ShowSetting()
end

---------------------------------------------------------------------------
-- hooks

NotifyOnNewObject("/Script/UMG.UserWidget", function(obj)
    if classOf(obj) == "BP_2d_hud_multi_C" then
        delayed(500, function()
            if not valid(obj) then return end
            if Config.VerticalSplit then RelayoutMultiHud(obj, true) end
            ApplyGaugeScaleAll()
        end)
    end
end)

-- The 2P HUD lives on the GameInstance and may be reused between battles;
-- re-apply after every map load in case the game resets its slots.
local RestartPending = false
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    if RestartPending then return end
    RestartPending = true
    delayed(1500, function()
        RestartPending = false
        if Config.VerticalSplit then RelayoutAll() end
        ApplyGaugeScaleAll()
    end)
end)

RegisterKeyBind(Config.SelectKey, function() inGameThread(SelectNext) end)
RegisterKeyBind(Config.DownKey, function() inGameThread(function() ChangeSelected(-1) end) end)
RegisterKeyBind(Config.UpKey, function() inGameThread(function() ChangeSelected(1) end) end)

local FovErrorLogged, GaugeErrorLogged = false, false
LoopInGameThreadAfterFrames(1, function()
    local ok, err = pcall(ApplyFov)
    if not ok and not FovErrorLogged then
        FovErrorLogged = true
        log("FOV error: %s", tostring(err))
    end
    if Frame % 60 == 30 then
        ok, err = pcall(KeepGaugeScale)
        if not ok and not GaugeErrorLogged then
            GaugeErrorLogged = true
            log("gauge scale error: %s", tostring(err))
        end
    end
    return false
end)

LoadSettings()
inGameThread(ApplySplitLayout)
log("v%s loaded", VERSION)
