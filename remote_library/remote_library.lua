local component = require('component')
local event = require('event')
local serialise = require('serialization')
local fs = require('filesystem')

local modem = component.modem

local libraries = {}

function initTables()
  if not fs.isDirectory('/etc') then fs.makeDirectory('/etc') end
  if fs.exists("/etc/libraries.cfg") then
    fileData = io.open("/etc/libraries.cfg")
    libraries = serialise.unserialize(fileData:read())
    fileData:close()
  end
end

function listen()
  local msg_name, _, sender, _, _, data = event.pull("modem_message")
  local msg = serialise.unserialize(data)

  -- Port to reply over
  local reply_port = msg.reply_port or 1
  local lib_name = msg.name

  local file_location = libraries[lib_name]
  if file_location == nil then
    modem.send(sender, reply_port, serialise.serialize({ success = false }))
    return
  end

  lib_file = io.open(file_location)
  lib_data = lib_file:read()
  lib_file:close()

  if lib_data:len() < 8192 then
    modem.send(sender, reply_port, serialise.serialize({ success = true, data = lib_data }))
    print("Transmitted library " .. lib_name)
  else
    modem.send(sender, reply_port, serialise.serialize({ success = false }))
    print("Library " .. lib_name .. " > 8192 bytes")
  end
end

running = true

initTables()

if not modem.isOpen(20) then
  print("Opening port 20")
  modem.open(20)
else
  print("Port 20 already open")
end

while running do
  listen()
end
