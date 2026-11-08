#!/usr/bin/env python3
"""
Xuất ảnh minh hoạ cho docs từ tools/shots/shots.html bằng Google Chrome (headless).
Render the docs illustrations from tools/shots/shots.html with headless Google Chrome.

    python tools/shots/render.py            # tất cả / all shots
    python tools/shots/render.py toggle     # một ảnh / one shot

Ảnh được lưu ở docs/assets/shots/<tên>.webp (cần Pillow để chuyển PNG -> WebP).
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
PAGE = ROOT / "tools" / "shots" / "shots.html"
OUT = ROOT / "docs" / "assets" / "shots"

CHROME_CANDIDATES = [
    os.environ.get("CHROME", ""),
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    shutil.which("google-chrome") or "",
    shutil.which("chromium") or "",
]


def find_chrome() -> str:
    for c in CHROME_CANDIDATES:
        if c and os.path.exists(c):
            return c
    sys.exit("Google Chrome not found. Set the CHROME environment variable.")


def main() -> None:
    chrome = find_chrome()
    shots = re.findall(r'<section class="shot" id="([a-z0-9-]+)"', PAGE.read_text(encoding="utf-8"))
    wanted = sys.argv[1:] or shots
    OUT.mkdir(parents=True, exist_ok=True)
    try:
        from PIL import Image
    except ImportError:
        Image = None

    with tempfile.TemporaryDirectory() as tmp:
        for name in wanted:
            png = pathlib.Path(tmp) / f"{name}.png"
            url = PAGE.as_uri() + f"?shot={name}"
            subprocess.run([
                chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=2", "--window-size=760,420",
                "--virtual-time-budget=5000", f"--screenshot={png}", url,
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if Image:
                target = OUT / f"{name}.webp"
                Image.open(png).convert("RGB").save(target, "WEBP", quality=88, method=6)
            else:
                target = OUT / f"{name}.png"
                shutil.copy(png, target)
            print(f"[ok] {target.relative_to(ROOT)}  {target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
