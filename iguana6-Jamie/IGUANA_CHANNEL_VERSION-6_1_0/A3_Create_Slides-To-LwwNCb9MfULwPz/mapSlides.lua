local api = require 'concentriqAPI'

-- LOCAL FUNCTIONS
-- Construct the message body for common items across all requests
local function createBody(msg, caseDetails, caseParts)
   local body = {}

   -- Determine the slide source: check for a slide under a case part, else look at the case level
   local slide = nil
   if msg.case.parts 
      and msg.case.parts[1] 
      and msg.case.parts[1].slides 
      and msg.case.parts[1].slides[1] then
      slide = msg.case.parts[1].slides[1]
   elseif msg.case.slides and msg.case.slides[1] then
      slide = msg.case.slides[1]
   else
      iguana.logError("Slide not found: neither msg.case.parts[1].slides[1] nor msg.case.slides[1] exist.")
      return nil
   end

   body.barcode = slide.barcode
   body.blockKey = slide.blockKey
   body.caseDetailId = caseDetails.id
   body.casePartId = caseParts and caseParts.id or nil
   body.name = slide.name
   body.sortOrder = slide.sortOrder

   -- Stain
   local stainCode = slide.stainCode
   local stainName = slide.stainName

   -- Trim the whitespace
   stainCode = stainCode and string.trimWS(stainCode)
   stainName = stainName and string.trimWS(stainName)

   if stainCode then
      local stainsQuery = json.serialize{
         data = { eager = { ["$where"] = { code = stainCode } } }
      }
      local stains = api.getStains(stainsQuery)
      if not stains then
         if msg.options.addStains == true then
            local stainsBody = {}
            stainsBody.code = stainCode
            stainsBody.name = stainName
            stains = api.postStains(stainsBody)
            if not stains then
               iguana.logError('Stain could not be added: ' .. stainCode)
               return nil
            end  
         else 
            iguana.stopOnError(true)
            iguana.logError('Stain does not exist: ' .. stainCode)
            return nil
         end
      end
      body.stainId = stains.id
   end
   
   body.sortOrder = slide.sortOrder

   -- UDF
   body.udf = slide.udf

   return body
end

-- FUNCTIONS TO EXPORT
local mapSlides = {}

function mapSlides.post(msg, caseDetails, caseParts)
   local body = createBody(msg, caseDetails, caseParts)
   return body
end

function mapSlides.patch(msg, caseDetails, caseParts)
   local body = createBody(msg, caseDetails, caseParts)
   return body
end

return mapSlides