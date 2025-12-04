--local tz = require "date.timezoneOffset"
--require "date.dateParse"
local gc = require 'globalConfig'
local mapAccessionId = require 'mapAccessionId'
local mapBlockKey = require 'mapBlockKey'

function parseImage(image, barcode, parsedBarcode)
   
   local blockKey = mapBlockKey(parsedBarcode)
   local accessionId = mapAccessionId(parsedBarcode)
   
   local j = {} -- create blank JSON placeholder
   
   -- set message type
   j.messageType = 'upsert'
   
   -- set options
   j.options = gc.MESSAGE_OPTIONS
   
   -- Case Details
   local accessionDate = image.event.current.createdAt
   -- Not sure if we need to account for timezone offset or not. Is the updated/created date from scanner plugin in UTC
   --local offset = tz.getTimezoneOffset(accessionDate, DEFAULT_OFFSET, DST_TRANSITIONS)
   
   j.case = {}
   j.case.accessionDate = accessionDate  --:ISO8601(offset)
   j.case.accessionId = accessionId
   --j.case.assignedUserCode = msg.OBR[16][1][1]:S() -- TODO: determine how to map assignedUser (Not in scope v1)
   j.case.labSiteId = gc.LAB_SITE
   j.case.patientDob = parsedBarcode.dob
   j.case.patientLastName = parsedBarcode.lastName
   j.case.patientFirstName = parsedBarcode.firstName
   j.case.patientMrn = parsedBarcode.mrn
   j.case.patientSex = parsedBarcode.gender -- Phoenix will only send Male, Female, or Unknown
   
 
   -- Parts
   local part = parsedBarcode.part
   local block = parsedBarcode.block
   
   j.case.parts = {{}}
   j.case.parts[1].blocks = {{key=blockKey,name=block}}
   j.case.parts[1].name = part
   --j.case.parts[1].procedureCode = ''
   --j.case.parts[1].procedureName = ''
   j.case.parts[1].specimenDescription = parsedBarcode.specimen
   j.case.parts[1].specimenCode = parsedBarcode.specimen
   j.case.parts[1].specimenName = parsedBarcode.specimen
   
   -- Slide
   local slide = parsedBarcode.slide or 1
   
   j.case.parts[1].slides = {{}}
   j.case.parts[1].slides[1].barcode = barcode
   j.case.parts[1].slides[1].blockKey = blockKey
   j.case.parts[1].slides[1].name = accessionId..'-'..blockKey..'-'..slide
   j.case.parts[1].slides[1].stainCode = parsedBarcode.stain
   j.case.parts[1].slides[1].stainName = parsedBarcode.stain
   
   return j
	
   
end

return parseImage

--[[
{
    "messageType": "upsert",
    "options": {
        "deleteCaseIfNoSlidesLeft": true,
        "addSpecimenCategories": true,
        "addProcedures": true,
        "addSpecimens": true,
        "addStains": true
    },
    "case": {
        "accessionDate": "2024-07-06T10:30:00-07:00",
        "accessionId": "TST24-001",
        "labSiteId": 1,
        "patientDob": "1950-10-10",
        "patientLastName": "PROSCIA",
        "patientFirstName": "TEST",
        "patientMrn": "123456",
        "patientSex": "M",
        "patientGenderIdentity": "M",
        "specimenCategoryCode": "Breast",
        "specimenCategoryName": "Breast",
        "parts": [
            {
                "blocks": [
                    {
                        "key": "B1",
                        "name": "1"
                    }
                ],
                "name": "B",
                "procedureCode": "Biopsy",
                "procedureName": "Biopsy",
                "specimenDescription": "Left Breast Biopsy",
                "specimenCode": "Left Breast",
                "specimenName": "Left Breast",
                "slides": [
                    {
                        "barcode":"876543219",
                        "blockKey":"B1",
                        "name":"TST24-001 B1-1",
                        "stainCode":"H&E",
                        "stainName":"H&E",
                        "images": [
                           {
                               "id": 16,
                               "slideId": null
                           }
                        ]
                    }
                ],
            }
        ]
    }
}
]]