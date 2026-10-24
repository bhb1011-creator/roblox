-- Ego-Perspektive: Kamera fest in der Ich-Sicht (eigener Körper unsichtbar),
-- leichtes Kopfwippen beim Laufen, ruhiges Atmen im Stand und ein kleiner Punkt
-- in der Bildmitte.

-- Liegen im selben Studio-Ort auch die Skripte von Level 1, läuft nur das Level
if game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Level") then
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5

local FIELD_OF_VIEW = 78
local BOB_SPEED = 9
local BOB_SIDE = 0.07
local BOB_UP = 0.11
local BREATH = 0.025

-- Punkt in der Bildmitte
local gui = Instance.new("ScreenGui")
gui.Name = "Crosshair"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(5, 5)
dot.BackgroundColor3 = Color3.new(1, 1, 1)
dot.BackgroundTransparency = 0.35
dot.BorderSizePixel = 0
dot.Parent = gui
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(1, 0)
round.Parent = dot

local humanoid
local bobTime, bobBlend = 0, 0

local function onCharacterAdded(character)
	bobTime, bobBlend = 0, 0
	humanoid = character:WaitForChild("Humanoid")
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

-- Läuft direkt nach der Roblox-Kamera, damit unsere Einstellungen gewinnen
RunService:BindToRenderStep("FirstPersonPolish", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	local camera = workspace.CurrentCamera
	camera.FieldOfView = FIELD_OF_VIEW

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local root = humanoid.RootPart
	local velocity = root and root.AssemblyLinearVelocity or Vector3.zero
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local walking = humanoid.MoveDirection.Magnitude > 0.1
		and humanoid.FloorMaterial ~= Enum.Material.Air
		and not humanoid.Sit
	bobBlend += ((walking and 1 or 0) - bobBlend) * math.min(deltaTime * 8, 1)
	bobTime += deltaTime * BOB_SPEED * math.clamp(speed / 16, 0.5, 1.5)

	local bob = Vector3.new(math.sin(bobTime) * BOB_SIDE, math.abs(math.cos(bobTime)) * BOB_UP, 0) * bobBlend
	local breath = Vector3.new(0, math.sin(os.clock() * 1.6) * BREATH, 0)
	humanoid.CameraOffset = bob + breath
end)
