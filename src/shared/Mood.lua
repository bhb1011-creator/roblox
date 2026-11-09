-- Stimmung und Leistung auf dem Client (Kapitel 1–3):
--  * Vignette: die Bildränder werden dunkel, die Mitte bleibt frei (enger, beklemmender Blick).
--  * Schatten-Budget: Schatten von Lichtern sind teuer. Nur die nächsten paar Lichter um die
--    Kamera werfen Schatten, alle anderen leuchten ohne Schatten weiter. Im Haus gibt es
--    Dutzende Kerzen – so bleibt das Bild flüssig, besonders am Handy.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Mood = {}

local MAX_SHADOW_LIGHTS = 6 -- so viele Lichter dürfen gleichzeitig Schatten werfen
local MAX_SHADOW_DISTANCE = 70 -- weiter weg wirft kein Licht Schatten
local UPDATE_EVERY = 0.35 -- Sekunden

local started = false

local function buildVignette()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	if playerGui:FindFirstChild("MoodVignette") then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "MoodVignette"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1 -- unter Untertiteln, Menüs und Abblenden
	-- vier Ränder, die nach innen durchsichtig werden
	local edges = {
		{ UDim2.fromScale(1, 0.32), UDim2.fromScale(0, 0), 90 }, -- oben
		{ UDim2.fromScale(1, 0.32), UDim2.fromScale(0, 0.68), -90 }, -- unten
		{ UDim2.fromScale(0.26, 1), UDim2.fromScale(0, 0), 0 }, -- links
		{ UDim2.fromScale(0.26, 1), UDim2.fromScale(0.74, 0), 180 }, -- rechts
	}
	for _, edge in edges do
		local frame = Instance.new("Frame")
		frame.Size = edge[1]
		frame.Position = edge[2]
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BorderSizePixel = 0
		frame.Active = false
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = edge[3]
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(0.45, 0.8),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = frame
		frame.Parent = gui
	end
	gui.Parent = playerGui
end

local function startShadowBudget()
	local lights = {} -- Licht -> true (Lichter, die Schatten werfen wollen)
	local function track(item)
		if (item:IsA("PointLight") or item:IsA("SpotLight") or item:IsA("SurfaceLight")) and item.Shadows then
			item:SetAttribute("WantsShadows", true)
			lights[item] = true
			item.Destroying:Once(function()
				lights[item] = nil
			end)
		end
	end
	for _, item in workspace:GetDescendants() do
		track(item)
	end
	workspace.DescendantAdded:Connect(function(item)
		-- (Eigenschaften wie Shadows werden oft erst nach dem Einfügen gesetzt)
		task.defer(function()
			if item.Parent then
				track(item)
			end
		end)
	end)

	local camera = workspace.CurrentCamera
	local nextUpdate = 0
	local candidates = {}
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now < nextUpdate then
			return
		end
		nextUpdate = now + UPDATE_EVERY
		camera = workspace.CurrentCamera or camera
		if not camera then
			return
		end
		local eye = camera.CFrame.Position
		table.clear(candidates)
		for light in lights do
			local holder = light.Parent
			local position = holder and (holder:IsA("BasePart") and holder.Position or holder:IsA("Attachment") and holder.WorldPosition)
			if position and light.Enabled then
				local distance = (position - eye).Magnitude
				if distance < MAX_SHADOW_DISTANCE then
					table.insert(candidates, { light = light, distance = distance })
				elseif light.Shadows then
					light.Shadows = false
				end
			end
		end
		table.sort(candidates, function(a, b)
			return a.distance < b.distance
		end)
		for index, entry in candidates do
			local want = index <= MAX_SHADOW_LIGHTS
			if entry.light.Shadows ~= want then
				entry.light.Shadows = want
			end
		end
	end)
end

function Mood.start()
	if started then
		return
	end
	started = true
	task.spawn(buildVignette)
	startShadowBudget()
end

return Mood
