//
//  WebViewController.swift
//  P2PTunnelAgent
//
//  Created by Cloud Hsiao on 2/19/16.
//  Copyright © 2016 ThroughTek. All rights reserved.
//

import Foundation
import UIKit

class WebViewController: UIViewController, UITextFieldDelegate {
  var LocalPort: Int!
  @IBOutlet weak var textFieldLocalPort: UITextField!
  @IBOutlet weak var webview: UIWebView!

  override func viewDidLoad() {
    textFieldLocalPort.text = "http://127.0.0.1:\(LocalPort)/"
    textFieldLocalPort.becomeFirstResponder()
    textFieldLocalPort.delegate = self
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    let url = NSURL(string: textField.text!)
    let requestObj = NSURLRequest(URL: url!)
    webview.loadRequest(requestObj)
    return true
  }
}
