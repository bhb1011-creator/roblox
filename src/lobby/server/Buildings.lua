-- Gebäude am Südrand: begehbarer Kiosk mit Verkäufer, Kassenhäuschen mit
-- Bestenliste, verlassener Wohnwagen und Getränkeautomat.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Layout = require(script.Parent.Layout)
local Parts = require(script.Parent.Parts)

local Buildings = {}

local COLORS = {
	wall = Color3.fromRGB(96, 74, 58),
	trim = Color3.fromRGB(60, 44, 34),
	roof = Color3.fromRGB(48, 48, 52),
	floor = Color3.fromRGB(150, 146, 138),
	glass = Color3.fromRGB(120, 140, 155),
	wood = Color3.fromRGB(110, 80, 55),
	neonWarm = Color3.fromRGB(255, 200, 110),
	coldLight = Color3.fromRGB(215, 230, 255),
}

local IDLE_ANIMATION = "rbxassetid://507766388" -- Standard-Atemanimation von Roblox (R15)

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

local function buildShelf(block, rng, cframe, width)
	local height, depth = 6.5, 1.6
	block("ShelfBack", Vector3.new(width, height, 0.2), cframe * CFrame.new(0, height / 2, depth / 2), COLORS.trim, Enum.Material.Wood)
	for _, x in { -width / 2, width / 2 } do
		block("ShelfSide", Vector3.new(0.2, height, depth), cframe * CFrame.new(x, height / 2, 0), COLORS.trim, Enum.Material.Wood)
	end
	for level = 0, 3 do
		local y = 0.3 + level * 1.7
		block("ShelfBoard", Vector3.new(width, 0.15, depth), cframe * CFrame.new(0, y, 0), COLORS.wood, Enum.Material.Wood)
		local x = -width / 2 + 0.5
		while x < width / 2 - 0.6 do
			local size = Vector3.new(rng:NextNumber(0.5, 0.9), rng:NextNumber(0.6, 1.3), rng:NextNumber(0.5, 0.9))
			block(
				"Product",
				size,
				cframe * CFrame.new(x + size.X / 2, y + 0.075 + size.Y / 2, rng:NextNumber(-0.2, 0.2)),
				Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.4, 0.8), rng:NextNumber(0.5, 0.9)),
				Enum.Material.SmoothPlastic,
				{ CanCollide = false }
			)
			x += size.X + 0.12
		end
	end
end

local function buildShop(parent)
	local shop = Instance.new("Model")
	shop.Name = "Kiosk"
	local base = Layout.SHOP
	local block = Parts.builder(shop, base)
	local rng = Random.new(5)
	local W, D, H, T = 22, 16, 10, 0.8
	local frontZ = -D / 2 + T / 2

	block("Floor", Vector3.new(W, 0.4, D), CFrame.new(0, 0.2, 0), COLORS.floor, Enum.Material.Marble)
	block("WallBack", Vector3.new(W, H, T), CFrame.new(0, H / 2, D / 2 - T / 2), COLORS.wall, Enum.Material.WoodPlanks)
	block("WallLeft", Vector3.new(T, H, D), CFrame.new(-W / 2 + T / 2, H / 2, 0), COLORS.wall, Enum.Material.WoodPlanks)
	block("WallRight", Vector3.new(T, H, D), CFrame.new(W / 2 - T / 2, H / 2, 0), COLORS.wall, Enum.Material.WoodPlanks)

	-- Vorderwand mit großem Fenster (links) und Türöffnung (rechts)
	local function frontPiece(x1, x2, y1, y2)
		block("WallFront", Vector3.new(x2 - x1, y2 - y1, T), CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, frontZ), COLORS.wall, Enum.Material.WoodPlanks)
	end
	frontPiece(-11, -9, 0, H)
	frontPiece(-9, -1, 0, 2.5)
	frontPiece(-9, -1, 7.5, H)
	frontPiece(-1, 1, 0, H)
	frontPiece(1, 7, 8, H)
	frontPiece(7, 11, 0, H)
	block("Window", Vector3.new(8, 5, 0.2), CFrame.new(-5, 5, frontZ), COLORS.glass, Enum.Material.Glass, { Transparency = 0.6 })
	block("WindowSill", Vector3.new(8.6, 0.3, 1.4), CFrame.new(-5, 2.4, frontZ - 0.3), COLORS.trim, Enum.Material.Wood)
	for _, x in { 1, 7 } do
		block("DoorFrame", Vector3.new(0.4, 8, 1.2), CFrame.new(x, 4, frontZ), COLORS.trim, Enum.Material.Wood)
	end
	block("Door", Vector3.new(0.25, 7.8, 5.6), CFrame.new(6.6, 4.3, -D / 2 + T + 2.8), COLORS.trim, Enum.Material.WoodPlanks)
	block("DoorMat", Vector3.new(5, 0.05, 3), CFrame.new(4, 0.43, -D / 2 + T + 1.6), Color3.fromRGB(110, 35, 30), Enum.Material.Fabric)

	block("Roof", Vector3.new(W + 2, 0.8, D + 2), CFrame.new(0, H + 0.4, 0), COLORS.roof, Enum.Material.Metal)
	block("RoofTrim", Vector3.new(W + 2.2, 0.6, 0.4), CFrame.new(0, H + 0.2, -D / 2 - 1.1), COLORS.trim, Enum.Material.Wood)
	block("Awning", Vector3.new(8, 0.3, 3), CFrame.new(4, 8.1, -D / 2 - 1.4) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(140, 35, 35), Enum.Material.Fabric)

	-- Leuchtreklame über dem Eingang
	local sign = block("Sign", Vector3.new(12, 1.5, 0.4), CFrame.new(-2, H - 0.8, -D / 2 - 0.2), Color3.fromRGB(25, 22, 20))
	Parts.text(Parts.surfaceGui(sign, Enum.NormalId.Front, true), {
		Text = "KIOSK",
		Font = Enum.Font.Arcade,
		TextColor3 = COLORS.neonWarm,
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
	})
	Parts.light("PointLight", sign, { Range = 14, Brightness = 1, Color = COLORS.neonWarm })

	local openSign = block("OpenSign", Vector3.new(3, 1.2, 0.1), CFrame.new(-5, 6.4, frontZ + 0.3), Color3.fromRGB(40, 10, 10), Enum.Material.SmoothPlastic, { CanCollide = false })
	Parts.text(Parts.surfaceGui(openSign, Enum.NormalId.Front, true), {
		Text = "OFFEN",
		Font = Enum.Font.Arcade,
		TextColor3 = Color3.fromRGB(255, 60, 60),
	})
	Parts.light("PointLight", openSign, { Range = 7, Brightness = 1, Color = Color3.fromRGB(255, 60, 60) })
	CollectionService:AddTag(openSign, "FlickerLamp")

	-- Deckenlampen (eine davon flackert)
	for i, offset in { Vector3.new(-4, H - 0.15, -2), Vector3.new(4, H - 0.15, 2) } do
		local panel = block("CeilingLight", Vector3.new(5, 0.2, 1.2), CFrame.new(offset), COLORS.coldLight, Enum.Material.Neon)
		Parts.light("PointLight", panel, { Range = 18, Brightness = 1.1, Color = COLORS.coldLight, Shadows = true })
		if i == 1 then
			CollectionService:AddTag(panel, "FlickerLamp")
		end
	end

	-- Theke mit Kasse
	block("Counter", Vector3.new(8, 3.6, 2), CFrame.new(-2, 2.2, 1.5), COLORS.wood, Enum.Material.WoodPlanks)
	block("CounterTop", Vector3.new(8.4, 0.25, 2.4), CFrame.new(-2, 4.1, 1.5), Color3.fromRGB(40, 38, 36), Enum.Material.Granite)
	block("Register", Vector3.new(1.6, 1, 1.2), CFrame.new(0.5, 4.7, 1.6), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	block("RegisterDisplay", Vector3.new(1, 0.4, 0.1), CFrame.new(0.5, 5.4, 1.2) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(90, 255, 120), Enum.Material.Neon)
	block("CandyBox", Vector3.new(1.4, 0.6, 0.9), CFrame.new(-4.5, 4.55, 1.2), Color3.fromRGB(200, 60, 120))
	block("Newspapers", Vector3.new(1.2, 0.4, 0.9), CFrame.new(-2.8, 4.45, 1.0), Color3.fromRGB(215, 210, 195))

	-- Regale: links an der Wand und hinter dem Verkäufer
	buildShelf(block, rng, CFrame.new(-W / 2 + T + 0.9, 0.4, -3) * CFrame.Angles(0, math.rad(-90), 0), 5.5)
	buildShelf(block, rng, CFrame.new(-W / 2 + T + 0.9, 0.4, 3.5) * CFrame.Angles(0, math.rad(-90), 0), 5.5)
	buildShelf(block, rng, CFrame.new(-2, 0.4, D / 2 - T - 0.9), 8)

	-- Kühlschrank mit Getränken an der rechten Wand
	local fridgeX = W / 2 - T - 1.1
	block("Fridge", Vector3.new(2, 7.5, 6), CFrame.new(fridgeX, 4.15, 3), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
	local fridgeLight = block("FridgeLight", Vector3.new(0.1, 6.6, 5.4), CFrame.new(fridgeX - 1.05, 4.2, 3), Color3.fromRGB(190, 225, 255), Enum.Material.Neon)
	Parts.light("PointLight", fridgeLight, { Range = 8, Brightness = 0.8, Color = Color3.fromRGB(170, 210, 255) })
	for row = 0, 3 do
		for col = 0, 6 do
			block(
				"Bottle",
				Vector3.new(0.35, 1, 0.35),
				CFrame.new(fridgeX - 1.25, 1.3 + row * 1.6, 0.6 + col * 0.8),
				Color3.fromHSV((row * 7 + col) % 5 / 5, 0.7, 0.8),
				Enum.Material.Glass,
				{ Transparency = 0.2, CanCollide = false }
			)
		end
	end
	block("FridgeGlass", Vector3.new(0.1, 7, 5.6), CFrame.new(fridgeX - 1.55, 4.15, 3), COLORS.glass, Enum.Material.Glass, { Transparency = 0.7 })

	-- Zeitschriftenständer am Fenster und ein Mülleimer
	block("MagazineRack", Vector3.new(4, 3, 1), CFrame.new(-5, 1.9, -D / 2 + T + 1), COLORS.trim, Enum.Material.Wood)
	block("Magazines", Vector3.new(3.6, 0.9, 0.6), CFrame.new(-5, 3.7, -D / 2 + T + 1.1) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(190, 70, 60))

	shop.Parent = parent
	createSeller(shop, base * CFrame.new(-2, 0.4, 4.2))
end

local function buildBooth(parent)
	local booth = Instance.new("Model")
	booth.Name = "Kassenhaeuschen"
	local block = Parts.builder(booth, Layout.BOOTH)
	local W, D, H = 10, 8, 8
	local frontZ = -D / 2

	block("Walls", Vector3.new(W, H, D), CFrame.new(0, H / 2, 0), Color3.fromRGB(150, 145, 135), Enum.Material.Concrete)
	block("Roof", Vector3.new(W + 2, 0.5, D + 2), CFrame.new(0, H + 0.25, 0), Color3.fromRGB(70, 72, 76), Enum.Material.Metal)
	block("Window", Vector3.new(3, 2.6, 0.1), CFrame.new(2.8, 4.6, frontZ - 0.1), COLORS.glass, Enum.Material.Glass, { Transparency = 0.3 })
	block("WindowGlow", Vector3.new(2.8, 2.4, 0.05), CFrame.new(2.8, 4.6, frontZ - 0.03), Color3.fromRGB(120, 90, 50), Enum.Material.Neon)
	block("Door", Vector3.new(0.2, 6.5, 3), CFrame.new(W / 2 + 0.05, 3.25, 1), COLORS.trim, Enum.Material.WoodPlanks)

	local nameplate = block("Nameplate", Vector3.new(4, 1, 0.2), CFrame.new(2.8, 6.6, frontZ - 0.1), Color3.fromRGB(230, 225, 210), Enum.Material.Metal)
	Parts.text(Parts.surfaceGui(nameplate, Enum.NormalId.Front), { Text = "KASSE", TextColor3 = Color3.fromRGB(40, 40, 40) })

	local board = block("Board", Vector3.new(4.6, 5.5, 0.3), CFrame.new(-2.4, 4.2, frontZ - 0.15), Color3.fromRGB(28, 26, 24))
	CollectionService:AddTag(board, "LeaderboardBoard")
	local gui = Parts.surfaceGui(board, Enum.NormalId.Front)
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	Parts.text(gui, {
		Name = "Title",
		Text = "🏆 ÜBERLEBT",
		TextColor3 = Color3.fromRGB(255, 210, 120),
		Size = UDim2.fromScale(1, 0.2),
		LayoutOrder = 0,
	})
	for rank = 1, 5 do
		Parts.text(gui, {
			Name = "Row" .. rank,
			Text = rank .. ".  ---",
			Font = Enum.Font.SpecialElite,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(0.85, 0.13),
			LayoutOrder = rank,
		})
	end
	Parts.light("PointLight", board, { Range = 10, Brightness = 0.8, Color = COLORS.neonWarm })

	booth.Parent = parent
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

local function buildVendingMachine(parent)
	local machine = Instance.new("Model")
	machine.Name = "Getraenkeautomat"
	local block = Parts.builder(machine, Layout.VENDING_MACHINE)
	block("Body", Vector3.new(3.5, 7, 2.5), CFrame.new(0, 3.5, 0), Color3.fromRGB(150, 30, 35), Enum.Material.Metal)
	local front = block("Front", Vector3.new(2.6, 4.4, 0.1), CFrame.new(-0.2, 4.4, -1.27), Color3.fromRGB(170, 205, 220), Enum.Material.Neon)
	Parts.light("PointLight", front, { Range = 11, Brightness = 0.9, Color = Color3.fromRGB(170, 210, 255) })
	CollectionService:AddTag(front, "FlickerLamp")
	block("Slot", Vector3.new(2, 0.6, 0.15), CFrame.new(-0.2, 1.3, -1.27), Color3.fromRGB(20, 20, 20))
	block("Buttons", Vector3.new(0.4, 2, 0.12), CFrame.new(1.4, 4.4, -1.27), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	machine.Parent = parent
end

function Buildings.build(parent)
	local buildings = Instance.new("Folder")
	buildings.Name = "Buildings"
	buildings.Parent = parent

	buildShop(buildings)
	buildBooth(buildings)
	buildCamper(buildings)
	buildVendingMachine(buildings)
end

return Buildings
