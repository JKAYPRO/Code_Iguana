function mapAccessionId(parsedBarcode)
   return parsedBarcode.pathologist .. parsedBarcode.year .. '-' .. parsedBarcode.caseNumber
end

return mapAccessionId