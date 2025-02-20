fx_version 'cerulean'
games { 'rdr3', 'gta5' }
lua54 'yes'
author 'Satria Adhi'
description 'FiveM Global Banned'
version '1.0.0'

server_scripts {
  'server/config.lua',
  'server/gbanhash.lua',
  'server/main.lua',
}

client_scripts {
  'client/warmenu.lua',
  'client/main.lua',
}

escrow_ignore {
  'server/*.lua',
  'client/*.lua',
  'README.md',
}