Config = {}

Config.Debug = false
Config.RequireOnDuty = false
Config.AllowedJobs = {
    mechanic = true,
}

Config.Inventory = {
    prefer = 'ox', -- ox | qb | auto
}

Config.Database = {
    table = 'renzu_tuners_qb',
}

Config.MechanicZones = {
    {
        id = 'renzu_tuner_bench_lsc',
        label = 'Open Tuner Bench',
        icon = 'fas fa-microchip',
        coords = vec3(-338.84, -136.74, 39.01),
        size = vec3(1.6, 1.2, 1.8),
        heading = 70.0,
        menu = 'bench',
    },
    {
        id = 'renzu_dyno_lsc',
        label = 'Use Dyno Workstation',
        icon = 'fas fa-gauge-high',
        coords = vec3(-362.50, -117.68, 39.08),
        size = vec3(1.8, 2.2, 1.8),
        heading = 160.0,
        menu = 'dyno',
    }
}

Config.Items = {
    ecu = 'ecu',
    stages = {
        [1] = 'elite_tuner_kit',
        [2] = 'pro_tuner_kit',
        [3] = 'ultimate_tuner_kit',
    },
    repair = 'repairparts',
}

Config.ActionPrices = {
    check = 250,
    dyno = 500,
    ecu_tune = 1500,
    repair = 1200,
    stage_1 = 4500,
    stage_2 = 9000,
    stage_3 = 16000,
}

Config.ClassMultiplier = {
    [0] = 1.00, -- compacts
    [1] = 1.00, -- sedans
    [2] = 1.05, -- suvs
    [3] = 1.10, -- coupes
    [4] = 1.15, -- muscle
    [5] = 1.25, -- sports classics
    [6] = 1.35, -- sports
    [7] = 1.50, -- super
    [8] = 0.90, -- motorcycles
    [9] = 0.90, -- offroad
    [10] = 1.10, -- industrial
    [11] = 1.10, -- utility
    [12] = 1.10, -- vans
    [13] = 1.00, -- cycles
    [14] = 0.80, -- boats
    [15] = 0.80, -- helicopters
    [16] = 0.80, -- planes
    [17] = 1.20, -- service
    [18] = 1.10, -- emergency
    [19] = 1.15, -- military
    [20] = 1.15, -- commercial
    [21] = 1.30, -- trains
}

Config.StagePowerMultiplier = {
    [0] = 0.0,
    [1] = 8.0,
    [2] = 14.0,
    [3] = 22.0,
}

Config.ItemDefinitions = {
    qb = {
        ecu = { name = 'ecu', label = 'Standalone ECU', weight = 700, type = 'item', image = 'ecu.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'Programmable standalone ECU for custom tuning.' },
        elite_tuner_kit = { name = 'elite_tuner_kit', label = 'Stage 1 Engine Kit', weight = 1200, type = 'item', image = 'engine.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'Entry stage engine upgrade kit.' },
        pro_tuner_kit = { name = 'pro_tuner_kit', label = 'Stage 2 Engine Kit', weight = 1500, type = 'item', image = 'racing_block.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'Performance stage engine upgrade kit.' },
        ultimate_tuner_kit = { name = 'ultimate_tuner_kit', label = 'Stage 3 Engine Kit', weight = 2000, type = 'item', image = 'ultimate_block.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'Highest performance stage engine upgrade kit.' },
        repairparts = { name = 'repairparts', label = 'Engine Repair Parts', weight = 900, type = 'item', image = 'repairparts.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'Replacement engine components for mechanical repair.' },
    },
    ox = {
        {'ecu', 'Standalone ECU', 700, 'Standalone ECU for tuning.'},
        {'elite_tuner_kit', 'Stage 1 Engine Kit', 1200, 'Entry stage engine upgrade kit.'},
        {'pro_tuner_kit', 'Stage 2 Engine Kit', 1500, 'Performance stage engine upgrade kit.'},
        {'ultimate_tuner_kit', 'Stage 3 Engine Kit', 2000, 'Highest stage engine upgrade kit.'},
        {'repairparts', 'Engine Repair Parts', 900, 'Replacement engine components for repairs.'},
    }
}
