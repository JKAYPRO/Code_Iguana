-- Import required modules
local retry = require 'retry'
local tu = require 'tableUtils'

-- Configuration variables from environment
local BASE_URL = os.getenv('CONCENTRIQ_API_URL')
local LIVE_GET = true
local LIVE_UPDATE = true
local TIMEOUT = 10
local RETRY = 10
local PAUSE = 1
local HEADERS = {['Content-Type']='application/json',['concentriq-api-key']=os.getenv('CONCENTRIQ_API_KEY')}


-- Table to hold all API related functions
local concentriqAPI = {}

-- Function to check the HTTP response status
local function checkHttpResponse(code, headers)
   -- Special handling when updates are not live
   if not LIVE_UPDATE then
      return true, 'Success - Testing'
   end

   -- Check if the response code is within successful range
   if code >= 200 and code < 400 then
      return true, 'Success'
   else
      -- Handle errors by extracting message from headers or default to "Unknown error"
      local error_message = headers.Response or "Unknown error"
      return false, 'Error: ' .. error_message
   end
end

-- Function to URL-encode parameters
local function urlEncode(str)
   if str then
      str = string.gsub(str, "([^%w _%-%.~])", function(c)
            return string.format("%%%02X", string.byte(c))
         end)
      str = string.gsub(str, " ", "+")
   end
   return str
end

-- Function to make HTTP requests
function concentriqAPI.httpRequest(params)
   -- Default parameters for the HTTP request
   local defaults = {
      method = "GET",
   endpoint = "",
      parameters = nil,
      body = nil,
      id = nil,
      headers = HEADERS,
      timeout = TIMEOUT,
      live = (params.method == "GET") and LIVE_GET or LIVE_UPDATE,
      retry = RETRY,
      pause = PAUSE
   }   

   -- Merge user-provided parameters with defaults
   for k, v in pairs(defaults) do
      trace(k)
      trace(params[k])
      if params[k] == nil then
         params[k] = v
      end
   end

   -- Construct the full URL for the request
   local url = BASE_URL .. params.endpoint
   if params.id then
      url = url .. '/' .. params.id
   end

   -- Prepare the request object
   local request = {
      url = url,
      headers = params.headers,
      timeout = params.timeout,
      parameters = params.parameters,
      live = params.live
   }

   -- Adjust the request body or data based on the HTTP method
   if params.body then
      if params.method == "POST" then
         request.body = json.serialize{data=params.body}
      elseif params.method == "PATCH" then
         request.data = json.serialize{data=params.body}
      end
   end

   iguana.stopOnError(true) 
   -- Make the HTTP request with retry logic
   local response, responseCode, responseHeaders = retry.call{
      func = net.http[params.method:lower()],
      arg1 = request,
      retry = params.retry,
      pause = params.pause,
      funcname = 'concentriqAPI.' .. params.method .. params.endpoint
   }

   -- Ignore when testing without LIVE_UPDATE = true
   if not responseHeaders == nil then
      iguana.logInfo(params.method..' '..params.endpoint..'\n'..responseHeaders.Response..'\n\nREQUEST:\n'..json.serialize{data=request}..'\n\nRESPONSE:\n'..response)
   end

   -- Check the HTTP response and log error if not successful
   local httpSuccessful, httpMessage = checkHttpResponse(responseCode, responseHeaders)
   if not httpSuccessful then
      iguana.logError(httpMessage)
      return
   end

   -- Exception for endpoints that don't return JSON
   if params.endpoint == 'files/download/redirect' or params.endpoint == 'runSlideAnalyses' then
      return response
   else   -- Parse the JSON response and return
      if response == '' then
         return response
         --return json.parse{data='{"test":"testing"}'}
      else
         return json.parse{data=response}
      end
   end
end

-- Additional functions for handling specific API endpoints like 'caseDetails', 'caseParts', etc.
-- These functions utilize `httpRequest` to interact with specific endpoints and handle the data accordingly.

-- CASE DETAILS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getCaseDetails(query)
   local caseDetails = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'caseDetails',
         parameters={
            filter=query
         }         
      })

   if tu.isEmpty(caseDetails.items) then
      return nil
   end


   return caseDetails.items[1]
end

function concentriqAPI.getCaseDetailsAll(query)
   local caseDetails = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'caseDetails',
         parameters={
            filter=query
         }         
      })

   if tu.isEmpty(caseDetails.items) then
      return nil
   end


   return caseDetails.items
end

function concentriqAPI.getCaseDetail(id, query)
   local caseDetail = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'caseDetails',
         id = id,
         parameters={
            filter=query
         }
      })

   return caseDetail
end

function concentriqAPI.postCaseDetails(body)
   local caseDetails = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'caseDetails',
         body = body
      })

   return caseDetails
end

function concentriqAPI.patchCaseDetails(id, body)
   local caseDetails = concentriqAPI.httpRequest({
         method = 'PATCH',
      endpoint = 'caseDetails',
         id = id,
         body = body
      })

   return caseDetails
end

function concentriqAPI.deleteCaseDetails(id)
   local caseDetails = concentriqAPI.httpRequest({
         method = 'DELETE',
      endpoint = 'caseDetails',
         id = id
      })

   return caseDetails
end

function concentriqAPI.postCaseDetailAttachment(id, body)
   local attachment = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'caseDetails/' .. id .. '/attachments',
         body = body
      })

   return attachment   
end

-- CASE PARTS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getCaseParts(query)
   local caseParts = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'caseParts',
         parameters={
            filter=query
         }
      })
   if tu.isEmpty(caseParts.items) then
      return nil
   end

   -- return the single caseParts object to match the POST return
   return caseParts.items[1]
end

function concentriqAPI.getCasePartsAll(query)
   local caseParts = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'caseParts',
         parameters={
            filter=query
         }
      })

   return caseParts
end

function concentriqAPI.postCaseParts(body)
   local caseParts = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'caseParts',
         body = body
      })

   return caseParts
end

function concentriqAPI.patchCaseParts(id, body)
   local caseParts = concentriqAPI.httpRequest({
         method = 'PATCH',
      endpoint = 'caseParts',
         id = id,
         body = body
      })

   return caseParts
end

function concentriqAPI.deleteCaseParts(id)
   local caseParts = concentriqAPI.httpRequest({
         method = 'DELETE',
      endpoint = 'caseParts',
         id = id
      })

   return caseParts
end

-- Check if the provided key already exists in the blocks for this part
function concentriqAPI.checkBlockExists(caseParts, key)
   local keyExists = false

   -- Check if block is a table and isn't empty
   if tu.isNotTableOrEmpty(caseParts.blocks) then
      return keyExists
   end

   -- Check if the block already exists using the helper function
   if tu.itemExists(caseParts.blocks, 'key', key) then
      keyExists = true
   end

   return keyExists
end

-- SLIDES
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getSlides(query)
   local slides = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'slides',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(slides.items) then
      return nil
   end

   -- return the single slide object to match the POST return
   return slides.items[1]
end

function concentriqAPI.getSlidesAll(query)
   local slides = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'slides',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(slides.items) then
      return nil
   end

   -- return the single slide object to match the POST return
   return slides.items
end

function concentriqAPI.getSlide(id,query)
   local slide = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'slides',
         id = id,
         parameters = query and { filter = query } or nil
      })

   return slide
end

function concentriqAPI.postSlides(body)
   local slides = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'slides',
         body = body
      })

   return slides
end

function concentriqAPI.patchSlides(id, body)
   local slides = concentriqAPI.httpRequest({
         method = 'PATCH',
      endpoint = 'slides',
         id = id,
         body = body
      })

   return slides
end

function concentriqAPI.deleteSlides(id)
   local slides = concentriqAPI.httpRequest({
         method = 'DELETE',
      endpoint = 'slides',
         id = id
      })

   return slides
end

-- Query all slides without images accounting for slides that will never receive images.
function concentriqAPI.slidesWithoutImageQuery(caseDetailId)
   local slidesWithoutImageQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = {
               caseDetailId = caseDetailId,
               ["$and"] = {
                  {["udf$noImageScanned"] = {["$exists"] = false}},
                  {
                     ["$or"] = {
                        {primaryImageId = {["$exists"] = false}},
                        {orderStatus = {["$exists"] = true}} 
                     }
                  }
               }
            }
         }
      }
   }
   local slidesWithoutImage = concentriqAPI.getSlidesAll(slidesWithoutImageQuery)
   return slidesWithoutImage
end   

function concentriqAPI.caseStatus(caseDetailId, archiveStatusLocked, currentStatus, totalExpectedSlides)
   -- Normalize totalExpectedSlides into an integer if provided
   if totalExpectedSlides ~= nil then
      totalExpectedSlides = tonumber(totalExpectedSlides)
   end

   -- If currentStatus is not provided, fetch it from the case details
   if not currentStatus then
      local caseDetails = concentriqAPI.getCaseDetail(caseDetailId)
      currentStatus = caseDetails.caseStage
   end

   -- If archived and locked, don't change status
   if currentStatus == 'archived' and archiveStatusLocked == true then
      iguana.logInfo('Case is archived and archiveStatusLocked is set to true. Skipping status update.')
      return currentStatus
   end

   -- Query: slides missing images 
   local slidesWithoutImage = concentriqAPI.slidesWithoutImageQuery(caseDetailId)
   local countWithout = (slidesWithoutImage and #slidesWithoutImage) or 0

   -- Query: all slides on the case
   local allSlidesQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = {
               caseDetailId = caseDetailId,
               ["udf$noImageScanned"] = { ["$exists"] = false }
            }
         }
      }
   }
   local allSlides = concentriqAPI.getSlidesAll(allSlidesQuery) or {}
   local totalSlides = #allSlides

   local status
   if totalExpectedSlides ~= nil then
      if totalSlides == totalExpectedSlides then
         if countWithout > 0 then
            iguana.logError('All slides are present, but are missing images. Please investigate: ' ..caseDetailId)
            status = 'pending'
         else
            status = 'ready'
         end
      elseif totalSlides < totalExpectedSlides then
         status = 'pending'
      elseif totalSlides > totalExpectedSlides then
         status = 'ready'
         iguana.logError('There are more slides than expected on this case. Please investigate: ' ..caseDetailId)
      else
         status = 'pending'
      end
   else
      if countWithout == 0 then
         status = 'ready'
      elseif totalSlides > 0 and countWithout == totalSlides then
         status = 'building'
      else
         status = 'pending'
      end
   end

   trace({ totalSlides = totalSlides, withoutImages = countWithout, totalExpectedSlides = totalExpectedSlides, resolvedStatus = status })

   return status
end


-- IMAGES
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getImages(query)
   local images = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'images',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(images.items) then
      return nil
   end

   -- return the single image object to match the POST return
   return images.items[1]
end

function concentriqAPI.getImagesAll(query)
   local images = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'images',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(images.items) then
      return nil
   end

   return images.items
end

function concentriqAPI.patchImages(id, body)
   local images = concentriqAPI.httpRequest({
         method = 'PATCH',
      endpoint = 'images',
         id = id,
         body = body
      })

   return images
end

function concentriqAPI.getImageToken(id)
   local imageToken = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'images/'..id..'/token'   
      })

   return imageToken
end

function concentriqAPI.deleteImage(id)
   local slides = concentriqAPI.httpRequest({
         method = 'DELETE',
      endpoint = 'images',
         id = id
      })

   return images
end

-- STAINS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getStains(query)
   local stains = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'stains',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(stains.items) then
      return nil
   end

   -- return the single stain object to match the POST return
   return stains.items[1]
end

function concentriqAPI.getStain(id)
   local stain = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'stains',
         id = id
      })

   -- return the slide
   return stain
end

function concentriqAPI.postStains(body)
   local stains = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'stains',
         body = body
      })

   return stains
end

-- PROCEDURES
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getProcedures(query)
   local procedures = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'procedures',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(procedures.items) then
      return nil
   end

   -- return the single procedures object to match the POST return
   return procedures.items[1]
end

function concentriqAPI.postProcedures(body)
   local procedures = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'procedures',
         body = body
      })

   return procedures
end

-- SPECIMENS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getSpecimens(query)
   local specimens = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'specimens',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(specimens.items) then
      return nil
   end

   -- return the single specimen object to match the POST return
   return specimens.items[1]
end

function concentriqAPI.postSpecimens(body)
   local specimens = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'specimens',
         body = body
      })

   return specimens
end

-- SPECIMEN CATEGORY
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getSpecimenCategories(query)
   local specimenCategories = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'specimenCategories',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(specimenCategories.items) then
      return nil
   end

   -- return the single specimen category object to match the POST return
   return specimenCategories.items[1]
end

function concentriqAPI.postSpecimenCategories(body)
   local specimenCategories = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'specimenCategories',
         body = body
      })

   return specimenCategories
end

-- USERS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getUsers(query)
   local users = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'users',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(users.items) then
      return nil
   end

   -- return the single user object to match the POST return
   return users.items[1]
end

function concentriqAPI.getUser(id)
   local user = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'users',
         id = id
      })

   return user
end

function concentriqAPI.getUserId(assignedUserCode, assignedUserIdLookupField)
   local queryCriteria = {["$ilike"] = assignedUserCode}
   local assignedUserQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = {
               [assignedUserIdLookupField] = queryCriteria
            }
         }
      }
   }
   local user = concentriqAPI.getUsers(assignedUserQuery)
   if user then
      return user
   else
      iguana.logWarning('User not found where ' .. assignedUserIdLookupField .. ' = ' .. assignedUserCode)
      return nil
   end
end

-- FILES
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getFile(resourceType, resourceId, storageKey)
   local file = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'files/download/redirect',
         timeout = 600,
         parameters={
            resourceType=resourceType,
            resourceId=resourceId,
            storageKey=storageKey
         }
      })

   return file
end

function concentriqAPI.getFileUploadUrl(resourceType, resourceId, storageKey)
   local url = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'files/upload/url',
         parameters={
            resourceType=resourceType,
            resourceId=resourceId,
            storageKey=storageKey
         }
      })

   return url
end

function concentriqAPI.postFileUploadComplete(resourceType, resourceId, storageKey)
   -- Not sure why, but passing in the values as parameters was not working, so constructing the url params manually
   local file = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = '/files/upload/complete?resourceType='..resourceType..'&resourceId='..resourceId..'&storageKey='..urlEncode(storageKey)
      })

   return file
end

--   concentriqAPI.uploadFile(caseDetailId, "gross.jpg", { dir="/var/images" })
--   concentriqAPI.uploadFile(caseDetailId, "gross.jpg", { base64=b64String })
function concentriqAPI.uploadFile(caseDetailId, filename, opts)
   assert(caseDetailId, 'caseDetailId is required')
   assert(filename, 'filename is required')
   assert(opts and (opts.dir or opts.base64), 'Provide opts.dir OR opts.base64')

   local fileContent
   local sourceDesc

   if opts.base64 then
      fileContent = filter.base64.dec(opts.base64)
      sourceDesc = 'base64 payload'
   else
      local path = opts.dir .. filename
      local f, err = io.open(path, 'rb')
      if not f then
         error(('Unable to open "%s": %s'):format(path, tostring(err)))
      end
      fileContent = f:read('*a')
      f:close()
      sourceDesc = path
   end

   local fileSize = #fileContent
   if fileSize == 0 then
      iguana.logError(('Skipping "%s" because it is empty'):format(sourceDesc))
      return
   end

   local attachmentBody = {
      filename = filename,
      fileSize = fileSize
   }
   local attachment = concentriqAPI.postCaseDetailAttachment(caseDetailId, attachmentBody)

   local fileUploadUrl = concentriqAPI.getFileUploadUrl('Attachment', attachment.id, attachment.storageKey)
   local responseData, responseCode, responseHeaders = net.http.put{
      url  = fileUploadUrl.url,
      data = fileContent,
      live = LIVE_UPDATE
   }

   if tonumber(responseCode) == 200 then
      concentriqAPI.postFileUploadComplete('Attachment', attachment.id, attachment.storageKey)
   else
      error(('File "%s" failed to upload (%s): %s'):format(filename, tostring(responseCode), tostring(responseData)))
   end
end

-- CASE TAGS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getCaseDetailCaseTags(query)
   local caseDetailCaseTags = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'caseDetailCaseTags',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(caseDetailCaseTags.items) then
      return nil
   end

   -- return the single caseDetailCaseTags object to match the POST return
   return caseDetailCaseTags.items[1]
end


function concentriqAPI.postCaseDetailCaseTags(body)
   local caseDetailCaseTags = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'caseDetailCaseTags',
         body = body
      })

   return caseDetailCaseTags
end   

-- WEBHOOK REQUESTS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.getWebhookRequests(query)
   local webhookRequests = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'webhookRequests',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(webhookRequests.items) then
      return nil
   end

   return webhookRequests
end

function concentriqAPI.postWebhookResend(id)
   local webhookResend = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'webhookRequests/'..id..'/resend'
      })   

   return webhookResend

end

-- ATTACHMENTS
--------------------------------------------------------------------------------------------------------------
function concentriqAPI.postAttachment(body)
   local attachment = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'attachments',
         body = body
      })

   return attachment
end

-- IMAGE JWT TOKEN
------------------
function concentriqAPI.getImageToken(id)
   local imageToken = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'images/'..id..'/token'   

      })

   return imageToken
end


-- IMAGE ANALYSIS
--------------------------------------------------
function concentriqAPI.postRunSlideAnalyses(body)
   local runSlideAnalyses = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'runSlideAnalyses',
         body = body
      })
end

-- LAB SITE
--------------------------------------------------
function concentriqAPI.getLabSites(query)
   local labSites = concentriqAPI.httpRequest({
         method = 'GET',
      endpoint = 'labSites',
         parameters={
            filter=query
         }
      })

   if tu.isEmpty(labSites.items) then
      return nil
   end

   -- return the single specimen object to match the POST return
   return labSites.items[1]
end

-- SECONDARY ASSIGNEE
-------------------------------------------------
function concentriqAPI.postSecondaryAssignee(body)
   local secondaryAssignees = concentriqAPI.httpRequest({
         method = 'POST',
      endpoint = 'secondaryAssignees',
         body = body
      })
   return secondaryAssignees
end


return concentriqAPI
