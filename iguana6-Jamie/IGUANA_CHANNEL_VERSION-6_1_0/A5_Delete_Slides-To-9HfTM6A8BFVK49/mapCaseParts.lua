local api = require 'concentriqAPI'

--JSON mapping for PATCH request
function mapCaseParts(blocks)
   local body = {}
   
   body.blocks = blocks
	return body
end

return mapCaseParts
