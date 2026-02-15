fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'renzu_tuners'
author 'Renzu + QBCore Integration'
description 'QBCore mechanic-only tuning, dyno, repair and upgrade integration'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib',
    'qb-target'
}
