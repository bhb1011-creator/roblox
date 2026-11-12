-- Abzeichen-Logos für den Shop (Gamepässe, Münz-Pakete, Coin Boost).
-- Alles aus Frames gebaut, alle Maße in Anteilen – passt sich jeder Feldgröße an.
-- ShopLogos.draw(view, id, big): legt das Logo über ein Vorschaufeld (nil entfernt es).
-- Wird vom Shop benutzt und kann in Studio im Edit-Modus einzeln getestet werden.

local ShopLogos = {}

local T = { coin = Color3.fromRGB(230, 184, 84) }

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

local LOGOS = {
	ThreeHearts = { face = { Color3.fromRGB(170, 34, 44), Color3.fromRGB(52, 6, 12) }, rim = { Color3.fromRGB(255, 214, 196), Color3.fromRGB(160, 92, 84) }, ribbon = Color3.fromRGB(236, 72, 72), ribbonText = Color3.fromRGB(255, 244, 238), label = "3 HEARTS", kicker = "GAME PASS" },
	DoubleCoins = { face = { Color3.fromRGB(176, 128, 36), Color3.fromRGB(62, 40, 8) }, rim = { Color3.fromRGB(255, 236, 170), Color3.fromRGB(150, 104, 30) }, ribbon = Color3.fromRGB(64, 40, 12), ribbonText = Color3.fromRGB(255, 226, 150), label = "2X COINS", kicker = "GAME PASS", rays = true },
	StrongFlashlight = { face = { Color3.fromRGB(52, 70, 100), Color3.fromRGB(10, 14, 24) }, rim = { Color3.fromRGB(220, 228, 240), Color3.fromRGB(100, 110, 128) }, ribbon = Color3.fromRGB(250, 226, 140), ribbonText = Color3.fromRGB(30, 34, 46), label = "FLASHLIGHT", kicker = "GAME PASS" },
	Supervision = { face = { Color3.fromRGB(38, 96, 80), Color3.fromRGB(6, 24, 20) }, rim = { Color3.fromRGB(210, 255, 232), Color3.fromRGB(84, 140, 118) }, ribbon = Color3.fromRGB(30, 60, 50), ribbonText = Color3.fromRGB(196, 255, 224), label = "SUPERVISION", kicker = "GAME PASS", rays = true },
	VipCar = { face = { Color3.fromRGB(56, 50, 56), Color3.fromRGB(8, 8, 10) }, rim = { Color3.fromRGB(255, 226, 140), Color3.fromRGB(150, 104, 30) }, ribbon = Color3.fromRGB(150, 24, 30), ribbonText = Color3.fromRGB(255, 226, 150), label = "VIP CAR", kicker = "GAME PASS", rays = true },
	Coins200 = { face = { Color3.fromRGB(150, 92, 52), Color3.fromRGB(52, 28, 14) }, rim = { Color3.fromRGB(240, 186, 140), Color3.fromRGB(130, 76, 40) }, ribbon = Color3.fromRGB(90, 52, 28), ribbonText = Color3.fromRGB(252, 220, 180), label = "200", kicker = "COINS", coins = 1 },
	Coins500 = { face = { Color3.fromRGB(120, 124, 134), Color3.fromRGB(34, 36, 42) }, rim = { Color3.fromRGB(240, 242, 248), Color3.fromRGB(130, 134, 146) }, ribbon = Color3.fromRGB(52, 56, 66), ribbonText = Color3.fromRGB(236, 240, 250), label = "500", kicker = "COINS", coins = 2 },
	Coins1500 = { face = { Color3.fromRGB(180, 130, 36), Color3.fromRGB(64, 40, 8) }, rim = { Color3.fromRGB(255, 236, 170), Color3.fromRGB(150, 104, 30) }, ribbon = Color3.fromRGB(70, 44, 10), ribbonText = Color3.fromRGB(255, 226, 150), label = "1,500", kicker = "COINS", coins = 3, rays = true },
	Coins5000 = { face = { Color3.fromRGB(92, 40, 120), Color3.fromRGB(24, 8, 36) }, rim = { Color3.fromRGB(255, 226, 140), Color3.fromRGB(150, 104, 30) }, ribbon = Color3.fromRGB(230, 182, 74), ribbonText = Color3.fromRGB(44, 16, 60), label = "5,000", kicker = "COINS", chest = true, rays = true },
	CoinBoost = { face = { Color3.fromRGB(36, 84, 150), Color3.fromRGB(8, 18, 40) }, rim = { Color3.fromRGB(200, 236, 255), Color3.fromRGB(70, 120, 170) }, ribbon = Color3.fromRGB(255, 214, 80), ribbonText = Color3.fromRGB(20, 30, 60), label = "BOOST", kicker = "2X COINS", bolt = true, rays = true },
}

local function round(frame)
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = frame })
	return frame
end

-- kleines Teil im Symbol-Feld (Position/Größe in Anteilen des Feldes)
local function shape(parent, x, y, w, h, color, z, props)
	local f = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = parent })
	for key, value in props or {} do
		f[key] = value
	end
	return f
end

local function vgrad(frame, top, bottom, rotation)
	create("UIGradient", { Rotation = rotation or 90, Color = ColorSequence.new(top, bottom), Parent = frame })
	return frame
end

-- Glanzlicht: weiße Fläche, die nach unten ausblendet
local function gloss(parent, x, y, w, h, z, strength)
	local g = round(shape(parent, x, y, w, h, Color3.new(1, 1, 1), z))
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - (strength or 0.35)), NumberSequenceKeypoint.new(1, 1) }), Parent = g })
	return g
end

local function heart(parent, x, y, size, color, z)
	local box = shape(parent, x, y, size, size, color, z, { BackgroundTransparency = 1 })
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	vgrad(round(shape(box, 0.3, 0.36, 0.52, 0.52, color, z)), color, dark)
	vgrad(round(shape(box, 0.7, 0.36, 0.52, 0.52, color, z)), color, dark)
	vgrad(shape(box, 0.5, 0.56, 0.52, 0.52, color, z, { Rotation = 45 }), color:Lerp(dark, 0.4), dark, 45)
	round(shape(box, 0.3, 0.3, 0.16, 0.12, Color3.new(1, 1, 1), z + 1, { BackgroundTransparency = 0.35, Rotation = -30 }))
	return box
end

-- Münze von vorne
local function coinFace(parent, x, y, size, z, label)
	local c = vgrad(round(shape(parent, x, y, size, size, T.coin, z)), Color3.fromRGB(255, 226, 130), Color3.fromRGB(196, 140, 40))
	create("UIStroke", { Color = Color3.fromRGB(130, 86, 24), Thickness = 2, Parent = c })
	local ring = round(shape(c, 0.5, 0.5, 0.74, 0.74, T.coin, z, { BackgroundTransparency = 1 }))
	create("UIStroke", { Color = Color3.fromRGB(150, 100, 30), Thickness = 1.5, Transparency = 0.25, Parent = ring })
	-- Riffelung am Rand
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		shape(c, 0.5 + math.cos(a) * 0.46, 0.5 + math.sin(a) * 0.46, 0.03, 0.08, Color3.fromRGB(150, 100, 30), z + 1, { Rotation = math.deg(a) + 90, BackgroundTransparency = 0.35 })
	end
	gloss(c, 0.42, 0.3, 0.5, 0.3, z + 1, 0.5)
	if not label then
		create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "★", TextScaled = true, TextColor3 = Color3.fromRGB(176, 120, 36), ZIndex = z + 2, Parent = c })
	end
	if label then
		create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromScale(0.7, 0.55), BackgroundTransparency = 1, Font = Enum.Font.Bangers, Text = label, TextScaled = true, TextColor3 = Color3.fromRGB(110, 70, 18), ZIndex = z + 2, Parent = c })
	end
	return c
end

-- Münzstapel von der Seite
local function coinStack(parent, x, bottom, width, count, z)
	for i = 0, count - 1 do
		local piece = vgrad(shape(parent, x, bottom - i * 0.075, width, 0.085, T.coin, z + i), Color3.fromRGB(255, 220, 120), Color3.fromRGB(170, 116, 30))
		create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = piece })
		create("UIStroke", { Color = Color3.fromRGB(120, 78, 20), Thickness = 1, Parent = piece })
	end
end

-- Funkeln: kleiner Stern aus zwei dünnen Strichen
local function sparkle(parent, x, y, size, color, z)
	-- weicher Schein, dann zwei spitz auslaufende Strahlen (senkrecht und waagerecht)
	local glow = round(shape(parent, x, y, size * 0.9, size * 0.9, color, z))
	create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }), Parent = glow })
	for _, r in { 0, 90 } do
		local ray = shape(parent, x, y, size * 0.09, size * 1.1, Color3.new(1, 1, 1), z + 1, { Rotation = r })
		create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = ray })
	end
	shape(parent, x, y, size * 0.2, size * 0.2, Color3.new(1, 1, 1), z + 2, { Rotation = 45 })
end

-- Linie zwischen zwei Punkten im Feld (für Zickzack, Speedlines)
local function line(parent, x1, y1, x2, y2, thick, color, z, transparency)
	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	return shape(parent, (x1 + x2) / 2, (y1 + y2) / 2, length, thick, color, z, { Rotation = math.deg(math.atan2(dy, dx)), BackgroundTransparency = transparency or 0 })
end

local ICONS = {}
function ICONS.ThreeHearts(icon, style, z)
	-- Herzschlag-Linie hinter den Herzen
	-- Herzschlag-Linie unter den Herzen
	local pulse = { { 0.04, 0.9 }, { 0.36, 0.9 }, { 0.42, 0.8 }, { 0.48, 0.98 }, { 0.54, 0.84 }, { 0.6, 0.9 }, { 0.96, 0.9 } }
	for i = 1, #pulse - 1 do
		line(icon, pulse[i][1], pulse[i][2], pulse[i + 1][1], pulse[i + 1][2], 0.03, Color3.fromRGB(255, 200, 190), z, 0.25)
	end
	heart(icon, 0.18, 0.52, 0.38, Color3.fromRGB(226, 70, 76), z)
	heart(icon, 0.82, 0.52, 0.38, Color3.fromRGB(226, 70, 76), z)
	heart(icon, 0.5, 0.42, 0.6, Color3.fromRGB(246, 70, 72), z + 2)
	sparkle(icon, 0.74, 0.18, 0.16, Color3.fromRGB(255, 220, 210), z + 4)
end
function ICONS.DoubleCoins(icon, style, z)
	coinFace(icon, 0.36, 0.56, 0.56, z, nil)
	coinFace(icon, 0.6, 0.46, 0.7, z + 3, "2x")
	for i = 0, 2 do
		line(icon, 0.02, 0.3 + i * 0.12, 0.2, 0.3 + i * 0.12, 0.03, Color3.fromRGB(255, 226, 150), z, 0.3 + i * 0.15)
	end
	sparkle(icon, 0.9, 0.16, 0.18, Color3.fromRGB(255, 240, 190), z + 8)
	sparkle(icon, 0.16, 0.86, 0.12, Color3.fromRGB(255, 240, 190), z + 8)
end
function ICONS.StrongFlashlight(icon, style, z)
	local beam = shape(icon, 0.7, 0.33, 0.95, 0.42, Color3.fromRGB(255, 240, 190), z, { Rotation = -35 })
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = beam })
	create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.7, 0.75), NumberSequenceKeypoint.new(1, 1) }), Parent = beam })
	local body = vgrad(shape(icon, 0.32, 0.68, 0.5, 0.17, Color3.fromRGB(46, 46, 52), z + 1, { Rotation = -35 }), Color3.fromRGB(90, 90, 100), Color3.fromRGB(24, 24, 28))
	create("UICorner", { CornerRadius = UDim.new(0.35, 0), Parent = body })
	for i = 0, 2 do
		shape(icon, 0.24 + i * 0.07, 0.73 - i * 0.05, 0.03, 0.16, Color3.fromRGB(20, 20, 24), z + 2, { Rotation = -35 })
	end
	vgrad(shape(icon, 0.52, 0.53, 0.2, 0.28, Color3.fromRGB(90, 90, 100), z + 1, { Rotation = -35 }), Color3.fromRGB(150, 150, 160), Color3.fromRGB(50, 50, 58))
	round(shape(icon, 0.57, 0.48, 0.15, 0.15, Color3.fromRGB(255, 250, 220), z + 3))
	-- Schalter am Griff
	vgrad(shape(icon, 0.38, 0.6, 0.07, 0.05, Color3.fromRGB(200, 40, 40), z + 3, { Rotation = -35 }), Color3.fromRGB(240, 80, 70), Color3.fromRGB(140, 20, 20))
	-- Staub im Lichtkegel
	local rng = Random.new(3)
	for _ = 1, 9 do
		round(shape(icon, rng:NextNumber(0.62, 0.98), rng:NextNumber(0.05, 0.4), 0.025, 0.025, Color3.new(1, 1, 1), z + 1, { BackgroundTransparency = rng:NextNumber(0.2, 0.6) }))
	end
end
function ICONS.Supervision(icon, style, z)
	for i = 0, 11 do
		shape(icon, 0.5, 0.5, 0.025, 1.02, style.rim[1], z, { Rotation = i * 15, BackgroundTransparency = i % 2 == 0 and 0.45 or 0.7 })
	end
	local white = vgrad(shape(icon, 0.5, 0.5, 0.84, 0.46, Color3.new(1, 1, 1), z + 1), Color3.fromRGB(250, 248, 240), Color3.fromRGB(196, 192, 182))
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = white })
	create("UIStroke", { Color = Color3.fromRGB(10, 30, 24), Thickness = 2, Parent = white })
	vgrad(round(shape(icon, 0.5, 0.5, 0.38, 0.38, Color3.fromRGB(60, 170, 120), z + 2)), Color3.fromRGB(110, 220, 160), Color3.fromRGB(20, 100, 70))
	round(shape(icon, 0.5, 0.5, 0.17, 0.17, Color3.fromRGB(8, 12, 10), z + 3))
	round(shape(icon, 0.57, 0.43, 0.07, 0.07, Color3.new(1, 1, 1), z + 4))
	-- Wimpern oben
	for i = -2, 2 do
		line(icon, 0.5 + i * 0.13, 0.27 - math.abs(i) * -0.02, 0.5 + i * 0.17, 0.13 + math.abs(i) * 0.05, 0.03, Color3.fromRGB(10, 30, 24), z + 2)
	end
	-- Spiegelung eines Gegenstands in der Pupille
	round(shape(icon, 0.45, 0.56, 0.035, 0.035, Color3.fromRGB(255, 220, 120), z + 4))
end
function ICONS.VipCar(icon, style, z)
	for i = -1, 1 do
		create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + i * 0.24, i == 0 and 0.13 or 0.2), Size = UDim2.fromScale(i == 0 and 0.24 or 0.18, i == 0 and 0.24 or 0.18), Rotation = i * 14, BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "★", TextScaled = true, TextColor3 = style.rim[1], TextStrokeColor3 = style.rim[2], TextStrokeTransparency = 0.2, ZIndex = z, Parent = icon })
	end
	local red, dark = Color3.fromRGB(196, 36, 42), Color3.fromRGB(92, 12, 16)
	local body = vgrad(shape(icon, 0.5, 0.63, 0.96, 0.21, red, z), red, dark)
	create("UICorner", { CornerRadius = UDim.new(0.4, 0), Parent = body })
	local cabin = vgrad(shape(icon, 0.46, 0.49, 0.5, 0.17, red, z), red:Lerp(Color3.new(1, 1, 1), 0.1), dark)
	create("UICorner", { CornerRadius = UDim.new(0.6, 0), Parent = cabin })
	for _, x in { 0.36, 0.56 } do
		vgrad(shape(icon, x, 0.5, 0.17, 0.09, Color3.new(1, 1, 1), z + 1), Color3.fromRGB(190, 220, 240), Color3.fromRGB(80, 110, 130))
	end
	shape(icon, 0.5, 0.6, 0.88, 0.02, Color3.fromRGB(255, 220, 140), z + 1, { BackgroundTransparency = 0.3 })
	round(shape(icon, 0.95, 0.6, 0.07, 0.06, Color3.fromRGB(255, 244, 200), z + 2))
	-- Lichtkegel des Scheinwerfers
	local glow = shape(icon, 1.08, 0.6, 0.26, 0.14, Color3.fromRGB(255, 240, 190), z + 1)
	create("UIGradient", { Transparency = NumberSequence.new(0.3, 1), Parent = glow })
	-- Fahrtwind hinter dem Auto
	for i = 0, 2 do
		line(icon, -0.12, 0.54 + i * 0.07, 0.02, 0.54 + i * 0.07, 0.025, style.rim[1], z, 0.3 + i * 0.2)
	end
	-- Nummernschild „VIP“
	local plate = shape(icon, 0.5, 0.7, 0.2, 0.08, Color3.fromRGB(240, 236, 220), z + 2)
	create("UIStroke", { Color = Color3.fromRGB(30, 30, 30), Thickness = 1, Parent = plate })
	create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "VIP", TextScaled = true, TextColor3 = Color3.fromRGB(30, 30, 30), ZIndex = z + 3, Parent = plate })
	for _, x in { 0.26, 0.74 } do
		round(shape(icon, x, 0.75, 0.2, 0.2, Color3.fromRGB(16, 16, 18), z + 2))
		vgrad(round(shape(icon, x, 0.75, 0.1, 0.1, style.rim[1], z + 3)), style.rim[1], style.rim[2])
	end
end
-- Münz-Pakete: mehr Münzen, je größer das Paket
local function coinsIcon(icon, style, z)
	if style.chest then
		-- Schatztruhe voller Münzen
		coinFace(icon, 0.3, 0.3, 0.3, z, nil)
		coinFace(icon, 0.55, 0.24, 0.34, z + 1, nil)
		coinFace(icon, 0.74, 0.34, 0.28, z, nil)
		local chest = vgrad(shape(icon, 0.5, 0.66, 0.84, 0.44, Color3.fromRGB(120, 70, 36), z + 3), Color3.fromRGB(150, 92, 50), Color3.fromRGB(70, 38, 18))
		create("UICorner", { CornerRadius = UDim.new(0.12, 0), Parent = chest })
		create("UIStroke", { Color = Color3.fromRGB(40, 20, 8), Thickness = 2, Parent = chest })
		for _, x in { 0.16, 0.84 } do
			vgrad(shape(icon, x, 0.66, 0.07, 0.44, T.coin, z + 4), Color3.fromRGB(255, 220, 120), Color3.fromRGB(160, 110, 30))
		end
		vgrad(shape(icon, 0.5, 0.5, 0.86, 0.06, T.coin, z + 4), Color3.fromRGB(255, 220, 120), Color3.fromRGB(160, 110, 30))
		-- Lichtschein aus der Truhe und Edelsteine
		local shine = round(shape(icon, 0.5, 0.36, 0.95, 0.7, Color3.fromRGB(255, 230, 150), z - 1))
		create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1) }), Parent = shine })
		for i, color in { Color3.fromRGB(220, 40, 60), Color3.fromRGB(60, 140, 240), Color3.fromRGB(60, 200, 120) } do
			shape(icon, 0.24 + (i - 1) * 0.26, 0.82, 0.08, 0.08, color, z + 5, { Rotation = 45 })
		end
		sparkle(icon, 0.84, 0.12, 0.16, Color3.fromRGB(255, 240, 190), z + 6)
		sparkle(icon, 0.16, 0.2, 0.12, Color3.fromRGB(255, 240, 190), z + 6)
		local lock = vgrad(shape(icon, 0.5, 0.6, 0.14, 0.16, T.coin, z + 5), Color3.fromRGB(255, 226, 130), Color3.fromRGB(170, 116, 30))
		create("UICorner", { CornerRadius = UDim.new(0.25, 0), Parent = lock })
		round(shape(lock, 0.5, 0.45, 0.32, 0.32, Color3.fromRGB(50, 30, 10), z + 6))
	elseif style.bolt then
		coinFace(icon, 0.42, 0.56, 0.68, z, "2x")
		-- Blitz: drei Striche im Zickzack, dunkler Rand darunter
		local bolt = { { 0.86, 0.08 }, { 0.7, 0.4 }, { 0.86, 0.4 }, { 0.68, 0.76 } }
		for i = 1, #bolt - 1 do
			local a, b = bolt[i], bolt[i + 1]
			line(icon, a[1], a[2], b[1], b[2], 0.13, Color3.fromRGB(120, 60, 10), z + 4)
		end
		for i = 1, #bolt - 1 do
			local a, b = bolt[i], bolt[i + 1]
			vgrad(line(icon, a[1], a[2], b[1], b[2], 0.08, Color3.new(1, 1, 1), z + 5), Color3.fromRGB(255, 248, 170), Color3.fromRGB(250, 180, 40))
		end
		-- elektrische Funken um die Münze
		for _, seg in { { 0.08, 0.3, 0.16, 0.22 }, { 0.16, 0.22, 0.12, 0.14 }, { 0.06, 0.8, 0.16, 0.88 }, { 0.16, 0.88, 0.12, 0.96 } } do
			line(icon, seg[1], seg[2], seg[3], seg[4], 0.03, Color3.fromRGB(170, 230, 255), z + 2)
		end
	else
		local n = style.coins or 1
		sparkle(icon, 0.86, 0.16, 0.14, Color3.fromRGB(255, 244, 210), z + 12)
		if n == 1 then
			coinFace(icon, 0.5, 0.5, 0.78, z, nil)
		elseif n == 2 then
			coinStack(icon, 0.3, 0.84, 0.42, 4, z)
			coinFace(icon, 0.6, 0.48, 0.66, z + 6, nil)
		else
			coinStack(icon, 0.22, 0.86, 0.36, 5, z)
			coinStack(icon, 0.78, 0.86, 0.36, 6, z)
			coinFace(icon, 0.5, 0.44, 0.66, z + 8, nil)
		end
	end
end

-- Logo in ein „Foto“-Feld legen (über dem leeren Vorschaufenster); nil entfernt es
local function passLogo(view, id, big)
	local back = view.Parent
	local old = back:FindFirstChild("Logo")
	if old then
		old:Destroy()
	end
	local style = id and LOGOS[id]
	if not style then
		return
	end
	back.ClipsDescendants = true -- Strahlen nicht über den Rand
	local z = view.ZIndex + 1
	local holder = create("Frame", { Name = "Logo", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z, Parent = back })
	-- quadratische Fläche in der Mitte (alles darin in Anteilen)
	local area = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.92, 0.92), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = z, Parent = holder })
	if style.rays then
		for i = 0, 11 do
			shape(area, 0.5, 0.5, 0.05, 1.5, style.rim[1], z, { Rotation = i * 15, BackgroundTransparency = 0.88 })
		end
	end
	-- Schatten unter dem Abzeichen
	round(shape(area, 0.52, 0.54, 0.9, 0.9, Color3.new(0, 0, 0), z, { BackgroundTransparency = 0.55 }))
	-- Metallrand mit Glanz
	local rim = round(shape(area, 0.5, 0.5, 0.9, 0.9, Color3.new(1, 1, 1), z))
	create("UIGradient", { Rotation = 135, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, style.rim[1]), ColorSequenceKeypoint.new(0.5, style.rim[2]), ColorSequenceKeypoint.new(1, style.rim[1]:Lerp(style.rim[2], 0.5)) }), Parent = rim })
	-- dunkler Innenring, dann das Gesicht
	local inner = round(shape(rim, 0.5, 0.5, 0.86, 0.86, style.face[2]:Lerp(Color3.new(0, 0, 0), 0.4), z))
	local face = round(shape(inner, 0.5, 0.5, 0.95, 0.95, Color3.new(1, 1, 1), z))
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(style.face[1], style.face[2]), Parent = face })
	-- Nieten rundum im Metallrand
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2 - math.pi / 2
		local rivet = round(shape(rim, 0.5 + math.cos(a) * 0.465, 0.5 + math.sin(a) * 0.465, 0.035, 0.035, style.rim[2], z + 1))
		create("UIGradient", { Rotation = 135, Color = ColorSequence.new(style.rim[1], style.rim[2]:Lerp(Color3.new(0, 0, 0), 0.4)), Parent = rivet })
	end
	-- feine gravierte Schräglinien im Gesicht
	face.ClipsDescendants = true
	for i = -4, 4 do
		shape(face, 0.5 + i * 0.13, 0.5, 0.012, 1.6, Color3.new(1, 1, 1), z, { Rotation = 30, BackgroundTransparency = 0.93 })
	end
	local ring = round(shape(face, 0.5, 0.5, 0.88, 0.88, Color3.new(1, 1, 1), z, { BackgroundTransparency = 1 }))
	create("UIStroke", { Color = style.rim[1], Thickness = big and 2 or 1, Transparency = 0.55, Parent = ring })
	-- kleine Kopfzeile oben im Ring
	create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromScale(0.5, 0.09), BackgroundTransparency = 1, Font = Enum.Font.Oswald, Text = style.kicker, TextScaled = true, TextColor3 = style.rim[1], TextTransparency = 0.15, ZIndex = z + 1, Parent = face })
	-- Symbol
	local icon = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.6, 0.6), BackgroundTransparency = 1, ZIndex = z + 1, Parent = face })
	if ICONS[id] then
		ICONS[id](icon, style, z + 1)
	else
		coinsIcon(icon, style, z + 1)
	end
	-- Glanzlicht oben auf dem Abzeichen
	gloss(face, 0.5, 0.24, 0.78, 0.42, z + 12, 0.18)
	-- Banner mit gefalteten Enden
	for _, side in { -1, 1 } do
		-- Bandende: zwei schräge Hälften ergeben eine Schwalbenschwanz-Kerbe
		local tailColor = style.ribbon:Lerp(Color3.new(0, 0, 0), 0.35)
		for _, half in { -1, 1 } do
			vgrad(shape(area, 0.5 + side * 0.44, 0.84 + half * 0.035, 0.15, 0.075, tailColor, z + 13, { Rotation = side * half * -12 }), tailColor, style.ribbon:Lerp(Color3.new(0, 0, 0), 0.55))
		end
		-- Falte, wo das Band nach hinten läuft
		shape(area, 0.5 + side * 0.39, 0.87, 0.05, 0.06, style.ribbon:Lerp(Color3.new(0, 0, 0), 0.7), z + 14, { Rotation = 45 })
	end
	local banner = vgrad(shape(area, 0.5, 0.79, 0.86, 0.17, style.ribbon, z + 15), style.ribbon:Lerp(Color3.new(1, 1, 1), 0.18), style.ribbon:Lerp(Color3.new(0, 0, 0), 0.15))
	create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = banner })
	create("UIStroke", { Color = style.ribbon:Lerp(Color3.new(0, 0, 0), 0.5), Thickness = big and 2 or 1, Parent = banner })
	shape(banner, 0.5, 0.12, 0.94, 0.06, Color3.new(1, 1, 1), z + 16, { BackgroundTransparency = 0.7 })
	-- Naht oben und unten am Banner
	for _, y in { 0.2, 0.82 } do
		for i = 0, 13 do
			shape(banner, 0.06 + i * 0.068, y, 0.04, 0.05, style.ribbonText, z + 16, { BackgroundTransparency = 0.55 })
		end
	end
	-- kleine Sterne links und rechts vom Namen
	for _, x in { 0.07, 0.93 } do
		create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.52), Size = UDim2.fromScale(0.08, 0.5), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "★", TextScaled = true, TextColor3 = style.ribbonText, TextTransparency = 0.25, ZIndex = z + 17, Parent = banner })
	end
	create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.54), Size = UDim2.fromScale(0.74, 0.8), BackgroundTransparency = 1, Font = Enum.Font.Oswald, Text = style.label, TextScaled = true, TextColor3 = style.ribbonText, ZIndex = z + 17, Parent = banner })
	return holder
end

ShopLogos.LOGOS = LOGOS
ShopLogos.draw = passLogo
return ShopLogos
