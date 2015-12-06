//
//  BingoViewController.swift
//  TTNSDemo151213
//
//  Created by 山崎 慎太郎 on 2015/12/06.
//  Copyright © 2015年 山崎 慎太郎. All rights reserved.
//

import UIKit

import CoreBluetooth

class BingoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    enum BingoStatus {
        case Connecting
        case Connected
        case Diconnected
        case Wrote1
        case Wrote2
        case Wrote3
        case Wrote4
        case Wrote5
        case Wrote6
    }
    
    @IBOutlet var btn1: UIButton!
    @IBOutlet var btn2: UIButton!
    @IBOutlet var btn3: UIButton!
    @IBOutlet var btn4: UIButton!
    @IBOutlet var btn5: UIButton!
    @IBOutlet var btn6: UIButton!
    @IBOutlet var btnConnect: UIButton!
    @IBOutlet var lblLog: UILabel!
    @IBOutlet var tblDevices: UITableView!
    
    var centralManager: CBCentralManager = CBCentralManager.init()
    var peripherals: [CBPeripheral] = []
    var characteristics: [String: CBCharacteristic] = [:]
    var status: [String: BingoStatus] = [:]
    
    /// 接続中
    var isConnected: Bool = false
    /// 各ボタンの番号割り当て
    var openNum: [String] = ["08", "18", "24", "32", "48", "00"]
    
    let kServiceUUID = "ADA99A7F-888B-4E9F-8080-07DDC240F3CE"
    let kWriteUUID = "ADA99A7F-888B-4E9F-8082-07DDC240F3CE"
    let kReadUUID = "ADA99A7F-888B-4E9F-8081-07DDC240F3CE"
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        enableButton(false)
        
        btn1.setTitle(openNum[0], forState: UIControlState.Normal)
        btn2.setTitle(openNum[1], forState: UIControlState.Normal)
        btn3.setTitle(openNum[2], forState: UIControlState.Normal)
        btn4.setTitle(openNum[3], forState: UIControlState.Normal)
        btn5.setTitle(openNum[4], forState: UIControlState.Normal)
        btn6.setTitle(openNum[5], forState: UIControlState.Normal)
        
        // 今回はボタン6は使わない
        btn6.hidden = true
        
        // セントラルマネージャ初期化
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        
        lblLog.text = ""
        
        tblDevices.delegate = self
        tblDevices.dataSource = self
    }
    
    func enableButton(isEnabled: Bool) {
        btn1.enabled = isEnabled
        btn2.enabled = isEnabled
        btn3.enabled = isEnabled
        btn4.enabled = isEnabled
        btn5.enabled = isEnabled
        btn6.enabled = isEnabled
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
        
        enableButton(false)
        
        btn1.backgroundColor = UIColor.clearColor()
        btn2.backgroundColor = UIColor.clearColor()
        btn3.backgroundColor = UIColor.clearColor()
        btn4.backgroundColor = UIColor.clearColor()
        btn5.backgroundColor = UIColor.clearColor()
        btn6.backgroundColor = UIColor.clearColor()
        
        btnConnect.setTitle("接続", forState: .Normal)
    }
    
    func connect() {
        // スキャン開始
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
        let log: String = "Start Scan"
        lblLog.text = log
        print(log)
        
        enableButton(true)
        
        btnConnect.setTitle("切断", forState: .Normal)
    }

    // MARK: - IBAction
    /// 戻るボタン
    @IBAction func onBack(sender: AnyObject) {
        disconnect()
        
        isConnected = false
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// ボタン1
    @IBAction func onButton1(sendr: AnyObject) {
        btn1.backgroundColor = UIColor.darkGrayColor()
        write(openNum[0])
    }
    
    /// ボタン2
    @IBAction func onButton2(sendr: AnyObject) {
        btn2.backgroundColor = UIColor.darkGrayColor()
        write(openNum[1])
    }
    
    /// ボタン3
    @IBAction func onButton3(sendr: AnyObject) {
        btn3.backgroundColor = UIColor.darkGrayColor()
        write(openNum[2])
    }
    
    /// ボタン4
    @IBAction func onButton4(sendr: AnyObject) {
        btn4.backgroundColor = UIColor.darkGrayColor()
        write(openNum[3])
    }
    
    /// ボタン5
    @IBAction func onButton5(sendr: AnyObject) {
        btn5.backgroundColor = UIColor.darkGrayColor()
        write(openNum[4])
    }
    
    /// ボタン6
    @IBAction func onButton6(sendr: AnyObject) {
        btn6.backgroundColor = UIColor.darkGrayColor()
        write(openNum[5])
    }
    
    /// 接続ボタン
    @IBAction func onConnect(sender: AnyObject) {
        if(!isConnected) {
            connect()
            
            isConnected = true
        } else {
            disconnect()
            
            isConnected = false
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
        
        var stxt: String
        switch status[peripheral.identifier.UUIDString]! as BingoStatus {
            case BingoStatus.Connecting:
                stxt = "Connecting"
                cell.textLabel?.textColor = UIColor.blackColor()
                break
            case BingoStatus.Connected:
                stxt = "Connected"
                cell.textLabel?.textColor = UIColor.blueColor()
                break
            case BingoStatus.Diconnected:
                stxt = "Disconnected"
                cell.textLabel?.textColor = UIColor.redColor()
                break
            case BingoStatus.Wrote1:
                stxt = String(format: "Open %@", openNum[0])
                cell.textLabel?.textColor = UIColor.greenColor()
                break
            case BingoStatus.Wrote2:
                stxt = String(format: "Open %@", openNum[1])
                cell.textLabel?.textColor = UIColor.greenColor()
                break
            case BingoStatus.Wrote3:
                stxt = String(format: "Open %@", openNum[2])
                cell.textLabel?.textColor = UIColor.greenColor()
                break
            case BingoStatus.Wrote4:
                stxt = String(format: "Open %@", openNum[3])
                cell.textLabel?.textColor = UIColor.greenColor()
                break
            case BingoStatus.Wrote5:
                stxt = String(format: "Open %@", openNum[4])
                cell.textLabel?.textColor = UIColor.greenColor()
                break
            case BingoStatus.Wrote6:
                stxt = String(format: "Open %@", openNum[5])
                cell.textLabel?.textColor = UIColor.greenColor()
                break
            default: break
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
    func write(num: String) {
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
        for peripheral in peripherals {
            let characteristic = characteristics[peripheral.identifier.UUIDString]
            if (characteristic != nil) {
                peripheral.writeValue(cmd_data, forCharacteristic: characteristic!, type: CBCharacteristicWriteType.WithResponse)
                let log: String = String(format: "Write %@ %@", num, peripheral.identifier.UUIDString)
                print(log)
                lblLog.text = log
                
                switch (num) {
                    case openNum[0]:
                        status[peripheral.identifier.UUIDString] = BingoStatus.Wrote1
                        break
                    case openNum[1]:
                        status[peripheral.identifier.UUIDString] = BingoStatus.Wrote2
                        break
                    case openNum[2]:
                        status[peripheral.identifier.UUIDString] = BingoStatus.Wrote3
                        break
                    case openNum[3]:
                        status[peripheral.identifier.UUIDString] = BingoStatus.Wrote4
                        break
                    case openNum[4]:
                        status[peripheral.identifier.UUIDString] = BingoStatus.Wrote5
                        break
                    case openNum[5]:
                        status[peripheral.identifier.UUIDString] = BingoStatus.Wrote6
                        break
                    default: break
                }
                tblDevices.reloadData()
            }
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
            status[peripheral.identifier.UUIDString] = BingoStatus.Connecting
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
        
        status[peripheral.identifier.UUIDString] = BingoStatus.Connected
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
            
            status[peripheral.identifier.UUIDString] = BingoStatus.Connecting
            tblDevices.reloadData()
            
            centralManager.connectPeripheral(peripheral, options: nil)
            
            return
        }
        
        status[peripheral.identifier.UUIDString] = BingoStatus.Diconnected
        tblDevices.reloadData()
        
        tblDevices.reloadData()
    }
    
    // 接続失敗
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        let log: String = String(format: "Fault Connect: %@", peripheral.name!)
        lblLog.text = log
        print(log)
        
        print("%@", error)
        
        status[peripheral.identifier.UUIDString] = BingoStatus.Connecting
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
}
