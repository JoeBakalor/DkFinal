//
//  EmulatedScoreboardViewController.swift
//  LiveSYNCiPad
//
//  Created by Joe Bakalor on 1/10/17.
//  Copyright © 2017 Joe Bakalor. All rights reserved.
//

import UIKit
import CoreBluetooth

let SerialCharacteristicUUID = CBUUID(string: "569A2001-B87F-490C-92CB-11BA5EA5167C") //UART-to-BLE Service
let SerialServiceUUID = CBUUID(string: "569A1101-B87F-490C-92CB-11BA5EA5167C")  //UART-to-BLE Characteristic
//var accessabileInstance: UIViewController

class EmulatedScoreboardViewController: UIViewController
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
    @IBOutlet weak var setupStatusIndicator: UIActivityIndicatorView!
    @IBOutlet weak var baseballStatusIndicator: UIImageView!
    /*==========================================================================================*/
    //
    //  Variables
    //
    /*==========================================================================================*/
    var protocolStringToSend: NSData?
    var scoreBoardPeripheral : CBPeripheral?
    var scoreboardService : CBService?
    var scoreboardCharacteristic : CBCharacteristic?  //need to write updates to this characteristic
    var setupComplete: Bool = false
    var timer: Timer?  //  Timer used for sending an a current status packet every 1 second
    /*==========================================================================================*/
    //
    //  Perform setup needed when view loads
    //
    /*==========================================================================================*/
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("Debug Status = \(debug)")
        
        //  Start animation to show that we are getting everything setup
        setupStatusIndicator.startAnimating(); setupView.layer.isHidden = false; setupStatusIndicator.isHidden = false
        
        if debug
        {
            setupView.layer.isHidden = true; setupStatusIndicator.isHidden = true; setupStatusIndicator.stopAnimating()
            sendUpdates()
        }
        
        baseballStatusIndicator.rotate360Degrees()
        
        self.navigationController?.isNavigationBarHidden = true//hide navigation controller bar
        if BLEConnectionManagerSharedInstance.getPeripheral() != nil{print("Found valid peripheral")}//check for valid connection
        
        //Start looking for the scoreboard service on the connected peripheral
        BLEConnectionManagerSharedInstance.bleService?.startDiscoveringServices([SerialServiceUUID])
        
        //Add observer to handle when the service is found
        NotificationCenter.default.addObserver(self, selector: (#selector(self.foundService(_:))), name: NSNotification.Name(rawValue: "foundServiceID"), object: nil)
        
        //Add observer to catch if or when peripheral connection fails
        NotificationCenter.default.addObserver(self, selector: (#selector(self.peripheralDisconnected(_:))), name: NSNotification.Name(rawValue: "connectionToPeripheralFailedID"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: (#selector(self.blankScoreboard)), name: NSNotification.Name(rawValue: "applicationWillTerminateID"), object: nil)
    }
    /*==========================================================================================*/
    //
    //  Called if the peripheral connection is terminated or fails, should let user know
    //
    /*==========================================================================================*/
    func peripheralDisconnected(_ notification: Notification)
    {
        print("Connection to scoreboard failed")
        self.navigationController?.popViewController(animated: false)//  Made ! instead of ?
    }
    /*==========================================================================================*/
    //
    // Take car of anything that needs to be done before view dissapears
    //
    /*==========================================================================================*/
    override func viewWillDisappear(_ animated: Bool)
    {
        //  Unsubscribe so this isnt called from another view
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "connectionToPeripheralFailedID"), object:nil)
        blankScoreboard() //  ADDED 1-16-17, HAVE NOT TESTED
        timer?.invalidate()
        BLEConnectionManagerSharedInstance.disconnectPeripheral()
        setupComplete = false
        self.navigationController?.isNavigationBarHidden = false
    }
    /*==========================================================================================*/
    //
    // Return to homescreen because user swiped right
    //
    /*==========================================================================================*/
    @IBAction func returnHome(_ sender: UISwipeGestureRecognizer)
    {
        print("User right swipe")
        
        // Create protocol packet to send
        //protocolStringToSend = MultidropPacketBuilderSharedInstance.blankScoreboard()
        
        print("Retuned Blanked Protocol String: \(protocolStringToSend)")
        
        // Send updates to scoreboard by writing protocol data to scoreboard characteristic
        //if !debug{BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(protocolStringToSend! as Data, characteristic: scoreboardCharacteristic!)}
        
        self.navigationController?.popViewController(animated: true)//  Made ! instead of ?
        
    }
    /*==========================================================================================*/
    //
    //  Called when correct service found, save reference to scoreboardService
    //
    /*==========================================================================================*/
    func blankScoreboard()
    {
        print("Request to blank scoreboard")
        
        //protocolStringToSend = MultidropPacketBuilderSharedInstance.blankScoreboard()
        
        print("Retuned Blanked Protocol String: \(protocolStringToSend)")
        
        //if !debug{BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(protocolStringToSend! as Data, characteristic: scoreboardCharacteristic!)}
    }
    /*==========================================================================================*/
    //
    //  Called when correct service found, save reference to scoreboardService
    //
    /*==========================================================================================*/
    func foundService(_ notification: Notification)
    {
        
        let userInfo = notification.userInfo as! [String: AnyObject]
        print("found service with data: \(userInfo)")
        let service = userInfo["service"] as! [CBService]!
        
        //  Save reference to scoreboard service
        scoreboardService = service?[0]
        
        //Start looking for the scoreboardCharacteristic
        BLEConnectionManagerSharedInstance.bleService?.peripheral?.discoverCharacteristics([SerialCharacteristicUUID], for: (service?[0])!)
        
        // Add observer for when the characteristic is found, only added if service which contains characteristic is found first
        NotificationCenter.default.addObserver(self, selector: #selector(ScoreBoardViewController.foundCharacteristic(_:)), name: NSNotification.Name(rawValue: "foundCharacteristicID"), object: nil)
    }
    /*==========================================================================================*/
    //
    //  Called when the correct characteristic we were looking for is found, save reference to characteristic
    //
    /*==========================================================================================*/
    func foundCharacteristic(_ notification: Notification)
    {
        setupComplete = true
        let userInfo = notification.userInfo as! [String: AnyObject]
        print("user info = \(userInfo)")
        var characteristicList = userInfo["characteristic"] as! [CBCharacteristic]!
        
        print("characteristic list: \(characteristicList)")
        scoreboardCharacteristic = characteristicList?[0]
        
        // Hide stutus view and stop antimating indicator since we have the characteristic to write to now
        setupView.layer.isHidden = true; setupStatusIndicator.isHidden = true; setupStatusIndicator.stopAnimating()
        
        //  Initialize scoreboard
        sendUpdates()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(EmulatedScoreboardViewController.sendUpdates), userInfo: nil, repeats: true)
    }
    /*==========================================================================================*/
    //
    //  User incremented or decremented ball count
    //
    /*==========================================================================================*/
    @IBAction func ballIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 4){sender.value = 0}

        switch Int(sender.value)
        {
        case 0: ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalNoBalls.png")
        case 1: ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalOneBall.png")
        case 2: ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalTwoBalls.png")
        case 3: ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinal.png")
        default: ballCount.image = #imageLiteral(resourceName: "ThreeBallsFinalNoBalls.png")
        }
        
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  User incremented or decremented strike count
    //
    /*==========================================================================================*/
    @IBAction func strikeIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 3){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        switch Int(sender.value)
        {
        case 0: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        case 1: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinalOneBall.png")
        case 2: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinal.png")
        default: strikeCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        }
        
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  User incremented or decremented out count
    //
    /*==========================================================================================*/
    @IBAction func outIncrementDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 3){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        switch Int(sender.value)
        {
        case 0: outCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        case 1: outCount.image = #imageLiteral(resourceName: "TwoBallsFinalOneBall.png")
        case 2: outCount.image = #imageLiteral(resourceName: "TwoBallsFinal.png")
        default: outCount.image = #imageLiteral(resourceName: "TwoBallsFinalNoBalls.png")
        }
        
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  User incremented or decremented guest score
    //
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
            guestScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
        }
        
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  User incremented or decremented inning count
    //
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
    //
    //  User incremented or decremented home score
    //
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
            homeScore10Digit.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
        }
        
        sendUpdates()
    }
    /*==========================================================================================*/
    func setDigit(value: Int, imageSegment: UIImageView)
    {
        switch value
        {
        case 0: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N0.png")
        case 1: imageSegment.image = #imageLiteral(resourceName: "7-SegmentFinal-N1.png")
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
    func sendUpdates()
    {
        //  Can't send updates until setup is finished
        if !debug{if !setupComplete{return}}
        
        // Create protocol packet to send
        //protocolStringToSend = MultidropPacketBuilderSharedInstance.convertValuesToProtocalString(String(Int(numberOfBalls.value)), strikes: String(Int(numberOfStrikes.value)), outs: String(Int(numberOfOuts.value)), guestScore: String(Int(guestScore.value)), inningCount: String(Int(numberOfInnings.value)), homeScore: String(Int(homeScore.value)), currentTime: "0")
        
        print("Retuned Protocol String: \(protocolStringToSend)")
        
        // Send updates to scoreboard by writing protocol data to scoreboard characteristic
        //if !debug{BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(protocolStringToSend! as Data, characteristic: scoreboardCharacteristic!)}
    }
    /*==========================================================================================*/

}
