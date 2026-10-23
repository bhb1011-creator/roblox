-- Ein realistischeres SUV aus Bauteilen. Vorne ist -Z (Blickrichtung von homeCFrame).
local Parts = require(script.Parent.Parts)

local Car = {}

local DARK = Color3.fromRGB(22, 22, 25)
local CHROME = Color3.fromRGB(175, 178, 184)
local GLASS = Color3.fromRGB(95, 115, 135)
local INTERIOR = Color3.fromRGB(42, 38, 36)

local function buildStatusSign(body, title)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusSign"
	billboard.Size = UDim2.fromOffset(220, 96)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 12, 0)
	billboard.MaxDistance = 120
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
	local paint = Enum.Material.Metal
	local glass = { Transparency = 0.5 }

	-- Karosserie
	local body = block("Body", Vector3.new(6.6, 2, 14.4), CFrame.new(0, 2, 0), color, paint)
	Parts.new("WedgePart", {
		Name = "Hood",
		Size = Vector3.new(6.4, 0.6, 4.2),
		CFrame = homeCFrame * CFrame.new(0, 3.3, -5.1),
		Color = color,
		Material = paint,
		Parent = model,
	})
	-- Seitenwände unter den Fenstern; innen bleibt der Boden auf Sitzhöhe frei
	for _, x in { -3, 3 } do
		block("Belt", Vector3.new(0.4, 0.6, 10.2), CFrame.new(x, 3.3, 2.1), color, paint)
	end
	block("Roof", Vector3.new(6.3, 0.4, 7.8), CFrame.new(0, 8, 3.2), color, paint)
	for _, x in { -2.6, 2.6 } do
		block("RoofRail", Vector3.new(0.2, 0.25, 6.6), CFrame.new(x, 8.32, 3.2), DARK, Enum.Material.Metal)
	end
	block("Antenna", Vector3.new(0.06, 1.2, 0.06), CFrame.new(1.5, 8.8, 5.6), DARK, Enum.Material.Metal, { CanCollide = false })

	-- Scheiben
	Parts.new("WedgePart", {
		Name = "Windshield",
		Size = Vector3.new(6, 4.2, 2.4),
		CFrame = homeCFrame * CFrame.new(0, 5.7, -1.8),
		Color = GLASS,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		Parent = model,
	})
	block("RearWindow", Vector3.new(6, 4.2, 0.15), CFrame.new(0, 5.7, 7.05), GLASS, Enum.Material.Glass, glass)

	for _, side in { -1, 1 } do
		local x = side * 3.1
		block("SideWindow", Vector3.new(0.15, 4.2, 7.6), CFrame.new(x, 5.7, 3.2), GLASS, Enum.Material.Glass, glass)
		Parts.beam(
			{ Name = "APillar", Color = color, Material = paint, Parent = model },
			homeCFrame * Vector3.new(side * 3.05, 3.6, -3),
			homeCFrame * Vector3.new(side * 3.05, 7.8, -0.6),
			0.3
		)
		block("BPillar", Vector3.new(0.3, 4.2, 0.4), CFrame.new(x, 5.7, 2.6), DARK)
		block("DPillar", Vector3.new(0.3, 4.2, 0.5), CFrame.new(x, 5.7, 6.9), color, paint)
		block("SideSkirt", Vector3.new(0.15, 0.5, 8), CFrame.new(side * 3.33, 1.25, 0), DARK)
		block("Mirror", Vector3.new(0.7, 0.55, 1), CFrame.new(side * 3.55, 4, -2.2), color, paint)
		for _, z in { -0.4, 2.8 } do
			block("DoorLine", Vector3.new(0.05, 2.2, 0.08), CFrame.new(side * 3.31, 2.3, z), DARK, Enum.Material.SmoothPlastic, { CanCollide = false })
		end
		for _, z in { 0.4, 3.6 } do
			block("DoorHandle", Vector3.new(0.12, 0.2, 0.7), CFrame.new(side * 3.34, 3.1, z), CHROME, Enum.Material.Metal, { CanCollide = false })
		end
		for _, z in { -4.7, 4.7 } do
			block("FenderFlare", Vector3.new(0.3, 0.6, 3.4), CFrame.new(side * 3.4, 2.55, z), DARK)
			block("Tire", Vector3.new(1.3, 2.7, 2.7), CFrame.new(side * 3.3, 1.35, z), DARK, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
			block("Rim", Vector3.new(1.35, 1.5, 1.5), CFrame.new(side * 3.3, 1.35, z), CHROME, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		end

		-- Lichter
		local headlight = block("Headlight", Vector3.new(1.5, 0.45, 0.15), CFrame.new(side * 2.4, 2.75, -7.25), Color3.fromRGB(255, 248, 230), Enum.Material.Neon)
		Parts.light("SpotLight", headlight, {
			Face = Enum.NormalId.Front,
			Range = 55,
			Angle = 55,
			Brightness = 3,
			Color = Color3.fromRGB(255, 244, 220),
			Shadows = true,
		})
		Parts.light("PointLight", headlight, { Range = 5, Brightness = 1, Color = Color3.fromRGB(255, 244, 220) })
		block("FogLight", Vector3.new(0.6, 0.3, 0.1), CFrame.new(side * 2.6, 1.4, -7.8), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
		local taillight = block("Taillight", Vector3.new(1.6, 0.5, 0.15), CFrame.new(side * 2.4, 2.75, 7.25), Color3.fromRGB(210, 20, 20), Enum.Material.Neon)
		Parts.light("PointLight", taillight, { Range = 6, Brightness = 0.7, Color = Color3.fromRGB(255, 40, 30) })
	end

	-- Front und Heck
	block("FrontBumper", Vector3.new(6.8, 0.9, 0.7), CFrame.new(0, 1.5, -7.4), DARK)
	block("RearBumper", Vector3.new(6.8, 0.9, 0.7), CFrame.new(0, 1.5, 7.4), DARK)
	block("Grille", Vector3.new(3.6, 1, 0.1), CFrame.new(0, 2.4, -7.25), DARK, Enum.Material.Metal)
	block("GrilleBar", Vector3.new(3.6, 0.12, 0.12), CFrame.new(0, 2.4, -7.32), CHROME, Enum.Material.Metal)
	addPlate(block("FrontPlate", Vector3.new(2.2, 0.55, 0.05), CFrame.new(0, 1.5, -7.78), Color3.fromRGB(235, 235, 230)), plate)
	addPlate(block("RearPlate", Vector3.new(2.2, 0.55, 0.05), CFrame.new(0, 2.3, 7.23) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(235, 235, 230)), plate)

	-- Innenraum: Armaturenbrett, Lenkrad, Sitze, Rückbank und Innenlicht
	block("Dashboard", Vector3.new(6, 0.9, 1.2), CFrame.new(0, 3.9, -1.9), DARK)
	block("SteeringWheel", Vector3.new(0.2, 1.3, 1.3), CFrame.new(-1.4, 4.6, -1) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, math.rad(-25)), DARK, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	block("RearBench", Vector3.new(5.6, 1, 2), CFrame.new(0, 3.5, 4.8), INTERIOR, Enum.Material.Fabric)
	block("RearBenchBack", Vector3.new(5.6, 2.6, 0.4), CFrame.new(0, 5, 6), INTERIOR, Enum.Material.Fabric, { CanCollide = false })
	local dome = block("DomeLight", Vector3.new(1, 0.1, 0.6), CFrame.new(0, 7.75, 2.5), Color3.fromRGB(255, 225, 170), Enum.Material.Neon)
	Parts.light("PointLight", dome, { Range = 9, Brightness = 0.7, Color = Color3.fromRGB(255, 220, 170) })

	local seats = {}
	for index, side in { -1, 1 } do
		local offset = CFrame.new(side * 1.4, 3.15, 1.2)
		block("SeatBack", Vector3.new(2, 2.8, 0.4), CFrame.new(side * 1.4, 4.7, 2.3), INTERIOR, Enum.Material.Fabric, { CanCollide = false })
		if index <= seatCount then
			local seat = Parts.new("Seat", {
				Name = "Seat",
				Size = Vector3.new(2, 0.3, 2),
				CFrame = homeCFrame * offset,
				Color = INTERIOR,
				Material = Enum.Material.Fabric,
				Parent = model,
			})
			seat:SetAttribute("LobbyCar", true)
			table.insert(seats, { seat = seat, exitOffset = CFrame.new(side * 7, 3, 1.2) })
		else
			block("PassengerSeat", Vector3.new(2, 0.3, 2), offset, INTERIOR, Enum.Material.Fabric)
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
