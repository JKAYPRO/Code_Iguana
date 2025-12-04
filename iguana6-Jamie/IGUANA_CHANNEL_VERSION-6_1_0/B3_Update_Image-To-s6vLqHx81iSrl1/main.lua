local api = require 'concentriqAPI'
local gc = require 'globalConfig'
local mapImages = require 'mapImages'
local mapCaseDetails = require 'mapCaseDetails'
local LOG_LEVEL = (gc.MESSAGE_OPTIONS.logLevels and gc.MESSAGE_OPTIONS.logLevels.imageSlideMatch) or 'logError'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)

   local image = json.parse{data=Data}
   local barcode = image.event.current.barcodeData:gsub('<FNC1>',''):gsub('\029','')
   trace(barcode)

   -- Check if the barcode is an empty string
   if image.event.current.barcodeData == "" then
      iguana[LOG_LEVEL]('Barcode is empty. Skipping image')
      return
   end

   -- Check if slide exists for the given barcode
   local slidesQuery = json.serialize{data={eager={["$where"]={barcode=barcode}}}}
   local slides = api.getSlides(slidesQuery)

   if not slides then
      -- For pull integrations, check if a slide exists for rescans, but do not throw an error
      if not gc.MESSAGE_OPTIONS.pullIntegration then
         -- No slides found
         iguana[LOG_LEVEL]('No slide found for barcode "' ..barcode..
            '". Verify the barcode format is correct and that the order has been received and processed successfully')
      else
         iguana[LOG_LEVEL]('No slide found for barcode "' ..barcode..'".')
      end
   else   

      local imagesBody = mapImages(slides)
      local imagesPatch = api.patchImages(image.event.current.id, imagesBody)

      -- Check if the slide is pending rescan, and if so, update the rescan status to null
      if slides.orderStatus ~= json.NULL then
         local slideBody = {orderStatus = json.NULL}
         local slideUpdate = api.patchSlides(slides.id, slideBody)
      end

      -- Now update the status based on the current state of the case
      local status = api.caseStatus(slides.caseDetailId, gc.MESSAGE_OPTIONS.archiveStatusLocked)      

      local caseDetailsBody = mapCaseDetails(status)
      local caseDetails = api.patchCaseDetails(slides.caseDetailId, caseDetailsBody)
   end

end