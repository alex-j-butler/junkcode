local red = component.proxy(component.list("redstone")())
local modem = component.proxy(component.list("modem")())

math.randomseed(os.time())

local serialization = {}
local api = {}

function serialization.unserialize(data)
  checkArg(1, data, "string")
  local result, reason = load("return " .. data, "=data", nil, {math={huge=math.huge}})
  if not result then
    return nil, reason
  end
  local ok, output = pcall(result)
  if not ok then
    return nil, output
  end
  return output
end

function api.get(name, timeout)
  timeout = timeout or 5
  local port = math.random(1024, 4096)
  while modem.isOpen(port) do
    port = math.random(1024, 4096)
  end
  modem.open(port)
  modem.broadcast(1, "{action=\"get\",name=\"" .. name .. "\",reply_port=" .. port .. "}")

  count = 0
  local msg_name, _, sender, _, _, data
  repeat msg_name, _, sender, _, _, data = computer.pullSignal(0.5) count = count + 1
    until msg_name == "modem_message" or count > timeout * 2
  if data == nil then
    return nil, false
  end
  resp_data = serialization.unserialize(data)
  modem.close(port)

  return resp_data.address, resp_data.resp == 0
end

function load_lib(name)
  addr, success = api.get("remote_library")
  if success then
    local port = 0
    repeat port = math.random(1024, 4096)
      until not modem.isOpen(port)

    modem.open(port)
    modem.send(addr, 20, "{name=\"" .. name .. "\",reply_port=" .. port .. "}")

    count = 0
    local msg_name, _, sender, _, _, data
      repeat msg_name, _, sender, _, _, data = computer.pullSignal(0.5) count = count + 1
    until msg_name == "modem_message" or count > 10

    if data ~= nil then
      u = serialization.unserialize(data)
      if u.success then
        return load(u.data, "=" .. name)()
      end

      return nil
    end
  end

  return nil
end

-- Load the global libraries
local event = load_lib("event_global")
local os = load_lib("os_global")

if not event or not os then
  error("core libraries could not be loaded")
  return
end

while true do

  red.setOutput(0, 15)
  os.sleep(2)
  red.setOutput(0, 0)
  os.sleep(2)

end
