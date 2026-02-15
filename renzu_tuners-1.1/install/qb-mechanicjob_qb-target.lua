-- qb-mechanicjob/client/main.lua addition (qb-target)
-- Paste this near your other target registration calls.

CreateThread(function()
    exports['qb-target']:AddBoxZone('mechanic_tuner_bench', vec3(-338.84, -136.74, 39.01), 1.6, 1.2, {
        name = 'mechanic_tuner_bench',
        heading = 70.0,
        debugPoly = false,
        minZ = 38.2,
        maxZ = 39.9,
    }, {
        options = {
            {
                icon = 'fas fa-microchip',
                label = 'Mechanic: Open Tuner Bench',
                event = 'renzu_tuners:client:openBench',
                canInteract = function()
                    local PlayerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
                    return PlayerData.job and PlayerData.job.name == 'mechanic'
                end
            }
        },
        distance = 2.0,
    })

    exports['qb-target']:AddBoxZone('mechanic_dyno_station', vec3(-362.50, -117.68, 39.08), 1.8, 2.2, {
        name = 'mechanic_dyno_station',
        heading = 160.0,
        debugPoly = false,
        minZ = 38.3,
        maxZ = 40.0,
    }, {
        options = {
            {
                icon = 'fas fa-gauge-high',
                label = 'Mechanic: Open Dyno Workstation',
                event = 'renzu_tuners:client:openDyno',
                canInteract = function()
                    local PlayerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
                    return PlayerData.job and PlayerData.job.name == 'mechanic'
                end
            }
        },
        distance = 2.0,
    })
end)
