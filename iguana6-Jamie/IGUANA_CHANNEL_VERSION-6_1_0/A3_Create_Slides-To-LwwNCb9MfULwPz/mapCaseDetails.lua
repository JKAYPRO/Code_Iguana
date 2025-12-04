-- unified_mapCaseDetails.lua

local api = require 'concentriqAPI'

-- Create the common body with shared fields.
local function createBody(msg)
   local body = {}
   body.accessionDate         = msg.case.accessionDate
   body.accessionId           = msg.case.accessionId
   body.isStat                = msg.case.isStat
   body.labSiteId             = msg.case.labSiteId
   body.patientDob            = msg.case.patientDob
   body.patientLastName       = msg.case.patientLastName
   body.patientFirstName      = msg.case.patientFirstName
   body.patientMiddleName     = msg.case.patientMiddleName
   body.patientMrn            = msg.case.patientMrn
   body.patientSex            = msg.case.patientSex
   body.patientGenderIdentity = msg.case.patientGenderIdentity

   -- Case Assignment
   local assignedUserCode = msg.case.assignedUserCode
   if assignedUserCode then
      local lookupField = msg.options.assignedUserIdLookupField
      local queryCriteria = {["$ilike"] = assignedUserCode}
      local assignedUserQuery = json.serialize{
         data = {
            eager = {
               ["$where"] = {
                  [lookupField] = queryCriteria
               }
            }
         }
      }
      local user = api.getUsers(assignedUserQuery)
      if user then
         body.assignedUserId = user.id
      else
         body.assignedUserId = nil
         iguana.logWarning('User not found where ' .. lookupField .. ' = ' .. assignedUserCode)
      end
   end
   body.assignedUserId = body.assignedUserId or nil

   -- Specimen Category
   local specimenCategoryCode = msg.case.specimenCategoryCode
   local specimenCategoryName = msg.case.specimenCategoryName
   if specimenCategoryCode then
      specimenCategoryCode = specimenCategoryCode and string.trimWS(specimenCategoryCode)
      specimenCategoryName = specimenCategoryName and string.trimWS(specimenCategoryName)
      local specimenCategoryQuery = json.serialize{
         data = { eager = { ["$where"] = { code = specimenCategoryCode } } }
      }
      local specimenCategories = api.getSpecimenCategories(specimenCategoryQuery)
      if not specimenCategories then
         if msg.options.addSpecimenCategories == true then
            local specimenCategoriesBody = { code = specimenCategoryCode, name = specimenCategoryName }
            specimenCategories = api.postSpecimenCategories(specimenCategoriesBody)
            if not specimenCategories then
               iguana.logError('Specimen Category could not be added: ' .. specimenCategoryCode)
               return nil
            end  
         else
            iguana.logError('Specimen Category does not exist: ' .. specimenCategoryCode .. '^' .. specimenCategoryName)
            return nil
         end
      end
      body.specimenCategoryId = specimenCategories.id
   end

   body.udf = msg.case.udf

   return body
end

local mapCaseDetails = {}

-- Unified mapping function.
-- Parameters:
--   msg         - The incoming message.
--   caseDetails - Existing case details (if applicable; required for patch).
--   options     - Table containing workflow and action options.
--                 For example:
--                 { workflow = "upsert", action = "post" }
--                 { workflow = "upsert", action = "patch", updateStatus = false }
--                 Other workflows: "caseResults", "delete"
function mapCaseDetails(msg, caseDetails, options)
   options = options or {}
   local workflow = options.workflow or "upsert"
   local body = createBody(msg)

   --if workflow == "upsert" then
   if options.action == "post" then
      -- For new records, set caseStage to "building".
      body.caseStage = "building"
   elseif options.action == "patch" then
      -- For updates, if a caseStage is provided in the message, use it.
      -- Overwrite case stage if it is provided in the message and not locked in Archive
      if msg.case.caseStage then
         if not (msg.options.archiveStatusLocked and caseDetails and caseDetails.caseStage == "archived") then
            body.caseStage = msg.case.caseStage
         end
      else
         -- Calculate case stage based on images linked to slides unless images are being added
         -- in which case we will update the status after adding the image.
         if options.updateStatus then
            local status = api.caseStatus(caseDetails.id, msg.options.archiveStatusLocked, caseDetails.caseStage)
            body.caseStage = status
         end
      end
   else
      iguana.logError("Unknown action for upsert workflow: " .. tostring(options.action))
   end

   return body
end

return mapCaseDetails