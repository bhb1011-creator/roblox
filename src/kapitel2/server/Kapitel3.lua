-- Kapitel 3: beginnt, sobald jemand die alte Tür hinter dem Regal öffnet (Escape.lua).
-- Schwarz, "KAPITEL 3", dann geht es im Ritualraum weiter.
local Players = game:GetService("Players")

local Kapitel3 = {}

Kapitel3.TITLE = "Das Ritual" -- Untertitel der Kapitelkarte (hier ändern)

function Kapitel3.run(kit)
	local ctx = kit.ctx
	local remotes, event = ctx.remotes, ctx.event
	remotes:SetAttribute("Phase", "kapitel3")
	remotes:SetAttribute("SneakAllowed", false)
	ctx.setMovement(false)
	event:FireAllClients({ type = "k3", step = "card", title = Kapitel3.TITLE })
	print("Kapitel 3: " .. #Players:GetPlayers() .. " Spieler – die Tür ist offen.")
end

return Kapitel3
