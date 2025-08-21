-- FX Information
fx_version 'adamant'
lua54 'yes'

game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

-- Resource Information
name 'ox_target'
version '1.0.0'
description ''


shared_scripts {
	'@frp_lib/library/linker.lua',
	'@ox_lib/init.lua',
}

client_scripts {
	'client/api.lua',
	'client/utils.lua',
	'client/framework/frp.lua',

	'client/state.lua',
	'client/models.lua',
	'client/main.lua',
	
	'client/defaults.lua',
}

server_scripts {
	'server/main.lua'
}

files {
	'nui/build/**/*',
}

ui_page 'nui/build/index.html'

dependency 'frp_lib'
dependency 'ox_lib'
