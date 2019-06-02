_G.imodem = {}
imodem.channel = '#imodem'
local server = 'irc.esper.net:6667'
local internet = require('internet')
local computer = require('computer')
local event = require('event')
local nick = 'x'..require('component').internet.address:sub(1, 8)
local socket

local function login()
  if socket then socket:close() end
  socket = internet.open(server)
  socket:setTimeout(0.05)
  imodem.send_raw('USER '..nick..' 0 * :'..nick)
  imodem.send_raw('NICK '..nick)
end

imodem.send_raw = function(message)
  socket:write(message..'\r\n')
  socket:flush()
end

imodem.broadcast = function(message)
  if socket and imodem.channel then
    imodem.send_raw('PRIVMSG '..imodem.channel..' :'..message)
    return true
  else
    return false
  end
end

imodem.send = function(receiver, message)
  if socket and receiver and message then
    imodem.send_raw('PRIVMSG '..receiver..' :'..message)
    return true
  else
    return false
  end
end

imodem.stop = function()
  if imodem.timer then
    if socket then
      imodem.send_raw('QUIT')
      socket:close()
    end
    event.cancel(imodem.timer)
    imodem = nil
  end
end

imodem.timer = event.timer(0.5, function()
  if not socket then login() end
  repeat
    local ok, line = pcall(socket.read, socket)
    if ok then
      if not line then login() end
      local match, prefix = line:match('^(:(%S+) )')
      if prefix then prefix = prefix:match('^[^!]+') end
      if match then line = line:sub(#match+1) end
      local match, command = line:match('^(([^:]%S*))')
      if match then line = line:sub(#match+1) end
      repeat
        local match = line:match('^( ([^:]%S*))')
        if match then
          line = line:sub(#match+1)
        end
      until not match
      local message = line:match('^ :(.*)$')
      if command == '001' or command == '404' then
        imodem.send_raw('JOIN '..imodem.channel)
      elseif command == '433' or command == '436' then
        nick = nick..string.char(math.random(97,122))
        imodem.send_raw('NICK '..nick)
      elseif command == 'PING' then
        imodem.send_raw('PONG :'..message)
      elseif command == 'PRIVMSG' then
        computer.pushSignal('modem_message', nick, prefix, 0, 0, message)
      end
    end
  until not ok
end, math.huge)
