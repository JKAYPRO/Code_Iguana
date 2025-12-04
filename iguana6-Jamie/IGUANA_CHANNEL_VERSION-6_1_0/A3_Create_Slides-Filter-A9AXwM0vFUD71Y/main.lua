-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   -- Parse HL7
   local msg = json.parse{data=Data}
   if msg.messageType == 'upsert' then
      queue.push{data=Data}
   else
      iguana.logInfo('Filtering message type '..msg.messageType)
   end

end