-- Zwischensequenz 1: Man sitzt im Auto (Fahrer oder Beifahrer) und schaut sich in der
-- Ego-Perspektive um. Das Auto fährt etwa 30 Sekunden durch den Wald und hält in der
-- Parkbucht. Dann kommt der Fremde aus dem Wald und bleibt am Fenster stehen.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Route = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelRoute"))
local player = Players.LocalPlayer
local cutscene = ReplicatedStorage:WaitForChild("Cutscene")
local puppets = cutscene:WaitForChild("Puppets")

local SIT_ANIMATION = "rbxassetid://2506281703"
local WALK_ANIMATION = "rbxassetid://507777826"
local IDLE_ANIMATION = "rbxassetid://507766388"
local LOOK_SIDE = math.rad(110)
local LOOK_UP, LOOK_DOWN = math.rad(40), math.rad(55)
local SENSITIVITY = 0.0035

for _, coreType in { Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health, Enum.CoreGuiType.PlayerList } do
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreType, false)
end

------------------------------------------------------------------ Anzeige
local function create(className, props)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	instance.Parent = props.Parent
	return instance
end

local gui = create("ScreenGui", {
	Name = "CutsceneUI",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 10,
	Parent = player:WaitForChild("PlayerGui"),
})
-- Kinobalken oben und unten
for _, info in { { 0, 0 }, { 1, 1 } } do
	create("Frame", {
		AnchorPoint = Vector2.new(0, info[2]),
		Position = UDim2.fromScale(0, info[1]),
		Size = UDim2.fromScale(1, 0.09),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = gui,
	})
end
local fade = create("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = gui,
})
local function label(props)
	props.BackgroundTransparency = 1
	props.TextTransparency = 1
	props.TextStrokeTransparency = 1
	props.ZIndex = 6
	props.Parent = gui
	return create("TextLabel", props)
end
local chapter = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.new(0.8, 0, 0, 40),
	Font = Enum.Font.SpecialElite,
	Text = "KAPITEL 1",
	TextSize = 28,
	TextColor3 = Color3.fromRGB(220, 205, 185),
})
local chapterTitle = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.8, 0, 0, 60),
	Font = Enum.Font.SpecialElite,
	Text = "Die Fahrt",
	TextSize = 48,
	TextColor3 = Color3.fromRGB(240, 230, 215),
})
local caption = label({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0.88, 0),
	Size = UDim2.new(0.8, 0, 0, 60),
	Font = Enum.Font.SpecialElite,
	Text = "",
	TextSize = 24,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(240, 235, 225),
})

local function showText(target, visible, duration)
	TweenService:Create(target, TweenInfo.new(duration), {
		TextTransparency = visible and 0 or 1,
		TextStrokeTransparency = visible and 0.6 or 1,
	}):Play()
end

------------------------------------------------------------------ Start abwarten
local startTime = cutscene:GetAttribute("StartTime")
while not startTime do
	cutscene:GetAttributeChangedSignal("StartTime"):Wait()
	startTime = cutscene:GetAttribute("StartTime")
end
local seatName = player:GetAttribute("CutsceneSeat")
while not seatName do
	player:GetAttributeChangedSignal("CutsceneSeat"):Wait()
	seatName = player:GetAttribute("CutsceneSeat")
end

------------------------------------------------------------------ Eigenes Auto
local car = cutscene:WaitForChild("Car"):Clone()
local root = car.PrimaryPart
root.Anchored = true
car.Parent = workspace
root.CFrame = Route.carCFrame(Route.START_S)

local steering
local wheels = {}
for _, descendant in car:GetDescendants() do
	if descendant:IsA("Weld") then
		if descendant.Name == "SteeringWeld" then
			steering = { weld = descendant, base = descendant.C0 }
		elseif descendant.Name == "WheelWeld" then
			table.insert(wheels, { weld = descendant, base = descendant.C0, front = descendant:GetAttribute("Front") })
		end
	end
end
local speedNeedle = car:FindFirstChild("SpeedNeedle", true)
local speedText = car:FindFirstChild("SpeedText", true)
local rpmNeedle = car:FindFirstChild("RpmNeedle", true)

local function loadTrack(humanoid, animationId, looped)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(animator.LoadAnimation, animator, animation)
	if ok then
		track.Looped = looped
		return track
	end
	return nil
end

------------------------------------------------------------------ Mitfahrer als Puppe im Auto
local seatedPlayers = {}
local function seatPuppets()
	for _, other in Players:GetPlayers() do
		local otherSeat = other:GetAttribute("CutsceneSeat")
		local template = puppets:FindFirstChild(tostring(other.UserId))
		if other ~= player and not seatedPlayers[other] and otherSeat and template then
			seatedPlayers[other] = true
			local puppet = template:Clone()
			local hip = puppet:FindFirstChild("HumanoidRootPart")
			local humanoid = puppet:FindFirstChildOfClass("Humanoid")
			for _, part in puppet:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
					part.Massless = true
				end
			end
			hip.CFrame = root.CFrame * Route.CAR_HIPS[otherSeat]
			local weld = Instance.new("Weld")
			weld.Part0 = root
			weld.Part1 = hip
			weld.C0 = Route.CAR_HIPS[otherSeat]
			weld.Parent = hip
			puppet.Parent = car
			local sit = loadTrack(humanoid, SIT_ANIMATION, true)
			if sit then
				sit:Play(0)
			end
		end
	end
end
seatPuppets()
puppets.ChildAdded:Connect(seatPuppets)
Players.PlayerAdded:Connect(function(other)
	other:GetAttributeChangedSignal("CutsceneSeat"):Connect(seatPuppets)
end)

------------------------------------------------------------------ Der Fremde
local stranger, strangerRoot, strangerHumanoid, strangerIdle
local strangerTemplate = cutscene:WaitForChild("Stranger", 10)
if strangerTemplate then
	stranger = strangerTemplate:Clone()
	strangerRoot = stranger:FindFirstChild("HumanoidRootPart")
	strangerHumanoid = stranger:FindFirstChildOfClass("Humanoid")
	local waypoints = Route.strangerWaypoints()
	local height = Vector3.new(0, strangerHumanoid.HipHeight + strangerRoot.Size.Y / 2, 0)
	strangerRoot.Anchored = true
	stranger.Parent = workspace
	stranger:PivotTo(CFrame.lookAt(waypoints[1] + height, waypoints[2] + height))
	strangerIdle = loadTrack(strangerHumanoid, IDLE_ANIMATION, true)
	if strangerIdle then
		strangerIdle:Play()
	end
end

local strangerArrived
local function strangerWalksToCar()
	if not stranger then
		return
	end
	local walk = loadTrack(strangerHumanoid, WALK_ANIMATION, true)
	strangerRoot.Anchored = false
	if strangerIdle then
		strangerIdle:Stop(0.3)
	end
	if walk then
		walk:Play(0.3, 1, 0.7)
	end
	task.spawn(function()
		local waypoints = Route.strangerWaypoints()
		for i = 2, #waypoints do
			strangerHumanoid:MoveTo(waypoints[i])
			strangerHumanoid.MoveToFinished:Wait()
		end
		if walk then
			walk:Stop(0.5)
		end
		if strangerIdle then
			strangerIdle:Play(0.5)
		end
		-- Er dreht sich zum Auto und starrt durchs Fenster
		local carPosition = root.Position
		strangerRoot.Anchored = true
		strangerRoot.CFrame = CFrame.lookAt(strangerRoot.Position, Vector3.new(carPosition.X, strangerRoot.Position.Y, carPosition.Z))
		strangerArrived = os.clock()
	end)
end

------------------------------------------------------------------ Flackernde Laterne an der Parkbucht
task.spawn(function()
	local rng = Random.new()
	while true do
		task.wait(rng:NextNumber(0.8, 3.5))
		for _, lens in CollectionService:GetTagged("FlickerLamp") do
			local light = lens:FindFirstChildWhichIsA("Light")
			if light then
				local brightness, color = light.Brightness, lens.Color
				for _ = 1, rng:NextInteger(2, 6) do
					light.Brightness = brightness * 0.05
					lens.Color = color:Lerp(Color3.new(0, 0, 0), 0.8)
					task.wait(rng:NextNumber(0.03, 0.15))
					light.Brightness = brightness
					lens.Color = color
					task.wait(rng:NextNumber(0.04, 0.2))
				end
			end
		end
	end
end)

------------------------------------------------------------------ Umsehen mit Maus oder Finger
local yaw, pitch = 0, 0
UserInputService.InputChanged:Connect(function(input)
	local kind = input.UserInputType
	if kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch then
		yaw = math.clamp(yaw - input.Delta.X * SENSITIVITY, -LOOK_SIDE, LOOK_SIDE)
		pitch = math.clamp(pitch - input.Delta.Y * SENSITIVITY, -LOOK_DOWN, LOOK_UP)
	end
end)

------------------------------------------------------------------ Ablauf
local done = {}
local function once(name, action)
	if not done[name] then
		done[name] = true
		action()
	end
end

local camera = workspace.CurrentCamera
local wheelSpin = 0

RunService.RenderStepped:Connect(function(deltaTime)
	local t = workspace:GetServerTimeNow() - startTime
	local s, speed = Route.driveDistance(t)
	local moving = math.clamp(speed / Route.SPEED, 0, 1)

	-- Auto: Straßenunebenheiten und leichtes Wanken, im Stand nur der laufende Motor
	local bump = (math.noise(s * 0.12, 1.7) * 0.05 + math.noise(t * 9, 4.2) * 0.008) * moving + math.noise(t * 14, 8.1) * 0.004
	local roll = math.noise(s * 0.05, 3.3) * 0.012 * moving
	root.CFrame = Route.carCFrame(s) * CFrame.new(0, bump, 0) * CFrame.Angles(0, 0, roll)

	-- Räder und Lenkrad
	local steer = Route.steerAt(s)
	wheelSpin = (wheelSpin + speed * deltaTime / 1.25) % (math.pi * 2)
	for _, wheel in wheels do
		local turn = wheel.front and CFrame.Angles(0, steer * 0.6, 0) or CFrame.new()
		wheel.weld.C0 = wheel.base * turn * CFrame.Angles(-wheelSpin, 0, 0)
	end
	if steering then
		steering.weld.C0 = steering.base * CFrame.Angles(0, 0, steer * 4)
	end

	-- Tacho und Drehzahl
	local kmh = speed * 1.3
	if speedNeedle then
		speedNeedle.Rotation = -120 + math.clamp(kmh / 200, 0, 1) * 240
		speedText.Text = tostring(math.floor(kmh + 0.5))
	end
	if rpmNeedle then
		rpmNeedle.Rotation = -120 + (0.12 + 0.3 * moving + math.noise(t * 2, 5) * 0.02) * 240
	end

	-- Kamera in den Augen des Spielers, leicht wackelnd
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 74
	local headShake = Vector3.new(math.noise(t * 1.3, 0.5) * 0.03, math.noise(t * 1.1, 2.5) * 0.03, 0)
	camera.CFrame = root.CFrame
		* Route.CAR_EYES[seatName]
		* CFrame.new(headShake)
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(pitch, 0, 0)
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	-- Zeitplan
	if t >= 0 then
		once("fadeIn", function()
			TweenService:Create(fade, TweenInfo.new(2.5), { BackgroundTransparency = 1 }):Play()
		end)
	end
	if t >= 2.5 then
		once("chapterIn", function()
			showText(chapter, true, 1.5)
			showText(chapterTitle, true, 2)
		end)
	end
	if t >= 7 then
		once("chapterOut", function()
			showText(chapter, false, 1.5)
			showText(chapterTitle, false, 1.5)
		end)
	end
	if t >= Route.STOP_TIME + 1.5 then
		once("stranger", strangerWalksToCar)
	end
	if strangerArrived and os.clock() - strangerArrived > 2 then
		once("dialogue", function()
			caption.Text = "Ein Mann steht am Fenster und starrt herein …\n(Hier beginnt das Gespräch – der Text folgt.)"
			showText(caption, true, 1.5)
		end)
	end
end)
