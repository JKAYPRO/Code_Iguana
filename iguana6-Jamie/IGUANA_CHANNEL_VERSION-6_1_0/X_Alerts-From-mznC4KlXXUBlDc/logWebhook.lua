local retry = require 'retry'
local tu = require 'tableUtils'
local gc = require 'globalConfig'

local function logWebhook(nameTable)
   local toRemove = {}

   for name, details in pairs(nameTable) do
      if details.status == 'on' and details.errors == '0' then
         table.insert(toRemove, name)
      end
   end

   trace(toRemove)

   -- Remove the marked entries after the loop
   for _, name in ipairs(toRemove) do
      nameTable[name] = nil
   end
   
   trace(nameTable)
   if tu.isEmpty(nameTable) then
      return
   end
   

   local requestBody = {
      requester = gc.ALERTS.REQUESTER,
      subject = gc.ALERTS.CLIENT_NAME..' - Iguana Channel Monitor'
   }

   -- Start the HTML table structure
   local htmlTable = [[
   <table border="1">
   <tr>
   <th>Name</th>
   <th>Status</th>
   <th>Errors</th>
   <th>Action Taken</th>
   </tr>
   ]]

   -- Loop through nameTable to add rows to the HTML table
   for name, details in pairs(nameTable) do
      htmlTable = htmlTable .. string.format([[
         <tr>
         <td>%s</td>
         <td>%s</td>
         <td>%d</td>
         <td>%s</td>
         </tr>
         ]], name, details.status, details.errors,details.actionTaken or "-")
   end

   -- Close the HTML table
   htmlTable = htmlTable .. "</table>"

   -- Add the generated HTML table to the "body" table under a single key
   requestBody.body = htmlTable   

   trace(requestBody)

   local request = {
      timeout = 10,
      live = false,
      url = 'https://hooks.zapier.com/hooks/catch/18692772/2mdtbtr/',
      body = json.serialize{data=requestBody,alphasort=true}
   }

   local response, responseCode, responseHeaders = retry.call{
      func = net.http.post,
      arg1 = request,
      retry = 10,
      pause = 1,
      funcname = 'Zapier - logWebhook'
   }

end

return logWebhook