fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tw_zombies'
author 'The Walking RP'
description 'Foundational zombie gameplay resource for QBX servers.'
version '1.0.0'

shared_script '@ox_lib/init.lua'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'locales/*.json'
}

dependencies {
    'qbx_core',
    'ox_lib'
}
