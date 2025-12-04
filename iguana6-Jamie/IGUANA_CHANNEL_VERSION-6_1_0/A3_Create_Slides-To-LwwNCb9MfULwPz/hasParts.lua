local tu = require 'tableUtils'

local function hasParts(msg)
   return msg.case.parts and not tu.isNotTableOrEmpty(msg.case.parts)
end

return hasParts