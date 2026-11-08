-- Run SlimeUI straight from src/ without building (for development).
--
-- Copy the repo folder into your executor's workspace/SlimeUI, then run:
--     local SlimeUI = loadstring(readfile("SlimeUI/dev.lua"))("SlimeUI")
local root = ... or "SlimeUI"
local chunks = {}
for name in string.gmatch(readfile(root .. "/src/order.txt"), "[^\r\n]+") do
    if name:sub(1, 1) ~= "#" then
        table.insert(chunks, readfile(root .. "/src/" .. name))
    end
end
local fn, err = loadstring(table.concat(chunks, "\n"), "=SlimeUI")
assert(fn, err)
return fn()
