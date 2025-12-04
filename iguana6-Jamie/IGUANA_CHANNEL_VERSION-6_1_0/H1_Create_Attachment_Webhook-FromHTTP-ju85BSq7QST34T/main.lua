-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.

function main(Data)
   iguana.logInfo(Data)
   local req = net.http.parseRequest{data=Data}
   queue.push{data=req.body}
   local resp = net.http.respond{code=200,body='OK'}
end