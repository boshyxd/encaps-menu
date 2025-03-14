--!strict
local getgenv: () -> { [string]: any } = getfenv().getgenv

getgenv().ScriptVersion = "v0.0.7"

getgenv().Changelog = [[
				v0.0.7
🔄 Changed "Items To Not Sell" to "Select Items To Sell" - now you specifically select which items to sell instead of which ones to keep
				
				v0.0.6b
❓ Applied minor fixes, cleaned up the code (could've caused issues)
				
				v0.0.6a
🛠 Fixed a small issue with Auto Sell
📃 Renamed "Sell Blacklist" to "Items To Not Sell" since people kept getting confused on what it's for

				v0.0.6
			🛠️ Changes & Fixes
🦌 Made it so Move to Mobs will not target tamed mobs
🐻 Moved the movement method below the mobs selection
	🌾 Did the same for Move to Resources' movement method
🌫 Replaced the Effects tab with Visuals

			🎉 What's New?
⚔ Combat -> Moving 
	📐 Offset
	🔼 Height Offset
🛡 Resources -> Moving -> Safety Mode
⚡ Movement -> Speed -> Change Speed Keybind
😷 Safety -> Identity
	🎭 Hide Identity (Client-Sided)
	💬 Name To Replace With
🔍 Visuals -> ESP
	🧍‍ Player ESP
	🐺 Mob ESP
]]

do
	local Core = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/boshyxd/encaps-menu/refs/heads/main/Core.lua") -- Updated repository link
	)

	if not Core then
		return warn("Failed to load the Encap's Menu Core")
	end

	Core()
end

-- Types

type Set = {
	Set: (self: any, NewValue: any) -> (),
}

type Tab = {
	CreateSection: (self: Tab, Name: string) -> Set,
	CreateDivider: (self: Tab) -> Set,
	CreateToggle: (self: Tab, any) -> Set,
	CreateSlider: (self: Tab, any) -> Set,
	CreateDropdown: (self: Tab, any) -> Set,
	CreateButton: (self: Tab, any) -> Set,
}

-- Variables

local ApplyUnsupportedName: (Name: string, Condition: boolean) -> string = getgenv().ApplyUnsupportedName
local HandleConnection: (Connection: RBXScriptConnection, Name: string) -> () = getgenv().HandleConnection
local Notify: (Title: string, Content: string, Image: string?) -> () = getgenv().Notify
local GetClosestChild: (Children: { PVInstance }, Callback: ((Child: PVInstance) -> () | boolean)?, MaxDistance: number?) -> PVInstance? =
	getgenv().GetClosestChild
local CreateFeature: (Tab: Tab, FeatureName: string) -> () = getgenv().CreateFeature

local Success, Network = pcall(require, game:GetService("ReplicatedStorage").Modules.Network)

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Flags: { [string]: { ["CurrentValue"]: any, ["CurrentOption"]: { string } } } = getgenv().Flags

local Player = game:GetService("Players").LocalPlayer

local function GetChildInCharacter(ChildName: string): Instance?
	local Character = Player.Character

	if not Character then
		return
	end

	local Child = Character:FindFirstChild(ChildName)

	return Child
end

local function GetInputRemote(RemoteName: string): RemoteEvent?
	local Character = Player.Character

	if not Character then
		return
	end

	local Remote = Character:FindFirstChild(RemoteName, true)

	task.spawn(assert, Remote, `Could not find the '{RemoteName}' remote within your character.`)

	return Remote
end

local LastFired = 0

local function TeleportLocalCharacter(NewLocation: CFrame)
	local Character = Player.Character

	if not Character then
		return
	end

	local InvisibleParts: Folder = workspace:FindFirstChild("InvisibleParts")

	if not InvisibleParts then
		return
	end

	local MandrakeRope = InvisibleParts:FindFirstChild("MandrakeRope")

	if not MandrakeRope then
		return
	end

	local MandrakePit = InvisibleParts:FindFirstChild("MandrakePit") :: Part

	if not MandrakePit then
		return
	end

	if (Character:GetPivot().Position - NewLocation.Position).Magnitude > 50 then
		if tick() - LastFired >= 2 then
			local Interact = GetInputRemote("Interact")

			if not Interact then
				return
			end

			Interact:FireServer({
				player = Player,
				Object = MandrakeRope,
				Action = "Enter",
			})
			LastFired = tick()
		end

		local Start = tick()

		repeat
			task.wait()
		until (Character:GetPivot().Position - MandrakePit.Position).Magnitude <= 10 or tick() - Start >= 1

		task.wait(0.1)
	end

	Character:PivotTo(NewLocation)
end

local function EmulateClick()
	if not Success then
		return
	end

	Network.connect("MouseInput", "Fire", Player.Character, {
		Config = "Button1Down",
	})

	Network.connect("MouseInput", "Fire", Player.Character, {
		Config = "Button1Up",
	})
end

-- Features

local Window = getgenv().Window

local Tab: Tab = Window:CreateTab("Combat", "swords")

Tab:CreateSection("Attacking")

Tab:CreateToggle({
	Name = ApplyUnsupportedName("⚔ • Auto Attack", Success),
	CurrentValue = false,
	Flag = "Attack",
	Looped = true,
	Callback = function()
		local ClosestMob = GetClosestChild(workspace.Alive:GetChildren(), function(Child)
			if Child == Player.Character then
				return true
			end
		end, Flags.Distance.CurrentValue)

		if not ClosestMob then
			return
		end

		EmulateClick()
	end,
})

Tab:CreateSection("Aiming")

Tab:CreateToggle({
	Name = "🎯 • Look At Closest Enemy",
	CurrentValue = false,
	Flag = "LookAt",
	Looped = true,
	Callback = function(Value)
		local ClosestMob = GetClosestChild(workspace.Alive:GetChildren(), function(Child)
			if Child == Player.Character then
				return true
			end
		end, Flags.Distance.CurrentValue)

		local Character = Player.Character

		if not Character then
			return
		end

		local Humanoid = GetChildInCharacter("Humanoid") :: Humanoid

		if not Humanoid then
			return
		end

		if not ClosestMob then
			Humanoid.AutoRotate = true
			return
		end

		local HumanoidRootPart: Part = Character:FindFirstChild("HumanoidRootPart")

		if not HumanoidRootPart then
			return
		end

		Humanoid.AutoRotate = false

		local Position = HumanoidRootPart.Position
		local ClosestPosition = ClosestMob:GetPivot().Position

		HumanoidRootPart.CFrame = CFrame.lookAt(Position, Vector3.new(ClosestPosition.X, Position.Y, ClosestPosition.Z))
	end,
	AfterLoop = function()
		local Humanoid = GetChildInCharacter("Humanoid") :: Humanoid

		if not Humanoid then
			return
		end

		Humanoid.AutoRotate = true
	end,
})

Tab:CreateSection("Configuration")

Tab:CreateSlider({
	Name = "📏 • Max Distance",
	Range = { 1, 100 },
	Increment = 1,
	Suffix = "Studs",
	CurrentValue = 20,
	Flag = "Distance",
})

Tab:CreateSection("Moving")

local MobTween: any
local ActiveNotification = false

Tab:CreateToggle({
	Name = "🦌 • Move to Mobs",
	CurrentValue = false,
	Flag = "MoveMobs",
	Looped = true,
	BeforeLoop = function(Value)
		if not Value and MobTween then
			MobTween:Cancel()
			MobTween = nil
		end
	end,
	Callback = function()
		local Closest = GetClosestChild(workspace.Alive:GetChildren(), function(Child)
			if not table.find(Flags.Mobs.CurrentOption, Child.Name:split(".")[1]) then
				return true
			end

			if Child:FindFirstChild("Master") then
				return true
			end
		end)

		if not Closest then
			if not ActiveNotification then
				Notify("Failed", "Couldn't find anything, try getting closer to it so it can load.")
				ActiveNotification = true
				task.delay(5, function()
					ActiveNotification = false
				end)
			end
			return
		end

		local HumanoidRootPart: Part = Player.Character.HumanoidRootPart

		local GoTo = CFrame.new(Closest:GetPivot().Position)
			+ Closest:GetPivot().LookVector * Flags.Offset.CurrentValue
			+ Vector3.yAxis * Flags.HeightOffset.CurrentValue

		local Distance = (HumanoidRootPart.Position - GoTo.Position).Magnitude

		if Distance <= 5 then
			--return
		end

		if Flags.MobsMethod.CurrentOption[1] == "Teleport" then
			TeleportLocalCharacter(GoTo)
		else
			MobTween = TweenService:Create(
				HumanoidRootPart,
				TweenInfo.new(Distance / 250, Enum.EasingStyle.Linear),
				{ CFrame = GoTo }
			)
			MobTween:Play()
			MobTween.Completed:Wait()
			MobTween = nil
		end
	end,
})

local Mobs = {}

for _, Object: Model in game:GetService("ReplicatedStorage").Storage.Mobs:GetChildren() do
	table.insert(Mobs, Object.Name)
end

table.sort(Mobs)

Tab:CreateDropdown({
	Name = "🐔 • Mobs",
	Options = Mobs,
	MultipleOptions = true,
	Flag = "Mobs",
})

Tab:CreateDivider()

local Dropdown
Dropdown = Tab:CreateDropdown({
	Name = "🐻 • Movement Method",
	Options = { "Teleport", "Tween" },
	CurrentOption = "Teleport",
	MultipleOptions = false,
	Flag = "MobsMethod",
})

Tab:CreateSlider({
	Name = "📐 • Offset",
	Range = { -10, 10 },
	Increment = 1,
	Suffix = "Studs",
	CurrentValue = -5,
	Flag = "Offset",
})

Tab:CreateSlider({
	Name = "🔼 • Height Offset",
	Range = { -10, 10 },
	Increment = 1,
	Suffix = "Studs",
	CurrentValue = 0,
	Flag = "HeightOffset",
})

local Tab: Tab = Window:CreateTab("Resources", "apple")

Tab:CreateSection("Gathering")

Tab:CreateToggle({
	Name = "🍎 • Auto Gather (No Tools Required)",
	CurrentValue = false,
	Flag = "Gather",
	Looped = true,
	Callback = function()
		if not Success then
			return
		end

		local Closest = GetClosestChild(workspace.Harvestable:GetChildren(), function(Child)
			if Child == Player.Character then
				return true
			end

			if Child:GetAttribute("SetRespawn") then
				return true
			end
		end)

		if not Closest then
			return
		end

		local Interact = GetInputRemote("Interact")

		if not Interact then
			return
		end

		Interact:FireServer({
			player = Player,
			Object = Closest,
			Action = "Gather",
		})
	end,
})

Tab:CreateToggle({
	Name = "🥚 • Auto Pick Up Items",
	CurrentValue = false,
	Flag = "PickUp",
	Looped = true,
	Callback = function()
		if not Success then
			return
		end

		for _, Item: Model in workspace.Effects:GetChildren() do
			if not Item:FindFirstChild("InteractPrompt") then
				continue
			end

			local Interact = GetInputRemote("Interact")

			if not Interact then
				continue
			end

			Interact:FireServer({
				player = Player,
				Object = Item,
				Action = "Pick Up",
			})
		end
	end,
})

Tab:CreateSection("Moving")

local ResourceTween: any
local ActiveNotification = false
local SavedPosition: Vector3

local function HarvestablesAfterLoop()
	local Part: Part = workspace:FindFirstChild("SafetyModePart")

	if not Part then
		return
	end

	TeleportLocalCharacter(CFrame.new(SavedPosition))
	Part:Destroy()
end

Tab:CreateToggle({
	Name = "🌲 • Move to Harvestables",
	CurrentValue = false,
	Flag = "MoveHarvestables",
	Looped = true,
	BeforeLoop = function(Value)
		if not Value and ResourceTween then
			ResourceTween:Cancel()
			ResourceTween = nil
		end

		local Character = Player.Character

		if not Character then
			return
		end

		SavedPosition = Character:GetPivot().Position
	end,
	Callback = function()
		local Closest = GetClosestChild(workspace.Harvestable:GetChildren(), function(Child)
			if not table.find(Flags.Harvestables.CurrentOption, Child.Name) then
				return true
			end

			if Child:GetAttribute("SetRespawn") then
				return true
			end
		end)

		if not Closest then
			if not ActiveNotification then
				Notify("Failed", "Couldn't find anything, try getting closer to it so it can load.")
				ActiveNotification = true
				task.delay(5, function()
					ActiveNotification = false
				end)
			end

			if Flags.SafetyMode.CurrentValue then
				local Character = Player.Character

				if not Character then
					return
				end

				if workspace:FindFirstChild("SafetyModePart") then
					return
				end

				local Part = Instance.new("Part")
				Part.Name = "SafetyModePart"
				Part.Size = Vector3.new(15, 5, 15)
				Part.Anchored = true
				Part.Parent = workspace
				Part.Position = Character:GetPivot().Position + Vector3.yAxis * 750

				TeleportLocalCharacter(CFrame.new(Part.Position + Vector3.yAxis * 5))
			end
			return
		end

		if workspace:FindFirstChild("SafetyModePart") then
			workspace.SafetyModePart:Destroy()
		end

		local HumanoidRootPart: Part = Player.Character.HumanoidRootPart

		local GoTo = CFrame.new(Closest:GetPivot().Position + Vector3.one * 5)

		local Distance = (HumanoidRootPart.Position - GoTo.Position).Magnitude

		if Distance <= 5 then
			return
		end

		if Flags.HarvestablesMethod.CurrentOption[1] == "Teleport" then
			TeleportLocalCharacter(GoTo)
		else
			ResourceTween = TweenService:Create(
				HumanoidRootPart,
				TweenInfo.new(Distance / 250, Enum.EasingStyle.Linear),
				{ CFrame = GoTo }
			)
			ResourceTween:Play()
			ResourceTween.Completed:Wait()
			ResourceTween = nil
		end
	end,
	AfterLoop = HarvestablesAfterLoop,
})

local Resources = {}

for _, Object: PVInstance in workspace.Harvestable:GetChildren() do
	if table.find(Resources, Object.Name) then
		continue
	end

	table.insert(Resources, Object.Name)
end

table.sort(Resources)

Tab:CreateDropdown({
	Name = "💎 • Harvestables",
	Options = Resources,
	MultipleOptions = true,
	Flag = "Harvestables",
})

Tab:CreateDivider()

local Dropdown
Dropdown = Tab:CreateDropdown({
	Name = "🌾 • Movement Method",
	Options = { "Teleport", "Tween" },
	CurrentOption = "Teleport",
	MultipleOptions = false,
	Flag = "HarvestablesMethod",
})

Tab:CreateToggle({
	Name = "🛡 • Safety Mode",
	CurrentValue = false,
	Flag = "SafetyMode",
	Callback = function(Value)
		if Value then
			return
		end

		HarvestablesAfterLoop()
	end,
})

Tab:CreateSection("Selling")

Tab:CreateToggle({
	Name = "💰 • Auto Sell Resources",
	CurrentValue = false,
	Flag = "Sell",
	Looped = true,
	Callback = function()
		if not Success then
			return
		end

		local Backpack: Backpack = Player:FindFirstChild("Backpack")

		if not Backpack then
			return
		end

		for _, Tool in Backpack:GetChildren() do
			if not Tool:IsA("Tool") then
				continue
			end

			if not table.find(Flags.ItemsToSell.CurrentOption, Tool.Name) then
				continue
			end

			if Tool:GetAttribute("Equipped") then
				continue
			end

			if not Tool:GetAttribute("Rarity") then
				continue
			end

			local SellEvent = GetInputRemote("SellEvent")

			if not SellEvent then
				continue
			end

			SellEvent:FireServer(Tool)
		end
	end,
})

local Items = {}

for _, Tool: Tool in game:GetService("ReplicatedStorage").Storage.Tools:GetChildren() do
	if not Tool:FindFirstChild("SellValue") then
		continue
	end

	table.insert(Items, Tool.Name)
end

table.sort(Items)

Tab:CreateDropdown({
	Name = "📃 • Select Items To Sell",
	Options = Items,
	MultipleOptions = true,
	Flag = "ItemsToSell",
})

Tab:CreateSection("Crafting")

local Dropdown
Dropdown = Tab:CreateDropdown({
	Name = "🛠 • Craft Item",
	Options = Items,
	CurrentOption = "",
	MultipleOptions = false,
	Callback = function(CurrentOption: any)
		CurrentOption = CurrentOption[1]

		if CurrentOption == "" then
			return
		end

		Player.PlayerGui.CraftingGui.LocalScript.RemoteEvent:FireServer({
			AmountToCraft = Flags.Quantity.CurrentValue,
			SelectedItem = {
				ToolTip = "",
				Station = "Buy",
				Name = CurrentOption,
			},
		})

		Dropdown:Set({ "" })
	end,
})

Tab:CreateSlider({
	Name = "🔢 • Quantity",
	Range = { 1, 100 },
	Increment = 1,
	Suffix = "Items",
	CurrentValue = 1,
	Flag = "Quantity",
})

local Tab: Tab = Window:CreateTab("Movement", "keyboard")

Tab:CreateSection("Sprinting")

Tab:CreateToggle({
	Name = ApplyUnsupportedName("💨 • Auto Sprint", Success),
	CurrentValue = false,
	Flag = "Sprint",
	Looped = true,
	Callback = function()
		if not Success then
			return
		end

		local Character = Player.Character

		if not Character then
			return
		end

		local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")

		if not Humanoid then
			return
		end

		if Humanoid.MoveDirection == Vector3.zero then
			return
		end

		Network.connect("Sprint", "Fire", Character, true)
	end,
})

Tab:CreateSection("Speed")

CreateFeature(Tab, "Speed")

Tab:CreateSection("Transporation")

local WorldAreas = game:GetService("ReplicatedStorage").WorldModel.Areas

local Areas = {}

for _, Object: Part in WorldAreas:GetChildren() do
	if table.find(Areas, Object.Name) then
		continue
	end

	table.insert(Areas, Object.Name)
end

local Dropdown
Dropdown = Tab:CreateDropdown({
	Name = "🌄 • Teleport to Area",
	Options = Areas,
	CurrentOption = "",
	MultipleOptions = false,
	Callback = function(CurrentOption: any)
		CurrentOption = CurrentOption[1]

		if CurrentOption == "" then
			return
		end

		local SelectedArea: Part = WorldAreas[CurrentOption]

		local Success = pcall(function()
			local Result = workspace:Raycast(SelectedArea.Position, Vector3.yAxis * -10000)

			if not Result then
				return Notify("Failed", "Failed to raycast in this area.")
			end

			local GoTo = CFrame.new(Result.Position)

			TeleportLocalCharacter(GoTo)

			Dropdown:Set({ "" })
		end)

		if not Success then
			return Notify("Error", "Failed to teleport.")
		end
	end,
})

local Tab: Tab = Window:CreateTab("Safety", "shield")

Tab:CreateSection("Damage")

local Original

Tab:CreateToggle({
	Name = ApplyUnsupportedName("🩸 • Remove Fall Damage", Success),
	CurrentValue = false,
	Flag = "FallDamage",
	Callback = function(Value)
		if not Success then
			return
		end

		if Value then
			Original = Network.connect
			Network.connect = function(RemoteName, Method, Character, Settings, ...)
				if Settings and typeof(Settings) == "table" and Settings.Config == "FallDamage" then
					return
				end

				return Original(RemoteName, Method, Character, Settings, ...)
			end
		elseif Original then
			Network.connect = Original
		end
	end,
})

local LavaParts = {}

Tab:CreateToggle({
	Name = "🌋 • Remove Lava",
	CurrentValue = false,
	Flag = "Lava",
	Callback = function(Value)
		if Value then
			for _, Part: Part in workspace:GetDescendants() do
				if Part.Name ~= "lava" or not Part:IsA("Part") then
					continue
				end

				LavaParts[Part] = Part.Parent
				Part.Parent = nil
			end
		else
			for Part: Part, Parent in LavaParts do
				Part.Parent = Parent
			end

			LavaParts = {}
		end
	end,
})

Tab:CreateSection("Healing")

Tab:CreateButton({
	Name = "💤 • Quick Sleep Anywhere (Heal)",
	Callback = function()
		if not Success then
			return
		end

		local Bed = workspace.Map:FindFirstChild("Bed", true)

		if not Bed then
			return Notify("Error", "Could not find a bed to sleep in.")
		end

		local Interact = GetInputRemote("Interact")

		if not Interact then
			return
		end

		Interact:FireServer({
			player = Player,
			Object = Bed,
			Action = "Sleep",
		})
	end,
})

Tab:CreateDivider()

Tab:CreateButton({
	Name = "💔 • Suicide Heal",
	Callback = function()
		local Character = Player.Character

		if not Character then
			return
		end

		local PreviousLocation = Character:GetPivot()

		local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")

		if not Humanoid then
			return
		end

		Humanoid.Health = 0

		Player.CharacterAdded:Once(function(NewCharacter)
			task.wait(Flags.Delay.CurrentValue)

			NewCharacter:PivotTo(PreviousLocation)
		end)
	end,
})

Tab:CreateSlider({
	Name = "🔃 • Delay After Respawn",
	Range = { 0, 5 },
	Increment = 0.01,
	Suffix = "Seconds",
	CurrentValue = 1.5,
	Flag = "Delay",
})

Tab:CreateSection("Identity")

CreateFeature(Tab, "HideIdentity")

local Tab: Tab = Window:CreateTab("Visuals", "sparkles")

Tab:CreateSection("ESP")

Tab:CreateSlider({
	Name = "📏 • ESP Max Distance",
	Range = { 500, 5000 },
	Increment = 10,
	Suffix = "Studs",
	CurrentValue = 200,
	Flag = "ESPDistance",
})

local CoreGui: Folder = game:GetService("CoreGui")

local function StringFloor(Number): string
	return tostring(math.floor(Number))
end

local function ESPModel(Model: Model, FlagName: string, OverheadText: string)
	if not Model or not Model.Parent then
		return
	end

	local FolderName = `{Model.Name}_{FlagName}`

	if not Flags[FlagName].CurrentValue then
		local Holder = CoreGui:FindFirstChild(FolderName)

		if not Holder then
			return
		end

		Holder:Destroy()

		return
	end

	do
		local ExistingFolder = CoreGui:FindFirstChild(FolderName)

		if ExistingFolder then
			ExistingFolder:Destroy()
		end
	end

	local Holder = Instance.new("Folder")
	Holder.Name = FolderName
	Holder.Parent = CoreGui

	-- Connect to model's AncestryChanged to clean up ESP when model is destroyed
	local AncestryConnection
	AncestryConnection = Model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			if Holder and Holder.Parent then
				Holder:Destroy()
			end
			if AncestryConnection then
				AncestryConnection:Disconnect()
			end
		end
	end)

	for _, Object in Model:GetChildren() do
		if not Object:IsA("BasePart") and not Object:IsA("Model") then
			continue
		end

		local BoxHandleAdornment = Instance.new("BoxHandleAdornment")
		BoxHandleAdornment.Name = Model.Name
		BoxHandleAdornment.Adornee = Object
		BoxHandleAdornment.AlwaysOnTop = true
		BoxHandleAdornment.ZIndex = 10
		BoxHandleAdornment.Size = if Object:IsA("BasePart") then Object.Size else Object:GetExtentsSize()
		BoxHandleAdornment.Transparency = 0.5
		BoxHandleAdornment.Color3 = Color3.fromRGB(255, 255, 255)
		BoxHandleAdornment.Parent = Holder
	end

	local BillboardGui = Instance.new("BillboardGui")
	BillboardGui.Name = Model.Name
	BillboardGui.Adornee = Model:FindFirstChild("Head") or Model:FindFirstChildWhichIsA("PVInstance")
	BillboardGui.Size = UDim2.new(0, 100, 0, 150)
	BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
	BillboardGui.AlwaysOnTop = true
	BillboardGui.Parent = Holder

	local TextLabel = Instance.new("TextLabel")
	TextLabel.BackgroundTransparency = 1
	TextLabel.Position = UDim2.new(0, 0, 0, -50)
	TextLabel.Size = UDim2.new(0, 100, 0, 100)
	TextLabel.Font = Enum.Font.SourceSansSemibold
	TextLabel.TextSize = 20
	TextLabel.TextColor3 = Color3.new(1, 1, 1)
	TextLabel.TextStrokeTransparency = 0
	TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	TextLabel.Text = "Loading..."
	TextLabel.ZIndex = 10
	TextLabel.Parent = BillboardGui

	-- Add health bar for mobs
	local HealthBarBackground
	local HealthBarFill

	if FlagName == "MobESP" then
		-- Health bar background
		HealthBarBackground = Instance.new("Frame")
		HealthBarBackground.Name = "HealthBarBackground"
		HealthBarBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		HealthBarBackground.BorderSizePixel = 0
		HealthBarBackground.Position = UDim2.new(0, 0, 0, 55)
		HealthBarBackground.Size = UDim2.new(1, 0, 0, 5)
		HealthBarBackground.ZIndex = 9
		HealthBarBackground.Parent = BillboardGui

		-- Health bar fill
		HealthBarFill = Instance.new("Frame")
		HealthBarFill.Name = "HealthBarFill"
		HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		HealthBarFill.BorderSizePixel = 0
		HealthBarFill.Size = UDim2.new(1, 0, 1, 0)
		HealthBarFill.ZIndex = 10
		HealthBarFill.Parent = HealthBarBackground
	end

	local RenderSteppedConnection: RBXScriptConnection
	RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if not Flags[FlagName].CurrentValue then
			-- Instead of destroying immediately, properly clean up
			for _, Object in Holder:GetChildren() do
				if Object:IsA("BoxHandleAdornment") then
					Object.Transparency = 1
				elseif Object:IsA("BillboardGui") then
					Object.Enabled = false
				end
			end
			task.delay(1, function()
				if Holder and Holder.Parent then
					Holder:Destroy()
				end
			end)
			RenderSteppedConnection:Disconnect()
			return
		end

		if not Holder.Parent then
			RenderSteppedConnection:Disconnect()
			return
		end

		local ModelHumanoid = Model and Model:FindFirstChild("Humanoid") :: Humanoid

		if not Model or not Model.Parent or (ModelHumanoid and ModelHumanoid.Health <= 0) then
			Holder:Destroy()
			RenderSteppedConnection:Disconnect()
			return
		end

		-- Check if model is within ESP distance range
		local Distance = math.huge
		if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
			Distance = (Model:GetPivot().Position - Player.Character:GetPivot().Position).Magnitude

			-- Hide ESP if beyond the max distance
			if Distance > Flags.ESPDistance.CurrentValue then
				-- Hide all ESP elements when beyond distance
				for _, Object in Holder:GetChildren() do
					if Object:IsA("BoxHandleAdornment") then
						Object.Transparency = 1
					elseif Object:IsA("BillboardGui") then
						Object.Enabled = false
					end
				end
				return
			else
				-- Show all ESP elements when within distance
				for _, Object in Holder:GetChildren() do
					if Object:IsA("BoxHandleAdornment") then
						Object.Transparency = 0.5
					elseif Object:IsA("BillboardGui") then
						Object.Enabled = true
					end
				end
			end
		end

		-- Update the display text with actual values
		local DisplayText = OverheadText
		DisplayText = DisplayText:gsub("<n>", Model.Name)

		-- Always update distance for both player and mob ESP
		if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
			DisplayText = DisplayText:gsub("<DISTANCE>", StringFloor(Distance))
		end

		if ModelHumanoid then
			DisplayText = DisplayText:gsub("<HEALTH>", StringFloor(ModelHumanoid.Health))
			DisplayText = DisplayText:gsub("<MAXHEALTH>", StringFloor(ModelHumanoid.MaxHealth))
			DisplayText = DisplayText:gsub(
				"<HEALTHPERCENTAGE>",
				StringFloor(ModelHumanoid.Health / ModelHumanoid.MaxHealth * 100)
			)

			-- Update health bar for mobs
			if FlagName == "MobESP" and HealthBarFill then
				local HealthPercent = ModelHumanoid.Health / ModelHumanoid.MaxHealth
				HealthBarFill.Size = UDim2.new(HealthPercent, 0, 1, 0)

				-- Change color based on health percentage
				local r, g = 255, 50
				if HealthPercent > 0.5 then
					-- Transition from red to green as health increases
					r = 255 - (HealthPercent - 0.5) * 2 * 205
					g = 50 + (HealthPercent - 0.5) * 2 * 205
				else
					-- Transition from yellow to red as health decreases
					r = 255
					g = 50 + HealthPercent * 2 * 205
				end

				HealthBarFill.BackgroundColor3 = Color3.fromRGB(r, g, 50)
			end
		end

		-- Only update text if BillboardGui is enabled
		for _, Object in Holder:GetChildren() do
			if Object:IsA("BillboardGui") and Object.Enabled then
				for _, Child in Object:GetChildren() do
					if Child:IsA("TextLabel") then
						Child.Text = DisplayText
					end
				end
			end
		end
	end)
end

local PlayerText = "Player: <n> | Health: <HEALTH>/<MAXHEALTH> (<HEALTHPERCENTAGE>%) | Distance: <DISTANCE>"

local function PlayerESP(TargetPlayer: Player)
	local function BeginEsp(NewCharacter: Model)
		ESPModel(NewCharacter, "PlayerESP", PlayerText)
	end

	if TargetPlayer.Character then
		BeginEsp(TargetPlayer.Character)
	end

	HandleConnection(TargetPlayer.CharacterAdded:Connect(BeginEsp), "PlayerESPCharacterAdded")
end

Tab:CreateToggle({
	Name = "🧍‍ • Player ESP",
	CurrentValue = false,
	Flag = "PlayerESP",
	Callback = function(Value)
		-- First handle existing ESP elements
		for _, Existing in CoreGui:GetChildren() do
			if Existing.Name:find("_PlayerESP") then
				if not Value then
					-- Clean up properly
					for _, Object in Existing:GetChildren() do
						if Object:IsA("BoxHandleAdornment") then
							Object.Transparency = 1
						elseif Object:IsA("BillboardGui") then
							Object.Enabled = false
						end
					end
					task.delay(1, function()
						if Existing and Existing.Parent then
							Existing:Destroy()
						end
					end)
				end
			end
		end

		-- Then create new ESP for players if enabled
		if Value then
			for _, TargetPlayer in Players:GetPlayers() do
				if TargetPlayer == Player then
					continue
				end

				PlayerESP(TargetPlayer)
			end
		end
	end,
})

-- Improved player joining handler
local function OnPlayerAdded(TargetPlayer)
	if TargetPlayer == Player then
		return
	end

	if Flags.PlayerESP and Flags.PlayerESP.CurrentValue then
		PlayerESP(TargetPlayer)
	end

	-- Also handle when player's character is added
	TargetPlayer.CharacterAdded:Connect(function(Character)
		if Flags.PlayerESP and Flags.PlayerESP.CurrentValue then
			ESPModel(Character, "PlayerESP", PlayerText)
		end
	end)
end

-- Connect to PlayerAdded event
HandleConnection(Players.PlayerAdded:Connect(OnPlayerAdded), "PlayerESP")

-- Apply to existing players
for _, TargetPlayer in Players:GetPlayers() do
	if TargetPlayer ~= Player then
		OnPlayerAdded(TargetPlayer)
	end
end

local MobText = "Mob: <n> | Health: <HEALTH>/<MAXHEALTH> (<HEALTHPERCENTAGE>%) | Distance: <DISTANCE>"

local function MobESP(Mob: Model)
	if not Mob:GetAttribute("NPC") then
		return
	end

	ESPModel(Mob, "MobESP", MobText)
end

Tab:CreateToggle({
	Name = "🐺 • Mob ESP",
	CurrentValue = false,
	Flag = "MobESP",
	Callback = function(Value)
		-- First handle existing ESP elements
		for _, Existing in CoreGui:GetChildren() do
			if Existing.Name:find("_MobESP") then
				if not Value then
					-- Clean up properly
					for _, Object in Existing:GetChildren() do
						if Object:IsA("BoxHandleAdornment") then
							Object.Transparency = 1
						elseif Object:IsA("BillboardGui") then
							Object.Enabled = false
						end
					end
					task.delay(1, function()
						if Existing and Existing.Parent then
							Existing:Destroy()
						end
					end)
				end
			end
		end

		-- Then create new ESP for mobs if enabled
		if Value then
			for _, Mob: Model in workspace.Alive:GetChildren() do
				MobESP(Mob)
			end
		end
	end,
})

-- Improved mob spawning handler
local function OnMobAdded(Mob)
	if not Mob:IsA("Model") then
		return
	end

	-- Wait a short time for attributes to load
	task.delay(0.1, function()
		if Flags.MobESP and Flags.MobESP.CurrentValue then
			MobESP(Mob)
		end
	end)
end

-- Connect to ChildAdded event
HandleConnection(workspace.Alive.ChildAdded:Connect(OnMobAdded), "MobESP")

-- Apply to existing mobs
for _, Mob in workspace.Alive:GetChildren() do
	if Mob:IsA("Model") then
		OnMobAdded(Mob)
	end
end

Tab:CreateSection("Effects")

local Lighting = game:GetService("Lighting")

local FogEnd
local FogObjects = {}

Tab:CreateToggle({
	Name = "🌫 • Remove Fog",
	CurrentValue = false,
	Flag = "Fog",
	Callback = function(Value)
		if Value then
			FogEnd = Lighting.FogEnd

			Lighting.FogEnd = 100000

			for _, v in Lighting:GetDescendants() do
				if v:IsA("Atmosphere") then
					table.insert(FogObjects, v)
					v.Parent = nil
				end
			end
		elseif FogEnd then
			Lighting.FogEnd = FogEnd

			for _, v in FogObjects do
				v.Parent = Lighting
			end

			FogObjects = {}
		end
	end,
})

getgenv().CreateUniversalTabs()
