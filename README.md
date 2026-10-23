# Horror-Spiel (Arbeitstitel: „Die letzte Nacht“)

Ein Roblox-Horrorspiel nach wahren Begebenheiten – allein oder zu zweit.

## Aktueller Stand: Lobby (erster Entwurf)

- Parkplatz am Waldrand, immer im **Sonnenuntergang** (die Zeit bleibt stehen)
- **4 Autos:** 2× „Allein“ (1 Platz) und 2× „Zu zweit“ (2 Plätze)
  - Einsteigen mit der Taste **E** (oder Antippen am Handy)
  - Ist das Auto voll, läuft ein Countdown von 10 Sekunden
  - Aussteigen mit dem Knopf **„Aussteigen“** oder der Leertaste – dann wird der Countdown abgebrochen
  - Danach fährt das Auto über die Straße in den Wald und der Bildschirm wird schwarz
- Lagerfeuer als Treffpunkt, flackernde Laternen, Nebel
- Infotafel, Shop-Kiosk und Bestenliste (Shop und Bestenliste sind noch Platzhalter)

Solange es das Horror-Level noch nicht gibt, fährt das Auto nur eine Proberunde
und man landet wieder am Lagerfeuer.

## Testen in Roblox Studio

1. Roblox Studio öffnen → neues Spiel mit der Vorlage **„Baseplate“**.
2. In VS Code diesen Ordner öffnen.
3. Rojo starten: in der Rojo-Erweiterung **`lobby.project.json`** auswählen und auf Start klicken
   (oder im Terminal: `rojo serve lobby.project.json`).
4. In Studio: **Plugins → Rojo → Connect**.
5. Auf **Play** drücken.

Die Lobby wird beim Start automatisch per Code gebaut – vorher ist die Welt leer, das ist normal.

## Ordner

| Ordner | Landet in Studio in | Inhalt |
|---|---|---|
| `src/shared` | ReplicatedStorage › Shared | `Config.lua` – Einstellungen (Titel, Countdown, Autos …) |
| `src/lobby/server` | ServerScriptService › Lobby | Bauen der Lobby, Autos, Abfahrt |
| `src/lobby/client` | StarterPlayerScripts › Lobby | Knöpfe, Hinweise, Shop-Fenster, Lichteffekte |

## Später, wenn das Level fertig ist

1. Im Roblox-Spiel einen zweiten Ort (Place) für das Level anlegen und dessen **PlaceId** in
   `Config.GAME_PLACE_ID` eintragen.
2. In den Spieleinstellungen der Lobby **max. 20 Spieler** einstellen.
3. Teleport funktioniert nur im veröffentlichten Spiel, nicht in Studio.
