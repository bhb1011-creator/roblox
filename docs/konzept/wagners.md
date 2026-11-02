# Familie Wagner – Konzept

Die Gastfamilie, bei der man nach dem Campingausflug eine Nacht bleiben soll. Vier Personen:
Vater, Mutter, Tochter und Sohn. Jeder bekommt eine eigene Figur und eine eigene Stimme.

## Die Geschichte (vom Spieler festgelegt)

- **Sarp ist ein Dämon.** Die ganze Familie Wagner ist von ihm **besessen** – deshalb sind
  sie alle so komisch.
- Erst glaubt man, **Sarp ist der Böse** (und die Familie hat Angst vor ihm). Im Laufe der
  Geschichte merkt man: **Die Wagners sind die Bösen**, sie gehören zu ihm.
- Irgendwann muss man **vor der Familie fliehen**.

## Grundgefühl

Alles ist düster bei ihnen, irgendwie komisch. Sie sind freundlich, aber es stimmt nicht:
- Sie lächeln zu lange und blinzeln kaum.
- Ihre Pausen kommen an den falschen Stellen.
- Sie wissen Dinge, die sie nicht wissen dürften.
- Im Haus brennen nur Kerzen, es ist kalt, die Standuhr ist stehen geblieben.
- Auf den Familienfotos sind die Gesichter zerkratzt.
- Sie reden über Sarp wie über einen Nachbarn, der „sich um Dinge kümmert“.

## Die Personen

| Person | Aussehen | Verhalten | Stimme (vorerst Roblox) |
|---|---|---|---|
| **Mrs. Wagner (Margaret)** | um die 45, dunkelgrünes Kleid, graubraune Strickjacke, Spitzenkragen, Medaillon, Haare streng zu einem Knoten, graue Strähnen. Sehr blass, dunkle Ringe unter den Augen, winzige starre Pupillen | übertrieben freundlich, langsam, ein bisschen zu süß. Lächelt immer. Schaut einen ständig an. Hält eine Kerze | Stimme 4 (amerikanisch, Frau), etwas tiefer, langsam |
| **Mr. Wagner (Richard)** | groß und hager, schmutziges Hemd mit hochgekrempelten Ärmeln, Hosenträger, ungepflegter Bart, müde Augen. Linke Hand verbunden, der Verband ist blutig | redet wenig und kurz, schaut meist auf den Boden. Scheint Angst vor etwas zu haben („He shouldn't have.“). Seine Frau unterbricht ihn („Richard.“) | Stimme 5 (amerikanisch, Mann), tief, müde |
| **Lucy** (Tochter, ca. 12) | weißes Nachthemd bis zu den Knöcheln, lange dunkle Haare, barfuß, hält eine Puppe. Lächelt genau wie die Mutter | steht beim Ankommen oben an der Galerie und schaut herunter, obwohl sie angeblich schläft | noch offen |
| **Tommy** (Sohn, ca. 7) | gestreifter Schlafanzug, zerzauste Haare, große fast schwarze Augen, hält eine Zeichnung | steht im Salon am Klavier (später: spielt immer denselben Ton), malt Bilder von Sarp | noch offen |

## Das Haus

Gebaut in `src/kapitel2/server/Mansion.lua`, Bauplan: `docs/konzept/hausplan.html` (und die
Bilder `hausplan_*.png`). Das Haus ist von Anfang an groß (auch von außen): Keller,
Erdgeschoss, Obergeschoss, runder Turm vorne links, Erker, sechseckiger Glas-Wintergarten
hinten rechts. Im Keller hinter einem Regal ein Geheimgang zum runden Ritualraum (Altar,
Kerzenkreis, Fotos früherer Gäste) und ein Tunnel in den Wald (möglicher Fluchtweg).
Weg nach oben: Treppe in der Halle → Galerie → Tür ins Spielzimmer → langer Flur.

## Kapitel 2 – Anfang (gebaut)

1. Man steht vor der Haustür und klopft.
2. Stille, Schritte im Haus, die Tür geht einen Spalt auf (mit Kette): Mrs. Wagner.
3. Sie öffnet ganz, Gespräch mit Antworten.
4. Die Kerze flackert fast aus, Mr. Wagner steht plötzlich hinter ihr.
5. Sie bitten einen herein, man geht selbst hinein, die Tür fällt zu.
6. „The children are already asleep.“ – „Your room is upstairs. Second door on the left. Not the first one.“ – „And whatever you hear tonight… it's just the house.“

Texte: `src/shared/Kapitel2Dialogue.lua`. Figuren: `src/kapitel2/server/Wagners.lua`. Starten: `rojo serve kapitel2.project.json --port 34874`.

## Offen

- Eigene Stimmen (ElevenLabs) für Mrs. und Mr. Wagner, später für die Kinder
- Die Kinder kennenlernen (Szenen mit Lucy und Tommy)
- Eigene Stimmen für Lucy und Tommy
- Wie es nach der Ankunft weitergeht (Zimmer oben, die vernagelte erste Tür, …)

## Die erste Nacht (eingebaut, `src/kapitel2/server/Night.lua`)

1. Wenn alle im Gästezimmer im Bett liegen: schwarz, „Mitten in der Nacht … 03:17“, Schreie
   irgendwo im Haus.
2. Man wacht auf, Mrs. Wagner steht in der Tür und holt einen mitten in der Nacht zum Essen.
   Man folgt ihr über Galerie, Treppe, Flur und Küche ins Esszimmer, Mr. Wagner wartet dort.
3. Am Tisch (man sitzt): kurzes Gespräch über Sarp, eine Auswahl, dann klopft es schwer an
   der Haustür. „Hide. Now!“ – die Wagners rennen durch die Küche weg und schließen ab.
4. 22 Sekunden zum Verstecken. Drei Verstecke im Esszimmer: **Schrank** (mit Schlitzen zum
   Rausschauen), **unter dem Tisch** (lange Tischdecke), **hinter dem Vorhang** im Erker.
5. Sarp in seiner **zweiten Gestalt** (`SarpStage2.lua`) reißt die Haustür auf, kommt durch
   Halle und Wohnzimmer, sprengt die Tür zum Esszimmer auf und sucht: Er bleibt vor jedem
   Versteck stehen, atmet, schaut hinein (unter den Tisch beugt er sich herunter). Wer drin
   ist: Herzschlag, Kamera zittert, er flüstert. Wer nicht versteckt ist oder rauskommt:
   Jumpscare („Er hat dich gefunden …“). Werden alle gefunden, beginnt das Verstecken neu.
6. Er geht wieder („...Not yet. Soon.“). Richard kommt zurück: Im Keller liegt eine Axt
   (an einem von 6 ausgelosten Plätzen, siehe `hausplan_keller_axt.png`), damit soll man oben
   **Tür 1** (vernagelt) aufbrechen.
7. Währenddessen läuft Sarp durchs Erdgeschoss (sehr laute Schritte, Herzschlag wird schneller,
   je näher er ist). Jetzt ist er nicht mehr tödlich: Sieht er einen, bleibt er stehen, starrt
   und flüstert. Die Familie (Mrs. Wagner, Lucy, Tommy) taucht irgendwo in der Ferne auf, sagt
   etwas Seltsames und rennt weg und verschwindet, wenn man näher kommt.
8. Wer die Axt hat, bricht Tür 1 auf (Bretter fallen ab). Sobald jemand den Raum dahinter
   betritt, beginnt die Flucht.

## Die Flucht (eingebaut, `src/kapitel2/server/Escape.lua`)

Hintergrund (wird hier **nicht** erzählt, erst im DLC): Die Familie hat Sarp erschaffen.
Richard war die ganze Zeit auf ihrer Seite, bis er gemerkt hat, dass es nicht mehr gut ist –
jetzt will er die Spieler gehen lassen. Er verrät nichts („That is not your story. Not yet.“).
Plan mit allen Fundorten und dem Kerzenweg: `hausplan_flucht.png`.

1. Hinter Tür 1: Pult, Safe, drei Verstecke (Schrank, hinter dem umgekippten Bett, Truhe).
   Richard erklärt: Im Safe liegt der Schlüssel nach draußen, man soll ihn aufsprengen –
   dafür **Chemikalien** und **Schießpulver** finden. Jeder bekommt eine **rote Kerze**;
   die Taschenlampe gibt es nicht mehr.
2. Suchen (je 6 mögliche Plätze, ausgelost; zu zweit trägt jeder nur eins). Liste oben links.
   Die Familie taucht außer Sicht auf, kommt auf einen zu und schlägt zu (20 Schaden), dann
   verschwindet sie. Der Raum hinter Tür 1 ist sicher. Sarp hört man nur von unten.
3. Am Pult ablegen → zusammenbauen → Ladung an den Safe → Lunte mit der Kerze anzünden →
   5 Sekunden zum Verstecken. Richard läuft weg.
4. Explosion: Safetür fliegt weg, die Kerzen sind verloren (innere Stimme sagt es).
   Sarp brüllt, kommt die Treppe hoch und durchsucht die drei Verstecke. Wer gefunden wird:
   Jumpscare, danach geht es im Raum weiter.
5. Danach stehen **rote Kerzen** auf dem Weg nach unten (Galerie, Treppe, Halle, Flur, Küche,
   Keller). Schlüssel nehmen. Sarp läuft im Erdgeschoss herum und ist tödlich: Er **hört**
   jeden, der nicht schleicht (bis 20 Studs), und **sieht** im Dunkeln nur aus der Nähe.
   **C = Schleichen** (langsam, leise). Erwischt: Jumpscare, Neustart im Raum hinter Tür 1.
6. Der Schlüssel schließt das Regal vor dem Geheimgang im Vorratskeller auf. Wer den
   **Ritualraum** betritt: sofort schwarz („Der Ritualraum … Fortsetzung folgt“).

Teststart: `Config.TEST_START_KAPITEL2 = "tuer1"` (gleich im Raum hinter Tür 1).
