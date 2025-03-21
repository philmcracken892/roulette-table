local RSGCore = exports['rsg-core']:GetCoreObject()

local CHECK_RADIUS = 2.0
local ROULETTE_TABLE_PROPS = {
    {
        label = "Roulette Table",
        model = `p_roulettetable01x`, -- Replace with the correct model for the roulette table
        offset = vector3(0.0, 0.0, 0.0),
        description = "A portable roulette table for gambling"
    }
}

-- Variables
local deployedRouletteTable = nil
local deployedOwner = nil
local currentRouletteTableData = nil

local function ShowRouletteTableMenu()
    local rouletteTableOptions = {}
    
    for i, rouletteTable in ipairs(ROULETTE_TABLE_PROPS) do
        table.insert(rouletteTableOptions, {
            title = rouletteTable.label,
            description = rouletteTable.description,
            icon = 'fas fa-dice',
            onSelect = function()
                TriggerEvent('rsg-roulette:client:placeRouletteTable', i)
            end
        })
    end

    lib.registerContext({
        id = 'roulettetable_selection_menu',
        title = 'Select Roulette Table',
        options = rouletteTableOptions
    })
    
    lib.showContext('roulettetable_selection_menu')
end

RegisterNetEvent('rsg-roulette:client:openRouletteTableMenu', function()
    ExecuteCommand('closeInv')
    
    CreateThread(function()
        Wait(500) 
        ShowRouletteTableMenu()
    end)
end)

local function RegisterRouletteTableTargeting()
    local models = {}
    for _, rouletteTable in ipairs(ROULETTE_TABLE_PROPS) do
        table.insert(models, rouletteTable.model)
    end

    exports['ox_target']:addModel(models, {
        {
            name = 'pickup_roulettetable',
            event = 'rsg-roulette:client:pickupRouletteTable',
            icon = "fas fa-hand",
            label = "Pick Up Roulette Table",
            distance = 2.0
        }
    })
end

RegisterNetEvent('rsg-roulette:client:placeRouletteTable', function(rouletteTableIndex)
    if deployedRouletteTable then
        lib.notify({
            title = "Roulette Table Already Placed",
            description = "You already have a roulette table placed.",
            type = 'error'
        })
        return
    end

    local rouletteTableData = ROULETTE_TABLE_PROPS[rouletteTableIndex]
    if not rouletteTableData then return end

    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local forward = GetEntityForwardVector(PlayerPedId())
    
    local offsetDistance = 2.0
    local x = coords.x + forward.x * offsetDistance
    local y = coords.y + forward.y * offsetDistance
    local z = coords.z

    print("ROULETTE: Requesting model: " .. rouletteTableData.model)
    RequestModel(rouletteTableData.model)
    while not HasModelLoaded(rouletteTableData.model) do
        Wait(100)
    end
    print("ROULETTE: Model loaded")

    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
    Wait(2000)
    
    print("ROULETTE: Creating table object")
    local rouletteTableObject = CreateObject(rouletteTableData.model, x, y, z, true, false, false)
    if not DoesEntityExist(rouletteTableObject) then
        print("ROULETTE: Failed to create table object")
        lib.notify({
            title = "Error",
            description = "Failed to create roulette table.",
            type = 'error'
        })
        ClearPedTasks(PlayerPedId())
        return
    end
    
    print("ROULETTE: Table object created: " .. rouletteTableObject)
    PlaceObjectOnGroundProperly(rouletteTableObject)
    SetEntityHeading(rouletteTableObject, heading)
    FreezeEntityPosition(rouletteTableObject, true)
    
    deployedRouletteTable = rouletteTableObject
    currentRouletteTableData = rouletteTableData
    deployedOwner = GetPlayerServerId(PlayerId())
    
    TriggerServerEvent('rsg-roulette:server:placeRouletteTable')
    print("ROULETTE: Table placed successfully")
    
    Wait(500)
    ClearPedTasks(PlayerPedId())
    
    -- Create the roulette wheel on top of the table
    local wheelCoords = GetEntityCoords(rouletteTableObject)
    wheelCoords = vector3(wheelCoords.x, wheelCoords.y, wheelCoords.z + 1.0)
    
    print("ROULETTE: Creating wheel object")
    local rouletteWheel = CreateObject(`p_roulette_wheel01x`, wheelCoords, true, false, false)
    if not DoesEntityExist(rouletteWheel) then
        print("ROULETTE: Failed to create wheel object")
        return
    end
    
    SetEntityHeading(rouletteWheel, heading)
    FreezeEntityPosition(rouletteWheel, true)
    
    -- Attach the wheel to the table
    AttachEntityToEntity(rouletteWheel, rouletteTableObject, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    print("ROULETTE: Wheel attached to table")
    
    lib.notify({
        title = 'Roulette Table Placed',
        description = 'You have placed your roulette table.',
        type = 'success'
    })
end)

RegisterNetEvent('rsg-roulette:client:pickupRouletteTable', function()
    if not deployedRouletteTable then
        lib.notify({
            title = "No Roulette Table!",
            description = "There's no roulette table to pick up.",
            type = 'error'
        })
        return
    end

    print("ROULETTE: Attempting to pick up table")
    local ped = PlayerPedId()
    
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
    Wait(2000)

    if deployedRouletteTable then
        -- Delete the roulette wheel and table
        local children = GetAttachedObjects(deployedRouletteTable)
        for _, child in ipairs(children) do
            print("ROULETTE: Deleting attached object: " .. child)
            DeleteObject(child)
        end
        
        print("ROULETTE: Deleting table: " .. deployedRouletteTable)
        DeleteObject(deployedRouletteTable)
        deployedRouletteTable = nil
        currentRouletteTableData = nil
        TriggerServerEvent('rsg-roulette:server:returnRouletteTable')
        deployedOwner = nil
    end

    ClearPedTasks(ped)
    
    lib.notify({
        title = 'Roulette Table Picked Up',
        description = 'You have picked up your roulette table.',
        type = 'success'
    })
end)

-- Function to get all objects attached to an entity
function GetAttachedObjects(entity)
    local attachedObjects = {}
    local entities = GetGamePool('CObject')
    
    for _, object in ipairs(entities) do
        if DoesEntityExist(object) and IsEntityAttachedToEntity(object, entity) then
            table.insert(attachedObjects, object)
        end
    end
    
    return attachedObjects
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if deployedRouletteTable then
        -- Delete the roulette wheel and table
        local children = GetAttachedObjects(deployedRouletteTable)
        for _, child in ipairs(children) do
            DeleteObject(child)
        end
        
        DeleteObject(deployedRouletteTable)
    end
end)

CreateThread(function()
    print("ROULETTE: Registering table targeting")
    RegisterRouletteTableTargeting()
end)