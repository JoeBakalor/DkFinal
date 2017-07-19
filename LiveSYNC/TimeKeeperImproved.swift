//
//  TimeKeeperImproved.swift
//  LiveSYNCiPad
//
//  Created by Joe Bakalor on 3/21/17.
//  Copyright © 2017 Joe Bakalor. All rights reserved.
//

import Foundation

class TimeKeeperImproved: NSObject
{
    /*==========================================================================================*/
    public enum countDirection: Int
    {
        case up = 1
        case down = 2
    }
    
    enum lastCalled
    {
        case clockSet
        case periodSet
    }
    /*==========================================================================================*/
    struct timerSettings
    {
        var countUpOrDown = countDirection.up
        var periodSetting = 0
        var clockSetting = 0
        var usePeriod = false
    }
    
    var clockTime = 0
    var savedTime = 0
    
    var clockTickTimer: Timer?
    var timerStartTime: Date?

    var timerIsRunning = false
    var countDownFrom = 0
    var countUpFrom = 0
    var timerPaused = false
    var timerTocked = false
    var allowStart = true
    var allowStop = false
    var lastSet: lastCalled = .periodSet
    var settings = timerSettings()

    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func shutdownTimer()
    {
        clockTickTimer?.invalidate()
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func startTimer()
    {
        if allowStart{
            
            allowStart = false
            allowStop = true
            
            switch timerPaused{
                
            case true:
                print("STARTED coming from timer paused")
                timerStartTime = Date()
                timerIsRunning = true
            case false:
                print("STARTED not coming from timer paused")
                timerStartTime = Date()
                timerIsRunning = true
            
                switch settings.countUpOrDown{
                    
                case .down:
                    print("timer count down")
                    if settings.usePeriod{
                        
                        countDownFrom = settings.periodSetting
                        
                    }else{
                        
                        countDownFrom = settings.clockSetting
                    }
                case .up:
                    print("timer count up")
                    countUpFrom = settings.clockSetting
                }
            }

            print("Timer is valid = \(clockTickTimer?.isValid)")
            clockTickTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(TimeKeeperImproved.timerTicked), userInfo: nil, repeats: true)
            timerPaused = false
        }
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func timerTicked()
    {
        timerTocked = true
        switch settings.countUpOrDown{
        case .down:
            print("timer count down")
            clockTime = countDownFrom - Int(round(Date().timeIntervalSince(timerStartTime!)))
            if clockTime <= 0{
                
                stopTimer()
                resetTimer()
            }
        case .up:
            print("timer count up")
            clockTime = Int(round(Date().timeIntervalSince(timerStartTime!))) + countUpFrom
            print("ClockTime = \(clockTime)")
            if settings.usePeriod && clockTime == settings.periodSetting{
                
                stopTimer()
                resetTimer()
            }
        }
        
        print("Current Time from Better Timer = \(clockTime)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTimeID"), object: self, userInfo: nil)
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func resumeTimer()
    {
        switch settings.countUpOrDown{
        case .down:
            print("timer count down")
        case .up:
            print("timer count up")
        }
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func stopTimer()
    {
        if allowStop{
            
            allowStop = false
            allowStart = true
            timerPaused = true
            clockTickTimer?.invalidate()
            timerIsRunning = false
        
            switch settings.countUpOrDown{
            case .down:
                print("timer count down")
                countDownFrom = clockTime
            case .up:
                countUpFrom = clockTime
                print("timer count up")
            }
            //else count timer start as false start and do nothing
            NotificationCenter.default.post(name: Notification.Name(rawValue: "timerStoppedID"), object: self, userInfo: nil)
        }
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func resetTimer()
    {
        timerPaused = false
        clockTime = 0
        
        switch settings.countUpOrDown{
        case .down:
            print("timer count down")
            if settings.usePeriod == true{
                
                clockTime = settings.periodSetting
                
            }else{
                
                clockTime = settings.clockSetting
            }
        case .up:
            print("timer count down")
            if settings.usePeriod == true{
                
                clockTime = 0
                
            }else{
                
                clockTime = settings.clockSetting
            }
            print("timer count up")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTimeID"), object: self, userInfo: nil)
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func setPeriod(period: Int)
    {
        settings.usePeriod = true
        lastSet = .periodSet
        if settings.countUpOrDown == .down{
            
            clockTime = period*60
        }
        settings.periodSetting = period*60
        resetTimer()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTimeID"), object: self, userInfo: nil)
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func setClock(time: Int)
    {
        lastSet = .clockSet
        settings.usePeriod = false
        clockTime = time*60
        settings.clockSetting = time*60
        resetTimer()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTimeID"), object: self, userInfo: nil)
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func changeCountDirection(direction: countDirection)
    {
        resetTimer()
        settings.countUpOrDown = direction
        switch direction{
        case .down: print("Set down direction")
            switch lastSet{
            case .clockSet: print("Clock set last"); clockTime = settings.clockSetting
            case .periodSet: print("Period set last"); clockTime = settings.periodSetting
            }
        case .up: print("Set up direction")
            switch lastSet{
            case .clockSet: clockTime = settings.clockSetting
            case .periodSet: clockTime = 0
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTimeID"), object: self, userInfo: nil)
    }
    /*==========================================================================================*/
}











