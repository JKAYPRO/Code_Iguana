function timezoneOffsetToNumber(offsetStr)
    -- Extract the sign, hours, and minutes from the offset string
    local sign, hours, minutes = offsetStr:match("([%+%-])(%d%d):(%d%d)")
    
    -- Convert hours and minutes to numbers
    hours = tonumber(hours)
    minutes = tonumber(minutes)

    -- Apply the sign to the hours and minutes
    if sign == "-" then
        hours = -hours
        minutes = -minutes
    end

    return hours, minutes
end

return timezoneOffsetToNumber