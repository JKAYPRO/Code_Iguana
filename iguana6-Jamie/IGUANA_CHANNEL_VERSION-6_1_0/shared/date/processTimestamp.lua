local gc = require 'globalConfig'
local tzOffset = require 'date.getTimezoneOffset'
local tzOffsetToNumber = require 'date.timezoneOffsetToNumber'
local convertAndFormatDatetime = require 'date.convertAndFormatDatetime'

local function processTimestamp(timestamp)
   local offsetHours, offsetMinutes = tzOffsetToNumber(
      tzOffset(timestamp:gsub("%D", ""):sub(1, 12):TIME(), gc.DEFAULT_OFFSET, gc.DST_TRANSITIONS)
   )
   return convertAndFormatDatetime(timestamp, '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+).(%d+)Z', 'YYYYMMDDhhmmssSSS', offsetHours, offsetMinutes)
end

return processTimestamp