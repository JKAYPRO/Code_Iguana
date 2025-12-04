function getTimezoneOffset(time, defaultOffset, dstTransitions)
  
   -- Determine the current timezone offset
   local tzoffset = defaultOffset
   for i, v in ipairs(dstTransitions) do
      if time > v.timestamp then
         tzoffset = v.offset
      else
         break
      end
   end

   -- Print the current timezone offset
   trace("Current timezone offset: " .. tzoffset)
	
   return tzoffset
end

return getTimezoneOffset