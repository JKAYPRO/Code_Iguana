local api = require 'concentriqAPI'

function mapOutboundMessage(slide)
   
   -- Build HL7
   local oru = hl7.message{vmd='Powerpath_ORU_R01.vmd',name='ORU'}
   -- MSH
   oru.MSH[3][1] = 'PROSCIA'
   oru.MSH[4][1] = 'CONCENTRIQAP'
   oru.MSH[5][1] = 'POWERPATH'
   oru.MSH[6][1] = 'CELLNETIX'
   oru.MSH[7] = os.date('%Y%m%d%H%M%S',os.time())
   oru.MSH[9][1] = 'ORU'
   oru.MSH[9][2] = 'R01'
   oru.MSH[10] = oru.MSH[7] .. '-'..slide.event.previous.id
   oru.MSH[11][1] = 'P'
   oru.MSH[12][1] = '2.4'

	-- OBR
   oru.OBR[1] = 1
   oru.OBR[2][1] = slide.event.previous.barcode
   oru.OBR[3][1] = slide.event.previous.barcode
   oru.OBR[4][1] = 'CONCENTRIQ'

   -- ZID
   oru.ZID[1] = 1
   oru.ZID[2][1] = slide.event.previous.id
   oru.ZID[3] = 'D'
   oru.ZID[4] = contextualLaunchUrl   

   return oru
end

return mapOutboundMessage