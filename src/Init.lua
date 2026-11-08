---------------------------------------------------------------------
-- Init: hàm tiện ích cấp thư viện
---------------------------------------------------------------------
function SlimeUI:Notify(...)
    local w = env.__SlimeUIWindow
    if w then
        w:Notify(...)
    end
end

-- Thêm theme riêng. Khoá nào thiếu sẽ lấy từ Glass.
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

