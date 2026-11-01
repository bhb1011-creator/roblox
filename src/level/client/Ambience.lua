-- Umgebungsgeräusche von Level 1: Wind in den Bäumen, zufällige Geräusche aus allen
-- Richtungen (Rascheln, knackende Äste, knarrende Bäume), ein Wald, der verstummt, wenn
-- etwas nicht stimmt, Herzschlag und Atmen bei der Jagd, Schritte passend zum Boden,
-- tickender Motor, Stimmen im Radiorauschen und das knarrende Haus.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Route = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelRoute"))

local Ambience = {}

-- 1 = Wald normal laut, 0 = totenstill (das Hauptskript dämpft damit die Grillen)
Ambience.forestFactor = 1

local makeSound
local loops = {}
local nextOneShot = 0
local nextAnimal = 0
local nextHouseCreak = 0
local nextRadioVoice = 0
local carTickStarted
local houseSetUp = false
local houseCenter
local steps = {} -- pro Spielfigur: zurückgelegte Strecke und Schritt-Sounds
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local GRAVEL = { [Enum.Material.Pebble] = true, [Enum.Material.Slate] = true, [Enum.Material.Concrete] = true, [Enum.Material.Asphalt] = true, [Enum.Material.Cobblestone] = true }
local WOOD = { [Enum.Material.Wood] = true, [Enum.Material.WoodPlanks] = true }

function Ambience.init(soundFactory)
	makeSound = soundFactory
	loops.wind = makeSound("forestWind", SoundService, { Looped = true, Volume = 0 })
	loops.heartbeat = makeSound("heartbeat", SoundService, { Looped = true, Volume = 0 })
	loops.breath = makeSound("scaredBreath", SoundService, { Looped = true, Volume = 0 })
	for _, sound in loops do
		sound:Play()
	end
end

local function blend(sound, volume, speed, deltaTime)
	if sound then
		sound.Volume += (volume - sound.Volume) * math.min(deltaTime * (speed or 2), 1)
	end
end

-- Einmaliges 3D-Geräusch an einer Stelle in der Welt
local function playAt(key, position, volume, maxDistance, speed, minDistance)
	local holder = Instance.new("Part")
	holder.Name = "AmbientSound"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.5, 0.5, 0.5)
	holder.CFrame = CFrame.new(position)
	holder.Parent = workspace
	local sound = makeSound(key, holder, { Volume = volume, RollOffMinDistance = minDistance or 8, RollOffMaxDistance = maxDistance or 80 })
	if sound then
		if speed then
			sound.PlaybackSpeed *= speed
		end
		sound:Play()
	end
	task.delay(8, function()
		holder:Destroy()
	end)
end

-- Zufälliger Punkt im Wald, meistens seitlich oder hinter einem
local function aroundYou(camera, minDistance, maxDistance)
	local look = camera.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local angle = yaw + math.pi + (math.random() - 0.5) * 3.4
	local distance = minDistance + math.random() * (maxDistance - minDistance)
	local base = camera.CFrame.Position
	local x, z = base.X - math.sin(angle) * distance, base.Z - math.cos(angle) * distance
	return Vector3.new(x, Route.groundY(x, z), z)
end

-- Schaukel, Fensterladen und Knarren am Haus (einmal einrichten, sobald das Haus da ist)
local function setUpHouse()
	local house = workspace:FindFirstChild("WagnerHouse", true)
	if not house then
		return
	end
	houseSetUp = true
	houseCenter = Route.houseCFrame().Position
	local tire = house:FindFirstChild("SwingTire")
	if tire then
		local swing = makeSound("swingCreak", tire, { Looped = true, Volume = 0.55, RollOffMinDistance = 6, RollOffMaxDistance = 50 })
		if swing then
			swing:Play()
		end
	end
	local shutter = house:FindFirstChild("Shutter")
	if shutter then
		local rattle = makeSound("shutterRattle", shutter, { Looped = true, Volume = 0.6, RollOffMinDistance = 6, RollOffMaxDistance = 45 })
		if rattle then
			rattle:Play()
		end
	end
end

-- Schritte aller Spielfiguren, je nach Boden (Schotter, Waldboden, Holz)
local function updateSteps(deltaTime)
	local characters = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			table.insert(characters, character)
			-- die normalen Roblox-Laufgeräusche stummschalten (nur bei uns)
			local running = root:FindFirstChild("Running")
			if running and running:IsA("Sound") then
				running.Volume = 0
			end
			local info = steps[character]
			if not info then
				info = {
					distance = 0,
					gravel = makeSound("stepGravel", root, { Volume = 0.55, RollOffMaxDistance = 50 }),
					dirt = makeSound("stepDirt", root, { Volume = 0.6, RollOffMaxDistance = 45 }),
					wood = makeSound("stepWood", root, { Volume = 0.6, RollOffMaxDistance = 55 }),
				}
				steps[character] = info
			end
			local velocity = root.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			if speed > 2 and humanoid.FloorMaterial ~= Enum.Material.Air then
				info.distance += speed * deltaTime
				local stride = 2.4 + speed * 0.07
				if info.distance >= stride then
					info.distance = 0
					rayParams.FilterDescendantsInstances = characters
					local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayParams)
					local material = hit and hit.Material or Enum.Material.Ground
					local sound = GRAVEL[material] and info.gravel or WOOD[material] and info.wood or info.dirt
					if sound then
						sound.PlaybackSpeed = 0.9 + math.random() * 0.2
						sound:Play()
					end
				end
			else
				info.distance = 0
			end
		end
	end
	for character in steps do
		if not character.Parent then
			steps[character] = nil
		end
	end
end

-- Jedes Bild. state: camera, carStopped, walking, quiet (Sarp am Fenster), radioOff,
-- carRoot (Teil des Autos), finished
function Ambience.update(deltaTime, state)
	local camera = state.camera
	local now = os.clock()
	local master = state.finished and 0 or 1

	-- Ist das Biest in der Nähe? Dann verstummt alles, nur Herz und Atem werden laut.
	local near = 0
	local anchor = workspace:FindFirstChild("BeastAnchor")
	if anchor and anchor:GetAttribute("Active") then
		local distance = (anchor.Position - camera.CFrame.Position).Magnitude
		near = math.clamp(1 - (distance - 6) / 60, 0, 1)
	end
	local quiet = state.quiet and 0.05 or 1
	Ambience.forestFactor = math.min(quiet, 1 - near * 0.95)

	blend(loops.wind, (state.walking and 0.45 or state.carStopped and 0.18 or 0) * Ambience.forestFactor * master, 1, deltaTime)
	blend(loops.heartbeat, near * 0.9 * master, 3, deltaTime)
	blend(loops.breath, (state.walking and near * 0.7 or 0) * master, 3, deltaTime)
	if loops.heartbeat then
		loops.heartbeat.PlaybackSpeed = 0.9 + near * 0.8
	end

	-- Zufällige Geräusche aus allen Richtungen (nicht, wenn alles still sein soll)
	local outside = state.walking or state.carStopped
	if outside and not state.finished and Ambience.forestFactor > 0.5 and now >= nextOneShot then
		nextOneShot = now + (state.walking and math.random(25, 70) / 10 or math.random(50, 110) / 10)
		local roll = math.random()
		local volume = state.walking and 1 or 0.6 -- im Auto klingt alles gedämpfter
		if roll < 0.45 then
			playAt("rustle", aroundYou(camera, 10, 30) + Vector3.new(0, 1, 0), 0.8 * volume, 60)
		elseif roll < 0.75 then
			playAt("twig", aroundYou(camera, 12, 35) + Vector3.new(0, 0.5, 0), 0.9 * volume, 70)
		else
			playAt("treeCreak", aroundYou(camera, 15, 40) + Vector3.new(0, 10, 0), 0.9 * volume, 90, 0.85 + math.random() * 0.3)
		end
	elseif not outside or Ambience.forestFactor <= 0.5 then
		nextOneShot = math.max(nextOneShot, now + 2)
	end

	-- Tiere im Hintergrund: weit weg im Wald, aber gut zu hören. Der Vogel flattert
	-- dagegen ganz in der Nähe auf, wenn man zu Fuß unterwegs ist.
	if outside and not state.finished and Ambience.forestFactor > 0.5 and now >= nextAnimal then
		nextAnimal = now + math.random(120, 260) / 10
		local roll = math.random()
		local volume = state.walking and 1 or 0.75
		if roll < 0.32 then
			playAt("owl", aroundYou(camera, 55, 95) + Vector3.new(0, 14, 0), 1.1 * volume, 320, 0.95 + math.random() * 0.1, 45)
		elseif roll < 0.52 then
			playAt("raven", aroundYou(camera, 40, 80) + Vector3.new(0, 18, 0), 1 * volume, 300, 0.9 + math.random() * 0.2, 40)
		elseif roll < 0.68 then
			playAt("wolf", aroundYou(camera, 90, 140), 1.2 * volume, 420, 0.95 + math.random() * 0.1, 70)
		elseif roll < 0.8 then
			playAt("foxScream", aroundYou(camera, 70, 120), 1.1 * volume, 380, 1, 55)
		elseif state.walking then
			playAt("birdFlyaway", aroundYou(camera, 8, 16) + Vector3.new(0, 6, 0), 1, 80, 0.9 + math.random() * 0.2, 10)
		end
	elseif not outside or Ambience.forestFactor <= 0.5 then
		nextAnimal = math.max(nextAnimal, now + 6)
	end

	-- Stimmen im Radiorauschen, solange man im Auto sitzt
	if not state.walking and state.radioOff and not state.finished and now >= nextRadioVoice then
		nextRadioVoice = now + math.random(70, 140) / 10
		local voice = makeSound("radioVoices", SoundService, { Volume = 0.3 })
		if voice then
			local speaker = Instance.new("EqualizerSoundEffect")
			speaker.LowGain = -8
			speaker.MidGain = 2
			speaker.HighGain = -6
			speaker.Parent = voice
			voice:Play()
			voice.Ended:Connect(function()
				voice:Destroy()
			end)
		end
	end

	-- Der Motor ist aus und tickt beim Abkühlen (wird über ~40 Sekunden leiser)
	if state.walking and state.carRoot then
		if not carTickStarted then
			carTickStarted = now
			loops.carTick = makeSound("carTick", state.carRoot, { Looped = true, Volume = 0.7, RollOffMinDistance = 4, RollOffMaxDistance = 35 })
			if loops.carTick then
				loops.carTick:Play()
			end
		end
		if loops.carTick then
			loops.carTick.Volume = math.max(0, 0.7 * (1 - (now - carTickStarted) / 40)) * master
		end
	end

	-- Am Haus: Schaukel, Fensterladen und ab und zu ein Knarren, als wäre jemand drin
	if not houseSetUp then
		setUpHouse()
	elseif houseCenter and not state.finished and now >= nextHouseCreak then
		nextHouseCreak = now + math.random(60, 150) / 10
		if (houseCenter - camera.CFrame.Position).Magnitude < 75 then
			local spot = Route.housePoint(math.random(-18, 18), math.random(-14, 14))
			playAt("houseCreak", spot + Vector3.new(0, math.random(3, 16), 0), 0.9, 70, 0.85 + math.random() * 0.3)
		end
	end

	if state.walking then
		updateSteps(deltaTime)
	end
end

return Ambience
