function simpleTable(X)
   local t = {}
   local num_channels = tonumber(X.IguanaStatus:childCount("Channel"))   
   for i = 1, num_channels do
      local name = X.IguanaStatus:child("Channel", i).Name:nodeValue()
      local channelDetails = {
         index = i,
         status = X.IguanaStatus:child("Channel", i).Status:nodeValue(),
         guid = X.IguanaStatus:child("Channel", i).Guid:nodeValue(), 
         errors = X.IguanaStatus:child("Channel", i).TotalErrors:nodeValue()
      }
      t[name]=channelDetails 
   end
   return t
end

return simpleTable