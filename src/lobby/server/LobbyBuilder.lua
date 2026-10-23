-- Baut die komplette Lobby per Code zusammen.
local Buildings = require(script.Parent.Buildings)
local Camp = require(script.Parent.Camp)
local Decor = require(script.Parent.Decor)
local Environment = require(script.Parent.Environment)
local Forest = require(script.Parent.Forest)
local Layout = require(script.Parent.Layout)
local ParkingLot = require(script.Parent.ParkingLot)
local Parts = require(script.Parent.Parts)
local Road = require(script.Parent.Road)

local LobbyBuilder = {}

local function removeTemplateParts()
	-- Die Studio-Vorlage "Baseplate" bringt eigene Teile mit, die wir nicht brauchen.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local existing = workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
end

-- Platz für Natur: nicht auf dem Parkplatz und nicht auf der Straße
local function isClearForNature(x, z, margin)
	local lot = Layout.LOT
	if math.abs(x) < lot.halfWidth + margin and z > lot.minZ - margin and z < lot.maxZ + margin then
		return false
	end
	return Road.distanceTo(x, z) > Road.WIDTH / 2 + 3 + margin
end

function LobbyBuilder.build()
	removeTemplateParts()
	Environment.setupLighting()
	Environment.buildTerrain(Road.SEGMENTS, Road.WIDTH)

	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = workspace

	ParkingLot.build(lobby)
	Road.build(lobby)
	local gate = Road.buildGate(lobby)
	Forest.build(lobby, isClearForNature, Road.distanceTo)
	Camp.build(lobby)
	Buildings.build(lobby)
	Decor.build(lobby)

	Parts.new("SpawnLocation", {
		Name = "LobbySpawn",
		Size = Vector3.new(14, 0.2, 8),
		CFrame = CFrame.new(Layout.SPAWN),
		Transparency = 1,
		CanCollide = false,
		Neutral = true,
		Duration = 0,
		Parent = lobby,
	})

	local cars = Instance.new("Folder")
	cars.Name = "Cars"
	cars.Parent = lobby

	return {
		folder = lobby,
		carsFolder = cars,
		gate = gate,
	}
end

return LobbyBuilder
