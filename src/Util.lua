---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function New(class, props, children)
    local obj = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            parent = v
        else
            obj[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function Corner(r)
    if r == "full" then
        return New("UICorner", { CornerRadius = UDim.new(1, 0) })
    end
    return New("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function Stroke(color, transparency, thickness)
    return New("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Pad(t, r, b, l)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
    })
end

local function List(padding, direction, halign, valign)
    return New("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = valign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
end

local function Tween(obj, time, props, style, direction)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function Loop(obj, time, props, style)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        props
    )
    t:Play()
    return t
end

local function Label(props, children)
    props.BackgroundTransparency = 1
    props.FontFace = props.FontFace or F(W_REG)
    props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return New("TextLabel", props, children)
end

local function Shake(obj)
    if obj:GetAttribute("SlimeShaking") then
        return
    end
    obj:SetAttribute("SlimeShaking", true)
    local base = obj.Position
    task.spawn(function()
        for _, dx in ipairs({ 12, -10, 8, -6, 3, 0 }) do
            Tween(obj, 0.05, { Position = base + UDim2.fromOffset(dx, 0) }, Enum.EasingStyle.Sine)
            task.wait(0.05)
        end
        obj.Position = base
        obj:SetAttribute("SlimeShaking", nil)
    end)
end

local function ViewportSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function IsTouch()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function IsClick(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function GetGuiParent()
    local ok, hui = pcall(function()
        return gethui()
    end)
    if ok and typeof(hui) == "Instance" then
        -- Một số executor trả về ScreenGui (vd. CoreGui.RobloxGui): không lồng ScreenGui vào ScreenGui
        if hui:IsA("LayerCollector") then
            if hui.Parent then
                return hui.Parent
            end
        else
            return hui
        end
    end
    local ok2, core = pcall(function()
        local cg = game:GetService("CoreGui")
        local probe = Instance.new("Folder")
        probe.Parent = cg
        probe:Destroy()
        return cg
    end)
    if ok2 and core then
        return core
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function NewScreenGui(name, order)
    local gui = New("ScreenGui", {
        Name = name,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = order,
    })
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        end
    end)
    gui.Parent = GetGuiParent()
    return gui
end

local function EnsureFolder(path)
    if typeof(makefolder) ~= "function" or typeof(isfolder) ~= "function" then
        return
    end
    local current = ""
    for part in string.gmatch(path, "[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        pcall(function()
            if not isfolder(current) then
                makefolder(current)
            end
        end)
    end
end

-- Tải file (vd. logo) về workspace nếu chưa có
-- Chỉ nhận dữ liệu ảnh thật (PNG/JPG), tránh ghi trang lỗi "404: Not Found" thành file ảnh
local function IsImageData(data)
    if type(data) ~= "string" or #data < 8 then
        return false
    end
    return string.sub(data, 1, 8) == "\137PNG\r\n\26\n" or string.sub(data, 1, 3) == "\255\216\255"
end

local function IsImageFile(path)
    local ok, data = pcall(readfile, path)
    return ok and IsImageData(data)
end

local function EnsureFile(path, url)
    if not url or typeof(writefile) ~= "function" or typeof(isfile) ~= "function" then
        return
    end
    local ok, exists = pcall(isfile, path)
    if ok and exists and IsImageFile(path) then
        return
    end
    local dir = string.match(path, "^(.*)/")
    if dir then
        EnsureFolder(dir)
    end
    local okGet, data = pcall(function()
        return game:HttpGet(url)
    end)
    if okGet and IsImageData(data) then
        pcall(writefile, path, data)
    end
end

-- Ảnh: rbxassetid, tên icon Lucide, hoặc file trong workspace (qua getcustomasset)
local function ResolveImage(src)
    if src == nil or src == "" then
        return nil
    end
    if type(src) == "number" then
        return "rbxassetid://" .. src
    end
    src = tostring(src)
    if string.find(src, "rbxasset", 1, true) then
        return src
    end
    if string.find(src, "[/%.]") then
        if typeof(getcustomasset) == "function" and typeof(isfile) == "function" then
            local ok, exists = pcall(isfile, src)
            if ok and exists and IsImageFile(src) then
                local ok2, asset = pcall(getcustomasset, src)
                if ok2 and asset then
                    return asset
                end
            end
        end
        return nil
    end
    return GetIcon(src)
end

local function MakeLogo(image, props)
    props.BackgroundTransparency = 1
    if image then
        props.Image = image
        props.ScaleType = Enum.ScaleType.Fit
        return New("ImageLabel", props)
    end
    props.Text = "S"
    props.TextColor3 = props.TextColor3 or WHITE
    props.FontFace = F(W_BOLD)
    props.TextScaled = true
    props.TextXAlignment = Enum.TextXAlignment.Center
    return New("TextLabel", props)
end

local function IconLabel(name, props)
    props.BackgroundTransparency = 1
    props.Image = GetIcon(name) or ""
    props.ScaleType = Enum.ScaleType.Fit
    return New("ImageLabel", props)
end

local function Trim(s)
    s = tostring(s or "")
    s = (string.gsub(s, "^%s+", ""))
    s = (string.gsub(s, "%s+$", ""))
    return s
end

-- Viền kính tĩnh (không theo theme), dùng cho Key System và splash
local function StaticEdge(parent, T, thickness)
    local s = Stroke(T.Edge, 0, thickness or 1)
    local mid = math.min(1, math.max(T.EdgeA, T.EdgeB) + 0.2)
    New("UIGradient", {
        Rotation = 75,
        Transparency = NumberSequence.new({ NSK(0, T.EdgeA), NSK(0.5, mid), NSK(1, T.EdgeB) }),
        Parent = s,
    })
    s.Parent = parent
    return s
end

-- Đối tượng rỗng: trả về khi người dùng đóng Key System, tránh lỗi ở các lệnh tiếp theo
local Null
Null = setmetatable({}, {
    __index = function()
        return function()
            return Null
        end
    end,
})

