local gc = require 'globalConfig'
local tzOffset = require 'date.getTimezoneOffset'
local bu = require 'barcodeUtils'
local mapBlockKey = require 'mapBlockKey'
hl7.unescape = require 'hl7.delimiter.unescape'
require 'date.parse'

function parseORU(msg)
   -- Extract and parse the barcode
   -- Replace _ with ^ to match the barcode. "^" not used in the HL7 since that is a reserved character
   local j = {} -- create blank JSON placeholder
   
   -- set message type
   j.messageType = 'caseUpdate'
   
   -- set options
   j.options = gc.MESSAGE_OPTIONS
   
   -- Case Details
   local accessionDate = msg.SAC[7]:S()
   local offset = tzOffset(accessionDate:TIME(), gc.DEFAULT_OFFSET, gc.DST_TRANSITIONS)   
   
   j.case = {}
   j.case.accessionDate = accessionDate:ISO8601(offset)
   j.case.accessionId = msg.ORC[2][1]:S()
   --j.case.assignedUserCode = msg.OBR[16][1][1]:S() -- TODO: determine how to map assignedUser (Not in scope v1)
   j.case.caseStage = 'diagnosisProvided'
   j.case.labSiteId = gc.LAB_SITE
   j.case.patientDob = msg.PID[7]:S():sub(1,8):DAY('yyyymmdd')
   j.case.patientLastName = msg.PID[5][1][1]:S()
   j.case.patientFirstName = msg.PID[5][1][2]:S()
   j.case.patientMrn = msg.PID[3][1][1]:S()
   j.case.patientSex = msg.PID[8][1]:S():sub(1, 1):upper() -- Phoenix will only send Male, Female, or Unknown
   j.case.patientGenderIdentity = j.case.patientSex
   
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

   return j
end

return parseORU
