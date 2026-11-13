local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local BACKGROUND_URL = "https://raw.giteeusercontent.com/gaozi729/gaojp/raw/master/Gaohub.png"
local WS_URL = "wss://luau-irc-bridge.onrender.com"
local MyTag = "Gao hub_User"
local NOTICE_URL = "https://raw.giteeusercontent.com/gaozi729/gaojp/raw/master/Gao_Notice-UI-library.lua"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local NoticeLib = nil
task.spawn(function()
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(NOTICE_URL))()
    end)
    if ok and res then NoticeLib = res end
end)

local Patch = (function(InputLibrary)
    local Library = InputLibrary or getgenv().Library
    if not Library then return nil end
    if Library._ObsidianPatchApplied then return getgenv().ObsidianPatch end
    Library._ObsidianPatchApplied = true

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        LocalPlayer = Players.LocalPlayer
    end

    Library.TweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Library.GroupboxTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Library.RotatingChevronTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Library.TabTransitionInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Library.WindowAnimationInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Library.DropdownTransitionInfo = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Library.KeyPickerTransitionInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Library.NotifyTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local MobileButtons = {}
    do
        local originalAddDraggableButton = Library.AddDraggableButton
        function Library:AddDraggableButton(...)
            local args = table.pack(...)
            local textArg = args[1]
            local isToggle, isLock = false, false
            if typeof(textArg) == "string" then
                if textArg == "Toggle" then isToggle = true; args[1] = "切换"
                elseif textArg == "Lock" then isLock = true; args[1] = "锁定" end
            elseif typeof(textArg) == "table" then
                if textArg.Text == "Toggle" then isToggle = true; textArg.Text = "切换"
                elseif textArg.Text == "Lock" then isLock = true; textArg.Text = "锁定" end
            end
            local btn = originalAddDraggableButton(self, table.unpack(args, 1, args.n))
            if btn then
                if isToggle then MobileButtons.Toggle = btn
                elseif isLock then MobileButtons.Lock = btn end
                local originalSetText = btn.SetText
                function btn:SetText(text)
                    if text == "Lock" then text = "锁定"
                    elseif text == "Unlock" then text = "解锁"
                    elseif text == "Toggle" then text = "切换" end
                    originalSetText(self, text)
                end
            end
            return btn
        end
    end

    local function PatchGroupbox(groupbox)
        if not groupbox or groupbox.Destroyed or groupbox._PatchApplied then return groupbox end
        groupbox._PatchApplied = true
        if groupbox.Holder then groupbox.Holder.ClipsDescendants = true end
        local originalSetCollapsed = groupbox.SetCollapsed
        function groupbox:SetCollapsed(collapsed)
            if self.Collapsed == collapsed then return end
            local tweenTime = Library.GroupboxTweenInfo and Library.GroupboxTweenInfo.Time or 0.5
            if not collapsed then
                if self.Container then self.Container.Visible = true end
                task.defer(function()
                    if self.Destroyed then return end
                    originalSetCollapsed(self, collapsed)
                    local startTime = os.clock()
                    task.spawn(function()
                        while os.clock() - startTime < tweenTime + 0.05 do
                            if self.Destroyed then break end
                            if self.RefreshBoxHolderLayout then self:RefreshBoxHolderLayout() end
                            RunService.Heartbeat:Wait()
                        end
                        if self.RefreshBoxHolderLayout then self:RefreshBoxHolderLayout() end
                    end)
                end)
            else
                originalSetCollapsed(self, collapsed)
                if self.Container then self.Container.Visible = true end
                local startTime = os.clock()
                task.spawn(function()
                    while os.clock() - startTime < tweenTime + 0.05 do
                        if self.Destroyed then break end
                        if self.RefreshBoxHolderLayout then self:RefreshBoxHolderLayout() end
                        RunService.Heartbeat:Wait()
                    end
                    if self.Container then self.Container.Visible = false end
                    if self.RefreshBoxHolderLayout then self:RefreshBoxHolderLayout() end
                end)
            end
        end
        return groupbox
    end

    local function PatchTab(tab)
        if not tab or tab._PatchTabApplied then return tab end
        tab._PatchTabApplied = true
        local originalAddGroupbox = tab.AddGroupbox
        if originalAddGroupbox then
            function tab:AddGroupbox(info)
                return PatchGroupbox(originalAddGroupbox(self, info))
            end
        end
        return tab
    end

    local function AttachToWindow(window)
        if not window or window._PatchWindowApplied then return window end
        window._PatchWindowApplied = true
        local originalAddTab = window.AddTab
        if originalAddTab then
            function window:AddTab(...) return PatchTab(originalAddTab(self, ...)) end
        end
        local originalAddKeyTab = window.AddKeyTab
        if originalAddKeyTab then
            function window:AddKeyTab(...) return PatchTab(originalAddKeyTab(self, ...)) end
        end
        return window
    end

    local DEFAULT_ANIMATIONS = { ToggleWindow = true, TabSwitch = true, Groupbox = true, Dropdown = true, KeyPicker = true }

    do
        local originalCreateWindow = Library.CreateWindow
        function Library:CreateWindow(...)
            local args = table.pack(...)
            local info = args[1]
            if typeof(info) == "table" then
                info.Animations = info.Animations or {}
                for k, v in pairs(DEFAULT_ANIMATIONS) do
                    if info.Animations[k] == nil then info.Animations[k] = v end
                end
            end
            local window = originalCreateWindow(self, table.unpack(args, 1, args.n))
            if window then AttachToWindow(window) end
            return window
        end
    end

    local function CreateImage(parent, iconName, props)
        if not parent then return nil end
        props = props or {}
        local parsed = Library:GetCustomIcon(iconName)
        if not parsed then return nil end
        local parentZIndex = parent:IsA("GuiObject") and parent.ZIndex or 1
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Name = props.Name or "CustomImage"
        imageLabel.BackgroundTransparency = props.BackgroundTransparency or 1
        imageLabel.Size = props.Size or UDim2.fromOffset(24, 24)
        imageLabel.Position = props.Position or UDim2.fromOffset(0, 0)
        imageLabel.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
        imageLabel.ImageColor3 = props.ImageColor3 or Color3.new(1, 1, 1)
        imageLabel.ZIndex = props.ZIndex or (parentZIndex + 1)
        imageLabel.ScaleType = props.ScaleType or Enum.ScaleType.Fit
        imageLabel.LayoutOrder = props.LayoutOrder or 0
        imageLabel.Parent = parent
        local isImageAsset = typeof(iconName) == "string" and (
            iconName:match("^https?://") or iconName:match("^rbxassetid://")
            or iconName:match("^rbxasset://") or iconName:match("^rbxthumb://")
            or iconName:match("^content://")
        )
        if isImageAsset then
            imageLabel.Image = parsed.Url or ""
            imageLabel.ImageRectOffset = parsed.ImageRectOffset or Vector2.zero
            imageLabel.ImageRectSize = parsed.ImageRectSize or Vector2.zero
            if props.Round ~= false then
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = imageLabel
            end
        else
            Library:ApplyLucideIcon(imageLabel, parsed)
        end
        return imageLabel
    end

    local function FindFooterLabel(window)
        local mainFrame = window and window.MainFrame
        if not mainFrame then return nil end
        if window._FooterLabel and window._FooterLabel.Parent then return window._FooterLabel end
        local existing = mainFrame:FindFirstChild("FooterContent", true)
        if existing then
            local named = existing:FindFirstChild("FooterLabel_PlayerName")
            if named and named:IsA("TextLabel") then return named end
        end
        for _, child in ipairs(mainFrame:GetChildren()) do
            if child:IsA("Frame") and child.Size == UDim2.new(1, 0, 0, 20)
                and child.AnchorPoint == Vector2.new(0, 1)
                and child.Position == UDim2.fromScale(0, 1)
                and child.BackgroundTransparency == 1
            then
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("TextLabel") and sub.TextSize == 14 then return sub end
                end
            end
        end
        return nil
    end

    local function SetupFooterContainer(window)
        if not window then return nil, nil end
        if window._FooterContent then return window._FooterContent, window._FooterLabel end
        local footerLabel = FindFooterLabel(window)
        if not footerLabel then return nil, nil end
        local bottomBar = footerLabel.Parent
        local container = Instance.new("Frame")
        container.Name = "FooterContent"
        container.BackgroundTransparency = 1
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.fromScale(0.5, 0.5)
        container.Size = UDim2.new(0, 0, 1, 0)
        container.AutomaticSize = Enum.AutomaticSize.X
        container.Parent = bottomBar
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.Parent = container
        footerLabel.Parent = container
        footerLabel.Name = "FooterLabel_PlayerName"
        footerLabel.LayoutOrder = 2
        footerLabel.Size = UDim2.new(0, 0, 1, 0)
        footerLabel.AutomaticSize = Enum.AutomaticSize.X
        footerLabel.TextXAlignment = Enum.TextXAlignment.Left
        footerLabel.BackgroundTransparency = 1
        window._FooterLabel = footerLabel
        window._FooterContent = container
        return container, footerLabel
    end

    local function AddFooterImage(window, iconName, props)
        local container = SetupFooterContainer(window)
        if not container then return nil end
        props = props or {}
        props.Size = props.Size or UDim2.fromOffset(16, 16)
        return CreateImage(container, iconName, props)
    end

    local function AddFooterText(window, text, props)
        local container = SetupFooterContainer(window)
        if not container then return nil end
        props = props or {}
        local label = Instance.new("TextLabel")
        label.Name = props.Name or "FooterText"
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0, 0, 1, 0)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Text = text
        label.TextSize = props.TextSize or 14
        label.TextColor3 = props.TextColor3 or Library.Scheme.FontColor
        label.TextTransparency = props.TextTransparency or 0.5
        label.FontFace = props.FontFace or Library.Scheme.Font
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.LayoutOrder = props.LayoutOrder or 0
        label.Parent = container
        return label
    end

    local function AddFPSText(window, props)
        props = props or { LayoutOrder = 100 }
        local label = AddFooterText(window, "当前FPS: --", props)
        if not label then return nil end
        local frames, elapsed = 0, 0
        local conn = RunService.RenderStepped:Connect(function(dt)
            if not label.Parent then return end
            frames += 1
            elapsed += dt
            if elapsed >= 0.25 then
                local fps = math.floor(frames / elapsed + 0.5)
                label.Text = "当前FPS: " .. tostring(fps)
                frames = 0
                elapsed = 0
            end
        end)
        Library:GiveSignal(conn)
        return label
    end

    local function GetPlayerAvatarUrl(player, size)
        player = player or LocalPlayer
        size = size or 150
        return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d", player.UserId, size, size)
    end

    local Patch = {
        Library = Library, LocalPlayer = LocalPlayer, MobileButtons = MobileButtons,
        PatchGroupbox = PatchGroupbox, AttachToWindow = AttachToWindow, CreateImage = CreateImage,
        FindFooterLabel = FindFooterLabel, SetupFooterContainer = SetupFooterContainer,
        AddFooterImage = AddFooterImage, AddFooterText = AddFooterText, AddFPSText = AddFPSText,
        GetPlayerAvatarUrl = GetPlayerAvatarUrl,
    }
    Library.Patch = Patch
    getgenv().ObsidianPatch = Patch
    return Patch
end)(Library)

local TabUIPatch = (function()
    local TabUIPatch = {}
    local function NewInstance(ClassName, Properties)
        local Inst = Instance.new(ClassName)
        for Key, Value in pairs(Properties) do
            if Key ~= "Parent" then Inst[Key] = Value end
        end
        if Properties.Parent then Inst.Parent = Properties.Parent end
        return Inst
    end

    function TabUIPatch.InjectTab(Tab)
        if not Tab or Tab._TabUIPatchInjected then return end
        Tab._TabUIPatchInjected = true
        function Tab:AddUIPassthrough(Idx, Info)
            local Library = getgenv().Library
            assert(type(Info) == "table", "Info 必须是 table")
            assert(Info.Instance and typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"), "Instance 必须是 GuiBase2d")
            local TabRef = self
            local Fullscreen = Info.Fullscreen == true
            local Height = tonumber(Info.Height) or 24
            if not Fullscreen then assert(Height > 0, "Height 必须大于 0") end
            local Holder
            if Fullscreen then
                Holder = NewInstance("Frame", {
                    Name = "TabUIPassthrough_" .. tostring(Idx), BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0),
                    ZIndex = tonumber(Info.ZIndex) or 100, Active = true, ClipsDescendants = true,
                    Visible = Info.Visible ~= false, Parent = self.Container,
                })
                if self.Sides then
                    for _, Side in ipairs(self.Sides) do Side.Visible = false end
                end
            else
                local Side = Info.Side or 1
                local Container = self.Sides and (self.Sides[Side] or self.Sides[1])
                assert(Container, "当前 Tab 没有可用的侧边容器")
                Holder = NewInstance("Frame", {
                    Name = "TabUIPassthrough_" .. tostring(Idx), BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Height), Visible = Info.Visible ~= false, Parent = Container,
                })
            end
            local UserInstance = Info.Instance
            UserInstance.Parent = Holder
            if Info.AutoFill ~= false then
                UserInstance.Size = UDim2.fromScale(1, 1)
                UserInstance.Position = UDim2.fromScale(0, 0)
            end
            local Pass = { Type = "UIPassthrough", Instance = UserInstance, Height = Height, Visible = Info.Visible ~= false, Holder = Holder, Fullscreen = Fullscreen }
            function Pass:SetHeight(NewHeight)
                if Fullscreen then return end
                NewHeight = tonumber(NewHeight)
                if not NewHeight or NewHeight <= 0 then return end
                Pass.Height = NewHeight
                Holder.Size = UDim2.new(1, 0, 0, NewHeight)
            end
            function Pass:SetInstance(NewInstance_)
                assert(NewInstance_ and NewInstance_:IsA("GuiBase2d"), "Instance 必须是 GuiBase2d")
                if Pass.Instance and Pass.Instance.Parent == Holder then Pass.Instance.Parent = nil end
                Pass.Instance = NewInstance_
                NewInstance_.Parent = Holder
                if Info.AutoFill ~= false then
                    NewInstance_.Size = UDim2.fromScale(1, 1)
                    NewInstance_.Position = UDim2.fromScale(0, 0)
                end
            end
            function Pass:SetVisible(Visible)
                Pass.Visible = Visible == true
                Holder.Visible = Pass.Visible
                if Fullscreen and TabRef.Sides then
                    for _, Side in ipairs(TabRef.Sides) do Side.Visible = not Pass.Visible end
                end
            end
            function Pass:Destroy()
                if Holder then Holder:Destroy(); Holder = nil end
                if Fullscreen and TabRef.Sides then
                    for _, Side in ipairs(TabRef.Sides) do Side.Visible = true end
                end
            end
            if Library and Library.Options then Library.Options[Idx] = Pass end
            return Pass
        end
    end

    function TabUIPatch.InjectExistingTabs()
        local Library = getgenv().Library
        if not Library or not Library.Tabs then return end
        for _, Tab in pairs(Library.Tabs) do
            if Tab and not Tab.IsKeyTab then TabUIPatch.InjectTab(Tab) end
        end
    end

    function TabUIPatch.ApplyToWindow(Window)
        if not Window or Window._TabUIPatchApplied then return Window end
        Window._TabUIPatchApplied = true
        local OldAddTab = Window.AddTab
        if type(OldAddTab) == "function" then
            Window.AddTab = function(self, ...)
                local Tab = OldAddTab(self, ...)
                if Tab and not Tab.IsKeyTab then TabUIPatch.InjectTab(Tab) end
                return Tab
            end
        end
        TabUIPatch.InjectExistingTabs()
        return Window
    end
    return TabUIPatch
end)()

local function ResolveRemoteImage(url)
    if typeof(url) ~= "string" or url == "" then return nil end
    if url:match("^rbxassetid://") or url:match("^rbxasset://") or url:match("^rbxthumb://") or url:match("^content://") then return url end
    if not (url:match("^https?://") and getcustomasset and writefile and isfile) then return nil end
    local filename = url:match("([^/]+)$")
    if not filename then return nil end
    if not filename:match("%.png$") and not filename:match("%.jpg$") and not filename:match("%.jpeg$") and not filename:match("%.webp$") then
        filename = filename .. ".png"
    end
    local dir = "Obsidian/backgrounds/"
    if isfolder and makefolder and not isfolder(dir) then
        makefolder("Obsidian"); makefolder(dir)
    end
    local path = dir .. filename
    if not isfile(path) then
        local ok = pcall(function() writefile(path, game:HttpGet(url)) end)
        if not ok then return nil end
    end
    local ok, asset = pcall(getcustomasset, path)
    if ok and asset then return asset end
    return nil
end

local Window = Library:CreateWindow({
    Title = "Gao irc",
    Footer = "当前玩家: " .. LocalPlayer.Name,
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
    TabTransitionTime = 0.3,
    TabSwipeOffset = 26,
    TabSwipeFrom = "bottom",
})
TabUIPatch.ApplyToWindow(Window)

do
    local mainFrame = Window.MainFrame
    local screenGui = Library.ScreenGui
    if mainFrame and screenGui then
        local resolved = ResolveRemoteImage(BACKGROUND_URL)
        if resolved then
            local bg = Instance.new("ImageLabel")
            bg.Name = "WindowBackgroundImage"
            bg.BackgroundTransparency = 1
            bg.Image = resolved
            bg.ImageTransparency = 0.65
            bg.ScaleType = Enum.ScaleType.Fit
            bg.Size = UDim2.fromOffset(240, 240)
            bg.AnchorPoint = Vector2.new(0.5, 0.5)
            bg.Position = UDim2.fromScale(0.5, 0.5)
            bg.ZIndex = mainFrame.ZIndex
            bg.Parent = mainFrame
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, Library.CornerRadius)
            corner.Parent = bg
            bg.Visible = true
        else
            Window:SetBackgroundImage(BACKGROUND_URL)
        end
    end
end

local avatarUrl = Patch.GetPlayerAvatarUrl(LocalPlayer)
Patch.AddFooterImage(Window, "info", { Name = "FooterSampleIcon", LayoutOrder = 1, Size = UDim2.fromOffset(16, 16) })
Patch.AddFooterText(Window, "当前玩家头像:", { Name = "FooterAvatarText", LayoutOrder = 3 })
Patch.AddFooterImage(Window, avatarUrl, { Name = "FooterPlayerAvatar", LayoutOrder = 4, Size = UDim2.fromOffset(16, 16) })
Patch.AddFPSText(Window, { Name = "FooterFPS", LayoutOrder = 5 })

local Tabs = {
    Chat = Window:AddTab("聊天", "message-circle"),
    ["UI Settings"] = Window:AddTab("界面设置", "settings"),
}

local function BuildChatUI()
    local Scheme = Library.Scheme
    local Font = Scheme.Font
    local AccentColor = Scheme.AccentColor
    local MainColor = Scheme.MainColor
    local BackgroundColor = Scheme.BackgroundColor
    local OutlineColor = Scheme.OutlineColor
    local FontColor = Scheme.FontColor
    local TextDim = Color3.fromRGB(140, 140, 155)
    local InputBarColor = Library:GetBetterColor(BackgroundColor, 4)
    local HalfCorner = math.max(1, (Library.CornerRadius or 4) / 2)

    local TOP_BAR_H = 40
    local INPUT_BAR_H = 56
    local PADX, PADY = 11, 8
    local NAME_H, NAME_GAP = 14, 4
    local maxBubbleW = Library:GetTextBounds(string.rep("中", 30), Font, 14)
    local minBubbleW = 10
    local minBubbleH = 17

    local wsConnection, isReady = nil, false
    local hideName, hiddenName = false, "User" .. math.random(1000, 9999)
    local syncToRobloxChat, syncToGaoTZ, suppressRobloxSync = false, false, false
    local activeChannelIrc = nil
    local channelData, channelKeys = {}, {}
    local messageCount = 0
    local addMessage, redrawMessages, activateChannel, addSystemMessageWithCopy, createChannelButton

    local function displayToRobloxChat(senderTag, senderName, content)
        if not syncToRobloxChat or suppressRobloxSync then return end
        local ok, TextChatService = pcall(function() return game:GetService("TextChatService") end)
        if not ok or not TextChatService then return end
        local ok2, channel = pcall(function() return TextChatService.TextChannels.RBXSystem end)
        if not ok2 or not channel then return end

        local dim = "rgb(146,153,172)"
        local pink = "rgb(255,105,180)"
        local cyan = "rgb(0,255,255)"
        local white = "rgb(255,255,255)"

        local rich
        if senderTag and senderTag ~= "" then
            rich = string.format(
                '<font color="%s">[</font><font color="%s">IRC</font><font color="%s">] [</font><font color="%s">%s</font><font color="%s">]</font><font color="%s">%s</font>：%s',
                dim, pink, dim, cyan, senderTag, dim, white, senderName or "?", content
            )
        else
            rich = string.format(
                '<font color="%s">[</font><font color="%s">IRC</font><font color="%s">]</font><font color="%s">%s</font>',
                dim, pink, dim, white, content
            )
        end

        pcall(function() channel:DisplaySystemMessage(rich) end)
    end

    local root = Instance.new("Frame")
    root.Name = "ChatUI"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundColor3 = BackgroundColor
    root.BorderSizePixel = 0
    root.ClipsDescendants = true

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, TOP_BAR_H)
    topBar.BackgroundColor3 = MainColor
    topBar.BorderSizePixel = 0
    topBar.Parent = root
    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, 0, 0, 1)
    topLine.Position = UDim2.new(0, 0, 1, 0)
    topLine.BackgroundColor3 = OutlineColor
    topLine.BorderSizePixel = 0
    topLine.Parent = topBar

    local hamburgerBtn = Instance.new("TextButton")
    hamburgerBtn.Size = UDim2.fromOffset(24, 24)
    hamburgerBtn.Position = UDim2.fromOffset(12, 8)
    hamburgerBtn.BackgroundColor3 = MainColor
    hamburgerBtn.BorderSizePixel = 0
    hamburgerBtn.Text = ""
    hamburgerBtn.AutoButtonColor = false
    hamburgerBtn.Parent = topBar
    local hamburgerCorner = Instance.new("UICorner")
    hamburgerCorner.CornerRadius = UDim.new(0, HalfCorner)
    hamburgerCorner.Parent = hamburgerBtn
    local hamburgerStroke = Instance.new("UIStroke")
    hamburgerStroke.Color = OutlineColor
    hamburgerStroke.Parent = hamburgerBtn
    local hamburgerIcon = Instance.new("ImageLabel")
    hamburgerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    hamburgerIcon.Position = UDim2.fromScale(0.5, 0.5)
    hamburgerIcon.Size = UDim2.fromOffset(14, 14)
    hamburgerIcon.BackgroundTransparency = 1
    hamburgerIcon.ImageColor3 = FontColor
    hamburgerIcon.Parent = hamburgerBtn
    Library:ApplyLucideIcon(hamburgerIcon, Library:GetCustomIcon("menu"))

    hamburgerBtn.MouseEnter:Connect(function()
        TweenService:Create(hamburgerStroke, Library.TweenInfo, { Color = AccentColor }):Play()
    end)
    hamburgerBtn.MouseLeave:Connect(function()
        TweenService:Create(hamburgerStroke, Library.TweenInfo, { Color = OutlineColor }):Play()
    end)

    local channelTitle = Instance.new("TextLabel")
    channelTitle.BackgroundTransparency = 1
    channelTitle.AnchorPoint = Vector2.new(0, 0.5)
    channelTitle.Position = UDim2.new(0, 48, 0.5, 0)
    channelTitle.Size = UDim2.new(1, -130, 1, 0)
    channelTitle.Text = "# 全局聊天"
    channelTitle.TextColor3 = FontColor
    channelTitle.TextSize = 14
    channelTitle.FontFace = Font
    channelTitle.TextXAlignment = Enum.TextXAlignment.Left
    channelTitle.Parent = topBar

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.fromOffset(26, 26)
    settingsBtn.AnchorPoint = Vector2.new(1, 0.5)
    settingsBtn.Position = UDim2.new(1, -12, 0.5, 0)
    settingsBtn.BackgroundColor3 = MainColor
    settingsBtn.BorderSizePixel = 0
    settingsBtn.Text = ""
    settingsBtn.AutoButtonColor = false
    settingsBtn.Parent = topBar
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, HalfCorner)
    settingsCorner.Parent = settingsBtn
    local settingsStroke = Instance.new("UIStroke")
    settingsStroke.Color = OutlineColor
    settingsStroke.Parent = settingsBtn
    local settingsIcon = Instance.new("ImageLabel")
    settingsIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    settingsIcon.Position = UDim2.fromScale(0.5, 0.5)
    settingsIcon.Size = UDim2.fromOffset(14, 14)
    settingsIcon.BackgroundTransparency = 1
    settingsIcon.ImageColor3 = FontColor
    settingsIcon.Parent = settingsBtn
    Library:ApplyLucideIcon(settingsIcon, Library:GetCustomIcon("settings"))

    settingsBtn.MouseEnter:Connect(function()
        TweenService:Create(settingsStroke, Library.TweenInfo, { Color = AccentColor }):Play()
    end)
    settingsBtn.MouseLeave:Connect(function()
        TweenService:Create(settingsStroke, Library.TweenInfo, { Color = OutlineColor }):Play()
    end)

    local msgScroll = Instance.new("ScrollingFrame")
    msgScroll.Position = UDim2.fromOffset(0, TOP_BAR_H + 1)
    msgScroll.Size = UDim2.new(1, 0, 1, -(TOP_BAR_H + 1 + INPUT_BAR_H))
    msgScroll.BackgroundTransparency = 1
    msgScroll.BorderSizePixel = 0
    msgScroll.CanvasSize = UDim2.fromOffset(0, 0)
    msgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    msgScroll.ScrollBarThickness = 2
    msgScroll.ScrollBarImageColor3 = OutlineColor
    msgScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    msgScroll.Parent = root
    local msgList = Instance.new("UIListLayout")
    msgList.Padding = UDim.new(0, 10)
    msgList.SortOrder = Enum.SortOrder.LayoutOrder
    msgList.Parent = msgScroll
    local msgPad = Instance.new("UIPadding")
    msgPad.PaddingTop = UDim.new(0, 12)
    msgPad.PaddingBottom = UDim.new(0, 12)
    msgPad.PaddingLeft = UDim.new(0, 12)
    msgPad.PaddingRight = UDim.new(0, 12)
    msgPad.Parent = msgScroll

    local inputBar = Instance.new("Frame")
    inputBar.AnchorPoint = Vector2.new(0, 1)
    inputBar.Position = UDim2.fromScale(0, 1)
    inputBar.Size = UDim2.new(1, 0, 0, INPUT_BAR_H)
    inputBar.BackgroundColor3 = InputBarColor
    inputBar.BorderSizePixel = 0
    inputBar.Parent = root
    local inputLine = Instance.new("Frame")
    inputLine.Size = UDim2.new(1, 0, 0, 1)
    inputLine.BackgroundColor3 = OutlineColor
    inputLine.BorderSizePixel = 0
    inputLine.Parent = inputBar

    local inputBox = Instance.new("TextBox")
    inputBox.BackgroundColor3 = MainColor
    inputBox.BorderSizePixel = 0
    inputBox.AnchorPoint = Vector2.new(0, 0.5)
    inputBox.Position = UDim2.new(0, 10, 0.5, 0.5)
    inputBox.Size = UDim2.new(1, -90, 0, 36)
    inputBox.PlaceholderText = "输入消息..."
    inputBox.PlaceholderColor3 = TextDim
    inputBox.Text = ""
    inputBox.TextColor3 = FontColor
    inputBox.TextSize = 14
    inputBox.FontFace = Font
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.TextYAlignment = Enum.TextYAlignment.Center
    inputBox.TextWrapped = true
    inputBox.MultiLine = true
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputBar
    local inputPad = Instance.new("UIPadding")
    inputPad.PaddingLeft = UDim.new(0, 8)
    inputPad.PaddingRight = UDim.new(0, 8)
    inputPad.Parent = inputBox
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, HalfCorner)
    inputCorner.Parent = inputBox
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = OutlineColor
    inputStroke.Parent = inputBox
    inputBox.Focused:Connect(function()
        TweenService:Create(inputStroke, Library.TweenInfo, { Color = AccentColor }):Play()
    end)
    inputBox.FocusLost:Connect(function()
        TweenService:Create(inputStroke, Library.TweenInfo, { Color = OutlineColor }):Play()
    end)

    local sendBtn = Instance.new("TextButton")
    sendBtn.AnchorPoint = Vector2.new(1, 0.5)
    sendBtn.Position = UDim2.new(1, -10, 0.5, 0.5)
    sendBtn.Size = UDim2.fromOffset(60, 36)
    sendBtn.BackgroundColor3 = MainColor
    sendBtn.BorderSizePixel = 0
    sendBtn.Text = "发送"
    sendBtn.TextColor3 = FontColor
    sendBtn.TextTransparency = 0.4
    sendBtn.TextSize = 14
    sendBtn.FontFace = Font
    sendBtn.AutoButtonColor = false
    sendBtn.Parent = inputBar
    local sendCorner = Instance.new("UICorner")
    sendCorner.CornerRadius = UDim.new(0, HalfCorner)
    sendCorner.Parent = sendBtn
    local sendStroke = Instance.new("UIStroke")
    sendStroke.Color = OutlineColor
    sendStroke.Parent = sendBtn
    sendBtn.MouseEnter:Connect(function()
        TweenService:Create(sendBtn, Library.TweenInfo, { TextTransparency = 0 }):Play()
        TweenService:Create(sendStroke, Library.TweenInfo, { Color = AccentColor }):Play()
    end)
    sendBtn.MouseLeave:Connect(function()
        TweenService:Create(sendBtn, Library.TweenInfo, { TextTransparency = 0.4 }):Play()
        TweenService:Create(sendStroke, Library.TweenInfo, { Color = OutlineColor }):Play()
    end)

    local channelPanel = Instance.new("CanvasGroup")
    channelPanel.Position = UDim2.fromOffset(0, TOP_BAR_H + 1)
    channelPanel.Size = UDim2.new(1, 0, 1, -(TOP_BAR_H + 1 + INPUT_BAR_H))
    channelPanel.BackgroundColor3 = BackgroundColor
    channelPanel.BorderSizePixel = 0
    channelPanel.GroupTransparency = 1
    channelPanel.Visible = false
    channelPanel.ZIndex = 50
    channelPanel.Parent = root

    local channelPanelHeader = Instance.new("Frame")
    channelPanelHeader.Size = UDim2.new(1, 0, 0, 40)
    channelPanelHeader.BackgroundColor3 = MainColor
    channelPanelHeader.BorderSizePixel = 0
    channelPanelHeader.ZIndex = 51
    channelPanelHeader.Parent = channelPanel
    local channelPanelHeaderLine = Instance.new("Frame")
    channelPanelHeaderLine.Size = UDim2.new(1, 0, 0, 1)
    channelPanelHeaderLine.Position = UDim2.new(0, 0, 1, 0)
    channelPanelHeaderLine.BackgroundColor3 = OutlineColor
    channelPanelHeaderLine.BorderSizePixel = 0
    channelPanelHeaderLine.Parent = channelPanelHeader

    local channelPanelTitle = Instance.new("TextLabel")
    channelPanelTitle.BackgroundTransparency = 1
    channelPanelTitle.AnchorPoint = Vector2.new(0, 0.5)
    channelPanelTitle.Position = UDim2.new(0, 12, 0.5, 0)
    channelPanelTitle.Size = UDim2.new(1, -90, 1, 0)
    channelPanelTitle.Text = "频道"
    channelPanelTitle.TextColor3 = FontColor
    channelPanelTitle.TextSize = 14
    channelPanelTitle.FontFace = Font
    channelPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
    channelPanelTitle.Parent = channelPanelHeader

    local channelAddBtn = Instance.new("TextButton")
    channelAddBtn.AnchorPoint = Vector2.new(1, 0.5)
    channelAddBtn.Position = UDim2.new(1, -44, 0.5, 0)
    channelAddBtn.Size = UDim2.fromOffset(24, 24)
    channelAddBtn.BackgroundColor3 = MainColor
    channelAddBtn.BorderSizePixel = 0
    channelAddBtn.Text = ""
    channelAddBtn.AutoButtonColor = false
    channelAddBtn.Parent = channelPanelHeader
    local caCorner = Instance.new("UICorner")
    caCorner.CornerRadius = UDim.new(0, HalfCorner)
    caCorner.Parent = channelAddBtn
    local caStroke = Instance.new("UIStroke")
    caStroke.Color = OutlineColor
    caStroke.Parent = channelAddBtn
    local caIcon = Instance.new("ImageLabel")
    caIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    caIcon.Position = UDim2.fromScale(0.5, 0.5)
    caIcon.Size = UDim2.fromOffset(14, 14)
    caIcon.BackgroundTransparency = 1
    caIcon.ImageColor3 = FontColor
    caIcon.Parent = channelAddBtn
    Library:ApplyLucideIcon(caIcon, Library:GetCustomIcon("plus"))
    channelAddBtn.MouseEnter:Connect(function()
        TweenService:Create(caStroke, Library.TweenInfo, { Color = AccentColor }):Play()
    end)
    channelAddBtn.MouseLeave:Connect(function()
        TweenService:Create(caStroke, Library.TweenInfo, { Color = OutlineColor }):Play()
    end)

    local channelCloseBtn = Instance.new("TextButton")
    channelCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    channelCloseBtn.Position = UDim2.new(1, -12, 0.5, 0)
    channelCloseBtn.Size = UDim2.fromOffset(24, 24)
    channelCloseBtn.BackgroundColor3 = MainColor
    channelCloseBtn.BorderSizePixel = 0
    channelCloseBtn.Text = ""
    channelCloseBtn.AutoButtonColor = false
    channelCloseBtn.Parent = channelPanelHeader
    local ccCorner = Instance.new("UICorner")
    ccCorner.CornerRadius = UDim.new(0, HalfCorner)
    ccCorner.Parent = channelCloseBtn
    local ccStroke = Instance.new("UIStroke")
    ccStroke.Color = OutlineColor
    ccStroke.Parent = channelCloseBtn
    local ccIcon = Instance.new("ImageLabel")
    ccIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ccIcon.Position = UDim2.fromScale(0.5, 0.5)
    ccIcon.Size = UDim2.fromOffset(14, 14)
    ccIcon.BackgroundTransparency = 1
    ccIcon.ImageColor3 = FontColor
    ccIcon.Parent = channelCloseBtn
    Library:ApplyLucideIcon(ccIcon, Library:GetCustomIcon("x"))
    channelCloseBtn.MouseEnter:Connect(function()
        TweenService:Create(ccStroke, Library.TweenInfo, { Color = AccentColor }):Play()
    end)
    channelCloseBtn.MouseLeave:Connect(function()
        TweenService:Create(ccStroke, Library.TweenInfo, { Color = OutlineColor }):Play()
    end)

    local channelScroll = Instance.new("ScrollingFrame")
    channelScroll.Position = UDim2.fromOffset(0, 41)
    channelScroll.Size = UDim2.new(1, 0, 1, -41)
    channelScroll.BackgroundTransparency = 1
    channelScroll.BorderSizePixel = 0
    channelScroll.CanvasSize = UDim2.fromOffset(0, 0)
    channelScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    channelScroll.ScrollBarThickness = 2
    channelScroll.ScrollBarImageColor3 = OutlineColor
    channelScroll.ZIndex = 51
    channelScroll.Parent = channelPanel
    local channelPad = Instance.new("UIPadding")
    channelPad.PaddingTop = UDim.new(0, 8)
    channelPad.PaddingBottom = UDim.new(0, 8)
    channelPad.PaddingLeft = UDim.new(0, 8)
    channelPad.PaddingRight = UDim.new(0, 8)
    channelPad.Parent = channelScroll
    local channelListLayout = Instance.new("UIListLayout")
    channelListLayout.Padding = UDim.new(0, 4)
    channelListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    channelListLayout.Parent = channelScroll

    local channelPanelOpen = false
    local function setChannelPanelOpen(state)
        if channelPanelOpen == state then return end
        channelPanelOpen = state
        if state then
            channelPanel.Visible = true
            channelPanel.GroupTransparency = 1
            TweenService:Create(channelPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                GroupTransparency = 0,
            }):Play()
        else
            local tw = TweenService:Create(channelPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                GroupTransparency = 1,
            })
            tw:Play()
            tw.Completed:Once(function()
                if not channelPanelOpen then channelPanel.Visible = false end
            end)
        end
    end
    hamburgerBtn.MouseButton1Click:Connect(function() setChannelPanelOpen(not channelPanelOpen) end)
    channelCloseBtn.MouseButton1Click:Connect(function() setChannelPanelOpen(false) end)

    local currentDialog = nil
    local function closeDialog()
        if not currentDialog then return end
        local d = currentDialog
        currentDialog = nil
        local dBox = d:FindFirstChild("Dialog")
        TweenService:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()
        if dBox then
            TweenService:Create(dBox, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                GroupTransparency = 1,
                Position = UDim2.new(0.5, 0, 1.3, 0),
            }):Play()
        end
        task.delay(0.24, function() d:Destroy() end)
    end

    local function showDialog(config)
        closeDialog()
        local overlay = Instance.new("TextButton")
        overlay.Name = "DialogOverlay"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.Text = ""
        overlay.AutoButtonColor = false
        overlay.ZIndex = 200
        overlay.Parent = root

        local box = Instance.new("CanvasGroup")
        box.Name = "Dialog"
        box.AnchorPoint = Vector2.new(0.5, 0.5)
        box.Position = UDim2.new(0.5, 0, 1.3, 0)
        box.Size = UDim2.fromOffset(config.width or 280, 0)
        box.AutomaticSize = Enum.AutomaticSize.Y
        box.BackgroundColor3 = MainColor
        box.GroupTransparency = 0
        box.BorderSizePixel = 0
        box.ZIndex = 201
        box.Parent = overlay
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, Library.CornerRadius)
        boxCorner.Parent = box
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = OutlineColor
        boxStroke.Parent = box
        local boxPad = Instance.new("UIPadding")
        boxPad.PaddingTop = UDim.new(0, 12)
        boxPad.PaddingBottom = UDim.new(0, 12)
        boxPad.PaddingLeft = UDim.new(0, 12)
        boxPad.PaddingRight = UDim.new(0, 12)
        boxPad.Parent = box
        local boxLayout = Instance.new("UIListLayout")
        boxLayout.Padding = UDim.new(0, 10)
        boxLayout.SortOrder = Enum.SortOrder.LayoutOrder
        boxLayout.Parent = box

        local titleRow = Instance.new("Frame")
        titleRow.BackgroundTransparency = 1
        titleRow.Size = UDim2.new(1, 0, 0, 24)
        titleRow.LayoutOrder = 1
        titleRow.Parent = box
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Size = UDim2.new(1, -28, 1, 0)
        titleLabel.Text = config.title or ""
        titleLabel.TextColor3 = FontColor
        titleLabel.TextSize = 14
        titleLabel.FontFace = Font
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = titleRow

        local closeX = Instance.new("TextButton")
        closeX.AnchorPoint = Vector2.new(1, 0.5)
        closeX.Position = UDim2.new(1, 0, 0.5, 0)
        closeX.Size = UDim2.fromOffset(24, 24)
        closeX.BackgroundTransparency = 1
        closeX.BorderSizePixel = 0
        closeX.Text = "x"
        closeX.TextColor3 = FontColor
        closeX.TextSize = 18
        closeX.FontFace = Font
        closeX.AutoButtonColor = false
        closeX.Parent = titleRow
        closeX.MouseEnter:Connect(function()
            TweenService:Create(closeX, Library.TweenInfo, { TextColor3 = AccentColor }):Play()
        end)
        closeX.MouseLeave:Connect(function()
            TweenService:Create(closeX, Library.TweenInfo, { TextColor3 = FontColor }):Play()
        end)
        closeX.MouseButton1Click:Connect(closeDialog)

        local content = Instance.new("Frame")
        content.BackgroundTransparency = 1
        content.Size = UDim2.new(1, 0, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.LayoutOrder = 2
        content.Parent = box
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = content

        if config.build then config.build(content) end

        TweenService:Create(overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.55,
        }):Play()
        TweenService:Create(box, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):Play()

        overlay.MouseButton1Click:Connect(function(input)
            if config.outsideClose == false then return end
            local pos = input.Position
            local bPos = box.AbsolutePosition
            local bSize = box.AbsoluteSize
            if pos.X >= bPos.X and pos.X <= bPos.X + bSize.X
               and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y then
                return
            end
            closeDialog()
        end)

        currentDialog = overlay
        return overlay
    end

    local function createDialogButton(parent, text, iconName, onClick)
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = MainColor
        b.BorderSizePixel = 0
        b.Size = UDim2.new(1, 0, 0, 36)
        b.Text = ""
        b.AutoButtonColor = false
        b.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, HalfCorner)
        c.Parent = b
        local s = Instance.new("UIStroke")
        s.Color = OutlineColor
        s.Transparency = 0.5
        s.Parent = b
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(0, 0.5)
        ic.Position = UDim2.new(0, 12, 0.5, 0)
        ic.Size = UDim2.fromOffset(16, 16)
        ic.BackgroundTransparency = 1
        ic.ImageColor3 = AccentColor
        ic.Parent = b
        Library:ApplyLucideIcon(ic, Library:GetCustomIcon(iconName))
        local lb = Instance.new("TextLabel")
        lb.AnchorPoint = Vector2.new(0, 0.5)
        lb.Position = UDim2.new(0, 36, 0.5, 0)
        lb.Size = UDim2.new(1, -48, 1, 0)
        lb.BackgroundTransparency = 1
        lb.Text = text
        lb.TextColor3 = FontColor
        lb.TextSize = 13
        lb.FontFace = Font
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.Parent = b
        b.MouseEnter:Connect(function()
            TweenService:Create(b, Library.TweenInfo, { BackgroundColor3 = Library:GetBetterColor(MainColor, 12) }):Play()
            s.Color = AccentColor
            s.Transparency = 0
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, Library.TweenInfo, { BackgroundColor3 = MainColor }):Play()
            s.Color = OutlineColor
            s.Transparency = 0.5
        end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    local function createInputRow(parent, placeholder)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = MainColor
        f.BorderSizePixel = 0
        f.Size = UDim2.new(1, 0, 0, 36)
        f.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, HalfCorner)
        c.Parent = f
        local s = Instance.new("UIStroke")
        s.Color = OutlineColor
        s.Transparency = 0.5
        s.Parent = f
        local t = Instance.new("TextBox")
        t.BackgroundTransparency = 1
        t.Position = UDim2.new(0, 12, 0, 0)
        t.Size = UDim2.new(1, -24, 1, 0)
        t.PlaceholderText = placeholder
        t.PlaceholderColor3 = TextDim
        t.Text = ""
        t.TextColor3 = FontColor
        t.TextSize = 13
        t.FontFace = Font
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ClearTextOnFocus = false
        t.Parent = f
        t.Focused:Connect(function()
            s.Color = AccentColor
            s.Transparency = 0.2
        end)
        t.FocusLost:Connect(function()
            s.Color = OutlineColor
            s.Transparency = 0.5
        end)
        return t
    end

    local function createToggleRow(parent, text, initial, onChange)
        local r = Instance.new("Frame")
        r.BackgroundTransparency = 1
        r.Size = UDim2.new(1, 0, 0, 32)
        r.Parent = parent
        local lb = Instance.new("TextLabel")
        lb.BackgroundTransparency = 1
        lb.Size = UDim2.new(1, -60, 1, 0)
        lb.Text = text
        lb.TextColor3 = FontColor
        lb.TextSize = 13
        lb.FontFace = Font
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.Parent = r
        local state = initial
        local bg = Instance.new("Frame")
        bg.AnchorPoint = Vector2.new(1, 0.5)
        bg.Position = UDim2.new(1, 0, 0.5, 0)
        bg.Size = UDim2.fromOffset(40, 22)
        bg.BackgroundColor3 = state and AccentColor or MainColor
        bg.Parent = r
        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(1, 0)
        bCorner.Parent = bg
        local bStroke = Instance.new("UIStroke")
        bStroke.Color = OutlineColor
        bStroke.Transparency = 0.5
        bStroke.Parent = bg
        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = state and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
        knob.Size = UDim2.fromOffset(16, 16)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = bg
        local kCorner = Instance.new("UICorner")
        kCorner.CornerRadius = UDim.new(1, 0)
        kCorner.Parent = knob
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = bg
        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(bg, TweenInfo.new(0.15), { BackgroundColor3 = state and AccentColor or MainColor }):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = state and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0),
            }):Play()
            if onChange then onChange(state) end
        end)
        return r
    end

    local showSettingsDialog = function()
        showDialog({
            title = "设置", width = 300,
            build = function(holder)
                createToggleRow(holder, "隐藏聊天室内用户名称", hideName, function(state)
                    hideName = state
                end)
                createToggleRow(holder, "同步到Roblox原版聊天栏", syncToRobloxChat, function(state)
                    syncToRobloxChat = state
                end)
                createToggleRow(holder, "同步到GaoTZ Ui", syncToGaoTZ, function(state)
                    syncToGaoTZ = state
                end)
            end,
        })
    end
    settingsBtn.MouseButton1Click:Connect(showSettingsDialog)

    local showJoinDialog
    showJoinDialog = function()
        showDialog({
            title = "加入频道", width = 300,
            build = function(holder)
                local nameInput = createInputRow(holder, "频道名称，例如 private-123456")
                local keyInput = createInputRow(holder, "密钥，可选")
                local joinBtn = Instance.new("TextButton")
                joinBtn.BackgroundColor3 = AccentColor
                joinBtn.BorderSizePixel = 0
                joinBtn.Size = UDim2.new(1, 0, 0, 34)
                joinBtn.Text = "加入"
                joinBtn.TextColor3 = Color3.new(1, 1, 1)
                joinBtn.TextSize = 13
                joinBtn.FontFace = Font
                joinBtn.AutoButtonColor = false
                joinBtn.Parent = holder
                local jc = Instance.new("UICorner")
                jc.CornerRadius = UDim.new(0, HalfCorner)
                jc.Parent = joinBtn
                local function submit()
                    local raw = nameInput.Text:match("^%s*(.-)%s*$")
                    if raw == "" then return end
                    local displayName = raw:gsub("^#", "")
                    local ircChannel = "#" .. displayName:gsub("[%s,:%c\001]", "-")
                    local key = keyInput.Text:match("^%s*(.-)%s*$")
                    if key == "" then key = nil end
                    if key then channelKeys[ircChannel] = key end
                    local btn = createChannelButton(displayName, ircChannel)
                    activateChannel(btn)
                    closeDialog()
                end
                joinBtn.MouseButton1Click:Connect(submit)
                nameInput.FocusLost:Connect(function(enter) if enter then submit() end end)
                keyInput.FocusLost:Connect(function(enter) if enter then submit() end end)
            end,
        })
    end

    local showCreateDialog = function()
        showDialog({
            title = "创建私人频道", width = 260,
            build = function(holder)
                if not wsConnection or not isReady then
                    local lbl = Instance.new("TextLabel")
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.new(1, 0, 0, 40)
                    lbl.Text = "未连接到服务器，无法创建频道"
                    lbl.TextColor3 = Color3.fromRGB(255, 120, 120)
                    lbl.TextSize = 13
                    lbl.FontFace = Font
                    lbl.TextWrapped = true
                    lbl.Parent = holder
                    return
                end
                local info = Instance.new("TextLabel")
                info.BackgroundTransparency = 1
                info.Size = UDim2.new(1, 0, 0, 40)
                info.Text = "将创建一个随机名称的私人频道，并生成密钥。"
                info.TextColor3 = TextDim
                info.TextSize = 13
                info.FontFace = Font
                info.TextWrapped = true
                info.Parent = holder
                local createBtn = Instance.new("TextButton")
                createBtn.BackgroundColor3 = AccentColor
                createBtn.BorderSizePixel = 0
                createBtn.Size = UDim2.new(1, 0, 0, 34)
                createBtn.Text = "创建频道"
                createBtn.TextColor3 = Color3.new(1, 1, 1)
                createBtn.TextSize = 13
                createBtn.FontFace = Font
                createBtn.AutoButtonColor = false
                createBtn.Parent = holder
                local cc = Instance.new("UICorner")
                cc.CornerRadius = UDim.new(0, HalfCorner)
                cc.Parent = createBtn
                createBtn.MouseButton1Click:Connect(function()
                    local rand = math.random(100000, 999999)
                    local chName = "#private-" .. rand
                    addSystemMessageWithCopy("正在创建私人频道 " .. chName .. " ...", chName, true)
                    wsConnection:Send(HttpService:JSONEncode({ type = "create_private", channel = chName }))
                    closeDialog()
                end)
            end,
        })
    end

    channelAddBtn.MouseButton1Click:Connect(function()
        showDialog({
            title = "频道", width = 260,
            build = function(holder)
                createDialogButton(holder, "加入频道", "log-in", function() showJoinDialog() end)
                createDialogButton(holder, "创建频道", "users", function() showCreateDialog() end)
            end,
        })
    end)

    local function scrollToBottom()
        task.defer(function()
            msgScroll.CanvasPosition = Vector2.new(0, msgList.AbsoluteContentSize.Y)
        end)
    end

    local function updateChannelTitle()
        if activeChannelIrc and channelData[activeChannelIrc] then
            channelTitle.Text = "# " .. channelData[activeChannelIrc].displayName
        else
            channelTitle.Text = "# 全局聊天"
        end
    end

    createChannelButton = function(displayName, ircChannel)
        if channelData[ircChannel] then
            return channelData[ircChannel].btn, false
        end
        local btn = Instance.new("TextButton")
        btn.Name = "Channel_" .. displayName
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = MainColor
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = channelScroll
        btn:SetAttribute("ChannelName", displayName)
        btn:SetAttribute("IRCChannel", ircChannel)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, HalfCorner)
        corner.Parent = btn
        local icon = Instance.new("ImageLabel")
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 10, 0.5, 0)
        icon.Size = UDim2.fromOffset(14, 14)
        icon.BackgroundTransparency = 1
        icon.ImageColor3 = FontColor
        icon.Parent = btn
        Library:ApplyLucideIcon(icon, Library:GetCustomIcon("hash"))
        local label = Instance.new("TextLabel")
        label.AnchorPoint = Vector2.new(0, 0.5)
        label.Position = UDim2.new(0, 32, 0.5, 0)
        label.Size = UDim2.new(1, -40, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = displayName
        label.TextColor3 = FontColor
        label.TextSize = 13
        label.FontFace = Font
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn
        btn.MouseEnter:Connect(function()
            if activeChannelIrc ~= ircChannel then
                TweenService:Create(btn, Library.TweenInfo, { BackgroundTransparency = 0.75, BackgroundColor3 = MainColor }):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeChannelIrc ~= ircChannel then
                TweenService:Create(btn, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            end
        end)
        btn.MouseButton1Click:Connect(function() activateChannel(btn) end)
        channelData[ircChannel] = { btn = btn, messages = {}, displayName = displayName }
        return btn, true
    end

    activateChannel = function(btn)
        if not btn then return end
        local irc = btn:GetAttribute("IRCChannel")
        if activeChannelIrc == irc then
            setChannelPanelOpen(false)
            return
        end
        activeChannelIrc = irc
        for irc2, data in pairs(channelData) do
            local active = (irc2 == irc)
            TweenService:Create(data.btn, Library.TweenInfo, { BackgroundColor3 = active and AccentColor or MainColor }):Play()
            TweenService:Create(data.btn, Library.TweenInfo, { BackgroundTransparency = active and 0.15 or 1 }):Play()
        end
        updateChannelTitle()
        redrawMessages(irc)
        if wsConnection and isReady then
            local payload = { type = "join", channel = irc }
            if channelKeys[irc] then payload.key = channelKeys[irc] end
            wsConnection:Send(HttpService:JSONEncode(payload))
        end
        setChannelPanelOpen(false)
    end

    addMessage = function(text, displayName, username, image, isSystem, isMine, tag, hideAvatar, skipStore)
        messageCount += 1
        if isSystem then
            if not skipStore and activeChannelIrc and channelData[activeChannelIrc] then
                table.insert(channelData[activeChannelIrc].messages, {
                    type = "system",
                    content = text,
                })
            end
            local row = Instance.new("Frame")
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.LayoutOrder = messageCount
            row.Parent = msgScroll
            local group = Instance.new("CanvasGroup")
            group.Name = "Group"
            group.BackgroundTransparency = 1
            group.Size = UDim2.new(1, 0, 0, 0)
            group.AutomaticSize = Enum.AutomaticSize.Y
            group.GroupTransparency = 1
            group.Parent = row
            local bubble = Instance.new("Frame")
            bubble.AnchorPoint = Vector2.new(0.5, 0)
            bubble.Position = UDim2.new(0.5, 0, 0, 0)
            bubble.BackgroundColor3 = MainColor
            bubble.BackgroundTransparency = 0.25
            bubble.Size = UDim2.fromOffset(0, 0)
            bubble.AutomaticSize = Enum.AutomaticSize.XY
            bubble.Parent = group
            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(1, 0)
            bc.Parent = bubble
            local bp = Instance.new("UIPadding")
            bp.PaddingTop = UDim.new(0, 6)
            bp.PaddingBottom = UDim.new(0, 6)
            bp.PaddingLeft = UDim.new(0, 14)
            bp.PaddingRight = UDim.new(0, 14)
            bp.Parent = bubble
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.fromOffset(0, 0)
            label.AutomaticSize = Enum.AutomaticSize.XY
            label.Text = text
            label.TextColor3 = TextDim
            label.TextSize = 12
            label.FontFace = Font
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Parent = bubble
            local constraint = Instance.new("UISizeConstraint")
            constraint.MaxSize = Vector2.new(260, math.huge)
            constraint.Parent = label
            TweenService:Create(group, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
            scrollToBottom()
            return row
        end

        local nameDisplayText = username or displayName or "?"
        local nameRichText
        if tag and tag ~= "" then
            nameRichText = string.format(
                '<font color="rgb(146,153,172)">[</font><font color="rgb(0,255,255)">%s</font><font color="rgb(146,153,172)">]</font><font color="rgb(255,255,255)">%s</font>',
                tag, nameDisplayText
            )
        else
            nameRichText = nameDisplayText
        end

        local textW, textH = Library:GetTextBounds(text, Font, 14, maxBubbleW)
        textW = math.max((textW or 0) + 2, minBubbleW)
        textH = math.max(textH or 0, minBubbleH)
        local bubbleW = textW + PADX * 2
        local bubbleH = textH + PADY * 2
        local nameW = math.max(Library:GetTextBounds(nameRichText, Font, 11) or 0, 30)
        local colW = math.max(nameW, bubbleW)
        local colH = NAME_H + NAME_GAP + bubbleH

        local wrapper = Instance.new("CanvasGroup")
        wrapper.Name = "MsgWrapper"
        wrapper.BackgroundTransparency = 1
        wrapper.Size = UDim2.new(1, 0, 0, colH + 4)
        wrapper.ClipsDescendants = true
        wrapper.GroupTransparency = 1
        wrapper.LayoutOrder = messageCount
        wrapper.Parent = msgScroll
        local animFrame = Instance.new("Frame")
        animFrame.BackgroundTransparency = 1
        animFrame.Size = UDim2.new(1, 0, 1, 0)
        animFrame.Position = UDim2.fromOffset(isMine and 50 or -50, 0)
        animFrame.Parent = wrapper
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 1, 0)
        row.Parent = animFrame
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = isMine and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        rowLayout.Padding = UDim.new(0, 8)
        rowLayout.Parent = row

        if hideAvatar then
            local avatarText = Instance.new("TextLabel")
            avatarText.Size = UDim2.fromOffset(34, 34)
            avatarText.BackgroundColor3 = MainColor
            avatarText.BorderSizePixel = 0
            avatarText.Text = (username or displayName or "?"):sub(-4)
            avatarText.TextColor3 = FontColor
            avatarText.TextSize = 10
            avatarText.FontFace = Font
            avatarText.Parent = row
            local ac = Instance.new("UICorner")
            ac.CornerRadius = UDim.new(1, 0)
            ac.Parent = avatarText
            local as = Instance.new("UIStroke")
            as.Color = OutlineColor
            as.Transparency = 0.4
            as.Parent = avatarText
        elseif image then
            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.fromOffset(34, 34)
            avatar.BackgroundColor3 = MainColor
            avatar.BorderSizePixel = 0
            avatar.Image = image
            avatar.Parent = row
            local ac = Instance.new("UICorner")
            ac.CornerRadius = UDim.new(1, 0)
            ac.Parent = avatar
            local as = Instance.new("UIStroke")
            as.Color = OutlineColor
            as.Transparency = 0.4
            as.Parent = avatar
        end

        local contentCol = Instance.new("Frame")
        contentCol.BackgroundTransparency = 1
        contentCol.Size = UDim2.fromOffset(colW, colH)
        contentCol.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Position = UDim2.fromOffset(0, 0)
        nameLabel.Size = UDim2.fromOffset(colW, NAME_H)
        nameLabel.RichText = true
        nameLabel.Text = nameRichText
        nameLabel.TextColor3 = FontColor
        nameLabel.TextTransparency = 0.45
        nameLabel.TextSize = 11
        nameLabel.FontFace = Font
        nameLabel.TextXAlignment = isMine and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.Parent = contentCol

        local bubble = Instance.new("Frame")
        bubble.BackgroundColor3 = isMine and AccentColor or MainColor
        bubble.BackgroundTransparency = isMine and 0.15 or 0
        bubble.BorderSizePixel = 0
        bubble.Position = UDim2.fromOffset(isMine and (colW - bubbleW) or 0, NAME_H + NAME_GAP)
        bubble.Size = UDim2.fromOffset(bubbleW, bubbleH)
        bubble.Parent = contentCol
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 12)
        bc.Parent = bubble
        local bstroke = Instance.new("UIStroke")
        bstroke.Color = isMine and AccentColor or OutlineColor
        bstroke.Transparency = isMine and 0.4 or 0
        bstroke.Parent = bubble
        local bpad = Instance.new("UIPadding")
        bpad.PaddingTop = UDim.new(0, PADY)
        bpad.PaddingBottom = UDim.new(0, PADY)
        bpad.PaddingLeft = UDim.new(0, PADX)
        bpad.PaddingRight = UDim.new(0, PADX)
        bpad.Parent = bubble

        local bubbleText = Instance.new("TextLabel")
        bubbleText.BackgroundTransparency = 1
        bubbleText.Size = UDim2.new(1, 0, 1, 0)
        bubbleText.Text = text
        bubbleText.TextColor3 = isMine and Color3.new(1, 1, 1) or FontColor
        bubbleText.TextSize = 14
        bubbleText.FontFace = Font
        bubbleText.TextWrapped = true
        bubbleText.TextXAlignment = Enum.TextXAlignment.Left
        bubbleText.TextYAlignment = Enum.TextYAlignment.Center
        bubbleText.LineHeight = 1
        bubbleText.Parent = bubble

        if isMine then
            contentCol.LayoutOrder = 1
            local avatarC = row:GetChildren()[1]
            if avatarC and avatarC:IsA("GuiObject") then avatarC.LayoutOrder = 2 end
        else
            contentCol.LayoutOrder = 2
            local avatarC = row:GetChildren()[1]
            if avatarC and avatarC:IsA("GuiObject") then avatarC.LayoutOrder = 1 end
        end

        TweenService:Create(wrapper, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
        TweenService:Create(animFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }):Play()

        displayToRobloxChat(tag, username or displayName, text)

        scrollToBottom()
        return wrapper
    end

    addSystemMessageWithCopy = function(text, copyText, hideCopy, skipStore)
        if not skipStore and activeChannelIrc and channelData[activeChannelIrc] then
            table.insert(channelData[activeChannelIrc].messages, {
                type = "copySystem",
                content = text,
                copyText = copyText,
                hideCopy = hideCopy,
            })
        end
        messageCount += 1
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.LayoutOrder = messageCount
        row.Parent = msgScroll
        local group = Instance.new("CanvasGroup")
        group.BackgroundTransparency = 1
        group.Size = UDim2.new(1, 0, 0, 0)
        group.AutomaticSize = Enum.AutomaticSize.Y
        group.GroupTransparency = 1
        group.Parent = row
        local bubble = Instance.new("Frame")
        bubble.AnchorPoint = Vector2.new(0.5, 0)
        bubble.Position = UDim2.new(0.5, 0, 0, 0)
        bubble.BackgroundColor3 = MainColor
        bubble.BackgroundTransparency = 0.25
        bubble.Size = UDim2.fromOffset(0, 0)
        bubble.AutomaticSize = Enum.AutomaticSize.XY
        bubble.Parent = group
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = bubble
        local bp = Instance.new("UIPadding")
        bp.PaddingTop = UDim.new(0, 5)
        bp.PaddingBottom = UDim.new(0, 5)
        bp.PaddingLeft = UDim.new(0, 12)
        bp.PaddingRight = UDim.new(0, 12)
        bp.Parent = bubble
        local bl = Instance.new("UIListLayout")
        bl.FillDirection = Enum.FillDirection.Horizontal
        bl.Padding = UDim.new(0, 6)
        bl.VerticalAlignment = Enum.VerticalAlignment.Center
        bl.Parent = bubble
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromOffset(0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.XY
        lbl.Text = text
        lbl.TextColor3 = TextDim
        lbl.TextSize = 12
        lbl.FontFace = Font
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.LayoutOrder = 1
        lbl.Parent = bubble
        if not hideCopy then
            local cb = Instance.new("TextButton")
            cb.Size = UDim2.fromOffset(18, 18)
            cb.BackgroundTransparency = 1
            cb.Text = ""
            cb.AutoButtonColor = false
            cb.LayoutOrder = 2
            cb.Parent = bubble
            local ci = Instance.new("ImageLabel")
            ci.AnchorPoint = Vector2.new(0.5, 0.5)
            ci.Position = UDim2.fromScale(0.5, 0.5)
            ci.Size = UDim2.fromOffset(14, 14)
            ci.BackgroundTransparency = 1
            ci.ImageColor3 = TextDim
            ci.Parent = cb
            Library:ApplyLucideIcon(ci, Library:GetCustomIcon("copy"))
            local chk = Instance.new("ImageLabel")
            chk.AnchorPoint = Vector2.new(0.5, 0.5)
            chk.Position = UDim2.fromScale(0.5, 0.5)
            chk.Size = UDim2.fromOffset(14, 14)
            chk.BackgroundTransparency = 1
            chk.ImageColor3 = Color3.fromRGB(110, 220, 130)
            chk.Visible = false
            chk.Parent = cb
            Library:ApplyLucideIcon(chk, Library:GetCustomIcon("check"))
            local resetToken = 0
            cb.MouseButton1Click:Connect(function()
                if setclipboard then pcall(setclipboard, copyText) end
                ci.Visible = false
                chk.Visible = true
                resetToken += 1
                local myToken = resetToken
                task.delay(2, function()
                    if resetToken == myToken then
                        ci.Visible = true
                        chk.Visible = false
                    end
                end)
            end)
        end
        TweenService:Create(group, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
        scrollToBottom()
        return row
    end

    redrawMessages = function(ircChannel)
        for _, child in ipairs(msgScroll:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
        messageCount = 0
        local data = channelData[ircChannel]
        if not data then return end
        suppressRobloxSync = true
        for _, m in ipairs(data.messages) do
            if m.type == "system" then
                addMessage(m.content, nil, nil, nil, true, false, nil, nil, true)
            elseif m.type == "copySystem" then
                addSystemMessageWithCopy(m.content, m.copyText, m.hideCopy, true)
            else
                addMessage(m.content, m.displayName, m.username, m.image, m.isSystem, m.isMine, m.tag, m.hideAvatar, true)
            end
        end
        suppressRobloxSync = false
    end

    local function getDisplayName()
        return hideName and hiddenName or LocalPlayer.Name
    end
    local function sendMessage()
        local content = inputBox.Text
        if content:gsub("%s", "") == "" then return end
        if not wsConnection or not isReady then
            addMessage("未连接到服务器，无法发送", nil, nil, nil, true, false)
            return
        end
        if not activeChannelIrc then
            addMessage("尚未加入任何频道", nil, nil, nil, true, false)
            return
        end
        local sendName = getDisplayName()
        local nameInMessage = hideName and ("[H]" .. sendName) or sendName
        local formatted = string.format("[IRC][%s][User]%s：%s", MyTag, nameInMessage, content)
        wsConnection:Send(HttpService:JSONEncode({ type = "message", message = formatted, channel = activeChannelIrc }))

        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        local img = ok and url or "rbxassetid://0"

        local msgData = {
            content = content, displayName = sendName, username = sendName, image = img,
            isSystem = false, isMine = true, tag = MyTag, hideAvatar = hideName,
        }
        if channelData[activeChannelIrc] then
            table.insert(channelData[activeChannelIrc].messages, msgData)
        end
        addMessage(content, sendName, sendName, img, false, true, MyTag, hideName, true)
        inputBox.Text = ""
    end
    sendBtn.MouseButton1Click:Connect(sendMessage)

    local function connectWS()
        if not WebSocket or not WebSocket.connect then
            addMessage("执行器不支持 WebSocket", nil, nil, nil, true, false)
            return
        end
        task.spawn(function()
            addMessage("正在连接服务器...", nil, nil, nil, true, false)
            local ok, ws = pcall(function() return WebSocket.connect(WS_URL) end)
            if not ok or not ws then
                addMessage("服务器连接失败，请稍后重试", nil, nil, nil, true, false)
                return
            end
            wsConnection = ws
            ws:Send(HttpService:JSONEncode({
                type = "init", userId = tostring(LocalPlayer.UserId),
                username = LocalPlayer.Name, displayName = LocalPlayer.DisplayName or LocalPlayer.Name,
                jobId = game.JobId,
            }))
            ws.OnMessage:Connect(function(raw)
                local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if not ok2 or not data then return end

                if data.type == "ready" then
                    isReady = true
                    local pub = data.channel or "#unknown"
                    if not channelData[pub] then
                        local btn = createChannelButton("公共频道", pub)
                        activateChannel(btn)
                    end
                    addMessage("请在IRC频道内保持和善交流", nil, nil, nil, true, false)
                    addMessage("服务器连接成功，已进入公共频道", nil, nil, nil, true, false)
                elseif data.type == "private_created" then
                    local chName = data.channel or "#unknown"
                    local key = data.key
                    if key then channelKeys[chName] = tostring(key) end
                    local btn = createChannelButton("私人频道", chName)
                    activateChannel(btn)
                    addSystemMessageWithCopy("私人频道已创建：" .. chName, chName)
                    if key then addSystemMessageWithCopy("频道密钥：" .. tostring(key), tostring(key)) end
                elseif data.type == "message" and data.data then
                    local msg = data.data
                    local irc = msg.channel
                    if not channelData[irc] then return end
                    local isMine = (msg.userId == tostring(LocalPlayer.UserId))
                    local rawMsg = msg.message or ""
                    local senderTag, senderName, actual = rawMsg:match("^%[IRC%]%[([^%]]+)%]%[User%]([^：]+)：(.*)$")
                    if not senderTag then
                        senderTag = nil; senderName = nil; actual = rawMsg
                    end
                    local hideAvatar = false
                    if senderName and senderName:sub(1, 3) == "[H]" then
                        hideAvatar = true
                        senderName = senderName:sub(4)
                    end
                    local ok, url = pcall(function()
                        return Players:GetUserThumbnailAsync(tonumber(msg.userId) or 0, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    end)
                    local img = ok and url or "rbxassetid://0"
                    local msgData = {
                        content = actual, displayName = senderName or msg.displayName or msg.username or "?",
                        username = senderName or msg.username or "?",
                        image = img, isSystem = false, isMine = isMine, tag = senderTag, hideAvatar = hideAvatar,
                    }
                    table.insert(channelData[irc].messages, msgData)
                    if activeChannelIrc == irc and not isMine then
                        addMessage(msgData.content, msgData.displayName, msgData.username, msgData.image, false, false, msgData.tag, msgData.hideAvatar, true)
                        if syncToGaoTZ and NoticeLib then
                            local notifyIcon = msgData.image
                            if hideAvatar or not notifyIcon or notifyIcon == "rbxassetid://0" then notifyIcon = "message-circle" end
                            local notifyTitle = msgData.displayName or msgData.username or "未知用户"
                            task.spawn(function()
                                local ok3 = pcall(NoticeLib.ShowNotification, notifyIcon, notifyTitle, msgData.content or "", 3)
                                if not ok3 then
                                    pcall(NoticeLib.ShowNotification, "message-circle", notifyTitle, msgData.content or "", 3)
                                end
                            end)
                        end
                    end
                elseif data.type == "irc_closed" then
                    addMessage("IRC 连接被关闭", nil, nil, nil, true, false)
                elseif data.type == "error" then
                    addMessage("服务器错误：" .. tostring(data.message or "未知"), nil, nil, nil, true, false)
                end
            end)
            ws.OnClose:Connect(function()
                isReady = false
                wsConnection = nil
                addMessage("WebSocket 连接已关闭", nil, nil, nil, true, false)
            end)
        end)
    end

    updateChannelTitle()
    task.spawn(function()
        addMessage("正在等待服务端分配公共频道...", nil, nil, nil, true, false)
        connectWS()
    end)

    return root
end

local ChatUI = BuildChatUI()
local ChatPass = Tabs.Chat:AddUIPassthrough("ChatUI", {
    Instance = ChatUI,
    Fullscreen = true,
    ZIndex = 100,
    Visible = true,
})

local MenuGroup = Tabs["UI Settings"]:AddGroupbox({
    Name = "菜单", Description = "调整 UI 外观与按键。", IconName = "wrench", Side = 1,
})
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible, Text = "打开按键绑定菜单",
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "自定义光标", Default = Library.ShowCustomCursor,
    Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "左", "右" }, Default = "右", Text = "通知位置",
    Callback = function(v) Library:SetNotifySide(v) end,
})
MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI 缩放",
    Callback = function(v)
        v = v:gsub("%%", "")
        local dpi = tonumber(v)
        Library:SetDPIScale(dpi)
    end,
})
MenuGroup:AddSlider("UICornerSlider", {
    Text = "圆角半径", Default = Library.CornerRadius, Min = 0, Max = 20, Rounding = 0,
    Callback = function(value) Window:SetCornerRadius(value) end,
})
local LockButtonDefault = true
if Patch.MobileButtons.Lock and Patch.MobileButtons.Lock.Button then
    LockButtonDefault = Patch.MobileButtons.Lock.Button.Visible ~= false
end
MenuGroup:AddCheckbox("ShowLockButton", {
    Text = "显示锁定按钮", Tooltip = "控制锁定按钮是否显示，仅移动端有效",
    Default = LockButtonDefault,
    Callback = function(value)
        if Patch.MobileButtons.Lock and Patch.MobileButtons.Lock.Button then
            Patch.MobileButtons.Lock.Button.Visible = value
        end
    end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("菜单绑定"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "菜单按键" })
MenuGroup:AddButton("卸载", function() Library:Unload() end)
Library.ToggleKeybind = Library.Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()