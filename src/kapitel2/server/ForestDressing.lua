-- Details für den Waldweg in Kapitel 3: Farne, Grasbüschel, Pilze, Laub auf dem Weg,
-- Wurzeln, Äste, kleine Steine, umgestürzte Stämme, Bodennebel und Glühwürmchen.
-- Alles nur zum Ansehen (man läuft durch, nichts hält einen auf).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Parts)
local Forest = require(ReplicatedStorage.Shared.Forest)
local Data = require(ReplicatedStorage.Shared.Kapitel3Data)

local ForestDressing = {}

local M = Enum.Material

local function deco(parent, name, size, cframe, color, material, extra)
	local props = {
		Name = name,
		Size = size,
		CFrame = cframe,
		Color = color,
		Material = material or M.SmoothPlastic,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = parent,
	}
	for key, value in extra or {} do
		props[key] = value
	end
	return Parts.new("Part", props)
end

-- Farn: mehrere schmale Wedel, die schräg nach außen hängen
function ForestDressing.fern(parent, position, rng)
	local count = rng:NextInteger(5, 8)
	local base = Color3.fromRGB(44, 74, 36):Lerp(Color3.fromRGB(70, 88, 40), rng:NextNumber())
	local size = rng:NextNumber(0.8, 1.4)
	for i = 1, count do
		local angle = i / count * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local length = rng:NextNumber(1.6, 2.6) * size
		local frond = CFrame.new(position) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(rng:NextNumber(45, 65)), 0, 0)
		deco(parent, "Fern", Vector3.new(0.5 * size, 0.06, length), frond * CFrame.new(0, 0, -length / 2), base:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)), M.Grass)
	end
end

-- Grasbüschel: dünne Halme
function ForestDressing.tuft(parent, position, rng)
	local color = Color3.fromRGB(78, 92, 50):Lerp(Color3.fromRGB(120, 116, 70), rng:NextNumber())
	for _ = 1, rng:NextInteger(4, 7) do
		local height = rng:NextNumber(0.9, 2.1)
		local blade = CFrame.new(position + Vector3.new(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4))) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, 6.28), rng:NextNumber(-0.35, 0.35))
		deco(parent, "Grass", Vector3.new(0.1, height, 0.04), blade * CFrame.new(0, height / 2, 0), color, M.Grass)
	end
end

-- Pilze (ein paar rote mit weißen Punkten, sonst braune)
function ForestDressing.mushrooms(parent, position, rng)
	for _ = 1, rng:NextInteger(2, 5) do
		local at = position + Vector3.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
		local height = rng:NextNumber(0.3, 0.7)
		local red = rng:NextNumber() < 0.3
		deco(parent, "MushroomStem", Vector3.new(height, 0.14, 0.14), CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(220, 210, 190), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		local capSize = rng:NextNumber(0.35, 0.6)
		deco(parent, "MushroomCap", Vector3.new(capSize, capSize * 0.5, capSize), CFrame.new(at + Vector3.new(0, height, 0)), red and Color3.fromRGB(170, 34, 26) or Color3.fromRGB(130, 96, 62), M.SmoothPlastic, { Shape = Enum.PartType.Ball })
		if red then
			deco(parent, "MushroomDot", Vector3.new(0.07, 0.07, 0.07), CFrame.new(at + Vector3.new(0.08, height + capSize * 0.24, 0)), Color3.new(1, 1, 1), M.SmoothPlastic, { Shape = Enum.PartType.Ball })
		end
	end
end

-- Laub (flache, bunte Blätter auf dem Weg)
function ForestDressing.leaves(parent, position, rng, count)
	local colors = { Color3.fromRGB(140, 80, 34), Color3.fromRGB(110, 60, 30), Color3.fromRGB(160, 120, 50), Color3.fromRGB(90, 70, 40), Color3.fromRGB(120, 40, 26) }
	for _ = 1, count or rng:NextInteger(3, 6) do
		local at = position + Vector3.new(rng:NextNumber(-1.5, 1.5), 0.16, rng:NextNumber(-1.5, 1.5))
		deco(parent, "Leaf", Vector3.new(rng:NextNumber(0.3, 0.55), 0.03, rng:NextNumber(0.4, 0.7)), CFrame.new(at) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 6.28), rng:NextNumber(-0.15, 0.15)), colors[rng:NextInteger(1, #colors)], M.Fabric)
	end
end

-- Wurzel, die über den Weg wächst (flach, man läuft drüber)
function ForestDressing.root(parent, from, to, rng)
	local last = from
	for k = 1, 4 do
		local u = k / 4
		local point = from:Lerp(to, u) + Vector3.new(rng:NextNumber(-0.3, 0.3), math.sin(u * math.pi) * 0.25, rng:NextNumber(-0.3, 0.3))
		Parts.beam({ Name = "Root", Color = Color3.fromRGB(70, 52, 38), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = parent }, last, point, 0.32 - k * 0.05)
		last = point
	end
end

-- Abgebrochener Ast mit Zweigen
function ForestDressing.branch(parent, position, rng)
	local angle = rng:NextNumber(0, math.pi * 2)
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local length = rng:NextNumber(2.5, 5)
	local from = position + Vector3.new(0, 0.15, 0)
	local to = from + direction * length
	Parts.beam({ Name = "Branch", Color = Color3.fromRGB(80, 62, 46), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = parent }, from, to, 0.22)
	for _ = 1, 3 do
		local start = from:Lerp(to, rng:NextNumber(0.2, 0.9))
		local twig = start + (direction:Cross(Vector3.yAxis) * rng:NextNumber(-1, 1) + direction * 0.5).Unit * rng:NextNumber(0.6, 1.2) + Vector3.new(0, rng:NextNumber(0, 0.4), 0)
		Parts.beam({ Name = "Twig", Color = Color3.fromRGB(80, 62, 46), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = parent }, start, twig, 0.08)
	end
end

-- kleine Steine
function ForestDressing.pebbles(parent, position, rng)
	for _ = 1, rng:NextInteger(1, 3) do
		local size = rng:NextNumber(0.3, 0.9)
		deco(parent, "Pebble", Vector3.new(size, size * 0.6, size * rng:NextNumber(0.8, 1.2)), CFrame.new(position + Vector3.new(rng:NextNumber(-0.8, 0.8), size * 0.2, rng:NextNumber(-0.8, 0.8))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4)), Color3.fromRGB(100, 98, 92):Lerp(Color3.fromRGB(70, 78, 60), rng:NextNumber()), M.Slate)
	end
end

-- Moos-Fleck
function ForestDressing.moss(parent, position, rng)
	deco(parent, "Moss", Vector3.new(rng:NextNumber(1.5, 3), 0.08, rng:NextNumber(1.2, 2.5)), CFrame.new(position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), Color3.fromRGB(56, 76, 38), M.Grass)
end

-- flacher, halb im Boden steckender Stein am Wegrand
function ForestDressing.edgeStone(parent, cframe, rng)
	local size = Vector3.new(rng:NextNumber(1, 2.2), rng:NextNumber(0.5, 0.9), rng:NextNumber(1, 2))
	deco(parent, "EdgeStone", size, cframe * CFrame.new(0, size.Y * 0.25, 0) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 6.28), rng:NextNumber(-0.15, 0.15)), Color3.fromRGB(96, 96, 90):Lerp(Color3.fromRGB(70, 80, 60), rng:NextNumber()), M.Slate)
end

-- Ast, der hoch über den Weg ragt (von der Seite), mit Zweigen und Moos
function ForestDressing.overhead(parent, frame, side, rng)
	local from = (frame * CFrame.new(side * 15, rng:NextNumber(11, 14), 0)).Position
	local to = (frame * CFrame.new(-side * rng:NextNumber(-2, 4), rng:NextNumber(9, 12), rng:NextNumber(-2, 2))).Position
	Parts.beam({ Name = "OverheadBranch", Color = Color3.fromRGB(66, 52, 40), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = true, Parent = parent }, from, to, 0.5)
	for _ = 1, 4 do
		local start = from:Lerp(to, rng:NextNumber(0.3, 1))
		local twig = start + Vector3.new(rng:NextNumber(-2, 2), rng:NextNumber(-1.5, 1), rng:NextNumber(-2, 2))
		Parts.beam({ Name = "Twig", Color = Color3.fromRGB(66, 52, 40), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = true, Parent = parent }, start, twig, 0.15)
	end
	for _ = 1, 3 do
		local at = from:Lerp(to, rng:NextNumber(0.4, 1))
		local length = rng:NextNumber(1, 2.5)
		deco(parent, "HangingMoss", Vector3.new(0.15, length, 0.15), CFrame.new(at - Vector3.new(0, length / 2, 0)), Color3.fromRGB(80, 96, 60), M.Grass, { Transparency = 0.15 })
	end
	return to
end

-- Klauenspuren im Boden (das Biest war schon hier)
function ForestDressing.clawPrint(parent, frame, rng)
	for k = -1, 1 do
		deco(parent, "ClawMark", Vector3.new(0.18, 0.04, 1.4), frame * CFrame.new(k * 0.35, 0.13, 0) * CFrame.Angles(0, k * 0.15, 0), Color3.fromRGB(34, 26, 20), M.Mud)
	end
	deco(parent, "PawPad", Vector3.new(0.9, 0.04, 0.7), frame * CFrame.new(0, 0.13, 0.9), Color3.fromRGB(34, 26, 20), M.Mud)
end

-- gruselige Fundstücke am Rand (abwechselnd)
local PROPS = { "skull", "stickFigure", "rag", "lantern", "stake", "bones" }
function ForestDressing.prop(parent, kind, frame, side, rng)
	local at = frame * CFrame.new(side * rng:NextNumber(6.5, 8.5), 0, 0) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	if kind == "skull" then
		-- Hirschschädel mit Geweih im Laub
		deco(parent, "Skull", Vector3.new(0.9, 0.6, 1.4), at * CFrame.new(0, 0.3, 0), Color3.fromRGB(214, 206, 186), M.SmoothPlastic)
		for _, s in { -1, 1 } do
			local base = (at * CFrame.new(s * 0.3, 0.5, 0.4)).Position
			local tip = base + (at.RightVector * s * 1.2 + Vector3.new(0, 1.2, 0) + at.LookVector * -0.5)
			Parts.beam({ Name = "Antler", Color = Color3.fromRGB(186, 172, 148), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, base, tip, 0.12)
			deco(parent, "EyeHole", Vector3.new(0.2, 0.2, 0.2), at * CFrame.new(s * 0.22, 0.42, -0.45), Color3.new(0.05, 0.05, 0.05), M.SmoothPlastic, { Shape = Enum.PartType.Ball })
		end
	elseif kind == "stickFigure" then
		-- Figur aus Zweigen, an einer Schnur an einem Ast aufgehängt
		local top = (at * CFrame.new(0, 7, 0)).Position
		Parts.beam({ Name = "String", Color = Color3.fromRGB(200, 190, 160), Material = M.Fabric, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, top + Vector3.new(0, 3, 0), top, 0.04)
		Parts.beam({ Name = "Branch", Color = Color3.fromRGB(66, 52, 40), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, top + Vector3.new(-3, 3, 0), top + Vector3.new(3, 3.1, 0), 0.3)
		local body = top - Vector3.new(0, 1.2, 0)
		Parts.beam({ Name = "StickBody", Color = Color3.fromRGB(90, 70, 50), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, top, body - Vector3.new(0, 0.6, 0), 0.1)
		Parts.beam({ Name = "StickArms", Color = Color3.fromRGB(90, 70, 50), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, top - Vector3.new(0.8, 0.4, 0), top + Vector3.new(0.8, -0.4, 0), 0.08)
		for _, s in { -1, 1 } do
			Parts.beam({ Name = "StickLeg", Color = Color3.fromRGB(90, 70, 50), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, body - Vector3.new(0, 0.6, 0), body + Vector3.new(s * 0.5, -1.6, 0), 0.08)
		end
	elseif kind == "rag" then
		-- roter Stofffetzen an einem Pfahl (als hätte jemand den Weg markiert)
		Parts.column({ Name = "MarkerPost", Color = Color3.fromRGB(80, 62, 46), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, 3.4, 0.25, at)
		deco(parent, "Rag", Vector3.new(0.9, 1.4, 0.05), at * CFrame.new(0.25, 2.6, 0) * CFrame.Angles(0, 0, 0.2), Color3.fromRGB(130, 26, 22), M.Fabric)
	elseif kind == "lantern" then
		-- alte, kaputte Laterne auf einem Baumstumpf
		Parts.column({ Name = "Stump", Color = Color3.fromRGB(80, 62, 46), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, 1.3, 1.8, at)
		deco(parent, "OldLantern", Vector3.new(0.5, 0.7, 0.5), at * CFrame.new(0, 1.65, 0) * CFrame.Angles(0, 0, 0.25), Color3.fromRGB(90, 80, 60), M.CorrodedMetal)
		deco(parent, "LanternGlass", Vector3.new(0.4, 0.45, 0.4), at * CFrame.new(0.02, 1.62, 0) * CFrame.Angles(0, 0, 0.25), Color3.fromRGB(120, 110, 80), M.Glass, { Transparency = 0.5 })
	elseif kind == "stake" then
		-- Holzpflock mit eingeritztem Zeichen (rot)
		Parts.column({ Name = "Stake", Color = Color3.fromRGB(96, 76, 54), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent }, 4, 0.5, at * CFrame.Angles(0.08, 0, 0.05))
		deco(parent, "Symbol", Vector3.new(0.06, 0.8, 0.06), at * CFrame.new(0, 3, -0.26) * CFrame.Angles(0, 0, 0.6), Color3.fromRGB(150, 20, 16), M.SmoothPlastic)
		deco(parent, "Symbol", Vector3.new(0.06, 0.8, 0.06), at * CFrame.new(0, 3, -0.26) * CFrame.Angles(0, 0, -0.6), Color3.fromRGB(150, 20, 16), M.SmoothPlastic)
		deco(parent, "Symbol", Vector3.new(0.5, 0.06, 0.06), at * CFrame.new(0, 2.6, -0.26), Color3.fromRGB(150, 20, 16), M.SmoothPlastic)
	else
		-- verstreute Knochen
		for _ = 1, 5 do
			local length = rng:NextNumber(0.8, 1.6)
			deco(parent, "Bone", Vector3.new(0.16, 0.16, length), at * CFrame.new(rng:NextNumber(-1, 1), 0.12, rng:NextNumber(-1, 1)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), Color3.fromRGB(206, 198, 178), M.SmoothPlastic)
		end
	end
end

-- Terrain: Felsbrocken im Wald und hohes Gras an den Wegrändern
function ForestDressing.terrain(points, free, from, to)
	local terrain = workspace.Terrain
	pcall(function()
		terrain.Decoration = true -- Grashalme auf "Grass"
	end)
	local rng = Random.new(57)
	local s = from
	local step = 0
	while s < to do
		local center, direction = Data.pointAt(points, s)
		local right = Vector3.new(-direction.Z, 0, direction.X)
		local frame = CFrame.lookAt(center, center + Vector3.new(direction.X, 0, direction.Z))
		local wet = false -- (kein Gras im Bach und im Schlamm)
		for _, obstacle in Data.OBSTACLES do
			local a = obstacle.from or (obstacle.length and obstacle.s - obstacle.length / 2 - 4)
			local b = obstacle.to or (obstacle.length and obstacle.s + obstacle.length / 2 + 4)
			if a and b and s >= a - 3 and s <= b + 3 then
				wet = true
			end
		end
		for _, side in { -1, 1 } do
			local edge = center + right * side * 6.8
			if free(edge) and not wet then
				terrain:FillBlock(frame * CFrame.new(side * 6.8, -4, 0), Vector3.new(3.4, 8, 4.5), Enum.Material.Grass)
			end
		end
		step += 1
		if step % 6 == 0 then
			local side = rng:NextNumber() < 0.5 and -1 or 1
			local at = center + right * side * rng:NextNumber(13, 22)
			if free(at) then
				local radius = rng:NextNumber(2, 4.5)
				terrain:FillBall(at - Vector3.new(0, radius * 0.45, 0), radius, rng:NextNumber() < 0.5 and Enum.Material.Rock or Enum.Material.Slate)
			end
		end
		if step % 10 == 0 then
			task.wait()
		end
		s += 4
	end
end

-- Bodennebel (große, sehr blasse Wolken, die langsam ziehen)
local function fog(parent, cframe, size)
	local holder = deco(parent, "GroundFog", size, cframe, Color3.new(), M.SmoothPlastic, { Transparency = 1 })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Fog"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(150, 160, 175))
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.8), NumberSequenceKeypoint.new(0.7, 0.84), NumberSequenceKeypoint.new(1, 1) })
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 11) })
	emitter.Lifetime = NumberRange.new(9, 14)
	emitter.Rate = 2.2
	emitter.Speed = NumberRange.new(0.3, 0.8)
	emitter.SpreadAngle = Vector2.new(180, 10)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-6, 6)
	emitter.LightInfluence = 0.8
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.Parent = holder
end

local function fireflies(parent, cframe, size)
	local holder = deco(parent, "Fireflies", size, cframe, Color3.new(), M.SmoothPlastic, { Transparency = 1 })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Fireflies"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(210, 255, 120))
	emitter.LightEmission = 1
	emitter.Brightness = 3
	emitter.Size = NumberSequence.new(0.2)
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(4, 7)
	emitter.Rate = 2
	emitter.Speed = NumberRange.new(0.3, 0.8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 0.5
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.Parent = holder
end

-- Den ganzen Weg schmücken. free(position) sagt, ob dort etwas hin darf (nicht in der
-- Schlucht, nicht auf der Lichtung). Gibt die Zahl der Teile zurück.
function ForestDressing.path(parent, points, free, from, to)
	local folder = Instance.new("Folder")
	folder.Name = "PathDetails"
	folder.Parent = parent
	local rng = Random.new(91)
	local s = from or 0
	local step = 0
	local fogEvery, flyEvery = 24, 90
	while s < to do
		local center, direction = Data.pointAt(points, s)
		local right = Vector3.new(-direction.Z, 0, direction.X)
		step += 1
		-- Laub und kleine Steine auf dem Weg
		if rng:NextNumber() < 0.75 then
			local at = center + right * rng:NextNumber(-4, 4) + direction * rng:NextNumber(-1.5, 1.5)
			if free(at) then
				ForestDressing.leaves(folder, at, rng)
			end
		end
		if rng:NextNumber() < 0.25 then
			local at = center + right * (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(3.5, 5) + direction * rng:NextNumber(-1.5, 1.5)
			if free(at) then
				ForestDressing.pebbles(folder, at, rng)
			end
		end
		-- ab und zu eine Wurzel quer über den Weg
		if rng:NextNumber() < 0.06 then
			local side = rng:NextNumber() < 0.5 and -1 or 1
			local a = center + right * side * 7 + direction * rng:NextNumber(-1, 1)
			local b = center - right * side * rng:NextNumber(0, 3) + direction * rng:NextNumber(-2, 2)
			if free(a) and free(b) then
				ForestDressing.root(folder, a, b, rng)
			end
		end
		local frame = CFrame.lookAt(center, center + Vector3.new(direction.X, 0, direction.Z))
		-- Randsteine (halb im Boden)
		if rng:NextNumber() < 0.35 then
			local side = rng:NextNumber() < 0.5 and -1 or 1
			local at = center + right * side * rng:NextNumber(4.6, 5.6)
			if free(at) then
				ForestDressing.edgeStone(folder, frame * CFrame.new(side * (at - center).Magnitude, 0, rng:NextNumber(-1, 1)), rng)
			end
		end
		-- kleine Zweige auf dem Weg
		if rng:NextNumber() < 0.3 then
			local at = center + right * rng:NextNumber(-3.5, 3.5)
			if free(at) then
				local angle = rng:NextNumber(0, 6.28)
				local twigStart = at + Vector3.new(0, 0.17, 0)
				Parts.beam({ Name = "PathTwig", Color = Color3.fromRGB(80, 62, 46), Material = M.Wood, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = folder }, twigStart, twigStart + Vector3.new(math.cos(angle), 0, math.sin(angle)) * rng:NextNumber(0.8, 1.8), 0.08)
			end
		end
		-- Äste hoch über dem Weg (wie ein Dach aus Ästen)
		if step % 5 == 0 and rng:NextNumber() < 0.7 then
			local side = rng:NextNumber() < 0.5 and -1 or 1
			if free(center + right * side * 15) and free(center) then
				ForestDressing.overhead(folder, frame, side, rng)
			end
		end
		-- Klauenspuren auf dem Weg
		if rng:NextNumber() < 0.05 then
			local at = center + right * rng:NextNumber(-2.5, 2.5)
			if free(at) then
				ForestDressing.clawPrint(folder, CFrame.lookAt(at, at - Vector3.new(direction.X, 0, direction.Z)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), rng)
			end
		end
		-- gruselige Fundstücke (etwa alle 45 Studs)
		if step % 15 == 7 then
			local side = rng:NextNumber() < 0.5 and -1 or 1
			if free(center + right * side * 8) then
				ForestDressing.prop(folder, PROPS[(math.floor(step / 15) % #PROPS) + 1], frame, side, rng)
			end
		end
		-- dichtes Unterholz direkt hinter dem Wegrand
		if rng:NextNumber() < 0.4 then
			local side = rng:NextNumber() < 0.5 and -1 or 1
			local at = center + right * side * rng:NextNumber(10, 11.5)
			if free(at) then
				Forest.builders.bush(folder, at, rng)
			end
		end
		-- an den Rändern: Farne, Gras, Moos, Pilze, Äste
		for _, side in { -1, 1 } do
			local at = center + right * side * rng:NextNumber(5.5, 9.2) + direction * rng:NextNumber(-1.5, 1.5)
			if free(at) then
				local roll = rng:NextNumber()
				if roll < 0.4 then
					ForestDressing.fern(folder, at, rng)
				elseif roll < 0.75 then
					ForestDressing.tuft(folder, at, rng)
				elseif roll < 0.85 then
					ForestDressing.moss(folder, at, rng)
				elseif roll < 0.92 then
					ForestDressing.mushrooms(folder, at, rng)
				else
					ForestDressing.branch(folder, at, rng)
				end
			end
			-- hinter der unsichtbaren Wand: Stämme, Baumstümpfe, Farne
			local far = center + right * side * rng:NextNumber(11, 15) + direction * rng:NextNumber(-2, 2)
			if free(far) then
				local roll = rng:NextNumber()
				if roll < 0.05 then
					Forest.builders.fallenLog(folder, far + right * side * 4, rng)
				elseif roll < 0.1 then
					Forest.builders.stump(folder, far, rng)
					ForestDressing.mushrooms(folder, far + right * side * 1.4, rng)
				elseif roll < 0.45 then
					ForestDressing.fern(folder, far, rng)
				end
			end
		end
		if step % math.floor(fogEvery / 3) == 0 then
			local at = center + Vector3.new(0, 1.5, 0)
			if free(at) then
				fog(folder, CFrame.lookAt(at, at + direction), Vector3.new(36, 3, 26))
			end
		end
		if step % math.floor(flyEvery / 3) == 0 then
			local at = center + Vector3.new(0, 4, 0)
			if free(at) then
				fireflies(folder, CFrame.lookAt(at, at + direction), Vector3.new(26, 5, 22))
			end
		end
		s += 3
		if step % 4 == 0 then
			task.wait()
		end
	end
	return folder
end

return ForestDressing
