import net
import threadpool
import ./tcpconnectionhandler

var socket = newSocket()
socket.bindAddr(Port(25567))
socket.listen()

var client: Socket
var address = ""
while true:
    socket.acceptAddr(client, address)
    echo("Client connected from: ", address)
    spawn connectionhandler(client, address)