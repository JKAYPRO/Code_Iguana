local api = require 'concentriqAPI'
local tu = require 'tableUtils'
local mapOutboundMessage = require 'mapOutboundMessage'
require 'date.parse'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)

   local attachment = json.parse{data=Data}

   -- Get the case details
   local caseDetailQuery = json.serialize{data={
         eager={
            ["$where"]={
               ["attachments.id"]=attachment.event.current.id
            }
         }
      }
   } 
   --caseDetailQuery = caseDetailQuery:gsub('"empty": false','') -- remove the dummy value
   local caseDetail = api.getCaseDetails(caseDetailQuery)
   
   -- Get the slide info
   trace(attachment.event.current.storageKey)
   local slideName = attachment.event.current.storageKey:match(".-/.-/.-%-(%a+%d+%-[0-9]+%-.+)%-%[")
   local slidesQuery = json.serialize{data={eager={["$where"]={name=slideName}}}}
   local slide = api.getSlides(slidesQuery)
    
   
   -- Get the snapshot file and base64 encode it   
   local snapshot = api.getFile('Attachment',attachment.event.current.id,attachment.event.current.storageKey)
   local base64 = filter.base64.enc(snapshot)
   
   -- Get aossicated slide
   
   local out = mapOutboundMessage(attachment, caseDetail, slide, base64)
   
   queue.push{data=out}


end