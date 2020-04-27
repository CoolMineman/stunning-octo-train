import net
import unicode

let a: uint8 = 0b01_111_111
let b: uint8 = 0b10_000_000

proc readBytes*(client: Socket, bytecount: int): seq[uint8] =
    let data = recv(client, bytecount, -1)
    for i in 0..(bytecount-1):
        result.add(uint8(data[i]))

proc writeBytes*(client: Socket, bytes: seq[uint8]) =
    var writestring = ""
    for i in 0..bytes.len-1:
        writestring.add(char(bytes[i]))
    send(client, writestring)

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

proc writeVarInt*(bytes: var seq[uint8], valuein: int32) =
    var invalue = valuein
    var value: uint32 = cast[ptr uint32](addr invalue)[] #voodoo magic
    
    while (true):
        var temp: uint8 = uint8(value and uint32(a))
        value = value shr 7 #unsigned b/c pointer magic
        if (value != 0):
            temp = temp or b
        bytes.add(temp)
        if (value == 0):
            break

proc readString*(bytes: var seq[uint8]): string =
    let stringlength = readVarInt(bytes)
    var i = 0
    while (i != stringlength.data):
        result = result & char(bytes[0])
        bytes.delete(0)
        if (validateUtf8(result) == -1):
            i += 1
            # echo i
            # echo result

#!Max Length is 32767 Currently No Bounds Checking
proc writeString*(bytes: var seq[uint8], str: string) =
    var unicodelength: int32 = 0
    for _ in runes(str):
        unicodelength += 1
    writeVarInt(bytes, unicodelength)
    for char in str:
        bytes.add(uint8(char))

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

proc sendPacket*(client: Socket, packetid: int32, bytes: seq[uint8]) =
    var packetbytes: seq[uint8] = @[]
    writeVarInt(packetbytes, packetid)
    for i in 0..bytes.len-1:
        packetbytes.add(bytes[i])
    var lengthbytes: seq[uint8] = @[]
    writeVarInt(lengthbytes, int32(packetbytes.len))
    writeBytes(client, lengthbytes)
    writeBytes(client, packetbytes)