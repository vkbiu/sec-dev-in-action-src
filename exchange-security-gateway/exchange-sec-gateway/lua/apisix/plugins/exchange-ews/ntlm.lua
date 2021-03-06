---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hartnett.
--- DateTime: 2019/11/10 21:11
---


local _M = {}

-- character table string for base64 decoding (by alex kloss)
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- base64 decoding to hex string  (by alex kloss)
function _M.b64decode(data)
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then
            return ''
        end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
        end
        return r
    end)        :gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then
            return ''
        end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
        end
        return string.format("%02X", c)
    end))
end

-- return ASCII for hex String representing little endian UTF-16
function _M.getASCII(hex)
    local ascii = ""
    -- skip every second byte
    for i = 1, #hex, 4 do
        ascii = ascii .. string.char(tonumber(string.sub(hex, i, i + 1), 16))
    end
    return ascii
end

-- return integer for hex string in little endian order
function _M.getValue(hex)
    local rev_hex = ""
    -- loop reverse the hex string
    for i = #hex, 1, -2 do
        rev_hex = rev_hex .. string.sub(hex, i - 1, i)
    end
    return tonumber(rev_hex, 16)
end

-- return an ASCII value from the type 3 message in hex
-- len_pos and off_pos denote the byte position of the
-- offset and length of the value to be extracted
function _M.getField(hex, len_pos, off_pos)
    -- multiply all byte variables by 2 since 1 byte = 2 hex chars
    local length = _M.getValue(string.sub(hex, len_pos * 2 + 1, len_pos * 2 + 4))
    local offset = _M.getValue(string.sub(hex, off_pos * 2 + 1, off_pos * 2 + 4))
    local user_name = _M.getASCII(string.sub(hex, offset * 2 + 1, offset * 2 + length * 2))
    return user_name
end

function _M.get_username(ntlm_hash)
    local username = ""
    local hash = string.gsub(ntlm_hash, "NTLM ", "")
    hash = string.gsub(hash, "Negotiate ", "")
    if #hash > 60 then
        local hex_message = _M.b64decode(hash)
        username = _M.getField(hex_message, 36, 40)
    end

    -- ngx.log(ngx.DEBUG, string.format("hash: %s, hash length: %d, username: %s", hash, #hash, username))

    return username
end

return _M
