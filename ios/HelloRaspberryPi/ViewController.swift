//
//  ViewController.swift
//  HelloRaspberryPi
//
//  Created by Sebastian Buys on 4/11/18.
//  Copyright © 2018 mobilelab. All rights reserved.
//

import UIKit
import CoreBluetooth


// Unique identifier for your BLE Peripheral, Service(s), and Characteristic(s)
// Change these values
// Make sure they match the values on your BLE device (Raspberry Pi)
let PERIPHERAL_NAME = "My Awesome Servo"
let PERIPHERAL_UUID_STRING = "89f3cea5-7619-4c7f-9114-1fd62a5bce2d"

let FIRSTSERVO_SERVICE_UUID_STRING = "08196144-d50c-4a48-af4b-1337c47bbcb9";
let FIRSTSERVO_CHARACTERISTIC_UUID_STRING = "44f6b86f-43e6-4c7b-8cab-820b7dfb441e";

let SECONDSERVO_SERVICE_UUID_STRING = "71059488-69db-49f6-8121-319e5d730e33";
let SECONDSERVO_CHARACTERISTIC_UUID_STRING = "1af42567-4a2c-4a8d-bffd-0b9b8e406d68";

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    
    // Store references to the CoreBluetooth objects here as we discover them.
    var myPi: CBPeripheral?
    
    var firstServoService: CBService?
    var firstServoPositionCharacteristic: CBCharacteristic?
    
    var secondServoService: CBService?
    var secondServoPositionCharacteristic: CBCharacteristic?
    
    @IBOutlet weak var firstServoSlider: UISlider!
    
    @IBAction func firstSliderValue(_ sender: UISlider) {
        
        print("First slider value: ", sender.value)
        
                // Make sure we already have a reference to our pi
                guard let pi = myPi else {
                    return
                }
        
                // Make sure we already have a reference to the servo position characteristic
                guard let firstPosCharacteristic = firstServoPositionCharacteristic else {
                    return
                }
        
                // Instead of sending a float value to our pi, we simplify by converting to a Int (0-100)
                var firstSliderValue = Int(sender.value * 100)
        
                // Convert the Int to Data
                let firstServoData = Data(bytes: &firstSliderValue, count: MemoryLayout.size(ofValue: firstSliderValue))
        
                print(">>> 1st Value to raspberry pi:", firstSliderValue)
        
                // Write the characteristic value
                pi.writeValue(firstServoData, for: firstPosCharacteristic, type: .withResponse)
    }
    
    
    @IBOutlet weak var secondServoSlider: UISlider!
    
    
    @IBAction func secondSliderValue(_ sender: UISlider) {
        
        print("Second slider value: ", sender.value)
        
        // Make sure we already have a reference to our pi
        guard let pi = myPi else {
            return
        }
        
        // Make sure we already have a reference to the servo position characteristic
        guard let secondPosCharacteristic = secondServoPositionCharacteristic else {
            return
        }
        
        // Instead of sending a float value to our pi, we simplify by converting to a Int (0-100)
        var secondSliderValue = Int(sender.value * 100)
        
        // Convert the Int to Data
        let secondServoData = Data(bytes: &secondSliderValue, count: MemoryLayout.size(ofValue: secondSliderValue))
        
        print(">>> 2nd Value to raspberry pi:", secondSliderValue)
        
        // Write the characteristic value
        pi.writeValue(secondServoData, for: secondPosCharacteristic, type: .withResponse)
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Set the slider to only update after user has finished interacting, not everytime they move
        // This is to prevent spamming the raspberry pi with requests.
        // May not be necessary to throttle like this.
        self.firstServoSlider.isContinuous = false
        self.secondServoSlider.isContinuous = false
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("central manager did update state:", central)
        if (central.state == .poweredOn) {
            print("Manager is powered on! Scanning  for peripherals...")

            // Just scan for our Raspberry Pi
            // central.scanForPeripherals(withServices: serviceIds, options: nil)
            
            // Scan for all peripherals
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    
    // MARK: CBCentralManager delegate methods

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.name == PERIPHERAL_NAME) {
            print(">>> Found our BLE peripheral:", PERIPHERAL_NAME)
            myPi = peripheral
            
            // Connect to the peripheral
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(">>> Connected to our peripheral:", peripheral.identifier.uuidString)
        
        // Assign ourselves as the delegate of the peripheral and search for our servo service
        // As the delegate, we receive messages from the peripheral when we implement methods in the CBPeripheralDelegate protocol
        // https://developer.apple.com/documentation/corebluetooth/cbperipheraldelegate
        
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: FIRSTSERVO_SERVICE_UUID_STRING)])
        peripheral.discoverServices([CBUUID(string: SECONDSERVO_SERVICE_UUID_STRING)])
        
        // Passing nil will search for all services.
        // peripheral.discoverServices(nil)
    }
    
    
    // MARK: CBPeripheralDelegate methods
    // Called when a peripheral for which we are the delegate (peripheral.delegate) discovers services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        // print(">>> Discovered services:", peripheral.services)
        
        // Look for our servo service by uuid. If we don't find it, exit.
        guard let FirstServoService = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: FIRSTSERVO_SERVICE_UUID_STRING)
        }) else {
            return
        }
        
        guard let SecondServoService = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SECONDSERVO_SERVICE_UUID_STRING)
        }) else {
            return
        }
        
        // Store reference to the servo we just found
        firstServoService = FirstServoService
        secondServoService = SecondServoService
        
        // Search for characteristics of the service
        peripheral.discoverCharacteristics([CBUUID(string: FIRSTSERVO_CHARACTERISTIC_UUID_STRING)], for: FirstServoService)
        peripheral.discoverCharacteristics([CBUUID(string: SECONDSERVO_CHARACTERISTIC_UUID_STRING)], for: SecondServoService)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        
        //print(">>> Discovered characteristics:", service.characteristics)
        
        // Look for our servo position characteristic by uuid. If we don't find it, exit.
        guard let FirstServoPositionCharacteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: FIRSTSERVO_CHARACTERISTIC_UUID_STRING)
        }) else {
            return
        }
        
        guard let SecondServoPositionCharacteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: SECONDSERVO_CHARACTERISTIC_UUID_STRING)
        }) else {
            return
        }
        
        // Store reference
        firstServoPositionCharacteristic = FirstServoPositionCharacteristic
        secondServoPositionCharacteristic = SecondServoPositionCharacteristic
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
