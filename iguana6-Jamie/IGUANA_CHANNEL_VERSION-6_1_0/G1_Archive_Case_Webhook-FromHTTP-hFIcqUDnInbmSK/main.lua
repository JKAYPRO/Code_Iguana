-- The main function is the first function called from Iguana.
	-- The Data argument will contain the message to be processed.
	require 'stringutil_old'
	
	function main(Data)
	   iguana.logInfo(Data)
	   --local Dec = filter.aes.dec{data=Data,key="ecRj7mmkcDp6zY5En2OwMxH97bhxW51U"}
                                          
	   local req = net.http.parseRequest{data=Data}
	   
	   queue.push{data=req.body}
   local resp = net.http.respond{code=200,body='OK'}
	end