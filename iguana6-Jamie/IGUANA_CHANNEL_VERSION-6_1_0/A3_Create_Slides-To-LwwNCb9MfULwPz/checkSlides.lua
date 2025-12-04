local api = require 'concentriqAPI'

function checkSlides(barcode, caseDetailId, createSlides, updateSlides)
   if not barcode then return end
   local slidesQuery = json.serialize{ 
      data = {
         eager = { 
            ["$where"] = { 
               barcode = barcode,
               caseDetailId = caseDetailId
            } 
         } 
      } 
   }
   slides = api.getSlides(slidesQuery)
   if not slides then
      createSlides = true
   else
      updateSlides = true
   end
   
   return slides, createSlides, updateSlides
end

return checkSlides