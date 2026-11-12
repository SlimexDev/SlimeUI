---------------------------------------------------------------------
-- Key System
---------------------------------------------------------------------
function SlimeUI:KeySystem(o)
    o = o or {}
    local file = o.FileName or (SlimeUI.Folder .. "/key.txt")
    local keys = o.Key or o.Keys
    if type(keys) == "string" then
        keys = { keys }
    end

    -- Key server: Api = "https://host/api" or { Url = "...", Hwid = function() return "..." end }
    local apiUrl, apiHwid, apiTimeout = nil, nil, 10
    if type(o.Api) == "string" then
        apiUrl = o.Api
    elseif type(o.Api) == "table" then
        apiUrl, apiHwid = o.Api.Url, o.Api.Hwid
        apiTimeout = tonumber(o.Api.Timeout) or apiTimeout
    end
    if type(apiUrl) == "string" then
        apiUrl = string.gsub(apiUrl, "/+$", "")
    else
        apiUrl = nil
    end
    local NETWORK_ERROR = "Couldn't reach the key server. Try again."
    local info -- { Key, Tier, ExpiresAt, Remaining } from the key server

    local function GetHwid()
        if type(apiHwid) == "function" then
            local ok, h = pcall(apiHwid)
            if ok and h ~= nil and tostring(h) ~= "" then
                return tostring(h)
            end
        end
        if typeof(gethwid) == "function" then
            local ok, h = pcall(gethwid)
            if ok and h ~= nil and tostring(h) ~= "" then
                return tostring(h)
            end
        end
        local ok, id = pcall(function()
            return game:GetService("RbxAnalyticsService"):GetClientId()
        end)
        return ok and id or "unknown"
    end

    -- Returns valid, message, networkError
    local function remoteCheck(k)
        local url = apiUrl .. "/verify?key=" .. HttpService:UrlEncode(k) .. "&hwid=" .. HttpService:UrlEncode(GetHwid())
        -- Some executors wait a long time on a dead server, so give up after apiTimeout seconds.
        local finished, ok, body = false, false, nil
        task.spawn(function()
            ok, body = pcall(function()
                return game:HttpGet(url)
            end)
            finished = true
        end)
        local started = os.clock()
        while not finished and os.clock() - started < apiTimeout do
            task.wait(0.05)
        end
        if not finished or not ok or type(body) ~= "string" then
            return false, NETWORK_ERROR, true
        end
        local decoded, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if not decoded or type(data) ~= "table" then
            return false, NETWORK_ERROR, true
        end
        if data.valid == true then
            info = {
                Key = data.key or k,
                Tier = data.tier or "free",
                ExpiresAt = tonumber(data.expiresAt),
                Remaining = tonumber(data.remaining),
            }
            return true
        end
        return false, type(data.message) == "string" and data.message or "That key isn't valid. Get a new key and try again."
    end

    local function check(k)
        k = Trim(k)
        if k == "" then
            return false, "Enter a key first."
        end
        if o.Validate then
            local ok, res, msg = pcall(o.Validate, k)
            if not ok then
                return false, "Couldn't check the key. Try again."
            end
            if res then
                return true
            end
            return false, msg or "That key isn't valid. Get a new key and try again."
        end
        if apiUrl then
            return remoteCheck(k)
        end
        if keys then
            for _, v in ipairs(keys) do
                if Trim(v) == k then
                    return true
                end
            end
        end
        return false, "That key isn't valid. Get a new key and try again."
    end

    -- "Premium · Lifetime" / "Free · 23h 12m left"
    local function DescribeInfo(i)
        local tier = i.Tier == "premium" and "Premium" or "Free"
        if not i.Remaining then
            return tier .. " · Lifetime"
        end
        local s = math.max(0, math.floor(i.Remaining))
        local d, h, m = math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60)
        local left
        if d > 0 then
            left = d .. "d " .. h .. "h"
        elseif h > 0 then
            left = h .. "h " .. m .. "m"
        else
            left = math.max(m, 1) .. "m"
        end
        return tier .. " · " .. left .. " left"
    end

    -- Key saved from a previous session
    local savedKey, savedMsg, savedNetwork
    if o.SaveKey ~= false and typeof(isfile) == "function" and typeof(readfile) == "function" then
        local ok, saved = pcall(function()
            return isfile(file) and readfile(file) or nil
        end)
        if ok and saved and Trim(saved) ~= "" then
            local valid, msg, network = check(saved)
            if valid then
                SlimeUI.KeyInfo = info
                return true, info
            end
            savedKey, savedMsg, savedNetwork = Trim(saved), msg, network
        end
    end

    local T = ThemeCopy(Themes[o.Theme or ""] and o.Theme or DefaultTheme, ParseOpacity(o.Opacity, o.Solid, 1))
    local accent = (typeof(o.Accent) == "Color3" and o.Accent) or Accents[o.Accent or ""] or T.Accent
    local conns = {}
    local function Connect(sig, fn)
        local c = sig:Connect(fn)
        table.insert(conns, c)
        return c
    end

    local Gui = NewScreenGui("SlimeUIKey", 10000)
    local Dim = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = BLACK,
        BackgroundTransparency = 1,
        Parent = Gui,
    })

    local vp = ViewportSize()
    -- Optional link row under the main buttons (Discord / Premium)
    local links = {}
    if type(o.Discord) == "string" and o.Discord ~= "" then
        table.insert(links, { Text = "Discord", Icon = "message-circle", Color = Color3.fromRGB(88, 101, 242), Url = o.Discord, Done = "Discord invite copied." })
    end
    if type(o.Premium) == "string" and o.Premium ~= "" then
        table.insert(links, { Text = "Premium", Icon = "crown", Color = Color3.fromRGB(255, 190, 50), Url = o.Premium, Done = "Premium link copied." })
    end
    local extra = #links > 0 and 44 or 0

    local W, H = math.min(380, vp.X - 32), 332 + extra
    local fit = math.min(1, (vp.Y - 24) / H)
    local Holder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H),
        BackgroundTransparency = 1,
        Parent = Gui,
    })
    local Scale = New("UIScale", { Scale = fit * 0.86, Parent = Holder })
    local Card = New("CanvasGroup", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Window,
        BackgroundTransparency = math.min(T.WindowT, 0.45),
        GroupTransparency = 1,
        Parent = Holder,
    }, { Corner(26) })
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        Parent = Card,
    }, { Corner(26), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(T.Sheen, 1) }) })
    local EdgeFrame = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Holder }, { Corner(26) })
    local Edge = StaticEdge(EdgeFrame, T, 1.2)
    Edge.Transparency = 1

    if T.Effect == "Slime" then
        SlimeDecor(Card, T, { Drips = { 0.1, 0.19, 0.82, 0.91 }, Blobs = 10, Bubbles = 7 })
    end

    -- Logo (static)
    local LogoHolder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 24),
        Size = UDim2.fromOffset(64, 64),
        BackgroundTransparency = 1,
        Parent = Card,
    })
    MakeLogo(ResolveImage(o.Logo or (SlimeUI.Folder .. "/logo.png")), {
        Size = UDim2.fromScale(1, 1),
        Parent = LogoHolder,
    })

    Label({
        Position = UDim2.fromOffset(0, 98),
        Size = UDim2.new(1, 0, 0, 26),
        Text = o.Title or "SlimeUI",
        TextColor3 = T.Text,
        TextSize = 22,
        FontFace = F(W_BOLD),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Card,
    })
    Label({
        Position = UDim2.fromOffset(20, 126),
        Size = UDim2.new(1, -40, 0, 18),
        Text = o.Subtitle or "Enter your key to continue",
        TextColor3 = T.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Card,
    })

    local InputFrame = New("Frame", {
        Position = UDim2.fromOffset(22, 160),
        Size = UDim2.new(1, -44, 0, 44),
        BackgroundColor3 = T.Field,
        BackgroundTransparency = T.FieldT,
        Parent = Card,
    }, { Corner(12) })
    local InputStroke = Stroke(accent, 1, 1.5)
    InputStroke.Parent = InputFrame
    IconLabel("key", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        ImageColor3 = T.SubText,
        Parent = InputFrame,
    })
    local KeyBox = New("TextBox", {
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -54, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = o.Placeholder or "Paste your key here",
        PlaceholderColor3 = T.SubText,
        TextColor3 = T.Text,
        TextSize = 15,
        FontFace = F(W_MED),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Parent = InputFrame,
    })

    local Status = Label({
        Position = UDim2.fromOffset(22, 210),
        Size = UDim2.new(1, -44, 0, 18),
        Text = o.Note or "Your key is saved on this device after verifying.",
        TextColor3 = T.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Card,
    })

    -- x: 0 = left half, 0.5 = right half, nil = full width
    local function MakeButton(text, icon, primary, x, y, h)
        y, h = y or 238, h or 44
        local B = New("TextButton", {
            Position = x and UDim2.new(x, x == 0 and 22 or 5, 0, y) or UDim2.fromOffset(22, y),
            Size = x and UDim2.new(0.5, -27, 0, h) or UDim2.new(1, -44, 0, h),
            BackgroundColor3 = primary and accent or T.Field,
            BackgroundTransparency = primary and 0 or math.max(0, T.FieldT - 0.04),
            AutoButtonColor = false,
            Text = "",
            Parent = Card,
        }, { Corner(12) })
        local sc = New("UIScale", { Parent = B })
        local Content = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = B,
        }, { List(7, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center) })
        local Ic = IconLabel(icon, {
            Size = UDim2.fromOffset(16, 16),
            ImageColor3 = primary and WHITE or T.Text,
            LayoutOrder = 1,
            Parent = Content,
        })
        local Tx = Label({
            Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = text,
            TextColor3 = primary and WHITE or T.Text,
            TextSize = 14,
            FontFace = F(W_SEMI),
            LayoutOrder = 2,
            Parent = Content,
        })
        Connect(B.MouseButton1Down, function()
            Tween(sc, 0.1, { Scale = 0.95 })
        end)
        Connect(B.MouseButton1Up, function()
            Tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
        end)
        Connect(B.MouseLeave, function()
            Tween(sc, 0.2, { Scale = 1 })
        end)
        return B, Tx, Ic
    end

    local GetKeyBtn = MakeButton("Get Key", "link", false, 0)
    local VerifyBtn, VerifyText, VerifyIcon = MakeButton("Verify", "check", true, 0.5)
    local VerifyGrad = New("UIGradient", { Enabled = false, Parent = VerifyBtn })
    if T.Accent2 and not o.Accent then
        VerifyBtn.BackgroundColor3 = AccentColor(T, VerifyGrad)
    end

    local LinkButtons = {}
    for i, l in ipairs(links) do
        local x = #links == 2 and (i == 1 and 0 or 0.5) or nil
        local B, _, Ic = MakeButton(l.Text, l.Icon, false, x, 290, 36)
        Ic.ImageColor3 = l.Color
        LinkButtons[B] = l
    end

    Label({
        Position = UDim2.fromOffset(0, 298 + extra),
        Size = UDim2.new(1, 0, 0, 16),
        Text = (o.Title or "SlimeUI") .. "  ·  by " .. SlimeUI.Author,
        TextColor3 = T.SubText,
        TextTransparency = 0.3,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Card,
    })

    local CloseBtn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = T.Field,
        BackgroundTransparency = T.FieldT,
        AutoButtonColor = false,
        Text = "",
        Parent = Card,
    }, { Corner("full") })
    IconLabel("x", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(14, 14),
        ImageColor3 = T.SubText,
        Parent = CloseBtn,
    })

    -- Logic
    local done = Instance.new("BindableEvent")
    local finished, busy = false, false
    local fails = 0 -- wrong keys in a row; 3 locks Verify for a few seconds

    local function setStatus(text, color)
        Status.Text = text
        Status.TextColor3 = color or T.SubText
        Status.TextTransparency = 1
        Tween(Status, 0.25, { TextTransparency = 0 })
    end

    local function copyLink(url, doneText)
        local copied = pcall(function()
            setclipboard(url)
        end)
        if copied then
            setStatus(doneText, accent)
        else
            setStatus(url, T.Text)
        end
    end

    -- Tell the user why the saved key no longer works (key server only)
    if savedMsg and apiUrl then
        if savedNetwork then
            KeyBox.Text = savedKey
        end
        setStatus(savedNetwork and savedMsg or ("Saved key: " .. savedMsg), savedNetwork and WARNING or DANGER)
    end

    local function close(result)
        if finished then
            return
        end
        finished = true
        Tween(Scale, 0.3, { Scale = fit * (result and 1.06 or 0.9) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Tween(Card, 0.3, { GroupTransparency = 1 })
        Tween(Edge, 0.2, { Transparency = 1 })
        Tween(Dim, 0.35, { BackgroundTransparency = 1 })
        task.delay(0.4, function()
            for _, c in ipairs(conns) do
                c:Disconnect()
            end
            Gui:Destroy()
            done:Fire(result)
        end)
    end

    local function verify()
        if busy or finished then
            return
        end
        busy = true
        VerifyText.Text = "Checking..."
        VerifyIcon.Image = GetIcon("loader-2") or ""
        local spin = TweenService:Create(VerifyIcon, TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
        spin:Play()
        local ok, msg, network = check(KeyBox.Text)
        spin:Cancel()
        VerifyIcon.Rotation = 0
        if finished then
            return
        end
        if ok then
            SlimeUI.KeyInfo = info
            if o.SaveKey ~= false and typeof(writefile) == "function" then
                pcall(function()
                    EnsureFolder(string.match(file, "^(.*)/") or SlimeUI.Folder)
                    writefile(file, Trim(KeyBox.Text))
                end)
            end
            VerifyIcon.Image = GetIcon("check") or ""
            VerifyText.Text = "Key verified"
            VerifyGrad.Enabled = false
            Tween(VerifyBtn, 0.25, { BackgroundColor3 = SUCCESS })
            InputStroke.Color = SUCCESS
            Tween(InputStroke, 0.2, { Transparency = 0.2 })
            if info then
                setStatus(DescribeInfo(info) .. "  ·  Loading...", SUCCESS)
                task.wait(1.4)
            else
                setStatus("Welcome! Loading " .. (o.Title or "SlimeUI") .. "...", SUCCESS)
                task.wait(0.8)
            end
            close(true)
        else
            VerifyIcon.Image = GetIcon("check") or ""
            VerifyText.Text = "Verify"
            setStatus(msg, network and WARNING or DANGER)
            InputStroke.Color = DANGER
            Tween(InputStroke, 0.15, { Transparency = 0.1 })
            Shake(Holder)
            task.delay(1.4, function()
                if not finished and not KeyBox:IsFocused() then
                    Tween(InputStroke, 0.4, { Transparency = 1 })
                end
            end)
            if not network then
                fails += 1
            end
            if fails >= 3 then
                fails = 0
                for s = 5, 1, -1 do
                    if finished then
                        return
                    end
                    VerifyText.Text = "Wait " .. s .. "s"
                    task.wait(1)
                end
                if not finished then
                    VerifyText.Text = "Verify"
                end
            end
            busy = false
        end
    end

    Connect(KeyBox.Focused, function()
        InputStroke.Color = accent
        Tween(InputStroke, 0.15, { Transparency = 0.35 })
    end)
    Connect(KeyBox.FocusLost, function(enter)
        if enter then
            task.spawn(verify)
        else
            Tween(InputStroke, 0.2, { Transparency = 1 })
        end
    end)
    Connect(VerifyBtn.MouseButton1Click, function()
        task.spawn(verify)
    end)
    Connect(GetKeyBtn.MouseButton1Click, function()
        if not o.Link then
            setStatus("No key link has been set for this script.", WARNING)
            return
        end
        local copied = pcall(function()
            setclipboard(o.Link)
        end)
        if copied then
            setStatus("Key link copied. Open it in your browser.", accent)
        else
            setStatus("Get your key at: " .. o.Link, T.Text)
        end
    end)
    for B, l in pairs(LinkButtons) do
        Connect(B.MouseButton1Click, function()
            copyLink(l.Url, l.Done)
        end)
    end
    Connect(CloseBtn.MouseButton1Click, function()
        close(false)
    end)

    -- Open animation
    Tween(Dim, 0.4, { BackgroundTransparency = 0.6 })
    Tween(Scale, 0.6, { Scale = fit }, Enum.EasingStyle.Back)
    Tween(Card, 0.35, { GroupTransparency = 0 })
    Tween(Edge, 0.4, { Transparency = 0 })

    local result = done.Event:Wait()
    done:Destroy()
    return result, result and info or nil
end

