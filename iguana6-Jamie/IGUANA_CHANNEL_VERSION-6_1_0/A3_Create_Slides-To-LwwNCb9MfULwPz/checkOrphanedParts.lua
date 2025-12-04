local api = require 'concentriqAPI'
local tu = require 'tableUtils'
local mapCaseDetails = require 'mapCaseDetails'

function checkOrphanedParts(caseDetails, msg)
   -- Build the query to retrieve case details with slides and caseParts.
   local caseDetailsWithPartsAndSlidesQuery = json.serialize{
      data = {
         eager = {
            slides = { ["empty"] = false },      -- add dummy value to force attachments to be an object
            caseParts = { ["empty"] = false }     -- add dummy value to force attachments to be an object
         }
      }
   }
   caseDetailsWithPartsAndSlidesQuery = caseDetailsWithPartsAndSlidesQuery:gsub('"empty": false','') -- remove the dummy value
   local caseDetailsWithPartsAndSlides = api.getCaseDetail(caseDetails.id, caseDetailsWithPartsAndSlidesQuery)

   -- Check if there are any slides in the case details
   if tu.isEmpty(caseDetailsWithPartsAndSlides.slides) and msg.options.deleteCaseIfNoSlidesLeft then
      local deletedCase = api.deleteCaseDetails(caseDetails.id)
      iguana.logInfo('Case ' .. caseDetails.id .. ' deleted.')
      return 'deletedCase'
   else
      local caseDetailsBody = mapCaseDetails(msg, caseDetails, {action = 'patch', updateStatus = true})
      local caseDetailsUpdate = api.patchCaseDetails(caseDetails.id, caseDetailsBody)
   end   

   -- Loop over each casePart in caseDetails
   for _, part in ipairs(caseDetailsWithPartsAndSlides.caseParts) do
      -- Filter slides associated with this part (matching via casePartId)
      local partSlides = {}
      for _, slide in ipairs(caseDetailsWithPartsAndSlides.slides) do
         if slide.casePartId == part.id then
            table.insert(partSlides, slide)
         end
      end

      if tu.isEmpty(partSlides) then
         -- If no slides are associated with this part, delete the part
         local deletedPart = api.deleteCaseParts(part.id)
         iguana.logInfo('Case part ' .. part.id .. ' deleted.')
      else
         local partChanged = false  -- Flag to track if any blocks are removed.
         -- Check each block in this part for a matching slide.
         for blockIndex = #part.blocks, 1, -1 do
            local block = part.blocks[blockIndex]
            local blockHasSlide = false

            -- Iterate over the filtered slides for this part.
            for _, slide in ipairs(partSlides) do
               if slide.blockKey == block.key then
                  blockHasSlide = true
                  break
               end
            end

            -- If no matching slide exists, remove the block.
            if not blockHasSlide then
               table.remove(part.blocks, blockIndex)
               partChanged = true
               iguana.logInfo('Block with key ' .. block.key .. ' removed from part ' .. part.id)
            end
         end

         -- If any blocks were removed, update the part via an API call.
         if partChanged then
            local patchCasePartsBody = { blocks = part.blocks }
            local patchedPart = api.patchCaseParts(part.id, patchCasePartsBody)
         end
      end
   end
end

return checkOrphanedParts