local QBCore = exports['qb-core']:GetCoreObject()

local function isMechanic()
    local data = QBCore.Functions.GetPlayerData()
    if not data or not data.job then return false end

    if not Config.AllowedJobs[data.job.name] then
        return false
    end

    if Config.RequireOnDuty and not data.job.onduty then
        return false
    end

    return true
end

local function notify(msg, typ)
    QBCore.Functions.Notify(msg, typ or 'primary')
end

local function getVehicleForMenu()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        vehicle = QBCore.Functions.GetClosestVehicle(GetEntityCoords(ped))
        if vehicle == 0 or #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > 5.0 then
            return nil
        end
    end

    return vehicle
end

local function applyTuneToVehicle(vehicle, data)
    if vehicle == 0 or not DoesEntityExist(vehicle) or type(data) ~= 'table' then
        return
    end

    local stage = tonumber(data.stage) or 0
    local ecuTune = tonumber(data.ecu_tune) or 0.0
    local health = tonumber(data.health) or 1000.0

    SetVehicleModKit(vehicle, 0)

    local maxEngineMod = GetNumVehicleMods(vehicle, 11) - 1
    if maxEngineMod >= 0 then
        local target = math.min(maxEngineMod, stage)
        SetVehicleMod(vehicle, 11, target, false)
    end

    local powerMult = (Config.StagePowerMultiplier[stage] or 0.0) + (ecuTune * 100.0)
    SetVehicleEnginePowerMultiplier(vehicle, powerMult)
    SetVehicleEngineTorqueMultiplier(vehicle, 1.0 + ecuTune)

    if health > 0 then
        SetVehicleEngineHealth(vehicle, health)
    end
end

local function requestAction(action)
    if not isMechanic() then
        notify('Only mechanics can use tuner workstations.', 'error')
        return
    end

    local veh = getVehicleForMenu()
    if not veh then
        notify('No vehicle nearby.', 'error')
        return
    end

    local plate = QBCore.Functions.GetPlate(veh)
    local class = GetVehicleClass(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)

    local response = lib.callback.await('renzu_tuners:server:performAction', false, {
        action = action,
        plate = plate,
        class = class,
        netId = netId,
    })

    if not response or not response.ok then
        notify((response and response.msg) or 'Action failed.', 'error')
        return
    end

    if action == 'dyno' then
        local stage = tonumber(response.data.stage) or 0
        local tune = tonumber(response.data.ecu_tune) or 0.0
        local hp = math.floor(180 + (stage * 50) + (tune * 400))
        local tq = math.floor(200 + (stage * 60) + (tune * 450))
        notify(('Dyno complete | HP: %s | TQ: %s | Cost: $%s'):format(hp, tq, response.price), 'success')
    else
        notify(response.msg, 'success')
    end

    applyTuneToVehicle(veh, response.data)

    if action == 'repair' then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
    end

    TriggerServerEvent('renzu_tuners:server:saveVehicleState', plate, netId, GetVehicleEngineHealth(veh))
end

local function openMainMenu(sourceLabel)
    if not isMechanic() then
        notify('Only mechanics can access this workstation.', 'error')
        return
    end

    lib.registerContext({
        id = 'renzu_tuner_main',
        title = ('Renzu Tuners - %s'):format(sourceLabel or 'Workbench'),
        options = {
            { title = 'Vehicle Health Check', description = 'Check and save current vehicle state.', icon = 'stethoscope', onSelect = function() requestAction('check') end },
            { title = 'Dyno Run', description = 'Run dyno graph and show output numbers.', icon = 'gauge-high', onSelect = function() requestAction('dyno') end },
            { title = 'ECU Tune', description = 'Apply a standalone ECU tune increment.', icon = 'microchip', onSelect = function() requestAction('ecu_tune') end },
            { title = 'Install Stage 1', description = 'Uses item: ' .. Config.Items.stages[1], icon = 'wrench', onSelect = function() requestAction('stage_1') end },
            { title = 'Install Stage 2', description = 'Uses item: ' .. Config.Items.stages[2], icon = 'wrench', onSelect = function() requestAction('stage_2') end },
            { title = 'Install Stage 3', description = 'Uses item: ' .. Config.Items.stages[3], icon = 'wrench', onSelect = function() requestAction('stage_3') end },
            { title = 'Repair Engine', description = 'Uses item: ' .. Config.Items.repair, icon = 'toolbox', onSelect = function() requestAction('repair') end },
        }
    })

    lib.showContext('renzu_tuner_main')
end

RegisterNetEvent('renzu_tuners:client:openBench', function()
    openMainMenu('Tuner Bench')
end)

RegisterNetEvent('renzu_tuners:client:openDyno', function()
    openMainMenu('Dyno Workstation')
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(500) end

    for _, zone in ipairs(Config.MechanicZones) do
        local evt = zone.menu == 'dyno' and 'renzu_tuners:client:openDyno' or 'renzu_tuners:client:openBench'

        exports['qb-target']:AddBoxZone(zone.id, zone.coords, zone.size.x, zone.size.y, {
            name = zone.id,
            heading = zone.heading,
            debugPoly = Config.Debug,
            minZ = zone.coords.z - (zone.size.z / 2),
            maxZ = zone.coords.z + (zone.size.z / 2),
        }, {
            options = {
                {
                    event = evt,
                    icon = zone.icon,
                    label = zone.label,
                    canInteract = function()
                        return isMechanic()
                    end,
                }
            },
            distance = 2.0,
        })
    end
end)

local lastPlate
CreateThread(function()
    while true do
        Wait(1500)

        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            local plate = QBCore.Functions.GetPlate(veh)
            if plate and plate ~= lastPlate then
                local tuneData = lib.callback.await('renzu_tuners:server:getTuneData', false, plate)
                if tuneData then
                    applyTuneToVehicle(veh, tuneData)
                end
                lastPlate = plate
            end
        else
            lastPlate = nil
        end
    end
end)
