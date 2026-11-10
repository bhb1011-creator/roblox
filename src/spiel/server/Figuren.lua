-- Testmenü "Figuren ansehen": die Familie Wagner steht hell beleuchtet nebeneinander auf
-- einer Bühne, Mrs. Wagner und Lucy laufen hin und her (Kleid / Nachthemd beim Gehen prüfen).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Figuren = {}

local CENTER = Vector3.new(0, 200, 0)

function Figuren.run()
	local Wagners = require(ServerScriptService:WaitForChild("Kapitel2"):WaitForChild("Wagners"))
	local folder = Instance.new("Folder")
	folder.Name = "Figuren"
	folder.Parent = workspace

	local floor = Instance.new("Part")
	floor.Name = "Stage"
	floor.Anchored = true
	floor.Size = Vector3.new(60, 1, 40)
	floor.Position = CENTER - Vector3.new(0, 0.5, 0)
	floor.Color = Color3.fromRGB(70, 66, 62)
	floor.Material = Enum.Material.WoodPlanks
	floor.Parent = folder
	-- neutrales Tageslicht (keine Lampen: die überstrahlen die Figuren)
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0
	Lighting.Ambient = Color3.fromRGB(110, 110, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 130, 135)
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
			effect:Destroy()
		end
	end

	local look = CENTER + Vector3.new(0, 0, -20)
	local standing = {
		{ Wagners.buildMr, -10 },
		{ Wagners.buildTommy, 10 },
	}
	for _, entry in standing do
		local model = entry[1](folder)
		if model then
			Wagners.place(model, CENTER + Vector3.new(entry[2], 0, 0), look + Vector3.new(entry[2], 0, 0))
		end
	end
	-- Mrs. Wagner und Lucy laufen langsam hin und her
	local walkers = {}
	for index, build in { Wagners.buildMrs, Wagners.buildLucy } do
		local model = build(folder)
		if model then
			local hips = {}
			for _, side in { "Left", "Right" } do
				local upper = model:FindFirstChild(side .. "UpperLeg")
				local joint = upper and upper:FindFirstChild(side .. "Hip")
				if joint then
					table.insert(hips, { joint = joint, base = joint.C0 })
				end
			end
			table.insert(walkers, { model = model, hips = hips, x = index == 1 and -3.5 or 3.5, phase = index })
		end
	end
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, walker in walkers do
			local z = math.sin(t * 0.5 + walker.phase) * 3
			local direction = math.cos(t * 0.5 + walker.phase) >= 0 and 1 or -1
			local ground = CENTER + Vector3.new(walker.x, 0, z)
			-- dreht sich zwischendurch zur Kamera (vorne), damit man das Gesicht sieht
			local facing = math.abs(math.cos(t * 0.5 + walker.phase)) < 0.25 and look or ground + Vector3.new(0, 0, direction)
			Wagners.place(walker.model, ground, facing)
			local scale = walker.model:GetAttribute("StepScale") or 1
			for i, hip in walker.hips do
				pcall(function()
					hip.joint.C0 = hip.base * CFrame.Angles(math.sin(t * 6 + i * math.pi) * 0.35 * scale, 0, 0)
				end)
			end
		end
	end)

	-- Spieler vor die Bühne stellen
	local function spawn(player)
		require(game:GetService("ReplicatedStorage").Shared.PlayerFigure).load(player)
		local character = player.Character
		local root = character and character:WaitForChild("HumanoidRootPart", 5)
		if root then
			root.CFrame = CFrame.lookAt(CENTER + Vector3.new(7, 3, -8), CENTER + Vector3.new(0, 3, 0))
		end
	end
	Players.CharacterAutoLoads = false
	Players.PlayerAdded:Connect(spawn)
	for _, player in Players:GetPlayers() do
		task.spawn(spawn, player)
	end
end

-- Testmenü "Charakterliste": alle Figuren des Spiels nebeneinander, jede mit Namensschild.
-- Die Kamera (TestMenu.client.lua) fährt der Reihe nach zu jeder (Attribut "Order" am Ordner).
local CHARACTERS = {
	{ id = "MrsWagner", label = "Margaret Wagner" },
	{ id = "MrWagner", label = "Richard Wagner" },
	{ id = "Lucy", label = "Lucy" },
	{ id = "Tommy", label = "Tommy" },
	{ id = "Spieler1", label = "Spieler 1 (Fahrer)" },
	{ id = "Spieler2", label = "Spieler 2 (Beifahrerin)" },
	{ id = "Sarp1", label = "Sarp – Stufe 1: der Fremde" },
	{ id = "Sarp", label = "Sarp – Stufe 2: das Monster im Haus" },
	{ id = "Beast", label = "Sarp – Stufe 3: das Biest" },
}

-- Namensschild über dem Kopf (als Schild an einem unsichtbaren Teil außerhalb der Figur,
-- damit es die Größe der Figur nicht verfälscht)
local function nameTag(folder, model, text)
	local head = model:FindFirstChild("Head")
	if not head then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "NameTag_" .. model.Name
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(head.Position + Vector3.new(0, head.Size.Y / 2 + 1.1, 0))
	anchor.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 40)
	gui.MaxDistance = 60
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(20, 18, 16)
	label.TextColor3 = Color3.fromRGB(240, 228, 205)
	label.Font = Enum.Font.SpecialElite
	label.TextScaled = true
	label.Text = text
	label.AutoLocalize = false
	label.Parent = gui
end

function Figuren.runList()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Wagners = require(ServerScriptService:WaitForChild("Kapitel2"):WaitForChild("Wagners"))
	local SarpStage2 = require(ServerScriptService.Kapitel2:WaitForChild("SarpStage2"))
	local RealFigure = require(ReplicatedStorage.Shared.RealFigure)
	local Beast = require(ReplicatedStorage.Shared.Beast)
	local folder = Instance.new("Folder")
	folder.Name = "Figuren"
	folder.Parent = workspace -- gleich in die Welt (Gegenstände in der Hand sitzen nur dort richtig)
	local floor = Instance.new("Part")
	floor.Name = "Stage"
	floor.Anchored = true
	floor.Size = Vector3.new(90, 1, 40)
	floor.Position = CENTER - Vector3.new(0, 0.5, 0)
	floor.Color = Color3.fromRGB(70, 66, 62)
	floor.Material = Enum.Material.WoodPlanks
	floor.Parent = folder
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0
	Lighting.Ambient = Color3.fromRGB(110, 110, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 130, 135)
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
			effect:Destroy()
		end
	end
	local builders = {
		MrsWagner = Wagners.buildMrs,
		MrWagner = Wagners.buildMr,
		Lucy = Wagners.buildLucy,
		Tommy = Wagners.buildTommy,
		Sarp = SarpStage2.build,
	}
	local order = {}
	local placed = {}
	local x = -36
	for _, entry in CHARACTERS do
		local ok, model = pcall(function()
			if builders[entry.id] then
				return builders[entry.id](folder)
			elseif entry.id == "Beast" then
				return (Beast.build(folder))
			else
				local source = entry.id:find("^Spieler") and RealFigure.source(entry.id, "Spieler") or RealFigure.source(entry.id)
				if source then
					local figure = RealFigure.prepare(source, { height = entry.id == "Spieler2" and 5.3 or (entry.id == "Spieler1" and 5.6 or 5.9) })
					figure.Name = entry.id
					figure.Parent = folder
					return figure
				end
			end
			return nil
		end)
		if ok and model then
			local spot = CENTER + Vector3.new(x, 0, 0)
			if entry.id == "Beast" then
				model:PivotTo(CFrame.lookAt(spot, spot + Vector3.new(0, 0, -1)))
			elseif model:GetAttribute("FootOffset") then
				Wagners.place(model, spot, spot + Vector3.new(0, 0, -1))
			else
				model:PivotTo(CFrame.lookAt(spot, spot + Vector3.new(0, 0, -1)))
			end
			table.insert(order, entry.id)
			table.insert(placed, { model = model, label = entry.label })
			x += entry.id == "Sarp" and 10 or 7
		elseif not ok then
			warn("Charakterliste: " .. entry.id .. " konnte nicht gebaut werden:", model)
		end
	end
	folder:SetAttribute("Order", table.concat(order, ","))
	-- erst wenn alle stehen (Gelenke einmal durchgerechnet), die Schilder über die Köpfe
	task.wait(0.3)
	for _, item in placed do
		nameTag(folder, item.model, item.label)
	end

	local function spawn(player)
		require(ReplicatedStorage.Shared.PlayerFigure).load(player)
		local character = player.Character
		local root = character and character:WaitForChild("HumanoidRootPart", 5)
		if root then
			root.CFrame = CFrame.lookAt(CENTER + Vector3.new(0, 3, -16), CENTER + Vector3.new(0, 3, 0))
		end
	end
	Players.CharacterAutoLoads = false
	Players.PlayerAdded:Connect(spawn)
	for _, player in Players:GetPlayers() do
		task.spawn(spawn, player)
	end
end

return Figuren
