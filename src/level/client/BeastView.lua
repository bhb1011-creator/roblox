-- Das Biest auf dem Client: zeigt die eigene Kopie dort, wo der Server sie hinsetzt
-- (Teil "BeastAnchor"), bewegt die Gelenke, spielt Knurren, Brüllen, Atmen und Schritte,
-- zeigt den Schreckmoment und den Todesbildschirm. Außerdem: Rennen mit Shift (Ausdauer).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Beast = require(Shared:WaitForChild("Beast"))
local Route = require(Shared:WaitForChild("LevelRoute"))

local BeastView = {}

local HIDDEN = CFrame.new(0, -200, 0) -- unter der Welt (aber über der Grenze, ab der Roblox Teile löscht)
local STRIDE = 9 -- Studs pro Laufschritt-Paar (lange Beine)
local SPRINT_TIME, RECOVER_TIME = 5, 8 -- Sekunden Rennen, bis die Ausdauer leer ist / wieder voll

local player = Players.LocalPlayer
local model, joints, root
local sounds = {}
local makeSound, fade, gui
local current = HIDDEN
local visible = false
local phase, amount, lastStepPhase = 0, 0, 0
local jumpscareUntil
local shakeUntil = 0
local warningLabel, deathLabel, flash, staminaBar, staminaFill, sprintButton
local stamina, sprinting = 1, false

local function label(props)
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.SpecialElite
	text.TextColor3 = Color3.fromRGB(230, 40, 30)
	text.TextStrokeTransparency = 0.4
	text.TextTransparency = 1
	text.ZIndex = 8
	for key, value in props do
		text[key] = value
	end
	text.Parent = gui
	return text
end

function BeastView.init(screenGui, soundFactory, fadeFrame)
	gui, makeSound, fade = screenGui, soundFactory, fadeFrame
	model, joints = Beast.build(workspace)
	root = model.PrimaryPart
	model:PivotTo(HIDDEN)

	sounds.breath = makeSound("beastBreath", root, { Looped = true, Volume = 0.9, RollOffMaxDistance = 90 })
	sounds.step = makeSound("beastStep", root, { Volume = 1, RollOffMaxDistance = 120 })
	sounds.roar = makeSound("roar", root, { Volume = 1.6, RollOffMaxDistance = 250 })
	sounds.roarClose = makeSound("roar", game:GetService("SoundService"), { Volume = 1.4 })
	sounds.sting = makeSound("sting", game:GetService("SoundService"), { Volume = 1 })

	warningLabel = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.8, 0, 0, 60),
		TextSize = 46,
		Text = "RUN!",
	})
	deathLabel = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0, 70),
		TextSize = 52,
		Text = "YOU DIED",
	})
	flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 4
	flash.Parent = gui

	-- Ausdauer beim Rennen
	staminaBar = Instance.new("Frame")
	staminaBar.AnchorPoint = Vector2.new(0.5, 1)
	staminaBar.Position = UDim2.fromScale(0.5, 0.95)
	staminaBar.Size = UDim2.fromOffset(220, 6)
	staminaBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	staminaBar.BackgroundTransparency = 0.4
	staminaBar.BorderSizePixel = 0
	staminaBar.Visible = false
	staminaBar.ZIndex = 7
	staminaBar.Parent = gui
	staminaFill = Instance.new("Frame")
	staminaFill.Size = UDim2.fromScale(1, 1)
	staminaFill.BackgroundColor3 = Color3.fromRGB(210, 205, 190)
	staminaFill.BorderSizePixel = 0
	staminaFill.ZIndex = 7
	staminaFill.Parent = staminaBar

	-- Am Handy gibt es einen Knopf zum Rennen
	sprintButton = Instance.new("TextButton")
	sprintButton.AnchorPoint = Vector2.new(1, 1)
	sprintButton.Position = UDim2.new(1, -30, 1, -170)
	sprintButton.Size = UDim2.fromOffset(90, 90)
	sprintButton.BackgroundColor3 = Color3.fromRGB(15, 14, 13)
	sprintButton.BackgroundTransparency = 0.35
	sprintButton.Font = Enum.Font.SpecialElite
	sprintButton.TextColor3 = Color3.fromRGB(230, 225, 215)
	sprintButton.TextSize = 18
	sprintButton.Text = "RUN"
	sprintButton.Visible = false
	sprintButton.ZIndex = 7
	sprintButton.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = sprintButton
	sprintButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sprinting = true
		end
	end)
	sprintButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sprinting = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
			sprinting = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
			sprinting = false
		end
	end)
end

local function showText(target, visibleNow, duration)
	TweenService:Create(target, TweenInfo.new(duration), {
		TextTransparency = visibleNow and 0 or 1,
		TextStrokeTransparency = visibleNow and 0.4 or 1,
	}):Play()
end

-- Knurren irgendwo im Wald (3D, damit man hört, aus welcher Richtung)
local function growlAt(position, volume)
	local holder = Instance.new("Part")
	holder.Name = "BeastGrowl"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.CFrame = CFrame.new(position)
	holder.Parent = workspace
	local growl = makeSound("growl", holder, { Volume = volume, RollOffMaxDistance = 200, RollOffMinDistance = 20 })
	if growl then
		growl:Play()
	end
	task.delay(6, function()
		holder:Destroy()
	end)
end

-- Nachrichten vom Server
function BeastView.handle(message)
	if message.type == "beastWarn" then
		growlAt(message.position, message.level == 1 and 1.2 or 1.8)
	elseif message.type == "chase" then
		if message.target == player.UserId then
			if sounds.roarClose then
				sounds.roarClose:Play()
			end
			warningLabel.Text = "RUN! (Shift)"
			warningLabel.TextSize = 46
			warningLabel.TextColor3 = Color3.fromRGB(230, 40, 30)
			showText(warningLabel, true, 0.2)
			task.delay(2.5, function()
				showText(warningLabel, false, 1)
			end)
		elseif sounds.roar then
			sounds.roar:Play()
		end
	elseif message.type == "escaped" then
		showText(warningLabel, false, 0.5)
	elseif message.type == "caught" then
		jumpscareUntil = os.clock() + 0.9
		shakeUntil = jumpscareUntil
		if sounds.roarClose then
			sounds.roarClose:Play()
		end
		if sounds.sting then
			sounds.sting:Play()
		end
		flash.BackgroundTransparency = 0.35
		task.delay(0.9, function()
			fade.BackgroundTransparency = 0
			flash.BackgroundTransparency = 1
			showText(warningLabel, false, 0.1)
			showText(deathLabel, true, 0.6)
		end)
	elseif message.type == "respawned" then
		showText(deathLabel, false, 0.8)
		TweenService:Create(fade, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
	end
end

-- Jedes Bild: Biest bewegen und Rennen/Ausdauer
function BeastView.update(deltaTime, camera, walkingFreely, finished)
	-- Rennen mit Ausdauer
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	staminaBar.Visible = walkingFreely and stamina < 0.999
	sprintButton.Visible = walkingFreely and UserInputService.TouchEnabled
	if walkingFreely and humanoid and humanoid.Health > 0 and not finished then
		local running = sprinting and stamina > 0 and humanoid.MoveDirection.Magnitude > 0.1
		humanoid.WalkSpeed = running and Route.SPRINT_SPEED or Route.WALK_SPEED
		if running then
			stamina = math.max(0, stamina - deltaTime / SPRINT_TIME)
		elseif not sprinting then
			stamina = math.min(1, stamina + deltaTime / RECOVER_TIME)
		end
		staminaFill.Size = UDim2.fromScale(stamina, 1)
	end

	if not model then
		return
	end
	-- Schreckmoment: das Biest direkt vor dem Gesicht, Maul weit offen
	if jumpscareUntil and os.clock() < jumpscareUntil then
		local shake = CFrame.new((math.random() - 0.5) * 0.4, (math.random() - 0.5) * 0.4, 0)
		-- so drehen und verschieben, dass der Kopf 2,4 Studs vor der Kamera ist
		model:PivotTo(camera.CFrame * shake * CFrame.new(0, -Beast.HEAD.Y, -2.4 + Beast.HEAD.Z) * CFrame.Angles(0, math.pi, 0))
		Beast.pose(joints, 0, 0, 1, math.sin(os.clock() * 40) * 0.15)
		if sounds.breath and not sounds.breath.IsPlaying then
			sounds.breath:Play()
		end
		return
	end

	local anchor = workspace:FindFirstChild("BeastAnchor")
	local active = anchor and anchor:GetAttribute("Active") == true
	if not active then
		if visible then
			visible = false
			model:PivotTo(HIDDEN)
			if sounds.breath then
				sounds.breath:Stop()
			end
		end
		return
	end
	local target = anchor.CFrame
	if not visible then
		visible = true
		current = target
		if sounds.breath then
			sounds.breath:Play()
		end
	end
	local before = current.Position
	current = current:Lerp(target, math.min(deltaTime * 8, 1))
	local moved = Vector3.new(current.X - before.X, 0, current.Z - before.Z).Magnitude
	local speed = moved / math.max(deltaTime, 1e-3)
	amount += (math.clamp(speed / 10, 0, 1) - amount) * math.min(deltaTime * 6, 1)
	phase += moved / STRIDE * math.pi * 2
	-- schwere Schritte bei jedem halben Laufzyklus
	if math.floor(phase / math.pi) ~= lastStepPhase then
		lastStepPhase = math.floor(phase / math.pi)
		if amount > 0.3 and sounds.step then
			sounds.step.PlaybackSpeed = 0.85 + math.random() * 0.2
			sounds.step:Play()
		end
	end
	local bob = math.abs(math.sin(phase)) * 0.35 * amount
	model:PivotTo(current * CFrame.new(0, bob, 0))
	local twitch = math.noise(os.clock() * 3, 7.7) * 0.5 * (1 - amount * 0.7)
	Beast.pose(joints, phase, amount, 0.25 + math.noise(os.clock(), 2.2) * 0.25, twitch)
end

-- Kurzer Hinweis oben im Bild (weiß statt rot)
function BeastView.hint(text, seconds)
	warningLabel.Text = text
	warningLabel.TextSize = 26
	warningLabel.TextColor3 = Color3.fromRGB(230, 225, 215)
	showText(warningLabel, true, 0.6)
	task.delay(seconds, function()
		showText(warningLabel, false, 1)
		task.delay(1.1, function()
			warningLabel.TextSize = 46
			warningLabel.TextColor3 = Color3.fromRGB(230, 40, 30)
		end)
	end)
end

-- Kamera wackeln lassen (wird vom Hauptskript abgefragt)
function BeastView.shaking()
	return os.clock() < shakeUntil
end

return BeastView
