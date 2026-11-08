-- SlimeUI example · Ví dụ dùng SlimeUI
local SlimeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SlimexDev/SlimeUI/main/dist/SlimeUI.lua"))()
-- Thử trên máy trước khi push / test locally before pushing:
-- local SlimeUI = loadstring(readfile("SlimeUI/SlimeUI.lua"))()

local Window = SlimeUI:CreateWindow({
    Title = "SlimeUI",
    Subtitle = "by SlimexDev",
    Theme = "Slime",                      -- Glass, Slime, Dark, Light, Midnight, Ocean, Sakura, Amethyst, Sunset
    ToggleKey = Enum.KeyCode.RightShift,
    KeySystem = {
        Key = { "SLIME-DEMO-KEY" },
        Link = "https://example.com/get-key",
        SaveKey = true,
    },
})

---------------------------------------------------------------------
-- Home
---------------------------------------------------------------------
local Home = Window:Tab("Home", "home", "Quick toggles and camera")

Home:Section("Display")
local fpsLabel, fpsConn
Home:Toggle({
    Name = "Show FPS counter",
    Description = "Small pill in the top-left corner",
    Icon = "activity",
    Flag = "ShowFPS",
    Callback = function(on)
        if on then
            fpsLabel = Instance.new("TextLabel")
            fpsLabel.Position = UDim2.fromOffset(16, 64)
            fpsLabel.Size = UDim2.fromOffset(86, 28)
            fpsLabel.BackgroundColor3 = Color3.fromRGB(10, 30, 18)
            fpsLabel.BackgroundTransparency = 0.25
            fpsLabel.TextColor3 = Color3.new(1, 1, 1)
            fpsLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
            fpsLabel.TextSize = 14
            fpsLabel.Text = "-- FPS"
            Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(1, 0)
            fpsLabel.Parent = Window.Gui
            local frames, last = 0, os.clock()
            fpsConn = game:GetService("RunService").RenderStepped:Connect(function()
                frames += 1
                local now = os.clock()
                if now - last >= 0.5 then
                    fpsLabel.Text = math.floor(frames / (now - last) + 0.5) .. " FPS"
                    frames, last = 0, now
                end
            end)
        else
            if fpsConn then fpsConn:Disconnect() fpsConn = nil end
            if fpsLabel then fpsLabel:Destroy() fpsLabel = nil end
        end
    end,
})

Home:Section("Camera")
local fov = Home:Slider({
    Name = "Field of view",
    Icon = "eye",
    Min = 40, Max = 120, Increment = 1,
    Default = math.floor(workspace.CurrentCamera.FieldOfView + 0.5),
    Suffix = "°",
    Flag = "FOV",
    Callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
    end,
})
Home:Button({
    Name = "Reset camera",
    Icon = "rotate-ccw",
    ButtonText = "Reset",
    Callback = function()
        fov:Set(70, false, true)
    end,
})

---------------------------------------------------------------------
-- Components (cách viết ngắn / short syntax)
---------------------------------------------------------------------
local Comp = Window:Tab("Components", "layers", "Every element, short syntax")

Comp:Section("Basics")
Comp:Toggle("Reduce motion", false, function(on)
    Window:Notify("Reduce motion", on and "Enabled" or "Disabled", 2)
end)
Comp:Slider("Volume", 0, 100, 50, function(v) end)
Comp:Button("Say hello", function()
    Window:Notify({ Title = "Hello!", Content = "Button pressed.", Type = "Success" })
end)

Comp:Section("Choices")
Comp:Dropdown("Mode", { "Legit", "Balanced", "Rage" }, "Legit", function(v)
    Window:Notify("Mode", "Selected: " .. tostring(v), 2)
end)
Comp:Dropdown({
    Name = "Widgets",
    Description = "Multi-select dropdown",
    Multi = true,
    Options = { "Clock", "Weather", "Calendar", "Battery" },
    Default = { "Clock", "Weather" },
    Flag = "Widgets",
})
Comp:Segmented("Speed", { "Slow", "Normal", "Fast" }, "Normal", function(v) end)

Comp:Section("Inputs")
Comp:Input("Nickname", "Type and press Enter", function(text, enter)
    if enter and text ~= "" then
        Window:Notify("Nickname saved", text, 3)
    end
end)
Comp:Keybind("Quick action", Enum.KeyCode.F, function()
    Window:Notify("Quick action", "Keybind pressed", 2)
end)
Comp:Button({ Name = "Primary action", ButtonText = "Continue", ButtonIcon = "arrow-right", Style = "Primary", Callback = function() end })

Comp:Section("Text")
Comp:Label("A simple line of text.")
Comp:Paragraph("Paragraph", "Longer text wraps onto several lines inside the card, which is handy for notes and instructions.")

---------------------------------------------------------------------
-- Themes
---------------------------------------------------------------------
local Looks = Window:Tab("Themes", "palette", "Try every built-in theme")
Looks:Section("Built-in themes")
for _, name in ipairs(SlimeUI:GetThemes()) do
    Looks:Button({
        Name = name,
        ButtonText = "Apply",
        Callback = function()
            Window:SetTheme(name)
            Window:Notify("Theme", name, 2)
        end,
    })
end

---------------------------------------------------------------------
-- Notifications
---------------------------------------------------------------------
local Alerts = Window:Tab("Notifications", "bell", "Banners in the top-right corner")
Alerts:Section("Types")
for _, kind in ipairs({ "Info", "Success", "Warning", "Error" }) do
    Alerts:Button({
        Name = kind .. " notification",
        ButtonText = "Send",
        Callback = function()
            Window:Notify({ Title = kind, Content = "This is a " .. string.lower(kind) .. " notification.", Type = kind, Duration = 4 })
        end,
    })
end
