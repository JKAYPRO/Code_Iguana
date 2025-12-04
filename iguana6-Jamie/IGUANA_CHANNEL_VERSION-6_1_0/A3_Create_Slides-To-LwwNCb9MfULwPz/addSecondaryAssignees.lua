local api = require 'concentriqAPI'

function addSecondaryAssignees(msg, caseDetails)
   if msg.case.secondaryAssignedUserCodes then
      local secondaryAssignees = {}
      for _, assignedUserCode in ipairs(msg.case.secondaryAssignedUserCodes) do
         local secondaryUser = api.getUserId(assignedUserCode, msg.options.assignedUserIdLookupField)
         if secondaryUser then
            table.insert(secondaryAssignees, secondaryUser.id)
         end
      end
      if #secondaryAssignees > 0 then
         local secondaryAssigneesBody = {
            caseDetailId = caseDetails.id,
            secondaryAssignees = secondaryAssignees
         }
         local secondaryAssigneePost = api.postSecondaryAssignee(secondaryAssigneesBody)
      end
   end

   return secondaryAssigneePost
end

return addSecondaryAssignees