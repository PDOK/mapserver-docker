uri = lighty.env["uri.query"]

params = ''
for k, v in uri:gmatch("\\?([^?&=]+)=([^&]+)") do
    if k:lower() ~= 'map' then
        params = params .. k .. '=' .. v .. '&'
    end
end

lighty.env["uri.query"] = params:sub(1, -2)