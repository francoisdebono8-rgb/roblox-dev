-- Upper case for the screen (QA test of b822ee5, 12/11: « SōSHūHA »,
-- « SōSHūGA », « GōRIKI SENPū » on the cards and the cast titles).
-- string.upper only knows ASCII: the accented letters of a UTF-8 name were
-- left in lower case inside an upper-case title. Their capitals are written
-- here: the long vowels of the romanized names (ā ē ī ō ū) and the Latin-1
-- accents (é, è, à, ô, û, ç...).
local Text={}
Text.LONG={["ā"]="Ā",["ē"]="Ē",["ī"]="Ī",["ō"]="Ō",["ū"]="Ū"}
-- (26/11, seen in the game: « GENIN TUNIC ¤� NAVY » on the gate's card) On a
-- player's machine string.upper follows its locale: a Latin-1 one turns the
-- byte 0xE2 (« â ») into 0xC2, the first byte of « • », « — », « … » (E2 80 ..),
-- and the text is no longer UTF-8. Only the ASCII letters are raised here; the
-- others below, by their own tables.
function Text.upper(value)
	local s=string.gsub(tostring(value or ""),"[a-z]",function(c) return string.char(string.byte(c)-32) end)
	for lower,upper in Text.LONG do s=string.gsub(s,lower,upper) end
	-- Latin-1 small letters (U+00E0..U+00FE, not ÷) are their capitals + 0x20.
	s=string.gsub(s,"\xC3([\xA0-\xBE])",function(c)
		local b=string.byte(c)
		if b==0xB7 then return nil end
		return "\xC3"..string.char(b-0x20)
	end)
	return s
end
return Text
