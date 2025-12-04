local tableUtils = {}

function tableUtils.isNotTable(t)
    -- Check if the variable is not a table
    return type(t) ~= "table"
end

function tableUtils.isEmpty(t)
    -- Check if the table is empty
    for _ in pairs(t) do
        return false  -- Found an element, so it's not empty
    end
    return true  -- No elements found, table is empty   
end

function tableUtils.isNotTableOrEmpty(t)
    -- Utilize isNotTable and isEmpty functions
    return tableUtils.isNotTable(t) or tableUtils.isEmpty(t)
end

-- Helper function to check if an item exists in a table based on a specified key and value
function tableUtils.itemExists(t, key, value)
   for _, item in ipairs(t) do
      if item[key] == value then
         return true
      end
   end
   return false
end

-- Helper function to check if an item exists in a table
function tableUtils.valueExists(t, value)
   for _, item in ipairs(t) do
      if item == value then
         return true
      end
   end
   return false
end

-- Function to remove an item from a table based on a specified key and value
function tableUtils.removeItem(t, key, value)
    for i, item in ipairs(t) do
        if item[key] == value then
            table.remove(t, i)
            return true
        end
    end
    return false
end

function tableUtils.deepCopy(t)
   local newTable = {}
   for k, v in pairs(t) do
      newTable[k] = v
   end
   return newTable
end

-- Function to remove items from a table based on pattern matching
-- If removeIfMatch is true, it removes items that match the pattern.
-- If removeIfMatch is false, it removes items that don't match the pattern.
function tableUtils.removeItemsByPattern(t, key, pattern, removeIfMatch)
    local i = 1
    while i <= #t do
        local item = t[i]
        local matchFound = item[key]:find(pattern)
        
        if (removeIfMatch and matchFound) or (not removeIfMatch and not matchFound) then
            table.remove(t, i)
        else
            i = i + 1
        end
    end
   return t
end

function tableUtils.mergeTables(tbl1, tbl2)
    local merged = {}
    for _, v in ipairs(tbl1) do
        table.insert(merged, v)
    end
    for _, v in ipairs(tbl2) do
        table.insert(merged, v)
    end
    return merged
end

return tableUtils
