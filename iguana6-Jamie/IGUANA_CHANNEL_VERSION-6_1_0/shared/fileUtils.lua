local fileUtils = {}

function fileUtils.listFiles(os, directory)
   -- Linux
   if os == 'Linux' then
      local command = 'ls ' .. directory
      local handle = io.popen(command)
      local result = handle:read("*a") -- Read all output from the command
      handle:close()

      -- Log the result
      trace(result)

      -- Split the result into lines (one file per line)
      local files = {}
      local listing = result:split("\n")
      for i, file in ipairs(listing) do
         if file ~= "" then
            table.insert(files,file)
         end
      end

      return files     
   end

   -- Windows


end


return fileUtils