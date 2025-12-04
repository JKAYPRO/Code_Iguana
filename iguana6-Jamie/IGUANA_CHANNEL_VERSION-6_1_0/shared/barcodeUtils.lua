local barcodeUtils = {}
local gc = require 'globalConfig'
local LOG_LEVEL = (gc.MESSAGE_OPTIONS.logLevels and gc.MESSAGE_OPTIONS.logLevels.parseBarcode) or 'logError'

function barcodeUtils.parseBarcode(barcode, pattern, components)
    if barcode == json.NULL then
        iguana[LOG_LEVEL]("parseBarcode: Barcode value is null")
        return nil
    end
   
    if not string.match(barcode, pattern) then
        iguana[LOG_LEVEL]("parseBarcode: Invalid barcode format. Barcode = " .. barcode)
        return nil
    end

    -- Check if componentKeys is a string
    local componentKeys = {}
    if type(components) == "string" then
        -- Remove spaces and split the string by commas into a table
        for key in string.gmatch(components, "([^,%s]+)") do
            table.insert(componentKeys, key)
        end
    else
      componentKeys = components
    end

    local parts = {}
    local values = {string.match(barcode, pattern)}
	
    
    if #values ~= #componentKeys then
        iguana[LOG_LEVEL]("parseBarcode: The number of extracted values does not match the number of component keys. Barcode = " .. barcode)
        return nil
    end

    for i, key in ipairs(componentKeys) do
        parts[key] = values[i]
    end

    return parts
end

return barcodeUtils