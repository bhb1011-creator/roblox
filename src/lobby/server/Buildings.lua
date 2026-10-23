-- Gebäude am Südrand: begehbarer Kiosk mit Verkäufer und drei Snack-Regalen,
-- Kassenhäuschen mit Kassierer (Robux-Käufe), große Bestenliste, verlassener
-- Wohnwagen.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Layout = require(script.Parent.Layout)
local Parts = require(game:GetService("ReplicatedStorage").Shared.Parts)

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

-- Figur hinter einer Theke mit Namensschild und Interaktion (E).
-- `feet` = Position der Füße, Blickrichtung = LookVector.
local function createNpc(parent, feet, options)
	local ok, npc = pcall(function()
		local description = Instance.new("HumanoidDescription")
		local skin = options.skin
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = options.shirt
		description.LeftLegColor = Color3.fromRGB(40, 40, 48)
		description.RightLegColor = Color3.fromRGB(40, 40, 48)
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn(options.name .. " konnte nicht erstellt werden:", npc)
		return nil
	end

	npc.Name = options.name
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	root.Anchored = true
	npc:PivotTo(feet * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0))
	npc.Parent = parent

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
	nameTag.Size = UDim2.fromOffset(160, 30)
	nameTag.StudsOffset = Vector3.new(0, 3, 0)
	nameTag.MaxDistance = 35
	nameTag.Parent = root
	Parts.text(nameTag, { Text = options.name, TextColor3 = Color3.fromRGB(255, 220, 160), TextStrokeTransparency = 0.4 })

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = options.action
	prompt.ObjectText = options.name
	prompt.MaxActivationDistance = options.distance or 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	CollectionService:AddTag(prompt, options.tag)
	return npc
end

-- Lockeres Snack-Regal: drei Böden mit je drei Snacks und Preisschild.
-- Rückwand bei +Z, Waren zeigen nach -Z.
local function buildSnackShelf(block, cframe, firstSnack)
	local width, height, depth = 6, 5.6, 1.6
	local snacks = Config.SNACKS
	block("ShelfBack", Vector3.new(width, height, 0.2), cframe * CFrame.new(0, height / 2, depth / 2), COLORS.trim, Enum.Material.Wood)
	for _, x in { -width / 2, width / 2 } do
		block("ShelfSide", Vector3.new(0.2, height, depth), cframe * CFrame.new(x, height / 2, 0), COLORS.trim, Enum.Material.Wood)
	end
	block("ShelfTop", Vector3.new(width + 0.2, 0.2, depth), cframe * CFrame.new(0, height, 0), COLORS.trim, Enum.Material.Wood)
	for level = 0, 2 do
		local y = 0.5 + level * 1.7
		block("ShelfBoard", Vector3.new(width, 0.15, depth), cframe * CFrame.new(0, y, 0), COLORS.wood, Enum.Material.Wood)
		for i = 0, 2 do
			local snack = snacks[(firstSnack + level * 3 + i - 1) % #snacks + 1]
			local x = -width / 2 + (i + 0.5) * width / 3
			block("Snack", Vector3.new(0.9, 1.1, 0.45), cframe * CFrame.new(x, y + 0.63, -0.1), snack.color, Enum.Material.SmoothPlastic, { CanCollide = false })
			block("PriceTag", Vector3.new(0.7, 0.25, 0.04), cframe * CFrame.new(x, y, -depth / 2 - 0.02), Color3.fromRGB(240, 235, 220), Enum.Material.SmoothPlastic, { CanCollide = false })
		end
	end
	local header = block("ShelfSign", Vector3.new(3, 0.8, 0.1), cframe * CFrame.new(0, height + 0.6, 0.3), Color3.fromRGB(170, 40, 35), Enum.Material.SmoothPlastic, { CanCollide = false })
	Parts.text(Parts.surfaceGui(header, Enum.NormalId.Front), { Text = "SNACKS" })
end

local function buildShop(parent)
	local shop = Instance.new("Model")
	shop.Name = "Kiosk"
	local base = Layout.SHOP
	local block = Parts.builder(shop, base)
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
	for i, offset in { Vector3.new(-8, H - 0.15, -4), Vector3.new(-8, H - 0.15, 5), Vector3.new(6, H - 0.15, -4), Vector3.new(6, H - 0.15, 5) } do
		local panel = block("CeilingLight", Vector3.new(5, 0.2, 1.2), CFrame.new(offset), COLORS.coldLight, Enum.Material.Neon)
		Parts.light("PointLight", panel, { Range = 16, Brightness = 0.9, Color = COLORS.coldLight, Shadows = i == 1 })
		if i == 3 then
			CollectionService:AddTag(panel, "FlickerLamp")
		end
	end

	-- Theke mit Kasse
	block("Counter", Vector3.new(10, 3.6, 2.2), CFrame.new(-8, 2.2, 3), COLORS.wood, Enum.Material.WoodPlanks)
	block("CounterSide", Vector3.new(2.2, 3.6, 3), CFrame.new(-2, 2.2, 5.6), COLORS.wood, Enum.Material.WoodPlanks)
	block("CounterTop", Vector3.new(10.4, 0.25, 2.6), CFrame.new(-8, 4.1, 3), Color3.fromRGB(40, 38, 36), Enum.Material.Granite)
	block("CounterSideTop", Vector3.new(2.6, 0.25, 3.2), CFrame.new(-2, 4.1, 5.6), Color3.fromRGB(40, 38, 36), Enum.Material.Granite)
	block("Register", Vector3.new(1.6, 1, 1.2), CFrame.new(-5, 4.7, 3.2), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	block("RegisterDisplay", Vector3.new(1, 0.4, 0.1), CFrame.new(-5, 5.4, 2.8) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(90, 255, 120), Enum.Material.Neon)
	block("CardTerminal", Vector3.new(0.5, 0.2, 0.8), CFrame.new(-3.7, 4.33, 2.5), COLORS.darkMetal)

	-- Rückwand hinter dem Verkäufer: Arbeitsfläche mit Kaffeemaschine und Preistafel
	block("BackCounter", Vector3.new(12, 3.4, 1.6), CFrame.new(-8, 2.1, D / 2 - T - 0.8), COLORS.wood, Enum.Material.WoodPlanks)
	block("CoffeeMachine", Vector3.new(1.6, 2, 1.2), CFrame.new(-12, 4.8, D / 2 - T - 0.9), COLORS.darkMetal, Enum.Material.Metal)
	block("CoffeeLight", Vector3.new(0.3, 0.3, 0.05), CFrame.new(-11.6, 5.2, D / 2 - T - 1.53), Color3.fromRGB(255, 80, 60), Enum.Material.Neon)
	block("CupStack", Vector3.new(0.5, 1, 0.5), CFrame.new(-10.6, 4.3, D / 2 - T - 0.9), Color3.fromRGB(235, 235, 230))
	local priceLines = {}
	for _, snack in Config.SNACKS do
		table.insert(priceLines, snack.title .. "  " .. snack.price)
	end
	local prices = block("PriceBoard", Vector3.new(9, 3.2, 0.15), CFrame.new(-8, 7.6, D / 2 - T - 0.1), Color3.fromRGB(25, 25, 25))
	Parts.text(Parts.surfaceGui(prices, Enum.NormalId.Front, true), {
		Text = table.concat(priceLines, "\n"),
		Font = Enum.Font.SpecialElite,
		TextColor3 = Color3.fromRGB(240, 230, 200),
		Size = UDim2.fromScale(0.9, 0.88),
		Position = UDim2.fromScale(0.05, 0.06),
	})

	-- Drei lockere Snack-Regale
	buildSnackShelf(block, CFrame.new(-W / 2 + T + 0.8, 0.4, -4) * CFrame.Angles(0, math.rad(-90), 0), 1)
	buildSnackShelf(block, CFrame.new(W / 2 - T - 0.8, 0.4, -5) * CFrame.Angles(0, math.rad(90), 0), 4)
	buildSnackShelf(block, CFrame.new(W / 2 - T - 0.8, 0.4, 4) * CFrame.Angles(0, math.rad(90), 0), 2)

	-- Stehtisch mit zwei Hockern am Fenster
	Parts.column({ Name = "TablePole", Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = shop }, 3.6, 0.3, base * CFrame.new(-8, 0.4, -7.5))
	Parts.column({ Name = "TableTop", Color = COLORS.wood, Material = Enum.Material.Wood, Parent = shop }, 0.2, 2.6, base * CFrame.new(-8, 4, -7.5))
	for _, x in { -10, -6 } do
		Parts.column({ Name = "StoolLeg", Color = COLORS.darkMetal, Material = Enum.Material.Metal, Parent = shop }, 2.4, 0.25, base * CFrame.new(x, 0.4, -7.5))
		Parts.column({ Name = "StoolCushion", Color = Color3.fromRGB(150, 40, 35), Material = Enum.Material.Fabric, Parent = shop }, 0.3, 1.4, base * CFrame.new(x, 2.8, -7.5))
		-- Unsichtbare, gerade Sitzfläche: so sitzt man aufrecht und schaut zum Tisch
		local stoolPosition = (base * CFrame.new(x, 3.05, -7.5)).Position
		local tablePosition = (base * CFrame.new(-8, 3.05, -7.5)).Position
		Parts.new("Seat", {
			Name = "Stool",
			Size = Vector3.new(1.2, 0.2, 1.2),
			CFrame = CFrame.lookAt(stoolPosition, tablePosition),
			Transparency = 1,
			Parent = shop,
		})
	end

	shop.Parent = parent
	createNpc(shop, base * CFrame.new(-8, 0.4, 6.2), {
		name = "Verkäufer",
		action = "Snacks kaufen",
		tag = "ShopPrompt",
		skin = Color3.fromRGB(205, 160, 125),
		shirt = Color3.fromRGB(45, 70, 50),
	})
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
	local lamp = block("DeskLamp", Vector3.new(0.6, 0.6, 0.6), CFrame.new(-1, 3.75, frontZ + 1.5), COLORS.neonWarm, Enum.Material.Neon)
	Parts.light("PointLight", lamp, { Range = 10, Brightness = 0.9, Color = COLORS.neonWarm })

	local nameplate = block("Nameplate", Vector3.new(4, 1, 0.2), CFrame.new(1, H - 1.1, frontZ - 0.4), Color3.fromRGB(230, 225, 210), Enum.Material.Metal)
	Parts.text(Parts.surfaceGui(nameplate, Enum.NormalId.Front), { Text = "KASSE", TextColor3 = Color3.fromRGB(40, 40, 40) })
	local outsideLamp = block("OutsideLamp", Vector3.new(1, 0.4, 0.6), CFrame.new(-4, H - 0.6, frontZ - 0.6), COLORS.neonWarm, Enum.Material.Neon)
	Parts.light("SpotLight", outsideLamp, { Face = Enum.NormalId.Bottom, Range = 14, Angle = 100, Brightness = 1.2, Color = COLORS.neonWarm })

	booth.Parent = parent
	createNpc(booth, Layout.BOOTH * CFrame.new(1, 0.4, frontZ + 3.2), {
		name = "Kassierer",
		action = "Kasse öffnen",
		tag = "CashierPrompt",
		distance = 12,
		skin = Color3.fromRGB(150, 105, 80),
		shirt = Color3.fromRGB(120, 30, 35),
	})
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
end

return Buildings
