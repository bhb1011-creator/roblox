-- Möbel und Gegenstände für das Haus der Wagners (Kapitel 2).
-- Jede Funktion bekommt `b` (Bauhelfer aus Mansion: b.box, b.ball, b.cyl, b.candle) und
-- `cf` = Stelle auf dem Boden. Die Vorderseite eines Möbels zeigt nach -Z (LookVector),
-- also dorthin, wo man davor steht oder sitzt.
local Furniture = {}

local C = {
	wood = Color3.fromRGB(70, 50, 36),
	darkWood = Color3.fromRGB(46, 33, 24),
	lightWood = Color3.fromRGB(110, 84, 60),
	sheet = Color3.fromRGB(190, 184, 170), -- weiße Tücher über den Möbeln
	fabricRed = Color3.fromRGB(96, 36, 34),
	fabricGreen = Color3.fromRGB(52, 66, 50),
	brass = Color3.fromRGB(120, 96, 52),
	metal = Color3.fromRGB(70, 72, 74),
	paper = Color3.fromRGB(214, 206, 186),
	black = Color3.fromRGB(16, 14, 12),
	stone = Color3.fromRGB(86, 82, 76),
	porcelain = Color3.fromRGB(200, 196, 186),
	glass = Color3.fromRGB(40, 48, 50),
	blood = Color3.fromRGB(96, 18, 16),
}
Furniture.C = C

local M = Enum.Material

function Furniture.rug(b, cf, w, d, color, border)
	b.box("RugBorder", Vector3.new(w, 0.03, d), cf * CFrame.new(0, 0.015, 0), border or Color3.fromRGB(46, 26, 22), M.Fabric)
	b.box("Rug", Vector3.new(w - 0.5, 0.03, d - 0.5), cf * CFrame.new(0, 0.045, 0), color, M.Fabric)
end

function Furniture.table(b, cf, w, d, h, color)
	h = h or 2.9
	color = color or C.wood
	b.box("TableTop", Vector3.new(w, 0.18, d), cf * CFrame.new(0, h - 0.09, 0), color, M.Wood)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			b.box("TableLeg", Vector3.new(0.22, h - 0.18, 0.22), cf * CFrame.new(x * (w / 2 - 0.3), (h - 0.18) / 2, z * (d / 2 - 0.3)), C.darkWood, M.Wood)
		end
	end
	return cf * CFrame.new(0, h, 0) -- Tischplatte (für Sachen obendrauf)
end

function Furniture.chair(b, cf, color)
	color = color or C.darkWood
	b.box("ChairSeat", Vector3.new(1.6, 0.2, 1.6), cf * CFrame.new(0, 1.8, 0), color, M.Wood)
	b.box("ChairBack", Vector3.new(1.6, 2.4, 0.2), cf * CFrame.new(0, 3.1, 0.7), color, M.Wood)
	for _, x in { -0.65, 0.65 } do
		for _, z in { -0.65, 0.65 } do
			b.box("ChairLeg", Vector3.new(0.16, 1.7, 0.16), cf * CFrame.new(x, 0.85, z), color, M.Wood)
		end
	end
end

-- Sessel oder Sofa, optional unter einem weißen Tuch
function Furniture.sofa(b, cf, w, color, covered)
	local fabric = covered and C.sheet or color
	local mat = M.Fabric
	b.box("SofaSeat", Vector3.new(w, 1.2, 2.6), cf * CFrame.new(0, 1.2, 0), fabric, mat)
	b.box("SofaBack", Vector3.new(w, 2.4, 0.8), cf * CFrame.new(0, 2.4, 1.0), fabric, mat)
	for _, x in { -1, 1 } do
		b.box("SofaArm", Vector3.new(0.7, 1.9, 2.6), cf * CFrame.new(x * (w / 2 - 0.35), 1.55, 0), fabric, mat)
	end
	if not covered then
		-- Sockel mit kurzen Füßen
		b.box("SofaBase", Vector3.new(w - 0.1, 0.45, 2.4), cf * CFrame.new(0, 0.37, 0), C.darkWood, M.Wood)
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				b.box("SofaFoot", Vector3.new(0.25, 0.16, 0.25), cf * CFrame.new(x * (w / 2 - 0.3), 0.08, z * 1.0), C.darkWood, M.Wood)
			end
		end
	end
	if covered then
		-- das Tuch hängt bis auf den Boden
		b.box("Sheet", Vector3.new(w + 0.2, 0.6, 3.0), cf * CFrame.new(0, 0.3, -0.1), C.sheet, mat)
	end
end

function Furniture.bed(b, cf, w, l, sheet, frame)
	frame = frame or C.darkWood
	b.box("BedFrame", Vector3.new(w, 1.2, l), cf * CFrame.new(0, 0.9, 0), frame, M.Wood)
	b.box("Mattress", Vector3.new(w - 0.2, 0.6, l - 0.3), cf * CFrame.new(0, 1.8, -0.1), Color3.fromRGB(200, 194, 180), M.Fabric)
	b.box("Blanket", Vector3.new(w - 0.1, 0.25, l * 0.62), cf * CFrame.new(0, 2.15, -l * 0.18), sheet, M.Fabric)
	b.box("Pillow", Vector3.new(w * 0.7, 0.4, 1.1), cf * CFrame.new(0, 2.3, l / 2 - 0.9), Color3.fromRGB(214, 208, 196), M.Fabric)
	b.box("Headboard", Vector3.new(w, 2.9, 0.3), cf * CFrame.new(0, 1.45, l / 2 + 0.1), frame, M.Wood) -- bleibt unter der Fensterbank
end

function Furniture.nightstand(b, cf)
	b.box("Nightstand", Vector3.new(1.6, 2.2, 1.4), cf * CFrame.new(0, 1.1, 0), C.wood, M.Wood)
	b.box("Drawer", Vector3.new(1.3, 0.6, 0.06), cf * CFrame.new(0, 1.5, -0.72), C.darkWood, M.Wood)
	return cf * CFrame.new(0, 2.2, 0)
end

function Furniture.wardrobe(b, cf, w)
	w = w or 4
	b.box("Wardrobe", Vector3.new(w, 7.2, 2), cf * CFrame.new(0, 3.6, 0), C.darkWood, M.Wood)
	b.box("WardrobeLine", Vector3.new(0.06, 6.6, 0.06), cf * CFrame.new(0, 3.6, -1.02), C.black, M.Wood)
	for _, x in { -0.3, 0.3 } do
		b.box("WardrobeKnob", Vector3.new(0.16, 0.16, 0.16), cf * CFrame.new(x, 3.8, -1.08), C.brass, M.Metal)
	end
	b.box("WardrobeTop", Vector3.new(w + 0.3, 0.3, 2.3), cf * CFrame.new(0, 7.35, 0), C.wood, M.Wood)
end

-- Regal mit Büchern oder Einmachgläsern
function Furniture.shelf(b, cf, w, h, kind, rng)
	h = h or 7
	b.box("ShelfBack", Vector3.new(w, h, 0.15), cf * CFrame.new(0, h / 2, 0.6), C.darkWood, M.Wood)
	for _, x in { -1, 1 } do
		b.box("ShelfSide", Vector3.new(0.2, h, 1.3), cf * CFrame.new(x * (w / 2 - 0.1), h / 2, 0), C.darkWood, M.Wood)
	end
	local rows = math.floor(h / 1.6)
	for r = 0, rows do
		local y = 0.2 + r * (h - 0.4) / rows
		b.box("ShelfBoard", Vector3.new(w - 0.3, 0.12, 1.2), cf * CFrame.new(0, y, 0), C.wood, M.Wood)
		if r < rows then
			local x = -w / 2 + 0.4
			while x < w / 2 - 0.5 do
				if kind == "jars" then
					local glass = rng:NextNumber() < 0.5 and Color3.fromRGB(120, 60, 40) or Color3.fromRGB(90, 100, 50)
					b.cyl("Jar", 0.7, 0.45, cf * CFrame.new(x + 0.25, y + 0.06, 0), glass, M.Glass, { Transparency = 0.15 })
					x += 0.65
				else
					local thick = rng:NextNumber(0.18, 0.35)
					local tall = rng:NextNumber(0.9, 1.3)
					local tint = rng:NextNumber(0.4, 1)
					b.box("Book", Vector3.new(thick, tall, 0.9), cf * CFrame.new(x + thick / 2, y + 0.06 + tall / 2, 0.05), Color3.fromRGB(60 * tint + 30, 40 * tint + 20, 30 * tint + 18), M.Fabric)
					x += thick + 0.03
				end
			end
		end
	end
end

-- Bild an der Wand; `cf` = Mitte des Bildes, Rückseite an der Wand (+Z)
function Furniture.picture(b, cf, w, h, color, scratched)
	b.box("PictureFrame", Vector3.new(w, h, 0.12), cf, C.brass, M.Metal)
	b.box("Picture", Vector3.new(w - 0.3, h - 0.3, 0.04), cf * CFrame.new(0, 0, -0.07), color or Color3.fromRGB(70, 62, 50), M.SmoothPlastic)
	if scratched then
		for i = 1, 3 do
			b.box("Scratch", Vector3.new(0.05, h * 0.35, 0.02), cf * CFrame.new(-0.15 + i * 0.1, h * 0.12, -0.1) * CFrame.Angles(0, 0, math.rad(25 - i * 15)), C.black)
		end
	end
end

-- Kinderzeichnung: Familie (vier kleine Figuren) und daneben ein großer schwarzer Mann
function Furniture.drawing(b, cf)
	b.box("Drawing", Vector3.new(1.6, 1.2, 0.02), cf, C.paper, M.SmoothPlastic)
	local function figure(x, height, color)
		b.box("DrawLine", Vector3.new(0.05, height, 0.01), cf * CFrame.new(x, -0.45 + height / 2, -0.015), color)
		b.box("DrawHead", Vector3.new(0.14, 0.14, 0.01), cf * CFrame.new(x, -0.45 + height + 0.07, -0.015), color)
	end
	for i, h in { 0.35, 0.33, 0.22, 0.18 } do
		figure(-0.65 + i * 0.18, h, Color3.fromRGB(60, 80, 140))
	end
	figure(0.45, 0.75, C.black)
	b.box("DrawArm", Vector3.new(0.4, 0.04, 0.01), cf * CFrame.new(0.3, 0.05, -0.015) * CFrame.Angles(0, 0, math.rad(-20)), C.black)
	b.box("DrawEyes", Vector3.new(0.12, 0.03, 0.01), cf * CFrame.new(0.45, 0.42, -0.02), C.blood)
end

function Furniture.fireplace(b, cf)
	b.box("FireplaceStone", Vector3.new(6.5, 5.2, 1.6), cf * CFrame.new(0, 2.6, 0.2), C.stone, M.Slate)
	b.box("FireplaceHole", Vector3.new(3.6, 3, 1.0), cf * CFrame.new(0, 1.6, -0.25), C.black, M.SmoothPlastic)
	b.box("Mantel", Vector3.new(7.2, 0.35, 2.1), cf * CFrame.new(0, 5.3, 0), C.darkWood, M.Wood)
	b.box("Ash", Vector3.new(3, 0.2, 0.8), cf * CFrame.new(0, 0.2, -0.3), Color3.fromRGB(60, 58, 56), M.Sand)
	for _, x in { -2.6, 2.6 } do
		b.cyl("Candlestick", 1, 0.3, cf * CFrame.new(x, 5.48, -0.2), C.brass, M.Metal)
	end
end

function Furniture.piano(b, cf)
	b.box("PianoBody", Vector3.new(5.2, 4.2, 2), cf * CFrame.new(0, 2.1, 0), C.black, M.SmoothPlastic, { Reflectance = 0.05 })
	b.box("PianoKeys", Vector3.new(4.6, 0.15, 0.9), cf * CFrame.new(0, 2.6, -1.4), Color3.fromRGB(220, 214, 200), M.SmoothPlastic)
	for i = 0, 15 do
		b.box("BlackKey", Vector3.new(0.12, 0.1, 0.5), cf * CFrame.new(-2.1 + i * 0.28, 2.72, -1.2), C.black)
	end
	b.box("KeyShelf", Vector3.new(5.0, 0.3, 1.0), cf * CFrame.new(0, 2.4, -1.4), C.black, M.SmoothPlastic)
	b.box("SheetMusic", Vector3.new(1.4, 1.0, 0.04), cf * CFrame.new(0, 3.9, -1.0) * CFrame.Angles(math.rad(-15), 0, 0), C.paper)
	-- Klavierbank
	b.box("PianoBench", Vector3.new(3, 0.3, 1.2), cf * CFrame.new(0, 1.7, -3.2), C.black, M.SmoothPlastic)
	for _, x in { -1.2, 1.2 } do
		b.box("BenchLeg", Vector3.new(0.2, 1.6, 0.9), cf * CFrame.new(x, 0.8, -3.2), C.black)
	end
end

function Furniture.desk(b, cf, rng)
	local top = Furniture.table(b, cf, 5, 2.6, 2.9, C.darkWood)
	for i = 1, 6 do
		b.box("Paper", Vector3.new(0.85, 0.02, 1.1), top * CFrame.new(rng:NextNumber(-1.8, 1.2), 0.02 + i * 0.01, rng:NextNumber(-0.6, 0.5)) * CFrame.Angles(0, rng:NextNumber(-0.6, 0.6), 0), C.paper)
	end
	b.cyl("LampBase", 0.15, 0.6, top * CFrame.new(1.8, 0, 0.6), C.brass, M.Metal)
	b.box("LampStem", Vector3.new(0.08, 1.2, 0.08), top * CFrame.new(1.8, 0.7, 0.6), C.brass, M.Metal)
	b.box("LampShade", Vector3.new(0.7, 0.4, 0.7), top * CFrame.new(1.8, 1.3, 0.6), Color3.fromRGB(40, 70, 40), M.Glass)
	Furniture.chair(b, cf * CFrame.new(0, 0, 2.2) * CFrame.Angles(0, math.pi, 0))
end

function Furniture.counter(b, cf, w)
	b.box("Counter", Vector3.new(w, 3, 2), cf * CFrame.new(0, 1.5, 0), Color3.fromRGB(92, 84, 70), M.Wood)
	b.box("CounterTop", Vector3.new(w + 0.1, 0.2, 2.2), cf * CFrame.new(0, 3.1, -0.05), Color3.fromRGB(140, 134, 120), M.Marble)
	for x = -w / 2 + 1, w / 2 - 1, 2 do
		b.box("CabinetLine", Vector3.new(0.05, 2.4, 0.04), cf * CFrame.new(x + 1, 1.5, -1.02), C.darkWood)
	end
end

function Furniture.sink(b, cf)
	b.box("SinkBasin", Vector3.new(2.2, 0.5, 1.5), cf * CFrame.new(0, 3.0, -0.1), C.porcelain, M.SmoothPlastic)
	b.box("SinkHole", Vector3.new(1.8, 0.05, 1.1), cf * CFrame.new(0, 3.26, -0.1), Color3.fromRGB(110, 106, 98))
	b.box("Tap", Vector3.new(0.15, 0.7, 0.15), cf * CFrame.new(0, 3.6, 0.55), C.metal, M.Metal)
	b.box("TapSpout", Vector3.new(0.12, 0.12, 0.5), cf * CFrame.new(0, 3.9, 0.35), C.metal, M.Metal)
end

function Furniture.stove(b, cf)
	b.box("Stove", Vector3.new(3, 3, 2.2), cf * CFrame.new(0, 1.5, 0), Color3.fromRGB(36, 34, 32), M.Metal)
	b.box("StoveDoor", Vector3.new(1.8, 1.2, 0.06), cf * CFrame.new(0, 1.2, -1.12), Color3.fromRGB(24, 22, 20), M.Metal)
	for _, x in { -0.7, 0.7 } do
		b.cyl("Pot", 0.8, 1.0, cf * CFrame.new(x, 3.0, 0), C.metal, M.Metal)
	end
	b.box("StovePipe", Vector3.new(0.5, 6, 0.5), cf * CFrame.new(0, 6, 0.8), Color3.fromRGB(30, 28, 26), M.Metal)
end

function Furniture.fridge(b, cf)
	b.box("Fridge", Vector3.new(2.6, 6, 2.2), cf * CFrame.new(0, 3, 0), Color3.fromRGB(196, 190, 170), M.SmoothPlastic)
	b.box("FridgeHandle", Vector3.new(0.15, 1.2, 0.15), cf * CFrame.new(0.9, 4, -1.15), C.metal, M.Metal)
	b.box("FridgeLine", Vector3.new(2.5, 0.05, 0.04), cf * CFrame.new(0, 4.2, -1.11), Color3.fromRGB(120, 116, 104))
end

function Furniture.bathtub(b, cf)
	b.box("Tub", Vector3.new(2.8, 1.8, 5.6), cf * CFrame.new(0, 1.3, 0), C.porcelain, M.SmoothPlastic)
	b.box("TubInside", Vector3.new(2.2, 0.1, 5.0), cf * CFrame.new(0, 2.2, 0), Color3.fromRGB(70, 60, 50), M.SmoothPlastic)
	for _, x in { -1, 1 } do
		for _, z in { -2.4, 2.4 } do
			b.ball("TubFoot", 0.5, cf * CFrame.new(x * 1.1, 0.25, z), C.brass, M.Metal)
		end
	end
end

function Furniture.toilet(b, cf)
	b.box("ToiletBowl", Vector3.new(1.3, 1.4, 1.8), cf * CFrame.new(0, 0.7, -0.2), C.porcelain, M.SmoothPlastic)
	b.box("ToiletTank", Vector3.new(1.6, 1.8, 0.7), cf * CFrame.new(0, 1.9, 0.6), C.porcelain, M.SmoothPlastic)
	b.box("ToiletSeat", Vector3.new(1.4, 0.12, 1.7), cf * CFrame.new(0, 1.46, -0.25), C.darkWood, M.Wood)
end

function Furniture.mirror(b, cf, scratched)
	b.box("MirrorFrame", Vector3.new(1.8, 2.4, 0.12), cf, C.brass, M.Metal)
	b.box("Mirror", Vector3.new(1.5, 2.1, 0.04), cf * CFrame.new(0, 0, -0.07), Color3.fromRGB(150, 160, 162), M.Glass, { Reflectance = 0.4 })
	if scratched then
		for i = 1, 4 do
			b.box("Scratch", Vector3.new(0.04, 1.4, 0.02), cf * CFrame.new(-0.45 + i * 0.18, 0, -0.1) * CFrame.Angles(0, 0, math.rad(18 - i * 9)), C.black)
		end
	end
end

function Furniture.rockingHorse(b, cf)
	b.box("HorseBody", Vector3.new(0.9, 1.0, 2.4), cf * CFrame.new(0, 2.0, 0), Color3.fromRGB(150, 120, 90), M.Wood)
	b.box("HorseHead", Vector3.new(0.7, 1.3, 0.9), cf * CFrame.new(0, 2.8, -1.3) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(150, 120, 90), M.Wood)
	b.box("HorseMane", Vector3.new(0.3, 1.2, 0.4), cf * CFrame.new(0, 3.0, -0.95) * CFrame.Angles(math.rad(-20), 0, 0), C.darkWood, M.Fabric)
	for _, x in { -0.55, 0.55 } do
		b.box("Rocker", Vector3.new(0.2, 0.3, 3.4), cf * CFrame.new(x, 0.15, 0), C.darkWood, M.Wood)
		for _, z in { -0.8, 0.8 } do
			b.box("HorseLeg", Vector3.new(0.2, 1.4, 0.2), cf * CFrame.new(x, 1.0, z), Color3.fromRGB(150, 120, 90), M.Wood)
		end
	end
	b.ball("HorseEye", 0.14, cf * CFrame.new(0.36, 3.1, -1.55), C.black)
end

function Furniture.doll(b, cf, dress)
	b.box("DollBody", Vector3.new(0.35, 0.5, 0.25), cf * CFrame.new(0, 0.25, 0), dress, M.Fabric)
	b.ball("DollHead", 0.32, cf * CFrame.new(0, 0.66, 0), C.porcelain, M.SmoothPlastic)
	b.box("DollEyes", Vector3.new(0.2, 0.04, 0.02), cf * CFrame.new(0, 0.7, -0.16), C.black)
end

function Furniture.dollhouse(b, cf)
	b.box("Dollhouse", Vector3.new(2.6, 2.2, 1.4), cf * CFrame.new(0, 1.1, 0), Color3.fromRGB(150, 120, 110), M.Wood)
	b.box("DollhouseRoof", Vector3.new(2.9, 0.3, 1.6), cf * CFrame.new(0, 2.4, 0), Color3.fromRGB(70, 50, 50), M.Wood)
	for _, x in { -0.7, 0.7 } do
		b.box("DollhouseWindow", Vector3.new(0.5, 0.5, 0.04), cf * CFrame.new(x, 1.5, -0.72), C.black)
	end
end

function Furniture.toyBox(b, cf)
	b.box("ToyBox", Vector3.new(2.6, 1.6, 1.6), cf * CFrame.new(0, 0.8, 0), Color3.fromRGB(120, 50, 40), M.Wood)
	b.box("ToyBoxLid", Vector3.new(2.7, 0.2, 1.7), cf * CFrame.new(0, 1.9, 0.5) * CFrame.Angles(math.rad(-50), 0, 0), Color3.fromRGB(110, 46, 36), M.Wood)
	for i, color in { Color3.fromRGB(160, 40, 40), Color3.fromRGB(40, 90, 160), Color3.fromRGB(200, 170, 40) } do
		b.box("Block", Vector3.new(0.5, 0.5, 0.5), cf * CFrame.new(-1.8 + i * 0.7, 0.25, -1.6) * CFrame.Angles(0, i, 0), color, M.Wood)
	end
end

function Furniture.sewing(b, cf)
	local top = Furniture.table(b, cf, 3.2, 1.8, 2.8, C.darkWood)
	b.box("SewingMachine", Vector3.new(1.6, 0.9, 0.7), top * CFrame.new(0, 0.45, 0.2), C.black, M.Metal)
	b.box("SewingArm", Vector3.new(0.3, 0.4, 0.7), top * CFrame.new(-0.6, 1.0, 0.2), C.black, M.Metal)
	-- Schneiderpuppe ohne Kopf
	local d = cf * CFrame.new(2.6, 0, 0)
	b.cyl("MannequinPole", 3.2, 0.15, d, C.darkWood, M.Wood)
	b.box("MannequinBody", Vector3.new(1.4, 2.0, 0.9), d * CFrame.new(0, 4.0, 0), Color3.fromRGB(150, 134, 120), M.Fabric)
	b.box("MannequinDress", Vector3.new(1.7, 1.4, 1.1), d * CFrame.new(0, 2.8, 0), Color3.fromRGB(110, 40, 40), M.Fabric)
end

function Furniture.boiler(b, cf)
	b.cyl("Boiler", 6, 3.2, cf, Color3.fromRGB(60, 54, 48), M.Metal)
	b.box("BoilerDoor", Vector3.new(1.2, 1.0, 0.1), cf * CFrame.new(0, 1.4, -1.62), Color3.fromRGB(30, 26, 22), M.Metal)
	b.box("BoilerGlow", Vector3.new(0.8, 0.2, 0.05), cf * CFrame.new(0, 1.1, -1.68), Color3.fromRGB(150, 50, 20), M.Neon)
	for _, x in { -0.8, 0.8 } do
		b.box("Pipe", Vector3.new(0.35, 4, 0.35), cf * CFrame.new(x, 8, 0), C.metal, M.Metal)
	end
	b.box("CoalPile", Vector3.new(2.5, 0.8, 2), cf * CFrame.new(3, 0.4, -1), Color3.fromRGB(20, 20, 20), M.Slate)
end

function Furniture.washtub(b, cf)
	b.cyl("Washtub", 1.6, 2.4, cf, Color3.fromRGB(110, 112, 110), M.Metal)
	b.box("Washboard", Vector3.new(1.1, 1.8, 0.12), cf * CFrame.new(0, 1.8, 0.7) * CFrame.Angles(math.rad(15), 0, 0), C.lightWood, M.Wood)
end

-- Wäscheleine zwischen zwei Punkten (auf Höhe `y`) mit hängenden Laken
function Furniture.clothesline(b, from, to, rng)
	b.beam("Clothesline", from, to, 0.05, Color3.fromRGB(160, 150, 130))
	local length = (to - from).Magnitude
	for i = 1, math.floor(length / 3) do
		local t = (i - 0.5) / math.floor(length / 3)
		local at = from:Lerp(to, t)
		-- das Laken hängt über der Leine (Oberkante knapp darüber)
		local sheetHeight = rng:NextNumber(2.2, 3.4)
		b.boxWorld("HangingSheet", Vector3.new(2.2, sheetHeight, 0.05), CFrame.lookAt(at, at + (to - from):Cross(Vector3.yAxis)) * CFrame.new(0, -sheetHeight / 2 + 0.05, 0), C.sheet, M.Fabric)
	end
end

function Furniture.altar(b, cf)
	b.box("Altar", Vector3.new(4.5, 3, 2.2), cf * CFrame.new(0, 1.5, 0), Color3.fromRGB(50, 46, 44), M.Slate)
	b.box("AltarCloth", Vector3.new(4.7, 0.1, 2.4), cf * CFrame.new(0, 3.05, 0), Color3.fromRGB(80, 14, 14), M.Fabric)
	b.box("AltarClothHang", Vector3.new(1.6, 2.4, 0.05), cf * CFrame.new(0, 1.9, -1.15), Color3.fromRGB(80, 14, 14), M.Fabric)
	-- ein Gefäß und ein Bild von Sarp (nur ein schwarzer Umriss mit roten Augen)
	b.cyl("Bowl", 0.4, 1.0, cf * CFrame.new(0, 3.1, -0.3), C.metal, M.Metal)
	b.box("SarpPicture", Vector3.new(1.4, 1.9, 0.08), cf * CFrame.new(0, 3.83, 0.7) * CFrame.Angles(math.rad(-10), 0, 0), C.black, M.SmoothPlastic)
	b.box("SarpEyes", Vector3.new(0.5, 0.08, 0.02), cf * CFrame.new(0, 4.33, 0.62) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(200, 30, 20), M.Neon)
end

-- Versteck: Schrank, innen hohl, vorne zwei Türen mit Schlitzen auf Augenhöhe (von innen
-- sieht man durch die Schlitze in den Raum). Vorne = -Z.
function Furniture.hideWardrobe(b, cf)
	local w, h, d = 3.4, 7.6, 2.4
	local wood, dark = C.darkWood, C.black
	b.box("HideWardrobeBack", Vector3.new(w, h, 0.2), cf * CFrame.new(0, h / 2, d / 2 - 0.1), wood, M.Wood)
	for _, x in { -1, 1 } do
		b.box("HideWardrobeSide", Vector3.new(0.2, h, d), cf * CFrame.new(x * (w / 2 - 0.1), h / 2, 0), wood, M.Wood)
	end
	b.box("HideWardrobeTop", Vector3.new(w + 0.3, 0.3, d + 0.3), cf * CFrame.new(0, h + 0.15, 0), C.wood, M.Wood)
	b.box("HideWardrobeFloor", Vector3.new(w, 0.2, d), cf * CFrame.new(0, 0.1, 0), wood, M.Wood)
	-- Türen: unten und oben geschlossen, dazwischen Lamellen mit Spalten
	local front = -d / 2 + 0.06
	local slitsFrom, slitsTo = 4.0, 6.4
	b.box("HideWardrobeDoor", Vector3.new(w - 0.4, slitsFrom - 0.2, 0.12), cf * CFrame.new(0, 0.2 + (slitsFrom - 0.2) / 2, front), wood, M.WoodPlanks)
	b.box("HideWardrobeDoor", Vector3.new(w - 0.4, h - slitsTo, 0.12), cf * CFrame.new(0, slitsTo + (h - slitsTo) / 2, front), wood, M.WoodPlanks)
	local y = slitsFrom
	while y < slitsTo - 0.1 do
		b.box("HideWardrobeSlat", Vector3.new(w - 0.4, 0.2, 0.12), cf * CFrame.new(0, y + 0.1, front) * CFrame.Angles(math.rad(-25), 0, 0), wood, M.Wood)
		y += 0.34
	end
	b.box("HideWardrobeLine", Vector3.new(0.05, h - 0.4, 0.04), cf * CFrame.new(0, h / 2, front - 0.08), dark, M.Wood)
	for _, x in { -0.3, 0.3 } do
		b.box("HideWardrobeKnob", Vector3.new(0.14, 0.14, 0.14), cf * CFrame.new(x, 3.6, front - 0.12), C.brass, M.Metal)
	end
	return cf * CFrame.new(0, 0.2, 0.15) -- Stelle für den Versteckten (Füße), Blick nach vorne
end

-- Lange Tischdecke, die an allen Seiten fast bis zum Boden hängt (darunter kann man sich
-- verstecken). `cf` = Tisch auf dem Boden (wie bei Furniture.table), w, d, h wie dort.
function Furniture.tableCloth(b, cf, w, d, h, color, gap)
	gap = gap or 0.7
	local hang = h - gap
	b.box("TableCloth", Vector3.new(w + 0.3, 0.04, d + 0.3), cf * CFrame.new(0, h + 0.02, 0), color, M.Fabric)
	for _, x in { -1, 1 } do
		b.box("TableClothSide", Vector3.new(0.05, hang, d + 0.3), cf * CFrame.new(x * (w / 2 + 0.15), gap + hang / 2, 0), color, M.Fabric)
	end
	for _, z in { -1, 1 } do
		b.box("TableClothEnd", Vector3.new(w + 0.35, hang, 0.05), cf * CFrame.new(0, gap + hang / 2, z * (d / 2 + 0.15)), color, M.Fabric)
	end
end

-- Schwerer, bodenlanger Vorhang (zwei Bahnen an einer Stange) zwischen `from` und `to`
-- (Punkte auf dem Boden, Haus-Koordinaten), `height` hoch
function Furniture.curtain(b, from, to, height, color)
	local span = to - from
	local middle = (from + to) / 2
	local frame = CFrame.lookAt(middle, middle + span:Cross(Vector3.yAxis))
	local width = span.Magnitude
	b.box("CurtainRod", Vector3.new(width + 0.4, 0.12, 0.12), frame * CFrame.new(0, height + 0.15, 0), C.brass, M.Metal)
	for _, side in { -1, 1 } do
		-- leicht gewellt: zwei Lagen versetzt
		for layer = 0, 1 do
			b.box("HeavyCurtain", Vector3.new(width / 2 - 0.05, height - 0.1, 0.08), frame * CFrame.new(side * width / 4, height / 2 + 0.05, layer * 0.1 - 0.05) * CFrame.Angles(0, math.rad(layer == 0 and 2 or -2), 0), color, M.Fabric)
		end
	end
end

return Furniture
