---------------------------------------------------------------------
-- Window
---------------------------------------------------------------------
function SlimeUI:CreateWindow(opts)
    opts = opts or {}

    if env.__SlimeUIWindow then
        pcall(function()
            env.__SlimeUIWindow:Destroy()
        end)
    end

    if opts.Folder then
        SlimeUI.Folder = opts.Folder
    end
    local logoPath = opts.Logo or (SlimeUI.Folder .. "/logo.png")
    local logoUrl = opts.LogoUrl or (opts.Logo == nil and SlimeUI.AssetsUrl and (SlimeUI.AssetsUrl .. "logo.png")) or nil
    if logoUrl then
        EnsureFile(logoPath, logoUrl)
    end

    if opts.KeySystem then
        local ks = opts.KeySystem == true and {} or opts.KeySystem
        ks.Theme = ks.Theme or opts.Theme
        ks.Logo = ks.Logo or opts.Logo
        ks.Title = ks.Title or opts.Title
        ks.Accent = ks.Accent or opts.Accent
        if not self:KeySystem(ks) then
            return Null
        end
    end

    -- Theme
    local themeName = (opts.Theme and Themes[opts.Theme]) and opts.Theme or "Glass"
    Theme.Name = themeName
    Theme.Current = table.clone(Themes[themeName])
    Theme.Objects = {}
    Theme.Hooks = {}
    Theme.AccentOverride = nil
    if opts.Accent then
        local c = (typeof(opts.Accent) == "Color3" and opts.Accent) or Accents[opts.Accent]
        if c then
            Theme.AccentOverride = c
            Theme.Current.Accent = c
            Theme.Current.Accent2 = nil
        end
    end
    table.clear(SlimeUI.Flags)
    table.clear(SlimeUI.Options)

    local LogoImage = ResolveImage(logoPath)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    if type(toggleKey) == "string" then
        toggleKey = Enum.KeyCode[toggleKey]
    end

    local Window = {
        Tabs = {},
        Flags = SlimeUI.Flags,
        Options = SlimeUI.Options,
        Title = opts.Title or "SlimeUI",
        Subtitle = opts.Subtitle or ("by " .. SlimeUI.Author),
        ToggleKey = toggleKey,
        Visible = false,
        Minimized = false,
        Zoomed = false,
        UserScale = 1,
        BlurEnabled = opts.Blur == true,
        _conns = {},
        _binding = false,
    }
    env.__SlimeUIWindow = Window

    local function Connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(Window._conns, c)
        return c
    end

    -- Layout: regular or compact (phones / small screens)
    local vp0 = ViewportSize()
    local compact
    if opts.Compact ~= nil then
        compact = opts.Compact
    else
        compact = IsTouch() or vp0.X < 1000 or vp0.Y < 560
    end
    Window.Compact = compact

    local L = compact and {
        SideW = 66, TabH = 46, RowH = 48, RowDescH = 60, Track = 120, Field = 140, Drop = 140, Notify = 290,
    } or {
        SideW = 214, TabH = 34, RowH = 44, RowDescH = 58, Track = 168, Field = 180, Drop = 170, Notify = 330,
    }
    local BaseSize = opts.Size or Vector2.new(780, 500)
    local ContentX = 8 + L.SideW + 18

    local function TargetSize()
        local v = ViewportSize()
        local s = Window.Zoomed and BaseSize * 1.15 or BaseSize
        if compact or Window.Zoomed then
            s = Vector2.new(math.min(s.X, v.X - 20), math.min(s.Y, v.Y - 20))
        end
        return s
    end

    local function FitScale()
        local v = ViewportSize()
        local s = TargetSize()
        return math.max(0.4, math.min(Window.UserScale, (v.X - 20) / s.X, (v.Y - 20) / s.Y))
    end

    local Gui = NewScreenGui("SlimeUI", 9999)
    Window.Gui = Gui

    -----------------------------------------------------------------
    -- Window frame
    -----------------------------------------------------------------
    local size0 = TargetSize()
    local Holder = New("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size0.X, size0.Y),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = Gui,
    })
    local Scale = New("UIScale", { Scale = FitScale() * 0.92, Parent = Holder })

    -- CanvasGroup: real rounded clipping + fading the whole window
    local Main = New("CanvasGroup", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = 1,
        ZIndex = 1,
        Parent = Holder,
    }, { Corner(20) })
    Bind(Main, { BackgroundColor3 = "Window", BackgroundTransparency = "WindowT" })

    local EdgeFrame = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = Holder,
    }, { Corner(20) })
    local Edge, EdgeGrad = GlassEdge(EdgeFrame, 1.2)
    Edge.Transparency = 1

    -- Top sheen + refraction band (liquid glass)
    local Sheen = New("Frame", {
        Size = UDim2.new(1, 0, 0, 170),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        Parent = Main,
    }, { Corner(20) })
    local SheenGrad = New("UIGradient", { Rotation = 90, Parent = Sheen })
    local Band = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.28, 0.3),
        Size = UDim2.new(0, 280, 2.5, 0),
        Rotation = 24,
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        Parent = Main,
    })
    local BandGrad = New("UIGradient", { Parent = Band })
    Hook(function(T)
        SheenGrad.Transparency = NumberSequence.new(T.Sheen, 1)
        BandGrad.Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.5, T.Band), NSK(1, 1) })
    end)

    -- Liquid glass: dispersive inner rim, edge highlight that follows the cursor
    local InnerRimFrame = New("Frame", {
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        ZIndex = 9,
        Parent = Main,
    }, { Corner(19) })
    local InnerRim = New("UIStroke", { Color = WHITE, Thickness = 1.5, Parent = InnerRimFrame })
    local InnerGrad = New("UIGradient", { Rotation = 255, Color = DispersionColors(), Parent = InnerRim })
    Hook(function(T)
        InnerGrad.Transparency = RimSequence(T)
    end)

    local rimAngle = 75
    Connect(RunService.RenderStepped, function(dt)
        if not Window.Visible or not Holder.Visible then
            return
        end
        local mouse = UserInputService:GetMouseLocation() + Gui.AbsolutePosition
        local d = mouse - (Holder.AbsolutePosition + Holder.AbsoluteSize / 2)
        if d.Magnitude > 1 then
            local target = math.deg(math.atan2(-d.Y, -d.X))
            local diff = (target - rimAngle + 180) % 360 - 180
            rimAngle += diff * math.min(1, dt * 8)
            EdgeGrad.Rotation = rimAngle
            InnerGrad.Rotation = rimAngle + 180
        end
    end)

    -- Slime theme decoration (rebuilt whenever the theme changes)
    local SlimeLayer
    Hook(function(T)
        if SlimeLayer then
            SlimeLayer:Destroy()
            SlimeLayer = nil
        end
        if T.Effect == "Slime" then
            SlimeLayer = SlimeDecor(Main, T)
        end
    end)

    local DragZone = New("Frame", {
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundTransparency = 1,
        ZIndex = 0,
        Parent = Main,
    })

    -----------------------------------------------------------------
    -- Floating sidebar
    -----------------------------------------------------------------
    local Sidebar = New("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(0, L.SideW, 1, -16),
        ClipsDescendants = true,
        Parent = Main,
    }, { Corner(15) })
    Bind(Sidebar, { BackgroundColor3 = "Sidebar", BackgroundTransparency = "SidebarT" })
    GlassEdge(Sidebar, 1)

    -- Traffic lights
    local lightGap = compact and 17 or 20
    local Lights = New("Frame", {
        Position = UDim2.fromOffset(compact and 9 or 16, 16),
        Size = UDim2.fromOffset(13 + lightGap * 2, 13),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = Sidebar,
    })
    local LightButtons = {}
    for i, d in ipairs({
        { "Close", Color3.fromRGB(255, 95, 87), "x" },
        { "Minimize", Color3.fromRGB(254, 188, 46), "minus" },
        { "Zoom", Color3.fromRGB(40, 200, 64), "plus" },
    }) do
        local b = New("TextButton", {
            Name = d[1],
            Position = UDim2.fromOffset((i - 1) * lightGap, 0),
            Size = UDim2.fromOffset(13, 13),
            BackgroundColor3 = d[2],
            AutoButtonColor = false,
            Text = "",
            Parent = Lights,
        }, { Corner("full"), Stroke(BLACK, 0.85, 0.5) })
        local glyph = IconLabel(d[3], {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(9, 9),
            ImageColor3 = Color3.fromRGB(80, 20, 10),
            ImageTransparency = 1,
            Parent = b,
        })
        local sc = New("UIScale", { Parent = b })
        LightButtons[d[1]] = b
        Connect(b.MouseButton1Down, function()
            Tween(sc, 0.1, { Scale = 0.85 })
        end)
        Connect(b.MouseButton1Up, function()
            Tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
        end)
        Connect(Lights.MouseEnter, function()
            Tween(glyph, 0.15, { ImageTransparency = 0.2 })
        end)
        Connect(Lights.MouseLeave, function()
            Tween(glyph, 0.15, { ImageTransparency = 1 })
            Tween(sc, 0.2, { Scale = 1 })
        end)
    end

    -- Compact title shown while minimized
    local MiniBrand = New("Frame", {
        Position = UDim2.fromOffset(16 + 13 + lightGap * 2 + 14, 9),
        Size = UDim2.new(1, -(16 + 13 + lightGap * 2 + 20), 0, 26),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = Sidebar,
    })
    MakeLogo(LogoImage, { Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(18, 18), Parent = MiniBrand })
    Bind(Label({
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Text = Window.Title,
        TextSize = 15,
        FontFace = F(W_BOLD),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = MiniBrand,
    }), { TextColor3 = "Text" })

    local SideContent = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })

    -- Logo + title
    local LogoHolder
    if compact then
        LogoHolder = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 38),
            Size = UDim2.fromOffset(34, 34),
            BackgroundTransparency = 1,
            Parent = SideContent,
        })
    else
        LogoHolder = New("Frame", {
            Position = UDim2.fromOffset(14, 40),
            Size = UDim2.fromOffset(34, 34),
            BackgroundTransparency = 1,
            Parent = SideContent,
        })
        Bind(Label({
            Position = UDim2.fromOffset(56, 40),
            Size = UDim2.new(1, -64, 0, 19),
            Text = Window.Title,
            TextSize = 16,
            FontFace = F(W_BOLD),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = SideContent,
        }), { TextColor3 = "Text" })
        Bind(Label({
            Position = UDim2.fromOffset(56, 59),
            Size = UDim2.new(1, -64, 0, 15),
            Text = Window.Subtitle,
            TextSize = 12,
            FontFace = F(W_MED),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = SideContent,
        }), { TextColor3 = "SubText" })
    end
    local LogoScale = New("UIScale", { Parent = LogoHolder })
    local Logo = MakeLogo(LogoImage, { Size = UDim2.fromScale(1, 1), Parent = LogoHolder })
    Connect(LogoHolder.MouseEnter, function()
        Tween(LogoScale, 0.35, { Scale = 1.12 }, Enum.EasingStyle.Back)
        Tween(Logo, 0.35, { Rotation = -8 }, Enum.EasingStyle.Back)
    end)
    Connect(LogoHolder.MouseLeave, function()
        Tween(LogoScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
        Tween(Logo, 0.35, { Rotation = 0 }, Enum.EasingStyle.Back)
    end)

    -- Search box (sidebar in regular layout, header in compact layout)
    local SearchFrame
    if compact then
        SearchFrame = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 18),
            Size = UDim2.fromOffset(150, 32),
            Parent = Main,
        }, { Corner(10) })
    else
        SearchFrame = New("Frame", {
            Position = UDim2.fromOffset(10, 86),
            Size = UDim2.new(1, -20, 0, 30),
            Parent = SideContent,
        }, { Corner(9) })
    end
    Bind(SearchFrame, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT" })
    Bind(IconLabel("search", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Parent = SearchFrame,
    }), { ImageColor3 = "SubText" })
    local SearchInput = New("TextBox", {
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -36, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search",
        TextSize = 14,
        FontFace = F(W_REG),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Parent = SearchFrame,
    })
    Bind(SearchInput, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })
    local SearchStroke = Stroke(Theme.Current.Accent, 1, 2)
    SearchStroke.Parent = SearchFrame
    Hook(function(T)
        SearchStroke.Color = T.Accent
    end)
    Connect(SearchInput.Focused, function()
        Tween(SearchStroke, 0.15, { Transparency = 0.45 })
    end)
    Connect(SearchInput.FocusLost, function()
        Tween(SearchStroke, 0.25, { Transparency = 1 })
    end)

    -- Tab list
    local listTop = compact and 84 or 126
    local footerH = compact and 54 or 62
    local TabList = New("ScrollingFrame", {
        Position = UDim2.fromOffset(compact and 7 or 8, listTop),
        Size = UDim2.new(1, compact and -14 or -16, 1, -listTop - footerH - 4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        Parent = SideContent,
    })
    local Indicator = New("Frame", {
        Size = UDim2.new(1, 0, 0, L.TabH),
        BackgroundTransparency = 1,
        ZIndex = 0,
        Parent = TabList,
    }, { Corner(11) })
    Bind(Indicator, { BackgroundColor3 = "Select" })

    -- Player profile
    local Footer = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 6, 1, -6),
        Size = UDim2.new(1, -12, 0, footerH - 6),
        BackgroundTransparency = 1,
        Parent = SideContent,
    })
    Bind(New("Frame", {
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 0, 1),
        BorderSizePixel = 0,
        Parent = Footer,
    }), { BackgroundColor3 = "Line", BackgroundTransparency = "LineT" })
    local Avatar = New("ImageLabel", {
        AnchorPoint = compact and Vector2.new(0.5, 0) or Vector2.new(0, 0),
        Position = compact and UDim2.new(0.5, 0, 0, 10) or UDim2.fromOffset(6, 12),
        Size = UDim2.fromOffset(34, 34),
        Image = "",
        Parent = Footer,
    }, { Corner("full") })
    Bind(Avatar, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT" })
    if not compact then
        Bind(Label({
            Position = UDim2.fromOffset(48, 12),
            Size = UDim2.new(1, -54, 0, 18),
            Text = LocalPlayer.DisplayName,
            TextSize = 14,
            FontFace = F(W_SEMI),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Footer,
        }), { TextColor3 = "Text" })
        Bind(Label({
            Position = UDim2.fromOffset(48, 30),
            Size = UDim2.new(1, -54, 0, 15),
            Text = "@" .. LocalPlayer.Name,
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Footer,
        }), { TextColor3 = "SubText" })
    end
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and Avatar.Parent then
            Avatar.Image = img
        end
    end)

    -----------------------------------------------------------------
    -- Content
    -----------------------------------------------------------------
    local headerRight = compact and 186 or 20
    local Header = Bind(Label({
        Position = UDim2.fromOffset(ContentX, 14),
        Size = UDim2.new(1, -ContentX - headerRight, 0, 32),
        Text = "",
        TextSize = compact and 22 or 26,
        FontFace = F(W_BOLD),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Main,
    }), { TextColor3 = "Text" })
    local SubHeader = Bind(Label({
        Position = UDim2.fromOffset(ContentX, 45),
        Size = UDim2.new(1, -ContentX - headerRight, 0, 18),
        Text = "",
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Main,
    }), { TextColor3 = "SubText" })
    local Pages = New("Frame", {
        Position = UDim2.fromOffset(ContentX - 6, 76),
        Size = UDim2.new(1, -ContentX - 2, 1, -82),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = Main,
    })

    local NotifyHolder = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, compact and 10 or 16),
        Size = UDim2.new(0, L.Notify, 1, -32),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = Gui,
    }, { List(10) })

    -----------------------------------------------------------------
    -- Blur the world behind
    -----------------------------------------------------------------
    local BlurFx
    local function BlurTo(on)
        if on then
            if not BlurFx or not BlurFx.Parent then
                BlurFx = New("BlurEffect", { Name = "SlimeUIBlur", Size = 0, Parent = Lighting })
            end
            Tween(BlurFx, 0.45, { Size = 10 })
        elseif BlurFx then
            Tween(BlurFx, 0.3, { Size = 0 })
        end
    end

    -----------------------------------------------------------------
    -- Popup menu (dropdown)
    -----------------------------------------------------------------
    local OpenMenu

    function Window:_closeMenu()
        if OpenMenu then
            local m = OpenMenu
            OpenMenu = nil
            if m.OnClose then
                m.OnClose()
            end
            Tween(m.Menu, 0.12, { GroupTransparency = 1 })
            Tween(m.Edge, 0.12, { Transparency = 1 })
            m.Overlay.Active = false
            task.delay(0.13, function()
                m.Overlay:Destroy()
            end)
        end
    end

    function Window:_openMenu(anchor, options, isSelected, onPick, onClose)
        self:_closeMenu()
        local T = Theme.Current
        local Overlay = New("TextButton", {
            Name = "MenuOverlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 50,
            Parent = Gui,
        })
        Overlay.MouseButton1Click:Connect(function()
            self:_closeMenu()
        end)

        local itemH, pad = compact and 36 or 30, 6
        local count = math.max(#options, 1)
        local height = math.min(count * itemH + pad * 2, compact and 210 or 260)
        local width = math.max(anchor.AbsoluteSize.X, 190)
        local rel = anchor.AbsolutePosition - Gui.AbsolutePosition
        local x = math.clamp(rel.X + anchor.AbsoluteSize.X - width, 8, math.max(8, Gui.AbsoluteSize.X - width - 8))
        local y = rel.Y + anchor.AbsoluteSize.Y + 6
        local up = false
        if y + height > Gui.AbsoluteSize.Y - 8 then
            y = rel.Y - 6
            up = true
        end
        local anchorPoint = up and Vector2.new(0, 1) or Vector2.new(0, 0)

        local Menu = New("CanvasGroup", {
            AnchorPoint = anchorPoint,
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, math.floor(height * 0.6)),
            BackgroundColor3 = T.Menu,
            BackgroundTransparency = T.MenuT,
            GroupTransparency = 1,
            Active = true,
            Parent = Overlay,
        }, { Corner(13) })
        local MenuEdgeFrame = New("Frame", {
            AnchorPoint = anchorPoint,
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, math.floor(height * 0.6)),
            BackgroundTransparency = 1,
            Parent = Overlay,
        }, { Corner(13) })
        local MenuEdge = StaticEdge(MenuEdgeFrame, T, 1)
        MenuEdge.Transparency = 1

        Tween(Menu, 0.3, { Size = UDim2.fromOffset(width, height), GroupTransparency = 0 })
        Tween(MenuEdgeFrame, 0.3, { Size = UDim2.fromOffset(width, height) })
        Tween(MenuEdge, 0.3, { Transparency = 0 })

        OpenMenu = { Overlay = Overlay, Menu = Menu, Edge = MenuEdge, OnClose = onClose }

        local Scroll = New("ScrollingFrame", {
            Size = UDim2.fromOffset(width, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.SubText,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = Menu,
        }, { List(1), Pad(pad, pad, pad, pad) })

        if #options == 0 then
            Label({
                Size = UDim2.new(1, 0, 0, itemH),
                Text = "No options",
                TextColor3 = T.SubText,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = Scroll,
            })
        end

        for i, opt in ipairs(options) do
            local Item = New("TextButton", {
                Size = UDim2.new(1, 0, 0, itemH),
                BackgroundColor3 = T.Accent,
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = i,
                Parent = Scroll,
            }, { Corner(8) })
            local Check = IconLabel("check", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 9, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                ImageColor3 = T.Text,
                ImageTransparency = isSelected(opt) and 0 or 1,
                Parent = Item,
            })
            local Txt = Label({
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -36, 1, 0),
                Text = tostring(opt),
                TextColor3 = T.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = Item,
            })
            Item.MouseEnter:Connect(function()
                Item.BackgroundTransparency = 0
                Txt.TextColor3 = WHITE
                Check.ImageColor3 = WHITE
            end)
            Item.MouseLeave:Connect(function()
                Item.BackgroundTransparency = 1
                Txt.TextColor3 = T.Text
                Check.ImageColor3 = T.Text
            end)
            Item.MouseButton1Click:Connect(function()
                local close = onPick(opt)
                if close then
                    self:_closeMenu()
                else
                    Tween(Check, 0.15, { ImageTransparency = isSelected(opt) and 0 or 1 })
                end
            end)
        end
    end

    -----------------------------------------------------------------
    -- Show / hide / minimize / zoom
    -----------------------------------------------------------------
    local Grip

    local function UpdateChrome()
        local mini = Window.Minimized
        SideContent.Visible = not mini
        if Grip then
            Grip.Visible = Window.Visible and not mini
        end
        MiniBrand.Visible = mini and not compact
        if compact then
            SearchFrame.Visible = not mini
        end
        Tween(SubHeader, mini and 0.15 or 0.35, { TextTransparency = mini and 1 or 0 })
    end

    local function FullSize()
        local s = TargetSize()
        return UDim2.fromOffset(s.X, Window.Minimized and 58 or s.Y)
    end

    -- Keep the window on screen (e.g. after the resolution changes while hidden)
    local function ClampPos(pos)
        if not pos then
            return UDim2.fromScale(0.5, 0.5)
        end
        local vp = Gui.AbsoluteSize
        local s = FitScale()
        local size = FullSize()
        local w, h = size.X.Offset * s, size.Y.Offset * s
        local maxX = math.max(0, vp.X / 2 + w / 2 - 80)
        local minY = -vp.Y / 2 + h / 2
        local maxY = math.max(minY, vp.Y / 2 + h / 2 - 56)
        return UDim2.new(0.5, math.clamp(pos.X.Offset, -maxX, maxX), 0.5, math.clamp(pos.Y.Offset, minY, maxY))
    end

    local function ApplySize(animated)
        if not Window.Visible then
            return
        end
        local target = FullSize()
        if animated then
            Tween(Holder, 0.5, { Size = target })
            Tween(Scale, 0.5, { Scale = FitScale() })
        else
            Holder.Size = target
            Scale.Scale = FitScale()
        end
    end

    -----------------------------------------------------------------
    -- Glass island bar at the top center: the UI collapses into it when hidden.
    -----------------------------------------------------------------
    local IslandH = compact and 46 or 42
    local IslandW = math.clamp(#Window.Title * 8 + 96, 180, 300)
    local IslandParts

    local function IslandCenter()
        return UDim2.new(0.5, 0, 0, 10 + IslandH / 2)
    end

    local function BuildIsland()
        local Root = New("Frame", {
            Name = "Island",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = IslandCenter(),
            Size = UDim2.fromOffset(IslandW, IslandH),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 45,
            Parent = Gui,
        })
        local RScale = New("UIScale", { Scale = 0.7, Parent = Root })
        local Group = New("CanvasGroup", {
            Size = UDim2.fromScale(1, 1),
            GroupTransparency = 1,
            Parent = Root,
        }, { Corner("full") })
        Bind(Group, { BackgroundColor3 = "Window" })
        local ISheen = New("Frame", {
            Size = UDim2.new(1, 0, 0.75, 0),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Parent = Group,
        }, { Corner("full") })
        local ISheenGrad = New("UIGradient", { Rotation = 90, Parent = ISheen })
        local IBand = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(-0.3, 0.5),
            Size = UDim2.new(0, 60, 3, 0),
            Rotation = 20,
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Parent = Group,
        })
        local IBandGrad = New("UIGradient", { Parent = IBand })
        local IRimFrame = New("Frame", {
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = Group,
        }, { Corner("full") })
        local IRim = New("UIStroke", { Color = WHITE, Thickness = 1.5, Parent = IRimFrame })
        local IRimGrad = New("UIGradient", { Rotation = 250, Color = DispersionColors(), Parent = IRim })
        Hook(function(T)
            Group.BackgroundTransparency = math.min(T.WindowT, 0.45)
            ISheenGrad.Transparency = NumberSequence.new(T.Sheen, 1)
            IBandGrad.Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.5, T.Band < 1 and T.Band - 0.06 or 1), NSK(1, 1) })
            IRimGrad.Transparency = RimSequence(T)
        end)

        MakeLogo(LogoImage, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, IslandH / 2, 0.5, 0),
            Size = UDim2.fromOffset(IslandH - 18, IslandH - 18),
            Parent = Group,
        })
        Bind(Label({
            Position = UDim2.fromOffset(IslandH - 2, 0),
            Size = UDim2.new(1, -(IslandH + 30), 1, 0),
            Text = Window.Title,
            TextSize = 14,
            FontFace = F(W_SEMI),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Group,
        }), { TextColor3 = "Text" })
        Bind(IconLabel("chevron-down", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Parent = Group,
        }), { ImageColor3 = "SubText" })

        local EdgeF = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = Root,
        }, { Corner("full") })
        local IEdge = GlassEdge(EdgeF, 1.2)
        IEdge.Transparency = 1
        local Click = New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 3,
            Parent = Root,
        })

        Connect(Click.MouseEnter, function()
            Tween(RScale, 0.35, { Scale = 1.04 }, Enum.EasingStyle.Back)
            IBand.Position = UDim2.fromScale(-0.3, 0.5)
            Tween(IBand, 0.8, { Position = UDim2.fromScale(1.3, 0.5) }, Enum.EasingStyle.Sine)
        end)
        Connect(Click.MouseLeave, function()
            Tween(RScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
        end)
        Connect(Click.MouseButton1Down, function()
            Tween(RScale, 0.1, { Scale = 0.95 })
        end)
        Connect(Click.MouseButton1Up, function()
            Tween(RScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
        end)
        Connect(Click.MouseButton1Click, function()
            Window:SetVisible(true)
        end)
        IslandParts = { Root = Root, Scale = RScale, Group = Group, Edge = IEdge, Band = IBand }
    end

    local function ShowIsland()
        if opts.Island == false or Window.Visible or Window.Destroyed then
            return
        end
        if not IslandParts then
            BuildIsland()
        end
        local p = IslandParts
        p.Root.Visible = true
        p.Scale.Scale = 0.6
        Tween(p.Scale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
        Tween(p.Group, 0.3, { GroupTransparency = 0 })
        Tween(p.Edge, 0.35, { Transparency = 0 })
    end

    local function HideIsland()
        local p = IslandParts
        if not p or not p.Root.Visible then
            return
        end
        Tween(p.Scale, 0.3, { Scale = 1.15 }, Enum.EasingStyle.Quad)
        Tween(p.Group, 0.2, { GroupTransparency = 1 })
        Tween(p.Edge, 0.2, { Transparency = 1 })
        task.delay(0.3, function()
            if Window.Visible then
                p.Root.Visible = false
            end
        end)
    end

    -- Starting size when the window expands out of the island
    local function IslandStartSize(s)
        local w, h = IslandH, IslandH
        if IslandParts and IslandParts.Root.Visible then
            w, h = IslandParts.Root.Size.X.Offset, IslandParts.Root.Size.Y.Offset
        end
        return UDim2.fromOffset(w / s, h / s)
    end

    local function GripVisible()
        return Window.Visible and not Window.Minimized
    end

    function Window:SetVisible(v)
        if v == self.Visible or self.Destroyed then
            return
        end
        self.Visible = v
        self:_closeMenu()
        local useIsland = opts.Island ~= false
        if v then
            HideIsland()
            Holder.Visible = true
            local s = FitScale()
            if self._collapsed and useIsland then
                -- Expand from the island back to the previous position
                Scale.Scale = s
                Holder.Position = IslandCenter()
                Holder.Size = IslandStartSize(s)
                Main.GroupTransparency = 1
                Edge.Transparency = 0.2
                Tween(Holder, 0.6, { Position = ClampPos(self._restorePos), Size = FullSize() }, Enum.EasingStyle.Quint)
                Tween(Edge, 0.5, { Transparency = 0 })
                task.delay(0.1, function()
                    if self.Visible then
                        Tween(Main, 0.45, { GroupTransparency = 0 })
                    end
                end)
                self._morphEnd = os.clock() + 0.65
            else
                Holder.Size = FullSize()
                Scale.Scale = s * 0.9
                if Theme.Current.Effect == "Slime" then
                    Tween(Scale, 1, { Scale = s }, Enum.EasingStyle.Elastic)
                else
                    Tween(Scale, 0.55, { Scale = s }, Enum.EasingStyle.Back)
                end
                Tween(Main, 0.3, { GroupTransparency = 0 })
                Tween(Edge, 0.35, { Transparency = 0 })
            end
            self._collapsed = false
            BlurTo(self.BlurEnabled)
            Band.Position = UDim2.fromScale(-0.45, 0.3)
            Tween(Band, 1.3, { Position = UDim2.fromScale(0.28, 0.3) }, Enum.EasingStyle.Quint)
            task.delay(0.55, function()
                if Grip and self.Visible then
                    Grip.Visible = GripVisible()
                end
            end)
        else
            BlurTo(false)
            if Grip then
                Grip.Visible = false
            end
            if useIsland then
                -- Collapse into the island at the top center
                if os.clock() >= (self._morphEnd or 0) then
                    self._restorePos = Holder.Position
                end
                self._collapsed = true
                local s = Scale.Scale
                Tween(Holder, 0.5, {
                    Position = IslandCenter(),
                    Size = UDim2.fromOffset(IslandW / s, IslandH / s),
                }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
                Tween(Main, 0.3, { GroupTransparency = 1 })
                task.delay(0.3, ShowIsland)
                task.delay(0.5, function()
                    if not self.Visible then
                        Holder.Visible = false
                        Edge.Transparency = 1
                    end
                end)
            else
                Tween(Scale, 0.22, { Scale = Scale.Scale * 0.93 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                Tween(Edge, 0.18, { Transparency = 1 })
                local t = Tween(Main, 0.22, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                t.Completed:Connect(function()
                    if not self.Visible then
                        Holder.Visible = false
                    end
                end)
            end
        end
    end

    function Window:Toggle()
        self:SetVisible(not self.Visible)
    end

    function Window:Minimize(state)
        if state == nil then
            state = not self.Minimized
        end
        self.Minimized = state
        self:_closeMenu()
        UpdateChrome()
        ApplySize(true)
    end

    function Window:Zoom(state)
        if state == nil then
            state = not self.Zoomed
        end
        self.Zoomed = state
        self.Minimized = false
        UpdateChrome()
        ApplySize(true)
    end

    function Window:SetScale(s)
        self.UserScale = math.clamp(s, 0.5, 1.5)
        Tween(Scale, 0.35, { Scale = FitScale() })
    end

    function Window:SetBlur(on)
        self.BlurEnabled = on and true or false
        if self.Visible then
            BlurTo(self.BlurEnabled)
        end
    end

    function Window:SetTheme(name)
        if not Themes[name] then
            return
        end
        Theme.Name = name
        Theme.Current = table.clone(Themes[name])
        Theme.AccentOverride = nil
        ApplyTheme(true)
    end

    function Window:SetAccent(accent)
        if accent == nil or accent == "Theme" then
            Theme.AccentOverride = nil
            Theme.Current.Accent = Themes[Theme.Name].Accent
            Theme.Current.Accent2 = Themes[Theme.Name].Accent2
        else
            local c = (typeof(accent) == "Color3" and accent) or Accents[accent]
            if not c then
                return
            end
            Theme.AccentOverride = c
            Theme.Current.Accent = c
            Theme.Current.Accent2 = nil
        end
        ApplyTheme(true)
    end

    Connect(LightButtons.Close.MouseButton1Click, function()
        Window:SetVisible(false)
        if not Window._hintShown then
            Window._hintShown = true
            local how = opts.Island ~= false and "Click the bar at the top" or "Use the floating button"
            if Window.ToggleKey then
                how = how .. " or press " .. Window.ToggleKey.Name
            end
            Window:Notify({ Title = Window.Title, Content = how .. " to open it again.", Duration = 4, Icon = "eye-off" })
        end
    end)
    Connect(LightButtons.Minimize.MouseButton1Click, function()
        Window:Minimize()
    end)
    Connect(LightButtons.Zoom.MouseButton1Click, function()
        Window:Zoom()
    end)

    -- Window dragging (mouse + touch)
    local dragging, dragStart, startPos = false, nil, nil
    local function StartDrag(input)
        if not IsClick(input) then
            return
        end
        dragging = true
        dragStart = input.Position
        startPos = Holder.Position
        Window:_closeMenu()
        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                c:Disconnect()
            end
        end)
    end
    Connect(DragZone.InputBegan, StartDrag)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and IsMove(input) then
            local d = input.Position - dragStart
            local vp = Gui.AbsoluteSize
            local size = Holder.AbsoluteSize
            local maxX = vp.X / 2 + size.X / 2 - 80
            local minY = -vp.Y / 2 + size.Y / 2
            local maxY = vp.Y / 2 + size.Y / 2 - 56
            local x = math.clamp(startPos.X.Offset + d.X, -maxX, maxX)
            local y = math.clamp(startPos.Y.Offset + d.Y, minY, math.max(minY, maxY))
            Tween(Holder, 0.12, { Position = UDim2.new(0.5, x, 0.5, y) })
        end
    end)

    -- macOS 26 style handles: an arc around the bottom-right corner (resize)
    -- and a bar under the window (drag to move)
    local MinSize = compact and Vector2.new(420, 260) or Vector2.new(600, 380)
    Grip = New("Frame", {
        Name = "WindowHandles",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Visible = false,
        Parent = Holder,
    })
    local ArcR = 27
    local ArcBox = New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 11, 1, 11),
        Size = UDim2.fromOffset(ArcR + 4, ArcR + 4),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = opts.Resizable ~= false,
        Parent = Grip,
    })
    local ArcFrame = New("Frame", {
        Position = UDim2.fromOffset(-ArcR, -ArcR),
        Size = UDim2.fromOffset(ArcR * 2, ArcR * 2),
        BackgroundTransparency = 1,
        Parent = ArcBox,
    }, { Corner("full") })
    local ArcStroke = New("UIStroke", {
        Thickness = 3.5,
        Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = ArcFrame,
    })
    Bind(ArcStroke, { Color = "Text" })
    local function GripGlow(on)
        Tween(ArcStroke, 0.2, { Transparency = on and 0.1 or 0.5 })
    end

    local MoveBar = New("Frame", {
        Name = "MoveBar",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 9),
        Size = UDim2.new(0.26, 0, 0, 5),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = Grip,
    }, { Corner("full") })
    Bind(MoveBar, { BackgroundColor3 = "Text" })
    local MoveHit = New("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 30, 0, 24),
        BackgroundTransparency = 1,
        Text = "",
        Parent = MoveBar,
    })
    Connect(MoveHit.InputBegan, StartDrag)
    Connect(MoveHit.MouseEnter, function()
        Tween(MoveBar, 0.25, { BackgroundTransparency = 0.15, Size = UDim2.new(0.32, 0, 0, 5) })
    end)
    Connect(MoveHit.MouseLeave, function()
        Tween(MoveBar, 0.3, { BackgroundTransparency = 0.5, Size = UDim2.new(0.26, 0, 0, 5) })
    end)

    local resizing
    if opts.Resizable ~= false then
        for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
            local ax, ay = c[1], c[2]
            local arcCorner = ax == 1 and ay == 1
            local hs = arcCorner and (compact and 46 or 40) or (compact and 26 or 18)
            local Handle = New("TextButton", {
                Name = "Resize",
                AnchorPoint = Vector2.new(ax, ay),
                Position = arcCorner and UDim2.new(1, 13, 1, 13) or UDim2.fromScale(ax, ay),
                Size = UDim2.fromOffset(hs, hs),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 6,
                Parent = Holder,
            })
            Connect(Handle.MouseEnter, function()
                if not resizing then
                    GripGlow(true)
                end
            end)
            Connect(Handle.MouseLeave, function()
                if not resizing then
                    GripGlow(false)
                end
            end)
            Connect(Handle.InputBegan, function(input)
                if not IsClick(input) or Window.Minimized or not Window.Visible then
                    return
                end
                resizing = {
                    sx = ax == 1 and 1 or -1,
                    sy = ay == 1 and 1 or -1,
                    start = input.Position,
                    w = Holder.Size.X.Offset,
                    h = Holder.Size.Y.Offset,
                    pos = Holder.Position,
                }
                Window:_closeMenu()
                GripGlow(true)
                local cn
                cn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        cn:Disconnect()
                        resizing = nil
                        GripGlow(false)
                    end
                end)
            end)
        end
        Connect(UserInputService.InputChanged, function(input)
            if not resizing or not IsMove(input) then
                return
            end
            local r = resizing
            local s = Scale.Scale
            local d = input.Position - r.start
            local vp = Gui.AbsoluteSize
            local w = math.clamp(r.w + r.sx * d.X / s, MinSize.X, math.max(MinSize.X, (vp.X - 20) / s))
            local h = math.clamp(r.h + r.sy * d.Y / s, MinSize.Y, math.max(MinSize.Y, (vp.Y - 20) / s))
            Holder.Size = UDim2.fromOffset(w, h)
            Holder.Position = UDim2.new(
                0.5, r.pos.X.Offset + r.sx * (w - r.w) * s / 2,
                0.5, r.pos.Y.Offset + r.sy * (h - r.h) * s / 2
            )
            BaseSize = Vector2.new(w, h)
            Window.Zoomed = false
        end)
    end

    -- Toggle key
    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe or Window._binding then
            return
        end
        if Window.ToggleKey and input.KeyCode == Window.ToggleKey then
            Window:Toggle()
        end
    end)

    if workspace.CurrentCamera then
        Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
            ApplySize(false)
        end)
    end

    -----------------------------------------------------------------
    -- Notifications
    -----------------------------------------------------------------
    local notifyOrder = 0
    local TypeInfo = {
        Success = { SUCCESS, "check-circle" },
        Error = { DANGER, "x-circle" },
        Warning = { WARNING, "alert-triangle" },
        Info = { nil, "info" },
    }

    function Window:Notify(a, b, c)
        local o = type(a) == "table" and a or { Title = a, Content = b, Duration = c }
        local T = Theme.Current
        local duration = o.Duration or 4
        local info = TypeInfo[o.Type or ""]
        local color = o.Color or (info and info[1]) or T.Accent
        local H = 80
        notifyOrder -= 1

        local Wrap = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            LayoutOrder = notifyOrder,
            Parent = NotifyHolder,
        })
        local Slide = New("Frame", {
            Position = UDim2.fromOffset(L.Notify + 50, 0),
            Size = UDim2.new(1, 0, 0, H),
            BackgroundTransparency = 1,
            Parent = Wrap,
        })
        local SScale = New("UIScale", { Scale = 0.85, Parent = Slide })

        -- Glass layer: translucent background + top sheen + refraction band
        local Group = New("CanvasGroup", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = T.Window,
            BackgroundTransparency = T.WindowT * 0.8,
            GroupTransparency = 1,
            Parent = Slide,
        }, { Corner(22) })
        New("Frame", {
            Size = UDim2.new(1, 0, 0.8, 0),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Parent = Group,
        }, { Corner(22), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(T.Sheen, 1) }) })
        local NBand = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(-0.3, 0.5),
            Size = UDim2.new(0, 110, 3, 0),
            Rotation = 20,
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Parent = Group,
        }, {
            New("UIGradient", {
                Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.5, T.Band < 1 and T.Band - 0.05 or 1), NSK(1, 1) }),
            }),
        })

        local IconBox = New("Frame", {
            Position = UDim2.fromOffset(14, 20),
            Size = UDim2.fromOffset(40, 40),
            BackgroundColor3 = color,
            Parent = Group,
        }, {
            Corner(12),
            New("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 200, 200)) }),
            Stroke(WHITE, 0.6, 1),
        })
        local iconName = o.Icon or (info and info[2])
        if iconName then
            IconLabel(iconName, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(20, 20),
                ImageColor3 = WHITE,
                Parent = IconBox,
            })
        else
            MakeLogo(LogoImage, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(26, 26),
                Parent = IconBox,
            })
        end
        Label({
            Position = UDim2.fromOffset(66, 16),
            Size = UDim2.new(1, -130, 0, 18),
            Text = o.Title or Window.Title,
            TextColor3 = T.Text,
            TextSize = 14,
            FontFace = F(W_SEMI),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Group,
        })
        Label({
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 17),
            Size = UDim2.fromOffset(50, 16),
            Text = "now",
            TextColor3 = T.SubText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = Group,
        })
        Label({
            Position = UDim2.fromOffset(66, 35),
            Size = UDim2.new(1, -82, 0, 32),
            Text = o.Content or "",
            TextColor3 = T.Text,
            TextTransparency = 0.12,
            TextSize = 13,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Group,
        })
        local Progress = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 22, 1, -6),
            Size = UDim2.new(1, -44, 0, 2),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Parent = Group,
        }, { Corner("full") })

        local EdgeF = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = Slide,
        }, { Corner(22) })
        local NEdge = StaticEdge(EdgeF, T, 1.2)
        NEdge.Transparency = 1
        local Click = New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 5,
            Parent = Slide,
        })

        -- Enter animation: slide + bounce + light sweep
        Tween(Wrap, 0.4, { Size = UDim2.new(1, 0, 0, H) })
        Tween(Slide, 0.65, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
        Tween(SScale, 0.7, { Scale = 1 }, Enum.EasingStyle.Back)
        Tween(Group, 0.35, { GroupTransparency = 0 })
        Tween(NEdge, 0.45, { Transparency = 0 })
        task.delay(0.2, function()
            Tween(NBand, 1.1, { Position = UDim2.fromScale(1.3, 0.5) }, Enum.EasingStyle.Sine)
        end)
        Tween(Progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

        local closed = false
        local function close()
            if closed then
                return
            end
            closed = true
            Tween(SScale, 0.3, { Scale = 0.9 })
            Tween(Group, 0.3, { GroupTransparency = 1 })
            Tween(NEdge, 0.25, { Transparency = 1 })
            Tween(Slide, 0.4, { Position = UDim2.fromOffset(L.Notify + 50, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.delay(0.3, function()
                local t = Tween(Wrap, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
                t.Completed:Wait()
                Wrap:Destroy()
            end)
        end
        Click.MouseEnter:Connect(function()
            if not closed then
                Tween(SScale, 0.3, { Scale = 1.03 }, Enum.EasingStyle.Back)
                NBand.Position = UDim2.fromScale(-0.3, 0.5)
                Tween(NBand, 0.8, { Position = UDim2.fromScale(1.3, 0.5) }, Enum.EasingStyle.Sine)
            end
        end)
        Click.MouseLeave:Connect(function()
            if not closed then
                Tween(SScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
            end
        end)
        Click.MouseButton1Click:Connect(close)
        task.delay(duration, close)
    end

    -----------------------------------------------------------------
    -- Tabs
    -----------------------------------------------------------------
    local function MoveIndicator(animated)
        local cur = Window.Current
        if not cur or not cur._button.Visible then
            Tween(Indicator, 0.2, { BackgroundTransparency = 1 })
            return
        end
        local target = { Position = cur._button.Position, BackgroundTransparency = Theme.Current.SelectT }
        if animated then
            Tween(Indicator, 0.45, target, Enum.EasingStyle.Quint)
        else
            Indicator.Position = target.Position
            Indicator.BackgroundTransparency = target.BackgroundTransparency
        end
    end
    Hook(function()
        MoveIndicator(false)
    end)

    local function RelayoutTabs()
        local sorted = table.clone(Window.Tabs)
        table.sort(sorted, function(a, b)
            return a._order < b._order
        end)
        local y = 0
        for _, t in ipairs(sorted) do
            if t._button.Visible then
                t._button.Position = UDim2.fromOffset(0, y)
                y += L.TabH + 3
            end
        end
        TabList.CanvasSize = UDim2.fromOffset(0, y)
        MoveIndicator(false)
    end

    -- Search
    local function ApplySearch()
        local q = string.lower(Trim(SearchInput.Text))
        local firstVisible
        for _, tab in ipairs(Window.Tabs) do
            local tabMatch = q == "" or string.find(string.lower(tab.Name), q, 1, true) ~= nil
            local count = 0
            for _, e in ipairs(tab.Elements) do
                local match = tabMatch or (e.Name ~= "" and string.find(e.Name, q, 1, true) ~= nil)
                e.Row.Visible = match
                if match then
                    count += 1
                end
            end
            for _, s in ipairs(tab.Sections) do
                s:_refresh()
            end
            tab._button.Visible = tabMatch or count > 0
            if tab._button.Visible and (not firstVisible or tab._order < firstVisible._order) then
                firstVisible = tab
            end
        end
        RelayoutTabs()
        if Window.Current and not Window.Current._button.Visible and firstVisible then
            Window:SelectTab(firstVisible)
        end
    end
    Connect(SearchInput:GetPropertyChangedSignal("Text"), ApplySearch)

    function Window:SelectTab(tab)
        if type(tab) == "string" then
            for _, t in ipairs(self.Tabs) do
                if t.Name == tab then
                    tab = t
                    break
                end
            end
        end
        if type(tab) ~= "table" or self.Current == tab then
            return
        end
        local prev = self.Current
        self.Current = tab
        self:_closeMenu()
        for _, t in ipairs(self.Tabs) do
            local on = t == tab
            t._page.Visible = on
            if t._name then
                t._name.FontFace = F(on and W_SEMI or W_MED)
            end
            if not on then
                Tween(t._button, 0.2, { BackgroundTransparency = 1 })
            end
        end
        MoveIndicator(prev ~= nil)

        local dir = (prev and prev._order > tab._order) and -1 or 1
        Header.Text = tab.Name
        SubHeader.Text = tab.Description
        Header.TextTransparency = 1
        SubHeader.TextTransparency = 1
        Header.Position = UDim2.fromOffset(ContentX, 14 + 8 * dir)
        Tween(Header, 0.45, { TextTransparency = 0, Position = UDim2.fromOffset(ContentX, 14) })
        task.delay(0.06, function()
            if self.Current == tab then
                Tween(SubHeader, 0.4, { TextTransparency = self.Minimized and 1 or 0 })
            end
        end)
        tab._page.Position = UDim2.fromOffset(0, 22 * dir)
        Tween(tab._page, 0.5, { Position = UDim2.fromOffset(0, 0) })
        tab._iconScale.Scale = 0.75
        Tween(tab._iconScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
    end

    -----------------------------------------------------------------
    -- Sections & elements
    -----------------------------------------------------------------
    local SectionMethods = {}
    SectionMethods.__index = SectionMethods
    local TabMethods = {}
    TabMethods.__index = TabMethods

    local function RegisterFlag(flag, api, value)
        if flag then
            SlimeUI.Flags[flag] = value
            SlimeUI.Options[flag] = api
        end
    end

    local function SetFlag(flag, value)
        if flag then
            SlimeUI.Flags[flag] = value
        end
    end

    local function CreateSection(tab, name)
        local section = setmetatable({ Tab = tab, Rows = {} }, SectionMethods)
        table.insert(tab.Sections, section)
        local Container = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = #tab.Sections,
            Parent = tab._page,
        }, { List(7) })
        if name and name ~= "" then
            Bind(Label({
                Size = UDim2.new(1, 0, 0, 18),
                Text = name,
                TextSize = 13,
                FontFace = F(W_SEMI),
                LayoutOrder = 0,
                Parent = Container,
            }, { Pad(0, 0, 0, 6) }), { TextColor3 = "SubText" })
        end
        local Card = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            Parent = Container,
        }, { Corner(14), List(0) })
        Bind(Card, { BackgroundColor3 = "Card", BackgroundTransparency = "CardT" })
        local cardStroke = Stroke(Theme.Current.Line, 0.9, 1)
        cardStroke.Parent = Card
        Hook(function(T)
            cardStroke.Color = T.Line
            cardStroke.Transparency = math.min(1, T.LineT + 0.02)
        end)
        section.Container = Container
        section.Card = Card
        return section
    end

    function SectionMethods:_refresh()
        local first, any = true, false
        for _, e in ipairs(self.Rows) do
            if e.Row.Visible then
                e.Sep.Visible = not first
                first = false
                any = true
            end
        end
        self.Container.Visible = any or #self.Rows == 0
    end

    local function NewRow(section, r)
        local tab = section.Tab
        local order = #section.Rows + 1
        local height = r.Height or (r.Description and L.RowDescH or L.RowH)
        local Row = New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = section.Card,
        })
        local HoverBg = New("Frame", {
            Position = UDim2.fromOffset(4, 3),
            Size = UDim2.new(1, -8, 1, -6),
            BackgroundTransparency = 1,
            ZIndex = 0,
            Parent = Row,
        }, { Corner(10) })
        Bind(HoverBg, { BackgroundColor3 = "Hover" })
        if not r.NoHover then
            Connect(Row.MouseEnter, function()
                Tween(HoverBg, 0.2, { BackgroundTransparency = Theme.Current.HoverT })
            end)
            Connect(Row.MouseLeave, function()
                Tween(HoverBg, 0.3, { BackgroundTransparency = 1 })
            end)
        end
        local Sep = New("Frame", {
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -28, 0, 1),
            BorderSizePixel = 0,
            Visible = order > 1,
            Parent = Row,
        })
        Bind(Sep, { BackgroundColor3 = "Line", BackgroundTransparency = "LineT" })

        local textX = 14
        if r.Icon and GetIcon(r.Icon) then
            Bind(IconLabel(r.Icon, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 14, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                Parent = Row,
            }), { ImageColor3 = "SubText" })
            textX = 42
        end
        if r.Name then
            local right = r.Right or 160
            Bind(Label({
                Position = UDim2.fromOffset(textX, r.Description and 10 or 0),
                Size = UDim2.new(1, -right - textX - 14, 0, r.Description and 20 or height),
                Text = r.Name,
                TextSize = 14,
                FontFace = F(W_MED),
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = Row,
            }), { TextColor3 = "Text" })
            if r.Description then
                Bind(Label({
                    Position = UDim2.fromOffset(textX, 30),
                    Size = UDim2.new(1, -right - textX - 14, 0, 16),
                    Text = r.Description,
                    TextSize = 12,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = Row,
                }), { TextColor3 = "SubText" })
            end
        end
        local entry = { Row = Row, Sep = Sep, Name = string.lower(r.SearchName or r.Name or "") }
        table.insert(section.Rows, entry)
        table.insert(tab.Elements, entry)
        return Row
    end

    local function PressScale(button)
        local sc = New("UIScale", { Parent = button })
        Connect(button.MouseButton1Down, function()
            Tween(sc, 0.1, { Scale = 0.94 })
        end)
        Connect(button.MouseButton1Up, function()
            Tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
        end)
        Connect(button.MouseLeave, function()
            Tween(sc, 0.2, { Scale = 1 })
        end)
        return sc
    end

    -- Toggle -------------------------------------------------------
    function SectionMethods:Toggle(a, b, c)
        local o = type(a) == "table" and a or { Name = a, Default = b, Callback = c }
        local Row = NewRow(self, { Name = o.Name, Description = o.Description, Icon = o.Icon, Right = 64 })
        local state = o.Default == true
        local RowButton = New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 0,
            Parent = Row,
        })
        local Switch = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(46, 26),
            AutoButtonColor = false,
            Text = "",
            ZIndex = 2,
            Parent = Row,
        }, { Corner("full") })
        local Knob = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, state and 22 or 2, 0.5, 0),
            Size = UDim2.fromOffset(22, 22),
            Parent = Switch,
        }, { Corner("full"), Stroke(BLACK, 0.86, 0.6) })
        Bind(Knob, { BackgroundColor3 = "Knob" })
        local SwitchGrad = New("UIGradient", { Enabled = false, Parent = Switch })

        local api = { Value = state, Type = "Toggle" }
        local function paint(animated)
            local T = Theme.Current
            local onColor = AccentColor(T, SwitchGrad)
            if not state then
                SwitchGrad.Enabled = false
            end
            local props = {
                BackgroundColor3 = state and onColor or T.Control,
                BackgroundTransparency = state and 0 or T.ControlT,
            }
            if animated then
                Tween(Switch, 0.25, props)
            else
                for k, v in pairs(props) do
                    Switch[k] = v
                end
            end
        end
        Hook(function(_, animated)
            paint(animated)
        end)
        local function knob(pressed)
            local w = pressed and 28 or 22
            local slime = Theme.Current.Effect == "Slime"
            Tween(Knob, slime and 0.8 or 0.4, {
                Size = UDim2.fromOffset(w, 22),
                Position = UDim2.new(0, state and (44 - w) or 2, 0.5, 0),
            }, slime and Enum.EasingStyle.Elastic or Enum.EasingStyle.Back)
        end
        function api:Set(v, silent)
            state = v and true or false
            api.Value = state
            SetFlag(o.Flag, state)
            paint(true)
            knob(false)
            if not silent and o.Callback then
                task.spawn(o.Callback, state)
            end
        end
        Connect(Switch.MouseButton1Down, function()
            knob(true)
        end)
        Connect(Switch.MouseLeave, function()
            knob(false)
        end)
        Connect(Switch.MouseButton1Click, function()
            api:Set(not state)
        end)
        Connect(RowButton.MouseButton1Click, function()
            api:Set(not state)
        end)
        RegisterFlag(o.Flag, api, state)
        return api
    end

    -- Slider -------------------------------------------------------
    function SectionMethods:Slider(a, b, c, d, e)
        local o = type(a) == "table" and a or { Name = a, Min = b, Max = c, Default = d, Callback = e }
        local min, max = tonumber(o.Min) or 0, tonumber(o.Max) or 100
        if max < min then
            min, max = max, min
        end
        local inc = tonumber(o.Increment) or 1
        if inc <= 0 then
            inc = 1
        end
        local value = math.clamp(tonumber(o.Default) or min, min, max)
        local suffix = o.Suffix or ""
        local decimals = 0
        local incStr = tostring(inc)
        local dot = string.find(incStr, ".", 1, true)
        if dot then
            decimals = #incStr - dot
        end

        local Row = NewRow(self, { Name = o.Name, Description = o.Description, Icon = o.Icon, Right = L.Track + 96 })
        local ValueBox = New("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(58, 26),
            Text = "",
            TextSize = 13,
            FontFace = F(W_MED),
            ClearTextOnFocus = false,
            Parent = Row,
        }, { Corner(8) })
        Bind(ValueBox, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT", TextColor3 = "Text" })
        local Track = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -84, 0.5, 0),
            Size = UDim2.fromOffset(L.Track, 5),
            BorderSizePixel = 0,
            Parent = Row,
        }, { Corner("full") })
        Bind(Track, { BackgroundColor3 = "Control" })
        Hook(function(T)
            Track.BackgroundTransparency = math.max(T.ControlT, 0)
        end)
        local Fill = New("Frame", {
            Size = UDim2.fromScale(0, 1),
            BorderSizePixel = 0,
            Parent = Track,
        }, { Corner("full") })
        local FillGrad = New("UIGradient", { Enabled = false, Parent = Fill })
        Hook(function(T)
            Fill.BackgroundColor3 = AccentColor(T, FillGrad)
        end)
        local Knob = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(20, 20),
            ZIndex = 2,
            Parent = Track,
        }, { Corner("full"), Stroke(BLACK, 0.82, 0.6) })
        Bind(Knob, { BackgroundColor3 = "Knob" })
        local Hit = New("TextButton", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -10, 0.5, 0),
            Size = UDim2.new(1, 20, 0, compact and 36 or 28),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 3,
            Parent = Track,
        })

        local api = { Type = "Slider" }
        local function fmt(v)
            return string.format("%." .. decimals .. "f", v)
        end
        local function render(slow)
            local alpha = (max > min) and (value - min) / (max - min) or 0
            local t = slow and 0.35 or 0.08
            Tween(Fill, t, { Size = UDim2.fromScale(alpha, 1) })
            Tween(Knob, t, { Position = UDim2.fromScale(alpha, 0.5) })
            ValueBox.Text = fmt(value) .. suffix
        end
        function api:Set(v, silent, slow)
            v = tonumber(v) or value
            v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
            v = tonumber(fmt(v))
            local changed = v ~= value
            value = v
            api.Value = v
            SetFlag(o.Flag, v)
            render(slow)
            if changed and not silent and o.Callback then
                task.spawn(o.Callback, v)
            end
        end

        local sliding = false
        local function fromX(x)
            local alpha = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            api:Set(min + (max - min) * alpha)
        end
        Connect(Hit.InputBegan, function(input)
            if not IsClick(input) then
                return
            end
            sliding = true
            self.Tab._page.ScrollingEnabled = false
            Tween(Knob, 0.2, { Size = UDim2.fromOffset(26, 26) }, Enum.EasingStyle.Back)
            fromX(input.Position.X)
            local cn
            cn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    cn:Disconnect()
                    sliding = false
                    self.Tab._page.ScrollingEnabled = true
                    Tween(Knob, 0.3, { Size = UDim2.fromOffset(20, 20) }, Enum.EasingStyle.Back)
                end
            end)
        end)
        Connect(UserInputService.InputChanged, function(input)
            if sliding and IsMove(input) then
                fromX(input.Position.X)
            end
        end)
        Connect(ValueBox.FocusLost, function()
            local n = tonumber((string.gsub(ValueBox.Text, "[^%d%.%-]", "")))
            if n then
                api:Set(n, false, true)
            else
                render(true)
            end
        end)

        api.Value = value
        render(true)
        RegisterFlag(o.Flag, api, value)
        return api
    end

    -- Button -------------------------------------------------------
    function SectionMethods:Button(a, b)
        local o = type(a) == "table" and a or { Name = a, Callback = b }
        local Row = NewRow(self, { Name = o.Name, Description = o.Description, Icon = o.Icon, Right = 140 })
        local style = o.Style or (o.Primary and "Primary") or (o.Danger and "Danger") or "Default"
        local Btn = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(0, compact and 32 or 28),
            AutomaticSize = Enum.AutomaticSize.X,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 2,
            Parent = Row,
        }, { Corner("full"), Pad(0, 14, 0, 14) })
        local Content = New("Frame", {
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = Btn,
        }, { List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center) })
        local BtnIcon = IconLabel(o.ButtonIcon or "", {
            Size = UDim2.fromOffset(14, 14),
            Visible = o.ButtonIcon ~= nil and GetIcon(o.ButtonIcon) ~= nil,
            LayoutOrder = 1,
            Parent = Content,
        })
        local BtnText = Label({
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = o.ButtonText or "Run",
            TextSize = 13,
            FontFace = F(W_SEMI),
            LayoutOrder = 2,
            Parent = Content,
        })
        local baseT
        local BtnGrad = New("UIGradient", { Enabled = false, Parent = Btn })
        Hook(function(T, animated)
            local bg, fg
            BtnGrad.Enabled = false
            if style == "Primary" then
                bg, fg, baseT = AccentColor(T, BtnGrad), WHITE, 0
            elseif style == "Danger" then
                bg, fg, baseT = DANGER, WHITE, 0
            else
                bg, fg, baseT = T.Field, T.Text, math.max(0, T.FieldT - 0.04)
            end
            local props = { BackgroundColor3 = bg, BackgroundTransparency = baseT }
            if animated then
                Tween(Btn, 0.3, props)
            else
                Btn.BackgroundColor3 = bg
                Btn.BackgroundTransparency = baseT
            end
            BtnText.TextColor3 = fg
            BtnIcon.ImageColor3 = fg
        end)
        PressScale(Btn)
        Connect(Btn.MouseEnter, function()
            Tween(Btn, 0.15, { BackgroundTransparency = math.max(0, baseT - 0.06) })
        end)
        Connect(Btn.MouseLeave, function()
            Tween(Btn, 0.2, { BackgroundTransparency = baseT })
        end)
        Connect(Btn.MouseButton1Click, function()
            -- Flash on click
            Btn.BackgroundTransparency = math.max(0, baseT - 0.15)
            Tween(Btn, 0.4, { BackgroundTransparency = baseT })
            if o.Callback then
                task.spawn(o.Callback)
            end
        end)
        return {
            Type = "Button",
            SetText = function(_, t)
                BtnText.Text = t
            end,
        }
    end

    -- Rotating chevron
    local function Chevron(parent, position)
        local holder = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = position,
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Parent = parent,
        })
        Bind(IconLabel("chevron-down", { Size = UDim2.fromScale(1, 1), Parent = holder }), { ImageColor3 = "SubText" })
        return holder
    end

    -- Dropdown -----------------------------------------------------
    function SectionMethods:Dropdown(a, b, c, d)
        local o = type(a) == "table" and a or { Name = a, Options = b, Default = c, Callback = d }
        local options = o.Options or o.Values or {}
        local multi = o.Multi == true
        local value
        if multi then
            value = {}
            for _, v in ipairs(type(o.Default) == "table" and o.Default or {}) do
                value[v] = true
            end
        else
            value = o.Default
        end

        local Row = NewRow(self, { Name = o.Name, Description = o.Description, Icon = o.Icon, Right = L.Drop + 20 })
        local Btn = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(L.Drop, compact and 32 or 28),
            AutoButtonColor = false,
            Text = "",
            ZIndex = 2,
            Parent = Row,
        }, { Corner(9) })
        Bind(Btn, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT" })
        local Text = Bind(Label({
            Position = UDim2.fromOffset(11, 0),
            Size = UDim2.new(1, -36, 1, 0),
            TextSize = 13,
            FontFace = F(W_MED),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Btn,
        }), { TextColor3 = "Text" })
        local Chev = Chevron(Btn, UDim2.new(1, -15, 0.5, 0))
        PressScale(Btn)

        local api = { Type = "Dropdown" }
        local function output()
            if multi then
                local l = {}
                for _, opt in ipairs(options) do
                    if value[opt] then
                        table.insert(l, opt)
                    end
                end
                return l
            end
            return value
        end
        local function display()
            if multi then
                local names = {}
                for _, opt in ipairs(output()) do
                    table.insert(names, tostring(opt))
                end
                Text.Text = #names > 0 and table.concat(names, ", ") or (o.Placeholder or "None")
            else
                Text.Text = value ~= nil and tostring(value) or (o.Placeholder or "Select")
            end
            api.Value = output()
            SetFlag(o.Flag, api.Value)
        end
        function api:Set(v, silent)
            if multi then
                value = {}
                for _, x in ipairs(type(v) == "table" and v or {}) do
                    value[x] = true
                end
            else
                value = v
            end
            display()
            if not silent and o.Callback then
                task.spawn(o.Callback, api.Value)
            end
        end
        function api:Refresh(newOptions, keep)
            options = newOptions or {}
            if not keep then
                value = multi and {} or nil
            end
            display()
        end

        Connect(Btn.MouseButton1Click, function()
            Tween(Chev, 0.3, { Rotation = 180 })
            Window:_openMenu(Btn, options, function(opt)
                if multi then
                    return value[opt] == true
                end
                return value == opt
            end, function(opt)
                if multi then
                    value[opt] = not value[opt] or nil
                else
                    value = opt
                end
                display()
                if o.Callback then
                    task.spawn(o.Callback, api.Value)
                end
                return not multi
            end, function()
                Tween(Chev, 0.3, { Rotation = 0 })
            end)
        end)

        display()
        RegisterFlag(o.Flag, api, api.Value)
        return api
    end

    -- Segmented ----------------------------------------------------
    function SectionMethods:Segmented(a, b, c, d)
        local o = type(a) == "table" and a or { Name = a, Options = b, Default = c, Callback = d }
        local options = o.Options or {}
        local widths, total = {}, 0
        for i, opt in ipairs(options) do
            widths[i] = o.SegmentWidth or math.max(54, #tostring(opt) * 7 + 24)
            total += widths[i]
        end
        local value = o.Default
        if table.find(options, value) == nil then
            value = options[1]
        end
        local Row = NewRow(self, { Name = o.Name, Description = o.Description, Icon = o.Icon, Right = total + 22 })
        local Bar = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(total + 4, compact and 34 or 30),
            ZIndex = 2,
            Parent = Row,
        }, { Corner(10) })
        Bind(Bar, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT" })
        local Pill = New("Frame", {
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(0, widths[1] or 60, 1, -4),
            Parent = Bar,
        }, { Corner(8), Stroke(BLACK, 0.9, 0.6) })
        Bind(Pill, { BackgroundColor3 = "SegPill", BackgroundTransparency = "SegPillT" })

        local api = { Type = "Segmented" }
        local buttons = {}
        local function offsetOf(idx)
            local x = 2
            for i = 1, idx - 1 do
                x += widths[i]
            end
            return x
        end
        function api:Set(v, silent)
            local idx = table.find(options, v)
            if not idx then
                return
            end
            value = v
            api.Value = v
            SetFlag(o.Flag, v)
            Tween(Pill, 0.45, { Position = UDim2.fromOffset(offsetOf(idx), 2), Size = UDim2.new(0, widths[idx], 1, -4) }, Enum.EasingStyle.Back)
            for opt, btn in pairs(buttons) do
                btn.FontFace = F(opt == v and W_SEMI or W_MED)
            end
            if not silent and o.Callback then
                task.spawn(o.Callback, v)
            end
        end
        for i, opt in ipairs(options) do
            local B = Bind(New("TextButton", {
                Position = UDim2.fromOffset(offsetOf(i), 2),
                Size = UDim2.new(0, widths[i], 1, -4),
                BackgroundTransparency = 1,
                Text = tostring(opt),
                TextSize = 13,
                FontFace = F(W_MED),
                ZIndex = 2,
                Parent = Bar,
            }), { TextColor3 = "Text" })
            buttons[opt] = B
            Connect(B.MouseButton1Click, function()
                if value ~= opt then
                    api:Set(opt)
                end
            end)
        end
        api:Set(value, true)
        RegisterFlag(o.Flag, api, value)
        return api
    end

    -- Keybind ------------------------------------------------------
    function SectionMethods:Keybind(a, b, c)
        local o = type(a) == "table" and a or { Name = a, Default = b, Callback = c }
        local key = o.Default
        if type(key) == "string" then
            key = Enum.KeyCode[key]
        end
        local Row = NewRow(self, { Name = o.Name, Description = o.Description, Icon = o.Icon, Right = 130 })
        local Box = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(0, compact and 32 or 28),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "",
            TextSize = 13,
            FontFace = F(W_SEMI),
            AutoButtonColor = false,
            ZIndex = 2,
            Parent = Row,
        }, { Corner(9), Pad(0, 12, 0, 12), New("UISizeConstraint", { MinSize = Vector2.new(70, 0) }) })
        Bind(Box, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT", TextColor3 = "Text" })
        local st = Stroke(Theme.Current.Accent, 1, 2)
        st.Parent = Box
        Hook(function(T)
            st.Color = T.Accent
        end)
        PressScale(Box)

        local api = { Value = key, Type = "Keybind" }
        local listening = false
        local pulse
        local function display()
            Box.Text = listening and "Press a key..." or (key and key.Name or "None")
        end
        function api:Set(k, silent)
            if type(k) == "string" then
                k = Enum.KeyCode[k]
            end
            key = k
            api.Value = k
            SetFlag(o.Flag, k)
            display()
            if not silent and o.Changed then
                task.spawn(o.Changed, k)
            end
        end
        Connect(Box.MouseButton1Click, function()
            listening = true
            Window._binding = true
            display()
            st.Transparency = 0.2
            pulse = Loop(st, 0.6, { Transparency = 0.8 })
        end)
        Connect(UserInputService.InputBegan, function(input, gpe)
            if listening then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    task.defer(function()
                        Window._binding = false
                    end)
                    if pulse then
                        pulse:Cancel()
                    end
                    Tween(st, 0.25, { Transparency = 1 })
                    if input.KeyCode == Enum.KeyCode.Escape then
                        display()
                    elseif input.KeyCode == Enum.KeyCode.Backspace then
                        api:Set(nil)
                    else
                        api:Set(input.KeyCode)
                    end
                elseif IsClick(input) then
                    -- clicked elsewhere: stop listening and keep the old key
                    listening = false
                    task.defer(function()
                        Window._binding = false
                    end)
                    if pulse then
                        pulse:Cancel()
                    end
                    Tween(st, 0.25, { Transparency = 1 })
                    display()
                end
                return
            end
            if gpe or Window._binding then
                return
            end
            if key and input.KeyCode == key and o.Callback then
                task.spawn(o.Callback)
            end
        end)
        display()
        RegisterFlag(o.Flag, api, key)
        return api
    end

    -- Input --------------------------------------------------------
    function SectionMethods:Input(a, b, c)
        local o = type(a) == "table" and a or { Name = a, Placeholder = b, Callback = c }
        local Row = NewRow(self, { Name = o.Name, Description = o.Description, Icon = o.Icon, Right = L.Field + 20 })
        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(L.Field, compact and 32 or 28),
            Text = o.Default or "",
            PlaceholderText = o.Placeholder or "",
            TextSize = 13,
            FontFace = F(W_REG),
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            ClipsDescendants = true,
            ZIndex = 2,
            Parent = Row,
        }, { Corner(9), Pad(0, 10, 0, 10) })
        Bind(Box, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT", TextColor3 = "Text", PlaceholderColor3 = "SubText" })
        local st = Stroke(Theme.Current.Accent, 1, 2)
        st.Parent = Box
        Hook(function(T)
            st.Color = T.Accent
        end)

        local api = { Value = Box.Text, Type = "Input" }
        function api:Set(t, silent)
            local text = tostring(t or "")
            if o.Numeric then
                text = (string.gsub(text, "[^%d%.%-]", ""))
            end
            Box.Text = text
            api.Value = text
            SetFlag(o.Flag, api.Value)
            if not silent and o.Callback then
                task.spawn(o.Callback, api.Value, false)
            end
        end
        if o.Numeric then
            Connect(Box:GetPropertyChangedSignal("Text"), function()
                local clean = string.gsub(Box.Text, "[^%d%.%-]", "")
                if clean ~= Box.Text then
                    Box.Text = clean
                end
            end)
        end
        Connect(Box.Focused, function()
            Tween(st, 0.15, { Transparency = 0.4 })
        end)
        Connect(Box.FocusLost, function(enter)
            Tween(st, 0.25, { Transparency = 1 })
            api.Value = Box.Text
            SetFlag(o.Flag, api.Value)
            if o.Callback then
                task.spawn(o.Callback, Box.Text, enter)
            end
        end)
        RegisterFlag(o.Flag, api, api.Value)
        return api
    end

    -- Label & Paragraph ---------------------------------------------
    function SectionMethods:Label(a)
        local text = type(a) == "table" and (a.Text or a.Name) or tostring(a)
        local Row = NewRow(self, { Height = 38, SearchName = text, NoHover = true })
        local L2 = Bind(Label({
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -28, 1, 0),
            Text = text,
            TextSize = 13,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Row,
        }), { TextColor3 = "SubText" })
        return {
            Type = "Label",
            Set = function(_, t)
                L2.Text = t
            end,
        }
    end

    function SectionMethods:Paragraph(a, b)
        local o = type(a) == "table" and a or { Title = a, Content = b }
        local Row = NewRow(self, { Height = 0, SearchName = o.Title, NoHover = true })
        Row.AutomaticSize = Enum.AutomaticSize.Y
        local Inner = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = Row,
        }, { List(4), Pad(12, 14, 13, 14) })
        local TitleL = Bind(Label({
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = o.Title or "",
            TextSize = 14,
            FontFace = F(W_SEMI),
            TextWrapped = true,
            LayoutOrder = 1,
            Parent = Inner,
        }), { TextColor3 = "Text" })
        local BodyL = Bind(Label({
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = o.Content or "",
            TextSize = 13,
            TextWrapped = true,
            LayoutOrder = 2,
            Parent = Inner,
        }), { TextColor3 = "SubText" })
        return {
            Type = "Paragraph",
            Set = function(_, title, content)
                if title then
                    TitleL.Text = title
                end
                if content then
                    BodyL.Text = content
                end
            end,
        }
    end

    -- Key status: type, status, time left, expiry, masked key and a copy button.
    -- Info = { Key, Tier, ExpiresAt, Remaining } (defaults to SlimeUI.KeyInfo set by KeySystem).
    function SectionMethods:KeyStatus(o)
        o = o or {}
        local info = o.Info or SlimeUI.KeyInfo
        if type(info) ~= "table" or type(info.Key) ~= "string" then
            local empty = self:Label(o.EmptyText or "No key info: this script was started without the key system.")
            return { Type = "KeyStatus", Refresh = function() end, TimeLeft = function() return nil end, Label = empty }
        end

        local title = o.Title or Window.Title or "SlimeUI"
        local notify = o.Notify ~= false
        local startedAt = os.time()
        -- Unix time the key expires, or nil for a lifetime key
        local expiresAt = tonumber(info.ExpiresAt) or (tonumber(info.Remaining) and startedAt + tonumber(info.Remaining)) or nil

        local function maskKey(key)
            local parts = string.split(key, "-")
            for i = 3, #parts - 1 do
                parts[i] = string.rep("•", #parts[i])
            end
            return table.concat(parts, "-")
        end
        local function formatLeft(seconds)
            seconds = math.max(0, math.floor(seconds))
            local d, h, m = math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600), math.floor(seconds % 3600 / 60)
            if d > 0 then
                return string.format("%dd %dh %dm", d, h, m)
            elseif h > 0 then
                return string.format("%dh %dm", h, m)
            end
            return string.format("%dm", math.max(m, 1))
        end

        self:Label("Type: " .. (info.Tier == "premium" and "Premium" or "Free"))
        local StatusLabel = self:Label("Status: Active")
        local LeftLabel = self:Label("Time left: ...")
        self:Label("Expires: " .. (expiresAt and os.date("%Y-%m-%d %H:%M", expiresAt) or "Never (lifetime)"))
        if o.ShowKey ~= false then
            self:Label("Key: " .. maskKey(info.Key))
        end

        local warnedSoon, warnedExpired = false, false
        local function refresh()
            if not expiresAt then
                LeftLabel:Set("Time left: Lifetime")
                return
            end
            local left = expiresAt - os.time()
            if left <= 0 then
                StatusLabel:Set("Status: Expired")
                LeftLabel:Set("Time left: 0m (get a new key to keep playing)")
                if notify and not warnedExpired then
                    warnedExpired = true
                    Window:Notify({ Title = title, Content = "Your key has expired. Get a new key next time you run the script.", Type = "Warning", Duration = 8 })
                end
                return
            end
            StatusLabel:Set(left <= 3600 and "Status: Expiring soon" or "Status: Active")
            LeftLabel:Set("Time left: " .. formatLeft(left))
            if notify and left <= 600 and not warnedSoon then
                warnedSoon = true
                Window:Notify({ Title = title, Content = "Your key expires in " .. formatLeft(left) .. ".", Type = "Warning", Duration = 6 })
            end
        end
        refresh()
        task.spawn(function()
            while not Window.Destroyed do
                task.wait(30)
                refresh()
            end
        end)

        if o.CopyButton ~= false then
            self:Button({
                Name = "Copy Key",
                Description = "Copy your full key to the clipboard.",
                Icon = "key",
                ButtonText = "Copy",
                Callback = function()
                    local ok = type(setclipboard) == "function" and pcall(setclipboard, info.Key)
                    Window:Notify({
                        Title = title,
                        Content = ok and "Key copied to clipboard!" or ("Could not copy. Key: " .. info.Key),
                        Type = ok and "Success" or "Warning",
                        Duration = ok and 3 or 8,
                    })
                end,
            })
        end

        return {
            Type = "KeyStatus",
            Info = info,
            Refresh = function()
                refresh()
            end,
            -- Seconds left, or nil for a lifetime key
            TimeLeft = function()
                return expiresAt and math.max(0, expiresAt - os.time()) or nil
            end,
        }
    end

    -- Short names + Add... aliases
    local ElementNames = { "Toggle", "Slider", "Button", "Dropdown", "Segmented", "Keybind", "Input", "Label", "Paragraph", "KeyStatus" }
    SectionMethods.Textbox = SectionMethods.Input
    for _, n in ipairs(ElementNames) do
        SectionMethods["Add" .. n] = SectionMethods[n]
    end
    SectionMethods.AddTextbox = SectionMethods.Input

    function TabMethods:Section(name)
        local s = CreateSection(self, name)
        self._section = s
        return s
    end
    TabMethods.AddSection = TabMethods.Section

    function TabMethods:_current()
        if not self._section then
            self._section = CreateSection(self, nil)
        end
        return self._section
    end

    for _, n in ipairs(ElementNames) do
        TabMethods[n] = function(self, ...)
            local s = self:_current()
            return s[n](s, ...)
        end
        TabMethods["Add" .. n] = TabMethods[n]
    end
    TabMethods.Textbox = TabMethods.Input
    TabMethods.AddTextbox = TabMethods.Input

    function TabMethods:Select()
        Window:SelectTab(self)
    end

    local tabCount = 0
    local function CreateTab(o)
        tabCount += 1
        local Tab = setmetatable({
            Name = o.Name or ("Tab " .. tabCount),
            Description = o.Description or "",
            Sections = {},
            Elements = {},
            _order = o._order or tabCount,
        }, TabMethods)
        local color = o.Color or TabPalette[(tabCount - 1) % #TabPalette + 1]

        local Button = New("TextButton", {
            Size = UDim2.new(1, 0, 0, L.TabH),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 1,
            Parent = TabList,
        }, { Corner(11) })
        Bind(Button, { BackgroundColor3 = "Hover" })

        local iconSize = compact and 32 or 24
        local IconBox = New("Frame", {
            AnchorPoint = compact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5),
            Position = compact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 7, 0.5, 0),
            Size = UDim2.fromOffset(iconSize, iconSize),
            BackgroundColor3 = color,
            Parent = Button,
        }, {
            Corner(compact and 9 or 7),
            New("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 200, 200)) }),
        })
        local IconScale = New("UIScale", { Parent = IconBox })
        local img = GetIcon(o.Icon)
        if img then
            New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(math.floor(iconSize * 0.6), math.floor(iconSize * 0.6)),
                BackgroundTransparency = 1,
                Image = img,
                ImageColor3 = WHITE,
                Parent = IconBox,
            })
        else
            Label({
                Size = UDim2.fromScale(1, 1),
                Text = string.upper(string.sub(Tab.Name, 1, 1)),
                TextColor3 = WHITE,
                TextSize = compact and 16 or 13,
                FontFace = F(W_BOLD),
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = IconBox,
            })
        end
        if not compact then
            Tab._name = Bind(Label({
                Position = UDim2.fromOffset(40, 0),
                Size = UDim2.new(1, -46, 1, 0),
                Text = Tab.Name,
                TextSize = 14,
                FontFace = F(W_MED),
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = Button,
            }), { TextColor3 = "Text" })
        end

        local Page = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            Parent = Pages,
        }, { List(16), Pad(4, 12, 18, 6) })
        Bind(Page, { ScrollBarImageColor3 = "SubText" })

        Tab._button = Button
        Tab._page = Page
        Tab._iconScale = IconScale

        Connect(Button.MouseEnter, function()
            if Window.Current ~= Tab then
                Tween(Button, 0.15, { BackgroundTransparency = Theme.Current.HoverT })
            end
            Tween(IconScale, 0.3, { Scale = 1.08 }, Enum.EasingStyle.Back)
        end)
        Connect(Button.MouseLeave, function()
            Tween(Button, 0.2, { BackgroundTransparency = 1 })
            Tween(IconScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
        end)
        Connect(Button.MouseButton1Click, function()
            Window:SelectTab(Tab)
        end)

        table.insert(Window.Tabs, Tab)
        RelayoutTabs()
        if not Window.Current and not o._settings then
            Window:SelectTab(Tab)
        end
        return Tab
    end

    function Window:Tab(a, b, c)
        local o = type(a) == "table" and a or { Name = a, Icon = b, Description = c }
        return CreateTab(o)
    end
    Window.AddTab = Window.Tab

    -----------------------------------------------------------------
    -- Config
    -----------------------------------------------------------------
    local function ConfigPath(name)
        return SlimeUI.Folder .. "/configs/" .. tostring(name or "default") .. ".json"
    end

    function Window:SaveConfig(name)
        if typeof(writefile) ~= "function" then
            return false
        end
        local data = {}
        for flag, api in pairs(SlimeUI.Options) do
            local v = api.Value
            if typeof(v) == "EnumItem" then
                v = { __enum = "KeyCode", name = v.Name }
            end
            if v ~= nil then
                data[flag] = v
            end
        end
        local ok = pcall(function()
            EnsureFolder(SlimeUI.Folder .. "/configs")
            writefile(ConfigPath(name), HttpService:JSONEncode(data))
        end)
        return ok
    end

    function Window:LoadConfig(name)
        if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then
            return false
        end
        local ok, data = pcall(function()
            local path = ConfigPath(name)
            if not isfile(path) then
                return nil
            end
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(data) ~= "table" then
            return false
        end
        for flag, v in pairs(data) do
            local api = SlimeUI.Options[flag]
            if api and api.Set then
                if type(v) == "table" and v.__enum == "KeyCode" then
                    v = Enum.KeyCode[v.name]
                end
                pcall(api.Set, api, v)
            end
        end
        return true
    end

    -----------------------------------------------------------------
    -- Floating toggle button
    -----------------------------------------------------------------
    local ToggleBtn, ToggleBtnConn
    function Window:SetToggleButton(on)
        self.ToggleButtonEnabled = on and true or false
        if on and not ToggleBtn then
            local size = compact and 56 or 50
            local Btn = New("TextButton", {
                Name = "ToggleButton",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = self._toggleBtnPos or UDim2.new(0, 18 + size / 2, 0.5, 0),
                Size = UDim2.fromOffset(size, size),
                BackgroundColor3 = Color3.fromRGB(18, 20, 28),
                BackgroundTransparency = 0.2,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 40,
                Parent = Gui,
            }, { Corner("full") })
            StaticEdge(Btn, Themes.Glass, 1.2)
            MakeLogo(LogoImage, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.58, 0.58),
                Parent = Btn,
            })

            -- Static button: tap to toggle the UI, drag to move it
            local pressing, moved, startInput, startPos = false, false, nil, nil
            Btn.InputBegan:Connect(function(input)
                if not IsClick(input) then
                    return
                end
                pressing, moved = true, false
                startInput, startPos = input.Position, Btn.Position
                local cn
                cn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        cn:Disconnect()
                        pressing = false
                        if moved then
                            self._toggleBtnPos = Btn.Position
                        else
                            self:Toggle()
                        end
                    end
                end)
            end)
            ToggleBtnConn = Connect(UserInputService.InputChanged, function(input)
                if not pressing or not IsMove(input) or not Btn.Parent then
                    return
                end
                local d = input.Position - startInput
                if not moved and d.Magnitude > 6 then
                    moved = true
                end
                if moved then
                    local vp = Gui.AbsoluteSize
                    local half = size / 2
                    local px = math.clamp(startPos.X.Scale * vp.X + startPos.X.Offset + d.X, half + 4, vp.X - half - 4)
                    local py = math.clamp(startPos.Y.Scale * vp.Y + startPos.Y.Offset + d.Y, half + 4, vp.Y - half - 4)
                    Btn.Position = UDim2.fromOffset(px, py)
                end
            end)
            ToggleBtn = Btn
        elseif not on and ToggleBtn then
            if ToggleBtnConn then
                ToggleBtnConn:Disconnect()
                ToggleBtnConn = nil
            end
            ToggleBtn:Destroy()
            ToggleBtn = nil
        end
    end

    -----------------------------------------------------------------
    -- Built-in Settings tab
    -----------------------------------------------------------------
    local function BuildSettings()
        local S = CreateTab({
            Name = "Settings",
            Icon = "settings",
            Description = "Theme, controls and configs",
            Color = Color3.fromRGB(142, 142, 147),
            _order = 1e6,
            _settings = true,
        })
        local Look = S:Section("Appearance")
        local accentDrop
        Look:Dropdown({
            Name = "Theme",
            Options = ThemeNames,
            Default = Theme.Name,
            Callback = function(v)
                Window:SetTheme(v)
                if accentDrop then
                    accentDrop:Set("Theme", true)
                end
            end,
        })
        local currentAccent = "Theme"
        if Theme.AccentOverride then
            for name, c in pairs(Accents) do
                if c == Theme.AccentOverride then
                    currentAccent = name
                end
            end
        end
        local accentOptions = { "Theme" }
        for _, name in ipairs(AccentNames) do
            table.insert(accentOptions, name)
        end
        accentDrop = Look:Dropdown({
            Name = "Accent color",
            Options = accentOptions,
            Default = currentAccent,
            Callback = function(v)
                Window:SetAccent(v)
            end,
        })
        Look:Toggle({
            Name = "Background blur",
            Description = "Blur the game world behind the window",
            Default = Window.BlurEnabled,
            Callback = function(v)
                Window:SetBlur(v)
            end,
        })
        Look:Slider({
            Name = "UI scale",
            Min = 60,
            Max = 130,
            Increment = 5,
            Default = 100,
            Suffix = "%",
            Callback = function(v)
                Window:SetScale(v / 100)
            end,
        })

        local Ctl = S:Section("Controls")
        Ctl:Keybind({
            Name = "Toggle UI",
            Default = Window.ToggleKey,
            Changed = function(k)
                Window.ToggleKey = k
            end,
        })
        Ctl:Toggle({
            Name = "Floating button",
            Description = "Round button to open the UI on any device",
            Default = Window.ToggleButtonEnabled,
            Callback = function(v)
                Window:SetToggleButton(v)
            end,
        })

        if typeof(writefile) == "function" then
            local Cfg = S:Section("Config")
            local nameBox = Cfg:Input({ Name = "Config name", Placeholder = "default", Default = "default" })
            Cfg:Button({
                Name = "Save config",
                ButtonText = "Save",
                ButtonIcon = "save",
                Callback = function()
                    local n = Trim(nameBox.Value) ~= "" and Trim(nameBox.Value) or "default"
                    local ok = Window:SaveConfig(n)
                    Window:Notify({ Title = ok and "Config saved" or "Couldn't save config", Content = n, Type = ok and "Success" or "Error", Duration = 3 })
                end,
            })
            Cfg:Button({
                Name = "Load config",
                ButtonText = "Load",
                ButtonIcon = "folder-open",
                Callback = function()
                    local n = Trim(nameBox.Value) ~= "" and Trim(nameBox.Value) or "default"
                    local ok = Window:LoadConfig(n)
                    Window:Notify({ Title = ok and "Config loaded" or "Config not found", Content = n, Type = ok and "Success" or "Warning", Duration = 3 })
                end,
            })
        end

        local About = S:Section("About")
        About:Paragraph({
            Title = Window.Title .. "  v" .. SlimeUI.Version,
            Content = "UI library for Roblox scripts by " .. SlimeUI.Author .. ".",
        })
        About:Button({
            Name = "Unload UI",
            Description = "Close the window and remove everything",
            ButtonText = "Unload",
            Style = "Danger",
            Callback = function()
                Window:Destroy()
            end,
        })
    end

    -----------------------------------------------------------------
    -- Startup splash
    -----------------------------------------------------------------
    local function PlaySplash(onDone)
        local T = Theme.Current
        local Splash = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(260, 220),
            BackgroundTransparency = 1,
            ZIndex = 60,
            Parent = Gui,
        })
        local SScale = New("UIScale", { Scale = 0.6, Parent = Splash })
        local Box = New("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.fromOffset(112, 112),
            BackgroundColor3 = T.Window,
            BackgroundTransparency = math.min(T.WindowT, 0.45),
            GroupTransparency = 1,
            Parent = Splash,
        }, { Corner(32) })
        New("Frame", {
            Size = UDim2.new(1, 0, 0.7, 0),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Parent = Box,
        }, { Corner(32), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(math.min(T.Sheen, 0.9), 1) }) })
        local SLogo = MakeLogo(LogoImage, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(62, 62),
            Rotation = -25,
            Parent = Box,
        })
        local BoxEdgeFrame = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.fromOffset(112, 112),
            BackgroundTransparency = 1,
            Parent = Splash,
        }, { Corner(32) })
        local BoxEdge = StaticEdge(BoxEdgeFrame, T, 1.2)
        BoxEdge.Transparency = 1
        local NameL = Label({
            Position = UDim2.fromOffset(0, 128),
            Size = UDim2.new(1, 0, 0, 26),
            Text = Window.Title,
            TextColor3 = T.Text,
            TextTransparency = 1,
            TextSize = 22,
            FontFace = F(W_BOLD),
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = Splash,
        })
        local ByL = Label({
            Position = UDim2.fromOffset(0, 154),
            Size = UDim2.new(1, 0, 0, 16),
            Text = "by " .. SlimeUI.Author,
            TextColor3 = T.SubText,
            TextTransparency = 1,
            TextSize = 13,
            FontFace = F(W_MED),
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = Splash,
        })
        local Track = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 186),
            Size = UDim2.fromOffset(130, 4),
            BackgroundColor3 = WHITE,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Splash,
        }, { Corner("full") })
        local Bar = New("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Parent = Track,
        }, { Corner("full") })

        BlurTo(Window.BlurEnabled)
        Tween(SScale, 0.7, { Scale = 1 }, Enum.EasingStyle.Back)
        Tween(Box, 0.45, { GroupTransparency = 0 })
        Tween(BoxEdge, 0.45, { Transparency = 0 })
        Tween(SLogo, 0.8, { Rotation = 0 }, Enum.EasingStyle.Back)
        task.delay(0.18, function()
            Tween(NameL, 0.4, { TextTransparency = 0 })
            Tween(ByL, 0.4, { TextTransparency = 0.1 })
            Tween(Track, 0.4, { BackgroundTransparency = 0.8 })
            Tween(Bar, 1, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        end)
        task.delay(1.45, function()
            Tween(SScale, 0.35, { Scale = 1.15 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            Tween(Box, 0.3, { GroupTransparency = 1 })
            Tween(BoxEdge, 0.25, { Transparency = 1 })
            Tween(NameL, 0.25, { TextTransparency = 1 })
            Tween(ByL, 0.25, { TextTransparency = 1 })
            Tween(Track, 0.25, { BackgroundTransparency = 1 })
            Tween(Bar, 0.25, { BackgroundTransparency = 1 })
            task.delay(0.15, onDone)
            task.delay(0.45, function()
                Splash:Destroy()
            end)
        end)
    end

    -----------------------------------------------------------------
    -- Destroy
    -----------------------------------------------------------------
    function Window:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self:_closeMenu()
        for _, c in ipairs(self._conns) do
            pcall(function()
                c:Disconnect()
            end)
        end
        table.clear(self._conns)
        if BlurFx then
            local fx = BlurFx
            Tween(fx, 0.25, { Size = 0 })
            task.delay(0.3, function()
                fx:Destroy()
            end)
        end
        Tween(Scale, 0.25, { Scale = FitScale() * 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Tween(Main, 0.25, { GroupTransparency = 1 })
        Tween(Edge, 0.2, { Transparency = 1 })
        task.delay(0.3, function()
            Gui:Destroy()
        end)
        Theme.Objects = {}
        Theme.Hooks = {}
        if env.__SlimeUIWindow == self then
            env.__SlimeUIWindow = nil
        end
    end

    -----------------------------------------------------------------
    -- Startup
    -----------------------------------------------------------------
    local wantButton = opts.ToggleButton
    if wantButton == nil then
        wantButton = true
    end
    Window.ToggleButtonEnabled = wantButton
    if opts.SettingsTab ~= false then
        BuildSettings()
    end

    task.defer(function()
        if not Window.Current and Window.Tabs[1] then
            local first = Window.Tabs[1]
            for _, t in ipairs(Window.Tabs) do
                if t._order < first._order then
                    first = t
                end
            end
            Window:SelectTab(first)
        end
    end)

    local function Open()
        if Window.Destroyed then
            return
        end
        Window:SetVisible(true)
        if Window.ToggleButtonEnabled then
            Window:SetToggleButton(true)
        end
    end
    if opts.Loader == false then
        task.defer(Open)
    else
        PlaySplash(Open)
    end

    return Window
end

