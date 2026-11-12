---------------------------------------------------------------------
-- Themes: each theme is a color table. Add your own with SlimeUI:AddTheme
---------------------------------------------------------------------

-- Builds a tinted glass theme from a few base colors
local function TintedGlass(o)
    local tint = o.Tint
    return {
        Window = o.Window, WindowT = o.WindowT or 0.45,
        Sidebar = tint, SidebarT = 0.9,
        Card = tint, CardT = 0.92,
        Hover = tint, HoverT = 0.88,
        Line = tint, LineT = 0.82,
        Edge = o.Edge or tint, EdgeA = 0.05, EdgeB = 0.45,
        Sheen = 0.86, Band = 0.9, Rim = 0.3,
        Text = o.Text,
        SubText = o.SubText,
        Control = tint, ControlT = 0.78,
        Field = tint, FieldT = 0.88,
        Select = o.Select or tint, SelectT = 0.8,
        SegPill = tint, SegPillT = 0.65,
        Menu = o.Menu, MenuT = 0.08,
        Knob = Color3.fromRGB(255, 255, 255),
        Accent = o.Accent,
        Accent2 = o.Accent2,
        Effect = o.Effect,
    }
end

local Themes = {
    -- Clear liquid glass (default)
    Glass = {
        Window = Color3.fromRGB(14, 16, 24), WindowT = 0.6,
        Sidebar = Color3.fromRGB(255, 255, 255), SidebarT = 0.93,
        Card = Color3.fromRGB(255, 255, 255), CardT = 0.94,
        Hover = Color3.fromRGB(255, 255, 255), HoverT = 0.9,
        Line = Color3.fromRGB(255, 255, 255), LineT = 0.84,
        Edge = Color3.fromRGB(255, 255, 255), EdgeA = 0.02, EdgeB = 0.4,
        Sheen = 0.88, Band = 0.92, Rim = 0.25,
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(206, 210, 222),
        Control = Color3.fromRGB(255, 255, 255), ControlT = 0.78,
        Field = Color3.fromRGB(255, 255, 255), FieldT = 0.88,
        Select = Color3.fromRGB(255, 255, 255), SelectT = 0.82,
        SegPill = Color3.fromRGB(255, 255, 255), SegPillT = 0.68,
        Menu = Color3.fromRGB(28, 30, 40), MenuT = 0.1,
        Knob = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(10, 132, 255),
    },

    -- Slime: green to cyan glass like the logo, a slime coat on the top edge,
    -- dripping slime, rising bubbles and a jelly bounce
    Slime = TintedGlass({
        Window = Color3.fromRGB(4, 24, 22), WindowT = 0.34,
        Tint = Color3.fromRGB(150, 255, 205),
        Edge = Color3.fromRGB(200, 255, 230),
        Select = Color3.fromRGB(110, 255, 185),
        Text = Color3.fromRGB(242, 255, 249),
        SubText = Color3.fromRGB(158, 230, 205),
        Menu = Color3.fromRGB(6, 34, 32),
        Accent = Color3.fromRGB(64, 222, 120),
        Accent2 = Color3.fromRGB(0, 194, 232),
        Effect = "Slime",
    }),

    Dark = {
        Window = Color3.fromRGB(28, 28, 32), WindowT = 0.05,
        Sidebar = Color3.fromRGB(62, 62, 68), SidebarT = 0.5,
        Card = Color3.fromRGB(255, 255, 255), CardT = 0.95,
        Hover = Color3.fromRGB(255, 255, 255), HoverT = 0.95,
        Line = Color3.fromRGB(255, 255, 255), LineT = 0.91,
        Edge = Color3.fromRGB(255, 255, 255), EdgeA = 0.45, EdgeB = 0.85,
        Sheen = 0.94, Band = 1, Rim = 0.8,
        Text = Color3.fromRGB(245, 245, 247),
        SubText = Color3.fromRGB(152, 152, 159),
        Control = Color3.fromRGB(84, 84, 90), ControlT = 0,
        Field = Color3.fromRGB(255, 255, 255), FieldT = 0.9,
        Select = Color3.fromRGB(255, 255, 255), SelectT = 0.87,
        SegPill = Color3.fromRGB(120, 120, 128), SegPillT = 0.25,
        Menu = Color3.fromRGB(40, 40, 46), MenuT = 0.03,
        Knob = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(10, 132, 255),
    },

    Light = {
        Window = Color3.fromRGB(242, 242, 246), WindowT = 0.05,
        Sidebar = Color3.fromRGB(255, 255, 255), SidebarT = 0.3,
        Card = Color3.fromRGB(255, 255, 255), CardT = 0.15,
        Hover = Color3.fromRGB(0, 0, 0), HoverT = 0.95,
        Line = Color3.fromRGB(0, 0, 0), LineT = 0.9,
        Edge = Color3.fromRGB(0, 0, 0), EdgeA = 0.86, EdgeB = 0.9,
        Sheen = 1, Band = 1, Rim = 1,
        Text = Color3.fromRGB(29, 29, 31),
        SubText = Color3.fromRGB(110, 110, 115),
        Control = Color3.fromRGB(214, 214, 219), ControlT = 0,
        Field = Color3.fromRGB(0, 0, 0), FieldT = 0.94,
        Select = Color3.fromRGB(0, 0, 0), SelectT = 0.91,
        SegPill = Color3.fromRGB(255, 255, 255), SegPillT = 0,
        Menu = Color3.fromRGB(250, 250, 252), MenuT = 0.02,
        Knob = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 122, 255),
    },

    -- Pure black for OLED screens
    Midnight = {
        Window = Color3.fromRGB(0, 0, 0), WindowT = 0.08,
        Sidebar = Color3.fromRGB(255, 255, 255), SidebarT = 0.95,
        Card = Color3.fromRGB(255, 255, 255), CardT = 0.96,
        Hover = Color3.fromRGB(255, 255, 255), HoverT = 0.94,
        Line = Color3.fromRGB(255, 255, 255), LineT = 0.92,
        Edge = Color3.fromRGB(255, 255, 255), EdgeA = 0.6, EdgeB = 0.9,
        Sheen = 1, Band = 1, Rim = 0.9,
        Text = Color3.fromRGB(235, 235, 240),
        SubText = Color3.fromRGB(130, 130, 140),
        Control = Color3.fromRGB(60, 60, 66), ControlT = 0,
        Field = Color3.fromRGB(255, 255, 255), FieldT = 0.93,
        Select = Color3.fromRGB(255, 255, 255), SelectT = 0.9,
        SegPill = Color3.fromRGB(90, 90, 96), SegPillT = 0.3,
        Menu = Color3.fromRGB(14, 14, 16), MenuT = 0.02,
        Knob = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(100, 210, 255),
    },

    Ocean = TintedGlass({
        Window = Color3.fromRGB(6, 22, 40),
        Tint = Color3.fromRGB(165, 215, 255),
        Text = Color3.fromRGB(240, 248, 255),
        SubText = Color3.fromRGB(165, 200, 232),
        Menu = Color3.fromRGB(8, 28, 50),
        Accent = Color3.fromRGB(56, 189, 248),
    }),

    Sakura = TintedGlass({
        Window = Color3.fromRGB(40, 14, 28),
        Tint = Color3.fromRGB(255, 195, 220),
        Text = Color3.fromRGB(255, 244, 248),
        SubText = Color3.fromRGB(240, 185, 208),
        Menu = Color3.fromRGB(46, 18, 32),
        Accent = Color3.fromRGB(255, 105, 160),
    }),

    Amethyst = TintedGlass({
        Window = Color3.fromRGB(22, 14, 42),
        Tint = Color3.fromRGB(212, 192, 255),
        Text = Color3.fromRGB(248, 244, 255),
        SubText = Color3.fromRGB(196, 182, 236),
        Menu = Color3.fromRGB(28, 18, 50),
        Accent = Color3.fromRGB(167, 120, 255),
    }),

    Sunset = TintedGlass({
        Window = Color3.fromRGB(40, 20, 10),
        Tint = Color3.fromRGB(255, 212, 172),
        Text = Color3.fromRGB(255, 248, 240),
        SubText = Color3.fromRGB(240, 202, 166),
        Menu = Color3.fromRGB(48, 24, 12),
        Accent = Color3.fromRGB(255, 140, 50),
    }),
}
local ThemeNames = { "Glass", "Slime", "Dark", "Light", "Midnight", "Ocean", "Sakura", "Amethyst", "Sunset" }
-- Used when CreateWindow / KeySystem get no Theme: black and solid
local DefaultTheme = "Midnight"
SlimeUI.DefaultTheme = DefaultTheme
SlimeUI.Themes = Themes
SlimeUI.ThemeNames = ThemeNames

local Accents = {
    Blue = Color3.fromRGB(10, 132, 255),
    Slime = Color3.fromRGB(88, 220, 72),
    Purple = Color3.fromRGB(191, 90, 242),
    Pink = Color3.fromRGB(255, 55, 95),
    Orange = Color3.fromRGB(255, 159, 10),
    Green = Color3.fromRGB(48, 209, 88),
    Teal = Color3.fromRGB(64, 200, 224),
    Red = Color3.fromRGB(255, 69, 58),
    Graphite = Color3.fromRGB(142, 142, 147),
}
SlimeUI.Accents = Accents
local AccentNames = { "Blue", "Slime", "Purple", "Pink", "Orange", "Green", "Teal", "Red", "Graphite" }

local TabPalette = {
    Color3.fromRGB(10, 132, 255), Color3.fromRGB(191, 90, 242), Color3.fromRGB(255, 55, 95),
    Color3.fromRGB(255, 159, 10), Color3.fromRGB(48, 209, 88), Color3.fromRGB(64, 200, 224),
    Color3.fromRGB(94, 92, 230), Color3.fromRGB(142, 142, 147),
}

