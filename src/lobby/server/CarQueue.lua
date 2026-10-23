-- Steuert die vier Autos: Einsteigen, Aussteigen, Countdown und Abfahrt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Car = require(script.Parent.Car)
local Layout = require(script.Parent.Layout)
local Road = require(script.Parent.Road)

local CarQueue = {}

local LOT_SPEED = 18
local ROAD_SPEED = 35
local TELEPORT_TIMEOUT = 15

local gate
local notifyRemote

local function getRiders(car)
	local riders = {}
	for _, info in car.seats do
		local humanoid = info.seat.Occupant
		local player = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
		if player then
			table.insert(riders, player)
		end
	end
	return riders
end

local function isInCar(player, car)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	return seat ~= nil and seat:IsDescendantOf(car.model)
end

local function updateLabels(car)
	local count = #getRiders(car)
	car.labels.count.Text = string.format("👤 %d / %d", count, car.capacity)

	local status
	if car.state == "Departing" then
		status = "🚗 Fährt los…"
	elseif car.state == "Countdown" then
		status = string.format("Start in %d…", car.timeLeft)
	elseif count == 0 then
		status = "Einsteigen zum Starten"
	else
		local missing = car.capacity - count
		status = missing == 1 and "Warte auf 1 Spieler…" or string.format("Warte auf %d Spieler…", missing)
	end
	car.labels.status.Text = status
end

local function setState(car, state)
	car.state = state
	car.model:SetAttribute("State", state)
	updateLabels(car)
end

-- Fährt das Auto Punkt für Punkt ab und dreht es dabei sanft in Fahrtrichtung.
local function driveAlong(model, route)
	local current = model:GetPivot()
	for _, waypoint in route do
		local startPosition = current.Position
		local delta = waypoint.position - startPosition
		local distance = delta.Magnitude
		if distance > 0.1 then
			local startRotation = current.Rotation
			local endRotation = CFrame.lookAt(startPosition, waypoint.position).Rotation
			local duration = distance / waypoint.speed
			local elapsed = 0
			while elapsed < duration do
				elapsed += RunService.Heartbeat:Wait()
				local alpha = math.min(elapsed / duration, 1)
				local turn = math.min(elapsed / math.min(0.8, duration), 1)
				current = CFrame.new(startPosition:Lerp(waypoint.position, alpha))
					* startRotation:Lerp(endRotation, turn)
				model:PivotTo(current)
			end
		end
	end
end

-- Aus der Parkbucht nach vorne, zur Mitte, dann nach Norden durch die Schranke
-- und die Waldstraße entlang, bis das Auto im Dunkeln verschwunden ist.
local function buildRoute(home)
	local position = home.Position
	local y = position.Y
	local route = {
		{ position = Vector3.new(position.X, y, -22), speed = LOT_SPEED },
		{ position = Vector3.new(0, y, -22), speed = LOT_SPEED },
		{ position = Vector3.new(0, y, Layout.GATE_Z - 2), speed = LOT_SPEED },
	}
	for _, point in Road.PATH do
		if point.Z < Layout.GATE_Z - 4 then
			table.insert(route, { position = Vector3.new(point.X, y, point.Z), speed = ROAD_SPEED })
		end
	end
	return route
end

-- Schickt die Mitfahrer ins Horror-Level. Ohne Level-PlaceId (oder wenn der
-- Teleport scheitert) kommen sie zurück zum Lagerfeuer.
local function sendOff(car, riders)
	local passengers = {}
	for _, player in riders do
		if player.Parent and isInCar(player, car) then
			table.insert(passengers, player)
		end
	end
	if #passengers == 0 then
		return
	end

	local message = "Das Level ist noch in Arbeit – bald geht die Fahrt richtig los!"
	if Config.GAME_PLACE_ID ~= 0 then
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		options:SetTeleportData({ mode = car.mode })
		local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, Config.GAME_PLACE_ID, passengers, options)
		if ok then
			local deadline = os.clock() + TELEPORT_TIMEOUT
			while os.clock() < deadline do
				local anyoneLeft = false
				for _, player in passengers do
					if player.Parent then
						anyoneLeft = true
					end
				end
				if not anyoneLeft then
					return
				end
				task.wait(0.5)
			end
		else
			warn("Teleport fehlgeschlagen:", err)
		end
		message = "Die Fahrt hat nicht geklappt – versuch es nochmal."
	end

	for _, player in passengers do
		if player.Parent then
			notifyRemote:FireClient(player, message)
			player:LoadCharacter()
		end
	end
end

local function depart(car)
	setState(car, "Departing")
	car.prompt.Enabled = false
	local riders = getRiders(car)

	gate.open()
	driveAlong(car.model, car.route)
	gate.close()

	sendOff(car, riders)

	task.wait(2)
	car.model:PivotTo(car.home)
	setState(car, "Idle")
	car.refresh()
end

local function startCountdown(car)
	car.token += 1
	local token = car.token
	car.timeLeft = Config.COUNTDOWN_SECONDS
	setState(car, "Countdown")

	task.spawn(function()
		for secondsLeft = Config.COUNTDOWN_SECONDS, 1, -1 do
			if car.state ~= "Countdown" or car.token ~= token then
				return
			end
			car.timeLeft = secondsLeft
			updateLabels(car)
			task.wait(1)
		end
		if car.state == "Countdown" and car.token == token then
			depart(car)
		end
	end)
end

local function setupCar(index, carConfig, parent)
	local mode = Config.MODES[carConfig.mode]
	local home = CFrame.lookAt(carConfig.position, carConfig.position + Vector3.zAxis)
	local plate = string.format("WL-%s %d", string.char(64 + index), 100 + index * 37)
	local built = Car.build(parent, home, carConfig.color, mode.capacity, "Car" .. index, mode.title, plate)

	local car = {
		model = built.model,
		seats = built.seats,
		prompt = built.prompt,
		labels = built.labels,
		home = home,
		route = buildRoute(home),
		mode = carConfig.mode,
		capacity = mode.capacity,
		state = "Idle",
		token = 0,
		timeLeft = 0,
	}

	function car.refresh()
		local count = #getRiders(car)
		if car.state ~= "Departing" then
			car.prompt.Enabled = count < car.capacity
			if count >= car.capacity and car.state == "Idle" then
				startCountdown(car)
			elseif count < car.capacity and car.state == "Countdown" then
				setState(car, "Idle")
			end
		end
		updateLabels(car)
	end

	car.prompt.Triggered:Connect(function(player)
		if car.state == "Departing" then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then
			return
		end
		for _, info in car.seats do
			if not info.seat.Occupant then
				info.seat:Sit(humanoid)
				return
			end
		end
	end)

	for _, info in car.seats do
		local lastOccupant
		info.seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local occupant = info.seat.Occupant
			if occupant then
				lastOccupant = occupant
			else
				-- Beim Aussteigen neben das Auto setzen, damit niemand in der Kabine feststeckt
				local character = lastOccupant and lastOccupant.Parent
				lastOccupant = nil
				if character and character.Parent and car.state ~= "Departing" then
					local exitCFrame = car.model:GetPivot() * info.exitOffset
					task.defer(function()
						if character.Parent then
							character:PivotTo(exitCFrame)
						end
					end)
				end
			end
			car.refresh()
		end)
	end

	car.refresh()
	return car
end

function CarQueue.init(parent, lobbyGate, notify)
	gate = lobbyGate
	notifyRemote = notify
	for index, carConfig in Config.CARS do
		setupCar(index, carConfig, parent)
	end
end

return CarQueue
