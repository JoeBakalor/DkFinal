//
//  TimeKeeper.swift
//  LiveSYNCiPad
//
//  Created by Joe Bakalor on 3/13/17.
//  Copyright © 2017 Joe Bakalor. All rights reserved.
//

import Foundation

class TimeKeeper: NSObject
{
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    enum countDirection
    {
        case up
        case down
    }
    enum timerStates
    {
        case stopped
        case clockTickingUpToPeriodSetting
        case clockTickingDownFromPeriodSetting
        case clockTickingUpNoPeriodSetting
        case clockTickingDownFromClockSetting
    }

    var clockTime = 0
    var periodSetting = 0
    var clockSetting = 0
    var clockTick: Timer?
    var startTime: Date?
    var stoppedTime: Date?
    var savedTime = 0
    var timerIsRunning = false
    var countUpOrDown = countDirection.up
    var lastTimerState = timerStates.stopped
    var currentTimerState = timerStates.stopped
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    override init()
    {
        
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func startTimer()
    {
        //if coming from reset
        //else if coming from stop
        if !timerIsRunning
        {
            startTime = Date()
            clockTick = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(TimeKeeper.timerTicked), userInfo: nil, repeats: true)
            timerIsRunning = true
        }
    }
    /*==========================================================================================*/
    func timerTicked()
    {
        if timerIsRunning
        {
            
            print("TickTock")
            
            switch countUpOrDown{
            case .up: print("")
            
                clockTime = Int(round(Date().timeIntervalSince(startTime!))) + savedTime
                if periodSetting != 0 && clockTime == periodSetting*60{
                    clockTime = 0
                    stopTimer()
                }
                
            case .down: print("")
            
                if periodSetting != 0{
                    clockTime = periodSetting*60 - Int(round(Date().timeIntervalSince(startTime!))) - savedTime
                }else{
                    clockTime = clockTime - Int(round(Date().timeIntervalSince(startTime!))) - savedTime
                }
            
                if clockTime < 0{
                    clockTime = 0
                    stopTimer()
                }
            }
            print("Current Time = \(clockTime)")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "timeUpdatedID"), object: self, userInfo: nil)
        }
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func stopTimer()
    {
        if timerIsRunning{
            clockTick?.invalidate()
            timerIsRunning = false
            if clockTime != 0 // in case user presses start and then presses stop before timer ticks
            {
                if countUpOrDown == .down
                {
                    if periodSetting != 0{
                        savedTime = (periodSetting*60 - clockTime)
                    }else{
                        savedTime = clockTime
                    }
                    
                }else{
                    savedTime = clockTime
                }
            }
            clockTime = 0
            stoppedTime = Date()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "timerStoppedID"), object: self, userInfo: nil)
        }
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func resetTimer()
    {
        if !timerIsRunning
        {
            clockTick?.invalidate()
            startTime = nil
            if periodSetting == 0{
                clockTime = 0
            }else if periodSetting != 0 && countUpOrDown == .down{
                clockTime = periodSetting*60
            }
            
            savedTime = 0
            NotificationCenter.default.post(name: Notification.Name(rawValue: "timeUpdatedID"), object: self, userInfo: nil)
        }
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func setCountUpOrDown(countUp: Bool)
    {
        if countUp{
            countUpOrDown = .up
            print("We should count up")
            resetTimer()
        }else{
            countUpOrDown = .down
            print("We should count down")
            resetTimer()
        }

    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func setClock(timeToSet: String)
    {
        print("Set Clock = \(timeToSet)")
        clockTime = (Int(timeToSet)!)*60
        periodSetting = 0
        //resetTimer()
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func setPeriod(periodToSet: String)
    {
        resetTimer()
        print("Set Period = \(periodToSet)")
        periodSetting = Int(periodToSet)!
        if countUpOrDown == .down
        {
            clockTime = periodSetting*60
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "timeUpdatedID"), object: self, userInfo: nil)
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
}





/*switch currentTimerState{
case .clockTickingDownFromClockSetting: print("")
case .clockTickingDownFromPeriodSetting: print("")
case .clockTickingUpToPeriodSetting: print("")
case .clockTickingUpNoPeriodSetting: print("")
default: print("Unknown State")
}*/












