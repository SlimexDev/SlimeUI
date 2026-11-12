---------------------------------------------------------------------
-- Core: library table, Roblox services, shared constants
---------------------------------------------------------------------
local SlimeUI = {
    Version = "1.3.0",
    Author = "SlimexDev",
    -- Change the two lines below if your GitHub repository has a different name
    Repository = "https://github.com/SlimexDev/SlimeUI",
    AssetsUrl = "https://raw.githubusercontent.com/SlimexDev/SlimeUI/main/assets/",
    Folder = "SlimeUI",
    Flags = {},
    Options = {},
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (typeof(getgenv) == "function" and getgenv()) or _G
local NSK = NumberSequenceKeypoint.new

local FONT_FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local W_REG, W_MED, W_SEMI, W_BOLD =
    Enum.FontWeight.Regular, Enum.FontWeight.Medium, Enum.FontWeight.SemiBold, Enum.FontWeight.Bold

local function F(weight)
    return Font.new(FONT_FAMILY, weight or W_REG)
end

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUCCESS = Color3.fromRGB(48, 209, 88)
local DANGER = Color3.fromRGB(255, 69, 58)
local WARNING = Color3.fromRGB(255, 159, 10)

