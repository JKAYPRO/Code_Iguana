-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.

local gc = require 'globalConfig'
local bu = require 'barcodeUtils'
local LOG_LEVEL = (gc.MESSAGE_OPTIONS.logLevels and gc.MESSAGE_OPTIONS.logLevels.parseBarcode) or 'logError'

function main(Data)
   -- 1) Parse JSON safely
   local ok, imageOrErr = pcall(json.parse, {data = Data})
   if not ok then
      iguana[LOG_LEVEL]('JSON parse failed: '..tostring(imageOrErr))
      return
   end
   
   local image = imageOrErr
   
   trace(image)
   trace(image.event)
   trace(image.event.current)
   if not image or not image.event or not image.event.current then
      iguana[LOG_LEVEL]('JSON is not a valid image event webhook payload')
      return
   end
   
   
   local barcode = image.event.current.barcodeData
   trace(barcode)

   -- Validate barcode
   if not gc.MESSAGE_OPTIONS.skipBarcodeValidation then
      local parsedBarcode = bu.parseBarcode(barcode, gc.BARCODE_FORMAT, gc.BARCODE_COMPONENTS)
      if parsedBarcode == nil then
         iguana[LOG_LEVEL]('Failed to parse barcode for image. Barcode value = '..barcode..'. Filename = '..image.event.current.filename)
         return
      end   
   end
   queue.push{data=Data}

end