//
//  TTNSDemoViewController.swift
//  TTNSDemo151213
//
//  Created by 山崎 慎太郎 on 2015/12/06.
//  Copyright © 2015年 山崎 慎太郎. All rights reserved.
//

import UIKit

import CoreBluetooth

class TTNSDemoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {

    enum TTNSStatus {
        case Connecting
        case Connected
        case Diconnected
        case WroteA
        case WroteB
    }
    
    @IBOutlet var btnA: UIButton!
    @IBOutlet var btnB: UIButton!
    @IBOutlet var btnStart: UIButton!
    @IBOutlet var lblLog: UILabel!
    @IBOutlet var tblDevices: UITableView!
    
    enum HeatPoint {
        case A
        case B
    }
    
    var heatPoint: HeatPoint?
    var isRunning = false
    
    var writeValue: [HeatPoint: String] = [:]
    
    var centralManager: CBCentralManager = CBCentralManager.init()
    var peripherals: [CBPeripheral] = []
    var characteristics: [String: CBCharacteristic] = [:]
    var status: [String: TTNSStatus] = [:]
    var rssis: [String: String] = [:]
    
    let kServiceUUID = "ADA99A7F-888B-4E9F-8080-07DDC240F3CE"
    let kWriteUUID = "ADA99A7F-888B-4E9F-8082-07DDC240F3CE"
    let kReadUUID = "ADA99A7F-888B-4E9F-8081-07DDC240F3CE"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // セントラルマネージャ初期化
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        
        tblDevices.delegate = self
        tblDevices.dataSource = self
        
        lblLog.text = ""
        btnStart.setTitle("AかBを選択", forState: UIControlState.Normal)
        btnStart.enabled = false
        
        reloadSendNum()
    }
    
    func reloadSendNum() {
        if (NSUserDefaults.standardUserDefaults().stringForKey("NUM_A") == nil) {
            NSUserDefaults.standardUserDefaults().setObject("08", forKey: "NUM_A")
        }
        if (NSUserDefaults.standardUserDefaults().stringForKey("NUM_B") == nil) {
            NSUserDefaults.standardUserDefaults().setObject("18", forKey: "NUM_B")
        }
        if (NSUserDefaults.standardUserDefaults().stringForKey("RSSI") == nil) {
            NSUserDefaults.standardUserDefaults().setInteger(-100, forKey: "RSSI")
        }
    }

    func disconnect() {
        // スキャン停止
        centralManager.stopScan()
        let log: String = "Stop Scan"
        lblLog.text = log
        print(log)
        
        for peripheral in peripherals {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        peripherals.removeAll()
        
        tblDevices .reloadData()
        
        btnStart.setTitle("AかBを選択", forState: UIControlState.Normal)
        btnA.enabled = true
        btnB.enabled = true
        btnA.backgroundColor = UIColor.clearColor()
        btnB.backgroundColor = UIColor.clearColor()
        btnStart.enabled = false
        heatPoint = nil
    }
    
    func connect() {
        // スキャン開始
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
        let log: String = "Start Scan"
        lblLog.text = log
        print(log)
        
        btnStart.setTitle("ストップ", forState: UIControlState.Normal)
        btnA.enabled = false
        btnB.enabled = false
    }

    
    // MARK: IBAction
    @IBAction func onBack(senfer: AnyObject) {
        self.disconnect()
        isRunning = false
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onSetting(sender: AnyObject) {
        self.performSegueWithIdentifier("TECHSETTING", sender: self)
    }
    
    @IBAction func onA(sender: AnyObject) {
        heatPoint = HeatPoint.A
        btnA.backgroundColor = UIColor.redColor()
        btnB.backgroundColor = UIColor.clearColor()
        
        btnStart.setTitle("A スタート", forState: UIControlState.Normal)
        btnStart.enabled = true
    }
    
    @IBAction func onB(sender: AnyObject) {
        heatPoint = HeatPoint.B
        btnB.backgroundColor = UIColor.redColor()
        btnA.backgroundColor = UIColor.clearColor()
        
        btnStart.setTitle("B スタート", forState: UIControlState.Normal)
        btnStart.enabled = true
    }
    
    @IBAction func onStart(sender: AnyObject) {
        if (heatPoint == nil) {
            lblLog.text = "AかBのボタンを押してください"
            
            return
        }
        
        if (!isRunning) {
            self.connect()
            isRunning = true
        } else {
            self.disconnect()
            isRunning = false
        }
    }
    
    // MARK: - TableDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        let peripheral = peripherals[indexPath.row]
        
        var stxt: String = ""
        
        switch status[peripheral.identifier.UUIDString]! as TTNSStatus {
        case TTNSStatus.Connecting:
            stxt = "Connecting"
            cell.textLabel?.textColor = UIColor.blackColor()
            break
        case TTNSStatus.Connected:
            stxt = "Connected"
            cell.textLabel?.textColor = UIColor.blueColor()
            break
        case TTNSStatus.Diconnected:
            stxt = "Disconnected"
            cell.textLabel?.textColor = UIColor.redColor()
            break
        case TTNSStatus.WroteA:
            stxt = "Wrote A"
            cell.textLabel?.textColor = UIColor.greenColor()
            break
        case TTNSStatus.WroteB:
            stxt = "Wrote B"
            cell.textLabel?.textColor = UIColor.greenColor()
            break
        }

        let log: String = String(format: "%@\n%@\n%@", peripheral.name!, stxt, peripheral.identifier.UUIDString)
        
        cell.textLabel?.text = log
        cell.textLabel?.numberOfLines = 3
        cell.textLabel?.font = UIFont(name: "AppleGothic", size: 10)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: - Writre
    func write(peripheral: CBPeripheral) {
        var num:String = ""
        switch heatPoint! as HeatPoint {
            case .A:
                status[peripheral.identifier.UUIDString] = TTNSStatus.WroteA
                num = NSUserDefaults.standardUserDefaults().stringForKey("NUM_A")!
                break
            case .B:
                status[peripheral.identifier.UUIDString] = TTNSStatus.WroteB
                num = NSUserDefaults.standardUserDefaults().stringForKey("NUM_B")!
                break
        }
        
        let num_nsdata = num.dataUsingEncoding(NSASCIIStringEncoding)
        let datalength = num_nsdata?.length
        var num_array = [CUnsignedChar](count: datalength!, repeatedValue: 0)
        num_nsdata?.getBytes(&num_array, length: datalength!)
        
        var cmd: [CUnsignedChar] = [0x05, 0x00, 0x00, 0x00]
        
        
        for (var i: Int = 4; i - 4 < datalength; i++) {
            let c: CUnsignedChar = num_array[i - 4]
            cmd.append(c)
        }
        print("%s", cmd)
        
        let cmd_data: NSData = NSData(bytes: cmd, length: cmd.count)
        
        print("%@", cmd_data)
        
        // 書き込み
        let characteristic = characteristics[peripheral.identifier.UUIDString]
        if (characteristic != nil) {
            // 書き込み
            peripheral.writeValue(cmd_data, forCharacteristic: characteristic!, type: CBCharacteristicWriteType.WithResponse)
            
            let log: String = String(format: "Write %@ %@", num, peripheral.identifier.UUIDString)
            print(log)
            lblLog.text = log
            
            switch heatPoint! as HeatPoint {
                case .A:
                    status[peripheral.identifier.UUIDString] = TTNSStatus.WroteA
                    break
                case .B:
                    status[peripheral.identifier.UUIDString] = TTNSStatus.WroteB
                    break
            }
            
            tblDevices.reloadData()
        }
        
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
    }
    
    // ペリフェラルを発見
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        if (peripheral.state == CBPeripheralState.Disconnected) {
            if peripheral.name == nil {
                return
            }
            let log: String = String(format: "Find Peripheral: %@", peripheral.name!)
            lblLog.text = log
            print(log)
            
            // NameがIMBLE0083なら接続
            if (!peripheral.name!.hasPrefix("IMBLE")) {
                return
            }
            
            peripherals.append(peripheral)
            status[peripheral.identifier.UUIDString] = TTNSStatus.Connecting
            tblDevices.reloadData()
            
            // ペリフェラルに接続
            centralManager.connectPeripheral(peripheral, options: nil)
        }
        
    }
    
    // ペリフェラルに接続成功
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        let log: String = String(format: "Connected Peripheral: %@", peripheral.name!)
        lblLog.text = log
        print(log)
        
        status[peripheral.identifier.UUIDString] = TTNSStatus.Connected
        tblDevices.reloadData()
        
        tblDevices.reloadData()
        
        peripheral.delegate = self
        // サービス検索
        peripheral.discoverServices(nil)
    }
    
    // ペリフェラル切断成功
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        if (error != nil) {
            print("%@", error)
            
            status[peripheral.identifier.UUIDString] = TTNSStatus.Connecting
            tblDevices.reloadData()
            
            centralManager.connectPeripheral(peripheral, options: nil)
            
            return
        }
        
        status[peripheral.identifier.UUIDString] = TTNSStatus.Diconnected
        tblDevices.reloadData()
        
        tblDevices.reloadData()
    }
    
    // 接続失敗
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        let log: String = String(format: "Fault Connect: %@", peripheral.name!)
        lblLog.text = log
        print(log)
        
        print("%@", error)
        
        status[peripheral.identifier.UUIDString] = TTNSStatus.Connecting
        tblDevices.reloadData()
        
        centralManager.connectPeripheral(peripheral, options: nil)
        
    }
    
    // MARK: - CBPeripheralDelegate
    // サービス発見
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if (error != nil) {
            print(error)
            
            return
        }
        
        let services = peripheral.services
        print("Find Service: %d services %@", services?.count, peripheral.name!)
        
        for service in services! {
            if (service.UUID.UUIDString.isEqual(kServiceUUID)) {
                // キャラスタリック検索開始
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    // キャラスタリック発見
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (error != nil) {
            print("%@", error)
            return
        }
        
        
        print("Find Charasteristic: %d charastatistics %@", service.characteristics!.count, peripheral.name!)
        
        for characteristic in service.characteristics! {
            if (characteristic.UUID.UUIDString.isEqual(kWriteUUID)) {
                // 保持
                characteristics[peripheral.identifier.UUIDString] = characteristic
                
                // RSSIチェック
                peripheral.readRSSI()
            }
        }
    }
    
    // 書き込み完了
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if (error != nil) {
            print("Write Error: %@", error)
            return
        }
        
        print("Success Write: %@", peripheral.identifier.UUIDString)
    }

    // RSSI更新
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        print("RSSI %d %@", RSSI.intValue, peripheral.identifier.UUIDString)
        
        rssis[peripheral.identifier.UUIDString] = RSSI.stringValue
        tblDevices.reloadData()
        
        let limit: Int = NSUserDefaults.standardUserDefaults().integerForKey("RSSI")
        
        // もう一度読みこむ
        if (RSSI.integerValue < limit) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                usleep(400);
                peripheral.readRSSI();
            });
            
            return
        }
        
        let log = String(format: "Start Writing %@", peripheral.identifier.UUIDString)
        lblLog.text = log
        print(log)
        
        
        write(peripheral)
    }

}
