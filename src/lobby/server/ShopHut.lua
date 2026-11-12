-- Shop-Hütte auf der Ostseite der Lobby: kleine Holzhütte mit Satteldach und Veranda, passend zu
-- Kiosk und Lagerplatz. Innen: Verkäufer an der Theke (öffnet den Shop), Kleiderständer mit den
-- Jacken auf Bügeln, Wandregal mit Mützen, Brillen & Co., Spiegel zum Anprobieren, im Schaufenster
-- Tafeln zum Katalog (Skins sieht man nur im Menü), Sessel in der Ecke. Daneben steht der Sportwagen.
-- Jedes Stück hat „Try on“ (Tag ShowroomItemPrompt, Attribut ShopItem) und öffnet den Shop dort.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(script.Parent.Layout)
local Parts = require(ReplicatedStorage.Shared.Parts)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local SportsCar = require(ReplicatedStorage.Shared.SportsCar)

local ShopHut = {}

local Y = Layout.GROUND_Y
-- Mitte der Hütte; die Vorderseite (Tür) zeigt nach Westen zum Lagerfeuer
local CENTER = Vector3.new(62, Y, 10)
local BASE = CFrame.lookAt(CENTER, Vector3.new(0, Y, CENTER.Z))
local W, D, H, T = 22, 16, 9, 0.7 -- Breite (lokal X), Tiefe (lokal Z), Wandhöhe, Wandstärke
local RIDGE = 3.6 -- Dachhöhe über der Wand
local FLOOR = 0.5 -- Oberkante des Bodens (lokal)

local C = {
	wall = Color3.fromRGB(104, 80, 60),
	log = Color3.fromRGB(70, 52, 38),
	trim = Color3.fromRGB(56, 41, 31),
	floor = Color3.fromRGB(122, 92, 64),
	roof = Color3.fromRGB(58, 46, 40),
	glass = Color3.fromRGB(120, 140, 155),
	warm = Color3.fromRGB(255, 205, 140),
	paper = Color3.fromRGB(236, 226, 205),
	ink = Color3.fromRGB(45, 36, 30),
	metal = Color3.fromRGB(70, 70, 74),
}

local function money(n)
	local text = tostring(n)
	return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function priceText(entry)
	if entry.pack then
		for _, pack in ShopCatalog.PACKS do
			if pack.id == entry.pack then
				return "in the " .. pack.title
			end
		end
	end
	local parts = {}
	if entry.coins then
		table.insert(parts, money(entry.coins) .. " coins")
	end
	if entry.robux then
		table.insert(parts, entry.robux .. " R$")
	end
	return table.concat(parts, "  ·  ")
end

local function tryOnPrompt(parent, itemId, title)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Try on"
	prompt.ObjectText = title
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton -- nur das nächste Stück zeigen
	prompt:SetAttribute("ShopItem", itemId)
	CollectionService:AddTag(prompt, "ShowroomItemPrompt")
	prompt.Parent = parent
	return prompt
end

-- kleines Preisschild aus Papier (Schrift zeigt nach `facing`)
local function priceTag(parent, position, facing, title, price)
	local cf = CFrame.lookAt(position, position + facing)
	local tag = Parts.new("Part", { Name = "PriceTag", Size = Vector3.new(1.5, 0.75, 0.04), CFrame = cf, Color = C.paper, CanCollide = false, Parent = parent })
	local gui = Parts.surfaceGui(tag, Enum.NormalId.Front, false)
	gui.PixelsPerStud = 110
	Parts.text(gui, { Text = title, Font = Enum.Font.SpecialElite, TextColor3 = C.ink, Size = UDim2.fromScale(0.92, 0.5), Position = UDim2.fromScale(0.04, 0.04) })
	Parts.text(gui, { Text = price, Font = Enum.Font.GothamMedium, TextColor3 = C.ink, Size = UDim2.fromScale(0.92, 0.36), Position = UDim2.fromScale(0.04, 0.58) })
	return tag
end

------------------------------------------------------------------ Hütte
local function buildCabin(model, block)
	local frontZ = -D / 2 + T / 2
	-- Boden und Veranda
	block("Floor", Vector3.new(W, FLOOR, D), CFrame.new(0, FLOOR / 2, 0), C.floor, Enum.Material.WoodPlanks)
	block("Porch", Vector3.new(W, FLOOR - 0.1, 4), CFrame.new(0, (FLOOR - 0.1) / 2, -D / 2 - 2), C.floor, Enum.Material.WoodPlanks)
	block("PorchStep", Vector3.new(6, 0.22, 1.2), CFrame.new(0, 0.11, -D / 2 - 4.6), C.floor, Enum.Material.WoodPlanks)
	for _, x in { -W / 2 + 0.4, W / 2 - 0.4 } do
		block("PorchPost", Vector3.new(0.6, H + 0.6, 0.6), CFrame.new(x, (H + 0.6) / 2, -D / 2 - 3.6), C.log, Enum.Material.Wood)
	end
	block("PorchRoof", Vector3.new(W + 1, 0.3, 4.6), CFrame.new(0, H + 0.3, -D / 2 - 2) * CFrame.Angles(math.rad(-10), 0, 0), C.roof, Enum.Material.WoodPlanks)

	-- Wände (Rückwand, Seiten) und dunkle Eckbalken
	block("WallBack", Vector3.new(W, H, T), CFrame.new(0, H / 2, D / 2 - T / 2), C.wall, Enum.Material.WoodPlanks)
	block("WallLeft", Vector3.new(T, H, D), CFrame.new(-W / 2 + T / 2, H / 2, 0), C.wall, Enum.Material.WoodPlanks)
	block("WallRight", Vector3.new(T, H, D), CFrame.new(W / 2 - T / 2, H / 2, 0), C.wall, Enum.Material.WoodPlanks)
	for _, x in { -W / 2, W / 2 } do
		for _, z in { -D / 2, D / 2 } do
			block("CornerLog", Vector3.new(1, H + 0.2, 1), CFrame.new(x, (H + 0.2) / 2, z), C.log, Enum.Material.Wood)
		end
	end
	-- Vorderwand: Tür in der Mitte, zwei Schaufenster
	local function front(x1, x2, y1, y2)
		block("WallFront", Vector3.new(x2 - x1, y2 - y1, T), CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, frontZ), C.wall, Enum.Material.WoodPlanks)
	end
	front(-W / 2, -9.5, 0, H)
	front(-3, 3, 7.6, H)
	front(9.5, W / 2, 0, H)
	for _, window in { { -9.5, -3 }, { 3, 9.5 } } do
		local x1, x2 = window[1], window[2]
		front(x1, x2, 0, 1.8)
		front(x1, x2, 7.2, H)
		-- kein Glas-Material: hinter Glas sind Schilder (SurfaceGui) unsichtbar
		block("ShopWindow", Vector3.new(x2 - x1, 5.4, 0.15), CFrame.new((x1 + x2) / 2, 4.5, frontZ), C.glass, Enum.Material.SmoothPlastic, { Transparency = 0.85, Reflectance = 0.15, CastShadow = false })
		block("WindowFrame", Vector3.new(x2 - x1 + 0.3, 0.25, T + 0.2), CFrame.new((x1 + x2) / 2, 1.8, frontZ), C.trim, Enum.Material.Wood)
		block("WindowFrame", Vector3.new(x2 - x1 + 0.3, 0.25, T + 0.2), CFrame.new((x1 + x2) / 2, 7.2, frontZ), C.trim, Enum.Material.Wood)
		-- Blumenkasten unter dem Fenster
		block("FlowerBox", Vector3.new(x2 - x1 - 1, 0.6, 0.7), CFrame.new((x1 + x2) / 2, 1.3, frontZ - 0.7), C.trim, Enum.Material.Wood)
		for i = 0, 4 do
			local x = x1 + 1 + i * (x2 - x1 - 2) / 4
			block("Flower", Vector3.new(0.35, 0.35, 0.35), CFrame.new(x, 1.75, frontZ - 0.7), i % 2 == 0 and Color3.fromRGB(190, 60, 55) or Color3.fromRGB(230, 200, 90), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, CanCollide = false })
		end
	end
	for _, x in { -3, 3 } do
		block("DoorFrame", Vector3.new(0.4, 7.6, T + 0.3), CFrame.new(x, 3.8, frontZ), C.trim, Enum.Material.Wood)
	end
	block("DoorLintel", Vector3.new(6.4, 0.4, T + 0.3), CFrame.new(0, 7.6, frontZ), C.trim, Enum.Material.Wood)
	-- offene Tür (nach innen geklappt) und Fußmatte
	block("Door", Vector3.new(0.25, 7.2, 3), CFrame.new(-2.8, 3.8 + FLOOR / 2, frontZ + 1.7), C.trim, Enum.Material.WoodPlanks)
	block("DoorMat", Vector3.new(4, 0.05, 2), CFrame.new(0, FLOOR - 0.05, -D / 2 - 1.2), Color3.fromRGB(95, 60, 40), Enum.Material.Fabric, { CanCollide = false })

	-- Satteldach: zwei schräge Flächen, Firstbalken, Giebel aus Keilen
	local half = D / 2 + 1.2
	local slope = math.atan(RIDGE / half)
	local length = math.sqrt(half * half + RIDGE * RIDGE)
	for _, side in { -1, 1 } do
		block("Roof", Vector3.new(W + 1.6, 0.4, length), CFrame.new(0, H + RIDGE / 2, side * half / 2) * CFrame.Angles(side * slope, 0, 0), C.roof, Enum.Material.WoodPlanks)
	end
	block("RidgeBeam", Vector3.new(W + 1.8, 0.5, 0.5), CFrame.new(0, H + RIDGE + 0.15, 0), C.log, Enum.Material.Wood)
	for _, x in { -W / 2 + T / 2, W / 2 - T / 2 } do
		for _, side in { -1, 1 } do
			Parts.new("WedgePart", {
				Name = "Gable",
				Size = Vector3.new(T, RIDGE, D / 2),
				CFrame = BASE * CFrame.new(x, H + RIDGE / 2, side * D / 4) * CFrame.Angles(0, side > 0 and math.pi or 0, 0),
				Color = C.wall,
				Material = Enum.Material.WoodPlanks,
				Parent = model,
			})
		end
	end
	-- Schild über der Tür: bemaltes Holzbrett mit warmem Licht
	local sign = block("ShopSign", Vector3.new(7.5, 1.7, 0.3), CFrame.new(0, 8.4, -D / 2 - 0.25), C.trim, Enum.Material.Wood)
	local gui = Parts.surfaceGui(sign, Enum.NormalId.Front, false)
	gui.PixelsPerStud = 50
	Parts.text(gui, { Text = "SHOP", Font = Enum.Font.SpecialElite, TextColor3 = C.paper, Size = UDim2.fromScale(0.9, 0.84), Position = UDim2.fromScale(0.05, 0.08) })
	local signLamp = block("SignLamp", Vector3.new(0.6, 0.35, 0.6), CFrame.new(0, 9.55, -D / 2 - 0.9), C.warm, Enum.Material.Neon, { CanCollide = false })
	Parts.light("SpotLight", signLamp, { Face = Enum.NormalId.Bottom, Angle = 80, Range = 9, Brightness = 1.2, Color = C.warm })
	for _, x in { -W / 2 + 0.4, W / 2 - 0.4 } do
		local lantern = block("PorchLantern", Vector3.new(0.5, 0.8, 0.5), CFrame.new(x, 6.2, -D / 2 - 3.25), C.warm, Enum.Material.Neon, { CanCollide = false })
		Parts.light("PointLight", lantern, { Range = 11, Brightness = 0.9, Color = C.warm })
	end
	-- Innen: zwei Hängelampen und ein Teppich
	for _, x in { -5, 5 } do
		block("LampCord", Vector3.new(0.08, 1.6, 0.08), CFrame.new(x, H + 0.8, 0), Color3.fromRGB(25, 25, 25), Enum.Material.SmoothPlastic, { CanCollide = false })
		local bulb = block("LampShade", Vector3.new(1.4, 0.6, 1.4), CFrame.new(x, H - 0.3, 0), C.trim, Enum.Material.Metal, { CanCollide = false })
		local light = block("Bulb", Vector3.new(0.5, 0.5, 0.5), CFrame.new(x, H - 0.7, 0), C.warm, Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
		Parts.light("PointLight", light, { Range = 18, Brightness = 1.1, Color = C.warm, Shadows = x < 0 })
		bulb.CastShadow = false
	end
	block("Rug", Vector3.new(8, 0.05, 6), CFrame.new(0, FLOOR + 0.02, -1), Color3.fromRGB(120, 45, 40), Enum.Material.Fabric, { CanCollide = false })
end

------------------------------------------------------------------ Schaufenster
-- Skins gibt es nur im Menü zu sehen: im Schaufenster steht eine Holztafel, die den Katalog
-- öffnet (Attribut ShopTab = Reiter im Menü)
local function easel(parent, block, localPosition, title, line, tab)
	local base = CFrame.new(localPosition)
	for _, x in { -0.8, 0.8 } do
		block("EaselLeg", Vector3.new(0.15, 3.6, 0.15), base * CFrame.new(x, 1.75, 0.3) * CFrame.Angles(math.rad(10), 0, 0), C.log, Enum.Material.Wood)
	end
	block("EaselBack", Vector3.new(0.15, 3.4, 0.15), base * CFrame.new(0, 1.6, 0.95) * CFrame.Angles(math.rad(-18), 0, 0), C.log, Enum.Material.Wood)
	-- Tafel lehnt nach hinten, Schrift zeigt nach draußen (Westen)
	local board = block("EaselBoard", Vector3.new(2.6, 1.8, 0.12), base * CFrame.new(0, 3, 0.35) * CFrame.Angles(math.rad(10), 0, 0), Color3.fromRGB(32, 30, 28), Enum.Material.Slate)
	local gui = Parts.surfaceGui(board, Enum.NormalId.Front, false)
	gui.PixelsPerStud = 90
	Parts.text(gui, { Text = title, Font = Enum.Font.SpecialElite, TextColor3 = C.paper, Size = UDim2.fromScale(0.9, 0.38), Position = UDim2.fromScale(0.05, 0.1) })
	Parts.text(gui, { Text = line, Font = Enum.Font.SpecialElite, TextColor3 = Color3.fromRGB(200, 190, 170), Size = UDim2.fromScale(0.9, 0.3), Position = UDim2.fromScale(0.05, 0.56) })
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open catalog"
	prompt.ObjectText = title
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt:SetAttribute("ShopTab", tab)
	CollectionService:AddTag(prompt, "ShopHutPrompt")
	prompt.Parent = board
end

-- gemütliche Ecke: Sessel und Topfpflanze
local function cozyCorner(block, localPosition)
	local base = CFrame.new(localPosition) * CFrame.Angles(0, math.rad(35), 0)
	local fabric = Color3.fromRGB(110, 46, 40)
	block("ChairSeat", Vector3.new(2.4, 0.7, 2.2), base * CFrame.new(0, 0.95, 0), fabric, Enum.Material.Fabric)
	block("ChairBack", Vector3.new(2.4, 2, 0.5), base * CFrame.new(0, 2, 0.9), fabric, Enum.Material.Fabric)
	for _, x in { -1.3, 1.3 } do
		block("ChairArm", Vector3.new(0.4, 1.1, 2.2), base * CFrame.new(x, 1.4, 0), fabric, Enum.Material.Fabric)
	end
	block("ChairBase", Vector3.new(2.2, 0.6, 2), base * CFrame.new(0, 0.3, 0), C.trim, Enum.Material.Wood)
	local pot = base * CFrame.new(2.6, 0, 0.4)
	block("PlantPot", Vector3.new(0.9, 1, 0.9), pot * CFrame.new(0, 0.5, 0), Color3.fromRGB(140, 80, 55), Enum.Material.Concrete)
	for i = 0, 4 do
		block("PlantLeaf", Vector3.new(0.25, 1.6, 0.7), pot * CFrame.Angles(0, i * math.rad(72), math.rad(25)) * CFrame.new(0.35, 1.7, 0), Color3.fromRGB(60, 110, 55), Enum.Material.Grass, { CanCollide = false })
	end
end

------------------------------------------------------------------ Kleidung
local function clothingTemplate(id)
	local folder = ReplicatedStorage:FindFirstChild("Shop") and ReplicatedStorage.Shop:FindFirstChild("Kleidung")
	return folder and folder:FindFirstChild(id)
end

local function showItem(parent, id, cframe, maxSize)
	local template = clothingTemplate(id)
	if not template then
		warn("Shop-Hütte: Kleidung fehlt: " .. id)
		return nil
	end
	local item = template:Clone()
	item.Anchored = true
	item.CanCollide = false
	local largest = math.max(item.Size.X, item.Size.Y, item.Size.Z)
	if largest > maxSize then
		item.Size = item.Size * (maxSize / largest)
	end
	item.CFrame = cframe
	item.Parent = parent
	return item
end

-- Kleiderständer an der rechten Wand: Stange, Bügel, Jacken hängen daran
local function buildRack(parent, block)
	local jackets = {}
	for _, item in ShopCatalog.CLOTHING do
		if item.slot == "Jacket" then
			table.insert(jackets, item)
		end
	end
	local rackX = W / 2 - 2.2
	local z1, z2 = -5, 4
	for _, z in { z1 - 0.4, z2 + 0.4 } do
		block("RackStand", Vector3.new(0.2, 5.6, 0.2), CFrame.new(rackX, FLOOR + 2.8, z), C.metal, Enum.Material.Metal)
		block("RackFoot", Vector3.new(1.6, 0.15, 0.3), CFrame.new(rackX, FLOOR + 0.08, z), C.metal, Enum.Material.Metal)
	end
	block("RackRod", Vector3.new(0.12, 0.12, z2 - z1 + 1), CFrame.new(rackX, FLOOR + 5.5, (z1 + z2) / 2), Color3.fromRGB(160, 160, 165), Enum.Material.Metal)
	-- die Jacken zeigen zur Raummitte (lokal -X)
	local facing = -BASE.RightVector
	for index, item in jackets do
		local z = z1 + (index - 1) * (z2 - z1) / math.max(#jackets - 1, 1)
		local hook = BASE * CFrame.new(rackX, FLOOR + 5.5, z)
		-- Bügel: Haken, zwei schräge Arme, Querstange
		block("HangerHook", Vector3.new(0.05, 0.3, 0.05), CFrame.new(rackX, FLOOR + 5.38, z), C.metal, Enum.Material.Metal, { CanCollide = false })
		for _, side in { -1, 1 } do
			block("HangerArm", Vector3.new(0.06, 0.06, 0.95), CFrame.new(rackX, FLOOR + 5.05, z + side * 0.42) * CFrame.Angles(side * math.rad(25), 0, 0), Color3.fromRGB(150, 110, 70), Enum.Material.Wood, { CanCollide = false })
		end
		block("HangerBar", Vector3.new(0.05, 0.05, 1.7), CFrame.new(rackX, FLOOR + 4.85, z), Color3.fromRGB(150, 110, 70), Enum.Material.Wood, { CanCollide = false })
		local jacket = clothingTemplate(item.id)
		if jacket then
			local height = 2.6
			local scale = height / jacket.Size.Y
			local shown = showItem(parent, item.id, CFrame.new(), 99)
			shown.Size = jacket.Size * scale
			-- Jacke schmal zur Stange gedreht: Vorderseite zeigt in den Raum
			local top = hook.Position - Vector3.new(0, 0.55, 0)
			shown.CFrame = CFrame.lookAt(top - Vector3.new(0, shown.Size.Y / 2, 0), top - Vector3.new(0, shown.Size.Y / 2, 0) + facing)
			tryOnPrompt(shown, item.id, item.title)
		end
		priceTag(parent, (BASE * CFrame.new(rackX - 0.9, FLOOR + 1.6, z)).Position, facing, item.title, priceText(item))
	end
	local header = block("RackSign", Vector3.new(0.15, 0.9, 4.4), CFrame.new(W / 2 - T - 0.05, 7.4, (z1 + z2) / 2), C.trim, Enum.Material.Wood)
	Parts.text(Parts.surfaceGui(header, Enum.NormalId.Left, false), { Text = "JACKETS", Font = Enum.Font.SpecialElite, TextColor3 = C.paper, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
end

-- Wandregal an der linken Wand: zwei Böden mit den Accessoires
local function buildShelf(parent, block)
	local items = {}
	for _, item in ShopCatalog.CLOTHING do
		if item.slot ~= "Jacket" then
			table.insert(items, item)
		end
	end
	local shelfX = -W / 2 + T + 0.7
	local z1, z2 = -4.2, 3.6
	block("ShelfBack", Vector3.new(0.15, 4.6, z2 - z1 + 1.6), CFrame.new(-W / 2 + T + 0.08, FLOOR + 3.9, (z1 + z2) / 2), C.trim, Enum.Material.WoodPlanks)
	local facing = BASE.RightVector -- in den Raum (lokal +X)
	for level = 0, 1 do
		local y = FLOOR + 2.2 + level * 2.2
		block("ShelfBoard", Vector3.new(1.4, 0.15, z2 - z1 + 1.6), CFrame.new(shelfX, y, (z1 + z2) / 2), C.log, Enum.Material.Wood)
		for i = 1, 4 do
			local item = items[level * 4 + i]
			if item then
				local z = z1 + (i - 1) * (z2 - z1) / 3
				local spot = BASE * CFrame.new(shelfX, y + 0.08, z)
				local shown = showItem(parent, item.id, CFrame.new(), 1.3)
				if shown then
					local pos = spot.Position + Vector3.new(0, shown.Size.Y / 2, 0)
					shown.CFrame = CFrame.lookAt(pos, pos + facing)
					tryOnPrompt(shown, item.id, item.title)
				end
				priceTag(parent, (BASE * CFrame.new(shelfX + 0.72, y - 0.32, z)).Position, facing, item.title, priceText(item))
			end
		end
	end
	local header = block("ShelfSign", Vector3.new(0.15, 0.9, 5), CFrame.new(-W / 2 + T + 0.05, 7.4, (z1 + z2) / 2), C.trim, Enum.Material.Wood)
	Parts.text(Parts.surfaceGui(header, Enum.NormalId.Right, false), { Text = "HATS & GEAR", Font = Enum.Font.SpecialElite, TextColor3 = C.paper, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
end

-- Verkäufer hinter der Theke (wie im Kiosk)
local function buildCounter(parent, block)
	local cx, cz = 3.5, D / 2 - 3.2
	block("Counter", Vector3.new(7, 3.4, 1.8), CFrame.new(cx, FLOOR + 1.7, cz), C.log, Enum.Material.WoodPlanks)
	block("CounterTop", Vector3.new(7.4, 0.2, 2.2), CFrame.new(cx, FLOOR + 3.5, cz), C.trim, Enum.Material.Wood)
	block("Register", Vector3.new(1.4, 0.9, 1), CFrame.new(cx + 2, FLOOR + 4.05, cz), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	block("Ledger", Vector3.new(1.2, 0.12, 0.9), CFrame.new(cx - 1.2, FLOOR + 3.66, cz - 0.2) * CFrame.Angles(0, math.rad(12), 0), C.paper, Enum.Material.SmoothPlastic)
	local ok, npc = pcall(function()
		local description = Instance.new("HumanoidDescription")
		local skin = Color3.fromRGB(196, 150, 118)
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = Color3.fromRGB(90, 60, 45)
		description.LeftLegColor = Color3.fromRGB(45, 40, 38)
		description.RightLegColor = Color3.fromRGB(45, 40, 38)
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("Verkäufer konnte nicht erstellt werden:", npc)
		return
	end
	npc.Name = "Tailor"
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	root.Anchored = true
	local feet = BASE * CFrame.new(cx, FLOOR, cz + 1.8) * CFrame.Angles(0, 0, 0)
	npc:PivotTo(feet * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0))
	npc.Parent = parent
	pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://507766388"
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play()
	end)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Browse the shop"
	prompt.ObjectText = "Tailor"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	CollectionService:AddTag(prompt, "ShopHutPrompt")
	prompt.Parent = root
end

-- Spiegel an der linken Wand vorne (öffnet den Shop zum Anprobieren)
local function buildMirror(parent, block)
	local z = -6.4
	block("MirrorFrame", Vector3.new(0.2, 6.2, 2.6), CFrame.new(-W / 2 + T + 0.1, FLOOR + 3.4, z), C.log, Enum.Material.Wood)
	local glass = block("Mirror", Vector3.new(0.1, 5.8, 2.2), CFrame.new(-W / 2 + T + 0.22, FLOOR + 3.4, z), Color3.fromRGB(200, 210, 215), Enum.Material.Glass, { Reflectance = 0.6, Transparency = 0.1 })
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Try things on"
	prompt.ObjectText = "Mirror"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	CollectionService:AddTag(prompt, "ShopHutPrompt")
	prompt.Parent = glass
end

------------------------------------------------------------------ Sportwagen neben der Hütte
local function buildCarSpot(parent)
	local center = Vector3.new(60, Y, 31) -- südlich der Hütte
	local stage = Parts.new("Part", { Name = "CarStage", Size = Vector3.new(17, 0.35, 11), CFrame = CFrame.new(center + Vector3.new(0, 0.175, 0)), Color = Color3.fromRGB(88, 84, 80), Material = Enum.Material.Cobblestone, Parent = parent })
	Parts.new("Part", { Name = "CarStageEdge", Size = Vector3.new(17.4, 0.3, 11.4), CFrame = CFrame.new(center + Vector3.new(0, 0.1, 0)), Color = C.log, Material = Enum.Material.Wood, Parent = parent })
	SportsCar.build(parent, CFrame.new(center + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, math.rad(90), 0)) -- gerade, längs auf dem Podest
	-- zwei Laternenmasten mit Spot aufs Auto
	for _, offset in { Vector3.new(-9.5, 0, -6.5), Vector3.new(9.5, 0, 6.5) } do
		local foot = center + offset
		Parts.new("Part", { Name = "SpotPole", Size = Vector3.new(0.35, 7, 0.35), CFrame = CFrame.new(foot + Vector3.new(0, 3.5, 0)), Color = C.log, Material = Enum.Material.Wood, Parent = parent })
		local lamp = Parts.new("Part", { Name = "CarSpot", Size = Vector3.new(0.7, 0.5, 0.7), CFrame = CFrame.lookAt(foot + Vector3.new(0, 7, 0), center + Vector3.new(0, 0.5, 0)), Color = C.warm, Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
		Parts.light("SpotLight", lamp, { Face = Enum.NormalId.Front, Angle = 55, Range = 18, Brightness = 1.6, Color = C.warm })
	end
	-- Tafel davor
	local signPos = center + Vector3.new(-9.2, 0, 0)
	Parts.new("Part", { Name = "SignPost", Size = Vector3.new(0.3, 2.4, 0.3), CFrame = CFrame.new(signPos + Vector3.new(0, 1.2, 0)), Color = C.log, Material = Enum.Material.Wood, Parent = parent })
	local board = Parts.new("Part", { Name = "CarSign", Size = Vector3.new(0.15, 1.3, 3), CFrame = CFrame.new(signPos + Vector3.new(0, 2.3, 0)), Color = C.trim, Material = Enum.Material.Wood, Parent = parent })
	local gui = Parts.surfaceGui(board, Enum.NormalId.Left, false)
	gui.PixelsPerStud = 80
	local car = ShopCatalog.SPORTS_CAR
	Parts.text(gui, { Text = "SPORTS CAR", Font = Enum.Font.SpecialElite, TextColor3 = C.paper, Size = UDim2.fromScale(0.92, 0.5), Position = UDim2.fromScale(0.04, 0.05) })
	Parts.text(gui, { Text = priceText(car), Font = Enum.Font.GothamMedium, TextColor3 = C.paper, Size = UDim2.fromScale(0.92, 0.32), Position = UDim2.fromScale(0.04, 0.6) })
	local prompt = tryOnPrompt(board, car.id, car.title)
	prompt.ActionText = "Look closer"
end

-- Trittsteine vom Weg am Lagerplatz zur Veranda
local function buildPath(parent)
	local from, to = Vector3.new(36, Y, 20), (BASE * CFrame.new(0, 0, -D / 2 - 5.5)).Position
	local steps = 7
	for i = 0, steps do
		local p = from:Lerp(to, i / steps)
		Parts.new("Part", { Name = "SteppingStone", Size = Vector3.new(0.18, 1.6 + (i % 2) * 0.3, 1.6), CFrame = CFrame.new(p.X, Y + 0.05, p.Z) * CFrame.Angles(0, i * 0.7, math.rad(90)), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(130, 126, 118), Material = Enum.Material.Slate, CanCollide = false, Parent = parent })
	end
end

function ShopHut.build(parent)
	local started = os.clock()
	local model = Instance.new("Model")
	model.Name = "ShopHut"
	model.Parent = parent
	local block = Parts.builder(model, BASE)

	buildCabin(model, block)
	buildRack(model, block)
	buildShelf(model, block)
	buildMirror(model, block)
	buildCounter(model, block)
	buildCarSpot(model)
	buildPath(model)

	-- Schaufenster: Tafeln zum Katalog (Skins nur im Menü), gemütliche Ecke hinten links
	easel(model, block, Vector3.new(-6.2, FLOOR, -D / 2 + 2.2), "SUITS & SKINS", "See them in the catalog", "Skins")
	easel(model, block, Vector3.new(6.2, FLOOR, -D / 2 + 2.2), "CLOTHING SETS", "Buy together, save coins", "Bundles")
	cozyCorner(block, Vector3.new(-6.8, FLOOR, D / 2 - 2.4))

	Parts.optimize(model)
	model:SetAttribute("Ready", true)
	local count = 0
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			count += 1
		end
	end
	print(string.format("Shop-Hütte: fertig in %.1f s (%d Teile)", os.clock() - started, count))
end

return ShopHut
