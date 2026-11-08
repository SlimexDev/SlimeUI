---------------------------------------------------------------------
-- Theme engine: mọi thuộc tính màu được đăng ký để đổi theme lúc chạy
---------------------------------------------------------------------
local Theme = { Name = "Glass", Current = Themes.Glass, Objects = {}, Hooks = {}, AccentOverride = nil }

local function Bind(inst, map)
    Theme.Objects[inst] = map
    for prop, key in pairs(map) do
        inst[prop] = Theme.Current[key]
    end
    return inst
end

local function Hook(fn)
    table.insert(Theme.Hooks, fn)
    fn(Theme.Current, false)
end

local function ApplyTheme(animated)
    local T = Theme.Current
    for inst, map in pairs(Theme.Objects) do
        if inst.Parent then
            local props = {}
            for prop, key in pairs(map) do
                props[prop] = T[key]
            end
            if animated then
                Tween(inst, 0.35, props)
            else
                for p, v in pairs(props) do
                    inst[p] = v
                end
            end
        else
            Theme.Objects[inst] = nil
        end
    end
    for _, fn in ipairs(Theme.Hooks) do
        pcall(fn, T, animated)
    end
end

local function GlassEdge(parent, thickness)
    local s = New("UIStroke", { Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local g = New("UIGradient", { Rotation = 75, Parent = s })
    Bind(s, { Color = "Edge" })
    Hook(function(T)
        local mid = math.min(1, math.max(T.EdgeA, T.EdgeB) + 0.2)
        g.Transparency = NumberSequence.new({ NSK(0, T.EdgeA), NSK(0.5, mid), NSK(1, T.EdgeB) })
    end)
    s.Parent = parent
    return s, g
end

-- Màu tán sắc nhẹ ở viền trong (hiệu ứng kính lỏng)
local function DispersionColors()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(185, 232, 255)),
        ColorSequenceKeypoint.new(0.5, WHITE),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 236)),
    })
end

local function RimSequence(T)
    return NumberSequence.new({ NSK(0, T.Rim), NSK(0.35, 1), NSK(0.65, 1), NSK(1, math.min(1, T.Rim + 0.2)) })
end

-- Màu nhấn dạng chuyển màu: theme có Accent2 (ví dụ Slime) dùng Accent -> Accent2.
-- Trả về màu nền cần đặt cho đối tượng; grad là UIGradient con của đối tượng đó.
local function AccentColor(T, grad)
    if T.Accent2 then
        grad.Color = ColorSequence.new(T.Accent, T.Accent2)
        grad.Enabled = true
        return WHITE
    end
    grad.Enabled = false
    return T.Accent
end

-- Trang trí riêng cho theme Slime: ánh màu chuyển giống logo, lớp slime gợn sóng
-- ở mép trên có giọt chảy xuống, và bong bóng bóng loáng nổi lên.
-- Trả về Frame để có thể huỷ khi đổi theme.
local function SlimeDecor(parent, T, o)
    o = o or {}
    local c1, c2 = T.Accent, T.Accent2 or T.Accent
    local layer = New("Frame", {
        Name = "SlimeDecor",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 0,
        Parent = parent,
    })

    -- Ánh màu chuyển xanh lá -> xanh ngọc
    New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = WHITE,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        Parent = layer,
    }, {
        New("UIGradient", {
            Rotation = 35,
            Color = ColorSequence.new(c1, c2),
            Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.55, 0.6), NSK(1, 0.1) }),
        }),
    })

    -- Lớp slime gợn sóng ở mép trên
    local count = o.Blobs or 16
    for i = 0, count do
        local h = math.random(20, 32)
        local tone = c1:Lerp(c2, i / count)
        New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(i / count, 0, 0, math.random(-9, -4)),
            Size = UDim2.fromOffset(math.floor(h * 1.7), h),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Parent = layer,
        }, {
            Corner("full"),
            New("UIGradient", { Rotation = 90, Color = ColorSequence.new(tone:Lerp(WHITE, 0.35), tone) }),
        })
    end

    -- Giọt slime chảy xuống, thỉnh thoảng rơi một giọt nhỏ
    for i, x in ipairs(o.Drips or { 0.62, 0.74, 0.87, 0.95 }) do
        local w = 9 + (i % 2) * 5
        local base = 18 + (i % 3) * 6
        local tone = c1:Lerp(c2, x)
        local drip = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(x, 0, 0, -6),
            Size = UDim2.fromOffset(w, base),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Parent = layer,
        }, {
            Corner("full"),
            New("UIGradient", { Rotation = 90, Color = ColorSequence.new(tone, tone:Lerp(WHITE, 0.25)) }),
        })
        New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 2, 1, -4),
            Size = UDim2.fromOffset(3, 6),
            BackgroundColor3 = WHITE,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Parent = drip,
        }, { Corner("full") })
        Loop(drip, 1.6 + i * 0.4, { Size = UDim2.fromOffset(w, base + 14) })
        task.spawn(function()
            task.wait(1 + math.random() * 3)
            while layer.Parent do
                local y = drip.Size.Y.Offset - 10
                local drop = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(x, 0, 0, y),
                    Size = UDim2.fromOffset(w - 3, w - 3),
                    BackgroundColor3 = tone,
                    BorderSizePixel = 0,
                    Parent = layer,
                }, { Corner("full") })
                Tween(drop, 1, { Position = UDim2.new(x, 0, 0, y + 60), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                task.delay(1.05, function()
                    drop:Destroy()
                end)
                task.wait(3 + math.random() * 4)
            end
        end)
    end

    -- Bong bóng bóng loáng nổi lên
    local bubbles = {}
    for i = 1, o.Bubbles or 10 do
        local size = math.random(8, 20)
        local b = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(size, size),
            BackgroundColor3 = c1:Lerp(c2, math.random()),
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            Parent = layer,
        }, { Corner("full"), Stroke(WHITE, 0.5, 1) })
        New("Frame", {
            Position = UDim2.fromScale(0.2, 0.16),
            Size = UDim2.fromScale(0.3, 0.3),
            BackgroundColor3 = WHITE,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Parent = b,
        }, { Corner("full") })
        bubbles[i] = { Frame = b, X = math.random(), Y = math.random(), Speed = 0.02 + math.random() * 0.035, Phase = math.random() * 6.28 }
    end
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not layer.Parent then
            conn:Disconnect()
            return
        end
        local t = os.clock()
        for _, b in ipairs(bubbles) do
            b.Y -= b.Speed * dt
            if b.Y < -0.08 then
                b.Y, b.X = 1.08, math.random()
            end
            b.Frame.Position = UDim2.fromScale(b.X + math.sin(t * 1.3 + b.Phase) * 0.012, b.Y)
        end
    end)
    return layer
end

