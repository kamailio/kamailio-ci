-- More info at 
-- https://gist.github.com/Samael500/5dbdf6d55838f841a08eb7847ad1c926
-- http://qaru.site/questions/11868853/using-nginx-lua-to-validate-github-webhooks-and-delete-cron-lock-file

-- luarocks install JSON4Lua
-- luarocks install luacrypto

local json = require "json"
local uuid = require "uuid"

local secret = 'qwerty1'
local workdir = '/run/image_puller/new_images'

ngx.header.content_type = "text/plain; charset=utf-8"


local function validate_hook ()
    local headers = ngx.req.get_headers()
    -- with correct header
    if headers['X-Auth-Token'] ~= secret then
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say('{"status":"error","description":"bad auth token"}')
        return ngx.exit (ngx.HTTP_FORBIDDEN)
    end

    -- should be POST method
    if ngx.req.get_method() ~= "POST" then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"status":"error","description":"bad request method: ', ngx.req.get_method(), '"}')
        return ngx.exit (ngx.HTTP_BAD_REQUEST)
    end

    -- should be json encoded request
    if headers['Content-Type'] ~= 'application/json' then
        ngx.status = ngx.HTTP_NOT_ACCEPTABLE
        ngx.say('{"status":"error","description":"wrong content type header: ', headers['Content-Type'], '"}')
        return ngx.exit (ngx.HTTP_NOT_ACCEPTABLE)
    end

    -- read request body
    ngx.req.read_body()
    local data = ngx.req.get_body_data()

    if not data then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"status":"error","description":"failed to get request body"}')
        return ngx.exit (ngx.HTTP_BAD_REQUEST)
    end

    data = json.decode(data)
    image_name = data['image_name']
    image_tag = data['image_tag']

    -- check image_name
    if image_name == nil then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"status":"error","description":"image_name must be provided"}')
        return ngx.exit (ngx.HTTP_BAD_REQUEST)
    end
    if string.match(image_name, '^rpms%-master$') == nil and string.match(image_name, '^rpms%-%d%.%d$') == nil and string.match(image_name, '^rpms%-%d%.%d%.%d$') == nil then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"status":"error","description":"wrong image_name value: ', image_name, '"}');
        return ngx.exit (ngx.HTTP_BAD_REQUEST);
    end

    -- check image_tag
    if image_tag == nil then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"status":"error","description":"image_tag must be provided"}')
        return ngx.exit (ngx.HTTP_BAD_REQUEST)
    end
    if string.match(image_tag, '^centos%-%d+$') == nil and string.match(image_tag, '^fedora%-%d+$') == nil and string.match(image_tag, '^rhel%-%d+$') == nil and string.match(image_tag, '^opensuse_leap%-%d+$') == nil and string.match(image_tag, '^opensuse_tumbleweed%-%d+$') == nil then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"status":"error","description":"wrong image_tag value: ', image_tag, '"}');
        return ngx.exit (ngx.HTTP_BAD_REQUEST);
    end

    return true
end


local function deploy ()
    local data = ngx.req.get_body_data()
    data = json.decode(data)
    image_name = data['image_name']
    image_tag = data['image_tag']
    filename = workdir .. '/' .. uuid.new() .. '.image_string'

    -- create image_string file
    os.execute("mkdir -p " .. workdir)
    file = io.open(filename, "a")
    io.output(file)
    io.write(image_name .. ':' .. image_tag)
    io.close(file)

    -- debug commmands
--    local handle = io.popen("ls -l " .. workdir)
--    local result = handle:read("*a")
--    handle:close()
--    ngx.say (result)

    ngx.say('{"status":"success"}');
    return ngx.exit (ngx.HTTP_OK)
end


if validate_hook() then
    deploy()
end

