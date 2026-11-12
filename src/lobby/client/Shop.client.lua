-- Shop und Kiosk in der Lobby (ein Fenster, zwei Sortimente):
--   Shop  (Shop-Hütte, Knopf unten links): Bundles, Suits & Skins, Clothing, Passes, Coins
--   Kiosk (Verkäufer am Kiosk):            Snacks und Extras (Wiederbelebungen)
-- Rechts ist die Anprobe: Wer etwas auswählt, sieht es sofort an der eigenen Figur (Kleidung
-- und Anzüge sammeln sich, bis man „Reset“ drückt). Mit der Maus kann man die Figur drehen.
-- Jedes Teil hat zwei Preise zur Wahl: Münzen oder Robux.
-- Stil wie der Rest der Lobby: warmes Dunkelbraun, Schreibmaschinenschrift für Titel, ruhig.

-- Liegen im selben Studio-Ort auch die Skripte von Level 1, läuft nur das Level
if game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Level") then
	return
end

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local RealFigure = require(Shared:WaitForChild("RealFigure"))
local Skins = require(Shared:WaitForChild("Skins"))
local SportsCar = require(Shared:WaitForChild("SportsCar"))
local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")

local player = Players.LocalPlayer

------------------------------------------------------------------ Gestaltung (Tokens)
local T = {
	panel = Color3.fromRGB(26, 22, 20),
	surface = Color3.fromRGB(35, 30, 27),
	surfaceHover = Color3.fromRGB(44, 38, 34),
	well = Color3.fromRGB(46, 40, 36), -- Hintergrund der Vorschaubilder
	line = Color3.fromRGB(255, 214, 150),
	text = Color3.fromRGB(240, 228, 210),
	muted = Color3.fromRGB(168, 152, 134),
	accent = Color3.fromRGB(214, 166, 92),
	onAccent = Color3.fromRGB(32, 24, 16),
	robux = Color3.fromRGB(64, 128, 90),
	good = Color3.fromRGB(150, 190, 130),
	bad = Color3.fromRGB(226, 128, 112),
	coin = Color3.fromRGB(230, 184, 84),
	coinEdge = Color3.fromRGB(150, 106, 38),
	glowTop = Color3.fromRGB(92, 72, 54), -- warmes Licht hinter den 3D-Bildern
	glowBottom = Color3.fromRGB(30, 26, 23),
	titleFont = Enum.Font.SpecialElite,
	bodyFont = Enum.Font.GothamMedium,
	boldFont = Enum.Font.GothamBold,
	radius = 8,
	touch = 48, -- Mindesthöhe für alles, was man antippt
}

local function create(className, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or T.radius) })
end

local function hairline(transparency)
	return create("UIStroke", { Color = T.line, Thickness = 1, Transparency = transparency or 0.82, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props)
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or T.text
	props.Font = props.Font or T.bodyFont
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

local function money(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

------------------------------------------------------------------ Spielerdaten
local state = { coins = 0, owned = {}, items = {}, equipped = {} }

local function readData()
	state.coins = player:GetAttribute("Coins") or 0
	local raw = player:GetAttribute("ShopData")
	if raw then
		local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(data) == "table" then
			state.owned = data.Owned or {}
			state.items = data.Items or {}
			state.equipped = data.Equipped or {}
		end
	end
end
readData()

------------------------------------------------------------------ Sortiment
-- entry: id, kind, tab, title, description, coins, robux, productId, passId, slot, rarity,
--        preview = { kind = ... }, contents (Liste von Titeln), once (einmal kaufbar)
local entries = {}
local byId = {}
local function add(entry)
	table.insert(entries, entry)
	byId[entry.id] = entry
	return entry
end

local function titlesOf(ids)
	local names = {}
	for _, id in ids or {} do
		local found = ShopCatalog.find(id)
		table.insert(names, found and found.title or id)
	end
	return names
end

-- Shop: Bundles
local starter = ShopCatalog.STARTER_PACK
add({ id = "StarterPack", kind = "Starter", tab = "Bundles", title = starter.title, description = starter.description, robux = starter.robux, firstRobux = starter.firstTimeRobux, productId = starter.productId, firstProductId = starter.firstTimeProductId, preview = { kind = "item", item = "Backpack" }, note = "First purchase only 50 R$", once = true })
for _, pack in ShopCatalog.PACKS do
	local previews = { GoldenPack = { kind = "family" }, SarpVip = { kind = "sarp", skin = "GildedHorror" }, Everything = { kind = "everything" } }
	add({ id = pack.id, kind = "Pack", tab = "Bundles", title = pack.title, description = pack.description, robux = pack.robux, productId = pack.productId, preview = previews[pack.id], contents = titlesOf(pack.grants), note = pack.tag, once = true })
end
for _, outfit in ShopCatalog.OUTFITS do
	add({ id = outfit.id, kind = "Outfit", tab = "Bundles", title = outfit.title, description = outfit.description, coins = outfit.coins, robux = outfit.robux, productId = outfit.productId, preview = { kind = "fitting" }, tryItems = outfit.items, contents = titlesOf(outfit.items), once = true })
end
-- Shop: Anzüge und Skins
for _, skin in ShopCatalog.SKINS do
	local preview = skin.slot == "Sarp" and { kind = "sarp", skin = skin.id } or { kind = "fitting" }
	add({ id = skin.id, kind = "Skin", tab = "Skins", title = skin.title, description = skin.description, coins = skin.coins, robux = skin.robux, productId = skin.productId, pack = skin.pack, slot = skin.slot, rarity = skin.rarity, preview = preview, trySuit = skin.slot == "Player" and skin.id or nil, once = true })
end
local car = ShopCatalog.SPORTS_CAR
add({ id = car.id, kind = "Car", tab = "Skins", title = car.title, description = car.description, coins = car.coins, robux = car.robux, productId = car.productId, rarity = car.rarity, preview = { kind = "car" }, once = true })
-- Shop: Kleidung
for _, item in ShopCatalog.CLOTHING do
	add({ id = item.id, kind = "Clothing", tab = "Clothing", title = item.title, description = "Clothing for your character. Wearing it in the game comes soon.", coins = item.coins, robux = item.robux, productId = item.productId, rarity = item.rarity, slot = item.slot, preview = { kind = "fitting" }, tryItems = { item.id }, once = true })
end
-- Shop: Pässe und Münzen
for _, pass in ShopCatalog.GAMEPASSES do
	add({ id = pass.id, kind = "Pass", tab = "Passes", title = pass.title, description = pass.description, robux = pass.robux, passId = pass.passId, preview = { kind = "pass", pass = pass.id }, once = true })
end
for _, pack in ShopCatalog.COIN_PACKS do
	add({ id = pack.id, kind = "CoinPack", tab = "Coins", title = money(pack.coins) .. " coins", description = "Spend coins on suits, clothing and snacks.", robux = pack.robux, productId = pack.productId, preview = { kind = "coins", amount = pack.coins }, note = pack.tag and (pack.tag:sub(1, 1) .. pack.tag:sub(2):lower()) or nil })
end
local boost = ShopCatalog.COIN_BOOST
add({ id = boost.id, kind = "Boost", tab = "Coins", title = boost.title, description = boost.description, robux = boost.robux, productId = boost.productId, preview = { kind = "coins", amount = 200, double = true } })
-- Kiosk: Snacks und Extras
for _, item in ShopCatalog.ITEMS do
	add({ id = item.id, kind = "Item", tab = "Snacks", title = item.title, description = item.description .. "\nYou can use up to 3 snacks per round.", coins = item.coins, robux = item.robux, productId = item.productId, preview = { kind = "snack", item = item.id } })
end
for index, product in Config.PRODUCTS do
	add({ id = "Product" .. index, kind = "Product", tab = "Extras", title = product.title, description = product.description, robux = product.robux, productId = product.id, preview = { kind = "revive", amount = product.amount, field = product.field } })
end

local SHOP_TABS = { { "Bundles", "Bundles" }, { "Skins", "Suits & Skins" }, { "Clothing", "Clothing" }, { "Passes", "Passes" }, { "Coins", "Coins" } }
local KIOSK_TABS = { { "Snacks", "Snacks" }, { "Extras", "Extras" } }

local function isOwned(entry)
	if not entry.once then
		return false
	end
	if state.owned[entry.id] then
		return true
	end
	if entry.kind == "Outfit" then
		for _, id in entry.tryItems do
			if not state.owned[id] then
				return false
			end
		end
		return true
	end
	return false
end

------------------------------------------------------------------ 3D-Modelle für Vorschau und Karten
local cache = {}
local buildArea = CFrame.new(0, 3000, 0)

-- Vorschaufenster zeigen keine SurfaceAppearance und Glas sieht silbern aus: aufbereiten
local function fitForViewport(model)
	for _, item in model:GetDescendants() do
		if item:IsA("ParticleEmitter") or item:IsA("Light") or item:IsA("ProximityPrompt") then
			item:Destroy()
		elseif item:IsA("SurfaceAppearance") then
			item:Destroy() -- Farbtextur hat buildFigure schon an die MeshPart gesetzt
		elseif item:IsA("BasePart") and item.Material == Enum.Material.Glass then
			item.Material = Enum.Material.SmoothPlastic
			item.Reflectance = 0.15
		end
	end
	return model
end

local function buildFigure(spec, skinId, options)
	local container = ReplicatedStorage:FindFirstChild(spec.folder)
	local template = container and container:FindFirstChild(spec.name)
	if not template then
		return nil
	end
	local model = RealFigure.prepare(template, { anchor = true, height = spec.height })
	local texture = ShopCatalog.FIGURE_TEXTURES[spec.name]
	if texture then
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") and part:FindFirstChildOfClass("SurfaceAppearance") then
				part.TextureID = texture
			end
		end
	end
	model:PivotTo(buildArea)
	model.Parent = workspace -- der Skin misst die Körperform mit Strahlen
	if skinId then
		Skins.apply(model, skinId, options)
	end
	model.Parent = nil
	model:PivotTo(CFrame.new())
	return fitForViewport(model)
end

local function clothingTemplate(id)
	local folder = ReplicatedStorage:FindFirstChild("Shop") and ReplicatedStorage.Shop:FindFirstChild("Kleidung")
	return folder and folder:FindFirstChild(id)
end

-- ein Kleidungsstück an die Figur hängen (ungefähr passend, nur für die Anprobe)
local function wear(model, id)
	local item = ShopCatalog.find(id)
	local template = clothingTemplate(id)
	local root = model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head")
	if not (item and template and root and head) then
		return
	end
	local rot = root.CFrame.Rotation
	local headTop = head.Position.Y + head.Size.Y * 0.5
	local headBottom = head.Position.Y - head.Size.Y * 0.42
	local lower = model:FindFirstChild("LowerTorso")
	local hip = lower and (lower.Position.Y - lower.Size.Y * 0.2) or headBottom - 2
	local front = root.CFrame.LookVector -- Blickrichtung der Figur
	local function place(name, size, cf)
		local part = template:Clone()
		part.Name = "Try_" .. name
		part.Anchored = true
		part.CanCollide = false
		part.Size = size
		part.CFrame = cf
		part.Parent = model
		return part
	end
	local function scaledTo(axis, value)
		local s = template.Size
		local k = value / s[axis]
		return s * k
	end
	local headWidth = math.min(head.Size.X, head.Size.Z) * 1.1
	if item.slot == "Head" then
		local size = scaledTo("X", headWidth * (id == "Headlamp" and 1.08 or 1.18))
		local y = id == "Headlamp" and (head.Position.Y + head.Size.Y * 0.12) or (headTop - size.Y * 0.42)
		place(id, size, CFrame.new(head.Position.X, y, head.Position.Z) * rot)
	elseif item.slot == "Face" then
		local size = scaledTo("X", headWidth * 1.02)
		local pos = head.Position + Vector3.new(0, head.Size.Y * 0.08, 0) + front * (head.Size.Z * 0.36)
		place(id, size, CFrame.new(pos) * rot)
	elseif item.slot == "Neck" then
		local size = scaledTo("X", headWidth * 1.8)
		local pos = Vector3.new(head.Position.X, headBottom - size.Y * 0.35, head.Position.Z) + front * 0.1
		place(id, size, CFrame.new(pos) * rot)
	elseif item.slot == "Back" then
		local size = scaledTo("Y", (headBottom - hip) * 0.85)
		local torso = model:FindFirstChild("UpperTorso")
		local center = torso and torso.Position or root.Position
		local pos = Vector3.new(center.X, (headBottom + hip) / 2, center.Z) - front * (0.35 + size.Z * 0.45)
		place(id, size, CFrame.new(pos) * rot)
	elseif item.slot == "Jacket" then
		local size = scaledTo("Y", (headBottom - hip) * 1.18)
		local torso = model:FindFirstChild("UpperTorso")
		local center = torso and torso.Position or root.Position
		place(id, size, CFrame.new(center.X, (headBottom + hip) / 2 - size.Y * 0.04, center.Z) * rot)
	elseif item.slot == "Hands" then
		for _, side in { "Left", "Right" } do
			local hand = model:FindFirstChild(side .. "Hand")
			if hand then
				local size = scaledTo("Y", hand.Size.Y * 1.15)
				place(id .. side, size, CFrame.new(hand.Position) * rot)
			end
		end
	elseif item.slot == "Feet" then
		local left, right = model:FindFirstChild("LeftFoot"), model:FindFirstChild("RightFoot")
		if left and right then
			local span = (left.Position - right.Position).Magnitude + math.max(left.Size.X, right.Size.X)
			local size = scaledTo("X", span * 1.05)
			local bottom = math.min(left.Position.Y - left.Size.Y / 2, right.Position.Y - right.Size.Y / 2)
			local mid = (left.Position + right.Position) / 2
			place(id, size, CFrame.new(mid.X, bottom + size.Y / 2, mid.Z) * rot)
		end
	end
end

-- kleine gebaute Modelle für Snacks, Pässe, Münzen
local function block(parent, size, cf, color, material, shape)
	return create("Part", { Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Shape = shape or Enum.PartType.Block, Anchored = true, CanCollide = false, Parent = parent })
end

local function coinStack(parent, amount, double)
	local stacks = amount >= 5000 and 4 or amount >= 1500 and 3 or amount >= 500 and 2 or 1
	for s = 1, stacks do
		local height = 3 + s * 2
		for i = 0, height - 1 do
			local x = (s - (stacks + 1) / 2) * 1.25
			block(parent, Vector3.new(0.2, 1.1, 1.1), CFrame.new(x, i * 0.22, (s % 2) * 0.3) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(214, 170, 76), Enum.Material.Metal, Enum.PartType.Cylinder)
		end
	end
	if double then
		block(parent, Vector3.new(0.2, 1.1, 1.1), CFrame.new(1.5, 0.6, -0.4) * CFrame.Angles(0, math.rad(70), math.rad(90)), Color3.fromRGB(230, 190, 90), Enum.Material.Metal, Enum.PartType.Cylinder)
	end
end

local SNACK_COLORS = { EnergyBar = Color3.fromRGB(190, 60, 44), Coffee = Color3.fromRGB(230, 225, 215), MintGum = Color3.fromRGB(90, 170, 140), GummyBears = Color3.fromRGB(230, 170, 60), XRayGlasses = Color3.fromRGB(40, 40, 46) }
local function snackModel(parent, id)
	local color = SNACK_COLORS[id] or T.accent
	if id == "EnergyBar" then
		block(parent, Vector3.new(3, 0.5, 1.2), CFrame.Angles(0, math.rad(20), math.rad(8)), color)
		block(parent, Vector3.new(1, 0.52, 1.22), CFrame.Angles(0, math.rad(20), math.rad(8)), Color3.fromRGB(240, 220, 170))
	elseif id == "Coffee" then
		block(parent, Vector3.new(2, 1.4, 1.4), CFrame.Angles(0, 0, math.rad(90)), color, nil, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.2, 1.5, 1.5), CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 40, 30), nil, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.6, 1.42, 1.42), CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 100, 60), Enum.Material.Cardboard, Enum.PartType.Cylinder)
	elseif id == "MintGum" then
		block(parent, Vector3.new(2, 1.3, 0.5), CFrame.Angles(0, math.rad(-20), 0), color)
		block(parent, Vector3.new(2.02, 0.35, 0.52), CFrame.new(0, 0.3, 0) * CFrame.Angles(0, math.rad(-20), 0), Color3.fromRGB(235, 245, 240))
	elseif id == "GummyBears" then
		block(parent, Vector3.new(2, 2.4, 0.8), CFrame.new(), color, Enum.Material.Plastic)
		for i, c in { Color3.fromRGB(200, 40, 40), Color3.fromRGB(60, 160, 60), Color3.fromRGB(240, 200, 40) } do
			block(parent, Vector3.new(0.5, 0.5, 0.5), CFrame.new(-0.9 + i * 0.45, -1.35, -0.6), c, Enum.Material.Glass, Enum.PartType.Ball)
		end
	elseif id == "XRayGlasses" then
		for _, x in { -0.7, 0.7 } do
			block(parent, Vector3.new(0.12, 1, 1), CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(120, 230, 160), Enum.Material.Neon, Enum.PartType.Cylinder)
			block(parent, Vector3.new(0.1, 1.15, 1.15), CFrame.new(x, 0, 0.04) * CFrame.Angles(0, math.rad(90), 0), color, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		block(parent, Vector3.new(0.5, 0.12, 0.12), CFrame.new(0, 0.2, 0), color, Enum.Material.Metal)
	end
end

local function passModel(parent, id)
	if id == "ThreeHearts" then
		for i = -1, 1 do
			local base = CFrame.new(i * 1.4, 0, 0)
			local red = Color3.fromRGB(180, 40, 44)
			block(parent, Vector3.new(0.7, 0.7, 0.5), base * CFrame.new(-0.22, 0.15, 0), red, nil, Enum.PartType.Ball)
			block(parent, Vector3.new(0.7, 0.7, 0.5), base * CFrame.new(0.22, 0.15, 0), red, nil, Enum.PartType.Ball)
			block(parent, Vector3.new(0.62, 0.62, 0.45), base * CFrame.new(0, -0.15, 0) * CFrame.Angles(0, 0, math.rad(45)), red)
		end
	elseif id == "DoubleCoins" then
		coinStack(parent, 500, true)
	elseif id == "StrongFlashlight" then
		block(parent, Vector3.new(2.6, 0.5, 0.5), CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.6, 0.8, 0.8), CFrame.Angles(0, math.rad(25), 0) * CFrame.new(1.5, 0, 0), Color3.fromRGB(60, 60, 64), Enum.Material.Metal, Enum.PartType.Cylinder)
		block(parent, Vector3.new(0.1, 0.7, 0.7), CFrame.Angles(0, math.rad(25), 0) * CFrame.new(1.82, 0, 0), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif id == "Supervision" then
		block(parent, Vector3.new(2.4, 1.4, 0.6), CFrame.new(), Color3.fromRGB(235, 230, 220), nil, Enum.PartType.Ball)
		block(parent, Vector3.new(0.9, 0.9, 0.3), CFrame.new(0, 0, -0.25), Color3.fromRGB(110, 170, 210), nil, Enum.PartType.Ball)
		block(parent, Vector3.new(0.4, 0.4, 0.2), CFrame.new(0, 0, -0.38), Color3.fromRGB(20, 20, 24), nil, Enum.PartType.Ball)
	elseif id == "VipCar" then
		SportsCar.build(parent, CFrame.new(), { paint = Color3.fromRGB(120, 24, 30) })
	end
end

local function reviveModel(parent, amount)
	for i = 1, math.min(amount, 3) do
		local base = CFrame.new((i - (math.min(amount, 3) + 1) / 2) * 1.3, 0, 0)
		block(parent, Vector3.new(0.4, 1.4, 0.4), base, Color3.fromRGB(230, 225, 215))
		block(parent, Vector3.new(1.2, 0.4, 0.4), base, Color3.fromRGB(230, 225, 215))
		block(parent, Vector3.new(0.42, 1.42, 0.42), base, Color3.fromRGB(190, 50, 46), Enum.Material.Neon)
	end
end

-- Anprobe: eigene Figur mit Anzug und Kleidung
local fitting = { suit = nil, items = {} } -- items[slot] = id

local function fittingKey(suit, items)
	local list = {}
	for slot, id in items do
		table.insert(list, slot .. "=" .. id)
	end
	table.sort(list)
	return "fit:" .. tostring(suit) .. ":" .. table.concat(list, ",")
end

-- ohne Anzug: schlichtes dunkles Outfit (wie eine Schaufensterpuppe), damit Kleidung gut wirkt
-- und keine Texturflecken der Vorschau stören
local PLAIN = {
	UpperTorso = Color3.fromRGB(58, 54, 52), LowerTorso = Color3.fromRGB(40, 40, 46),
	LeftUpperArm = Color3.fromRGB(58, 54, 52), RightUpperArm = Color3.fromRGB(58, 54, 52),
	LeftLowerArm = Color3.fromRGB(58, 54, 52), RightLowerArm = Color3.fromRGB(58, 54, 52),
	LeftUpperLeg = Color3.fromRGB(40, 40, 46), RightUpperLeg = Color3.fromRGB(40, 40, 46),
	LeftLowerLeg = Color3.fromRGB(40, 40, 46), RightLowerLeg = Color3.fromRGB(40, 40, 46),
	LeftFoot = Color3.fromRGB(28, 26, 26), RightFoot = Color3.fromRGB(28, 26, 26),
}
local function plainOutfit(model)
	for name, color in PLAIN do
		local part = model:FindFirstChild(name)
		if part and part:IsA("MeshPart") then
			part.TextureID = ""
			part.Color = color
			part.Material = Enum.Material.Fabric
		end
	end
end

local function buildFitting(suit, items)
	local skin = suit and ShopCatalog.find(suit)
	local spec = skin and skin.preview or { folder = "Spieler", name = "Spieler1", height = 5.9 }
	local model = buildFigure(spec, suit, skin and skin.options)
	if model and not suit then
		plainOutfit(model)
	end
	if model then
		for _, id in items do
			wear(model, id)
		end
	end
	return model
end

local function previewFor(entry, tried)
	local preview = entry.preview
	if not preview then
		return nil
	end
	local key
	if preview.kind == "fitting" then
		key = fittingKey(tried.suit, tried.items)
	else
		key = preview.kind .. ":" .. tostring(preview.skin or preview.item or preview.pass or preview.amount or "") .. tostring(preview.double or "")
	end
	if cache[key] ~= nil then
		return cache[key] or nil
	end
	local ok, model = pcall(function()
		local holder = Instance.new("Model")
		if preview.kind == "fitting" then
			return buildFitting(tried.suit, tried.items)
		elseif preview.kind == "sarp" then
			local skin = ShopCatalog.find(preview.skin)
			return buildFigure(skin.preview, skin.id, skin.options)
		elseif preview.kind == "family" or preview.kind == "everything" then
			local x = -2.6
			for _, spec in ShopCatalog.FAMILY_GOLD do
				local figure = buildFigure(spec, "GoldSuit", spec.options)
				if figure then
					figure:PivotTo(CFrame.new(x, 0, 0))
					figure.Parent = holder
					x += 1.7
				end
			end
			if preview.kind == "everything" then
				local skin = ShopCatalog.find("GildedHorror")
				local sarp = buildFigure(skin.preview, skin.id, skin.options)
				if sarp then
					sarp:PivotTo(CFrame.new(x + 0.6, 0, 0.8))
					sarp.Parent = holder
				end
			end
		elseif preview.kind == "car" then
			SportsCar.build(holder, CFrame.new())
		elseif preview.kind == "item" then
			local template = clothingTemplate(preview.item)
			if template then
				local part = template:Clone()
				part.Anchored = true
				part.CFrame = CFrame.new()
				part.Parent = holder
			end
		elseif preview.kind == "snack" then
			snackModel(holder, preview.item)
		elseif preview.kind == "pass" then
			passModel(holder, preview.pass)
		elseif preview.kind == "coins" then
			coinStack(holder, preview.amount, preview.double)
		elseif preview.kind == "revive" then
			reviveModel(holder, preview.amount)
		end
		return fitForViewport(holder)
	end)
	if not ok then
		warn("Shop-Vorschau fehlgeschlagen:", model)
		model = nil
	end
	cache[key] = model or false
	return model
end

-- Modell in ein Vorschaufenster setzen, auf ein kleines Holzpodest; gibt eine Funktion zum Drehen zurück
local function show(viewport, model, yaw)
	viewport:ClearAllChildren()
	if not model then
		return nil
	end
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local clone = model:Clone()
	clone.Parent = world
	local cf, size = clone:GetBoundingBox()
	-- Podest unter dem Modell (dunkles Holz mit hellem Rand)
	local radius = math.clamp(math.max(size.X, size.Z) * 0.62, 0.8, 6)
	local bottom = cf.Position.Y - size.Y / 2
	local function disc(height, r, color, material)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(height, r * 2, r * 2)
		part.CFrame = CFrame.new(cf.Position.X, bottom - height / 2, cf.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		part.Color = color
		part.Material = material
		part.Anchored = true
		part.Parent = world
	end
	disc(radius * 0.12, radius, Color3.fromRGB(58, 42, 32), Enum.Material.Wood)
	disc(radius * 0.02, radius * 1.03, Color3.fromRGB(150, 112, 60), Enum.Material.Wood)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 26
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local reach = math.max(size.X, size.Y * 1.08, size.Z) * 0.5
	local distance = reach / math.tan(math.rad(camera.FieldOfView / 2)) * 1.12
	local focus = cf.Position - Vector3.new(0, size.Y * 0.03, 0)
	local function aim(angle)
		local offset = Vector3.new(math.sin(angle), 0.16, -math.cos(angle)).Unit * distance
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
	end
	aim(yaw or math.rad(-18))
	return aim
end

------------------------------------------------------------------ Bausteine der Oberfläche
-- gezeichnete Münze (statt eines Emojis)
local function coinIcon(parent, size, z)
	local coin = create("Frame", { Name = "Coin", Size = UDim2.fromOffset(size, size), BackgroundColor3 = T.coin, ZIndex = z, Parent = parent }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = T.coinEdge, Thickness = math.max(1, size / 10) }),
	})
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.52, 0.52), BackgroundTransparency = 1, ZIndex = z, Parent = coin }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = T.coinEdge, Thickness = 1, Transparency = 0.35 }),
	})
	return coin
end

-- warmer Lichtverlauf hinter einem 3D-Bild; das Vorschaufenster selbst ist durchsichtig
local function glowBackdrop(parent, z)
	local back = create("Frame", { Name = "Backdrop", BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z, Parent = parent }, {
		corner(T.radius - 2),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(T.glowTop, T.glowBottom) }),
	})
	local view = create("ViewportFrame", {
		Name = "View",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 138, 126),
		LightColor = Color3.fromRGB(255, 232, 205),
		LightDirection = Vector3.new(-0.6, -1, -0.8),
		ZIndex = z + 1,
		Parent = back,
	})
	return back, view
end

-- Zeile „Münze 1,800 · R$ 349“
local function priceRow(parent, entry, textSize, z)
	local row = create("Frame", { Name = "PriceRow", Size = UDim2.new(1, 0, 0, textSize + 6), BackgroundTransparency = 1, ZIndex = z, Parent = parent }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	return row
end

------------------------------------------------------------------ Fenster
local gui = create("ScreenGui", {
	Name = "VipShop",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	DisplayOrder = 30,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- unten links: Münzen und der Shop-Knopf (groß genug zum Tippen)
local hud = create("Frame", { Name = "Hud", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -18), Size = UDim2.fromOffset(170, 92), BackgroundTransparency = 1, Parent = gui })
local hudCoinRow = create("Frame", { Name = "CoinRow", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = hud }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
coinIcon(hudCoinRow, 20, 2).LayoutOrder = 1
local hudCoins = text({ Name = "Coins", Size = UDim2.fromOffset(130, 26), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = 18, Text = "0", TextColor3 = T.text, TextStrokeTransparency = 0.55, LayoutOrder = 2, Parent = hudCoinRow })
local hudButton = create("TextButton", {
	Name = "OpenShop",
	Position = UDim2.fromOffset(0, 38),
	Size = UDim2.fromOffset(150, 54),
	BackgroundColor3 = T.panel,
	BackgroundTransparency = 0.1,
	AutoButtonColor = true,
	Font = T.titleFont,
	Text = "Shop",
	TextSize = 26,
	TextColor3 = T.text,
	Parent = hud,
}, { corner(), hairline(0.6) })

local overlay = create("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, ZIndex = 10, Parent = gui })
local root = create("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1040, 640),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 11,
	Parent = overlay,
}, {
	corner(12),
	hairline(0.7),
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(36, 30, 26), T.panel) }),
})

-- Kopfzeile: Titel links, Münzen und Schließen rechts
local titleLabel = text({ Name = "Title", Font = T.titleFont, TextSize = 34, Text = "Shop", ZIndex = 12, Parent = root })
local subtitle = text({ Name = "Subtitle", TextSize = 14, TextColor3 = T.muted, Text = "", TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 12, Parent = root })
local coinBox = create("TextButton", { Name = "CoinBox", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(170, T.touch), BackgroundColor3 = T.surface, AutoButtonColor = true, Text = "", ZIndex = 12, Parent = root }, {
	corner(),
	hairline(0.82),
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
coinIcon(coinBox, 22, 13).LayoutOrder = 1
local coinsLabel = text({ Name = "Amount", Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = 18, Text = "0", ZIndex = 13, LayoutOrder = 2, Parent = coinBox })
local testNote = text({ Name = "TestNote", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(220, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.muted, Text = "Studio test coins, not saved", Visible = false, ZIndex = 12, Parent = root })
local closeButton = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(T.touch, T.touch),
	BackgroundColor3 = T.surface,
	AutoButtonColor = true,
	Font = T.boldFont,
	Text = "X",
	TextSize = 20,
	TextColor3 = T.text,
	Modal = true, -- Maus frei, solange das Fenster offen ist
	ZIndex = 12,
	Parent = root,
}, { corner(), hairline(0.82) })

-- Reiter (große Tippflächen, Unterstrich zeigt den aktiven)
local tabBar = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, ZIndex = 12, Parent = root }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local divider = create("Frame", { Name = "Divider", BackgroundColor3 = T.line, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 12, Parent = root })

-- Karten
local grid = create("ScrollingFrame", {
	Name = "Grid",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = T.muted,
	ScrollBarImageTransparency = 0.5,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 12,
	Parent = root,
}, {
	create("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }),
})
local gridLayout = create("UIGridLayout", { CellSize = UDim2.fromOffset(200, 230), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })

-- Anprobe / Details
local detail = create("Frame", { Name = "Detail", BackgroundColor3 = T.surface, ZIndex = 12, Parent = root }, { corner(10), hairline(0.88) })
local stageBack, stage = glowBackdrop(detail, 13)
stageBack.Name = "Stage"
local stageHint = text({ Name = "Hint", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -8), Size = UDim2.fromOffset(120, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.muted, Text = "Drag to turn", ZIndex = 15, Parent = stageBack })
local resetButton = create("TextButton", { Name = "Reset", Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(84, 36), BackgroundColor3 = T.panel, BackgroundTransparency = 0.25, AutoButtonColor = true, Font = T.boldFont, Text = "Reset", TextSize = 14, TextColor3 = T.text, ZIndex = 15, Visible = false, Parent = stageBack }, { corner() })
local info = create("Frame", { Name = "Info", BackgroundTransparency = 1, ZIndex = 13, Parent = detail }, {
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local kindRow = create("Frame", { Name = "KindRow", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 13, Parent = info }, {
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local rarityDot = create("Frame", { Name = "Dot", Size = UDim2.fromOffset(8, 8), BackgroundColor3 = T.muted, LayoutOrder = 1, ZIndex = 13, Parent = kindRow }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
local kindLabel = text({ Name = "Kind", Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = 12, TextColor3 = T.muted, Text = "", LayoutOrder = 2, ZIndex = 13, Parent = kindRow })
local nameLabel = text({ Name = "Name", Size = UDim2.new(1, 0, 0, 30), Font = T.titleFont, TextSize = 26, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", LayoutOrder = 2, ZIndex = 13, Parent = info })
local descLabel = text({ Name = "Description", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = T.muted, Text = "", LayoutOrder = 3, ZIndex = 13, Parent = info })
local statusLabel = text({ Name = "Status", Size = UDim2.new(1, 0, 0, 18), Font = T.boldFont, TextSize = 13, TextColor3 = T.good, Text = "", LayoutOrder = 4, ZIndex = 13, Parent = info })
local actions = create("Frame", { Name = "Actions", AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 13, Parent = detail })

-- Meldung als kleine Leiste unten in der Mitte
local message = create("TextLabel", {
	Name = "Message",
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = T.panel,
	Font = T.boldFont,
	TextSize = 14,
	Text = "",
	TextColor3 = T.text,
	Visible = false,
	ZIndex = 20,
	Parent = root,
}, { corner(16), hairline(0.75), create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }) })
local messageToken = 0
local function say(textValue, color)
	messageToken += 1
	local token = messageToken
	message.Text = textValue
	message.TextColor3 = color or T.text
	message.Visible = true
	task.delay(3.5, function()
		if token == messageToken then
			message.Visible = false
		end
	end)
end

------------------------------------------------------------------ Aufbau je nach Bildschirmgröße
local layout = { compact = false, cardText = 18 }
local function applyLayout()
	local area = gui.AbsoluteSize
	if area.X < 50 then
		return
	end
	local W = math.min(area.X - 24, 1040)
	local H = math.min(area.Y - 24, 640)
	local compact = H < 520 or W < 860
	layout.compact = compact
	root.Size = UDim2.fromOffset(W, H)
	local pad = compact and 12 or 24
	local headerH = compact and 56 or 76
	-- Kopfzeile
	titleLabel.Position = UDim2.fromOffset(pad, compact and 8 or 14)
	titleLabel.Size = UDim2.fromOffset(300, compact and 30 or 38)
	titleLabel.TextSize = compact and 26 or 34
	subtitle.Visible = not compact
	subtitle.Position = UDim2.fromOffset(pad + 2, 52)
	subtitle.Size = UDim2.fromOffset(math.max(W - 520, 200), 18)
	closeButton.Position = UDim2.new(1, -pad, 0, compact and 4 or 14)
	coinBox.Position = UDim2.new(1, -pad - T.touch - 10, 0, compact and 4 or 14)
	coinBox.Size = UDim2.fromOffset(compact and 130 or 170, T.touch)
	testNote.Position = UDim2.new(1, -pad - T.touch - 10, 0, (compact and 4 or 14) + T.touch + 2)
	testNote.Visible = testNote:GetAttribute("Wanted") == true and not compact
	-- Reiter
	tabBar.Position = UDim2.fromOffset(pad - 8, headerH)
	tabBar.Size = UDim2.new(1, -2 * pad, 0, T.touch - 4)
	divider.Position = UDim2.fromOffset(pad, headerH + T.touch - 4)
	divider.Size = UDim2.new(1, -2 * pad, 0, 1)
	-- Inhalt: Karten links, Anprobe rechts
	local top = headerH + T.touch + 8
	local contentH = H - top - pad
	local detailW = compact and math.floor(W * 0.42) or 344
	local gridW = W - 2 * pad - detailW - (compact and 10 or 18)
	grid.Position = UDim2.fromOffset(pad - 2, top)
	grid.Size = UDim2.fromOffset(gridW + 2, contentH)
	detail.Position = UDim2.fromOffset(W - pad - detailW, top)
	detail.Size = UDim2.fromOffset(detailW, contentH)
	-- Karten-Raster: so viele Spalten, wie gut passen
	local usable = gridW - 12
	local columns = usable >= 600 and 3 or usable >= 300 and 2 or 1
	local gap = compact and 8 or 12
	local cellW = math.floor((usable - gap * (columns - 1)) / columns)
	local thumbH = math.floor(cellW * (compact and 0.58 or 0.66))
	layout.cardText = compact and 15 or 18
	gridLayout.CellPadding = UDim2.fromOffset(gap, gap)
	gridLayout.CellSize = UDim2.fromOffset(cellW, thumbH + (compact and 58 or 74))
	layout.thumbH = thumbH
	-- Anprobe: Bühne oben, Infos, Knöpfe unten
	local inner = compact and 8 or 12
	local stageH = math.floor(math.clamp(contentH * (compact and 0.4 or 0.46), 110, 280))
	stageBack.Position = UDim2.fromOffset(inner, inner)
	stageBack.Size = UDim2.new(1, -2 * inner, 0, stageH)
	-- Knöpfe nebeneinander, wenn breit genug; sonst zwei Reihen
	local actionsH = (detailW - 2 * inner >= 280) and T.touch or (T.touch * 2 + 8)
	info.Position = UDim2.fromOffset(inner + 6, inner + stageH + (compact and 6 or 12))
	info.Size = UDim2.new(1, -2 * inner - 12, 0, contentH - stageH - actionsH - inner * 3)
	info.ClipsDescendants = true
	nameLabel.TextSize = compact and 20 or 26
	nameLabel.Size = UDim2.new(1, 0, 0, compact and 24 or 30)
	descLabel.TextSize = compact and 12 or 14
	actions.Position = UDim2.new(0, inner, 1, -inner)
	actions.Size = UDim2.new(1, -2 * inner, 0, actionsH)
	message.Position = UDim2.new(0.5, 0, 1, -pad)
end

------------------------------------------------------------------ Karten
local mode = "shop"
local currentTab
local selected
local cards = {}
local tabButtons = {}
local turn = math.rad(-18)
local aimStage

-- Preis einer Karte: Münze + Zahl, dahinter R$; oder „Owned“ / „Wearing“
local function fillPrice(row, entry, size, z)
	for _, child in row:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	if isOwned(entry) then
		local wearing = entry.slot and state.equipped[entry.slot] == entry.id
		local pill = text({ Size = UDim2.fromOffset(0, size + 6), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = size - 2, TextColor3 = T.good, Text = wearing and "Wearing" or "Owned", ZIndex = z, Parent = row })
		pill.LayoutOrder = 1
		return
	end
	if entry.coins then
		coinIcon(row, size - 2, z).LayoutOrder = 1
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = size, Text = money(entry.coins), ZIndex = z, LayoutOrder = 2, Parent = row })
	end
	if entry.robux then
		if entry.coins then
			text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, TextSize = size - 2, TextColor3 = T.muted, Text = "or", ZIndex = z, LayoutOrder = 3, Parent = row })
		end
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = size, TextColor3 = Color3.fromRGB(150, 210, 165), Text = "R$ " .. money(entry.robux), ZIndex = z, LayoutOrder = 4, Parent = row })
	end
	if not entry.coins and not entry.robux and entry.pack then
		local pack = byId[entry.pack]
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, TextSize = size - 2, TextColor3 = T.muted, Text = "In the " .. (pack and pack.title or "bundle"), ZIndex = z, LayoutOrder = 1, Parent = row })
	end
	if entry.kind == "Item" and (state.items[entry.id] or 0) > 0 then
		text({ Size = UDim2.fromOffset(0, size + 4), AutomaticSize = Enum.AutomaticSize.X, TextSize = size - 2, TextColor3 = T.good, Text = "  " .. state.items[entry.id] .. " in bag", ZIndex = z, LayoutOrder = 5, Parent = row })
	end
end

local function styleCard(card)
	local active = selected == card.entry
	card.stroke.Color = active and T.accent or T.line
	card.stroke.Transparency = active and 0 or 0.9
	card.stroke.Thickness = active and 2 or 1
	card.frame.BackgroundColor3 = active and T.surfaceHover or T.surface
	fillPrice(card.price, card.entry, layout.compact and 13 or 15, 15)
end

local select -- weiter unten

local thumbQueue = {}
local function makeCard(entry, order)
	local frame = create("TextButton", { Name = entry.id, BackgroundColor3 = T.surface, AutoButtonColor = false, Text = "", LayoutOrder = order, ZIndex = 13, Parent = grid }, { corner(10) })
	local stroke = create("UIStroke", { Color = T.line, Thickness = 1, Transparency = 0.9, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
	local back, view = glowBackdrop(frame, 14)
	back.Position = UDim2.fromOffset(6, 6)
	back.Size = UDim2.new(1, -12, 0, layout.thumbH or 130)
	if entry.note then
		local note = text({ Name = "Note", Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = 11, TextColor3 = T.onAccent, Text = entry.note, ZIndex = 17, Parent = frame })
		note.BackgroundTransparency = 0
		note.BackgroundColor3 = T.accent
		corner(10).Parent = note
		create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = note })
	end
	local titleY = (layout.thumbH or 130) + 12
	text({ Name = "Title", Position = UDim2.fromOffset(12, titleY), Size = UDim2.new(1, -24, 0, layout.cardText + 4), Font = T.titleFont, TextSize = layout.cardText, TextTruncate = Enum.TextTruncate.AtEnd, Text = entry.title, ZIndex = 14, Parent = frame })
	local price = priceRow(frame, entry, layout.compact and 13 or 15, 15)
	price.Position = UDim2.fromOffset(12, titleY + layout.cardText + 8)
	price.Size = UDim2.new(1, -24, 0, (layout.compact and 13 or 15) + 6)
	local card = { entry = entry, frame = frame, stroke = stroke, price = price, thumb = view }
	frame.MouseEnter:Connect(function()
		if selected ~= entry then
			frame.BackgroundColor3 = T.surfaceHover
		end
	end)
	frame.MouseLeave:Connect(function()
		styleCard(card)
	end)
	frame.Activated:Connect(function()
		select(entry)
	end)
	styleCard(card)
	table.insert(thumbQueue, card)
	return card
end

-- Bilder der Karten nach und nach bauen (Kleidung als Teil allein, nicht an der Figur)
task.spawn(function()
	while true do
		local card = table.remove(thumbQueue, 1)
		if card and card.frame.Parent then
			local entry = card.entry
			local model
			if entry.kind == "Clothing" then
				model = previewFor({ preview = { kind = "item", item = entry.id } }, fitting)
			elseif entry.preview and entry.preview.kind == "fitting" then
				local items = {}
				for _, id in entry.tryItems or {} do
					local item = ShopCatalog.find(id)
					items[item.slot] = id
				end
				model = previewFor(entry, { suit = entry.trySuit, items = items })
			else
				model = previewFor(entry, fitting)
			end
			show(card.thumb, model, math.rad(-20))
		end
		task.wait(card and 0.02 or 0.15)
	end
end)

local function showTab(tab)
	currentTab = tab
	for id, button in tabButtons do
		local active = id == tab
		button.TextColor3 = active and T.text or T.muted
		button.Underline.Visible = active
	end
	for _, card in cards do
		card.frame:Destroy()
	end
	table.clear(cards)
	table.clear(thumbQueue)
	local order = 0
	for _, entry in entries do
		if entry.tab == tab then
			order += 1
			table.insert(cards, makeCard(entry, order))
		end
	end
	grid.CanvasPosition = Vector2.zero
end

local function buildTabs(list)
	for _, button in tabButtons do
		button:Destroy()
	end
	table.clear(tabButtons)
	for index, info_ in list do
		local button = create("TextButton", {
			Name = info_[1],
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = T.boldFont,
			Text = info_[2],
			TextSize = layout.compact and 15 or 17,
			TextColor3 = T.muted,
			LayoutOrder = index,
			ZIndex = 13,
			Parent = tabBar,
		}, { create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
		create("Frame", { Name = "Underline", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, -16, 0, 3), BackgroundColor3 = T.accent, BorderSizePixel = 0, Visible = false, ZIndex = 14, Parent = button }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		button.Activated:Connect(function()
			showTab(info_[1])
			if cards[1] then
				select(cards[1].entry)
			end
		end)
		tabButtons[info_[1]] = button
	end
end

------------------------------------------------------------------ Anprobe und Knöpfe
local function refreshStage()
	if not selected then
		return
	end
	local entry = selected
	local model = previewFor(entry, fitting)
	if selected ~= entry then
		return
	end
	aimStage = show(stage, model, turn)
	local wearing = fitting.suit ~= nil or next(fitting.items) ~= nil
	resetButton.Visible = entry.preview ~= nil and entry.preview.kind == "fitting" and wearing
end

-- Auswahl probiert Kleidung und Anzüge sofort an (sammelt sich auf der Figur)
local function tryOn(entry)
	if entry.trySuit then
		fitting.suit = entry.trySuit
	end
	for _, id in entry.tryItems or {} do
		local item = ShopCatalog.find(id)
		if item then
			fitting.items[item.slot] = id
		end
	end
end

-- großer Knopf (48 hoch); `coins` = Münz-Symbol vor dem Text
local function bigButton(parent, label, fill, textColor, order, onClick, options)
	options = options or {}
	local b = create("TextButton", {
		Size = UDim2.new(options.width or 1, options.width and -5 or 0, 0, T.touch),
		BackgroundColor3 = fill,
		AutoButtonColor = onClick ~= nil,
		Text = "",
		LayoutOrder = order,
		ZIndex = 14,
		Parent = parent,
	}, {
		corner(),
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	if options.outline then
		hairline(0.6).Parent = b
	end
	if options.coins then
		coinIcon(b, 20, 15).LayoutOrder = 1
	end
	text({ Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Font = T.boldFont, TextSize = 16, TextColor3 = textColor, Text = label, ZIndex = 15, LayoutOrder = 2, Parent = b })
	if onClick then
		local busy = false
		b.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			onClick()
			busy = false
		end)
	end
	return b
end

local function promptRobux(entry)
	if entry.kind == "Pass" then
		if not entry.passId or entry.passId == 0 then
			say("Robux purchases open soon.", T.accent)
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, entry.passId)
		return
	end
	local productId = entry.productId
	if entry.kind == "Starter" and not state.owned.StarterPack and entry.firstProductId and entry.firstProductId ~= 0 then
		productId = entry.firstProductId
	end
	if not productId or productId == 0 then
		say("Robux purchases open soon.", T.accent)
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

local function buyWithCoins(entry)
	if state.coins < entry.coins then
		say("You need " .. money(entry.coins - state.coins) .. " more coins.", T.bad)
		return
	end
	local ok, result = remotes.BuyWithCoins:InvokeServer(entry.id)
	say(result or (ok and "Done." or "Something went wrong."), ok and T.good or T.bad)
end

local function equip(entry, on)
	local ok, result = remotes.Equip:InvokeServer(entry.slot, on and entry.id or nil)
	if ok then
		say(on and ("You are wearing " .. entry.title .. ".") or (entry.title .. " taken off."), T.good)
	else
		say(result or "Something went wrong.", T.bad)
	end
end

local function renderActions(entry)
	actions:ClearAllChildren()
	statusLabel.Text = ""
	statusLabel.TextColor3 = T.good
	local rows = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 13, Parent = actions }, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom }),
	})
	if isOwned(entry) then
		if entry.slot then
			local on = state.equipped[entry.slot] == entry.id
			statusLabel.Text = on and "You are wearing this." or "You own this."
			bigButton(rows, on and "Take off" or "Wear", on and T.surfaceHover or T.accent, on and T.text or T.onAccent, 2, function()
				equip(entry, not on)
			end, { outline = on })
		else
			statusLabel.Text = entry.kind == "Pack" and "You own this bundle." or "You own this."
		end
		return
	end
	if entry.kind == "Item" then
		statusLabel.Text = "In your bag: " .. (state.items[entry.id] or 0)
		statusLabel.TextColor3 = T.muted
	end
	if entry.pack and not entry.coins and not entry.robux then
		local pack = byId[entry.pack]
		bigButton(rows, "See the " .. (pack and pack.title or "bundle"), T.accent, T.onAccent, 2, function()
			if pack then
				showTab(pack.tab)
				select(pack)
			end
		end)
		return
	end
	-- zwei Wege zu bezahlen: nebeneinander, wenn Platz ist, sonst untereinander
	local both = entry.coins and entry.robux
	local sideBySide = both and actions.AbsoluteSize.X >= 280
	local holder = rows
	if sideBySide then
		holder = create("Frame", { Size = UDim2.new(1, 0, 0, T.touch), BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 13, Parent = rows }, {
			create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
	end
	if entry.coins then
		local afford = state.coins >= entry.coins
		bigButton(holder, money(entry.coins), afford and T.accent or T.surfaceHover, afford and T.onAccent or T.muted, 1, function()
			buyWithCoins(entry)
		end, { coins = true, width = sideBySide and 0.5 or nil })
	end
	if entry.robux then
		local label = "R$ " .. money(entry.robux)
		if entry.kind == "Starter" and entry.firstRobux and not state.owned.StarterPack then
			label = "R$ " .. entry.firstRobux .. "   (instead of " .. entry.robux .. ")"
		end
		bigButton(holder, label, T.robux, T.text, 3, function()
			promptRobux(entry)
		end, { width = sideBySide and 0.5 or nil })
	end
end

function select(entry)
	selected = entry
	for _, card in cards do
		styleCard(card)
	end
	tryOn(entry)
	local rarity = entry.rarity and ShopCatalog.RARITIES[entry.rarity]
	local kinds = { Skin = "Suit & skin", Car = "Car", Clothing = "Clothing", Outfit = "Clothing set", Pack = "Bundle", Starter = "Bundle", Pass = "Game pass", CoinPack = "Coins", Boost = "Boost", Item = "Snack", Product = "Extra" }
	kindLabel.Text = ((kinds[entry.kind] or "") .. (rarity and ("  ·  " .. rarity.title:sub(1, 1) .. rarity.title:sub(2):lower()) or "")):upper()
	rarityDot.Visible = rarity ~= nil
	rarityDot.BackgroundColor3 = rarity and rarity.color:Lerp(T.muted, 0.35) or T.muted
	nameLabel.Text = entry.title
	local description = entry.description or ""
	if entry.contents then
		description ..= "\nIncludes: " .. table.concat(entry.contents, ", ")
	end
	descLabel.Text = description
	stage:ClearAllChildren()
	task.spawn(refreshStage)
	renderActions(entry)
end

resetButton.Activated:Connect(function()
	fitting.suit = state.equipped.Player
	table.clear(fitting.items)
	refreshStage()
end)

-- Figur mit der Maus (oder dem Finger) drehen
local dragging = false
local lastX
stageBack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		lastX = input.Position.X
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local dx = input.Position.X - lastX
		lastX = input.Position.X
		turn -= dx * 0.012
		if aimStage then
			aimStage(turn)
		end
	end
end)

------------------------------------------------------------------ Öffnen / Schließen
local open = false
local function setOpen(value, wantedMode, target)
	open = value
	if not value then
		GuiService.SelectedObject = nil
		overlay.Visible = false
		hud.Visible = true
		return
	end
	readData()
	applyLayout()
	if wantedMode and wantedMode ~= mode then
		mode = wantedMode
		currentTab = nil
	end
	buildTabs(mode == "kiosk" and KIOSK_TABS or SHOP_TABS)
	titleLabel.Text = mode == "kiosk" and "Kiosk" or "Shop"
	subtitle.Text = mode == "kiosk" and "Snacks for the long night. Use up to 3 per round." or "Suits, clothing and bundles. Pick anything to try it on."
	fitting.suit = state.equipped.Player
	table.clear(fitting.items)
	local entry = target and byId[target]
	local tabTarget = not entry and target or nil -- auch ein Reiter als Ziel ("Skins")
	hud.Visible = false
	overlay.Visible = true
	showTab(entry and entry.tab or tabTarget or currentTab or (mode == "kiosk" and "Snacks" or "Bundles"))
	if entry then
		select(entry)
	elseif cards[1] then
		select(cards[1].entry)
	end
	-- kurz und ruhig einblenden (Abdunklung), außer bei „weniger Bewegung“
	if not GuiService.ReducedMotionEnabled then
		overlay.BackgroundTransparency = 1
		TweenService:Create(overlay, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.45 }):Play()
	end
end

-- Bildschirmgröße ändert sich (Fenster, Drehen des Handys): neu anordnen
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if open then
		applyLayout()
		showTab(currentTab)
		if selected then
			select(selected)
		end
	end
end)

hudButton.Activated:Connect(function()
	setOpen(true, "shop")
end)
closeButton.Activated:Connect(function()
	setOpen(false)
end)
coinBox.Activated:Connect(function()
	if mode == "shop" then
		showTab("Coins")
		if cards[1] then
			select(cards[1].entry)
		end
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if open and not processed and input.KeyCode == Enum.KeyCode.Escape then
		setOpen(false)
	end
end)

-- Andere Skripte (und Tests) können öffnen: VipShop:SetAttribute("Open", "shop" | "kiosk" | Artikel-ID | Reiter)
gui:GetAttributeChangedSignal("Open"):Connect(function()
	local target = gui:GetAttribute("Open")
	if type(target) == "string" and target ~= "" then
		gui:SetAttribute("Open", nil)
		if target == "shop" or target == "kiosk" then
			setOpen(true, target)
		else
			local entry = byId[target]
			local kioskTab = target == "Snacks" or target == "Extras"
			setOpen(true, (kioskTab or (entry and (entry.tab == "Snacks" or entry.tab == "Extras"))) and "kiosk" or "shop", target)
		end
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then
		return
	end
	if CollectionService:HasTag(prompt, "ShopHutPrompt") then
		setOpen(true, "shop", prompt:GetAttribute("ShopTab"))
	elseif CollectionService:HasTag(prompt, "ShowroomItemPrompt") then
		setOpen(true, "shop", prompt:GetAttribute("ShopItem"))
	elseif CollectionService:HasTag(prompt, "KioskPrompt") or CollectionService:HasTag(prompt, "ShopPrompt") then
		setOpen(true, "kiosk")
	end
end)

-- Daten geändert (Kauf, Anziehen): neu anzeigen
local function onDataChanged()
	readData()
	hudCoins.Text = money(state.coins)
	coinsLabel.Text = money(state.coins)
	testNote:SetAttribute("Wanted", player:GetAttribute("TestCoins") == true)
	testNote.Visible = player:GetAttribute("TestCoins") == true and not layout.compact
	if open then
		for _, card in cards do
			styleCard(card)
		end
		if selected then
			renderActions(selected)
		end
	end
end
player:GetAttributeChangedSignal("Coins"):Connect(onDataChanged)
player:GetAttributeChangedSignal("ShopData"):Connect(onDataChanged)
onDataChanged()
