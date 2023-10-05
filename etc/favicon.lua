local r = lighty.r
r.resp_header["Content-Type"] = "image/x-icon" 
r.resp_body:set({ { filename = '/favicon.ico' } })
return 200
