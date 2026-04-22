local orders = {}
local WEBHOOK_URL = "https://discord.com/api/webhooks/1450844700306182317/LeAig3k640f213WD1MAWhZ54aBZ9osQcdXc8rwn089zqJSCuHvCEyVoORq9cOscC0H6c"

local function SendWebhook(title, description)
    if WEBHOOK_URL == "" or WEBHOOK_URL == nil then return end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = 3066993,
            ["footer"] = {
                ["text"] = "VOS",
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(WEBHOOK_URL, function(err, text, headers) end, 'POST', json.encode({
        username = "VOS",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

function SpawnAttackPed(src, coords, model)
    local modelHash = GetHashKey(model)
    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    if not DoesEntityExist(ped) then
        return nil
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)
    TriggerClientEvent('flex_order:client:SetupPed', src, netId, coords)
    return ped
end

RegisterServerEvent("flex_orders:server:confirmOrder", function(order)
    local src = source
    if not src then return end
    local player = GetPlayer(src)
    if not player then return end
    local orderId = #orders + 1
    local locId = math.random(1, #Config.DeliverLocs)
    local timeout = 5000
    local startTime = GetGameTimer()
    local locationFound = true

    while Config.DeliverLocs[locId].inUse do
        if GetGameTimer() - startTime >= timeout and not locationFound then
            locationFound = false
            break
        end
        locId = math.random(1, #Config.DeliverLocs)
        locationFound = true
        Wait(100)
    end

    if locationFound then
        Config.DeliverLocs[locId].inUse = true
    else
        Config.Notify.server(src, Language.info.nolocationatthistime, 'info', 5000)
    end
    local coords = Config.DeliverLocs[locId].crate
    orders[orderId] = {
        coords = coords,
        order = order,
        orderId = orderId,
        locId = locId,
        peds = {},
        object = nil,
        objectId = nil,
        spawned = false,
        done = false
    }
    Config.DeliverLocs[locId].inUse = true
    SendWebhook(Language.discord:format(player?.PlayerData?.charinfo?.firstname..' '..player?.PlayerData?.charinfo?.lastname..' ('..player?.PlayerData?.citizenid..')'), json.encode(order))
    CreateThread(function()
        SetTimeout(1000 * 60 * Config.DeliverTime,function()
            Config.Mail.server(Language.mail.sender, Language.mail.pickupReady, Language.mail.pickupReady, src)
            TriggerClientEvent('flex_orders:client:createWaypoint', src, coords, Language.blip.location, 161, 49, false, false)
            TriggerClientEvent('flex_orders:client:registerPedAndCrateSpawnZone', -1, coords, locId, orderId)
            if math.random(0, 100) <= Config.GlobalBlipChance then
                SetTimeout(1000 * 60 * math.random(1, 2),function()
                    local players = GetPlayers()
                    for k, v in pairs(players) do
                        if v?.PlayerData.job.name ~= 'police' or v?.PlayerData.job.name ~= 'ambulance' or v?.PlayerData.job.type ~= 'leo' or v?.PlayerData.job.type ~= 'ems' then
                            TriggerClientEvent('flex_orders:client:createWaypoint', src, coords, Language.blip.location, 161, 49, false, true)
                            Config.Mail.server(Language.mail.rob.sender, Language.mail.rob.title, Language.mail.rob.message, k)
                        end
                    end
                end)
            end
        end)
    end)
end)

RegisterServerEvent("flex_orders:server:spawnPedsAndCrate", function(coords, locId, orderId, src)
    Wait(math.random(10,300))
    source = source or src
    if not orders[orderId] then return end
    if orders[orderId].spawned or not source then return end
    orders[orderId].spawned = true
    local object = CreateObjectNoOffset(
        GetHashKey('xm3_prop_xm3_crate_01a'),
        coords.x, coords.y, coords.z-1,
        true,
        true,
        false
    )
    Wait(50)
    SetEntityHeading(object, coords.w)
    FreezeEntityPosition(object, true)
    orders[orderId].object = object
    Wait(50)
    if locId then
        for k, v in pairs(Config.DeliverLocs[locId].peds) do
            local ped = SpawnAttackPed(source, v.coords, v.model)
            table.insert(orders[orderId].peds, ped)
            Wait(100)
        end
    end
    local netId = NetworkGetNetworkIdFromEntity(object)
    orders[orderId].objectId = netId
    TriggerClientEvent('flex_orders:client:registerTarget', -1, netId, orderId, coords, true)
end)

RegisterServerEvent("flex_orders:server:confirmAdminOrder", function(order, coords, policeambu)
    local src = source
    local orderId = #orders + 1
    local coords = coords
    orders[orderId] = {
        coords = coords,
        order = order,
        orderId = orderId,
        peds = {},
        object = nil,
        objectId = nil,
    }
    CreateThread(function()
        TriggerClientEvent('flex_orders:client:registerPedAndCrateSpawnZone', -1, coords, locId, orderId)
        Wait(1000)
        local players = GetPlayers()
        for k, v in pairs(players) do
            if policeambu or v?.PlayerData.job.name ~= 'police' or v?.PlayerData.job.name ~= 'ambulance' or v?.PlayerData.job.type ~= 'leo' or v?.PlayerData.job.type ~= 'ems' then
                TriggerClientEvent('flex_orders:client:createWaypoint', k, coords, Language.blip.location, 161, 49, false, true)
                Config.Mail.server(Language.mail.rob.sender, Language.mail.rob.title, Language.mail.rob.message, k)
            end
            Wait(5)
        end
    end)
end)

RegisterNetEvent('flex_orders:server:SendYSeriesMail', function(sender, subject, message, id)
    local receiverType = 'source'
    local receiver = id or source
    local insertId, received = exports.yseries:SendMail({
        title = subject,
        sender = sender..'@LastAntis.onion',
        senderDisplayName = sender,
        content = message,
    }, receiverType, receiver)
end)

RegisterServerEvent("flex_orders:server:removeTarget", function(netId, orderId)
    TriggerClientEvent('flex_orders:client:removeTarget', -1, netId)
end)

local function AttackPlayers(src, orderId)
    if not orders[orderId] then
        print(("AttackPlayers: no order for id %s"):format(tostring(orderId)))
        return
    end

    if not orders[orderId].order then
        print(("AttackPlayers: order field is nil for id %s"):format(tostring(orderId)))
        return
    end

    if not orders[orderId].peds or #orders[orderId].peds == 0 then
        print(("AttackPlayers: no peds for orderId %s"):format(tostring(orderId)))
        return
    end

    local playerPed = GetPlayerPed(src)
    if not DoesEntityExist(playerPed) then
        print(("AttackPlayers: player ped does not exist for src %s"):format(tostring(src)))
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - orders[orderId].coords.xyz) >= 100 then
        print(("AttackPlayers: player too far from order %s"):format(tostring(orderId)))
        return
    end

    for _, pedEntity in pairs(orders[orderId].peds) do
        if DoesEntityExist(pedEntity) then
            local netId = NetworkGetNetworkIdFromEntity(pedEntity)
            if netId and netId ~= 0 then
                TriggerClientEvent('flex_order:client:AttackPlayer', src, netId)
            else
                print("AttackPlayers: ped has no valid netId")
            end
        else
            print("AttackPlayers: ped entity does not exist (deleted?)")
        end
    end
end

RegisterServerEvent("flex_orders:server:getOrderItems", function(netId, orderId)
    local src = source
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local distance = #(pedCoords - orders[orderId].coords.xyz)

    if (distance > 10.0) then
        return
    end

    if orders[orderId].done then
        return
    end

    if not orders[orderId].order or #orders[orderId].order <= 0 then
        return
    end

    orders[orderId].done = true

    CreateThread(function()
        SetTimeout(1000 * 60 * math.random(5, 10), function()
            TriggerClientEvent('flex_orders:client:removeObject', -1, netId)

            if orders[orderId].locId then
                Config.DeliverLocs[orders[orderId].locId].inUse = false
            end

            if orders[orderId].peds then
                for k, v in pairs(orders[orderId].peds) do
                    if DoesEntityExist(v) then
                        DeleteEntity(v)
                    end
                end
            end

            if DoesEntityExist(orders[orderId].object) then
                DeleteEntity(orders[orderId].object)
            end

            orders[orderId] = nil
        end)
    end)

    for k, v in pairs(orders[orderId].order) do
        if orders[orderId].order then
            if RemoveMoney(src, v.priceType, (v.price or 0) * v.amount, nil) then
                AddItem(src, v.name, v.amount or 1, v.info or {}, nil)
                if k == #orders[orderId].order then
                    orders[orderId].order = nil
                    return
                end

            elseif orders[orderId].peds and orders[orderId].order then
                if AddItem(src, v.name, v.amount or 1, v.info or {}, nil) then
                    for k2, ped in pairs(orders[orderId].peds) do
                        if DoesEntityExist(ped) then
                            if GetEntityHealth(ped) > 10 then
                                orders[orderId].order = nil
                                return AttackPlayers(src, orderId)
                            end
                        end
                    end
                end
            end
        end
    end

    orders[orderId].order = nil
end)


lib.callback.register("flex_orders:server:getPeds", function(source, orderId)
    local netIds = {}
    for k, v in pairs(orders[orderId].peds) do
        local netId = NetworkGetNetworkIdFromEntity(v)
        netIds[#netIds+1] = netId
    end
    return netIds
end)

lib.addCommand('adminorder', {
    help = 'Open Admin Order Menu',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('flex_orders:client:openAdminOrder', source)
end)

AddEventHandler("onResourceStop", function(resource)
    local currentResource = GetCurrentResourceName()
    if resource == currentResource then
        for k, v in pairs(orders) do
            for key, ped in pairs(v.peds) do
                if DoesEntityExist(ped) then
                    DeleteEntity(ped)
                end
            end
            if DoesEntityExist(v.object) then
                DeleteEntity(v.object)
            end
        end
    end
end)