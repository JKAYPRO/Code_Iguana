local api = require 'concentriqAPI'
local mapCaseDetails = require 'mapCaseDetails'
local tu = require 'tableUtils'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   local msg = json.parse{data=Data}

   local accessionId = msg.case.accessionId

   -- GET caseDetails to see if case exists 
   local caseDetailsQuery = json.serialize{data={eager={["$where"]={accessionId=accessionId}}}}
   local caseDetails = api.getCaseDetails(caseDetailsQuery)

   if not caseDetails then
      iguana.logError('Case ' .. accessionId .. ' does not exist. Skipping')
      return
   else
      local caseDetailsUpdateBody = mapCaseDetails(msg)
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