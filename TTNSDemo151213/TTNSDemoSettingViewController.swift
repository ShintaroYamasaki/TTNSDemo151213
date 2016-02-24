//
//  TTNSDemoSettingViewController.swift
//  TTNSDemo151213
//
//  Created by Yamasaki Shintaro on 2015/12/08.
//  Copyright © 2015年 山崎 慎太郎. All rights reserved.
//

import UIKit

class TTNSDemoSettingViewController: UIViewController {

    @IBOutlet var txtA: UITextField!
    @IBOutlet var txtB: UITextField!
    @IBOutlet var lblRSSI: UILabel!
    @IBOutlet var stpRSSI: UIStepper!
    
    var delegate: TTNSDemoSettingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        txtA.text = NSUserDefaults.standardUserDefaults().stringForKey("NUM_A")
        txtB.text = NSUserDefaults.standardUserDefaults().stringForKey("NUM_B")
        stpRSSI.value = NSUserDefaults.standardUserDefaults().doubleForKey("RSSI")
        lblRSSI.text = String(format: "%f", stpRSSI.value)
        
    }

    // MARK: IBAction
    @IBAction func onBack() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onOK() {
        NSUserDefaults.standardUserDefaults().setObject(txtA.text, forKey: "NUM_A")
        NSUserDefaults.standardUserDefaults().setObject(txtB.text, forKey: "NUM_B")
        NSUserDefaults.standardUserDefaults().setDouble(stpRSSI.value, forKey: "RSSI")
        
        delegate?.completeSetting()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func chageStepperRSSI(sender: AnyObject) {
        lblRSSI.text = String(format: "%f", stpRSSI.value)
    }
    
    @IBAction func tapScreen(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}

protocol TTNSDemoSettingDelegate {
    // 完了
    func completeSetting();
}
