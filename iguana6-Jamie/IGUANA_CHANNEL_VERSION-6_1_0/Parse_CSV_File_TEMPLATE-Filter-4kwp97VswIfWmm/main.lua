-- This example shows parsing of a CSV file.

-- http://help.interfaceware.com/v6/csv-parser

local parseCsv = require 'parseCsv'

function main(Data)
   local csv = parseCsv({data=Data,headers={"Case","Responisble Pathologist Login ID","Specimen Type","Subspecialty","Discrete Diagnosis","Is Case Completed?"},rowDelimiter='\r'})  
   trace('Count of rows = '..#csv)
   
   queue.push{data=json.serialize{data=csv}}
end