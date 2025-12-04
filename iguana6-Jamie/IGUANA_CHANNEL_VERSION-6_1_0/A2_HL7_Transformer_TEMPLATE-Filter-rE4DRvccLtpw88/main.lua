-- Import necessary modules
hl7.fix = require 'hl7.delimiter.fix'
local parseOML = require 'parseOML'
local parseORU = require 'parseORU'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)   
   -- Fix unescaped "&" characters
   local Data = hl7.fix{data=Data, segment='OBR',field_index=2}
   Data = hl7.fix{data=Data, segment='NTE',field_index=3}
   
   -- Parse the incoming HL7 message
   local msg, msgType = hl7.parse{vmd='Delta_09092024.vmd',data=Data}
   local jsonMsg = {}

   -- Filter messages and apply the necessary JSON mapping
   if msgType == 'CatchAll' then
      iguana.logInfo('Message type not supported')
      return
   elseif msgType == 'OML' then
      jsonMsg = parseOML(msg)
   elseif msgType == 'ORU' then
      jsonMsg = parseORU(msg)
   end

   queue.push{data=json.serialize{data=jsonMsg,alphasort=true}}
end
