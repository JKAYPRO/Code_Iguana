local api = require 'concentriqAPI'
local mapOutboundMessage = require 'mapOutboundMessage'
require 'date.parse'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   local caseDetail = json.parse{data=Data}

   -- Get all of the slides for this case.

   local slidesQuery = json.serialize{data={eager={["$where"]={caseDetailId=caseDetail.event.current.id}}}}
   local slides = api.getSlidesAll(slidesQuery)   

   -- Create HL7 message for each slide.
   for i, slide in ipairs(slides) do
      local imageQuery = json.serialize{data={eager={["$where"]={id=slide.primaryImageId}}}}
      local image = api.getImages(imageQuery)
      local msgOut = mapOutboundMessage(caseDetail, slide, image)
      
      queue.push{data=msgOut}
   end   



end