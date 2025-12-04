-- unified_mapCaseParts.lua

local api = require 'concentriqAPI'
local tu  = require 'tableUtils'

-- Create the common body with shared fields.
local function createBody(msg, caseDetails)
   local body = {}
   body.caseDetailId = caseDetails.id
   body.name = msg.case.parts[1].name

   -- Procedures
   local procedureCode = msg.case.parts[1].procedureCode
   local procedureName = msg.case.parts[1].procedureName

   procedureCode = procedureCode and string.trimWS(procedureCode)
   procedureName = procedureName and string.trimWS(procedureName)

   if procedureCode then
      local proceduresQuery = json.serialize{
         data = { eager = { ["$where"] = { code = procedureCode } } }
      }
      local procedures = api.getProcedures(proceduresQuery)
      if not procedures then
         if msg.options.addProcedures == true then
            local proceduresBody = { code = procedureCode, name = procedureName }
            procedures = api.postProcedures(proceduresBody)
            if not procedures then
               iguana.logError('Procedure could not be added: ' .. procedureCode)
               return nil
            end            
         else      
            iguana.logError('Procedure does not exist: ' .. procedureCode .. '^' .. procedureName)
            return nil
         end 
      end
      body.procedureId = procedures.id
   end
   
   -- Sort Order
   body.sortOrder = msg.case.parts[1].sortOrder

   -- Specimens
   local specimenCode = msg.case.parts[1].specimenCode
   local specimenName = msg.case.parts[1].specimenName
   
   specimenCode = specimenCode and string.trimWS(specimenCode)
   specimenName = specimenName and string.trimWS(specimenName)   

   if specimenCode then
      local specimensQuery = json.serialize{
         data = { eager = { ["$where"] = { code = specimenCode } } }
      }
      local specimens = api.getSpecimens(specimensQuery)
      if not specimens then
         if msg.options.addSpecimens == true then
            local specimensBody = { code = specimenCode, name = specimenName }
            specimens = api.postSpecimens(specimensBody)           
            if not specimens then
               iguana.logError('Specimen could not be added: ' .. specimenCode)
               return nil
            end
         else            
            iguana.logError('Specimen does not exist: ' .. specimenCode)
            return nil
         end
      end
      body.specimenId = specimens.id  
   end

   body.specimenDescription = msg.case.parts[1].specimenDescription
   
   if msg.case.parts[1].udf then
      body.udf = msg.case.parts[1].udf
   end   

   return body
end

local mapCaseParts = {}

-- Unified mapping function for case parts.
-- Parameters:
--   msg         - The incoming message.
--   caseDetails - The existing case details (required for relationship).
--   caseParts   - The existing case part object (only used for patch actions).
--   options     - Table containing action options, for example:
--                   { action = "post" } for new records, or
--                   { action = "patch" } for updates.
function mapCaseParts(msg, caseDetails, caseParts, options)
   options = options or {}
   local action = options.action or "post"
   local body = createBody(msg, caseDetails)
   if not body then
      return nil
   end

   if action == "post" then
      -- For a new case part, include blocks from the message if available.
      if not tu.isNotTableOrEmpty(msg.case.parts[1].blocks) then
         body.blocks = msg.case.parts[1].blocks
      else
         body.blocks = {}
      end
   elseif action == "patch" then
      -- For patching an existing case part, start with the current blocks.
      body.blocks = caseParts.blocks
      -- Check if a new block is provided and if it doesn't already exist, then add it.
      if not tu.isNotTableOrEmpty(msg.case.parts[1].blocks) then
         local newBlock = msg.case.parts[1].blocks[1]
         local blockExists = api.checkBlockExists(caseParts, newBlock.key)
         if not blockExists then
            table.insert(body.blocks, newBlock)
         end
      end
   else
      iguana.logError("Unknown action for mapCaseParts: " .. tostring(action))
   end

   return body
end

return mapCaseParts