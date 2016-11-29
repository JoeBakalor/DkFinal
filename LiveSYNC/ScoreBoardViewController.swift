//
//  ScoreBoardViewController.swift
//  LiveSYNC
//
//  Created by Joe Bakalor on 11/16/16.
//  Copyright © 2016 Joe Bakalor. All rights reserved.
//

import UIKit
import CoreBluetooth

let SerialCharacteristicUUID = CBUUID(string: "569A2001-B87F-490C-92CB-11BA5EA5167C")
let SerialServiceUUID = CBUUID(string: "569A1101-B87F-490C-92CB-11BA5EA5167C")

class ScoreBoardViewController: UIViewController {

    /*==========================================================================================*/
    //
    //  UI Outlets
    //
    /*==========================================================================================*/
    @IBOutlet weak var ballCount: UILabel!
    @IBOutlet weak var strikeCount: UILabel!
    @IBOutlet weak var outCount: UILabel!
    @IBOutlet weak var guestScore: UILabel!
    @IBOutlet weak var inningCount: UILabel!
    @IBOutlet weak var homeScore: UILabel!
    @IBOutlet weak var setupStatusView: UIView! // Setup status window
    @IBOutlet weak var setupStatusIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var LiveSYNCLabel: UILabel!
    
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
    //var timer = Timer()
    /*==========================================================================================*/
    //
    //  Take care of anything that needs to be done at loading
    //
    /*==========================================================================================*/
    override func viewDidLoad()
    {
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation)
        {
            LiveSYNCLabel.layer.isHidden = true
        }else{
            LiveSYNCLabel.layer.isHidden = false
        }
        //  Start animation to show that we are getting everything setup
        setupStatusIndicator.startAnimating()
        setupStatusView.layer.isHidden = false
        setupStatusIndicator.isHidden = false
        
        //scoreBoardPeripheral, check if we have a valid peripheral connection
        if BLEConnectionManagerSharedInstance.getPeripheral() != nil{
            print("Found valid peripheral")
        }
        
        //Start looking for the scoreboard service on the connected peripheral
        BLEConnectionManagerSharedInstance.bleService?.startDiscoveringServices([SerialServiceUUID])
        //  Setup a timer to call a function if setup fails or takes too long.  Report scoreboard error to user
        
        //  Add observer to handle when the service is found
        NotificationCenter.default.addObserver(self, selector: (#selector(ScoreBoardViewController.foundService(_:))), name: NSNotification.Name(rawValue: "foundServiceID"), object: nil)
        
        // Detect rotation changes
        NotificationCenter.default.addObserver(self, selector: #selector(ScoreBoardViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        //!!!!!!******COMMENTED OUT BECUASE OF WARNING, IF BREAKS CHANGE BACK NOVEMBER 23
        //MultidropPacketBuilderSharedInstance//init the class instance so we can start using it
    }
    /*==========================================================================================*/
    //
    //  Take care of anything that needs to be modified for landscape orientation
    //
    /*==========================================================================================*/
    func rotated()
    {
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            print("Landscape")
            LiveSYNCLabel.layer.isHidden = true
        }
        
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            print("Portrait")
            LiveSYNCLabel.layer.isHidden = false
        }
    }
    /*==========================================================================================*/
    //
    // Take car of anything that needs to be done before view dissapears
    //
    /*==========================================================================================*/
    override func viewWillDisappear(_ animated: Bool)
    {
        //  Unsubscribe so this isnt called from another view
        NotificationCenter.default.removeObserver(NSNotification.Name.UIDeviceOrientationDidChange)
        BLEConnectionManagerSharedInstance.disconnectPeripheral()
        setupComplete = false
        //availableScoreboardsTableView.reloadData()
        
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
    //  Called when the correct service we wanted is found, save reference to characteristic
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
        setupStatusView.layer.isHidden = true
        setupStatusIndicator.isHidden = true
        setupStatusIndicator.stopAnimating()
    }
    /*==========================================================================================*/
    //
    //  Ball incremented or decremented by user
    //
    /*==========================================================================================*/
    @IBAction func ballIncrementOrDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 4){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        ballCount.text = "\(Int(sender.value))"
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  Strikes incremented or decremented by user
    //
    /*==========================================================================================*/
    @IBAction func strikeIncrementOrDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 3){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        strikeCount.text = "\(Int(sender.value))"
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  Outs incremented or decremented
    //
    /*==========================================================================================*/
    @IBAction func outIncrementOrDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 3){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        outCount.text = "\(Int(sender.value))"
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  Guest score incremented or decremented by user
    //
    /*==========================================================================================*/
    @IBAction func guestScoreIncrementOrDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 99){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        guestScore.text = "\(Int(sender.value))"
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  Inning incremented or decremented by user
    //
    /*==========================================================================================*/
    @IBAction func inningIncrementOrDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 10){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        inningCount.text = "\(Int(sender.value))"
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  Home score incremented or decremented by user
    //
    /*==========================================================================================*/
    @IBAction func homeScoreIncrementOrDecrement(_ sender: UIStepper)
    {
        print("\(sender.value)")
        if (sender.value == 99){sender.value = 0}
        
        // Set new value and send updates to scoreboard
        homeScore.text = "\(Int(sender.value))"
        sendUpdates()
    }
    /*==========================================================================================*/
    //
    //  Send updates to scoreboard
    //
    /*==========================================================================================*/
    func sendUpdates()
    {
        //  Can't send updates until setup is finished 
        if !setupComplete{return}
        
        // Create protocol packet to send
        protocolStringToSend = MultidropPacketBuilderSharedInstance.convertValuesToProtocalString(ballCount.text!, strikes: strikeCount.text!, outs: outCount.text!, guestScore: guestScore.text!, inningCount: inningCount.text!, homeScore: homeScore.text!)
        print("Retuned Protocol String: \(protocolStringToSend)")
        
        // Send updates to scoreboard by writing protocol data to scoreboard characteristic
        BLEConnectionManagerSharedInstance.bleService?.writeValueToCharacteristic(protocolStringToSend! as Data, characteristic: scoreboardCharacteristic!)
    }
    /*==========================================================================================*/

}
