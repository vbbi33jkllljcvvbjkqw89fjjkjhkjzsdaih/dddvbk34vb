
--[[
	oxy Animation Logger
	Version: 2.1.1
	
	Changelog (2.1.1):
	- Added loading UI with animated progress bar that expands into main UI
	- Fixed ~5 second game freeze by deferring entity tracking with batch processing
	- File cache now enabled by default for faster subsequent loads
	- Fixed grid floor not showing on preview window open
	- Migrated all IB_* macros to LPH_* (Luraph compatibility)
	
	Previous (2.0.1):
	- Added caching for animation name lookups and full path lookups
	- Fixed constant lag
]]


local table_insert = table.insert
local table_concat = table.concat
local string_match = string.match
local string_gsub = string.gsub
local string_sub = string.sub
local tostring = tostring
local tonumber = tonumber
local typeof = typeof
local pcall = pcall
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type


if not LPH_OBFUSCATED then
	LPH_OBFUSCATED = false
	LPH_LINE = 0
	LPH_CRASH = function() return end
	LPH_JIT = function(f) return f end
	LPH_JIT_MAX = function(f) return f end
	LPH_NO_VIRTUALIZE = function(f) return f end
	LPH_NO_UPVALUES = function(f) return f end
	LPH_ENCSTR = function(s) return s end
	LPH_STRENC = function(s) return s end
	LPH_ENCNUM = function(n) return n end
	LPH_NUMENC = function(n) return n end
	LPH_ENCFUNC = function(f, _, _) return f end
	LPH_FUNCENC = function(f, _, _) return f end
end

local cloneref = (cloneref or clonereference or function(instance: any)
	return instance
end)


local Players, CoreGui, TweenService, RunService, Workspace, ReplicatedStorage, MarketplaceService, HttpService, UserInputService, TextService, StarterGui, LocalPlayer

do
	Players = cloneref(game:GetService("Players"))
	CoreGui = cloneref(game:GetService("CoreGui"))
	TweenService = cloneref(game:GetService("TweenService"))
	RunService = cloneref(game:GetService("RunService"))
	Workspace = cloneref(game:GetService("Workspace"))
	ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
	MarketplaceService = cloneref(game:GetService("MarketplaceService"))
	HttpService = cloneref(game:GetService("HttpService"))
	UserInputService = cloneref(game:GetService("UserInputService"))
	TextService = cloneref(game:GetService("TextService"))
	StarterGui = cloneref(game:GetService("StarterGui"))
	LocalPlayer = Players.LocalPlayer
end


local hasFileSystem = (writefile and readfile and isfile) and true or false
local CACHE_FOLDER = "oxyAnimationLogger"
local CACHE_FILE = CACHE_FOLDER .. "/animation_cache.json"
local isFileCacheEnabled = hasFileSystem 
local fileCacheData = {}
local ignoredParents = {} 
local ignoredPlayers = {} 
local NPC_PROFILE_USER_ID = 10297255849 

local Colors = {
	FontColor = Color3.fromRGB(216, 222, 233),
	MainColor = Color3.fromRGB(27, 43, 52),
	BackgroundColor = Color3.fromRGB(32, 34, 36),
	AccentColor = Color3.fromRGB(102, 153, 204),
	OutlineColor = Color3.fromRGB(52, 61, 70),
	DisabledTextColor = Color3.fromRGB(150, 160, 170),
	Black = Color3.fromRGB(0, 0, 0),
	PlayerNameColor = Color3.fromRGB(102, 153, 204),
	NPCNameColor = Color3.fromRGB(200, 205, 212),
}

local Font = Enum.Font.Code

local function GetDarkerColor(color)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, v * 0.8)
end

-- Credits to cobalt for Lucide asset fetching
local Icons = {}
do
	local Success, IconsModule = pcall(function()
		local IconFetchSuccess, IconModuleSource = pcall(request or http_request or (syn and syn.request) or function()
			return { Success = false }
		end, {
			Url = "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua",
			Method = "GET",
		})

		if not (IconFetchSuccess and (IconModuleSource.Success or (IconModuleSource.StatusCode and IconModuleSource.StatusCode >= 200 and IconModuleSource.StatusCode < 300))) then
			return nil
		end
		return loadstring(IconModuleSource.Body)()
	end)
	
	function Icons.GetIcon(iconName)
		if not Success or not IconsModule then
			return nil
		end
		
		local ok, icon = pcall(IconsModule.GetAsset, iconName)
		if not ok then
			return nil
		end
		
		return icon
	end
	
	function Icons.SetIcon(imageInstance, iconName)
		local icon = Icons.GetIcon(iconName)
		if not icon then
			return false
		end
		
		imageInstance.Image = icon.Url
		imageInstance.ImageRectOffset = icon.ImageRectOffset
		imageInstance.ImageRectSize = icon.ImageRectSize
		return true
	end
end


local NUMERIC_PATTERN = "%d+"


local function getNumericId(animationId)
	return string_match(tostring(animationId), NUMERIC_PATTERN)
end
local animationNameCache = {}

local function CreateIcon(parent, iconName, size, position, addHover)
	if addHover == nil then
		addHover = parent:IsA("TextButton") or parent:IsA("ImageButton")
	end
	
	local icon
	local iconSize = size or 16
	local iconPosition = position or UDim2.new(0, 0, 0, 0)
	
	
	local lucideName = string_gsub(iconName, "%-", "_")
	local iconAsset = Icons.GetIcon(lucideName)
	
	if iconAsset then
		icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, iconSize, 0, iconSize)
		icon.Position = iconPosition
		icon.BackgroundTransparency = 1
		icon.Image = iconAsset.Url
		icon.ImageRectSize = iconAsset.ImageRectSize
		icon.ImageRectOffset = iconAsset.ImageRectOffset
		icon.ImageColor3 = Colors.FontColor
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = parent.ZIndex + 1
		icon.Parent = parent
	else
		
		local iconMap = {
			["play-circle"] = "▶", ["settings"] = "⚙", ["minus"] = "–", ["maximize-2"] = "+",
			["x"] = "✕", ["trash-2"] = "🗑", ["play"] = "▶", ["pause"] = "⏸", ["copy"] = "📋",
			["square"] = "■", ["stop-circle"] = "■", ["repeat"] = "🔁", ["repeat-1"] = "🔁",
			["rotate-ccw"] = "↺", ["home"] = "⌂", ["step-back"] = "◀|", ["step-forward"] = "|▶",
			["plus"] = "+", ["download"] = "⬇", ["flag"] = "🚩", ["chevron-left"] = "◀",
			["chevron-right"] = "▶", ["users"] = "👥", ["user"] = "👤", ["eye"] = "👁"
		}
		
		icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, iconSize, 0, iconSize)
		icon.Position = iconPosition
		icon.BackgroundTransparency = 1
		icon.Text = iconMap[iconName] or "?"
		icon.TextColor3 = Colors.FontColor
		icon.TextSize = iconSize - 2
		icon.Font = Font
		icon.TextStrokeTransparency = 0
		icon.ZIndex = parent.ZIndex + 1
		icon.Parent = parent
	end
	
	
	if addHover and icon then
		parent.MouseEnter:Connect(function()
			if icon:IsA("ImageLabel") then
				icon.ImageColor3 = Colors.AccentColor
			else
				icon.TextColor3 = Colors.AccentColor
			end
		end)
		parent.MouseLeave:Connect(function()
			if icon:IsA("ImageLabel") then
				icon.ImageColor3 = Colors.FontColor
			else
				icon.TextColor3 = Colors.FontColor
			end
		end)
	end
	
	return icon
end

local function findAnimationName(animationId)
	local numericId = getNumericId(animationId)
	if not numericId then return nil, nil, nil end
	
	
	local cached = animationNameCache[numericId]
	if cached then
		return cached.name, cached.parent, cached.location
	end
	
	local searchLocations = {Workspace, ReplicatedStorage}
	local locationNames = {[Workspace] = "Workspace", [ReplicatedStorage] = "ReplicatedStorage"}
	
	for _, location in searchLocations do
		for _, desc in location:GetDescendants() do
			if desc:IsA("Animation") then
				local descId = string_match(tostring(desc.AnimationId), NUMERIC_PATTERN)
				if descId == numericId then
					local descName = desc.Name
					if descName and descName ~= "" and descName ~= "Animation" then
						local parentName = nil
						local descParent = desc.Parent
						if descParent and descParent ~= location then
							parentName = descParent.Name
						end
						
						animationNameCache[numericId] = {name = descName, parent = parentName, location = locationNames[location]}
						
						if isFileCacheEnabled then
							task.defer(saveFileCache)
						end
						return descName, parentName, locationNames[location]
					end
				end
			end
		end
	end
	
	
	animationNameCache[numericId] = {name = nil, parent = nil, location = nil}
	return nil, nil, nil
end


local marketplaceNameCache = {}

local function fetchAnimationNameFromAsset(animationId)
	local numericId = getNumericId(animationId)
	if not numericId then return nil end
	
	
	if marketplaceNameCache[numericId] ~= nil then
		return marketplaceNameCache[numericId]
	end
	
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(tonumber(numericId))
	end)
	
	if success and info and info.Name and info.Name ~= "" then
		marketplaceNameCache[numericId] = info.Name
		
		if isFileCacheEnabled then
			task.defer(saveFileCache)
		end
		return info.Name
	else
		marketplaceNameCache[numericId] = false 
		return nil
	end
end


local function loadFileCache()
	if not hasFileSystem or not isFileCacheEnabled then return end
	
	local success, result = pcall(function()
		if not isfolder(CACHE_FOLDER) then
			makefolder(CACHE_FOLDER)
			return {}
		end
		if not isfile(CACHE_FILE) then
			return {}
		end
		return HttpService:JSONDecode(readfile(CACHE_FILE))
	end)
	
	if success and result then
		fileCacheData = result
		
		local animations = fileCacheData.animations
		if animations then
			for id, data in animations do
				if not animationNameCache[id] then
					animationNameCache[id] = data
				end
			end
		end
		local marketplace = fileCacheData.marketplace
		if marketplace then
			for id, name in marketplace do
				if marketplaceNameCache[id] == nil then
					marketplaceNameCache[id] = name
				end
			end
		end
	end
end

local function saveFileCache()
	if not hasFileSystem or not isFileCacheEnabled then return end
	
	pcall(function()
		if not isfolder(CACHE_FOLDER) then
			makefolder(CACHE_FOLDER)
		end
		
		local cacheToSave = {
			animations = animationNameCache,
			marketplace = {},
			version = 1
		}
		
		
		for id, name in marketplaceNameCache do
			if name and name ~= false then
				cacheToSave.marketplace[id] = name
			end
		end
		
		writefile(CACHE_FILE, HttpService:JSONEncode(cacheToSave))
	end)
end

local function clearFileCache()
	if not hasFileSystem then return false end
	
	local success = pcall(function()
		if isfile(CACHE_FILE) then
			delfile(CACHE_FILE)
		end
		
		animationNameCache = {}
		marketplaceNameCache = {}
		fileCacheData = {}
	end)
	
	return success
end


if hasFileSystem and isFileCacheEnabled then
	loadFileCache()
end


local animationPathCache = {}

local function getAnimationFullPath(animationId)
	local numericId = getNumericId(animationId)
	if not numericId then return nil end
	
	
	local cached = animationPathCache[numericId]
	if cached then
		return cached
	end
	
	local searchLocations = {Workspace, ReplicatedStorage}
	local locationNames = {[Workspace] = "Workspace", [ReplicatedStorage] = "ReplicatedStorage"}
	
	for _, location in searchLocations do
		for _, desc in location:GetDescendants() do
			if desc:IsA("Animation") then
				local descId = string_match(tostring(desc.AnimationId), NUMERIC_PATTERN)
				if descId == numericId then
					
					local pathParts = {}
					local current = desc
					local partCount = 0
					
					while current and current ~= location do
						partCount += 1
						pathParts[partCount] = current.Name
						current = current.Parent
					end
					
					
					local reversed = table.create(partCount)
					for i = partCount, 1, -1 do
						reversed[partCount - i + 1] = pathParts[i]
					end
					
					local fullPath = locationNames[location] .. "." .. table_concat(reversed, ".")
					animationPathCache[numericId] = fullPath
					return fullPath
				end
			end
		end
	end
	
	animationPathCache[numericId] = nil
	return nil
end




-- oxy perf: index every Animation once (kills per-id descendant scans = the lag)
task.spawn(function()
	local locs = { { Workspace, "Workspace" }, { ReplicatedStorage, "ReplicatedStorage" } }
	local processed = 0
	for _, pair in ipairs(locs) do
		local loc, locName = pair[1], pair[2]
		for _, desc in ipairs(loc:GetDescendants()) do
			if desc:IsA("Animation") then
				local nid = getNumericId(desc.AnimationId)
				if nid then
					if animationNameCache[nid] == nil then
						local nm = desc.Name
						local parentName
						if desc.Parent and desc.Parent ~= loc then parentName = desc.Parent.Name end
						if nm and nm ~= "" and nm ~= "Animation" then
							animationNameCache[nid] = { name = nm, parent = parentName, location = locName }
						end
					end
					if animationPathCache[nid] == nil then
						local parts, cur, c = {}, desc, 0
						while cur and cur ~= loc do c += 1; parts[c] = cur.Name; cur = cur.Parent end
						local rev = {}
						for i = c, 1, -1 do rev[#rev + 1] = parts[i] end
						animationPathCache[nid] = locName .. "." .. table_concat(rev, ".")
					end
				end
			end
			processed += 1
			if processed % 4000 == 0 then task.wait() end
		end
	end
end)

local function getConsistentAnimName(baseName, parentName, includeParent)
	local name = baseName or "Unknown"
	name = string_gsub(name, "%s+", "") 
	
	if includeParent and parentName then
		local cleanParent = string_gsub(parentName, "%s+", "")
		return cleanParent .. name 
	end
	
	return name
end

local OXY_IDENTIFIER = LPH_ENCSTR("oxyAnimationLogger_Instance")

if _G[OXY_IDENTIFIER] then
	local oldData = _G[OXY_IDENTIFIER]
	
	
	if oldData.Connections then
		for _, connection in oldData.Connections do
			if typeof(connection) == "RBXScriptConnection" then
				pcall(function() connection:Disconnect() end)
			end
		end
	end
	
	
	if oldData.ScreenGui and oldData.ScreenGui.Parent then
		pcall(function() oldData.ScreenGui:Destroy() end)
	end
	
	_G[OXY_IDENTIFIER] = nil
end


for _, child in CoreGui:GetChildren() do
	if child:IsA("ScreenGui") and child.Name == LPH_ENCSTR("oxyAnimationLogger") then
		pcall(function() child:Destroy() end)
	end
end


local ActiveConnections = {}
local connectionCount = 0

local function TrackConnection(connection)
	connectionCount += 1
	ActiveConnections[connectionCount] = connection
	return connection
end


local NotificationArea = nil
local notificationCount = 0

local function SetupNotificationArea()
	if NotificationArea then return end
	
	NotificationArea = Instance.new("Frame")
	NotificationArea.Name = "NotificationArea"
	NotificationArea.BackgroundTransparency = 1
	NotificationArea.Position = UDim2.new(1, -310, 0, 40)
	NotificationArea.Size = UDim2.new(0, 300, 1, -80)
	NotificationArea.ZIndex = 500
	NotificationArea.Parent = CoreGui:WaitForChild("oxyAnimationLogger", 5) or CoreGui
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = NotificationArea
end

local function Notify(title, text, duration)
	task.spawn(function()
		SetupNotificationArea()
		
		local displayText = title and title ~= "" and ("[" .. title .. "] " .. (text or "")) or (text or "")
		local textBounds = TextService:GetTextSize(displayText, 14, Font, Vector2.new(280, 1000))
		local ySize = textBounds.Y + 10
		
		notificationCount += 1
		local order = notificationCount
		
		
		local notifyOuter = Instance.new("Frame")
		notifyOuter.Name = "Notification"
		notifyOuter.BackgroundColor3 = Colors.Black
		notifyOuter.BorderSizePixel = 0
		notifyOuter.Size = UDim2.new(0, 0, 0, ySize)
		notifyOuter.ClipsDescendants = true
		notifyOuter.ZIndex = 500
		notifyOuter.LayoutOrder = order
		notifyOuter.Parent = NotificationArea
		
		
		local notifyInner = Instance.new("Frame")
		notifyInner.BackgroundColor3 = Colors.MainColor
		notifyInner.BorderColor3 = Colors.OutlineColor
		notifyInner.BorderMode = Enum.BorderMode.Inset
		notifyInner.Size = UDim2.new(1, 0, 1, 0)
		notifyInner.ZIndex = 501
		notifyInner.Parent = notifyOuter
		
		local innerFrame = Instance.new("Frame")
		innerFrame.BackgroundColor3 = Colors.MainColor
		innerFrame.BorderSizePixel = 0
		innerFrame.Position = UDim2.new(0, 1, 0, 1)
		innerFrame.Size = UDim2.new(1, -2, 1, -2)
		innerFrame.ZIndex = 502
		innerFrame.Parent = notifyInner
		
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, GetDarkerColor(Colors.MainColor)),
			ColorSequenceKeypoint.new(1, Colors.MainColor)
		})
		gradient.Rotation = -90
		gradient.Parent = innerFrame
		
		
		local accentBar = Instance.new("Frame")
		accentBar.BackgroundColor3 = Colors.AccentColor
		accentBar.BorderSizePixel = 0
		accentBar.Position = UDim2.new(0, 0, 0, 0)
		accentBar.Size = UDim2.new(0, 3, 1, 0)
		accentBar.ZIndex = 504
		accentBar.Parent = notifyOuter
		
		
		local notifyLabel = Instance.new("TextLabel")
		notifyLabel.BackgroundTransparency = 1
		notifyLabel.Position = UDim2.new(0, 8, 0, 0)
		notifyLabel.Size = UDim2.new(1, -12, 1, 0)
		notifyLabel.Font = Font
		notifyLabel.Text = displayText
		notifyLabel.TextColor3 = Colors.FontColor
		notifyLabel.TextSize = 14
		notifyLabel.TextStrokeTransparency = 0
		notifyLabel.TextXAlignment = Enum.TextXAlignment.Left
		notifyLabel.TextWrapped = true
		notifyLabel.ZIndex = 503
		notifyLabel.Parent = innerFrame
		
		
		local targetWidth = textBounds.X + 20
		TweenService:Create(notifyOuter, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, targetWidth, 0, ySize)
		}):Play()
		
		
		task.wait(duration or 3)
		
		TweenService:Create(notifyOuter, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 0, 0, ySize)
		}):Play()
		
		task.wait(0.35)
		notifyOuter:Destroy()
	end)
end


local function ReplaceIcon(parent, newIconName, size, position)
	for _, child in parent:GetChildren() do
		if (child:IsA("ImageLabel") or child:IsA("TextLabel")) and child.Position == position then
			child:Destroy()
			break
		end
	end
	return CreateIcon(parent, newIconName, size, position)
end


local function CreateFrame(props)
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Frame"
	frame.BackgroundColor3 = props.BackgroundColor3 or Colors.MainColor
	frame.BorderColor3 = props.BorderColor3 or Colors.OutlineColor
	frame.BorderSizePixel = props.BorderSizePixel or 1
	frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
	frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
	frame.ZIndex = props.ZIndex or 1
	frame.BackgroundTransparency = props.BackgroundTransparency or 0
	frame.Visible = props.Visible ~= false
	if props.Parent then frame.Parent = props.Parent end
	return frame
end

local function CreateTextLabel(props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.BackgroundTransparency = props.BackgroundTransparency or 1
	label.BackgroundColor3 = props.BackgroundColor3 or Colors.MainColor
	label.BorderSizePixel = props.BorderSizePixel or 0
	label.Position = props.Position or UDim2.new(0, 0, 0, 0)
	label.Size = props.Size or UDim2.new(1, 0, 1, 0)
	label.ZIndex = props.ZIndex or 1
	label.Font = props.Font or Font
	label.Text = props.Text or ""
	label.TextColor3 = props.TextColor3 or Colors.FontColor
	label.TextSize = props.TextSize or 14
	label.TextStrokeTransparency = props.TextStrokeTransparency or 0
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	label.TextWrapped = props.TextWrapped or false
	label.TextTruncate = props.TextTruncate or Enum.TextTruncate.None
	if props.Parent then label.Parent = props.Parent end
	return label
end

local function CreateTextButton(props)
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.BackgroundColor3 = props.BackgroundColor3 or Colors.MainColor
	button.BorderColor3 = props.BorderColor3 or Colors.OutlineColor
	button.BackgroundTransparency = props.BackgroundTransparency or 0
	button.Position = props.Position or UDim2.new(0, 0, 0, 0)
	button.Size = props.Size or UDim2.new(0, 100, 0, 24)
	button.ZIndex = props.ZIndex or 1
	button.Font = props.Font or Font
	button.Text = props.Text or ""
	button.TextColor3 = props.TextColor3 or Colors.FontColor
	button.TextSize = props.TextSize or 14
	button.TextStrokeTransparency = props.TextStrokeTransparency or 0
	button.AutoButtonColor = props.AutoButtonColor or false
	if props.Parent then button.Parent = props.Parent end
	return button
end

local function CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 4)
	corner.Parent = parent
	return corner
end

local function CreatePadding(parent, top, bottom, left, right)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.Parent = parent
	return padding
end


local function AddHoverEffect(element, normalColor, hoverColor, property)
	property = property or "BackgroundColor3"
	element.MouseEnter:Connect(function()
		element[property] = hoverColor
	end)
	element.MouseLeave:Connect(function()
		element[property] = normalColor
	end)
end

local function CreateGradient(parent, darkColor, lightColor, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GetDarkerColor(darkColor or Colors.MainColor)),
		ColorSequenceKeypoint.new(1, lightColor or Colors.MainColor)
	})
	gradient.Rotation = rotation or -90
	gradient.Parent = parent
	return gradient
end

local function CreateToggleRow(parent, label, yPos, zBase)
	local container = CreateFrame({
		BackgroundColor3 = Colors.BackgroundColor,
		BorderColor3 = Colors.OutlineColor,
		Position = UDim2.new(0, 8, 0, yPos),
		Size = UDim2.new(1, -16, 0, 28),
		ZIndex = zBase,
		Parent = parent
	})
	
	CreateTextLabel({
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		ZIndex = zBase + 1,
		Text = label,
		TextSize = 13,
		Parent = container
	})
	
	local toggleBox = CreateTextButton({
		BackgroundColor3 = Colors.MainColor,
		Size = UDim2.new(0, 12, 0, 12),
		Position = UDim2.new(1, -20, 0.5, -6),
		ZIndex = zBase + 1,
		Parent = container
	})
	
	local checkmark = CreateTextLabel({
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = zBase + 2,
		TextColor3 = Colors.AccentColor,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = toggleBox
	})
	
	return toggleBox, checkmark
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = LPH_ENCSTR("oxyAnimationLogger")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = LPH_ENCNUM(999)
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
ScreenGui.Enabled = false  -- oxy: start hidden

_G[OXY_IDENTIFIER] = {
	ScreenGui = ScreenGui,
	Connections = ActiveConnections
}


local MAIN_UI_SIZE = UDim2.new(0, 450, 0, 550)
local CENTER_POS = UDim2.new(0.5, -225, 0.5, -275)
local LoadingFrame, LoadingStatus, LoadingProgress

do
	local LOADING_SIZE = UDim2.new(0, 200, 0, 80)
	local LOADING_CENTER_POS = UDim2.new(0.5, -100, 0.5, -40)
	
	LoadingFrame = Instance.new("Frame")
	LoadingFrame.Name = "LoadingFrame"
	LoadingFrame.BackgroundColor3 = Colors.MainColor
	LoadingFrame.BorderColor3 = Colors.Black
	LoadingFrame.Position = LOADING_CENTER_POS
	LoadingFrame.Size = UDim2.new(0, 0, 0, 0) 
	LoadingFrame.ZIndex = 100
	LoadingFrame.ClipsDescendants = true
	LoadingFrame.Parent = ScreenGui
	
	local LoadingInner = Instance.new("Frame")
	LoadingInner.BackgroundColor3 = Colors.MainColor
	LoadingInner.BorderColor3 = Colors.AccentColor
	LoadingInner.BorderMode = Enum.BorderMode.Inset
	LoadingInner.Size = UDim2.new(1, 0, 1, 0)
	LoadingInner.ZIndex = 101
	LoadingInner.Parent = LoadingFrame
	
	local LoadingGradient = Instance.new("UIGradient")
	LoadingGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GetDarkerColor(Colors.MainColor)),
		ColorSequenceKeypoint.new(1, Colors.MainColor),
	})
	LoadingGradient.Rotation = -90
	LoadingGradient.Parent = LoadingInner
	
	local LoadingTitle = Instance.new("TextLabel")
	LoadingTitle.Name = "Title"
	LoadingTitle.BackgroundTransparency = 1
	LoadingTitle.Position = UDim2.new(0, 0, 0, 8)
	LoadingTitle.Size = UDim2.new(1, 0, 0, 20)
	LoadingTitle.ZIndex = 102
	LoadingTitle.Font = Font
	LoadingTitle.Text = LPH_ENCSTR("oxy Animation Logger")
	LoadingTitle.TextColor3 = Colors.FontColor
	LoadingTitle.TextSize = 14
	LoadingTitle.TextStrokeTransparency = 0
	LoadingTitle.Parent = LoadingInner
	
	LoadingStatus = Instance.new("TextLabel")
	LoadingStatus.Name = "Status"
	LoadingStatus.BackgroundTransparency = 1
	LoadingStatus.Position = UDim2.new(0, 0, 0, 32)
	LoadingStatus.Size = UDim2.new(1, 0, 0, 16)
	LoadingStatus.ZIndex = 102
	LoadingStatus.Font = Font
	LoadingStatus.Text = LPH_ENCSTR("Initializing...")
	LoadingStatus.TextColor3 = Colors.DisabledTextColor
	LoadingStatus.TextSize = 12
	LoadingStatus.TextStrokeTransparency = 0
	LoadingStatus.Parent = LoadingInner
	
	local LoadingBar = Instance.new("Frame")
	LoadingBar.Name = "LoadingBar"
	LoadingBar.BackgroundColor3 = Colors.BackgroundColor
	LoadingBar.BorderColor3 = Colors.OutlineColor
	LoadingBar.Position = UDim2.new(0, 16, 0, 54)
	LoadingBar.Size = UDim2.new(1, -32, 0, 8)
	LoadingBar.ZIndex = 102
	LoadingBar.Parent = LoadingInner
	
	LoadingProgress = Instance.new("Frame")
	LoadingProgress.Name = "Progress"
	LoadingProgress.BackgroundColor3 = Colors.AccentColor
	LoadingProgress.BorderSizePixel = 0
	LoadingProgress.Size = UDim2.new(0, 0, 1, 0)
	LoadingProgress.ZIndex = 103
	LoadingProgress.Parent = LoadingBar
	
	local LoadingCorner = Instance.new("UICorner")
	LoadingCorner.CornerRadius = UDim.new(0, 2)
	LoadingCorner.Parent = LoadingProgress
	
	
	TweenService:Create(LoadingFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = LOADING_SIZE
	}):Play()
end

local function updateLoadingProgress(progress, status)
	LoadingStatus.Text = status or "Loading..."
	TweenService:Create(LoadingProgress, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(progress, 0, 1, 0)
	}):Play()
end


task.wait()
updateLoadingProgress(0.1, LPH_ENCSTR("Creating UI..."))
task.wait()


local UI_TOGGLE_KEY = Enum.KeyCode.RightControl
local isUIVisible = false  -- oxy: start hidden

TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == UI_TOGGLE_KEY or input.KeyCode == Enum.KeyCode.RightShift then
		isUIVisible = not isUIVisible
		if UI and UI.Outer then
			UI.Outer.Visible = isUIVisible
		end
		ScreenGui.Enabled = isUIVisible  -- oxy: show/hide whole gui
	end
end))


local UI = {} 
local Preview = {} 
local Settings = {} 
local Controls = {} 
local Sliders = {} 

UI.Outer = Instance.new("Frame")
UI.Outer.Name = LPH_ENCSTR("AnimationLoggerOuter")
UI.Outer.BorderColor3 = Colors.Black
UI.Outer.Position = UDim2.new(0.5, -225, 0.5, -275)
UI.Outer.Visible = false 
UI.Outer.Size = UDim2.new(0, 450, 0, 550)
UI.Outer.ZIndex = 1
UI.Outer.Active = true
UI.Outer.Draggable = true
UI.Outer.Parent = ScreenGui

UI.Inner = Instance.new("Frame")
UI.Inner.BackgroundColor3 = Colors.MainColor
UI.Inner.BorderColor3 = Colors.AccentColor
UI.Inner.BorderMode = Enum.BorderMode.Inset
UI.Inner.Size = UDim2.new(1, 0, 1, 0)
UI.Inner.ZIndex = 2
UI.Inner.Parent = UI.Outer

UI.Container = Instance.new("Frame")
UI.Container.BackgroundColor3 = Color3.new(1, 1, 1)
UI.Container.BorderSizePixel = 0
UI.Container.Position = UDim2.new(0, 1, 0, 1)
UI.Container.Size = UDim2.new(1, -2, 1, -2)
UI.Container.ZIndex = 3
UI.Container.Parent = UI.Inner

do 
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GetDarkerColor(Colors.MainColor)),
		ColorSequenceKeypoint.new(1, Colors.MainColor),
	})
	g.Rotation = -90
	g.Parent = UI.Container
end

UI.TitleBar = Instance.new("Frame")
UI.TitleBar.BackgroundColor3 = Colors.BackgroundColor
UI.TitleBar.BorderSizePixel = 0
UI.TitleBar.Size = UDim2.new(1, 0, 0, 24)
UI.TitleBar.ZIndex = 4
UI.TitleBar.Parent = UI.Container

do 
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Size = UDim2.new(1, -90, 1, 0)
	TitleLabel.Position = UDim2.new(0, 6, 0, 0)
	TitleLabel.ZIndex = 5
	TitleLabel.Font = Font
	TitleLabel.Text = LPH_ENCSTR("oxy Animation Logger")
	TitleLabel.TextColor3 = Colors.FontColor
	TitleLabel.TextSize = 14
	TitleLabel.TextStrokeTransparency = 0
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = UI.TitleBar
end

UI.PreviewButton = Instance.new("TextButton")
UI.PreviewButton.BackgroundTransparency = 1
UI.PreviewButton.Size = UDim2.new(0, 20, 0, 20)
UI.PreviewButton.Position = UDim2.new(1, -96, 0, 2)
UI.PreviewButton.ZIndex = 5
UI.PreviewButton.Text = ""
UI.PreviewButton.Parent = UI.TitleBar
CreateIcon(UI.PreviewButton, "play-circle", 16, UDim2.new(0, 2, 0, 2))

UI.SettingsButton = Instance.new("TextButton")
UI.SettingsButton.BackgroundTransparency = 1
UI.SettingsButton.Size = UDim2.new(0, 20, 0, 20)
UI.SettingsButton.Position = UDim2.new(1, -72, 0, 2)
UI.SettingsButton.ZIndex = 5
UI.SettingsButton.Text = ""
UI.SettingsButton.Parent = UI.TitleBar
CreateIcon(UI.SettingsButton, "settings", 16, UDim2.new(0, 2, 0, 2))

UI.MinimizeButton = Instance.new("TextButton")
UI.MinimizeButton.BackgroundTransparency = 1
UI.MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
UI.MinimizeButton.Position = UDim2.new(1, -48, 0, 2)
UI.MinimizeButton.ZIndex = 5
UI.MinimizeButton.Text = ""
UI.MinimizeButton.Parent = UI.TitleBar
CreateIcon(UI.MinimizeButton, "minus", 16, UDim2.new(0, 2, 0, 2))

UI.CloseButton = Instance.new("TextButton")
UI.CloseButton.BackgroundTransparency = 1
UI.CloseButton.Size = UDim2.new(0, 20, 0, 20)
UI.CloseButton.Position = UDim2.new(1, -24, 0, 2)
UI.CloseButton.ZIndex = 5
UI.CloseButton.Text = ""
UI.CloseButton.Parent = UI.TitleBar
CreateIcon(UI.CloseButton, "x", 16, UDim2.new(0, 2, 0, 2))

do 
	local Divider = Instance.new("Frame")
	Divider.BackgroundColor3 = Colors.OutlineColor
	Divider.BorderSizePixel = 0
	Divider.Position = UDim2.new(0, 0, 0, 24)
	Divider.Size = UDim2.new(1, 0, 0, 1)
	Divider.ZIndex = 4
	Divider.Parent = UI.Container
end


UI.TabBar = Instance.new("Frame")
UI.TabBar.BackgroundColor3 = Colors.BackgroundColor
UI.TabBar.BorderSizePixel = 0
UI.TabBar.Position = UDim2.new(0, 0, 0, 25)
UI.TabBar.Size = UDim2.new(1, 0, 0, 28)
UI.TabBar.ZIndex = 4
UI.TabBar.Parent = UI.Container

do 
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 0)
	l.Parent = UI.TabBar
end

local activeTab = "AnimationLogger"
local tabButtons = {}
local tabContents = {}

local function switchTab(tabName)
	if activeTab == tabName then return end
	
	
	local oldButton = tabButtons[activeTab]
	if oldButton then
		oldButton.BackgroundColor3 = Colors.BackgroundColor
		oldButton.TextColor3 = Colors.DisabledTextColor
		local oldUnderline = oldButton:FindFirstChild("Underline")
		if oldUnderline then oldUnderline.Visible = false end
	end
	
	
	local oldContent = tabContents[activeTab]
	if oldContent then
		oldContent.Visible = false
	end
	
	
	local newButton = tabButtons[tabName]
	if newButton then
		newButton.BackgroundColor3 = Colors.MainColor
		newButton.TextColor3 = Colors.FontColor
		local newUnderline = newButton:FindFirstChild("Underline")
		if newUnderline then newUnderline.Visible = true end
	end
	
	
	local newContent = tabContents[tabName]
	if newContent then
		newContent.Visible = true
	end
	
	activeTab = tabName
end

local function CreateTab(name, displayName, isFirst)
	local TabButton = Instance.new("TextButton")
	TabButton.Name = name .. "Tab"
	TabButton.BackgroundColor3 = isFirst and Colors.MainColor or Colors.BackgroundColor
	TabButton.BorderSizePixel = 0
	TabButton.Size = UDim2.new(0.5, 0, 1, 0)
	TabButton.ZIndex = 5
	TabButton.Font = Font
	TabButton.Text = displayName
	TabButton.TextColor3 = isFirst and Colors.FontColor or Colors.DisabledTextColor
	TabButton.TextSize = 13
	TabButton.TextStrokeTransparency = 0
	TabButton.AutoButtonColor = false
	TabButton.Parent = UI.TabBar
	
	local TabUnderline = Instance.new("Frame")
	TabUnderline.Name = "Underline"
	TabUnderline.BackgroundColor3 = Colors.AccentColor
	TabUnderline.BorderSizePixel = 0
	TabUnderline.Position = UDim2.new(0, 0, 1, -2)
	TabUnderline.Size = UDim2.new(1, 0, 0, 2)
	TabUnderline.ZIndex = 6
	TabUnderline.Visible = isFirst
	TabUnderline.Parent = TabButton
	
	TrackConnection(TabButton.MouseButton1Click:Connect(function()
		switchTab(name)
	end))
	
	tabButtons[name] = TabButton
	return TabButton
end

CreateTab("AnimationLogger", "Local Player", true)
CreateTab("Others", "Others", false)

do 
	local d = Instance.new("Frame")
	d.BackgroundColor3 = Colors.OutlineColor
	d.BorderSizePixel = 0
	d.Position = UDim2.new(0, 0, 0, 53)
	d.Size = UDim2.new(1, 0, 0, 1)
	d.ZIndex = 4
	d.Parent = UI.Container
end


UI.AnimLoggerContent = Instance.new("Frame")
UI.AnimLoggerContent.Name = "AnimLoggerContent"
UI.AnimLoggerContent.BackgroundTransparency = 1
UI.AnimLoggerContent.Position = UDim2.new(0, 0, 0, 54)
UI.AnimLoggerContent.Size = UDim2.new(1, 0, 1, -54)
UI.AnimLoggerContent.ZIndex = 4
UI.AnimLoggerContent.Visible = true
UI.AnimLoggerContent.Parent = UI.Container

tabContents["AnimationLogger"] = UI.AnimLoggerContent

do 
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Colors.BackgroundColor
	f.BorderSizePixel = 0
	f.Position = UDim2.new(0, 8, 0, 4)
	f.Size = UDim2.new(1, -16, 0, 22)
	f.ZIndex = 4
	f.Parent = UI.AnimLoggerContent
	
	UI.StatsLabel = Instance.new("TextLabel")
	UI.StatsLabel.BackgroundTransparency = 1
	UI.StatsLabel.Size = UDim2.new(1, -8, 1, 0)
	UI.StatsLabel.Position = UDim2.new(0, 4, 0, 0)
	UI.StatsLabel.ZIndex = 5
	UI.StatsLabel.Font = Font
	UI.StatsLabel.Text = "Logged: 0"
	UI.StatsLabel.TextColor3 = Colors.FontColor
	UI.StatsLabel.TextSize = 13
	UI.StatsLabel.TextStrokeTransparency = 0
	UI.StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
	UI.StatsLabel.Parent = f
end

UI.ScrollFrame = Instance.new("ScrollingFrame")
UI.ScrollFrame.BackgroundColor3 = Colors.BackgroundColor
UI.ScrollFrame.BorderColor3 = Colors.OutlineColor
UI.ScrollFrame.Position = UDim2.new(0, 8, 0, 30)
UI.ScrollFrame.Size = UDim2.new(1, -16, 1, -38)
UI.ScrollFrame.ZIndex = 4
UI.ScrollFrame.ScrollBarThickness = 4
UI.ScrollFrame.ScrollBarImageColor3 = Colors.OutlineColor
UI.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.ScrollFrame.Parent = UI.AnimLoggerContent

UI.ListLayout = Instance.new("UIListLayout")
UI.ListLayout.Padding = UDim.new(0, 4)
UI.ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UI.ListLayout.Parent = UI.ScrollFrame

do 
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, 4)
	p.PaddingBottom = UDim.new(0, 4)
	p.PaddingLeft = UDim.new(0, 4)
	p.PaddingRight = UDim.new(0, 4)
	p.Parent = UI.ScrollFrame
end


do
	local LocalPlayerHeader = Instance.new("Frame")
	LocalPlayerHeader.Name = "LocalPlayerHeader"
	LocalPlayerHeader.BackgroundColor3 = Colors.Black
	LocalPlayerHeader.BorderSizePixel = 0
	LocalPlayerHeader.Size = UDim2.new(1, -8, 0, 36)
	LocalPlayerHeader.ZIndex = 5
	LocalPlayerHeader.LayoutOrder = -1 
	LocalPlayerHeader.Parent = UI.ScrollFrame
	
	local HeaderInner = Instance.new("Frame")
	HeaderInner.BackgroundColor3 = Colors.MainColor
	HeaderInner.BorderColor3 = Colors.OutlineColor
	HeaderInner.BorderMode = Enum.BorderMode.Inset
	HeaderInner.Size = UDim2.new(1, 0, 1, 0)
	HeaderInner.ZIndex = 6
	HeaderInner.Parent = LocalPlayerHeader
	
	
	local ProfilePic = Instance.new("ImageLabel")
	ProfilePic.Name = "ProfilePic"
	ProfilePic.BackgroundColor3 = Colors.BackgroundColor
	ProfilePic.BorderSizePixel = 0
	ProfilePic.Position = UDim2.new(0, 4, 0, 4)
	ProfilePic.Size = UDim2.new(0, 28, 0, 28)
	ProfilePic.ZIndex = 7
	ProfilePic.Image = ""
	ProfilePic.Parent = HeaderInner
	
	local ProfileCorner = Instance.new("UICorner")
	ProfileCorner.CornerRadius = UDim.new(0, 4)
	ProfileCorner.Parent = ProfilePic
	
	
	task.spawn(function()
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if success and result then
			ProfilePic.Image = result
		end
	end)
	
	
	local PlayerNameLabel = Instance.new("TextLabel")
	PlayerNameLabel.Name = "PlayerName"
	PlayerNameLabel.BackgroundTransparency = 1
	PlayerNameLabel.Size = UDim2.new(1, -100, 1, 0)
	PlayerNameLabel.Position = UDim2.new(0, 38, 0, 0)
	PlayerNameLabel.ZIndex = 7
	PlayerNameLabel.Font = Font
	PlayerNameLabel.Text = LocalPlayer.Name
	PlayerNameLabel.TextColor3 = Colors.FontColor
	PlayerNameLabel.TextSize = 13
	PlayerNameLabel.TextStrokeTransparency = 0
	PlayerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	PlayerNameLabel.Parent = HeaderInner
	
	
	local YouBadge = Instance.new("TextLabel")
	YouBadge.Name = "YouBadge"
	YouBadge.BackgroundColor3 = Colors.AccentColor
	YouBadge.BorderSizePixel = 0
	YouBadge.Size = UDim2.new(0, 32, 0, 16)
	YouBadge.Position = UDim2.new(1, -40, 0, 10)
	YouBadge.ZIndex = 7
	YouBadge.Font = Font
	YouBadge.Text = "You"
	YouBadge.TextColor3 = Colors.FontColor
	YouBadge.TextSize = 10
	YouBadge.TextStrokeTransparency = 0
	YouBadge.Parent = HeaderInner
	
	local BadgeCorner = Instance.new("UICorner")
	BadgeCorner.CornerRadius = UDim.new(0, 3)
	BadgeCorner.Parent = YouBadge
end


UI.OthersContent = Instance.new("Frame")
UI.OthersContent.Name = "OthersContent"
UI.OthersContent.BackgroundTransparency = 1
UI.OthersContent.Position = UDim2.new(0, 0, 0, 54)
UI.OthersContent.Size = UDim2.new(1, 0, 1, -54)
UI.OthersContent.ZIndex = 4
UI.OthersContent.Visible = false
UI.OthersContent.Parent = UI.Container

tabContents["Others"] = UI.OthersContent

do 
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Colors.BackgroundColor
	f.BorderSizePixel = 0
	f.Position = UDim2.new(0, 8, 0, 4)
	f.Size = UDim2.new(1, -16, 0, 22)
	f.ZIndex = 4
	f.Parent = UI.OthersContent
	
	UI.OthersStatsLabel = Instance.new("TextLabel")
	UI.OthersStatsLabel.BackgroundTransparency = 1
	UI.OthersStatsLabel.Size = UDim2.new(1, -8, 1, 0)
	UI.OthersStatsLabel.Position = UDim2.new(0, 4, 0, 0)
	UI.OthersStatsLabel.ZIndex = 5
	UI.OthersStatsLabel.Font = Font
	UI.OthersStatsLabel.Text = "Logged: 0"
	UI.OthersStatsLabel.TextColor3 = Colors.FontColor
	UI.OthersStatsLabel.TextSize = 13
	UI.OthersStatsLabel.TextStrokeTransparency = 0
	UI.OthersStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
	UI.OthersStatsLabel.Parent = f
end

UI.OthersScrollFrame = Instance.new("ScrollingFrame")
UI.OthersScrollFrame.BackgroundColor3 = Colors.BackgroundColor
UI.OthersScrollFrame.BorderColor3 = Colors.OutlineColor
UI.OthersScrollFrame.Position = UDim2.new(0, 8, 0, 30)
UI.OthersScrollFrame.Size = UDim2.new(1, -16, 1, -38)
UI.OthersScrollFrame.ZIndex = 4
UI.OthersScrollFrame.ScrollBarThickness = 4
UI.OthersScrollFrame.ScrollBarImageColor3 = Colors.OutlineColor
UI.OthersScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.OthersScrollFrame.Parent = UI.OthersContent

UI.OthersListLayout = Instance.new("UIListLayout")
UI.OthersListLayout.Padding = UDim.new(0, 4)
UI.OthersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UI.OthersListLayout.Parent = UI.OthersScrollFrame

do 
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, 4)
	p.PaddingBottom = UDim.new(0, 4)
	p.PaddingLeft = UDim.new(0, 4)
	p.PaddingRight = UDim.new(0, 4)
	p.Parent = UI.OthersScrollFrame
end

Settings.Outer = Instance.new("Frame")
Settings.Outer.Name = "SettingsOuter"
Settings.Outer.BackgroundColor3 = Colors.MainColor
Settings.Outer.BorderColor3 = Colors.AccentColor
Settings.Outer.Position = UDim2.new(0, 8, 0, 32)
Settings.Outer.Size = UDim2.new(1, -16, 0, 260)
Settings.Outer.ZIndex = 200
Settings.Outer.Visible = false
Settings.Outer.Parent = UI.Container

do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = Settings.Outer
end

Settings.Container = Instance.new("ScrollingFrame")
Settings.Container.BackgroundTransparency = 1
Settings.Container.BorderSizePixel = 0
Settings.Container.Position = UDim2.new(0, 4, 0, 4)
Settings.Container.Size = UDim2.new(1, -8, 1, -8)
Settings.Container.ZIndex = 201
Settings.Container.ScrollBarThickness = 3
Settings.Container.ScrollBarImageColor3 = Colors.OutlineColor
Settings.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Settings.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Settings.Container.Parent = Settings.Outer

do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = Settings.Container
end


local function createSettingsRow(text, layoutOrder, hasCheckbox)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Colors.BackgroundColor
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 26)
	row.ZIndex = 202
	row.LayoutOrder = layoutOrder
	row.Parent = Settings.Container
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 3)
	rowCorner.Parent = row
	
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.ZIndex = 203
	lbl.Font = Font
	lbl.Text = text
	lbl.TextColor3 = Colors.FontColor
	lbl.TextSize = 11
	lbl.TextStrokeTransparency = 0
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	if hasCheckbox then
		local box = Instance.new("TextButton")
		box.BackgroundColor3 = Colors.MainColor
		box.BorderColor3 = Colors.OutlineColor
		box.Size = UDim2.new(0, 14, 0, 14)
		box.Position = UDim2.new(1, -22, 0.5, -7)
		box.ZIndex = 203
		box.Text = ""
		box.Parent = row
		
		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 2)
		boxCorner.Parent = box
		
		local check = Instance.new("TextLabel")
		check.BackgroundTransparency = 1
		check.Size = UDim2.new(1, 0, 1, 0)
		check.ZIndex = 204
		check.Font = Font
		check.Text = ""
		check.TextColor3 = Colors.AccentColor
		check.TextSize = 12
		check.Parent = box
		
		return row, box, check
	end
	
	return row
end


local function createSettingsButton(text, layoutOrder, textColor)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = Colors.BackgroundColor
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(1, 0, 0, 26)
	btn.ZIndex = 202
	btn.LayoutOrder = layoutOrder
	btn.Font = Font
	btn.Text = "     " .. text
	btn.TextColor3 = textColor or Colors.FontColor
	btn.TextSize = 11
	btn.TextStrokeTransparency = 0
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.Parent = Settings.Container
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 3)
	btnCorner.Parent = btn
	
	return btn
end


do
	local _, copyLinkBox, copyLinkCheck = createSettingsRow("Copy as Link", 1, true)
	Settings.ToggleBox, Settings.ToggleCheckmark = copyLinkBox, copyLinkCheck
	
	local _, autoPreviewBox, autoPreviewCheck = createSettingsRow("Auto Preview", 2, true)
	Settings.AutoPreviewBox, Settings.AutoPreviewCheckmark = autoPreviewBox, autoPreviewCheck
	
	local _, nameParentBox, nameParentCheck = createSettingsRow("Name Parenting", 3, true)
	Settings.NameParentingBox, Settings.NameParentingCheckmark = nameParentBox, nameParentCheck
	
	local _, groupParentBox, groupParentCheck = createSettingsRow("Group by Parent", 4, true)
	Settings.GroupByParentBox, Settings.GroupByParentCheckmark = groupParentBox, groupParentCheck
	
	local _, fileCacheBox, fileCacheCheck = createSettingsRow("File Cache", 5, true)
	Settings.FileCacheBox, Settings.FileCacheCheckmark = fileCacheBox, fileCacheCheck
	
	
	if not hasFileSystem then
		Settings.FileCacheBox.BackgroundColor3 = Colors.OutlineColor
	elseif isFileCacheEnabled then
		
		Settings.FileCacheCheckmark.Text = "✓"
		Settings.FileCacheBox.BorderColor3 = Colors.AccentColor
	end
	
	
	local divider1 = Instance.new("Frame")
	divider1.BackgroundColor3 = Colors.OutlineColor
	divider1.BorderSizePixel = 0
	divider1.Size = UDim2.new(1, 0, 0, 1)
	divider1.ZIndex = 202
	divider1.LayoutOrder = 6
	divider1.Parent = Settings.Container
	
	
	Settings.ClearButton = createSettingsButton("Clear All Animations", 7, Colors.FontColor)
	Settings.ClearCacheButton = createSettingsButton("Clear Animation Cache", 8, Color3.fromRGB(255, 150, 100))
	
	
	local divider2 = Instance.new("Frame")
	divider2.BackgroundColor3 = Colors.OutlineColor
	divider2.BorderSizePixel = 0
	divider2.Size = UDim2.new(1, 0, 0, 1)
	divider2.ZIndex = 202
	divider2.LayoutOrder = 9
	divider2.Parent = Settings.Container
	
	
	local ignoredLabel = Instance.new("TextLabel")
	ignoredLabel.BackgroundTransparency = 1
	ignoredLabel.Size = UDim2.new(1, 0, 0, 18)
	ignoredLabel.ZIndex = 202
	ignoredLabel.LayoutOrder = 10
	ignoredLabel.Font = Font
	ignoredLabel.Text = "Ignored (right-click groups to add)"
	ignoredLabel.TextColor3 = Colors.DisabledTextColor
	ignoredLabel.TextSize = 9
	ignoredLabel.TextStrokeTransparency = 0
	ignoredLabel.Parent = Settings.Container
	
	Settings.ClearIgnoredBtn = createSettingsButton("Clear All Ignored", 11, Color3.fromRGB(255, 100, 100))
	
	
	Settings.IgnoredCountLabel = Instance.new("TextLabel")
	Settings.IgnoredCountLabel.BackgroundTransparency = 1
	Settings.IgnoredCountLabel.Size = UDim2.new(1, 0, 0, 16)
	Settings.IgnoredCountLabel.ZIndex = 202
	Settings.IgnoredCountLabel.LayoutOrder = 12
	Settings.IgnoredCountLabel.Font = Font
	Settings.IgnoredCountLabel.Text = "0 parents, 0 players ignored"
	Settings.IgnoredCountLabel.TextColor3 = Colors.DisabledTextColor
	Settings.IgnoredCountLabel.TextSize = 9
	Settings.IgnoredCountLabel.TextStrokeTransparency = 0
	Settings.IgnoredCountLabel.Parent = Settings.Container
end


updateLoadingProgress(0.2, LPH_ENCSTR("Setting up menus..."))
task.wait()


local ContextMenu = {}
ContextMenu.Frame = Instance.new("Frame")
ContextMenu.Frame.Name = "ContextMenu"
ContextMenu.Frame.BackgroundColor3 = Colors.MainColor
ContextMenu.Frame.BorderColor3 = Colors.AccentColor
ContextMenu.Frame.Size = UDim2.new(0, 120, 0, 0)
ContextMenu.Frame.ZIndex = 500
ContextMenu.Frame.Visible = false
ContextMenu.Frame.AutomaticSize = Enum.AutomaticSize.Y
ContextMenu.Frame.Parent = ScreenGui

do
	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 4)
	menuCorner.Parent = ContextMenu.Frame
	
	local menuLayout = Instance.new("UIListLayout")
	menuLayout.Padding = UDim.new(0, 2)
	menuLayout.Parent = ContextMenu.Frame
	
	local menuPadding = Instance.new("UIPadding")
	menuPadding.PaddingTop = UDim.new(0, 4)
	menuPadding.PaddingBottom = UDim.new(0, 4)
	menuPadding.PaddingLeft = UDim.new(0, 4)
	menuPadding.PaddingRight = UDim.new(0, 4)
	menuPadding.Parent = ContextMenu.Frame
end

ContextMenu.Items = {}

local function clearContextMenu()
	for _, item in ContextMenu.Items do
		item:Destroy()
	end
	ContextMenu.Items = {}
end

local function addContextMenuItem(text, callback, textColor)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = Colors.BackgroundColor
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(1, 0, 0, 22)
	btn.ZIndex = 501
	btn.Font = Font
	btn.Text = text
	btn.TextColor3 = textColor or Colors.FontColor
	btn.TextSize = 10
	btn.TextStrokeTransparency = 0
	btn.AutoButtonColor = false
	btn.Parent = ContextMenu.Frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = btn
	
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Colors.OutlineColor
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Colors.BackgroundColor
	end)
	
	btn.MouseButton1Click:Connect(function()
		ContextMenu.Frame.Visible = false
		if callback then callback() end
	end)
	
	table_insert(ContextMenu.Items, btn)
	return btn
end

local function showContextMenu(x, y)
	ContextMenu.Frame.Position = UDim2.new(0, x, 0, y)
	ContextMenu.Frame.Visible = true
end

local function hideContextMenu()
	ContextMenu.Frame.Visible = false
end


TrackConnection(UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		task.defer(function()
			if ContextMenu.Frame.Visible then
				local mouse = LocalPlayer:GetMouse()
				local pos = ContextMenu.Frame.AbsolutePosition
				local size = ContextMenu.Frame.AbsoluteSize
				if mouse.X < pos.X or mouse.X > pos.X + size.X or mouse.Y < pos.Y or mouse.Y > pos.Y + size.Y then
					hideContextMenu()
				end
			end
		end)
	end
end))


local function updateIgnoredCount()
	local parentCount = 0
	local playerCount = 0
	for _ in ignoredParents do parentCount += 1 end
	for _ in ignoredPlayers do playerCount += 1 end
	Settings.IgnoredCountLabel.Text = string.format("%d parents, %d players ignored", parentCount, playerCount)
end


updateLoadingProgress(0.3, LPH_ENCSTR("Creating preview window..."))
task.wait()

local PREVIEW_DEFAULT_POSITION = UDim2.new(0, -368, 0, 0)
Preview.Outer = Instance.new("Frame")
Preview.Outer.Name = LPH_ENCSTR("PreviewOuter")
Preview.Outer.BorderColor3 = Colors.Black
Preview.Outer.Position = PREVIEW_DEFAULT_POSITION
Preview.Outer.Size = UDim2.new(0, 360, 0, 520)
Preview.Outer.ZIndex = 100
Preview.Outer.Visible = false
Preview.Outer.Parent = UI.Outer

Preview.Inner = Instance.new("Frame")
Preview.Inner.BackgroundColor3 = Colors.MainColor
Preview.Inner.BorderColor3 = Colors.AccentColor
Preview.Inner.BorderMode = Enum.BorderMode.Inset
Preview.Inner.Size = UDim2.new(1, 0, 1, 0)
Preview.Inner.ZIndex = 101
Preview.Inner.Parent = Preview.Outer

Preview.Container = Instance.new("Frame")
Preview.Container.BackgroundColor3 = Color3.new(1, 1, 1)
Preview.Container.BorderSizePixel = 0
Preview.Container.Position = UDim2.new(0, 1, 0, 1)
Preview.Container.Size = UDim2.new(1, -2, 1, -2)
Preview.Container.ZIndex = 102
Preview.Container.Parent = Preview.Inner

do 
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GetDarkerColor(Colors.MainColor)), ColorSequenceKeypoint.new(1, Colors.MainColor)})
	g.Rotation = -90
	g.Parent = Preview.Container
end

do 
	Preview.TitleBar = Instance.new("Frame")
	Preview.TitleBar.Name = "TitleBar"
	Preview.TitleBar.BackgroundColor3 = Colors.BackgroundColor
	Preview.TitleBar.BorderSizePixel = 0
	Preview.TitleBar.Size = UDim2.new(1, 0, 0, 24)
	Preview.TitleBar.ZIndex = 103
	Preview.TitleBar.Active = true
	Preview.TitleBar.Parent = Preview.Container
	
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -50, 1, 0)
	l.Position = UDim2.new(0, 6, 0, 0)
	l.ZIndex = 104
	l.Font = Font
	l.Text = "Animation Preview"
	l.TextColor3 = Colors.FontColor
	l.TextSize = 14
	l.TextStrokeTransparency = 0
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = Preview.TitleBar
	
	Preview.SnapBtn = Instance.new("TextButton")
	Preview.SnapBtn.BackgroundTransparency = 1
	Preview.SnapBtn.Size = UDim2.new(0, 20, 0, 20)
	Preview.SnapBtn.Position = UDim2.new(1, -46, 0, 2)
	Preview.SnapBtn.ZIndex = 104
	Preview.SnapBtn.Text = ""
	Preview.SnapBtn.Parent = Preview.TitleBar
	CreateIcon(Preview.SnapBtn, "home", 14, UDim2.new(0, 2, 0, 2))
	
	Preview.CloseBtn = Instance.new("TextButton")
	Preview.CloseBtn.BackgroundTransparency = 1
	Preview.CloseBtn.Size = UDim2.new(0, 20, 0, 20)
	Preview.CloseBtn.Position = UDim2.new(1, -24, 0, 2)
	Preview.CloseBtn.ZIndex = 104
	Preview.CloseBtn.Text = ""
	Preview.CloseBtn.Parent = Preview.TitleBar
	CreateIcon(Preview.CloseBtn, "x", 16, UDim2.new(0, 2, 0, 2))
	
	local d = Instance.new("Frame")
	d.BackgroundColor3 = Colors.OutlineColor
	d.BorderSizePixel = 0
	d.Position = UDim2.new(0, 0, 0, 24)
	d.Size = UDim2.new(1, 0, 0, 1)
	d.ZIndex = 103
	d.Parent = Preview.Container
end

Preview.ViewportFrame = Instance.new("ViewportFrame")
Preview.ViewportFrame.BackgroundColor3 = Colors.BackgroundColor
Preview.ViewportFrame.BorderSizePixel = 0
Preview.ViewportFrame.Position = UDim2.new(0, 8, 0, 33)
Preview.ViewportFrame.Size = UDim2.new(1, -16, 0, 220)
Preview.ViewportFrame.ZIndex = 103
Preview.ViewportFrame.Parent = Preview.Container

do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = Preview.ViewportFrame
end

Preview.Camera = Instance.new("Camera")
Preview.Camera.Parent = Preview.ViewportFrame
Preview.ViewportFrame.CurrentCamera = Preview.Camera
Preview.Camera.CFrame = CFrame.new(0, 5, 10) * CFrame.Angles(math.rad(-15), 0, 0)

Preview.WorldModel = Instance.new("WorldModel")
Preview.WorldModel.Parent = Preview.ViewportFrame

do 
	Preview.ViewportFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
	Preview.ViewportFrame.BackgroundTransparency = 0
	
	local ambientLight = Instance.new("Sky")
	ambientLight.SkyboxBk = "rbxasset://sky/moon_2.jpg"
	ambientLight.SkyboxDn = "rbxasset://sky/moon_2.jpg"  
	ambientLight.SkyboxFt = "rbxasset://sky/moon_2.jpg"
	ambientLight.SkyboxLf = "rbxasset://sky/moon_2.jpg"
	ambientLight.SkyboxRt = "rbxasset://sky/moon_2.jpg"
	ambientLight.SkyboxUp = "rbxasset://sky/moon_2.jpg"
	ambientLight.Parent = Preview.WorldModel
end


do 
	local overlay = Instance.new("Frame")
	overlay.BackgroundColor3 = Colors.Black
	overlay.BackgroundTransparency = 0.6
	overlay.BorderSizePixel = 0
	overlay.Position = UDim2.new(0, 4, 0, 4)
	overlay.Size = UDim2.new(0, 120, 0, 24)
	overlay.ZIndex = 110
	overlay.Parent = Preview.ViewportFrame
	
	local oc = Instance.new("UICorner")
	oc.CornerRadius = UDim.new(0, 4)
	oc.Parent = overlay
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = overlay
	
	Preview.GridBtn = Instance.new("TextButton")
	Preview.GridBtn.BackgroundColor3 = Colors.AccentColor
	Preview.GridBtn.BackgroundTransparency = 0.5
	Preview.GridBtn.BorderSizePixel = 0
	Preview.GridBtn.Size = UDim2.new(0, 34, 0, 18)
	Preview.GridBtn.ZIndex = 111
	Preview.GridBtn.Font = Font
	Preview.GridBtn.Text = "Grid"
	Preview.GridBtn.TextColor3 = Colors.FontColor
	Preview.GridBtn.TextSize = 9
	Preview.GridBtn.TextStrokeTransparency = 0
	Preview.GridBtn.Parent = overlay
	local gc = Instance.new("UICorner")
	gc.CornerRadius = UDim.new(0, 3)
	gc.Parent = Preview.GridBtn
	
	Preview.AutoRotateBtn = Instance.new("TextButton")
	Preview.AutoRotateBtn.BackgroundColor3 = Colors.OutlineColor
	Preview.AutoRotateBtn.BackgroundTransparency = 0.5
	Preview.AutoRotateBtn.BorderSizePixel = 0
	Preview.AutoRotateBtn.Size = UDim2.new(0, 34, 0, 18)
	Preview.AutoRotateBtn.ZIndex = 111
	Preview.AutoRotateBtn.Font = Font
	Preview.AutoRotateBtn.Text = "Spin"
	Preview.AutoRotateBtn.TextColor3 = Colors.FontColor
	Preview.AutoRotateBtn.TextSize = 9
	Preview.AutoRotateBtn.TextStrokeTransparency = 0
	Preview.AutoRotateBtn.Parent = overlay
	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0, 3)
	ac.Parent = Preview.AutoRotateBtn
	
	Preview.ResetCameraBtn = Instance.new("TextButton")
	Preview.ResetCameraBtn.BackgroundColor3 = Colors.OutlineColor
	Preview.ResetCameraBtn.BackgroundTransparency = 0.5
	Preview.ResetCameraBtn.BorderSizePixel = 0
	Preview.ResetCameraBtn.Size = UDim2.new(0, 34, 0, 18)
	Preview.ResetCameraBtn.ZIndex = 111
	Preview.ResetCameraBtn.Font = Font
	Preview.ResetCameraBtn.Text = "Reset"
	Preview.ResetCameraBtn.TextColor3 = Colors.FontColor
	Preview.ResetCameraBtn.TextSize = 9
	Preview.ResetCameraBtn.TextStrokeTransparency = 0
	Preview.ResetCameraBtn.Parent = overlay
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 3)
	rc.Parent = Preview.ResetCameraBtn
end


Preview.InfoPanel = Instance.new("Frame")
Preview.InfoPanel.BackgroundColor3 = Colors.BackgroundColor
Preview.InfoPanel.BorderSizePixel = 0
Preview.InfoPanel.Position = UDim2.new(0, 8, 0, 257)
Preview.InfoPanel.Size = UDim2.new(1, -16, 0, 36)
Preview.InfoPanel.ZIndex = 103
Preview.InfoPanel.Parent = Preview.Container

do
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(0, 4)
	ic.Parent = Preview.InfoPanel
end

Preview.InfoLabel = Instance.new("TextLabel")
Preview.InfoLabel.BackgroundTransparency = 1
Preview.InfoLabel.Position = UDim2.new(0, 8, 0, 0)
Preview.InfoLabel.Size = UDim2.new(1, -16, 1, 0)
Preview.InfoLabel.ZIndex = 104
Preview.InfoLabel.Font = Font
Preview.InfoLabel.Text = "Select an animation to preview"
Preview.InfoLabel.TextColor3 = Colors.DisabledTextColor
Preview.InfoLabel.TextSize = 11
Preview.InfoLabel.TextStrokeTransparency = 0
Preview.InfoLabel.TextWrapped = true
Preview.InfoLabel.TextYAlignment = Enum.TextYAlignment.Center
Preview.InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
Preview.InfoLabel.Parent = Preview.InfoPanel

Controls.Frame = Instance.new("Frame")
Controls.Frame.BackgroundColor3 = Colors.BackgroundColor
Controls.Frame.BorderSizePixel = 0
Controls.Frame.Position = UDim2.new(0, 8, 0, 297)
Controls.Frame.Size = UDim2.new(1, -16, 0, 192)
Controls.Frame.ZIndex = 103
Controls.Frame.Parent = Preview.Container

do
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 4)
	cc.Parent = Controls.Frame
end


do
	local r = Instance.new("Frame")
	r.BackgroundTransparency = 1
	r.Position = UDim2.new(0, 8, 0, 8)
	r.Size = UDim2.new(1, -16, 0, 16)
	r.ZIndex = 104
	r.Parent = Controls.Frame
	
	Controls.CurrentTimeLabel = Instance.new("TextLabel")
	Controls.CurrentTimeLabel.Name = "CurrentTime"
	Controls.CurrentTimeLabel.BackgroundTransparency = 1
	Controls.CurrentTimeLabel.Position = UDim2.new(0, 0, 0, 0)
	Controls.CurrentTimeLabel.Size = UDim2.new(0, 50, 1, 0)
	Controls.CurrentTimeLabel.ZIndex = 104
	Controls.CurrentTimeLabel.Font = Font
	Controls.CurrentTimeLabel.Text = "00:00.00"
	Controls.CurrentTimeLabel.TextColor3 = Colors.FontColor
	Controls.CurrentTimeLabel.TextSize = 11
	Controls.CurrentTimeLabel.TextStrokeTransparency = 0
	Controls.CurrentTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	Controls.CurrentTimeLabel.Parent = r
	
	Controls.TotalTimeLabel = Instance.new("TextLabel")
	Controls.TotalTimeLabel.Name = "TotalTime"
	Controls.TotalTimeLabel.BackgroundTransparency = 1
	Controls.TotalTimeLabel.Position = UDim2.new(1, -50, 0, 0)
	Controls.TotalTimeLabel.Size = UDim2.new(0, 50, 1, 0)
	Controls.TotalTimeLabel.ZIndex = 104
	Controls.TotalTimeLabel.Font = Font
	Controls.TotalTimeLabel.Text = "00:00.00"
	Controls.TotalTimeLabel.TextColor3 = Colors.FontColor
	Controls.TotalTimeLabel.TextSize = 11
	Controls.TotalTimeLabel.TextStrokeTransparency = 0
	Controls.TotalTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
	Controls.TotalTimeLabel.Parent = r
	
	
	Controls.ProgressBarBg = Instance.new("Frame")
	Controls.ProgressBarBg.BackgroundColor3 = Colors.OutlineColor
	Controls.ProgressBarBg.BorderSizePixel = 0
	Controls.ProgressBarBg.Position = UDim2.new(0, 54, 0.5, -2)
	Controls.ProgressBarBg.Size = UDim2.new(1, -108, 0, 4)
	Controls.ProgressBarBg.ZIndex = 104
	Controls.ProgressBarBg.Parent = r
end

do 
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 2)
	c.Parent = Controls.ProgressBarBg
end

Controls.ProgressBarFill = Instance.new("Frame")
Controls.ProgressBarFill.BackgroundColor3 = Colors.AccentColor
Controls.ProgressBarFill.BorderSizePixel = 0
Controls.ProgressBarFill.Position = UDim2.new(0, 0, 0, 0)
Controls.ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
Controls.ProgressBarFill.ZIndex = 105
Controls.ProgressBarFill.Parent = Controls.ProgressBarBg

do 
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 2)
	c.Parent = Controls.ProgressBarFill
end

Controls.ProgressKnob = Instance.new("Frame")
Controls.ProgressKnob.Name = "Knob"
Controls.ProgressKnob.BackgroundColor3 = Colors.FontColor
Controls.ProgressKnob.BorderSizePixel = 0
Controls.ProgressKnob.Position = UDim2.new(1, -5, 0.5, -5)
Controls.ProgressKnob.Size = UDim2.new(0, 10, 0, 10)
Controls.ProgressKnob.ZIndex = 106
Controls.ProgressKnob.Parent = Controls.ProgressBarFill

do 
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = Controls.ProgressKnob
end


Controls.MarkerContainer = Instance.new("Frame")
Controls.MarkerContainer.Name = "MarkerContainer"
Controls.MarkerContainer.BackgroundTransparency = 1
Controls.MarkerContainer.Position = UDim2.new(0, 0, 0, 0)
Controls.MarkerContainer.Size = UDim2.new(1, 0, 1, 0)
Controls.MarkerContainer.ZIndex = 107
Controls.MarkerContainer.Parent = Controls.ProgressBarBg


do 
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 8, 0, 26)
	row.Size = UDim2.new(1, -16, 0, 24)
	row.ZIndex = 104
	row.Parent = Controls.Frame
	
	
	local btns = Instance.new("Frame")
	btns.BackgroundTransparency = 1
	btns.Position = UDim2.new(0, 0, 0, 0)
	btns.Size = UDim2.new(0, 100, 1, 0)
	btns.ZIndex = 104
	btns.Parent = row
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 3)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = btns
	
	
	Controls.PlayPauseBtn = Instance.new("TextButton")
	Controls.PlayPauseBtn.Name = "PlayPause"
	Controls.PlayPauseBtn.BackgroundColor3 = Colors.MainColor
	Controls.PlayPauseBtn.BorderColor3 = Colors.OutlineColor
	Controls.PlayPauseBtn.Size = UDim2.new(0, 26, 0, 22)
	Controls.PlayPauseBtn.ZIndex = 104
	Controls.PlayPauseBtn.Text = ""
	Controls.PlayPauseBtn.Parent = btns
	
	
	Controls.StopBtn = Instance.new("TextButton")
	Controls.StopBtn.Name = "Stop"
	Controls.StopBtn.BackgroundColor3 = Colors.MainColor
	Controls.StopBtn.BorderColor3 = Colors.OutlineColor
	Controls.StopBtn.Size = UDim2.new(0, 26, 0, 22)
	Controls.StopBtn.ZIndex = 104
	Controls.StopBtn.Text = ""
	Controls.StopBtn.Parent = btns
	
	CreateIcon(Controls.StopBtn, "square", 11, UDim2.new(0.5, -5, 0.5, -5))
	
	
	Controls.RestartBtn = Instance.new("TextButton")
	Controls.RestartBtn.Name = "Restart"
	Controls.RestartBtn.BackgroundColor3 = Colors.MainColor
	Controls.RestartBtn.BorderColor3 = Colors.OutlineColor
	Controls.RestartBtn.Size = UDim2.new(0, 26, 0, 22)
	Controls.RestartBtn.ZIndex = 104
	Controls.RestartBtn.Text = ""
	Controls.RestartBtn.Parent = btns
	
	CreateIcon(Controls.RestartBtn, "rotate-ccw", 11, UDim2.new(0.5, -5, 0.5, -5))
	
	Controls.ControlsRow = row
	Controls.PlaybackBtns = btns
end


do
	local btns = Instance.new("Frame")
	btns.BackgroundTransparency = 1
	btns.Position = UDim2.new(1, -60, 0, 0)
	btns.Size = UDim2.new(0, 60, 1, 0)
	btns.ZIndex = 104
	btns.Parent = Controls.ControlsRow
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 3)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = btns
	
	
	Controls.LoopBtn = Instance.new("TextButton")
	Controls.LoopBtn.Name = "Loop"
	Controls.LoopBtn.BackgroundColor3 = Colors.MainColor
	Controls.LoopBtn.BorderColor3 = Colors.OutlineColor
	Controls.LoopBtn.Size = UDim2.new(0, 26, 0, 22)
	Controls.LoopBtn.ZIndex = 104
	Controls.LoopBtn.Text = ""
	Controls.LoopBtn.Parent = btns
	
	
	Controls.LoopIcon = CreateIcon(Controls.LoopBtn, "repeat", 11, UDim2.new(0.5, -5, 0.5, -5), false)
	
	
	if Controls.LoopIcon then
		if Controls.LoopIcon:IsA("ImageLabel") then
			Controls.LoopIcon.ImageColor3 = Colors.AccentColor
		elseif Controls.LoopIcon:IsA("TextLabel") then
			Controls.LoopIcon.TextColor3 = Colors.AccentColor
		end
	end
	
	
	Controls.SpeedBtn = Instance.new("TextButton")
	Controls.SpeedBtn.Name = "Speed"
	Controls.SpeedBtn.BackgroundColor3 = Colors.MainColor
	Controls.SpeedBtn.BorderColor3 = Colors.OutlineColor
	Controls.SpeedBtn.Size = UDim2.new(0, 26, 0, 22)
	Controls.SpeedBtn.ZIndex = 104
	Controls.SpeedBtn.Font = Font
	Controls.SpeedBtn.Text = "1x"
	Controls.SpeedBtn.TextColor3 = Colors.FontColor
	Controls.SpeedBtn.TextSize = 9
	Controls.SpeedBtn.TextStrokeTransparency = 0
	Controls.SpeedBtn.Parent = btns
end


do
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 8, 0, 52)
	row.Size = UDim2.new(1, -16, 0, 20)
	row.ZIndex = 104
	row.Parent = Controls.Frame
	
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.Size = UDim2.new(0, 40, 1, 0)
	lbl.ZIndex = 104
	lbl.Font = Font
	lbl.Text = "Speed:"
	lbl.TextColor3 = Colors.DisabledTextColor
	lbl.TextSize = 10
	lbl.TextStrokeTransparency = 0
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	Sliders.SpeedBg = Instance.new("Frame")
	Sliders.SpeedBg.BackgroundColor3 = Colors.OutlineColor
	Sliders.SpeedBg.BorderSizePixel = 0
	Sliders.SpeedBg.Position = UDim2.new(0, 48, 0.5, -3)
	Sliders.SpeedBg.Size = UDim2.new(1, -100, 0, 6)
	Sliders.SpeedBg.ZIndex = 104
	Sliders.SpeedBg.Parent = row
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 3)
	c.Parent = Sliders.SpeedBg
	
	Sliders.SpeedFill = Instance.new("Frame")
	Sliders.SpeedFill.BackgroundColor3 = Colors.AccentColor
	Sliders.SpeedFill.BorderSizePixel = 0
	Sliders.SpeedFill.Position = UDim2.new(0, 0, 0, 0)
	Sliders.SpeedFill.Size = UDim2.new(0.31, 0, 1, 0)
	Sliders.SpeedFill.ZIndex = 105
	Sliders.SpeedFill.Parent = Sliders.SpeedBg
	
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 3)
	fc.Parent = Sliders.SpeedFill
	
	Sliders.SpeedKnob = Instance.new("Frame")
	Sliders.SpeedKnob.BackgroundColor3 = Colors.FontColor
	Sliders.SpeedKnob.BorderSizePixel = 0
	Sliders.SpeedKnob.Position = UDim2.new(1, -5, 0.5, -5)
	Sliders.SpeedKnob.Size = UDim2.new(0, 10, 0, 10)
	Sliders.SpeedKnob.ZIndex = 106
	Sliders.SpeedKnob.Parent = Sliders.SpeedFill
	
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1, 0)
	kc.Parent = Sliders.SpeedKnob
	
	Sliders.SpeedValue = Instance.new("TextLabel")
	Sliders.SpeedValue.BackgroundTransparency = 1
	Sliders.SpeedValue.Position = UDim2.new(1, -48, 0, 0)
	Sliders.SpeedValue.Size = UDim2.new(0, 48, 1, 0)
	Sliders.SpeedValue.ZIndex = 104
	Sliders.SpeedValue.Font = Font
	Sliders.SpeedValue.Text = "1.00x"
	Sliders.SpeedValue.TextColor3 = Colors.FontColor
	Sliders.SpeedValue.TextSize = 11
	Sliders.SpeedValue.TextStrokeTransparency = 0
	Sliders.SpeedValue.TextXAlignment = Enum.TextXAlignment.Right
	Sliders.SpeedValue.Parent = row
end


do
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 8, 0, 74)
	row.Size = UDim2.new(1, -16, 0, 20)
	row.ZIndex = 104
	row.Parent = Controls.Frame
	
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.Size = UDim2.new(0, 40, 1, 0)
	lbl.ZIndex = 104
	lbl.Font = Font
	lbl.Text = "Zoom:"
	lbl.TextColor3 = Colors.DisabledTextColor
	lbl.TextSize = 10
	lbl.TextStrokeTransparency = 0
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	Sliders.ZoomBg = Instance.new("Frame")
	Sliders.ZoomBg.BackgroundColor3 = Colors.OutlineColor
	Sliders.ZoomBg.BorderSizePixel = 0
	Sliders.ZoomBg.Position = UDim2.new(0, 48, 0.5, -3)
	Sliders.ZoomBg.Size = UDim2.new(1, -100, 0, 6)
	Sliders.ZoomBg.ZIndex = 104
	Sliders.ZoomBg.Parent = row
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 3)
	c.Parent = Sliders.ZoomBg
	
	Sliders.ZoomFill = Instance.new("Frame")
	Sliders.ZoomFill.BackgroundColor3 = Colors.AccentColor
	Sliders.ZoomFill.BorderSizePixel = 0
	Sliders.ZoomFill.Position = UDim2.new(0, 0, 0, 0)
	Sliders.ZoomFill.Size = UDim2.new(0.71, 0, 1, 0)
	Sliders.ZoomFill.ZIndex = 105
	Sliders.ZoomFill.Parent = Sliders.ZoomBg
	
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 3)
	fc.Parent = Sliders.ZoomFill
	
	Sliders.ZoomKnob = Instance.new("Frame")
	Sliders.ZoomKnob.BackgroundColor3 = Colors.FontColor
	Sliders.ZoomKnob.BorderSizePixel = 0
	Sliders.ZoomKnob.Position = UDim2.new(1, -5, 0.5, -5)
	Sliders.ZoomKnob.Size = UDim2.new(0, 10, 0, 10)
	Sliders.ZoomKnob.ZIndex = 106
	Sliders.ZoomKnob.Parent = Sliders.ZoomFill
	
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1, 0)
	kc.Parent = Sliders.ZoomKnob
	
	Sliders.ZoomValue = Instance.new("TextLabel")
	Sliders.ZoomValue.BackgroundTransparency = 1
	Sliders.ZoomValue.Position = UDim2.new(1, -48, 0, 0)
	Sliders.ZoomValue.Size = UDim2.new(0, 48, 1, 0)
	Sliders.ZoomValue.ZIndex = 104
	Sliders.ZoomValue.Font = Font
	Sliders.ZoomValue.Text = "15.0"
	Sliders.ZoomValue.TextColor3 = Colors.FontColor
	Sliders.ZoomValue.TextSize = 11
	Sliders.ZoomValue.TextStrokeTransparency = 0
	Sliders.ZoomValue.TextXAlignment = Enum.TextXAlignment.Right
	Sliders.ZoomValue.Parent = row
end


do
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 8, 0, 96)
	row.Size = UDim2.new(1, -16, 0, 20)
	row.ZIndex = 104
	row.Parent = Controls.Frame
	
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.Size = UDim2.new(0, 35, 1, 0)
	lbl.ZIndex = 104
	lbl.Font = Font
	lbl.Text = "Time:"
	lbl.TextColor3 = Colors.DisabledTextColor
	lbl.TextSize = 10
	lbl.TextStrokeTransparency = 0
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	Controls.TimeCounter = Instance.new("TextLabel")
	Controls.TimeCounter.Name = "TimeCounter"
	Controls.TimeCounter.BackgroundColor3 = Colors.MainColor
	Controls.TimeCounter.BorderColor3 = Colors.OutlineColor
	Controls.TimeCounter.Position = UDim2.new(0, 35, 0, 0)
	Controls.TimeCounter.Size = UDim2.new(0, 80, 0, 18)
	Controls.TimeCounter.ZIndex = 104
	Controls.TimeCounter.Font = Font
	Controls.TimeCounter.Text = "0.00 / 0.00"
	Controls.TimeCounter.TextColor3 = Colors.FontColor
	Controls.TimeCounter.TextSize = 9
	Controls.TimeCounter.TextStrokeTransparency = 0
	Controls.TimeCounter.Parent = row
	
	Controls.PrecisionTimeLabel = Instance.new("TextLabel")
	Controls.PrecisionTimeLabel.Name = "PrecisionTime"
	Controls.PrecisionTimeLabel.BackgroundColor3 = Colors.MainColor
	Controls.PrecisionTimeLabel.BorderColor3 = Colors.OutlineColor
	Controls.PrecisionTimeLabel.Position = UDim2.new(0, 118, 0, 0)
	Controls.PrecisionTimeLabel.Size = UDim2.new(0, 60, 0, 18)
	Controls.PrecisionTimeLabel.ZIndex = 104
	Controls.PrecisionTimeLabel.Font = Font
	Controls.PrecisionTimeLabel.Text = "0.000s"
	Controls.PrecisionTimeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	Controls.PrecisionTimeLabel.TextSize = 9
	Controls.PrecisionTimeLabel.TextStrokeTransparency = 0
	Controls.PrecisionTimeLabel.Parent = row
	
	Controls.FPSBtn = Instance.new("TextButton")
	Controls.FPSBtn.Name = "FPSBtn"
	Controls.FPSBtn.BackgroundColor3 = Colors.MainColor
	Controls.FPSBtn.BorderColor3 = Colors.OutlineColor
	Controls.FPSBtn.Position = UDim2.new(1, -45, 0, 0)
	Controls.FPSBtn.Size = UDim2.new(0, 45, 0, 18)
	Controls.FPSBtn.ZIndex = 104
	Controls.FPSBtn.Font = Font
	Controls.FPSBtn.Text = "60 FPS"
	Controls.FPSBtn.TextColor3 = Colors.AccentColor
	Controls.FPSBtn.TextSize = 8
	Controls.FPSBtn.TextStrokeTransparency = 0
	Controls.FPSBtn.Parent = row
end


do
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 8, 0, 122)
	row.Size = UDim2.new(1, -16, 0, 60)
	row.ZIndex = 104
	row.Parent = Controls.Frame
	
	
	local div = Instance.new("Frame")
	div.BackgroundColor3 = Colors.OutlineColor
	div.BorderSizePixel = 0
	div.Position = UDim2.new(0, 0, 0, 0)
	div.Size = UDim2.new(1, 0, 0, 1)
	div.ZIndex = 104
	div.Parent = row
	
	
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0, 0, 0, 4)
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.ZIndex = 104
	lbl.Font = Font
	lbl.Text = "Parry Builder"
	lbl.TextColor3 = Colors.AccentColor
	lbl.TextSize = 10
	lbl.TextStrokeTransparency = 0
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	
	
	local btnContainer = Instance.new("Frame")
	btnContainer.BackgroundColor3 = Colors.Black
	btnContainer.BackgroundTransparency = 0.6
	btnContainer.BorderSizePixel = 0
	btnContainer.Position = UDim2.new(0, 0, 0, 20)
	btnContainer.Size = UDim2.new(1, 0, 0, 36)
	btnContainer.ZIndex = 104
	btnContainer.Parent = row
	
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 4)
	bc.Parent = btnContainer
	
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.Padding = UDim.new(0, 4)
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.Parent = btnContainer
	
	
	local function createGridBtn(name, text, color, isActive)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.BackgroundColor3 = isActive and color or Colors.OutlineColor
		btn.BackgroundTransparency = 0.5
		btn.BorderSizePixel = 0
		btn.Size = UDim2.new(0, 46, 0, 26)
		btn.ZIndex = 105
		btn.Font = Font
		btn.Text = text
		btn.TextColor3 = Colors.FontColor
		btn.TextSize = 9
		btn.TextStrokeTransparency = 0
		btn.Parent = btnContainer
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = btn
		return btn
	end
	
	Controls.AddMarkerBtn = createGridBtn("AddMarker", "+ Parry", Color3.fromRGB(0, 255, 100), false)
	Controls.AddDodgeBtn = createGridBtn("AddDodge", "+ Dodge", Color3.fromRGB(255, 180, 0), false)
	Controls.AddRedBtn = createGridBtn("AddRed", "+ Red", Color3.fromRGB(190, 60, 255), false)
	Controls.ClearMarkersBtn = createGridBtn("Clear", "Clear", Color3.fromRGB(255, 100, 100), false)
	Controls.ExportMarkersBtn = createGridBtn("Export", "Export", Colors.AccentColor, false)
	Controls.AddToTableBtn = createGridBtn("AddTable", "+ Table", Color3.fromRGB(100, 200, 255), false)
	Controls.ExportTableBtn = createGridBtn("ExportAll", "Export All", Color3.fromRGB(100, 255, 100), false)
	
	
	Controls.TableCountLabel = Instance.new("TextLabel")
	Controls.TableCountLabel.BackgroundTransparency = 1
	Controls.TableCountLabel.Position = UDim2.new(1, -50, 0, 4)
	Controls.TableCountLabel.Size = UDim2.new(0, 50, 0, 14)
	Controls.TableCountLabel.ZIndex = 104
	Controls.TableCountLabel.Font = Font
	Controls.TableCountLabel.Text = "0 in table"
	Controls.TableCountLabel.TextColor3 = Colors.DisabledTextColor
	Controls.TableCountLabel.TextSize = 8
	Controls.TableCountLabel.TextStrokeTransparency = 0
	Controls.TableCountLabel.TextXAlignment = Enum.TextXAlignment.Right
	Controls.TableCountLabel.Parent = row
end


do
	local tipFrame = Instance.new("Frame")
	tipFrame.BackgroundTransparency = 1
	tipFrame.Position = UDim2.new(0, 8, 0, 185)
	tipFrame.Size = UDim2.new(1, -16, 0, 40)
	tipFrame.ZIndex = 104
	tipFrame.Parent = Controls.Frame
	
	local tipLabel = Instance.new("TextLabel")
	tipLabel.BackgroundTransparency = 1
	tipLabel.Size = UDim2.new(1, 0, 1, 0)
	tipLabel.ZIndex = 104
	tipLabel.Font = Font
	tipLabel.Text = "Tip: Click markers to jump • Right-click to delete • Drag viewport to orbit"
	tipLabel.TextColor3 = Colors.DisabledTextColor
	tipLabel.TextSize = 9
	tipLabel.TextStrokeTransparency = 0
	tipLabel.TextWrapped = true
	tipLabel.TextYAlignment = Enum.TextYAlignment.Top
	tipLabel.Parent = tipFrame
end


local loggedAnimations = {}
local animationObjects = {}
local othersLoggedAnimations = {}
local othersAnimationObjects = {}
local playerGroups = {} 
local parentGroups = {} 
local isCopyingAsLink = false
local isAutoPreview = false
local isNameParenting = false
local isGroupByParent = false
local animationCount = 0
local othersAnimationCount = 0
local isMinimized = false
local originalSize = UI.Outer.Size
local currentPreviewHumanoid = nil
local currentPreviewTrack = nil
local currentPreviewAnimId = nil
local previewRotation = 0
local rotationConnection = nil
local progressConnection = nil
local isPaused = false
local isStopped = false
local isLooping = true
local animationSpeed = 1.0
local ANIMATION_FPS = LPH_ENCNUM(60)
local animationMarkers = {} 
local markerUIElements = {} 
local selectedMarker = nil 
local MARKER_TYPES = {
	{name = "Parry", color = Color3.fromRGB(0, 255, 100)},
	{name = "Dodge", color = Color3.fromRGB(255, 180, 0)},
	{name = "Red Counter", color = Color3.fromRGB(190, 60, 255)},
}
local parryTable = {} 
local isParryTableVisible = false
local ParryAddons = {}


do
	ParryAddons.ExportFormats = {}
	ParryAddons.Hooks = {
		onAnimationAdded = {},
		onExport = {},
		onMarkerAdded = {},
	}

	
	ParryAddons.ExportFormats["Default"] = {
		name = "Default",
		description = "Standard parry table format",
		export = function(entries)
			local lines = {}
			local lineCount = 0
			for animId, data in entries do
				local timings = {}
				local timingCount = 0
				for _, t in data.Timings or {} do
					timingCount += 1
					timings[timingCount] = string.format("%.4f", t.time)
				end
				local valueStr = table_concat(timings, ", ")
				
				local name = getConsistentAnimName(data.Name, data.ParentName, true)
				lineCount += 1
				if data.Dodge then
					lines[lineCount] = string.format('\t["rbxassetid://%s"] = { Name = "%s", Value = {%s}, Dodge = true },', animId, name, valueStr)
				else
					lines[lineCount] = string.format('\t["rbxassetid://%s"] = { Name = "%s", Value = {%s} },', animId, name, valueStr)
				end
			end
			return "{\n" .. table_concat(lines, "\n") .. "\n}"
		end
	}

	
	function ParryAddons.RegisterExportFormat(id, name, description, exportFunc)
		ParryAddons.ExportFormats[id] = {
			name = name,
			description = description,
			export = exportFunc
		}
	end

	function ParryAddons.RegisterHook(hookType, callback)
		if ParryAddons.Hooks[hookType] then
			table_insert(ParryAddons.Hooks[hookType], callback)
		end
	end

	function ParryAddons.RunHooks(hookType, ...)
		local hooks = ParryAddons.Hooks[hookType]
		if hooks then
			for _, callback in hooks do
				pcall(callback, ...)
			end
		end
	end
end


_G.oxyParryAddons = ParryAddons


local cameraOrbitX = 0 
local cameraOrbitY = 15 
local cameraZoom = 15 
local cameraTarget = Vector3.new(0, 3, 0) 
local isAutoRotate = false 
local isCameraDragging = false
local lastMousePosition = Vector2.new(0, 0)
local DEFAULT_ORBIT_X = 0
local DEFAULT_ORBIT_Y = 15
local DEFAULT_ZOOM = 15
local isGridEnabled = true
local gridFloor = nil 
local updateCameraPosition
local updateGridFloor

do
	updateCameraPosition = LPH_JIT(function()
		local orbitXRad = math.rad(cameraOrbitX)
		local orbitYRad = math.rad(cameraOrbitY)
		
		local x = cameraZoom * math.sin(orbitXRad) * math.cos(orbitYRad)
		local y = cameraZoom * math.sin(orbitYRad)
		local z = cameraZoom * math.cos(orbitXRad) * math.cos(orbitYRad)
		
		local cameraPos = cameraTarget + Vector3.new(x, y, z)
		Preview.Camera.CFrame = CFrame.lookAt(cameraPos, cameraTarget)
	end)
	
	updateGridFloor = function()
	if gridFloor then
		gridFloor:Destroy()
		gridFloor = nil
	end
	
	if not isGridEnabled then return end
	
	
	local floorBase = Instance.new("Part")
	floorBase.Name = "GridFloor"
	floorBase.Anchored = true
	floorBase.CanCollide = false
	floorBase.Size = Vector3.new(64, 0.2, 64)
	floorBase.Position = Vector3.new(0, -0.1, 0)
	floorBase.Color = Color3.fromRGB(91, 100, 112) 
	floorBase.Material = Enum.Material.Plastic
	floorBase.Transparency = 0
	
	
	local topTexture = Instance.new("Texture")
	topTexture.Face = Enum.NormalId.Top
	topTexture.Texture = "rbxassetid://6372755229" 
	topTexture.StudsPerTileU = 8
	topTexture.StudsPerTileV = 8
	topTexture.Transparency = 0.8
	topTexture.Parent = floorBase
	
	floorBase.Parent = Preview.WorldModel
	gridFloor = floorBase
end

	
	updateGridFloor()
end 


local function getMarkerColor(markerType)
	for _, mtype in MARKER_TYPES do
		if mtype.name == markerType then
			return mtype.color
		end
	end
	return Color3.fromRGB(255, 200, 0) 
end

local function clearMarkerUI()
	for _, element in markerUIElements do
		if element and element.Parent then
			element:Destroy()
		end
	end
	markerUIElements = {}
end

local function refreshMarkerUI()
	clearMarkerUI()
	
	if not currentPreviewAnimId or not currentPreviewTrack then return end
	
	local markers = animationMarkers[currentPreviewAnimId]
	if not markers then return end
	
	local animLength = currentPreviewTrack.Length
	if animLength <= 0 then return end
	
	for i, marker in markers do
		local progress = marker.time / animLength
		local markerColor = getMarkerColor(marker.type)
		
		
		local markerElement = Instance.new("Frame")
		markerElement.Name = "Marker_" .. i
		markerElement.BackgroundColor3 = markerColor
		markerElement.BorderSizePixel = 0
		markerElement.Position = UDim2.new(progress, -3, 0.5, -8)
		markerElement.Size = UDim2.new(0, 6, 0, 16)
		markerElement.ZIndex = 108
		markerElement.Parent = Controls.MarkerContainer
		
		local markerCorner = Instance.new("UICorner")
		markerCorner.CornerRadius = UDim.new(0, 2)
		markerCorner.Parent = markerElement
		
		
		local markerFrame = math.floor(marker.time * ANIMATION_FPS)
		local tooltip = Instance.new("TextLabel")
		tooltip.Name = "Tooltip"
		tooltip.BackgroundColor3 = Colors.BackgroundColor
		tooltip.BorderColor3 = markerColor
		tooltip.Position = UDim2.new(0.5, -40, 0, -22)
		tooltip.Size = UDim2.new(0, 80, 0, 18)
		tooltip.ZIndex = 120
		tooltip.Font = Font
		tooltip.Text = string.format("%s f%d %.3fs", marker.type, markerFrame, marker.time)
		tooltip.TextColor3 = markerColor
		tooltip.TextSize = 9
		tooltip.TextStrokeTransparency = 0
		tooltip.Visible = false
		tooltip.Parent = markerElement
		
		
		local markerBtn = Instance.new("TextButton")
		markerBtn.BackgroundTransparency = 1
		markerBtn.Position = UDim2.new(0, 0, 0, 0)
		markerBtn.Size = UDim2.new(1, 0, 1, 0)
		markerBtn.ZIndex = 109
		markerBtn.Text = ""
		markerBtn.Parent = markerElement
		
		
		markerBtn.MouseEnter:Connect(function()
			tooltip.Visible = true
		end)
		
		markerBtn.MouseLeave:Connect(function()
			tooltip.Visible = false
		end)
		
		
		markerBtn.MouseButton2Click:Connect(function()
			if currentPreviewAnimId and animationMarkers[currentPreviewAnimId] then
				table.remove(animationMarkers[currentPreviewAnimId], i)
				refreshMarkerUI()
			end
		end)
		
		
		markerBtn.MouseButton1Click:Connect(function()
			if currentPreviewTrack then
				currentPreviewTrack.TimePosition = marker.time
			end
		end)
		
		table_insert(markerUIElements, markerElement)
	end
end

local function addMarkerOfType(markerType)
	if not currentPreviewAnimId or not currentPreviewTrack then return end
	
	local currentTime = currentPreviewTrack.TimePosition
	
	if not animationMarkers[currentPreviewAnimId] then
		animationMarkers[currentPreviewAnimId] = {}
	end
	
	
	table_insert(animationMarkers[currentPreviewAnimId], {
		time = currentTime, 
		type = markerType,
		label = string.format("%s @ %.3fs", markerType, currentTime)
	})
	
	
	table.sort(animationMarkers[currentPreviewAnimId], function(a, b)
		return a.time < b.time
	end)
	
	
	refreshMarkerUI()
	
	
	ParryAddons.RunHooks("onMarkerAdded", currentPreviewAnimId, markerType, currentTime)
	
	if Preview.InfoLabel then
		Preview.InfoLabel.Text = string.format("%s marker added @ %.3fs", markerType, currentTime)
	end
end



local function clearAllMarkers()
	if currentPreviewAnimId then
		animationMarkers[currentPreviewAnimId] = {}
		refreshMarkerUI()
	end
end


updateLoadingProgress(0.4, LPH_ENCSTR("Setting up export functions..."))
task.wait()

local function exportMarkersToLua()
	if not currentPreviewAnimId then
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "No animation loaded"
		end
		return
	end
	
	local markers = animationMarkers[currentPreviewAnimId]
	if not markers or #markers == 0 then
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "No markers to export"
		end
		return
	end
	
	
	local markersByType = {}
	for _, marker in markers do
		if not markersByType[marker.type] then
			markersByType[marker.type] = {}
		end
		table_insert(markersByType[marker.type], marker.time)
	end
	
	
	local hasDodge = markersByType["Dodge"] and #markersByType["Dodge"] > 0
	
	local typeOrder = {"Parry", "Dodge",}
	local allTimes = {}
	local timeCount = 0
	for _, typeName in typeOrder do
		local times = markersByType[typeName]
		if times then
			for _, t in times do
				timeCount += 1
				allTimes[timeCount] = string.format("%.4f", t)
			end
		end
	end
	
	local valueStr = table_concat(allTimes, ", ")
	
	
	local animData = animationObjects[tonumber(currentPreviewAnimId)] or othersAnimationObjects[tonumber(currentPreviewAnimId)]
	local animName = ""
	if animData then
		animName = getConsistentAnimName(animData.Name, animData.ParentName, true)
	end
	
	local output
	if hasDodge then
		output = string.format('[rbxassetid://%s] = { Name="%s", Value={%s}, Dodge=true }', currentPreviewAnimId, animName, valueStr)
	else
		output = string.format('[rbxassetid://%s] = { Name="%s", Value={%s} }', currentPreviewAnimId, animName, valueStr)
	end
	
	
	if setclipboard then
		setclipboard(output)
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Exported to clipboard!"
		end
	elseif toclipboard then
		toclipboard(output)
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Exported to clipboard!"
		end
	else
		
		print("=== MARKER EXPORT ===")
		print(output)
		print("=====================")
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Printed to console (no clipboard)"
		end
	end
end


local function updateTableCountLabel()
	local count = 0
	for _ in parryTable do
		count += 1
	end
	Controls.TableCountLabel.Text = count .. " anim" .. (count == 1 and "" or "s")
end

local function addToParryTable()
	if not currentPreviewAnimId then
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "No animation loaded"
		end
		return
	end
	
	local markers = animationMarkers[currentPreviewAnimId]
	if not markers or #markers == 0 then
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Add markers first!"
		end
		return
	end
	
	local animData = animationObjects[tonumber(currentPreviewAnimId)] or othersAnimationObjects[tonumber(currentPreviewAnimId)]
	local animName = ""
	local parentName = nil
	if animData then
		animName = animData.Name or ""
		parentName = animData.ParentName
	end
	
	
	local hasDodge = false
	local hasRed = false
	local timings = {}
	local timingCount = 0
	for _, marker in markers do
		timingCount += 1
		timings[timingCount] = {time = marker.time, type = marker.type}
		if marker.type == "Dodge" then
			hasDodge = true
		elseif marker.type == "Red Counter" then
			hasRed = true
		end
	end
	
	parryTable[currentPreviewAnimId] = {
		Name = animName,
		ParentName = parentName,
		Timings = timings,
		Dodge = hasDodge,
		RedCounter = hasRed
	}
	
	updateTableCountLabel()
	
	
	ParryAddons.RunHooks("onAnimationAdded", currentPreviewAnimId, parryTable[currentPreviewAnimId])
	
	if Preview.InfoLabel then
		Preview.InfoLabel.Text = "Added to parry table!"
	end
end

local function clearParryTable()
	parryTable = {}
	updateTableCountLabel()
	if Preview.InfoLabel then
		Preview.InfoLabel.Text = "Parry table cleared"
	end
end

local function exportParryTable(formatId)
	if next(parryTable) == nil then
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Parry table is empty"
		end
		return
	end
	
	formatId = formatId or "Default"
	local format = ParryAddons.ExportFormats[formatId]
	if not format then
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Unknown export format"
		end
		return
	end
	
	
	ParryAddons.RunHooks("onExport", parryTable, formatId)
	
	local output = format.export(parryTable)
	
	if setclipboard then
		setclipboard(output)
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Table exported to clipboard!"
		end
	elseif toclipboard then
		toclipboard(output)
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Table exported to clipboard!"
		end
	else
		print("=== PARRY TABLE EXPORT ===")
		print(output)
		print("==========================")
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Printed to console"
		end
	end
end

local function updatePlayPauseIcon()
	for _, child in Controls.PlayPauseBtn:GetChildren() do
		if child:IsA("ImageLabel") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if isPaused or isStopped then
		CreateIcon(Controls.PlayPauseBtn, "play", 14, UDim2.new(0.5, -7, 0.5, -7))
	else
		CreateIcon(Controls.PlayPauseBtn, "pause", 14, UDim2.new(0.5, -7, 0.5, -7))
	end
end

updatePlayPauseIcon()

local function createDummyRig(existingClone)
	local dummyCharacter
	
	if existingClone then
		
		dummyCharacter = existingClone:Clone()
	else
		
		local character = LocalPlayer.Character
		if not character then return nil end
		
		character.Archivable = true
		dummyCharacter = character:Clone()
		character.Archivable = false
	end
	
	if not dummyCharacter.PrimaryPart then
		local hrp = dummyCharacter:FindFirstChild("HumanoidRootPart")
		if hrp then
			dummyCharacter.PrimaryPart = hrp
		end
	end
	
	
	for _, desc in dummyCharacter:GetDescendants() do
		if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
			desc:Destroy()
		elseif desc:IsA("Humanoid") then
			desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		elseif desc:IsA("BillboardGui") or desc:IsA("Sound") then
			desc:Destroy()
		end
		
	end
	
	local animate = dummyCharacter:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	
	return dummyCharacter
end

local function previewAnimation(animId, characterClone)
	
	for _, child in Preview.WorldModel:GetChildren() do
		if child:IsA("Model") or (child:IsA("Part") and child.Name ~= "GridFloor") then
			child:Destroy()
		end
	end
	
	if currentPreviewTrack then
		currentPreviewTrack:Stop()
		currentPreviewTrack = nil
	end
	
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end
	
	if progressConnection then
		progressConnection:Disconnect()
		progressConnection = nil
	end
	
	isPaused = false
	isStopped = false
	updatePlayPauseIcon()
	
	local dummyRig = createDummyRig(characterClone)
	if not dummyRig then return end
	
	local humanoid = dummyRig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if dummyRig:FindFirstChild("HumanoidRootPart") then
			pcall(function()
				dummyRig:ScaleTo(1.8)
			end)
		end
	end
	
	dummyRig.Parent = Preview.WorldModel
	
	Preview.Camera.CameraSubject = dummyRig
	Preview.Camera.FieldOfView = 70
	Preview.Camera.CameraType = Enum.CameraType.Track
	
	if not humanoid then return end
	
	currentPreviewHumanoid = humanoid
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local animationObject = Instance.new("Animation")
	animationObject.AnimationId = "rbxassetid://" .. animId
	
	local success, result = pcall(function()
		return animator:LoadAnimation(animationObject)
	end)
	
	if success and result then
		currentPreviewTrack = result
		currentPreviewAnimId = animId
		result:Play()
		result.Looped = isLooping
		result:AdjustSpeed(animationSpeed)
		
		if Preview.InfoLabel then
			Preview.InfoLabel.Text = "Playing ID: " .. animId
		end
		
		progressConnection = RunService.RenderStepped:Connect(LPH_JIT(function()
			if currentPreviewTrack and currentPreviewTrack.Length > 0 then
				local progress = currentPreviewTrack.TimePosition / currentPreviewTrack.Length
				Controls.ProgressBarFill.Size = UDim2.new(progress, 0, 1, 0)
				
				
				local currentTime = currentPreviewTrack.TimePosition
				local totalTime = currentPreviewTrack.Length
				
				local function formatTime(t)
					local mins = math.floor(t / 60)
					local secs = t % 60
					return string.format("%02d:%05.2f", mins, secs)
				end
				
				Controls.CurrentTimeLabel.Text = formatTime(currentTime)
				Controls.TotalTimeLabel.Text = formatTime(totalTime)
				
				
				Controls.TimeCounter.Text = string.format("%.2f / %.2f", currentTime, totalTime)
				
				
				Controls.PrecisionTimeLabel.Text = string.format("%.3fs", currentTime)
			end
		end))
		
		
		task.defer(function()
			refreshMarkerUI()
		end)
	end
	
	animationObject:Destroy()
	
	
	if dummyRig and dummyRig.PrimaryPart then
		dummyRig:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, math.pi, 0))
	end
	
	
	cameraTarget = Vector3.new(0, 3, 0)
	updateCameraPosition()
	
	rotationConnection = RunService.RenderStepped:Connect(LPH_JIT(function()
		if dummyRig and dummyRig.Parent == Preview.WorldModel and dummyRig.PrimaryPart then
			
			dummyRig:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, math.pi, 0))
			
			
			if isAutoRotate and not isCameraDragging then
				cameraOrbitX = cameraOrbitX + 0.3
				updateCameraPosition()
			end
		end
	end))
end



local function getOrCreateParentGroup(parentName, containerParent, groupsTable)
	local groupKey = parentName or "Ungrouped"
	local targetGroupsTable = groupsTable or parentGroups
	local targetContainer = containerParent or UI.ScrollFrame
	local isNested = containerParent ~= nil
	
	if targetGroupsTable[groupKey] then
		return targetGroupsTable[groupKey]
	end
	
	
	local GroupFrame = Instance.new("Frame")
	GroupFrame.Name = "ParentGroup_" .. groupKey
	GroupFrame.BackgroundColor3 = isNested and Colors.BackgroundColor or Colors.Black
	GroupFrame.BorderSizePixel = 0
	GroupFrame.Size = UDim2.new(1, isNested and 0 or -8, 0, 28)
	GroupFrame.ZIndex = 5
	GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
	GroupFrame.Parent = targetContainer
	
	local GroupInner = Instance.new("Frame")
	GroupInner.BackgroundColor3 = isNested and Colors.BackgroundColor or Colors.MainColor
	GroupInner.BorderColor3 = Colors.OutlineColor
	GroupInner.BorderMode = Enum.BorderMode.Inset
	GroupInner.Size = UDim2.new(1, 0, 1, 0)
	GroupInner.AutomaticSize = Enum.AutomaticSize.Y
	GroupInner.ZIndex = 6
	GroupInner.Parent = GroupFrame
	
	local GroupContent = Instance.new("Frame")
	GroupContent.BackgroundTransparency = 1
	GroupContent.Size = UDim2.new(1, 0, 0, 0)
	GroupContent.AutomaticSize = Enum.AutomaticSize.Y
	GroupContent.ZIndex = 7
	GroupContent.Parent = GroupInner
	
	local GroupLayout = Instance.new("UIListLayout")
	GroupLayout.Padding = UDim.new(0, 0)
	GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	GroupLayout.Parent = GroupContent
	
	
	local Header = Instance.new("TextButton")
	Header.Name = "Header"
	Header.BackgroundColor3 = isNested and Colors.MainColor or Colors.BackgroundColor
	Header.BorderSizePixel = 0
	Header.Size = UDim2.new(1, 0, 0, isNested and 28 or 32)
	Header.ZIndex = 8
	Header.Text = ""
	Header.AutoButtonColor = false
	Header.LayoutOrder = 0
	Header.Parent = GroupContent
	
	
	local FolderIcon = CreateIcon(Header, "folder", isNested and 14 or 16, UDim2.new(0, 6, 0, isNested and 7 or 8))
	
	
	local ExpandIcon = CreateIcon(Header, "chevron-right", isNested and 12 or 14, UDim2.new(0, isNested and 24 or 26, 0, isNested and 8 or 9))
	
	
	local ParentNameLabel = Instance.new("TextLabel")
	ParentNameLabel.Name = "ParentName"
	ParentNameLabel.BackgroundTransparency = 1
	ParentNameLabel.Size = UDim2.new(1, -100, 0, isNested and 28 or 16)
	ParentNameLabel.Position = UDim2.new(0, isNested and 40 or 44, 0, isNested and 0 or 3)
	ParentNameLabel.ZIndex = 9
	ParentNameLabel.Font = Font
	ParentNameLabel.Text = groupKey
	ParentNameLabel.TextColor3 = Colors.FontColor
	ParentNameLabel.TextSize = isNested and 12 or 13
	ParentNameLabel.TextStrokeTransparency = 0
	ParentNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	ParentNameLabel.Parent = Header
	
	
	local CountLabel = Instance.new("TextLabel")
	CountLabel.Name = "CountLabel"
	CountLabel.BackgroundTransparency = 1
	CountLabel.Size = UDim2.new(0, 60, 0, isNested and 28 or 12)
	CountLabel.Position = isNested and UDim2.new(1, -65, 0, 0) or UDim2.new(0, 44, 0, 18)
	CountLabel.ZIndex = 9
	CountLabel.Font = Font
	CountLabel.Text = "0"
	CountLabel.TextColor3 = Colors.DisabledTextColor
	CountLabel.TextSize = isNested and 11 or 10
	CountLabel.TextStrokeTransparency = 0
	CountLabel.TextXAlignment = isNested and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	CountLabel.Parent = Header
	
	
	local AnimContainer = Instance.new("Frame")
	AnimContainer.Name = "AnimContainer"
	AnimContainer.BackgroundTransparency = 1
	AnimContainer.Size = UDim2.new(1, 0, 0, 0)
	AnimContainer.AutomaticSize = Enum.AutomaticSize.None
	AnimContainer.ZIndex = 7
	AnimContainer.LayoutOrder = 1
	AnimContainer.ClipsDescendants = true
	AnimContainer.Visible = false
	AnimContainer.Parent = GroupContent
	
	local AnimLayout = Instance.new("UIListLayout")
	AnimLayout.Padding = UDim.new(0, 2)
	AnimLayout.SortOrder = Enum.SortOrder.LayoutOrder
	AnimLayout.Parent = AnimContainer
	
	local AnimPadding = Instance.new("UIPadding")
	AnimPadding.PaddingTop = UDim.new(0, 4)
	AnimPadding.PaddingBottom = UDim.new(0, 4)
	AnimPadding.PaddingLeft = UDim.new(0, 4)
	AnimPadding.PaddingRight = UDim.new(0, 4)
	AnimPadding.Parent = AnimContainer
	
	local groupData = {
		Frame = GroupFrame,
		ContentFrame = GroupContent,
		Header = Header,
		AnimContainer = AnimContainer,
		AnimLayout = AnimLayout,
		CountLabel = CountLabel,
		ExpandIcon = ExpandIcon,
		FolderIcon = FolderIcon,
		AnimCount = 0,
		IsExpanded = false,
		IsNested = isNested
	}
	
	
	local chevronPos = isNested and UDim2.new(0, 24, 0, 8) or UDim2.new(0, 26, 0, 9)
	local chevronSize = isNested and 12 or 14
	
	TrackConnection(Header.MouseButton1Click:Connect(function()
		groupData.IsExpanded = not groupData.IsExpanded
		
		if groupData.IsExpanded then
			AnimContainer.Visible = true
			AnimContainer.AutomaticSize = Enum.AutomaticSize.Y
			groupData.ExpandIcon = ReplaceIcon(Header, "chevron-down", chevronSize, chevronPos)
		else
			AnimContainer.Visible = false
			AnimContainer.AutomaticSize = Enum.AutomaticSize.None
			AnimContainer.Size = UDim2.new(1, 0, 0, 0)
			groupData.ExpandIcon = ReplaceIcon(Header, "chevron-right", chevronSize, chevronPos)
		end
	end))
	
	
	local hoverColor = isNested and Color3.fromRGB(40, 40, 40) or Colors.MainColor
	local normalColor = isNested and Colors.MainColor or Colors.BackgroundColor
	
	TrackConnection(Header.MouseEnter:Connect(function()
		Header.BackgroundColor3 = hoverColor
	end))
	
	TrackConnection(Header.MouseLeave:Connect(function()
		Header.BackgroundColor3 = normalColor
	end))
	
	
	TrackConnection(Header.MouseButton2Click:Connect(function()
		local mouse = Players.LocalPlayer:GetMouse()
		clearContextMenu()
		
		local isIgnored = ignoredParents[groupKey]
		addContextMenuItem(isIgnored and "Unignore Parent" or "Ignore Parent", function()
			if isIgnored then
				ignoredParents[groupKey] = nil
			else
				ignoredParents[groupKey] = true
			end
			updateIgnoredCount()
			
			Header.BackgroundColor3 = isIgnored and normalColor or Color3.fromRGB(60, 30, 30)
			task.delay(0.3, function()
				Header.BackgroundColor3 = normalColor
			end)
		end, isIgnored and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
		
		showContextMenu(mouse.X, mouse.Y)
	end))
	
	targetGroupsTable[groupKey] = groupData
	return groupData
end


local function getOrCreatePlayerGroup(playerName, userId)
	if playerGroups[playerName] then
		return playerGroups[playerName]
	end
	
	
	local isNPC = userId == 0 or string_sub(playerName, 1, 5) == "[NPC]"
	local displayName = isNPC and string_gsub(playerName, "^%[NPC%] ", "") or playerName
	local nameColor = isNPC and Colors.NPCNameColor or Colors.PlayerNameColor
	local profileUserId = isNPC and NPC_PROFILE_USER_ID or userId
	
	
	local GroupFrame = Instance.new("Frame")
	GroupFrame.Name = "PlayerGroup_" .. playerName
	GroupFrame.BackgroundColor3 = Colors.Black
	GroupFrame.BorderSizePixel = 0
	GroupFrame.Size = UDim2.new(1, -8, 0, 36) 
	GroupFrame.ZIndex = 5
	GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
	GroupFrame.Parent = UI.OthersScrollFrame
	
	local GroupInner = Instance.new("Frame")
	GroupInner.BackgroundColor3 = Colors.MainColor
	GroupInner.BorderColor3 = Colors.OutlineColor
	GroupInner.BorderMode = Enum.BorderMode.Inset
	GroupInner.Size = UDim2.new(1, 0, 1, 0)
	GroupInner.AutomaticSize = Enum.AutomaticSize.Y
	GroupInner.ZIndex = 6
	GroupInner.Parent = GroupFrame
	
	local GroupContent = Instance.new("Frame")
	GroupContent.BackgroundTransparency = 1
	GroupContent.Size = UDim2.new(1, 0, 0, 0)
	GroupContent.AutomaticSize = Enum.AutomaticSize.Y
	GroupContent.ZIndex = 7
	GroupContent.Parent = GroupInner
	
	local GroupLayout = Instance.new("UIListLayout")
	GroupLayout.Padding = UDim.new(0, 0)
	GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	GroupLayout.Parent = GroupContent
	
	
	local Header = Instance.new("TextButton")
	Header.Name = "Header"
	Header.BackgroundColor3 = Colors.BackgroundColor
	Header.BorderSizePixel = 0
	Header.Size = UDim2.new(1, 0, 0, 36)
	Header.ZIndex = 8
	Header.Text = ""
	Header.AutoButtonColor = false
	Header.LayoutOrder = 0
	Header.Parent = GroupContent
	
	
	local ProfilePic = Instance.new("ImageLabel")
	ProfilePic.Name = "ProfilePic"
	ProfilePic.BackgroundColor3 = Colors.OutlineColor
	ProfilePic.BorderSizePixel = 0
	ProfilePic.Size = UDim2.new(0, 28, 0, 28)
	ProfilePic.Position = UDim2.new(0, 4, 0, 4)
	ProfilePic.ZIndex = 9
	ProfilePic.ScaleType = Enum.ScaleType.Fit
	ProfilePic.Parent = Header
	
	local ProfileCorner = Instance.new("UICorner")
	ProfileCorner.CornerRadius = UDim.new(0, 4)
	ProfileCorner.Parent = ProfilePic
	
	
	task.spawn(function()
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(profileUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if success and result then
			ProfilePic.Image = result
		end
	end)
	
	
	local ExpandIcon = CreateIcon(Header, "chevron-right", 14, UDim2.new(0, 36, 0, 11))
	
	
	local PlayerNameLabel = Instance.new("TextLabel")
	PlayerNameLabel.Name = "PlayerName"
	PlayerNameLabel.BackgroundTransparency = 1
	PlayerNameLabel.Size = UDim2.new(1, -100, 0, 16)
	PlayerNameLabel.Position = UDim2.new(0, 54, 0, 4)
	PlayerNameLabel.ZIndex = 9
	PlayerNameLabel.Font = Font
	PlayerNameLabel.Text = (isNPC and "[NPC] " or "") .. displayName
	PlayerNameLabel.TextColor3 = nameColor
	PlayerNameLabel.TextSize = 13
	PlayerNameLabel.TextStrokeTransparency = 0
	PlayerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	PlayerNameLabel.Parent = Header
	
	
	local CountLabel = Instance.new("TextLabel")
	CountLabel.Name = "CountLabel"
	CountLabel.BackgroundTransparency = 1
	CountLabel.Size = UDim2.new(1, -54, 0, 14)
	CountLabel.Position = UDim2.new(0, 54, 0, 20)
	CountLabel.ZIndex = 9
	CountLabel.Font = Font
	CountLabel.Text = "0 animations"
	CountLabel.TextColor3 = Colors.DisabledTextColor
	CountLabel.TextSize = 11
	CountLabel.TextStrokeTransparency = 0
	CountLabel.TextXAlignment = Enum.TextXAlignment.Left
	CountLabel.Parent = Header
	
	
	local AnimContainer = Instance.new("Frame")
	AnimContainer.Name = "AnimContainer"
	AnimContainer.BackgroundTransparency = 1
	AnimContainer.Size = UDim2.new(1, 0, 0, 0)
	AnimContainer.AutomaticSize = Enum.AutomaticSize.None
	AnimContainer.ZIndex = 7
	AnimContainer.LayoutOrder = 1
	AnimContainer.ClipsDescendants = true
	AnimContainer.Visible = false
	AnimContainer.Parent = GroupContent
	
	local AnimLayout = Instance.new("UIListLayout")
	AnimLayout.Padding = UDim.new(0, 2)
	AnimLayout.SortOrder = Enum.SortOrder.LayoutOrder
	AnimLayout.Parent = AnimContainer
	
	local AnimPadding = Instance.new("UIPadding")
	AnimPadding.PaddingTop = UDim.new(0, 4)
	AnimPadding.PaddingBottom = UDim.new(0, 4)
	AnimPadding.PaddingLeft = UDim.new(0, 4)
	AnimPadding.PaddingRight = UDim.new(0, 4)
	AnimPadding.Parent = AnimContainer
	
	local groupData = {
		Frame = GroupFrame,
		ContentFrame = GroupContent,
		Header = Header,
		AnimContainer = AnimContainer,
		AnimLayout = AnimLayout,
		CountLabel = CountLabel,
		ExpandIcon = ExpandIcon,
		AnimCount = 0,
		IsExpanded = false,
		UserId = userId,
		NestedParentGroups = {} 
	}
	
	
	local playerChevronPos = UDim2.new(0, 36, 0, 11)
	TrackConnection(Header.MouseButton1Click:Connect(function()
		groupData.IsExpanded = not groupData.IsExpanded
		
		if groupData.IsExpanded then
			AnimContainer.Visible = true
			AnimContainer.AutomaticSize = Enum.AutomaticSize.Y
			groupData.ExpandIcon = ReplaceIcon(Header, "chevron-down", 14, playerChevronPos)
		else
			AnimContainer.Visible = false
			AnimContainer.AutomaticSize = Enum.AutomaticSize.None
			AnimContainer.Size = UDim2.new(1, 0, 0, 0)
			groupData.ExpandIcon = ReplaceIcon(Header, "chevron-right", 14, playerChevronPos)
		end
	end))
	
	
	TrackConnection(Header.MouseEnter:Connect(function()
		Header.BackgroundColor3 = Colors.MainColor
	end))
	
	TrackConnection(Header.MouseLeave:Connect(function()
		Header.BackgroundColor3 = Colors.BackgroundColor
	end))
	
	
	TrackConnection(Header.MouseButton2Click:Connect(function()
		local mouse = Players.LocalPlayer:GetMouse()
		clearContextMenu()
		
		local isIgnored = ignoredPlayers[playerName]
		addContextMenuItem(isIgnored and "Unignore Player" or "Ignore Player", function()
			if isIgnored then
				ignoredPlayers[playerName] = nil
			else
				ignoredPlayers[playerName] = true
			end
			updateIgnoredCount()
			
			Header.BackgroundColor3 = isIgnored and Colors.BackgroundColor or Color3.fromRGB(60, 30, 30)
			task.delay(0.3, function()
				Header.BackgroundColor3 = Colors.BackgroundColor
			end)
		end, isIgnored and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
		
		showContextMenu(mouse.X, mouse.Y)
	end))
	
	playerGroups[playerName] = groupData
	return groupData
end

local function createAnimationEntry(animName, animId, isOther, playerName, userId, characterClone)
	local numericId = tonumber(animId:match("%d+"))
	
	
	local targetLoggedAnimations = isOther and othersLoggedAnimations or loggedAnimations
	local targetAnimationObjects = isOther and othersAnimationObjects or animationObjects
	local targetStatsLabel = isOther and UI.OthersStatsLabel or UI.StatsLabel
	
	
	local baseName, animParentName = animName, nil
	if type(animName) == "table" then
		baseName = animName.name
		animParentName = animName.parent
	else
		_, animParentName = findAnimationName(animId)
	end
	
	
	
	local playerGroup = nil
	local parentGroup = nil
	local targetParent = nil
	local targetListLayout = nil
	
	if isOther and playerName and userId then
		playerGroup = getOrCreatePlayerGroup(playerName, userId)
		
		
		if isGroupByParent then
			parentGroup = getOrCreateParentGroup(animParentName, playerGroup.AnimContainer, playerGroup.NestedParentGroups)
			targetParent = parentGroup.AnimContainer
			targetListLayout = parentGroup.AnimLayout
		else
			targetParent = playerGroup.AnimContainer
			targetListLayout = playerGroup.AnimLayout
		end
	elseif not isOther and isGroupByParent then
		parentGroup = getOrCreateParentGroup(animParentName)
		targetParent = parentGroup.AnimContainer
		targetListLayout = parentGroup.AnimLayout
	else
		targetParent = UI.ScrollFrame
		targetListLayout = UI.ListLayout
	end
	
	if targetLoggedAnimations[numericId] then
		return
	end
	
	targetLoggedAnimations[numericId] = true
	if isOther then
		othersAnimationCount = othersAnimationCount + 1
		targetStatsLabel.Text = "Logged: " .. othersAnimationCount
		
		
		if playerGroup then
			playerGroup.AnimCount = playerGroup.AnimCount + 1
			playerGroup.CountLabel.Text = playerGroup.AnimCount .. " animation" .. (playerGroup.AnimCount == 1 and "" or "s")
		end
		
		
		if parentGroup then
			parentGroup.AnimCount = parentGroup.AnimCount + 1
			parentGroup.CountLabel.Text = tostring(parentGroup.AnimCount)
		end
	else
		animationCount = animationCount + 1
		targetStatsLabel.Text = "Logged: " .. animationCount
		
		
		if parentGroup then
			parentGroup.AnimCount = parentGroup.AnimCount + 1
			parentGroup.CountLabel.Text = parentGroup.AnimCount .. " animation" .. (parentGroup.AnimCount == 1 and "" or "s")
		end
	end
	
	local EntryOuter = Instance.new("Frame")
	EntryOuter.BackgroundColor3 = Colors.Black
	EntryOuter.BorderSizePixel = 0
	EntryOuter.Size = UDim2.new(1, (isOther or isGroupByParent) and 0 or -8, 0, 60)
	EntryOuter.ZIndex = 5
	EntryOuter.Parent = targetParent
	
	local displayName = baseName
	if isNameParenting and animParentName then
		displayName = animParentName .. baseName
	end
	
	targetAnimationObjects[numericId] = {
		Name = baseName,
		ParentName = animParentName,
		Id = numericId,
		Frame = EntryOuter,
		PlayerName = playerName,
		PlayerGroup = playerGroup,
		ParentGroup = parentGroup,
		CharacterClone = characterClone 
	}
	
	local EntryInner = Instance.new("TextButton")
	EntryInner.BackgroundColor3 = Colors.MainColor
	EntryInner.BorderColor3 = Colors.OutlineColor
	EntryInner.BorderMode = Enum.BorderMode.Inset
	EntryInner.Size = UDim2.new(1, 0, 1, 0)
	EntryInner.ZIndex = 6
	EntryInner.Text = ""
	EntryInner.AutoButtonColor = false
	EntryInner.Parent = EntryOuter
	
	local EntryContent = Instance.new("Frame")
	EntryContent.BackgroundColor3 = Color3.new(1, 1, 1)
	EntryContent.BorderSizePixel = 0
	EntryContent.Position = UDim2.new(0, 1, 0, 1)
	EntryContent.Size = UDim2.new(1, -2, 1, -2)
	EntryContent.ZIndex = 7
	EntryContent.Parent = EntryInner
	
	local EntryGradient = Instance.new("UIGradient")
	EntryGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GetDarkerColor(Colors.MainColor)),
		ColorSequenceKeypoint.new(1, Colors.MainColor),
	})
	EntryGradient.Rotation = -90
	EntryGradient.Parent = EntryContent
	
	local CopyPathBtn = Instance.new("TextButton")
	CopyPathBtn.BackgroundTransparency = 1
	CopyPathBtn.Size = UDim2.new(0, 20, 0, 20)
	CopyPathBtn.Position = UDim2.new(1, -48, 0, 4)
	CopyPathBtn.ZIndex = 8
	CopyPathBtn.Text = ""
	CopyPathBtn.Parent = EntryContent
	
	local copyPathIcon = CreateIcon(CopyPathBtn, "copy", 14, UDim2.new(0, 3, 0, 3))
	
	local PreviewBtn = Instance.new("TextButton")
	PreviewBtn.BackgroundTransparency = 1
	PreviewBtn.Size = UDim2.new(0, 20, 0, 20)
	PreviewBtn.Position = UDim2.new(1, -26, 0, 4)
	PreviewBtn.ZIndex = 8
	PreviewBtn.Text = ""
	PreviewBtn.Parent = EntryContent
	
	local previewIcon = CreateIcon(PreviewBtn, "play", 14, UDim2.new(0, 3, 0, 3))
	
	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "AnimNameLabel"
	NameLabel.BackgroundTransparency = 1
	NameLabel.Size = UDim2.new(1, -60, 0, 16)
	NameLabel.Position = UDim2.new(0, 6, 0, 4)
	NameLabel.ZIndex = 8
	NameLabel.Font = Font
	NameLabel.Text = displayName
	NameLabel.TextColor3 = Colors.FontColor
	NameLabel.TextSize = 13
	NameLabel.TextStrokeTransparency = 0
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Parent = EntryContent
	
	local IdLabel = Instance.new("TextLabel")
	IdLabel.BackgroundTransparency = 1
	IdLabel.Size = UDim2.new(1, -12, 0, 14)
	IdLabel.Position = UDim2.new(0, 6, 0, 22)
	IdLabel.ZIndex = 8
	IdLabel.Font = Font
	IdLabel.Text = "ID: " .. numericId
	IdLabel.TextColor3 = Colors.DisabledTextColor
	IdLabel.TextSize = 12
	IdLabel.TextStrokeTransparency = 0
	IdLabel.TextXAlignment = Enum.TextXAlignment.Left
	IdLabel.Parent = EntryContent
	
	local CopyHint = Instance.new("TextLabel")
	CopyHint.BackgroundTransparency = 1
	CopyHint.Size = UDim2.new(1, -12, 0, 14)
	CopyHint.Position = UDim2.new(0, 6, 1, -18)
	CopyHint.ZIndex = 8
	CopyHint.Font = Font
	CopyHint.Text = isCopyingAsLink and "Click to copy link" or "Click to copy ID"
	CopyHint.TextColor3 = Colors.AccentColor
	CopyHint.TextSize = 11
	CopyHint.TextStrokeTransparency = 0
	CopyHint.TextXAlignment = Enum.TextXAlignment.Left
	CopyHint.Parent = EntryContent
	
	CopyPathBtn.MouseButton1Click:Connect(function()
		local fullPath = getAnimationFullPath(animId)
		if fullPath then
			setclipboard(fullPath)
			
			
			EntryInner.BorderColor3 = Color3.fromRGB(100, 255, 100)
			CopyHint.Text = "Path copied!"
			CopyHint.TextColor3 = Color3.fromRGB(100, 255, 100)
			
			task.wait(0.5)
			EntryInner.BorderColor3 = Colors.OutlineColor
			CopyHint.Text = isCopyingAsLink and "Click to copy link" or "Click to copy ID"
			CopyHint.TextColor3 = Colors.AccentColor
		else
			
			EntryInner.BorderColor3 = Color3.fromRGB(255, 100, 100)
			CopyHint.Text = "Path not found!"
			CopyHint.TextColor3 = Color3.fromRGB(255, 100, 100)
			
			task.wait(0.5)
			EntryInner.BorderColor3 = Colors.OutlineColor
			CopyHint.Text = isCopyingAsLink and "Click to copy link" or "Click to copy ID"
			CopyHint.TextColor3 = Colors.AccentColor
		end
	end)
	
	PreviewBtn.MouseButton1Click:Connect(function()
		Preview.Outer.Visible = true
		Preview.InfoLabel.Text = string.format("%s\nID: %d\nPlaying...", displayName, numericId)
		Preview.InfoLabel.TextColor3 = Colors.FontColor
		previewAnimation(numericId, characterClone)
	end)
	
	
	local function createLinoriaTooltip(text)
		local tooltipFrame = Instance.new("Frame")
		tooltipFrame.Name = "Tooltip"
		tooltipFrame.BackgroundColor3 = Colors.MainColor
		tooltipFrame.BorderColor3 = Colors.OutlineColor
		tooltipFrame.BorderMode = Enum.BorderMode.Outline
		tooltipFrame.ZIndex = 100
		tooltipFrame.Visible = false
		tooltipFrame.Parent = ScreenGui
		
		local tooltipLabel = Instance.new("TextLabel")
		tooltipLabel.Name = "Label"
		tooltipLabel.BackgroundTransparency = 1
		tooltipLabel.Position = UDim2.new(0, 4, 0, 2)
		tooltipLabel.ZIndex = 101
		tooltipLabel.Font = Font
		tooltipLabel.Text = text
		tooltipLabel.TextColor3 = Colors.FontColor
		tooltipLabel.TextSize = 13
		tooltipLabel.TextStrokeTransparency = 0
		tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
		tooltipLabel.AutomaticSize = Enum.AutomaticSize.XY
		tooltipLabel.Parent = tooltipFrame
		
		
		local textSize = TextService:GetTextSize(text, 13, Font, Vector2.new(math.huge, math.huge))
		tooltipFrame.Size = UDim2.new(0, textSize.X + 8, 0, textSize.Y + 4)
		
		return tooltipFrame
	end
	
	
	local previewTooltip = createLinoriaTooltip("Preview Animation")
	local copyPathTooltip = createLinoriaTooltip("Copy Full Path")
	
	
	local previewHoverThread = nil
	local previewIsHovering = false
	
	PreviewBtn.MouseEnter:Connect(function()
		if previewIcon then
			if previewIcon:IsA("ImageLabel") then
				previewIcon.ImageColor3 = Colors.AccentColor
			elseif previewIcon:IsA("TextLabel") then
				previewIcon.TextColor3 = Colors.AccentColor
			end
		end
		
		previewIsHovering = true
		
		previewHoverThread = task.spawn(function()
			local mouse = LocalPlayer:GetMouse()
			previewTooltip.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y + 12)
			previewTooltip.Visible = true
			
			
			while previewIsHovering do
				RunService.Heartbeat:Wait()
				previewTooltip.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y + 12)
			end
			previewTooltip.Visible = false
		end)
	end)
	
	PreviewBtn.MouseLeave:Connect(function()
		if previewIcon then
			if previewIcon:IsA("ImageLabel") then
				previewIcon.ImageColor3 = Colors.FontColor
			elseif previewIcon:IsA("TextLabel") then
				previewIcon.TextColor3 = Colors.FontColor
			end
		end
		
		previewIsHovering = false
		if previewHoverThread then
			task.cancel(previewHoverThread)
			previewHoverThread = nil
		end
		previewTooltip.Visible = false
	end)
	
	
	local copyPathHoverThread = nil
	local copyPathIsHovering = false
	
	CopyPathBtn.MouseEnter:Connect(function()
		if copyPathIcon then
			if copyPathIcon:IsA("ImageLabel") then
				copyPathIcon.ImageColor3 = Colors.AccentColor
			elseif copyPathIcon:IsA("TextLabel") then
				copyPathIcon.TextColor3 = Colors.AccentColor
			end
		end
		
		copyPathIsHovering = true
		
		copyPathHoverThread = task.spawn(function()
			local mouse = LocalPlayer:GetMouse()
			copyPathTooltip.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y + 12)
			copyPathTooltip.Visible = true
			
			
			while copyPathIsHovering do
				RunService.Heartbeat:Wait()
				copyPathTooltip.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y + 12)
			end
			copyPathTooltip.Visible = false
		end)
	end)
	
	CopyPathBtn.MouseLeave:Connect(function()
		if copyPathIcon then
			if copyPathIcon:IsA("ImageLabel") then
				copyPathIcon.ImageColor3 = Colors.FontColor
			elseif copyPathIcon:IsA("TextLabel") then
				copyPathIcon.TextColor3 = Colors.FontColor
			end
		end
		
		copyPathIsHovering = false
		if copyPathHoverThread then
			task.cancel(copyPathHoverThread)
			copyPathHoverThread = nil
		end
		copyPathTooltip.Visible = false
	end)
	
	
	EntryInner.MouseEnter:Connect(function()
		EntryInner.BorderColor3 = Colors.AccentColor
	end)
	
	EntryInner.MouseLeave:Connect(function()
		EntryInner.BorderColor3 = Colors.OutlineColor
	end)
	
	EntryInner.MouseButton1Click:Connect(function()
		local copyText = isCopyingAsLink 
			and "https://www.roblox.com/library/" .. numericId 
			or tostring(numericId)
		
		setclipboard(copyText)
		
		EntryInner.BorderColor3 = Color3.fromRGB(100, 255, 100)
		CopyHint.Text = "Copied!"
		CopyHint.TextColor3 = Color3.fromRGB(100, 255, 100)
		
		task.wait(0.5)
		EntryInner.BorderColor3 = Colors.OutlineColor
		CopyHint.Text = isCopyingAsLink and "Click to copy link" or "Click to copy ID"
		CopyHint.TextColor3 = Colors.AccentColor
	end)
	
	if isAutoPreview then
		Preview.Outer.Visible = true
		Preview.InfoLabel.Text = string.format("%s\nID: %d\nPlaying...", displayName, numericId)
		Preview.InfoLabel.TextColor3 = Colors.FontColor
		previewAnimation(numericId, characterClone)
	end
	
	
	if not isOther then
		UI.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UI.ListLayout.AbsoluteContentSize.Y + 8)
	end
end

local function onAnimationPlayed(animationTrack, isOther, playerName, userId, otherCharacter)
	local animation = animationTrack.Animation
	if not animation then return end
	
	local animationId = animation.AnimationId
	local numericId = getNumericId(animationId)

	local targetLoggedAnimations = isOther and othersLoggedAnimations or loggedAnimations
	local numericIdNum = numericId and tonumber(numericId)
	if numericIdNum and targetLoggedAnimations[numericIdNum] then
		return
	end
	
	
	local characterClone = nil
	if isOther and otherCharacter then
		local success, clone = pcall(function()
			otherCharacter.Archivable = true
			local cloned = otherCharacter:Clone()
			otherCharacter.Archivable = false
			return cloned
		end)
		if success and clone then
			characterClone = clone
			
			for _, desc in characterClone:GetDescendants() do
				if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
					desc:Destroy()
				elseif desc:IsA("Humanoid") then
					desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				elseif desc:IsA("BillboardGui") or desc:IsA("Sound") then
					desc:Destroy()
				end
				
			end
			local animate = characterClone:FindFirstChild("Animate")
			if animate then
				animate:Destroy()
			end
		end
	end
	
	
	task.defer(function()
		local animationName = animation.Name
		local parentName = nil
		
		
		local nameLen = animationName and #animationName or 0
		local isValid = nameLen >= 4 and animationName ~= "Animation"
		
		
		if not isValid then
			local foundName, foundParent = findAnimationName(animationId)
			local foundLen = foundName and #foundName or 0
			if foundLen >= 4 and foundName ~= "Animation" then
				animationName = foundName
				parentName = foundParent
			else
				
				local marketplaceName = fetchAnimationNameFromAsset(animationId)
				if marketplaceName and marketplaceName ~= "" then
					animationName = marketplaceName
					parentName = foundParent 
				elseif foundName then
					
					animationName = foundName
					parentName = foundParent
				else
					animationName = "Unknown Animation"
				end
			end
		else
			_, parentName = findAnimationName(animationId)
		end
		
		animationName = string_gsub(animationName, "%s+", "")
		
		
		if parentName and ignoredParents[parentName] then
			return 
		end
		
		if isOther and playerName and ignoredPlayers[playerName] then
			return 
		end
		
		createAnimationEntry({name = animationName, parent = parentName}, animationId, isOther, playerName, userId, characterClone)
	end)
end

local function trackPlayerAnimations()
	local player = LocalPlayer
	
	local function setupCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			TrackConnection(humanoid.AnimationPlayed:Connect(function(track)
				onAnimationPlayed(track, false, nil, nil)
			end))
		end
	end
	
	if player.Character then
		setupCharacter(player.Character)
	end
	
	TrackConnection(player.CharacterAdded:Connect(setupCharacter))
end

local function trackOtherPlayersAnimations()
	local function setupOtherPlayer(player)
		if player == LocalPlayer then return end
		
		local playerUserId = player.UserId
		local playerName = player.Name
		
		local function setupCharacter(character)
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid then
				TrackConnection(humanoid.AnimationPlayed:Connect(function(track)
					onAnimationPlayed(track, true, playerName, playerUserId, character)
				end))
			end
		end
		
		if player.Character then
			setupCharacter(player.Character)
		end
		
		TrackConnection(player.CharacterAdded:Connect(setupCharacter))
	end
	
	
	for _, player in Players:GetPlayers() do
		setupOtherPlayer(player)
	end
	
	
	TrackConnection(Players.PlayerAdded:Connect(setupOtherPlayer))
end


local trackedEntities = {} 

local function isPlayerCharacter(model)
	
	for _, player in Players:GetPlayers() do
		if player.Character == model then
			return true
		end
	end
	return false
end

local function trackEntityAnimations(humanoid)
	
	if trackedEntities[humanoid] then return end
	trackedEntities[humanoid] = true
	
	
	local character = humanoid.Parent
	if not character then return end
	
	
	if isPlayerCharacter(character) then return end
	
	
	local entityName = character:GetAttribute("FirstName") or character.Name or "Unknown Entity"
	
	
	humanoid.Destroying:Connect(function()
		trackedEntities[humanoid] = nil
	end)
	
	TrackConnection(humanoid.AnimationPlayed:Connect(function(track)
		
		local characterClone = nil
		pcall(function()
			character.Archivable = true
			characterClone = character:Clone()
			character.Archivable = false
			
			
			for _, desc in characterClone:GetDescendants() do
				if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
					desc:Destroy()
				elseif desc:IsA("Humanoid") then
					desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				elseif desc:IsA("BillboardGui") or desc:IsA("Sound") then
					desc:Destroy()
				end
				
			end
			local animate = characterClone:FindFirstChild("Animate")
			if animate then
				animate:Destroy()
			end
		end)
		
		onAnimationPlayed(track, true, "[NPC] " .. entityName, 0, characterClone)
	end))
end

local function trackAllEntities()
	
	for _, desc in Workspace:GetDescendants() do
		if desc:IsA("Humanoid") then
			task.spawn(trackEntityAnimations, desc)
		end
	end
	
	
	TrackConnection(Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("Humanoid") then
			
			task.delay(0.1, function()
				trackEntityAnimations(desc)
			end)
		end
	end))
end

TrackConnection(UI.PreviewButton.MouseButton1Click:Connect(function()
	Preview.Outer.Visible = not Preview.Outer.Visible
end))


TrackConnection(Preview.SnapBtn.MouseButton1Click:Connect(function()
	Preview.Outer.Position = PREVIEW_DEFAULT_POSITION
end))


do
	local isDraggingPreview = false
	local dragStartPos = nil
	local frameStartPos = nil
	
	TrackConnection(Preview.TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDraggingPreview = true
			dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
			frameStartPos = Preview.Outer.Position
		end
	end))
	
	TrackConnection(Preview.TitleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDraggingPreview = false
		end
	end))
	
	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if isDraggingPreview and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
			Preview.Outer.Position = UDim2.new(
				frameStartPos.X.Scale,
				frameStartPos.X.Offset + delta.X,
				frameStartPos.Y.Scale,
				frameStartPos.Y.Offset + delta.Y
			)
		end
	end))
	
	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDraggingPreview = false
		end
	end))
end

TrackConnection(Preview.CloseBtn.MouseButton1Click:Connect(function()
	Preview.Outer.Visible = false
	
	if currentPreviewTrack then
		currentPreviewTrack:Stop()
		currentPreviewTrack = nil
	end
	
	currentPreviewAnimId = nil
	
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end
	
	if progressConnection then
		progressConnection:Disconnect()
		progressConnection = nil
	end
	
	for _, child in Preview.WorldModel:GetChildren() do
		if child:IsA("Model") then
			child:Destroy()
		end
	end
	
	Controls.ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
	isPaused = false
	isStopped = false
	updatePlayPauseIcon()
	
	
	cameraOrbitX = DEFAULT_ORBIT_X
	cameraOrbitY = DEFAULT_ORBIT_Y
	cameraZoom = DEFAULT_ZOOM
	isCameraDragging = false
	
	
	local ZOOM_MIN = 3
	local ZOOM_MAX = 30
	local zoomProgress = (cameraZoom - ZOOM_MIN) / (ZOOM_MAX - ZOOM_MIN)
	Sliders.ZoomFill.Size = UDim2.new(zoomProgress, 0, 1, 0)
	Sliders.ZoomValue.Text = string.format("%.1f", cameraZoom)
	
	Preview.InfoLabel.Text = "Select an animation to preview"
	Preview.InfoLabel.TextColor3 = Colors.DisabledTextColor
end))

TrackConnection(Controls.PlayPauseBtn.MouseButton1Click:Connect(function()
	if currentPreviewTrack then
		if isStopped then
			
			currentPreviewTrack:Play()
			currentPreviewTrack:AdjustSpeed(animationSpeed)
			isStopped = false
			isPaused = false
		elseif isPaused then
			
			currentPreviewTrack:AdjustSpeed(animationSpeed)
			isPaused = false
		else
			
			currentPreviewTrack:AdjustSpeed(0)
			isPaused = true
		end
		updatePlayPauseIcon()
	end
end))


TrackConnection(Controls.StopBtn.MouseButton1Click:Connect(function()
	if currentPreviewTrack then
		
		currentPreviewTrack:Stop()
		isStopped = true
		isPaused = false
		updatePlayPauseIcon()
		
		
		Controls.ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
		Controls.CurrentTimeLabel.Text = "00:00.00"
	end
end))


TrackConnection(Controls.LoopBtn.MouseButton1Click:Connect(function()
	isLooping = not isLooping
	if currentPreviewTrack then
		currentPreviewTrack.Looped = isLooping
	end
	
	local iconColor = isLooping and Colors.AccentColor or Colors.DisabledTextColor
	if Controls.LoopIcon then
		if Controls.LoopIcon:IsA("ImageLabel") then
			Controls.LoopIcon.ImageColor3 = iconColor
		elseif Controls.LoopIcon:IsA("TextLabel") then
			Controls.LoopIcon.TextColor3 = iconColor
		end
	end
end))


TrackConnection(Controls.RestartBtn.MouseButton1Click:Connect(function()
	if currentPreviewTrack then
		currentPreviewTrack:Stop()
		currentPreviewTrack:Play()
		currentPreviewTrack:AdjustSpeed(animationSpeed)
		currentPreviewTrack.Looped = isLooping
		isStopped = false
		isPaused = false
		updatePlayPauseIcon()
	end
end))


TrackConnection(Controls.AddMarkerBtn.MouseButton1Click:Connect(function()
	addMarkerOfType("Parry")
end))

TrackConnection(Controls.AddDodgeBtn.MouseButton1Click:Connect(function()
	addMarkerOfType("Dodge")
end))

TrackConnection(Controls.AddRedBtn.MouseButton1Click:Connect(function()
	addMarkerOfType("Red Counter")
end))


TrackConnection(Controls.ClearMarkersBtn.MouseButton1Click:Connect(function()
	clearAllMarkers()
end))


TrackConnection(Controls.ExportMarkersBtn.MouseButton1Click:Connect(function()
	exportMarkersToLua()
end))


TrackConnection(Controls.AddToTableBtn.MouseButton1Click:Connect(function()
	addToParryTable()
end))

TrackConnection(Controls.ExportTableBtn.MouseButton1Click:Connect(function()
	exportParryTable("Default")
end))


TrackConnection(Preview.GridBtn.MouseButton1Click:Connect(function()
	isGridEnabled = not isGridEnabled
	if isGridEnabled then
		Preview.GridBtn.BackgroundColor3 = Colors.AccentColor
		Preview.GridBtn.BackgroundTransparency = 0.5
	else
		Preview.GridBtn.BackgroundColor3 = Colors.OutlineColor
		Preview.GridBtn.BackgroundTransparency = 0.5
	end
	updateGridFloor()
end))


TrackConnection(Preview.AutoRotateBtn.MouseButton1Click:Connect(function()
	isAutoRotate = not isAutoRotate
	if isAutoRotate then
		Preview.AutoRotateBtn.BackgroundColor3 = Colors.AccentColor
		Preview.AutoRotateBtn.BackgroundTransparency = 0.5
	else
		Preview.AutoRotateBtn.BackgroundColor3 = Colors.OutlineColor
		Preview.AutoRotateBtn.BackgroundTransparency = 0.5
	end
end))


TrackConnection(Preview.ResetCameraBtn.MouseButton1Click:Connect(function()
	cameraOrbitX = DEFAULT_ORBIT_X
	cameraOrbitY = DEFAULT_ORBIT_Y
	cameraZoom = DEFAULT_ZOOM
	updateCameraPosition()
	
	
	local ZOOM_MIN = 3
	local ZOOM_MAX = 30
	local zoomProgress = (cameraZoom - ZOOM_MIN) / (ZOOM_MAX - ZOOM_MIN)
	Sliders.ZoomFill.Size = UDim2.new(zoomProgress, 0, 1, 0)
	Sliders.ZoomValue.Text = string.format("%.1f", cameraZoom)
end))


TrackConnection(Preview.ViewportFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isCameraDragging = true
		lastMousePosition = Vector2.new(input.Position.X, input.Position.Y)
		Preview.CameraHint.Text = "Orbiting..."
	end
end))

TrackConnection(Preview.ViewportFrame.InputChanged:Connect(function(input)
	if isCameraDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local currentPos = Vector2.new(input.Position.X, input.Position.Y)
		local delta = currentPos - lastMousePosition
		
		
		cameraOrbitX = cameraOrbitX - delta.X * 0.5
		
		
		
		lastMousePosition = currentPos
		updateCameraPosition()
	end
end))

TrackConnection(Preview.ViewportFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isCameraDragging = false
		if isAutoRotate then
			Preview.CameraHint.Text = "Auto-rotating"
		else
			Preview.CameraHint.Text = "Drag to orbit"
		end
	end
end))


TrackConnection(Preview.ViewportFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local ZOOM_MIN = 3
		local ZOOM_MAX = 30
		local zoomDelta = -input.Position.Z * 1.5 
		cameraZoom = math.clamp(cameraZoom + zoomDelta, ZOOM_MIN, ZOOM_MAX)
		updateCameraPosition()
		
		
		local zoomProgress = (cameraZoom - ZOOM_MIN) / (ZOOM_MAX - ZOOM_MIN)
		Sliders.ZoomFill.Size = UDim2.new(zoomProgress, 0, 1, 0)
		Sliders.ZoomValue.Text = string.format("%.1f", cameraZoom)
	end
end))



local isZoomScrubbing = false
local updateZoomFromSlider

do
	local ZOOM_MIN = 3
	local ZOOM_MAX = 30
	
	local function updateZoomSliderVisual()
		local progress = (cameraZoom - ZOOM_MIN) / (ZOOM_MAX - ZOOM_MIN)
		Sliders.ZoomFill.Size = UDim2.new(progress, 0, 1, 0)
		Sliders.ZoomValue.Text = string.format("%.1f", cameraZoom)
	end
	
	updateZoomFromSlider = function(inputX)
		local relativeX = inputX - Sliders.ZoomBg.AbsolutePosition.X
		local progress = math.clamp(relativeX / Sliders.ZoomBg.AbsoluteSize.X, 0, 1)
		cameraZoom = ZOOM_MIN + progress * (ZOOM_MAX - ZOOM_MIN)
		
		cameraZoom = math.floor(cameraZoom * 2 + 0.5) / 2
		cameraZoom = math.clamp(cameraZoom, ZOOM_MIN, ZOOM_MAX)
		
		updateZoomSliderVisual()
		updateCameraPosition()
	end
	
	TrackConnection(Sliders.ZoomBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isZoomScrubbing = true
			updateZoomFromSlider(input.Position.X)
		end
	end))
	
	TrackConnection(Sliders.ZoomBg.InputChanged:Connect(function(input)
		if isZoomScrubbing and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateZoomFromSlider(input.Position.X)
		end
	end))
	
	TrackConnection(Sliders.ZoomBg.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isZoomScrubbing = false
		end
	end))
end



local isSpeedScrubbing = false
local updateSpeedFromSlider

do
	local SPEED_MIN = 0.1
	local SPEED_MAX = 3.0
	local speedOptions = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0}
	local currentSpeedIndex = 4
	
	local function updateSpeedSliderVisual()
		local progress = (animationSpeed - SPEED_MIN) / (SPEED_MAX - SPEED_MIN)
		Sliders.SpeedFill.Size = UDim2.new(progress, 0, 1, 0)
		Sliders.SpeedValue.Text = string.format("%.2fx", animationSpeed)
		Controls.SpeedBtn.Text = string.format("%.2gx", animationSpeed)
	end
	
	updateSpeedFromSlider = function(inputX)
		local relativeX = inputX - Sliders.SpeedBg.AbsolutePosition.X
		local progress = math.clamp(relativeX / Sliders.SpeedBg.AbsoluteSize.X, 0, 1)
		animationSpeed = SPEED_MIN + progress * (SPEED_MAX - SPEED_MIN)
		
		animationSpeed = math.floor(animationSpeed * 20 + 0.5) / 20
		animationSpeed = math.clamp(animationSpeed, SPEED_MIN, SPEED_MAX)
		
		updateSpeedSliderVisual()
		
		if currentPreviewTrack and not isPaused and not isStopped then
			currentPreviewTrack:AdjustSpeed(animationSpeed)
		end
	end
	
	TrackConnection(Sliders.SpeedBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isSpeedScrubbing = true
			updateSpeedFromSlider(input.Position.X)
		end
	end))
	
	TrackConnection(Sliders.SpeedBg.InputChanged:Connect(function(input)
		if isSpeedScrubbing and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSpeedFromSlider(input.Position.X)
		end
	end))
	
	TrackConnection(Sliders.SpeedBg.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isSpeedScrubbing = false
		end
	end))
	
	TrackConnection(Controls.SpeedBtn.MouseButton1Click:Connect(function()
		currentSpeedIndex = (currentSpeedIndex % #speedOptions) + 1
		animationSpeed = speedOptions[currentSpeedIndex]
		updateSpeedSliderVisual()
		if currentPreviewTrack and not isPaused and not isStopped then
			currentPreviewTrack:AdjustSpeed(animationSpeed)
		end
	end))
end



local isScrubbing = false
local updateTimelinePosition

do
	updateTimelinePosition = function(inputX)
		if currentPreviewTrack and currentPreviewTrack.Length > 0 then
			local relativeX = inputX - Controls.ProgressBarBg.AbsolutePosition.X
			local progress = math.clamp(relativeX / Controls.ProgressBarBg.AbsoluteSize.X, 0, 1)
			local targetTime = progress * currentPreviewTrack.Length
			currentPreviewTrack.TimePosition = targetTime
		end
	end
	
	TrackConnection(Controls.ProgressBarBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if currentPreviewTrack and currentPreviewTrack.Length > 0 then
				
				if not isPaused then
					isPaused = true
					currentPreviewTrack:AdjustSpeed(0)
					updatePlayPauseIcon()
				end
				
				isScrubbing = true
				updateTimelinePosition(input.Position.X)
			end
		end
	end))
	
	TrackConnection(Controls.ProgressBarBg.InputChanged:Connect(function(input)
		if isScrubbing and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateTimelinePosition(input.Position.X)
		end
	end))
	
	TrackConnection(Controls.ProgressBarBg.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isScrubbing = false
		end
	end))
end


TrackConnection(UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if isScrubbing then
			updateTimelinePosition(input.Position.X)
		end
		if isSpeedScrubbing then
			updateSpeedFromSlider(input.Position.X)
		end
		if isZoomScrubbing then
			updateZoomFromSlider(input.Position.X)
		end
		if isCameraDragging then
			local currentPos = Vector2.new(input.Position.X, input.Position.Y)
			local delta = currentPos - lastMousePosition
			cameraOrbitX = cameraOrbitX - delta.X * 0.5
			
			lastMousePosition = currentPos
			updateCameraPosition()
		end
	end
end))

TrackConnection(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isScrubbing = false
		isSpeedScrubbing = false
		isZoomScrubbing = false
		if isCameraDragging then
			isCameraDragging = false
			if isAutoRotate then
				Preview.CameraHint.Text = "Auto-rotating"
			else
				Preview.CameraHint.Text = "Drag to orbit"
			end
		end
	end
end))

TrackConnection(UI.SettingsButton.MouseButton1Click:Connect(function()
	Settings.Outer.Visible = not Settings.Outer.Visible
end))

TrackConnection(UI.MinimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	
	if isMinimized then
		UI.Outer.Size = UDim2.new(0, 450, 0, 26)
		UI.Divider.Visible = false
		UI.StatsFrame.Visible = false
		UI.ScrollFrame.Visible = false
		Settings.Outer.Visible = false
		Preview.Outer.Visible = false
		
		for _, child in UI.MinimizeButton:GetChildren() do
			if child:IsA("ImageLabel") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		CreateIcon(UI.MinimizeButton, "maximize-2", 16, UDim2.new(0, 2, 0, 2))
	else
		UI.Outer.Size = originalSize
		UI.Divider.Visible = true
		UI.StatsFrame.Visible = true
		UI.ScrollFrame.Visible = true
		
		for _, child in UI.MinimizeButton:GetChildren() do
			if child:IsA("ImageLabel") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		CreateIcon(UI.MinimizeButton, "minus", 16, UDim2.new(0, 2, 0, 2))
	end
end))

TrackConnection(UI.CloseButton.MouseButton1Click:Connect(function()
	
	for _, connection in ActiveConnections do
		if typeof(connection) == "RBXScriptConnection" then
			pcall(function() connection:Disconnect() end)
		end
	end
	
	if currentPreviewTrack then
		currentPreviewTrack:Stop()
		currentPreviewTrack = nil
	end
	
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end
	
	if progressConnection then
		progressConnection:Disconnect()
		progressConnection = nil
	end
	
	loggedAnimations = {}
	animationObjects = {}
	othersLoggedAnimations = {}
	othersAnimationObjects = {}
	playerGroups = {}
	parentGroups = {}
	
	_G[OXY_IDENTIFIER] = nil
	
	ScreenGui:Destroy()
end))

TrackConnection(Settings.ClearButton.MouseButton1Click:Connect(function()
	
	if activeTab == "AnimationLogger" then
		for _, child in UI.ScrollFrame:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		
		for parentName, groupData in parentGroups do
			if groupData.Frame then
				groupData.Frame:Destroy()
			end
		end
		parentGroups = {}
		
		loggedAnimations = {}
		animationObjects = {}
		animationCount = 0
		UI.StatsLabel.Text = "Logged: 0"
		UI.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	elseif activeTab == "Others" then
		
		for playerName, groupData in playerGroups do
			if groupData.Frame then
				groupData.Frame:Destroy()
			end
		end
		playerGroups = {}
		
		othersLoggedAnimations = {}
		othersAnimationObjects = {}
		othersAnimationCount = 0
		UI.OthersStatsLabel.Text = "Logged: 0"
	end
end))

TrackConnection(Settings.ToggleBox.MouseButton1Click:Connect(function()
	isCopyingAsLink = not isCopyingAsLink
	
	if isCopyingAsLink then
		Settings.ToggleCheckmark.Text = "✓"
		Settings.ToggleBox.BorderColor3 = Colors.AccentColor
	else
		Settings.ToggleCheckmark.Text = ""
		Settings.ToggleBox.BorderColor3 = Colors.OutlineColor
	end
	
	
	local scrollFrames = {UI.ScrollFrame, UI.OthersScrollFrame}
	for _, scrollFrame in scrollFrames do
		for _, child in scrollFrame:GetChildren() do
			if child:IsA("Frame") then
				for _, desc in child:GetDescendants() do
					if desc:IsA("TextLabel") and string_match(desc.Text, "Click to copy") then
						desc.Text = isCopyingAsLink and "Click to copy link" or "Click to copy ID"
					end
				end
			end
		end
	end
end))

TrackConnection(Settings.AutoPreviewBox.MouseButton1Click:Connect(function()
	isAutoPreview = not isAutoPreview
	
	if isAutoPreview then
		Settings.AutoPreviewCheckmark.Text = "✓"
		Settings.AutoPreviewBox.BorderColor3 = Colors.AccentColor
	else
		Settings.AutoPreviewCheckmark.Text = ""
		Settings.AutoPreviewBox.BorderColor3 = Colors.OutlineColor
	end
end))

TrackConnection(Settings.NameParentingBox.MouseButton1Click:Connect(function()
	isNameParenting = not isNameParenting
	
	if isNameParenting then
		Settings.NameParentingCheckmark.Text = "✓"
		Settings.NameParentingBox.BorderColor3 = Colors.AccentColor
	else
		Settings.NameParentingCheckmark.Text = ""
		Settings.NameParentingBox.BorderColor3 = Colors.OutlineColor
	end
	
	
	for numericId, animData in animationObjects do
		local displayName = animData.Name
		if isNameParenting and animData.ParentName then
			displayName = animData.ParentName .. animData.Name
		end
		
		if animData.Frame then
			for _, desc in animData.Frame:GetDescendants() do
				if desc:IsA("TextLabel") and desc.Name == "AnimNameLabel" then
					desc.Text = displayName
				end
			end
		end
	end
	
	
	for numericId, animData in othersAnimationObjects do
		local displayName = animData.Name
		if isNameParenting and animData.ParentName then
			displayName = animData.ParentName .. animData.Name
		end
		
		if animData.Frame then
			for _, desc in animData.Frame:GetDescendants() do
				if desc:IsA("TextLabel") and desc.Name == "AnimNameLabel" then
					desc.Text = displayName
				end
			end
		end
	end
end))

TrackConnection(Settings.GroupByParentBox.MouseButton1Click:Connect(function()
	isGroupByParent = not isGroupByParent
	
	if isGroupByParent then
		Settings.GroupByParentCheckmark.Text = "✓"
		Settings.GroupByParentBox.BorderColor3 = Colors.AccentColor
		
		
		for numericId, animData in animationObjects do
			if animData.Frame and animData.Frame.Parent == UI.ScrollFrame then
				local parentGroup = getOrCreateParentGroup(animData.ParentName)
				
				
				animData.Frame.Size = UDim2.new(1, 0, 0, 60)
				animData.Frame.Parent = parentGroup.AnimContainer
				animData.ParentGroup = parentGroup
				
				
				parentGroup.AnimCount = parentGroup.AnimCount + 1
				parentGroup.CountLabel.Text = parentGroup.AnimCount .. " animation" .. (parentGroup.AnimCount == 1 and "" or "s")
			end
		end
		
		
		for numericId, animData in othersAnimationObjects do
			local playerGroupData = animData.PlayerGroup
			if playerGroupData and animData.Frame and animData.Frame.Parent == playerGroupData.AnimContainer then
				local nestedParentGroup = getOrCreateParentGroup(animData.ParentName, playerGroupData.AnimContainer, playerGroupData.NestedParentGroups)
				
				
				animData.Frame.Parent = nestedParentGroup.AnimContainer
				animData.ParentGroup = nestedParentGroup
				
				
				nestedParentGroup.AnimCount = nestedParentGroup.AnimCount + 1
				nestedParentGroup.CountLabel.Text = tostring(nestedParentGroup.AnimCount)
			end
		end
	else
		Settings.GroupByParentCheckmark.Text = ""
		Settings.GroupByParentBox.BorderColor3 = Colors.OutlineColor
		
		
		for numericId, animData in animationObjects do
			if animData.Frame and animData.ParentGroup then
				animData.Frame.Size = UDim2.new(1, -8, 0, 60)
				animData.Frame.Parent = UI.ScrollFrame
				animData.ParentGroup = nil
			end
		end
		
		
		for parentName, groupData in parentGroups do
			if groupData.Frame then
				groupData.Frame:Destroy()
			end
		end
		parentGroups = {}
		
		
		for numericId, animData in othersAnimationObjects do
			local playerGroupData = animData.PlayerGroup
			if playerGroupData and animData.Frame and animData.ParentGroup then
				animData.Frame.Parent = playerGroupData.AnimContainer
				animData.ParentGroup = nil
			end
		end
		
		
		for playerName, playerGroupData in playerGroups do
			if playerGroupData.NestedParentGroups then
				for parentName, groupData in playerGroupData.NestedParentGroups do
					if groupData.Frame then
						groupData.Frame:Destroy()
					end
				end
				playerGroupData.NestedParentGroups = {}
			end
		end
	end
end))


TrackConnection(Settings.FileCacheBox.MouseButton1Click:Connect(function()
	if not hasFileSystem then
		Notify("oxy", "File system not available in this executor")
		return
	end
	
	isFileCacheEnabled = not isFileCacheEnabled
	
	if isFileCacheEnabled then
		Settings.FileCacheCheckmark.Text = "✓"
		Settings.FileCacheBox.BorderColor3 = Colors.AccentColor
		loadFileCache()
		Notify("oxy", "File cache enabled - animations will be cached")
	else
		Settings.FileCacheCheckmark.Text = ""
		Settings.FileCacheBox.BorderColor3 = Colors.OutlineColor
		Notify("oxy", "File cache disabled")
	end
end))


TrackConnection(Settings.ClearCacheButton.MouseButton1Click:Connect(function()
	local success = clearFileCache()
	Notify("oxy", success and "Animation cache cleared!" or "Failed to clear cache or no cache exists")
end))


TrackConnection(Settings.ClearIgnoredBtn.MouseButton1Click:Connect(function()
	ignoredParents = {}
	ignoredPlayers = {}
	updateIgnoredCount()
	Notify("oxy", "Cleared all ignored parents and players")
end))

TrackConnection(UI.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	UI.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UI.ListLayout.AbsoluteContentSize.Y + 8)
end))

TrackConnection(UI.OthersListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	UI.OthersScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UI.OthersListLayout.AbsoluteContentSize.Y + 8)
end))


updateLoadingProgress(0.5, LPH_ENCSTR("Setting up player tracking..."))
task.wait()

trackPlayerAnimations()
updateLoadingProgress(0.65, LPH_ENCSTR("Setting up other players..."))
task.wait()

trackOtherPlayersAnimations()
updateLoadingProgress(0.8, LPH_ENCSTR("Scanning for entities..."))
task.wait()


task.spawn(function()
	local descendants = Workspace:GetDescendants()
	local totalDescendants = #descendants
	local processedCount = 0
	local batchSize = 50 
	
	for i, desc in descendants do
		if desc:IsA("Humanoid") then
			task.spawn(trackEntityAnimations, desc)
		end
		processedCount = processedCount + 1
		
		
		if processedCount % batchSize == 0 then
			local progress = 0.8 + (0.15 * (processedCount / totalDescendants))
			updateLoadingProgress(progress, LPH_ENCSTR("Scanning entities...") .. " (" .. processedCount .. "/" .. totalDescendants .. ")")
			task.wait()
		end
	end
	
	
	TrackConnection(Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("Humanoid") then
			task.delay(0.1, function()
				trackEntityAnimations(desc)
			end)
		end
	end))
	
	
	updateLoadingProgress(1, LPH_ENCSTR("Done!"))
	task.wait(0.3)
	
	
	local expandTween = TweenService:Create(LoadingFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = MAIN_UI_SIZE,
		Position = CENTER_POS
	})
	expandTween:Play()
	expandTween.Completed:Wait()
	
	
	UI.Outer.Visible = true
	LoadingFrame:Destroy()
	
	Notify(LPH_ENCSTR("oxy Loaded"), LPH_ENCSTR("Initialized successfully"), 5)
end)


-- ================================================
--  oxy bridge  (feeds the oxy hub Auto Parry tab) - event driven, low cost
-- ================================================
do
	local g = (getgenv and getgenv()) or _G
	g.oxy_SeenAnims = g.oxy_SeenAnims or {}
	g.oxy_GetParryTable = function() return parryTable end

	local hooked = setmetatable({}, { __mode = "k" })
	local function feed(track)
		local id = track and track.Animation and track.Animation.AnimationId
		if not id or id == "" then return end
		local num = getNumericId(id); if not num then return end
		if not g.oxy_SeenAnims[num] then
			local c = animationNameCache[num]
			g.oxy_SeenAnims[num] = (c and c.name) or num
		end
		g.oxy_LastAnim = num
	end
	local function hook(hum)
		if not hum or hooked[hum] then return end
		hooked[hum] = true
		pcall(function() hum.AnimationPlayed:Connect(feed) end)
	end
	local function hookModel(m)
		local h = m and m:FindFirstChildOfClass("Humanoid")
		if h then hook(h) end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then hookModel(p.Character) end
		p.CharacterAdded:Connect(hookModel)
	end
	Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(hookModel) end)
	local living = Workspace:FindFirstChild("Living")
	if living then
		for _, m in ipairs(living:GetChildren()) do hookModel(m) end
		living.ChildAdded:Connect(function(m) task.defer(hookModel, m) end)
	end
end
