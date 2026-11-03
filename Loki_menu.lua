-- language: Lua, file: loki_v19_1.lua, target: Universal
local LOKI_VERSION = "v19.1"
print("[LOKI " .. LOKI_VERSION .. "] start")

local ok, err = pcall(function()
    local Players      = game:GetService("Players")
    local RunService   = game:GetService("RunService")
    local UIS          = game:GetService("UserInputService")
    local Workspace    = game:GetService("Workspace")
    local TweenService = game:GetService("TweenService")
    local Lighting     = game:GetService("Lighting")
    local TS           = game:GetService("TeleportService")
    local SoundService = game:GetService("SoundService")

    local mousemoverel = rawget(getfenv(0), "mousemoverel") or rawget(_G, "mousemoverel")
    local CoreGui = gethui and select(2, pcall(gethui)) or game:GetService("CoreGui")
    if not CoreGui then CoreGui = Players.LocalPlayer:WaitForChild("PlayerGui") end

    local LP = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local intro_active = true

    local old = CoreGui:FindFirstChild("Menu_Loki")
    if old then old:Destroy() end
    local old_f = Workspace:FindFirstChild("__LOKI_ESP")
    if old_f then old_f:Destroy() end
    
    local esp_folder = Instance.new("Folder")
    esp_folder.Name = "__LOKI_ESP"; esp_folder.Parent = Workspace

    local C = {
        bg = Color3.fromRGB(8, 14, 8), bg2 = Color3.fromRGB(16, 26, 16), bg3 = Color3.fromRGB(26, 42, 26),
        accent = Color3.fromRGB(0, 255, 110), accent_d = Color3.fromRGB(0, 150, 60), accent_g = Color3.fromRGB(130, 255, 175),
        esp_green = Color3.fromRGB(0, 255, 100),
        killer = Color3.fromRGB(255, 20, 20),
        purple = Color3.fromRGB(160, 60, 255), purple_d = Color3.fromRGB(80, 20, 140),
        danger = Color3.fromRGB(255, 60, 60), danger_d = Color3.fromRGB(160, 30, 30),
        text = Color3.fromRGB(220, 255, 225), off = Color3.fromRGB(50, 65, 50),
    }

    local gui = Instance.new("ScreenGui")
    gui.Name = "Menu_Loki"; gui.ResetOnSpawn = false; gui.DisplayOrder = 100
    gui.IgnoreGuiInset = true; gui.Parent = CoreGui

    local SOUNDS = {
        intro_start = "rbxasset://sounds/uuhhh.mp3", intro_thunder = "rbxasset://sounds/metal.ogg",
        intro_whoosh = "rbxasset://sounds/swoosh.wav", intro_flash = "rbxasset://sounds/electronicpingshort.wav",
        intro_hum = "rbxasset://sounds/impact_water.mp3", ui_click = "rbxasset://sounds/clickfast.wav",
    }
    local function play_sfx(name, vol, pitch)
        local id = SOUNDS[name]; if not id then return end
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = id; s.Volume = vol or 0.7; s.PlaybackSpeed = pitch or 1
            s.Parent = SoundService
            pcall(function() SoundService:PlayLocalSound(s) end)
            task.delay(10, function() pcall(function() s:Destroy() end) end)
        end)
    end

    local function rot2d(v, a)
        local c, s = math.cos(a), math.sin(a)
        return Vector2.new(v.X * c - v.Y * s, v.X * s + v.Y * c)
    end

    local fx_layer = Instance.new("Frame")
    fx_layer.Size = UDim2.new(1, 0, 1, 0); fx_layer.BackgroundTransparency = 1
    fx_layer.BorderSizePixel = 0; fx_layer.ZIndex = 50; fx_layer.Parent = gui

    local function spawn_bolt(parent, x, y, color, thick)
        color = color or C.accent_g; thick = thick or 2
        local pts = { Vector2.new(x, y) }; local cx, cy = x, y
        for _ = 1, 4 do
            cx = cx + (math.random() - 0.5) * 26; cy = cy + (math.random() - 0.5) * 26
            table.insert(pts, Vector2.new(cx, cy))
        end
        for i = 1, #pts - 1 do
            local p1, p2 = pts[i], pts[i + 1]; local d = p2 - p1
            if d.Magnitude >= 0.5 then
                local f = Instance.new("Frame")
                f.AnchorPoint = Vector2.new(0, 0.5); f.Position = UDim2.fromOffset(p1.X, p1.Y)
                f.Size = UDim2.fromOffset(d.Magnitude, thick); f.Rotation = math.deg(math.atan2(d.Y, d.X))
                f.BackgroundColor3 = color; f.BackgroundTransparency = 0.1
                f.BorderSizePixel = 0; f.ZIndex = 30; f.Parent = parent
                local t = TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
                t:Play(); t.Completed:Connect(function() f:Destroy() end)
            end
        end
    end

    local function spawn_dust(parent, x, y, color, count)
        color = color or C.accent_g; count = count or 8
        for _ = 1, count do
            local d = Instance.new("Frame")
            d.AnchorPoint = Vector2.new(0.5, 0.5); d.Position = UDim2.fromOffset(x, y)
            d.Size = UDim2.new(0, 3, 0, 3); d.BackgroundColor3 = color
            d.BackgroundTransparency = 0.2; d.BorderSizePixel = 0; d.ZIndex = 30; d.Parent = parent
            Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
            local ang = math.random() * math.pi * 2; local dist = 20 + math.random() * 40
            local t = TweenService:Create(d, TweenInfo.new(0.4 + math.random() * 0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.fromOffset(x + math.cos(ang) * dist, y + math.sin(ang) * dist),
                BackgroundTransparency = 1, Size = UDim2.new(0, 1, 0, 1),
            })
            t:Play(); t.Completed:Connect(function() d:Destroy() end)
        end
    end

    local function scanline_pass(parent, color, thick, dur)
        local sl = Instance.new("Frame")
        sl.Size = UDim2.new(1, 0, 0, thick or 3)
        sl.Position = UDim2.new(0, 0, 0, -10)
        sl.BackgroundColor3 = color or C.accent_g
        sl.BackgroundTransparency = 0.15
        sl.BorderSizePixel = 0; sl.ZIndex = 215; sl.Parent = parent
        local t = TweenService:Create(sl, TweenInfo.new(dur or 0.6, Enum.EasingStyle.Linear), {
            Position = UDim2.new(0, 0, 1, 10), BackgroundTransparency = 1
        })
        t:Play(); t.Completed:Connect(function() sl:Destroy() end)
    end

    local MAIN_W = 340
    local MAIN_H = 720
    local TITLE_H = 46
    local main
    local function spawn_cursor_bolt_to_tree()
        if not main or main.AbsoluteSize.X < 20 then return end
        local mp = UIS:GetMouseLocation()
        local sx, sy = mp.X, mp.Y
        local ex = main.AbsolutePosition.X + main.AbsoluteSize.X / 2
        local ey = main.AbsolutePosition.Y + TITLE_H / 2
        if ex <= 0 or ey <= 0 then return end
        local pts = { Vector2.new(sx, sy) }
        for i = 1, 6 do
            local t = i / 6
            local bx = sx + (ex - sx) * t; local by = sy + (ey - sy) * t
            if i < 6 then
                bx = bx + (math.random() - 0.5) * 44; by = by + (math.random() - 0.5) * 44
            else bx, by = ex, ey end
            table.insert(pts, Vector2.new(bx, by))
        end
        for i = 1, #pts - 1 do
            local p1, p2 = pts[i], pts[i + 1]; local d = p2 - p1
            if d.Magnitude >= 0.5 then
                local f = Instance.new("Frame")
                f.AnchorPoint = Vector2.new(0, 0.5); f.Position = UDim2.fromOffset(p1.X, p1.Y)
                f.Size = UDim2.fromOffset(d.Magnitude, 2); f.Rotation = math.deg(math.atan2(d.Y, d.X))
                f.BackgroundColor3 = C.accent_g; f.BackgroundTransparency = 0.05
                f.BorderSizePixel = 0; f.ZIndex = 51; f.Parent = fx_layer
                local t = TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
                t:Play(); t.Completed:Connect(function() f:Destroy() end)
            end
        end
    end

    local fov_overlay = Instance.new("Frame")
    fov_overlay.AnchorPoint = Vector2.new(0.5, 0.5); fov_overlay.Position = UDim2.new(0.5, 0, 0.5, 0)
    fov_overlay.Size = UDim2.new(0, 400, 0, 400); fov_overlay.BackgroundTransparency = 1
    fov_overlay.BorderSizePixel = 0; fov_overlay.Visible = false; fov_overlay.Parent = gui
    Instance.new("UICorner", fov_overlay).CornerRadius = UDim.new(0.5, 0)
    local fov_stroke = Instance.new("UIStroke", fov_overlay)
    fov_stroke.Thickness = 2; fov_stroke.Color = C.accent; fov_stroke.Transparency = 0.15
    local fov_glow = Instance.new("UIStroke", fov_overlay)
    fov_glow.Thickness = 6; fov_glow.Color = C.accent; fov_glow.Transparency = 0.85

    main = Instance.new("Frame")
    main.Position = UDim2.new(0, 40, 0, 90); main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundColor3 = C.bg; main.BackgroundTransparency = 1; main.BorderSizePixel = 0
    main.Active = true; main.Draggable = true; main.ClipsDescendants = true
    main.Visible = false; main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local main_stroke = Instance.new("UIStroke", main)
    main_stroke.Color = C.accent; main_stroke.Thickness = 1.4; main_stroke.Transparency = 0.35

    task.spawn(function()
        while main.Parent do
            TweenService:Create(main_stroke, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { Transparency = 0.7 }):Play()
            task.wait(2.2); if not main.Parent then break end
            TweenService:Create(main_stroke, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { Transparency = 0.25 }):Play()
            task.wait(2.2)
        end
    end)

    local orbit_dot = Instance.new("Frame")
    orbit_dot.Size = UDim2.new(0, 6, 0, 6)
    orbit_dot.BackgroundColor3 = C.accent_g
    orbit_dot.BorderSizePixel = 0
    orbit_dot.AnchorPoint = Vector2.new(0.5, 0.5)
    orbit_dot.ZIndex = 8
    orbit_dot.Visible = false
    orbit_dot.Parent = main
    Instance.new("UICorner", orbit_dot).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        local t = 0
        while main.Parent do
            if not main.Visible or intro_active then
                orbit_dot.Visible = false
            else
                orbit_dot.Visible = true
                t = t + 0.012
                local perimeter = 2 * (MAIN_W + MAIN_H)
                local pos = (t % 1) * perimeter
                local x, y
                if pos < MAIN_W then x, y = pos, 0
                elseif pos < MAIN_W + MAIN_H then x, y = MAIN_W, pos - MAIN_W
                elseif pos < 2*MAIN_W + MAIN_H then x, y = MAIN_W - (pos - MAIN_W - MAIN_H), MAIN_H
                else x, y = 0, MAIN_H - (pos - 2*MAIN_W - MAIN_H) end
                orbit_dot.Position = UDim2.fromOffset(x, y)
            end
            task.wait(0.033)
        end
    end)

    task.spawn(function()
        while main.Parent do
            task.wait(8)
            if main.Visible and not intro_active then
                local sl = Instance.new("Frame")
                sl.Size = UDim2.new(1, 0, 0, 30)
                sl.Position = UDim2.new(0, 0, 0, -30)
                sl.BackgroundColor3 = C.accent; sl.BackgroundTransparency = 0.85
                sl.BorderSizePixel = 0; sl.ZIndex = 9; sl.Parent = main
                Instance.new("UICorner", sl).CornerRadius = UDim.new(0, 10)
                local tw = TweenService:Create(sl, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(0, 0, 1, 30), BackgroundTransparency = 1
                })
                tw:Play()
                tw.Completed:Connect(function() sl:Destroy() end)
            end
        end
    end)

    local brackets = {}
    local function bracket(xa, xo, ya, yo)
        local h = Instance.new("Frame")
        h.BackgroundColor3 = C.accent; h.BackgroundTransparency = 0.15; h.BorderSizePixel = 0
        h.Size = UDim2.new(0, 16, 0, 2); h.AnchorPoint = Vector2.new(xa, ya)
        h.Position = UDim2.new(xa, xo, ya, yo); h.ZIndex = 5; h.Parent = main
        local v = Instance.new("Frame")
        v.BackgroundColor3 = C.accent; v.BackgroundTransparency = 0.15; v.BorderSizePixel = 0
        v.Size = UDim2.new(0, 2, 0, 16); v.AnchorPoint = Vector2.new(xa, ya)
        v.Position = UDim2.new(xa, xo, ya, yo); v.ZIndex = 5; v.Parent = main
        table.insert(brackets, h); table.insert(brackets, v)
    end
    bracket(0, 6, 0, 6); bracket(1, -6, 0, 6); bracket(0, 6, 1, -6); bracket(1, -6, 1, -6)
    task.spawn(function()
        while main.Parent do
            local target = 0.15 + math.random() * 0.6
            for _, b in ipairs(brackets) do
                if b.Parent then TweenService:Create(b, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { BackgroundTransparency = target }):Play() end
            end
            task.wait(1.2)
        end
    end)

    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1, 0, 0, TITLE_H); tb.BackgroundColor3 = C.bg2
    tb.BorderSizePixel = 0; tb.ClipsDescendants = true; tb.Parent = main
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

    local tb_line = Instance.new("Frame")
    tb_line.Size = UDim2.new(1, -20, 0, 1); tb_line.Position = UDim2.new(0, 10, 1, -1)
    tb_line.BackgroundColor3 = C.accent; tb_line.BorderSizePixel = 0; tb_line.ZIndex = 4; tb_line.Parent = tb

    local tree = Instance.new("Frame")
    tree.Size = UDim2.new(1, 0, 1, 0); tree.BackgroundTransparency = 1
    tree.BorderSizePixel = 0; tree.ZIndex = 2; tree.Parent = tb
    local tree_segs = {}
    local function branch(start, dir, len, depth)
        local finish = start + dir * len
        local d = finish - start
        if d.Magnitude < 0.5 then return end
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0, 0.5); f.Position = UDim2.fromOffset(start.X, start.Y)
        f.Size = UDim2.fromOffset(d.Magnitude, math.max(0.9, depth * 0.7))
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
        f.BackgroundColor3 = C.accent; f.BackgroundTransparency = 0.1
        f.BorderSizePixel = 0; f.ZIndex = 2; f.Parent = tree
        table.insert(tree_segs, f)
        if depth > 0 then
            branch(finish, rot2d(dir, 0.38 + math.random() * 0.06), len * 0.72, depth - 1)
            branch(finish, rot2d(dir, -0.42 - math.random() * 0.08), len * 0.72, depth - 1)
        end
    end
    branch(Vector2.new(MAIN_W / 2, TITLE_H - 4), Vector2.new(0, -1), 11, 3)
    task.spawn(function()
        for _, seg in ipairs(tree_segs) do
            task.spawn(function()
                task.wait(math.random() * 3)
                while seg.Parent do
                    TweenService:Create(seg, TweenInfo.new(2, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.85 }):Play()
                    task.wait(2)
                    if not seg.Parent then break end
                    TweenService:Create(seg, TweenInfo.new(2, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.15 }):Play()
                    task.wait(2)
                end
            end)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Text = "MENU DO LOKI  " .. LOKI_VERSION; title.Size = UDim2.new(1, -90, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0); title.BackgroundTransparency = 1
    title.TextColor3 = C.accent_g; title.Font = Enum.Font.GothamBlack
    title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5; title.Parent = tb
    local title_stroke = Instance.new("UIStroke", title)
    title_stroke.Color = C.accent; title_stroke.Thickness = 1.6; title_stroke.Transparency = 0.55
    task.spawn(function()
        while title.Parent do
            TweenService:Create(title_stroke, TweenInfo.new(2, Enum.EasingStyle.Sine), { Transparency = 0.9 }):Play()
            task.wait(2); if not title.Parent then break end
            TweenService:Create(title_stroke, TweenInfo.new(2, Enum.EasingStyle.Sine), { Transparency = 0.15 }):Play()
            task.wait(2)
        end
    end)

    local function round_btn(sym, xpos)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 26, 0, 26); b.Position = UDim2.new(1, xpos, 0.5, -13)
        b.BackgroundColor3 = C.bg3; b.Text = sym; b.TextColor3 = C.accent_g
        b.Font = Enum.Font.GothamBold; b.TextSize = 15; b.BorderSizePixel = 0
        b.ZIndex = 6; b.Parent = tb
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        local sc = Instance.new("UIScale", b)
        b.MouseButton1Down:Connect(function() TweenService:Create(sc, TweenInfo.new(0.08), { Scale = 0.85 }):Play() end)
        b.MouseButton1Up:Connect(function() TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() end)
        b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = C.accent_d }):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = C.bg3 }):Play() end)
        return b
    end
    local min_btn = round_btn("_", -68)
    local close_btn = round_btn("X", -34)

    local tab_bar = Instance.new("Frame")
    tab_bar.Size = UDim2.new(1, -20, 0, 28); tab_bar.Position = UDim2.new(0, 10, 0, 54)
    tab_bar.BackgroundTransparency = 1; tab_bar.Parent = main
    local tab_layout = Instance.new("UIListLayout", tab_bar)
    tab_layout.FillDirection = Enum.FillDirection.Horizontal; tab_layout.Padding = UDim.new(0, 4)

    local tab_frames, tab_buttons = {}, {}
    local function switch_tab(name)
        for n, f in pairs(tab_frames) do
            if n == name then
                f.Visible = true
                f.Position = UDim2.new(0, MAIN_W, 0, 90)
                TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 10, 0, 90)
                }):Play()
            else f.Visible = false end
        end
        for n, b in pairs(tab_buttons) do
            if n == name then
                TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = C.accent_d }):Play()
                b.TextColor3 = Color3.new(0, 0, 0)
                local stk = b:FindFirstChildOfClass("UIStroke")
                if not stk then stk = Instance.new("UIStroke", b); stk.Color = C.accent_g; stk.Thickness = 2 end
                stk.Transparency = 0.3
            else
                TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = C.bg2 }):Play()
                b.TextColor3 = C.text
                local stk = b:FindFirstChildOfClass("UIStroke")
                if stk then stk.Transparency = 1 end
            end
        end
    end

    local function create_tab(name, width)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, width or 76, 1, 0); btn.BackgroundColor3 = C.bg2
        btn.Text = name; btn.TextColor3 = C.text; btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11; btn.BorderSizePixel = 0; btn.Parent = tab_bar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            switch_tab(name); spawn_cursor_bolt_to_tree(); play_sfx("ui_click", 0.4, 1.2)
        end)
        tab_buttons[name] = btn

        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1, -20, 1, -110); frame.Position = UDim2.new(0, 10, 0, 90)
        frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.ScrollBarThickness = 3; frame.ScrollBarImageColor3 = C.accent
        frame.ScrollBarImageTransparency = 0.4; frame.Visible = false; frame.Parent = main
        local l = Instance.new("UIListLayout", frame)
        l.Padding = UDim.new(0, 6); l.SortOrder = Enum.SortOrder.LayoutOrder
        tab_frames[name] = frame
        return frame
    end

    local visual_frame = create_tab("VISUAL")
    local aim_frame = create_tab("AIMBOT")
    local move_frame = create_tab("MOVIM")
    local risk_frame = create_tab("RISCO")

    for _, f in pairs(tab_frames) do
        local scan1 = Instance.new("Frame")
        scan1.Size = UDim2.new(1, -20, 0, 2); scan1.Position = UDim2.new(0, 10, 0, -2)
        scan1.BackgroundColor3 = C.accent; scan1.BackgroundTransparency = 0.85
        scan1.BorderSizePixel = 0; scan1.ZIndex = 10; scan1.Parent = f
        task.spawn(function()
            while scan1.Parent do
                scan1.Position = UDim2.new(0, 10, 0, -2)
                TweenService:Create(scan1, TweenInfo.new(5, Enum.EasingStyle.Linear), { Position = UDim2.new(0, 10, 1, 0) }):Play()
                task.wait(10)
            end
        end)
    end

    -- ============ CONFIG COM VALORES INTEIROS ============
    local cfg = {
        esp = true, team_check = false, wall_check = false,
        esp_name = true, esp_dist = true, esp_lines = false, esp_body = false,
        fullbright = false, no_fog = false,
        aimbot = false, mobile_aim = true, show_fov = true, rainbow_fov = false, prediction = true,
        aim_jitter = false,
        target_part = "Head", fov_radius = 150, smoothing = 4, fov_alpha = 15,
        aimbot_min_dist = 5, aimbot_max_dist = 400,
        aimbot_priority = "Smart",
        aimbot_angle_weight = 150,
        wall_pierce = false, wall_pierce_fov = 400, wp_show_fov = false, wp_debug = false,
        enemies_only = true,
        revenge_mark = true,
        revenge_duration = 120,
        revenge_radius = 200,
        revenge_los_radius = 500,
        revenge_max_suspects = 1,
        tp_aim = false, tp_auto = false, tp_cycle_rate = 2, tp_only_grounded = true,
        tp_smooth = true,
        tp_smooth_ms = 120,   -- milissegundos (antes era 0.12s)
        tp_max_dist = 500,
        auto_fire = false,
        fire_delay_ms = 100,  -- milissegundos (antes era 0.1s)
        god = false,
        walkspeed = 16, jumppower = 50,
        noclip = false, infjump = false, fly = false, fly_speed = 50,
        anti_afk = false,
        menu_key = Enum.KeyCode.RightShift,
        waiting_key = false,
        menu_state = "open",
    }

    local esp_hl, esp_drawings, los_cache = {}, {}, {}
    local last_tp_t = 0
    local tp_current_target = nil
    local tp_target_start = 0
    local last_safe_pos = Vector3.new(0, 50, 0)
    local hue = 0
    local touch_active = false
    local last_input = Vector2.new(0, 0)
    local rmb_down = false
    local lmb_down = false
    local fly_bv, fly_bg
    local noclip_conn, infjump_conn, god_conn, god_char_conn
    local god_ff
    local last_fire_t = 0
    local orig = { Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }

    -- ===== REVENGE =====
    local event_log = {}
    local function log_event(msg)
        print("[LOKI] " .. msg)
        table.insert(event_log, 1, { msg = msg, time = os.clock() })
        if #event_log > 20 then table.remove(event_log) end
    end

    local killer_marks = {}
    local damage_events = {}
    local death_handled = true
    local last_hp_seen = 100
    local last_my_pos = Vector3.new(0, 50, 0)
    local last_damage_clock = 0
    local last_attacker = nil
    local last_attacker_time = 0
    local last_dmg_record = 0

    local function clear_killer_marks()
        killer_marks = {}
        damage_events = {}
        log_event("marcas limpas")
    end

    local function mark_killer(plr, reason)
        if not plr or plr == LP then return end
        if not cfg.revenge_mark then return end
        if killer_marks[plr] and killer_marks[plr] > os.clock() + cfg.revenge_duration - 2 then return end
        killer_marks[plr] = os.clock() + cfg.revenge_duration
        log_event("KILLER: " .. plr.Name .. " (" .. tostring(reason) .. ")")
    end

    local function get_aiming_suspects(my_pos, max_dist)
        local out = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local pHrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local pHead = plr.Character:FindFirstChild("Head")
                local pHum = plr.Character:FindFirstChildOfClass("Humanoid")
                if pHrp and pHum and pHum.Health > 0 then
                    local d = (pHrp.Position - my_pos).Magnitude
                    if d <= max_dist then
                        local toMe = (my_pos - pHrp.Position).Unit
                        local faceScore = 0
                        if pHead then faceScore = math.max(faceScore, pHead.CFrame.LookVector:Dot(toMe)) end
                        faceScore = math.max(faceScore, pHrp.CFrame.LookVector:Dot(toMe))
                        if faceScore > 0.35 then
                            table.insert(out, { plr = plr, dist = d, facing = faceScore })
                        end
                    end
                end
            end
        end
        return out
    end

    local function record_damage()
        local now = os.clock()
        if now - last_dmg_record < 0.5 then return end
        last_dmg_record = now
        local suspects = get_aiming_suspects(last_my_pos, 800)
        for _, s in ipairs(suspects) do s.score = s.facing * 100 - s.dist / 10 end
        table.sort(suspects, function(a, b) return a.score > b.score end)
        table.insert(damage_events, 1, { time = now, suspects = suspects })
        while #damage_events > 3 do table.remove(damage_events) end
    end

    local function show_killer_popup(names)
        if #names == 0 then names = { "?" } end
        local popup = Instance.new("TextLabel")
        popup.Size = UDim2.new(0, 500, 0, 60)
        popup.Position = UDim2.new(0.5, -250, 0.28, 0)
        popup.BackgroundColor3 = C.killer; popup.BackgroundTransparency = 0.2
        popup.TextColor3 = Color3.new(1, 1, 1); popup.Font = Enum.Font.GothamBlack
        popup.TextSize = 20; popup.Text = "KILLED BY: " .. table.concat(names, ", ")
        popup.ZIndex = 300; popup.Parent = gui
        Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 10)
        local stk = Instance.new("UIStroke", popup)
        stk.Color = Color3.new(1, 1, 1); stk.Thickness = 2; stk.Transparency = 0.3
        TweenService:Create(popup, TweenInfo.new(3.5), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
        TweenService:Create(stk, TweenInfo.new(3.5), { Transparency = 1 }):Play()
        task.delay(3.7, function() if popup.Parent then popup:Destroy() end end)
    end

    local function handle_death(pos)
        log_event(("MORRI em (%.0f, %.0f, %.0f)"):format(pos.X, pos.Y, pos.Z))
        local now = os.clock()
        local tally = {}
        local eventos_recentes = 0
        for _, ev in ipairs(damage_events) do
            if now - ev.time < 8 then
                eventos_recentes = eventos_recentes + 1
                for i, s in ipairs(ev.suspects) do
                    if i <= 3 then
                        local weight = (4 - i) / 3
                        tally[s.plr] = (tally[s.plr] or 0) + weight + (s.facing or 0) * 0.5
                    end
                end
            end
        end
        log_event(("eventos de dano: %d"):format(eventos_recentes))
        if last_attacker and (now - last_attacker_time) < 10
           and last_attacker.Character
           and last_attacker.Character:FindFirstChildOfClass("Humanoid")
           and last_attacker.Character.Humanoid.Health > 0 then
            tally[last_attacker] = (tally[last_attacker] or 0) + 5
            log_event("último atacante vivo: " .. last_attacker.Name)
        end
        local ranked = {}
        for plr, score in pairs(tally) do
            local ch = plr.Character
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then table.insert(ranked, { plr = plr, score = score }) end
        end
        table.sort(ranked, function(a, b) return a.score > b.score end)
        local marked_names = {}
        local cap = math.max(1, math.min(3, tonumber(cfg.revenge_max_suspects) or 1))
        for i = 1, math.min(cap, #ranked) do
            local entry = ranked[i]
            mark_killer(entry.plr, ("score_%.1f"):format(entry.score))
            table.insert(marked_names, entry.plr.Name)
        end
        log_event(("marcados por score: %d"):format(#marked_names))
        if #marked_names == 0 then
            local nearest, nearest_d = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local pHrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local pHum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if pHrp and pHum and pHum.Health > 0 then
                        local d = (pHrp.Position - pos).Magnitude
                        if d < nearest_d then nearest_d = d; nearest = plr end
                    end
                end
            end
            if nearest then
                mark_killer(nearest, ("nearest_%.0f"):format(nearest_d))
                table.insert(marked_names, nearest.Name)
                log_event("FALLBACK: " .. nearest.Name)
            end
        end
        damage_events = {}
        if #marked_names > 0 then show_killer_popup(marked_names)
        else log_event("nenhum suspeito válido") end
    end

    task.spawn(function()
        while gui.Parent do
            local char = LP.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then last_my_pos = hrp.Position end
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then
                    local hp = h.Health
                    if death_handled then last_hp_seen = hp; death_handled = false end
                    if hp < last_hp_seen - 0.5 and hp > 0 then
                        last_damage_clock = os.clock()
                        if cfg.revenge_mark then
                            log_event(("dano: %.0f -> %.0f"):format(last_hp_seen, hp))
                            record_damage()
                            local de = damage_events[1]
                            if de and de.suspects[1] then
                                last_attacker = de.suspects[1].plr
                                last_attacker_time = os.clock()
                            end
                        end
                    end
                    if hp <= 0 and not death_handled then
                        death_handled = true
                        handle_death(last_my_pos)
                    end
                    last_hp_seen = hp
                end
            else
                if not death_handled and last_hp_seen > 0 then
                    death_handled = true
                    handle_death(last_my_pos)
                end
            end
            task.wait(0.25)
        end
    end)

    LP.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        death_handled = true
        last_damage_clock = 0
        damage_events = {}
        local h = char:FindFirstChildOfClass("Humanoid")
        last_hp_seen = h and h.Health or 100
    end)

    UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            last_input = Vector2.new(inp.Position.X, inp.Position.Y)
        end
    end)
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType == Enum.UserInputType.Touch then
            touch_active = true; last_input = Vector2.new(inp.Position.X, inp.Position.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then touch_active = false end
    end)

    local function ripple(parent_frame, x, y)
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5); r.Position = UDim2.fromOffset(x, y)
        r.Size = UDim2.new(0, 4, 0, 4); r.BackgroundColor3 = C.accent
        r.BackgroundTransparency = 0.3; r.BorderSizePixel = 0; r.ZIndex = 20; r.Parent = parent_frame
        Instance.new("UICorner", r).CornerRadius = UDim.new(1, 0)
        local t = TweenService:Create(r, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 60, 0, 60), BackgroundTransparency = 1,
        })
        t:Play(); t.Completed:Connect(function() r:Destroy() end)
    end

    local function flash(target_frame, color)
        color = color or C.accent
        local fl = Instance.new("Frame")
        fl.Size = UDim2.new(1, 0, 1, 0); fl.BackgroundColor3 = color
        fl.BackgroundTransparency = 0.65; fl.BorderSizePixel = 0; fl.ZIndex = 15; fl.Parent = target_frame
        Instance.new("UICorner", fl).CornerRadius = UDim.new(0, 6)
        local t = TweenService:Create(fl, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
        t:Play(); t.Completed:Connect(function() fl:Destroy() end)
    end

    local function section(txt, parent, color)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -10, 0, 20); f.BackgroundTransparency = 1; f.Parent = parent
        local l = Instance.new("TextLabel")
        l.Text = txt; l.Size = UDim2.new(1, 0, 0, 14); l.BackgroundTransparency = 1
        l.TextColor3 = color or C.accent; l.TextTransparency = 0.3
        l.Font = Enum.Font.GothamBold; l.TextSize = 11
        l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
        local underline = Instance.new("Frame")
        underline.Size = UDim2.new(0, 0, 0, 1); underline.Position = UDim2.new(0, 0, 1, -2)
        underline.BackgroundColor3 = color or C.accent; underline.BorderSizePixel = 0; underline.Parent = f
        task.spawn(function()
            task.wait(0.1)
            TweenService:Create(underline, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 60, 0, 1) }):Play()
        end)
    end

    local function toggle(name, key, parent, cb, danger)
        local on_color = danger and C.danger or C.accent
        local on_color_g = danger and Color3.fromRGB(255, 140, 140) or C.accent_g
        local btn = Instance.new("Frame")
        btn.Size = UDim2.new(1, -10, 0, 34); btn.BackgroundColor3 = cfg[key] and C.bg3 or C.bg2
        btn.BorderSizePixel = 0; btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local sc = Instance.new("UIScale", btn)
        local hover_stroke = Instance.new("UIStroke", btn)
        hover_stroke.Color = on_color_g; hover_stroke.Thickness = 1.5; hover_stroke.Transparency = 1
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, -10); bar.Position = UDim2.new(0, 0, 0, 5)
        bar.BackgroundColor3 = cfg[key] and on_color or C.off; bar.BorderSizePixel = 0; bar.Parent = btn
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
        local bar_stroke = Instance.new("UIStroke", bar)
        bar_stroke.Color = on_color_g; bar_stroke.Thickness = 2
        bar_stroke.Transparency = cfg[key] and 0.3 or 1
        local lbl = Instance.new("TextLabel")
        lbl.Text = name; lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = cfg[key] and on_color_g or C.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10); dot.Position = UDim2.new(1, -22, 0.5, -5)
        dot.BackgroundColor3 = cfg[key] and on_color or C.off; dot.BorderSizePixel = 0; dot.Parent = btn
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local dot_stroke = Instance.new("UIStroke", dot)
        dot_stroke.Color = on_color_g; dot_stroke.Thickness = 1.5
        dot_stroke.Transparency = cfg[key] and 0.2 or 1
        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 0); hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = btn
        hit.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = C.bg3 }):Play()
            TweenService:Create(hover_stroke, TweenInfo.new(0.2), { Transparency = 0.25 }):Play()
        end)
        hit.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = cfg[key] and C.bg3 or C.bg2 }):Play()
            TweenService:Create(hover_stroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
        end)
        hit.MouseButton1Down:Connect(function() TweenService:Create(sc, TweenInfo.new(0.08), { Scale = 0.97 }):Play() end)
        hit.MouseButton1Up:Connect(function() TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() end)
        hit.MouseButton1Click:Connect(function()
            cfg[key] = not cfg[key]; local on = cfg[key]
            TweenService:Create(dot, TweenInfo.new(0.22), { BackgroundColor3 = on and on_color or C.off }):Play()
            TweenService:Create(dot_stroke, TweenInfo.new(0.22), { Transparency = on and 0.2 or 1 }):Play()
            TweenService:Create(bar, TweenInfo.new(0.22), { BackgroundColor3 = on and on_color or C.off }):Play()
            TweenService:Create(bar_stroke, TweenInfo.new(0.22), { Transparency = on and 0.3 or 1 }):Play()
            TweenService:Create(lbl, TweenInfo.new(0.22), { TextColor3 = on and on_color_g or C.text }):Play()
            ripple(btn, 20, 17); spawn_cursor_bolt_to_tree()
            play_sfx("ui_click", 0.35, on and 1.3 or 0.9)
            if on then
                spawn_bolt(btn, btn.AbsoluteSize.X / 2, 17, on_color_g)
                spawn_dust(btn, btn.AbsoluteSize.X / 2, 17, on_color, 10)
                flash(btn, on_color)
            else spawn_dust(btn, btn.AbsoluteSize.X / 2, 17, C.off, 6) end
            if cb then cb(on) end
        end)
    end

    -- SLIDER INTEIRO (sempre número inteiro, sem decimais)
    local function slider(name, min, max, key, parent, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -10, 0, 44); f.BackgroundColor3 = C.bg2
        f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel")
        lbl.Text = name .. ": " .. tostring(math.floor(cfg[key] + 0.5))
        lbl.Size = UDim2.new(1, -20, 0, 16); lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = C.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 4); track.Position = UDim2.new(0, 10, 0, 30)
        track.BackgroundColor3 = C.bg3; track.BorderSizePixel = 0; track.Parent = f
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((math.floor(cfg[key] + 0.5) - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = C.accent; fill.BorderSizePixel = 0; fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12); knob.Position = UDim2.new(fill.Size.X.Scale, -6, 0.5, -6)
        knob.BackgroundColor3 = C.accent_g; knob.BorderSizePixel = 0; knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local knob_stroke = Instance.new("UIStroke", knob)
        knob_stroke.Color = C.accent; knob_stroke.Thickness = 2; knob_stroke.Transparency = 0.5
        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 0); hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = track
        local dragging = false
        local function set_val(px)
            local pos = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + (max - min) * pos + 0.5) -- arredonda sempre
            if v < min then v = min end
            if v > max then v = max end
            cfg[key] = v
            lbl.Text = name .. ": " .. tostring(v)
            TweenService:Create(fill, TweenInfo.new(0.06), { Size = UDim2.new(pos, 0, 1, 0) }):Play()
            TweenService:Create(knob, TweenInfo.new(0.06), { Position = UDim2.new(pos, -6, 0.5, -6) }):Play()
            if cb then cb(v) end
        end
        hit.MouseButton1Down:Connect(function()
            dragging = true; TweenService:Create(knob_stroke, TweenInfo.new(0.1), { Transparency = 0 }):Play()
            set_val(last_input.X)
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                set_val(last_input.X)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                dragging = false; TweenService:Create(knob_stroke, TweenInfo.new(0.2), { Transparency = 0.5 }):Play()
            end
        end)
    end

    local function selector(name, options, key, parent, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -10, 0, 34); f.BackgroundColor3 = C.bg2
        f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel")
        lbl.Text = name .. ": " .. tostring(cfg[key])
        lbl.Size = UDim2.new(1, -80, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = C.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 64, 0, 24); btn.Position = UDim2.new(1, -74, 0.5, -12)
        btn.BackgroundColor3 = C.accent_d; btn.Text = "Mudar"; btn.TextColor3 = Color3.new(0, 0, 0)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0; btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local idx = 1
        for i = 1, #options do if options[i] == cfg[key] then idx = i end end
        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            cfg[key] = options[idx]; lbl.Text = name .. ": " .. tostring(cfg[key])
            play_sfx("ui_click", 0.35, 1.25)
            if cb then cb(cfg[key]) end
        end)
    end

    local function action_btn(name, cb, parent, danger)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -10, 0, 32); b.BackgroundColor3 = danger and C.danger_d or C.accent_d
        b.Text = name; b.TextColor3 = Color3.new(0, 0, 0)
        b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.BorderSizePixel = 0; b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function() play_sfx("ui_click", 0.35, 1.0); cb() end)
    end

    local function hum()
        if LP.Character then return LP.Character:FindFirstChildOfClass("Humanoid") end
        return nil
    end
    local function alive(plr)
        local ch = plr.Character
        if not ch then return false end
        local h = ch:FindFirstChildOfClass("Humanoid")
        return h and h.Health > 0 and ch:FindFirstChild("HumanoidRootPart")
    end
    local function is_enemy(plr)
        if plr == LP then return false end
        if not cfg.enemies_only then return true end
        if plr.Team and LP.Team and plr.Team == LP.Team then return false end
        return true
    end
    local function los_clear(plr, part)
        local now = os.clock()
        local c = los_cache[plr]
        if c and now - c.t < 0.5 then return c.v end
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = true
        local filter = { Camera }
        if LP.Character then table.insert(filter, LP.Character) end
        if plr.Character then table.insert(filter, plr.Character) end
        rp.FilterDescendantsInstances = filter
        local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp)
        local v = (hit == nil)
        los_cache[plr] = { v = v, t = now }
        return v
    end
    local function is_killer(plr)
        local exp = killer_marks[plr]
        if not exp then return false end
        if os.clock() >= exp then killer_marks[plr] = nil; return false end
        return true
    end

    -- try_fire: usa fire_delay_ms / 1000
    local function try_fire()
        local now = os.clock()
        local delay = math.max((cfg.fire_delay_ms or 100) / 1000, 0.06)
        if now - last_fire_t < delay then return false end
        last_fire_t = now
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton1(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
        end)
        pcall(function()
            local char = LP.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end)
        return true
    end

    local function find_wall_pierce_target()
        local center = Camera.ViewportSize / 2
        local best, best_d = nil, cfg.wall_pierce_fov
        for _, plr in ipairs(Players:GetPlayers()) do
            if is_enemy(plr) and alive(plr) then
                local ch = plr.Character
                local head = ch:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, on = Camera:WorldToViewportPoint(head.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < best_d then best_d = d; best = head end
                    end
                end
            end
        end
        return best
    end

    section("VISUAL", visual_frame)
    toggle("ESP (Highlight)", "esp", visual_frame)
    toggle("ESP Corpo Inteiro", "esp_body", visual_frame)
    toggle("ESP Nome", "esp_name", visual_frame)
    toggle("ESP Distancia", "esp_dist", visual_frame)
    toggle("ESP Linhas (Tracers)", "esp_lines", visual_frame)
    toggle("Team Check ESP", "team_check", visual_frame)
    toggle("Wall Check", "wall_check", visual_frame)
    toggle("Fullbright", "fullbright", visual_frame, function(on) Lighting.Brightness = on and 3 or orig.Brightness end)
    toggle("Sem Fog", "no_fog", visual_frame, function(on)
        if on then Lighting.FogEnd = 100000; Lighting.FogStart = 100000 else Lighting.FogEnd = orig.FogEnd; Lighting.FogStart = orig.FogStart end
    end)

    section("REVENGE MARK", visual_frame, C.killer)
    toggle("Marcar quem me matou", "revenge_mark", visual_frame)
    slider("Duração (s)", 10, 600, "revenge_duration", visual_frame)
    slider("Raio de detecção", 50, 500, "revenge_radius", visual_frame)
    slider("Raio LOS (sniper)", 100, 1000, "revenge_los_radius", visual_frame)
    slider("Máx. marcados", 1, 3, "revenge_max_suspects", visual_frame)

    local function test_mark_killer()
        clear_killer_marks()
        local enemies = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
                table.insert(enemies, plr)
            end
        end
        if #enemies > 0 then
            local test = enemies[math.random(1, #enemies)]
            mark_killer(test, "teste_manual")
            log_event("TESTE: marcado " .. test.Name)
            show_killer_popup({test.Name})
        else log_event("TESTE: nenhum inimigo disponível") end
    end

    action_btn("Testar marca (inimigo aleatório)", test_mark_killer, visual_frame)
    action_btn("Limpar marcas", function() clear_killer_marks() end, visual_frame)

    local log_holder = Instance.new("Frame")
    log_holder.Size = UDim2.new(1, -10, 0, 130)
    log_holder.BackgroundColor3 = C.bg3
    log_holder.BorderSizePixel = 0
    log_holder.Parent = visual_frame
    Instance.new("UICorner", log_holder).CornerRadius = UDim.new(0, 6)

    local log_title = Instance.new("TextLabel")
    log_title.Size = UDim2.new(1, -10, 0, 16); log_title.Position = UDim2.new(0, 6, 0, 3)
    log_title.BackgroundTransparency = 1; log_title.Text = "REVENGE LOG (últimas 6)"
    log_title.TextColor3 = C.killer; log_title.Font = Enum.Font.GothamBold
    log_title.TextSize = 10; log_title.TextXAlignment = Enum.TextXAlignment.Left
    log_title.Parent = log_holder

    local log_labels = {}
    for i = 1, 6 do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 16)
        lbl.Position = UDim2.new(0, 6, 0, 20 + (i - 1) * 17)
        lbl.BackgroundTransparency = 1; lbl.Text = ""; lbl.TextColor3 = C.text
        lbl.Font = Enum.Font.Code; lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = log_holder
        log_labels[i] = lbl
    end

    task.spawn(function()
        while gui.Parent do
            for i = 1, 6 do
                local e = event_log[i]
                if e then
                    local age = os.clock() - e.time
                    log_labels[i].Text = ("[%.0fs] %s"):format(age, e.msg)
                    log_labels[i].TextColor3 = (age < 5) and C.accent_g or C.text
                else log_labels[i].Text = "" end
            end
            task.wait(0.5)
        end
    end)

    section("CONFIGURAÇÃO DE TECLA", visual_frame)
    local key_frame = Instance.new("Frame")
    key_frame.Size = UDim2.new(1, -10, 0, 34); key_frame.BackgroundColor3 = C.bg2
    key_frame.BorderSizePixel = 0; key_frame.Parent = visual_frame
    Instance.new("UICorner", key_frame).CornerRadius = UDim.new(0, 6)
    local key_lbl = Instance.new("TextLabel")
    key_lbl.Text = "Tecla Atual: " .. cfg.menu_key.Name
    key_lbl.Size = UDim2.new(1, -80, 1, 0); key_lbl.Position = UDim2.new(0, 10, 0, 0)
    key_lbl.BackgroundTransparency = 1; key_lbl.TextColor3 = C.text
    key_lbl.Font = Enum.Font.Gotham; key_lbl.TextSize = 12
    key_lbl.TextXAlignment = Enum.TextXAlignment.Left; key_lbl.Parent = key_frame
    local key_btn = Instance.new("TextButton")
    key_btn.Size = UDim2.new(0, 64, 0, 24); key_btn.Position = UDim2.new(1, -74, 0.5, -12)
    key_btn.BackgroundColor3 = C.accent_d; key_btn.Text = "Mudar"; key_btn.TextColor3 = Color3.new(0, 0, 0)
    key_btn.Font = Enum.Font.GothamBold; key_btn.TextSize = 11; key_btn.BorderSizePixel = 0; key_btn.Parent = key_frame
    Instance.new("UICorner", key_btn).CornerRadius = UDim.new(0, 4)
    key_btn.MouseButton1Click:Connect(function()
        cfg.waiting_key = true
        key_lbl.Text = "Aperte uma tecla..."
        key_lbl.TextColor3 = C.accent
    end)

    section("ALVO", aim_frame)
    toggle("Só Inimigos", "enemies_only", aim_frame)

    section("AIMBOT", aim_frame)
    toggle("Aimbot (RMB / toque)", "aimbot", aim_frame)
    toggle("Touch Aim", "mobile_aim", aim_frame)
    toggle("Mostrar FOV", "show_fov", aim_frame)
    toggle("Predicao", "prediction", aim_frame)
    toggle("Humanizacao (Jitter)", "aim_jitter", aim_frame)
    slider("FOV", 50, 500, "fov_radius", aim_frame)
    slider("Suavizacao", 1, 10, "smoothing", aim_frame)
    selector("Parte Alvo", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "target_part", aim_frame)

    section("ALCANCE DO AIMBOT", aim_frame)
    slider("Distância Max (studs)", 50, 2000, "aimbot_max_dist", aim_frame)
    slider("Distância Min (studs)", 0, 100, "aimbot_min_dist", aim_frame)
    selector("Prioridade", {"Smart", "Closest", "FOV"}, "aimbot_priority", aim_frame)

    section("SMART MODE (peso)", aim_frame)
    slider("Peso do centro", 0, 500, "aimbot_angle_weight", aim_frame)

    section("WALL PIERCE", aim_frame)
    toggle("Wall Pierce (via câmera)", "wall_pierce", aim_frame)
    toggle("Mostrar WP FOV", "wp_show_fov", aim_frame)
    slider("WP FOV", 50, 800, "wall_pierce_fov", aim_frame)

    section("MOVIMENTO", move_frame)
    slider("WalkSpeed", 8, 100, "walkspeed", move_frame, function(v) local h = hum(); if h then h.WalkSpeed = v end end)
    slider("JumpPower", 50, 200, "jumppower", move_frame, function(v) local h = hum(); if h then h.JumpPower = v end end)
    slider("Fly Speed", 10, 300, "fly_speed", move_frame)

    local function set_fly(on)
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local h = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not h then return end
        if on then
            if fly_bg then fly_bg:Destroy() end
            if fly_bv then fly_bv:Destroy() end
            fly_bg = Instance.new("BodyGyro", hrp); fly_bg.P = 9e4; fly_bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); fly_bg.CFrame = hrp.CFrame
            fly_bv = Instance.new("BodyVelocity", hrp); fly_bv.Velocity = Vector3.zero; fly_bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            h:ChangeState(Enum.HumanoidStateType.Physics)
        else
            if fly_bg then fly_bg:Destroy(); fly_bg = nil end
            if fly_bv then fly_bv:Destroy(); fly_bv = nil end
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end)
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Freefall) end)
        end
    end

    local function set_noclip(on)
        if noclip_conn then noclip_conn:Disconnect(); noclip_conn = nil end
        if not on then
            local char = LP.Character
            if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
            return
        end
        noclip_conn = RunService.Stepped:Connect(function()
            if not cfg.noclip or not LP.Character then return end
            for _, p in ipairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end
        end)
    end

    local function set_infjump(on)
        if infjump_conn then infjump_conn:Disconnect(); infjump_conn = nil end
        if not on then return end
        infjump_conn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode ~= Enum.KeyCode.Space then return end
            local h = hum()
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not h or not hrp then return end
            h:ChangeState(Enum.HumanoidStateType.Jumping)
            local v = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(v.X, h.JumpPower, v.Z)
        end)
    end

    local function set_god(on)
        if god_conn then god_conn:Disconnect(); god_conn = nil end
        if god_char_conn then god_char_conn:Disconnect(); god_char_conn = nil end
        if god_ff then pcall(function() god_ff:Destroy() end); god_ff = nil end
        if not on then return end
        local function attach()
            local char = LP.Character; if not char then return end
            local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
            if god_conn then god_conn:Disconnect(); god_conn = nil end
            if god_ff then pcall(function() god_ff:Destroy() end) end
            god_ff = Instance.new("ForceField", char); god_ff.Visible = false
            god_conn = h.HealthChanged:Connect(function(hp) if cfg.god and hp < h.MaxHealth and h.Health > 0 then pcall(function() h.Health = h.MaxHealth end) end end)
        end
        attach()
        god_char_conn = LP.CharacterAdded:Connect(function() if cfg.god then task.wait(0.6); attach() end end)
    end

    toggle("NoClip", "noclip", move_frame, function(on) set_noclip(on) end)
    toggle("Infinite Jump", "infjump", move_frame, function(on) set_infjump(on) end)
    toggle("Fly", "fly", move_frame, function(on) set_fly(on) end)
    toggle("Anti-AFK", "anti_afk", move_frame)

    task.spawn(function()
        while gui.Parent do
            if cfg.walkspeed ~= 16 or cfg.jumppower ~= 50 then
                local h = hum()
                if h then
                    if h.WalkSpeed ~= cfg.walkspeed then h.WalkSpeed = cfg.walkspeed end
                    if h.JumpPower ~= cfg.jumppower then h.JumpPower = cfg.jumppower; h.UseJumpPower = true end
                end
            end
            task.wait(0.3)
        end
    end)

    section("ACOES", move_frame)
    action_btn("Reset personagem", function()
        local h = hum(); local char = LP.Character
        if not h or not char then return end
        pcall(function() if fly_bv then fly_bv:Destroy(); fly_bv = nil end; if fly_bg then fly_bg:Destroy(); fly_bg = nil end end)
        pcall(function() h.Health = 0 end); pcall(function() char:BreakJoints() end)
    end, move_frame)
    action_btn("Rejoin servidor", function() pcall(function() TS:Teleport(game.PlaceId, LP) end) end, move_frame)

    section("TP AIM", risk_frame, C.danger)
    toggle("TP Manual (RMB -> cabeça)", "tp_aim", risk_frame, nil, true)
    toggle("TP Auto (ciclo sem RMB)", "tp_auto", risk_frame, nil, true)
    toggle("TP só se alvo no chão", "tp_only_grounded", risk_frame, nil, true)
    toggle("TP Suave (Anti-Ban)", "tp_smooth", risk_frame, nil, true)
    slider("TP Tempo (ms)", 50, 500, "tp_smooth_ms", risk_frame)    -- inteiro em ms
    slider("TP Dist Max", 50, 800, "tp_max_dist", risk_frame)
    slider("TP Cycle (s)", 1, 5, "tp_cycle_rate", risk_frame)       -- 1-5 segundos inteiros

    section("FIRE / GOD", risk_frame, C.danger)
    toggle("Auto Fire (LMB segura)", "auto_fire", risk_frame, nil, true)
    slider("Fire Delay (ms)", 50, 500, "fire_delay_ms", risk_frame) -- inteiro em ms
    toggle("Godmode (teste)", "god", risk_frame, function(on) set_god(on) end, true)

    -- RenderStepped único
    local esp_accum = 0
    RunService.RenderStepped:Connect(function(dt)
        rmb_down = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        lmb_down = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

        if intro_active then fov_overlay.Visible = false; return end

        if cfg.show_fov and cfg.aimbot then
            fov_overlay.Visible = true
            fov_overlay.Size = UDim2.new(0, cfg.fov_radius * 2, 0, cfg.fov_radius * 2)
            local a = math.clamp(cfg.fov_alpha / 100, 0, 1)
            fov_stroke.Transparency = a; fov_glow.Transparency = math.clamp(a + 0.55, 0, 1)
            if cfg.rainbow_fov then
                hue = (hue + 0.005) % 1; local col = Color3.fromHSV(hue, 1, 1); fov_stroke.Color = col; fov_glow.Color = col
            else fov_stroke.Color = C.accent; fov_glow.Color = C.accent end
        else fov_overlay.Visible = false end

        if cfg.fly then
            if not fly_bv then set_fly(true) end
            if fly_bv then
                local h = hum()
                if h then
                    local dir = h.MoveDirection
                    if dir.Magnitude < 0.05 then
                        local kd = Vector3.zero
                        if UIS:IsKeyDown(Enum.KeyCode.W) then kd = kd + Camera.CFrame.LookVector end
                        if UIS:IsKeyDown(Enum.KeyCode.S) then kd = kd - Camera.CFrame.LookVector end
                        if UIS:IsKeyDown(Enum.KeyCode.A) then kd = kd - Camera.CFrame.RightVector end
                        if UIS:IsKeyDown(Enum.KeyCode.D) then kd = kd + Camera.CFrame.RightVector end
                        if kd.Magnitude > 0 then dir = kd.Unit end
                    end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
                    fly_bv.Velocity = dir * cfg.fly_speed
                    fly_bg.CFrame = Camera.CFrame
                end
            end
        else
            if fly_bv then set_fly(false) end
        end

        esp_accum = esp_accum + dt
        if esp_accum < 0.05 then return end
        esp_accum = 0

        if not cfg.esp then return end

        local vp_size = Camera.ViewportSize
        local cam_pos = Camera.CFrame.Position
        local players = Players:GetPlayers()

        for _, plr in ipairs(players) do
            if plr ~= LP then
                local ch = plr.Character
                local head = ch and ch:FindFirstChild("Head")
                local hum2 = ch and ch:FindFirstChildOfClass("Humanoid")
                local show = head and hum2 and hum2.Health > 0
                if show and cfg.team_check and plr.Team and LP.Team and plr.Team == LP.Team then show = false end
                local dist = 0
                if show and head then
                    dist = (cam_pos - head.Position).Magnitude
                    if dist > 1500 then show = false end
                end
                if not show then
                    if esp_drawings[plr] then
                        esp_drawings[plr].line.Visible = false
                        esp_drawings[plr].name.Visible = false
                        esp_drawings[plr].dist.Visible = false
                    end
                    if esp_hl[plr] then esp_hl[plr].Enabled = false end
                else
                    local sp, on = Camera:WorldToViewportPoint(head.Position)
                    if on and sp.Z > 0 then
                        local hl = esp_hl[plr]
                        if not hl or hl.Adornee ~= ch then
                            if hl then hl:Destroy() end
                            hl = Instance.new("Highlight")
                            hl.Name = "LOKI_ESP"
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Adornee = ch
                            hl.Parent = esp_folder
                            esp_hl[plr] = hl
                        end
                        hl.Enabled = true
                        local is_k = is_killer(plr)
                        local col
                        if is_k then col = C.killer
                        elseif plr.Team and LP.Team and plr.Team == LP.Team then col = C.accent
                        else col = C.esp_green end
                        if hl.FillColor ~= col then hl.FillColor = col; hl.OutlineColor = col end
                        local targetFill = cfg.esp_body and 0.5 or 1
                        if hl.FillTransparency ~= targetFill then hl.FillTransparency = targetFill end
                        if hl.OutlineTransparency ~= 0 then hl.OutlineTransparency = 0 end
                        if Drawing then
                            local d = esp_drawings[plr]
                            if not d then
                                d = { line = Drawing.new("Line"), name = Drawing.new("Text"), dist = Drawing.new("Text") }
                                d.name.Center = true; d.name.Outline = true; d.name.Size = 14; d.name.Font = 2
                                d.dist.Center = true; d.dist.Outline = true; d.dist.Size = 12; d.dist.Font = 2
                                esp_drawings[plr] = d
                            end
                            if cfg.esp_lines then
                                d.line.Visible = true
                                d.line.From = Vector2.new(vp_size.X / 2, vp_size.Y)
                                d.line.To = Vector2.new(sp.X, sp.Y)
                                d.line.Color = col
                                d.line.Thickness = is_k and 2 or 1
                            else d.line.Visible = false end
                            if cfg.esp_name then
                                d.name.Visible = true
                                d.name.Text = is_k and ("KILLER " .. plr.Name) or plr.Name
                                d.name.Position = Vector2.new(sp.X, sp.Y - 20)
                                d.name.Color = col
                                d.name.Size = is_k and 16 or 14
                            else d.name.Visible = false end
                            if cfg.esp_dist then
                                d.dist.Visible = true
                                if is_k then
                                    local remaining = math.floor((killer_marks[plr] or 0) - os.clock())
                                    if remaining < 0 then remaining = 0 end
                                    d.dist.Text = math.floor(dist) .. "m · " .. remaining .. "s"
                                else d.dist.Text = math.floor(dist) .. "m" end
                                d.dist.Position = Vector2.new(sp.X, sp.Y + 15)
                                d.dist.Color = col
                            else d.dist.Visible = false end
                        end
                    else
                        if esp_drawings[plr] then
                            esp_drawings[plr].line.Visible = false
                            esp_drawings[plr].name.Visible = false
                            esp_drawings[plr].dist.Visible = false
                        end
                        if esp_hl[plr] then esp_hl[plr].Enabled = false end
                    end
                end
            end
        end
    end)

    local function get_target()
        local center = Camera.ViewportSize / 2
        local cam_pos = Camera.CFrame.Position
        local cam_look = Camera.CFrame.LookVector
        local my_char = LP.Character
        local my_pos = my_char and my_char:FindFirstChild("HumanoidRootPart") and my_char.HumanoidRootPart.Position
        if not my_pos then return nil end
        local best, best_score, best_plr = nil, math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if is_enemy(plr) and alive(plr) then
                local ch = plr.Character
                local part = ch:FindFirstChild(cfg.target_part) or ch:FindFirstChild("Head")
                if part and part:IsA("BasePart") then
                    local dist3d = (part.Position - my_pos).Magnitude
                    if dist3d >= cfg.aimbot_min_dist and dist3d <= cfg.aimbot_max_dist then
                        local dir = (part.Position - cam_pos).Unit
                        if cam_look:Dot(dir) > 0.4 then
                            local sp, on = Camera:WorldToViewportPoint(part.Position)
                            if on and sp.Z > 0 then
                                local fov_dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if fov_dist < cfg.fov_radius and (not cfg.wall_check or los_clear(plr, part)) then
                                    local score
                                    if cfg.aimbot_priority == "Closest" then score = dist3d
                                    elseif cfg.aimbot_priority == "FOV" then score = fov_dist
                                    else
                                        local fov_norm = fov_dist / math.max(cfg.fov_radius, 1)
                                        score = dist3d + fov_norm * cfg.aimbot_angle_weight
                                    end
                                    if score < best_score then best_score = score; best = part; best_plr = plr end
                                end
                            end
                        end
                    end
                end
            end
        end
        return best, best_plr
    end

    local function get_nearest_enemy()
        local my_char = LP.Character
        if not my_char then return nil end
        local my_hrp = my_char:FindFirstChild("HumanoidRootPart")
        if not my_hrp then return nil end
        local best, best_d = nil, cfg.tp_max_dist
        for _, plr in ipairs(Players:GetPlayers()) do
            if is_enemy(plr) and alive(plr) then
                local ch = plr.Character
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                local h = ch:FindFirstChildOfClass("Humanoid")
                if hrp and h and h.Health > 0 and hrp.Position.Y > -50 then
                    local d = (hrp.Position - my_hrp.Position).Magnitude
                    if d < best_d then best_d = d; best = plr end
                end
            end
        end
        return best
    end

    local tp_running = false
    local function do_tp_aim(tplr)
        if not tplr or not tplr.Character then return false end
        local tgt_head = tplr.Character:FindFirstChild("Head")
        local tgt_hrp = tplr.Character:FindFirstChild("HumanoidRootPart")
        local tgt_hum = tplr.Character:FindFirstChildOfClass("Humanoid")
        if not tgt_head or not tgt_head:IsA("BasePart") then return false end
        if not tgt_hrp or not tgt_hum or tgt_hum.Health <= 0 then return false end
        if tgt_head.Position.Y < -50 then return false end
        if cfg.tp_only_grounded then
            if tgt_hum.FloorMaterial == Enum.Material.Air then return false end
            if tgt_hrp.AssemblyLinearVelocity.Y < -50 then return false end
        end
        local my_char = LP.Character
        if not my_char then return false end
        local my_hrp = my_char:FindFirstChild("HumanoidRootPart")
        local my_hum = my_char:FindFirstChildOfClass("Humanoid")
        if not my_hrp or not my_hum then return false end
        if my_hum.FloorMaterial ~= Enum.Material.Air and my_hrp.Position.Y > -50 then
            last_safe_pos = my_hrp.Position
        end
        local dy = tgt_head.Position.Y - my_hrp.Position.Y
        if dy < -80 then return false end
        local now = os.clock()
        if now - last_tp_t > 0.15 then
            last_tp_t = now
            local dest = CFrame.new(tgt_head.Position + Vector3.new(0, 3.5, 0))
            if cfg.tp_smooth then
                if not tp_running then
                    tp_running = true
                    task.spawn(function()
                        local start_cf = my_hrp.CFrame
                        -- tp_smooth_ms em ms → converter para segundos
                        local duration = (cfg.tp_smooth_ms or 120) / 1000
                        local steps = math.floor(duration / 0.03)
                        if steps < 2 then steps = 2 end
                        for i = 1, steps do
                            if not my_hrp.Parent or not my_char.Parent then break end
                            local alpha = i / steps
                            my_hrp.CFrame = start_cf:Lerp(dest, alpha)
                            RunService.RenderStepped:Wait()
                        end
                        tp_running = false
                    end)
                end
            else
                pcall(function() my_hrp.CFrame = dest end)
            end
        end
        pcall(function() my_hrp.AssemblyLinearVelocity = Vector3.zero; my_hrp.AssemblyAngularVelocity = Vector3.zero end)
        if Camera.CameraType ~= Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Scriptable end
        local cam_origin = my_hrp.Position + Vector3.new(0, 1.5, 0)
        pcall(function() Camera.CFrame = CFrame.new(cam_origin, tgt_head.Position) end)
        return true
    end

    RunService:BindToRenderStep("LOKI_AIM", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if intro_active then return end
        local trigger = rmb_down or (cfg.mobile_aim and touch_active)
        if cfg.tp_auto then
            local now = os.clock()
            if not tp_current_target or not alive(tp_current_target) or (now - tp_target_start > cfg.tp_cycle_rate) then
                tp_current_target = get_nearest_enemy(); tp_target_start = now
            end
            if tp_current_target and do_tp_aim(tp_current_target) then return end
        end
        if cfg.tp_aim and trigger then
            local tplr = get_nearest_enemy()
            if tplr and do_tp_aim(tplr) then return end
        end
        if not (cfg.aimbot and trigger) then return end
        local target = get_target()
        if not target then return end
        local tpos = target.CFrame.Position
        if cfg.prediction then
            local vel = target.AssemblyLinearVelocity
            if vel.Magnitude > 0.5 then
                local dist = (tpos - Camera.CFrame.Position).Magnitude
                local travel_time = dist / 2000
                tpos = tpos + vel * travel_time
            end
        end
        if cfg.aim_jitter then 
            tpos = tpos + Vector3.new((math.random() - 0.5) * 0.05, (math.random() - 0.5) * 0.05, (math.random() - 0.5) * 0.05) 
        end
        local alpha = math.clamp((dt * 60) / math.max(cfg.smoothing, 1), 0.05, 1)
        if mousemoverel then
            local sp, on = Camera:WorldToViewportPoint(tpos)
            if on and sp.Z > 0 then
                local center = Camera.ViewportSize / 2
                local delta = Vector2.new(sp.X, sp.Y) - center
                if delta.Magnitude > 0.5 then pcall(mousemoverel, delta.X * alpha, delta.Y * alpha) end
            end
        else
            local cam_pos = Camera.CFrame.Position
            local currentLook = Camera.CFrame.LookVector
            local targetDir = (tpos - cam_pos).Unit
            local newDir = currentLook:Lerp(targetDir, alpha)
            Camera.CFrame = CFrame.lookAt(cam_pos, cam_pos + newDir)
        end
    end)

    RunService.Heartbeat:Connect(function()
        if intro_active then return end
        if not cfg.auto_fire then return end
        local trigger = lmb_down or touch_active
        if not trigger then return end
        try_fire()
    end)

    LP.Idled:Connect(function()
        if cfg.anti_afk then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController(); vu:ClickButton2(Vector2.new())
            end)
        end
    end)

    local function open_menu()
        cfg.menu_state = "open"; main.Visible = true
        if main.Size == UDim2.new(0, 0, 0, 0) then
            main.BackgroundTransparency = 1; main.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, MAIN_W, 0, MAIN_H), BackgroundTransparency = 0.05
            }):Play()
            flash(main, C.accent)
        else
            TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, MAIN_W, 0, MAIN_H), BackgroundTransparency = 0.05
            }):Play()
        end
    end
    local function minimize_menu()
        cfg.menu_state = "minimized"
        TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, MAIN_W, 0, TITLE_H), BackgroundTransparency = 0.05
        }):Play()
        spawn_dust(main, MAIN_W / 2, TITLE_H, C.accent, 8)
    end
    local function close_menu()
        cfg.menu_state = "closed"
        spawn_dust(main, MAIN_W / 2, MAIN_H / 2, C.accent, 15)
        local t = TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1
        })
        t:Play()
        t.Completed:Connect(function() if cfg.menu_state == "closed" then main.Visible = false end end)
    end
    min_btn.MouseButton1Click:Connect(function() if cfg.menu_state == "open" then minimize_menu() else open_menu() end end)
    close_btn.MouseButton1Click:Connect(close_menu)

    UIS.InputBegan:Connect(function(input, gp)
        if cfg.waiting_key and input.UserInputType == Enum.UserInputType.Keyboard then
            cfg.menu_key = input.KeyCode
            key_lbl.Text = "Tecla Atual: " .. input.KeyCode.Name
            key_lbl.TextColor3 = C.text
            cfg.waiting_key = false
            return
        end
        if input.KeyCode == cfg.menu_key then
            if cfg.menu_state == "open" then minimize_menu() else open_menu() end
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if esp_hl[plr] then pcall(function() esp_hl[plr]:Destroy() end); esp_hl[plr] = nil end
        if esp_drawings[plr] then 
            pcall(function() esp_drawings[plr].line:Remove() end)
            pcall(function() esp_drawings[plr].name:Remove() end)
            pcall(function() esp_drawings[plr].dist:Remove() end)
            esp_drawings[plr] = nil 
        end
        los_cache[plr] = nil
        killer_marks[plr] = nil
    end)

    -- INTRO
    local intro = Instance.new("Frame")
    intro.Size = UDim2.new(1, 0, 1, 0); intro.BackgroundColor3 = Color3.new(0, 0, 0)
    intro.BackgroundTransparency = 0; intro.BorderSizePixel = 0; intro.ZIndex = 200; intro.Parent = gui

    local intro_grid = Instance.new("Frame")
    intro_grid.Size = UDim2.new(1, 0, 1, 0); intro_grid.BackgroundTransparency = 1
    intro_grid.ZIndex = 200; intro_grid.Parent = intro
    for i = 0, 24 do
        local h = Instance.new("Frame")
        h.Size = UDim2.new(1, 0, 0, 1); h.Position = UDim2.new(0, 0, i / 24, 0)
        h.BackgroundColor3 = C.accent; h.BackgroundTransparency = 1
        h.BorderSizePixel = 0; h.ZIndex = 200; h.Parent = intro_grid
        local v = Instance.new("Frame")
        v.Size = UDim2.new(0, 1, 1, 0); v.Position = UDim2.new(i / 24, 0, 0, 0)
        v.BackgroundColor3 = C.accent; v.BackgroundTransparency = 1
        v.BorderSizePixel = 0; v.ZIndex = 200; v.Parent = intro_grid
        task.delay(i * 0.02, function()
            if h.Parent then
                TweenService:Create(h, TweenInfo.new(0.5), { BackgroundTransparency = 0.93 }):Play()
                TweenService:Create(v, TweenInfo.new(0.5), { BackgroundTransparency = 0.93 }):Play()
            end
        end)
    end

    local intro_tree = Instance.new("Frame")
    intro_tree.Size = UDim2.new(0, 500, 0, 500); intro_tree.AnchorPoint = Vector2.new(0.5, 0.5)
    intro_tree.Position = UDim2.new(0.5, 0, 0.5, 0); intro_tree.BackgroundTransparency = 1
    intro_tree.ZIndex = 201; intro_tree.Parent = intro

    local intro_segs = {}
    local function intro_branch(start, dir, len, depth)
        local finish = start + dir * len
        local d = finish - start
        if d.Magnitude < 0.5 then return end
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0, 0.5); f.Position = UDim2.fromOffset(start.X, start.Y)
        f.Size = UDim2.new(0, 0, 0, math.max(1, depth * 0.8))
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
        f.BackgroundColor3 = (depth % 2 == 0) and C.accent or C.purple
        f.BorderSizePixel = 0; f.ZIndex = 201; f.Parent = intro_tree
        table.insert(intro_segs, { frame = f, target_w = d.Magnitude })
        if depth > 0 then
            intro_branch(finish, rot2d(dir, 0.4 + math.random() * 0.1), len * 0.72, depth - 1)
            intro_branch(finish, rot2d(dir, -0.42 - math.random() * 0.1), len * 0.72, depth - 1)
        end
    end
    intro_branch(Vector2.new(250, 250), Vector2.new(0, -1), 22, 5)
    intro_branch(Vector2.new(250, 250), Vector2.new(0, 1), 16, 5)
    intro_branch(Vector2.new(250, 250), Vector2.new(-1, 0.2), 16, 4)
    intro_branch(Vector2.new(250, 250), Vector2.new(1, -0.2), 16, 4)

    local letters = {}
    local word = {"L", "O", "K", "I"}
    local letter_spacing = 100
    local start_x_letters = -(#word - 1) * letter_spacing / 2
    for i, ch in ipairs(word) do
        local ml = Instance.new("TextLabel")
        ml.Text = ch; ml.Size = UDim2.new(0, 100, 0, 120)
        ml.Position = UDim2.new(0.5, start_x_letters + (i - 1) * letter_spacing - 50, 0.5, -70 - 350)
        ml.BackgroundTransparency = 1; ml.TextColor3 = Color3.fromRGB(130, 255, 175)
        ml.Font = Enum.Font.GothamBlack; ml.TextSize = 100
        ml.TextTransparency = 1; ml.ZIndex = 205; ml.Parent = intro
        local stk = Instance.new("UIStroke", ml)
        stk.Color = C.accent; stk.Thickness = 4; stk.Transparency = 1

        local red = ml:Clone()
        red.TextColor3 = Color3.fromRGB(255, 40, 60)
        red.Position = ml.Position + UDim2.new(0, -8, 0, 0)
        red.ZIndex = 204
        if red:FindFirstChildOfClass("UIStroke") then red:FindFirstChildOfClass("UIStroke"):Destroy() end
        red.Parent = intro

        local blue = ml:Clone()
        blue.TextColor3 = Color3.fromRGB(40, 100, 255)
        blue.Position = ml.Position + UDim2.new(0, 8, 0, 0)
        blue.ZIndex = 204
        if blue:FindFirstChildOfClass("UIStroke") then blue:FindFirstChildOfClass("UIStroke"):Destroy() end
        blue.Parent = intro

        letters[i] = {
            main = ml, red = red, blue = blue, stroke = stk,
            target = UDim2.new(0.5, start_x_letters + (i - 1) * letter_spacing - 50, 0.5, -70)
        }
    end

    local intro_ver = Instance.new("TextLabel")
    intro_ver.Text = LOKI_VERSION; intro_ver.Size = UDim2.new(1, 0, 0, 20)
    intro_ver.Position = UDim2.new(0, 0, 0.5, 70); intro_ver.BackgroundTransparency = 1
    intro_ver.TextColor3 = C.accent_g; intro_ver.Font = Enum.Font.GothamBold
    intro_ver.TextSize = 16; intro_ver.TextTransparency = 1
    intro_ver.ZIndex = 205; intro_ver.Parent = intro

    local function shake_intro(duration, intensity)
        task.spawn(function()
            local t0 = os.clock()
            while os.clock() - t0 < duration and intro.Parent do
                intro.Position = UDim2.fromOffset(
                    (math.random() - 0.5) * intensity,
                    (math.random() - 0.5) * intensity
                )
                RunService.RenderStepped:Wait()
            end
            if intro.Parent then intro.Position = UDim2.fromOffset(0, 0) end
        end)
    end

    task.spawn(function()
        play_sfx("intro_start", 1.0, 0.85)
        task.wait(0.15)
        local scr = gui.AbsoluteSize
        local cx0, cy0 = scr.X / 2, scr.Y / 2

        for _ = 1, 100 do
            local d = Instance.new("Frame")
            d.Position = UDim2.fromOffset(math.random() * scr.X, -100)
            d.Size = UDim2.new(0, 2, 0, math.random(20, 100))
            d.BackgroundColor3 = (math.random() > 0.5) and C.accent or C.purple
            d.BackgroundTransparency = math.random(20, 80) / 100
            d.BorderSizePixel = 0; d.ZIndex = 202; d.Parent = intro
            local t = TweenService:Create(d, TweenInfo.new(0.4 + math.random() * 1.0, Enum.EasingStyle.Linear), {
                Position = UDim2.fromOffset(d.Position.X.Offset, scr.Y + 100),
                BackgroundTransparency = 1
            })
            t:Play(); t.Completed:Connect(function() d:Destroy() end)
        end

        for _ = 1, 60 do
            local ang = math.random() * math.pi * 2
            local dist = 200 + math.random() * 500
            local sx = cx0 + math.cos(ang) * dist
            local sy = cy0 + math.sin(ang) * dist
            local p = Instance.new("Frame")
            p.Position = UDim2.fromOffset(sx, sy); p.Size = UDim2.new(0, 4, 0, 4)
            p.BackgroundColor3 = C.accent_g; p.BorderSizePixel = 0
            p.ZIndex = 203; p.Parent = intro
            Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
            local t = TweenService:Create(p, TweenInfo.new(0.5 + math.random() * 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.fromOffset(cx0, cy0), Size = UDim2.new(0, 1, 0, 1),
                BackgroundTransparency = 1
            })
            t:Play(); t.Completed:Connect(function() p:Destroy() end)
        end

        task.wait(0.35)
        play_sfx("intro_thunder", 0.9, 0.9)
        shake_intro(0.3, 6)
        for _ = 1, 15 do
            local col = (math.random() > 0.5) and C.accent or C.purple
            spawn_bolt(intro, cx0 + (math.random() - 0.5) * 500, cy0 + (math.random() - 0.5) * 500, col, 3)
            task.wait(0.03)
        end

        for i = 1, 6 do
            task.delay(i * 0.1, function()
                local ring = Instance.new("Frame")
                ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.new(0.5, 0, 0.5, 0)
                ring.Size = UDim2.new(0, 10, 0, 10); ring.BackgroundTransparency = 1
                ring.BorderSizePixel = 0; ring.ZIndex = 203; ring.Parent = intro
                Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
                local stk = Instance.new("UIStroke", ring)
                stk.Color = (i % 2 == 0) and C.accent or C.purple
                stk.Thickness = 4; stk.Transparency = 0.1
                TweenService:Create(ring, TweenInfo.new(1.5, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 1000, 0, 1000) }):Play()
                TweenService:Create(stk, TweenInfo.new(1.5, Enum.EasingStyle.Quad), { Transparency = 1, Thickness = 0.1 }):Play()
                task.delay(1.6, function() if ring.Parent then ring:Destroy() end end)
            end)
        end

        for i, s in ipairs(intro_segs) do
            task.delay(i * 0.01, function()
                if s.frame.Parent then
                    TweenService:Create(s.frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, s.target_w, 0, s.frame.Size.Y.Offset)
                    }):Play()
                end
            end)
        end

        task.wait(0.55)

        for i, L in ipairs(letters) do
            task.delay((i - 1) * 0.12, function()
                TweenService:Create(L.main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    TextTransparency = 0, Position = L.target
                }):Play()
                TweenService:Create(L.red, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    TextTransparency = 0.45, Position = L.target + UDim2.new(0, -8, 0, 0)
                }):Play()
                TweenService:Create(L.blue, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    TextTransparency = 0.45, Position = L.target + UDim2.new(0, 8, 0, 0)
                }):Play()
                TweenService:Create(L.stroke, TweenInfo.new(0.4), { Transparency = 0.15 }):Play()
                local lx = cx0 + L.target.X.Offset + 50
                local ly = cy0 + L.target.Y.Offset + 60
                spawn_bolt(intro, lx, ly, C.accent_g, 3)
                spawn_dust(intro, lx, ly, C.accent, 8)
                play_sfx("ui_click", 0.4, 1.4)
            end)
        end

        task.wait(0.7)
        TweenService:Create(intro_ver, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
        task.wait(0.4)

        play_sfx("intro_flash", 1.0, 0.8)
        shake_intro(0.4, 10)
        for _ = 1, 12 do
            local col = (math.random() > 0.5) and C.accent or C.purple
            spawn_bolt(intro, cx0 + (math.random() - 0.5) * 600, cy0 + (math.random() - 0.5) * 600, col, 4)
            task.wait(0.03)
        end

        scanline_pass(intro, C.accent_g, 4, 0.5)

        local white = Instance.new("Frame")
        white.Size = UDim2.new(1, 0, 1, 0); white.BackgroundColor3 = Color3.fromRGB(230, 255, 240)
        white.BackgroundTransparency = 0.05; white.BorderSizePixel = 0
        white.ZIndex = 210; white.Parent = intro
        TweenService:Create(white, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
        task.delay(0.6, function() if white.Parent then white:Destroy() end end)

        task.wait(0.6)

        TweenService:Create(intro, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
        for _, L in ipairs(letters) do
            task.spawn(function()
                TweenService:Create(L.main, TweenInfo.new(0.4), { TextTransparency = 1, Position = L.target + UDim2.new(0, 0, 0, -40) }):Play()
                TweenService:Create(L.red, TweenInfo.new(0.4), { TextTransparency = 1, Position = L.target + UDim2.new(0, -40, 0, -40) }):Play()
                TweenService:Create(L.blue, TweenInfo.new(0.4), { TextTransparency = 1, Position = L.target + UDim2.new(0, 40, 0, -40) }):Play()
                TweenService:Create(L.stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
            end)
        end
        TweenService:Create(intro_ver, TweenInfo.new(0.5), { TextTransparency = 1, Position = UDim2.new(0, 0, 0.4, 70) }):Play()
        for _, s in ipairs(intro_segs) do
            task.spawn(function()
                if s.frame.Parent then
                    TweenService:Create(s.frame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
                end
            end)
        end

        task.wait(0.7)
        intro:Destroy()
        intro_active = false
        switch_tab("VISUAL")
        open_menu()
        play_sfx("ui_click", 0.5, 1.4)
    end)

    print("[LOKI " .. LOKI_VERSION .. "] DONE")
end)

if not ok then
    print("[LOKI " .. LOKI_VERSION .. "] ERRO FATAL: " .. tostring(err))
end
