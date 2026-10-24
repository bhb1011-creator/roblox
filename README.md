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

## Level 1 – Zwischensequenz „Die Fahrt“

- Man sitzt im Auto: allein am Steuer, zu zweit sitzt der zweite Spieler auf dem Beifahrersitz
- Ego-Perspektive, umsehen mit der Maus (oder Finger am Handy)
- Detaillierter Innenraum: Tacho und Drehzahlmesser laufen mit, Lenkrad dreht in Kurven, Radio, Schaltknüppel, Gurte, Rückspiegel, Duftbaum
- Ca. 30 Sekunden Fahrt durch den Wald in pechschwarzer Nacht: orange Straßenlaternen (manche flackern), Leitpfosten, Leitplanken, Schilder, Strommasten, Innenlicht im Auto
- Während der Fahrt erzählt eine Stimme (Englisch, mit Untertiteln), wo man herkommt: vom Campingplatz, eine Nacht bei der Gastfamilie Wagner, dann nach Hause
- Das Auto hält in einer Parkbucht mit Waldweg und flackernder Laterne
- Der Fremde kommt schon beim Einparken langsam aus dem Wald, klopft ans Beifahrerfenster und redet mit einem. Bis er sich als **Sarp** vorstellt, steht in den Untertiteln „???“
- Drei Antworten wählt der **Fahrer** (Maus/Finger oder Tasten **1** und **2**); nach 25 Sekunden ohne Wahl wird die erste genommen
- **Ende A – nicht folgen:** Man fährt weiter, die Straße macht eine Rechtskurve, dann biegt man in die Einfahrt der Wagners. Sarp steht schon im Scheinwerferlicht vor der Garage
- **Ende B – folgen:** Man steigt aus und läuft mit dem Handylicht über einen unheimlichen Waldweg (tote Bäume, hängende Zweigfiguren, Stoffstreifen) bis zur Veranda. Dort verabschiedet sich Sarp und verschwindet im Wald
- Das Haus der Wagners: großes, altes Holzhaus mit zwei Stockwerken, Veranda, Garage, Schornstein, Zaun, Briefkasten – **kein einziges Licht brennt**
- Danach: „Fortsetzung folgt …“
- Sounds: Musik im Autoradio, Motor, Fahrgeräusche, Blinker, Bremsen, Schotter, Waldgeräusche, Klopfen, knackender Ast; ab der Erzählung über das Funkloch rauscht das Radio

### Sprachausgabe (Text-to-Speech)

Gesprochen wird mit der Text-to-Speech-Funktion von Roblox (`AudioTextToSpeech`). Die Stimmen stehen in
`src/shared/Config.lua` unter `Config.VOICES` (`id` = Nummer der Stimme, `pitch` = Tonhöhe, `speed` = Tempo).
Klingt eine Stimme unpassend, eine andere Nummer eintragen. Geht die Sprachausgabe in Studio nicht, steht im
**Output** eine gelbe Warnung – dann gibt es nur Untertitel, der Ablauf funktioniert trotzdem.
Alle Texte stehen in `src/shared/Dialogue.lua`.

**Testen:** In Studio ein **neues** Spiel (Vorlage „Baseplate“) öffnen. Im Terminal:

```
rojo serve level.project.json --port 34873
```

Im Rojo-Plugin den Port auf **34873** stellen, **Connect**, dann **Play**.
Zu zweit testen: **Test → Clients und Server → 2 Spieler**.

### Sounds und Musik hochladen (einmalig)

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

1. Auf **create.roblox.com → Kreationen → Entwicklungsobjekte (Development Items) → Audio** jede Datei hochladen
   (oder in Studio: **Asset Manager → Bulk Import**).
2. Bei jeder Datei die **ID kopieren** und in `src/shared/Config.lua` bei `Config.SOUNDS` eintragen,
   z. B. `engine = "rbxassetid://1234567890",`.
3. Statt `music_calm.ogg` kannst du auch ein ruhiges Lied aus der **Toolbox → Audio** nehmen
   (Roblox stellt dort viele Lieder kostenlos bereit) und dessen ID eintragen.

Fehlt eine ID, wird der Sound einfach weggelassen – das Spiel funktioniert trotzdem
(für Klopfen und Ast-Knacken wird so lange ein tiefer Schritt-Sound genommen).

## Ordner

| Ordner | Landet in Studio in | Inhalt |
|---|---|---|
| `src/shared` | ReplicatedStorage › Shared | `Config.lua` (Einstellungen), `Parts.lua` und `Forest.lua` (Bausteine), `LevelRoute.lua` (Strecke, Haus und Wege von Level 1), `Dialogue.lua` (alle Texte) |
| `src/lobby/server` | ServerScriptService › Lobby | Bauen der Lobby (Environment, Road, ParkingLot, Camp, Buildings, Decor, Car) und Autos (CarQueue) |
| `src/lobby/client` | StarterPlayerScripts › Lobby | Knöpfe, Hinweise, Shop-Fenster, Lichteffekte |
| `src/level/server` | ServerScriptService › Level | Level 1: Welt, Haus der Wagners, Auto, Sarp, Ablauf des Gesprächs (`DialogueRunner`) |
| `src/level/client` | StarterPlayerScripts › Level | Ablauf der Zwischensequenz, Kamera, Sprachausgabe/Untertitel (`Speech`), Antwortauswahl (`Choices`) |

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
