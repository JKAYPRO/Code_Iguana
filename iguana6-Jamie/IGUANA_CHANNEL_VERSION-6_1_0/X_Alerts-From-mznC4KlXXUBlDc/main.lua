-- Import dependencies
local tu = require 'tableUtils'
local simpleTable = require 'simpleTable'
local logWebhook = require 'logWebhook'
local gc = require 'globalConfig'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   local X = xml.parse{data=iguana.status()}

   -- Create a table with an entry for each channel with the channel name as the key 
   -- so that the id and guid are easily retrievable
   local nameTable = simpleTable(X)
   trace(nameTable)   

   -- Remove the exception channels from nameTable
   for name in pairs(nameTable) do
      if tu.valueExists(gc.ALERTS.EXCEPTIONS, name) then
         nameTable[name] = nil
      end
   end

   -- Send a list of all
   logWebhook(nameTable)
end
