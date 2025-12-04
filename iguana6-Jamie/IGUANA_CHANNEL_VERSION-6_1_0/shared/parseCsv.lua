function parseCsv(params)
   local headers = params.headers
   local rowDelimiter = params.rowDelimiter or "\r\n"
   local columnDelimiter = params.columnDelimiter or ","
   local data = params.data:gsub(rowDelimiter.."+$", "") -- Trim trailing empty rows

   local result      = {}
   local currentRow  = {}
   local columnCount = #headers
   local i           = 1
   local inQuotes    = false
   local quoteChar   = '"'
   local fieldBuffer = {}
   local dataLength  = #data
   local rowIndex    = 1

   local function finalizeField()
      local fieldValue = table.concat(fieldBuffer)
      table.insert(currentRow, fieldValue)
      fieldBuffer = {}
   end

   local function finalizeRow()
      if #currentRow ~= columnCount then
         error("Row "..rowIndex.." does not match the number of headers.")
      end
      local rowObj = {}
      for colIndex, colName in ipairs(headers) do
         rowObj[colName] = currentRow[colIndex]
      end
      table.insert(result, rowObj)
      currentRow = {}
      rowIndex = rowIndex + 1
   end

   while i <= dataLength do
      local c = data:sub(i, i)

      if c == quoteChar then
         if inQuotes then
            -- Handle escaped quotes
            if i < dataLength and data:sub(i + 1, i + 1) == quoteChar then
               table.insert(fieldBuffer, quoteChar)
               i = i + 2
            else
               inQuotes = false
               i = i + 1
            end
         else
            inQuotes = true
            i = i + 1
         end
      elseif not inQuotes and data:sub(i, i + #columnDelimiter - 1) == columnDelimiter then
         finalizeField()
         i = i + #columnDelimiter
      elseif not inQuotes and data:sub(i, i + #rowDelimiter - 1) == rowDelimiter then
         finalizeField()
         finalizeRow()
         i = i + #rowDelimiter
      else
         table.insert(fieldBuffer, c)
         i = i + 1
      end
   end

   if #fieldBuffer > 0 or #currentRow > 0 then
      finalizeField()
      finalizeRow()
   end

   return result
end

return parseCsv
