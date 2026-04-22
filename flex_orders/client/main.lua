local ShopPed = nil
local IsOrdering = false
local PedTargets, EntityTargets, Points, Zones, BoxPoints = {}, {}, {}, {}, {}
local Blips = {}
local objects = {}
local scenarios = { "WORLD_HUMAN_VALET", "WORLD_HUMAN_AA_COFFEE", "WORLD_HUMAN_GUARD_STAND_CASINO", "WORLD_HUMAN_GUARD_PATROL", "PROP_HUMAN_STAND_IMPATIENT", }
local CurrentOrder = {}
local InPoint = false

function createBlip(coords, name, blip, color, shortrange)
    local x, y, z = table.unpack(coords)
    local newBlip = AddBlipForCoord(x, y, z)
    SetBlipSprite(newBlip, blip)
    SetBlipDisplay(newBlip, 4)
    SetBlipScale(newBlip, 0.8)
    SetBlipColour(newBlip, color)
    SetBlipAsShortRange(newBlip, shortrange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(newBlip)
    Blips[newBlip] = newBlip
    return newBlip
end

function CreateRadiusBlip(coords, scale, color)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, scale)

    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    SetBlipAlpha(blip, 150)

    return blip
end

local function TakeControlOfObject(netId)
    local obj = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(obj) then
        return
    end

    NetworkRequestControlOfNetworkId(netId)
    local timeout = GetGameTimer() + 2000
    while not NetworkHasControlOfNetworkId(netId) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfNetworkId(netId)
    end

    local timeoutEntity = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(obj) and GetGameTimer() < timeoutEntity do
        Wait(0)
        NetworkRequestControlOfEntity(obj)
    end

    SetEntityAsMissionEntity(obj, true, true)
end

local function checkMaxOrder(item, amount, max)
    for k, v in pairs(CurrentOrder) do
        if v.name == item then
            if v.amount+amount > max then
                return false
            else
                return false
            end
        end
    end
    return false
end

local function OpenShop()
    local menu = {}
    local level = Config.Skill()
    for _, v in pairs(Config.OrderItems) do
        if level >= v.rep then
            local description = Language.menu.order.buy:format(v.label, v.price, Language.menu.order[v.priceType or Config.MoneType], v.max)
            if v.price <= 0 then
                description = Language.menu.order.buyfree:format(v.label)
            end
            menu[#menu + 1] = {
                title = v.label,
                description = description,
                icon = Config.ImagePath:format(v.name) or v.icon or "fa-solid fa-box",
                onSelect = function()
                    local input = lib.inputDialog(Language.menu.print_menutitle, {
                        { type = 'number', label = Language.menu.amount },
                    })
                    if input and not checkMaxOrder(v.name, tonumber(input[1]) or 1, v.max) then
                        for key, val in pairs(CurrentOrder) do
                            if val.name == v.name then
                                val.amount += tonumber(input[1]) or 1
                            else
                                CurrentOrder[#CurrentOrder + 1] = {
                                    name = v.name,
                                    label = v.label,
                                    price = v.price,
                                    info = v.info or {},
                                    amount = tonumber(input[1]) or 1,
                                    priceType = v.priceType or Config.MoneType or 'cash',
                                }
                            end
                        end
                    else
                        Config.Notify.client(Language.error.cantorderthatmuch, 'error')
                    end
                end
            }
        end
        Wait(100)
    end
    lib.registerContext({
        id = 'flex_order_menu',
        title = Language.menu.order.title,
        options = menu
    })
    lib.showContext('flex_order_menu')
end

local function CheckOrder()
    if #CurrentOrder == 0 then
        Config.Notify.client(Language.info.noorder, 'error')
        return
    end

    local menu = {}
    for _, v in pairs(CurrentOrder) do
        local description = Language.menu.order.totalcost:format(v.amount, v.label, v.price * v.amount, Language.menu.order[v.priceType or Config.MoneType])
        if v.price * v.amount <= 0 then
            description = Language.menu.order.totalcostfree:format(v.amount, v.label or v.name)
        end
        menu[#menu + 1] = {
            title = v.label,
            description = description,
            icon = v.icon or "fa-solid fa-box",
            onSelect = function()
                table.remove(CurrentOrder, _)
                Config.Notify.client(Language.info.removedfromorder, 'info')
            end
        }
        Wait(100)
    end

    lib.registerContext({
        id = 'flex_order_check',
        title = Language.target.checkorder,
        options = menu
    })
    lib.showContext('flex_order_check')
end

CreateThread(function()
    if not Config.OrderPed.model then return end
	local targetOptions = {
        {
            name = Language.target.order..'_flex_orders',
            label = Language.target.order,
            icon = "fa-solid fa-cart-plus",
            distance = 2.0,
            canInteract = function()
                return not IsOrdering
            end,
            onSelect = function()
                OpenShop()
            end
        },
        {
            name = Language.target.checkorder..'_flex_orders',
            label = Language.target.checkorder,
            icon = "fa-solid fa-magnifying-glass",
            distance = 2.0,
            canInteract = function()
                return not IsOrdering
            end,
            onSelect = function()
                CheckOrder()
            end
        },
        {
            name = Language.target.confirmorder..'_flex_orders',
            label = Language.target.confirmorder,
            icon = "fa-solid fa-truck",
            distance = 2.0,
            canInteract = function()
                return not IsOrdering
            end,
            onSelect = function()
                IsOrdering = true
                TriggerServerEvent('flex_orders:server:confirmOrder', CurrentOrder)
                Config.Notify.client(Language.info.orderplaced, 'info')
                CurrentOrder = {}
                SetTimeout(1000 * 60 * 15,function()
                    IsOrdering = false
                end)
            end
        },
    }

    local model = type(Config.OrderPed.model) == "table" and Config.OrderPed.model[math.random(1, #Config.OrderPed.model)] or Config.OrderPed.model

    if model then -- Create entity target
        local createEntity
        local deleteEntity
        if IsModelAPed(model) then
            function createEntity()
                ShopPed = CreatePed(0, model, Config.OrderPed.coords.x, Config.OrderPed.coords.y, Config.OrderPed.coords.z - 1.0, Config.OrderPed.coords.w, false, false)
                SetEntityInvincible(ShopPed, true)
                SetEntityNoCollisionEntity(ShopPed, cache.ped, false)
                TaskStartScenarioInPlace(ShopPed, scenarios[math.random(1, #scenarios)], -1, true)
                SetBlockingOfNonTemporaryEvents(ShopPed, true)
                SetEntityNoCollisionEntity(ShopPed, cache.ped, false)
                FreezeEntityPosition(ShopPed, true)
            end

            function deleteEntity()
                DeletePed(ShopPed)
            end
        end

        local point = lib.points.new(Config.OrderPed.coords.xyz, 15)
        function point:onEnter()
            if not ShopPed or (ShopPed and not DoesEntityExist(ShopPed)) then
                while not HasModelLoaded(model) do
                    pcall(function()
                        lib.requestModel(model)
                    end)
                end
                createEntity()
            end

            exports.ox_target:addLocalEntity(ShopPed, targetOptions)
        end

        function point:onExit()
            deleteEntity()
            CurrentOrder = {}
        end

        Points[#Points + 1] = point
    else
        local target = exports.ox_target:addSphereZone({
            coords = Config.OrderPed.coords.xyz,
            options = targetOptions,
            radius = 3.0
        })

        PedTargets[#PedTargets + 1] = target
    end
end)

RegisterNetEvent('flex_orders:client:registerPedAndCrateSpawnZone', function(coords, locId, orderId)
    local point = lib.points.new(coords, 125)
    function point:onEnter()
        InPoint = true
        Wait(100)
        TriggerServerEvent('flex_orders:server:spawnPedsAndCrate', coords, locId, orderId, GetPlayerServerId(NetworkGetPlayerIndexFromPed(PlayerPedId())))
    end

    function point:onExit()
        InPoint = false
    end

    Zones[orderId] = point
end)

RegisterNetEvent('flex_orders:client:registerTarget', function(netId, orderId, coords, spawnedPeds)
    if not netId and netId == 0 then return end
    local point = lib.points.new(coords, 85)
    function point:onEnter()
        InPoint = true
        Wait(100)
        local obj = NetworkGetEntityFromNetworkId(netId)
        if obj == 0 then return end
        EntityTargets[netId] = exports.ox_target:addLocalEntity(obj, {
            {
                icon = "fa-solid fa-plus",
                label = Language.target.opencrate,
                canInteract = function()
                    return not IsPedInAnyVehicle(PlayerPedId(), false)
                end,
                onSelect = function()
                    -- TakeControlOfObject(netId)
                    local objCoords = GetEntityCoords(obj)
                    local crate = GetClosestObjectOfType(objCoords.x, objCoords.y, objCoords.z, 1.0, GetHashKey('xm3_prop_xm3_crate_01a'), false, 0, 0)
                    if crate == 0 or crate == nil then return end
                    Wait(500)

                    local timeoutEntity = GetGameTimer() + 2000
                    while not NetworkHasControlOfEntity(crate) and GetGameTimer() < timeoutEntity do
                        Wait(0)
                        NetworkRequestControlOfEntity(crate)
                    end
                    SetEntityAsMissionEntity(crate, true, true)

                    TriggerServerEvent('flex_orders:server:removeTarget', netId, orderId)
                    local ped = cache.ped or PlayerPedId()
                    local targetPosition, targetRotation, targetHeading = GetEntityCoords(ped), GetEntityRotation(ped), GetEntityHeading(ped)
                    local crateCoords = GetEntityCoords(crate)
                    objects[1] = CreateObject(GetHashKey('w_me_crowbar'), targetPosition.x, targetPosition.y, targetPosition.z, true, true, true)
                    objects[2] = CreateObject(GetHashKey('v_ret_gc_bag01'), crateCoords.x, crateCoords.y, crateCoords.z, true, true, true)
                    Wait(50)
                    local AnimDic = "anim@scripted@player@mission@trn_ig1_loot@male@"
                    lib.requestAnimDict(AnimDic)
                    local animCoords = vec3(targetPosition.x, targetPosition.y, targetPosition.z-1)
                    local OpenCrateEnter = NetworkCreateSynchronisedScene(animCoords, targetRotation, 2, false, true, 1065353216, 0, 1.0)
                    while not OpenCrateEnter do
                        OpenCrateEnter = NetworkCreateSynchronisedScene(animCoords, targetRotation, 2, false, true, 1065353216, 0, 1.0)
                        Wait(100)
                    end
                    NetworkAddPedToSynchronisedScene(ped, OpenCrateEnter, AnimDic, "loot", 8.0, -8.0, 1, 16, 1148846080, 0)
                    NetworkAddEntityToSynchronisedScene(objects[2], OpenCrateEnter, AnimDic, "loot_can", 8.0, -8.0, 1)
                    NetworkAddEntityToSynchronisedScene(objects[1], OpenCrateEnter, AnimDic, "loot_crowbar", 8.0, -8.0, 1)
                    NetworkAddEntityToSynchronisedScene(crate, OpenCrateEnter, AnimDic, "loot_crate", 8.0, -8.0, 1)
                    NetworkStartSynchronisedScene(OpenCrateEnter)
                    Wait(GetAnimDuration(AnimDic, "loot_crate")*1000)
                    NetworkStopSynchronisedScene(OpenCrateEnter)
                    for k, v in pairs(objects) do
                        if DoesEntityExist(v) then
                            DeleteEntity(v)
                        end
                    end
                    TriggerServerEvent('flex_orders:server:getOrderItems', netId, orderId)
                end,
                distance = 2.0
            }
        })
        if spawnedPeds then
            CreateThread(function()
                local shotCooldown = 0
                local ped = NetworkGetEntityFromNetworkId(v)
                while InPoint do
                    local playerPed = PlayerPedId()
                    if IsPedShooting(playerPed) then
                        lib.callback('flex_orders:server:getPeds', 1000, function(peds)
                            for k, v in pairs(peds) do
                                PedShootEvent(v)
                            end
                        end, orderId)
                        return
                        -- local weapon = GetSelectedPedWeapon(playerPed)
                        -- if weapon ~= `WEAPON_UNARMED` then
                        -- end
                    end
                    Wait(10)
                end
            end)
        end
    end

    function point:onExit()
        exports.ox_target:removeLocalEntity(obj)
        InPoint = false
    end

    BoxPoints[netId] = point
end)

local function SetupPed(npc, coords)
    if not DoesEntityExist(npc) then
        print("Ped does not exist in SetupPed")
        return
    end
    -- SetEntityCoords(npc, coords.x, coords.y, coords.z)
    FreezeEntityPosition(npc, false)
    SetEntityInvincible(npc, false)
    SetEntityAsMissionEntity(npc, true, true)
    SetPedCombatAttributes(npc, 46, true)
    SetPedCombatAttributes(npc, 0, false)
    SetPedRelationshipGroupHash(npc, `HATES_PLAYER`)
    SetPedFleeAttributes(npc, 0, false)
    SetPedKeepTask(npc, true)
    if Config.PedWeapons and #Config.PedWeapons > 0 then
        local RandomPedWeapon = math.random(1, #Config.PedWeapons)
        local weaponHash = GetHashKey(Config.PedWeapons[RandomPedWeapon])
        GiveWeaponToPed(npc, weaponHash, 100, false, true)
        SetCurrentPedWeapon(npc, weaponHash, true)
    end
    SetPedMaxHealth(npc, 300)
    SetEntityHealth(npc, 300)
    SetPedArmour(npc, 400)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedConfigFlag(npc, 100, false)
    SetPedSuffersCriticalHits(npc, false)
    ClearPedTasksImmediately(npc)
    TaskWanderInArea(npc, coords.x, coords.y, coords.z, 15.0, 1.0, 10.0)
    -- TaskWanderStandard(npc, 10.0, 10)
end

local function MakePedHatePlayer(npc)
    if not DoesEntityExist(npc) then
        print("Ped does not exist in SetupPed")
        return
    end
    TaskCombatPed(npc, PlayerPedId(), 0, 16)
    SetPedMaxHealth(npc, 300)
    SetEntityHealth(npc, 300)
    SetPedArmour(npc, 100)
    SetPedSuffersCriticalHits(npc, false)
end

function PedShootEvent(netId)
    local timeout = 0
    local ped = NetworkGetEntityFromNetworkId(netId)

    while not DoesEntityExist(ped) and timeout < 1000 do
        Wait(10)
        ped = NetworkGetEntityFromNetworkId(netId)
        timeout += 10
    end

    if not DoesEntityExist(ped) then
        print(("Ped with netId %s never loaded on client"):format(netId))
        return
    end

    NetworkRequestControlOfEntity(ped)
    local tries = 0
    while not NetworkHasControlOfEntity(ped) and tries < 50 do
        Wait(10)
        tries += 1
    end

    MakePedHatePlayer(ped)
end

RegisterNetEvent('flex_order:client:SetupPed', function(netId, coords)
    if not netId or netId == 0 then
        print("Invalid netId received")
        return
    end

    local startTime = GetGameTimer()
    local ped = 0

    while not DoesEntityExist(ped) and (GetGameTimer() - startTime) < 5000 do
        ped = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(ped) then
            break
        end
        Wait(100)
    end

    if not DoesEntityExist(ped) then
        print(("Failed to get ped with netId %s after 5 seconds"):format(netId))
        return
    end

    local tries = 0
    NetworkRequestControlOfEntity(ped)
    while not NetworkHasControlOfEntity(ped) and tries < 100 do
        Wait(10)
        tries = tries + 1
        NetworkRequestControlOfEntity(ped)
    end

    if not NetworkHasControlOfEntity(ped) then
        print("Failed to get network control of ped")
        return
    end

    local tries = 0
    while not NetworkGetEntityIsNetworked(ped) and tries < 100 do
        Wait(100)
        tries = tries + 1
        NetworkRegisterEntityAsNetworked(ped)
    end
    SetEntityAsMissionEntity(ped, true, true)

    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    SetupPed(ped, coords)
end)

RegisterNetEvent('flex_order:client:AttackPlayer', function(netId)
    local timeout = 0
    local ped = NetworkGetEntityFromNetworkId(netId)

    while not DoesEntityExist(ped) and timeout < 1000 do
        Wait(10)
        ped = NetworkGetEntityFromNetworkId(netId)
        timeout += 10
    end

    if not DoesEntityExist(ped) then
        print(("Ped with netId %s never loaded on client"):format(netId))
        return
    end

    NetworkRequestControlOfEntity(ped)
    local tries = 0
    while not NetworkHasControlOfEntity(ped) and tries < 50 do
        Wait(10)
        tries += 1
    end

    MakePedHatePlayer(ped)
end)

RegisterNetEvent('flex_orders:client:createWaypoint', function(coords, name, blip, color, shortrange, radius)
    if not radius then
        local blip = createBlip(coords.xyz, name, blip, color, shortrange)
        SetBlipRoute(blip, true)
        CreateThread(function()
            SetTimeout(1000 * 60 * Config.BlipsTime,function()
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end)
        end)
    else
        local x, y, z = table.unpack(coords)
        local xVariation = math.random(-45, 45)
        local yVariation = math.random(-45, 45)
        x = x + xVariation
        y = y + yVariation
        local blip = CreateRadiusBlip(vec3(x, y, z), 200.0, color)
        CreateThread(function()
            SetTimeout(1000 * 60 * Config.RadiusblipTime,function()
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end)
        end)
    end
end)

RegisterNetEvent('flex_orders:client:removeTarget', function(netId)
    if not netId and netId == 0 then return end
    local obj = NetworkGetEntityFromNetworkId(netId)
    if obj == 0 then return end
    exports.ox_target:removeLocalEntity(obj)
    if BoxPoints[netId] then
        BoxPoints[netId]:remove()
    end
end)

RegisterNetEvent('flex_orders:client:removeObject', function(netId)
    local obj = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
end)

local function OpenAdminShop()
    local menu = {}
    menu[#menu + 1] = {
        title = 'Choose an Item to add in the crate',
        onSelect = function()
            local input = lib.inputDialog(Language.menu.print_menutitle, {
                { type = 'input',  label = 'Item Name', description = 'Spawnname of the item.', required = true },
                { type = 'input',  label = 'Item Info', description = 'Extra Info if needed for script or so.'},
                { type = 'number', label = Language.menu.amount },
            })
            if input then
                CurrentOrder[#CurrentOrder + 1] = {
                    name = input[1],
                    price = 0,
                    info = input[2] or {},
                    amount = tonumber(input[3]) or 1,
                }
                OpenAdminShop()
            end
        end
    }
    menu[#menu + 1] = {
        title = 'Check Order',
        onSelect = function()
            CheckOrder()
        end
    }
    menu[#menu + 1] = {
        title = 'place Order',
        description = 'NO POLICE + AMBU',
        onSelect = function()
            local coords = GetEntityCoords(cache.ped)
            local heading = GetEntityHeading(cache.ped)
            local distance = 2.0

            local forwardCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, distance, 0.0)
            local vec4 = vec4(forwardCoords.x, forwardCoords.y, forwardCoords.z, heading)
            TriggerServerEvent('flex_orders:server:confirmAdminOrder', CurrentOrder, vec4, false)
            Config.Notify.client(Language.info.orderplaced, 'info')
            CurrentOrder = {}
        end
    }
    menu[#menu + 1] = {
        title = 'place Order',
        description = 'WITH POLICE + AMBU',
        onSelect = function()
            local coords = GetEntityCoords(cache.ped)
            local heading = GetEntityHeading(cache.ped)
            local distance = 2.0

            local forwardCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, distance, 0.0)
            local vec4 = vec4(forwardCoords.x, forwardCoords.y, forwardCoords.z, heading)
            TriggerServerEvent('flex_orders:server:confirmAdminOrder', CurrentOrder, vec4, true)
            Config.Notify.client(Language.info.orderplaced, 'info')
            CurrentOrder = {}
        end
    }
    lib.registerContext({
        id = 'flex_order_menu_admin',
        title = Language.menu.order.title,
        options = menu
    })
    lib.showContext('flex_order_menu_admin')
end

RegisterNetEvent('flex_orders:client:openAdminOrder', function()
    OpenAdminShop()
end)

AddEventHandler("onResourceStop", function(resource)
    local currentResource = GetCurrentResourceName()
    if resource == currentResource then
        IsOrdering = false
        for k, v in pairs(EntityTargets) do
            exports.ox_target:removeLocalEntity(v)
        end
        for _, point in ipairs(Points) do
            point:remove()
        end
        DeletePed(ShopPed)
        for _, blip in ipairs(Blips) do
            RemoveBlip(blip)
        end
        for k, v in pairs(objects) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
    end
end)