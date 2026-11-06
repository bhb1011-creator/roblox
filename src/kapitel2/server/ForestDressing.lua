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

-- Bodennebel (große, sehr blasse Wolken, die langsam ziehen)
local function fog(parent, cframe, size)
	local holder = deco(parent, "GroundFog", size, cframe, Color3.new(), M.SmoothPlastic, { Transparency = 1 })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Fog"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(150, 160, 175))
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.88), NumberSequenceKeypoint.new(0.7, 0.9), NumberSequenceKeypoint.new(1, 1) })
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 11) })
	emitter.Lifetime = NumberRange.new(9, 14)
	emitter.Rate = 1.2
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
	local fogEvery, flyEvery = 55, 90
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
				fog(folder, CFrame.lookAt(at, at + direction), Vector3.new(30, 2, 20))
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
