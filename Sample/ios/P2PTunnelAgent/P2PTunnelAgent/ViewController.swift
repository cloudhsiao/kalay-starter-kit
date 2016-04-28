//
//  ViewController.swift
//  P2PTunnelAgent
//
//  Created by Cloud Hsiao on 9/8/15.
//  Copyright (c) 2015 ThroughTek. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    @IBOutlet weak var lblUID: UILabel!
    @IBOutlet weak var switchConnect: UISwitch!
    @IBOutlet weak var textFieldLocalPort: UITextField!
    @IBOutlet weak var textFieldRemotePort: UITextField!
    @IBOutlet weak var btnAddPortMapping: UIButton!
    @IBOutlet weak var indicatorConnecting: UIActivityIndicatorView!
    @IBOutlet weak var lblConnect: UILabel!
    
    var tunnel: TunnelBrain = TunnelBrain.sharedInstance
    var userIsInConnecting: Bool = false
    var UID: String?
    var lastLocalPort: Int? = nil
  
    override func viewDidLoad() {
        super.viewDidLoad()
        if let uid = NSUserDefaults.standardUserDefaults().stringForKey("UID") {
            lblUID.text = uid
        }
        if let lPort = NSUserDefaults.standardUserDefaults().stringForKey("LPort") {
            textFieldLocalPort.text = lPort
        }
        if let rPort = NSUserDefaults.standardUserDefaults().stringForKey("RPort") {
            textFieldRemotePort.text = rPort
        }
        tunnel.delegate = self
     }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard  segue.identifier != nil else {
            return
        }
      
        if segue.identifier! == "segueEditUID" {
            let vc = segue.destinationViewController as! EditUIDViewController
            vc.UID = lblUID.text
            vc.delegate = self
        } else if segue.identifier! == "segueViewWeb" {
            let vc = segue.destinationViewController as! WebViewController
            vc.LocalPort = lastLocalPort!
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "segueEditUID" {
            return !userIsInConnecting && !tunnel.isTunnelSessionConnected(UID)
        } else if identifier == "segueViewWeb" {
            return lastLocalPort != nil
        }
        return false
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "CONNECTION"
        case 1:
            return tunnel.isTunnelSessionConnected(UID) ? "PORT MAPPING" : nil
        case 2:
            return tunnel.isTunnelSessionConnected(UID) && lastLocalPort != nil ? "ACTION" : nil
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return tunnel.isTunnelSessionConnected(UID) ? 3 : 0
        case 2:
            return tunnel.isTunnelSessionConnected(UID) && lastLocalPort != nil ? 1 : 0
        default:
            return 2
        }
    }
    
// MARK: - UI methods
    
    @IBAction func switchConnectValueDidChanged(sender: AnyObject?) {
        if switchConnect.on {
            if lblUID.text != nil && (self.lblUID.text!).characters.count == 20 {
                switchConnect.hidden = true
                indicatorConnecting.hidden = false
                lblConnect.text = "Connecting..."
                userIsInConnecting = true
                UID = lblUID.text
                tunnel.connect(UID!, withUsername: "Tutk.com", andPassword: "P2P Platform")
                NSUserDefaults.standardUserDefaults().setObject(UID, forKey: "UID")
                NSUserDefaults.standardUserDefaults().synchronize()
            } else {
                showMessage(title: "Connection", withMessage: "The UID is wrong.")
                switchConnect.setOn(false, animated: true)
                UID = nil
            }
        } else {
            if tunnel.isTunnelSessionConnected(UID) {
                tunnel.disconnect(UID!)
            }
            UID = nil
            lastLocalPort = nil
        }
    }
    
    @IBAction func btnAddPortMappingPressed(sender: AnyObject?) {
        let localPort: Int? = Int(textFieldLocalPort.text!)
        let remotePort: Int? = Int(textFieldRemotePort.text!)
      
        if localPort != nil && remotePort != nil {
            if localPort > 1024 && localPort < 65536 && remotePort > 1024 && remotePort < 65536 {
                textFieldLocalPort.resignFirstResponder()
                textFieldRemotePort.resignFirstResponder()
                tunnel.addPortMapping(UID!, AtLocalPort: UInt16(localPort!), ToRemotePort: UInt16(remotePort!))
            } else {
                showMessage(title: "Warning", withMessage: "Your local or remote port is out of range.")
            }
        } else {
            showMessage(title: "Warning", withMessage: "You can not empty the local and remote port.")
        }
    }
    
// MARK: Private methods
    
    func showMessage(title text: String?, withMessage message: String?) {
        let msg = UIAlertView(title: text, message: message, delegate: nil, cancelButtonTitle: "OK")
        msg.show()
    }
}

// MARK: - EditUIDViewControllerDelegate

extension ViewController: EditUIDViewControllerDelegate {
    func EditUIDViewControllerDidReceiveUID(UID: String?) {
        lblUID.text = UID
    }
}

// MARK: - TunnelBrainDelegate

extension ViewController: TunnelBrainDelegate {
    func Tunnel(UID: String, didConnectReturn code: Int32, AndErrorFromDevice error: Int32) {
        if code < 0 || error < 0 {
            showMessage(title: "Connection", withMessage: "Your connection failed (\(code)). Try reconnecting. If the problem continues, veryify your network settings.")
        }
        lblConnect.text = "Connection"
        indicatorConnecting.hidden = true
        userIsInConnecting = false
        switchConnect.hidden = false
        switchConnect.setOn((code >= 0 && error == 0) ? true : false, animated: true)
        tableView.reloadData()
    }

    func Tunnel(UID: String, didChangeStatus status: Int32, atSessionID sessionID: Int32) {
        if status == TUNNEL_ER_DISCONNECTED {
            tunnel.clearPortMapping(self.UID!)
            switchConnect.hidden = false
            switchConnect.setOn(false, animated: true)
            self.UID = nil
            lastLocalPort = nil
            showMessage(title: "Connection", withMessage: "Oops! Your connection closed. Try reconnecting.")
        }
        tableView.reloadData()
    }
    
    func Tunnel(UID: String, didAddPortMappingAtIndex index: Int32, withLocalPort localPort: UInt16, AndRemotePort remotePort: UInt16) {
        textFieldLocalPort.text = ""
        textFieldRemotePort.text = ""
        lastLocalPort = Int(localPort)
        NSUserDefaults.standardUserDefaults().setObject("\(localPort)", forKey: "LPort")
        NSUserDefaults.standardUserDefaults().setObject("\(remotePort)", forKey: "RPort")
        NSUserDefaults.standardUserDefaults().synchronize()
        tableView.reloadData()
    }
  
    func Tunnel(UID: String, didDisconnectAtSessionID sessionID: Int32) {
        tableView.reloadData()
    }
}
