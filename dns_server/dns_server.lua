local component = require('component')
local event = require('event')
local serialise = require('serialization')
local fs = require('filesystem')

local modem = component.modem

local resp_codes = {
  success = 0,
  not_found = 1,
  bad_request = 2,
  already_exists = 3,
}

local dnsList = {}
local dnsCount = 0

function initTables()
  if not fs.isDirectory('/etc') then fs.makeDirectory('/etc') end
  if fs.exists("/etc/dns_names.cfg") then
    fileData = io.open("/etc/dns_names.cfg")
    dnsList = serialise.unserialize(fileData:read())
    fileData:close()
    dnsCount = #dnsList
  end
end

function saveTables()
  local file = io.open("/etc/dns_names.cfg", "w")
  file:write(serialise.serialize(dnsList))
  file:close()
end

function addRecord(name, address)
  if dnsList == nil then
    dnsList = {}
    dnsCount = 0
  end

  for i = 1, #dnsList do
    if dnsList[i]["name"]:lower() == name:lower() then
      print("Name collision : " .. name:lower() .. " already exists")
      return false
    end
  end

  dnsList[#dnsList+1] = {
    name = name,
    address = address,
  }

  return true
end

function addressLookup(name)
  for i = 1, #dnsList do
    -- Match case-insensitively
    if dnsList[i]["name"]:lower() == name:lower() then
      return dnsList[i]["address"]
    end
  end

  return nil
end

function listen()
  if not modem.isOpen(1) then
    print("Opening port 1")
    modem.open(1)
  end

  local msg_name, _, sender, _, _, data = event.pull("modem_message")
  local msg = serialise.unserialize(data)

  -- Port to reply over
  local reply_port = msg.reply_port or 1

  if msg.action == "get" then
    if msg.name ~= nil then
      local addr = addressLookup(msg.name)
      if addr ~= nil then
        modem.send(sender, reply_port, serialise.serialize({ resp = resp_codes.success, address = addr }))

        print("get (" .. sender .. ") " .. resp_codes.success .. " \"" .. msg.name .. "\"" .. " " .. addr)
      else
        modem.send(sender, reply_port, serialise.serialize({ resp = resp_codes.not_found }))

        print("get (" .. sender .. ") " .. resp_codes.not_found)
      end
    else
      -- Invalid request
      modem.send(sender, reply_port, serialise.serialize({ resp = resp_codes.bad_request }))

      print("get (" .. sender .. ") " .. resp_codes.bad_request)
    end
  end

  if msg.action == "put" then
    if msg.name ~= nil and msg.address ~= nil then
      local success = addRecord(msg.name, msg.address)
      if success == true then
        modem.send(sender, reply_port, serialise.serialize({ resp = resp_codes.success }))

        print("put (" .. sender .. ") " .. resp_codes.success .. " \"" .. msg.name .. "\"" .. " " .. msg.address)

        saveTables()
      else
        modem.send(sender, reply_port, serialise.serialize({ resp = resp_codes.already_exists }))

        print("put (" .. sender .. ") " .. resp_codes.already_exists)
      end
    else
      -- Invalid request
      modem.send(sender, reply_port, serialise.serialize({ resp = resp_codes.bad_request }))

      print("put (" .. sender .. ") " .. resp_codes.bad_request)
    end
  end
end

running = true

initTables()

while running do
  listen()
end
