-- VIP-Shop in der Lobby: Menü mit Kategorien (Featured, Skins, Clothing, Snacks, Passes, Coins),
-- Karten mit Vorschau, rechts eine große 3D-Vorschau (dreht sich) mit Kaufen / Anziehen.
-- Öffnen: Knopf unten links, die Terminals im VIP-Showroom, „View in shop“ an jedem Ausstellungs-
-- stück und der Verkäufer im Kiosk (öffnet die Snacks).
-- Außerdem drehen sich hier die Drehscheibe und die Kleidung im Showroom (nur beim Client).

-- Liegen im selben Studio-Ort auch die Skripte von Level 1, läuft nur das Level
if game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Level") then
	return
end

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local RealFigure = require(Shared:WaitForChild("RealFigure"))
local Skins = require(Shared:WaitForChild("Skins"))
local SportsCar = require(Shared:WaitForChild("SportsCar"))
local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")

local player = Players.LocalPlayer

------------------------------------------------------------------ Farben und Helfer
local C = {
	gold = Color3.fromRGB(226, 182, 84),
	goldDark = Color3.fromRGB(150, 112, 40),
	panel = Color3.fromRGB(18, 17, 21),
	panel2 = Color3.fromRGB(28, 26, 32),
	card = Color3.fromRGB(34, 32, 39),
	cardHover = Color3.fromRGB(44, 41, 50),
	text = Color3.fromRGB(242, 236, 226),
	muted = Color3.fromRGB(165, 158, 150),
	robux = Color3.fromRGB(46, 160, 90),
	coins = Color3.fromRGB(196, 146, 40),
	red = Color3.fromRGB(170, 50, 46),
	owned = Color3.fromRGB(70, 150, 90),
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
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", { Color = color, Thickness = thickness or 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function label(props)
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or C.text
	props.Font = props.Font or Enum.Font.GothamMedium
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

local function money(n)
	local text = tostring(math.floor(n))
	return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
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

------------------------------------------------------------------ Einträge des Shops
-- entry = { id, kind, title, description, coins, robux, productId, passId, rarity, icon, tag, preview }
local entries = {}
local byId = {}
local function add(entry)
	table.insert(entries, entry)
	byId[entry.id] = entry
	return entry
end

local PACK_PREVIEW = {
	GoldenPack = { kind = "family" },
	SarpVip = { kind = "skin", skin = "GildedHorror" },
	Everything = { kind = "skin", skin = "CrimsonCount" },
}

local starter = ShopCatalog.STARTER_PACK
add({ id = "StarterPack", kind = "Starter", tab = "Featured", title = starter.title, description = starter.description, robux = starter.robux, firstRobux = starter.firstTimeRobux, productId = starter.productId, firstProductId = starter.firstTimeProductId, rarity = "Rare", icon = "🎒", tag = "FIRST TIME 50 R$", once = true })
for _, pack in ShopCatalog.PACKS do
	add({ id = pack.id, kind = "Pack", tab = "Featured", title = pack.title, description = pack.description, robux = pack.robux, productId = pack.productId, rarity = "Legendary", tag = pack.tag or "PACK", preview = PACK_PREVIEW[pack.id], grants = pack.grants, once = true })
end
for _, skin in ShopCatalog.SKINS do
	local entry = add({ id = skin.id, kind = "Skin", tab = "Skins", title = skin.title, description = skin.description, coins = skin.coins, robux = skin.robux, productId = skin.productId, pack = skin.pack, slot = skin.slot, rarity = skin.rarity, preview = { kind = "skin", skin = skin.id }, once = true })
	if skin.id == "ShadowSarp" then
		entry.featured = true
	end
end
local car = ShopCatalog.SPORTS_CAR
add({ id = car.id, kind = "Car", tab = "Skins", title = car.title, description = car.description, coins = car.coins, robux = car.robux, productId = car.productId, rarity = car.rarity, preview = { kind = "car" }, once = true, featured = true })
for _, item in ShopCatalog.CLOTHING do
	add({ id = item.id, kind = "Clothing", tab = "Clothing", title = item.title, description = "Clothing for coins. Wearing it in the game comes soon.", coins = item.coins, rarity = item.rarity, preview = { kind = "clothing", item = item.id }, once = true })
end
for _, item in ShopCatalog.ITEMS do
	add({ id = item.id, kind = "Item", tab = "Snacks", title = item.title, description = item.description .. "\nUse up to 3 snacks per round.", coins = item.coins, robux = item.robux, productId = item.productId, rarity = "Common", icon = item.icon })
end
for _, pass in ShopCatalog.GAMEPASSES do
	add({ id = pass.id, kind = "Pass", tab = "Passes", title = pass.title, description = pass.description, robux = pass.robux, passId = pass.passId, rarity = "Epic", icon = pass.icon, once = true })
end
for _, pack in ShopCatalog.COIN_PACKS do
	add({ id = pack.id, kind = "CoinPack", tab = "Coins", title = money(pack.coins) .. " Coins", description = "Spend coins on skins, clothing and snacks.", robux = pack.robux, productId = pack.productId, rarity = pack.coins >= 1500 and "Legendary" or "Rare", icon = "💰", tag = pack.tag })
end
local boost = ShopCatalog.COIN_BOOST
add({ id = boost.id, kind = "Boost", tab = "Coins", title = boost.title, description = boost.description, robux = boost.robux, productId = boost.productId, rarity = "Epic", icon = "⚡" })

local TABS = {
	{ id = "Featured", title = "Featured", icon = "★" },
	{ id = "Skins", title = "Skins", icon = "👔" },
	{ id = "Clothing", title = "Clothing", icon = "🧥" },
	{ id = "Snacks", title = "Snacks", icon = "🍫" },
	{ id = "Passes", title = "Passes", icon = "🎟️" },
	{ id = "Coins", title = "Coins", icon = "💰" },
}

local function inTab(entry, tab)
	return entry.tab == tab or (tab == "Featured" and entry.featured)
end

local function isOwned(entry)
	return entry.once and state.owned[entry.id] == true
end

local function rarityColor(entry)
	local rarity = ShopCatalog.RARITIES[entry.rarity or "Common"]
	return rarity and rarity.color or C.gold
end

------------------------------------------------------------------ 3D-Vorschau
-- Modelle werden einmal gebaut und zwischengespeichert. Figuren brauchen kurz den workspace
-- (der Skin misst die Körperform mit Strahlen), dann kommen sie in die Vorschau.
-- Vorschaufenster (ViewportFrame) zeigen keine SurfaceAppearance (Köpfe wären grau) und Glas
-- sieht silbern aus: Farbtextur direkt an die MeshPart, Glas wird glatter Kunststoff.
local function fitForViewport(model)
	for _, item in model:GetDescendants() do
		if item:IsA("ParticleEmitter") or item:IsA("Light") then
			item:Destroy() -- in der Vorschau unsichtbar, kostet nur
		elseif item:IsA("SurfaceAppearance") then
			item:Destroy() -- Farbtextur hat buildFigure schon an die MeshPart gesetzt
		elseif item:IsA("BasePart") and item.Material == Enum.Material.Glass then
			item.Material = Enum.Material.SmoothPlastic
			item.Reflectance = 0.15
		end
	end
	return model
end

local previewCache = {}
local buildArea = CFrame.new(0, 3000, 0)

local function buildFigure(spec, skinId, options)
	local container = ReplicatedStorage:FindFirstChild(spec.folder)
	local template = container and container:FindFirstChild(spec.name)
	if not template then
		return nil
	end
	local model = RealFigure.prepare(template, { anchor = true, height = spec.height })
	-- Farbtextur direkt an die Körperteile (für das Vorschaufenster)
	local texture = ShopCatalog.FIGURE_TEXTURES[spec.name]
	if texture then
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") and part:FindFirstChildOfClass("SurfaceAppearance") then
				part.TextureID = texture
			end
		end
	end
	model:PivotTo(buildArea)
	model.Parent = workspace
	Skins.apply(model, skinId, options)
	model.Parent = nil
	return model
end

local function buildPreview(preview)
	if not preview then
		return nil
	end
	local key = preview.kind .. ":" .. tostring(preview.skin or preview.item or "")
	if previewCache[key] ~= nil then
		return previewCache[key] or nil
	end
	local ok, model = pcall(function()
		if preview.kind == "skin" then
			local skin = ShopCatalog.find(preview.skin)
			return buildFigure(skin.preview, skin.id, skin.options)
		elseif preview.kind == "family" then
			local group = Instance.new("Model")
			local x = -2.4
			for _, spec in ShopCatalog.FAMILY_GOLD do
				local figure = buildFigure(spec, "GoldSuit", spec.options)
				if figure then
					figure:PivotTo(CFrame.new(x, 0, 0))
					figure.Parent = group
					x += 1.6
				end
			end
			return group
		elseif preview.kind == "car" then
			local holder = Instance.new("Model")
			SportsCar.build(holder, CFrame.new())
			return holder
		elseif preview.kind == "clothing" then
			local folder = ReplicatedStorage:FindFirstChild("Shop") and ReplicatedStorage.Shop:FindFirstChild("Kleidung")
			local template = folder and folder:FindFirstChild(preview.item)
			if template then
				local holder = Instance.new("Model")
				local part = template:Clone()
				part.Anchored = true
				part.CFrame = CFrame.new()
				part.Parent = holder
				return holder
			end
		end
		return nil
	end)
	if not ok then
		warn("Shop-Vorschau fehlgeschlagen:", model)
		model = nil
	end
	if model then
		fitForViewport(model)
	end
	previewCache[key] = model or false
	return model
end

-- Modell in einen ViewportFrame setzen, Kamera passend; gibt die Kamera-Daten zurück
local function showInViewport(viewport, model, angle)
	viewport:ClearAllChildren()
	if not model then
		return nil
	end
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local clone = model:Clone()
	clone.Parent = world
	local cf, size = clone:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	viewport.CurrentCamera = camera
	camera.Parent = viewport
	local radius = math.max(size.X, size.Y, size.Z) * 0.5
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.05
	local focus = cf.Position
	local info = { camera = camera, focus = focus, distance = distance, height = size.Y * 0.08 }
	local function aim(a)
		local offset = Vector3.new(math.sin(a), 0, -math.cos(a)) * distance
		camera.CFrame = CFrame.lookAt(focus + offset + Vector3.new(0, info.height, 0), focus)
	end
	info.aim = aim
	aim(angle or math.rad(-20))
	return info
end

------------------------------------------------------------------ Oberfläche
local gui = create("ScreenGui", {
	Name = "VipShop",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 30,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- HUD: Münzen und Shop-Knopf unten links
local hud = create("Frame", {
	Name = "Hud",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.fromOffset(170, 96),
	BackgroundTransparency = 1,
	Parent = gui,
})
local hudCoins = label({
	Name = "Coins",
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	Text = "● 0",
	TextColor3 = C.gold,
	Parent = hud,
})
create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Transparency = 0.3, Parent = hudCoins })
local hudButton = create("TextButton", {
	Name = "OpenShop",
	Position = UDim2.fromOffset(0, 40),
	Size = UDim2.fromOffset(150, 50),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.1,
	AutoButtonColor = true,
	Font = Enum.Font.GothamBlack,
	Text = "★ VIP SHOP",
	TextSize = 18,
	TextColor3 = C.gold,
	Parent = hud,
}, { corner(12), stroke(C.gold, 2, 0.15) })

local overlay = create("Frame", {
	Name = "Overlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Visible = false,
	ZIndex = 10,
	Parent = gui,
})

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(980, 600),
	BackgroundColor3 = C.panel,
	ZIndex = 11,
	Parent = overlay,
}, {
	corner(18),
	stroke(C.gold, 2, 0.2),
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(30, 27, 33), Color3.fromRGB(14, 13, 16)),
	}),
})
local scale = create("UIScale", { Parent = panel })
local function updateScale()
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min((size.X - 24) / 980, (size.Y - 24) / 600), 0.45, 1.25)
end
updateScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Kopfzeile
label({ Name = "Title", Position = UDim2.fromOffset(26, 14), Size = UDim2.fromOffset(300, 34), Font = Enum.Font.GothamBlack, TextSize = 30, Text = "★ VIP SHOP", TextColor3 = C.gold, ZIndex = 12, Parent = panel })
label({ Name = "Sub", Position = UDim2.fromOffset(28, 46), Size = UDim2.fromOffset(400, 18), TextSize = 14, Text = "Skins, packs and snacks for the last night", TextColor3 = C.muted, ZIndex = 12, Parent = panel })
local coinPill = create("TextButton", {
	Name = "CoinPill",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -78, 0, 18),
	Size = UDim2.fromOffset(190, 40),
	BackgroundColor3 = C.panel2,
	AutoButtonColor = true,
	Font = Enum.Font.GothamBold,
	Text = "● 0   +",
	TextSize = 18,
	TextColor3 = C.gold,
	ZIndex = 12,
	Parent = panel,
}, { corner(20), stroke(C.goldDark, 1.5, 0.2) })
local closeButton = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 18),
	Size = UDim2.fromOffset(44, 40),
	BackgroundColor3 = C.red,
	AutoButtonColor = true,
	Font = Enum.Font.GothamBlack,
	Text = "X",
	TextSize = 20,
	TextColor3 = C.text,
	Modal = true, -- Maus frei, solange der Shop offen ist (Ego-Perspektive)
	ZIndex = 12,
	Parent = panel,
}, { corner(12) })
local testNote = label({ Name = "TestNote", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -78, 0, 60), Size = UDim2.fromOffset(190, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, Text = "Studio test coins (not saved)", TextColor3 = C.muted, Visible = false, ZIndex = 12, Parent = panel })

-- Seitenleiste
local sidebar = create("Frame", {
	Name = "Sidebar",
	Position = UDim2.fromOffset(18, 84),
	Size = UDim2.fromOffset(160, 496),
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = panel,
}, { create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

-- Kartenbereich
local grid = create("ScrollingFrame", {
	Name = "Grid",
	Position = UDim2.fromOffset(192, 84),
	Size = UDim2.fromOffset(470, 496),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = C.goldDark,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 12,
	Parent = panel,
}, {
	create("UIGridLayout", { CellSize = UDim2.fromOffset(146, 196), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }),
})

-- Detailbereich rechts
local detail = create("Frame", {
	Name = "Detail",
	Position = UDim2.fromOffset(676, 84),
	Size = UDim2.fromOffset(286, 496),
	BackgroundColor3 = C.panel2,
	ZIndex = 12,
	Parent = panel,
}, { corner(14), stroke(C.goldDark, 1, 0.4) })
local detailView = create("ViewportFrame", {
	Name = "Preview",
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 0, 236),
	BackgroundColor3 = Color3.fromRGB(40, 36, 44),
	Ambient = Color3.fromRGB(150, 145, 150),
	LightColor = Color3.fromRGB(255, 240, 220),
	LightDirection = Vector3.new(-0.5, -1, -0.7),
	ZIndex = 13,
	Parent = detail,
}, { corner(10) })
local detailIcon = label({ Name = "Icon", Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 236), TextSize = 110, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, Text = "", ZIndex = 14, Parent = detail })
local detailRarity = label({ Name = "Rarity", Position = UDim2.fromOffset(16, 252), Size = UDim2.new(1, -32, 0, 16), Font = Enum.Font.GothamBlack, TextSize = 12, Text = "", ZIndex = 13, Parent = detail })
local detailTitle = label({ Name = "Title", Position = UDim2.fromOffset(16, 268), Size = UDim2.new(1, -32, 0, 30), Font = Enum.Font.GothamBlack, TextSize = 24, TextScaled = false, Text = "", ZIndex = 13, Parent = detail })
local detailText = label({ Name = "Text", Position = UDim2.fromOffset(16, 300), Size = UDim2.new(1, -32, 0, 64), TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = C.muted, Text = "", ZIndex = 13, Parent = detail })
local detailStatus = label({ Name = "Status", Position = UDim2.fromOffset(16, 366), Size = UDim2.new(1, -32, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13, Text = "", TextColor3 = C.owned, ZIndex = 13, Parent = detail })
local buttonArea = create("Frame", {
	Name = "Buttons",
	Position = UDim2.fromOffset(14, 390),
	Size = UDim2.new(1, -28, 0, 96),
	BackgroundTransparency = 1,
	ZIndex = 13,
	Parent = detail,
}, { create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom }) })

-- Meldung unten im Shop
local message = label({
	Name = "Message",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 34),
	Size = UDim2.fromOffset(700, 26),
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = Enum.Font.GothamBold,
	TextSize = 17,
	Text = "",
	TextTransparency = 1,
	TextStrokeTransparency = 1,
	ZIndex = 13,
	Parent = panel,
})
local messageToken = 0
local function say(text, color)
	messageToken += 1
	local token = messageToken
	message.Text = text
	message.TextColor3 = color or C.text
	message.TextTransparency = 0
	message.TextStrokeTransparency = 0.5
	task.delay(3.5, function()
		if token == messageToken then
			TweenService:Create(message, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

------------------------------------------------------------------ Karten
local currentTab = "Featured"
local selected
local cards = {}
local tabButtons = {}
local detailCamera
local spinAngle = math.rad(-20)

local function priceLine(entry)
	if isOwned(entry) then
		return (entry.slot and state.equipped[entry.slot] == entry.id) and "EQUIPPED" or "OWNED", C.owned
	end
	if entry.kind == "Item" and (state.items[entry.id] or 0) > 0 then
		return "● " .. money(entry.coins) .. "  ·  x" .. state.items[entry.id], C.gold
	end
	if entry.coins then
		return "● " .. money(entry.coins), C.gold
	end
	if entry.pack then
		local pack = byId[entry.pack]
		return pack and pack.title or "Pack", C.muted
	end
	if entry.robux then
		return "R$ " .. money(entry.robux), Color3.fromRGB(120, 220, 150)
	end
	return "", C.muted
end

local function refreshCard(card)
	local entry = card.entry
	local text, color = priceLine(entry)
	card.price.Text = text
	card.price.TextColor3 = color
	card.frame:FindFirstChildOfClass("UIStroke").Color = (selected == entry) and C.gold or rarityColor(entry)
	card.frame:FindFirstChildOfClass("UIStroke").Thickness = (selected == entry) and 2.5 or 1
end

local select -- weiter unten

local function makeCard(entry, order)
	local frame = create("TextButton", {
		Name = entry.id,
		BackgroundColor3 = C.card,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		ZIndex = 13,
		Parent = grid,
	}, { corner(12), stroke(rarityColor(entry), 1, 0.15) })
	local thumb = create("ViewportFrame", {
		Name = "Thumb",
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, 118),
		BackgroundColor3 = Color3.fromRGB(46, 42, 50),
		Ambient = Color3.fromRGB(160, 155, 160),
		LightDirection = Vector3.new(-0.5, -1, -0.7),
		ZIndex = 14,
		Parent = frame,
	}, { corner(9) })
	if entry.icon then
		label({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 58, Font = Enum.Font.GothamBold, Text = entry.icon, ZIndex = 15, Parent = thumb })
	end
	-- Seltenheits-Streifen
	create("Frame", { Name = "RarityBar", Position = UDim2.new(0, 6, 0, 126), Size = UDim2.new(1, -12, 0, 3), BackgroundColor3 = rarityColor(entry), BorderSizePixel = 0, ZIndex = 14, Parent = frame })
	label({ Name = "Title", Position = UDim2.fromOffset(10, 134), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.GothamBold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Text = entry.title, ZIndex = 14, Parent = frame })
	local price = label({ Name = "Price", Position = UDim2.fromOffset(10, 158), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.GothamBlack, TextSize = 14, Text = "", ZIndex = 14, Parent = frame })
	if entry.tag then
		local tag = label({ Name = "Tag", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, TextColor3 = Color3.fromRGB(30, 22, 8), Font = Enum.Font.GothamBlack, TextSize = 11, Text = "  " .. entry.tag .. "  ", TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 16, Parent = frame })
		tag.BackgroundTransparency = 0
		tag.BackgroundColor3 = C.gold
		corner(5).Parent = tag
	end
	local card = { entry = entry, frame = frame, price = price, thumb = thumb }
	frame.MouseEnter:Connect(function()
		frame.BackgroundColor3 = C.cardHover
	end)
	frame.MouseLeave:Connect(function()
		frame.BackgroundColor3 = C.card
	end)
	frame.Activated:Connect(function()
		select(entry)
	end)
	refreshCard(card)
	return card
end

-- Vorschaubilder der Karten nach und nach bauen (eine pro Bild, damit nichts ruckelt)
local thumbQueue = {}
local function queueThumb(card)
	if card.entry.preview and not card.thumbDone then
		table.insert(thumbQueue, card)
	end
end
task.spawn(function()
	while true do
		local card = table.remove(thumbQueue, 1)
		if card and card.frame.Parent then
			card.thumbDone = true
			local model = buildPreview(card.entry.preview)
			showInViewport(card.thumb, model, math.rad(-25))
		end
		task.wait(card and 0.03 or 0.2)
	end
end)

local function showTab(tab)
	currentTab = tab
	for id, button in tabButtons do
		local active = id == tab
		button.BackgroundColor3 = active and C.gold or C.panel2
		button.TextColor3 = active and Color3.fromRGB(28, 20, 8) or C.text
	end
	for _, card in cards do
		card.frame:Destroy()
	end
	table.clear(cards)
	table.clear(thumbQueue)
	local order = 0
	for _, entry in entries do
		if inTab(entry, tab) then
			order += 1
			local card = makeCard(entry, order)
			table.insert(cards, card)
			queueThumb(card)
		end
	end
	grid.CanvasPosition = Vector2.zero
end

for index, tab in TABS do
	local button = create("TextButton", {
		Name = tab.id,
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = C.panel2,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		Text = "  " .. tab.icon .. "   " .. tab.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 17,
		TextColor3 = C.text,
		LayoutOrder = index,
		ZIndex = 13,
		Parent = sidebar,
	}, { corner(10) })
	button.Activated:Connect(function()
		showTab(tab.id)
	end)
	tabButtons[tab.id] = button
end

------------------------------------------------------------------ Kaufen und Anziehen
local function actionButton(text, color, order, onClick, textColor)
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = color,
		AutoButtonColor = onClick ~= nil,
		Font = Enum.Font.GothamBlack,
		Text = text,
		TextSize = 16,
		TextColor3 = textColor or C.text,
		LayoutOrder = order,
		ZIndex = 14,
		Parent = buttonArea,
	}, { corner(10) })
	if onClick then
		local busy = false
		button.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			onClick()
			busy = false
		end)
	end
	return button
end

local function promptRobux(entry)
	local productId = entry.productId
	if entry.kind == "Starter" and not state.owned.StarterPack and entry.firstProductId and entry.firstProductId ~= 0 then
		productId = entry.firstProductId
	end
	if entry.kind == "Pass" then
		if not entry.passId or entry.passId == 0 then
			say("Robux purchases open soon!", C.gold)
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, entry.passId)
		return
	end
	if not productId or productId == 0 then
		say("Robux purchases open soon!", C.gold)
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

local function buyCoins(entry)
	local ok, result = remotes.BuyWithCoins:InvokeServer(entry.id)
	say(result or (ok and "Done!" or "Something went wrong."), ok and C.owned or Color3.fromRGB(240, 120, 110))
end

local function equip(entry, on)
	local ok, result = remotes.Equip:InvokeServer(entry.slot, on and entry.id or nil)
	if ok then
		say(on and (entry.title .. " equipped!") or (entry.title .. " taken off."), C.owned)
	else
		say(result or "Something went wrong.", Color3.fromRGB(240, 120, 110))
	end
end

local function renderButtons(entry)
	buttonArea:ClearAllChildren()
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = buttonArea })
	detailStatus.Text = ""
	if isOwned(entry) then
		if entry.slot then
			local on = state.equipped[entry.slot] == entry.id
			detailStatus.Text = on and "✓ You are wearing this" or "✓ Owned"
			actionButton(on and "TAKE OFF" or "EQUIP", on and C.panel or C.gold, 1, function()
				equip(entry, not on)
			end, on and C.text or Color3.fromRGB(28, 20, 8))
		elseif entry.kind == "Pack" then
			detailStatus.Text = "✓ Owned – everything in it is yours"
			actionButton("OWNED", C.owned, 1, nil)
		else
			detailStatus.Text = "✓ In your collection"
			actionButton("OWNED", C.owned, 1, nil)
		end
		return
	end
	if entry.kind == "Item" then
		detailStatus.Text = "In your backpack: " .. (state.items[entry.id] or 0)
	end
	if entry.pack and not entry.coins then
		local pack = byId[entry.pack]
		actionButton("GET IT IN " .. (pack and pack.title:upper() or "A PACK"), C.gold, 1, function()
			if pack then
				showTab("Featured")
				select(pack)
			end
		end, Color3.fromRGB(28, 20, 8))
		return
	end
	if entry.coins then
		local afford = state.coins >= entry.coins
		actionButton("BUY  ● " .. money(entry.coins), afford and C.coins or Color3.fromRGB(70, 62, 50), 1, function()
			if state.coins < entry.coins then
				say("Not enough coins: you need " .. money(entry.coins - state.coins) .. " more.", Color3.fromRGB(240, 120, 110))
				return
			end
			buyCoins(entry)
		end)
	end
	if entry.robux then
		local robux = entry.robux
		local text = "BUY  R$ " .. money(robux)
		if entry.kind == "Starter" and entry.firstRobux then
			text = "BUY  R$ " .. entry.firstRobux .. "   (instead of " .. robux .. ")"
		end
		actionButton(text, C.robux, 2, function()
			promptRobux(entry)
		end)
	end
end

function select(entry)
	selected = entry
	for _, card in cards do
		refreshCard(card)
	end
	local rarity = ShopCatalog.RARITIES[entry.rarity or "Common"]
	detailRarity.Text = rarity and rarity.title or ""
	detailRarity.TextColor3 = rarityColor(entry)
	detailTitle.Text = entry.title
	detailText.Text = entry.description or ""
	if entry.kind == "Pack" and entry.grants then
		local names = {}
		for _, id in entry.grants do
			local granted = ShopCatalog.find(id)
			table.insert(names, granted and granted.title or id)
		end
		detailText.Text = entry.description .. "\nIncludes: " .. table.concat(names, ", ")
	end
	detailIcon.Text = entry.preview and "" or (entry.icon or "")
	detailCamera = nil
	detailView:ClearAllChildren()
	if entry.preview then
		detailIcon.Text = "…"
		task.spawn(function()
			local model = buildPreview(entry.preview)
			if selected == entry then
				detailIcon.Text = model and "" or (entry.icon or "")
				detailCamera = showInViewport(detailView, model, spinAngle)
			end
		end)
	end
	renderButtons(entry)
end

------------------------------------------------------------------ Öffnen / Schließen
local open = false
local function setOpen(value, tab, itemId)
	open = value
	overlay.Visible = value
	hud.Visible = not value
	if value then
		readData()
		showTab(tab or currentTab)
		local entry = itemId and byId[itemId]
		if entry then
			if not inTab(entry, currentTab) then
				showTab(entry.tab)
			end
			select(entry)
		elseif cards[1] then
			select(cards[1].entry)
		end
		panel.Position = UDim2.new(0.5, 0, 0.5, 30)
		TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	end
end

hudButton.Activated:Connect(function()
	setOpen(true, "Featured")
end)
-- Andere Skripte können den Shop öffnen: VipShop:SetAttribute("Open", "Snacks") (Tab oder Artikel-ID)
gui:GetAttributeChangedSignal("Open"):Connect(function()
	local target = gui:GetAttribute("Open")
	if type(target) == "string" and target ~= "" then
		gui:SetAttribute("Open", nil)
		if byId[target] then
			setOpen(true, nil, target)
		else
			setOpen(true, target)
		end
	end
end)
closeButton.Activated:Connect(function()
	setOpen(false)
end)
coinPill.Activated:Connect(function()
	showTab("Coins")
	if cards[1] then
		select(cards[1].entry)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then
		return
	end
	if CollectionService:HasTag(prompt, "VipShopPrompt") then
		setOpen(true, "Featured")
	elseif CollectionService:HasTag(prompt, "ShowroomItemPrompt") then
		setOpen(true, nil, prompt:GetAttribute("ShopItem"))
	elseif CollectionService:HasTag(prompt, "ShopPrompt") then
		setOpen(true, "Snacks")
	end
end)

-- Daten geändert (Kauf, Anziehen): alles neu anzeigen
local function onDataChanged()
	readData()
	hudCoins.Text = "● " .. money(state.coins)
	coinPill.Text = "● " .. money(state.coins) .. "   +"
	testNote.Visible = player:GetAttribute("TestCoins") == true
	if open then
		for _, card in cards do
			refreshCard(card)
		end
		if selected then
			renderButtons(selected)
		end
	end
end
player:GetAttributeChangedSignal("Coins"):Connect(onDataChanged)
player:GetAttributeChangedSignal("ShopData"):Connect(onDataChanged)
onDataChanged()

------------------------------------------------------------------ Drehen: Vorschau und Showroom
local spinning = {}
local function registerSpin(item)
	local center = item:GetAttribute("SpinCenter")
	if typeof(center) ~= "Vector3" then
		return
	end
	local pivot = item:IsA("Model") and item:GetPivot() or item.CFrame
	spinning[item] = { center = center, offset = CFrame.new(center):ToObjectSpace(pivot), speed = item:GetAttribute("SpinSpeed") or 0.5 }
end
for _, item in CollectionService:GetTagged("ShowroomSpin") do
	registerSpin(item)
end
CollectionService:GetInstanceAddedSignal("ShowroomSpin"):Connect(registerSpin)
CollectionService:GetInstanceRemovedSignal("ShowroomSpin"):Connect(function(item)
	spinning[item] = nil
end)

local lastSpin = 0
RunService.RenderStepped:Connect(function(dt)
	if open and detailCamera then
		spinAngle += dt * 0.5
		detailCamera.aim(spinAngle)
	end
	-- Showroom mit 30 Bildern pro Sekunde und nur in der Nähe drehen
	local now = os.clock()
	if now - lastSpin < 1 / 30 then
		return
	end
	lastSpin = now
	local camera = workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position or Vector3.zero
	for item, info in spinning do
		if item.Parent and (info.center - eye).Magnitude < 140 then
			local cf = CFrame.new(info.center) * CFrame.Angles(0, now * info.speed, 0) * info.offset
			if item:IsA("Model") then
				item:PivotTo(cf)
			else
				item.CFrame = cf
			end
		end
	end
end)
