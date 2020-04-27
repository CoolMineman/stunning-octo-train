import net
import protocalutils

proc connectionhandler*(client: Socket, address: string) {.thread.} =
    #echo "cool"
    var exit = false
    try:
        while (not exit):
            let length = readVarInt(client)
            let packetid = readVarInt(client)
            var data = readBytes(client, int32(length.data - packetid.bytesread))
            # echo length
            # echo packetid
            # echo data
            case packetid.data:
                of 0x00:
                    if data.len > 0:
                        # echo "Handshaking"
                        let protocolversion = readVarInt(data)
                        let serveraddress = readString(data)
                        let serverport = readUShort(data)
                        let nextstate = readVarInt(data)
                        if (nextstate.data == 1):
                            # echo "status"
                            var packetdata: seq[uint8] = @[]
                            packetdata.writeString("""{"version":{"name":"1.8.10","protocol":47},"players":{"max":100,"online":5,"sample":[{"name":"thinkofdeath","id":"4566e69f-c907-48ee-8d71-d7ba5aa00d20"}]},"description":{"text":"Hello world"}}""")
                            sendPacket(client, 0x00, packetdata)
                        elif (nextstate.data == 2):
                            echo "login"
                        else:
                            #todo error 
                            echo "wtf"
                            exit = true
                of 0x01:
                    #var packetdata = @[data[0], data[1], data[2],  data[3], data[4], data[5], data[7]]
                    sendPacket(client, 0x01, data)
                    #echo "ping"
                else:
                    echo "Bad Packet"
                    exit = true
    except:
        assert true
        # echo "Connection did a bad"
    finally:
        client.close()