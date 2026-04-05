--- DIHHHHHHH 
-- bridger: WESTERN

pcall(function()
	for _, v in getgc(true) do
		if type(v) == "table" and rawget(v, "indexInstance") then
			for _, a in pairs(v) do
				if type(a) == "table" and type(a[2]) == "function" then
					hookfunction(a[2], newcclosure(function() return false end))
				end
			end break
		end
	end
end)

local global = getgenv()

local reserve, claim = loadstring(game:HttpGet("https://raw.githubusercontent.com/odioism/Utilities/refs/heads/main/Reserve%2BClaim.lua"))()
reserve(global, "Loop", loadstring(game:HttpGet("https://raw.githubusercontent.com/odioism/Utilities/refs/heads/main/Loop.lua"))())

local players = cloneref(game:GetService("Players"))
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local entities = workspace.Entities
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local remotes = replicatedStorage.Remotes
local userInputService = cloneref(game:GetService("UserInputService"))
local runService = cloneref(game:GetService("RunService"))
local renderStepped = runService.RenderStepped

local function draw(class, properties)
	local drawing = Drawing.new(class)

	for property, value in properties do
		pcall(function()
			drawing[property] = value
		end)
	end

	return drawing
end

local function create(class, properties)
	local instance = Instance.new(class)

	for property, value in properties do
		pcall(function()
			instance[property] = value
		end)
	end
	
	return instance
end

reserve(reserve(global, "Player", {}), "Cache", {})
reserve(reserve(global, "Entity", {}), "Cache", {})

reserve(global, "Visuals", {
	Enabled = true,
	WallCheck = false,
	RenderDistance = 3000,
	Font = 1,
	TextSize = 13,
	Box = true,
	BoxOutline = true,
	BoxFill = true,
	BoxFillTransparency = 0.25,
	BoxColor = Color3.fromRGB(255, 255, 255),
	BoxFillColor = Color3.fromRGB(255, 255, 255),
	BoxOutlineColor = Color3.fromRGB(0, 0, 0),
	Health = true,
	HealthText = true,
	HealthOutline = true,
	HealthMaxColor = Color3.fromRGB(0, 255, 0),
	HealthMinColor = Color3.fromRGB(255, 0, 0),
	HealthOutlineColor = Color3.fromRGB(0, 0, 0),
	Name = true,
	NameOutline = true,
	NameColor = Color3.fromRGB(255, 255, 255),
	NameOutlineColor = Color3.fromRGB(0, 0, 0),
	Distance = true,
	DistanceOutline = true,
	DistanceColor = Color3.fromRGB(255, 255, 255),
	DistanceOutlineColor = Color3.fromRGB(0, 0, 0),
	Weapon = true,
	WeaponOutline = true,
	WeaponColor = Color3.fromRGB(255, 255, 255),
	WeaponOutlineColor = Color3.fromRGB(0, 0, 0),
	Entity = true,
	EntityName = true,
	EntityNameOutline = true,
	EntityNameColor = Color3.fromRGB(255, 255, 0),
	EntityNameOutlineColor = Color3.fromRGB(0, 0, 0),
	Entity = true,
	EntityHealth = true,
	EntityHealthOutline = true,
	EntityHealthMaxColor = Color3.fromRGB(0, 255, 0),
	EntityHealthMinColor = Color3.fromRGB(255, 0, 0),
	EntityHealthOutlineColor = Color3.fromRGB(0, 0, 0),
})

reserve(global, "Aim", {
	Lock = true,
	Key = "F",
	Assist = true,
	Chance = 100,
	Weapons = {"Gun", "Item", "Stand"},
	Entity = true,
	WallCheck = true,
	Fov = true,
	FovRadius = 200,
	Prediction = false,
	PredictionPing = false,
	PredictionAmount = 0.15,
	Method = "Mouse",
	Part = "HumanoidRootPart",
})

reserve(global, "AimVisuals", {
	Fov = true,
	FovOutline = true,
	FovColor = Color3.fromRGB(255, 255, 255),
	FovOutlineColor = Color3.fromRGB(0, 0, 0),
	Highlight = true,
	HighlightColor = Color3.fromRGB(255, 255, 255),
	HighlightOutlineColor = Color3.fromRGB(255, 255, 255),
	HighlightTransparency = 0.5,
	HighlightOutlineTransparency = 0,
})

reserve(AimVisuals, "Visuals", {
	Fov = draw("Circle", {Visible = false}),
	FovOutline = draw("Circle", {Visible = false}),
	Line = draw("Line", {Visible = false}),
	LineOutline = draw("Line", {Visible = false}),
	Highlight = create("Highlight", {Parent = cloneref(game:GetService("CoreGui"))})
})

function Aim:Closest()
	local closest, target = (self.Method == "Mouse" and self.Fov) and self.FovRadius or math.huge
	local mouse = userInputService:GetMouseLocation()

	for character, data in Player.Cache do
		pcall(function()
			local distance = self.Method == "Mouse" and (mouse - Vector2.new(data.ScreenPosition.X, data.ScreenPosition.Y)).Magnitude or data.Distance

			if distance < closest and data.OnScreen then
				local wallCheck = Aim.WallCheck and Visuals:IsVisible(character.HumanoidRootPart.CFrame.Position, {character}) or not Aim.WallCheck

				if not wallCheck or not character:FindFirstChild(self.Part) then return end

				closest = distance
				target = character
			end
		end)
	end

	if self.Entity then
		for entity, data in Entity.Cache do
			pcall(function()
				local distance = self.Method == "Mouse" and (mouse - Vector2.new(data.ScreenPosition.X, data.ScreenPosition.Y)).Magnitude or data.Distance

				if distance < closest and data.OnScreen then
					local wallCheck = Aim.WallCheck and Visuals:IsVisible(entity.HumanoidRootPart.CFrame.Position, {entity}) or not Aim.WallCheck

					if not wallCheck then return end

					closest = distance
					target = entity
				end
			end)
		end
	end

	return target
end

claim(Aim, "Loop", Loop.new(function()
	local mouse = userInputService:GetMouseLocation()
	local visuals = AimVisuals.Visuals

	Aim.Target = Aim:Closest()
	Aim.TargetPart = Aim.Target and Aim.Target:FindFirstChild(Aim.Part)
	Aim.PredictionAmount = Aim.PredictionPing and cloneref(game:GetService("Stats")).Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 or Aim.PredictionAmount
	Aim.TargetPosition = Aim.TargetPart and (Aim.Prediction and Aim.TargetPart.Position + (Aim.TargetPart.AssemblyLinearVelocity * Aim.PredictionAmount) or Aim.TargetPart.Position)
	Aim.GunTargetPosition = nil

	local success, range = pcall(function()
		return require(localPlayer.Character:FindFirstChild("ServerConfig", true)).Range
	end)

	if Aim.TargetPosition and success and range then
		local origin = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2).Origin
		local direction = (Aim.TargetPosition - origin)
		local distance = direction.Magnitude
		local unit = distance > 0 and direction.Unit or Vector3.zero

		if range < distance then
			Aim.GunTargetPosition = origin + unit * math.max(0, range - 5)
		else
			Aim.GunTargetPosition = Aim.TargetPosition
		end
	end

	local data = Aim.TargetPart and (Player.Cache[Aim.Target] or Entity.Cache[Aim.Target])

	if Aim.Lock and userInputService:IsKeyDown(Enum.KeyCode[Aim.Key]) and data then
		Aim.LockTargetPart = not Aim.LockTargetPart and Aim.TargetPart or Aim.LockTargetPart 
		Aim.LockTargetPosition = Aim.Prediction and Aim.LockTargetPart.Position + (Aim.LockTargetPart.AssemblyLinearVelocity * Aim.PredictionAmount) or Aim.LockTargetPart.Position
		camera.CFrame = CFrame.new(camera.CFrame.Position, Aim.LockTargetPosition)
	elseif not userInputService:IsKeyDown(Enum.KeyCode[Aim.Key]) then
		Aim.LockTargetPart = nil
	end

	if AimVisuals.Highlight then	
		visuals.Highlight.FillColor = AimVisuals.HighlightColor
		visuals.Highlight.FillTransparency = AimVisuals.HighlightTransparency
		visuals.Highlight.OutlineColor = AimVisuals.HighlightOutlineColor
		visuals.Highlight.OutlineTransparency = AimVisuals.HighlightOutlineTransparency
		visuals.Highlight.Adornee = Aim.Target
	end

	visuals.Highlight.Enabled = AimVisuals.Highlight

	local fovCheck = Aim.Fov and AimVisuals.Fov

	if fovCheck then
		visuals.Fov.Position = Vector2.new(mouse.X, mouse.Y)
		visuals.Fov.Color = AimVisuals.FovColor
		visuals.Fov.Thickness = 1
		visuals.Fov.Radius = Aim.FovRadius

		visuals.FovOutline.Position = visuals.Fov.Position
		visuals.FovOutline.Color = AimVisuals.FovOutlineColor
		visuals.FovOutline.Thickness = 3
		visuals.FovOutline.Radius = visuals.Fov.Radius
		visuals.FovOutline.ZIndex = visuals.Fov.ZIndex - 1
	end

	visuals.Fov.Visible = fovCheck
	visuals.FovOutline.Visible = AimVisuals.FovOutline and visuals.Fov.Visible

	-- remotes.GetMousePos.OnClientInvoke = function()

	-- 	local target = Aim.GunTargetPosition or Aim.TargetPosition

	-- 	return target or localPlayer:GetMouse().Hit.Position
	-- end
end))

function Visuals:IsVisible(position, whitelist)
	if Player:Check(localPlayer) then
		table.insert(whitelist, localPlayer.Character)
	end
	return #camera:GetPartsObscuringTarget({position}, whitelist) == 0
end

function Player:Find(player)
	for character, data in self.Cache do
		if data.Player == player then return character end
	end
end

function Player:Check(player)
	local success, check = pcall(function()
		local character = player:IsA("Player") and player.Character or player
		local children = {character.Humanoid, character.HumanoidRootPart, character.Head}

		return children and character.Parent ~= nil
	end)

	return success and check
end

function Player:Add(player)
	self:Remove(player)

	local function cache(character)
		self.Cache[character] = {
			["Player"] = player,
			["Drawings"] = {
				Box = draw("Square", {Visible = false}),
				BoxFill = draw("Square", {Visible = false, Filled = true}),
				BoxOutline = draw("Square", {Visible = false}),
				Health = draw("Line", {Visible = false}),
				HealthOutline = draw("Line", {Visible = false}),
				HealthText = draw("Text", {Visible = false, Center = false}),
				Name = draw("Text", {Visible = false, Center = true}),
				Distance = draw("Text", {Visible = false, Center = true}),
				Weapon = draw("Text", {Visible = false, Center = true})
			}
		}
	end

	local function check(character)
		if self:Check(character) then
			cache(character)
		else
			local listener; listener = character.ChildAdded:Connect(function(child)
				repeat task.wait() until child:IsDescendantOf(game)

				if self:Check(character) then
					cache(character) listener:Disconnect()
				end
			end)
		end
	end

	if player.Character then check(player.Character) end	
	player.CharacterAdded:Connect(check)
end

function Player:Remove(player)
	if player:IsA("Player") then
		local character = self:Find(player)
		if character then self:Remove(character) end
	else
		pcall(function()
			for _, drawing in self.Cache[player].Drawings do
				drawing:Destroy()
			end
		end)

		self.Cache[player] = nil
	end
end

function Player:Update(character, data)
	if not self:Check(character) then
		self:Remove(character)
	end

	local player = data.Player
	local root = character.HumanoidRootPart
	local humanoid = character.Humanoid
	local weapon = character:FindFirstChildWhichIsA("Tool")
	local drawings = data.Drawings

	if self:Check(localPlayer) then
		data.Distance = (localPlayer.Character.HumanoidRootPart.CFrame.Position - root.CFrame.Position).Magnitude
	end

	data.Distance = data.Distance == nil and tonumber("nan") or data.Distance
	data.RenderDistance = (camera.CFrame.Position - root.CFrame.Position).Magnitude
	data.ScreenPosition, data.OnScreen = camera:WorldToViewportPoint(root.CFrame.Position)
	data.Visible = data.onScreen and Visuals:IsVisible(root.CFrame.Position, {character})

	local distanceCheck = data.RenderDistance <= Visuals.RenderDistance
	local wallCheck = Visuals.WallCheck and data.Visible or not Visuals.WallCheck
	local check = data.OnScreen and distanceCheck and wallCheck and Visuals.Enabled
	local healthPercent = 100 / (humanoid.MaxHealth / humanoid.Health)

	task.spawn(function()
		if check then
			local scale = 1 / (data.ScreenPosition.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
			local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
			local x, y = math.floor(data.ScreenPosition.X), math.floor(data.ScreenPosition.Y)
			local xPosition, yPostion = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))

			drawings.Box.Size = Vector2.new(width, height)
			drawings.Box.Position = Vector2.new(xPosition, yPostion)
			drawings.BoxFill.Size = drawings.Box.Size
			drawings.BoxFill.Position = drawings.Box.Position
			drawings.BoxOutline.Size = drawings.Box.Size
			drawings.BoxOutline.Position = drawings.Box.Position
			drawings.Box.Color = Visuals.BoxColor
			drawings.Box.Thickness = 1
			drawings.BoxFill.Color = Visuals.BoxFillColor
			drawings.BoxFill.Transparency = Visuals.BoxFillTransparency
			drawings.BoxOutline.Color = Visuals.BoxOutlineColor
			drawings.BoxOutline.Thickness = 3
			drawings.BoxOutline.ZIndex = drawings.Box.ZIndex - 1
			drawings.BoxFill.ZIndex = drawings.BoxOutline.ZIndex - 1
		
			drawings.Health.From = Vector2.new(xPosition - 5, (yPostion + height) - 1)
			drawings.Health.To = Vector2.new(xPosition - 5, ((drawings.Health.From.Y - ((height / 100) * healthPercent))) + 2)
			drawings.Health.Color = Visuals.HealthMinColor:Lerp(Visuals.HealthMaxColor, healthPercent * 0.01)
			drawings.HealthOutline.From = Vector2.new(xPosition - 5, yPostion)
			drawings.HealthOutline.To = Vector2.new(xPosition - 5, yPostion + height)
			drawings.HealthOutline.Color = Visuals.HealthOutlineColor
			drawings.HealthOutline.Thickness = 3
			drawings.HealthOutline.ZIndex = drawings.Health.ZIndex - 1
			drawings.HealthText.Text = `[HP {math.floor(humanoid.Health)}]`
			drawings.HealthText.Font = Visuals.Font
			drawings.HealthText.Size = Visuals.TextSize--math.min(math.abs(Visuals.TextSize * scale), Visuals.TextSize)
			drawings.HealthText.Position = Vector2.new(drawings.Health.To.X - (drawings.HealthText.TextBounds.X + 3), (drawings.Health.To.Y - (2 / scale)))
			drawings.HealthText.Color = drawings.Health.Color
			drawings.HealthText.Outline = Visuals.HealthOutline
			drawings.HealthText.OutlineColor = Visuals.HealthOutlineColor

			drawings.Name.Text = `[{player.Name}]`
			drawings.Name.Font = Visuals.Font
			drawings.Name.Size = Visuals.TextSize
			drawings.Name.Position = Vector2.new(x, (yPostion - drawings.Name.TextBounds.Y) - 2)
			drawings.Name.Color = Visuals.NameColor
			drawings.Name.Outline = Visuals.NameOutline
			drawings.Name.OutlineColor = Visuals.NameOutlineColor
			drawings.Name.ZIndex = drawings.Box.ZIndex + 1

			drawings.Distance.Text = `[{math.floor(data.Distance)}]`
			drawings.Distance.Font = Visuals.Font
			drawings.Distance.Size = Visuals.TextSize
			drawings.Distance.Position = Vector2.new(x, (yPostion + height) + (drawings.Distance.TextBounds.Y * 0.25))
			drawings.Distance.Color = Visuals.DistanceColor
			drawings.Distance.Outline = Visuals.DistanceOutline
			drawings.Distance.OutlineColor = Visuals.DistanceOutlineColor
			
			drawings.Weapon.Text = `[{weapon or "none"}]`
			drawings.Weapon.Font = Visuals.Font
			drawings.Weapon.Size = Visuals.TextSize
			drawings.Weapon.Position = Visuals.Distance and Vector2.new(drawings.Distance.Position.x, drawings.Distance.Position.Y + (drawings.Weapon.TextBounds.Y * 0.75)) or drawings.Distance.Position
			drawings.Weapon.Color = Visuals.WeaponColor
			drawings.Weapon.Outline = Visuals.WeaponOutline
			drawings.Weapon.OutlineColor = Visuals.WeaponOutlineColor
		end

		drawings.Box.Visible = (check and Visuals.Box)
		drawings.BoxFill.Visible = (check and drawings.Box.Visible and Visuals.BoxFill)
		drawings.BoxOutline.Visible = (check and drawings.Box.Visible and Visuals.BoxOutline)
		drawings.Name.Visible = (check and Visuals.Name)
		drawings.Health.Visible = (check and Visuals.Health)
		drawings.HealthOutline.Visible = (check and drawings.Health.Visible and Visuals.HealthOutline)
		drawings.HealthText.Visible = (check and drawings.Health.Visible and Visuals.HealthText)
		drawings.Distance.Visible = (check and Visuals.Distance)
		drawings.Weapon.Visible = (check and Visuals.Weapon)
	end)
end

reserve(Player, "Loop", Loop.new(function()
	for character, data in Player.Cache do
		Player:Update(character, data)
	end
end), true)

for _, player in players:GetPlayers() do
	if player ~= localPlayer then Player:Add(player) end
end

reserve(Player, "Added", players.PlayerAdded:Connect(function(player)
	Player:Add(player)
end), true)

reserve(Player, "Removing", players.PlayerRemoving:Connect(function(player)
	Player:Remove(player)
end), true)

function Entity:Check(entity)
	local success, check = pcall(function()
		local children = {entity.Humanoid, entity.HumanoidRootPart, entity.Head}
		return children and entity.Parent ~= nil
	end)
	return success and check
end

function Entity:Add(entity)
	if not (entity:GetAttribute("Faction") ~= nil and entity:GetAttribute("LastInteractionTime") ~= nil) then return end
	self:Remove(entity)
	local function cache(entity)
		self.Cache[entity] = {
			["Drawings"] = {
				Name = draw("Text", {Visible = false, Center = true}),
				Health = draw("Text", {Visible = false, Center = true}),
			}
		}
	end
	if self:Check(entity) then
		cache(entity)
	else
		local listener; listener = entity.ChildAdded:Connect(function(child)
			repeat task.wait() until child:IsDescendantOf(game)
			if self:Check(entity) then
				cache(entity) listener:Disconnect()
			end
		end)
	end
end

function Entity:Remove(entity)
	pcall(function()
		for _, drawing in self.Cache[entity].Drawings do
			drawing:Destroy()
		end
	end)
	self.Cache[entity] = nil
end

function Entity:Update(entity, data)
	if not self:Check(entity) then
		self:Remove(entity)
	end

	local root = entity.HumanoidRootPart
	local humanoid = entity.Humanoid
	local drawings = data.Drawings

	if self:Check(localPlayer) then
		data.Distance = (localPlayer.Character.HumanoidRootPart.CFrame.Position - root.CFrame.Position).Magnitude
	end

	data.Distance = data.Distance == nil and tonumber("nan") or data.Distance
	data.RenderDistance = (camera.CFrame.Position - root.CFrame.Position).Magnitude
	data.ScreenPosition, data.OnScreen = camera:WorldToViewportPoint(root.CFrame.Position)
	data.Visible = data.OnScreen and Visuals:IsVisible(root.CFrame.Position, {character})

	local distanceCheck = data.RenderDistance <= Visuals.RenderDistance
	local wallCheck = Visuals.WallCheck and data.Visible or not Visuals.WallCheck
	local check = data.OnScreen and distanceCheck and Visuals.Enabled
	local healthPercent = 100 / (humanoid.MaxHealth / humanoid.Health)

	task.spawn(function()
		if check then
			local scale = 1 / (data.ScreenPosition.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
			local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
			local x, y = math.floor(data.ScreenPosition.X), math.floor(data.ScreenPosition.Y)
			local xPosition, yPostion = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))

			drawings.Name.Text = `[{entity.Name}]`
			drawings.Name.Size = Visuals.TextSize
			drawings.Name.Position = Vector2.new(x, (yPostion - drawings.Name.TextBounds.Y) - 2)
			drawings.Name.Color = Visuals.EntityNameColor
			drawings.Name.Outline = Visuals.EntityNameOutline
			drawings.Name.OutlineColor = Visuals.EntityNameOutlineColor

			drawings.Health.Text = `[HP {math.floor(humanoid.Health)}]`
			drawings.Health.Size = Visuals.TextSize
			drawings.Health.Position = Vector2.new(x, (yPostion + height) + (drawings.Health.TextBounds.Y * 0.25))
			drawings.Health.Color = Visuals.EntityHealthMinColor:Lerp(Visuals.EntityHealthMaxColor, healthPercent * 0.01)
			drawings.Health.Outline = Visuals.EntityHealthOutline
			drawings.Health.OutlineColor = Visuals.EntityHealthOutlineColor
		end

		drawings.Name.Visible = (check and Visuals.EntityName)
		drawings.Health.Visible = (check and Visuals.EntityHealth)
	end)
end

reserve(Entity, "Loop", Loop.new(function()
	for entity, data in Entity.Cache do
		Entity:Update(entity, data)
	end
end), true)

for _, entity in entities:GetChildren() do
	Entity:Add(entity)
end

reserve(Entity, "Added", entities.ChildAdded:Connect(function(entity)
	Entity:Add(entity)
end), true)

reserve(Entity, "Removed", entities.ChildRemoved:Connect(function(entity)
	Entity:Remove(entity)
end), true)

local aimRemotes = {GunAction = "Gun", UseTool = "Item", StandEvent = "Stand", AimedAttackRequest = "Stand"}

function global.namecallFunction(self, ...)
	local arguments = {...}
	local method = getnamecallmethod()

	if not checkcaller() then
		if method == "FireServer" then
			local weapon = table.find(Aim.Weapons, aimRemotes[self.Name]) and aimRemotes[self.Name]
			local target = weapon ~= "Gun" and Aim.TargetPosition or weapon == "Gun" and Aim.GunTargetPosition

			if Aim.Assist and weapon and target then
				pcall(function()
					for index, argument in arguments do
						if typeof(argument) == "Vector3" then
							arguments[index] = target
						end
					end
				end)
			end
		end

		return namecall(self, unpack(arguments))
	end

	return namecall(self, ...)
end

reserve(global, "namecall", hookmetamethod(game, "__namecall", newcclosure(namecallFunction)))
