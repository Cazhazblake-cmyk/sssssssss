-- =====================================================
-- Otter Hub Loader (Key + Script)
-- Upload this WHOLE file to GitHub
-- =====================================================

local CORRECT_KEY = "Otter_key_PaidScript" -- CHANGE THIS

local function askKey()
	local player = game:GetService("Players").LocalPlayer
	local pg = player:WaitForChild("PlayerGui")

	local old = pg:FindFirstChild("OtterKey")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "OtterKey"
	gui.ResetOnSpawn = false
	gui.Parent = pg

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(320, 140)
	frame.Position = UDim2.new(0.5, -160, 0.5, -70)
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Text = "Otter Hub — Enter Key"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = frame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -20, 0, 32)
	box.Position = UDim2.fromOffset(10, 50)
	box.BackgroundColor3 = Color3.fromRGB(35, 38, 52)
	box.PlaceholderText = "Key..."
	box.Text = ""
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Font = Enum.Font.Code
	box.TextSize = 14
	box.ClearTextOnFocus = false
	box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -20, 0, 18)
	status.Position = UDim2.fromOffset(10, 115)
	status.BackgroundTransparency = 1
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(255, 100, 100)
	status.Font = Enum.Font.Gotham
	status.TextSize = 12
	status.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.Position = UDim2.fromOffset(10, 88)
	btn.BackgroundColor3 = Color3.fromRGB(130, 80, 255)
	btn.Text = "Unlock"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local done = false
	local ok = false

	local function try()
		if box.Text == CORRECT_KEY then
			ok = true
			done = true
			gui:Destroy()
		else
			status.Text = "Wrong key"
		end
	end

	btn.MouseButton1Click:Connect(try)
	box.FocusLost:Connect(function(enter)
		if enter then try() end
	end)

	while not done do
		task.wait(0.1)
	end
	return ok
end

-- Stop here if key is wrong
if not askKey() then
	return
end

-- =====================================================
-- PASTE YOUR FULL OTTER HUB SCRIPT BELOW THIS LINE
-- (everything from "-- Otter Hub V1" to the last print)
-- =====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local events = ReplicatedStorage:WaitForChild("Events")
local swing = events:WaitForChild("SwingSaber")
local uiAction = events:WaitForChild("UIAction")
local sellStrength = events:FindFirstChild("SellStrength")
local collectRemote = events:WaitForChild("CollectCurrencyPickup")

for _, name in ipairs({
	"SaberHubV5", "DungeonAuraTP", "OtterHubV1",
	"OtterLollipopCollect", "OtterCollectAll", "OtterCollectCandy",
}) do
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
end

local Theme = {
	Bg = Color3.fromRGB(12, 14, 22),
	Panel = Color3.fromRGB(20, 23, 34),
	Card = Color3.fromRGB(28, 32, 48),
	Accent = Color3.fromRGB(145, 95, 255),
	Accent2 = Color3.fromRGB(80, 200, 255),
	AccentSoft = Color3.fromRGB(90, 60, 160),
	Text = Color3.fromRGB(245, 247, 255),
	Muted = Color3.fromRGB(150, 158, 185),
	Green = Color3.fromRGB(70, 230, 150),
	Red = Color3.fromRGB(255, 90, 110),
}

local State = {
	Visible = true,
	Paused = false,
	Toggles = {},
	SavedToggles = {},
	Callbacks = {},
}

local Dungeon = {
	Enabled = false,
	TPAbove = true,
	Orbit = false,
	Height = 8,
	OrbitRadius = 6,
	Delay = 0.06,
	MaxTargets = 15,
	HitsPerBot = 4,
	ExtraFires = 2,
	Range = 2000,
	CacheEvery = 0.35,
}

local Boss = { Enabled = false, Delay = 0.08 }
local Auto = {
	SellDelay = 1.2,
	BuyDelay = 2.5,
	SwingDelay = 0.08,
	AntiAFKEvery = 45,
	CollectDelay = 0.3,
	CollectTPHeight = 3,
	CollectWait = 0.07,
	CollectMax = 25,
}

local CONFIG_FILE = "OtterHub_V1_Config.json"
local lastDungeon, lastCache, orbitAngle = 0, 0, 0
local cachedEnemies = {}
local statusCombat = "Idle"
local pulsePhase = 0
local statusLabel

local function make(className, props, parent)
	local o = Instance.new(className)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end

local function corner(o, r)
	make("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o)
end

local function stroke(o, color, thick, trans)
	return make("UIStroke", {
		Color = color or Theme.Accent,
		Thickness = thick or 1.2,
		Transparency = trans or 0.4,
	}, o)
end

local function gradient(o, c1, c2, rot)
	return make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(1, c2),
		}),
		Rotation = rot or 90,
	}, o)
end

-- ========== CONFIG ==========
local function buildConfig()
	local data = {
		Toggles = {},
		Dungeon = {
			Delay = Dungeon.Delay,
			MaxTargets = Dungeon.MaxTargets,
			HitsPerBot = Dungeon.HitsPerBot,
			Height = Dungeon.Height,
			OrbitRadius = Dungeon.OrbitRadius,
			TPAbove = Dungeon.TPAbove,
			Orbit = Dungeon.Orbit,
		},
		Auto = {
			SellDelay = Auto.SellDelay,
			BuyDelay = Auto.BuyDelay,
			SwingDelay = Auto.SwingDelay,
			CollectDelay = Auto.CollectDelay,
			AntiAFKEvery = Auto.AntiAFKEvery,
		},
	}
	for id, v in pairs(State.Toggles) do
		if type(v) == "boolean" and not tostring(id):find("_Render") then
			data.Toggles[id] = v
		end
	end
	return data
end

local function saveConfig()
	local ok, err = pcall(function()
		writefile(CONFIG_FILE, HttpService:JSONEncode(buildConfig()))
	end)
	if ok then
		print("[Otter] Config saved")
		if statusLabel then
			statusLabel.Text = "💾  CONFIG SAVED"
			statusLabel.TextColor3 = Theme.Green
		end
	else
		warn("[Otter] Save failed (executor need writefile):", err)
	end
	return ok
end

local function loadConfig(applyToggles)
	local ok, data = pcall(function()
		if not isfile or not isfile(CONFIG_FILE) then return nil end
		return HttpService:JSONDecode(readfile(CONFIG_FILE))
	end)
	if not ok or not data then
		print("[Otter] No config yet")
		return false
	end
	if data.Dungeon then
		for k, v in pairs(data.Dungeon) do
			if Dungeon[k] ~= nil then Dungeon[k] = v end
		end
	end
	if data.Auto then
		for k, v in pairs(data.Auto) do
			if Auto[k] ~= nil then Auto[k] = v end
		end
	end
	if applyToggles and data.Toggles then
		for id, on in pairs(data.Toggles) do
			if type(on) == "boolean" and State.Toggles[id] ~= nil then
				State.Toggles[id] = on
				local render = State.Toggles[id .. "_Render"]
				if render then render() end
				if on and State.Callbacks[id] then
					task.spawn(function()
						pcall(State.Callbacks[id], true)
					end)
				end
			end
		end
	end
	print("[Otter] Config loaded")
	if statusLabel then
		statusLabel.Text = "📂  CONFIG LOADED"
		statusLabel.TextColor3 = Theme.Green
	end
	return true
end

-- ========== UI ==========
local gui = make("ScreenGui", {
	Name = "OtterHubV1",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local shadow = make("ImageLabel", {
	Name = "Shadow",
	Size = UDim2.fromOffset(760, 560),
	Position = UDim2.new(0.5, -370, 0.5, -268),
	BackgroundTransparency = 1,
	Image = "rbxassetid://5028857084",
	ImageColor3 = Color3.fromRGB(0, 0, 0),
	ImageTransparency = 0.45,
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(24, 24, 276, 276),
}, gui)

local main = make("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(740, 530),
	Position = UDim2.new(0.5, -370, 0.5, -265),
	BackgroundColor3 = Theme.Bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
corner(main, 16)
local mainStroke = stroke(main, Theme.Accent, 1.5, 0.25)

local accentBar = make("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = Theme.Accent,
	BorderSizePixel = 0,
	ZIndex = 5,
}, main)
gradient(accentBar, Theme.Accent, Theme.Accent2, 0)

task.spawn(function()
	while main.Parent do
		pulsePhase += 0.04
		mainStroke.Transparency = 0.2 + (math.sin(pulsePhase) * 0.5 + 0.5) * 0.25
		task.wait(0.03)
	end
end)

local header = make("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 72),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
}, main)
corner(header, 16)
make("Frame", {
	Position = UDim2.new(0, 0, 1, -16),
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
}, header)
gradient(header, Color3.fromRGB(28, 24, 48), Theme.Panel, 0)

make("TextLabel", {
	Position = UDim2.fromOffset(22, 10),
	Size = UDim2.new(1, -120, 0, 28),
	BackgroundTransparency = 1,
	Text = "🦦  OTTER HUB",
	TextColor3 = Theme.Text,
	TextSize = 24,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

make("TextLabel", {
	Position = UDim2.fromOffset(24, 40),
	Size = UDim2.new(1, -130, 0, 18),
	BackgroundTransparency = 1,
	Text = "V1  ·  Made By Otter  ·  Enjoy  ·  Z hide  ·  X dungeon",
	TextColor3 = Theme.Muted,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local chip = make("Frame", {
	Position = UDim2.new(1, -118, 0, 20),
	Size = UDim2.fromOffset(52, 22),
	BackgroundColor3 = Theme.AccentSoft,
	BorderSizePixel = 0,
}, header)
corner(chip, 8)
make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "V1",
	TextColor3 = Theme.Text,
	TextSize = 12,
	Font = Enum.Font.GothamBold,
}, chip)

local closeButton = make("TextButton", {
	Position = UDim2.new(1, -52, 0, 18),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = Theme.Card,
	Text = "×",
	TextSize = 20,
	TextColor3 = Theme.Text,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	AutoButtonColor = false,
}, header)
corner(closeButton, 8)
stroke(closeButton, Theme.Red, 1, 0.5)

local sidebar = make("Frame", {
	Position = UDim2.fromOffset(14, 84),
	Size = UDim2.new(0, 158, 1, -98),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
}, main)
corner(sidebar, 12)
stroke(sidebar, Theme.Accent, 1, 0.7)

make("TextLabel", {
	Position = UDim2.fromOffset(12, 10),
	Size = UDim2.new(1, -20, 0, 18),
	BackgroundTransparency = 1,
	Text = "NAVIGATION",
	TextColor3 = Theme.Muted,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, sidebar)

local tabButtons, pages = {}, {}

local content = make("Frame", {
	Position = UDim2.fromOffset(184, 84),
	Size = UDim2.new(1, -198, 1, -98),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
}, main)
corner(content, 12)
stroke(content, Theme.Accent, 1, 0.75)

local function createPage(name)
	local page = make("ScrollingFrame", {
		Name = name .. "Page",
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.new(1, -24, 1, -24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, content)
	make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)
	pages[name] = page
	return page
end

local function selectTab(name)
	for tabName, page in pairs(pages) do
		page.Visible = (tabName == name)
	end
	for tabName, button in pairs(tabButtons) do
		local selected = tabName == name
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = selected and Theme.Accent or Theme.Card,
		}):Play()
		button.TextColor3 = selected and Color3.new(1, 1, 1) or Theme.Muted
	end
end

local function createTab(name, icon, order)
	local button = make("TextButton", {
		Name = name .. "Tab",
		Position = UDim2.fromOffset(10, 36 + (order - 1) * 48),
		Size = UDim2.new(1, -20, 0, 40),
		BackgroundColor3 = Theme.Card,
		Text = "  " .. icon .. "   " .. name,
		TextColor3 = Theme.Muted,
		TextSize = 13,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, sidebar)
	corner(button, 10)
	button.MouseButton1Click:Connect(function() selectTab(name) end)
	tabButtons[name] = button
	return createPage(name)
end

local combatPage = createTab("Combat", "⚔", 1)
local automationPage = createTab("Auto", "⚡", 2)
local settingsPage = createTab("Settings", "✦", 3)

local function section(parent, text)
	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
	}, parent)
	local bar = make("Frame", {
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.fromOffset(3, 14),
		BackgroundColor3 = Theme.Accent2,
		BorderSizePixel = 0,
	}, frame)
	corner(bar, 2)
	make("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 1, 0),
		BackgroundTransparency = 1,
		Text = text:upper(),
		TextColor3 = Theme.Accent2,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)
	return frame
end

local function createToggle(parent, id, titleText, description)
	State.Toggles[id] = false
	local row = make("Frame", {
		Name = id .. "Row",
		Size = UDim2.new(1, -4, 0, 64),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
	}, parent)
	corner(row, 12)
	local rowStroke = stroke(row, Theme.Accent, 1, 0.85)

	make("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -90, 0, 22),
		BackgroundTransparency = 1,
		Text = titleText,
		TextColor3 = Theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	make("TextLabel", {
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -90, 0, 20),
		BackgroundTransparency = 1,
		Text = description or "",
		TextColor3 = Theme.Muted,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	local switch = make("TextButton", {
		Position = UDim2.new(1, -70, 0.5, -14),
		Size = UDim2.fromOffset(56, 28),
		BackgroundColor3 = Theme.Bg,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, row)
	corner(switch, 14)

	local knob = make("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Theme.Muted,
		BorderSizePixel = 0,
	}, switch)
	corner(knob, 11)

	local function render()
		local on = State.Toggles[id] and not State.Paused
		TweenService:Create(switch, TweenInfo.new(0.18), {
			BackgroundColor3 = on and Theme.Accent or Theme.Bg,
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.18), {
			Position = on and UDim2.new(1, -25, 0, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = on and Color3.new(1, 1, 1) or Theme.Muted,
		}):Play()
		TweenService:Create(rowStroke, TweenInfo.new(0.18), {
			Transparency = on and 0.45 or 0.85,
		}):Play()
	end

	switch.MouseButton1Click:Connect(function()
		if State.Paused then return end
		State.Toggles[id] = not State.Toggles[id]
		render()
		local cb = State.Callbacks[id]
		if cb then pcall(cb, State.Toggles[id]) end
		task.defer(saveConfig)
	end)
	State.Toggles[id .. "_Render"] = render
	return row
end

local function createSlider(parent, title, minV, maxV, default, onChange)
	local row = make("Frame", {
		Size = UDim2.new(1, -4, 0, 56),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
	}, parent)
	corner(row, 12)
	stroke(row, Theme.Accent, 1, 0.88)

	local titleLbl = make("TextLabel", {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 0, 18),
		BackgroundTransparency = 1,
		Text = title .. "  ·  " .. tostring(default),
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local box = make("TextBox", {
		Position = UDim2.fromOffset(14, 28),
		Size = UDim2.new(1, -28, 0, 20),
		BackgroundColor3 = Theme.Bg,
		Text = tostring(default),
		TextColor3 = Theme.Accent2,
		Font = Enum.Font.Code,
		TextSize = 13,
		ClearTextOnFocus = false,
		BorderSizePixel = 0,
	}, row)
	corner(box, 6)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			n = math.clamp(n, minV, maxV)
			box.Text = tostring(n)
			titleLbl.Text = title .. "  ·  " .. tostring(n)
			onChange(n)
			task.defer(saveConfig)
		else
			box.Text = tostring(default)
		end
	end)
	return row
end

section(combatPage, "Combat")
createToggle(combatPage, "AutoSwing", "Auto Swing", "Empty SwingSaber")
createToggle(combatPage, "AuraMode", "Boss Aura", "World boss")
createToggle(combatPage, "DungeonAura", "Dungeon Aura", "Multi-hit bots & bosses")
createToggle(combatPage, "DungeonTP", "TP Above", "Teleport above closest")
createToggle(combatPage, "DungeonOrbit", "Orbit", "Circle around target")
createToggle(combatPage, "NoclipTP", "Noclip TP", "No wall stuck")

section(combatPage, "Tuning")
createSlider(combatPage, "Aura Delay", 0.03, 0.5, Dungeon.Delay, function(n) Dungeon.Delay = n end)
createSlider(combatPage, "Max Targets", 1, 30, Dungeon.MaxTargets, function(n) Dungeon.MaxTargets = math.floor(n) end)
createSlider(combatPage, "Hits Per Bot", 1, 10, Dungeon.HitsPerBot, function(n) Dungeon.HitsPerBot = math.floor(n) end)
createSlider(combatPage, "TP Height", 2, 30, Dungeon.Height, function(n) Dungeon.Height = n end)
createSlider(combatPage, "Orbit Radius", 2, 20, Dungeon.OrbitRadius, function(n) Dungeon.OrbitRadius = n end)

section(automationPage, "Automation")
createToggle(automationPage, "AutoSell", "Auto Sell", "SellStrength")
createToggle(automationPage, "AutoBuy", "Auto Buy", "BuyAll DNA + Weapons")
createToggle(automationPage, "AntiAFK", "Anti AFK", "Idle protection")

section(automationPage, "Collect")
createToggle(automationPage, "CollectLollipop", "Collect Lollipops", "Halloween CurrencyHolder")
createToggle(automationPage, "CollectCrown", "Collect Crowns", "Main CurrencyHolder")

section(automationPage, "Delays")
createSlider(automationPage, "Sell Delay (sec)", 0.3, 5, Auto.SellDelay, function(n) Auto.SellDelay = n end)
createSlider(automationPage, "Buy Delay (sec)", 0.5, 8, Auto.BuyDelay, function(n) Auto.BuyDelay = n end)
createSlider(automationPage, "Swing Delay (sec)", 0.03, 0.5, Auto.SwingDelay, function(n) Auto.SwingDelay = n end)
createSlider(automationPage, "Collect Delay (sec)", 0.15, 2, Auto.CollectDelay, function(n) Auto.CollectDelay = n end)

section(settingsPage, "Session")
statusLabel = make("TextLabel", {
	Size = UDim2.new(1, -4, 0, 56),
	BackgroundColor3 = Theme.Card,
	Text = "✦  STATUS: READY\nOtter Hub V1 · Config auto-saves",
	TextColor3 = Theme.Green,
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	TextWrapped = true,
}, settingsPage)
corner(statusLabel, 12)
stroke(statusLabel, Theme.Green, 1, 0.6)

local liveLabel = make("TextLabel", {
	Size = UDim2.new(1, -4, 0, 44),
	BackgroundColor3 = Theme.Card,
	Text = "  Combat: Idle",
	TextColor3 = Theme.Muted,
	TextSize = 12,
	Font = Enum.Font.Code,
	BorderSizePixel = 0,
	TextXAlignment = Enum.TextXAlignment.Left,
}, settingsPage)
corner(liveLabel, 12)

local function makeActionButton(parent, text, color, callback)
	local button = make("TextButton", {
		Size = UDim2.new(1, -4, 0, 40),
		BackgroundColor3 = color,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, parent)
	corner(button, 10)
	button.MouseButton1Click:Connect(callback)
	return button
end

local function refreshToggles()
	for id, value in pairs(State.Toggles) do
		if type(value) == "boolean" then
			local render = State.Toggles[id .. "_Render"]
			if render then render() end
		end
	end
end

local function pauseAndSave()
	if State.Paused then return end
	State.SavedToggles = {}
	for id, value in pairs(State.Toggles) do
		if type(value) == "boolean" and not string.find(id, "_Render") then
			State.SavedToggles[id] = value
			if value and State.Callbacks[id] then pcall(State.Callbacks[id], false) end
			State.Toggles[id] = false
		end
	end
	State.Paused = true
	statusLabel.Text = "⏸  STATUS: PAUSED"
	statusLabel.TextColor3 = Theme.Red
	refreshToggles()
	saveConfig()
end

local function restoreSaved()
	if not State.Paused then return end
	State.Paused = false
	for id, value in pairs(State.SavedToggles) do
		State.Toggles[id] = value
		if value and State.Callbacks[id] then pcall(State.Callbacks[id], true) end
	end
	statusLabel.Text = "▶  STATUS: RESTORED"
	statusLabel.TextColor3 = Theme.Green
	refreshToggles()
	saveConfig()
end

makeActionButton(settingsPage, "💾  Save Config", Theme.Accent, saveConfig)
makeActionButton(settingsPage, "📂  Load Config", Theme.Card, function()
	loadConfig(true)
end)
makeActionButton(settingsPage, "Ⅱ   Pause & Save", Theme.Card, pauseAndSave)
makeActionButton(settingsPage, "▶   Restore", Theme.AccentSoft, restoreSaved)
makeActionButton(settingsPage, "↻   Reset All", Color3.fromRGB(120, 45, 60), function()
	for id, value in pairs(State.Toggles) do
		if type(value) == "boolean" and not string.find(id, "_Render") then
			if value and State.Callbacks[id] then pcall(State.Callbacks[id], false) end
			State.Toggles[id] = false
		end
	end
	State.Paused = false
	State.SavedToggles = {}
	statusLabel.Text = "↻  STATUS: RESET"
	statusLabel.TextColor3 = Theme.Muted
	refreshToggles()
	saveConfig()
end)

make("TextLabel", {
	Size = UDim2.new(1, -4, 0, 40),
	BackgroundTransparency = 1,
	Text = "Auto-saves every 20s + on toggle.\nFile: OtterHub_V1_Config.json",
	TextWrapped = true,
	TextColor3 = Theme.Muted,
	TextSize = 11,
	Font = Enum.Font.Gotham,
}, settingsPage)

-- Drag
local dragging, dragInput, dragStart, startPosition
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		local pos = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
		)
		main.Position = pos
		shadow.Position = UDim2.new(pos.X.Scale, pos.X.Offset - 10, pos.Y.Scale, pos.Y.Offset - 8)
	end
end)

local function setVisible(v)
	State.Visible = v
	main.Visible = v
	shadow.Visible = v
end
closeButton.MouseButton1Click:Connect(function() setVisible(false) end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Z then
		setVisible(not State.Visible)
	elseif input.KeyCode == Enum.KeyCode.X then
		local on = not Dungeon.Enabled
		State.Toggles.DungeonAura = on
		if State.Callbacks.DungeonAura then State.Callbacks.DungeonAura(on) end
		local r = State.Toggles["DungeonAura_Render"]
		if r then r() end
		task.defer(saveConfig)
	end
end)

-- ========== LOGIC ==========
local function getRoot()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPart(model)
	if not model then return nil end
	if model:IsA("BasePart") then return model end
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
	for _, n in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso", "Head" }) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") then return p end
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function isEnemy(model)
	if not model:IsA("Model") then return false end
	local n = model.Name:lower()
	return n:find("bot") ~= nil or n:find("boss") ~= nil
end

local function isBossName(model)
	return model.Name:lower():find("boss") ~= nil
end

local function scanEnemies()
	local list = {}
	local storage = Workspace:FindFirstChild("DungeonStorage")
	if not storage then return list end
	local root = getRoot()
	local origin = root and root.Position
	for _, room in ipairs(storage:GetChildren()) do
		local important = room:FindFirstChild("Important")
		if important then
			for _, obj in ipairs(important:GetDescendants()) do
				if isEnemy(obj) then
					local hum = obj:FindFirstChildOfClass("Humanoid")
					if not hum or hum.Health > 0 then
						local part = getPart(obj)
						if part then
							local d = origin and (part.Position - origin).Magnitude or 0
							if d <= Dungeon.Range then
								table.insert(list, {
									Model = obj, Part = part, Dist = d, IsBoss = isBossName(obj),
								})
							end
						end
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		if a.IsBoss ~= b.IsBoss then return a.IsBoss end
		return a.Dist < b.Dist
	end)
	return list
end

local function getEnemiesCached()
	if tick() - lastCache >= Dungeon.CacheEvery then
		lastCache = tick()
		cachedEnemies = scanEnemies()
	end
	return cachedEnemies
end

local noclipConn = nil
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	if not on then return end
	noclipConn = RunService.Stepped:Connect(function()
		local c = player.Character
		if not c then return end
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
end

local function tpNear(part)
	local root = getRoot()
	if not root or not part then return end
	local cf
	if Dungeon.Orbit then
		orbitAngle += 0.35
		local off = Vector3.new(
			math.cos(orbitAngle) * Dungeon.OrbitRadius,
			Dungeon.Height,
			math.sin(orbitAngle) * Dungeon.OrbitRadius
		)
		cf = CFrame.new(part.Position + off, part.Position)
	else
		cf = CFrame.new(part.Position + Vector3.new(0, Dungeon.Height, 0), part.Position)
	end
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = cf
	end)
end

local function multiHit(enemies)
	if #enemies == 0 then return end
	local pack = {}
	local n = math.min(Dungeon.MaxTargets, #enemies)
	for i = 1, n do
		local m = enemies[i].Model
		for _ = 1, Dungeon.HitsPerBot do table.insert(pack, m) end
	end
	while #pack > 40 do table.remove(pack) end
	for _ = 1, Dungeon.ExtraFires do
		pcall(function() swing:FireServer(pack) end)
	end
end

local function getWorldBoss()
	local gp = Workspace:FindFirstChild("Gameplay")
	local bossFolder = gp and gp:FindFirstChild("Boss")
	local holder = bossFolder and bossFolder:FindFirstChild("BossHolder")
	local boss = holder and holder:FindFirstChild("Boss")
	if boss and boss:IsA("Model") then
		local hum = boss:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health <= 0 then return nil end
		return boss
	end
	return nil
end

local function getHalloweenHolder()
	local gp = Workspace:FindFirstChild("Gameplay")
	local regions = gp and gp:FindFirstChild("RegionsLoaded")
	local event = regions and regions:FindFirstChild("HalloweenEvent")
	local cp = event and event:FindFirstChild("CurrencyPickup")
	return cp and cp:FindFirstChild("CurrencyHolder")
end

local function getMainHolder()
	local gp = Workspace:FindFirstChild("Gameplay")
	local cp = gp and gp:FindFirstChild("CurrencyPickup")
	return cp and cp:FindFirstChild("CurrencyHolder")
end

local function collectFrom(holder, nameFilter, root)
	if not holder or not root then return 0 end
	local n = 0
	for _, obj in ipairs(holder:GetChildren()) do
		if n >= Auto.CollectMax then break end
		if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
			if not nameFilter or obj.Name:lower():find(nameFilter) then
				local part = getPart(obj)
				if part then
					pcall(function()
						root.AssemblyLinearVelocity = Vector3.zero
						root.CFrame = part.CFrame + Vector3.new(0, Auto.CollectTPHeight, 0)
					end)
					task.wait(Auto.CollectWait)
					pcall(function()
						collectRemote:FireServer({ obj })
					end)
					n += 1
				end
			end
		end
	end
	return n
end

RunService.Heartbeat:Connect(function()
	if not Dungeon.Enabled or State.Paused then return end
	if tick() - lastDungeon < Dungeon.Delay then return end
	lastDungeon = tick()
	local enemies = getEnemiesCached()
	if #enemies == 0 then
		statusCombat = "No enemies"
		return
	end
	local closest = enemies[1]
	statusCombat = string.format("%d near · %s (%.0f)", #enemies, closest.Model.Name, closest.Dist)
	if Dungeon.TPAbove or Dungeon.Orbit then tpNear(closest.Part) end
	multiHit(enemies)
end)

task.spawn(function()
	while liveLabel.Parent do
		liveLabel.Text = "  Combat: " .. statusCombat
		task.wait(0.25)
	end
end)

State.Callbacks.DungeonAura = function(on)
	Dungeon.Enabled = on
	if not on then statusCombat = "Idle" end
end
State.Callbacks.DungeonTP = function(on) Dungeon.TPAbove = on end
State.Callbacks.DungeonOrbit = function(on)
	Dungeon.Orbit = on
	if on then Dungeon.TPAbove = true end
end
State.Callbacks.NoclipTP = function() end

task.spawn(function()
	while true do
		local want = State.Toggles.NoclipTP and (Dungeon.Enabled or Boss.Enabled) and not State.Paused
		setNoclip(want)
		task.wait(0.5)
	end
end)

local lolliOn, lolliId = false, 0
State.Callbacks.CollectLollipop = function(enabled)
	lolliOn = enabled
	lolliId += 1
	local id = lolliId
	if not enabled then return end
	pcall(function() uiAction:FireServer("SetRegionLoaded", "HalloweenEvent") end)
	task.spawn(function()
		while lolliOn and lolliId == id and not State.Paused do
			collectFrom(getHalloweenHolder(), nil, getRoot())
			task.wait(Auto.CollectDelay)
		end
	end)
end

local crownOn, crownId = false, 0
State.Callbacks.CollectCrown = function(enabled)
	crownOn = enabled
	crownId += 1
	local id = crownId
	if not enabled then return end
	task.spawn(function()
		while crownOn and crownId == id and not State.Paused do
			collectFrom(getMainHolder(), "crown", getRoot())
			task.wait(Auto.CollectDelay)
		end
	end)
end

local sellOn, sellId = false, 0
State.Callbacks.AutoSell = function(enabled)
	sellOn = enabled
	sellId += 1
	local id = sellId
	if not enabled or not sellStrength then return end
	task.spawn(function()
		while sellOn and sellId == id and not State.Paused do
			pcall(function() sellStrength:FireServer() end)
			task.wait(Auto.SellDelay)
		end
	end)
end

local buyOn, buyId = false, 0
State.Callbacks.AutoBuy = function(enabled)
	buyOn = enabled
	buyId += 1
	local id = buyId
	if not enabled then return end
	task.spawn(function()
		while buyOn and buyId == id and not State.Paused do
			pcall(function() uiAction:FireServer("BuyAllDNAs") end)
			task.wait(0.35)
			if not (buyOn and buyId == id) then break end
			pcall(function() uiAction:FireServer("BuyAllWeapons") end)
			task.wait(Auto.BuyDelay)
		end
	end)
end

local swingOn, swingId = false, 0
State.Callbacks.AutoSwing = function(enabled)
	swingOn = enabled
	swingId += 1
	local id = swingId
	if not enabled then return end
	task.spawn(function()
		while swingOn and swingId == id and not State.Paused do
			pcall(function() swing:FireServer({}) end)
			task.wait(Auto.SwingDelay)
		end
	end)
end

local bossOn, bossId = false, 0
State.Callbacks.AuraMode = function(enabled)
	bossOn = enabled
	Boss.Enabled = enabled
	bossId += 1
	local id = bossId
	if not enabled then return end
	task.spawn(function()
		while bossOn and bossId == id and not State.Paused do
			local boss = getWorldBoss()
			if boss then pcall(function() swing:FireServer({ boss }) end) end
			task.wait(Boss.Delay)
		end
	end)
end

local afkOn, afkId = false, 0
State.Callbacks.AntiAFK = function(enabled)
	afkOn = enabled
	afkId += 1
	local id = afkId
	if not enabled then return end
	task.spawn(function()
		while afkOn and afkId == id do
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
			local root = getRoot()
			if root then
				pcall(function()
					root.CFrame = root.CFrame * CFrame.new(0, 0, 0.05)
					task.wait(0.05)
					root.CFrame = root.CFrame * CFrame.new(0, 0, -0.05)
				end)
			end
			task.wait(Auto.AntiAFKEvery)
		end
	end)
end

player.CharacterAdded:Connect(function()
	orbitAngle = 0
	lastCache = 0
	cachedEnemies = {}
end)

-- auto-save loop + load on start
task.spawn(function()
	while true do
		task.wait(20)
		if not State.Paused then saveConfig() end
	end
end)

selectTab("Combat")
task.defer(function()
	task.wait(0.6)
	loadConfig(true)
end)

print("✅ Otter Hub V1 | Made By Otter | Enjoy")
print("Config: OtterHub_V1_Config.json | auto-save 20s + on toggle")

local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function toBase64(data)
	return ((data:gsub(".", function(x)
		local r, byte = "", x:byte()
		for i = 8, 1, -1 do
			r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and "1" or "0")
		end
		return r
	end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
		if #x < 6 then return "" end
		local c = 0
		for i = 1, 6 do
			c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
		end
		return b:sub(c + 1, c + 1)
	end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

local encoded = toBase64(src)
print("===== COPY EVERYTHING BELOW =====")
print(encoded)
print("===== END =====")
writefile("OtterHub_B64.txt", encoded) -- optional save
print("Also saved to OtterHub_B64.txt if writefile works")