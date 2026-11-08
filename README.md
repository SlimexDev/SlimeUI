<p align="center">
  <img src="assets/slimex.png" width="110" alt="SlimeUI logo">
</p>

<h1 align="center">SlimeUI</h1>

<p align="center">
  Liquid Glass UI library for Roblox, inspired by macOS<br>
  Thư viện UI kính lỏng cho Roblox, lấy cảm hứng từ macOS
</p>

<p align="center">
  <a href="https://slimexdev.github.io/SlimeUI/"><b>Documentation / Tài liệu</b></a> ·
  <a href="examples/Example.lua">Example</a> ·
  <a href="LICENSE">MIT License</a>
</p>

<p align="center">
  <img src="docs/assets/shots/window.webp" width="760" alt="SlimeUI window with the Slime theme">
</p>

<table>
  <tr>
    <td><img src="docs/assets/shots/themes.webp" alt="9 built-in themes"></td>
    <td><img src="docs/assets/shots/keysystem.webp" alt="Key system"></td>
  </tr>
  <tr>
    <td><img src="docs/assets/shots/notifications.webp" alt="Notifications"></td>
    <td><img src="docs/assets/shots/dropdown.webp" alt="Dropdown"></td>
  </tr>
</table>

---

**Language / Ngôn ngữ:** [English](#english) · [Tiếng Việt](#tiếng-việt)

## English

### Features

- Liquid Glass windows: translucent panels, refractive edges that follow the cursor, light sweep on open
- 9 built-in themes: `Glass`, `Slime`, `Dark`, `Light`, `Midnight`, `Ocean`, `Sakura`, `Amethyst`, `Sunset`, plus `SlimeUI:AddTheme` for your own
- The **Slime** theme has rising bubbles, slime drips and jelly-bounce animations
- 818 Lucide icons by name (`"home"`, `"settings"`, `"swords"`...)
- Elements: Toggle, Slider, Button, Dropdown (single and multi), Segmented, Keybind, Input, Label, Paragraph
- Built-in key system, notifications, settings tab, config saving with flags
- Collapses into a glass bar at the top of the screen when hidden; resize from any corner
- Mobile layout and a floating toggle button for touch devices

### Install

```lua
local SlimeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SlimexDev/SlimeUI/main/dist/SlimeUI.lua"))()
```

### Quick start

```lua
local Window = SlimeUI:CreateWindow({
    Title = "My Hub",
    Theme = "Slime",
})

local Main = Window:Tab("Main", "home")
Main:Section("Player")
Main:Toggle("Auto farm", false, function(on) print(on) end)
Main:Slider("Walk speed", 16, 100, 16, function(v) print(v) end)
Main:Button("Say hi", function() Window:Notify("Hi", "Hello from SlimeUI", 3) end)
```

Every option and element is explained in the [documentation](https://slimexdev.github.io/SlimeUI/).

### Project layout

```
src/            source modules (edit these)
  order.txt     build order
dist/           built single file (SlimeUI.lua)
build/          build script
docs/           documentation site (GitHub Pages)
examples/       example scripts
assets/         logos (logo.png is the one loaded in game)
tools/shots/    docs illustrations, render with python tools/shots/render.py
dev.lua         run straight from src/ without building
```

### Building

Requires Python 3.

```bash
python build/build.py
```

This joins the files in `src/` (in the order of `src/order.txt`) into `dist/SlimeUI.lua`. Commit the new `dist/` file after building.

### Publishing the docs

1. Push this repository to GitHub.
2. Open **Settings → Pages**.
3. Under **Build and deployment**, choose **Deploy from a branch**, branch `main`, folder `/docs`, then save.
4. After a minute the docs are live at `https://<your-username>.github.io/SlimeUI/`.

If your GitHub username is not `SlimexDev`, update the links in `src/Core.lua`, `README.md`, `docs/index.html` and `build/header.lua`.

### Releases

Push a tag such as `v1.0.0` and the release workflow attaches `SlimeUI.lua` to a GitHub release. Users can then load the latest release with:

```lua
local SlimeUI = loadstring(game:HttpGet("https://github.com/SlimexDev/SlimeUI/releases/latest/download/SlimeUI.lua"))()
```

## Tiếng Việt

### Tính năng

- Cửa sổ kính lỏng: trong suốt, viền phản quang xoay theo con trỏ, dải sáng quét qua khi mở
- 9 theme có sẵn: `Glass`, `Slime`, `Dark`, `Light`, `Midnight`, `Ocean`, `Sakura`, `Amethyst`, `Sunset`, và tự tạo theme bằng `SlimeUI:AddTheme`
- Theme **Slime** có bong bóng nổi lên, giọt slime nhỏ xuống và hiệu ứng nảy như thạch
- 818 icon Lucide gọi bằng tên (`"home"`, `"settings"`, `"swords"`...)
- Element: Toggle, Slider, Button, Dropdown (chọn một hoặc nhiều), Segmented, Keybind, Input, Label, Paragraph
- Có sẵn Key System, thông báo, tab Settings, lưu config bằng Flag
- Khi ẩn sẽ thu gọn thành thanh kính ở giữa phía trên; kéo 4 góc để đổi kích thước
- Bố cục cho điện thoại và nút nổi bật/tắt cho thiết bị cảm ứng

### Cài đặt

```lua
local SlimeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SlimexDev/SlimeUI/main/dist/SlimeUI.lua"))()
```

### Bắt đầu nhanh

```lua
local Window = SlimeUI:CreateWindow({
    Title = "My Hub",
    Theme = "Slime",
})

local Main = Window:Tab("Main", "home")
Main:Section("Player")
Main:Toggle("Auto farm", false, function(on) print(on) end)
Main:Slider("Walk speed", 16, 100, 16, function(v) print(v) end)
Main:Button("Say hi", function() Window:Notify("Hi", "Hello from SlimeUI", 3) end)
```

Mọi tuỳ chọn và element đều có giải thích trong [tài liệu](https://slimexdev.github.io/SlimeUI/).

### Cấu trúc dự án

```
src/            các module mã nguồn (sửa ở đây)
  order.txt     thứ tự ghép khi build
dist/           file đã build (SlimeUI.lua)
build/          script build
docs/           trang tài liệu (GitHub Pages)
examples/       script ví dụ
assets/         logo (logo.png là file được tải trong game)
tools/shots/    ảnh minh hoạ cho docs, xuất bằng python tools/shots/render.py
dev.lua         chạy thẳng từ src/ không cần build
```

### Build

Cần Python 3.

```bash
python build/build.py
```

Lệnh này ghép các file trong `src/` (theo thứ tự trong `src/order.txt`) thành `dist/SlimeUI.lua`. Nhớ commit file mới trong `dist/` sau khi build.

### Đăng tài liệu lên GitHub Pages

1. Push repo này lên GitHub.
2. Mở **Settings → Pages**.
3. Ở mục **Build and deployment**, chọn **Deploy from a branch**, nhánh `main`, thư mục `/docs`, rồi bấm Save.
4. Khoảng một phút sau, tài liệu có ở `https://<tên-github-của-bạn>.github.io/SlimeUI/`.

Nếu tên GitHub của bạn không phải `SlimexDev`, hãy sửa link trong `src/Core.lua`, `README.md`, `docs/index.html` và `build/header.lua`.

### Phát hành

Push một tag như `v1.0.0`, workflow sẽ đính kèm `SlimeUI.lua` vào GitHub Release. Người dùng có thể tải bản mới nhất bằng:

```lua
local SlimeUI = loadstring(game:HttpGet("https://github.com/SlimexDev/SlimeUI/releases/latest/download/SlimeUI.lua"))()
```

## Credits

- Design and code: **SlimexDev**
- Icons: [Lucide](https://lucide.dev) (ISC License); asset ID table from [Fluent](https://github.com/dawid-scripts/Fluent) (MIT)
- Project layout inspired by [WindUI](https://github.com/Footagesus/WindUI)
