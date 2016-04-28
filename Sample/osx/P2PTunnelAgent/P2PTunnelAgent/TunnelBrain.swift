//
//  P2PTunnel.swift
//  P2PTunnelAgent
//
//  Created by Cloud Hsiao on 9/30/15.
//  Copyright © 2015 ThroughTek. All rights reserved.
//

import Foundation

struct PortMapping {
    var Index: UInt32 = 0
    var SessionID: Int32 = -1
}

extension PortMapping: Equatable {}
func ==(lhs: PortMapping, rhs: PortMapping) -> Bool {
    return lhs.Index == rhs.Index && lhs.SessionID == rhs.SessionID
}

@objc protocol TunnelBrainDelegate {
    optional func Tunnel(UID: String, didConnectReturn code: Int32, AndErrorFromDevice error: Int32)
    optional func Tunnel(UID: String, didDisconnectAtSessionID sessionID: Int32)
    optional func Tunnel(UID: String, didChangeStatus status: Int32, atSessionID sessionID: Int32)
    optional func Tunnel(UID: String, didAddPortMappingAtIndex index: Int32, withLocalPort localPort: UInt16, AndRemotePort remotePort: UInt16)
}

class TunnelBrain {
    
    static let sharedInstance = TunnelBrain()
    var delegate: TunnelBrainDelegate?
    
    private var sessionIDs = [Int32 : String]()
    private var portMappingList = [PortMapping]()
    
    private init() {
        // Set the callback function
        let block : @convention(block) (nErrorCode: Int32,
                                    nSessionID: Int32,
                                    pArg: UnsafeMutablePointer<Void>) -> Void =
        { (nErrorCode: Int32, nSessionID: Int32, pArg: UnsafeMutablePointer<Void>) in
            let uid = self.sessionIDs[nSessionID]
            
            if (nErrorCode == TUNNEL_ER_DISCONNECTED) {
                self.sessionIDs[nSessionID] = nil
            }

            dispatch_async(dispatch_get_main_queue(), {
                delegate?.Tunnel?(uid!, didChangeStatus: nErrorCode, atSessionID: nSessionID)
            })
        }
        let callback = unsafeBitCast(imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self)),
                                        tunnelStatusCB.self)
        
        P2PTunnelAgentInitialize(4)
        P2PTunnelAgent_GetStatus(callback, nil)
    }
    
    deinit {
        P2PTunnelAgentDeInitialize();
    }
    
    func isTunnelSessionConnected(UID: String?) -> Bool {
        for uid in sessionIDs.values {
            if uid == UID {
                return true
            }
        }
        return false
    }
    
    func connect(UID: String, withUsername username: String?, andPassword password: String?) {
        let uid: UnsafePointer<Int8> = UnsafePointer<Int8>((UID as NSString!).UTF8String)
        var sid: Int32 = -1
        var authData: Array<CChar> = Array(count:128, repeatedValue: 0)
        var acc: Array<CChar> = Array(count:64, repeatedValue: 0)
        var pwd: Array<CChar> = Array(count:64, repeatedValue: 0)
        var pnErrFromDevice: Int32 = 0

        if let u = username, p = password {
            strcpy(&acc, u)
            strcpy(&pwd, p)
        }

        memcpy(&authData, &acc, 64)
        memcpy(&authData + 64, &pwd, 64)
        
        // Connect to device in a thread queue
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            sid = P2PTunnelAgent_Connect(uid, &authData, 128, &pnErrFromDevice)
            print("P2PTunnelAgent_Connect(\(UID)) -> \(sid)")
            if sid >= 0 {
                self.sessionIDs[sid] = UID
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.Tunnel?(UID, didConnectReturn: sid, AndErrorFromDevice: pnErrFromDevice)
            })
        })
    }
    
    func disconnect(UID: String) {
        for (sid, uid) in sessionIDs {
            if uid == UID {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    // Stop and Remove port mappings
                    for mapping in self.portMappingList {
                        if mapping.SessionID == sid {
                            P2PTunnelAgent_StopPortMapping(mapping.Index)
                            print("P2PTunnelAgent_StopPortMapping(\(mapping.Index))")
                            
                            if let foundIndex = self.portMappingList.indexOf(mapping) {
                                self.portMappingList.removeAtIndex(foundIndex)
                            }
                        }
                    }
                    P2PTunnelAgent_Disconnect(sid)
                    print("P2PTunnelAgent_Disconnect(\(sid))")
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.sessionIDs[sid] = nil
                        self.delegate?.Tunnel?(UID, didDisconnectAtSessionID: sid)
                    })
                })
            }
        }
    }
    
    func addPortMapping(UID: String, AtLocalPort localPort: UInt16, ToRemotePort remotePort: UInt16) -> (Bool, Int32) {
        for (sid, uid) in sessionIDs {
            if uid == UID {
                let ret = P2PTunnelAgent_PortMapping(sid, localPort, remotePort)
                print("P2PTunnelAgent_PortMapping(\(sid), \(localPort), \(remotePort)) -> \(ret)")
                if ret >= 0 {
                    portMappingList.append(PortMapping(Index: UInt32(ret), SessionID: sid))
                    delegate?.Tunnel?(uid, didAddPortMappingAtIndex: ret, withLocalPort: localPort, AndRemotePort: remotePort)
                }
                return (true, ret)
            }
        }
        return (false, 0)
    }
    
    func clearPortMapping(UID: String) {
        for (sid, uid) in sessionIDs {
            if uid == UID {
                for mapping in self.portMappingList {
                    if mapping.SessionID == sid {
                        P2PTunnelAgent_StopPortMapping(mapping.Index)
                        print("P2PTunnelAgent_StopPortMapping(\(mapping.Index))")
                        
                        if let foundIndex = self.portMappingList.indexOf(mapping) {
                            self.portMappingList.removeAtIndex(foundIndex)
                        }
                    }
                }
            }
        }
    }
}