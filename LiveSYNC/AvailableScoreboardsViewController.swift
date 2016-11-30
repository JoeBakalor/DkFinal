//
//  AvailableScoreboardsViewController.swift
//  LiveSYNC
//
//  Created by Joe Bakalor on 11/18/16.
//  Copyright © 2016 Joe Bakalor. All rights reserved.
//

import UIKit
import CoreBluetooth
public var debug = false


class AvailableScoreboardsViewController: UIViewController
{
    /*==========================================================================================*/
    //
    //  UI Outlets
    //
    /*==========================================================================================*/
    @IBOutlet weak var availableScoreboardsTableView: UITableView! //  Table to display compatible scoreboards found
    @IBOutlet weak var connectingView: UIView!  //  Connection status window overlay
    @IBOutlet weak var connectionStatus: UIActivityIndicatorView!  // Spinning indicator
    @IBOutlet weak var connectingViewLabel: UILabel!
    @IBOutlet weak var simulatedSwitch: UISwitch!
    /*==========================================================================================*/
    //
    // Constants
    //
    /*==========================================================================================*/
    /*==========================================================================================*/
    //
    // Variables
    //
    /*==========================================================================================*/
    var listOfPeripherals: [AnyObject] = []
    var listOfPeripheralsCopy: [AnyObject] = []  //used to check for duplicate entries
    var duplicateFound: Bool = false
    var timer = Timer()
    var bluetoothReady: Bool = false
    /*==========================================================================================*/
    //
    // Do initial setup when view loads
    //
    /*==========================================================================================*/
    override func viewDidLoad()
    {
        //super.viewDidLoad()
        availableScoreboardsTableView.layer.cornerRadius = 10
        
        //  Should use an initializer instead
        BLEConnectionManagerSharedInstance //this has to be called to recieve notification that bluetoothState powered on
        
        //  MAY NEED TO (SHOULD) REMOVE OBSERVERS BEFORE LEAVING VIEW OTHERWISE THERE MAY BE ERRORS
        //  Add observer for when scoreboards are found
        NotificationCenter.default.addObserver(self, selector: #selector(AvailableScoreboardsViewController.foundScoreboardPeripheral(_:)), name: NSNotification.Name(rawValue: "foundPeripheralID"), object: nil)
        //  Add observer for when connection to scoreboard succeeds
        NotificationCenter.default.addObserver(self, selector: #selector(AvailableScoreboardsViewController.connectionToPeripheralSuccessful(_:)), name: NSNotification.Name(rawValue: "connectedToPeripheralID"), object: nil)
        //  Add observer for when the connection to peripheral scorebaord fails, can be caused by connection timeout
        NotificationCenter.default.addObserver(self, selector: #selector(AvailableScoreboardsViewController.connectionToPeripheralFailed(_:)), name: NSNotification.Name(rawValue: "connectionToPeripheralFailedID"), object: nil)
        //  Add observer for bluetooth powered on
        NotificationCenter.default.addObserver(self, selector: #selector(AvailableScoreboardsViewController.bluetoothStatePoweredOn(_:)), name: NSNotification.Name(rawValue: "bluetoothNowPoweredOnID"), object: nil)
        
        connectingView.layer.isHidden = true
        connectionStatus.stopAnimating()
        connectionStatus.isHidden = true
    }
    
    @IBAction func simulatedSwitched(_ sender: UISwitch)
    {
        if sender.isOn
        {
            debug = true
        }
        else
        {
            debug = false
        }
        
        listOfPeripherals = []
        listOfPeripheralsCopy = []
        availableScoreboardsTableView.reloadData()
    }
    
    /*==========================================================================================*/
    //
    //  Recieved after confirmation of bluetooth powered on ---- ALWAYS WAIT FOR THIS BEFORE SCANNING
    //
    /*==========================================================================================*/
    func bluetoothStatePoweredOn(_ notification: Notification)
    {
        // Start looking for Scoreboards with UUID defined as constant
        bluetoothReady = true
        print("Received notification that bluetooth is now powered on, started scanning ")
        BLEConnectionManagerSharedInstance.startScanning([SerialServiceUUID])
    }
    /*==========================================================================================*/
    //
    // Do any initial setup when view re-appears after having already been loaded before
    //
    /*==========================================================================================*/
    override func viewDidAppear(_ animated: Bool)
    {
        listOfPeripherals = []
        listOfPeripheralsCopy = []
        availableScoreboardsTableView.reloadData()
        
        if bluetoothReady{
            BLEConnectionManagerSharedInstance.startScanning([SerialServiceUUID])
        }
    }
    /*==========================================================================================*/
    //
    // Take care of any loading that needs to be done just before view will appear
    //
    /*==========================================================================================*/
    override func viewWillAppear(_ animated: Bool)
    {
        availableScoreboardsTableView.reloadData()
    }
    /*==========================================================================================*/
    //
    // Take car of anything that needs to be done before view dissapears
    //
    /*==========================================================================================*/
    override func viewWillDisappear(_ animated: Bool)
    {
        //availableScoreboardsTableView.reloadData()
    }
    /*==========================================================================================*/
    //
    //  Handle data from new peripheral found and post to table
    //
    /*==========================================================================================*/
    func foundScoreboardPeripheral (_ notification: Notification)
    {
        //  Debug Statement
        print("Found Scoreboard")
        
        //save peripheral information to local variable for parsing
        let userInfo = notification.userInfo as! [String: AnyObject]
        let newPeripheral = userInfo["peripheralFound"] as! CBPeripheral!
        
        //rebuild listOfPeripherals check for and removing/replacing duplicate entries.  Updated info always used
        for entry in listOfPeripherals
        {
            let oldPeripheral = entry["peripheralFound"] as! CBPeripheral!
            
            if newPeripheral == oldPeripheral{
                duplicateFound = true
                listOfPeripheralsCopy.append(userInfo as AnyObject)
            }else{
                //duplicateFound = false
                listOfPeripheralsCopy.append(entry)
            }
            print("listOfPeripheralsCopy: \(listOfPeripheralsCopy)")
        }
        listOfPeripherals = listOfPeripheralsCopy
        
        //didnt find a duplicate so we just made a copy of the existing list above, so add the new peripheral to the list
        if !duplicateFound{
            listOfPeripherals.append(userInfo as AnyObject)
        }
        
        //clear copy
        listOfPeripheralsCopy = []
        self.availableScoreboardsTableView.reloadData()
    }
    /*==========================================================================================*/
    //
    //  Connection was succesful, now we can bring up the scoreboard GUI
    //
    /*==========================================================================================*/
    func connectionToPeripheralSuccessful (_ notification: Notification)
    {
        // Debug statement
        timer.invalidate()
        
        // Clear connectionView status window and stop indicator animation
        connectionStatus.stopAnimating(); connectionStatus.isHidden = true; connectingView.layer.isHidden = true
        
        print("Connected to Scoreboard!!")
        
        let newView = self.storyboard?.instantiateViewController(withIdentifier: "ScoreBoardViewController") as! ScoreBoardViewController!
        self.navigationController?.show(newView!, sender: self)
    }
    /*==========================================================================================*/
    //
    //  Connection failure handlers
    //
    /*==========================================================================================*/
    func connectionToPeripheralFailed (_ notification: Notification)
    {
        print("Connection to scoreboard failed :(")
        //  Let user know "Connection Failed"
        connectionStatus.stopAnimating(); connectionStatus.isHidden = true; connectingViewLabel.text! = "Connection Failed"
        
        //  Delay one second so user sees connection failed message
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AvailableScoreboardsViewController.connectionFailed), userInfo: nil, repeats: false);
    }
    /*==========================================================================================*/
    func connectionFailed()
    {
        // Clear connectionView status window and stop indicator animation
        connectingViewLabel.text! = "Connecting"; connectingView.layer.isHidden = true
        
        //  Clear Table data and Start scanning again
        listOfPeripherals = []; listOfPeripheralsCopy = []; availableScoreboardsTableView.reloadData()
        
        //  Re-start scanning since connnection failed
        BLEConnectionManagerSharedInstance.startScanning([SerialServiceUUID])
        
        //  Invalidate timer
        timer.invalidate()
    }
    /*==========================================================================================*/
    //
    //  Simulate successful connection for debugging purposes
    //
    /*==========================================================================================*/
    func simConnected()
    {
        //  Debug statement
        print("We are running sim so we can't actually make a connection so lets fake it")
        
        // Clear connectionView status window and stop indicator animation
        connectingView.layer.isHidden = true; connectionStatus.isHidden = true; connectionStatus.stopAnimating()
        
        let newView = self.storyboard?.instantiateViewController(withIdentifier: "ScoreBoardViewController") as! ScoreBoardViewController!
        self.navigationController?.show(newView!, sender: self)
    }
    /*==========================================================================================*/
}

extension AvailableScoreboardsViewController: UITableViewDataSource
{
    /*==========================================================================================*/
    //
    //  TableView number of rows in table
    //
    /*==========================================================================================*/
    func tableView(_ tableView: UITableView,numberOfRowsInSection section: Int) -> Int
    {
        print("Number of peripherals \(listOfPeripherals.count)")
        var count = 0
        if !debug{
            count = listOfPeripherals.count
        }
        else{
            count = 1
        }
        return count
    }
    /*==========================================================================================*/
    //
    //  TableView cell data and formatting
    //
    /*==========================================================================================*/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("cellForRowAtIndex")
        let cell = UITableViewCell()
        var peripheralData: AnyObject?
        
        if !debug
        {
            peripheralData = listOfPeripherals[indexPath.row]
        }
        
        var cellData = ""
        var numberOfLinesNeeded = 2
        
        // Setup cell style
        cell.textLabel?.textColor = UIColor(red: 60/255, green: 133/255, blue: 59/255, alpha: 1)
        cell.textLabel?.font = UIFont (name: "HelveticaNeue-Bold", size: 16)
        cell.textLabel?.textAlignment = .center
        cell.layer.cornerRadius = 6
        cell.layer.borderWidth = 2
        cell.layer.borderColor = UIColor(red: 60/255, green: 133/255, blue: 59/255, alpha: 1).cgColor
        
        // Pull Local Name From Peripheral
        if !debug
        {
            if let localName = peripheralData?["localName"] as! String!{
                numberOfLinesNeeded += 1
                cellData = cellData + "\(localName)"
                
            }
            
            if let rssi = peripheralData?["RSSI"] as! NSInteger!{
                numberOfLinesNeeded += 1
                cellData = cellData + "\rRSSI: [\(rssi)]"
            }
        }
        
        if debug
        {
            cellData = "Simulated Scoreboard"
        }

        cell.textLabel?.numberOfLines = numberOfLinesNeeded
        cell.textLabel?.text = cellData
        return cell
    }
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    private func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        let view:UIView = UIView()
        view.alpha = 0
        return view
    }
    /*==========================================================================================*/
}

// Mark: Table View Delegate
extension AvailableScoreboardsViewController: UITableViewDelegate
{
    /*==========================================================================================*/
    //
    //
    //
    /*==========================================================================================*/
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //  Indicate to user that connection attempt is in progress
        connectingView.layer.isHidden = false; connectionStatus.isHidden = false; connectingViewLabel.text! = "Connecting"; connectionStatus.startAnimating()
        
        //try to connect to peripheral
        if debug == false{
            BLEConnectionManagerSharedInstance.stopScanning()
            BLEConnectionManagerSharedInstance.connectToPeripheral((listOfPeripherals[indexPath.row])["peripheralFound"] as! CBPeripheral!)
            //timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(AvailableScoreboardsViewController.connectionTimeout), userInfo: nil, repeats: false);
        }
        else{
            timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(AvailableScoreboardsViewController.simConnected), userInfo: nil, repeats: false)
        }
    }
    /*==========================================================================================*/

}


/*==========================================================================================*/
//Need to move functionality to BLEConnectionManager
// Moved 11/28, now testing to remove here
/*func connectionTimeout()//Need to impliment connection timout in BLEConnectionManager class, not here
 {
 timer.invalidate()
 BLEConnectionManagerSharedInstance.cancelConnectionAttempt()
 }*/
