-- Ein Auto aus Blöcken. Vorne ist -Z (Blickrichtung von homeCFrame).
local Parts = require(script.Parent.Parts)

local Car = {}

local DARK = Color3.fromRGB(25, 25, 28)
local CHROME = Color3.fromRGB(170, 172, 178)

local function buildStatusSign(body, title)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusSign"
	billboard.Size = UDim2.fromOffset(220, 96)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 11, 0)
	billboard.MaxDistance = 110
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
	local metal = Enum.Material.Metal

	local body = block("Body", Vector3.new(6.4, 2, 13), CFrame.new(0, 2, 0), color, metal)
	block("Roof", Vector3.new(6.2, 0.4, 6.4), CFrame.new(0, 7.7, 1.2), color, metal)
	for _, x in { -2.95, 2.95 } do
		for _, z in { -1.8, 4.2 } do
			block("Pillar", Vector3.new(0.3, 4.5, 0.3), CFrame.new(x, 5.25, z), color, metal)
		end
	end

	local glass = { Transparency = 0.55 }
	local glassColor = Color3.fromRGB(110, 130, 150)
	block("Windshield", Vector3.new(5.6, 4.5, 0.15), CFrame.new(0, 5.25, -1.8), glassColor, Enum.Material.Glass, glass)
	block("RearWindow", Vector3.new(5.6, 4.5, 0.15), CFrame.new(0, 5.25, 4.2), glassColor, Enum.Material.Glass, glass)
	for _, x in { -2.95, 2.95 } do
		block("SideWindow", Vector3.new(0.15, 4.5, 5.7), CFrame.new(x, 5.25, 1.2), glassColor, Enum.Material.Glass, glass)
		block("Mirror", Vector3.new(0.7, 0.5, 0.9), CFrame.new(x * 1.17, 4.1, -1.5), color, metal)
		-- Türfugen
		for _, z in { -1.6, 1.4 } do
			block("DoorLine", Vector3.new(0.05, 1.8, 0.08), CFrame.new(x * 1.087, 2, z), DARK, Enum.Material.SmoothPlastic, { CanCollide = false })
		end
		block("DoorHandle", Vector3.new(0.12, 0.2, 0.7), CFrame.new(x * 1.095, 2.6, -0.6), CHROME, metal, { CanCollide = false })
	end

	for _, x in { -3.3, 3.3 } do
		for _, z in { -4.2, 4.2 } do
			block("Tire", Vector3.new(1.2, 2.4, 2.4), CFrame.new(x, 1.2, z), DARK, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
			block("Rim", Vector3.new(1.25, 1.3, 1.3), CFrame.new(x, 1.2, z), CHROME, metal, { Shape = Enum.PartType.Cylinder })
		end
	end

	block("FrontBumper", Vector3.new(6.6, 0.8, 0.6), CFrame.new(0, 1.3, -6.7), DARK)
	block("RearBumper", Vector3.new(6.6, 0.8, 0.6), CFrame.new(0, 1.3, 6.7), DARK)
	block("Grille", Vector3.new(3.2, 0.9, 0.1), CFrame.new(0, 2.4, -6.55), DARK, metal)
	addPlate(block("FrontPlate", Vector3.new(2.2, 0.55, 0.05), CFrame.new(0, 1.3, -7.03), Color3.fromRGB(235, 235, 230)), plate)
	local rearPlate = block("RearPlate", Vector3.new(2.2, 0.55, 0.05), CFrame.new(0, 2.3, 6.53) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(235, 235, 230))
	addPlate(rearPlate, plate)

	for _, x in { -2.2, 2.2 } do
		local headlight = block("Headlight", Vector3.new(1.2, 0.6, 0.2), CFrame.new(x, 2.5, -6.55), Color3.fromRGB(255, 245, 220), Enum.Material.Neon)
		Parts.light("SpotLight", headlight, {
			Face = Enum.NormalId.Front,
			Range = 45,
			Angle = 60,
			Brightness = 2,
			Color = Color3.fromRGB(255, 240, 210),
		})
		block("Taillight", Vector3.new(1.2, 0.6, 0.2), CFrame.new(x, 2.5, 6.55), Color3.fromRGB(200, 20, 20), Enum.Material.Neon)
	end

	-- Innenraum: Armaturenbrett, Lenkrad und Sitze
	block("Dashboard", Vector3.new(5.6, 0.8, 1), CFrame.new(0, 3.6, -1.2), DARK)
	block("SteeringWheel", Vector3.new(0.2, 1.2, 1.2), CFrame.new(-1.4, 4.2, -0.6) * CFrame.Angles(0, math.pi / 2, math.rad(-20)), DARK, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })

	local seats = {}
	local sides = seatCount == 1 and { -1 } or { -1, 1 }
	for _, side in sides do
		local seat = Parts.new("Seat", {
			Name = "Seat",
			Size = Vector3.new(2, 0.6, 2),
			CFrame = homeCFrame * CFrame.new(side * 1.4, 3.3, 0.8),
			Color = Color3.fromRGB(45, 40, 38),
			Material = Enum.Material.Fabric,
			Parent = model,
		})
		seat:SetAttribute("LobbyCar", true)
		block("SeatBack", Vector3.new(2, 2.6, 0.4), CFrame.new(side * 1.4, 4.6, 1.9), Color3.fromRGB(45, 40, 38), Enum.Material.Fabric, { CanCollide = false })
		table.insert(seats, { seat = seat, exitOffset = CFrame.new(side * 6.5, 3, 0.8) })
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
