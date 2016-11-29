//
//  MultidropProtocol.swift
//  LiveSYNC
//
//  Created by Joe Bakalor on 11/17/16.
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

let MultidropProtocolSharedInstance = MultidropProtocol();

class MultidropProtocol: NSObject
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
    //
    //
    /*==========================================================================================*/
    var packetIdentifierToggle: Bool?
    var protocolPacket: [String] = ["55", "AA", "3E", "09", "00", "22", "00", "00", "00", "00", "00", "00", "00", "00", "00"]
    /*==========================================================================================*/
    //
    //
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
    //
    //
    /*==========================================================================================*/
    func convertValuesToProtocalString(balls: String, strikes: String, outs: String, guestScore: String, inningCount: String, homeScore: String)
    {
        print("Home Score: \(homeScore)")
        print("Guest Score: \(guestScore)")
        print("OUT: \(outs)")
        print("BALL: \(balls)")
        print("STRIKE: \(strikes)")
        print("INNING: \(inningCount)")
        var checkSum1 = 0x00
        var checkSum2 = 0x00
        var charCount = 0
        //var bitTest = oneBall | twoStrike | twoOut
        
        //print("\(bitTest)")
        if (packetIdentifierToggle == false)
        {
            protocolPacket[4] = "05"
            packetIdentifierToggle = true
            protocolPacket[5] = "B5" //checksum, should calculate it
            
        }
        else
        {
            protocolPacket[4] = "15"
            packetIdentifierToggle = false
            protocolPacket[5] = "A5" //checksum, should calculate it
        }
        
        for i in 0...4 {
            
            checkSum1 = checkSum1 + protocolPacket[i].hexaToDecimal
            
        }
        
        if checkSum1 > 255{
            checkSum1 = checkSum1>>8 - (checkSum1 & 0x00FF)
            //checkSum1 = ~checkSum1
            checkSum1 = (checkSum1 & 0x00FF) - 1
        }

        protocolPacket[5] = "\(checkSum1.toHexaString)"
        print("checkSum1 = \(checkSum1.toHexaString)")
        
        //populate protocolPacket[7-11]..protocolPacket[7] = guest score first digit, protocolPacket[8] = guest score second digit, protocolPacket[9] = home score second digit, protocolPacket[10] = home score first digit, protocolPacket
        
        charCount = guestScore.characters.count
        if charCount == 1{
            protocolPacket[7] = convertDigitToProtocolValue(Int(guestScore[0])!) //first digit
            protocolPacket[8] = convertDigitToProtocolValue(0) //second digit
        }
        else{
            protocolPacket[7] = convertDigitToProtocolValue(Int(guestScore[0])!) //first digit
            protocolPacket[8] = convertDigitToProtocolValue(Int(guestScore[1])!)//second digit
            
        }
        
        
        charCount = homeScore.characters.count
        if charCount == 1{
            protocolPacket[9] = convertDigitToProtocolValue(0) //second digit
            protocolPacket[10] = convertDigitToProtocolValue(Int(homeScore[0])!)//first digit
        }
        else{
            protocolPacket[9] = convertDigitToProtocolValue(Int(homeScore[1])!) //second digit
            protocolPacket[10] = convertDigitToProtocolValue(Int(homeScore[0])!)//first digit
        }
        
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
        
        var tempStringToHex = "\(temp)"
        if tempStringToHex.characters.count = 1
        {
            tempStringToHex = "0" + tempStringToHex
        }
        
        //protocolPacket[13] = tempStringToHex
        
       for i in 5...13 {
            
            checkSum2 = checkSum2 + protocolPacket[i].hexaToDecimal
            
        }
        
        if checkSum2 > 255{
            checkSum2 = checkSum1>>8 - (checkSum2 & 0x00FF)
            //checkSum1 = ~checkSum1
            checkSum2 = (checkSum2 & 0x00FF) - 1
        }
        
        protocolPacket[14] = "\(checkSum2.toHexaString)"
        
        print("Protocol Packet: \(protocolPacket)")
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func convertDigitToProtocolValue(digit: Int) -> String
    {
        var digitConvert: String = ""
        switch (digit)
        {
        case 0: digitConvert = "BF" //0xBF H on 0x3F H off
        case 1: digitConvert = "86" //0x86 0x06
        case 2: digitConvert = "DB" //0xDB 0x5B
        case 3: digitConvert = "CF" //0xCF 0x4F
        case 4: digitConvert = "E6" //0xE6 0x66
        case 5: digitConvert = "ED"//0xED 0x6D
        case 6: digitConvert = "FD" //0xFD 0x7D
        case 7: digitConvert = "87" //0x87 0x07
        case 8: digitConvert = "FF"//0xFF 0x7F
        case 9: digitConvert = "E7" //0xE7 0x67
        default:break
        }
        return digitConvert
    }

}

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = startIndex.advancedBy(r.startIndex)
        let end = start.advancedBy(r.endIndex - r.startIndex)
        return self[Range(start ..< end)]
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


