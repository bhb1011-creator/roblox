"""Sprachaufnahmen mit ElevenLabs erzeugen (Modell Eleven v3, mit Emotions-Tags).

Der Schlüssel steht in .elevenlabs_key im Projektordner (nicht auf GitHub).

  python3 tools/elevenlabs_voices.py stimmen              # eigene Stimmen auflisten und sichern (docs/stimmen_elevenlabs.md)
  python3 tools/elevenlabs_voices.py sarp <voice_id>      # alle Sarp-Sätze erzeugen
  python3 tools/elevenlabs_voices.py erzaehler <voice_id> # alle Erzähler-/Spieler-Sätze erzeugen
  python3 tools/elevenlabs_voices.py sarp <voice_id> sarp_01_evening sarp2_stay   # nur einzelne

Ergebnis: assets/voice/raw_v3/<name>.mp3 (so wie von ElevenLabs) und assets/voice/v3/<name>.ogg.
Sarp als Monster (sarp2_*) wird danach etwas tiefer gesetzt.
"""
import json, os, subprocess, sys, time, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
KEY_FILE = os.path.join(ROOT, ".elevenlabs_key")
RAW = os.path.join(ROOT, "assets", "voice", "raw_v3")
OUT = os.path.join(ROOT, "assets", "voice", "v3")
DOC = os.path.join(ROOT, "docs", "stimmen_elevenlabs.md")
API = "https://api.elevenlabs.io"
MODEL = "eleven_v3"

SARP = [
    ("sarp_01_evening", "[calm, friendly] Evening."),
    ("sarp_02_shouldnt_stop", "[quiet, serious] You shouldn't stop here. [pause] Not on this road."),
    ("sarp_03_the_wagners", "[thoughtful, slow] The Wagners..."),
    ("sarp_04_told_me", "[calm, faint smile] Yes. They told me you would come."),
    ("sarp_05_im_sarp", "[friendly, calm] I'm Sarp. I live close to them."),
    ("sarp_06_who_am_i", "[slightly amused, slow] Who am I?"),
    ("sarp_07_my_name", "[calm, friendly] My name is Sarp. I'm a neighbor of the Wagners."),
    ("sarp_08_waiting_solo", "[quiet, a little too warm] I've been waiting for you."),
    ("sarp_08_waiting_duo", "[quiet, a little too warm] I've been waiting for you two."),
    ("sarp_09_campsite_solo", "[curious, calm] You're the one from the campsite, aren't you?"),
    ("sarp_09_campsite_duo", "[curious, calm] You're the two from the campsite, aren't you?"),
    ("sarp_10_small_place", "[casual, slight smile] Small place. Word gets around."),
    ("sarp_11_watched_you", "[calm, matter-of-fact] I know. I watched you pack up your tent this afternoon."),
    ("sarp_12_house_up_path", "[warm, inviting] The house is just up that path. The beds are made. There's warm food."),
    ("sarp_13_come", "[calm, gentle] Come. I'll take you."),
    ("sarp_14_no_road", "[flat, quiet] There is no road to the house."),
    ("sarp_15_ill_be_waiting", "[calm, faint smile] But go ahead. [pause] I'll be waiting."),
    ("sarp_16_long_way", "[calm, knowing] You took the long way."),
    ("sarp_17_stay_close", "[serious, quiet] Good. Stay close. [pause] And don't look into the trees."),
    ("sarp_18_leave_you", "[calm, quiet] This is where I leave you."),
    ("sarp_19_sleep_well", "[friendly, then serious] Sleep well. [pause] And lock your door."),
    # Sarp als Monster (Kapitel 2 und 3)
    ("sarp2_whisper_here", "[whispers, menacing] I know you're here."),
    ("sarp2_whisper_heart", "[whispers, slow] I can hear your heart."),
    ("sarp2_whisper_come_out", "[whispers, teasing] Come out... [pause] come out..."),
    ("sarp2_whisper_cant_hide", "[whispers, cold] You can't hide from me."),
    ("sarp2_not_yet", "[low, raspy] ...Not yet. [pause] Soon."),
    ("sarp2_who_opened", "[angry, low] Who opened my door?"),
    ("sarp2_smell_you", "[sniffs] [low, menacing] I smell you."),
    ("sarp2_little_thieves", "[low, mocking] Little thieves..."),
    ("sarp2_opened_my_door", "[low, cold] You opened my door."),
    ("sarp2_nobody_leaves", "[low, menacing] Nobody leaves this house."),
    ("sarp2_stay", "[low growl] Stay."),
]

ERZAEHLER = [
    ("erzaehler_01", "[quiet, tired] October 14th. [pause] 11:52 PM."),
    ("erzaehler_02", "[calm, a little tired] The camping trip was over. One more night with a host family, the Wagners. [sighs softly] Then I could finally go home."),
    ("erzaehler_03", "[calm, a little tired] The camping trip was over. One more night with a host family, the Wagners. [sighs softly] Then we could finally go home."),
    ("erzaehler_04", "[thoughtful, slightly uneasy] Mrs. Wagner's directions were strange. Take the old forest road. Don't stop. [quieter] No matter what you see."),
    ("erzaehler_05", "[growing uneasy] Then the radio lost its signal. And the navigation lost the road. [pause] I had to stop."),
    ("erzaehler_06", "[growing uneasy] Then the radio lost its signal. And the navigation lost the road. [pause] We had to stop."),
    ("erzaehler_07", "[tense, quiet] That's when I saw him. A man, walking out of the forest. [slower] Straight towards me."),
    ("erzaehler_08", "[tense, quiet] That's when we saw him. A man, walking out of the forest. [slower] Straight towards us."),
    ("erzaehler_09", "[uneasy] I drove on. In the mirror, he just stood there. [quieter] Watching me go."),
    ("erzaehler_10", "[uneasy] We drove on. In the mirror, he just stood there. [quieter] Watching us go."),
    ("erzaehler_11", "[confused, uneasy] The road turned all the way around, back through the forest. [quietly] As if it didn't want to let me leave."),
    ("erzaehler_12", "[confused, uneasy] The road turned all the way around, back through the forest. [quietly] As if it didn't want to let us leave."),
    ("erzaehler_13", "[tense, quiet] The house was dark. Not a single light. Nobody was waiting for me. [pause] [whispers] Nobody but him."),
    ("erzaehler_14", "[tense, quiet] The house was dark. Not a single light. Nobody was waiting for us. [pause] [whispers] Nobody but him."),
    ("erzaehler_15", "[slightly out of breath] He walked fast. He never once looked back."),
    ("erzaehler_16", "[nervous, quiet] Something moved between the trees. Something that kept pace with me."),
    ("erzaehler_17", "[nervous, quiet] Something moved between the trees. Something that kept pace with us."),
    ("erzaehler_18", "[quiet, uneasy] The path climbed up the hill. With every step, the forest got quieter."),
    ("erzaehler_19", "[tense, quiet] The house was dark. Not a single light. [pause] And I never heard him walk away."),
    ("erzaehler_20", "[tense, quiet] The house was dark. Not a single light. [pause] And we never heard him walk away."),
    ("erzaehler_21", "[unsure, polite] I'm looking for the Wagners' house."),
    ("erzaehler_22", "[unsure, polite] We're looking for the Wagners' house."),
    ("erzaehler_23", "[cautious] Who are you?"),
    ("erzaehler_24", "[suspicious] How do you know that?"),
    ("erzaehler_25", "[hesitant] ...Yes."),
    ("erzaehler_26", "[firm, a little nervous] I'll drive there myself."),
    ("erzaehler_27", "[firm, a little nervous] We'll drive there ourselves."),
    ("erzaehler_28", "[hesitant, giving in] ...Okay. Show me the way."),
    ("erzaehler_29", "[hesitant, giving in] ...Okay. Show us the way."),
    ("k2_got_chemicals", "[quiet, focused] Chemicals. This should do it."),
    ("k2_got_powder", "[careful, quiet] Black powder. Careful with that."),
    ("k2_carry_one", "[strained] My hands are full. The other one has to carry that."),
    ("k2_lit", "[urgent, scared] It is lit. Hide! Now!"),
    ("k2_candle_lost", "[scared, quiet] My candle... [pause] it's gone. I can barely see anything."),
    ("k2_he_heard", "[panicked whisper] He heard that. He's coming up here!"),
    ("k2_after_search", "[shaky, relieved] He's gone. [pause] Red candles... somebody lit a path. Downstairs."),
    ("k2_take_key", "[whispers, tense] The key. Now follow the candles. And keep quiet."),
    ("k2_sneak_hint", "[whispers] If I walk slowly, he won't hear me."),
    ("k2_shelf_locked", "[quiet, thinking] There's a keyhole behind this shelf. I need the key from the safe."),
    ("k2_shelf_open", "[relieved, quiet] It fits. There's a passage behind the shelf."),
    ("k2_hurt", "[scared, shouting] Get away from me!"),
    ("k3_tunnel", "[urgent, shouting] The tunnel! Go! Now!"),
    ("k3_cabin_light", "[out of breath, hopeful] A cabin... [pause] There's light inside!"),
    ("k3_sarps_cabin", "[slowly realizing, scared] Wait... that jacket. The name on the mailbox... [pause] This is Sarp's cabin."),
    ("k3_phone_solo", "[urgent] There's a phone. I have to call the police!"),
    ("k3_phone_duo", "[urgent] There's a phone. We have to call the police!"),
    ("k3_call_01_solo", "[panicked, breathless] Please, you have to help me! I'm in a cabin by the old forest road. Something is hunting me!"),
    ("k3_call_01_duo", "[panicked, breathless] Please, you have to help us! We're in a cabin by the old forest road. Something is hunting us!"),
    ("k3_call_02", "[shaky, quiet] Please... hurry."),
    ("k3_coming_out_solo", "[relieved, calling out] I'm here! I'm coming out!"),
    ("k3_coming_out_duo", "[relieved, calling out] We're here! We're coming out!"),
]


def key():
    if not os.path.exists(KEY_FILE):
        raise SystemExit("Datei .elevenlabs_key fehlt.")
    value = open(KEY_FILE, encoding="utf-8").read().strip()
    if not value:
        raise SystemExit("Datei .elevenlabs_key ist leer.")
    return value


def request(method, path, body=None, raw=False):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("xi-api-key", key())
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=180) as response:
            payload = response.read()
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")[:400]
        raise SystemExit(f"ElevenLabs-Fehler {error.code}: {detail}")
    return payload if raw else json.loads(payload)


def voices():
    """Eigene Stimmen auflisten und ihre Beschreibung sichern (für einen anderen Account)"""
    result = request("GET", "/v1/voices")
    lines = ["# ElevenLabs-Stimmen (gesichert)", "",
             "Automatisch gesichert von `tools/elevenlabs_voices.py stimmen`. Damit kann man die Stimmen",
             "auf einem anderen Account nachbauen (Voice Design: Beschreibung einfügen).", ""]
    own = []
    for voice in result.get("voices", []):
        if voice.get("category") in ("premade",):
            continue
        own.append(voice)
        try:
            settings = request("GET", f"/v1/voices/{voice['voice_id']}/settings")
        except SystemExit as problem:
            settings = {"fehler": str(problem)}
        lines += [
            f"## {voice.get('name')}",
            f"- voice_id: `{voice.get('voice_id')}`",
            f"- Art: {voice.get('category')}",
            f"- Merkmale: {json.dumps(voice.get('labels') or {}, ensure_ascii=False)}",
            f"- Einstellungen: {json.dumps(settings, ensure_ascii=False)}",
            "- Beschreibung:", "", "```", (voice.get("description") or "(keine)").strip(), "```", "",
        ]
    open(DOC, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    for voice in own:
        print(f"{voice.get('voice_id')}  {voice.get('category'):10}  {voice.get('name')}")
    print(f"gesichert: {os.path.relpath(DOC, ROOT)} ({len(own)} eigene Stimmen)")


def generate(table, voice_id, only):
    os.makedirs(RAW, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    chars = 0
    for name, text in table:
        if only and name not in only:
            continue
        mp3 = os.path.join(RAW, name + ".mp3")
        audio = request("POST", f"/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128",
                        {"text": text, "model_id": MODEL, "voice_settings": {"stability": 0.5}}, raw=True)
        open(mp3, "wb").write(audio)
        chars += len(text)
        # Monster-Sarp etwas tiefer (gleiche Länge)
        effect = ["-af", "asetrate=44100*0.88,aresample=44100,atempo=1.1364"] if name.startswith("sarp2_") else []
        ogg = os.path.join(OUT, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", mp3, *effect, "-ac", "2", "-c:a", "vorbis", "-strict", "-2", ogg], check=True)
        length = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", ogg],
                                      capture_output=True, text=True).stdout or 0)
        print(f"{name}  {length:.2f}s")
        time.sleep(0.3)
    print(f"fertig, {chars} Zeichen")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    command = sys.argv[1]
    if command == "stimmen":
        voices()
    elif command in ("sarp", "erzaehler"):
        if len(sys.argv) < 3:
            raise SystemExit("voice_id fehlt (siehe: stimmen)")
        generate(SARP if command == "sarp" else ERZAEHLER, sys.argv[2], set(sys.argv[3:]))
    else:
        raise SystemExit(__doc__)
