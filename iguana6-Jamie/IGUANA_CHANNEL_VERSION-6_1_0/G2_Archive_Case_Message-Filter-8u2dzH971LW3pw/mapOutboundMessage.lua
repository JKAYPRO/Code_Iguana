local api = require 'concentriqAPI'
local processTimestamp = require 'date.processTimestamp'

function mapOutboundMessage(caseDetail, slide, image)
   -- Set URL
   local contextualLaunchUrl = 'https://dev-dx.hnl.com/case/viewer/'..slide.caseDetailId..'/'..slide.id..'?lis=1'
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
   local accessionDateLocalFormatted = processTimestamp(caseDetail.event.current.accessionDate)

   -- Image Created Date
   local createdAtLocalFormatted = processTimestamp(image.createdAt)

   -- Event timestamp
   local timestampLocalFormatted = processTimestamp(caseDetail.event.timestamp)

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

   oru.PID[3][1][1]     = caseDetail.event.current.patientMrn
   oru.PID[5][1][1][1]  = caseDetail.event.current.patientLastName
   oru.PID[5][1][2]     = caseDetail.event.current.patientFirstName


   oru.ORC[1]           = 'RE'
   oru.ORC[2][1]        = caseDetail.event.current.accessionId
   oru.ORC[9][1]        = accessionDateLocalFormatted


   oru.OBR[2][1]        = caseDetail.event.current.accessionId 
   oru.OBR[3][1]        = slide.barcode


   oru.OBX[1][1][1]   = '1'
   oru.OBX[1][2]      = 'CE'


   oru.OBX[1][3][1]   = caseDetail.event.current.accessionId ..'&'.. slide.barcode ..'&ATT' --need to make sure that ampersand is not escaped

   oru.OBX[1][4]       = '1' --slide ID here for now
   oru.OBX[1][5][1]   = contextualLaunchUrl ..'&'.. slide.barcode ..'_Image '.. image.id ..'&'.. caseDetail.event.current.id ..'/'.. slide.id ..'&Gross'
   oru.OBX[1][14]     = createdAtLocalFormatted 

   return oru
end

return mapOutboundMessage