-- Licht, Himmel, Nebel und Gelände (Waldboden).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(script.Parent.Layout)

local Environment = {}

function Environment.setupLighting()
	-- Fester Sonnenuntergang: die Uhrzeit wird nie verändert.
	Lighting.ClockTime = Config.LOBBY_CLOCK_TIME
	Lighting.GeographicLatitude = 41
	Lighting.Brightness = 2.6
	Lighting.ExposureCompensation = 0
	Lighting.Ambient = Color3.fromRGB(60, 48, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 95, 90)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25

	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("PostEffect") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- Himmel ohne Sterne und Mond, damit es nicht halb Tag, halb Nacht aussieht
	local sky = Instance.new("Sky")
	sky.StarCount = 0
	sky.MoonTextureId = ""
	sky.SunAngularSize = 14
	sky.Parent = Lighting

	-- Warmer, roter Dunst: um die Sonne herum leuchtet der Himmel rot-orange
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.34
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(255, 135, 90)
	atmosphere.Decay = Color3.fromRGB(125, 60, 70)
	atmosphere.Glare = 2.2
	atmosphere.Haze = 2.4
	atmosphere.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.Name = "LobbyGrading"
	grading.Saturation = 0.05
	grading.Contrast = 0.12
	grading.Brightness = 0.02
	grading.TintColor = Color3.fromRGB(255, 232, 215)
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.4
	bloom.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.15
	sunRays.Spread = 0.7
	sunRays.Parent = Lighting
end

function Environment.buildTerrain(roadSegments, roadWidth)
	local terrain = workspace.Terrain
	terrain:Clear()
	-- Keine Grashalme: Waldboden aus Laub und Erde
	pcall(function()
		terrain.Decoration = false
	end)
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(64, 72, 42))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(84, 68, 50))
	terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(66, 54, 42))

	-- Oberkante des Geländes liegt bei Höhe 0
	terrain:FillBlock(CFrame.new(0, -6, -140), Vector3.new(1000, 12, 1000), Enum.Material.LeafyGrass)

	-- Flecken aus Erde und Matsch für einen natürlichen Waldboden
	local rng = Random.new(77)
	local materials = { Enum.Material.Ground, Enum.Material.Ground, Enum.Material.Mud }
	for _ = 1, 160 do
		local position = CFrame.new(rng:NextNumber(-480, 480), -2, rng:NextNumber(-620, 340))
		terrain:FillBlock(
			position * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			Vector3.new(rng:NextNumber(12, 40), 4, rng:NextNumber(12, 40)),
			materials[rng:NextInteger(1, #materials)]
		)
	end

	-- Erdiger Rand neben der Straße und festgetretene Erde rund um den Grillplatz
	for _, segment in roadSegments do
		terrain:FillBlock(segment.cframe * CFrame.new(0, -2, 0), Vector3.new(roadWidth + 10, 4, segment.length + 4), Enum.Material.Ground)
	end
	local fire = Layout.CAMPFIRE
	terrain:FillCylinder(CFrame.new(fire.X, -2, fire.Z), 4, 18, Enum.Material.Ground)

	-- Unter Asphalt, Gehweg und Straße das Gelände entfernen. Dort liegen dicke
	-- Platten, so kann kein Gelände durch die Oberfläche ragen.
	local lot = Layout.LOT
	for _, zone in { Layout.ASPHALT, Layout.PLAZA } do
		terrain:FillBlock(
			CFrame.new(0, 0, (zone.minZ + zone.maxZ) / 2),
			Vector3.new(lot.halfWidth * 2 + 2, 8, zone.maxZ - zone.minZ + 2),
			Enum.Material.Air
		)
	end
	for _, segment in roadSegments do
		terrain:FillBlock(segment.cframe, Vector3.new(roadWidth + 1, 8, segment.length + 2), Enum.Material.Air)
	end
end

return Environment
