# internet_modem
Modem over IRC for OpenComputers

Allows to create a bridge using the IRC server. Messages from an IRC server converts into a signal 'modem_message'.

The signal from the server looks like this:

*localAddress: string, remoteAddress: string, source: string, distance: number, message: string*

If the message is received from the channel, then: *imodem.nick, sender_nickname, #channel_name, 0, message*

if a private message is received from an user: *imodem.nick, sender_nickname, imodem.nick, 0, message*

## Variables
**imodem.server** *:string* - IRC server address to which library are connecting (default 'irc.esper.net')

**imodem.port** *:number* - IRC server port (default 6667)

**imodem.channel** *:string* - Server channel to which want to connect. If set to **nil**, only imodem.send() can be used. If the connection occurred without specifying a channel, can connect by setting the channel and calling imodem.connect() or imodem.send_raw('JOIN #channel')

**imodem.nick** *:string* - Bot nickname, generated based on the internet card address.
 
 
## Methods
**imodem.isOnline()** *:boolean* - Return value - is there a connection to the server.

**imodem.connect()** *:boolean* - Сonnects to the server.

**imodem.disconnect()** *:boolean* - Disconnects from the server.

**imodem.send_raw(data: string)** *:boolean* - Send data at IRC protocol level.

**imodem.broadcast(data: string)** *:boolean* - Send message to current channel.

**imodem.send(target: string, data: string)** *:boolean* - Send a message to the channel or user that are specified in target.

## Installing in OpenOS
wget https://raw.githubusercontent.com/DOOBW/internet_modem/master/imodem.lua /lib/imodem.lua

## Usage example

    local imodem = require('imodem')
    local event = require('event')
    
    imodem.connect()
    
    while not imodem.isOnline() do
      os.sleep()
    end
    
    imodem.broadcast('Hello IRC!')
    
    while true do
      local e = {event.pull('modem_message')}
      print(e[3]..': '..e[6])
    end
