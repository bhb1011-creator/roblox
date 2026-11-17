-- Start-Menü der Lobby ("Play"): das ganze Spiel (Kapitel 1 bis 3) starten, ohne ins Auto zu steigen.
--   "solo"            → allein los
--   "invite", userId  → einen Spieler in dieser Lobby einladen (er bekommt einen Zettel)
--   "accept", userId  → Einladung annehmen: beide fahren zusammen (Duo) los
--   "decline", userId → Einladung ablehnen
-- Der Teleport geht nur im echten Roblox, nicht in Studio (dort kommt nur ein Hinweis).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayMenu = {}

local INVITE_TIME = 30 -- Sekunden, so lange gilt eine Einladung
local INVITE_COOLDOWN = 3
local TELEPORT_TIMEOUT = 15

local remote
local notifyRemote
local invites = {} -- [eingeladener Spieler] = { from = Spieler, at = os.clock() }
local lastInvite = {} -- [Spieler] = os.clock()
local leaving = {} -- [Spieler] = true, solange der Teleport läuft

local function notify(player, text)
	if player.Parent then
		notifyRemote:FireClient(player, text)
	end
end

local function send(group, mode)
	for _, player in group do
		if leaving[player] then
			return
		end
	end
	if RunService:IsStudio() or Config.GAME_PLACE_ID == 0 then
		for _, player in group do
			notify(player, "Starting the game only works in the real Roblox game, not in Studio.")
		end
		return
	end
	for _, player in group do
		leaving[player] = true
		remote:FireClient(player, "leaving", mode)
	end
	task.wait(2.2) -- Bildschirm wird schwarz
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true -- eigener Server nur für diese Gruppe
	options:SetTeleportData({ mode = mode })
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, Config.GAME_PLACE_ID, group, options)
	if ok then
		local deadline = os.clock() + TELEPORT_TIMEOUT
		repeat
			local anyoneLeft = false
			for _, player in group do
				if player.Parent then
					anyoneLeft = true
				end
			end
			if not anyoneLeft then
				return
			end
			task.wait(0.5)
		until os.clock() > deadline
	else
		warn("Teleport fehlgeschlagen:", err)
	end
	for _, player in group do
		leaving[player] = nil
		if player.Parent then
			remote:FireClient(player, "failed")
			notify(player, "The drive didn't work – please try again.")
		end
	end
end

local function findPlayer(userId)
	return type(userId) == "number" and Players:GetPlayerByUserId(userId) or nil
end

local function onAction(player, action, userId)
	if leaving[player] then
		return
	end
	if action == "solo" then
		invites[player] = nil
		send({ player }, "Solo")
	elseif action == "invite" then
		local target = findPlayer(userId)
		if not target or target == player or leaving[target] then
			return
		end
		if os.clock() - (lastInvite[player] or 0) < INVITE_COOLDOWN then
			return
		end
		lastInvite[player] = os.clock()
		invites[target] = { from = player, at = os.clock() }
		remote:FireClient(target, "invited", player.UserId, player.DisplayName)
		notify(player, "Invitation sent to " .. target.DisplayName .. ".")
	elseif action == "accept" or action == "decline" then
		local invite = invites[player]
		local from = findPlayer(userId)
		if not invite or invite.from ~= from or os.clock() - invite.at > INVITE_TIME then
			if action == "accept" then
				notify(player, "This invitation has expired.")
			end
			return
		end
		invites[player] = nil
		if action == "decline" then
			notify(from, player.DisplayName .. " doesn't want to play right now.")
			return
		end
		if not from.Parent or leaving[from] then
			notify(player, "Your friend has already left.")
			return
		end
		send({ from, player }, "Duo")
	end
end

function PlayMenu.init(remotesFolder, notify)
	notifyRemote = notify
	remote = Instance.new("RemoteEvent")
	remote.Name = "PlayMenu"
	remote.OnServerEvent:Connect(onAction)
	remote.Parent = remotesFolder

	Players.PlayerRemoving:Connect(function(player)
		invites[player] = nil
		lastInvite[player] = nil
		leaving[player] = nil
		for invited, invite in invites do
			if invite.from == player then
				invites[invited] = nil
				remote:FireClient(invited, "inviteGone", player.UserId)
			end
		end
	end)
end

return PlayMenu
