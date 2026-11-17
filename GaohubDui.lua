--This is just a UI
local Hub = getgenv().GaoHub
if not Hub then
	return
end

local Config = Hub.Config
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = true
Library.Scheme.AccentColor = Color3.fromRGB(255, 50, 50)
Library.NotifyOnError = false

local Sound = Hub.Sound
local applying = false

local function set(name, value)
	Hub.Set(name, value)
end

local function tset(name)
	return function(v)
		if applying then
			return
		end
		Sound(v)
		Hub.Set(name, v)
	end
end

Hub.Listen(function(name, value)
	local opt = Options[name] or Toggles[name]
	if opt and opt.SetValue then
		applying = true
		pcall(function()
			opt:SetValue(value)
		end)
		applying = false
	end
end)

local BASE_CORNER = UDim.new(1, 0)
local MUSIC_WIDTH, MUSIC_HEIGHT, COVER_SIZE = 240, 57, 36
local ISLAND_CFG = {
	TOP_OFFSET = 6, MIN_WIDTH = 72, MIN_HEIGHT = 26, MAX_WIDTH = 340,
	TEXT_SIZE = 11, TEXT_FONT = Enum.Font.GothamBold, TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	BG_COLOR = Color3.fromRGB(0, 0, 0), BG_TRANSPARENCY = 0.7,
	FADE_TIME = 0.18, POP_TIME = 0.45, SIZE_TIME = 0.35,
}

local function fmtTime(sec)
	sec = math.max(0, math.floor(sec or 0))
	return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local Island = nil

local function newIsland()
	local self = {}
	self.active = true
	self.conns = {}
	self.fps = 0
	self.ping = 0
	self.musicMode = false
	self.musicPlaying = false
	self.dragging = false
	self._totalTime = 0
	self.scale = 1
	self.notificationText = nil
	self.notificationUntil = 0
	self.buttons = {}
	self.strokes = {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "GaoIsland"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	local ok = pcall(function()
		gui.Parent = CoreGui
	end)
	if not ok or not gui.Parent then
		gui.Parent = playerGui
	end
	self.gui = gui

	local island = Instance.new("Frame")
	island.AnchorPoint = Vector2.new(0.5, 0)
	island.Position = UDim2.new(0.5, 0, 0, ISLAND_CFG.TOP_OFFSET)
	island.Size = UDim2.new(0, 30, 0, 6)
	island.BackgroundColor3 = ISLAND_CFG.BG_COLOR
	island.BackgroundTransparency = 1
	island.BorderSizePixel = 0
	island.ZIndex = 2
	island.Parent = gui
	self.island = island

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = island
	self.uiScale = uiScale

	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(1, 10, 1, 10)
	glow.Position = UDim2.new(0, -5, 0, -5)
	glow.BackgroundColor3 = Color3.new(1, 1, 1)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.ZIndex = 1
	glow.Parent = island
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = BASE_CORNER
	glowCorner.Parent = glow
	local glowGrad = Instance.new("UIGradient")
	glowGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	glowGrad.Rotation = 45
	glowGrad.Parent = glow
	self.glowCorner = glowCorner

	local corner = Instance.new("UICorner")
	corner.CornerRadius = BASE_CORNER
	corner.Parent = island
	self.corner = corner

	local text = Instance.new("TextLabel")
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.new(0.5, 0, 0.5, 0)
	text.Size = UDim2.new(1, -20, 1, -6)
	text.BackgroundTransparency = 1
	text.Text = ""
	text.TextColor3 = ISLAND_CFG.TEXT_COLOR
	text.TextSize = ISLAND_CFG.TEXT_SIZE
	text.Font = ISLAND_CFG.TEXT_FONT
	text.TextWrapped = true
	text.TextTransparency = 1
	text.ZIndex = 3
	text.Parent = island
	self.textLabel = text

	local music = Instance.new("Frame")
	music.Size = UDim2.new(1, 0, 1, 0)
	music.BackgroundTransparency = 1
	music.Visible = false
	music.ZIndex = 3
	music.Parent = island
	self.musicFrame = music

	local cover = Instance.new("ImageLabel")
	cover.Position = UDim2.new(0, 8, 0, 6)
	cover.Size = UDim2.new(0, COVER_SIZE, 0, COVER_SIZE)
	cover.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	cover.BackgroundTransparency = 0.2
	cover.BorderSizePixel = 0
	cover.ZIndex = 4
	cover.Parent = music
	local coverCorner = Instance.new("UICorner")
	coverCorner.CornerRadius = UDim.new(0, 6)
	coverCorner.Parent = cover
	self.cover = cover

	local info = Instance.new("Frame")
	info.Position = UDim2.new(0, 52, 0, 6)
	info.Size = UDim2.new(0, 108, 0, 36)
	info.BackgroundTransparency = 1
	info.ZIndex = 4
	info.Parent = music

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 11
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 5
	title.Parent = info
	self.titleLabel = title

	local lyric = Instance.new("TextLabel")
	lyric.Position = UDim2.new(0, 0, 0, 15)
	lyric.Size = UDim2.new(1, 0, 0, 18)
	lyric.BackgroundTransparency = 1
	lyric.TextColor3 = Color3.fromRGB(180, 180, 180)
	lyric.TextSize = 10
	lyric.Font = Enum.Font.Gotham
	lyric.TextXAlignment = Enum.TextXAlignment.Left
	lyric.TextWrapped = true
	lyric.TextYAlignment = Enum.TextYAlignment.Top
	lyric.TextTruncate = Enum.TextTruncate.AtEnd
	lyric.ZIndex = 5
	lyric.Parent = info
	self.lyricLabel = lyric

	local controls = Instance.new("Frame")
	controls.Position = UDim2.new(0, 166, 0, 18)
	controls.Size = UDim2.new(0, 66, 0, 20)
	controls.BackgroundTransparency = 1
	controls.ZIndex = 4
	controls.Parent = music

	local function makeBtn(kind, xOff)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 20, 0, 20)
		btn.Position = UDim2.new(0, xOff, 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(120, 180, 255)
		btn.BackgroundTransparency = 0.55
		btn.Text = ""
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.ZIndex = 5
		btn.Parent = controls

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = btn

		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(120, 180, 255)
		s.Transparency = 0.35
		s.Thickness = 1
		s.Parent = btn

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.fromScale(1, 1)
		icon.BackgroundTransparency = 1
		icon.TextColor3 = Color3.new(1, 1, 1)
		icon.Font = Enum.Font.GothamBold
		icon.ZIndex = 6
		icon.Parent = btn

		local function setIcon(k)
			if k == "prev" then
				icon.Text = "◀◀"
				icon.TextSize = 9
			elseif k == "play" then
				icon.Text = "▶"
				icon.TextSize = 13
			elseif k == "pause" then
				icon.Text = "||"
				icon.TextSize = 12
			elseif k == "next" then
				icon.Text = "▶▶"
				icon.TextSize = 9
			end
		end
		setIcon(kind)

		table.insert(self.buttons, btn)
		table.insert(self.strokes, s)

		return btn, setIcon
	end

	local prevBtn = makeBtn("prev", 0)
	local playBtn, setPlayIcon = makeBtn("pause", 23)
	local nextBtn = makeBtn("next", 46)
	self.setPlayIcon = setPlayIcon

	table.insert(self.conns, prevBtn.MouseButton1Click:Connect(function()
		if self.onPrev then
			self.onPrev()
		end
	end))
	table.insert(self.conns, playBtn.MouseButton1Click:Connect(function()
		if self.onPlayPause then
			self.onPlayPause()
		end
	end))
	table.insert(self.conns, nextBtn.MouseButton1Click:Connect(function()
		if self.onNext then
			self.onNext()
		end
	end))

	local area = Instance.new("Frame")
	area.Position = UDim2.new(0, 8, 0, 43)
	area.Size = UDim2.new(1, -16, 0, 11)
	area.BackgroundTransparency = 1
	area.ZIndex = 5
	area.Parent = music

	local curLabel = Instance.new("TextLabel")
	curLabel.Size = UDim2.new(0, 21, 0, 11)
	curLabel.BackgroundTransparency = 1
	curLabel.Text = "0:00"
	curLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	curLabel.TextSize = 9
	curLabel.Font = Enum.Font.Gotham
	curLabel.TextXAlignment = Enum.TextXAlignment.Left
	curLabel.ZIndex = 6
	curLabel.Parent = area
	self.curLabel = curLabel

	local totalLabel = Instance.new("TextLabel")
	totalLabel.Position = UDim2.new(1, -21, 0, 0)
	totalLabel.Size = UDim2.new(0, 21, 0, 11)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "0:00"
	totalLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	totalLabel.TextSize = 9
	totalLabel.Font = Enum.Font.Gotham
	totalLabel.TextXAlignment = Enum.TextXAlignment.Right
	totalLabel.ZIndex = 6
	totalLabel.Parent = area
	self.totalLabel = totalLabel

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 26, 0, 4)
	track.Size = UDim2.new(1, -52, 0, 3)
	track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	track.BorderSizePixel = 0
	track.ZIndex = 6
	track.Parent = area
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Size = UDim2.new(1, 0, 0, 16)
	hit.Position = UDim2.new(0, 0, 0.5, -8)
	hit.ZIndex = 10
	hit.AutoButtonColor = false
	hit.Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 7
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill
	self.fill = fill

	local handle = Instance.new("Frame")
	handle.AnchorPoint = Vector2.new(0.5, 0.5)
	handle.Position = UDim2.new(0, 0, 0.5, 0)
	handle.Size = UDim2.new(0, 8, 0, 8)
	handle.BackgroundColor3 = Color3.new(1, 1, 1)
	handle.BorderSizePixel = 0
	handle.ZIndex = 8
	handle.Parent = track
	local handleCorner = Instance.new("UICorner")
	handleCorner.CornerRadius = UDim.new(1, 0)
	handleCorner.Parent = handle
	self.handle = handle

	local dragProgress = 0
	local function updateFromX(x)
		local absPos = track.AbsolutePosition.X
		local absSize = track.AbsoluteSize.X
		if absSize <= 0 then
			return
		end
		local rel = math.clamp((x - absPos) / absSize, 0, 1)
		dragProgress = rel
		fill.Size = UDim2.new(rel, 0, 1, 0)
		handle.Position = UDim2.new(rel, 0, 0.5, 0)
		if self._totalTime > 0 then
			curLabel.Text = fmtTime(rel * self._totalTime)
		end
	end

	table.insert(self.conns, hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.dragging = true
			updateFromX(input.Position.X)
		end
	end))
	table.insert(self.conns, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.dragging = true
		end
	end))
	table.insert(self.conns, UserInputService.InputChanged:Connect(function(input)
		if not self.dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end))
	table.insert(self.conns, UserInputService.InputEnded:Connect(function(input)
		if not self.dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.dragging = false
			if self.onSeek then
				pcall(self.onSeek, dragProgress)
			end
		end
	end))

	TweenService:Create(island, TweenInfo.new(ISLAND_CFG.POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 150, 0, ISLAND_CFG.MIN_HEIGHT),
		BackgroundTransparency = ISLAND_CFG.BG_TRANSPARENCY,
	}):Play()
	TweenService:Create(glow, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()

	task.spawn(function()
		local hue = 0.6
		while self.active and glow.Parent do
			hue = (hue + 0.005) % 1
			local cA = Color3.fromHSV(hue, 0.8, 1)
			local cB = Color3.fromHSV((hue + 0.3) % 1, 0.8, 1)
			glowGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, cA), ColorSequenceKeypoint.new(1, cB) })
			for _, b in ipairs(self.buttons) do
				if b.Parent then
					b.BackgroundColor3 = cA
				end
			end
			for _, s in ipairs(self.strokes) do
				if s.Parent then
					s.Color = cA
				end
			end
			task.wait(0.05)
		end
	end)

	local fpsCount, fpsTimer = 0, 0
	table.insert(self.conns, RunService.RenderStepped:Connect(function(dt)
		fpsCount = fpsCount + 1
		fpsTimer = fpsTimer + dt
		if fpsTimer >= 1 then
			self.fps = fpsCount
			fpsCount = 0
			fpsTimer = 0
		end
	end))

	task.spawn(function()
		while self.active do
			local ok2, ping = pcall(function()
				return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			if ok2 and ping then
				self.ping = math.floor(ping)
			end
			task.wait(2)
		end
	end)

	task.spawn(function()
		while self.active do
			task.wait(0.5)
			if not self.musicMode and not self.notificationText then
				self:RefreshBase()
			end
		end
	end)

	task.wait(0.4)
	self:RefreshBase()

	function self:DisplayText(text)
		if not self.active then
			return
		end
		self.textLabel.Text = text
		local ts = TextService:GetTextSize(text, ISLAND_CFG.TEXT_SIZE, ISLAND_CFG.TEXT_FONT, Vector2.new(2000, 100))
		local w = math.clamp(ts.X + 44, ISLAND_CFG.MIN_WIDTH, ISLAND_CFG.MAX_WIDTH)
		TweenService:Create(self.island, TweenInfo.new(ISLAND_CFG.SIZE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, w, 0, ISLAND_CFG.MIN_HEIGHT),
		}):Play()
		TweenService:Create(self.textLabel, TweenInfo.new(ISLAND_CFG.FADE_TIME), { TextTransparency = 0 }):Play()
	end

	function self:RefreshBase()
		if not self.active or self.musicMode then
			return
		end
		self:DisplayText(string.format("FPS %d  |  ping %d ms", self.fps, self.ping))
	end

	function self:ShowNotification(text, duration)
		if not self.active then
			return
		end
		duration = duration or 3
		self.notificationText = text
		self.notificationUntil = tick() + duration
		if self.musicMode then
			self.lyricLabel.Text = text
			self.lyricLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
		else
			self:DisplayText(text)
			task.delay(duration, function()
				if not self.active then
					return
				end
				if tick() >= self.notificationUntil and self.notificationText == text then
					self.notificationText = nil
					self:RefreshBase()
				end
			end)
		end
	end

	function self:ApplyShape(radius)
		self.corner.CornerRadius = radius
		self.glowCorner.CornerRadius = radius
	end

	function self:SetScale(s)
		s = math.clamp(tonumber(s) or 1, 0.5, 2)
		self.scale = s
		self.uiScale.Scale = s
		self.island.Position = UDim2.new(0.5, 0, 0, ISLAND_CFG.TOP_OFFSET / s)
	end

	function self:SetMusic(title)
		if not self.active then
			return
		end
		local was = self.musicMode
		self.musicMode = true
		self.musicPlaying = true
		self.notificationText = nil
		self.textLabel.Visible = false
		self.textLabel.TextTransparency = 1
		self.musicFrame.Visible = true
		self.titleLabel.Text = title or "未知歌曲"
		self.lyricLabel.Text = ""
		self.lyricLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		self.curLabel.Text = "0:00"
		self.totalLabel.Text = "0:00"
		self.fill.Size = UDim2.new(0, 0, 1, 0)
		self.handle.Position = UDim2.new(0, 0, 0.5, 0)
		self:ApplyShape(UDim.new(0, 10))
		if not was then
			TweenService:Create(self.island, TweenInfo.new(ISLAND_CFG.SIZE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, MUSIC_WIDTH, 0, MUSIC_HEIGHT),
			}):Play()
		end
	end

	function self:StopMusic()
		if not self.active then
			return
		end
		self.musicMode = false
		self.musicPlaying = false
		self.musicFrame.Visible = false
		self.textLabel.Visible = true
		self.textLabel.TextTransparency = 1
		self:ApplyShape(BASE_CORNER)
		self:RefreshBase()
	end

	function self:SetCover(assetId)
		if assetId and assetId ~= "" then
			self.cover.Image = assetId
			self.cover.BackgroundTransparency = 1
		else
			self.cover.Image = ""
			self.cover.BackgroundTransparency = 0.2
		end
	end

	function self:SetLyric(text)
		if not self.active or not self.musicMode then
			return
		end
		if self.notificationText and tick() < self.notificationUntil then
			return
		end
		self.notificationText = nil
		self.lyricLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		if self.lyricLabel.Text ~= text then
			self.lyricLabel.Text = text or ""
		end
	end

	function self:SetProgress(progress, cur, total)
		if not self.active or not self.musicMode then
			return
		end
		if total then
			self._totalTime = total
		end
		if self.dragging then
			return
		end
		progress = math.clamp(progress or 0, 0, 1)
		self.fill.Size = UDim2.new(progress, 0, 1, 0)
		self.handle.Position = UDim2.new(progress, 0, 0.5, 0)
		if cur then
			self.curLabel.Text = fmtTime(cur)
		end
		if total then
			self.totalLabel.Text = fmtTime(total)
		end
	end

	function self:SetPlayState(playing)
		if not self.active or not self.musicMode then
			return
		end
		self.setPlayIcon(playing and "pause" or "play")
	end

	function self:Destroy()
		if not self.active then
			return
		end
		self.active = false
		for _, c in ipairs(self.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		self.conns = {}
		pcall(function()
			self.gui:Destroy()
		end)
	end

	return self
end

local function setIslandEnabled(enabled)
	if enabled then
		if not Island then
			Island = newIsland()
			Island:SetScale(Config.IslandScale or 1)
			Island.onPrev = function()
				if Hub.Music then
					Hub.Music.Prev()
				end
			end
			Island.onPlayPause = function()
				if Hub.Music then
					Hub.Music.Toggle()
				end
			end
			Island.onNext = function()
				if Hub.Music then
					Hub.Music.Next()
				end
			end
			Island.onSeek = function(p)
				if Hub.Music then
					Hub.Music.Seek(p)
				end
			end
		end
	else
		if Island then
			local old = Island
			Island = nil
			pcall(function()
				old:Destroy()
			end)
		end
	end
end

Hub.NotifyHook = function(title, desc, duration)
	local text = title or ""
	if desc and desc ~= "" then
		text = text .. " · " .. desc
	end
	if Island then
		Island:ShowNotification(text, duration)
	end
end

local Music = { playing = false, sound = nil, song = nil, list = {}, index = 1, mode = "listLoop", file = nil, coverFile = nil, lyrics = {}, listName = nil }
Hub.Music = Music

local function urlEncode(str)
	if not str then
		return ""
	end
	return (string.gsub(str, "([^a-zA-Z0-9_.~-])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function apiGet(url)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({ Url = url, Method = "GET", Headers = { ["User-Agent"] = "Mozilla/5.0" } })
	end)
	if not ok or not res or not res.Success then
		return nil
	end
	local dok, data = pcall(function()
		return HttpService:JSONDecode(res.Body)
	end)
	if not dok or not data or data.code ~= 0 or not data.data then
		return nil
	end
	return data.data
end

local function searchSongs(keyword)
	local list = {}
	if not keyword or keyword == "" then
		return list
	end
	local data = apiGet("https://oiapi.net/api/Music_163?name=" .. urlEncode(keyword) .. "&limit=100")
	if not data then
		return list
	end
	local seen = {}
	for _, s in ipairs(data) do
		local singer = ""
		if s.singers and #s.singers > 0 then
			singer = s.singers[1].name or ""
		end
		local key = (s.name or "") .. "|" .. singer
		if not seen[key] then
			seen[key] = true
			table.insert(list, { name = s.name or "未知", singer = singer, cover = s.picurl or "", id = s.id })
		end
	end
	return list
end

local function songUrl(song)
	local data
	if song.id then
		data = apiGet("https://oiapi.net/api/Music_163?id=" .. tostring(song.id))
	else
		data = apiGet("https://oiapi.net/api/Music_163?name=" .. urlEncode(song.name) .. "&n=1")
	end
	if not data then
		return nil
	end
	if #data > 0 and data[1].url then
		return data[1].url
	end
	return data.url
end

local function songLyrics(song)
	local url
	if song.id then
		url = "https://api.paugram.com/netease/?id=" .. tostring(song.id)
	else
		url = "https://api.paugram.com/netease/?title=" .. urlEncode(song.name)
	end
	local ok, res = pcall(function()
		return HttpService:RequestAsync({ Url = url, Method = "GET", Headers = { ["User-Agent"] = "Mozilla/5.0" } })
	end)
	if not ok or not res or not res.Success then
		return nil
	end
	local dok, data = pcall(function()
		return HttpService:JSONDecode(res.Body)
	end)
	if not dok or not data or not data.lyric then
		return nil
	end
	return data.lyric
end

local function parseLRC(text)
	local out = {}
	for line in text:gmatch("[^\r\n]+") do
		local times = {}
		for ts in line:gmatch("%[([%d:%.]+)%]") do
			local m, s, ms = ts:match("(%d+):(%d+):?(%d*)")
			m, s = tonumber(m) or 0, tonumber(s) or 0
			local msNum = 0
			if ms and ms ~= "" then
				msNum = (#ms == 2) and tonumber(ms) / 100 or tonumber(ms:sub(1, 3)) / 1000
			end
			table.insert(times, m * 60 + s + msNum)
		end
		local content = line:gsub("%[%d+:%d+%.?%d*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
		if content ~= "" then
			for _, t in ipairs(times) do
				table.insert(out, { time = t, text = content })
			end
		end
	end
	table.sort(out, function(a, b)
		return a.time < b.time
	end)
	return out
end

local function stopMusic()
	if Music.sound then
		pcall(function()
			Music.sound:Stop()
			Music.sound:Destroy()
		end)
		Music.sound = nil
	end
	Music.playing = false
	Music.song = nil
	Music.lyrics = {}
	if Island then
		Island:StopMusic()
	end
end

local function playSong(song, list, index, listName)
	if not song then
		return
	end
	stopMusic()
	Music.song = song
	Music.list = list or {}
	Music.index = index or 1
	Music.listName = listName
	if Island then
		Island:SetMusic(song.name)
		Island:SetCover(nil)
		Island:SetPlayState(true)
	end

	task.spawn(function()
		if song.cover and song.cover ~= "" then
			local ok, raw = pcall(function()
				return game:HttpGet(song.cover)
			end)
			if ok and raw then
				local fn = "GaoHub-Cover_" .. tostring(tick()) .. ".jpg"
				local wok = pcall(writefile, fn, raw)
				if wok then
					local aok, asset = pcall(getcustomasset, fn)
					if aok and asset then
						if Music.coverFile and Music.coverFile ~= fn then
							pcall(delfile, Music.coverFile)
						end
						Music.coverFile = fn
						if Island and Music.song == song then
							Island:SetCover(asset)
						end
					else
						pcall(delfile, fn)
					end
				end
			end
		end

		local raw = songLyrics(song)
		if Music.song == song then
			Music.lyrics = raw and parseLRC(raw) or {}
		end
	end)

	local url = songUrl(song)
	if not url then
		Hub.Notify("音乐", "无法获取播放地址", 3)
		return
	end

	local ok, data = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or not data then
		Hub.Notify("音乐", "下载失败", 3)
		return
	end

	local path = "GaoHub-Music_" .. tostring(tick()) .. ".mp3"
	if not pcall(writefile, path, data) then
		Hub.Notify("音乐", "写入失败", 3)
		return
	end
	local aok, asset = pcall(getcustomasset, path)
	if not aok or not asset then
		pcall(delfile, path)
		Hub.Notify("音乐", "资源加载失败", 3)
		return
	end
	if Music.file and Music.file ~= path then
		pcall(delfile, Music.file)
	end
	Music.file = path

	local snd = Instance.new("Sound")
	snd.SoundId = asset
	snd.Volume = 0.79
	snd.Parent = Workspace
	snd:Play()
	Music.sound = snd
	Music.playing = true

	snd.Ended:Connect(function()
		if Music.sound == snd then
			Music.Next()
		end
	end)
end

function Music.Play(song, list, index, listName)
	playSong(song, list, index, listName)
end

function Music.Toggle()
	if not Music.sound or not Music.sound.Parent then
		return
	end
	if Music.playing then
		Music.sound:Pause()
		Music.playing = false
		if Island then
			Island:SetPlayState(false)
		end
	else
		Music.sound:Resume()
		Music.playing = true
		if Island then
			Island:SetPlayState(true)
		end
	end
end

local function nextIndex(idx, total, forward)
	if total == 0 then
		return nil
	end
	if Music.mode == "singleLoop" then
		return idx
	end
	if Music.mode == "shuffle" then
		if total == 1 then
			return 1
		end
		local n
		repeat
			n = math.random(1, total)
		until n ~= idx
		return n
	end
	if Music.mode == "sequence" then
		if forward then
			return idx < total and idx + 1 or nil
		end
		return idx > 1 and idx - 1 or nil
	end
	if forward then
		return idx < total and idx + 1 or 1
	end
	return idx > 1 and idx - 1 or total
end

function Music.Next()
	if #Music.list == 0 then
		return
	end
	local n = nextIndex(Music.index, #Music.list, true)
	if n then
		playSong(Music.list[n], Music.list, n, Music.listName)
	end
end

function Music.Prev()
	if #Music.list == 0 then
		return
	end
	local n = nextIndex(Music.index, #Music.list, false)
	if n then
		playSong(Music.list[n], Music.list, n, Music.listName)
	end
end

function Music.Seek(progress)
	if Music.sound and Music.sound.Parent and Music.sound.TimeLength > 0 then
		pcall(function()
			Music.sound.TimePosition = progress * Music.sound.TimeLength
		end)
	end
end

function Music.SetMode(mode)
	Music.mode = mode
end

function Music.Stop()
	stopMusic()
end

RunService.Heartbeat:Connect(function()
	if not Music.sound or not Music.sound.Parent or not Music.playing then
		return
	end
	local total = Music.sound.TimeLength
	if total <= 0 then
		return
	end
	if Island and Island.active and Island.musicMode then
		Island:SetProgress(Music.sound.TimePosition / total, Music.sound.TimePosition, total)
		if #Music.lyrics > 0 and not Island.dragging then
			local idx = 1
			for i = #Music.lyrics, 1, -1 do
				if Music.lyrics[i].time <= Music.sound.TimePosition then
					idx = i
					break
				end
			end
			Island:SetLyric(Music.lyrics[idx].text)
		end
	end
end)

task.spawn(function()
	task.wait(0.2)
	if not Config.DisableIsland then
		setIslandEnabled(true)
	end
end)

local LibraryNotify = Library.Notify
Library.Notify = function(self, cfg)
	if not cfg then
		return
	end
	if Island then
		local text = cfg.Title or ""
		if cfg.Description and cfg.Description ~= "" then
			text = text .. " · " .. cfg.Description
		end
		Island:ShowNotification(text, cfg.Time or 3)
	else
		return LibraryNotify(self, cfg)
	end
end

local Window = Library:CreateWindow({
	Title = "Gao hub",
	Footer = "1.15 用户: " .. LocalPlayer.Name,
	Icon = 137852711514468,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Info = Window:AddTab({ Name = "信息", Description = "更新日志与玩家信息", Icon = "info" }),
	Main = Window:AddTab({ Name = "主要", Description = "主要功能", Icon = "user" }),
	Items = Window:AddTab({ Name = "物品", Description = "带来物品", Icon = "package" }),
	Vehicle = Window:AddTab({ Name = "车辆", Description = "车辆控制", Icon = "truck" }),
	Other = Window:AddTab({ Name = "其他", Description = "杂项功能", Icon = "message-circle-plus" }),
	Visual = Window:AddTab({ Name = "视觉", Description = "视觉与ESP", Icon = "eye" }),
	Gun = Window:AddTab({ Name = "枪械", Description = "枪械修改", Icon = "crosshair" }),
	Settings = Window:AddTab({ Name = "配置", Description = "界面与保存设置", Icon = "settings" }),
}

do
	local InfoTab = Tabs.Info
	InfoTab:UpdateWarningBox({
		Title = "1.15 更新日志：",
		Text = "<font color=\"rgb(73,230,133)\">[+]核心逻辑与UI分离\n[+]传送方法\n[*]瓶盖农场\n[*]灵动岛</font>",
		IsNormal = true,
		Visible = true,
		LockSize = true,
	})

	local InfoLeft = InfoTab:AddLeftGroupbox({ Name = "玩家信息", IconName = "user", Description = "当前用户信息" })
	local avatarUrl = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	InfoLeft:AddImage("PlayerAvatarInfo", { Image = avatarUrl, Height = 200 })
	InfoLeft:AddDivider()
	InfoLeft:AddLabel("[<font color=\"rgb(73,230,133)\">用户名: " .. LocalPlayer.Name .. "</font>]")

	local InfoRight = InfoTab:AddRightTabbox()
	local QQTab = InfoRight:AddTab("QQ群")
	local CTab = InfoRight:AddTab("贡献者")
	QQTab:AddLabel("QQ群号: <font color=\"#FFFF00\">1022556003</font>", true)
	CTab:AddLabel("所有者:[<font color=\"#00FF00\">GaoLaoBa</font>]", true)
end

do
	local G = Tabs.Main:AddLeftGroupbox({ Name = "玩家", IconName = "user", Description = "调整玩家移动速度并锁定" })
	G:AddInput("PlayerSpeedInput", {
		Text = "移动速度", Default = tostring(Config.PlayerSpeed), Placeholder = "输入数字", Numeric = true,
		Callback = function(v)
			set("PlayerSpeed", tonumber(v))
		end,
	})
	local t = G:AddToggle("LockSpeed", { Text = "应用速度", Default = Config.LockSpeed, Callback = tset("LockSpeed") })
	t:AddKeyPicker("LockSpeedKeybind", { Default = "V", SyncToggleState = true, Mode = "Toggle", Text = "应用速度" })

	local M = Tabs.Main:AddLeftGroupbox({ Name = "主要功能", IconName = "pointer", Description = "自动道路、瓶盖、神秘卖家" })
	M:AddToggle("AutoRoad", { Text = "自动道路", Default = Config.AutoRoad, Callback = tset("AutoRoad") })
	local caps = M:AddToggle("Caps", { Text = "自动收集瓶盖", Default = Config.Caps, Callback = tset("Caps") })
	caps:AddKeyPicker("CapsKeybind", { Default = "C", SyncToggleState = true, Mode = "Toggle", Text = "自动收集瓶盖" })

	M:AddDivider()
	M:AddLabel("神秘卖家")
	M:AddToggle("FindRandomShop", { Text = "寻找神秘卖家", Default = Config.FindRandomShop, Callback = tset("FindRandomShop") })
	M:AddSlider("RandomShopDelay", {
		Text = "拉杆延迟", Default = Config.RandomShopDelay, Min = 0.5, Max = 1.5, Rounding = 2,
		Callback = function(v)
			set("RandomShopDelay", v)
		end,
	})
	M:AddToggle("AutoUseRandomShop", { Text = "自动使用神秘卖家", Default = Config.AutoUseRandomShop, Callback = tset("AutoUseRandomShop") })
	M:AddToggle("AutoDeleteUselessItems", { Text = "自动删除无用物品", Default = Config.AutoDeleteUselessItems, Callback = tset("AutoDeleteUselessItems") })
	M:AddSlider("DeleteInterval", {
		Text = "删除检查间隔", Default = Config.DeleteInterval, Min = 0.5, Max = 5, Rounding = 1,
		Callback = function(v)
			set("DeleteInterval", v)
		end,
	})
	M:AddDropdown("ExcludedCategories", {
		Values = { "稀有物品", "武器", "食物", "爆炸物", "近战武器" },
		Default = { "稀有物品" }, Multi = true, Text = "排除物品种类",
		Tooltip = "选中后，这些种类的物品将不会被删除",
		Callback = function(sel)
			local out = {}
			for k, v in pairs(sel) do
				if v then
					table.insert(out, k)
				end
			end
			Config.ExcludedCategories = out
		end,
	})

	M:AddDivider()
	M:AddLabel("道具")
	M:AddButton("获取伤害道具", function()
		Hub.Call("GetDamageTool")
	end)
	M:AddButton("获取删除道具", function()
		Hub.Call("GetDeleteTool")
	end)
	M:AddButton("无限跳跃", function()
		loadstring(game:HttpGet("https://pastefy.app/2ZKdOO9N/raw", true))()
	end)
	M:AddButton("无限体力", function()
		loadstring(game:HttpGet("https://pastefy.app/uqDKxjaZ/raw", true))()
	end)
	M:AddButton("获取所有里程碑徽章", function()
		Hub.Call("Milestones")
	end)
	M:AddButton("吃食物", function()
		Hub.Call("EatFood")
	end)

	local K = Tabs.Main:AddRightGroupbox({ Name = "杀戮光环", IconName = "sword", Description = "杀戮光环" })
	K:AddToggle("KillAura", { Text = "启用杀戮光环", Default = Config.KillAura, Callback = tset("KillAura") })
	K:AddSlider("KillAuraDelay", {
		Text = "攻击间隔", Default = Config.KillAuraDelay, Min = 0.05, Max = 0.5, Rounding = 2,
		Callback = function(v)
			set("KillAuraDelay", v)
		end,
	})
	K:AddInput("KillAuraCount", {
		Text = "单次攻击次数", Default = tostring(Config.KillAuraCount), Numeric = true, Placeholder = "输入数字",
		Callback = function(v)
			local n = tonumber(v)
			if n and n >= 1 then
				Config.KillAuraCount = n
			end
		end,
	})

	local Box = Tabs.Main:AddRightTabbox()
	local FarmTab = Box:AddTab("瓶盖农场")
	local FarmCfg = Box:AddTab("农场配置")

	FarmTab:AddDropdown("CapsFarmMode", {
		Values = { "new", "cap gun" }, Default = Config.CapsFarmMode, Text = "瓶盖农场方法",
		Callback = function(v)
			if type(v) == "table" then
				v = v[1]
			end
			if v ~= "new" and v ~= "cap gun" then
				v = "new"
			end
			Config.CapsFarmMode = v
		end,
	})
	local farm = FarmTab:AddToggle("CapsFarm", { Text = "瓶盖农场", Default = Config.CapsFarm, Callback = tset("CapsFarm") })
	farm:AddKeyPicker("CapsFarmKeybind", { Default = "P", SyncToggleState = true, Mode = "Toggle", Text = "瓶盖农场" })

	local function numInput(key, text)
		FarmCfg:AddInput(key .. "Input", {
			Text = text, Default = tostring(Config[key]), Numeric = true, Placeholder = "输入数字",
			Callback = function(v)
				local n = tonumber(v)
				if n then
					Config[key] = n
				end
			end,
		})
	end
	numInput("CapsFarmFireCount", "购买空投次数")
	numInput("CapsFarmWaitAfterFire", "等待空投生成")
	numInput("CapsFarmIdleTimeout", "开箱空闲超时")
	numInput("CapsFarmOpenInterval", "开箱扫描间隔")
	numInput("CapsFarmSellThreshold", "卖出阈值")
	numInput("CapsFarmSellWait", "低值确认间隔")
	numInput("CapsFarmSellTriggerGap", "卖出触发间隔")
	numInput("CapsFarmRequiredLow", "确认结束所需低值次数")
	numInput("CapsFarmMaxSellTime", "单轮卖出硬超时")
	numInput("CapsFarmLoopWait", "每次间隔")
end

do
	local G = Tabs.Items:AddLeftGroupbox({ Name = "物品", IconName = "package", Description = "选择物品类型后把物品传送到身边" })
	local selected = "稀有物品"
	G:AddDropdown("BringItems", {
		Values = Hub.BringTypes, Default = "稀有物品", Text = "物品",
		Tooltip = "选择带来的物品",
		Callback = function(v)
			selected = v
		end,
	})
	G:AddButton("带来选中物品", function()
		local n = Hub.Call("Bring", selected)
		Hub.Notify("物品", "已带来 " .. tostring(n or 0) .. " 个物品", 3)
	end)
	G:AddDivider()
	G:AddDropdown("TeleportMethodDropdown", {
		Values = { "远程事件", "网格所有权" }, Default = "网格所有权", Text = "传送实现方法",
		Tooltip = "旧版建议使用远程事件",
		Callback = function(v)
			set("TeleportMethod", v == "远程事件" and "remote" or "network")
		end,
	})
	G:AddCheckbox("SequentialTeleport", {
		Text = "逐个传送", Default = Config.SequentialTeleport, Tooltip = "用于防止卡顿",
		Callback = function(v)
			set("SequentialTeleport", v)
		end,
	})
end

do
	local V = Tabs.Vehicle:AddLeftGroupbox({ Name = "车辆", IconName = "truck", Description = "一些车辆属性" })
	local function currentList()
		Hub.Call("RefreshVehicles")
		return Hub.Vehicles.list
	end
	V:AddDropdown("SelectVehicle", {
		Values = currentList(), Default = Hub.Vehicles.list[1] or "无车辆", Text = "选择车辆",
		Callback = function(v)
			Hub.Call("SelectVehicle", v)
		end,
	})
	V:AddButton("刷新车辆", function()
		local dd = Options.SelectVehicle
		if dd then
			dd:SetValues(currentList(), Hub.Vehicles.list[1] or "无车辆")
		end
	end)
	V:AddButton("传送到选中车辆", function()
		Hub.Call("TeleportToVehicle")
	end)
	V:AddButton("带来选中车辆", function()
		Hub.Call("BringVehicle")
	end)
	V:AddToggle("GasFill", { Text = "加汽油", Default = Config.GasFill, Callback = tset("GasFill") })
	V:AddToggle("DieselFill", { Text = "加柴油", Default = Config.DieselFill, Callback = tset("DieselFill") })
	V:AddToggle("OilFill", { Text = "给引擎加机油", Default = Config.OilFill, Callback = tset("OilFill") })
	V:AddToggle("WaterFill", { Text = "给散热器加水", Default = Config.WaterFill, Callback = tset("WaterFill") })
	V:AddToggle("InfFuel", { Text = "无限燃料（先启动车辆）", Default = Config.InfFuel, Callback = tset("InfFuel") })
	V:AddButton("移除速度限制", function()
		Hub.Call("RemoveSpeedLimit")
	end)
	V:AddInput("VehicleSpeed", {
		Text = "设置车辆速度", Default = "", Placeholder = "输入数字", Numeric = true,
		Callback = function(v)
			Hub.Call("SetVehicleSpeed", v)
		end,
	})

	local F = Tabs.Vehicle:AddRightGroupbox({ Name = "飞车", IconName = "plane", Description = "WASD/空格/左Ctrl 控制，Speed 调速度" })
	local fly = F:AddToggle("FlyEnabled", { Text = "启用飞车", Default = Config.FlyEnabled, Callback = tset("FlyEnabled") })
	fly:AddKeyPicker("FlyKeybind", { Default = "F", SyncToggleState = true, Mode = "Toggle", Text = "飞车" })
	F:AddInput("FlySpeedInput", {
		Text = "速度值", Default = tostring(Config.FlySpeed), Placeholder = "输入数字", Numeric = true,
		Callback = function(v)
			set("FlySpeed", tonumber(v))
		end,
	})
	F:AddDivider()
	F:AddLabel("触屏方向键")
	local dirs = {
		{ "前", 0, 1 }, { "后", 0, -1 }, { "左", -1, 0 }, { "右", 1, 0 },
	}
	for _, d in ipairs(dirs) do
		F:AddButton("移动 " .. d[1], function()
			Hub.Call("FlyMove", d[2], d[3])
			task.delay(0.35, function()
				Hub.Call("FlyMove", 0, 0)
			end)
		end)
	end
end

do
	local C = Tabs.Other:AddLeftGroupbox({ Name = "自动开箱", IconName = "package", Description = "自动打开地图上的所有货箱" })
	C:AddToggle("AutoOpenCargo", { Text = "自动开箱", Default = Config.AutoOpenCargo, Callback = tset("AutoOpenCargo") })
	C:AddToggle("AutoOpenCargoSequential", { Text = "逐箱开箱", Default = Config.AutoOpenCargoSequential, Callback = tset("AutoOpenCargoSequential") })

	local M = Tabs.Other:AddLeftGroupbox({ Name = "地图", IconName = "map", Description = "一些视觉" })
	M:AddToggle("NightVision", { Text = "夜视", Default = Config.NightVision, Callback = tset("NightVision") })
	M:AddToggle("SetDay", { Text = "设置为白天", Default = Config.SetDay, Callback = tset("SetDay") })
	M:AddToggle("SetNight", { Text = "设置为夜晚", Default = Config.SetNight, Callback = tset("SetNight") })
	M:AddButton("移除雾", function()
		Hub.Call("RemoveFog")
	end)
	local rare = M:AddToggle("RareItemAlert", { Text = "稀有物品提示", Default = Config.RareItemAlert, Callback = tset("RareItemAlert") })
	rare:AddKeyPicker("RareAlertKeybind", { Default = "R", SyncToggleState = true, Mode = "Toggle", Text = "稀有物品提示" })
	M:AddButton("删除出生点", function()
		Hub.Call("DeleteSpawn")
	end)
	M:AddToggle("SoundSpammer", { Text = "声音轰炸(慎用)", Default = Config.SoundSpammer, Callback = tset("SoundSpammer") })

	local P = Tabs.Other:AddRightGroupbox({ Name = "玩家管理", IconName = "users", Description = "部分功能仅限老版本" })
	local function names()
		local t = {}
		for _, p in ipairs(Players:GetPlayers()) do
			table.insert(t, p.Name)
		end
		return t
	end
	local selectedPlayer = names()[1] or ""
	P:AddDropdown("SelectPlayer", {
		Values = names(), Default = selectedPlayer, Text = "选择玩家",
		Callback = function(v)
			selectedPlayer = v
		end,
	})
	P:AddButton("刷新玩家列表", function()
		local list = names()
		selectedPlayer = list[1] or ""
		if Options.SelectPlayer then
			Options.SelectPlayer:SetValues(list, selectedPlayer)
		end
	end)
	P:AddButton("传送选中玩家到我这里", function()
		Hub.Call("BringPlayer", selectedPlayer)
	end)
	P:AddButton("击杀选中玩家", function()
		Hub.Call("KillPlayer", selectedPlayer)
	end)
	P:AddButton("传送怪物到选中玩家", function()
		Hub.Call("BringMobsToPlayer", selectedPlayer)
	end)
	P:AddButton("击杀所有玩家", function()
		Hub.Call("KillAllPlayers")
	end)
	P:AddButton("传送所有玩家到我这里", function()
		Hub.Call("BringAllPlayers")
	end)
end

do
	local B = Tabs.Other:AddLeftGroupbox({ Name = "背包", IconName = "backpack", Description = "获取背包" })
	local selected = "6x6背包"
	B:AddDropdown("BackpackSelect", {
		Values = { "6x6背包", "8x8背包", "10x10背包" }, Default = selected, Text = "选择背包",
		Callback = function(v)
			selected = v
		end,
	})
	B:AddButton("获取背包", function()
		local size = 6
		if selected == "8x8背包" then
			size = 8
		elseif selected == "10x10背包" then
			size = 10
		end
		Hub.Dialog("警告", "确定此操作?", function()
			Hub.Call("GiveBackpack", size)
		end)
	end)

	local D = Tabs.Other:AddRightGroupbox({ Name = "背包调试", IconName = "package", Description = "用于背包10以上" })
	local selectedItem = nil
	D:AddDropdown("BackpackItemSelect", {
		Values = {}, Default = "", Text = "选择物品",
		Callback = function(v)
			selectedItem = v
		end,
	})
	D:AddButton("刷新物品列表", function()
		local list = Hub.Call("ScanBackpackItems") or {}
		if Options.BackpackItemSelect then
			Options.BackpackItemSelect:SetValues(list, list[1] or "")
		end
		selectedItem = list[1]
		Hub.Notify("背包调试", "共找到 " .. #list .. " 个物品", 3)
	end)
	D:AddDivider()
	D:AddDropdown("BackpackSlot", {
		Values = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12" },
		Default = "1", Text = "选择槽位",
		Callback = function(v)
			Config.BackpackSlot = tonumber(v) or 1
		end,
	})
	D:AddDivider()
	D:AddButton("将对象放入背包", function()
		if not selectedItem then
			return
		end
		Hub.Call("PutInBackpack", selectedItem, Config.BackpackSlot)
	end)
end

do
	local V = Tabs.Visual:AddRightGroupbox({ Name = "视野", IconName = "eye", Description = "调整并锁定视野（FOV）" })
	V:AddSlider("FOVSlider", {
		Text = "视野", Default = Config.FieldOfView, Min = 60, Max = 120, Rounding = 0,
		Callback = function(v)
			set("FieldOfView", v)
		end,
	})
	V:AddToggle("LockFOV", { Text = "锁定视野", Default = Config.LockFOV, Callback = tset("LockFOV") })

	local T = Tabs.Visual:AddRightGroupbox({ Name = "第三人称", IconName = "camera", Description = "启用第三人称视角并调整偏移" })
	local tp = T:AddToggle("ThirdPerson", { Text = "启用第三人称", Default = Config.ThirdPerson, Callback = tset("ThirdPerson") })
	tp:AddKeyPicker("ThirdPersonKeybind", { Default = "T", SyncToggleState = true, Mode = "Toggle", Text = "第三人称" })
	T:AddToggle("ShowModel", { Text = "显示玩家模型", Default = Config.ShowModel, Callback = tset("ShowModel") })
	T:AddDivider()
	T:AddSlider("OffsetX", { Text = "X 偏移", Default = Config.OffsetX, Min = -10, Max = 10, Rounding = 1, Callback = function(v)
		Config.OffsetX = v
	end })
	T:AddSlider("OffsetY", { Text = "Y 偏移", Default = Config.OffsetY, Min = -10, Max = 10, Rounding = 1, Callback = function(v)
		Config.OffsetY = v
	end })
	T:AddSlider("OffsetZ", { Text = "Z 偏移", Default = Config.OffsetZ, Min = -10, Max = 10, Rounding = 1, Callback = function(v)
		Config.OffsetZ = v
	end })

	local Box = Tabs.Visual:AddLeftTabbox()
	local E = Box:AddTab("ESP")
	local C = Box:AddTab("配置")

	local function colorPicker(toggle, key, title)
		toggle:AddColorPicker(key .. "Picker", {
			Default = Config[key], Title = title,
			Callback = function(c)
				Config[key] = c
				Hub.Set(key, c)
			end,
		})
	end

	local p = E:AddToggle("ESPPlayer", { Text = "ESP 玩家", Default = Config.ESPPlayer, Callback = tset("ESPPlayer") })
	colorPicker(p, "ESPPlayerColor", "玩家颜色")
	local n = E:AddToggle("ESPAllNPC", { Text = "ESP NPC", Default = Config.ESPAllNPC, Callback = tset("ESPAllNPC") })
	colorPicker(n, "ESPAllNPCColor", "NPC 颜色")
	local r = E:AddToggle("ESPRare", { Text = "ESP 稀有物品", Default = Config.ESPRare, Callback = tset("ESPRare") })
	colorPicker(r, "ESPRareColor", "稀有物品颜色")
	local g = E:AddToggle("ESPGun", { Text = "ESP 枪械", Default = Config.ESPGun, Callback = tset("ESPGun") })
	colorPicker(g, "ESPGunColor", "枪械颜色")
	local m = E:AddToggle("ESPMelee", { Text = "ESP 近战武器", Default = Config.ESPMelee, Callback = tset("ESPMelee") })
	colorPicker(m, "ESPMeleeColor", "近战颜色")

	C:AddToggle("ESPTracer", { Text = "启用追踪射线", Default = Config.ESPTracer, Callback = tset("ESPTracer") })
	C:AddSlider("ESPTransparency", {
		Text = "填充透明度", Default = Config.ESPTransparency, Min = 0, Max = 1, Rounding = 2,
		Callback = function(v)
			set("ESPTransparency", v)
		end,
	})
	C:AddToggle("ESPBox3D", { Text = "3D 方框", Default = Config.ESPBox3D, Callback = tset("ESPBox3D") })
	C:AddToggle("ESPBox2D", { Text = "2D 方框", Default = Config.ESPBox2D, Callback = tset("ESPBox2D") })
end

do
	local G = Tabs.Gun:AddLeftGroupbox({ Name = "枪械修改", IconName = "crosshair", Description = "一些枪械配置修改" })
	G:AddToggle("InfAmmo", { Text = "无限弹药", Default = Config.InfAmmo, Callback = tset("InfAmmo") })
	G:AddToggle("NoFirerate", { Text = "无射速", Default = Config.NoFirerate, Callback = tset("NoFirerate") })
	G:AddToggle("NoReload", { Text = "无需装弹", Default = Config.NoReload, Callback = tset("NoReload") })
	G:AddToggle("NoRecoil", { Text = "无后坐力", Default = Config.NoRecoil, Callback = tset("NoRecoil") })
end

do
	local Menu = Tabs.Settings:AddLeftGroupbox({ Name = "菜单", IconName = "settings", Description = "UI" })
	local kb = Menu:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "打开按键绑定菜单", Callback = function(v)
		Sound(v)
		Library.KeybindFrame.Visible = v
	end })
	Library.KeybindFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		kb:SetValue(Library.KeybindFrame.Visible)
	end)
	Menu:AddToggle("ShowCustomCursor", { Text = "自定义光标", Default = true, Callback = function(v)
		Sound(v)
		Library.ShowCustomCursor = v
	end })
	Menu:AddDropdown("NotificationSide", {
		Values = { "左侧", "右侧" }, Default = "右侧", Text = "通知位置",
		Callback = function(v)
			Library:SetNotifySide(v)
		end,
	})
	Menu:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
		Default = "100%", Text = "DPI缩放",
		Callback = function(v)
			Library:SetDPIScale(tonumber((v:gsub("%%", ""))))
		end,
	})
	Menu:AddDivider()
	Menu:AddLabel("菜单按键绑定"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "菜单按键绑定" })
	Menu:AddButton("卸载UI", function()
		Library:Unload()
	end)

	local Music2 = Tabs.Settings:AddRightGroupbox({ Name = "灵动岛", IconName = "music", Description = "灵动岛显示与大小" })
	Music2:AddToggle("DisableIsland", {
		Text = "禁用灵动岛", Default = false,
		Tooltip = "启用后通知回落到 UI 自带样式",
		Callback = function(v)
			Sound(v)
			setIslandEnabled(not v)
		end,
	})
	local SCALE = {
		["更小 ×5"] = 0.5, ["更小 ×4"] = 0.6, ["更小 ×3"] = 0.7, ["更小 ×2"] = 0.8, ["更小 ×1"] = 0.9,
		["默认"] = 1.0, ["更大 ×1"] = 1.1, ["更大 ×2"] = 1.2, ["更大 ×3"] = 1.3, ["更大 ×4"] = 1.4, ["更大 ×5"] = 1.5,
	}
	Music2:AddDropdown("IslandSizeDropdown", {
		Values = { "更小 ×5", "更小 ×4", "更小 ×3", "更小 ×2", "更小 ×1", "默认", "更大 ×1", "更大 ×2", "更大 ×3", "更大 ×4", "更大 ×5" },
		Default = "默认", Text = "灵动岛大小",
		Callback = function(v)
			local s = SCALE[v] or 1
			Config.IslandScale = s
			if Island then
				pcall(function()
					Island:SetScale(s)
				end)
			end
		end,
	})
	Music2:AddSlider("UICornerSlider", {
		Text = "圆角半径", Default = 12, Min = 0, Max = 20, Rounding = 0,
		Callback = function(v)
			Window:SetCornerRadius(v)
		end,
	})
	Window:SetCornerRadius(12)

	local Song = Tabs.Settings:AddRightGroupbox({ Name = "音乐", IconName = "music", Description = "搜索并播放网易云音乐" })
	local results = {}
	local current = nil
	local function refreshResults()
		local dd = Options.SongSelect
		if not dd then
			return
		end
		local names = {}
		for _, s in ipairs(results) do
			table.insert(names, s.name .. " - " .. s.singer)
		end
		if #names == 0 then
			names = { "暂无结果" }
		end
		dd:SetValues(names, names[1])
	end
	Song:AddInput("SongKeyword", {
		Text = "关键词", Default = "", Placeholder = "歌名或歌手",
		Callback = function() end,
	})
	Song:AddButton("搜索", function()
		local kw = Options.SongKeyword and Options.SongKeyword:GetValue() or ""
		results = searchSongs(kw)
		current = nil
		refreshResults()
		Hub.Notify("音乐", "找到 " .. #results .. " 首", 3)
	end)
	Song:AddDropdown("SongSelect", {
		Values = { "暂无结果" }, Default = "暂无结果", Text = "选择歌曲",
		Callback = function(v)
			for _, s in ipairs(results) do
				if (s.name .. " - " .. s.singer) == v then
					current = s
					break
				end
			end
		end,
	})
	Song:AddButton("播放", function()
		if not current then
			return
		end
		local idx = 1
		for i, s in ipairs(results) do
			if s == current then
				idx = i
				break
			end
		end
		Music.Play(current, results, idx, "search")
	end)
	Song:AddButton("暂停/继续", function()
		Music.Toggle()
	end)
	Song:AddButton("上一首", function()
		Music.Prev()
	end)
	Song:AddButton("下一首", function()
		Music.Next()
	end)
	Song:AddButton("停止", function()
		Music.Stop()
	end)
	Song:AddDropdown("PlayMode", {
		Values = { "列表循环", "顺序播放", "单曲循环", "随机播放" },
		Default = "列表循环", Text = "播放模式",
		Callback = function(v)
			local map = { ["列表循环"] = "listLoop", ["顺序播放"] = "sequence", ["单曲循环"] = "singleLoop", ["随机播放"] = "shuffle" }
			Music.SetMode(map[v] or "listLoop")
		end,
	})
end

do
	local Menu = Tabs.Settings:AddLeftGroupbox({ Name = "水印", IconName = "image", Description = "底部 FPS 与水印" })
	local label = Library:AddDraggableLabel("FPS: 0 | 延迟: 0ms")
	local frames, last = 0, tick()
	RunService.Heartbeat:Connect(function()
		frames = frames + 1
	end)
	task.spawn(function()
		while true do
			task.wait(1.5)
			local now = tick()
			local fps = frames / (now - last)
			frames = 0
			last = now
			label:SetText(string.format("FPS: %.1f | 延迟: %.0fms", fps, LocalPlayer:GetNetworkPing() * 1000))
		end
	end)
	Menu:AddButton("重置所有功能", function()
		Hub.ResetAll()
	end)
end

do
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "MenuKeybind", "DisableIsland" })
	ThemeManager:SetFolder("GaoHubDesertMoney")
	SaveManager:SetFolder("GaoHubDesertMoney/specific-game")
	SaveManager:SetSubFolder("desert")
	SaveManager:BuildConfigSection(Tabs.Settings)
	ThemeManager:ApplyToTab(Tabs.Settings)
	SaveManager:LoadAutoloadConfig()
end

Library:OnUnload(function()
	Music.Stop()
	if Music.file then
		pcall(delfile, Music.file)
	end
	if Music.coverFile then
		pcall(delfile, Music.coverFile)
	end
	if Island then
		pcall(function()
			Island:Destroy()
		end)
		Island = nil
	end
	if Hub.ClearESP then
		pcall(Hub.ClearESP)
	end
end)

Library.ToggleKeybind = Options.MenuKeybind