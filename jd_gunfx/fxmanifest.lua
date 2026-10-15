fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jd_gunfx'
author 'JD Development & Designs'
description 'Gunfire hearing ring, near-miss bullet whizz and suppression screen shake'
version '1.0.0'

ui_page 'html/index.html'

shared_script 'config.lua'
client_script 'client.lua'

files {
    'html/index.html',
    'html/script.js',
    'html/sounds/*'
}
