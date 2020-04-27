import net
import unicode

let a: uint8 = 0b01_111_111
let b: uint8 = 0b10_000_000

proc readBytes*(client: Socket, bytecount: int): seq[uint8] =
    let data = recv(client, bytecount, -1)
    for i in 0..(bytecount-1):
        result.add(uint8(data[i]))

type
  VarInt* = object
    data*: int32
    bytesread*: int32

#https://wiki.vg/Protocol#VarInt_and_VarLong
proc readVarInt*(client: Socket): VarInt =
    result.bytesread = 0
    var read: uint8
    while (true):
        read = readBytes(client, 1)[0]
        var value: int32 = int32(read and a)
        result.data = result.data or (value shl (7 * result.bytesread))

        result.bytesread += 1
        if (result.bytesread > 5):
            #Todo error handling
            result.data = 0
            break
        if ((read and b) == 0):
            break

proc readVarInt*(bytes: var seq[uint8]): VarInt =
    result.bytesread = 0
    var read: uint8
    while (true):
        read = bytes[0]
        bytes.delete(0)
        var value: int32 = int32(read and a)
        result.data = result.data or (value shl (7 * result.bytesread))

        result.bytesread += 1
        if (result.bytesread > 5):
            #Todo error handling
            result.data = 0
            break
        if ((read and b) == 0):
            break

proc readString*(bytes: var seq[uint8]): string =
    let stringlength = readVarInt(bytes)
    var i = 0
    while (i != stringlength.data):
        result = result & char(bytes[0])
        bytes.delete(0)
        if (validateUtf8(result) == -1):
            i += 1
            echo i
            echo result

#https://stackoverflow.com/questions/2182002/convert-big-endian-to-little-endian-in-c-without-using-provided-func
proc readUShort*(bytes: var seq[uint8]): uint16 =
    let byte1 = bytes[0]
    let byte2 = bytes[1]
    bytes.delete(0)
    bytes.delete(0)
    result = byte1
    result = result shl 8
    result += byte2
    result = (result shr 8) or (result shl 8)