local api = require 'concentriqAPI'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   msg = json.parse{data=Data}

   local webhookResend = api.postWebhookResend(msg.id)
   iguana.logInfo('Webhook resent. Id = ' .. msg.id)

end