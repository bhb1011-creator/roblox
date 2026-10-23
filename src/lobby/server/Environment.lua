-- Licht, Himmel, Nebel und Gelände (Gras, Waldboden).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(script.Parent.Layout)

local Environment = {}

function Environment.setupLighting()
	-- Fester Sonnenuntergang: die Uhrzeit wird nie verändert.
	Lighting.ClockTime = Config.LOBBY_CLOCK_TIME
	Lighting.GeographicLatitude = 41
	Lighting.Brightness = 2.4
	Lighting.ExposureCompensation = 0
	Lighting.Ambient = Color3.fromRGB(55, 45, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 95, 95)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25

	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	-- Warmer Dunst: die Straße verschwindet in der Ferne.
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.33
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(200, 140, 110)
	atmosphere.Decay = Color3.fromRGB(90, 60, 70)
	atmosphere.Glare = 0.7
	atmosphere.Haze = 1.8
	atmosphere.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.Name = "LobbyGrading"
	grading.Saturation = 0
	grading.Contrast = 0.1
	grading.Brightness = 0.02
	grading.TintColor = Color3.fromRGB(255, 238, 225)
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 28
	bloom.Threshold = 1.5
	bloom.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.12
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting
end

function Environment.buildTerrain(roadSegments, roadWidth)
	local terrain = workspace.Terrain
	terrain:Clear()
	-- Animierte Grashalme (falls Roblox das per Skript erlaubt)
	pcall(function()
		terrain.Decoration = true
	end)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(66, 80, 44))
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(58, 70, 40))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(76, 64, 48))
	terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(60, 50, 40))

	-- Oberkante des Geländes liegt bei Höhe 0
	terrain:FillBlock(CFrame.new(0, -6, -140), Vector3.new(1000, 12, 1000), Enum.Material.Grass)

	-- Flecken aus Laub, Erde und Matsch für einen natürlichen Waldboden
	local rng = Random.new(77)
	local materials = { Enum.Material.LeafyGrass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud }
	for _ = 1, 220 do
		local position = CFrame.new(rng:NextNumber(-480, 480), -2, rng:NextNumber(-620, 340))
		terrain:FillBlock(
			position * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			Vector3.new(rng:NextNumber(12, 40), 4, rng:NextNumber(12, 40)),
			materials[rng:NextInteger(1, #materials)]
		)
	end

	-- Erdiger Rand neben der Straße
	for _, segment in roadSegments do
		terrain:FillBlock(segment.cframe * CFrame.new(0, -2, 0), Vector3.new(roadWidth + 10, 4, segment.length + 4), Enum.Material.Ground)
	end

	-- Unter Parkplatz und Straße das Gelände entfernen. Dort liegen dicke Platten,
	-- so kann kein Gelände (oder Gras) durch den Asphalt ragen.
	local lot = Layout.LOT
	terrain:FillBlock(
		CFrame.new(0, 0, (lot.minZ + lot.maxZ) / 2),
		Vector3.new(lot.halfWidth * 2 + 2, 8, lot.maxZ - lot.minZ + 2),
		Enum.Material.Air
	)
	for _, segment in roadSegments do
		terrain:FillBlock(segment.cframe, Vector3.new(roadWidth + 1, 8, segment.length + 2), Enum.Material.Air)
	end
end

return Environment
