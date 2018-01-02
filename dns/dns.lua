local dns_api = require('./dns_lib')
local component = require('component')
local shell = require('shell')

local args = shell.parse(...)

if not component.isAvailable("modem") then
  io.stderr:write("This program requires a network card to run.")
  return
end

if #args < 2 then
  io.write("Usage: dns <get|set> <name> [<address>]\n")
  return
end

if args[1] == "set" and #args < 3 then
  io.write("Usage: dns set <name> <address>\n")
  return
end

if args[1] == "get" then
  local name = args[2]
  address, success = dns_api.get(name)
  if success then
    print(name .. " has address " .. address)
  else
    print(name .. " could not be found")
  end
  elseif args[1] == "set" then
    local name = args[2]
    local address = args[3]
    success = dns_api.put(name, address)
    if success then
      print("Record successfully added")
    else
      print("Failed to add record\nCheck network connection & ensure name is not unavailable.")
    end
  else
    io.write("Usage: dns <get|set> <name> [<address>]\n")
  end


