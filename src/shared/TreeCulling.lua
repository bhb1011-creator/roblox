-- Leistung im Wald (Client): Bäume, die weit weg im Nebel stehen, werden nicht gezeichnet.
-- Eine echte Tanne hat rund 2.000 Dreiecke; im Wald von Kapitel 3 stehen fast 2.000 davon.
-- Die Bäume werden in Kacheln sortiert; nur Kacheln, die über die Grenze wandern, werden
-- umgeschaltet (LocalTransparencyModifier, die Bäume selbst bleiben stehen).
local RunService = game:GetService("RunService")

local TreeCulling = {}

local CELL = 36
local SHOW, HIDE = 190, 210 -- Studs: näher = zeigen, weiter = ausblenden (Abstand gegen Flackern)
local UPDATE_EVERY = 0.25
local MAX_CELLS = 10 -- so viele Kacheln höchstens pro Durchgang umschalten (keine Ruckler)
local TREES = { Pine = true, FarPine = true, DeadTree = true }

local started = {}

function TreeCulling.start(folder)
	if started[folder] then
		return
	end
	started[folder] = true
	local cells = {}

	local function setModel(model, hidden)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = hidden and 1 or 0
			end
		end
	end
	local function add(model)
		if not (model:IsA("Model") and TREES[model.Name]) then
			return
		end
		local position = model:GetPivot().Position
		local kx, kz = math.floor(position.X / CELL), math.floor(position.Z / CELL)
		local key = kx .. "," .. kz
		local cell = cells[key]
		if not cell then
			cell = { center = Vector3.new((kx + 0.5) * CELL, 0, (kz + 0.5) * CELL), models = {}, hidden = false }
			cells[key] = cell
		end
		table.insert(cell.models, model)
		if cell.hidden then
			setModel(model, true)
		end
	end
	for _, child in folder:GetChildren() do
		add(child)
	end
	folder.ChildAdded:Connect(function(child)
		task.defer(add, child) -- (erst wenn alle Teile da sind)
	end)

	local nextUpdate = 0
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not folder.Parent then
			connection:Disconnect()
			started[folder] = nil
			return
		end
		local now = os.clock()
		if now < nextUpdate then
			return
		end
		nextUpdate = now + UPDATE_EVERY
		local eye = workspace.CurrentCamera.CFrame.Position
		local changed = 0
		for _, cell in cells do
			local distance = ((cell.center - eye) * Vector3.new(1, 0, 1)).Magnitude
			local hidden = cell.hidden
			if hidden and distance < SHOW then
				hidden = false
			elseif not hidden and distance > HIDE then
				hidden = true
			end
			-- (Zeigen geht immer sofort, Ausblenden darf warten)
			if hidden ~= cell.hidden and (not hidden or changed < MAX_CELLS) then
				cell.hidden = hidden
				changed += 1
				for _, model in cell.models do
					setModel(model, hidden)
				end
			end
		end
	end)
end

return TreeCulling
