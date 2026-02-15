fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'twta-zombies'
author 'The Walking RP'
description 'Zombie interactions with ox_target, ox_inventory, and ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
