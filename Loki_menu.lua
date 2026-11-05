-- language: Lua, file: loki_v20.lua, target: Universal
local LOKI_VERSION = "v20"
print("[LOKI " .. LOKI_VERSION .. "] start")

local genv = (getgenv and getgenv()) or _G
if genv.LOKI_CLEAN then pcall(genv.LOKI_CLEAN) end
local conns = {}
local function track(c) conns[#conns + 1] = c; return c end

local ok, err = pcall(function()
    local Players      = game:GetService("Players")
    local RunService   = game:GetService("RunService")
    local UIS          = game:GetService("UserInputService")
    local Workspace    = game:GetService("Workspace")
    local TweenService = game:GetService("TweenService")
    local Lighting     = game:GetService("Lighting")
    local TS           = game:GetService("TeleportService")
    local SoundService = game:GetService("SoundService")

    local mousemoverel = genv.mousemoverel or mousemoverel
    local mouse1click_fn = genv.mouse1click or mouse1click
    local CoreGui = game:GetService("CoreGui")
    if gethui then
        local okh, h = pcall(gethui)
        if okh and typeof(h) == "Instance" then CoreGui = h end
    end

    repeat task.wait() until Players.LocalPlayer
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
        orange = Color3.fromRGB(255, 160, 40),
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

    local function make_circle(color, thick, transp)
        local fr = Instance.new("Frame")
        fr.AnchorPoint = Vector2.new(0.5, 0.5); fr.Position = UDim2.new(0.5, 0, 0.5, 0)
        fr.Size = UDim2.new(0, 400, 0, 400); fr.BackgroundTransparency = 1
        fr.BorderSizePixel = 0; fr.Visible = false; fr.Parent = gui
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0.5, 0)
        local st = Instance.new("UIStroke", fr)
        st.Thickness = thick; st.Color = color; st.Transparency = transp
        return fr, st
    end

    local fov_overlay, fov_stroke = make_circle(C.accent, 2, 0.15)
    local fov_glow = Instance.new("UIStroke", fov_overlay)
    fov_glow.Thickness = 6; fov_glow.Color = C.accent; fov_glow.Transparency = 0.85
    local wp_overlay = make_circle(C.purple, 2, 0.3)
    local sil_overlay = make_circle(C.orange, 2, 0.25)

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
                elseif pos < 2 * MAIN_W + MAIN_H then x, y = MAIN_W - (pos - MAIN_W - MAIN_H), MAIN_H
                else x, y = 0, MAIN_H - (pos - 2 * MAIN_W - MAIN_H) end
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
        btn.Size = UDim2.new(0, width or 60, 1, 0); btn.BackgroundColor3 = C.bg2
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
    local silent_frame = create_tab("SILENT")
    local move_frame = create_tab("MOVIM")
    local risk_frame = create_tab("RISCO")

    local cfg = {
        esp = true, team_check = false, wall_check = false,
        esp_name = true, esp_dist = true, esp_lines = false, esp_body = false,
        fullbright = false, no_fog = false,
        aimbot = false, mobile_aim = true, show_fov = true, rainbow_fov = false, prediction = true,
        aim_jitter = false,
        aim_mode = "RMB", aim_method = "Auto",
        target_part = "Head", fov_radius = 150, smoothing = 4, fov_alpha = 15,
        aimbot_min_dist = 5, aimbot_max_dist = 400,
        aimbot_priority = "Smart",
        aimbot_angle_weight = 150,
        wall_pierce = false, wall_pierce_fov = 400, wp_show_fov = false, wp_debug = false,
        enemies_only = true,
        -- silent aim / bala mágica
        silent_aim = false, silent_remote = false, silent_always = true,
        silent_wallcheck = false, silent_show_fov = true,
        silent_fov = 200, silent_hitchance = 100, silent_part = "Head",
        revenge_mark = true,
        revenge_duration = 120,
        revenge_radius = 200,
        revenge_los_radius = 500,
        revenge_max_suspects = 1,
        -- TP
        tp_aim = false, tp_auto = false, tp_autofire = true,
        tp_only_grounded = false, tp_smooth = true, tp_smooth_ms = 120,
        tp_cycle_rate = 0, tp_max_dist = 2000,
        tp_pos = "Cima", tp_height = 4,
        auto_fire = false, fire_delay_ms = 100,
        god = false,
        walkspeed = 16, jumppower = 50,
        noclip = false, infjump = false, fly = false, fly_speed = 50,
        anti_afk = false,
        menu_key = Enum.KeyCode.RightShift,
        waiting_key = false,
        menu_state = "open",
    }

    local esp_hl, esp_drawings, los_cache = {}, {}, {}
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
    local orig = {
        Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows,
    }

    -- estado compartilhado com os hooks (persistente entre reexecuções)
    local S = genv.LOKI_S or {}
    genv.LOKI_S = S
    S.on = false; S.target = nil; S.pos = Vector3.zero; S.vp = nil; S.sc = nil
    S.fire_t = 0; S.busy = false; S.hit = true; S.roll_t = 0
    S.ws = Workspace; S.cam = Camera; S.mouse = LP:GetMouse()
    S.always = true; S.remote = false

    -- ===== REVENGE =====
    local event_log = {}
    local function log_event(msg)
        print("[LOKI] " .. msg)
        table.insert(event_log, 1, { msg = msg, time = os.clock() })
        if #event_log > 20 then table.remove(event_log) end
    end

    local killer_marks = {}
    local damage_events = {}
    local last_hp_seen = 100
    local last_my_pos = Vector3.new(0, 50, 0)
    local last_damage_clock = 0
    local last_attacker = nil
    local last_attacker_time = 0
    local last_dmg_record = 0
    local suppress_until = 0

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
                    if d <= max_dist and d > 0.01 then
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
           and last_attacker.Parent
           and last_attacker.Character
           and last_attacker.Character:FindFirstChildOfClass("Humanoid")
           and last_attacker.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
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

    local was_alive = false
    task.spawn(function()
        while gui.Parent do
            local char = LP.Character
            local h = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then last_my_pos = hrp.Position end
            if h then
                local hp = h.Health
                if hp > 0 then
                    if not was_alive then last_hp_seen = hp; damage_events = {} end
                    was_alive = true
                    if hp < last_hp_seen - 0.5 then
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
                    last_hp_seen = hp
                elseif was_alive then
                    was_alive = false
                    if os.clock() > suppress_until then handle_death(last_my_pos) end
                end
            elseif was_alive then
                was_alive = false
                if os.clock() > suppress_until then handle_death(last_my_pos) end
            end
            task.wait(0.25)
        end
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
        local track_f = Instance.new("Frame")
        track_f.Size = UDim2.new(1, -20, 0, 4); track_f.Position = UDim2.new(0, 10, 0, 30)
        track_f.BackgroundColor3 = C.bg3; track_f.BorderSizePixel = 0; track_f.Parent = f
        Instance.new("UICorner", track_f).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((math.floor(cfg[key] + 0.5) - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = C.accent; fill.BorderSizePixel = 0; fill.Parent = track_f
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12); knob.Position = UDim2.new(fill.Size.X.Scale, -6, 0.5, -6)
        knob.BackgroundColor3 = C.accent_g; knob.BorderSizePixel = 0; knob.Parent = track_f
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local knob_stroke = Instance.new("UIStroke", knob)
        knob_stroke.Color = C.accent; knob_stroke.Thickness = 2; knob_stroke.Transparency = 0.5
        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 0); hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = track_f
        local dragging = false
        local function set_val(px)
            local pos = math.clamp((px - track_f.AbsolutePosition.X) / math.max(track_f.AbsoluteSize.X, 1), 0, 1)
            local v = math.floor(min + (max - min) * pos + 0.5)
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
            set_val(UIS:GetMouseLocation().X)
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                set_val(i.Position.X)
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
        local hrp = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
        if not hrp then return false end
        local h = ch:FindFirstChildOfClass("Humanoid")
        if h then return h.Health > 0 and hrp end
        return hrp
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

    local function aim_origin()
        if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
            or (UIS.TouchEnabled and not UIS.MouseEnabled) then
            return Camera.ViewportSize / 2
        end
        return UIS:GetMouseLocation()
    end

    local function cursor_over_menu()
        if not main.Visible then return false end
        local m = UIS:GetMouseLocation()
        local p, s = main.AbsolutePosition, main.AbsoluteSize
        return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
    end

    -- tiro: Tool:Activate + clique real (se o executor tiver) ou VirtualUser
    local function try_fire()
        local now = os.clock()
        local delay = math.max((cfg.fire_delay_ms or 100) / 1000, 0.05)
        if now - last_fire_t < delay then return false end
        last_fire_t = now
        S.fire_t = now + 0.3
        local char = LP.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
        if not cursor_over_menu() then
            if mouse1click_fn then
                pcall(mouse1click_fn)
            else
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:ClickButton1(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
                end)
            end
        end
        return true
    end

    section("VISUAL", visual_frame)
    toggle("ESP (Highlight)", "esp", visual_frame)
    toggle("ESP Corpo Inteiro", "esp_body", visual_frame)
    toggle("ESP Nome", "esp_name", visual_frame)
    toggle("ESP Distancia", "esp_dist", visual_frame)
    toggle("ESP Linhas (Tracers)", "esp_lines", visual_frame)
    toggle("Team Check ESP", "team_check", visual_frame)
    toggle("Wall Check", "wall_check", visual_frame)
    toggle("Fullbright", "fullbright", visual_frame, function(on)
        if not on then
            Lighting.Brightness = orig.Brightness; Lighting.Ambient = orig.Ambient
            Lighting.OutdoorAmbient = orig.OutdoorAmbient; Lighting.GlobalShadows = orig.GlobalShadows
        end
    end)
    toggle("Sem Fog", "no_fog", visual_frame, function(on)
        if not on then Lighting.FogEnd = orig.FogEnd; Lighting.FogStart = orig.FogStart end
    end)
    task.spawn(function()
        while gui.Parent do
            if cfg.fullbright then
                Lighting.Brightness = 3; Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false
            end
            if cfg.no_fog then
                Lighting.FogEnd = 1e5; Lighting.FogStart = 1e5
                local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                if atm then atm.Density = 0 end
            end
            task.wait(0.5)
        end
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
            show_killer_popup({ test.Name })
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
    log_title.BackgroundTransparency = 1; log_title.Text = "LOG (últimas 6)"
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
    toggle("Aimbot", "aimbot", aim_frame)
    selector("Gatilho", { "RMB", "LMB", "Sempre" }, "aim_mode", aim_frame)
    selector("Método", { "Auto", "Mouse", "Camera" }, "aim_method", aim_frame)
    toggle("Touch Aim", "mobile_aim", aim_frame)
    toggle("Mostrar FOV", "show_fov", aim_frame)
    toggle("Predicao", "prediction", aim_frame)
    toggle("Humanizacao (Jitter)", "aim_jitter", aim_frame)
    slider("FOV", 50, 500, "fov_radius", aim_frame)
    slider("Suavizacao", 1, 10, "smoothing", aim_frame)
    selector("Parte Alvo", { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }, "target_part", aim_frame)

    section("ALCANCE DO AIMBOT", aim_frame)
    slider("Distância Max (studs)", 50, 2000, "aimbot_max_dist", aim_frame)
    slider("Distância Min (studs)", 0, 100, "aimbot_min_dist", aim_frame)
    selector("Prioridade", { "Smart", "Closest", "FOV" }, "aimbot_priority", aim_frame)

    section("SMART MODE (peso)", aim_frame)
    slider("Peso do centro", 0, 500, "aimbot_angle_weight", aim_frame)

    section("WALL PIERCE", aim_frame)
    toggle("Wall Pierce (mira através de parede)", "wall_pierce", aim_frame)
    toggle("Mostrar WP FOV", "wp_show_fov", aim_frame)
    slider("WP FOV", 50, 800, "wall_pierce_fov", aim_frame)

    section("SILENT AIM / BALA MÁGICA", silent_frame, C.orange)
    toggle("Silent Aim (bala na cabeça)", "silent_aim", silent_frame, function(on)
        if on and not genv.LOKI_HOOKED then
            log_event("silent: executor sem hookmetamethod")
        end
    end)
    toggle("Bala Mágica (remotes de tiro)", "silent_remote", silent_frame)
    toggle("Sempre ativo (sem janela de tiro)", "silent_always", silent_frame)
    toggle("Wall Check Silent", "silent_wallcheck", silent_frame)
    toggle("Mostrar FOV Silent", "silent_show_fov", silent_frame)
    slider("FOV Silent", 30, 800, "silent_fov", silent_frame)
    slider("Hit Chance (%)", 1, 100, "silent_hitchance", silent_frame)
    selector("Parte Silent", { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }, "silent_part", silent_frame)

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
        suppress_until = os.clock() + 5
        pcall(function() if fly_bv then fly_bv:Destroy(); fly_bv = nil end; if fly_bg then fly_bg:Destroy(); fly_bg = nil end end)
        pcall(function() h.Health = 0 end); pcall(function() char:BreakJoints() end)
    end, move_frame)
    action_btn("Rejoin servidor", function() pcall(function() TS:Teleport(game.PlaceId, LP) end) end, move_frame)

    section("TP AIM", risk_frame, C.danger)
    toggle("TP Manual (RMB -> cabeça)", "tp_aim", risk_frame, nil, true)
    toggle("TP Auto (sempre, sem apertar nada)", "tp_auto", risk_frame, nil, true)
    toggle("TP Auto Atirar", "tp_autofire", risk_frame, nil, true)
    toggle("TP só se alvo no chão", "tp_only_grounded", risk_frame, nil, true)
    toggle("TP Suave", "tp_smooth", risk_frame, nil, true)
    selector("TP Posição", { "Cima", "Atrás" }, "tp_pos", risk_frame)
    slider("TP Altura/Distância", 1, 15, "tp_height", risk_frame)
    slider("TP Tempo (ms)", 50, 500, "tp_smooth_ms", risk_frame)
    slider("TP Dist Max", 50, 5000, "tp_max_dist", risk_frame)
    slider("TP Trocar alvo (s) 0=fixo", 0, 10, "tp_cycle_rate", risk_frame)

    section("FIRE / GOD", risk_frame, C.danger)
    toggle("Auto Fire (LMB segura)", "auto_fire", risk_frame, nil, true)
    slider("Fire Delay (ms)", 50, 500, "fire_delay_ms", risk_frame)
    toggle("Godmode (teste)", "god", risk_frame, function(on) set_god(on) end, true)

    -- RenderStepped único
    track(RunService.RenderStepped:Connect(function(dt)
        Camera = Workspace.CurrentCamera or Camera
        rmb_down = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        lmb_down = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

        if intro_active then
            fov_overlay.Visible = false; wp_overlay.Visible = false; sil_overlay.Visible = false
            return
        end

        local origin = aim_origin()
        if cfg.show_fov and cfg.aimbot then
            fov_overlay.Visible = true
            fov_overlay.Position = UDim2.fromOffset(origin.X, origin.Y)
            fov_overlay.Size = UDim2.new(0, cfg.fov_radius * 2, 0, cfg.fov_radius * 2)
            local a = math.clamp(cfg.fov_alpha / 100, 0, 1)
            fov_stroke.Transparency = a; fov_glow.Transparency = math.clamp(a + 0.55, 0, 1)
            if cfg.rainbow_fov then
                hue = (hue + 0.005) % 1; local col = Color3.fromHSV(hue, 1, 1); fov_stroke.Color = col; fov_glow.Color = col
            else fov_stroke.Color = C.accent; fov_glow.Color = C.accent end
        else fov_overlay.Visible = false end

        if cfg.wp_show_fov and cfg.wall_pierce and cfg.aimbot then
            wp_overlay.Visible = true
            wp_overlay.Position = UDim2.fromOffset(origin.X, origin.Y)
            wp_overlay.Size = UDim2.new(0, cfg.wall_pierce_fov * 2, 0, cfg.wall_pierce_fov * 2)
        else wp_overlay.Visible = false end

        if cfg.silent_aim and cfg.silent_show_fov then
            sil_overlay.Visible = true
            sil_overlay.Position = UDim2.fromOffset(origin.X, origin.Y)
            sil_overlay.Size = UDim2.new(0, cfg.silent_fov * 2, 0, cfg.silent_fov * 2)
        else sil_overlay.Visible = false end

        if cfg.fly then
            if not fly_bv or not fly_bv.Parent then set_fly(true) end
            if fly_bv and fly_bg and fly_bg.Parent then
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

        if not cfg.esp then
            for _, hl in pairs(esp_hl) do hl.Enabled = false end
            for _, d in pairs(esp_drawings) do
                d.line.Visible = false; d.name.Visible = false; d.dist.Visible = false
            end
            return
        end

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
    end))

    local function get_target()
        local center = aim_origin()
        local cam_pos = Camera.CFrame.Position
        local cam_look = Camera.CFrame.LookVector
        local my_char = LP.Character
        local my_root = my_char and (my_char:FindFirstChild("HumanoidRootPart") or my_char.PrimaryPart)
        if not my_root then return nil end
        local my_pos = my_root.Position
        local fov_limit = cfg.wall_pierce and math.max(cfg.fov_radius, cfg.wall_pierce_fov) or cfg.fov_radius
        local best, best_score, best_plr = nil, math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if is_enemy(plr) and alive(plr) then
                local ch = plr.Character
                local part = ch:FindFirstChild(cfg.target_part) or ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
                if part and part:IsA("BasePart") then
                    local dist3d = (part.Position - my_pos).Magnitude
                    if dist3d >= cfg.aimbot_min_dist and dist3d <= cfg.aimbot_max_dist then
                        local dir = (part.Position - cam_pos).Unit
                        if cam_look:Dot(dir) > 0.4 then
                            local sp, on = Camera:WorldToViewportPoint(part.Position)
                            if on and sp.Z > 0 then
                                local fov_dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                local visible_ok = cfg.wall_pierce or (not cfg.wall_check) or los_clear(plr, part)
                                if fov_dist < fov_limit and visible_ok then
                                    local score
                                    if cfg.aimbot_priority == "Closest" then score = dist3d
                                    elseif cfg.aimbot_priority == "FOV" then score = fov_dist
                                    else score = dist3d + (fov_dist / math.max(fov_limit, 1)) * cfg.aimbot_angle_weight end
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

    -- ================= TP AIM (heartbeat, à prova de falha) =================
    local tp = { target = nil, t0 = 0, active_t = 0, head = nil }

    local function tp_valid(plr)
        if not plr or plr == LP or not plr.Parent then return false end
        if not is_enemy(plr) or not alive(plr) then return false end
        local ch = plr.Character
        local head = ch:FindFirstChild("Head")
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not head or not hrp or not head:IsA("BasePart") then return false end
        if head.Position.Y < -50 then return false end
        if cfg.tp_only_grounded then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h and h.FloorMaterial == Enum.Material.Air then return false end
            if hrp.AssemblyLinearVelocity.Y < -50 then return false end
        end
        return true
    end

    local function tp_pick()
        local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not my then return nil end
        local best, bd = nil, cfg.tp_max_dist
        for _, plr in ipairs(Players:GetPlayers()) do
            if tp_valid(plr) then
                local d = (plr.Character.HumanoidRootPart.Position - my.Position).Magnitude
                if d < bd then bd = d; best = plr end
            end
        end
        return best
    end

    local function tp_tick(dt)
        local manual = cfg.tp_aim and (rmb_down or (cfg.mobile_aim and touch_active))
        if not (cfg.tp_auto or manual) then tp.target = nil; return end
        local char = LP.Character
        local my_hrp = char and char:FindFirstChild("HumanoidRootPart")
        local my_hum = char and char:FindFirstChildOfClass("Humanoid")
        if not my_hrp or not my_hum or my_hum.Health <= 0 then return end

        if my_hum.FloorMaterial ~= Enum.Material.Air and my_hrp.Position.Y > -50 then
            last_safe_pos = my_hrp.Position
        end
        if my_hrp.Position.Y < -100 then
            my_hrp.CFrame = CFrame.new(last_safe_pos + Vector3.new(0, 5, 0))
        end

        local now = os.clock()
        local need = (not tp_valid(tp.target))
            or (cfg.tp_cycle_rate > 0 and now - tp.t0 > cfg.tp_cycle_rate)
        if need then
            local nxt = tp_pick()
            if nxt then tp.target = nxt; tp.t0 = now
            elseif not tp_valid(tp.target) then tp.target = nil end
        end
        local tgt = tp.target
        if not tgt then return end

        local ch = tgt.Character
        local head = ch:FindFirstChild("Head")
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then tp.target = nil; return end

        local dest
        if cfg.tp_pos == "Atrás" then
            local base = hrp.Position - hrp.CFrame.LookVector * cfg.tp_height
            dest = Vector3.new(base.X, head.Position.Y, base.Z)
        else
            dest = head.Position + Vector3.new(0, cfg.tp_height, 0)
        end

        local cf = my_hrp.CFrame
        if cfg.tp_smooth then
            local dur = math.max((cfg.tp_smooth_ms or 120) / 1000, 0.03)
            local a = math.clamp(dt / dur, 0, 1)
            my_hrp.CFrame = CFrame.new(cf.Position:Lerp(dest, a)) * cf.Rotation
        else
            my_hrp.CFrame = CFrame.new(dest) * cf.Rotation
        end
        my_hrp.AssemblyLinearVelocity = Vector3.zero
        my_hrp.AssemblyAngularVelocity = Vector3.zero

        tp.active_t = now; tp.head = head
        if cfg.tp_autofire then try_fire() end
    end

    -- ================= SILENT AIM =================
    local function pick_silent()
        local origin = aim_origin()
        local best, bd = nil, cfg.silent_fov
        for _, plr in ipairs(Players:GetPlayers()) do
            if is_enemy(plr) and alive(plr) then
                local ch = plr.Character
                local part = ch:FindFirstChild(cfg.silent_part) or ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
                if part and part:IsA("BasePart") then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - origin).Magnitude
                        if d < bd and (not cfg.silent_wallcheck or los_clear(plr, part)) then
                            bd = d; best = part
                        end
                    end
                end
            end
        end
        return best
    end

    local function update_silent()
        S.cam = Camera
        S.on = (cfg.silent_aim or cfg.silent_remote) and genv.LOKI_HOOKED == true
        S.remote = cfg.silent_remote
        S.always = cfg.silent_always
        if not (cfg.silent_aim or cfg.silent_remote) then S.target = nil; return end
        local now = os.clock()
        if now - S.roll_t > 0.2 then
            S.roll_t = now
            S.hit = math.random(1, 100) <= cfg.silent_hitchance
        end
        local part = S.hit and pick_silent() or nil
        S.target = part
        if part then
            local pos = part.Position
            S.pos = pos
            local sp = Camera:WorldToViewportPoint(pos)
            S.vp = Vector2.new(sp.X, sp.Y)
            local sc = Camera:WorldToScreenPoint(pos)
            S.sc = Vector2.new(sc.X, sc.Y)
        end
    end

    local function owner_of(inst)
        local cur = inst
        while cur and cur ~= Workspace do
            local p = Players:GetPlayerFromCharacter(cur)
            if p then return p end
            cur = cur.Parent
        end
        return nil
    end

    local SHOT_WORDS = { "shoot", "fire", "hit", "damage", "bullet", "gun", "weapon", "shot", "attack" }
    local function name_is_shot(n)
        n = string.lower(n)
        for _, w in ipairs(SHOT_WORDS) do
            if string.find(n, w, 1, true) then return true end
        end
        return false
    end

    -- origem plausível de tiro: perto da câmera ou da cabeça, raio longo
    S.shot_origin = function(o, d)
        if d.Magnitude < 60 then return false end
        if (o - Camera.CFrame.Position).Magnitude < 15 then return true end
        local ch = LP.Character
        local hd = ch and ch:FindFirstChild("Head")
        return hd ~= nil and (o - hd.Position).Magnitude < 15
    end
    S.redirect = function(o, d)
        local to = S.pos - o
        if to.Magnitude < 0.1 then return d end
        return to.Unit * math.max(d.Magnitude, to.Magnitude + 5)
    end
    S.fix_remote = function(remote, a, n)
        local win = S.always or os.clock() < S.fire_t
        local cam_pos = Camera.CFrame.Position
        local changed = false
        local enemy_pos
        for i = 1, n do
            local v = a[i]
            if typeof(v) == "Instance" then
                local p = owner_of(v)
                if p and p ~= LP and is_enemy(p) then
                    if v:IsA("BasePart") then
                        enemy_pos = v.Position; a[i] = S.target; changed = true
                    elseif v:IsA("Model") then
                        enemy_pos = v:GetPivot().Position; a[i] = S.target.Parent; changed = true
                    end
                end
            end
        end
        local by_name = win and name_is_shot(remote.Name)
        if enemy_pos or by_name then
            for i = 1, n do
                local v = a[i]
                local tv = typeof(v)
                if tv == "Vector3" then
                    if (enemy_pos and (v - enemy_pos).Magnitude < 40)
                        or (not enemy_pos and (v - cam_pos).Magnitude > 25) then
                        a[i] = S.pos; changed = true
                    end
                elseif tv == "CFrame" then
                    local pv = v.Position
                    if (enemy_pos and (pv - enemy_pos).Magnitude < 40)
                        or (not enemy_pos and (pv - cam_pos).Magnitude > 25) then
                        a[i] = CFrame.new(S.pos); changed = true
                    end
                end
            end
        end
        return changed
    end

    -- ================= BIND DE CÂMERA / AIMBOT =================
    local mm_rem = Vector2.zero
    local cam_locked = false
    pcall(function() RunService:UnbindFromRenderStep("LOKI_AIM") end)
    RunService:BindToRenderStep("LOKI_AIM", Enum.RenderPriority.Last.Value, function(dt)
        Camera = Workspace.CurrentCamera or Camera
        if intro_active then return end

        -- câmera do TP: olha pra cabeça do alvo enquanto o TP está ativo
        if tp.head and tp.head.Parent and os.clock() - tp.active_t < 0.2 then
            local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if my then
                local from = my.Position + Vector3.new(0, 1.5, 0)
                if (tp.head.Position - from).Magnitude > 0.1 then
                    cam_locked = true
                    if Camera.CameraType ~= Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Scriptable end
                    Camera.CFrame = CFrame.lookAt(from, tp.head.Position)
                    return
                end
            end
        end
        if cam_locked then
            cam_locked = false
            if Camera.CameraType == Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Custom end
        end

        local trigger
        if cfg.aim_mode == "Sempre" then trigger = true
        elseif cfg.aim_mode == "LMB" then trigger = lmb_down or (cfg.mobile_aim and touch_active)
        else trigger = rmb_down or (cfg.mobile_aim and touch_active) end

        if not (cfg.aimbot and trigger) then mm_rem = Vector2.zero; return end
        local target = get_target()
        if not target then return end

        local tpos = target.Position
        if cfg.prediction then
            local vel = target.AssemblyLinearVelocity
            if vel.Magnitude > 0.5 then
                tpos = tpos + vel * ((tpos - Camera.CFrame.Position).Magnitude / 2000)
            end
        end
        if cfg.aim_jitter then
            tpos = tpos + Vector3.new((math.random() - 0.5) * 0.05, (math.random() - 0.5) * 0.05, (math.random() - 0.5) * 0.05)
        end
        local alpha = math.clamp((dt * 60) / math.max(cfg.smoothing, 1), 0.05, 1)

        local use_mouse = (cfg.aim_method == "Mouse") or (cfg.aim_method == "Auto" and mousemoverel ~= nil)
        if use_mouse and mousemoverel then
            local sp, on = Camera:WorldToViewportPoint(tpos)
            if on and sp.Z > 0 then
                local delta = Vector2.new(sp.X, sp.Y) - aim_origin()
                if delta.Magnitude > 0.5 then
                    local ax, ay = delta.X * alpha + mm_rem.X, delta.Y * alpha + mm_rem.Y
                    local ix, fx = math.modf(ax)
                    local iy, fy = math.modf(ay)
                    mm_rem = Vector2.new(fx, fy)
                    if ix ~= 0 or iy ~= 0 then pcall(mousemoverel, ix, iy) end
                end
            end
        else
            local cam_pos = Camera.CFrame.Position
            local newDir = Camera.CFrame.LookVector:Lerp((tpos - cam_pos).Unit, alpha)
            Camera.CFrame = CFrame.lookAt(cam_pos, cam_pos + newDir)
        end
    end)

    -- ================= HEARTBEAT ÚNICO (tp + silent + auto fire) =================
    local last_err = 0
    local function guarded(name, fn, dt)
        local okf, e = pcall(fn, dt)
        if not okf and os.clock() - last_err > 3 then
            last_err = os.clock()
            log_event(name .. ": " .. string.sub(tostring(e), 1, 70))
        end
    end
    track(RunService.Heartbeat:Connect(function(dt)
        Camera = Workspace.CurrentCamera or Camera
        if intro_active then return end
        guarded("tp", tp_tick, dt)
        guarded("silent", update_silent, dt)
        if cfg.auto_fire and (lmb_down or touch_active) then guarded("fire", try_fire, dt) end
    end))

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
        if tp.target == plr then tp.target = nil end
        if last_attacker == plr then last_attacker = nil end
    end)

    -- ================= HOOKS (silent aim / bala mágica) =================
    if not genv.LOKI_HOOKED and hookmetamethod and getnamecallmethod and checkcaller then
        local nc = newcclosure or function(f) return f end
        local okh = pcall(function()
            local old_nc, old_idx
            old_nc = hookmetamethod(game, "__namecall", nc(function(self, ...)
                local s = genv.LOKI_S
                if not s or not s.on or not s.target or s.busy or checkcaller() then
                    return old_nc(self, ...)
                end
                local method = getnamecallmethod()
                local n = select("#", ...)
                local a
                local changed = false
                local active = s.always or os.clock() < s.fire_t

                if active then
                    if self == s.ws and (method == "Raycast" or method == "FindPartOnRay"
                        or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
                        a = { ... }
                        s.busy = true
                        pcall(function()
                            if method == "Raycast" then
                                local o, d = a[1], a[2]
                                if typeof(o) == "Vector3" and typeof(d) == "Vector3" and s.shot_origin(o, d) then
                                    a[2] = s.redirect(o, d); changed = true
                                end
                            else
                                local r = a[1]
                                if typeof(r) == "Ray" and s.shot_origin(r.Origin, r.Direction) then
                                    a[1] = Ray.new(r.Origin, s.redirect(r.Origin, r.Direction)); changed = true
                                end
                            end
                        end)
                        s.busy = false
                    elseif self == s.cam and s.vp
                        and (method == "ViewportPointToRay" or method == "ScreenPointToRay") then
                        a = { ... }
                        local p = (method == "ViewportPointToRay") and s.vp or s.sc
                        a[1] = p.X; a[2] = p.Y; changed = true
                    end
                end

                if not changed and s.remote and (method == "FireServer" or method == "InvokeServer") then
                    a = { ... }
                    s.busy = true
                    local okc, res = pcall(s.fix_remote, self, a, n)
                    s.busy = false
                    changed = (okc and res) and true or false
                end

                setnamecallmethod(method)
                if changed then return old_nc(self, unpack(a, 1, n)) end
                return old_nc(self, ...)
            end))

            old_idx = hookmetamethod(game, "__index", nc(function(self, key)
                if key == "Hit" or key == "Target" then
                    local s = genv.LOKI_S
                    if s and s.on and s.target and self == s.mouse and not checkcaller()
                        and (s.always or os.clock() < s.fire_t) then
                        if key == "Hit" then return CFrame.new(s.pos) end
                        return s.target
                    end
                end
                return old_idx(self, key)
            end))
        end)
        genv.LOKI_HOOKED = okh and true or false
    end
    if not genv.LOKI_HOOKED then log_event("hooks indisponíveis: silent desligado") end

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
    local word = { "L", "O", "K", "I" }
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
        if intro_active then
            intro:Destroy()
            intro_active = false
            switch_tab("VISUAL")
            open_menu()
            play_sfx("ui_click", 0.5, 1.4)
        end
    end)

    -- failsafe: se a intro falhar, libera tudo depois de 10s
    task.delay(10, function()
        if intro_active then
            intro_active = false
            pcall(function() intro:Destroy() end)
            switch_tab("VISUAL")
            open_menu()
        end
    end)

    genv.LOKI_CLEAN = function()
        S.on = false; S.target = nil
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        pcall(function() RunService:UnbindFromRenderStep("LOKI_AIM") end)
        for _, d in pairs(esp_drawings) do
            for _, o in pairs(d) do pcall(function() o:Remove() end) end
        end
        pcall(function() esp_folder:Destroy() end)
        pcall(function() gui:Destroy() end)
    end

    print("[LOKI " .. LOKI_VERSION .. "] DONE")
end)

if not ok then
    print("[LOKI " .. LOKI_VERSION .. "] ERRO FATAL: " .. tostring(err))
end
