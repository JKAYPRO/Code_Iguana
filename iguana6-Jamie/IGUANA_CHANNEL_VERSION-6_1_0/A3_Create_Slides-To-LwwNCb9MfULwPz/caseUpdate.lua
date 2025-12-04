local api = require 'concentriqAPI'
local mapCaseDetails = require 'mapCaseDetails'
local tu = require 'tableUtils'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function caseUpdate(msg)
   -- Set log level
   local LOG_LEVEL = (msg.options.logLevels and msg.options.logLevels.caseUpdate) or 'logError'   

   local accessionId = msg.case.accessionId

   -- GET caseDetails to see if case exists 
   local caseDetailsQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = { 
               accessionId = msg.case.accessionId,
               labSiteId = msg.case.labSiteId
            }
         }
      }
   }
   local caseDetails = api.getCaseDetails(caseDetailsQuery)

   if not caseDetails then
      iguana[LOG_LEVEL]('Case ' .. accessionId .. ' does not exist. Skipping')
      return
   else
      local caseDetailsUpdateBody = mapCaseDetails(msg, caseDetails, {action = 'patch'})
      if not caseDetailsUpdateBody then
         iguana.logError('Could not create caseDetails. Skipping message. ' .. msg.case.accessionId)
         return nil
      end    
      local caseDetailsUpdate = api.patchCaseDetails(caseDetails.id, caseDetailsUpdateBody)

      -- Update case tags if provided
      if not tu.isNotTableOrEmpty(msg.case.tags) then
         for i = 1, #msg.case.tags do
            -- Check if the case tag already exists for that case
            local caseDetailCaseTagsQuery = json.serialize{data={eager={["$where"]={["$and"]={caseDetailId=caseDetails.id,caseTagId=msg.case.tags[i]}}}}}
            local caseDetailCaseTags = api.getCaseDetailCaseTags(caseDetailCaseTagsQuery)

            if not caseDetailCaseTags then            
               local caseDetailCaseTagsBody = {caseDetailId=caseDetails.id,caseTagId=msg.case.tags[i]}
               local caseDetailCaseTagsUpdate = api.postCaseDetailCaseTags(caseDetailCaseTagsBody)
            end
         end
      end      

   end
end

return caseUpdate