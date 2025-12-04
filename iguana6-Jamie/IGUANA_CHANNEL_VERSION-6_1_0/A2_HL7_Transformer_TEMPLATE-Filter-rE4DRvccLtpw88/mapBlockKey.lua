function mapBlockKey(parsedBarcode)
   trace(parsedBarcode)
   return parsedBarcode.part..parsedBarcode.block
end 

return mapBlockKey