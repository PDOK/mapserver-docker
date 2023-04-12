-- obtain service type from environment
serviceType = os.getenv('SERVICE_TYPE')
if not serviceType then
    print('SERVICE_TYPE environment variable is missing')
    return 500
end

if lighty.r.req_attr["uri.path"] == "/mapserver" then
    params = {}
    -- parse and rewrite query string
    if lighty.r.req_attr["uri.query"] then
        newQuery = ''
        for k, v in lighty.r.req_attr["uri.query"]:gmatch("([^?&=]+)=([^&]+)") do
            k = k:lower()

            params[k] = v

            -- remove map parameter from query
            if k ~= 'map' then
                newQuery = newQuery .. k .. '=' .. v .. '&'
            end
        end

        lighty.r.req_attr["uri.query"] = newQuery:sub(1, -2)
    end

    if params['service'] and params['service']:lower() ~= serviceType:lower() then
        return 404
    end

    if lighty.r.req_attr["request.method"] == "GET" then
        if not lighty.r.req_attr["uri.query"] or lighty.r.req_attr["uri.query"] == '' or not params['service'] then
            return 400
        end
    end
end
