function unescapeHL7(text)
    local unescaped = text
    unescaped = unescaped:gsub("\\F\\", "|")
    unescaped = unescaped:gsub("\\S\\", "^")
    unescaped = unescaped:gsub("\\T\\", "&")
    unescaped = unescaped:gsub("\\R\\", "~")
    unescaped = unescaped:gsub("\\E\\", "\\")
    return unescaped
end

return unescapeHL7