//
//  BingoSettingViewController.swift
//  TTNSDemo151213
//
//  Created by Yamasaki Shintaro on 2015/12/07.
//  Copyright © 2015年 山崎 慎太郎. All rights reserved.
//

import UIKit

class BingoSettingViewController: UIViewController {

    @IBOutlet var txt1: UITextField!
    @IBOutlet var txt2: UITextField!
    @IBOutlet var txt3: UITextField!
    @IBOutlet var txt4: UITextField!
    @IBOutlet var txt5: UITextField!
    @IBOutlet var txt6: UITextField!
    
    var delegate: BingoSettingDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txt1.text = NSUserDefaults.standardUserDefaults().stringForKey("BUTTON1")
        txt2.text = NSUserDefaults.standardUserDefaults().stringForKey("BUTTON2")
        txt3.text = NSUserDefaults.standardUserDefaults().stringForKey("BUTTON3")
        txt4.text = NSUserDefaults.standardUserDefaults().stringForKey("BUTTON4")
        txt5.text = NSUserDefaults.standardUserDefaults().stringForKey("BUTTON5")
        txt6.text = NSUserDefaults.standardUserDefaults().stringForKey("BUTTON6")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBAction
    @IBAction func onCancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onOK(sendr: AnyObject) {
        NSUserDefaults.standardUserDefaults().setObject(txt1.text, forKey: "BUTTON1")
        NSUserDefaults.standardUserDefaults().setObject(txt2.text, forKey: "BUTTON2")
        NSUserDefaults.standardUserDefaults().setObject(txt3.text, forKey: "BUTTON3")
        NSUserDefaults.standardUserDefaults().setObject(txt4.text, forKey: "BUTTON4")
        NSUserDefaults.standardUserDefaults().setObject(txt5.text, forKey: "BUTTON5")
        NSUserDefaults.standardUserDefaults().setObject(txt6.text, forKey: "BUTTON6")
        
        delegate.completedSetting()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

protocol BingoSettingDelegate {
    /// 設定完了
    func completedSetting()
}
