-- Licht, Himmel, Nebel und Gelände (Gras, Waldboden).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(script.Parent.Layout)

local Environment = {}

function Environment.setupLighting()
	-- Fester, dunkler Sonnenuntergang: die Uhrzeit wird nie verändert.
	Lighting.ClockTime = Config.LOBBY_CLOCK_TIME
	Lighting.GeographicLatitude = 41
	Lighting.Brightness = 1.6
	Lighting.ExposureCompensation = -0.35
	Lighting.Ambient = Color3.fromRGB(30, 24, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(85, 60, 62)
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3

	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	-- Leichter, warmer Dunst: die Straße verschwindet in der Ferne im Dunkeln.
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.42
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(185, 115, 95)
	atmosphere.Decay = Color3.fromRGB(45, 28, 48)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 2.2
	atmosphere.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.Name = "LobbyGrading"
	grading.Saturation = -0.1
	grading.Contrast = 0.15
	grading.Brightness = -0.03
	grading.TintColor = Color3.fromRGB(255, 232, 215)
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 28
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.08
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting
end

function Environment.buildTerrain(roadSegments)
	local terrain = workspace.Terrain
	terrain:Clear()
	-- Animierte Grashalme (falls Roblox das per Skript erlaubt)
	pcall(function()
		terrain.Decoration = true
	end)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(62, 74, 42))
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(56, 66, 38))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(72, 60, 46))
	terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(58, 48, 38))

	-- Oberkante des Geländes liegt bei Höhe 0
	terrain:FillBlock(CFrame.new(0, -6, -120), Vector3.new(800, 12, 800), Enum.Material.Grass)

	-- Flecken aus Laub, Erde und Matsch für einen natürlichen Waldboden
	local rng = Random.new(77)
	local materials = { Enum.Material.LeafyGrass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud }
	for _ = 1, 160 do
		local position = CFrame.new(rng:NextNumber(-380, 380), -2, rng:NextNumber(-500, 260))
		terrain:FillBlock(
			position * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			Vector3.new(rng:NextNumber(12, 40), 4, rng:NextNumber(12, 40)),
			materials[rng:NextInteger(1, #materials)]
		)
	end

	-- Unter Parkplatz und Straße: Erde statt Gras, damit kein Gras durch den Asphalt wächst
	local lot = Layout.LOT
	terrain:FillBlock(
		CFrame.new(0, -2, (lot.minZ + lot.maxZ) / 2),
		Vector3.new(lot.halfWidth * 2 + 12, 4, lot.maxZ - lot.minZ + 12),
		Enum.Material.Ground
	)
	for _, segment in roadSegments do
		terrain:FillBlock(segment.cframe * CFrame.new(0, -2, 0), Vector3.new(26, 4, segment.length + 4), Enum.Material.Ground)
	end
end

return Environment
