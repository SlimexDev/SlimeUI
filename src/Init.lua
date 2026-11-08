---------------------------------------------------------------------
-- Init: library-level helpers
---------------------------------------------------------------------
function SlimeUI:Notify(...)
    local w = env.__SlimeUIWindow
    if w then
        w:Notify(...)
    end
end

-- Adds a custom theme. Missing keys are taken from Glass.
function SlimeUI:AddTheme(name, colors)
    local theme = table.clone(Themes.Glass)
    for k, v in pairs(colors or {}) do
        theme[k] = v
    end
    Themes[name] = theme
    if not table.find(ThemeNames, name) then
        table.insert(ThemeNames, name)
    end
    return theme
end

function SlimeUI:GetThemes()
    return table.clone(ThemeNames)
end

return SlimeUI

