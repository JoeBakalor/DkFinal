//
//  GameData.swift
//  LiveSYNCiPad
//
//  Created by Joe Bakalor on 4/19/17.
//  Copyright © 2017 Joe Bakalor. All rights reserved.
//

import Foundation



class GameData: NSObject
{
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    public enum timeUnits: Int
    {
        case minutes = 1
        case seconds = 2
    }
    
    public struct gameData
    {
        var outCount: Int?
        var ballCount: Int?
        var strikeCount: Int?
        var inningCount: Int?
        var guestScore: Int?
        var homeScore: Int?
        var currentTime: Int?
        var savedTimeUnits: timeUnits?
        var dateSaved: Date?
        var countDirection: Int?
        //need scoreboard identifier, dont want to reload data for wrong scoreboard
    }
    
    var savedGameDataArray = [[String:AnyObject]]()
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    override init()
    {
        if let gameData = defaults.object(forKey: "savedGameData") as? [[String: AnyObject]]{
            
            savedGameDataArray = gameData
            print("Found saved game data")
        }
        
    }
    /*==========================================================================================*/
    //
    //  Variables
    //
    /*==========================================================================================*/
    func saveGameData(data: gameData)
    {
        
        //only going to allow one entry to be saved so each time this is called we should clear all data
        //and add new entry
        
        clearHistoricalData()
        
        let readableDate = Date().formatted
        var convertedData = [String: AnyObject]()
        
        convertedData["outCount"] = data.outCount as AnyObject?
        convertedData["ballCount"] = data.ballCount as AnyObject?
        convertedData["strikeCount"] = data.strikeCount as AnyObject?
        convertedData["inningCount"] = data.inningCount as AnyObject?
        convertedData["guestScore"] = data.guestScore as AnyObject?
        convertedData["homeScore"] = data.homeScore as AnyObject?
        convertedData["currentTime"] = data.currentTime as AnyObject?
        convertedData["savedTimeUnits"] = data.savedTimeUnits?.rawValue as AnyObject?
        convertedData["countDirection"] = data.countDirection as AnyObject?
        //convertedData["dateSaved"] = data.dateSaved as AnyObject?
        
        let date = Date()
        let calender = Calendar.current
        let day = calender.component(.weekday, from: date)
        let month = calender.component(.month, from: date)
        let year = calender.component(.year, from: date)
        convertedData["day"] = day as AnyObject?
        convertedData["month"] = month as AnyObject?
        convertedData["year"] = year as AnyObject?
        
        savedGameDataArray.append(convertedData)
        defaults.set(savedGameDataArray as Any, forKey: "savedGameData")
        print("Saved game data \(convertedData)")
    }
    /*==========================================================================================*/
    func clearHistoricalData()
    {
        savedGameDataArray = [[String:AnyObject]]()
        defaults.set(savedGameDataArray as Any, forKey: "savedGameData")
    }
    /*==========================================================================================*/
}
/*==========================================================================================*/

extension Date
{
    var formatted: String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = /*"yyyy-MM-dd'*/ "'hh:mm:ss.SS'"//use HH for 24 hour scale and hh for 12 hour scale
        formatter.timeZone = TimeZone.autoupdatingCurrent//(forSecondsFromGMT: 4)
        formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}
