import net
import protocalutils

proc connectionhandler*(client: Socket, address: string) {.thread.} =
    echo "cool"
    var exit = false
    while (not exit):
        echo "---"
        echo exit
        echo "---"
        let length = readVarInt(client)
        let packetid = readVarInt(client)
        var data = readBytes(client, int32(length.data - packetid.bytesread))
        echo "Length:"
        echo length
        echo "Packetid:"
        echo packetid
        echo "Data:"
        echo data
        case packetid.data:
            of 0x00:
                echo "Handshaking"
                let protocolversion = readVarInt(data)
                let serveraddress = readString(data)
                let serverport = readUShort(data)
                let nextstate = readVarInt(data)
                if (nextstate.data == 1):
                    echo "status"
                    exit = true
                elif (nextstate.data == 2):
                    echo "login"
                else:
                    #todo error 
                    echo "wtf"
                    exit = true
            else:
                echo "Bad Packet"
                exit = true
    client.close()