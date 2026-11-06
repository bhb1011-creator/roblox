# Handoff – Horror-Spiel „Die letzte Nacht“ (Roblox, Kapitel 2)

Stand: 6. November 2026, Branch `claude/optimistic-bardeen-4tmohk`, letzter Spielcode-Commit `185aacc`.
Diese Datei ist für einen **neuen Chat** gedacht: erst den Prompt unten kopieren, der Rest ist Nachschlagewerk.

---

## 1. Prompt zum Einfügen in den neuen Chat

```text
Ich arbeite mit dir an meinem Roblox-Horrorspiel „Die letzte Nacht“ (Fears-to-Fathom-Stil,
allein oder zu zweit, gebaut mit Rojo). Ich bin Anfänger und nutze einen Mac – erkläre bitte
alles in einfachem Deutsch, in kurzen Schritten.

Lies zuerst `handoff.md` im Repo (Stand, Dateien, Fehler, nächste Schritte) und danach
`docs/konzept/wagners.md` (Geschichte und Ablauf von Kapitel 2).

Regeln:
- Arbeite NUR auf dem Branch `claude/optimistic-bardeen-4tmohk`, committe und pushe dort.
  Kein Pull Request, außer ich verlange ihn.
- Schick mir Vorschau-Bilder nur, wenn ich es sage (Bauplan oder Figuren zeige ich nur auf Wunsch).
- Erst Gameplay, Sounds/Audio kommen ganz am Ende.
- Die Geschichte NICHT spoilern: Sarp wurde von der Familie erschaffen und Richard stand lange
  auf ihrer Seite – das kommt erst im DLC und wird in Kapitel 2 nicht erzählt.
- Ich teste selbst: `git pull`, dann `~/Desktop/rojo serve kapitel2.project.json --port 34872`,
  in Roblox Studio „Connect“ und „Play“. Sag mir nach jeder Änderung, was ich neu testen soll.
- Sei ehrlich: Was du in Studio nicht testen konntest, sag klar dazu.

Aktueller Stand: Die ganze Flucht aus dem Haus ist eingebaut (Großmutters Zimmer hinter der
vernagelten Tür 1, Chemikalien + Schießpulver suchen, Bombe, Safe sprengen, Sarp als
Hauptgefahr, Familie mit Quick-Time-Event, 3 Herzen + Game Over, roter Kerzenweg,
Ritualraum = schwarzer Bildschirm). Ich teste das gerade in Studio und gebe dir Rückmeldung.

Als Nächstes: (1) Fehler aus meinem Studio-Test beheben, (2) dann die Fortsetzung hinter dem
Ritualraum (Sarp mutiert) bauen – dazu frage ich dich vorher nach meinen Ideen.
Fang damit an, dass du die Dateien liest und mir in 5 Sätzen sagst, wo wir stehen.
```

---

## 2. Ziel des Projekts

- Roblox-Horrorspiel „Die letzte Nacht“ (Arbeitstitel), Fears-to-Fathom-Stil, **Solo oder Duo**.
- Gebaut mit **Rojo** (Code in `src/`), Teile sind getrennt testbar:
  - Lobby: `default.project.json` (`rojo serve`)
  - Kapitel 1 „Die Fahrt“: `level.project.json` (Port 34873)
  - Kapitel 2 „Die Wagners“: `kapitel2.project.json` (Port 34872 beim User, README nennt 34874)
  - Am Ende sollen Lobby und Kapitel zusammengeführt werden (noch nicht gemacht).
- Der User ist Anfänger auf dem Mac, testet mit `~/Desktop/rojo serve kapitel2.project.json --port 34872`, dann in Studio **Connect** und **Play**.

### Geschichte (vom User festgelegt)
- Sarp ist ein Dämon, die Familie Wagner ist besessen. Anfangs wirkt Sarp böse, später stellt sich
  heraus, dass die Wagners böse sind. Am Ende muss man fliehen.
- **Für den DLC (NICHT in Kapitel 2 erzählen):** Sarp wurde von der Familie erschaffen. Richard war
  die ganze Zeit auf ihrer Seite, erkennt jetzt, dass es nicht mehr gut ist, und lässt die Spieler gehen.
- Kapitel 2 endet, wenn man aus dem Haus ausbricht (nur die Spieler selbst; über den Ritualraum).

### Regeln und Vorlieben des Users
- Nur auf Branch `claude/optimistic-bardeen-4tmohk` entwickeln und pushen. **Kein PR**, außer verlangt.
- Commits enden mit den Attribution-Zeilen, die die Umgebung vorgibt (`Co-Authored-By …` und
  `Claude-Session: https://claude.ai/code/session_01GviBXdi7ntk81fPhdjJLgL`). Keine Modell-IDs in Commit-Texten außerhalb dieser Zeilen.
- **Vorschau-Bilder nur auf Wunsch** (Ausnahme: Baupläne hat er ausdrücklich verlangt).
- **Audio kommt ganz am Ende**, erst Gameplay. Die Sound-Slots in `src/shared/Config.lua` (`Config.SOUNDS`) sind leer, Dateien liegen in `assets/audio`, ein paar Stimmen in `assets/voice`.
- Den ElevenLabs-Wasserzeichen-Ton soll ich **nicht** entfernen (wurde abgelehnt).
- Antworten auf Deutsch, einfach, mit konkreten Testschritten.

---

## 3. Status (was fertig und eingebaut ist)

### Kapitel 2 – Ablauf
1. **Ankunft:** Klopfen, Mrs. Wagner (Kerze), Mr. Wagner, Hereinbitten, Haus erkunden, Kerzen, Schlafen gehen (03:17).
2. **Erste Nacht** (`Night.lua`): Mrs. weckt euch, Abendessen (Familie sitzt am Tisch, Kinder Lucy und Tommy), Klopfen, Familie flieht, **Verstecken** (22 s; Schrank, Tisch, Vorhang), Sarp (zweite Gestalt) sucht, Jumpscare bei Fund, bis zu 5 Runden.
3. **Axt:** Richard schickt einen in den Keller; die Axt liegt jede Nacht an einem von **6 Plätzen** im Keller (Server-Output: `[Kapitel2] Die Axt liegt: …`). Damit **Tür 1** aufbrechen (jetzt: die Tür zu **Großmutters Zimmer** im langen Flur oben).
4. Währenddessen läuft Sarp patrouillierend, verfolgt (sieht Spieler mit Licht, 26 Studs), Schaden 25 / Treffer; F = Licht aus, dann sieht er einen nicht.
5. **Die Flucht** (`Escape.lua`, startet, wenn jemand Großmutters Zimmer betritt):
   - Richard am Pult erklärt (ohne Spoiler), jeder bekommt eine **rote Kerze**, keine Taschenlampe mehr.
   - Suchen: **Chemikalien** und **Schießpulver**, je 2 Stück an 2 von 6 möglichen Plätzen (auf Tischen/Kisten); nimmt man eins, verschwindet das andere. Zu zweit trägt jeder nur eins. Liste oben links.
   - **Sarp ist die Hauptgefahr:** läuft durchs ganze Haus (EG, Keller, langer Flur oben), bemerkt rotes Licht (26), im Dunkeln 12, schleichend 8, hört, wer nicht schleicht (16). Großmutters Zimmer ist sicher.
   - **Familie** (Mrs., Lucy, Tommy) taucht seltener auf (erst nach 45 s, dann alle 40–65 s), packt einen → **Quick-Time-Event** (10× tippen in 4 s: E, Leertaste oder Knopf). Misslingt es: −1 Herz. Packt sie einen, kommt Sarp zu dieser Stelle.
   - Am Pult ablegen → zusammenbauen → Ladung an den Safe → **Richard geht vorher raus** → Lunte mit der Kerze anzünden → 5 s verstecken → **Explosion** (Safetür fliegt weg, Kerzen weg, Sarp rennt hoch, läuft nur einmal durch das Zimmer).
   - Danach **11 rote Kerzen** als Weg, Schlüssel aus dem Safe, **Schleichen (C)**, Sarp tödlich im EG.
   - Schlüssel öffnet das **Regal vor dem Geheimgang** (Vorratskeller) → **Ritualraum** → Bild sofort schwarz („Der Ritualraum … Fortsetzung folgt“).
6. **Herzen:** 3 pro Spieler für das ganze Kapitel (Attribut `Hearts`, oben rechts ♥♥♥). −1 bei Sarp-Treffer/Gefundenwerden, Familie-Griff, Explosion ohne Versteck, Sterben. Bei 0: **Game Over** (Knopf „Nochmal versuchen“ → wieder 3 Herzen).
7. **Verstecke** überall im Haus (Schränke in Gästezimmer, langem Flur, Salon, Wohnzimmer, Waschkeller + Esszimmer + drei in Großmutters Zimmer). Raus: **E / Leertaste / Knopf „[E] Rauskommen“** (Remote `LeaveHide`). Versteckt man sich vor Sarps Augen, schaut er dort nach.

### Tasten
E = Aktion/Verstecken/Rauskommen/QTE, F = Kerze/Licht an/aus, C = Schleichen (nur Flucht), Leertaste = QTE/Rauskommen.

### Teststart
`Config.TEST_START_KAPITEL2` in `src/shared/Config.lua` – **steht gerade auf `"tuer1"`** (man erscheint direkt in Großmutters Zimmer bei Richard).
- `""` = normaler Start vor der Haustür
- `"nachVerstecken"` = direkt nach dem Verstecken im Esszimmer (Richard, Axt)
- `"tuer1"` = Flucht

### Wichtig: Nichts davon wurde in echtem Roblox Studio getestet
Alles lief nur in meiner Mock-Testumgebung (siehe Abschnitt 7). Der User testet gerade.

---

## 4. Aktive / wichtige Dateien

| Datei | Zweck |
|---|---|
| `src/kapitel2/server/Kapitel2.lua` (~1100 Zeilen) | Start, Remotes (`SceneEvent`, `SceneChoice`, `Light`, `Sneak`, `LeaveHide`, `Qte`, `Restart`), Spawn, Kerze (normal/rot/none), Herzen/Game Over, Türen, Betten, Szenen; Teststart |
| `src/kapitel2/server/Night.lua` (~1350) | Erste Nacht: Aufwachen, Essen, Verstecken, Axt, Tür 1 aufbrechen, Patrouille, Familie-Erscheinungen; ruft am Ende `Escape.run` |
| `src/kapitel2/server/Escape.lua` (~1320) | Die Flucht: Items, Pult/Safe/Bombe, Explosion, Sarp-Jagd/Suche, Familie + QTE, Kerzenweg, Schlüssel, Regal, Ritualraum |
| `src/kapitel2/server/Mansion.lua` (~1730) | Das Haus (Räume, Wände, Türen, Möbel), `Mansion.point`, `Mansion.escape` (Safe, Pult, Verstecke, Fundorte, Wege), `Mansion.axeSpots`, `Mansion.hideSpots` |
| `src/kapitel2/server/Furniture.lua`, `HouseInterior.lua` | Möbel (Bett, Schrank, Versteck-Schrank, Pult …), Treppe/Halle/Kerzen |
| `src/kapitel2/server/Wagners.lua` | NPCs (Mrs., Mr., Lucy, Tommy), Sitzen/Aufstehen, Laufen |
| `src/kapitel2/server/SarpStage2.lua` | Sarps zweite Gestalt (Modell + Kopfdrehung) |
| `src/kapitel2/client/Scene.lua` (~1240) | Anzeige: Kerze/Licht, Herzen, Game Over, QTE, Aufgabenliste, Schleichen, Jumpscare, Nachrichten vom Server |
| `src/shared/Kapitel2Dialogue.lua` | Alle Texte (Englisch gesprochen): Szenen, `NIGHT_*`, `ESCAPE_INTRO`, `ESCAPE`, `FAMILY_ANGRY`, `SARP_*` |
| `src/shared/Config.lua` | Sounds (leer), Stimmen, `TEST_START_KAPITEL2` |
| `src/level/server/House.lua`, `World.lua`, `ForestWalk.lua` | Von Kapitel 1 mitgenutzt (Hof, Welt, Spawn); `House.lua` hat ein Loch im Hof über der Kellertreppe |
| `docs/konzept/wagners.md` | Konzept: Geschichte, Nacht, Flucht, Balance |
| `docs/konzept/hausplan_flucht.png` | Bauplan: Fundorte (C = Chemikalien, P = Pulver), Verstecke (V), Kerzenweg, Großmutters Zimmer |
| `docs/konzept/hausplan_keller_axt.png`, `hausplan_nacht.png` | Axt-Plätze, Verstecke im Esszimmer |

Koordinaten im Haus: `Mansion.point(x, y, höhe)` mit Plan-Koordinaten; Stockwerke `Mansion.FLOORS` = `K` (-8.3), `E` (1.712), `O` (11.6).

---

## 5. Änderungen in dieser Session (grob chronologisch)

- Frühere Phasen (Kurzfassung): Haus gebaut und mehrfach auf Überlagerungen geprüft, Treppe neu (steiler, Platz vor der ersten Stufe), Kellergeländer, Türen/Betten/Schlafen, NPC-Figuren (wieder „blockig wie die Kinder“), Fehlerausgabe auf dem Ladebildschirm, Konversation robuster.
- **Erste Nacht** gebaut: Wecken, Essen, Klopfen, Verstecken (Schrank/Tisch/Vorhang), Sarp Stufe 2, Jumpscares, Axt, Tür 1 → schwarz.
- Sarp als Patrouille mit lauten Schritten, Verfolgung + Schaden, F = Licht aus, Familie erscheint komisch.
- Kerzenlicht heller, Teststart `"nachVerstecken"`.
- Familie sitzt richtig am Tisch (`Wagners.sit/stand`).
- **Überlagerungen** behoben: Rasenplatte schwebte in der Kellertreppe (`House.lua` Loch), schwebende Fußleiste, Betten/Schrank/Badewanne in Wänden, Tapete-Probleme, flackernde Flächen (26 → 1).
- **Axt** an 6 zufälligen Kellerplätzen; Bauplan dazu.
- **Familie** erscheint nur an geprüften freien Stellen, blendet ein/aus, dreht sich mit.
- **Flucht** komplett gebaut (`Escape.lua`), neue Texte, rote Kerzen, Schleichen (C), Bauplan `hausplan_flucht`.
- Teststart `"tuer1"` direkt in den Raum.
- **Raumtausch:** Tür 1 = Großmutters großes Zimmer (rot/gedämpft beleuchtet, Pult, Safe unter dem Bild, 3 Verstecke), kleines Galerie-Zimmer = abgeschlossene Kammer.
- Sarp = Hauptgefahr (ganzes Haus), Familie mit **QTE**, Verstecke per Taste verlassen.
- **Herzen/Game Over**, Familie seltener + Sarp kommt zur Griff-Stelle, Verstecke im ganzen Haus, Richard geht vor der Explosion, 2× jedes Item auf Möbeln, weniger Kerzen, sichtbarer E-Knopf.
- `/session-start-hook` wurde angefangen (Rojo und Luau als mögliche Abhängigkeiten geprüft), aber **vom User abgebrochen – es existiert kein Hook**.

---

## 6. Fehler, die passiert sind (und wie sie gelöst wurden)

Echte Roblox-Fehler (vom User gemeldet):
- `Tile` ist kein Material → `CeramicTiles`. Die Mock-Umgebung prüft Enums jetzt gegen `api.json`.
- „Infinite yield … Kapitel2“ → Remotes werden zuerst angelegt, Bau in `xpcall`, Status auf dem Ladebildschirm.
- TTS **FilteredText**: „You'll meet them tomorrow“ wurde gefiltert → umformuliert („You'll see them at breakfast“). **Risiko:** auch „black powder“ könnte gefiltert werden.
- Treppe: User meldete mehrfach „nicht behoben“; echte Ursache: kein Platz vor der ersten Stufe → neues Design (steiler, ab z -10.6, Rampe).
- Kellergeländer ragte in die Küche; Hügel-Terrain im Keller; schwebende Möbel/Bilder vor Fenstern → per Analyse-Skripten behoben.
- NPC-Look: „zu rund/natürlich“ → zurück zum früheren blockigen Stil.

Fehler in meinem Code / Tests:
- `if not completed or handleCatch()` kurzgeschlossen → `handleCatch()` vorher aufrufen.
- Endlosschleifen in der Mock-Umgebung (synchrones `task.spawn`) → `STOP_AT`.
- Sarp jagte trotz Licht aus → Dunkle Spieler werden nie erkannt.
- Neu in dieser Session: `enterEscape` war beim Aufruf noch `nil` (Wartschleife eingebaut); Schlüssel-Prompt war zu früh aktiv; Sarp-Rundgang wählte Punkte auf falschem Stockwerk (jetzt `nearestOnFloor`); Game-Over wurde durch „retry“-Nachricht überschrieben (jetzt `restart = true`); fehlendes `MaxHealth` im Mock.
- Teststart `"tuer1"` setzte erst in die Halle → jetzt direkt im Raum.

Bekannte Einschränkungen der Mock-Tests: `PivotTo` auf Modellen, `Humanoid.MoveDirection`, Raycasts und Pathfinding sind nicht echt.

---

## 7. Test- und Hilfswerkzeuge (WICHTIG: gehen mit der Sitzung verloren)

Die Werkzeuge lagen nur im Scratchpad dieser Sitzung (`/tmp/claude-0/…/scratchpad`) und sind im neuen Chat **weg**:
- `luau` / `luau-analyze` / `luau-compile` (aus `https://github.com/luau-lang/luau/releases/latest/download/luau-ubuntu.zip`)
- `rojo` (Linux-Binary, `https://github.com/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip`; `rokit.toml` nennt 7.7.1)
- `preview/` mit Mock-Roblox-API (`mock4–6.luau`), `build.py` (setzt Module + Test-Ende zusammen), Analyse-Skripte (`zfight`, `floating`, `checks`, `pierce`), `mansion.html` (three.js-Renderer), `plan_escape.py` (Bauplan → PNG)
- `api.json` (Roblox-API-Dump für Enum-Prüfung)

Was im neuen Chat ohne den Mock noch geht:
- Syntax prüfen: `luau-compile --null datei.lua`, `luau-analyze datei.lua`
- Bauen: `rojo build kapitel2.project.json -o k2.rbxl`
- Alles Spielerische nur noch **in Studio** testen (User) oder einen neuen Mock schreiben.
- Die Baupläne (`docs/konzept/*.html/png`) liegen im Repo; die Generator-Skripte (`plan_*.py`) nicht.

---

## 8. Nächste Schritte

1. **User-Rückmeldung aus dem Studio-Test abwarten** und Fehler beheben. Besonders prüfen:
   - Laufen NPCs/Sarp mit `PathfindingService` sinnvoll (Türen, Treppen, nicht durch Wände)?
   - Funktioniert `Humanoid.MoveDirection` auf dem Server für „Sarp hört einen“?
   - Safe-Tür fliegt weg (Welds/Velocity), Rauch, Explosion sichtbar?
   - ProximityPrompts (Verstecke, Items, Pult, Safe, Regal), QTE, Herzen/Game Over, Sneak-Knopf.
   - Balance: Sarps Tempo (3.4 Patrouille, 7.2 Jagd), Familie-Häufigkeit, Sichtweiten.
   - TTS-Filter für neue Sätze.
2. **Fortsetzung** nach dem Ritualraum (User will das als Nächstes, Ideen vorher erfragen): mutierter Sarp, Ende von Kapitel 2 (nur Spieler brechen aus, Story-Wahrheit bleibt für DLC).
3. Später / offen:
   - **Audio** füllen (Slots in `Config.SOUNDS`, u. a. neu: `fuse`, `explosion`, `sarpRoar`, `scream`, `heavyKnock`, `doorBurst`, `sarpStep`, `sarpBreath`, `jumpscare`), ElevenLabs-Stimmen.
   - Herzen auch über **Kapitel 1 und Lobby** speichern (jetzt nur Kapitel 2, Attribut `Hearts`).
   - Lobby und Kapitel zusammenführen.
   - `Config.TEST_START_KAPITEL2` wieder auf `""` setzen, wenn Testphase vorbei ist.
   - `sarp_07` (offen aus früherer Planung).
   - Optional: SessionStart-Hook (`.claude/hooks/session-start.sh`) für Rojo/Luau – war angefangen, wurde abgebrochen.
