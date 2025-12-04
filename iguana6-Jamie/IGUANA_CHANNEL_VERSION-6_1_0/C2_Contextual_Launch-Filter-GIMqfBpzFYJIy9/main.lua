local api = require 'concentriqAPI'
require 'date.parse'
local mapOutboundMessage = require 'mapOutboundMessage'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   local image = json.parse{data=Data}
   
   --GET caseDetailsId
   local slidesQuery = json.serialize{data={eager={["$where"]={id=image.event.current.slideId}}}}
   local slides = api.getSlides(slidesQuery)
   
   -- Get the caseDetails data
   local caseDetailsQuery = json.serialize{data={eager={["$where"]={id=slides.caseDetailId}}}}
   local caseDetails = api.getCaseDetails(caseDetailsQuery)
   
	local msgOut = mapOutboundMessage(caseDetails, slides,image)
   trace(msgOut:S())
	queue.push{data=msgOut}
end