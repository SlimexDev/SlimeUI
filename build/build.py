#!/usr/bin/env python3
"""
Build SlimeUI

Joins the files in src/ (in the order listed in src/order.txt) into a single
file, dist/SlimeUI.lua, that users can load with loadstring.

    python build/build.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
DIST = ROOT / "dist"


def main() -> int:
    order = [
        line.strip()
        for line in (SRC / "order.txt").read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]
    core = (SRC / "Core.lua").read_text(encoding="utf-8")
    version = re.search(r'Version = "([^"]+)"', core).group(1)
    repository = re.search(r'Repository = "([^"]+)"', core).group(1)

    header = (ROOT / "build" / "header.lua").read_text(encoding="utf-8")
    header = header.replace("{{VERSION}}", version).replace("{{REPOSITORY}}", repository)

    parts = [header.rstrip() + "\n"]
    for name in order:
        path = SRC / name
        if not path.exists():
            print(f"[x] Missing src/{name}")
            return 1
        parts.append(f"-- >>> src/{name}\n" + path.read_text(encoding="utf-8").rstrip() + "\n")

    output = "\n".join(parts)
    DIST.mkdir(exist_ok=True)
    with open(DIST / "SlimeUI.lua", "w", encoding="utf-8", newline="\n") as f:
        f.write(output)

    size_kb = len(output.encode("utf-8")) / 1024
    print(f"[ok] dist/SlimeUI.lua  v{version}  {size_kb:.1f} KB  {output.count(chr(10))} lines  ({len(order)} modules)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
