path = lighty.env["uri.path"]
query = lighty.env["uri.query"]

-- redirect to MapServer
if path ~= "/mapserver" then
    lighty.env["request.uri"] = "/mapserver?" .. query
    return lighty.RESTART_REQUEST
end

-- parse and rewrite query string
params = {}
newQuery = ''
for k, v in query:gmatch("([^?&=]+)=([^&]+)") do
    k = k:lower()

    params[k] = v

    -- remove map parameter from query
    if k ~= 'map' then
        newQuery = newQuery .. k .. '=' .. v .. '&'
    end
end

lighty.env["uri.query"] = newQuery:sub(1, -2)

if lighty.env["request.method"] == "GET" then

    -- obtain service type from environment
    serviceType = os.getenv('SERVICE_TYPE')
    if serviceType == nil then
        print('SERVICE_TYPE environment variable is missing')
        return 500
    end

    serviceType = serviceType:lower()

    -- check if query is present
    if not query then
        return 400
    end

    -- assign service and version default values
    version = params['version']
    service = params['service']

    if service == nil then
        service = serviceType
    else
        service = service:lower()
    end

    if (service == 'wms' and (version == nil or version ~= '1.1.1')) then
        version = '1.3.0'
    end

    if (service == 'wfs' and (version == nil or (version ~= '1.0.0' and version ~= '1.1.0'))) then
        version = '2.0.0'
    end

    -- check if current request matches configured service type
    if service ~= serviceType then
        return 404
    end

end
