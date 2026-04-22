if GetResourceState(Config.CoreName.qbx) ~= 'started' then return end

function GetPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

function GetPlayers()
    return exports.qbx_core:GetQBPlayers()
end

function RemoveItem(src, item, amount, info, slot)
    return exports.ox_inventory:RemoveItem(src, item, amount, info, slot or nil)
end

function AddItem(src, item, amount, info, slot)
    if string.find(item, "_blueprint", 1, true) then
        local blueprint = item:gsub("_blueprint", "")
        print(blueprint)
        return exports['nextgenfivem_crafting']:givePlayerBlueprint(src, blueprint)
    end
    return exports.ox_inventory:AddItem(src, item, amount, info, slot or nil)
end

function HasInvGotItem(inv, search, item, metadata, amount)
    if type(amount) == "boolean" then return end
    if amount == 0 then return false end
    if exports.ox_inventory:Search(inv, search, item) >= amount then
        return true
    else
        return false
    end
end

function GetInvItems(inv)
    return exports.ox_inventory:GetInventoryItems(inv)
end

function GetItemBySlot(src, slot)
    local Player = exports.qbx_core:GetPlayer(src)
    return Player.Functions.GetItemBySlot(slot)
end

function AddMoney(src, AddType, amount, reason)
    exports.qbx_core:AddMoney(src, AddType, amount, reason or '')
end

function RemoveMoney(src, RemoveType, amount, reason)
    exports.qbx_core:RemoveMoney(src, RemoveType, amount, reason or '')
end

function RegisterStash(id, slots, maxWeight)
    exports.ox_inventory:RegisterStash(id, id, slots, maxWeight)
end

function ClearStash(id)
    exports.ox_inventory:ClearInventory(id, 'false')
end