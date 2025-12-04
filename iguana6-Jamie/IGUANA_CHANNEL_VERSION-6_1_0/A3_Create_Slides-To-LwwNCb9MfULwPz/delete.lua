-- Import necessary modules
local api = require 'concentriqAPI'
local tu = require 'tableUtils'
local mapCaseDetails = require 'mapCaseDetails'
local mapCaseParts = require 'mapCaseParts'
local checkCaseStatus = require 'checkCaseStatus'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function delete(msg)
   -- Parse the incoming HL7 message
   LOG_LEVEL = (msg.options.logLevels and msg.options.logLevels.deleteSlide) or 'logError'

   ----------------------------------------------------------------------------
   -- CASE DETAILS CHECK
   ----------------------------------------------------------------------------
   local caseDetailsQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = { 
               accessionId = msg.case.accessionId,
               labSiteId = msg.case.labSiteId,
               patientDob = msg.case.patientDob
            }
         }
      }
   }
   caseDetails = api.getCaseDetails(caseDetailsQuery)   

   ----------------------------------------------------------------------------
   -- SLIDE CHECK (only if caseDetails exist)
   ----------------------------------------------------------------------------
   local barcode
   if caseDetails then
      -- If the top-level msg.case.slides is present
      local haveSlides = (msg.case.slides and not tu.isNotTableOrEmpty(msg.case.slides))
      if haveSlides then
         barcode = msg.case.slides[1].barcode
         slides = checkSlides(barcode, caseDetails.id)
      else
         -- If slides are provided under msg.case.parts => blocks => slides
         local haveParts = (msg.case.parts and not tu.isNotTableOrEmpty(msg.case.parts))
         if haveParts then
            local partSlides = msg.case.parts[1].slides
            if partSlides and not tu.isNotTableOrEmpty(partSlides) then
               barcode = partSlides[1].barcode
               slides = checkSlides(barcode, caseDetails.id)
            end
         end
      end
   else
      iguana[LOG_LEVEL]('Skipping message. This case does not exist. Accession ID = ' ..msg.case.accessionId)
      return
   end

   if not slides then
      iguana[LOG_LEVEL]('Skipping message. This slide does not exist. barcode = ' ..barcode)
      return
   end

   -- Prevent slides with images from being deleted based on the flag.
   if slides.primaryImageId ~= json.NULL and msg.options.preventDeletionOfSlidesWithImages then
      iguana.logInfo('Skipping message. This slide has images attached. barcode = ' ..barcode)
      return
   end

   -- Delete the slide
   local slidesDelete = api.deleteSlides(slides.id)

   -- Check for any orphaned blocks or parts and remove them
   local checkOrphanedParts = checkOrphanedParts(caseDetails, msg)
   if checkOrphanedParts == 'deletedCase' then
      iguana.logInfo('Case '..caseDetails.accessionId..' was deleted. Skipping case status update')
      return
   end

   -- Now update the status based on the current state of the case if it has changed
   checkCaseStatus(msg, caseDetails)

   return
end

return delete