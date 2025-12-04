local api = require 'concentriqAPI'
require 'date.parse'
require 'mapOutboundMessage'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   local slide = json.parse{data=Data}
   
	local msgOut = mapOutboundMessage(slide)
   trace(msgOut:S())
	queue.push{data=msgOut}
end