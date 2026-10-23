-- Gebäude am Südrand: großer begehbarer Kiosk mit Verkäufer und Automaten,
-- Kassenhäuschen, große Bestenliste, verlassener Wohnwagen und Automaten draußen.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Layout = require(script.Parent.Layout)
local Parts = require(script.Parent.Parts)

local Buildings = {}

local COLORS = {
	wall = Color3.fromRGB(100, 78, 60),
	trim = Color3.fromRGB(60, 44, 34),
	roof = Color3.fromRGB(48, 48, 52),
	floorLight = Color3.fromRGB(170, 166, 156),
	floorDark = Color3.fromRGB(110, 106, 100),
	glass = Color3.fromRGB(120, 140, 155),
	wood = Color3.fromRGB(110, 80, 55),
	metal = Color3.fromRGB(70, 72, 76),
	darkMetal = Color3.fromRGB(35, 35, 38),
	neonWarm = Color3.fromRGB(255, 200, 110),
	coldLight = Color3.fromRGB(215, 230, 255),
}

local IDLE_ANIMATION = "rbxassetid://507766388" -- Standard-Atemanimation von Roblox (R15)

local function randomProductColor(rng)
	return Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.45, 0.85), rng:NextNumber(0.55, 0.95))
end

-- Verkäufer hinter der Theke. `feet` = Position der Füße, Blickrichtung = LookVector.
local function createSeller(parent, feet)
	local ok, seller = pcall(function()
		local description = Instance.new("HumanoidDescription")
		local skin = Color3.fromRGB(205, 160, 125)
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = Color3.fromRGB(45, 70, 50) -- grüne Schürze
		description.LeftLegColor = Color3.fromRGB(40, 40, 48)
		description.RightLegColor = Color3.fromRGB(40, 40, 48)
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("Verkäufer konnte nicht erstellt werden:", seller)
		return nil
	end

	seller.Name = "Verkäufer"
	local humanoid = seller:FindFirstChildOfClass("Humanoid")
	local root = seller:FindFirstChild("HumanoidRootPart")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	root.Anchored = true
	seller:PivotTo(feet * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0))
	seller.Parent = parent

	pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local animation = Instance.new("Animation")
		animation.AnimationId = IDLE_ANIMATION
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play()
	end)

	local nameTag = Instance.new("BillboardGui")
	nameTag.Size = UDim2.fromOffset(140, 30)
	nameTag.StudsOffset = Vector3.new(0, 3, 0)
	nameTag.MaxDistance = 30
	nameTag.Parent = root
	Parts.text(nameTag, { Text = "Verkäufer", TextColor3 = Color3.fromRGB(255, 220, 160), TextStrokeTransparency = 0.4 })

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop öffnen"
	prompt.ObjectText = "Verkäufer"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	CollectionService:AddTag(prompt, "ShopPrompt")
	return seller
end

-- Reihe von Produkten auf einem Regalboden (von x1 bis x2, lokale Koordinaten von `cframe`)
local function fillBoard(block, rng, cframe, x1, x2, y, z)
	local x = x1
	while x < x2 - 0.7 do
		local size = Vector3.new(rng:NextNumber(0.55, 1), rng:NextNumber(0.6, 1.3), rng:NextNumber(0.5, 0.8))
		block("Product", size, cframe * CFrame.new(x + size.X / 2, y + size.Y / 2, z), randomProductColor(rng), Enum.Material.SmoothPlastic, { CanCollide = false })
		x += size.X + 0.15
	end
end

-- Wandregal; Rückwand bei +Z, Waren zeigen nach -Z
local function buildWallShelf(block, rng, cframe, width, height)
	local depth = 1.6
	block("ShelfBack", Vector3.new(width, height, 0.2), cframe * CFrame.new(0, height / 2, depth / 2), COLORS.trim, Enum.Material.Wood)
	for _, x in { -width / 2, width / 2 } do
		block("ShelfSide", Vector3.new(0.2, height, depth), cframe * CFrame.new(x, height / 2, 0), COLORS.trim, Enum.Material.Wood)
	end
	local levels = math.floor(height / 1.7)
	for level = 0, levels - 1 do
		local y = 0.3 + level * 1.7
		block("ShelfBoard", Vector3.new(width, 0.15, depth), cframe * CFrame.new(0, y, 0), COLORS.wood, Enum.Material.Wood)
		fillBoard(block, rng, cframe, -width / 2 + 0.2, width / 2, y + 0.075, 0)
	end
end

-- Freistehendes Regal mit Waren auf beiden Seiten (Länge entlang lokal X)
local function buildGondola(block, rng, cframe, length)
	local height, width = 5.2, 2.6
	block("GondolaBase", Vector3.new(length, 0.5, width), cframe * CFrame.new(0, 0.25, 0), COLORS.darkMetal, Enum.Material.Metal)
	block("GondolaDivider", Vector3.new(length, height, 0.2), cframe * CFrame.new(0, height / 2, 0), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
	block("GondolaTop", Vector3.new(length + 0.2, 0.3, width), cframe * CFrame.new(0, height + 0.15, 0), COLORS.darkMetal, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		for level = 0, 2 do
			local y = 0.5 + level * 1.6
			block("GondolaBoard", Vector3.new(length, 0.12, width / 2 - 0.1), cframe * CFrame.new(0, y, side * width / 4), Color3.fromRGB(220, 220, 225), Enum.Material.Metal)
			fillBoard(block, rng, cframe, -length / 2 + 0.2, length / 2, y + 0.06, side * (width / 4 + 0.1))
		end
	end
	local sign = block("GondolaSign", Vector3.new(3, 1, 0.1), cframe * CFrame.new(0, height + 1, 0), Color3.fromRGB(200, 50, 40), Enum.Material.SmoothPlastic, { CanCollide = false })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		Parts.text(Parts.surfaceGui(sign, face), { Text = "SNACKS", TextColor3 = Color3.new(1, 1, 1) })
	end
end

-- Getränkekühlschrank mit Glastür; Vorderseite zeigt nach -Z von `cframe`
local function buildFridge(parent, cframe, rng)
	local block = Parts.builder(parent, cframe)
	local W, H, D = 4.6, 8, 2.6
	block("FridgeTop", Vector3.new(W, 1, D), CFrame.new(0, H - 0.5, 0), Color3.fromRGB(30, 60, 120), Enum.Material.Metal)
	block("FridgeBottom", Vector3.new(W, 0.8, D), CFrame.new(0, 0.4, 0), COLORS.darkMetal, Enum.Material.Metal)
	for _, x in { -W / 2 + 0.15, W / 2 - 0.15 } do
		block("FridgeSide", Vector3.new(0.3, H, D), CFrame.new(x, H / 2, 0), COLORS.darkMetal, Enum.Material.Metal)
	end
	local panel = block("FridgeLight", Vector3.new(W - 0.6, H - 1.8, 0.1), CFrame.new(0, H / 2 - 0.1, D / 2 - 0.1), Color3.fromRGB(200, 230, 255), Enum.Material.Neon)
	Parts.light("PointLight", panel, { Range = 8, Brightness = 0.7, Color = Color3.fromRGB(180, 215, 255) })
	for level = 0, 3 do
		local y = 1.0 + level * 1.5
		block("FridgeShelf", Vector3.new(W - 0.6, 0.08, D - 0.4), CFrame.new(0, y, 0), COLORS.glass, Enum.Material.Glass, { Transparency = 0.4 })
		for i = 0, 5 do
			Parts.column({
				Name = "Bottle",
				Color = randomProductColor(rng),
				Material = Enum.Material.Glass,
				Transparency = 0.15,
				CanCollide = false,
				Parent = parent,
			}, 1.1, 0.45, cframe * CFrame.new(-1.5 + i * 0.6, y + 0.04, -0.2))
		end
	end
	block("FridgeDoor", Vector3.new(W - 0.6, H - 1.8, 0.1), CFrame.new(0, H / 2 - 0.1, -D / 2 + 0.05), COLORS.glass, Enum.Material.Glass, { Transparency = 0.7 })
	block("FridgeHandle", Vector3.new(0.15, 2, 0.2), CFrame.new(W / 2 - 0.6, H / 2, -D / 2 - 0.1), Color3.fromRGB(190, 190, 195), Enum.Material.Metal)
	local label = block("FridgeLabel", Vector3.new(W - 0.4, 0.7, 0.05), CFrame.new(0, H - 0.5, -D / 2 - 0.03), Color3.fromRGB(30, 60, 120), Enum.Material.SmoothPlastic, { CanCollide = false })
	Parts.text(Parts.surfaceGui(label, Enum.NormalId.Front, true), { Text = "GETRÄNKE", TextColor3 = Color3.new(1, 1, 1) })
end

-- Snackautomat (befüllt); Vorderseite zeigt nach -Z von `cframe`
local function buildSnackMachine(parent, cframe, rng, bodyColor)
	local machine = Instance.new("Model")
	machine.Name = "Snackautomat"
	local block = Parts.builder(machine, cframe)
	local W, H, D = 4.6, 8, 3
	block("Body", Vector3.new(W, H, D), CFrame.new(0, H / 2, 0.15), bodyColor, Enum.Material.Metal)
	local front = -D / 2
	-- Innenraum hinter der Scheibe
	local back = block("InnerLight", Vector3.new(3.2, 5.6, 0.05), CFrame.new(-0.55, 4.6, front + 0.05), Color3.fromRGB(235, 240, 245), Enum.Material.Neon)
	Parts.light("PointLight", back, { Range = 9, Brightness = 0.8, Color = Color3.fromRGB(220, 235, 255) })
	CollectionService:AddTag(back, "FlickerLamp")
	for row = 0, 4 do
		local y = 2.3 + row * 1.1
		block("Tray", Vector3.new(3.2, 0.08, 0.9), CFrame.new(-0.55, y, front - 0.45), COLORS.darkMetal, Enum.Material.Metal)
		for col = 0, 3 do
			block(
				"Snack",
				Vector3.new(0.62, 0.85, 0.3),
				CFrame.new(-1.75 + col * 0.8, y + 0.47, front - 0.5) * CFrame.Angles(math.rad(-8), 0, 0),
				randomProductColor(rng),
				Enum.Material.SmoothPlastic,
				{ CanCollide = false }
			)
		end
	end
	block("Window", Vector3.new(3.4, 5.8, 0.1), CFrame.new(-0.55, 4.6, front - 1), COLORS.glass, Enum.Material.Glass, { Transparency = 0.75 })
	for _, x in { -2.3, 1.2 } do
		block("WindowFrame", Vector3.new(0.2, 6, 1.1), CFrame.new(x, 4.6, front - 0.5), bodyColor, Enum.Material.Metal)
	end
	block("FrameTop", Vector3.new(3.7, 0.3, 1.1), CFrame.new(-0.55, 7.65, front - 0.5), bodyColor, Enum.Material.Metal)
	block("FrameBottom", Vector3.new(3.7, 0.3, 1.1), CFrame.new(-0.55, 1.55, front - 0.5), bodyColor, Enum.Material.Metal)
	-- Bedienfeld rechts
	block("Panel", Vector3.new(0.9, 5.8, 1.1), CFrame.new(1.8, 4.6, front - 0.5), COLORS.darkMetal, Enum.Material.Metal)
	block("Display", Vector3.new(0.7, 0.4, 0.05), CFrame.new(1.8, 6.6, front - 1.07), Color3.fromRGB(90, 255, 120), Enum.Material.Neon)
	for row = 0, 3 do
		for col = 0, 1 do
			block("Button", Vector3.new(0.22, 0.22, 0.08), CFrame.new(1.65 + col * 0.3, 5.6 - row * 0.35, front - 1.07), Color3.fromRGB(200, 200, 200), Enum.Material.Metal)
		end
	end
	block("CoinSlot", Vector3.new(0.3, 0.5, 0.08), CFrame.new(1.8, 3.6, front - 1.07), Color3.fromRGB(150, 150, 150), Enum.Material.Metal)
	block("Flap", Vector3.new(3, 0.9, 0.1), CFrame.new(-0.55, 0.9, front - 0.02), COLORS.darkMetal, Enum.Material.Metal)
	machine.Parent = parent
	return machine
end

local function buildDrinkMachine(parent, cframe)
	local machine = Instance.new("Model")
	machine.Name = "Getraenkeautomat"
	local block = Parts.builder(machine, cframe)
	block("Body", Vector3.new(3.5, 7.5, 2.5), CFrame.new(0, 3.75, 0), Color3.fromRGB(150, 30, 35), Enum.Material.Metal)
	local front = block("Front", Vector3.new(2.6, 4.6, 0.1), CFrame.new(-0.2, 4.6, -1.27), Color3.fromRGB(170, 205, 220), Enum.Material.Neon)
	Parts.light("PointLight", front, { Range = 11, Brightness = 0.9, Color = Color3.fromRGB(170, 210, 255) })
	CollectionService:AddTag(front, "FlickerLamp")
	block("Slot", Vector3.new(2, 0.6, 0.15), CFrame.new(-0.2, 1.3, -1.27), Color3.fromRGB(20, 20, 20))
	block("Buttons", Vector3.new(0.4, 2, 0.12), CFrame.new(1.4, 4.6, -1.27), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	machine.Parent = parent
end

local function buildShop(parent)
	local shop = Instance.new("Model")
	shop.Name = "Kiosk"
	local base = Layout.SHOP
	local block = Parts.builder(shop, base)
	local rng = Random.new(5)
	local W, D, H, T = 30, 22, 11, 0.8
	local frontZ = -D / 2 + T / 2
	local innerW, innerD = W - 2 * T, D - 2 * T

	-- Boden mit Schachbrett-Fliesen
	block("Floor", Vector3.new(W, 0.4, D), CFrame.new(0, 0.2, 0), COLORS.floorLight, Enum.Material.Marble)
	local nx, nz = 10, 8
	for ix = 0, nx - 1 do
		for iz = 0, nz - 1 do
			if (ix + iz) % 2 == 0 then
				block(
					"Tile",
					Vector3.new(innerW / nx, 0.02, innerD / nz),
					CFrame.new(-innerW / 2 + (ix + 0.5) * innerW / nx, 0.41, -innerD / 2 + (iz + 0.5) * innerD / nz),
					COLORS.floorDark,
					Enum.Material.Marble,
					{ CanCollide = false }
				)
			end
		end
	end

	block("WallBack", Vector3.new(W, H, T), CFrame.new(0, H / 2, D / 2 - T / 2), COLORS.wall, Enum.Material.WoodPlanks)
	block("WallLeft", Vector3.new(T, H, D), CFrame.new(-W / 2 + T / 2, H / 2, 0), COLORS.wall, Enum.Material.WoodPlanks)
	block("WallRight", Vector3.new(T, H, D), CFrame.new(W / 2 - T / 2, H / 2, 0), COLORS.wall, Enum.Material.WoodPlanks)

	-- Vorderwand: zwei große Fenster und eine breite Türöffnung
	local function frontPiece(x1, x2, y1, y2)
		block("WallFront", Vector3.new(x2 - x1, y2 - y1, T), CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, frontZ), COLORS.wall, Enum.Material.WoodPlanks)
	end
	frontPiece(-15, -13, 0, H)
	frontPiece(-3, 2, 0, H)
	frontPiece(2, 8, 8.5, H)
	frontPiece(8, 10, 0, H)
	frontPiece(14, 15, 0, H)
	for _, window in { { -13, -3 }, { 10, 14 } } do
		local x1, x2 = window[1], window[2]
		frontPiece(x1, x2, 0, 2.5)
		frontPiece(x1, x2, 8, H)
		block("Window", Vector3.new(x2 - x1, 5.5, 0.2), CFrame.new((x1 + x2) / 2, 5.25, frontZ), COLORS.glass, Enum.Material.Glass, { Transparency = 0.6 })
		block("WindowSill", Vector3.new(x2 - x1 + 0.6, 0.3, 1.4), CFrame.new((x1 + x2) / 2, 2.4, frontZ - 0.3), COLORS.trim, Enum.Material.Wood)
	end
	for _, x in { 2, 8 } do
		block("DoorFrame", Vector3.new(0.4, 8.5, 1.2), CFrame.new(x, 4.25, frontZ), COLORS.trim, Enum.Material.Wood)
	end
	block("Door", Vector3.new(0.25, 8.2, 5.6), CFrame.new(7.6, 4.5, frontZ + T / 2 + 2.8), COLORS.trim, Enum.Material.WoodPlanks)
	block("DoorWindow", Vector3.new(0.3, 3, 3), CFrame.new(7.6, 6, frontZ + T / 2 + 2.8), COLORS.glass, Enum.Material.Glass, { Transparency = 0.5 })
	block("DoorMat", Vector3.new(6, 0.05, 3), CFrame.new(5, 0.43, frontZ + 2), Color3.fromRGB(110, 35, 30), Enum.Material.Fabric)

	block("Roof", Vector3.new(W + 2, 0.8, D + 2), CFrame.new(0, H + 0.4, 0), COLORS.roof, Enum.Material.Metal)
	block("RoofTrim", Vector3.new(W + 2.2, 0.6, 0.4), CFrame.new(0, H + 0.2, -D / 2 - 1.1), COLORS.trim, Enum.Material.Wood)
	block("AirCon", Vector3.new(4, 2, 3), CFrame.new(8, H + 1.8, 5), Color3.fromRGB(170, 170, 170), Enum.Material.Metal)
	block("Awning", Vector3.new(8, 0.3, 3.5), CFrame.new(5, 8.8, -D / 2 - 1.6) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(140, 35, 35), Enum.Material.Fabric)

	-- Leuchtreklame und Wandlampen außen
	local sign = block("Sign", Vector3.new(16, 1.6, 0.4), CFrame.new(-6, H - 0.85, -D / 2 - 0.2), Color3.fromRGB(25, 22, 20))
	Parts.text(Parts.surfaceGui(sign, Enum.NormalId.Front, true), {
		Text = "KIOSK",
		Font = Enum.Font.Arcade,
		TextColor3 = COLORS.neonWarm,
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
	})
	Parts.light("PointLight", sign, { Range = 16, Brightness = 1, Color = COLORS.neonWarm })
	for _, x in { 0.6, 9.2 } do
		local sconce = block("WallLamp", Vector3.new(0.7, 1, 0.5), CFrame.new(x, 7, -D / 2 - 0.25), COLORS.neonWarm, Enum.Material.Neon)
		Parts.light("PointLight", sconce, { Range = 12, Brightness = 0.9, Color = COLORS.neonWarm })
	end

	local openSign = block("OpenSign", Vector3.new(3, 1.2, 0.1), CFrame.new(-8, 7, frontZ + 0.3), Color3.fromRGB(40, 10, 10), Enum.Material.SmoothPlastic, { CanCollide = false })
	Parts.text(Parts.surfaceGui(openSign, Enum.NormalId.Front, true), {
		Text = "OFFEN",
		Font = Enum.Font.Arcade,
		TextColor3 = Color3.fromRGB(255, 60, 60),
	})
	Parts.light("PointLight", openSign, { Range = 7, Brightness = 1, Color = Color3.fromRGB(255, 60, 60) })
	CollectionService:AddTag(openSign, "FlickerLamp")

	-- Deckenlampen (eine davon flackert)
	for i, offset in { Vector3.new(-8, H - 0.15, -4), Vector3.new(-8, H - 0.15, 5), Vector3.new(5, H - 0.15, -4), Vector3.new(5, H - 0.15, 5) } do
		local panel = block("CeilingLight", Vector3.new(5, 0.2, 1.2), CFrame.new(offset), COLORS.coldLight, Enum.Material.Neon)
		Parts.light("PointLight", panel, { Range = 16, Brightness = 0.9, Color = COLORS.coldLight, Shadows = i == 1 })
		if i == 3 then
			CollectionService:AddTag(panel, "FlickerLamp")
		end
	end

	-- Theke mit Kasse, Kartenterminal und Süßigkeiten
	block("Counter", Vector3.new(10, 3.6, 2.2), CFrame.new(-8, 2.2, 3), COLORS.wood, Enum.Material.WoodPlanks)
	block("CounterSide", Vector3.new(2.2, 3.6, 3), CFrame.new(-2, 2.2, 5.6), COLORS.wood, Enum.Material.WoodPlanks)
	block("CounterTop", Vector3.new(10.4, 0.25, 2.6), CFrame.new(-8, 4.1, 3), Color3.fromRGB(40, 38, 36), Enum.Material.Granite)
	block("CounterSideTop", Vector3.new(2.6, 0.25, 3.2), CFrame.new(-2, 4.1, 5.6), Color3.fromRGB(40, 38, 36), Enum.Material.Granite)
	block("Register", Vector3.new(1.6, 1, 1.2), CFrame.new(-5, 4.7, 3.2), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	block("RegisterDisplay", Vector3.new(1, 0.4, 0.1), CFrame.new(-5, 5.4, 2.8) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(90, 255, 120), Enum.Material.Neon)
	block("CardTerminal", Vector3.new(0.5, 0.2, 0.8), CFrame.new(-3.7, 4.33, 2.5), COLORS.darkMetal)
	for i = 0, 3 do
		block("CandyBox", Vector3.new(0.9, 0.6, 0.7), CFrame.new(-12 + i * 1.1, 4.55, 2.4), randomProductColor(rng))
	end
	block("Newspapers", Vector3.new(1.4, 0.4, 1), CFrame.new(-7.5, 4.45, 2.6), Color3.fromRGB(215, 210, 195))

	-- Rückwand hinter dem Verkäufer: Arbeitsfläche, Kaffeemaschine, Regal und Preistafel
	block("BackCounter", Vector3.new(12, 3.4, 1.6), CFrame.new(-8, 2.1, D / 2 - T - 0.8), COLORS.wood, Enum.Material.WoodPlanks)
	block("CoffeeMachine", Vector3.new(1.6, 2, 1.2), CFrame.new(-12, 4.8, D / 2 - T - 0.9), COLORS.darkMetal, Enum.Material.Metal)
	block("CoffeeLight", Vector3.new(0.3, 0.3, 0.05), CFrame.new(-11.6, 5.2, D / 2 - T - 1.53), Color3.fromRGB(255, 80, 60), Enum.Material.Neon)
	block("CupStack", Vector3.new(0.5, 1, 0.5), CFrame.new(-10.6, 4.3, D / 2 - T - 0.9), Color3.fromRGB(235, 235, 230))
	buildWallShelf(block, rng, CFrame.new(-8, 5.2, D / 2 - T - 0.8), 10, 3.6)
	local prices = block("PriceBoard", Vector3.new(8, 2, 0.15), CFrame.new(-8, 9.5, D / 2 - T - 0.1), Color3.fromRGB(25, 25, 25))
	Parts.text(Parts.surfaceGui(prices, Enum.NormalId.Front, true), {
		Text = "Kaffee 1,50 €   Hotdog 2,50 €\nCola 1,80 €   Chips 1,20 €   Eis 1,00 €",
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(240, 230, 200),
		Size = UDim2.fromScale(0.92, 0.8),
		Position = UDim2.fromScale(0.04, 0.1),
	})

	-- Regale links an der Wand und zwei freistehende Regale in der Mitte
	buildWallShelf(block, rng, CFrame.new(-W / 2 + T + 0.8, 0.4, -5) * CFrame.Angles(0, math.rad(-90), 0), 6, 6.5)
	buildGondola(block, rng, CFrame.new(1.5, 0.4, -1) * CFrame.Angles(0, math.rad(90), 0), 9)
	buildGondola(block, rng, CFrame.new(6.5, 0.4, -1) * CFrame.Angles(0, math.rad(90), 0), 9)

	-- Drei Getränkekühlschränke an der rechten Wand
	for _, z in { -6.6, -1.8, 3 } do
		buildFridge(shop, base * CFrame.new(W / 2 - T - 1.3, 0.4, z) * CFrame.Angles(0, math.rad(90), 0), rng)
	end

	-- Snackautomat an der Rückwand
	buildSnackMachine(shop, base * CFrame.new(9, 0.4, D / 2 - T - 1.6), rng, Color3.fromRGB(35, 70, 140))

	-- Eistruhe vor der Theke
	block("Freezer", Vector3.new(4, 3, 2.2), CFrame.new(-7, 1.9, -3), Color3.fromRGB(230, 232, 235), Enum.Material.Metal)
	for i = 0, 5 do
		block("IceCream", Vector3.new(0.5, 0.3, 0.8), CFrame.new(-8.6 + i * 0.65, 3.42, -3), randomProductColor(rng), Enum.Material.SmoothPlastic, { CanCollide = false })
	end
	block("FreezerGlass", Vector3.new(3.6, 0.1, 1.8), CFrame.new(-7, 3.6, -3), COLORS.glass, Enum.Material.Glass, { Transparency = 0.6 })
	local freezerLabel = block("FreezerLabel", Vector3.new(2, 0.8, 0.05), CFrame.new(-7, 2.2, -4.13), Color3.fromRGB(60, 140, 220), Enum.Material.SmoothPlastic, { CanCollide = false })
	Parts.text(Parts.surfaceGui(freezerLabel, Enum.NormalId.Front), { Text = "EIS" })

	-- Stehtisch mit zwei Hockern am Fenster
	Parts.column({ Name = "TablePole", Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = shop }, 3.6, 0.3, base * CFrame.new(-9, 0.4, -7.5))
	Parts.column({ Name = "TableTop", Color = COLORS.wood, Material = Enum.Material.Wood, Parent = shop }, 0.2, 2.6, base * CFrame.new(-9, 4, -7.5))
	for _, x in { -11, -7 } do
		Parts.column({ Name = "StoolLeg", Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = shop }, 2.4, 0.25, base * CFrame.new(x, 0.4, -7.5))
		Parts.new("Seat", {
			Name = "Stool",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 1.4, 1.4),
			CFrame = base * CFrame.new(x, 2.95, -7.5) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(150, 40, 35),
			Material = Enum.Material.Fabric,
			Parent = shop,
		})
	end

	-- Zeitschriftenständer neben der Tür
	block("MagazineRack", Vector3.new(3, 3.4, 1), CFrame.new(-0.5, 2.1, frontZ + 1.2), COLORS.trim, Enum.Material.Wood)
	for i = 0, 2 do
		block("Magazine", Vector3.new(0.8, 1.1, 0.1), CFrame.new(-1.4 + i * 0.9, 3.6, frontZ + 0.75) * CFrame.Angles(math.rad(-15), 0, 0), randomProductColor(rng))
	end

	shop.Parent = parent
	createSeller(shop, base * CFrame.new(-8, 0.4, 6.2))
end

local function buildBooth(parent)
	local booth = Instance.new("Model")
	booth.Name = "Kassenhaeuschen"
	local block = Parts.builder(booth, Layout.BOOTH)
	local W, D, H, T = 12, 9, 9, 0.6
	local frontZ = -D / 2 + T / 2
	local wallColor = Color3.fromRGB(160, 155, 145)

	block("Floor", Vector3.new(W, 0.4, D), CFrame.new(0, 0.2, 0), COLORS.floorDark, Enum.Material.Concrete)
	block("WallBack", Vector3.new(W, H, T), CFrame.new(0, H / 2, D / 2 - T / 2), wallColor, Enum.Material.Concrete)
	block("WallLeft", Vector3.new(T, H, D), CFrame.new(-W / 2 + T / 2, H / 2, 0), wallColor, Enum.Material.Concrete)
	block("WallRight", Vector3.new(T, H, D), CFrame.new(W / 2 - T / 2, H / 2, 0), wallColor, Enum.Material.Concrete)
	block("WallFrontLeft", Vector3.new(4, H, T), CFrame.new(-4, H / 2, frontZ), wallColor, Enum.Material.Concrete)
	block("WallFrontRight", Vector3.new(2, H, T), CFrame.new(5, H / 2, frontZ), wallColor, Enum.Material.Concrete)
	block("WallUnderWindow", Vector3.new(6, 3.2, T), CFrame.new(1, 1.6, frontZ), wallColor, Enum.Material.Concrete)
	block("WallAboveWindow", Vector3.new(6, 2.3, T), CFrame.new(1, H - 1.15, frontZ), wallColor, Enum.Material.Concrete)
	block("Window", Vector3.new(6, 3.5, 0.15), CFrame.new(1, 4.95, frontZ), COLORS.glass, Enum.Material.Glass, { Transparency = 0.55 })
	block("TicketShelf", Vector3.new(6.4, 0.25, 1.4), CFrame.new(1, 3.2, frontZ - 0.6), COLORS.trim, Enum.Material.Wood)
	block("Roof", Vector3.new(W + 2.4, 0.5, D + 2.4), CFrame.new(0, H + 0.25, 0), COLORS.metal, Enum.Material.Metal)
	block("RoofFascia", Vector3.new(W + 2.4, 0.8, 0.2), CFrame.new(0, H + 0.1, -D / 2 - 1.2), Color3.fromRGB(150, 40, 40), Enum.Material.SmoothPlastic)
	block("Door", Vector3.new(0.2, 7, 3), CFrame.new(W / 2 + 0.05, 3.9, 1.5), COLORS.trim, Enum.Material.WoodPlanks)

	-- Innen: Schreibtisch, Stuhl und eine schwache Lampe
	block("Desk", Vector3.new(5, 0.3, 2), CFrame.new(1, 3.3, frontZ + 1.5), COLORS.wood, Enum.Material.Wood)
	block("Chair", Vector3.new(1.6, 2.4, 1.6), CFrame.new(1, 1.6, frontZ + 3.4), Color3.fromRGB(40, 40, 45), Enum.Material.Fabric)
	local lamp = block("DeskLamp", Vector3.new(0.6, 0.6, 0.6), CFrame.new(-1, 3.75, frontZ + 1.5), COLORS.neonWarm, Enum.Material.Neon)
	Parts.light("PointLight", lamp, { Range = 10, Brightness = 0.9, Color = COLORS.neonWarm })

	local nameplate = block("Nameplate", Vector3.new(4, 1, 0.2), CFrame.new(1, H - 1.1, frontZ - 0.4), Color3.fromRGB(230, 225, 210), Enum.Material.Metal)
	Parts.text(Parts.surfaceGui(nameplate, Enum.NormalId.Front), { Text = "KASSE", TextColor3 = Color3.fromRGB(40, 40, 40) })
	local outsideLamp = block("OutsideLamp", Vector3.new(1, 0.4, 0.6), CFrame.new(-4, H - 0.6, frontZ - 0.6), COLORS.neonWarm, Enum.Material.Neon)
	Parts.light("SpotLight", outsideLamp, { Face = Enum.NormalId.Bottom, Range = 14, Angle = 100, Brightness = 1.2, Color = COLORS.neonWarm })

	booth.Parent = parent
end

-- Große Bestenliste mit Holzrahmen, Dach und zwei Strahlern
local function buildLeaderboard(parent)
	local model = Instance.new("Model")
	model.Name = "Bestenliste"
	local base = Layout.LEADERBOARD
	local block = Parts.builder(model, base)
	local W, H, bottom = 16, 10, 3
	local centerY = bottom + H / 2
	local darkWood = Color3.fromRGB(64, 46, 32)

	for _, x in { -W / 2 - 0.2, W / 2 + 0.2 } do
		block("Leg", Vector3.new(0.9, bottom + H + 1.5, 0.9), CFrame.new(x, (bottom + H + 1.5) / 2, 0.4), darkWood, Enum.Material.Wood)
	end
	local board = block("Board", Vector3.new(W, H, 0.4), CFrame.new(0, centerY, 0), Color3.fromRGB(24, 24, 26), Enum.Material.Wood)
	CollectionService:AddTag(board, "LeaderboardBoard")
	block("FrameTop", Vector3.new(W + 1, 0.6, 0.7), CFrame.new(0, bottom + H + 0.3, 0), darkWood, Enum.Material.Wood)
	block("FrameBottom", Vector3.new(W + 1, 0.6, 0.7), CFrame.new(0, bottom - 0.3, 0), darkWood, Enum.Material.Wood)
	block("Roof", Vector3.new(W + 3, 0.4, 2.6), CFrame.new(0, bottom + H + 1.6, -0.3) * CFrame.Angles(math.rad(-14), 0, 0), Color3.fromRGB(70, 50, 36), Enum.Material.WoodPlanks)
	for _, x in { -5, 5 } do
		block("LampArm", Vector3.new(0.25, 0.25, 2.4), CFrame.new(x, bottom + H + 0.9, -1.4), COLORS.darkMetal, Enum.Material.Metal)
		local headPosition = (base * CFrame.new(x, bottom + H + 0.7, -2.6)).Position
		local head = CFrame.lookAt(headPosition, (base * CFrame.new(x * 0.6, centerY - 1, 0)).Position)
		Parts.new("Part", { Name = "LampHead", Size = Vector3.new(1, 0.7, 0.9), CFrame = head, Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = model })
		local lens = Parts.new("Part", {
			Name = "LampLens",
			Size = Vector3.new(0.8, 0.5, 0.05),
			CFrame = head * CFrame.new(0, 0, -0.47),
			Color = Color3.fromRGB(255, 240, 210),
			Material = Enum.Material.Neon,
			Parent = model,
		})
		Parts.light("SpotLight", lens, { Face = Enum.NormalId.Front, Range = 16, Angle = 70, Brightness = 1.4, Color = Color3.fromRGB(255, 240, 210) })
	end

	local gui = Parts.surfaceGui(board, Enum.NormalId.Front)
	Parts.text(gui, {
		Name = "Title",
		Text = "🏆 BESTENLISTE",
		Font = Enum.Font.Creepster,
		TextColor3 = Color3.fromRGB(255, 200, 100),
		Size = UDim2.fromScale(0.9, 0.14),
		Position = UDim2.fromScale(0.05, 0.03),
	})
	Parts.text(gui, {
		Name = "Subtitle",
		Text = "Wer hat die Nacht überlebt?",
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(200, 190, 175),
		Size = UDim2.fromScale(0.9, 0.07),
		Position = UDim2.fromScale(0.05, 0.17),
	})
	local columns = { { "#", 0.04, 0.1 }, { "SPIELER", 0.16, 0.5 }, { "ÜBERLEBT", 0.68, 0.28 } }
	local function row(index, values, y, background, color, font)
		local frame = Instance.new("Frame")
		frame.Name = "Row" .. index
		frame.Size = UDim2.fromScale(0.92, 0.065)
		frame.Position = UDim2.fromScale(0.04, y)
		frame.BackgroundColor3 = background
		frame.BackgroundTransparency = 0.2
		frame.BorderSizePixel = 0
		frame.Parent = gui
		for i, column in columns do
			Parts.text(frame, {
				Name = column[1],
				Text = values[i],
				Font = font,
				TextColor3 = color,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.fromScale(column[3], 0.8),
				Position = UDim2.fromScale(column[2], 0.1),
			})
		end
	end
	row(0, { "#", "SPIELER", "ÜBERLEBT" }, 0.27, Color3.fromRGB(120, 30, 30), Color3.fromRGB(255, 230, 200), Enum.Font.GothamBold)
	for rank = 1, 9 do
		local shade = rank % 2 == 0 and Color3.fromRGB(40, 38, 40) or Color3.fromRGB(32, 30, 32)
		local color = rank == 1 and Color3.fromRGB(255, 210, 90)
			or rank == 2 and Color3.fromRGB(210, 210, 220)
			or rank == 3 and Color3.fromRGB(215, 150, 90)
			or Color3.fromRGB(220, 215, 205)
		row(rank, { rank .. ".", "---", "0×" }, 0.27 + rank * 0.075, shade, color, Enum.Font.SpecialElite)
	end

	model.Parent = parent
end

-- Verlassener Wohnwagen; hinter einem Fenster brennt noch Licht
local function buildCamper(parent)
	local camper = Instance.new("Model")
	camper.Name = "Wohnwagen"
	local block = Parts.builder(camper, Layout.CAMPER * CFrame.Angles(0, 0, math.rad(2)))
	local L, Wd = 16, 7

	block("Body", Vector3.new(L, 6.5, Wd), CFrame.new(0, 4.45, 0), Color3.fromRGB(190, 182, 165))
	block("Stripe", Vector3.new(L + 0.05, 0.8, Wd + 0.05), CFrame.new(0, 3.3, 0), Color3.fromRGB(120, 80, 50))
	block("Roof", Vector3.new(L + 0.3, 0.3, Wd + 0.3), CFrame.new(0, 7.85, 0), Color3.fromRGB(160, 155, 145))
	block("RoofVent", Vector3.new(2, 0.8, 2), CFrame.new(-3, 8.3, 0), Color3.fromRGB(140, 140, 140))
	block("Door", Vector3.new(2.4, 5, 0.12), CFrame.new(1, 4, -Wd / 2 - 0.05), Color3.fromRGB(170, 162, 148))
	block("DoorHandle", Vector3.new(0.3, 0.15, 0.2), CFrame.new(2, 4, -Wd / 2 - 0.15), Color3.fromRGB(80, 80, 80), Enum.Material.Metal)
	block("Step", Vector3.new(2.4, 0.3, 1.2), CFrame.new(1, 1, -Wd / 2 - 0.7), Color3.fromRGB(70, 70, 70), Enum.Material.DiamondPlate)

	local litWindow = block("WindowLit", Vector3.new(3, 2, 0.12), CFrame.new(-4.5, 5.2, -Wd / 2 - 0.05), Color3.fromRGB(110, 70, 30), Enum.Material.Neon)
	Parts.light("PointLight", litWindow, { Range = 9, Brightness = 0.6, Color = Color3.fromRGB(255, 160, 80) })
	CollectionService:AddTag(litWindow, "FlickerLamp")
	block("Window", Vector3.new(3, 2, 0.12), CFrame.new(5, 5.2, -Wd / 2 - 0.05), Color3.fromRGB(25, 28, 32), Enum.Material.Glass)

	for _, z in { -Wd / 2 - 0.4, Wd / 2 + 0.4 } do
		block("Wheel", Vector3.new(1, 2.6, 2.6), CFrame.new(1, 1.3, z) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(25, 25, 25), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	end
	block("Hitch", Vector3.new(4, 0.4, 0.4), CFrame.new(-L / 2 - 2, 1.4, 0), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	block("JackStand", Vector3.new(0.4, 1.4, 0.4), CFrame.new(-L / 2 - 3.5, 0.7, 0), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)

	camper.Parent = parent
end

function Buildings.build(parent)
	local buildings = Instance.new("Folder")
	buildings.Name = "Buildings"
	buildings.Parent = parent

	buildShop(buildings)
	buildBooth(buildings)
	buildLeaderboard(buildings)
	buildCamper(buildings)
	buildDrinkMachine(buildings, Layout.VENDING_MACHINE)
	buildSnackMachine(buildings, Layout.VENDING_MACHINE * CFrame.new(4.6, 0, 0), Random.new(9), Color3.fromRGB(150, 110, 30))
end

return Buildings
