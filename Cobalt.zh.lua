--Cobalt-ZH
local URL = "https://raw.githubusercontent.com/gZE66/Ngh/main/Cobalt.lua"
local PLUGIN_PATH = "Cobalt/Plugins/StrictRemoteCode.lua"

local BLOCK = {}
for _, Name in ipairs({
	"Equals", "NotEquals", "LessThan", "LessThanOrEqual", "GreaterThan",
	"GreaterThanOrEqual", "Contains", "StartsWith", "EndsWith", "TypeIs",
	"Argument", "ArgumentCount", "Instance", "Query", "And", "Or", "None",
	"Name", "ClassName", "FullName", "Class",
	"RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent", "BindableEvent", "BindableFunction",
	"Outgoing", "Incoming", "Any", "All", "Ignore", "Block", "Highlight",
	"Arguments", "Args", "InvokeResult", "Event", "Call", "Hook", "InstancePath",
	"Font", "Image", "RemoteList", "CallList", "GetNil", "Upvalue Lookup",
	"Index", "WaitForChild", "FindFirstChild", "Unload", "ActorCall",
	"MainBlock", "MainIgnore", "MainSettingsSync", "MainCallFiltersSync",
	"InspectIncomingConnections", "ResolveEventReference", "ResolveEventReferenceResponse",
	"IncomingConnectionMetadata", "LimitedLoggingAcknowledged",
}) do
	BLOCK[Name] = true
end

local DICT = {
["Settings"] = "设置", ["Plugins"] = "插件", ["General"] = "通用", ["Capture"] = "捕获",
["Filtering"] = "过滤", ["Call Filters"] = "调用过滤器", ["Ignored Remotes"] = "已忽略远程",
["Blocked Remotes"] = "已拦截远程", ["Code Generation"] = "代码生成", ["File Logging"] = "文件日志",
["Compatibility & Safety"] = "兼容与安全", ["About & Credits"] = "关于与致谢",
["Interface Scale"] = "界面缩放", ["Calls Per Page"] = "每页调用数",
["Relaunch After Teleport"] = "传送后重新注入",
["Use RakNet Hooks on Relaunch (Experimental)"] = "重新注入时使用 RakNet 钩子(实验性)",
["Use Oth Hooks on Relaunch"] = "重新注入时使用 Oth 钩子",
["Capture Roblox Internal Events"] = "捕获 Roblox 内部事件",
["Capture Actor Calls"] = "捕获 Actor 调用",
["Record Blocked Calls"] = "记录被拦截的调用",
["Ignored Remote Classes"] = "忽略的远程类别",
["Auto-ignore High-frequency Calls"] = "自动忽略高频调用",
["Ignore PlayerModule Calls"] = "忽略 PlayerModule 调用",
["Show Executor Calls"] = "显示注入器调用",
["Instance Path Style"] = "实例路径风格",
["Nil Instance Strategy"] = "nil 实例策略",
["Use buffer.fromstring()"] = "使用 buffer.fromstring()",
["Include Cobalt Header"] = "包含 Cobalt 头注释",
["Save Calls to File"] = "将调用保存到文件",
["Skip Optional Executor Checks"] = "跳过可选的注入器检查",
["Enable Anti-Cheat Bypass"] = "启用反作弊绕过",
["Clear Captured Calls"] = "清空已捕获调用",
["Reset Filtering Preferences"] = "重置过滤偏好",
["Copy File Name"] = "复制文件名", ["Copy File Path"] = "复制文件路径",
["Export Session as HTML"] = "导出会话为 HTML", ["View Credits"] = "查看致谢",
["View details"] = "查看详情",
["These options take effect the next time Cobalt launches."] = "这些选项将在下次启动 Cobalt 时生效",
["Cobalt and the open-source projects that make it possible."] = "Cobalt 以及让这一切成为可能的开源项目",
["Cancel"] = "取消", ["Close"] = "关闭", ["Delete"] = "删除", ["Edit"] = "编辑",
["Duplicate"] = "复制一份", ["Save Changes"] = "保存修改", ["Create Filter"] = "创建过滤器",
["Clear Calls"] = "清空调用", ["Nevermind"] = "算了",
["Continue (Hold to Confirm)"] = "继续(长按确认)", ["I understand"] = "我明白了",
["Warning"] = "警告", ["Detection Risk"] = "检测风险", ["Credits"] = "致谢",
["Limited Logging Support"] = "日志支持受限",
["Clear Captured Calls?"] = "清空已捕获调用?",
["This will permanently remove all captured incoming and outgoing calls. This action cannot be undone."] = "这会永久删除所有已捕获的接收与发出调用,无法撤销",
["Delete Call Filter?"] = "删除调用过滤器?",
["This permanently removes the selected call filter."] = "这会永久删除所选的调用过滤器",
["Your executor can't fully support Cobalt's remote logging. Incoming RemoteEvents will still be captured with limited info; outgoing calls and incoming RemoteFunctions won't be logged on this executor."] = "你的注入器无法完全支持 Cobalt 的远程日志。接收方向的 RemoteEvent 仍会被捕获,但信息有限;在此注入器上,发出调用与接收方向的 RemoteFunction 不会被记录",
["Are you sure you want to disable Oth hooks? This is risky and could theoretically lead to getting banned in certain games. Cobalt is not responsible for any bans you may receive. This change takes effect the next time Cobalt launches."] = "确定要关闭 Oth 钩子吗?这有风险,理论上可能导致在某些游戏中被封禁。Cobalt 不对你可能受到的封禁负责。此更改将在下次启动 Cobalt 时生效",
["Are you sure you want to use RakNet hooks? This is risky and could theoretically lead to account bans. Cobalt is not responsible for any bans you may receive. This change takes effect the next time Cobalt launches."] = "确定要使用 RakNet 钩子吗?这有风险,理论上可能导致账号被封。Cobalt 不对你可能受到的封禁负责。此更改将在下次启动 Cobalt 时生效",
["Edit Call Filter"] = "编辑调用过滤器", ["Create Call Filter"] = "创建调用过滤器",
["Choose which remote calls Cobalt should match."] = "选择 Cobalt 需要匹配哪些远程调用",
["This filter contains conflicting conditions."] = "此过滤器包含互相冲突的条件",
["This remote"] = "当前远程", ["Matching remotes"] = "匹配的远程",
["Any direction"] = "任意方向",
["Ignore matching calls"] = "忽略匹配调用", ["Block matching calls"] = "拦截匹配调用",
["Highlight matching calls"] = "高亮匹配调用",
["AND"] = "且", ["OR"] = "或", ["Remote"] = "远程", ["Where"] = "条件",
["Action"] = "动作", ["Add Condition"] = "添加条件", ["Add remote condition"] = "添加远程条件",
["Full path"] = "完整路径", ["Starts with"] = "开头是",
["Ends with"] = "结尾是", ["Type"] = "类型",
["No call filters have been created yet.\\nRight-click a captured call to create one."] = "还没有创建任何调用过滤器。\\n右键一条已捕获的调用即可创建",
["No remotes have been ignored yet."] = "还没有忽略任何远程",
["No remotes have been blocked yet."] = "还没有拦截任何远程",
["Remove All"] = "全部移除", ["Select..."] = "选择...",
["Search for logs..."] = "搜索日志...",
["No plugins installed."] = "未安装插件", ["Waiting for plugins..."] = "等待插件...",
["loaded"] = "已加载", ["errored"] = "出错", ["ERROR"] = "错误",
["Return Data"] = "返回数据", ["Code"] = "代码", ["Function Info"] = "函数信息",
["Origin"] = "来源", ["Remote Path"] = "远程路径", ["Script Path"] = "脚本路径",
["Decompiled Script"] = "反编译脚本", ["Replay"] = "重放",
["Unignore"] = "取消忽略", ["Unblock"] = "取消拦截", ["Clear Logs"] = "清空日志",
["Copy Calling Code"] = "复制调用代码", ["Copy Intercept Code"] = "复制拦截代码",
["Copy Remote Path"] = "复制远程路径", ["Copy Script Path"] = "复制脚本路径",
["Calling Code"] = "调用代码", ["Intercept Code"] = "拦截代码",
["Copied code to clipboard"] = "代码已复制到剪贴板",
["Failed to copy code to clipboard"] = "复制代码失败",
["Copied remote path to clipboard"] = "远程路径已复制",
["Failed to copy remote path to clipboard"] = "复制远程路径失败",
["Copied script path to clipboard"] = "脚本路径已复制",
["Failed to copy script path to clipboard"] = "复制脚本路径失败",
["Copied function info to clipboard"] = "函数信息已复制",
["Failed to copy function info to clipboard"] = "复制函数信息失败",
["Copied decompiled script to clipboard"] = "反编译脚本已复制",
["Failed to copy decompiled script to clipboard"] = "复制反编译脚本失败",
["Failed to decompile script"] = "反编译失败",
["Replaying event..."] = "正在重放事件...",
["Replayed event successfully!"] = "事件重放成功!",
["Failed to replay event"] = "事件重放失败",
["Call filter created"] = "调用过滤器已创建", ["Call filter updated"] = "调用过滤器已更新",
["Call filter duplicated"] = "调用过滤器已复制", ["Call filter deleted"] = "调用过滤器已删除",
["Removed all remotes"] = "已移除全部远程",
["File logging is not enabled"] = "文件日志未启用",
["Successfully enabled file logging"] = "已启用文件日志",
["Successfully disabled file logging"] = "已关闭文件日志",
["Successfully copied session name to clipboard"] = "会话文件名已复制",
["Successfully copied log path to clipboard"] = "日志路径已复制",
["Failed to copy session name"] = "复制会话文件名失败",
["Failed to copy log path"] = "复制日志路径失败",
["Successfully reset remote filtering to default"] = "已恢复默认过滤设置",
["Invalid page number provided!"] = "页码无效!",
["Starting Export..."] = "开始导出...", ["Loading..."] = "加载中...", ["Success!"] = "成功!",
}

for Key in DICT do
	assert(not BLOCK[Key], "Cobalt-ZH: blocked key in dictionary -> " .. tostring(Key))
end

local PLUGIN_SOURCE = [==[
local PluginName = "严格远程代码"
local Prefix = "PluginSettings-" .. PluginName .. "-"

Cobalt.PluginData = {
	Name = PluginName,
	Description = "逐个开关控制 Cobalt 在生成远程调用代码时做哪些二次加工,关掉对应开关即恢复原版行为",
	Author = "CobaltZH",
	Version = "1.1.0",
	Game = "*",
}

local Defaults = {
	StrictRemoteCode = true,
	KeepTableIdentity = true,
	KeepRawNumbers = true,
	DropInvokeWrapping = true,
	MarkUnknownTypes = true,
	ShortInstancePath = true,
	Watermark = false,
}

if Cobalt.Settings[Prefix .. "Ready"] ~= true then
	for Key, Value in pairs(Defaults) do
		Cobalt.Settings[Prefix .. Key] = Value
	end
	Cobalt.Settings[Prefix .. "Ready"] = true
end

local Flags = {}
for Key in pairs(Defaults) do
	Flags[Key] = Cobalt.Settings[Prefix .. Key] == true
end

local Section = Cobalt.UI:CreatePluginSettings()

for _, Option in ipairs({
	{ Key = "StrictRemoteCode", Text = "禁止Cobalt二改远程事件代码(总开关)", Default = true },
	{ Key = "KeepTableIdentity", Text = "保留表引用(同一张表只生成一份)", Default = true },
	{ Key = "KeepRawNumbers", Text = "数字按原始写法输出", Default = true },
	{ Key = "DropInvokeWrapping", Text = "去掉 pcall 与返回值包装", Default = true },
	{ Key = "MarkUnknownTypes", Text = "未知类型输出占位注释", Default = true },
	{ Key = "ShortInstancePath", Text = "实例路径用最短写法", Default = true },
	{ Key = "Watermark", Text = "添加水印(中文)", Default = false },
}) do
	Section:CreateCheckbox(Option.Key, {
		Text = Option.Text,
		Default = Option.Default,
		Callback = function(Value)
			Flags[Option.Key] = Value
		end,
	})
end

local ClassInfo = {
	RemoteEvent = { Out = "FireServer", In = "OnClientEvent", Kind = "Signal" },
	UnreliableRemoteEvent = { Out = "FireServer", In = "OnClientEvent", Kind = "Signal" },
	BindableEvent = { Out = "Fire", In = "Event", Kind = "Signal" },
	RemoteFunction = { Out = "InvokeServer", In = "OnClientInvoke", Kind = "Callback" },
	BindableFunction = { Out = "Invoke", In = "OnInvoke", Kind = "Callback" },
}

local function Build(CallInfo)
	local Info = ClassInfo[CallInfo.Instance.ClassName]
	if not Info then
		return nil
	end

	local function Unknown(Kind)
		if Flags.MarkUnknownTypes then
			return string.format("nil --[[ %s ]]", Kind)
		end
		return "nil"
	end

	local function Number(Value)
		if Value ~= Value then
			return "(0/0)"
		end
		if Value == math.huge then
			return "math.huge"
		end
		if Value == -math.huge then
			return "-math.huge"
		end

		if not Flags.KeepRawNumbers then
			return string.format("%.17g", Value)
		end

		if Value % 1 == 0 and math.abs(Value) < 9007199254740992 then
			return string.format("%d", Value)
		end

		for Precision = 1, 17 do
			local Candidate = string.format("%." .. Precision .. "g", Value)
			if tonumber(Candidate) == Value then
				return Candidate
			end
		end

		return string.format("%.17g", Value)
	end

	local function Text(Value)
		local Out = Value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
		Out = Out:gsub("[%c]", function(Char)
			return string.format("\\%d", string.byte(Char))
		end)
		return '"' .. Out .. '"'
	end

	local function Field(Name)
		if Flags.ShortInstancePath and Name:match("^[%a_][%w_]*$") then
			return "." .. Name
		end
		return string.format(":FindFirstChild(%s)", Text(Name))
	end

	local function Path(Obj)
		if Obj == game then
			return "game"
		end

		local Parts = {}
		local Current = Obj

		while Current do
			if Current == game then
				table.insert(Parts, 1, "game")
				return table.concat(Parts)
			elseif Current == workspace then
				table.insert(Parts, 1, "workspace")
				return table.concat(Parts)
			end

			local Parent = Current.Parent
			if not Parent then
				return nil
			end

			if Parent == game then
				local Service
				pcall(function()
					Service = game:GetService(Current.ClassName)
				end)
				if Service == Current then
					table.insert(Parts, 1, string.format('game:GetService("%s")', Current.ClassName))
				else
					table.insert(Parts, 1, string.format("game:FindFirstChild(%s)", Text(Current.Name)))
				end
				return table.concat(Parts)
			end

			if Current.ClassName == "Player" and Parent.ClassName == "Players" then
				table.insert(Parts, 1, 'game:GetService("Players").LocalPlayer')
				return table.concat(Parts)
			end

			table.insert(Parts, 1, Field(Current.Name))
			Current = Parent
		end

		return nil
	end

	local Names = {}
	local Order = {}
	local Total = 0

	local function Name(Value)
		Total = Total + 1
		local NewName = "A" .. Total
		Names[Value] = NewName
		Order[#Order + 1] = Value
		return NewName
	end

	local function List(Values)
		local Parts = {}
		for Index = 1, #Values do
			Parts[Index] = Number(Values[Index])
		end
		return table.concat(Parts, ", ")
	end

	local Expr

	Expr = function(Value)
		local Kind = typeof(Value)

		if Kind == "nil" then
			return "nil"
		elseif Kind == "boolean" then
			return Value and "true" or "false"
		elseif Kind == "number" then
			return Number(Value)
		elseif Kind == "string" then
			return Text(Value)
		elseif Kind == "table" then
			local Existing = Names[Value]
			if Existing then
				if Flags.KeepTableIdentity then
					return Existing
				end
				return "{}"
			end
			return Name(Value)
		elseif Kind == "Instance" then
			local InstancePath = Path(Value)
			if InstancePath then
				return InstancePath
			end
			return Unknown(Value.ClassName)
		elseif Kind == "Vector2" then
			return string.format("Vector2.new(%s)", List({ Value.X, Value.Y }))
		elseif Kind == "Vector3" then
			return string.format("Vector3.new(%s)", List({ Value.X, Value.Y, Value.Z }))
		elseif Kind == "Vector2int16" then
			return string.format("Vector2int16.new(%s)", List({ Value.X, Value.Y }))
		elseif Kind == "Vector3int16" then
			return string.format("Vector3int16.new(%s)", List({ Value.X, Value.Y, Value.Z }))
		elseif Kind == "Color3" then
			return string.format("Color3.new(%s)", List({ Value.R, Value.G, Value.B }))
		elseif Kind == "UDim" then
			return string.format("UDim.new(%s)", List({ Value.Scale, Value.Offset }))
		elseif Kind == "UDim2" then
			return string.format(
				"UDim2.new(%s)",
				List({ Value.X.Scale, Value.X.Offset, Value.Y.Scale, Value.Y.Offset })
			)
		elseif Kind == "CFrame" then
			local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Value:GetComponents()
			return string.format("CFrame.new(%s)", List({ X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 }))
		elseif Kind == "Rect" then
			return string.format("Rect.new(%s)", List({ Value.Min.X, Value.Min.Y, Value.Max.X, Value.Max.Y }))
		elseif Kind == "Ray" then
			return string.format(
				"Ray.new(%s)",
				List({
					Value.Origin.X, Value.Origin.Y, Value.Origin.Z,
					Value.Direction.X, Value.Direction.Y, Value.Direction.Z,
				})
			)
		elseif Kind == "NumberRange" then
			return string.format("NumberRange.new(%s)", List({ Value.Min, Value.Max }))
		elseif Kind == "NumberSequence" then
			local Parts = {}
			for _, Point in ipairs(Value.Keypoints) do
				Parts[#Parts + 1] = string.format(
					"NumberSequenceKeypoint.new(%s)",
					List({ Point.Time, Point.Value, Point.Envelope })
				)
			end
			return string.format("NumberSequence.new({ %s })", table.concat(Parts, ", "))
		elseif Kind == "ColorSequence" then
			local Parts = {}
			for _, Point in ipairs(Value.Keypoints) do
				Parts[#Parts + 1] = string.format(
					"ColorSequenceKeypoint.new(%s, Color3.new(%s))",
					Number(Point.Time),
					List({ Point.Value.R, Point.Value.G, Point.Value.B })
				)
			end
			return string.format("ColorSequence.new({ %s })", table.concat(Parts, ", "))
		elseif Kind == "TweenInfo" then
			return string.format(
				"TweenInfo.new(%s, %s, %s, %s, %s, %s)",
				Number(Value.Time),
				tostring(Value.EasingStyle),
				tostring(Value.EasingDirection),
				Number(Value.RepeatCount),
				tostring(Value.Reverses),
				Number(Value.DelayTime)
			)
		elseif Kind == "Font" then
			return string.format("Font.new(%s, %s, %s)", Text(Value.Family), tostring(Value.Weight), tostring(Value.Style))
		elseif Kind == "DateTime" then
			return string.format("DateTime.fromUnixTimestamp(%s)", Number(Value.UnixTimestamp))
		elseif Kind == "BrickColor" then
			return string.format("BrickColor.new(%s)", Text(Value.Name))
		elseif Kind == "EnumItem" then
			return tostring(Value)
		elseif Kind == "buffer" then
			return string.format("buffer.fromstring(%s)", Text(buffer.tostring(Value)))
		end

		return Unknown(Kind)
	end

	local Args = CallInfo.Arguments or {}
	local ArgCount = Args.n or #Args
	local ArgExprs = {}

	for Index = 1, ArgCount do
		ArgExprs[Index] = Expr(Args[Index])
	end

	local Fill = {}
	local Cursor = 1

	while Cursor <= #Order do
		local Value = Order[Cursor]
		local Target = Names[Value]
		local ArrayCount = #Value

		for Index = 1, ArrayCount do
			Fill[#Fill + 1] = string.format("%s[%d] = %s", Target, Index, Expr(Value[Index]))
		end

		for Key, Child in pairs(Value) do
			local Skip = false
			if type(Key) == "number" and Key >= 1 and Key <= ArrayCount and Key % 1 == 0 then
				Skip = true
			elseif Key == "n" and type(Child) == "number" then
				Skip = true
			end

			if not Skip then
				local KeyExpr
				if type(Key) == "string" and Key:match("^[%a_][%w_]*$") then
					KeyExpr = Target .. "." .. Key
				elseif type(Key) == "string" then
					KeyExpr = Target .. "[" .. Text(Key) .. "]"
				elseif type(Key) == "number" then
					KeyExpr = Target .. "[" .. Number(Key) .. "]"
				elseif typeof(Key) == "Instance" then
					KeyExpr = Target .. "[" .. Expr(Key) .. "]"
				end

				if KeyExpr then
					Fill[#Fill + 1] = string.format("%s = %s", KeyExpr, Expr(Child))
				end
			end
		end

		Cursor = Cursor + 1
	end

	local Lines = {}

	if Flags.Watermark then
		local SafeName = CallInfo.Instance.Name:gsub("[\r\n]", " ")
		Lines[#Lines + 1] = "-- 本代码由 Cobalt 汉化版自动生成"
		Lines[#Lines + 1] = string.format(
			"-- 远程: %s · 方向: %s",
			SafeName,
			CallInfo.Type == "Incoming" and "接收" or "发出"
		)
		Lines[#Lines + 1] = "-- https://gitlab.com/upio/cobalt"
		Lines[#Lines + 1] = ""
	end

	local EventPath = Path(CallInfo.Instance)
	if EventPath then
		Lines[#Lines + 1] = "local Event = " .. EventPath
	else
		Lines[#Lines + 1] = string.format("local Event = %s", Unknown(CallInfo.Instance.ClassName))
	end

	for Index = 1, #Order do
		Lines[#Lines + 1] = string.format("local A%d = {}", Index)
	end

	for _, Line in ipairs(Fill) do
		Lines[#Lines + 1] = Line
	end

	local ArgText = table.concat(ArgExprs, ", ")
	local Wrapper = Flags.DropInvokeWrapping and "%s" or "local Result = table.pack(%s)"

	if CallInfo.Type == "Incoming" then
		if Info.Kind == "Signal" then
			Lines[#Lines + 1] = string.format(
				"firesignal(Event.%s%s%s)",
				Info.In,
				ArgText ~= "" and ", " or "",
				ArgText
			)
		elseif CallInfo.InvokeKind == "Callback" then
			Lines[#Lines + 1] = string.format('local Callback = getcallbackvalue(Event, "%s")', Info.In)
			Lines[#Lines + 1] = string.format(Wrapper, string.format("Callback(%s)", ArgText))
		else
			Lines[#Lines + 1] = string.format(Wrapper, string.format("Event:%s(%s)", Info.Out, ArgText))
		end
	else
		Lines[#Lines + 1] = string.format(Wrapper, string.format("Event:%s(%s)", Info.Out, ArgText))
	end

	return table.concat(Lines, "\n")
end

Cobalt.CodeGen:InterceptGeneration("Call", function(CallInfo)
	if not Flags.StrictRemoteCode then
		return nil
	end

	local Success, Code = pcall(Build, CallInfo)
	if Success and type(Code) == "string" then
		return Code
	end

	return nil
end)
]==]

local function InstallPlugin()
	if type(writefile) ~= "function" or type(isfolder) ~= "function" or type(makefolder) ~= "function" then
		return false, "executor has no filesystem support"
	end

	if not isfolder("Cobalt") then
		makefolder("Cobalt")
	end
	if not isfolder("Cobalt/Plugins") then
		makefolder("Cobalt/Plugins")
	end

	local Success, Error = pcall(writefile, PLUGIN_PATH, PLUGIN_SOURCE)
	if not Success then
		return false, tostring(Error)
	end

	return true
end

local function Fetch(Url)
	local Ok, Body = pcall(function()
		return game:HttpGet(Url)
	end)
	if Ok and type(Body) == "string" and #Body > 0 then
		return Body
	end
	local Candidates = { request, http_request }
	if syn and syn.request then
		table.insert(Candidates, syn.request)
	end
	for _, Fn in ipairs(Candidates) do
		if type(Fn) == "function" then
			local Good, Response = pcall(Fn, { Url = Url, Method = "GET" })
			if Good and type(Response) == "table" and type(Response.Body) == "string" and #Response.Body > 0 then
				return Response.Body
			end
		end
	end
	error("Cobalt-ZH: download failed")
end

local function Lookup(Body)
	if BLOCK[Body] then
		return nil
	end
	return DICT[Body]
end

local function Patch(Text)
	local n = #Text
	local out = {}
	local i = 1
	local Hits = 0

	while i <= n do
		local c = Text:sub(i, i)

		if c == "-" and Text:sub(i + 1, i + 1) == "-" then
			local eq = Text:match("^%-%-%[(=*)%[", i)
			if eq then
				local close = "]" .. eq .. "]"
				local e = Text:find(close, i, true)
				if not e then
					out[#out + 1] = Text:sub(i)
					break
				end
				out[#out + 1] = Text:sub(i, e + #close - 1)
				i = e + #close
			else
				local e = Text:find("\n", i, true) or n + 1
				out[#out + 1] = Text:sub(i, e - 1)
				i = e
			end

		elseif c == "`" then
			local j = i + 1
			local depth = 0
			while j <= n do
				local ch = Text:sub(j, j)
				if ch == "\\" then
					j = j + 2
				elseif ch == "{" then
					if Text:sub(j + 1, j + 1) == "{" then
						j = j + 2
					else
						depth = depth + 1
						j = j + 1
					end
				elseif ch == "}" then
					if depth > 0 then
						depth = depth - 1
						j = j + 1
					elseif Text:sub(j + 1, j + 1) == "}" then
						j = j + 2
					else
						j = j + 1
					end
				elseif ch == "`" and depth == 0 then
					break
				else
					j = j + 1
				end
			end
			out[#out + 1] = Text:sub(i, j)
			i = j + 1

		elseif c == '"' or c == "'" then
			local j = i + 1
			local buf = {}
			local closed = false
			while j <= n do
				local ch = Text:sub(j, j)
				if ch == "\\" then
					buf[#buf + 1] = Text:sub(j, j + 1)
					j = j + 2
				elseif ch == c then
					closed = true
					break
				elseif ch == "\n" then
					break
				else
					buf[#buf + 1] = ch
					j = j + 1
				end
			end
			if not closed then
				out[#out + 1] = Text:sub(i, j - 1)
				i = j
			else
				local body = table.concat(buf)
				local v = Lookup(body)
				if v then
					Hits = Hits + 1
					v = v:gsub("\\", "\\\\"):gsub(c, "\\" .. c)
					out[#out + 1] = c .. v .. c
				else
					out[#out + 1] = c .. body .. c
				end
				i = j + 1
			end

		elseif Text:match("^%[(=*)%[", i) then
			local eq = Text:match("^%[(=*)%[", i)
			local close = "]" .. eq .. "]"
			local start = i + #eq + 2
			local e = Text:find(close, start, true)
			if not e then
				out[#out + 1] = Text:sub(i)
				break
			end
			local body = Text:sub(start, e - 1)
			local v = Lookup(body)
			if v then
				Hits = Hits + 1
				out[#out + 1] = "[" .. eq .. "[" .. v .. "]" .. eq .. "]"
			else
				out[#out + 1] = Text:sub(i, e + #close - 1)
			end
			i = e + #close

		else
			out[#out + 1] = c
			i = i + 1
		end
	end

	return table.concat(out), Hits
end

local Installed, InstallError = InstallPlugin()
if not Installed then
	warn("Cobalt-ZH: plugin not installed -> " .. tostring(InstallError))
end

local Src = Fetch(URL)
local DataStart = Src:find("local ObjectTree = {", 1, true)
local DataEnd = Src:find("local LineOffsets = {", 1, true)
assert(DataStart and DataEnd and DataEnd > DataStart, "Cobalt-ZH: layout markers not found")

local Head, HeadHits = Patch(Src:sub(1, DataStart - 1))
local Data = Src:sub(DataStart, DataEnd - 1)
local Tail, TailHits = Patch(Src:sub(DataEnd))

local Result = Head .. Data .. Tail
local Chunk, Err = loadstring(Result, "=Cobalt.zh")
assert(Chunk, "Cobalt-ZH: patch invalid -> " .. tostring(Err))

print(string.format("[Cobalt-ZH] %d strings replaced, running", HeadHits + TailHits))
Chunk()

pcall(function()
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCore("SendNotification", {
		Title = "Cobalt-ZH",
		Text = "译者: GaoLaoBa",
		Duration = 10,
	})
end)