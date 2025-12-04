local gc = require 'globalConfig'
local tzOffset = require 'date.getTimezoneOffset'
local bu = require 'barcodeUtils'
local mapBlockKey = require 'mapBlockKey'
hl7.unescape = require 'hl7.delimiter.unescape'
require 'date.parse'

function parseOML(msg)
   -- Check order control early
   local orderControl = msg.ORC[1]:S()

   -- Get accession date from ORC.15
   local accDateStr = msg.ORC[15]:S()
   local accDate = accDateStr ~= "" and accDateStr or os.date('%Y%m%d%H%M%S')
   local offset = tzOffset(accDate:TIME(), gc.DEFAULT_OFFSET, gc.DST_TRANSITIONS)

   -- Get accession ID from OBR.18
   local accessionId = msg.OBR[18]:S()

   -- Handle XO (change/update order) - these update existing cases without creating slides
   if orderControl == "XO" then
      iguana.logInfo('Processing XO (update) order for: ' .. accessionId)

      local j = {}
      j.messageType = 'caseUpdate'
      j.options = gc.MESSAGE_OPTIONS

      j.case = {}
      j.case.accessionId = accessionId
      j.case.accessionDate = accDate:ISO8601(offset)
      j.case.labSiteId = gc.LAB_SITE

      -- Patient demographics with safe extraction
      local dobRaw = msg.PID[7]:S()
      if dobRaw ~= "" and #dobRaw >= 8 then
         j.case.patientDob = dobRaw:sub(1,8):DAY('yyyymmdd')
      end

      local lastName = msg.PID[5][1][1]:S()
      if lastName ~= "" then
         j.case.patientLastName = lastName
      end

      local firstName = msg.PID[5][1][2]:S()
      if firstName ~= "" then
         j.case.patientFirstName = firstName
      end

      local mrn = msg.PID[3][1][1]:S()
      if mrn ~= "" then
         j.case.patientMrn = mrn
      end

      local sexRaw = msg.PID[8][1]:S()
      if sexRaw ~= "" then
         j.case.patientSex = sexRaw:sub(1, 1)
         j.case.patientGenderIdentity = j.case.patientSex
      end

      return j
   end

   -- For NW (new order) messages, SPM segment is required
   if orderControl == "NW" then
      if not msg.SPM or not msg.SPM[1] or not msg.SPM[1][2] or msg.SPM[1][2]:S() == "" then
         iguana.logInfo('Skipping NW order without barcode/SPM segment: ' .. accessionId)
         return nil
      end
   end

   -- Check if SPM segment exists for slide processing
   if not msg.SPM or not msg.SPM[1] or not msg.SPM[1][2] then
      iguana.logInfo('No SPM segment found, skipping slide processing: ' .. accessionId .. ' (Order Control: ' .. orderControl .. ')')
      return nil
   end

   -- Get slide ID from SPM.2 (format: "A70-25;6")
   local slideId = msg.SPM[1][2]:S()

   if slideId == "" then
      iguana.logInfo('Empty SPM.2, skipping slide processing: ' .. accessionId .. ' (Order Control: ' .. orderControl .. ')')
      return nil
   end

   -- Extract part and block from SPM.4
   local blockName = msg.SPM[1][4][1]:S()  -- SPM.4.1 = "C"
   local partName = msg.SPM[1][4][4]:S()   -- SPM.4.4 = "3"

   -- Set defaults if empty
   blockName = blockName ~= "" and blockName or "A"
   partName = partName ~= "" and partName or "1"

   -- Parse the slide ID using barcodeUtils
   local parsedBarcode = bu.parseBarcode(slideId, gc.BARCODE_FORMAT, gc.BARCODE_COMPONENTS)

   -- Validate parsed barcode
   if not parsedBarcode or not parsedBarcode.accessionId or not parsedBarcode.slide then
      iguana.logError('Failed to parse barcode: ' .. slideId .. ' (Order Control: ' .. orderControl .. ')')
      return nil
   end

   -- Construct blockKey as part-block (e.g., "3-C")
   local blockKey = partName .. '-' .. blockName

   -- Construct barcode: accessionId-blockKey-slide (e.g., "A70-25-3-C-6")
   local barcode = parsedBarcode.accessionId .. '-' .. blockKey .. '-' .. parsedBarcode.slide

   -- Handle order control for cancellations
   if orderControl == "CA" then
      return {
         messageType = 'cancel',
         options = {
            push = true,
            delete = true,
            preventDeletionOfSlidesWithImages = true,
            logLevel = 'logInfo'
         },
         case = {
            accessionId = accessionId,
            labSiteId = gc.LAB_SITE,
            cancellationDate = accDate:ISO8601(offset),
            cancellationReason = "Order cancelled",
            parts = {{
               slides = {{ barcode = barcode }}
            }}
         }
      }
   end

   local j = {} -- create blank JSON placeholder

   -- set message type
   j.messageType = 'upsert'

   -- set options
   j.options = gc.MESSAGE_OPTIONS

   -- Case Details
   j.case = {}
   j.case.accessionDate = accDate:ISO8601(offset)
   j.case.accessionId = accessionId
   j.case.labSiteId = gc.LAB_SITE

   -- Patient demographics with safe extraction
   local dobRaw = msg.PID[7]:S()
   if dobRaw ~= "" and #dobRaw >= 8 then
      j.case.patientDob = dobRaw:sub(1,8):DAY('yyyymmdd')
   end

   local lastName = msg.PID[5][1][1]:S()
   if lastName ~= "" then
      j.case.patientLastName = lastName
   end

   local firstName = msg.PID[5][1][2]:S()
   if firstName ~= "" then
      j.case.patientFirstName = firstName
   end

   local mrn = msg.PID[3][1][1]:S()
   if mrn ~= "" then
      j.case.patientMrn = mrn
   end

   local sexRaw = msg.PID[8][1]:S()
   if sexRaw ~= "" then
      j.case.patientSex = sexRaw:sub(1, 1)
      j.case.patientGenderIdentity = j.case.patientSex
   end

   -- UDFs
   -- Check if NTE segments exist
   if msg.NTE then
      for i = 1, #msg.NTE do
         if msg.NTE[i][2]:S() == 'Diagnosis' then
            j.case.udf = {}
            j.case.udf.diagnosis = hl7.unescape(msg.NTE[i][3][1]:S())
            break
         end
      end
   end

   -- Get description from OBR.21
   local description = msg.OBR[21]:S()

   -- Get stain from SPM.6
   local stainCode = msg.SPM[1][6]:S()
   local stainName = stainCode

   -- Convert HE to H&E if needed
   if stainCode == "HE" then
      stainName = "H&E"
   end

   -- Parts
   j.case.parts = {{}}
   j.case.parts[1].blocks = {{key=blockKey, name=blockName}}
   j.case.parts[1].name = partName
   j.case.parts[1].specimenDescription = description ~= "" and description or nil
   j.case.parts[1].specimenCode = blockName
   j.case.parts[1].specimenName = blockName

   -- Slide
   j.case.parts[1].slides = {{}}
   j.case.parts[1].slides[1].barcode = barcode
   j.case.parts[1].slides[1].blockKey = blockKey
   j.case.parts[1].slides[1].name = parsedBarcode.accessionId..'-'..blockKey..'-'..parsedBarcode.slide
   j.case.parts[1].slides[1].stainCode = stainName
   j.case.parts[1].slides[1].stainName = stainName

   return j
end

return parseOML
