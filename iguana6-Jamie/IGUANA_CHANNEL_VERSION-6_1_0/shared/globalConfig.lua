local globalConfig = {}

-- Pattern explanation:
globalConfig.BARCODE_FORMAT = "^(%a+%d+-%d+)_(%d+)_(%d+)_(%d+)$"

-- The number of components must match the number of parenthesis pairs
globalConfig.BARCODE_COMPONENTS = {"accessionId","part","item","count"}

globalConfig.LAB_SITE = 1
globalConfig.EMAIL_DOMAIN = '@healthnetworklabs.com'

globalConfig.MESSAGE_OPTIONS = {
   addProcedures = true,
   addSpecimens = true,
   addSpecimenCategories = true, 
   addStains = true,
   assignedUserIdLookupField = 'name',
   deleteCaseIfNoSlidesLeft = true,
   archiveStatusLocked = true,
   logLevels = {
      parseBarcode = 'logInfo',
      imageSlideMatch = 'logInfo',
      caseUpdate = 'logInfo'
      }
}

-- TIMEZONE OFFSET
local defaultOffset = '-05:00'
local dstOffset = '-04:00'
globalConfig.DEFAULT_OFFSET = defaultOffset
globalConfig.DST_TRANSITIONS = {
   {year=2021, month=11, day=7, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2023, month=3, day=12, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2023, month=11, day=5, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2024, month=3, day=10, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2024, month=11, day=3, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2025, month=3, day=9, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2025, month=11, day=2, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2026, month=3, day=8, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2026, month=11, day=1, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2027, month=3, day=14, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2027, month=11, day=7, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2028, month=3, day=12, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2028, month=11, day=5, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2029, month=3, day=11, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2029, month=11, day=4, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2030, month=3, day=10, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2030, month=11, day=3, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2031, month=3, day=9, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2031, month=11, day=2, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2032, month=3, day=14, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2032, month=11, day=7, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2033, month=3, day=13, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2033, month=11, day=6, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2034, month=3, day=12, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2034, month=11, day=5, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2035, month=3, day=11, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2035, month=11, day=4, hour=2, min=0, sec=0, offset=defaultOffset}
}

-- Convert transition dates to timestamps
for i, v in ipairs(globalConfig.DST_TRANSITIONS) do
   v.timestamp = os.time(v)
end

-- WEBHOOK IDS TO BE CHECKED
globalConfig.WEBHOOK_REQUEST_IDS = {1, 2, 36, 69}
globalConfig.WEBHOOK_REQUEST_START_DATE = '2024-09-17T00:00:00Z'

globalConfig.ALERTS = {
   PASSWORD = os.getenv('PW'),
   USERNAME = 'admin',
   IGUANA_URL = 'https://10.128.9.6:6543/status',
   LIVE = true,
   EXCEPTIONS = {
      'zChannel Restart v2',
      'zHNL-P2-inbound pass thru',
      'zHNL-P3-HL7 to tables',
      'zHNL-P4-push  A B C CDU STAT',
      'zHNL-P5A-inbound pass thru A',
      'zHNL-P5B-inbound pass thru B',
      'zHNL-P5C-inbound pass thru C',
      'zHNL-P5S-inbound pthru S',
      'zHNL-P6A-HL7 to caseDetails',
      'zHNL-P6B-HL7 to caseDetails',
      'zHNL-P6C-HL7 to caseDetails',
      'zHNL-P6S-caseDetails STAT',
      'zHNL-P7A-HL7 to caseParts',
      'zHNL-P7B-HL7 to caseParts',
      'zHNL-P7C-HL7 to caseParts',
      'zHNL-P7S-caseParts STAT',
      'zHNL-P8A-HL7 postSlide',
      'zHNL-P8B-HL7 postSlide',
      'zHNL-P8C-HL7 postSlide',
      'zHNL-P8S-postSlide STAT',
      'zHNL-P9-caseDetails update',
      'zHNL-P10-**END OF HL7 INBOUND*',
      'zHNL-P13-patchImage w slide',
      'zHNL-P15-patchImage wh pthru',
      'zHNL-P16- moveCase',
      'zHNL-P17-outbound import notif',
      'zHNL-P18-delete slide webhook',
      'zHNL-P19-delete slide wh pthru',
      'zHNL-P20-patch part block',
      'zHNL-P24-SFTP translator',
      'zHNL-P25-assignmentUpdates FTP',
      'zHNL-P27-caseDetail update pth',
      'zHNL-P28- caseDetail WH parse',
      'zHNL-P29-outbound HL7 archived',
      'zHNL-P31-Iguana Monitor',
      'zHNL-P32-channel restart',
      'zHNL-PZ1 WH DOWNTIME RESEND',
      'zHNL-PZ2-AUTO RESENDtoAP'
   },
   REQUESTER = 'proscia_alerts@hnl.com',
   CLIENT_NAME = 'HNL',
   URL = 'https://hooks.zapier.com/hooks/catch/18692772/2mdtbtr/'
}

return globalConfig