-- Alle Texte von Level 1: Erzählung während der Fahrt, das Gespräch mit Sarp und
-- die beiden Enden. Gesprochen wird auf Englisch (Text-to-Speech), dazu Untertitel.
--
-- Ein Text ist entweder ein String oder eine Tabelle { solo = "...", duo = "..." },
-- wenn er allein anders lautet als zu zweit ("I" statt "we").
-- speaker: "narrator" (Erzähler), "sarp" (der Fremde) oder "player" (der Spieler,
-- der die Antwort ausgewählt hat). `voice` = Name der eigenen Sprachaufnahme
-- (siehe Config.VOICE_LINES); fehlt sie, spricht die Roblox-Stimme.
local Dialogue = {}

-- Den passenden Text für allein oder zu zweit holen
function Dialogue.text(entry, duo)
	if type(entry) == "table" then
		return duo and entry.duo or entry.solo
	end
	return entry
end

-- Ungefähre Sprechdauer in Sekunden (danach kommt der nächste Satz)
function Dialogue.duration(text, speed)
	return (1 + #text * 0.068) / (speed or 1)
end

-- Erzählung während der Fahrt; `at` = frühester Zeitpunkt (Sekunden nach dem Start der
-- Zwischensequenz). Ein Satz wartet immer, bis der vorige fertig gesprochen ist.
Dialogue.NARRATION = {
	{ at = 7.5, text = "October 14th. 11:52 PM.", voice = "erzaehler_01" },
	{
		at = 11.5,
		voice = { solo = "erzaehler_02", duo = "erzaehler_03" },
		text = {
			solo = "The camping trip was over. One more night with a host family, the Wagners. Then I could finally go home.",
			duo = "The camping trip was over. One more night with a host family, the Wagners. Then we could finally go home.",
		},
	},
	{ at = 21, text = "Mrs. Wagner's directions were strange. Take the old forest road. Don't stop. No matter what you see.", voice = "erzaehler_04" },
	{
		at = 30,
		radioOff = true, -- ab hier rauscht das Radio nur noch
		voice = { solo = "erzaehler_05", duo = "erzaehler_06" },
		text = {
			solo = "Then the radio lost its signal. And the navigation lost the road. I had to stop.",
			duo = "Then the radio lost its signal. And the navigation lost the road. We had to stop.",
		},
	},
	{
		at = 37,
		voice = { solo = "erzaehler_07", duo = "erzaehler_08" },
		text = {
			solo = "That's when I saw him. A man, walking out of the forest. Straight towards me.",
			duo = "That's when we saw him. A man, walking out of the forest. Straight towards us.",
		},
	},
}

-- Das Gespräch am Fenster. `reveal` = ab diesem Satz kennt man Sarps Namen.
-- `action` lässt Sarp etwas tun, `wait` = zusätzliche Pause danach.
Dialogue.SCRIPT = {
	{ action = "knock", wait = 2 },
	{ speaker = "sarp", text = "Evening.", voice = "sarp_01_evening", action = "lean", wait = 0.8 },
	{ speaker = "sarp", text = "You shouldn't stop here. Not on this road.", voice = "sarp_02_shouldnt_stop", action = "tilt" },
	{
		choice = {
			{
				text = { solo = "I'm looking for the Wagners' house.", duo = "We're looking for the Wagners' house." },
				reply = {
					{ speaker = "sarp", text = "The Wagners...", voice = "sarp_03_the_wagners", wait = 1.2 },
					{ speaker = "sarp", text = "Yes. They told me you would come.", voice = "sarp_04_told_me" },
					{ speaker = "sarp", text = "I'm Sarp. I live close to them.", voice = "sarp_05_im_sarp", reveal = true },
				},
			},
			{
				text = "Who are you?",
				reply = {
					{ speaker = "sarp", text = "Who am I?", voice = "sarp_06_who_am_i", action = "tilt", wait = 1 },
					{ speaker = "sarp", text = "My name is Sarp. I'm a neighbor of the Wagners.", voice = "sarp_07_my_name", reveal = true },
					{ speaker = "sarp", text = { solo = "I've been waiting for you.", duo = "I've been waiting for you two." }, voice = { solo = "sarp_08_waiting_solo", duo = "sarp_08_waiting_duo" } },
				},
			},
		},
	},
	{ speaker = "sarp", text = { solo = "You're the one from the campsite, aren't you?", duo = "You're the two from the campsite, aren't you?" }, voice = { solo = "sarp_09_campsite_solo", duo = "sarp_09_campsite_duo" } },
	{
		choice = {
			{
				text = "How do you know that?",
				reply = { { speaker = "sarp", text = "Small place. Word gets around.", voice = "sarp_10_small_place" } },
			},
			{
				text = "...Yes.",
				reply = { { speaker = "sarp", text = "I know. I watched you pack up your tent this afternoon.", voice = "sarp_11_watched_you" } },
			},
		},
	},
	{ speaker = "sarp", text = "The house is just up that path. The beds are made. There's warm food.", voice = "sarp_12_house_up_path", action = "turnToPath" },
	{ speaker = "sarp", text = "Come. I'll take you.", voice = "sarp_13_come", action = "faceCar", wait = 0.5 },
	{
		choice = {
			{
				text = { solo = "I'll drive there myself.", duo = "We'll drive there ourselves." },
				reply = {
					{ speaker = "sarp", text = "There is no road to the house.", voice = "sarp_14_no_road", action = "stepBack", wait = 1.2 },
					{ speaker = "sarp", text = "But go ahead. I'll be waiting.", voice = "sarp_15_ill_be_waiting" },
				},
				ending = "drive",
			},
			{
				text = { solo = "...Okay. Show me the way.", duo = "...Okay. Show us the way." },
				reply = { { speaker = "sarp", text = "Good. Stay close. And don't look into the trees.", voice = "sarp_17_stay_close" } },
				ending = "follow",
			},
		},
	},
}

-- Die beiden Enden. `at` = Sekunden nach Beginn des Endes, `progress` = wenn der erste
-- Spieler diesen Anteil des Waldwegs geschafft hat (0.5 = Hälfte),
-- `arrive` = Sekunden nach der Ankunft am Haus. `finish` blendet aus.
Dialogue.ENDINGS = {
	-- Nicht folgen: weiterfahren, um die Kurve, die Einfahrt hoch. Sarp steht schon da.
	drive = {
		{
			at = 3,
			speaker = "narrator",
			voice = { solo = "erzaehler_09", duo = "erzaehler_10" },
			text = {
				solo = "I drove on. In the mirror, he just stood there. Watching me go.",
				duo = "We drove on. In the mirror, he just stood there. Watching us go.",
			},
		},
		{
			at = 15,
			speaker = "narrator",
			voice = { solo = "erzaehler_11", duo = "erzaehler_12" },
			text = {
				solo = "The road turned all the way around, back through the forest. As if it didn't want to let me leave.",
				duo = "The road turned all the way around, back through the forest. As if it didn't want to let us leave.",
			},
		},
		{ arrive = 1.5, speaker = "sarp", text = "You took the long way.", voice = "sarp_16_long_way" },
		{
			arrive = 5,
			speaker = "narrator",
			voice = { solo = "erzaehler_13", duo = "erzaehler_14" },
			text = {
				solo = "The house was dark. Not a single light. Nobody was waiting for me. Nobody but him.",
				duo = "The house was dark. Not a single light. Nobody was waiting for us. Nobody but him.",
			},
		},
		{ arrive = 12.5, finish = true },
	},
	-- Folgen: selbst zu Fuß über den Waldweg den Hügel hinauf bis zur Veranda,
	-- Sarp geht voraus. An der Veranda verschwindet er.
	follow = {
		{ progress = 0.06, speaker = "narrator", text = "He walked fast. He never once looked back.", voice = "erzaehler_15" },
		{ progress = 0.37, action = "crack" },
		{
			progress = 0.38,
			speaker = "narrator",
			voice = { solo = "erzaehler_16", duo = "erzaehler_17" },
			text = {
				solo = "Something moved between the trees. Something that kept pace with me.",
				duo = "Something moved between the trees. Something that kept pace with us.",
			},
		},
		{
			progress = 0.7,
			speaker = "narrator",
			voice = "erzaehler_18",
			text = "The path climbed up the hill. With every step, the forest got quieter.",
		},
		{ arrive = 0.5, action = "faceGroup" },
		{ arrive = 1.2, speaker = "sarp", text = "This is where I leave you.", voice = "sarp_18_leave_you" },
		{ arrive = 4.5, speaker = "sarp", text = "Sleep well. And lock your door.", voice = "sarp_19_sleep_well" },
		{ arrive = 8, action = "leave" },
		{
			arrive = 11,
			speaker = "narrator",
			voice = { solo = "erzaehler_19", duo = "erzaehler_20" },
			text = {
				solo = "The house was dark. Not a single light. And I never heard him walk away.",
				duo = "The house was dark. Not a single light. And we never heard him walk away.",
			},
		},
		{ arrive = 18, finish = true },
	},
}

return Dialogue
