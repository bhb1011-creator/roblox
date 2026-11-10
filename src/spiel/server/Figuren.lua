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

return Figuren
