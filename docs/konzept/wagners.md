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
