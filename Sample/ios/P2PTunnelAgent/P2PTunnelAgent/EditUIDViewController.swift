//
//  EditUIDViewController.swift
//  P2PTunnelAgent
//
//  Created by Cloud Hsiao on 9/8/15.
//  Copyright (c) 2015 ThroughTek. All rights reserved.
//

import Foundation
import UIKit

protocol EditUIDViewControllerDelegate {
    func EditUIDViewControllerDidReceiveUID(UID: String?)
}

class EditUIDViewController : UITableViewController {
    
    @IBOutlet weak var textFieldUID: UITextField!
    
    var UID : String?
    var delegate: EditUIDViewControllerDelegate? = nil
    
    override func viewDidLoad() {
        self.textFieldUID.text = UID
        self.textFieldUID.becomeFirstResponder()
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if (!(parent?.isEqual(self.parentViewController) ?? false)) {
            if delegate != nil {
                delegate!.EditUIDViewControllerDidReceiveUID(textFieldUID.text)
            }
        }
    }
}

// MARK: UITextFieldDelegate
extension EditUIDViewController: UITextFieldDelegate {
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let maxLen = 20
        let currentString: NSString = textFieldUID.text!
        let newString: NSString = currentString.stringByReplacingCharactersInRange(range, withString: string)
        return newString.length <= maxLen
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textFieldUID.resignFirstResponder()
        self.navigationController?.popViewControllerAnimated(true)
        return false
    }
}