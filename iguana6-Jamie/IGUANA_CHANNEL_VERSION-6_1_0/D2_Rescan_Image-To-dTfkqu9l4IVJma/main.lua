local api = require 'concentriqAPI'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   local msg = json.parse{data=Data}

   local currentOrderStatus = msg.event.current.orderStatus
   local previousOrderStatus = msg.event.previous.orderStatus   
   local caseDetailsBody = {}

   -- If the current status is not null, then the status should be pending because the case 
   -- is waiting for a rescan. Otherwise, if it is null then the rescan was cancelled and
   -- the caseStage should be updated to review if all slides have images and there are no rescans
   if currentOrderStatus ~= json.NULL then
      caseDetailsBody.caseStage = 'pending'
      trace(caseDetailsBody)
   else

      -- Now update the status based on the current state of the case
      local status = api.caseStatus(msg.event.current.caseDetailId)      

      caseDetailsBody.caseStage = status
   end
   local caseDetails = api.patchCaseDetails(msg.event.current.caseDetailId, caseDetailsBody)      
end