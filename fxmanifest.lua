fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'futrdesigns'
description 'Simple HUD with Player Info'
version '1.0.3'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

files {
    'html/index.html',
    'html/assets/css/*.css',
    'html/assets/js/*.js',
    'html/assets/img/*'
}

ui_page 'html/index.html'
