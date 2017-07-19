//
//  EmulatedScoreBoardAlternateViewController.swift
//  LiveSYNCiPad
//
//  Created by Joe Bakalor on 3/11/17.
//  Copyright © 2017 Joe Bakalor. All rights reserved.
//

import UIKit
import CoreBluetooth


//add ability to recall previous game data
//save data when a connection is lost for any reason

let historicalGameData = GameData()

class EmulatedScoreBoardAlternateViewController: UIViewController
{

    /*==========================================================================================*/
    //
    //  UI Outlets
    //
    /*==========================================================================================*/
    @IBOutlet weak var ballCount: UIImageView!
    @IBOutlet weak var strikeCount: UIImageView!
    @IBOutlet weak var outCount: UIImageView!
    
    @IBOutlet weak var guestScore10Digit: UIImageView!
    @IBOutlet weak var guestScore1Digit: UIImageView!
    
    @IBOutlet weak var inningCount1Digit: UIImageView!
    
    @IBOutlet weak var homeScore10Digit: UIImageView!
    @IBOutlet weak var homeScore1Digit: UIImageView!
    
    @IBOutlet weak var numberOfBalls: UIStepper!
    @IBOutlet weak var numberOfStrikes: UIStepper!
    @IBOutlet weak var numberOfOuts: UIStepper!
    
    @IBOutlet weak var guestScore: UIStepper!
    @IBOutlet weak var numberOfInnings: UIStepper!
    @IBOutlet weak var homeScore: UIStepper!
    
    @IBOutlet weak var setupView: UIView!
    @IBOutlet weak var baseballStatusIndicator: UIImageView!
    
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var timePicker: UIPickerView!
    
    @IBOutlet weak var timeSetupView: UIView!
    @IBOutlet weak var timerStartStopButton: UIButton!
    @IBOutlet weak var timeResetButton: UIButton!
  
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var miniTimeView: UIView!
    
    @IBOutlet weak var miniTimer10Digit: UIImageView!
    @IBOutlet weak var miniTimer1Digit: UIImageView!
    
    @IBOutlet weak var bigTimer10Digit: UIImageView!
    @IBOutlet weak var bigTimer1Digit: UIImageView!
    
    @IBOutlet weak var countDirection: UISegmentedControl!
    @IBOutlet weak var clockOrPeriod: UISegmentedControl!
    @IBOutlet weak var editTimerSettingsButton: UIButton!

    @IBOutlet weak var loadPreviousGameView: UIView!
    @IBOutlet weak var previousGameDataStatus: UIActivityIndicatorView!
    
    //@IBOutlet var testGestureTiming: UITapGestureRecognizer!
    //@IBOutlet var doubleTapToStartOrStopTimer: UITapGestureRecognizer!
    /*==========================================================================================*/
    //  Variables
    /*==========================================================================================*/
    var scoreBoardPeripheral : CBPeripheral?
    var scoreboardService : CBService?
    var scoreboardCharacteristic : CBCharacteristic?  //need to write updates to this characteristic
    var protocolStringToSend: NSData?
    var setupComplete: Bool = false
    var timer: Timer?  //  Timer used for sending an a current status packet every 1 second
    var flashMiniTimeView: Timer?
    var simulateSuccesfulConnectionTimer: Timer?
    var flashToggle = false
    var betterClock: TimeKeeperImproved?
    var clockTimeToSet = "0"
    var periodTimeToSet = "0"
    var currentTime = 0
    
    var currentGameData: GameData.gameData?
    var timeUnitsCurrent = GameData.timeUnits.seconds
    var savedDataFound = false
    
    var startShutDown = false
    var saveTime = 0
    /*==========================================================================================*/
    //  Constants
    /*==========================================================================================*/
    let measurementPickerData = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99"]
    /*==========================================================================================*/
    //  Perform setup needed when view loads
    /*==========================================================================================*/
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        timeUnitsCurrent = .seconds
        betterClock = TimeKeeperImproved()
        setupUI()
        
        if debug{
            simulateSuccesfulConnectionTimer = Timer.scheduledTimer(timeInterval: 2,
                                                                    target: self,
                                                                    selector: #selector(self.hideConnectingView),
                                                                    userInfo: nil,
                                                                    repeats: true)
        }

        if debug{ sendUpdates()}
        
        if historicalGameData.savedGameDataArray.count != 0{
            savedDataFound = true
        }else{
            savedDataFound = false
        }
        
        setupView.layer.isHidden = false
        baseballStatusIndicator.rotate360Degrees()
        
        if BLEConnectionManagerSharedInstance.getPeripheral() != nil{
            print("Found valid peripheral")
        }
        
        addObservers()
        //Start looking for the scoreboard service on the connected peripheral
        BLEConnectionManagerSharedInstance.bleService?.startDiscoveringServices([SerialServiceUUID])
    }
    /*==========================================================================================*/
    //
    /*==========================================================================================*/
    func hideConnectingView()
    {
        setupView.layer.isHidden = true
    }
    /*==========================================================================================*/
    //  Process response to user request to start new game or reload previous data
    /*==========================================================================================*/
    @IBAction func loadPreviousGameViewButton(_ sender: UIButton)
    {
        switch sender.titleLabel!.text!{
            
        case "YES": print("ok load saved game data")
            previousGameDataStatus.startAnimating()
            previousGameDataStatus.isHidden = false
        
            //make it seem like loading is taking place
            let delayInSeconds = 0.5
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds){
                self.loadSavedGameData()
            }
            
        default: print("ok, don't load save data");
            loadPreviousGameView.isHidden = true
            
        }
    }
    /*==========================================================================================*/
    //  load saved game data
    /*==========================================================================================*/
    func loadSavedGameData()
    {
        
        previousGameDataStatus.startAnimating()
        previousGameDataStatus.isHidden = false
        var savedGameData = historicalGameData.savedGameDataArray[0]
        
        print("retrieved game data = \(savedGameData)")
        print("what are we getting = \((savedGameData["ballCount"])!)")
        numberOfBalls.value = Double((savedGameData["ballCount"])! as! NSNumber)
        numberOfStrikes.value = Double((savedGameData["strikeCount"])! as! NSNumber)
        numberOfOuts.value = Double((savedGameData["outCount"])! as! NSNumber)
        guestScore.value = Double((savedGameData["guestScore"])! as! NSNumber)
        numberOfInnings.value = Double((savedGameData["inningCount"])! as! NSNumber)
        homeScore.value = Double((savedGameData["homeScore"])! as! NSNumber)
        
        switch Int(savedGameData["countDirection"] as! NSNumber)
        {
        case 1: print("count up!!")
            betterClock?.settings.countUpOrDown = .up
            countDirection.selectedSegmentIndex = 0
        case 2: print("cound down!!")
            betterClock?.settings.countUpOrDown = .down
            countDirection.selectedSegmentIndex = 1
        default: print("should never happen")
        }
        
        //betterClock?.settings.countUpOrDown
        
        var timeUnitsPulled = savedGameData["savedTimeUnits"] as! Int
        var savedCurrentTime = savedGameData["currentTime"] as! Int
        
            
        betterClock?.clockTime = savedCurrentTime
        currentTime = savedCurrentTime

        betterClock?.timerPaused = true
        betterClock?.countUpFrom = (betterClock?.clockTime)!
        betterClock?.countDownFrom = (betterClock?.clockTime)!
        betterClock?.stopTimer()
        
        ballIncrementDecrement(numberOfBalls)
        strikeIncrementDecrement(numberOfStrikes)
        outIncrementDecrement(numberOfOuts)
        
        guestScoreIncrementDecrement(guestScore)
        inningIncrementDecrement(numberOfInnings)
        homeScoreIncrementDecrement(homeScore)
        
        let notificationTest = Notification(name: Notification.Name(rawValue: "HEllO"))
        
        updateTime(notificationTest)
        
        previousGameDataStatus.stopAnimating()
        loadPreviousGameView.isHidden = true

    }
    /*==========================================================================================*/
    //  Add observers for bluetooth and timer events
    /*==========================================================================================*/
    func addObservers()
    {
        //Add observer t handle when the service is found
        NotificationCenter.default.addObserver(self,
                                               selector: (#selector(self.foundService(_:))),
                                               name: NSNotification.Name(rawValue: "foundServiceID"),
                                               object: nil)
        
        //Add observer to catch if or when peripheral connection fails
        NotificationCenter.default.addObserver(self,
                                               selector: (#selector(self.peripheralDisconnected(_:))),
                                               name: NSNotification.Name(rawValue: "connectionToPeripheralFailedID"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: (#selector(self.blankScoreboard)),
                                               name: NSNotification.Name(rawValue: "applicationWillTerminateID"),
                                               object: nil)
        
        //  Add TimeKeeper class observers to update time and timer stopped
        NotificationCenter.default.addObserver(self,
                                               selector: (#selector(self.timerStopped)),
                                               name: NSNotification.Name(rawValue: "timerStoppedID"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: (#selector(self.updateTime)),
                                               name: NSNotification.Name(rawValue: "updateTimeID"),
                                               object: nil)
    }
    /*==========================================================================================*/
    func timerStopped(_ notification: Notification)
    {
        timerStartStopButton.setTitle("START", for: .normal)
        flashMiniTimeView?.invalidate()
        //clock?.stopTimer()
        countDirection.isHidden = false
        editTimerSettingsButton.layer.isHidden = false
    }
    /*==========================================================================================*/
    //
    //  Double tap gesture responder
    //
    /*==========================================================================================*/
    @IBAction func doubleTapToStartStop(_ sender: UITapGestureRecognizer)
    {
        timerViewButton(timerStartStopButton)
    }
    /*==========================================================================================*/
    //  Called if the peripheral connection is terminated or fails, should let user know
    /*==========================================================================================*/
    func peripheralDisconnected(_ notification: Notification)
    {
        startShutDown = true
        print("Connection to scoreboard failed")
        betterClock?.stopTimer()
        betterClock?.resetTimer()
        removeObserers()
        self.navigationController?.popViewController(animated: false)//  Made ! instead of ?
    }
    /*==========================================================================================*/
    // Take car of anything that needs to be done before view dissapears
    /*==========================================================================================*/
    override func viewWillDisappear(_ animated: Bool)
    {
        //saveData()
        print("View Will Dissapear")
        removeObserers()
        blankScoreboard()
        timer?.invalidate()
        BLEConnectionManagerSharedInstance.disconnectPeripheral()
        setupComplete = false
        self.navigationController?.isNavigationBarHidden = false
        
        betterClock = nil //added 6-9
    }
    /*==========================================================================================*/
    // Remove all observers to external events
    /*==========================================================================================*/
    func removeObserers()
    {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "connectionToPeripheralFailedID"),
                                                  object:nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "updateTimeID"),
                                                  object:nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "applicationWillTerminateID"),
                                                  object:nil)
    }
    /*==========================================================================================*/
    // Save all game data
    /*==========================================================================================*/
    func saveData()
    {
        currentGameData = GameData.gameData(outCount: (Int(numberOfOuts.value)),
                                            ballCount: (Int(numberOfBalls.value)),
                                            strikeCount: (Int(numberOfStrikes.value)),
                                            inningCount: (Int(numberOfInnings.value)),
                                            guestScore: (Int(guestScore.value)),
                                            homeScore: (Int(homeScore.value)),
                                            currentTime: betterClock?.clockTime,
                                            savedTimeUnits: timeUnitsCurrent,
                                            dateSaved: Date(),
                                            countDirection: betterClock?.settings.countUpOrDown.rawValue)
        
        historicalGameData.saveGameData(data: currentGameData!)
    }
    /*==========================================================================================*/
    // Return to homescreen because user swiped right
    /*==========================================================================================*/
    @IBAction func returnHome(_ sender: UISwipeGestureRecognizer)
    {
        //saveData()//added May 3rd
        startShutDown = true
        print("User right swipe")
        blankScoreboard()
        betterClock?.shutdownTimer()
        timer?.invalidate()
        flashMiniTimeView?.invalidate()
        // Create protocol packet to send
        
        var returnedProtocolStrings: (string1: NSData, string2: NSData)?
        returnedProtocolStrings = MultidropPacketBuilderSharedInstance.blankScoreboard()
        
        // Send updates to scoreboard by writing protocol data to scoreboard characteristic
        if !debug{
            
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string1 as Data, characteristic: scoreboardCharacteristic!)
        }
        
        let firstRange: NSRange = NSRange(location: 0, length: 16)
        let secondRange: NSRange = NSRange(location: 16, length: 5)
        
        if !debug{
            
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string2.subdata(with: firstRange) as Data, characteristic: scoreboardCharacteristic!)
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string2.subdata(with: secondRange) as Data, characteristic: scoreboardCharacteristic!)
        }
        
        //Can't i just add this to remove observers
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "timerStoppedID"),
                                                  object:nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "connectionToPeripheralFailedID"),
                                                  object:nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "applicationWillTerminateID"),
                                                  object:nil)

        self.navigationController?.popViewController(animated: true)//  Made ! instead of ?
        
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        print("Historical Data Found = \(historicalGameData.savedGameDataArray)")
    }
    /*==========================================================================================*/
    // Reset scoreboard to base state
    /*==========================================================================================*/
    func blankScoreboard()
    {
        print("Request to blank scoreboard")
        var returnedProtocolStrings: (string1: NSData, string2: NSData)?
        returnedProtocolStrings = MultidropPacketBuilderSharedInstance.blankScoreboard()
        
        
        //print("Retuned Blanked Protocol String: \(protocolStringToSend)")
        if !debug{
            
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string1 as Data, characteristic: scoreboardCharacteristic!)
        }
        
        let firstRange: NSRange = NSRange(location: 0, length: 16)
        let secondRange: NSRange = NSRange(location: 16, length: 5)
        
        if !debug{
            
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string2.subdata(with: firstRange) as Data, characteristic: scoreboardCharacteristic!)
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string2.subdata(with: secondRange) as Data, characteristic: scoreboardCharacteristic!)
        }
        
        //if !debug{BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string2 as Data, characteristic: scoreboardCharacteristic!)}
    }
    /*==========================================================================================*/
    //  Called when correct service found, save reference to scoreboardService
    /*==========================================================================================*/
    func foundService(_ notification: Notification)
    {
        print("found service notification")
        
        let userInfo = notification.userInfo as! [String: AnyObject]
        //print("found service with data: \(userInfo)")
        let service = userInfo["service"] as! [CBService]!
        
        //  Save reference to scoreboard service
        scoreboardService = service?[0]
        
        //Start looking for the scoreboardCharacteristic
        BLEConnectionManagerSharedInstance.bleService?.peripheral?.discoverCharacteristics([SerialCharacteristicUUID], for: (service?[0])!)
        // Remove found service observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "foundServiceID"), object:nil)
        // Add observer for when the characteristic is found, only added if service which contains characteristic is found first
        NotificationCenter.default.addObserver(self, selector: #selector(ScoreBoardViewController.foundCharacteristic(_:)), name: NSNotification.Name(rawValue: "foundCharacteristicID"), object: nil)
    }
    /*==========================================================================================*/
    //  Called when the correct characteristic we were looking for is found, save reference to characteristic
    /*==========================================================================================*/
    func foundCharacteristic(_ notification: Notification)
    {
        print("found characteristic")
        setupComplete = true
        let userInfo = notification.userInfo as! [String: AnyObject]
        //print("user info = \(userInfo)")
        var characteristicList = userInfo["characteristic"] as! [CBCharacteristic]!
        
        //print("characteristic list: \(characteristicList)")
        scoreboardCharacteristic = characteristicList?[0]

        setupView.layer.isHidden = true; //setupStatusIndicator.isHidden = true; setupStatusIndicator.stopAnimating()
        
        if savedDataFound{
            
            let delayInSeconds = 0.5
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds)
            {
                self.loadPreviousGameView.isHidden = false
            }
        }
        
        //Remove found service notification
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "foundCharacteristicID"), object:nil)
        //  Initialize scoreboard
        sendUpdates()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(EmulatedScoreboardViewController.sendUpdates), userInfo: nil, repeats: true)
    }
    /*==========================================================================================*/
    // Respond to count up or count down change
    /*==========================================================================================*/
    @IBAction func countDirectionChanged(_ sender: UISegmentedControl)
    {
        var directionToCount: TimeKeeperImproved.countDirection = .up
        if !(betterClock?.timerIsRunning)!
        {
            betterClock?.resetTimer()
            switch sender.selectedSegmentIndex
            {
            case 0: print("Count Up"); /*betterClock?.settings.countUpOrDown = .up;*/
                directionToCount = .up;
                betterClock?.changeCountDirection(direction: directionToCount)
            case 1: print("Count Down"); /*betterClock?.settings.countUpOrDown = .down*/
                directionToCount = .down
                betterClock?.changeCountDirection(direction: directionToCount)
            default: print("Do nothing")
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTimeID"), object: self, userInfo: nil)
        }
    }
    /*==========================================================================================*/
    //  Respond to button presses for buttons in timeSetupView
    /*==========================================================================================*/
    @IBAction func timeSetupViewButton(_ sender: UIButton) {
        
        if let title = sender.titleLabel?.text{
            
            switch title{
            case "SET": print("Set button pressed");
                timeSetupView.layer.isHidden = true
                switch clockOrPeriod.selectedSegmentIndex{
                case 0: betterClock?.setPeriod(period: Int(periodTimeToSet)!); betterClock?.settings.usePeriod = true
                case 1: betterClock?.setClock(time: Int(clockTimeToSet)!); betterClock?.settings.usePeriod = false
                default: print("do nothing")
                }
            case "CANCEL": print("Cancel button pressed");
                timeSetupView.layer.isHidden = true
            default: print("No button found")
            }
        }
    }
    /*==========================================================================================*/
    //  User wants to edit time so show timeSetupView to select value
    /*==========================================================================================*/
    @IBAction func editTime(_ sender: UIButton)
    {
        if !(betterClock?.timerIsRunning)!
        {
            if timeSetupView.isHidden{
                
                timeSetupView.layer.isHidden = false
                
            }else{
                
                timeSetupView.layer.isHidden = true
            }
        }
    }
    /*==========================================================================================*/
    //  Respond to button presses for buttons in timerView
    /*==========================================================================================*/
    @IBAction func timerViewButton(_ sender: UIButton)
    {
        
        if let title = sender.titleLabel?.text{
            switch title{
            case "START": print("Timer Start button pressed"); sender.setTitle("STOP", for: .normal)
                //clock?.startTimer()
                betterClock?.startTimer()
                countDirection.isHidden = true; editTimerSettingsButton.layer.isHidden = true
                print("Start Timer")
                flashMiniTimeView = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(EmulatedScoreBoardAlternateViewController.flashMiniTimerBorder), userInfo: nil, repeats: true)
                
            case "RESET": print("Timer Reset button pressed")
                //clock?.resetTimer()
                if !((betterClock?.timerIsRunning)!)
                {
                   betterClock?.resetTimer()
                }
            case "STOP": print("Stop button pressed"); sender.setTitle("START", for: .normal)
                flashMiniTimeView?.invalidate()
                //clock?.stopTimer()
                betterClock?.stopTimer()
                print("Stop Timer")
            
                countDirection.isHidden = false; editTimerSettingsButton.layer.isHidden = false
            default: print("no button match")
            }
        }
    }
    /*==========================================================================================*/
    //  View Timer Button
    /*==========================================================================================*/
    @IBAction func showTimer(_ sender: AnyObject)
    {
        
        if timerView.isHidden == false{
            
            print("Hide Timer View")
            timerView.isHidden = true
            blurView.isHidden = true
            
        }else{
            
            print("Show Timer View")
            timerView.isHidden = false
            blurView.isHidden = false
        }
    }
    /*==========================================================================================*/
    //  User incremented or decremented ball count
    /*==========================================================================================*/
    @IBAction func ballIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
            if (sender.value == 4){sender.value = 0}
            switch Int(sender.value){
            case 0: self.ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalNoBalls.png")
            case 1: self.ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalOneBall.png")
            case 2: self.ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalTwoBalls.png")
            case 3: self.ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinal.png")
            default: self.ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalNoBalls.png")
            }
            self.sendUpdates()
    }
    /*==========================================================================================*/
    //  User incremented or decremented strike count
    /*==========================================================================================*/
    @IBAction func strikeIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 3){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        switch Int(sender.value){
        case 0: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        case 1: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinalOneBall.png")
        case 2: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinal.png")
        default: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        }
        
        sendUpdates()
    }
    /*==========================================================================================*/
    //  User incremented or decremented out count
    /*==========================================================================================*/
    @IBAction func outIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 3){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        switch Int(sender.value){
        case 0: outCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        case 1: outCount.image = #imageLiteral(resourceName: "TwoBallsFinalOneBall.png")
        case 2: outCount.image = #imageLiteral(resourceName: "TwoBallsFinal.png")
        default: outCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        }
        
        sendUpdates()
    }
    /*==========================================================================================*/
    //  User incremented or decremented guest score
    /*==========================================================================================*/
    @IBAction func guestScoreIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 99){sender.value = 0}
        
        switch Int(sender.value)
        {
        case 1...9:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
            setDigit(value: Int(sender.value), imageSegment: guestScore1Digit)
        case 10...19:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N1.png")
            let countToShow = Int(sender.value) - 10
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 20...29:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N2.png")
            let countToShow = Int(sender.value) - 20
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 30...39:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N3.png")
            let countToShow = Int(sender.value) - 30
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 40...49:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N4.png")
            let countToShow = Int(sender.value) - 40
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 50...59:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N5.png")
            let countToShow = Int(sender.value) - 50
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 60...69:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N6.png")
            let countToShow = Int(sender.value) - 60
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 70...79:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N7.png")
            let countToShow = Int(sender.value) - 70
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 80...89:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N8.png")
            let countToShow = Int(sender.value) - 80
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        case 90...99:
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N9.png")
            let countToShow = Int(sender.value) - 90
            setDigit(value: countToShow, imageSegment: guestScore1Digit)
        default:
            guestScore1Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
        }
        sendUpdates()
    }
    /*==========================================================================================*/
    //  User incremented or decremented inning count
    /*==========================================================================================*/
    @IBAction func inningIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 10){sender.value = 1}
        // Set new value and send updates to scoreboard
        setDigit(value: Int(sender.value), imageSegment: inningCount1Digit)
        sendUpdates()
    }
    /*==========================================================================================*/
    //  User incremented or decremented home score
    /*==========================================================================================*/
    @IBAction func homeScoreIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 99){sender.value = 0}
        
        switch Int(sender.value)
        {
        case 1...9:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
            setDigit(value: Int(sender.value), imageSegment: homeScore1Digit)
        case 10...19:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N1.png")
            let countToShow = Int(sender.value) - 10
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 20...29:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N2.png")
            let countToShow = Int(sender.value) - 20
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 30...39:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N3.png")
            let countToShow = Int(sender.value) - 30
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 40...49:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N4.png")
            let countToShow = Int(sender.value) - 40
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 50...59:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N5.png")
            let countToShow = Int(sender.value) - 50
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 60...69:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N6.png")
            let countToShow = Int(sender.value) - 60
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 70...79:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N7.png")
            let countToShow = Int(sender.value) - 70
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 80...89:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N8.png")
            let countToShow = Int(sender.value) - 80
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        case 90...99:
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N9.png")
            let countToShow = Int(sender.value) - 90
            setDigit(value: countToShow, imageSegment: homeScore1Digit)
        default:
            homeScore1Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
        }
        sendUpdates()
    }
    /*==========================================================================================*/
    //  Update time display
    /*==========================================================================================*/
    func updateTime(_ notification: Notification)
    {
        saveTime = currentTime
        
        if ((betterClock?.clockTime)!/60 == 99){betterClock?.clockTime = 0}
        
        currentTime = (betterClock?.clockTime)!
        
        print("Current Time before modification = \(currentTime)")
        var correctDisplay = 0
        
        if currentTime > 60{
            
            timeUnitsCurrent = .minutes
            currentTime = currentTime/60
            
            if betterClock?.settings.countUpOrDown == .up {
                
                correctDisplay = 0
                print("Add one")
                
            }else if betterClock?.settings.countUpOrDown == .down && (betterClock?.timerIsRunning)!{
                
                correctDisplay = 1
                print("Add one")
            }
            
        }else{
            
            timeUnitsCurrent = .seconds
        }
        print("currentTime to show = \(currentTime + correctDisplay)")
        
        switch Int(currentTime){
            
        case 1...9:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
            setDigit(value: Int(currentTime), imageSegment: miniTimer1Digit)
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
            setDigit(value: Int(currentTime), imageSegment: bigTimer1Digit)
            
        case 10...19:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N1.png")
            let countToShow = Int(currentTime) - 10
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N1.png")
            let countToShow2 = Int(currentTime) - 10
            print("count = \(currentTime)")
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
            
        case 20...29:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N2.png")
            let countToShow = Int(currentTime) - 20
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N2.png")
            let countToShow2 = Int(currentTime) - 20
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
            
        case 30...39:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N3.png")
            let countToShow = Int(currentTime) - 30
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N3.png")
            let countToShow2 = Int(currentTime) - 30
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
            
        case 40...49:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N4.png")
            let countToShow = Int(currentTime) - 40
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N4.png")
            let countToShow2 = Int(currentTime) - 40
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
            
        case 50...59:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N5.png")
            let countToShow = Int(currentTime) - 50
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N5.png")
            let countToShow2 = Int(currentTime) - 50
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
            
        case 60...69:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N6.png")
            let countToShow = Int(currentTime) - 60
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N6.png")
            let countToShow2 = Int(currentTime) - 60
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
        case 70...79:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N7.png")
            let countToShow = Int(currentTime) - 70
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N7.png")
            let countToShow2 = Int(currentTime) - 70
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
        case 80...89:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N8.png")
            let countToShow = Int(currentTime) - 80
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N8.png")
            let countToShow2 = Int(currentTime) - 80
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
        case 90...99:
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N9.png")
            let countToShow = Int(currentTime) - 90
            setDigit(value: countToShow, imageSegment: miniTimer1Digit)
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N9.png")
            let countToShow2 = Int(currentTime) - 90
            setDigit(value: countToShow2, imageSegment: bigTimer1Digit)
        default:
            miniTimer1Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
            miniTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
            bigTimer1Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
            bigTimer10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-BLANK.png")
        }
        sendUpdates()
        
        if !startShutDown{
            saveData()
        }
        
    }
    /*==========================================================================================*/
    //  Set correct image for corresponding integer value
    /*==========================================================================================*/
    func setDigit(value: Int, imageSegment: UIImageView)
    {
        switch value{
        case 0: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")  //Zero image
        case 1: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N1.png")  //...
        case 2: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N2.png")
        case 3: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N3.png")
        case 4: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N4.png")
        case 5: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N5.png")
        case 6: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N6.png")
        case 7: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N7.png")
        case 8: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N8.png")
        case 9: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N9.png")
        default: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
        }
    }
    /*==========================================================================================*/
    //  Send current scoreboard state data to scoreboard
    /*==========================================================================================*/
    func sendUpdates()
    {
        //  Can't send updates until setup is finished
        if !debug{if !setupComplete{return}}
        
        // Create protocol packet to send
        var returnedProtocolStrings: (string1: NSData, string2: NSData)?
        returnedProtocolStrings = MultidropPacketBuilderSharedInstance.convertValuesToProtocalString(String(Int(numberOfBalls.value)), strikes: String(Int(numberOfStrikes.value)), outs: String(Int(numberOfOuts.value)), guestScore: String(Int(guestScore.value)), inningCount: String(Int(numberOfInnings.value)), homeScore: String(Int(homeScore.value)), currentTime: "\(currentTime)")
        
        let firstRange: NSRange = NSRange(location: 0, length: 16)//0...15
        let secondRange: NSRange = NSRange(location: 16, length: 5)//16...20
        
        //print("Retuned Protocol String1: \(returnedProtocolStrings!.string1) String2: \(returnedProtocolStrings!.string2))")
        
        // Send updates to scoreboard by writing protocol data to scoreboard characteristic
        if !debug{
            
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string1 as Data, characteristic: scoreboardCharacteristic!)
        }
        // Had to break up packet on app side to accomodate project running on eval kit.  Better to handle this on the devkit
        // side in the future
        if !debug{
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string2.subdata(with: firstRange) as Data, characteristic: scoreboardCharacteristic!)
            BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(returnedProtocolStrings!.string2.subdata(with: secondRange) as Data, characteristic: scoreboardCharacteristic!)
        }
    }
    /*==========================================================================================*/
    // Inidcate timer second tick by flashing miniTimeView boarder from white to yellow once a second
    /*==========================================================================================*/
    func flashMiniTimerBorder()
    {
        if flashToggle{
            
            flashToggle = false
            //flash from white to yellow
            miniTimeView.layer.borderColor = UIColor(red:254/255.0, green:189/255.0, blue:9/255.0, alpha: 1.0).cgColor
            
        }else{
            
            flashToggle = true
            //flash from yellow to white
            miniTimeView.layer.borderColor = UIColor(red:255/255.0, green:255/255.0, blue:255/255.0, alpha: 1.0).cgColor
        }
    }
    /*==========================================================================================*/
    // Setup custom UI settings
    /*==========================================================================================*/
    func setupUI()
    {
        previousGameDataStatus.isHidden = true
        loadPreviousGameView.isHidden = true
        self.navigationController?.isNavigationBarHidden = true//hide navigation controller bar
        timerView.isHidden = true
        blurView.isHidden = true

        miniTimeView.layer.borderWidth         = 3
        miniTimeView.layer.borderColor         = UIColor(red:254/255.0,
                                                         green:189/255.0,
                                                         blue:9/255.0,
                                                         alpha: 1.0).cgColor
        
        timerStartStopButton.layer.borderWidth = 1
        timerStartStopButton.layer.borderColor = UIColor(red:254/255.0,
                                                         green:189/255.0,
                                                         blue:9/255.0,
                                                         alpha: 1.0).cgColor
        timeResetButton.layer.borderWidth      = 1
        timeResetButton.layer.borderColor      = UIColor(red:254/255.0,
                                                         green:189/255.0,
                                                         blue:9/255.0,
                                                         alpha: 1.0).cgColor
        
        timeSetupView.layer.borderWidth        = 1
        timeSetupView.layer.borderColor        = UIColor(red:254/255.0,
                                                         green:189/255.0,
                                                         blue:9/255.0,
                                                         alpha: 1.0).cgColor
        timeSetupView.layer.isHidden = true
        
        self.blurView.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        //always fill the view
        blurEffectView.frame = self.blurView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.97
        self.blurView.addSubview(blurEffectView)
    }
    /*==========================================================================================*/

}

/*==========================================================================================*/
//
//  Extensions
//
/*==========================================================================================*/
extension EmulatedScoreBoardAlternateViewController: UIPickerViewDataSource
{
    func numberOfComponents(in timePicker: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return measurementPickerData.count
    }
    
}
/*==========================================================================================*/
extension EmulatedScoreBoardAlternateViewController: UIPickerViewDelegate
{
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
    {
        print("Load Data")
        let titleData = measurementPickerData[row] + " Minutes"
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont(name: "Helvetica Neue", size: 15.0)!,NSForegroundColorAttributeName:UIColor(red:254/255.0, green:189/255.0, blue:9/255.0, alpha: 1.0)])
        
        return myTitle
    }

    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        print("User Selected Option from Picker View \(measurementPickerData[row])")
        var numberSelected = Int(measurementPickerData[row])!
        print("number selected = \(numberSelected)")
        
        switch clockOrPeriod.selectedSegmentIndex
        {
        case 0:
            periodTimeToSet = measurementPickerData[row]
            print("")
        case 1:
            print("")
            clockTimeToSet = measurementPickerData[row]
        default: print("NA")
        }
    }
}







//print("Time units pulled = \(timeUnitsPulled)")
//if timeUnitsPulled == 1{//units in minutes, multiply by 60

//betterClock?.clockTime = savedCurrentTime * 60
//currentTime = savedCurrentTime * 60

//}else{







