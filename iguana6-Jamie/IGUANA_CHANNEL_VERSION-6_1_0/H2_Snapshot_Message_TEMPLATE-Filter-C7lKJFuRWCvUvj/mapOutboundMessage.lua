local processTimestamp = require 'date.processTimestamp'

function mapOutboundMessage(attachment, caseDetail, slide, base64)
   
   local out = hl7.message{vmd="NEW_OML_0621_v2.vmd",name="OML"}
   
   local timestampLocalFormatted = processTimestamp(attachment.event.timestamp)

   out.MSH[3][1]      = 'ConcentriqDx'
   out.MSH[4][1]      = 'Proscia'
   out.MSH[5][1]      = 'ProgrammerFabrik'
   out.MSH[6][1]      = 'LIS'
   out.MSH[7][1]         = os.date('%Y%m%d%H%M%S')  -- Current timestamp
   out.MSH[9][1]      = 'OML'
   out.MSH[9][2]      = '021'
   out.MSH[10]        = timestampLocalFormatted
   out.MSH[11][1]     = "D"
   out.MSH[12][1]     = "2.5.1" -- Confirm HL7 version of VMD file
   
   out.ORC[2][1]      = caseDetail.accessionId  -- Adjust as needed
   out.ORC[5]         = 'IP'

   out.OBR[2][1]      = caseDetail.accessionId  -- Adjust as needed
   out.OBR[3][2]      = 'https://dx-concentriq.vlkh.net/case/viewer/'..caseDetail.id..'/'..slide.id..'?lis=1'
   out.OBR[4][1]      = 'ImportNotification'

   -- Include the Base64-encoded image in the OBX segment as text
   out.OBX[1][1]   = '1'                   -- Set ID
   out.OBX[1][2]      = 'TX'                  -- Data type as Text
   out.OBX[1][3][1]   = slide.barcode               -- Observation Identifier
   out.OBX[1][3][2]   = 'Snapshot'     -- Observation Identifier text
   out.OBX[1][5][1]      = base64    
   
   return out
end   

return mapOutboundMessage