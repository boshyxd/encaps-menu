--!strict
local StartLoadTime = tick()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

local getgenv: () -> { [string]: any } = getfenv().getgenv

local PlaceName: string = getgenv().PlaceName
	or game:GetService("AssetService"):GetGamePlacesAsync(game.GameId):GetCurrentPage()[1].Name

local getexecutorname = getfenv().getexecutorname
local identifyexecutor: () -> string = getfenv().identifyexecutor
local request = getfenv().request
local getconnections: (RBXScriptSignal) -> { RBXScriptConnection } = getfenv().getconnections
local queue_on_teleport: (Code: string) -> () = getfenv().queue_on_teleport
local setfpscap: (FPS: number) -> () = getfenv().setfpscap
local isrbxactive: () -> boolean = getfenv().isrbxactive
local setclipboard: (Text: string) -> () = getfenv().setclipboard
local firesignal: (RBXScriptSignal) -> () = getfenv().firesignal

if not getgenv().ScriptVersion then
	getgenv().ScriptVersion = "Dev Mode"
end

local ScriptVersion = getgenv().ScriptVersion

getgenv().gethui = function()
	return game:GetService("CoreGui")
end

getgenv().EncapConnections = getgenv().EncapConnections or {}

local function HandleConnection(Connection: RBXScriptConnection?, Name: string)
	if getgenv().EncapConnections[Name] then
		getgenv().EncapConnections[Name]:Disconnect()
	end

	getgenv().EncapConnections[Name] = Connection
end

getgenv().HandleConnection = HandleConnection

getgenv().GetClosestChild = function(
	Children: { PVInstance },
	Callback: ((Child: PVInstance) -> boolean)?,
	MaxDistance: number?
)
	local Character = Player.Character

	if not Character then
		return
	end

	local HumanoidRootPart: Part = Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then
		return
	end

	local CurrentPosition: Vector3 = HumanoidRootPart.Position

	local ClosestMagnitude = MaxDistance or math.huge
	local ClosestChild

	for _, Child in Children do
		if not Child:IsA("PVInstance") then
			continue
		end

		if Callback and Callback(Child) then
			continue
		end

		local Magnitude = (Child:GetPivot().Position - CurrentPosition).Magnitude

		if Magnitude < ClosestMagnitude then
			ClosestMagnitude = Magnitude
			ClosestChild = Child
		end
	end

	return ClosestChild
end

local UnsupportedName = " (Executor Unsupported)"

local function ApplyUnsupportedName(Name: string, Condition: boolean)
	return Name .. if Condition then "" else UnsupportedName
end

getgenv().ApplyUnsupportedName = ApplyUnsupportedName

if not getgenv().PlaceFileName then
	local PlaceFileName = PlaceName:gsub("%b[]", "")
	PlaceFileName = PlaceFileName:gsub("[^%a]", "")
	getgenv().PlaceFileName = PlaceFileName
end

local function SendNotification(
	Title: string,
	Text: string,
	Duration: number?,
	Button1: string?,
	Button2: string?,
	Callback: BindableFunction?
)
	StarterGui:SetCore("SendNotification", {
		Title = Title,
		Text = Text,
		Duration = Duration or 10,
		Button1 = Button1,
		Button2 = Button2,
		Callback = Callback,
	})
end

task.spawn(function()
	if ScriptVersion:sub(1, 1) == "v" then
		local PlaceFileName = getgenv().PlaceFileName

		local BindableFunction = Instance.new("BindableFunction")

		local Response = false

		local Button1 = "✅ Yes"
		local Button2 = "❌ No"

		local File =
			`https://raw.githubusercontent.com/alyssagithub/Scripts/refs/heads/main/FrostByte/Games/{PlaceFileName}.lua` -- Still using FrostByte's resources

		BindableFunction.OnInvoke = function(Button: string)
			Response = true

			if Button == Button1 then
				local Temp = loadstring(game:HttpGet(File))

				if not Temp then
					return warn("Failed to load the script for the current game.")
				end

				Temp()
			end
		end

		while task.wait(60) do
			local Result = game:HttpGet(File)

			if not Result then
				continue
			end

			Result = Result:split('getgenv().ScriptVersion = "')[2]
			Result = Result:split('"')[1]

			if Result == ScriptVersion then
				continue
			end

			SendNotification(
				`A new Encap's Menu version {Result} has been detected!`,
				"Would you like to load it?",
				math.huge,
				Button1,
				Button2,
				BindableFunction
			)

			break
		end
	end
end)

local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

HandleConnection(
	Player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.zero)
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightMeta, false, game)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightMeta, false, game)
	end),
	"AntiAFK"
)

local OriginalFlags = {}

if getgenv().Flags then
	for FlagName: string, FlagInfo in getgenv().Flags do
		if typeof(FlagInfo.CurrentValue) ~= "boolean" then
			continue
		end

		OriginalFlags[FlagName] = FlagInfo.CurrentValue
		FlagInfo:Set(false)
	end
end

if getgenv().Rayfield then
	getgenv().Rayfield:Destroy()
end

local Rayfield

if getgenv().RayfieldTesting then
	local Temp = loadstring(getgenv().RayfieldTesting)

	if not Temp then
		return warn("Failed to load rayfield testing.")
	end

	Rayfield = Temp()
	print("Running Rayfield Testing")
else
	repeat
		pcall(function()
			local Temp = loadstring(game:HttpGet(
				"https://raw.githubusercontent.com/alyssagithub/Scripts/refs/heads/main/FrostByte/Rayfield.luau" -- Still using FrostByte's resources
			))

			if not Temp then
				return warn("Failed to load rayfield.")
			end

			Rayfield = Temp()
		end)
		task.wait()
	until Rayfield
end

getgenv().Initiated = nil

type Element = {
	CurrentValue: any,
	CurrentOption: { string },
	Set: (self: Element, any) -> (),
}

type Flags = {
	[string]: Element,
}

type Tab = {
	CreateSection: (self: Tab, Name: string) -> Element,
	CreateDivider: (self: Tab) -> Element,
	CreateToggle: (self: Tab, any) -> Element,
	CreateSlider: (self: Tab, any) -> Element,
	CreateDropdown: (self: Tab, any) -> Element,
	CreateButton: (self: Tab, any) -> Element,
	CreateLabel: (self: Tab, any, any?) -> Element,
	CreateParagraph: (self: Tab, any) -> Element,
}

local function Notify(Title: string, Content: string, Image: string)
	if not Rayfield then
		return
	end

	Rayfield:Notify({
		Title = Title,
		Content = Content,
		Duration = 10,
		Image = Image or "info",
	})
end

getgenv().Notify = Notify

local Flags: Flags = Rayfield.Flags

getgenv().Flags = Flags

local Window = Rayfield:CreateWindow({
	Name = `Encap's Menu | {PlaceName} | {ScriptVersion or "Dev Mode"}`,
	Icon = "snowflake",
	LoadingTitle = "❄ Brought to you by Encap ❄",
	LoadingSubtitle = PlaceName,
	Theme = "DarkBlue",

	DisableRayfieldPrompts = true,
	DisableBuildWarnings = true,

	ConfigurationSaving = {
		Enabled = true,
		FolderName = "EncapMenu",
		FileName = `{getgenv().PlaceFileName or `DevMode-{game.PlaceId}`}-{Player.Name}`,
	},

	Discord = {
		Enabled = true,
		Invite = "sS3tDP6FSB",
		RememberJoins = true,
	},
})

getgenv().Window = Window

local Tab: Tab = Window:CreateTab("Home", "snowflake")

Tab:CreateSection("Join our Discord!")

Tab:CreateLabel("discord.gg/sS3tDP6FSB", "messages-square")

Tab:CreateSection("Performance")

local PingLabel = Tab:CreateLabel("Ping: 0 ms", "wifi")
local FPSLabel = Tab:CreateLabel("FPS: 0/s", "monitor")

local Stats = game:GetService("Stats")

task.spawn(function()
	while getgenv().Flags == Flags and task.wait(0.25) do
		PingLabel:Set(`Ping: {math.floor(Stats.PerformanceStats.Ping:GetValue() * 100) / 100} ms`)
		FPSLabel:Set(`FPS: {math.floor(1 / Stats.FrameTime * 10) / 10}/s`)
	end
end)

Tab:CreateSection("Changelog")

Tab:CreateParagraph({ Title = `{PlaceName} {ScriptVersion}`, Content = getgenv().Changelog or "Changelog Not Found" })

--------------------------------------------------------------------------------------------------------------

local SpeedConnection: RBXScriptConnection?
local ConnectedHumanoid

local function SetSpeed()
	local Character = Player.Character

	if not Character then
		return
	end

	local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")

	if not Humanoid then
		return
	end

	if Flags.ChangeSpeed.CurrentValue then
		Humanoid.WalkSpeed = Flags.Speed.CurrentValue
	end

	if not SpeedConnection then
		SpeedConnection = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(SetSpeed)
		ConnectedHumanoid = Humanoid
		HandleConnection(SpeedConnection, "WalkSpeedConnection")
	end
end

HandleConnection(
	Player.CharacterAdded:Connect(function()
		if SpeedConnection then
			SpeedConnection:Disconnect()
			SpeedConnection = nil
		end

		SetSpeed()
	end),
	"WalkSpeedCharacterAdded"
)

local Connections = {}

local OriginalText = {}

local function HandleUsernameChange(Object)
	if not Flags.HideIdentity.CurrentValue then
		return
	end

	if not Object:IsA("TextLabel") and not Object:IsA("TextBox") and not Object:IsA("TextButton") then
		return
	end

	local NameReplacement = Flags.NameReplacement.CurrentValue

	if not Connections[Object] then
		Connections[Object] = Object:GetPropertyChangedSignal("Text"):Connect(function()
			HandleUsernameChange(Object)
		end)
	end

	if Object.Text:find(Player.Name) then
		OriginalText[Object] = Object.Text
		Object.Text = Object.Text:gsub(Player.Name, NameReplacement)
	elseif Object.Text:find(Player.DisplayName) then
		OriginalText[Object] = Object.Text
		Object.Text = Object.Text:gsub(Player.DisplayName, NameReplacement)
	end
end

local DescendantAddedConnection

type FeaturesList = {
	[string]: {
		{
			Element: string,
			Info: {},
		}
	},
}

local Features: FeaturesList = {
	Speed = {
		{
			Element = "Toggle",
			Info = {
				Name = "⚡ • Change Speed",
				CurrentValue = false,
				Flag = "ChangeSpeed",
				Callback = function(Value)
					if not Player.Character or not Value then
						return
					end

					SetSpeed()
				end,
			},
		},
		{
			Element = "Slider",
			Info = {
				Name = "⚡ • Speed",
				Range = { 0, 250 },
				Increment = 1,
				Suffix = "Studs/s",
				CurrentValue = game:GetService("StarterPlayer").CharacterWalkSpeed,
				Flag = "Speed",
				Callback = SetSpeed,
			},
		},
		{
			Element = "Keybind",
			Info = {
				Name = "⚡ • Change Speed Keybind",
				CurrentKeybind = "Z",
				HoldToInteract = false,
				Flag = "ChangeSpeedKeybind",
				Callback = function()
					Flags.ChangeSpeed:Set(not Flags.ChangeSpeed.CurrentValue)
				end,
			},
		},
	},
	HideIdentity = {
		{
			Element = "Toggle",
			Info = {
				Name = "🎭 • Hide Identity (Client-Sided)",
				CurrentValue = false,
				Flag = "HideIdentity",
				Callback = function(Value)
					if Value and not DescendantAddedConnection then
						for i, v in game:GetDescendants() do
							HandleUsernameChange(v)
						end

						DescendantAddedConnection = game.DescendantAdded:Connect(HandleUsernameChange)

						HandleConnection(DescendantAddedConnection, "HideIdentity")
					elseif DescendantAddedConnection then
						DescendantAddedConnection:Disconnect()
						DescendantAddedConnection = nil

						for Object, Text in OriginalText do
							Object.Text = Text
						end

						OriginalText = {}
					end
				end,
			},
		},
		{
			Element = "Input",
			Info = {
				Name = "💬 • Name To Replace With",
				CurrentValue = "Encap",
				PlaceholderText = "New Name Here",
				RemoveTextAfterFocusLost = false,
				Flag = "NameReplacement",
			},
		},
	},
}

getgenv().CreateFeature = function(Tab: Tab, FeatureName: string)
	if not Features[FeatureName] then
		return warn(`The feature '{FeatureName}' does not exist in the Features.`)
	end

	for _, Data in Features[FeatureName] do
		Tab[`Create{Data.Element}`](Tab, Data.Info)
	end
end

getgenv().CreateUniversalTabs = function()
	Rayfield:LoadConfiguration()

	task.wait(1)

	for FlagName: string, CurrentValue: boolean? in OriginalFlags do
		local FlagInfo = Flags[FlagName]

		if not FlagInfo then
			continue
		end

		FlagInfo:Set(CurrentValue)
	end

	Notify("Welcome to Encap's Menu", `Loaded in {math.floor((tick() - StartLoadTime) * 10) / 10}s`, "loader-circle")
end

local EncapStarted = getgenv().EncapStarted

if EncapStarted then
	EncapStarted()
end
