local gc = require 'globalConfig'
local parseImage = require "parseImage"
local bu = require "barcodeUtils"

function main(Data)
   local image = json.parse{data=Data}
   local barcode = image.event.current.barcodeData
	local parsedBarcode = bu.parseBarcode(barcode,gc.BARCODE_FORMAT,gc.BARCODE_COMPONENTS)
   if parsedBarcode == nil then
      -- Handle invalid barcodes
      iguana.logError('Invalid Barcode. Message filtered. Barcode = '..barcode)
      return
   else
      local jsonMsg = {}
      jsonMsg = parseImage(image, barcode, parsedBarcode)
      queue.push{data=json.serialize{data=jsonMsg,alphasort=true}}
   end
end