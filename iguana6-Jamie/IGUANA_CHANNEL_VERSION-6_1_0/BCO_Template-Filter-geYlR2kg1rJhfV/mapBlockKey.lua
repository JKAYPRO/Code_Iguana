function mapBlockKey(parsedBarcode)
   return parsedBarcode.part..'-'..parsedBarcode.block
end

return mapBlockKey