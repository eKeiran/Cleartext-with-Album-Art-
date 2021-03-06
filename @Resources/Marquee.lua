-- LuaMarquee v6.2 by Smurfier (smurfier20@gmail.com)
-- Adapted for UTF-8 by Skymil
-- This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 3.0 License.

function Initialize()
	Vars = SELF:GetOption('Variable')
	Pos = SELF:GetOption('Position', 'right'):lower()
	Pause = SELF:GetNumberOption('Pause', 1)
	Measures, Timer = {}, -1
	for w in SELF:GetOption('MeasureName'):gmatch('[^%|]+') do
		table.insert(Measures, SKIN:GetMeasure(w))
	end
end -- Initialize

-- Local declaration of UTF-8 management functions
local UTF8CharLen, UTF8StringLen, UTF8SubStringLenByte

function Update()
	local Values, Text = {}
	for i, v in ipairs(Measures) do
		table.insert(Values, v:GetStringValue())
	end
	for w in Vars:gmatch('[^%|]+') do
		table.insert(Values, SKIN:GetVariable(w))
	end
	local nText = SELF:GetOption('Text')
	if nText ~= '' then
		table.insert(Values, nText)
	end
	if #Values == 0 then
		return 'Input Error!'
	else
		Text = table.concat(Values, SELF:GetOption('Delimiter', '  ')):gsub('\n', ' ')
		
	end
	--Marquee
	if (not OldText) or Text ~= (OldText or '') then
		LenTimer, Timer, Length, OldText, NewText = 1, 1, UTF8StringLen(Text), Text, ''
	end
	local Width = SELF:GetNumberOption('Width', 10)
	if Length <= Width and SELF:GetNumberOption('ForceScroll', 0) == 0 then
		return Text
	else
		NewText = ((Pos == 'left' and Text or '') .. string.rep(' ', Width) .. Text)
		Timer = Timer % (Length + Width) + 1 * Pause
		if Timer == 1 then
			LenTimer = 1
		else
			LenTimer = LenTimer + UTF8CharLen(NewText, LenTimer) * Pause
		end
		return NewText:sub(LenTimer, LenTimer + UTF8SubString(NewText, Timer, Timer + Width - 1):len() - 1)
	end
end -- Update

-- UTF-8 management functions

-- The following function is taken from Kyle Smith's work, modified by Skymil.

-- Copyright (c) 2006-2007, Kyle Smith
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

--     * Redistributions of source code must retain the above copyright notice,
--       this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * Neither the name of the author nor the names of its contributors may be
--       used to endorse or promote products derived from this software without
--       specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-- Returns the length in byte(s) of a character in an Unicode string encoded in UTF-8.
-- It can also be used to validate an encoding of a character.
-- @param unicodeString The Unicode string encoded in UTF-8.
-- @param index The byte index, in the string, of the character which length is needed.
-- @return The length in byte(s) of the character, or -1 if an error has occurred.
UTF8CharLen = function (unicodeString, index)
	if type(unicodeString) ~= "string" then
		error("UTF8CharLen: bad argument #1 (string expected, got " .. type(unicodeString) .. ").")
		return -1
	end
	if type(index) ~= "number" then
		error("UTF8CharLen: bad argument #2 (number expected, got " .. type(index) .. ").")
		return -1
	end

	if unicodeString:len() == 0 then
		error("UTF8CharLen: argument #1 cannot be an empty string.")
		return -1
	end
	if (((index - 1) >= unicodeString:len()) or (index < 1)) then
		error("UTF8CharLen: wrong argument #2.")
		return -1
	end

	local c = unicodeString:byte(index)

	-- Determines the number of bytes needed for the character, based on RFC 3629.
	-- Validates byte 1.
	if c > 0 and c <= 127 then
		-- UTF8-1
		return 1

	elseif c >= 194 and c <= 223 then
		-- UTF8-2
		local c2 = unicodeString:byte(index + 1)

		if not c2 then
			error("UTF8CharLen: UTF-8 string terminated early.")
			return -1
		end

		-- Validates byte 2.
		if c2 < 128 or c2 > 191 then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		end

		return 2

	elseif c >= 224 and c <= 239 then
		-- UTF8-3
		local c2 = unicodeString:byte(index + 1)
		local c3 = unicodeString:byte(index + 2)

		if not c2 or not c3 then
			error("UTF8CharLen: UTF-8 string terminated early.")
			return -1
		end

		-- Validates byte 2.
		if c == 224 and (c2 < 160 or c2 > 191) then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		elseif c == 237 and (c2 < 128 or c2 > 159) then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		elseif c2 < 128 or c2 > 191 then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		end

		-- Validates byte 3.
		if c3 < 128 or c3 > 191 then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		end

		return 3

	elseif c >= 240 and c <= 244 then
		-- UTF8-4
		local c2 = unicodeString:byte(index + 1)
		local c3 = unicodeString:byte(index + 2)
		local c4 = unicodeString:byte(index + 3)

		if not c2 or not c3 or not c4 then
			error("UTF8CharLen: UTF-8 string terminated early.")
			return -1
		end

		-- Validates byte 2.
		if c == 240 and (c2 < 144 or c2 > 191) then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		elseif c == 244 and (c2 < 128 or c2 > 143) then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		elseif c2 < 128 or c2 > 191 then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		end
		
		-- Validates byte 3.
		if c3 < 128 or c3 > 191 then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		end

		-- Validates byte 4.
		if c4 < 128 or c4 > 191 then
			error("UTF8CharLen: invalid UTF-8 character.")
			return -1
		end

		return 4

	else
		error("UTF8CharLen: invalid UTF-8 character.")
		return -1
	end
end

-- Returns the length of an Unicode string encoded in UTF-8.
-- @param unicodeString The Unicode string encoded in UTF-8.
-- @return The length (number of UTF-8 characters) of the Unicode string, or -1 if an error has occurred.
UTF8StringLen = function (unicodeString)
	if type(unicodeString) ~= "string" then
		error("UTF8StringLen: bad argument (string expected, got " .. type(unicodeString) .. ").")
		return -1
	end

	local unicodeStringLen = unicodeString:len()
	local currentIndex = 1
	local nbUTF8Chars = 0

	while currentIndex <= unicodeStringLen do
		nbUTF8Chars = nbUTF8Chars + 1
		currentIndex = currentIndex + UTF8CharLen(unicodeString, currentIndex)
	end

	return nbUTF8Chars
end

-- Returns the substring of an Unicode string encoded in UTF-8.
-- @param unicodeString The Unicode string encoded in UTF-8.
-- @param startIndexUnicode The UTF-8 index, in the Unicode string (each character is considered as an UTF-8 character), of the beginning of the substring.
-- @param endIndexUnicode The UTF-8 index, in the Unicode string (each character is considered as an UTF-8 character), of the end of the substring. If not given, the substring is a suffix of the string.
-- @return The substring of the Unicode string, or -1 if an error has occurred.
UTF8SubString = function(unicodeString, startIndexUnicode, endIndexUnicode)
	endIndexUnicode = endIndexUnicode or UTF8StringLen(unicodeString)

	if type(unicodeString) ~= "string" then
		error("UTF8SubString: bad argument #1 (string expected, got " .. type(unicodeString) .. ").")
		return -1
	end
	if type(startIndexUnicode) ~= "number" then
		error("UTF8SubString: bad argument #2 (number expected, got " .. type(startIndexUnicode) .. ").")
		return -1
	end
	if type(endIndexUnicode) ~= "number" then
		error("UTF8SubString: bad argument #3 (number expected, got " .. type(endIndexUnicode) .. ").")
		return -1
	end

	if (endIndexUnicode < 1) or (startIndexUnicode < 1) then
		error("UTF8SubString: arguments #2 and #3 cannot be negative or equal to zero.")
		return -1
	end
	if (endIndexUnicode - startIndexUnicode) < 0 then
		error("UTF8SubString: argument #3 must be greater or equal to argument #2.")
		return -1
	end
	if endIndexUnicode > UTF8StringLen(unicodeString) then
		endIndexUnicode = UTF8StringLen(unicodeString)
	end

	local currentIndexUnicode = 1
	local currentIndex = 1
	local startIndex

	while currentIndexUnicode < (endIndexUnicode + 1) do
		if currentIndexUnicode == startIndexUnicode then
			startIndex = currentIndex
		end
		currentIndex = currentIndex + UTF8CharLen(unicodeString, currentIndex)
		currentIndexUnicode = currentIndexUnicode + 1
	end

	return unicodeString:sub(startIndex, currentIndex - 1)
end