-- Ein realistischer Kombi/SUV in Roblox-Charaktergröße. Vorne ist -Z (Blickrichtung von homeCFrame).
-- Die Sitze liegen tief in der Karosserie, so passen Spieler hinein, ohne dass das Auto riesig wird.
local Parts = require(script.Parent.Parts)

local Car = {}

local DARK = Color3.fromRGB(22, 22, 25)
local TRIM = Color3.fromRGB(40, 40, 44)
local CHROME = Color3.fromRGB(180, 182, 188)
local GLASS = Color3.fromRGB(70, 85, 100)
local INTERIOR = Color3.fromRGB(42, 38, 36)

-- Maße
local LENGTH, WIDTH = 15, 6.8
local SILL = 2.9 -- Oberkante der Karosserie (Fensterunterkante liegt etwas höher)
local GLASS_BOTTOM, GLASS_TOP = 3.3, 5.8
local ROOF_FRONT, ROOF_BACK = -0.8, 6.8
local WHEEL_Z = 4.9

local function buildStatusSign(body, title)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusSign"
	billboard.Size = UDim2.fromOffset(220, 96)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 9.5, 0)
	billboard.MaxDistance = 25 -- nur sichtbar, wenn man nah am Auto steht
	billboard.LightInfluence = 0
	billboard.Parent = body

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(15, 12, 12)
	panel.BackgroundTransparency = 0.3
	panel.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	return {
		mode = Parts.text(panel, {
			Name = "Mode",
			Text = title,
			TextColor3 = Color3.fromRGB(255, 210, 120),
			Size = UDim2.new(1, -16, 0.4, 0),
			Position = UDim2.new(0, 8, 0.04, 0),
		}),
		count = Parts.text(panel, {
			Name = "Count",
			Text = "",
			Size = UDim2.new(1, -16, 0.26, 0),
			Position = UDim2.new(0, 8, 0.44, 0),
		}),
		status = Parts.text(panel, {
			Name = "Status",
			Text = "",
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(210, 200, 190),
			Size = UDim2.new(1, -16, 0.22, 0),
			Position = UDim2.new(0, 8, 0.72, 0),
		}),
	}
end

local function addPlate(part, text)
	Parts.text(Parts.surfaceGui(part, Enum.NormalId.Front), {
		Text = text,
		Font = Enum.Font.Code,
		TextColor3 = Color3.fromRGB(20, 20, 20),
	})
end

function Car.build(parent, homeCFrame, color, seatCount, name, title, plate)
	local model = Instance.new("Model")
	model.Name = name
	local block = Parts.builder(model, homeCFrame)
	local paint = Enum.Material.SmoothPlastic
	local shine = { Reflectance = 0.12 }
	local glassProps = { Transparency = 0.45, Reflectance = 0.1 }
	local front, back = -LENGTH / 2, LENGTH / 2

	local function wedge(partName, size, offset, partColor, material, extra)
		local props = {
			Name = partName,
			Size = size,
			CFrame = homeCFrame * offset,
			Color = partColor,
			Material = material,
			Parent = model,
		}
		for key, value in extra or {} do
			props[key] = value
		end
		return Parts.new("WedgePart", props)
	end

	-- Karosserie
	local body = block("Body", Vector3.new(WIDTH, SILL - 0.7, LENGTH), CFrame.new(0, (SILL + 0.7) / 2, 0), color, paint, shine)
	wedge("Hood", Vector3.new(WIDTH - 0.2, GLASS_BOTTOM - SILL, 4.3), CFrame.new(0, (SILL + GLASS_BOTTOM) / 2, front + 2.15), color, paint, shine)
	for _, x in { -WIDTH / 2 + 0.2, WIDTH / 2 - 0.2 } do
		block("Belt", Vector3.new(0.4, GLASS_BOTTOM - SILL, back - (front + 4.3)), CFrame.new(x, (SILL + GLASS_BOTTOM) / 2, (front + 4.3 + back) / 2), color, paint, shine)
	end
	block("RearDeck", Vector3.new(WIDTH - 0.8, GLASS_BOTTOM - SILL, back - ROOF_BACK), CFrame.new(0, (SILL + GLASS_BOTTOM) / 2, (ROOF_BACK + back) / 2), color, paint, shine)
	block("Roof", Vector3.new(WIDTH - 0.4, 0.3, ROOF_BACK - ROOF_FRONT), CFrame.new(0, GLASS_TOP + 0.15, (ROOF_FRONT + ROOF_BACK) / 2), color, paint, shine)
	for _, x in { -2.5, 2.5 } do
		block("RoofRail", Vector3.new(0.15, 0.2, 6), CFrame.new(x, GLASS_TOP + 0.4, 3), TRIM, Enum.Material.Metal)
	end

	-- Scheiben (Windschutzscheibe schräg)
	local glassHeight = GLASS_TOP - GLASS_BOTTOM
	wedge("Windshield", Vector3.new(WIDTH - 0.6, glassHeight, 2.4), CFrame.new(0, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_FRONT - 1.2), GLASS, Enum.Material.Glass, glassProps)
	block("RearWindow", Vector3.new(WIDTH - 0.6, glassHeight, 0.12), CFrame.new(0, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_BACK), GLASS, Enum.Material.Glass, glassProps)

	for _, side in { -1, 1 } do
		local x = side * (WIDTH / 2 - 0.2)
		block("SideWindow", Vector3.new(0.12, glassHeight, ROOF_BACK - ROOF_FRONT), CFrame.new(x, (GLASS_BOTTOM + GLASS_TOP) / 2, (ROOF_FRONT + ROOF_BACK) / 2), GLASS, Enum.Material.Glass, glassProps)
		Parts.beam(
			{ Name = "APillar", Color = color, Material = paint, Reflectance = 0.12, Parent = model },
			homeCFrame * Vector3.new(x, GLASS_BOTTOM, ROOF_FRONT - 2.4),
			homeCFrame * Vector3.new(x, GLASS_TOP, ROOF_FRONT),
			0.25
		)
		block("BPillar", Vector3.new(0.25, glassHeight, 0.35), CFrame.new(x, (GLASS_BOTTOM + GLASS_TOP) / 2, 2.4), DARK)
		block("DPillar", Vector3.new(0.25, glassHeight, 0.6), CFrame.new(x, (GLASS_BOTTOM + GLASS_TOP) / 2, ROOF_BACK - 0.3), color, paint, shine)
		block("WindowTrim", Vector3.new(0.15, 0.12, ROOF_BACK - ROOF_FRONT), CFrame.new(side * (WIDTH / 2 - 0.1), GLASS_BOTTOM + 0.05, (ROOF_FRONT + ROOF_BACK) / 2), CHROME, Enum.Material.Metal)
		block("SideSkirt", Vector3.new(0.12, 0.45, WHEEL_Z * 2 - 3.2), CFrame.new(side * (WIDTH / 2 + 0.03), 0.95, 0), TRIM)
		block("Mirror", Vector3.new(0.6, 0.45, 0.9), CFrame.new(side * (WIDTH / 2 + 0.35), GLASS_BOTTOM + 0.3, ROOF_FRONT - 1.9), color, paint, shine)
		for _, z in { -0.6, 2.4 } do
			block("DoorLine", Vector3.new(0.04, SILL - 1.1, 0.06), CFrame.new(side * (WIDTH / 2 + 0.01), (SILL + 1.1) / 2, z), DARK, paint, { CanCollide = false })
		end
		for _, z in { 0.2, 3.2 } do
			block("DoorHandle", Vector3.new(0.1, 0.15, 0.6), CFrame.new(side * (WIDTH / 2 + 0.04), SILL - 0.4, z), CHROME, Enum.Material.Metal, { CanCollide = false })
		end
		for _, z in { -WHEEL_Z, WHEEL_Z } do
			block("Tire", Vector3.new(1.1, 2.5, 2.5), CFrame.new(side * (WIDTH / 2 - 0.35), 1.25, z), DARK, paint, { Shape = Enum.PartType.Cylinder })
			block("Rim", Vector3.new(1.14, 1.5, 1.5), CFrame.new(side * (WIDTH / 2 - 0.35), 1.25, z), CHROME, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
			block("Hub", Vector3.new(1.16, 0.5, 0.5), CFrame.new(side * (WIDTH / 2 - 0.35), 1.25, z), TRIM, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
			block("WheelArch", Vector3.new(0.2, 0.45, 3.1), CFrame.new(side * (WIDTH / 2 + 0.05), 2.55, z), TRIM)
		end

		-- Lichter
		local headlight = block("Headlight", Vector3.new(1.4, 0.4, 0.1), CFrame.new(side * 2.3, 2.45, front - 0.02), Color3.fromRGB(255, 248, 230), Enum.Material.Neon)
		Parts.light("SpotLight", headlight, {
			Face = Enum.NormalId.Front,
			Range = 55,
			Angle = 55,
			Brightness = 3,
			Color = Color3.fromRGB(255, 244, 220),
			Shadows = true,
		})
		Parts.light("PointLight", headlight, { Range = 5, Brightness = 1, Color = Color3.fromRGB(255, 244, 220) })
		block("Indicator", Vector3.new(0.4, 0.25, 0.1), CFrame.new(side * 3.15, 2.45, front - 0.02), Color3.fromRGB(255, 150, 40), Enum.Material.Neon)
		local taillight = block("Taillight", Vector3.new(1.3, 0.45, 0.1), CFrame.new(side * 2.5, 2.5, back + 0.02), Color3.fromRGB(210, 20, 20), Enum.Material.Neon)
		Parts.light("PointLight", taillight, { Range = 6, Brightness = 0.7, Color = Color3.fromRGB(255, 40, 30) })
	end

	-- Front und Heck
	block("FrontBumper", Vector3.new(WIDTH + 0.2, 0.7, 0.5), CFrame.new(0, 1.1, front - 0.2), TRIM)
	block("RearBumper", Vector3.new(WIDTH + 0.2, 0.7, 0.5), CFrame.new(0, 1.1, back + 0.2), TRIM)
	block("Grille", Vector3.new(3.2, 0.7, 0.08), CFrame.new(0, 2.1, front - 0.03), DARK, Enum.Material.Metal)
	block("GrilleBar", Vector3.new(3.2, 0.1, 0.1), CFrame.new(0, 2.1, front - 0.07), CHROME, Enum.Material.Metal)
	addPlate(block("FrontPlate", Vector3.new(2, 0.5, 0.04), CFrame.new(0, 1.1, front - 0.47), Color3.fromRGB(235, 235, 230)), plate)
	addPlate(block("RearPlate", Vector3.new(2, 0.5, 0.04), CFrame.new(0, 1.9, back + 0.03) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(235, 235, 230)), plate)

	-- Innenraum: tiefe Sitze, Armaturenbrett, Lenkrad, Rückbank und Innenlicht
	block("Dashboard", Vector3.new(WIDTH - 0.8, 0.6, 1.1), CFrame.new(0, GLASS_BOTTOM + 0.1, ROOF_FRONT - 1.5), DARK)
	block("SteeringWheel", Vector3.new(0.15, 1.1, 1.1), CFrame.new(-1.35, GLASS_BOTTOM + 0.55, ROOF_FRONT - 0.7) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, math.rad(-25)), DARK, paint, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	block("RearBenchBack", Vector3.new(WIDTH - 1, 2.6, 0.4), CFrame.new(0, 3.2, 5.6), INTERIOR, Enum.Material.Fabric, { CanCollide = false })
	local dome = block("DomeLight", Vector3.new(0.9, 0.08, 0.5), CFrame.new(0, GLASS_TOP - 0.04, 2.4), Color3.fromRGB(255, 225, 170), Enum.Material.Neon)
	Parts.light("PointLight", dome, { Range = 8, Brightness = 0.6, Color = Color3.fromRGB(255, 220, 170) })

	local seats = {}
	for index, side in { -1, 1 } do
		local offset = CFrame.new(side * 1.35, 1.75, 1.2)
		block("SeatBack", Vector3.new(1.9, 2.8, 0.35), CFrame.new(side * 1.35, 3.2, 2.2) * CFrame.Angles(math.rad(-8), 0, 0), INTERIOR, Enum.Material.Fabric, { CanCollide = false })
		block("Headrest", Vector3.new(1.1, 0.6, 0.35), CFrame.new(side * 1.35, 4.9, 2.35), INTERIOR, Enum.Material.Fabric, { CanCollide = false })
		if index <= seatCount then
			local seat = Parts.new("Seat", {
				Name = "Seat",
				Size = Vector3.new(1.9, 0.3, 1.9),
				CFrame = homeCFrame * offset,
				Color = INTERIOR,
				Material = Enum.Material.Fabric,
				Parent = model,
			})
			seat:SetAttribute("LobbyCar", true)
			table.insert(seats, { seat = seat, exitOffset = CFrame.new(side * 7, 3, 1.2) })
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Einsteigen"
	prompt.ObjectText = title
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	model.PrimaryPart = body
	model.WorldPivot = homeCFrame
	model:SetAttribute("State", "Idle")
	model.Parent = parent

	return {
		model = model,
		seats = seats,
		prompt = prompt,
		labels = buildStatusSign(body, title),
	}
end

return Car
