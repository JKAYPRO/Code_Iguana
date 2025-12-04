local api = require 'concentriqAPI'
local processTimestamp = require 'date.processTimestamp'

function mapOutboundMessage(caseDetails, slides, image)
   -- Set URL
   local contextualLaunchUrl = 'https://dx.hnl.com/case/viewer/'..slides.caseDetailId..'/'..slides.id..'?lis=1'
   trace(contextualLaunchUrl)   

   -- Get Thumbnail Image
   --local resourceType = 'Image'
   --local resourceId = image.event.current.id
   --local storageKey = image.event.current.thumbnailImage
   --local thumbnailImage = api.getFile(resourceType,resourceId,storageKey)

   -- Get timestamp
   local timestamp = os.date('%Y%m%d%H%M%S',os.time())
   local milliseconds = math.floor((os.clock() % 1) * 1000000)


   --Convert timestamps from UTC to local time
   -- Accession Date
   local accessionDateLocalFormatted = processTimestamp(caseDetails.accessionDate)

   -- Image Created Date
   local createdAtLocalFormatted = processTimestamp(image.event.current.createdAt)

   -- Event timestamp
   local timestampLocalFormatted = processTimestamp(image.event.timestamp)

   -- Build HL7
   local oru = hl7.message{vmd='HNL_wZID_02282024_V3.vmd',name='OML'}

   oru.MSH[3][1]        = 'PROSCIA'
   oru.MSH[5][1]        = 'COPATHPLUS'
   oru.MSH[6][1]        = 'HNL'
   oru.MSH[7]           = timestampLocalFormatted
   oru.MSH[9][1]        = 'ORU'
   oru.MSH[9][2]        = 'R01'
   oru.MSH[10]          = timestampLocalFormatted
   oru.MSH[11][1]       = 'P'
   oru.MSH[12][1]       = '2.3' --confirm hl7 version of vmd file

   oru.PID[3][1][1]     = caseDetails.patientMrn
   oru.PID[5][1][1][1]  = caseDetails.patientLastName
   oru.PID[5][1][2]     = caseDetails.patientFirstName


   oru.ORC[1]           = 'RE'
   oru.ORC[2][1]        = caseDetails.accessionId
   oru.ORC[9][1]        = accessionDateLocalFormatted


   oru.OBR[2][1]        = caseDetails.accessionId 
   oru.OBR[3][1]        = slides.barcode


   oru.OBX[1][1][1]   = '1'
   oru.OBX[1][2]      = 'CE'


   oru.OBX[1][3][1]   = caseDetails.accessionId ..'&'.. slides.barcode ..'&ATT' --need to make sure that ampersand is not escaped

   oru.OBX[1][4]       = '1' --slide ID here for now
   oru.OBX[1][5][1]   = contextualLaunchUrl ..'&'.. slides.barcode ..'_Image '.. image.event.current.id ..'&'.. caseDetails.id ..'/'.. slides.id ..'&Microscopic'
   oru.OBX[1][14]     = createdAtLocalFormatted 
   --[[
   -- MSH
   oru.MSH[3][1] = 'PROSCIA'
   oru.MSH[4][1] = 'CONCENTRIQAP'
   oru.MSH[5][1] = 'POWERPATH'
   oru.MSH[6][1] = 'CELLNETIX'
   oru.MSH[7] = os.date('%Y%m%d%H%M%S',os.time())
   oru.MSH[9][1] = 'ORU'
   oru.MSH[9][2] = 'R01'
   oru.MSH[10] = oru.MSH[7] .. '-'..slides.id
   oru.MSH[11][1] = 'P'
   oru.MSH[12][1] = '2.4'

   -- OBR
   oru.OBR[1] = 1
   oru.OBR[2][1] = slides.barcode
   oru.OBR[3][1] = slides.barcode
   oru.OBR[4][1] = 'CONCENTRIQ'

   -- ZID
   oru.ZID[1] = 1
   oru.ZID[2][1] = slides.id
   oru.ZID[3] = 'A'
   oru.ZID[4] = contextualLaunchUrl
   oru.ZID[5] = slides.name
   oru.ZID[7] = image.event.current.createdAt:gsub("[^%w]", ""):gsub("[TZ]", ""):sub(1,14)
   oru.ZID[8] = image.event.current.status
   oru.ZID[22] = image.event.current.objectivePower .. 'x'
   oru.ZID[23] = filter.base64.enc(thumbnailImage)
   ]]

   return oru
end

return mapOutboundMessage