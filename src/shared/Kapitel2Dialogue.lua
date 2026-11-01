-- Kapitel 2, Anfang: Ankunft bei den Wagners. Alle Texte und der Ablauf.
-- Gesprochen wird Englisch (erst mal mit den Roblox-Stimmen), dazu Untertitel.
--
-- speaker: "mrsWagner", "mrWagner" oder (bei Antworten) der Spieler.
-- Ein Text ist ein String oder { solo = "...", duo = "..." }.
-- `action` passiert vor dem Satz (siehe Kapitel2.lua auf dem Server):
--   knock       – Klopfen, alle bleiben stehen, Stille
--   stepsInside – Schritte im Haus kommen zur Tür
--   doorCrack   – die Tür geht einen Spalt auf (mit Kette)
--   doorClose   – Tür kurz zu
--   chain       – die Kette wird abgenommen, sie tritt zurück
--   doorOpen    – die Tür geht ganz auf
--   mrAppears   – die Kerze flackert fast aus; danach steht Mr. Wagner hinter ihr
--   invite      – beide treten zur Seite, man geht selbst hinein, die Tür fällt zu
--   point       – Mr. Wagner zeigt die Treppe hoch
--   finish      – Ende des Anfangs
-- `look` = wohin der Sprecher schaut: "player", "down" oder "stairs".
-- `wait` = Pause danach (Sekunden).
local Kapitel2Dialogue = {}

Kapitel2Dialogue.NAMES = {
	mrsWagner = "Mrs. Wagner",
	mrWagner = "Mr. Wagner",
}

Kapitel2Dialogue.SCRIPT = {
	{ action = "knock" },
	{ action = "stepsInside" },
	{ action = "doorCrack", wait = 0.9 },
	{ speaker = "mrsWagner", text = "Oh... There you are.", wait = 0.9 },
	{ speaker = "mrsWagner", text = "We were starting to think you got lost." },
	{ action = "doorClose", wait = 0.3 },
	{ action = "chain", wait = 0.8 },
	{ action = "doorOpen", wait = 0.8 },
	{
		choice = {
			{
				text = { solo = "Sorry I'm so late.", duo = "Sorry we're so late." },
				reply = { { speaker = "mrsWagner", text = "Late? No... You're right on time." } },
			},
			{
				text = "Why are all the lights off?",
				reply = { { speaker = "mrsWagner", text = "The power goes out a lot up here. We're used to the dark." } },
			},
		},
	},
	{ speaker = "mrsWagner", text = "You met Sarp on the way, didn't you?", wait = 0.9 },
	{ speaker = "mrsWagner", text = "He always finds our guests first.", wait = 0.4 },
	{ action = "mrAppears", wait = 0.9 },
	{ speaker = "mrWagner", look = "player", text = "He shouldn't have.", wait = 0.7 },
	{ speaker = "mrsWagner", text = "...Richard.", wait = 1.3 },
	{ speaker = "mrWagner", look = "down", text = "...Welcome. You must be tired." },
	{
		choice = {
			{
				text = "Who is Sarp?",
				reply = { { speaker = "mrsWagner", text = "A good neighbor. He takes care of things." } },
			},
			{
				text = "He was... strange.",
				reply = {
					{ speaker = "mrWagner", look = "player", text = "Yes. He is.", wait = 0.5 },
					{ speaker = "mrsWagner", text = "Richard.", wait = 0.4 },
				},
			},
		},
	},
	{ speaker = "mrsWagner", text = "Come in. Don't let the cold in." },
	{ action = "invite", wait = 1.2 },
	{ speaker = "mrsWagner", text = "The children are already asleep. You'll meet them tomorrow.", wait = 0.6 },
	{ speaker = "mrWagner", action = "point", look = "stairs", text = "Your room is upstairs. Second door on the left.", wait = 1.3 },
	{ speaker = "mrWagner", text = "Not the first one.", wait = 1 },
	{ speaker = "mrWagner", look = "player", text = "And whatever you hear tonight...", wait = 0.7 },
	{ speaker = "mrWagner", text = "...it's just the house.", wait = 2.5 },
	{ action = "finish" },
}

-- Wenn nach dem Hereinbitten jemand draußen stehen bleibt
Kapitel2Dialogue.COME_INSIDE = { speaker = "mrsWagner", text = "Please. Come inside." }

return Kapitel2Dialogue
