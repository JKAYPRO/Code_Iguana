local tu = require 'tableUtils'
local hasParts = require 'hasParts'

local function hasSlides(msg)
   local slidesAtCase = msg.case.slides and not tu.isNotTableOrEmpty(msg.case.slides)
   local slidesAtPart = false
   if hasParts(msg) then
      slidesAtPart = msg.case.parts[1].slides and not tu.isNotTableOrEmpty(msg.case.parts[1].slides)
   end
   return slidesAtCase or false, slidesAtPart or false
end

return hasSlides