function gbanHash(...)
    local arg = {...}
    key = table.concat( arg )
    maxInt = 62857143
    maxPostInt = 31428571
    hash = os.time() + Config.serverId
    length = string.len(key)
    for i=1, length do
        hash = hash * 31 + string.byte(string.sub(key,i,i))
        if hash > maxInt then
            div = math.floor(hash / (maxInt + 1))
            hash = hash - (div * (maxInt + 1))
        end
    end
    if hash > maxPostInt then
        hash = hash - maxInt - 1
    end
    if hash < 0 then
        hash = hash + maxInt + 1
    end
    return string.format("%x", hash)
end