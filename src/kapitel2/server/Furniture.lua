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
-- kleine Zierteile: keine Kollision (man bleibt nirgends hängen, Verstecke und Wege bleiben gleich)
local DECO = { CanCollide = false }
local function deco(extra)
	local props = { CanCollide = false }
	for key, value in extra or {} do
		props[key] = value
	end
	return props
end
local function shade(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

-- Teppich: Rand, Innenfläche, Zierlinie, Mittelmuster und Fransen an den kurzen Enden
function Furniture.rug(b, cf, w, d, color, border)
	border = border or Color3.fromRGB(46, 26, 22)
	b.box("RugBorder", Vector3.new(w, 0.03, d), cf * CFrame.new(0, 0.015, 0), border, M.Fabric)
	b.box("Rug", Vector3.new(w - 0.5, 0.03, d - 0.5), cf * CFrame.new(0, 0.045, 0), color, M.Fabric)
	local line = color:Lerp(Color3.fromRGB(200, 170, 110), 0.35)
	for _, x in { -1, 1 } do
		b.box("RugLine", Vector3.new(0.08, 0.01, d - 1.1), cf * CFrame.new(x * (w / 2 - 0.55), 0.065, 0), line, M.Fabric, DECO)
	end
	for _, z in { -1, 1 } do
		b.box("RugLine", Vector3.new(w - 1.1, 0.01, 0.08), cf * CFrame.new(0, 0.065, z * (d / 2 - 0.55)), line, M.Fabric, DECO)
	end
	local medallion = math.min(w, d) * 0.32
	b.box("RugMedallion", Vector3.new(medallion, 0.01, medallion), cf * CFrame.new(0, 0.066, 0) * CFrame.Angles(0, math.rad(45), 0), border, M.Fabric, DECO)
	b.box("RugMedallion", Vector3.new(medallion * 0.55, 0.01, medallion * 0.55), cf * CFrame.new(0, 0.07, 0) * CFrame.Angles(0, math.rad(45), 0), line, M.Fabric, DECO)
	-- Fransen an den kurzen Enden
	local alongX = w < d
	local count = math.floor((alongX and w or d) / 0.45)
	for _, side in { -1, 1 } do
		for i = 0, count - 1 do
			local t = (i + 0.5) / count - 0.5
			local offset = alongX and CFrame.new(t * (w - 0.3), 0.02, side * (d / 2 + 0.2)) or CFrame.new(side * (w / 2 + 0.2), 0.02, t * (d - 0.3))
			b.box("RugFringe", alongX and Vector3.new(0.06, 0.02, 0.4) or Vector3.new(0.4, 0.02, 0.06), cf * offset, Color3.fromRGB(196, 184, 160), M.Fabric, DECO)
		end
	end
end

-- Tisch mit Kante, Zarge und gedrechselten Beinen
function Furniture.table(b, cf, w, d, h, color)
	h = h or 2.9
	color = color or C.wood
	local dark = shade(color, 0.3)
	b.box("TableTop", Vector3.new(w, 0.18, d), cf * CFrame.new(0, h - 0.09, 0), color, M.Wood)
	b.box("TableEdge", Vector3.new(w - 0.1, 0.08, d - 0.1), cf * CFrame.new(0, h - 0.22, 0), dark, M.Wood, DECO)
	-- Zarge unter der Platte
	for _, z in { -1, 1 } do
		b.box("TableApron", Vector3.new(w - 0.7, 0.35, 0.1), cf * CFrame.new(0, h - 0.43, z * (d / 2 - 0.3)), dark, M.Wood, DECO)
	end
	for _, x in { -1, 1 } do
		b.box("TableApron", Vector3.new(0.1, 0.35, d - 0.7), cf * CFrame.new(x * (w / 2 - 0.3), h - 0.43, 0), dark, M.Wood, DECO)
	end
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local leg = cf * CFrame.new(x * (w / 2 - 0.3), 0, z * (d / 2 - 0.3))
			b.box("TableLeg", Vector3.new(0.22, h - 0.18, 0.22), leg * CFrame.new(0, (h - 0.18) / 2, 0), C.darkWood, M.Wood, { Transparency = 1 }) -- unsichtbarer Kern (Kollision wie bisher)
			b.box("LegBlock", Vector3.new(0.26, 0.5, 0.26), leg * CFrame.new(0, h - 0.43, 0), C.darkWood, M.Wood, DECO)
			b.cyl("LegTurn", h - 0.9, 0.2, leg * CFrame.new(0, 0.22, 0), C.darkWood, M.Wood, DECO)
			b.ball("LegRing", 0.28, leg * CFrame.new(0, h * 0.42, 0), C.darkWood, M.Wood)
			b.ball("LegFoot", 0.26, leg * CFrame.new(0, 0.13, 0), C.darkWood, M.Wood)
		end
	end
	return cf * CFrame.new(0, h, 0) -- Tischplatte (für Sachen obendrauf)
end

-- Stuhl mit Sprossenlehne, Sitzpolster und Querstreben
function Furniture.chair(b, cf, color)
	color = color or C.darkWood
	b.box("ChairSeat", Vector3.new(1.6, 0.2, 1.6), cf * CFrame.new(0, 1.8, 0), color, M.Wood)
	b.box("ChairCushion", Vector3.new(1.4, 0.12, 1.4), cf * CFrame.new(0, 1.96, -0.05), Color3.fromRGB(96, 36, 34), M.Fabric, DECO)
	-- Lehne: zwei Pfosten, oberer Bogen, drei Sprossen (Kollision über einen unsichtbaren Block wie bisher)
	b.box("ChairBack", Vector3.new(1.6, 2.4, 0.2), cf * CFrame.new(0, 3.1, 0.7), color, M.Wood, { Transparency = 1 })
	for _, x in { -0.7, 0.7 } do
		b.box("ChairPost", Vector3.new(0.18, 2.5, 0.18), cf * CFrame.new(x, 3.1, 0.7), color, M.Wood, DECO)
		b.ball("ChairFinial", 0.24, cf * CFrame.new(x, 4.4, 0.7), color, M.Wood)
	end
	b.box("ChairRail", Vector3.new(1.5, 0.4, 0.16), cf * CFrame.new(0, 4.05, 0.7), color, M.Wood, DECO)
	for _, x in { -0.35, 0, 0.35 } do
		b.box("ChairSlat", Vector3.new(0.12, 1.9, 0.08), cf * CFrame.new(x, 2.95, 0.7), color, M.Wood, DECO)
	end
	for _, x in { -0.65, 0.65 } do
		for _, z in { -0.65, 0.65 } do
			b.box("ChairLeg", Vector3.new(0.16, 1.7, 0.16), cf * CFrame.new(x, 0.85, z), color, M.Wood)
		end
		b.box("ChairStretcher", Vector3.new(0.08, 0.08, 1.2), cf * CFrame.new(x, 0.5, 0), color, M.Wood, DECO)
	end
	b.box("ChairStretcher", Vector3.new(1.2, 0.08, 0.08), cf * CFrame.new(0, 0.7, 0), color, M.Wood, DECO)
end

-- Sessel oder Sofa, optional unter einem weißen Tuch (mit Falten, unter dem man die Form ahnt)
function Furniture.sofa(b, cf, w, color, covered)
	local fabric = covered and C.sheet or color
	local mat = M.Fabric
	-- Grundform (Kollision)
	b.box("SofaSeat", Vector3.new(w, 1.2, 2.6), cf * CFrame.new(0, 1.2, 0), fabric, mat)
	b.box("SofaBack", Vector3.new(w, 2.4, 0.8), cf * CFrame.new(0, 2.4, 1.0), fabric, mat)
	for _, x in { -1, 1 } do
		b.box("SofaArm", Vector3.new(0.7, 1.9, 2.6), cf * CFrame.new(x * (w / 2 - 0.35), 1.55, 0), fabric, mat)
	end
	local seats = math.max(1, math.floor((w - 1.4) / 1.6 + 0.5))
	local seatW = (w - 1.4) / seats
	if covered then
		-- das Tuch: weiche Rundungen über Polstern und Armlehnen, Falten und ein Saum am Boden
		local fold = shade(C.sheet, 0.12)
		for i = 1, seats do
			local x = -w / 2 + 0.7 + (i - 0.5) * seatW
			-- liegende Rollen (von links nach rechts): Sitzpolster vorne, Rückenpolster oben
			local alongX = CFrame.Angles(0, 0, math.rad(-90))
			b.cyl("SheetBump", seatW * 0.92, 0.7, cf * CFrame.new(x - seatW * 0.46, 1.65, -0.9) * alongX, C.sheet, mat, DECO)
			b.cyl("SheetBump", seatW * 0.92, 0.8, cf * CFrame.new(x - seatW * 0.46, 3.45, 1.0) * alongX, C.sheet, mat, DECO)
		end
		for _, x in { -1, 1 } do
			b.cyl("SheetArmRoll", 2.6, 0.95, cf * CFrame.new(x * (w / 2 - 0.35), 2.5, -1.3) * CFrame.Angles(math.rad(90), 0, 0), C.sheet, mat, DECO)
		end
		b.box("Sheet", Vector3.new(w + 0.2, 0.6, 3.0), cf * CFrame.new(0, 0.3, -0.1), C.sheet, mat)
		-- Falten: schräg hängende Streifen vorne und an den Seiten
		for i = 0, math.floor(w / 0.9) do
			local x = -w / 2 + 0.3 + i * 0.9
			if x < w / 2 - 0.2 then
				b.box("SheetFold", Vector3.new(0.12, 1.5, 0.08), cf * CFrame.new(x, 0.95, -1.62) * CFrame.Angles(0, 0, math.rad((i % 2 == 0) and 6 or -5)), fold, mat, DECO)
			end
		end
		for _, x in { -1, 1 } do
			b.box("SheetFold", Vector3.new(0.08, 1.6, 0.12), cf * CFrame.new(x * (w / 2 + 0.11), 1.0, -0.6) * CFrame.Angles(math.rad(7), 0, 0), fold, mat, DECO)
			b.box("SheetFold", Vector3.new(0.08, 1.4, 0.12), cf * CFrame.new(x * (w / 2 + 0.11), 0.9, 0.5) * CFrame.Angles(math.rad(-6), 0, 0), fold, mat, DECO)
		end
		-- Staub auf dem Tuch
		b.box("SheetDust", Vector3.new(w * 0.6, 0.02, 0.5), cf * CFrame.new(0, 3.63, 1.0), Color3.fromRGB(150, 146, 136), mat, DECO)
	else
		-- Sockel mit gedrechselten Füßen, einzelne Sitz- und Rückenkissen, gerollte Armlehnen, Ziernähte
		b.box("SofaBase", Vector3.new(w - 0.1, 0.45, 2.4), cf * CFrame.new(0, 0.37, 0), C.darkWood, M.Wood)
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				b.cyl("SofaFoot", 0.18, 0.22, cf * CFrame.new(x * (w / 2 - 0.3), 0, z * 1.0), C.darkWood, M.Wood, DECO)
			end
		end
		local seam = shade(color, 0.3)
		for i = 1, seats do
			local x = -w / 2 + 0.7 + (i - 0.5) * seatW
			b.box("SofaCushion", Vector3.new(seatW - 0.08, 0.35, 2.1), cf * CFrame.new(x, 1.95, -0.2), color, mat, DECO)
			b.box("SofaPiping", Vector3.new(seatW - 0.06, 0.05, 0.05), cf * CFrame.new(x, 2.1, -1.26), seam, mat, DECO)
			b.box("SofaBackCushion", Vector3.new(seatW - 0.1, 1.4, 0.4), cf * CFrame.new(x, 2.85, 0.45) * CFrame.Angles(math.rad(-8), 0, 0), color, mat, DECO)
			b.ball("SofaButton", 0.1, cf * CFrame.new(x, 3.0, 0.23), seam, mat)
		end
		for _, x in { -1, 1 } do
			b.cyl("SofaArmRoll", 2.6, 0.8, cf * CFrame.new(x * (w / 2 - 0.35), 2.5, -1.3) * CFrame.Angles(math.rad(90), 0, 0), color, mat, DECO)
			b.cyl("SofaArmFace", 0.04, 0.6, cf * CFrame.new(x * (w / 2 - 0.35), 2.5, -1.33) * CFrame.Angles(math.rad(90), 0, 0), seam, mat, DECO)
		end
	end
end

function Furniture.bed(b, cf, w, l, sheet, frame)
	frame = frame or C.darkWood
	b.box("BedFrame", Vector3.new(w, 1.2, l), cf * CFrame.new(0, 0.9, 0), frame, M.Wood)
	b.box("Mattress", Vector3.new(w - 0.2, 0.6, l - 0.3), cf * CFrame.new(0, 1.8, -0.1), Color3.fromRGB(200, 194, 180), M.Fabric)
	b.box("Blanket", Vector3.new(w - 0.1, 0.25, l * 0.62), cf * CFrame.new(0, 2.15, -l * 0.18 - 0.08), sheet, M.Fabric)
	b.box("Pillow", Vector3.new(w * 0.7, 0.4, 1.1), cf * CFrame.new(0, 2.3, l / 2 - 0.9), Color3.fromRGB(214, 208, 196), M.Fabric)
	b.box("Headboard", Vector3.new(w, 2.9, 0.4), cf * CFrame.new(0, 1.45, l / 2 + 0.1), frame, M.Wood) -- bleibt unter der Fensterbank
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

-- Regal mit Büchern oder Einmachgläsern: Sockel, Kranz oben, Bücher stehend, schief und gestapelt
function Furniture.shelf(b, cf, w, h, kind, rng)
	h = h or 7
	b.box("ShelfBack", Vector3.new(w, h, 0.15), cf * CFrame.new(0, h / 2, 0.6), C.darkWood, M.Wood)
	for _, x in { -1, 1 } do
		b.box("ShelfSide", Vector3.new(0.2, h, 1.3), cf * CFrame.new(x * (w / 2 - 0.1), h / 2, 0), C.darkWood, M.Wood)
	end
	if h > 4 then
		b.box("ShelfCrown", Vector3.new(w + 0.3, 0.25, 1.5), cf * CFrame.new(0, h + 0.12, -0.05), C.wood, M.Wood, DECO)
		b.box("ShelfCrown", Vector3.new(w + 0.15, 0.12, 1.4), cf * CFrame.new(0, h - 0.06, -0.05), shade(C.wood, 0.25), M.Wood, DECO)
	end
	b.box("ShelfPlinth", Vector3.new(w + 0.1, 0.3, 1.36), cf * CFrame.new(0, 0.15, -0.02), shade(C.darkWood, 0.2), M.Wood, DECO)
	local rows = math.floor(h / 1.6)
	for r = 0, rows do
		local y = 0.2 + r * (h - 0.4) / rows
		b.box("ShelfBoard", Vector3.new(w - 0.3, 0.12, 1.2), cf * CFrame.new(0, y, 0), C.wood, M.Wood)
		b.box("ShelfLip", Vector3.new(w - 0.3, 0.05, 0.04), cf * CFrame.new(0, y + 0.02, -0.62), shade(C.wood, 0.3), M.Wood, DECO)
		if r < rows then
			local x = -w / 2 + 0.4
			while x < w / 2 - 0.5 do
				if kind == "jars" then
					local glass = rng:NextNumber() < 0.5 and Color3.fromRGB(120, 60, 40) or Color3.fromRGB(90, 100, 50)
					local jar = cf * CFrame.new(x + 0.25, y + 0.06, 0)
					b.cyl("Jar", 0.7, 0.45, jar, glass, M.Glass, { Transparency = 0.15 })
					b.cyl("JarLid", 0.08, 0.48, jar * CFrame.new(0, 0.7, 0), Color3.fromRGB(150, 140, 120), M.Fabric, DECO)
					b.cyl("JarString", 0.04, 0.5, jar * CFrame.new(0, 0.66, 0), Color3.fromRGB(90, 70, 50), M.Fabric, DECO)
					x += 0.65
				else
					local roll = rng:NextNumber()
					local tint = rng:NextNumber(0.4, 1)
					local bookColor = Color3.fromRGB(60 * tint + 30, 40 * tint + 20, 30 * tint + 18)
					if roll < 0.08 and x < w / 2 - 1.3 then
						-- kleiner Stapel liegender Bücher
						local top = y + 0.06
						for i = 1, rng:NextInteger(2, 4) do
							local thick = rng:NextNumber(0.14, 0.22)
							b.box("Book", Vector3.new(0.9, thick, 0.75), cf * CFrame.new(x + 0.45, top + thick / 2, 0.05) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0), bookColor:Lerp(Color3.fromRGB(110, 40, 30), rng:NextNumber(0, 0.6)), M.Fabric, DECO)
							top += thick
						end
						x += 1.0
					elseif roll < 0.13 then
						x += rng:NextNumber(0.2, 0.45) -- Lücke
					else
						local thick = rng:NextNumber(0.18, 0.35)
						local tall = rng:NextNumber(0.9, 1.3)
						local lean = roll > 0.93 and math.rad(-14) or 0
						local book = cf * CFrame.new(x + thick / 2 + (lean ~= 0 and 0.12 or 0), y + 0.06 + tall / 2, 0.05) * CFrame.Angles(0, 0, lean)
						b.box("Book", Vector3.new(thick, tall, 0.9), book, bookColor, M.Fabric)
						-- Buchrücken: zwei goldene Streifen
						if tall > 1.0 then
							for _, band in { 0.3, -0.25 } do
								b.box("BookBand", Vector3.new(thick + 0.01, 0.04, 0.02), book * CFrame.new(0, band * tall, -0.45), Color3.fromRGB(160, 130, 70), M.Fabric, DECO)
							end
						end
						x += thick + 0.03 + (lean ~= 0 and 0.25 or 0)
					end
				end
			end
		end
	end
end

-- Bild an der Wand; `cf` = Mitte des Bildes, Rückseite an der Wand (+Z).
-- Goldrahmen mit Innenleiste, dunkles Ölbild (Horizont, Hügel, Mond), Namensschildchen.
function Furniture.picture(b, cf, w, h, color, scratched)
	color = color or Color3.fromRGB(70, 62, 50)
	b.box("PictureFrame", Vector3.new(w, h, 0.12), cf, C.brass, M.Metal)
	local inner = shade(C.brass, 0.35)
	for _, x in { -1, 1 } do
		b.box("FrameBevel", Vector3.new(0.06, h - 0.24, 0.04), cf * CFrame.new(x * (w / 2 - 0.15), 0, -0.08), inner, M.Metal, DECO)
	end
	for _, y in { -1, 1 } do
		b.box("FrameBevel", Vector3.new(w - 0.24, 0.06, 0.04), cf * CFrame.new(0, y * (h / 2 - 0.15), -0.08), inner, M.Metal, DECO)
	end
	b.box("Picture", Vector3.new(w - 0.3, h - 0.3, 0.04), cf * CFrame.new(0, 0, -0.07), color, M.SmoothPlastic)
	-- gemalte Landschaft: heller Himmelsstreifen, dunkle Hügel, ein Mond
	local cw, ch = w - 0.36, h - 0.36
	b.box("Paint", Vector3.new(cw, ch * 0.18, 0.01), cf * CFrame.new(0, ch * 0.05, -0.095), color:Lerp(Color3.fromRGB(150, 130, 100), 0.35), M.SmoothPlastic, DECO)
	b.box("Paint", Vector3.new(cw * 0.7, ch * 0.3, 0.01), cf * CFrame.new(-cw * 0.15, -ch * 0.25, -0.1) * CFrame.Angles(0, 0, math.rad(8)), shade(color, 0.45), M.SmoothPlastic, DECO)
	b.box("Paint", Vector3.new(cw * 0.6, ch * 0.24, 0.01), cf * CFrame.new(cw * 0.2, -ch * 0.3, -0.105) * CFrame.Angles(0, 0, math.rad(-10)), shade(color, 0.6), M.SmoothPlastic, DECO)
	b.cyl("PaintMoon", 0.01, math.min(cw, ch) * 0.16, cf * CFrame.new(cw * 0.28, ch * 0.3, -0.1) * CFrame.Angles(math.rad(-90), 0, 0), Color3.fromRGB(200, 190, 160), M.SmoothPlastic, DECO)
	b.box("PicturePlate", Vector3.new(math.min(0.6, w * 0.3), 0.12, 0.02), cf * CFrame.new(0, -h / 2 + 0.06, -0.08), C.brass, M.Metal, DECO)
	if scratched then
		for i = 1, 3 do
			b.box("Scratch", Vector3.new(0.05, h * 0.35, 0.02), cf * CFrame.new(-0.15 + i * 0.1, h * 0.12, -0.12) * CFrame.Angles(0, 0, math.rad(25 - i * 15)), C.black, nil, DECO)
		end
	end
end

-- Kinderzeichnung: Familie (vier kleine Figuren) und daneben ein großer schwarzer Mann
function Furniture.drawing(b, cf)
	b.box("Drawing", Vector3.new(1.6, 1.2, 0.02), cf, C.paper, M.SmoothPlastic)
	local function figure(x, height, color)
		b.box("DrawLine", Vector3.new(0.05, height, 0.01), cf * CFrame.new(x, -0.45 + height / 2, -0.03), color)
		b.box("DrawHead", Vector3.new(0.14, 0.14, 0.01), cf * CFrame.new(x, -0.45 + height + 0.07, -0.03), color)
	end
	for i, h in { 0.35, 0.33, 0.22, 0.18 } do
		figure(-0.65 + i * 0.18, h, Color3.fromRGB(60, 80, 140))
	end
	figure(0.45, 0.75, C.black)
	b.box("DrawArm", Vector3.new(0.4, 0.04, 0.01), cf * CFrame.new(0.3, 0.05, -0.015) * CFrame.Angles(0, 0, math.rad(-20)), C.black)
	b.box("DrawEyes", Vector3.new(0.12, 0.03, 0.01), cf * CFrame.new(0.45, 0.42, -0.02), C.blood)
end

-- Kamin: Steinumrandung mit Pfeilern und Schlussstein, Ziegel innen, Feuerrost mit
-- verkohlten Scheiten, Asche, Ruß, Steinplatte davor, Kaminbesteck, Sims mit Uhr und Leuchtern
function Furniture.fireplace(b, cf)
	local stone = C.stone
	b.box("FireplaceStone", Vector3.new(6.5, 5.2, 1.6), cf * CFrame.new(0, 2.6, 0.2), stone, M.Slate)
	-- Pfeiler links und rechts, Schlussstein über der Öffnung
	for _, x in { -1, 1 } do
		b.box("FireplacePillar", Vector3.new(0.8, 4.9, 0.25), cf * CFrame.new(x * 2.85, 2.45, -0.68), shade(stone, 0.12), M.Slate, DECO)
		b.box("PillarCap", Vector3.new(0.95, 0.25, 0.35), cf * CFrame.new(x * 2.85, 4.95, -0.7), shade(stone, 0.2), M.Slate, DECO)
	end
	b.box("FireplaceArch", Vector3.new(4.2, 0.45, 0.2), cf * CFrame.new(0, 3.3, -0.65), shade(stone, 0.18), M.Slate, DECO)
	b.box("Keystone", Vector3.new(0.6, 0.7, 0.28), cf * CFrame.new(0, 3.4, -0.72), shade(stone, 0.05), M.Slate, DECO)
	-- Öffnung: schwarz, hinten dunkle Ziegel mit Fugen
	b.box("FireplaceHole", Vector3.new(3.6, 3, 1.0), cf * CFrame.new(0, 1.6, -0.25), C.black, M.SmoothPlastic)
	b.box("FireBrick", Vector3.new(3.4, 2.8, 0.05), cf * CFrame.new(0, 1.5, 0.2), Color3.fromRGB(58, 30, 24), M.Brick, DECO)
	-- Ruß über der Öffnung
	b.box("Soot", Vector3.new(2.6, 0.9, 0.02), cf * CFrame.new(0, 3.75, -0.63), Color3.fromRGB(30, 28, 26), M.SmoothPlastic, deco({ Transparency = 0.35 }))
	-- Feuerrost mit Scheiten
	for _, x in { -0.9, 0.9 } do
		b.box("GrateLeg", Vector3.new(0.1, 0.5, 0.1), cf * CFrame.new(x, 0.45, -0.5), C.black, M.Metal, DECO)
	end
	for i = 0, 4 do
		b.box("GrateBar", Vector3.new(2.0, 0.06, 0.06), cf * CFrame.new(0, 0.65, -0.75 + i * 0.12), C.black, M.Metal, DECO)
	end
	for _, info in { { -0.3, 0.8, 15 }, { 0.35, 0.8, -12 }, { 0.05, 1.05, 4 } } do
		-- Scheit liegt quer: Mitte bei info, um info[3] Grad gedreht; die Säule wächst nach +X
		local middle = cf * CFrame.new(info[1], info[2], -0.45) * CFrame.Angles(0, math.rad(info[3]), 0)
		b.cyl("Log", 1.6, 0.38, middle * CFrame.new(-0.8, 0, 0) * CFrame.Angles(0, 0, math.rad(-90)), Color3.fromRGB(34, 26, 20), M.Wood, DECO)
		b.cyl("LogEnd", 0.03, 0.34, middle * CFrame.new(0.8, 0, 0) * CFrame.Angles(0, 0, math.rad(-90)), Color3.fromRGB(90, 40, 22), M.Wood, DECO)
	end
	b.box("Ash", Vector3.new(3, 0.2, 0.8), cf * CFrame.new(0, 0.2, -0.3), Color3.fromRGB(60, 58, 56), M.Sand)
	-- Steinplatte davor
	b.box("Hearth", Vector3.new(7, 0.2, 1.4), cf * CFrame.new(0, 0.1, -1.3), shade(stone, 0.08), M.Slate, DECO)
	-- Kaminbesteck rechts: Ständer mit Schürhaken und Schaufel
	local tools = cf * CFrame.new(3.6, 0, -1.1)
	b.cyl("ToolStandBase", 0.08, 0.6, tools, C.black, M.Metal, DECO)
	b.cyl("ToolStand", 2.4, 0.08, tools, C.black, M.Metal, DECO)
	b.box("ToolHook", Vector3.new(0.5, 0.06, 0.06), tools * CFrame.new(0, 2.3, 0), C.black, M.Metal, DECO)
	for _, x in { -0.2, 0.2 } do
		b.box("FireTool", Vector3.new(0.05, 2.0, 0.05), tools * CFrame.new(x, 1.25, -0.05) * CFrame.Angles(0, 0, math.rad(x > 0 and -4 or 4)), C.black, M.Metal, DECO)
		b.ball("FireToolKnob", 0.12, tools * CFrame.new(x, 2.3, -0.05), C.brass, M.Metal)
	end
	b.box("Shovel", Vector3.new(0.3, 0.35, 0.04), tools * CFrame.new(0.25, 0.35, -0.05), C.black, M.Metal, DECO)
	-- Sims in zwei Stufen
	b.box("Mantel", Vector3.new(7.2, 0.35, 2.1), cf * CFrame.new(0, 5.3, 0), C.darkWood, M.Wood)
	b.box("MantelMolding", Vector3.new(6.8, 0.2, 1.9), cf * CFrame.new(0, 5.03, 0.05), shade(C.darkWood, 0.25), M.Wood, DECO)
	-- Kaminuhr in der Mitte (stehengeblieben)
	local clock = cf * CFrame.new(0, 5.48, -0.1)
	b.box("Clock", Vector3.new(1.1, 1.0, 0.5), clock * CFrame.new(0, 0.5, 0), C.wood, M.Wood, DECO)
	b.box("ClockTop", Vector3.new(0.7, 0.3, 0.45), clock * CFrame.new(0, 1.15, 0), C.wood, M.Wood, DECO)
	b.cyl("ClockFace", 0.03, 0.6, clock * CFrame.new(0, 0.55, -0.26) * CFrame.Angles(math.rad(-90), 0, 0), Color3.fromRGB(214, 204, 180), M.SmoothPlastic, DECO)
	b.box("ClockHand", Vector3.new(0.03, 0.22, 0.01), clock * CFrame.new(0.05, 0.6, -0.29) * CFrame.Angles(0, 0, math.rad(-35)), C.black, nil, DECO)
	b.box("ClockHand", Vector3.new(0.03, 0.16, 0.01), clock * CFrame.new(-0.05, 0.52, -0.29) * CFrame.Angles(0, 0, math.rad(115)), C.black, nil, DECO)
	-- Leuchter mit heruntergebrannten Kerzen
	for _, x in { -2.6, 2.6 } do
		b.cyl("CandlestickBase", 0.1, 0.45, cf * CFrame.new(x, 5.48, -0.2), C.brass, M.Metal, DECO)
		b.cyl("Candlestick", 1, 0.3, cf * CFrame.new(x, 5.48, -0.2), C.brass, M.Metal)
		b.cyl("CandleStub", 0.35, 0.18, cf * CFrame.new(x, 6.48, -0.2), Color3.fromRGB(214, 206, 186), M.SmoothPlastic, DECO)
		b.box("Wax", Vector3.new(0.05, 0.2, 0.05), cf * CFrame.new(x + 0.08, 6.4, -0.28), Color3.fromRGB(214, 206, 186), M.SmoothPlastic, DECO)
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
		b.box("Pipe", Vector3.new(0.35, 3.6, 0.35), cf * CFrame.new(x, 7.8, 0), C.metal, M.Metal) -- endet im Boden darüber
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
		b.boxWorld("HangingSheet", Vector3.new(2.2, sheetHeight, 0.09), CFrame.lookAt(at, at + (to - from):Cross(Vector3.yAxis)) * CFrame.new(0, -sheetHeight / 2 + 0.05, 0), C.sheet, M.Fabric)
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
	-- Lamellen oben und unten, dazwischen ein breiter offener Schlitz auf Augenhöhe
	local openFrom, openTo = 4.55, 5.75
	local y = slitsFrom
	while y < slitsTo - 0.1 do
		if y + 0.2 < openFrom or y > openTo then
			b.box("HideWardrobeSlat", Vector3.new(w - 0.4, 0.2, 0.12), cf * CFrame.new(0, y + 0.1, front) * CFrame.Angles(math.rad(-20), 0, 0), wood, M.Wood)
		end
		y += 0.38
	end
	for _, x in { -1, 1 } do
		-- schmale Rahmenleisten links und rechts vom Schlitz
		b.box("HideWardrobeFrame", Vector3.new(0.2, openTo - openFrom + 0.2, 0.12), cf * CFrame.new(x * (w / 2 - 0.3), (openFrom + openTo) / 2, front), wood, M.Wood)
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
