--67.1
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GHOST = 0.45

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local placeFood = ReplicatedStorage:WaitForChild("PlaceFood")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	if not checkcaller() and getnamecallmethod() == "InvokeServer" then
		local isGP = false
		pcall(function()
			isGP = typeof(self) == "Instance"
				and self:IsA("RemoteFunction")
				and self.Name:lower():find("gamepass", 1, true) ~= nil
		end)
		if isGP then
			return true
		end
	end
	return oldNamecall(self, ...)
end))

local function lift(inst)
	if inst:IsA("LocalScript") and inst.Name:lower():find("maximum", 1, true) then
		pcall(function()
			inst.Disabled = true
		end)
	end
end

for _, d in ipairs(plr.PlayerGui:GetDescendants()) do
	lift(d)
end

plr.PlayerGui.DescendantAdded:Connect(function(d)
	task.defer(lift, d)
end)

local anchor = Instance.new("Part")
anchor.Name = "TrayPlaceable"
anchor.Size = Vector3.new(0.2, 0.2, 0.2)
anchor.Transparency = 1
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanTouch = false
anchor.CanQuery = false
anchor.Parent = workspace

local folder = Instance.new("Folder")
folder.Name = "PlacedFoods"
folder.Parent = anchor

local trayCache = setmetatable({}, { __mode = "k" })

local function trackTray(inst)
	if inst:IsA("Folder") and inst.Name == "PlacedFoods" then
		trayCache[inst] = true
	end
end

for _, d in ipairs(workspace:GetDescendants()) do
	trackTray(d)
end

workspace.DescendantAdded:Connect(trackTray)

local yAxis = Vector3.new(0, 1, 0)
local green = Color3.fromRGB(0, 255, 0)
local hitPart
local fakeHit = { Position = Vector3.zero, Normal = yAxis, Instance = nil }
local baseAlpha = setmetatable({}, { __mode = "k" })

local function currentTool()
	local c = plr.Character
	return c and c:FindFirstChildOfClass("Tool")
end

local function validTray(inst)
	return inst ~= nil
		and typeof(inst) == "Instance"
		and inst.Name == "TrayPlaceable"
		and inst:FindFirstChild("PlacedFoods") ~= nil
end

local function resolveTray(inst)
	if typeof(inst) ~= "Instance" then
		return nil
	end
	if validTray(inst) then
		return inst
	end
	local a = inst
	while a and a ~= workspace do
		if a:FindFirstChild("PlacedFoods") then
			return a
		end
		a = a.Parent
	end
	return nil
end

local function shade(part)
	local orig = baseAlpha[part]
	if orig == nil then
		orig = part.Transparency
		baseAlpha[part] = orig
	end
	part.Transparency = orig + (1 - orig) * GHOST
end

local function dress(inst)
	if inst:IsA("Highlight") then
		inst.FillColor = green
		inst.OutlineColor = green
		inst.FillTransparency = 0.9
		inst.OutlineTransparency = 0
		return
	end
	if inst:IsA("BasePart") then
		shade(inst)
	end
end

local function polish(preview)
	if preview:IsA("BasePart") then
		shade(preview)
	end
	for _, d in ipairs(preview:GetDescendants()) do
		dress(d)
	end
end

local function refresh()
	if not currentTool() then
		hitPart = nil
		return
	end

	local char = plr.Character
	local filter = { anchor }
	if char then
		filter[#filter + 1] = char
	end
	for f in pairs(trayCache) do
		if f.Parent then
			filter[#filter + 1] = f
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filter

	local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
	local res = workspace:Raycast(ray.Origin, ray.Direction * 3000, params)

	local pos, normal
	if res then
		pos, normal, hitPart = res.Position, res.Normal, res.Instance
	else
		pos, normal, hitPart = ray.Origin + ray.Direction * 60, -ray.Direction, nil
	end

	fakeHit = { Position = pos, Normal = normal, Instance = hitPart }

	local right = normal:Cross(yAxis)
	if right.Magnitude < 0.001 then
		right = Vector3.new(1, 0, 0)
	end
	anchor.CFrame = CFrame.fromMatrix(pos, right.Unit, normal)

	local preview = mouse.TargetFilter
	if typeof(preview) == "Instance" and preview.Parent then
		polish(preview)
	end
end

RunService.RenderStepped:Connect(refresh)

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
	if self == mouse and not checkcaller() then
		if key == "Target" then
			return resolveTray(oldIndex(self, "Target")) or anchor
		elseif key == "TargetSurface" then
			return Enum.NormalId.Top
		elseif key == "Hit" then
			return fakeHit
		end
	end
	return oldIndex(self, key)
end))

local oldBounds
oldBounds = hookfunction(workspace.GetPartBoundsInBox, newcclosure(function(self, cf, size, params)
	if not checkcaller() and params then
		local list = params.FilterDescendantsInstances
		if list then
			for _, v in ipairs(list) do
				if v and v.Name == "PlacedFoods" then
					return {}
				end
			end
		end
	end
	return oldBounds(self, cf, size, params)
end))

local lastFire = 0

local function schedulePlace()
	local p = mouse.TargetFilter
	if typeof(p) ~= "Instance" or not p.Parent then
		return
	end

	task.delay(0.6, function()
		local now = mouse.TargetFilter
		local tool = currentTool()
		if now ~= p or not tool then
			return
		end
		if os.clock() - lastFire < 1 then
			return
		end
		lastFire = os.clock()

		local cf = p:IsA("Model") and p:GetPivot() or p.CFrame
		local tray = resolveTray(hitPart)
		pcall(function()
			placeFood:FireServer("PlacedFood", tool.Name, cf, tool, tray or hitPart)
		end)
	end)
end

mouse.Button1Down:Connect(schedulePlace)

task.spawn(function()
	local gui = plr.PlayerGui:WaitForChild("PhoneFoodControls", 15)
	if not gui then
		return
	end
	local place = gui:WaitForChild("Place", 10)
	if place and place:IsA("GuiButton") then
		place.MouseButton1Up:Connect(schedulePlace)
	end
end)