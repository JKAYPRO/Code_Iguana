local gc = require 'globalConfig'

-- Function to control the channel (start/stop) based on action and guid
local function controlChannel(action, guid)
   local post = net.http.post{
      url=gc.ALERTS.IGUANA_URL,           
      auth={
         password=gc.ALERTS.PASSWORD,
         username=gc.ALERTS.USERNAME
      },
      parameters={
         action=action,
         guid=guid
      },
      live=gc.ALERTS.LIVE
   }
   
   return post
end

return controlChannel