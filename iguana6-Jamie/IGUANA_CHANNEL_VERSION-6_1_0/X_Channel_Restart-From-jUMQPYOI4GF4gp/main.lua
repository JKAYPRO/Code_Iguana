-- Import dependencies
local tu = require 'tableUtils'
local controlChannel = require 'controlChannel'
local logAction = require 'logAction'
local simpleTable = require 'simpleTable'
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

   -- Loop through all channels and start any that are not on
   for name, details in pairs(nameTable) do
      if details.status == 'off' or details.status == 'error' then
         local guid = details.guid
         local channelStart = controlChannel('start', guid)
         local logMessage
         if string.match(channelStart:lower(), 'error') ~= nil then
            logMessage = logAction('start', name, 'failed. ' .. channelStart)
         else
            logMessage = logAction('start', name, 'successfully')
         end
         details.actionTaken = logMessage
      end
   end

end
