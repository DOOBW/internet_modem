local internet = require('component').internet
local computer = require('computer')

local imodem = {}

-------------------------------------------------------------------------------

imodem.server = 'irc.esper.net'
imodem.port = 6667
imodem.channel = '#imodem'
imodem.nick = 'x'..internet.address:sub(1, 8)

local socket
local delay = 0.8
local lastTime = computer.uptime()
local lastPing = lastTime
local isConnected = false

imodem.isOnline = function()
  if isConnected and
     socket and
     socket.finishConnect() and
     computer.uptime()-lastPing < 65 then
    return true
  else
    return false
  end
end

imodem.connect = function()
  if socket then socket.close() end
  socket, reason = internet.connect(imodem.server, imodem.port)
  if not socket then
    return reason
  end
  return true
end

imodem.disconnect = function()
  if socket then
    imodem.send_raw('QUIT')
    socket.close()
  end
  if isConnected then
    isConnected = false
  end
  return true
end

imodem.send_raw = function(message)
  if socket then
    socket.write(message..'\r\n')
    return true
  else
    return false
  end
end

imodem.broadcast = function(message)
  if socket and imodem.channel then
    imodem.send_raw('PRIVMSG '..imodem.channel..' :'..message)
    return true
  else
    return false
  end
end

imodem.send = function(target, message)
  if socket and target and message then
    imodem.send_raw('PRIVMSG '..target..' :'..message)
    return true
  else
    return false
  end
end

if not package.loaded.imodem then
  local pullSignal = computer.pullSignal
  computer.pullSignal = function(...)
    local e = {pullSignal(...)}

    if isConnected and e[1] == 'internet_ready' then
      local line = socket.read()
      if line and line ~= '' then
        lastPing = computer.uptime()
        local ok, prefix = line:match('^(:(%S+) )')
        if prefix then prefix = prefix:match('^[^!]+') end
        if ok then line = line:sub(#ok+1) end
        local ok, command = line:match('^(([^:]%S*))')
        if ok then line = line:sub(#ok+1) end
        local ok, source = line:match('^( ([^:]%S*))')
        if ok then line = line:sub(#ok+1) end
        repeat
          ok = line:match('^( ([^:]%S*))')
          if ok then line = line:sub(#ok+1) end
        until not ok
        local message = line:match('^ :(.*)$')
        if (command == '001' or command == '404') and imodem.channel then
          imodem.send_raw('JOIN '..imodem.channel)
        elseif command == '433' or command == '436' then
          imodem.nick = imodem.nick..string.char(math.random(97,122))
          imodem.send_raw('NICK '..imodem.nick)
        elseif command == 'PING' then
          imodem.send_raw('PONG :'..message)
        elseif command == 'PONG' then
          lastPing = computer.uptime()
        elseif command == 'PRIVMSG' then
          computer.pushSignal('modem_message', imodem.nick, prefix, source, 0, message)
        end
      end
    end

    if delay < computer.uptime()-lastTime then

      if not isConnected and socket and socket.finishConnect() then
        isConnected = true
        imodem.send_raw('USER '..imodem.nick..' . . :'..imodem.nick)
        imodem.send_raw('NICK '..imodem.nick)
      end

      if isConnected then
        if computer.uptime()-lastPing > 60 then
          imodem.send_raw('PING :'..imodem.nick)
        end
        if not socket or 
        (socket and not socket.finishConnect()) or
        computer.uptime()-lastPing > 90 then
          isConnected = false
          imodem.connect()
        end
      end

      lastTime = computer.uptime()
    end

    return table.unpack(e)
  end
end

-------------------------------------------------------------------------------

return imodem
