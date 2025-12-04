-- Import necessary modules
local api = require 'concentriqAPI'
local map = require 'mappingTables'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)
   local msg = json.parse{data=Data}   

   local slideQuery = json.serialize{
      data = {
         eager = {
            stain = {["empty"]=false}
         },            
      }
   }
   slideQuery = slideQuery:gsub('"empty": false','') -- Remove any unwanted fields
   local slide = api.getSlide(msg.event.current.slideId,slideQuery)

   -- Get the stain name from the slide
   local stainName = slide.stain and slide.stain.name
   if not stainName then
      trace('No stain name found for slide ID: ' .. slide.id)
   else
      -- Directly reference stainAppMap to find app ID
      local appId = map.stainAppMap[stainName]


      if not appId then
         trace('No app found for stain "' .. stainName .. '" on slide ID: ' .. slide.id)
      else
         -- Build the request body
         local runSlideAnalysesBody = {
            slideIds = { slide.id },
            thirdPartyAnalysisAppId = appId
         }

         trace(runSlideAnalysesBody)
         if not iguana.isTest() then
            local runSlideAnalyses = api.postRunSlideAnalyses(runSlideAnalysesBody)
         end


      end
   end

end
