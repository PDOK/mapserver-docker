local r = lighty.r
r.resp_header["Content-Type"] = "text/plain; charset=utf-8" 
r.resp_body:set({ '400 Bad Request - Invalid value for query parameter "service"\n'})
return 400
