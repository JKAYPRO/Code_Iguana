-- stringutil contains a number of extensions to the standard Lua String library.

-- As you can see writing extra methods that will work on strings is very easy.

-- See http://www.lua.org/manual/5.1/manual.html#5.4 for documentation on the Lua String library

 

-- Trims white space on both sides.

function string.trimWS(self) 

   local L, R

   L = #self

   while _isWhite(self:byte(L)) and L > 1 do

      L = L - 1

   end

   R = 1

   while _isWhite(self:byte(R)) and R < L do

      R = R + 1

   end    

   return self:sub(R, L)

end

 

-- Trims white space on right side.

function string.trimRWS(self)

   local L

   L = #self

   while _isWhite(self:byte(L)) and L > 0 do

      L = L - 1

   end

   return self:sub(1, L)

end

 

-- Trims white space on left side.

function string.trimLWS(self)

   local R = 1

   local L = #self

   while _isWhite(self:byte(R)) and R < L do

      R = R + 1

  end

   return self:sub(R, L)

end

 

function _isWhite(byte)

   return byte == 32 or byte == 9

end

 

-- This routine will replace multiple spaces with single spaces

function string.compactWS(self)

   return self:gsub("%s+", " ")

end

 

-- This routine capitalizes the first letter of the string

-- and returns the rest in lower characters

function string.capitalize(self)

   local R = self:sub(1,1):upper()..self:sub(2):lower()

   return R

end