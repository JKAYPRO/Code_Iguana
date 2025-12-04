local upsert = require 'upsert'
local caseUpdate = require 'caseUpdate'
local delete = require 'delete'
local deleteCase = require 'deleteCase'
local api = require 'concentriqAPI'

function main(Data)
   local msg = json.parse{data = Data}

   -- Lookup labSite if lab code is provided and labSiteId is not already set.
   if msg.case.labSiteId then
      -- Do Nothing
   else
      local labSiteCode = msg.case.labSiteCode
      if labSiteCode then
         labSiteCode = labSiteCode and string.trimWS(labSiteCode)
         local labSiteQuery = json.serialize{
            data = { eager = { ["$where"] = { shortDescription = labSiteCode } } }
         }
         local labSite = api.getLabSites(labSiteQuery)
         if not labSite then
            iguana.logError('No lab site found for code ' .. labSiteCode .. '. Accession = ' .. msg.case.accessionId)
            return nil
         else
            msg.case.labSiteId = labSite.id
         end
      end   
   end


   if msg.messageType == "upsert" then
      upsert(msg)
   elseif msg.messageType == "caseUpdate" then
      caseUpdate(msg)
   elseif msg.messageType == "delete" then
      delete(msg)
   elseif msg.messageType == "deleteCase" then
      deleteCase(msg)
   else
      iguana.logError("Unknown messageType: " .. tostring(msg.messageType))
   end
end