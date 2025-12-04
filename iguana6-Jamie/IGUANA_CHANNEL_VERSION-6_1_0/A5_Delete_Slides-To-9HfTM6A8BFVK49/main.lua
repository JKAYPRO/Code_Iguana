-- Import necessary modules
local api = require 'concentriqAPI'
local tu = require 'tableUtils'
local mapCaseDetails = require 'mapCaseDetails'

local mapCaseParts = require 'mapCaseParts'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   -- Parse the incoming HL7 message
   local msg = json.parse{data=Data}
   LOG_LEVEL = msg.options.logLevel or 'logError'

   -- Extract and parse the barcode
   local barcode = msg.case.parts[1].slides[1].barcode
   trace(barcode)

   -- Get the existing slide information
   local slidesQuery = json.serialize{data={eager={["$where"]={barcode=barcode}}}}
   trace(slidesQuery)
   local slides = api.getSlides(slidesQuery)   
   trace(slides)

   if not slides then
      iguana[LOG_LEVEL]('Skipping message. This slide does not exist. barcode = ' ..barcode)
      return
   end

      -- Prevent slides with images from being deleted based on the flag.
      if slides.primaryImageId ~= json.NULL and msg.options.preventDeletionOfSlidesWithImages then
        iguana[LOG_LEVEL]('Skipping message. This slide has images attached. barcode = ' ..barcode)
        return
     end
  
   -- Delete the slide
   local slidesDelete = api.deleteSlides(slides.id)

   -- Check if that is the only slide on the block
   local otherSlidesQuery = json.serialize{data={eager={["$where"]={casePartId=slides.casePartId,blockKey=slides.blockKey}}}}
   local otherSlides = api.getSlides(otherSlidesQuery)

   -- if otherSlides is falsey, then there are no other slides on the block
   if not otherSlides then
      -- If so, update caseParts to remove the block, or remove the part if that is the last block
      local casePartsQuery = json.serialize{data={eager={["$where"]={id=slides.casePartId}}}}
      local caseParts = api.getCaseParts(casePartsQuery)
      -- Remove the block from the blocks table
      tu.removeItem(caseParts.blocks, 'key', slides.blockKey)

      -- Check if the block is the only block on the part. If the blocks table is now empty, it was the only block
      if tu.isEmpty(caseParts.blocks) then
         -- If so, delete the part instead of updating the blocks array on the part
         local casePartsDelete = api.deleteCaseParts(caseParts.id)

         -- Since a part was deleted, check if there are any other parts for the case, if not, delete the case
         local casePartsOnCaseQuery = json.serialize{data={eager={["$where"]={caseDetailId = caseParts.caseDetailId}}}}
         local casePartsOnCase = api.getCaseParts(casePartsOnCaseQuery)

         if not casePartsOnCase then
            localCaseDetailsDelete = api.deleteCaseDetails(caseParts.caseDetailId)
            return -- If the case is deleted, no further acction is needed.
         end

      else
         -- If there are other blocks, then update the "blocks" value to remove the block from the part.
         local casePartsBody = mapCaseParts(caseParts.blocks)
         local casePartsPatch = api.patchCaseParts(caseParts.id, casePartsBody)
      end      
   end

   -- Now update the status based on the current state of the case
   local status = api.caseStatus(slides.caseDetailId)

   local caseDetailsBody = mapCaseDetails(status)
   local caseDetails = api.patchCaseDetails(slides.caseDetailId, caseDetailsBody)   

   return
end