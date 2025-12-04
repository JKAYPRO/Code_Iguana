local api = require 'concentriqAPI'

function mapCaseDetails(msg)
   local body = {}
   body.accessionDate = msg.case.accessionDate
   body.accessionId = msg.case.accessionId
   body.caseStage = msg.case.caseStage
   body.isStat = msg.case.isStat
   body.labSiteId = msg.case.labSiteId
   body.patientDob = msg.case.patientDob
   body.patientLastName = msg.case.patientLastName
   body.patientFirstName = msg.case.patientFirstName
   body.patientMiddleName = msg.case.patientMiddleName
   body.patientMrn = msg.case.patientMrn
   body.patientSex = msg.case.patientSex
   body.patientGenderIdentity = msg.case.patientGenderIdentity

   -- Case Assignment
   local assignedUserCode = msg.case.assignedUserCode
   
   if assignedUserCode then
      local assignedUserQuery = json.serialize{data={eager={["$where"]={[msg.options.assignedUserIdLookupField]=assignedUserCode}}}}
      local users = api.getUsers(assignedUserQuery)
      if not users then
         body.assignedUserId = nil
         iguana.logWarning('User not found where '..msg.options.assignedUserIdLookupField..' = '..assignedUserCode)
      else
         body.assignedUserId = users.id    
      end
   end   
   
   local pathologist = msg.case.assignedUserId
   body.assignedUserId = nil
   
   --Specimen Category
   local specimenCategoryCode = msg.case.specimenCategoryCode
   local specimenCategoryName = msg.case.specimenCategoryName
   
   if specimenCategoryCode then
      local specimenCategoryQuery = json.serialize{data={eager={["$where"]={code=specimenCategoryCode}}}}
      local specimenCategories = api.getSpecimenCategories(specimenCategoryQuery)
      if not specimenCategories then
         if msg.options.addSpecimenCategories == true then
            local specimenCategoriesBody = {}
            specimenCategoriesBody.code = specimenCategoryCode
            specimenCategoriesBody.name = specimenCategoryName
            specimenCategories = api.postSpecimenCategories(specimenCategoriesBody)
         else
            iguana.logError('Specimen Category does not exist: '..specimenCategoryCode..'^'..specimenCategoryName)
            return
         end
      end
      body.specimenCategoryId = specimenCategories.id   
   end  
   
   -- UDF
   body.udf = msg.case.udf   

   return body    

end

return mapCaseDetails