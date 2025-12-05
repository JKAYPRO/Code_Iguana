-- Import necessary modules
local api = require 'concentriqAPI'

function deleteCase(msg)
   LOG_LEVEL = (msg.options.logLevels and msg.options.logLevels.deleteCase) or 'logError'

   ----------------------------------------------------------------------------
   -- CASE DETAILS CHECK
   ----------------------------------------------------------------------------
   -- Build the query conditionally to avoid issues with null/missing patientDob
   local whereClause = {
      accessionId = msg.case.accessionId,
      labSiteId = msg.case.labSiteId
   }

   -- Only include patientDob in the query if it's actually provided
   if msg.case.patientDob and msg.case.patientDob ~= "" then
      whereClause.patientDob = msg.case.patientDob
   end

   local caseDetailsQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = whereClause
         }
      }
   }
   caseDetails = api.getCaseDetails(caseDetailsQuery)

   -- Delete the case
   if caseDetails then
      local deletedCase = api.deleteCaseDetails(caseDetails.id)
      iguana.logInfo('Case '..caseDetails.accessionId..' (id: '..caseDetails.id..')'..' deleted.')
   else
      iguana[LOG_LEVEL]('Skipping message. This case does not exist. Accession ID = ' ..msg.case.accessionId)
   end
end

return deleteCase