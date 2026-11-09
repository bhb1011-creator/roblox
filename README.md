# Horror-Spiel (Arbeitstitel: „Die letzte Nacht“)

Ein Roblox-Horrorspiel nach wahren Begebenheiten – allein oder zu zweit.

## Aktueller Stand: Lobby (erster Entwurf)

- **Ego-Perspektive** mit leichtem Kopfwippen und Punkt in der Bildmitte
- Waldparkplatz im **Sonnenuntergang** (die Zeit bleibt stehen, Himmel ohne Sterne), Asphalt nur im Autobereich, weiße Flutlichtmasten, sonst flacher Waldboden
- Hohe, detaillierte Tannen, tote Bäume, Büsche, Felsen und umgestürzte Stämme
- Waldstraße mit Kurve, Leitpfosten und Warnschildern, die im Dunkeln verschwindet
- Begehbarer **Kiosk** mit Verkäufer und drei Snack-Regalen (Snacks ansehen per **E**)
- **Kasse** mit Kassierer: Wiederbelebungen und Rebirths für Robux (werden gespeichert)
- **Grillplatz** in der Mitte: Feuerstelle mit Schwenkgrill, Bänke und Biertische zum Hinsetzen, gemauerter Grill, Zelte, Lichterketten außen herum
- Große Bestenliste, Pinnwand mit Vermisst-Zetteln am Rand
- Holzzaun, verlassener Wohnwagen mit Campingecke, Topfpflanzen, Blumenkasten an der Bestenliste, Farne und Büsche am Zaun, Trittsteinwege
- **4 Autos:** 2× „Allein“ (1 Platz) und 2× „Zu zweit“ (2 Plätze)
  - Einsteigen mit der Taste **E** (oder Antippen am Handy); das Schild über dem Auto erscheint, wenn man nah dran ist
  - Ist das Auto voll, läuft ein Countdown von 10 Sekunden
  - Aussteigen mit dem Knopf **„Aussteigen“** oder der Leertaste – dann wird der Countdown abgebrochen
  - Danach fährt das Auto über die Straße in den Wald und der Bildschirm wird schwarz
- Infotafel und Bestenliste (Snack-Kauf mit Münzen und die Bestenliste kommen später)

Solange es das Horror-Level noch nicht gibt, fährt das Auto nur eine Proberunde
und man landet wieder am Lagerfeuer.

## Testen in Roblox Studio

1. Roblox Studio öffnen → neues Spiel mit der Vorlage **„Baseplate“**.
2. In VS Code diesen Ordner öffnen.
3. Rojo starten: im Terminal `rojo serve` (nutzt automatisch `default.project.json`).
4. In Studio: **Plugins → Rojo → Connect**.
5. Auf **Play** drücken.

Die Lobby wird erst beim **Play** per Code gebaut. Im Bearbeiten-Modus siehst du nur die
Skripte (z. B. ServerScriptService › Lobby) und die leere Baseplate – das ist normal.
Die Baseplate wird beim Start automatisch entfernt.

## Teile einzeln testen

Jeder Teil ist ein eigenes Rojo-Projekt (am Ende wird alles zusammengefügt):

| Teil | Starten mit |
|---|---|
| Lobby | `rojo serve` (nutzt `default.project.json`) |
| Kapitel 1 – Die Fahrt | `rojo serve level.project.json --port 34873` |
| Kapitel 2 – Die Wagners | `rojo serve kapitel2.project.json --port 34874` |
| **Ganzes Spiel** (Kapitel 1 → 2 → 3 am Stück) | `rojo serve spiel.project.json --port 34875` |

Danach in Studio: **Plugins → Rojo → Connect** (beim Port die richtige Zahl eintragen), dann **Play**.
Am besten jeden Teil in einem eigenen Studio-Ort (eigene Datei) testen.

## Kapitel 2 – „Die Wagners“ (Anfang)

- Man startet auf der Veranda vor der Haustür (wie am Ende von Kapitel 1), läuft selbst in der Ego-Perspektive, Handy als Taschenlampe
- An der Tür erscheint **„Klopfen“** (Taste **E** oder antippen). Danach: lange Stille, Schritte im Haus, die Tür geht einen Spalt auf – mit Kette
- **Mrs. Wagner** steht mit einer Kerze dahinter: übertrieben freundlich, starres Lächeln, blinzelt nie, ihr Kopf dreht sich immer mit einem mit
- Sie nimmt die Kette ab und öffnet ganz. Zwei Antworten wählt, wer geklopft hat (Tasten **1** und **2**)
- Die Kerze flackert fast aus – danach steht **Mr. Wagner** plötzlich hinter ihr (groß, hager, Bart, blutig verbundene Hand, schaut meist auf den Boden)
- Sie bitten einen herein; man geht selbst hinein, die Tür fällt hinter einem zu. (Wer draußen bleibt, wird erinnert und nach 40 Sekunden hereingeholt)
- Danach darf man sich frei im Haus umsehen
- **Das Haus** (`src/kapitel2/server/Mansion.lua`, Bauplan: `docs/konzept/hausplan.html`): ein großes, verwinkeltes Herrenhaus mit Keller, Erdgeschoss und Obergeschoss, rundem Turm (vorne links), Erkern, sechseckigem Glas-Wintergarten (hinten rechts), zwei Schornsteinen. Über 20 eingerichtete Räume: Eingangshalle mit Galerie, Wohnzimmer mit Kamin, Esszimmer (gedeckt für sieben), Küche mit Kellertreppe, Speisekammer, Salon mit Klavier, Arbeitszimmer (abgeschlossen), WC, Gartenflur, Wintergarten; oben langer Flur, Gästezimmer (euer Zimmer), die vernagelte Tür 1, Zimmer von Lucy und Tommy, Bad, Elternschlafzimmer, Spielzimmer, Nähzimmer im Turm, Großmutters Zimmer (abgeschlossen); im Keller Vorratskeller, Waschkeller, Heizungsraum, Kriechkeller, hinter einem Regal ein Geheimgang zum runden Ritualraum und ein Tunnel in den Wald
- **Die Familie** (`src/kapitel2/server/Wagners.lua`): Mrs. und Mr. Wagner an der Tür, Lucy steht oben an der Galerie und schaut herunter (obwohl sie „schläft“), Tommy steht im Salon am Klavier
- Stimmen erst mal mit der Roblox-Stimme (Mrs. Wagner: Stimme 4, Mr. Wagner: Stimme 5, siehe `Config.VOICES`)
- Texte und Ablauf: `src/shared/Kapitel2Dialogue.lua`, Konzept: `docs/konzept/wagners.md`

## Level 1 – Zwischensequenz „Die Fahrt“

- Man sitzt im Auto: allein am Steuer, zu zweit sitzt der zweite Spieler auf dem Beifahrersitz
- Ego-Perspektive, umsehen mit der Maus (oder Finger am Handy)
- Detaillierter Innenraum: Tacho und Drehzahlmesser laufen mit, Lenkrad dreht in Kurven, Radio, Schaltknüppel, Gurte, Rückspiegel, Duftbaum
- Ca. 30 Sekunden Fahrt durch den Wald in pechschwarzer Nacht: orange Straßenlaternen (manche flackern), Leitpfosten, Leitplanken, Schilder, Strommasten, Innenlicht im Auto
- Während der Fahrt erzählt eine Stimme (Englisch, mit Untertiteln), wo man herkommt: vom Campingplatz, eine Nacht bei der Gastfamilie Wagner, dann nach Hause
- Das Auto hält in einer Parkbucht mit Waldweg und flackernder Laterne
- Der Fremde kommt schon beim Einparken langsam aus dem Wald, klopft ans Beifahrerfenster und redet mit einem. Bis er sich als **Sarp** vorstellt, steht in den Untertiteln „???“
- Drei Antworten wählt der **Fahrer** (Maus/Finger oder Tasten **1** und **2**); nach 25 Sekunden ohne Wahl wird die erste genommen
- **Ende A – nicht folgen:** Man fährt weiter. Die Straße wendet in einer weiten Kehre (180°) und führt auf der anderen Seite des Waldes zurück; dann biegt man in die Einfahrt der Wagners und fährt den Hang hinauf. Sarp steht schon im Scheinwerferlicht vor der Garage. Er sagt „You took the long way.“, geht an der Garage vorbei in den Wald und löst sich auf. Dann wird es kurz schwarz, man steigt aus und steht (selbst laufend) auf der Veranda vor der Haustür.
- **Ende B – folgen:** Man steigt aus und **läuft selbst** (WASD oder Stick, Ego-Perspektive, Handy als Taschenlampe, **Shift = rennen** mit Ausdauer) über einen unheimlichen Waldweg quer durch dichten Wald den Hügel hinauf. Der Weg ist hell, mit Randsteinen und schwach leuchtenden Pilzen. Sarp geht gleichmäßig voraus und wartet nicht. An der Veranda verabschiedet er sich und verschwindet im Wald
- **Das Biest** ist der Fremde in seiner letzten Gestalt (Stufe 3 aus `docs/konzept/der_fremde_stufen.png`): riesig und dürr, ovaler Kopf mit einem Maul vom Scheitel bis zum Kinn, rot glühende Flecken und Adern, Fetzen der olivgrünen Jacke. Wer Sarp nicht folgt (mehr als ~26 Studs zurück oder weit neben dem Weg), hört nach 4 Sekunden ein Knurren im Wald, nach 9 Sekunden näher, und nach 14 Sekunden kommt es und jagt einen. Wer zurück zu Sarp rennt, ist sicher. Wen es erwischt, der stirbt (Schreckmoment, „DU BIST GESTORBEN“) und taucht nach ein paar Sekunden hinter Sarp wieder auf
- Das Haus der Wagners steht oben auf einem Hügel: großes, altes Holzhaus mit zwei Stockwerken, Veranda, Garage, Schornstein, Zaun, Briefkasten – **kein einziges Licht brennt**
- Danach: „Fortsetzung folgt …“
- Sounds: Musik im Autoradio, Motor, Fahrgeräusche, Blinker, Bremsen, Schotter, Waldgeräusche, Klopfen, knackender Ast; ab der Erzählung über das Funkloch rauscht das Radio

### Sprachausgabe (Text-to-Speech)

Gesprochen wird mit der Text-to-Speech-Funktion von Roblox (`AudioTextToSpeech`). Die Stimmen stehen in
`src/shared/Config.lua` unter `Config.VOICES` (`id` = Nummer der Stimme, `pitch` = Tonhöhe, `speed` = Tempo,
`effects` = Bass/Höhen und Hall). Sarp hat eine tiefe, langsame Männerstimme mit Hall, die Spieler und der
Erzähler eine hellere Stimme. Die Liste aller Stimmen steht direkt darüber in der Config. Die automatische Übersetzung von Roblox (`AutoLocalize`) ist für Stimmen und Untertitel ausgeschaltet,
damit sie auch bei deutschen Spielern Englisch bleiben. Geht die Sprachausgabe in Studio nicht, steht im
**Output** eine gelbe Warnung – dann gibt es nur Untertitel, der Ablauf funktioniert trotzdem.
Alle Texte stehen in `src/shared/Dialogue.lua`.

### Eigene Sprachaufnahmen (Sarp und Erzähler)

Die Rohaufnahmen liegen in `assets/voice/raw`, die fertig bearbeiteten Dateien (Stille entfernt,
gleich laut, etwas dunkler; Satz 16 gedämpft wie durch die Windschutzscheibe) als `.ogg` in
`assets/voice`. Die `.ogg`-Dateien bei Roblox hochladen und die IDs in `src/shared/Config.lua`
unter `Config.VOICE_LINES` bei `id` eintragen. Sobald eine ID eingetragen ist, wird dieser Satz
mit der Aufnahme gesprochen (Sarp aus seiner Richtung mit etwas Hall, der Erzähler überall gleich laut),
sonst mit der Roblox-Stimme. Die Erzähler-Dateien heißen `erzaehler_01` bis `erzaehler_20`; bei zwei
aufeinanderfolgenden Nummern ist die erste für allein („I“) und die zweite für zu zweit („we“).

**Testen:** In Studio ein **neues** Spiel (Vorlage „Baseplate“) öffnen. Im Terminal:

```
rojo serve level.project.json --port 34873
```

Im Rojo-Plugin den Port auf **34873** stellen, **Connect**, dann **Play**.
Zu zweit testen: **Test → Clients und Server → 2 Spieler**.

### Sounds und Musik hochladen (einmalig)

**Kapitel 3:** alle Sounds liegen zusammen in `assets/audio/kapitel3` (56 Dateien, selbst
erzeugt mit `python3 tools/make_kapitel3_audio.py assets/audio/kapitel3`). In Studio: Asset
Manager → **Bulk Import** → alle Dateien aus dem Ordner auswählen. Danach die IDs bei
`Config.SOUNDS` eintragen (der Dateiname steht dort jeweils im Kommentar).

Die Sounds liegen in `assets/audio` (selbst erzeugt, frei verwendbar):

| Datei | Wofür |
|---|---|
| `music_calm.ogg` | ruhige Musik im Autoradio |
| `engine_loop.ogg`, `road_loop.ogg`, `wind_loop.ogg` | Motor, Abrollgeräusch, Fahrtwind |
| `brake.ogg`, `gravel_loop.ogg`, `blinker_tick.ogg` | Bremsen, Schotter in der Parkbucht, Blinker |
| `forest_night_loop.ogg` | Grillen, Wind und eine Eule im Wald |
| `footstep.ogg`, `lamp_buzz_loop.ogg` | Schritte des Fremden, summende Laterne |
| `radio_static_loop.ogg`, `sting.ogg` | Radio-Rauschen und Schreck-Akzent, wenn der Fremde ankommt |
| `knock.ogg`, `twig_snap.ogg` | Klopfen ans Autofenster, knackender Ast im Wald (Config: `knock`, `twig`) |
| `beast_growl.ogg`, `beast_roar.ogg` | Knurren und Brüllen des Biests (Config: `growl`, `roar`) |
| `beast_breath_loop.ogg`, `beast_step.ogg` | Atmen und schwere Schritte des Biests (Config: `beastBreath`, `beastStep`) |
| `forest_wind_loop.ogg` | Wind in den Tannen (Config: `forestWind`) |
| `leaves_rustle.ogg`, `tree_creak.ogg` | Rascheln und knarrende Bäume aus zufälligen Richtungen (Config: `rustle`, `treeCreak`) |
| `house_creak.ogg`, `swing_creak_loop.ogg`, `shutter_rattle_loop.ogg` | Knarrendes Haus, quietschende Schaukel, klappernder Fensterladen (Config: `houseCreak`, `swingCreak`, `shutterRattle`) |
| `car_tick_loop.ogg`, `radio_voices.ogg` | Abkühlender Motor, Stimmen im Radiorauschen (Config: `carTick`, `radioVoices`) |
| `heartbeat_loop.ogg`, `scared_breath_loop.ogg` | Herzschlag und panisches Atmen, wenn das Biest nah ist (Config: `heartbeat`, `scaredBreath`) |
| `step_gravel.ogg`, `step_dirt.ogg`, `step_wood.ogg` | Schritte auf Schotter, Waldboden und Holz (Config: `stepGravel`, `stepDirt`, `stepWood`) |
| `owl_hoot.ogg`, `wolf_howl.ogg`, `raven_caw.ogg`, `fox_scream.ogg` | Tiere weit weg im Wald (Config: `owl`, `wolf`, `raven`, `foxScream`) |
| `bird_flyaway.ogg` | Vogel fliegt in der Nähe erschrocken auf (Config: `birdFlyaway`) |
| `door_creak.ogg`, `door_slam.ogg`, `door_chain.ogg` | Kapitel 2: Haustür knarrt, fällt zu, Türkette (Config: `doorCreak`, `doorSlam`, `doorChain`) |

1. Auf **create.roblox.com → Kreationen → Entwicklungsobjekte (Development Items) → Audio** jede Datei hochladen
   (oder in Studio: **Asset Manager → Bulk Import**).
2. Bei jeder Datei die **ID kopieren** und in `src/shared/Config.lua` bei `Config.SOUNDS` eintragen,
   z. B. `engine = "rbxassetid://1234567890",`.
3. Statt `music_calm.ogg` kannst du auch ein ruhiges Lied aus der **Toolbox → Audio** nehmen
   (Roblox stellt dort viele Lieder kostenlos bereit) und dessen ID eintragen.

Fehlt eine ID, wird der Sound einfach weggelassen – das Spiel funktioniert trotzdem
(für Klopfen, Ast-Knacken und die Geräusche des Biests wird so lange ein anderer Sound tiefer abgespielt).

## Ordner

| Ordner | Landet in Studio in | Inhalt |
|---|---|---|
| `src/shared` | ReplicatedStorage › Shared | `Config.lua` (Einstellungen), `Parts.lua` und `Forest.lua` (Bausteine), `LevelRoute.lua` (Strecke, Haus und Wege von Level 1), `Dialogue.lua` (alle Texte), `Beast.lua` (das Biest) |
| `src/lobby/server` | ServerScriptService › Lobby | Bauen der Lobby (Environment, Road, ParkingLot, Camp, Buildings, Decor, Car) und Autos (CarQueue) |
| `src/lobby/client` | StarterPlayerScripts › Lobby | Knöpfe, Hinweise, Shop-Fenster, Lichteffekte |
| `src/level/server` | ServerScriptService › Level | Level 1: Welt, Haus der Wagners, Auto, Sarp, Ablauf des Gesprächs (`DialogueRunner`), Waldweg mit Biest (`ForestWalk`) |
| `src/level/client` | StarterPlayerScripts › Level | Ablauf der Zwischensequenz, Kamera, Sprachausgabe/Untertitel (`Speech`), Antwortauswahl (`Choices`), Biest/Rennen/Tod (`BeastView`), Umgebungsgeräusche (`Ambience`) |
| `src/kapitel2/server` | ServerScriptService › Kapitel2 | Kapitel 2: Start (`Main`), Ablauf (`Kapitel2`), das große Haus (`Mansion`), Möbel (`Furniture`), Einrichtung der Eingangshalle (`HouseInterior`), die Familie (`Wagners`). Welt, Hof/Veranda/Tür (`House`) und `ForestWalk` kommen aus `src/level/server` |
| `src/kapitel2/client` | StarterPlayerScripts › Kapitel2 | Kapitel 2: Start (`Main`), Kamera/Licht/Kerzen/Köpfe (`Scene`). `Speech`, `Choices` und `Ambience` kommen aus `src/level/client` |

## Robux-Produkte einrichten (Kasse)

1. Spiel veröffentlichen.
2. Auf create.roblox.com → dein Spiel → **Monetarisierung → Entwicklerprodukte** drei Produkte anlegen
   (Wiederbelebung, 3× Wiederbelebung, Rebirth) und den Preis festlegen.
3. Die **Produkt-IDs** in `src/shared/Config.lua` bei `Config.PRODUCTS` eintragen (statt `0`).
4. Damit Käufe auch in Studio gespeichert werden: Spieleinstellungen → Sicherheit →
   **Studio-Zugriff auf API-Dienste** einschalten.

## Grafik

Beide Projektdateien stellen **Lighting → Technology** automatisch auf **Future**.
In Level 1 ist außerdem **StreamingEnabled** aus, damit die ganze Strecke sofort geladen ist.
Rojo entfernt beim Verbinden Skripte, die nicht zum jeweiligen Ort gehören.

## Später, wenn das Level fertig ist

1. Im Roblox-Spiel einen zweiten Ort (Place) für das Level anlegen und dessen **PlaceId** in
   `Config.GAME_PLACE_ID` eintragen.
2. In den Spieleinstellungen der Lobby **max. 20 Spieler** einstellen.
3. Teleport funktioniert nur im veröffentlichten Spiel, nicht in Studio.
