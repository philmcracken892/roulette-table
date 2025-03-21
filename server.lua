local RSGCore = exports['rsg-core']:GetCoreObject()


RSGCore.Functions.CreateUseableItem("roulettetable", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    print("ROULETTE: Player " .. source .. " is using roulette table item")
    TriggerClientEvent('rsg-roulette:client:openRouletteTableMenu', source)
end)


RegisterNetEvent('rsg-roulette:server:returnRouletteTable', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    print("ROULETTE: Returning table to player " .. src)
    Player.Functions.AddItem("roulettetable", 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items["roulettetable"], "add")
end)


RegisterNetEvent('rsg-roulette:server:placeRouletteTable', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    print("ROULETTE: Removing table from player " .. src)
    Player.Functions.RemoveItem("roulettetable", 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items["roulettetable"], "remove")
end)
