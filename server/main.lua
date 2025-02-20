-- Don't edit hash and PostData content
function PostData(data)
    local result = nil
    data['serverKey'] = Config.serverKey
    data['serverEndPoint'] = Config.serverEndPoint
    PerformHttpRequest("https://dejavu.gigne.net/fivem/ban-list/", function(err, response, headers)
        if err == 200 then
            result = json.decode(result)
        else
            result = {error = err, message = response}
        end
    end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
    while result == nil do
        Wait(0)
    end
    return result
end

function banByPlayerId(playerId, reason, expires, staff)
    local identifiers = json.encode(GetPlayerIdentifiers(playerId))
    local reason = reason or Config.DefaultReason
    local staff = staff or Config.projectName
    local hash = gbanHash(identifiers, staff)

    if type(expires) == 'number' and expires < os.time() then
        expires = os.time()+expires 
    end

    if Config.Kick then DropPlayer(playerId, reason) end
    return PostData({ban = identifiers, reason = reason, staff = staff, expires = expires, hash = hash})
end

function banByIdentifier(identifiers, reason, expires, staff)
    if type(identifiers) ~= 'table' then identifiers = {identifiers} end
    identifiers = json.encode(identifiers)
    local reason = reason or Config.DefaultReason
    
    if type(expires) == 'number' and expires < os.time() then
        expires = os.time()+expires 
    end
    
    local staff = staff or Config.projectName
    local hash = gbanHash(identifiers, staff)
    return PostData({ban = identifiers, reason = reason, staff = staff, expires = expires, hash = hash})
end

function gbanRemove(serial, staff)
    local staff = staff or Config.projectName
    local hash = gbanHash(serial, staff)
    return PostData({remove = serial, staff = staff, hash = hash})
end

AddEventHandler('onResourceStart', function(resourceName)
    Config.locale = GetConvar('locale')
    Config.projectName = GetConvar('sv_projectName')
    if (GetCurrentResourceName() == resourceName) then
        result = PostData({event = 'onResourceStart', locale = Config.locale, projectName = Config.projectName, serverEndPoint = Config.serverEndPoint, time = os.time()})
        Config.serverId = result['serverId']
        Config.serverKey = result['serverKey']
    end
end)

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    deferrals.defer()
    deferrals.update("Checking Player Information. Please Wait.")
    local identifier = json.encode(GetPlayerIdentifiers(source))
    local hash = gbanHash(identifiers)
    local result = PostData({identifier = identifier, hash = hash})
    if result then
        if Config.CheckBan and result['reason'] then
            if Config.score then
                if result['score'] >= Config.score then
                    deferrals.done("Reason: " .. result['reason'])
                else
                    deferrals.done()
                end                
            else
                deferrals.done("Reason: " .. result['reason'])
            end
        else
            deferrals.done()
        end
    end
end)

RegisterCommand('gban', function(playerId, args, rawCommand)
    if (IsPlayerAceAllowed(playerId, 'command')) then
        staff = GetPlayerIdentifiers(playerId)[1]

        local ban = tonumber(args[1])
        local expires = nil
        
        if tonumber(args[2]) ~= nil then
            expires = args[2]
            table.remove(args, 1)
            table.remove(args, 1)
        else
            table.remove(args, 1)
        end        
        
        reason = table.concat(args, ' ')
        banByPlayerId(ban, reason, expires, staff)
    end
end)

RegisterCommand('gbanlist', function(playerId, args, rawCommand)
    if (IsPlayerAceAllowed(playerId, 'command')) then
        local staff = GetPlayerIdentifiers(playerId)[1]
        local hash = gbanHash(staff)
        local result = nil
        result = PostData({list = staff, hash = hash})
        TriggerClientEvent('gban:list', playerId, result.list)
    end
end)

RegisterCommand('gbanident', function(playerId, args, rawCommand)
    if (IsPlayerAceAllowed(playerId, 'command')) then
        staff = GetPlayerIdentifiers(playerId)[1]

        local ban = args[1]
        local expires = nil
        
        if tonumber(args[2]) ~= nil then
            expires = args[2]
            table.remove(args, 1)
            table.remove(args, 1)
        else
            table.remove(args, 1)
        end        
        
        reason = table.concat(args, ' ')
        banByIdentifier(ban, reason, expires, staff)
    end
end)

RegisterServerEvent('gban:selfBan')
AddEventHandler('gban:selfBan', function (reason, time, staff)
    banByPlayerId(source, reason, time, staff)
end)

RegisterServerEvent('gban:playerBan')
AddEventHandler('gban:playerBan', function (playerId, reason, time)
    if (IsPlayerAceAllowed(source, 'command')) then
        local staff = GetPlayerIdentifiers(source)[1]
        banByPlayerId(playerId, reason, time, staff)
    end
end)

RegisterServerEvent('gban:remove')
AddEventHandler('gban:remove', function (hash, staff)
    if (IsPlayerAceAllowed(source, 'command')) then
        local staff = GetPlayerIdentifiers(source)[1]
        gbanRemove(hash, staff)
    end
end)

RegisterServerEvent('gban:GetPlayers')
AddEventHandler('gban:GetPlayers', function ()
    for _, playerId in ipairs(GetPlayers()) do
        local name = GetPlayerName(playerId)
        connectedPlayers[playerId] = name
    end
end)

exports('playerBan', banByPlayerId)
exports('identifierBan', banByIdentifier)
exports('remove', gbanRemove)
