//
//  ViewController.swift
//  P2PTunnelAgent
//
//  Created by Cloud Hsiao on 9/15/15.
//  Copyright (c) 2015 ThroughTek. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var txtUID: NSTextField!
    @IBOutlet weak var btnConnect: NSButton!
    @IBOutlet weak var processIndicator: NSProgressIndicator!
    @IBOutlet weak var txtLocalPort: NSTextField!
    @IBOutlet weak var txtRemotePort: NSTextField!
    @IBOutlet weak var btnAddPortMapping: NSButton!
    
    var tunnel = TunnelBrain.sharedInstance
    var UID: String?
    
    @IBAction func connectToServer(sender: AnyObject) {
        if btnConnect.state == NSOnState  {
            if txtUID.stringValue.characters.count == 20 {
                btnConnect.enabled = false
                processIndicator.startAnimation(nil)
                btnConnect.title = "Connecting"
                UID = txtUID.stringValue
                tunnel.connect(UID!, withUsername: "Tutk.com", andPassword: "P2P Platform")
            } else {
                showMessage(title: "Connection", withMessage: "The UID is wrong.")
                btnConnect.state = (NSOffState)
                UID = nil
            }
        } else {
            tunnel.disconnect(UID!)
            btnConnect.title = "Connect"
            UID = nil
        }
    }
    
    @IBAction func addPortMapping(sender: AnyObject) {
        let localPort: Int? = Int(txtLocalPort.stringValue)
        let remotePort: Int? = Int(txtRemotePort.stringValue)

        if localPort != nil && remotePort != nil {
            if localPort > 1024 && localPort < 65536 && remotePort > 1024 && remotePort < 65536 {
                tunnel.addPortMapping(UID!, AtLocalPort: UInt16(localPort!), ToRemotePort: UInt16(remotePort!))
            } else {
                self.showMessage(title: "Warning", withMessage: "Your local or remote port is out of range.")
            }
        }else {
            self.showMessage(title: "Warning", withMessage: "You can not empty the local and remote port.")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tunnel.delegate = self
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        if obj.object === txtUID {
            if let info = obj.userInfo, text = info["NSFieldEditor"] as? NSText, string = text.string {
                text.string = string.uppercaseString
            }
        }
    }
    
    private func showMessage(title text: String?, withMessage message: String?) {
        let msg = NSAlert()
        msg.messageText = text!
        msg.informativeText = message!
        msg.runModal()
    }
}

// MARK: - TunnelBrainDelegate

extension ViewController: TunnelBrainDelegate {
    func Tunnel(UID: String, didConnectReturn code: Int32, AndErrorFromDevice error: Int32) {
        if code >= 0 && error == 0 {
            // Connect successfully
            btnConnect.title = "Connected"
            txtLocalPort.hidden = false
            txtRemotePort.hidden = false
            btnAddPortMapping.hidden = false
            btnConnect.state = NSOnState
        } else {
            // Connection failed
            btnConnect.title = "Connect"
            txtLocalPort.hidden = true
            txtRemotePort.hidden = true
            btnAddPortMapping.hidden = true
            btnConnect.state = NSOffState
            showMessage(title: "Connection", withMessage: "Your connection failed. Try reconnecting. If the problem continues, veryify your network settings.")
        }
        processIndicator.stopAnimation(nil)
        btnConnect.enabled = true
    }
    
    func Tunnel(UID: String, didChangeStatus status: Int32, atSessionID sessionID: Int32) {
        if status == TUNNEL_ER_DISCONNECTED {
            tunnel.clearPortMapping("")
            btnConnect.title = "Connect"
            txtLocalPort.hidden = true
            txtRemotePort.hidden = true
            btnAddPortMapping.hidden = true
            btnConnect.state = NSOffState
            showMessage(title: "Connection", withMessage: "Oops! Your connection closed. Try reconnecting.")
        }
    }
    
    func Tunnel(UID: String, didDisconnectAtSessionID sessionID: Int32) {
        btnConnect.title = "Connect"
        txtLocalPort.hidden = true
        txtRemotePort.hidden = true
        btnAddPortMapping.hidden = true
        btnConnect.state = NSOffState
    }
}