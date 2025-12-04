-- Import required modules
local retry = require 'retry'
local tu = require 'tableUtils'

-- Configuration variables from environment
local BASE_URL = os.getenv('IAS_API_URL')
local LIVE_GET = true
local LIVE_UPDATE = true
local TIMEOUT = 10
local RETRY = 10
local PAUSE = 1
local HEADERS = {}


-- Table to hold all API related functions
local iasAPI = {}

-- Function to check the HTTP response status
function checkHttpResponse(code, headers)
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

-- Function to make HTTP requests
function iasAPI.httpRequest(params)
   -- Default parameters for the HTTP request
   trace(HEADERS)
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
      funcname = 'iasAPI.' .. params.method .. params.endpoint
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

   if response == '' then
      return response
      --return json.parse{data='{"test":"testing"}'}
   else
      return json.parse{data=response}
   end

end

-- Additional functions for handling specific API endpoints

-- ANALYSES
function iasAPI.getAnalyses(query, jwt)
   local analyses = iasAPI.httpRequest({
         method = 'GET',
      endpoint = 'analyses',
         parameters={
            filter=query
         },
         headers={['Authorization']='Bearer '..jwt}         
      })

   if tu.isEmpty(analyses.items) then
      return nil
   end

   return analyses
end



return iasAPI
