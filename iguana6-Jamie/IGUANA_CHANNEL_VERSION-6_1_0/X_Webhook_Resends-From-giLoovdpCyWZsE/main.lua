local api = require 'concentriqAPI'
local gc = require 'globalConfig'

-- The main function is the first function called from Iguana.
function main()

   -- GET webhookRequests to see if any have erred and failed to process
   local webhookRequestsQuery = json.serialize{
      data = {
         eager = {
            ["$where"]= {
               webhookId = {
                  ["$in"] = gc.WEBHOOK_REQUEST_IDS
               },
               requestSignatureTimestamp = {
                  ["$gte"] = gc.WEBHOOK_REQUEST_START_DATE
               },
               status = 'error'
            }
         },
         fields = {'id', 'webhookId'},
         order = {
            {
               column = "requestSignatureTimestamp",
               order = "asc"
            }
         }
      }
   }

   local webhookRequests = api.getWebhookRequests(webhookRequestsQuery)

   if webhookRequests then
      for i=1, #webhookRequests.items do
         queue.push{data=json.serialize{data=webhookRequests.items[i],alphasort=true}}
      end
   end

end