local component = require('component')
local math = require('math')
local serialise = require('serialization')
local event = require('event')
local modem = component.modem

-- Seed the random generator
math.randomseed(os.time())

local api = {}

function api.get(name)
  -- Generate a random reply port
  local port = math.random(1024, 4096)
  while modem.isOpen(port) do
    port = math.random(1024, 4096)
  end

  modem.open(port)
  modem.broadcast(1, serialise.serialize({ action = "get", name = name, reply_port = port }))

  local msg_name, _, sender, _, _, data = event.pull("modem_message")
  resp_data = serialise.unserialize(data)

  modem.close(port)

  return resp_data.address, resp_data.resp == 0

end

function api.put(name, address)
  -- Generate a random reply port
  local port = math.random(1024, 4096)
  while modem.isOpen(port) do
    port = math.random(1024, 4096)
  end

  modem.open(port)
  modem.broadcast(1, serialise.serialize({ action = "put", name = name, address = address, reply_port = port }))

  local msg_name, _, sender, _, _, data = event.pull("modem_message")
  resp_data = serialise.unserialize(data)

  modem.close(port)

  return resp_data.resp == 0

end

return api
