-- Function to log channel actions
local function logAction(action, channelName, message)
   local logMessage = action..' channel: '..channelName..' - '..message
   iguana.logInfo(logMessage)
   return logMessage
end

return logAction