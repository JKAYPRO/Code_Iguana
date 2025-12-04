local api = require 'concentriqAPI'
local ias = require 'iasAPI'
local tu = require 'tableUtils'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)

   local case = json.parse{data=Data}
   local aiResults = {
      accessionId = case.event.current.accessionId,
      slides = {}
   }

   -- Get all snapshots and grab the ones with the Visiopharm prefix
   local caseDetailQuery = json.serialize{data={eager={attachments={["empty"]=false}}}} -- add dummy value to force attacments to be an object
   caseDetailQuery = caseDetailQuery:gsub('"empty": false','') -- remove the dummy value
   local caseDetail = api.getCaseDetail(case.event.current.id,caseDetailQuery)
   local attachments = tu.removeItemsByPattern(caseDetail.attachments, 'filename', '^VP-', false)

   for i = 1, #attachments do
      local slideName = attachments[i].storageKey:match("SS%d+%-%d+%a+%-%d+")
      attachments[i].slideName = slideName

   end

   -- Sort the attachments by updatedAt in descending order
   table.sort(attachments, function(a, b)
         return a.updatedAt > b.updatedAt  -- Descending order: most recent first
      end)

   trace(attachments)

   -- Get all the slides. 
   local slidesQuery = json.serialize{
      data={
         eager={
            ["$where"]={caseDetailId=case.event.current.id},
            casePart={["empty"]=false} -- add dummy value to force attacments to be an object
         },            
      }
   }
   slidesQuery = slidesQuery:gsub('"empty": false','') -- remove the dummy value
   local slides = api.getSlidesAll(slidesQuery)

   -- Loop through the slides and get all of the stain and AI result data, and grab the appropriate attachment
   for i = 1, #slides do
      local aiResult = {}
      local stain = api.getStain(slides[i].stainId)
      trace(slides[i].name)

      -- Get the slide info
      aiResult.barcode = slides[i].barcode
      aiResult.stain = stain.name

      -- Get Visiopharm Data
      -- Get JWT Token for the Image
      if slides[i].primaryImageId ~= json.NULL then
         local jwtToken = api.getImageToken(slides[i].primaryImageId)

         -- Get Analysis from IAS API
         local analysesQuery = json.serialize{data={eager={["$where"]={status='Complete'}}}}
         local analyses = ias.getAnalyses(analysesQuery,jwtToken.jwt)

         local results
         if not analyses then
            aiResult.results = {}
         else
            aiResult.results = analyses.items[1].userDefinedFields
         end
      end

      -- Get snapshot
      local snapshot
      for a = 1, #attachments do
         trace(attachments[a].slideName)
         trace(slides[i].name)

         if attachments[a].slideName == slides[i].name then
            snapshot = api.getFile('Attachment',attachments[a].id,attachments[a].storageKey)
            aiResult.snapshot = filter.base64.enc(snapshot)

            -- Exit the loop once the first snapshot is found. This will be the latest one based on our sort order
            break            
         end         
      end

      trace(aiResult)
      aiResults.slides[i] = aiResult

   end   

   trace(aiResults)
   queue.push{data=json.serialize{data=aiResults,alphasort=true}}



   -- Link the snapshots with the slides. If there are more than one, use the latest

end