//
//  MultidropPacketBuilder.swift
//  LiveSYNC
//
//  Created by Joe Bakalor on 11/18/16.
//  Copyright © 2016 Joe Bakalor. All rights reserved.
//
/*
Packet Format

HEADER BYTES
--------------------------------------------------
0x55 0xAA => Sync byte one and sync byte two
0x3E => Address, 62 for BA-2518
0x07 => Data Byte count following first check sum 6 digits + 1 command byte always for BA-2518
0x05 => Packet identifier/command byte.  Add 0x10 to this after each successive packet to detect re-tx
0xXX => Checksum 1, subtract first 5 bytes from 0x00
--------------------------------------------------
PAYLOAD BYTES
--------------------------------------------------
0x22 => Control Byte, Looks like this is always 22
0xXX => Guest Score x1
0xXX => Guest Score x10
0xXX => Home Score x10
0xXX => Home Score x1
0xXX => Ball (Segment A,B,C = 1,2,3) Strike (Segment D,E = 1,2) Out (Segment F,G = 1,2)
0xXX => Checksum 2, subtract data bytes from 0x00
*/


import Foundation

let MultidropPacketBuilderSharedInstance = MultidropPacketBuilder()

class MultidropPacketBuilder: NSObject
{
    
    /*==========================================================================================*/
    //
    //  Constants
    //
    /*==========================================================================================*/
    let oneBall = 0b00000001
    let twoBall = 0b00000011
    let threeBall = 0b00000111
    let oneStrike = 0b00001000
    let twoStrike = 0b00011000
    let oneOut = 0b00100000
    let twoOut = 0b01100000
    /*==========================================================================================*/
    //
    //  Variables
    //
    /*==========================================================================================*/
    var packetIdentifierToggle: Bool?
    var hexProtocolPacket: [UInt8] = [0x55, 0xaa, 0x3e, 0x08, 0x00, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    /*==========================================================================================*/
    //
    //  Init necessary values or functions
    //
    /*==========================================================================================*/
    override init()
    {
        super.init()
        packetIdentifierToggle = false
        print("attempting to add custom characteristic")
    }
    /*==========================================================================================*/
    //
    //  Build protocol packet
    //
    /*==========================================================================================*/
    func convertValuesToProtocalString(_ balls: String, strikes: String, outs: String, guestScore: String, inningCount: String, homeScore: String) ->NSData
    {
        // Debug statements print values passed to function
        print("Home Score: \(homeScore)")
        print("Guest Score: \(guestScore)")
        print("OUT: \(outs)")
        print("BALL: \(balls)")
        print("STRIKE: \(strikes)")
        print("INNING: \(inningCount)")
        
        var hexCheckSum1: UInt8 = 0x00
        var hexCheckSum2: UInt8 = 0x00
        var charCount = 0
        
        // First 4 bytes of packet don't change
        /*==========================================================================================*/
        // Set packet identifer and Checksum1
        if (packetIdentifierToggle == false){
            hexProtocolPacket[4] = 0x05
            packetIdentifierToggle = true
            
        }else{
            hexProtocolPacket[4] = 0x15 //converting to hex string instead of regular string
            packetIdentifierToggle = false
        }
        /*==========================================================================================*/
        //  Calculate first checksum
        for i in 0...4{
            hexCheckSum1 = UInt8.subtractWithOverflow(hexCheckSum1, hexProtocolPacket[i]).0
        }
        hexProtocolPacket[5] = hexCheckSum1//UInt8(checkSum1)
        /*==========================================================================================*/
        //  Populate protocolPacket[7-11]..protocolPacket[7] = guest score first digit, protocolPacket[8] = guest score second digit, protocolPacket[9] = home score second digit, protocolPacket[10] = home score first digit, protocolPacket
        //  Populate protocol packet bytes 8 and 9
        charCount = guestScore.characters.count
        if charCount == 1{
            hexProtocolPacket[7] = UInt8(convertDigitToHexProtocolValue(Int(guestScore[0])!))
            hexProtocolPacket[8] = UInt8(convertDigitToHexProtocolValue(0)) //second digit
        }else{
            hexProtocolPacket[7] = UInt8(convertDigitToHexProtocolValue(Int(guestScore[0])!))//first digit
            hexProtocolPacket[8] = UInt8(convertDigitToHexProtocolValue(Int(guestScore[1])!))//second digit
        }
        /*==========================================================================================*/
        // Populate protcol bytes 10 and 11
        charCount = homeScore.characters.count
        if charCount == 1{
            hexProtocolPacket[9] = UInt8(convertDigitToHexProtocolValue(0)) //second digit
            hexProtocolPacket[10] = UInt8(convertDigitToHexProtocolValue(Int(homeScore[0])!))//first digit
        }else{
            hexProtocolPacket[9] = UInt8(convertDigitToHexProtocolValue(Int(homeScore[1])!)) //second digit
            hexProtocolPacket[10] = UInt8(convertDigitToHexProtocolValue(Int(homeScore[0])!))//first digit
        }
        /*==========================================================================================*/
        // Populate protocol byte 12
        hexProtocolPacket[11] = UInt8(convertDigitToHexProtocolValue(Int(inningCount)!))
        /*==========================================================================================*/
        // Populate protocol btye 13
        var temp = 0b00000000
        switch Int(balls)!{
        case 0: break
        case 1: temp |= oneBall
        case 2: temp |= twoBall
        case 3: temp |= threeBall
        default: break
        }
        
        switch Int(strikes)!{
        case 0: break
        case 1: temp |= oneStrike
        case 2: temp |= twoStrike
        default: break
        }
        
        switch Int(outs)!{
        case 0: break
        case 1: temp |= oneOut
        case 2: temp |= twoOut
        default: break
        }
        hexProtocolPacket[12] = UInt8(temp)
        /*==========================================================================================*/
        //  Calculate second checksum
        for i in 5...13{
            hexCheckSum2 = UInt8.subtractWithOverflow(hexCheckSum2, hexProtocolPacket[i]).0
        }
        hexProtocolPacket[13] = hexCheckSum2//UInt8(checkSum2)
        /*==========================================================================================*/
        //  Format for NSData
        let bytes: [UInt8] = hexProtocolPacket
        let data = Data(bytes:bytes)
        
        print("HEX formatted protocol string: \(data)")
        return data as NSData
    }
    /*==========================================================================================*/
    //
    //  Return hex equivalent
    //
    /*==========================================================================================*/
    func convertDigitToHexProtocolValue(_ digit: Int) -> Int
    {
        var digitConvert = 0x00
        switch (digit){
        case 0: digitConvert = 0xBF //0xBF H on 0x3F H off
        case 1: digitConvert = 0x86 //0x86 0x06
        case 2: digitConvert = 0xDB //0xDB 0x5B
        case 3: digitConvert = 0xCF //0xCF 0x4F
        case 4: digitConvert = 0xE6 //0xE6 0x66
        case 5: digitConvert = 0xED//0xED 0x6D
        case 6: digitConvert = 0xFD //0xFD 0x7D
        case 7: digitConvert = 0x87 //0x87 0x07
        case 8: digitConvert = 0xFF//0xFF 0x7F
        case 9: digitConvert = 0xE7 //0xE7 0x67
        default:break
        }
        return digitConvert
    }
    /*==========================================================================================*/
}

/*==========================================================================================*/
//
// Extensions
//
/*==========================================================================================*/
extension String {
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
}

extension String
{
    var drop0xPrefix:          String { return hasPrefix("0x") ? String(characters.dropFirst(2)) : self }
    var drop0bPrefix:          String { return hasPrefix("0b") ? String(characters.dropFirst(2)) : self }
    var hexaToDecimal:            Int { return Int(drop0xPrefix, radix: 16) ?? 0 }
    var hexaToBinaryString:    String { return String(hexaToDecimal, radix: 2) }
    var decimalToHexaString:   String { return String(Int(self) ?? 0, radix: 16) }
    var decimalToBinaryString: String { return String(Int(self) ?? 0, radix: 2) }
    var binaryToDecimal:          Int { return Int(drop0bPrefix, radix: 2) ?? 0 }
    var binaryToHexaString:    String { return String(binaryToDecimal, radix: 16) }
}

extension Int
{
    var toBinaryString: String { return String(self, radix: 2) }
    var toHexaString:   String { return String(self, radix: 16) }
}







































