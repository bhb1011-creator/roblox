-- Sounds aus den Sammeldateien (siehe Config.SOUND_BANKS und SoundPieces.lua):
-- ein Sound bekommt die ID der Sammeldatei und spielt nur sein eigenes Stück.
--
--   local id, piece = SoundBank.find(key)   -- nil, wenn es keine Sammeldatei-ID gibt
--   SoundBank.apply(sound, piece)          -- nach dem Anlegen des Sounds aufrufen
local Config = require(script.Parent:WaitForChild("Config"))
local okPieces, Pieces = pcall(require, script.Parent:WaitForChild("SoundPieces", 5))

local SoundBank = {}

function SoundBank.find(key)
	local piece = okPieces and type(Pieces) == "table" and Pieces[key]
	if not piece then
		return nil
	end
	local id = Config.SOUND_BANKS and Config.SOUND_BANKS[piece.bank] or ""
	if id == "" then
		return nil
	end
	return id, piece
end

function SoundBank.apply(sound, piece)
	if not (sound and piece) then
		return
	end
	local region = NumberRange.new(piece.start, piece.start + piece.length)
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = region
	if piece.loop then
		-- das Stück liegt dreimal hintereinander; geschleift wird im mittleren (nahtlos)
		sound.LoopRegion = region
	end
end

return SoundBank
