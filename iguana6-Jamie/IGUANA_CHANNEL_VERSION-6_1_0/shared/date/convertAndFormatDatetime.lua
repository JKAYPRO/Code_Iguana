function convertAndFormatDatetime(datetimeStr, inputPattern, outputFormat, offsetHours, offsetMinutes)
    -- Parse the input datetime string using the given pattern
    local year, month, day, hour, min, sec, ms = datetimeStr:match(inputPattern)
    
    -- Convert parsed values to numbers, handling cases where certain components are optional
    year = tonumber(year) or 0
    month = tonumber(month) or 0
    day = tonumber(day) or 0
    hour = tonumber(hour) or 0
    min = tonumber(min) or 0
    sec = tonumber(sec) or 0
    ms = tonumber(ms) or 0  -- Default to 0 if milliseconds are not provided

    -- Create a table with parsed datetime components
    local timeTable = {year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = false}
    
    -- Use os.ts.time to get the Unix Epoch time as a number
    local timeInSeconds = os.ts.time(timeTable)
    if not timeInSeconds then
        error("Failed to convert the provided date and time to a numeric timestamp.")
    end

    -- Apply the offset (adjust hours and minutes)
    local offsetInSeconds = (offsetHours * 3600) + (offsetMinutes * 60)
    timeInSeconds = timeInSeconds + offsetInSeconds  -- Apply the offset

    -- Get the adjusted time using os.ts.date
    local adjustedTime = os.ts.date("*t", timeInSeconds)

    -- Replace output format placeholders with adjusted time components
    local formattedTimestamp = outputFormat
    formattedTimestamp = formattedTimestamp:gsub("YYYY", string.format("%04d", adjustedTime.year))
    formattedTimestamp = formattedTimestamp:gsub("MM", string.format("%02d", adjustedTime.month))
    formattedTimestamp = formattedTimestamp:gsub("DD", string.format("%02d", adjustedTime.day))
    formattedTimestamp = formattedTimestamp:gsub("hh", string.format("%02d", adjustedTime.hour))
    formattedTimestamp = formattedTimestamp:gsub("mm", string.format("%02d", adjustedTime.min))
    formattedTimestamp = formattedTimestamp:gsub("ss", string.format("%02d", adjustedTime.sec))
    formattedTimestamp = formattedTimestamp:gsub("SSS", string.format("%03d", ms))

    return formattedTimestamp
end

return convertAndFormatDatetime

