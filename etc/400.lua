local r = lighty.r
r.resp_header["Content-Type"] = "text/plain; charset=utf-8" 
r.resp_body:set({ '400 Bad Request - No query parameters specified\n'})
return 400
