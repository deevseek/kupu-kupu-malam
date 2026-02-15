local QBCore = exports['qb-core']:GetCoreObject()

local function notify(src, msg, typ)
    TriggerClientEvent('QBCore:Notify', src, msg, typ or 'primary')
end

local function isMechanic(Player)
    if not Player or not Player.PlayerData or not Player.PlayerData.job then
        return false
    end

    local job = Player.PlayerData.job
    if not Config.AllowedJobs[job.name] then
        return false
    end

    if Config.RequireOnDuty and not job.onduty then
        return false
    end

    return true
end

local function tableName()
    return Config.Database.table
end

CreateThread(function()
    MySQL.query(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `plate` varchar(16) NOT NULL,
            `citizenid` varchar(60) NOT NULL,
            `data` longtext DEFAULT NULL,
            `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`plate`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(tableName()))
end)

local function getPrice(action, vehicleClass)
    local basePrice = Config.ActionPrices[action] or 0
    local multiplier = Config.ClassMultiplier[vehicleClass] or 1.0
    return math.floor(basePrice * multiplier)
end

local function hasItem(src, item, amount)
    amount = amount or 1

    if GetResourceState('ox_inventory') == 'started' and Config.Inventory.prefer ~= 'qb' then
        return (exports.ox_inventory:GetItemCount(src, item) or 0) >= amount
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local invItem = Player.Functions.GetItemByName(item)
    return invItem and invItem.amount >= amount
end

local function removeItem(src, item, amount)
    amount = amount or 1

    if GetResourceState('ox_inventory') == 'started' and Config.Inventory.prefer ~= 'qb' then
        return exports.ox_inventory:RemoveItem(src, item, amount)
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    return Player.Functions.RemoveItem(item, amount)
end

local function chargeBank(src, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 'Player not found.' end

    local bank = Player.PlayerData.money.bank or 0
    if bank < amount then
        return false, ('Insufficient bank balance. Required $%s'):format(amount)
    end

    local success = Player.Functions.RemoveMoney('bank', amount, 'renzu-tuners-service')
    if not success then
        return false, 'Unable to process payment.'
    end

    return true
end

local function validateVehicleEntity(src, netId)
    if type(netId) ~= 'number' then
        return false, 'Invalid vehicle reference.'
    end

    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then
        return false, 'Vehicle does not exist.'
    end

    local ped = GetPlayerPed(src)
    if ped == 0 then
        return false, 'Invalid player state.'
    end

    local playerCoords = GetEntityCoords(ped)
    local vehCoords = GetEntityCoords(veh)
    if #(playerCoords - vehCoords) > 20.0 then
        return false, 'You are too far away from the vehicle.'
    end

    return true, veh
end

local function fetchVehicleData(plate)
    local row = MySQL.single.await(('SELECT `data` FROM `%s` WHERE plate = ?'):format(tableName()), {plate})
    if not row or not row.data then
        return { stage = 0, ecu_tune = 0.0, health = 1000.0 }
    end

    local data = json.decode(row.data) or {}
    data.stage = tonumber(data.stage) or 0
    data.ecu_tune = tonumber(data.ecu_tune) or 0.0
    data.health = tonumber(data.health) or 1000.0
    return data
end

local function saveVehicleData(plate, citizenid, data)
    MySQL.update.await(([[
        INSERT INTO `%s` (plate, citizenid, data)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE citizenid = VALUES(citizenid), data = VALUES(data)
    ]]):format(tableName()), {plate, citizenid, json.encode(data)})
end

QBCore.Functions.CreateCallback('renzu_tuners:server:getTuneData', function(_, cb, plate)
    if type(plate) ~= 'string' or plate == '' then
        cb(nil)
        return
    end

    cb(fetchVehicleData(plate))
end)

QBCore.Functions.CreateCallback('renzu_tuners:server:performAction', function(src, cb, payload)
    local Player = QBCore.Functions.GetPlayer(src)
    if not isMechanic(Player) then
        cb({ ok = false, msg = 'Mechanic job required.' })
        return
    end

    if type(payload) ~= 'table' then
        cb({ ok = false, msg = 'Invalid request.' })
        return
    end

    local action = payload.action
    local plate = tostring(payload.plate or ''):upper()
    local class = tonumber(payload.class) or 0
    local netId = tonumber(payload.netId)

    if action == nil or plate == '' or not netId then
        cb({ ok = false, msg = 'Missing action data.' })
        return
    end

    local validVeh, vehOrMsg = validateVehicleEntity(src, netId)
    if not validVeh then
        cb({ ok = false, msg = vehOrMsg })
        return
    end

    local vehicle = vehOrMsg
    if GetVehicleNumberPlateText(vehicle):gsub('%s+', ''):upper() ~= plate:gsub('%s+', ''):upper() then
        cb({ ok = false, msg = 'Vehicle/plate mismatch detected.' })
        return
    end

    local requiredItem
    local itemAmount = 1

    if action == 'ecu_tune' then
        requiredItem = Config.Items.ecu
    elseif action == 'repair' then
        requiredItem = Config.Items.repair
    elseif action == 'stage_1' then
        requiredItem = Config.Items.stages[1]
    elseif action == 'stage_2' then
        requiredItem = Config.Items.stages[2]
    elseif action == 'stage_3' then
        requiredItem = Config.Items.stages[3]
    elseif action ~= 'check' and action ~= 'dyno' then
        cb({ ok = false, msg = 'Unknown action requested.' })
        return
    end

    if requiredItem and not hasItem(src, requiredItem, itemAmount) then
        cb({ ok = false, msg = ('Missing required item: %s'):format(requiredItem) })
        return
    end

    local price = getPrice(action, class)
    local paid, payReason = chargeBank(src, price)
    if not paid then
        cb({ ok = false, msg = payReason })
        return
    end

    if requiredItem then
        removeItem(src, requiredItem, itemAmount)
    end

    local tuneData = fetchVehicleData(plate)

    if action == 'ecu_tune' then
        tuneData.ecu_tune = math.min(0.25, (tonumber(tuneData.ecu_tune) or 0.0) + 0.05)
    elseif action == 'repair' then
        tuneData.health = 1000.0
    elseif action == 'stage_1' then
        tuneData.stage = math.max(tuneData.stage, 1)
    elseif action == 'stage_2' then
        tuneData.stage = math.max(tuneData.stage, 2)
    elseif action == 'stage_3' then
        tuneData.stage = math.max(tuneData.stage, 3)
    end

    saveVehicleData(plate, Player.PlayerData.citizenid, tuneData)

    cb({ ok = true, msg = ('Service completed. Charged $%s.'):format(price), price = price, data = tuneData })
end)

RegisterNetEvent('renzu_tuners:server:saveVehicleState', function(plate, netId, engineHealth)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not isMechanic(Player) then return end

    local validVeh = validateVehicleEntity(src, tonumber(netId))
    if not validVeh then return end

    plate = tostring(plate or ''):upper()
    if plate == '' then return end

    local data = fetchVehicleData(plate)
    data.health = tonumber(engineHealth) or data.health
    saveVehicleData(plate, Player.PlayerData.citizenid, data)
end)

RegisterNetEvent('renzu_tuners:server:notify', function(msg, typ)
    notify(source, msg, typ)
end)
